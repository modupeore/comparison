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

# = = = = PICARD = = = = = = = = 
#echo "Sortsam"
#java -jar $PICARDDIR SortSam \
#    	INPUT=$path/$sample-merge.sorted.bam \
#    	OUTPUT=$path/$sample-merge_picard.bam \
#    	SO=coordinate \
#	VALIDATION_STRINGENCY=LENIENT
    

# = = = = HAPLOTYPE CALLER = = = = = = = =    
echo "Haplotype caller"
java -jar $GATKDIR -T HaplotypeCaller \
  	-R $REF \
  	-I $path/$sample-merge_split.bam \
  	-o $path/$sample-new.vcf \
	-dontUseSoftClippedBases \
	-stand_call_conf 20.0 \
	-stand_emit_conf 20.0

echo "======================="
echo end JOB_ID `date`
