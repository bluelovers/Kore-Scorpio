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

#		, 'CR_GRANDCROSS'	#	聖十字審判

	);

	return $val;
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
		undef $ai_seq_args[$index]{'move'};
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
	my $modeEx = shift;
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

	$args{'takenBy'} = $modeEx;

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
	my $x	= shift;
	my $y	= shift;
	my $why	= shift;
	my $ID	= shift;
	my %args;
	$args{'move_to'}{'x'} = $x;
	$args{'move_to'}{'y'} = $y;
	$args{'why'} = $why;
	$args{'ID'} = $ID;
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
	$args{'send'} = 0;
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
#						percent_hp(\%{$chars[$config{'char'}]}) >= $config{"equipAuto_$i"."_hp_lower"}
#						&& percent_hp(\%{$chars[$config{'char'}]}) <= $config{"equipAuto_$i"."_hp_upper"}
#						&& percent_sp(\%{$chars[$config{'char'}]}) >= $config{"equipAuto_$i"."_sp_lower"}
#						&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"equipAuto_$i"."_sp_upper"}

						mathInNum(percent_hp(\%{$chars[$config{'char'}]}), $config{"equipAuto_${i}_hp_upper"}, $config{"equipAuto_${i}_hp_lower"}, 1)
						&& mathInNum(percent_sp(\%{$chars[$config{'char'}]}), $config{"equipAuto_${i}_sp_upper"}, $config{"equipAuto_${i}_sp_lower"}, 1)
					)
				)
				&& (
					!$config{"equipAuto_$i"."_monsters"}
					|| (
						$ai_index_attack ne ""
						&& existsInList($config{"equipAuto_$i"."_monsters"}, $monsters{$ai_seq_args[$ai_index_attack]{'ID'}}{'name'})
					)
				)
				&& (
					!$config{"equipAuto_$i"."_monstersNot"}
					|| (
						$ai_index_attack ne ""
						&& existsInList($config{"equipAuto_$i"."_monstersNot"}, $monsters{$ai_seq_args[$ai_index_attack]{'ID'}}{'name'})
					)
				)
				&& ($config{"equipAuto_${i}_inCity"} || !$ai_v{'temp'}{'inCity'})
				&& (!$config{"equipAuto_${i}_inLockOnly"} || ($config{"equipAuto_${i}_inLockOnly"} && $ai_v{'temp'}{'inLockMap'}))
				&& (!$config{"equipAuto_${i}_unLockOnly"} || ($config{"equipAuto_${i}_unLockOnly"} && !$ai_v{'temp'}{'inLockMap'}))

				&& (
					!$config{"equipAuto_$i"."_skills"}
					|| (
						$ai_index_skill_use ne ""
						&& existsInList($config{"equipAuto_$i"."_skills"}, $skillsID_lut{$ai_seq_args[$ai_index_skill_use]{'skill_use_id'}})
					)
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
				undef @array;
				splitUseArray(\@array, $config{$prefix."_$j"}, ",");
				$ai_v{'temp'}{'equipAuto'}{'target'} = $array[0];
				$ai_v{'temp'}{'equipAuto'}{'type_equip'} = $array[1];

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

								if ($config{"${prefix}_attackDistance"} && $config{"${prefix}_attackDistance"} != $config{'attackDistance'}) {
									$ai_v{'ka'}{'attackDistance'} = $config{'attackDistance'};
									$config{'attackDistance'} = $config{"${prefix}_attackDistance"};
									print "Change Attack Distance to : $config{'attackDistance'}\n";
								}
								if ($config{"${prefix}_useWeapon"} ne "" && $config{"${prefix}_useWeapon"} != $config{'attackUseWeapon'}) {
									$ai_v{'ka'}{'attackUseWeapon'} = $config{'attackUseWeapon'};
									$config{'attackUseWeapon'} = $config{"${prefix}_useWeapon"};
									print "Change Attack useWeapon to : $config{'attackUseWeapon'}\n";
								}
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

	return $ai_v{'temp'}{'equipAuto'}{'packet_sent'} if ($ai_v{'temp'}{'equipAuto'}{'packet_sent'});

	if ($ai_v{'ka'}{'attackDistance'} && $config{'attackDistance'} != $ai_v{'ka'}{'attackDistance'}) {
		$config{'attackDistance'} = $ai_v{'ka'}{'attackDistance'};
		print "Change Attack Distance to Default : $config{'attackDistance'}\n";
	}
	if ($ai_v{'ka'}{'attackUseWeapon'} ne "" && $config{'attackUseWeapon'} != $ai_v{'ka'}{'attackUseWeapon'}) {
		$config{'attackUseWeapon'} = $ai_v{'ka'}{'attackUseWeapon'};
		print "Change Attack useWeapon to default : $config{'attackUseWeapon'}\n";
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