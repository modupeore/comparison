#!/usr/bin/perl
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - H E A D E R - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# MANUAL for extracting stuff from the database
#10/26/2015

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - U S E R  V A R I A B L E S- - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
use strict;
use DBI;

# DATABASE ATTRIBUTES
my $dsn = 'dbi:mysql:transcriptatlas';
my $user = 'frnakenstein';
my $passwd = 'maryshelley';
open(OUT,">whatIwant.txt");

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - G L O B A L  V A R I A B L E S- - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
my ($dbh, $sth); my %HashDirectory;
# CONNECT TO THE DATABASE
print "\n\n\tCONNECTING TO THE DATABASE : $dsn\n\n";
$dbh = DBI->connect($dsn, $user, $passwd) or die "Connection Error: $DBI::errstr\n";
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - M A I N - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# CONNECT
#GETTING ALL THE LIBRARIES FROM THE DATABASE.
#my $syntax= "select a.gene_name, group_concat(a.library_id) from variants_annotation a join vw_libraryinfo b on a.library_id = b.library_id where b.species like \"gall%\" group by a.gene_name";

#my $syntax = "select a.library_id, c.line, c.tissue,a.gene_short_name, concat(a.chrom_no,':',a.chrom_start,'-',a.chrom_stop),
#		a.fpkm, b.ref_allele, b.alt_allele, b.quality from genes_fpkm a join 
#		variants_result b on a.library_id = b.library_id join vw_libraryinfo c on a.library_id = c.library_id
#		where a.chrom_no = \"chr10\" and a.gene_short_name = \"IGF1R\" and b.chrom=\"chr10\" 
#		and b.ref_allele = \"C\" and b.alt_allele = \"CT\" and b.position = 16191296 
#		group by a.library_id";

#my $syntax = "select a.library_id, c.line,c.tissue, a.gene_short_name, concat(a.chrom_no,':',a.chrom_start,'-',a.chrom_stop), 
#a.fpkm from genes_fpkm a join vw_libraryinfo c on a.library_id = c.library_id
#where a.chrom_no = \"chr10\" and a.gene_short_name = \"IGF1R\" group by a.library_id";

#my $syntax = "select group_concat(library_id), chrom, position, group_concat(distinct ref_allele), group_concat(distinct alt_allele),
#		group_concat(quality), count(library_id) from variants_result where library_id between 1321 and 1328 and
#		variant_class = \"SNV\" group by chrom, position";

#my $syntax = "select group_concat(distinct a.library_id), a.chrom, a.position, group_concat(distinct ref_allele), group_concat(distinct alt_allele),
#                group_concat(distinct quality), group_concat(distinct consequence), group_concat(distinct b.gene_id), group_concat(distinct b.gene_name), 
#		count(distinct a.library_id), count(distinct consequence) from variants_result a left outer join variants_annotation b on 
#		a.library_id = b.library_id and a.chrom = b.chrom and a.position = b.position where a.library_id between 1330 and 1337 and
#               variant_class = \"SNV\" group by a.chrom, a.position";


my $syntax = "select group_concat(distinct a.library_id), a.chrom, a.position, group_concat(distinct ref_allele), group_concat(distinct alt_allele),
                group_concat(distinct quality), group_concat(distinct consequence), group_concat(distinct b.gene_id), group_concat(distinct b.gene_name),
                count(distinct a.library_id), count(distinct consequence) from variants_result a left outer join variants_annotation b on
                a.library_id = b.library_id and a.chrom = b.chrom and a.position = b.position join vw_libraryinfo c on a.library_id = c.library_id where c.line like \"Ugandan\" and
                variant_class = \"SNV\" group by a.chrom, a.position";

$sth = $dbh->prepare($syntax);
$sth->execute or die "SQL Error: $DBI::errstr\n";

#TABLE FORMAT
my $i = 0;
while ( my @row = $sth->fetchrow_array() ) {
	$i++;
	foreach my $jj (0..$#row-1){
		print OUT "$row[$jj]\t";
	}
	print OUT "$row[$#row]\n";
}
print "Total number of rows $i\n";
close (OUT);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
print "\n\n*********DONE*********\n\n";
# - - - - - - - - - - - - - - - - - - EOF - - - - - - - - - - - - - - - - - - - - - -
exit;
