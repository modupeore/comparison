#!/usr/bin/nextflow
//NOTE: Filter variants based on DP, QD, MQ, MQRankSum, ReadPosRankSum, FS 
//This is done on Raven

params.homedir = "/home/modupe"
GFF = params.homedir + "/.big_ten/chicken/chicken.gff"
tophat = "/usr/local/bin/tophat"
genome = params.homedir + "/.big_ten/chicken/chicken/chicken"
REF = params.homedir + "/.GENOMES/chicken/chicken.fa"
GATKDIR = params.homedir + "/.software/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar"


params.vfiles = "/home/modupe/LSRH/comparison/filesvcf/variants_files/mergevcf/*vcf"
params.finalDir = "Filtered"

demuxed = Channel.fromPath(params.vfiles)

groupedDemux = demuxed
                 .map { it -> [ middle(it), it ]}
                 .groupTuple( sort: true )
                 .map{ middle, reads ->
                   tuple( middle, reads[0] ) }

process filter {
  tag {middle}

  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(middle), file (vcf) from groupedDemux

  output:
    file '*' into filterOut
  
  shell:
    """
    java -jar $GATKDIR \
	-T VariantFiltration \
	-R $REF \
	-V ${vcf} \
	--filterExpression \"QD < 2.0 || MQ < 40.0 || DP < 5 || MQRankSum < -12.5 || FS > 60.0 || ReadPosRankSum < -8.0\" \
	--filterName "my_snp_filter" \
	-o ${middle}_filtered.vcf

    """
}


def middle(fileproc) {
  def procfile = fileproc.getFileName().toString()
  if(procfile =~ /merge-(.+)\..+/) {
    value = procfile =~ /merge-(.+)\..+/
  }
  return value[0][1]
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
