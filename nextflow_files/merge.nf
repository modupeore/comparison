#!/usr/bin/nextflow
//NOTE: create samtools sort and index

GFF = "/home/modupeore17/.big_ten/chicken/chicken.gff"
tophat = "/usr/local/bin/tophat"
genome = "/home/modupeore17/.big_ten/chicken/chicken/chicken"


params.folder = "/home/modupeore17/COMPARISON/bamfiles/UL"
params.finalDir = "UL"

allFiles = Channel.fromPath("${params.folder}/*bam").toList()

process merge {
  tag {params.finalDir}

  publishDir "${params.finalDir}", mode: 'link'

  input:
    file '*' from allFiles

  output:
    file '*' into mergeOut
  
  shell:
    """
    samtools merge -nr ${params.finalDir}-merge.bam *bam
    samtools sort ${params.finalDir}-merge.bam ${params.finalDir}-merge.sorted
    samtools index ${params.finalDir}-merge.sorted.bam

    """
}

def sample(fileproc) {
  def procfile = fileproc.getFileName().toString()
  if(procfile =~ /.+[_\.][Rr][12].+/) {
    value = procfile =~ /(\d+)_.*[_\.][Rr][12].+/
  }
  else if(procfile =~ /.+[_\.][12].+/) {
    value = procfile =~ /(\d+)_.*[_\.][12].+/
  }
  else if(procfile =~ /.+[_\.]pe[12]/) {
    value = procfile =~ /(\d+)_.*[_\.]pe[12].+/
  }
  else if(procfile =~ /.+[_\.]PE[12]/) {
    value = procfile =~ /(\d+)_.*[_\.]PE[12].+/
  }
  return value[0][1]
}
