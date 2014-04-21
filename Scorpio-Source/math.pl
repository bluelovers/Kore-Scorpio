#######################################
#######################################
#AI MATH
#######################################
#######################################

sub percent_max {
	my $r_hash = shift;
	my $key = shift;

	if (!$$r_hash{"${key}_max"}) {
		return 0;
	} else {
		return ($$r_hash{"${key}"} / $$r_hash{"${key}_max"} * 100);
	}
}

sub mathInNum {
	my ($num, $min, $max, $mod, $debug) = @_;
	my $tmp;

	if ($max < $min){
		$tmp = $max;
		$max = $min;
		$min = $tmp;
	}

	if ($mod > 1) {
		return ($num <= $min && $num < $max);
	} elsif ($mod) {
		print "$num - $min - $max = ".(($num >= $min && $num <= $max)?1:0)."\n" if ($debug);
		return ($num >= $min && ($num <= $max || !$max));
	} else {
		return ($num >= $min && $num < $max);
	}
}

sub isNum {
	my $n = shift;

	if ($n =~ /^\d+$/ ) {
		return 1;
	}

	return 0;
}

sub mathPercent {
	my ($a, $b, $c, $d, $e) = @_;
	my $value;

	$d = "%.2f" if (!$d);

#	if ($e){
#		$value = $b * $e / 100;
#	} else {
#		$value = $a * 100 / $b;
#	}
	if ($e){
		$value = $b * $e / 100;
	} elsif ($b) {
		$value = $a * 100 / $b;
	}

	$value = sprintf($d, $value);

	if ($c){
		$^A = "";
		formline($c, $value);
		$value = "$^A";
	}

	return $value;

	#print mathPercent(1000, 8000, 0, "(%d)", 0);
	#print mathPercent(1000, 8000, 0, "(%d)", 1);
}

sub distance {
	my $r_hash1 = shift;
	my $r_hash2 = shift;
	my $mode = shift;
	my $val;
	my %line;
	if ($r_hash2) {
		$line{'x'} = abs($$r_hash1{'x'} - $$r_hash2{'x'});
		$line{'y'} = abs($$r_hash1{'y'} - $$r_hash2{'y'});
	} else {
		%line = %{$r_hash1};
	}

	$val = sqrt($line{'x'} ** 2 + $line{'y'} ** 2);

	$val = int($val) if (!$mode);

	return $val;
}

sub getVector {
	my $r_store = shift;
	my $r_head = shift;
	my $r_tail = shift;
	$$r_store{'x'} = $$r_head{'x'} - $$r_tail{'x'};
	$$r_store{'y'} = $$r_head{'y'} - $$r_tail{'y'};
}

sub lineIntersection {
	my $r_pos1 = shift;
	my $r_pos2 = shift;
	my $r_pos3 = shift;
	my $r_pos4 = shift;
	my ($x1, $x2, $x3, $x4, $y1, $y2, $y3, $y4, $result, $result1, $result2);
	$x1 = $$r_pos1{'x'};
	$y1 = $$r_pos1{'y'};
	$x2 = $$r_pos2{'x'};
	$y2 = $$r_pos2{'y'};
	$x3 = $$r_pos3{'x'};
	$y3 = $$r_pos3{'y'};
	$x4 = $$r_pos4{'x'};
	$y4 = $$r_pos4{'y'};
	$result1 = ($x4 - $x3)*($y1 - $y3) - ($y4 - $y3)*($x1 - $x3);
	$result2 = ($y4 - $y3)*($x2 - $x1) - ($x4 - $x3)*($y2 - $y1);
	if ($result2 != 0) {
		$result = $result1 / $result2;
	}
	return $result;
}


sub moveAlongVector {
	my $r_store = shift;
	my $r_pos = shift;
	my $r_vec = shift;
	my $amount = shift;
	my %norm;
	if ($amount) {
		normalize(\%norm, $r_vec);
		$$r_store{'x'} = $$r_pos{'x'} + $norm{'x'} * $amount;
		$$r_store{'y'} = $$r_pos{'y'} + $norm{'y'} * $amount;
	} else {
		$$r_store{'x'} = $$r_pos{'x'} + $$r_vec{'x'};
		$$r_store{'y'} = $$r_pos{'y'} + $$r_vec{'y'};
	}
}

sub normalize {
	my $r_store = shift;
	my $r_vec = shift;
	my $dist;
	$dist = distance($r_vec);
	if ($dist > 0) {
		$$r_store{'x'} = $$r_vec{'x'} / $dist;
		$$r_store{'y'} = $$r_vec{'y'} / $dist;
	} else {
		$$r_store{'x'} = 0;
		$$r_store{'y'} = 0;
	}
}

sub percent_hp {
	my $r_hash = shift;
	if (!$$r_hash{'hp_max'}) {
		return 0;
	} else {
		return ($$r_hash{'hp'} / $$r_hash{'hp_max'} * 100);
	}
}

sub percent_sp {
	my $r_hash = shift;
	if (!$$r_hash{'sp_max'}) {
		return 0;
	} else {
		return ($$r_hash{'sp'} / $$r_hash{'sp_max'} * 100);
	}
}

sub percent_weight {
	my $r_hash = shift;
	if (!$$r_hash{'weight_max'}) {
		return 0;
	} else {
		return ($$r_hash{'weight'} / $$r_hash{'weight_max'} * 100);
	}
}

sub getRand {
	my $tDefault = shift;
	my $tRandom = shift;
	my $t = int($tDefault) + int(rand() * $tRandom + 1);
	return $t;
}

sub getNinePos {
	my $r_centerPos = shift;
	my $r_checkPos = shift;
	if ($$r_checkPos{'x'} - $$r_centerPos{'x'} == -1 && $$r_checkPos{'y'} - $$r_centerPos{'y'} == 1) {
		return 1;
	} elsif ($$r_checkPos{'x'} - $$r_centerPos{'x'} == 0 && $$r_checkPos{'y'} - $$r_centerPos{'y'} == 1) {
		return 2;
	} elsif ($$r_checkPos{'x'} - $$r_centerPos{'x'} == 1 && $$r_checkPos{'y'} - $$r_centerPos{'y'} == 1) {
		return 3;
	} elsif ($$r_checkPos{'x'} - $$r_centerPos{'x'} == -1 && $$r_checkPos{'y'} - $$r_centerPos{'y'} == 0) {
		return 4;
	} elsif ($$r_checkPos{'x'} - $$r_centerPos{'x'} == 0 && $$r_checkPos{'y'} - $$r_centerPos{'y'} == 0) {
		return 5;
	} elsif ($$r_checkPos{'x'} - $$r_centerPos{'x'} == 1 && $$r_checkPos{'y'} - $$r_centerPos{'y'} == 0) {
		return 6;
	} elsif ($$r_checkPos{'x'} - $$r_centerPos{'x'} == -1 && $$r_checkPos{'y'} - $$r_centerPos{'y'} == -1) {
		return 7;
	} elsif ($$r_checkPos{'x'} - $$r_centerPos{'x'} == 0 && $$r_checkPos{'y'} - $$r_centerPos{'y'} == -1) {
		return 8;
	} elsif ($$r_checkPos{'x'} - $$r_centerPos{'x'} == 1 && $$r_checkPos{'y'} - $$r_centerPos{'y'} == -1) {
		return 9;
	} else {
		return 0;
	}
}

sub getNinePosFull {
	my $r_array = shift;
	my $i;
	for ($i = 1;$i <= 9;$i++) {
		last if (!$$r_array[$i]);
		return 1 if ($i == 9);
	}
}

sub lenNum {
	my $num = shift;
	my $len = shift;
	my $idx = length($num);

	if ($len > $idx){
		$num = '0'x($len - $idx).$num
	}

	return $num;
}

sub toZeny {
	my ($num, $rev) = @_;

	if (!$rev){
		my $c = ($num < 0)?"-":"";

		$num = abs($num);

		my $len = length($num);
		my $idx;
		my $idx2;
		my $i;

		$idx2 = int($len / 3) - 1;
		$idx2++ if ($len % 3);

		for ($i=0; $i < $idx2; $i++){
			$idx++;
			$idx = $i*4 + 3;
			substr($num, -$idx, 0) = ",";
		}

		$num = $c.$num;
	} else {
		my @array = split(/,/, $num);
		$num = join("", @array);
	}

	return $num;
}

sub posToRand {
	my %r_hash = (
		x => 0,
		y => 0
	);
	my $t_hash = shift;
	my $r_dist = shift;
	my $r_type = shift;
	my $r_min  = shift;
	my $val;

	$r_dist = abs($r_dist);

#	print "$$t_hash{'x'} , $$t_hash{'y'}\n";

	do {
		$r_hash{'x'} = $$t_hash{'x'} + int(rand() * ($r_dist * 2 + 1)) - $r_dist;
		$r_hash{'y'} = $$t_hash{'y'} + int(rand() * ($r_dist * 2 + 1)) - $r_dist;

		if ($r_type){
			$val = pos2pos(\%{$r_hash}, \%{$t_hash});
		} else {
			$val = 0;
		}
		$val = 0 if ($r_min && distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$r_hash}) < $r_min);
	} while ($val);

#	print "$r_hash{'x'} , $r_hash{'y'}\n";

	return ($r_hash{'x'}, $r_hash{'y'});
}

sub posToCoordinate {
	my $r_hash = shift;
	my $char = shift;
	my $value = swrite2(
			"@>>,@>>",
			[$$r_hash{'x'}, $$r_hash{'y'}]
			);

#	chomp($value);

	if ($char > 1){
		$value = "( Coordinate : ".$value." )";
	} elsif ($char) {
		$value = "(".$value.")";
	}

	return $value;
}

sub pos2pos {
	my $r_hash = shift;
	my $t_hash = shift;
	my $val = 0;

	$val = 1 if ($$r_hash{'x'} == $$t_hash{'x'} && $$r_hash{'y'} == $$t_hash{'y'});

	return $val;
}

sub posBypos {
	my $r_hash = shift;
	my $t_hash = shift;

	$$r_hash{'x'} = $$t_hash{'x'};
	$$r_hash{'y'} = $$t_hash{'y'};
}

1;