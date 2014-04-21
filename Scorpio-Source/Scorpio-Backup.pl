## Scorpio version config //
#
#$sc_v{'Scorpio'}{'version'}	= "5.11.1.2";
#$sc_v{'Scorpio'}{'update'}	= "01/11/05 - 11:03:23";
#$sc_v{'Scorpio'}{'regkey'}	= "0f8243594fd85969fc37ec85bee96346";
#
#$sc_v{'Scorpio'}{'checkVer'}	= 0;
#
#$sc_v{'Scorpio'}{'checkUser'}	= 0;
#$sc_v{'Scorpio'}{'checkGuild'}	= '雙魚&雙子,☆妖靈魅影☆♀Scorpio,☆妖靈魅影☆,☆大無限喵喵團☆,↖~私人海灘~↘,⊙-DISHONEST-CLOTH-⊙';
#
#
## // Scorpio version config

#**                                                                          **
#** Scorpio-Backup      Bluelovers。風      http://bluelovers.idv.st         **
#***                                                                        ***
#***                                                      Version: 5.11.1.2 ***
#***                                          ActivePerl 5.008007 - MSWin32 ***
#***                    Modify By Bluelovers。風 Update 01/11/05 - 11:03:23 ***

#use strict;

use Time::HiRes qw(time usleep);
use Digest::MD5 qw(md5 md5_hex);
use Getopt::Long;
use File::Copy;

our %sc_v;

require 'Scorpio_version.pl';

$sc_v{time}{start} = time;

$sc_v{path}{source} = "Scorpio-Source";
$sc_v{path}{source_now} = "$sc_v{path}{source}/$sc_v{'Scorpio'}{'version'}";

our @Version;
#
#addVersionText("Scorpio-Backup", "Bluelovers。風", "http://bluelovers.idv.st",1);
#getVersionText();
#
#print "$sc_v{versionText}\n";

unless (-e "$sc_v{path}{source}/") {
	mkdir("$sc_v{path}{source}/", 0777) or die "無法產生目錄 $sc_v{path}{source}";
	print "mkdir $sc_v{path}{source}/\n";
}

unless (-e "$sc_v{path}{source_now}/") {
	mkdir("$sc_v{path}{source_now}/", 0777) or die "無法產生目錄 $sc_v{path}{source_now}";
	print "mkdir $sc_v{path}{source_now}/\n";
}

@{$sc_v{files}} = (
	'miscFunctions.pl',
	'fileParser.pl',
	'input.pl',
	'packetParser.pl',
	'math.pl',
	'utils.pl',
	'parseMsg.pl',
	'parseInput.pl',
	'AI.pl',
	'scFunctions.pl',
	'sc_event.pl',
	'ai_funs.pl',
	'ai_route.pl',
	'ai_npc.pl',
	'ai_cmd.pl',
	'Scorpio_version.pl',
	'Scorpio.pl',
	'Scorpio_update.pl',
	'Scorpio-2005-make.pl',
	'Scorpio.exe',
	'version.txt',
	'version_data.txt',
	'version-old.txt',
	'Scorpio-Backup.pl',
	'ex_config.txt',
	'ex_config_plus.txt',
	'ex_timeouts.txt',
	'Scorpio-2005-上船版.bat',
	'Scorpio-2005-上船版-確認使用者.bat',
	'Scorpio-2005-測試版.bat',
	'Scorpio-2005-測試版-確認使用者.bat',
	'Scorpio-2005-發布版.bat',
#	'.txt',
#	'.txt',
#	'.txt',
#	'.txt',
	''
);

print "Backup Dir [ $sc_v{path}{source_now}/ ]...\n";

undef %{$sc_v{new}};

undef $sc_v{temp}{i};

$sc_v{temp}{i} = 0;

foreach (sort @{$sc_v{files}}) {
	next unless (-e $_);
	
	$sc_v{temp}{file_now} = $_;
	$sc_v{temp}{file_new} = "$sc_v{path}{source_now}/$_";
	
	print "\tBackup File [ $sc_v{temp}{file_now} ]...";
	copy($sc_v{temp}{file_now}, $sc_v{temp}{file_new});
	
	$sc_v{temp}{md5_now} = getMD5File($sc_v{temp}{file_now});
	$sc_v{temp}{md5_new} = getMD5File($sc_v{temp}{file_new});
	
	unless (-e $sc_v{temp}{file_new}) {
		print "\n\t-\tError: File Copy!!";
	}
	
#	print "MD5: ";
	
	if ($sc_v{temp}{md5_now} eq $sc_v{temp}{md5_new}) {
#		print "OK";
	} else {
		print "\n\t-\tError: MD5!!";
	}
	
	undef %{$sc_v{new}{$sc_v{temp}{file_now}}};
	
	$sc_v{new}{$sc_v{temp}{file_now}}{size} = getFileSize($sc_v{temp}{file_new});
	$sc_v{new}{$sc_v{temp}{file_now}}{MD5} = $sc_v{temp}{md5_new};
	
#	print "$sc_v{new}{$sc_v{temp}{file_now}}{size} = ".getSize($sc_v{new}{$sc_v{temp}{file_now}}{size});
	
	print "\n";
	
	$sc_v{temp}{i}++;
}

$sc_v{temp}{num_files} = $sc_v{temp}{i};

print "End Backup ($sc_v{temp}{num_files}) Files\n";

$sc_v{path}{backup_now} = "$sc_v{path}{source}/backup.txt";
$sc_v{path}{backup_new} = "$sc_v{path}{source_now}/backup.txt";

print "Backup Info [ $sc_v{path}{backup_new} ]...\n";

open(FILE, "> $sc_v{path}{backup_new}");

undef $sc_v{temp}{i};
$sc_v{temp}{i} = 0;

foreach (sort %{$sc_v{new}}) {
	next unless (%{$sc_v{new}{$_}});
	
	$sc_v{temp}{size} = getSize($sc_v{new}{$_}{size});
	
	print FILE <<"EOM";

backup_File $_ {
	size	$sc_v{temp}{size} ($sc_v{new}{$_}{size} bytes)
	MD5	$sc_v{new}{$_}{MD5}
}
EOM
;

	$sc_v{temp}{i}++;
}

print FILE "\nbackup_Files $sc_v{temp}{i}\n";

print FILE "\n";

close FILE;

print "End Backup Info ($sc_v{temp}{i}) Files\n";

my ($a, $b) = times;
print qq"系統負荷 : ( $a usr \+ $b sys \= " . ($a + $b) . qq" CPU)\n";
print qq"花費時間 : " . getSpend($sc_v{time}{start}, time) . "\n";

sub getMD5File {
	my $file = shift;
	my $ctx = Digest::MD5->new;

	open(FILE, "$file");
	binmode(FILE);
	$ctx->addfile(*FILE);
	close FILE;

	return $ctx->hexdigest;
}

sub getFileSize {
	my $file = shift;
	my $size;
	
	open(FILE, "$file");
	binmode(FILE);
	foreach (<FILE>) {
		$size += length($_);
	}
	close FILE;
	
	return $size;
}

sub getSize {
	my $size = shift;
	my @arg	= ("bytes", "KB", "MB", "GB");
	my $i = 0;

	while ($size > 1024) {
		$i++;
		$size /= 1024;
	}

	if ($i) {
		$size = sprintf("%.2f %s", $size, $arg[$i]);
	} else {
		$size = sprintf("%d %s", $size, $arg[$i]);
	}

#	$size .= " - $i";

	return $size;
}

sub getSpend {
	my ($spend_s, $spend_e, $mode) = @_;
	my ($w_sec, $w_hour, $w_min, $val, @arg);
	$w_sec = abs($spend_e - $spend_s);

	if ($w_sec >= 3600) {
		$w_hour = int($w_sec / 3600);
		$w_sec %= 3600;
	}

	if ($w_sec >= 60) {
		$w_min = int($w_sec / 60);
		$w_sec %= 60;
	}

	$w_hour = "0" . $w_hour if ($mode && $w_hour < 10);
	$w_min = "0" . $w_min if ($mode && $w_min < 10);
	$w_sec = "0" . $w_sec if ($mode && $w_sec < 10);

	push @arg, "$w_hour 小時" if ($w_hour > 0);
	push @arg, "$w_min 分" if ($w_min > 0);
	push @arg, "$w_sec 秒" if ($w_sec > 0);

	$val = join(/ /, @arg);

	return $val;
}

sub getVersionText {
	my $mod = "unknow";
	my $value;
	my $text;

	my $show = "** @<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< **";

	$value .= swrite($show, []);

	foreach (@Version){
		$text = swrite($show, [$$_{'version'}, $$_{'name'}, $$_{'url'}]);

		if ($$_{'modify'}){
			$mod = $$_{'name'};
			#$welcomeText = " ★☆ Welcome to $$_{'version'} - $$_{'name'} - $$_{'url'} ☆★ ";
			$sc_v{'welcomeText'} = " ☆ Welcome to $$_{'version'} - $$_{'name'} - $$_{'url'} ☆ ";
		}

		$value .= $text;
	}

	$show = "*** @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ***";

	$value .= swrite($show
		,[]
		,$show
		,["Version: $sc_v{'Scorpio'}{'version'}"]
		,$show
		,["ActivePerl $] - $^O"]
		,$show
#			,["Modify By $mod Update ".getupdateDay(".")])
		,["Modify By $mod Update $sc_v{'Scorpio'}{'update'}"])
		;

	$sc_v{'versionText'} = $value;

	@Version = [];

	return $value;
}

sub addVersionText {

	my $fields = {};

	$fields->{'version'}	= shift or "";

	return 0 if ($fields->{'version'} eq "");

	$fields->{'name'}	= shift or " ";
	$fields->{'url'}	= shift or " ";
	$fields->{'modify'}	= shift or 0;

	push @Version , $fields;

	return 1;
}

sub swrite {
	my $result = '';
	for (my $i = 0; $i < @_; $i += 2) {
		my $format = $_[$i];
		my @args = @{$_[$i+1]};
		if ($format =~ /@[<|>]/) {
			$^A = '';
			formline($format, @args);
			$result .= "$^A\n";
		} else {
			$result .= "$format\n";
		}
	}
	$^A = '';
	return $result;
}

1;