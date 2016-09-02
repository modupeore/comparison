#! usr/bin/perl
use File::Basename;

#OBJECTIVE
#continuation of tabulationSNPS-2.pl
print "\n\tFrequency of annotations called from Tabulated file\n";

my $input = $ARGV[0];
my $i= 0;
unless(open(FILE,$input)){
	print "File \'$input\' doesn't exist\n";
	exit;
}

my @file = <FILE>;
chomp @file;
close (FILE);
my $count = 0;
my %Hashdetails;
foreach my $chr (@file){
	if ($chr =~ /^\d/){
		my @chrdetails = split('\t', $chr);
		my $chrIwant = $chrdetails[$ARGV[1]];
		my @morechrsplit = split('\(', $chrIwant);
		$Hashdetails{$morechrsplit[0]} = 0;
  if($morechrsplit[0] == $ARGV[2]){print "\n$chr\n";die;}
	}
}

foreach my $newcount (@file){
        if ($newcount =~ /^\d/){
                my @details = split('\t', $newcount);
                my $chragain = $details[$ARGV[1]];
                my @morechr = split('\(', $chragain);
                $Hashdetails{$morechr[0]} ++; $count++;
		#print $count++."\t$details[0]\t$details[1]\t\t$morechr[0]\t$Hashdetails{$morechr[0]}\n";
        }
}

print "ABC\n";
foreach my $newkey (sort keys %Hashdetails){
	print "$newkey\t$Hashdetails{$newkey}\n";
}

print "\n$count\n";
exit;
