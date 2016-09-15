#!/usr/bin/nextflow
//NOTE: Filter variants based on DP, QD, MQ, MQRankSum, ReadPosRankSum, FS 
//This is done on Raven

params.homedir = "/home/amodupe"
GFF = params.homedir + "/.big_ten/chicken/chicken.gff"
tophat = "/usr/local/bin/tophat"
genome = params.homedir + "/.big_ten/chicken/chicken/chicken"
REF = params.homedir + "/.GENOMES/chicken/chicken.fa"
GATKDIR = params.homedir + "/.software/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar"
changes = params.homedir + "/workmodupe/RAVEN_scripts/standard/change_variants.pl"
params.finalDir = "ICS"
params.vfiles = "/work/amodupe/comparison/filesvcf/variants_files/" + params.finalDir + "/*vcf.gz"

demuxed = Channel.fromPath(params.vfiles)

groupedDemux = demuxed
                 .map { it -> [ prefix(it), it ]}
                 .groupTuple( sort: true )
                 .map{ prefix, reads ->
                   tuple( prefix, reads[0] ) }

process changes {
  tag {prefix}
  publishDir "${params.finalDir}", mode: 'link'
  
  input:
    set val(prefix), file (vcf) from groupedDemux

  output:
    set val(prefix),file ("${prefix}-${params.finalDir}_PASS.vcf") into PassOut

  shell:
    """
    gunzip ${vcf}
    $changes "${prefix}-${params.finalDir}.vcf" ./
    """
}


process select {
  tag { prefix }
  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(prefix), file (vcf) from PassOut

  output:
    set val(prefix),file ("${prefix}-raw_snp.vcf"), \
	file ("${prefix}-raw_indel.vcf")  into selectOut

  shell:
    """
    java -jar $GATKDIR \
        -T SelectVariants \
	-R ${REF} \
	-V ${vcf} \
	-selectType SNP \
	-o ${prefix}-raw_snp.vcf

    java -jar $GATKDIR \
        -T SelectVariants \
        -R ${REF} \
        -V ${vcf} \
        -selectType INDEL \
        -o ${prefix}-raw_indel.vcf
    """
}

selectOut.tap {selectOut1}
	.tap {selectOut2}

process filter {
  tag {prefix}

  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(prefix), file (snp), file(indel) from selectOut1

  output:
    file '*' into filterOut
  
  shell:
    """
    java -jar $GATKDIR \
	-T VariantFiltration \
	-R $REF \
	-V ${snp} \
	--filterExpression "QD < 2.0 || MQ < 40.0 || DP <5 || MQRankSum < -12.5 || FS > 60.0 || ReadPosRankSum < -8.0" \
	--filterName "FAIL" \
	-o ${prefix}-filtered_snp.vcf

    java -jar $GATKDIR \
        -T VariantFiltration \
        -R $REF \
        -V ${indel} \
        --filterExpression "QD < 2.0 || MQ < 40.0 || DP <5 || FS > 200.0 || ReadPosRankSum < -20.0" \
        --filterName "FAIL" \
        -o ${prefix}-filtered_indel.vcf
    """
}

process filter_new {
  tag {prefix}

  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(prefix), file (snp), file(indel) from selectOut2

  output:
    file '*' into filterOut2

  shell:
    """
    java -jar $GATKDIR \
        -T VariantFiltration \
        -R $REF \
        -V ${snp} \
        --filterExpression "QD < 2.0 || MQ < 40.0 || DP <5 || MQRankSum < -12.5 || FS > 30.0 || ReadPosRankSum < -8.0" \
        --filterName "FAIL" \
        -o ${prefix}-filtered_snp30.vcf

    java -jar $GATKDIR \
        -T VariantFiltration \
        -R $REF \
        -V ${indel} \
        --filterExpression "QD < 2.0 || MQ < 40.0 || DP <5 || FS > 60.0 || ReadPosRankSum < -20.0" \
        --filterName "FAIL" \
        -o ${prefix}-filtered_indel60.vcf
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
  if(procfile =~ /.+-\w+\..+/) {
    value = procfile =~ /(.+)-\w+\..+/
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
