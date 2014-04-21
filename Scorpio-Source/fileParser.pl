
our @parseFixer_lut;
our @parseFixerEx_lut;

sub addFixerExValue {
	my ($hash, $key, $value, $mode) = @_;

	return 0 if (!$hash || !$key || !$value);

	my %fields;

	$fields{'hash'}		= $hash;

	$fields{'key'}		= $key;
	$fields{'key2'}		= $value;

	push @parseFixerEx_lut , \%fields;
}

sub parseFixerEx {
	my ($i, $hash, $key, $key2, $mode, $tmpVal);

	for ($i=0; $i<@parseFixerEx_lut; $i++) {
		$hash	= $parseFixerEx_lut[$i]{'hash'};
		$key	= $parseFixerEx_lut[$i]{'key'};
		$key2	= $parseFixerEx_lut[$i]{'key2'};

		if ($hash eq "timeout"){
			${$hash}{$key}{'timeout'} = ${$hash}{$key2}{'timeout'} if (!${$hash}{$key}{'timeout'} && ${$hash}{$key2}{'timeout'});
		} else {
			${$hash}{$key} = ${$hash}{$key2} if (${$hash}{$key} eq "" && ${$hash}{$key2} ne "");
		}
	}
}

sub addFixerValue {
	my ($hash, $key, $value, $mode) = @_;

	return 0 if (!$hash || !$key);

	for ($i=0; $i<@parseFixer_lut; $i++) {
		if ($parseFixer_lut[$i]{'key'} eq $key) {
			$parseFixer_lut[$i]{'hash'}	= $hash;
			$parseFixer_lut[$i]{'key'}	= $key;
			$parseFixer_lut[$i]{'value'}	= $value;
			$parseFixer_lut[$i]{'mode'}	= $mode;

			return 1;
		}
	}

	my %fields;

	$fields{'hash'}		= $hash;

	$fields{'key'}		= $key;
	$fields{'value'}	= $value;
	$fields{'mode'}		= $mode;

	push @parseFixer_lut , \%fields;
}

sub parseFixer {
	my ($i, $hash, $key, $value, $mode, $tmpVal);

	for ($i=0; $i<@parseFixer_lut; $i++) {
		$hash	= $parseFixer_lut[$i]{'hash'};
		$key	= $parseFixer_lut[$i]{'key'};
		$value	= $parseFixer_lut[$i]{'value'};
		$mode	= $parseFixer_lut[$i]{'mode'};
		$tmpVal	= "";

		if ($hash eq "timeout"){
			$tmpVal	= ${$hash}{$key}{'timeout'};

			if ($mode < 0) {
				delete ${$hash}{$key};
			} elsif ($mode > 8) {
				${$hash}{$key}{'timeout'} = $value if ($tmpVal <= 0 || $value <= $tmpVal);
			} elsif ($mode > 7) {
				${$hash}{$key}{'timeout'} = $value if ($tmpVal > 0 && $value > $tmpVal);
			} elsif ($mode > 6) {
				${$hash}{$key}{'timeout'} = $value if ($tmpVal);
			} elsif ($mode > 5) {
				${$hash}{$key}{'timeout'} = $value if ($tmpVal < 1);
			} elsif ($mode > 4) {
				${$hash}{$key}{'timeout'} = $value if ($tmpVal < 0);
			} elsif ($mode > 3) {
				${$hash}{$key}{'timeout'} = $value if ($value < $tmpVal);
			} elsif ($mode > 2) {
				${$hash}{$key}{'timeout'} = $value if ($value >= $tmpVal);
			} elsif ($mode > 1) {
				${$hash}{$key}{'timeout'} = $value;
			} elsif ($mode > 0 && !$tmpVal) {
				${$hash}{$key}{'timeout'} = $value;
			} else {
				${$hash}{$key}{'timeout'} = $value if ($tmpVal eq "");
			}

		} else {
			$tmpVal	= ${$hash}{$key};

			if ($mode < 0) {
				delete ${$hash}{$key};
			} elsif ($mode > 8) {
				${$hash}{$key} = $value if ($tmpVal <= 0 || $value <= $tmpVal);
			} elsif ($mode > 7) {
				${$hash}{$key} = $value if ($tmpVal > 0 && $value > $tmpVal);
			} elsif ($mode > 6) {
				${$hash}{$key} = $value if ($tmpVal);
			} elsif ($mode > 5) {
				${$hash}{$key} = $value if ($tmpVal < 1);
			} elsif ($mode > 4) {
				${$hash}{$key} = $value if ($tmpVal < 0);
			} elsif ($mode > 3) {
				${$hash}{$key} = $value if ($value < $tmpVal);
			} elsif ($mode > 2) {
				${$hash}{$key} = $value if ($value >= $tmpVal);
			} elsif ($mode > 1) {
				${$hash}{$key} = $value;
			} elsif ($mode > 0 && !$tmpVal) {
				${$hash}{$key} = $value;
			} else {
				${$hash}{$key} = $value if ($tmpVal eq "");
			}

		}
	}
}

sub parseGMAIDLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $ip_string;
	my @ip;
	my $AID_string;
	my $i;
	open(FILE, $file);
	foreach (<FILE>) {
#		s/[\r\n]//g;
#		s/\s+$//g;

		getString(\$_);

		next if /^\/\//;
		if (/^#/) {
			undef @array; splitUseArray(\@array, $AID_string, ",");
			for ($i = 0;$i < @ip;$i++) {
				push @{$$r_hash{$ip[$i]}}, @array;
			}
			undef $ip_string;
			undef @ip;
			undef $AID_string;
		} elsif (!$ip_string) {
			($ip_string) = /([\s\S]+)#$/;
			@ip = split /#/, $ip_string;
		} else {
			$AID_string .= $_;
		}
	}
	close(FILE);
}

sub parseDataFile {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key, $value);
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
#		s/[\r\n]//g;
#		s/\s+$//g;

		getString(\$_);

		($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
		if ($key ne "" && $value ne "") {
			$$r_hash{$key} = $value;
		}
	}
	close(FILE);
}

sub parseDataFile_lc {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key, $value);
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
#		s/[\r\n]//g;
#		s/\s+$//g;

		getString(\$_);

		($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
		if ($key ne "" && $value ne "") {
			$$r_hash{lcCht($key)} = $value;
		}
	}
	close(FILE);
}

#sub parseDataFile2 {
#	my $file = shift;
#	my $r_hash = shift;
#	undef %{$r_hash};
#	my ($key, $value);
#	open(FILE, $file);
#	foreach (<FILE>) {
#		next if (/^#/);
##		s/[\r\n]//g;
##		s/\s+$//g;
#
#		getString(\$_, 1);
#
#		($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
##		$key =~ s/\s//g;
#
#		getString(\$key);
#		getString(\$value);
#
#		if ($key eq "") {
#			($key) = $_ =~ /([\s\S]*)$/;
#			$key =~ s/\s//g;
#		}
#		if ($key ne "") {
#			$$r_hash{$key} = $value;
#		}
#	}
#	close(FILE);
#}

sub parseDataFile2 {
	my $file	= shift;
	my $r_hash	= shift;
	undef %{$r_hash};
	my ($key, $value, $line);

	my $plus	= shift;
	my @plus_file;
	my $line;
	@plus_file = glob $plus if ($plus ne "");

	foreach $line ($file, @plus_file) {

#		print "\n$line\n";

		next unless (-e "$line");

		open(FILE, $line);
		foreach (<FILE>) {
			next if (/^#/);

			getString(\$_, 1);

			($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;

			getString(\$key);
			getString(\$value);

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
}

sub parseItemsControl {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,@args);
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
#		s/[\r\n]//g;
#		s/\s+$//g;

		getString(\$_);

		($key, $args) = $_ =~ /([\s\S]+?) (\d+[\s\S]*)/;
#		@args = split / /, $args;

		splitUseArray(\@args, $args, " ");

		if ($key ne "") {
			$key = lcCht($key);

			$$r_hash{$key}{'keep'} = $args[0];
			$$r_hash{$key}{'storage'} = $args[1];
			$$r_hash{$key}{'sell'} = $args[2];
			$$r_hash{$key}{'cart'} = $args[3];
		}
	}
	close(FILE);
}

sub parseNPCs {
	my $file = shift;
	my $r_hash = shift;
	my ($i, $string);
	undef %{$r_hash};
	my ($key, $value);
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
#		s/[\r\n]//g;
#		s/\s+/ /g;
#		s/\s+$//g;

		getString(\$_, 1);

#		@args = split /\s/, $_;

		splitUseArray(\@args, $_, " ");

		if (@args >= 4) {
			$$r_hash{$args[0]}{'map'} = $args[1];
			$$r_hash{$args[0]}{'pos'}{'x'} = $args[2];
			$$r_hash{$args[0]}{'pos'}{'y'} = $args[3];
			$string = $args[4];
			for ($i = 5; $i < @args; $i++) {
				$string .= " $args[$i]";
			}

			$string = "<none>" if ($string eq "");

			$$r_hash{$args[0]}{'name'} = $string;

#			print "$args[0] $args[1] $args[2] $args[3] $string = @args\n";
		}
	}
	close(FILE);
}

sub parseMonControl {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key,@args);
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
#		s/[\r\n]//g;
#		s/\s+$//g;

		getString(\$_);

		($key, $args) = $_ =~ /([\s\S]+?) (-?\d+[\s\S]*)/;
#		@args = split / /, $args;

		splitUseArray(\@args, $args, " ");

		if ($key ne "") {
			$key = lcCht($key);

			$$r_hash{$key}{'attack_auto'} = $args[0];
			$$r_hash{$key}{'teleport_auto'} = $args[1];
			$$r_hash{$key}{'teleport_search'} = $args[2];
			$$r_hash{$key}{'teleport_extra'} = $args[3];
			$$r_hash{$key}{'teleport_extra2'} = $args[4];

#			print "$key, [$$r_hash{lcCht($key)}{'attack_auto'}], [$$r_hash{lcCht($key)}{'teleport_auto'}], [$$r_hash{lcCht($key)}{'teleport_search'}], [$$r_hash{lcCht($key)}{'teleport_extra'}], [$$r_hash{lcCht($key)}{'teleport_extra2'}]\n";
		}
	}
	close(FILE);
}

#sub parsePortals {
#	my $file = shift;
#	my $r_hash = shift;
#	undef %{$r_hash};
#	open FILE, "< $file";
#	while (my $line = <FILE>) {
#		next if $line =~ /^#/;
#		$line =~ s/\cM|\cJ//g;
#		$line =~ s/\s+/ /g;
#		$line =~ s/^\s+|\s+$//g;
#		my @args = split /\s/, $line, 8;
#		if (@args > 5) {
#			my $portal = "$args[0] $args[1] $args[2]";
#			my $dest = "$args[3] $args[4] $args[5]";
#			$$r_hash{$portal}{'source'}{'ID'} = $portal;
#			$$r_hash{$portal}{'source'}{'map'} = $args[0];
#			$$r_hash{$portal}{'source'}{'pos'}{'x'} = $args[1];
#			$$r_hash{$portal}{'source'}{'pos'}{'y'} = $args[2];
#			$$r_hash{$portal}{'dest'}{$dest}{'ID'} = $dest;
#			$$r_hash{$portal}{'dest'}{$dest}{'map'} = $args[3];
#			$$r_hash{$portal}{'dest'}{$dest}{'pos'}{'x'} = $args[4];
#			$$r_hash{$portal}{'dest'}{$dest}{'pos'}{'y'} = $args[5];
#			$$r_hash{$portal}{'dest'}{$dest}{'cost'} = $args[6];
#			$$r_hash{$portal}{'dest'}{$dest}{'steps'} = $args[7];
#		}
#	}
#	close FILE;
#}

#sub parsePortals {
#	my $file = shift;
#	my $r_hash = shift;
#	undef %{$r_hash};
#	my ($key, $value);
#	my %IDs;
#	my $i;
#	my $j = 0;
#	my $nameID;
#	open(FILE, $file);
#	foreach (<FILE>) {
#		next if (/^#/);
##		s/[\r\n]//g;
##		s/\s+/ /g;
##		s/\s+$//g;
#
#		getString(\$_, 1);
#
#		@args = split /\s/, $_;
#		if (@args > 5) {
##			my $portal = "$args[0] $args[1] $args[2]";
##			my $dest = "$args[3] $args[4] $args[5]";
##			$$r_hash{$portal}{'source'}{'ID'} = $portal;
##			$$r_hash{$portal}{'source'}{'map'} = $args[0];
##			$$r_hash{$portal}{'source'}{'pos'}{'x'} = $args[1];
##			$$r_hash{$portal}{'source'}{'pos'}{'y'} = $args[2];
##			$$r_hash{$portal}{'dest'}{$dest}{'ID'} = $dest;
##			$$r_hash{$portal}{'dest'}{$dest}{'map'} = $args[3];
##			$$r_hash{$portal}{'dest'}{$dest}{'pos'}{'x'} = $args[4];
##			$$r_hash{$portal}{'dest'}{$dest}{'pos'}{'y'} = $args[5];
###			$$r_hash{$portal}{'dest'}{$dest}{'cost'} = $args[6];
###			$$r_hash{$portal}{'npc'}{'ID'} = $args[6];
###			$$r_hash{$portal}{'dest'}{$dest}{'steps'} = $args[7];
##
##			if ($args[6] ne "" && $args[6] ne "<none>") {
##				$$r_hash{$portal}{'npc'}{'ID'} = $args[6];
##				for ($i = 7; $i < @args; $i++) {
##					$$r_hash{$portal}{'npc'}{'steps'}[@{$$r_hash{$portal}{'npc'}{'steps'}}] = $args[$i];
##				}
##			}
#
#			$nameID = "$args[0] $args[1] $args[2]";
#
#			$nameID = "$args[0] $args[1] $args[2] $args[3] $args[4] $args[5]" if ($sc_v{'kore'}{'multiPortals'});
#
#			$$r_hash{$nameID}{'nameID'} = "$args[0] $args[1] $args[2]";
#			$IDs{$args[0]}{$args[1]}{$args[2]} = $nameID;
#			$$r_hash{$nameID}{'source'}{'ID'} = $nameID;
#			$$r_hash{$nameID}{'source'}{'map'} = $args[0];
#			$$r_hash{$nameID}{'source'}{'pos'}{'x'} = $args[1];
#			$$r_hash{$nameID}{'source'}{'pos'}{'y'} = $args[2];
#			$$r_hash{$nameID}{'dest'}{'map'} = $args[3];
#			$$r_hash{$nameID}{'dest'}{'pos'}{'x'} = $args[4];
#			$$r_hash{$nameID}{'dest'}{'pos'}{'y'} = $args[5];
#			if ($args[6] ne "" && $args[6] ne "<none>") {
#				$$r_hash{$nameID}{'npc'}{'ID'} = $args[6];
#				for ($i = 7; $i < @args; $i++) {
#					$$r_hash{$nameID}{'npc'}{'steps'}[@{$$r_hash{$nameID}{'npc'}{'steps'}}] = $args[$i];
#				}
#			}
#		}
#		$j++;
#	}
#	foreach (keys %{$r_hash}) {
#		$$r_hash{$_}{'dest'}{'ID'} = $IDs{$$r_hash{$_}{'dest'}{'map'}}{$$r_hash{$_}{'dest'}{'pos'}{'x'}}{$$r_hash{$_}{'dest'}{'pos'}{'y'}};
#	}
#	close(FILE);
#}

sub parsePortals {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key, $value);
	my %IDs;
	my $i;
	my $j = 0;
	my $nameID;

	my $plus	= shift;
	my @plus_file;
	my $line;
	@plus_file = glob $plus if ($plus ne "");

	foreach $line ($file, @plus_file) {

#		print "\n$line\n";

		next unless (-e "$line");

		open(FILE, $line);
		foreach (<FILE>) {
			next if (/^#/);

			getString(\$_, 1);

			@args = split /\s/, $_;
			if (@args > 5) {
				$nameID = "$args[0] $args[1] $args[2]";

				$nameID = "$args[0] $args[1] $args[2] $args[3] $args[4] $args[5]" if ($sc_v{'kore'}{'multiPortals'});

				$$r_hash{$nameID}{'nameID'} = "$args[0] $args[1] $args[2]";
				$IDs{$args[0]}{$args[1]}{$args[2]} = $nameID;
				$$r_hash{$nameID}{'source'}{'ID'} = $nameID;
				$$r_hash{$nameID}{'source'}{'map'} = $args[0];
				$$r_hash{$nameID}{'source'}{'pos'}{'x'} = $args[1];
				$$r_hash{$nameID}{'source'}{'pos'}{'y'} = $args[2];
				$$r_hash{$nameID}{'dest'}{'map'} = $args[3];
				$$r_hash{$nameID}{'dest'}{'pos'}{'x'} = $args[4];
				$$r_hash{$nameID}{'dest'}{'pos'}{'y'} = $args[5];
				if ($args[6] ne "" && $args[6] ne "<none>") {
					$$r_hash{$nameID}{'npc'}{'ID'} = $args[6];
					for ($i = 7; $i < @args; $i++) {
						$$r_hash{$nameID}{'npc'}{'steps'}[@{$$r_hash{$nameID}{'npc'}{'steps'}}] = $args[$i];
					}
				}
			}
			$j++;
		}
		close(FILE);
	}

	foreach (keys %{$r_hash}) {
		$$r_hash{$_}{'dest'}{'ID'} = $IDs{$$r_hash{$_}{'dest'}{'map'}}{$$r_hash{$_}{'dest'}{'pos'}{'x'}}{$$r_hash{$_}{'dest'}{'pos'}{'y'}};
	}
}

sub parsePortalsLOS {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $key;
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
#		s/[\r\n]//g;
#		s/\s+/ /g;
#		s/\s+$//g;

		getString(\$_, 1);

		@args = split /\s/, $_;
		if (@args) {
			$map = shift @args;
			$x = shift @args;
			$y = shift @args;
			for ($i = 0; $i < @args; $i += 4) {
				$$r_hash{"$map $x $y"}{"$args[$i] $args[$i+1] $args[$i+2]"} = $args[$i+3];
			}
		}
	}
	close(FILE);
}

sub parseReload {
	my $temp = shift;
	my $mode = shift;
	my @temp;
	my %temp;
	my $temp2;
	my $except;
	while ($temp =~ /(\w+)/g) {
		$temp2 = $1;
		$qm = quotemeta $temp2;
		if ($temp2 eq "all") {
			foreach (@{$sc_v{'parseFiles'}}) {
				$temp{$$_{'file'}} = $_;
			}
		} elsif ($temp2 =~ /\bexcept\b/i || $temp2 =~ /\bbut\b/i) {
			$except = 1;
		} else {
			if ($except) {
				foreach (@{$sc_v{'parseFiles'}}) {
					delete $temp{$$_{'file'}} if $$_{'file'} =~ /$qm/i;
				}
			} else {
				foreach (@{$sc_v{'parseFiles'}}) {
					$temp{$$_{'file'}} = $_ if $$_{'file'} =~ /$qm/i;
				}
			}
		}
	}
	foreach $temp (keys %temp) {
		$temp[@temp] = $temp{$temp};
	}
	load(\@temp, $mode);
}

sub parseResponses {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key, $value);
	my $i;
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
		s/[\r\n]//g;
		($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
		if ($key ne "" && $value ne "") {
			$i = 0;
			while ($$r_hash{"$key\_$i"} ne "") {
				$i++;
			}
			$$r_hash{"$key\_$i"} = $value;
		}
	}
	close(FILE);
}

#sub parseROLUT {
#	my $file = shift;
#	my $r_hash = shift;
#	undef %{$r_hash};
#	my @stuff;
#	open(FILE, $file);
#	foreach (<FILE>) {
#		s/\r//g;
#		next if /^\/\//;
#		@stuff = split /#/, $_;
##Karasu Start
##		$stuff[1] =~ s/_/ /g;
#		# Avoid display errors
#		replaceUnderToSpace(\$stuff[1]);
##Karasu End
#		if ($stuff[0] ne "" && $stuff[1] ne "") {
#			$$r_hash{$stuff[0]} = $stuff[1];
#		}
#	}
#	close(FILE);
#}

sub parseROLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;

	my $plus	= shift;
	my @plus_file;
	my $line;
	@plus_file = glob $plus if ($plus ne "");

	foreach $line ($file, @plus_file) {

#		print "\n$line\n";

		next unless (-e "$line");

		open(FILE, $line);

		foreach (<FILE>) {
#			s/\r//g;

			getString(\$_, 1);

			next if /^\/\//;
			@stuff = split /#/, $_;
	#Karasu Start
	#		$stuff[1] =~ s/_/ /g;
			# Avoid display errors
			replaceUnderToSpace(\$stuff[1]);
	#Karasu End
			if ($stuff[0] ne "" && $stuff[1] ne "") {
				$$r_hash{$stuff[0]} = $stuff[1];
			}
		}
		close(FILE);
	}
}

sub parseRODescLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $ID;
	my $IDdesc;
	open(FILE, $file);
	foreach (<FILE>) {
		s/\r//g;
		next if /^\/\//;
		if (/^#/) {
			$$r_hash{$ID} = $IDdesc;
			undef $ID;
			undef $IDdesc;
		} elsif (!$ID) {
			($ID) = /([\s\S]+)#/;
		} else {
#Karasu Start
			$_ =~ s/\^[0-9a-fA-F]{6}//g;
			$_ =~ s/^_$/--------------/g;
#Karasu End
			$IDdesc .= $_;
		}
	}
	close(FILE);
}

sub parseROSlotsLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $ID;
	open(FILE, $file);
	foreach (<FILE>) {
		getString(\$_, 1);
		next if (/^\/\// || $_ eq "");

		if (!$ID) {
			($ID) = /(\d+)#/;
		} else {
			($$r_hash{$ID}) = /(\d+)#/;
			undef $ID;
		}
	}
	close(FILE);
}

sub parseSkillsLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open(FILE, $file);
	$i = 1;
	foreach (<FILE>) {
		next if /^\/\//;

		@stuff = split /#/, $_;
#Karasu Start
#		$stuff[1] =~ s/_/ /g;
		# Avoid display errors
		replaceUnderToSpace(\$stuff[1]);
#Karasu End
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{$stuff[0]} = $stuff[1];
		}
		$i++;
	}
	close(FILE);
}

sub parseSkillsIDLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open(FILE, $file);
	$i = 1;
	foreach (<FILE>) {
		next if /^\/\//;

		@stuff = split /#/, $_;
#Karasu Start
#		$stuff[1] =~ s/_/ /g;
		# Avoid display errors
		replaceUnderToSpace(\$stuff[1]);
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			# skills.txt must have number
			#$$r_hash{$i} = $stuff[1];
			$$r_hash{$stuff[2]} = $stuff[1];
		}
#Karasu End
		$i++;
	}
	close(FILE);
}

sub parseSkillsReverseLUT_lc {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open(FILE, $file);
	$i = 1;
	foreach (<FILE>) {
		next if /^\/\//;

		@stuff = split /#/, $_;
#Karasu Start
#		$stuff[1] =~ s/_/ /g;
		# Avoid display errors
		replaceUnderToSpace(\$stuff[1]);
#Karasu End
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{lcCht($stuff[1])} = $stuff[0];

#			print lcCht($stuff[1])." = ".lcCht($stuff[1])."\n" if (lcCht($stuff[1]) ne lcCht($stuff[1]));
		}
		$i++;
	}
	close(FILE);
}

sub parseSkillsSPLUT {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my $ID;
	my $i;
	$i = 1;
	open(FILE, $file);
	foreach (<FILE>) {
		if (/^\@/) {
			undef $ID;
			$i = 1;
		} elsif (!$ID) {
			($ID) = /([\s\S]+)#/;
		} else {
			($$r_hash{$ID}{$i++}) = /(\d+)#/;
		}
	}
	close(FILE);
}

sub parseTimeouts {
	my $file = shift;
	my $r_hash = shift;
	my ($key, $value);
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
#		s/[\r\n]//g;
#
#		s/\s+$//g;

		getString(\$_);

		($key, $value) = $_ =~ /([\s\S]*) ([\s\S]*?)$/;
		if ($key ne "" && $value ne "") {
			$$r_hash{$key}{'timeout'} = abs($value);
		}
	}
	close(FILE);
}

sub writeDataFile {
	my $file = shift;
	my $r_hash = shift;
	my ($key, $value);
	open(FILE, "+> $file");
	foreach (keys %{$r_hash}) {
		if ($_ ne "") {
			print FILE "$_ $$r_hash{$_}\n";
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

sub writeDataFileIntact2 {
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
		$data .= "$key $$r_hash{$key}{'timeout'}\n";
	}
	close(FILE);
	open(FILE, "+> $file");
	print FILE $data;
	close(FILE);
}

sub writePortalsLOS {
	my $file = shift;
	my $r_hash = shift;
	open(FILE, "+> $file");
	foreach $key (sort keys %{$r_hash}) {
		next if (!(keys %{$$r_hash{$key}}));
		print FILE $key;
		foreach (sort keys %{$$r_hash{$key}}) {
			print FILE " $_ $$r_hash{$key}{$_}";
		}
		print FILE "\n";
	}
	close(FILE);
}

sub updateMonsterLUT {
	my $file = shift;
	my $ID = shift;
	my $name = shift;
	open(FILE, ">> $file");
	print FILE "$ID $name\n";
	close(FILE);

	sysLog("update", "怪物", "自動新增 $ID $name ", 1);
}

sub updatePortalLUT {
	my ($file, $src, $x1, $y1, $dest, $x2, $y2) = @_;
	open(FILE, ">> $file");
	print FILE "$src $x1 $y1 $dest $x2 $y2\n";
	close(FILE);

	sysLog("update", "傳點", "自動新增 $src $x1 $y1 $dest $x2 $y2", 1);
}

sub updateNPCLUT {
	my ($file, $ID, $map, $x, $y, $name) = @_;
	open(FILE, ">> $file");
	print FILE "$ID $map $x $y $name \n";
	close(FILE);

	sysLog("update", "NPC", "自動新增 $ID $map $x $y $name ");
}

sub load {
	my $r_array = shift;
	my $mode = shift;
	my $mode2 = shift;

	foreach (@{$r_array}) {
		if (!$mode) {
			if (-e $$_{'file'}) {
				print "Loading $$_{'file'}".(($$_{'desc'} eq "")?"...":" : $$_{'desc'}")."\n";
			} else {
				printC("Error:\tCouldn't load $$_{'file'}".(($$_{'desc'} eq "")?"":" : $$_{'desc'}")."\n", "error");

				if ($$_{'quit'}) {
					printC("◇Please download the file \'$$_{'file'}\'\n", "WHITE");
					quit(1, 1);
				}
			}
		}

		&{$$_{'function'}}("$$_{'file'}", $$_{'hash'}, $$_{'plus'});
	}

	parseFixerEx();
	parseFixer();
	parseFixerEx();

	if (!$mode2) {

		if (@preferRoute && %map_control) {
			foreach (@preferRoute) {
				next if ($$_{'map'} eq "" || $map_control{$$_{'map'}}{'restrict_map'} < 0);

	#			print "$$_{'map'}\n";

				$map_control{$$_{'map'}}{'restrict_map'} = 1;
			}
		}

		$itemsPickup{'all'} = 1 if ($itemsPickup{'all'} eq "");

		if ($config{'teleportAuto_search'}) {
			undef $sc_v{'ai'}{'temp'}{'found'};
			$sc_v{'ai'}{'temp'}{'found'} = 0;

			foreach (keys %mon_control) {
				if ($mon_control{$_}{'teleport_search'}) {
					$sc_v{'ai'}{'temp'}{'found'} = $config{'teleportAuto_search'};
					last;
				}
			}

			$config{'teleportAuto_search'} = $sc_v{'ai'}{'temp'}{'found'};
		}

		if ($config{'teleportAuto_away'}) {
			undef $sc_v{'ai'}{'temp'}{'found'};
			$sc_v{'ai'}{'temp'}{'found'} = 0;

			foreach (keys %mon_control) {
				if ($mon_control{$_}{'teleport_auto'}) {
					$sc_v{'ai'}{'temp'}{'found'} = $config{'teleportAuto_away'};
					last;
				}
			}

			$config{'teleportAuto_away'} = $sc_v{'ai'}{'temp'}{'found'};
		}

	}

	foreach (keys %timeout) {
		next if (!$_);
		$timeout{$_}{'time'} = time;
	}
}

# File parser
sub parseDataFile3 {
	my $file = shift;
	my $r_hash = shift;
	my $i = 0;
	undef %{$r_hash};
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
#		s/[\r\n]//g;
#		s/\s+$//g;

		getString(\$_);

		if($_ ne ""){
			$$r_hash[$i++] = $_;
		}
	}
	close(FILE);
}

# Message table parser
sub parseMsgStrings {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	my $i;
	open(FILE, $file);
	foreach (<FILE>) {
#		s/\r//g;

		getString(\$_);

		next if /^\/\//;
#		@stuff = split /#/, $_;

		splitUseArray(\@stuff, $_, "\#");

		if ($stuff[0] ne "" && $stuff[1] ne "" && $stuff[2] ne "") {
			$$r_hash{$stuff[0]}{$stuff[1]} = $stuff[2];
		}
	}
	close(FILE);
}

# Log command outputs
sub logCommand {
	my $outfile = shift;
	my $command = shift;

	open(LOGDATA, $outfile);
		select(LOGDATA);
			parseInput($command);
			print "\n";
		close(LOGDATA);
	select(STDOUT);
}

sub parseDataFile_quote {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key, $value);
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
#		s/[\r\n]//g;
#		s/\s+$//g;

		getString(\$_);

		($key, $value) = $_ =~ /^"([\s\S]*)" ([\s\S]*?)$/;
		if ($key ne "" && $value ne "") {
			$$r_hash{$key} = $value;
		}
	}
	close(FILE);
}

sub parseMapControl {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key, @args);
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
#		s/[\r\n]//g;
#		s/\s+$//g;

		getString(\$_);

#		($key, $args) = $_ =~ /([\s\S]+?) (\d+[\s\S]*)/;

		($key, $args) = $_ =~ /([\s\S]+?) (-?\d+[\s\S]*)/;

		@args = split / /, $args;
		if ($key ne "") {
			$$r_hash{lcCht($key)}{'teleport_allow'} = $args[0];
			$$r_hash{lcCht($key)}{'restrict_map'} = $args[1];
		}
	}
	close(FILE);
}

sub parsePreferRoute {
	my $file = shift;
	my $r_hash = shift;
	my $i = 0;
	undef %{$r_hash};
	my @stuff;
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
#		s/[\r\n]//g;
#		s/\s+$//g;

		getString(\$_);

		@stuff = split / /, $_;
		if ($stuff[0] ne ""){
			$i++;
			$$r_hash[$i]{'map'} = $stuff[0];
			$$r_hash[$i]{'upLeft'}{'x'} = $stuff[1];
			$$r_hash[$i]{'upLeft'}{'y'} = $stuff[2];
			$$r_hash[$i]{'bottomRight'}{'x'} = $stuff[3];
			$$r_hash[$i]{'bottomRight'}{'y'} = $stuff[4];
		}
	}
	close(FILE);
}

# Like parseROLUT but not replace "_" to " "
sub parseROLUT2 {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my @stuff;
	open(FILE, $file);
	foreach (<FILE>) {
		s/\r//g;
		next if /^\/\//;
		@stuff = split /#/, $_;
		if ($stuff[0] ne "" && $stuff[1] ne "") {
			$$r_hash{$stuff[0]} = $stuff[1];
		}
	}
	close(FILE);
}

sub addParseFiles {
	my $file	= shift;
	my $hash	= shift;
	my $function	= shift;
	my $desc	= shift;
	my $quit	= shift;
	my @plus	= @_;

	my %t_hash = (
		file		=> $file,
		hash		=> $hash,
		function	=> $function,
		desc		=> $desc,
		quit		=> $quit,
		plus		=> @plus
	);

	push @{$sc_v{'parseFiles'}}, \%t_hash;
}

# Replace underscore to space
sub replaceUnderToSpace {
	my $string = shift;
	my $isDualByte = 0;
	my $i;
	for ($i = 0; $i < length($$string); $i++) {
		if (substr($$string, $i, 1) eq "_" && !$isDualByte) {
			substr($$string, $i, 1) = " ";
		} elsif (ord(substr($$string, $i, 1)) >= 0x80) {
			$isDualByte = 1 - $isDualByte;
		} else {
			$isDualByte = 0;
		}
	}
}

# Update NPCs table
sub updateNPCLUTIntact {
	my ($file, $ID, $newID) = @_;
	my $data;
	my $key;
	open(FILE, $file);
	foreach (<FILE>) {
		if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
			$data .= $_;
			next;
		}
		($key) = $_ =~ /^(\d+)/;
		if ($key eq $ID) {
			$_ =~ s/^$ID\b/$newID/;
			$npcs_lut{$newID}{'map'} = $npcs_lut{$ID}{'map'};
			$npcs_lut{$newID}{'pos'}{'x'} = $npcs_lut{$ID}{'pos'}{'x'};
			$npcs_lut{$newID}{'pos'}{'y'} = $npcs_lut{$ID}{'pos'}{'y'};
			$npcs_lut{$newID}{'name'} = $npcs_lut{$ID}{'name'};
			binRemove(\@npcsID, $ID);
			undef %{$npcs{$ID}};
			undef %{$npcs_lut{$ID}};

			$data .= "$newID $npcs_lut{$newID}{'map'} $npcs_lut{$newID}{'pos'}{'x'} $npcs_lut{$newID}{'pos'}{'y'} $npcs_lut{$newID}{'name'} \n";
		} else {
			$data .= $_;
		}
	}
	close(FILE);

	open(FILE, "+> $file");
	print FILE $data;
	close(FILE);
}

# Update NPCs table
sub updateNPCLUTIntactEx {
	my ($file, $ID) = @_;
	my $data;
	my $key;
	my $string;
	my $found;
	open(FILE, $file);
	foreach (<FILE>) {
		if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
			$data .= $_;
			next;
		}

		getString(\$_, 1);

#		@args = split /\s/, $_;

		splitUseArray(\@args, $_, " ");

		if (@args >= 4) {
			$string = $args[4];
			for ($i = 5; $i < @args; $i++) {
				$string .= " $args[$i]";
			}

			getString(\$args[1], 1);

			if (
#				$npcs{$ID}{'nameID'} ne $args[0]
#				&&
				$npcs{$ID}{'map'} eq $args[1]
				&& $npcs{$ID}{'pos'}{'x'} == $args[2]
				&& $npcs{$ID}{'pos'}{'y'} == $args[3]
			) {
				if ($npcs{$ID}{'nameID'} ne $args[0]) {
					$string = "<none>" if ($string eq "");

#					print "$args[0] $args[1] $args[2] $args[3] $string "
#						."= $npcs{$ID}{'nameID'} $npcs{$ID}{'map'} $npcs{$ID}{'pos'}{'x'} $npcs{$ID}{'pos'}{'y'} $npcs{$ID}{'name'} \n";

					binRemove(\@npcsID, $args[0]);
					undef %{$npcs{$args[0]}};
					undef %{$npcs_lut{$args[0]}};

					$args[0] = $npcs{$ID}{'nameID'};
					$key = ($config{'updateNPC'}?$npcs{$ID}{'nameID'}:"<auto>");

					$npcs_lut{$args[0]}{'map'} = $args[1];
					$npcs_lut{$args[0]}{'pos'}{'x'} = $args[2];
					$npcs_lut{$args[0]}{'pos'}{'y'} = $args[3];
					$npcs_lut{$args[0]}{'name'} = $string;

					$data .= "$key $args[1] $args[2] $args[3] $string ";
				} else {
					$data .= $_;
				}

				$found = 1;
			} else {
				$data .= $_;
			}
		} else {
			$data .= $_;
		}

		$data .= "\n";


#		if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
#			$data .= $_;
#			next;
#		}
#		($key) = $_ =~ /^(\d+)/;
#		if ($key eq $ID) {
#			$_ =~ s/^$ID\b/$newID/;
#			$npcs_lut{$newID}{'map'} = $npcs_lut{$ID}{'map'};
#			$npcs_lut{$newID}{'pos'}{'x'} = $npcs_lut{$ID}{'pos'}{'x'};
#			$npcs_lut{$newID}{'pos'}{'y'} = $npcs_lut{$ID}{'pos'}{'y'};
#			$npcs_lut{$newID}{'name'} = $npcs_lut{$ID}{'name'};
#			binRemove(\@npcsID, $ID);
#			undef %{$npcs{$ID}};
#			undef %{$npcs_lut{$ID}};
#
#			$data .= "$newID $npcs_lut{$newID}{'map'} $npcs_lut{$newID}{'pos'}{'x'} $npcs_lut{$newID}{'pos'}{'y'} $npcs_lut{$newID}{'name'} \n";
#		} else {
#			$data .= $_;
#		}
	}

	if (!$found) {
		$key = ($config{'updateNPC'}?$npcs{$ID}{'nameID'}:"<auto>");
		$data .= "$key $npcs{$ID}{'map'} $npcs{$ID}{'pos'}{'x'} $npcs{$ID}{'pos'}{'y'} $npcs{$ID}{'name'} \n";

		undef %{$npcs_lut{$npcs{$ID}{'nameID'}}};

		$npcs_lut{$npcs{$ID}{'nameID'}}{'map'} = $npcs{$ID}{'map'};
		$npcs_lut{$npcs{$ID}{'nameID'}}{'pos'}{'x'} = $npcs{$ID}{'pos'}{'x'};
		$npcs_lut{$npcs{$ID}{'nameID'}}{'pos'}{'y'} = $npcs{$ID}{'pos'}{'y'};
		$npcs_lut{$npcs{$ID}{'nameID'}}{'name'} = $npcs{$ID}{'name'};
	}

	close(FILE);

	open(FILE, "+> $file");
	print FILE $data;
	close(FILE);
}

# Update portals table
sub updatePortalLUTIntact {
	my ($file, $ID, $newID) = @_;
	my $data;
	open(FILE, $file);
	foreach (<FILE>) {
		if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
			$data .= $_;
			next;
		}
		@args = split /\s/, $_;
		if (@args > 6 && $args[6] eq $ID) {
			$_ =~ s/\b$ID\b/$newID/;
			$portals_lut{"$args[0] $args[1] $args[2]"}{'npc'}{'ID'} = $newID;
		}
		$data .= $_;
	}
	close(FILE);
	open(FILE, "+> $file");
	print FILE $data;
	close(FILE);
}
#Karasu End

sub convertGatField {
	my $file = shift;
	my $r_hash = shift;
	my $i;
	open(FILE, "+> $file");
	binmode(FILE);
	print FILE pack("S*", $$r_hash{'width'}, $$r_hash{'height'});
	for ($i = 0; $i < @{$$r_hash{'field'}}; $i++) {
		print FILE pack("C1", $$r_hash{'field'}[$i]);
	}
	close(FILE);
}

sub dumpData {
	my $msg		= shift;
	my $mode	= shift;
	my $isSend	= shift;
	my $desc	= shift;
	my $dump;
	my $i;
	my $switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));

	$dump = "\n\n================================================\n".getFormattedDate(int(time))."\n\nSwitch: ".$switch."\n\n".length($msg)." bytes\n\n";
	$dump .= "DESC: $desc\n\n" if ($desc ne "");
	for ($i=0; $i + 15 < length($msg);$i += 16) {
		$dump .= getHex(substr($msg, $i,8))."    ".getHex(substr($msg, $i+8,8))."\n";
	}
	if (length($msg) - $i > 8) {
		$dump .= getHex(substr($msg, $i,8))."    ".getHex(substr($msg, $i+8,length($msg) - $i - 8))."\n";
	} elsif (length($msg) > 0) {
		$dump .= getHex(substr($msg, $i,length($msg) - $i))."\n";
	}

	my $file = "DUMP";
	$file .= "_Send" if ($isSend);

	open(DUMP, ">> $sc_v{'path'}{'def_control_'}${file}.txt");
	print DUMP $dump;
	close(DUMP);
	print "$dump\n" if ($config{'debug'} >= 2 || $mode);
	print "將封包[ $switch ]內容傾印至: ${file}.txt！\n";
	print "DESC: $desc\n" if ($desc ne "");
}

#sub getField {
#	my $file = shift;
#	my $r_hash = shift;
#	my ($i, $data);
#	my $alias;
#	undef %{$r_hash};
#	if ($file =~ /\//) {
#		($$r_hash{'name'}) = $file =~ /\/([\s\S]*)\./;
#	} else {
#		($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
#	}
##Karasu Start
#	# Check for map alias
#	if ($mapAlias_lut{$$r_hash{'name'}.'.rsw'} ne "") {
#		($alias) = $mapAlias_lut{$$r_hash{'name'}.'.rsw'} =~ /([\s\S]*)\./;
#		$file =~ s/$$r_hash{'name'}/$alias/;
#	}
#	if (!(-e $file)) {
#		print "無法載入地圖檔($file), 你必須安裝Kore Field Pack！\n\n";
#		return;
#	}
##Karasu End
#	open(FILE, $file);
#	binmode(FILE);
#	read(FILE, $data, 4);
#	my $width = unpack("S1", substr($data, 0,2));
#	my $height = unpack("S1", substr($data, 2,2));
#	$$r_hash{'width'} = $width;
#	$$r_hash{'height'} = $height;
#	while (read(FILE, $data, 1)) {
##Karasu Start
## Use substr instead of large array
##		$$r_hash{'field'}[$i] = unpack("C",$data);
#		$$r_hash{'rawMap'} .= $data;
##		$i++;
##Karasu End
#	}
#	close(FILE);
#}

sub getField {
	my $file = shift;
	my $r_hash = shift;
	my ($i, $data);
	my $alias;
	undef %{$r_hash};

	$file =~ s/ /_/g;

	if ($file =~ /\//) {
		($$r_hash{'name'}) = $file =~ /\/([\s\S]*)\./;
	} else {
		($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
	}
#Karasu Start
	# Check for map alias
	if ($mapAlias_lut{$$r_hash{'name'}.'.rsw'} ne "") {
		($alias) = $mapAlias_lut{$$r_hash{'name'}.'.rsw'} =~ /([\s\S]*)\./;
		$file =~ s/$$r_hash{'name'}/$alias/;
	}
	if (!(-e $file)) {
#		print "無法載入地圖檔($file), 你必須安裝Kore Field Pack！\n\n";
		sysLog("error", "Field", "無法載入地圖檔($file), 你必須安裝Kore Field Pack！", 1);
		return;
	}
#Karasu End
	# Load the .fld file
	#($$r_hash{'name'}) = $file =~ m{/?([^/.]*)\.};
	open FILE, "<", $file;
	binmode(FILE);
	my $data;
	{
		local($/);
		$data = <FILE>;
		close FILE;
	}
	@$r_hash{'width', 'height'} = unpack("S1 S1", substr($data, 0, 4, ''));
	$$r_hash{'rawMap'} = $data;
	#$$r_hash{'binMap'} = pack('b*', $data);
	$$r_hash{'field'} = [unpack("C*", $data)];
	(my $dist_file = $file) =~ s/\.fld$/.dist/i;
	# Load the associated .dist file (distance map)
	if (-e $dist_file) {
		open FILE, "< $dist_file";
		binmode(FILE);
		my $dist_data;
		{
			local($/);
			$dist_data = <FILE>;
		}
		close FILE;
		my $dversion = 0;
		if (substr($dist_data, 0, 2) eq "V#") {
			$dversion = unpack("xx S1", substr($dist_data, 0, 4, ''));
		}

		my ($dw, $dh) = unpack("S1 S1", substr($dist_data, 0, 4, ''));
		if (
			#version 0 files had a bug when height != width
			#version 1 files did not treat walkable water as walkable, all version 0 and 1 maps need to be rebuilt
			#version 2 and greater have no know bugs, so just do a minimum validity check.
			$dversion >= 2 && $$r_hash{'width'} == $dw && $$r_hash{'height'} == $dh
		) {
			$$r_hash{'dstMap'} = $dist_data;
		}
	}

	# The .dist file is not available; create it
	unless ($$r_hash{'dstMap'}) {
		$$r_hash{'dstMap'} = makeDistMap(@$r_hash{'rawMap', 'width', 'height'});
		open FILE, "> $dist_file" or die "Could not write dist cache file: $!\n";
		binmode(FILE);
		print FILE pack("a2 S1", 'V#', 2);
		print FILE pack("S1 S1", @$r_hash{'width', 'height'});
		print FILE $$r_hash{'dstMap'};
		close FILE;
	}

	return 1;
}

sub getGatField {
	my $file = shift;
	my $r_hash = shift;
	my ($i, $data);
	undef %{$r_hash};
	($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
	open(FILE, $file);
	binmode(FILE);
	read(FILE, $data, 16);
	my $width = unpack("L1", substr($data, 6,4));
	my $height = unpack("L1", substr($data, 10,4));
	$$r_hash{'width'} = $width;
	$$r_hash{'height'} = $height;
	while (read(FILE, $data, 20)) {
		$$r_hash{'field'}[$i] = unpack("C1", substr($data, 14,1));
		$i++;
	}
	close(FILE);
}

sub getRoutePoint {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key, $value_1, $value_2);
	if (!(-e $file)) {
		printC("\n!!Could not load Waypoint - you must install waypoint for this map!!\n\n", "alert");
		return 0;
	}
	if ($file =~ /\//) {
		($$r_hash{'name'}) = $file =~ /\/([\s\S]*)\./;
	} else {
		($$r_hash{'name'}) = $file =~ /([\s\S]*)\./;
	}
	open FILE, $file;
	$$r_hash{'max'} = 0;
	foreach (<FILE>) {
		next if (/^#/ || /^\n/);
		s/[\r\n]//g;

		($value_1, $value_2) = $_ =~ /(\d+):(\d+)/;

		$$r_hash{$$r_hash{'max'}}{'x'} = $value_1;
		$$r_hash{$$r_hash{'max'}}{'y'} = $value_2;
		$$r_hash{'max'}++;
	}
	close FILE;
}

sub parseItemsPrices {
	my $file = shift;
	my $r_hash = shift;
#	undef %{$r_hash};
	my ($key, $value);
	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);
#		s/[\r\n]//g;
#		s/\s+$//g;

		getString(\$_);

		($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
		$key =~ s/\s//g;
		if ($key eq "") {
			($key) = $_ =~ /([\s\S]*)$/;
			$key =~ s/\s//g;
		}
		if ($key ne "") {
			$$r_hash{$key}{'value'} = $value;
		}
	}
	close(FILE);
}

sub parsePacketsFile {
	my $file	= shift;
	my $r_hash	= shift;
	undef %{$r_hash};
	my ($key, $value, $desc, $line);

	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);

		getString(\$_, 1);

		$line = $_;
		($key, $value) = $line =~ /^([\d\S]+) ([\d\S]+)/;
		($desc) = $line =~ /^[\d\S]+ [\d\S]+ ([\s\S]*)$/;

		$key =~ s/\s//g;
		$desc =~ s/^\s+//g;

		getString(\$value, 1);

		if ($key eq "") {
			($key) = $_ =~ /([\s\S]*)$/;
			$key =~ s/\s//g;

			getString(\$key, 1);
		}
		if ($key ne "") {
			$$r_hash{$key} = $value;
#			print "$key = $value\n";
		}
	}
	close(FILE);
}

sub parseDataFile2_new {
	my $file = shift;
	my $r_hash = shift;
	undef %{$r_hash};
	my ($key, $value, $inBlock, $commentBlock, %blocks);

	my $plus	= shift;
	my @plus_file;
	my $line;
	@plus_file = glob $plus if ($plus ne "");

	foreach $line ($file, @plus_file) {

#		print "\n$line\n";

		next unless (-e "$line");

		open(FILE, $line);
		foreach (<FILE>) {
			next if (/^\s*\#/ || /^\s*[\r\n]/);
			s/\s*$//;
			s/^\s*//;

			getString(\$_, 1);

			next if ($_ eq "");

			if (!defined $commentBlock && /^\/\*/) {
				$commentBlock = 1;

			} elsif (defined $commentBlock) {
				undef $commentBlock if (/\*\/$/);

			} elsif (!defined $inBlock && /\s+{$/) {
				s/\s+{$//;
				next if ($_ eq "");
				($key, $value) = $_ =~ /^(.*?)(?:\s+(.*))?$/;

				getString(\$value, 1);

				if (!exists $blocks{$key}) {
					$blocks{$key} = 0;
				} else {
					$blocks{$key}++;
				}
				$inBlock = "${key}_$blocks{$key}";
				while (exists $$r_hash{$inBlock}) {
					$blocks{$key}++;
					$inBlock = "${key}_$blocks{$key}";
				}
				$$r_hash{$inBlock} = $value;

	#			print "$inBlock $value\n";

			} elsif (defined $inBlock && $_ eq "}") {
				# End of block
				undef $inBlock;

			} else {
				# Option
				($key, $value) = $_ =~ /^(.*?)(?:\s+(.*))?$/;

				getString(\$value, 1);

				$key = "${inBlock}_${key}" if (defined $inBlock);
				$$r_hash{$key} = $value;

	#			print "$key $value\n";
			}
		}
		close(FILE);
	}
}

sub updateDataFile2_new {
	my $file = shift;
	my $r_hash = shift;
#	my $mode = shift;
	my ($data, $key, $value, $result, $inBlock, $commentBlock, %blocks, %hash_temp);
	$result = 0;

	open(FILE,"< $file");
	foreach (<FILE>) {
		if (/^\s*\#/ || /^\s*[\n\r]/) {
			$data .= $_ if (!$option{'delete_fileDesc'});
			next;
		}

		if (!defined $commentBlock && /^\s*\/\*/) {
			$commentBlock = 1;

			$_ = "" if ($option{'delete_fileDesc'});

		} elsif (defined $commentBlock) {

			undef $commentBlock if (/\*\/\s*$/);

			$_ = "" if ($option{'delete_fileDesc'});

		} elsif (!defined $inBlock && /\s+{\s*$/) {
			($key, $value) = $_ =~ /^(?:\s*)(.*?)(?:\s+(.*))?\s+{\s*$/;
			if ($key eq "") {
				$data .= $_;
				next;
			}

			getString(\$value, 1);

			if (!exists $blocks{$key}) {
				$blocks{$key} = 0;
			} else {
				$blocks{$key}++;
			}
			$inBlock = "${key}_$blocks{$key}";
			while (exists $hash_temp{$inBlock}) {
				$blocks{$key}++;
				$inBlock = "${key}_$blocks{$key}";
			}
			$hash_temp{$inBlock} = $value;
			if (exists $$r_hash{$inBlock} && $value ne $$r_hash{$inBlock}) {
				$hash_temp{$inBlock} = $$r_hash{$inBlock};
				
				if ($_ =~ /^(\s*\S+)\s*?(\s+{\s*)$/) {
					$_ = "$1 $$r_hash{$inBlock}$2";
#					print "000 $_\n";
				} else {
					$_ =~ s/^(\s*\S+)(\s+)(?:.*?)(\s+{\s*)$/$1$2$$r_hash{$inBlock}$3/;
#					print "010 $_\n";
				}
				$result = 1;
			}

			getString(\$_, 1);

#			$_ = RTrim($_)."\n";

			$_ .= "\n";

		} elsif (defined $inBlock && /^\s*}\s*$/) {
			undef $inBlock;

		} else {
			($key, $value) = $_ =~ /^(?:\s*)(.*?)(?:\s+(.*?))?\s*$/;
			$key = "${inBlock}_${key}" if (defined $inBlock);

			$hash_temp{$key} = $value;
			if (exists $$r_hash{$key} && $value ne $$r_hash{$key}) {
#				getString(\$_, 1);
				
#				print "$_\n";
#				print "$key - $value - $$r_hash{$key}\n";
				
				$hash_temp{$key} = $$r_hash{$key};
				
				if ($_ =~ /^(\s*\S+)\s*?([\r\n]*)$/) {
					$_ = "$1 $$r_hash{$key}$2";
					
#					print "[0] $_\n";
#				} elsif ($value eq "") {
#					$_ = "$key $$r_hash{$key}";
#					
#					print "[1] $_\n";
				} else {
					$_ =~ s/^(\s*\S+)(\s+)(?:.*?)([\r\n]*)$/$1$2$$r_hash{$key}$3/;
				}
				
#				print "$_\n";
				
				$result = 1;
			}

			$_ = RTrim($_)."\n";

#			getString(\$_, 1);
#
#			$_ .= "\n";
		}
		$data .= $_;
	}
	close FILE;

	if ($result) {
#		print "Change File: $file\n";
		
		if (!$option{'delete_fileDesc'}) {

			open(FILE, "> $file");
			print FILE $data;
			close FILE;

		} else {

			open(FILE, "> $file");
			foreach (sort keys (%hash_temp)) {
				$data = "$_ $hash_temp{$_}";
				next if (getString(\$data, 1) eq "");
				print FILE "$data\n";
			}
			close FILE;

		}
	}
}

sub updateDataFile2_id {
	my ($file, $r_hash) = @_;
	my $data;
	my %r_hash2;

#	foreach (%{$r_hash}) {
#		next if ($$r_hash{$_}{'name'} eq "" || $_ eq "");
#
#		$r_hash2{getID($_)} = $$r_hash{$_}{'name'};
#		print getID($_)." $$r_hash{$_}{'name'}\n";
#	}

#	open(FILE, $file);
#	foreach (<FILE>) {
#		if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
#			next;
#		}
#
#		getString(\$_, 1);
#		@args = split /\s/, $_;
#
#		if ($args[0] ne "" && $args[1] ne "") {
##			$$r_hash{$args[0]}{'name'} = $args[1];
#			$r_hash2{$args[0]} = $args[1];
#		}
#	}
#	close(FILE);

	open(FILE, "> $file");
	foreach (sort sortNum keys (%{$r_hash})) {
		next if ($_ eq "" || $$r_hash{$_} eq "");

		print FILE "$_ $$r_hash{$_}\n";
	}
	close(FILE);
}

sub updateDataFile2_guild {
	my ($file, $r_hash) = @_;
	my %r_hash2;

#	foreach (%{$r_hash}) {
#		next if ($$r_hash{$_}{'name'} eq "" || $_ eq "");
#
#		$r_hash2{getID($_)} = $$r_hash{$_}{'name'};
#		print getID($_)." $$r_hash{$_}{'name'}\n";
#	}

#	open(FILE, $file);
#	foreach (<FILE>) {
#		if (/^#/ || $_ =~ /^\n/ || $_ =~ /^\r/) {
#			next;
#		}
#
#		getString(\$_, 1);
#		@args = split /\s/, $_;
#
#		if ($args[0] ne "" && $args[1] ne "") {
##			$$r_hash{$args[0]}{'name'} = $args[1];
#			$r_hash2{$args[0]} = $args[1];
#		}
#	}
#	close(FILE);

	my $data;
	my ($key, $value);

	$data .= "\# [ ".getFormattedDate(int(time))." ]\n";
	$data .= "\# [ ".$sc_v{'parseMsg'}{'server_name'}." ]\n\n";

	open(FILE, $file);
	foreach (<FILE>) {
		next if (/^#/);

		getString(\$_, 1);

		($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;

		getString(\$key);
		getString(\$value);

		if ($key eq "") {
			($key) = $_ =~ /([\s\S]*)$/;
			$key =~ s/\s//g;
		}
		if ($key ne "") {
#			$$r_hash{$key} = $value;

			$data .= "$key $value\n";

			delete $$r_hash{$key};
		}
	}
	close(FILE);

	foreach (sort sortNum keys (%{$r_hash})) {
		next if ($_ eq "" || $$r_hash{$_} eq "");

		$data .= "$_ $$r_hash{$_}\n";

		$result = 1;
	}

#	$data .= "\n";

	if ($result) {
		open(FILE, "> $file");
		print FILE $data;
		close(FILE);
	}
}

1;