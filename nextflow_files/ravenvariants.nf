#!/usr/bin/nextflow

GFF = "/home/modupe/.big_ten/chicken/chicken.gff"
tophat = "/usr/local/bin/tophat"
genome = "/home/modupe/.big_ten/chicken/chicken/chicken"
PICARDDIR = "/home/modupe/.software/picard-tools-1.136/picard.jar"
GATKDIR = "/home/modupe/.software/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar"
REF = "/home/modupe/.GENOMES/chicken/chicken.fa"
  

params.ffiles = "bamfiles/SORTED/*sorted*"
params.finalDir = "bamfiles/SORTED"
demuxed = Channel.fromPath(params.ffiles)

groupedDemux = demuxed
                 .map { it -> [ prefix(it), it ]}
                 .groupTuple( sort: true )
                 .map{ prefix, reads ->
                   tuple( prefix, reads[0], reads[1])}

process sortsam {
  tag {prefix}

  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(prefix), file (bam), file(bai) from groupedDemux 

  output:
    set prefix, file ("${bam.name.replaceFirst(/\.sorted.bam/, '_picard.bam')}" ) into SortOut
  
  shell:
    """
    java -jar $PICARDDIR SortSam \
    	INPUT=${bam} \
    	OUTPUT=${bam.name.replaceFirst(/\.sorted.bam/, '_picard.bam')} \
    	SO=coordinate \
	VALIDATION_STRINGENCY=LENIENT
    
    """
}

process addreplace {
  tag {prefix}

  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(prefix), file (bam) from SortOut 

  output:
    set prefix, file ("${bam.name.replaceFirst(/picard.bam/, 'add.bam')}") into AddOut
  
  shell:
    """
    java -jar $PICARDDIR AddOrReplaceReadGroups \
    	INPUT=${bam} \
    	OUTPUT=${bam.name.replaceFirst(/picard.bam/, 'add.bam')} \
    	SO=coordinate VALIDATION_STRINGENCY=LENIENT \
	RGID=LAbel RGLB=Label RGPL=illumina RGPU=Label RGSM=Label
    
    """
}

process markduplicate {
  tag {prefix}

  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(prefix), file (bam) from AddOut 

  output:
    set prefix, \
	file ("${bam.name.replaceFirst(/add.bam/, 'mdup.bam')}"), \
	file ("${bam.name.replaceFirst(/add.bam/, 'mdup.bai')}"), \
    	file ("${bam.name.replaceFirst(/add.bam/, 'mdup.metrics')}") into MarkOut
  
  shell:
    """
    java -jar $PICARDDIR MarkDuplicates \
  		INPUT=${bam} \
    	OUTPUT=${bam.name.replaceFirst(/add.bam/, 'mdup.bam')} \
  		M=${bam.name.replaceFirst(/add.bam/, 'mdup.metrics')} \
  		CREATE_INDEX=true
    """
}

process splitNcigar {
  tag {prefix}

  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(prefix), file (bam), file(bai), file(metrics) from MarkOut 

  output:
    set prefix, \
	file ("${bam.name.replaceFirst(/mdup.bam/, 'split.bam')}"), \
	file ("${bam.name.replaceFirst(/mdup.bam/, 'split.bai')}") into SplitOut
  
  shell:
    """
  
    java -jar $GATKDIR -T SplitNCigarReads \
  		-R $REF \
  		-I ${bam} \
  		-o ${bam.name.replaceFirst(/mdup.bam/, 'split.bam')} \
  		-rf ReassignOneMappingQuality -RMQF 255 -RMQT 60 --filter_reads_with_N_cigar
  		
    """
}

process HaplotypeCaller {
  tag {prefix}

  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(prefix), file (bam), file(bai) from SplitOut

  output:
    set prefix, file ("${prefix}.vcf") into VariantOut
    
  shell:
    """
    java -jar $GATKDIR -T HaplotypeCaller \
  		-R $REF \
  		-I ${bam} \
  		-o ${prefix}.vcf
  		
    """
}


def prefix(fileproc) {
  def procfile = fileproc.getFileName().toString()
  if(procfile =~ /.+-merge\..+/) {
    value = procfile =~ /(.+)-merge\..+/
  }
  return value[0][1]
}

def sample(fileproc) {
  def procfile = fileproc.getFileName().toString()
  if(procfile =~ /.+[_\.][Rr][12].+/) {
    value = procfile =~ /(.+)[_\.][Rr][12].+/
  }
  else if(procfile =~ /.+[_\.][12].+/) {
    value = procfile =~ /(.+)[_\.][12].+/
  }
  else if(procfile =~ /.+[_\.]pe[12]/) {
    value = procfile =~ /(.+)[_\.]pe[12].+/
  }
  else if(procfile =~ /.+[_\.]PE[12]/) {
    value = procfile =~ /(.+)[_\.]PE[12].+/
  }
  return value[0][1]
}

