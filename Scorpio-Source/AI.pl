#######################################
#######################################
#AI
#######################################
#######################################



sub AI {

	my ($i, $j);

	undef $ai_v{'temp'}{'tele'};

	ai_event_cmd(\%{(shift)});

	ai_event_getInfo();

	ai_event_checkUser();

	if ($ai_seq[0] eq "sc_relog") {

		if (checkTimeOut('ai_relog')){

			printC($ai_seq_args[0]{'msg'}, "s");

#			relog();

			undef @ai_seq;
			undef @ai_seq_args;
			killConnection(\$remote_socket);
			sleep(5);
			relog();

#			undef @ai_seq;
#			undef @ai_seq_args;

#			ai_warpperMode("do", 1, "relog", 0);

		}

		return 0;
	}

	ai_event_map();

	ai_event_look();

	ai_event_auto_request();

	goto END_AI if (ai_event_dead());

	ai_event_auto_addPoints();

	ai_getTempVariable();

	goto AUTOITEMUSE if (ai_event_teleportAuto() || $sc_v{'temp'}{'teleOnEvent'});

#	ai_getTempVariable();

	ai_event_auto_parseInput();

	ai_event_autoCart();

	ai_event_npc_autoTalk();

	ai_event_npc_autoStorage();

	ai_event_npc_autoSell();

	ai_event_npc_autoBuy();

	ai_event_route_preferRoute();

	ai_event_useWaypoint();

	ai_event_lockMap();

	ai_event_shop();

	ai_event_route_randomWalk();

AUTOITEMUSE:
	ai_getTempVariable();

	ai_event_auto_useItem();

	goto END_AI if ($sc_v{'temp'}{'teleOnEvent'} || $ai_v{'temp'}{'teleOnEvent'});

	ai_getTempVariable();

	ai_event_auto_useSkill();

	ai_event_auto_resurrect();

	ai_event_auto_useParty();

	ai_event_auto_useGuild();

	ai_event_hitAndRun();

	ai_event_follow();

	ai_event_body();

	ai_event_auto_attack();

	ai_event_attack();

	ai_event_autoEquip();

	ai_event_route();

	ai_event_route_getRoute();

	ai_event_route_getMapRoute();

	ai_event_skills_use();

	ai_event_items_take();

	ai_event_items_gather();

	ai_event_take();

	ai_event_move();

#	ai_event_teleportAuto();

	# Record char position for MapViewer
	ai_event_recordLocation();

END_AI:

	ai_event_debug();

	ai_event_end();

}

sub ai_event_end {
	if ($ai_v{'clear_aiQueue'}) {
		undef $ai_v{'clear_aiQueue'};
		undef @ai_seq;
		undef @ai_seq_args;
	}

	if ($sc_v{'ai'}{'first'} && checkTimeOut('ai_first_wait')) {
		undef $sc_v{'ai'}{'first'};
		timeOutStart('ai_first_wait');
	}
}

sub ai_event_debug {
	#DEBUG CODE
	if (time - $ai_v{'time'} > 2 && $config{'debug'}) {
		$stuff = @ai_seq_args;
		print <<"EOM";
AI: @ai_seq | $stuff

conState:	$sc_v{'input'}{'conState'}
field:		$field{'name'}
EOM
;

		$ai_v{'time'} = time;
	}

	#koreSE2.2
	if (@ai_seq > 20) {
		sysLog(
			"debug"
			, "AI"
			, "AI 陣列超出範圍，清除陣列\nAI: (@ai_seq | $stuff)\n"
			, "error"
		);

		undef @ai_seq;
		undef @ai_seq_args;
	}
}

sub ai_event_getInfo {

	##### MISC #####

	if (checkTimeOut('ai_wipe_check')) {
		foreach (keys %players_old) {
			delete $players_old{$_} if (time - $players_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %monsters_old) {
			delete $monsters_old{$_} if (time - $monsters_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %npcs_old) {
			delete $npcs_old{$_} if (time - $npcs_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %items_old) {
			delete $items_old{$_} if (time - $items_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		foreach (keys %portals_old) {
			delete $portals_old{$_} if (time - $portals_old{$_}{'gone_time'} >= $timeout{'ai_wipe_old'}{'timeout'});
		}
		timeOutStart('ai_wipe_check');
		print "Wiped old\n" if ($config{'debug'} >= 2);
	}

	if (checkTimeOut('ai_getInfo')) {
		foreach (keys %players) {
			if ($players{$_}{'name'} eq "不明人物") {
				sendGetPlayerInfo(\$remote_socket, $_);
				last;
			}
		}
		foreach (keys %monsters) {
			if ($monsters{$_}{'name'} =~ /不明怪物/ || $monsters{$_}{'name'} =~ /Unknown/) {
				sendGetPlayerInfo(\$remote_socket, $_);
				last;
			}
		}
		foreach (keys %npcs) {
			if ($npcs{$_}{'name'} =~ /不明NPC/ || $npcs{$_}{'name'} =~ /Unknown/) {
				sendGetPlayerInfo(\$remote_socket, $_);
#				last;
			}
		}
		foreach (keys %pets) {
			if ($pets{$_}{'name_given'} =~ /不明寵物/) {
				sendGetPlayerInfo(\$remote_socket, $_);
				last;
			}
		}
		timeOutStart('ai_getInfo');
	}

	if (!$option{'X-Kore'} && checkTimeOut('ai_sync')) {
		timeOutStart('ai_sync');
		sendSync(\$remote_socket, getTickCount());
	}

	# Auto reset teleOnEvent
#	if ($ai_v{'temp'}{'teleOnEvent'} && checkTimeOut('ai_teleport_event')) {
#		undef $ai_v{'temp'}{'teleOnEvent'};
#		undef $sc_v{'temp'}{'teleOnEvent'};
#	}

	if (checkTimeOut('ai_teleport_event')) {
		undef $ai_v{'temp'}{'teleOnEvent'} if ($ai_v{'temp'}{'teleOnEvent'});
		undef $sc_v{'temp'}{'teleOnEvent'} if ($sc_v{'temp'}{'teleOnEvent'});
	}

	if ($ai_v{'portalTrace_mapChanged'}) {
		undef $ai_v{'portalTrace_mapChanged'};
		undef $ai_v{'temp'}{'foundID'};
		undef $ai_v{'temp'}{'smallDist'};
		$ai_v{'temp'}{'first'} = 1;
		foreach (@portalsID_old) {
			$ai_v{'temp'}{'dist'} = distance(\%{$chars_old[$config{'char'}]{'pos_to'}}, \%{$portals_old{$_}{'pos'}});
			if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
				$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
				$ai_v{'temp'}{'foundID'} = $_;
				undef $ai_v{'temp'}{'first'};
			}
		}
		if ($ai_v{'temp'}{'foundID'}) {
			$ai_v{'portalTrace'}{'source'}{'map'} = $portals_old{$ai_v{'temp'}{'foundID'}}{'source'}{'map'};
			$ai_v{'portalTrace'}{'source'}{'ID'} = $portals_old{$ai_v{'temp'}{'foundID'}}{'nameID'};
			%{$ai_v{'portalTrace'}{'source'}{'pos'}} = %{$portals_old{$ai_v{'temp'}{'foundID'}}{'pos'}};
		}
	}

	if (%{$ai_v{'portalTrace'}} && portalExists($ai_v{'portalTrace'}{'source'}{'map'}, \%{$ai_v{'portalTrace'}{'source'}{'pos'}}) ne "") {
		undef %{$ai_v{'portalTrace'}};
	} elsif (%{$ai_v{'portalTrace'}} && $field{'name'}) {
		undef $ai_v{'temp'}{'foundID'};
		undef $ai_v{'temp'}{'smallDist'};
		$ai_v{'temp'}{'first'} = 1;
		foreach (@portalsID) {
			$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$portals{$_}{'pos'}});
			if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
				$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
				$ai_v{'temp'}{'foundID'} = $_;
				undef $ai_v{'temp'}{'first'};
			}
		}

		if (%{$portals{$ai_v{'temp'}{'foundID'}}}) {
			if (portalExists($field{'name'}, \%{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}}) eq ""
				&& $ai_v{'portalTrace'}{'source'}{'map'} && $ai_v{'portalTrace'}{'source'}{'pos'}{'x'} ne "" && $ai_v{'portalTrace'}{'source'}{'pos'}{'y'} ne ""
				&& $field{'name'} && $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'} ne "" && $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'} ne "") {


				$portals{$ai_v{'temp'}{'foundID'}}{'name'} = "$field{'name'} -> $ai_v{'portalTrace'}{'source'}{'map'}";
				$portals{pack("L", $ai_v{'portalTrace'}{'source'}{'ID'})}{'name'} = "$ai_v{'portalTrace'}{'source'}{'map'} -> $field{'name'}";

				$ai_v{'temp'}{'ID'} = "$ai_v{'portalTrace'}{'source'}{'map'} $ai_v{'portalTrace'}{'source'}{'pos'}{'x'} $ai_v{'portalTrace'}{'source'}{'pos'}{'y'}";
				$portals_lut{$ai_v{'temp'}{'ID'}}{'source'}{'map'} = $ai_v{'portalTrace'}{'source'}{'map'};
				%{$portals_lut{$ai_v{'temp'}{'ID'}}{'source'}{'pos'}} = %{$ai_v{'portalTrace'}{'source'}{'pos'}};
				$portals_lut{$ai_v{'temp'}{'ID'}}{'dest'}{'map'} = $field{'name'};
				%{$portals_lut{$ai_v{'temp'}{'ID'}}{'dest'}{'pos'}} = %{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}};

				updatePortalLUT("$sc_v{'path'}{'tables'}/portals.txt",
					$ai_v{'portalTrace'}{'source'}{'map'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'x'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'y'},
					$field{'name'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'});

				$ai_v{'temp'}{'ID2'} = "$field{'name'} $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'} $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'}";
				$portals_lut{$ai_v{'temp'}{'ID2'}}{'source'}{'map'} = $field{'name'};
				%{$portals_lut{$ai_v{'temp'}{'ID2'}}{'source'}{'pos'}} = %{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}};
				$portals_lut{$ai_v{'temp'}{'ID2'}}{'dest'}{'map'} = $ai_v{'portalTrace'}{'source'}{'map'};
				%{$portals_lut{$ai_v{'temp'}{'ID2'}}{'dest'}{'pos'}} = %{$ai_v{'portalTrace'}{'source'}{'pos'}};

				updatePortalLUT("$sc_v{'path'}{'tables'}/portals.txt",
					$field{'name'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'},
					$ai_v{'portalTrace'}{'source'}{'map'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'x'}, $ai_v{'portalTrace'}{'source'}{'pos'}{'y'});
			}
			undef %{$ai_v{'portalTrace'}};
		}
	}

	##### CLIENT SUSPEND #####

	if ($ai_seq[0] eq "clientSuspend" && timeOut(\%{$ai_seq_args[0]})) {
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "clientSuspend" && $option{'X-Kore'}) {
		#this section is used in X-Kore
		if ($ai_seq_args[0]{'type'} eq "0089") {
			if ($ai_seq_args[0]{'args'}[0] == 2) {
				if ($chars[$config{'char'}]{'sitting'}) {
					$ai_seq_args[0]{'time'} = time;
				}
			} elsif ($ai_seq_args[0]{'args'}[0] == 3) {
				$ai_seq_args[0]{'timeout'} = 6;
			} else {
				if (!$ai_seq_args[0]{'forceGiveup'}{'timeout'}) {
					$ai_seq_args[0]{'forceGiveup'}{'timeout'} = 6;
					$ai_seq_args[0]{'forceGiveup'}{'time'} = time;
				}
				if ($ai_seq_args[0]{'dmgFromYou_last'} != $monsters{$ai_seq_args[0]{'args'}[1]}{'dmgFromYou'}) {
					$ai_seq_args[0]{'forceGiveup'}{'time'} = time;
				}
				$ai_seq_args[0]{'dmgFromYou_last'} = $monsters{$ai_seq_args[0]{'args'}[1]}{'dmgFromYou'};
				$ai_seq_args[0]{'missedFromYou_last'} = $monsters{$ai_seq_args[0]{'args'}[1]}{'missedFromYou'};
				if (%{$monsters{$ai_seq_args[0]{'args'}[1]}}) {
					$ai_seq_args[0]{'time'} = time;
				} else {
					$ai_seq_args[0]{'time'} -= $ai_seq_args[0]{'timeout'};
				}
				if (timeOut(\%{$ai_seq_args[0]{'forceGiveup'}})) {
					$ai_seq_args[0]{'time'} -= $ai_seq_args[0]{'timeout'};
				}
			}
		} elsif ($switch eq "009F") {
			if (!$ai_seq_args[0]{'forceGiveup'}{'timeout'}) {
				$ai_seq_args[0]{'forceGiveup'}{'timeout'} = 4;
				$ai_seq_args[0]{'forceGiveup'}{'time'} = time;
			}
			if (%{$items{$ai_seq_args[0]{'args'}[0]}}) {
				$ai_seq_args[0]{'time'} = time;
			} else {
				$ai_seq_args[0]{'time'} -= $ai_seq_args[0]{'timeout'};
			}
			if (timeOut(\%{$ai_seq_args[0]{'forceGiveup'}})) {
				$ai_seq_args[0]{'time'} -= $ai_seq_args[0]{'timeout'};
			}
		}
	}

	if ($config{'dcOnDualLogin'} ne "1" && $config{'dcOnDualLogin_protect'} && $sc_v{'parseMsg'}{'dcOnDualLogin'} && $sc_v{'temp'}{'dcOnDualLogin'} > 0) {
		if (binSize(\@playersID) || binSize(\@npcsID) || binSize(\@portalsID) || $sc_v{'temp'}{'dcOnDualLogin'} == 1) {
			sysLog("im", "防盜", "順移: 遭相同序號登入 $sc_v{'parseMsg'}{'dcOnDualLogin'}次, 自動迴避玩家、傳點、NPC！ 順移次數: $sc_v{'temp'}{'dcOnDualLogin'}次", 1);
			$sc_v{'temp'}{'dcOnDualLogin'}++;

			$ai_v{'temp'}{'teleOnEvent'} = 1;
			timeOutStart('ai_teleport_event');
			useTeleport(1);
			ai_clientSuspend(0);
			$ai_v{'clear_aiQueue'} = 1;

			$ai_v{'temp'}{'tele'} = 1;
		} else {
			undef $sc_v{'temp'}{'dcOnDualLogin'};

			$timeout{'gamelogin'}{'timeout'} = $sc_v{'timeout'}{'gamelogin'} if ($sc_v{'timeout'}{'gamelogin'} ne "");
			$timeout{'master'}{'timeout'} = $sc_v{'timeout'}{'master'} if ($sc_v{'timeout'}{'master'} ne "");
			$timeout{'maplogin'}{'timeout'} = $sc_v{'timeout'}{'maplogin'} if ($sc_v{'timeout'}{'maplogin'} ne "");
			$timeout{'play'}{'timeout'} = $sc_v{'timeout'}{'play'} if ($sc_v{'timeout'}{'play'} ne "");

			undef $sc_v{'timeout'}{'gamelogin'}, $sc_v{'timeout'}{'master'}, $sc_v{'timeout'}{'maplogin'}, $sc_v{'timeout'}{'play'};
		}
	}


	### GET GUILD INFORMATION ###
	if ($config{'guildAutoInfo'} && $chars[$config{'char'}]{'guild'}{'name'} && checkTimeOut('ai_guildAutoInfo')) {
		sendGuildInfoRequest(\$remote_socket);

		my $i = 0;
		my $j = int($config{'guildAutoInfo'});

		$j = 4 if ($j > 4 || $j < 1);

		for ($i = 0; $i<=$j ; $i++) {
			sendGuildRequest(\$remote_socket, $i);
		}
		timeOutStart('ai_guildAutoInfo');
	}

#Karasu Start
	# EXPs gained per hour
	if ($config{'recordExp'} >= 2 && $record{'exp'}{'start'} ne "" && timeOut($config{'recordExp_timeout'}, $recordExp{'record'}) && !(($sc_v{'input'}{'conState'} == 2 || $sc_v{'input'}{'conState'} == 3) && $sc_v{'input'}{'waitingForInput'})) {
		unlink("$sc_v{'path'}{'def_logs'}"."ExpLog.txt") if ($config{'recordExp'} == 3 && -e "$sc_v{'path'}{'def_logs'}"."ExpLog.txt");
		parseInput("exp log");
		parseInput("exp reset") if ($config{'recordExp'} == 4);
		$recordExp{'record'} = time;
	}
#Karasu End

	if (checkTimeOut('ai_event_onHit') && $sc_v{'ai'}{'onHit'}) {
		$sc_v{'ai'}{'onHit'} = 0 if (!ai_getAggressivesEx() && !switchInput($ai_seq[0], "attack", "skill_use"));
		timeOutStart(1, 'ai_event_onHit');
	}

	if (checkTimeOut('ai_item_use_check') && $config{'autoCheckItemUse'} && !switchInput($ai_seq[0], "attack", "take", "items_take", "skill_use") && !$sc_v{'ai'}{'onHit'}) {
		if ($chars[$config{'char'}]{'sendItemUse'} >= $config{'autoCheckItemUse'}) {
#			printC("使用物品失敗$chars[$config{'char'}]{'sendItemUse'}次\n", "error");
			sysLog("error", "錯誤", "使用物品失敗 $chars[$config{'char'}]{'sendItemUse'} 次, 重新連線！", 1);
#			chatLog("x", "使用物品失敗$chars[$config{'char'}]{'sendItemUse'}次\n");
#			relog();
			relogWait("◆嚴重錯誤: 連續使用物品失敗 $chars[$config{'char'}]{'sendItemUse'} 次", 1);

			undef $chars[$config{'char'}]{'sendItemUse'};
		}
		timeOutStart('ai_item_use_check');
	}

	if (checkTimeOut('ai_checkStatus') && !switchInput($ai_seq[0], "attack", "take", "items_take")) {
		if ($config{'dcOnZeny'} && $chars[$config{'char'}]{'zenny'} <= $config{'dcOnZeny'}) {
			printC("◆啟動 dcOnZeny - 立即登出！\n", "s");
			sysLog("d", "狀態", "Zeny <= $config{'dcOnZeny'}, 立即登出！");
#			$quit = 1;

			quit(1, 1);
		} else {
			timeOutStart('ai_checkStatus');
		}
	}

}

sub ai_event_teleportAuto {
	##### AUTO-TELEPORT #####

#	return 1 if ($sc_v{'temp'}{'teleOnEvent'});

	my ($tele_val, $tele_verbose);

#	$ai_v{'map_name_lu'} = getMapID($map_name, 3);

#	if ($config{'teleportAuto_onlyWhenSafe'} && binSize(\@playersID)) {
#		undef $ai_v{'ai_teleport_safe'};
#		if (!$cities_lut{$ai_v{'map_name_lu'}} && !$indoors_lut{$ai_v{'map_name_lu'}} && checkTimeOut('ai_teleport_safe_force')) {
#			$ai_v{'ai_teleport_safe'} = 1;
#		}
#	} elsif (!$cities_lut{$ai_v{'map_name_lu'}} && !$indoors_lut{$ai_v{'map_name_lu'}}) {
#		$ai_v{'ai_teleport_safe'} = 1;
#		timeOutStart('ai_teleport_safe_force');
#	} else {
#		undef $ai_v{'ai_teleport_safe'};
#	}
	if ($config{'teleportAuto_onlyWhenSafe'} && binSize(\@playersID)) {
		undef $ai_v{'ai_teleport_safe'};
		if (($config{'teleportAuto_inCity'} || !$ai_v{'temp'}{'inCity'}) && !$ai_v{'temp'}{'inDoor'} && checkTimeOut('ai_teleport_safe_force')) {
			$ai_v{'ai_teleport_safe'} = 1;
		}
	} elsif (($config{'teleportAuto_inCity'} || !$ai_v{'temp'}{'inCity'}) && !$ai_v{'temp'}{'inDoor'}) {
		$ai_v{'ai_teleport_safe'} = 1;
		timeOutStart('ai_teleport_safe_force');
	} else {
		undef $ai_v{'ai_teleport_safe'};
	}

#	if ($ai_v{'ai_teleport_safe'} && $chars[$config{'char'}]{'param1'}) {
#		$ai_v{'ai_teleport_safe'} = 1;
#	}

#	$ai_v{'temp'}{'inLockMap'}	= (($field{'name'} eq $config{'lockMap'} || $config{'lockMap'} eq "")?1:0);
#	$ai_v{'temp'}{'inCity'}		= $cities_lut{$field{'name'}.'.rsw'};
#	$ai_v{'temp'}{'inTake'}		= ((binFind(\@ai_seq, "take") ne "" || binFind(\@ai_seq, "items_take") ne "")?1:0);
#	$ai_v{'temp'}{'onHit'}		= $sc_v{'ai'}{'onHit'} or ai_getMonstersHitMe();
#	$ai_v{'temp'}{'inAttack'}	= (binFind(\@ai_seq, "attack") ne "")?1:0;
#	$ai_v{'temp'}{'getAggressives'}	= ai_getAggressives();
#	$ai_v{'temp'}{'getAggressives'}	= $ai_v{'temp'}{'getAggressives'}?$ai_v{'temp'}{'getAggressives'}:$ai_v{'temp'}{'onHit'};

	return 1 if ($sc_v{'temp'}{'itemsImportantAutoMode'});

#	undef $ai_v{'temp'}{'tele'};

	if (!$ai_v{'temp'}{'tele'} && $config{'teleportAuto_away'} && checkTimeOut('ai_teleport_away') && $ai_v{'ai_teleport_safe'} && !$sc_v{'temp'}{'teleOnEvent'}) {
#Karasu Start
		# Detect more condition
		my %agNotorious;
		my $name_lc;
#		my $agMonsters = ai_getAggressives();
		my $agMonsters = $ai_v{'temp'}{'getAggressives'};

		my $tele_coords = getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});

		foreach (@monstersID) {
			$name_lc = lc($monsters{$_}{'name'});
			$agNotorious{$name_lc}++ if ($mon_control{$name_lc}{'teleport_auto'} == 5 && ($monsters{$_}{'dmgToYou'} > 0 || $monsters{$_}{'missedYou'} > 0));
			if (
				$mon_control{$name_lc}{'teleport_auto'} == 1
				|| (
					(
						$mon_control{$name_lc}{'teleport_auto'} == 2
						|| (
							$mon_control{$name_lc}{'teleport_auto'} == 3
							&& (
#								binFind(\@ai_seq, "attack") eq ""
								!$ai_v{'temp'}{'inAttack'}
								|| $ai_seq_args[binFind(\@ai_seq, "attack")]{'ID'} eq $_
							)
						)
					)
#					&& binFind(\@ai_seq, "take") eq ""
#					&& binFind(\@ai_seq, "items_take") eq ""
					&& !$ai_v{'temp'}{'inTake'}
					&& (
						$monsters{$_}{'dmgToYou'} > 0
						|| $monsters{$_}{'missedYou'} > 0
					)
					&& (
#						$ai_v{'map_name_lu'} eq $config{'lockMap'}.'.rsw'
#						|| $config{'lockMap'} eq ""
						$ai_v{'temp'}{'inLockMap'}
					)
				)
				|| (
					$mon_control{$name_lc}{'teleport_auto'} == 4
					&& distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}) <= $mon_control{$name_lc}{'teleport_extra'}
				)
				|| (
					$mon_control{$name_lc}{'teleport_extra'}
					&& $agNotorious{$name_lc} >= $mon_control{$name_lc}{'teleport_extra'}
				)
				|| (
					$mon_control{$name_lc}{'teleport_auto'} == 5
					&& (
						$monsters{$_}{'dmgToYou'} > 0
						|| $monsters{$_}{'missedYou'} > 0
					)
					&& (
						$mon_control{$name_lc}{'teleport_extra2'}
						&& $agMonsters >= $mon_control{$name_lc}{'teleport_extra2'}
					)
				)
			) {
				# Verbose of teleport
				undef $tele_verbose;

				if ($mon_control{$name_lc}{'teleport_auto'} == 1) {
					$tele_verbose = "▲自動瞬移 - 迴避指定怪物(1): $monsters{$_}{'name'}, 瞬移前座標: $tele_coords\n";
				} elsif ($mon_control{$name_lc}{'teleport_auto'} == 2) {
					$tele_verbose = "▲自動瞬移 - 迴避指定怪物(2): $monsters{$_}{'name'}, 瞬移前座標: $tele_coords\n";
				} elsif ($mon_control{$name_lc}{'teleport_auto'} == 3) {
					$tele_verbose = "▲自動瞬移 - 迴避指定怪物(3): $monsters{$_}{'name'}, 瞬移前座標: $tele_coords\n";
				} elsif ($mon_control{$name_lc}{'teleport_auto'} == 4) {
					$tele_verbose = "▲自動瞬移 - 迴避指定怪物(4): $monsters{$_}{'name'}, 瞬移前座標: $tele_coords, 距離: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}})."\n";
				} elsif ($agNotorious{$name_lc} >= $mon_control{$name_lc}{'teleport_extra'}) {
					$tele_verbose = "▲自動瞬移 - 迴避指定怪物(5-1): $monsters{$_}{'name'}, 瞬移前座標: $tele_coords, 數量: $agNotorious{$name_lc}\n";
				} elsif ($agMonsters >= $mon_control{$name_lc}{'teleport_extra2'}) {
					$tele_verbose = "▲自動瞬移 - 迴避指定怪物(5-2): $monsters{$_}{'name'}, 瞬移前座標: $tele_coords, 數量: $agMonsters\n";
				}

				$ai_v{'temp'}{'teleOnEvent'} = 1;
				timeOutStart('ai_teleport_event');
				$tele_val = useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;

				$sc_v{'temp'}{'teleOnEvent'} = 1;

				printVerbose($config{'teleportAuto_verbose'}, $tele_verbose, "tele");

				$ai_v{'temp'}{'tele'} = 1;

				last;
			}
		}
		timeOutStart('ai_teleport_away');
	}

	if (!$ai_v{'temp'}{'tele'} && checkTimeOut('ai_teleport_hp') && (ai_getAggressivesEx() || $sc_v{'ai'}{'onHit'} || $ai_v{'temp'}{'onHit'})) {
		my $tele = 1;
		undef $tele_verbose;
		my $agMonsters = ai_getAggressivesEx();
		$agMonsters = 1 if (!$agMonsters && ($sc_v{'ai'}{'onHit'} || $ai_v{'temp'}{'onHit'}));

		my $modeConfig = ($config{'teleportAuto_autoMode'} > 1)?"teleportAuto_whenDmgToYou":"teleportAuto_onHit";

		if ($config{'teleportAuto_minAggressives'} && $agMonsters >= $config{'teleportAuto_minAggressives'}) {
			$tele_verbose = "▲自動瞬移 - 遭受 $config{'teleportAuto_minAggressives'} 隻以上怪物圍攻\n";
		} elsif ($config{'teleportAuto_sp'} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{'teleportAuto_sp'}) {
			$tele_verbose = "▲自動瞬移 - SP低於 $config{'teleportAuto_sp'}%\n";
		} elsif (
			$config{'teleportAuto_onHit'}
			&& ($sc_v{'ai'}{'onHit'} >= $config{'teleportAuto_onHit'})
			&& !(
				$config{'teleportAuto_autoMode'}
				&& $config{'teleportAuto_hp'}
				&& percent_hp(\%{$chars[$config{'char'}]}) > $config{'teleportAuto_hp'}
			)
		) {
			$tele_verbose = "▲自動瞬移 - 遭受超過 $config{'teleportAuto_onHit'} 傷害\n";
		} elsif ($config{'teleportAuto_hp'} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{'teleportAuto_hp'}) {
			$tele_verbose = "▲自動瞬移 - HP低於 $config{'teleportAuto_hp'}%\n";

			if ($config{'teleportAuto_autoMode'} > 0){
				if ($ai_v{'ka'}{$modeConfig} eq ""){
					$ai_v{'ka'}{$modeConfig} = ($config{$modeConfig}?1:0);
					$config{$modeConfig} = 1;
					$tele_verbose = "[Event] HP低於 $config{'teleportAuto_hp'}% 啟動 $modeConfig\n";

					timeOutStart('ai_event_onHit');
				} elsif ($ai_v{'ka'}{$modeConfig} ne "" && !$config{$modeConfig} && $config{'teleportAuto_hp'}) {
					undef $ai_v{'ka'}{$modeConfig};
				} else {
					$tele = 0;
				}
			}

#		} elsif ($config{'teleportAuto_onHit'} && ($sc_v{'ai'}{'onHit'} >= $config{'teleportAuto_onHit'})) {
#			$tele_verbose = "▲自動瞬移 - 遭受超過 $config{'teleportAuto_onHit'} 傷害\n";
		} else {
			$tele = 0;

			if ($config{'teleportAuto_autoMode'} > 0 && $ai_v{'ka'}{$modeConfig} ne "" && !$sc_v{'ai'}{'onHit'}){
				$config{$modeConfig} = $ai_v{'ka'}{$modeConfig};
				$tele_verbose = "[Event] HP高於 $config{'teleportAuto_hp'}% $modeConfig 恢復為 $config{$modeConfig}\n";
				undef $ai_v{'ka'}{$modeConfig};

				$tele = -1;
				timeOutStart('ai_event_onHit');
			}
		}

		if ($tele > 0){
#			printVerbose($config{'teleportAuto_verbose'}, $tele_verbose, "tele");

			event_checkInfo();

			$ai_v{'temp'}{'teleOnEvent'} = 1;
			timeOutStart('ai_teleport_event');
			$tele_val = useTeleport(1);
			$ai_v{'clear_aiQueue'} = 1;
			timeOutStart('ai_teleport_hp');

			$sc_v{'temp'}{'teleOnEvent'} = 1;

			printVerbose($config{'teleportAuto_verbose'}, $tele_verbose, "tele");

			$ai_v{'temp'}{'tele'} = 1;
		} elsif ($tele < 0) {
			printVerbose($config{'teleportAuto_verbose'}, $tele_verbose, "tele");
		}
	}

	if (
		(
			$config{'teleportAuto_search'}
#			&& !($config{'teleportAuto_search'} > 1 && ($ai_v{'useGuild_skill'} || $ai_v{'useParty_skill'}))
		)
		&& !$ai_v{'temp'}{'tele'}
		&& $ai_seq[0] ne "clientSuspend"
#		&& !$sc_v{'temp'}{'teleOnEvent'}
		&& !($ai_v{'temp'}{'teleOnEvent'} && $sc_v{'temp'}{'teleOnEvent'})
		&& checkTimeOut('ai_teleport_search')
#		&& binFind(\@ai_seq, "attack") eq ""
		&& !$ai_v{'temp'}{'inAttack'}
#		&& binFind(\@ai_seq, "take") eq ""
#		&& binFind(\@ai_seq, "items_take") eq ""
		&& !$ai_v{'temp'}{'inTake'}
		&& $ai_v{'ai_teleport_safe'}
		&& binFind(\@ai_seq, "sitAuto") eq ""
		&& binFind(\@ai_seq, "talkAuto") eq ""
		&& binFind(\@ai_seq, "storageAuto") eq ""
		&& binFind(\@ai_seq, "sellAuto") eq ""
		&& binFind(\@ai_seq, "buyAuto") eq ""
		&& binFind(\@ai_seq, "follow") eq ""
		# Teleport in lockMap only
		&& (
#			$ai_v{'map_name_lu'} eq $config{'lockMap'}.'.rsw'
#			|| $config{'lockMap'} eq ""
			$ai_v{'temp'}{'inLockMap'}
		)
		&& !$ai_v{'temp'}{'castWait'}
		&& (
			$ai_v2{'ImportantItem'}{'attackAuto'} eq ""
			|| !binSize(\@{$ai_v2{'ImportantItem'}{'targetID'}})
		)
	) {
		undef $ai_v{'temp'}{'search'};
		foreach (keys %mon_control) {
			if ($mon_control{$_}{'teleport_search'}) {
				$ai_v{'temp'}{'search'} = 1;
				last;
			}
		}
		if ($ai_v{'temp'}{'search'}) {
			undef $ai_v{'temp'}{'found'};
			foreach (@monstersID) {
				if ($mon_control{lc($monsters{$_}{'name'})}{'teleport_search'} && !$monsters{$_}{'attack_failed'}) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
			if (!$ai_v{'temp'}{'found'}) {
				# Verbose of teleport
				if ($config{'teleportAuto_verbose'}) {
					print "▲自動瞬移 - 搜尋指定怪物($timeout{'ai_teleport_search'}{'timeout'}秒)\n";
				}
				$ai_v{'temp'}{'teleOnEvent'} = 1;
				timeOutStart('ai_teleport_event');
				useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;
				timeOutStart('ai_teleport_idle');

				$ai_v{'temp'}{'tele'} = 1;

#				my $ai_index = binFind(\@ai_seq, "take");
#
#				if ($ai_index ne "" && $ai_seq_args[$ai_index]{'mode'}) {
#					sysLog("ii", "順移", "撿取物品失敗: $items{$ai_seq_args[$ai_index]{'ID'}}{'name'} ($items{$ai_seq_args[$ai_index]{'ID'}}{'binID'}) 你瞬間移動了", 1);
#				}
			}
		}
		timeOutStart('ai_teleport_search');
	}

	if ($config{'teleportAuto_idle'}) {
		if ($ai_seq[0] ne "" || $ai_v{'temp'}{'tele'} || $sc_v{'temp'}{'teleOnEvent'}) {
			timeOutStart('ai_teleport_idle');
		} elsif (
			checkTimeOut('ai_teleport_idle')
			&& $ai_v{'ai_teleport_safe'}

			&& !$ai_v{'temp'}{'inTake'}
			&& $ai_v{'temp'}{'inLockMap'}
			&& binFind(\@ai_seq, "follow") eq ""
			&& binFind(\@ai_seq, "skill_use") eq ""
		) {
			if ($config{'teleportAuto_verbose'}) {
			print "▲自動瞬移 - 發呆超過時間($timeout{'ai_teleport_idle'}{'timeout'}秒)\n";
			}
			$ai_v{'temp'}{'teleOnEvent'} = 1;
			timeOutStart('ai_teleport_event');
			useTeleport(1);
			$ai_v{'clear_aiQueue'} = 1;
			timeOutStart('ai_teleport_idle');

			$ai_v{'temp'}{'tele'} = 1;
		}
	}

#	if ($config{'teleportAuto_idle'} && $ai_seq[0] ne "") {
#		timeOutStart('ai_teleport_idle');
#	}
#
#	if (
#		$config{'teleportAuto_idle'}
#		&& !$ai_v{'temp'}{'tele'}
#		&& checkTimeOut('ai_teleport_idle')
#		&& $ai_seq[0] ne "clientSuspend"
#		&& $ai_v{'ai_teleport_safe'}
#		&& !$sc_v{'temp'}{'teleOnEvent'}
#		&& !$ai_v{'temp'}{'inTake'}
#		# Teleport in lockMap only
#		&& (
##			$ai_v{'map_name_lu'} eq $config{'lockMap'}.'.rsw'
##			|| $config{'lockMap'} eq ""
#			$ai_v{'temp'}{'inLockMap'}
#		)
#		&& binFind(\@ai_seq, "follow") eq ""
#		&& binFind(\@ai_seq, "skill_use") eq ""
#	) {
#		# Verbose of teleport
#		if ($config{'teleportAuto_verbose'}) {
#			print "▲自動瞬移 - 發呆超過時間($timeout{'ai_teleport_idle'}{'timeout'}秒)\n";
#		}
#		$ai_v{'temp'}{'teleOnEvent'} = 1;
#		timeOutStart('ai_teleport_event');
#		useTeleport(1);
#		$ai_v{'clear_aiQueue'} = 1;
#		timeOutStart('ai_teleport_idle');
#
#		$ai_v{'temp'}{'tele'} = 1;
#
##		my $ai_index = binFind(\@ai_seq, "take");
##
##		if ($ai_index ne "" && $ai_seq_args[$ai_index]{'mode'}) {
##			sysLog("ii", "順移", "撿取物品失敗: $items{$ai_seq_args[$ai_index]{'ID'}}{'name'} ($items{$ai_seq_args[$ai_index]{'ID'}}{'binID'}) 你瞬間移動了", 1);
##		}
#	}

	if (
		$config{'teleportAuto_portal'}
		&& !$ai_v{'temp'}{'tele'}
		&& checkTimeOut('ai_teleport_portal')
		&& $ai_v{'ai_teleport_safe'}
		&& !$sc_v{'temp'}{'teleOnEvent'}
		&& binFind(\@ai_seq, "talkAuto") eq ""
		&& binFind(\@ai_seq, "storageAuto") eq ""
		&& binFind(\@ai_seq, "sellAuto") eq ""
		&& binFind(\@ai_seq, "buyAuto") eq ""
		&& binFind(\@ai_seq, "follow") eq ""
		# Teleport in lockMap only
#		&& ($ai_v{'map_name_lu'} eq $config{'lockMap'}.'.rsw' || $config{'lockMap'} eq "")
		&& $ai_v{'temp'}{'inLockMap'}
	) {
		if (binSize(\@portalsID)) {
			# Verbose of teleport
			if ($config{'teleportAuto_verbose'}) {
				print "▲自動瞬移 - 迴避傳送點\n";
			}
			$ai_v{'temp'}{'teleOnEvent'} = 1;
			timeOutStart('ai_teleport_event');
			useTeleport(1);
			$ai_v{'clear_aiQueue'} = 1;

			$ai_v{'temp'}{'tele'} = 1;
		}
		timeOutStart('ai_teleport_portal');
	}
#Karasu Start
	# Avoid ground effect skills
	if ($config{'teleportAuto_spell'} && !$ai_v{'temp'}{'tele'} && checkTimeOut('ai_teleport_spell')) {
		$i = 0;

		my ($sourceDisplay, $castBy);

		while (1) {
			last if (!$config{"teleportAuto_spell_$i"} || $ai_v{'temp'}{'teleOnEvent'});
			foreach (@spellsID) {
#				undef $sourceDisplay;
				undef $targetDisplay;
				undef $s_cDist;
#				undef $castBy;
#				if (%{$monsters{$spells{$_}{'sourceID'}}}) {
#					$sourceDisplay = "$monsters{$spells{$_}{'sourceID'}}{'name'} ($monsters{$spells{$_}{'sourceID'}}{'binID'}) ";
#					$castBy = 2;
#				} elsif (%{$players{$spells{$_}{'sourceID'}}}) {
#					$sourceDisplay = "$players{$spells{$_}{'sourceID'}}{'name'} ($players{$spells{$_}{'sourceID'}}{'binID'}) ";
#					$castBy = 4;
#				} elsif ($spells{$_}{'sourceID'} eq $accountID) {
#					$sourceDisplay = "你";
#					$castBy = 1;
#				} else {
#					$sourceDisplay = "不明人物 ";
#					$castBy = 8;
#				}

				($sourceDisplay, $castBy) = ai_getCaseID($spells{$_}{'sourceID'});

				$targetDisplay = ($messages_lut{'011F'}{$spells{$_}{'type'}} ne "")
					? $messages_lut{'011F'}{$spells{$_}{'type'}}
					: "不明型態 ".$spells{$_}{'type'};

				$s_cDist = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$spells{$_}{'pos'}}));

				if (
					existsInList($config{"teleportAuto_spell_$i"}, $targetDisplay)
					&& existsInList2($config{"teleportAuto_spell_$i"."_castBy"}, $castBy, "and")
					&& (
						!$config{"teleportAuto_spell_$i"."_dist"}
						|| $s_cDist < $config{"teleportAuto_spell_$i"."_dist"}
					)
					&& (
						$config{"teleportAuto_spell_$i"."_inCity"}
						|| !$cities_lut{$field{'name'}.'.rsw'}
					)
				) {
					if ($config{"teleportAuto_spell_$i"."_randomWalk"} ne "") {
						undef @array;
						splitUseArray(\@array, $config{"teleportAuto_spell_$i"."_randomWalk"}, ",");
						do {
							$ai_v{'temp'}{'randX'} = $chars[$config{'char'}]{'pos_to'}{'x'} + int(rand() * ($array[1] * 2 + 1)) - $array[1];
							$ai_v{'temp'}{'randY'} = $chars[$config{'char'}]{'pos_to'}{'y'} + int(rand() * ($array[1] * 2 + 1)) - $array[1];
						} while (ai_route_getOffset(\%field, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
									|| $ai_v{'temp'}{'randX'} == $chars[$config{'char'}]{'pos_to'}{'x'} && $ai_v{'temp'}{'randY'} == $chars[$config{'char'}]{'pos_to'}{'y'}
									|| $ai_v{'temp'}{'randX'} == $spells{$_}{'pos'}{'x'} && $ai_v{'temp'}{'randY'} == $spells{$_}{'pos'}{'y'}
									|| abs($ai_v{'temp'}{'randX'} - $chars[$config{'char'}]{'pos_to'}{'x'}) < $array[0] && abs($ai_v{'temp'}{'randY'} - $chars[$config{'char'}]{'pos_to'}{'y'}) < $array[0]);

						printC(
							"◆存在技能: $sourceDisplay施放的 $targetDisplay 距離你只剩 $s_cDist格！\n"
							."◆啟動 teleportAuto_spell - 隨機移動！\n"
							, "tele"
						);
						sysLog("tele", "迴避", "存在技能: $sourceDisplay施放的 $targetDisplay 距離你只剩 $s_cDist格, 隨機移動！");

						move($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'});

						last;
					} else {
						$ai_v{'temp'}{'teleOnEvent'} = 1;
						timeOutStart('ai_teleport_event');
						$tele_val = useTeleport(1);
						$ai_v{'clear_aiQueue'} = 1;

						printC(
							"◆存在技能: $sourceDisplay施放的 $targetDisplay 距離你只剩 $s_cDist格！\n"
							."◆啟動 teleportAuto_spell - 瞬間移動！\n"
							, "tele"
						);
						sysLog("tele", "迴避", "存在技能: $sourceDisplay施放的 $targetDisplay 距離你只剩 $s_cDist格, 瞬間移動！");

						$ai_v{'temp'}{'tele'} = 1;

						last;
					}
				}
			}
			$i++;
		}
		timeOutStart('ai_teleport_spell');
	}

#	if (
#		$config{'teleportAuto_searchPlayer'}
#		&& checkTimeOut('ai_teleport_searchPlaysr')
#
#		&& $ai_seq[0] eq ""
#
#		&& $ai_v{'ai_teleport_safe'}
#		&& !$sc_v{'temp'}{'teleOnEvent'}
#		&& !$ai_v{'temp'}{'teleOnEvent'}
#		&& !$ai_v{'temp'}{'inDoor'}
#		&& !$ai_v{'temp'}{'inCity'}
#		&& $ai_v{'temp'}{'inLockMap'}
##		&& !$ai_v{'temp'}{'inTake'}
##		&& !$ai_v{'temp'}{'inAttack'}
#
##		&& binFind(\@ai_seq, "talkAuto") eq ""
##		&& binFind(\@ai_seq, "storageAuto") eq ""
##		&& binFind(\@ai_seq, "sellAuto") eq ""
##		&& binFind(\@ai_seq, "buyAuto") eq ""
##		&& binFind(\@ai_seq, "follow") eq ""
##		&& binFind(\@ai_seq, "skill_use") eq ""
#
##		&& binSize(\@playersID)
#	) {
#
#	}

# Auto-teleport search portal (13Feb05 update)

	if (
		$config{'teleportAuto_search_portal'} > 0
		&& $ai_v{'ai_teleport_safe'}
		&& $ai_seq_args[0]{'mapIndex'} >= 0
		&& $map_control{lc($field{'name'})}{'teleport_allow'} == 1
		&& !(
			$ai_seq[0] eq "route_getMapRoute"
			|| $ai_seq[0] eq "storageAuto"
			|| $ai_seq[0] eq "route_getRoute"
			|| $ai_seq[0] eq "follow"
			|| $ai_seq[0] eq "sitAuto"
#			|| $ai_seq[0] eq "take"
#			|| $ai_seq[0] eq "items_gather"
#			|| $ai_seq[0] eq "items_take"
#			|| $ai_seq[0] eq "attack"
		)
		&& !(
			$ai_v{'temp'}{'inTake'}
			|| $ai_v{'temp'}{'inAttack'}
#			|| $ai_v{'temp'}{'inCity'}
			|| $ai_v{'temp'}{'inDoor'}
			|| $ai_v{'temp'}{'inLockMap'}
		)
#		&& ($config{'teleportAuto_search_portal_inCity'} || !$ai_v{'temp'}{'inCity'})
#		&& !$cities_lut{$field{'name'}.'.rsw'}
#		&& $field{'name'} ne $chars[$config{'char'}]{'lockMap'}
#		&& timeOut(\%{$timeout{'ai_teleport_search_portal'}})
		&& checkTimeOut('ai_teleport_search_portal')
	) {
#		my $tdist = @{$ai_seq_args[0]{'solution'}};

		if (
			$config{'preferRoute_teleport'}
			&& $preferRoute[$ai_v{'temp'}{'index'}]{'upLeft'}{'x'} ne ""
			&& $preferRoute[$ai_v{'temp'}{'index'}]{'upLeft'}{'y'} ne ""
			&& $preferRoute[$ai_v{'temp'}{'index'}]{'bottomRight'}{'x'} ne ""
			&& $preferRoute[$ai_v{'temp'}{'index'}]{'bottomRight'}{'y'} ne ""
		) {
			timeOutStart(1, 'ai_teleport_search_portal');
		} elsif (
			$field{'name'} eq $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'map'}
		) {
			$ai_v{'temp'}{'distance'} = distance(\%{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});

			if ($ai_v{'temp'}{'distance'} > $config{'teleportAuto_search_portal'}) {
				print "Walk Distance from portal is $tdist\n";
				print "Trying to Teleport nearer to Portal\n";
				$ai_v{'temp'}{'tele'} = 1;
				useTeleport(1);
#				$timeout{'ai_teleport_search_portal'}{'time'} = time;
				timeOutStart('ai_teleport_search_portal');

				ai_clientSuspend(0, $timeout{'ai_teleport_search_portal'}{'timeout'});
			}
		}
	}

	if (
		$config{'teleportAuto_dmgFromYou'} > 0
		&& !$ai_v{'temp'}{'tele'}
		&& checkTimeOut('ai_teleport_dmgFromYou')
		&& $ai_v{'ai_teleport_safe'}
		&& !$sc_v{'temp'}{'teleOnEvent'}
		# Teleport in lockMap only
#		&& ($ai_v{'map_name_lu'} eq $config{'lockMap'}.'.rsw' || $config{'lockMap'} eq "")
		&& $ai_v{'temp'}{'inLockMap'}
		&& !$ai_v{'temp'}{'inTake'}
		&& ai_getAggressivesEx(1) >= $config{'teleportAuto_dmgFromYou'}
	) {
		printVerbose($config{'teleportAuto_verbose'}, "▲自動瞬移 - 你對 $config{'teleportAuto_dmgFromYou'} 隻以上怪物造成傷害\n", "tele");
		$ai_v{'temp'}{'teleOnEvent'} = 1;
		timeOutStart('ai_teleport_event');
		useTeleport(1);
		$ai_v{'clear_aiQueue'} = 1;

		$ai_v{'temp'}{'tele'} = 1;
		timeOutStart('ai_teleport_dmgFromYou');
	}

	if (
		$config{'teleportAuto_player'}
		&& !$ai_v{'temp'}{'tele'}
		&& checkTimeOut('ai_teleport_player')
		&& $ai_v{'ai_teleport_safe'}
		&& !$sc_v{'temp'}{'teleOnEvent'}
		&& binFind(\@ai_seq, "talkAuto") eq ""
		&& binFind(\@ai_seq, "storageAuto") eq ""
		&& binFind(\@ai_seq, "sellAuto") eq ""
		&& binFind(\@ai_seq, "buyAuto") eq ""
		&& binFind(\@ai_seq, "follow") eq ""
	) {
		if (binSize(\@playersID)) {
			# Verbose of teleport
			printVerbose($config{'teleportAuto_verbose'}, "▲自動瞬移 - 迴避玩家\n", "tele");
			$ai_v{'temp'}{'teleOnEvent'} = 1;
			timeOutStart('ai_teleport_event');
			useTeleport(1);
			$ai_v{'clear_aiQueue'} = 1;

			$ai_v{'temp'}{'tele'} = 1;
		} elsif ($config{'teleportAuto_player'} > 1 && binSize(\@npcsID)) {
			# Verbose of teleport
			printVerbose($config{'teleportAuto_verbose'}, "▲自動瞬移 - 迴避NPC\n", "tele");
			$ai_v{'temp'}{'teleOnEvent'} = 1;
			timeOutStart('ai_teleport_event');
			useTeleport(1);
			$ai_v{'clear_aiQueue'} = 1;

			$ai_v{'temp'}{'tele'} = 1;
		}
		timeOutStart('ai_teleport_player');
	}

	ai_stopByTele($ai_v{'temp'}{'tele'});

#	if ($ai_v{'temp'}{'tele'} && $ai_v{'temp'}{'inTake'}) {
#		my $ai_index = binFind(\@ai_seq, "take");
#
#		if ($ai_index ne "" && $ai_seq_args[$ai_index]{'mode'} > 0) {
#			my $targetDisplay;
#
#			if (!%{$items{$ai_seq_args[$ai_index]{'ID'}}}) {
#				$targetDisplay = "$items_old{$ai_seq_args[$ai_index]{'ID'}}{'name'} ($items_old{$ai_seq_args[$ai_index]{'ID'}}{'binID'})";
#			} else {
#				$targetDisplay = "$items{$ai_seq_args[$ai_index]{'ID'}}{'name'} ($items{$ai_seq_args[$ai_index]{'ID'}}{'binID'})";
#			}
#
#			sysLog("ii", "順移", "撿取物品失敗: $items{$ai_seq_args[$ai_index]{'ID'}}{'name'} ($items{$ai_seq_args[$ai_index]{'ID'}}{'binID'}) 原因: 你瞬間移動了", 1);
#		}
#	}

#	$sc_v{'temp'}{'teleOnEvent'} = 1 if ($tele_val && $config{'teleportAuto_autoMode'} > 0);

	return $tele_val;
}

sub ai_event_cmd {
	my %cmd = %{(shift)};

	return 0 if (!$config{'autoAdmin'} || !%cmd);


	$responseVars{'cmd_user'} = $cmd{'user'};

	if ($cmd{'user'} eq $chars[$config{'char'}]{'name'}) {
		return;
	}

	if ($cmd{'type'} eq "pm" || $cmd{'type'} eq "p" || $cmd{'type'} eq "g") {
		$ai_v{'temp'}{'qm'} = quotemeta $config{'adminPassword'};
		if ($cmd{'msg'} =~ /^$ai_v{'temp'}{'qm'}\b/) {
			if ($overallAuth{$cmd{'user'}} == 1) {
				sendMessage(\$remote_socket, "pm", getResponse("authF"), $cmd{'user'});
			} else {
				auth($cmd{'user'}, 1);
				sendMessage(\$remote_socket, "pm", getResponse("authS"), $cmd{'user'});
			}
		}
	}
	$ai_v{'temp'}{'qm'} = quotemeta $config{'callSign'};
	if ($overallAuth{$cmd{'user'}} >= 1
		&& ($cmd{'msg'} =~ /\b$ai_v{'temp'}{'qm'}\b/i || $cmd{'type'} eq "pm")) {
		if ($cmd{'msg'} =~ /\bsit\b/i) {
			if ($ai_v2{'attackAuto_old'} eq "" && $config{'attackAuto'} > 0) {
				$ai_v2{'attackAuto_old'} = $config{'attackAuto'};
				configModify("attackAuto", 1);
			}
			if ($ai_v2{'route_randomWalk_old'} eq "" && $config{'route_randomWalk'} > 0) {
				$ai_v2{'route_randomWalk_old'} = $config{'route_randomWalk'};
				configModify("route_randomWalk", 0);
			}
			aiRemove("move");
			aiRemove("route");
			aiRemove("route_getRoute");
			aiRemove("route_getMapRoute");
			sit();
			$ai_v{'sitAuto_forceStop'} = 0;
			sendMessage(\$remote_socket, $cmd{'type'}, getResponse("sitS"), $cmd{'user'}) if $config{'verbose'};
			timeOutStart('ai_thanks_set');
		} elsif ($cmd{'msg'} =~ /\bstand\b/i) {
			if ($ai_v2{'attackAuto_old'} ne "") {
				configModify("attackAuto", $ai_v2{'attackAuto_old'});
				undef $ai_v2{'attackAuto_old'};
			}
			if ($ai_v2{'route_randomWalk_old'} ne "") {
				configModify("route_randomWalk", $ai_v2{'route_randomWalk_old'});
				undef $ai_v2{'route_randomWalk_old'};
			}
			stand();
			$ai_v{'sitAuto_forceStop'} = 1;
			sendMessage(\$remote_socket, $cmd{'type'}, getResponse("standS"), $cmd{'user'}) if $config{'verbose'};
			timeOutStart('ai_thanks_set');
		} elsif ($cmd{'msg'} =~ /\brelog\b/i) {
			$sc_v{'input'}{'MinWaitRecon'} = 1;
			relogWait("", 1);
			sendMessage(\$remote_socket, $cmd{'type'}, getResponse("relogS"), $cmd{'user'}) if $config{'verbose'};
			timeOutStart('ai_thanks_set');
		} elsif ($cmd{'msg'} =~ /\blogout\b/i) {
			quit();
			sendMessage(\$remote_socket, $cmd{'type'}, getResponse("quitS"), $cmd{'user'}) if $config{'verbose'};
			timeOutStart('ai_thanks_set');
		} elsif ($cmd{'msg'} =~ /\breload\b/i) {
			parseReload($');
			sendMessage(\$remote_socket, $cmd{'type'}, getResponse("reloadS"), $cmd{'user'}) if $config{'verbose'};
			timeOutStart('ai_thanks_set');
		} elsif ($cmd{'msg'} =~ /\bstatus\b/i) {
			$responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'};
			$responseVars{'char_hp'} = $chars[$config{'char'}]{'hp'};
			$responseVars{'char_sp_max'} = $chars[$config{'char'}]{'sp_max'};
			$responseVars{'char_hp_max'} = $chars[$config{'char'}]{'hp_max'};
			$responseVars{'char_lv'} = $chars[$config{'char'}]{'lv'};
			$responseVars{'char_lv_job'} = $chars[$config{'char'}]{'lv_job'};
			$responseVars{'char_exp'} = $chars[$config{'char'}]{'exp'};
			$responseVars{'char_exp_max'} = $chars[$config{'char'}]{'exp_max'};
			$responseVars{'char_exp_job'} = $chars[$config{'char'}]{'exp_job'};
			$responseVars{'char_exp_job_max'} = $chars[$config{'char'}]{'exp_job_max'};
			$responseVars{'char_weight'} = $chars[$config{'char'}]{'weight'};
			$responseVars{'char_weight_max'} = $chars[$config{'char'}]{'weight_max'};
			$responseVars{'zenny'} = $chars[$config{'char'}]{'zenny'};
			sendMessage(\$remote_socket, $cmd{'type'}, getResponse("statusS"), $cmd{'user'}) if $config{'verbose'};
			timeOutStart('ai_thanks_set');
		} elsif ($cmd{'msg'} =~ /\bconf\b/i) {
			$ai_v{'temp'}{'after'} = $';
			($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}) = $ai_v{'temp'}{'after'} =~ /(\w+) (\w+)/;
			@{$ai_v{'temp'}{'conf'}} = keys %config;
			if ($ai_v{'temp'}{'arg1'} eq "") {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confF1"), $cmd{'user'}) if $config{'verbose'};
			} elsif (binFind(\@{$ai_v{'temp'}{'conf'}}, $ai_v{'temp'}{'arg1'}) eq "") {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confF2"), $cmd{'user'}) if $config{'verbose'};
			} elsif ($ai_v{'temp'}{'arg2'} eq "value" || valBolck($ai_v{'temp'}{'arg1'})) {
				if ($ai_v{'temp'}{'arg1'} =~ /username/i || $ai_v{'temp'}{'arg1'} =~ /password/i) {
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confF3"), $cmd{'user'}) if $config{'verbose'};
				} else {
					$responseVars{'key'} = $ai_v{'temp'}{'arg1'};
					$responseVars{'value'} = $config{$ai_v{'temp'}{'arg1'}};
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confS1"), $cmd{'user'}) if $config{'verbose'};
					timeOutStart('ai_thanks_set');
				}
			} else {
#				configModify($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'});
				scModify("config", $ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}, 2, 1);
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("confS2"), $cmd{'user'}) if $config{'verbose'};
				timeOutStart('ai_thanks_set');
			}
		} elsif ($cmd{'msg'} =~ /\btimeout\b/i) {
			$ai_v{'temp'}{'after'} = $';
			($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}) = $ai_v{'temp'}{'after'} =~ /([\s\S]+) (\w+)/;
			if ($ai_v{'temp'}{'arg1'} eq "") {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutF1"), $cmd{'user'}) if $config{'verbose'};
			} elsif ($timeout{$ai_v{'temp'}{'arg1'}} eq "") {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutF2"), $cmd{'user'}) if $config{'verbose'};
			} elsif ($ai_v{'temp'}{'arg2'} eq "" || valBolck($ai_v{'temp'}{'arg1'})) {
				$responseVars{'key'} = $ai_v{'temp'}{'arg1'};
				$responseVars{'value'} = $timeout{$ai_v{'temp'}{'arg1'}};
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutS1"), $cmd{'user'}) if $config{'verbose'};
				timeOutStart('ai_thanks_set');
			} else {
#				setTimeout($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'});
				scModify("timeout", $ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}, 2, 1);
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("timeoutS2"), $cmd{'user'}) if $config{'verbose'};
				timeOutStart('ai_thanks_set');
			}
		} elsif ($cmd{'msg'} =~ /\bshut[\s\S]*up\b/i) {
			if ($config{'verbose'}) {
				configModify("verbose", 0);
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOffS"), $cmd{'user'});
				timeOutStart('ai_thanks_set');
			} else {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOffF"), $cmd{'user'});
			}
		} elsif ($cmd{'msg'} =~ /\bspeak\b/i) {
			if (!$config{'verbose'}) {
				configModify("verbose", 1);
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOnS"), $cmd{'user'});
				timeOutStart('ai_thanks_set');
			} else {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOnF"), $cmd{'user'});
			}
		} elsif ($cmd{'msg'} =~ /\bdate\b/i) {
			$responseVars{'date'} = getFormattedDate(int(time));
			sendMessage(\$remote_socket, $cmd{'type'}, getResponse("dateS"), $cmd{'user'}) if $config{'verbose'};
			timeOutStart('ai_thanks_set');
		} elsif ($cmd{'msg'} =~ /\bmove\b/i
			&& $cmd{'msg'} =~ /\bstop\b/i) {
			aiRemove("move");
			aiRemove("route");
			aiRemove("route_getRoute");
			aiRemove("route_getMapRoute");
			sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
			timeOutStart('ai_thanks_set');
		} elsif ($cmd{'msg'} =~ /\bmove\b/i) {
			$ai_v{'temp'}{'after'} = $';
			$ai_v{'temp'}{'after'} =~ s/^\s+//;
			$ai_v{'temp'}{'after'} =~ s/\s+$//;
			($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'}, $ai_v{'temp'}{'arg3'}) = $ai_v{'temp'}{'after'} =~ /(\d+)\D+(\d+)(.*?)$/;
			undef $ai_v{'temp'}{'map'};
			if ($ai_v{'temp'}{'arg1'} eq "") {
				($ai_v{'temp'}{'map'}) = $ai_v{'temp'}{'after'} =~ /(.*?)$/;
			} else {
				$ai_v{'temp'}{'map'} = $ai_v{'temp'}{'arg3'};
			}
			$ai_v{'temp'}{'map'} =~ s/\s//g;
			if (($ai_v{'temp'}{'arg1'} eq "" || $ai_v{'temp'}{'arg2'} eq "") && !$ai_v{'temp'}{'map'}) {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveF"), $cmd{'user'}) if $config{'verbose'};
			} else {
				$ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
				if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
					if ($ai_v{'temp'}{'arg2'} ne "") {
						print "計算路徑前往指定地點 - $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): ".getFormattedCoords($ai_v{'temp'}{'arg1'}, $ai_v{'temp'}{'arg2'})."\n";
						$ai_v{'temp'}{'x'} = $ai_v{'temp'}{'arg1'};
						$ai_v{'temp'}{'y'} = $ai_v{'temp'}{'arg2'};
					} else {
						print "計算路徑前往指定地圖 - $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n";
						undef $ai_v{'temp'}{'x'};
						undef $ai_v{'temp'}{'y'};
					}
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
					timeOutStart('ai_thanks_set');
				} else {
					print "指定地圖設定錯誤 - $sc_v{'path'}{'tables'}/maps.txt中找不到 $ai_v{'temp'}{'map'}.rsw\n";
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveF"), $cmd{'user'}) if $config{'verbose'};
				}
			}
		} elsif ($cmd{'msg'} =~ /\blook\b/i) {
			($ai_v{'temp'}{'body'}) = $cmd{'msg'} =~ /(\d+)/;
			($ai_v{'temp'}{'head'}) = $cmd{'msg'} =~ /\d+ (\d+)/;
			if ($ai_v{'temp'}{'body'} ne "") {
				look($ai_v{'temp'}{'body'}, $ai_v{'temp'}{'head'});
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("lookS"), $cmd{'user'}) if $config{'verbose'};
				timeOutStart('ai_thanks_set');
			} else {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("lookF"), $cmd{'user'}) if $config{'verbose'};
			}

		} elsif ($cmd{'msg'} =~ /\bfollow/i
			&& $cmd{'msg'} =~ /\bstop\b/i) {
			if ($config{'follow'}) {
				aiRemove("follow");
				configModify("follow", 0);
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followStopS"), $cmd{'user'}) if $config{'verbose'};
				timeOutStart('ai_thanks_set');
			} else {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followStopF"), $cmd{'user'}) if $config{'verbose'};
			}
		} elsif ($cmd{'msg'} =~ /\bfollow\b/i) {
			$ai_v{'temp'}{'after'} = $';
			$ai_v{'temp'}{'after'} =~ s/^\s+//;
			$ai_v{'temp'}{'after'} =~ s/\s+$//;
			$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
			if ($ai_v{'temp'}{'targetID'} ne "") {
				aiRemove("follow");
				ai_follow($players{$ai_v{'temp'}{'targetID'}}{'name'});
				configModify("follow", 1);
				configModify("followTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'});
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followS"), $cmd{'user'}) if $config{'verbose'};
				timeOutStart('ai_thanks_set');
			} else {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("followF"), $cmd{'user'}) if $config{'verbose'};
			}
		} elsif ($cmd{'msg'} =~ /\btank/i
			&& $cmd{'msg'} =~ /\bstop\b/i) {
			if (!$config{'tankMode'}) {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankStopF"), $cmd{'user'}) if $config{'verbose'};
			} elsif ($config{'tankMode'}) {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankStopS"), $cmd{'user'}) if $config{'verbose'};
				configModify("tankMode", 0);
				timeOutStart('ai_thanks_set');
			}
		} elsif ($cmd{'msg'} =~ /\btank/i) {
			$ai_v{'temp'}{'after'} = $';
			$ai_v{'temp'}{'after'} =~ s/^\s+//;
			$ai_v{'temp'}{'after'} =~ s/\s+$//;
			$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
			if ($ai_v{'temp'}{'targetID'} ne "") {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankS"), $cmd{'user'}) if $config{'verbose'};
				configModify("tankMode", 1);
				configModify("tankModeTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'});
				timeOutStart('ai_thanks_set');
			} else {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankF"), $cmd{'user'}) if $config{'verbose'};
			}
		} elsif ($cmd{'msg'} =~ /\btown/i) {
			sendMessage(\$remote_socket, $cmd{'type'}, getResponse("moveS"), $cmd{'user'}) if $config{'verbose'};
			useTeleport(2);
			timeOutStart('ai_thanks_set');

		} elsif ($cmd{'msg'} =~ /\bwhere\b/i) {
			$responseVars{'x'} = $chars[$config{'char'}]{'pos_to'}{'x'};
			$responseVars{'y'} = $chars[$config{'char'}]{'pos_to'}{'y'};
			$responseVars{'map'} = qq~$maps_lut{$field{'name'}.'.rsw'} ($field{'name'})~;
			timeOutStart('ai_thanks_set');
			sendMessage(\$remote_socket, $cmd{'type'}, getResponse("whereS"), $cmd{'user'}) if $config{'verbose'};
		}

	}
	$ai_v{'temp'}{'qm'} = quotemeta $config{'callSign'};
	if ($overallAuth{$cmd{'user'}} >= 1 && ($cmd{'msg'} =~ /\b$ai_v{'temp'}{'qm'}\b/i || $cmd{'type'} eq "pm")
		&& $cmd{'msg'} =~ /\bheal\b/i) {
		$ai_v{'temp'}{'after'} = $';
		($ai_v{'temp'}{'amount'}) = $ai_v{'temp'}{'after'} =~ /(\d+)/;
		$ai_v{'temp'}{'after'} =~ s/\d+//;
		$ai_v{'temp'}{'after'} =~ s/^\s+//;
		$ai_v{'temp'}{'after'} =~ s/\s+$//;
		$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
		if ($ai_v{'temp'}{'targetID'} eq "") {
			sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healF1"), $cmd{'user'}) if $config{'verbose'};
		} elsif ($chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} > 0) {
			undef $ai_v{'temp'}{'amount_healed'};
			undef $ai_v{'temp'}{'sp_needed'};
			undef $ai_v{'temp'}{'sp_used'};
			undef $ai_v{'temp'}{'failed'};
			undef @{$ai_v{'temp'}{'skillCasts'}};
			while ($ai_v{'temp'}{'amount_healed'} < $ai_v{'temp'}{'amount'}) {
				for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
					$ai_v{'temp'}{'sp'} = 10 + ($i * 3);
					$ai_v{'temp'}{'amount_this'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
							* (4 + $i * 8);
					last if ($ai_v{'temp'}{'amount_healed'} + $ai_v{'temp'}{'amount_this'} >= $ai_v{'temp'}{'amount'});
				}
				$ai_v{'temp'}{'sp_needed'} += $ai_v{'temp'}{'sp'};
				$ai_v{'temp'}{'amount_healed'} += $ai_v{'temp'}{'amount_this'};
			}
			while ($ai_v{'temp'}{'sp_used'} < $ai_v{'temp'}{'sp_needed'} && !$ai_v{'temp'}{'failed'}) {
				for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
					$ai_v{'temp'}{'lv'} = $i;
					$ai_v{'temp'}{'sp'} = 10 + ($i * 3);
					if ($ai_v{'temp'}{'sp_used'} + $ai_v{'temp'}{'sp'} > $chars[$config{'char'}]{'sp'}) {
						$ai_v{'temp'}{'lv'}--;
						$ai_v{'temp'}{'sp'} = 10 + ($ai_v{'temp'}{'lv'} * 3);
						last;
					}
					last if ($ai_v{'temp'}{'sp_used'} + $ai_v{'temp'}{'sp'} >= $ai_v{'temp'}{'sp_needed'});
				}
				if ($ai_v{'temp'}{'lv'} > 0) {
					$ai_v{'temp'}{'sp_used'} += $ai_v{'temp'}{'sp'};
					$ai_v{'temp'}{'skillCast'}{'skill'} = 28;
					$ai_v{'temp'}{'skillCast'}{'lv'} = $ai_v{'temp'}{'lv'};
					$ai_v{'temp'}{'skillCast'}{'maxCastTime'} = 0;
					$ai_v{'temp'}{'skillCast'}{'minCastTime'} = 0;
					$ai_v{'temp'}{'skillCast'}{'ID'} = $ai_v{'temp'}{'targetID'};
					unshift @{$ai_v{'temp'}{'skillCasts'}}, {%{$ai_v{'temp'}{'skillCast'}}};
				} else {
					$responseVars{'char_sp'} = $chars[$config{'char'}]{'sp'} - $ai_v{'temp'}{'sp_used'};
					sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healF2"), $cmd{'user'}) if $config{'verbose'};
					$ai_v{'temp'}{'failed'} = 1;
				}
			}
			if (!$ai_v{'temp'}{'failed'}) {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healS"), $cmd{'user'}) if $config{'verbose'};
				timeOutStart('ai_thanks_set');
			}
			foreach (@{$ai_v{'temp'}{'skillCasts'}}) {
				ai_skillUse($$_{'skill'}, $$_{'lv'}, $$_{'maxCastTime'}, $$_{'minCastTime'}, $$_{'ID'});
			}
		} else {
			sendMessage(\$remote_socket, $cmd{'type'}, getResponse("healF3"), $cmd{'user'}) if $config{'verbose'};
		}
	}

	if ($overallAuth{$cmd{'user'}} >= 1) {
		if ($cmd{'msg'} =~ /\bthank/i || $cmd{'msg'} =~ /\bthn/i) {
			if (!checkTimeOut('ai_thanks_set')) {
				$timeout{'ai_thanks_set'}{'time'} -= $timeout{'ai_thanks_set'}{'timeout'};
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("thankS"), $cmd{'user'}) if $config{'verbose'};
			}
		}
	}

}

sub ai_event_auto_request {

#	if ($ai_seq[0] ne "deal" && %currentDeal) {
#		unshift @ai_seq, "deal";
#		unshift @ai_seq_args, "";
#	} elsif ($ai_seq[0] eq "deal" && %currentDeal && !$currentDeal{'you_finalize'} && checkTimeOut('ai_dealAuto') && $config{'dealAuto'}==2) {
#		sendDealFinalize(\$remote_socket);
#		timeOutStart('ai_dealAuto');
#	} elsif ($ai_seq[0] eq "deal" && %currentDeal && $currentDeal{'other_finalize'} && $currentDeal{'you_finalize'} &&checkTimeOut('ai_dealAuto') && $config{'dealAuto'}==2) {
#		sendDealTrade(\$remote_socket);
#		timeOutStart('ai_dealAuto');
#	} elsif ($ai_seq[0] eq "deal" && !%currentDeal) {
#		shift @ai_seq;
#		shift @ai_seq_args;
#
#		timeOutStart(1, 'ai_dealAuto');
#	}

	if ($ai_seq[0] ne "deal" && %currentDeal && checkTimeOut('ai_dealAuto')) {
		unshift @ai_seq, "deal";
		unshift @ai_seq_args, "";

		timeOutStart('ai_dealAuto');
	} elsif ($ai_seq[0] eq "deal") {
		if (%currentDeal && checkTimeOut('ai_dealAuto') && $config{'dealAuto'}==2) {
			if (!$currentDeal{'you_finalize'}) {
				sendDealFinalize(\$remote_socket);
				timeOutStart('ai_dealAuto');
			} elsif ($currentDeal{'other_finalize'} && $currentDeal{'you_finalize'}) {
				sendDealTrade(\$remote_socket);
				timeOutStart('ai_dealAuto');
			}
		} elsif (!%currentDeal) {
			shift @ai_seq;
			shift @ai_seq_args;

			timeOutStart(1, 'ai_dealAuto');
		}
	}

	#dealAuto 1=refuse 2=accept
	if ($config{'dealAuto'} && %incomingDeal && checkTimeOut('ai_dealAuto')) {
		if ($config{'dealAuto'}==1) {
			sendDealCancel(\$remote_socket);
			undef %incomingDeal;
		}elsif ($config{'dealAuto'}==2) {
			sendDealAccept(\$remote_socket);
		}
		timeOutStart('ai_dealAuto');
	}

	if ($config{'partyAuto'} && %incomingParty && checkTimeOut('ai_partyAuto')) {
		sendPartyJoin(\$remote_socket, $incomingParty{'ID'}, (abs($config{'partyAuto'} - 1)?1:0));
		timeOutStart(1, 'ai_partyAuto');
		undef %incomingParty;
	}

#Karasu Start
	# guild request auto deny
	if ($config{'guildAuto'} && %incomingGuild && checkTimeOut('ai_guildAuto')) {
		sendGuildJoin(\$remote_socket, $incomingGuild{'ID'}, (abs($config{'guildAuto'} - 1)?1:0));
		timeOutStart(1, 'ai_guildAuto');
		undef %incomingGuild;
	}
#Karasu End

	if (
		$config{'preferRoute_warp'}
		&& $warp{'use'} != 26
		&& $ai_seq[0] eq ""
		&& (!@{$record{'warp'}{'memo'}} || $record{'warp'}{'use'} != 27)
		&& !$sc_v{'temp'}{'teleOnEvent'}
		&& !$sc_v{'ai'}{'onHit'}
		&& checkTimeOut('ai_warpTo_wait')
	) {
		if (
			$chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'} > 1
			&& $chars[$config{'char'}]{'sp'} < $skillsSP_lut{$chars[$config{'char'}]{'skills'}{'AL_WARP'}{'ID'}}{$chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'}}
		) {
			print "啟動 preferRoute_warp 施展傳送之陣取得傳送資料失敗 原因: SP不足\n";
			timeOutStart('ai_warpTo_wait');
		} elsif ($chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'} > 1) {
#			sendSkillUse(\$remote_socket, $chars[$config{'char'}]{'skills'}{'AL_WARP'}{'ID'}, $chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'}, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'} - 5);

#			my $wx = $chars[$config{'char'}]{'pos_to'}{'x'} - 5;
#			my $wy = $chars[$config{'char'}]{'pos_to'}{'y'} - 5;

#			parseInput("warp at $wx $wy");

			print "啟動 preferRoute_warp 施展傳送之陣取得傳送資料\n";

			parseInput("warp me");

			timeOutStart('ai_warpTo_wait');

		} else {
			scModify('config', 'preferRoute_warp', 0, 1);
		}
	}

	# Party auto share
	if ($config{'partyAutoShare'} && %{$chars[$config{'char'}]{'party'}} && checkTimeOut('ai_partyAutoShare') && !$sc_v{'temp'}{'teleOnEvent'}) {
		sendPartyShareEXP(\$remote_socket, 1);
		timeOutStart('ai_partyAutoShare');
	}

	if (
		$config{'partyAutoCreate'}
		&& $ai_seq[0] eq ""
		&& !$sc_v{'temp'}{'teleOnEvent'}
		&& checkTimeOut('ai_partyAutoCreate')
		&& !(($sc_v{'input'}{'conState'} == 2 || $sc_v{'input'}{'conState'} == 3) && $sc_v{'input'}{'waitingForInput'})
	) {
		timeOutStart('ai_partyAutoCreate');

		if (!%{$chars[$config{'char'}]{'party'}}) {
			sysLog("event", "隊伍", "你沒有隊伍，自動建立隊伍。", 1);
			parseInput("party create");
#			timeOutStart('ai_partyAutoCreate');
#			sleep(0.1);
			timeOutStart(-1, 'ai_partyAutoShare');
		}
	}

	##### Q' pet ####
	if ($config{'petAuto_play'} && %{$chars[$config{'char'}]{'pet'}} && checkTimeOut('ai_petAuto_play') && !$sc_v{'temp'}{'teleOnEvent'}){
		sendPetCommand(\$remote_socket, 2);
		timeOutStart('ai_petAuto_play');
		print "Auto Play pet\n";
	}

#	if ($config{'dcOnDualLogin_protect'} && $sc_v{'parseMsg'}{'dcOnDualLogin'} > 1) {
#		useTeleport(1);
#		undef $sc_v{'parseMsg'}{'dcOnDualLogin'};
#	}
}

sub ai_event_autoCart {
	#Karasu Start
	##### AUTO CART-GET #####

	if ($config{'cartAuto'} && $cart{'weight_max'} && checkTimeOut('ai_cartAuto')) {
		$i = 0;
		while (1) {
			last if (!$config{"cartgetAuto_$i"});
			undef $ai_v{'temp'}{'invIndex'};
			$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"cartgetAuto_$i"});
			if ($config{"cartgetAuto_$i"."_minAmount"} ne "" && $config{"cartgetAuto_$i"."_maxAmount"} ne ""
				&& ($ai_v{'temp'}{'invIndex'} eq ""
				|| ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"cartgetAuto_$i"."_minAmount"}
				&& $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"cartgetAuto_$i"."_maxAmount"}))) {
				undef $ai_v{'temp'}{'cartInvIndex'};
				$ai_v{'temp'}{'cartInvIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $config{"cartgetAuto_$i"});
				if ($ai_v{'temp'}{'cartInvIndex'} ne "") {
					$cartgetAmount = ($ai_v{'temp'}{'invIndex'} ne "")
						? $config{"cartgetAuto_$i"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'}
						: $config{"cartgetAuto_$i"."_maxAmount"};
					if ($cartgetAmount > $cart{'inventory'}[$ai_v{'temp'}{'cartInvIndex'}]{'amount'}) {
						$cartgetAmount = $cart{'inventory'}[$ai_v{'temp'}{'cartInvIndex'}]{'amount'};
					}
					sendCartGet(\$remote_socket, $ai_v{'temp'}{'cartInvIndex'}, $cartgetAmount);
				}
			}
			$i++;
		}
		timeOutStart('ai_cartAuto');
	}
#Karasu End
}

#sub ai_event_npc_autoTalk {
#	#Karasu Start
#	#####AUTO TALK#####
#
#	AUTOTALK: {
#
#	$ai_v{'temp'}{'inNpcMap'} = (getMapID($field{'name'}) eq getMapID($npcs_lut{$config{"talkAuto_npc"}}{'map'}));
#
#	if (
#		(switchInput($ai_seq[0], "", "route", "sitAuto") || ($ai_seq[0] eq "attack" && !$config{'talkAuto_peace'}))
#		&& $config{'talkAuto'}
#		&& $config{'talkAuto_npc'} ne ""
##		&& (
##			(
##				!$config{'talkAuto_hp'}
##				|| ($config{'talkAuto_hp'} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{'talkAuto_hp'})
##			) || (
##				!$config{'talkAuto_sp'}
##				|| ($config{'talkAuto_sp'} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{'talkAuto_sp'})
##			)
##		)
#		&& (
#			!$config{"talkAuto_inNpcMapOnly"}
#			|| (
#				$config{"talkAuto_inNpcMapOnly"}
#				&&
#				$ai_v{'temp'}{'inNpcMap'}
#			)
#		)
#		&& (
#			!$config{'talkAuto_broken'}
#			|| ($config{'talkAuto_broken'} && getBrokenItems(\@{$chars[$config{'char'}]{'inventory'}}))
#		)
#		&& ai_checkZeny($config{"talkAuto_zeny"})
#	) {
#		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
#		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
#			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
#		}
#		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)) {
#			unshift @ai_seq, "talkAuto";
#			unshift @ai_seq_args, {};
#		}
#	}
#
#	return 0 if ($ai_seq[0] ne "talkAuto");
#
#	if ($ai_seq_args[0]{'done'}) {
#		undef %{$ai_v{'temp'}{'ai'}};
#		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
#		shift @ai_seq;
#		shift @ai_seq_args;
#		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'}) {
#			$ai_v{'temp'}{'ai'}{'completedAI'}{'talkAuto'} = 1;
#			unshift @ai_seq, "sellAuto";
#			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
#			timeOutStart('ai_sellAuto');
#		}
#
#	} elsif (checkTimeOut('ai_route_npcTalk')) {
##		if (!$config{'talkAuto'} || !%{$npcs_lut{$config{'talkAuto_npc'}}}) {
##			$ai_seq_args[0]{'done'} = 1;
##			last AUTOTALK;
##		}
##
#
##		if (
##			!$config{'talkAuto'}
##			|| !$config{'talkAuto_npc'}
##			|| (
##				!$config{'talkAuto_borned'}
##				|| !($config{'talkAuto_borned'} > 0 && $config{'talkAuto_borned'} >= getBrokenItems(\@{$chars[$config{'char'}]{'inventory'}}))
##			)
##			|| !ai_checkZeny($config{"talkAuto_zeny"})
##		) {
##			$ai_seq_args[0]{'done'} = 1;
##			last AUTOTALK;
##		}
#
#		if (
#			$config{'talkAuto'}
#			&& $config{'talkAuto_npc'} ne ""
#			&& %{$npcs_lut{$config{'talkAuto_npc'}}}
#			&& (
#				!$config{"talkAuto_inNpcMapOnly"}
#				|| (
#					$config{"talkAuto_inNpcMapOnly"}
#					&&
#					$ai_v{'temp'}{'inNpcMap'}
#				)
#			)
#			&& (
#				!$config{'talkAuto_broken'}
#				|| ($config{'talkAuto_broken'} && getBrokenItems(\@{$chars[$config{'char'}]{'inventory'}}))
#			)
#			&& ai_checkZeny($config{"talkAuto_zeny"})
#		) {
#
#		} else {
#
#			$ai_seq_args[0]{'done'} = 1;
#			last AUTOTALK;
#		}
#
#		undef $ai_v{'temp'}{'do_route'};
#		if ($field{'name'} ne $npcs_lut{$config{'talkAuto_npc'}}{'map'}) {
#			$ai_v{'temp'}{'do_route'} = 1;
#		} else {
#			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'talkAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
#			if ($ai_v{'temp'}{'distance'} > 14) {
#				$ai_v{'temp'}{'do_route'} = 1;
#			}
#		}
#		if ($ai_v{'temp'}{'do_route'}) {
#			# Reset warpedToSave if not really do
#			if ($ai_seq_args[0]{'warpedToSave'} && (!$ai_seq_args[0]{'mapChanged'} || $field{'name'} ne $config{'saveMap'})) {
#				undef $ai_seq_args[0]{'warpedToSave'};
#			}
#			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
#				$ai_seq_args[0]{'warpedToSave'} = 1;
#				useTeleport(2);
#				timeOutStart('ai_route_npcTalk');
##Karasu Start
#			# Talk position change
#			} elsif ($config{'talkAuto_npc_dist'}) {
#				getField("$sc_v{'path'}{'fields'}/$npcs_lut{$config{'talkAuto_npc'}}{'map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
#				do {
#					$ai_v{'temp'}{'randX'} = $npcs_lut{$config{'talkAuto_npc'}}{'pos'}{'x'} + int(rand() * ($config{'talkAuto_npc_dist'} * 2 + 1)) - $config{'talkAuto_npc_dist'};
#					$ai_v{'temp'}{'randY'} = $npcs_lut{$config{'talkAuto_npc'}}{'pos'}{'y'} + int(rand() * ($config{'talkAuto_npc_dist'} * 2 + 1)) - $config{'talkAuto_npc_dist'};
#				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
#							|| $ai_v{'temp'}{'randX'} == $npcs_lut{$config{'talkAuto_npc'}}{'pos'}{'x'} && $ai_v{'temp'}{'randY'} == $npcs_lut{$config{'talkAuto_npc'}}{'pos'}{'y'});
#				print "計算路徑前往自動談話地點: $maps_lut{$npcs_lut{$config{'talkAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'talkAuto_npc'}}{'map'}): ".getFormattedCoords($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $npcs_lut{$config{'talkAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
##Karasu End
#			} else {
#				print "計算路徑前往自動談話地點: $maps_lut{$npcs_lut{$config{'talkAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'talkAuto_npc'}}{'map'}): ".getFormattedCoords($npcs_lut{$config{'talkAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'talkAuto_npc'}}{'pos'}{'y'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'talkAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'talkAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'talkAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
#			}
#		} else {
#			if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
#				sendTalk(\$remote_socket, pack("L1", $config{'talkAuto_npc'}));
#				@{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $config{'talkAuto_npc_steps'});
#				$ai_seq_args[0]{'npc'}{'sentTalk'} = 1;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
#				sendTalkContinue(\$remote_socket, pack("L1", $config{'talkAuto_npc'}));
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
#				#sendTalkCancel(\$remote_socket, pack("L1", $config{'talkAuto_npc'}));
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i) {
#				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i;
#				if ($ai_v{'temp'}{'arg'} ne "") {
#					sendTalkAnswerNum(\$remote_socket, pack("L1", $config{'talkAuto_npc'}), $ai_v{'temp'}{'arg'});
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i) {
#				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i;
#				if ($ai_v{'temp'}{'arg'} ne "") {
#					sendTalkAnswerWord(\$remote_socket, pack("L1", $config{'talkAuto_npc'}), $ai_v{'temp'}{'arg'});
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} else {
#				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
#				if ($ai_v{'temp'}{'arg'} ne "") {
#					$ai_v{'temp'}{'arg'}++;
#					sendTalkResponse(\$remote_socket, pack("L1", $config{'talkAuto_npc'}), $ai_v{'temp'}{'arg'});
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			}
#			$ai_seq_args[0]{'done'} = 1 if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "");
#			timeOutStart('ai_route_npcTalk');
#		}
#	}
#	} #END OF BLOCK AUTOTALK
##Karasu End
#}

sub ai_event_npc_autoTalk_data {
	my $tmp = "";
	my ($i, $mode) = @_;

	if ($config{'talkAuto'} > 1) {
		$i = int($i);

		$tmp = "_${i}";
	}

	if ($mode && $i > 0 && $config{'talkAuto'} == 1) {
		return "";
	} elsif ($mode) {
		return $config{"talkAuto${tmp}_npc"};
	} else {
		my $tdo = $sc_v{'temp'}{'ai'}{'talkAuto'}{'do'};

		undef %{$sc_v{'temp'}{'ai'}{'autoTalk'}};

		$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'}			= $tdo;
		$sc_v{'temp'}{'ai'}{'talkAuto'}{'index'}		= $i;

		$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}			= $config{"talkAuto${tmp}_npc"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'}		= $config{"talkAuto${tmp}_npc_dist"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_steps'}		= $config{"talkAuto${tmp}_npc_steps"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'hp'}			= $config{"talkAuto${tmp}_hp"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'sp'}			= $config{"talkAuto${tmp}_sp"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'peace'}		= $config{"talkAuto${tmp}_peace"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'}		= $config{"talkAuto${tmp}_broken"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'end_warpedToSave'}	= $config{"talkAuto${tmp}_end_warpedToSave"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'zeny'}			= $config{"talkAuto${tmp}_zeny"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'}		= $config{"talkAuto${tmp}_inNpcMapOnly"};

		$sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItem'}		= $config{"talkAuto${tmp}_checkItem"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItemEx'}		= $config{"talkAuto${tmp}_checkItemEx"};

		$sc_v{'temp'}{'ai'}{'autoTalk'}{'loop'}			= $config{"talkAuto${tmp}_loop"};

	}
}

sub ai_event_npc_autoTalk {
	#Karasu Start
	#####AUTO TALK#####

	my $i = 0;

	AUTOTALK: {

	if (switchInput($ai_seq[0], "", "route", "sitAuto", "attack") && $config{'talkAuto'}) {

		undef $sc_v{'temp'}{'ai'}{'talkAuto'}{'do'};

		while (!$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} && ai_event_npc_autoTalk_data($i, 1) ne "") {

#			last if (ai_event_npc_autoTalk_data($i, 1) eq "");

			ai_event_npc_autoTalk_data($i);

			$ai_v{'temp'}{'inNpcMap'} = inTargetMap($field{'name'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}, $sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'});

			if (
				(
					switchInput($ai_seq[0], "", "route", "sitAuto")
					|| (
						$ai_seq[0] eq "attack"
						&& !$sc_v{'temp'}{'ai'}{'autoTalk'}{'peace'}
					)
				)
				&& %{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}}
				&& (
					(
						!$sc_v{'temp'}{'ai'}{'autoTalk'}{'hp'}
						|| ($sc_v{'temp'}{'ai'}{'autoTalk'}{'hp'} && percent_hp(\%{$chars[$config{'char'}]}) <= $sc_v{'temp'}{'ai'}{'autoTalk'}{'hp'})
					) && (
						!$sc_v{'temp'}{'ai'}{'autoTalk'}{'sp'}
						|| ($sc_v{'temp'}{'ai'}{'autoTalk'}{'sp'} && percent_sp(\%{$chars[$config{'char'}]}) <= $sc_v{'temp'}{'ai'}{'autoTalk'}{'sp'})
					)
				)
				&& (
					!$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'}
					|| (
						$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'}
						&&
						$ai_v{'temp'}{'inNpcMap'}
					)
				)
				&& (
					!$sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'}
					|| ($sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'} && getBrokenItems(\@{$chars[$config{'char'}]{'inventory'}}) >= $sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'})
				)
				&& ai_checkZeny($sc_v{'temp'}{'ai'}{'autoTalk'}{'zeny'})
			) {
				undef $ai_v{'temp'}{'found'};

				if (!$ai_v{'temp'}{'found'} && $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItem'}) {
					undef @array;
					splitUseArray(\@array, $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItem'}, ",");
					foreach (@array) {
						next if (!$_);
						if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) eq "") {
							$ai_v{'temp'}{'found'} = 1;
							last;
						}
					}
				}

				if (!$ai_v{'temp'}{'found'} && $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItemEx'}) {
					undef @array;
					undef $ai_v{'temp'}{'foundEx'};
					splitUseArray(\@array, $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItemEx'}, ",");
					foreach (@array) {
						next if (!$_);

						if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) ne "") {
							$ai_v{'temp'}{'foundEx'} = 1;
							last;
						}
					}
					$ai_v{'temp'}{'found'} = 1 if (!$ai_v{'temp'}{'foundEx'});
				}

				if (!$ai_v{'temp'}{'found'}) {
					$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
					if ($ai_v{'temp'}{'ai_route_index'} ne "") {
						$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
					}
					if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)) {
						unshift @ai_seq, "talkAuto";
						unshift @ai_seq_args, {};

						$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
						$sc_v{'temp'}{'ai'}{'talkAuto'}{'index'} = $i;
					}
				}
			}
			$i++;
		}
	}

	return 0 if ($ai_seq[0] ne "talkAuto");

	if ($ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'}) {

			if ($sc_v{'temp'}{'ai'}{'talkAuto'}{'do'}) {
				if ($sc_v{'temp'}{'ai'}{'autoTalk'}{'end_warpedToSave'} && $field{'name'} ne $config{'saveMap'}) {
					printC("[EVENT] talkAuto: end_warpedToSave 啟動順移回城\n", "event");

					delete $sc_v{'temp'}{'ai'}{'talkAuto'};

					useTeleport(2);
				} elsif ($field{'name'} ne $config{'saveMap'}) {
					delete $sc_v{'temp'}{'ai'}{'talkAuto'};
				}
				$ai_v{'temp'}{'ai'}{'completedAI'}{'talkAuto'} = 1;
				delete $sc_v{'temp'}{'ai'}{'itemsMaxWeight'};
			} else {
				$ai_v{'temp'}{'ai'}{'completedAI'}{'talkAuto'} = -1;
			}

			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
			timeOutStart('ai_sellAuto');
		}

	} elsif (checkTimeOut('ai_route_npcTalk') && !%{$sc_v{'temp'}{'ai'}{'autoTalk'}}) {

		$i = $sc_v{'temp'}{'ai'}{'talkAuto'}{'index'} if ($sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} > 0);

		ai_event_npc_autoTalk_data($i);

#		$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;

#		$ai_seq_args[0]{'done'} = 1 if (!%{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}});

		timeOutStart('ai_route_npcTalk');

	} elsif (checkTimeOut('ai_route_npcTalk')) {

#		ai_event_npc_autoTalk_data();

		$ai_v{'temp'}{'inNpcMap'} = inTargetMap($field{'name'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}, $sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'});

		if (
			$config{'talkAuto'}
			&& $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'} ne ""
#			&& %{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}}
			&& ai_npc_check($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'})
			&& (
				!$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'}
				|| (
					$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'}
					&&
					$ai_v{'temp'}{'inNpcMap'}
				)
			)
			&& (
				!$sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'}
				|| ($sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'} && getBrokenItems(\@{$chars[$config{'char'}]{'inventory'}}))
			)
			&& ai_checkZeny($sc_v{'temp'}{'ai'}{'autoTalk'}{'zeny'})
		) {

			undef $ai_v{'temp'}{'found'};

			if (!$ai_v{'temp'}{'found'} && $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItem'}) {
				undef @array;
				splitUseArray(\@array, $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItem'}, ",");
				foreach (@array) {
					next if (!$_);
					if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) eq "") {
						$ai_v{'temp'}{'found'} = 1;
						last;
					}
				}
			}

			if (!$ai_v{'temp'}{'found'} && $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItemEx'}) {
				undef @array;
				undef $ai_v{'temp'}{'foundEx'};
				splitUseArray(\@array, $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItemEx'}, ",");
				foreach (@array) {
					next if (!$_);

					if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) ne "") {
						$ai_v{'temp'}{'foundEx'} = 1;
						last;
					}
				}
				$ai_v{'temp'}{'found'} = 1 if (!$ai_v{'temp'}{'foundEx'});
			}

			if (!$ai_v{'temp'}{'found'}) {
				$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
				delete $sc_v{'temp'}{'ai'}{'itemsMaxWeight'};
			} else {
				delete $sc_v{'temp'}{'ai'}{'itemsMaxWeight'};

				$ai_seq_args[0]{'done'} = 1;
				last AUTOTALK;
			}
		} elsif ($sc_v{'temp'}{'ai'}{'itemsMaxWeight'} && $config{'saveMap'} ne $field{'name'} && $config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$indoors_lut{$field{'name'}.'.rsw'}) {
			$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
			$ai_seq_args[0]{'warpedToSave'} = 1;
			useTeleport(2);
			timeOutStart('ai_route_npcTalk');
			last AUTOTALK;
		} else {
			delete $sc_v{'temp'}{'ai'}{'itemsMaxWeight'};

			$ai_seq_args[0]{'done'} = 1;
			last AUTOTALK;
		}

		undef $ai_v{'temp'}{'do_route'};

		ai_getNpc(\%{$ai_v{'temp'}{'npcData'}}, $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'});

		if ($field{'name'} ne $ai_v{'temp'}{'npcData'}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$ai_v{'temp'}{'npcData'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}

#		if ($field{'name'} ne $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}) {
#			$ai_v{'temp'}{'do_route'} = 1;
#		} else {
#			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
#			if ($ai_v{'temp'}{'distance'} > 14) {
#				$ai_v{'temp'}{'do_route'} = 1;
#			}
#		}
		if ($ai_v{'temp'}{'do_route'}) {
			# Reset warpedToSave if not really do
#			if ($ai_seq_args[0]{'warpedToSave'} && (!$ai_seq_args[0]{'mapChanged'} || $field{'name'} ne $config{'saveMap'})) {
#				undef $ai_seq_args[0]{'warpedToSave'};
#			}

			undef $ai_v{'temp'}{'found'};

			$ai_v{'temp'}{'found'} = 1 if ($field{'name'} eq $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'});

			if (!$ai_v{'temp'}{'found'} && @{$record{'warp'}{'memo'}}) {
				undef %{$sc_v{'ai'}{'warpTo'}};

				if ($config{'autoWarp_checkItem'} ne "") {
					undef @array;
					splitUseArray(\@array, $config{'autoWarp_checkItem'}, ",");
					foreach (@array) {
						next if (!$_);
						if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) eq "") {
							$ai_v{'temp'}{'found'} = 1;
							last;
						}
					}
				}

				if (!$ai_v{'temp'}{'found'}) {
					for ($i=0; $i<@{$record{'warp'}{'memo'}}; $i++) {
						next if ($record{'warp'}{'memo'}[$i] eq "" || $field{'name'} eq $record{'warp'}{'memo'}[$i] || $record{'warp'}{'memo'}[$i] eq $config{'saveMap'});

						if ($record{'warp'}{'memo'}[$i] eq $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}) {

							$sc_v{'ai'}{'warpTo'}{'map'} = $record{'warp'}{'memo'}[$i];

							$ai_v{'temp'}{'found'} = 1;

							$ai_seq_args[0]{'warpedToSave'} = 1;

#								print "preferRoute_warp $sc_v{'ai'}{'warpTo'}{'map'}\n";

							print "[talkAuto] 使用傳送之陣通往自動談話地點 ".getMapName($sc_v{'ai'}{'warpTo'}{'map'}, 1)."\n";

							parseInput("warp me");

#							last;
							last AUTOTALK;
						}
					}
				} else {
					undef $ai_v{'temp'}{'found'};
				}
			}

			ai_getNpcTalk_warpedToSave_reset();

#			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} &&  (1 || !$cities_lut{$field{'name'}.'.rsw'}) && !$indoors_lut{$field{'name'}.'.rsw'}) {
			if (ai_getNpcTalk_warpedToSave($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'})) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				timeOutStart('ai_route_npcTalk');
#Karasu Start
			# Talk position change
#			} elsif ($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'}) {
##				getField("$sc_v{'path'}{'fields'}/$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
#				getFieldNPC($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'});
#				do {
#					$ai_v{'temp'}{'randX'} = $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'x'} + int(rand() * ($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'} * 2 + 1)) - $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'};
#					$ai_v{'temp'}{'randY'} = $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'y'} + int(rand() * ($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'} * 2 + 1)) - $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'};
#				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
#							|| $ai_v{'temp'}{'randX'} == $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'x'} && $ai_v{'temp'}{'randY'} == $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'y'});
#				print "計算路徑前往自動談話地點: $maps_lut{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}.'.rsw'}($npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}): ".getFormattedCoords($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
##Karasu End
#			} else {
#				print "計算路徑前往自動談話地點: $maps_lut{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}.'.rsw'}($npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}): ".getFormattedCoords($npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'x'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'y'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'x'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'y'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				ai_route_npc('談話', $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}, $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'});
			}
		} else {
#			$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'} = $config{"talkAuto_${i}_npc"};
#			$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_steps'} = $config{"talkAuto_${i}_npc_steps"};

			ai_npc_autoTalk($ai_seq[0], \%{$ai_v{'temp'}{'npcData'}});

#			if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
#				sendTalk(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}));
#				@{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_steps'});
#				$ai_seq_args[0]{'npc'}{'sentTalk'} = 1;
#
#				$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
#
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
#				sendTalkContinue(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}));
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
#				#sendTalkCancel(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}));
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i) {
#				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i;
#				if ($ai_v{'temp'}{'arg'} ne "") {
#					sendTalkAnswerNum(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}), $ai_v{'temp'}{'arg'});
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i) {
#				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i;
#				if ($ai_v{'temp'}{'arg'} ne "") {
#					sendTalkAnswerWord(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}), $ai_v{'temp'}{'arg'});
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} else {
#				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
#				if ($ai_v{'temp'}{'arg'} ne "") {
#					$ai_v{'temp'}{'arg'}++;
#					sendTalkResponse(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}), $ai_v{'temp'}{'arg'});
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			}
##			$ai_seq_args[0]{'done'} = 1 if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "");
#			if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "") {
#				$ai_seq_args[0]{'done'} = 1;
#				$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
#			}
			timeOutStart('ai_route_npcTalk');
		}
	}
	} #END OF BLOCK AUTOTALK
#Karasu End
}

#sub ai_event_npc_autoTalk_2 {
#	#Karasu Start
#	#####AUTO TALK#####
#
#	my $i = 0;
#
#	AUTOTALK: {
#
#	if (switchInput($ai_seq[0], "", "route", "sitAuto", "attack")) {
#		while ($config{"talkAuto_${i}_npc"} && !$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'}) {
#
##			$ai_v{'temp'}{'inNpcMap'} = (getMapID($field{'name'}) eq getMapID($npcs_lut{$config{"talkAuto_${i}_npc"}}{'map'}));
#			$ai_v{'temp'}{'inNpcMap'} = inTargetMap($field{'name'}, $npcs_lut{$config{"talkAuto_${i}_npc"}}{'map'}, $config{"talkAuto_${i}_inNpcMapOnly"});
#
#			$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}		= $config{"talkAuto_${i}_npc"};
#			$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_steps'}	= $config{"talkAuto_${i}_npc_steps"};
#			$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'}	= $config{"talkAuto_${i}_inNpcMapOnly"};
#			$sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'}	= $config{"talkAuto_${i}_broken"};
#			$sc_v{'temp'}{'ai'}{'autoTalk'}{'zeny'}		= $config{"talkAuto_${i}_zeny"};
#			$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'}	= $config{"talkAuto_${i}_npc_dist"};
#
#			if (
#				(switchInput($ai_seq[0], "", "route", "sitAuto") || ($ai_seq[0] eq "attack" && !$config{"talkAuto_${i}_peace"}))
#				&& $config{'talkAuto'}
#				&& $config{"talkAuto_${i}_npc"} ne ""
#				&& (
#					(
#						!$config{"talkAuto_${i}_hp"}
#						|| ($config{"talkAuto_${i}_hp"} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{"talkAuto_${i}_hp"})
#					) && (
#						!$config{"talkAuto_${i}_sp"}
#						|| ($config{"talkAuto_${i}_sp"} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{"talkAuto_${i}_sp"})
#					)
#				)
#				&& (
#					!$config{"talkAuto_${i}_inNpcMapOnly"}
#					|| (
#						$config{"talkAuto_${i}_inNpcMapOnly"}
#						&&
#						$ai_v{'temp'}{'inNpcMap'}
#					)
#				)
#				&& (
#					!$config{"talkAuto_${i}_broken"}
#					|| ($config{"talkAuto_${i}_broken"} && getBrokenItems(\@{$chars[$config{'char'}]{'inventory'}}))
#				)
#				&& ai_checkZeny($sc_v{'temp'}{'ai'}{'autoTalk'}{'zeny'})
#			) {
#				$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
#				if ($ai_v{'temp'}{'ai_route_index'} ne "") {
#					$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
#				}
#				if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)) {
#					unshift @ai_seq, "talkAuto";
#					unshift @ai_seq_args, {};
#
#					$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
#					$sc_v{'temp'}{'ai'}{'talkAuto'}{'index'} = $i;
#				}
#			}
#			$i++;
#		}
#	}
#
#	return 0 if ($ai_seq[0] ne "talkAuto");
#
#	$i = $sc_v{'temp'}{'ai'}{'talkAuto'}{'index'} if ($sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} > 0);
#
#	$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'} = $config{"talkAuto_${i}_npc"};
#	$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_steps'} = $config{"talkAuto_${i}_npc_steps"};
#	$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'} = $config{"talkAuto_${i}_inNpcMapOnly"};
#	$sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'} = $config{"talkAuto_${i}_broken"};
#	$sc_v{'temp'}{'ai'}{'autoTalk'}{'zeny'} = $config{"talkAuto_${i}_zeny"};
#	$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'} = $config{"talkAuto_${i}_npc_dist"};
#	$sc_v{'temp'}{'ai'}{'autoTalk'}{'end_warpedToSave'} = $config{"talkAuto_${i}_end_warpedToSave"};
##	$ai_v{'temp'}{'inNpcMap'} = (getMapID($field{'name'}) eq getMapID($npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}));
#
#	$ai_v{'temp'}{'inNpcMap'} = inTargetMap($field{'name'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}, $sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'});
#
#	if ($ai_seq_args[0]{'done'}) {
#		undef %{$ai_v{'temp'}{'ai'}};
#		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
#		shift @ai_seq;
#		shift @ai_seq_args;
#		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'}) {
#
#			if ($sc_v{'temp'}{'ai'}{'talkAuto'}{'do'}) {
#				if ($sc_v{'temp'}{'ai'}{'autoTalk'}{'end_warpedToSave'} && $field{'name'} ne $config{'saveMap'}) {
#					printC("[talkAuto_$i_end_warpedToSave] 啟動順移回城\n", "event");
#
#					delete $sc_v{'temp'}{'ai'}{'talkAuto'};
#
#					useTeleport(2);
#				} elsif ($field{'name'} ne $config{'saveMap'}) {
#					delete $sc_v{'temp'}{'ai'}{'talkAuto'};
#				}
#				$ai_v{'temp'}{'ai'}{'completedAI'}{'talkAuto'} = 1;
#				delete $sc_v{'temp'}{'ai'}{'itemsMaxWeight'};
#			} else {
#				$ai_v{'temp'}{'ai'}{'completedAI'}{'talkAuto'} = -1;
#			}
#
#			unshift @ai_seq, "sellAuto";
#			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
#			timeOutStart('ai_sellAuto');
#		}
#
#	} elsif (checkTimeOut('ai_route_npcTalk')) {
##		if (!$config{'talkAuto'} || !%{$npcs_lut{$config{'talkAuto_npc'}}}) {
##			$ai_seq_args[0]{'done'} = 1;
##			last AUTOTALK;
##		}
##
#
##		if (
##			!$config{'talkAuto'}
##			|| !$config{'talkAuto_npc'}
##			|| (
##				!$config{'talkAuto_borned'}
##				|| !($config{'talkAuto_borned'} > 0 && $config{'talkAuto_borned'} >= getBrokenItems(\@{$chars[$config{'char'}]{'inventory'}}))
##			)
##			|| !ai_checkZeny($config{"talkAuto_$i_zeny"})
##		) {
##			$ai_seq_args[0]{'done'} = 1;
##			last AUTOTALK;
##		}
#
#		if (
#			$config{'talkAuto'}
#			&& $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'} ne ""
#			&& %{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}}
#			&& (
#				!$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'}
#				|| (
#					$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'}
#					&&
#					$ai_v{'temp'}{'inNpcMap'}
#				)
#			)
#			&& (
#				!$config{"talkAuto_${i}_broken"}
#				|| ($config{"talkAuto_${i}_broken"} && getBrokenItems(\@{$chars[$config{'char'}]{'inventory'}}))
#			)
#			&& ai_checkZeny($sc_v{'temp'}{'ai'}{'autoTalk'}{'zeny'})
#		) {
#			$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
#			delete $sc_v{'temp'}{'ai'}{'itemsMaxWeight'};
#		} elsif ($sc_v{'temp'}{'ai'}{'itemsMaxWeight'} && $config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$indoors_lut{$field{'name'}.'.rsw'}) {
#			$ai_seq_args[0]{'warpedToSave'} = 1;
#			useTeleport(2);
#			timeOutStart('ai_route_npcTalk');
#			last AUTOTALK;
#		} else {
#			delete $sc_v{'temp'}{'ai'}{'itemsMaxWeight'};
#
#			$ai_seq_args[0]{'done'} = 1;
#			last AUTOTALK;
#		}
#
#		undef $ai_v{'temp'}{'do_route'};
#		if ($field{'name'} ne $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}) {
#			$ai_v{'temp'}{'do_route'} = 1;
#		} else {
#			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
#			if ($ai_v{'temp'}{'distance'} > 14) {
#				$ai_v{'temp'}{'do_route'} = 1;
#			}
#		}
#		if ($ai_v{'temp'}{'do_route'}) {
#			# Reset warpedToSave if not really do
#			if ($ai_seq_args[0]{'warpedToSave'} && (!$ai_seq_args[0]{'mapChanged'} || $field{'name'} ne $config{'saveMap'})) {
#				undef $ai_seq_args[0]{'warpedToSave'};
#			}
#			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$cities_lut{$field{'name'}.'.rsw'}) {
#				$ai_seq_args[0]{'warpedToSave'} = 1;
#				useTeleport(2);
#				timeOutStart('ai_route_npcTalk');
##Karasu Start
#			# Talk position change
#			} elsif ($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'}) {
#				getField("$sc_v{'path'}{'fields'}/$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
#				do {
#					$ai_v{'temp'}{'randX'} = $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'x'} + int(rand() * ($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'} * 2 + 1)) - $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'};
#					$ai_v{'temp'}{'randY'} = $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'y'} + int(rand() * ($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'} * 2 + 1)) - $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'};
#				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
#							|| $ai_v{'temp'}{'randX'} == $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'x'} && $ai_v{'temp'}{'randY'} == $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'y'});
#				print "計算路徑前往自動談話地點: $maps_lut{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}.'.rsw'}($npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}): ".getFormattedCoords($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
##Karasu End
#			} else {
#				print "計算路徑前往自動談話地點: $maps_lut{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}.'.rsw'}($npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}): ".getFormattedCoords($npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'x'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'y'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'x'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'y'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
#			}
#		} else {
##			$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'} = $config{"talkAuto_${i}_npc"};
##			$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_steps'} = $config{"talkAuto_${i}_npc_steps"};
#
#			if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
#				sendTalk(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}));
#				@{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_steps'});
#				$ai_seq_args[0]{'npc'}{'sentTalk'} = 1;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
#				sendTalkContinue(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}));
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
#				#sendTalkCancel(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}));
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i) {
#				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i;
#				if ($ai_v{'temp'}{'arg'} ne "") {
#					sendTalkAnswerNum(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}), $ai_v{'temp'}{'arg'});
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i) {
#				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i;
#				if ($ai_v{'temp'}{'arg'} ne "") {
#					sendTalkAnswerWord(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}), $ai_v{'temp'}{'arg'});
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} else {
#				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
#				if ($ai_v{'temp'}{'arg'} ne "") {
#					$ai_v{'temp'}{'arg'}++;
#					sendTalkResponse(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}), $ai_v{'temp'}{'arg'});
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			}
#			$ai_seq_args[0]{'done'} = 1 if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "");
#			timeOutStart('ai_route_npcTalk');
#		}
#	}
#	} #END OF BLOCK AUTOTALK
##Karasu End
#}

sub ai_event_npc_autoStorage {



#storageAuto - chobit aska 20030128
#####AUTO STORAGE#####

	AUTOSTORAGE: {

	if ($config{'storageAuto'} && $config{'storageAuto_npc'} ne "") {

#		if (switchInput($ai_seq[0], "", "route") && percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}) {
		if (switchInput($ai_seq[0], "", "route") && &getItemsMaxWeight()) {
			$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
			if ($ai_v{'temp'}{'ai_route_index'} ne "") {
				$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
			}
			if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_storageAutoCheck()) {
				unshift @ai_seq, "talkAuto";
				unshift @ai_seq_args, {};

				$sc_v{'temp'}{'ai'}{'itemsMaxWeight'} = 1;
			}
#storagegetAuto Start - Ayon 20030421
		} elsif (switchInput($ai_seq[0], "", "route", "attack") && $config{'storageAuto'} && $config{'storageAuto_npc'} ne "" && checkTimeOut('ai_storageAuto')) {
			undef $ai_v{'temp'}{'found'};
			my $inNpcMap = checkNpcMap($field{'name'}, $config{"storageAuto_npc"});

			$i = 0;
			while (1) {
				last if (!$config{"storagegetAuto_$i"});
				$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"storagegetAuto_$i"});
				if (
					!$stockVoid{'storage'}[$i]
					&& (
						$ai_v{'temp'}{'invIndex'} eq ""
						|| mathInNum($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'}, $config{"storagegetAuto_$i"."_minAmount"}, $config{"storagegetAuto_$i"."_maxAmount"}, 2)
					)
					&& sc_isTrue($config{"storagegetAuto_$i"."_inNpcMapOnly"}, $inNpcMap)
					&& ai_checkZeny($config{"storagegetAuto_zeny"})
				) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
				$i++;
			}
			$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
			if ($ai_v{'temp'}{'ai_route_index'} ne "") {
				$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
			}
			if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
				unshift @ai_seq, "talkAuto";
				unshift @ai_seq_args, {};
			}
			timeOutStart(
				'ai_storageAuto'
			);
		}

	}
#storagegetAuto End - Ayon 20030421

	return 0 if ($ai_seq[0] ne "storageAuto");

	if ($ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'} = 1;
			unshift @ai_seq, "buyAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
			timeOutStart('ai_buyAuto_wait');
		}
	} elsif (checkTimeOut('ai_storageAuto')) {
#		if (!$config{'storageAuto'} || !%{$npcs_lut{$config{'storageAuto_npc'}}}) {
#			$ai_seq_args[0]{'done'} = 1;
#			last AUTOSTORAGE;
#		}
		if (!$config{'storageAuto'} || ai_npc_check($config{'storageAuto_npc'})) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOSTORAGE;
		}

		undef $ai_v{'temp'}{'do_route'};
#		if ($field{'name'} ne $npcs_lut{$config{'storageAuto_npc'}}{'map'}) {
#			$ai_v{'temp'}{'do_route'} = 1;
#		} else {
#			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'storageAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
#			if ($ai_v{'temp'}{'distance'} > 14) {
#				$ai_v{'temp'}{'do_route'} = 1;
#			}
#		}

#		undef $ai_v{'temp'}{'npcData'};
		ai_getNpc(\%{$ai_v{'temp'}{'npcData'}}, $config{'storageAuto_npc'});

		if ($field{'name'} ne $ai_v{'temp'}{'npcData'}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$ai_v{'temp'}{'npcData'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			# Reset warpedToSave if not really do
#			if ($ai_seq_args[0]{'warpedToSave'} && (!$ai_seq_args[0]{'mapChanged'} || $field{'name'} ne $config{'saveMap'})) {
#				undef $ai_seq_args[0]{'warpedToSave'};
#			}

			ai_getNpcTalk_warpedToSave_reset();

#			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} &&  (1 || !$cities_lut{$field{'name'}.'.rsw'}) && !$indoors_lut{$field{'name'}.'.rsw'}) {
			if (ai_getNpcTalk_warpedToSave($config{'storageAuto_npc'})) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				timeOutStart('ai_storageAuto');
#Karasu Start
			# Storage position change
#			} elsif ($config{'storageAuto_npc_dist'}) {
##				getField("$sc_v{'path'}{'fields'}/$npcs_lut{$config{'storageAuto_npc'}}{'map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
#				getFieldNPC($config{'storageAuto_npc'});
#				do {
#					$ai_v{'temp'}{'randX'} = $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'} + int(rand() * ($config{'storageAuto_npc_dist'} * 2 + 1)) - $config{'storageAuto_npc_dist'};
#					$ai_v{'temp'}{'randY'} = $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'} + int(rand() * ($config{'storageAuto_npc_dist'} * 2 + 1)) - $config{'storageAuto_npc_dist'};
#				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
#							|| $ai_v{'temp'}{'randX'} == $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'} && $ai_v{'temp'}{'randY'} == $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'});
#				print "計算路徑前往自動存倉地點 - $maps_lut{$npcs_lut{$config{'storageAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'storageAuto_npc'}}{'map'}): ".getFormattedCoords($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $npcs_lut{$config{'storageAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
##Karasu End
#			} else {
#				print "計算路徑前往自動存倉地點 - $maps_lut{$npcs_lut{$config{'storageAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'storageAuto_npc'}}{'map'}): ".getFormattedCoords($npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'storageAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				ai_route_npc('存倉', $config{'storageAuto_npc'}, $config{'storageAuto_npc_dist'});
			}
		} else {
#Karasu Start
			# Let user define steps
#			if (!$ai_seq_args[0]{'npc'}{'sentStorage'}) {
#
#				if ($config{'storagegetAuto_uneqArrow'}){
#					for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
#						# Equip arrow related
#						next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne "0");
#
#						print "[EVENT] 開倉前自動卸下箭矢\n";
#
#						parseInput("uneq 0");
#
#						sleep(0.1);
#
#						last;
#					}
#				}
#
#				sendTalk(\$remote_socket, pack("L1", $config{'storageAuto_npc'}));
#				@{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $config{'storageAuto_npc_steps'});
#				$ai_seq_args[0]{'npc'}{'sentStorage'} = 1;
#				timeOutStart('ai_storageAuto');
#				last AUTOSTORAGE;
#			} elsif (defined(@{$ai_seq_args[0]{'npc'}{'steps'}})) {
#				if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
#					sendTalkContinue(\$remote_socket, pack("L1", $config{'storageAuto_npc'}));
#				} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
##					sendTalkCancel(\$remote_socket, pack("L1", $config{'storageAuto_npc'}));
#				} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i) {
#					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i;
#					if ($ai_v{'temp'}{'arg'} ne "") {
#						sendTalkAnswerNum(\$remote_socket, pack("L1", $config{'storageAuto_npc'}), $ai_v{'temp'}{'arg'});
#					}
#				} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i) {
#					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i;
#					if ($ai_v{'temp'}{'arg'} ne "") {
#						sendTalkAnswerWord(\$remote_socket, pack("L1", $config{'storageAuto_npc'}), $ai_v{'temp'}{'arg'});
#					}
#				} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i) {
#					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
#					if ($ai_v{'temp'}{'arg'} ne "") {
#						$ai_v{'temp'}{'arg'}++;
#						sendTalkResponse(\$remote_socket, pack("L1", $config{'storageAuto_npc'}), $ai_v{'temp'}{'arg'});
#					}
#				} else {
#					undef @{$ai_seq_args[0]{'npc'}{'steps'}};
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#				timeOutStart('ai_storageAuto');
#				last AUTOSTORAGE;
#			}

			last AUTOSTORAGE if (ai_npc_autoTalk($ai_seq[0], \%{$ai_v{'temp'}{'npcData'}}));

			$ai_seq_args[0]{'done'} = 1 ;
#Karasu End
			if (!$ai_seq_args[0]{'storagegetStart'}) {
				for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
					next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne "" || $chars[$config{'char'}]{'inventory'}[$i]{'borned'});
					if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'}
						&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
						if ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $chars[$config{'char'}]{'inventory'}[$i]{'index'}
							&& checkTimeOut('ai_storageAuto_giveup')) {
							last AUTOSTORAGE;
						} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $chars[$config{'char'}]{'inventory'}[$i]{'index'}) {
							timeOutStart('ai_storageAuto_giveup');
						}
						undef $ai_seq_args[0]{'done'};
						$ai_seq_args[0]{'lastIndex'} = $chars[$config{'char'}]{'inventory'}[$i]{'index'};
						sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'});
						timeOutStart('ai_storageAuto');
						last AUTOSTORAGE;
					}
				}
				last AUTOSTORAGE if (ai_event_itemToStorage());
			}
#storagegetAuto Start - Ayon 20030421
			if (!$ai_seq_args[0]{'storagegetStart'} && $ai_seq_args[0]{'done'} == 1) {
				$ai_seq_args[0]{'storagegetStart'} = 1;
				undef $ai_seq_args[0]{'done'};
				last AUTOSTORAGE;
			}
			$i = 0;
			undef $ai_seq_args[0]{'index'};
			while (1) {
				last if (!$config{"storagegetAuto_$i"});
				$ai_seq_args[0]{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"storagegetAuto_$i"});
				if (!$ai_seq_args[0]{'index_failed'}{$i} && $config{"storagegetAuto_$i"."_maxAmount"} ne "" && !$stockVoid{'storage'}[$i]
					&& ($ai_seq_args[0]{'invIndex'} eq ""
					|| $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} < $config{"storagegetAuto_$i"."_maxAmount"})) {
					$ai_seq_args[0]{'index'} = $i;
					last;
				}
				$i++;
			}
			if ($ai_seq_args[0]{'index'} eq ""
				|| ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'}
				&& checkTimeOut('ai_storageAuto_giveup'))) {
				$ai_seq_args[0]{'done'} = 1;
#Karasu Start
				if ($config{'recordStorage'}) {
					open(STORAGELOG, "> $sc_v{'path'}{'def_logs'}"."StorageLog.txt") if ($config{'recordStorage'} > 0);
#					open(STORAGELOG, ">> $sc_v{'path'}{'def_logs'}"."StorageLog.txt") if ($config{'recordStorage'} eq "2");
					select(STORAGELOG);
					print "[".getFormattedDate(int(time))."]\n";
					print "[".$servers[$config{'server'}]{'name'}." - ".$chars[$config{'char'}]{'name'}."]\n";
					close(STORAGELOG);
					logCommand(">> $sc_v{'path'}{'def_logs'}"."StorageLog.txt", "storage");
				}
#Karasu End
				sendStorageClose(\$remote_socket);
				last AUTOSTORAGE;
			} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $ai_seq_args[0]{'index'}) {
				timeOutStart('ai_storageAuto_giveup');
			}

			undef $ai_seq_args[0]{'done'};
			undef $ai_seq_args[0]{'storageInvIndex'};

			$ai_seq_args[0]{'lastIndex'} = $ai_seq_args[0]{'index'};
			$ai_seq_args[0]{'storageInvIndex'} = findIndexString_lc(\@{$storage{'inventory'}}, "name", $config{"storagegetAuto_$ai_seq_args[0]{'index'}"});
			if ($ai_seq_args[0]{'storageInvIndex'} eq "") {
				$stockVoid{'storage'}[$ai_seq_args[0]{'index'}] = 1;
				last AUTOSTORAGE;
			} else {
				$storagegetAmount = ($ai_seq_args[0]{'invIndex'} ne "")
					? $config{"storagegetAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'}
					: $config{"storagegetAuto_$ai_seq_args[0]{'index'}"."_maxAmount"};
				if ($storagegetAmount > $storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'amount'}) {
					$storagegetAmount = $storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'amount'};
					$stockVoid{'storage'}[$ai_seq_args[0]{'index'}] = 1;
				}
			}

			$record{"storageGet"}{$storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'nameID'}} += $storagegetAmount;

			sendStorageGet(\$remote_socket, $ai_seq_args[0]{'storageInvIndex'}, $storagegetAmount);

			timeOutStart('ai_storageAuto');
#storagegetAuto End - Ayon 20030421
		}
	}

	} #END OF BLOCK AUTOSTORAGE
}

sub ai_event_npc_autoSell {
	#####AUTO SELL#####

#	$ai_v{'temp'}{'inNpcMap'} = (getMapID($field{'name'}) eq getMapID($npcs_lut{$config{"sellAuto_npc"}}{'map'}));

	$ai_v{'temp'}{'inNpcMap'} = checkNpcMap($field{'name'}, $config{"sellAuto_npc"});

	AUTOSELL: {

	if (
		switchInput($ai_seq[0], "", "route")
		&& $config{'sellAuto'}
		&& $config{'sellAuto_npc'} ne ""
#		&& percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}
		&& &getItemsMaxWeight()
		&& (
			!$config{"sellAuto_inNpcMapOnly"}
			|| (
				$config{"sellAuto_inNpcMapOnly"}
				&&
				$ai_v{'temp'}{'inNpcMap'}
			)
		)
	) {
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_sellAutoCheck()) {
			unshift @ai_seq, "talkAuto";
			unshift @ai_seq_args, {};

			$sc_v{'temp'}{'ai'}{'itemsMaxWeight'} = 1;
		}
	}

	return 0 if ($ai_seq[0] ne "sellAuto");

	if ($ai_seq_args[0]{'done'}) {
		if ($ai_seq_args[0]{'sentSell'}) {
			$talk{'clientCancel'} = 1;
#			sendTalkResponse(\$remote_socket, pack("L1",$config{'sellAuto_npc'}), 255);
			sendTalkResponse(\$remote_socket, pack("L1",$ai_v{'temp'}{'npcData'}{'ID'}), 255);
		}
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'} = 1;
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
			timeOutStart('ai_storageAuto');
		}
	} elsif (checkTimeOut('ai_sellAuto')) {
		if (
			!$config{'sellAuto'}
#			|| !%{$npcs_lut{$config{'sellAuto_npc'}}}
			|| ai_npc_check($config{'sellAuto_npc'})
#			|| (
#				!$ai_seq_args[0]{'sentSell'}
#				&& !ai_sellAutoCheck()
#			)
		) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOSELL;
		}

		undef $ai_v{'temp'}{'do_route'};

		ai_getNpc(\%{$ai_v{'temp'}{'npcData'}}, $config{'sellAuto_npc'});

		if ($field{'name'} ne $ai_v{'temp'}{'npcData'}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$ai_v{'temp'}{'npcData'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
#
#		if ($field{'name'} ne $npcs_lut{$config{'sellAuto_npc'}}{'map'}) {
#			$ai_v{'temp'}{'do_route'} = 1;
#		} else {
#			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'sellAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
#
#			if ($ai_v{'temp'}{'distance'} > 14) {
#				$ai_v{'temp'}{'do_route'} = 1;
#			}
#		}
		if ($ai_v{'temp'}{'do_route'}) {
			# Reset warpedToSave if not really do
#			if ($ai_seq_args[0]{'warpedToSave'} && (!$ai_seq_args[0]{'mapChanged'} || $field{'name'} ne $config{'saveMap'})) {
#				undef $ai_seq_args[0]{'warpedToSave'};
#			}

			ai_getNpcTalk_warpedToSave_reset();

#			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && (1 || !$cities_lut{$field{'name'}.'.rsw'}) && !$indoors_lut{$field{'name'}.'.rsw'}) {
			if (ai_getNpcTalk_warpedToSave($config{'sellAuto_npc'})) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				timeOutStart('ai_sellAuto');
#Karasu Start
			# Sell position change
#			} elsif ($config{'sellAuto_npc_dist'}) {
##				getField("$sc_v{'path'}{'fields'}/$npcs_lut{$config{'sellAuto_npc'}}{'map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
#				getFieldNPC($config{'sellAuto_npc'});
#				do {
#					$ai_v{'temp'}{'randX'} = $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'} + int(rand() * ($config{'sellAuto_npc_dist'} * 2 + 1)) - $config{'sellAuto_npc_dist'};
#					$ai_v{'temp'}{'randY'} = $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'} + int(rand() * ($config{'sellAuto_npc_dist'} * 2 + 1)) - $config{'sellAuto_npc_dist'};
#				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
#							|| $ai_v{'temp'}{'randX'} == $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'} && $ai_v{'temp'}{'randY'} == $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'});
#				print "計算路徑前往自動賣物地點 - $maps_lut{$npcs_lut{$config{'sellAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'sellAuto_npc'}}{'map'}): ".getFormattedCoords($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $npcs_lut{$config{'sellAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
##Karasu End
#			} else {
#				print "計算路徑前往自動賣物地點 - $maps_lut{$npcs_lut{$config{'sellAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'sellAuto_npc'}}{'map'}): ".getFormattedCoords($npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'sellAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				ai_route_npc('賣物', $config{'sellAuto_npc'}, $config{'sellAuto_npc_dist'});
			}
		} else {
#			if ($ai_seq_args[0]{'sentSell'} <= 1) {
#				sendTalk(\$remote_socket, pack("L1", $config{'sellAuto_npc'})) if !$ai_seq_args[0]{'sentSell'};
#				sendGetSellList(\$remote_socket, pack("L1", $config{'sellAuto_npc'})) if $ai_seq_args[0]{'sentSell'};
#				$ai_seq_args[0]{'sentSell'}++;
#				timeOutStart('ai_sellAuto');
#				last AUTOSELL;
#			}

			last AUTOSELL if (ai_npc_autoTalk($ai_seq[0], \%{$ai_v{'temp'}{'npcData'}}));

			$ai_seq_args[0]{'done'} = 1;
			for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
				next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne "" || $chars[$config{'char'}]{'inventory'}[$i]{'borned'});
				if (
					$items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'sell'}
					&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}
				) {
					if (
						$ai_seq_args[0]{'lastIndex'} ne ""
						&& $ai_seq_args[0]{'lastIndex'} == $chars[$config{'char'}]{'inventory'}[$i]{'index'}
						&& checkTimeOut('ai_sellAuto_giveup')
					) {
						last AUTOSELL;
					} elsif (
						$ai_seq_args[0]{'lastIndex'} eq ""
						|| $ai_seq_args[0]{'lastIndex'} != $chars[$config{'char'}]{'inventory'}[$i]{'index'}
					) {
						timeOutStart('ai_sellAuto_giveup');
					}
					undef $ai_seq_args[0]{'done'};
					$ai_seq_args[0]{'lastIndex'} = $chars[$config{'char'}]{'inventory'}[$i]{'index'};
					sendSell(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'});
					timeOutStart('ai_sellAuto');
					last AUTOSELL;
				}
			}
		}
	}

	} #END OF BLOCK AUTOSELL
}

sub ai_event_npc_autoBuy {
	#####AUTO BUY#####

	if (switchInput($ai_seq[0], "", "route", "attack") && checkTimeOut('ai_buyAuto')) {
		undef $ai_v{'temp'}{'found'};
		$i = 0;
		while (1) {
			last if (!$config{"buyAuto_$i"} || !$config{"buyAuto_$i"."_npc"});
			$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
			if ($config{"buyAuto_$i"."_minAmount"} ne "" && $config{"buyAuto_$i"."_maxAmount"} ne ""
				&& ($ai_v{'temp'}{'invIndex'} eq ""
				|| ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"buyAuto_$i"."_minAmount"}
				&& $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"})
				)
				&& (
					!$config{"buyAuto_$i"."_inNpcMapOnly"}
					|| (
						$config{"buyAuto_$i"."_inNpcMapOnly"}
#						&& $field{'name'} eq $npcs_lut{$config{"buyAuto_$i"."_npc"}}{'map'}
						&& checkNpcMap($field{'name'}, $config{"buyAuto_$i"."_npc"})
					)
				)
				&& ai_checkZeny($config{"buyAuto_$i"."_zeny"})
			) {
				$ai_v{'temp'}{'found'} = 1;
				last;
			}
			$i++;
		}
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
			unshift @ai_seq, "talkAuto";
			unshift @ai_seq_args, {};
		}
		timeOutStart('ai_buyAuto');
	}

	return 0 if ($ai_seq[0] ne "buyAuto");

	if ($ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'talkAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'} = 1;
			unshift @ai_seq, "talkAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
			timeOutStart('ai_route_npcTalk');
		}
	} elsif (checkTimeOut('ai_buyAuto_wait') && timeOut(\%{$timeout{'ai_buyAuto_wait_buy'}})) {
		$i = 0;
		undef $ai_seq_args[0]{'index'};

		while (1) {
			last if (
				!$config{"buyAuto_$i"}
#				|| !%{$npcs_lut{$config{"buyAuto_$i"."_npc"}}}
				|| ai_npc_check($config{"buyAuto_$i"."_npc"})
			);

			$ai_seq_args[0]{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
			if (!$ai_seq_args[0]{'index_failed'}{$i} && $config{"buyAuto_$i"."_maxAmount"} ne "" && ($ai_seq_args[0]{'invIndex'} eq ""
				|| $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"})) {
				$ai_seq_args[0]{'index'} = $i;
				last;
			}
			$i++;
		}
		if ($ai_seq_args[0]{'index'} eq ""
			|| ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'}
			&& checkTimeOut('ai_buyAuto_giveup'))) {
			$ai_seq_args[0]{'done'} = 1;
			return;
		}
		undef $ai_v{'temp'}{'do_route'};

#		ai_getNpc(\%{$ai_v{'temp'}{'npcData'}}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"});
#
#		if ($field{'name'} ne $ai_v{'temp'}{'npcData'}{'map'}) {
#			$ai_v{'temp'}{'do_route'} = 1;
#		} else {
#			$ai_v{'temp'}{'distance'} = distance(\%{$ai_v{'temp'}{'npcData'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
#			if ($ai_v{'temp'}{'distance'} > 14) {
#				$ai_v{'temp'}{'do_route'} = 1;
#			}
#		}
#
#		print "buyAuto_$ai_seq_args[0]{'index'} - do_route : $ai_v{'temp'}{'do_route'}\n";

		if ($field{'name'} ne $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			# Reset warpedToSave if not really do
#			if ($ai_seq_args[0]{'warpedToSave'} && (!$ai_seq_args[0]{'mapChanged'} || $field{'name'} ne $config{'saveMap'})) {
#				undef $ai_seq_args[0]{'warpedToSave'};
#			}

			ai_getNpcTalk_warpedToSave_reset();

#			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} &&  (1 || !$cities_lut{$field{'name'}.'.rsw'}) && !$indoors_lut{$field{'name'}.'.rsw'}) {
			if (ai_getNpcTalk_warpedToSave($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				timeOutStart('ai_buyAuto_wait');
#Karasu Start
			# Buy position change
#			} elsif ($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"}){
##				getField(qq~$sc_v{'path'}{'fields'}/$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.fld~, \%{$ai_seq_args[0]{'dest_field'}});
#				getFieldNPC($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"});
#				do {
#					$ai_v{'temp'}{'randX'} = $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'} + int(rand() * ($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"} * 2 + 1)) - $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"};
#					$ai_v{'temp'}{'randY'} = $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'} + int(rand() * ($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"} * 2 + 1)) - $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"};
#				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
#							|| $ai_v{'temp'}{'randX'} == $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'} && $ai_v{'temp'}{'randY'} == $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'});
#				$coord_string = getFormattedCoords($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'});
#				print qq~計算路徑前往自動買物地點 - $maps_lut{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.'.rsw'}($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}): $coord_string\n~;
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}, 0, 0, 1, 0, 0, 1);
##Karasu End
#			} else {
#				$coord_string = getFormattedCoords($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'});
#				print qq~計算路徑前往自動買物地點 - $maps_lut{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.'.rsw'}($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}): $coord_string\n~;
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				ai_route_npc('買物', $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"});
			}
		} else {
			if ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $ai_seq_args[0]{'index'}) {
				undef $ai_seq_args[0]{'itemID'};
				if ($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"} != $config{"buyAuto_$ai_seq_args[0]{'lastIndex'}"."_npc"}) {
					undef $ai_seq_args[0]{'sentBuy'};
				}
				timeOutStart('ai_buyAuto_giveup');
			}
			$ai_seq_args[0]{'lastIndex'} = $ai_seq_args[0]{'index'};
			if ($ai_seq_args[0]{'itemID'} eq "") {
				foreach (keys %items_lut) {
					if (lc($items_lut{$_}) eq lc($config{"buyAuto_$ai_seq_args[0]{'index'}"})) {
						$ai_seq_args[0]{'itemID'} = $_;
					}
				}
				if ($ai_seq_args[0]{'itemID'} eq "") {
					$ai_seq_args[0]{'index_failed'}{$ai_seq_args[0]{'index'}} = 1;
					print "autoBuy index $ai_seq_args[0]{'index'} failed\n" if ($config{'debug'});
					return;
				}
			}

#			if ($ai_seq_args[0]{'sentBuy'} <= 1) {
#				if (!$ai_seq_args[0]{'sentBuy'} && $config{'buyAuto_smartEquip'} ne "") {
#					ai_equip_special($config{'buyAuto_smartEquip'});
#					sleep(0.5);
#				}
#				sendTalk(\$remote_socket, pack("L1", $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) if !$ai_seq_args[0]{'sentBuy'};
#				sendGetStoreList(\$remote_socket, pack("L1", $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) if $ai_seq_args[0]{'sentBuy'};
#				$ai_seq_args[0]{'sentBuy'}++;
#				timeOutStart('ai_buyAuto_wait');
#				return;
#			}

			return if (ai_npc_autoTalk($ai_seq[0], \%{$ai_v{'temp'}{'npcData'}}));

			if ($ai_seq_args[0]{'invIndex'} ne "") {
				sendBuy(\$remote_socket, $ai_seq_args[0]{'itemID'}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'});
			} else {
				sendBuy(\$remote_socket, $ai_seq_args[0]{'itemID'}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxAmount"});
			}

#			koreSE2.2 //

			undef $ai_seq_args[0]{'rebuy'};
			if (
				$config{'cartAuto'}
				&& $cart{'weight_max'} > 0
				&& ($cart{'weight'}/$cart{'weight_max'})*100 < $config{'cartMaxWeight'}
				&& $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxCartAmount"} > 0
			) {
				$ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $config{"buyAuto_$ai_seq_args[0]{'index'}"});
				if (
					$ai_v{'temp'}{'cartIndex'} eq ""
					|| ($cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxCartAmount"})
				) {
					$ai_seq_args[0]{'reBuy'} = 1;
					$timeout{'ai_buyAuto_giveup'}{'time'} = time;
				}
			}

#			// koreSE2.2

			timeOutStart('ai_buyAuto_wait_buy');
		}
	}
}

sub ai_event_route_preferRoute {
	#Karasu Start
	##### PREFER ROUTE #####

#	return 0 if (!$config{'preferRoute'} || $ai_v{'temp'}{'teleOnEvent'} || !@preferRoute || $sc_v{'temp'}{'teleOnEvent'});

	if (
		$config{'preferRoute'}
		&& @preferRoute
		&& !(
			$ai_v{'temp'}{'teleOnEvent'}
			|| $sc_v{'temp'}{'teleOnEvent'}
		)
		&& $ai_seq[0] eq ""
		&& $field{'name'}
		&& $field{'name'} ne $config{'lockMap'}
		&& checkTimeOut('ai_warpTo_wait')
		&& binFind(\@ai_seq, "talkAuto") eq ""
		&& binFind(\@ai_seq, "storageAuto") eq ""
		&& binFind(\@ai_seq, "sellAuto") eq ""
		&& binFind(\@ai_seq, "buyAuto") eq ""
	) {

#	if ($ai_seq[0] eq "" && $field{'name'} && $field{'name'} ne $config{'lockMap'} && checkTimeOut('ai_warpTo_wait')) {
		undef $ai_v{'temp'}{'index'};
		undef $ai_v{'temp'}{'index_next'};
		$ai_v{'temp'}{'index'} = findIndexString_lc(\@preferRoute, "map", $field{'name'});
		if ($ai_v{'temp'}{'index'} ne "") {
			$ai_v{'temp'}{'index_next'} = $ai_v{'temp'}{'index'} + 1;

			undef $ai_v{'temp'}{'found'};

			if ($config{'preferRoute_warp'} && @{$record{'warp'}{'memo'}} && $sc_v{'ai'}{'warpTo'}{'open'}) {

				if (!$sc_v{'ai'}{'warpTo'}{'stop'}) {
					$sc_v{'ai'}{'warpTo'}{'stop'} = 1;
					undef $ai_v{'temp'}{'found'};

					foreach (@spellsID) {
						undef $sourceDisplay;
						undef $castBy;
						undef $targetDisplay;

						($sourceDisplay, $castBy) = ai_getCaseID($spells{$_}{'sourceID'});

						if ($spells{$_}{'type'} eq "128" && $castBy eq "1") {
							$ai_v{'temp'}{'found'} = 1;
#							$sc_v{'ai'}{'warpTo'}{'stop'} = 1;

							$targetDisplay = getMsgStrings("011F", $spells{$_}{'type'}, 0, 2);

							print "依照偏好路徑 - 自動進入 $targetDisplay\n";

							move($spells{$_}{'pos'}{'x'}, $spells{$_}{'pos'}{'y'});

							last;
						}
					}
				}

			} elsif ($config{'preferRoute_warp'} && @{$record{'warp'}{'memo'}}) {
#				undef $ai_v{'temp'}{'found'};
#				undef $sc_v{'ai'}{'warpTo'};
				undef %{$sc_v{'ai'}{'warpTo'}};

				if ($config{'autoWarp_checkItem'} ne "") {
					undef @array;
					splitUseArray(\@array, $config{'autoWarp_checkItem'}, ",");
					foreach (@array) {
						next if (!$_);
						if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) eq "") {
							$ai_v{'temp'}{'found'} = 1;
							last;
						}
					}
				}

				$ai_v{'temp'}{'index_end'} = findIndexString_lc(\@preferRoute, "map", $config{'lockMap'});

				if (
					!$ai_v{'temp'}{'found'}
					&& (
						$ai_v{'temp'}{'index'} < $ai_v{'temp'}{'index_end'}
						|| $ai_v{'temp'}{'index_end'} eq ""
					)
				) {
					for ($i=$ai_v{'temp'}{'index_next'}; $i<$ai_v{'temp'}{'index_end'}+1; $i++) {
						next if (
							$preferRoute[$i]{'map'} eq ""
							|| $field{'name'} eq $preferRoute[$i]{'map'}
							|| $preferRoute[$i]{'map'} eq $config{'saveMap'}
						);

#						print "i= $i, j= $j - $preferRoute[$i]{'map'} : $record{'warp'}{'memo'}[$j]\n";

						for ($j=0; $j<@{$record{'warp'}{'memo'}}; $j++) {
							next if ($record{'warp'}{'memo'}[$j] eq "" || $field{'name'} eq $record{'warp'}{'memo'}[$j] || $record{'warp'}{'memo'}[$j] eq $config{'saveMap'});

#							print "i= $i, j= $j - $preferRoute[$i]{'map'} : $record{'warp'}{'memo'}[$j]\n";

							if ($record{'warp'}{'memo'}[$j] eq $preferRoute[$i]{'map'}) {

								$sc_v{'ai'}{'warpTo'}{'map'} = $record{'warp'}{'memo'}[$j];

								$ai_v{'temp'}{'found'} = 1;

#								print "preferRoute_warp $sc_v{'ai'}{'warpTo'}{'map'}\n";

								print "依照偏好路徑 - 自動使用傳送之陣通往 ".getMapName($sc_v{'ai'}{'warpTo'}{'map'}, 1)."\n";

								parseInput("warp me");

								timeOutStart('ai_warpTo_wait');

								last;
							}
						}

						last if ($ai_v{'temp'}{'found'});
					}
				} else {
					undef $ai_v{'temp'}{'found'};
				}

			}

			if (!$ai_v{'temp'}{'found'} && $config{'autoRoute_saveMap'} && $config{'saveMap'} && $config{'saveMap'} ne $field{'name'} && !$indoors_lut{$field{'name'}.'.rsw'}) {
				$ai_v{'temp'}{'index_back'} = findIndexString_lc(\@preferRoute, "map", $config{'saveMap'});

				if ($ai_v{'temp'}{'index_back'} > $ai_v{'temp'}{'index'}) {
					$ai_v{'temp'}{'found'} = 1;

					print "依照偏好路徑 - 自動順移回儲存點 ".getMapName($config{'saveMap'}, 1)."\n";

					useTeleport(2);
				}
			}

			if (!$ai_v{'temp'}{'found'} && $preferRoute[$ai_v{'temp'}{'index_next'}]{'map'} ne "") {
				if ($maps_lut{$preferRoute[$ai_v{'temp'}{'index_next'}]{'map'}.'.rsw'} eq "") {
					print "偏好路徑(preferRoute)設定錯誤 - $sc_v{'path'}{'tables'}/maps.txt中找不到 $preferRoute[$ai_v{'temp'}{'index_next'}]{'map'}.rsw\n";
				} else {
#					print "依照偏好路徑前往下一地圖 - $maps_lut{$preferRoute[$ai_v{'temp'}{'index_next'}]{'map'}.'.rsw'}($preferRoute[$ai_v{'temp'}{'index_next'}]{'map'})\n";
					print "依照偏好路徑前往下一地圖 - ".getMapName($preferRoute[$ai_v{'temp'}{'index_next'}]{'map'}, 1)."\n";
					# Find nearest portal
					undef $ai_v{'temp'}{'foundID'};
#					if ($config{'lockMap_returnQuickly'} && $config{'lockMap'} && $field{'name'} ne $config{'lockMap'}) {
					if ($config{'lockMap_returnQuickly'} && $config{'lockMap'} ne "") {
						undef $ai_v{'temp'}{'smallDist'};
						$ai_v{'temp'}{'first'} = 1;
						foreach (@portalsID) {
							undef @array;
							splitUseArray(\@array, $portals{$_}{'name'}, "->");
							if ($array[1] eq $config{'lockMap'}) {
								$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$portals{$_}{'pos'}});
								if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
									$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
									$ai_v{'temp'}{'foundID'} = $_;
									undef $ai_v{'temp'}{'first'};
								}
							}
						}
					}

					if (!$ai_v{'temp'}{'foundID'} && $config{'preferRoute_returnQuickly'}) {
						undef $ai_v{'temp'}{'smallDist'};
						$ai_v{'temp'}{'first'} = 1;
						foreach (@portalsID) {
							undef @array;
							splitUseArray(\@array, $portals{$_}{'name'}, "->");
							if ($array[1] eq $preferRoute[$ai_v{'temp'}{'index_next'}]{'map'}) {
								$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$portals{$_}{'pos'}});
								if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
									$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
									$ai_v{'temp'}{'foundID'} = $_;
									undef $ai_v{'temp'}{'first'};
								}
							}
						}
					}

					if ($ai_v{'temp'}{'foundID'}) {
						undef $ai_v{'temp'}{'pos'};

						%{$ai_v{'temp'}{'pos'}} = %{$portals{$ai_v{'temp'}{'foundID'}}{'pos'}};
						$ai_v{'temp'}{'distance'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'pos'}});
						$ai_v{'temp'}{'display'} = "$portals{$ai_v{'temp'}{'foundID'}}{'name'} - ($portals{$ai_v{'temp'}{'foundID'}}{'binID'}) ".getFormattedCoords($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'})." - Dist: $ai_v{'temp'}{'distance'}";

						if ($ai_v{'temp'}{'distance'} <= 1 && $ai_v{'temp'}{'inPortal'} > 5) {
							$ai_v{'temp'}{'distance_rand'} = 10;
							undef %{$ai_v{'temp'}{'rand'}};

							getField("$sc_v{'path'}{'fields'}/$field{'name'}.fld", \%{$ai_seq_args[0]{'dest_field'}});

							do {
								$ai_v{'temp'}{'rand'}{'x'} = $ai_v{'temp'}{'pos'}{'x'} + int(rand() * ($ai_v{'temp'}{'distance_rand'} * 2 + 1)) - $ai_v{'temp'}{'distance_rand'};
								$ai_v{'temp'}{'rand'}{'y'} = $ai_v{'temp'}{'pos'}{'y'} + int(rand() * ($ai_v{'temp'}{'distance_rand'} * 2 + 1)) - $ai_v{'temp'}{'distance_rand'};
							} while (
								ai_route_getOffset(
									\%{$ai_seq_args[0]{'dest_field'}}
									, $ai_v{'temp'}{'rand'}{'x'}
									, $ai_v{'temp'}{'rand'}{'y'}
								)
								|| (
									$ai_v{'temp'}{'rand'}{'x'} == $ai_v{'temp'}{'pos'}{'x'}
									&& $ai_v{'temp'}{'rand'}{'y'} == $ai_v{'temp'}{'pos'}{'y'}
								)
							);
							printC("▲計算路徑離開指定傳送點 $ai_v{'temp'}{'display'} - [$ai_v{'temp'}{'inPortal'}]\n", "white");

							ai_clientSuspend(0, 5);
							ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'rand'}{'x'}, $ai_v{'temp'}{'rand'}{'y'}, $field{'name'}, 0, 0, 1, 0, 0, 1);

#							ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $npcs_lut{$config{'storageAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);

							undef $ai_v{'temp'}{'distance_rand'};
						} else {
							$ai_v{'temp'}{'inPortal'}++ if ($ai_v{'temp'}{'distance'} <= 1);

							printC("▲計算路徑前往指定傳送點 $ai_v{'temp'}{'display'}\n", "white");

#						ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'} + getRand_sc(0, 1), $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'} + getRand_sc(0, 1), $field{'name'}, 0, 0, 1);
							ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, 0, 0, 1, 0, 0, 1);
						}

					} else {
						if (
							$config{'preferRoute_teleport'}
							&& $preferRoute[$ai_v{'temp'}{'index'}]{'upLeft'}{'x'} ne ""
							&& $preferRoute[$ai_v{'temp'}{'index'}]{'upLeft'}{'y'} ne ""
							&& $preferRoute[$ai_v{'temp'}{'index'}]{'bottomRight'}{'x'} ne ""
							&& $preferRoute[$ai_v{'temp'}{'index'}]{'bottomRight'}{'y'} ne ""
							&& !(
								$chars[$config{'char'}]{'pos_to'}{'x'} > $preferRoute[$ai_v{'temp'}{'index'}]{'upLeft'}{'x'}
								&& $chars[$config{'char'}]{'pos_to'}{'y'} < $preferRoute[$ai_v{'temp'}{'index'}]{'upLeft'}{'y'}
								&& $chars[$config{'char'}]{'pos_to'}{'x'} < $preferRoute[$ai_v{'temp'}{'index'}]{'bottomRight'}{'x'}
								&& $chars[$config{'char'}]{'pos_to'}{'y'} > $preferRoute[$ai_v{'temp'}{'index'}]{'bottomRight'}{'y'}
							)
#							&& !$cities_lut{$field{'name'}.'.rsw'}
							&& !$ai_v{'temp'}{'inDoor'}
							&& ($config{"preferRoute_teleport_inCity"} || !$ai_v{'temp'}{'inCity'})
						) {
							if ($config{'teleportAuto_verbose'}) {
								print "▲自動瞬移 - 尚未到達偏好路徑指定的區域\n";
							}
							$ai_v{'temp'}{'teleOnEvent'} = 1;
							timeOutStart('ai_teleport_event');
							$sc_v{'temp'}{'teleOnEvent'} = 1 if (useTeleport(1));
							#$ai_v{'clear_aiQueue'} = 1;
							ai_clientSuspend(0, $timeout{'ai_teleport_prefer'}{'timeout'});
						} else {
							ai_route(\%{$ai_v{'temp'}{'returnHash'}}, "", "", $preferRoute[$ai_v{'temp'}{'index_next'}]{'map'}, 0, 0, 1, 0, 0, 1);
						}
					}
				}
			}
		}
	}
#Karasu End
}

sub ai_event_lockMap {
	##### LOCKMAP #####

#	if ($myShop{'shop_lockMap'} && $myShop{'shop_autoStart'} && !$sc_v{'shop_config'}) {
#
#		$sc_v{'shop_config'} = 1;
#
#		my $i = 0;
#
#		$sc_v{'config'}{'lockMap'} = $config{'lockMap'};
#		$sc_v{'config'}{'lockMap_x'} = $config{'lockMap_x'};
#		$sc_v{'config'}{'lockMap_y'} = $config{'lockMap_y'};
#		$sc_v{'config'}{'lockMap_x_rand'} = $config{'lockMap_x_rand'};
#		$sc_v{'config'}{'lockMap_x_rand'} = $config{'lockMap_x_rand'};
#
#		$config{'lockMap'}	= $myShop{"shop_lockMap_${i}"};
#		$config{'lockMap_x'}	= $myShop{"shop_lockMap_${i}_x"};
#		$config{'lockMap_y'}	= $myShop{"shop_lockMap_${i}_y"};
#
#		$config{'lockMap_x_rand'} = $myShop{"shop_lockMap_${i}_x_rand"};
#		$config{'lockMap_y_rand'} = $myShop{"shop_lockMap_${i}_y_rand"};
#
#		printC("Auto change 'lockMap' to 'shop_lockMap'\n", "white");
#
#	} elsif ($sc_v{'shop_config'}) {
#
#		delete $sc_v{'shop_config'};
#
#		$config{'lockMap'}	= $sc_v{'config'}{"lockMap"};
#		$config{'lockMap_x'}	= $sc_v{'config'}{"lockMap_x"};
#		$config{'lockMap_y'}	= $sc_v{'config'}{"lockMap_y"};
#
#		$config{'lockMap_x_rand'} = $sc_v{'config'}{"lockMap_x_rand"};
#		$config{'lockMap_y_rand'} = $sc_v{'config'}{"lockMap_y_rand"};
#
#	}

	if ($ai_v{'waitting_for_leave_indoor'} && $field{'name'} ne "" && !$ai_v{'temp'}{'inDoor'}) {
		printC("event", "安全", "成功\離開不能瞬移地圖，目前地圖：".getMapName($field{'name'}, 1));
		undef $ai_v{'waitting_for_leave_indoor'};
		aiRemove("move");
		aiRemove("route");
		aiRemove("route_getRoute");
		aiRemove("route_getMapRoute");
	}

	return 0 if (!$config{'lockMap'} || !$field{'name'} || ($ai_v{'temp'}{'teleOnEvent'} && 0) || !checkTimeOut('ai_warpTo_wait'));

#Karasu Start
	my $tmpMap = getMapID($field{'name'});

	if (
		$ai_seq[0] eq ""
		&& (
			$tmpMap ne $config{'lockMap'}
			|| (
				$config{'lockMap_x'} ne ""
				&& $config{'lockMap_y'} ne ""
				&& (
					$lockMap{'pos_to'}{'x'} eq ""
					|| $chars[$config{'char'}]{'pos_to'}{'x'} != $lockMap{'pos_to'}{'x'}
					|| $chars[$config{'char'}]{'pos_to'}{'y'} != $lockMap{'pos_to'}{'y'}
				)
			)
		)
	) {
		if ($maps_lut{$config{'lockMap'}.'.rsw'} eq "") {
			print "鎖定地圖(lockMap)設定錯誤 - $sc_v{'path'}{'tables'}/maps.txt中找不到 $config{'lockMap'}.rsw\n";
		} elsif (
			1
			&& $map_control{$tmpMap}{'restrict_map'} ne "1"
			&& $tmpMap ne ""
			&& $tmpMap ne $config{'saveMap'}
			&& $tmpMap ne $config{'lockMap'}
		) {
			undef $ai_v{'waitting_for_leave_indoor'};
			if ($ai_v{'temp'}{'inDoor'}) {

#				print "試圖離開不能瞬移地圖，當前地圖：".getMapName($field{'name'}, 1)."\n";
#				chatLog("危險", "試圖離開不能瞬移地圖，當前地圖：".getMapName($field{'name'}, 1)."\n");

				sysLog("event", "危險", "試圖離開不能瞬移地圖，當前地圖：".getMapName($field{'name'}, 1), 1);

				print "正在計算鎖定地圖路線: $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'})\n";

				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, "", "", $config{'lockMap'}, 0, 0, 1, 0, 0, 1);
				$ai_v{'waitting_for_leave_indoor'} = 1;

			} elsif ($config{'respawnAuto_undef'} && $map_control{lc($map_string)}{'teleport_allow'} >= 1) {
				print "◆限定地圖: 你出現在非限定地圖($map_string)！\n";
				print "◆啟動 respawnAuto_undef - 瞬間移動回儲存點！\n";
#				chatLog("危險", "限定地圖: 你出現在非限定地圖($map_string), 瞬間移動回儲存點！", "d");
				sysLog("event", "危險", "限定地圖: 你出現在非限定地圖($map_string), 瞬間移動回儲存點！");

				useTeleport(2);
				ai_clientSuspend(0, 1);
			}
		} else {
			if ($config{'lockMap_x'} ne "") {
				$lockMap{'pos_to'}{'x'} = $config{'lockMap_x'};
				$lockMap{'pos_to'}{'y'} = $config{'lockMap_y'};
				if ($config{'lockMap_x_rand'} > 0 || $config{'lockMap_y_rand'} > 0) {
					do {
						$lockMap{'pos_to'}{'x'} = $config{'lockMap_x'} + int(rand() * ($config{'lockMap_x_rand'} * 2 + 1)) - $config{'lockMap_x_rand'};
						$lockMap{'pos_to'}{'y'} = $config{'lockMap_y'} + int(rand() * ($config{'lockMap_y_rand'} * 2 + 1)) - $config{'lockMap_y_rand'};
					} while ($field{'name'}[$lockMap{'pos_to'}{'y'} * $field{'width'} + $lockMap{'pos_to'}{'x'}]);
				}
				print "計算路徑前往鎖定位置 - $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'}): ".getFormattedCoords($lockMap{'pos_to'}{'x'}, $lockMap{'pos_to'}{'y'})."\n";
			} else {
				undef %{$lockMap{'pos_to'}};
				print "計算路徑前往鎖定地圖 - $maps_lut{$config{'lockMap'}.'.rsw'}($config{'lockMap'})\n";
			}
			if ($tmpMap ne $config{'lockMap'}) {
				# Find nearest portal
				undef $ai_v{'temp'}{'foundID'};
				if ($config{'lockMap_returnQuickly'}) {
					undef $ai_v{'temp'}{'smallDist'};
					$ai_v{'temp'}{'first'} = 1;
					foreach (@portalsID) {
						undef @array;
						splitUseArray(\@array, $portals{$_}{'name'}, "->");
						if ($array[1] eq $config{'lockMap'}) {
							$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$portals{$_}{'pos'}});
							if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
								$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
								$ai_v{'temp'}{'foundID'} = $_;
								undef $ai_v{'temp'}{'first'};
							}
						}
					}
				}
				if ($ai_v{'temp'}{'foundID'}) {
					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'x'}, $portals{$ai_v{'temp'}{'foundID'}}{'pos'}{'y'}, $field{'name'}, 0, 0, 1);
				} else {
					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $config{'lockMap_x'}, $config{'lockMap_y'}, $config{'lockMap'}, 0, 0, 1, 0, 0, 1);
				}
			} else {
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $lockMap{'pos_to'}{'x'}, $lockMap{'pos_to'}{'y'}, $config{'lockMap'}, 0, 0, 2, 0, 0, 1);
			}
		}
	}
#Karasu End
}

sub ai_event_route_randomWalk {
	##### RANDOM WALK #####

	return 0 if (!$config{'route_randomWalk'} || $ai_v{'temp'}{'teleOnEvent'});

	if ($ai_seq[0] eq "" && length($field{'rawMap'}) > 1 && (!$cities_lut{$field{'name'}.'.rsw'} || ($config{'route_randomWalk_inCity'} && $cities_lut{$field{'name'}.'.rsw'}))) {
		if ($config{'route_randomWalk_upLeft'} && $config{'route_randomWalk_bottomRight'}) {
			undef @array; splitUseArray(\@array, $config{'route_randomWalk_upLeft'}, ",");
			$ai_v{'temp'}{'upLeft'}{'x'} = $array[0]; $ai_v{'temp'}{'upLeft'}{'y'} = $array[1];
			undef @array; splitUseArray(\@array, $config{'route_randomWalk_bottomRight'}, ",");
			$ai_v{'temp'}{'bottomRight'}{'x'} = $array[0]; $ai_v{'temp'}{'bottomRight'}{'y'} = $array[1];
			$ai_v{'temp'}{'center'}{'x'} = int(($ai_v{'temp'}{'upLeft'}{'x'} + $ai_v{'temp'}{'bottomRight'}{'x'}) / 2);
			$ai_v{'temp'}{'center'}{'y'} = int(($ai_v{'temp'}{'upLeft'}{'y'} + $ai_v{'temp'}{'bottomRight'}{'y'}) / 2);
			$ai_v{'temp'}{'radius'}{'x'} = int(($ai_v{'temp'}{'bottomRight'}{'x'} - $ai_v{'temp'}{'upLeft'}{'x'}) / 2);
			$ai_v{'temp'}{'radius'}{'y'} = int(($ai_v{'temp'}{'upLeft'}{'y'} - $ai_v{'temp'}{'bottomRight'}{'y'}) / 2);
			do {
				$ai_v{'temp'}{'randX'} = $ai_v{'temp'}{'center'}{'x'} + int(rand() * ($ai_v{'temp'}{'radius'}{'x'} * 2 + 1)) - $ai_v{'temp'}{'radius'}{'x'};
				$ai_v{'temp'}{'randY'} = $ai_v{'temp'}{'center'}{'y'} + int(rand() * ($ai_v{'temp'}{'radius'}{'y'} * 2 + 1)) - $ai_v{'temp'}{'radius'}{'y'};
			} while (ai_route_getOffset(\%field, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}));
		} else {
			do {
				$ai_v{'temp'}{'randX'} = int(rand() * ($field{'width'} - 1));
				$ai_v{'temp'}{'randY'} = int(rand() * ($field{'height'} - 1));
			} while (ai_route_getOffset(\%field, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}));
		}
		print "計算路徑前往隨機地點 - $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})."\n";
		ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $field{'name'}, 0, $config{'route_randomWalk_maxRouteTime'}, 2);
	}
}

sub ai_event_dead {
	##### DEAD #####

	if ($ai_seq[0] eq "dead" && !$chars[$config{'char'}]{'dead'}) {
		shift @ai_seq;
		shift @ai_seq_args;

		#force storage after death
		unshift @ai_seq, "talkAuto";
		unshift @ai_seq_args, {};
	} elsif ($ai_seq[0] ne "dead" && $chars[$config{'char'}]{'dead'}) {
		if ($sc_v{'temp'}{'itemsImportantAutoMode'}) {
			undef $sc_v{'temp'}{'itemsImportantAutoMode'};

			my $ai_index = binFind(\@ai_seq, "take");

			if ($ai_index ne "" && $ai_seq_args[$ai_index]{'mode'}) {
#				print "撿取物品: $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) 失敗\n";

				sysLog("ii", "死亡", "撿取物品失敗: $items{$ai_seq_args[$ai_index]{'ID'}}{'name'} ($items{$ai_seq_args[$ai_index]{'ID'}}{'binID'}) 你死了！", 1);
			}
		}

		undef @ai_seq;
		undef @ai_seq_args;
		unshift @ai_seq, "dead";
		unshift @ai_seq_args, {};
	}

	if ($ai_seq[0] eq "dead") {
		if ($config{'dcOnDeath'}) {
			print "◆啟動 dcOnDeath - 立即登出！\n";
#			chatLog("重要", "重要訊息: 你死了, 立即登出！", "im");

			sysLog("im", "重要", "重要訊息: 你死了, 立即登出！");

#			$quit = 1;

			quit(1, 1);

		} elsif (ks_isTrue($config{'deadRespawn'}) && (time - $chars[$config{'char'}]{'dead_time'}) >= $timeout{'ai_dead_respawn'}{'timeout'}) {

			if ($shop{'opened'}) {

				event_shop_close(0, 1);

				sleep(1);

			}

			sendRespawn(\$remote_socket);
			$chars[$config{'char'}]{'dead_time'} = time;

		}
		return 1;
	}

	return 0;
}

sub ai_event_auto_useItem {
	##### AUTO-ITEM USE #####

	if (
		switchInput(
			$ai_seq[0],
			"",
			"route",
			"route_getRoute",
			"route_getMapRoute",
			"follow",
			"sitAuto",
			"take",
			"items_gather",
			"items_take",
			"attack"
		)
		&& checkTimeOut('ai_item_use_auto')
	) {
		my $ai_index = binFind(\@ai_seq, "attack");

		my $i = 0;
#		my $inTake	= ((binFind(\@ai_seq, "take") ne "" || binFind(\@ai_seq, "items_take") ne "" || binFind(\@ai_seq, "items_gather") ne "")?1:0);
#		my $inAttack	= (binFind(\@ai_seq, "attack") ne "")?1:0;

		while (1) {
			last if (!$config{"useSelf_item_$i"});
			if (percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_item_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_item_$i"."_hp_lower"}
				&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_item_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_item_$i"."_sp_lower"}
				&& !($config{"useSelf_item_$i"."_stopWhenHit"} && $ai_v{'temp'}{'onHit'})
				# Use when not sit
				&& !($config{"useSelf_item_$i"."_stopWhenSit"} && $chars[$config{'char'}]{'sitting'})
				&& $config{"useSelf_item_$i"."_minAggressives"} <= $ai_v{'temp'}{'getAggressives'}
				&& (!$config{"useSelf_item_$i"."_maxAggressives"} || $config{"useSelf_item_$i"."_maxAggressives"} >= $ai_v{'temp'}{'getAggressives'})
				# Monsters support
				&& (!$config{"useSelf_item_$i"."_monsters"} || ($ai_index ne "" && existsInList($config{"useSelf_item_$i"."_monsters"}, $monsters{$ai_seq_args[$ai_index]{'ID'}}{'name'})))
				# Timeout support
				&& timeOut($config{"useSelf_item_$i"."_timeout"}, $ai_v{"useSelf_item_$i"."_time"})
				# Use in lockMap only
				&& (!$config{"useSelf_item_$i"."_inLockOnly"} || ($config{"useSelf_item_$i"."_inLockOnly"} && $ai_v{'temp'}{'inLockMap'}))
				&& (!$config{"useSelf_item_$i"."_unLockOnly"} || ($config{"useSelf_item_$i"."_unLockOnly"} && !$ai_v{'temp'}{'inLockMap'}))
				&& !($config{"useSelf_item_$i"."_stopWhenAttack"} && $ai_v{'temp'}{'inAttack'})
				&& !($config{"useSelf_item_$i"."_stopWhenTake"} && $ai_v{'temp'}{'inTake'})
			) {
				# Judge parameter and status
				undef $ai_v{'temp'}{'found'};
				if ($config{"useSelf_item_$i"."_param2"} && !existsInList2($config{"useSelf_item_$i"."_param2"}, $chars[$config{'char'}]{'param2'}, "and")) {
					$ai_v{'temp'}{'found'} = 1;
				}
				if ($config{"useSelf_item_$i"."_checkItem"}) {
					undef @array;
					splitUseArray(\@array, $config{"useSelf_item_$i"."_checkItem"}, ",");
					foreach (@array) {
						next if (!$_);
						if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) eq "") {
							$ai_v{'temp'}{'found'} = 1;
							last;
						}
					}
				}
				if ($config{"useSelf_item_$i"."_checkItemEx"}) {
					undef @array;
					undef $ai_v{'temp'}{'foundEx'};
					splitUseArray(\@array, $config{"useSelf_item_$i"."_checkItemEx"}, ",");
					foreach (@array) {
						next if (!$_);

						if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) eq "") {
							$ai_v{'temp'}{'foundEx'} = 1;
							last;
						}
					}
					$ai_v{'temp'}{'found'} = 1 if (!$ai_v{'temp'}{'foundEx'});
				}
				if ($config{"useSelf_item_$i"."_status"} ne "") {
					foreach (@{$chars[$config{'char'}]{'status'}}) {
						if (existsInList2($config{"useSelf_item_$i"."_status"}, $_, "noand")) {
							$ai_v{'temp'}{'found'} = 1;
#							print "useSelf_item_${i}_status = $ai_v{'temp'}{'found'} - $_\n";
							last;
						}
					}
				}

#				print "useSelf_item_$i = $ai_v{'temp'}{'found'}\n";

				if (!$ai_v{'temp'}{'found'}) {
					undef $ai_v{'temp'}{'invIndex'};
#ICE-WR Start
					# Use item in priority
					#$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"useSelf_item_$i"});
					$ai_v{'temp'}{'invIndex'} = findIndexStringPriority_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"useSelf_item_$i"});
#ICE-WR End

#					print "- $ai_v{'temp'}{'invIndex'}\n";

					if ($ai_v{'temp'}{'invIndex'} ne "") {
						# Check storagegetAuto and buyAuto first
						$ai_v{'temp'}{'checkSupplyPass'} = 1;
						if ($config{"useSelf_item_$i"."_checkSupplyFirst"}) {
							$k = 0;
							while ($ai_v{'temp'}{'checkSupplyPass'}) {
								last if (!$config{'storageAuto'} || !$config{'storageAuto_npc'} || !$config{"storagegetAuto_$k"});
								if ($config{"storagegetAuto_$k"} eq $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'name'} && !$stockVoid{'storage'}[$k]
									&& $config{"storagegetAuto_$k"."_minAmount"} ne "" && $config{"storagegetAuto_$k"."_maxAmount"} ne ""
									&& $config{"storagegetAuto_$k"."_minAmount"} == $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} - 1) {
									undef $ai_v{'temp'}{'checkSupplyPass'};
								}
								$k++;
							}
							$k = 0;
							while ($ai_v{'temp'}{'checkSupplyPass'}) {
								last if (!$config{"buyAuto_$k"} || !$config{"buyAuto_$k"."_npc"});
								if ($config{"buyAuto_$k"} eq $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'name'}
									&& $config{"buyAuto_$k"."_minAmount"} ne "" && $config{"buyAuto_$k"."_maxAmount"} ne ""
									&& $config{"buyAuto_$k"."_minAmount"} == $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} - 1) {
									undef $ai_v{'temp'}{'checkSupplyPass'};
								}
								$k++;
							}
						}
						if ($ai_v{'temp'}{'checkSupplyPass'}) {
							$ai_v{"useSelf_item_$i"."_time"} = time;
							# Item use repeat
							$config{"useSelf_item_$i"."_repeat"} = 1 if(!$config{"useSelf_item_$i"."_repeat"});
							for ($j = 0; $j < $config{"useSelf_item_$i"."_repeat"}; $j++) {
								sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'index'}, $accountID);
								$chars[$config{'char'}]{'sendItemUse'}++;
							}
#							timeOutStart('ai_item_use_auto');
							print qq~Auto-item use: $items_lut{$chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'nameID'}}\n~ if ($config{'debug'});
						} elsif (binFind(\@ai_seq, "talkAuto") eq "" && binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "sellAuto") eq "" && binFind(\@ai_seq, "buyAuto") eq "") {
							unshift @ai_seq, "talkAuto";
							unshift @ai_seq_args, {};
						}
						last;
					}
				}
			}
			$i++;
		}
		timeOutStart('ai_item_use_auto');
	}
}

sub ai_event_auto_useSkill {
	##### AUTO-SKILL USE #####

	return 0 if (
		!$config{'useSelf_skill'}
		|| !switchInput(
			$ai_seq[0],
			"",
			"route",
			"route_getRoute",
			"route_getMapRoute",
			"follow",
			"sitAuto",
			"take",
			"items_gather",
			"items_take",
			"attack"
		)
		|| !checkTimeOut('ai_useSelf_skill_auto')
	);

	my $i = 0;

	undef $ai_v{'useSelf_skill'};
	undef $ai_v{'useSelf_skill_lvl'};

#	my $inLockMap	= (($field{'name'} eq $config{'lockMap'})?1:0);
#	my $inLockPos	= (($inLockMap && $config{'lockMap_x'} eq "") || ($chars[$config{'char'}]{'pos_to'}{'x'} == $lockMap{'pos_to'}{'x'} && $chars[$config{'char'}]{'pos_to'}{'y'} == $lockMap{'pos_to'}{'y'}));
#	my $inCity	= $cities_lut{$field{'name'}.'.rsw'};
#	my $inTake	= ((binFind(\@ai_seq, "take") ne "" || binFind(\@ai_seq, "items_take") ne "" || binFind(\@ai_seq, "items_gather") ne "")?1:0);
#
##	my $onHit	= ai_getAggressives() or ai_getMonstersWhoHitMe() or ai_getMonstersHitMe();
##	my $onHit	= ai_getMonstersHitMe() or $sc_v{'ai'}{'onHit'};
#	my $onHit	= ai_getMonstersHitMe() or $sc_v{'ai'}{'onHit'};
#	my $inAttack	= (binFind(\@ai_seq, "attack") ne "")?1:0;

	while (1) {
		last if (!$config{"useSelf_skill_$i"});

		if (
#			mathInNum(percent_hp(\%{$chars[$config{'char'}]}), $config{"useSelf_skill_$i"."_hp_upper"}, $config{"useSelf_skill_$i"."_hp_lower"}, 1)
#			&& mathInNum(percent_sp(\%{$chars[$config{'char'}]}), $config{"useSelf_skill_$i"."_sp_upper"}, $config{"useSelf_skill_$i"."_sp_lower"}, 1)
#			percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_skill_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_skill_$i"."_hp_lower"}
#			&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useSelf_skill_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useSelf_skill_$i"."_sp_lower"}
			# Not really important, just change the sp judge
			#&& $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"useSelf_skill_$i"})}}{$config{"useSelf_skill_$i"."_lvl"}}
#			&&
#			timeOut($config{"useSelf_skill_$i"."_timeout"}, $ai_v{"useSelf_skill_$i"."_time"})
##			&& !($config{"useSelf_skill_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
#			&& !($config{"useSelf_skill_$i"."_stopWhenHit"} && $sc_v{'ai'}{'onHit'})
#			# Use when not sit
#			&& !($config{"useSelf_skill_$i"."_stopWhenSit"} && $chars[$config{'char'}]{'sitting'})
#			# Use when not take
#			&& !($config{"useSelf_skill_$i"."_stopWhenTake"} && $inTake)
#			&& $config{"useSelf_skill_$i"."_minAggressives"} <= ai_getAggressives()
#			&& (!$config{"useSelf_skill_$i"."_maxAggressives"} || $config{"useSelf_skill_$i"."_maxAggressives"} >= ai_getAggressives())
#			# Wait after kill
#			&& (!$config{"useSelf_skill_$i"."_waitAfterKill"} || timeOut(\%{$timeout{'ai_skill_use_waitAfterKill'}}))
##Karasu Start
#			# Spirits support
#			&& (isMonk($chars[$config{'char'}]{'jobID'}) || ($chars[$config{'char'}]{'spirits'} <= $config{"useSelf_skill_$i"."_spirits_upper"} && $chars[$config{'char'}]{'spirits'} >= $config{"useSelf_skill_$i"."_spirits_lower"}))
#			# Allow to use in city or not
#			&& ($config{"useSelf_skill_$i"."_inCity"} || !$inCity)
#			# Use in lockMap only
#			&& (!$config{"useSelf_skill_$i"."_inLockOnly"} || (($config{"useSelf_skill_$i"."_inLockOnly"} ne "2" && $config{"useSelf_skill_$i"."_inLockOnly"} && $inLockMap) || ($config{"useSelf_skill_$i"."_inLockOnly"} eq "2" && $config{"useSelf_skill_$i"."_inLockOnly"} && $inLockPos)))
#			&& (!$config{"useSelf_skill_$i"."_unLockOnly"} || ($config{"useSelf_skill_$i"."_unLockOnly"} && !$inLockMap))
#			&& !($config{"useSelf_skill_$i"."_stopWhenAttack"} && $inAttack)
			ai_checkToUseSkill("useSelf_skill", $i, 1, $ai_v{"useSelf_skill_$i"."_time"}, $chars[$config{'char'}]{'useSelf_skill_uses'}{$i})
		) {
			# Judge parameter and status
			undef $ai_v{'temp'}{'found'};
#			if (!$ai_v{'temp'}{'found'} && $config{"useSelf_skill_$i"."_param2"} && !existsInList2($config{"useSelf_skill_$i"."_param2"}, $chars[$config{'char'}]{'param2'}, "and")) {
#				$ai_v{'temp'}{'found'} = 1;
#			}
#			if ($config{"useSelf_skill_$i"."_checkItem"}) {
#				undef @array;
#				splitUseArray(\@array, $config{"useSelf_skill_$i"."_checkItem"}, ",");
#				foreach (@array) {
#					next if (!$_);
#					if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) eq "") {
#						$ai_v{'temp'}{'found'} = 1;
#						last;
#					}
#				}
#			}
#			if ($config{"useSelf_skill_$i"."_checkItemEx"}) {
#				undef @array;
#				undef $ai_v{'temp'}{'foundEx'};
#				splitUseArray(\@array, $config{"useSelf_skill_$i"."_checkItemEx"}, ",");
#				foreach (@array) {
#					next if (!$_);
#
#					if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) ne "") {
#						$ai_v{'temp'}{'foundEx'} = 1;
#						last;
#					}
#				}
#				$ai_v{'temp'}{'found'} = 1 if (!$ai_v{'temp'}{'foundEx'});
#			}
#			if (!$ai_v{'temp'}{'found'} && $config{"useSelf_skill_$i"."_status"} ne "") {
#				foreach (@{$chars[$config{'char'}]{'status'}}) {
#					if (existsInList2($config{"useSelf_skill_$i"."_status"}, $_, "noand")) {
#						$ai_v{'temp'}{'found'} = 1;
#						last;
#					}
#				}
#			}

			$ai_v{'temp'}{'found'} = ai_checkToUseSkill("useSelf_skill", $i, 0, \%{$chars[$config{'char'}]}, \%{$chars[$config{'char'}]});

#			# Judge equipped type
#			if ($config{"useSelf_skill_$i"."_checkEquipped"} ne "") {
#				undef $ai_v{'temp'}{'invIndex'};
#				$ai_v{'temp'}{'invIndex'} = findIndexStringWithList_KeyNotNull_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"useSelf_skill_$i"."_checkEquipped"}, "equipped");
#				$ai_v{'temp'}{'found'} = 1 if ($ai_v{'temp'}{'invIndex'} eq "");
#			}
#			$ai_v{'temp'}{'found'} = 1 if (
#				!$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"useSelf_skill_$i"})}}{'lv'}
#				&& (
#					$config{"useSelf_skill_$i"."_smartEquip"} eq ""
#					|| ($config{"useSelf_skill_$i"."_smartEquip"} ne "" findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"useSelf_skill_$i"."_smartEquip"}))
#				)
#			);

#			if (!$ai_v{'temp'}{'found'} && $config{"useSelf_skill_${i}_spells"} ne "") {
#				foreach (@spellsID) {
#					next if ($_ eq "" || $spells{$_}{'type'} eq "");
#
#					undef $s_cDist;
#
#					$s_cDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$spells{$_}{'pos'}});
#
#					if (
#						existsInList($config{"useSelf_skill_${i}_spells"}, $spells{$_}{'type'})
#						&& (!$config{"useSelf_skill_${i}_spells_dist"} || $s_cDist <= $config{"useSelf_skill_${i}_spells_dist"})
#					) {
#						$ai_v{'temp'}{'found'} = 1;
#
#						last;
#					}
#				}
#			}

			if (!$ai_v{'temp'}{'found'}) {

#				print $config{"useSelf_skill_$i"}." getAggressives: ".ai_getAggressives()." onHit: $onHit inTake: $inTake\n";

				# Equip for skill
				undef %{$ai_v{'checkEquip'}};
				if (!$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"useSelf_skill_$i"})}}{'lv'} && $config{"useSelf_skill_$i"."_smartEquip"} ne "") {
					$ai_v{'checkEquip'}{'ignorePos'} = ai_equip_special($config{"useSelf_skill_$i"."_smartEquip"});
					$ai_v{'checkEquip'}{'skillID'} = ai_getSkillUseID($config{"useSelf_skill_$i"});
				}

#				print "onHit: $sc_v{'ai'}{'onHit'}\n" if ($config{"useSelf_skill_$i"."_stopWhenHit"});
#Karasu End
				$ai_v{"useSelf_skill_$i"."_time"} = time;
				$ai_v{'useSelf_skill'} = $config{"useSelf_skill_$i"};
				$ai_v{'useSelf_skill_lvl'} = $config{"useSelf_skill_$i"."_lvl"};
				$ai_v{'useSelf_skill_maxCastTime'} = $config{"useSelf_skill_$i"."_maxCastTime"};
				$ai_v{'useSelf_skill_minCastTime'} = $config{"useSelf_skill_$i"."_minCastTime"};

				$chars[$config{'char'}]{'useSelf_skill_uses'}{$i}++;

				last;
			}
		}
		$i++;
	}

	if ($ai_v{'useSelf_skill'}) {
#		if ($config{'useSelf_skill_smartHeal'} && $skills_rlut{lc($ai_v{'useSelf_skill'})} eq "AL_HEAL") {
#			undef $ai_v{'useSelf_skill_smartHeal_lvl'};
#			$ai_v{'useSelf_skill_smartHeal_hp_dif'} = $chars[$config{'char'}]{'hp_max'} - $chars[$config{'char'}]{'hp'};
#			$ai_v{'useSelf_skill_smartHeal_lvl_upper'} = ($chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}) ? $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} : $ai_v{'useSelf_skill_lvl'};
#			for ($i = 1; $i <= $ai_v{'useSelf_skill_smartHeal_lvl_upper'}; $i++) {
#				$ai_v{'useSelf_skill_smartHeal_lvl'} = $i;
#				$ai_v{'useSelf_skill_smartHeal_sp'} = 10 + ($i * 3);
#				$ai_v{'useSelf_skill_smartHeal_amount'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
#						* (4 + $i * 8);
#				if ($chars[$config{'char'}]{'sp'} < $ai_v{'useSelf_skill_smartHeal_sp'}) {
#					$ai_v{'useSelf_skill_smartHeal_lvl'}--;
#					last;
#				}
#				last if ($ai_v{'useSelf_skill_smartHeal_amount'} >= $ai_v{'useSelf_skill_smartHeal_hp_dif'});
#			}
#			$ai_v{'useSelf_skill_lvl'} = $ai_v{'useSelf_skill_smartHeal_lvl'};
#		}
		$ai_v{'useSelf_skill_lvl'} = ai_smartHeal($ai_v{'useSelf_skill_lvl'}) if ($skills_rlut{lc($ai_v{'useSelf_skill'})} eq "AL_HEAL");
		if ($config{'useSelf_skill_smartAutospell'} && $skills_rlut{lc($ai_v{'useSelf_skill'})} eq "SA_AUTOSPELL") {
			undef $ai_v{'useSelf_skill_smartAutospell'};
			$ai_v{'useSelf_skill_smartAutospell'} = ai_getSkillUseID($config{'useSelf_skill_smartAutospell'});
		}
		if ($skills_rlut{lc($ai_v{'useSelf_skill'})} eq "AM_PHARMACY") {
			undef $ai_v{'useSelf_smartAutomake'};
			$ai_v{'useSelf_smartAutomake'} = 1 if ($config{'useSelf_smartAutomake'});
		}
		if ($skills_rlut{lc($ai_v{'useSelf_skill'})} eq "AC_MAKINGARROW") {
			undef $ai_v{'useSelf_smartAutoarrow'};
			$ai_v{'useSelf_smartAutoarrow'} = 1 if ($config{'useSelf_smartAutoarrow'});
		}
		# Change sp judge in here
		if ($ai_v{'useSelf_skill_lvl'} > 0 && $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{$ai_v{'useSelf_skill_lvl'}}) {
			$ai_v{'useSelf_skill_ID'} = ($ai_v{'checkEquip'}{'skillID'}) ? $ai_v{'checkEquip'}{'skillID'} : $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useSelf_skill'})}}{'ID'};
			print qq~Auto-skill on self: $skills_lut{$skills_rlut{lc($ai_v{'useSelf_skill'})}} (lvl $ai_v{'useSelf_skill_lvl'}) [ID:$ai_v{'useSelf_skill_ID'}]\n~ if ($config{'debug'});
			if (!ai_getSkillUseType($skills_rlut{lc($ai_v{'useSelf_skill'})})) {
				ai_skillUse($ai_v{'useSelf_skill_ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, $accountID, "", $ai_v{'checkEquip'}{'ignorePos'}, "self");
			} else {
				ai_skillUse($ai_v{'useSelf_skill_ID'}, $ai_v{'useSelf_skill_lvl'}, $ai_v{'useSelf_skill_maxCastTime'}, $ai_v{'useSelf_skill_minCastTime'}, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}, $ai_v{'checkEquip'}{'ignorePos'}, "self");
			}
		}
		undef $sc_v{'temp'}{'teleOnEvent'};
	}

	timeOutStart('ai_useSelf_skill_auto');
}

sub ai_event_follow {
	##### FOLLOW #####
	return 0;

	if (!$config{'follow'}){

		if ($ai_seq[0] eq "follow"){
			aiRemove("follow");
		}

		return 0;
	} elsif ($ai_seq[0] eq "" && ($config{'lockMap'} eq "" || $field{'name'} eq $config{'lockMap'})) {
		ai_follow($config{'followTarget'});
	}

	return 0 if ($ai_seq[0] ne "follow" || !checkTimeOut('ai_follow'));

	if ($ai_seq_args[0]{'suspended'}) {
		if ($ai_seq_args[0]{'ai_follow_lost'}) {
			$ai_seq_args[0]{'ai_follow_lost_end'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		}
		undef $ai_seq_args[0]{'suspended'};
	}

	if (!$ai_seq_args[0]{'ai_follow_lost'}) {
		if (!$ai_seq_args[0]{'following'}) {
			undef $ai_seq_args[0]{'following'};
			undef $ai_seq_args[0]{'ID'};

			foreach (keys %players) {
				if ($players{$_}{'name'} eq $ai_seq_args[0]{'name'}) {
					$ai_seq_args[0]{'ID'} = $_;
					$ai_seq_args[0]{'following'} = 1;

					print "找到主人 $players{$_}{'name'}\n";

					last;
				}
			}
		}
		if ($ai_seq_args[0]{'following'} && $players{$ai_seq_args[0]{'ID'}}{'pos_to'}) {
			$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ai_seq_args[0]{'ID'}}{'pos_to'}});
			if ($ai_v{'temp'}{'dist'} > $config{'followDistanceMax'}) {
				ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'x'}, $players{$ai_seq_args[0]{'ID'}}{'pos_to'}{'y'}, $field{'name'}, 0, 0, 1, 0, $config{'followDistanceMin'});
			}
		}
		if ($ai_seq_args[0]{'following'} && $players{$ai_seq_args[0]{'ID'}}{'sitting'} == 1 && $chars[$config{'char'}]{'sitting'} == 0) {
			sit();
		}
	}

	return 0 if (!$ai_seq_args[0]{'following'} || $ai_seq_args[0]{'ID'} eq "");

	if ($ai_seq_args[0]{'following'} && ($players{$ai_seq_args[0]{'ID'}}{'dead'} || $players_old{$ai_seq_args[0]{'ID'}}{'dead'})) {
		print "我的主人死了, 在原地等待\n";
		undef $ai_seq_args[0]{'following'};
	} elsif ($ai_seq_args[0]{'following'} && !%{$players{$ai_seq_args[0]{'ID'}}}) {
		print "我竟然跟丟了！\n";
		undef $ai_seq_args[0]{'following'};
		if ($players_old{$ai_seq_args[0]{'ID'}}{'disconnected'}) {
			print "原來主人下線了\n";

		} elsif ($players_old{$ai_seq_args[0]{'ID'}}{'disappeared'}) {
			print "往主人走的方向找找看好了\n";
			undef $ai_seq_args[0]{'ai_follow_lost_char_last_pos'};
			undef $ai_seq_args[0]{'follow_lost_portal_tried'};
			$ai_seq_args[0]{'ai_follow_lost'} = 1;
			$ai_seq_args[0]{'ai_follow_lost_end'}{'timeout'} = $timeout{'ai_follow_lost_end'}{'timeout'};
			$ai_seq_args[0]{'ai_follow_lost_end'}{'time'} = time;
			getVector(\%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, \%{$players_old{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});

			#check if player went through portal
			undef $ai_v{'temp'}{'foundID'};
			undef $ai_v{'temp'}{'smallDist'};
			$ai_v{'temp'}{'first'} = 1;
			foreach (@portalsID) {
				$ai_v{'temp'}{'dist'} = distance(\%{$players_old{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$portals{$_}{'pos'}});
				if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
					$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
					$ai_v{'temp'}{'foundID'} = $_;
					undef $ai_v{'temp'}{'first'};
				}
			}
			$ai_seq_args[0]{'follow_lost_portalID'} = $ai_v{'temp'}{'foundID'};
		} else {
			print "你知道我的主人怎麼了嗎？\n";
		}
	}



	##### FOLLOW-LOST #####


	if ($ai_seq_args[0]{'ai_follow_lost'}) {
		if ($ai_seq_args[0]{'ai_follow_lost_char_last_pos'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'} && $ai_seq_args[0]{'ai_follow_lost_char_last_pos'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}) {
			$ai_seq_args[0]{'lost_stuck'}++;
		} else {
			undef $ai_seq_args[0]{'lost_stuck'};
		}
		%{$ai_seq_args[0]{'ai_follow_lost_char_last_pos'}} = %{$chars[$config{'char'}]{'pos_to'}};

		if (timeOut(\%{$ai_seq_args[0]{'ai_follow_lost_end'}})) {
			undef $ai_seq_args[0]{'ai_follow_lost'};
#ICE-WR Start
			undef $ai_seq_args[0]{'follow_lost_portalID'};
#ICE-WR End
			print "找不到主人, 我放棄了\n";

		} elsif ($players_old{$ai_seq_args[0]{'ID'}}{'disconnected'}) {
			undef $ai_seq_args[0]{'ai_follow_lost'};
			print "原來主人下線了\n";

		} elsif (%{$players{$ai_seq_args[0]{'ID'}}}) {
			$ai_seq_args[0]{'following'} = 1;
			undef $ai_seq_args[0]{'ai_follow_lost'};
			print "主人我終於找到你了！\n";

		} elsif ($ai_seq_args[0]{'lost_stuck'}) {
			if ($ai_seq_args[0]{'follow_lost_portalID'} eq "") {
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, $config{'followLostStep'} / ($ai_seq_args[0]{'lost_stuck'} + 1));
				move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
			}
		} else {
			if ($ai_seq_args[0]{'follow_lost_portalID'} ne "") {
				if (%{$portals{$ai_seq_args[0]{'follow_lost_portalID'}}} && !$ai_seq_args[0]{'follow_lost_portal_tried'}) {
					$ai_seq_args[0]{'follow_lost_portal_tried'} = 1;
					%{$ai_v{'temp'}{'pos'}} = %{$portals{$ai_seq_args[0]{'follow_lost_portalID'}}{'pos'}};
					ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, 0, 0, 1);
#ICE-WR Start
					undef $ai_seq_args[0]{'follow_lost_portalID'};
#ICE-WR End
				}
			} else {
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'ai_follow_lost_vec'}}, $config{'followLostStep'});
				move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
			}
		}
	}

	timeOutStart('ai_follow');
}

sub ai_event_body {
	##### AUTO-SIT/SIT/STAND #####

	if ($config{'sitAuto_idle'}) {

		if (!switchInput($ai_seq[0], "", "follow")) {
			timeOutStart('ai_sit_idle');
		} elsif (!$chars[$config{'char'}]{'sitting'} && checkTimeOut('ai_sit_idle') && !$shop{'opened'}) {

			if ($config{'shopAuto_open'}) {
##				sendLook(\$remote_socket, 4, 0);
##				sleep(1);
				sendShopOpen(\$remote_socket);

#				sit();

#				unshift @ai_seq, "shopauto";
#				unshift @ai_seq_args, {};

			} else {
				sit();
			}

		}
	}

	if ($ai_seq[0] eq "sitting") {
		if ($chars[$config{'char'}]{'sitting'} || $chars[$config{'char'}]{'skills'}{'NV_BASIC'}{'lv'} < 3) {
			shift @ai_seq;
			shift @ai_seq_args;
			$timeout{'ai_sit'}{'time'} -= $timeout{'ai_sit'}{'timeout'};
		} elsif (!$chars[$config{'char'}]{'sitting'} && checkTimeOut('ai_sit') && checkTimeOut('ai_sit_wait')) {

			if ($warp{'use'} != 26 && $config{'teleportAuto_onSitting'} && $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} > 0) {
				sendSkillUse(\$remote_socket, $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'ID'}, $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'}, $accountID);
#				sleep(0.1);
			}

			sendSit(\$remote_socket);
			timeOutStart('ai_sit');
		}
	}

	if ($ai_seq[0] eq "standing"){
		if (!$chars[$config{'char'}]{'sitting'} && !$timeout{'ai_stand_wait'}{'time'}) {
			timeOutStart('ai_stand_wait');
		} elsif (!$chars[$config{'char'}]{'sitting'} && checkTimeOut('ai_stand_wait')) {
			shift @ai_seq;
			shift @ai_seq_args;
			undef $timeout{'ai_stand_wait'}{'time'};
			$timeout{'ai_sit'}{'time'} -= $timeout{'ai_sit'}{'timeout'};
		} elsif ($chars[$config{'char'}]{'sitting'} && checkTimeOut('ai_sit')) {
			sendStand(\$remote_socket);
			timeOutStart('ai_sit');
		}
	}

	if ($ai_v{'sitAuto_forceStop'} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_hp_lower'} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_sp_lower'}) {
		$ai_v{'sitAuto_forceStop'} = 0;
	}

	if (
		!$ai_v{'sitAuto_forceStop'}
		&& switchInput($ai_seq[0], "", "follow", "route", "route_getRoute", "route_getMapRoute")
		&& !ai_getAggressives()
		&& percent_weight(\%{$chars[$config{'char'}]}) < 50
		&& (
			percent_hp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_hp_lower'}
			|| percent_sp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_sp_lower'}
		)
		&& binFind(\@ai_seq, "attack") eq ""
		&& binFind(\@ai_seq, "talkAuto") eq ""
		&& binFind(\@ai_seq, "storageAuto") eq ""
		&& binFind(\@ai_seq, "sellAuto") eq ""
		&& binFind(\@ai_seq, "buyAuto") eq ""
	) {
		if (percent_hp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_hp_lower'}) {
			$ai_v{'sitAuto_triggerBy'} = 1;
		} elsif (percent_sp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_sp_lower'}) {
			$ai_v{'sitAuto_triggerBy'} = 2;
		} elsif (percent_hp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_hp_lower'} && percent_sp(\%{$chars[$config{'char'}]}) < $config{'sitAuto_sp_lower'}) {
			$ai_v{'sitAuto_triggerBy'} = 3;
		}
		unshift @ai_seq, "sitAuto";
		unshift @ai_seq_args, {};
		print "Auto-sitting\n" if ($config{'debug'});
	}

	if ($ai_seq[0] eq "sitAuto" && ($config{'sitAuto_stopWhenHit'} && $sc_v{'ai'}{'onHit'})) {
		shift @ai_seq;
		shift @ai_seq_args;
		if ($chars[$config{'char'}]{'sitting'}) {
			stand();
		}
	}

	if ($ai_seq[0] eq "sitAuto" && !$chars[$config{'char'}]{'sitting'} && $chars[$config{'char'}]{'skills'}{'NV_BASIC'}{'lv'} >= 3 && !(ai_getAggressives() && $sc_v{'ai'}{'onHit'})) {
		sit();
	}

	if (
		$ai_seq[0] eq "sitAuto"
		&& (
			$ai_v{'sitAuto_forceStop'}
			|| (
				$ai_v{'sitAuto_triggerBy'} == 1
				&& percent_hp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_hp_upper'}
				|| $ai_v{'sitAuto_triggerBy'} == 2
				&& percent_sp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_sp_upper'}
				|| $ai_v{'sitAuto_triggerBy'} == 3
				&& percent_hp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_hp_upper'}
				&& percent_sp(\%{$chars[$config{'char'}]}) >= $config{'sitAuto_sp_upper'}
			)
		)
	) {
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$config{'sitAuto_idle'} && $chars[$config{'char'}]{'sitting'}) {
			stand();
		}
	}
}

sub ai_event_autoEquip {
	##### AUTO-EQUIP CHANGE #####

	if (
		(
			switchInput($ai_seq[0]
				, ""
				, "route"
				, "route_getRoute"
				, "route_getMapRoute"
				, "sitAuto"
				, "attack"
				, "skill_use"
			)
			|| ($ai_seq[0] eq "skill_use" && !$ai_seq_args[0]{'skill_used'})
		)
		&& checkTimeOut('ai_equip_auto')
	) {

		my $ai_index_attack = binFind(\@ai_seq, "attack");
		my $ai_index_skill_use = binFind(\@ai_seq, "skill_use");
#		ai_equip($ai_index_attack, $ai_index_skill_use, 0);
		ai_equip($ai_index_attack, $ai_index_skill_use, $sc_v{'ai'}{'first'});

		timeOutStart('ai_equip_auto');

	}
}

sub ai_event_skills_use {
	##### SKILL USE #####

	return 0 if ($ai_seq[0] ne "skill_use");

	if ($ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_skill_use_minCastTime'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_skill_use_maxCastTime'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}

	if (
		!$ai_seq_args[0]{'suspended'}
		&& $config{'attackAuto_checkSkills'}
		&& $ai_seq_args[0]{'skill_use_target'} ne $accountID
		&& $ai_seq_args[0]{'skill_used'}
		&& !$ai_seq_args[0]{'skill_success'}
		&& timeOut(\%{$ai_seq_args[0]{'ai_skill_use_giveup'}})
	) {

#		print "$ai_seq_args[0]{'skill_used'} - $ai_v{'temp'}{'castWait'} - $chars[$config{'char'}]{'time_cast'} - $ai_seq_args[0]{'ai_skill_use_giveup'}{'timeout'} - ".timeOut(\%{$ai_seq_args[0]{'ai_skill_use_giveup'}})."\n";

		if (!$ai_seq_args[0]{'skill_use_first'}) {

			my $tmpMsg = "★嘗試施展技能逾時 - 可能卡點 ";
			my $tmpCheck = 1;

#			if ($ai_v{'useParty_skill'} ne "") {
#				$tmpCheck = 0;
#			} els
			if (%{$monsters{$ai_seq_args[0]{'skill_use_target'}}}) {
				if (
					$config{'attackAuto_checkSkills'} eq "1"
					&& (
						$monsters{$ai_seq_args[0]{'skill_use_target'}}{'dmgFromYou'} > 0
						|| $monsters{$ai_seq_args[0]{'skill_use_target'}}{'missedFromYou'} > 0
#						|| $monsters{$ai_v{'ai_attack_ID'}}{'dmgFromYou'} > 0
#						|| $monsters{$ai_v{'ai_attack_ID'}}{'missedFromYou'} > 0
					)
				) {

#					$tmpCheck = 0;
					undef $tmpCheck;

					ai_shift();

				} else {

					$monsters{$ai_seq_args[0]{'skill_use_target'}}{'attack_failed'}++ if (binFind(\@MVPID, $monsters{$ai_seq_args[0]{'skill_use_target'}}{'nameID'}) eq "");

					$tmpMsg .= "目標 $monsters{$ai_seq_args[0]{'skill_use_target'}}{'name'} ($monsters{$ai_seq_args[0]{'skill_use_target'}}{'binID'})";

					$tmpMsg .= " ".getMsgStrings('0080', $monsters{$ai_seq_args[0]{'skill_use_target'}}{'0080'}, 0, 2) if ($monsters{$ai_seq_args[0]{'skill_use_target'}}{'0080'} ne "");

				}
			} elsif (%{$monsters_old{$ai_seq_args[0]{'skill_use_target'}}}) {
#				$monsters_old{$ai_seq_args[0]{'skill_use_target'}}{'attack_failed'}++ if (binFind(\@MVPID, $monsters{$ai_seq_args[0]{'skill_use_target'}}{'nameID'}) eq "");

				$tmpMsg .= "目標 $monsters_old{$ai_seq_args[0]{'skill_use_target'}}{'name'} ($monsters_old{$ai_seq_args[0]{'skill_use_target'}}{'binID'})";

				$tmpMsg .= " ".getMsgStrings('0080', $monsters_old{$ai_seq_args[0]{'skill_use_target'}}{'0080'}, 0, 2) if ($monsters_old{$ai_seq_args[0]{'skill_use_target'}}{'0080'} ne "");

				$monsters_old{$ai_seq_args[0]{'skill_use_target'}}{'attack_failed'}++ if (binFind(\@MVPID, $monsters_old{$ai_seq_args[0]{'skill_use_target'}}{'nameID'}) eq "");

#				undef $tmpCheck;
				$tmpCheck = -1;

			} elsif ($ai_seq_args[0]{'skill_use_target_x'} ne "" && $ai_seq_args[0]{'skill_use_target_y'} ne "") {
				$tmpMsg .= " 座標 ($ai_seq_args[0]{'skill_use_target_x'}, $ai_seq_args[0]{'skill_use_target_y'})";

				if ($ai_seq_args[0]{'skill_use_type'} eq "attack" && %{$monsters{$ai_v{'ai_attack_ID'}}}) {
#					$monsters{$ai_v{'ai_attack_ID'}}
					$monsters{$ai_v{'ai_attack_ID'}}{'attack_failed'}++ if (binFind(\@MVPID, $monsters{$ai_v{'ai_attack_ID'}}{'nameID'}) eq "");
				}
			} elsif (%{$players{$ai_seq_args[0]{'skill_use_target'}}}) {
#				undef $tmpCheck;

				$tmpMsg .= "目標 $players{$ai_seq_args[0]{'skill_use_target'}}{'name'} ($players{$ai_seq_args[0]{'skill_use_target'}}{'binID'})";

				$tmpMsg .= " ".getMsgStrings('0080', $players{$ai_seq_args[0]{'skill_use_target'}}{'0080'}, 0, 2) if ($players{$ai_seq_args[0]{'skill_use_target'}}{'0080'} ne "");

#				printC("$tmpMsg\n", "alert");

				$players{$ai_seq_args[0]{'skill_use_target'}}{'skills_failed'}++;

				$tmpCheck = -1;

			} elsif (%{$players_old{$ai_seq_args[0]{'skill_use_target'}}}) {
#				$monsters_old{$ai_seq_args[0]{'skill_use_target'}}{'attack_failed'}++ if (binFind(\@MVPID, $monsters{$ai_seq_args[0]{'skill_use_target'}}{'nameID'}) eq "");

				$tmpMsg .= "目標 $players_old{$ai_seq_args[0]{'skill_use_target'}}{'name'} ($players_old{$ai_seq_args[0]{'skill_use_target'}}{'binID'})";

				$tmpMsg .= " ".getMsgStrings('0080', $players_old{$ai_seq_args[0]{'skill_use_target'}}{'0080'}, 0, 2) if ($players_old{$ai_seq_args[0]{'skill_use_target'}}{'0080'} ne "");

				$players_old{$ai_seq_args[0]{'skill_use_target'}}{'skills_failed'}++;

				$tmpCheck = -1;

#				undef $tmpCheck;
#				printC("$tmpMsg\n", "alert");

			} else {
				$tmpMsg .= "不明原因";
			}

#			parseInput("ai");

			if ($tmpCheck) {
				printC("$tmpMsg\n", "alert");

				shift @ai_seq;
				shift @ai_seq_args;

#				my $ai_index = binFind(\@ai_seq, "attack");
#				$ai_seq_args[$ai_index]{'ai_attack_giveup'}{'time'} -= $ai_seq_args[$ai_index]{'ai_attack_giveup'}{'timeout'} if ($ai_index ne "");

#				timeOutStart(
#					 'ai_teleport_search'
#					,'ai_teleport_idle'
#				);
				timeOutStart(
					'ai_teleport_idle'
				);

				if ($tmpCheck > 0) {
					aiRemove("attack") if ($config{'attackAuto_checkSkills'} > 1 || 1);
				} elsif ($tmpCheck < 0) {
					timeOutStart('ai_skill_party_wait') if ($ai_seq_args[0]{'skill_use_type'} eq "party");
					timeOutStart('ai_skill_guild_wait') if ($ai_seq_args[0]{'skill_use_type'} eq "guild");
					timeOutStart('ai_resurrect_wait') if ($ai_seq_args[0]{'skill_use_type'} eq "resurrect");
				}
			}

		} else {
#			$ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} = time;
			if ($ai_v{'temp'}{'castWait'}) {
				$ai_seq_args[0]{'ai_skill_use_giveup'}{'timeout'} += $ai_v{'temp'}{'castWait'} + 0.5;
			} else {
				$ai_seq_args[0]{'ai_skill_use_giveup'}{'timeout'} += 0.5;
#				$ai_seq_args[0]{'ai_skill_use_giveup'}{'timeout'} += 1;
#				$ai_seq_args[0]{'ai_skill_use_giveup'}{'timeout'} += $timeout{'ai_skill_use_giveup'}{'timeout'};
			}

			$ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} = time;

#			ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} = time;

#			if ($ai_seq_args[0]{'skill_use_first'} < 0) {
#				undef $ai_seq_args[0]{'skill_use_first'};
##				$ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} = time;
#			} elsif ($ai_seq_args[0]{'skill_use_first'} > 0) {
#				$ai_seq_args[0]{'skill_use_first'} = -1;
#			}

			undef $ai_seq_args[0]{'skill_use_first'};
		}
	}

	return 0 if ($ai_seq[0] ne "skill_use");

	if ($chars[$config{'char'}]{'sitting'}) {
		ai_setSuspend(0);
		stand();
	} elsif (!$ai_seq_args[0]{'skill_used'}) {
		if ($ai_seq_args[0]{'skill_use_target_x'} ne "") {
			sendSkillUseLoc(\$remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target_x'}, $ai_seq_args[0]{'skill_use_target_y'});
		} else {
			sendSkillUse(\$remote_socket, $ai_seq_args[0]{'skill_use_id'}, $ai_seq_args[0]{'skill_use_lv'}, $ai_seq_args[0]{'skill_use_target'});
		}
		$ai_seq_args[0]{'skill_used'} = 1;
		$ai_seq_args[0]{'ai_skill_use_giveup'}{'time'} = time;
		$ai_seq_args[0]{'skill_use_last'} = $chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$ai_seq_args[0]{'skill_use_id'}})}}{'time_used'};
#Pino Start(控制發送attack)
		undef $timeout{'ai_attack'}{'time'} if (!$config{'attackAuto_unLock'});
#Pino End
	} elsif (
		(
			$ai_seq_args[0]{'skill_use_last'} != $chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$ai_seq_args[0]{'skill_use_id'}})}}{'time_used'}

			|| $ai_seq_args[0]{'skill_success'}

			|| (
				timeOut(\%{$ai_seq_args[0]{'ai_skill_use_giveup'}})
				&&
				(
					!$chars[$config{'char'}]{'time_cast'}
					||
					!$ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'}
				)
			)
			|| (
				$ai_seq_args[0]{'skill_use_maxCastTime'}{'timeout'}
				&&
				timeOut(\%{$ai_seq_args[0]{'skill_use_maxCastTime'}})
			)
		)
		&& timeOut(\%{$ai_seq_args[0]{'skill_use_minCastTime'}})
	) {
		$chars[$config{'char'}]{'last_skill_used'} = "";
		$chars[$config{'char'}]{'last_skill_target'} = "";

		shift @ai_seq;
		shift @ai_seq_args;
	}
}

sub ai_event_items_take {
	##### ITEMS TAKE #####

	return 0 if ($ai_seq[0] ne "items_take");

	if ($ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_items_take_start'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		$ai_seq_args[0]{'ai_items_take_end'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
#	if (!$config{'itemsGreedyMode'} && (percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'} || percent_weight(\%{$chars[$config{'char'}]}) >= 89)) {
	if (!$config{'itemsGreedyMode'} && &getItemsMaxWeight()) {
		shift @ai_seq;
		shift @ai_seq_args;
		ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
	} elsif ($config{'itemsTakeAuto'} && timeOut(\%{$ai_seq_args[0]{'ai_items_take_start'}})) {
		undef $ai_v{'temp'}{'foundID'};
		undef $ai_v{'temp'}{'itemsPickup'};

		foreach (@itemsID) {

			$ai_v{'temp'}{'itemsPickup'} = $itemsPickup{lc($items{$_}{'name'})};
#			$record{'importantItems'}{$items{$_}{'nameID'}}

			next if (
				$_ eq ""
#				|| $ai_v{'temp'}{'itemsPickup'} < 0
#				|| $itemsPickup{lc($items{$_}{'name'})} eq "0"
#				|| ($itemsPickup{'all'} eq "0" && !$itemsPickup{lc($items{$_}{'name'})})

				|| (
					sc_isTrue2($ai_v{'temp'}{'itemsPickup'}, $itemsPickup{'all'}) <= 0
					&& $record{'importantItems'}{$items{$_}{'nameID'}} <= 0
				)

#				|| !(
#					ks_isTrue($ai_v{'temp'}{'itemsPickup'}, $itemsPickup{'all'})
#					|| $record{'importantItems'}{$items{$_}{'nameID'}}
#				)
			);

#			print "$ai_seq[0]: $items{$_}{'name'} = ".sc_isTrue2($ai_v{'temp'}{'itemsPickup'}, $itemsPickup{'all'})."\n";

			$ai_v{'temp'}{'dist'} = distance(\%{$items{$_}{'pos'}}, \%{$ai_seq_args[0]{'pos'}});
			$ai_v{'temp'}{'dist_to'} = distance(\%{$items{$_}{'pos'}}, \%{$ai_seq_args[0]{'pos_to'}});
			if (($ai_v{'temp'}{'dist'} <= 4 || $ai_v{'temp'}{'dist_to'} <= 4) && $items{$_}{'take_failed'} == 0) {
				$ai_v{'temp'}{'foundID'} = $_;
				last;
			}
		}
		if ($ai_v{'temp'}{'foundID'}) {
			$ai_seq_args[0]{'ai_items_take_end'}{'time'} = time;
			$ai_seq_args[0]{'started'} = 1;

			if ($ai_v{'temp'}{'itemsPickup'} < 3) {
				if ($record{'importantItems'}{$items{$_}{'nameID'}}) {
					$ai_v{'temp'}{'itemsPickup'} = 1;
				} else {
					$ai_v{'temp'}{'itemsPickup'} = 0;
				}
			}

			take($ai_v{'temp'}{'foundID'}, $ai_v{'temp'}{'itemsPickup'});
		} elsif ($ai_seq_args[0]{'started'} || timeOut(\%{$ai_seq_args[0]{'ai_items_take_end'}})) {
			shift @ai_seq;
			shift @ai_seq_args;
			ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
		}
	}
}

sub ai_event_take {
	##### TAKE #####

	return 0 if ($ai_seq[0] ne "take");

	if ($ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_take_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}

	if (!%{$items{$ai_seq_args[0]{'ID'}}}) {

		shift @ai_seq;
		shift @ai_seq_args;

	} elsif (timeOut(\%{$ai_seq_args[0]{'ai_take_giveup'}})) {
		$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});

		print "撿取物品: $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) 失敗 $ai_seq_args[0]{'send'} 次 - Dist: $ai_v{'temp'}{'dist'} - $ai_seq_args[0]{'ai_take_giveup'}{'timeout'}\n";
		# Important item fail
		if ($ai_v2{'ImportantItem'}{'attackAuto'} ne "") {
			shift @{$ai_v2{'ImportantItem'}{'targetID'}};
			if (!binSize(\@{$ai_v2{'ImportantItem'}{'targetID'}})) {
				$config{'attackAuto'} = $ai_v2{'ImportantItem'}{'attackAuto'};
				undef %{$ai_v2{'ImportantItem'}};
			}
		}
		$items{$ai_seq_args[0]{'ID'}}{'take_failed'}++;

		sendTake(\$remote_socket, $ai_seq_args[0]{'ID'}) if ($config{'itemsGreedyMode'} && !$ai_seq_args[0]{'send'} && $ai_v{'temp'}{'dist'} <= $config{'itemsTakeDist'});

		shift @ai_seq;
		shift @ai_seq_args;

	} else {

		$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});

		if ($chars[$config{'char'}]{'sitting'}) {
			stand();
		} elsif ($ai_v{'temp'}{'dist'} > $config{'itemsTakeDist'}) {
			getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'dist'} - 1);
			# Check field before move
			undef @{$ai_v{'temp'}{'nine'}};
			while (ai_route_getOffset(\%field, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'})) {
				$ai_v{'temp'}{'pos'}{'x'} = $items{$ai_seq_args[0]{'ID'}}{'pos'}{'x'} + int(rand() * 3) - 1;
				$ai_v{'temp'}{'pos'}{'y'} = $items{$ai_seq_args[0]{'ID'}}{'pos'}{'y'} + int(rand() * 3) - 1;
				$ai_v{'temp'}{'nine'}[getNinePos(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$ai_v{'temp'}{'pos'}})] = 1;
				last if (getNinePosFull(\@{$ai_v{'temp'}{'nine'}}));
			}
			move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, "take");
#			sendTake(\$remote_socket, $ai_seq_args[0]{'ID'}) if ($ai_v{'temp'}{'dist'} <= 5);
		} elsif (checkTimeOut('ai_take')) {
			$ai_seq_args[0]{'send'}++;
			$sc_v{'temp'}{'takeNameID'} = $items{$ai_seq_args[0]{'ID'}}{'nameID'};
			sendTake(\$remote_socket, $ai_seq_args[0]{'ID'});
			timeOutStart('ai_take');
		}
	}
}

sub ai_event_move {
	##### MOVE #####

	return 0 if ($ai_seq[0] ne "move");

	if ($ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_move_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}

	if (!$ai_seq_args[0]{'ai_moved'} && $ai_seq_args[0]{'ai_moved_tried'} && $ai_seq_args[0]{'ai_move_time_last'} != $chars[$config{'char'}]{'time_move'}) {
		$ai_seq_args[0]{'ai_moved'} = 1;
	}
	if ($chars[$config{'char'}]{'sitting'}) {
		ai_setSuspend(0);
		stand();
	} elsif (!$ai_seq_args[0]{'ai_moved'} && timeOut(\%{$ai_seq_args[0]{'ai_move_giveup'}})) {
#Karasu Start
		# Avoid stuck
		$ai_v{'avoidStuck'}{'move_failed'}++;
		avoidStuck();
#Karasu End
		shift @ai_seq;
		shift @ai_seq_args;

		my $ai_index = binFind(\@ai_seq, "route");

		if ($ai_index ne "" && %{$ai_seq_args[$ai_index]{'mapSolution'}[$ai_seq_args[$ai_index]{'mapIndex'}]{'npc'}}) {
			timeOutStart('ai_route_npcTalk');
#			print "move route npc\n";
		}
	} elsif (!$ai_seq_args[0]{'ai_moved_tried'}) {
		print "Test: 送出移動至(".int($ai_seq_args[0]{'move_to'}{'x'}).", ".int($ai_seq_args[0]{'move_to'}{'y'}).")\n" if ($config{'debug_move'});
		sendMove(\$remote_socket, int($ai_seq_args[0]{'move_to'}{'x'}), int($ai_seq_args[0]{'move_to'}{'y'}));
		$ai_seq_args[0]{'ai_move_giveup'}{'time'} = time;
		$ai_seq_args[0]{'ai_move_time_last'} = $chars[$config{'char'}]{'time_move'};
		$ai_seq_args[0]{'ai_moved_tried'} = 1;
	} elsif ($ai_seq_args[0]{'ai_moved'} && time - $chars[$config{'char'}]{'time_move'} >= $chars[$config{'char'}]{'time_move_calc'}) {
#Karasu Start
		# Avoid stuck
		undef %{$ai_v{'avoidStuck'}};
#Karasu End
		shift @ai_seq;
		shift @ai_seq_args;

		my $ai_index = binFind(\@ai_seq, "route");

		if ($ai_index ne "" && %{$ai_seq_args[$ai_index]{'mapSolution'}[$ai_seq_args[$ai_index]{'mapIndex'}]{'npc'}}) {
			timeOutStart('ai_route_npcTalk');
#			print "move route npc\n";
		}
	}
}

sub ai_event_items_gather {
	##### ITEMS AUTO-GATHER #####

#	if (switchInput($ai_seq[0], "", "follow", "route", "route_getRoute", "route_getMapRoute") && $config{'itemsGatherAuto'} && !(percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}) && checkTimeOut('ai_items_gather_auto')) {
	if (
		$config{'itemsGatherAuto'}
		&& !(&getItemsMaxWeight())
		&& checkTimeOut('ai_items_gather_auto')
		&& switchInput($ai_seq[0], "", "follow", "route", "route_getRoute", "route_getMapRoute")
	) {
		undef @{$ai_v{'ai_items_gather_foundIDs'}};

		foreach (@playersID) {
			next if ($_ eq "");
			if (!%{$chars[$config{'char'}]{'party'}} || !%{$chars[$config{'char'}]{'party'}{'users'}{$_}}) {
				push @{$ai_v{'ai_items_gather_foundIDs'}}, $_;
			}
		}

		foreach $item (@itemsID) {
			$ai_v{'temp'}{'itemsPickup'} = $itemsPickup{lc($items{$item}{'name'})};

			next if (
				$item eq ""
				|| time - $items{$item}{'appear_time'} < $timeout{'ai_items_gather_start'}{'timeout'}
				|| $items{$item}{'take_failed'} >= 1
#				|| $itemsPickup{lc($items{$item}{'name'})} < 0
#				|| $itemsPickup{lc($items{$item}{'name'})} eq "0" || (!$itemsPickup{'all'} && !$itemsPickup{lc($items{$item}{'name'})})
#
#				|| !ks_isTrue($itemsPickup{lc($items{$item}{'name'})}, $itemsPickup{'all'})

				|| (
					sc_isTrue2($ai_v{'temp'}{'itemsPickup'}, $itemsPickup{'all'}) <= 0
					&& $record{'importantItems'}{$items{$item}{'nameID'}} <= 0
				)
			);

#			print "items_gather: $items{$item}{'name'} = ".sc_isTrue2($ai_v{'temp'}{'itemsPickup'}, $itemsPickup{'all'})."\n";

			undef $ai_v{'temp'}{'dist'};
			undef $ai_v{'temp'}{'found'};
			foreach (@{$ai_v{'ai_items_gather_foundIDs'}}) {
				$ai_v{'temp'}{'dist'} = distance(\%{$items{$item}{'pos'}}, \%{$players{$_}{'pos_to'}});
				if (
					!($config{'itemsGreedyMode'} > 1 && $ai_v{'temp'}{'dist'} > 3)
					&& $ai_v{'temp'}{'dist'} < 9
				) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
			if ($ai_v{'temp'}{'found'} == 0) {
				gather($item);
				last;
			}
		}
		timeOutStart('ai_items_gather_auto');
	}

	##### ITEMS GATHER #####

	return 0 if ($ai_seq[0] ne "items_gather");

	if ($ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_items_gather_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if (!%{$items{$ai_seq_args[0]{'ID'}}}) {
		print "收集無主物品: $items_old{$ai_seq_args[0]{'ID'}}{'name'} ($items_old{$ai_seq_args[0]{'ID'}}{'binID'}) 失敗 - 物品消失！\n";
		shift @ai_seq;
		shift @ai_seq_args;
	} else {
		undef $ai_v{'temp'}{'dist'};
		undef @{$ai_v{'ai_items_gather_foundIDs'}};
		undef $ai_v{'temp'}{'found'};
		foreach (@playersID) {
			next if ($_ eq "");
			if (%{$chars[$config{'char'}]{'party'}} && !%{$chars[$config{'char'}]{'party'}{'users'}{$_}}) {
				push @{$ai_v{'ai_items_gather_foundIDs'}}, $_;
			}
		}
		foreach (@{$ai_v{'ai_items_gather_foundIDs'}}) {
			$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$players{$_}{'pos'}});
			if (
				!(
					($config{'itemsGreedyMode'} > 1 && $ai_v{'temp'}{'dist'} > 3)
					|| $config{'itemsGreedyMode'} > 2
				)
				&& $ai_v{'temp'}{'dist'} < 9
			) {
				$ai_v{'temp'}{'found'}++;
				last;
			}
		}
		$ai_v{'temp'}{'dist'} = distance(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
		if (timeOut(\%{$ai_seq_args[0]{'ai_items_gather_giveup'}})) {
			print "收集無主物品: $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) 失敗 - 逾時！ - Dist: $ai_v{'temp'}{'dist'} 格\n";
			$items{$ai_seq_args[0]{'ID'}}{'take_failed'}++;

			sendTake(\$remote_socket, $ai_seq_args[0]{'ID'}) if ($config{'itemsGreedyMode'} && $ai_v{'temp'}{'dist'} <= $config{'itemsTakeDist'});

			shift @ai_seq;
			shift @ai_seq_args;
		} elsif ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif ($ai_v{'temp'}{'found'} == 0 && $ai_v{'temp'}{'dist'} > $config{'itemsTakeDist'}) {
			getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'temp'}{'dist'} - 1);
			# Check field before move
			undef @{$ai_v{'temp'}{'nine'}};
			while (ai_route_getOffset(\%field, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'})) {
				$ai_v{'temp'}{'pos'}{'x'} = $items{$ai_seq_args[0]{'ID'}}{'pos'}{'x'} + int(rand() * 3) - 1;
				$ai_v{'temp'}{'pos'}{'y'} = $items{$ai_seq_args[0]{'ID'}}{'pos'}{'y'} + int(rand() * 3) - 1;
				$ai_v{'temp'}{'nine'}[getNinePos(\%{$items{$ai_seq_args[0]{'ID'}}{'pos'}}, \%{$ai_v{'temp'}{'pos'}})] = 1;
				last if (getNinePosFull(\@{$ai_v{'temp'}{'nine'}}));
			}
			move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
		} elsif ($ai_v{'temp'}{'found'} == 0) {
			$ai_v{'ai_items_gather_ID'} = $ai_seq_args[0]{'ID'};
			shift @ai_seq;
			shift @ai_seq_args;
			take($ai_v{'ai_items_gather_ID'}, -1);
		} elsif ($ai_v{'temp'}{'found'} > 0) {
			print "收集無主物品: $items{$ai_seq_args[0]{'ID'}}{'name'} ($items{$ai_seq_args[0]{'ID'}}{'binID'}) 失敗 - 無法掠奪！ - Dist: $ai_v{'temp'}{'dist'} 格\n";

			sendTake(\$remote_socket, $ai_seq_args[0]{'ID'}) if ($config{'itemsGreedyMode'} && $ai_v{'temp'}{'dist'} <= $config{'itemsTakeDist'});

#			$items{$ai_seq_args[0]{'ID'}}{'take_failed'}++;

			shift @ai_seq;
			shift @ai_seq_args;
		}
	}
}

sub ai_event_route {
	##### ROUTE #####

	return 0 if ($ai_seq[0] ne "route");

	ROUTE: {

	if (@{$ai_seq_args[0]{'solution'}} && $ai_seq_args[0]{'index'} == @{$ai_seq_args[0]{'solution'}} - 1 && $ai_seq_args[0]{'solutionReady'}) {
		print "Route success\n" if ($config{'debug'});
#Karasu Start
		# Avoid stuck
		undef %{$ai_v{'avoidStuck'}};
#Karasu End
		shift @ai_seq;
		shift @ai_seq_args;
#		undef $RouteFailedTimes;
	} elsif ($ai_seq_args[0]{'failed'}) {
		print "Route failed\n" if ($config{'debug'});
#Karasu Start
		# Avoid stuck
		$ai_v{'avoidStuck'}{'route_failed'}++;
		avoidStuck();
#Karasu End
		shift @ai_seq;
		shift @ai_seq_args;

	} elsif (checkTimeOut('ai_route_npcTalk')) {
		last ROUTE if (!$field{'name'});
		if ($ai_seq_args[0]{'waitingForMapSolution'}) {
			undef $ai_seq_args[0]{'waitingForMapSolution'};
			if (!@{$ai_seq_args[0]{'mapSolution'}}) {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
			$ai_seq_args[0]{'mapIndex'} = -1;
		}
		if ($ai_seq_args[0]{'waitingForSolution'}) {
			undef $ai_seq_args[0]{'waitingForSolution'};
			if ($ai_seq_args[0]{'distFromGoal'} && $field{'name'} && $ai_seq_args[0]{'dest_map'} eq $field{'name'}
				&& (!@{$ai_seq_args[0]{'mapSolution'}} || $ai_seq_args[0]{'mapIndex'} == @{$ai_seq_args[0]{'mapSolution'}} - 1)) {
				for ($i = 0; $i < $ai_seq_args[0]{'distFromGoal'}; $i++) {
					pop @{$ai_seq_args[0]{'solution'}};
				}
				if (@{$ai_seq_args[0]{'solution'}}) {
					$ai_seq_args[0]{'dest_x_original'} = $ai_seq_args[0]{'dest_x'};
					$ai_seq_args[0]{'dest_y_original'} = $ai_seq_args[0]{'dest_y'};
					$ai_seq_args[0]{'dest_x'} = $ai_seq_args[0]{'solution'}[@{$ai_seq_args[0]{'solution'}}-1]{'x'};
					$ai_seq_args[0]{'dest_y'} = $ai_seq_args[0]{'solution'}[@{$ai_seq_args[0]{'solution'}}-1]{'y'};
				}
			}
			$ai_seq_args[0]{'returnHash'}{'solutionLength'} = @{$ai_seq_args[0]{'solution'}};
			$ai_seq_args[0]{'returnHash'}{'solutionTime'} = time - $ai_seq_args[0]{'time_getRoute'};
			if ($ai_seq_args[0]{'maxRouteDistance'} && @{$ai_seq_args[0]{'solution'}} > $ai_seq_args[0]{'maxRouteDistance'}) {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
			if (!@{$ai_seq_args[0]{'solution'}} && !@{$ai_seq_args[0]{'mapSolution'}} && $ai_seq_args[0]{'dest_map'} eq $field{'name'} && $ai_seq_args[0]{'checkInnerPortals'} && !$ai_seq_args[0]{'checkInnerPortals_done'}) {
				$ai_seq_args[0]{'checkInnerPortals_done'} = 1;
				undef $ai_seq_args[0]{'solutionReady'};
				$ai_seq_args[0]{'temp'}{'pos'}{'x'} = $ai_seq_args[0]{'dest_x'};
				$ai_seq_args[0]{'temp'}{'pos'}{'y'} = $ai_seq_args[0]{'dest_y'};
				$ai_seq_args[0]{'waitingForMapSolution'} = 1;
				ai_mapRoute_getRoute(\@{$ai_seq_args[0]{'mapSolution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%field, \%{$ai_seq_args[0]{'temp'}{'pos'}}, $ai_seq_args[0]{'maxRouteTime'});
				last ROUTE;
			} elsif (!@{$ai_seq_args[0]{'solution'}}) {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
		}
		if (@{$ai_seq_args[0]{'mapSolution'}} && $ai_seq_args[0]{'mapChanged'} && $field{'name'} eq $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'dest'}{'map'}) {
			undef $ai_seq_args[0]{'mapChanged'};
			undef @{$ai_seq_args[0]{'solution'}};
			undef %{$ai_seq_args[0]{'last_pos'}};
			undef $ai_seq_args[0]{'index'};
			undef $ai_seq_args[0]{'npc'};
			undef $ai_seq_args[0]{'divideIndex'};
		}
#		if (
#			$config{'route_NPC_distance'} > 0
#			&& %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}}
#			&& $field{'name'} eq $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'map'}
#			&& distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}}) < $config{'route_NPC_distance'}
#			&& @{$ai_seq_args[0]{'mapSolution'}}
#			&& @{$ai_seq_args[0]{'solution'}}
#			&& $ai_seq_args[0]{'index'} == @{$ai_seq_args[0]{'solution'}} - 1
#			&& %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}}
#			&& $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] ne ""
#		) {
#			%{$ai_v{'temp'}{'pos'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};
#
#			printC("Target NPC Pos: ".getFormattedCoords($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'})." - Dist: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'pos'}}, 1)."\n", "white");
#		} els
		if (!@{$ai_seq_args[0]{'solution'}}) {
			if ($ai_seq_args[0]{'dest_map'} eq $field{'name'}
				&& (!@{$ai_seq_args[0]{'mapSolution'}} || $ai_seq_args[0]{'mapIndex'} == @{$ai_seq_args[0]{'mapSolution'}} - 1)) {
				$ai_seq_args[0]{'temp'}{'dest'}{'x'} = $ai_seq_args[0]{'dest_x'};
				$ai_seq_args[0]{'temp'}{'dest'}{'y'} = $ai_seq_args[0]{'dest_y'};
				$ai_seq_args[0]{'solutionReady'} = 1;
				undef @{$ai_seq_args[0]{'mapSolution'}};
				undef $ai_seq_args[0]{'mapIndex'};
			} else {
				if (!(@{$ai_seq_args[0]{'mapSolution'}})) {
					if (!%{$ai_seq_args[0]{'dest_field'}}) {
						getField("$sc_v{'path'}{'fields'}/$ai_seq_args[0]{'dest_map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
					}
					$ai_seq_args[0]{'temp'}{'pos'}{'x'} = $ai_seq_args[0]{'dest_x'};
					$ai_seq_args[0]{'temp'}{'pos'}{'y'} = $ai_seq_args[0]{'dest_y'};
					$ai_seq_args[0]{'waitingForMapSolution'} = 1;
					ai_mapRoute_getRoute(\@{$ai_seq_args[0]{'mapSolution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'dest_field'}}, \%{$ai_seq_args[0]{'temp'}{'pos'}}, $ai_seq_args[0]{'maxRouteTime'});
					last ROUTE;
				}
#Karasu Start
				# Null solution bug fix
				if (!defined $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'} + 1]{'source'}{'map'}) {
					$ai_seq_args[0]{'failed'} = 1;
					last ROUTE;
				}
#Karasu End
				if ($field{'name'} eq $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'} + 1]{'source'}{'map'}) {
					$ai_seq_args[0]{'mapIndex'}++;
#					%{$ai_seq_args[0]{'temp'}{'dest'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};
#				} else {
#					%{$ai_seq_args[0]{'temp'}{'dest'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};
				}

				#	mKore-2.05.04 //

				%{$ai_seq_args[0]{'temp'}{'dest'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};

				if (%{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}}) {

#					%{$ai_v{'temp'}{'pos'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};
#					printC("Target NPC Pos: ".getFormattedCoords($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'})." - Dist: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'pos'}}, 1)."\n", "white");

					ai_getRandPosInCenter(
						$ai_seq_args[0]{'temp'}{'dest'}
						, $field{'name'}
						, $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}
						, {'dist' => $config{'route_NPC_distance'}, 'min' => 1}
						, 0
					);
				}

				#	// mKore-2.05.04
			}
			if ($ai_seq_args[0]{'temp'}{'dest'}{'x'} eq "") {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
			$ai_seq_args[0]{'waitingForSolution'} = 1;
			$ai_seq_args[0]{'time_getRoute'} = time;
			ai_route_getRoute(\@{$ai_seq_args[0]{'solution'}}, \%field, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_seq_args[0]{'temp'}{'dest'}}, $ai_seq_args[0]{'maxRouteTime'});
			last ROUTE;
		}
		if (
			@{$ai_seq_args[0]{'mapSolution'}}
			&& @{$ai_seq_args[0]{'solution'}}
			&& $ai_seq_args[0]{'index'} == @{$ai_seq_args[0]{'solution'}} - 1
			&& %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}}
		) {
			if ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] ne "") {

#				print "autoTalkStep: $ai_seq_args[0]{'npc'}{'step'} - $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}]\n";

				if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {

#					undef $ai_seq_args[0]{'npc'}{'step'};
					$ai_seq_args[0]{'npc'}{'step'} = 0;

					if ($config{'autoRoute_npcChoice'} || switchInput($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}, "<npc>", "<auto>", "auto")) {
						undef $ai_v{'temp'}{'nearest_npc_id'};

						$ai_v{'temp'}{'nearest_distance'} = 9999;

						%{$ai_v{'temp'}{'pos'}} = %{$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'source'}{'pos'}};

						for ($i = 0; $i < @npcsID; $i++) {
							next if ($npcsID[$i] eq "");
							$ai_v{'temp'}{'distance'} = distance(\%{$npcs{$npcsID[$i]}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, 1);

#							print "$npcs{$npcsID[$i]}{'name'} : $ai_v{'temp'}{'distance'}\n";

							if (
								$npcs{$npcsID[$i]}{'pos'}{'x'} == $ai_v{'temp'}{'pos'}{'x'}
								&& $npcs{$npcsID[$i]}{'pos'}{'y'} == $ai_v{'temp'}{'pos'}{'y'}
							) {
#								$ai_v{'temp'}{'nearest_npc_id'} = $npcs{$npcsID[$i]}{'nameID'};

								$ai_v{'temp'}{'nearest_npc_id'} = $npcsID[$i];

								last;
							}
						}

						if ($ai_v{'temp'}{'nearest_npc_id'} eq "") {
							for ($i = 0; $i < @npcsID; $i++) {
								next if ($npcsID[$i] eq "");
#								$ai_v{'temp'}{'distance'} = distance(\%{$npcs{$npcsID[$i]}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
#								$ai_v{'temp'}{'distance'} = distance(\%{$npcs{$npcsID[$i]}{'pos'}}, \%{$ai_seq_args[0]{'temp'}{'pos'}});

								$ai_v{'temp'}{'distance'} = distance(\%{$npcs{$npcsID[$i]}{'pos'}}, \%{$ai_v{'temp'}{'pos'}}, 1);

#								print "$npcs{$npcsID[$i]}{'name'} : $ai_v{'temp'}{'distance'}\n";

								if ($ai_v{'temp'}{'distance'} < $ai_v{'temp'}{'nearest_distance'}) {
#									$ai_v{'temp'}{'nearest_npc_id'} = $npcs{$npcsID[$i]}{'nameID'};
									$ai_v{'temp'}{'nearest_npc_id'} = $npcsID[$i];
									$ai_v{'temp'}{'nearest_distance'} = $ai_v{'temp'}{'distance'};
								}
							}
						}

						if ($ai_v{'temp'}{'nearest_npc_id'} ne "") {
#							$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'} = $ai_v{'temp'}{'nearest_npc_id'};
							$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'} = $npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'nameID'};

							printC("Target NPC Pos: ".getFormattedCoords($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'})."\n", "white");
							printC("Found nearest NPC: $npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'nameID'} $npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'name'} ($npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'binID'}) ".getFormattedCoords($npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'pos'}{'x'}, $npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'pos'}{'y'})." - Dist: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'pos'}}, 1)."\n", "white");

						} else {
							# Not found nearest NPC, cancel all steps.
							$ai_seq_args[0]{'npc'}{'step'} = 9999;
							printC("[ROUTE] 錯誤: 找不到 NPC 接近 ".getFormattedCoords($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'})." 該 NPC 可能被移除\n", "alert");
						}
					}

					sendTalk(\$remote_socket, pack("L1", $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
					$ai_seq_args[0]{'npc'}{'sentTalk'} = 1;
				} elsif ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
					sendTalkContinue(\$remote_socket, pack("L1", $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
					$ai_seq_args[0]{'npc'}{'step'}++;
#Karasu Start(portals.txt新增語法n)
				} elsif ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
					#sendTalkCancel(\$remote_socket, pack("L1", $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}));
					$ai_seq_args[0]{'npc'}{'step'}++;
#Karasu End(portals.txt新增語法n)
#Ayon Start(portals.txt新增語法a?)
				} elsif ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i) {
					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i;
					if ($ai_v{'temp'}{'arg'} ne "") {
						sendTalkAnswerNum(\$remote_socket, pack("L1", $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}), $ai_v{'temp'}{'arg'});
					}
					$ai_seq_args[0]{'npc'}{'step'}++;
				} elsif ($ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i) {
					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i;
					if ($ai_v{'temp'}{'arg'} ne "") {
						sendTalkAnswerWord(\$remote_socket, pack("L1", $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}), $ai_v{'temp'}{'arg'});
					}
					$ai_seq_args[0]{'npc'}{'step'}++;
#Ayon End(portals.txt新增語法a?)
				} else {
					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
					if ($ai_v{'temp'}{'arg'} ne "") {
						$ai_v{'temp'}{'arg'}++;
						sendTalkResponse(\$remote_socket, pack("L1", $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'}), $ai_v{'temp'}{'arg'});
					}
					$ai_seq_args[0]{'npc'}{'step'}++;
				}
				timeOutStart('ai_route_npcTalk');
				last ROUTE;
			} elsif (0 && $ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'} ne "" && $ai_v{'temp'}{'nearest_npc_id'} ne "") {
				$ai_seq_args[0]{'mapSolution'}[$ai_seq_args[0]{'mapIndex'}]{'npc'}{'ID'} = "<auto>";
			}
		}
		if ($ai_seq_args[0]{'mapChanged'}) {
			$ai_seq_args[0]{'failed'} = 1;
			last ROUTE;

		} elsif (%{$ai_seq_args[0]{'last_pos'}}
			&& $chars[$config{'char'}]{'pos_to'}{'x'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}
			&& $chars[$config{'char'}]{'pos_to'}{'y'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}
			&& $ai_seq_args[0]{'last_pos'}{'x'} != $chars[$config{'char'}]{'pos_to'}{'x'}
			&& $ai_seq_args[0]{'last_pos'}{'y'} != $chars[$config{'char'}]{'pos_to'}{'y'}) {

			if ($ai_seq_args[0]{'dest_x_original'} ne "") {
				$ai_seq_args[0]{'dest_x'} = $ai_seq_args[0]{'dest_x_original'};
				$ai_seq_args[0]{'dest_y'} = $ai_seq_args[0]{'dest_y_original'};
			}
			undef @{$ai_seq_args[0]{'solution'}};
			undef %{$ai_seq_args[0]{'last_pos'}};
			undef $ai_seq_args[0]{'index'};
			undef $ai_seq_args[0]{'npc'};
			undef $ai_seq_args[0]{'divideIndex'};

		} else {
			if ($ai_seq_args[0]{'divideIndex'} && $chars[$config{'char'}]{'pos_to'}{'x'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}
				&& $chars[$config{'char'}]{'pos_to'}{'y'} != $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}) {

				#we're stuck!
				$ai_v{'temp'}{'index_old'} = $ai_seq_args[0]{'index'};
				$ai_seq_args[0]{'index'} -= int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
				$ai_seq_args[0]{'index'} = 0 if ($ai_seq_args[0]{'index'} < 0);
				$ai_v{'temp'}{'index'} = $ai_seq_args[0]{'index'};
				undef $ai_v{'temp'}{'done'};
				do {
					$ai_seq_args[0]{'divideIndex'}++;
					$ai_v{'temp'}{'index'} = $ai_seq_args[0]{'index'};
					$ai_v{'temp'}{'index'} += int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
					$ai_v{'temp'}{'index'} = @{$ai_seq_args[0]{'solution'}} - 1 if ($ai_v{'temp'}{'index'} >= @{$ai_seq_args[0]{'solution'}});
					$ai_v{'temp'}{'done'} = 1 if (int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'}) == 0);
				} while ($ai_v{'temp'}{'index'} >= $ai_v{'temp'}{'index_old'} && !$ai_v{'temp'}{'done'});
			} else {
				$ai_seq_args[0]{'divideIndex'} = 1;
			}


			if (int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'}) == 0) {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}

			%{$ai_seq_args[0]{'last_pos'}} = %{$chars[$config{'char'}]{'pos_to'}};

			do {
				$ai_seq_args[0]{'index'} += int($config{'route_step'} / $ai_seq_args[0]{'divideIndex'});
				$ai_seq_args[0]{'index'} = @{$ai_seq_args[0]{'solution'}} - 1 if ($ai_seq_args[0]{'index'} >= @{$ai_seq_args[0]{'solution'}});
			} while (
				$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'}
				&& $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}
				&& $ai_seq_args[0]{'index'} != @{$ai_seq_args[0]{'solution'}} - 1
			);

#Karasu Start
			#Null solution bug fix
			if (!defined $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}	|| !defined $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'}) {
				$ai_seq_args[0]{'failed'} = 1;
				last ROUTE;
			}
#Karasu End

			if ($ai_seq_args[0]{'avoidPortals'}) {
				undef $ai_v{'temp'}{'foundID'};
				undef $ai_v{'temp'}{'smallDist'};
				$ai_v{'temp'}{'first'} = 1;
				foreach (@portalsID) {
					$ai_v{'temp'}{'dist'} = distance(\%{$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]}, \%{$portals{$_}{'pos'}});
					if ($ai_v{'temp'}{'dist'} <= 7 && ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'})) {
						$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
						$ai_v{'temp'}{'foundID'} = $_;
						undef $ai_v{'temp'}{'first'};
					}
				}
				if ($ai_v{'temp'}{'foundID'}) {
					$ai_seq_args[0]{'failed'} = 1;
					last ROUTE;
				}
			}
			if (
				$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'} != $chars[$config{'char'}]{'pos_to'}{'x'}
				||
				$ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'} != $chars[$config{'char'}]{'pos_to'}{'y'}
			) {
				if($config{'modifiedWalkType'}){
					modifiedWalk($config{'modifiedWalkType'});
				}
				move($ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'x'}, $ai_seq_args[0]{'solution'}[$ai_seq_args[0]{'index'}]{'y'});
			}
		}
	}

	} #END OF ROUTE BLOCK
}

sub ai_event_auto_addPoints {
	return 0 if (!$config{'autoAddStatusOrSkill'} && (!$config{'autoAddStatusOrSkill_jobs'} || existsInList($config{'autoAddStatusOrSkill_jobs'}, $chars[$config{'char'}]{'jobID'})));

	my $timeOutName = 'ai_addAuto';
	my $idx = 0;

	if (checkTimeOut($timeOutName)){
		my $i = 0;
		my ($target, $target_now, $target_lc, $tmpValue);

		$tmpValue = 'autoAddStatus_';

		if ($config{'autoAddStatus_0'} ne "" && $chars[$config{'char'}]{'points_free'}) {
			for ($i = 0; $config{"autoAddStatus_$i"} ne ""; $i++) {
				$target = lc $config{"autoAddStatus_$i"};
				$target_now = $chars[$config{'char'}]{$target};
				if ($target_now ne "" && $target_now < 99 && $target_now < $config{"autoAddStatus_$i"."_limit"}) {
					if ($chars[$config{'char'}]{"points_$target"} <= $chars[$config{'char'}]{'points_free'}) {
						sysLog("event", "事件", "Auto-add status : $target - Now: $target_now", 1);
						parseInput("stat_add $target");
#						timeOutStart('ai_statusAuto_add');
						timeOutStart($timeOutName);

						$idx = 1;
					}
					last if ($idx || $config{'autoAddStatusOrSkill'} == 1);
				}
			}
		}

		$tmpValue = 'autoAddSkill_';

		if ($config{'autoAddSkill_0'} ne "" && $chars[$config{'char'}]{'points_skill'}) {
			for ($i = 0; $config{"autoAddSkill_$i"} ne ""; $i++) {
				$target = $config{"autoAddSkill_$i"};
				$target_lc = $skills_rlut{lc($target)};
				$target_now = $chars[$config{'char'}]{'skills'}{$target_lc}{'lv'};

				if ($target_now ne "" && $target_lc ne "" && $target_now < $config{"autoAddSkill_$i"."_limit"}) {
					sysLog("event", "事件", "Auto-add skill : $target - Now: $target_now", 1);
					sendAddSkillPoint(\$remote_socket, $chars[$config{'char'}]{'skills'}{$target_lc}{'ID'});
					timeOutStart($timeOutName);
					$idx = 1;
					last;
				}
			}
		}

		if (!$idx){
			timeOutStart(1, $timeOutName);
		}
	}
	return $idx;
}

sub ai_event_auto_attack {
	##### AUTO-ATTACK #####

	if (
		switchInput($ai_seq[0]
			, ""
			, "route"
			, "route_getRoute"
			, "route_getMapRoute"
			, "follow"
			, "sitAuto"
			, "take"
			, "items_gather"
			, "items_take"
		)
		&& !($config{'itemsTakeAuto'} >= 2 && ($ai_seq[0] eq "take" || $ai_seq[0] eq "items_take"))
		&& !($config{'itemsGatherAuto'} >= 2 && ($ai_seq[0] eq "take" || $ai_seq[0] eq "items_gather"))
		&& checkTimeOut('ai_attack_auto')
#		&& (!$config{'attackAuto_unLockOnly'} || ($config{'attackAuto_unLockOnly'} && $field{'name'} ne $config{'lockMap'}))
#		&& (!$config{'attackAuto_inLockOnly'} || ($config{'attackAuto_inLockOnly'} && $field{'name'} eq $config{'lockMap'}))
		&& (!$config{'attackAuto_unLockOnly'} || ($config{'attackAuto_unLockOnly'} && inTargetMap($field{'name'}, "", $config{'attackAuto_unLockOnly'})))
		&& (!$config{'attackAuto_inLockOnly'} || ($config{'attackAuto_inLockOnly'} && inTargetMap($field{'name'}, $config{'lockMap'}, $config{'attackAuto_inLockOnly'})))
	) {
		undef @{$ai_v{'ai_attack_agMonsters'}};
		undef @{$ai_v{'ai_attack_cleanMonsters'}};
		undef @{$ai_v{'ai_attack_partyMonsters'}};

		undef @{$ai_v{'ai_attack_stealMonsters'}};
		undef @{$ai_v{'ai_attack_takenByMonsters'}};

		undef $ai_v{'temp'}{'foundID'};
		if ($config{'tankMode'}) {
			undef $ai_v{'temp'}{'found'};
			foreach (@playersID) {
				next if ($_ eq "");
				if ($config{'tankModeTarget'} eq $players{$_}{'name'}) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
			}
		}
		if (!$config{'tankMode'} || ($config{'tankMode'} && $ai_v{'temp'}{'found'})) {
			$ai_v{'temp'}{'ai_follow_index'} = binFind(\@ai_seq, "follow");
			if ($ai_v{'temp'}{'ai_follow_index'} ne "") {
				$ai_v{'temp'}{'ai_follow_following'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'following'};
				$ai_v{'temp'}{'ai_follow_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ID'};
			} else {
				undef $ai_v{'temp'}{'ai_follow_following'};
			}
			$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
			if ($ai_v{'temp'}{'ai_route_index'} ne "") {
				$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
			}
			@{$ai_v{'ai_attack_agMonsters'}} = ai_getAggressives() if ($config{'attackAuto'} && !($ai_v{'temp'}{'ai_route_index'} ne "" && !$ai_v{'temp'}{'ai_route_attackOnRoute'}));
			foreach (@monstersID) {
				# Mon_control add "all 0|1" setup
				next if (
					$_ eq ""
					|| (
						$mon_control{'all'}{'attack_auto'} eq "0"
						&& $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq ""
					)
					|| (
						$config{'attackAuto_notParam3'}
						&& existsInList2($config{'attackAuto_notParam3'}, $monsters{$_}{'param3'}, "and")
					)
					|| (
						$config{'attackAuto_notMode'} > 0
						&& sc_getVal($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'}, $mon_control{'all'}{'attack_auto'}, 1) <= 0
						&& !($config{'attackAuto_takenBy'} && $monsters{$_}{'takenBy'})
					)
					|| !isAttackAble(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}})
				);

				if ($config{'attackAuto_takenBy'} && $monsters{$_}{'takenBy'} && $monsters{$_}{'attack_failed'} == 0) {
					push @{$ai_v{'ai_attack_takenByMonsters'}}, $_;
				} elsif ($config{'stealOnly'} > 2) {

					if (
						!$monsters{$_}{'beSteal'}
#						&& ks_isTrue($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'})
						&& sc_getVal($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'}, $mon_control{'all'}{'attack_auto'}, 1)
						&& $monsters{$_}{'attack_failed'} == 0
						&& !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)
						&& !switchInput($ai_seq[0], "sitAuto", "take", "items_gather", "items_take")
					) {
						push @{$ai_v{'ai_attack_stealMonsters'}}, $_;
					}

				} elsif (
					$config{'attackAuto_party'} > 1
					&& !switchInput($ai_seq[0], "take", "items_take")
					&& (
						$monsters{$_}{'dmgToParty'} > 0
						|| $monsters{$_}{'dmgFromParty'} > 0
						|| $monsters{$_}{'missedToParty'} > 0
						|| $monsters{$_}{'missedFromParty'} > 0
						|| $monsters{$_}{'castOnByParty'} > 0
					)
					&& !($ai_v{'temp'}{'ai_route_index'} ne "" && !$ai_v{'temp'}{'ai_route_attackOnRoute'})
					&& $monsters{$_}{'attack_failed'} == 0
#					&& ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 1 || $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "")
				) {
					push @{$ai_v{'ai_attack_partyMonsters'}}, $_;

				} elsif (
					(
						(
							$config{'attackAuto_party'}
							&& $ai_seq[0] ne "take"
							&& $ai_seq[0] ne "items_take"
							&& (
								$monsters{$_}{'dmgToParty'} > 0
								|| $monsters{$_}{'dmgFromParty'} > 0

								|| $monsters{$_}{'missedToParty'} > 0
								|| $monsters{$_}{'missedFromParty'} > 0
							)
						)
						|| (
							$config{'attackAuto_followTarget'}
							&& $ai_v{'temp'}{'ai_follow_following'}
							&& (
								$monsters{$_}{'dmgToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0
								|| $monsters{$_}{'dmgFromPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0

								|| $monsters{$_}{'missedFromPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0
								|| $monsters{$_}{'missedToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0
							)
						)
					)
					&& !(
						$ai_v{'temp'}{'ai_route_index'} ne ""
						&& !$ai_v{'temp'}{'ai_route_attackOnRoute'}
					)
					&& $monsters{$_}{'attack_failed'} == 0
					&& (
						$mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 1
						|| $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq ""
					)
				) {
					push @{$ai_v{'ai_attack_partyMonsters'}}, $_;

				} elsif (
					$config{'attackBerserk'} > 2
					&& $config{'attackAuto'} >= 2
					&& !switchInput($ai_seq[0], "sitAuto", "take", "items_gather", "items_take")
#					&& ks_isTrue($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'})
					&& sc_getVal($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'}, $mon_control{'all'}{'attack_auto'}, 1)
					&& $monsters{$_}{'attack_failed'} == 0
					&& !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)
				) {

					push @{$ai_v{'ai_attack_cleanMonsters'}}, $_;

				} elsif ($config{'attackAuto'} >= 2
					&& $ai_seq[0] ne "sitAuto" && $ai_seq[0] ne "take" && $ai_seq[0] ne "items_gather" && $ai_seq[0] ne "items_take"
					# MVP control
					&& !($monsters{$_}{'dmgFromYou'} == 0 && (binFind(\@MVPID, $monsters{$_}{'nameID'}) eq "" && ($monsters{$_}{'dmgTo'} > 0 || $monsters{$_}{'dmgFrom'} > 0 || %{$monsters{$_}{'missedFromPlayer'}} || %{$monsters{$_}{'missedToPlayer'}} || %{$monsters{$_}{'castOnByPlayer'}})))
					&& $monsters{$_}{'attack_failed'} == 0
					&& !($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)
					&& ($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} >= 1 || $mon_control{lc($monsters{$_}{'name'})}{'attack_auto'} eq "")
				) {
#Karasu Start
					# MVP control
					my $isMVP = (binFind(\@MVPID, $monsters{$_}{'nameID'}) ne "");

					if ($config{'stealOnly'} > 1) {
						if (!$monsters{$_}{'beSteal'} && !$isMVP) {
							push @{$ai_v{'ai_attack_cleanMonsters'}}, $_;
						}
					} elsif ($config{'attackBerserk'} > 1 || $isMVP) {
						push @{$ai_v{'ai_attack_cleanMonsters'}}, $_;
					} else {
						# Prevent kill steal
						my ($i, $Ankled);

						$ai_v{'temp'}{'myDist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
						undef $ai_v{'temp'}{'smallDist'};
						$ai_v{'temp'}{'first'} = 1;
						for ($i = 0; $i < @playersID; $i++) {
							next if ($playersID[$i] eq "");
							$ai_v{'temp'}{'dist'} = distance(\%{$players{$playersID[$i]}{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
							if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
								$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
								undef $ai_v{'temp'}{'first'};
							}
						}
						# Anklesnare Detection
						for ($i = 0; $i < @spellsID; $i++) {
							next if ($spellsID[$i] eq "" || $spells{$spellsID[$i]}{'type'} != 91);
							if (distance(\%{$spells{$spellsID[$i]}{'pos'}}, \%{$monsters{$_}{'pos_to'}}) <= $config{'NotAttackNearSpell'}) {
								$Ankled = 1;
								last;
							}
						}
						if (
							!$Ankled
#							&& $monsters{$_}{'param1'} != 1
#							&& $monsters{$_}{'param1'} != 2
#							&& $monsters{$_}{'param1'} != 6
							&& (
								!$monsters{$_}{'param1'}
								|| !existsInList2($config{'attackAuto_preventParam1'}, $monsters{$_}{'param1'}, "noand")
							)
							&& (
								!$config{'attackAuto_notParam3'}
								|| !existsInList2($config{'attackAuto_notParam3'}, $monsters{$_}{'param3'}, "and")
							)
							&& (
								!$ai_v{'temp'}{'smallDist'}
								|| $ai_v{'temp'}{'myDist'} <= $ai_v{'temp'}{'smallDist'}
								|| $ai_v{'temp'}{'smallDist'} > $config{'NotAttackDistance'}
							)
						) {
							push @{$ai_v{'ai_attack_cleanMonsters'}}, $_;
						}
					}
#Karasu End
				}
			}
			undef $ai_v{'temp'}{'smallDist'};
			undef $ai_v{'temp'}{'foundID'};
			$ai_v{'temp'}{'first'} = 1;

			if ($config{'stealOnly'} > 2){
				foreach (@{$ai_v{'ai_attack_agMonsters'}}) {

					next if (
						$monsters{$_}{'beSteal'} > 0
						|| !isAttackAble(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}})
					);

					$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
					if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
						$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
						$ai_v{'temp'}{'foundID'} = $_;
						undef $ai_v{'temp'}{'first'};
					}
				}
				if (!$ai_v{'temp'}{'foundID'}) {
					undef $ai_v{'temp'}{'smallDist'};
					undef $ai_v{'temp'}{'foundID'};
					$ai_v{'temp'}{'first'} = 1;
					foreach (@{$ai_v{'ai_attack_stealMonsters'}}) {
#						next if (!isAttackAble(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}));
						$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
						if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
							$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
							$ai_v{'temp'}{'foundID'} = $_;
							undef $ai_v{'temp'}{'first'};
						}
					}
				}
			} else {
				foreach (@{$ai_v{'ai_attack_takenByMonsters'}}) {
					$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
					if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
						$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
						$ai_v{'temp'}{'foundID'} = $_;
						undef $ai_v{'temp'}{'first'};
					}
				}
				if (!$ai_v{'temp'}{'foundID'}) {
					foreach (@{$ai_v{'ai_attack_agMonsters'}}) {
						next if (
							(
								$config{'attackAuto_notMode'} == 1
								&& sc_getVal($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'}, $mon_control{'all'}{'attack_auto'}) <= 0
							)
							||
							(
								$config{'attackAuto_notMode'} > 1
								&& sc_getVal($mon_control{lc($monsters{$_}{'name'})}{'attack_auto'}, $mon_control{'all'}{'attack_auto'}) < 0
							)
							|| (
								$config{'attackAuto_notParam3'}
								&& existsInList2($config{'attackAuto_notParam3'}, $monsters{$ai_seq_args[0]{'ID'}}{'param3'}, "and")
							)
							|| !isAttackAble(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}})
						);

						$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
						if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
							$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
							$ai_v{'temp'}{'foundID'} = $_;
							undef $ai_v{'temp'}{'first'};
						}
					}
				}
				if (!$ai_v{'temp'}{'foundID'}) {
					undef $ai_v{'temp'}{'smallDist'};
					undef $ai_v{'temp'}{'foundID'};
					$ai_v{'temp'}{'first'} = 1;
					foreach (@{$ai_v{'ai_attack_partyMonsters'}}) {
#						next if (!isAttackAble(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}));
						$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
						if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
							$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
							$ai_v{'temp'}{'foundID'} = $_;
							undef $ai_v{'temp'}{'first'};
						}
					}
				}
				if (!$ai_v{'temp'}{'foundID'}) {
					undef $ai_v{'temp'}{'smallDist'};
					undef $ai_v{'temp'}{'foundID'};
					$ai_v{'temp'}{'first'} = 1;
					foreach (@{$ai_v{'ai_attack_cleanMonsters'}}) {
#						next if (!isAttackAble(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}}));
						$ai_v{'temp'}{'dist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$_}{'pos_to'}});
						if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'dist'} < $ai_v{'temp'}{'smallDist'}) {
							$ai_v{'temp'}{'smallDist'} = $ai_v{'temp'}{'dist'};
							$ai_v{'temp'}{'foundID'} = $_;
							undef $ai_v{'temp'}{'first'};
						}
					}
				}

			}
		}
		if ($ai_v{'temp'}{'foundID'}) {
			ai_setSuspend(0);
			attack($ai_v{'temp'}{'foundID'});
		} else {
			timeOutStart('ai_attack_auto');
		}
	}
}

sub ai_event_attack {
	##### ATTACK #####

	return 0 if ($ai_seq[0] ne "attack");

	if ($ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'ai_attack_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}

#	if (timeOut(\%{$ai_seq_args[0]{'ai_attack_giveup'}}) && (!$config{'attackAuto_overTimeMode'} || ($config{'attackAuto_overTimeMode'} && $monsters{$ai_seq_args[0]{'ID'}}{'0080'} eq ""))) {
	if (
		timeOut(\%{$ai_seq_args[0]{'ai_attack_giveup'}})
		&& (
			!$config{'attackAuto_overTimeMode'}
			|| (
				$config{'attackAuto_overTimeMode'}
				&& %{$monsters{$ai_seq_args[0]{'ID'}}}
			)
		)
	) {
#		$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++ if (binFind(\@MVPID, $monsters{$ai_seq_args[0]{'ID'}}{'nameID'}) eq "");
		if (
			binFind(\@MVPID, $monsters{$ai_seq_args[0]{'ID'}}{'nameID'}) eq ""
			&& (
				!$config{'attackAuto_overTimeMode'}
				|| $monsters{$ai_seq_args[0]{'ID'}}{'attack_overTime'} > 1
				|| (
					$config{'attackAuto_overTimeMode'}
					&& (
						!$monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'}
						|| $monsters{$ai_seq_args[0]{'ID'}}{'attack_overTime'} > $config{'attackAuto_overTimeMode'}
					)
				)
			)
		) {
			$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++;
		} else {
			$monsters{$ai_seq_args[0]{'ID'}}{'attack_overTime'}++;
		}

		print "放棄目標 $monsters{$ai_seq_args[0]{'ID'}}{'name'} ($monsters{$ai_seq_args[0]{'ID'}}{'binID'}) - 嘗試攻擊逾時\n";

		shift @ai_seq;
		shift @ai_seq_args;

		timeOutStart(
			 'ai_teleport_search'
			,'ai_teleport_idle'
		);
	} elsif (!%{$monsters{$ai_seq_args[0]{'ID'}}}) {
		$timeout{'ai_attack'}{'time'} -= $timeout{'ai_attack'}{'timeout'};
		$ai_v{'ai_attack_ID_old'} = $ai_seq_args[0]{'ID'};
		shift @ai_seq;
		shift @ai_seq_args;

		my $display;

		if ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'dead'}) {
			my $val = mathPercent($monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgTo'}, 0, 0, 0);

			$display = "目標陣亡: $monsters_old{$ai_v{'ai_attack_ID_old'}}{'name'} ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'binID'})";
			$display .= " (Total: ${val}%)" if (!$config{'hideMsg_attackDmgFromYou'} && $val > 0);
#Karasu Start
			# Defeated monster record
			$record{'monsters'}{$monsters_old{$ai_v{'ai_attack_ID_old'}}{'nameID'}}++ if ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} > 0 || $monsters_old{$ai_v{'ai_attack_ID_old'}}{'missedFromYou'} > 0);
#Karasu End
			if (
				$config{'itemsTakeAuto'}
				&& $monsters_old{$ai_v{'ai_attack_ID_old'}}{'dmgFromYou'} > 0
				&& (
				 	!$config{'itemsTakeDamage'}
				 	|| $val >= $config{'itemsTakeDamage'}
				)
			) {
				ai_items_take($monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos'}{'y'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'x'}, $monsters_old{$ai_v{'ai_attack_ID_old'}}{'pos_to'}{'y'});
			} elsif ($ai_v{'temp'}{'getAggressives'}) {
#				ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
			} else {
				ai_clientSuspend(0, $timeout{'ai_attack_waitAfterKill'}{'timeout'});
			}
		} elsif ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'0080'} ne "" && getMsgStrings('0080', $monsters_old{$ai_v{'ai_attack_ID_old'}}{'0080'}) ne "") {

			$display = "目標".getMsgStrings('0080', $monsters_old{$ai_v{'ai_attack_ID_old'}}{'0080'}, 0, 2).": $monsters_old{$ai_v{'ai_attack_ID_old'}}{'name'} ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'binID'})";

		} else {
			$display = "目標失去蹤影: $monsters_old{$ai_v{'ai_attack_ID_old'}}{'name'} ($monsters_old{$ai_v{'ai_attack_ID_old'}}{'binID'})";
		}

		print "$display\n";

		timeOutStart(
			 'ai_teleport_search'
			,'ai_teleport_idle'
		);
	} elsif (
		$config{'attackAuto_notParam3'}
		&& existsInList2($config{'attackAuto_notParam3'}, $monsters{$ai_seq_args[0]{'ID'}}{'param3'}, "and")
		&& binFind(\@MVPID, $monsters{$ai_seq_args[0]{'ID'}}{'nameID'}) eq ""
		&& !$ai_v{'temp'}{'castWait'}
	) {
		$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++ if (binFind(\@MVPID, $monsters{$ai_seq_args[0]{'ID'}}{'nameID'}) eq "");

		print "放棄目標 $monsters{$ai_seq_args[0]{'ID'}}{'name'} ($monsters{$ai_seq_args[0]{'ID'}}{'binID'}) - [param3]: $monsters{$ai_seq_args[0]{'ID'}}{'param3'}\n";

		shift @ai_seq;
		shift @ai_seq_args;
	} else {
		$ai_v{'temp'}{'ai_follow_index'} = binFind(\@ai_seq, "follow");
		if ($ai_v{'temp'}{'ai_follow_index'} ne "") {
			$ai_v{'temp'}{'ai_follow_following'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'following'};
			$ai_v{'temp'}{'ai_follow_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_follow_index'}]{'ID'};
		} else {
			undef $ai_v{'temp'}{'ai_follow_following'};
		}
		$ai_v{'ai_attack_monsterDist'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}});

		my $tmp_clean = 0;

		if (
			$config{'stealOnly'} > 0
			|| $config{'attackBerserk'} > 0
			|| ($config{'attackAuto_mvp'} && binFind(\@MVPID, $monsters{$ai_seq_args[0]{'ID'}}{'nameID'}) ne "")
			|| ($config{'attackAuto_mvp'} > 1 && binFind(\@RMID, $monsters{$ai_seq_args[0]{'ID'}}{'nameID'}) ne "")
		) {
			$tmp_clean = 1;
		} elsif (
			$config{'attackAuto_party'}
			&& (
				$monsters{$ai_seq_args[0]{'ID'}}{'dmgFromParty'} > 0
				|| $monsters{$ai_seq_args[0]{'ID'}}{'dmgToParty'} > 0
				|| $monsters{$ai_seq_args[0]{'ID'}}{'missedFromParty'} > 0
				|| $monsters{$ai_seq_args[0]{'ID'}}{'missedToParty'} > 0
				|| $monsters{$ai_seq_args[0]{'ID'}}{'castOnByParty'} > 0
			)
		) {
			$tmp_clean = 1;
		} elsif ($config{'attackAuto_followTarget'} && $ai_v{'temp'}{'ai_follow_following'} && ($monsters{$ai_seq_args[0]{'ID'}}{'dmgToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'missedFromPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0 || $monsters{$ai_seq_args[0]{'ID'}}{'missedToPlayer'}{$ai_v{'temp'}{'ai_follow_ID'}} > 0)) {
			$tmp_clean = 1;
		} elsif (
			!(
				$monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} == 0
				&& (
					$monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'} > 0
					|| $monsters{$ai_seq_args[0]{'ID'}}{'dmgFrom'} > 0
					|| %{$monsters{$ai_seq_args[0]{'ID'}}{'missedFromPlayer'}}
					|| %{$monsters{$ai_seq_args[0]{'ID'}}{'missedToPlayer'}}
					|| (!$config{'attackAuto_beCastOn'} && %{$monsters{$ai_seq_args[0]{'ID'}}{'castOnByPlayer'}})
				)
			)
			|| (
				$monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'} > 0
				|| $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'} > 0
			)
		) {
			$tmp_clean = 1;
		} else {
			$tmp_clean = 0;
		}

		$ai_v{'ai_attack_cleanMonster'} = $tmp_clean;

		if (
			$ai_seq_args[0]{'dmgToYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'}
			|| $ai_seq_args[0]{'missedYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'}
			|| $ai_seq_args[0]{'dmgFromYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'}
			|| $ai_seq_args[0]{'missedFromYou_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'missedFromYou'}
		) {
				$ai_seq_args[0]{'ai_attack_giveup'}{'time'} = time;
		}
		$ai_seq_args[0]{'dmgToYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgToYou'};
		$ai_seq_args[0]{'missedYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'missedYou'};
		$ai_seq_args[0]{'dmgFromYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'};
		$ai_seq_args[0]{'missedFromYou_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'missedFromYou'};
		if (!%{$ai_seq_args[0]{'attackMethod'}}) {
			if ($config{'attackUseWeapon'}) {
				$ai_seq_args[0]{'attackMethod'}{'distance'} = $config{'attackDistance'};
				$ai_seq_args[0]{'attackMethod'}{'type'} = "weapon";
			} else {
				$ai_seq_args[0]{'attackMethod'}{'distance'} = 30;
				undef $ai_seq_args[0]{'attackMethod'}{'type'};
			}
			$i = 0;

#			my $onHit	= ai_getMonstersHitMe() or $sc_v{'ai'}{'onHit'};

			ai_getTempVariable();

			while ($config{"attackSkillSlot"} && $config{"attackSkillSlot_$i"} ne "") {
				if (
#					percent_hp(\%{$chars[$config{'char'}]}) >= $config{"attackSkillSlot_$i"."_hp_lower"} && percent_hp(\%{$chars[$config{'char'}]}) <= $config{"attackSkillSlot_$i"."_hp_upper"}
#					&& percent_sp(\%{$chars[$config{'char'}]}) >= $config{"attackSkillSlot_$i"."_sp_lower"} && percent_sp(\%{$chars[$config{'char'}]}) <= $config{"attackSkillSlot_$i"."_sp_upper"}
#					&&
					$chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"attackSkillSlot_$i"})}}{$config{"attackSkillSlot_$i"."_lvl"}}
#					&& !($config{"attackSkillSlot_$i"."_stopWhenHit"} && $sc_v{'ai'}{'onHit'})
					# Use when not sit
#					&& !($config{"attackSkillSlot_$i"."_stopWhenSit"} && $chars[$config{'char'}]{'sitting'})
#					&& (!$config{"attackSkillSlot_$i"."_maxUses"} || $ai_seq_args[0]{'attackSkillSlot_uses'}{$i} < $config{"attackSkillSlot_$i"."_maxUses"})
#					&& $config{"attackSkillSlot_$i"."_minAggressives"} <= ai_getAggressives()
#					&& (!$config{"attackSkillSlot_$i"."_maxAggressives"} || $config{"attackSkillSlot_$i"."_maxAggressives"} >= ai_getAggressives())
#					&& (!$config{"attackSkillSlot_$i"."_monsters"} || existsInList($config{"attackSkillSlot_$i"."_monsters"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))
#					&& (!$config{"attackSkillSlot_$i"."_monstersNot"} || !existsInList($config{"attackSkillSlot_$i"."_monstersNot"}, $monsters{$ai_seq_args[0]{'ID'}}{'name'}))
#Karasu Start
					# Spirits support
#					&& (isMonk($chars[$config{'char'}]{'jobID'}) || ($chars[$config{'char'}]{'spirits'} <= $config{"attackSkillSlot_$i"."_spirits_upper"} && $chars[$config{'char'}]{'spirits'} >= $config{"attackSkillSlot_$i"."_spirits_lower"}))
					# Timeout support
#					&& timeOut($config{"attackSkillSlot_$i"."_timeout"}, $ai_v{"attackSkillSlot_$i"."_time"})
					# Allow to use in city or not
#					&& ($config{"attackSkillSlot_$i"."_inCity"} || !$cities_lut{$field{'name'}.'.rsw'})
					# Use in lockMap only
#					&& (!$config{"attackSkillSlot_$i"."_inLockOnly"} || ($config{"attackSkillSlot_$i"."_inLockOnly"} && $field{'name'} eq $config{'lockMap'}))
#					&& (!$config{"attackSkillSlot_$i"."_unLockOnly"} || ($config{"attackSkillSlot_$i"."_unLockOnly"} && $field{'name'} ne $config{'lockMap'}))
#					&& (!$config{"attackSkillSlot_$i"."_unSteal"} || ($config{"attackSkillSlot_$i"."_unSteal"} && !$monsters{$ai_seq_args[0]{'ID'}}{'beSteal'}))

#					&& (!$config{"attackSkillSlot_$i"."_afterSkill"} || $config{"attackSkillSlot_$i"."_afterSkill"} eq getName("skills_lut", $chars[$config{'char'}]{'last_skill_used'}))

					&& ai_checkToUseSkill("attackSkillSlot", $i, 1, $ai_v{"attackSkillSlot_$i"."_time"}, $ai_seq_args[0]{'attackSkillSlot_uses'}{$i})
				) {
					# Judge parameter and status
					undef $ai_v{'temp'}{'found'};
#					if (
#						!$ai_v{'temp'}{'found'}
#						&& (
#							$config{"attackSkillSlot_$i"."_param1"} && !existsInList2($config{"attackSkillSlot_$i"."_param1"}, $monsters{$ai_seq_args[0]{'ID'}}{'param1'}, "noand")
#							|| $config{"attackSkillSlot_$i"."_param2"} && !existsInList2($config{"attackSkillSlot_$i"."_param2"}, $monsters{$ai_seq_args[0]{'ID'}}{'param2'}, "and")
#							|| $config{"attackSkillSlot_$i"."_param3"} && !existsInList2($config{"attackSkillSlot_$i"."_param3"}, $monsters{$ai_seq_args[0]{'ID'}}{'param3'}, "and")
#						)
#					) {
#						$ai_v{'temp'}{'found'} = 1;
#					}
#					if (!$ai_v{'temp'}{'found'} && $config{"attackSkillSlot_$i"."_status"} ne "") {
#						foreach (@{$chars[$config{'char'}]{'status'}}) {
#							if (existsInList2($config{"attackSkillSlot_$i"."_status"}, $_, "noand")) {
#								$ai_v{'temp'}{'found'} = 1;
#								last;
#							}
#						}
#					}
#					if ($config{"attackSkillSlot_$i"."_checkItem"}) {
#						undef @array;
#						splitUseArray(\@array, $config{"attackSkillSlot_$i"."_checkItem"}, ",");
#						foreach (@array) {
#							next if (!$_);
#							if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) eq "") {
#								$ai_v{'temp'}{'found'} = 1;
#								last;
#							}
#						}
#					}
#					if ($config{"attackSkillSlot_$i"."_checkItemEx"}) {
#						undef @array;
#						undef $ai_v{'temp'}{'foundEx'};
#						splitUseArray(\@array, $config{"attackSkillSlot_$i"."_checkItemEx"}, ",");
#						foreach (@array) {
#							next if (!$_);
#
#							if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) eq "") {
#								$ai_v{'temp'}{'foundEx'} = 1;
#								last;
#							}
#						}
#						$ai_v{'temp'}{'found'} = 1 if (!$ai_v{'temp'}{'foundEx'});
#					}
#					# Judge equipped type
#					if ($config{"attackSkillSlot_$i"."_checkEquipped"} ne "") {
#						undef $ai_v{'temp'}{'invIndex'};
#						$ai_v{'temp'}{'invIndex'} = findIndexStringWithList_KeyNotNull_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"attackSkillSlot_$i"."_checkEquipped"}, "equipped");
#						$ai_v{'temp'}{'found'} = 1 if ($ai_v{'temp'}{'invIndex'} eq "");
#					}
#					$ai_v{'temp'}{'found'} = 1 if (!$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$i"})}}{'lv'} && $config{"attackSkillSlot_$i"."_smartEquip"} eq "");

					$ai_v{'temp'}{'found'} = ai_checkToUseSkill("attackSkillSlot", $i, 0, \%{$chars[$config{'char'}]}, \%{$monsters{$ai_seq_args[0]{'ID'}}});

#					if (!$ai_v{'temp'}{'found'} && $config{"attackSkillSlot_${i}_spells"} ne "") {
#						foreach (@spellsID) {
#							next if ($_ eq "" || $spells{$_}{'type'} eq "");
#
#							undef $s_cDist;
#
#							$s_cDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$spells{$_}{'pos'}});
#
#							if (
#								existsInList($config{"attackSkillSlot_${i}_spells"}, $spells{$_}{'type'})
#								&& (!$config{"attackSkillSlot_${i}_spells_dist"} || $s_cDist <= $config{"attackSkillSlot_${i}_spells_dist"})
#							) {
#								$ai_v{'temp'}{'found'} = 1;
#
#								last;
#							}
#						}
#					}

					if (!$ai_v{'temp'}{'found'}) {
						# Equip for skill
						undef %{$ai_v{'checkEquip'}};
						if (!$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$i"})}}{'lv'} && $config{"attackSkillSlot_$i"."_smartEquip"} ne "") {
							$ai_v{'checkEquip'}{'ignorePos'} = ai_equip_special($config{"attackSkillSlot_$i"."_smartEquip"});
							$ai_v{'checkEquip'}{'skillID'} = ai_getSkillUseID($config{"attackSkillSlot_$i"});
						}
						$ai_v{"attackSkillSlot_$i"."_time"} = time;
#Karasu End
						$ai_seq_args[0]{'attackSkillSlot_uses'}{$i}++;
						$ai_seq_args[0]{'attackMethod'}{'distance'} = $config{"attackSkillSlot_$i"."_dist"};
						$ai_seq_args[0]{'attackMethod'}{'type'} = "skill";
						$ai_seq_args[0]{'attackMethod'}{'skillSlot'} = $i;
#Karasu Start
						# Looping skills support
						if ($config{"attackSkillSlot_$i"."_loopSlot"} ne ""
							&& $ai_seq_args[0]{'attackSkillSlot_uses'}{$i} >= $config{"attackSkillSlot_$i"."_maxUses"}) {
							undef $ai_v{qq~attackSkillSlot_$config{"attackSkillSlot_$i"."_loopSlot"}~."_time"};
							undef $ai_seq_args[0]{'attackSkillSlot_uses'}{$config{"attackSkillSlot_$i"."_loopSlot"}};
						}
#Karasu End
						last;
					}
				}
				$i++;
			}
		}
		if ($chars[$config{'char'}]{'sitting'}) {
			ai_setSuspend(0);
			stand();
		} elsif ($monsters{$ai_seq_args[0]{'ID'}}{'beSteal'} > 0 && $config{'stealOnly'} > 0) {

			print "放棄目標 - 目標已被 $monsters{$ai_seq_args[0]{'ID'}}{'stealByWho'} 施展偷竊\n";

			shift @ai_seq;
			shift @ai_seq_args;

			$record{'counts'}{'Steal-Dropping-target'}++;
		} elsif (!$ai_v{'ai_attack_cleanMonster'} && !$monsters{$_}{'takenBy'}) {
			print "放棄目標 - 目標 $monsters{$ai_seq_args[0]{'ID'}}{'name'} ($monsters{$ai_seq_args[0]{'ID'}}{'binID'}) 被搶先攻擊\n" if (!$config{'attackBerserk'});

			shift @ai_seq;
			shift @ai_seq_args;
		} elsif ($ai_v{'ai_attack_monsterDist'} > $ai_seq_args[0]{'attackMethod'}{'distance'}) {
			if (
				%{$ai_seq_args[0]{'char_pos_last'}}
				&& %{$ai_seq_args[0]{'attackMethod_last'}}
				&& $ai_seq_args[0]{'attackMethod_last'}{'distance'} == $ai_seq_args[0]{'attackMethod'}{'distance'}
				&& $ai_seq_args[0]{'char_pos_last'}{'x'} == $chars[$config{'char'}]{'pos_to'}{'x'}
				&& $ai_seq_args[0]{'char_pos_last'}{'y'} == $chars[$config{'char'}]{'pos_to'}{'y'}
			) {
				$ai_seq_args[0]{'distanceDivide'}++;
			} else {
				$ai_seq_args[0]{'distanceDivide'} = 1;
			}
			if (
				(
					int($ai_seq_args[0]{'attackMethod'}{'distance'} / $ai_seq_args[0]{'distanceDivide'}) == 0
					|| (
						$config{'attackMaxRouteDistance'}
						&& $ai_seq_args[0]{'ai_route_returnHash'}{'solutionLength'} > $config{'attackMaxRouteDistance'}
					)
					|| (
						$config{'attackMaxRouteTime'}
						&& $ai_seq_args[0]{'ai_route_returnHash'}{'solutionTime'} > $config{'attackMaxRouteTime'}
					)
				)
			) {
				# MVP control
				$monsters{$ai_seq_args[0]{'ID'}}{'attack_failed'}++ if (binFind(\@MVPID, $monsters{$ai_seq_args[0]{'ID'}}{'nameID'}) eq "");
				shift @ai_seq;
				shift @ai_seq_args;
				print "放棄目標 - 需花費過多時間接近目標\n";
			} else {
				getVector(\%{$ai_v{'temp'}{'vec'}}, \%{$monsters{$ai_seq_args[0]{'ID'}}{'pos_to'}}, \%{$chars[$config{'char'}]{'pos_to'}});
				moveAlongVector(\%{$ai_v{'temp'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, \%{$ai_v{'temp'}{'vec'}}, $ai_v{'ai_attack_monsterDist'} - ($ai_seq_args[0]{'attackMethod'}{'distance'} / $ai_seq_args[0]{'distanceDivide'}) + 1);

				%{$ai_seq_args[0]{'char_pos_last'}} = %{$chars[$config{'char'}]{'pos_to'}};
				%{$ai_seq_args[0]{'attackMethod_last'}} = %{$ai_seq_args[0]{'attackMethod'}};

				ai_setSuspend(0);
				if (length($field{'rawMap'}) > 1) {
					ai_route(\%{$ai_seq_args[0]{'ai_route_returnHash'}}, $ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'}, $field{'name'}, $config{'attackMaxRouteDistance'}, $config{'attackMaxRouteTime'}, 0, 0);
				} else {
					move($ai_v{'temp'}{'pos'}{'x'}, $ai_v{'temp'}{'pos'}{'y'});
				}
			}
		} elsif (
			(
				($config{'tankMode'} && $monsters{$ai_seq_args[0]{'ID'}}{'dmgFromYou'} == 0)
				|| !$config{'tankMode'}
			)
		) {
#Pino Start(控制發送attack)
			$timeout{'ai_attack'}{'timeout'} = 1 if ($timeout{'ai_attack'}{'timeout'} < 1 && !$config{'attackAuto_unLock'});
#Pino End
			if ($ai_seq_args[0]{'attackMethod'}{'type'} eq "weapon" && checkTimeOut('ai_attack')) {
				if ($config{'tankMode'}) {
					sendAttack(\$remote_socket, $ai_seq_args[0]{'ID'}, 0);
				} else {
					sendAttack(\$remote_socket, $ai_seq_args[0]{'ID'}, 7);
				}
				timeOutStart('ai_attack');
				undef %{$ai_seq_args[0]{'attackMethod'}};
			} elsif ($ai_seq_args[0]{'attackMethod'}{'type'} eq "skill" && checkTimeOut('ai_skill_use')) {
				$ai_v{'ai_attack_method_skillSlot'} = $ai_seq_args[0]{'attackMethod'}{'skillSlot'};
				$ai_v{'ai_attack_ID'} = $ai_seq_args[0]{'ID'};
				undef %{$ai_seq_args[0]{'attackMethod'}};
				ai_setSuspend(0);
				$ai_v{'ai_attack_method_skillSlot_ID'} = ($ai_v{'checkEquip'}{'skillID'}) ? $ai_v{'checkEquip'}{'skillID'} : $chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}}{'ID'};
				if (!ai_getSkillUseType($skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})})) {
#attackSkillSlot_$i_useSelf Start - Karasu
					if ($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_useSelf"}) {
						ai_skillUse($ai_v{'ai_attack_method_skillSlot_ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $accountID, "", $ai_v{'checkEquip'}{'ignorePos'}, "attack");
					} else {
						ai_skillUse($ai_v{'ai_attack_method_skillSlot_ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $ai_v{'ai_attack_ID'}, "", $ai_v{'checkEquip'}{'ignorePos'}, "attack");
					}
				} else {
					if ($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_useSelf"}) {
						ai_skillUse($ai_v{'ai_attack_method_skillSlot_ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}, $ai_v{'checkEquip'}{'ignorePos'}, "attack");
					} else {
						ai_skillUse($ai_v{'ai_attack_method_skillSlot_ID'}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_maxCastTime"}, $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_minCastTime"}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'x'}, $monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'y'}, $ai_v{'checkEquip'}{'ignorePos'}, "attack");
					}
#attackSkillSlot_$i_useSelf End - Karasu
				}
				print qq~Auto-skill on monster: $skills_lut{$skills_rlut{lc($config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"})}} (lvl $config{"attackSkillSlot_$ai_v{'ai_attack_method_skillSlot'}"."_lvl"}) [ID:$ai_v{'ai_attack_method_skillSlot_ID'}]\n~ if ($config{'debug'});
				timeOutStart('ai_skill_use');
			}
#Hit & Run By sonic_and_tails2000
############################################################
		} elsif ($config{'attackAutoHitAndRun'} && %{$monsters{$ai_v{'ai_attack_ID'}}}) {
			if (!$config{"attackAutoHitAndRun_monsters"} || existsInList($config{"attackAutoHitAndRun_monsters"}, $monsters{$ai_v{'ai_attack_ID'}}{'name'})) {
				my $flee_x;
				my $flee_y;
				while ($config{'attackAutoHitAndRun_minDistance'} >= distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}})) {
					if (($chars[$config{'char'}]{'pos'}{'x'}) - ($monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'x'}) < 0) {
						$flee_x = $config{'attackAutoHitAndRun_runDistance'} * -1;
					} else {
						$flee_x = $config{'attackAutoHitAndRun_runDistance'};
					}
					if (($chars[$config{'char'}]{'pos'}{'y'}) - ($monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'y'}) < 0) {
						$flee_y = $config{'attackAutoHitAndRun_runDistance'} * -1;
					} else {
						$flee_y = $config{'attackAutoHitAndRun_runDistance'};
					}
					$flee_x = ($chars[$config{'char'}]{'pos'}{'x'}) + $flee_x;
					$flee_y = ($chars[$config{'char'}]{'pos'}{'y'}) + $flee_y;
					$flee_x = 0 if ($flee_x < $field{'width'});
					$flee_x = $field{'width'} if ($flee_x > $field{'width'});
					$flee_y = 0 if ($flee_y < $field{'height'});
					$flee_y = $field{'height'} if ($flee_y > $field{'height'});
					if ($flee_x && $flee_y eq 0) {
						$flee_x = int(rand() * ($field{'width'} - 1));
						$flee_y = int(rand() * ($field{'height'} - 1));
					} elsif ($flee_x eq $field{'width'} && $flee_y eq $field{'height'}) {
						$flee_x = int(rand() * ($field{'width'} - 1));
						$flee_y = int(rand() * ($field{'height'} - 1));
					}
					move($flee_x, $flee_y);
				}
				print "Fleeing from target\n";
				injectMessage("Fleeing from target") if ($config{'verbose'} && $config{'Xmode'});
			}
############################################################
		} elsif ($config{'tankMode'}) {
			if ($ai_seq_args[0]{'dmgTo_last'} != $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'}) {
				$ai_seq_args[0]{'ai_attack_giveup'}{'time'} = time;
			}
			$ai_seq_args[0]{'dmgTo_last'} = $monsters{$ai_seq_args[0]{'ID'}}{'dmgTo'};
		}
	}
}

sub ai_event_route_getRoute {
	##### ROUTE_GETROUTE #####


	if ($ai_seq[0] eq "route_getRoute" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'time_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "route_getRoute" && ($ai_seq_args[0]{'done'} || $ai_seq_args[0]{'mapChanged'}
		|| ($ai_seq_args[0]{'time_giveup'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'time_giveup'}})))) {
		$timeout{'ai_route_calcRoute_cont'}{'time'} -= $timeout{'ai_route_calcRoute_cont'}{'timeout'};
		ai_route_getRoute_destroy(\%{$ai_seq_args[0]});
		shift @ai_seq;
		shift @ai_seq_args;

	} elsif ($ai_seq[0] eq "route_getRoute" && checkTimeOut('ai_route_calcRoute_cont')) {
		if (!$ai_seq_args[0]{'init'}) {
			undef @{$ai_v{'temp'}{'subSuc'}};
			undef @{$ai_v{'temp'}{'subSuc2'}};
			if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'start'}{'x'}, $ai_seq_args[0]{'start'}{'y'})) {
				ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'start'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				foreach (@{$ai_v{'temp'}{'subSuc'}}) {
					ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
					ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
				}
				if (@{$ai_v{'temp'}{'subSuc'}}) {
					%{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
				} elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
					%{$ai_seq_args[0]{'start'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
				}
			}
			undef @{$ai_v{'temp'}{'subSuc'}};
			undef @{$ai_v{'temp'}{'subSuc2'}};
			if (ai_route_getMap(\%{$ai_seq_args[0]}, $ai_seq_args[0]{'dest'}{'x'}, $ai_seq_args[0]{'dest'}{'y'})) {
				ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$ai_seq_args[0]{'dest'}}, \@{$ai_v{'temp'}{'subSuc'}},0);
				foreach (@{$ai_v{'temp'}{'subSuc'}}) {
					ai_route_getSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
					ai_route_getDiagSuccessors(\%{$ai_seq_args[0]}, \%{$_}, \@{$ai_v{'temp'}{'subSuc2'}},0);
				}
				if (@{$ai_v{'temp'}{'subSuc'}}) {
					%{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc'}[0]};
				} elsif (@{$ai_v{'temp'}{'subSuc2'}}) {
					%{$ai_seq_args[0]{'dest'}} = %{$ai_v{'temp'}{'subSuc2'}[0]};
				}
			}
			$ai_seq_args[0]{'timeout'} = $timeout{'ai_route_calcRoute'}{'timeout'}*1000;
		}
		$ai_seq_args[0]{'init'} = 1;
		ai_route_searchStep(\%{$ai_seq_args[0]});
		timeOutStart('ai_route_calcRoute_cont');
		ai_setSuspend(0);
	}
}

sub ai_event_route_getMapRoute {
	##### ROUTE_GETMAPROUTE #####


	ROUTE_GETMAPROUTE: {

	if ($ai_seq[0] eq "route_getMapRoute" && $ai_seq_args[0]{'suspended'}) {
		$ai_seq_args[0]{'time_giveup'}{'time'} += time - $ai_seq_args[0]{'suspended'};
		undef $ai_seq_args[0]{'suspended'};
	}
	if ($ai_seq[0] eq "route_getMapRoute" && ($ai_seq_args[0]{'done'} || $ai_seq_args[0]{'mapChanged'}
		|| ($ai_seq_args[0]{'time_giveup'}{'timeout'} && timeOut(\%{$ai_seq_args[0]{'time_giveup'}})))) {
		$timeout{'ai_route_calcRoute_cont'}{'time'} -= $timeout{'ai_route_calcRoute_cont'}{'timeout'};
		shift @ai_seq;
		shift @ai_seq_args;

	} elsif ($ai_seq[0] eq "route_getMapRoute" && checkTimeOut('ai_route_calcRoute_cont')) {
		if (!%{$ai_seq_args[0]{'start'}}) {
			%{$ai_seq_args[0]{'start'}{'dest'}{'pos'}} = %{$ai_seq_args[0]{'r_start_pos'}};
			$ai_seq_args[0]{'start'}{'dest'}{'map'} = $ai_seq_args[0]{'r_start_field'}{'name'};
			$ai_seq_args[0]{'start'}{'dest'}{'field'} = $ai_seq_args[0]{'r_start_field'};
			%{$ai_seq_args[0]{'dest'}{'source'}{'pos'}} = %{$ai_seq_args[0]{'r_dest_pos'}};
			$ai_seq_args[0]{'dest'}{'source'}{'map'} = $ai_seq_args[0]{'r_dest_field'}{'name'};
			$ai_seq_args[0]{'dest'}{'source'}{'field'} = $ai_seq_args[0]{'r_dest_field'};
			push @{$ai_seq_args[0]{'openList'}}, \%{$ai_seq_args[0]{'start'}};
		}
		timeOutStart('ai_route_calcRoute');
		while (!$ai_seq_args[0]{'done'} && !checkTimeOut('ai_route_calcRoute')) {
			ai_mapRoute_searchStep(\%{$ai_seq_args[0]});
			last ROUTE_GETMAPROUTE if ($ai_seq[0] ne "route_getMapRoute");
		}

		if ($ai_seq_args[0]{'done'}) {
			@{$ai_seq_args[0]{'returnArray'}} = @{$ai_seq_args[0]{'solutionList'}};
		}
		timeOutStart('ai_route_calcRoute_cont');
		ai_setSuspend(0);
	}

	} #End of block ROUTE_GETMAPROUTE
}

sub ai_event_cartToStorage {
	return 0 if (!$cart{'weight_max'} || !@{$cart{'inventory'}} || !$config{'cartAuto'});


}

sub ai_event_itemToStorage {
	return 0 if (!$cart{'weight_max'} || !@{$cart{'inventory'}} || !$config{'cartAuto'});

	my $i;

	if ($config{'cartAuto'} > 1){
		for ($i = 0; $i < @{$cart{'inventory'}}; $i++) {
			next if (!%{$cart{'inventory'}[$i]});
			if (
				$items_control{lc($cart{'inventory'}[$i]{'name'})}{'storage'}
				&& $cart{'inventory'}[$i]{'amount'} > $items_control{lc($cart{'inventory'}[$i]{'name'})}{'keep'}
			) {
				if (
					$ai_seq_args[0]{'lastIndex'} ne ""
					&& $ai_seq_args[0]{'lastIndex'} == $cart{'inventory'}[$i]{'index'}
					&& checkTimeOut('ai_storageAuto_giveup')
				) {
					return 1;
				} elsif (
					$ai_seq_args[0]{'lastIndex'} eq ""
					|| $ai_seq_args[0]{'lastIndex'} != $cart{'inventory'}[$i]{'index'}
				) {
					timeOutStart('ai_storageAuto_giveup');
				}
				undef $ai_seq_args[0]{'done'};
				$ai_seq_args[0]{'lastIndex'} = $cart{'inventory'}[$i]{'index'};
				sendCartGetToStorage(\$remote_socket, $i, $cart{'inventory'}[$i]{'amount'} - $items_control{lc($cart{'inventory'}[$i]{'name'})}{'keep'});
#				parseInput("cart get $i storage");
				timeOutStart('ai_storageAuto');
				return 1;
			}
		}
	} elsif ($config{'cartAuto'} > 0){
		for ($i = 0; $i < @{$cart{'inventory'}}; $i++) {
			next if (!%{$cart{'inventory'}[$i]});
			if (
				$items_control{lc($cart{'inventory'}[$i]{'name'})}{'storage'} > 1
				&& $cart{'inventory'}[$i]{'amount'} > $items_control{lc($cart{'inventory'}[$i]{'name'})}{'keep'}
			) {
				if (
					$ai_seq_args[0]{'lastIndex'} ne ""
					&& $ai_seq_args[0]{'lastIndex'} == $cart{'inventory'}[$i]{'index'}
					&& checkTimeOut('ai_storageAuto_giveup')
				) {
					return 1;
				} elsif (
					$ai_seq_args[0]{'lastIndex'} eq ""
					|| $ai_seq_args[0]{'lastIndex'} != $cart{'inventory'}[$i]{'index'}
				) {
					timeOutStart('ai_storageAuto_giveup');
				}
				undef $ai_seq_args[0]{'done'};
				$ai_seq_args[0]{'lastIndex'} = $cart{'inventory'}[$i]{'index'};
				sendCartGetToStorage(\$remote_socket, $i, $cart{'inventory'}[$i]{'amount'} - $items_control{lc($cart{'inventory'}[$i]{'name'})}{'keep'});
#				parseInput("cart get $i storage");
				timeOutStart('ai_storageAuto');
				return 1;
			}
		}
	}

	return 0;
}

# Open vendor
sub sendShopOpen {
	return 0 if (!ai_checkShop());

	my $r_socket = shift;
	my $msg;
	my $length = 85;
	my $index;

	my $maxItem;
	my $amount;
	my $price;
	my $i = 0;
	my $j = 0;
	my @selected = "";

	my $priceMax = 99999999;

	my $tmpTitle = $myShop{'shop_title'};

	$tmpTitle = vocalString(8) if (switchInput($myShop{'shop_title'}, '<auto>', '<none>'));

	$msg = (length($tmpTitle) > 36)
		? substr($tmpTitle, 0, 36).chr(0)x44
		: $tmpTitle . chr(0) x (36 - length($tmpTitle)) . chr(0) x 44;

	$msg .= pack("C1", 0x01);

	$maxItem = $chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'} + 2;

	while ($myShop{"shop_$i"} && $j < $maxItem) {
		undef $index;
		$index = findIndexStringNotSelected_lc(\@{$cart{'inventory'}}, \@selected, "name", $myShop{"shop_$i"});
		if ($index ne "" && $myShop{"shop_$i"."_price"} > 0 && $myShop{"shop_$i"."_amount"}) {
			push @selected, $index;
			if ($cart{'inventory'}[$index]{'identified'}) {
				$amount = ($myShop{"shop_$i"."_amount"} > $cart{'inventory'}[$index]{'amount'} || $myShop{"shop_$i"."_amount"} < 0)
					? $cart{'inventory'}[$index]{'amount'}
					: $myShop{"shop_$i"."_amount"};
				$price = ($myShop{"shop_$i"."_price"} > $priceMax || $myShop{"shop_$i"."_price"} < 0)
					? $priceMax
					: $myShop{"shop_$i"."_price"};
				$msg .= pack("S1", $index).pack("S1", $amount).pack("L1", $price);
				$length += 8;
				$j++;
			}
		}
		if ($myShop{"shop_$i"."_each"} && findIndexStringNotSelected_lc(\@{$cart{'inventory'}}, \@selected, "name", $myShop{"shop_$i"}) ne ""){

		} else {
			$i++;
		}
	}

	if (!$j){
		print "Can't Open Shop : No Items to sold\n";
		$myShop{'shop_autoStart'} = 0 if ($myShop{'shop_autoStart'});
		return 0;
	}

	$msg = pack("C*", 0xB2, 0x01).pack("S1", $length).$msg;

	if (length($msg) > 85) {

		if ($myShop{'shop_look'}) {
			sendLook(\$remote_socket, $myShop{'shop_look_body'}, $myShop{'shop_look_head'});

			sleep(0.5);
		}

		aiRemove("move");
		aiRemove("route");
		aiRemove("route_getRoute");
		aiRemove("route_getMapRoute");

		encrypt($r_socket, $msg);
		print "Shop Opened\n" if ($config{'debug'} >= 2);

		if ($myShop{'shop_sitAuto'}) {
			sit('Shop sitAuto');
			$ai_v{'sitAuto_forceStop'} = 0;
		}
	} else {
		print "擺\設攤位失敗, 請檢查相關設定！\n";
	}

	if ($ai_seq[0] eq "shopauto") {
		shift @ai_seq;
		shift @ai_seq_args;
	}
}

sub ai_event_auto_parseInput {
	my @cmd = @_;

	if (@cmd) {

		unshift @ai_seq, "ai_parseInput";
		unshift @ai_seq_args, join(/ /, @cmd);

		timeOutStart('ai_parseInput');

	} else {

		if ($ai_seq[0] eq "ai_parseInput" && checkTimeOut('ai_parseInput')) {

			timeOutStart(1, 'ai_parseInput');

			ai_shift();

			parseInput($ai_seq_args[0]);
		}

	}
}

sub ai_checkShop {
	my $verbose = shift;
	my $mode;
	my $msg;

	if (!$cart{'weight_max'}) {
		$msg = "擺\設攤位失敗 - 你並沒有手推車！\n";
	} elsif ($myShop{'shop_title'} eq "" && $myShop{'title'} eq "") {
		$msg = "擺\設攤位失敗 - 尚未設定攤位名稱！\n";
	} elsif ($chars[$config{'char'}]{'skill_ban'}) {
		$msg = "擺\設攤位失敗 - 你處在禁止聊天和使用技能的狀態下！\n";
	} elsif ($myShop{"shop_$i"} eq "") {
		$msg = "擺\設攤位失敗 - 尚未設定攤位物品！\n";
	} else {
		$mode = 1;
	}

	printVerbose($msg, $verbose, "alert");

	if (!$mode) {
		$myShop{'shop_autoStart'}	= 0 if ($myShop{'shop_autoStart'});
		$config{'shopAuto_open'}	= 0 if ($config{'shopAuto_open'});
	}

	return $mode;
}

sub openShop {
	return 0 if (!ai_checkShop());

	my $r_socket = shift;
	my $msg;
	my $length = 85;
	my $index;

	my $maxItem;
	my $amount;
	my $price;
	my $i = 0;
	my $j = 0;
	my @selected = ();

	my $tmpTitle = $myShop{'shop_title'} or $myShop{'title'};

	$tmpTitle = vocalString(8) if (switchInput($myShop{'shop_title'}, '<auto>', '<none>'));

	$msg = (length($tmpTitle) > 36)
		? substr($tmpTitle, 0, 36).chr(0)x44
		: $tmpTitle . chr(0) x (36 - length($tmpTitle)) . chr(0) x 44;

	$msg .= pack("C1", 0x01);

	$maxItem = $chars[$config{'char'}]{'skills'}{'MC_VENDING'}{'lv'} + 2;

	while ($myShop{"shop_$i"} && $j < $maxItem) {
		undef $index;
		$index = findIndexStringNotSelected_lc(\@{$cart{'inventory'}}, \@selected, "name", $myShop{"shop_$i"});
		if ($index ne "" && $myShop{"shop_$i"."_price"} > 0 && $myShop{"shop_$i"."_amount"}) {
			push @selected, $index;
			if ($cart{'inventory'}[$index]{'identified'}) {
				$amount = ($myShop{"shop_$i"."_amount"} > $cart{'inventory'}[$index]{'amount'} || $myShop{"shop_$i"."_amount"} < 0)
					? $cart{'inventory'}[$index]{'amount'}
					: $myShop{"shop_$i"."_amount"};
				$price = ($myShop{"shop_$i"."_price"} > 10000000 || $myShop{"shop_$i"."_price"} < 0)
					? 10000000
					: $myShop{"shop_$i"."_price"};
				$msg .= pack("S1", $index).pack("S1", $amount).pack("L1", $price);
				$length += 8;
				$j++;
			}
		}
		if ($myShop{"shop_$i"."_each"} && findIndexStringNotSelected_lc(\@{$cart{'inventory'}}, \@selected, "name", $myShop{"shop_$i"}) ne ""){

		} else {
			$i++;
		}
	}

	if (!$j){
		print "Can't Open Shop : No Items to sold\n";
		$myShop{'shop_autoStart'} = 0 if ($myShop{'shop_autoStart'});
		return 0;
	}

	$msg = pack("C*", 0xB2, 0x01).pack("S1", $length).$msg;

	if (length($msg) > 85) {

		aiRemove("move");
		aiRemove("route");
		aiRemove("route_getRoute");
		aiRemove("route_getMapRoute");

		encrypt($r_socket, $msg);
		print "Shop Opened\n" if ($config{'debug'} >= 2);
	} else {
		print "擺\設攤位失敗, 請檢查相關設定！\n";
	}

	if ($ai_seq[0] eq "shopauto") {
		shift @ai_seq;
		shift @ai_seq_args;
	}
}

sub ai_event_shop {
	return 0 if ($shop{'opened'} || 1);

	if ($ai_seq[0] eq "" && $myShop{'shop_autoStart'} && !$ai_v{'temp'}{'shop'}{'time'}) {

		if (ai_checkShop()) {
			unshift @ai_seq, "shopauto";
			unshift @ai_seq_args, {};
		}

	}

	return 0 if ($ai_seq[0] ne "shopauto");

	if (!ai_checkShop()) {

		ai_shift();

		return 0;
	}

	if ($ai_seq_args[0]{'done'} && !$shop{'opened'}) {

		ai_shift();

		return 0;
	}

#	if ($ai_seq_args[0]{'done'} && !$myShop{'shop_autoReStart'}) {
#
#		ai_shift();
#
#	} elsif ($ai_seq_args[0]{'done'} && $myShop{'shop_autoReStart'}) {
#
#		undef $ai_v{'temp'}{'shop'}{'time'};
#		undef $ai_seq_args[0]{'done'};
#
#	} elsif ($ai_seq_args[0]{'done'}) {
#
#		ai_shift();
#
#	} elsif (!$ai_v{'temp'}{'shop'}{'time'}) {
	if (!$ai_v{'temp'}{'shop'}{'time'}) {

		undef $ai_seq_args[0]{'done'};

		if ($chars[$config{'char'}]{'sitting'}) {

			sendStand(\$remote_socket);
			sleep($timeout{'ai_stand_wait'});

		}

		if ($myShop{'shop_look'}) {
			sendLook(\$remote_socket, $myShop{'shop_look_body'}, $myShop{'shop_look_head'});

			sleep(1);
		}

		$ai_v{'temp'}{'shop'}{'time'} = time;

	} elsif ($myShop{'shop_autoStart'}) {

		if ($myShop{'shop_lockMap'} && 1 == 0){
#				undef $ai_v{'temp'}{'map'};
#				$ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
#				$maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}
#				$ai_v{'temp'}{'x'} = $arg1;
#				$ai_v{'temp'}{'y'} = $arg2;
#
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
		} elsif (timeOut($ai_v{'temp'}{'shop'}{'time'}, $myShop{'shop_startTimeDelay'})){
			$ai_seq_args[0]{'done'} = 1;

			openShop(\$remote_socket);
			undef $ai_v{'temp'}{'shop'}{'time'};

			if ($myShop{'shop_sitAuto'}) {
				sit('Shop sitAuto');
				$ai_v{'sitAuto_forceStop'} = 0;
			}
		}

	}
}

sub ai_warpperMode {
	my %args = @_;

	timeOutStart("ai_warpperMode");

	unshift @ai_seq, "warpperMode";
	unshift @ai_seq_args, \%args;
}

sub ai_event_warpperMode {
	return 0 if ($ai_seq[0] ne "warpperMode");

	my $timeOutName = "ai_warpperMode";
	my $tmpTag = "[warpperMode]";
	my $tmpDelay = $config{'warpperModeDelay'} or 3;

	if (checkTimeOut($timeOutName) || $ai_seq_args[0]{'do'}) {
		my $idx;

		delete $ai_seq_args[0]{'do'} if (exists $ai_seq_args[0]{'do'});

		if (!$ai_seq_args[0]{'relog'}) {
			$ai_seq_args[0]{'relog'} = 1;

			printC("$tmpTag 重新取得地圖資訊\n", "s");

			killConnection(\$remote_socket);
			sleep(5);
			relog();

#			ai_clientSuspend(0, $tmpDelay);

		} elsif (!$ai_seq_args[0]{'done'}) {

			print "$tmpTag 現在地圖 ".getMapName($field{'name'}, 1)."\n";

			if ($config{'warpperMode'} > 1 && $field{'name'} eq $config{'lockMap'}) {
				$ai_seq_args[0]{'done'} = 1;

				print "順移回儲存點\n";

				useTeleport(2);

				ai_clientSuspend(0, $tmpDelay);
			} elsif ($config{'warpperMode'} > 1) {
				undef $ai_seq_args[0]{'relog'};
			} else {
				$ai_seq_args[0]{'done'} = 1;
			}

		} else {
			printC("$tmpTag 結束跳躍地圖伺服器\n", "s");

			$idx = 1;

			ai_shift();
		}

		timeOutStart($idx, $timeOutName);

	}
}

sub ai_event_checkUser_lock {
	addFixerValue('config', 'attackAuto_mvp', 0, 4);
#	addFixerValue('config', 'attackAuto_beCastOn', 0, 4);
#	addFixerValue('config', 'attackAuto_checkSkills', 2, 8);
#	addFixerValue('config', 'teleportAuto_onSitting', 0, 4);
#	addFixerValue('config', 'itemsDropAuto', 0, 4);
	addFixerValue('config', 'stealOnly', 1, 4);
#	addFixerValue('config', 'teleportAuto_deadly', 0, 4);
#	addFixerValue('config', 'teleportAuto_onHit', 0, 4);
#	addFixerValue('config', 'teleportAuto_maxDmg', 0, 4);
	addFixerValue('config', 'guildAuto', 2, 8);
	addFixerValue('config', 'partyAuto', 2, 8);
	addFixerValue('config', 'NotAttackDistance', 3, 3);
	addFixerValue('config', 'autoQuit', 17280000, 9);
	addFixerValue('config', 'NotAttackNearSpell', 3, 3);
	addFixerValue('config', 'useGuild_skill', 1, 4);
	addFixerValue('config', 'itemsTakeDamage', 1, 3);
#	addFixerValue('config', 'autoResurrect', 3);
	addFixerValue('config', 'preferRoute_warp', 0);
	addFixerValue('config', 'useSkill_smartCheck', 0);
	addFixerValue('config', 'autoWarp_checkItem', '');
	addFixerValue('config', 'recordItemPickup', 0);
	addFixerValue('config', 'autoCheckItemUse', 600);
	addFixerValue('config', 'itemsTakeDist', 2, 4);
	addFixerValue('config', 'hideMsg_takenByInfo', 0);
	addFixerValue('config', 'autoRoute_npcChoice', 0);
	addFixerValue('config', 'attackAuto_takenByMonsters', '');
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);

	parseFixer();

	parseReload("config", 1);
}

sub ai_event_checkUser_free {
	my $mode = shift;

	addFixerValue('config', 'attackBerserk', 2, 4);
	addFixerValue('config', 'itemsTakeDist', 3, 1);

	addFixerValue('config', 'route_NPC_distance', 12);
	addFixerValue('config', 'dcOnDualLogin_protect', 1, 1);

	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);
	addFixerValue('config', '', 0, 4);

	return 1 if ($mode);

	parseFixer();

	parseReload("config", 1);
}

sub ai_event_checkUser {
#	return 0 if (!$sc_v{'checkUser'});
	return 0 if (!$sc_v{'Scorpio'}{'checkUser'});

	if (checkTimeOut('ai_checkUser')) {

#		if ($chars[$config{'char'}]{'guild'}{'name'} ne '雙魚&雙子') {
#			printC("[嚴重錯誤] 拒絕使用\n", "s");
#			kore_close();
#		}

		if (
			!existsInList($sc_v{'Scorpio'}{'checkServer'}, $sc_v{'parseMsg'}{'server_name'})
			|| !existsInList($sc_v{'Scorpio'}{'checkGuild'}, $chars[$config{'char'}]{'guild'}{'name'})
		) {
#			printC("[嚴重錯誤] 拒絕使用\n", "s");

			if ($sc_v{'Scorpio'}{'checkUser'} > 1) {
				ai_event_checkUser_lock();
			} else {
				kore_close();
			}
		} elsif (existsInList($sc_v{'Scorpio'}{'checkGuild'}, $chars[$config{'char'}]{'guild'}{'name'})) {
			ai_event_checkUser_free();
		}

		timeOutStart(1, 'ai_checkUser');
	}
}

# Record char position for MapViewer
sub ai_event_recordLocation {
	my $map_string;
	if ($config{'recordLocation'} && %{$chars[$config{'char'}]{'pos_to'}}
		&& ($ai_v{'map_refresh'}{'last'}{'x'} ne $chars[$config{'char'}]{'pos_to'}{'x'} || $ai_v{'map_refresh'}{'last'}{'y'} ne $chars[$config{'char'}]{'pos_to'}{'y'})
		&& timeOut($config{'recordLocation'}, $ai_v{'map_refresh'}{'time'})) {
		open(DATA, "> $sc_v{'path'}{'def_control_'}"."walk.dat");
		$map_string = getMapID($map_name);
		# Check for map alias
		$map_string = getMapID($mapAlias_lut{getMapID($map_name, 3)}) if ($mapAlias_lut{getMapID($map_name, 3)} ne "");
		print DATA "$map_string\n";
		print DATA $chars[$config{'char'}]{'pos_to'}{'x'}."\n";
		print DATA $chars[$config{'char'}]{'pos_to'}{'y'}."\n";
		close(DATA);
		$ai_v{'map_refresh'}{'last'}{'x'} = $chars[$config{'char'}]{'pos_to'}{'x'};
		$ai_v{'map_refresh'}{'last'}{'y'} = $chars[$config{'char'}]{'pos_to'}{'y'};
		$ai_v{'map_refresh'}{'time'} = time;
	}
}

sub ai_event_map {
	##### FLY MAP #####

	return 0;

	if ($sendFlyMap && $ai_seq[0] ne "flyMap") {
		unshift @ai_seq, "flyMap";
		unshift @ai_seq_args, {};
		$ai_v{'temp'}{'send_fly'} = 1;
	}
	if ($ai_seq[0] eq "flyMap" && $ai_v{'temp'}{'send_fly'} && $ai_seq_args[0]{'teleport_tried'} < 5 && time - $ai_seq_args[0]{'teleport_time'} > 1) {
		useTeleport(1);
		$ai_seq_args[0]{'teleport_tried'}++;
		$ai_seq_args[0]{'teleport_time'} = time;
	} elsif ($ai_seq[0] eq "flyMap" && !$ai_v{'temp'}{'send_fly'}) {
		undef $sendFlyMap;
		shift @ai_seq;
		shift @ai_seq_args;
	} elsif ($ai_seq[0] eq "flyMap" && $ai_seq_args[0]{'teleport_tried'} >= 5) {
		undef $sendFlyMap;
		shift @ai_seq;
		shift @ai_seq_args;
		relog();
	}
}

sub ai_event_look {
	return 0 if (!($ai_seq[0] eq "look" && checkTimeOut('ai_look')));

	timeOutStart(1, 'ai_look');
	sendLook(\$remote_socket, $ai_seq_args[0]{'look_body'}, $ai_seq_args[0]{'look_head'});

	shift @ai_seq;
	shift @ai_seq_args;
}

sub ai_event_useWaypoint {
	##### Waypoint #####
	return 0 if (!$config{'useWaypoint'} || $shop{'opened'});

	if ($ai_seq[0] eq "" && @{$field{'field'}} > 1 && !getMapName($field{'field'}, 0, 1) && $field{'name'} ne $config{'lockMap'}) {
		if (!%route || $route{'name'} ne $field{'name'}) {
			if (!getRoutePoint("wap/$field{'name'}.wap", \%route)) {
				if (!getRoutePoint("wap/$field{'name'}.fild.wap", \%route)){
#					configModify("useWaypoint", 0);
					scModify("config", "useWaypoint", 0, 1);
				} else {
					#sticky to waypoint
					$route{'count'} = 0;
					for ($i=0; $i<$route{'max'}; $i++) {
						if (distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$route{"$route{'count'}"}}) > distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$route{"$i"}})) {
							$route{'count'} = $i;
						}
					}
				}
			}else{
				#sticky to waypoint
				$route{'count'} = 0;
				for ($i=0;$i<$route{'max'};$i++) {
					if (distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$route{"$route{'count'}"}}) > distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$route{"$i"}})) {
						$route{'count'} = $i;
					}
				}
			}
		}
		if ($config{'useWaypoint'}) {
			print "move to ".getMapName($map_name, 1)." (".$route{"$route{'count'}"}{'x'}.",".$route{"$route{'count'}"}{'y'}.")\n";
			$ai_v{'temp'}{'randX'} = $route{"$route{'count'}"}{'x'};
			$ai_v{'temp'}{'randY'} = $route{"$route{'count'}"}{'y'};
			ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $field{'name'}, 0, $config{'route_randomWalk_maxRouteTime'}, 2);
			$route{'count'}++;
			#wrap around
			if($route{'count'} == $route{'max'}) {
				$route{'count'} = 0;
			}
		}
	}
}

sub ai_event_hitAndRun {
	return 0 if (!$config{'attackAutoHitAndRun'} || $ai_seq[0] ne "attack" || 1==1);
##### Hit and Run #####
# by SnT2k
	if (
		checkTimeOut('ai_hitAndRun')
		&& $config{'attackAutoHitAndRun_minDistance'} >= distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}})
		&& !$chars[$config{'char'}]{'param1'}
	) {
		my ($flee_x, $flee_y);

		if (($chars[$config{'char'}]{'pos'}{'x'}) - ($monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'x'}) < 0) {
			$flee_x = $config{'attackAutoHitAndRun_runDistance'} * -1;
		} elsif (($chars[$config{'char'}]{'pos'}{'x'}) - ($monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'x'}) > 0) {
			$flee_x = $config{'attackAutoHitAndRun_runDistance'};
		} else {
			$flee_x = 0;
		}
		if (($chars[$config{'char'}]{'pos'}{'y'}) - ($monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'y'}) < 0) {
			$flee_y = $config{'attackAutoHitAndRun_runDistance'} * -1;
		} elsif (($chars[$config{'char'}]{'pos'}{'y'}) - ($monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}{'y'}) > 0) {
			$flee_y = $config{'attackAutoHitAndRun_runDistance'};
		} else {
			$flee_y = 0;
		}

		$flee_x = ($chars[$config{'char'}]{'pos'}{'x'}) + $flee_x;
		$flee_y = ($chars[$config{'char'}]{'pos'}{'y'}) + $flee_y;
		$flee_x = 2 if ($flee_x == 0);
		$flee_x = $field{'width'} if ($flee_x > $field{'width'});
		$flee_y = 2 if ($flee_y == 0);
		$flee_y = $field{'height'} if ($flee_y > $field{'height'});

		if (($flee_x && $flee_y) eq 0) {
			$flee_x = int(rand() * ($field{'width'} - 2));
			$flee_y = int(rand() * ($field{'height'} - 2));
		} elsif ($flee_x eq $field{'width'} && $flee_y eq $field{'height'}) {
			$flee_x = int(rand() * ($field{'width'} - 2));
			$flee_y = int(rand() * ($field{'height'} - 2));
		}

#		$ai_seq_args[0]{'ai_attack_giveup'}{'time'} = time + 1;

		move($flee_x, $flee_y);
		timeOutStart('ai_hitAndRun');
		print "Fleeing from target. Dist: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ai_v{'ai_attack_ID'}}{'pos_to'}})."\n";
	}

}

sub ai_event_auto_useParty {
	##### PARTY-SKILL #####
	if (
		$config{'useParty_skill'}
		&& $config{"useParty_skill_0"} ne ""
		&& %{$chars[$config{'char'}]{'party'}}
		&& (
			$ai_seq[0] eq ""
			|| $ai_seq[0] eq "route"
			|| $ai_seq[0] eq "route_getRoute"
			|| $ai_seq[0] eq "route_getMapRoute"
			|| $ai_seq[0] eq "follow"
			|| $ai_seq[0] eq "sitAuto"
			|| $ai_seq[0] eq "items_gather"
			|| (($ai_seq[0] eq "items_take" || $ai_seq[0] eq "take") && !@{$ai_v2{'ImportantItem'}{'targetID'}})
			|| ($ai_seq[0] eq "attack" && %{$monsters{$ai_seq_args[0]{'ID'}}})
		)
#		&& timeOut(\%{$timeout{'ai_skill_party'}})
		&& checkTimeOut('ai_skill_party')
		&& checkTimeOut('ai_skill_party_auto')
	) {
		undef $ai_v{'useParty_skill'};
		undef $ai_v{'useParty_skill_lvl'};
		undef $ai_v{'temp'}{'distSmall'};
		undef $ai_v{'temp'}{'foundID'};

#		my $inLockMap	= (($field{'name'} eq $config{'lockMap'})?1:0);
#		my $inCity	= $cities_lut{$field{'name'}.'.rsw'};
#		my $inTake	= ((binFind(\@ai_seq, "take") ne "" || binFind(\@ai_seq, "items_take") ne "" || binFind(\@ai_seq, "items_gather") ne "")?1:0);
#		my $onHit	= ai_getMonstersHitMe() or $sc_v{'ai'}{'onHit'};
#		my $inAttack	= (binFind(\@ai_seq, "attack") ne "")?1:0;

		for ($j = 0; $j < @playersID; $j++) {
			next if (
				$playersID[$j] eq ""
				|| $players{$playersID[$j]}{'name'} eq ""
#				|| $players{$playersID[$j]}{'dead'} == 1
				|| $players{$playersID[$j]}{'0080'} ne ""
				|| !getPlayerType($playersID[$j], 1, -1, 0, "useParty_skill")
#				|| !$chars[$config{'char'}]{'party'}{'users'}{$playersID[$j]}{'hp_max'}
				|| ($players{$playersID[$j]}{'skills_failed'} && !checkTimeOut('ai_skill_party_wait'))
			);
#			$ai_v{'temp'}{'distance'} = $players{$playersID[$j]}{'distance'};
			$ai_v{'temp'}{'distance'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$playersID[$j]}{'pos_to'}});
			$i = 0;

			while (1) {
				last if (!$config{"useParty_skill_$i"});

#				print "$players{$playersID[$j]}{'name'} : ".ai_checkToUseSkill("useParty_skill", $i, 1)."\n";
#				print "useParty_skill_$i"."_jobs : ".(!$config{"useParty_skill_$i"."_jobs"} || existsInList($config{"useParty_skill_$i"."_jobs"}, $players{$playersID[$j]}{'jobID'}))."\n";
#				print "useParty_skill_$i"."_jobsNot : ".(!$config{"useParty_skill_$i"."_jobsNot"} || !existsInList($config{"useParty_skill_$i"."_jobsNot"}, $players{$playersID[$j]}{'jobID'}))."\n";
#				print "useParty_skill_$i"."_timeout : ".timeOut($config{"useParty_skill_$i"."_timeout"}, $ai_v{"useParty_skill_$i"."_time"}{$playersID[$j]})."\n";
#				print "useParty_skill_$i"."_jobsNot : ".(!$config{"useParty_skill_$i"."_jobsNot"} || !existsInList($config{"useParty_skill_$i"."_jobsNot"}, $players{$playersID[$j]}{'jobID'}))."\n";
#				print "useParty_skill_$i"."_jobsNot : ".(!$config{"useParty_skill_$i"."_jobsNot"} || !existsInList($config{"useParty_skill_$i"."_jobsNot"}, $players{$playersID[$j]}{'jobID'}))."\n";
#				print "useParty_skill_$i"."_jobsNot : ".(!$config{"useParty_skill_$i"."_jobsNot"} || !existsInList($config{"useParty_skill_$i"."_jobsNot"}, $players{$playersID[$j]}{'jobID'}))."\n";

				if (
#					$config{"useParty_skill_$i"."_lvl"} > 0
#					&&
#					percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useParty_skill_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useParty_skill_$i"."_hp_lower"}
#					&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useParty_skill_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useParty_skill_$i"."_sp_lower"}
#					&&
					$chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"useParty_skill_$i"})}}{$config{"useParty_skill_$i"."_lvl"}}
					&& (!$config{"useParty_skill_$i"."_dist"} || $ai_v{'temp'}{'distance'} <= $config{"useParty_skill_$i"."_dist"})
					&& (!$config{"useParty_skill_$i"."_players"} || existsInList($config{"useParty_skill_$i"."_players"}, $players{$playersID[$j]}{'name'}))
#					&& percent_hp(\%{$chars[$config{'char'}]{'party'}{'users'}{$playersID[$j]}}) <= $config{"useParty_skill_$i"."_player_hp_upper"}
#					&& percent_hp(\%{$chars[$config{'char'}]{'party'}{'users'}{$playersID[$j]}}) >= $config{"useParty_skill_$i"."_player_hp_lower"}
					&& mathInNum(percent_hp(\%{$chars[$config{'char'}]{'party'}{'users'}{$playersID[$j]}}), $config{"useParty_skill_$i"."_player_hp_upper"}, $config{"useParty_skill_$i"."_player_hp_lower"}, 1)
#					&& $config{"useParty_skill_$i"."_minAggressives"} <= ai_getAggressives()
#					&& (!$config{"useParty_skill_$i"."_maxAggressives"} || $config{"useParty_skill_$i"."_maxAggressives"} > ai_getAggressives())
##					&& !($config{"useParty_skill_$i"."_stopWhenHit"} && ai_getMonstersWhoHitMe())
#					&& !($config{"useParty_skill_$i"."_stopWhenHit"} && $onHit)
#					&& (!$config{"useParty_skill_$i"."_stopWhenSit"} || ($config{"useParty_skill_$i"."_stopWhenSit"} && binFind(\@ai_seq, "sitAuto") eq ""))
##					&& (!$config{"useParty_skill_$i"."_inLockOnly"} || ($config{"useParty_skill_$i"."_inLockOnly"} && $field{'name'} eq $config{'lockMap'}))
#					&& (!$config{"useParty_skill_$i"."_inLockOnly"} || ($config{"useParty_skill_$i"."_inLockOnly"} && $inLockMap))
#					&& (!$config{"useParty_skill_$i"."_unLockOnly"} || ($config{"useParty_skill_$i"."_unLockOnly"} && !$inLockMap))
#					&& !($config{"useParty_skill_$i"."_stopWhenAttack"} && $inAttack)
#					&& !($config{"useParty_skill_$i"."_stopWhenTake"} && $inTake)
#					&& (!$config{"useParty_skill_$i"."_name"} || $config{"useParty_skill_$i"."_name"} eq $playersID[$j]{'name'})
#					&& timeOut($config{"useParty_skill_$i"."_timeout"}, $ai_v{"useParty_skill_$i"."_time"}{$playersID[$j]})

					&& (!$config{"useParty_skill_$i"."_jobs"} || existsInList($config{"useParty_skill_$i"."_jobs"}, $players{$playersID[$j]}{'jobID'}))
					&& (!$config{"useParty_skill_$i"."_jobsNot"} || !existsInList($config{"useParty_skill_$i"."_jobsNot"}, $players{$playersID[$j]}{'jobID'}))

					&& ai_checkToUseSkill("useParty_skill", $i, 1, $ai_v{"useParty_skill_$i"."_time"}{$playersID[$j]}, $players{$playersID[$j]}{'useParty_skill_uses'}{$i})
				) {
					undef $ai_v{'temp'}{'found'};

#					if (!$ai_v{'temp'}{'found'} && $config{"useParty_skill_$i"."_status"} ne "") {
##						print "[useParty_skill_$i] ".$config{"useParty_skill_${i}_status"}." - ".@{$chars[$config{'char'}]{'party'}{'users'}{$playersID[$j]}{'status'}}."\n";
##
##						foreach (@{$chars[$config{'char'}]{'party'}{'users'}{$playersID[$j]}{'status'}}) {
##							if (existsInList2($config{"useParty_skill_$i"."_status"}, $_, "noand")) {
##								$ai_v{'temp'}{'found'} = 1;
##								last;
##							}
##						}
#
##						print "[useParty_skill_$i] ".$config{"useParty_skill_${i}_status"}." - ".@{$players{$playersID[$j]}{'status'}}."\n";
#
#						foreach (@{$players{$playersID[$j]}{'status'}}) {
#							if (existsInList2($config{"useParty_skill_$i"."_status"}, $_, "noand")) {
#								$ai_v{'temp'}{'found'} = 1;
#								last;
#							}
#						}
#					}
#					# Judge equipped type
#					if ($config{"useParty_skill_$i"."_checkEquipped"} ne "") {
#						undef $ai_v{'temp'}{'invIndex'};
#						$ai_v{'temp'}{'invIndex'} = findIndexStringWithList_KeyNotNull_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"useParty_skill_$i"."_checkEquipped"}, "equipped");
#						$ai_v{'temp'}{'found'} = 1 if ($ai_v{'temp'}{'invIndex'} eq "");
#					}
#					$ai_v{'temp'}{'found'} = 1 if (!$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"useParty_skill_$i"})}}{'lv'} && $config{"useParty_skill_$i"."_smartEquip"} eq "");

					$ai_v{'temp'}{'found'} = ai_checkToUseSkill("useParty_skill", $i, 0, \%{$players{$playersID[$j]}}, \%{$players{$playersID[$j]}});

#					if (!$ai_v{'temp'}{'found'} && $config{"useParty_skill_${i}_player_spells"} ne "") {
#						foreach (@spellsID) {
#							next if ($_ eq "" || $spells{$_}{'type'} eq "");
#
#							undef $s_cDist;
#
#							$s_cDist = distance(\%{$players{$playersID[$j]}{'pos_to'}}, \%{$spells{$_}{'pos'}});
#
#							if (
#								existsInList($config{"useParty_skill_${i}_player_spells"}, $spells{$_}{'type'})
#								&& (!$config{"useParty_skill_${i}_player_spells_dist"} || $s_cDist <= $config{"useParty_skill_${i}_player_spells_dist"})
#							) {
#								$ai_v{'temp'}{'found'} = 1;
#
#								last;
#							}
#						}
#					}

					if (!$ai_v{'temp'}{'found'}) {

						undef %{$ai_v{'checkEquip'}};
						if (!$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"useParty_skill_$i"})}}{'lv'} && $config{"useParty_skill_$i"."_smartEquip"} ne "") {
							$ai_v{'checkEquip'}{'ignorePos'} = ai_equip_special($config{"useParty_skill_$i"."_smartEquip"});
							$ai_v{'checkEquip'}{'skillID'} = ai_getSkillUseID($config{"useParty_skill_$i"});
						}

						$ai_v{'useParty_skill_index'} = $i;
						$ai_v{'useParty_skill'} = $config{"useParty_skill_$i"};
						$ai_v{'useParty_skill_lvl'} = $config{"useParty_skill_$i"."_lvl"};
						$ai_v{'useParty_skill_maxCastTime'} = $config{"useParty_skill_$i"."_maxCastTime"};
						$ai_v{'useParty_skill_minCastTime'} = $config{"useParty_skill_$i"."_minCastTime"};
#						$ai_v{'useParty_skill_smartHeal'} = $config{"useParty_skill_$i"."_smartHeal"};
						$ai_v{"useParty_skill_$i"."_time"}{$playersID[$j]} = time;

						$players{$playersID[$j]}{'useParty_skill_uses'}{$i}++;

						if ($config{"useParty_skill_$i"."_useSelf"}) {
							$ai_v{'temp'}{'foundID'} = $accountID;
						} else {
							$ai_v{'temp'}{'foundID'} = $playersID[$j];
						}

						last;
					}
				}
				$i++;
			}
			last if ($ai_v{'temp'}{'foundID'});
		}
		if ($ai_v{'temp'}{'foundID'}) {
#			if ($ai_v{'useParty_skill_smartHeal'} && $skills_rlut{lc($ai_v{'useParty_skill'})} eq "AL_HEAL") {
#			if ($config{'useParty_skill_smartHeal'} && $skills_rlut{lc($ai_v{'useParty_skill'})} eq "AL_HEAL") {
#				undef $ai_v{'temp'}{'smartHeal_lvl'};
#				$ai_v{'temp'}{'smartHeal_hp_dif'} = $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'foundID'}}{'hp_max'} - $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'foundID'}}{'hp'};
#				for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
#					$ai_v{'temp'}{'smartHeal_lvl'} = $i;
#					$ai_v{'temp'}{'smartHeal_sp'} = 10 + ($i * 3);
#					$ai_v{'temp'}{'smartHeal_amount'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
#							* (4 + $i * 8);
#					if ($chars[$config{'char'}]{'sp'} < $ai_v{'temp'}{'smartHeal_sp'}) {
#						$ai_v{'temp'}{'smartHeal_lvl'}--;
#						last;
#					}
#					last if ($ai_v{'temp'}{'smartHeal_amount'} >= $ai_v{'temp'}{'smartHeal_hp_dif'});
#				}
#			}
			$ai_v{'useParty_skill_lvl'} = ai_smartHeal($ai_v{'useParty_skill_lvl'}, $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'foundID'}}{'hp_max'} - $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'foundID'}}{'hp'}) if ($skills_rlut{lc($ai_v{'useParty_skill'})} eq "AL_HEAL");
			if ($ai_v{'useParty_skill_lvl'} > 0) {
				print qq~Auto-skill on party: $skills_lut{$skills_rlut{lc($ai_v{'useParty_skill'})}} (lvl $ai_v{'useParty_skill_lvl'})\n~ if $config{'debug'};
				if (!ai_getSkillUseType($skills_rlut{lc($ai_v{'useParty_skill'})})) {
					ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useParty_skill'})}}{'ID'}, $ai_v{'useParty_skill_lvl'}, $ai_v{'useParty_skill_maxCastTime'}, $ai_v{'useParty_skill_minCastTime'}, $ai_v{'temp'}{'foundID'}, "", $ai_v{'checkEquip'}{'ignorePos'}, "party");
				} else {
					ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useParty_skill'})}}{'ID'}, $ai_v{'useParty_skill_lvl'}, $ai_v{'useParty_skill_maxCastTime'}, $ai_v{'useParty_skill_minCastTime'}, $players{$ai_v{'temp'}{'foundID'}}{'pos_to'}{'x'}, $players{$ai_v{'temp'}{'foundID'}}{'pos_to'}{'pos_to'}{'y'}, $ai_v{'checkEquip'}{'ignorePos'}, "party");
				}

#				$record{"counts"}{'useParty_skill'}++;

				$record{"counts"}{$players{$playersID[$j]}{'name'}}++ if ($config{'record_useParty_skill'});

			}
		} else {
			timeOutStart('ai_skill_party_auto');
		}
#		$timeout{'ai_skill_party'}{'time'} = time;
		timeOutStart('ai_skill_party');
	}
}

sub ai_event_auto_useGuild {
	##### PARTY-SKILL #####
	if (
		$config{'useGuild_skill'}
		&& $config{"useGuild_skill_0"} ne ""
		&& $chars[$config{'char'}]{'guild'}{'name'} ne ""
		&& (
			$ai_seq[0] eq ""
			|| $ai_seq[0] eq "route"
			|| $ai_seq[0] eq "route_getRoute"
			|| $ai_seq[0] eq "route_getMapRoute"
			|| $ai_seq[0] eq "follow"
			|| $ai_seq[0] eq "sitAuto"
#			|| $ai_seq[0] eq "take"
			|| $ai_seq[0] eq "items_gather"
			|| (($ai_seq[0] eq "items_take" || $ai_seq[0] eq "take") && !@{$ai_v2{'ImportantItem'}{'targetID'}})
			|| ($ai_seq[0] eq "attack" && %{$monsters{$ai_seq_args[0]{'ID'}}})
		)
#		&& timeOut(\%{$timeout{'ai_skill_party'}})
		&& checkTimeOut('ai_skill_guild')
		&& checkTimeOut('ai_skill_guild_auto')
	) {
		undef $ai_v{'useGuild_skill'};
		undef $ai_v{'useGuild_skill_lvl'};
		undef $ai_v{'temp'}{'distSmall'};
		undef $ai_v{'temp'}{'foundID'};

#		my $inLockMap	= (($field{'name'} eq $config{'lockMap'})?1:0);
#		my $inCity	= $cities_lut{$field{'name'}.'.rsw'};
#		my $inTake	= ((binFind(\@ai_seq, "take") ne "" || binFind(\@ai_seq, "items_take") ne "" || binFind(\@ai_seq, "items_gather") ne "")?1:0);
#		my $onHit	= ai_getMonstersHitMe() or $sc_v{'ai'}{'onHit'};
#		my $inAttack	= (binFind(\@ai_seq, "attack") ne "")?1:0;

		for ($j = 0; $j < @playersID; $j++) {
			next if (
				$playersID[$j] eq ""
#				|| $players{$playersID[$j]}{'dead'} == 1
				|| $players{$playersID[$j]}{'0080'} ne ""
				|| !getPlayerType($playersID[$j], 2, 0, $config{'useGuild_skill'}, "useGuild_skill")
#				|| !($guildUsersID{$playersID[$j]} || $chars[$config{'char'}]{'guild'}{'users'}{$playersID[$j]}{'ID'} ne "")
#				|| $chars[$config{'char'}]{'guild'}{'users'}{$playersID[$j]}{'ID'} eq ""
#				|| (
#					($config{'useGuild_skill'} > 1 && !$guildUsersID{$playersID[$j]}))
#					|| ($config{'useGuild_skill'} <= 1 && $chars[$config{'char'}]{'guild'}{'users'}{$playersID[$j]}{'ID'} eq "")
#				)
#				|| $players{$playersID[$j]}{'guild'}{'name'} ne $chars[$config{'char'}]{'guild'}{'name'}
#				|| !binFind(\@guildUsersID, $playersID[$j])
				|| ($players{$playersID[$j]}{'skills_failed'} && !checkTimeOut('ai_skill_guild_wait'))
			);
#			$ai_v{'temp'}{'distance'} = $players{$playersID[$j]}{'distance'};
			$ai_v{'temp'}{'distance'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$playersID[$j]}{'pos_to'}});
			$i = 0;
			while (1) {
				last if (!$config{"useGuild_skill_$i"});
				if (
#					$config{"useGuild_skill_$i"."_lvl"} > 0
#					&&
#					percent_hp(\%{$chars[$config{'char'}]}) <= $config{"useGuild_skill_$i"."_hp_upper"} && percent_hp(\%{$chars[$config{'char'}]}) >= $config{"useGuild_skill_$i"."_hp_lower"}
#					&& percent_sp(\%{$chars[$config{'char'}]}) <= $config{"useGuild_skill_$i"."_sp_upper"} && percent_sp(\%{$chars[$config{'char'}]}) >= $config{"useGuild_skill_$i"."_sp_lower"}
#					&&
					$chars[$config{'char'}]{'sp'} >= $skillsSP_lut{$skills_rlut{lc($config{"useGuild_skill_$i"})}}{$config{"useGuild_skill_$i"."_lvl"}}
					&& (!$config{"useGuild_skill_$i"."_dist"} || $ai_v{'temp'}{'distance'} <= $config{"useGuild_skill_$i"."_dist"})
					&& (!$config{"useGuild_skill_$i"."_players"} || existsInList($config{"useGuild_skill_$i"."_players"}, $players{$playersID[$j]}{'name'}))
#					&& $config{"useGuild_skill_$i"."_minAggressives"} <= ai_getAggressives()
#					&& (!$config{"useGuild_skill_$i"."_maxAggressives"} || $config{"useGuild_skill_$i"."_maxAggressives"} > ai_getAggressives())
#					&& !($config{"useGuild_skill_$i"."_stopWhenHit"} && $onHit)
#					&& (!$config{"useGuild_skill_$i"."_stopWhenSit"} || ($config{"useGuild_skill_$i"."_stopWhenSit"} && binFind(\@ai_seq, "sitAuto") eq ""))
#					&& (!$config{"useGuild_skill_$i"."_inLockOnly"} || ($config{"useGuild_skill_$i"."_inLockOnly"} && $inLockMap))
#					&& (!$config{"useGuild_skill_$i"."_unLockOnly"} || ($config{"useGuild_skill_$i"."_unLockOnly"} && !$inLockMap))
#					&& !($config{"useGuild_skill_$i"."_stopWhenAttack"} && $inAttack)
#					&& !($config{"useGuild_skill_$i"."_stopWhenTake"} && $inTake)
#					&& timeOut($config{"useGuild_skill_$i"."_timeout"}, $ai_v{"useGuild_skill_$i"."_time"}{$playersID[$j]})

					&& (!$config{"useGuild_skill_$i"."_jobs"} || existsInList($config{"useGuild_skill_$i"."_jobs"}, $players{$playersID[$j]}{'jobID'}))
					&& (!$config{"useGuild_skill_$i"."_jobsNot"} || !existsInList($config{"useGuild_skill_$i"."_jobsNot"}, $players{$playersID[$j]}{'jobID'}))

					&& ai_checkToUseSkill("useGuild_skill", $i, 1, $ai_v{"useGuild_skill_$i"."_time"}{$playersID[$j]}, $players{$playersID[$j]}{'useGuild_skill_uses'}{$i})
				) {
					undef $ai_v{'temp'}{'found'};



#					if (!$ai_v{'temp'}{'found'} && $config{"useGuild_skill_$i"."_status"} ne "") {
##						print "[useGuild_skill_$i] ".$config{"useGuild_skill_${i}_status"}." - ".@{$chars[$config{'char'}]{'party'}{'users'}{$playersID[$j]}{'status'}}."\n";
##
##						foreach (@{$chars[$config{'char'}]{'party'}{'users'}{$playersID[$j]}{'status'}}) {
##							if (existsInList2($config{"useGuild_skill_$i"."_status"}, $_, "noand")) {
##								$ai_v{'temp'}{'found'} = 1;
##								last;
##							}
##						}
#
##						print "[useGuild_skill_$i] ".$config{"useGuild_skill_${i}_status"}." - ".@{$players{$playersID[$j]}{'status'}}."\n";
#
#						foreach (@{$players{$playersID[$j]}{'status'}}) {
#							if (existsInList2($config{"useGuild_skill_$i"."_status"}, $_, "noand")) {
#								$ai_v{'temp'}{'found'} = 1;
#								last;
#							}
#						}
#					}
					# Judge equipped type
#					if ($config{"useGuild_skill_$i"."_checkEquipped"} ne "") {
#						undef $ai_v{'temp'}{'invIndex'};
#						$ai_v{'temp'}{'invIndex'} = findIndexStringWithList_KeyNotNull_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"useGuild_skill_$i"."_checkEquipped"}, "equipped");
#						$ai_v{'temp'}{'found'} = 1 if ($ai_v{'temp'}{'invIndex'} eq "");
#					}
#					$ai_v{'temp'}{'found'} = 1 if (!$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"useGuild_skill_$i"})}}{'lv'} && $config{"useGuild_skill_$i"."_smartEquip"} eq "");

					$ai_v{'temp'}{'found'} = ai_checkToUseSkill("useGuild_skill", $i, 0, \%{$players{$playersID[$j]}}, \%{$players{$playersID[$j]}});

#					print "useGuild_skill_$i $ai_v{'temp'}{'found'}\n";

#					if (!$ai_v{'temp'}{'found'} && $config{"useGuild_skill_${i}_player_spells"} ne "") {
#						foreach (@spellsID) {
#							next if ($_ eq "" || $spells{$_}{'type'} eq "");
#
#							undef $s_cDist;
#
#							$s_cDist = distance(\%{$players{$playersID[$j]}{'pos_to'}}, \%{$spells{$_}{'pos'}});
#
#							if (
#								existsInList($config{"useGuild_skill_${i}_player_spells"}, $spells{$_}{'type'})
#								&& (!$config{"useGuild_skill_${i}_player_spells_dist"} || $s_cDist <= $config{"useGuild_skill_${i}_player_spells_dist"})
#							) {
#								$ai_v{'temp'}{'found'} = 1;
#
#								last;
#							}
#						}
#					}

					if (!$ai_v{'temp'}{'found'}) {

						undef %{$ai_v{'checkEquip'}};
						if (!$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($config{"useGuild_skill_$i"})}}{'lv'} && $config{"useGuild_skill_$i"."_smartEquip"} ne "") {
							$ai_v{'checkEquip'}{'ignorePos'} = ai_equip_special($config{"useGuild_skill_$i"."_smartEquip"});
							$ai_v{'checkEquip'}{'skillID'} = ai_getSkillUseID($config{"useGuild_skill_$i"});
						}

						$ai_v{'useGuild_skill_index'} = $i;
						$ai_v{'useGuild_skill'} = $config{"useGuild_skill_$i"};
						$ai_v{'useGuild_skill_lvl'} = $config{"useGuild_skill_$i"."_lvl"};
						$ai_v{'useGuild_skill_maxCastTime'} = $config{"useGuild_skill_$i"."_maxCastTime"};
						$ai_v{'useGuild_skill_minCastTime'} = $config{"useGuild_skill_$i"."_minCastTime"};
#						$ai_v{'useGuild_skill_smartHeal'} = $config{"useGuild_skill_$i"."_smartHeal"};
						$ai_v{"useGuild_skill_$i"."_time"}{$playersID[$j]} = time;

						$players{$playersID[$j]}{'useGuild_skill_uses'}{$i}++;

#						$ai_v{'temp'}{'foundID'} = $playersID[$j];

						if ($config{"useGuild_skill_$i"."_useSelf"}) {
							$ai_v{'temp'}{'foundID'} = $accountID;
						} else {
							$ai_v{'temp'}{'foundID'} = $playersID[$j];
						}

						last;
					}
				}
				$i++;
			}
			last if ($ai_v{'temp'}{'foundID'});
		}
		if ($ai_v{'temp'}{'foundID'}) {
#			if ($ai_v{'useGuild_skill_smartHeal'} && $skills_rlut{lc($ai_v{'useGuild_skill'})} eq "AL_HEAL") {
#			if ($config{'useGuild_skill_smartHeal'} && $skills_rlut{lc($ai_v{'useGuild_skill'})} eq "AL_HEAL") {
#				undef $ai_v{'temp'}{'smartHeal_lvl'};
#				$ai_v{'temp'}{'smartHeal_hp_dif'} = $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'foundID'}}{'hp_max'} - $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'foundID'}}{'hp'};
#				for ($i = 1; $i <= $chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'}; $i++) {
#					$ai_v{'temp'}{'smartHeal_lvl'} = $i;
#					$ai_v{'temp'}{'smartHeal_sp'} = 10 + ($i * 3);
#					$ai_v{'temp'}{'smartHeal_amount'} = int(($chars[$config{'char'}]{'lv'} + $chars[$config{'char'}]{'int'}) / 8)
#							* (4 + $i * 8);
#					if ($chars[$config{'char'}]{'sp'} < $ai_v{'temp'}{'smartHeal_sp'}) {
#						$ai_v{'temp'}{'smartHeal_lvl'}--;
#						last;
#					}
#					last if ($ai_v{'temp'}{'smartHeal_amount'} >= $ai_v{'temp'}{'smartHeal_hp_dif'});
#				}
#			}
#			$ai_v{'useGuild_skill_lvl'} = ai_smartHeal($ai_v{'useGuild_skill_lvl'}, $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'foundID'}}{'hp_max'} - $chars[$config{'char'}]{'party'}{'users'}{$ai_v{'temp'}{'foundID'}}{'hp'}) if ($skills_rlut{lc($ai_v{'useGuild_skill'})} eq "AL_HEAL");
			if ($ai_v{'useGuild_skill_lvl'} > 0) {
				print qq~Auto-skill on guild: $skills_lut{$skills_rlut{lc($ai_v{'useGuild_skill'})}} (lvl $ai_v{'useGuild_skill_lvl'})\n~ if $config{'debug'};
				if (!ai_getSkillUseType($skills_rlut{lc($ai_v{'useGuild_skill'})})) {
					ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useGuild_skill'})}}{'ID'}, $ai_v{'useGuild_skill_lvl'}, $ai_v{'useGuild_skill_maxCastTime'}, $ai_v{'useGuild_skill_minCastTime'}, $ai_v{'temp'}{'foundID'}, "", $ai_v{'checkEquip'}{'ignorePos'}, "guild");
				} else {
					ai_skillUse($chars[$config{'char'}]{'skills'}{$skills_rlut{lc($ai_v{'useGuild_skill'})}}{'ID'}, $ai_v{'useGuild_skill_lvl'}, $ai_v{'useGuild_skill_maxCastTime'}, $ai_v{'useGuild_skill_minCastTime'}, $players{$ai_v{'temp'}{'foundID'}}{'pos_to'}{'x'}, $players{$ai_v{'temp'}{'foundID'}}{'pos_to'}{'pos_to'}{'y'}, $ai_v{'checkEquip'}{'ignorePos'}, "guild");
				}

#				$record{"counts"}{'useGuild_skill'}++;
				$record{"counts"}{$players{$playersID[$j]}{'name'}}++ if ($config{'record_useGuild_skill'});
			}
		} else {
			timeOutStart('ai_skill_guild_auto');
		}
#		$timeout{'ai_skill_party'}{'time'} = time;
		timeOutStart('ai_skill_guild');
	}
}

sub ai_event_auto_resurrect {
	##### PARTY-RESURRECT #####

	if (
		$config{'autoResurrect'}
		&& (
			$ai_seq[0] eq ""
			|| $ai_seq[0] eq "route"
			|| $ai_seq[0] eq "route_getRoute"
			|| $ai_seq[0] eq "route_getMapRoute"
			|| $ai_seq[0] eq "follow"
			|| $ai_seq[0] eq "sitAuto"
			|| $ai_seq[0] eq "items_gather"
			|| (($ai_seq[0] eq "items_take" || $ai_seq[0] eq "take") && !@{$ai_v2{'ImportantItem'}{'targetID'}})
			|| $ai_seq[0] eq "attack"
		)
		&& checkTimeOut('ai_resurrect')
		&& checkTimeOut('ai_resurrect_auto')
	) {
		undef $ai_v{'temp'}{'distSmall'};
		undef $ai_v{'temp'}{'foundID'};
		undef $ai_v{'temp'}{'distance'};
		undef $ai_v{'temp'}{'method'};
		my $invIndex;

		if ($config{'autoResurrect_checkItem'}) {
			$ai_v{'temp'}{'found'} = 1;
#
#			if (
#				$chars[$config{'char'}]{'skills'}{'ALL_RESURRECTION'}{'lv'} > 0
#				&& $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{'ALL_RESURRECTION'}{$chars[$config{'char'}]{'skills'}{'ALL_RESURRECTION'}{'lv'}}
#			) {
#				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 717);
#				$ai_v{'temp'}{'method'} = 0;
#			}
#			if ($invIndex eq "") {
#				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 610);
#				$ai_v{'temp'}{'method'} = 1;
#			}
#			$ai_v{'temp'}{'found'} = 1 if ($invIndex eq "");

			undef @array;
			splitUseArray(\@array, $config{"autoResurrect_checkItem"}, ",");

			foreach (@array) {
				next if (!$_);

				$invIndex = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_);

				if ($invIndex ne "") {
					$ai_v{'temp'}{'found'} = 0;
					last;
				}
			}

			if (!$ai_v{'temp'}{'found'}) {
				if (
					$chars[$config{'char'}]{'skills'}{'ALL_RESURRECTION'}{'lv'} > 0
					&& $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{'ALL_RESURRECTION'}{$chars[$config{'char'}]{'skills'}{'ALL_RESURRECTION'}{'lv'}}
					&& $chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} eq "717"
				) {
					$ai_v{'temp'}{'method'} = 0;
				} elsif ($chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} ne "717") {
#					$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 610);
					$ai_v{'temp'}{'method'} = 1;
				} else {
					$ai_v{'temp'}{'found'} = 1;
				}
			}

		}
#		else {
#			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 610);
#		}

		if (
			!$ai_v{'temp'}{'found'}
			&& !(
				mathInNum(percent_hp(\%{$chars[$config{'char'}]}), $config{"autoResurrect_hp_upper"}, $config{"autoResurrect_hp_lower"}, 1)
				&& mathInNum(percent_sp(\%{$chars[$config{'char'}]}), $config{"autoResurrect_sp_upper"}, $config{"autoResurrect_sp_lower"}, 1)
				&& !($config{"autoResurrect_stopWhenHit"} && $ai_v{'temp'}{'onHit'})
				&& !($config{"autoResurrect_stopWhenSit"} && $chars[$config{'char'}]{'sitting'})
				&& !($config{"autoResurrect_stopWhenTake"} && $ai_v{'temp'}{'inTake'})
				&& !($config{"autoResurrect_stopWhenAttack"} && $ai_v{'temp'}{'inAttack'})

				&& $config{"autoResurrect_minAggressives"} <= $ai_v{'temp'}{'getAggressives'}
				&& (!$config{"autoResurrect_maxAggressives"} || $config{"autoResurrect_maxAggressives"} >= $ai_v{'temp'}{'getAggressives'})

				&& (!$config{"autoResurrect_waitAfterKill"} || timeOut(\%{$timeout{'ai_skill_use_waitAfterKill'}}))
				&& ($config{"autoResurrect_inCity"} || !$ai_v{'temp'}{'inCity'})
				&& (!$config{"autoResurrect_inLockOnly"} || ($config{"autoResurrect_inLockOnly"} && $ai_v{'temp'}{'inLockMap'}))
				&& (!$config{"autoResurrect_unLockOnly"} || ($config{"autoResurrect_unLockOnly"} && !$ai_v{'temp'}{'inLockMap'}))
			)
		) {
			$ai_v{'temp'}{'found'} = 1;
		}

		if (!$ai_v{'temp'}{'found'}) {
			for ($i = 0; $i < @playersID; $i++) {
				next if (
					$playersID[$i] eq ""
					|| !$players{$playersID[$i]}{'dead'}
					|| ($players{$playersID[$j]}{'skills_failed'} && !checkTimeOut('ai_resurrect_wait'))
					|| $players{$playersID[$j]}{'skills_failed'} > $config{'autoResurrect_retry'}
				);
				undef $ai_v{'temp'}{'found'};

	#			$ai_v{'temp'}{'distance'} = $players{$playersID[$i]}{'distance'};
				$ai_v{'temp'}{'distance'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$playersID[$j]}{'pos_to'}});

				$ai_v{'temp'}{'found'} = 1 if (
					(
						$config{'autoResurrect'} > 2
						|| ($config{'autoResurrect'} && $chars[$config{'char'}]{'party'}{'users'}{$playersID[$j]}{'name'} ne "")
						|| ($config{'autoResurrect'} > 1 && ($guildUsersID{$playersID[$j]} || $chars[$config{'char'}]{'guild'}{'users'}{$playersID[$j]}{'ID'} ne ""))
					)
					&& (!$config{"autoResurrect_players"} || existsInList($config{"autoResurrect_players"}, $players{$playersID[$j]}{'name'}))
					&& (!$config{"autoResurrect_jobs"} || existsInList($config{"autoResurrect_jobs"}, $players{$playersID[$j]}{'jobID'}))
					&& (!$config{"autoResurrect_jobsNot"} || !existsInList($config{"autoResurrect_jobsNot"}, $players{$playersID[$j]}{'jobID'}))
				);

				next if (!$ai_v{'temp'}{'found'} || $ai_v{'temp'}{'distance'} > $config{'autoResurrect_dist'});

				if ($ai_v{'temp'}{'first'} || $ai_v{'temp'}{'distance'} < $ai_v{'temp'}{'distSmall'}) {
					$ai_v{'temp'}{'distSmall'} = $ai_v{'temp'}{'distance'};
					$ai_v{'temp'}{'foundID'} = $playersID[$i];
					undef $ai_v{'temp'}{'first'};
				}
			}
		}

		if ($ai_v{'temp'}{'foundID'}) {
			if (
				!$ai_v{'temp'}{'method'}
				&& $chars[$config{'char'}]{'skills'}{'ALL_RESURRECTION'}{'lv'} > 0
			) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{'ALL_RESURRECTION'}{'ID'}, $chars[$config{'char'}]{'skills'}{'ALL_RESURRECTION'}{'lv'}, $config{"autoResurrect_maxCastTime"}, $config{"autoResurrect_minCastTime"}, $ai_v{'temp'}{'foundID'}, "", "", "resurrect");
			} elsif ($invIndex ne "") {
				$resurrectID = $ai_v{'temp'}{'foundID'};
				sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $ai_v{'temp'}{'foundID'});
			} else {
#				$resurrectID = $ai_v{'temp'}{'foundID'};
#				sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $ai_v{'temp'}{'foundID'});

				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 610);

				if ($invIndex ne "") {
					$resurrectID = $ai_v{'temp'}{'foundID'};
					sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $ai_v{'temp'}{'foundID'});
				} else {
					timeOutStart('ai_resurrect_auto');
				}
			}
		} else {
			timeOutStart('ai_resurrect_auto');
		}
		timeOutStart('ai_resurrect');
	}
}
1;