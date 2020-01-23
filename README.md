# Museoscript
# Introduction

Museoscript is a bash script wrapping several programs, aiming to process High-Throughput Sequencing data from historical specimens, particularly in the context of taxonomy and systematics studies. More in details, this script takes as input raw illumina reads and, after trimming and quality checking, aligns them to a set of reference sequences with vsearch, using an user-specified similarity threshold. It outputs a table summarizing the amount of reads matching each of the reference sequences, as well as the lists of these reads, that can be used to retrieve the sequences from the original data (in order for exemple to assemble consensus sequences). 

# Dependencies

Museoscript relies on three external softwares that must be installed in order to use it:
  - Trimmomatic (http://www.usadellab.org/cms/?page=trimmomatic)
  - Seqtk (https://github.com/lh3/seqtk)
  - vsearch (https://github.com/torognes/vsearch)
  
  The script must be modified to have the right path to the trimmomatic executable. To do so, open the script in a text editor and edit the line 122 to provide the correct path:
  java -jar ~/path/to/trimmomatic/trimmomatic-0.XX.jar SE -phred33 $i trimmed_reads/"$name"_trimmed.fastq.gz ILLUMINACLIP:/home/lois/softwares/Trimmomatic-0.38/adapters/TruSeq3-SE.fa:2:30:10 LEADING:10 TRAILING:10 SLIDINGWINDOW:2:25 MINLEN:36 &> trimmed_reads/trimmomatic_"$name".log
  
  This line can be modified to change Trimmomatic's parameters as well.
