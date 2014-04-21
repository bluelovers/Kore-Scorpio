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
		print "�Ұʥ����s���� ($config{'local_host'}:$config{'local_port'})\n";
	} else {
		$input_server_socket = IO::Socket::INET->new(
				Listen		=> 5,
				LocalAddr	=> $config{'local_host'},
				Proto			=> 'tcp',
				Timeout		=> 2,
				Reuse			=> 1);
		($input_server_socket) || die "Error creating local input server: $!";
		print "�Ұʥ����s���� ($config{'local_host'}:".$input_server_socket->sockport().")\n";
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
	print "�s�u�� ($host:$port)... ";
	$$r_socket = IO::Socket::INET->new(
			PeerAddr	=> $host,
			PeerPort	=> $port,
			Proto		=> 'tcp',
			Timeout	=> 4);
	($$r_socket && inet_aton($$r_socket->peerhost()) eq inet_aton($host)) ? print "�w�s�u\n" : print "�L�k�s�u\n";
}

sub input_client {
	my ($input, $switch);
	my $msg;
	my $local_socket;
	my ($addrcheck, $portcheck, $hostcheck);
	my $port;

	print "���Ϳ�J�ݤf... ";
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
		print "��J�ݤf�w�s��\n";
		return $pid;
	}
}

sub killConnection {
	my $r_socket = shift;
	if ($$r_socket && $$r_socket->connected()) {
		print "���u�� (".$$r_socket->peerhost().":".$$r_socket->peerport().")... " if ($config{'debug'});
		close($$r_socket);
		if ($config{'debug'}) {
			!$$r_socket->connected() ? print "�w���u\n" : print "�L�k���u\n";
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

	if ($sc_v{'input'}{'conState'} == 1 && !($remote_socket && $remote_socket->connected()) && timeOut(\%{$timeout_ex{'master'}}) && !$sc_v{'input'}{'conState_tries'}) {
		my (@array, $msg);
		splitUseArray(\@array, $config{'waitRecon'}, ",");

		if ($config{'dcOnDualLogin'} ne "1" && $config{'dcOnDualLogin_protect'} && $sc_v{'parseMsg'}{'dcOnDualLogin'}) {
			printC("���Ұ� dcOnDualLogin_protect �۰ʧ��ܳs�u�n�J�ɶ�\n", "white");

			undef $array[0];
			undef $array[1];

			$array[0] = 4 if ($array[0] < 5);
			$array[1] = 3 if ($array[1] < 5);

			$timeout{'connectServer_auto'}{'timeout'} = getRand($array[0], $array[1]);

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
		print "\n�s�u��D���A��...\n";
		if (!$sc_v{'input'}{'FirstStart'}) {
			if ($config{'waitRecon_noChoice'}) {
				print "�еy�ݤ���, $timeout{'connectServer_auto'}{'timeout'}���۰ʳs�u...\n";
				sleep($timeout{'connectServer_auto'}{'timeout'});
			} else {
				print "\n�s�u��D���A��...\n";
				print "�ߧY�s�u(y/n)�H $timeout{'connectServer_auto'}{'timeout'}���۰ʳs�u...\n";
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
			print "�Ұʦw���n�J...\n";
			undef $ai_v{'msg01DC'};
			sendMasterCodeRequest(\$remote_socket);
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
		print "�K�X�[�K��...\n";
		sendMasterSecureLogin(\$remote_socket, $config{'username'}, $config{'password'}, $ai_v{'msg01DC'});
		undef $ai_v{'msg01DC'};
#Karasu End

	} elsif ($sc_v{'input'}{'conState'} == 1 && checkTimeOut('master') && timeOut(\%{$timeout_ex{'master'}})) {
		relogWait("�s�u�D���A���O��, ���s�s�u��D���A��...", 1);

	} elsif ($sc_v{'input'}{'conState'} == 2 && !($remote_socket && $remote_socket->connected()) && ($config{'server'} ne "" || $config{'charServer_host'}) && !$sc_v{'input'}{'conState_tries'}) {
		print "�s�u��n�J���A��...\n";
		$sc_v{'input'}{'conState_tries'}++;
		if ($config{'charServer_host'}) {
			connection(\$remote_socket, $config{'charServer_host'}, $config{'charServer_port'});
		} else {
			connection(\$remote_socket, $servers[$config{'server'}]{'ip'}, $servers[$config{'server'}]{'port'});
		}
		sendGameLogin(\$remote_socket, $accountID, $sessionID, $sc_v{'input'}{'accountSex'});
		timeOutStart('gamelogin');

	} elsif ($sc_v{'input'}{'conState'} == 2 && checkTimeOut('gamelogin') && ($config{'server'} ne "" || $config{'charServer_host'})) {
		relogWait("�s�u�n�J���A���O��, ���s�s�u��D���A��...", 1);

	} elsif ($sc_v{'input'}{'conState'} == 3 && checkTimeOut('gamelogin') && $config{'char'} ne "") {
		relogWait("�s�u�n�J���A���O��, ���s�s�u��D���A��...", 1);

	} elsif ($sc_v{'input'}{'conState'} == 4 && !($remote_socket && $remote_socket->connected()) && !$sc_v{'input'}{'conState_tries'}) {

		return 0 if ($config{'warpperMode'} && $config{'mapserver'} eq "" && !$sc_v{'warpperMode'}{'done'});

		print "�s�u��a�Ϧ��A��...\n";
		$sc_v{'input'}{'conState_tries'}++;
		initConnectVars();

		if ($config{'warpperMode'} && $sc_v{'warpperMode'}{'ip'} && $sc_v{'warpperMode'}{'port'} && !$sc_v{'warpperMode'}{'done'} && $sc_v{'warpperMode'}{'ip'} ne $sc_v{'warpperMode'}{'from_ip'}){
			connection(\$remote_socket, $sc_v{'warpperMode'}{'ip'}, $sc_v{'warpperMode'}{'port'});
		} else {
			connection(\$remote_socket, $map_ip, $map_port);
			$sc_v{'warpperMode'}{'done'} = 1 if ($config{'warpperMode'} && !$sc_v{'warpperMode'}{'done'});
		}

		sendMapLogin(\$remote_socket, $accountID, $sc_v{'input'}{'charID'}, $sessionID, $sc_v{'input'}{'accountSex2'});
		timeOutStart('maplogin');

	} elsif ($sc_v{'input'}{'conState'} == 4 && checkTimeOut('maplogin')) {
		relogWait("�s�u�a�Ϧ��A���O��, ���s�s�u��D���A��...", 1);

	} elsif ($sc_v{'input'}{'conState'} == 5 && !($remote_socket && $remote_socket->connected())) {
		$sc_v{'input'}{'conState'} = 1;
		undef $sc_v{'input'}{'conState_tries'};

	} elsif ($sc_v{'input'}{'conState'} == 5 && checkTimeOut('play')) {
		relogWait("�s�u�a�Ϧ��A���O��, ���s�s�u��D���A��...", 1);
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
		print "�����n�T��: �۰ʭ��n�ɶ�($config{'autoRestart'})�w��I\n";
		relogWait("���Ұ� autoRestart - ���s�s�u�I", 1);
#		chatLog("���n", "���n�T��: �۰ʭ��n�ɶ��w��, ���s�s�u�I", "im");
		sysLog("im", "���n", "���n�T��: �۰ʭ��n�ɶ�($config{'autoRestart'})�w��, ���s�s�u�I");
	}
#Karasu Start
	# auto-quit
	if ($config{'autoQuit'} && time - $sc_v{'kore'}{'startTime'} > $config{'autoQuit'}) {
		print "�����n�T��: �۰ʵn�X�ɶ��w��I\n";
		print "���Ұ� autoQuit - �ߧY�n�X�I\n";
#		chatLog("���n", "���n�T��: �۰ʵn�X�ɶ��w��, �ߧY�n�X�I", "im");
		sysLog("im", "���n", "���n�T��: �۰ʵn�X�ɶ��w��, �ߧY�n�X�I");
		$quit = 1;
		quit(1, 1);
	}
#Karasu End
}

1;