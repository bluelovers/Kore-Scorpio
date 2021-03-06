#######################################
#######################################
#CONNECTION FUNCTIONS
#######################################
#######################################

our $enabled;
our $injectServer_socket;
our $remote_socket;
our $MAX_READ;

sub input_start {
	$MAX_READ = 30000;

	$remote_socket = IO::Socket::INET->new();
	$config{'local_host'} = "localhost" if (!$config{'local_host'});
	if ($config{'local_port'}) {
		$input_server_socket = IO::Socket::INET->new(
				Listen		=> 5,
				LocalAddr	=> $config{'local_host'},
				LocalPort	=> $config{'local_port'},
				Proto		=> 'tcp',
				Timeout		=> 2,
				Reuse		=> 1);
		($input_server_socket) || die "Error creating local input server: $!";
		print "啟動本機連接埠 ($config{'local_host'}:$config{'local_port'})\n";
	} else {
		$input_server_socket = IO::Socket::INET->new(
				Listen		=> 5,
				LocalAddr	=> $config{'local_host'},
				Proto			=> 'tcp',
				Timeout		=> 2,
				Reuse			=> 1);
		($input_server_socket) || die "Error creating local input server: $!";
		print "啟動本機連接埠 ($config{'local_host'}:".$input_server_socket->sockport().")\n";
	}
	$input_pid = input_client();
	$enabled = 1;

	#Create InjectSocket to comunicate with RO Client ( Xmode )
	if ($option{'X-Kore'} && $^O eq 'MSWin32') {
		#add send packet explorer
		if ($config{'debug_sendPacket'}) {
			addParseFiles("$sc_v{'path'}{'tables'}/sendpackets.txt", \%spackets,\&parseDataFile2);
			parseReload("sendpackets");
		}
		$injectServer_socket = IO::Socket::INET->new(
				Listen		=> 5,
				LocalAddr	=> 'localhost',
				LocalPort	=> 2350,
				Proto		=> 'tcp') || die "Error creating local inject server: $!";
		print "Local inject server started (".$injectServer_socket->sockhost().":2350)\n";

		our $cwd = Win32::GetCwd();
		our $injectDLL_file = $cwd."\\Inject.dll";
		our $GetProcByName = new Win32::API("Tools", "GetProcByName", "P", "N") || die "Could not locate Tools.dll";
	}

	print "\n";
}

sub connection {
	my $r_socket = shift;
	my $host = shift;
	my $port = shift;
	print "連線中 ($host:$port)... ";
	$$r_socket = IO::Socket::INET->new(
			PeerAddr	=> $host,
			PeerPort	=> $port,
			Proto		=> 'tcp',
			Timeout	=> 4);
	($$r_socket && inet_aton($$r_socket->peerhost()) eq inet_aton($host)) ? print "已連線\n" : print "無法連線\n";
}

sub input_client {
	my ($input, $switch);
	my $msg;
	my $local_socket;
	my ($addrcheck, $portcheck, $hostcheck);
	my $port;

	print "產生輸入端口... ";
	# OpenKore Start(server_socket -> input_server_socket)
	$port = ($config{'local_port'}) ? $config{'local_port'} : $input_server_socket->sockport();
	# OpenKore End
	my $pid = fork;
	if ($pid == 0) {
		$local_socket = IO::Socket::INET->new(
				PeerAddr	=> $config{'local_host'},
				PeerPort	=> $port,
				Proto		=> 'tcp',
				Timeout	=> 4);
		($local_socket) || die "Error creating connection to local server: $!";
		while (1) {
			$input = <STDIN>;
			chomp $input;
			($switch) = $input =~ /^(\w*)/;
			if ($input ne "") {
				$local_socket->send($input);
			}
			last if ($input eq "quit" || $input eq "dump");
		}
		close($local_socket);
		exit;
	} else {
		$input_socket = $input_server_socket->accept();
		(inet_aton($input_socket->peerhost()) == inet_aton($config{'local_host'}))
		|| die "Input Socket must be connected from localhost";
		print "輸入端口已連接\n";
		return $pid;
	}
}

sub killConnection {
	my $r_socket = shift;
	if ($$r_socket && $$r_socket->connected()) {
		print "離線中 (".$$r_socket->peerhost().":".$$r_socket->peerport().")... " if ($config{'debug'});
		close($$r_socket);
		if ($config{'debug'}) {
			!$$r_socket->connected() ? print "已離線\n" : print "無法離線\n";
		}
	}
}

sub dataWaiting {
	my $r_fh = shift;
	my $bits;
	vec($bits, fileno($$r_fh), 1) = 1;
	return (select($bits, $bits, $bits, 0.05) > 1);
}

sub input_canRead {
	return undef unless ($enabled);
	my $bits = '';
	vec($bits, $input_socket->fileno, 1) = 1;
	return (select($bits, $bits, $bits, 0.005) > 1);
}

sub input_readLine {
	return undef unless ($enabled);

	my $input;
	$input_socket->recv($input, $MAX_READ);
	return $input;
}

sub stop {
	return unless ($enabled);

	parseInput("exp log") if ($config{'recordExp'} && $record{'exp'}{'start'} ne "" && !(($sc_v{'input'}{'conState'} == 2 || $sc_v{'input'}{'conState'} == 3) && $sc_v{'input'}{'waitingForInput'}));

	$enabled = 0;
#	close($input_server);
	close($input_server_socket);
	close($input_socket);
	kill(9, $input_pid);
}

sub kore_close {
	my $mode = shift;
	$quit = 1;

	if ($option{'X-Kore'}){
		close($server_socket);
#		unlink('buffer');
	}

	undef $SIG{"HUP"};

	stop();
	killConnection(\$remote_socket) if ($remote_socket);

	sleep(1);

	undef %ai_v;
	undef %sc_v;

	sleep(5) if ($mode);

	close;
#	close "STDERR";

	exit 1;

	return 1;
}

#######################################
#######################################
#Check Connection
#######################################
#######################################

sub checkConnection {
	if ($option{'X-Kore'}) {
#		print "conState: $sc_v{'input'}{'conState'}\n";
#		initConnectVars() if ($sc_v{'input'}{'conState'} == 4);
		return 0;
	}

	if (
		$config{'kore_sleepTime'}
		&& (
			$remote_socket && $remote_socket->connected()
			|| $sc_v{'input'}{'conState'} > 0
		)
#		&& $timeout_ex{'master'}{'timeout'} > 0

		&& checkTimeOut("ai_kore_sleepTime")
	) {
#		my $idx = 0;

		if ($sc_v{'input'}{'kore_sleepTime'}{'found'} && $timeout_ex{'master'}{'timeout'} > 0) {
			my @array;

			splitUseArray(\@array, $config{'waitRecon'}, ",");

			$array[0] = 10 if ($array[0] < 10);
			$array[1] = 10 if ($array[1] < 10);

			$sc_v{'input'}{'kore_sleepTime'}{'rand'} = getRand($array[0], $array[1]);

			printC(
					"\n◆啟動 kore_sleepTime".(($config{"kore_sleepTime_$sc_v{'input'}{'kore_sleepTime'}{'index'}"} ne "")?" - ".$config{"kore_sleepTime_$sc_v{'input'}{'kore_sleepTime'}{'index'}"}:"")
				.	"\n\n\t現在時間: ".getFormattedDate(int(time))
				.	"\n\t休眠時間: ".$config{"kore_sleepTime_$sc_v{'input'}{'kore_sleepTime'}{'index'}_start"}." -> ".$config{"kore_sleepTime_$sc_v{'input'}{'kore_sleepTime'}{'index'}_stop"}
				.	"\n\t進入睡眠: $timeout_ex{'master'}{'timeout'} + $sc_v{'input'}{'kore_sleepTime'}{'rand'} 秒\n"
				, "s"
				, 1
			);

			$timeout_ex{'master'}{'timeout'} += $sc_v{'input'}{'kore_sleepTime'}{'rand'};

			undef %{$sc_v{'input'}{'kore_sleepTime'}};

			sleep($timeout_ex{'master'}{'timeout'});

#			undef $sc_v{'input'}{'conState_stop'};
#			undef %{$sc_v{'input'}{'kore_sleepTime'}};

		} elsif ($config{"kore_sleepTime_0_start"} eq "" || $config{"kore_sleepTime_0_stop"} eq "") {
			scModify('config', 'kore_sleepTime', 0, 2);

#			undef $sc_v{'input'}{'conState_stop'};
			undef %{$sc_v{'input'}{'kore_sleepTime'}};
		} else {
			my @localtime = localtime time;
			$localtime[4] = $localtime[4] + 1;

			undef %{$sc_v{'input'}{'kore_sleepTime'}};

			my $idx = 0;

			my ($s_hr,$s_min,$s_sec);
			my ($e_hr,$e_min,$e_sec);

			while (1) {
				last if ($config{"kore_sleepTime_${idx}_start"} eq "" || $config{"kore_sleepTime_${idx}_stop"} eq "");

				($s_hr,$s_min,$s_sec) = $config{"kore_sleepTime_${idx}_start"}=~ /(\d+):(\d+):(\d+)/;
				($e_hr,$e_min,$e_sec) = $config{"kore_sleepTime_${idx}_stop"}=~ /(\d+):(\d+):(\d+)/;

#				print $config{"kore_sleepTime_${idx}_start"}."\n";
#				print $config{"kore_sleepTime_${idx}_stop"}."\n";
#
#				print "$s_hr <= $localtime[2] : ".($s_hr <= $localtime[2])."\n";
#				print "$s_min <= $localtime[1] : ".($s_min <= $localtime[1])."\n";
#				print "$s_sec <= $localtime[0] : ".($s_sec <= $localtime[0])."\n";
#
#				print "$e_hr >= $localtime[2] : ".($e_hr >= $localtime[2])."\n";
#				print "$e_min <= $localtime[1] : ".($e_min <= $localtime[1])."\n";
#				print "$e_sec <= $localtime[0] : ".($e_sec <= $localtime[0])."\n";

				if (
					(
						$config{"kore_sleepTime_${idx}_day"} eq ""
						|| $config{"kore_sleepTime_${idx}_day"} == $localtime[6]
					)
#					&& $s_hr <= $localtime[2]
#					&& $s_min <= $localtime[1]
#					&& $s_sec <= $localtime[0]

#					&& $e_hr >= $localtime[2]
#					&& $e_min <= $localtime[1]
#					&& $e_sec <= $localtime[0]

					&& (
						$localtime[2] > $s_hr
						|| (
							$localtime[2] == $s_hr
							&& (
								$localtime[1] > $s_min
								|| (
									$localtime[1] == $s_min
									&& $localtime[0] >= $s_sec
								)
							)
						)
					) && (
						$localtime[2] < $e_hr
						|| (
							$localtime[2] == $e_hr
							&& (
								$localtime[1] < $e_min
								|| (
									$localtime[1] == $e_min
									&& $localtime[0] < $e_sec
								)
							)
						)
					)
				) {
					my $halt_sec = 0;
					my $hr	= $e_hr - $localtime[2];
					my $min	= $e_min - $localtime[1];
					my $sec	= $e_sec - $localtime[0];

					if ($hr < 0) { $hr = $hr + 24;}
					my $reconnect_time = $hr * 3600 + $min * 60 + $sec;

					$sc_v{'input'}{'conState'} = 1;
					undef $sc_v{'input'}{'conState_tries'};

					undef @ai_seq;
					undef @ai_seq_args;

#					print "\nwaiting Time : ".$config{"kore_sleepTime_${idx}_start"}." to ".$config{"kore_sleepTime_${idx}_stop"}."\n\n";
#					sysLog("a", "waiting Time : ".$config{"kore_sleepTime_${idx}_start"}." to ".$config{"kore_sleepTime_${idx}_stop"}."\n");
					$timeout_ex{'master'}{'time'} = time;
					$timeout_ex{'master'}{'timeout'} = $reconnect_time;
					killConnection(\$remote_socket);

					timeOutStart(-1, "ai_kore_sleepTime");

					$sc_v{'input'}{'kore_sleepTime'}{'index'} = $idx;
					$sc_v{'input'}{'kore_sleepTime'}{'found'} = 1;

					last;
				} else {
					timeOutStart("ai_kore_sleepTime");
#					print "123";
				}

				$idx++;
			}
		}
	}

	if ($sc_v{'input'}{'conState'} == 1 && !($remote_socket && $remote_socket->connected()) && timeOut(\%{$timeout_ex{'master'}}) && !$sc_v{'input'}{'conState_tries'}) {
		my (@array, $msg);
		splitUseArray(\@array, $config{'waitRecon'}, ",");

		if ($config{'dcOnDualLogin'} ne "1" && $config{'dcOnDualLogin_protect'} && $sc_v{'parseMsg'}{'dcOnDualLogin'}) {
			printC("◆啟動 dcOnDualLogin_protect 自動改變連線登入時間\n", "white");

			undef $array[0];
			undef $array[1];

			$array[0] = 4 if ($array[0] < 5);
			$array[1] = 3 if ($array[1] < 5);

			$timeout{'connectServer_auto'}{'timeout'} = getRand($array[0], $array[1]);
#			$timeout{'connectServer_auto'}{'timeout'} = 17;

			scModify('config', 'waitRecon_noChoice', 1, 1) if (!$config{'waitRecon_noChoice'});

			$sc_v{'timeout'}{'gamelogin'} = $timeout{'gamelogin'}{'timeout'} if ($sc_v{'timeout'}{'gamelogin'} eq "");
			$timeout{'gamelogin'}{'timeout'} = getRand($array[0], $array[1]);

			$sc_v{'timeout'}{'master'} = $timeout{'master'}{'timeout'} if ($sc_v{'timeout'}{'master'} eq "");
			$timeout{'master'}{'timeout'} = getRand($array[0], $array[1]);

			$sc_v{'timeout'}{'maplogin'} = $timeout{'maplogin'}{'timeout'} if ($sc_v{'timeout'}{'maplogin'} eq "");
			$timeout{'maplogin'}{'timeout'} = getRand($array[0], $array[1]);

#			$sc_v{'timeout'}{'play'} = $timeout{'play'}{'timeout'} if ($sc_v{'timeout'}{'play'} eq "");
#			$timeout{'play'}{'timeout'} = getRand($array[0], $array[1]);

#			$sc_v{'timeout'}{'gamelogin'} = $timeout{'connectServer_auto'}{'timeout'} if ($sc_v{'timeout'}{'gamelogin'} eq "");
#			$sc_v{'timeout'}{'gamelogin'} = $timeout{'connectServer_auto'}{'timeout'} if ($sc_v{'timeout'}{'gamelogin'} eq "");

		} else {
			$array[0] = 10 if ($array[0] < 10);
			$array[1] = 10 if ($array[1] < 10);
			$timeout{'connectServer_auto'}{'timeout'} = ($sc_v{'input'}{'MinWaitRecon'}) ? getRand(10, 10) : getRand($array[0], $array[1]);
		}

		sleep(2) if ($sc_v{'input'}{'FirstStart'});
		print "\n連線到主伺服器...\n";
		if (!$sc_v{'input'}{'FirstStart'}) {
			if ($config{'waitRecon_noChoice'}) {
				print "請稍待片刻, $timeout{'connectServer_auto'}{'timeout'}秒後自動連線...\n";
				sleep($timeout{'connectServer_auto'}{'timeout'});
			} else {
				print "\n連線到主伺服器...\n";
				print "立即連線(y/n)？ $timeout{'connectServer_auto'}{'timeout'}秒後自動連線...\n";
				timeOutStart('connectServer_auto');
#				undef $msg;
				while (!checkTimeOut('connectServer_auto')) {
					usleep($config{'sleepTime'});
					if (dataWaiting(\$input_socket)) {
#						$input_socket->recv($msg, $MAX_READ);
						$msg = input_readLine();
					}
					last if $msg;
				}
				if ($msg =~ /n/) {
					quit();
					return;
				}
			}
		}
		$sc_v{'input'}{'conState_tries'}++;
#		undef $msg;
		connection(\$remote_socket, $config{"master_host_$config{'master'}"}, $config{"master_port_$config{'master'}"});
#Karasu Start
		# Secure login
		if ($config{'secureLogin'}) {
			print "啟動安全登入...\n";
			undef $ai_v{'msg01DC'};
			sendMasterCodeRequest(\$remote_socket);
			sysLog("im", "重要", "重要訊息: 啟動安全登入...");
#Karasu End
		} else {
			sendMasterLogin(\$remote_socket, $config{'username'}, $config{'password'});
		}
		timeOutStart('master');
		undef $sc_v{'input'}{'FirstStart'};
		undef $sc_v{'input'}{'MinWaitRecon'};

#Karasu Start
	# Secure login
	} elsif ($sc_v{'input'}{'conState'} == 1 && $config{'secureLogin'} >= 1 && $ai_v{'msg01DC'} ne "" && !checkTimeOut('master') && $sc_v{'input'}{'conState_tries'}) {
		print "密碼加密中...\n";
		sysLog("im", "重要", "重要訊息: 密碼加密中...");
		sendMasterSecureLogin(\$remote_socket, $config{'username'}, $config{'password'}, $ai_v{'msg01DC'});
		undef $ai_v{'msg01DC'};
#Karasu End

	} elsif ($sc_v{'input'}{'conState'} == 1 && checkTimeOut('master') && timeOut(\%{$timeout_ex{'master'}})) {
		relogWait("連線主伺服器逾時, 重新連線到主伺服器...", 1);
	} elsif ($sc_v{'input'}{'conState'} == 2 && !($remote_socket && $remote_socket->connected()) && ($config{'server'} ne "" || $config{'charServer_host'}) && !$sc_v{'input'}{'conState_tries'}) {
		print "連線到登入伺服器...\n";
		$sc_v{'input'}{'conState_tries'}++;
		if ($config{'charServer_host'}) {
			connection(\$remote_socket, $config{'charServer_host'}, $config{'charServer_port'});
		} else {
			connection(\$remote_socket, $servers[$config{'server'}]{'ip'}, $servers[$config{'server'}]{'port'});
		}
		sendGameLogin(\$remote_socket, $accountID, $sessionID, $sc_v{'input'}{'accountSex'});
		timeOutStart('gamelogin');

	} elsif ($sc_v{'input'}{'conState'} == 2 && checkTimeOut('gamelogin') && ($config{'server'} ne "" || $config{'charServer_host'})) {
		relogWait("連線登入伺服器逾時, 重新連線到主伺服器...", 1);

	} elsif ($sc_v{'input'}{'conState'} == 3 && checkTimeOut('gamelogin') && $config{'char'} ne "") {
		relogWait("連線登入伺服器逾時, 重新連線到主伺服器...", 1);

	} elsif ($sc_v{'input'}{'conState'} == 4 && !($remote_socket && $remote_socket->connected()) && !$sc_v{'input'}{'conState_tries'}) {

		return 0 if ($config{'warpperMode'} && $config{'mapserver'} eq "" && !$sc_v{'warpperMode'}{'done'});

		print "連線到地圖伺服器...\n";
		$sc_v{'input'}{'conState_tries'}++;
		initConnectVars();

		if ($config{'warpperMode'} && $sc_v{'warpperMode'}{'ip'} && $sc_v{'warpperMode'}{'port'} && !$sc_v{'warpperMode'}{'done'} && $sc_v{'warpperMode'}{'ip'} ne $sc_v{'warpperMode'}{'from_ip'}){
			connection(\$remote_socket, $sc_v{'warpperMode'}{'ip'}, $sc_v{'warpperMode'}{'port'});
		} else {
			connection(\$remote_socket, $map_ip, $map_port);
			$sc_v{'warpperMode'}{'done'} = 1 if ($config{'warpperMode'} && !$sc_v{'warpperMode'}{'done'});
		}

		if ($config{'serverType'}) {
			sendMapLoginPK(\$remote_socket, $accountID, $sessionID, $sc_v{'input'}{'accountSex2'});
		} else {
			sendMapLogin(\$remote_socket, $accountID, $sc_v{'input'}{'charID'}, $sessionID, $sc_v{'input'}{'accountSex2'});
		}

#		sendMapLogin(\$remote_socket, $accountID, $sc_v{'input'}{'charID'}, $sessionID, $sc_v{'input'}{'accountSex2'});
		timeOutStart('maplogin');

	} elsif ($sc_v{'input'}{'conState'} == 4 && checkTimeOut('maplogin')) {
		sysLog("im", "連線", "連線地圖伺服器逾時[$sc_v{'input'}{'conState'}-$timeout{'maplogin'}{'timeout'}], 重新連線到主伺服器...");
		relogWait("連線地圖伺服器逾時, 重新連線到主伺服器...", 1);
		
#		print "Packet Switch: $lastswitch + $switch\n";
#		dumpData($last_know_msg.$msg, 0, 0, "Debug: 連線地圖伺服器逾時, 重新連線到主伺服器...\n$lastswitch + $switch") if ($config{'debug'} || $config{'debug_packet'});
	} elsif ($sc_v{'input'}{'conState'} == 5 && !($remote_socket && $remote_socket->connected())) {
		$sc_v{'input'}{'conState'} = 1;
		undef $sc_v{'input'}{'conState_tries'};

	} elsif ($sc_v{'input'}{'conState'} == 5 && checkTimeOut('play')) {
		sysLog("im", "連線", "連線地圖伺服器逾時[$sc_v{'input'}{'conState'}-$timeout{'play'}{'timeout'}], 重新連線到主伺服器...");
		relogWait("連線地圖伺服器逾時, 重新連線到主伺服器...", 1);
		
#		print "Packet Switch: $lastswitch + $switch\n";
#		dumpData($last_know_msg.$msg, 0, 0, "Debug: 連線地圖伺服器逾時, 重新連線到主伺服器...\n$lastswitch + $switch") if ($config{'debug'} || $config{'debug_packet'});
	}

	if (
		$config{'autoRestart'}
		&& time - $sc_v{'input'}{'startTime'} > $config{'autoRestart'}
		&& !$sc_v{'input'}{'autoStartPause'}
		&& binFind(\@ai_seq, "attack") eq ""
		&& binFind(\@ai_seq, "take") eq ""
		&& binFind(\@ai_seq, "items_take") eq ""
		&& binFind(\@ai_seq, "talkAuto") eq ""
		&& binFind(\@ai_seq, "storageAuto") eq ""
		&& binFind(\@ai_seq, "sellAuto") eq ""
		&& binFind(\@ai_seq, "buyAuto") eq ""
	) {
		$sc_v{'input'}{'startTime'} = time;
		print "◆重要訊息: 自動重登時間($config{'autoRestart'})已到！\n";
		relogWait("◆啟動 autoRestart - 重新連線！", 1);
#		chatLog("重要", "重要訊息: 自動重登時間已到, 重新連線！", "im");
		sysLog("im", "重要", "重要訊息: 自動重登時間($config{'autoRestart'})已到, 重新連線！");
	}
#Karasu Start
	# auto-quit
	if ($config{'autoQuit'} && time - $sc_v{'kore'}{'startTime'} > $config{'autoQuit'}) {
		print "◆重要訊息: 自動登出時間已到！\n";
		print "◆啟動 autoQuit - 立即登出！\n";
#		chatLog("重要", "重要訊息: 自動登出時間已到, 立即登出！", "im");
		sysLog("im", "重要", "重要訊息: 自動登出時間已到, 立即登出！");
		$quit = 1;
		quit(1, 1);
#	} elsif (
#		$config{'kore_sleepTime'}
#		&& (
#			$remote_socket && $remote_socket->connected()
#			|| $sc_v{'input'}{'conState'} > 0
#		)
#		&& 0
#	) {
#		my $idx = 0;
#
#		if ($config{"kore_sleepTime_${idx}_start"} eq "" || $config{"kore_sleepTime_${idx}_stop"} eq "") {
#			scModify('config', 'kore_sleepTime', 0, 2);
#		} else {
#			my @localtime = localtime time;
#			$localtime[4] = $localtime[4] + 1;
#
#			my ($s_hr,$s_min,$s_sec);
#			my ($e_hr,$e_min,$e_sec);
#
#			while (1) {
#				($s_hr,$s_min,$s_sec) = $config{"kore_sleepTime_${idx}_start"}=~ /(\d+):(\d+):(\d+)/;
#				($e_hr,$e_min,$e_sec) = $config{"kore_sleepTime_${idx}_stop"}=~ /(\d+):(\d+):(\d+)/;
#
#				if (
#					(
#						$config{"kore_sleepTime_${idx}_day"} eq ""
#						|| $config{"kore_sleepTime_${idx}_day"} == $localtime[6]
#					)
#					&& $s_hr >= $localtime[2]
#					&& $s_min >= $localtime[1]
#					&& $s_sec >= $localtime[0]
#					&& $e_hr <= $localtime[2]
#					&& $e_min <= $localtime[1]
#					&& $e_sec <= $localtime[0]
#				) {
#					my $halt_sec = 0;
#					my $hr	= $e_hr - $s_hr;
#					my $min	= $e_min - $s_min;
#					my $sec	= $e_sec - $s_sec;
#
#					if ($hr<0) { $hr = $hr + 24;}
#					my $reconnect_time = $hr * 3600 + $min * 60 + $sec;
#
#					$sc_v{'input'}{'conState'} = 1;
#					undef $sc_v{'input'}{'conState_tries'};
#
#					undef @ai_seq;
#					undef @ai_seq_args;
#
#					print "\nwaiting Time : ".$config{"kore_sleepTime_${idx}_start"}." to ".$config{"kore_sleepTime_${idx}_stop"}."\n\n";
#					sysLog("a", "waiting Time : ".$config{"kore_sleepTime_${idx}_start"}." to ".$config{"kore_sleepTime_${idx}_stop"}."\n");
#					$timeout_ex{'master'}{'time'} = time;
#					$timeout_ex{'master'}{'timeout'} = $reconnect_time;
#					killConnection(\$remote_socket);
#
#					last;
#				}
#
#				$idx++;
#			}
#		}
	}
#Karasu End
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

1;