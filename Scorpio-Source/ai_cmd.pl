
sub ai_event_cmd_sc {
	
#	my %cmd = %{(shift)};
	
#	return 0 if (!$config{'autoAdmin'} || !%cmd);
#	return 0 unless (
#		$config{'autoAdmin'}
#		&& %cmd
#		&& (
#			$config{'autoAdmin_type'} eq ""
#			|| existsInList($config{'autoAdmin_type'}, $cmd{'type'})
#		)
#	)
	
#	my @params;
#	my $inputparam;
#	my $switch;
#	
#	@params = parseCmdLine($cmd{'msg'});
#	
#	$switch = $params[0];
#	$switch = lc $switch;
#	$inputparam = Trim(substr($cmd{'msg'}, length($switch)));

	return 0 unless (
		$config{'autoAdmin'}
		&& !$sc_v{'ai'}{'first'}
		&& $ai_cmdQue > 0
		&& checkTimeOut('ai_code_request')
	);

	my %cmd;
	
	undef $ai_v{'temp'}{'foundID'};
	
	$ai_cmdQue_shift = 0;
	
	while ($ai_cmdQue > 0) {
		undef %cmd;
		
#		print "$ai_cmdQue[$ai_cmdQue_shift]{'user'} - $ai_cmdQue[$ai_cmdQue_shift]{'msg'}\n";
		
		%cmd = %{$ai_cmdQue[$ai_cmdQue_shift]};
		undef %{$ai_cmdQue[$ai_cmdQue_shift]};
		
		$ai_cmdQue_shift++;
		
		$ai_cmdQue-- if ($ai_cmdQue > 0);
		
		if (
			$cmd{'msg'} ne ""
			&& (
				$config{'autoAdmin_type'} eq ""
				|| existsInList($config{'autoAdmin_type'}, $cmd{'type'})
			)
		) {
			$ai_v{'temp'}{'foundID'} = 1;
			
			
#			print "$cmd{'user'} - $cmd{'msg'}\n";
			
			getString(\$cmd{'msg'});
#			getString(\$cmd{'user'});
			
			last;
		};
	};
	
	if (
		$overallAuth{$cmd{'user'}} eq "0"
		|| $overallAuth{$cmd{'user'}} < 0
	) {
		undef $ai_v{'temp'}{'foundID'};
	} elsif (
		$config{'autoAdmin_user'} eq ""
		|| $overallAuth{$cmd{'user'}} > 0
		|| (
			existsInList($config{'autoAdmin_user'}, "g")
			&& (
				$cmd{'type'} eq "g"
				|| getPlayerType($cmd{'ID'}, 2, 0, 2)
			)
		) || (
			existsInList($config{'autoAdmin_user'}, "p")
			&& (
				$cmd{'type'} eq "p"
				|| getPlayerType($cmd{'ID'}, 1, 1)
			)
		) || (
			existsInList($config{'autoAdmin_user'}, "f")
			&& (
				getPlayerType($cmd{'ID'}, 4)
			)
		) || (
			$players{$cmd{'ID'}}{'guild'}{'name'} ne ""
			&& $config{'autoAdmin_guild'} ne ""
			&& existsInList($config{'autoAdmin_guild'}, $players{$cmd{'ID'}}{'guild'}{'name'})
		) || (
			$players{$cmd{'ID'}}{'guild'}{'ID'} ne ""
			&& $config{'autoAdmin_guildID'} ne ""
			&& existsInList($config{'autoAdmin_guildID'}, getID($players{$cmd{'ID'}}{'guild'}{'ID'}))
		)
	) {
		if ($overallAuth{$cmd{'user'}} <= 0) {
#			auth($cmd{'user'}, 1);
			$overallAuth{$cmd{'user'}} = 1;
		}
#	} elsif (!$overallAuth{$cmd{'user'}}) {
#		auth($cmd{'user'}, 1);
	} else {
#		auth($cmd{'user'}, 0);
#		$overallAuth{$cmd{'user'}} = 0;
		undef $ai_v{'temp'}{'foundID'};
	}
	
#	print "類型: ".getPlayerType($cmd{'ID'}, -1, 1, 2)."\n";
#	print "玩家: $cmd{'user'}\n";
#	print "玩家ID: ".getID($cmd{'ID'})."\n";
#	print "工會: $players{$cmd{'ID'}}{'guild'}{'name'}\n";
#	print "工會ID: ".getID($players{$cmd{'ID'}}{'guild'}{'ID'})."\n";
#	print "頻道: $cmd{'type'}\n";
#	print "訊息: $cmd{'msg'}\n";

	return 0 unless ($ai_v{'temp'}{'foundID'});

	$i = 0;
	
	my @params;
	my $inputparam;
	my $switch;
	
	while ($config{"autoAdmin_code_${i}"}) {
		next if (!$config{"autoAdmin_code_${i}_call"});
		
		if (existsInList($config{"autoAdmin_code_${i}"}, $cmd{'msg'})) {
			undef $ai_v{'temp'}{'foundID'};
			
			undef @params;
			undef $inputparam;
			undef $switch;
			
			@params = parseCmdLine($config{"autoAdmin_code_${i}_call"});
			
			$switch = $params[0];
#			$switch = lc $switch;
#			$inputparam = Trim(substr($cmd{'msg'}, length($switch)));
			
			if (
				1
				&& !switchInput($switch, "warp", "recall")
			) {
				$ai_v{'temp'}{'foundID'} = 1;
				printC("◆不允\許的執行指令 ".$config{"autoAdmin_code_${i}_call"}."\n", "alert");
				
				$config{"autoAdmin_code_${i}_call"} = "";
			}
			
			if (!$ai_v{'temp'}{'foundID'}) {
#				printC("◆遠端執行指令 ".$config{"autoAdmin_code_${i}_call"}."\n", "cmd", 1);
				sysLog("event", "遠端", "遠端使用者: $cmd{'user'} 透過 $cmd{'type'} 管道請求執行指令 ".$config{"autoAdmin_code_${i}_call"}, 1);
				parseInput($config{"autoAdmin_code_${i}_call"});
				
				timeOutStart('ai_code_request');
				
				last;
			}
		}
		
		$i++;
	}
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
#				configModify("attackAuto", 1);
				scModify("config", "attackAuto", 1, 1);
			}
			if ($ai_v2{'route_randomWalk_old'} eq "" && $config{'route_randomWalk'} > 0) {
				$ai_v2{'route_randomWalk_old'} = $config{'route_randomWalk'};
#				configModify("route_randomWalk", 0);
				scModify("config", "route_randomWalk", 0, 1);
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
#				configModify("attackAuto", $ai_v2{'attackAuto_old'});
				scModify("config", "attackAuto", $ai_v2{'attackAuto_old'}, 1);
				undef $ai_v2{'attackAuto_old'};
			}
			if ($ai_v2{'route_randomWalk_old'} ne "") {
#				configModify("route_randomWalk", $ai_v2{'route_randomWalk_old'});
				scModify("config", "route_randomWalk", $ai_v2{'route_randomWalk_old'}, 1);
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
#				configModify("verbose", 0);
				scModify("config", "verbose", 0, 1);
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOffS"), $cmd{'user'});
				timeOutStart('ai_thanks_set');
			} else {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("verboseOffF"), $cmd{'user'});
			}
		} elsif ($cmd{'msg'} =~ /\bspeak\b/i) {
			if (!$config{'verbose'}) {
#				configModify("verbose", 1);
				scModify("config", "verbose", 1, 1);
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
#				configModify("follow", 0);
				scModify("config", "follow", 0, 1);
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
#				configModify("follow", 1);
				scModify("config", "follow", 1, 1);
#				configModify("followTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'});
				scModify("config", "followTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'}, 1);
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
#				configModify("tankMode", 0);
				scModify("config", "tankMode", 0, 1);
				timeOutStart('ai_thanks_set');
			}
		} elsif ($cmd{'msg'} =~ /\btank/i) {
			$ai_v{'temp'}{'after'} = $';
			$ai_v{'temp'}{'after'} =~ s/^\s+//;
			$ai_v{'temp'}{'after'} =~ s/\s+$//;
			$ai_v{'temp'}{'targetID'} = ai_getIDFromChat(\%players, $cmd{'user'}, $ai_v{'temp'}{'after'});
			if ($ai_v{'temp'}{'targetID'} ne "") {
				sendMessage(\$remote_socket, $cmd{'type'}, getResponse("tankS"), $cmd{'user'}) if $config{'verbose'};
#				configModify("tankMode", 1);
				scModify("config", "tankMode", 1, 1);
#				configModify("tankModeTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'});
				scModify("config", "tankModeTarget", $players{$ai_v{'temp'}{'targetID'}}{'name'}, 1);
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

1;