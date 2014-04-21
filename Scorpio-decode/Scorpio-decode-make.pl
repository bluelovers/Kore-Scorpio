
sub parseDataFile {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key, $value);
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		s/\s+$//g;
		($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
		$key =~ s/\s//g;
		if ($key eq "") {
			($key) = $_ =~ /([\s\S]*)$/;
			$key =~ s/\s//g;
		}
		if ($key ne "") {
			$$r_hash{$key} = $value;
		}
	}
	close(FILE);
}

sub writeDataFileIntact {
	my $file = shift;
	my $r_hash = shift;
	my $data;
	my $key;
	open(FILE, $file);
	foreach (<FILE>) {
		if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
			$data .= $_;
			next;
		}
		($key) = $_ =~ /^(\w+)/;
		$data .= "$key $$r_hash{$key}\n";
	}
	close(FILE);
	open(FILE, "+> $file");
	print FILE $data;
	close(FILE);
}

sub getupdateDay {
	my $sp = shift or "/";
	my $cp = shift || ":";
	my $ap = " - ";
	my $update_day = (stat($0))[9];
	my @localtime = localtime $update_day;
	$localtime[4]++;
	$localtime[5] %=100;

	for (my $i=0; $i<@localtime; $i++){
		$localtime[$i] = "0".$localtime[$i] if ($localtime[$i] < 10);
	}

#	return "$localtime[3]".$sp."$localtime[4]".$sp."$localtime[5]";
	return $localtime[3].$sp.$localtime[4].$sp.$localtime[5].$ap.$localtime[2].$cp.$localtime[1].$cp.$localtime[0];
}

use Time::HiRes qw(time usleep);
use Digest::MD5 qw(md5 md5_hex);
use Getopt::Long;

my %sc_v;

my $mode = 'test';

parseDataFile 'version_data.txt', \%version;

#print $version{'regkey'};

ver_add();

%make = (
	icon => "icon.ico"
	, CompanyName => '"BLUELOVERS"'
	, FileDescription => '"Ragnarok Online Bot"'
	, LegalCopyright => '"BLUELOVERS"'
	, LegalTrademarks => '"BLUELOVERS"'
	, FileVersion => $version{'version'}
	, InternalName => '"Scorpio-decode"'
	, OriginalFilename => '"Scorpio-decode"'
	, ProductName => '"Scorpio-decode"'
	, ProductVersion => $version{'version'}
	, output => "Scorpio-decode.exe"
	, input => "Scorpio-decode.pl"
);

print <<EOM;

	Scorpio - BLUELOVERS

	Version		$version{'version'}
	UpDate		$version{'update'}

EOM
;

print "	開始進行編譯.";

open(FILE, "> version.pl");

print FILE <<EOM;
# Scorpio version config //

\$sc_v\{'Scorpio'\}\{'version'\}	= "$version{'version'}";
\$sc_v\{'Scorpio'\}\{'update'\}	= "$version{'update'}";

# // Scorpio version config
EOM
;

close(FILE);

my $tmp = "--icon $make{'icon'} --info CompanyName=$make{'CompanyName'};FileDescription=$make{'FileDescription'};LegalCopyright=$make{'LegalCopyright'};LegalTrademarks=$make{'LegalTrademarks'};FileVersion=$make{'FileVersion'};InternalName=$make{'InternalName'};OriginalFilename=$make{'OriginalFilename'};ProductName=$make{'ProductName'};ProductVersion=$make{'ProductVersion'} --force -o=$make{'output'} $make{'input'}";

#$tmp = "--xclude $tmp";

print ".\n".("-"x79)."\n";

print `perlapp $tmp`;

print "".("-"x79)."\n";

$version{'MD5'} = getMD5File($make{'output'});

print "\tMD5\t\t$version{'MD5'}\n";

writeDataFileIntact 'version_data.txt', \%version;

open(FILE, "> version.txt");

print FILE <<EOM;
# Scorpio version config //

version	$version{'version'}
update	$version{'update'}
MD5	$version{'MD5'}

# // Scorpio version config
EOM

close(FILE);

print "\t完成.";

sub getMD5File {
	my $file = shift;
	my $ctx = Digest::MD5->new;

	open(FILE, "$file");
	binmode(FILE);
	$ctx->addfile(*FILE);
	close FILE;

	return $ctx->hexdigest;
}

sub ver_add {
	my @localtime = localtime time;

	$localtime[4]++;
	$localtime[5] %=100;

	my @old_ver = split(/\./, $version{'version'});

	my $new_ver = 0;

	#print "\n$old_ver[0].$old_ver[1].$old_ver[2].$old_ver[3]";

	if ($localtime[5] == $old_ver[0] && $localtime[4] == $old_ver[1] && $localtime[3] == $old_ver[2]) {
		$new_ver = $old_ver[3] + 1;
	}

	my $sp = "/";
	my $cp = ":";
	my $ap = " - ";

	my %old = %version;

	if ($mode eq 'test') {

		$version{'old_version'} = $old{'version'};
		$version{'old_update'} = $old{'update'};
		$version{'old_regkey'} = $old{'regkey'};
		$version{'old_chkkey'} = $old{'chkkey'};
		$version{'old_MD5'} = $old{'MD5'};

	}

	$version{'version'} = "$localtime[5].$localtime[4].$localtime[3].$new_ver";

	for (my $i=0; $i<@localtime; $i++){
		$localtime[$i] = "0".$localtime[$i] if ($localtime[$i] < 10);
	}

	my $ex_key = encrypt('Bluelovers。風 bluelovers.no-ip.info');

	$version{'regkey'} = md5_hex($old{'version'}.$old{'chkkey'}.$version{'version'}.$ex_key);
	$version{'chkkey'} = encrypt($version{'regkey'});

	#print "\n".$version{'regkey'}."\n";

	$version{'update'} = "$localtime[3]$sp$localtime[4]$sp$localtime[5]$ap$localtime[2]$cp$localtime[1]$cp$localtime[0]";

	#return "\n$localtime[5].$localtime[4].$localtime[3].\n";
}


#----------------#
#  密碼編碼處理  #
#----------------#
sub encrypt {
	local($inpw) = $_[0];
	local($salt, $encrypt, @char);

	# 文字列定義
	@char = ('a'..'z', 'A'..'Z', '0'..'9', '.', '/');

	# 亂數生成核對碼
	srand;
	$salt = $char[int(rand(@char))] . $char[int(rand(@char))];

	# 編碼
	$encrypt = crypt($inpw, $salt) || crypt ($inpw, '$1$' . $salt);
	return $encrypt;
}

#----------------#
#  密碼驗證處理  #
#----------------#
sub decrypt {
	local($inpw, $enpw) = @_;
	local($salt, $key, $check);

	# 取出核對碼
	$salt = $enpw =~ /^\$1\$(.*)\$/ && $1 || substr($enpw, 0, 2);

	# 驗證處理
	if (crypt($inpw, $salt) eq $enpw || crypt($inpw, '$1$' . $salt) eq $enpw) {
		return (1);
	} else {
		return (0);
	}
}

1;