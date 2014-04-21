sub onEvent {
	my $event = shift;


}

sub event_attack {
	my $ID = shift;

}

sub event_00B1 {
	my ($type, $val) = @_;

	$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

	if ($type == 1) {
		$chars[$config{'char'}]{'exp_last'} = $chars[$config{'char'}]{'exp'};
		$chars[$config{'char'}]{'exp'} = $val;
		print "Exp: $val\n" if ($config{'debug'});
		if ($chars[$config{'char'}]{'exp_last'} > $chars[$config{'char'}]{'exp'} && $sc_v{'exp'}{'lv_up'}) {
			$sc_v{'exp'}{'base_add'} += $chars[$config{'char'}]{'exp_max_last'} - $chars[$config{'char'}]{'exp_last'} + $chars[$config{'char'}]{'exp'};
			undef $sc_v{'exp'}{'lv_up'};
		} elsif ($chars[$config{'char'}]{'exp_last'} < $chars[$config{'char'}]{'exp'}) {
			$sc_v{'exp'}{'base_add'} += $chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'exp_last'};
		}
		$sc_v{'exp'}{'base'} += $sc_v{'exp'}{'base_add'} if ($chars[$config{'char'}]{'exp_max'} != $chars[$config{'char'}]{'exp'});
	} elsif ($type == 2) {
		$chars[$config{'char'}]{'exp_job_last'} = $chars[$config{'char'}]{'exp_job'};
		$chars[$config{'char'}]{'exp_job'} = $val;
		print "Job Exp: $val\n" if ($config{'debug'});
		if ($chars[$config{'char'}]{'exp_job_last'} > $chars[$config{'char'}]{'exp_job'} && $sc_v{'exp'}{'lv_job_up'}) {
			$sc_v{'exp'}{'job_add'} += $chars[$config{'char'}]{'exp_job_max_last'} - $chars[$config{'char'}]{'exp_job_last'} + $chars[$config{'char'}]{'exp_job'};
			undef $sc_v{'exp'}{'lv_job_up'};
		} elsif ($chars[$config{'char'}]{'exp_job_last'} < $chars[$config{'char'}]{'exp_job'}) {
			$sc_v{'exp'}{'job_add'} += $chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'exp_job_last'};
		}
		$sc_v{'exp'}{'job'} += $sc_v{'exp'}{'job_add'} if ($chars[$config{'char'}]{'exp_job_max'} != $chars[$config{'char'}]{'exp_job'});
	} elsif ($type == 20) {
		my $tmp_zenny = $val - $chars[$config{'char'}]{'zenny'};

		if ($shop{'opened'}) {
			$shop{'earnedLast'} = $tmp_zenny;
		}

		if ($chars[$config{'char'}]{'zenny'} && $tmp_zenny){
			my $tmp_tag = (($tmp_zenny < 0)?'-':'+');
			$record{'zenny'}{"$tmp_tag"} += abs($tmp_zenny);
		}
		$chars[$config{'char'}]{'zenny'} = $val;
		print "Zenny: $val\n" if ($config{'debug'});
	} elsif ($type == 22) {
		$chars[$config{'char'}]{'exp_max_last'} = $chars[$config{'char'}]{'exp_max'};
		$chars[$config{'char'}]{'exp_max'} = $val;
		print "Required Exp: $val\n" if ($config{'debug'});

		setTimeOut('ai_addAuto') if ($config{'autoAddStatusOrSkill'});

	} elsif ($type == 23) {
		$chars[$config{'char'}]{'exp_job_max_last'} = $chars[$config{'char'}]{'exp_job_max'};
		$chars[$config{'char'}]{'exp_job_max'} = $val;
		print "Required Job Exp: $val\n" if ($config{'debug'});

		setTimeOut('ai_addAuto') if ($config{'autoAddStatusOrSkill'});

	}

	if ($type == 2 && ($sc_v{'exp'}{'base_add'} || $chars[$config{'char'}]{'exp_max'} == $chars[$config{'char'}]{'exp'})) {
		my $tmp_f = "%.3f";
		my $percentB = "(".sprintf($tmp_f, $sc_v{'exp'}{'base_add'} * 100 / $chars[$config{'char'}]{'exp_max'})."%)" if ($chars[$config{'char'}]{'exp_max'});
		my $percentJ = "(".sprintf($tmp_f, $sc_v{'exp'}{'job_add'} * 100 / $chars[$config{'char'}]{'exp_job_max'})."%)" if ($chars[$config{'char'}]{'exp_job_max'});
		printC("[EXP] BaseExp: $sc_v{'exp'}{'base_add'} $percentB \/ JobExp: $sc_v{'exp'}{'job_add'} $percentJ\n", "exp", 1);

		$sc_v{'exp'}{'base_add'} = 0;
		$sc_v{'exp'}{'job_add'} = 0;
	}
}

sub event_beep {
	my $type = shift;
	my $mode = shift;
	my $val;

	return 0 if (!$config{'beep'});

	$type = switchInputFix(
		$type,
		'Deal',
		# 收到交易邀請時播放音效，對應sounds/Deal.wav(0=關、1=開)
		'Death',
		# 死亡時播放音效，對應sounds/Death.wav(0=關、1=開)
		'GM',
		# 偵測到GM時播音效，對應sounds/GM.wav(0=關、1=開)
		'Guest',
		# 玩家進入聊天室時播放音效，對應sounds/Guest.wav(0=關、1=開)
		'iItemsFound',
		# 發現重要物品時播放音效，對應sounds/iItemsFound.wav(0=關、1=開)
		'iItemsGot',
		# 獲得重要物品時播放音效，對應sounds/iItemsGot.wav(0=關、1=開)
		'C',
		# 收到聊天頻道訊息時播放音效，對應sounds/C.wav(0=關、1=開)
		'G',
		# 收到公會頻道訊息時播放音效，對應sounds/G.wav(0=關、1=開)
		'P',
		# 收到隊伍頻道訊息時播放音效，對應sounds/P.wav(0=關、1=開)
		'PM',
		# 收到密語頻道訊息時播放音效，對應sounds/PM.wav(0=關、1=開)
		'S'
		# 收到公告頻道訊息時播放音效，對應sounds/S.wav(0=關、1=開)
	);

	if ($config{"beep_${type}"}){
		playWave("sounds/${type}.wav", $mode);
		$val = 1;
	} else {
		$val = 0;
	}
	return $val;
}

sub event_online {
	my ($type, $ID, $TargetID, $name, $online) = @_;

	if (switchInput($type, '016D', '01F2')) {
		if ($ID ne $accountID && $TargetID ne $accountID) {
			if ($charID_lut{$TargetID}) {
				$name = ($charID_lut{$TargetID} ne "" ? $charID_lut{$TargetID} : $players{$TargetID}{'name'});
				$sc_v{'event'}{'isOnline'} = (($online) ? "Log In" : "Log Out");

#				$charID_lut{$TargetID}{(($online) ? "login" : "logout")} = time;

				sysLog("g", "成員", "Guild Member : $name $sc_v{'event'}{'isOnline'}", 1, !$config{'recordGuildMember'});
			} else {
				$players{$TargetID}{'online'} = $online;

#				addCharName($TargetID, $name, $players{$ID}{'online'});

				sendNameRequest(\$remote_socket, $TargetID);
			}
		}
	} elsif (switchInput($type, '0194')) {
		if ($ID ne $accountID) {
			$charID_lut{$ID} = $name;

			addCharName($ID, $name, $players{$ID}{'online'});

			if ($players{$ID}{'online'} ne "") {
#				$charID_lut{$ID}{($players{$ID}{'online'} ? "login" : "logout")} = time;

				$sc_v{'event'}{'isOnline'} = ($players{$ID}{'online'} ? "Log In" : "Log Out");

				sysLog("g", "成員", "Guild Member : $name $sc_v{'event'}{'isOnline'}", 1, !$config{'recordGuildMember'});

				undef $players{$ID}{'online'};
			}
		}
	}
}

sub event_chat {
	my ($type, $uesr, $msg, $ID, $options) = @_;
	my ($tag, $tag2, $display, $type_c);

	my $c = " : ";

	$type = lc $type;
	$type_c = $type;

	$uesr	= $uesr;
	$msg	= $msg;

	if ($type eq "p"){
		$tag = "隊伍";
	} elsif ($type eq "g"){
		$tag = "工會";
	} elsif ($type eq "s"){
		$tag = "公告";

		$uesr = $msg if ($user eq "");
		$msg = $uesr if ($msg eq "");

		$uesr = $msg;
		$msg = "";

		undef $c;

	} elsif ($type eq "pm"){
		$tag = "密語";
		if ($options ne "") {
			$tag2 = 'To';

			$user	= $lastpm[0]{'user'};
			$msg	= $lastpm[0]{'msg'};

			$user	= $sc_v{'pm'}{'lastTo'};
			$msg	= $sc_v{'pm'}{'lastMsg'};

			if ($ID == 1) {
				$display = "($user) 目前不在線上\n";
			} elsif ($ID == 2) {
				$display = "($user) 拒絕你的密語\n";
			} elsif ($ID == 3) {
				$display = "($user) 拒絕所有密語\n";
			}

			shift @lastpm;
		} else {
			$tag2 = 'From';

			if ($user ne "" && binFind(\@privMsgUsers, $user) eq "") {
				$privMsgUsers[@privMsgUsers] = $user;
			}
		}

		$tag2 = "($tag2 $uesr)";

		undef $options;
		undef $ID;
	} else {
		if ($currentChatRoom ne "") {
			$tag = "聊天室";
			$type = "cr";
		} else {
			$tag = "聊天";
			$type = "c";
		}

		if (%{$players{$ID}}) {
			$tag2 = "$uesr ($players{$ID}{'binID'})";
			$options = "(GID:".unpack("L1", $ID)."/".sprintf("%2d", $players{$ID}{'lv'})."等/".substr($jobs_lut{$players{$ID}{'jobID'}}, 0, 4)."/$sex_lut{$players{$ID}{'sex'}}/".sprintf("%2d", int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ID}{'pos_to'}})))."格)";
		}
	}

	$tag2 = $uesr if (!$tag2);
	$tag2 = "$options $tag2" if ($options);

	$display = "${tag2}${c}${msg}" if (!$display);

	event_beep($type);
	printC("[${tag}] $display\n", $type_c, 1);
#	chatLog($tag, $display, $type);
	sysLog($type, $tag, $display);

	if (!switchInput($type, "s")) {
		if ($config{'autoAdmin'}) {
			$ai_cmdQue[$ai_cmdQue]{'type'}	= $type;
			$ai_cmdQue[$ai_cmdQue]{'ID'}	= $ID;
			$ai_cmdQue[$ai_cmdQue]{'user'}	= $user;
			$ai_cmdQue[$ai_cmdQue]{'msg'}	= $msg;
			$ai_cmdQue[$ai_cmdQue]{'time'}	= time;
			$ai_cmdQue++;
		}

		avoidGM("", $user, "在$tag頻道發言", 0);
	}

#	if ($config{'dcOnGM'} && !$quitBczGM) {
	if ($config{'dcOnGM'}) {
		my ($found, @array, $seperate, $text);

		$seperate = (($config{'dcOnWord_split'}) ? $config{'dcOnWord_split'} : ",");

#		$msg = uc $msg;

		$msg = $uesr if (!$msg);

		splitUseArray(\@array, $config{(switchInput($type, "s") ? 'dcOnSysWord' : 'dcOnChatWord')}, $seperate);

		if ($config{'dcOnYourName'}) {
			unshift @array, "$chars[$config{'char'}]{'name'}";
			push @array, "$chars[$config{'char'}]{'name'}";

#			$found = 1 if ($msg =~ /\Q$chars[$config{'char'}]{'name'}\E/i);
		}

#		$msg = ucCht($msg);

		foreach (@array) {
			if ($config{'dcOnWord_quote'}) {
				($_) = $_ =~ /^"([\s\S]*?)"$/;
			}

			if ($msg =~ /\Q$_\E/i) {
				$found = 1;

				$text = $_;

				last;
			}

#			print "[$found] $_\n" if (switchInput($type, "s"));

#			print "[$found] $_\n";


		}

		if ($found && $config{'dcOnWord_checkNpc'} && @npcsID && switchInput($type, "s")) {
			undef @array;

			splitUseArray(\@array, $msg, ":");
			my $i;

			for ($i = 0; $i < @npcsID; $i++) {
#				next if ($npcsID[$i] eq "");

				if ($npcsID[$i] ne "" && $npcs{$npcsID[$i]}{'name'} eq $array[0]) {
					printC("◆啟動 dcOnWord_checkNpc - $tag頻道出現指定字詞【$text】 - 確認為NPC對話: $npcs{$npcsID[$i]}{'name'} ($npcs{$npcsID[$i]}{'binID'})\n", "s", 1);
					sysLog("gm", "忽略", "$tag頻道出現指定字詞【$text】 - 確認為NPC對話: $npcs{$npcsID[$i]}{'name'} ($npcs{$npcsID[$i]}{'binID'})");

					$found = 0;
					last;
				}
			}
		}

		if ($found) {
			printC("◆發現ＧＭ: $tag頻道出現指定字詞【$text】！\n", "s", 1);
			# Beep on event
			event_beep('GM');
			undef %{$ai_v{'dcOnGM_counter'}};
			quitOnEvent("dcOnGM", "迴避", "發現ＧＭ: $tag頻道出現指定字詞【$text】", "gm");
#				chatLog("迴避", "目前位置 【$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."】", "gm");
			sysLog("gm", "迴避", "目前位置 【$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."】");
		}
	}
}

sub event_death {
	$record{'counts'}{'dead'}++;
#	print "◆重要訊息: 你受到致命的一擊, 你死了！\n";
#	chatLog("重要", "重要訊息: $showHP{'killedBy'}{'who'} 的 $showHP{'killedBy'}{'how'}對你造成致命的傷害($showHP{'killedBy'}{'dmg'})！你死了！", "im");
	sysLog("event", "重要", "重要訊息: $showHP{'killedBy'}{'who'} 的 $showHP{'killedBy'}{'how'}對你造成致命的傷害($showHP{'killedBy'}{'dmg'})！你死了！", 1);
	undef %{$showHP{'killedBy'}};

	event_beep("Death");

	$chars[$config{'char'}]{'dead'} = 1;
	$chars[$config{'char'}]{'dead_time'} = time;
#Solos Start(死亡時關閉露店)
	event_shop_close(2);
}

sub event_checkInfo {
	if (!$chars[$config{'char'}]{'dead'} && !$chars[$config{'char'}]{'hp'}) {
#		chatLog("錯誤", "嚴重錯誤: 可能遺失HP資訊, 重新連線！", "e");
		sysLog("e", "錯誤", "嚴重錯誤: 可能遺失HP資訊, 重新連線！");
		$sc_v{'input'}{'MinWaitRecon'} = 1;
		relogWait("◆嚴重錯誤: 可能遺失HP資訊！", 1);
	}
}

sub event_0071 {
	my ($map_name, $map_ip, $map_port) = @_;

	return 0 if (!$config{'warpperMode'});

	if ($config{'mapserver'} eq "" && !$sc_v{'warpperMode'}{'done'}) {
		$i = 0;

		$sc_v{'warpperMode'}{'from_ip'} = $map_ip;

		my $tmp = "@<< @<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<< ";

		print subStrLine($tmp, "Map Servers", -1);
		print swrite($tmp, ["No", "Name", "Map IP"]);

		while ($config{"map_name_$config{'master'}"."_$config{'server'}"."_$i"} ne "") {
			print swrite($tmp, [$i, $config{"map_name_$config{'master'}"."_$config{'server'}"."_$i"}, $config{"map_host_$config{'master'}"."_$config{'server'}"."_$i"}]);

			$i++;
		}

		print subStrLine($tmp);

		print "Choose your map server:\n";
		$sc_v{'input'}{'waitingForInput'} = 1;
	} elsif ($config{'mapserver'} ne "" && !$sc_v{'warpperMode'}{'done'}) {

		scMapJump($config{"map_host_$config{'master'}"."_$config{'server'}"."_$config{'mapserver'}"}, $config{'map_port'});

	}

}

sub event_0073 {
	my $msg = shift;

	makeCoords(\%{$chars[$config{'char'}]{'pos'}}, substr($msg, 6, 3));

	$sc_v{'input'}{'conState'} = 5;
	undef $sc_v{'input'}{'conState_tries'};

	$CONSOLE->Title("$chars[$config{'char'}]{'name'}");

	%{$chars[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos'}};
	print "\n█▆▄▂▁你已進入遊戲▁▂▄▆█\n";

	if ($config{'warpperMode'} && !$sc_v{'warpperMode'}{'done'}) {
		$sc_v{'warpperMode'}{'done'} = 1;

		print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n";
		sendMapLoaded(\$remote_socket);
		print "Successfully transferred\n";

#		killConnection(\$remote_socket);
#		sleep(5);
#		relog();

		undef $ai_v{'teleOnGM'};
		sc_relog("{Event] warpperMode 重新取得地圖資訊\n");

		timeOutStart('ai');
	} else {
		print "你出現在: $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'})."\n";
		sendMapLoaded(\$remote_socket);

		# Set console title

		# Set ignore all
		sendIgnoreAll(\$remote_socket, !$config{'ignoreAll'}) if ($config{'ignoreAll'} ne "");
		# Avoid GM
		if ($ai_v{'teleOnGM'} == 2) {
			undef %{$ai_v{'dcOnGM_counter'}};
			quitOnEvent("dcOnGM", "迴避", "發現ＧＭ: 瞬移次數已滿", "gm");
		}
		undef $ai_v{'teleOnGM'};
		# Respawn at undefine map
		respawnUndefine($field{'name'});
		timeOutStart('ai');
	}
}

sub event_shop_selling {
	my ($index, $amount) = @_;

	$shop{'earned'} += $shop{'earnedLast'};

	sysLog("sh", "賣出", "賣出 $articles[$index]{'name'} x $amount - 獲得 ".toZeny($shop{'earnedLast'})." Zeny", 1);

	undef $shop{'earnedLast'};

	$articles[$index]{'amount'} -= $amount;
	$articles[$index]{'sold'} += $amount;
	if ($articles[$index]{'amount'} < 1) {
		$articles--;
		undef %{$articles[$index]};
	}

	if ($articles == 0) {

		sysLog("sh", "結束", "商品已全部賣出, 總收入: ".toZeny($shop{'earned'})." Zeny", 1);

		event_shop_close(1);

	}

}

sub event_shop_close {
	my $mode = shift;
	my $ex_mode - shift;

	if ($mode > 1){

		return 0 if (!$shop{'opened'} || !$myShop{'shop_closeOnDeath'});

	}

	sysLog("sh", "結束", "已賣出商品總收入: ".toZeny($shop{'earned'})." Zeny", 1) if ($shop{'earned'} && !$mode);
	sysLog("sh", "關閉", "結束擺\攤: 目前擁有 ".toZeny($chars[$config{'char'}]{'zenny'})." Zeny, 總收入: ".toZeny($shop{'earned'})." Zeny", 1);

	sendShopClose(\$remote_socket) if ($shop{'opened'});
	undef %shop;

#	ai_event_auto_parseInput("shop open") if ($mode && $myShop{'shop_autoReStart'} && !$ex_mode);
#
#	if ($myShop{'dcOnShopClosed'}) {
#
#		print "◆啟動 dcOnShopClosed - 立即登出！\n";
#		sysLog("im", "重要", "重要訊息: 結束擺\攤, 立即登出！");
#
#		$quit = 1;
#	}

	return 1;

}

sub event_mvp_get {
	my ($switch, $ID) = @_;
	return 0 if (!$config{'recordMonsterInfo_mvp'} || !$switch || !$ID);

	my $msg;
	my $display;

	if ($switch eq "010A") {
		$display = "你";
		$msg	= "成為ＭＶＰ！！取得MVP物品: $items_lut{$ID}";
	} elsif ($switch eq "010B") {
		$display = "你";
		$msg	= "成為ＭＶＰ！！獲得特殊經驗值: $ID";
	} elsif ($switch eq "010C") {
		if ($ID eq $accountID) {
			$display = "你";
		} elsif (%{$players{$ID}}) {
			$display = "$players{$ID}{'name'} ($players{$ID}{'binID'})";
		} else {
			$display = "不明人物[".unpack("L1", $ID)."]";

#			sendGetPlayerInfo(\$remote_socket, $ID);
		}
		$msg	= " 成為ＭＶＰ！！";
	}

	if ($msg ne "") {
		sysLog("mvp", "MVP", "${display}${msg}", 1);

		if ($display eq "你") {
			$display = "";
		} else {
			$display = "(GID:".unpack("L1", $ID)."/".sprintf("%2d", $players{$ID}{'lv'})."等/".substr($jobs_lut{$players{$ID}{'jobID'}}, 0, 4)."/$sex_lut{$ID}{'sex'}}) $display ";
		}

		$msg = "[MVP] $sc_v{'parseMsg'}{'server_name'} - ${display}${msg}";

		if ($config{'broadcastMode'}) {
			sendMessage(\$remote_socket, "p", $msg) if ($config{'broadcastMode'} != 2 && %{$chars[$config{'char'}]{'party'}});

			if ($config{'broadcastMode'} > 1 && $chars[$config{'char'}]{'guild'}{'ID'}) {
				sendMessage(\$remote_socket, "g", $msg);
			}
		}
	}
}

sub event_mvp {
	my ($switch, $ID) = @_;
	return 0 if (!$switch || !$ID);

	my $mode;
	my $t_type;
	my $t_dist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ID}{'pos_to'}}, 1);
	my $t_map = getMapName($field{'name'}, 1)." ".posToCoordinate(\%{$monsters{$ID}{'pos_to'}}, 1);
	my $name = $monsters{$ID}{'name'};
	my $nameID = $monsters{$ID}{'nameID'};

	my ($title, $msg);

	return 0 if ($ID eq $chars[$config{'char'}]{'pet'}{'ID'} || $t_dist == 0);

	$t_dist = int($t_dist);

	if (binFind(\@MVPID, $nameID) ne "") {
		$t_type = "MVP";
	} elsif ($config{'recordMonsterInfo_mvp'} > 1 &&  binFind(\@RMID, $nameID) ne "") {
		$t_type = "RM";
	} else {
		$mode = 1;
	}

	if ($mode < 1){
		if ($switch eq "0078") {
			$title	= "Exists";
			$msg	= "在 $t_map 發現 $name";
		} elsif ($switch eq "007C") {
			$title	= "Spawned";
			$msg	= "$name 出現在 $t_map";
		} elsif ($switch eq "0080") {
			$title	= "Died";
			$msg	= "$name - 陣亡在 $t_map";
		} elsif ($switch eq "007B" || $switch eq "022C") {
			$title	= "Move";
			$msg	= "$name - 移動到 $t_map";

			$mode = -1;
		} else {
			$mode = 1;
		}
	}

#Karasu Start - recordMonsterInfo
	# Record monster data
	recordMonsterData($ID) if ($config{'recordMonsterInfo'});
#Karasu End - recordMonsterInfo

	if ($mode < 1 && $nameID ne "" && $name ne "") {

		$record{'mvp'}{$nameID}{$title}{'time'} = time;
		$record{'mvp'}{$nameID}{$title}{'map'} = $t_map;

		if (!$mode || !$monsters{$ID}{'alert'}) {
			$msg = "[${t_type}] $sc_v{'parseMsg'}{'server_name'} - $msg";
#			" - 距離: $t_dist 格";

			if ($config{'broadcastMode'}) {
				sendMessage(\$remote_socket, "p", $msg) if ($config{'broadcastMode'} != 2 && %{$chars[$config{'char'}]{'party'}});

				if (
					$config{'broadcastMode'} > 1
					&& $chars[$config{'char'}]{'guild'}{'ID'}
				) {
					sendMessage(\$remote_socket, "g", $msg);
				}
			}

			$monsters{$ID}{'alert'} = 1;

			sysLog("mvp", $title, "$msg - 距離: $t_dist 格", 1, !$config{'recordMonsterInfo_mvp'});
		}

		if (
			$config{'attackAuto_mvpFirst'}
			&& (
				$config{'attackAuto_mvpFirst'} > 1
				|| $t_type eq "MVP"
			)
			&& $monsters{$ID}{'mvp'} != 1
			&& switchInput($switch, "0078", "007C", "007B", "022C")
			&& !$sc_v{'temp'}{'itemsImportantAutoMode'}
		) {
			$monsters{$ID}{'mvp'} = 1;

			if (!$chars[$config{'char'}]{'mvp'}) {
				attack($ID);
			}
#		} elsif (
#			switchInput($switch, "0080")
#			&& !switchInput($ai_seq[0], "take", "items_take")
#		) {
#			ai_items_take($monsters{$ID}{'pos'}{'x'}, $monsters{$ID}{'pos'}{'y'}, $monsters{$ID}{'pos_to'}{'x'}, $monsters{$ID}{'pos_to'}{'y'});
		}

	}

}

sub event_spell {
	my ($switch, $ID, $sourceID, $pos_x, $pos_y, $type) = @_;
	my ($sourceDisplay, $castBy, $targetDisplay, $s_cDist);

	$spells{$ID}{'sourceID'} = $sourceID;
	$spells{$ID}{'pos'}{'x'} = $pos_x;
	$spells{$ID}{'pos'}{'y'} = $pos_y;
	$spells{$ID}{'type'} = $type;

	my $binID = binAdd(\@spellsID, $ID);
	$spells{$ID}{'binID'} = $binID;

	($sourceDisplay, $castBy) = ai_getCaseID($sourceID);

#	$targetDisplay = ($messages_lut{'011F'}{$type} ne "")
#		? $messages_lut{'011F'}{$type}
#		: "不明型態 ".$type;

	$targetDisplay = getMsgStrings('011F', $type, 0, 1);

	$s_cDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$spells{$ID}{'pos'}});

	if (
		$messages_lut{'011F'}{$type} ne ""
		&& !existsInList($config{'hideMsg_groundEffect'}, $type)
		&& $config{'hideMsg_groundEffect'} ne "all"
		&& (
			$ai_v{'hideMsg_groundEffect'}{'sourceID'} ne $sourceID
			|| $ai_v{'hideMsg_groundEffect'}{'type'} ne $type
			|| timeOut($config{'hideMsg_groundEffect_timeout'}, $ai_v{'hideMsg_groundEffect_time'})
			|| $config{'debug'}
		)
	) {
		printS("★$sourceDisplay的 $targetDisplay 出現在座標: ".getFormattedCoords($coords{'x'}, $coords{'y'}).", 距離: $s_cDist\n", "", $sourceID, "floor");
		$ai_v{'hideMsg_groundEffect'}{'sourceID'} = $sourceID;
		$ai_v{'hideMsg_groundEffect'}{'type'} = $type;
		$ai_v{'hideMsg_groundEffect_time'} = time;
	}
#Karasu Start
	# Avoid ground effect skills
	my $i = 0;

#	while ($config{"useCast_spell_$i"}) {
##		last if (!$config{"useCast_spell_$i"});
#		if (
#			existsInList($config{"useCast_spel_$i"}, $targetDisplay)
#			&& existsInList2($config{"useCast_spell_$i"."_castBy"}, $castBy, "and")
#			&& (!$config{"useCast_spell_$i"."_dist"} || $s_cDist < $config{"useCast_spell_$i"."_dist"})
#			&& ($config{"useCast_spell_$i"."_inCity"} || !$cities_lut{$field{'name'}.'.rsw'})
#		) {
#
#		}
#		$i++;
#	}

	return if ($sc_v{'temp'}{'itemsImportantAutoMode'});

	$i = 0;

	while (1) {
		last if (!$config{"teleportAuto_spell_$i"} || $ai_v{'temp'}{'teleOnEvent'});
		if (
			existsInList($config{"teleportAuto_spell_$i"}, $targetDisplay)
			&& existsInList2($config{"teleportAuto_spell_$i"."_castBy"}, $castBy, "and")
			&& (!$config{"teleportAuto_spell_$i"."_dist"} || $s_cDist < $config{"teleportAuto_spell_$i"."_dist"})
			&& ($config{"teleportAuto_spell_$i"."_inCity"} || !$cities_lut{$field{'name'}.'.rsw'})
		) {
			if ($config{"teleportAuto_spell_$i"."_randomWalk"} ne "") {
				my @array;
				splitUseArray(\@array, $config{"teleportAuto_spell_$i"."_randomWalk"}, ",");
				do {
					$ai_v{'temp'}{'randX'} = $chars[$config{'char'}]{'pos_to'}{'x'} + int(rand() * ($array[1] * 2 + 1)) - $array[1];
					$ai_v{'temp'}{'randY'} = $chars[$config{'char'}]{'pos_to'}{'y'} + int(rand() * ($array[1] * 2 + 1)) - $array[1];
				} while (ai_route_getOffset(\%field, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
							|| $ai_v{'temp'}{'randX'} == $chars[$config{'char'}]{'pos_to'}{'x'} && $ai_v{'temp'}{'randY'} == $chars[$config{'char'}]{'pos_to'}{'y'}
							|| $ai_v{'temp'}{'randX'} == $coords{'x'} && $ai_v{'temp'}{'randY'} == $coords{'y'}
							|| abs($ai_v{'temp'}{'randX'} - $chars[$config{'char'}]{'pos_to'}{'x'}) < $array[0] && abs($ai_v{'temp'}{'randY'} - $chars[$config{'char'}]{'pos_to'}{'y'}) < $array[0]);

				move($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'});

				printC(
					"◆發現技能: $sourceDisplay施放的 $targetDisplay 距離你只剩 $s_cDist格！\n"
					."◆啟動 teleportAuto_spell - 隨機移動！\n"
					, "tele"
				);
				sysLog("tele", "迴避", "發現技能: $sourceDisplay施放的 $targetDisplay 距離你只剩 $s_cDist格, 隨機移動！");

				last;
			} else {

				$ai_v{'temp'}{'teleOnEvent'} = 1;
				timeOutStart('ai_teleport_event');
				$sc_v{'temp'}{'teleOnEvent'} = useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;

				printC(
					"◆發現技能: $sourceDisplay施放的 $targetDisplay 距離你只有 $s_cDist格！\n"
					."◆啟動 teleportAuto_spell - 瞬間移動！\n"
					, "tele"
				);
				sysLog("tele", "迴避", "發現技能: $sourceDisplay施放的 $targetDisplay 距離你只有 $s_cDist格, 瞬間移動！");

			}
		}
		$i++;
	}
}

sub event_deal {
	my ($switch, $type, $CID, $lv) = @_;

	if (switchInput($switch, "00E5", "01F4")) {
		$incomingDeal{'name'} = $type;

		if (switchInput($switch, "01F4")) {
			print "CID: $CID Lv: $lv\n";
		}

		$sc_v{'deal'}{'lastToYou'}{'name'}	= $type;
		$sc_v{'deal'}{'lastToYou'}{'CID'}	= $CID;
		$sc_v{'deal'}{'lastToYou'}{'lv'}	= $lv;

		print "($dealUser)詢問(先生／小姐)願不願意交易？\n";
		print "請輸入 'deal' 接受交易, 或輸入 'deal no' 拒絕交易\n";

		event_beep('Deal');
		timeOutStart(-1, 'ai_dealAuto');
	} elsif (switchInput($switch, "00E7", "01F5")) {
		if ($type == 3) {
			if (%incomingDeal) {
				$currentDeal{'name'} = $incomingDeal{'name'};
			} else {
				$currentDeal{'name'} = $players{$outgoingDeal{'ID'}}{'name'};
			}
			parseInput("dl");
		} else {
			$sc_v{'deal'}{'lastFromYou'}{'fall'}	= $type;

			printC(getMsgStrings($switch, $type, '', 2)."\n", "alert");
		}
		undef %outgoingDeal;
		undef %incomingDeal;
	} elsif (switchInput($switch, "00EC")) {
		if ($type == 1) {
			$currentDeal{'other_finalize'} = 1;
			print "$currentDeal{'name'} 確認此次交易\n";
		} else {
			$currentDeal{'you_finalize'} = 1;
			print "你確認此次交易\n";
		}
		parseInput("dl");
	} elsif (switchInput($switch, "00EE")) {
		undef %incomingDeal;
		undef %outgoingDeal;
		undef %currentDeal;
		printC("交易取消\n", "alert");
	} elsif (switchInput($switch, "00F0")) {
		print "交易物品成功\\n";
		undef %currentDeal;
	} elsif (switchInput($switch, "00E9")) {

	} elsif (switchInput($switch, "00EA")) {

	}
}

sub event_map {
	my ($switch, $msg) = @_;

	if ($switch eq "0091") {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		initMapChangeVars();

		for ($i = 0; $i < @ai_seq; $i++) {
			ai_setMapChanged($i);
		}

		($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;

		# Prevent lost map name
		if ($map_name eq "") {
#			chatLog("錯誤", "嚴重錯誤: 可能遺失地圖名稱, 重新連線！", "e");
			sysLog("e", "錯誤", "嚴重錯誤: 可能遺失地圖名稱, 重新連線！");
			relogWait("◆嚴重錯誤: 可能遺失地圖名稱！", 1);
		}

		$ai_v{'temp'}{'map'} = getMapID($map_name);

		$coords{'x'} = unpack("S1", substr($msg, 18, 2));
		$coords{'y'} = unpack("S1", substr($msg, 20, 2));
		%{$chars[$config{'char'}]{'pos'}} = %coords;
		%{$chars[$config{'char'}]{'pos_to'}} = %coords;

		$sc_v{'parseMsg'}{'map'} = $ai_v{'temp'}{'map'};

		if (
			$ai_v{'temp'}{'map'} ne $field{'name'} || $field{'name'} eq "" || !$field{'name'}
#			event_map_onChange($ai_v{'temp'}{'map'})
		) {
			getField("$sc_v{'path'}{'fields'}/$ai_v{'temp'}{'map'}.fld", \%field);

			$sc_v{'parseMsg'}{'map'} = $ai_v{'temp'}{'map'};

#			undef %{$chars[$config{'char'}]{'guild'}{'users'}};

			if (%{$chars[$config{'char'}]{'guild'}{'users'}}) {
				foreach (keys %{$chars[$config{'char'}]{'guild'}{'users'}}) {
					if ($chars[$config{'char'}]{'guild'}{'users'}{$_}{'ID'} eq "") {
						delete $chars[$config{'char'}]{'guild'}{'users'}{$_};
						next;
					}

					$chars[$config{'char'}]{'guild'}{'users'}{$_}{'onhere'} = 0;
				}
			}

#			timeOutStart(-1, 'ai_partyAutoCreate');
		}

		aiRemove("attack");

		print "地圖轉換到 - $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): ".getFormattedCoords($chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'})."\n";
		print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if ($config{'debug'});

		if (!$option{'X-Kore'}) {
			print "Sending Map Loaded\n" if ($config{'debug'});
			sendMapLoaded(\$remote_socket);

			# Avoid GM

			if ($ai_v{'teleOnGM'} == 2) {
				undef %{$ai_v{'dcOnGM_counter'}};
				quitOnEvent("dcOnGM", "迴避", "發現ＧＭ: 瞬移次數已滿", "gm");
			}

			undef $ai_v{'teleOnGM'};
			undef $sc_v{'temp'}{'teleOnEvent'};
			# Respawn at undefine map
			respawnUndefine($ai_v{'temp'}{'map'});
		} else {
#			timeOutStart(1, 'ai');
		}
	} elsif ($switch eq "0092") {
		if ($option{'X-Kore'}) {
			initMapChangeVars();
			$sc_v{'ai'}{'first'} = 1;
			timeOutStart('ai_first_wait');
		};
#		initConnectVars();

		$sc_v{'input'}{'conState'} = 4;
		undef $sc_v{'input'}{'conState_tries'};
		for ($i = 0; $i < @ai_seq; $i++) {
			ai_setMapChanged($i);
		}
		($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
		# Prevent lost map name
		if ($map_name eq "") {
#			chatLog("錯誤", "嚴重錯誤: 可能遺失地圖名稱, 重新連線！", "e");
			sysLog("e", "錯誤", "嚴重錯誤: 可能遺失地圖名稱, 重新連線！");
			relogWait("◆嚴重錯誤: 可能遺失地圖名稱！", 1);
		}

		$ai_v{'temp'}{'map'} = getMapID($map_name);
		$sc_v{'parseMsg'}{'map'} = $ai_v{'temp'}{'map'};

		$map_ip = makeIP(substr($msg, 22, 4));
		$map_port = unpack("S1", substr($msg, 26, 2));

		if ($ai_v{'temp'}{'map'} ne $field{'name'} || $field{'name'} eq "" || !$field{'name'}) {
			getField("$sc_v{'path'}{'fields'}/$ai_v{'temp'}{'map'}.fld", \%field);
			sysLog("map", "$switch", "Map: $field{'name'} IP: $map_ip Port: $map_port");
		}

		print swrite(
			 "\n ┌──── Game  Info ────┐",[]
			," ∣MAP  Name : @<<<<<<<<<<<<<<<∣",[$map_name]
			," ∣MAP  IP   : @<<<<<<<<<<<<<<<∣",[$map_ip]
			," ∣MAP  Port : @<<<<<<<<<<<<<<<∣",[$map_port]
			," └──────────────┘\n",[]
		);
		print "關閉與地圖伺服器的連線\n" if ($config{'debug'} || 1);

		if (!$option{'X-Kore'}) {
			killConnection(\$remote_socket);
		} else {
			timeOutStart(1, 'ai');
		}

		undef $sc_v{'temp'}{'teleOnEvent'};
	} elsif ($switch eq "0071") {
#		initConnectVars();
		print "由登入伺服器取得Char ID及Map IP\n" if ($config{'debug'});
		$sc_v{'input'}{'conState'} = 4;
		undef $sc_v{'input'}{'conState_tries'};
#Karasu Start
		# Reconnect when map chang bug fix
		undef @ai_seq;
		undef @ai_seq_args;
#Karasu End
		$sc_v{'input'}{'charID'} = substr($msg, 2, 4);
		($map_name) = substr($msg, 6, 16) =~ /([\s\S]*?)\000/;
		# Prevent lost map name
		if ($map_name eq "") {
#			chatLog("錯誤", "嚴重錯誤: 可能遺失地圖名稱, 重新連線！", "e");
			sysLog("e", "錯誤", "嚴重錯誤: 可能遺失地圖名稱, 重新連線！", 1);
			relogWait("◆嚴重錯誤: 可能遺失地圖名稱！", 1);
		}

		$ai_v{'temp'}{'map'} = getMapID($map_name);

		$sc_v{'parseMsg'}{'map'} = $ai_v{'temp'}{'map'};

		$map_ip = makeIP(substr($msg, 22, 4));
		$map_port = unpack("S1", substr($msg, 26, 2));

		if (!$field{'name'} || $ai_v{'temp'}{'map'} ne $field{'name'}) {
			getField("$sc_v{'path'}{'fields'}/$ai_v{'temp'}{'map'}.fld", \%field);
			sysLog("map", "$switch", "Map: $field{'name'} IP: $map_ip Port: $map_port");
		}

		print swrite(
			 "\n ┌──── Game  Info ────┐",[]
			," ∣Char ID   : @<<<<<<<<<<<<<<<∣",[getHex($sc_v{'input'}{'charID'})]
			," ∣MAP  Name : @<<<<<<<<<<<<<<<∣",[$map_name]
			," ∣MAP  IP   : @<<<<<<<<<<<<<<<∣",[$map_ip]
			," ∣MAP  Port : @<<<<<<<<<<<<<<<∣",[$map_port]
			," └──────────────┘\n",[]
		);

		if (!$option{'X-Kore'}) {

			print "關閉與登入伺服器的連線\n" if ($config{'debug'});
			killConnection(\$remote_socket);

			event_0071($map_name, $map_ip, $map_port);

		} else {
			timeOutStart(1, 'ai');
		}
	} elsif ($switch eq "0073") {

#		if ($option{'X-Kore'}) {
#			initConnectVars();
#		}

		makeCoords(\%{$chars[$config{'char'}]{'pos'}}, substr($msg, 6, 3));

		if ($option{'X-Kore'}) {
#			$sc_v{'input'}{'conState'} = 4;
		} else {
			$sc_v{'input'}{'conState'} = 5;
		}
		undef $sc_v{'input'}{'conState_tries'};

		$CONSOLE->Title("$chars[$config{'char'}]{'name'}");

		%{$chars[$config{'char'}]{'pos_to'}} = %{$chars[$config{'char'}]{'pos'}};

		if (!$option{'X-Kore'}) {

			print "\n█▆▄▂▁你已進入遊戲▁▂▄▆█\n";

			if ($config{'warpperMode'} && !$sc_v{'warpperMode'}{'done'}) {
				$sc_v{'warpperMode'}{'done'} = 1;

				print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n";
				sendMapLoaded(\$remote_socket);
				print "Successfully transferred\n";

		#		killConnection(\$remote_socket);
		#		sleep(5);
		#		relog();

				undef $ai_v{'teleOnGM'};
				sc_relog("{Event] warpperMode 重新取得地圖資訊\n");

				timeOutStart('ai');
			} else {
				print "你出現在: $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'})."\n";
				sendMapLoaded(\$remote_socket);

				# Set console title

				if ($config{'serverType'} != 0) {
					sendSync(\$remote_socket, 1);
					print "Sent initial sync\n" if ($config{'debug'});
				}

				# Set ignore all
				sendIgnoreAll(\$remote_socket, !$config{'ignoreAll'}) if ($config{'ignoreAll'} ne "");
				# Avoid GM
				if ($ai_v{'teleOnGM'} == 2) {
					undef %{$ai_v{'dcOnGM_counter'}};
					quitOnEvent("dcOnGM", "迴避", "發現ＧＭ: 瞬移次數已滿", "gm");
				}
				undef $ai_v{'teleOnGM'};
				# Respawn at undefine map
				respawnUndefine($field{'name'}) if (!$sc_v{'parseMsg'}{'dcOnDualLogin'});
				timeOutStart('ai');

#				timeOutStart(-1, 'ai_partyAutoCreate');

	#			timeOutStart(-1, 'ai_partyAutoCreate');

	#			$sc_v{'parseMsg'}{'dcOnDualLogin'}++ if ($sc_v{'parseMsg'}{'dcOnDualLogin'});
			}

		} else {
			print "Waiting for map to load...\n";
			timeOutStart(1, 'ai');
		}
	}
}

sub event_buyOrSell {
	my ($switch, $msg) = @_;

	if (switchInput($switch, "00C7")) {
		if (length($msg) > 4 && 0) {
			decrypt(\$newmsg, substr($msg, 4, length($msg) - 4));
			$msg = substr($msg, 0, 4).$newmsg;

			undef %{$sc_v{'sell'}} if (!$sc_v{'sell'}{'down'});

			my $file = "$sc_v{'path'}{'logs'}/items_prices.txt";

#			undef %{$sc_v{'sell'}};

#			parseDataFile2("$sc_v{'path'}{'def_logs'}\items_prices.txt", \%{$sc_v{'sell'}}) if (!%{$sc_v{'sell'}});
			parseItemsPrices("$file", \%{$sc_v{'sell'}});

#			my $tmp;
#			my @tmp;
#
#			if (%{$sc_v{'sell'}}) {
#
#				foreach (keys %{$sc_v{'sell'}}) {
#					next if ($sc_v{'sell'}{$_} eq "" || $_ eq "");
#
#					$sc_v{'sell'}{$_}{'value'} = "$sc_v{'sell'}{$_}";
#
##					undef @tmp;
##
##					@tmp = split(/ /, $sc_v{'sell'}{$_}{'value'});
##
##					$sc_v{'sell'}{$_}{'price'} = pop @tmp;
#				}
#
				$sc_v{'sell'}{'down'} = 1;
#			}

			my ($pa, $pb, $idx, $ID, $invIdx, $i, $j);

			my @sell_array = sort sortNum getItemList(\@{$chars[$config{'char'}]{'inventory'}}, $params[1], "Inventory", "", 2);;

			$invIdx = 0 - unpack("S1", substr($msg, 4, 2));

			#print "$invIdx\n";

			for ($i=4; $i<=length($msg); $i++) {
				$ID = unpack("S1", substr($msg, $i, 2));
				$pa = unpack("S1", substr($msg, $i+2, 4));
				$pb = unpack("S1", substr($msg, $i+6, 4));
#					print getName("items_lut", $ID)."\n";

				next if ($sell_array[$j] eq "" || $pa eq "" || $pb eq "");

#				$idx = $ID + $invIdx;

				$idx = $sell_array[$j];

				#print "$chars[$config{'char'}]{'inventory'}[$idx]{'index'} = $chars[$config{'char'}]{'inventory'}[$idx]{'name'}\n";
				#print "$pa -> $pb\n";

#					$sc_v{'sell'}{$chars[$config{'char'}]{'inventory'}[$idx]{'nameID'}}{'price'} = $pa;
#					$sc_v{'sell'}{$chars[$config{'char'}]{'inventory'}[$idx]{'nameID'}}{'price_new'} = $pb;

				$sc_v{'sell'}{$chars[$config{'char'}]{'inventory'}[$idx]{'nameID'}}{'value'} = "$pa -> $pb" if ($pa ne "" && $pb ne "");
				$sc_v{'sell'}{$chars[$config{'char'}]{'inventory'}[$idx]{'nameID'}}{'price'} = ($pb?$pb:$pa) if ($pa || $pb);

#				print "j: $j - $sell_array[$j] - $chars[$config{'char'}]{'inventory'}[$sell_array[$j]]{'name'}\n";
#				print "ID: $ID\n";
#				print "idx: $idx - invIdx: $invIdx\n";
#				print "$chars[$config{'char'}]{'inventory'}[$idx]{'nameID'}: $chars[$config{'char'}]{'inventory'}[$idx]{'name'}\n";
#				print "$pa -> $pb\n";

				$i += 9;
				$j++;
			}

#				writeDataFileIntact_sell();

			my $data;
#			my $file = "$sc_v{'path'}{'logs'}\items_prices.txt";

			foreach (sort sortNum keys %{$sc_v{'sell'}}) {
				next if ($sc_v{'sell'}{$_}{'value'} eq "" || $_ eq "");

				$data .= "\#".getName("items_lut", $_)."\n";
				$data .= "$_ $sc_v{'sell'}{$_}{'value'}\n";
			}

			open(FILE, "> $file");
			print FILE $data;
			close(FILE);

		}
		undef $talk{'buyOrSell'};
		print "$npcs{$talk{'ID'}}{'name'}: 請輸入 'sell <物品編號> [<數量>]' 賣出物品\n";
	} elsif (switchInput($switch, "00C4")) {
		undef %talk;
		$talk{'buyOrSell'} = 1;
		$talk{'ID'} = $msg;
		print "$npcs{$talk{'ID'}}{'name'}: 你是要買東西(buy), 還是要賣(sell)東西呢？\n";
	} elsif (switchInput($switch, "00C6")) {
		undef @storeList;
		$storeList = 0;
		undef $talk{'buyOrSell'};
		for ($i = 4; $i < $msg_size; $i+=11) {
			$price = unpack("L1", substr($msg, $i, 4));
			$price_dc = unpack("L1", substr($msg, $i + 4, 4));
			$type = unpack("C1", substr($msg, $i + 8, 1));
			$ID = unpack("S1", substr($msg, $i + 9, 2));
			$storeList[$storeList]{'nameID'} = $ID;
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "不明物品 ".$ID;
			$storeList[$storeList]{'name'} = $display;
			$storeList[$storeList]{'nameID'} = $ID;
			$storeList[$storeList]{'type'} = $type;
			$storeList[$storeList]{'price'} = $price;
			$storeList[$storeList]{'price_dc'} = $price_dc;
			print "Item added to Store: $storeList[$storeList]{'name'} - $price z\n" if ($config{'debug'} >= 2);
			$storeList++;
		}
		parseInput("store");
	}
}

sub event_takenBy {
#	00A1
#	$ID = substr($msg, 2, 4);
	my $ID = shift;

	if (%{$items{$ID}}) {
		print "Item Disappeared: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if ($config{'debug'});
#		%{$items_old{$ID}} = %{$items{$ID}};
#		$items_old{$ID}{'disappeared'} = 1;
#		$items_old{$ID}{'gone_time'} = time;

		$items{$ID}{'disappeared'} = 1;
		$items{$ID}{'gone_time'} = time;

		%{$items_old{$ID}} = %{$items{$ID}};

		# Important item fail
		if ($ai_v2{'ImportantItem'}{'attackAuto'} ne "" && binFind(\@{$ai_v2{'ImportantItem'}{'targetID'}}, $ID) ne "") {
			binRemoveAndShift(\@{$ai_v2{'ImportantItem'}{'targetID'}}, $ID);
			if (!binSize(\@{$ai_v2{'ImportantItem'}{'targetID'}})) {
				$config{'attackAuto'} = $ai_v2{'ImportantItem'}{'attackAuto'};
				undef %{$ai_v2{'ImportantItem'}};
				undef $sc_v{'temp'}{'itemsImportantAutoMode'};
			}
			if ($items{$ID}{'takenBy'} ne "") {
				if ($items{$ID}{'takenBy'} eq $accountID) {
					event_beep("iItemsGot");
					sysLog("ii", "自己", "$items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 獲得！");
				} elsif (%{$players{$items{$ID}{'takenBy'}}}) {
					my $options;
					$options = "(GID:".unpack("L1", $items{$ID}{'takenBy'})."/".sprintf("%2d", $players{$items{$ID}{'takenBy'}}{'lv'})."等/".substr($jobs_lut{$players{$items{$ID}{'takenBy'}}{'jobID'}}, 0, 4)."/$sex_lut{$players{$items{$ID}{'takenBy'}}{'sex'}}/".sprintf("%2d", int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$items{$ID}{'takenBy'}}{'pos_to'}})))."格) " if (!$config{'hideMsg_takenByInfo'});
					sysLog("ii", "玩家", "重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 被 ${options}$players{$items{$ID}{'takenBy'}}{'name'} ($players{$items{$ID}{'takenBy'}}{'binID'}) 撿走了！", 1);
				} elsif (%{$monsters{$items{$ID}{'takenBy'}}}) {
					$monsters{$items{$ID}{'takenBy'}}{'takenBy'} = 1;
					sysLog("ii", "怪物", "重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 被 $monsters{$items{$ID}{'takenBy'}}{'name'} ($monsters{$items{$ID}{'takenBy'}}{'binID'}) 吃掉了！", 1);

					if ($config{'attackAuto_takenBy'}) {
						ai_takenBy($items{$ID}{'takenBy'});
					}
				} elsif ($config{'attackAuto_takenBy'} > 1 && $config{'attackAuto_takenByMonsters'} ne "") {
					undef $ai_v{'temp'}{'foundID'};
					foreach (@monstersID) {
						next if (!isCollector($_));
#						next if ($_ eq "" || !existsInList($config{'attackAuto_takenByMonsters'}, $monsters{$_}{'name'}));
						if (
							(
								$monsters{$_}{'pos'}{'x'} == $items_old{$ID}{'pos'}{'x'}
								&& $monsters{$_}{'pos'}{'y'} == $items_old{$ID}{'pos'}{'y'}
							) || (
								$monsters{$_}{'pos_to'}{'x'} == $items_old{$ID}{'pos'}{'x'}
								&& $monsters{$_}{'pos_to'}{'y'} == $items_old{$ID}{'pos'}{'y'}
							)
						) {
							$ai_v{'temp'}{'foundID'} = $_;
							last;
						}
					}

					ai_takenBy($ai_v{'temp'}{'foundID'}, $ID);
				} else {
					sysLog("ii", "不明", "重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 消失於 ($items{$ID}{'pos'}{'x'}, $items{$ID}{'pos'}{'y'}) - Dist: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$items{$ID}{'pos'}}), 1);
				}
			} elsif ($config{'attackAuto_takenBy'} > 1 && $config{'attackAuto_takenByMonsters'} ne "") {
				undef $ai_v{'temp'}{'foundID'};
				undef $ai_v{'temp'}{'pos'};
				undef $ai_v{'temp'}{'pos_to'};

				undef $ai_v{'temp'}{'dist'};

				if ($config{'attackAuto_takenBy'} > 2) {
					my $j = 0;

					foreach (@monstersID) {
						next if (
							$_ eq ""
							|| !isCollector($_)
#							|| !existsInList($config{'attackAuto_takenByMonsters'}, $monsters{$_}{'name'})
						);

						$ai_v{'temp'}{'pos'} = distance(\%{$items_old{$ID}{'pos'}}, \%{$monsters{$_}{'pos'}}, 1);
						$ai_v{'temp'}{'pos_to'} =distance(\%{$items_old{$ID}{'pos'}}, \%{$monsters{$_}{'pos_to'}}, 1);

						if (
							distance(\%{$items_old{$ID}{'pos'}}, \%{$monsters{$_}{'pos'}}, 1) <= $config{'itemsTakeDist'}
							||
							distance(\%{$items_old{$ID}{'pos'}}, \%{$monsters{$_}{'pos_to'}}, 1) <= $config{'itemsTakeDist'}
						) {
							$monsters{$_}{'attack_failed'} = 0;
							$monsters{$_}{'takenBy'} = 1;
							if (
								$ai_v{'temp'}{'foundID'} eq ""
								|| $ai_v{'temp'}{'pos'} < $ai_v{'temp'}{'dist'}
								|| $ai_v{'temp'}{'pos_to'} < $ai_v{'temp'}{'dist'}
							) {
								$ai_v{'temp'}{'foundID'} = $_;
								$ai_v{'temp'}{'dist'} = (($ai_v{'temp'}{'pos'}<$ai_v{'temp'}{'pos_to'})?$ai_v{'temp'}{'pos'}:$ai_v{'temp'}{'pos_to'});
							}
						}
					}
				} else {
					foreach (@monstersID) {
						next if (
							$_ eq ""
							|| !isCollector($_)
#							|| !existsInList($config{'attackAuto_takenByMonsters'}, $monsters{$_}{'name'})
						);
						if (
							(
								$monsters{$_}{'pos'}{'x'} == $items_old{$ID}{'pos'}{'x'}
								&& $monsters{$_}{'pos'}{'y'} == $items_old{$ID}{'pos'}{'y'}
							) || (
								$monsters{$_}{'pos_to'}{'x'} == $items_old{$ID}{'pos'}{'x'}
								&& $monsters{$_}{'pos_to'}{'y'} == $items_old{$ID}{'pos'}{'y'}
							)
						) {
							$ai_v{'temp'}{'foundID'} = $_;
							last;
						}
					}
				}

				ai_takenBy($ai_v{'temp'}{'foundID'}, $ID);
			} else {
				sysLog("ii", "不明", "重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 消失於 ($items{$ID}{'pos'}{'x'}, $items{$ID}{'pos'}{'y'}) - Dist: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$items{$ID}{'pos'}}), 1);
			}
		}
		%{$items_old{$ID}} = %{$items{$ID}};
		undef %{$items{$ID}};
		binRemove(\@itemsID, $ID);
	}
}

sub event_useSelf_smartAuto {
	my ($switch, $msg, $msg_size) = @_;
	my ($i, $ID, $hide, $newmsg);

	if ($switch eq "01A6") {
		decrypt(\$newmsg, substr($$msg, 4, length($$msg)-4));
		$$msg = substr($$msg, 0, 4).$newmsg;
		undef @callID;
#		undef $invIndex;
		for ($i = 4; $i < $msg_size; $i += 2) {
#			$index = unpack("S1", substr($$msg, $i, 2));
#			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
#			binAdd(\@callID, $invIndex);

			$ID = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", unpack("S1", substr($$msg, $i, 2)));
			binAdd(\@callID, $ID);
		}

		if ($ai_v{'useSelf_smartAutocall'} || $config{'useSelf_smartAutocall'}) {
			undef $ai_v{'useSelf_smartAutocall'};

			for ($i = 0; $i < @callID; $i++) {
				next if ($callID[$i] eq "");

				if (existsInList($config{'useSelf_smartAutocall'}, $chars[$config{'char'}]{'inventory'}[$callID[$i]]{'name'})) {
					sendPetCall(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$callID[$i]]{'index'});

					$hide = 1;

					last;
				}
			}
		}

#		print "請輸入 'call' 查看可孵化寵物蛋清單\n";
	} elsif ($switch eq "018D") {
		decrypt(\$newmsg, substr($$msg, 4, length($$msg)-4));
		$$msg = substr($$msg, 0, 4).$newmsg;
		undef @makeID;

		for ($i = 4; $i < $msg_size; $i += 8) {
			$ID = unpack("S1",substr($$msg, $i, 2));

			binAdd(\@makeID, $ID);
		}

		if ($ai_v{'useSelf_smartAutomake'} || $config{'useSelf_smartAutomake'}) {

			undef $ai_v{'useSelf_smartAutomake'};
			for ($i = 0; $i < @makeID; $i++) {
				next if ($makeID[$i] eq "");

				if (existsInList($config{'useSelf_smartAutomake'}, $items_lut{$makeID[$i]})) {
					sendItemCreate(\$remote_socket, $makeID[$i]);

					$hide = 1;

					last;
				}
			}
		}

#		print "請輸入 'make' 查看可鍛冶物品/配製藥瓶清單\n";
	} elsif ($switch eq "01AD") {
		decrypt(\$newmsg, substr($$msg, 4, length($$msg)-4));
		$$msg = substr($$msg, 0, 4).$newmsg;
		undef @arrowID;

		for ($i = 4; $i < $msg_size; $i += 2) {
			$ID = unpack("S1", substr($$msg, $i, 2));
			binAdd(\@arrowID, $ID);
		}

		# Auto-make smart select

		if ($ai_v{'useSelf_smartAutoarrow'}) {
			undef $ai_v{'useSelf_smartAutoarrow'};
			for ($i = 0; $i < @arrowID; $i++) {
				next if ($arrowID[$i] eq "");

				if (existsInList($config{'useSelf_smartAutoarrow'}, getName("items_lut", $arrowID[$i]))) {
					sendArrowMake(\$remote_socket, $arrowID[$i]);

					$hide = 1;

					last;
				}
			}
		}

#		print "請輸入 'arrow' 查看可製作箭矢物品清單\n";
	} elsif ($switch eq "01CD") {
		undef @autospellID;
		for ($i = 2; $i < 30; $i += 4) {
			$ID = unpack("S1",substr($$msg, $i, 2));
			binAdd(\@autospellID, $ID);
		}
#		print "請輸入 'autospell' 查看可選擇技能清單\n";
		# Auto-spell smart select
		if ($ai_v{'useSelf_skill_smartAutospell'} ne "" && binFind(\@autospellID, $ai_v{'useSelf_skill_smartAutospell'}) ne "") {
			sendAutospell(\$remote_socket, $ai_v{'useSelf_skill_smartAutospell'});
			undef $ai_v{'useSelf_skill_smartAutospell'};

			$hide = 1;
		}
	} elsif ($switch eq "0177") {
		decrypt(\$newmsg, substr($$msg, 4, length($$msg)-4));
		$$msg = substr($$msg, 0, 4).$newmsg;
		undef @identifyID;
#		undef $invIndex;
		for ($i = 4; $i < $msg_size; $i += 2) {
#			$index = unpack("S1", substr($$msg, $i, 2));
#			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
#			binAdd(\@identifyID, $invIndex);

			$ID = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", unpack("S1", substr($$msg, $i, 2)));
			binAdd(\@identifyID, $ID);

		}
#		print "請輸入 'identify' 查看可鑑定物品清單\n";

		if ($ai_v{'useSelf_skill_smartAutoidentify'} || $config{'useSelf_skill_smartAutoidentify'}) {
			undef $ai_v{'useSelf_skill_smartAutoidentify'};

			sendIdentify(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$identifyID[0]]{'index'});

			$hide = 1;
		}
	}

	print getMsgStrings($switch, 0, 0, 2)."\n" if (!$hide);

#	event_useSelf_smartAuto($switch, \$msg, $msg_size);
}

#sub event_map_onChange {
#	my ($map_get) = @_;
#	my $val = 0;
#
#	if ($map_get ne $field{'name'} || !$field{'name'}) {
#		$sc_v{'parseMsg'}{'map_last'} = $sc_v{'parseMsg'}{'map'};
#		getField("$sc_v{'path'}{'fields'}/${map_get}.fld", \%field);
#
#		$val = 1;
#	}
#
#	$sc_v{'parseMsg'}{'map'} = $map_get;
#
#	return $val;
#}

sub event_parseTarget {
	my ($switch, $msg, $msg_size) = @_;
#	my (
#		$ID, $AID, $walk_speed
#		, %coordsFrom, %coordsTo
#		, $type, $pet, $nameID
#		, $param1, $param2, $param3
#		, $hair_s, $weapon, $shield, $hair_c
#		, $desc
#	);
	my $desc;

	if ($switch eq "022C") {
		$ID = substr($$msg, 2, 4);
		$AID = unpack("S*", $ID);

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$walk_speed = unpack("S", substr($$msg, 6, 2)) / 1000;

		makeCoords(\%coordsFrom, substr($$msg, 50+4, 3));
		makeCoords2(\%coordsTo, substr($$msg, 52+4, 3));
		$type = unpack("S*",substr($$msg, 14+2, 2));
		$pet = unpack("C*",substr($$msg, 16+2, 1));
		$level = unpack("S1",substr($$msg, 58+4, 2));
		# 0119 status
		$param1 = unpack("S1", substr($$msg, 8, 2));
		$param2 = unpack("S1", substr($$msg, 10, 2));
		$param3 = unpack("S1", substr($$msg, 12, 2));

#		$hair_s = unpack("S1", substr($$msg, 16, 2));
#		$weapon = unpack("S1", substr($$msg, 18, 2));
#		$shield = unpack("S1", substr($$msg, 20, 2));
#		$hair_c = unpack("S1", substr($$msg, 32, 2));

		$desc = "Moved";
	} elsif ($switch eq "007B") {
		$ID = substr($msg, 2, 4);
		$AID = unpack("S*", $ID);

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		my $walk_speed = unpack("S", substr($$msg, 6, 2)) / 1000;

		makeCoords(\%coordsFrom, substr($$msg, 50, 3));
		makeCoords2(\%coordsTo, substr($$msg, 52, 3));
		$type = unpack("S*",substr($$msg, 14, 2));
		$pet = unpack("C*",substr($$msg, 16, 1));
		$level = unpack("S1",substr($$msg, 58, 2));
		# 0119 status
		$param1 = unpack("S1", substr($$msg, 8, 2));
		$param2 = unpack("S1", substr($$msg, 10, 2));
		$param3 = unpack("S1", substr($$msg, 12, 2));

#		$hair_s = unpack("S1", substr($$msg, 16, 2));
#		$weapon = unpack("S1", substr($$msg, 18, 2));
#		$shield = unpack("S1", substr($$msg, 20, 2));
#		$hair_c = unpack("S1", substr($$msg, 32, 2));

		$desc = "Moved";
	} elsif ($switch eq "0078") {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$ID = substr($msg, 2, 4);
		$walk_speed = unpack("S", substr($$msg, 6, 2)) / 1000;
#		makeCoords(\%coords, substr($msg, 46, 3));
		makeCoords(\%coordsTo, substr($$msg, 46, 3));

		%coordsFrom = %coordsTo;

		$type = unpack("S1",substr($$msg, 14, 2));
		$pet = unpack("C1",substr($$msg, 16, 1));
		# 0119 status
		$param1 = unpack("S1", substr($$msg, 8, 2));
		$param2 = unpack("S1", substr($$msg, 10, 2));
		$param3 = unpack("S1", substr($$msg, 12, 2));
		$level = unpack("S1", substr($$msg, 52, 2));

#		$hair_s = unpack("S1", substr($$msg, 16, 2));
#		$weapon = unpack("S1", substr($$msg, 18, 2));
#		$shield = unpack("S1", substr($$msg, 20, 2));
#		$hair_c = unpack("S1", substr($$msg, 28, 2));

		$desc = "Exists";
	}

	if (0 && $type == 45) {
		if (!%{$portals{$ID}}) {
			$portals{$ID}{'appear_time'} = time;
			$nameID = unpack("L1", $ID);
			$exists = portalExists($field{'name'}, \%coords);
			$display = ($exists ne "")
				? "$portals_lut{$exists}{'source'}{'map'} -> $portals_lut{$exists}{'dest'}{'map'}"
				: "不明傳點 ".$nameID;
			binAdd(\@portalsID, $ID);
			$portals{$ID}{'source'}{'map'} = $field{'name'};
			$portals{$ID}{'type'} = $type;
			$portals{$ID}{'nameID'} = $nameID;
			$portals{$ID}{'name'} = $display;
			$portals{$ID}{'binID'} = binFind(\@portalsID, $ID);
		}
		%{$portals{$ID}{'pos'}} = %coords;
		print "發現傳送點: $portals{$ID}{'name'} - ($portals{$ID}{'binID'}) ".getFormattedCoords($coords{'x'}, $coords{'y'})." - Dist: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$portals{$ID}{'pos'}})."\n";

	} elsif ($jobs_lut{$type} ne "") {
		if (!%{$players{$ID}}) {
			binAdd(\@playersID, $ID);
			$players{$ID}{'appear_time'} = time;
			$players{$ID}{'sex'} = $sex;
			$players{$ID}{'jobID'} = $type;
			$players{$ID}{'name'} = "不明人物";
			$players{$ID}{'binID'} = binFind(\@playersID, $ID);
			print "Player Appeared: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$sex} $jobs_lut{$type}\n" if ($config{'debug'});
		}

		$players{$ID}{'walk_speed'} = $walk_speed;

		$players{$ID}{'time_move'} = time;
		$players{$ID}{'time_move_calc'} = distance(\%coordsFrom, \%coordsTo) * $walk_speed;

		%{$players{$ID}{'pos'}} = %coordsFrom;
		%{$players{$ID}{'pos_to'}} = %coordsTo;
		# 0119 status
		$players{$ID}{'param1'} = $param1;
		$players{$ID}{'param2'} = $param2;
		$players{$ID}{'param3'} = $param3;
		# Player's look
#		$players{$ID}{'hair_s'} = $hair_s;
#		$players{$ID}{'weapon'} = $weapon;
#		$players{$ID}{'shield'} = $shield;
#		$players{$ID}{'hair_c'} = $hair_c;
		# Player's level
		$players{$ID}{'lv'} = $level;
		print "Player ${desc}: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}} - lv $players{$ID}{'lv'}\n" if ($config{'debug'} >= 2);
		# Avoid GM by ID
		avoidGM($ID, "", "${desc}", 1) if ($config{'dcOnGM_paranoia'});
	} elsif ($type >= 1000) {
		if ($pet) {
			if (!%{$pets{$ID}} || $pets{$ID}{'name'} eq "") {
				$pets{$ID}{'appear_time'} = time;
				$display = ($monsters_lut{$type} ne "")
						? $monsters_lut{$type}
						: "不明種類 ".$type;
				binAdd(\@petsID, $ID);
				$pets{$ID}{'nameID'} = $type;
				$pets{$ID}{'name'} = $display;
				$pets{$ID}{'name_given'} = "不明寵物";
				$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
			}

			$pets{$ID}{'walk_speed'} = $walk_speed;

			$pets{$ID}{'time_move'} = time;
			$pets{$ID}{'time_move_calc'} = distance(\%coordsFrom, \%coordsTo) * $walk_speed;

			%{$pets{$ID}{'pos'}} = %coordsFrom;
			%{$pets{$ID}{'pos_to'}} = %coordsTo;
			$pets{$ID}{'lv'} = $level;
			if ($monsters{$ID}) {
#					binRemove(\@monstersID, $ID);
#					delete $monsters{$ID};

				undef $ai_v{'temp'}{'ai_attack_index'};
				undef $ai_v{'ai_attack_ID'};
				$ai_v{'temp'}{'ai_attack_index'} = binFind(\@ai_seq, "attack");

				if ($ai_v{'temp'}{'ai_attack_index'} ne "") {
					$ai_v{'ai_attack_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_attack_index'}]{'ID'};

					if ($ai_v{'ai_attack_ID'} eq $ID) {
						print "放棄目標 $monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) - 目標為寵物 $pets{$ID}{'name'} ($pets{$ID}{'binID'}) - ($pets{$ID}{'pos_to'}{'x'}, $pets{$ID}{'pos_to'}{'y'}) - Dist: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$pets{$ID}{'pos'}})."\n";
						aiRemove("attack");
						aiRemove("skill_use");
					}
				}

				binRemove(\@monstersID, $ID);
				undef %{$monsters{$ID}};
				delete $monsters{$ID};
			}
			print "Pet ${desc}: $pets{$ID}{'name'} ($pets{$ID}{'binID'}) - lv $pets{$ID}{'lv'}\n" if ($config{'debug'});

#			dumpData(substr($$msg, 0, $msg_size), 0, 0, getHex(substr($$msg, 16+2, 1))." ID: ".getID($ID)." Moved: ".getName("auto", $ID, 0, -1)." - $type $pets{$ID}{'name'} - lv $pets{$ID}{'lv'} - ($pets{$ID}{'pos_to'}{'x'}, $pets{$ID}{'pos_to'}{'y'}) - Dist: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$pets{$ID}{'pos'}}));
		} else {
			if (!%{$monsters{$ID}} || $monsters{$ID}{'name'} eq "") {
				binAdd(\@monstersID, $ID);
				$monsters{$ID}{'appear_time'} = time;
				$monsters{$ID}{'nameID'} = $type;
				$display = ($monsters_lut{$type} ne "")
					? $monsters_lut{$type}
					: "不明怪物 ".$type;
				$monsters{$ID}{'nameID'} = $type;
				$monsters{$ID}{'name'} = $display;
				$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
				print "Monster Appeared: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'});

			}

			$monsters{$ID}{'walk_speed'} = $walk_speed;

			$monsters{$ID}{'time_move'} = time;
			$monsters{$ID}{'time_move_calc'} = distance(\%coordsFrom, \%coordsTo) * $walk_speed;

			%{$monsters{$ID}{'pos'}} = %coordsFrom;
			%{$monsters{$ID}{'pos_to'}} = %coordsTo;
##Karasu Start
# 				# Record monster data
#				recordMonsterData($ID) if ($config{'recordMonsterInfo'});
##Karasu End
			# 0119 status
			$monsters{$ID}{'param1'} = $param1;
			$monsters{$ID}{'param2'} = $param2;
			$monsters{$ID}{'param3'} = $param3;
			$monsters{$ID}{'lv'} = $level;
			# Anklesnare Detection

			event_mvp($switch, $ID);

			if (binFind(\@MVPID, $monsters{$ID}{'nameID'}) eq "") {
				for ($i = 0; $i < @spellsID; $i++) {
					next if ($spellsID[$i] eq "" || $spells{$spellsID[$i]}{'type'} != 91);
					if (distance(\%{$spells{$spellsID[$i]}{'pos'}}, \%{$monsters{$ID}{'pos_to'}}) <= 1) {
						$monsters{$ID}{'attack_failed'}++;
						last;
					}
				}
			}
			print "Monster ${desc}: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) - lv $monsters{$ID}{'lv'}\n" if ($config{'debug'} >= 2);
		}
	} elsif ($type < 1000) {
		if (!%{$npcs{$ID}}) {
			$npcs{$ID}{'appear_time'} = time;
			$nameID = unpack("L1", $ID);
#				$display = (%{$npcs_lut{$nameID}})
#					? $npcs_lut{$nameID}{'name'}
#					: "不明NPC ".$nameID;

#				$display = getName("npcs_lut", $nameID);

			binAdd(\@npcsID, $ID);
			$npcs{$ID}{'type'} = $type;
			$npcs{$ID}{'nameID'} = $nameID;
			$npcs{$ID}{'name'} = getName("npcs_lut", $nameID);
			$npcs{$ID}{'binID'} = binFind(\@npcsID, $ID);
		}
		%{$npcs{$ID}{'pos'}} = %coordsTo;
		print "發現NPC: $npcs{$ID}{'name'} - ($npcs{$ID}{'binID'}) - ($coordsTo{'x'}, $coordsTo{'y'}) Dist: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%coordsTo)."\n";

	} else {
		print "[$switch] Unknown ${desc}: $type - ".getHex($ID)."\n" if ($config{'debug'});
		# Avoid GM by ID
		avoidGM($ID, "", "${desc}($switch type:$type)", 1) if ($config{'dcOnGM_paranoia'});
	}

#	if (distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%coordsTo) > 100) {
#		dumpData(substr($$msg, 0, $msg_size), 0, 0, getHex(substr($$msg, 52+2, 3))." 距離超過 100 - ($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}) - ($coordsTo{'x'}, $coordsTo{'y'})");
#	}
}

1;