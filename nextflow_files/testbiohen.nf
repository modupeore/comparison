#!/usr/bin/nextflow

params.homedir = "/home/amodupe"
GFF = params.homedir + "/.big_ten/chicken/chicken.gff"
tophat = "/usr/local/bin/tophat"
genome = params.homedir + "/.big_ten/chicken/chicken/chicken"
PICARDDIR = params.homedir + "/.software/picard-tools-1.136/picard.jar"
GATKDIR = params.homedir + "/.software/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar"
REF = params.homedir + "/.GENOMES/chicken/chicken.fa"
samtools = "/usr/bin/samtools"

params.ffiles = "/work/amodupe/comparison/bamfiles/SORTED/*sorted*"
params.finalDir = "SORTED"
demuxed = Channel.fromPath(params.ffiles)

groupedDemux = demuxed
                 .map { it -> [ prefix(it), it ]}
                 .groupTuple( sort: true )
                 .map{ prefix, reads ->
                   tuple( prefix, reads[0], reads[1])}
process inputIn {
   tag {prefix}
   cpus 1
   clusterOptions = clusterOptions

   publishDir "${params.finalDir}", mode: 'link'

   input:
     set val(prefix), file (bam), file(bai) from groupedDemux

   output:
     file '*' into inputOut

   shell:
     """
     $samtools idxstats ${bam} >${prefix}.idx.txt
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

