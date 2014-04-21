#######################################
#######################################
#HASH/ARRAY MANAGEMENT
#######################################
#######################################


sub binAdd {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i <= @{$r_array};$i++) {
		if ($$r_array[$i] eq "") {
			$$r_array[$i] = $ID;
			return $i;
		}
	}
}

sub binFind {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] eq $ID) {
			return $i;
		}
	}
}

sub binFindReverse {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = @{$r_array} - 1; $i >= 0;$i--) {
		if ($$r_array[$i] eq $ID) {
			return $i;
		}
	}
}

sub binRemove {
	my $r_array = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] eq $ID) {
			undef $$r_array[$i];
			last;
		}
	}
}

sub binRemoveAndShift {
	my $r_array = shift;
	my $ID = shift;
	my $found;
	my $i;
	my @newArray;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] ne $ID || $found ne "") {
			push @newArray, $$r_array[$i];
		} else {
			$found = $i;
		}
	}
	@{$r_array} = @newArray;
	return $found;
}

sub binRemoveAndShiftByIndex {
	my $r_array = shift;
	my $index = shift;
	my $found;
	my $i;
	my @newArray;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($i != $index) {
			push @newArray, $$r_array[$i];
		} else {
			$found = 1;
		}
	}
	@{$r_array} = @newArray;
	return $found;
}

sub binSize {
	my $r_array = shift;
	my $found = 0;
	my $i;
	for ($i = 0; $i < @{$r_array};$i++) {
		if ($$r_array[$i] ne "") {
			$found++;
		}
	}
	return $found;
}

#sub existsInList {
#	my ($list, $val) = @_;
#	undef @array;
#	@array = split /,/, $list;
#	return 0 if ($val eq "");
#	$val = lcCht($val);
#	foreach (@array) {
#		s/^\s+//;
#		s/\s+$//;
#		s/\s+/ /g;
#		next if ($_ eq "");
#		return 1 if (lcCht($_) eq $val);
#	}
#	return 0;
#}

sub existsInList {
	my ($list, $val) = @_;
	undef @array;
	@array = split /,/, lcCht($list);
	return 0 if ($val eq "");
	$val = lcCht($val);
	foreach (@array) {
		s/^\s+//;
		s/\s+$//;
		s/\s+/ /g;
		next if ($_ eq "");
		return 1 if ($_ eq $val);
	}
	return 0;
}

sub findIndex {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && $$r_array[$i]{$match} == $ID)
			|| (!%{$$r_array[$i]} && $ID eq "")) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}


sub findIndexString {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && $$r_array[$i]{$match} eq $ID)
			|| (!%{$$r_array[$i]} && $ID eq "")) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}


#sub findIndexString_lc {
#	my $r_array = shift;
#	my $match = shift;
#	my $ID = shift;
#	my $i;
#	for ($i = 0; $i < @{$r_array} ;$i++) {
#		if ((%{$$r_array[$i]} && lcCht($$r_array[$i]{$match}) eq lcCht($ID))
#			|| (!%{$$r_array[$i]} && $ID eq "")) {
#			return $i;
#		}
#	}
#	if ($ID eq "") {
#		return $i;
#	}
#}

sub findIndexString_lc {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array} ;$i++) {
		if ((%{$$r_array[$i]} && lcCht($$r_array[$i]{$match}) eq lcCht($ID))
			|| (!%{$$r_array[$i]} && $ID eq "")) {
			return $i;
		}
	}
	if ($ID eq "") {
		return $i;
	}
}

sub findKey {
	my $r_hash = shift;
	my $match = shift;
	my $ID = shift;
	foreach (keys %{$r_hash}) {
		if ($$r_hash{$_}{$match} == $ID) {
			return $_;
		}
	}
}

sub findKeyString {
	my $r_hash = shift;
	my $match = shift;
	my $ID = shift;
	foreach (keys %{$r_hash}) {
		if ($$r_hash{$_}{$match} eq $ID) {
			return $_;
		}
	}
}

sub minHeapAdd {
	my $r_array = shift;
	my $r_hash = shift;
	my $match = shift;
	my $i;
	my $found;
	my @newArray;
	for ($i = 0; $i < @{$r_array};$i++) {
		if (!$found && $$r_hash{$match} < $$r_array[$i]{$match}) {
			push @newArray, $r_hash;
			$found = 1;
		}
		push @newArray, $$r_array[$i];
	}
	if (!$found) {
		push @newArray, $r_hash;
	}
	@{$r_array} = @newArray;
}

sub existsInList2 {
	my ($list, $val, $type) = @_;
	undef @array;
	@array = split /,/, $list;
	if ($array[0] < 0) {
		return 1 if ($val eq "");
		foreach (@array) {
			s/^\s+//;
			s/\s+$//;
			s/\s+/ /g;
			next if ($_ eq "");
			return 0 if ((abs($_) eq $val) || $type eq "and" && (abs($_) & $val));
		}
		return 1;
	} else {
		return 0 if ($val eq "");
		foreach (@array) {
			s/^\s+//;
			s/\s+$//;
			s/\s+/ /g;
			next if ($_ eq "");
			return 1 if (($_ eq $val) || $type eq "and" && ($_ & $val));
		}
		return 0;
	}
}

# For sub avoidPlayer
sub existsInList_quote {
	my ($list, $val) = @_;
	undef @array;
	@array = split /,/, $list;
	return 0 if ($val eq "");
	#$val = lcCht($val);
	foreach (@array) {
		s/^\s+//;
		s/\s+$//;
		s/\s+/ /g;
		($_) = $_ =~ /^"([\s\S]*?)"$/;
		next if ($_ eq "");
		#return 1 if (lcCht($_) eq $val);
		return 1 if ($_ eq $val);
	}
	return 0;
}

sub findIndexStringWithList_KeyNotNull_lc {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $key = shift;
	my $i;
	undef @array; splitUseArray(\@array, $ID, ",");
	for ($i = 0; $i < @{$r_array} ;$i++) {
		next if (!%{$$r_array[$i]} || $$r_array[$i]{$key} eq "");
		if (existsInList($ID, $$r_array[$i]{$match})) {
			return $i;
		}
	}
}

#ICE-WR Start
sub findIndexStringPriority_lc {
	my $r_array = shift;
	my $match = shift;
	my $ID = shift;
	my $index;
	undef @array; splitUseArray(\@array, $ID, ",");
	foreach (@array) {
		next if ($_ eq "");
		$index = findIndexString_lc($r_array, $match, $_);
		if ($index ne "") {
			return $index;
		}
	}
}

#ICE-WR End

# Return index which is not selected
# findIndexStringNotSelected_lc(reference list, reference selected_list, match pattern, id);
#sub findIndexStringNotSelected_lc {
#	my $r_array1 = shift;
#	my $r_array2 = shift;
#	my $match = shift;
#	my $ID = shift;
#	my $i;
#	for ($i = 0; $i < @{$r_array1}; $i++) {
#		if ((%{$$r_array1[$i]} && lcCht($$r_array1[$i]{$match}) eq lcCht($ID)) || (!%{$$r_array1[$i]} && $ID eq "")) {
#			return $i if (binFind(\@{$r_array2}, $i) eq "");
#		}
#	}
#	if ($ID eq "") {
#		return $i;
#	}
#}
sub findIndexStringNotSelected_lc {
	my $r_array1 = shift;
	my $r_array2 = shift;
	my $match = shift;
	my $ID = shift;
	my $i;
	for ($i = 0; $i < @{$r_array1}; $i++) {
		if ((%{$$r_array1[$i]} && lcCht($$r_array1[$i]{$match}) eq lcCht($ID)) || (!%{$$r_array1[$i]} && $ID eq "")) {
			return $i if (binFind(\@{$r_array2}, $i) eq "");
		}
	}
	if ($ID eq "") {
		return $i;
	}
}

sub vocalString {
        my $letter_length = shift;
        return if ($letter_length <= 0);
        my $r_string = shift;
        my $test;
        my $i;
        my $password;
        my @cons = ("b", "c", "d", "g", "h", "j", "k", "l", "m", "n", "p", "r", "s", "t", "v", "w", "y", "z", "tr", "cl", "cr", "br", "fr", "th", "dr", "ch", "st", "sp", "sw", "pr", "sh", "gr", "tw", "wr", "ck");
        my @vowels = ("a", "e", "i", "o", "u" , "a", "e" , "i", "o", "u", "a", "e", "i", "o", "ea" , "ou" , "ie" , "ai" , "ee" , "au", "oo");
        my %badend = ( "tr" => 1, "cr" => 1, "br" => 1, "fr" => 1, "dr" => 1, "sp" => 1, "sw" => 1, "pr" =>1, "gr" => 1, "tw" => 1, "wr" => 1, "cl" => 1);
        for (;;) {
                $password = "";
                for($i = 0; $i < $letter_length; $i++){
                        $password .= $cons[rand(@cons - 1)] . $vowels[rand(@vowels - 1)];
                }
                $password = substr($password, 0, $letter_length);
                ($test) = ($password =~ /(..)\z/);
                last if ($badend{$test} != 1);
        }
        $$r_string = $password;
        return $$r_string;
}

sub makeCoords {
	my $r_hash = shift;
	my $rawCoords = shift;
	$$r_hash{'x'} = unpack("C", substr($rawCoords, 0, 1)) * 4 + (unpack("C", substr($rawCoords, 1, 1)) & 0xC0) / 64;
	$$r_hash{'y'} = (unpack("C",substr($rawCoords, 1, 1)) & 0x3F) * 16 +
				(unpack("C",substr($rawCoords, 2, 1)) & 0xF0) / 16;
}

sub makeCoords2 {
	my $r_hash = shift;
	my $rawCoords = shift;
	$$r_hash{'x'} = (unpack("C",substr($rawCoords, 1, 1)) & 0xFC) / 4 +
				(unpack("C",substr($rawCoords, 0, 1)) & 0x0F) * 64;
	$$r_hash{'y'} = (unpack("C", substr($rawCoords, 1, 1)) & 0x03) * 256 + unpack("C", substr($rawCoords, 2, 1));
}

sub makeIP {
	my $raw = shift;
	my $ret;
	my $i;
	for ($i=0;$i < 4;$i++) {
		$ret .= hex(getHex(substr($raw, $i, 1)));
		if ($i + 1 < 4) {
			$ret .= ".";
		}
	}
	return $ret;
}

sub getCoordString {
	my $x = shift;
	my $y = shift;
	return pack("C*", int($x / 4), ($x % 4) * 64 + int($y / 16), ($y % 16) * 16);
}

sub getFormattedDate {
	my $thetime = shift;
	my $r_date = shift;
	my @localtime = localtime $thetime;

	$localtime[4] = $localtime[4] + 1;
	$localtime[4] = "0" . $localtime[4] if ($localtime[4] < 10);
	$localtime[3] = "0" . $localtime[3] if ($localtime[3] < 10);
	$localtime[2] = "0" . $localtime[2] if ($localtime[2] < 10);
	$localtime[1] = "0" . $localtime[1] if ($localtime[1] < 10);
	$localtime[0] = "0" . $localtime[0] if ($localtime[0] < 10);
	$$r_date = ($localtime[5] + 1900) . "/$localtime[4]/$localtime[3] $localtime[2]:$localtime[1]:$localtime[0]";
	return $$r_date;
}

sub getHex {
	my $data = shift;
	my $i;
	my $return;
	for ($i = 0; $i < length($data); $i++) {
		$return .= uc(unpack("H2",substr($data, $i, 1)));
		if ($i + 1 < length($data)) {
			$return .= " ";
		}
	}
	return $return;
}

sub splitUseArray {
	my $r_array = shift;
	my $var = shift;
	my $sym = shift;
	@{$r_array} = split /\Q$sym\E/, $var;
	foreach (@{$r_array}) {
		s/^\s+//;
		s/\s+$//;
		s/\s+/ /g;
	}
}

sub splitUseArray_sc {
	my $var		= shift;
	my $sym		= shift;
	my $upcase	= shift;

	$var = ucCht($var) if ($upcase);

	my @r_array = split /\Q$sym\E/, $var;
	foreach (@r_array) {
		s/^\s+//;
		s/\s+$//;
		s/\s+/ /g;
	}
	return @r_array;
}

sub timeOut {
	my ($r_time, $compare_time) = @_;
	if ($compare_time ne "") {
		return (time - $r_time > $compare_time);
	} else {
		return (time - $$r_time{'time'} > $$r_time{'timeout'});
	}
}

1;