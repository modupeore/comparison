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
params.vfiles = "/work/amodupe/comparison/filesvcf/variants_files/" + params.finalDir + "/*vcf"

demuxed = Channel.fromPath(params.vfiles)

groupedDemux = demuxed
                 .map { it -> [ prefix(it), it ]}
                 .groupTuple( sort: true )
                 .map{ prefix, reads ->
                   tuple( prefix, reads[0] ) }
groupedDemux.tap{group1}
            .tap{group2}

process changes {
  tag {prefix}
  publishDir "${params.finalDir}", mode: 'link'
  
  input:
    set val(prefix), file (vcf) from group1

  output:
    set val(prefix),file ("${prefix}-${params.finalDir}_PASS.vcf") into PassOut

  shell:
    """
    $changes "${prefix}-${params.finalDir}.vcf" ./
    """
}

PassOut.tap{PassOut1}
       .tap{PassOut2}
       
process select {
  tag { prefix }
  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(prefix), file (vcf) from PassOut1

  output:
    set val(prefix),file ("${prefix}-${params.finalDir}-raw_snp.vcf"), \
	file ("${prefix}-${params.finalDir}-raw_indel.vcf")  into selectOut

  shell:
    """
    java -jar $GATKDIR \
        -T SelectVariants \
	-R ${REF} \
	-V ${vcf} \
	-selectType SNP \
	-o ${prefix}-${params.finalDir}-raw_snp.vcf

    java -jar $GATKDIR \
        -T SelectVariants \
        -R ${REF} \
        -V ${vcf} \
        -selectType INDEL \
        -o ${prefix}-${params.finalDir}-raw_indel.vcf
    """
}

selectOut.tap {selectOut1}
         .tap {selectOut2}
         .tap {selectOut3}	

process filter {
  tag {prefix}

  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(prefix), file (snp), file(indel) from selectOut1

  output:
    file '*' into filterSNPOut
  
  shell:
    """
    java -jar $GATKDIR \
	-T VariantFiltration \
	-R $REF \
	-V ${snp} \
	--filterExpression "QD < 2.0 || MQ < 40.0 || DP <5 || MQRankSum < -12.5 || FS > 60.0 || ReadPosRankSum < -8.0" \
	--filterName "FAIL" \
	-o ${prefix}-${params.finalDir}-filtered_snp.vcf

    java -jar $GATKDIR \
        -T VariantFiltration \
        -R $REF \
        -V ${indel} \
        --filterExpression "QD < 2.0 || MQ < 40.0 || DP <5 || FS > 200.0 || ReadPosRankSum < -20.0" \
        --filterName "FAIL" \
        -o ${prefix}-${params.finalDir}-filtered_indel.vcf
    """
}

process filter_new {
  tag {prefix}

  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(prefix), file (snp), file(indel) from selectOut2

  output:
    file '*' into filterIndelOut

  shell:
    """
    java -jar $GATKDIR \
        -T VariantFiltration \
        -R $REF \
        -V ${snp} \
        --filterExpression "QD < 2.0 || MQ < 40.0 || DP <5 || MQRankSum < -12.5 || FS > 30.0 || ReadPosRankSum < -8.0" \
        --filterName "FAIL" \
        -o ${prefix}-${params.finalDir}-filtered_snp30.vcf

    java -jar $GATKDIR \
        -T VariantFiltration \
        -R $REF \
        -V ${indel} \
        --filterExpression "QD < 2.0 || MQ < 40.0 || DP <5 || FS > 60.0 || ReadPosRankSum < -20.0" \
        --filterName "FAIL" \
        -o ${prefix}-${params.finalDir}-filtered_indel60.vcf
    """
}
/*
process stats {
  tag {prefix}
  publishDir "${params.finalDir}", mode: 'link'
 
  input:
    set val(prefix), file (vcf) from group2
    file '*' from PassOut2
    file '*' from selectOut3
    file '*' from filterSNPOut
    file '*' from filterIndelOut


  output:
    file '*' into output

  shell:
    """
    #Total READS
    echo "Total reads \t" > ${params.finalDir}-${prefix}.zzz
    grep "^chr" ${prefix}-${params.finalDir}.vcf | wc -l >> ${params.finalDir}-${prefix}.zzz
    
    #NOT RANDOM
    echo "Total not random \t" >> ${params.finalDir}-${prefix}.zzz
    grep "^chr" ${prefix}-${params.finalDir}_PASS.vcf | wc -l >> ${params.finalDir}-${prefix}.zzz
    
    #COUNT
    echo "Total SNPS \t" >> ${params.finalDir}-${prefix}.zzz
    grep "^chr" "${prefix}-${params.finalDir}-raw_snp.vcf" | wc -l >> ${params.finalDir}-${prefix}.zzz
    echo "Total INDEL \t" >> ${params.finalDir}-${prefix}.zzz
    grep "^chr" "${prefix}-${params.finalDir}-raw_indel.vcf" | wc -l >> ${params.finalDir}-${prefix}.zzz
  
    #COUNT
    echo "Total SNPS filtered \t" >> ${params.finalDir}-${prefix}.zzz
    grep "PASS" "${prefix}-${params.finalDir}-filtered_snp.vcf" | wc -l >> ${params.finalDir}-${prefix}.zzz
    echo "Total INDEL filtered \t" >> ${params.finalDir}-${prefix}.zzz
    grep "PASS" "${prefix}-${params.finalDir}-filtered_indel.vcf" | wc -l >> ${params.finalDir}-${prefix}.zzz
 
    #COUNT
    echo "Total SNPS filtered 30 \t" >> ${params.finalDir}-${prefix}.zzz
    grep "PASS" "${prefix}-${params.finalDir}-filtered_snp30.vcf" | wc -l >> ${params.finalDir}-${prefix}.zzz
    echo "Total INDEL filtered 60 \t" >> ${params.finalDir}-${prefix}.zzz
    grep "PASS" "${prefix}-${params.finalDir}-filtered_indel60.vcf" | wc -l >> ${params.finalDir}-${prefix}.zzz
    
    """ 
}  
 */   
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
