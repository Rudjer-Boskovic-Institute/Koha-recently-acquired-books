#!/usr/bin/perl

use strict;
use DBI();
use Business::ISBN;
use YAML::XS;
use Data::Dumper;
use File::Basename;

my $config = do{local(@ARGV,$/)="conf/config.yml";<>};
my $conf = Load $config;

my $sqlNumGet = $ARGV[0];
my $sqlNumShow = $ARGV[1];
my $layout = $ARGV[2];
my $target = $ARGV[3];

my $dbh = DBI->connect("DBI:mysql:database=$conf->{'dbName'};host=$conf->{'dbHost'}",
                       $conf->{'dbUser'}, $conf->{'dbPass'},
                       {'RaiseError' => 1});

my $isbn;
my $isbn10;
my $amazonImg;

my $sqlQuery = "select * from (select aqorders.biblionumber as bnum, biblio.title, biblio.author, biblioitems.isbn from aqorders,biblio,biblioitems where biblioitems.biblionumber=aqorders.biblionumber and biblio.biblionumber=aqorders.biblionumber order by datereceived desc limit 25) as recent order by rand() limit " . $sqlNumShow . ";";

my $uni = $dbh->prepare("set names utf8;");
my $sth = $dbh->prepare($sqlQuery);
$uni->execute();
$sth->execute();


if ($layout eq 'html') {
print <<HEADER;
<html>
  <head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  </head>
<body>
HEADER
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
print <<FOOTER;
</body>
</html>
FOOTER
}

$sth->finish();

# Disconnect from the database.
$dbh->disconnect();
