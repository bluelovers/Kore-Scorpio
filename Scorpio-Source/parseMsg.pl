#######################################
#######################################
#Parse Message
#######################################
#######################################

sub parseMsg {
	my $msg = shift;
	my $msg_size;

	my $switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
	if (length($msg) >= 4 && substr($msg,0,4) ne $accountID && $sc_v{'input'}{'conState'} >= 4 && $lastswitch ne $switch
		&& length($msg) >= unpack("S1", substr($msg, 0, 2))) {
		decrypt(\$msg, $msg);
	}
	$switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));
#Karasu Start
	# debug_packet mode
#	print "Packet Switch: $switch\n" if ($config{'debug'} >= 2);
	print "Packet Switch: $switch\n" if ($config{'debug'} >= 2 || $config{'debug_packet'} >= 3);
#Karasu End

	if ($lastswitch eq $switch && length($msg) > $lastMsgLength) {
		$sc_v{'input'}{'errorCount'}++;
	} else {
		$sc_v{'input'}{'errorCount'} = 0;
	}
	if ($sc_v{'input'}{'errorCount'} > 3) {
		print "$last_know_switch > $switch ($msg_size): 接收到無法辨識的封包, 資料可能遺失\n";
#Karasu Start
	# debug_packet mode
#		dumpData($msg) if ($config{'debug'});
		dumpData($lastPacket) if ($config{'debug_packet'} >= 2 && $lastPacket ne "");
		dumpData($msg) if ($config{'debug'} || $config{'debug_packet'});
#Karasu End
		$sc_v{'input'}{'errorCount'} = 0;
		$msg_size = length($msg);
	}

	if (substr($msg,0,4) ne $accountID || ($sc_v{'input'}{'conState'} != 2 && $sc_v{'input'}{'conState'} != 4)) {
		if ($rpackets{$switch} eq "-" || $rpackets{$switch} < 0) {
			# Complete packet; the size of this packet is equal to the size of the entire data
			$msg_size = length($msg);
		} elsif ($rpackets{$switch} eq "\#") {
			if (length($msg) < 4) {
				return $msg;
			}
			$msg_size = unpack("S1", substr($msg, 2, 2));
			if (length($msg) < $msg_size) {
				return $msg;
			}
		} elsif ($rpackets{$switch} eq "0") {
			# Variable length packet
			if (length($msg) < 4) {
				return $msg;
			}
			$msg_size = unpack("S1", substr($msg, 2, 2));
			if (length($msg) < $msg_size) {
				return $msg;
			}
		} elsif ($rpackets{$switch} > 1) {
			if (length($msg) < $rpackets{$switch}) {
				return $msg;
			}
			$msg_size = $rpackets{$switch};
		} else {
			print "Packet Switch: $lastswitch + $switch\n";
			dumpData($last_know_msg.$msg, "$lastswitch + $switch") if ($config{'debug'} || $config{'debug_packet'});
		}
		$last_know_msg = substr($msg, 0, $msg_size);
		$last_know_switch = $switch;
		dumpData($msg,$msg_size) if ($msg_size && $config{'debug_recv'});
	}

	if ($config{'debug'} >= 2 || $config{'debug_packet'} >= 3) {
		print <<"EOM";
Packet.Switch: $switch
Packet.Length: $msg_size
EOM
;
	}

	$lastswitch = $switch;
	$lastMsgLength = length($msg);

	if (substr($msg,0,4) eq $accountID && ($sc_v{'input'}{'conState'} == 2 || $sc_v{'input'}{'conState'} == 4)) {
		if ($config{'encrypt'} && $sc_v{'input'}{'conState'} == 4) {
			$encryptKey1 = unpack("L1", substr($msg, 6, 4));
			$encryptKey2 = unpack("L1", substr($msg, 10, 4));
			{
				use integer;
				$imult = (($encryptKey1 * $encryptKey2) + $encryptKey1) & 0xFF;
				$imult2 = ((($encryptKey1 * $encryptKey2) << 4) + $encryptKey2 + ($encryptKey1 * 2)) & 0xFF;
			}
			$encryptVal = $imult + ($imult2 << 8);
			$msg_size = 14;
		} else {
			$msg_size = 4;
		}
	} elsif ($switch eq "0069" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
		$sc_v{'input'}{'conState'} = 2;
		undef $sc_v{'input'}{'conState_tries'};
		if ($versionSearch) {
			$versionSearch = 0;
			writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);
		}
		$sessionID = substr($msg, 4, 4);
		$accountID = substr($msg, 8, 4);
		$sc_v{'input'}{'accountSex'} = unpack("C1",substr($msg, 46, 1));
		$sc_v{'input'}{'accountSex2'} = ($config{'sex'} ne "") ? $config{'sex'} : $sc_v{'input'}{'accountSex'};

		if (binFind(\@{$sc_v{'valBan'}}, getID($accountID)) ne "") {
#			print "拒絕使用\n";
			kore_close();
		}

#		my $tmp_txt;
#
#		$tmp_txt .= "---------Account Info----------\n";
#		$tmp_txt .= sprintf("Account ID: %-20s\n",getHex($accountID));
#		$tmp_txt .= sprintf("Sex:        %-20s\n",$sex_lut[$sc_v{'input'}{'accountSex'}]);
#		$tmp_txt .= sprintf("Session ID: %-20s\n",getHex($sessionID));
#		$tmp_txt .= sprintf("            %-20s\n",getHex($sessionID2));
#		$tmp_txt .= "-------------------------------\n";
#
#		print $tmp_txt;

		print swrite(
			 "\n ┌──── Account Info ───┐",[]
			," ∣Account ID: @<<<<<<<<<<<<<<<∣",[getHex($accountID)]
			," ∣Sex       : @<<<<<<<<<<<<<<<∣",[$sex_lut[$sc_v{'input'}{'accountSex'}]]
			," ∣Session ID: @<<<<<<<<<<<<<<<∣",[getHex($sessionID)]
			," ∣            @<<<<<<<<<<<<<<<∣",[getHex($sessionID2)]
			," └──────────────┘\n",[]
		);

		$num = 0;
		undef @servers;
		for($i = 47; $i < $msg_size; $i+=32) {
			$servers[$num]{'ip'} = makeIP(substr($msg, $i, 4));
			$servers[$num]{'port'} = unpack("S1", substr($msg, $i+4, 2));
			($servers[$num]{'name'}) = substr($msg, $i + 6, 20) =~ /([\s\S]*?)\000/;
			$servers[$num]{'users'} = unpack("L",substr($msg, $i + 26, 4));
			$num++;
		}
		$~ = "SERVERS";
		print "----------------- 登入伺服器 -----------------\n";
		print "#   名稱           人數  IP              Port \n";

		for ($num = 0; $num < @servers; $num++) {
			format SERVERS =
@<< @<<<<<<<<<<<< @>>>>  @<<<<<<<<<<<<<< @<<<<
$num, $servers[$num]{'name'}, $servers[$num]{'users'}, $servers[$num]{'ip'}, $servers[$num]{'port'}
.
			write;
		}
		print "----------------------------------------------\n";

		if (!$option{'X-Kore'}) {
			print "關閉與主伺服器的連線\n" if ($config{'debug'});

			killConnection(\$remote_socket);
			if (!$config{'charServer_host'} && $config{'server'} eq "") {
				print "選擇登入伺服器, 請輸入編號:\n";
				$sc_v{'input'}{'waitingForInput'} = 1;
			} elsif ($config{'charServer_host'}) {
				print "強制連線char server $config{'charServer_host'}:$config{'charServer_port'}\n";
			} else {
				print "選擇 $config{'server'} 號登入伺服器($servers[$config{'server'}]{'name'})\n";
				if ($config{'server_name'} && lc($servers[$config{'server'}]{'name'}) ne lc($config{'server_name'})) {
	#				print "◆嚴重錯誤: $config{'server'} 號登入伺服器($servers[$config{'server'}]{'name'})不符設定, ";
					$chatLog_string = "嚴重錯誤: $config{'server'} 號登入伺服器($servers[$config{'server'}]{'name'})不符設定, ";
					undef $found;
					for ($num = 0; $num < @servers; $num++) {
						if (lc($servers[$num]{'name'}) eq lc($config{'server_name'})) {
							$found = 1;
							$config{'server'} = $num;
							writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);
							last;
						}
					}
					if (!$found) {
	#					print "搜尋其他登入伺服器失敗！\n\n";
						$chatLog_string .= "搜尋其他登入伺服器失敗！";
					} else {
	#					print "改選擇 $config{'server'} 號登入伺服器($servers[$config{'server'}]{'name'})！\n\n";
						$chatLog_string .= "改選擇 $config{'server'} 號登入伺服器($servers[$config{'server'}]{'name'})！";
					}
	#				chatLog("錯誤", $chatLog_string, "e");
					sysLog("e", "錯誤", $chatLog_string, 1);
				}
				$sc_v{'parseMsg'}{'server_name'} = $servers[$config{'server'}]{'name'};
			}

		}

	} elsif ($switch eq "006A" && length($msg) >= 23) {
		$type = unpack("C1",substr($msg, 2, 1));

		my $tmpmsg;

		if ($type == 0) {
#			chatLog("錯誤", "嚴重錯誤: 遊戲帳號不存在, 重新連線！", "e");
			sysLog("e", "錯誤", "嚴重錯誤: 遊戲帳號不存在, 重新連線！");

			print "Enter Username Again: \n";

			if (!$option{'X-Kore'}) {
				$tmpmsg = input_readLine();

				$config{'username'} = $tmpmsg;
				writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);

				if ($tmpmsg) {
					relogWait("◆重新登入遊戲帳號", 1);
				} else {
					relogWait("◆嚴重錯誤: 遊戲帳號不存在！", 1);
				}
			}
		} elsif ($type == 1) {
#			chatLog("錯誤", "嚴重錯誤: 遊戲密碼錯誤, 重新連線！", "e");
			sysLog("e", "錯誤", "嚴重錯誤: 遊戲密碼錯誤, 重新連線！");

			print "Enter Password Again: \n";

			if (!$option{'X-Kore'}) {
				undef $tmpmsg;

				if (!$config{'password_noChoice'}) {

					$tmpmsg = input_readLine();

					$config{'password'} = $tmpmsg;
					writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);

				}

				if ($tmpmsg) {
					relogWait("◆重新登入遊戲密碼", 1);
				} else {
					relogWait("◆嚴重錯誤: 遊戲密碼錯誤！", 1);
				}
			}
		} elsif ($type == 3) {
			relogWait("伺服器拒絕登入！", 1);
		} elsif ($type == 4) {
#			chatLog("錯誤", "嚴重錯誤: 你的帳號被凍結了！", "e");
#			print "◆嚴重錯誤: 你的帳號被凍結了！\n";

			sysLog("e", "錯誤", "◆嚴重錯誤: 你的帳號被凍結了！", 1);

#			$quit = 1;
			quit(1, 1);
		} elsif ($type == 5) {
#			print "版本編號錯誤($config{'version'})！, 嘗試尋找正確的版本編號...\n";
			sysLog("e", "錯誤", "版本編號錯誤($config{'version'})！, 嘗試尋找正確的版本編號...", 1);

			$config{'version'}++;
			if (!$versionSearch) {
				$config{'version'} = 0;
				$versionSearch = 1;
			}
		} elsif ($type == 6) {
			relogWait("請稍後連線！", 1);
		}
		if ($type != 5 && $versionSearch) {
			$versionSearch = 0;
			writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);
		}
		$msg_size = 23;

	} elsif ($switch eq "006B" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		print "由登入伺服器取得角色資料\n" if ($config{'debug'});
		$sc_v{'input'}{'conState'} = 3;
		undef $sc_v{'input'}{'conState_tries'};
		$msg_size = unpack("S1", substr($msg, 2, 2));
		if ($config{"master_version_$config{'master'}"} == 0) {
			$startVal = 24;
		} else {
			$startVal = 4;
		}
		for($i = $startVal; $i < $msg_size; $i+=106) {
#exp display bugfix - chobit andy 20030129
			$num = unpack("C1", substr($msg, $i + 104, 1));
			$chars[$num]{'exp'} = unpack("L1", substr($msg, $i + 4, 4));
			$chars[$num]{'zenny'} = unpack("L1", substr($msg, $i + 8, 4));
			$chars[$num]{'exp_job'} = unpack("L1", substr($msg, $i + 12, 4));
			$chars[$num]{'lv_job'} = unpack("C1", substr($msg, $i + 16, 1));
			$chars[$num]{'hp'} = unpack("S1", substr($msg, $i + 42, 2));
			$chars[$num]{'hp_max'} = unpack("S1", substr($msg, $i + 44, 2));
			$chars[$num]{'hp_string'} = sprintf("%5d", $chars[$num]{'hp'})."/".sprintf("%-5d", $chars[$num]{'hp_max'}) if ($chars[$num]{'hp_max'} ne "");
			$chars[$num]{'sp'} = unpack("S1", substr($msg, $i + 46, 2));
			$chars[$num]{'sp_max'} = unpack("S1", substr($msg, $i + 48, 2));
			$chars[$num]{'sp_string'} = sprintf("%5d", $chars[$num]{'sp'})."/".sprintf("%-5d", $chars[$num]{'sp_max'}) if ($chars[$num]{'sp_max'} ne "");
			$chars[$num]{'jobID'} = unpack("C1", substr($msg, $i + 52, 1));
			$chars[$num]{'lv'} = unpack("C1", substr($msg, $i + 58, 1));
			($chars[$num]{'name'}) = substr($msg, $i + 74, 24) =~ /([\s\S]*?)\000/;
			$chars[$num]{'str'} = unpack("C1", substr($msg, $i + 98, 1));
			$chars[$num]{'agi'} = unpack("C1", substr($msg, $i + 99, 1));
			$chars[$num]{'vit'} = unpack("C1", substr($msg, $i + 100, 1));
			$chars[$num]{'int'} = unpack("C1", substr($msg, $i + 101, 1));
			$chars[$num]{'dex'} = unpack("C1", substr($msg, $i + 102, 1));
			$chars[$num]{'luk'} = unpack("C1", substr($msg, $i + 103, 1));
			$chars[$num]{'sex'} = $sc_v{'input'}{'accountSex2'};
		}
		$~ = "CHAR";
		format CHAR =

 ┌────角 色 0─────────角 色 1─────────角 色 2────┐
 │Name: @<<<<<<<<<<<<<<<<│Name: @<<<<<<<<<<<<<<<<│Name: @<<<<<<<<<<<<<<<<│
 $chars[0]{'name'},             $chars[1]{'name'},      $chars[2]{'name'}
 │Job : @<<<<<<<  Str: @>│Job : @<<<<<<<  Str: @>│Job : @<<<<<<<  Str: @>│
 getName("jobs_lut", $chars[0]{'jobID'}), $chars[0]{'str'}, getName("jobs_lut", $chars[1]{'jobID'}), $chars[1]{'str'}, getName("jobs_lut", $chars[2]{'jobID'}), $chars[2]{'str'}
 │Lv  : @<<       Agi: @>│Lv  : @<<       Agi: @>│Lv  : @<<       Agi: @>│
 $chars[0]{'lv'}, $chars[0]{'agi'}, $chars[1]{'lv'}, $chars[1]{'agi'}, $chars[2]{'lv'}, $chars[2]{'agi'}
 │J.Lv: @<<       Vit: @>│J.Lv: @<<       Vit: @>│J.Lv: @<<       Vit: @>│
 $chars[0]{'lv_job'}, $chars[0]{'vit'}, $chars[1]{'lv_job'}, $chars[1]{'vit'}, $chars[2]{'lv_job'}, $chars[2]{'vit'}
 │HP: @>>>>>>>>>> Int: @>│HP: @>>>>>>>>>> Int: @>│HP: @>>>>>>>>>> Int: @>│
 $chars[0]{'hp_string'}, $chars[0]{'int'}, $chars[1]{'hp_string'}, $chars[1]{'int'}, $chars[2]{'hp_string'}, $chars[2]{'int'}
 │SP: @>>>>>>>>>> Dex: @>│SP: @>>>>>>>>>> Dex: @>│SP: @>>>>>>>>>> Dex: @>│
 $chars[0]{'sp_string'}, $chars[0]{'dex'}, $chars[1]{'sp_string'}, $chars[1]{'dex'}, $chars[2]{'sp_string'}, $chars[2]{'dex'}
 │Zeny: @<<<<<<<<<Luk: @>│Zeny: @<<<<<<<<<Luk: @>│Zeny: @<<<<<<<<<Luk: @>│
 $chars[0]{'zenny'}, $chars[0]{'luk'}, $chars[1]{'zenny'}, $chars[1]{'luk'}, $chars[2]{'zenny'}, $chars[2]{'luk'}
 └────────────────────────────────────-┘

.
			write;

		if (!$option{'X-Kore'}) {
			if ($config{'char'} eq "") {
				print "選擇角色, 請輸入編號:\n";
				$sc_v{'input'}{'waitingForInput'} = 1;
			} else {
				print "選擇 $config{'char'} 號角色\n";
				sendCharLogin(\$remote_socket, $config{'char'});
				timeOutStart('gamelogin');
			}
		}
		#$msg_size = length($msg);

	} elsif ($switch eq "006C" && length($msg) >= 3) {
		print "無法連線登入伺服器(角色指定錯誤)...\n";
		$sc_v{'input'}{'conState'} = 1;
		undef $sc_v{'input'}{'conState_tries'};
		$msg_size = 3;
		#$msg_size = length($msg);

	} elsif ($switch eq "006E" && length($msg) >= 3) {
		$msg_size = 3;

	} elsif ($switch eq "0071" && length($msg) >= 28) {
#		print "由登入伺服器取得Char ID及Map IP\n" if ($config{'debug'});
#		$sc_v{'input'}{'conState'} = 4;
#		undef $sc_v{'input'}{'conState_tries'};
##Karasu Start
#		# Reconnect when map chang bug fix
#		undef @ai_seq;
#		undef @ai_seq_args;
##Karasu End
#		$sc_v{'input'}{'charID'} = substr($msg, 2, 4);
#		($map_name) = substr($msg, 6, 16) =~ /([\s\S]*?)\000/;
#		# Prevent lost map name
#		if ($map_name eq "") {
##			chatLog("錯誤", "嚴重錯誤: 可能遺失地圖名稱, 重新連線！", "e");
#			sysLog("e", "錯誤", "嚴重錯誤: 可能遺失地圖名稱, 重新連線！", 1);
#			relogWait("◆嚴重錯誤: 可能遺失地圖名稱！", 1);
#		}
#
#		$ai_v{'temp'}{'map'} = getMapID($map_name);
#
#		$sc_v{'parseMsg'}{'map'} = $ai_v{'temp'}{'map'};
#
#		$map_ip = makeIP(substr($msg, 22, 4));
#		$map_port = unpack("S1", substr($msg, 26, 2));
#
#		if (!$field{'name'} || $ai_v{'temp'}{'map'} ne $field{'name'}) {
#			getField("$sc_v{'path'}{'fields'}/$ai_v{'temp'}{'map'}.fld", \%field);
#			sysLog("map", "$switch", "Map: $field{'name'} IP: $map_ip Port: $map_port");
#		}
#
#		print swrite(
#			 "\n ┌──── Game  Info ────┐",[]
#			," ∣Char ID   : @<<<<<<<<<<<<<<<∣",[getHex($sc_v{'input'}{'charID'})]
#			," ∣MAP  Name : @<<<<<<<<<<<<<<<∣",[$map_name]
#			," ∣MAP  IP   : @<<<<<<<<<<<<<<<∣",[$map_ip]
#			," ∣MAP  Port : @<<<<<<<<<<<<<<<∣",[$map_port]
#			," └──────────────┘\n",[]
#		);
#
#		if (!$option{'X-Kore'}) {
#
#			print "關閉與登入伺服器的連線\n" if ($config{'debug'});
#			killConnection(\$remote_socket);
#
#			event_0071($map_name, $map_ip, $map_port);
#
#		}

		event_map($switch, $msg);

		$msg_size = 28;

	} elsif ($switch eq "0073" && length($msg) >= 11) {

#		event_0073($msg);
		event_map($switch, $msg);

		$msg_size = 11;

	} elsif ($switch eq "0075" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

	} elsif ($switch eq "0077" && length($msg) >= 5) {
		$msg_size = 5;

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

	} elsif ($switch eq "0078" && length($msg) >= 54) {

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$ID = substr($msg, 2, 4);
		my $walk_speed = unpack("S", substr($msg, 6, 2)) / 1000;
		makeCoords(\%coords, substr($msg, 46, 3));
		$type = unpack("S1",substr($msg, 14, 2));
		$pet = unpack("C1",substr($msg, 16, 1));
		# 0119 status
		$param1 = unpack("S1", substr($msg, 8, 2));
		$param2 = unpack("S1", substr($msg, 10, 2));
		$param3 = unpack("S1", substr($msg, 12, 2));
		$level = unpack("S1", substr($msg, 52, 2));
		if ($type >= 1000) {
			if ($pet) {
				if (!%{$pets{$ID}}) {
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

				%{$pets{$ID}{'pos'}} = %coords;
				%{$pets{$ID}{'pos_to'}} = %coords;
				$pets{$ID}{'lv'} = $level;
				print "Pet Exists: $pets{$ID}{'name'} ($pets{$ID}{'binID'}) - lv $pets{$ID}{'lv'}\n" if ($config{'debug'});

				if ($monsters{$ID}) {
					binRemove(\@monstersID, $ID);
					delete $monsters{$ID};

					undef $ai_v{'temp'}{'ai_attack_index'};
					undef $ai_v{'ai_attack_ID'};
					$ai_v{'temp'}{'ai_attack_index'} = binFind(\@ai_seq, "attack");

					if ($ai_v{'temp'}{'ai_attack_index'} ne "") {
						$ai_v{'ai_attack_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_attack_index'}]{'ID'};

						if ($ai_v{'ai_attack_ID'} eq $ID) {
							aiRemove("attack");
							aiRemove("skill_use");
						}
					}
				}
			} else {
				if (!%{$monsters{$ID}}) {
					$monsters{$ID}{'appear_time'} = time;
					$display = ($monsters_lut{$type} ne "")
							? $monsters_lut{$type}
							: "不明怪物 ".$type;
					binAdd(\@monstersID, $ID);
					$monsters{$ID}{'nameID'} = $type;
					$monsters{$ID}{'name'} = $display;
					$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
				}
				%{$monsters{$ID}{'pos'}} = %coords;
				%{$monsters{$ID}{'pos_to'}} = %coords;
#Karasu Start - recordMonsterInfo
#					# Record monster data
#					recordMonsterData($ID) if ($config{'recordMonsterInfo'});
#Karasu End - recordMonsterInfo
				# 0119 status
				$monsters{$ID}{'param1'} = $param1;
				$monsters{$ID}{'param2'} = $param2;
				$monsters{$ID}{'param3'} = $param3;
				$monsters{$ID}{'lv'} = $level;
				print "Monster Exists: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) - lv $monsters{$ID}{'lv'}\n" if ($config{'debug'});

				event_mvp("0078", $ID);
			}
		} elsif ($jobs_lut{$type} ne "") {
			if (!%{$players{$ID}}) {
				$players{$ID}{'appear_time'} = time;
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "不明人物";
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
				$players{$ID}{'skills_failed'} = 0;
			}

			$players{$ID}{'walk_speed'} = $walk_speed;

			$players{$ID}{'sitting'} = $sitting > 0;
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			# 0119 status
			$players{$ID}{'param1'} = $param1;
			$players{$ID}{'param2'} = $param2;
			$players{$ID}{'param3'} = $param3;
			# Player's look
			$players{$ID}{'hair_s'} = unpack("S1", substr($msg, 16, 2));
			$players{$ID}{'weapon'} = unpack("S1", substr($msg, 18, 2));
			$players{$ID}{'shield'} = unpack("S1", substr($msg, 20, 2));
			$players{$ID}{'hair_c'} = unpack("S1", substr($msg, 28, 2));

			# Player's level
			$players{$ID}{'lv'} = $level;
			print "Player Exists: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}} - lv $players{$ID}{'lv'}\n" if ($config{'debug'});
			# Avoid GM by ID
			avoidGM($ID, "", "存在", 1) if ($config{'dcOnGM_paranoia'});

		} elsif ($type == 45) {
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
			%{$npcs{$ID}{'pos'}} = %coords;
			print "發現NPC: $npcs{$ID}{'name'} - ($npcs{$ID}{'binID'})\n";

		} else {
			print "Unknown Exists: $type - ".unpack("L*", $ID)."\n" if ($config{'debug'});
			# Avoid GM by ID
			avoidGM($ID, "", "存在(0078 type:$type)", 1) if ($config{'dcOnGM_paranoia'});
		}
		$msg_size = 54;

	# Seperate player from 0078
	} elsif ($switch eq "01D8" && length($msg) >= 54) {

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$ID = substr($msg, 2, 4);
		makeCoords(\%coords, substr($msg, 46, 3));
		$type = unpack("S1",substr($msg, 14, 2));
		$sex = unpack("C1",substr($msg, 45, 1));
		$sitting = unpack("C1",substr($msg, 51, 1));
		$level = unpack("S1", substr($msg, 52, 2));
		# 0119 status
		$param1 = unpack("S1", substr($msg, 8, 2));
		$param2 = unpack("S1", substr($msg, 10, 2));
		$param3 = unpack("S1", substr($msg, 12, 2));

		if (!%{$players{$ID}}) {
			$players{$ID}{'appear_time'} = time;
			binAdd(\@playersID, $ID);
			$players{$ID}{'jobID'} = $type;
			$players{$ID}{'sex'} = $sex;
			$players{$ID}{'name'} = "不明人物";
			$players{$ID}{'binID'} = binFind(\@playersID, $ID);
		}
		$players{$ID}{'sitting'} = $sitting > 0;
		%{$players{$ID}{'pos'}} = %coords;
		%{$players{$ID}{'pos_to'}} = %coords;
		# 0119 status
		$players{$ID}{'param1'} = $param1;
		$players{$ID}{'param2'} = $param2;
		$players{$ID}{'param3'} = $param3;
		# Player's look
		$players{$ID}{'hair_s'} = unpack("S1", substr($msg, 16, 2));
		$players{$ID}{'weapon'} = unpack("S1", substr($msg, 18, 2));
		$players{$ID}{'shield'} = unpack("S1", substr($msg, 20, 2));
		$players{$ID}{'hair_c'} = unpack("S1", substr($msg, 28, 2));

		# Player's level
		$players{$ID}{'lv'} = $level;
		print "Player Exists: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}} - lv $players{$ID}{'lv'}\n" if ($config{'debug'});
		if ($jobs_lut{$type} eq "") {
			print "Unknown Exists: $type - ".unpack("L*", $ID)."\n" if ($config{'debug'});
		}
		# Avoid GM by ID
		avoidGM($ID, "", "存在", 1) if ($config{'dcOnGM_paranoia'});
		$msg_size = 54;

	} elsif (($switch eq "0079" || $switch eq "01D9") && length($msg) >= 53) {
		$ID = substr($msg, 2, 4);

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		my $walk_speed = unpack("S", substr($msg, 6, 2)) / 1000;

		makeCoords(\%coords, substr($msg, 46, 3));
		$type = unpack("S1",substr($msg, 14, 2));
		$sex = unpack("C1",substr($msg, 45, 1));
		$level = unpack("S1", substr($msg, 51, 2));
		# 0119 status
		$param1 = unpack("S1", substr($msg, 8, 2));
		$param2 = unpack("S1", substr($msg, 10, 2));
		$param3 = unpack("S1", substr($msg, 12, 2));

		if (!%{$players{$ID}}) {
			$players{$ID}{'appear_time'} = time;
			binAdd(\@playersID, $ID);
			$players{$ID}{'jobID'} = $type;
			$players{$ID}{'sex'} = $sex;
			$players{$ID}{'name'} = "不明人物";
			$players{$ID}{'binID'} = binFind(\@playersID, $ID);
		}

		$players{$ID}{'walk_speed'} = $walk_speed;

		%{$players{$ID}{'pos'}} = %coords;
		%{$players{$ID}{'pos_to'}} = %coords;
		# 0119 status
		$players{$ID}{'param1'} = $param1;
		$players{$ID}{'param2'} = $param2;
		$players{$ID}{'param3'} = $param3;
		$players{$ID}{'lv'} = $level;
		# Player's look
		$players{$ID}{'hair_s'} = unpack("S1", substr($msg, 16, 2));
		$players{$ID}{'weapon'} = unpack("S1", substr($msg, 18, 2));
		$players{$ID}{'shield'} = unpack("S1", substr($msg, 20, 2));
		$players{$ID}{'hair_c'} = unpack("S1", substr($msg, 28, 2));
		print "Player Connected: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}} - lv $players{$ID}{'lv'}\n" if ($config{'debug'});
		if ($jobs_lut{$type} eq "") {
			print "Unknown Connected: $type - ".getHex($ID)."\n" if ($config{'debug'});
		}
		# Avoid GM by ID
		avoidGM($ID, "", "出現", 1) if ($config{'dcOnGM_paranoia'});
		$msg_size = 53;

	} elsif ($switch eq "007A" && length($msg) >= 58) {
		$msg_size = 58;

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

	} elsif ($switch eq "007B" && length($msg) >= 60) {
		$ID = substr($msg, 2, 4);
		$AID = unpack("S*", $ID);

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		my $walk_speed = unpack("S", substr($msg, 6, 2)) / 1000;

		makeCoords(\%coordsFrom, substr($msg, 50, 3));
		makeCoords2(\%coordsTo, substr($msg, 52, 3));
		$type = unpack("S*",substr($msg, 14, 2));
		$pet = unpack("C*",substr($msg, 16, 1));
		$level = unpack("S1",substr($msg, 58, 2));
		# 0119 status
		$param1 = unpack("S1", substr($msg, 8, 2));
		$param2 = unpack("S1", substr($msg, 10, 2));
		$param3 = unpack("S1", substr($msg, 12, 2));
		if ($type >= 1000) {
			if ($pet) {
				if (!%{$pets{$ID}}) {
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

				%{$pets{$ID}{'pos'}} = %coords;
				%{$pets{$ID}{'pos_to'}} = %coords;
				$pets{$ID}{'lv'} = $level;
				if ($monsters{$ID}) {
					binRemove(\@monstersID, $ID);
					delete $monsters{$ID};

					undef $ai_v{'temp'}{'ai_attack_index'};
					undef $ai_v{'ai_attack_ID'};
					$ai_v{'temp'}{'ai_attack_index'} = binFind(\@ai_seq, "attack");

					if ($ai_v{'temp'}{'ai_attack_index'} ne "") {
						$ai_v{'ai_attack_ID'} = $ai_seq_args[$ai_v{'temp'}{'ai_attack_index'}]{'ID'};

						if ($ai_v{'ai_attack_ID'} eq $ID) {
							aiRemove("attack");
							aiRemove("skill_use");
						}
					}
				}
				print "Pet Moved: $pets{$ID}{'name'} ($pets{$ID}{'binID'}) - lv $pets{$ID}{'lv'}\n" if ($config{'debug'});
			} else {
				if (!%{$monsters{$ID}}) {
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
				print "Monster Moved: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) - lv $monsters{$ID}{'lv'}\n" if ($config{'debug'} >= 2);
			}
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
			$players{$ID}{'hair_s'} = unpack("S1", substr($msg, 16, 2));
			$players{$ID}{'weapon'} = unpack("S1", substr($msg, 18, 2));
			$players{$ID}{'shield'} = unpack("S1", substr($msg, 20, 2));
			$players{$ID}{'hair_c'} = unpack("S1", substr($msg, 32, 2));
			# Player's level
			$players{$ID}{'lv'} = $level;
			print "Player Moved: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}} - lv $players{$ID}{'lv'}\n" if ($config{'debug'} >= 2);
			# Avoid GM by ID
			avoidGM($ID, "", "移動", 1) if ($config{'dcOnGM_paranoia'});
		} else {
			print "Unknown Moved: $type - ".getHex($ID)."\n" if ($config{'debug'});
			# Avoid GM by ID
			avoidGM($ID, "", "移動(007B type:$type)", 1) if ($config{'dcOnGM_paranoia'});
		}
		$msg_size = 60;

	# Seperate player from 007B
	} elsif ($switch eq "01DA" && length($msg) >= 60) {
		$ID = substr($msg, 2, 4);
		$AID = unpack("S*", $ID);
		makeCoords(\%coordsFrom, substr($msg, 50, 3));
		makeCoords2(\%coordsTo, substr($msg, 52, 3));
		$type = unpack("S1",substr($msg, 14, 2));
		$sex = unpack("C1",substr($msg, 49, 1));
		$level = unpack("S1",substr($msg, 58, 2));
		# 0119 status
		$param1 = unpack("S1", substr($msg, 8, 2));
		$param2 = unpack("S1", substr($msg, 10, 2));
		$param3 = unpack("S1", substr($msg, 12, 2));
		if (!%{$players{$ID}}) {
			binAdd(\@playersID, $ID);
			$players{$ID}{'appear_time'} = time;
			$players{$ID}{'sex'} = $sex;
			$players{$ID}{'jobID'} = $type;
			$players{$ID}{'name'} = "不明人物";
			$players{$ID}{'binID'} = binFind(\@playersID, $ID);

			print "Player Appeared: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$sex} $jobs_lut{$type}\n" if ($config{'debug'});
		}
		%{$players{$ID}{'pos'}} = %coordsFrom;
		%{$players{$ID}{'pos_to'}} = %coordsTo;
		# 0119 status
		$players{$ID}{'param1'} = $param1;
		$players{$ID}{'param2'} = $param2;
		$players{$ID}{'param3'} = $param3;
		# Player's look
		$players{$ID}{'hair_s'} = unpack("S1", substr($msg, 16, 2));
		$players{$ID}{'weapon'} = unpack("S1", substr($msg, 18, 2));
		$players{$ID}{'shield'} = unpack("S1", substr($msg, 20, 2));
		$players{$ID}{'hair_c'} = unpack("S1", substr($msg, 32, 2));
		# Player's level
		$players{$ID}{'lv'} = $level;
		print "Player Moved: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}} - lv $players{$ID}{'lv'}\n" if ($config{'debug'} >= 2);
		if ($jobs_lut{$type} eq "") {
			print "Unknown Moved: $type - ".getHex($ID)."\n" if ($config{'debug'});
		}
		# Avoid GM by ID
		avoidGM($ID, "", "移動", 1) if ($config{'dcOnGM_paranoia'});
		$msg_size = 60;

	} elsif ($switch eq "007C" && length($msg) >= 41) {

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$ID = substr($msg, 2, 4);
		makeCoords(\%coords, substr($msg, 36, 3));
		$type = unpack("S1",substr($msg, 20, 2));
		$sex = unpack("C1",substr($msg, 35, 1));

#		$pet = unpack("C*",substr($msg, 22, 1));

		if ($type >= 1000) {
			if (!%{$monsters{$ID}}) {
				binAdd(\@monstersID, $ID);
				$monsters{$ID}{'nameID'} = $type;
				$monsters{$ID}{'appear_time'} = time;
				$display = ($monsters_lut{$monsters{$ID}{'nameID'}} ne "")
						? $monsters_lut{$monsters{$ID}{'nameID'}}
						: "不明怪物 ".$monsters{$ID}{'nameID'};
				$monsters{$ID}{'name'} = $display;
				$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);
			}
			%{$monsters{$ID}{'pos'}} = %coords;
			%{$monsters{$ID}{'pos_to'}} = %coords;
##Karasu Start - recordMonsterInfo
#				# Record monster data
#				recordMonsterData($ID) if ($config{'recordMonsterInfo'});
##Karasu End - recordMonsterInfo
			print "Monster Spawned: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'});

			event_mvp("007C", $ID);
		} elsif ($jobs_lut{$type}) {
			if (!%{$players{$ID}}) {
				binAdd(\@playersID, $ID);
				$players{$ID}{'jobID'} = $type;
				$players{$ID}{'sex'} = $sex;
				$players{$ID}{'name'} = "不明人物";
				$players{$ID}{'appear_time'} = time;
				$players{$ID}{'binID'} = binFind(\@playersID, $ID);
			}
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
			print "Player Spawned: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});
			# Avoid GM by ID
			avoidGM($ID, "", "出現", 1) if ($config{'dcOnGM_paranoia'});
		} else {
			print "Unknown Spawned: $type - ".getHex($ID)."\n" if ($config{'debug'});
			# Avoid GM by ID
			avoidGM($ID, "", "出現(007C type:$type)", 1) if ($config{'dcOnGM_paranoia'});
		}
		$msg_size = 41;

	} elsif ($switch eq "007F" && length($msg) >= 6) {

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$time = unpack("L1",substr($msg, 2, 4));
		print "Recieved Sync\n" if ($config{'debug'} >= 2);
		timeOutStart('play');
		$msg_size = 6;


	} elsif ($switch eq "0080" && length($msg) >= 7) {

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$ID = substr($msg, 2, 4);
		$type = unpack("C1",substr($msg, 6, 1));

		if ($ID eq $accountID) {

			event_death();

		} elsif (%{$monsters{$ID}}) {
			$monsters{$ID}{'gone_time'} = time;
			$monsters{$ID}{'0080'} = $type;
			%{$monsters_old{$ID}} = %{$monsters{$ID}};
#			$monsters_old{$ID}{'gone_time'} = time;
#			$monsters_old{$ID}{'0080'} = $type;

			if ($type == 0 || $type == 3) {
				print "Monster Disappeared: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'});
				$monsters_old{$ID}{'disappeared'} = 1;
			} elsif ($type == 1) {
				print "Monster Died: $monsters{$ID}{'name'} ($monsters{$ID}{'binID'})\n" if ($config{'debug'});
				$monsters_old{$ID}{'dead'} = 1;
				# Skill use wait after kill
				my $ai_index_attack = binFind(\@ai_seq, "attack");
				if ($ai_index_attack ne "" && $ID eq $ai_seq_args[$ai_index_attack]{'ID'}) {
					timeOutStart('ai_skill_use_waitAfterKill');
				}

				event_mvp("0080", $ID);
			}
			# shift skill_use when monster died or disappeared
			my $ai_index_skill_use = binFind(\@ai_seq, "skill_use");
			if ($ai_index_skill_use ne "" && $ID eq $ai_seq_args[$ai_index_skill_use]{'skill_use_target'}) {
				undef $chars[$config{'char'}]{'time_cast'};
				undef $ai_v{'temp'}{'castWait'};
			}
			binRemove(\@monstersID, $ID);
			undef %{$monsters{$ID}};
		} elsif (%{$players{$ID}}) {
			$players{$ID}{'0080'} = $type;

			if ($type == 0 || $type == 3) {
				print "Player Disappeared: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n" if ($config{'debug'});
				%{$players_old{$ID}} = %{$players{$ID}};
				$players_old{$ID}{'disappeared'} = 1;
				$players_old{$ID}{'gone_time'} = time;
				binRemove(\@playersID, $ID);
				undef %{$players{$ID}};
			} elsif ($type == 1) {
#				print "發現陣亡玩家: $players{$ID}{'name'} ($players{$ID}{'binID'}) $sex_lut{$players{$ID}{'sex'}} $jobs_lut{$players{$ID}{'jobID'}}\n";
				print "發現陣亡玩家: (GID:".unpack("L1", $ID)."/".sprintf("%2d", $players{$ID}{'lv'})."等/".getName("jobs_lut", $players{$ID}{'jobID'})."/$sex_lut{$players{$ID}{'sex'}}/".sprintf("%2d", int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ID}{'pos_to'}})))."格) $players{$ID}{'name'} ($players{$ID}{'binID'})\n";
				$players{$ID}{'dead'} = 1;
			} elsif ($type == 2) {
				print "Player Disconnected: $players{$ID}{'name'}\n" if ($config{'debug'});
				%{$players_old{$ID}} = %{$players{$ID}};
				$players_old{$ID}{'disconnected'} = 1;
				$players_old{$ID}{'gone_time'} = time;
				binRemove(\@playersID, $ID);
				undef %{$players{$ID}};
#ICE-WR Start
				#for ($i = 0; $i < @partyUsersID; $i++) {
				#	next if ($partyUsersID[$i] eq "");
				#	if ($partyUsersID[$i] eq $ID) {
				#		undef $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'};
				#		undef $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'y'};
				#		last;
				#	}
				#}
#ICE-WR End
			}
		} elsif (%{$players_old{$ID}}) {
			$players_old{$ID}{'0080'} = $type;

			if ($type == 2) {
				print "Player Disconnected: $players_old{$ID}{'name'}\n" if ($config{'debug'});
				$players_old{$ID}{'disconnected'} = 1;
			}
		} elsif (%{$portals{$ID}}) {
			print "Portal Disappeared: $portals{$ID}{'name'} ($portals{$ID}{'binID'})\n" if ($config{'debug'});
			%{$portals_old{$ID}} = %{$portals{$ID}};
			$portals_old{$ID}{'disappeared'} = 1;
			$portals_old{$ID}{'gone_time'} = time;
			binRemove(\@portalsID, $ID);
			undef %{$portals{$ID}};
		} elsif (%{$npcs{$ID}}) {
			print "NPC Disappeared: $npcs{$ID}{'name'} ($npcs{$ID}{'binID'})\n" if ($config{'debug'});
			%{$npcs_old{$ID}} = %{$npcs{$ID}};
			$npcs_old{$ID}{'disappeared'} = 1;
			$npcs_old{$ID}{'gone_time'} = time;
			binRemove(\@npcsID, $ID);
			undef %{$npcs{$ID}};
		} elsif (%{$pets{$ID}}) {
			print "Pet Disappeared: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
			binRemove(\@petsID, $ID);
			undef %{$pets{$ID}};
			# My pet gone
			if ($ID eq $chars[$config{'char'}]{'pet'}{'ID'}) {
				undef %{$chars[$config{'char'}]{'pet'}};
				$record{'counts'}{'petDead'}++;
			}
		} else {
			print "Unknown Disappeared: ".getHex($ID)."\n" if ($config{'debug'});
			# Avoid GM by ID
			avoidGM($ID, "", "可能想要測試你", 1) if ($config{'dcOnGM_paranoia'});
		}
		$msg_size = 7;

	} elsif ($switch eq "0081" && length($msg) >= 3) {
		$type = unpack("C1", substr($msg, 2, 1));
		$sc_v{'input'}{'MinWaitRecon'} = 1;
		if ($type == 2) {
			print "◆嚴重錯誤: 遭相同序號登入！\n";
			$sc_v{'parseMsg'}{'dcOnDualLogin'}++;
			$sc_v{'parseMsg'}{'dcOnDualLogin'} = 1 if ($sc_v{'parseMsg'}{'dcOnDualLogin'} <= 0);
			$sc_v{'temp'}{'dcOnDualLogin'} = 1;

			if ($config{'dcOnDualLogin'} == 0) {
				relogWait("◆啟動 dcOnDualLogin - 重新連線！", 1);
#				chatLog("錯誤", "嚴重錯誤: 遭相同序號登入, 重新連線！", "e");
				sysLog("e", "錯誤", "嚴重錯誤: 遭相同序號登入, 重新連線！");

				if ($config{'dcOnDualLogin_protect'}) {
					relogWait("◆啟動 dcOnDualLogin_protect - 啟動保護模式！", 1);
					sysLog("im", "防盜", "啟動: 遭相同序號登入 $sc_v{'parseMsg'}{'dcOnDualLogin'}次, 啟動保護模式！");
				}

#				$sc_v{'kore'};
			} else {
				quitOnEvent("dcOnDualLogin", "錯誤", "嚴重錯誤: 遭相同序號登入", "e");

#				if ($config{'dcOnDualLogin'} ne "1" && $config{'dcOnDualLogin_protect'}) {
#					relogWait("◆啟動 dcOnDualLogin_protect - 啟動保護模式！", 1);
#					sysLog("im", "防盜", "啟動: 遭相同序號登入 $sc_v{'parseMsg'}{'dcOnDualLogin'}次, 啟動保護模式！");
#				}
			}

		} elsif ($type == 3) {
			print "◆與伺服器同步處理失敗！\n";
			# Avoid GM
			if ($ai_v{'teleOnGM'}) {
				undef $ai_v{'teleOnGM'};
				undef %{$ai_v{'dcOnGM_counter'}};
				quitOnEvent("dcOnGM", "迴避", "與伺服器同步處理失敗", "gm");
			} else {
				relogWait("", 1);
			}

		} elsif ($type == 6) {
#			chatLog("錯誤", "嚴重錯誤: 此帳號儲值點數已用完, 重新連線！", "e");
			sysLog("e", "錯誤", "嚴重錯誤: 此帳號儲值點數已用完, 重新連線！");
			relogWait("◆嚴重錯誤: 此帳號儲值點數已用完！", 30);
		} elsif ($type == 8) {
			relogWait("伺服器仍在確認上一次的連線！", 1);
		}
		$msg_size = 3;

	} elsif ($switch eq "0087" && length($msg) >= 12) {

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		makeCoords(\%coordsFrom, substr($msg, 6, 3));
		makeCoords2(\%coordsTo, substr($msg, 8, 3));
		%{$chars[$config{'char'}]{'pos'}} = %coordsFrom;
		%{$chars[$config{'char'}]{'pos_to'}} = %coordsTo;
		print "You move to: $coordsTo{'x'}, $coordsTo{'y'}\n" if ($config{'debug'});
		$chars[$config{'char'}]{'time_move'} = time;
		$chars[$config{'char'}]{'time_move_calc'} = distance(\%{$chars[$config{'char'}]{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}) * ($chars[$config{'char'}]{'walk_speed'} || $config{'seconds_per_block'});
		$msg_size = 12;

	} elsif ($switch eq "0088" && length($msg) >= 10) {
		undef $level_real;
		$ID = substr($msg, 2, 4);
		$coords{'x'} = unpack("S1", substr($msg, 6, 2));
		$coords{'y'} = unpack("S1", substr($msg, 8, 2));
		if ($ID eq $accountID) {
			%{$chars[$config{'char'}]{'pos'}} = %coords;
			%{$chars[$config{'char'}]{'pos_to'}} = %coords;
			print "Movement interrupted, your coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if ($config{'debug'});
			aiRemove("move");
		} elsif (%{$monsters{$ID}}) {
			%{$monsters{$ID}{'pos'}} = %coords;
			%{$monsters{$ID}{'pos_to'}} = %coords;
			# Anklesnare Detection
			if (binFind(\@MVPID, $monsters{$ID}{'nameID'}) eq "") {
				for ($i = 0; $i < @spellsID; $i++) {
					next if ($spellsID[$i] eq "" || $spells{$spellsID[$i]}{'type'} != 91);
					if (distance(\%{$spells{$spellsID[$i]}{'pos'}}, \%{$monsters{$ID}{'pos_to'}}) <= 1) {
						$monsters{$ID}{'attack_failed'}++;
						last;
					}
				}
			}
		} elsif (%{$players{$ID}}) {
			%{$players{$ID}{'pos'}} = %coords;
			%{$players{$ID}{'pos_to'}} = %coords;
		}
		$msg_size = 10;

	} elsif ($switch eq "0089" && length($msg) >= 7) {
		$msg_size = 7;

	} elsif ($switch eq "008A" && length($msg) >= 29) {

		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$ID1 = substr($msg, 2, 4);
		$ID2 = substr($msg, 6, 4);
#在戰鬥中代表是否lucky或是critical,非戰鬥中代表站立或坐下
		$damage = unpack("S1", substr($msg, 22, 2));
		$hit = unpack("S1", substr($msg, 24, 2));
		$action = unpack("C1", substr($msg, 26, 1));
		$damage_left = unpack("S1", substr($msg, 27, 2));
#		my $ai_index = binFind(\@ai_seq, "attack");

		$totaldamage = $damage;
		if ($ID1 eq $accountID || %{$players{$ID1}}) {
			$totaldamage = ($damage_left) ? $damage + $damage_left : $damage;
		}
		updateDamageTables($ID1, $ID2, $totaldamage);

#		if ($damage == 0) {
#			$dmgDisplay = ($action == 0x0b) ? "Lucky!" : "Miss!!";
#		} elsif ($ID1 eq $accountID || %{$players{$ID1}}) {
#			$dmgDisplay = ($damage_left) ? $damage."/".$damage_left : $damage;
#		} else {
#			$dmgDisplay = $damage;
#		}
#		if ($ID1 eq $accountID && %{$monsters{$ID2}}
#			&& (!$config{'hideMsg_attackDmgFromYou'} || $config{'debug'})) {
#			$dmgDisplay .= " (Total: $monsters{$ID2}{'dmgFromYou'})";
#		}
#		$dmgDisplay .= "☆" if ($action == 0x0a);

		$dmgDisplay = parseAttack($ID1, $ID2, $damage, $hit, $action, $damage_left);

		my ($sourceDisplay, $castBy) = ai_getCaseID($ID1);
		my ($targetDisplay, $castOn, $dist) = ai_getCaseID($ID2, $ID1);

		my $ai_index = binFind(\@ai_seq, "attack");
		undef $ai_v{'temp'}{'ai_attack_ID'};

		if ($ai_index ne "") {
			$ai_v{'temp'}{'ai_attack_ID'} = $ai_seq_args[$ai_index]{'ID'};
		}

		if ($ID1 eq $accountID) {
			if (%{$monsters{$ID2}}) {
				if ($damage || !$config{'hideMsg_attackMiss'} || $config{'debug'}) {
					printf "○你攻擊怪物:${targetDisplay}- 造成傷害: $dmgDisplay\n";
				}

				if ($config{'dcOnAtkMiss'} && $monsters{$ID2}{'missedFromYou'} >= $config{'dcOnAtkMiss'}) {
				#disconnect when atk miss
					print "You attack miss! $config{'dcOnAtkMiss'} times or more, then disconnect...\n";
#					sysLog("D","You attack miss! $config{'dcOnAtkMiss'} times or more, then disconnect...\n");
					quit();
				} elsif ($config{'teleportAuto_AtkMiss'} && $monsters{$ID2}{'missedFromYou'} >= $config{'teleportAuto_AtkMiss'}) {
					print "You attack miss! $config{'teleportAuto_AtkMiss'} times or more, then teleport..\n";
#					sysLog("D","You attack miss! $config{'teleportAuto_AtkMiss'} times or more, then teleport...\n");
					useTeleport(1,1);

				} elsif (!$ai_v{'temp'}{'teleOnEvent'}){
#Pino Start(控制發送attack)
					timeOutStart('ai_attack');
#Pino End
				}
			} elsif (%{$items{$ID2}}) {
				print "You pick up Item: $items{$ID2}{'name'} ($items{$ID2}{'binID'})\n" if ($config{'debug'});
				$items{$ID2}{'takenBy'} = $accountID;
			} elsif ($ID2 == 0) {
				if ($action == 0x03) {
					$chars[$config{'char'}]{'sitting'} = 0;
					print "你站了起來\n";
				} elsif ($action == 0x02) {
					$chars[$config{'char'}]{'sitting'} = 1;
					print "你找個舒適的地方, 坐下來休息\n";
				}
			} elsif (%{$players{$ID2}}) {
				print "○你攻擊玩家:${targetDisplay}- 造成傷害: $dmgDisplay\n" if ($config{'debug'});
			}
		} elsif ($ID2 eq $accountID) {
			if (%{$monsters{$ID1}}) {
				if ($damage || !$config{'hideMsg_attackMiss'} || $config{'debug'}) {
					# Show HP
					undef $showHP{'hp_now'};
					undef $showHP{'hppercent_now'};
					$showHP{'hp_now'} = int($chars[$config{'char'}]{'hp'} - $damage);
					if ($chars[$config{'char'}]{'hp_max'}) {
						$showHP{'hppercent_now'} = $showHP{'hp_now'} / $chars[$config{'char'}]{'hp_max'} * 100;
						$showHP{'hppercent_now'} = ($showHP{'hppercent_now'} > 1) ? int($showHP{'hppercent_now'}) : 1;
						if ($showHP{'hp_now'} <= 0) {
							$showHP{'hppercent_now'} = 0;
							$showHP{'killedBy'}{'who'} = "$monsters{$ID1}{'name'} ($monsters{$ID1}{'binID'})";
							$showHP{'killedBy'}{'how'} = "普通攻擊";
							$showHP{'killedBy'}{'dmg'} = $dmgDisplay;
						}
					}
					if ($damage) {
#						printC("●怪物攻擊你: $monsters{$ID1}{'name'} ($monsters{$ID1}{'binID'}) - 造成傷害: $dmgDisplay●($showHP{'hppercent_now'}%)\n", "alert");
						printC("●怪物攻擊你: ${sourceDisplay}- 造成傷害: $dmgDisplay●($showHP{'hppercent_now'}%)\n", "alert");
					} else {
						print "●怪物攻擊你: ${sourceDisplay}- 造成傷害: $dmgDisplay●($showHP{'hppercent_now'}%)\n";
					}
				}
#Karasu Start
				# Counter priority

				if (
					$config{'attackCounterFirst'} ne "-1"
					&& !$monsters{$ID1}{'attack_failed'}
					&& $ai_index ne ""
					&& %{$monsters{$ai_seq_args[$ai_index]{'ID'}}}
					&& $ai_seq_args[$ai_index]{'ID'} ne $ID1
					&& !$ai_seq_args[$ai_index]{'takenBy'}
					&& !(
						$config{'attackAuto_notMode'} > 1
#						&& $mon_control{lc($monsters{$ai_seq_args[$ai_index]{'ID'}}{'name'})}{'attack_auto'} < 0
						&& sc_getVal($mon_control{lc($monsters{$ID1}{'name'})}{'attack_auto'}, $mon_control{'all'}{'attack_auto'}, 1) < 0
					)
					&& !$ai_v{'temp'}{'castWait'}
#					&& checkTimeOut('ai_attackCounter')
				) {

					if (
						$config{'attackCounterFirst'}
						&& $monsters{$ai_seq_args[$ai_index]{'ID'}}{'dmgFromYou'} == 0
						&& checkTimeOut('ai_attackCounter')
					) {
						undef $ai_v{'temp'}{'distance'};
						$ai_v{'temp'}{'distance'} = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$ID1}{'pos_to'}});

						if (
							$config{'attackCounterFirst'} >= $ai_v{'temp'}{'distance'}
							|| $config{'attackCounterFirst'} < 0
						) {
							print "◆優先反擊圍攻怪物 ${sourceDisplay}-Dist: $ai_v{'temp'}{'distance'}\n";
							attackForceStop(\$remote_socket, $ai_seq_args[$ai_index]{'ID'});
							attack($ID1);
							timeOutStart('ai_attackCounter');
						}

					} elsif ($mon_control{lc($monsters{$ai_seq_args[$ai_index]{'ID'}}{'name'})}{'attack_auto'} ne "0") {

						$counterPriorityLater = ($mon_control{lc($monsters{$ID1}{'name'})}{'attack_auto'} eq "") ? 1 : abs($mon_control{lc($monsters{$ID1}{'name'})}{'attack_auto'});
						$counterPriorityEarlier = ($mon_control{lc($monsters{$ai_seq_args[$ai_index]{'ID'}}{'name'})}{'attack_auto'} eq "") ? 1 : abs($mon_control{lc($monsters{$ai_seq_args[$ai_index]{'ID'}}{'name'})}{'attack_auto'});

						if ($counterPriorityLater > $counterPriorityEarlier) {
							print "◆優先反擊怪物 ${sourceDisplay}-Dist: $ai_v{'temp'}{'distance'}\n";
							attackForceStop(\$remote_socket, $ai_seq_args[$ai_index]{'ID'});
							attack($ID1);
							timeOutStart('ai_attackCounter');
						}

					}

				}
#Karasu End
			} elsif (%{$players{$ID1}}) {
				if ($damage || !$config{'hideMsg_attackMiss'} || $config{'debug'}) {
					# Show HP
					undef $showHP{'hp_now'};
					undef $showHP{'hppercent_now'};
					$showHP{'hp_now'} = int($chars[$config{'char'}]{'hp'} - $damage);
					if ($chars[$config{'char'}]{'hp_max'}) {
						$showHP{'hppercent_now'} = $showHP{'hp_now'} / $chars[$config{'char'}]{'hp_max'} * 100;
						$showHP{'hppercent_now'} = ($showHP{'hppercent_now'} > 1) ? int($showHP{'hppercent_now'}) : 1;
						if ($showHP{'hp_now'} <= 0) {
							$showHP{'hppercent_now'} = 0;
							$showHP{'killedBy'}{'who'} = "$players{$ID1}{'name'} ($players{$ID1}{'binID'})";
							$showHP{'killedBy'}{'how'} = "普通攻擊";
							$showHP{'killedBy'}{'dmg'} = $dmgDisplay;
						}
					}
					if ($damage) {
						printC("●玩家攻擊你: ${sourceDisplay}- 造成傷害: $dmgDisplay●($showHP{'hppercent_now'}%)\n", "alert");
					} else {
						print "●玩家攻擊你: ${sourceDisplay}- 造成傷害: $dmgDisplay●($showHP{'hppercent_now'}%)\n";
					}
				}
			}
#Ayon Start
			#undef $chars[$config{'char'}]{'time_cast'};
#Ayon End
		} elsif (%{$players{$ID1}}) {
			if (%{$monsters{$ID2}}) {
				print "Player ${sourceDisplay}attacks Monster${targetDisplay}- Dmg: $dmgDisplay\n" if ($config{'debug'});
#				print "$sourceDisplay攻擊$targetDisplay - Dmg: $dmgDisplay\n" if ($config{'debug'} || $ID2 eq $ai_v{'temp'}{'ai_attack_ID'});
			} elsif (%{$items{$ID2}}) {
				$items{$ID2}{'takenBy'} = $ID1;
				print "Player ${sourceDisplay}picks up Item $items{$ID2}{'name'} ($items{$ID2}{'binID'})\n" if ($config{'debug'});
			} elsif ($ID2 == 0) {
				if ($action == 0x03) {
					$players{$ID1}{'sitting'} = 0;
					print "Player is Standing: ${sourceDisplay}\n" if ($config{'debug'});
				} elsif ($action == 0x02) {
					$players{$ID1}{'sitting'} = 1;
					print "Player is Sitting: ${sourceDisplay}\n" if ($config{'debug'});
				}
			} elsif (%{$players{$ID2}}) {
				print "Player ${sourceDisplay}attacks Player${targetDisplay}- Dmg: $dmgDisplay\n" if ($config{'debug'});
			}
		} elsif (%{$monsters{$ID1}}) {
			if (%{$players{$ID2}}) {
				print "Monster ${sourceDisplay}attacks Player${targetDisplay}- Dmg: $dmgDisplay\n" if ($config{'debug'});
			} elsif (%{$items{$ID2}}) {
				$items{$ID2}{'takenBy'} = $ID1;
				print "Monster ${sourceDisplay}picks up Item $items{$ID2}{'name'} ($items{$ID2}{'binID'})\n" if ($config{'debug'});
				sysLog("debug", "$switch", "Monster $monsters{$ID1}{'name'} ($monsters{$ID1}{'binID'}) picks up Item $items{$ID2}{'name'} ($items{$ID2}{'binID'})\n", 1);
			} else {
				# Avoid GM by ID
				avoidGM($ID2, "", "可能想要測試你", 1) if ($config{'dcOnGM_paranoia'});
			}

		} else {
			print "不明人物 ".getHex($ID1)." attacks ".getHex($ID2)." - Dmg: $dmgDisplay\n" if ($config{'debug'});
			# Avoid GM by ID
			avoidGM($ID1, "", "可能想要測試你", 1) if ($config{'dcOnGM_paranoia'});
			avoidGM($ID2, "", "可能想要測試你", 1) if ($config{'dcOnGM_paranoia'});
		}

		$msg_size = 29;

	} elsif ($switch eq "008D" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S*", substr($msg, 2, 2));
		$ID = substr($msg, 4, 4);
		$AID = unpack("S*", $ID);
		$chat = substr($msg, 8, $msg_size - 8);
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;

		event_chat("cl", $chatMsgUser, $chatMsg, $ID);
#		if (%{$players{$ID}}) {
#			$chat ="(".sprintf("%2d", $players{$ID}{'lv'})."等/".substr($jobs_lut{$players{$ID}{'jobID'}}, 0, 4)."/$sex_lut{$players{$ID}{'sex'}}/".sprintf("%2d", int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$ID}{'pos_to'}})))."格) $chatMsgUser ($players{$ID}{'binID'}) : $chatMsg";
#		}
#
#		if ($currentChatRoom ne "") {
#			chatLog("聊天室", $chat, "cr");
#		} else {
#			chatLog("聊天", $chat, "c1");
#		}
#		$ai_cmdQue[$ai_cmdQue]{'type'} = "c";
#		$ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
#		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
#		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
#		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
#		$ai_cmdQue++;
#		if ($currentChatRoom ne "") {
#			printC("[聊天室] $chat\n", "c1");
#		} else {
#			printC("[聊天] $chat\n", "c1");
#		}
#		# Beep on event
#		playWave("sounds/C.wav") if ($config{'beep'} && $config{'beep_C'});
#		# Avoid GM
#		avoidGM($ID, $chatMsgUser, "在聊天頻道發言", 0);
#		# Detect chat channel
#		if ($config{'dcOnGM'} && !$quitBczGM) {
#			$seperate = ($config{'dcOnWord_split'}) ? $config{'dcOnWord_split'} : ",";
#			undef @array; splitUseArray(\@array, $config{'dcOnChatWord'}, $seperate);
#			foreach (@array) {
#				undef $found;
#				if ($config{'dcOnWord_quote'}) {
#					($_) = $_ =~ /^"([\s\S]*?)"$/;
#					$found = 1 if ($chatMsg =~ /\Q$_\E/);
#				} else {
#					$found = 1 if ($chatMsg =~ /\Q$_\E/);
#				}
#				if ($found) {
#					print "◆發現ＧＭ: 聊天頻道出現指定字詞【$_】！\n";
#					# Beep on event
#					playWave("sounds/GM.wav") if ($config{'beep'} && $config{'beep_GM'});
#					undef %{$ai_v{'dcOnGM_counter'}};
#					quitOnEvent("dcOnGM", "迴避", "發現ＧＭ: 聊天頻道出現指定字詞【$_】", "gm");
#					chatLog("迴避", "目前位置 【$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."】", "gm");
#					last;
#				}
#			}
#		}

	} elsif ($switch eq "008E" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S*", substr($msg, 2, 2));
		$chat = substr($msg, 4, $msg_size - 4);
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;
#		if ($currentChatRoom ne "") {
#			chatLog("聊天室", "$chatMsgUser : $chatMsg", "cr");
#		} else {
#			chatLog("聊天", "$chatMsgUser : $chatMsg", "c2");
#		}
#		$ai_cmdQue[$ai_cmdQue]{'type'} = "c";
#		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
#		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
#		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
#		$ai_cmdQue++;
#		if ($currentChatRoom ne "") {
#			printC("[聊天室] $chatMsgUser : $chatMsg\n", "c2");
#		} else {
#			printC("[聊天] $chatMsgUser : $chatMsg\n", "c2");
#		}

		event_chat("c2", $chatMsgUser, $chatMsg);

	} elsif ($switch eq "0091" && length($msg) >= 22) {
#		initMapChangeVars();
#		for ($i = 0; $i < @ai_seq; $i++) {
#			ai_setMapChanged($i);
#		}
#		($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
#		# Prevent lost map name
#		if ($map_name eq "") {
#			chatLog("錯誤", "嚴重錯誤: 可能遺失地圖名稱, 重新連線！", "e");
#			relogWait("◆嚴重錯誤: 可能遺失地圖名稱！", 1);
#		}
#
#		$ai_v{'temp'}{'map'} = getMapID($map_name);
#
#		$coords{'x'} = unpack("S1", substr($msg, 18, 2));
#		$coords{'y'} = unpack("S1", substr($msg, 20, 2));
#		%{$chars[$config{'char'}]{'pos'}} = %coords;
#		%{$chars[$config{'char'}]{'pos_to'}} = %coords;
#
#		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
#			getField("$sc_v{'path'}{'fields'}/$ai_v{'temp'}{'map'}.fld", \%field);
#		}
#
#		print "地圖轉換到 - $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): ".getFormattedCoords($chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'})."\n";
#		print "Your Coordinates: $chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'}\n" if ($config{'debug'});
#		print "Sending Map Loaded\n" if ($config{'debug'});
#		sendMapLoaded(\$remote_socket);
#		# Avoid GM
#		if ($ai_v{'teleOnGM'} == 2) {
#			undef %{$ai_v{'dcOnGM_counter'}};
#			quitOnEvent("dcOnGM", "迴避", "發現ＧＭ: 瞬移次數已滿", "gm");
#		}
#		undef $ai_v{'teleOnGM'};
#		undef $sc_v{'temp'}{'teleOnEvent'};
#		# Respawn at undefine map
#		respawnUndefine($ai_v{'temp'}{'map'});

		event_map($switch, $msg);

		$msg_size = 22;

	} elsif ($switch eq "0092" && length($msg) >= 28) {
#		$sc_v{'input'}{'conState'} = 4;
#		undef $sc_v{'input'}{'conState_tries'};
#		for ($i = 0; $i < @ai_seq; $i++) {
#			ai_setMapChanged($i);
#		}
#		($map_name) = substr($msg, 2, 16) =~ /([\s\S]*?)\000/;
#		# Prevent lost map name
#		if ($map_name eq "") {
##			chatLog("錯誤", "嚴重錯誤: 可能遺失地圖名稱, 重新連線！", "e");
#			sysLog("e", "錯誤", "嚴重錯誤: 可能遺失地圖名稱, 重新連線！");
#			relogWait("◆嚴重錯誤: 可能遺失地圖名稱！", 1);
#		}
#
#		$ai_v{'temp'}{'map'} = getMapID($map_name);
#
#		$map_ip = makeIP(substr($msg, 22, 4));
#		$map_port = unpack("S1", substr($msg, 26, 2));
#
#		if ($ai_v{'temp'}{'map'} ne $field{'name'}) {
#			getField("$sc_v{'path'}{'fields'}/$ai_v{'temp'}{'map'}.fld", \%field);
#			sysLog("map", "$switch", "Map: $field{'name'} IP: $map_ip Port: $map_port");
#		}
#
#		print swrite(
#			 "\n ┌──── Game  Info ────┐",[]
#			," ∣MAP  Name : @<<<<<<<<<<<<<<<∣",[$map_name]
#			," ∣MAP  IP   : @<<<<<<<<<<<<<<<∣",[$map_ip]
#			," ∣MAP  Port : @<<<<<<<<<<<<<<<∣",[$map_port]
#			," └──────────────┘\n",[]
#		);
#		print "關閉與地圖伺服器的連線\n" if ($config{'debug'});
#
#		killConnection(\$remote_socket) if (!$option{'X-Kore'});
#
#		undef $sc_v{'temp'}{'teleOnEvent'};

		event_map($switch, $msg);

		$msg_size = 28;

	} elsif ($switch eq "0093" && length($msg) >= 2) {
		$msg_size = 2;

	} elsif ($switch eq "0095" && length($msg) >= 30) {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		if (%{$players{$ID}}) {
			$players{$ID}{'name'} = $name;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@playersID, $ID);
				print "Player Info: $players{$ID}{'name'} ($binID)\n";
			}
			# Record player data
			recordPlayerData($ID) if ($config{'recordPlayerInfo'});
			# Avoid GM
			avoidGM($ID, $name, "出現在你附近", 1);
#Karasu Start
			# Avoid specified player
			avoidPlayer($ID);
#Karasu End
		} elsif (%{$monsters{$ID}}) {
			($monsters{$ID}{'name'}) = $name;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@monstersID, $ID);
				print "Monster Info: $monsters{$ID}{'name'} ($binID)\n";
			}
			if ($monsters_lut{$monsters{$ID}{'nameID'}} eq "") {
				$monsters_lut{$monsters{$ID}{'nameID'}} = $monsters{$ID}{'name'};
				updateMonsterLUT("$sc_v{'path'}{'tables'}/monsters.txt", $monsters{$ID}{'nameID'}, $monsters{$ID}{'name'});
			}
		} elsif (%{$npcs{$ID}}) {
			($npcs{$ID}{'name'}) = $name;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@npcsID, $ID);
				print "NPC Info: $npcs{$ID}{'name'} ($binID)\n";
			}
#Karasu Start
			# NPC Update
			if ($config{'updateNPC'}) {
				foreach (keys(%npcs_lut)) {
					if (
						$npcs_lut{$_}{'map'} eq $field{'name'}
						&& $npcs_lut{$_}{'name'} eq $npcs{$ID}{'name'}
						&& $_ ne $npcs{$ID}{'nameID'}
						&& $npcs_lut{$_}{'pos'}{'x'} == $npcs{$ID}{'pos'}{'x'}
						&& $npcs_lut{$_}{'pos'}{'y'} == $npcs{$ID}{'pos'}{'y'}
					) {
#						print "◆重要訊息: 自動更新 $npcs_lut{$_}{'map'} $npcs_lut{$_}{'pos'}{'x'} $npcs_lut{$_}{'pos'}{'y' } $npcs_lut{$_}{'name'} 的編號, $_ -> $npcs{$ID}{'nameID'}！\n";
#						chatLog("重要", "重要訊息: 自動更新 $npcs_lut{$_}{'map'} $npcs_lut{$_}{'pos'}{'x'} $npcs_lut{$_}{'pos'}{'y' } $npcs_lut{$_}{'name'} 的編號, $_ -> $npcs{$ID}{'nameID'}！", "im");

						sysLog("update", "重要", "◆重要訊息: 自動更新 $npcs_lut{$_}{'map'} $npcs_lut{$_}{'pos'}{'x'} $npcs_lut{$_}{'pos'}{'y' } $npcs_lut{$_}{'name'} 的編號, $_ -> $npcs{$ID}{'nameID'}！", 1);

						updateNPCLUTIntact("$sc_v{'path'}{'tables'}/npcs.txt", $_, $npcs{$ID}{'nameID'});
						updatePortalLUTIntact("$sc_v{'path'}{'tables'}/portals.txt", $_, $npcs{$ID}{'nameID'});

						if ($config{'talkAuto_npc'} eq $_) {
							configModify('talkAuto_npc', $npcs{$ID}{'nameID'}, 2);
						}
						$i = 0;
						while ($config{"talkAuto_$i"."_npc"}) {
							if ($config{"talkAuto_$i"."_npc"} eq $_) {
								configModify("talkAuto_$i"."_npc", $npcs{$ID}{'nameID'}, 2);
							}
							$i++;
						}
						timeOutStart('ai_route_npcTalk') if (binFind(\@ai_seq, "talkAuto") ne "");
						if ($config{'storageAuto_npc'} eq $_) {
							configModify('storageAuto_npc', $npcs{$ID}{'nameID'}, 2);
						}
						timeOutStart('ai_storageAuto') if (binFind(\@ai_seq, "storageAuto") ne "");
						if ($config{'sellAuto_npc'} eq $_) {
							configModify('sellAuto_npc', $npcs{$ID}{'nameID'}, 2);
						}
						timeOutStart('ai_sellAuto') if (binFind(\@ai_seq, "sellAuto") ne "");
						$i = 0;
						while ($config{"buyAuto_$i"."_npc"}) {
							if ($config{"buyAuto_$i"."_npc"} eq $_) {
								configModify("buyAuto_$i"."_npc", $npcs{$ID}{'nameID'}, 2);
							}
							$i++;
						}
						timeOutStart('ai_buyAuto') if (binFind(\@ai_seq, "buyAuto") ne "");

						ai_clientSuspend(0, $timeout{'ai_updateNPC_wait'}{'timeout'}) if (binFind(\@ai_seq, "clientSuspend") eq "");

						last;
					}
				}
			}
#Karasu End
			if (!%{$npcs_lut{$npcs{$ID}{'nameID'}}}) {
				$npcs_lut{$npcs{$ID}{'nameID'}}{'name'} = $npcs{$ID}{'name'};
				$npcs_lut{$npcs{$ID}{'nameID'}}{'map'} = $field{'name'};
				%{$npcs_lut{$npcs{$ID}{'nameID'}}{'pos'}} = %{$npcs{$ID}{'pos'}};
				updateNPCLUT("$sc_v{'path'}{'tables'}/npcs.txt", $npcs{$ID}{'nameID'}, $field{'name'}, $npcs{$ID}{'pos'}{'x'}, $npcs{$ID}{'pos'}{'y'}, $npcs{$ID}{'name'});
			}
		} elsif (%{$pets{$ID}}) {
			($pets{$ID}{'name_given'}) = $name;
			if ($config{'debug'} >= 2) {
				$binID = binFind(\@petsID, $ID);
				print "Pet Info: $pets{$ID}{'name_given'} ($binID)\n";
			}
		}
		$msg_size = 30;

	} elsif ($switch eq "0096" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1",substr($msg,2,2));

	} elsif ($switch eq "0097" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$msg_size = unpack("S1",substr($msg,2,2));
		decrypt(\$newmsg, substr($msg, 28, length($msg)-28));
		$msg = substr($msg, 0, 28).$newmsg;
		($privMsgUser) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		$privMsg = substr($msg, 28, $msg_size - 29);
#		if ($privMsgUser ne "" && binFind(\@privMsgUsers, $privMsgUser) eq "") {
#			$privMsgUsers[@privMsgUsers] = $privMsgUser;
#		}
#		chatLog("密語", "(From $privMsgUser) : $privMsg", "pm");
#		$ai_cmdQue[$ai_cmdQue]{'type'} = "pm";
#		$ai_cmdQue[$ai_cmdQue]{'user'} = $privMsgUser;
#		$ai_cmdQue[$ai_cmdQue]{'msg'} = $privMsg;
#		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
#		$ai_cmdQue++;
#		printC("[密語] (From $privMsgUser) : $privMsg\n", "pm");
#		# Beep on event
#		playWave("sounds/PM.wav") if ($config{'beep'} && $config{'beep_PM'});
#		# Avoid GM
#		avoidGM("", $privMsgUser, "在密語頻道發言", 0);

		event_chat("pm", $privMsgUser, $privMsg);

	} elsif ($switch eq "0098" && length($msg) >= 3) {
#		$type = unpack("C1",substr($msg, 2, 1));
#		if ($type == 0) {
#			printC("[密語] (To $lastpm[0]{'user'}) : $lastpm[0]{'msg'}\n", "pm");
#			chatLog("密語", "(To $lastpm[0]{'user'}) : $lastpm[0]{'msg'}", "pm");
#		} elsif ($type == 1) {
#			print "($lastpm[0]{'user'}) 目前不在線上\n";
#		} elsif ($type == 2) {
#			print "($lastpm[0]{'user'}) 拒絕你的密語\n";
#		} elsif ($type == 3) {
#			print "($lastpm[0]{'user'}) 拒絕所有密語\n";
#		}
#		shift @lastpm;

		event_chat("pm", $sc_v{'pm'}{'lastTo'}, $sc_v{'pm'}{'lastMsg'}, unpack("C1",substr($msg, 2, 1)), 1);

		$msg_size = 3;

	} elsif ($switch eq "009A" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
		$chat = substr($msg, 4, $msg_size - 4);

		$chat =~ s/\000$//g;

		event_chat("s", "", $chat);

#		chatLog("公告", $chat, "s");
#		printC("$chat\n", "s");
#		# Beep on event
#		playWave("sounds/S.wav") if ($config{'beep'} && $config{'beep_S'});
#		# Detect system channel
#		if ($config{'dcOnGM'}) {
#			$seperate = ($config{'dcOnWord_split'}) ? $config{'dcOnWord_split'} : ",";
#			undef @array; splitUseArray(\@array, $config{'dcOnSysWord'}, $seperate);
#			foreach (@array) {
#				undef $found;
#				if ($config{'dcOnWord_quote'}) {
#					($_) = $_ =~ /^"([\s\S]*?)"$/;
#					$found = 1 if ($chat =~ /\Q$_\E/);
#				} else {
#					$found = 1 if ($chat =~ /\Q$_\E/);
#				}
#				if ($found) {
#					print "◆發現ＧＭ: 公告頻道出現指定字詞【$_】！\n";
#					# Beep on event
#					playWave("sounds/GM.wav") if ($config{'beep'} && $config{'beep_GM'});
#					undef %{$ai_v{'dcOnGM_counter'}};
#					quitOnEvent("dcOnGM", "迴避", "發現ＧＭ: 公告頻道出現指定字詞【$_】", "gm");
#					chatLog("迴避", "目前位置 【$maps_lut{$field{'name'}.'.rsw'}($field{'name'}): ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."】", "gm");
#					last;
#				}
#			}
#		}

	} elsif ($switch eq "009C" && length($msg) >= 9) {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$ID = substr($msg, 2, 4);
		$body = unpack("C1",substr($msg, 8, 1));
		$head = unpack("C1",substr($msg, 6, 1));
		if ($ID eq $accountID) {
			$chars[$config{'char'}]{'look'}{'head'} = $head;
			$chars[$config{'char'}]{'look'}{'body'} = $body;
			print "You look at $chars[$config{'char'}]{'look'}{'body'}, $chars[$config{'char'}]{'look'}{'head'}\n" if ($config{'debug'} >= 2);

		} elsif (%{$players{$ID}}) {
			$players{$ID}{'look'}{'head'} = $head;
			$players{$ID}{'look'}{'body'} = $body;
			print "Player $players{$ID}{'name'} ($players{$ID}{'binID'}) looks at $players{$ID}{'look'}{'body'}, $players{$ID}{'look'}{'head'}\n" if ($config{'debug'} >= 2);

		} elsif (%{$monsters{$ID}}) {
			$monsters{$ID}{'look'}{'head'} = $head;
			$monsters{$ID}{'look'}{'body'} = $body;
			print "Monster $monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) looks at $monsters{$ID}{'look'}{'body'}, $monsters{$ID}{'look'}{'head'}\n" if ($config{'debug'} >= 2);
		}
		$msg_size = 9;

	} elsif ($switch eq "009D" && length($msg) >= 17) {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$ID = substr($msg, 2, 4);
		$type = unpack("S1",substr($msg, 6, 2));
		$x = unpack("S1", substr($msg, 9, 2));
		$y = unpack("S1", substr($msg, 11, 2));
		$amount = unpack("S1", substr($msg, 13, 2));
		if (!%{$items{$ID}}) {
			binAdd(\@itemsID, $ID);
			$items{$ID}{'appear_time'} = time;
			$items{$ID}{'amount'} = $amount;
			$items{$ID}{'nameID'} = $type;
			$display = ($items_lut{$items{$ID}{'nameID'}} ne "")
				? $items_lut{$items{$ID}{'nameID'}}
				: "不明物品 ".$items{$ID}{'nameID'};
			$items{$ID}{'binID'} = binFind(\@itemsID, $ID);
			$items{$ID}{'name'} = $display;
		}
		$items{$ID}{'pos'}{'x'} = $x;
		$items{$ID}{'pos'}{'y'} = $y;
		print "發現物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'}\n" if (!$config{'hideMsg_itemsExist'} || $config{'debug'});
		# Important item found
		my $i_cDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$items{$ID}{'pos'}});
		if (
			$config{'itemsImportantAuto'}
			&& $i_cDist <= $config{'itemsImportantAuto'}
			&& (
				$itemsPickup{lc($items{$ID}{'name'})} eq ""
				|| $itemsPickup{lc($items{$ID}{'name'})} >= 2
			)
		){
			getImportantItems($ID, int($i_cDist), "009D");
		}
		$msg_size = 17;

	} elsif ($switch eq "009E" && length($msg) >= 17) {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$ID = substr($msg, 2, 4);
		$type = unpack("S1",substr($msg, 6, 2));
		$x = unpack("S1", substr($msg, 9, 2));
		$y = unpack("S1", substr($msg, 11, 2));
		$amount = unpack("S1", substr($msg, 15, 2));
		if (!%{$items{$ID}}) {
			binAdd(\@itemsID, $ID);
			$items{$ID}{'appear_time'} = time;
			$items{$ID}{'amount'} = $amount;
			$items{$ID}{'nameID'} = $type;
			$display = ($items_lut{$items{$ID}{'nameID'}} ne "")
				? $items_lut{$items{$ID}{'nameID'}}
				: "不明物品 ".$items{$ID}{'nameID'};
			$items{$ID}{'binID'} = binFind(\@itemsID, $ID);
			$items{$ID}{'name'} = $display;
		}
		$items{$ID}{'pos'}{'x'} = $x;
		$items{$ID}{'pos'}{'y'} = $y;
		print "出現物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'}\n";
		# Important item found
		my $i_cDist = distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$items{$ID}{'pos'}});
		if (
			$config{'itemsImportantAuto'}
			&& $i_cDist <= $config{'itemsImportantAuto'}
			&& (
				$itemsPickup{lc($items{$ID}{'name'})} eq ""
				|| $itemsPickup{lc($items{$ID}{'name'})} >= 2
			)
		){
			getImportantItems($ID, int($i_cDist), "009E");
		}
		$msg_size = 17;

	} elsif ($switch eq "00A0" && length($msg) >= 23) {
		$index  = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		$ID     = unpack("S1",substr($msg, 6, 2));
		$type   = unpack("C1",substr($msg, 21, 1));
		$fail   = unpack("C1",substr($msg, 22, 1));
		undef $invIndex;
#Solos Start
#Search with index, not name! Otherwise non-stackable item will screw it up!
#		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", $ID);
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
#Solos End
		if ($fail == 0) {
			if ($invIndex eq "" || $itemSlots_lut{$ID} != 0) {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}      = $index;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}     = $ID;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'}     = $amount;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}       = $type;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1",substr($msg, 8, 1));
				#$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = unpack("S1",substr($msg, 19, 2));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = $itemSlots_lut{$ID};
				if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} == 1024) {
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'borned'} = unpack("C1", substr($msg, 9, 1));
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'named'} = unpack("C1", substr($msg, 17, 1));
				} elsif ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}) {
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'broken'}       = unpack("C1", substr($msg, 9, 1));
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'refined'}      = unpack("C1", substr($msg, 10, 1));
#					if (unpack("S1", substr($msg, 11, 2)) == 0x00FF) {
#						$chars[$config{'char'}]{'inventory'}[$invIndex]{'attribute'} = unpack("C1", substr($msg, 13, 1));
#						$chars[$config{'char'}]{'inventory'}[$invIndex]{'star'}      = unpack("C1", substr($msg, 14, 1)) / 0x05;
#						$chars[$config{'char'}]{'inventory'}[$invIndex]{'maker_charID'} = substr($msg, 15, 4);
#						if (!$charID_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'maker_charID'}}) {
#							sendGetPlayerInfoByCharID(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'maker_charID'});
#						}
#					} else {
#						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[0]   = unpack("S1", substr($msg, 11, 2));
#						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[1]   = unpack("S1", substr($msg, 13, 2));
#						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[2]   = unpack("S1", substr($msg, 15, 2));
#						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[3]   = unpack("S1", substr($msg, 17, 2));
#					}
					if (unpack("S1", substr($msg, 11, 2)) == 0x00FF) {
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'attribute'} = unpack("C1", substr($msg, 13, 1));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'star'}      = unpack("C1", substr($msg, 14, 1)) / 0x05;
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'maker_charID'} = substr($msg, 15, 4);
						if (!$charID_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'maker_charID'}}) {
							sendGetPlayerInfoByCharID(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'maker_charID'});
						}
					} else {
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[0]   = unpack("S1", substr($msg, 11, 2));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[1]   = unpack("S1", substr($msg, 13, 2));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[2]   = unpack("S1", substr($msg, 15, 2));
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[3]   = unpack("S1", substr($msg, 17, 2));
					}
				}
				$display = ($items_lut{$ID} ne "")
					? $items_lut{$ID}
					: "不明物品 ".$ID;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
				modifyName(\%{$chars[$config{'char'}]{'inventory'}[$invIndex]});
			} else {
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} += $amount;
			}
			print "物品欄增加: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n";

			# Rare item got list
			my $tmp_pick = $itemsPickup{lc($chars[$config{'char'}]{'inventory'}[$invIndex]{'name'})};

			if (($tmp_pick >= 2 || ($config{'recordItemPickup'} && ($tmp_pick >= $config{'recordItemPickup'} || !$tmp_pick))) || $record{'importantItems'}{$ID} > 0 || $record{'item'}{$ID}) {
				$record{'item'}{$ID} += $amount;
			}

#			if (!switchInput($ai_seq[0], "take", "buyAuto", "storageAuto")) {
#				$record{'takeNot'}{$ID} += $amount;
#			}
			if (!switchInput($ai_seq[0], "buyAuto", "storageAuto") && $ID ne $sc_v{'temp'}{'takeNameID'}) {
				$record{'takeNot'}{$ID} += $amount;
			} else {
				undef $sc_v{'temp'}{'takeNameID'};
			}
#Karasu Start
			if ($config{'itemsDropAuto'} && $tmp_pick < 0 && (binFind(\@ai_seq, "storageAuto") eq "" && binFind(\@ai_seq, "buyAuto") eq "")) {
				sendDrop(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $amount);
				printC("Auto-Drop Item : $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount \n", "event");
				$record{'Auto-Drop'}{$ID} += $amount;
			}
			# Auto cart add (When cart is avaliable)
			elsif ($config{'cartAuto'} && $cart{'weight_max'} && ($cart{'weight'}/$cart{'weight_max'})*100 < $config{'cartMaxWeight'}) {
				if ($ai_seq[0] eq "buyAuto") {
					$i = 0;
					while(1) {
						last if (!$config{"buyAuto_$i"} || !$config{"buyAuto_$i"."_npc"});
						if ($display eq $config{"buyAuto_$i"} && $config{"buyAuto_$i"."_maxCartAmount"} > 0 && $config{"buyAuto_$i"."_minAmount"} ne "" && $config{"buyAuto_$i"."_maxAmount"} ne "") {
							$ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $display);
							if ($ai_v{'temp'}{'cartIndex'} eq "" || ($ai_v{'temp'}{'cartIndex'} ne "" && $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxCartAmount"})) {
								if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} > $config{"buyAuto_$i"."_maxCartAmount"} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'}) {
									sendCartAdd(\$remote_socket, $index, $config{"buyAuto_$i"."_maxCartAmount"} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'});
								} else {
									sendCartAdd(\$remote_socket, $index, $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'});
								}
								timeOutStart('ai_buyAuto');
								last;
							}
						}
						$i++;
					}
#				} elsif ($ai_seq[0] eq "storageAuto" && $config{"storagegetAuto_npc"}) {
#					$i = 0;
#					while(1) {
#						last if (!$config{"storagegetAuto_$i"});
#						if ($display eq $config{"storagegetAuto_$i"} && $config{"storagegetAuto_$i"."_maxCartAmount"} > 0 && $config{"storagegetAuto_$i"."_minAmount"} ne "" && $config{"storagegetAuto_$i"."_maxAmount"} ne "") {
#							$ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $display);
#							if ($ai_v{'temp'}{'cartIndex'} eq "" || ($ai_v{'temp'}{'cartIndex'} ne "" && $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"storagegetAuto_$i"."_maxCartAmount"})) {
#								if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} > $config{"storagegetAuto_$i"."_maxCartAmount"} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'}) {
#									sendCartAdd(\$remote_socket, $index, $config{"storagegetAuto_$i"."_maxCartAmount"} - $cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'});
#								} else {
#									sendCartAdd(\$remote_socket, $index, $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'});
#								}
#								timeOutStart('ai_storageAuto');
#								last;
#							}
#						}
#						$i++;
#					}
				} elsif ($items_control{lc($chars[$config{'char'}]{'inventory'}[$invIndex]{'name'})}{'cart'}) {
					$cartAmount = $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$invIndex]{'name'})}{'keep'};
					#$itemWeight= findItemWeight($chars[$config{'char'}]{'inventory'}[$i]{'nameID'});
					if ($cartAmount > 0) {
						sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}, $cartAmount);
					}
				}
			}
#Karasu End
#		} elsif ($fail == 2) {
#			printC("超過最大負重量, 無法取得物品\n", "alert");
#		} elsif ($fail == 4) {
#			printC("已經超過一次可以拿取的數量, 無法再拿取任何物品\n", "alert");
#		} elsif ($fail == 5) {
#			printC("同一種物品無法取得３萬個以上\n", "alert");
#		} elsif ($fail == 6) {
#			print "無法撿起物品...重試中...\n";
		} else {
			printC(getMsgStrings("00A0", $fail, 0, 1)."\n", "alert");
		}
		$msg_size = 23;

	} elsif ($switch eq "00A1" && length($msg) >= 6) {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$ID = substr($msg, 2, 4);

		event_takenBy($ID);

#		if (%{$items{$ID}}) {
#			print "Item Disappeared: $items{$ID}{'name'} ($items{$ID}{'binID'})\n" if ($config{'debug'});
#			%{$items_old{$ID}} = %{$items{$ID}};
#			$items_old{$ID}{'disappeared'} = 1;
#			$items_old{$ID}{'gone_time'} = time;
#			# Important item fail
#			if ($ai_v2{'ImportantItem'}{'attackAuto'} ne "" && binFind(\@{$ai_v2{'ImportantItem'}{'targetID'}}, $ID) ne "") {
#				binRemoveAndShift(\@{$ai_v2{'ImportantItem'}{'targetID'}}, $ID);
#				if (!binSize(\@{$ai_v2{'ImportantItem'}{'targetID'}})) {
#					$config{'attackAuto'} = $ai_v2{'ImportantItem'}{'attackAuto'};
#					undef %{$ai_v2{'ImportantItem'}};
#					undef $sc_v{'temp'}{'itemsImportantAutoMode'};
#				}
#				if ($items{$ID}{'takenBy'} ne "") {
#					if ($items{$ID}{'takenBy'} eq $accountID) {
#						# Beep on event
##						playWave("sounds/iItemsGot.wav") if ($config{'beep'} && $config{'beep_iItemsGot'});
#
#						event_beep("iItemsGot");
#
##						chatLog("", "$items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 獲得！", "ii");
#						sysLog("ii", "自己", "$items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 獲得！");
#						# Rare item got list
##						$rareItemGet{$items{$ID}{'name'}} += $items{$ID}{'amount'};
#					} elsif (%{$players{$items{$ID}{'takenBy'}}}) {
#						my $options;
#						$options = "(GID:".unpack("L1", $items{$ID}{'takenBy'})."/".sprintf("%2d", $players{$items{$ID}{'takenBy'}}{'lv'})."等/".substr($jobs_lut{$players{$items{$ID}{'takenBy'}}{'jobID'}}, 0, 4)."/$sex_lut{$players{$items{$ID}{'takenBy'}}{'sex'}}/".sprintf("%2d", int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$items{$ID}{'takenBy'}}{'pos_to'}})))."格) " if (!$config{'hideMsg_takenByInfo'});
#						# Show important item's taker
##						print "重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 被 $players{$items{$ID}{'takenBy'}}{'name'} ($players{$items{$ID}{'takenBy'}}{'binID'}) 撿走了！\n";
#						sysLog("ii", "玩家", "重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 被 ${options}$players{$items{$ID}{'takenBy'}}{'name'} ($players{$items{$ID}{'takenBy'}}{'binID'}) 撿走了！", 1);
#					} elsif (%{$monsters{$items{$ID}{'takenBy'}}}) {
#						# Show important item's taker
##						print "重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 被 $monsters{$items{$ID}{'takenBy'}}{'name'} ($monsters{$items{$ID}{'takenBy'}}{'binID'}) 吃掉了！\n";
##						chatLog("", "重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 被 $players{$items{$ID}{'takenBy'}}{'name'} ($players{$items{$ID}{'takenBy'}}{'binID'}) 吃掉了！", "ii");
#
#						$monsters{$items{$ID}{'takenBy'}}{'takenBy'} = 1;
#						sysLog("ii", "怪物", "重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 被 $monsters{$items{$ID}{'takenBy'}}{'name'} ($monsters{$items{$ID}{'takenBy'}}{'binID'}) 吃掉了！", 1);
#
#						if ($config{'attackAuto_takenBy'}) {
#							ai_takenBy($items{$ID}{'takenBy'});
#
##							my $ai_index = binFind(\@ai_seq, "attack");
##
##							if ($ai_index ne "") {
##								attackForceStop(\$remote_socket, $ai_seq_args[$ai_index]{'ID'});
###								aiRemove("attack");
##							}
##
##							attack($items{$ID}{'takenBy'});
#						}
#					} elsif ($config{'attackAuto_takenBy'} > 1) {
#						undef $ai_v{'temp'}{'foundID'};
#						foreach (@monstersID) {
#							next if ($_ eq "" || !existsInList($config{'attackAuto_takenByMonsters'}, $monsters{$_}{'name'}));
#							if (
#								(
#									$monsters{$_}{'pos'}{'x'} == $items_old{$ID}{'pos'}{'x'}
#									&& $monsters{$_}{'pos'}{'y'} == $items_old{$ID}{'pos'}{'y'}
#								) || (
#									$monsters{$_}{'pos_to'}{'x'} == $items_old{$ID}{'pos'}{'x'}
#									&& $monsters{$_}{'pos_to'}{'y'} == $items_old{$ID}{'pos'}{'y'}
#								)
#							) {
#								$ai_v{'temp'}{'foundID'} = $_;
#								last;
#							}
#						}
#
#						ai_takenBy($ai_v{'temp'}{'foundID'});
#
##						if ($ai_v{'temp'}{'foundID'} ne "") {
##							$monsters{$ai_v{'temp'}{'foundID'}}{'takenBy'} = 1;
##
##							my $ai_index = binFind(\@ai_seq, "attack");
##							if ($ai_index ne "") {
##								attackForceStop(\$remote_socket, $ai_seq_args[$ai_index]{'ID'});
###								aiRemove("attack");
##							}
##							attack($ai_v{'temp'}{'foundID'});
##
##							sysLog("ii", "怪物", "重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 可能被 $monsters{$ai_v{'temp'}{'foundID'}}{'name'} ($monsters{$ai_v{'temp'}{'foundID'}}{'binID'}) 吃掉了！", 1);
##						}
#					} else {
#						sysLog("ii", "不明", "重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 消失於 ($items{$ID}{'pos'}{'x'}, $items{$ID}{'pos'}{'y'})", 1);
#					}
#				} elsif ($config{'attackAuto_takenBy'} > 1) {
#					undef $ai_v{'temp'}{'foundID'};
#
#					if ($config{'attackAuto_takenBy'} > 2) {
#						my $j = 0;
#
#						foreach (@monstersID) {
#							next if ($_ eq "" || !existsInList($config{'attackAuto_takenByMonsters'}, $monsters{$_}{'name'}));
#							if (
#								distance(\%{$items_old{$ID}{'pos'}}, \%{$monsters{$_}{'pos'}}, 1) <= $config{'itemsTakeDist'}
#								||
#								distance(\%{$items_old{$ID}{'pos'}}, \%{$monsters{$_}{'pos_to'}}, 1) <= $config{'itemsTakeDist'}
#							) {
#								$monsters{$_}{'attack_failed'} = 0;
#								$monsters{$_}{'takenBy'} = 1;
#								$ai_v{'temp'}{'foundID'} = $_;
##								last if ($j > 3);
##								$j++
#							}
#						}
#					} else {
#						foreach (@monstersID) {
#							next if ($_ eq "" || !existsInList($config{'attackAuto_takenByMonsters'}, $monsters{$_}{'name'}));
#							if (
#								(
#									$monsters{$_}{'pos'}{'x'} == $items_old{$ID}{'pos'}{'x'}
#									&& $monsters{$_}{'pos'}{'y'} == $items_old{$ID}{'pos'}{'y'}
#								) || (
#									$monsters{$_}{'pos_to'}{'x'} == $items_old{$ID}{'pos'}{'x'}
#									&& $monsters{$_}{'pos_to'}{'y'} == $items_old{$ID}{'pos'}{'y'}
#								)
#							) {
#								$ai_v{'temp'}{'foundID'} = $_;
#								last;
#							}
#						}
#					}
#
#					ai_takenBy($ai_v{'temp'}{'foundID'});
#
##					if ($ai_v{'temp'}{'foundID'} ne "") {
##						$monsters{$ai_v{'temp'}{'foundID'}}{'takenBy'} = 1;
##
##						my $ai_index = binFind(\@ai_seq, "attack");
##						attackForceStop(\$remote_socket, $ai_seq_args[$ai_index]{'ID'}) if ($ai_index ne "");
##						attack($ai_v{'temp'}{'foundID'});
##
##						sysLog("ii", "怪物", "重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 可能被 $monsters{$ai_v{'temp'}{'foundID'}}{'name'} ($monsters{$ai_v{'temp'}{'foundID'}}{'binID'}) 吃掉了！", 1);
##					}
#				} else {
#					sysLog("ii", "不明", "重要物品: $items{$ID}{'name'} ($items{$ID}{'binID'}) x $items{$ID}{'amount'} 消失於 ($items{$ID}{'pos'}{'x'}, $items{$ID}{'pos'}{'y'})", 1);
#				}
#			}
#			undef %{$items{$ID}};
#			binRemove(\@itemsID, $ID);
#		}
		$msg_size = 6;

	} elsif (($switch eq "00A3" || $switch eq "01EE") && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		$psize = ($switch eq "00A3") ? 10 : 18;
		undef $invIndex;
		for($i = 4; $i < $msg_size; $i+=$psize) {
			$index    = unpack("S1", substr($msg, $i, 2));
			$ID       = unpack("S1", substr($msg, $i + 2, 2));
			$type     = unpack("C1", substr($msg, $i + 4, 1));
			$amount   = unpack("S1", substr($msg, $i + 6, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
			}
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}      = $index;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}     = $ID;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'}     = $amount;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}       = $type;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = 0 if ($type == 10);
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "不明物品 ".$ID;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
			print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount - $itemTypes_lut{$type}\n" if ($config{'debug'});
		}
		useTeleport($ai_v{'teleQueue'}) if ($ai_v{'teleQueue'});

#		timeOutStart(-1, 'ai');

	} elsif ($switch eq "00A4" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef $invIndex;
		for($i = 4; $i < $msg_size; $i+=20) {
			$index  = unpack("S1", substr($msg, $i, 2));
			$ID     = unpack("S1", substr($msg, $i + 2, 2));
			$type   = unpack("C1", substr($msg, $i + 4, 1));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
			}
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'}      = $index;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}     = $ID;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'}     = 1;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}       = $type;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			#$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = unpack("S1", substr($msg, $i + 6, 2));
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} = $itemSlots_lut{$ID};
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'}   = unpack("S1", substr($msg, $i + 8, 2));
			# Equip arrow related
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = "" if !($chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'});
			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'} == 1024) {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'borned'} = unpack("C1", substr($msg, $i + 10, 1));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'named'} = unpack("C1", substr($msg, $i + 18, 1));
			} elsif ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}) {
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'broken'}       = unpack("C1", substr($msg, $i + 10, 1));
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'refined'}      = unpack("C1", substr($msg, $i + 11, 1));
				if (unpack("S1", substr($msg, $i + 12, 2)) == 0x00FF) {
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'attribute'} = unpack("C1", substr($msg, $i + 14, 1));
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'star'}      = unpack("C1", substr($msg, $i + 15, 1)) / 0x05;
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'maker_charID'} = substr($msg, $i + 16, 4);
					if (!$charID_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'maker_charID'}}) {
						sendGetPlayerInfoByCharID(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$invIndex]{'maker_charID'});
					}
				} else {
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[0]   = unpack("S1", substr($msg, $i + 12, 2));
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[1]   = unpack("S1", substr($msg, $i + 14, 2));
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[2]   = unpack("S1", substr($msg, $i + 16, 2));
					$chars[$config{'char'}]{'inventory'}[$invIndex]{'card'}[3]   = unpack("S1", substr($msg, $i + 18, 2));
				}
			}
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "不明物品 ".$ID;
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} = $display;
			modifyName(\%{$chars[$config{'char'}]{'inventory'}[$invIndex]});
			print "Inventory: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x 1 - $itemTypes_lut{$type} - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}}\n" if ($config{'debug'});

			if ($sc_v{'temp'}{'broken'} eq $invIndex && $chars[$config{'char'}]{'inventory'}[$invIndex]{'borned'}) {
				$record{"broken"}{$ID}++;
				sysLog("event", "物品", "$showHP{'killedBy'}{'who'} 的 $showHP{'killedBy'}{'how'} 對你的 $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} 造成破壞", 1);
				undef $sc_v{'temp'}{'broken'};
			}
		}

	} elsif (($switch eq "00A5" || $switch eq "01F0") && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		$psize = ($switch eq "00A5") ? 10 : 18;
		undef %storage;
		for($i = 4; $i < $msg_size; $i+=$psize) {
			$index  = unpack("S1", substr($msg, $i, 2));
			$ID     = unpack("S1", substr($msg, $i + 2, 2));
			$type   = unpack("C1", substr($msg, $i + 4, 1));
			$amount = unpack("S1", substr($msg, $i + 6, 2));
			$storage{'inventory'}[$index]{'nameID'}     = $ID;
			$storage{'inventory'}[$index]{'amount'}     = $amount;
			$storage{'inventory'}[$index]{'type'}       = $type;
			$storage{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "不明物品 ".$ID;
			$storage{'inventory'}[$index]{'name'} = $display;
			print "Storage: $storage{'inventory'}[$index]{'name'} ($index) x $amount\n" if ($config{'debug'});
		}
		print "倉庫已開啟\n";

	} elsif ($switch eq "00A6" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
 		$msg = substr($msg, 0, 4).$newmsg;
		for($i = 4; $i < $msg_size; $i+=20) {
			$index  = unpack("S1", substr($msg, $i, 2));
			$ID     = unpack("S1", substr($msg, $i + 2, 2));
			$type   = unpack("C1", substr($msg, $i + 4, 1));
			$storage{'inventory'}[$index]{'nameID'}     = $ID;
			$storage{'inventory'}[$index]{'amount'}     = 1;
			$storage{'inventory'}[$index]{'type'}       = $type;
			$storage{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			#$storage{'inventory'}[$index]{'type_equip'} = unpack("S1", substr($msg, $i + 6, 2));
			$storage{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
			if ($storage{'inventory'}[$index]{'type_equip'} == 1024) {
				$storage{'inventory'}[$index]{'borned'} = unpack("C1", substr($msg, $i + 10, 1));
				$storage{'inventory'}[$index]{'named'} = unpack("C1", substr($msg, $i + 18, 1));
			} elsif ($storage{'inventory'}[$index]{'type_equip'}) {
				$storage{'inventory'}[$index]{'broken'}       = unpack("C1", substr($msg, $i + 10, 1));
				$storage{'inventory'}[$index]{'refined'}      = unpack("C1", substr($msg, $i + 11, 1));
				if (unpack("S1", substr($msg, $i + 12, 2)) == 0x00FF) {
					$storage{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, $i + 14, 1));
					$storage{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, $i + 15, 1)) / 0x05;
					$storage{'inventory'}[$index]{'maker_charID'} = substr($msg, $i + 16, 4);
					if (!$charID_lut{$storage{'inventory'}[$index]{'maker_charID'}}) {
						sendGetPlayerInfoByCharID(\$remote_socket, $storage{'inventory'}[$index]{'maker_charID'});
					}
				} else {
					$storage{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, $i + 12, 2));
					$storage{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, $i + 14, 2));
					$storage{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, $i + 16, 2));
					$storage{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, $i + 18, 2));
				}
			}
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "不明物品 ".$ID;
			$storage{'inventory'}[$index]{'name'} = $display;
			modifyName(\%{$storage{'inventory'}[$index]});
			print "Storage Item: $storage{'inventory'}[$index]{'name'} ($index) x 1\n" if ($config{'debug'});
		}

	} elsif ($switch eq "00A8" && length($msg) >= 7) {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$index = unpack("S1",substr($msg, 2, 2));
		$amountleft = unpack("S1",substr($msg, 4, 2));
		$amountused = unpack("C1",substr($msg, 6, 1));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if (!$amountused) {
			print "你無法使用物品: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n";
		} else {
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = $amountleft;
			print "你使用物品: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amountused - 剩餘數量: $amountleft\n";
			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
				undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
			}
		}
		undef $chars[$config{'char'}]{'sendItemUse'};

		$msg_size = 7;

	} elsif ($switch eq "00AA" && length($msg) >= 7) {
		$index = unpack("S1",substr($msg, 2, 2));
		$type = unpack("S1",substr($msg, 4, 2));
		$fail = unpack("C1",substr($msg, 6, 1));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if ($fail == 0) {
			print "你無法裝備 $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n";
		} else {
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = $type;
			print "你裝備 $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}}\n";
		}
		$msg_size = 7;

	} elsif ($switch eq "00AC" && length($msg) >= 7) {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$index = unpack("S1",substr($msg, 2, 2));
		$type = unpack("S1",substr($msg, 4, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = "";
		# Equip arrow related
		if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} == 10) {
			print "你卸下 $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n";
		} else {
			print "你卸下 $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $equipTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type_equip'}}\n";
		}

		sysLog("event", "物品", "$showHP{'killedBy'}{'who'} 的 $showHP{'killedBy'}{'how'} 對你的 $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} 造成破壞", 1) if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'broken'});

		$sc_v{'temp'}{'broken'} = $invIndex;
		undef $chars[$config{'char'}]{'autoSwitch'} if ($chars[$config{'char'}]{'autoSwitch'} eq $invIndex);

		$msg_size = 7;

	} elsif ($switch eq "00AF" && length($msg) >= 6) {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$index = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		if ($amount == 0 && $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} eq "0") {
			print "裝備的箭一定要先卸下\n";
		} elsif ($chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} ne "" && $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} ne "0") {
			print "裝備的物品一定要先卸下\n";
		} else {
#			if (!($amount == 1 && $ai_seq[0] eq "attack" && $config{'hideMsg_arrowRemove'} && $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} eq "0")
#				|| $config{'debug'}) {
#				print "物品欄減少: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n";
#			}
			if (!($config{'hideMsg_arrowRemove'} && $chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} eq "0")) {
				print "物品欄減少: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amount - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n";
			}
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $amount;
			if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
				undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
			}
		}
		$msg_size = 6;

	} elsif ($switch eq "00B0" && length($msg) >= 8) {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("L1",substr($msg, 4, 4));
		if ($type == 0) {
			$chars[$config{'char'}]{'walk_speed'} = $val / 1000;
			print "Walk Speed: $val\n" if ($config{'debug'});
		} elsif ($type == 3) {
			print "Something2: $val\n" if ($config{'debug'});
		} elsif ($type == 4) {
			$val = unpack("l1",substr($msg, 4, 4));
			$val = abs($val);
			if ($val) {
				print "你的禁言限制還剩下 $val分鐘！\n";
				$chars[$config{'char'}]{'skill_ban'} = $val;
				if ($config{'dcOnSkillBan'}) {
					print "◆啟動 dcOnSkillBan - 立即登出！\n";
#					chatLog("危險", "禁言限制: 可能遭到惡意禁言, 立即登出！", "im");
					sysLog("im", "危險", "禁言限制($val分鐘): 可能遭到惡意禁言, 立即登出！");
#					$quit = 1;

					quit(1, 1);
				}
			} else {
				print "你的禁言限制已經解除！\n";
				$chars[$config{'char'}]{'skill_ban'} = 0;
			}
		} elsif ($type == 5) {
			$chars[$config{'char'}]{'hp'} = $val;
			print "Hp: $val\n" if ($config{'debug'});
		} elsif ($type == 6) {
			$chars[$config{'char'}]{'hp_max'} = $val;
			print "Max Hp: $val\n" if ($config{'debug'});
		} elsif ($type == 7) {
			$chars[$config{'char'}]{'sp'} = $val;
			print "Sp: $val\n" if ($config{'debug'});
		} elsif ($type == 8) {
			$chars[$config{'char'}]{'sp_max'} = $val;
			print "Max Sp: $val\n" if ($config{'debug'});
		} elsif ($type == 9) {
			$chars[$config{'char'}]{'points_free'} = $val;
			print "Status Points: $val\n" if ($config{'debug'});
		} elsif ($type == 11) {
			$chars[$config{'char'}]{'lv'} = $val;
			print "Level: $val\n" if ($config{'debug'});
		} elsif ($type == 12) {
			$chars[$config{'char'}]{'points_skill'} = $val;
			print "Skill Points: $val\n" if ($config{'debug'});
		} elsif ($type == 24) {
			$chars[$config{'char'}]{'weight'} = int($val / 10);
			print "Weight: $chars[$config{'char'}]{'weight'}\n" if ($config{'debug'});
		} elsif ($type == 25) {
			$chars[$config{'char'}]{'weight_max'} = int($val / 10);
			print "Max Weight: $chars[$config{'char'}]{'weight_max'}\n" if ($config{'debug'});
		} elsif ($type == 41) {
			$chars[$config{'char'}]{'attack'} = $val;
			print "Attack: $val\n" if ($config{'debug'});
		} elsif ($type == 42) {
			$chars[$config{'char'}]{'attack_bonus'} = $val;
			print "Attack Bonus: $val\n" if ($config{'debug'});
		} elsif ($type == 43) {
			$chars[$config{'char'}]{'attack_magic_min'} = $val;
			print "Magic Attack Min: $val\n" if ($config{'debug'});
		} elsif ($type == 44) {
			$chars[$config{'char'}]{'attack_magic_max'} = $val;
			print "Magic Attack Max: $val\n" if ($config{'debug'});
		} elsif ($type == 45) {
			$chars[$config{'char'}]{'def'} = $val;
			print "Defense: $val\n" if ($config{'debug'});
		} elsif ($type == 46) {
			$chars[$config{'char'}]{'def_bonus'} = $val;
			print "Defense Bonus: $val\n" if ($config{'debug'});
		} elsif ($type == 47) {
			$chars[$config{'char'}]{'def_magic'} = $val;
			print "Magic Defense: $val\n" if ($config{'debug'});
		} elsif ($type == 48) {
			$chars[$config{'char'}]{'def_magic_bonus'} = $val;
			print "Magic Defense Bonus: $val\n" if ($config{'debug'});
		} elsif ($type == 49) {
			$chars[$config{'char'}]{'hit'} = $val;
			print "Hit: $val\n" if ($config{'debug'});
		} elsif ($type == 50) {
			$chars[$config{'char'}]{'flee'} = $val;
			print "Flee: $val\n" if ($config{'debug'});
		} elsif ($type == 51) {
			$chars[$config{'char'}]{'flee_bonus'} = $val;
			print "Flee Bonus: $val\n" if ($config{'debug'});
		} elsif ($type == 52) {
			$chars[$config{'char'}]{'critical'} = $val;
			print "Critical: $val\n" if ($config{'debug'});
		} elsif ($type == 53) {
			$chars[$config{'char'}]{'attack_speed'} = 200 - $val/10;
			print "Attack Speed: $chars[$config{'char'}]{'attack_speed'}\n" if ($config{'debug'});
		} elsif ($type == 55) {
			$chars[$config{'char'}]{'lv_job'} = $val;
			print "Job Level: $val\n" if ($config{'debug'});
		} elsif ($type == 124) {
			print "Something3: $val\n" if ($config{'debug'});
		} else {
			print "[00B0]Something: $val\n" if ($config{'debug'});
		}
		$msg_size = 8;

	} elsif ($switch eq "00B1" && length($msg) >= 8) {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("L1",substr($msg, 4, 4));

		event_00B1($type, $val);

#		$monsterBaseExp = 0;
#		$monsterJobExp = 0;
#		if ($type == 1) {
#			$chars[$config{'char'}]{'exp_last'} = $chars[$config{'char'}]{'exp'};
#			$chars[$config{'char'}]{'exp'} = $val;
#			print "Exp: $val\n" if ($config{'debug'});
##Karasu Start
#			# EXPs gained per hour
#			if ($chars[$config{'char'}]{'exp_last'} > $chars[$config{'char'}]{'exp'} && $sc_v{'exp'}{'lv_up'}) {
#				$monsterBaseExp = $chars[$config{'char'}]{'exp_max_last'} - $chars[$config{'char'}]{'exp_last'} + $chars[$config{'char'}]{'exp'};
#				undef $sc_v{'exp'}{'lv_up'};
#			} elsif ($chars[$config{'char'}]{'exp_last'} < $chars[$config{'char'}]{'exp'}) {
#				$monsterBaseExp = $chars[$config{'char'}]{'exp'} - $chars[$config{'char'}]{'exp_last'};
#			}
#			print "～獲得經驗值 - $monsterBaseExp";
#			$totalBaseExp += $monsterBaseExp;
##Karasu End
#		} elsif ($type == 2) {
#			$chars[$config{'char'}]{'exp_job_last'} = $chars[$config{'char'}]{'exp_job'};
#			$chars[$config{'char'}]{'exp_job'} = $val;
#			print "Job Exp: $val\n" if ($config{'debug'});
##Karasu Start
#			# EXPs gained per hour
#			if ($chars[$config{'char'}]{'exp_job_last'} > $chars[$config{'char'}]{'exp_job'} && $sc_v{'exp'}{'lv_job_up'}) {
#				$monsterJobExp = $chars[$config{'char'}]{'exp_job_max_last'} - $chars[$config{'char'}]{'exp_job_last'} + $chars[$config{'char'}]{'exp_job'};
#				undef $sc_v{'exp'}{'lv_job_up'};
#			} elsif ($chars[$config{'char'}]{'exp_job_last'} < $chars[$config{'char'}]{'exp_job'}) {
#				$monsterJobExp = $chars[$config{'char'}]{'exp_job'} - $chars[$config{'char'}]{'exp_job_last'};
#			}
#			print "/$monsterJobExp～\n";
#			$totalJobExp += $monsterJobExp;
##Karasu End
#		} elsif ($type == 20) {
#			if ($shop{'opened'}) {
#				$shop{'earnedLast'} = $val - $chars[$config{'char'}]{'zenny'};
#			}
#			$chars[$config{'char'}]{'zenny'} = $val;
#			print "Zenny: $val\n" if ($config{'debug'});
#		} elsif ($type == 22) {
#			$chars[$config{'char'}]{'exp_max_last'} = $chars[$config{'char'}]{'exp_max'};
#			$chars[$config{'char'}]{'exp_max'} = $val;
#			print "Required Exp: $val\n" if ($config{'debug'});
#		} elsif ($type == 23) {
#			$chars[$config{'char'}]{'exp_job_max_last'} = $chars[$config{'char'}]{'exp_job_max'};
#			$chars[$config{'char'}]{'exp_job_max'} = $val;
#			print "Required Job Exp: $val\n" if ($config{'debug'});
#		}
		$msg_size = 8;

	} elsif ($switch eq "00B4" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$ID = substr($msg, 4, 4);
		($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;
		$talk{'ID'} = $ID;
		$talk{'nameID'} = unpack("L1", $ID);
		$talk =~ s/^\s+//;
		$talk =~ s/\^[0-9a-fA-F]{6}//g;
		$talk{'msg'} = $talk;
		print "$npcs{$ID}{'name'}: $talk{'msg'}\n";

	} elsif ($switch eq "00B5" && length($msg) >= 6) {
		$ID = substr($msg, 2, 4);
		print "$npcs{$ID}{'name'}: 請輸入 'talk cont' 繼續對話, 或輸入 'talk no' 取消對話\n";
		$msg_size = 6;

	} elsif ($switch eq "00B6" && length($msg) >= 6) {
		$ID = substr($msg, 2, 4);
		print "$npcs{$ID}{'name'}: 對話結束\n";
		sendTalkCancel(\$remote_socket, $ID) if (!$talk{'clientCancel'});
		undef %talk;
		$msg_size = 6;

	} elsif ($switch eq "00B7" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$ID = substr($msg, 4, 4);
		($talk) = substr($msg, 8, $msg_size - 8) =~ /([\s\S]*?)\000/;
		$talk{'ID'} = $ID;
		@preTalkResponses = split /:/, $talk;
		undef @{$talk{'responses'}};
		foreach (@preTalkResponses) {
			$_ =~ s/^\s+//;
			$_ =~ s/\^[0-9a-fA-F]{6}//g;
			push @{$talk{'responses'}}, $_ if $_ ne "";
		}
		parseInput("talk resp");

	} elsif ($switch eq "00BC" && length($msg) >= 6) {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("C1",substr($msg, 5, 1));
		if ($val == 207) {
			print "素質點數不足\n";
		} else {
			if ($type == 13) {
				$chars[$config{'char'}]{'str'} = $val;
				print "Strength: $val\n" if ($config{'debug'});
			} elsif ($type == 14) {
				$chars[$config{'char'}]{'agi'} = $val;
				print "Agility: $val\n" if ($config{'debug'});
			} elsif ($type == 15) {
				$chars[$config{'char'}]{'vit'} = $val;
				print "Vitality: $val\n" if ($config{'debug'});
			} elsif ($type == 16) {
				$chars[$config{'char'}]{'int'} = $val;
				print "Intelligence: $val\n" if ($config{'debug'});
			} elsif ($type == 17) {
				$chars[$config{'char'}]{'dex'} = $val;
				print "Dexterity: $val\n" if ($config{'debug'});
			} elsif ($type == 18) {
				$chars[$config{'char'}]{'luk'} = $val;
				print "Luck: $val\n" if ($config{'debug'});
			} else {
				print "[00BC]Something: $val\n" if ($config{'debug'});
			}
		}
		$msg_size = 6;


	} elsif ($switch eq "00BD" && length($msg) >= 44) {
		$chars[$config{'char'}]{'points_free'} = unpack("S1", substr($msg, 2, 2));
		$chars[$config{'char'}]{'str'} = unpack("C1", substr($msg, 4, 1));
		$chars[$config{'char'}]{'points_str'} = unpack("C1", substr($msg, 5, 1));
		$chars[$config{'char'}]{'agi'} = unpack("C1", substr($msg, 6, 1));
		$chars[$config{'char'}]{'points_agi'} = unpack("C1", substr($msg, 7, 1));
		$chars[$config{'char'}]{'vit'} = unpack("C1", substr($msg, 8, 1));
		$chars[$config{'char'}]{'points_vit'} = unpack("C1", substr($msg, 9, 1));
		$chars[$config{'char'}]{'int'} = unpack("C1", substr($msg, 10, 1));
		$chars[$config{'char'}]{'points_int'} = unpack("C1", substr($msg, 11, 1));
		$chars[$config{'char'}]{'dex'} = unpack("C1", substr($msg, 12, 1));
		$chars[$config{'char'}]{'points_dex'} = unpack("C1", substr($msg, 13, 1));
		$chars[$config{'char'}]{'luk'} = unpack("C1", substr($msg, 14, 1));
		$chars[$config{'char'}]{'points_luk'} = unpack("C1", substr($msg, 15, 1));
		$chars[$config{'char'}]{'attack'} = unpack("S1", substr($msg, 16, 2));
		$chars[$config{'char'}]{'attack_bonus'} = unpack("S1", substr($msg, 18, 2));
		$chars[$config{'char'}]{'attack_magic_min'} = unpack("S1", substr($msg, 20, 2));
		$chars[$config{'char'}]{'attack_magic_max'} = unpack("S1", substr($msg, 22, 2));
		$chars[$config{'char'}]{'def'} = unpack("S1", substr($msg, 24, 2));
		$chars[$config{'char'}]{'def_bonus'} = unpack("S1", substr($msg, 26, 2));
		$chars[$config{'char'}]{'def_magic'} = unpack("S1", substr($msg, 28, 2));
		$chars[$config{'char'}]{'def_magic_bonus'} = unpack("S1", substr($msg, 30, 2));
		$chars[$config{'char'}]{'hit'} = unpack("S1", substr($msg, 32, 2));
		$chars[$config{'char'}]{'flee'} = unpack("S1", substr($msg, 34, 2));
		$chars[$config{'char'}]{'flee_bonus'} = unpack("S1", substr($msg, 36, 2));
		$chars[$config{'char'}]{'critical'} = unpack("S1", substr($msg, 38, 2));
		print	"Strength: $chars[$config{'char'}]{'str'} #$chars[$config{'char'}]{'points_str'}\n"
			, "Agility: $chars[$config{'char'}]{'agi'} #$chars[$config{'char'}]{'points_agi'}\n"
			, "Vitality: $chars[$config{'char'}]{'vit'} #$chars[$config{'char'}]{'points_vit'}\n"
			, "Intelligence: $chars[$config{'char'}]{'int'} #$chars[$config{'char'}]{'points_int'}\n"
			, "Dexterity: $chars[$config{'char'}]{'dex'} #$chars[$config{'char'}]{'points_dex'}\n"
			, "Luck: $chars[$config{'char'}]{'luk'} #$chars[$config{'char'}]{'points_luk'}\n"
			, "Attack: $chars[$config{'char'}]{'attack'}\n"
			, "Attack Bonus: $chars[$config{'char'}]{'attack_bonus'}\n"
			, "Magic Attack Min: $chars[$config{'char'}]{'attack_magic_min'}\n"
			, "Magic Attack Max: $chars[$config{'char'}]{'attack_magic_max'}\n"
			, "Defense: $chars[$config{'char'}]{'def'}\n"
			, "Defense Bonus: $chars[$config{'char'}]{'def_bonus'}\n"
			, "Magic Defense: $chars[$config{'char'}]{'def_magic'}\n"
			, "Magic Defense Bonus: $chars[$config{'char'}]{'def_magic_bonus'}\n"
			, "Hit: $chars[$config{'char'}]{'hit'}\n"
			, "Flee: $chars[$config{'char'}]{'flee'}\n"
			, "Flee Bonus: $chars[$config{'char'}]{'flee_bonus'}\n"
			, "Critical: $chars[$config{'char'}]{'critical'}\n"
			, "Status Points: $chars[$config{'char'}]{'points_free'}\n"
			if ($config{'debug'});
		$msg_size = 44;

	} elsif ($switch eq "00BE" && length($msg) >= 5) {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("C1",substr($msg, 4, 1));
		if ($type == 32) {
			$chars[$config{'char'}]{'points_str'} = $val;
			print "Points needed for Strength: $val\n" if ($config{'debug'});
		} elsif ($type == 33) {
			$chars[$config{'char'}]{'points_agi'} = $val;
			print "Points needed for Agility: $val\n" if ($config{'debug'});
		} elsif ($type == 34) {
			$chars[$config{'char'}]{'points_vit'} = $val;
			print "Points needed for Vitality: $val\n" if ($config{'debug'});
		} elsif ($type == 35) {
			$chars[$config{'char'}]{'points_int'} = $val;
			print "Points needed for Intelligence: $val\n" if ($config{'debug'});
		} elsif ($type == 36) {
			$chars[$config{'char'}]{'points_dex'} = $val;
			print "Points needed for Dexterity: $val\n" if ($config{'debug'});
		} elsif ($type == 37) {
			$chars[$config{'char'}]{'points_luk'} = $val;
			print "Points needed for Luck: $val\n" if ($config{'debug'});
		}
		$msg_size = 5;

	} elsif ($switch eq "00C0" && length($msg) >= 7) {
		$ID = substr($msg, 2, 4);
		$type = unpack("C*", substr($msg, 6, 1));
		if ($ID eq $accountID && (!existsInList2($config{'hideMsg_emotion'}, 1, "and") || $config{'debug'})) {
			printC("[表情] 你作了個表情 : $emotions_lut{$type}\n", "e");
		} elsif (%{$players{$ID}} && (!existsInList2($config{'hideMsg_emotion'}, 4, "and") || $config{'debug'})) {
			printC("[表情] 玩家 $players{$ID}{'name'} ($players{$ID}{'binID'}) : $emotions_lut{$type}\n", "e");
		} elsif (%{$monsters{$ID}} && (!existsInList2($config{'hideMsg_emotion'}, 2, "and") || $config{'debug'})) {
			printC("[表情] 怪物 $monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) : $emotions_lut{$type}\n", "e");
		}
		$msg_size = 7;

	} elsif ($switch eq "00C2" && length($msg) >= 6) {
		$users = unpack("L*", substr($msg, 2, 4));
		print "目前有 $users 位玩家在線上\n";
		$msg_size = 6;

	} elsif ($switch eq "00C3" && length($msg) >= 8) {
		# Character outlook changed
		$msg_size = 8;

	} elsif ($switch eq "00C4" && length($msg) >= 6) {
		$ID = substr($msg, 2, 4);

		event_buyOrSell($switch, $ID);

#		undef %talk;
#		$talk{'buyOrSell'} = 1;
#		$talk{'ID'} = $ID;
#		print "$npcs{$talk{'ID'}}{'name'}: 你是要買東西(buy), 還是要賣(sell)東西呢？\n";
		$msg_size = 6;

	} elsif ($switch eq "00C6" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1",substr($msg,2,2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;


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

	} elsif ($switch eq "00C7" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		#sell list, similar to buy list
		$msg_size = unpack("S1",substr($msg,2,2));

		event_buyOrSell($switch, $msg);

#		if (length($msg) > 4) {
#			decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
#			$msg = substr($msg, 0, 4).$newmsg;
#
#			my ($pa, $pb, $idx, $ID);
#
#			for ($i=4; $i<=length($msg); $i++) {
#				$ID = unpack("S1", substr($msg, $i, 2));
#				$pa = unpack("S1", substr($msg, $i+2, 4));
#				$pb = unpack("S1", substr($msg, $i+6, 4));
#				print getName("items_lut", $ID)."\n";
#				print "$pa -> $pb\n";
#				$idx = $ID - 7;
##				print "$chars[$config{'char'}]{'inventory'}[$idx]{'index'} = $chars[$config{'char'}]{'inventory'}[$idx]{'name'}\n";
#
#				$sc_v{'sell'}{$chars[$config{'char'}]{'inventory'}[$idx]{'nameID'}}{'price'} = $pa;
#				$sc_v{'sell'}{$chars[$config{'char'}]{'inventory'}[$idx]{'nameID'}}{'price_new'} = $pb;
#
#				$i += 9;
#			}
#
#			writeDataFileIntact_sell();
#		}
#		undef $talk{'buyOrSell'};
#		print "$npcs{$talk{'ID'}}{'name'}: 請輸入 'sell <物品編號> [<數量>]' 賣出物品\n";

	} elsif ($switch eq "00CA" && length($msg) >= 3) {
		# Finished to buy from NPC
		$fail = unpack("C1", substr($msg, 2, 1));
		if (!$fail) {
			print "交易成功\\n" if ($config{'debug'});
		} elsif ($fail == 1) {
			print "金錢不足\n";
		} elsif ($fail == 2) {
			print "超過負重量\n";
		}
		$msg_size = 3;

	} elsif ($switch eq "00CB" && length($msg) >= 3) {
		# Finished to sell to NPC
		$msg_size = 3;

	} elsif ($switch eq "00D1" && length($msg) >= 4) {
		$type = unpack("C1", substr($msg, 2, 1));
		$error = unpack("C1", substr($msg, 3, 1));
		if ($type == 0) {
			print "已拒絕此位玩家密語\n";
		} elsif ($type == 1) {
			if ($error == 0) {
				print "接受此位玩家密語\n";
			}
		}
		$msg_size = 4;

	} elsif ($switch eq "00D2" && length($msg) >= 4) {
		$type = unpack("C1", substr($msg, 2, 1));
		$error = unpack("C1", substr($msg, 3, 1));
		if ($type == 0) {
			printC("◇拒絕所有密語\n", "s");
		} elsif ($type == 1) {
			if ($error == 0) {
				printC("◇接受所有密語\n", "s");
			}
		}
		$msg_size = 4;

	} elsif ($switch eq "00D3" && length($msg) >= 2) {
		$msg_size = 2;

	} elsif ($switch eq "00D6" && length($msg) >= 3) {
		$currentChatRoom = "new";
		%{$chatRooms{'new'}} = %createdChatRoom;
		binAdd(\@chatRoomsID, "new");
		binAdd(\@currentChatRoomUsers, $chars[$config{'char'}]{'name'});
		print "你開了一個聊天室\n";
		$msg_size = 3;

	} elsif ($switch eq "00D7" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1",substr($msg,2,2));
		decrypt(\$newmsg, substr($msg, 17, length($msg)-17));
		$msg = substr($msg, 0, 17).$newmsg;
		$ID = substr($msg,8,4);
		if (!%{$chatRooms{$ID}}) {
			binAdd(\@chatRoomsID, $ID);
		}
		$chatRooms{$ID}{'ownerID'} = substr($msg, 4, 4);
		$chatRooms{$ID}{'limit'} = unpack("S1",substr($msg, 12, 2));
		$chatRooms{$ID}{'num_users'} = unpack("S1",substr($msg, 14, 2));
		$chatRooms{$ID}{'public'} = unpack("C1",substr($msg,16,1));
		$chatRooms{$ID}{'title'} = substr($msg, 17, $msg_size - 17);
#Karasu Start
		# Record chat room titles
#		$chatLog_string = sprintf("%-62s", "$players{$chatRooms{$ID}{'ownerID'}}{'name'} : $chatRooms{$ID}{'title'}")
#							." $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): "
#							.getFormattedCoords($players{$chatRooms{$ID}{'ownerID'}}{'pos_to'}{'x'}, $players{$chatRooms{$ID}{'ownerID'}}{'pos_to'}{'y'});
#		chatLog("", $chatLog_string, "crt") if ($config{'recordChatRoom'} && %{$players{$chatRooms{$ID}{'ownerID'}}});

		if ($config{'recordChatRoom'} && %{$players{$chatRooms{$ID}{'ownerID'}}}) {
			$chatLog_string = sprintf("%-62s", "$players{$chatRooms{$ID}{'ownerID'}}{'name'} : $chatRooms{$ID}{'title'}")
					." $maps_lut{$field{'name'}.'.rsw'}($field{'name'}): "
					.getFormattedCoords($players{$chatRooms{$ID}{'ownerID'}}{'pos_to'}{'x'}, $players{$chatRooms{$ID}{'ownerID'}}{'pos_to'}{'y'});
			sysLog("crt", "", $chatLog_string);
		}

		# Avoid GM
		avoidGM($chatRooms{$ID}{'ownerID'}, $players{$chatRooms{$ID}{'ownerID'}}{'name'}, "在你附近開啟聊天室", 0);
#Karasu End

	} elsif ($switch eq "00D8" && length($msg) >= 6) {
		$ID = substr($msg,2,4);
		binRemove(\@chatRoomsID, $ID);
		undef %{$chatRooms{$ID}};
		$msg_size = 6;

	} elsif ($switch eq "00DA" && length($msg) >= 3) {
		$type = unpack("C1",substr($msg, 2, 1));
		if ($type == 0) {
			print "無法進入聊天室 - 人數超過上限\n";
		} elsif ($type == 1) {
			print "無法進入聊天室 - 密碼錯誤\n";
		} elsif ($type == 2) {
			print "無法進入聊天室 - 拒絕進入\n";
		}
		$msg_size = 3;

	} elsif ($switch eq "00DB" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1",substr($msg,2,2));
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$ID = substr($msg,4,4);
		$currentChatRoom = $ID;
		$chatRooms{$currentChatRoom}{'num_users'} = 0;
		for ($i = 8; $i < $msg_size; $i+=28) {
			$type = unpack("C1",substr($msg, $i,1));
			($chatUser) = substr($msg, $i + 4,24) =~ /([\s\S]*?)\000/;
			if ($chatRooms{$currentChatRoom}{'users'}{$chatUser} eq "") {
				binAdd(\@currentChatRoomUsers, $chatUser);
				if ($type == 0) {
					$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 2;
				} else {
					$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 1;
				}
				$chatRooms{$currentChatRoom}{'num_users'}++;
			}
		}
		print qq~進入聊天室 "$chatRooms{$currentChatRoom}{'title'}"\n~;

	} elsif ($switch eq "00DC" && length($msg) >= 28) {
		if ($currentChatRoom ne "") {
			$num_users = unpack("S1", substr($msg,2,2));
			($joinedUser) = substr($msg,4,24) =~ /([\s\S]*?)\000/;
			binAdd(\@currentChatRoomUsers, $joinedUser);
			$chatRooms{$currentChatRoom}{'users'}{$joinedUser} = 1;
			$chatRooms{$currentChatRoom}{'num_users'} = $num_users;
#			printC("<$joinedUser 進入聊天室>\n", "cr_in");
			# Beep on event
			playWave("sounds/Guest.wav") if ($config{'beep'} && $config{'beep_Guest'});
#			chatLog("聊天室", "<$joinedUser 進入聊天室>", "cr");
			sysLog("cr", "聊天室", "<$joinedUser 進入聊天室>", "cr_in");
		}
		$msg_size = 28;

	} elsif ($switch eq "00DD" && length($msg) >= 29) {
		$num_users = unpack("S1", substr($msg,2,2));
		($leaveUser) = substr($msg,4,24) =~ /([\s\S]*?)\000/;
		$chatRooms{$currentChatRoom}{'users'}{$leaveUser} = "";
		binRemove(\@currentChatRoomUsers, $leaveUser);
		$chatRooms{$currentChatRoom}{'num_users'} = $num_users;
		if ($leaveUser eq $chars[$config{'char'}]{'name'}) {
			binRemove(\@chatRoomsID, $currentChatRoom);
			undef %{$chatRooms{$currentChatRoom}};
			undef @currentChatRoomUsers;
			$currentChatRoom = "";
			print "你離開聊天室\n";
		} else {
#			printC("<$leaveUser 離開聊天室>\n", "cr_out");
#			chatLog("聊天室", "<$leaveUser 離開聊天室>", "cr");
			sysLog("cr", "聊天室", "<$leaveUser 離開聊天室>", "cr_out");
		}
		$msg_size = 29;

	} elsif ($switch eq "00DF" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg,2,2));
		decrypt(\$newmsg, substr($msg, 17, length($msg)-17));
		$msg = substr($msg, 0, 17).$newmsg;
		$ID = substr($msg,8,4);
		$ownerID = substr($msg,4,4);
		if ($ownerID eq $accountID) {
			$chatRooms{'new'}{'title'} = substr($msg,17, $msg_size - 17);
			$chatRooms{'new'}{'ownerID'} = $ownerID;
			$chatRooms{'new'}{'limit'} = unpack("S1",substr($msg,12,2));
			$chatRooms{'new'}{'public'} = unpack("C1",substr($msg,16,1));
			$chatRooms{'new'}{'num_users'} = unpack("S1",substr($msg,14,2));
		} else {
			$chatRooms{$ID}{'title'} = substr($msg,17, $msg_size - 17);
			$chatRooms{$ID}{'ownerID'} = $ownerID;
			$chatRooms{$ID}{'limit'} = unpack("S1",substr($msg,12,2));
			$chatRooms{$ID}{'public'} = unpack("C1",substr($msg,16,1));
			$chatRooms{$ID}{'num_users'} = unpack("S1",substr($msg,14,2));
		}
		printC("◇聊天室設定已更改\n", "s");

	} elsif ($switch eq "00E1" && length($msg) >= 30) {
		$type = unpack("C1", substr($msg, 2, 1));
		($chatUser) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		if ($type == 0) {
			if ($chatUser eq $chars[$config{'char'}]{'name'}) {
				$chatRooms{$currentChatRoom}{'ownerID'} = $accountID;
			} else {
				$key = findKeyString(\%players, "name", $chatUser);
				$chatRooms{$currentChatRoom}{'ownerID'} = $key;
			}
			$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 2;
		} else {
			$chatRooms{$currentChatRoom}{'users'}{$chatUser} = 1;
		}
		$msg_size = 30;

	} elsif ($switch eq "00E5" && length($msg) >= 26 || $switch eq "01F4" && length($msg) >= 32) {
		($dealUser) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		if ($switch eq "01F4") {
			$CID = substr($msg, 26, 4);
			$lv = unpack("S1", substr($msg, 30, 2));
		}
#		$incomingDeal{'name'} = $dealUser;
#		timeOutStart('ai_dealAuto');
#		print "($dealUser)詢問(先生／小姐)願不願意交易？\n";
#		print "請輸入 'deal' 接受交易, 或輸入 'deal no' 拒絕交易\n";
#		# Beep on event
#		playWave("sounds/Deal.wav") if ($config{'beep'} && $config{'beep_Deal'});
#
		event_deal($switch, $dealUser, $CID, $lv);

		$msg_size = ($switch eq "00E5") ? 26 : 32;

	} elsif ($switch eq "00E7" && length($msg) >= 3 || $switch eq "01F5" && length($msg) >= 9) {
		$type = unpack("C1", substr($msg, 2, 1));
		if ($switch eq "01F5") {
			$CID = substr($msg, 3, 4);
			$lv = unpack("S1", substr($msg, 7, 2));
		}
#		if ($type == 0) {
#			print "超過可交易的距離\n";
#		} elsif ($type == 1) {
#			print "沒有您所指定的人物\n";
#		} elsif ($type == 2) {
#			print "此人物與其他人物正在交易中\n";
#		} elsif ($type == 3) {
#			if (%incomingDeal) {
#				$currentDeal{'name'} = $incomingDeal{'name'};
#			} else {
#				$currentDeal{'name'} = $players{$outgoingDeal{'ID'}}{'name'};
#			}
#			parseInput("dl");
#		}
#		undef %outgoingDeal;
#		undef %incomingDeal;

		event_deal($switch, $type, $CID, $lv);

		$msg_size = ($switch eq "00E7") ? 3 : 9;

	} elsif ($switch eq "00E9" && length($msg) >= 19) {
		$amount = unpack("L*", substr($msg, 2,4));
		$ID = unpack("S*", substr($msg, 6,2));
		if ($ID > 0) {
			$currentDeal{'other'}{$ID}{'amount'}     += $amount;
			$currentDeal{'other'}{$ID}{'identified'} = unpack("C1",substr($msg, 8, 1));
			$currentDeal{'other'}{$ID}{'type_equip'} = $itemSlots_lut{$ID};
			if ($currentDeal{'other'}{$ID}{'type_equip'} == 1024) {
				$currentDeal{'other'}{$ID}{'borned'} = unpack("C1", substr($msg, 9, 1));
				$currentDeal{'other'}{$ID}{'named'} = unpack("C1", substr($msg, 17, 1));
			} elsif ($currentDeal{'other'}{$ID}{'type_equip'}) {
				$currentDeal{'other'}{$ID}{'broken'}       = unpack("C1", substr($msg, 9, 1));
				$currentDeal{'other'}{$ID}{'refined'}      = unpack("C1", substr($msg, 10, 1));
				if (unpack("S1", substr($msg, 11, 2)) == 0x00FF) {
					$currentDeal{'other'}{$ID}{'attribute'} = unpack("C1", substr($msg, 13, 1));
					$currentDeal{'other'}{$ID}{'star'}      = unpack("C1", substr($msg, 14, 1)) / 0x05;
					$currentDeal{'other'}{$ID}{'maker_charID'} = substr($msg, 15, 4);
					if (!$charID_lut{$currentDeal{'other'}{$ID}{'maker_charID'}}) {
						sendGetPlayerInfoByCharID(\$remote_socket, $currentDeal{'other'}{$ID}{'maker_charID'});
					}
				} else {
					$currentDeal{'other'}{$ID}{'card'}[0]   = unpack("S1", substr($msg, 11, 2));
					$currentDeal{'other'}{$ID}{'card'}[1]   = unpack("S1", substr($msg, 13, 2));
					$currentDeal{'other'}{$ID}{'card'}[2]   = unpack("S1", substr($msg, 15, 2));
					$currentDeal{'other'}{$ID}{'card'}[3]   = unpack("S1", substr($msg, 17, 2));
				}
			}
			$display = ($items_lut{$ID} ne "")
					? $items_lut{$ID}
					: "不明物品 ".$ID;
			$currentDeal{'other'}{$ID}{'name'} = $display;
			modifyName(\%{$currentDeal{'other'}{$ID}});

			$display = $currentDeal{'other'}{$ID}{'name'};
			if ($currentDeal{'other'}{$ID}{'maker_charID'}) {
				$display .= " -- 由 $charID_lut{$currentDeal{'other'}{$ID}{'maker_charID'}} 製作";
			}
			if (!$currentDeal{'other'}{$ID}{'identified'}) {
				$display .= " -- 未鑑定";
			}
			if ($currentDeal{'other'}{$ID}{'named'}) {
				$display .= " -- 已命名";
			}
			if ($currentDeal{'other'}{$ID}{'broken'}) {
				$display .= " -- 已損壞";
			}
			print "$currentDeal{'name'} 放了 $display x $amount 到交易欄\n";
			parseInput("dl");

		} elsif ($amount > 0) {
			$currentDeal{'other_zenny'} += $amount;
			print "$currentDeal{'name'} 放了 ".toZeny($amount)." z 到交易欄\n";
			parseInput("dl");
		}

		$msg_size = 19;

	} elsif ($switch eq "00EA" && length($msg) >= 5) {
		$index = unpack("S1", substr($msg, 2, 2));
		$fail = unpack("C1", substr($msg, 4, 1));
		if (!$fail) {
			undef $invIndex;
			if ($index > 0) {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
				$currentDeal{'you'}{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}{'amount'} += $currentDeal{'lastItemAmount'};
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $currentDeal{'lastItemAmount'};
				$currentDeal{'you'}{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}{'name'} = $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'};
#				$display = $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'};
#				if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'maker_charID'}) {
#					$display .= " -- 由 $charID_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'maker_charID'}} 製作";
#				}
#				if (!$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'}) {
#					$display .= " -- 未鑑定";
#				}
#				if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'named'}) {
#					$display .= " -- 已命名";
#				}
#				if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'broken'}) {
#					$display .= " -- 已損壞";
#				}
				$display = fixingName(\%{$chars[$config{'char'}]{'inventory'}[$invIndex]});
				print "你放了 $display x $currentDeal{'lastItemAmount'} 到交易欄\n";
				$currentDeal{'totalItems'} += 1;
				parseInput("dl");
				if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
					undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
				}
			} elsif ($currentDeal{'you_zenny'} > 0) {
				$chars[$config{'char'}]{'zenny'} -= $currentDeal{'you_zenny'};
			}
		} elsif ($fail == 1) {
			printC("對方人物超過最大負重量, 無法拿取\n", "alert");
		}
		$msg_size = 5;

	} elsif ($switch eq "00EC" && length($msg) >= 3) {
		$type = unpack("C1", substr($msg, 2, 1));
#		if ($type == 1) {
#			$currentDeal{'other_finalize'} = 1;
#			print "$currentDeal{'name'} 確認此次交易\n";
#			parseInput("dl");
#		} else {
#			$currentDeal{'you_finalize'} = 1;
#			print "你確認此次交易\n";
#			parseInput("dl");
#		}

		event_deal($switch, $type);

		$msg_size = 3;

	} elsif ($switch eq "00EE" && length($msg) >= 2) {
#		undef %incomingDeal;
#		undef %outgoingDeal;
#		undef %currentDeal;
#		printC("交易取消\n", "alert");

		event_deal($switch);

		$msg_size = 2;

	} elsif ($switch eq "00F0" && length($msg) >= 3) {
#		print "交易物品成功\\n";
#		undef %currentDeal;

		event_deal($switch);

		$msg_size = 3;

	} elsif ($switch eq "00F2" && length($msg) >= 6) {
		$storage{'items'} = unpack("S1", substr($msg, 2, 2));
		$storage{'items_max'} = unpack("S1", substr($msg, 4, 2));
		$msg_size = 6;

	} elsif ($switch eq "00F4" && length($msg) >= 21 || $switch eq "01C4" && length($msg) >= 22) {
		$index  = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$ID     = unpack("S1", substr($msg, 8, 2));
		$psize = ($switch eq "00F4") ? 0 : 1;
		if (%{$storage{'inventory'}[$index]}) {
			$storage{'inventory'}[$index]{'amount'}     += $amount;
		} else {
			$storage{'inventory'}[$index]{'nameID'}     = $ID;
			$storage{'inventory'}[$index]{'amount'}     = $amount;
			$storage{'inventory'}[$index]{'type'} = unpack("C1", substr($msg, 10, 1)) if ($switch eq "01C4");
			$storage{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, 10 + $psize, 1));
			$storage{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
			if ($storage{'inventory'}[$index]{'type_equip'} == 1024) {
				$storage{'inventory'}[$index]{'borned'} = unpack("C1", substr($msg, 11 + $psize, 1));
				$storage{'inventory'}[$index]{'named'} = unpack("C1", substr($msg, 19 + $psize, 1));
			} elsif ($storage{'inventory'}[$index]{'type_equip'}) {
				$storage{'inventory'}[$index]{'broken'}       = unpack("C1", substr($msg, 11 + $psize, 1));
				$storage{'inventory'}[$index]{'refined'}      = unpack("C1", substr($msg, 12 + $psize, 1));
				if (unpack("S1", substr($msg, 13 + $psize, 2)) == 0x00FF) {
					$storage{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, 15 + $psize, 1));
					$storage{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, 16 + $psize, 1)) / 0x05;
					$storage{'inventory'}[$index]{'maker_charID'} = substr($msg, 17 + $psize, 4);
					if (!$charID_lut{$storage{'inventory'}[$index]{'maker_charID'}}) {
						sendGetPlayerInfoByCharID(\$remote_socket, $storage{'inventory'}[$index]{'maker_charID'});
					}
				} else {
					$storage{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, 13 + $psize, 2));
					$storage{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, 15 + $psize, 2));
					$storage{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, 17 + $psize, 2));
					$storage{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, 19 + $psize, 2));
				}
			}
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "不明物品 ".$ID;
			$storage{'inventory'}[$index]{'name'} = $display;
			modifyName(\%{$storage{'inventory'}[$index]});
		}
		print "你將 $storage{'inventory'}[$index]{'name'} ($index) x $amount 存入倉庫\n";
		$msg_size = ($switch eq "00F4") ? 21 : 22;

	} elsif ($switch eq "00F6" && length($msg) >= 8) {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$storage{'inventory'}[$index]{'amount'} -= $amount;
		print "你從倉庫取出 $storage{'inventory'}[$index]{'name'} ($index) x $amount\n";
		if ($storage{'inventory'}[$index]{'amount'} <= 0) {
			undef %{$storage{'inventory'}[$index]};
		}
		$msg_size = 8;

	} elsif ($switch eq "00F8" && length($msg) >= 2) {
		print "倉庫已關閉\n";

		$msg_size = 2;

	} elsif ($switch eq "00FA" && length($msg) >= 3) {
		$type = unpack("C1", substr($msg, 2, 1));
#		if ($type == 1) {
#			print "無法組織隊伍 - 隊伍名稱已有人使用\n";
#		} elsif ($type == 2) {
#			print "無法組織隊伍 - 你已經有隊伍了\n";
#		}

		print getMsgStrings($switch, $type, 0, 1)."\n";

		$msg_size = 3;

	} elsif ($switch eq "00FB" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 28, length($msg)-28));
		$msg = substr($msg, 0, 28).$newmsg;
		($chars[$config{'char'}]{'party'}{'name'}) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		for ($i = 28; $i < $msg_size;$i+=46) {
			$ID = substr($msg, $i, 4);
			if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
				binAdd(\@partyUsersID, $ID);
			}
			($chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'}) = substr($msg, $i + 4, 24) =~ /([\s\S]*?)\000/;
			($chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'}) = substr($msg, $i + 28, 16) =~ /([\s\S]*?)\000/;
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = !(unpack("C1",substr($msg, $i + 45, 1)));
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'admin'} = !(unpack("C1",substr($msg, $i + 44, 1)));
		}
		if ($config{'partyAutoShare'} && %{$chars[$config{'char'}]{'party'}}) {
#			sendPartyShareEXP(\$remote_socket, 1);
			timeOutStart(-1, 'ai_partyAutoShare');
		}

	} elsif ($switch eq "00FD" && length($msg) >= 27) {
		($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		$type = unpack("C1", substr($msg, 26, 1));
		if ($type == 0) {
			print "邀請加入隊伍失敗 - $name 已加入別的隊伍\n";
		} elsif ($type == 1) {
			print "邀請加入隊伍失敗 - $name 拒絕你的邀請\n";
#		#} elsif ($type == 2) {
#		#	print "$name 接受你的邀請\n";
#		} elsif ($type == 4) {
#			print "邀請加入隊伍失敗 - 隊伍裡已經有相同帳號的角色\n";
		} else {
			print getMsgStrings($switch, $type, 0, 1)."\n";
		}
		$msg_size = 27;

	} elsif ($switch eq "00FE" && length($msg) >= 30) {
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		print "[$name] 邀請你加入隊伍\n";
		$incomingParty{'ID'} = $ID;
		timeOutStart('ai_partyAuto');
		$msg_size = 30;

	} elsif ($switch eq "0100" && length($msg) >= 2) {
		$msg_size = 2;

	} elsif ($switch eq "0101" && length($msg) >= 6) {
		$type = unpack("C1", substr($msg, 2, 1));
		if ($type == 0) {
			printC("◇經驗值分配方式: 各自取得\n", "s");
			$chars[$config{'char'}]{'party'}{'share'} = 0;
		} elsif ($type == 1) {
			printC("◇經驗值分配方式: 均等分配\n", "s");
			$chars[$config{'char'}]{'party'}{'share'} = 1;
		} else {
			printC("◇無法更改經驗值分配方式\n", "s");
		}

		$msg_size = 6;

	} elsif ($switch eq "0104" && length($msg) >= 79) {
		$ID = substr($msg, 2, 4);
		$x = unpack("S1", substr($msg,10, 2));
		$y = unpack("S1", substr($msg,12, 2));
		$type = unpack("C1",substr($msg, 14, 1));
		($name) = substr($msg, 15, 24) =~ /([\s\S]*?)\000/;
		($partyUser) = substr($msg, 39, 24) =~ /([\s\S]*?)\000/;
		($map) = substr($msg, 63, 16) =~ /([\s\S]*?)\000/;
		if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
			binAdd(\@partyUsersID, $ID);
			if ($ID eq $accountID) {
				print "你加入隊伍 [$name]\n";
				# Party is created by self
				if ($createPartyBySelf) {
					$chars[$config{'char'}]{'party'}{'users'}{$ID}{'admin'} = 1 ;
					undef $createPartyBySelf;

					timeOutStart(-1, 'ai_partyAutoShare');
				}
			} else {
				print "$partyUser 加入你的隊伍 [$name]\n";
			}
		}
		if ($type == 0) {
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
		} elsif ($type == 1) {
			$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 0;
		}
		$chars[$config{'char'}]{'party'}{'name'} = $name;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = $x;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = $y;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'map'} = $map;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} = $partyUser;
		$msg_size = 79;

	} elsif ($switch eq "0105" && length($msg) >= 31) {
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		undef %{$chars[$config{'char'}]{'party'}{'users'}{$ID}};
		binRemove(\@partyUsersID, $ID);
		if ($ID eq $accountID) {
#			print "你離開隊伍\n";
			sysLog("event", "隊伍", "你離開隊伍", 1);
			undef %{$chars[$config{'char'}]{'party'}};
			$chars[$config{'char'}]{'party'} = "";
			undef @partyUsersID;
		} elsif ($chars[$config{'char'}]{'party'}{'users'}{$accountID}{'admin'}) {
#			print "$name 離開隊伍\n";
			sysLog("event", "隊伍", "$name 離開隊伍，自動嘗試均等分配。", 1);
			timeOutStart(-1, 'ai_partyAutoShare');
		}
		$msg_size = 31;

	} elsif ($switch eq "0106" && length($msg) >= 10) {
		$ID = substr($msg, 2, 4);
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp'} = unpack("S1", substr($msg, 6, 2));
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'hp_max'} = unpack("S1", substr($msg, 8, 2));
		$msg_size = 10;

	} elsif ($switch eq "0107" && length($msg) >= 10) {
		$ID = substr($msg, 2, 4);
		$x = unpack("S1", substr($msg,6, 2));
		$y = unpack("S1", substr($msg,8, 2));
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'x'} = $x;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'pos'}{'y'} = $y;
		$chars[$config{'char'}]{'party'}{'users'}{$ID}{'online'} = 1;
		print "Party member location: $chars[$config{'char'}]{'party'}{'users'}{$ID}{'name'} - $x, $y\n" if ($config{'debug'} >= 2);
		$msg_size = 10;

	} elsif ($switch eq "0109" && length($msg) >= 4 && length($msg) >= unpack("S*", substr($msg, 2, 2))) {
		$msg_size = unpack("S*", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$chat = substr($msg, 8, $msg_size - 8);
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;

		event_chat("p", $chatMsgUser, $chatMsg);

#		chatLog("隊伍", "$chatMsgUser : $chatMsg", "p");
#		$ai_cmdQue[$ai_cmdQue]{'type'} = "p";
#		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
#		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
#		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
#		$ai_cmdQue++;
#		printC("[隊伍] $chatMsgUser : $chatMsg\n", "p");
#
#		# Beep on Event
#		playWave("sounds/P.wav") if ($config{'beep'} && $config{'beep_P'});
#		# Avoig GM
#		avoidGM("", $chatMsgUser, "在隊伍頻道發言", 0);

	} elsif ($switch eq "010A" && length($msg) >= 4) {
  		$ID = unpack("S1", substr($msg, 2, 2));
#  		printC("你成為ＭＶＰ！！取得MVP物品: $items_lut{$ID}\n", "s");
#  		chatLog("重要", "你成為ＭＶＰ！！取得MVP物品: $items_lut{$ID}", "im");
#
#  		sysLog("mvp", "MVP", "你成為ＭＶＰ！！取得MVP物品: $items_lut{$ID}", 1);

  		event_mvp_get($switch, $ID);

  		$msg_size = 4;

  	} elsif ($switch eq "010B" && length($msg) >= 6) {
		$val = unpack("L1",substr($msg, 2, 4));
#		printC("你成為ＭＶＰ！！獲得特殊經驗值: $val\n", "s");
#		chatLog("重要", "你成為ＭＶＰ！！獲得特殊經驗值: $val", "im");

#		sysLog("mvp", "MVP", "你成為ＭＶＰ！！獲得特殊經驗值: $val", 1);

		event_mvp_get($switch, $val);

		$msg_size = 6;

  	} elsif ($switch eq "010C" && length($msg) >= 6) {
		$ID = substr($msg, 2, 4);
#		if ($ID eq $accountID) {
#			$display = "你";
#		} elsif (%{$players{$ID}}) {
#			$display = "$players{$ID}{'name'} ($players{$ID}{'binID'}) [".unpack("L1", $ID)."]";
#		} else {
#			$display = "不明人物[".unpack("L1", $ID)."]";
#
##			sendGetPlayerInfo(\$remote_socket, $ID);
#		}
##		printC("$display成為ＭＶＰ！！\n", "s");
##		chatLog("重要", "$display 成為ＭＶＰ！！", "im");
#
#		sysLog("mvp", "MVP", "$display 成為ＭＶＰ！！", 1);

		event_mvp_get($switch, $ID);

		$msg_size = 6;

	} elsif ($switch eq "010E" && length($msg) >= 11) {
		$ID = unpack("S1",substr($msg, 2, 2));
		$lv = unpack("S1",substr($msg, 4, 2));
		$chars[$config{'char'}]{'skills'}{$skills_rlut{lc($skillsID_lut{$ID})}}{'lv'} = $lv;
		print "Skill $skillsID_lut{$ID}: $lv\n" if ($config{'debug'});
		$msg_size = 11;

	} elsif ($switch eq "010F" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$sc_v{'input'}{'conState'} = 5 if ($sc_v{'input'}{'conState'} != 4 && $option{'X-Kore'});

		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		# Reset all skills - by Ayon
		# I also change $chars[$config{'char'}]{'skills'}{'XXX'}{'time_used'} to $chars[$config{'char'}]{'skills_used'}{'XXX'}{'time_used'}
		undef %{$chars[$config{'char'}]{'skills'}};
		undef @skillsID;
		for($i = 4;$i < $msg_size;$i+=37) {
			$ID = unpack("S1", substr($msg, $i, 2));
			($name) = substr($msg, $i + 12, 24) =~ /([\s\S]*?)\000/;
			if (!$name) {
				$name = $skills_rlut{lc($skillsID_lut{$ID})};
			}
			$chars[$config{'char'}]{'skills'}{$name}{'ID'} = $ID;
			if (!$chars[$config{'char'}]{'skills'}{$name}{'lv'}) {
				$chars[$config{'char'}]{'skills'}{$name}{'lv'} = unpack("S1", substr($msg, $i + 6, 2));
			}
			$skillsID_lut{$ID} = $skills_lut{$name};
			binAdd(\@skillsID, $name);
		}

	} elsif ($switch eq "0110" && length($msg) >= 10) {
#Karasu Start
		# Skill using failed
		$skillID = unpack("S1", substr($msg, 2, 2));
		$basicType = unpack("S1", substr($msg, 4, 2));
		$fail = unpack("C1", substr($msg, 8, 1));
		$type = unpack("C1", substr($msg, 9, 1));
		if (!$fail) {
			aiRemove("skill_use");
			printC("★$messages_lut{'0110'}{$type}: $skillsID_lut{$skillID}\n", "alert") if (!$config{'hideMsg_skillFail'} || $config{'debug'});
		}
#Karasu End
		$msg_size = 10;

	} elsif ($switch eq "0111" && length($msg) >= 39) {
		$msg_size = 39;

	} elsif ($switch eq "0114" && length($msg) >= 31 || $switch eq "01DE" && length($msg) >= 33) {
		$skillID = unpack("S1", substr($msg, 2, 2));
		$sourceID = substr($msg, 4, 4);
		$targetID = substr($msg, 8, 4);
		# damage fix
		if ($switch eq "0114") {
			$damage = unpack("s1", substr($msg, 24, 2));
#			$miss = ($damage == -30000) ? 1 : 0;
			$level = unpack("S1", substr($msg, 26, 2));
		} else {
			$damage = unpack("l1", substr($msg, 24, 4));
#			$miss = ($damage == -30000) ? 1 : 0;
			$level = unpack("S1", substr($msg, 28, 2));
		}

		parseSkill($switch, $skillID, $sourceID, $targetID, $damage, $level);

#		undef $sourceDisplay;
#		undef $targetDisplay;
#		if (%{$spells{$sourceID}}) {
#			$sourceID = $spells{$sourceID}{'sourceID'};
#		}

#		updateDamageTables($sourceID, $targetID, $damage) if (!$miss);
#		parseSteal($sourceID, $targetID, $skillID);
#
#		if (%{$monsters{$sourceID}}) {
#			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) ";
#		} elsif (%{$players{$sourceID}}) {
#			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) ";
#		} elsif ($sourceID eq $accountID) {
#			$sourceDisplay = "你";
#			$chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
#			undef $chars[$config{'char'}]{'time_cast'};
#			undef $ai_v{'temp'}{'castWait'};
#		} else {
#			$sourceDisplay = "不明人物 ";
#		}
#
#		if (%{$monsters{$targetID}}) {
#			if ($sourceID ne $targetID) {
#				$targetDisplay = " $monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'}) ";
#				if ($sourceID eq $accountID) {
#					$monsters{$targetID}{'castOnByYou'}++;
#				} elsif (%{$players{$sourceID}}) {
#					$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
#				}
#			} else {
#				$targetDisplay = "他自己";
#			}
#		} elsif (%{$players{$targetID}}) {
#			if ($sourceID ne $targetID) {
#				$targetDisplay = " $players{$targetID}{'name'} ($players{$targetID}{'binID'}) ";
#			} else {
#				$targetDisplay = "他自己";
#			}
#		} elsif ($targetID eq $accountID) {
#			if ($sourceID eq $accountID) {
#				$targetDisplay = "自己";
#			} else {
#				$targetDisplay = "你";
#			}
#		} else {
#			$targetDisplay = " 不明目標 ";
#		}
#		if (!$miss) {
#			if ($level_real ne "") {
#				$level = $level_real;
#			}
#			$levelDisplay = ($level == 65535) ? "" : "(Lv $level) ";
#			if ($targetID eq $accountID) {
#				# Show HP
#				undef $showHP{'hp_now'};
#				undef $showHP{'hppercent_now'};
#				$showHP{'hp_now'} = int($chars[$config{'char'}]{'hp'} - $damage);
#				if ($chars[$config{'char'}]{'hp_max'}) {
#					$showHP{'hppercent_now'} = $showHP{'hp_now'} / $chars[$config{'char'}]{'hp_max'} * 100;
#					$showHP{'hppercent_now'} = ($showHP{'hppercent_now'} > 1) ? int($showHP{'hppercent_now'}) : 1;
#					if ($showHP{'hp_now'} <= 0) {
#						$showHP{'hppercent_now'} = 0;
#						$showHP{'killedBy'}{'who'} = $sourceDisplay;
#						$showHP{'killedBy'}{'how'} = "$skillsID_lut{$skillID} $levelDisplay";
#						$showHP{'killedBy'}{'dmg'} = $damage;
#					}
#				}
#				if  ($damage != 0) {
#					printS("★$sourceDisplay的 $skillsID_lut{$skillID} $levelDisplay對$targetDisplay造成傷害: $damage★($showHP{'hppercent_now'}%)\n", "alert", $sourceID, $targetID);
#				} else {
#					printS("★$sourceDisplay的 $skillsID_lut{$skillID} $levelDisplay對$targetDisplay造成傷害: $damage★($showHP{'hppercent_now'}%)\n", "", $sourceID, $targetID);
#				}
#			} else {
#				if ($sourceID eq $accountID && %{$monsters{$targetID}}) {
#					$damageTotalDisplay = (!$config{'hideMsg_attackDmgFromYou'} || $config{'debug'}) ? "(Total: $monsters{$targetID}{'dmgFromYou'})" : "";
#					printS("★$sourceDisplay的 $skillsID_lut{$skillID} $levelDisplay對$targetDisplay造成傷害: $damage $damageTotalDisplay\n", "", $sourceID, $targetID);
#				} else {
#					printS("★$sourceDisplay的 $skillsID_lut{$skillID} $levelDisplay對$targetDisplay造成傷害: $damage\n", "", $sourceID, $targetID);
#				}
#			}
#		} else {
#			$level_real = $level;
#			$levelDisplay = ($level == 65535) ? "" : "(Lv $level) ";
#			printS("★$sourceDisplay施展 $skillsID_lut{$skillID} $levelDisplay\n", "", $sourceID);
#		}
		$msg_size = ($switch eq "0114") ? 31 : 33;

	} elsif ($switch eq "0115" && length($msg) >= 35) {
		$skillID = unpack("S1",substr($msg, 2, 2));
		$sourceID = substr($msg, 4, 4);
		$targetID = substr($msg, 8, 4);
		$coords{'x'} = unpack("S1",substr($msg, 24, 2));
		$coords{'y'} = unpack("S1",substr($msg, 26, 2));
		# use s1 to unpack instead S1
		$damage = unpack("s1",substr($msg, 28, 2));
#		$miss = ($damage == 0x8AD0) ? 1 : 0;
		$level = unpack("S1",substr($msg, 30, 2));

		parseSkill($switch, $skillID, $sourceID, $targetID, $damage, $level, $coords{'x'}, $coords{'y'});

#		undef $sourceDisplay;
#		undef $targetDisplay;
#		if (%{$spells{$sourceID}}) {
#			$sourceID = $spells{$sourceID}{'sourceID'}
#		}
#
#		updateDamageTables($sourceID, $targetID, $damage) if (!$miss);
#		parseSteal($sourceID, $targetID, $skillID);
#
#		if (%{$monsters{$sourceID}}) {
#			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) ";
#		} elsif (%{$players{$sourceID}}) {
#			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) ";
#		} elsif ($sourceID eq $accountID) {
#			$sourceDisplay = "你";
#			$chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
#			undef $chars[$config{'char'}]{'time_cast'};
#			undef $ai_v{'temp'}{'castWait'};
#		} else {
#			$sourceDisplay = "不明人物 ";
#		}
#
#		if (%{$monsters{$targetID}}) {
#			if ($sourceID ne $targetID) {
#				$targetDisplay = " $monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'}) ";
#				if ($sourceID eq $accountID) {
#					$monsters{$targetID}{'castOnByYou'}++;
#				} elsif (%{$players{$sourceID}}) {
#					$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
#				}
#			} else {
#				$targetDisplay = "他自己";
#			}
#			%{$monsters{$ID}{'pos'}} = %coords;
#			%{$monsters{$ID}{'pos_to'}} = %coords;
#		} elsif (%{$players{$targetID}}) {
#			if ($sourceID ne $targetID) {
#				$targetDisplay = " $players{$targetID}{'name'} ($players{$targetID}{'binID'}) ";
#			} else {
#				$targetDisplay = "他自己";
#			}
#			%{$players{$ID}{'pos'}} = %coords;
#			%{$players{$ID}{'pos_to'}} = %coords;
#		} elsif ($targetID eq $accountID) {
#			if ($sourceID eq $accountID) {
#				$targetDisplay = "自己";
#			} else {
#				$targetDisplay = "你";
#			}
#			%{$chars[$config{'char'}]{'pos'}} = %coords;
#			%{$chars[$config{'char'}]{'pos_to'}} = %coords;
#		} else {
#			$targetDisplay = " 不明目標 ";
#		}
#		if (!$miss) {
#			if ($level_real ne "") {
#				$level = $level_real;
#			}
#			$levelDisplay = ($level == 65535) ? "" : "(Lv $level) ";
#			if ($targetID eq $accountID) {
#				# Show HP
#				undef $showHP{'hp_now'};
#				undef $showHP{'hppercent_now'};
#				$showHP{'hp_now'} = int($chars[$config{'char'}]{'hp'} - $damage);
#				if ($chars[$config{'char'}]{'hp_max'}) {
#					$showHP{'hppercent_now'} = $showHP{'hp_now'} / $chars[$config{'char'}]{'hp_max'} * 100;
#					$showHP{'hppercent_now'} = ($showHP{'hppercent_now'} > 1) ? int($showHP{'hppercent_now'}) : 1;
#					if ($showHP{'hp_now'} <= 0) {
#						$showHP{'hppercent_now'} = 0;
#						$showHP{'killedBy'}{'who'} = $sourceDisplay;
#						$showHP{'killedBy'}{'how'} = "$skillsID_lut{$skillID} $levelDisplay";
#						$showHP{'killedBy'}{'dmg'} = $damage;
#					}
#				}
#				if  ($damage != 0) {
#					printS("★$sourceDisplay的 $skillsID_lut{$skillID} $levelDisplay對$targetDisplay造成傷害: $damage★($showHP{'hppercent_now'}%)\n", "alert", $sourceID, $targetID);
#				} else {
#					printS("★$sourceDisplay的 $skillsID_lut{$skillID} $levelDisplay對$targetDisplay造成傷害: $damage★($showHP{'hppercent_now'}%)\n", "", $sourceID, $targetID);
#				}
#			} else {
#				if ($sourceID eq $accountID && %{$monsters{$targetID}}) {
#					$damageTotalDisplay = (!$config{'hideMsg_attackDmgFromYou'} || $config{'debug'}) ? "(Total: $monsters{$targetID}{'dmgFromYou'})" : "";
#					printS("★$sourceDisplay的 $skillsID_lut{$skillID} $levelDisplay對$targetDisplay造成傷害: $damage $damageTotalDisplay\n", "", $sourceID, $targetID);
#				} else {
#					printS("★$sourceDisplay的 $skillsID_lut{$skillID} $levelDisplay對$targetDisplay造成傷害: $damage\n", "", $sourceID, $targetID);
#				}
#			}
#		} else {
#			$level_real = $level;
#			$levelDisplay = ($level == 65535) ? "" : "(Lv $level) ";
#			printS("★$sourceDisplay施展 $skillsID_lut{$skillID} $levelDisplay\n", "", $sourceID);
#		}
		$msg_size = 35;

	} elsif ($switch eq "0117" && length($msg) >= 18) {
		$skillID = unpack("S1", substr($msg, 2, 2));
		$sourceID = substr($msg, 4, 4);
		$level = unpack("S1", substr($msg, 8, 2));
		$coords{'x'} = unpack("S1", substr($msg, 10, 2));
		$coords{'y'} = unpack("S1", substr($msg, 12, 2));

		parseSkill($switch, $skillID, $sourceID, "floor", "(".unpack("S1", substr($msg, 14, 2)).", ".unpack("S1", substr($msg, 16, 2)).")", $level, $coords{'x'}, $coords{'y'});
#
#		undef $sourceDisplay;
#		undef $s_cDist;
#		undef $castBy;
#		undef $castOn;
#
#		parseSteal($sourceID, $targetID, $skillID);
#
#		if (%{$monsters{$sourceID}}) {
#			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) ";
#			$castBy = 2;
#		} elsif (%{$players{$sourceID}}) {
#			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) ";
#			$castBy = 4;
#		} elsif ($sourceID eq $accountID) {
#			$sourceDisplay = "你";
#			$chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
#			undef $chars[$config{'char'}]{'time_cast'};
#			undef $ai_v{'temp'}{'castWait'};
#			$castBy = 1;
#		} else {
#			$sourceDisplay = "不明人物 ";
#			$castBy = 8;
#		}
#		$targetDisplay = "座標: ".getFormattedCoords($coords{'x'}, $coords{'y'});
#		printS("★$sourceDisplay施展 $skillsID_lut{$skillID} → $targetDisplay\n", "", $sourceID, "floor");
#		# Avoid monster skills
#		$castOn = 16;
#		$s_cDist = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%coords));
#		$i = 0;
#		while (1) {
#			last if (!$config{"teleportAuto_skill_$i"} || $ai_v{'temp'}{'teleOnEvent'});
#			if (existsInList($config{"teleportAuto_skill_$i"}, $skillsID_lut{$skillID})
#				&& existsInList2($config{"teleportAuto_skill_$i"."_castBy"}, $castBy, "and")
#				&& existsInList2($config{"teleportAuto_skill_$i"."_castOn"}, $castOn, "and")
#				&& (!$config{"teleportAuto_skill_$i"."_dist"} || $s_cDist < $config{"teleportAuto_skill_$i"."_dist"})
#				&& ($config{"teleportAuto_skill_$i"."_inCity"} || !$cities_lut{$field{'name'}.'.rsw'})) {
#				if ($config{"teleportAuto_skill_$i"."_randomWalk"} ne "") {
#					undef @array;
#					splitUseArray(\@array, $config{"teleportAuto_skill_$i"."_randomWalk"}, ",");
#					do {
#						$ai_v{'temp'}{'randX'} = $chars[$config{'char'}]{'pos_to'}{'x'} + int(rand() * ($array[1] * 2 + 1)) - $array[1];
#						$ai_v{'temp'}{'randY'} = $chars[$config{'char'}]{'pos_to'}{'y'} + int(rand() * ($array[1] * 2 + 1)) - $array[1];
#					} while (ai_route_getOffset(\%field, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
#								|| $ai_v{'temp'}{'randX'} == $chars[$config{'char'}]{'pos_to'}{'x'} && $ai_v{'temp'}{'randY'} == $chars[$config{'char'}]{'pos_to'}{'y'}
#								|| $ai_v{'temp'}{'randX'} == $coords{'x'} && $ai_v{'temp'}{'randY'} == $coords{'y'}
#								|| abs($ai_v{'temp'}{'randX'} - $chars[$config{'char'}]{'pos_to'}{'x'}) < $array[0] && abs($ai_v{'temp'}{'randY'} - $chars[$config{'char'}]{'pos_to'}{'y'}) < $array[0]);
#
#					move($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'});
#
#					printC(
#						"◆發現技能: $sourceDisplay對$targetDisplay施展 $skillsID_lut{$skillID}！\n"
#						."◆啟動 teleportAuto_skill - 隨機移動！\n"
#						, "tele"
#					);
#					sysLog("tele", "迴避", "發現技能: $sourceDisplay對$targetDisplay施展 $skillsID_lut{$skillID}, 隨機移動！");
#					last;
#				} else {
#					$ai_v{'temp'}{'teleOnEvent'} = 1;
#					timeOutStart('ai_teleport_event');
#					$sc_v{'temp'}{'teleOnEvent'} = useTeleport(1);
#					$ai_v{'clear_aiQueue'} = 1;
#
#					printC(
#						"◆發現技能: $sourceDisplay對$targetDisplay施展 $skillsID_lut{$skillID}！\n"
#						."◆啟動 teleportAuto_skill - 瞬間移動！\n"
#						, "tele"
#					);
#
#					sysLog("tele", "迴避", "發現技能: $sourceDisplay對$targetDisplay施展 $skillsID_lut{$skillID}, 瞬間移動！");
#
#					last;
#				}
#			}
#			$i++;
#		}
		$msg_size = 18;

	} elsif ($switch eq "0119" && length($msg) >= 13) {
#Karasu Start
		# Character status
		$ID = substr($msg, 2, 4);
		$param1 = unpack("S1", substr($msg, 6, 2));
		$param2 = unpack("S1", substr($msg, 8, 2));
		$param3 = unpack("S1", substr($msg, 10, 2));
		if ($ID eq $accountID) {
			$chars[$config{'char'}]{'param1'} = $param1;
			$chars[$config{'char'}]{'param2'} = $param2;
			$chars[$config{'char'}]{'param3'} = $param3;
			$targetDisplay = "你";
		} elsif (%{$players{$ID}}) {
			$players{$ID}{'param1'} = $param1;
			$players{$ID}{'param2'} = $param2;
			$players{$ID}{'param3'} = $param3;
			$targetDisplay = "$players{$ID}{'name'} ($players{$ID}{'binID'}) ";
		} elsif (%{$monsters{$ID}}) {
			$monsters{$ID}{'param1'} = $param1;
			$monsters{$ID}{'param2'} = $param2;
			$monsters{$ID}{'param3'} = $param3;
			$targetDisplay = "$monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) ";
		} else {
			$targetDisplay = "不明人物 ";
			# Avoid GM by ID
			avoidGM($ID, "", "可能想要測試你", 1) if ($config{'dcOnGM_paranoia'});
		}
		my $ai_index = binFind(\@ai_seq, "attack");
		if (($ai_index ne "" && $ID eq $ai_seq_args[$ai_index]{'ID'})
			|| $ID eq $accountID || $config{'debug'}) {
			printC("[特殊狀態Ａ] $targetDisplay".$messages_lut{$switch."_A"}{$param1}."\n", "status") if ($param1);
			foreach (keys %{$messages_lut{'0119_B'}}) {
				printC("[特殊狀態Ｂ] $targetDisplay".$messages_lut{$switch."_B"}{$_}."\n", "status") if ($_ & $param2);
			}
			if ($ID eq $accountID) {
				printC("[特殊狀態Ｃ] $targetDisplay".$messages_lut{$switch."_C"}{$_}."\n", "status") if (1 & $param3);
			} else {
				foreach (keys %{$messages_lut{'0119_C'}}) {
					printC("[特殊狀態Ｃ] $targetDisplay".$messages_lut{$switch."_C"}{$_}."\n", "status") if ($_ & $param3);
				}
			}
		}
#Karasu End
		$msg_size = 13;

	} elsif ($switch eq "011A" && length($msg) >= 15) {
		$skillID = unpack("S1",substr($msg, 2, 2));
		$targetID = substr($msg, 6, 4);
		$sourceID = substr($msg, 10, 4);
		$amount = unpack("S1",substr($msg, 4, 2));

		parseSkill($switch, $skillID, $sourceID, $targetID, $amount);

#		undef $sourceDisplay;
#		undef $targetDisplay;
#
#		parseSteal($sourceID, $targetID, $skillID);
#
#		if (%{$spells{$sourceID}}) {
#			$sourceID = $spells{$sourceID}{'sourceID'}
#		}
#		if (%{$monsters{$sourceID}}) {
#			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) ";
#		} elsif (%{$players{$sourceID}}) {
#			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) ";
#		} elsif ($sourceID eq $accountID) {
#			$sourceDisplay = "你";
#			$chars[$config{'char'}]{'skills_used'}{$skills_rlut{lc($skillsID_lut{$skillID})}}{'time_used'} = time;
#			undef $chars[$config{'char'}]{'time_cast'};
#			undef $ai_v{'temp'}{'castWait'};
#		} else {
#			$sourceDisplay = "不明人物 ";
#		}
#		if (%{$monsters{$targetID}}) {
#			if ($sourceID ne $targetID) {
#				$targetDisplay = " $monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'}) ";
#				if ($sourceID eq $accountID) {
#					$monsters{$targetID}{'castOnByYou'}++;
#				} elsif (%{$players{$sourceID}}) {
#					$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
#				}
#			} else {
#				$targetDisplay = "他自己";
#			}
#		} elsif (%{$players{$targetID}}) {
#			if ($sourceID ne $targetID) {
#				$targetDisplay = " $players{$targetID}{'name'} ($players{$targetID}{'binID'}) ";
#			} else {
#				$targetDisplay = "他自己";
#			}
#		} elsif ($targetID eq $accountID) {
#			if ($sourceID eq $accountID) {
#				$targetDisplay = "你自己";
#			} else {
#				$targetDisplay = "你";
#			}
#		} else {
#			$targetDisplay = " 不明目標 ";
#		}
#		if ($skillID == 28 || $skillID == 334) {
#			$extra = " - 回復 $amount HP";
#		} elsif ($skillID == 335) {
#			$extra = " - 回復 $amount SP";
#		} else {
#			$extra = ($amount == 65535) ? "" : " (Lv $amount)";
#		}
#		printS("★$sourceDisplay對$targetDisplay施展 $skillsID_lut{$skillID}$extra\n", "", $sourceID, $targetID);
		$msg_size = 15;

	} elsif ($switch eq "011C" && length($msg) >= 68) {
		# Location list of teleport/warp

		my $type = unpack("S1",substr($msg, 2, 2));
		my ($memo1, $memo2, $memo3, $memo4);

		undef %warp;

		($memo1) = substr($msg, 4, 16) =~ /([\s\S]*?)\000/;
		($memo2) = substr($msg, 20, 16) =~ /([\s\S]*?)\000/;
		($memo3) = substr($msg, 36, 16) =~ /([\s\S]*?)\000/;
		($memo4) = substr($msg, 52, 16) =~ /([\s\S]*?)\000/;

		($memo1) = $memo1 =~ /([\s\S]*)\.gat/;
		($memo2) = $memo2 =~ /([\s\S]*)\.gat/;
		($memo3) = $memo3 =~ /([\s\S]*)\.gat/;
		($memo4) = $memo4 =~ /([\s\S]*)\.gat/;

		$warp{'use'} = $type;

		undef @{$warp{'memo'}};

		push @{$warp{'memo'}}, $memo1 if $memo1 ne "";
		push @{$warp{'memo'}}, $memo2 if $memo2 ne "";
		push @{$warp{'memo'}}, $memo3 if $memo3 ne "";
		push @{$warp{'memo'}}, $memo4 if $memo4 ne "";

		if ($warp{'use'} == 27 || @{$warp{'memo'}} >= @{$record{'warp'}{'memo'}}) {
#			@{$record{'warp'}{'memo'}} = @{$warp{'memo'}};
#			$record{'warp'}{'use'} = $warp{'use'};
			%{$record{'warp'}} = %warp;
		}

		if ($warp{'memo'}[0] ne "" && $config{'saveMap'} ne $warp{'memo'}[0]){
			configModify('saveMap', $warp{'memo'}[0]);
			printC("Auto-update saveMap to ".getMapName($warp{'memo'}[0], 1)."\n", "s");
		}

		if ($sc_v{'ai'}{'warpTo'}{'map'} ne "") {
#			move($sc_v{'ai'}{'warpTo'}{'x'}, $sc_v{'ai'}{'warpTo'}{'y'});

#			ai_clientSuspend(0, 2);
#			ai_clientSuspend(0, $timeout{'ai_warpTo_wait'}{'timeout'});

			timeOutStart('ai_warpTo_wait');

			parseInput("warp $sc_v{'ai'}{'warpTo'}{'map'}");

			ai_clientSuspend(0, $timeout{'ai_warpTo_wait'}{'timeout'});

#			parseInput("move $sc_v{'ai'}{'warpTo'}{'x'} $sc_v{'ai'}{'warpTo'}{'y'}");

			print "計算路徑進入傳送之陣\n";

			move($sc_v{'ai'}{'warpTo'}{'x'}, $sc_v{'ai'}{'warpTo'}{'y'});
#			ai_clientSuspend(0, $timeout{'ai_warpTo_wait'}{'timeout'});
		} elsif (@{$warp{'memo'}}) {
			parseInput("warp list");
			ai_clientSuspend(0, 5);
		}

		$msg_size = 68;

	} elsif ($switch eq "011E" && length($msg) >= 3) {
		$fail = unpack("C1", substr($msg, 2, 1));
		if (!$fail) {
			print "Memo 成功\！\n";
		} else {
			print "Memo 失敗！\n";
		}
		$msg_size = 3;

	} elsif ($switch eq "011F" && length($msg) >= 16 || $switch eq "01C9" && length($msg) >= 97 ) {
		#area effect spell

#		my $ID = substr($msg, 2, 4);
#		my $sourceID = substr($msg, 6, 4);
#		my $pos_x = unpack("S1",substr($msg, 10, 2));
#		my $pos_y = unpack("S1",substr($msg, 12, 2));
#		my $type = unpack("C1",substr($msg, 14, 1));
#
#		event_spell($switch
#			, $ID
#			, $sourceID
#			, $pos_x
#			, $pos_y
#			, $type
#		);

		$ID = substr($msg, 2, 4);
		$sourceID = substr($msg, 6, 4);
		$coords{'x'} = unpack("S1",substr($msg, 10, 2));
		$coords{'y'} = unpack("S1",substr($msg, 12, 2));
		$type = unpack("C1",substr($msg, 14, 1));

		$spells{$ID}{'sourceID'} = $sourceID;
		$spells{$ID}{'pos'}{'x'} = $coords{'x'};
		$spells{$ID}{'pos'}{'y'} = $coords{'y'};
		$spells{$ID}{'type'} = $type;
		$binID = binAdd(\@spellsID, $ID);
		$spells{$ID}{'binID'} = $binID;

#		undef $sourceDisplay;
#		undef $targetDisplay;
#		undef $s_cDist;
#		undef $castBy;

		my ($sourceDisplay, $targetDisplay, $s_cDist, $castBy);

		if (%{$monsters{$sourceID}}) {
			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) ";
			$castBy = 2;
		} elsif (%{$players{$sourceID}}) {
			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) ";
			$castBy = 4;
		} elsif ($sourceID eq $accountID) {
			$sourceDisplay = "你";
			$castBy = 1;
		} else {
			$sourceDisplay = "不明人物 ";
			$castBy = 8;
		}

		if ($type == 128) {
			$sc_v{'ai'}{'warpTo'}{'x'} = $coords{'x'};
			$sc_v{'ai'}{'warpTo'}{'y'} = $coords{'y'};
		}

		$targetDisplay = ($messages_lut{'011F'}{$type} ne "")
			? $messages_lut{'011F'}{$type}
			: "不明型態 ".$type;
		$s_cDist = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$spells{$ID}{'pos'}}));

		if ($messages_lut{'011F'}{$type} ne "" && !existsInList($config{'hideMsg_groundEffect'}, $type) && $config{'hideMsg_groundEffect'} ne "all"
			&& ($ai_v{'hideMsg_groundEffect'}{'sourceID'} ne $sourceID || $ai_v{'hideMsg_groundEffect'}{'type'} ne $type || timeOut($config{'hideMsg_groundEffect_timeout'}, $ai_v{'hideMsg_groundEffect_time'}) || $config{'debug'})) {
			printS("★$sourceDisplay的 $targetDisplay 出現在座標: ".getFormattedCoords($coords{'x'}, $coords{'y'}).", 距離: $s_cDist\n", "", $sourceID, "floor");
			$ai_v{'hideMsg_groundEffect'}{'sourceID'} = $sourceID;
			$ai_v{'hideMsg_groundEffect'}{'type'} = $type;
			$ai_v{'hideMsg_groundEffect_time'} = time;
		}
#Karasu Start
		# Avoid ground effect skills
		$i = 0;
#		while (1) {
		while ($config{"teleportAuto_spell"}) {
			last if (!$config{"teleportAuto_spell_$i"} || $ai_v{'temp'}{'teleOnEvent'});
			if (existsInList($config{"teleportAuto_spell_$i"}, $targetDisplay)
				&& existsInList2($config{"teleportAuto_spell_$i"."_castBy"}, $castBy, "and")
				&& (!$config{"teleportAuto_spell_$i"."_dist"} || $s_cDist < $config{"teleportAuto_spell_$i"."_dist"})
				&& ($config{"teleportAuto_spell_$i"."_inCity"} || !$cities_lut{$field{'name'}.'.rsw'})) {
				if ($config{"teleportAuto_spell_$i"."_randomWalk"} ne "") {
					undef @array;
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
#Karasu End
		$msg_size = ($switch eq "011F") ? 16 : 97;

	} elsif ($switch eq "0120" && length($msg) >= 6) {
		#The area effect spell with ID dissappears
		$ID = substr($msg, 2, 4);
		undef %{$spells{$ID}};
		binRemove(\@spellsID, $ID);

		if (binFind(\@monstersID, $ai_seq_args[0]{'ID'}) ne "") {
			if ($monsters{$ai_seq_args[0]{'ID'}}{'StoporSnare'}) {
				$monsters{$ai_seq_args[0]{'ID'}}{'StoporSnare'} = "";
#				PrintMessage($monsters{$ai_seq_args[0]{'ID'}}{'name'}." Free for Stop or Snare.", "gray");
			}
		} elsif (binFind(\@monstersID, $ai_seq_args[0]{'ID'}) ne "") {
		 	if ($players{$ai_seq_args[0]{'ID'}}{'StoporSnare'}) {
				$players{$ai_seq_args[0]{'ID'}}{'StoporSnare'} = "";
#				PrintMessage($players{$ai_seq_args[0]{'ID'}}{'name'}." Free for Stop or Snare.", "gray");
			}
		}

		$msg_size = 6;

#Cart Parses - chobit andy 20030102
	} elsif ($switch eq "0121" && length($msg) >= 14) {
		$cart{'items'}      = unpack("S1", substr($msg, 2, 2));
		$cart{'items_max'}  = unpack("S1", substr($msg, 4, 2));
		$cart{'weight'}     = int(unpack("L1", substr($msg, 6, 4)) / 10);
		$cart{'weight_max'} = int(unpack("L1", substr($msg, 10, 4)) / 10);
		$msg_size = 14;

	} elsif ($switch eq "0122" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1",substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		for($i = 4; $i < $msg_size; $i+=20) {
			$index  = unpack("S1", substr($msg, $i, 2));
			$ID     = unpack("S1", substr($msg, $i + 2, 2));
			$type   = unpack("C1", substr($msg, $i + 4, 1));
			$cart{'inventory'}[$index]{'nameID'}     = $ID;
			$cart{'inventory'}[$index]{'amount'}     = 1;
			$cart{'inventory'}[$index]{'type'}       = $type;
			$cart{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			#$cart{'inventory'}[$index]{'type_equip'} = unpack("S1", substr($msg, $i + 6, 2));
			$cart{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
			if ($cart{'inventory'}[$index]{'type_equip'} == 1024) {
				$cart{'inventory'}[$index]{'borned'} = unpack("C1", substr($msg, $i + 10, 1));
				$cart{'inventory'}[$index]{'named'} = unpack("C1", substr($msg, $i + 18, 1));
			} elsif ($cart{'inventory'}[$index]{'type_equip'}) {
				$cart{'inventory'}[$index]{'broken'}       = unpack("C1", substr($msg, $i + 10, 1));
				$cart{'inventory'}[$index]{'refined'}      = unpack("C1", substr($msg, $i + 11, 1));
				if (unpack("S1", substr($msg, $i + 12, 2)) == 0x00FF) {
					$cart{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, $i + 14, 1));
					$cart{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, $i + 15, 1)) / 0x05;
					$cart{'inventory'}[$index]{'maker_charID'} = substr($msg, $i + 16, 4);
					if (!$charID_lut{$cart{'inventory'}[$index]{'maker_charID'}}) {
						sendGetPlayerInfoByCharID(\$remote_socket, $cart{'inventory'}[$index]{'maker_charID'});
					}
				} else {
					$cart{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, $i + 12, 2));
					$cart{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, $i + 14, 2));
					$cart{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, $i + 16, 2));
					$cart{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, $i + 18, 2));
				}
			}
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "不明物品 ".$ID;
			$cart{'inventory'}[$index]{'name'} = $display;
			modifyName(\%{$cart{'inventory'}[$index]});
			print "Cart Item: $cart{'inventory'}[$index]{'name'} ($index) x 1\n" if ($config{'debug'});
		}

	} elsif (($switch eq "0123" || $switch eq "01EF") && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1",substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		$psize = ($switch eq "0123") ? 10 : 18;
		for($i = 4; $i < $msg_size; $i+=$psize) {
			$index  = unpack("S1", substr($msg, $i, 2));
			$ID     = unpack("S1", substr($msg, $i + 2, 2));
			$type   = unpack("C1", substr($msg, $i + 4, 1));
			$amount = unpack("S1", substr($msg, $i + 6, 2));
			$cart{'inventory'}[$index]{'nameID'}     = $ID;
			$cart{'inventory'}[$index]{'amount'}     = $amount;
			$cart{'inventory'}[$index]{'type'}       = $type;
			$cart{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, $i + 5, 1));
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "不明物品 ".$ID;
			$cart{'inventory'}[$index]{'name'} = $display;
			print "Cart Item: $cart{'inventory'}[$index]{'name'} ($index) x $amount\n" if ($config{'debug'});
		}

	} elsif ($switch eq "0124" && length($msg) >= 21 || $switch eq "01C5" && length($msg) >= 22) {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$ID = unpack("S1", substr($msg, 8, 2));
		$psize = ($switch eq "0124") ? 0 : 1;
		if (%{$cart{'inventory'}[$index]}) {
			$cart{'inventory'}[$index]{'amount'}     += $amount;
		} else {
			$cart{'inventory'}[$index]{'nameID'}     = $ID;
			$cart{'inventory'}[$index]{'amount'}     = $amount;
			$cart{'inventory'}[$index]{'type'} = unpack("C1", substr($msg, 10, 1)) if ($switch eq "01C5");
			$cart{'inventory'}[$index]{'identified'} = unpack("C1", substr($msg, 10 + $psize, 1));
			$cart{'inventory'}[$index]{'type_equip'} = $itemSlots_lut{$ID};
			if ($cart{'inventory'}[$index]{'type_equip'} == 1024) {
				$cart{'inventory'}[$index]{'borned'} = unpack("C1", substr($msg, 11 + $psize, 1));
				$cart{'inventory'}[$index]{'named'} = unpack("C1", substr($msg, 19 + $psize, 1));
			} elsif ($cart{'inventory'}[$index]{'type_equip'}) {
				$cart{'inventory'}[$index]{'broken'}       = unpack("C1", substr($msg, 11 + $psize, 1));
				$cart{'inventory'}[$index]{'refined'}      = unpack("C1", substr($msg, 12 + $psize, 1));
				if (unpack("S1", substr($msg, 13 + $psize, 2)) == 0x00FF) {
					$cart{'inventory'}[$index]{'attribute'} = unpack("C1", substr($msg, 15 + $psize, 1));
					$cart{'inventory'}[$index]{'star'}      = unpack("C1", substr($msg, 16 + $psize, 1)) / 0x05;
					$cart{'inventory'}[$index]{'maker_charID'} = substr($msg, 17 + $psize, 4);
					if (!$charID_lut{$cart{'inventory'}[$index]{'maker_charID'}}) {
						sendGetPlayerInfoByCharID(\$remote_socket, $cart{'inventory'}[$index]{'maker_charID'});
					}
				} else {
					$cart{'inventory'}[$index]{'card'}[0]   = unpack("S1", substr($msg, 13 + $psize, 2));
					$cart{'inventory'}[$index]{'card'}[1]   = unpack("S1", substr($msg, 15 + $psize, 2));
					$cart{'inventory'}[$index]{'card'}[2]   = unpack("S1", substr($msg, 17 + $psize, 2));
					$cart{'inventory'}[$index]{'card'}[3]   = unpack("S1", substr($msg, 19 + $psize, 2));
				}
			}
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "不明物品 ".$ID;
			$cart{'inventory'}[$index]{'name'} = $display;
			modifyName(\%{$cart{'inventory'}[$index]});
		}
		print "你將 $cart{'inventory'}[$index]{'name'} ($index) x $amount 放入手推車\n";
		$msg_size = ($switch eq "0124") ? 21 : 22;

	} elsif ($switch eq "0125" && length($msg) >= 8) {
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("L1", substr($msg, 4, 4));
		$cart{'inventory'}[$index]{'amount'} -= $amount;
		print "你從手推車拿出 $cart{'inventory'}[$index]{'name'} ($index) x $amount\n";
		if ($cart{'inventory'}[$index]{'amount'} <= 0) {
			undef %{$cart{'inventory'}[$index]};
		}
		$msg_size = 8;

	} elsif ($switch eq "012C" && length($msg) >= 3) {
		$fail = unpack("C1", substr($msg, 2, 1));
		if ($fail == 0) {
			printC("手推車的載重量已超過上限\n", "alert");
		} elsif ($fail == 1) {
			printC("手推車的物品數量已超過上限\n", "alert");
		}
	  	$msg_size = 3;

	} elsif ($switch eq "012D" && length($msg) >= 4) {
		# vendor open
		$amount = unpack("S1", substr($msg, 2, 2));
		$shop{'maxItems'} = $amount;
		print "你最多可以販賣 $amount樣商品\n";
		$msg_size = 4;

	} elsif ($switch eq "0131" && length($msg) >= 86) {
		# vendor list
		$ID = substr($msg, 2, 4);
		if (!%{$vendorList{$ID}}) {
			binAdd(\@vendorListID, $ID);
		}
		($vendorList{$ID}{'title'}) = substr($msg, 6, 80) =~ /(.*?)\000/;
		$vendorList{$ID}{'ID'} = $ID;
		$msg_size = 86;

	} elsif ($switch eq "0132" && length($msg) >= 6) {
		# vendor closed
		$ID = substr($msg, 2, 4);
		binRemove(\@vendorListID, $ID);
		undef %{$vendorList{$ID}};
		$msg_size = 6;

	} elsif ($switch eq "0133" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		# vendor item list
		$msg_size = unpack("S1",substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$ID = substr($msg, 4, 4);
		if ($currentVendingShop ne $ID) {
			$currentVendingShop = $ID;
		}
		$~ = "VENDORTITLE";
		print "-------------------------------- 攤位物品清單 --------------------------------\n";
		$title_string = $vendorList{$ID}{'title'};
		$owner_string = $players{$ID}{'name'};
		write;
		print "#   名稱                                       種類      數量  金  額(Z)      \n";

		undef @vendorItemList;
		for ($i = 8; $i < $msg_size; $i += 22) {
			$price  = unpack("L1", substr($msg, $i, 4));
			$amount = unpack("S1", substr($msg, $i + 4, 2));
			$index  = unpack("S1", substr($msg, $i + 6, 2));
			$type   = unpack("C1", substr($msg, $i + 8, 1));
			$itemID = unpack("S1", substr($msg, $i + 9, 2));
			$vendorItemList[$index]{'itemID'}     = $itemID;
			$vendorItemList[$index]{'amount'}     = $amount;
			$vendorItemList[$index]{'type'}       = $type;
			$vendorItemList[$index]{'price'}      = $price;
			$vendorItemList[$index]{'identified'} = unpack("C1", substr($msg, $i + 11, 1));
			$vendorItemList[$index]{'type_equip'} = $itemSlots_lut{$itemID};
			if ($vendorItemList[$index]{'type_equip'} == 1024) {
				$vendorItemList[$index]{'borned'} = unpack("C1", substr($msg, $i + 12, 1));
				$vendorItemList[$index]{'named'} = unpack("C1", substr($msg, $i + 20, 1));
			} elsif ($vendorItemList[$index]{'type_equip'}) {
				$vendorItemList[$index]{'broken'}       = unpack("C1", substr($msg, $i + 12, 1));
				$vendorItemList[$index]{'refined'}      = unpack("C1", substr($msg, $i + 13, 1));
				if (unpack("S1", substr($msg, $i + 14, 2)) == 0x00FF) {
					$vendorItemList[$index]{'attribute'} = unpack("C1", substr($msg, $i + 16, 1));
					$vendorItemList[$index]{'star'}      = unpack("C1", substr($msg, $i + 17, 1)) / 0x05;
					$vendorItemList[$index]{'maker_charID'} = substr($msg, $i + 18, 4);
					if (!$charID_lut{$vendorItemList[$index]{'maker_charID'}}) {
						sendGetPlayerInfoByCharID(\$remote_socket, $vendorItemList[$index]{'maker_charID'});
					}
				} else {
					$vendorItemList[$index]{'card'}[0]   = unpack("S1", substr($msg, $i + 14, 2));
					$vendorItemList[$index]{'card'}[1]   = unpack("S1", substr($msg, $i + 16, 2));
					$vendorItemList[$index]{'card'}[2]   = unpack("S1", substr($msg, $i + 18, 2));
					$vendorItemList[$index]{'card'}[3]   = unpack("S1", substr($msg, $i + 20, 2));
				}
			}
			$display = ($items_lut{$itemID} ne "")
						? $items_lut{$itemID}
						: "不明物品 ".$itemID;
			$vendorItemList[$index]{'name'} = $display;
			modifyName(\%{$vendorItemList[$index]});
			print "Item added to vendorItem : $vendorItemList[$index]{'name'} x $amount - $price z\n" if ($config{'debug'});
			# Display
			$price_string = toZeny($vendorItemList[$index]{'price'});
			$~ = "VENDORITEMLIST";
			format VENDORITEMLIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @>>>> @>>>>>>>>>
$index, $vendorItemList[$index]{'name'}, $itemTypes_lut{$vendorItemList[$index]{'type'}}, $vendorItemList[$index]{'amount'}, $price_string
.
			write;
		}
		print "------------------------------------------------------------------------------\n";
		print "請輸入 'pick <攤位物品編號> [<數量>]' 挑選物品\n"
			, "或輸入 'shop <攤位編號>' 瀏覽其他攤位\n";

#Karasu Start
	} elsif ($switch eq "0135" && length($msg) >= 7) {
		# can't buy from shop
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("S1", substr($msg, 4, 2));
		$fail = unpack("C1", substr($msg, 6, 1));
		print "$vendorItemList[$index]{'name'} 購買失敗 - " if ($fail != 0);
		print "$messages_lut{$switch}{$fail}";
		print ", 目前庫存數量 $amount 個" if ($fail == 4);
		print "\n";
		print "Error Code : $fail\n" if ($config{'debug'});
		$msg_size = 7;
#Karasu End

	} elsif ($switch eq "0136" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		# vendor open succeed
		$msg_size = unpack("S1",substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 8, length($msg)-8));
		$msg = substr($msg, 0, 8).$newmsg;
		$~ = "VENDORTITLE";
		$title_string = (length($myShop{'shop_title'}) > 36) ? substr($myShop{'shop_title'}, 0, 36) : $myShop{'shop_title'};
		$owner_string = $chars[$config{'char'}]{'name'};
		print "---------------------------------- 我的商店 ----------------------------------\n";
		write;
		print "#   名稱                                       種類      數量  金  額(Z)      \n";

		undef @articles;
		$articles = 0;
		for ($i = 8; $i < $msg_size; $i+=22) {
			$articles++;
			$price  = unpack("L1", substr($msg, $i, 4));
			$index  = unpack("S1", substr($msg, $i + 4, 2));
			$amount = unpack("S1", substr($msg, $i + 6, 2));
			$type   = unpack("C1", substr($msg, $i + 8, 1));
			$itemID = unpack("S1", substr($msg, $i + 9, 2));
			#$articles[$index]{'index'}      = $index;
			$articles[$index]{'itemID'}     = $itemID;
			$articles[$index]{'amount'}     = $amount;
			$articles[$index]{'type'}       = $type;
			$articles[$index]{'price'}      = $price;
			$articles[$index]{'sold'}       = 0;
			$articles[$index]{'identified'} = unpack("C1", substr($msg, $i + 11, 1));
			$articles[$index]{'type_equip'} = $itemSlots_lut{$itemID};
			if ($articles[$index]{'type_equip'} == 1024) {
				$articles[$index]{'borned'} = unpack("C1", substr($msg, $i + 12, 1));
				$articles[$index]{'named'} = unpack("C1", substr($msg, $i + 20, 1));
			} elsif ($articles[$index]{'type_equip'}) {
				$articles[$index]{'broken'}       = unpack("C1", substr($msg, $i + 12, 1));
				$articles[$index]{'refined'}      = unpack("C1", substr($msg, $i + 13, 1));
				if (unpack("S1", substr($msg, $i + 14, 2)) == 0x00FF) {
					$articles[$index]{'attribute'} = unpack("C1", substr($msg, $i + 16, 1));
					$articles[$index]{'star'}      = unpack("C1", substr($msg, $i + 17, 1)) / 0x05;
					$articles[$index]{'maker_charID'} = substr($msg, $i + 18, 4);
					if (!$charID_lut{$articles[$index]{'maker_charID'}}) {
						sendGetPlayerInfoByCharID(\$remote_socket, $articles[$index]{'maker_charID'});
					}
				} else {
					$articles[$index]{'card'}[0]   = unpack("S1", substr($msg, $i + 14, 2));
					$articles[$index]{'card'}[1]   = unpack("S1", substr($msg, $i + 16, 2));
					$articles[$index]{'card'}[2]   = unpack("S1", substr($msg, $i + 18, 2));
					$articles[$index]{'card'}[3]   = unpack("S1", substr($msg, $i + 20, 2));
				}
			}
			$display = ($items_lut{$itemID} ne "")
						? $items_lut{$itemID}
						: "不明物品 ".$itemID;
			$articles[$index]{'name'} = $display;
			modifyName(\%{$articles[$index]});
			print "Item added to vendor : $articles[$index]{'name'} x $amount - $price z\n" if ($config{'debug'});
			# Display
			$price_string = toZeny($articles[$index]{'price'});
			$~ = "ARTICLESLIST";
			format ARTICLESLIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @>>>> @>>>>>>>>>
$index, $articles[$index]{'name'}, $itemTypes_lut{$articles[$index]{'type'}}, $articles[$index]{'amount'}, $price_string
.
			write;
		}
		print "------------------------------------------------------------------------------\n";
		$shop{'opened'} = 1;
#		chatLog("販賣", "開始擺\攤: 目前擁有 ".toZeny($chars[$config{'char'}]{'zenny'})." Zeny", "sh");
		sysLog("sh", "販賣", "開始擺\攤: 目前擁有 ".toZeny($chars[$config{'char'}]{'zenny'})." Zeny");

	} elsif ($switch eq "0137" && length($msg) >= 6) {
		# report for selling from vendor
		$index = unpack("S1", substr($msg, 2, 2));
		$amount = unpack("S1", substr($msg, 4, 2));

		event_shop_selling($index, $amount);

		$msg_size = 6;

	} elsif ($switch eq "0139" && length($msg) >= 16) {
		$ID = substr($msg, 2, 4);
		$type = unpack("S1",substr($msg, 14, 2));
		$coords1{'x'} = unpack("S1",substr($msg, 6, 2));
		$coords1{'y'} = unpack("S1",substr($msg, 8, 2));
		$coords2{'x'} = unpack("S1",substr($msg, 10, 2));
		$coords2{'y'} = unpack("S1",substr($msg, 12, 2));
		%{$monsters{$ID}{'pos_attack_info'}} = %coords1;
		# Adjust monster position
		%{$monsters{$ID}{'pos'}} = %coords1;
		%{$monsters{$ID}{'pos_to'}} = %coords1;
		%{$chars[$config{'char'}]{'pos'}} = %coords2;
		%{$chars[$config{'char'}]{'pos_to'}} = %coords2;
		print "Recieved attack location - $monsters{$ID}{'pos_attack_info'}{'x'}, $monsters{$ID}{'pos_attack_info'}{'y'} - ".getHex($ID)."\n" if ($config{'debug'} >= 2);
		$msg_size = 16;

	} elsif ($switch eq "013A" && length($msg) >= 4) {
		# Attack range
		$val = unpack("S1",substr($msg, 2, 2));
		$msg_size = 4;

#Karasu Start
	} elsif ($switch eq "013B" && length($msg) >= 4) {
		#Arrow equiped
		$type = unpack("S1", substr($msg, 2, 2));
#Hambo Start
		if ($type == 0) {
			print "你沒有裝備箭矢, 攻擊失敗\n";
#Hambo End
		} elsif ($type == 3) {
			print "裝備箭矢成功\\n" if ($config{'debug'});
		}
		$msg_size = 4;
#Karasu End

	} elsif ($switch eq "013C" && length($msg) >= 4) {
		$index = unpack("S1", substr($msg, 2, 2));
		# Equip arrow related
		if ($index) {
			undef $invIndex;
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			if ($invIndex eq "") {
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", "");
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'index'} = $index;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'} = -1;
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = "0";
			} else {
				print "你裝備 $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) - $itemTypes_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'type'}}\n" if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} ne "0");
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'equipped'} = "0";
			}
			undef $chars[$config{'char'}]{'autoSwitch'} if ($chars[$config{'char'}]{'autoSwitch'} ne $invIndex);
		}
		$msg_size = 4;

	} elsif ($switch eq "013D" && length($msg) >= 6) {
		$type = unpack("S1",substr($msg, 2, 2));
		$amount = unpack("S1",substr($msg, 4, 2));
		if ($type == 5) {
			$chars[$config{'char'}]{'hp'} += $amount;
			$chars[$config{'char'}]{'hp'} = $chars[$config{'char'}]{'hp_max'} if ($chars[$config{'char'}]{'hp'} > $chars[$config{'char'}]{'hp_max'});
		} elsif ($type == 7) {
			$chars[$config{'char'}]{'sp'} += $amount;
			$chars[$config{'char'}]{'sp'} = $chars[$config{'char'}]{'sp_max'} if ($chars[$config{'char'}]{'sp'} > $chars[$config{'char'}]{'sp_max'});
		}
		$msg_size = 6;

	} elsif ($switch eq "013E" && length($msg) >= 24) {
		$sourceID = substr($msg, 2, 4);
		$targetID = substr($msg, 6, 4);
		my %coords;
		$coords{'x'} = unpack("S1",substr($msg, 10, 2));
		$coords{'y'} = unpack("S1",substr($msg, 12, 2));
		$skillID = unpack("S1",substr($msg, 14, 2));
		my $attribute = unpack("L1",substr($msg, 16, 4));

#		parseSteal($sourceID, $targetID, $skillID);

#		if ($attribute == 0) {
#			$attrDisplay = "[無]";
#		} else {
#			$attrDisplay = "[$attribute_lut{$attribute}]";
#		}
		$wait = unpack("L1",substr($msg, 20, 4)) / 1000;

		parseSkill($switch, $skillID, $sourceID, $targetID, $attribute, $wait, $coords{'x'}, $coords{'y'});

#		undef $sourceDisplay;
#		undef $targetDisplay;
#		undef $s_cDist;
#		undef $castBy;
#		undef $castOn;
#		if (%{$monsters{$sourceID}}) {
#			$sourceDisplay = "$monsters{$sourceID}{'name'} ($monsters{$sourceID}{'binID'}) ";
#			$castBy = 2;
#		} elsif (%{$players{$sourceID}}) {
#			$sourceDisplay = "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) ";
#			$castBy = 4;
#		} elsif ($sourceID eq $accountID) {
#			$sourceDisplay = "你";
#			$chars[$config{'char'}]{'time_cast'} = time;
#			$ai_v{'temp'}{'castWait'} = $wait;
#			$castBy = 1;
#		} else {
#			$sourceDisplay = "不明人物 ";
#			$castBy = 8;
#		}
#
#		if (%{$monsters{$targetID}}) {
#			if ($sourceID ne $targetID) {
#				$targetDisplay = "$monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'})";
#				if ($sourceID eq $accountID) {
#					$monsters{$targetID}{'castOnByYou'}++;
#				} elsif (%{$players{$sourceID}}) {
#					$monsters{$targetID}{'castOnByPlayer'}{$sourceID}++;
#				}
#			} else {
#				$targetDisplay = "他自己";
#			}
#			$s_cDist = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$targetID}{'pos_to'}}));
#			$castOn = 2;
#		} elsif (%{$players{$targetID}}) {
#			if ($sourceID ne $targetID) {
#				$targetDisplay = "$players{$targetID}{'name'} ($players{$targetID}{'binID'})";
#			} else {
#				$targetDisplay = "他自己";
#			}
#			$s_cDist = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$targetID}{'pos_to'}}));
#			$castOn = 4;
#		} elsif ($targetID eq $accountID) {
#			if ($sourceID eq $accountID) {
#				$targetDisplay = "自己";
#			} else {
#				$targetDisplay = "你";
#			}
#			$s_cDist = 0;
#			$castOn = 1;
#		} elsif ($coords{'x'} != 0 || $coords{'y'} != 0) {
#			$targetDisplay = "座標: ".getFormattedCoords($coords{'x'}, $coords{'y'});
#			$s_cDist = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%coords));
#			$castOn = 16;
#			$targetID = "floor";
#		} else {
#			$targetDisplay = " 不明目標";
#			$s_cDist = 0;
#			$castOn = 8;
#		}
#		printS("★$sourceDisplay施展 $skillsID_lut{$skillID} $attrDisplay → $targetDisplay, $wait秒後詠唱完成\n", "", $sourceID, $targetID);
#
#		# Avoid monster skills
#		$i = 0;
#		while (1) {
#			last if (!$config{"teleportAuto_skill_$i"} || $ai_v{'temp'}{'teleOnEvent'});
#			if (existsInList($config{"teleportAuto_skill_$i"}, $skillsID_lut{$skillID})
#				&& existsInList2($config{"teleportAuto_skill_$i"."_castBy"}, $castBy, "and")
#				&& existsInList2($config{"teleportAuto_skill_$i"."_castOn"}, $castOn, "and")
#				&& (!$config{"teleportAuto_skill_$i"."_dist"} || $s_cDist < $config{"teleportAuto_skill_$i"."_dist"})
#				&& ($config{"teleportAuto_skill_$i"."_inCity"} || !$cities_lut{$field{'name'}.'.rsw'})) {
#				if ($config{"teleportAuto_skill_$i"."_randomWalk"} ne "") {
#					undef @array;
#					splitUseArray(\@array, $config{"teleportAuto_skill_$i"."_randomWalk"}, ",");
#					do {
#						$ai_v{'temp'}{'randX'} = $chars[$config{'char'}]{'pos_to'}{'x'} + int(rand() * ($array[1] * 2 + 1)) - $array[1];
#						$ai_v{'temp'}{'randY'} = $chars[$config{'char'}]{'pos_to'}{'y'} + int(rand() * ($array[1] * 2 + 1)) - $array[1];
#					} while (ai_route_getOffset(\%field, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
#								|| $ai_v{'temp'}{'randX'} == $chars[$config{'char'}]{'pos_to'}{'x'} && $ai_v{'temp'}{'randY'} == $chars[$config{'char'}]{'pos_to'}{'y'}
#								|| $ai_v{'temp'}{'randX'} == $coords{'x'} && $ai_v{'temp'}{'randY'} == $coords{'y'}
#								|| abs($ai_v{'temp'}{'randX'} - $chars[$config{'char'}]{'pos_to'}{'x'}) < $array[0] && abs($ai_v{'temp'}{'randY'} - $chars[$config{'char'}]{'pos_to'}{'y'}) < $array[0]);
#
#					move($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'});
#
#					printC(
#						"◆發現技能: $sourceDisplay對$targetDisplay施展 $skillsID_lut{$skillID}！\n"
#						."◆啟動 teleportAuto_skill - 隨機移動！\n"
#						, "tele"
#					);
#					sysLog("tele", "迴避", "發現技能: $sourceDisplay對$targetDisplay施展 $skillsID_lut{$skillID}, 隨機移動！");
#
#					last;
#				} else {
#
#					$ai_v{'temp'}{'teleOnEvent'} = 1;
#					timeOutStart('ai_teleport_event');
#					$sc_v{'temp'}{'teleOnEvent'} = useTeleport(1);
#					$ai_v{'clear_aiQueue'} = 1;
#
#					printC(
#						"◆發現技能: $sourceDisplay對$targetDisplay施展 $skillsID_lut{$skillID}！\n"
#						."◆啟動 teleportAuto_skill - 瞬間移動！\n"
#						, "tele"
#					);
#					sysLog("tele", "迴避", "發現技能: $sourceDisplay對$targetDisplay施展 $skillsID_lut{$skillID}, 瞬間移動！");
#
#					last;
#				}
#			}
#			$i++;
#		}
		$msg_size = 24;

	} elsif ($switch eq "0141" && length($msg) >= 14) {
		$type = unpack("S1",substr($msg, 2, 2));
		$val = unpack("S1",substr($msg, 6, 2));
		$val2 = unpack("s1",substr($msg, 10, 2));
		if ($type == 13) {
			$chars[$config{'char'}]{'str'} = $val;
			$chars[$config{'char'}]{'str_bonus'} = $val2;
			print "Strength: $val + $val2\n" if ($config{'debug'});
		} elsif ($type == 14) {
			$chars[$config{'char'}]{'agi'} = $val;
			$chars[$config{'char'}]{'agi_bonus'} = $val2;
			print "Agility: $val + $val2\n" if ($config{'debug'});
		} elsif ($type == 15) {
			$chars[$config{'char'}]{'vit'} = $val;
			$chars[$config{'char'}]{'vit_bonus'} = $val2;
			print "Vitality: $val + $val2\n" if ($config{'debug'});
		} elsif ($type == 16) {
			$chars[$config{'char'}]{'int'} = $val;
			$chars[$config{'char'}]{'int_bonus'} = $val2;
			print "Intelligence: $val + $val2\n" if ($config{'debug'});
		} elsif ($type == 17) {
			$chars[$config{'char'}]{'dex'} = $val;
			$chars[$config{'char'}]{'dex_bonus'} = $val2;
			print "Dexterity: $val + $val2\n" if ($config{'debug'});
		} elsif ($type == 18) {
			$chars[$config{'char'}]{'luk'} = $val;
			$chars[$config{'char'}]{'luk_bonus'} = $val2;
			print "Luck: $val + $val2\n" if ($config{'debug'});
		}
		$msg_size = 14;

#s4u Start - Ayon 20030429(回應npc要求輸入數量)
	} elsif ($switch eq "0142" && length($msg) >= 6) {
		$ID = substr($msg, 2, 4);
		print "$npcs{$ID}{'name'}: 請輸入 'talk answer <數量>' 選擇欲回應數量, 或輸入 'talk no' 取消對話\n";
		$msg_size = 6;
#s4u End - Ayon 20030429(回應npc要求輸入數量)

	} elsif ($switch eq "0144" && length($msg) >= 23) {
		$msg_size = 23;

	} elsif ($switch eq "0145" && length($msg) >= 19) {
		$msg_size = 19;

	} elsif ($switch eq "0147" && length($msg) >= 39) {
		$skillID = unpack("S*",substr($msg, 2, 2));
		$skillLv = unpack("S*",substr($msg, 8, 2));
		print "Now using $skillsID_lut{$skillID}, lv $skillLv\n" if ($config{'debug'});
		sendSkillUse(\$remote_socket, $skillID, $skillLv, $accountID);
		$msg_size = 39;

	} elsif ($switch eq "0148" && length($msg) >= 8) {
		$ID = substr($msg, 2, 4);
		if ($ID eq $accountID) {
#			print "你已經復活了！\n";
#			chatLog("重要", "你已經復活了！", "im");
			sysLog("im", "重要", "你已經復活了！", 1);
			undef $chars[$config{'char'}]{'dead'};
			undef $chars[$config{'char'}]{'dead_time'};
			undef @ai_seq;
			undef @ai_seq_args;
		} elsif (%{$players{$ID}}) {
			undef $players{$ID}{'dead'};
			print "$players{$ID}{'name'} ($players{$ID}{'binID'}) 已經復活了！\n" if ($config{'debug'});
		} else {
			print "不明人物 已經復活了！\n" if ($config{'debug'});
		}
		$msg_size = 8;

	} elsif ($switch eq "014A" && length($msg) >= 6) {
		$msg_size = 6;

	} elsif ($switch eq "014B" && length($msg) >= 27) {
		$msg_size = 27;

#Karasu Start
	} elsif ($switch eq "014C" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		# alliance or rival guild
		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		$ID = $chars[$config{'char'}]{'guild'}{'ID'};
		for ($i = 4; $i < $msg_size; $i += 32) {
			$type = unpack("S1", substr($msg, $i, 4));
			$GID   = substr($msg, $i + 4, 4);
			($name) = substr($msg, $i + 8, 24) =~ /([\s\S]*?)\000/;
			if ($type == 0) {
				$guild{$ID}{'alliance'}[int($i/32)]{'ID'} = $GID;
				$guild{$ID}{'alliance'}[int($i/32)]{'name'} = $name;
			} else {
				$guild{$ID}{'rival'}[int($i/32)]{'ID'} = $GID;
				$guild{$ID}{'rival'}[int($i/32)]{'name'} = $name;
			}
		}

	} elsif ($switch eq "014E" && length($msg) >= 6) {
		$type = unpack("S1", substr($msg, 2, 2));
		if ($type == 0x57) {
#			normal guild member;
		} elsif ($type == 0xD7) {
#			guild master;
		}
		$msg_size = 6;

	} elsif ($switch eq "0152" && length($msg) >= 4 && length($msg) >= unpack("S*", substr($msg, 2, 2))) {
		# guild emblem image
		$msg_size = unpack("S*", substr($msg, 2, 2));

	} elsif ($switch eq "0154" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		# Guild Members Information
		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		$ID = $chars[$config{'char'}]{'guild'}{'ID'};
		$guild{$ID}{'members'} = 0;

		undef %guildUsers;

		for ($i = 4; $i < $msg_size; $i+=104) {

			$AID = substr($msg, $i, 4);
			$CID = substr($msg, $i+4, 4);

#			if (!binFind(\@guildUsersID, $CID)) {
#				binAdd(\@guildUsersID, $CID);
#			}

			$guildUsers{'AID'}{$AID} = 1;
			$guildUsers{'CID'}{$CID} = 1;

#			$guildUsersID{$AID} = 1 if (!$guildUsersID{$AID});

#			printC("guild AID:".getID($AID)." CID:".getID($CID)."\n", "s");

			$guild{$ID}{'member'}[int($i/104)]{'ID'} = $AID;
			$guild{$ID}{'member'}[int($i/104)]{'CID'} = $CID;
			$guild{$ID}{'member'}[int($i/104)]{'sex'} = unpack("S1", substr($msg, $i+12, 2));
			$guild{$ID}{'member'}[int($i/104)]{'jobID'} = unpack("S1", substr($msg, $i + 14, 2));
			$guild{$ID}{'member'}[int($i/104)]{'lvl'} = unpack("S1", substr($msg, $i + 16, 2));
			$guild{$ID}{'member'}[int($i/104)]{'contribution'} = unpack("L1", substr($msg, $i + 18, 4));
			$guild{$ID}{'member'}[int($i/104)]{'online'} = unpack("S1", substr($msg, $i + 22, 2));
			$guild{$ID}{'member'}[int($i/104)]{'title'} = unpack("L1", substr($msg, $i + 26, 4));
			($guild{$ID}{'member'}[int($i/104)]{'name'}) = substr($msg, $i + 80, 24) =~ /([\s\S]*?)\000/;
			$guild{$ID}{'members'}++;

			$charID_lut{$CID} = $guild{$ID}{'member'}[int($i/104)]{'name'};
			$charID_lut{$AID} = $guild{$ID}{'member'}[int($i/104)]{'name'} if ($charID_lut{$AID} eq "");
		}

	} elsif ($switch eq "0156" && length($msg) > 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
#		$ID1 = substr($msg, 4, 4);
#		$ID2 = substr($msg, 8, 4);

	} elsif ($switch eq "015A" && length($msg) >= 66) {
		# guild leave recv
		($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		($message) = substr($msg, 26, 40) =~ /([\s\S]*?)\000/;

		my $display;

		if ($name eq $chars[$config{'char'}]{'name'}) {
			$display = "你退出公會";
			undef %{$guild{$chars[$config{'char'}]{'guild'}{'ID'}}};
			undef %{$chars[$config{'char'}]{'guild'}};

			ai_event_checkUser_lock();
		} else {
			$display = "$name 退出公會";
		}

		sysLog("gm", "成員", "$display ($message)", 1);

		$msg_size = 66;

	} elsif ($switch eq "015C" && length($msg) >= 90) {
		# guild expell recv
		($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		($message) = substr($msg, 26, 40) =~ /([\s\S]*?)\000/;

		my $display;

		if ($name eq $chars[$config{'char'}]{'name'}) {
			$display = "你被逐出公會";
			undef %{$guild{$chars[$config{'char'}]{'guild'}{'ID'}}};
			undef %{$chars[$config{'char'}]{'guild'}};
		} else {
			$display = "$name 被逐出公會";
		}

		sysLog("gm", "成員", "$display ($message)", 1);

		$msg_size = 90;
	} elsif ($switch eq "0160") {
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));

		$msg = substr($msg, 0, 4).$newmsg;
		my ($num, $join, $kick);

		my $ID = $chars[$config{'char'}]{'guild'}{'ID'};

#		$guild{$ID}{'positions'} = 0;

		for(my $i = 4; $i < $msg_size; $i+=16) {
			$num = unpack("L*", substr($msg, $i, 4));
			$join = (unpack("C1", substr($msg, $i+4, 1)) & 0x01) ? 1 : 0;
			$kick = (unpack("C1", substr($msg, $i+4, 1)) & 0x10) ? 1 : 0;

			$guild{$ID}{'positions'}{$num}{'join'} = $join;
			$guild{$ID}{'positions'}{$num}{'kick'} = $kick;
			$guild{$ID}{'positions'}{$num}{'feeEXP'} = unpack("L1", substr($msg, $i+12, 4));
		}

#		$guild{$ID}{'positions'} = $num;

	} elsif ($switch eq "0162" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		# guild skills
		$msg_size = unpack("S1", substr($msg, 2, 2));

		my ($i, $nameID, $idx);
		my $ID = $chars[$config{'char'}]{'guild'}{'ID'};

		for($i = 6; $i < $msg_size; $i += 37) {

			($nameID) = substr($msg, $i + 12, 24) =~ /([\s\S]*?)\000/;
			$idx = unpack("S1",substr($msg, $i, 2)) % 10000;

			$guild{$ID}{'skills'}{$idx}{'nameID'} = $nameID;
			$guild{$ID}{'skills'}{$idx}{'ID'} = $idx;
			$guild{$ID}{'skills'}{$idx}{'lv'} = unpack("S1",substr($msg, $i + 6, 2));

			#print "$ID $nameID LV.$lv ($type)\n";
		}

#	} elsif ($switch eq "0163" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		# guild kick message
#		$msg_size = unpack("S1", substr($msg, 2, 2));

	} elsif ($switch eq "0166" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		# Guild Members Title List
		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		$ID = $chars[$config{'char'}]{'guild'}{'ID'};
		for ($i = 4; $i < $msg_size; $i += 28) {
			($guild{$ID}{'title'}[unpack("L1", substr($msg, $i, 4))]) = substr($msg, $i + 4, 24) =~ /([\s\S]*?)\000/;
			($guild{$ID}{'positions'}{unpack("L1", substr($msg, $i, 4))}{'name'}) = substr($msg, $i + 4, 24) =~ /([\s\S]*?)\000/;
		}

	} elsif ($switch eq "0167" && length($msg) >= 3) {
		# guild create recv
		$type = substr($msg, 2, 1);
		if ($type == 0) {
			print "建立公會成功\\n";
		} elsif ($type == 2) {
			print "建立公會失敗\n";
		}
		$msg_size = 3;

	} elsif ($switch eq "0169" && length($msg) >= 3) {
		# guild request denied
		$type = unpack("C1", substr($msg, 2, 1));
		if ($type == 0) {
			print "邀請加入公會失敗 - $name 已加入別的公會\n";
		} elsif ($type == 1) {
			print "邀請加入公會失敗 - $name 拒絕你的邀請\n";
		} elsif ($type == 2) {
			print "邀請加入公會成功\ - $name 接受你的邀請\n";
		}
		$msg_size = 3;

	} elsif ($switch eq "016A" && length($msg) >= 30) {
		# guild request for you
		$ID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		print "[$name] 邀請你加入公會\n";
		$incomingGuild{'ID'} = $ID;
		$incomingGuild{'name'} = $name;
		timeOutStart('ai_guildAuto');
		$msg_size = 30;

	} elsif ($switch eq "016C" && length($msg) >= 43) {
		# 016C <guildID>.l <?>.13B <guildName>.24B
		$chars[$config{'char'}]{'guild'}{'ID'} = substr($msg, 2, 4);
		($chars[$config{'char'}]{'guild'}{'name'}) = substr($msg, 19, 24) =~ /([\s\S]*?)\000/;
		$msg_size = 43;

	} elsif ($switch eq "016D" && length($msg) >= 14 || $switch eq "01F2" && length($msg) >= 20) {
		$ID = substr($msg, 2, 4);
		$CID =  substr($msg, 6, 4);
		$type = unpack("L1", substr($msg, 10, 4));
#		if ($ID ne $accountID) {
#			if ($charID_lut{$CID}) {
#				my $online_string = ($type) ? "上線了" : "離線了";
#				printC("公會成員 ($charID_lut{$CID}) $online_string\n", "g");
#			} else {
#				$players{$CID}{'online'} = $type;
#				sendGetPlayerInfoByCharID(\$remote_socket, $CID);
#			}
#		}
		$msg_size = ($switch eq "016D") ? 14 : 20;

		event_online($switch, $ID, $CID, "", $type);
#Karasu End

	} elsif ($switch eq "016F" && length($msg) >= 182) {
		($address) = substr($msg, 2, 60) =~ /([\s\S]*?)\000/;
		($message) = substr($msg, 62, 120) =~ /([\s\S]*?)\000/;

		my $ID = $chars[$config{'char'}]{'guild'}{'ID'};

		$guild{$ID}{'address'} = $address;
		$guild{$ID}{'message'} = $message;

		if (!$sc_v{'kore'}{'guildBulletinShow'} || !$config{'hideMsg_guildBulletin'} || $config{'debug'}) {
			printC("[ $address ]\n", "s") if ($address);
			printC("[ $message ]\n", "s") if ($message);
			$sc_v{'kore'}{'guildBulletinShow'} = 1 if (!$sc_v{'kore'}{'guildBulletinShow'});
		}
		$msg_size = 182;

#Karasu Start
	} elsif ($switch eq "0171" && length($msg) >= 30) {
		# Guild alliance request
#		$sourceID = substr($msg, 2, 4);
#		($name) = substr($msg, 6, 24) =~ /[\s\S]*?\000/;
		$msg_size = 30;

	} elsif ($switch eq "0173" && length($msg) >= 3) {
		# Reply guild alliance
#		$type = substr($msg, 2, 1);
		$msg_size = 3;

	} elsif ($switch eq "0174" && length($msg) > 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		# Edit Guild Position Info
		$msg_size = unpack("S1", substr($msg, 2, 2));
#		$amount = unpack("L1", substr($msg, 16, 4));
#		$name = substr($msg, 20, 24);
#Karasu End

	} elsif ($switch eq "0177" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @identifyID;
		undef $invIndex;
		for ($i = 4; $i < $msg_size; $i += 2) {
			$index = unpack("S1", substr($msg, $i, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			binAdd(\@identifyID, $invIndex);
		}
		print "請輸入 'identify' 查看可鑑定物品清單\n";

	} elsif ($switch eq "0179" && length($msg) >= 5) {
		$index = unpack("S*",substr($msg, 2, 2));
		undef $invIndex;
		$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
		$chars[$config{'char'}]{'inventory'}[$invIndex]{'identified'} = 1;
		print "物品鑑定成功\: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}\n";
		undef @identifyID;
		$msg_size = 5;

	} elsif ($switch eq "017F" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S*", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		$ID = substr($msg, 4, 4);
		$chat = substr($msg, 4, $msg_size - 4);
		($chatMsgUser, $chatMsg) = $chat =~ /([\s\S]*?) : ([\s\S]*)\000/;

		event_chat("g", $chatMsgUser, $chatMsg, $ID);

#		chatLog("公會", "$chatMsgUser : $chatMsg", "g");
#		$ai_cmdQue[$ai_cmdQue]{'type'} = "g";
#		$ai_cmdQue[$ai_cmdQue]{'ID'} = $ID;
#		$ai_cmdQue[$ai_cmdQue]{'user'} = $chatMsgUser;
#		$ai_cmdQue[$ai_cmdQue]{'msg'} = $chatMsg;
#		$ai_cmdQue[$ai_cmdQue]{'time'} = time;
#		$ai_cmdQue++;
#		printC("[公會] $chatMsgUser : $chatMsg\n", "g");
#		# Beep on Event
#		playWave("sounds/G.wav") if ($config{'beep'} && $config{'beep_G'});
#		# Avoid GM
#		avoidGM("", $chatMsgUser, "在公會頻道發言", 0);

	} elsif ($switch eq "0180" && length($msg) >= 6) {
		$msg_size = 6;

	} elsif ($switch eq "0181") {
		$type = unpack("C1", substr($msg, 2, 1));

#		if ($type == 1) {
#			print "You have more allies.\n";
#		} elsif ($type == 2) {
#			print "This guild is already in list.\n";
#		} else {
#			print "0181, TYPE: $type\n";
#		}

		printC(getMsgStrings($switch, $type, 0, 2)."\n", "alert");
#Karasu Start
	} elsif ($switch eq "0182" && length($msg) >= 106) {
		# player joins your guild
		$ID = substr($msg, 2, 4);

		if ($ID eq $accountID) {
#			printC("你加入公會 [$incomingGuild{'name'}]\n", "gm");

			printC("gm", "成員", "你加入公會 [$incomingGuild{'name'}]\n", 1);

			undef %incomingGuild;
		} else {
			my $guildMember;
			($guildMember) = substr($msg, 82, 24) =~ /([\s\S]*?)\000/;

			my $GID = $chars[$config{'char'}]{'guild'}{'ID'};
			my $idx = unpack("L1", substr($msg, 28, 4));

			my $t_accountID	= substr($msg, 2, 4);
			my $t_sex	= unpack("S1",substr($msg, 14, 2));
			my $t_jobID	= unpack("S1", substr($msg, 16, 2));
			my $t_lv	= unpack("S1", substr($msg, 18, 2));

			if ($GID) {
				undef %{$guild{$GID}{'member'}[$idx]};
				$guild{$GID}{'member'}[$idx]{'accountID'}	= $t_accountID;
				$guild{$GID}{'member'}[$idx]{'nameID'}		= substr($msg, 6, 4);
				$guild{$GID}{'member'}[$idx]{'sex'}		= $t_sex;
				$guild{$GID}{'member'}[$idx]{'jobID'}		= $t_jobID;
				$guild{$GID}{'member'}[$idx]{'lv'}		= $t_lv;
				$guild{$GID}{'member'}[$idx]{'exp'}		= unpack("L1", substr($msg, 20, 4));
				$guild{$GID}{'member'}[$idx]{'online'}		= unpack("L1", substr($msg, 24, 4));
	#			$guild{$GID}{'member'}[$idx]{'online'}		= unpack("C1", substr($msg, 24, 1));
				$guild{$GID}{'member'}[$idx]{'position'}	= unpack("L1", substr($msg, 28, 4));
				($guild{$GID}{'member'}[$idx]{'name'})		= $guildMember;

				$guild{$ID}{'members'} = $idx + 1 if ($idx >= $guild{$ID}{'members'});
			}

#			printC("(GID:".unpack("L1", $t_accountID)."/".sprintf("%2d", $t_lv)."等/".getName("job", $t_jobID)."/".getSex($t_sex, 1).") $guildMember 加入你的公會\n", "gm");

			sysLog("gm", "成員", "(GID:".unpack("L1", $t_accountID)."/".sprintf("%2d", $t_lv)."等/".getName("job", $t_jobID)."/".getSex($t_sex, 1).") $guildMember 加入你的公會\n", 1);

		}

		$msg_size = 106;
#Karasu End

	} elsif ($switch eq "0183" && length($msg) >= 10) {
		$msg_size = 10;

	} elsif ($switch eq "0184" && length($msg) >= 10) {
		$msg_size = 10;

	} elsif ($switch eq "0185" && length($msg) >= 34) {
		$msg_size = 34;

	} elsif ($switch eq "0187" && length($msg) >= 6) {

		# 0187 - long ID
		# I'm not sure what this is. In inRO this seems to have something
		# to do with logging into the game server, while on
		# oRO it has got something to do with the sync packet.
		if ($config{serverType} != 0) {
			my $ID = substr($msg, 2, 4);
			if ($ID == $accountID) {
#				$timeout{ai_sync}{time} = time;
				timeOutStart('ai_sync');
				sendSync(\$remote_socket);
				print "Sync packet requested\n" if ($config{'debug'});
			} else {
				print "Sync packet requested for wrong ID\n";
			}
		}

		if (!$option{'X-Kore'} && 0) {
			sleep(0.5);
			sendPasswordEp10(0, $sc_v{'kore'}{'023B'}{'key'});
		}

		$msg_size = 6;

	} elsif ($switch eq "0188" && length($msg) >= 8) {
		$fail = unpack("S1",substr($msg, 2, 2));
		$index = unpack("S1",substr($msg, 4, 2));
		$enchant = unpack("C1",substr($msg, 6, 1));
		if ($fail) {
			printC("精鍊失敗！\n", "0188");
		} else {
			undef $invIndex;
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			if ($enchant - $chars[$config{'char'}]{'inventory'}[$invIndex]{'refined'} > 0) {
				printC("精鍊成功\！\n", "0188");
			}
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'refined'} = $enchant;
			# Need re-modify item name
			$chars[$config{'char'}]{'inventory'}[$invIndex]{'name'}
				= ($items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}} ne "")
				? $items_lut{$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'}}
				: "不明物品 ".$chars[$config{'char'}]{'inventory'}[$invIndex]{'nameID'};
			modifyName(\%{$chars[$config{'char'}]{'inventory'}[$invIndex]});
		}
			$msg_size = 8;

	} elsif ($switch eq "0189" && length($msg) >= 4) {
		# 無法使用傳送之區域
		print "無法使用傳送移動的地區\n";
#		undef $ai_v{'temp'}{'teleOnEvent'};
#		undef $sc_v{'temp'}{'teleOnEvent'};

		checkTimeOut(-1, 'ai_teleport_event');

		if ($chars[$config{'char'}]{'sendTeleport'} == 1 && $map_control{lc($field{'name'})}{'teleport_allow'}) {
			$map_control{lc($field{'name'})}{'teleport_allow'} == 2;
		} elsif ($chars[$config{'char'}]{'sendTeleport'} == 2 && $map_control{lc($field{'name'})}{'teleport_allow'}) {
			$map_control{lc($field{'name'})}{'teleport_allow'} == 0;
		}

		$msg_size = 4;

	} elsif ($switch eq "018A" && length($msg) >= 4) {
		$msg_size = 4;

	} elsif ($switch eq "018B" && length($msg) >= 4) {

		print getMsgStrings($switch, 0, 0, 2)."\n";

	} elsif ($switch eq "018C" && length($msg) >= 29) {

		undef %{$sc_v{'sense'}};

		$sc_v{'sense'}{'nameID'}	= unpack("S1", substr($msg, 2, 2));
		$sc_v{'sense'}{'level'}		= unpack("S1", substr($msg, 4, 2));
		$sc_v{'sense'}{'size'}		= unpack("S1", substr($msg, 6, 2));
		$sc_v{'sense'}{'hp'}		= unpack("L1", substr($msg, 8, 4));
		$sc_v{'sense'}{'def'}		= unpack("S1", substr($msg, 12, 2));
		$sc_v{'sense'}{'element'}	= unpack("S1", substr($msg, 14, 2));
		$sc_v{'sense'}{'mdef'}		= unpack("S1", substr($msg, 16, 2));
		$sc_v{'sense'}{'element_def'}	= unpack("S1", substr($msg, 18, 2));
		$sc_v{'sense'}{'e_ice'}		= unpack("C1", substr($msg, 20, 1));
		$sc_v{'sense'}{'e_earth'}	= unpack("C1", substr($msg, 21, 1));
		$sc_v{'sense'}{'e_fire'}	= unpack("C1", substr($msg, 22, 1));
		$sc_v{'sense'}{'e_wind'}	= unpack("C1", substr($msg, 23, 1));
		$sc_v{'sense'}{'e_poison'}	= unpack("C1", substr($msg, 24, 1));
		$sc_v{'sense'}{'e_holy'}	= unpack("C1", substr($msg, 25, 1));
		$sc_v{'sense'}{'e_dark'}	= unpack("C1", substr($msg, 26, 1));
		$sc_v{'sense'}{'e_spirit'}	= unpack("C1", substr($msg, 27, 1));
		$sc_v{'sense'}{'e_undead'}	= unpack("C1", substr($msg, 28, 1));

#8C 01 1A 04 04 00 00 00    53 00 00 00 03 00 02 00
#0B 00 17 00 96 32 19 64    64 64 64 64 64

#8C 01 59 04 03 00 01 00    37 00 00 00 03 00 03 00
#01 00 17 00 96 32 19 64    64 64 64 64 64
		# 怪物情報
		$msg_size = 29;

	} elsif ($switch eq "018D" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @makeID;
		my ($i, $ID);

		for ($i = 4; $i < $msg_size; $i += 8) {
			$ID = unpack("S1",substr($msg, $i, 2));
			binAdd(\@makeID, $ID);
		}
		# Auto-make smart select

		if ($ai_v{'useSelf_smartAutomake'} || 1) {

#			print "$config{'useSelf_smartAutomake'}";

			undef $ai_v{'useSelf_smartAutomake'};
			for ($i = 0; $i < @makeID; $i++) {
				next if ($makeID[$i] eq "");

#				print "$i $items_lut{$makeID[$i]}\n";

				if (existsInList($items_lut{$makeID[$i]}, $config{'useSelf_smartAutomake'})) {
					sendItemCreate(\$remote_socket, $makeID[$i]);
					last;
				}
			}
		}

		print "請輸入 'make' 查看可鍛冶物品/配製藥瓶清單\n";

#		parseInput("make");


	} elsif ($switch eq "018F" && length($msg) >= 6) {
		$type = unpack("C1", substr($msg, 2, 1));
		$ID = unpack("S1", substr($msg, 4, 2));
		$display = $items_lut{$ID};
		# 以下為自己之訊息(鍛冶不包括精鍊, 精鍊在0188)

		my $tmpMsg;

		if ($type == 0) {
			$tmpMsg = "鍛冶 $display 成功\！\n";
		} elsif ($type == 1) {
			$tmpMsg = "鍛冶 $display 失敗！\n";
		} elsif ($type == 2) {
			$tmpMsg = "配製 $display 成功\！\n";
		} elsif ($type == 3) {
			$tmpMsg = "配製 $display 失敗！\n";
		}

		printC($tmpMsg, "make");

		$msg_size = 6;

#Karasu Start
	} elsif ($switch eq "0191" && length($msg) >= 86) {
		# talkie box message
		$ID = substr($msg, 2, 4);
		($message) = substr($msg, 6, 80) =~ /(.*?)\000/;
		print "留言盒 : $message\n";
		$msg_size = 86;
#Karasu End

	} elsif ($switch eq "0192" && length($msg) >= 24) {
		$msg_size = 24;

#Karasu Start
	} elsif ($switch eq "0194" && length($msg) >= 30) {
		$CID = substr($msg, 2, 4);
		($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
#		$charID_lut{$CID} = $name;
#		if ($players{$CID}{'online'} ne "") {
#			my $online_string = ($players{$CID}{'online'}) ? "上線了" : "離線了";
#			printC("公會成員 ($name) $online_string\n", "g");
#			undef $players{$CID}{'online'};
#		}
		$msg_size = 30;

		event_online($switch, $CID, "", $name);
#Karasu End

	} elsif ($switch eq "0195" && length($msg) >= 102) {
		$ID = substr($msg, 2, 4);
		$AID = unpack("S*", $ID);
		($name) = substr($msg, 6, 24) =~ /([\s\S]*?)\000/;
		if (%{$players{$ID}}) {
			$players{$ID}{'name'} = $name;
			($players{$ID}{'party'}{'name'}) = substr($msg, 30, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'guild'}{'name'}) = substr($msg, 54, 24) =~ /([\s\S]*?)\000/;
			($players{$ID}{'guild'}{'men'}{$players{$ID}{'name'}}{'title'}) = substr($msg, 78, 24) =~ /([\s\S]*?)\000/;
			print "Player Info: $players{$ID}{'name'} ($players{$ID}{'binID'})\n" if ($config{'debug'} >= 2);
		}
		# Record player data
		recordPlayerData($ID) if ($config{'recordPlayerInfo'});
		# Avoid GM
		avoidGM($ID, $name, "出現在你附近", 1);
#Karasu Start
		# Avoid specified player
		avoidPlayer($ID);
#Karasu End
		$msg_size = 102;

#Karasu Start(EP 3.0)
	} elsif ($switch eq "0196" && length($msg) >= 9) {
		# Status icon
		$type = unpack("C1", substr($msg, 2, 2));
		$targetID = substr($msg, 4, 4);
		$on = unpack("C1", substr($msg, 8, 1));
		my @messages = split(/::/, $messages_lut{$switch}{$type});
		my $targetDisplay = "";

		if ($targetID eq $accountID) {
			if (
				(
					$on eq "1"
					&& binFind(\@{$chars[$config{'char'}]{'status'}}, $type) eq ""
					&& !existsInList($config{'hideMsg_charStatus'}, $type)
					&& $config{'hideMsg_charStatus'} ne "all"
					&& $type != 27
					&& $type != 28
				)
				|| $config{'debug'}
			) {
				if ($type == 35 || $type == 36) {
					printC("[持續狀態] $messages[$on]\n", "alert");
				} else {
					if ($messages[$on] ne "") {
						printC("[持續狀態] $messages[$on]\n", "status");
					} else {
						printC("[持續狀態] 已變成不明狀態 $type\n", "status");
					}
				}
			} elsif (($on eq "0" && binFind(\@{$chars[$config{'char'}]{'status'}}, $type) ne ""
						&& !existsInList($config{'hideMsg_charStatus'}, $type) && $config{'hideMsg_charStatus'} ne "all")
						|| $config{'debug'}) {
				if ($messages[$on] ne "") {
					printC("[持續狀態] $messages[$on]\n", "status");
				} else {
					printC("[持續狀態] 不明狀態 $type 已解除\n", "status");
				}
			}
			binRemoveAndShift(\@{$chars[$config{'char'}]{'status'}}, $type);
			push @{$chars[$config{'char'}]{'status'}}, $type if $on;
			if ($config{'equipAuto_aspersio'} && $type == 17 && $on eq "1") {
				undef $eqBack;
				for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
					next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} eq "");
					if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} & 2) {
#						print "◆惡意洒水: 可能遭到惡意洒水, 重新裝備武器！\n";
#						chatLog("危險", "惡意洒水: 可能遭到惡意洒水, 重新裝備武器！", "d");

						sysLog("event", "危險", "惡意洒水: 可能遭到惡意洒水, 重新裝備武器！", 1);

						$eqBack = $i;
						sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'});
						last;
					}
				}
				parseInput("eq $eqBack") if ($eqBack ne "");
			}
		} elsif (%{$players{$targetID}}) {
			$targetDisplay = "$players{$targetID}{'name'} ($players{$targetID}{'binID'})";
			if (binFind(\@$partyUsersID, $targetID) ne "") {
				if (($on eq "1" && binFind(\@{$chars[$config{'char'}]{'party'}{'users'}{$targetID}{'status'}}, $type) eq ""
					&& !existsInList($config{'hideMsg_partyStatus'}, $type) && $config{'hideMsg_partyStatus'} ne "all")
					|| $config{'debug'}) {
					if ($messages[$on] ne "") {
						printC("[持續狀態] 隊員 $targetDisplay $messages[$on]\n", "status");
					} else {
						printC("[持續狀態] 隊員 $targetDisplay 已變成不明狀態 $type\n", "status");
					}
				} elsif (($on eq "0" && binFind(\@{$chars[$config{'char'}]{'party'}{'users'}{$targetID}{'status'}}, $type) ne ""
					&& !existsInList($config{'hideMsg_partyStatus'}, $type) && $config{'hideMsg_partyStatus'} ne "all")
					|| $config{'debug'}) {
					if ($messages[$on] ne "") {
						printC("[持續狀態] 隊員 $targetDisplay $messages[$on]\n", "status");
					} else {
						printC("[持續狀態] 隊員 $targetDisplay 不明狀態 $type 已解除\n", "status");
					}
				}
				binRemoveAndShift(\@{$chars[$config{'char'}]{'party'}{'users'}{$targetID}{'status'}}, $type);
				push @{$chars[$config{'char'}]{'party'}{'users'}{$targetID}{'status'}}, $type if $on;
      			}

      			binRemoveAndShift(\@{$players{$targetID}{'status'}}, $type);
			push @{$players{$targetID}{'status'}}, $type if $on;
		} elsif (%{$monsters{$ID}}) {
			$targetDisplay = "$monsters{$targetID}{'name'} ($monsters{$targetID}{'binID'})";
		} else {
			$targetDisplay = "不明人物";
		}
		print "[持續狀態] $targetDisplay $messages[$on]\n" if ($config{'debug'} && $targetID ne $accountID && binFind(\@$partyUsersID, $targetID) eq "");
		$msg_size = 9;
#Karasu End(EP 3.0)

	} elsif ($switch eq "0199" && length($msg) >= 4) {
		# PVP mode start(PVP=1, GVG=3)
		$mode = unpack("S1", substr($msg, 2, 2));
		undef $display;
		if ($mode == 1) {
			$display = "PVP 模式";
		} elsif ($mode == 3) {
			$display = "GVG 模式";
		} else {
			$display = "不明模式 $mode";
		}
		printC("你進入 $display！\n", "s");
		$chars[$config{'char'}]{'pvp'}{'start'} = $mode;
		$msg_size = 4;

	} elsif ($switch eq "019A" && length($msg) >= 14) {
		# PVP rank
		$ID = substr($msg, 2, 4);
		$rank = unpack("L1", substr($msg, 6, 4));
		$num = unpack("L1", substr($msg, 10, 4));
		if ($ID eq $accountID) {
			$chars[$config{'char'}]{'pvp'}{'rank_num'} = "$rank / $num";
			printC("＠你目前排名 $chars[$config{'char'}]{'pvp'}{'rank_num'}！\n", "g");
		}
		$msg_size = 14;

	} elsif ($switch eq "019B" && length($msg) >= 10) {
		$ID = substr($msg, 2, 4);
		$type = unpack("L1", substr($msg, 6, 4));
#		undef $display;
#		if ($type == 0) {
#			$display = "的基本等級上升了！";
#		} elsif ($type == 1) {
#			$display = "的職業等級上升了！";
#		# 以下為其它玩家之訊息(另見018F)
#		} elsif ($type == 2) {
#			$display = "鍛冶(精鍊)失敗了！";
#		} elsif ($type == 3) {
#			$display = "鍛冶(精鍊)成功\了！";
#		} elsif ($type == 5) {
#			$display = "配藥成功\了！";
#		} elsif ($type == 6) {
#			$display = "配藥失敗了！";
#		}

		my $display = getMsgStrings($switch, $type, 0, 2)."！";

		if ($ID eq $accountID) {
			print "你$display\n";
			$sc_v{'exp'}{'lv_up'} = 1 if ($type == 0);
			$sc_v{'exp'}{'lv_job_up'} = 1 if ($type == 1);
#		} elsif (%{$players{$ID}}) {
#			print "$players{$ID}{'name'} $display\n" if ($config{'debug'} || 1);
		} else {
#			$name = "不明人物 $display\n" if ($config{'debug'});

			print getName("player", $ID, 0, -1)." $display\n";
		}
		$msg_size = 10;

	} elsif ($switch eq "019E" && length($msg) >= 2) {
		# When you use a item which can catch a pet will receive this packet
		# Then you can sendPetCatch(019F)
		$msg_size = 2;

#Karas Start
	} elsif ($switch eq "01A0" && length($msg) >= 3) {
		# Judge get a pet
		$fail = unpack("C1", substr($msg, 2, 1));
		if (!$fail) {
			print "捕抓寵物 - 失敗！\n";
		} else {
			print "捕抓寵物 - 成功\！\n";
		}
		$msg_size = 3;

	} elsif ($switch eq "01A2" && length($msg) >= 35) {
		#pet status
		# 01A2 <name>.24B <flag>.B <lvl>.w <hunger>.w <imtimate>.w <accessoryID>.w
		($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		$chars[$config{'char'}]{'pet'}{'online'} = 1;
		$chars[$config{'char'}]{'pet'}{'modified'} = unpack("C1", substr($msg, 26, 1));
		$chars[$config{'char'}]{'pet'}{'name_given'} = $name;
		$chars[$config{'char'}]{'pet'}{'lvl'} = unpack("S1", substr($msg, 27, 2));
		$chars[$config{'char'}]{'pet'}{'hunger'} = unpack("S1", substr($msg, 29, 2));
		$chars[$config{'char'}]{'pet'}{'intimate'} = unpack("S1", substr($msg, 31, 2));
		$chars[$config{'char'}]{'pet'}{'accessory'} = unpack("S1", substr($msg, 33, 2));
		$msg_size = 35;

	} elsif ($switch eq "01A3" && length($msg) >= 5) {
		# Pet Feed
		$fail = unpack("C1", substr($msg, 2, 1));
		$ID = unpack("S1", substr($msg, 3, 2));
		if (!$fail) {
			# Pet-auto feed
			if ($config{'petAuto_feed'} && $chars[$config{'char'}]{'pet'}{'feed'}) {
				sendPetCommand(\$remote_socket, 3);
#				print "◆重要訊息: 飼料 $items_lut{$ID} 已用完, 將寵物回復成蛋的狀態！";
#				chatLog("重要", "重要訊息: 飼料 $items_lut{$ID} 已用完, 將寵物回復成蛋的狀態！", "im");

				sysLog("pet", "重要", "◆重要訊息: 飼料 $items_lut{$ID} 已用完, 將寵物回復成蛋的狀態！", 1);
			} elsif ($config{'petAuto_protect'}) {
				sendPetCommand(\$remote_socket, 3);
				sysLog("pet", "重要", "你沒有飼料: $items_lut{$ID} 可以餵食你的寵物, 將寵物回復成蛋的狀態！", 1);
			} else {
				sysLog("pet", "重要", "你沒有飼料: $items_lut{$ID} 可以餵食你的寵物！", 1);
			}
		}
		undef $chars[$config{'char'}]{'pet'}{'feed'};
		$msg_size = 5;

	} elsif ($switch eq "01A4" && length($msg) >= 11) {
		# Pet spawn
		$type = unpack("C1",substr($msg, 2, 1));
		$ID = substr($msg, 3, 4);
		$val = unpack("L1", substr($msg, 7, 4));
		if ($type == 0x00) {
			$chars[$config{'char'}]{'pet'}{'ID'} = $ID;
			$chars[$config{'char'}]{'pet'}{'online'} = 1;
			if ($callInvIndex ne "") {
				$chars[$config{'char'}]{'inventory'}[$callInvIndex]{'borned'} = 1;
				undef $callInvIndex;
			}
			undef @callID;
		} elsif ($type == 0x01) {
			# Pet intimately
			if (!$config{'hideMsg_petStatus'} || $config{'debug'}) {
				if ($val - $chars[$config{'char'}]{'pet'}{'intimate'} >= 0) {
					print "你的寵物親密度上升 $val/1000\n";
				} else {
					print "你的寵物親密度下降 $val/1000\n";
				}
			}
			$chars[$config{'char'}]{'pet'}{'intimate'} = $val;
			# Pet-auto return
			if ($val >= $config{'petAuto_return'} && $config{'petAuto_return'}){
				print "◆重要訊息: 你的寵物親密度($val)高於設定值($config{'petAuto_return'})！\n";
				print "◆啟動 petAuto_return - 將寵物回復成蛋的狀態！\n";
#				chatLog("重要", "重要訊息: 你的寵物親密度($val)高於設定值($config{'petAuto_return'}), 將寵物回復成蛋的狀態！", "im");
				sysLog("pet", "重要", "重要訊息: 你的寵物親密度($val)高於設定值($config{'petAuto_return'}), 將寵物回復成蛋的狀態！");
				sendPetCommand(\$remote_socket, 3);
			# Pet-auto protect
			} elsif ($val <= $config{'petAuto_intimate_lower'} && $config{'petAuto_intimate_lower'}) {
				print "◆重要訊息: 你的寵物親密度($val)低於設定值($config{'petAuto_intimate_lower'})！\n";
				print "◆啟動 petAuto_protect - 將寵物回復成蛋的狀態！\n";
#				chatLog("重要", "重要訊息: 你的寵物親密度($val)低於危險值(100), 將寵物回復成蛋的狀態！", "im");
				sysLog("pet", "重要", "重要訊息: 你的寵物親密度($val)低於設定值($config{'petAuto_intimate_lower'}), 將寵物回復成蛋的狀態！");
				sendPetCommand(\$remote_socket, 3);
			} elsif ($val <= 100 && $config{'petAuto_protect'}) {
				print "◆重要訊息: 你的寵物親密度($val)低於危險值(100)！\n";
				print "◆啟動 petAuto_protect - 將寵物回復成蛋的狀態！\n";
#				chatLog("重要", "重要訊息: 你的寵物親密度($val)低於危險值(100), 將寵物回復成蛋的狀態！", "im");
				sysLog("pet", "重要", "重要訊息: 你的寵物親密度($val)低於危險值(100), 將寵物回復成蛋的狀態！");
				sendPetCommand(\$remote_socket, 3);
			}
		} elsif ($type == 0x02) {
			# Pet hunger
			if (!$config{'hideMsg_petStatus'} || $config{'debug'}) {
				if ($val - $chars[$config{'char'}]{'pet'}{'hunger'} >= 0) {
					print "你的寵物滿足感上升 $val/100\n";
				} else {
					print "你的寵物滿足感下降 $val/100\n";
				}
			}
			# Pet-auto feed
			if ($val <= $config{'petAuto_feed'} && $config{'petAuto_feed'}){
				print "◆重要訊息: 你的寵物滿足感($val)低於設定值($config{'petAuto_feed'})\n";
				print "◆啟動 petAuto_feed - 自動餵食飼料\n";
#				chatLog("重要", "重要訊息: 你的寵物滿足感($val)低於設定值($config{'petAuto_feed'}), 自動餵食飼料！", "im");
				sysLog("pet", "重要", "重要訊息: 你的寵物滿足感($val)低於設定值($config{'petAuto_feed'}), 自動餵食飼料！");
				$chars[$config{'char'}]{'pet'}{'feed'} = 1;
				sendPetCommand(\$remote_socket, 1);

				$record{'counts'}{'petAuto'}++;
			}
			$chars[$config{'char'}]{'pet'}{'hunger'} = $val;
			# Pet-auto protect
			if ($val <= 10 && $config{'petAuto_protect'}) {
				print "◆重要訊息: 你的寵物滿足感($val)低於危險值(10)！\n";
				print "◆啟動 petAuto_protect - 將寵物回復成蛋的狀態！\n";
#				chatLog("重要", "重要訊息: 你的寵物滿足感($val)低於危險值(10), 將寵物回復成蛋的狀態！", "im");
				sysLog("pet", "重要", "重要訊息: 你的寵物滿足感($val)低於危險值(10), 將寵物回復成蛋的狀態！");
				sendPetCommand(\$remote_socket, 3);
				$record{'counts'}{'petAuto_protect'}++;
			}
		} elsif ($type == 0x03) {
			# Pet equip accessory
			if (!$val){
				if ($ID eq $chars[$config{'char'}]{'pet'}{'ID'}) {
					if ($chars[$config{'char'}]{'pet'}{'accessory'}) {
						print "$pets{$ID}{'name_given'} 卸下 $items_lut{$chars[$config{'char'}]{'pet'}{'accessory'}}\n";
						$chars[$config{'char'}]{'pet'}{'accessory'} = "";
					} else {
						print "你的寵物沒有佩戴裝飾品\n";
					}
				} else {
					print "$pets{$ID}{'name_given'} 卸下裝飾品\n" if ($config{'debug'});
				}
			} else {
				if ($ID eq $chars[$config{'char'}]{'pet'}{'ID'}) {
					print "$pets{$ID}{'name_given'} 裝備上 $items_lut{$val}\n";
					$chars[$config{'char'}]{'pet'}{'accessory'} = $val;
				} else {
					print "$pets{$ID}{'name_given'} 裝備上 $items_lut{$val}\n" if ($config{'debug'});
				}
			}
		} elsif ($type == 0x04) {
			# Pet show
			if ($ID eq $chars[$config{'char'}]{'pet'}{'ID'}) {
				print "你的寵物 $pets{$ID}{'name'} 正賣力的表演[$val]\n";
			} else {
				print "$pets{$ID}{'name_given'} 正賣力的表演\n" if ($config{'debug'});
			}

		} elsif ($type == 0x05) {
			if (!%{$pets{$ID}}) {
				binAdd(\@petsID, $ID);
				%{$pets{$ID}} = %{$monsters{$ID}};
				$pets{$ID}{'name_given'} = "不明寵物";
				$pets{$ID}{'binID'} = binFind(\@petsID, $ID);
			}
			if (%{$monsters{$ID}}) {
				binRemove(\@monstersID, $ID);
				undef %{$monsters{$ID}};
			}
			if ($ID eq $chars[$config{'char'}]{'pet'}{'ID'}) {
				$chars[$config{'char'}]{'pet'}{'name'} = $pets{$ID}{'name'};
				print "你的寵物 - $chars[$config{'char'}]{'pet'}{'name'} 出現在你身邊\n";
			}
			print "Pet Spawned: $pets{$ID}{'name'} ($pets{$ID}{'binID'})\n" if ($config{'debug'});
		} else {
			print "[$switch] Pet: type= $type, ID= $ID, val= $val\n";
		}
		$msg_size = 11;

	} elsif ($switch eq "01A6" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @callID;
		undef $invIndex;
		for ($i = 4; $i < $msg_size; $i += 2) {
			$index = unpack("S1", substr($msg, $i, 2));
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			binAdd(\@callID, $invIndex);
		}
		print "請輸入 'call' 查看可孵化寵物蛋清單\n";

	} elsif ($switch eq "01AA" && length($msg) >= 10) {
		#pet emotion
		# 01AA <ID>.l <emotion>.w <?>.w
		$ID = substr($msg, 2, 4);
#		$type = unpack("S1", substr($msg, 6, 2));
#
#		$type2 = unpack("S1", substr($msg, 8, 2));
#
#		if ($type < 48) {
#			if ($ID eq $chars[$config{'char'}]{'pet'}{'ID'} && (!existsInList2($config{'hideMsg_emotion'}, 1, "and") || $config{'debug'})) {
#				printC("[表情] 你的寵物做了個表情 : $emotions_lut{$type} [$type2]\n", "e");
#			} elsif (!existsInList2($config{'hideMsg_emotion'}, 4, "and") || $config{'debug'}) {
#				printC("[表情] 寵物 $pets{$ID}{'name_given'} ($pets{$ID}{'binID'}) : $emotions_lut{$type} [$type2]\n", "e");
#			}
#		}

		$type = unpack("S1", substr($msg, 6, 4));

		if ($type < 48) {
			if ($ID eq $chars[$config{'char'}]{'pet'}{'ID'} && (!existsInList2($config{'hideMsg_emotion'}, 1, "and") || $config{'debug'})) {
				printC("[表情] 你的寵物做了個表情 : $emotions_lut{$type}\n", "e");
			} elsif (!existsInList2($config{'hideMsg_emotion'}, 4, "and") || $config{'debug'}) {
				printC("[表情] 寵物 $pets{$ID}{'name_given'} ($pets{$ID}{'binID'}) : $emotions_lut{$type}\n", "e");
			}
		} else {
			if ($ID eq $chars[$config{'char'}]{'pet'}{'ID'} && (!existsInList2($config{'hideMsg_emotion'}, 1, "and") || $config{'debug'})) {
				printC("[寵物] 你的寵物 $pets{$ID}{'name_given'} ($pets{$ID}{'binID'}) : $type\n", "e");
			} elsif (!existsInList2($config{'hideMsg_emotion'}, 4, "and") || $config{'debug'}) {
				printC("[寵物] $pets{$ID}{'name_given'} ($pets{$ID}{'binID'}) : $type\n", "e");
			}
		}

		$msg_size = 10;
#Karasu End

#Ayon Start(不明封包)
	} elsif ($switch eq "01AB" && length($msg) >= 12) {
		# 禁言
		$ID = substr($msg, 2, 4);
		$type = unpack("S1", substr($msg, 6, 2));
		$value = unpack("l1", substr($msg, 8, 4));
		$value = abs($value);
		undef $display;
		if (%{$players{$ID}}) {
			$display = "$players{$ID}{'name'} ($players{$ID}{'binID'}) ";
		} else {
			$display = "不明人物 ";
		}
		print "$display的禁言限制($type)還剩下 $value分鐘！\n";
		$msg_size = 12;

	} elsif ($switch eq "01AC" && length($msg) >= 6) {
#		MessyKoreXP //

		$ID = substr($msg, 2, 4);
		$time = unpack("L1",substr($msg, 2, 4));

#		print getHex($ID)." - ".$time."\n";
#		print "01AC: LONG $time, NAME ".Name($ID)."\n";

		if (binFind(\@monstersID, $ai_seq_args[0]{'ID'}) ne "") {
			$monsters{$ai_seq_args[0]{'ID'}}{'StoporSnare'} = 1;
#			PrintMessage($monsters{$ai_seq_args[0]{'ID'}}{'name'}." Stop or Snare.", "green");
		} elsif (binFind(\@playersID, $ai_seq_args[0]{'ID'}) ne "") {
			$players{$ai_seq_args[0]{'ID'}}{'StoporSnare'} = 1;
#			PrintMessage($players{$ai_seq_args[0]{'ID'}}{'name'}." Stop or Snare.", "green");
		}

#		print "01AC: LONG $time, NAME ".Name($ID)."\n";
#		// MessyKoreXP

		$msg_size = 6;
#Ayon Start(不明封包)

#Karasu Start
	# Make arrow
	} elsif ($switch eq "01AD" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		undef @arrowID;

		my $i;

		for ($i = 4; $i < $msg_size; $i += 2) {
			$ID = unpack("S1", substr($msg, $i, 2));
			binAdd(\@arrowID, $ID);
		}

		# Auto-make smart select

		if ($ai_v{'useSelf_smartAutoarrow'}) {
			undef $ai_v{'useSelf_smartAutoarrow'};
			for ($i = 0; $i < @arrowID; $i++) {
				next if ($arrowID[$i] eq "");

#				print existsInList($config{'useSelf_skill_smartAutoarrow_item'}, getName("items_lut", $arrowID[$i]))." ".getName($arrowID[$i])."\n";

				if (existsInList($config{'useSelf_smartAutoarrow'}, getName("items_lut", $arrowID[$i]))) {
					sendArrowMake(\$remote_socket, $arrowID[$i]);
					last;
				}
			}
		}

		print "請輸入 'arrow' 查看可製作箭矢物品清單\n";
#Karasu End

#Karasu Start
	} elsif ($switch eq "01B0" && length($msg) >= 11) {
		#01b0 <monster id>.l <?>.b <new monster code>.l
		#monster Type Change

		my $ID = substr($msg,2,4);
		my $type = unpack("L1", substr($msg, 7, 4));

		my $name;

		if (!%{$monsters{$ID}}) {
			$monsters{$ID}{'appear_time'} = time;
			binAdd(\@monstersID, $ID);
			$monsters{$ID}{'binID'} = binFind(\@monstersID, $ID);

			$name = "不明人物";
		} else {

			$name = "$monsters{$ID}{'name'}";

		}

		$monsters{$ID}{'nameID'} = $type;
		$monsters{$ID}{'name'} = getName("mon", $type);

		printC("$name ($monsters{$ID}{'binID'}) 變化成 $monsters{$ID}{'name'}\n", "alert");

		$msg_size = 11;
#Karasu End

#Karasu Start(EP 3.0)
	} elsif ($switch eq "01B3" && length($msg) >= 67) {
		#NPC image
		$npc_image = substr($msg, 2, 64);
		$type = unpack("C1", substr($msg, 66, 1));

#		($npc_image) = $npc_image =~ s/[\r\n]//g;
#		($npc_image) = $npc_image =~ /(\S+)/;

		getString(\$npc_image);

		print "NPC image: $npc_image\n" if ($config{'debug'});

		if ($type == 2) {
			print "Show NPC image: ${npc_image}\n";
		} elsif ($type == 255) {
			print "Hide NPC image: ${npc_image}\n";
		} else {
			print "NPC image: ${npc_image} ($type)\n";
		}

		$msg_size = 67;
#Karasu End(EP 3.0)

#Karasu Start(EP 5.0)
	} elsif ($switch eq "01B4" && length($msg) >= 12) {
		$msg_size = 12;
#Karasu End(EP 5.0)
#B4 01 41 DB 00 00 3E 83 00 00 30 00

	} elsif ($switch eq "01B5" && length($msg) >= 18) {
		my $remain = unpack("L1", substr($msg, 2, 4));
		my ($day, $hour, $minute);

		if (!$remain) {
			$remain = unpack("L1", substr($msg, 6, 4));
		}

		$day = int($remain / 1440);
		$remain = $remain % 1440;
		$hour = int($remain / 60);
		$remain = $remain % 60;
		$minute = $remain;

		print "You have Airtime : $day days, $hour hours and $minute minutes\n";

		$chars[$config{'char'}]{'Airtime'}{'day'}	= $day;
		$chars[$config{'char'}]{'Airtime'}{'hour'}	= $hour;
		$chars[$config{'char'}]{'Airtime'}{'minute'}	= $minute;
		$chars[$config{'char'}]{'Airtime'}{'loginat'}	= getFormattedDate(int(time));

		$msg_size = 18;

#Karasu Start
	} elsif ($switch eq "01B6" && length($msg) >= 114) {
		# Guild Information
		$ID = substr($msg, 2, 4);
		$guild{$ID}{'ID'}        = $ID;

		$guild{$ID}{'exp_last'} = $guild{$ID}{'exp'};
		$guild{$ID}{'next_exp_last'} = $guild{$ID}{'next_exp'};

		$guild{$ID}{'lvl'}       = unpack("L1", substr($msg,  6, 4));
		$guild{$ID}{'conMember'} = unpack("L1", substr($msg, 10, 4));
		$guild{$ID}{'maxMember'} = unpack("L1", substr($msg, 14, 4));
		$guild{$ID}{'average'}   = unpack("L1", substr($msg, 18, 4));
		$guild{$ID}{'exp'}       = unpack("L1", substr($msg, 22, 4));
		$guild{$ID}{'next_exp'}  = unpack("L1", substr($msg, 26, 4));
		$guild{$ID}{'offerPoint'} = unpack("L1", substr($msg, 30, 4));
		($guild{$ID}{'name'})    = substr($msg, 46, 24) =~ /([\s\S]*?)\000/;
		($guild{$ID}{'master'})  = substr($msg, 70, 24) =~ /([\s\S]*?)\000/;
		($guild{$ID}{'castle'}) = substr($msg, 94, 20) =~ /([\s\S]*?)\000/;

		undef $sc_v{'exp'}{'guild_add'};

		if ($guild{$ID}{'exp_last'} > $guild{$ID}{'exp'}) {
			$sc_v{'exp'}{'guild_add'} += $guild{$ID}{'next_exp_last'} - $guild{$ID}{'exp_last'} + $guild{$ID}{'exp'};
		} elsif ($guild{$ID}{'exp_last'} && $guild{$ID}{'exp_last'} < $guild{$ID}{'exp'}) {
			$sc_v{'exp'}{'guild_add'} += $guild{$ID}{'exp'} - $guild{$ID}{'exp_last'};
		}

		$sc_v{'exp'}{'guild'} += $sc_v{'exp'}{'guild_add'};

		$msg_size = 114;

	} elsif ($switch eq "01B9" && length($msg) >= 6) {
		$ID = substr($msg, 2, 4);
#		undef $display;
#		if ($ID eq $accountID) {
#			$display = "你";
#			aiRemove("skill_use");
#			undef $chars[$config{'char'}]{'time_cast'};
#			undef $ai_v{'temp'}{'castWait'};
#		} elsif (%{$players{$ID}}) {
#			$display = "$players{$ID}{'name'} ($players{$ID}{'binID'}) ";
#		} elsif (%{$monsters{$ID}}) {
#			$display = "$monsters{$ID}{'name'} ($monsters{$ID}{'binID'}) ";
#		} else {
#			$display = "不明人物 ";
#		}
#		printS("★$display施展的技能已被中斷\n", "", $ID);

		parseSkill($switch, "", $ID);

		$msg_size = 6;
#Karasu End

	} elsif ($switch eq "01C8" && length($msg) >= 13) {
		$index = unpack("S1",substr($msg, 2, 2));
		$ID = unpack("S1", substr($msg, 4, 2));
		$sourceID = substr($msg, 6, 4);
		$amountleft = unpack("S1",substr($msg, 10, 2));
		$amountused = unpack("C1",substr($msg, 12, 1));
		if (!$amountused) {
			undef $invIndex;
			$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
			print "你無法使用物品: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex)\n";
		} else {
			undef $display;
			$display = ($items_lut{$ID} ne "")
				? $items_lut{$ID}
				: "不明物品 ".$ID;
			if ($sourceID eq $accountID) {
				undef $invIndex;
				$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $index);
				$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} = $amountleft;
				print "你使用物品: $chars[$config{'char'}]{'inventory'}[$invIndex]{'name'} ($invIndex) x $amountused - 剩餘數量: $amountleft\n";
				if ($chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} <= 0) {
					undef %{$chars[$config{'char'}]{'inventory'}[$invIndex]};
				}
				undef $chars[$config{'char'}]{'sendItemUse'};
			} elsif (%{$players{$sourceID}}) {
				print "$players{$sourceID}{'name'} ($players{$sourceID}{'binID'}) 使用物品: $display x $amountused  - 剩餘數量: $amountleft\n" if (!$config{'hideMsg_otherUseItem'} || $config{'debug'});
			} else {
				print "不明人物 使用物品: $display x $amountused  - 剩餘數量: $amountleft\n" if (!$config{'hideMsg_otherUseItem'} || $config{'debug'});
			}
		}
		$msg_size = 13;

#Karasu Start
	# EP 5.0 packet
	} elsif ($switch eq "01CD" && length($msg) >= 30) {
		undef @autospellID;
		for ($i = 2; $i < 30; $i += 4) {
			$ID = unpack("S1",substr($msg, $i, 2));
			binAdd(\@autospellID, $ID);
		}
		print "請輸入 'autospell' 查看可選擇技能清單\n";
		# Auto-spell smart select
		if ($ai_v{'useSelf_skill_smartAutospell'} ne "" && binFind(\@autospellID, $ai_v{'useSelf_skill_smartAutospell'}) ne "") {
			sendAutospell(\$remote_socket, $ai_v{'useSelf_skill_smartAutospell'});
			undef $ai_v{'useSelf_skill_smartAutospell'};
		}
		$msg_size = 30;

	} elsif ($switch eq "01CF" && length($msg) >= 28) {
		# 犧牲
		$msg_size = 28;

	} elsif (($switch eq "01D0" || $switch eq "01E1") && length($msg) >= 8) {
		$ID = substr($msg, 2, 4);
		$amount = unpack("S1",substr($msg, 6, 2));
		if ($ID eq $accountID) {
			print "[氣 球 數] 目前擁有 $amount顆氣球\n" if ($chars[$config{'char'}]{'spirits'} != $amount);
			$chars[$config{'char'}]{'spirits'} = $amount;
		}
		$msg_size = 8;

	} elsif ($switch eq "01D1" && length($msg) >= 14) {
		#真劍百破道
		$sourceID = substr($msg, 2, 4);
		$targetID = substr($msg, 6, 4);
		$flag = unpack("S1",substr($msg, 10, 2));
		#$something = unpack("S1",substr($msg, 12, 2));
		$msg_size = 14;

	} elsif ($switch eq "01D2" && length($msg) >= 10) {
		#六合拳
		$sourceID = substr($msg, 2, 4);
		$wait = unpack("L1",substr($msg, 6, 4)) / 1000;
		$msg_size = 10;
#Karasu End

	} elsif ($switch eq "01D4" && length($msg) >= 6) {
		#npc要求輸入文字
		$ID = substr($msg, 2, 4);
		print qq~$npcs{$ID}{'name'}: 請輸入 'talk answer "<文字>"' 輸入欲回應文字, 或輸入 'talk no' 取消對話\n~;
		$msg_size = 6;

	} elsif ($switch eq "01D6" && length($msg) >= 4) {
		$msg_size = 4;

#HaMBo Start
	} elsif ($switch eq "01D7" && length($msg) >= 11) {
		# 武器紙娃娃
      $sourceID = substr($msg, 2, 4);
      # 0=職業(轉換時才會收到), 2=手, 9=腳
      $type = unpack("C1",substr($msg, 6, 1));
      $itemID1 = unpack("S1",substr($msg, 7, 2));
      $itemID2 = unpack("S1",substr($msg, 9, 2));
      $msg_size = 11;
#HaMBo End

#Karasu Start
	# Secure login
	} elsif ($switch eq "01DC" && length($msg) >= 4 && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		$msg_size = unpack("S1", substr($msg, 2, 2));
		$ai_v{'msg01DC'} = substr($msg, 4, $msg_size - 4);
#Karasu End

	# EP 6.0 packet
	} elsif ($switch eq "01E6" && length($msg) >= 26) {
		# 有人使用想念你收到的封包, name為對方的名字
		($name) = substr($msg, 2, 24) =~ /([\s\S]*?)\000/;
		#print "[吶喊] $name 我好想你阿～～～\n";
		$msg_size = 26;

	} elsif ($switch eq "01EA" && length($msg) >= 6) {
		# 女方與國王對話結束完成結婚儀式收到的封包, ID為女方的ID, 可能是放紙片用
		$ID = substr($msg, 2, 4);
		$msg_size = 6;

	# EP 7.0 packet
	} elsif ($switch eq "0201" && length($msg) >= unpack("S1", substr($msg, 2, 2))) {
		# 好友名單資訊
		# 0201 <len>.w {<accID>.l <charID>.l <name>.24B}.32B*
		$msg_size = unpack("S1", substr($msg, 2, 2));
		decrypt(\$newmsg, substr($msg, 4, length($msg)-4));
		$msg = substr($msg, 0, 4).$newmsg;
		$index = 0;

#		undef @friendUsersID;
		undef %friendUsers;

		for ($i = 4; $i < $msg_size; $i+=32) {
			$AID = substr($msg, $i , 4);
			$CID = substr($msg, $i + 4, 4);

			$friendUsers{'AID'}{$AID} = 1;
			$friendUsers{'CID'}{$CID} = 1;

#			if (!%{$chars[$config{'char'}]{'party'}{'users'}{$ID}}) {
#				binAdd(\@partyUsersID, $ID);
#			}

#			binAdd(\@friendUsersID, $ID);

			$sc_v{'friend'}{'member'}[$index]{'AID'} = $AID;
			$sc_v{'friend'}{'member'}[$index]{'CID'} = $CID;
			($sc_v{'friend'}{'member'}[$index]{'name'}) = substr($msg, $i + 8, 24) =~ /([\s\S]*?)\000/;
			print "朋友 ($sc_v{'friend'}{'member'}[$index]{'name'}) 載入好友名單。\n" if ($config{'debug'});

			undef $charID_lut{$CID};

			$charID_lut{$CID} = $sc_v{'friend'}{'member'}[$index]{'name'};
			$charID_lut{$CID}{'online'} = 0;

			$charID_lut{$AID} = $sc_v{'friend'}{'member'}[$index]{'name'} if ($charID_lut{$AID} eq "");

			$index++;
		}

		print "請輸入 'fl' 查看好友名單\n";

	} elsif ($switch eq "0206" && length($msg) >= 11) {
		# 好友上線通知
		# 0206 <accID>.l <charID>.l ?.B
		$ID = substr($msg, 2, 4);
		$CID = substr($msg, 6, 4);
		$index = findIndexString(\@{$sc_v{'friend'}{'member'}}, 'AID', $ID);

		if ($index ne "") {
			$charID_lut{$ID}{'online'} = ($charID_lut{$ID}{'online'}?0:1);
			printC("朋友 ($sc_v{'friend'}{'member'}[$index]{'name'}) ".($charID_lut{$ID}{'online'}?"上":"下")."線了！\n", "g");
		}

		$msg_size = 11;

	} elsif ($switch eq "0207" && length($msg) >= 34) {
		# 收到好友邀請加入名單
		# 0207 <accID>.l <charID>.l <name>.24B
		$invitefriend{'AID'} = substr($msg, 2, 4);
		$invitefriend{'CID'} = substr($msg, 6, 4);
		($invitefriend{'name'}) = substr($msg, 10, 24) =~ /([\s\S]*?)\000/;
		print "(AID:".getID($invitefriend{'AID'})."/CID:".getID($invitefriend{'CID'}).") $invitefriend{'name'} 邀請你加入好友\n";

		timeOutStart('ai_friendAuto');

		$msg_size = 34;

	} elsif ($switch eq "0209" && length($msg) >= 36) {
		#R 0209 <type>.w <accID>.l <charID>.l <name>.24B
		#別人回應加入好友的結果
		#type = 00 同意
		#type = 01 拒絕
		($name) = substr($msg, 12, 24) =~ /([\s\S]*?)\000/;
		$type = unpack("C1", substr($msg, 2, 1));

		$AID = substr($msg, 4 , 4);
		$CID = substr($msg, 8, 4);

#		if ($type == 0){
#			print "與'$name'成為好友\n";
#		} elsif ($type == 1){
#			print "無法與'$name'成為好友\n";
#		}

		my $display;

		if ($type == 0) {
			my $index = @{$sc_v{'friend'}{'member'}};

			$friendUsers{'AID'}{$AID} = 1;
			$friendUsers{'CID'}{$CID} = 1;

			$sc_v{'friend'}{'member'}[$index]{'AID'} = $AID;
			$sc_v{'friend'}{'member'}[$index]{'CID'} = $CID;
			$sc_v{'friend'}{'member'}[$index]{'name'} = $name;

			$display = "與 $name 成為好友\n";
		} elsif ($type==1) {
			$display = "無法與 $name 成為好友\n";
		} elsif ($type==2) {
			$display = "你的好友名單已滿，不能再加入\n";
		} elsif ($type==3) {
			$display = "$name 的好友名單已滿，不能再加入\n";
		}

		sysLog("event", "朋友", $display, 1) if ($display ne "");

#		$msg_size = 36;

	} elsif ($switch eq "020A" && length($msg) >= 10) {
		# 被人家剔除好友名單
		# R 020A <accID>.l <charID>.l

		$ID = substr($msg, 2, 4);
		$CID = substr($msg, 6, 4);

		$index = findIndexString(\@{$sc_v{'friend'}{'member'}}, 'AID', $ID);

		sysLog("event", "朋友", "被 ($sc_v{'friend'}{'member'}[$index]{'name'}) 人家剔除好友名單", 1);

		$friendUsers{'AID'}{$sc_v{'friend'}{'member'}[$index]{'AID'}} = 0;
		$friendUsers{'CID'}{$sc_v{'friend'}{'member'}[$index]{'CID'}} = 0;

		binRemoveAndShiftByIndex(\@{$sc_v{'friend'}{'member'}}, $index);

		$msg_size = 10;

	} elsif ($switch eq "0210" && length($msg) >= 22) {
		# 諸神PVP伺服器戰績
		# R 0210 <accID>.l <charactorID>.l <勝>.l <敗>.l <PVP點數>.l
		my $win = unpack("S1",substr($msg, 10, 2));
		my $lose = unpack("S1",substr($msg, 14, 2));
		my $pvp = unpack("L1",substr($msg, 18, 4));

		print "現場 $win 勝, $lose 敗, PVP點數: $pvp \n";

		$msg_size = 22;

	} elsif ($switch eq "01EB" && length($msg) >= 10) {
		$AID = substr($msg, 2, 4);
		$x = unpack("S1", substr($msg,6, 2));
		$y = unpack("S1", substr($msg,8, 2));

#		$ID = unpack("L1", $ID);

		if ($AID ne "") {
#			sendNameRequest(\$remote_socket, $ID) if (!getName("player", $ID, 1));

			$guildUsers{'AID'}{$AID} = 1;

			$chars[$config{'char'}]{'guild'}{'users'}{$AID}{'ID'}		= $AID;
			$chars[$config{'char'}]{'guild'}{'users'}{$AID}{'pos'}{'x'}	= $x;
			$chars[$config{'char'}]{'guild'}{'users'}{$AID}{'pos'}{'y'}	= $y;
			$chars[$config{'char'}]{'guild'}{'users'}{$AID}{'map'}		= $sc_v{'parseMsg'}{'map'};
			$chars[$config{'char'}]{'guild'}{'users'}{$AID}{'onhere'}	= 1;

			print "Guild member location: ".getID($AID)." $chars[$config{'char'}]{'guild'}{'users'}{$AID}{'name'} - $x, $y\n" if ($config{'debug'} >= 2);
		}
		$msg_size = 10;

	} elsif (switchInput($switch, "023A", "023C", "023E")) {
#		print "[$switch]: $msg_size\n";

		if ($switch eq "023A") {
			print "請輸入倉庫密碼\n";
			if ($config{'storageAuto_password'} ne "" && $sc_v{'input'}{'conState'} >= 5) {
#				my $newmsg = pack("C*", 0x3B, 0x02) . pack("C*", 0x03, 0x00) . toHex($config{'storageAuto_password'}) . toHex('EC 62 E5 39 BB 6B BC 81 1A 60 C0 6F AC CB 7E C8');
#				encrypt(\$remote_socket, $newmsg);
				sendPasswordEp10(1, $config{'storageAuto_password'});
			}
		} elsif ($switch eq "023E") {
			print "請輸入角色密碼\n";

#			dumpData($msg);

#			sleep(0.5);

			sendPasswordEp10(1, $config{'char_password'}) if ($config{'char_password'} ne "" && !$option{'X-Kore'});

#			dumpData($msg, 1);
		} else {
			print "密碼輸入完成\n";
		}

#		dumpData($msg, 1);
	} elsif ($switch eq "01C3") {
		#01C3 <len>.w <color>.l <>.l <>.w <>.w <str>.?B
		#NPC廣播
		my ($color_r, $color_g, $color_b, $chat);
		$color_r = unpack("C1", substr($msg, 4, 1));
		$color_g = unpack("C1", substr($msg, 5, 1));
		$color_b = unpack("C1", substr($msg, 6, 1));
		($chat = substr($msg, 16, $msg_size - 16)) =~ s/\000.*$//s;

		sysLog("n", "", $chat, "s");
	} elsif (!defined($rpackets{$switch})) {
		print "Unparsed packet - $switch\n";
		print "-Length : ".length($msg)."\n";
		printC("◇Please update the file 'recvpackets.txt'\n", "WHITE");
	}
	# Dump switch
	dumpData(substr($msg, 0, $msg_size)) if ($config{'debug_switch'} && $switch eq $config{'debug_switch'});
#Karasu Start
	# debug_packet mode
	$lastPacket = substr($msg, 0, $msg_size) if ($config{'debug_packet'} >= 2 && $msg_size);
#Karasu End
	$msg = (length($msg) >= $msg_size) ? substr($msg, $msg_size, length($msg) - $msg_size) : "";
	return $msg;
}

1;