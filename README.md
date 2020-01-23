# Museoscript
# Museoscript

Museoscript is a bash script wrapping several programs, aiming to process High-Throughput Sequencing data from historical specimens, particularly in the context of taxonomy and systematics studies. More in details, this script takes as input raw illumina reads and, after trimming and quality checking, aligns them to a set of reference sequences with vsearch, using an user-specified similarity threshold. It outputs a table summarizing the amount of reads matching each of the reference sequences, as well as the lists of these reads, that can be used to retrieve the sequences from the original data (in order for exemple to assemble consensus sequences). 

# Dependencies
