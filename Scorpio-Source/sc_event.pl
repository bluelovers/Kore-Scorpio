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
		$sc_v{'exp'}{'base'} += $sc_v{'exp'}{'base_add'};
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
		$sc_v{'exp'}{'job'} += $sc_v{'exp'}{'job_add'};
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

	if ($type == 2 && $sc_v{'exp'}{'base_add'}) {
		my $tmp_f = "%.3f";
		my $percentB = "(".sprintf($tmp_f, $sc_v{'exp'}{'base_add'} * 100 / $chars[$config{'char'}]{'exp_max'})."%)" if ($chars[$config{'char'}]{'exp_max'});
		my $percentJ = "(".sprintf($tmp_f, $sc_v{'exp'}{'job_add'} * 100 / $chars[$config{'char'}]{'exp_job_max'})."%)" if ($chars[$config{'char'}]{'exp_job_max'});
		printC("[EXP] BaseExp: $sc_v{'exp'}{'base_add'} $percentB \/ JobExp: $sc_v{'exp'}{'job_add'} $percentJ\n", "exp");

		undef $sc_v{'exp'}{'base_add'};
		undef $sc_v{'exp'}{'job_add'};
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
		# �������ܽЮɼ��񭵮ġA����sounds/Deal.wav(0=���B1=�})
		'Death',
		# ���`�ɼ��񭵮ġA����sounds/Death.wav(0=���B1=�})
		'GM',
		# ������GM�ɼ����ġA����sounds/GM.wav(0=���B1=�})
		'Guest',
		# ���a�i�J��ѫǮɼ��񭵮ġA����sounds/Guest.wav(0=���B1=�})
		'iItemsFound',
		# �o�{���n���~�ɼ��񭵮ġA����sounds/iItemsFound.wav(0=���B1=�})
		'iItemsGot',
		# ��o���n���~�ɼ��񭵮ġA����sounds/iItemsGot.wav(0=���B1=�})
		'C',
		# �������W�D�T���ɼ��񭵮ġA����sounds/C.wav(0=���B1=�})
		'G',
		# ���줽�|�W�D�T���ɼ��񭵮ġA����sounds/G.wav(0=���B1=�})
		'P',
		# ���춤���W�D�T���ɼ��񭵮ġA����sounds/P.wav(0=���B1=�})
		'PM',
		# ����K�y�W�D�T���ɼ��񭵮ġA����sounds/PM.wav(0=���B1=�})
		'S'
		# ���줽�i�W�D�T���ɼ��񭵮ġA����sounds/S.wav(0=���B1=�})
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

				sysLog("g", "����", "Guild Member : $name $sc_v{'event'}{'isOnline'}", 1, !$config{'recordGuildMember'});
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

				sysLog("g", "����", "Guild Member : $name $sc_v{'event'}{'isOnline'}", 1, !$config{'recordGuildMember'});

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
		$tag = "����";
	} elsif ($type eq "g"){
		$tag = "�u�|";
	} elsif ($type eq "s"){
		$tag = "���i";

		$uesr = $msg if ($user eq "");
		$msg = $uesr if ($msg eq "");

		undef $c;

	} elsif ($type eq "pm"){
		$tag = "�K�y";
		if ($options ne "") {
			$tag2 = 'To';

			$user	= $lastpm[0]{'user'};
			$msg	= $lastpm[0]{'msg'};

			$user	= $sc_v{'pm'}{'lastTo'};
			$msg	= $sc_v{'pm'}{'lastMsg'};

			if ($ID == 1) {
				$display = "($user) �ثe���b�u�W\n";
			} elsif ($ID == 2) {
				$display = "($user) �ڵ��A���K�y\n";
			} elsif ($ID == 3) {
				$display = "($user) �ڵ��Ҧ��K�y\n";
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
			$tag = "��ѫ�";
			$type = "cr";
		} else {
			$tag = "���";
			$type = "c";
		}

		if (%{$players{$ID}}) {
			$tag2 = "$uesr ($players{$ID}{'binID'})";
			$options = "(GID:".unpack("L1", $ID)."/".sprintf("%2d", $players{$ID}{'lv'})."��/".substr($jobs_lut{$players{$ID}{'jobID'}}, 0, 4)."/$sex_lut{$players{$ID}{'sex'}}/".sprintf("%2d", int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ID}{'pos_to'}})))."��)";
		}
	}

	$tag2 = $uesr if (!$tag2);
	$tag2 = "$options $tag2" if ($options);

	$display = "${tag2}${c}${msg}" if (!$display);

	event_beep($type);
	printC("[${tag}] $display\n", $type_c);
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

		avoidGM("", $user, "�b$tag�W�D�o��", 0);
	}

#	if ($config{'dcOnGM'} && !$quitBczGM) {
	if ($config{'dcOnGM'}) {
		my ($found, @array, $seperate);

		$seperate = (($config{'dcOnWord_split'}) ? $config{'dcOnWord_split'} : ",");

#		$msg = uc $msg;

		splitUseArray(\@array, $config{(switchInput($type, "s") ? 'dcOnSysWord' : 'dcOnChatWord')}, $seperate);

		if ($config{'dcOnYourName'}) {
			unshift @array, "$chars[$config{'char'}]{'name'}";
			push @array, "$chars[$config{'char'}]{'name'}";

#			$found = 1 if ($msg =~ /\Q$chars[$config{'char'}]{'name'}\E/i);
		}

		foreach (@array) {
			if ($config{'dcOnWord_quote'}) {
				($_) = $_ =~ /^"([\s\S]*?)"$/;
			}

			$found = 1 if ($msg =~ /\Q$_\E/i);

#			print "[$found] $_\n" if (switchInput($type, "s"));

#			print "[$found] $_\n";

			if ($found) {
				printC("���o�{�բ�: $tag�W�D�X�{���w�r���i$_�j�I\n", "s");
				# Beep on event
				event_beep('GM');
				undef %{$ai_v{'dcOnGM_counter'}};
				quitOnEvent("dcOnGM", "�j��", "�o�{�բ�: $tag�W�D�X�{���w�r���i$_�j", "gm");
#				chatLog("�j��", "�ثe��m �i$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."�j", "gm");
				sysLog("gm", "�j��", "�ثe��m �i$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."�j");
				last;
			}
		}
	}
}

sub event_death {
	$record{'counts'}{'dead'}++;
#	print "�����n�T��: �A����P�R���@��, �A���F�I\n";
#	chatLog("���n", "���n�T��: $showHP{'killedBy'}{'who'} �� $showHP{'killedBy'}{'how'}��A�y���P�R���ˮ`($showHP{'killedBy'}{'dmg'})�I�A���F�I", "im");
	sysLog("event", "���n", "���n�T��: $showHP{'killedBy'}{'who'} �� $showHP{'killedBy'}{'how'}��A�y���P�R���ˮ`($showHP{'killedBy'}{'dmg'})�I�A���F�I", 1);
	undef %{$showHP{'killedBy'}};

	event_beep("Death");

	$chars[$config{'char'}]{'dead'} = 1;
	$chars[$config{'char'}]{'dead_time'} = time;
#Solos Start(���`�������S��)
	event_shop_close(2);
}

sub event_checkInfo {
	if (!$chars[$config{'char'}]{'dead'} && !$chars[$config{'char'}]{'hp'}) {
#		chatLog("���~", "�Y�����~: �i���HP��T, ���s�s�u�I", "e");
		sysLog("e", "���~", "�Y�����~: �i���HP��T, ���s�s�u�I");
		$sc_v{'input'}{'MinWaitRecon'} = 1;
		relogWait("���Y�����~: �i���HP��T�I", 1);
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
	print "\n�i�g�e�c�b�A�w�i�J�C���b�c�e�g�i\n";

	if ($config{'warpperMode'} && !$sc_v{'warpperMode'}{'done'}) {
		$sc_v{'warpperMode'}{'done'} = 1;

		print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n";
		sendMapLoaded(\$remote_socket);
		print "Successfully transferred\n";

#		killConnection(\$remote_socket);
#		sleep(5);
#		relog();

		undef $ai_v{'teleOnGM'};
		sc_relog("{Event] warpperMode ���s���o�a�ϸ�T\n");

		timeOutStart('ai');
	} else {
		print "�A�X�{�b: $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'})."\n";
		sendMapLoaded(\$remote_socket);

		# Set console title

		# Set ignore all
		sendIgnoreAll(\$remote_socket, !$config{'ignoreAll'});
		# Avoid GM
		if ($ai_v{'teleOnGM'} == 2) {
			undef %{$ai_v{'dcOnGM_counter'}};
			quitOnEvent("dcOnGM", "�j��", "�o�{�բ�: �������Ƥw��", "gm");
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

	sysLog("sh", "��X", "��X $articles[$index]{'name'} x $amount - ��o ".toZeny($shop{'earnedLast'})." Zeny", 1);

	undef $shop{'earnedLast'};

	$articles[$index]{'amount'} -= $amount;
	$articles[$index]{'sold'} += $amount;
	if ($articles[$index]{'amount'} < 1) {
		$articles--;
		undef %{$articles[$index]};
	}

	if ($articles == 0) {

		sysLog("sh", "����", "�ӫ~�w������X, �`���J: ".toZeny($shop{'earned'})." Zeny", 1);

		event_shop_close(1);

	}

}

sub event_shop_close {
	my $mode = shift;
	my $ex_mode - shift;

	if ($mode > 1){

		return 0 if (!$shop{'opened'} || !$myShop{'shop_closeOnDeath'});

	}

	sysLog("sh", "����", "�w��X�ӫ~�`���J: ".toZeny($shop{'earned'})." Zeny", 1) if ($shop{'earned'} && !$mode);
	sysLog("sh", "����", "�����\\�u: �ثe�֦� ".toZeny($chars[$config{'char'}]{'zenny'})." Zeny, �`���J: ".toZeny($shop{'earned'})." Zeny", 1);

	sendShopClose(\$remote_socket) if ($shop{'opened'});
	undef %shop;

#	ai_event_auto_parseInput("shop open") if ($mode && $myShop{'shop_autoReStart'} && !$ex_mode);
#
#	if ($myShop{'dcOnShopClosed'}) {
#
#		print "���Ұ� dcOnShopClosed - �ߧY�n�X�I\n";
#		sysLog("im", "���n", "���n�T��: �����\\�u, �ߧY�n�X�I");
#
#		$quit = 1;
#	}

}

sub event_mvp_get {
	my ($switch, $ID) = @_;
	return 0 if (!$config{'recordMonsterInfo_mvp'} || !$switch || !$ID);

	my $msg;
	my $display;

	if ($switch eq "010A") {
		$display = "�A";
		$msg	= "�����ۢ�ޡI�I���oMVP���~: $items_lut{$ID}";
	} elsif ($switch eq "010B") {
		$display = "�A";
		$msg	= "�����ۢ�ޡI�I��o�S��g���: $ID";
	} elsif ($switch eq "010C") {
		if ($ID eq $accountID) {
			$display = "�A";
		} elsif (%{$players{$ID}}) {
			$display = "$players{$ID}{'name'} ($players{$ID}{'binID'})";
		} else {
			$display = "�����H��[".unpack("L1", $ID)."]";

#			sendGetPlayerInfo(\$remote_socket, $ID);
		}
		$msg	= " �����ۢ�ޡI�I";
	}

	if ($msg ne "") {
		sysLog("mvp", "MVP", "${display}${msg}", 1);

		if ($display eq "�A") {
			$display = "";
		} else {
			$display = "(GID:".unpack("L1", $ID)."/".sprintf("%2d", $players{$ID}{'lv'})."��/".substr($jobs_lut{$players{$ID}{'jobID'}}, 0, 4)."/$sex_lut{$ID}{'sex'}}) $display ";
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
			$msg	= "�b $t_map �o�{ $name";
		} elsif ($switch eq "007C") {
			$title	= "Spawned";
			$msg	= "$name �X�{�b $t_map";
		} elsif ($switch eq "0080") {
			$title	= "Died";
			$msg	= "$name - �}�`�b $t_map";
		} elsif ($switch eq "007B") {
			$title	= "Move";
	#		$msg	= "$name - �}�`�b $t_map";

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

		if (!$mode) {
			$msg = "[${t_type}] $sc_v{'parseMsg'}{'server_name'} - $msg - �Z��: $t_dist ��";

			if ($config{'broadcastMode'}) {
				sendMessage(\$remote_socket, "p", $msg) if ($config{'broadcastMode'} != 2 && %{$chars[$config{'char'}]{'party'}});

				if (
					$config{'broadcastMode'} > 1
					&& $chars[$config{'char'}]{'guild'}{'ID'}
				) {
					sendMessage(\$remote_socket, "g", $msg);
				}
			}

			sysLog("mvp", $title, $msg, 1, !$config{'recordMonsterInfo_mvp'});
		}

		if (
			$config{'attackAuto_mvpFirst'}
			&& (
				$config{'attackAuto_mvpFirst'} > 1
				|| $t_type eq "MVP"
			)
			&& $monsters{$ID}{'mvp'} != 1
			&& switchInput($switch, "0078", "007C", "007B")
		) {
			$monsters{$ID}{'mvp'} = 1;

			if (!$chars[$config{'char'}]{'mvp'}) {
				attack($ID);
			}
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

	$targetDisplay = ($messages_lut{'011F'}{$type} ne "")
		? $messages_lut{'011F'}{$type}
		: "�������A ".$type;

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
		printS("��$sourceDisplay�� $targetDisplay �X�{�b�y��: ".getFormattedCoords($coords{'x'}, $coords{'y'}).", �Z��: $s_cDist\n", "", $sourceID, "floor");
		$ai_v{'hideMsg_groundEffect'}{'sourceID'} = $sourceID;
		$ai_v{'hideMsg_groundEffect'}{'type'} = $type;
		$ai_v{'hideMsg_groundEffect_time'} = time;
	}
#Karasu Start
	# Avoid ground effect skills
	my $i = 0;

	return if ($sc_v{'temp'}{'itemsImportantAutoMode'});

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
					"���o�{�ޯ�: $sourceDisplay�I�� $targetDisplay �Z���A�u�� $s_cDist��I\n"
					."���Ұ� teleportAuto_spell - �H�����ʡI\n"
					, "tele"
				);
				sysLog("tele", "�j��", "�o�{�ޯ�: $sourceDisplay�I�� $targetDisplay �Z���A�u�� $s_cDist��, �H�����ʡI");

				last;
			} else {

				$ai_v{'temp'}{'teleOnEvent'} = 1;
				timeOutStart('ai_teleport_event');
				$sc_v{'temp'}{'teleOnEvent'} = useTeleport(1);
				$ai_v{'clear_aiQueue'} = 1;

				printC(
					"���o�{�ޯ�: $sourceDisplay�I�� $targetDisplay �Z���A�u�� $s_cDist��I\n"
					."���Ұ� teleportAuto_spell - �������ʡI\n"
					, "tele"
				);
				sysLog("tele", "�j��", "�o�{�ޯ�: $sourceDisplay�I�� $targetDisplay �Z���A�u�� $s_cDist��, �������ʡI");

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

		print "($dealUser)�߰�(���͡��p�j)�@���@�N����H\n";
		print "�п�J 'deal' �������, �ο�J 'deal no' �ڵ����\n";

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
			print "$currentDeal{'name'} �T�{�������\n";
		} else {
			$currentDeal{'you_finalize'} = 1;
			print "�A�T�{�������\n";
		}
		parseInput("dl");
	} elsif (switchInput($switch, "00EE")) {
		undef %incomingDeal;
		undef %outgoingDeal;
		undef %currentDeal;
		printC("�������\n", "alert");
	} elsif (switchInput($switch, "00F0")) {
		print "������~���\\\n";
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
#			chatLog("���~", "�Y�����~: �i��򥢦a�ϦW��, ���s�s�u�I", "e");
			sysLog("e", "���~", "�Y�����~: �i��򥢦a�ϦW��, ���s�s�u�I");
			relogWait("���Y�����~: �i��򥢦a�ϦW�١I", 1);
		}

		$ai_v{'temp'}{'map'} = getMapID($map_name);

		$coords{'x'} = unpack("S1", substr($msg, 18, 2));
		$coords{'y'} = unpack("S1", substr($msg, 20, 2));
		%{$chars[$config{'char'}]{'pos'}} = %coords;
		%{$chars[$config{'char'}]{'pos_to'}} = %coords;

		$sc_v{'parseMsg'}{'map'} = $ai_v{'temp'}{'map'};

		if ($ai_v{'temp'}{'map'} ne $field{'name'} || $field{'name'} eq "") {
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

			timeOutStart(-1, 'ai_partyAutoCreate');
		}

		aiRemove("attack");

		print "�a���ഫ�� - $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): ".getFormattedCoords($chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'})."\n";
		print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if ($config{'debug'});

		if (!$option{'X-Kore'}) {
			print "Sending Map Loaded\n" if ($config{'debug'});
			sendMapLoaded(\$remote_socket);

			# Avoid GM

			if ($ai_v{'teleOnGM'} == 2) {
				undef %{$ai_v{'dcOnGM_counter'}};
				quitOnEvent("dcOnGM", "�j��", "�o�{�բ�: �������Ƥw��", "gm");
			}

			undef $ai_v{'teleOnGM'};
			undef $sc_v{'temp'}{'teleOnEvent'};
			# Respawn at undefine map
			respawnUndefine($ai_v{'temp'}{'map'});
		} else {
#			timeOutStart(1, 'ai');
		}
	} elsif ($switch eq "0092") {
		initMapChangeVars() if ($option{'X-Kore'});
#		initConnectVars();

		$sc_v{'input'}{'conState'} = 4;
		undef $sc_v{'input'}{'conState_tries'};
		for ($i = 0; $i < @ai_seq; $i++) {
			ai_setMapChanged($i);
		}
		($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
		# Prevent lost map name
		if ($map_name eq "") {
#			chatLog("���~", "�Y�����~: �i��򥢦a�ϦW��, ���s�s�u�I", "e");
			sysLog("e", "���~", "�Y�����~: �i��򥢦a�ϦW��, ���s�s�u�I");
			relogWait("���Y�����~: �i��򥢦a�ϦW�١I", 1);
		}

		$ai_v{'temp'}{'map'} = getMapID($map_name);
		$sc_v{'parseMsg'}{'map'} = $ai_v{'temp'}{'map'};

		$map_ip = makeIP(substr($msg, 22, 4));
		$map_port = unpack("S1", substr($msg, 26, 2));

		if ($ai_v{'temp'}{'map'} ne $field{'name'} || $field{'name'} eq "") {
			getField("$sc_v{'path'}{'fields'}/$ai_v{'temp'}{'map'}.fld", \%field);
			sysLog("map", "$switch", "Map: $field{'name'} IP: $map_ip Port: $map_port");
		}

		print swrite(
			 "\n �z�w�w�w�w Game  Info �w�w�w�w�{",[]
			," ��MAP  Name : @<<<<<<<<<<<<<<<��",[$map_name]
			," ��MAP  IP   : @<<<<<<<<<<<<<<<��",[$map_ip]
			," ��MAP  Port : @<<<<<<<<<<<<<<<��",[$map_port]
			," �|�w�w�w�w�w�w�w�w�w�w�w�w�w�w�}\n",[]
		);
		print "�����P�a�Ϧ��A�����s�u\n" if ($config{'debug'} || 1);

		if (!$option{'X-Kore'}) {
			killConnection(\$remote_socket);
		} else {
			timeOutStart(1, 'ai');
		}

		undef $sc_v{'temp'}{'teleOnEvent'};
	} elsif ($switch eq "0071") {
#		initConnectVars();
		print "�ѵn�J���A�����oChar ID��Map IP\n" if ($config{'debug'});
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
#			chatLog("���~", "�Y�����~: �i��򥢦a�ϦW��, ���s�s�u�I", "e");
			sysLog("e", "���~", "�Y�����~: �i��򥢦a�ϦW��, ���s�s�u�I", 1);
			relogWait("���Y�����~: �i��򥢦a�ϦW�١I", 1);
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
			 "\n �z�w�w�w�w Game  Info �w�w�w�w�{",[]
			," ��Char ID   : @<<<<<<<<<<<<<<<��",[getHex($sc_v{'input'}{'charID'})]
			," ��MAP  Name : @<<<<<<<<<<<<<<<��",[$map_name]
			," ��MAP  IP   : @<<<<<<<<<<<<<<<��",[$map_ip]
			," ��MAP  Port : @<<<<<<<<<<<<<<<��",[$map_port]
			," �|�w�w�w�w�w�w�w�w�w�w�w�w�w�w�}\n",[]
		);

		if (!$option{'X-Kore'}) {

			print "�����P�n�J���A�����s�u\n" if ($config{'debug'});
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

			print "\n�i�g�e�c�b�A�w�i�J�C���b�c�e�g�i\n";

			if ($config{'warpperMode'} && !$sc_v{'warpperMode'}{'done'}) {
				$sc_v{'warpperMode'}{'done'} = 1;

				print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n";
				sendMapLoaded(\$remote_socket);
				print "Successfully transferred\n";

		#		killConnection(\$remote_socket);
		#		sleep(5);
		#		relog();

				undef $ai_v{'teleOnGM'};
				sc_relog("{Event] warpperMode ���s���o�a�ϸ�T\n");

				timeOutStart('ai');
			} else {
				print "�A�X�{�b: $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'})."\n";
				sendMapLoaded(\$remote_socket);

				# Set console title

				if ($config{'serverType'} != 0) {
					sendSync(\$remote_socket, 1);
					print "Sent initial sync\n" if ($config{'debug'});
				}

				# Set ignore all
				sendIgnoreAll(\$remote_socket, !$config{'ignoreAll'});
				# Avoid GM
				if ($ai_v{'teleOnGM'} == 2) {
					undef %{$ai_v{'dcOnGM_counter'}};
					quitOnEvent("dcOnGM", "�j��", "�o�{�բ�: �������Ƥw��", "gm");
				}
				undef $ai_v{'teleOnGM'};
				# Respawn at undefine map
				respawnUndefine($field{'name'}) if (!$sc_v{'parseMsg'}{'dcOnDualLogin'});
				timeOutStart('ai');

				timeOutStart(-1, 'ai_partyAutoCreate');

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
		print "$npcs{$talk{'ID'}}{'name'}: �п�J 'sell <���~�s��> [<�ƶq>]' ��X���~\n";
	} elsif (switchInput($switch, "00C4")) {
		undef %talk;
		$talk{'buyOrSell'} = 1;
		$talk{'ID'} = $msg;
		print "$npcs{$talk{'ID'}}{'name'}: �A�O�n�R�F��(buy), �٬O�n��(sell)�F��O�H\n";
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
				: "�������~ ".$ID;
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
		%{$items_old{$ID}} = %{$items{$ID}};
		$items_old{$ID}{'disappeared'} = 1;
		$items_old{$ID}{'gone_time'} = time;
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
					sysLog("ii", "�ۤv", "$items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} ��o�I");
				} elsif (%{$players{$items{$ID}{'takenBy'}}}) {
					my $options;
					$options = "(GID:".unpack("L1", $items{$ID}{'takenBy'})."/".sprintf("%2d", $players{$items{$ID}{'takenBy'}}{'lv'})."��/".substr($jobs_lut{$players{$items{$ID}{'takenBy'}}{'jobID'}}, 0, 4)."/$sex_lut{$players{$items{$ID}{'takenBy'}}{'sex'}}/".sprintf("%2d", int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$items{$ID}{'takenBy'}}{'pos_to'}})))."��) " if (!$config{'hideMsg_takenByInfo'});
					sysLog("ii", "���a", "���n���~: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} �Q ${options}$players{$items{$ID}{'takenBy'}}{'name'} ($players{$items{$ID}{'takenBy'}}{'binID'}) �ߨ��F�I", 1);
				} elsif (%{$monsters{$items{$ID}{'takenBy'}}}) {
					$monsters{$items{$ID}{'takenBy'}}{'takenBy'} = 1;
					sysLog("ii", "�Ǫ�", "���n���~: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} �Q $monsters{$items{$ID}{'takenBy'}}{'name'} ($monsters{$items{$ID}{'takenBy'}}{'binID'}) �Y���F�I", 1);

					if ($config{'attackAuto_takenBy'}) {
						ai_takenBy($items{$ID}{'takenBy'});
					}
				} elsif ($config{'attackAuto_takenBy'} > 1) {
					undef $ai_v{'temp'}{'foundID'};
					foreach (@monstersID) {
						next if ($_ eq "" || !existsInList($config{'attackAuto_takenByMonsters'}, $monsters{$_}{'name'}));
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
					sysLog("ii", "����", "���n���~: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} ������ ($items{$ID}{'pos'}{'x'}, $items{$ID}{'pos'}{'y'})", 1);
				}
			} elsif ($config{'attackAuto_takenBy'} > 1) {
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
				sysLog("ii", "����", "���n���~: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} ������ ($items{$ID}{'pos'}{'x'}, $items{$ID}{'pos'}{'y'})", 1);
			}
		}
		undef %{$items{$ID}};
		binRemove(\@itemsID, $ID);
	}
}

1;