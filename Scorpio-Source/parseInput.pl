#######################################
#PARSE INPUT
#######################################

sub parseInput {
	my $input	= shift;
	my $mode	= shift;
	my ($arg1, $arg2, $switch, $map_string);

	printC("Echo: $input\n", "debug") if (!$mode && ($config{'debug'} >= 2 || $config{'echoInput'}));
#	($switch) = $input =~ /^(\w*)/;

	return 0 if ($input eq "");

	my @params;
	my $inputparam;
	my %tmpVal;

	@params = parseCmdLine($input);

#	$switch = shift(@params);
	$switch = $params[0];
	$switch = lc $switch;
	$inputparam = Trim(substr($input, length($switch)));

	if ($mode && $sc_v{'kore'}{'lock'} && !switchInput($switch, "quit", "close", "end")) {
		return 0;
	}

#Check if in special state

#	if ($sc_v{'input'}{'conState'} == 2 && $sc_v{'input'}{'waitingForInput'}) {
#		$config{'server'} = $input;
#		$config{'server_name'} = $servers[$input]{'name'};
#		$sc_v{'input'}{'waitingForInput'} = 0;
#		writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);
#	} elsif ($sc_v{'input'}{'conState'} == 3 && $sc_v{'input'}{'waitingForInput'}) {
#		$config{'char'} = $input;
#		$sc_v{'input'}{'waitingForInput'} = 0;
#		writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);
#		sendCharLogin(\$remote_socket, $config{'char'});
#		timeOutStart('gamelogin');

	if (!$option{'X-Kore'} && $sc_v{'input'}{'waitingForInput'}) {

		if ($sc_v{'input'}{'conState'} == 2) {
			$config{'server'} = $input;
			$config{'server_name'} = $servers[$input]{'name'};

			writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);

			$sc_v{'input'}{'waitingForInput'} = 0;
		} elsif ($sc_v{'input'}{'conState'} == 3) {
#			$config{'char'} = $input;
#
#			writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);
#
			scModify("config", "char", $input, 2);

			sendCharLogin(\$remote_socket, $config{'char'});
			timeOutStart('gamelogin');

			$sc_v{'input'}{'waitingForInput'} = 0;
		} elsif ($sc_v{'input'}{'conState'} == 4){
			$config{'mapserver'} = $input;

			scMapJump($config{"map_host_$config{'master'}"."_$config{'server'}"."_$config{'mapserver'}"}, $config{'map_port'});

			writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);

			$sc_v{'input'}{'waitingForInput'} = 0;
		}

#Parse command...ugh

	} elsif ($switch eq "a") {

		if (isNum($params[1])) {

			if ($monstersID[$params[1]] eq "") {
				$tmpVal{'text'} = "�Ǫ� $params[1] ���s�b";
			} else {
				attack($monstersID[$params[1]]);
			}

		} elsif (switchInput($params[1], "no", "n")) {

			scModify("config", "attackAuto", 1, 1);

		} elsif (switchInput($params[1], "yes", "y")) {

			scModify("config", "attackAuto", 2, 1);

		} else {
			$tmpVal{'text'} = "<�Ǫ��s�� | no | yes>";
			$tmpVal{'type'} = 1;
		}

		printErr('attack', 'Attack Monster', $tmpVal{'text'}, $tmpVal{'type'});

	} elsif ($switch eq "auth") {

		if ($params[1] eq "" || ($params[2] ne "1" && $params[2] ne "0")) {

			printErr('auth', 'Overall Authorize', "<���a�W��> <0=�� | 1=�}>", 1);

		} else {
			auth($params[1], $params[2]);
		}

	} elsif ($switch eq "bestow") {

		if ($currentChatRoom eq "") {
			$tmpVal{'text'} = "�A���b��ѫǸ�";
		} elsif (!isNum($params[1])) {
			$tmpVal{'text'} = "<���a�s��>";
			$tmpVal{'type'} = 1;
		} elsif ($currentChatRoomUsers[$params[1]] eq "") {
			$tmpVal{'text'} = "�����I���a $arg1 ���s�b";
		} else {
			sendChatRoomBestow(\$remote_socket, $currentChatRoomUsers[$params[1]]);
		}

		printErr($switch, 'Bestow Admin in Chat', $tmpVal{'text'}, $tmpVal{'type'});

	} elsif ($switch eq "buy") {

		if ($params[1] eq "" && $talk{'buyOrSell'}) {
			sendGetStoreList(\$remote_socket, $talk{'ID'});
		} elsif ($params[1] eq "") {
			$tmpVal{'text'} = "<�ө����~�s��> [<�ƶq>]";
			$tmpVal{'type'} = 1;
		} elsif ($storeList[$params[1]] eq "") {
			$tmpVal{'text'} = "���ʶR���~ $params[1] ���s�b";
		} else {
			$params[2] = ($params[2] <= 0) ? 1 : $params[2];
			sendBuy(\$remote_socket, $storeList[$params[1]]{'nameID'}, $params[2]);
		}

		printErr($switch, 'Buy Store Item', $tmpVal{'text'}, $tmpVal{'type'});

	} elsif (switchInput($switch, "c", "p", "g")) {

		if ($inputparam eq "") {

			if (switchInput($switch, "p")) {
				$tmpVal{'title'} = "Party Chat";
			} elsif (switchInput($switch, "g")) {
				$tmpVal{'title'} = "Guild Chat";
			} else {
				$tmpVal{'title'} = "Chat";
			}

			printErr($switch, $tmpVal{'title'}, "<�T��>", 1);
		} else {
			sendMessage(\$remote_socket, $switch, $inputparam);
		}

	#Cart command - chobit andy 20030101
	} elsif ($switch eq "cart") {
#		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
#		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
#		($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\w+)/;
#		($arg4) = $input =~ /^[\s\S]*? \w+ \d+ \d+ (\w+)/;

		$tmpVal{'tag'} = $switch;

		if (!$cart{'weight_max'}) {

			$tmpVal{'title'} = "Cart Functions";
			$tmpVal{'text'} = "�b�S������������A�U�L�k�ϥΤ�����������O";

		} elsif (switchInput($params[1], "", "eq", "u", "nu", "card", "arrow")) {

			$tmpVal{'cart'} = "Capacity: " . int($cart{'items'}) . "/" . int($cart{'items_max'}) . "  Weight: " . int($cart{'weight'}) . "/" . int($cart{'weight_max'}) . mathPercent($cart{'weight'}, $cart{'weight_max'}, 0, "(%.2f%)");
			getItemList(\@{$cart{'inventory'}}, $params[1], "Cart", $tmpVal{'cart'});

		} elsif (switchInput($params[1], "add")) {

			$tmpVal{'tag'} .= " $params[1]";
			$tmpVal{'title'} = "Add Item to Cart";

			if (isNum($params[2])) {

				if (!%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					$tmpVal{'text'} = "����J���~ $params[2] ���s�b";
				} else {
					if (!$params[3] || $params[3] > $chars[$config{'char'}]{'inventory'}[$params[2]]{'amount'}) {
						$params[3] = $chars[$config{'char'}]{'inventory'}[$params[2]]{'amount'};
					}
					sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, $params[3]);
				}

			} else {
				$tmpVal{'text'} = "<���~�s��> [<�ƶq>]";
				$tmpVal{'type'} = 1;
			}

		} elsif (switchInput($params[1], "get")) {

			$tmpVal{'tag'} .= " $params[1]";
			$tmpVal{'title'} = "Get Item from Cart";

			if (isNum($params[2])) {

				if (!%{$cart{'inventory'}[$params[2]]}) {
					$tmpVal{'text'} = "�����X���~ $params[2] ���s�b";
				} else {
					if (!$params[3] || $params[3] > $cart{'inventory'}[$params[2]]{'amount'} || $params[3] eq "storage") {
						$params[4] = "storage" if ($params[3] eq "storage");
						$params[3] = $cart{'inventory'}[$params[2]]{'amount'};
					}
					if ($params[4] eq "storage") {
						sendCartGetToStorage(\$remote_socket, $params[2], $params[3]);
					} else {
						sendCartGet(\$remote_socket, $params[2], $params[3]);
					}
				}

			} else {
				$tmpVal{'text'} = "<��������~�s��> [<�ƶq>] [<storage>]";
				$tmpVal{'type'} = 1;
			}

		} elsif (switchInput($params[1], "desc")) {

			$tmpVal{'tag'} .= " $params[1]";
			$tmpVal{'title'} = "Cart Item Description";

			if (isNum($params[2])) {

				if (!%{$cart{'inventory'}[$params[2]]}) {
					$tmpVal{'text'} = "���˵����~ $params[2] ���s�b";
				} else {
					printDesc(0, $cart{'inventory'}[$params[2]]{'nameID'}, fixingName(\%{$cart{'inventory'}[$arg2]}));
				}

			} else {
				$tmpVal{'text'} = "<��������~�s��>";
				$tmpVal{'type'} = 1;
			}

		} else {
			$tmpVal{'title'} = "Cart Items List";
			$tmpVal{'text'} = "[<u | eq | nu | desc>] [<��������~�s��>]";
			$tmpVal{'type'} = 1;
		}

		printErr($tmpVal{'tag'}, $tmpVal{'title'}, $tmpVal{'text'}, $tmpVal{'type'});

	} elsif ($switch eq "chat") {
		($replace, $title) = $input =~ /(^[\s\S]*? \"([\s\S]*?)\" ?)/;
		$qm = quotemeta $replace;
		$input =~ s/$qm//;
		@arg = split / /, $input;
		if ($title eq "") {
			print	"�y�k���~ 'chat' (Create Chat Room)\n"
				,qq~�ϥΤ�k: chat "<���D>" [<�H�ƤW��> <0=�p�H> <�K�X>]\n~;
		} elsif ($currentChatRoom ne "") {
			print	"�o�Ϳ��~ 'chat' (Create Chat Room)\n"
				, "�A�w�g�b��ѫǸ̤F.\n";
		} elsif ($shop{'opened'}) {
			print	"�o�Ϳ��~ 'chat' (Create Chat Room)\n"
				, "�\\�u���ɭԥ����M��, ���M�i��|�Q����o�Ͼ�.\n";
		} else {
			if ($arg[0] eq "" || $arg[0] >= 20 || $arg[0] < 2) {
				$arg[0] = 20;
			}
			$arg[1] = ($arg[1] eq "") ? 1 : $arg[1];
			sendChatRoomCreate(\$remote_socket, $title, $arg[0], $arg[1], $arg[2]);
			$createdChatRoom{'title'} = $title;
			$createdChatRoom{'ownerID'} = $accountID;
			$createdChatRoom{'limit'} = $arg[0];
			$createdChatRoom{'public'} = $arg[1];
			$createdChatRoom{'num_users'} = 1;
			$createdChatRoom{'users'}{$chars[$config{'char'}]{'name'}} = 2;
		}

	} elsif ($switch eq "chatmod") {
		($replace, $title) = $input =~ /(^[\s\S]*? \"([\s\S]*?)\" ?)/;
		$qm = quotemeta $replace;
		$input =~ s/$qm//;
		@arg = split / /, $input;
		if ($title eq "") {
			print	"�y�k���~ 'chatmod' (Modify Chat Room)\n"
				,qq~�ϥΤ�k: chatmod "<���D>" [<�H�ƤW��> <0=�p�H> <�K�X>]\n~;
		} else {
			$arg[0] = ($arg[0] eq "") ? 20 : $arg[0];
			$arg[1] = ($arg[1] eq "") ? 1 : $arg[1];
			sendChatRoomChange(\$remote_socket, $title, $arg[0], $arg[1], $arg[2]);
		}

	} elsif ($switch eq "cl") {
#		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
#		if ($arg1 eq "all") {
#			chatLog_clear($arg1, "all");
#		} else {
#			chatLog_clear($arg1);
#		}

		if ($params[1] eq "all") {
			sysLog_clear($params[1], "all");
		} else {
			sysLog_clear($inputparam);
		}

#	} elsif ($switch eq "conf") {
#		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
#		($arg2) = $input =~ /^[\s\S]*? \w+ ([\s\S]+)$/;
#		@{$ai_v{'temp'}{'conf'}} = keys %config;
#		if ($arg1 eq "") {
#			print	"�y�k���~ 'conf' (Config Modify)\n"
#				, "�ϥΤ�k: conf <�ܼƦW��> [<�ƭ� | value>]\n";
#		} elsif (binFind(\@{$ai_v{'temp'}{'conf'}}, $arg1) eq "") {
#			print "�o�Ϳ��~ 'conf' (Config Modify)\n"
#				, "�A�Q�]�w���ܼ� $arg1 ���s�b.\n";
#		} elsif ($arg2 eq "value") {
#			print "$arg1 �ثe���Ȭ� $config{$arg1}\n";
#		} else {
#			configModify($arg1, $arg2);
#		}

	} elsif ($switch eq "cri") {
		if ($currentChatRoom eq "") {
			print "�o�Ϳ��~ 'cri' (Chat Room Information)\n"
				, "�|���i�J��ѫ�, ��J 'crl' �i�d�ݲ�ѫǦC��.\n";
		} else {
			$~ = "CRI";
			print "----------------- ��ѫǸ�T -----------------\n";
			$public_string = ($chatRooms{$currentChatRoom}{'public'}) ? "��" : "�p";
			format CRI =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<(@>/@>)
$public_string, $chatRooms{$currentChatRoom}{'title'}, $chatRooms{$currentChatRoom}{'num_users'}, $chatRooms{$currentChatRoom}{'limit'}
.
            write;
			print "----------------------------------------------\n";
			$~ = "CRIUSERS";
			print "#   �W��\n";
			for ($i = 0; $i < @currentChatRoomUsers; $i++) {
				next if ($currentChatRoomUsers[$i] eq "");
				$user_string = $currentChatRoomUsers[$i];
				$admin_string = ($chatRooms{$currentChatRoom}{'users'}{$currentChatRoomUsers[$i]} > 1) ? "(�֦���)" : "";
				format CRIUSERS =
@<< @<<<<<<<<<<<<<<<<<<<<<<<   @<<<<<<<
$i, $user_string,                   $admin_string
.
				write;
			}
			print "----------------------------------------------\n";
		}

	} elsif ($switch eq "crl") {
		$~ = "CRLIST";
		print "--------------------------------- ��ѫǦC�� ---------------------------------\n";
		print "#   ���D                                  �֦���                  �H ��  ��/�p\n";
		for ($i = 0; $i < @chatRoomsID; $i++) {
			next if ($chatRoomsID[$i] eq "");
			$owner_string = ($chatRooms{$chatRoomsID[$i]}{'ownerID'} ne $accountID) ? $players{$chatRooms{$chatRoomsID[$i]}{'ownerID'}}{'name'} : $chars[$config{'char'}]{'name'};
			$public_string = ($chatRooms{$chatRoomsID[$i]}{'public'}) ? "��   " : "   ��";
			format CRLIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<< @>/@>  @<<<<
$i, $chatRooms{$chatRoomsID[$i]}{'title'}, $owner_string, $chatRooms{$chatRoomsID[$i]}{'num_users'}, $chatRooms{$chatRoomsID[$i]}{'limit'}, $public_string
.
			write;
		}
		print "------------------------------------------------------------------------------\n";
		print "�п�J 'join <��ѫǽs��> [<�K�X>]' �i�J��ѫ�\n";

	} elsif ($switch eq "deal") {
		@arg = split / /, $input;
		shift @arg;
		if (%currentDeal && $arg[0] =~ /^\d+$/) {
			print	"�o�Ϳ��~ 'deal' (Deal a Player)\n"
				, "�A�w�g�b�����.\n";
		} elsif (%incomingDeal && $arg[0] =~ /^\d+$/) {
			print	"�o�Ϳ��~ 'deal' (Deal a Player)\n"
				, "�A�������פ�i�椤�����.\n";
		} elsif ($arg[0] =~ /^\d+$/ && $playersID[$arg[0]] eq "") {
			print	"�o�Ϳ��~ 'deal' (Deal a Player)\n"
				, "��������a $arg[0] ���s�b.\n";
		} elsif ($arg[0] =~ /^\d+$/) {
			$outgoingDeal{'ID'} = $playersID[$arg[0]];
			sendDeal(\$remote_socket, $playersID[$arg[0]]);
			print "�A�߰� $players{$playersID[$arg[0]]}{'name'} �@���@�N���\n";

		} elsif ($arg[0] eq "no" && !%incomingDeal && !%outgoingDeal && !%currentDeal) {
			print	"�o�Ϳ��~ 'deal' (Deal a Player)\n"
				, "�S���������i�H����.\n";
		} elsif ($arg[0] eq "no" && (%incomingDeal || %outgoingDeal)) {
			sendDealCancel(\$remote_socket);
		} elsif ($arg[0] eq "no" && %currentDeal) {
			sendCurrentDealCancel(\$remote_socket);


		} elsif ($arg[0] eq "" && !%incomingDeal && !%currentDeal) {
			print	"�o�Ϳ��~ 'deal' (Deal a Player)\n"
				, "�S���������i�H����.\n";
		} elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && !$currentDeal{'other_finalize'}) {
			print	"�o�Ϳ��~ 'deal' (Deal a Player)\n"
				, "�L�k������� - $currentDeal{'name'} �|���T�{���.\n";
		} elsif ($arg[0] eq "" && $currentDeal{'final'}) {
			print	"�o�Ϳ��~ 'deal' (Deal a Player)\n"
				, "�A�w�g�T�{�}�l�洫.\n";
		} elsif ($arg[0] eq "" && %incomingDeal) {
			sendDealAccept(\$remote_socket);
		} elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && $currentDeal{'other_finalize'}) {
			sendDealTrade(\$remote_socket);
			$currentDeal{'final'} = 1;
			print "�A�T�{�}�l�洫\n";
			parseInput("dl");
		} elsif ($arg[0] eq "" && %currentDeal) {
			sendDealAddItem(\$remote_socket, 0, $currentDeal{'you_zenny'});
			sendDealFinalize(\$remote_socket);

		} elsif ($arg[0] eq "add" && !%currentDeal) {
			print	"�o�Ϳ��~ 'deal add' (Add Item to Deal)\n"
				, "�L�k��J���󪫫~������ - �A�S���b���.\n";
		} elsif ($arg[0] eq "add" && $arg[1] eq "") {
			print	"�y�k���~ 'deal add' (Add Item to Deal)\n"
				, "�ϥΤ�k: deal add <���~�s�� | z=Zeny> [<�ƶq>]\n";
		} elsif ($arg[0] eq "add" && $currentDeal{'you_finalize'}) {
			print	"�o�Ϳ��~ 'deal add' (Add Item to Deal)\n"
				, "�L�k��J���󪫫~������ - �A�w�g�T�{���.\n";
		} elsif ($arg[0] eq "add" && $arg[1] =~ /^\d+$/ && !%{$chars[$config{'char'}]{'inventory'}[$arg[1]]}) {
			print	"�o�Ϳ��~ 'deal add' (Add Item to Deal)\n"
				, "��������~ $arg[1] ���s�b.\n";
		} elsif ($arg[0] eq "add" && $arg[2] ne "" && $arg[2] !~ /^\d+$/) {
			print	"�o�Ϳ��~ 'deal add' (Add Item to Deal)\n"
				, "�ƶq���ݬ��Ʀr, �B�����j��s.\n";
		} elsif ($arg[0] eq "add" && $arg[1] =~ /^\d+$/) {
			if ($currentDeal{'totalItems'} < 10) {
				if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'}) {
					$arg[2] = $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'};
				}
				$currentDeal{'lastItemAmount'} = $arg[2];
				sendDealAddItem(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg[1]]{'index'}, $arg[2]);
			} else {
				print "�o�Ϳ��~ 'deal add' (Add Item to Deal)\n"
					, "�̦h�u��洫10�˪��~.\n";
			}

		} elsif ($arg[0] eq "add" && $arg[1] eq "z" && $arg[2] !~ /^\d+$/) {
			print	"�o�Ϳ��~ 'deal add z' (Add Zeny to Deal)\n"
				, "�ƶq���ݬ��Ʀr, �B�����j��s.\n";
		} elsif ($arg[0] eq "add" && $arg[1] eq "z") {
			if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'zenny'}) {
				$arg[2] = $chars[$config{'char'}]{'zenny'};
			}
			$currentDeal{'you_zenny'} = $arg[2];
			print "�A��F ".toZeny($arg[2])." z ������\n";
			parseInput("dl");

		} else {
			print	"�y�k���~ 'deal' (Deal a player)\n"
				, "�ϥΤ�k: deal [<���a�s�� | no>]\n";
		}

	} elsif ($switch eq "dl") {
		if (!%currentDeal) {
			print "�o�Ϳ��~ 'dl' (Deal List)\n"
				, "�S����������i��� - �A�S���b���.\n";

		} else {
			print "---------------------------------- ������� ----------------------------------\n";
			$other_string = $currentDeal{'name'};
			$you_string = "�A";
			if ($currentDeal{'other_finalize'}) {
				$other_string .= " - �w�T�{";
			} else {
				$other_string .= " - ���T�{";
			}
			if ($currentDeal{'you_finalize'}) {
				$you_string .= " - �w�T�{";
			} else {
				$you_string .= " - ���T�{";
			}

			$~ = "PREDLIST";
			format PREDLIST =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<          @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$you_string,                                $other_string

.
			write;
			$~ = "DLIST";
			undef @currentDealYou;
			undef @currentDealOther;
			foreach (keys %{$currentDeal{'you'}}) {
				push @currentDealYou, $_;
			}
			foreach (keys %{$currentDeal{'other'}}) {
				push @currentDealOther, $_;
			}
			$lastindex = @currentDealOther;
			$lastindex = @currentDealYou if (@currentDealYou > $lastindex);
			for ($i = 0; $i < $lastindex; $i++) {
				if ($i < @currentDealYou) {
					$display =  "$currentDeal{'you'}{$currentDealYou[$i]}{'name'}";
					$display .= " x $currentDeal{'you'}{$currentDealYou[$i]}{'amount'}";
				} else {
					$display = "";
				}
				if ($i < @currentDealOther) {
					$display2 =  "$currentDeal{'other'}{$currentDealOther[$i]}{'name'}";
					$display2 .= " x $currentDeal{'other'}{$currentDealOther[$i]}{'amount'}";
				} else {
					$display2 = "";
				}
				format DLIST =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<          @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$display,                                   $display2
.
				write;
			}
			$you_string = ($currentDeal{'you_zenny'} ne "") ? toZeny($currentDeal{'you_zenny'}) : 0;
			$other_string = ($currentDeal{'other_zenny'} ne "") ? toZeny($currentDeal{'other_zenny'}) : 0;
			$~ = "DLISTSUF";
			format DLISTSUF =

�v��X��:      @>>>>>>>>>>>> Zeny           ���X��:      @>>>>>>>>>>>> Zeny
               $you_string,                                $other_string
.
			write;
			print "------------------------------------------------------------------------------\n";
			if (!$currentDeal{'you_finalize'}) {
				print "�п�J 'deal add <���~�s�� | z=Zeny> [<�ƶq>]' �s�W���~�Ϊ���������\n";
				print "�Y���A�s�W���~, �п�J 'deal' �T�{���, �ο�J 'deal no' �������\n";
			} elsif (!$currentDeal{'other_finalize'}) {
				print "���� $currentDeal{'name'} �T�{�������, �ο�J 'deal no' �������\n";
			} elsif (!$currentDeal{'final'}) {
				print "�п�J 'deal' �T�{�}�l�洫, �ο�J 'deal no' �������\n";
			} else {
				print "���� $currentDeal{'name'} �T�{�}�l�洫, �ο�J 'deal no' �������\n";
			}
			print "\n";
		}


	} elsif ($switch eq "drop") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			print	"�y�k���~ 'drop' (Drop Inventory Item)\n"
				, "�ϥΤ�k: drop <���~�s��> [<�ƶq>]\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"�o�Ϳ��~ 'drop' (Drop Inventory Item)\n"
				, "����󪫫~ $arg1 ���s�b.\n";
		} elsif (isEquipment($chars[$config{'char'}]{'inventory'}[$arg1]{'type'})) {
			print	"�o�Ϳ��~ 'drop' (Drop Inventory Item)\n"
				, "�L�k��󪫫~ $arg1.\n";
		} else {
			if (!$arg2 || $arg2 > $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'}) {
				$arg2 = $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'};
			}
			sendDrop(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $arg2);
		}

	} elsif ($switch eq "dump") {
#Karasu Start
		# Dump packages without quiting
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		dumpData($msg);
#		$quit = 1 if ($arg1 ne "now");
		quit(1, 1) if ($arg1 ne "now");
#Karasu End

	} elsif ($switch eq "e") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "" || $arg1 < 0) {
			print	"�y�k���~ 'e' (Emotion)\n"
				, "�ϥΤ�k: e <���s��>\n";
		$~ = "EMOTIONLIST";
		print "-------------- �B�~���� --------------\n";
		print "#                  #                  #\n";
		for ($i = 0; $i <= 16; $i++) {
			next if ($emotions_lut{$i} eq "");
			format EMOTIONLIST =
@<< @<<<<<<<<<<<<< @<< @<<<<<<<<<<<<< @<< @<<<<<<<<<<<<<
$i, $emotions_lut{$i}, $i+17, $emotions_lut{$i+17},$i+34, $emotions_lut{$i+34}
.
			write;
		}
		print "--------------------------------------\n";
		} else {
			sendEmotion(\$remote_socket, $arg1);
		}

	} elsif ($switch eq "eq") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\w+)/;
		if ($arg1 eq "") {
			# Seperate armed-equipment with inventory
			undef %equipment;
			undef $arrow_index_string;
			undef $arrow_string;
			for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
				# Equip arrow related
				next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} eq "");
				if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} & 256) {
					$equipment{'headUp'}{'index'} = $i;
					$equipment{'headUp'}{'name'} = $chars[$config{'char'}]{'inventory'}[$i]{'name'};
				}
				if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} & 512) {
					$equipment{'headMiddle'}{'index'} = $i;
					$equipment{'headMiddle'}{'name'} = $chars[$config{'char'}]{'inventory'}[$i]{'name'};
				}
				if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} & 1) {
					$equipment{'headLow'}{'index'} = $i;
					$equipment{'headLow'}{'name'} = $chars[$config{'char'}]{'inventory'}[$i]{'name'};
				}
				if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} == 16) {
					$equipment{'body'}{'index'} = $i;
					$equipment{'body'}{'name'} = $chars[$config{'char'}]{'inventory'}[$i]{'name'};
				}
				if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} & 2) {
					$equipment{'handRight'}{'index'} = $i;
					$equipment{'handRight'}{'name'} = $chars[$config{'char'}]{'inventory'}[$i]{'name'};
					if ($chars[$config{'char'}]{'inventory'}[$i]{'maker_charID'}) {
						$equipment{'handRight'}{'name'} .= " -- �� $charID_lut{$chars[$config{'char'}]{'inventory'}[$i]{'maker_charID'}} �s�@";
					}
				}
				if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} & 32) {
					$equipment{'handLeft'}{'index'} = $i;
					$equipment{'handLeft'}{'name'} = $chars[$config{'char'}]{'inventory'}[$i]{'name'};
					if ($chars[$config{'char'}]{'inventory'}[$i]{'maker_charID'}) {
						$equipment{'handLeft'}{'name'} .= " -- �� $charID_lut{$chars[$config{'char'}]{'inventory'}[$i]{'maker_charID'}} �s�@";
					}
				}
				if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} == 4) {
					$equipment{'about'}{'index'} = $i;
					$equipment{'about'}{'name'} = $chars[$config{'char'}]{'inventory'}[$i]{'name'};
				}
				if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} == 64) {
					$equipment{'feet'}{'index'} = $i;
					$equipment{'feet'}{'name'} = $chars[$config{'char'}]{'inventory'}[$i]{'name'};
				}
				if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} == 8) {
					$equipment{'accessoryRight'}{'index'} = $i;
					$equipment{'accessoryRight'}{'name'} = $chars[$config{'char'}]{'inventory'}[$i]{'name'};
				}
				if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} == 128) {
					$equipment{'accessoryLeft'}{'index'} = $i;
					$equipment{'accessoryLeft'}{'name'} = $chars[$config{'char'}]{'inventory'}[$i]{'name'};
				}
				# Equip arrow related
				if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} eq "0") {
					$arrow_index_string = $i;
					if ($i < 10) {
						$arrow_index_string = $i."  ";
					} elsif ($i < 100) {
						$arrow_index_string = $i." ";
					}
					$arrow_string = "�b���˵�  $arrow_index_string $chars[$config{'char'}]{'inventory'}[$i]{'name'} x $chars[$config{'char'}]{'inventory'}[$i]{'amount'}";
				}
			}
			$~ = "EQUIPMENTLIST";
			print "------------------- �˳��� -------------------\n";
			print "�˳Ʀ�m  #   �W��                            \n";
			format EQUIPMENTLIST =
�Y��(�W)  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'headUp'}{'index'}, $equipment{'headUp'}{'name'}
�Y��(��)  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'headMiddle'}{'index'}, $equipment{'headMiddle'}{'name'}
�Y��(�U)  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'headLow'}{'index'}, $equipment{'headLow'}{'name'}
���W���  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'body'}{'index'}, $equipment{'body'}{'name'}
�k�⮳��  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'handRight'}{'index'}, $equipment{'handRight'}{'name'}
���⮳��  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'handLeft'}{'index'}, $equipment{'handLeft'}{'name'}
�ӤW�ܵ�  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'about'}{'index'}, $equipment{'about'}{'name'}
�}�W���  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'feet'}{'index'}, $equipment{'feet'}{'name'}
�t��(�k)  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'accessoryRight'}{'index'}, $equipment{'accessoryRight'}{'name'}
�t��(��)  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'accessoryLeft'}{'index'}, $equipment{'accessoryLeft'}{'name'}
.
			write;
			print "----------------------------------------------\n";

			if ($arrow_index_string ne "") {
				print "$arrow_string\n";
				print "----------------------------------------------\n";
			}

		} elsif ($arg1 =~ /^\d+$/ && !%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"�o�Ϳ��~ 'eq' (Equip Inventory Item)\n"
				, "���˳ƪ��~ $arg1 ���s�b.\n";
		# Equip arrow related
		} elsif ($arg1 =~ /^\d+$/ && !$chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'} && $chars[$config{'char'}]{'inventory'}[$arg1]{'type'} != 10) {
			print	"�o�Ϳ��~ 'eq' (Equip Inventory Item)\n"
				, "���~ $arg1 �L�k�˳�.\n";

		} elsif ($arg1 =~ /^\d+$/) {
			if ($chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'} == 2 && $arg2 eq "left") {
				sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, 32);
			} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'} == 136 && $arg2 eq "left") {
				sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, 128);
			} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'} == 136) {
				sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, 8);
			} else {
				sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'});
			}
		} else {
			print	"�y�k���~ 'eq' (Equip Inventory Item)\n"
				, "�ϥΤ�k: eq [<���~�s��>] [<left=�����m>]\n";
		}

	} elsif ($switch eq "follow") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			print	"�y�k���~ 'follow' (Follow Player)\n"
				, "�ϥΤ�k: follow <���a�s��>\n";
		} elsif ($arg1 eq "stop") {
			aiRemove("follow");
#			configModify("follow", 0);
			scModify("config", "follow", 0, 2);
		} elsif ($playersID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'follow' (Follow Player)\n"
				, "�����H���a $arg1 ���s�b.\n";
		} else {
			ai_follow($players{$playersID[$arg1]}{'name'});
#			configModify("follow", 1);
#			configModify("followTarget", $players{$playersID[$arg1]}{'name'});

			scModify("config", "follow", 1, 2);
			scModify("config", "followTarget", $players{$playersID[$arg1]}{'name'}, 2);
		}

	} elsif ($switch eq "i") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if (switchInput($params[1], "", "eq", "u", "nu", "card", "arrow")) {

			getItemList(\@{$chars[$config{'char'}]{'inventory'}}, $params[1], "Inventory");

		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/ && !%{$chars[$config{'char'}]{'inventory'}[$arg2]}) {
			print	"�o�Ϳ��~ 'i' (Iventory Item Description)\n"
				, "���˵����~ $arg2 ���s�b.\n";
		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/) {

			printDesc(0, $chars[$config{'char'}]{'inventory'}[$arg2]{'nameID'}, fixingName(\%{$chars[$config{'char'}]{'inventory'}[$arg2]}));

		} else {
			print	"�y�k���~ 'i' (Iventory List)\n"
				, "�ϥΤ�k: i [<u | eq | nu | desc>] [<���~�s��>]\n";
		}

	} elsif ($switch eq "identify") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			$~ = "IDENTIFY";
			print "--------------- �iŲ�w���~�M�� ---------------\n";
			print "#   �W��                                      \n";
			for ($i = 0; $i < @identifyID; $i++) {
				next if ($identifyID[$i] eq "");
				format IDENTIFY =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $chars[$config{'char'}]{'inventory'}[$identifyID[$i]]{'name'}
.
				write;
			}
			print "----------------------------------------------\n";
			print "�п�J 'identify <�iŲ�w���~�s��>' ���\n";

		} elsif ($arg1 =~ /^\d+$/ && $identifyID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'identify' (Identify Item)\n"
				, "��Ų�w���~ $arg1 ���s�b.\n";

		} elsif ($arg1 =~ /^\d+$/) {
			sendIdentify(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$identifyID[$arg1]]{'index'});
		} else {
			print	"�y�k���~ 'identify' (Identify Item)\n"
				, "�ϥΤ�k: identify [<�iŲ�w���~�s��>]\n";
		}


	} elsif ($switch eq "ignore") {
		($arg1, $arg2) = $input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
		if ($arg1 eq "" || $arg2 eq "" || ($arg1 ne "0" && $arg1 ne "1")) {
			print	"�y�k���~ 'ignore' (Ignore Player/Everyone)\n"
				, "�ϥΤ�k: ignore <0=�}�ұK�y | 1=�����K�y> <���a�W�� | all>\n";
		} else {
			if ($arg2 eq "all") {
				sendIgnoreAll(\$remote_socket, !$arg1);
			} else {
				sendIgnore(\$remote_socket, $arg2, !$arg1);
			}
		}

	} elsif ($switch eq "il") {
		$~ = "ILIST";
		print "------------------ ���~�C�� ------------------\n";
		print "#   �W��                                      \n";
		for ($i = 0; $i < @itemsID; $i++) {
			next if ($itemsID[$i] eq "");
			$display = $items{$itemsID[$i]}{'name'};
			$display .= " x $items{$itemsID[$i]}{'amount'}";
			format ILIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $display
.
			write;
		}
		print "----------------------------------------------\n";

#	} elsif ($switch eq "im") {
#		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
#		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
#		if ($arg1 eq "" || $arg2 eq "") {
#			print	"�y�k���~ 'im' (Use Item on Monster)\n"
#				, "�ϥΤ�k: im <���~�s��> <�Ǫ��s��>\n";
#		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
#			print	"�o�Ϳ��~ 'im' (Use Item on Monster)\n"
#				, "���ϥΪ��~ $arg1 ���s�b.\n";
#		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
#			print	"�o�Ϳ��~ 'im' (Use Item on Monster)\n"
#				, "���ϥΪ��~ $arg1 ���O�i�ϥΪ�.\n";
#		} elsif ($monstersID[$arg2] eq "") {
#			print	"�o�Ϳ��~ 'im' (Use Item on Monster)\n"
#				, "�Ǫ� $arg2 ���s�b.\n";
#		} else {
#			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $monstersID[$arg2]);
#		}
#
#	} elsif ($switch eq "ip") {
#		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
#		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
#		if ($arg1 eq "" || $arg2 eq "") {
#			print	"�y�k���~ 'ip' (Use Item on Player)\n"
#				, "�ϥΤ�k: ip <���~�s��> <���a�s��>\n";
#		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
#			print	"�o�Ϳ��~ 'ip' (Use Item on Player)\n"
#				, "���ϥΪ��~ $arg1 ���s�b.\n";
#		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
#			print	"�o�Ϳ��~ 'ip' (Use Item on Player)\n"
#				, "���ϥΪ��~ $arg1 ���O�i�ϥΪ�.\n";
#		} elsif ($playersID[$arg2] eq "") {
#			print	"�o�Ϳ��~ 'ip' (Use Item on Player)\n"
#				, "���a $arg2 ���s�b.\n";
#		} else {
#			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $playersID[$arg2]);
#		}
#
#	} elsif ($switch eq "is") {
#		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
#		if ($arg1 eq "") {
#			print	"�y�k���~ 'is' (Use Item on Self)\n"
#				, "�ϥΤ�k: is <���~�s��>\n";
#		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
#			print	"�o�Ϳ��~ 'is' (Use Item on Self)\n"
#				, "���ϥΪ��~ $arg1 ���s�b.\n";
#		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
#			print	"�o�Ϳ��~ 'is' (Use Item on Self)\n"
#				, "���ϥΪ��~ $arg1 ���O�i�ϥΪ�.\n";
#		} else {
#			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $accountID);
#		}

	} elsif (switchInput($switch, "im", "ip", "is")) {

		if ($switch eq "im") {
			$tmpVal{'title'} = "Monster";
			$tmpVal{'targetID'} = $monstersID[$params[2]];

		} elsif ($switch eq "ip") {
			$tmpVal{'title'} = "Player";
			$tmpVal{'targetID'} = $playersID[$params[2]];
		} else {
			$tmpVal{'title'} = "Self";
			$tmpVal{'targetID'} = $accountID;
		}

		if ($params[1] eq "") {
			$tmpVal{'text'} = "<���~�s��>";
			$tmpVal{'text'} .= " <$tmpVal{'title'} ID>" if ($switch ne "is");
			$tmpVal{'type'} = 1;
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$params[1]]}) {
			$tmpVal{'text'} = "���ϥΪ��~ $params[1] ���s�b";
		} elsif ($chars[$config{'char'}]{'inventory'}[$params[1]]{'type'} > 2) {
			$tmpVal{'text'} = "���ϥΪ��~ $params[1] ���O�i�ϥΪ�";
		} elsif ($tmpVal{'targetID'} eq "") {
			$tmpVal{'text'} = "$tmpVal{'title'} $params[2] ���s�b";
		} else {
			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[1]]{'index'}, $accountID);
		}

		printErr($switch, "Use Item on $tmpVal{'title'}", $tmpVal{'text'}, $tmpVal{'type'});

	} elsif ($switch eq "join") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ ([\s\S]*)$/;
		if ($arg1 eq "") {
			print	"�y�k���~ 'join' (Join Chat Room)\n"
				, "�ϥΤ�k: join <��ѫǽs��> [<�K�X>]\n";
		} elsif ($currentChatRoom ne "") {
			print	"�o�Ϳ��~ 'join' (Join Chat Room)\n"
				, "�A�w�g�b��ѫǤ��F.\n";
		} elsif ($shop{'opened'}) {
			print	"�o�Ϳ��~ 'join' (Join Chat Room)\n"
				, "�\\�u���ɭԥ����M��, ���M�i��|�Q����o�Ͼ�.\n";
		} elsif ($chatRoomsID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'join' (Join Chat Room)\n"
				, "���[�J��ѫ� $arg1 ���s�b.\n";
		} else {
			sendChatRoomJoin(\$remote_socket, $chatRoomsID[$arg1], $arg2);
		}

	} elsif ($switch eq "judge") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"�y�k���~ 'judge' (Give an alignment point to Player)\n"
				, "�ϥΤ�k: judge <���a�s��> <0=�n | 1=�a>\n";
		} elsif ($playersID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'judge' (Give an alignment point to Player)\n"
				, "����Ų���a $arg1 ���s�b.\n";
		} else {
			$arg2 = ($arg2 >= 1);
			sendAlignment(\$remote_socket, $playersID[$arg1], $arg2);
		}

	} elsif ($switch eq "kick") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($currentChatRoom eq "") {
			print	"�o�Ϳ��~ 'kick' (Kick from Chat)\n"
				, "�A���b��ѫǸ�.\n";
		} elsif ($arg1 eq "") {
			print	"�y�k���~ 'kick' (Kick from Chat)\n"
				, "�ϥΤ�k: kick <���a�s��>\n";
		} elsif ($currentChatRoomUsers[$arg1] eq "") {
			print	"�o�Ϳ��~ 'kick' (Kick from Chat)\n"
				, "����X���a $arg1 ���s�b.\n";
		} else {
			sendChatRoomKick(\$remote_socket, $currentChatRoomUsers[$arg1]);
		}

	} elsif ($switch eq "leave") {
		if ($currentChatRoom eq "") {
			print	"�o�Ϳ��~ 'leave' (Leave Chat Room)\n"
				, "�A���b��ѫǸ�.\n";
		} else {
			sendChatRoomLeave(\$remote_socket);
		}

	} elsif ($switch eq "look") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;

		my $z = getSex($chars[$config{'char'}]{'sex'}, 1);

		if (!isNum($params[1])) {
			printErr($switch, "Look a Direction", "<����> [<�Y��>]", 1);

			print "-------------- �B�~���� --------------\n";
			print "����: ��  ��  ��        �Y��: 0=���e��\n";
			print "        ������                        \n";
			print "      ����$z����              1=�k�e��\n";
			print "        ������                        \n";
			print "      ��  ��  ��              2=���e��\n";
			print "--------------------------------------\n";
		} else {
			look($params[1], $params[2]);
		}

	} elsif ($switch eq "memo") {

		printC("[Memo] Location ".getMapName($field{'name'}, 1)." : $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'} \n", "WHITE");
		sendMemo(\$remote_socket);

	} elsif ($switch eq "ml") {
		$~ = "MLIST";
		$mycoords = getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
		print "---------------------------------- �Ǫ��C�� ---------------------$mycoords----\n";
		print "#   Lv �W��                          ���a�����ˮ`  ���a����ˮ`   �y   �� �Z��\n";
		for ($i = 0; $i < @monstersID; $i++) {
			next if ($monstersID[$i] eq "");
			$mlcoords = getFormattedCoords($monsters{$monstersID[$i]}{'pos_to'}{'x'}, $monsters{$monstersID[$i]}{'pos_to'}{'y'});
			$dMDist = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$monstersID[$i]}{'pos_to'}}));
			$dmgTo = ($monsters{$monstersID[$i]}{'dmgTo'} ne "")
				? $monsters{$monstersID[$i]}{'dmgTo'}
				: 0;
			$dmgFrom = ($monsters{$monstersID[$i]}{'dmgFrom'} ne "")
				? $monsters{$monstersID[$i]}{'dmgFrom'}
				: 0;
			format MLIST =
@<<@>> @<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>>>>>>>>>>   @>>>>>>>>>>   @<<<<<<<< @>>
$i, $monsters{$monstersID[$i]}{'lv'}, $monsters{$monstersID[$i]}{'name'}, $dmgTo, $dmgFrom, $mlcoords, $dMDist
.
			write;
		}
		print "------------------------------------------------------------------------------\n";

	} elsif ($switch eq "move") {
		($arg1, $arg2, $arg3) = $input =~ /^[\s\S]*? (\d+) (\d+)(.*?)$/;

		undef $ai_v{'temp'}{'map'};
		if ($arg1 eq "") {
			($ai_v{'temp'}{'map'}) = $input =~ /^[\s\S]*? (.*?)$/;
			if (substr($ai_v{'temp'}{'map'}, 0, 4) eq "ptl ") {
				($arg2) = $ai_v{'temp'}{'map'} =~ /^ptl (\d+)$/;
				$ai_v{'temp'}{'map'} = "ptl";
			}
		} else {
			$ai_v{'temp'}{'map'} = $arg3;
		}
		$ai_v{'temp'}{'map'} =~ s/\s//g;

		if (($arg1 eq "" || $arg2 eq "") && !$ai_v{'temp'}{'map'}) {
			print	"�y�k���~ 'move' (Move Player)\n"
				, "�ϥΤ�k: move <x�y��> <y�y��> &| <�a�ϦW��>\n";
		} elsif ($ai_v{'temp'}{'map'} eq "stop") {
			aiRemove("move");
			aiRemove("route");
			aiRemove("route_getRoute");
			aiRemove("route_getMapRoute");
			print "����Ҧ�����\n";

		} elsif ($ai_v{'temp'}{'map'} eq "ptl" && $arg2 eq "") {
			print	"�y�k���~ 'move ptl' (Move Player to Portal)\n"
				, "�ϥΤ�k: move ptl <���I�s��>\n";
		} elsif ($ai_v{'temp'}{'map'} eq "ptl" && $portalsID[$arg2] eq "") {
			print	"�y�k���~ 'move ptl' (Move Player to Portal)\n"
				, "���i�J�ǰe�I $arg2 ���s�b.\n";
		} elsif ($ai_v{'temp'}{'map'} eq "ptl") {
			print "�p����|�e�����w�ǰe�I ($arg2) - $portals{$portalsID[$arg2]}{'name'} ".getFormattedCoords($portals{$portalsID[$arg2]}{'pos'}{'x'}, $portals{$portalsID[$arg2]}{'pos'}{'y'})."\n";
			ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $portals{$portalsID[$arg2]}{'pos'}{'x'}, $portals{$portalsID[$arg2]}{'pos'}{'y'}, $field{'name'}, 0, 0, 1);

		} else {
			$ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
			if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
				if ($arg2 ne "") {
					print "�p����|�e�����w�a�I - $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): ".getFormattedCoords($arg1, $arg2)."\n";
					$ai_v{'temp'}{'x'} = $arg1;
					$ai_v{'temp'}{'y'} = $arg2;
				} else {
					print "�p����|�e�����w�a�� - $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n";
					undef $ai_v{'temp'}{'x'};
					undef $ai_v{'temp'}{'y'};
				}
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				print	"�y�k���~ 'move' (Move Player)\n"
					, "���w�a�ϳ]�w���~ - $sc_v{'path'}{'tables'}/maps.txt���䤣�� $ai_v{'temp'}{'map'}.rsw\n";
			}
		}

	} elsif ($switch eq "nl") {
		# Add ID information to the list
		$~ = "NLIST";
		print "------------------ NPC �C�� ------------------\n";
		print "#   ID     �W��                       �y   �� \n";
		for ($i = 0; $i < @npcsID; $i++) {
			next if ($npcsID[$i] eq "");
			$nlcoords = getFormattedCoords($npcs{$npcsID[$i]}{'pos'}{'x'}, $npcs{$npcsID[$i]}{'pos'}{'y'});
			format NLIST =
@<< @<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<@<<<<<<<<
$i, $npcs{$npcsID[$i]}{'nameID'}, $npcs{$npcsID[$i]}{'name'}, $nlcoords
.
			write;
		}
		print "----------------------------------------------\n";

	} elsif ($switch eq "party") {
		($arg1) = $input =~ /^[\s\S]*? (\w*)/;
		($arg2) = $input =~ /^[\s\S]*? [\s\S]*? (\d+)\b/;
		if ($arg1 eq "" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"�o�Ϳ��~ 'party' (Party Functions)\n"
				, "�L�k�d�߶����T - �A�S������.\n";
		} elsif ($arg1 eq "") {
			$~ = "PARTYUSERS";
			$share_string = ($chars[$config{'char'}]{'party'}{'share'}) ? "�������t" : "�U�ۨ��o";
			print "---------------------------------- �����T ----------------------------------\n";
			print "����W��: $chars[$config{'char'}]{'party'}{'name'}($share_string)\n";
			print "#   ����  �u�W �W��                    �Ҧb�a��     �y   ��                   \n";

			my ($i, $admin_string, $online_string, $name_string, $map_string, $coord_string, $hp_string);

			for ($i = 0; $i < @partyUsersID; $i++) {
				next if ($partyUsersID[$i] eq "");
				$coord_string = "";
				$hp_string = "";
				$name_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'name'};
				$admin_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'admin'}) ? " �� " : "";

				if ($partyUsersID[$i] eq $accountID) {
					$online_string = " �� ";
					($map_string) = getMapID($map_name);
					$coord_string = getFormattedCoords($chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'});
					$hp_string = sprintf("%5d", $chars[$config{'char'}]{'hp'})."/".sprintf("%-5d", $chars[$config{'char'}]{'hp_max'})
							."(".sprintf("%3d", int(percent_hp(\%{$chars[$config{'char'}]})))
							."%)";
				} else {
					$online_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'}) ? " �� " : "";
					$map_string = getMapID($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'map'});
					$coord_string = getFormattedCoords($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'}, $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'y'})
						if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'pos'}{'x'} ne ""
							&& $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'});
					$hp_string = sprintf("%5d", $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp'})."/".sprintf("%-5d", $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'})
							."(".sprintf("%3d", int(percent_hp(\%{$chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}})))
							."%)" if ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'hp_max'} && $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'});
				}
				format PARTYUSERS =
@<< @<<<  @<<< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<< @<<<<<<<< @<<<<<<<<<<<<<<<<
$i, $admin_string, $online_string, $name_string, $map_string, $coord_string, $hp_string
.
				write;
			}
			print "------------------------------------------------------------------------------\n";

		} elsif ($arg1 eq "create") {
			($arg2) = $input =~ /^[\s\S]*? [\s\S]*? \"([\s\S]*?)\"/;

			if (%{$chars[$config{'char'}]{'party'}}) {

				FunctionError('party create', 'Organize Party', '�A�w�g�b����̭�');

			} elsif ($params[2] eq "" && $config{'partyAutoCreate'}) {

				sendPartyOrganize(\$remote_socket, vocalString(14));
				# Party created by self
				$createPartyBySelf = 1;

			} elsif ($params[2] eq "") {
#				print	"�y�k���~ 'party create' (Organize Party)\n"
#				,qq~�ϥΤ�k: party create "<����W��>"\n~;

				printErr('party create', 'Organize Party', '"<����W��>"', 1);
			} else {
				sendPartyOrganize(\$remote_socket, $params[2]);
				# Party created by self
				$createPartyBySelf = 1;
			}

		} elsif ($arg1 eq "join" && $arg2 ne "1" && $arg2 ne "0") {
			print	"�y�k���~ 'party join' (Accept/Deny Party Join Request)\n"
				, "�ϥΤ�k: party join <0=�ڵ� | 1=����>\n";
		} elsif ($arg1 eq "join" && $incomingParty{'ID'} eq "") {
			print	"�o�Ϳ��~ 'party join' (Join/Request to Join Party)\n"
				, "�L�k�����Ωڵ������ܽ� - �S���J���ܽ�.\n";
		} elsif ($arg1 eq "join") {
			sendPartyJoin(\$remote_socket, $incomingParty{'ID'}, $arg2);
			undef %incomingParty;

		} elsif ($arg1 eq "request" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"�o�Ϳ��~ 'party request' (Request to Join Party)\n"
				, "�L�k�ܽХ[�J - �A�S������.\n";
		} elsif ($arg1 eq "request" && $playersID[$arg2] eq "") {
			print	"�o�Ϳ��~ 'party request' (Request to Join Party)\n"
				, "�L�k�ܽХ[�J - ���ܽЪ��a $arg2 ���s�b.\n";
		} elsif ($arg1 eq "request") {
			sendPartyJoinRequest(\$remote_socket, $playersID[$arg2]);

		} elsif ($arg1 eq "leave" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"�o�Ϳ��~ 'party leave' (Leave Party)\n"
				, "�L�k�������� - �A�S������.\n";
		} elsif ($arg1 eq "leave") {
			sendPartyLeave(\$remote_socket);


		} elsif ($arg1 eq "share" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"�o�Ϳ��~ 'party share' (Set Party Share EXP)\n"
				, "�L�k�]�w�g��Ȥ��t - �A�S������.\n";
		} elsif ($arg1 eq "share" && !$chars[$config{'char'}]{'party'}{'users'}{$accountID}{'admin'}) {
			print	"�o�Ϳ��~ 'party share' (Set Party Share EXP)\n"
				, "�L�k�]�w�g��Ȥ��t - �A���O����.\n";
		} elsif ($arg1 eq "share" && $arg2 ne "1" && $arg2 ne "0") {
			print	"�y�k���~ 'party share' (Set Party Share EXP)\n"
				, "�ϥΤ�k: party share <0=�U�ۨ��o | 1=�������t>\n";
		} elsif ($arg1 eq "share") {
			sendPartyShareEXP(\$remote_socket, $arg2);


#		} elsif ($arg1 eq "kick" && !%{$chars[$config{'char'}]{'party'}}) {
#			print	"�o�Ϳ��~ 'party kick' (Kick Party Member)\n"
#				, "�L�k��X���a - �A�S������.\n";
#		} elsif ($arg1 eq "kick" && $arg2 eq "") {
#			print	"�y�k���~ 'party kick' (Kick Party Member)\n"
#				, "�ϥΤ�k: party kick <������s��>\n";
#		} elsif ($arg1 eq "kick" && $partyUsersID[$arg2] eq "") {
#			print	"�o�Ϳ��~ 'party kick' (Kick Party Member)\n"
#				, "�L�k��X���a - ����X���a $arg2 ���s�b.\n";
#		} elsif ($arg1 eq "kick") {
#			sendPartyKick(\$remote_socket, $partyUsersID[$arg2]
#					, $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$arg2]}{'name'});
#
#		}
		} elsif ($params[1] eq "kick") {
			@{$tmpVal{'err'}} = ('party kick', 'Kick Party Member');

			if (!%{$chars[$config{'char'}]{'party'}}) {
				$tmpVal{'err'}[2] = "�L�k��X���a - �A�S������";
			} elsif ($params[2] eq "") {
				$tmpVal{'err'}[2] = "<������s��>";
				$tmpVal{'err'}[3] = 1;
			} elsif ($partyUsersID[$params[2]] eq "") {
				$tmpVal{'err'}[2] = "�L�k��X���a - ����X���a $arg2 ���s�b";
			} elsif ($partyUsersID[$params[2]] eq $accountID) {
				$tmpVal{'err'}[2] = "�A�O����";
			} else {
				sendPartyKick(
					\$remote_socket
					, $partyUsersID[$params[2]]
					, $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$params[2]]}{'name'}
				);
				$tmpVal{'err'}[3] = -1;
			}

			printErr(@{$tmpVal{'err'}});
		}

	} elsif ($switch eq "petl") {
		$~ = "PETLIST";
		print "------------------ �d���C�� ------------------\n";
		print "#   ����               �W��                   \n";
		for ($i = 0; $i < @petsID; $i++) {
			next if ($petsID[$i] eq "");
			format PETLIST =
@<< @<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<<
$i, $pets{$petsID[$i]}{'name'}, $pets{$petsID[$i]}{'name_given'}
.
			write;
		}
		print "----------------------------------------------\n";

	} elsif ($switch eq "pm") {
		($arg1, $arg2) = $input =~ /^[\s\S]*? "([\s\S]*?)" ([\s\S]*)/;
		$type = 0;
		if (!$arg1) {
			($arg1, $arg2) =$input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
			$type = 1;
		}
		if ($arg1 eq "" || $arg2 eq "") {
			print	"�y�k���~ 'pm' (Private Message)\n"
				,qq~�ϥΤ�k: pm ("<���a�W��>" | �K�y�C��s��) <�T��>\n~;
		} elsif ($type) {
			if ($arg1 - 1 >= @privMsgUsers) {
				print	"�o�Ϳ��~ 'pm' (Private Message)\n"
				, "���a $arg1 ���b�A���K�y�C��.\n";
			} elsif (@privMsgUsers && ($arg1 - 1) > 0) {
#				$lastpm{'msg'} = $arg2;
#				$lastpm{'user'} = $privMsgUsers[$arg1 - 1];

				$sc_v{'pm'}{'lastTo'} = $privMsgUsers[$arg1 - 1];
				$sc_v{'pm'}{'lastMsg'} = $arg2;

				sendMessage(\$remote_socket, "pm", $arg2, $privMsgUsers[$arg1 - 1]);
			}
		} else {
			if ($arg1 =~ /^%(\d*)$/) {
				$arg1 = $1;
			}
#pml bugfix - chobit andy 20030127
			if (binFind(\@privMsgUsers, $arg1) eq "") {
				$privMsgUsers[@privMsgUsers] = $arg1;
			}
#			$lastpm{'msg'} = $arg2;
#			$lastpm{'user'} = $arg1;

			$sc_v{'pm'}{'lastTo'} = $arg1;
			$sc_v{'pm'}{'lastMsg'} = $arg2;

			sendMessage(\$remote_socket, "pm", $arg2, $arg1);
		}

	} elsif ($switch eq "pmcl") {
		shift @lastpm;
		print "�w�N�ǰe�K�y�ɭ�����ܤ��ܻy�R��\n";

	} elsif ($switch eq "pml") {
		$~ = "PMLIST";
		print "------------------ �K�y�C�� ------------------\n";
		print "#   �W��                                      \n";
		for ($i = 1; $i <= @privMsgUsers; $i++) {
			format PMLIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $privMsgUsers[$i - 1]
.
			write;
		}
		print "----------------------------------------------\n";


	} elsif ($switch eq "pl") {
		$~ = "PLIST";
		$mycoords = getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
		print "---------------------------------- ���a�C�� ---------------------$mycoords----\n";
		print "#   Lv ¾�~ �ʧO �W��                   ���ݤ��|                  �y   �� �Z��\n";
		for ($i = 0; $i < @playersID; $i++) {
			next if ($playersID[$i] eq "");
			$plcoords = getFormattedCoords($players{$playersID[$i]}{'pos_to'}{'x'}, $players{$playersID[$i]}{'pos_to'}{'y'});
			$dPDist = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$players{$playersID[$i]}{'pos_to'}}));
			$job_string = ($jobs_lut{$players{$playersID[$i]}{'jobID'}}) ? $jobs_lut{$players{$playersID[$i]}{'jobID'}} : $players{$playersID[$i]}{'jobID'};
			$guild_string = ($players{$playersID[$i]}{'guild'}{'name'}) ? "[$players{$playersID[$i]}{'guild'}{'name'}]" : "";
			format PLIST =
@<<@>> @<<< @<<< @<<<<<<<<<<<<<<<<<<<<<<@<<<<<<<<<<<<<<<<<<<<<<<<@<<<<<<<< @>>
$i, $players{$playersID[$i]}{'lv'}, $job_string, $sex_lut{$players{$playersID[$i]}{'sex'}}, $players{$playersID[$i]}{'name'}, $guild_string, $plcoords, $dPDist
.
			write;
		}
		print "------------------------------------------------------------------------------\n";

	} elsif (switchInput($switch, "portals", "ptl", "portal")) {
		# Add ID information to the list
#		$~ = "PORTALLIST";
#		print "----------------- �ǰe�I�C�� -----------------\n";

		my $tmpLine = "@>> @<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>>";

		print	subStrLine($tmpLine, "Portals List")
			.swrite($tmpLine, ["No", "ID", "Name.", "Coords"]);

		for ($i = 0; $i < @portalsID; $i++) {
			next if ($portalsID[$i] eq "");

			$portalscoords = getFormattedCoords($portals{$portalsID[$i]}{'pos'}{'x'}, $portals{$portalsID[$i]}{'pos'}{'y'});
#			format PORTALLIST =
#@<< @<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<@<<<<<<<<
#$i, $portals{$portalsID[$i]}{'nameID'}, $portals{$portalsID[$i]}{'name'}, $portalscoords
#.
#			write;

			print swrite($tmpLine, [$i, $portals{$portalsID[$i]}{'nameID'}, $portals{$portalsID[$i]}{'name'}, $portalscoords]);

		}

		print subStrLine($tmpLine);

	} elsif (switchInput($switch, "quit", "close", "end", "logout")) {

		quit();

	} elsif ($switch eq "reload") {

		parseReload($inputparam);

	} elsif ($switch eq "relog") {
		$sc_v{'input'}{'MinWaitRecon'} = 1;
		relogWait("", 1);

	} elsif ($switch eq "respawn") {
		useTeleport(2);

	} elsif ($switch eq "s") {
		my ($id,$baseEXPKill,$jobEXPKill,$hp_string, $sp_string, $base_string, $job_string, $weight_string, $job_name_string, $zeny_string);
		my ($percent_expB, $percent_expJ);

		$hp_string = sprintf("%5d", $chars[$config{'char'}]{'hp'})."/".sprintf("%-5d", $chars[$config{'char'}]{'hp_max'})."("
				.sprintf("%3d", int(percent_hp(\%{$chars[$config{'char'}]})))
				."%)";
		$sp_string = sprintf("%5d", $chars[$config{'char'}]{'sp'})."/".sprintf("%-5d", $chars[$config{'char'}]{'sp_max'})."("
				.sprintf("%3d", int(percent_sp(\%{$chars[$config{'char'}]})))
				."%)";

		my $t_exp = $chars[$config{'char'}]{'exp'};
		my $t_exp_max = $chars[$config{'char'}]{'exp_max'};

		my $t_exp_job = $chars[$config{'char'}]{'exp_job'};
		my $t_exp_job_max = $chars[$config{'char'}]{'exp_job_max'};

		if (!isLevelMax(0, $chars[$config{'char'}]{'lv'}) && $t_exp_max) {

			$base_string = "$t_exp/$t_exp_max";
			$percent_expB = swrite("(@>>>>%)",[mathPercent($t_exp, $t_exp_max, 0, 0, 0)]);

			$baseEXPKill = "-".mathPercent($t_exp, $t_exp_max, 0, 0, 1);
		}

		if (!isLevelMax(1, $chars[$config{'char'}]{'lv_job'}, $chars[$config{'char'}]{'exp_job_max'}) && $t_exp_job_max) {

			$job_string = "$t_exp_job/$t_exp_job_max";
#			$percent_expJ = swrite("(@>>>>%)",[($t_exp_job/$t_exp_job_max * 100)]);
			$percent_expJ = swrite("(@>>>>%)",[mathPercent($t_exp_job, $t_exp_job_max, 0, 0, 0)]);

			$jobEXPKill = "-".mathPercent($t_exp_job, $t_exp_job_max, 0, 0, 1);
		}

		$weight_string = $chars[$config{'char'}]{'weight'}."/".$chars[$config{'char'}]{'weight_max'}." ("
				.int(percent_weight(\%{$chars[$config{'char'}]}))
				."%)";
		$job_name_string = getName("jobs_lut", $chars[$config{'char'}]{'jobID'})." $sex_lut{$chars[$config{'char'}]{'sex'}}";
		$zeny_string = ($chars[$config{'char'}]{'zenny'}) ? toZeny($chars[$config{'char'}]{'zenny'}) : 0;

		$id = unpack("L1", $accountID);

		my $t_exp_line = "----------------------------------------------";

		print subStrLine($t_exp_line, "Status ( ID: $id )", -1)
		.swrite(
		"@<<<<<<<<<<<<<<<<<<<<<<< HP: @>>>>/@<<<<(@>>%)"
		,[$chars[$config{'char'}]{'name'}, $chars[$config{'char'}]{'hp'}, $chars[$config{'char'}]{'hp_max'}, int(percent_hp(\%{$chars[$config{'char'}]}))]
		,"@<<<<<<<<<<<<<<<<<<<<<<< SP: @>>>>/@<<<<(@>>%)"
		,[$job_name_string, $chars[$config{'char'}]{'sp'}, $chars[$config{'char'}]{'sp_max'}, int(percent_sp(\%{$chars[$config{'char'}]}))]
		,"Base Lv: @> @>>>>>>>>>>>>>>>>>>>>>>>> @>>>>>>> @<<<<<<<<<<<<<<<<<<<<<"
		,[$chars[$config{'char'}]{'lv'},$base_string,$percent_expB,$baseEXPKill]
		,"Job  Lv: @> @>>>>>>>>>>>>>>>>>>>>>>>> @>>>>>>> @<<<<<<<<<<<<<<<<<<<<<"
		,[$chars[$config{'char'}]{'lv_job'},$job_string,$percent_expJ,$jobEXPKill]
		,"Weight: @>>>>>>>>>>>>>>> Zeny: @>>>>>>>>>>>>>>"
		,[$weight_string,toZeny($chars[$config{'char'}]{'zenny'})]);

		print subStrLine($t_exp_line, "Status Param", -1);

		print getStatusParam();

#		# Character status
#		$outlook_string = getOutlookString($chars[$config{'char'}]{'sitting'}, $chars[$config{'char'}]{'look'}{'body'}, $chars[$config{'char'}]{'look'}{'head'});
#		$attack_string = getAttackString($config{'attackAuto'}, $config{'route_randomWalk'});
#		print "[�������A] $attack_string\n";
#		print "[�~    �[] $outlook_string\n";
#		print "[�T    ��] �T�������ٳѤU $chars[$config{'char'}]{'skill_ban'}����\n" if ($chars[$config{'char'}]{'skill_ban'});
#		print "[�� �� ��] �ثe�ƦW $chars[$config{'char'}]{'pvp'}{'rank_num'}\n" if ($chars[$config{'char'}]{'pvp'}{'start'} == 1);
#		print "[�� �y ��] �ثe�֦� $chars[$config{'char'}]{'spirits'}����y\n" if ($chars[$config{'char'}]{'spirits'});
#
#		print "[�S���A��] ".getMsgStrings('0119_A', $chars[$config{'char'}]{'param1'})."\n" if ($chars[$config{'char'}]{'param1'});
#
#		foreach (keys %{$messages_lut{'0119_B'}}) {
#			print "[�S���A��] ".getMsgStrings('0119_B', $_)."\n" if ($_ & $chars[$config{'char'}]{'param2'});
#		}
#		foreach (keys %{$messages_lut{'0119_C'}}) {
#			print "[�S���A��] ".getMsgStrings('0119_C', $_)."\n" if ($_ & $chars[$config{'char'}]{'param3'});
#		}
#		# Status icon
#		foreach (@{$chars[$config{'char'}]{'status'}}) {
#			next if ($_ == 27 || $_ == 28);
#			my $messages = getMsgStrings('0196', $_, 1);
#			$messages .= " -- $chars[$config{'char'}]{'autospell'}" if ($_ == 65);
#			print "[���򪬺A] ${messages}\n";
#		}
		print subStrLine($t_exp_line);

	} elsif ($switch eq "sell") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "" && $talk{'buyOrSell'}) {
			sendGetSellList(\$remote_socket, $talk{'ID'});
		} elsif ($arg1 eq "") {
			print	"�y�k���~ 'sell' (Sell Inventory Item)\n"
				, "�ϥΤ�k: sell <���~�s��> [<�ƶq>]\n";

		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"�o�Ϳ��~ 'sell' (Sell Inventory Item)\n"
				, "���c�檫�~ $arg1 ���s�b.\n";
		} else {
			if (!$arg2 || $arg2 > $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'}) {
				$arg2 = $chars[$config{'char'}]{'inventory'}[$arg1]{'amount'};
			}
			sendSell(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $arg2);
		}

	} elsif ($switch eq "send") {
		($args) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		sendRaw(\$remote_socket, $args);

	} elsif ($switch eq "sit") {
		if ($ai_v2{'attackAuto_old'} eq "" && $config{'attackAuto'} > 0) {
			$ai_v2{'attackAuto_old'} = $config{'attackAuto'};
#			configModify("attackAuto", 1);
			scModify("config", "attackAuto", 1, 1);
		}
		if ($ai_v2{'route_randomWalk_old'} eq "" && $config{'route_randomWalk'} > 0) {
			$ai_v2{'route_randomWalk_old'} = $config{'route_randomWalk'};
#			configModify("route_randomWalk", 0);
			scModify("config", "route_randomWalk", 0, 1);
		}
		aiRemove("move");
		aiRemove("route");
		aiRemove("route_getRoute");
		aiRemove("route_getMapRoute");
		sit();
		$ai_v{'sitAuto_forceStop'} = 0;

	} elsif ($switch eq "sm") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \d+ \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"�y�k���~ 'sm' (Use Skill on Monster)\n"
				, "�ϥΤ�k: sm <�ޯ�s��> <�Ǫ��s��> [<�ޯ൥��>]\n";
		} elsif ($monstersID[$arg2] eq "") {
			print	"�o�Ϳ��~ 'sm' (Use Skill on Monster)\n"
				, "�Ǫ� $arg2 ���s�b.\n";
		} elsif ($skillsID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'sm' (Use Skill on Monster)\n"
				, "���ϥΧޯ� $arg1 ���s�b.\n";
		} else {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
				$arg3 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
			}
			if (!ai_getSkillUseType($skillsID[$arg1])) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $monstersID[$arg2]);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $monsters{$monstersID[$arg2]}{'pos_to'}{'x'}, $monsters{$monstersID[$arg2]}{'pos_to'}{'y'});
			}
		}

	} elsif ($switch eq "skills") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "") {
			$~ = "SKILLS";
			print "------------------- �ޯ��� -------------------\n";
			print "#   �W��                          Lv   Sp     \n";
			for ($i=0; $i < @skillsID; $i++) {
				format SKILLS =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>  @>>
$i, $skills_lut{$skillsID[$i]}, $chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'}, $skillsSP_lut{$skillsID[$i]}{$chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'}}
.
				write;
			}
			print "\n�Ѿl�ޯ��I��: $chars[$config{'char'}]{'points_skill'}\n";
			print "----------------------------------------------\n";


		} elsif ($arg1 eq "add" && $arg2 =~ /^\d+$/ && $skillsID[$arg2] eq "") {
			print	"�o�Ϳ��~ 'skills add' (Add Skill Point)\n"
				, "�ޯ� $arg2 ���s�b.\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /^\d+$/ && $chars[$config{'char'}]{'points_skill'} < 1) {
			print	"�o�Ϳ��~ 'skills add' (Add Skill Point)\n"
				, "�S���������ޯ��I�ƥi�H���@ $skills_lut{$skillsID[$arg2]} ������.\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /^\d+$/) {
			sendAddSkillPoint(\$remote_socket, $chars[$config{'char'}]{'skills'}{$skillsID[$arg2]}{'ID'});


		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/ && $skillsID[$arg2] eq "") {
			print	"�o�Ϳ��~ 'skills desc' (Skill Description)\n"
				, "���˵��ޯ� $arg2 ���s�b.\n";
		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/) {

			printDesc("skills", "$skillsID[$arg2]");
#Karasu Start
		# Print out Skill - ID reference chart
		} elsif ($arg1 eq "log") {
			my @temp;
			my @output;
			foreach (keys %skillsID_lut) {
				my $msg = $skills_rlut{lc($skillsID_lut{$_})}."#".$skillsID_lut{$_}."#".$_."#";
				if (binFind(\@skillsID, $skills_rlut{lc($skillsID_lut{$_})}) ne "") {
					$temp[$_] = $msg;
				}
			}
			foreach (@temp) {
				next if ($_ eq "");
				push(@output, $_."\n");
			}
			open(FILE, "> SkillsList.txt");
			print FILE @output;
			close(FILE);
			print "�N�ޯ�����s���g�J SkillsList.txt\n";
#Karasu End
		} else {
			print	"�y�k���~ 'skills' (Skills Functions)\n"
				, "�ϥΤ�k: skills [<add | desc | log>] [<�ޯ�s��>]\n";
		}


	} elsif ($switch eq "sp") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \d+ \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"�y�k���~ 'sp' (Use Skill on Player)\n"
				, "�ϥΤ�k: sp <�ޯ�s��> <���a�s��> [<�ޯ൥��>]\n";
		} elsif ($playersID[$arg2] eq "") {
			print	"�o�Ϳ��~ 'sp' (Use Skill on Player)\n"
				, "���a $arg2 ���s�b.\n";
		} elsif ($skillsID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'sp' (Use Skill on Player)\n"
				, "���ϥΧޯ� $arg1 ���s�b.\n";
		} else {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
				$arg3 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
			}
			if (!ai_getSkillUseType($skillsID[$arg1])) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $playersID[$arg2]);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg3, 0,0, $players{$playersID[$arg2]}{'pos_to'}{'x'}, $players{$playersID[$arg2]}{'pos_to'}{'y'});
			}
		}

	} elsif ($switch eq "ss") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "") {
			print	"�y�k���~ 'ss' (Use Skill on Self)\n"
				, "�ϥΤ�k: ss <�ޯ�s��> [<�ޯ൥��>]\n";
		} elsif ($skillsID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'ss' (Use Skill on Self)\n"
				, "���ϥΧޯ� $arg1 ���s�b.\n";
		} else {
			if (!$arg2 || $arg2 > $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'}) {
				$arg2 = $chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'lv'};
			}
			if (!ai_getSkillUseType($skillsID[$arg1])) {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg2, 0,0, $accountID);
			} else {
				ai_skillUse($chars[$config{'char'}]{'skills'}{$skillsID[$arg1]}{'ID'}, $arg2, 0,0, $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
			}
		}

	} elsif ($switch eq "st") {
		$~ = "STATS";
		print "------------------ ������� ------------------\n";
		$tilde = "~";
		format STATS =
Str: @<<+@<<#@>  Atk : @>> +@>> Def : @>> +@>>
$chars[$config{'char'}]{'str'}, $chars[$config{'char'}]{'str_bonus'}, $chars[$config{'char'}]{'points_str'}, $chars[$config{'char'}]{'attack'}, $chars[$config{'char'}]{'attack_bonus'}, $chars[$config{'char'}]{'def'}, $chars[$config{'char'}]{'def_bonus'}
Agi: @<<+@<<#@>  Matk: @>> @@>> Mdef: @>> +@>>
$chars[$config{'char'}]{'agi'}, $chars[$config{'char'}]{'agi_bonus'}, $chars[$config{'char'}]{'points_agi'}, $chars[$config{'char'}]{'attack_magic_min'}, $tilde, $chars[$config{'char'}]{'attack_magic_max'}, $chars[$config{'char'}]{'def_magic'}, $chars[$config{'char'}]{'def_magic_bonus'}
Vit: @<<+@<<#@>  Hit :      @>> Flee: @>> +@>>
$chars[$config{'char'}]{'vit'}, $chars[$config{'char'}]{'vit_bonus'}, $chars[$config{'char'}]{'points_vit'}, $chars[$config{'char'}]{'hit'}, $chars[$config{'char'}]{'flee'}, $chars[$config{'char'}]{'flee_bonus'}
int: @<<+@<<#@>  Critical:  @>> Aspd:      @>>
$chars[$config{'char'}]{'int'}, $chars[$config{'char'}]{'int_bonus'}, $chars[$config{'char'}]{'points_int'}, $chars[$config{'char'}]{'critical'}, $chars[$config{'char'}]{'attack_speed'}
Dex: @<<+@<<#@>  Status Points:           @>>>
$chars[$config{'char'}]{'dex'}, $chars[$config{'char'}]{'dex_bonus'}, $chars[$config{'char'}]{'points_dex'}, $chars[$config{'char'}]{'points_free'}
Luk: @<<+@<<#@>  Guild:@>>>>>>>>>>>>>>>>>>>>>>
$chars[$config{'char'}]{'luk'}, $chars[$config{'char'}]{'luk_bonus'}, $chars[$config{'char'}]{'points_luk'}, $chars[$config{'char'}]{'guild'}{'name'}
.
		write;
		print "----------------------------------------------\n";

	} elsif ($switch eq "stand") {
		if ($ai_v2{'attackAuto_old'} ne "") {
#			configModify("attackAuto", $ai_v2{'attackAuto_old'});
			scModify("config", "attackAuto", $ai_v2{'attackAuto_old'}, 1);
			undef $ai_v2{'attackAuto_old'};
		}
		if ($ai_v2{'route_randomWalk_old'} ne "") {
#			configModify("route_randomWalk", $ai_v2{'route_randomWalk_old'});
			scModify("config", "route_randomWalk", $ai_v2{'route_randomWalk_old'}, 1);
			undef $ai_v2{'route_randomWalk_old'};
		}
		stand();
		$ai_v{'sitAuto_forceStop'} = 1;

	} elsif ($switch eq "stat_add") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)$/;
		if ($arg1 ne "str" &&  $arg1 ne "agi" && $arg1 ne "vit" && $arg1 ne "int"
			&& $arg1 ne "dex" && $arg1 ne "luk" && $arg1 ne "no") {
			print	"�y�k���~ 'stat_add' (Add Status Point)\n"
			, "�ϥΤ�k: stat_add <str | agi | vit | int | dex | luk>\n";
		} else {
			if ($arg1 eq "str") {
				$ID = 0x0D;
			} elsif ($arg1 eq "agi") {
				$ID = 0x0E;
			} elsif ($arg1 eq "vit") {
				$ID = 0x0F;
			} elsif ($arg1 eq "int") {
				$ID = 0x10;
			} elsif ($arg1 eq "dex") {
				$ID = 0x11;
			} elsif ($arg1 eq "luk") {
				$ID = 0x12;
			}
			if ($chars[$config{'char'}]{"points_$arg1"} > $chars[$config{'char'}]{'points_free'}) {
				print	"�o�Ϳ��~ 'stat_add' (Add Status Point)\n"
					, "�S���������I�ƥi�H���t�� $arg1.\n";
			} elsif ($chars[$config{'char'}]{$arg1} == 99 && $chars[$config{'char'}]{"points_$arg1"} > 0) {
				print "����: $arg1 �N�|�W�L 99, �T�w(y/n)�H, $timeout{'cancelStatAdd_auto'}{'timeout'}���۰ʨ���...\n";
				timeOutStart('cancelStatAdd_auto');
				my $input;
				while (!checkTimeOut('cancelStatAdd_auto')) {
					usleep($config{'sleepTime'});
					if (input_canRead()) {
						$input = input_readLine();
					}
					last if $input;
				}
				if (switchInput($input, "y")) {
					$chars[$config{'char'}]{$arg1} += 1;
					sendAddStatusPoint(\$remote_socket, $ID);
				}
			} else {
				$chars[$config{'char'}]{$arg1} += 1;
				sendAddStatusPoint(\$remote_socket, $ID);
			}
		}

	} elsif ($switch eq "storage") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\w+)/;
		($arg4) = $input =~ /^[\s\S]*? \w+ \d+ \d+ (\w+)/;
		# Classify storage items like command 'i'
		if (switchInput($params[1], "", "eq", "u", "nu", "card", "arrow")) {

			getItemList(\@{$storage{'inventory'}}, $params[1], "Storage", "Capacity: $storage{'items'}/$storage{'items_max'}", ($config{'recordStorage'}>1?1:0));

		} elsif ($arg1 eq "add" && $arg2 =~ /^\d+$/ && !%{$chars[$config{'char'}]{'inventory'}[$arg2]}) {
			print	"�o�Ϳ��~ 'storage add' (Add Item to Storage)\n"
				, "���s�J���~ $arg2 ���s�b.\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /^\d+$/) {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
				$arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
			}
			sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);
		} elsif ($arg1 eq "add" && $arg2 eq "") {
			print	"�y�k���~ 'storage add' (Add Item to Storage)\n"
				, "�ϥΤ�k: storage add <���~�s��> [<�ƶq>]\n";

		} elsif ($arg1 eq "get" && $arg2 =~ /^\d+$/ && !%{$storage{'inventory'}[$arg2]}) {
			print	"�o�Ϳ��~ 'storage get' (Get Item from Storage)\n"
				, "���������~ $arg2 ���s�b.\n";
		} elsif ($arg1 eq "get" && $arg2 =~ /^\d+$/) {
			if (!$arg3 || $arg3 > $storage{'inventory'}[$arg2]{'amount'} || $arg3 eq "cart") {
				$arg4 = "cart" if ($arg3 eq "cart");
				$arg3 = $storage{'inventory'}[$arg2]{'amount'};
			}
			if ($arg4 eq "cart") {
				sendStorageGetToCart(\$remote_socket, $arg2, $arg3);
			} else {
				sendStorageGet(\$remote_socket, $arg2, $arg3);
			}
		} elsif ($arg1 eq "get" && $arg2 eq "") {
			print	"�y�k���~ 'storage get' (Get Item from Storage)\n"
				, "�ϥΤ�k: storage get <�ܮw���~�s��> [<�ƶq>] [<cart>]\n";

		} elsif ($arg1 eq "close") {
			sendStorageClose(\$remote_socket);

		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/ && !%{$storage{'inventory'}[$arg2]}) {
			print	"�o�Ϳ��~ 'storage desc' (Storage Item Description)\n"
				, "���˵����~ $arg2 ���s�b.\n";
		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/) {

			printDesc(0, $storage{'inventory'}[$params[2]]{'nameID'}, fixingName(\%{$storage{'inventory'}[$params[2]]}));

		} else {
			print	"�y�k���~ 'storage' (Storage List)\n"
				, "�ϥΤ�k: storage [<u | eq | nu | desc>] [<�ܮw���~�s��>]\n";
		}

	} elsif ($switch eq "store") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "" && !$talk{'buyOrSell'}) {
			$~ = "STORELIST";
			print "---------------- �ө����~�M�� ----------------\n";
			print "#   �W��                    ����      �� �B(Z)\n";
			for ($i=0; $i < @storeList;$i++) {
				$price_string = toZeny($storeList[$i]{'price_dc'});
				format STORELIST =
@<< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @>>>>>>>>
$i, $storeList[$i]{'name'}, $itemTypes_lut{$storeList[$i]{'type'}}, $price_string
.
				write;
			}
			print "----------------------------------------------\n";
			print "$npcs{$talk{'ID'}}{'name'}: �п�J 'buy <�ө����~�s��> [<�ƶq>]' �ʶR���~\n"
				, "$npcs{$talk{'ID'}}{'name'}: �ο�J 'store' �d�ݰө����~�M��\n";

		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/ && !%{$storeList[$arg2]}) {
			print	"�o�Ϳ��~ 'store desc' (Store Item Description)\n"
				, "���˵��ө����~ $arg2 ���s�b.\n";
		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/) {

			printDesc(0, $storeList[$arg2]{'nameID'}, $storeList[$arg2]{'name'});

		} else {
			print	"�y�k���~ 'store' (Store Functions)\n"
				, "�ϥΤ�k: store [<desc>] [<�ө����~�s��>]\n";

		}

	} elsif ($switch eq "take") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)$/;
		if ($arg1 eq "") {
			print	"�y�k���~ 'take' (Take Item)\n"
				, "�ϥΤ�k: take <���~�s��>\n";
		} elsif ($itemsID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'take' (Take Item)\n"
				, "���ߨ����~ $arg1 ���s�b.\n";
		} else {
			take($itemsID[$arg1]);
		}


	} elsif ($switch eq "talk") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ "([\s\S]*?)"$/;
		$type = 0;
		if ($arg2 eq "") {
			($arg2) =$input =~ /^[\s\S]*? \w+ (\d+)/;
			$type = 1;
		}

		if ($arg1 =~ /^\d+$/ && $npcsID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'talk' (Talk to NPC)\n"
				, "NPC $arg1 ���s�b.\n";
		} elsif ($arg1 =~ /^\d+$/) {
			sendTalk(\$remote_socket, $npcsID[$arg1]);

		} elsif ($arg1 eq "answer" && !%talk) {
			print	"�o�Ϳ��~ 'talk answer' (Answer to NPC)\n"
				, "�A�٨S������� NPC ���.\n";
		} elsif ($arg1 eq "answer" && $arg2 eq "") {
			print	"�y�k���~ 'talk answer' (Answer to NPC)\n"
				, qq~�ϥΤ�k: talk answer (�ƶq | "<��r>")\n~;
		} elsif ($arg1 eq "answer" && $arg2 ne "") {
			if ($type) {
				sendTalkAnswerNum(\$remote_socket, $talk{'ID'}, $arg2);
			} else {
				sendTalkAnswerWord(\$remote_socket, $talk{'ID'}, $arg2);
			}

		} elsif ($arg1 eq "resp" && !%talk) {
			print	"�o�Ϳ��~ 'talk resp' (Respond to NPC)\n"
				, "�A�٨S�������NPC���.\n";
		} elsif ($arg1 eq "resp" && $arg2 eq "") {
			$~ = "RESPONSES";
			$display = $npcs{$talk{'ID'}}{'name'};
			print "------------------ �^���M�� ------------------\n";
			print "��H: $display\n\n";
			print "#   �ﶵ                                      \n";
			for ($i=0; $i < @{$talk{'responses'}};$i++) {
				format RESPONSES =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $talk{'responses'}[$i]
.
				write;
			}
			print "----------------------------------------------\n";
			print "$npcs{$talk{'ID'}}{'name'}: �п�J 'talk resp <�s��>' ��ܱ��^���ﶵ, �ο�J 'talk no' �������\n"
				, "$npcs{$talk{'ID'}}{'name'}: �ο�J 'talk resp' �d�ݦ^���M��\n";

		} elsif ($arg1 eq "resp" && $arg2 ne "" && $talk{'responses'}[$arg2] eq "") {
			print	"�o�Ϳ��~ 'talk resp' (Respond to NPC)\n"
				, "���^���ﶵ $arg2 ���s�b.\n";
		} elsif ($arg1 eq "resp" && $arg2 ne "") {
			$arg2 += 1;
			sendTalkResponse(\$remote_socket, $talk{'ID'}, $arg2);

		} elsif ($arg1 eq "cont" && !%talk) {
			print	"�o�Ϳ��~ 'talk cont' (Continue Talking to NPC)\n"
				, "�A�٨S�������NPC���.\n";
		} elsif ($arg1 eq "cont") {
			sendTalkContinue(\$remote_socket, $talk{'ID'});

		} elsif ($arg1 eq "no" && !%talk) {
			print	"�o�Ϳ��~ 'talk no' (Talk to NPC)\n"
				, "�A�٨S�������NPC���.\n";
		} elsif ($arg1 eq "no") {
			$talk{'clientCancel'} = 1;
			sendTalkResponse(\$remote_socket, $talk{'ID'}, 255);

		} else {
			print	"�y�k���~ 'talk' (Talk to NPC)\n"
				, qq~�ϥΤ�k: talk <NPC�s�� | cont | resp | answer | no> [<�^���ﶵ�s��> | (�ƶq | "<��r>")]\n~;
		}


	} elsif ($switch eq "tank") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			print	"�y�k���~ 'tank' (Tank for a Player)\n"
				, "�ϥΤ�k: tank <���a�s��>\n";
		} elsif ($arg1 eq "stop") {
#			configModify("tankMode", 0);
			scModify("config", "tankMode", 0, 2);
		} elsif ($playersID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'tank' (Tank for a Player)\n"
				, "���a $arg1 ���s�b.\n";
		} else {
#			configModify("tankMode", 1);
#			configModify("tankModeTarget", $players{$playersID[$arg1]}{'name'});
#
			scModify("config", "tankMode", 1, 2);
			scModify("config", "tankModeTarget", $players{$playersID[$arg1]}{'name'}, 2);
		}

	} elsif ($switch eq "tele") {
		$ai_v{'temp'}{'teleOnEvent'} = 1;
		timeOutStart('ai_teleport_event');
		useTeleport(1);
		$ai_v{'clear_aiQueue'} = 1;

	} elsif (switchInput($switch, "timeout", "conf")) {
#		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
#		($arg2) = $input =~ /^[\s\S]*? \w+ ([\s\S]+)$/;
#		if ($arg1 eq "") {
#			print	"�y�k���~ 'timeout' (Set a Timeout)\n"
#				, "�ϥΤ�k: timeout <�ɶ��ܼƦW��> [<���>]\n";
#		} elsif ($timeout{$arg1} eq "") {
#			print	"�o�Ϳ��~ 'timeout' (Set a Timeout)\n"
#				, "�A�Q�]�w���ɶ��ܼ� $arg1 ���s�b.\n";
#		} elsif ($arg2 eq "") {
#			print "�ɶ��ܼ� $arg1 �ثe���Ȭ� $timeout{$arg1}{'timeout'}\n";
#		} else {
#			setTimeout($arg1, $arg2);
#		}

		print "$switch\n";

		if (!$params[1]) {
			print	"�y�k���~ '$switch' (Set a $switch)\n"
				, "�ϥΤ�k: $switch <variable> [<value> | <null>]\n";
		} else {

			$switch = "config" if (switchInput($switch, "conf"));

			my $idx;

			if (switchInput($params[2], "null")) {

				$params[2] = "";

				$idx = 2;
			} elsif ($params[2] eq "") {

				$idx = 0;
			} else {
				$idx = 2;
			}

			scModify($switch, $params[1], $params[2], $idx, 1);
		}

	} elsif ($switch eq "uneq") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			print	"�y�k���~ 'uneq' (Unequip Inventory Item)\n"
				, "�ϥΤ�k: uneq <���~�s��>\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"�o�Ϳ��~ 'uneq' (Unequip Inventory Item)\n"
				, "�����U�˳� $arg1 ���s�b.\n";
		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'equipped'} eq "") {
			print	"�o�Ϳ��~ 'uneq' (Unequip Inventory Item)\n"
				, "�A�S���˳� $arg1.\n";
		} else {
			sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'});
		}

	} elsif ($switch eq "where") {
		$map_string = getMapName($map_name, 1);
#		printC("�ثe��m �i$map_string: ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."�j\n", "s");
#Karasu Start
		printC(
			subStrLine(0, "Location Info")
			."Location $map_string : $chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'}\n"
#			."Last destination calculated : (".int($old_x).", ".int($old_y).") from spot (".int($old_pos_x).", ".int($old_pos_y).").\n"
			.subStrLine()
			, "s"
		);

		# Map viewer
		undef $ai_v{'map_refresh'}{'time'};
#Karasu End

	} elsif ($switch eq "who") {
		sendWho(\$remote_socket);

	# AI functions
	} elsif ($switch eq "ai") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\w+)/;
		if ($arg1 eq "") {
			my $stuff = @ai_seq_args;
			print "AI: @ai_seq | $stuff\n";
		} elsif ($arg1 eq "pause" && $arg2 =~ /^\d+$/ && $arg2 <= 0) {
			print	"�o�Ϳ��~ 'ai pause' (Suspend AI Mission)\n"
				, "���w�Ȱ���ƥ��ݤj��s.\n";
		} elsif ($arg1 eq "pause" && $arg2 =~ /^\d+$/) {
			print "�Ȱ��ثe�Ҧ�AI���� $arg2��\n";
			ai_clientSuspend(0, $arg2);

		} elsif ($arg1 eq "resume") {
			print "��_�ثe�Ҧ�AI����\n";
			aiRemove("clientSuspend");

		} elsif ($arg1 eq "clear") {
			print "�M���ثe�Ҧ�AI����\n";
			undef @ai_seq;
			undef @ai_seq_args;

		} elsif ($arg1 eq "remove" && $arg2 && binFind(\@ai_seq, $arg2) eq "") {
			print	"�o�Ϳ��~ 'ai remove' (Remove AI Mission)\n"
				, "���������� $arg2 ���s�b.\n";
		} elsif ($arg1 eq "remove" && $arg2) {
			print "����AI���� $arg2\n";
			aiRemove($arg2);
		} elsif ($arg1 eq "remove" && $arg2 eq "0" && !binSize(\@ai_seq)) {
			print	"�o�Ϳ��~ 'ai remove' (Remove AI Mission)\n"
				, "�ثe�õL����AI����.\n";
		} elsif ($arg1 eq "remove" && $arg2 eq "0") {
			print "�����Ĥ@��AI���� $ai_seq[0]\n";
			aiRemove($ai_seq[0]);
		} elsif ($arg1 eq "remove") {
			print	"�y�k���~ 'ai remove' (Remove AI Mission)\n"
				, "�ϥΤ�k: ai remove <���ȦW�� | 0=�Ĥ@�ӥ���>\n";
		} else {
			print	"�y�k���~ 'ai' (AI Control)\n"
				, "�ϥΤ�k: ai [<pause | resume | clear | remove>] [<�Ȱ���� | ���ȦW�� | 0=�Ĥ@�ӥ���>]\n";
		}

	} elsif ($switch eq "AID") {
		my $AID = unpack("L1", $accountID);
		print "[AID]: $AID\n";

	# Recall to supply
	} elsif ($switch eq "recall") {

		ai_unshift("talkAuto");

#Karasu Start
	# Aggressive Monster List
	} elsif ($switch eq "aml") {
		$~ = "MLIST";
		$mycoords = getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
		print "---------------------------------- �Ǫ��C�� ---------------------$mycoords----\n";
		print "#   Lv �W��                            �A�����ˮ`    �A����ˮ`   �y   �� �Z��\n";
		for ($i = 0; $i < @monstersID; $i++) {
			next if ($monstersID[$i] eq "");
			$mlcoords = getFormattedCoords($monsters{$monstersID[$i]}{'pos_to'}{'x'}, $monsters{$monstersID[$i]}{'pos_to'}{'y'});
			$dMDist = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$monsters{$monstersID[$i]}{'pos_to'}}));
			$dmgTo = ($monsters{$monstersID[$i]}{'dmgFromYou'} ne "")
				? $monsters{$monstersID[$i]}{'dmgFromYou'}
				: 0;
			$dmgFrom = ($monsters{$monstersID[$i]}{'dmgToYou'} ne "")
				? $monsters{$monstersID[$i]}{'dmgToYou'}
				: 0;
			write if ($dmgFrom || $monsters{$monstersID[$i]}{'missedYou'});
		}
		print "------------------------------------------------------------------------------\n";


	# Make arrow
	} elsif ($switch eq "arrow") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			$~ = "ARROWMAKING";
			print "------------- �i�s�@�b�ڪ��~�M�� -------------\n";
			print "#   �W��                                      \n";
			for ($i = 0; $i < @arrowID; $i++) {
				next if ($arrowID[$i] eq "");
				format ARROWMAKING =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $items_lut{$arrowID[$i]}
.
				write;
			}
			print "----------------------------------------------\n";
			print "�п�J 'arrow <�i�s�@�b�ڪ��~�s��>' ���\n";

		} elsif ($arg1 =~ /^\d+$/ && $arrowID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'arrow' (Make Arrow)\n"
				, "���s�@�b�ڪ��~ $arg1 ���s�b.\n";

		} elsif ($arg1 =~ /^\d+$/) {
			sendArrowMake(\$remote_socket, $arrowID[$arg1]);
		} else {
			print	"�y�k���~ 'arrow' (Make Arrow)\n"
				, "�ϥΤ�k: arrow [<�i�s�@�b�ڪ��~�s��>]\n";
		}

	} elsif ($switch eq "autospell") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			$~ = "AUTOSPELL";
			print "------------- �i�۰ʩ��G�ޯ�M�� -------------\n";
			print "#   �W��                                      \n";
			for ($i = 0; $i < @autospellID; $i++) {
				next if ($autospellID[$i] eq "");
				format AUTOSPELL =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $skillsID_lut{$autospellID[$i]}
.
				write;
			}
			print "----------------------------------------------\n";
			print "�п�J 'autospell <�i�۰ʩ��G�ޯ�s��>' ���\n";

		} elsif ($arg1 =~ /^\d+$/ && $autospellID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'autospell' (Set Autospell Skill)\n"
				, "���۰ʩ��G�ޯ� $arg1 ���s�b.\n";

		} elsif ($arg1 =~ /^\d+$/) {
			sendAutospell(\$remote_socket, $autospellID[$arg1]);
		} else {
			print	"�y�k���~ 'autospell' (Set Autospell Skill)\n"
				, "�ϥΤ�k: autospell [<�i�۰ʩ��G�ޯ�s��>]\n";
		}

	} elsif ($switch eq "make") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
		if ($arg1 eq "") {
			$~ = "MAKELIST";
			print "----------- �i��M���~/�t�s�Ĳ~�M�� ----------\n";
			print "#   �W��                                      \n";
			for ($i = 0; $i < @makeID; $i++) {
				next if ($makeID[$i] eq "");
				format MAKELIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $items_lut{$makeID[$i]}
.
				write;
			}
			print "----------------------------------------------\n";
			print "�п�J 'make <�i��M���~/�t�s�Ĳ~�s��>' ���\n";
			print "�п�J 'make <�i��M���~�s��> <�ݩ�> <�P���ƶq>' ��M�ݩʩαj���Z��\n"
				, "        <�ݩ�: 0=�L, 1=��, 2=��, 3=��, 4=�a>\n";

		} elsif ($arg1 =~ /^\d+$/ && $makeID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'make' (Smithery and Pharmacy)\n"
				, "����M���~/�t�s�Ĳ~ $arg1 ���s�b.\n";

		} elsif ($arg1 =~ /^\d+$/) {
			if (!$arg2 && !$arg3) {
				sendItemCreate(\$remote_socket, $makeID[$arg1]);
			} elsif (($arg2 >= 1 && $arg2 <= 4 && $arg3 >= 0 && $arg3 <= 2)
					|| (!$arg2 && $arg3 >= 1 && $arg3 <= 3)) {
				my $found = 1;
				if ($arg2) {
					undef $invIndex;
					$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", $arg2 + 993);
					if ($invIndex ne "") {
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= 1;
					} else {
						$found = 0;
					}
				}
				if ($arg3) {
					undef $invIndex;
					$invIndex = findIndex(\@{$chars[$config{'char'}]{'inventory'}}, "nameID", 1000);
					if ($invIndex ne "" && $chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} > $arg3) {
						$chars[$config{'char'}]{'inventory'}[$invIndex]{'amount'} -= $arg3;
					} else {
						$found = 0;
					}
				}
				if ($found) {
					$arg2 = $arg2 + 993 if ($arg2);
					sendItemCreate(\$remote_socket, $makeID[$arg1], $arg2, $arg3);
				} else {
					print	"�o�Ϳ��~ 'make <�i��M���~�s��> <�ݩ�> <�P���ƶq>' (Smithery and Pharmacy)\n"
					, "���ˬd���W�� �ݩʥ� �H�� �P�P���� ���ƶq.\n";
				}
			} else {
				print	"�o�Ϳ��~ 'make <�i��M���~�s��> <�ݩ�> <�P���ƶq>' (Smithery and Pharmacy)\n"
					, "���ˬd��J�� <�ݩ�> �H�� <�P���ƶq> �O�_���~.\n";
			}

		} elsif ($arg1 eq "desc" && !$makeID[$arg2]) {
			print	"�o�Ϳ��~ 'make desc' (Smithery Material Description)\n"
				, "���˵����� $arg2 ���s�b.\n";
		} elsif ($arg1 eq "desc") {

			printDesc("make", $makeID[$params[2]], $items_lut{$makeID[$params[2]]});

		} else {
			print	"�y�k���~ 'make' (Smithery and Pharmacy)\n"
				, "�ϥΤ�k: make [<�i��M���~/�t�s�Ĳ~�s��>] [<�ݩ�>] [<�P���ƶq>]\n"
				, "          make <desc> <�i��M���~/�t�s�Ĳ~�s��>\n";
		}

	# EXPs gained per hour
	} elsif ($switch eq "exp") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;

		my ($EstB_hour,$EstB_min,$EstB_sec,$EstJ_hour,$EstJ_min,$EstJ_sec, $total) = (0,0,0,0,0,0,0);
		my ($endTime_EXP,$w_hour,$w_min,$w_sec,$bExpPerHour,$jExpPerHour,$percentB,$percentJ, $percentBH, $percentJH, $EstB_day, $EstJ_day);

		if (!switchInput($params[1], "log", "cls", "reset")) {
			$record{'exp'}{'end'} = time;
			$w_sec = int($record{'exp'}{'end'} - $record{'exp'}{'start'});
#			$bExpPerHour = ($w_sec != 0) ? int($sc_v{'exp'}{'base'} * 3600 / $w_sec) : 0;
#			$jExpPerHour = ($w_sec != 0) ? int($sc_v{'exp'}{'job'} * 3600 / $w_sec) : 0;

			$w_hour = $w_min = 0;

			if ($w_sec > 0) {

				if($sc_v{'exp'}{'base'}){
					$bExpPerHour = int($sc_v{'exp'}{'base'} / $w_sec * 3600);
					$percentBH = "(".sprintf("%.2f",$bExpPerHour * 100 / $chars[$config{'char'}]{'exp_max'})."%)";
					$percentB = "(".sprintf("%.2f",$sc_v{'exp'}{'base'} * 100 / $chars[$config{'char'}]{'exp_max'})."%)";
				}

				if($sc_v{'exp'}{'job'}){
					$jExpPerHour = int($sc_v{'exp'}{'job'} / $w_sec * 3600);
					$percentJH = "(".sprintf("%.2f",$jExpPerHour * 100 / $chars[$config{'char'}]{'exp_job_max'})."%)";
					$percentJ = "(".sprintf("%.2f",$sc_v{'exp'}{'job'} * 100 / $chars[$config{'char'}]{'exp_job_max'})."%)";
				}

				if ($w_sec >= 3600) {
					$w_hour = int($w_sec / 3600);
					$w_sec %= 3600;
				}
				if ($w_sec >= 60) {
					$w_min = int($w_sec / 60);
					$w_sec %= 60;
				}
				if (!isLevelMax(0, $chars[$config{'char'}]{'lv'}) && $bExpPerHour){
					$EstB_sec = int(($chars[$config{'char'}]{'exp_max'} - $chars[$config{'char'}]{'exp'})/($bExpPerHour/3600));
					$EstB_hour = ($EstB_sec >=3600) ? int($EstB_sec/3600):0;
					$EstB_sec %=3600;
					$EstB_min = ($EstB_sec >=60) ? int($EstB_sec/60):0;
					$EstB_sec %=60;

					if ($EstB_hour >= 24){
						$EstB_day = int($EstB_hour / 24);
						$EstB_hour %= 24;

						$EstB_day = '��' if ($EstB_day > 100);
						$EstB_day .= ' ��';
					}

					$EstB_hour = "0" . $EstB_hour if ($EstB_hour < 10);
					$EstB_min = "0" . $EstB_min if ($EstB_min < 10);
					$EstB_sec = "0" . $EstB_sec if ($EstB_sec < 10);

				}
				if (!isLevelMax(1, $chars[$config{'char'}]{'lv_job'}, $chars[$config{'char'}]{'exp_job_max'}) && $jExpPerHour){
					$EstJ_sec = int(($chars[$config{'char'}]{'exp_job_max'} - $chars[$config{'char'}]{'exp_job'})/($jExpPerHour/3600));
					$EstJ_hour = ($EstJ_sec >=3600) ? int($EstJ_sec/3600):0;
					$EstJ_sec %=3600;
					$EstJ_min = ($EstJ_sec >=60) ? int($EstJ_sec/60):0;
					$EstJ_sec %=60;

					if ($EstJ_hour >= 24){
						$EstJ_day = int($EstJ_hour / 24);
						$EstJ_hour %= 24;

						$EstJ_day = '��' if ($EstJ_day > 100);
						$EstJ_day .= ' ��';
					}

					$EstJ_hour = "0" . $EstJ_hour if ($EstJ_hour < 10);
					$EstJ_min = "0" . $EstJ_min if ($EstJ_min < 10);
					$EstJ_sec = "0" . $EstJ_sec if ($EstJ_sec < 10);

				}
			}

			my $t_exp_line = ("-" x45);

			print
			  subStrLine($t_exp_line,"Exp Report")
			. swrite(
			  "Report  time : @# Hours @> Minutes @> Seconds"
			, [$w_hour, $w_min, $w_sec]
			, "BaseExp      : @>>>>>>>>>>>>>>>>>>>> @>>>>>>>"
			, [$sc_v{'exp'}{'base'},$percentB]
			, "JobExp       : @>>>>>>>>>>>>>>>>>>>> @>>>>>>>"
			, [$sc_v{'exp'}{'job'}, $percentJ]
			, "BaseExp/Hour : @>>>>>>>>>>>>>>>>>>>> @>>>>>>>"
			, [$bExpPerHour, $percentBH]
			, "JobExp/Hour  : @>>>>>>>>>>>>>>>>>>>> @>>>>>>>"
			, [$jExpPerHour, $percentJH]
			, "Base Levelup Time Estimation : @>>>> @>:@>:@>"
			, [$EstB_day, $EstB_hour,$EstB_min,$EstB_sec]
			, "Job Levelup Time Estimation  : @>>>> @>:@>:@>"
			, [$EstJ_day, $EstJ_hour,$EstJ_min,$EstJ_sec]);

			undef $tmpVal{'value'};

			$params[1] = "" if ($params[1] eq "all");

			if(@{$record{"warp"}{'memo'}} && switchInput($params[1], "", "warp")){
				$tmpVal{'value'} .= subStrLine($t_exp_line,"Warp Portal Record ($record{'warp'}{'use'})");

				$tmpVal{'format'} = " @> @<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<";
				for ($i=0; $i<@{$record{"warp"}{'memo'}}; $i++){
					$tmpVal{'value'} .= swrite($tmpVal{'format'}, [$i, $record{"warp"}{'memo'}[$i], getMapName($record{"warp"}{'memo'}[$i])]);
				}
			}

			print $tmpVal{'value'};
			undef $tmpVal{'value'};

			if(%{$record{"zenny"}} && switchInput($params[1], "", "zenny", "z", "zeny")){
				$tmpVal{'value'} .= subStrLine($t_exp_line,"Zenny Record");

				$tmpVal{'format'} = " @> @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ";

				$tmpVal{'value'} .= swrite($tmpVal{'format'}, ["+", toZeny($record{"zenny"}{"+"})]) if ($record{"zenny"}{"+"});
				$tmpVal{'value'} .= swrite($tmpVal{'format'}, ["-", toZeny($record{"zenny"}{"-"})]) if ($record{"zenny"}{"-"});

				$tmpVal{'value'} .= swrite($tmpVal{'format'}, ["=", toZeny($record{"zenny"}{"+"} - $record{"zenny"}{"-"})]) if ($record{"zenny"}{"+"} && $record{"zenny"}{"-"});
			}

			print $tmpVal{'value'};
			undef $tmpVal{'value'};

			$tmpVal{'format'} = " @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< x@>>>>>>";

			my ($defeatMonsterID, $defeatMonsterName, $defeatMonsterNum);

			my @defeatKey = sort keys(%{$record{"counts"}});

			if(@defeatKey && switchInput($params[1], "", "count", "counts", "c")){
				$tmpVal{'value'} .= subStrLine($t_exp_line,"Counts Report");

				foreach (@defeatKey) {
					$defeatMonsterName = $_;
					$defeatMonsterNum = $record{"counts"}{$_};

					$tmpVal{'value'} .= swrite($tmpVal{'format'}, [$defeatMonsterName, $defeatMonsterNum]);
				}
			}

			print $tmpVal{'value'};
			undef $tmpVal{'value'};

			$tmpVal{'format'} = " @>>> @<<<<<<<<<<<<<<<<<<<<<<<<<<<< x@>>>>>>";

			@defeatKey = sort sortNum keys(%{$record{"storageGet"}});

			if(@defeatKey && switchInput($params[1], "", "s", "storage")){
				$tmpVal{'value'} .= subStrLine($t_exp_line,"Storage Get");

				foreach (@defeatKey) {
					$defeatMonsterID = lenNum($_, 4);
					$defeatMonsterName = getName("item", $_);
					$defeatMonsterNum = $record{"storageGet"}{$_};

					$tmpVal{'value'} .= swrite($tmpVal{'format'}, [$defeatMonsterID, $defeatMonsterName, $defeatMonsterNum]);
				}
			}

			print $tmpVal{'value'};
			undef $tmpVal{'value'};

			@defeatKey = sort sortNum keys(%{$record{"steal"}});

			if(@defeatKey && switchInput($params[1], "", "steal")){
				$tmpVal{'value'} .= subStrLine($t_exp_line,"Steal Report");

				foreach (@defeatKey) {
					$defeatMonsterID = lenNum($_, 4);
					$defeatMonsterName = getName("mon", $_);
					$defeatMonsterNum = $record{"steal"}{$_};

					$tmpVal{'value'} .= swrite($tmpVal{'format'}, [$defeatMonsterID, $defeatMonsterName, $defeatMonsterNum]);
				}
			}
			print $tmpVal{'value'};
			undef $tmpVal{'value'};

			@defeatKey = sort sortNum keys(%{$record{"takeNot"}});

			if(@defeatKey && switchInput($params[1], "", "steal", "item", "items")){
				$tmpVal{'value'} .= subStrLine($t_exp_line,"Not Take");

				foreach (@defeatKey) {
					$defeatMonsterID = lenNum($_, 4);
					$defeatMonsterName = getName("item", $_);
					$defeatMonsterNum = $record{"takeNot"}{$_};

					$tmpVal{'value'} .= swrite($tmpVal{'format'}, [$defeatMonsterID, $defeatMonsterName, $defeatMonsterNum]);
				}
			}
			print $tmpVal{'value'};
			undef $tmpVal{'value'};

			@defeatKey = sort sortNum keys(%{$record{"Auto-Drop"}});

			if(@defeatKey && switchInput($params[1], "", "drop", "item", "items")){
				$tmpVal{'value'} .= subStrLine($t_exp_line,"Auto Drop");

				foreach (@defeatKey) {
					$defeatMonsterID = lenNum($_, 4);
					$defeatMonsterName = getName("item", $_);
					$defeatMonsterNum = $record{"Auto-Drop"}{$_};

					$tmpVal{'value'} .= swrite($tmpVal{'format'}, [$defeatMonsterID, $defeatMonsterName, $defeatMonsterNum]);
				}
			}

			print $tmpVal{'value'};
			undef $tmpVal{'value'};

			@defeatKey = sort sortNum keys(%{$record{"monsters"}});

			if(@defeatKey && switchInput($params[1], "", "mon", "monsters", "monster")){
				$tmpVal{'value'} .= subStrLine($t_exp_line,"Mon Report");

				foreach (@defeatKey) {
					$defeatMonsterID = lenNum($_, 4);
					$defeatMonsterName = getName("mon", $_);
					$defeatMonsterNum = $record{"monsters"}{$_};

					$tmpVal{'value'} .= swrite($tmpVal{'format'}, [$defeatMonsterID, $defeatMonsterName, $defeatMonsterNum]);
				}
			}

			print $tmpVal{'value'};
			undef $tmpVal{'value'};

			@defeatKey = sort sortNum keys(%{$record{"item"}});

			if(@defeatKey && switchInput($params[1], "", "item", "items")){
				$tmpVal{'value'} .= subStrLine($t_exp_line,"Rare Item");

				foreach (@defeatKey) {
					$defeatMonsterID = lenNum($_, 4);
					$defeatMonsterName = getName("item", $_);
					$defeatMonsterNum = $record{"item"}{$_};

					$tmpVal{'value'} .= swrite($tmpVal{'format'}, [$defeatMonsterID, $defeatMonsterName, $defeatMonsterNum]);
				}
			}

			print $tmpVal{'value'};

			print subStrLine($t_exp_line);

		} elsif (switchInput($params[1], "log")) {
			open(EXPLOG, ">> $sc_v{'path'}{'def_logs'}"."ExpLog.txt");
			select(EXPLOG);
			print "[".getFormattedDate(int($record{'exp'}{'start'}))." -> ".getFormattedDate(int(time))."]\n";
			print "[".$servers[$config{'server'}]{'name'}." - ".$chars[$config{'char'}]{'name'};
			if ($config{'lockMap'}) {
				print " - ".$config{'lockMap'}."]\n";
			} else {
				print "]\n";
			}
			print "[$sc_v{'kore'}{'exeName'} $sc_v{'Scorpio'}{'version'}]\n";
			close(EXPLOG);
			logCommand(">> $sc_v{'path'}{'def_logs'}"."ExpLog.txt", "exp");
		} elsif (switchInput($params[1], "reset", "cls")) {
			undef $sc_v{'exp'}{'base'};
			undef $sc_v{'exp'}{'job'};

			undef %record;

			$record{'exp'}{'start'} = time;
			$record{'exp'}{'record'} = time;
		} else {
			print "�y�k���~ 'exp' (Show Exp Earning Speed)\n"
				, "�ϥΤ�k: exp [<log | reset>]\n";
		}

	# Guild related
	} elsif ($switch eq "guild") {
#		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
#		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
#		my $ID = $chars[$config{'char'}]{'guild'}{'ID'};
#		if ($params[1] eq "" && !%{$chars[$config{'char'}]{'guild'}}) {
#			print	"�o�Ϳ��~ 'guild' (Guild Functions)\n"
#				, "�L�k�d�ߤ��|��T - �A�S�����|.\n";
#		} elsif (switchInput($params[1], "i", "info", "", "information")) {
#			$~ = "GUILD";
#			$online_string = $guild{$ID}{'conMember'}."/".$guild{$ID}{'maxMember'};
#			$exp_string = $guild{$ID}{'exp'}."/".$guild{$ID}{'next_exp'};
#			print "------------------ ���|��T ------------------\n";
#			format GUILD =
#���|�W��: @<<<<<<<<<<<<<<<<<<<<<<
#          $guild{$ID}{'name'}
#���|����: @>       �g���: @>>>>>>>>>>>>>>>>>>
#          $guild{$ID}{'lvl'}, $exp_string
#�|���W��: @<<<<<<<<<<<<<<<<<<<<<<
#          $guild{$ID}{'master'}
#���|�H��: @<<<<    ���|������������: @>
#          $online_string, $guild{$ID}{'average'}
#
#[�P�����|]              [�Ĺ綠�|]
#@<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<
#$guild{$ID}{'alliance'}[0]{'name'}, $guild{$ID}{'rival'}[0]{'name'}
#@<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<
#$guild{$ID}{'alliance'}[1]{'name'}, $guild{$ID}{'rival'}[1]{'name'}
#@<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<
#$guild{$ID}{'alliance'}[2]{'name'}, $guild{$ID}{'rival'}[2]{'name'}
#.
#		write;
#			print "----------------------------------------------\n";
#		} elsif ($params[1] eq "member" && !%{$chars[$config{'char'}]{'guild'}}) {
#			print	"�o�Ϳ��~ 'guild member' (Guild Functions)\n"
#				, "�L�k�d�ߤ��|���� - �A�S�����|.\n";
#		} elsif ($params[1] eq "member") {
#			$~ = "GM";
#			print "---------------------------------- ���|���� ----------------------------------\n";
#			print "�u�W �W��                    ¾��                    ¾�~     ����  ú�Ǹg���\n";
#			for ($i = 0; $i < $guild{$ID}{'members'}; $i++) {
#				$online_string = $guild{$ID}{'member'}[$i]{'online'} ? " �� " : "";
#				$name_string  = $guild{$ID}{'member'}[$i]{'name'};
#				$title_string = $guild{$ID}{'title'}[$guild{$ID}{'member'}[$i]{'title'}];
#				$job_string   = $jobs_lut{$guild{$ID}{'member'}[$i]{'jobID'}};
#				$lvl_string   = $guild{$ID}{'member'}[$i]{'lvl'};
#				$exp_string   = $guild{$ID}{'member'}[$i]{'contribution'};
#				format GM =
#@<<< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @>>   @>>>>>>>>>
#$online_string, $name_string, $title_string, $job_string, $lvl_string, $exp_string
#.
#				write;
#			}
#			print "------------------------------------------------------------------------------\n";
#
#		} elsif ($params[1] eq "join" && $params[2] ne "1" && $params[2] ne "0") {
#			print	"�y�k���~ 'guild join' (Accept/Deny Guild Join Request)\n"
#				, "�ϥΤ�k: guild join <0=�ڵ� | 1=����>\n";
#		} elsif ($params[1] eq "join" && $incomingGuild{'ID'} eq "") {
#			print	"�o�Ϳ��~ 'guild join' (Join/Request to Join Guild)\n"
#				, "�L�k�����Ωڵ����|�ܽ� - �S�����|�ܽ�.\n";
#		} elsif ($params[1] eq "join") {
#			sendGuildJoin(\$remote_socket, $incomingGuild{'ID'}, $params[2]);
#			undef %incomingGuild if ($params[2] eq "0");
#
#		} elsif ($params[1] eq "request" && !%{$chars[$config{'char'}]{'guild'}}) {
#			print	"�o�Ϳ��~ 'guild request' (Request to Join Guild)\n"
#				, "�L�k�ܽХ[�J - �A�S�����|.\n";
#		} elsif ($params[1] eq "request" && $playersID[$params[2]] eq "") {
#			print	"�o�Ϳ��~ 'guild request' (Request to Join Guild)\n"
#				, "�L�k�ܽХ[�J - ���ܽЪ��a $params[2] ���s�b.\n";
#		} elsif ($params[1] eq "request") {
#			sendGuildJoinRequest(\$remote_socket, $playersID[$params[2]]);
#		}

		my $ID = $chars[$config{'char'}]{'guild'}{'ID'};

		$tmpVal{'tag'}		= $switch;
		$tmpVal{'title'}	= "Guild Functions";

		if (!switchInput($params[1], "join", "j") && !$chars[$config{'char'}]{'guild'}{'name'}) {

			$tmpVal{'text'} = "�L�k�d�ߤ��|��T - �A�S�����|";

		} elsif (!switchInput($params[1], "join", "j", "u", "user", "users") && (!%{$guild{$ID}} || !$guild{$ID}{'name'})) {

			sendGuildInfoRequest(\$remote_socket);

			for (my $i = 0; $i<=4 ; $i++) {
				sendGuildRequest(\$remote_socket, $i);
			}

		} elsif (switchInput($params[1], "i", "info", "", "information")) {

			$tmpVal{'line'} = "@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<";

			print subStrLine($tmpVal{'line'}, "Guild Info (ID: ".getHex($ID)." )", -1);

			print swrite(
				 "���|�W��: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<", [$guild{$ID}{'name'}]
				,"���|����: @>       �g���: @>>>>>>>>>>>>>>>>>> @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<", [$guild{$ID}{'lvl'}, "$guild{$ID}{'exp'}\/$guild{$ID}{'next_exp'}", (swrite2("(@>>>>%)",[($guild{$ID}{'exp'}/$guild{$ID}{'next_exp'} * 100)])." -".mathPercent($guild{$ID}{'exp'}, $guild{$ID}{'next_exp'}, 0, 0, 1))]
				,"�|���W��: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<", [$guild{$ID}{'master'}]
				,"���|�H��: @<<<<    ���|������������: @>",["$guild{$ID}{'conMember'}\/$guild{$ID}{'maxMember'}", $guild{$ID}{'average'}]
				,"Castle  : @<<<<<<<<<<<< offerPoint: @<<<<<<<<<<", [$guild{$ID}{'castle'}, $guild{$ID}{'offerPoint'}]
				,"@<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<", ['[�P�����|]', '[�Ĺ綠�|]']
			);

			for (my $i=0; $i<3; $i++) {
				print swrite(
					 "@<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<"
					,[$guild{$ID}{'alliance'}[$i]{'name'}, $guild{$ID}{'rival'}[$i]{'name'}]
				);
			}

			my ($w_sec, $w_hour, $w_min, $guildPerHour, $percentGH, $percentG, $EstG_sec, $EstG_hour, $EstG_min, $EstG_day) = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

			$record{'exp'}{'end'} = time;
			$w_sec = int($record{'exp'}{'end'} - $record{'exp'}{'start'});
#			$bExpPerHour = ($w_sec != 0) ? int($sc_v{'exp'}{'base'} * 3600 / $w_sec) : 0;
#			$jExpPerHour = ($w_sec != 0) ? int($sc_v{'exp'}{'job'} * 3600 / $w_sec) : 0;

			if ($w_sec > 0) {
				if($sc_v{'exp'}{'guild'}){
					$guildPerHour = int($sc_v{'exp'}{'guild'} / $w_sec * 3600);
					$percentGH = "(".sprintf("%.2f",$guildPerHour * 100 / $guild{$ID}{'next_exp'})."%)";
					$percentG = "(".sprintf("%.2f",$sc_v{'exp'}{'guild'} * 100 / $guild{$ID}{'next_exp'})."%)";
				}

				if ($w_sec >= 3600) {
					$w_hour = int($w_sec / 3600);
					$w_sec %= 3600;
				}
				if ($w_sec >= 60) {
					$w_min = int($w_sec / 60);
					$w_sec %= 60;
				}
				if ($guildPerHour){
					$EstG_sec = int(($guild{$ID}{'next_exp'} - $guild{$ID}{'exp'})/($guildPerHour/3600));
					$EstG_hour = ($EstG_sec >=3600) ? int($EstG_sec/3600):0;
					$EstG_sec %=3600;
					$EstG_min = ($EstG_sec >=60) ? int($EstG_sec/60):0;
					$EstG_sec %=60;

					if ($EstG_hour >= 24){
						$EstG_day = int($EstG_hour / 24);
						$EstG_hour %= 24;

						$EstG_day = '��' if ($EstG_day > 100);
						$EstG_day .= ' ��';
					}

					$EstG_hour = "0" . $EstG_hour if ($EstG_hour < 10);
					$EstG_min = "0" . $EstG_min if ($EstG_min < 10);
					$EstG_sec = "0" . $EstG_sec if ($EstG_sec < 10);

				}

				my $t_exp_line = ("-" x45);

				print
				  subStrLine($tmpVal{'line'},"Guild Exp Report")
				. swrite(
				  "Report  time : @# Hours @> Minutes @> Seconds"
				, [$w_hour, $w_min, $w_sec]
				, "guildExp      : @>>>>>>>>>>>>>>>>>>>> @>>>>>>>"
				, [$sc_v{'exp'}{'guild'},$percentG]
				, "guildExp/Hour : @>>>>>>>>>>>>>>>>>>>> @>>>>>>>"
				, [$guildPerHour, $percentGH]
				, "Guild Levelup Time Estimation : @>>>> @>:@>:@>"
				, [$EstG_day, $EstG_hour,$EstG_min,$EstG_sec]
				) if ($sc_v{'exp'}{'guild'});
			}

			print subStrLine($tmpVal{'line'});

			sendGuildInfoRequest(\$remote_socket);

			for (my $i = 0; $i<=4 ; $i++) {
				sendGuildRequest(\$remote_socket, $i);
			}

		} elsif (switchInput($params[1], "m", "member")) {

			$tmpVal{'line'} = "@<<<< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @>>  @>>>>>>>>>";

			print subStrLine($tmpVal{'line'}, "Guild Member", -1);

			print swrite(
				 $tmpVal{'line'}
#				,["�u�W", "�W��", "¾��", "¾�~", "����", "ú�Ǹg���"]
				,["No", "Name", "Position", "Job", "Lv", "Exp"]
			);

			for ($i = 0; $i < $guild{$ID}{'members'}; $i++) {

				print swrite($tmpVal{'line'} ,[
					  swrite("@> @<", [$i, ($guild{$ID}{'member'}[$i]{'online'}?getSex($guild{$ID}{'member'}[$i]{'sex'}, 1):"")])
					, $guild{$ID}{'member'}[$i]{'name'}
					, $guild{$ID}{'title'}[$guild{$ID}{'member'}[$i]{'title'}]
					, getName("jobs_lut", $guild{$ID}{'member'}[$i]{'jobID'}, 0, 1)
					, $guild{$ID}{'member'}[$i]{'lvl'}
					, $guild{$ID}{'member'}[$i]{'contribution'}
				]);

			}

			print subStrLine($tmpVal{'line'});
		} elsif (switchInput($params[1], "j", "join")) {
			$tmpVal{'tag'}  .= " $params[1]";
			$tmpVal{'title'} = "Accept/Deny Guild Join Request";

			if (!isBoolean($params[2])) {
				$tmpVal{'text'} = "<0=�ڵ� | 1=����>";
				$tmpVal{'type'} = 1;
			} elsif ($incomingGuild{'ID'} eq "") {
				$tmpVal{'text'} = "�L�k�����Ωڵ����|�ܽ� - �S�����|�ܽ�";
			} else {
				sendGuildJoin(\$remote_socket, $incomingGuild{'ID'}, isBoolean($params[2], 1));
				undef %incomingGuild if (!isBoolean($params[2], 1));
			}
		} elsif (switchInput($params[1], "r", "request")) {
			$tmpVal{'tag'}  .= " $params[1]";
			$tmpVal{'title'} = "Request to Join Guild";

			if ($playersID[$params[2]] eq "") {
				$tmpVal{'text'} = "�L�k�ܽХ[�J�u�| - ���ܽЪ��a $params[2] ���s�b";
			} else {
				sendGuildJoinRequest(\$remote_socket, $playersID[$params[2]]);
			}
		} elsif (switchInput($params[1], "p", "pos", "positions")) {
#			$tmpVal{'line'} = "@<<<< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @>>  @>>>>>>>>>";
			$tmpVal{'line'} = "@>> @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>> @>>> @>>>>>>";

			print subStrLine($tmpVal{'line'}, "Guild Positions", -1);

			print swrite(
				 $tmpVal{'line'}
				,["No", "Position Name", "Join", "Kick", "EXP"]
			);

			foreach (sort sortNum keys %{$guild{$ID}{'positions'}}) {

				print swrite($tmpVal{'line'} ,[
					  $_
					, $guild{$ID}{'positions'}{$_}{'name'}
					, $guild{$ID}{'positions'}{$_}{'join'}
					, $guild{$ID}{'positions'}{$_}{'kick'}
					, $guild{$ID}{'positions'}{$_}{'feeEXP'}
				]);

			}

			print subStrLine($tmpVal{'line'});
		} elsif (switchInput($params[1], "s", "skills")) {
#			$tmpVal{'line'} = "----------------------------------------------";
#			$tmpVal{'line'} = "#   �W��                          Lv";
			$tmpVal{'line'} = "@>> @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>> ";

			print subStrLine($tmpVal{'line'}, "Guild Skills", -1);

			print swrite(
				 $tmpVal{'line'}
				,["No", "Skill Name", "Lv"]
			);

			foreach (sort sortNum keys %{$guild{$ID}{'skills'}}) {

				print swrite($tmpVal{'line'} ,[
					  $_
					, getName("skills_lut", $guild{$ID}{'skills'}{$_}{'nameID'}, 0, 1)
					, $guild{$ID}{'skills'}{$_}{'lv'}
				]);

			}

			print subStrLine($tmpVal{'line'});
		} elsif (switchInput($params[1], "leave")) {
			sendGuildLeave(\$remote_socket, $chars[$config{'char'}]{'guild'}{'ID'}, $accountID, $sc_v{'input'}{'charID'}, $params[2]);
		} elsif (switchInput($params[1], "n", "notice")) {

			my $address = $guild{$ID}{'address'};
			my $message = $guild{$ID}{'message'};

			print	subStrLine(0,"$chars[$config{'char'}]{'guild'}{'name'} : Guild Notice")
				.($address?" $address\n":"")
				.($message?" $message\n":"")
				.subStrLine();
		} elsif (switchInput($params[1], "u", "user", "users")) {
			$tmpVal{'line'} = "@>> @>>> @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<";

			print subStrLine(0, "Guild In Map", -1);
			print swrite($tmpVal{'line'}, ["No", "Here", "Name.", "Coordinate"]);

			$tmpVal{'idx'} = 0;

			foreach (keys %{$chars[$config{'char'}]{'guild'}{'users'}}) {
				next if ($chars[$config{'char'}]{'guild'}{'users'}{$_}{'ID'} eq "");

				print swrite($tmpVal{'line'}, [$tmpVal{'idx'}++, ($chars[$config{'char'}]{'guild'}{'users'}{$_}{'onhere'}?"��":""), "[".unpack("L1", $chars[$config{'char'}]{'guild'}{'users'}{$_}{'ID'})."] ".getName("player", $chars[$config{'char'}]{'guild'}{'users'}{$_}{'ID'}, 0, -1), posToCoordinate(\%{$chars[$config{'char'}]{'guild'}{'users'}{$_}{'pos'}}, 1)]);
			}
			print subStrLine();
		}

		printErr($tmpVal{'tag'}, $tmpVal{'title'}, $tmpVal{'text'}, $tmpVal{'type'});

	# Log command outputs
	} elsif ($switch eq "log") {
		($arg1) = $input =~ /^[\s\S]*? "([\s\S]*?)"/;
		($arg2) = $input =~ /^[\s\S]*? "[\s\S]*?" (\w+)/;
		$arg2 = "CmdLog" if ($arg2 eq "");
		if ($arg1 ne "") {
			print "�N���O \'$arg1\' ����X���G�g�J $sc_v{'path'}{'def_logs'}"."$arg2.txt\n";
			logCommand(">> $sc_v{'path'}{'def_logs'}"."$arg2.txt", $arg1);
		} else {
			print	"�y�k���~ 'log' (Log Command)\n"
				,qq~�ϥΤ�k: log "<���O>" [<��X�ɦW>]\n~;
		}

	# Pet related
	} elsif ($switch eq "pet") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		$~ = "PETSTATUS";
		if ($arg1 ne "catch" && $chars[$config{'char'}]{'pet'}{'online'}) {
			if ($arg1 eq ""){
				$modify_string       = ($chars[$config{'char'}]{'pet'}{'modified'}) ? "�w�R�W" : "���R�W";
				$feed_string         = ($config{'petAuto_feed'}) ? "<".sprintf("%4s", $config{'petAuto_feed'}) : "   �L";
				$return_string       = ($config{'petAuto_return'}) ? ">".sprintf("%4s", $config{'petAuto_return'}) : "   �L";
				$protect_string      = ($config{'petAuto_protect'}) ? "   ��" : "  �L";
				$temp1 = "�۰ʦ��^";
				$temp2 = "�˹��~";
				$temp3 = "�۰ʫO�@";
				print "------------------ �d����T ------------------\n";
				format PETSTATUS =
�m  �W: @<<<<<<<<<<<<<<<<<<<<<<�R  �W:  @<<<<<
        $chars[$config{'char'}]{'pet'}{'name_given'}, $modify_string
��  ��: @<<<<<<<<<<<<<<<       ��  ��:  @>>>>>
        $chars[$config{'char'}]{'pet'}{'name'}, $chars[$config{'char'}]{'pet'}{'lvl'}

�����P: @>>>/100               �۰�����: @>>>>
        $chars[$config{'char'}]{'pet'}{'hunger'}, $feed_string
�˱K��: @>>>/1000              @>>>>>>>: @>>>>
        $chars[$config{'char'}]{'pet'}{'intimate'}, $temp1, $return_string
@>>>>>: @<<<<<<<<<<<<<<<<<<<<<<@>>>>>>>: @>>>>
$temp2, $items_lut{$chars[$config{'char'}]{'pet'}{'accessory'}}, $temp3, $protect_string
.
				write;
				print "----------------------------------------------\n";
			} elsif ($arg1 eq "feed") {
				sendPetCommand(\$remote_socket, 1);
			} elsif ($arg1 eq "show") {
				sendPetCommand(\$remote_socket, 2);
			} elsif ($arg1 eq "return") {
				sendPetCommand(\$remote_socket, 3);
				print "�A�N�d���^�_���J�����A\n";
			} elsif ($arg1 eq "uneq") {
				sendPetCommand(\$remote_socket, 4);
			} elsif ($arg1 eq "eq" && !%{$chars[$config{'char'}]{'inventory'}[$arg2]}) {
				print	"�o�Ϳ��~ 'pet eq' (Equip Pet Accessory)\n"
					, "���˳ƪ��~ $arg2 ���s�b.\n";
			} elsif ($arg1 eq "eq") {
				sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, 0);
			} else {
				print "�y�k���~ 'pet' (Pet Functions)\n"
					, "�ϥΤ�k: pet [<feed | show | eq | uneq | return>] [<�d���˹��~�s��>]\n";
			}
		} elsif ($arg1 eq "catch" && $arg2 eq "") {
			print	"�y�k���~ 'pet catch' (Catch Pet)\n"
				, "�ϥΤ�k: pet catch <�Ǫ��s��>\n";
		} elsif ($arg1 eq "catch" && $monstersID[$arg2] eq "") {
			print	"�o�Ϳ��~ 'pet catch' (Catch Pet)\n"
				, "�Ǫ� $arg2 ���s�b.\n";
		} elsif ($arg1 eq "catch") {
			sendPetCatch(\$remote_socket, $monstersID[$arg2]);

		} else {
			print	"�o�Ϳ��~ 'pet' (Pet Functions)\n"
				, "�Х���J 'is <��a�ι�J���s��>' ����d��.\n";
		}

	# Pet call
	} elsif ($switch eq "call") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			$~ = "CALL";
			print "-------------- �i����d���J�M�� --------------\n";
			print "#   �W��                                      \n";
			for ($i = 0; $i < @callID; $i++) {
				next if ($callID[$i] eq "");
				format CALL =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $chars[$config{'char'}]{'inventory'}[$callID[$i]]{'name'}
.
				write;
			}
			print "----------------------------------------------\n";
			print "�п�J 'call <�i����d���J�s��>' ���\n";

		} elsif ($arg1 =~ /^\d+$/ && $callID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'call' (Call Pet)\n"
				, "������d���J $arg1 ���s�b.\n";

		} elsif ($arg1 =~ /^\d+$/) {
			undef $callInvIndex;
			$callInvIndex = $callID[$arg1];
			sendPetCall(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$callID[$arg1]]{'index'});
		} else {
			print	"�y�k���~ 'call' (Call Pet)\n"
				, "�ϥΤ�k: call [<�i����d���J�s��>]\n";
		}

	# Vendor related
	} elsif ($switch eq "shop") {
		($arg1) = $input =~ /^[\s\S]*? ([\w\d]+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "" && !$shop{'opened'}) {
			print	"�o�Ϳ��~ 'shop' (Browse Vending Shop)\n"
				, "�Х���J 'shop open' �\\�]�A���u��.\n";
		} elsif ($arg1 eq "") {
			$~ = "VENDORTITLE";
			$title_string = (length($myShop{'shop_title'}) > 36) ? substr($myShop{'shop_title'}, 0, 36) : $myShop{'shop_title'};
			$owner_string = $chars[$config{'char'}]{'name'};
			print "---------------------------------- �ڪ��ө� ----------------------------------\n";
			format VENDORTITLE =
�ө��W��: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< �֦���: @<<<<<<<<<<<<<<<<<<<<<<
          $title_string, $owner_string

.
			write;
			print "#   �W��                                       ����      �ƶq  ��  �B(Z)  ��X\n";
			$~ = "ARTICLESREMAINLIST";
			for ($i = 0; $i < @articles; $i++) {
				next if (!%{$articles[$i]});
				$price_string = toZeny($articles[$i]{'price'});
				format ARTICLESREMAINLIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @>>>> @>>>>>>>>> @>>>>
$i, $articles[$i]{'name'}, $itemTypes_lut{$articles[$i]{'type'}}, $articles[$i]{'amount'}, $price_string, $articles[$i]{'sold'}
.
				write;
			}
			print "------------------------------------------------------------------------------\n";
			print "�p�p: �ثe�ȶi ".toZeny($shop{'earned'})." Zeny\n" if ($shop{'earned'});

		} elsif ($arg1 eq "close" && !$shop{'opened'}) {
			print	"�o�Ϳ��~ 'shop close' (Close Vending Shop)\n"
				, "�Х���J 'shop open' �\\�]�A���u��.\n";
		} elsif ($arg1 eq "close") {

			event_shop_close();

		} elsif ($arg1 eq "open" && $currentChatRoom ne "") {
			print	"�o�Ϳ��~ 'shop open' (Open Vending Shop)\n"
				, "�A���������}��ѫ�.\n";
		} elsif ($arg1 eq "open" && $shop{'opened'}) {
				print	"�o�Ϳ��~ 'shop open' (Open Vending Shop)\n"
					, "�A�w�g�\\�]�n�@���u��F.\n";
		} elsif ($arg1 eq "open") {

			unshift @ai_seq, "shopauto";
			unshift @ai_seq_args, {};

#			if ($chars[$config{'char'}]{'sitting'}) {
#				stand();
#				print "�к������߫��դ@�|��A��J 'shop open' ���O, �H�K�ް_�h��\n";
#
#				ai_event_auto_parseInput("shop open");
#			} else {
				sendShopOpen(\$remote_socket);
#			}

		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/ && $shop{'opened'}) {
			if (!%{$articles[$arg2]}) {
				print	"�o�Ϳ��~ 'shop desc' (Vending Shop Item Description)\n"
					, "���˵��u�쪫�~ $arg2 ���s�b.\n";
			} else {
				printDesc(0, $articles[$arg2]{'itemID'}, fixingName(\%{$articles[$arg2]}));
			}
		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/ && $currentVendingShop ne "") {
			if (!%{$vendorItemList[$arg2]}) {
				print	"�o�Ϳ��~ 'shop desc' (Vending Shop Item Description)\n"
					, "���˵��u�쪫�~ $arg2 ���s�b.\n";
			} else {
				printDesc(0, $vendorItemList[$arg2]{'itemID'}, fixingName(\%{$vendorItemList[$arg2]}));
			}
		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/) {
			print	"�o�Ϳ��~ 'shop desc' (Vending Shop Item Description)\n"
				, "���˵��u�쪫�~ $arg2 ���s�b.\n";

		} elsif ($arg1 =~ /^\d+$/ && $vendorListID[$arg1] ne "" && $shop{'opened'}) {
			print	"�o�Ϳ��~ 'shop' (Browse Vending Shop)\n"
				, "�\\�u���ɭԥ����M��, ���M�i��|�Q����o�Ͼ�.\n";
		} elsif ($arg1 =~ /^\d+$/ && $vendorListID[$arg1] eq "") {
			print	"�o�Ϳ��~ 'shop' (Browse Vending Shop)\n"
				, "���s���u�� $arg1 ���s�b.\n";
		} elsif ($arg1 =~ /^\d+$/) {
			sendGetShopList(\$remote_socket, $vendorListID[$arg1]);

		} else {
			print "�y�k���~ 'shop' (Vending Shop Functions)\n"
				, "�ϥΤ�k: shop [<�u��s�� | open | close | desc>] [<�u�쪫�~�s��>]\n";
		}

	} elsif ($switch eq "pick") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			print	"�y�k���~ 'pick' (Pick Vending Shop Item)\n"
				, "�ϥΤ�k: pick <�u�쪫�~�s��> [<�ƶq>]\n";
		} elsif ($currentVendingShop eq "") {
			print	"�o�Ϳ��~ 'pick' (Pick Vending Shop Item)\n"
				, "�|���s���u��, ��J 'vsl' �i�d���u��C��.\n";
		} elsif ($vendorItemList[$arg1] eq "") {
			print	"�o�Ϳ��~ 'pick' (Pick Vending Shop Item)\n"
				, "���D�磌�~ $arg1 ���s�b.\n";
		} else {
			$arg2 = ($arg2 <= 0) ? 1 : $arg2;
			print "�A�D��F: $vendorItemList[$arg1]{'name'} x $arg2 (from $vendorList{$currentVendingShop}{'title'})\n";
			sendBuyFromShop(\$remote_socket, $currentVendingShop, $arg2, $arg1);
		}

	} elsif ($switch eq "vsl") {
		$~ = "VENDORLIST";
		print "---------------------------------- �u��C�� ----------------------------------\n";
		print "#   ���D                                  �֦���                              \n";
		for ($i = 0; $i < @vendorListID; $i++) {
			next if ($vendorListID[$i] eq "");
			$owner_string = ($vendorListID[$i] ne $accountID) ? $players{$vendorListID[$i]}{'name'} : $chars[$config{'char'}]{'name'};
			format VENDORLIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<<
$i, $vendorList{$vendorListID[$i]}{'title'}, $owner_string
.
			write;
		}
		print "------------------------------------------------------------------------------\n";
		print "�п�J 'shop <�u��s��>' �s���c�檫�~\n";

	# Locational Skill List
	} elsif ($switch eq "sl") {
		$~ = "SLIST";
		$mycoords = getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
		print "--------------------- �a�����򫬧ޯ�C�� --------$mycoords----\n";
		print "���� �W��          �I�N��                         �y   �� �Z��\n";
		for ($i = 0; $i < @spellsID; $i++) {
			next if ($spellsID[$i] eq "");
			$slcoords = getFormattedCoords($spells{$spellsID[$i]}{'pos'}{'x'}, $spells{$spellsID[$i]}{'pos'}{'y'});
			$dSDist = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$spells{$spellsID[$i]}{'pos'}}));
			if (%{$monsters{$spells{$spellsID[$i]}{'sourceID'}}}) {
				$name_string = "$monsters{$spells{$spellsID[$i]}{'sourceID'}}{'name'} ($monsters{$spells{$spellsID[$i]}{'sourceID'}}{'binID'})";
			} elsif (%{$players{$spells{$spellsID[$i]}{'sourceID'}}}) {
				$name_string = "$players{$spells{$spellsID[$i]}{'sourceID'}}{'name'} ($players{$spells{$spellsID[$i]}{'sourceID'}}{'binID'})";
			} elsif ($spells{$spellsID[$i]}{'sourceID'} eq $accountID) {
				$name_string = "�A";
			} else {
				$name_string = "�����H��";
			}
			format SLIST =
@<<  @<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<< @>>
$spells{$spellsID[$i]}{'type'}, $messages_lut{'011F'}{$spells{$spellsID[$i]}{'type'}}, $name_string, $slcoords, $dSDist
.
			write if ($spells{$spellsID[$i]}{'type'});
		}
		print "--------------------------------------------------------------\n";
#Karasu End

	} elsif ($switch =~ /^\d$/) {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($switch eq "5") {
			if ($arg1 eq "") {
				my $z = ($config{'handyMove_step'} < 10) ? " $config{'handyMove_step'}" : $config{'handyMove_step'};
				print "-------------- �B�~���� --------------\n";
				print "  ��  ��  ��  ��  �ϥΤ�k:           \n";
				print "  �r    ������      �̷ӷQ�e�i����V��\n";
				print "  �L  ����  ����    �J '�Ʀr [<���>]'\n";
				print "  �G    ������      �p�����w��Ʀ۰ʥH\n";
				print "      ��  ��  ��    �򥻨B��($z)�N�J�C\n";
				print "--------------------------------------\n";
				print "��J '5 <���>' �i�]�w�򥻨B��        \n";

			} else {
#				configModify($config{'handyMove_step'}, $arg1);
				scModify("config", "handyMove_step", $arg1, 2);
			}
		} elsif ($switch eq "6") {
			handyMove("�F", $arg1);
		} elsif ($switch eq "4") {
			handyMove("��", $arg1);
		} elsif ($switch eq "2") {
			handyMove("�n", $arg1);
		} elsif ($switch eq "8") {
			handyMove("�_", $arg1);
		} elsif ($switch eq "9") {
			handyMove("�F�_", $arg1);
		} elsif ($switch eq "7") {
			handyMove("��_", $arg1);
		} elsif ($switch eq "3") {
			handyMove("�F�n", $arg1);
		} elsif ($switch eq "1") {
			handyMove("��n", $arg1);
		}

	} elsif ($switch eq "beep") {
		if ($params[1] eq "stop" && $playingWave ne "") {
			playWave("stop", "100%", "test");
		} elsif ($params[1] eq "stop" && $playingWave eq "") {
			print "�o�Ϳ��~ 'beep stop' (Stop Beep)\n"
				, "�ثe�S��������󭵮�.\n";
#		} elsif ($arg1 eq "deal") {
#			playWave("sounds/Deal.wav", "test");
#		} elsif ($arg1 eq "death") {
#			playWave("sounds/Death.wav", "test");
#		} elsif ($arg1 eq "gm") {
#			playWave("sounds/GM.wav", "test");
#		} elsif ($arg1 eq "guest") {
#			playWave("sounds/Guest.wav", "test");
#		} elsif ($arg1 eq "iif") {
#			playWave("sounds/iItemsFound.wav", "test");
#		} elsif ($arg1 eq "iig") {
#			playWave("sounds/iItemsGot.wav", "test");
#		} elsif ($arg1 eq "c") {
#			playWave("sounds/C.wav", "test");
#		} elsif ($arg1 eq "g") {
#			playWave("sounds/G.wav", "test");
#		} elsif ($arg1 eq "p") {
#			playWave("sounds/P.wav", "test");
#		} elsif ($arg1 eq "pm") {
#			playWave("sounds/PM.wav", "test");
#		} elsif ($arg1 eq "s") {
#			playWave("sounds/S.wav", "test");
		} elsif (event_beep($params[1], "test")) {

		} else {
			print	"�y�k���~ 'beep' (Beep Functions)\n"
				, "�ϥΤ�k: beep <death | gm | iif | iig | c | g | p | pm | s | stop>\n";
		}
#beep End - Ayon 20030530

	} elsif ($switch eq "warp") {
		if ($chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'} > 0 || $chars[$config{'char'}]{'skills'}{'AL_TELEPORT'}{'lv'} > 0) {
			if (switchInput($params[1], "", "list")){
				if(@{$warp{'memo'}} && $warp{'use'}){
					my $tmp = "@>> @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<";
					my $i;

					print	 subStrLine(0, "Warp Portal ($warp{'use'})", -1)
						.swrite($tmp, ['No', 'Place', 'Map'])
						;

					for ($i = 0; $i < @{$warp{'memo'}}; $i++) {
						next if (!$warp{'memo'}[$i]);
						print swrite($tmp, [$i, getMapName($warp{'memo'}[$i], 1)]);
					}

					print	subStrLine();
				} else {
					FunctionError($switch, "Warp List", "Use warp skill to get list");
				}
			} elsif ($params[1] eq "me") {
				$tmpVal{'dist'} = $config{'warpPortalRandomDist'} || 6;

				undef %{$tmpVal{'pos'}};

				($tmpVal{'pos'}{'x'}, $tmpVal{'pos'}{'y'}) = posToRand(\%{$chars[$config{'char'}]{'pos_to'}}, $tmpVal{'dist'}, 1, 3);
#				sendSkillUseLoc(\$remote_socket, $chars[$config{'char'}]{'skills'}{'AL_WARP'}{'ID'}, $chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'}, $tmpVal{'pos'}{'x'}, $tmpVal{'pos'}{'y'});

				ai_skillUse($chars[$config{'char'}]{'skills'}{'AL_WARP'}{'ID'}, $chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'}, 2, 0, $tmpVal{'pos'}{'x'}, $tmpVal{'pos'}{'y'});

#				print "[3] $tmpVal{'pos'}{'x'}, $tmpVal{'pos'}{'y'}\n";

				$sc_v{'ai'}{'warpTo'}{'x'} = $tmpVal{'pos'}{'x'};
				$sc_v{'ai'}{'warpTo'}{'y'} = $tmpVal{'pos'}{'y'};

				if ($params[2]){
					sleep(0.5);
					$params[2]-- if (isNum($params[2]) && $params[2] > 0);
					parseInput("warp $params[2]");
				}
			} elsif ($params[1] eq "no") {
				$warp{'use'} = 0;
			} elsif (switchInput($params[1], "at") && isNum($params[2]) && isNum($params[3])) {
#				ai_skillUse(27, $chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'}, 2, 0, 0, $params[2], $params[3]);

				ai_skillUse($chars[$config{'char'}]{'skills'}{'AL_WARP'}{'ID'}, $chars[$config{'char'}]{'skills'}{'AL_WARP'}{'lv'}, 2, 0, $params[2], $params[3]);

				$sc_v{'ai'}{'warpTo'}{'x'} = $params[2];
				$sc_v{'ai'}{'warpTo'}{'y'} = $params[3];

				if ($params[4]){
					sleep(0.5);
					$params[4]-- if (isNum($params[4]) && $params[4] > 0);
					parseInput("warp $params[4]");
				}
			} elsif ($warp{'use'} && $params[1] ne "") {
				if (isNum($params[1])){
					$tmpVal{'map'} = getMapName($warp{'memo'}[$params[1]], 1);
					if (!$warp{'memo'}[$params[1]]){
						FunctionError($switch, "Warp Command", "Memo $params[1] does not exist.");
					} elsif ($warp{'use'} == 0x1A) {
						printC("[Warp] Teleport to $tmpVal{'map'}.\n", "warp");
						sendTeleport(\$remote_socket, $warp{'memo'}[$params[1]].".gat");
					} elsif ($warp{'use'} == 0x1B) {
						printC("[Warp] Warp Portal to $tmpVal{'map'}.\n", "warp");
						sendWarpPortal(\$remote_socket, $warp{'memo'}[$params[1]].".gat");
					}
				} else {
					$params[1] = lc $params[1];
					my $tmp = binFind(\@{$warp{'memo'}}, $params[1]);
					if ($tmp){
						print "sendWarpPortal : ".getMapName($params[1], 1)."\n";
						sendWarpPortal(\$remote_socket, $warp{'memo'}[$tmp].".gat");

						$sc_v{'ai'}{'warpTo'}{'open'} = 1;

#						parseInput("move $sc_v{'ai'}{'warpTo'}{'x'} $sc_v{'ai'}{'warpTo'}{'y'}");
#						ai_clientSuspend(0, 2);
					} else {
						FunctionError($switch, "Warp Command", "You don't have a memo ".getMapName($params[1], 1));
					}
				}
			} else {
				SyntaxError($switch, "Warp Command", "< me [<memo #> | <target map>] | at <x> <y> [<memo #> | <target map>] | no | <memo #> | <map> >");
			}
		} else {
			FunctionError($switch, "Warp Command", "You don't have a warp skill.");
		}

	} elsif (switchInput($switch, "fl", "friend", "friends")) {

		if (!@{$sc_v{'friend'}{'member'}}) {

				FunctionError($switch, "Friend Command", "You don't have friend list.");

		} elsif (switchInput($params[1], "", "list")){

			my $line = "";
			my $text = subStrLine(0, "Friend List");
			my $c;

			$text .= " No    Name.\n";

			for (my $i=0; $i<@{$sc_v{'friend'}{'member'}}; $i++) {
				$c = $charID_lut{$sc_v{'friend'}{'member'}[$i]{'AID'}}{'online'}?"��":"";

				$text .= swrite2("@>> @>", [$i, $c])." $sc_v{'friend'}{'member'}[$i]{'name'}\n";

			}

			$text .= subStrLine(0);

			print $text;

		} elsif (isNum($params[1]) && $params[2] ne "") {
			if ($sc_v{'friend'}{'member'}[$params[1]]{'name'} eq "") {
				FunctionError($switch, "Private Message To Frineds", "���a $params[1] ���b�A���B�ͦW�椤");
			} else {
				$sc_v{'pm'}{'lastTo'} = $sc_v{'friend'}{'member'}[$params[1]]{'name'};
				$sc_v{'pm'}{'lastMsg'} = $params[2];
				sendMessage(\$remote_socket, "pm", $params[2], $sc_v{'friend'}{'member'}[$params[1]]{'name'});
			}
		} else {
			SyntaxError($switch, "Friend Command", "<list>");
		}

	} elsif ($switch eq "organize") {

		parseInput('party create "'.$params[1].'"');

	} elsif ($switch eq "lock") {

		printC("Lock Mode\n", "s");

		$sc_v{'kore'}{'lock'} = 1;

	} elsif ($switch eq "mvp") {

		my $line = " @<<<<<<";
		my $text = subStrLine(0, "MVP List");
		my $c;

#		$text .= " Type    Name.\n";

		$text .= "Date: ".getFormattedDate(int(time))."\n";

		foreach $mvpKey (keys %{$record{'mvp'}}) {

			$text .= getName("mon", $mvpKey)."\n";
#			$text .= "\t\tdmgTo	: $record{'mvp'}{$mvpKey}{'dmgTo'}\n" if ($record{'mvp'}{$mvpKey}{'dmgTo'});
#			$text .= "\t\tdmgFrom	: $record{'mvp'}{$mvpKey}{'dmgFrom'}\n" if ($record{'mvp'}{$mvpKey}{'dmgFrom'});

			foreach (sort keys %{$record{'mvp'}{$mvpKey}}) {

				$text .= swrite2("\t@<<<<<<", [$_])." - [".getFormattedDate(int($record{'mvp'}{$mvpKey}{$_}{'time'}))."]\n";
				$text .= "\t\t$record{'mvp'}{$mvpKey}{$_}{'map'}\n";

			}

		}

		$text .= subStrLine(0);

		printC($text, "mvp");

	} elsif ($switch eq "msg") {
		my (@chat, $i, $idx);
		my $chatfile;

		$chatfile = getLogFile($params[1], 1);

		open(CHAT, "$chatfile") or printC("Unable to open file: ".getLogFile($params[1]).". \n", "alert");
		@chat = <CHAT>;
		close(CHAT);

		if (@chat) {

			if (isNum($params[2]) && $params[2] > 0) {
				$idx = int($params[2]);
			} else {
				$idx = 5;
			}

			$idx = @chat if ($idx > @chat);

			print subStrLine(0, "Message History ($idx) - ".getFormattedDate(int(time)));

			for ($i = @chat - $idx; $i < @chat;$i++) {
				print $chat[$i];
			}

			print subStrLine();

		}

	} elsif ($switch eq "remain") {
		my ($Remain, $endTime_EXP, $w_hour, $w_min, $w_sec, $r_day, $r_hour, $r_min, $r_sec);

		$endTime_EXP = time;
		$w_sec = int($endTime_EXP - $sc_v{'kore'}{'startTime'});

		$w_hour = $w_min = 0;

		if ($w_sec >= 3600) {
			$w_hour = int($w_sec / 3600);
			$w_sec %= 3600;
		}
		if ($w_sec >= 60) {
			$w_min = int($w_sec / 60);
			$w_sec %= 60;
		}

		$Remain = int(($chars[$config{'char'}]{'Airtime'}{'day'} *86400) + ($chars[$config{'char'}]{'Airtime'}{'hour'} * 3600) + ($chars[$config{'char'}]{'Airtime'}{'minute'} * 60));
		$r_sec = int($Remain - $w_sec);
		$r_day = $r_hour = $r_min = 0;

		if ($r_sec >= 86400) {
			$r_day = int($r_sec / 86400);
			$r_sec %= 86400;
		}
		if ($r_sec >= 3600) {
			$r_hour = int($r_sec / 3600);
			$r_sec %= 3600;
		}
		if ($r_sec >= 60) {
			$r_min = int($r_sec / 60);
			$r_sec %= 60;
		}

		my $line = "Now Remain : 00 Days 00 Hours 00 Minutes 33 Seconds";

		print subStrLine($line, "Airtime Remaining");
		#print sprintf("Day: %-3d Hour: %-3d Minutes: %-3d\n",$chars[$config{'char'}]{'Airtime'}{'day'},$chars[$config{'char'}]{'Airtime'}{'hour'},$chars[$config{'char'}]{'Airtime'}{'minute'});
		print sprintf("Login at: %-30s\n", $chars[$config{'char'}]{'Airtime'}{'loginat'});
		print "Botting time : $w_hour Hours $w_min Minutes $w_sec Seconds\n";
		print "Now Remain : $r_day Days $r_hour Hours $r_min Minutes $r_sec Seconds\n";
		print subStrLine($line);

	} elsif (switchInput($switch, "version", "ver")){

		printC("$sc_v{'versionText'}\n", "version");

	} elsif ($switch eq "heal") {
		if ($chars[$config{'char'}]{'skills'}{'AL_HEAL'}{'lv'} eq "") {

		} else {
			if ($playersID[$params[1]]) {
				$params[1] = $playersID[$params[1]];
				$params[2] = 3000 if (!$params[2])
			} elsif (switchInput($params[1], "me")) {
				$params[1] = $accountID;
			} else {
				$params[2] = $params[1];
				$params[1] = $accountID;
			}
			ai_skillUse($chars[$config{'char'}]{'skills'}{"AL_HEAL"}{'ID'}, ai_smartHeal(1, $params[2], 1), 0, 0, $params[1], "");
		}

	} elsif (switchInput($switch, "date", "now")) {
		printC("Date: ".getFormattedDate(int(time))."\n", "s");
#	} elsif (switchInput($switch, "sense")) {
#
#		$tmpVal{'line'} = "@<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<";
#
#		print swrite(
#			$tmpVal{'line'}, [getName("mon", $sc_v{'sense'}{'nameID'}), "size: $sc_v{'sense'}{'size'}"]
#			, $tmpVal{'line'}, ["level: $sc_v{'sense'}{'level'}", "size: $sc_v{'sense'}{'size'}"]
#
#		);

	} else {
		print "���~�����O : $switch \n";
	}

END_IPPUT:
	undef %tmpVal, @params;
}

1;