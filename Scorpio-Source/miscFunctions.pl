#######################################
#INITIALIZE VARIABLES
#######################################

sub initConnectVars {

	initMapChangeVars();
	undef @{$chars[$config{'char'}]{'inventory'}};
	undef %{$chars[$config{'char'}]{'skills'}};
	# Added bcz reset all skill at 010F
	undef %{$chars[$config{'char'}]{'skills_used'}};
	undef @skillsID;
#Karasu Start
	# Spirits
	undef $chars[$config{'char'}]{'spirits'};
	# Status icon
	undef @{$chars[$config{'char'}]{'status'}};
	# EXPs gained per hour
	parseInput("exp reset") if (!$record{'exp'}{'start'});
#Karasu End
#Ayon Start
	# Auto-spell
	undef $chars[$config{'char'}]{'autospell'};
	undef $sc_v{'input'}{'autoStartPause'};
	undef $quitBczGM;
	undef $sc_v{'kore'}{'guildBulletinShow'};
	undef %charID_lut;
	undef %storage;

#	undef %guildUsersID;

	undef %{$chars[$config{'char'}]{'guild'}{'users'}};

	# Reset attackSkillslot/useSelf_skill/useSelf_item timeout
	resetTimeout();
#Ayon End
}

sub initMapChangeVars {
	@portalsID_old = @portalsID;
	%portals_old = %portals;
	%{$chars_old[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos_to'}};
	undef $chars[$config{'char'}]{'sitting'};
	undef $chars[$config{'char'}]{'dead'};
	undef $chars[$config{'char'}]{'autoSwitch'};

	timeOutStart(
		'play',
		'ai_sync',
		'ai_sit_idle',
		'ai_teleport_idle',
		'ai_teleport_search',
		'ai_teleport_safe_force',
		'ai_useSelf_skill_auto',
		'ai_item_use_auto',
		'ai_route_npcTalk',
		'ai_event_onHit',
		'ai_teleport_search_portal'
	);

	timeOutStart(-1,
		'ai_attackCounter',
		'ai_skill_guild_wait',
		'ai_skill_party_wait',
		'ai_resurrect_wait',
		'ai_warpTo_wait'
	);

	undef $ai_v{'temp'}{'inPortal'};

	undef $sc_v{'temp'}{'itemsImportantAutoMode'};

	undef $sc_v{'ai'}{'onHit'};
	undef %{$sc_v{'ai'}{'warpTo'}};

	undef $ai_v{'useGuild_skill'};
	undef $ai_v{'useParty_skill'};

	undef %incomingDeal;
	undef %outgoingDeal;
	undef %currentDeal;
	undef $currentChatRoom;
	undef @currentChatRoomUsers;
	undef @playersID;
	undef @monstersID;
	undef @portalsID;
	undef @itemsID;
	undef @npcsID;
	undef @identifyID;
	undef @spellsID;
	undef @petsID;
	undef %players;
	undef %monsters;
	undef %portals;
	undef %items;
	undef %npcs;
	undef %spells;
	undef %incomingParty;
	undef $msg;
	undef %talk;
	# Original was undef $ai_v{'temp'};
	undef %{$ai_v{'temp'}};
	undef @{$cart{'inventory'}};
	# Undefine at initConnectVars()
	#undef %storage;
#Karasu Start
	# Avoid stuck
	undef %{$ai_v{'avoidStuck'}};
	# Guild request clear
	undef %incomingGuild;
	# Make arrow
	undef @arrowID;
	# Autospell
	undef @autospellID;
	# Smithery and pharmacy
	undef @makeID;
	# Pet call
	undef @callID;
	# Teleport on event
	undef $ai_v{'temp'}{'teleOnEvent'};
	# Vendor clear
	undef @articles;
	undef @vendorListID;
	undef %vendorList;
	undef @vendorItemList;
	undef %shop;
	undef $currentVendingShop;
#Karasu End
#Ayon Start
	# PVP mode clear
	undef %{$chars[$config{'char'}]{'pvp'}};
	# Chatroom clear
	undef @chatRoomsID;
	undef %chatRooms;
	# Important item clear
	if ($ai_v2{'ImportantItem'}{'attackAuto'} ne "") {
		$config{'attackAuto'} = $ai_v2{'ImportantItem'}{'attackAuto'};
		undef %{$ai_v2{'ImportantItem'}};
	}
	undef @{$ai_v2{'ImportantItem'}{'targetID'}};

	undef %warp;
#Ayon End
}

sub quit {
	$quit = 1;
	my $hide = shift;
	$sc_v{'kore'}{'quit'} = 1;
	$sc_v{'kore'}{'delay'} = shift;

	print "呼～  終於可以休息了～\n" if (!$hide);
}

sub relog {
	$sc_v{'input'}{'conState'} = 1;
	undef $sc_v{'input'}{'conState_tries'};
	print "重新連線到主伺服器... ";
}

#Karasu
sub useTeleport {
	my $level = shift;
	my $invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", $level + 600);
	my $invTelePos;
	undef $ai_v{'teleQueue'};

	my $teleAllow = 1 if (
		!$chars[$config{'char'}]{'skill_ban'}
		&& (
			$config{'teleportAuto_param1'}
			|| !$chars[$config{'char'}]{'param1'}
		)
#		&& (
#			!$config{'teleportAuto_useSkill'}
#			|| $invIndex ne ""
#			|| $chars[$config{'char'}]{'sp'} >= $skillsSP_lut{'AL_TELEPORT'}{$chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'}}
#		)
	);
	# Equip for teleport

	my $val = 1;

	if (
		$config{'equipAuto_teleport'} ne ""
		&& !$config{'teleportAuto_useItem'}
		&& !$chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'}
		&& $teleAllow
	) {
		$invTelePos = ai_equip_special($config{'equipAuto_teleport'});
	}

	if (
		$map_control{lc($field{'name'})}{'teleport_allow'} == 1
		|| ($map_control{lc($field{'name'})}{'teleport_allow'} == 2 && $level == 2)
		|| $sc_v{'temp'}{'dcOnDualLogin'}
		|| $level > 2
	) {
		if (
			!$config{'teleportAuto_useItem'}
			&& (
				$chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'}
				|| $invTelePos ne ""
			) && $teleAllow
		) {
			if (
				(
					!$config{'teleportAuto_onSitting'}
					|| $warp{'use'} != 26
				)
				&& $chars[$config{'char'}]{'sitting'}
			) {
				sendStand(\$remote_socket);
				sleep(0.5);
			}
#			sendSkillUse(\$remote_socket, $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'ID'}, $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'}, $accountID) if ($warp{'use'} != 26 && $config{'teleportAuto_useSkill'});
			sendTeleport(\$remote_socket, "Random") if ($level == 1 || $level > 2);
			sendTeleport(\$remote_socket, $config{'saveMap'}.".gat") if ($level == 2);

			$chars[$config{'char'}]{'sendTeleport'} = $level;
		} elsif ($invIndex ne "" && $teleAllow) {
			if ($chars[$config{'char'}]{'sitting'}) {
				sendStand(\$remote_socket);
				timeOutStart('ai_sit');
				sleep(0.5);
			}
			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $accountID);
		} elsif (!scalar(@{$chars[$config{'char'}]{'inventory'}}) && $teleAllow) {
			undef $ai_v{'temp'}{'teleOnEvent'};
			if ($ai_v{'teleOnGM'}) {
				undef $ai_v{'teleOnGM'};
				undef %{$ai_v{'dcOnGM_counter'}};
				quitOnEvent("dcOnGM", "迴避", "瞬移失敗: 尚未接收到物品封包", "gm");
			} else {
				$ai_v{'teleQueue'} = $level;
			}

			$val = 0;
		} else {
			undef $ai_v{'temp'}{'teleOnEvent'};
			if (!$teleAllow && $chars[$config{'char'}]{'skill_ban'}) {
				$display = "你處在禁止聊天和使用技能的狀態下！";
			} elsif (!$teleAllow && $chars[$config{'char'}]{'param1'}) {
				$display = "你已經$messages_lut{'0119_A'}{$chars[$config{'char'}]{'param1'}}了！";
			} elsif (
				!$teleAllow
				&& $config{'teleportAuto_useSkill'}
				&& $chars[$config{'char'}]{'sp'} < $skillsSP_lut{'AL_TELEPORT'}{$chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'}}
			) {
				$display = "你已經SP不足無法使用瞬移的技能！";
			} else {
				$display = "你沒有可以使用瞬移的技能或物品！";
			}
			print "◆瞬移失敗: $display\n";
			if ($ai_v{'teleOnGM'}) {
				undef $ai_v{'teleOnGM'};
				undef %{$ai_v{'dcOnGM_counter'}};
				quitOnEvent("dcOnGM", "迴避", "瞬移失敗: $display", "gm");
			} else {
#				chatLog("危險", "瞬移失敗: $display", "d");
				sysLog("tele", "危險", "瞬移失敗: $display");
			}
			$val = 0;
		}

	} elsif ($level == 1) {
		undef $ai_v{'temp'}{'teleOnEvent'};
		print "◆瞬移失敗: 你無法在目前的地圖($field{'name'})瞬移！\n";
		if ($ai_v{'teleOnGM'}) {
			undef $ai_v{'teleOnGM'};
			undef %{$ai_v{'dcOnGM_counter'}};
			quitOnEvent("dcOnGM", "迴避", "瞬移失敗: 你無法在目前的地圖($field{'name'})瞬移", "gm");
		} else {
#			chatLog("危險", "瞬移失敗: 你無法在目前的地圖($field{'name'})瞬移", "d");
			sysLog("tele", "危險", "瞬移失敗: 你無法在目前的地圖($field{'name'})瞬移");
		}

		$val = 0;
	} elsif ($level == 2) {
		print "◆瞬移失敗: 你無法從目前的地圖($field{'name'})瞬移回儲存點！\n";
#		chatLog("危險", "瞬移失敗: 你無法從目前的地圖($field{'name'})瞬移回儲存點", "d");
		sysLog("event", "危險", "瞬移失敗: 你無法從目前的地圖($field{'name'})瞬移回儲存點");

		$val = 0;
	}

	return $val;
}

#######################################
#######################################
#CONFIG MODIFIERS
#######################################
#######################################

sub auth {
	my $user = shift;
	my $flag = shift;
	if ($flag) {
		printC("◇賦予玩家 '$user' 遠端控制的授權\n", "s");
	} else {
		printC("◇撤銷玩家 '$user' 遠端控制的授權\n", "s");
	}
	$overallAuth{$user} = $flag;
	writeDataFile("$sc_v{'path'}{'control'}/overallAuth.txt", \%overallAuth);
}

sub configModify {
	my $key = shift;
	my $val = shift;
	printC("◇Config '$key' 設定成 $val\n", "s");
	$config{$key} = $val;
	writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);
}

#sub setTimeout {
#	my $timeout = shift;
#	my $time = shift;
#	$timeout{$timeout}{'timeout'} = abs($time);
#	printC("◇Timeout '$timeout' 設定成 ".abs($time)."\n", "s");
#	writeDataFileIntact2("$sc_v{'path'}{'control'}/timeouts.txt", \%timeout);
#}

#######################################
#######################################
#FILE PARSING AND WRITING
#######################################
#######################################

# New chagLog function
#sub chatLog {
#	my $type = shift;
#	my $message = shift;
#	my $msg_type = shift;
#	my $filename;
#
#	$filename = "Chat.txt" if ($msg_type eq "c1" || $msg_type eq "c2" || $msg_type eq "s");
#	$filename = "ChatRoom.txt" if ($msg_type eq "cr");
#	$filename = "Guild.txt" if ($msg_type eq "g");
#	$filename = "Party.txt" if ($msg_type eq "p");
#	$filename = "PrivateMsg.txt" if ($msg_type eq "pm");
#
#	$filename = "iItemsLog.txt" if ($msg_type eq "ii");
#	$filename = "StuckLog.txt" if ($msg_type eq "st");
#	$filename = "ShopLog.txt" if ($msg_type eq "sh");
#	$filename = "ChatRoomTitle.txt" if ($msg_type eq "crt");
#	$filename = "Alert.txt" if ($msg_type eq "gm" || $msg_type eq "d" || $msg_type eq "im" || $msg_type eq "e" );
#
#	$type = "[$type] " if ($type ne "");
#	open(CHAT, ">> $sc_v{'path'}{'def_logs'}"."$filename");
#	print CHAT "[".getFormattedDate(int(time))."]".$type.$message."\n";
#	close(CHAT);
#}

#sub chatLog_clear {
#	my $type = shift;
#	my @chatFiles = ("Chat.txt", "ChatRoom.txt", "Guild.txt", "Party.txt", "PrivateMsg.txt", "Alert.txt");
#	if ($type eq "all") {
#		@chatFiles = (@chatFiles, "iItemsLog.txt", "ExpLog.txt", "StuckLog.txt", "StorageLog.txt", "CmdLog.txt", "MonsterData.txt", "ChatRoomTitle.txt");
#	}
#	foreach (@chatFiles) {
#		if (-e "$sc_v{'path'}{'def_logs'}"."$_") {
#			unlink("$sc_v{'path'}{'def_logs'}"."$_");
#			print "已清除 $sc_v{'path'}{'def_logs'}"."$_...\n";
#		}
#	}
#}

sub getResponse {
	my $type = shift;
	my $key;
	my @keys;
	my $msg;
	foreach $key (keys %responses) {
		if ($key =~ /^$type\_\d+$/) {
			push @keys, $key;
		}
	}
	$msg = $responses{$keys[int(rand(@keys))]};
	$msg =~ s/\%\$(\w+)/$responseVars{$1}/eig;
	return $msg;
}

sub updateDamageTables {
	my ($ID1, $ID2, $damage) = @_;

	if ($ID1 eq $accountID) {
		if (%{$monsters{$ID2}}) {
			$monsters{$ID2}{'dmgTo'} += $damage;
			$monsters{$ID2}{'dmgFromYou'} += $damage;
			if ($damage == 0) {
				$monsters{$ID2}{'missedFromYou'}++;
			} elsif ($monsters{$ID2}{'param1'}) {
				$monsters{$ID2}{'param1'} = 0;
			}
			if (binFind(\@MVPID, $monsters{$ID2}{'nameID'}) ne "") {
				$record{'mvp'}{$monsters{$ID2}{'nameID'}}{'dmgTo'}{'time'} = time;
				$record{'mvp'}{$monsters{$ID2}{'nameID'}}{'dmgTo'}{'map'} += $damage;
			}
		} elsif (%{$players{$ID2}}) {
			$players{$ID2}{'dmgTo'} += $damage;
			$players{$ID2}{'dmgFromYou'} += $damage;
			if ($damage == 0) {
				$players{$ID2}{'missedFromYou'}++;
			} elsif ($players{$ID2}{'param1'}) {
				$players{$ID2}{'param1'} = 0;
			}
		}
	} elsif ($ID2 eq $accountID) {
		if (%{$monsters{$ID1}}) {
			$monsters{$ID1}{'dmgFrom'} += $damage;
			$monsters{$ID1}{'dmgToYou'} += $damage;
			if ($damage == 0) {
				$monsters{$ID1}{'missedYou'}++;
			} else {
				$sc_v{'ai'}{'onHit'} = $damage;
			}
			timeOutStart('ai_event_onHit');

			if (binFind(\@MVPID, $monsters{$ID1}{'nameID'}) ne "") {
				$record{'mvp'}{$monsters{$ID1}{'nameID'}}{'dmgFrom'}{'time'} = time;
				$record{'mvp'}{$monsters{$ID1}{'nameID'}}{'dmgFrom'}{'map'} += $damage;
			}

#			my $t_m_t = $mon_control{lc($monsters{$ID1}{'name'})}{'teleport_auto'};

			my $teleported;
			my $tele_verbose;

			if($config{'teleportAuto_deadly'} && $damage >= $chars[$config{'char'}]{'hp'}){
				$tele_verbose = "[Act] Next $damage dmg could kill you. Teleporting...\n";
				$teleported = 2;
			} elsif ($config{'teleportAuto_deadly'} && $chars[$config{'char'}]{'hp'} <= 1) {
				$tele_verbose = "[Act] Next $damage dmg could kill you. Teleporting...\n";
				$teleported = 2;
			} elsif ($damage > 0 && !$sc_v{'temp'}{'itemsImportantAutoMode'}){
				if ($config{'teleportAuto_whenDmgToYou'}){
					$tele_verbose = "[Act] $monsters{$ID1}{'name'} attack you $damage dmg. Teleporting...\n";
					$teleported = 1;
				} elsif ($config{'teleportAuto_maxDmg'} && $damage >= $config{'teleportAuto_maxDmg'}){
					$tele_verbose = "[Act] $monsters{$ID1}{'name'} attack you more than $config{'teleportAuto_maxDmg'} dmg. Teleporting...\n";
					$teleported = 1;
				}
			}

			if ($chars[$config{'char'}]{'hp'} > $damage) {
				$chars[$config{'char'}]{'hp'} -= $damage;
			} elsif ($chars[$config{'char'}]{'hp'} <= $damage) {
				$chars[$config{'char'}]{'hp'} = 1;
			}

			if ($teleported && !($sc_v{'temp'}{'teleOnEvent'} && $ai_v{'temp'}{'teleOnEvent'})){
				$ai_v{'temp'}{'teleOnEvent'} = 1;
				timeOutStart('ai_teleport_event');
				$sc_v{'temp'}{'teleOnEvent'} = useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;
#				ai_clientSuspend(0, 1);

				printVerbose($config{'teleportAuto_verbose'}, $tele_verbose, "tele");

				ai_stopByTele(1);

#				my $ai_index = binFind(\@ai_seq, "take");
#
#				if ($ai_index ne "" && $ai_seq_args[$ai_index]{'mode'}) {
#					sysLog("ii", "順移", "撿取物品失敗: $items{$ai_seq_args[$ai_index]{'ID'}}{'name'} ($items{$ai_seq_args[$ai_index]{'ID'}}{'binID'}) 你瞬間移動了", 1);
#				}
			} elsif ($teleported > 1) {
				$ai_v{'temp'}{'teleOnEvent'} = 1;
				timeOutStart('ai_teleport_event');
				$sc_v{'temp'}{'teleOnEvent'} = useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;
#				ai_clientSuspend(0, 1);

				printVerbose($config{'teleportAuto_verbose'}, $tele_verbose, "tele");

				ai_stopByTele(1);

#				my $ai_index = binFind(\@ai_seq, "take");
#
#				if ($ai_index ne "" && $ai_seq_args[$ai_index]{'mode'}) {
#					sysLog("ii", "順移", "撿取物品失敗: $items{$ai_seq_args[$ai_index]{'ID'}}{'name'} ($items{$ai_seq_args[$ai_index]{'ID'}}{'binID'}) 你瞬間移動了", 1);
#				}
			}
		}
	} elsif (%{$monsters{$ID1}}) {
		if (%{$players{$ID2}}) {
			$monsters{$ID1}{'dmgFrom'} += $damage;
			$monsters{$ID1}{'dmgToPlayer'}{$ID2} += $damage;
			$players{$ID2}{'dmgFromMonster'}{$ID1} += $damage;
			if ($damage == 0) {
				$monsters{$ID1}{'missedToPlayer'}{$ID2}++;
				$players{$ID2}{'missedFromMonster'}{$ID1}++;
			} elsif ($players{$ID2}{'param1'}) {
				$players{$ID2}{'param1'} = 0;
			}
			if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$ID2}}) {
				$monsters{$ID1}{'dmgToParty'} += $damage;
				$monsters{$ID1}{'missedToParty'}++ if ($damage == 0);
			}
		}

	} elsif (%{$players{$ID1}}) {
		if (%{$monsters{$ID2}}) {
			$monsters{$ID2}{'dmgTo'} += $damage;
			$monsters{$ID2}{'dmgFromPlayer'}{$ID1} += $damage;
			$players{$ID1}{'dmgToMonster'}{$ID2} += $damage;
			if ($damage == 0) {
				$monsters{$ID2}{'missedFromPlayer'}{$ID1}++;
				$players{$ID1}{'missedToMonster'}{$ID2}++;
			} elsif ($monsters{$ID2}{'param1'} != 5) {
				$monsters{$ID2}{'param1'} = 0;
			}
			if (%{$chars[$config{'char'}]{'party'}} && %{$chars[$config{'char'}]{'party'}{'users'}{$ID1}}) {
				$monsters{$ID2}{'dmgFromParty'} += $damage;
				$monsters{$ID1}{'missedFromParty'}++ if ($damage == 0);
			}
		}
	}
}


#######################################
#######################################
#MISC FUNCTIONS
#######################################
#######################################

sub compilePortals {
	my($i, $map, $portal, @tmpArgs, $ID);

	undef %mapPortals;
	foreach (keys %portals_lut) {

		$ID = $portals_lut{$_}{'nameID'};

		%{$mapPortals{$portals_lut{$_}{'source'}{'map'}}{$ID}{'pos'}} = %{$portals_lut{$_}{'source'}{'pos'}};
	}
	$l = 0;
	foreach $map (keys %mapPortals) {
		foreach $portal (keys %{$mapPortals{$map}}) {

#			@tmpArgs = split /\s/, $portal;
#
#			$portal = "$tmpArgs[0] $tmpArgs[1] $tmpArgs[2]";

#			$portal = $mapPortals{$map}{'nameID'};

			foreach (keys %{$mapPortals{$map}}) {

#				@tmpArgs = split /\s/, $_;
#
#				$_ = "$tmpArgs[0] $tmpArgs[1] $tmpArgs[2]";

#				$_ = $mapPortals{$map}{'nameID'};

				next if ($_ eq $portal);

				if ($portals_los{$portal}{$_} eq "" && $portals_los{$_}{$portal} eq "") {
					if ($field{'name'} ne $map) {
						print "正在處理地圖: ".getMapName($map, 1)."\n";
						getField("$sc_v{'path'}{'fields'}/$map.fld", \%field);
					}
					print "計算傳送點之間的路徑: $portal -> $_\n";
					ai_route_getRoute(\@solution, \%field, \%{$mapPortals{$map}{$portal}{'pos'}}, \%{$mapPortals{$map}{$_}{'pos'}});
					compilePortals_getRoute();
					$portals_los{$portal}{$_} = (@solution) ? 1 : 0;
				}
			}
		}
	}

	writePortalsLOS("$sc_v{'path'}{'tables'}/portalsLOS.txt", \%portals_los);

	print "\n將傳送點間的直線路徑資料表寫入 $sc_v{'path'}{'tables'}/portalsLOS.txt\n\n";

}

sub compilePortals_check {
	my $r_return = shift;
	my (%mapPortals, @tmpArgs, $ID);
	undef $$r_return;
#	foreach (keys %portals_lut) {
#		%{$mapPortals{$portals_lut{$_}{'source'}{'map'}}{$_}{'pos'}} = %{$portals_lut{$_}{'source'}{'pos'}};
#	}
	foreach (keys %portals_lut) {

		$ID = $portals_lut{$_}{'nameID'};

		%{$mapPortals{$portals_lut{$_}{'source'}{'map'}}{$ID}{'pos'}} = %{$portals_lut{$_}{'source'}{'pos'}};
	}
	foreach $map (keys %mapPortals) {

		foreach $portal (keys %{$mapPortals{$map}}) {

#			@tmpArgs = split /\s/, $portal;
#
#			$portal = "$tmpArgs[0] $tmpArgs[1] $tmpArgs[2]";

#			$portal = $mapPortals{$map}{'nameID'};

			foreach (keys %{$mapPortals{$map}}) {

#				@tmpArgs = split /\s/, $_;
#
#				$_ = "$tmpArgs[0] $tmpArgs[1] $tmpArgs[2]";

#				$_ = $mapPortals{$map}{'nameID'};

				next if ($_ eq $portal);
				if ($portals_los{$portal}{$_} eq "" && $portals_los{$_}{$portal} eq "") {
					$$r_return = 1;
					return;
				}
			}
		}
	}
}

sub compilePortals_getRoute {
	if ($ai_seq[0] eq "route_getRoute") {
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
			$ai_seq_args[0]{'timeout'} = 90000;
		}
		$ai_seq_args[0]{'init'} = 1;
		ai_route_searchStep(\%{$ai_seq_args[0]});
		ai_route_getRoute_destroy(\%{$ai_seq_args[0]});
		shift @ai_seq;
		shift @ai_seq_args;
	}
}

sub getTickCount {
	my $time = int(time()*1000);
	if (length($time) > 9) {
		return substr($time, length($time) - 8, length($time));
	} else {
		return $time;
	}
}

sub portalExists {
	my ($map, $r_pos) = @_;
	foreach (keys %portals_lut) {
		if ($portals_lut{$_}{'source'}{'map'} eq $map && $portals_lut{$_}{'source'}{'pos'}{'x'} == $$r_pos{'x'}
			&& $portals_lut{$_}{'source'}{'pos'}{'y'} == $$r_pos{'y'}) {
			return $_;
		}
	}
}

# Avoid specified player
sub avoidPlayer {
	my $ID = shift;
	my $AID = unpack("L1", $ID);

	if (!$ai_v{'temp'}{'teleOnEvent'} && !$cities_lut{$field{'name'}.'.rsw'}
		&& (existsInList_quote($config{'teleportAuto_player'}, $players{$ID}{'name'})
			|| existsInList($config{'teleportAuto_player_AID'}, $AID))) {
		print "◆發現玩家: $players{$ID}{'name'} [$AID] 出現！\n";
		print "◆啟動 teleportAuto_player - 瞬間移動！\n";
#		chatLog("迴避", "發現玩家: $players{$ID}{'name'} [$AID] 出現, 瞬間移動！", "gm");
		sysLog("gm", "迴避", "發現玩家: $players{$ID}{'name'} [$AID] 出現, 瞬間移動！");
		$ai_v{'temp'}{'teleOnEvent'} = 1;
		timeOutStart('ai_teleport_event');
		useTeleport(1);
		$ai_v{'clear_aiQueue'} = 1;
	}
}

# Avoid stuck
sub avoidStuck {
	my ($i, $j);
	my $check;
	my $isStuck;

	for ($i = -1; $i < 2; $i++) {
		for ($j = -1; $j < 2; $j++) {
			next if ($i == 0 && $j == 0);
			$check++ if (ai_route_getOffset(\%field, $chars[$config{'char'}]{'pos_to'}{'x'} + $i, $chars[$config{'char'}]{'pos_to'}{'y'} + $j));
		}
	}
	if (($config{'unstuckAuto_margin'} && $check >= $config{'unstuckAuto_margin'})
		|| ($config{'unstuckAuto_rfcount'} && $ai_v{'avoidStuck'}{'route_failed'} >= $config{'unstuckAuto_rfcount'})
		|| ($config{'unstuckAuto_mfcount'} && $ai_v{'avoidStuck'}{'move_failed'} >= $config{'unstuckAuto_mfcount'})) {
		$ai_v{'avoidStuck_tries'}++;
		if ($config{'unstuckAuto_utcount'} && $ai_v{'avoidStuck_tries'} >= $config{'unstuckAuto_utcount'}) {
			undef $ai_v{'avoidStuck_tries'};
			$isStuck = 3;
		} else {
			$isStuck = 2;
		}
	} elsif ($config{'unstuckAuto_mfcount'} && ($ai_v{'avoidStuck'}{'move_failed'} == int($config{'unstuckAuto_mfcount'}/2))) {
		$isStuck = 1;
	}
	if ($isStuck) {
		aiRemove("move");
		aiRemove("route");
		aiRemove("route_getRoute");
		aiRemove("route_getMapRoute");
		ai_clientSuspend(0, 5);

		if ($isStuck == 3 || ($isStuck == 2 && $map_control{lc($field{'name'})}{'teleport_allow'} != 1)) {
			print "◆可能卡點: 似乎無法以 瞬間移動解決, 採取最後手段 重新載入DLL檔！\n";
#			chatLog("防卡", "可能卡點: 似乎無法以 瞬間移動解決, 採取最後手段 重新載入DLL檔！", "st");
#			chatLog("防卡", "目前位置 【$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."】", "st");

			sysLog("st", "防卡",
				["可能卡點: 似乎無法以 瞬間移動解決, 採取最後手段 重新載入DLL檔！"
				,"目前位置 【$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."】"]
			);

			importDynaLib();
		} elsif ($isStuck == 2) {
			print "◆可能卡點: 無法移動前往目的地, 嘗試以 瞬間移動解決！\n";
#			chatLog("防卡", "可能卡點: 無法移動前往目的地, 嘗試以 瞬間移動解決！", "st");
#			chatLog("防卡", "目前位置 【$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."】", "st");

			sysLog("st", "防卡",
				["可能卡點: 無法移動前往目的地, 嘗試以 瞬間移動解決！"
				,"目前位置 【$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."】"]
			);

			useTeleport(1);
			$ai_v{'clear_aiQueue'} = 1;
		} elsif ($isStuck == 1) {
			my $half_mfcount = int($config{'unstuckAuto_mfcount'}/2);
#			print "◆可能卡點: 連續移動失敗 $half_mfcount次, 嘗試以 重新計算移動路線解決！\n";
#			chatLog("防卡", "可能卡點: 連續移動失敗 $half_mfcount次, 嘗試以 重新計算移動路線解決！", "st");
			sysLog("st", "防卡", "可能卡點: 連續移動失敗 $half_mfcount次, 嘗試以 重新計算移動路線解決！", 1);
		} elsif ((getMapName($field{'name'}, 0, 1) || getMapName($field{'name'}, 0, 2)) && $ai_v{'avoidStuck'}{'route_failed'} > $config{'unstuckAuto_indoor'}) {

			my $tmp = ((getMapName($field{'name'}, 0, 1) ne "")?"室":"城市");

			print "◆可能卡點: ${tmp}內計算路徑失敗 $config{'unstuckAuto_indoor'}次，離線$timeout{'ai_unstuckAuto_indoor'}{'timeout'}秒！\n";

			sysLog("st", "防卡",
				["可能卡點: ${tmp}內計算路徑失敗 $config{'unstuckAuto_indoor'}次，離線$timeout{'ai_unstuckAuto_indoor'}{'timeout'}秒！"
				,"目前位置 【$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."】"]
			);

			$sc_v{'input'}{'MinWaitRecon'} = 1;
			relogWait("", $timeout{'ai_unstuckAuto_indoor'}{'timeout'});
		}
	}
}

# Get important items
sub getImportantItems {
	my $ID = shift;
	my $dist = shift;
	my $switch = shift;
	my $msg;
	my $found;
	if ($switch eq "009D") {
		$msg = "靜靜的躺在";
	} elsif ($switch eq "009E") {
		$msg = "出現在";
	}

	my $name	= $items{$ID}{'name'};
	my $nameID	= $items{$ID}{'nameID'};
	my $tmpVal	= $record{'importantItems'}{$nameID};
	my $tmpPick	= $itemsPickup{lc($items{$ID}{'name'})};

	if ($tmpPick >= 3) {
#		$found = 3;
		$found = $tmpPick;
	} elsif ($tmpVal > 0){
		$found = 2;
	} elsif ($tmpVal < 0 || ($tmpPick <= 0 && $tmpPick ne "")){
		$found = 0;
	} else {
		$found = -1;

		foreach(@importantItems){
			if ($name =~ /\Q$_\E/) {
				$found = 1;
				last;
			}
		}
		$record{'importantItems'}{$nameID} = $found;
	}
	if ($config{'itemsImportantAutoMode'}){
		if ($sc_v{'temp'}{'itemsImportantAutoMode'} && $found < 5) {

		} elsif ($found) {
			if ($ai_v2{'ImportantItem'}{'attackAuto'} eq "") {
				$ai_v2{'ImportantItem'}{'attackAuto'} = $config{'attackAuto'};
			}
			unshift @{$ai_v2{'ImportantItem'}{'targetID'}}, $ID;
			$config{'attackAuto'} = 0;
			sendAttackStop(\$remote_socket);
			aiRemove("attack");
			aiRemove("skill_use");
			take($ID, $found);
			sendTake(\$remote_socket, $ID);

			my $why;

			if ($found >= 5) {
				$sc_v{'temp'}{'itemsImportantAutoMode'} = 1;
				$why = "unless";
			} else {
				$sc_v{'temp'}{'itemsImportantAutoMode'} = 0;
				$why = ("keyword", "record", "pickup", "pickup", "unless")[$found-1];
			}

			print "◆重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) $msg距離你 $dist格的地上！(Type: $why)\n";
			print "◆啟動 itemsImportantAuto - 立即撿取！\n";
			# Beep on event
			event_beep("iItemsFound");

	#		chatLog("", "重要物品: $items{$ID}{'name'} $msg距離你 $dist格的地上, 立即撿取！", "ii");
			sysLog("ii", "", "重要物品: $items{$ID}{'name'} $msg距離你 $dist格的地上, 立即撿取！");
		}
	} elsif ($found > 0){
		if ($ai_v2{'ImportantItem'}{'attackAuto'} eq "") {
			$ai_v2{'ImportantItem'}{'attackAuto'} = $config{'attackAuto'};
		}
		unshift @{$ai_v2{'ImportantItem'}{'targetID'}}, $ID;
		$config{'attackAuto'} = 0;
		sendAttackStop(\$remote_socket);
		aiRemove("attack");
		aiRemove("skill_use");
		take($ID, $found);
		sendTake(\$remote_socket, $ID);

		my $why = ("keyword", "record", "pickup")[$found-1];

		print "◆重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) $msg距離你 $dist格的地上！(Type: $why)\n";
		print "◆啟動 itemsImportantAuto - 立即撿取！\n";
		# Beep on event
		event_beep("iItemsFound");

#		chatLog("", "重要物品: $items{$ID}{'name'} $msg距離你 $dist格的地上, 立即撿取！", "ii");
		sysLog("ii", "", "重要物品: $items{$ID}{'name'} $msg距離你 $dist格的地上, 立即撿取！");
	}
}

sub importDynaLib {
	undef $CalcPath_init;
	undef $CalcPath_pathStep;
	undef $CalcPath_destroy;

	if (!$config{'buildType'}) {
		$CalcPath_init = new Win32::API("Tools", "CalcPath_init", "PPNNPPN", "N");
		die "Could not locate Tools.dll" if (!$CalcPath_init);

		$CalcPath_pathStep = new Win32::API("Tools", "CalcPath_pathStep", "N", "N");
		die "Could not locate Tools.dll" if (!$CalcPath_pathStep);

		$CalcPath_destroy = new Win32::API("Tools", "CalcPath_destroy", "N", "V");
		die "Could not locate Tools.dll" if (!$CalcPath_destroy);
	} elsif ($config{'buildType'} == 1) {
		$ToolsLib = new C::DynaLib("./Tools.so");

		$CalcPath_init = $ToolsLib->DeclareSub("CalcPath_init", "L", "p","p","L","L","p","p","L");
		die "Could not locate Tools.so" if (!$CalcPath_init);

		$CalcPath_pathStep = $ToolsLib->DeclareSub("CalcPath_pathStep", "L", "L");
		die "Could not locate Tools.so" if (!$CalcPath_pathStep);

		$CalcPath_destroy = $ToolsLib->DeclareSub("CalcPath_destroy", "", "L");
		die "Could not locate Tools.so" if (!$CalcPath_destroy);
	}
}

# Record monster data
sub recordMonsterData {
	my $ID = shift;
	my @temp;
	unless(-e "$sc_v{'path'}{'def_logs'}"."MonsterData.txt") {
		open(FILE, ">"."$sc_v{'path'}{'def_logs'}"."MonsterData.txt");
		close(FILE);
	}
	open(FILE, "+<"."$sc_v{'path'}{'def_logs'}"."MonsterData.txt");
	while (<FILE>) {
		chomp;
		if (/^\[[\s\S]*?\]\Q$monsters{$ID}{'name'}\E[\s\S]*?\Q$maps_lut{$field{'name'}.'.rsw'}($field{'name'})\E/) {
			if (binFind(\@MVPID, $monsters{$ID}{'nameID'}) eq "" && binFind(\@RMID, $monsters{$ID}{'nameID'}) eq "") {
				undef @temp;
				return;
			}
		} else {
			push(@temp, $_."\n");
		}
	}
	my $temp_string = "[".getFormattedDate(int(time))."]".sprintf("%-23s", "$monsters{$ID}{'name'}")." $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($monsters{$ID}{'pos_to'}{'x'}, $monsters{$ID}{'pos_to'}{'y'})."\n";
	unshift(@temp, $temp_string);
	truncate(FILE, 0);
	seek(FILE, 0, 0);
	print FILE @temp;
	close(FILE);
	print "The data of monster $monsters{$ID}{'name'} has been recorded.\n" if ($config{'debug'});
	undef @temp;
}

# Record player data
sub recordPlayerData {
	my $ID = shift;
	my $hexID = getHex($ID);
	my $AID = unpack("L1", $ID);
	my $ID_string = "[".sprintf("%8d", $AID).":$hexID]";
	my $description = "(".sprintf("%2d", $players{$ID}{'lv'})."等/".substr($jobs_lut{$players{$ID}{'jobID'}}, 0, 4)."/$sex_lut{$players{$ID}{'sex'}})";
	my $appearance  = "[武:$items_lut{$players{$ID}{'weapon'}}/盾:$items_lut{$players{$ID}{'shield'}}]";
	my @temp;
	unless(-e "$sc_v{'path'}{'def_logs'}"."PlayerData.txt") {
		open(FILE, ">"."$sc_v{'path'}{'def_logs'}"."PlayerData.txt");
		close(FILE);
	}
	open(FILE, "+<"."$sc_v{'path'}{'def_logs'}"."PlayerData.txt");
	while (<FILE>) {
		chomp;
		if (/^\[[\s\S]*?\]\Q$players{$ID}{'name'}\E[\s\S]*?\Q$ID_string\E/) {
			if (/^\[[\s\S]*?\]\Q$players{$ID}{'name'}\E[\s\S]*?\Q$ID_string\E[\s\S]*?$appearance/) {
				undef @temp;
				return;
			}
		} else {
			push(@temp, $_."\n");
		}
	}
	my $temp_string = "[".getFormattedDate(int(time))."]".sprintf("%-23s", "$players{$ID}{'name'}")." $ID_string $description <".sprintf("%-23s", "$players{$ID}{'party'}{'name'}")."> [".sprintf("%-23s", "$players{$ID}{'guild'}{'name'}")."]: ".sprintf("%-23s", "$players{$ID}{'guild'}{'men'}{$players{$ID}{'name'}}{'title'}")." $appearance\n";
	unshift(@temp, $temp_string);
	truncate(FILE, 0);
	seek(FILE, 0, 0);
	print FILE @temp;
	close(FILE);
	print "The data of player $players{$ID}{'name'} has been recored.\n" if $config{'debug'};
	undef @temp;
}

#Ayon Start

sub getFormattedCoords {
	my $x = shift;
	my $y = shift;
	return sprintf("(%3d,%3d)", $x, $y);
}

#sub getAttackString {
#	my $attack_in = shift;
#	my $random_in = shift;
#	my $attack_out;
#	my $random_out;
#	my $r_string;
#	$attack_out = ("完全不", "被動", "主動")[$attack_in];
#	$random_out = ("未啟動", "啟動")[$random_in];
#	$r_string = "$attack_out攻擊, $random_out隨機路徑移動";
#	return $r_string;
#}

#sub getOutlookString {
#	my $sit_in = shift;
#	my $body_in = shift;
#	my $head_in = shift;
#	my $sit_out;
#	my $body_out;
#	my $head_out;
#	my $r_string;
#	$sit_out = ("站姿", "坐姿")[$sit_in];
#	$body_out = ("北", "西北", "西", "西南", "南", "東南", "東", "東北")[$body_in];
#	$head_out = ("正前", "右前", "左前")[$head_in];
#	$r_string = "$sit_out, 面向$body_out方, 臉朝$head_out方";
#	return $r_string;
#}

sub modifyName {
	my $r_hash = shift;
	my $modified;
	my @card;
	my ($i, $j);

	if (!$$r_hash{'type_equip'} || (!$$r_hash{'attribute'} && !$$r_hash{'refined'} && !$$r_hash{'card'}[0] && !$$r_hash{'star'})) {
		return 0;
	} else {
		if ($$r_hash{'refined'}) {
			$modified .= "+$$r_hash{'refined'} ";
		}
		if ($$r_hash{'star'}) {
			$modified .= "$stars_lut{$$r_hash{'star'}} ";
		}

		$modified .= $$r_hash{'name'};

		for ($i = 0; $i < 4; $i++) {
			last if !$$r_hash{'card'}[$i];
			if (@card) {
				for ($j = 0; $j <= @card; $j++) {
					if ($card[$j]{'ID'} eq $$r_hash{'card'}[$i]) {
						$card[$j]{'amount'}++;
						last;
					} elsif ($card[$j]{'ID'} eq "") {
						$card[$j]{'ID'} = $$r_hash{'card'}[$i];
						$card[$j]{'amount'} = 1;
						last;
					}
				}
			} else {
				$card[0]{'ID'} = $$r_hash{'card'}[$i];
				$card[0]{'amount'} = 1;
			}
		}
		if (@card) {
			$modified .= " ";
			for ($i = 0; $i < @card; $i++) {
				$modified .= "[";
				if ($card[$i]{'amount'} == 1) {
					$modified .= $cards_lut{$card[$i]{'ID'}};
				} else {
					$modified .= "$card[$i]{'amount'}X$cards_lut{$card[$i]{'ID'}}";
				}
				$modified .= "]";
			}
		}

		if ($$r_hash{'attribute'}) {
			$modified .= " [$attribute_lut{$$r_hash{'attribute'}}]";
		}
		$$r_hash{'name'} = $modified;
	}
}

sub playWave {
	my $file = shift;
	my $type = shift;

	Win32::Sound::Stop();
	if ($file eq "stop") {
		print "停止播放 $playingWave\n";
		undef $playingWave;
	} else {
		$file = "sounds/Def.wav" if ($config{'beep'} == 1 && $type ne "test");
		Win32::Sound::Play($file, SND_ASYNC);
		if ($config{'beep'} == 2 || $type eq "test") {
			if (!(-e $file)) {
				print "無法載入音效檔($file), 你必須安裝KoreC Sound Pack！\n\n";
				undef $playingWave;
			} else {
				$playingWave = $file;
			}
		}
	}
}

sub printS {
	my $string = shift;
	my $printC = shift;
	my $sourceID = shift;
	my $targetID = shift;
	my $exception = shift;
	my $attackID;
	my ($castBy, $castOn);
	my $ai_index = binFind(\@ai_seq, "attack");
	if ($ai_index ne "") {
		$attackID = $ai_seq_args[$ai_index]{'ID'};
	}
	if ($sourceID ne "") {
		if (%{$monsters{$sourceID}}) {
			$castBy = 2;
		} elsif (%{$players{$sourceID}}) {
			$castBy = 4;
		} elsif ($sourceID eq $accountID) {
			$castBy = 1;
		} else {
			$castBy = 8;
		}
	}
	if ($targetID ne "") {
		if ($targetID eq "floor") {
			$castOn = 16;
		} elsif (%{$monsters{$targetID}}) {
			$castOn = 2;
		} elsif (%{$players{$targetID}}) {
			$castOn = 4;
		} elsif ($targetID eq $accountID) {
			$castOn = 1;
		} else {
			$castOn = 8;
		}
	}
	if ($castBy == 1 || $castOn == 1
		|| ($castBy == 2 && $sourceID eq $attackID) || ($castOn == 2 && $targetID eq $attackID)
		|| !$config{'hideMsg_skill'}
		|| !($config{'hideMsg_skill'} eq "all" || (existsInList2($config{'hideMsg_skill_castBy'}, $castBy, "and") && existsInList2($config{'hideMsg_skill_castOn'}, $castOn, "and")))
		|| $config{'debug'}
	) {
		if ($printC ne "") {
			printC($string, $printC);
		} else {
			print "$string";
		}
	}
}

sub relogWait {
	my $message = shift;
	my $waittime = shift;

	if ($message ne "") {
		print "$message\n";
	}
	killConnection(\$remote_socket);
	if ($sc_v{'input'}{'conState'} == 4 || $sc_v{'input'}{'conState'} == 5) {
		undef %ai_v;
		undef @ai_seq;
		undef @ai_seq_args;
		parseReload("config") if (!$sc_v{'kore'}{'lock'});
		importDynaLib();
	}
	$sc_v{'input'}{'conState'} = 1;
	undef $sc_v{'input'}{'conState_tries'};
	$timeout_ex{'master'}{'time'} = time;
	$timeout_ex{'master'}{'timeout'} = $waittime;
}

sub resetTimeout {
	my ($i, $j) = (0, 0);
#	while (1) {
#		last if (!$config{"useSelf_item_$i"});
#		undef $ai_v{"useSelf_item_$i"."_time"};
#		$i++;
#	}
#	$i = 0;
#	while (1) {
#		last if (!$config{"useSelf_skill_$i"});
#		undef $ai_v{"useSelf_skill_$i"."_time"};
#		$i++;
#	}
#	$i = 0;
#	while (1) {
#		last if (!$config{"attackSkillSlot_$i"});
#		undef $ai_v{"attackSkillSlot_$i"."_time"};
#		$i++;
#	}
	my @arg = ("useSelf_item_", "useSelf_skill_", "attackSkillSlot_", "useParty_skill_");

	foreach (@arg) {
		$i = 0;
		while ($config{"$_$i"}) {
			undef $ai_v{"$_$i"."_time"};
			$i++;
		}
	}
}

sub respawnUndefine {
	my $map_string = shift;
	if ($config{'respawnAuto_undef'} && $map_control{lc($map_string)}{'restrict_map'} ne "1"
		&& $map_string ne "" && $map_string ne $config{'lockMap'} && $map_string ne $config{'saveMap'}) {
		print "◆限定地圖: 你出現在非限定地圖($map_string)！\n";
		print "◆啟動 respawnAuto_undef - 瞬間移動回儲存點！\n";
#		chatLog("危險", "限定地圖: 你出現在非限定地圖($map_string), 瞬間移動回儲存點！", "d");
		sysLog("event", "危險", "限定地圖: 你出現在非限定地圖($map_string), 瞬間移動回儲存點！");
		if ($map_control{lc($map_string)}{'teleport_allow'} >= 1) {
			useTeleport(2);
			$ai_v{'clear_aiQueue'} = 1;
		} else {
#			chatLog("危險", "限定地圖: 你無法從目前的地圖($map_string)瞬移回儲存點, 立即登出！", "d");
			sysLog("event", "危險", "限定地圖: 你無法從目前的地圖($map_string)瞬移回儲存點, 立即登出！");
#			$quit = 1;

			quit(1, 1);
		}
	}
}

sub quitOnEvent {
	my $event = shift;
	my $chatlog_arg1 = shift;
	my $chatlog_arg2 = shift;
	my $chatlog_arg3 = shift;

	$quitBczGM = 1 if ($event eq "dcOnGM");

	if ($config{$event} == 1) {
		printC("◆啟動 $event - 立即登出！\n", "s");
#		chatLog($chatlog_arg1, $chatlog_arg2.", 立即登出！", $chatlog_arg3);
		sysLog($chatlog_arg3, $chatlog_arg1, $chatlog_arg2.", 立即登出！");
#		$quit = 1;

		quit(1, 1);

	} elsif ($config{$event} >= 2) {
		$sc_v{'input'}{'MinWaitRecon'} = 1;
		$sc_v{'input'}{'autoStartPause'} = 1;
#		chatLog($chatlog_arg1, $chatlog_arg2.", 暫時離線 $config{$event}秒！", $chatlog_arg3);
		sysLog($chatlog_arg3, $chatlog_arg1, $chatlog_arg2.", 暫時離線 $config{$event}秒！");
		relogWait("◆啟動 $event - 暫時離線 $config{$event}秒！", $config{$event});

	}
}

sub avoidGM {
	my $ID = shift;
	my $name = shift;
	my $type = shift;
	my $count = shift;
	my $area;

	$ID = ai_getIDFromChat(\%players, $name, "") if ($ID eq "");
	my $AID = ($ID ne "") ? unpack("L1", $ID) : "";

	if ($field{'name'} eq $config{'lockMap'}) {
		$area = 4;
	} elsif ($cities_lut{$field{'name'}.'.rsw'}) {
		$area = 1;
	} else {
		$area = 2;
	}
	if ($config{'dcOnGM'}) {
		if (
			(
				$name =~ /^GM\d{2,3}/i
				|| $autoLogoff{$name}
				|| ($players{$ID}{'param3'} & 64)
				|| binFind(\@{$GMAID_lut{$config{"master_host_$config{'master'}"}}}, $AID) ne ""
				|| binFind(\@{$GMAID_lut{'255.255.255.255'}}, $AID) ne ""
			)
			&& $autoLogoff{$name} ne "0"
		){
			# Beep on event
			playWave("sounds/GM.wav", "100%") if ($config{'beep'} && $config{'beep_GM'});
			my $display = ($AID ne "") ? " [$AID]" : "";
			$name = "不明人物" if ($name eq "");
			my $times = $ai_v{'dcOnGM_counter'}{$name} + 1;

			if (!$ai_v{'teleOnGM'} && $count && $config{'dcOnGM_ignoreArea'} && existsInList2($config{'dcOnGM_ignoreArea'}, $area, "and")) {
				print "◆發現ＧＭ: $name$display $type！\n";
				print "◆啟動 dcOnGM_ignoreArea - 按兵不動！\n";
#				chatLog("迴避", "發現ＧＭ: $name$display $type, 按兵不動！", "gm");
				sysLog("gm", "迴避", "發現ＧＭ: $name$display $type, 按兵不動！");
			} elsif (!$ai_v{'teleOnGM'} && $count && $config{'dcOnGM_count'} && !$cities_lut{$field{'name'}.'.rsw'} && $times <= $config{'dcOnGM_count'}) {
				print "◆發現ＧＭ: $name$display $type($times)！\n";
				print "◆啟動 dcOnGM_count - 瞬間移動！\n";
#				chatLog("迴避", "發現ＧＭ: $name$display $type($times), 瞬間移動！", "gm");
				sysLog("gm", "迴避", "發現ＧＭ: $name$display $type($times), 瞬間移動！");
				$ai_v{'teleOnGM'} = 1;
				$ai_v{'teleOnGM'} = 2 if ($times == $config{'dcOnGM_count'});
			} else {
				print "◆發現ＧＭ: $name$display $type！\n";
				undef $ai_v{'teleOnGM'};
				undef %{$ai_v{'dcOnGM_counter'}};
				quitOnEvent("dcOnGM", "迴避", "發現ＧＭ: $name$display $type", "gm");
			}

#			chatLog("迴避", "目前位置 【$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."】", "gm");
#			chatLog("迴避", "ＧＭ位置 【$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($players{$ID}{'pos_to'}{'x'}, $players{$ID}{'pos_to'}{'y'})."】", "gm") if ($ID ne "" && %{$players{$ID}});

			sysLog("gm", "迴避", "目前位置 【$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."】");
			sysLog("gm", "迴避", "ＧＭ位置 【$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($players{$ID}{'pos_to'}{'x'}, $players{$ID}{'pos_to'}{'y'})."】") if ($ID ne "" && %{$players{$ID}});

			if ($ai_v{'teleOnGM'}) {
				$ai_v{'dcOnGM_counter'}{$name}++;
				$ai_v{'temp'}{'teleOnEvent'} = 1;
				timeOutStart('ai_teleport_event');
				useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;
			}
		}
	}
}

1;