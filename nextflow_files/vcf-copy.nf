#!/usr/bin/nextflow

GFF = "/home/modupeore17/.big_ten/chicken/chicken.gff"
tophat = "/usr/local/bin/tophat"
genome = "/home/modupeore17/.big_ten/chicken/chicken/chicken"


params.finalDir = "UL"
params.fastq = "/home/modupeore17/COMPARISON/bamfiles/" + params.finalDir + "/*hits.bam"

if (!params.fastq){
	error 'No input reads specified. Please specify parameters "fastq" or "read1" and "read2"'
}
else if ( params.fastq ) {
  demuxed = Channel.fromPath(params.fastq)
  println "Executing pipeline for \"${params.fastq}\""
}
else {
  error 'Please specify parameters "fastq"'
}

groupedDemux = demuxed
		.map {it -> [sample(it), it ]}
		.groupTuple (sort:true)
		.map{ sample, reads -> tuple (sample, reads[0]) }

process copy {
  tag { sample }
  errorStrategy 'ignore' 
  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(sample), file(read1) from groupedDemux

  output:
    file '*' into mergeOut
  
  shell:
    """
    cp -rf /home/modupeore17/modupeore17/CHICKENvariants/LIB*/library_${sample}/library*${sample}.vcf ${sample}-${params.finalDir}.vcf
    cp -rf /home/modupeore17/modupeore17/CHICKENvariants/LIB*/library_${sample}/library*${sample}.vcf.idx ${sample}-${params.finalDir}.vcf.idx

    """
}

def sample(fileproc) {
  def procfile = fileproc.getFileName().toString()
  if(procfile =~ /.+[_\.-].+/) {
    value = procfile =~ /(\d+)[-_\.].+/
  }
  return value[0][1]
}
