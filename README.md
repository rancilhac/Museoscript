# Museoscript
# Introduction

Museoscript is a bash script wrapping several programs, aiming to process High-Throughput Sequencing data from historical specimens, particularly to assign them to species and integrate them in phylogenetic analyses in the context of taxonomics and systematics studies. More in details, this script trims and cleans the raw reads and align them to a set of reference sequences based on an user-provided similarity threshold. The output is a summary of the amount of reads matching the different reference sequences, as well as the list of these reads, that can be used to assembled consensus sequences (see details below).

# Dependencies

Museoscript uses three external softwares that must be installed in order to use it:
  - Trimmomatic (http://www.usadellab.org/cms/?page=trimmomatic)
  - Seqtk (https://github.com/lh3/seqtk)
  - vsearch (https://github.com/torognes/vsearch)
  
GNU parralel (https://www.gnu.org/software/parallel/) must also be installed.
  
To set path to the trimmomatic executable, the script must be modified. This can be done easily by opening the script in a text editor and editing the line 122 to provide the correct path (make sure to change both the path to the executable and to the adapters):
  
  echo "java -jar path/to/trimmomatic/trimmomatic-0.XX.jar SE -phred33 $i trimmed_reads/$name-trimmed.fastq.gz ILLUMINACLIP:/path/to/trimmomatic/adapters/TruSeq3-SE.fa:2:30:10 LEADING:10 TRAILING:10 SLIDINGWINDOW:2:25 MINLEN:36 &> trimmed_reads/trimmomatic-$name.log" >> run_trimmomatic
  
  This line can be modified to change other settings of Trimmomatic as well.
  
  # Usage
  
arguments: 
	-h | --help : print a help message and exit
	-r | --ref : path to a directory containing the reference sequences. Each sequence must be in a separate fasta file with names such as "ref_sequence.fasta"
	-d | --raw : path to a directory containing the raw illumina reads. Each file must be in .fastq.gz format with names such as "sample.fastq.gz"
	-w | --work : path to working directory : path to an existing directory where the outputs will be stored 
	-P | --phred : phred score below which bases should be masked with a N in the raw reads (used by seqtk)
	-t | --threshold : similarity threshold to be used by vsearch to map align the reads 
	-T | --threads : number of threads to use, default = 1
