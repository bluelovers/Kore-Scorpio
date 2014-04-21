#######################################
#######################################
#Parse RO Client Send Message
#######################################
#######################################

sub parseSendMsg {
	my $msg = shift;
	$sendMsg = $msg;
	if (length($msg) >= 4 && $conState >= 4 && length($msg) >= unpack("S1", substr($msg, 0, 2)) && $config{'encrypt'}) {
		decrypt(\$msg, $msg, $config{'encrypt'});
	}
	$switch = uc(unpack("H2", substr($msg, 1, 1))) . uc(unpack("H2", substr($msg, 0, 1)));

	# If the player tries to manually do something in the RO client, disable AI for a small period
	# of time using ai_clientSuspend().

	if ($switch eq "0064") {#systeman

		my $tmp_version		= unpack("L*", substr($msg, 2, 4));
		my $tmp_master_version	= unpack("C*", substr($msg, 54, 1));

		if ($option{'X-Kore_version'} && $config{'version'} ne $tmp_version) {
			scModify('config', 'version', $tmp_version, 1);
		}
		if ($config{'X-Kore_master_version'}) {
			scModify('config', "master_version_".$config{'master'}, $tmp_master_version, 1);
		}

#		print "$remote_socket{'PeerAddr'} : $remote_socket{'PeerPort'}\n";
#		print "$remote_socket{'PeerAddr'} : $remote_socket{'PeerPort'}\n";
	} elsif ($switch eq "0066") {
		# Login character selected
#		configModify("char", unpack("C*",substr($msg, 2, 1)));

		scModify('config', 'char', unpack("C*",substr($msg, 2, 1)), 1);

#		initConnectVars();

#		timeOutStart('gamelogin');

	} elsif ($switch eq "0072") {
		initConnectVars();

		# Map login
		if ($config{'sex'} ne "") {
			$sendMsg = substr($sendMsg, 0, 18) . pack("C", $config{'sex'});
		}

	} elsif ($switch eq "007D") {
		# Map loaded
#		if ($sc_v{'input'}{'conState'} != 5) {
#			timeOutStart(-1, 'ai');
#		}
#		timeOutStart(-1, 'ai') if (!checkTimeOut('ai'));
		$sc_v{'input'}{'conState'} = 5;

		$timeout{'ai_storagegetAuto'}{'time'} = time;
#		if ($firstLoginMap) {
#			undef $sentWelcomeMessage;
#			undef $firstLoginMap;
#		}
#		$timeout{'welcomeText'}{'time'} = time;
		print "Map loaded\n";

		timeOutStart('ai');
		ai_clientSuspend(0, 1);#systeman wait for charater info;

#		timeOutStart(
#			'play',
#			'ai_sync',
#			'ai_sit_idle',
#			'ai_teleport_idle',
#			'ai_teleport_search',
#			'ai_teleport_safe_force',
#			'ai_useSelf_skill_auto',
#			'ai_item_use_auto',
#			'ai_route_npcTalk',
#			'ai_event_onHit',
#			'ai_teleport_search_portal'
#		);

#		# Avoid GM
#
#		if ($ai_v{'teleOnGM'} == 2) {
#			undef %{$ai_v{'dcOnGM_counter'}};
#			quitOnEvent("dcOnGM", "迴避", "發現ＧＭ: 瞬移次數已滿", "gm");
#		}
#
#		undef $ai_v{'teleOnGM'};
#		undef $sc_v{'temp'}{'teleOnEvent'};
#		# Respawn at undefine map
#		respawnUndefine($ai_v{'temp'}{'map'});

	} elsif ($switch eq "0085") {
		# Move
		aiRemove("clientSuspend");
		makeCoords(\%coords, substr($msg, 2, 3));
		ai_clientSuspend($switch, (distance(\%{$chars[$config{'char'}]{'pos'}}, \%coords) * ($chars[$config{'char'}]{'walk_speed'} || $config{'seconds_per_block'})) + 2);
	} elsif ($switch eq "0089") {
		# Attack
		if (!($config{'tankMode'} && binFind(\@ai_seq, "attack") ne "")) {
			aiRemove("clientSuspend");
			ai_clientSuspend($switch, 2, unpack("C*",substr($msg,6,1)), substr($msg,2,4));
		} else {
			undef $sendMsg;
		}
	} elsif ($switch eq "008C" || $switch eq "0108" || $switch eq "017E") {
		# Public, party and guild chat
		my $length = unpack("S",substr($msg,2,2));
		my $message = substr($msg, 4, $length - 4);
		my ($chat) = $message =~ /^[\s\S]*? : ([\s\S]*)\000?/;
		$chat =~ s/^\s*//;
		if ($chat =~ /^$config{'commandPrefix'}/) {
			$chat =~ s/^$config{'commandPrefix'}//;
			$chat =~ s/^\s*//;
			$chat =~ s/\s*$//;
			$chat =~ s/\000*$//;
			parseInput($chat);
			undef $sendMsg;
		}

	} elsif ($switch eq "0096") {
		# Private message
		$length = unpack("S",substr($msg,2,2));
		($user) = substr($msg, 4, 24) =~ /([\s\S]*?)\000/;
		$chat = substr($msg, 28, $length - 29);
		$chat =~ s/^\s*//;
		if ($chat =~ /^$config{'commandPrefix'}/) {
			$chat =~ s/^$config{'commandPrefix'}//;
			$chat =~ s/^\s*//;
			$chat =~ s/\s*$//;
			parseInput($chat);
			undef $sendMsg;
#		} else {
#			undef %lastpm;
#			$lastpm{'msg'} = $chat;
#			$lastpm{'user'} = $user;
#			push @lastpm, {%lastpm};
		}
	} elsif ($switch eq "009B") {
		$body = unpack("C1",substr($msg, 4, 1));
		$head = unpack("C1",substr($msg, 2, 1));

		$chars[$config{'char'}]{'look'}{'head'} = $head;
		$chars[$config{'char'}]{'look'}{'body'} = $body;
		print "You look at $chars[$config{'char'}]{'look'}{'body'}, $chars[$config{'char'}]{'look'}{'head'}\n" if ($config{'debug'} >= 2);
	} elsif ($switch eq "009F") {
		# Take
		aiRemove("clientSuspend");
		ai_clientSuspend($switch, 2, substr($msg,2,4));

	} elsif ($switch eq "00B2") {
		# Trying to exit (Respawn)
		aiRemove("clientSuspend");
		ai_clientSuspend($switch, 10);

	} elsif ($switch eq "018A") {
		# Trying to exit
		aiRemove("clientSuspend");
		ai_clientSuspend($switch, 10);
	} elsif ($switch eq "01DD") {#systeman
		if ($option{'X-Kore_version'}) {
			scModify('config', "version", unpack("L*", substr($msg, 2, 4)), 1);
		}
		if ($option{'X-Kore_master_version'}) {
			scModify('config', "master_version_".$config{'master'}, unpack("C*", substr($msg, 46, 1)), 1);
		}
	} elsif ($switch eq "01FA") {#systeman
		if ($option{'X-Kore_version'}) {
			scModify('config', "version", unpack("L*", substr($msg, 2, 4)), 1);
		}
		if ($option{'X-Kore_master_version'}) {
			scModify('config', "master_version_".$config{'master'}, unpack("S*", substr($msg, 46, 2)), 1);
		}
	} elsif ($switch eq "023B") {
#		print "[023B] length: ".length($msg)."\n";
#		print "[023B] ".getHex(substr($msg,2,2))."\n";
#		print "[023B] ".getID(substr($msg,4,16))." - ".getHex(substr($msg,4,16))."\n";
#		print "[023B] ".getID(substr($msg,20,16))." - ".getHex(substr($msg,20,16))."\n";

#		print "[023B] ".unpack("L1",substr($msg, 2, 4))."\n";
#		print "[023B] ".unpack("L1",substr($msg, 6, 28))."\n";
#		print "[023B] ".unpack("L1",substr($msg, 2, 34))."\n";
#
#		($name) = substr($msg, 6, 28) =~ /([\s\S]*?)\000/;
#		($name2) = substr($msg, 2, 34) =~ /([\s\S]*?)\000/;
#
#		print "[023B] $name = $name2\n";
#		dumpData($sendMsg,0);
#		print "lastswitch: $lastswitch\n";
#		print "lastswitchSendMsg: $sc_v{'input'}{'sendMsg'}{'lastSwitch'}\n";
		printC("密碼金鑰: ".getHex(substr($msg,4,16))."\n", "s");
#	} elsif ($switch eq "023D") {
#		print "[$switch] length: ".length($msg)."\n";
#		print "[$switch] ".getHex(substr($msg,2,2))."\n";
#		print "[$switch] ".getID(substr($msg,4,16))." - ".getHex(substr($msg,4,16))."\n";
#		print "[$switch] ".getID(substr($msg,20,16))." - ".getHex(substr($msg,20,16))."\n";
#
##		print "[023B] ".unpack("L1",substr($msg, 2, 4))."\n";
##		print "[023B] ".unpack("L1",substr($msg, 6, 28))."\n";
##		print "[023B] ".unpack("L1",substr($msg, 2, 34))."\n";
##
##		($name) = substr($msg, 6, 28) =~ /([\s\S]*?)\000/;
##		($name2) = substr($msg, 2, 34) =~ /([\s\S]*?)\000/;
#
#		print "[$switch] $name = $name2\n";
#		dumpData($sendMsg,1);
##		print "倉庫密碼: ".getHex(substr($msg,4,16))."\n";
#	} elsif ($switch eq "0151") {
#		print "[$switch] lastswitch: $lastswitch\n";
	}
	if ($config{'debug_sendPacket'}) {
		my $found = 1;

		if (!defined($spackets{$switch}) && $sendMsg ne "" ) {
			dumpData($sendMsg, 1, 1);
		} elsif ($config{'debug_switch_send'} && existsInList($config{'debug_switch_send'}, $switch)) {
			dumpData($sendMsg, 1, 1);
		} else {
			$found = 0;
		}

		if ($found) {
			my $temp1;
			my $temp2;

			$temp1 = length($sendMsg);
			$temp2 = unpack("S1", substr($sendMsg, 2, 2));

			print <<"EOM";
sendPacket.Switch: $switch
sendPacket.Length - 1: $temp1
sendPacket.Length - 2: $temp2
sendPacket.Length - 3: $spackets{$switch}
EOM
;
}
	} elsif ($config{'debug_switch_send'} && existsInList($config{'debug_switch_send'}, $switch)) {
		dumpData($sendMsg, 1, 1);
	}

	if ($sendMsg ne "") {
		sendToServerByInject(\$remote_socket, $sendMsg);

		$sc_v{'input'}{'sendMsg'}{'lastSwitch'} = $switch;
		$sc_v{'input'}{'sendMsg'}{'lastTime'} = time;
	}

#	$sc_v{'input'}{'sendMsg'}{'lastSwitch'} = $switch;
##	$sc_v{'input'}{'sendMsg'}{'lastMsgLength'} = $switch;
#	$sc_v{'input'}{'sendMsg'}{'lastTime'} = time;
}

sub sendSyncInject {
	my $r_socket = shift;
	$$r_socket->send("K".pack("S", 0)) if $$r_socket && $$r_socket->connected();
}

sub sendToClientByInject {
	my $r_socket = shift;
	my $msg = shift;
	$$r_socket->send("R".pack("S", length($msg)).$msg) if $$r_socket && $$r_socket->connected();
}

sub sendToServerByInject {
	my $r_socket = shift;
	my $msg = shift;
	$$r_socket->send("S".pack("S", length($msg)).$msg) if $$r_socket && $$r_socket->connected();
}

sub injectMessage {
	my $message = shift;
	my $name = "X";
	my $msg .= $name . " : " . $message . chr(0);
	encrypt_mk(\$msg, $msg);
	$msg = pack("C*",0x09, 0x01) . pack("S*", length($name) + length($message) + 12) . pack("C*",0,0,0,0) . $msg;
	encrypt_mk(\$msg, $msg);
	sendToClientByInject(\$remote_socket, $msg);
}

sub injectAdminMessage {
	my $message = shift;
	$msg = pack("C*",0x9A, 0x00) . pack("S*", length($message)+5) . $message .chr(0);
	encrypt_mk(\$msg, $msg);
	sendToClientByInject(\$remote_socket, $msg);
}

sub encrypt_mk {
	my $r_msg = shift;
	my $themsg = shift;
	my $type = shift;
	my $state = shift;
	my @mask;
	my $newmsg;
	my ($i, $in, $out, $temp, $encryptVal);
	if ($type == 1 && $state >=5 ) {
		$out = 0;
		undef $newmsg;
		for ($i = 0; $i < 13;$i++) {
			$mask[$i] = 0;
		}
		{
			use integer;
			$temp = ($encryptVal * $encryptVal * 1391);
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $encryptVal * 1397;
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		for($in = 0; $in < length($themsg); $in++) {
			if ($mask[$out % 13]) {
				$newmsg .= pack("C1", int(rand() * 255) & 0xFF);
				$out++;
			}
			$newmsg .= substr($themsg, $in, 1);
			$out++;
		}
		$out += 4;
		$newmsg = pack("S2", $out, $encryptVal) . $newmsg;
		while ((length($newmsg) - 4) % 8 != 0) {
			$newmsg .= pack("C1", (rand() * 255) & 0xFF);
		}
	} elsif ($type >= 2 && $state >=5) {
		$out = 0;
		undef $newmsg;
		for ($i = 0; $i < 17;$i++) {
			$mask[$i] = 0;
		}
		{
			use integer;
			$temp = ($encryptVal * $encryptVal * 34953);
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $encryptVal * 2341;
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		for($in = 0; $in < length($themsg); $in++) {
			if ($mask[$out % 17]) {
				$newmsg .= pack("C1", int(rand() * 255) & 0xFF);
				$out++;
			}
			$newmsg .= substr($themsg, $in, 1);
			$out++;
		}
		$out += 4;
		$newmsg = pack("S2", $out, $encryptVal) . $newmsg;
		while ((length($newmsg) - 4) % 8 != 0) {
			$newmsg .= pack("C1", (rand() * 255) & 0xFF);
		}
	} else {
		$newmsg = $themsg;
	}

	$$r_msg = $newmsg;
}

#######################################
#######################################
#OUTGOING PACKET FUNCTIONS
#######################################
#######################################

sub decrypt {
	my $r_msg = shift;
	my $themsg = shift;
	my @mask;
	my $i;
	my ($temp, $msg_temp, $len_add, $len_total, $loopin, $len, $val);
	if ($config{'encrypt'} == 1) {
		undef $$r_msg;
		undef $len_add;
		undef $msg_temp;
		for ($i = 0; $i < 13;$i++) {
			$mask[$i] = 0;
		}
		$len = unpack("S1",substr($themsg,0,2));
		$val = unpack("S1",substr($themsg,2,2));
		{
			use integer;
			$temp = ($val * $val * 1391);
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $val * 1397;
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		for($loopin = 0; ($loopin + 4) < $len; $loopin++) {
 			if (!($mask[$loopin % 13])) {
  				$msg_temp .= substr($themsg, $loopin + 4,1);
			}
		}
		if (($len - 4) % 8 != 0) {
			$len_add = 8 - (($len - 4) % 8);
		}
		$len_total = $len + $len_add;
		$$r_msg = $msg_temp.substr($themsg, $len_total, length($themsg) - $len_total);
	} elsif ($config{'encrypt'} >= 2) {
		undef $$r_msg;
		undef $len_add;
		undef $msg_temp;
		for ($i = 0; $i < 17;$i++) {
			$mask[$i] = 0;
		}
		$len = unpack("S1",substr($themsg,0,2));
		$val = unpack("S1",substr($themsg,2,2));
		{
			use integer;
			$temp = ($val * $val * 34953);
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $val * 2341;
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		for($loopin = 0; ($loopin + 4) < $len; $loopin++) {
 			if (!($mask[$loopin % 17])) {
  				$msg_temp .= substr($themsg, $loopin + 4,1);
			}
		}
		if (($len - 4) % 8 != 0) {
			$len_add = 8 - (($len - 4) % 8);
		}
		$len_total = $len + $len_add;
		$$r_msg = $msg_temp.substr($themsg, $len_total, length($themsg) - $len_total);
	} else {
		$$r_msg = $themsg;
	}
}

sub encrypt {
	my $r_socket	= shift;
	my $themsg	= shift;
	my $mode	= shift;
	my @mask;
	my $newmsg;
	my ($in, $out);
	if ($config{'encrypt'} == 1 && $sc_v{'input'}{'conState'} >= 5) {
		$out = 0;
		undef $newmsg;
		for ($i = 0; $i < 13;$i++) {
			$mask[$i] = 0;
		}
		{
			use integer;
			$temp = ($encryptVal * $encryptVal * 1391);
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $encryptVal * 1397;
		}
		$temp = ~(~($temp));
		$temp = $temp % 13;
		$mask[$temp] = 1;
		for($in = 0; $in < length($themsg); $in++) {
			if ($mask[$out % 13]) {
				$newmsg .= pack("C1", int(rand() * 255) & 0xFF);
				$out++;
			}
			$newmsg .= substr($themsg, $in, 1);
			$out++;
		}
		$out += 4;
		$newmsg = pack("S2", $out, $encryptVal) . $newmsg;
		while ((length($newmsg) - 4) % 8 != 0) {
			$newmsg .= pack("C1", (rand() * 255) & 0xFF);
		}
	} elsif ($config{'encrypt'} >= 2 && $sc_v{'input'}{'conState'} >= 5) {
		$out = 0;
		undef $newmsg;
		for ($i = 0; $i < 17;$i++) {
			$mask[$i] = 0;
		}
		{
			use integer;
			$temp = ($encryptVal * $encryptVal * 34953);
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		{
			use integer;
			$temp = $encryptVal * 2341;
		}
		$temp = ~(~($temp));
		$temp = $temp % 17;
		$mask[$temp] = 1;
		for($in = 0; $in < length($themsg); $in++) {
			if ($mask[$out % 17]) {
				$newmsg .= pack("C1", int(rand() * 255) & 0xFF);
				$out++;
			}
			$newmsg .= substr($themsg, $in, 1);
			$out++;
		}
		$out += 4;
		$newmsg = pack("S2", $out, $encryptVal) . $newmsg;
		while ((length($newmsg) - 4) % 8 != 0) {
			$newmsg .= pack("C1", (rand() * 255) & 0xFF);
		}
	} else {
		$newmsg = $themsg;
	}

	if ($option{'X-Kore'}) {
		sendToServerByInject(\$remote_socket, $newmsg);
	} else {
		$$r_socket->send($newmsg) if ($$r_socket && $$r_socket->connected());
	}

#	$$r_socket->send($newmsg) if $$r_socket && $$r_socket->connected();
}

sub sendMessage {
	my $r_socket = shift;
	my $type = shift;
	my $msg = shift;
	my $user = shift;
	my ($i, $j);
	my @msg;
	my @msgs;
	my $oldmsg;
	my $amount;
	my $space;
	@msgs = split /\\n/, $msg;
	for ($j = 0; $j < @msgs; $j++) {
		@msg = split / /, $msgs[$j];
		undef $msg;
		for ($i = 0; $i < @msg; $i++) {
			if (!length($msg[$i])) {
				$msg[$i] = " ";
				$space = 1;
			}
			if (length($msg[$i]) > $config{'message_length_max'}) {
				while (length($msg[$i]) >= $config{'message_length_max'}) {
					$oldmsg = $msg;
					if (length($msg)) {
						$amount = $config{'message_length_max'};
						if ($amount - length($msg) > 0) {
							$amount = $config{'message_length_max'} - 1;
							$msg .= " " . substr($msg[$i], 0, $amount - length($msg));
						}
					} else {
						$amount = $config{'message_length_max'};
						$msg .= substr($msg[$i], 0, $amount);
					}
					if ($type eq "c") {
						sendChat($r_socket, $msg);
					} elsif ($type eq "g") {
						sendGuildChat($r_socket, $msg);
					} elsif ($type eq "p") {
						sendPartyChat($r_socket, $msg);
					} elsif ($type eq "pm") {
						undef %lastpm;
						$lastpm{'msg'} = $msg;
						$lastpm{'user'} = $user;
						push @lastpm, {%lastpm};

						$sc_v{'pm'}{'lastTo'} = $user;
						$sc_v{'pm'}{'lastMsg'} = $msg;

						sendPrivateMsg($r_socket, $user, $msg);
					} elsif ($type eq "k" && $option{'X-Kore'}) {
						injectMessage($msg);
 					}
					$msg[$i] = substr($msg[$i], $amount - length($oldmsg), length($msg[$i]) - $amount - length($oldmsg));
					undef $msg;
				}
			}
			if (length($msg[$i]) && length($msg) + length($msg[$i]) <= $config{'message_length_max'}) {
				if (length($msg)) {
					if (!$space) {
						$msg .= " " . $msg[$i];
					} else {
						$space = 0;
						$msg .= $msg[$i];
					}
				} else {
					$msg .= $msg[$i];
				}
			} else {
				if ($type eq "c") {
					sendChat($r_socket, $msg);
				} elsif ($type eq "g") {
					sendGuildChat($r_socket, $msg);
				} elsif ($type eq "p") {
					sendPartyChat($r_socket, $msg);
				} elsif ($type eq "pm") {
					undef %lastpm;
					$lastpm{'msg'} = $msg;
					$lastpm{'user'} = $user;
					push @lastpm, {%lastpm};
					sendPrivateMsg($r_socket, $user, $msg);
				} elsif ($type eq "k" && $option{'X-Kore'}) {
					injectMessage($msg);
				}
				$msg = $msg[$i];
			}
			if (length($msg) && $i == @msg - 1) {
				if ($type eq "c") {
					sendChat($r_socket, $msg);
				} elsif ($type eq "g") {
					sendGuildChat($r_socket, $msg);
				} elsif ($type eq "p") {
					sendPartyChat($r_socket, $msg);
				} elsif ($type eq "pm") {
					undef %lastpm;
					$lastpm{'msg'} = $msg;
					$lastpm{'user'} = $user;
					push @lastpm, {%lastpm};
					sendPrivateMsg($r_socket, $user, $msg);
				} elsif ($type eq "k" && $option{'X-Kore'}) {
					injectMessage($msg);
				}
			}
		}
	}
}

sub sendAddSkillPoint {
	my $r_socket = shift;
	my $skillID = shift;
	my $msg = pack("C*", 0x12, 0x01) . pack("S*", $skillID);
	encrypt($r_socket, $msg);
}

sub sendAddStatusPoint {
	my $r_socket = shift;
	my $statusID = shift;
	my $msg = pack("C*", 0xBB, 0) . pack("S*", $statusID) . pack("C*", 0x01);
	encrypt($r_socket, $msg);
}

sub sendAlignment {
	my $r_socket = shift;
	my $ID = shift;
	my $alignment = shift;
	my $msg = pack("C*", 0x49, 0x01) . $ID . pack("C*", $alignment);
	encrypt($r_socket, $msg);
	print "Sent Alignment: ".getHex($ID).", $alignment\n" if ($config{'debug'} >= 2);
}

sub sendAttack {
	my $r_socket = shift;
	my $monID = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x89, 0x00) . $monID . pack("C*", $flag);
	encrypt($r_socket, $msg);
	print "Sent Attack: ".getHex($monID)."\n" if ($config{'debug'} >= 2);
}

sub sendAttackStop {
	my $r_socket = shift;
	my $msg = pack("C*", 0x18, 0x01);
	encrypt($r_socket, $msg);
	print "Sent Stop Attack\n" if ($config{'debug'});
}

sub sendBuy {
	my $r_socket = shift;
	my $ID = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xC8, 0x00, 0x08, 0x00) . pack("S*", $amount, $ID);
	encrypt($r_socket, $msg);
	print "Sent Buy: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendCartAdd {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x26, 0x01) . pack("S*", $index) . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Cart Add: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCartGet {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x27, 0x01) . pack("S*", $index) . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Cart Get: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCharLogin {
	my $r_socket = shift;
	my $char = shift;
	my $msg = pack("C*", 0x66,0) . pack("C*", $char);
	encrypt($r_socket, $msg);
}

sub sendChat {
	my $r_socket = shift;
	my $message = shift;
	# Avoid chat when skill_ban
	if ($chars[$config{'char'}]{'skill_ban'}) {
		print "你處在禁止聊天和使用技能的狀態下！\n";
		return;
	}

	my $msg = pack("C*",0x8C, 0x00) . pack("S*", length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
			$chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
	encrypt($r_socket, $msg);
}

sub sendChatRoomBestow {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xE0, 0x00, 0x00, 0x00, 0x00, 0x00) . $name;
	encrypt($r_socket, $msg);
	print "Sent Chat Room Bestow: $name\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomChange {
	my $r_socket = shift;
	my $title = shift;
	my $limit = shift;
	my $public = shift;
	my $password = shift;
	$password = substr($password, 0, 8) if (length($password) > 8);
	$password = $password . chr(0) x (8 - length($password));
	my $msg = pack("C*", 0xDE, 0x00).pack("S*", length($title) + 15, $limit).pack("C*", $public).$password.$title;
	encrypt($r_socket, $msg);
	print "Sent Change Chat Room: $title, $limit, $public, $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomCreate {
	my $r_socket = shift;
	my $title = shift;
	my $limit = shift;
	my $public = shift;
	my $password = shift;
	$password = substr($password, 0, 8) if (length($password) > 8);
	$password = $password . chr(0) x (8 - length($password));
	my $msg = pack("C*", 0xD5, 0x00).pack("S*", length($title) + 15, $limit).pack("C*", $public).$password.$title;
	encrypt($r_socket, $msg);
	print "Sent Create Chat Room: $title, $limit, $public, $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomJoin {
	my $r_socket = shift;
	my $ID = shift;
	my $password = shift;
	$password = substr($password, 0, 8) if (length($password) > 8);
	$password = $password . chr(0) x (8 - length($password));
	my $msg = pack("C*", 0xD9, 0x00).$ID.$password;
	encrypt($r_socket, $msg);
	print "Sent Join Chat Room: ".getHex($ID)." $password\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomKick {
	my $r_socket = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xE2, 0x00).$name;
	encrypt($r_socket, $msg);
	print "Sent Chat Room Kick: $name\n" if ($config{'debug'} >= 2);
}

sub sendChatRoomLeave {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE3, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Leave Chat Room\n" if ($config{'debug'} >= 2);
}

sub sendCurrentDealCancel {
	my $r_socket = shift;
	my $msg = pack("C*", 0xED, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Cancel Current Deal\n" if ($config{'debug'} >= 2);
}

sub sendDeal {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xE4, 0x00) . $ID;
	encrypt($r_socket, $msg);
	print "Sent Initiate Deal: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendDealAccept {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE6, 0x00, 0x03);
	encrypt($r_socket, $msg);
	print "Sent Accept Deal\n" if ($config{'debug'} >= 2);
}

sub sendDealAddItem {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xE8, 0x00) . pack("S*", $index) . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Deal Add Item: $index, $amount\n" if ($config{'debug'} >= 2);
}

sub sendDealCancel {
	my $r_socket = shift;
	my $msg = pack("C*", 0xE6, 0x00, 0x04);
	encrypt($r_socket, $msg);
	print "Sent Cancel Deal\n" if ($config{'debug'} >= 2);
}

sub sendDealFinalize {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEB, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Deal OK\n" if ($config{'debug'} >= 2);
}

sub sendDealOK {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEB, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Deal OK\n" if ($config{'debug'} >= 2);
}

sub sendDealTrade {
	my $r_socket = shift;
	my $msg = pack("C*", 0xEF, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Deal Trade\n" if ($config{'debug'} >= 2);
}

sub sendDrop {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xA2, 0x00) . pack("S*", $index, $amount);
	encrypt($r_socket, $msg);
	print "Sent drop: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendEmotion {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xBF, 0x00) . pack("C1", $ID);
	encrypt($r_socket, $msg);
	print "Sent Emotion\n" if ($config{'debug'} >= 2);
}

#Pino Start
sub sendEquip {
	my $r_socket = shift;
	my $index = shift;
	my $type = shift;
	my $msg = pack("C*", 0xA9, 0x00) . pack("S*", $index) . pack("S*", $type);
	encrypt($r_socket, $msg);
	print "Sent Equip: $index\n" if ($config{'debug'} >= 2);
}
#Pino End

sub sendGameLogin {
	my $r_socket = shift;
	my $accountID = shift;
	my $sessionID = shift;
	my $sex = shift;
	my $msg = pack("C*", 0x65,0) . $accountID . $sessionID . pack("C*", 0,0,0,0,0,0, $sex);
	encrypt($r_socket, $msg);
}

sub sendGetPlayerInfo {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x94, 0x00) . $ID;
	encrypt($r_socket, $msg);
	print "Sent Get Player Info: ID - ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGetStoreList {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x00);
	encrypt($r_socket, $msg);
	print "Sent Get Store List: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGetSellList {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xC5, 0x00) . $ID . pack("C*",0x01);
	encrypt($r_socket, $msg);
	print "Sent Sell to NPC: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendGuildChat {
	my $r_socket = shift;
	my $message = shift;
	my $msg = pack("C*",0x7E, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
	$chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
	encrypt($r_socket, $msg);
}

sub sendIdentify {
	my $r_socket = shift;
	my $index = shift;
	my $msg = pack("C*", 0x78, 0x01) . pack("S*", $index);
	encrypt($r_socket, $msg);
	print "Sent Identify: $index\n" if ($config{'debug'} >= 2);
}

sub sendIgnore {
	my $r_socket = shift;
	my $name = shift;
	my $flag = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xCF, 0x00).$name.pack("C*", $flag);
	encrypt($r_socket, $msg);
	print "Sent Ignore: $name, $flag\n" if ($config{'debug'} >= 2);
}

sub sendIgnoreAll {
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xD0, 0x00) . pack("C*", $flag);
	encrypt($r_socket, $msg);
	print "Sent Ignore All: $flag\n" if ($config{'debug'} >= 2);
}

#sendGetIgnoreList - chobit 20021223
sub sendIgnoreListGet {
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xD3, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Get Ignore List: $flag\n" if ($config{'debug'} >= 2);
}

sub sendItemUse {
	my $r_socket = shift;
	my $ID = shift;
	my $targetID = shift;
	my $invIndex;
	# Avoid use item when skill_ban
	if ($chars[$config{'char'}]{'skill_ban'}) {
		print "你處在禁止聊天和使用技能的狀態下！\n";
		return;
	}
	$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "index", $ID);
	# Avoid use unusable item
	if ($invIndex ne "" && $chars[$config{'char'}]{'inventory'}[$invIndex]{'type'} > 2) {
		print "無法使用除了使用品之外的物品！\n";
		return;
	}
	my $msg = pack("C*", 0xA7, 0x00) . pack("S*", $ID) . $targetID;
	encrypt($r_socket, $msg);
	print "Send Item Use: $ID\n" if ($config{'debug'} >= 2);
}

sub sendLook {
	my $r_socket = shift;
	my $body = shift;
	my $head = shift;
	my $msg = pack("C*", 0x9B, 0x00, $head, 0x00, $body);
	encrypt($r_socket, $msg);
	print "Sent look: $body $head\n" if ($config{'debug'} >= 2);
	$chars[$config{'char'}]{'look'}{'head'} = $head;
	$chars[$config{'char'}]{'look'}{'body'} = $body;

	my $body_out = ("北", "西北", "西", "西南", "南", "東南", "東", "東北")[$body];
	my $head_out = ("正前", "右前", "左前")[$head];

	print "你面向$body_out方, 臉朝$head_out方\n";
}

sub sendMapLoaded {
	my $r_socket = shift;
	my $msg = pack("C*", 0x7D,0x00);
	print "Sending Map Loaded\n" if ($config{'debug'});
	encrypt($r_socket, $msg);
}

sub sendMapLogin {
	my $r_socket = shift;
	my $accountID = shift;
	my $charID = shift;
	my $sessionID = shift;
	my $sex = shift;
	my $msg = pack("C*", 0x72,0) . $accountID . $charID . $sessionID . pack("L1", getTickCount()) . pack("C*", $sex);
	encrypt($r_socket, $msg);
}

sub sendMasterLogin {
	my $r_socket = shift;
	my $username = shift;
	my $password = shift;
	my $msg = pack("C*", 0x64,0) . pack("L1", $config{'version'}) . $username . chr(0) x (24 - length($username)) .
			$password . chr(0) x (24 - length($password)) . pack("C*", $config{"master_version_$config{'master'}"});
	encrypt($r_socket, $msg);
}

sub sendMemo {
	my $r_socket = shift;
	my $msg = pack("C*", 0x1D, 0x01);
	encrypt($r_socket, $msg);
	print "Sent Memo\n" if ($config{'debug'} >= 2);
}

sub sendMove {
	my $r_socket = shift;
	my $x = shift;
	my $y = shift;
	my $msg;

	if ($config{'serverType'}) {
		$msg = pack("C*", 0xbc, 0x00) . getCoordString($x, $y) . chr(173);
	} else {
		$msg = pack("C*", 0x85, 0x00) . getCoordString($x, $y);
	}

	encrypt($r_socket, $msg);
	print "Sent move to: $x, $y\n" if ($config{'debug'} >= 2);
}

sub sendPartyChat {
	my $r_socket = shift;
	my $message = shift;
	my $msg = pack("C*",0x08, 0x01) . pack("S*",length($chars[$config{'char'}]{'name'}) + length($message) + 8) .
			$chars[$config{'char'}]{'name'} . " : " . $message . chr(0);
	encrypt($r_socket, $msg);
}

sub sendPartyJoin {
	my $r_socket = shift;
	my $ID = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xFF, 0x00) . $ID . pack("L*", $flag);
	encrypt($r_socket, $msg);
	print "Sent Join Party: ".getHex($ID).", $flag\n" if ($config{'debug'} >= 2);
}

sub sendPartyJoinRequest {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xFC, 0x00) . $ID;
	encrypt($r_socket, $msg);
	print "Sent Request Join Party: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendPartyKick {
	my $r_socket = shift;
	my $ID = shift;
	my $name = shift;
	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0x03, 0x01).$ID.$name;
	encrypt($r_socket, $msg);
	print "Sent Kick Party: ".getHex($ID).", $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyLeave {
	my $r_socket = shift;
	my $msg = pack("C*", 0x00, 0x01);
	encrypt($r_socket, $msg);
	print "Sent Leave Party: $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyOrganize_old {
	my $r_socket = shift;
	my $name = shift;

	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xF9, 0x00) . $name;
	encrypt($r_socket, $msg);
	print "Sent Organize Party: $name\n" if ($config{'debug'} >= 2);
}

sub sendPartyOrganize {
	my $r_socket = shift;
	my $name = shift;
	my $flag1 = shift;
	my $flag2 = shift;

	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xF9, 0x00) . $name . pack("C*", $flag1) . pack("C*", $flag2);
	encrypt($r_socket, $msg);
	print "Sent Organize Party: $name [$flag1, $flag2]\n" if ($config{'debug'} >= 2);
}

sub sendPartyShareEXP {
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x02, 0x01) . pack("L", $flag);
	encrypt($r_socket, $msg);
	print "Sent Party Share: $flag\n" if ($config{'debug'} >= 2);
}

sub sendRaw {
	my $r_socket = shift;
	my $raw = shift;
	my @raw;
	my $msg;
	@raw = split / /, $raw;
	foreach (@raw) {
		$msg .= pack("C", hex($_));
	}
	encrypt($r_socket, $msg);
	print "Sent Raw Packet: @raw\n" if ($config{'debug'} >= 2);
}

sub sendRespawn {
	my $r_socket = shift;
	my $msg = pack("C*", 0xB2, 0x00, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Respawn\n" if ($config{'debug'} >= 2);
}

sub sendPrivateMsg {
	my $r_socket = shift;
	my $user = shift;
	my $message = shift;
	my $msg = pack("C*", 0x96, 0x00) . pack("S*", length($message) + 29) . $user . chr(0) x (24 - length($user)) .
			$message . chr(0);
	encrypt($r_socket, $msg);
}

sub sendSell {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xC9, 0x00, 0x08, 0x00) . pack("S*", $index, $amount);
	encrypt($r_socket, $msg);
	print "Sent Sell: $index x $amount\n" if ($config{'debug'} >= 2);

}

sub sendSit {
	my $r_socket = shift;
#	my $msg = pack("C*", 0x89, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02);
	my $msg;

	if ($config{'serverType'}) {
		$msg = pack("C*", 0x89, 0x00, 0x9c, 0x22, 0xfa, 0x83, 0x02);
	} else {
		$msg = pack("C*", 0x89, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02);
	}

	encrypt($r_socket, $msg);
	print "Sitting\n" if ($config{'debug'} >= 2);
}

sub sendSkillUse {
	my $r_socket = shift;
	my $ID = shift;
	my $lv = shift;
	my $targetID = shift;
#Karasu Start
	# Avoid passive skills be used as active
	# Avoid use skill when skill_ban
   print "你處在禁止聊天和使用技能的狀態下！\n" if ($chars[$config{'char'}]{'skill_ban'});
   return if ($ID == 48 || $ID == 263 || $chars[$config{'char'}]{'skill_ban'});
#Karasu End
	my $msg = pack("C*", 0x13, 0x01) . pack("S*", $lv, $ID) . $targetID;
	encrypt($r_socket, $msg);
	print "Skill Use: $ID\n" if ($config{'debug'} >= 2);
}

sub sendSkillUseLoc {
	my $r_socket = shift;
	my $ID = shift;
	my $lv = shift;
	my $x = shift;
	my $y = shift;
	# Avoid use skill when skill_ban
   if ($chars[$config{'char'}]{'skill_ban'}) {
		print "你處在禁止聊天和使用技能的狀態下！\n";
		return;
	}
	my $msg = pack("C*", 0x16, 0x01) . pack("S*", $lv, $ID, $x, $y);
	encrypt($r_socket, $msg);
	print "Skill Use Loc: $ID\n" if ($config{'debug'} >= 2);
}

sub sendStorageAdd {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xF3, 0x00) . pack("S*", $index) . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Storage Add: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendStorageClose {
	my $r_socket = shift;
	my $msg = pack("C*", 0xF7, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Storage Close\n" if ($config{'debug'} >= 2);
}

sub sendStorageGet {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0xF5, 0x00) . pack("S*", $index) . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Storage Get: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendStand {
	my $r_socket = shift;
#	my $msg = pack("C*", 0x89,0x00, 0x00, 0x00, 0x00, 0x00, 0x03);
	my $msg;

	if ($config{'serverType'}) {
		$msg = pack("C*", 0x89, 0x00, 0x9c, 0x22, 0xfa, 0x83, 0x03);
	} else {
		$msg = pack("C*", 0x89, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03);
	}

	encrypt($r_socket, $msg);
	print "Standing\n" if ($config{'debug'} >= 2);
}

#sub sendSync {
#	my $r_socket = shift;
#	my $time = shift;
#	my $msg = pack("C*", 0x7E, 0x00) . pack("L1", $time);
#	encrypt($r_socket, $msg);
#	print "Sent Sync: $time\n" if ($config{'debug'} >= 2);
#}

#sub sendSync {
#	my $r_socket = shift;
#	my $time = shift;
#	my $msg;
#
#	if ($config{serverType} == 0) {
#		$msg = pack("C*", 0x7E, 0x00) . pack("L1", getTickCount());
#
#	} else {
#		$msg = pack("C*", 0x7E, 0x00);
#		$msg .= pack("C*", 0x30, 0x00, 0x40) if ($initialSync);
#		$msg .= pack("C*", 0x00, 0x00, 0x1F) if (!$initialSync);
#		$msg .= pack("L", getTickCount());
#	}
#
#	sendMsgToServer($r_socket, $msg);
#	print "Sent Sync: $time\n" if ($config{'debug'} >= 2);
#}

sub sendSync {
	my $r_socket = shift;
	my $time = shift;
	my $msg;

	if ($config{'serverType'} == 0) {
		$msg = pack("C*", 0x7E, 0x00) . pack("L1", $time);
	} else {
		$msg = pack("C*", 0x7E, 0x00);
		$msg .= pack("C*", 0x30, 0x00, 0x40) if ($initialSync);
		$msg .= pack("C*", 0x00, 0x00, 0x1F) if (!$initialSync);
		$msg .= pack("L", getTickCount());
	}

	encrypt($r_socket, $msg);
	print "Sent Sync: $time\n" if ($config{'debug'} >= 2);
}

sub sendTake {
	my $r_socket = shift;
	my $itemID = shift;
	my $msg = pack("C*", 0x9F, 0x00) . $itemID;
	encrypt($r_socket, $msg);
	print "Sent Take\n" if ($config{'debug'} >= 2);
}

sub sendTalk {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x90, 0x00) . $ID . pack("C*", 0x01);
	encrypt($r_socket, $msg);
	print "Sent Talk: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
	# 與每一位NPC講話前先清除clientCancel
	undef $talk{'clientCancel'};
}

sub sendTalkCancel {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x46, 0x01) . $ID;
	encrypt($r_socket, $msg);
	print "Sent Talk Cancel: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkContinue {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xB9, 0x00) . $ID;
	encrypt($r_socket, $msg);
	print "Sent Talk Continue: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

sub sendTalkResponse {
	my $r_socket = shift;
	my $ID = shift;
	my $response = shift;
	my $msg = pack("C*", 0xB8, 0x00) . $ID . pack("C1", $response);
	encrypt($r_socket, $msg);
	print "Sent Talk Respond: ".getHex($ID).", $response\n" if ($config{'debug'} >= 2);
}

sub sendTeleport {
	my $r_socket = shift;
	my $location = shift;
	$location = substr($location, 0, 16) if (length($location) > 16);
	$location .= chr(0) x (16 - length($location));
	my $msg = pack("C*", 0x1B, 0x01, 0x1A, 0x00) . $location;
	encrypt($r_socket, $msg);
	print "Sent Teleport: $location\n" if ($config{'debug'} >= 2);
}

sub sendUnequip{
	my $r_socket = shift;
	my $index = shift;
	my $msg = pack("C*", 0xAB, 0x00) . pack("S*", $index);
	encrypt($r_socket, $msg);
	print "Sent Unequip: $index\n" if ($config{'debug'} >= 2);
}

sub sendWho {
	my $r_socket = shift;
	my $msg = pack("C*", 0xC1, 0x00);
	encrypt($r_socket, $msg);
	print "Sent Who\n" if ($config{'debug'} >= 2);
}

#s4u Start
# Send answer to NPC
sub sendTalkAnswerNum {
	my $r_socket = shift;
	my $ID = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x43, 0x01) . $ID . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Talk Answer Number: ".getHex($ID).", $amount\n" if ($config{'debug'} >= 2);
}

sub sendTalkAnswerWord {
	my $r_socket = shift;
	my $ID = shift;
	my $string = shift;
	$string = substr($string, 0, 40) if (length($string) > 40);
	my $msg = pack("C*", 0xD5, 0x01) . pack("S*", length($string) + 9) . $ID . $string . chr(0);
	encrypt($r_socket, $msg);
	print "Sent Talk Answer Word: ".getHex($ID).", $string\n" if ($config{'debug'} >= 2);
}

sub sendPetCall {
	my $r_socket = shift;
	my $index = shift;
	my $msg = pack("C*", 0xA7, 0x01) . pack("S*", $index);
	encrypt($r_socket, $msg);
	print "Sent Pet Call: $index\n" if ($config{'debug'} >= 2);
}

sub sendPetCommand {
	my $r_socket = shift;
	my $flag = shift;
	my $msg = pack("C*", 0xA1, 0x01) . pack("C*", $flag);
	encrypt($r_socket, $msg);
	print "Sent Pet Command: $flag\n" if ($config{'debug'} >= 2);
}
#s4u End

sub sendAutospell {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xCE, 0x01) . pack("S*", $ID) . chr(0) x 2;
	encrypt($r_socket, $msg);
	print "Sent Autospell: $ID\n" if ($config{'debug'} >= 2);
	$chars[$config{'char'}]{'autospell'} = $skillsID_lut{$ID};
}

sub sendPetCatch {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x9F, 0x01) . $ID;
	encrypt($r_socket, $msg);
	print "Send Pet Catch: getHex($ID)\n" if ($config{'debug'} >= 2);
}

sub sendItemCreate {
	my $r_socket = shift;
	my $ID = shift;
	my $stone = shift;
	my $stars = shift;
	my $i;
	my $msg = pack("C*", 0x8E, 0x01) . pack("S*", $ID);
	$msg .= pack("S*", $stone) if ($stone);
	for ($i = 0; $i < $stars; $i++) {
		$msg .= pack("S*", 1000);
	}
	$msg .= chr(0) x (10 - length($msg));
	encrypt($r_socket, $msg);
	print "Sent Item Create: $ID\n" if ($config{'debug'} >= 2);
}

sub sendStorageGetToCart {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x28, 0x01) . pack("S*", $index) . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Storage Get to Cart: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendCartGetToStorage {
	my $r_socket = shift;
	my $index = shift;
	my $amount = shift;
	my $msg = pack("C*", 0x29, 0x01) . pack("S*", $index) . pack("L*", $amount);
	encrypt($r_socket, $msg);
	print "Sent Cart Get to Storage: $index x $amount\n" if ($config{'debug'} >= 2);
}

#Karasu Start
# Make arrow
sub sendArrowMake {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0xAE, 0x01) . pack("S*", $ID);
	encrypt($r_socket, $msg);
	print "Sent Arrow Make: $ID\n" if ($config{'debug'} >= 2);
}

# Request player name by charID
sub sendGetPlayerInfoByCharID {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x93, 0x01) . $ID;
	encrypt($r_socket, $msg);
	print "Sent Get Player Info by CharID: ID - ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

# Guild Member Name Request
sub sendNameRequest {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x93, 0x01) . $ID;
#	sendMsgToServer($r_socket, $msg);
	encrypt($r_socket, $msg);
	print "Sent Name Request : ".getHex($ID)."\n" if ($sys{'debug'} >= 2);
}

# Send guild related packages
sub sendGuildInfoRequest {
	my $r_socket = shift;
	my $msg = pack("C*", 0x4d, 0x01);
	encrypt($r_socket, $msg);
	print "Sent Guild Infor Request\n" if ($config{'debug'} >= 2);
}

sub sendGuildRequest {
	my $r_socket = shift;
	my $page = shift;
	my $msg = pack("C*", 0x4f, 0x01) . pack("L*", $page);
	encrypt($r_socket, $msg);
	print "Sent Guild Request Page: ".$page."\n" if ($config{'debug'} >= 2);
}

# send guild join package
sub sendGuildJoin {
	my $r_socket = shift;
	my $ID = shift;
	my $flag = shift;
	my $msg = pack("C*", 0x6B, 0x01) . $ID . pack("L*", $flag);
	encrypt($r_socket, $msg);
	print "Sent Join Guild: ".getHex($ID).", $flag\n" if ($config{'debug'} >= 2);
}

# Reply guild join request
sub sendGuildJoinRequest {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x68, 0x01) . $ID . $accountID . $sc_v{'input'}{'charID'};
	encrypt($r_socket, $msg);
	print "Sent Request Join Guild: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

# Secure login
sub sendMasterCodeRequest {
	my $r_socket = shift;
	my $msg = pack("C*", 0xDB, 0x01);
	encrypt($r_socket, $msg);
}

sub sendMasterSecureLogin {
	my $r_socket = shift;
	my $username = shift;
	my $password = shift;
	my $salt = shift;

	if ($config{'secureLogin'} == 1) {
		$salt = $salt . $password;
	} else {
		$salt = $password . $salt;
	}
	my $msg = pack("C*", 0xDD, 0x01) . pack("L1", $config{'version'}) . $username . chr(0) x (24 - length($username)) .
			md5($salt) . pack("C*", $config{"master_version_$config{'master'}"});
	encrypt($r_socket, $msg);
}

# Close vendor
sub sendShopClose {
	my $r_socket = shift;
	my $msg = pack("C*", 0x2E, 0x01);
	encrypt($r_socket, $msg);
	print "Send Shop Close\n" if ($config{'debug'} >= 2);
}

# Get shop list
sub sendGetShopList {
	my $r_socket = shift;
	my $ID = shift;
	my $msg = pack("C*", 0x30, 0x01) . $ID;
	encrypt($r_socket, $msg);
	print "Sent Get Shop List: ".getHex($ID)."\n" if ($config{'debug'} >= 2);
}

# Buy from vendor
sub sendBuyFromShop {
	my $r_socket = shift;
	my $shopID = shift;
	my $amount = shift;
	my $index = shift;
	my $msg = pack("C*", 0x34, 0x01, 0x0C, 0x00) . $shopID . pack("S*", $amount, $index);
	encrypt($r_socket, $msg);
	print "Sent Buy from Shop: $index x $amount\n" if ($config{'debug'} >= 2);
}

sub sendGuildLeave {
	my $r_socket = shift;
	my $guildID = shift;
	my $accountID = shift;
	my $charID = shift;
	my $cause = shift;

	$cause = substr($cause, 0, 40) if (length($cause) > 40);
	$cause = $cause . chr(0) x (40 - length($cause));

	my $msg = pack("C*", 0x59, 0x01).$guildID.$accountID.$charID.$cause;
	encrypt($r_socket, $msg);
	print "Sent Guild Leave\n" if ($config{'debug'} >= 2);

#       Guild ID      Account ID    Char ID       Cause
#59 01 | 9F 2B 00 00 | 72 99 06 00 | 90 24 14 00 | B7 B4
#CA CD BA 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00
}

sub sendGuildAllyRequest {
	my $r_socket = shift;
	my $targetID = shift;
	my $accountID = shift;
	my $charID = shift;
	my $msg = pack("C*", 0x70, 0x01).$targetID.$accountID.$charID;
	encrypt($r_socket, $msg);
	print "Sent Guild Request Ally $targetID\n" if ($config{'debug'} >= 2);

#           Target ID       Account ID      Char ID
# 70 01 | 72 99 06 00 | 7C C4 0A 00 | 44 2F 09 00
}

sub sendGuildAlly {
	my $r_socket = shift;
	my $targetID = shift;
	my $type = shift;
	my $msg = pack("C*", 0x72, 0x01).$targetID.pack("L*",$type);
	encrypt($r_socket, $msg);
	print "Sent Guild Ally $targetID\n" if ($config{'debug'} >= 2);

#           Target ID       Type
#72 01 | 72 99 06 00 | 01 00 00 00
}

sub sendGuildEnemyRequest {
	my $r_socket = shift;
	my $targetID = shift;
	my $msg = pack("C*", 0x80, 0x01).$targetID;
	encrypt($r_socket, $msg);
	print "Sent Guild Request Enemy $targetID\n" if ($config{'debug'} >= 2);

#          Target ID
#80 01 | 72 99 06 00
}

sub sendGuildDeleteRequest {
	my $r_socket = shift;
	my $guildID = shift;
	my $type = shift;
	my $msg = pack("C*", 0x80, 0x01).$guildID.pack("L*",$type);
	encrypt($r_socket, $msg);
	print "Sent Guild Delete Request\n" if ($config{'debug'} >= 2);

#          Guild ID
#83 01 | 70 17 00 00 | 01 00 00 00
}

sub sendGuildMemberDelete {
	my $r_socket = shift;
	my $guildID = shift;
	my $accountID = shift;
	my $charID = shift;
	my $cause = shift;

	$cause = substr($cause, 0, 40) if (length($cause) > 40);
	$cause = $cause . chr(0) x (40 - length($cause));

	my $msg = pack("C*", 0x5B, 0x01).$guildID.$accountID.$charID;
	encrypt($r_socket, $msg);
	print "Sent Guild Member Delete: $accountID\n" if ($config{'debug'} >= 2);

#       Guild ID      Account ID    Char ID
#5B 01 | 9F 2B 00 00 | CE 72 0C 00 | 63 6A 13 00 |
#C5 BA B5 D1 C7 C5 D0 A4 C3 E4 BB E1 C5 E9 C7 20 CA D2 C7 E6
#20 C5 BA E4 B4 E9 E4 A7 00 00 00 00 00 00 00 00 00 00 00 00
}

sub sendGuildMemberTitleChange {
	my $r_socket = shift;
	my $index = shift;
	my $title = shift;

	$title = substr($title, 0, 24) if (length($title) > 24);
	$title = $title . chr(0) x (24 - length($title));

	my $msg = pack("C*", 0x61, 0x01).pack("S*",44).pack("L*",$index).pack("L*",1).pack("L*",$index).pack("L*",0).$title;
	encrypt($r_socket, $msg);
	print "Sent Guild Member Title Changed\n" if ($config{'debug'} >= 2);

#61 01 54 00 0E 00 00 00    01 00 00 00 0E 00 00 00
#00 00 00 00 CA C7 C2 E3    CA A1 C3 D0 AA D2 A1 E3
#A8 BB EB D2 00 00 00 00    00 00 00 00 10 00 00 00
#00 00 00 00 10 00 00 00    00 00 00 00 50 6F 73 69
#74 69 6F 6E 20 31 37 00    00 00 00 00 00 00 00 00
#00 00 00 00
}

sub sendGuildNotice {
	my $r_socket = shift;
	my $guildID = shift;
	my $name = shift;
	my $notice = shift;

	$name = substr($name, 0, 60) if (length($name) > 60);
	$name = $name . chr(0) x (60 - length($name));

	$notice = substr($notice, 0, 120) if (length($notice) > 120);
	$notice = $notice . chr(0) x (120 - length($notice));

	my $msg = pack("C*", 0x6E, 0x01).$guildID.$name.$notice;
	encrypt($r_socket, $msg);
	print "Sent Guild Notice\n" if ($config{'debug'} >= 2);

#      Guild ID    Name
#6E 01 9F 2B 00 00 7E 47    2E 4F 2E 44 7E 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 43 61 74 63 68 20    6D 65 2C 20 69 66 20 79
#6F 75 20 63 61 6E 2E 20    4C 6F 76 65 20 6D 65 2C
#20 69 66 20 79 6F 75 20    61 72 65 20 61 20 67 69
#72 6C 2E 20 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00 00 00 00 00 00 00
#00 00 00 00 00 00 00 00    00 00
}

sub sendWarpPortal {
	my $r_socket = shift;
	my $location = shift;
	$location = substr($location, 0, 16) if (length($location) > 16);
	$location .= chr(0) x (16 - length($location));
	my $msg = pack("C*", 0x1B, 0x01, 0x1B, 0x00) . $location;
	encrypt($r_socket, $msg);
	print "Sent Warp Portal: $location\n" if ($config{'debug'} >= 2);
}

#--------------------------------------------

sub sendMapLoginPK {
	my $r_socket = shift;
	my $accountID = shift;
	my $sessionID = shift;
	my $sex = shift;
	my $msg = pack("C*", 0x72,0,0) . $accountID .
	pack("C*", 0x00, 0x2C, 0xFC, 0x2B, 0x8B, 0x01, 0x00, 0x60, 0x00, 0xFF, 0xFF, 0xFF, 0xFF) .
		$sessionID . pack("L1", getTickCount()) . pack("C*",$sex);
	encrypt($r_socket, $msg);
}

#--------------------------------------------
# koreSC - BLUELOVERS

# Send Emblem Request packages
sub sendGuildEmblemRequest {
	my $r_socket = shift;
	my $targetID = shift;
	my $msg = pack("C*", 0x51, 0x01).$targetID;
	encrypt($r_socket, $msg);
	print "Sent Guild Emblem Request ".getID($targetID)."\n" if ($config{'debug'} >= 2);
}

sub sendPartyOrganize_050924 {
	my $r_socket = shift;
	my $name = shift;
	my $flag1 = shift;
	my $flag2 = shift;

	$name = substr($name, 0, 24) if (length($name) > 24);
	$name = $name . chr(0) x (24 - length($name));
	my $msg = pack("C*", 0xF9, 0x00) . $name . pack("L*", $flag1) . pack("L*", $flag2);
	encrypt($r_socket, $msg);
	print "Sent Organize Party: $name [$flag1, $flag2]\n" if ($config{'debug'} >= 2);
}

1;