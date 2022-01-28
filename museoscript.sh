#!/bin/bash

# Loïs Rancilhac (loisrancilhac@gmail.com)
# September 2019

# dependencies : 
# trimmomatic (http://www.usadellab.org/cms/?page=trimmomatic)
# seqtk (https://github.com/lh3/seqtk)
# vsearch (https://github.com/torognes/vsearch)
# parallel


###### PARSE ARGUMENTS #######

err="\n script to map illumina reads to a set of reference sequences, aimed at identifying museum specimens \n
	\n
dependencies:\n
	trimmomatic (http://www.usadellab.org/cms/?page=trimmomatic)\n
	seqtk (https://github.com/lh3/seqtk)\n
	vsearch (https://github.com/torognes/vsearch)\n
	\n
arguments:\n 
	-h | --help : print this message and exit\n
	-r | --ref : path to reference sequences (in fasta format) \n
	-d | --raw : path to raw illumina reads (in .fastq.gz format) \n
	-w | --work : path to working directory\n
	-P | --phred : phred score below which bases should be masked with a N\n
	-t | --threshold : similarity threshold to be used by vsearch to map align the reads\n
	-T | --threads : number of threads to use. Default = 1\n
	-C | --clean : Y/N, whether to trim adapters and quality check reads before aligning to the reference. Default = Y;
"

if [[ $# == 0 ]]
then
echo -e $err
exit 1
else
while [[ $# -gt 0 ]]
do
key="$1"

case "$key" in
	-h | --help)
	echo -e $err
	shift
	shift
	;;
	-r | --ref)
	REF=$2
	shift
	shift
	;;
	-d | --raw)
	RAW=$2
	shift
	shift
	;;
	-w | --work)
	WORK=$2
	shift
	shift
	;;
	-t | --threshold)
	THRESH=$2
	shift
	shift
	;;
	-P | --phred)
	PHRED=$2
	shift
	shift
	;;
	-T | --threads)
	THREAD=$2
	shift
	shift
	;;
		-C | --clean)
	CLEAN=$2
	shift
	shift
	;;
esac
done
fi

###### MAIN SCRIPT #######

# check for fastq files in the raw data directory and return an error if none found

FASTQ=$(ls $RAW/*.fastq.gz)

if [[ -z $FASTQ ]]
	then
		echo "no fastq files could be found in" $RAW
		exit 1
	else
		NSAMPLES=$(echo $FASTQ | wc -w)
		LSAMPLES=$(echo $FASTQ | sed 's/\.fastq\.gz//g' | sed 's/ /\n/g')
		echo "$NSAMPLES samples to be processed:
$LSAMPLES"
fi

if [[ -z $THREAD ]]
	then
		THREAD=1
fi


if [[ -z $CLEAN ]]
	then
		CLEAN=Y
fi

#### STEP 1 ⁻ Data cleaning ####

if [[ $CLEAN = Y ]]
then
echo $(date "+%D %H:%M:%S") "- Step 1 : Quality filtering and trimming"

cd $RAW
mkdir trimmed_reads

# store the trimmomatic and seqtk commands to be executed
for i in *.fastq.gz
do
name=$(echo $i | sed 's/\.fastq\.gz//')
# trimm the reads; check for quality using a sliding window
echo "java -jar ~/softwares/Trimmomatic-0.38/trimmomatic-0.38.jar SE -phred33 $i trimmed_reads/$name-trimmed.fastq.gz ILLUMINACLIP:/home/lois/softwares/Trimmomatic-0.38/adapters/TruSeq3-SE.fa:2:30:10 LEADING:10 TRAILING:10 SLIDINGWINDOW:2:25 MINLEN:36 &> trimmed_reads/trimmomatic-$name.log" >> run_trimmomatic
# translate from fastq to fasta; mask the positions with quality below 30 with N
echo "seqtk seq -A -q30 -n N trimmed_reads/$name-trimmed.fastq.gz > trimmed_reads/$name-trimmed.fasta" >> run_seqtk
done


parallel --will-cite -j $THREAD < run_trimmomatic
parallel --will-cite -j $THREAD < run_seqtk

rm run_trimmomatic run_seqtk

echo $(date "+%D %H:%M:%S") "- Quality filtering and trimming done!"
fi

echo -e "\n"
echo -e $(date "+%D %H:%M:%S") "- Step 2 : aligning the reads to the references sequences with a similarity of $THRESH \n"

#### STEP 2 Reads mapping ####

for sample in $(ls $RAW/trimmed_reads/*.fasta | sed 's/\-trimmed\.fasta//')
do
SAMPLE=$(echo $sample | rev | cut -d'/' -f 1 | rev)


echo -e "\n"
centrer_term "#################### Parsing $SAMPLE ####################"
start=$(date "+%s")
echo -e "\n"

cd $WORK
mkdir $SAMPLE
cd $SAMPLE

# this loops align the reads to each reference sequence iteratively and stores the results in a *.vsearch file, as well as the headers of the reads that aligned in a *.read file
for ref in $(ls $REF)
do
#store reference name without extension
seq=$(echo $ref | sed "s/\.[a-zA-Z]*$//")
#execute vsearch
vsearch --usearch_global $RAW/trimmed_reads/$SAMPLE-trimmed.fasta --db $REF/$ref --id $THRESH --alnout $seq-$SAMPLE.vsearch &> $seq-$SAMPLE-vsearch.log
echo $(date "+%D %H:%M:%S") reads aligned to $ref
echo "grep 'Query >' $seq-$SAMPLE.vsearch > $seq-in-$SAMPLE.reads" >> run_grep_$SAMPLE
echo "sed -i 's/Query //' $seq-in-$SAMPLE.reads" >> run_sed_$SAMPLE
done


parallel --will-cite -j $THREAD < run_grep_*
parallel --will-cite -j $THREAD < run_sed_*
rm run_grep_* run_sed_*

# this block merges all the *.reads files and sorts them depending on the number of occurences of a read (thre categories : unique, 2 or 3+ occurences)
cat *.reads | cut -d'|' -f1 | sort | uniq -c | grep "^[[:space:]]*1 " | sed 's/^[[:space:]]*1 //' > reads.uniq
cat *.reads | cut -d'|' -f1 | sort | uniq -c | grep "^[[:space:]]*2 " | sed 's/^[[:space:]]*2 //' > reads.2shared
cat *.reads | cut -d'|' -f1 | sort | uniq -c | grep -E "^[[:space:]]*[3-9]+" | sed 's/^[[:space:]]*[3-9] //' > reads.3shared  
echo "###### READS CATEGORIES DONE"

# split the reads files for parralelization
if [ -s reads.uniq ] ; then split -d --additional-suffix=reads.uniq -l $(expr `wc -l reads.uniq | cut -d' ' -f1` / $THREAD) reads.uniq ; else rm reads.uniq ; fi
if [ -s reads.2shared ] ; then split -d --additional-suffix=reads.2shared -l $(expr `wc -l reads.2shared | cut -d' ' -f1` / $THREAD) reads.2shared ; else rm reads.2shared ; fi
if [ -s reads.3shared ] ; then split -d --additional-suffix=reads.3shared -l $(expr `wc -l reads.3shared | cut -d' ' -f1` / $THREAD) reads.3shared ; else rm reads.3shared ; fi

# this loop checks the number of occurences of each read in the *.read files and write grep command files to retrieve them
for reads in *.reads
do

name=$(echo $reads | cut -d'.' -f1,2)

# Create the run files to be executed by parralel, containing the grep commands
if [ -s reads.uniq ] ; then for runiq in x*reads.uniq ; do echo "while read uniq; do grep \$uniq $reads >> $name.uniq ; done < $runiq" >> run_grep_uniq ; done ; fi
if [ -s reads.2shared ] ; then for r2shared in x*reads.2shared ; do echo "while read shared2; do grep \$shared2 $reads >> $name.2shared ; done < $r2shared" >> run_grep_2shared ; done ; fi
if [ -s reads.3shared ] ; then for r3shared in x*reads.3shared ; do echo "while read shared3; do grep \$shared3 $reads >> $name.3shared ; done < $r3shared" >> run_grep_3shared ; done ; fi

done

# execute the grep files in parralel
if [ -s run_grep_uniq ] ; then parallel --will-cite -j $THREAD < run_grep_uniq ; rm run_grep_uniq x*reads.uniq ; echo $(date "+%D %H:%M:%S") "done classifying unique matches" ; fi
if [ -s run_grep_2shared ] ; then parallel --will-cite -j $THREAD < run_grep_2shared ; rm run_grep_2shared x*reads.2shared ; echo $(date "+%D %H:%M:%S") "done classifying double matches" ; fi
if [ -s run_grep_3shared ] ; then parallel --will-cite -j $THREAD < run_grep_3shared ; rm run_grep_3shared x*reads.3shared ; echo $(date "+%D %H:%M:%S") "done classifying multiple matches" ; fi

# remove empty files
for i in *; do if [ ! -s $i ]; then echo $i "was deleted : file empty"; rm $i; fi; done

# generate summary file in csv format
echo "Threshold = $THRESH" > summary_"$SAMPLE".csv
echo "ref" "$SAMPLE" "Nuniq" "Nshared_2" "Nshared_3" >> summary_"$SAMPLE".csv

# count the number of reads of each category and writes it to the summary file
for i in $(ls *.reads | cut -d'.' -f1,2)
do
ref=$(echo $i | sed 's/_in.*//')
if [ -e "$i".uniq ]
then
Nuniq=$(wc -l "$i".uniq | cut -d' ' -f1)
else Nuniq=0
fi
if [ -e "$i".2shared ]
then
Nshared2=$(wc -l "$i".2shared | cut -d' ' -f1)
else Nshared2=0
fi
if [ -e "$i".3shared ]
then
Nshared3=$(wc -l "$i".3shared | cut -d' ' -f1)
else Nshared3=0
fi
echo $ref $SAMPLE $Nuniq $Nshared2 $Nshared3 >> summary_"$SAMPLE".csv
done

cat summary_"$SAMPLE".csv | sed '1,2d' >> $WORK/summary.csv
done

