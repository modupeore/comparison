#!/usr/bin/perl

$newdir = $ARGV[0]; 
opendir(DIR, $newdir);
my @Directory = readdir(DIR); close(DIR);
foreach my $folder (@Directory){
  if ($folder =~ /[A-Z]/){
    my $executemerge="
time \\
java -jar ~/.software/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar \\
-T CombineVariants \\
-R ~/.GENOMES/chicken/chicken.fa \\
";

    $newfolder = "$newdir$folder/";
    opendir(FDIR, "$newfolder");
    my @FDirectory = readdir(FDIR); close(FDIR); 
    foreach my $FILE (@FDirectory) { 
      if ($FILE =~ /(\d+).*.filtered_indel_PASS.vcf$/){
        $executemerge .= "--variant:$1 $newfolder$FILE \\\n";
      }
    }
    $executemerge .= "-o $newdir"."mergevcf/merge_indel-".$folder.".vcf -genotypeMergeOptions UNIQUIFY\n";
    print $executemerge;
    `$executemerge`;
  }
}
