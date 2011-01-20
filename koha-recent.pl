#!/usr/bin/perl

use strict;
use C4::Context;
use CGI;
use Business::ISBN;
use YAML::XS;

my $config = do{local(@ARGV,$/)="conf/config.yml";<>};
my $conf = Load $config;

my $sqlNumGet = $ARGV[0];
my $sqlNumShow = $ARGV[1];
my $layout = $ARGV[2];
my $target = $ARGV[3];

my $dbh = C4::Context->dbh();

my $isbn;
my $isbn10;
my $amazonImg;

my $sqlQuery = "SELECT * FROM (SELECT aqorders.biblionumber AS bnum, biblio.title, biblio.author, biblioitems.isbn FROM aqorders,biblio,biblioitems WHERE biblioitems.biblionumber=aqorders.biblionumber AND biblio.biblionumber=aqorders.biblionumber ORDER BY datereceived DESC LIMIT 25) AS recent ORDER BY rand() LIMIT " . $sqlNumShow . ";";

my $uni = $dbh->prepare("set names utf8;");
my $sth = $dbh->prepare($sqlQuery);
$uni->execute();
$sth->execute();

my $query;
if ($layout eq 'html') {
    $query = new CGI;
    print $query->header(-charset=>'utf-8');
    print $query->start_html(-encoding=>'utf-8');
}
print <<CSS;
<style type="text/css">
td { font-family: Arial, Verdana; font-size: 12px; }
p.cover { height: 185px; width: 150px; background: url($conf->{'coverBgUrl'}) no-repeat center; align: center; }
</style>
CSS
print "\t<table width=\"100%\">\n\t\t<tr>\n\t\t\t";

while (my $ref = $sth->fetchrow_hashref()) {
  if (defined($ref->{'isbn'})) {
    $isbn = Business::ISBN->new($ref->{'isbn'});
    $isbn = $isbn->as_isbn10;
    $isbn10 = $isbn->isbn;
    $amazonImg = '<img src="http://images.amazon.com/images/P/'. $isbn10 .'.01._THUMBZZZ_PB_PU_PU0_.jpg" alt="" border="0" />'; 
  } else {
    $isbn10 = '';
    $amazonImg = '';
  }
  $ref->{'title'} =~ s/\ (:|\/)$//g;
print <<MAIN
			<td valign="top" width="20" align="center" border="0">
				<p class="cover"><a border="0" target="_$target" href="$conf->{'kohaOpacUrl'}/opac-detail.pl?biblionumber=$ref->{'bnum'}">$amazonImg</a></p>
				<br />
				<a border="0" target="_$target" href="$conf->{'kohaOpacUrl'}/opac-detail.pl?biblionumber=$ref->{'bnum'}"><b>$ref->{'title'}</b></a>
				<br />
				$ref->{'author'}
			</td>
MAIN

}

print "\n\t\t</tr>\n\t</table>\n";

if ($layout eq 'html') {
    print $query->end_html;
}

$sth->finish();

# Disconnect from the database.
$dbh->disconnect();
