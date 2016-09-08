#!/usr/bin/nextflow

GFF = "/home/modupeore17/.big_ten/chicken/chicken.gff"
tophat = "/usr/local/bin/tophat"
genome = "/home/modupeore17/.big_ten/chicken/chicken/chicken"


params.fastq = "/home/modupeore17/COMPARISON/bamfiles/UL/*gz"
params.finalDir = "UL"

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

process align {
  tag { sample }
  
  publishDir "${params.finalDir}", mode: 'link'

  input:
    set val(sample), file(read1) from groupedDemux

  output:
    file '*' into alignmentOut
  
  shell:
    """
    $tophat \
	--no-coverage-search \
	-G $GFF \
	-p 24 -o ${sample}-tophat_out \
	$genome \
	${read1}

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
