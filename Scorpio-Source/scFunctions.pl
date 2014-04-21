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

sub getPlayerType {
	my $ID = shift;
	my $val = 0;

	if (binFind(\@partyUsersID, $ID) ne "") {
		$val = 1;
	}

	return $val;
}

sub sc_srand {
	srand(time());
}

sub ai_takenBy {
	my $ID = shift;
	my $targetID = shift;

	if ($ID ne "" && $targetID ne "") {
		$monsters{$ID}{'takenBy'} = 1;

		sysLog("ii", "怪物", "重要物品: $items{$targetID}{'name'} ($items{$targetID}{'binID'}) x $items{$targetID}{'amount'} 可能被 $monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) 吃掉了！", 1);

#		for ($ai_index=0; $ai_index<@ai_seq; $ai_index++) {
#			if (
#				$ai_seq[$ai_index] eq "take"
#				&& $ai_seq_args[$ai_index]{'ID'} eq $targetID
#			) {
#				binRemoveAndShiftByIndex(\@ai_seq, $ai_index);
#				binRemoveAndShiftByIndex(\@ai_seq_args, $ai_index);
#				last;
#			}
#		}

		ai_removeByKey("take", "ID", $targetID);

		$ai_index = binFind(\@ai_seq, "attack");
		attackForceStop(\$remote_socket, $ai_seq_args[$ai_index]{'ID'}) if ($ai_index ne "" && $ai_seq_args[$ai_index]{'ID'} ne $ID);
		if (
			$ai_index eq ""
			|| (
#				$monsters{$ID}{'attack_failed'} <= 1
#				&&
				$ai_seq_args[$ai_index]{'ID'} ne $ID
			)
		) {
			attack($ID, 1);
		}
	}
}

sub ai_stopByTele {
	my $tele = shift;

	return 0 if (!$tele);

	my $ai_index = binFind(\@ai_seq, "take");

	if ($ai_index ne "" && $ai_seq_args[$ai_index]{'mode'} > 0) {
		my $targetDisplay;

		if (!%{$items{$ai_seq_args[$ai_index]{'ID'}}}) {
			$targetDisplay = "$items_old{$ai_seq_args[$ai_index]{'ID'}}{'name'} ($items_old{$ai_seq_args[$ai_index]{'ID'}}{'binID'})";
		} else {
			$targetDisplay = "$items{$ai_seq_args[$ai_index]{'ID'}}{'name'} ($items{$ai_seq_args[$ai_index]{'ID'}}{'binID'})";
		}

		sysLog("ii", "順移", "撿取物品失敗: $targetDisplay 原因: 你施展瞬間移動了", 1);
	}
}

sub getRand_sc {
	my $tDefault = shift;
	my $tRandom = shift;
	my $t = (int(rand() * 1)?"":"-").int($tDefault) + int(rand() * $tRandom + 1);
	return $t;
}

sub ai_getNpcTalk_warpedToSave_reset {
	if ($ai_seq_args[0]{'warpedToSave'} && (!$ai_seq_args[0]{'mapChanged'} || $field{'name'} ne $config{'saveMap'})) {
		undef $ai_seq_args[0]{'warpedToSave'};
	}

#	if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'} && $field{'name'} ne $config{'saveMap'}) {
#		undef $ai_seq_args[0]{'warpedToSave'};
#	}
}

sub ai_getNpcTalk_warpedToSave {
	my $ID = shift;

	return (
		$config{'saveMap'} ne ""
		&& $config{'saveMap_warpToBuyOrSell'}
		&& !$ai_seq_args[0]{'warpedToSave'}
		&&  (1 || !$cities_lut{$field{'name'}.'.rsw'})
		&& !$indoors_lut{$field{'name'}.'.rsw'}
		&& $field{'name'} ne $config{'saveMap'}
		&& $field{'name'} ne $npcs_lut{$ID}{'map'}
	)?1:0;
}

sub ai_npc_autoTalk {
	my $key = shift;
	my $ID;
	my $val;

	if ($key eq "storageAuto") {
		$ID = $config{'storageAuto_npc'};

		if (!$ai_seq_args[0]{'npc'}{'sentStorage'}) {

			if ($config{'storagegetAuto_uneqArrow'}){
				for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
					# Equip arrow related
					next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne "0");

					print "[EVENT] 開倉前自動卸下箭矢\n";

					parseInput("uneq 0");

					sleep(0.1);

					last;
				}
			}

			sendTalk(\$remote_socket, pack("L1", $ID));
			@{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $config{'storageAuto_npc_steps'});
			$ai_seq_args[0]{'npc'}{'sentStorage'} = 1;
			timeOutStart('ai_storageAuto');

			$val = 1;

		} elsif (defined(@{$ai_seq_args[0]{'npc'}{'steps'}})) {
			if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
				sendTalkContinue(\$remote_socket, pack("L1", $ID));
			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
#					sendTalkCancel(\$remote_socket, pack("L1", $ID));
			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i) {
				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i;
				if ($ai_v{'temp'}{'arg'} ne "") {
					sendTalkAnswerNum(\$remote_socket, pack("L1", $ID), $ai_v{'temp'}{'arg'});
				}
			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i) {
				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i;
				if ($ai_v{'temp'}{'arg'} ne "") {
					sendTalkAnswerWord(\$remote_socket, pack("L1", $ID), $ai_v{'temp'}{'arg'});
				}
			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i) {
				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
				if ($ai_v{'temp'}{'arg'} ne "") {
					$ai_v{'temp'}{'arg'}++;
					sendTalkResponse(\$remote_socket, pack("L1", $ID), $ai_v{'temp'}{'arg'});
				}
			} else {
				undef @{$ai_seq_args[0]{'npc'}{'steps'}};
			}
			$ai_seq_args[0]{'npc'}{'step'}++;
			timeOutStart('ai_storageAuto');

			$val = 1;

		}
	} elsif ($key eq "sellAuto") {
		$ID = $config{'sellAuto_npc'};

		if ($ai_seq_args[0]{'sentSell'} <= 1) {
			sendTalk(\$remote_socket, pack("L1", $ID)) if !$ai_seq_args[0]{'sentSell'};
			sendGetSellList(\$remote_socket, pack("L1", $ID)) if $ai_seq_args[0]{'sentSell'};
			$ai_seq_args[0]{'sentSell'}++;
			timeOutStart('ai_sellAuto');

			$val = 1;

		}
	} elsif ($key eq "buyAuto") {
		$ID = $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"};

		if ($ai_seq_args[0]{'sentBuy'} <= 1) {
			if (!$ai_seq_args[0]{'sentBuy'} && $config{'buyAuto_smartEquip'} ne "") {
				ai_equip_special($config{'buyAuto_smartEquip'});
				sleep(0.5);
			}
			sendTalk(\$remote_socket, pack("L1", $ID)) if !$ai_seq_args[0]{'sentBuy'};
			sendGetStoreList(\$remote_socket, pack("L1", $ID)) if $ai_seq_args[0]{'sentBuy'};
			$ai_seq_args[0]{'sentBuy'}++;
			timeOutStart('ai_buyAuto_wait');

			$val = 1;
		}
	} elsif ($key eq "talkAuto") {
		$ID = $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'};

		if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
#			undef $ai_v{'temp'}{'pos'};
#			undef $ai_v{'temp'}{'nearest_npc_id'};
#			$ai_v{'temp'}{'nearest_distance'} = 9999;
#
#			%{$ai_v{'temp'}{'pos'}} = %{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}};
#
#			for ($i = 0; $i < @npcsID; $i++) {
#				next if ($npcsID[$i] eq "");
#
#				if (
#					$npcs{$npcsID[$i]}{'pos'}{'x'} == $ai_v{'temp'}{'pos'}{'x'}
#					&& $npcs{$npcsID[$i]}{'pos'}{'x'} == $ai_v{'temp'}{'pos'}{'x'}
#				) {
##								$ai_v{'temp'}{'nearest_npc_id'} = $npcs{$npcsID[$i]}{'nameID'};
#
#					$ai_v{'temp'}{'nearest_npc_id'} = $npcsID[$i];
#
#					last;
#				}
#			}
#
#			if ($ai_v{'temp'}{'nearest_npc_id'} eq "") {
#				for ($i = 0; $i < @npcsID; $i++) {
#					next if ($npcsID[$i] eq "");
#					$ai_v{'temp'}{'distance'} = distance(\%{$npcs{$npcsID[$i]}{'pos'}}, \%{$ai_v{'temp'}{'pos'}});
#					if ($ai_v{'temp'}{'distance'} < $ai_v{'temp'}{'nearest_distance'}) {
#						$ai_v{'temp'}{'nearest_npc_id'} = $npcsID[$i];
#						$ai_v{'temp'}{'nearest_distance'} = $ai_v{'temp'}{'distance'};
#					}
#				}
#			}

			sendTalk(\$remote_socket, pack("L1", $ID));
			@{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_steps'});
			$ai_seq_args[0]{'npc'}{'sentTalk'} = 1;

			$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;

		} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
			sendTalkContinue(\$remote_socket, pack("L1", $ID));
			$ai_seq_args[0]{'npc'}{'step'}++;
		} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
			#sendTalkCancel(\$remote_socket, pack("L1", $ID));
			$ai_seq_args[0]{'npc'}{'step'}++;
		} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i) {
			($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i;
			if ($ai_v{'temp'}{'arg'} ne "") {
				sendTalkAnswerNum(\$remote_socket, pack("L1", $ID), $ai_v{'temp'}{'arg'});
			}
			$ai_seq_args[0]{'npc'}{'step'}++;
		} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i) {
			($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i;
			if ($ai_v{'temp'}{'arg'} ne "") {
				sendTalkAnswerWord(\$remote_socket, pack("L1", $ID), $ai_v{'temp'}{'arg'});
			}
			$ai_seq_args[0]{'npc'}{'step'}++;
		} else {
			($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
			if ($ai_v{'temp'}{'arg'} ne "") {
				$ai_v{'temp'}{'arg'}++;
				sendTalkResponse(\$remote_socket, pack("L1", $ID), $ai_v{'temp'}{'arg'});
			}
			$ai_seq_args[0]{'npc'}{'step'}++;
		}

		if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "") {
			$ai_seq_args[0]{'done'} = 1;
			$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
		}
	}

	return $val;
}

sub ai_getTempVariable {

	my $ai_index = binFind(\@ai_seq, "attack");
	undef $ai_v{'ai_attack_ID'};

	if ($ai_index ne "") {
		$ai_v{'ai_attack_ID'} = $ai_seq_args[$ai_index]{'ID'};
	}

	$ai_v{'temp'}{'inLockMap'}	= (($field{'name'} eq $config{'lockMap'} || $config{'lockMap'} eq "")?1:0);
	$ai_v{'temp'}{'inLockPos'}	= (($ai_v{'temp'}{'inLockMap'} && $config{'lockMap_x'} eq "") || ($chars[$config{'char'}]{'pos_to'}{'x'} == $lockMap{'pos_to'}{'x'} && $chars[$config{'char'}]{'pos_to'}{'y'} == $lockMap{'pos_to'}{'y'}));
	$ai_v{'temp'}{'inDoor'}		= $indoors_lut{$field{'name'}.'.rsw'};
	$ai_v{'temp'}{'inCity'}		= $cities_lut{$field{'name'}.'.rsw'} || $ai_v{'temp'}{'inDoor'};
	$ai_v{'temp'}{'inTake'}		= ((binFind(\@ai_seq, "take") ne "" || binFind(\@ai_seq, "items_take") ne "" || binFind(\@ai_seq, "items_gather") ne "")?1:0);
	$ai_v{'temp'}{'onHit'}		= $sc_v{'ai'}{'onHit'} or ai_getMonstersHitMe();
	$ai_v{'temp'}{'inAttack'}	= ($ai_index ne "")?1:0;
	$ai_v{'temp'}{'getAggressives'}	= ai_getAggressives();
	$ai_v{'temp'}{'getAggressives'}	= $ai_v{'temp'}{'getAggressives'}?$ai_v{'temp'}{'getAggressives'}:$ai_v{'temp'}{'onHit'};
}

sub existsInList_sc {
	my ($list, $val, $type) = @_;
	undef @array;
	@array = split /,/, $list;

	return (($array[0] < 0)?1:0) if ($val eq "");

	foreach (@array) {
		s/^\s+//;
		s/\s+$//;
		s/\s+/ /g;
		next if ($_ eq "");

		if (
			$_ < 0
			&& (
				(abs($_) eq $val)
				|| $type eq "and"
				&& (abs($_) & $val)
			)
		) {
			return 0;
		} elsif ($_ >= 0 && (($_ eq $val) || $type eq "and" && ($_ & $val))) {
			return 1;
		}
	}

	return (($array[0] < 0)?0:1);
}

sub ai_checkToUseSkill {
	my ($key, $i, $mode, $r_hash, $r_hash2) = @_;

#	undef $ai_v{'temp'}{'found'} if ($mode);

	if ($mode) {
		my $val = (
			$config{"${key}_${i}_lvl"} > 0
			&& mathInNum(percent_hp(\%{$chars[$config{'char'}]}), $config{"${key}_${i}_hp_upper"}, $config{"${key}_${i}_hp_lower"}, 1)
			&& mathInNum(percent_sp(\%{$chars[$config{'char'}]}), $config{"${key}_${i}_sp_upper"}, $config{"${key}_${i}_sp_lower"}, 1)
			&& !($config{"${key}_${i}_stopWhenHit"} && $ai_v{'temp'}{'onHit'})
			&& !($config{"${key}_${i}_stopWhenSit"} && $chars[$config{'char'}]{'sitting'})
			&& !($config{"${key}_${i}_stopWhenTake"} && $ai_v{'temp'}{'inTake'})
			&& !($config{"${key}_${i}_stopWhenAttack"} && $ai_v{'temp'}{'inAttack'})

			&& $config{"${key}_${i}_minAggressives"} <= $ai_v{'temp'}{'getAggressives'}
			&& (!$config{"${key}_${i}_maxAggressives"} || $config{"${key}_${i}_maxAggressives"} >= $ai_v{'temp'}{'getAggressives'})

			&& (!$config{"${key}_${i}_waitAfterKill"} || timeOut(\%{$timeout{'ai_skill_use_waitAfterKill'}}))
			&& (
				isMonk($chars[$config{'char'}]{'jobID'})
				|| (
					$chars[$config{'char'}]{'spirits'} <= $config{"${key}_${i}_spirits_upper"}
					&& $chars[$config{'char'}]{'spirits'} >= $config{"${key}_${i}_spirits_lower"}
				)
			)

			&& timeOut($config{"${key}_${i}_timeout"}, $r_hash)

			&& ($config{"${key}_${i}_inCity"} || !$ai_v{'temp'}{'inCity'})
			&& (!$config{"${key}_${i}_inLockOnly"} || (($config{"${key}_${i}_inLockOnly"} ne "2" && $config{"${key}_${i}_inLockOnly"} && $ai_v{'temp'}{'inLockMap'}) || ($config{"${key}_${i}_inLockOnly"} eq "2" && $config{"${key}_${i}_inLockOnly"} && $ai_v{'temp'}{'inLockPos'})))
			&& (!$config{"${key}_${i}_unLockOnly"} || ($config{"${key}_${i}_unLockOnly"} && !$ai_v{'temp'}{'inLockMap'}))
		)?1:0;

#		print "${key}_${i} : $val\n" if ($key eq "useParty_skill");

		return $val;
	} else {
#		my $t_hash;
#
#		if (!%{$$r_hash2}) {
#			%{$t_hash} = %{$$r_hash};
#		} else {
#			%{$t_hash} = %{$$r_hash2};
#		}

		if (
			!$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"${key}_${i}"})}}{'lv'}
			&& (
				$config{"${key}_${i}_smartEquip"} eq ""
				|| ($config{"${key}_${i}_smartEquip"} ne "" && findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"${key}_${i}_smartEquip"}) eq "")
			)
		) {
			$ai_v{'temp'}{'found'} = 1;
			scModify("config", "${key}_${i}_lvl", 0, 1) if ($config{"useSkill_smartCheck"});
		}

		if (
			!$ai_v{'temp'}{'found'}
			&& (
				$config{"${key}_${i}_param1"} && !existsInList2($config{"${key}_${i}_param1"}, $$r_hash2{'param1'}, "noand")
				|| $config{"${key}_${i}_param2"} && !existsInList2($config{"${key}_${i}_param2"}, $$r_hash2{'param2'}, "and")
				|| $config{"${key}_${i}_param3"} && !existsInList2($config{"${key}_${i}_param3"}, $$r_hash2{'param3'}, "and")
			)
		) {
			$ai_v{'temp'}{'found'} = 1;
		}

		if (!$ai_v{'temp'}{'found'} && $config{"${key}_${i}_status"} ne "") {
			foreach (@{$$r_hash{'status'}}) {
#				if (existsInList2($config{"${key}_${i}_status"}, $_, "noand")) {
#					$ai_v{'temp'}{'found'} = 1;
#					last;
#				}
				if (existsInList2($config{"${key}_${i}_status"}, $_, "noand")) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
		}

		if (!$ai_v{'temp'}{'found'} && $config{"${key}_${i}_checkItem"}) {
			undef @array;
			splitUseArray(\@array, $config{"${key}_${i}_checkItem"}, ",");
			foreach (@array) {
				next if (!$_);
				if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) eq "") {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
		}

		if (!$ai_v{'temp'}{'found'} && $config{"${key}_${i}_checkItemEx"}) {
			undef @array;
			undef $ai_v{'temp'}{'foundEx'};
			splitUseArray(\@array, $config{"${key}_${i}_checkItemEx"}, ",");
			foreach (@array) {
				next if (!$_);

				if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) ne "") {
					$ai_v{'temp'}{'foundEx'} = 1;
					last;
				}
			}
			$ai_v{'temp'}{'found'} = 1 if (!$ai_v{'temp'}{'foundEx'});
		}

		# Judge equipped type
		if (!$ai_v{'temp'}{'found'} && $config{"${key}_${i}_checkEquipped"} ne "") {
			undef $ai_v{'temp'}{'invIndex'};
			$ai_v{'temp'}{'invIndex'} = findIndexStringWithList_KeyNotNull_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"${key}_${i}_checkEquipped"}, "equipped");
			$ai_v{'temp'}{'found'} = 1 if ($ai_v{'temp'}{'invIndex'} eq "");
		}

		if (!$ai_v{'temp'}{'found'} && $config{"${key}_${i}_spells"} ne "") {
			foreach (@spellsID) {
				next if ($_ eq "" || $spells{$_}{'type'} eq "");

				undef $s_cDist;

				$s_cDist = distance(\%{$r_hash2{'pos_to'}}, \%{$spells{$_}{'pos'}});

				if (
					existsInList($config{"${key}_${i}_spells"}, $spells{$_}{'type'})
					&& (!$config{"${key}_${i}_spells_dist"} || $config{"${key}_${i}_spells_dist"} <= $s_cDist)
				) {
					$ai_v{'temp'}{'found'} = 1;

					last;
				}
			}
		}

#		if (
#			!$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"${key}_${i}"})}}{'lv'}
#			&& (
#				$config{"${key}_${i}_smartEquip"} eq ""
#				|| ($config{"${key}_${i}_smartEquip"} ne "" && findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"${key}_${i}_smartEquip"}) eq "")
#			)
#		) {
#			$ai_v{'temp'}{'found'} = 1;
#			scModify("config", "${key}_${i}_lvl", 0, 1) if ($config{"useSkill_smartCheck"});
#		}

		return $ai_v{'temp'}{'found'};
	}
}

sub ai_getAggressivesEx {
	my $mode = shift;
	my @agMonsters;

	if ($mode) {
		foreach (@monstersID) {
			next if (
				$_ eq ""
			);

			if (
				$_ ne ""
				&& $monsters{$_}{'dmgFromYou'} > 0
				&& $monsters{$_}{'0080'} eq ""
			) {
				push @agMonsters, $_;
			}
		}
	} else {

		foreach (@monstersID) {
			next if (
				$_ eq ""
#				|| $monsters_old{$_}{'disappeared'}
#				|| $monsters_old{$_}{'dead'}
#				|| $monsters_old{$_}{'0080'} ne ""
#	#			|| $monsters{$_}{'disappeared'}
#	#			|| $monsters{$_}{'dead'}
#	#			|| $monsters{$_}{'0080'} ne ""
#	#			|| $monsters{$_}{'attack_failed'} > 1
			);

			if (
				$monsters{$_}{'dmgToYou'} > 0
				|| (
					$monsters{$_}{'missedYou'} > 0
					&& !$config{'teleportAuto_skipMiss'}
				)
			) {
				push @agMonsters, $_;
			}
		}
	}

	return @agMonsters;
}

sub ai_checkZeny {
	my $num = shift;

	return ((!$num || ($chars[$config{'char'}]{'zenny'} >= $num))?1:0);
}

sub getBrokenItems {
	my $ref_item	= shift;
	my ($num, $i) = (0, 0);

	for ($i=0; $i<@{$ref_item}; $i++) {
		$num++ if ($$ref_item[$i]{'broken'});
	}

	return $num;
}

sub isEquipment {
	my $type = shift;

	if ($type <= 3 || $type == 6 || $type == 10){
		return 0;
	} else {
		return 1;
	}
}

sub getItemList {
	my $ref_item	= shift;
	my $switch	= shift;
	my $c_top	= shift;
	my $c_bottom	= shift;
	my $mode	= shift;

	my (@useable, @equipment, @non_useable, @card, @arrow);
	my ($i, $idx);
	my $tag = "---";
	my $tagidx = "@>>";
	my $display;
	my $tmp;
#	my $tmp = "@>> @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< x @>>>>  ";

	for ($i=0; $i<@{$ref_item}; $i++){
		next if (
			!%{$$ref_item[$i]}
			|| $$ref_item[$i]{'equipped'} ne ""
			|| $$ref_item[$i]{'borned'}
		);
		my $type = $$ref_item[$i]{'type'};

		if ($type <= 2){
			push @useable, $i;
		} elsif ($type == 3) {
			push @non_useable, $i;
		} elsif ($type == 6) {
			push @card, $i
		} elsif ($type == 10) {
			push @arrow, $i
		} else {
			push @equipment, $i;
		}
	}

	return (@useable, @non_useable, @card, @equipment, @arrow) if ($mode > 1);

	print subStrLine(0, $c_top, 3) if ($c_top);

	$switch = "" if (switchInput($switch, "", "all"));

	print swrite2($tagidx,[" No"])." Name\n";

	if (switchInput($switch, , "", "eq") && @equipment){
		print "$tag Equipment\n";

		for ($i = 0; $i < @equipment; $i++) {
			$idx = $equipment[$i];
			$display = fixingName(\%{$$ref_item[$idx]});

#			print sprintf("%-4d",$idx).$display."\n";
			print swrite2($tagidx,[$idx])." $display\n";
		}

	}
	if (switchInput($switch, "", "nu") && @non_useable){
		print	"$tag Non-Useable\n";

		for ($i = 0; $i < @non_useable; $i++) {
			$idx = $non_useable[$i];

			$display = "$$ref_item[$idx]{'name'} x $$ref_item[$idx]{'amount'}";

			if ($mode) {
				$tmp = $sc_v{'sell'}{$$ref_item[$idx]{'nameID'}}{'price'};
				$display .= " * $tmp => ".($$ref_item[$idx]{'amount'} * $tmp) if ($tmp);
			}

#			print sprintf("%-4d",$idx).$display."\n";
			print swrite2($tagidx,[$idx])." $display\n";
		}

	}
	if (switchInput($switch, "", "nu", "card") && @card){
		print	"$tag Card\n";

		for ($i = 0; $i < @card; $i++) {
			$idx = $card[$i];
			$display = "$$ref_item[$idx]{'name'} x $$ref_item[$idx]{'amount'}";

#			print sprintf("%-4d",$idx).$display."\n";
			print swrite2($tagidx,[$idx])." $display\n";
		}
	}
	if (switchInput($switch, "", "nu", "arrow") && @arrow){
		print	"$tag Arrow\n";

		for ($i = 0; $i < @arrow; $i++) {
			$idx = $arrow[$i];
			$display = "$$ref_item[$idx]{'name'} x $$ref_item[$idx]{'amount'}";

#			print sprintf("%-4d",$idx).$display."\n";
			print swrite2($tagidx,[$idx])." $display\n";
		}

	}

	if (switchInput($switch, "", "u") && @useable){
		print "$tag Useable\n";

		for ($i = 0; $i < @useable; $i++) {
			$idx = $useable[$i];
			$display = fixingName(\%{$$ref_item[$idx]});
			$display .= " x $$ref_item[$idx]{'amount'}";

			if ($mode) {
				$tmp = $sc_v{'sell'}{$$ref_item[$idx]{'nameID'}}{'price'};
				$display .= " * $tmp => ".($$ref_item[$idx]{'amount'} * $tmp) if ($tmp);
			}

#			print sprintf("%-4d",$idx).$display."\n";
			print swrite2($tagidx,[$idx])." $display\n";
		}

	}

	print "\n${c_bottom}\n" if ($c_bottom);
	print subStrLine() if ($c_top);

	undef @useable, @equipment, @non_useable, @card, @arrow;
}

sub swrite2 {
	my $result = '';
	for (my $i = 0; $i < @_; $i += 2) {
		my $format = $_[$i];
		my @args = @{$_[$i+1]};
		if ($format =~ /@[<|>]/) {
			$^A = '';
			formline($format, @args);
			$result .= "$^A";
		} else {
			$result .= "$format";
		}
	}
	$^A = '';
	return $result;
}

sub fixingName {
	my $r_hash = shift;
	my $type = shift;
	my $display = "";

	if ($$r_hash{'maker_charID'} && $charID_lut{$$r_hash{'maker_charID'}}) {
		$display .= " -- 由 $charID_lut{$$r_hash{'maker_charID'}} 製作";
	}
	if (!$$r_hash{'identified'}) {
#		$display .= " -- 未鑑定";
		$display .= " -- Not Identified";
	}
	if ($$r_hash{'named'}) {
		$display .= " -- 已命名";
	}
	if ($$r_hash{'broken'}) {
		$display .= " -- 已損壞";
	}

	$display = $$r_hash{'name'}.$display if (!$type);

	return $display;
}

sub subStrLine {
	my ($text, $msg, $idx, $c, $t) = @_;
	my $len = length($msg);

	$c = " " if (!$c);
	$t = "-" if (!$t);

	if (!$text || $text eq "max"){
		$text = "-" x (80 - 1);
	} else {
		$text = $t x length($text);
	}

	$idx = (length($text)-$len)/2 if ($idx == -1);
	$idx = length($text)-$len-1 if ($idx == -2);
	$idx = 13 if (!$idx || $idx eq "def" || $idx < 0);

	substr($text, $idx, $len + length($c)*2) = $c.$msg.$c if ($len);

	return $text ."\n";
}

sub getMsgStrings {
	my $switch	= shift;
	my $ID		= shift;
	my $idx		= shift;
	my $mode	= shift;

	my $val = $messages_lut{$switch}{$ID};

	if ($idx && $val){
		my @messages = split(/::/, $val);
		$val = $messages[1];
	}

	if (!$val && $mode >= 0) {
		undef $val;

		if (!$mode) {
			$val = "Affected "
		} elsif ($mode > 1) {
			$val = "[$switch] ";
		}

		$val .= "Unknown $ID" ;

	}

	return $val;
}

sub checkTimeOut {
	my $name = shift;
	my $lock = shift;

#	if (
#		!exists($timeout{"$name"})
#		|| $timeout{"$name"}{'lock'} == 1
#		|| !$timeout{"$name"}{'time'}
#		|| !$timeout{"$name"}{'timeout'}
#	) {
#		return 0;
#	}

	if (
		!exists($timeout{"$name"})
		|| $timeout{"$name"}{'lock'} == 1
		|| !$timeout{"$name"}{'timeout'}
	) {
		return 0;
	} elsif ($lock) {
		setTimeOutLock($name, 1)
	}

	return timeOut(\%{$timeout{$name}});
}

sub setTimeOutLock {
	my $name = shift;
	my $idx = shift;

	if ($idx > 1){
		undef $timeout{"$name"};
	} elsif ($idx) {
		$timeout{"$name"}{'lock'} = 1;
	} else {
		undef $timeout{"$name"}{'lock'};
	}
}

sub setTimeOut {
	my $name = shift;

	return 0 if (!$name);

	setTimeOutLock($name);
	return $timeout{"$name"}{'time'} = time;
}

sub timeOutStart {
	my @name	= @_;
	my ($mode, $mode2)	= (0, 0);

#	print "timeOutStart $name[0] - $name[$i]\n";

	if ($name[0] eq "1"){
		$mode = 1;
		shift @name;
	} elsif ($name[0] < 0){
		$mode2 = 1;
		shift @name;
	} elsif ($name[0] eq "0"){
		shift @name;
	}

	for (my $i = 0; $i < @name; $i++){
		next if (!exists($timeout{$name[$i]}));

		$timeout{$name[$i]}{'lock'}	= $mode;
		$timeout{$name[$i]}{'time'}	= time;
		$timeout{$name[$i]}{'time'} -= $timeout{$name[$i]}{'timeout'} if ($mode2);
	}
}

sub getAttrColor {
	my ($mode, $r_color) = @_;
	my $OriginalColor = $CONSOLE->Attr();

	my $val;

	my @colors = (
		'BLACK'
		, 'BLUE'
		, 'LIGHTBLUE'
		, 'RED'
		, 'LIGHTRED'
		, 'GREEN'
		, 'LIGHTGREEN'
		, 'MAGENTA'
		, 'LIGHTMAGENTA'
		, 'CYAN'
		, 'LIGHTCYAN'
		, 'BROWN'
		, 'YELLOW'
		, 'GRAY'
		, 'WHITE'
	);

	my $cm = ($mode?'BG':'FG');

#	print " [ OriginalColor = $OriginalColor ]\n";

	foreach (reverse @colors) {
		last if (($OriginalColor == ${"${cm}_$_"}) || !($OriginalColor | ${"${cm}_$_"}))
#		if (($OriginalColor == ${"${cm}_$_"}) || !($OriginalColor | ${"${cm}_$_"})) {
#			print " [ ${cm}_$_ = ".${"${cm}_$_"}." ]\n";

#			$cm = ($mode?'FG':'BG') if ($r_color);
#			return ${"${cm}_$_"};
#		}
#		print " [ ${cm}_$_ = ".${"${cm}_$_"}." ]\n";

#			$cm = ($mode?'FG':'BG') if ($r_color);

#			return ${"${cm}_$_"};
#		}
	}

	$cm = ($mode?'FG':'BG') if ($r_color);

	$val = ${"${cm}_$_"};

	$val = 0 if ($val eq "");

#	print "return $val\n";

	return $val;
}

sub setColor {
	my $color = shift;

	$CONSOLE->Attr($color);
}

sub printColor {
	my $color = shift;
	my @msg = @_;

	my $OriginalColor = $CONSOLE->Attr();

	setColor($color);

	print @msg;

	setColor($OriginalColor);
}

sub printC {
	my $message	= shift;
	my $channel	= shift;
	my $xmode	= shift;
	my $color;

	if (switchInput($channel, "c1", "exp", "c", "WHITE", "version")) {
		$color = ($FG_WHITE);
	} elsif (switchInput($channel, "c2", "LIGHTGREEN")) {
		$color = ($FG_LIGHTGREEN);
	} elsif (switchInput($channel, "cr_in", "GREEN")) {
		$color = ($FG_GREEN);
	} elsif (switchInput($channel, "cr_out", "MAGENTA")) {
		$color = ($FG_MAGENTA);
	} elsif (switchInput($channel, "e", "CYAN")) {
		$color = ($FG_CYAN);
	} elsif (switchInput($channel, "g", "gm", "warp", "LIGHTCYAN", "sh", "0188", "make")) {
		$color = ($FG_LIGHTCYAN);
	} elsif (switchInput($channel, "p", "LIGHTBLUE")) {
		$color = ($FG_LIGHTBLUE);
	} elsif (switchInput($channel, "pm", "s", "event", "YELLOW", "update", "mvp", "kore")) {
		$color = ($FG_YELLOW);
	} elsif (switchInput($channel, "alert", "LIGHTRED", "error")) {
		$color = ($FG_LIGHTRED);
	} elsif (switchInput($channel, "status", "tele", "LIGHTMAGENTA")) {
		$color = ($FG_LIGHTMAGENTA);
	} elsif (isNum($channel)) {
		$color = $channel;
	}

	printColor($color, "$message");
	setColor($sc_v{'Console'}{'original'});
}

sub parseSkill {
	my $switch = shift;

	my $skillID = shift;
	my $sourceID = shift;
	my $targetID = shift;

	my $exception = shift;
	my $wait = shift;
	my @coords = @_;

#	($coords{'x'}, $coords{'y'}) = @_;

	my $attackID;

	$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

	my $ai_index = binFind(\@ai_seq, "attack");
	if ($ai_index ne "") {
		$attackID = $ai_seq_args[$ai_index]{'ID'};
	}

	if (%{$spells{$sourceID}}) {
		$sourceID = $spells{$sourceID}{'sourceID'};
	}

#	if ($coords{'x'} != 0 || $coords{'y'} != 0) {
#		$targetID = "floor";
#		$targetDisplay = "座標: ".getFormattedCoords($coords{'x'}, $coords{'y'});
#	}

	my ($sourceDisplay, $castBy) = ai_getCaseID($sourceID);
	my ($targetDisplay, $castOn, $dist) = ai_getCaseID($targetID, $sourceID, @coords);

#	if ($targetID eq "floor" || $coords{'x'} != 0 || $coords{'y'} != 0) {
#		$targetID = "floor";
#		$targetDisplay = "座標: ".getFormattedCoords($coords{'x'}, $coords{'y'});
#	}

	parseSteal($sourceID, $targetID, $skillID);

	my $skillName = getName("skillsID_lut", $skillID);
	my ($display, $display_ex, $printC, $show, $miss);

	if (switchInput($switch, "0114", "01DE", "0115")) {

		if (switchInput($switch, "0115")) {

			my %coords = (
				x => $coords[0],
				y => $coords[1]
			);

			if ($castOn == 2) {
				if ($castBy == 1) {
					$monsters{$targetID}{'castOnByYou'}++;
				} elsif ($castBy == 2) {
					$monsters{$targetID}{'castOnByMonster'}{$sourceID}++;
				} elsif ($castBy == 4) {
					$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;

					if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$sourceID}}) {
						$monsters{$targetID}{'castOnByParty'}++;
					}
				}
			}

			if ($castBy == 2) {
				if ($castOn == 1) {
					$monsters{$sourceID}{'castOnToYou'}++;
				} elsif ($castOn == 2) {
					$monsters{$sourceID}{'castOnToMonster'}{$targetID}++;
				} elsif ($castOn == 4) {
					$monsters{$sourceID}{'castOnToPlayer'}{$targetID}++;

					if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$targetID}}) {
						$monsters{$sourceID}{'castOnToParty'}++;
					}
				}
			}

			if ($castOn == 2) {
#				if ($castBy == 1) {
#					$monsters{$targetID}{'castOnByYou'}++;
#				} elsif ($castBy == 2) {
#					$monsters{$targetID}{'castOnByMonster'}{$sourceID}++;
#				} elsif ($castBy == 4) {
#					$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
#
#					if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$sourceID}}) {
#						$monsters{$targetID}{'castOnByParty'}++;
#					}
#				}

				$display_ex = posToCoordinate(\%{$monsters{$targetID}{'pos'}}, 1);

				%{$monsters{$targetID}{'pos'}} = %coords;
				%{$monsters{$targetID}{'pos_to'}} = %coords;
			} elsif ($castOn == 4) {
				%{$players{$targetID}{'pos'}} = %coords;
				%{$players{$targetID}{'pos_to'}} = %coords;

				$display_ex = posToCoordinate(\%{$players{$targetID}{'pos_to'}}, 1);
			} elsif ($castOn == 1) {
				%{$chars[$config{'char'}]{'pos'}} = %coords;
				%{$chars[$config{'char'}]{'pos_to'}} = %coords;

				$display_ex = posToCoordinate(\%{$chars[$config{'char'}]{'pos'}}, 1);
			}

			$display_ex = " $display_ex → ".posToCoordinate(\%coords, 1) if ($display_ex);

			if ($castBy == 1) {
				$chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
				undef $chars[$config{'char'}]{'time_cast'};
				undef $ai_v{'temp'}{'castWait'};
			}

			$miss = ($exception == 0x8AD0) ? 1 : 0;

			$show = 1;
			$printC = "s";

		} else {

			if ($castOn == 2) {
				if ($castBy == 1) {
					$monsters{$targetID}{'castOnByYou'}++;
				} elsif ($castBy == 2) {
					$monsters{$targetID}{'castOnByMonster'}{$sourceID}++;
				} elsif ($castBy == 4) {
					$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;

					if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$sourceID}}) {
						$monsters{$targetID}{'castOnByParty'}++;
					}
				}
			}

			if ($castBy == 2) {
				if ($castOn == 1) {
					$monsters{$sourceID}{'castOnToYou'}++;
				} elsif ($castOn == 2) {
					$monsters{$sourceID}{'castOnToMonster'}{$targetID}++;
				} elsif ($castOn == 4) {
					$monsters{$sourceID}{'castOnToPlayer'}{$targetID}++;

					if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$targetID}}) {
						$monsters{$sourceID}{'castOnToParty'}++;
					}
				}
			}

#			if ($castOn == 2) {
#				if ($castBy == 1) {
#					$monsters{$targetID}{'castOnByYou'}++;
#				} else {
#					$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
#				}
#			}
			if ($castBy == 1) {
				$chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
				undef $chars[$config{'char'}]{'time_cast'};
				undef $ai_v{'temp'}{'castWait'};
			}

			$miss = ($exception == -30000) ? 1 : 0;

		}
		$wait = ($wait == 65535) ? "" : "(Lv $wait) ";

		updateDamageTables($sourceID, $targetID, $exception) if (!$miss);

		if (!$miss) {
			if (!$wait && $sc_v{'parseMsg'}{'level_real'} ne "") {
				$wait = $sc_v{'parseMsg'}{'level_real'};
				undef $sc_v{'parseMsg'}{'level_real'};
			}
			$display = "★$sourceDisplay的 $skillName $wait對$targetDisplay造成傷害: ".($exception ? $exception : "Miss!");

			if ($targetID eq $accountID) {
				undef $showHP{'hp_now'};
				undef $showHP{'hppercent_now'};
				$showHP{'hp_now'} = int($chars[$config{'char'}]{'hp'} - $exception);
				if ($chars[$config{'char'}]{'hp_max'}) {
					$showHP{'hppercent_now'} = $showHP{'hp_now'} / $chars[$config{'char'}]{'hp_max'} * 100;
					$showHP{'hppercent_now'} = ($showHP{'hppercent_now'} > 1) ? int($showHP{'hppercent_now'}) : 1;
					if ($showHP{'hp_now'} <= 0) {
						$showHP{'hppercent_now'} = 0;
						$showHP{'killedBy'}{'who'} = $sourceDisplay;
						$showHP{'killedBy'}{'how'} = "$skillName $wait";
						$showHP{'killedBy'}{'dmg'} = $exception;
					}
				}

				$display .= "★($showHP{'hppercent_now'}%)";

				$printC = "alert" if ($exception != 0);
			} else {
#				if ($sourceID eq $accountID && %{$monsters{$targetID}}) {
#
#					$display .= (!$config{'hideMsg_attackDmgFromYou'} || $config{'debug'}) ? " (Total: $monsters{$targetID}{'dmgFromYou'})" : "";
#				}
				if (!$config{'hideMsg_attackDmgFromYou'} || $config{'debug'}) {
					$display .= getTotal($sourceID, $targetID);
				}
			}


		} else {
			$sc_v{'parseMsg'}{'level_real'} = $wait;
			$display = "★$sourceDisplay施展 $skillName $wait";
		}
	} elsif (switchInput($switch, "013E")) {
		if ($castBy == 1) {
			$chars[$config{'char'}]{'time_cast'} = time;
			$ai_v{'temp'}{'castWait'} = $wait;
		}
		$exception = getName("attribute_lut", $exception);

		$display = "★$sourceDisplay施展 $skillName [$exception] → $targetDisplay, $wait秒後詠唱完成";
	} elsif (switchInput($switch, "01B9")) {
		if ($castBy == 1) {
			aiRemove("skill_use");
			undef $chars[$config{'char'}]{'time_cast'};
			undef $ai_v{'temp'}{'castWait'};
		}
		$display = "★$sourceDisplay施展的技能已被中斷";

	} elsif (switchInput($switch, "0117")) {
		if ($castBy == 1) {
			$chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'time_cast'};
			undef $ai_v{'temp'}{'castWait'};

			if (
				$ai_seq[0] eq "skill_use"
				&& $ai_seq_args[0]{'skill_use_id'} eq $skillID
			) {
				$ai_seq_args[0]{'skill_success'} = 1;
			}
		}
		$wait = ($wait == 65535) ? "" : "(Lv $wait) ";
#		$display = "★$sourceDisplay施展 $skillName $wait → $targetDisplay Ex: $exception";
		$display = "★$sourceDisplay施展 $skillName $wait → $targetDisplay";
	} elsif (switchInput($switch, "011A")) {
		if ($castOn == 2) {
			if ($castBy == 1) {
				$monsters{$targetID}{'castOnByYou'}++;
			} else {
				$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
			}
		}
		if ($castBy == 1) {
			$chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
			undef $chars[$config{'char'}]{'time_cast'};
			undef $ai_v{'temp'}{'castWait'};
		}
		if (switchInput($skillID, 28, 334, 231)) {
			$wait = " - 回復 $exception HP";
		} elsif ($skillID == 335) {
			$wait = " - 回復 $exception SP";
		} else {
			$wait = ($exception == 65535) ? "" : " (Lv $exception)";
		}
		$display = "★$sourceDisplay對$targetDisplay施展 $skillName$wait";
	} else {
		$show = 1;
		$printC = "s";
	}

	return if (!$display);

	if (
		$castBy == 1 || $castOn == 1
		|| ($castBy == 2 && $sourceID eq $attackID)
		|| ($castOn == 2 && $targetID eq $attackID)
		|| !$config{'hideMsg_skill'}
		|| !(
			$config{'hideMsg_skill'} eq "all"
			|| (
				existsInList2($config{'hideMsg_skill_castBy'}, $castBy, "and")
				&& existsInList2($config{'hideMsg_skill_castOn'}, $castOn, "and")
			)
		)
		|| $config{'debug'}
		|| $show
	) {
		printC("${display}${display_ex}\n", $printC);
	}

	if (switchInput($switch, "013E", "0117") && !$sc_v{'temp'}{'itemsImportantAutoMode'}) {
		my $i = 0;
#		my inCity = $cities_lut{$field{'name'}.'.rsw'};
		my $inCity = getMapName($field{'name'}, 0, 1);

		while (1) {
#			last if (!$config{"teleportAuto_skill_$i"} || $ai_v{'temp'}{'teleOnEvent'});
			last if (!$config{"teleportAuto_skill_$i"} || $sc_v{'temp'}{'teleOnEvent'});
			if (
#				existsInList($config{"teleportAuto_skill_$i"}, $skillID)
				existsInList($config{"teleportAuto_skill_$i"}, $skillName)
				&& existsInList2($config{"teleportAuto_skill_$i"."_castBy"}, $castBy, "and")
				&& existsInList2($config{"teleportAuto_skill_$i"."_castOn"}, $castOn, "and")
				&& (
					!$config{"teleportAuto_skill_$i"."_dist"}
					|| $dist < $config{"teleportAuto_skill_$i"."_dist"}
				)
				&& (
					$config{"teleportAuto_skill_$i"."_inCity"}
					|| !$inCity
				)
			) {
				if ($config{"teleportAuto_skill_$i"."_randomWalk"} ne "") {
					undef @array;
					splitUseArray(\@array, $config{"teleportAuto_skill_$i"."_randomWalk"}, ",");
					do {
						$ai_v{'temp'}{'randX'} = $chars[$config{'char'}]{'pos_to'}{'x'} + int(rand() * ($array[1] * 2 + 1)) - $array[1];
						$ai_v{'temp'}{'randY'} = $chars[$config{'char'}]{'pos_to'}{'y'} + int(rand() * ($array[1] * 2 + 1)) - $array[1];
					} while (ai_route_getOffset(\%field, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
								|| $ai_v{'temp'}{'randX'} == $chars[$config{'char'}]{'pos_to'}{'x'} && $ai_v{'temp'}{'randY'} == $chars[$config{'char'}]{'pos_to'}{'y'}
								|| $ai_v{'temp'}{'randX'} == $coords{'x'} && $ai_v{'temp'}{'randY'} == $coords{'y'}
								|| abs($ai_v{'temp'}{'randX'} - $chars[$config{'char'}]{'pos_to'}{'x'}) < $array[0] && abs($ai_v{'temp'}{'randY'} - $chars[$config{'char'}]{'pos_to'}{'y'}) < $array[0]);

					move($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'});

					printC(
						"◆發現技能: $sourceDisplay對$targetDisplay施展 ${skillName}！\n"
						."◆啟動 teleportAuto_skill - 隨機移動！\n"
						, "tele"
					);
					sysLog("tele", "迴避", "發現技能: $sourceDisplay對$targetDisplay施展 ${skillName}, 隨機移動！");

					last;
				} else {

					$ai_v{'temp'}{'teleOnEvent'} = 1;
					timeOutStart('ai_teleport_event');
					$sc_v{'temp'}{'teleOnEvent'} = useTeleport(1);
					$ai_v{'clear_aiQueue'} = 1;

					printC(
						"◆發現技能: $sourceDisplay對$targetDisplay施展 ${skillName}！\n"
						."◆啟動 teleportAuto_skill - 瞬間移動！\n"
						, "tele"
					);
					sysLog("tele", "迴避", "發現技能: $sourceDisplay對$targetDisplay施展 ${skillName}, 瞬間移動！");

					last;
				}
			}
			$i++;
		}
	}
}

sub getName {
	my $switch	= shift;
	my $ID		= shift;
	my $hide	= shift;
	my $mode	= shift;
	my $val;

	if (switchInput($switch, "job", "jobs", "jobs_lut")) {
		$val = $jobs_lut{$ID};
	} elsif (switchInput($switch, "skill", "skills", "skillsID_lut")) {
		$val = $skillsID_lut{$ID};
	} elsif (switchInput($switch, "skills_lut", "skills_nameID")) {
		$val = $skills_lut{$ID};
	} elsif (switchInput($switch, "mon", "monsters", "monsters_lut")) {
		$val = $monsters_lut{$ID};
	} elsif (switchInput($switch, "item", "items", "items_lut")) {
		$val = $items_lut{$ID};
	} elsif (switchInput($switch, "auto")) {
		if (%{$monsters{$ID}}) {
			$val = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) ";
		} elsif (%{$players{$ID}}) {
			$val = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) ";
		} elsif ($sourceID eq $accountID) {
			$val = "你";
		}
	} elsif (switchInput($switch, "attr", "attribute_lut")) {
		$val = $attribute_lut{$ID};
	} elsif (switchInput($switch, "npcs_lut")) {
		$val = $npcs_lut{$ID}{'name'};
	} elsif (switchInput($switch, "player")) {
		$val = (($charID_lut{$ID} ne "") ? $charID_lut{$ID} : $players{$ID}{'name'});
	}

	if (!$val && !$hide) {
		if (!$mode) {
			$val = "Unknown $ID";
		} elsif ($mode < 0) {
			$ID = unpack("L1", $ID);
			$val = "Unknown $ID";
		} else {
			$val = "$ID";
		}
	}

	return $val;
}

sub addCharName {
	my ($ID, $name, $online, $mode) = @_;
	my $CID = $ID;

	$CID = unpack("L1", $ID) if (!$mode);

	$sc_v{'charID'}{$CID}{'ID'}	= $ID;
	$sc_v{'charID'}{$CID}{'CID'}	= $CID;
	$sc_v{'charID'}{$CID}{'name'}	= $name;
	$sc_v{'charID'}{$CID}{'online'}	= $online;
}

sub isLevelMax {
	my $type	= shift;
	my $lv		= shift;
	my $lv_exp	= shift;
	my $val;

	if (!$type){
		$val = 1 if ($lv >= 99);
	} else {
		if ($lv == 50 && $lv_exp == 999999999) {
			$val = 1;
		} elsif ($lv = 70 && $lv_exp == 999999999) {
			$val = 1;
		} elsif ($lv == 10 && $lv_exp == 999999999) {
			$val = 1;
		}
	}
	return ($val);
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

sub Trim {
	my $s = shift;

	$s =~ s/\s+$//g;
	$s =~ s/^\s+//g;

	return $s;
}


sub switchInput {
	my @array = @_;
	my $switch = lc $array[0];
	my $i = 0;

	return 0 if ( @array <= 1);

	for ($i=1; $i< @array; $i++ ) {
		$array[$i] = lc $array[$i];
		return 1 if($switch eq $array[$i]);
	}

	return 0;
}

sub switchInputFix {
	my @array = @_;
	my $switch = lc $array[0];
	my $i = 0;

	return 0 if ( @array <= 1);

	for ( my $i=1; $i< @array; $i++ ) {
		if($switch eq lc($array[$i])){
			return $array[$i];
		}
	}

	return 0;
}

sub getMapID {
	my $text = shift;
	my $r_type = shift;
	my @value = split(/\./, $text);

	$text = $value[0];

	if ($r_type == 1){
		$text .= '.gat';
	} elsif ($r_type == 2){
		$text .= '.fld';
	} elsif ($r_type == 3){
		$text .= '.rsw';
	}

	$text = lc $text;

	return $text;
}

sub getMapName {
	my $text = shift;
	my $r_type = shift;
	my $r_idx = shift;
	my $value = "";
	$text = getMapID("$text", 0);

	if ($r_idx > 1){
		$value = $indoors_lut{$text.".rsw"};
	} elsif ($r_idx){
		$value = $cities_lut{$text.".rsw"};
	} else {
		$value = $maps_lut{$text.".rsw"};
	}

	if ($r_type){
		$value .= "(${text})";
	}

	return $value;
}

sub isSteal {
	my $skill = shift;
	#$skill = uc $skill;
	#$skill = $skills_lut{$skill};

	my $val = 0;

	if (switchInput($skill, "TF_STEAL", 50)){
		$val = 1;
	} elsif (switchInput($skill, "RG_STEALCOIN", 211)){
		$val = 2;
	}

	return $val;
	#$monsters{$targetID}{'beSteal'} += isSteal($skillID);
}

sub parseSteal {
	my $sourceID = shift;
	my $targetID = shift;
	my $skillID = shift;

	my $val = isSteal($skillID);

	return $val if (!$val);

	my $name = $players{$sourceID}{'name'};

	if (%{$monsters{$targetID}}) {

		if ($sourceID eq $accountID){
#			$record{'counts'}{'Steal'}++ if ($val);

	#		if ($config{'teleportAuto_onSteal'}) {
	#			$ai_v{'ai_teleport_event'} = '自動順移你已偷竊成功';
	#		}

			$ai_v{'ai_teleport_event'} = "自動順移 你已偷竊\n" if ($config{'teleportAuto_onSteal'});

			my $nameID = $monsters{$targetID}{'nameID'};

			$record{'steal'}{$nameID}++;

			$name = "你";
		}

#		$monsters{$targetID}{'stealByWho'} = $sourceID;
		$monsters{$targetID}{'stealByWho'} = $name;
		$monsters{$targetID}{'beSteal'} += $val;
	}
}

sub getLogFile {
	my $switch	= lc shift;
	my $mode	= shift;
	my $filename;
	my $type	= '>>';

	my $path = 'logs/';
	$path .= $chars[$config{'char'}]{'name'}.'/';

	if ($switch eq 's') {
		$filename = 'Sys';
	} elsif ($switch eq 'p') {
		$filename = 'Party';
	} elsif ($switch eq 'g') {
		$filename = 'Guild';
	} elsif ($switch eq 'gm') {
		$filename = 'Guild_member';
	} elsif ($switch eq 'cr') {
		$filename = 'ChatRoom';
	} elsif ($switch eq 'pm') {
		$filename = 'PrivateMsg';
	} elsif (switchInput($switch, 'ii', 'i')) {
		$filename = 'iItemsLog';
	} elsif ($switch eq 'st') {
		$filename = 'StuckLog';
	} elsif (switchInput($switch, 'sh', 'shop')) {
		$filename = 'ShopLog';
	} elsif ($switch eq 'crt') {
		$filename = 'ChatRoomTitle';
	} elsif (switchInput($switch, 'gm', 'd', 'im')) {
		$filename = 'Alert';
	} elsif (switchInput($switch, 'e', 'error', 'err')) {
		$filename = 'Error';
#	} elsif ($switch eq '') {
#		$filename = '';
	} elsif (switchInput($switch, 'event', 'pet')) {
		$filename = 'Event';
	} elsif (switchInput($switch, 'escape', 'tele')) {
		$filename = 'Event_escape';
	} elsif (switchInput($switch, 'update')) {
		$filename = 'Update';
	} elsif (switchInput($switch, 'ii')) {
		$filename = 'iItemsLog';
	} elsif (switchInput($switch, 'mvp')) {
		$filename = 'Event_MVP';
	} elsif (switchInput($switch, 'map')) {
		$filename = 'Map';
	} elsif (switchInput($switch, 'debug')) {
		$filename = 'Debug';
	} else {
		$filename = 'Chat';
	}

	$filename = "$sc_v{'path'}{'def_logs'}${filename}" if ($mode);

	return "${filename}.txt";
}

sub sysLog {
	my $type	= lc shift;
	my $title	= shift;
	my @message	= shift;
	my $p		= shift;
	my $p2		= shift;

	if (!$p2){
		my $filename = getLogFile($type);

		my $tagTime = "[".getFormattedDate(int(time))."]";

		$title = "[$title] " if ($title ne "");

		open CHAT, ">> $sc_v{'path'}{'def_logs'}${filename}";

		foreach (@message) {
			print CHAT "$tagTime$title$_\n";
		}

		close CHAT;
	}

	if ($p) {
		printC(
			join(/\n/, @message)."\n"
			, (isNum($p) ? $type : $p)
		);
	}
}

sub sysLog_clear {
	my $type = shift;

	my @chatFiles;

	@chatFiles = (@chatFiles
		, "iItemsLog"
		, "ExpLog"
		, "StuckLog"
		, "StorageLog"
		, "CmdLog"
		, "MonsterData"
		, "ChatRoomTitle"

		, "Event_MVP"
		, "Update"
		, "Event_escape"
		, "Error"
		, "Sys"
		, ""
		, ""
		, ""
	);

	if ($type eq "all") {
		@chatFiles = (@chatFiles
			, "Alert"
			, "Chat"
			, "ChatRoom"
			, "Guild"
			, "Party"
			, "PrivateMsg"
			, "Map"
			, "Event"
			, "ShopLog"
			, "Guild_member"
			, ""
			, ""
			, ""
		);
	}

	my $filename;

	foreach (getArray((($type eq "")?"all":$type), @chatFiles)) {
		next if (!$_);

		$filename = "$sc_v{'path'}{'def_logs'}"."$_".".txt";

		if (-e $filename) {
			unlink($filename);
			printC("已清除 $filename...\n", "alert");
		}
	}
}

sub getArray {
	my $temp = shift;
	my @s_array = @_;
	my @temp;
	my %temp;
	my $temp2;
	my $except;

	while ($temp =~ /(\w+)/g) {
		$temp2 = $1;
		$qm = quotemeta $temp2;
		if ($temp2 eq "all") {
			foreach (@s_array) {
				$temp{$_} = $_;
			}
		} elsif ($temp2 =~ /\bexcept\b/i || $temp2 =~ /\bbut\b/i) {
			$except = 1;
		} else {
			if ($except) {
				foreach (@s_array) {
					delete $temp{$_} if $_ =~ /$qm/i;
				}
			} else {
				foreach (@s_array) {
					$temp{$_} = $_ if $_ =~ /$qm/i;
				}
			}
		}
	}

	my @r_array;

	foreach $temp (keys %temp) {
		push @r_array, $temp{$temp};
		$temp[@temp] = $temp{$temp};
	}

	return sort @r_array;
}

sub printVerbose {
	my $verbose	= shift;
	my $msg		= shift;
	my $tag		= shift;

	printC($msg, $tag) if ($verbose && $msg);
}

sub getTotal {
	my $ID1 = shift;
	my $ID2 = shift;
	my $val;
	my $dmg;

	if ($ID1 eq $accountID){
		$dmg = $monsters{$ID2}{'dmgFromYou'};
	}

	$val = " (Total: $dmg)" if ($dmg ne "");

	return $val;
}

sub parseAttack {
	my $ID1		= shift;
	my $ID2		= shift;
	my $damage	= shift;
	my $hit		= shift;
	my $type	= shift;
	my $damage2	= shift;

	my $dmgdisplay;

	if ($damage == 0) {
		$dmgdisplay = ($type == 11)?"Lucky!!":"Miss!";
	} else {
		$dmgdisplay = $damage;
		if ($type == 10){
			$dmgdisplay .= "☆";
			#CRITICAL ATTACK
		} elsif ($type == 8) {
			$dmgdisplay .= "◇";
			#DOUBLE ATTACK
		} elsif (!$type) {
			$dmgdisplay .= "";
			#ATTACK
		} else {
			$dmgdisplay .= "[$type]";
			#ATTACK ($type)
		}
	}

	if ($damage2 > 0) {
		$dmgdisplay .= " +".$damage2;
	}
	if ((!($type == 8 && $hit == 2) && $hit > 1) && $hit <= 15) {
		$dmgdisplay .= " : $hit hits";
	}

	if ($ID1 eq $accountID){
		$dmgdisplay .= getTotal($ID1, $ID2) if (!$config{'hideMsg_attackDmgFromYou'});
	}

	return $dmgdisplay;
}

sub printErr {
	my ($fn, $fd, $fu, $mode)= @_;

	return 0 if ($mode < 0 || !$fn || !$fd || !$fu);

	my $et;

	if ($mode) {
		$et =	"Syntax Error in function '$fn' ( $fd )\n"
		."Usage: $fn $fu\n";
#		$et =	"語法錯誤於命令 '$fn' ( $fd )\n"
#			."使用方法 : $fn $fu\n";
	} else {
		$et =	"Error in function '$fn' ( $fd )\n"
		."$fu.\n";
#中文版
#		$et =	"發生錯誤於命令 '$fn' ( $fd )\n"
#			."原因 : $fu\n";
	}

	print $et;
}

sub SyntaxError($$) {
	my ($fn, $fd, $fu)= @_;
	my $et;

#英文版
	$et =	"Syntax Error in function '$fn' ( $fd )\n"
		."Usage: $fn $fu\n";
#中文版
#	$et =	"語法錯誤於命令 '$fn' ( $fd )\n"
#		."使用方法 : $fn $fu\n";

	print $et;
}

sub FunctionError {
	my ($fn, $fd, $fu)= @_;
	my $et;

#英文版
	$et =	"Error in function '$fn' ( $fd )\n"
		."$fu.\n";
#中文版
#	$et =	"發生錯誤於命令 '$fn' ( $fd )\n"
#		."原因 : $fu\n";

	print $et;
}

sub ks_isTrue {
	my $h_cmd = shift;
	my $h_default = shift;

	if ($h_cmd eq "") {
		if ($h_default eq "") {
			$h_default = 1;
		}
		return $h_default;
	} else {
		return ($h_cmd ? 1 : 0);
	}
}

sub sc_getVal {
	my $h_cmd = shift;
	my $h_default = shift;
	my $mode = shift;

	if ($h_cmd eq "") {
		if ($h_default eq "") {
			$h_default = ($mode?0:1);
		}
		return $h_default;
	} else {
		return $h_cmd;
	}
}

sub sc_isTrue {
	my ($r_val, $r_chk) = @_;

#	$r_chk = 1 if ($r_chk eq "");

	my $val = (!$r_val || ( $r_val && $r_chk ));

#	print "sc_isTrue( $r_val , $r_chk ) = $val\n";
	return $val;
}

sub checkNpcMap {
	my ($name, $npc) = @_;

	my $val = (getMapID($name) eq getMapID($npcs_lut{$npc}{'map'}));

	return $val;
}

sub ai_unshift {
	my $name = shift;
	my %hash = @_ or ();

	unshift @ai_seq, $name;
	unshift @ai_seq_args, \%hash;
}

sub ai_shift {
	shift @ai_seq;
	shift @ai_seq_args;
}

sub ai_removeByKey {
	my ($ai_type, $ai_key, $ai_val) = @_;
	my $ai_index;

	return 0 if ($ai_type eq "" || $ai_key eq "" || !@ai_seq);

	for ($ai_index=0; $ai_index<@ai_seq; $ai_index++) {
		if (
			$ai_seq[$ai_index] eq $ai_type
			&& $ai_seq_args[$ai_index]{$ai_key} eq $ai_val
		) {
			binRemoveAndShiftByIndex(\@ai_seq, $ai_index);
			binRemoveAndShiftByIndex(\@ai_seq_args, $ai_index);

			return 1;
		}
	}
}

sub printDesc {
	my $type = shift;
	my $ID = shift;
	my $fullname = shift;
	my ($title, $desc, $tag);

	if (switchInput($type, "skill", "skills")){
		$title		= "Skill";
		$desc		= $skillsDesc_lut{$ID};
		$fullname	= $skills_lut{$ID};
	} elsif (switchInput($type, "Material", "Materials", "make")){
		$title		= "Material";
		$tag		= "Item";
		$desc		= $materialDesc_lut{$ID};
	} else {
		$title		= "Item";
		$desc		= $itemsDesc_lut{$ID};
	}

	$tag = $title if (!$tag);
	$desc = "No Description." if (!$desc);

	print	 subStrLine(0, "$title Description")
		."${tag} Name : $fullname\n\n"
		.Trim($desc)
		."\n"
		.subStrLine();
	;
}

sub valBolck {
	my $key = shift;

	return switchInput($key, @{$sc_v{'valBolck'}});
}

sub scModify {
	my ($hash, $key, $value, $mode, $modeEx) = @_;

	$hash = switchInputFix($hash, "timeout", "config");

	return 0 if (!$hash || ($modeEx && valBolck($key)) || !$key);

	my $tmpVal;
	my $method = ($mode?"set to":"is");

	$mode = 1 if ($sc_v{'kore'}{'lock'} && $mode > 1);

	if ($hash eq "timeout"){

		$tmpVal = ${$hash}{$key}{'timeout'};

		if ($mode) {

			$value = abs($value);

			${$hash}{$key}{'timeout'} = $value;
			writeDataFileIntact2("$sc_v{'path'}{'control'}/timeouts.txt", \%timeout) if ($mode > 1);

		}
	} else {

		$tmpVal = ${$hash}{$key};

		if ($mode) {

			${$hash}{$key} = $value;
			writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config) if ($mode > 1);

		}
	}

	$value = $tmpVal if (!$mode);

	my @tmp = keys %{$hash};

	if (binFind(\@tmp, $key) eq "") {
		$tmpVal = "variable '$key' doesn't exist";
	} else {
		$tmpVal = "'$key' $method '$value'";
	}

	$hash = switchInputFix($hash, "Timeout", "Config");

	printC("◇$hash $tmpVal\n", "s");
}

sub scMapJump {
	my $ip = shift;
	my $port = shift or 5000;

	return 0 if (!$ip);

	$sc_v{'warpperMode'}{'do'}	= 1;
	$sc_v{'warpperMode'}{'ip'}	= $ip;
	$sc_v{'warpperMode'}{'port'}	= $port;

	return 1;

	undef @ai_seq;
	undef @ai_seq_args;
	killConnection(\$remote_socket);
	sleep(5);
	relog();
}

sub sc_relog {
	my $message = shift;
	my %hash;

	$hash{'msg'} = $message;

	undef @ai_seq;
	undef @ai_seq_args;

	unshift @ai_seq, "sc_relog";
	unshift @ai_seq_args, \%hash;

	timeOutStart("ai_relog");
}

sub waitInput {
	my $msg = shift;
	my $t_timeout = shift or 5;

	$sc_v{'temp'}{'waitInput_time'} = time;

	my $input;

	printC("${msg}(Y/N)?, $t_timeout秒後自動取消...\n", "input") if ($msg);

	while (!timeOut($t_timeout, $sc_v{'temp'}{'waitInput_time'})) {
		usleep($config{'sleepTime'});

		if (input_canRead()) {
			$input = input_readLine();
		}

		last if $input;
	}

	my $val = ($input?1:0);

	delete $sc_v{'temp'}{'waitInput_time'};
	return $val;
}

sub getVendorList {
#	format VENDORTITLE =
#商店名稱: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 擁有者: @<<<<<<<<<<<<<<<<<<<<<<
#          $title_string, $owner_string
#
#.
#@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @>>>> @>>>>>>>>> @>>>>
#$i, $articles[$i]{'name'}, $itemTypes_lut{$articles[$i]{'type'}}, $articles[$i]{'amount'}, $price_string, $articles[$i]{'sold'}
#.
#	print "------------------------------------------------------------------------------\n";
#	print "小計: 目前賺進 ".toZeny($shop{'earned'})." Zeny\n" if ($shop{'earned'});
#
	my $v_title;
	my $v_format;



	$v_format = "@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @>>>> @>>>>>>>>> @>>>>";


}

sub ai_getCaseID {
	my $ID = shift;
	my $mode = shift;
	my ($pos_x, $pos_y) = @_;
	my ($name, $castBy, $dist);

	if (%{$players{$ID}}) {
		$name = "$players{$ID}{'name'} ($players{$ID}{'binID'}) ";
		$castBy = 4;
		$dist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ID}{'pos_to'}});
	} elsif ($ID eq $accountID) {
		$name = "你";
		$castBy = 1;
	} elsif ($ID eq "floor" || $pos_x || $pos_y) {
		$name = "座標: ".getFormattedCoords($pos_x, $pos_y);
		$castBy = 16;
		$dist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%coords);
	} elsif (%{$monsters{$ID}}) {
		$name = "$monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) ";
		$castBy = 2;
		$dist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ID}{'pos_to'}});
	} else {
		$name = "不明人物[".unpack("L1", $ID)."] ";;
		$castBy = 8;
	}

	if ($mode eq $ID && $castBy !=16) {
		$name = (($ID eq $accountID)?"你":"他")."自己";
	} elsif ($castBy !=16 && $castBy != 1 && $mode ne $ID && $mode) {
		$name = " $name";
	}

#	my @hash;
#
#	$hash[0]	= $name;
#	$hash[1]	= $castBy;

	return ($name, $castBy, $dist);
}

sub getSex {
	my $idx = shift;
	my $type = shift;
	my $val;
	$idx = $idx ? 1 : 0;

	if ($type) {
		my @dir = ('♀', '♂');

		$val = $dir[$idx];
	} else {
		$val = $sex_lut[$idx];
	}

	return $val;

}

sub isBoolean {
	my ($switch, $mode) = @_;
	my $val = 0;

	if (switchInput($switch, 1, "true", 0, "false")) {
		$val = 1;

		$val = (switchInput($switch, 1, "true")?1:0) if ($mode);
	} elsif ($mode) {
		$val = ($switch?1:0);
	}

	return $val;
}

sub sortNum {

	$a <=> $b;

}

sub ai_smartHeal {
	my $c_lv = shift;
	my $t_hp = shift;
	my $mode = shift;

	if ($config{'useSelf_skill_smartHeal'} || $mode) {

		$t_hp = $chars[$config{'char'}]{'hp_max'} - $chars[$config{'char'}]{'hp'} if ($t_hp <= 0);

		my $t_lv;
#		my $t_hp = $chars[$config{'char'}]{'hp_max'} - $chars[$config{'char'}]{'hp'};
		my $t_max = $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} or $c_lv;
		my $t_num;

		my $a_lv = $chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'} + $chars[$config{'char'}]{'int_bonus'};
		my $a_sp = $chars[$config{'char'}]{'sp'};
#		my $b_lv = $chars[$config{'char'}]{'skills'}{'HP_MEDITATIO'}{'lv'} * 0.025;
		my $b_lv = $chars[$config{'char'}]{'skills'}{'HP_MEDITATIO'}{'lv'} * 0.02;

#		$b_lv = 1;

		if ($a_lv <= 7) {
			$a_lv = 8;
		}

		my $e_a = $a_lv % 8;
		my $e_b = ($a_lv - $e_a) / 8;

		my ($e_heal1, $e_heal2, $e_heal);

#		$e_heal1 = $e_b * $t_lv;
#		$e_heal2 = $e_heal1 * (1 + $b_lv) * 10 % 10;
#		$e_heal = ($e_heal1 * (1 + $b_lv) * 10 - $e_heal2) / 10;

		my $t_fun = int($a_lv / 8);

		for (my $i = 1; $i <= $t_max; $i++) {
			$t_lv = $i;
			$t_sp = 10 + ($i * 3);
			$t_num = (4 + $i * 8);

			$e_heal1 = $e_b * $t_num;
			$e_heal2 = ($e_heal1 * (1 + $b_lv) * 10) % 10;
			$e_heal = ($e_heal1 * (1 + $b_lv) * 10 - $e_heal2) / 10;

			if ($a_sp < $t_sp) {
				$t_lv--;
				last;
			}
			last if ($e_heal >= $t_hp);
		}

#		print "ai_smartHeal: ${t_lv} - ${e_heal}\n";

		$c_lv = $t_lv;
	}
#	if ($config{'useSelf_skill_smartHeal'} || $mode) {
#
#		$t_hp = $chars[$config{'char'}]{'hp_max'} - $chars[$config{'char'}]{'hp'} if ($t_hp <= 0);
#
#		my $t_lv;
##		my $t_hp = $chars[$config{'char'}]{'hp_max'} - $chars[$config{'char'}]{'hp'};
#		my $t_max = $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} or $c_lv;
#		my $t_num;
#
#		my $a_lv = $chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'} + $chars[$config{'char'}]{'int_bonus'};
#		my $a_sp = $chars[$config{'char'}]{'sp'};
#		my $b_lv = $chars[$config{'char'}]{'skills'}{'HP_MEDITATIO'}{'lv'} * 0.025;
#
##		$b_lv = 1;
#
#		my $t_fun = int(int($a_lv / 8) * (1 + $b_lv));
#
#		for (my $i = 1; $i <= $t_max; $i++) {
#			$t_lv = $i;
#			$t_sp = 10 + ($i * 3);
#			$t_num = $t_fun * (4 + $i * 8);
#
#			if ($a_sp < $t_sp) {
#				$t_lv--;
#				last;
#			}
#			last if ($t_num >= $t_hp);
#		}
#
#		$c_lv = $t_lv;
#	}

	return $c_lv;
}

sub getStatusParam {
	my $text;
	# Character status
	my $attack_out = ("完全不", "被動", "主動")[$config{'attackAuto'}];
	my $random_out = ("未啟動", "啟動")[$config{'route_randomWalk'}];
	my $attack_string = "$attack_out攻擊, $random_out隨機路徑移動";

	my $sit_out = ("站姿", "坐姿")[$chars[$config{'char'}]{'sitting'}];
	my $body_out = ("北", "西北", "西", "西南", "南", "東南", "東", "東北")[$chars[$config{'char'}]{'look'}{'body'}];
	my $head_out = ("正前", "右前", "左前")[$chars[$config{'char'}]{'look'}{'head'}];
	my $outlook_string = "$sit_out, 面向$body_out方, 臉朝$head_out方";

	$text .= "[攻擊狀態] $attack_string\n";
	$text .= "[外    觀] $outlook_string\n";
	$text .= "[禁    言] 禁言限制還剩下 $chars[$config{'char'}]{'skill_ban'}分鐘\n" if ($chars[$config{'char'}]{'skill_ban'});
	$text .= "[Ｐ ｖ Ｐ] 目前排名 $chars[$config{'char'}]{'pvp'}{'rank_num'}\n" if ($chars[$config{'char'}]{'pvp'}{'start'} == 1);
	$text .= "[氣 球 數] 目前擁有 $chars[$config{'char'}]{'spirits'}顆氣球\n" if ($chars[$config{'char'}]{'spirits'});

	my $tmpF = "@<<<<<<<<<<< @>>";

	$text .= "[特殊狀態Ａ] ".getMsgStrings('0119_A', $chars[$config{'char'}]{'param1'})."\n" if ($chars[$config{'char'}]{'param1'});

	foreach (keys %{$messages_lut{'0119_B'}}) {
		$text .= swrite2($tmpF, ["[特殊狀態Ｂ]", $_])." ".getMsgStrings('0119_B', $_)."\n" if ($_ & $chars[$config{'char'}]{'param2'});
	}
	foreach (keys %{$messages_lut{'0119_C'}}) {
		$text .= swrite2($tmpF, ["[特殊狀態Ｃ]", $_])." ".getMsgStrings('0119_C', $_)."\n" if ($_ & $chars[$config{'char'}]{'param3'});
	}
	# Status icon

	my $messages;

	foreach (@{$chars[$config{'char'}]{'status'}}) {
		next if ($_ == 27 || $_ == 28);
		$messages = getMsgStrings('0196', $_, 1);
		$messages .= " -- $chars[$config{'char'}]{'autospell'}" if ($_ == 65);
		$text .= swrite2($tmpF, ["[持續狀態]", $_])." "."${messages}\n";
	}

	return $text;
}

sub writeDataFileIntact_sell {
	return 0;

	my $file = "$sc_v{'path'}{'def_logs'}\items_prices.txt";
	my $data;
	my $key;
	my %hash;
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

sub getItemsMaxWeight {
	my $val = 1;

	if (percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'} || percent_weight(\%{$chars[$config{'char'}]}) >= 89) {
		#print "負重達 ".percent_weight(\%{$chars[$config{'char'}]})."\n";

		if ($config{'itemsMaxWeight_considerHpSp'} > 1) {
			if (
				(
					!$config{'itemsMaxWeight_sp_lower'} ||
					($config{'itemsMaxWeight_sp_lower'} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{'itemsMaxWeight_sp_lower'})
				) && (
					!$config{'itemsMaxWeight_hp_lower'} ||
					($config{'itemsMaxWeight_hp_lower'} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{'itemsMaxWeight_hp_lower'}))
			) {
				#print "負重 Hp <= $config{'itemsMaxWeight_hp_lower'}\n";
			} else {
				$val = 0;
			}
		} elsif ($config{'itemsMaxWeight_considerHpSp'} > 0) {
			if ($config{'itemsMaxWeight_sp_lower'} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{'itemsMaxWeight_sp_lower'}) {
				#print "負重 Sp <= $config{'itemsMaxWeight_sp_lower'}\n";
			} elsif ($config{'itemsMaxWeight_hp_lower'} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{'itemsMaxWeight_hp_lower'}) {
				#print "負重 Hp <= $config{'itemsMaxWeight_hp_lower'}\n";
			} else {
				$val = 0;
			}
		}
	} else {
		$val = 0;
	}

	#print "[getItemsMaxWeight] $val\n";

	return $val;
}

sub isCollector {
# 會減取道具的怪物

	my $ID = shift;
	my $val = 0;

	if ($ID eq "" || $ai_v{'temp'}{'takenByMonsters'}{$monsters{$ID}{'nameID'}} < 0) {

	} elsif (
		$ai_v{'temp'}{'takenByMonsters'}{$monsters{$ID}{'nameID'}} > 0
		|| existsInList($config{'attackAuto_takenByMonsters'}, $monsters{$ID}{'name'})
	) {
		$ai_v{'temp'}{'takenByMonsters'}{$monsters{$ID}{'nameID'}} = 1;

		$val = 1;
	} else {
		$ai_v{'temp'}{'takenByMonsters'}{$monsters{$ID}{'nameID'}} = -1;
	}

	return $val;
}

sub isMonk {
# 是武道家系列的職業
# 用來檢查是否擁有氣球 spirits
	my $jobID = shift;

	return switchInput($jobID, 15, 39, 176, 4016);
}

sub inTargetMap {
	my ($map_now, $map_def, $map_list) = @_;

	$map_now = getMapID($map_now);
	$map_def = getMapID($map_def);

	return (($map_now eq $map_def) || ($map_list ne "" && existsInList($map_list, $map_now)))?1:0;
}

#---------------------------------
# korese 2.2

sub ai_findIndexAutoSwitch {
	my $String = shift;
	my $i = 0;
	my $find_index;
	for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
		next if ($chars[$config{'char'}]{'inventory'}[$i]{'type'} < 4);

		if ($chars[$config{'char'}]{'inventory'}[$i]{'name'} eq $String) {
			$find_index = $i;
			return $find_index if ($chars[$config{'char'}]{'inventory'}[$find_index]{'equipped'} == 0);
		} elsif (
			$chars[$config{'char'}]{'inventory'}[$i]{'slotName'}
			|| $chars[$config{'char'}]{'inventory'}[$i]{'elementName'}
		) {
			if (
				substr($chars[$config{'char'}]{'inventory'}[$i]{'name'},0,4) eq substr($String,0,4)
				&& (
					!$chars[$config{'char'}]{'inventory'}[$i]{'slotName'}
					|| existsInList($String, $chars[$config{'char'}]{'inventory'}[$i]{'slotName'})
				)
				&& (
					!$chars[$config{'char'}]{'inventory'}[$i]{'elementName'}
					|| existsInList($String, $chars[$config{'char'}]{'inventory'}[$i]{'elementName'})
				)
			) {
				$find_index = $i;
				return $find_index if ($chars[$config{'char'}]{'inventory'}[$find_index]{'equipped'} == 0);
			}
		}
	}
	return $find_index;
}

sub ai_stateResetParty {
	my $ID = shift;
	$i =0;
	while ($config{"useParty_skill_$i"}) {
		undef $ai_v{"useParty_skill_$i"."_time"}{$ID};
		$i++;
	}
	undef $players{$ID}{'state'};
	undef %{$players{$ID}{'skillsst'}};
}

#---------------------------------
# modKore-Hybrid-ReBirth

sub checkCoordinate {
	my ($oldX, $oldY, $j, $i) = @_;
	my ($x, $y);
	if ($field{'field'}[$oldY * $field{'width'} + $oldX + $j] == 1){
		$x = $j * -1 * $config{'modifiedWalkDistance'} + $oldX;
		$y = $i * -1 * $config{'modifiedWalkDistance'} + $oldY;
		if ($field{'field'}[$y * $field{'width'} + $x] == 0){
			$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'} = $x;
			$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'} = $y;
			return 1;
		}
	}
	return 0;
}

sub modifiedWalk {
	my $type = shift;
	my ($x, $y);
	my ($key, $distX, $distY);
	my ($oldX, $oldY) = ($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}, $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'});

	return if(binSize(\@portalsID));

	if ($type == 1) {
		return if(binFind(\@ai_seq, "attack"));
		for ($i = -1; $i < 2; $i++) {
			for ($j = -1; $j < 2; $j++) {
				next if ($i == 0 && $j == 0);
				return if(checkCoordinate($oldX, $oldY, $j, $i) == 1);
			}
		}
	} elsif ($type == 2){
		for ($j = -1; $j < 2; $j++) {
			next if ($j == 0);
			return if(checkCoordinate($oldX, $oldY, $j, 0) == 1);
		}
		for ($i = -1; $i < 2; $i++) {
			next if ($i == 0);
			return if(checkCoordinate($oldX, $oldY, 0, $i) == 1);
		}
		for ($i = -1; $i < 2; $i++) {
			for ($j = -1; $j < 2; $j++) {
				next if ($i == 0 || $j == 0);
				return if(checkCoordinate($oldX, $oldY, $j, $i) == 1);
			}
		}
	} else {
		return if (binFind(\@ai_seq, "attack"));
		for ($i = -1; $i < 2; $i++) {
			for ($j = -1; $j < 2; $j++) {
				next if ($i == 0 && $j == 0);
				$key = $key.$field{'field'}[($i+$oldY)*$field{'width'}+$oldX + $j];
			}
		}
		return if(!$modifiedWalk{$key});

		($x, $y) = (-1, -1)	if ($modifiedWalk{$key} == 1);
		($x, $y) = (0, -1)	if ($modifiedWalk{$key} == 2);
		($x, $y) = (1, -1)	if ($modifiedWalk{$key} == 3);
		($x, $y) = (-1, 0)	if ($modifiedWalk{$key} == 4);
		($x, $y) = (0, 0)	if ($modifiedWalk{$key} == 5);
		($x, $y) = (1, 0)	if ($modifiedWalk{$key} == 6);
		($x, $y) = (-1, 1)	if ($modifiedWalk{$key} == 7);
		($x, $y) = (0, 1)	if ($modifiedWalk{$key} == 8);
		($x, $y) = (1, 1)	if ($modifiedWalk{$key} == 9);

		return if($modifiedWalk{$key} == 5);

		$distX = $x * $config{'modifiedWalkDistance'};
		$distY = $y * $config{'modifiedWalkDistance'};

		while ($distX || $distY){
			($x,$y) = ($distX + $oldX, $distY + $oldY);

			if ($field{'field'}[$y * $field{'width'} + $x] == 0){
				$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'} = $x;
				$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'} = $y;
				last;
			}
			if ($distX){
				$distX--;
			} elsif ($distX < 0){
				$dist++;
			}
			if ($distY){
				$distY--;
			} elsif ($distY<0){
				$distY++;
			}
		}
	}
}

#---------------------------------
# KoreXP

sub getWallLength {
	my $r_pos = shift;
	my $dx = shift;
	my $dy = shift;
	my $x;
	my $y;
	my $len = 0;

	$x = $$r_pos{'x'};
	$y = $$r_pos{'y'};

	do {
		last if($x < 0 || $x >= $field{'width'} || $y < 0 || $y >= $field{'height'});

		$x += $dx;
		$y += $dy;
		$len++;
	} while ($field{'field'}[$y * $field{'width'} + $x]);

	#print "- Wall length at $$r_pos{'x'}, $$r_pos{'y'} $dx $dy is $len\n";
	return $len;
}

sub isAttackAble {
	my $r_pos = shift;
	my $r_pos_to = shift;
	my $distance;
	my $i;
	my %vector;
	my %pos;

	if (!$config{'attackAuto_checkWall'}) {
		return 1;
	}

	$distance = distance($r_pos, $r_pos_to);

	#print "$$r_pos{'x'}, $$r_pos{'y'} -> $$r_pos_to{'x'}, $$r_pos_to{'y'} DIST: $distance\n";
	getVector(\%{vector}, $r_pos, $r_pos_to);
	for ($i = 1; $i < $distance; $i++) {
		moveAlongVector(\%{pos}, $r_pos, \%{vector}, -$i);
		$pos{'x'} = int($pos{'x'});
		$pos{'y'} = int($pos{'y'});
		#print "- $pos{'x'}, $pos{'y'} $i $distance\n";
		if ($field{'field'}[$pos{'y'} * $field{'width'} + $pos{'x'}]) {
			#print "- Found wall at $pos{'x'}, $pos{'y'}\n";
			if (
				getWallLength(\%{pos}, -1, 0)		> 5
				|| getWallLength(\%{pos}, 1, 0)		> 5
				|| getWallLength(\%{pos}, 0, -1)	> 5
				|| getWallLength(\%{pos}, 0, 1)		> 5
				|| getWallLength(\%{pos}, -1, -1)	> 5
				|| getWallLength(\%{pos}, 1, 1)		> 5
				|| getWallLength(\%{pos}, 1, -1)	> 5
				|| getWallLength(\%{pos}, -1, 1)	> 5
			) {
				#print "- Can not attack.\n";
				return 0;
			}
		}
	}

	#print "- Attack able.\n";
	return 1;
}

sub getFieldNPC {
	my $ID = shift;
	my $npcMap;

	$npcMap = $npcs_lut{$ID}{'map'};

	$npcMap = $sc_v{'parseMsg'}{'map'} if ($npcMap eq "");

	getField(qq~$sc_v{'path'}{'fields'}/${npcMap}.fld~, \%{$ai_seq_args[0]{'dest_field'}});
}

1;