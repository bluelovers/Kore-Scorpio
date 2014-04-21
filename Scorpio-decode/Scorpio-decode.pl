
BEGIN {
	open "STDERR", "> errors.txt" or die "Could not write to errors.txt: $!\n";
}
END {
	exit;
}

our %sc_v;

require 'version.pl';

use Utils::Crypton;
my %config = {};

$config{tag}	= "Scorpio-decode>";
$config{mode}	= 0;

my (@Version);

addVersionText("Scorpio-decode", "Bluelovers。風", "http://bluelovers.idv.st",1);
getVersionText();

@{$config{key}} = split /[, ]+/, $config{encryptKey};

if (!@{$config{key}}) {
	@{$config{key}} = ('0x050B6F79', '0x0202C179', '0x00E20120', '0x04FA43E3', '0x0179B6C8', '0x05973DF2', '0x07D8D6B', '0x08CB9ED9');
}

my $crypton = new Utils::Crypton(pack("V*", @{$config{key}}), 32);
my ($num, $input, $ciphertextBlock);
my @params;
my $inputparam;

print "$sc_v{versionText}\n";

CMD_INPUT:
print "$config{tag} ";
$input = <STDIN>;

@params = parseCmdLine(getString(\$input));
$switch = lc $params[0];
$inputparam = Trim(substr($input, length($switch)));

if ($switch eq "") {
	$config{error} = "輸入值不可為空白";
	
CMD_ERROR_OUTPUT:
	print "Error: $config{error}\n" if ($config{error});
} elsif ($switch =~ /^\d+$/) {
	undef $num;
	undef $ciphertextBlock;
	
	$num = $switch;
	
	if (length($num) > 8) {
		$config{error} = "$num 長度大於 8";
		goto CMD_ERROR_OUTPUT;
	} elsif ($num == 0) {
		$config{error} = "輸入值不可為 0";
		goto CMD_ERROR_OUTPUT;
	}
	
	$num = sprintf("%d%08d", length($num), $num);
	
	$ciphertextBlock = $crypton->encrypt(pack("V*", $num, 0, 0, 0));
	
	print "encrypt[0] : ".getHex($ciphertextBlock, 0)."\n";
	print "encrypt[1] : ".getHex($ciphertextBlock, 1)."\n";
} elsif ($switch eq "quit" || $switch eq "exit") {
#	print "$config{tag} 請按 Enter 鍵結束";
#	<STDIN>;
	exit;
} elsif ($switch eq "version" || $switch eq "ver") {
	print "\n$sc_v{versionText}\n";
} elsif ($switch ne "") {
	$config{error} = "錯誤的指令 $input";
	goto CMD_ERROR_OUTPUT;
}

$config{lasterror} = $config{error};
undef $config{error};

goto CMD_INPUT;

sub Trim {
	my $s = shift;

	$s =~ s/\s+$//g;
	$s =~ s/^\s+//g;

	return $s;
}

sub getString {
	my $s		= shift;
	my $mode	= shift;

	s/\s+/ /g if ($mode);

	$$s =~ s/\s+$//g;
	$$s =~ s/^\s+//g;
	$$s =~ s/[\r\n]//g;

	return $$s;
}

sub toHex {
	my $raw = shift;
	my @raw;
	my $msg;
	@raw = split / /, $raw;
	foreach (@raw) {
#		支援 A6 98 AE 8A 3E 9D B7 92 4F FB AC A4 67 01 C5 4F
#		$msg .= pack("H2", $_);
#		支援 A6 98 AE 8A 3E 9D B7 92 4F FB AC A4 67 01 C5 4F
#		與 A698AE8A3E9DB7924FFBACA46701C54F
		$msg .= pack("H*", $_);
	}
	return $msg;
}

sub getHex {
	my $data = shift;
	my $mode = shift;
	my $i;
	my $return;
	for ($i = 0; $i < length($data); $i++) {
		$return .= uc(unpack("H2",substr($data, $i, 1)));
		if (!$mode && $i + 1 < length($data)) {
			$return .= " ";
		}
	}
	return $return;
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

sub parseCmdLine {
	my $cmd_line = shift;
	my $param;
	my $noquote;
	my @params;
	my $n;

	$n = 0;
	while ($cmd_line ne "") {
		$cmd_line =~ s/\s+$//g;
		$cmd_line =~ s/^\s+//g;

		($param, $noquote) = $cmd_line =~ /^(\"([\s\S]*?)\")/;
		if ($param eq "") {
			($param) = $cmd_line =~ /^(\w*)/;
		}

		$cmd_line = substr($cmd_line, length($param) + 1);

		if ($noquote ne "") {
			if (!$cmd_trim){
				$params[$n] = $noquote;
			} else {
				$params[$n] = Trim($noquote);
			}
		} else {
			$params[$n] = $param;
		}

		$n++;
	}

	return @params;
}

sub isNum {
	my $n = shift;

	if ($n =~ /^\d+$/ ) {
		return 1;
	}

	return 0;
}

1;