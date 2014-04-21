#######################################
#######################################
#AI FUNCTIONS
#######################################
#######################################

sub ai_clientSuspend {
	my ($type, $initTimeout, @args) = @_;
	my %args;
	$args{'type'} = $type;
	$args{'time'} = time;
	$args{'timeout'} = $initTimeout;
	@{$args{'args'}} = @args;
	unshift @ai_seq, "clientSuspend";
	unshift @ai_seq_args, \%args;
}

sub ai_follow {
	my $name = shift;
	my %args;
	($args{'name'}) = $name =~ /^"([\s\S]*?)"$/;

	aiRemove("follow");

	unshift @ai_seq, "follow";
	unshift @ai_seq_args, \%args;

	timeOutStart('ai_follow');
}

sub ai_getAggressives {
	my $mode = shift;

	my @agMonsters;

	if (!$mode) {

		foreach (@monstersID) {
#			next if ($_ eq "");
			next if ($_ eq "" || $monsters_old{$_}{'disappeared'} || $monsters_old{$_}{'dead'});

			if (($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0) && $monsters{$_}{'attack_failed'} <= 1) {
				push @agMonsters, $_;
			}
		}

	} else {

		foreach (@monstersID) {
			next if ($_ eq "" || ($mon_control{'all'}{'attack_auto'} eq "0" && $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "") || $monsters_old{$_}{'disappeared'} || $monsters_old{$_}{'dead'});
			if (
				ks_isTrue($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'})
				&&
				($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0)
				&& $monsters{$_}{'attack_failed'} <= 1
			) {
				push @agMonsters, $_;
			}
		}

	}

	return @agMonsters;
}

sub ai_getIDFromChat {
	my $r_hash = shift;
	my $msg_user = shift;
	my $match_text = shift;
	my $qm;
	if ($match_text !~ /\w+/ || $match_text eq "me") {
		foreach (keys %{$r_hash}) {
			next if ($_ eq "");
			if ($msg_user eq $$r_hash{$_}{'name'}) {
				return $_;
			}
		}
	} else {
		foreach (keys %{$r_hash}) {
			next if ($_ eq "");
			$qm = quotemeta $match_text;
			if ($$r_hash{$_}{'name'} =~ /$qm/i) {
				return $_;
			}
		}
	}
}

sub ai_getMonstersWhoHitMe {
	my @agMonsters;
	foreach (@monstersID) {
		next if ($_ eq "");
#		next if ($_ eq "" || $monsters_old{$_}{'disappeared'} || $monsters_old{$_}{'dead'});
#		if ($monsters{$_}{'dmgToYou'} > 0 && $monsters{$_}{'attack_failed'} <= 1) {
#			push @agMonsters, $_;
#		}
		if (($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0) && $monsters{$_}{'attack_failed'} <= 1) {
			push @agMonsters, $_;
		}
	}
	return @agMonsters;
}

sub ai_getMonstersHitMe {
	my @agMonsters;
	foreach (@monstersID) {
		next if ($_ eq "" || $monsters_old{$_}{'disappeared'} || $monsters_old{$_}{'dead'});
#		if ($monsters{$_}{'dmgToYou'} > 0 && $monsters{$_}{'attack_failed'} <= 1) {
#			push @agMonsters, $_;
#		}
#		if (($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0 || $monsters{$_}{'dmgFromYou'} > 0) && $monsters{$_}{'attack_failed'} <= 1) {
		if ($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0) {
			return 1;
		}
	}
	return 0;
}

sub ai_getSkillUseType {
	my $skill = shift;

	my $val = switchInput($skill
		, "WZ_FIREPILLAR"
		, "WZ_METEOR"
		, "WZ_VERMILION"
		, "WZ_STORMGUST"
		, "WZ_HEAVENDRIVE"
		, "WZ_QUAGMIRE"
		, "MG_SAFETYWALL"
		, "MG_FIREWALL"
		, "MG_THUNDERSTORM"
		, "AL_PNEUMA"
		, "AL_WARP"
		, "PR_SANCTUARY"
		, "PR_MAGNUS"
		, "BS_HAMMERFALL"
		, "TF_PICKSTONE"
		, "AS_VENOMDUST"
		, "HT_SKIDTRAP"
		, "HT_LANDMINE"
		, "HT_ANKLESNARE"
		, "HT_SHOCKWAVE"
		, "HT_SANDMAN"
		, "HT_FLASHER"
		, "HT_FREEZINGTRAP"
		, "HT_BLASTMINE"
		, "HT_CLAYMORETRAP"
		, "AM_DEMONSTRATION"
		, "AM_CANNIBALIZE"
		, "AM_SPHEREMINE"
		, "MO_BODYRELOCATION"
		, "SA_VOLCANO"
		, "SA_DELUGE"
		, "SA_VIOLENTGALE"
		, "SA_LANDPROTECTOR"

		, "SM_MAGNUM"
		, "AC_SHOWER"
#		, "ASC_METEORASSAULT"

	);

	return $val;
}

sub ai_mapRoute_getRoute {

	my %args;

	##VARS

	$args{'g_normal'} = 1;

	###

	my ($returnArray, $r_start_field, $r_start_pos, $r_dest_field, $r_dest_pos, $time_giveup) = @_;
	$args{'returnArray'} = $returnArray;
	$args{'r_start_field'} = $r_start_field;
	$args{'r_start_pos'} = $r_start_pos;
	$args{'r_dest_field'} = $r_dest_field;
	$args{'r_dest_pos'} = $r_dest_pos;
	$args{'time_giveup'}{'timeout'} = $time_giveup;
	$args{'time_giveup'}{'time'} = time;
	unshift @ai_seq, "route_getMapRoute";
	unshift @ai_seq_args, \%args;
}

sub ai_mapRoute_getSuccessors {
	my ($r_args, $r_array, $r_cur) = @_;
	my $ok;
	foreach (keys %portals_lut) {
		if ($portals_lut{$_}{'source'}{'map'} eq $$r_cur{'dest'}{'map'}

			&& !($$r_cur{'source'}{'map'} eq $portals_lut{$_}{'dest'}{'map'}
			&& $$r_cur{'source'}{'pos'}{'x'} == $portals_lut{$_}{'dest'}{'pos'}{'x'}
			&& $$r_cur{'source'}{'pos'}{'y'} == $portals_lut{$_}{'dest'}{'pos'}{'y'})

			&& !(%{$$r_cur{'parent'}} && $$r_cur{'parent'}{'source'}{'map'} eq $portals_lut{$_}{'dest'}{'map'}
			&& $$r_cur{'parent'}{'source'}{'pos'}{'x'} == $portals_lut{$_}{'dest'}{'pos'}{'x'}
			&& $$r_cur{'parent'}{'source'}{'pos'}{'y'} == $portals_lut{$_}{'dest'}{'pos'}{'y'})) {
			undef $ok;
			if (!%{$$r_cur{'parent'}}) {
				if (!$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solutionTried'}) {
					$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solutionTried'} = 1;
					$timeout{'ai_route_calcRoute'}{'time'} -= $timeout{'ai_route_calcRoute'}{'timeout'};
					$$r_args{'waitingForSolution'} = 1;
					ai_route_getRoute(\@{$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solution'}},
							$$r_args{'start'}{'dest'}{'field'}, \%{$$r_args{'start'}{'dest'}{'pos'}}, \%{$portals_lut{$_}{'source'}{'pos'}});
					last;
				}
				$ok = 1 if (@{$$r_args{'solutions'}{$$r_args{'start'}{'dest'}{'field'}.\%{$$r_args{'start'}{'dest'}{'pos'}}.\%{$portals_lut{$_}{'source'}{'pos'}}}{'solution'}});
			} elsif ($portals_los{$$r_cur{'dest'}{'ID'}}{$portals_lut{$_}{'source'}{'ID'}} ne "0"
				&& $portals_los{$portals_lut{$_}{'source'}{'ID'}}{$$r_cur{'dest'}{'ID'}} ne "0") {
				$ok = 1;
			}
			if ($$r_args{'dest'}{'source'}{'pos'}{'x'} ne "" && $portals_lut{$_}{'dest'}{'map'} eq $$r_args{'dest'}{'source'}{'map'}) {
				if (!$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solutionTried'}) {
					$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solutionTried'} = 1;
					$timeout{'ai_route_calcRoute'}{'time'} -= $timeout{'ai_route_calcRoute'}{'timeout'};
					$$r_args{'waitingForSolution'} = 1;
					ai_route_getRoute(\@{$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$portals_lut{$_}{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solution'}},
							$$r_args{'dest'}{'source'}{'field'}, \%{$portals_lut{$_}{'dest'}{'pos'}}, \%{$$r_args{'dest'}{'source'}{'pos'}});
					last;
				}
			}
			push @{$r_array}, \%{$portals_lut{$_}} if $ok;
		}
	}
}

sub ai_mapRoute_searchStep {
	my $r_args = shift;
	my @successors;
	my ($r_cur, $r_suc);
	my $i;

	###check if failed
	if (!@{$$r_args{'openList'}}) {
		#failed!
		$$r_args{'done'} = 1;
		return;
	}

	$r_cur = shift @{$$r_args{'openList'}};

	###check if finished
	if ($$r_args{'dest'}{'source'}{'map'} eq $$r_cur{'dest'}{'map'}
		&& (@{$$r_args{'solutions'}{$$r_args{'dest'}{'source'}{'field'}.\%{$$r_cur{'dest'}{'pos'}}.\%{$$r_args{'dest'}{'source'}{'pos'}}}{'solution'}}
		|| $$r_args{'dest'}{'source'}{'pos'}{'x'} eq "")) {
		do {
			unshift @{$$r_args{'solutionList'}}, {%{$r_cur}};
			$r_cur = $$r_cur{'parent'} if (%{$$r_cur{'parent'}});
		} while ($r_cur != \%{$$r_args{'start'}});
		$$r_args{'done'} = 1;
		return;
	}

	ai_mapRoute_getSuccessors($r_args, \@successors, $r_cur);
	if ($$r_args{'waitingForSolution'}) {
		undef $$r_args{'waitingForSolution'};
		unshift @{$$r_args{'openList'}}, $r_cur;
		return;
	}

	$newg = $$r_cur{'g'} + $$r_args{'g_normal'};
	foreach $r_suc (@successors) {
		undef $found;
		undef $openFound;
		undef $closedFound;
		for($i = 0; $i < @{$$r_args{'openList'}}; $i++) {
			if ($$r_suc{'dest'}{'map'} eq $$r_args{'openList'}[$i]{'dest'}{'map'}
				&& $$r_suc{'dest'}{'pos'}{'x'} == $$r_args{'openList'}[$i]{'dest'}{'pos'}{'x'}
				&& $$r_suc{'dest'}{'pos'}{'y'} == $$r_args{'openList'}[$i]{'dest'}{'pos'}{'y'}) {
				if ($newg >= $$r_args{'openList'}[$i]{'g'}) {
					$found = 1;
					}
				$openFound = $i;
				last;
			}
		}
		next if ($found);

		undef $found;
		for($i = 0; $i < @{$$r_args{'closedList'}}; $i++) {
			if ($$r_suc{'dest'}{'map'} eq $$r_args{'closedList'}[$i]{'dest'}{'map'}
				&& $$r_suc{'dest'}{'pos'}{'x'} == $$r_args{'closedList'}[$i]{'dest'}{'pos'}{'x'}
				&& $$r_suc{'dest'}{'pos'}{'y'} == $$r_args{'closedList'}[$i]{'dest'}{'pos'}{'y'}) {
				if ($newg >= $$r_args{'closedList'}[$i]{'g'}) {
					$found = 1;
				}
				$closedFound = $i;
				last;
			}
		}
		next if ($found);
		if ($openFound ne "") {
			binRemoveAndShiftByIndex(\@{$$r_args{'openList'}}, $openFound);
		}
		if ($closedFound ne "") {
			binRemoveAndShiftByIndex(\@{$$r_args{'closedList'}}, $closedFound);
		}
		$$r_suc{'g'} = $newg;
		$$r_suc{'h'} = 0;
		$$r_suc{'f'} = $$r_suc{'g'} + $$r_suc{'h'};
		$$r_suc{'parent'} = $r_cur;
		minHeapAdd(\@{$$r_args{'openList'}}, $r_suc, "f");
	}
	push @{$$r_args{'closedList'}}, $r_cur;
}

sub ai_items_take {
	my ($x1, $y1, $x2, $y2) = @_;
	my %args;
	$args{'pos'}{'x'} = $x1;
	$args{'pos'}{'y'} = $y1;
	$args{'pos_to'}{'x'} = $x2;
	$args{'pos_to'}{'y'} = $y2;
	$args{'ai_items_take_end'}{'time'} = time;
	$args{'ai_items_take_end'}{'timeout'} = $timeout{'ai_items_take_end'}{'timeout'};
	$args{'ai_items_take_start'}{'time'} = time;
	$args{'ai_items_take_start'}{'timeout'} = $timeout{'ai_items_take_start'}{'timeout'};
	unshift @ai_seq, "items_take";
	unshift @ai_seq_args, \%args;
}

sub ai_route {
	my ($r_ret, $x, $y, $map, $maxRouteDistance, $maxRouteTime, $attackOnRoute, $avoidPortals, $distFromGoal, $checkInnerPortals) = @_;
	my %args;
	$x = int($x) if ($x ne "");
	$y = int($y) if ($y ne "");
	$args{'returnHash'} = $r_ret;
	$args{'dest_x'} = $x;
	$args{'dest_y'} = $y;
	$args{'dest_map'} = $map;
	$args{'maxRouteDistance'} = $maxRouteDistance;
	$args{'maxRouteTime'} = $maxRouteTime;
	$args{'attackOnRoute'} = $attackOnRoute;
	$args{'avoidPortals'} = $avoidPortals;
	$args{'distFromGoal'} = $distFromGoal;
	$args{'checkInnerPortals'} = $checkInnerPortals;
	undef %{$args{'returnHash'}};
	unshift @ai_seq, "route";
	unshift @ai_seq_args, \%args;
	print "On route to: $maps_lut{$map.'.rsw'}($map): $x, $y\n" if ($config{'debug'});
}

sub ai_route_getDiagSuccessors {
	my $r_args = shift;
	my $r_pos = shift;
	my $r_array = shift;
	my $type = shift;
	my %pos;

	if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}-1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
		$pos{'x'} = $$r_pos{'x'}-1;
		$pos{'y'} = $$r_pos{'y'}-1;
		push @{$r_array}, {%pos};
	}

	if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}-1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
		$pos{'x'} = $$r_pos{'x'}+1;
		$pos{'y'} = $$r_pos{'y'}-1;
		push @{$r_array}, {%pos};
	}

	if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}+1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
		$pos{'x'} = $$r_pos{'x'}+1;
		$pos{'y'} = $$r_pos{'y'}+1;
		push @{$r_array}, {%pos};
	}


	if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}+1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
		$pos{'x'} = $$r_pos{'x'}-1;
		$pos{'y'} = $$r_pos{'y'}+1;
		push @{$r_array}, {%pos};
	}
}

#Karasu Start
sub ai_route_getMap {
	my $r_args = shift;
	my $x = shift;
	my $y = shift;
	return ai_route_getOffset(\%{$$r_args{'field'}}, $x, $y);
}

sub ai_route_getOffset {
	my $r_args = shift;
	my $x = shift;
	my $y = shift;
	$x = int($x); $y = int($y);
	if ($x < 0 || $x >= $$r_args{'width'} || $y < 0 || $y >= $$r_args{'height'}) {
		return 1;
	}
# Use substr instead of large array
#	return $$r_args{'field'}[($y*$$r_args{'width'})+$x];
	return unpack("C", substr($$r_args{'rawMap'}, ($y*$$r_args{'width'})+$x, 1));
}
#Karasu End

sub ai_route_getRoute {
	my %args;
	my ($returnArray, $r_field, $r_start, $r_dest, $time_giveup) = @_;
	$args{'returnArray'} = $returnArray;
	$args{'field'} = $r_field;
	%{$args{'start'}} = %{$r_start};
	%{$args{'dest'}} = %{$r_dest};
	$args{'time_giveup'}{'timeout'} = $time_giveup;
	$args{'time_giveup'}{'time'} = time;
	$args{'destroyFunction'} = \&ai_route_getRoute_destroy;
	undef @{$args{'returnArray'}};
	unshift @ai_seq, "route_getRoute";
	unshift @ai_seq_args, \%args;
}

sub ai_route_getRoute_destroy {
	my $r_args = shift;
#ICE-WR Start
	return if ($$r_args{'session'} eq "");
#ICE-WR End
	if (!$config{'buildType'}) {
		$CalcPath_destroy->Call($$r_args{'session'});
	} elsif ($config{'buildType'} == 1) {
		&{$CalcPath_destroy}($$r_args{'session'});
	}
}
sub ai_route_searchStep {
	my $r_args = shift;
	my $ret;

	if (!$$r_args{'initialized'}) {
		#####
		my $SOLUTION_MAX = 5000;
		$$r_args{'solution'} = "\0" x ($SOLUTION_MAX*4+4);
		#####
		if (!$config{'buildType'}) {
			$$r_args{'session'} = $CalcPath_init->Call($$r_args{'solution'},
				$$r_args{'field'}{'rawMap'}, $$r_args{'field'}{'width'}, $$r_args{'field'}{'height'},
				pack("S*", $$r_args{'start'}{'x'}, $$r_args{'start'}{'y'}), pack("S*", $$r_args{'dest'}{'x'}, $$r_args{'dest'}{'y'}), $$r_args{'timeout'});
		} elsif ($config{'buildType'} == 1) {
			$$r_args{'session'} = &{$CalcPath_init}($$r_args{'solution'},
				$$r_args{'field'}{'rawMap'}, $$r_args{'field'}{'width'}, $$r_args{'field'}{'height'},
				pack("S*", $$r_args{'start'}{'x'}, $$r_args{'start'}{'y'}), pack("S*", $$r_args{'dest'}{'x'}, $$r_args{'dest'}{'y'}), $$r_args{'timeout'});

		}
	}
	if ($$r_args{'session'} < 0) {
		$$r_args{'done'} = 1;
		return;
	}
	$$r_args{'initialized'} = 1;
	if (!$config{'buildType'}) {
		$ret = $CalcPath_pathStep->Call($$r_args{'session'});
	} elsif ($config{'buildType'} == 1) {
		$ret = &{$CalcPath_pathStep}($$r_args{'session'});
	}
	if (!$ret) {
		my $size = unpack("L",substr($$r_args{'solution'},0,4));
		my $j = 0;
		my $i;
		for ($i = ($size-1)*4+4; $i >= 4;$i-=4) {
			$$r_args{'returnArray'}[$j]{'x'} = unpack("S",substr($$r_args{'solution'}, $i, 2));
			$$r_args{'returnArray'}[$j]{'y'} = unpack("S",substr($$r_args{'solution'}, $i+2, 2));
			$j++;
		}
		$$r_args{'done'} = 1;
	}
}

sub ai_route_getSuccessors {
	my $r_args = shift;
	my $r_pos = shift;
	my $r_array = shift;
	my $type = shift;
	my %pos;

	if (ai_route_getMap($r_args, $$r_pos{'x'}-1, $$r_pos{'y'}) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}-1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'})) {
		$pos{'x'} = $$r_pos{'x'}-1;
		$pos{'y'} = $$r_pos{'y'};
		push @{$r_array}, {%pos};
	}

	if (ai_route_getMap($r_args, $$r_pos{'x'}, $$r_pos{'y'}-1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'} && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}-1)) {
		$pos{'x'} = $$r_pos{'x'};
		$pos{'y'} = $$r_pos{'y'}-1;
		push @{$r_array}, {%pos};
	}

	if (ai_route_getMap($r_args, $$r_pos{'x'}+1, $$r_pos{'y'}) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'}+1 && $$r_pos{'parent'}{'y'} == $$r_pos{'y'})) {
		$pos{'x'} = $$r_pos{'x'}+1;
		$pos{'y'} = $$r_pos{'y'};
		push @{$r_array}, {%pos};
	}


	if (ai_route_getMap($r_args, $$r_pos{'x'}, $$r_pos{'y'}+1) == $type
		&& !($$r_pos{'parent'} && $$r_pos{'parent'}{'x'} == $$r_pos{'x'} && $$r_pos{'parent'}{'y'} == $$r_pos{'y'}+1)) {
		$pos{'x'} = $$r_pos{'x'};
		$pos{'y'} = $$r_pos{'y'}+1;
		push @{$r_array}, {%pos};
	}
}

#sellAuto for items_control - chobit andy 20030210
sub ai_sellAutoCheck {
	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
		next if (
			!%{$chars[$config{'char'}]{'inventory'}[$i]}
			|| $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne ""
		);
		if (
			$items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'sell'}
			&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}
		) {
			return 1;
		}
	}
}

sub ai_setMapChanged {
	my $index = shift;
	$index = 0 if ($index eq "");
	if ($index < @ai_seq_args) {
		$ai_seq_args[$index]{'mapChanged'} = time;
	}
	$ai_v{'portalTrace_mapChanged'} = 1;
}

sub ai_setSuspend {
	my $index = shift;
	$index = 0 if ($index eq "");
	if ($index < @ai_seq_args) {
		$ai_seq_args[$index]{'suspended'} = time;
	}
}

sub ai_skillUse {
	my $ID = shift;
	my $lv = shift;
	my $maxCastTime = shift;
	my $minCastTime = shift;
	my $target = shift;
	my $y = shift;
	my $ignorePos = shift;
	my $type = shift;
	my %args;
	$args{'ai_skill_use_giveup'}{'time'} = time;
	$args{'ai_skill_use_giveup'}{'timeout'} = $timeout{'ai_skill_use_giveup'}{'timeout'};
	$args{'skill_use_id'} = $ID;
	$args{'skill_use_lv'} = $lv;
	$args{'skill_use_maxCastTime'}{'time'} = time;
	$args{'skill_use_maxCastTime'}{'timeout'} = $maxCastTime;
	$args{'skill_use_minCastTime'}{'time'} = time;
	$args{'skill_use_minCastTime'}{'timeout'} = $minCastTime;

	$args{'skill_use_type'} = $type;

	$args{'skill_use_first'} = 1;
	$args{'skill_success'} = 0;

	if ($y eq "") {
		$args{'skill_use_target'} = $target;
	} else {
		$args{'skill_use_target_x'} = $target;
		$args{'skill_use_target_y'} = $y;
	}
	$args{'skill_use_ignorePos'} = $ignorePos;

	unshift @ai_seq, "skill_use";
	unshift @ai_seq_args, \%args;
	# Equip when skill use
	my $ai_index_attack = binFind(\@ai_seq, "attack");
	ai_equip($ai_index_attack, 0, 0);
	timeOutStart('ai_equip_auto');
}

#storageAuto for items_control - chobit andy 20030210
sub ai_storageAutoCheck {
	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
		next if (
			!%{$chars[$config{'char'}]{'inventory'}[$i]}
			|| $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne ""
		);
		if (
			$items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'}
			&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}
		) {
			return 1;
		}
	}
}

sub attack {
	my $ID = shift;
	my $mode = shift;
	my %args;

	if ($ai_v{'temp'}{'teleOnEvent'} && $config{'attackAuto_stopOnTele'}){
		my $ai_index = binFind(\@ai_seq, "attack");
		if ($ai_seq_args[$ai_index]{'ID'}){
			attackForceStop(\$remote_socket, $ai_seq_args[$ai_index]{'ID'});
			print "⊕順移中停止鎖定攻擊目標: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n";
		}
		return 0;
	}

	$args{'ai_attack_giveup'}{'time'} = time;
	$args{'ai_attack_giveup'}{'timeout'} = $timeout{'ai_attack_giveup'}{'timeout'};
	$args{'ID'} = $ID;
	%{$args{'pos_to'}} = %{$monsters{$ID}{'pos_to'}};
	%{$args{'pos'}} = %{$monsters{$ID}{'pos'}};
	unshift @ai_seq, "attack";
	unshift @ai_seq_args, \%args;

	my $tmp = "⊕鎖定攻擊目標: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})";

	# Show HP
	if ($chars[$config{'char'}]{'hp_max'} && (1 || $config{'hideMsg_attackMiss'})) {
		undef $showHP{'hppercent_now'};
		$showHP{'hppercent_now'} = int(percent_hp(\%{$chars[$config{'char'}]}));
		$showHP{'hppercent_now'} = ($showHP{'hppercent_now'} > 1) ? int($showHP{'hppercent_now'}) : 1;
		$tmp .= " ●($showHP{'hppercent_now'}%)";
	}

	$tmp .= " - Dist: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ID}{'pos_to'}});

#	print "$tmp\n";

	sysLog("ii", "怪物", "$tmp", 1, !$mode);

	timeOutStart(-1, 'ai_hitAndRun');
	# Equip when attack
#	if ($config{'autoSwitch'}){
		ai_equip(0, "", 1);
		timeOutStart('ai_equip_auto');
#	}
}

# Stop attacking
sub attackForceStop {
	my $r_socket = shift;
	my $ID = shift;
	return if (binFind(\@ai_seq, "attack") eq "");

	$tmp = "⊙停止攻擊目標: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})";
	$tmp .= getTotal($accountID, $ID2) if (!$config{'hideMsg_attackDmgFromYou'});
	$tmp .= " - Dist: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ID}{'pos_to'}});

	print "$tmp\n";

	aiRemove("attack");
	sendAttackStop($r_socket);
}

sub aiRemove {
	my $ai_type = shift;
	my $index;
	while (1) {
		$index = binFind(\@ai_seq, $ai_type);
		if ($index ne "") {
			if ($ai_seq_args[$index]{'destroyFunction'}) {
				&{$ai_seq_args[$index]{'destroyFunction'}}(\%{$ai_seq_args[$index]});
			}
			binRemoveAndShiftByIndex(\@ai_seq, $index);
			binRemoveAndShiftByIndex(\@ai_seq_args, $index);
		} else {
			last;
		}
	}
}


sub gather {
	my $ID = shift;
	my %args;
	$args{'ai_items_gather_giveup'}{'time'} = time;
	$args{'ai_items_gather_giveup'}{'timeout'} = $timeout{'ai_items_gather_giveup'}{'timeout'};
	$args{'ID'} = $ID;
	%{$args{'pos'}} = %{$items{$ID}{'pos'}};
	unshift @ai_seq, "items_gather";
	unshift @ai_seq_args, \%args;
	print "Targeting for Gather: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if ($config{'debug'});

#	sendTake(\$remote_socket, $ID);
}


sub look {
	my $body = shift;
	my $head = shift;
	my %args;
	unshift @ai_seq, "look";
	$args{'look_body'} = $body;
	$args{'look_head'} = $head;
	unshift @ai_seq_args, \%args;
}

sub move {
	my $x = shift;
	my $y = shift;
	my %args;
	$args{'move_to'}{'x'} = $x;
	$args{'move_to'}{'y'} = $y;
	$args{'ai_move_giveup'}{'time'} = time;
	$args{'ai_move_giveup'}{'timeout'} = $timeout{'ai_move_giveup'}{'timeout'};
	unshift @ai_seq, "move";
	unshift @ai_seq_args, \%args;
}

sub sit {
	timeOutStart('ai_sit_wait');
	unshift @ai_seq, "sitting";
	unshift @ai_seq_args, {};

	if ($warp{'use'} != 26 && $config{'teleportAuto_onSitting'} && $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} > 0) {
		sendSkillUse(\$remote_socket, $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'ID'}, $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'}, $accountID);
	}
}

sub stand {
	unshift @ai_seq, "standing";
	unshift @ai_seq_args, {};
}

sub take {
	my ($ID, $mode) = @_;
	my %args;
	$args{'ai_take_giveup'}{'time'} = time;
#	$args{'ai_take_giveup'}{'timeout'} = ($mode ? $timeout{'ai_take_giveup_important'}{'timeout'} : $timeout{'ai_take_giveup'}{'timeout'});

	if ($mode >= 5 && $config{'itemsImportantAutoMode'}) {
		$args{'ai_take_giveup'}{'timeout'} = $timeout{'ai_take_giveup_important'}{'timeout'} * 10;
		timeOutStart(-1, 'ai_take');
	} elsif ($mode > 0) {
		$args{'ai_take_giveup'}{'timeout'} = $timeout{'ai_take_giveup_important'}{'timeout'};
		timeOutStart(-1, 'ai_take');
	} elsif ($mode < 0) {
		$args{'ai_take_giveup'}{'timeout'} = $timeout{'ai_take_giveup_gather'}{'timeout'};
	} else {
		$args{'ai_take_giveup'}{'timeout'} = $timeout{'ai_take_giveup'}{'timeout'};
	}

	$args{'mode'} = $mode;
#	if ($mode) {
#		$args{'ai_take_giveup'}{'timeout'} = $timeout{'ai_take_giveup'}{'timeout'} + $timeout{'ai_take_giveup_important'}{'timeout'};
#		$args{'mode'} = 1;
#	} else {
#		$args{'ai_take_giveup'}{'timeout'} = $timeout{'ai_take_giveup'}{'timeout'};
#	}
	$args{'ID'} = $ID;
	%{$args{'pos'}} = %{$items{$ID}{'pos'}};
	unshift @ai_seq, "take";
	unshift @ai_seq_args, \%args;
	print "Targeting for Gather: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if ($config{'debug'});

	sendTake(\$remote_socket, $ID);
}

sub ai_equip {
	my $ai_index_attack = shift;
	my $ai_index_skill_use = shift;
	my $checkDefaultWeapon = shift;
	my $prefix;
	my ($i, $j, $k);
	$i = 0;
	while (1) {
		last if (!$config{"equipAuto_$i"."_0"} && !$checkDefaultWeapon);
		if (
			(
				(
					$config{"equipAuto_$i"."_ignoreHpSp"}
					|| (
						percent_hp(\%{$chars[$config{'char'}]}) >= $config{"equipAuto_$i"."_hp_lower"}
						&& percent_hp(\%{$chars[$config{'char'}]}) <= $config{"equipAuto_$i"."_hp_upper"}
						&& percent_sp(\%{$chars[$config{'char'}]}) >= $config{"equipAuto_$i"."_sp_lower"}
						&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"equipAuto_$i"."_sp_upper"}
					)
				)
				&& (
					!$config{"equipAuto_$i"."_monsters"}
					|| $ai_index_attack ne ""
					&& existsInList($config{"equipAuto_$i"."_monsters"}, $monsters{$ai_seq_args[$ai_index_attack]{'ID'}}{'name'})
				)
				&& (
					!$config{"equipAuto_$i"."_skills"}
					|| $ai_index_skill_use ne ""
					&& existsInList($config{"equipAuto_$i"."_skills"}, $skillsID_lut{$ai_seq_args[$ai_index_skill_use]{'skill_use_id'}})
				)
				&& (
					!$config{"equipAuto_$i"."_stopWhenCasting"}
					|| !$chars[$config{'char'}]{'time_cast'}
					|| timeOut($ai_v{'temp'}{'castWait'}, $chars[$config{'char'}]{'time_cast'})
				)
				&& $config{"equipAuto_$i"."_0"}
			) || (
				!$config{"equipAuto_$i"."_0"} && $checkDefaultWeapon
			)
		) {

			undef @{$ai_v{'temp'}{'equipAuto'}{'sendUneqed'}};
			undef @{$ai_v{'temp'}{'equipAuto'}{'sendEqed'}};
			undef %{$ai_v{'temp'}{'equipAuto'}};

			if (
				$checkDefaultWeapon
				&& (
					!$config{"equipAuto_$i"."_0"}
					|| !$config{"equipAuto_$i"."_monsters"}
				)
			) {
				$prefix = "equipAuto_def";
			} else {
				$prefix = "equipAuto_$i";
			}

			$j = 0;

			while (1) {
				last if (!$config{$prefix."_$j"});
				undef @array; splitUseArray(\@array, $config{$prefix."_$j"}, ",");
				$ai_v{'temp'}{'equipAuto'}{'target'} = $array[0]; $ai_v{'temp'}{'equipAuto'}{'type_equip'} = $array[1];

				if (
					$ai_v{'temp'}{'equipAuto'}{'target'} eq "uneq"
					&& $ai_v{'temp'}{'equipAuto'}{'type_equip'} ne ""
					&& (
						$ai_index_skill_use eq ""
						|| $ai_seq_args[$ai_index_skill_use]{'skill_use_ignorePos'} ne $ai_v{'temp'}{'equipAuto'}{'type_equip'}
					)
				) {
					my $invIndex = findIndexStringNotSelected_lc(\@{$chars[$config{'char'}]{'inventory'}}, \@{$ai_v{'temp'}{'equipAuto'}{'sendUneqed'}}, "equipped", $ai_v{'temp'}{'equipAuto'}{'type_equip'});
					if ($invIndex ne "" && $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} ne "") {
						push @{$ai_v{'temp'}{'equipAuto'}{'sendUneqed'}}, $invIndex;
						sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'});
						print "Auto-unequip: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n" if ($config{'debug'});
						$ai_v{'temp'}{'equipAuto'}{'packet_sent'}++;
					}

				} elsif ($ai_v{'temp'}{'equipAuto'}{'target'} ne "") {
					for ($k = 0; $k < @{$chars[$config{'char'}]{'inventory'}};$k++) {
						next if (
							!%{$chars[$config{'char'}]{'inventory'}[$k]}
							|| $chars[$config{'char'}]{'inventory'}[$k]{'equipped'} ne ""
							|| !$chars[$config{'char'}]{'inventory'}[$k]{'identified'}
							|| $chars[$config{'char'}]{'inventory'}[$k]{'broken'}
							|| binFind(\@{$ai_v{'temp'}{'equipAuto'}{'sendEqed'}}, $k) ne ""
							|| ($chars[$config{'char'}]{'autoSwitch'} ne "" && $chars[$config{'char'}]{'autoSwitch'} == $k)
						);
						if ($chars[$config{'char'}]{'inventory'}[$k]{'name'} eq $ai_v{'temp'}{'equipAuto'}{'target'}) {
							# Check if the same eq already equipped
							if ($ai_v{'temp'}{'equipAuto'}{'type_equip'} == 32 || $ai_v{'temp'}{'equipAuto'}{'type_equip'} == 128) {
								$ai_v{'temp'}{'equipAuto'}{'type_check'} = $ai_v{'temp'}{'equipAuto'}{'type_equip'};
							} elsif ($chars[$config{'char'}]{'inventory'}[$k]{'type_equip'} == 136) {
								$ai_v{'temp'}{'equipAuto'}{'type_check'} = 8;
							} else {
								$ai_v{'temp'}{'equipAuto'}{'type_check'} = $chars[$config{'char'}]{'inventory'}[$k]{'type_equip'};
							}
							last if ($ai_index_skill_use ne "" && $ai_seq_args[$ai_index_skill_use]{'skill_use_ignorePos'} eq $ai_v{'temp'}{'equipAuto'}{'type_check'});
							my $invIndex = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "equipped", $ai_v{'temp'}{'equipAuto'}{'type_check'});
							if (
								$invIndex eq ""
								|| $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ne $ai_v{'temp'}{'equipAuto'}{'target'}
							) {
								push @{$ai_v{'temp'}{'equipAuto'}{'sendEqed'}}, $k;
								if ($ai_v{'temp'}{'equipAuto'}{'type_equip'} == 32 || $ai_v{'temp'}{'equipAuto'}{'type_equip'} == 128) {
									parseInput("eq $k left");
								} else {
									parseInput("eq $k");
								}
								print "Auto-equip: $chars[$config{'char'}]{'inventory'}[$k]{'name'} ($k)\n" if ($config{'debug'});
								$ai_v{'temp'}{'equipAuto'}{'packet_sent'}++;
								$chars[$config{'char'}]{'autoSwitch'} = $k;
							}
							last;
						}
					}
				}
				$j++;
			}
			ai_clientSuspend(0, $timeout{'ai_equip_waitAfterChange'}{'timeout'}) if ($ai_v{'temp'}{'equipAuto'}{'packet_sent'});
			last;
		}
		$i++;
	}
}

sub ai_equip_special {
	my $equip_format = shift;
	my ($invIndex, $eq, $pos);
	my $r_pos;

	undef @array; splitUseArray(\@array, $equip_format, ",");
	$eq = $array[0]; $pos = $array[1];
	$invIndex = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $eq);
	if (
		$invIndex ne ""
		&& $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} eq ""
	) {
		if ($pos == 32 || $pos == 128) {
			parseInput("eq $invIndex left");
			$r_pos = $pos;
		} else {
			parseInput("eq $invIndex");
			$r_pos = ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} == 136) ? 8 : $chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'};
		}

		return $r_pos;
	}
}

sub ai_getSkillUseID {
	$name = shift;
	foreach (keys %skillsID_lut) {
		if ($skillsID_lut{$_} eq $name) {
			return $_;
		}
	}
}

sub handyMove {
	my $dir = shift;
	my $step = shift;
	my ($step_x, $step_y);

	if ($step eq "") {
		$step = ($config{'handyMove_step'}) ? $config{'handyMove_step'} : 1;
	}

	if ($dir eq "東") {
		$step_x = $step;
		$step_y = 0;
	} elsif ($dir eq "西") {
		$step_x = 0 - $step;
		$step_y = 0;
	} elsif ($dir eq "南") {
		$step_x = 0;
		$step_y = 0 - $step;
	} elsif ($dir eq "北") {
		$step_x = 0;
		$step_y = $step;
	} elsif ($dir eq "東北") {
		$step_x = $step;
		$step_y = $step;
	} elsif ($dir eq "西北") {
		$step_x = 0 - $step;
		$step_y = $step;
	} elsif ($dir eq "東南") {
		$step_x = $step;
		$step_y = 0 - $step;
	} elsif ($dir eq "西南") {
		$step_x = 0 - $step;
		$step_y = 0 - $step;
	}

	print "往$dir移動 $step 格, ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})." -> ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'} + $step_x, $chars[$config{'char'}]{'pos_to'}{'y'} + $step_y)."\n";
	$ai_v{'temp'}{'x'} = $chars[$config{'char'}]{'pos_to'}{'x'} + $step_x;
	$ai_v{'temp'}{'y'} = $chars[$config{'char'}]{'pos_to'}{'y'} + $step_y;
	if (abs($step_x) <= 15 && abs($step_y) <= 10) {
		move($ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'});
	} else {
		ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $field{'name'}, 0, 0, 1);
	}
}

1;