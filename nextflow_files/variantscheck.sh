#!/bin/bash
# -N = job name

echo start JOB_ID `date`
echo "======================="

# = = = = VARIABLES = = = = =
path="/work/amodupe/comparison/bamfiles/SORTED"
sample="RHS"
homedir="/home/amodupe"
GFF="$homedir/.big_ten/chicken/chicken.gff"
tophat="/usr/local/bin/tophat"
genome="$homedir/.big_ten/chicken/chicken/chicken"
PICARDDIR="$homedir/.software/picard-tools-1.136/picard.jar"
GATKDIR="$homedir/.software/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar"
REF="$homedir/.GENOMES/chicken/chicken.fa"
ls -la
# = = = = PICARD = = = = = = = = 
#echo "Sortsam"
#java -jar $PICARDDIR SortSam \
#    	INPUT=$path/$sample-merge.sorted.bam \
#    	OUTPUT=$path/$sample-merge_picard.bam \
#    	SO=coordinate \
#	VALIDATION_STRINGENCY=LENIENT
    

# = = = = ADD or REPLACE = = = = = = = = 
echo "AddorReplace"
java -jar $PICARDDIR AddOrReplaceReadGroups \
    	INPUT=$path/$sample-merge_picard.bam \
    	OUTPUT=$path/$sample-merge_add.bam \
    	SO=coordinate VALIDATION_STRINGENCY=LENIENT \
	RGID=LAbel RGLB=Label RGPL=illumina RGPU=Label RGSM=Label
    
# = = = = MARK DUPLICATES = = = = = = = =
echo "MarkDuplicates"
java -jar $PICARDDIR MarkDuplicates \
  	INPUT=$path/$sample-merge_add.bam \
    	OUTPUT=$path/$sample-merge_mdup.bam \
	M=$path/$sample-merge_mdup.metrics \
  	CREATE_INDEX=true


# = = = = SPLIT CIGAR = = = = = = = =    
echo "Split cigar"
java -jar $GATKDIR -T SplitNCigarReads \
  	-R $REF \
  	-I $path/$sample-merge_mdup.bam \
  	-o $path/$sample-merge_split.bam \
  	-rf ReassignOneMappingQuality -RMQF 255 -RMQT 60 --filter_reads_with_N_cigar


# = = = = HAPLOTYPE CALLER = = = = = = = =    
echo "Haplotype caller"
java -jar $GATKDIR -T HaplotypeCaller \
  	-R $REF \
  	-I $path/$sample-merge_split.bam \
  	-o $path/$sample.vcf


echo "======================="
echo end JOB_ID `date`
