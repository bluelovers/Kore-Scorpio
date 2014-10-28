#!perl -w
use Getopt::Long;
use IO::Socket;
use Win32::API;
use Net::FTP;

# small tool to parse item history file and generate simple HTML output
# coded by junq for the (s)kore users - freeware, distribute freely as
# long as credit is given.

# $history_file = "items.txt";
# $html_file = "items.html";
$ftp_host = "ftp.myweb.hinet.net";
$ftp_host = "upload.myweb.hinet.net";
$ftp_username = "";
$ftp_password = "";
$ftp_location = "/kore";
$use_ftp = "Yes";
$ftp_debug = "No";
my $html_file = "version.txt";

if ($use_ftp ne "No") {
	if ($ftp_debug eq "Yes") {
		$ftp = Net::FTP->new("$ftp_host",'Debug',10);
	} elsif ($ftp_debug eq "No") {
		$ftp = Net::FTP->new("$ftp_host");
	}
	print "login\n";
	$ftp->login("$ftp_username","$ftp_password");
	print "cwd $ftp_location\n";
	$ftp->cwd("$ftp_location");
	print "binary\n";
	$ftp->binary();
	print "put Scorpio.exe\n";
	$ftp->put("Scorpio.exe");
	print "ascii\n";
	$ftp->ascii();
	print "put version.txt\n";
	$ftp->put("version.txt");
#	print "binary\n";
#	$ftp->binary();
#	print "put Scorpio.exe\n";
#	$ftp->put("Scorpio.exe");
	print "quit\n";
	$ftp->quit;
}

exit 1;
1;
