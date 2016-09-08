#!/usr/bin/nextflow

GFF = "/home/modupeore17/.big_ten/chicken/chicken.gff"
tophat = "/usr/local/bin/tophat"
genome = "/home/modupeore17/.big_ten/chicken/chicken/chicken"


params.finalDir = "filesvcf"


groupedDemux = demuxed
		.map {it -> [sample(it), it ]}
		.groupTuple (sort:true)
		.map{ sample, reads -> tuple (sample, reads[0]) }

process copy {
  tag { sample }
  
  publishDir "${params.finalDir}", mode: 'link'

  output:
    file '*' into mergeOut
  
  shell:
    """
    cp -rf ${workflow.launchDir}/${params.finalDir}/${sample}-tophat_out/accepted_hits.bam ${sample}-accepted_hits.bam

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
