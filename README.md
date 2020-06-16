# Museoscript
# Introduction

Museoscript is a bash script wrapping several programs, aiming to process High-Throughput Sequencing data from historical specimens, particularly to assign them to species and integrate them in phylogenetic analyses in the context of taxonomics and systematics studies. As summarized in the figure below, the pipeline performs the following steps: 1) the raw reads from the historic sample(s) are trimmed and quality checked; 2) the clean reads are aligned to a set of reference sequences using a user-defined similarity threshold and the matching reads are extracted; 3) the number of reads matching each reference sequence is counted; 4) the reads can also be used to construct consensus sequences for e.g. phylogenetic inference (not yet implemented in the script). If several samples are provided, they will be analyzed sequentially. See the "Output" section for more details on the script's output. Note that in the present form the script handles only Single-end data, but it can probably be easily modified to handle Paired-end data as well if needed. 


![flowchart](https://user-images.githubusercontent.com/55992265/84758093-4b99a500-afc5-11ea-8dd9-cf29ee1c298c.png)


(Frog pictures courtesy of Mark D. Scherz)


If you use this script, please cite: Rancilhac, L., Bruy, T., Scherz, M. D., Pereira, E. A., Preick, M., Straube, N., Lyra, M. L., Ohler, A., Streicher, J. W., Andreone, F., Crottini, A., Hutter, C. R., Randrianantoandro,J. C., Rokotoarison, A., Glaw, F., Hofreiter, M. & Vences, M. (2020). Target-enriched DNA sequencing from historical type material enables a partial revision of the Madagascar giant stream frogs (genus Mantidactylus). Journal of Natural History, 1-32. https://doi.org/10.1080/00222933.2020.1748243

# Dependencies

Museoscript uses three external softwares that must be installed in order to use it:
  - Trimmomatic (http://www.usadellab.org/cms/?page=trimmomatic)
  - Seqtk (https://github.com/lh3/seqtk)
  - vsearch (https://github.com/torognes/vsearch)
  
GNU parralel (https://www.gnu.org/software/parallel/) must also be installed.
  
No other installation is required to run the script, but it must be modified to set the correct path to the trimmomatic executable. This can be done easily by opening the script in a text editor and editing the line 122 to provide the correct path (make sure to change both the path to the executable and to the adapters):
  
 `` echo "java -jar path/to/trimmomatic/trimmomatic-0.XX.jar SE -phred33 $i trimmed_reads/$name-trimmed.fastq.gz ILLUMINACLIP:/path/to/trimmomatic/adapters/TruSeq3-SE.fa:2:30:10 LEADING:10 TRAILING:10 SLIDINGWINDOW:2:25 MINLEN:36 &> trimmed_reads/trimmomatic-$name.log" >> run_trimmomatic ``
  
  This line can be modified to change other settings of Trimmomatic as well.
  
  # Usage
  
arguments: 

-h | --help : print a help message and exit

-r | --ref : path to a directory containing the reference sequences. Each sequence must be in a separate fasta file with names such as "ref_sequence.fasta"

-d | --raw : path to a directory containing the raw illumina reads. Each file must be in .fastq.gz format with names such as "sample.fastq.gz"

-w | --work : path to working directory : path to an existing directory where the outputs will be stored 

-P | --phred : phred score below which bases should be masked with a N in the raw reads (used by seqtk)

-t | --threshold : minimum similarity threshold to consider that a read matches the reference sequence (used by vsearch)

-T | --threads : number of threads to use, default = 1

  # Output
  
For each individual present in the raw data directory, the script will create a folder in the working directory containing the following outputs.

For each reference sequences, several files are created with a name in the form ``reference_sequence-in-sample_name``. Four files containing the identifiers of the reads that matched the reference sequence are created: ``*.reads`` contains all the aformetionned identifiers, while ``*.reads.uniq``, ``*.reads.2shared``and ``*.reads.3shared`` contains respectively the reads matching only the given reference, those matching exactly two references and those matching three or more references. These files can be subsequently used to retrieve the reads from the raw data and assemble a consensus sequence (not yet implemented in the present script). Additonnaly, two more outputs are given: ``*.vsearch`` gives the raw output of vsearch, in case manual check is needed; ``*-vsearch.log`` gives the standard output of vsearch, which includes error messages.

Finally, a file named ``summary_sample_name.csv`` is also created. It is a space-delimited table summarizing the whole run, with the following columns: name of reference sequence, name of the sample, number of "unique" matches, number of "2shared" matches and number of "3shared" matches.
  
