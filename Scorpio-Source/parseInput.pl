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
				$tmpVal{'text'} = "怪物 $params[1] 不存在";
			} else {
				attack($monstersID[$params[1]]);
			}

		} elsif (switchInput($params[1], "no", "n")) {

			scModify("config", "attackAuto", 1, 1);

		} elsif (switchInput($params[1], "yes", "y")) {

			scModify("config", "attackAuto", 2, 1);

		} else {
			$tmpVal{'text'} = "<怪物編號 | no | yes>";
			$tmpVal{'type'} = 1;
		}

		printErr('attack', 'Attack Monster', $tmpVal{'text'}, $tmpVal{'type'});

	} elsif ($switch eq "auth") {

		if ($params[1] eq "" || ($params[2] ne "1" && $params[2] ne "0")) {

			printErr('auth', 'Overall Authorize', "<玩家名稱> <0=關 | 1=開>", 1);

		} else {
			auth($params[1], $params[2]);
		}

	} elsif ($switch eq "bestow") {

		if ($currentChatRoom eq "") {
			$tmpVal{'text'} = "你不在聊天室裡";
		} elsif (!isNum($params[1])) {
			$tmpVal{'text'} = "<玩家編號>";
			$tmpVal{'type'} = 1;
		} elsif ($currentChatRoomUsers[$params[1]] eq "") {
			$tmpVal{'text'} = "欲托付玩家 $arg1 不存在";
		} else {
			sendChatRoomBestow(\$remote_socket, $currentChatRoomUsers[$params[1]]);
		}

		printErr($switch, 'Bestow Admin in Chat', $tmpVal{'text'}, $tmpVal{'type'});

	} elsif ($switch eq "buy") {

		if ($params[1] eq "" && $talk{'buyOrSell'}) {
			sendGetStoreList(\$remote_socket, $talk{'ID'});
		} elsif ($params[1] eq "") {
			$tmpVal{'text'} = "<商店物品編號> [<數量>]";
			$tmpVal{'type'} = 1;
		} elsif ($storeList[$params[1]] eq "") {
			$tmpVal{'text'} = "欲購買物品 $params[1] 不存在";
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

			printErr($switch, $tmpVal{'title'}, "<訊息>", 1);
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
			$tmpVal{'text'} = "在沒有手推車的狀態下無法使用手推車相關指令";

		} elsif (switchInput($params[1], "", "eq", "u", "nu", "card", "arrow")) {

			$tmpVal{'cart'} = "Capacity: " . int($cart{'items'}) . "/" . int($cart{'items_max'}) . "  Weight: " . int($cart{'weight'}) . "/" . int($cart{'weight_max'}) . mathPercent($cart{'weight'}, $cart{'weight_max'}, 0, "(%.2f%)");
			getItemList(\@{$cart{'inventory'}}, $params[1], "Cart", $tmpVal{'cart'});

		} elsif (switchInput($params[1], "add")) {

			$tmpVal{'tag'} .= " $params[1]";
			$tmpVal{'title'} = "Add Item to Cart";

			if (isNum($params[2])) {

				if (!%{$chars[$config{'char'}]{'inventory'}[$params[2]]}) {
					$tmpVal{'text'} = "欲放入物品 $params[2] 不存在";
				} else {
					if (!$params[3] || $params[3] > $chars[$config{'char'}]{'inventory'}[$params[2]]{'amount'}) {
						$params[3] = $chars[$config{'char'}]{'inventory'}[$params[2]]{'amount'};
					}
					sendCartAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[2]]{'index'}, $params[3]);
				}

			} else {
				$tmpVal{'text'} = "<物品編號> [<數量>]";
				$tmpVal{'type'} = 1;
			}

		} elsif (switchInput($params[1], "get")) {

			$tmpVal{'tag'} .= " $params[1]";
			$tmpVal{'title'} = "Get Item from Cart";

			if (isNum($params[2])) {

				if (!%{$cart{'inventory'}[$params[2]]}) {
					$tmpVal{'text'} = "欲取出物品 $params[2] 不存在";
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
				$tmpVal{'text'} = "<手推車物品編號> [<數量>] [<storage>]";
				$tmpVal{'type'} = 1;
			}

		} elsif (switchInput($params[1], "desc")) {

			$tmpVal{'tag'} .= " $params[1]";
			$tmpVal{'title'} = "Cart Item Description";

			if (isNum($params[2])) {

				if (!%{$cart{'inventory'}[$params[2]]}) {
					$tmpVal{'text'} = "欲檢視物品 $params[2] 不存在";
				} else {
					printDesc(0, $cart{'inventory'}[$params[2]]{'nameID'}, fixingName(\%{$cart{'inventory'}[$arg2]}));
				}

			} else {
				$tmpVal{'text'} = "<手推車物品編號>";
				$tmpVal{'type'} = 1;
			}

		} else {
			$tmpVal{'title'} = "Cart Items List";
			$tmpVal{'text'} = "[<u | eq | nu | desc>] [<手推車物品編號>]";
			$tmpVal{'type'} = 1;
		}

		printErr($tmpVal{'tag'}, $tmpVal{'title'}, $tmpVal{'text'}, $tmpVal{'type'});

	} elsif ($switch eq "chat") {
		($replace, $title) = $input =~ /(^[\s\S]*? \"([\s\S]*?)\" ?)/;
		$qm = quotemeta $replace;
		$input =~ s/$qm//;
		@arg = split / /, $input;
		if ($title eq "") {
			print	"語法錯誤 'chat' (Create Chat Room)\n"
				,qq~使用方法: chat "<標題>" [<人數上限> <0=私人> <密碼>]\n~;
		} elsif ($currentChatRoom ne "") {
			print	"發生錯誤 'chat' (Create Chat Room)\n"
				, "你已經在聊天室裡了.\n";
		} elsif ($shop{'opened'}) {
			print	"發生錯誤 'chat' (Create Chat Room)\n"
				, "擺\攤的時候必須專心, 不然可能會被順手牽羊噢.\n";
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
			print	"語法錯誤 'chatmod' (Modify Chat Room)\n"
				,qq~使用方法: chatmod "<標題>" [<人數上限> <0=私人> <密碼>]\n~;
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
#			print	"語法錯誤 'conf' (Config Modify)\n"
#				, "使用方法: conf <變數名稱> [<數值 | value>]\n";
#		} elsif (binFind(\@{$ai_v{'temp'}{'conf'}}, $arg1) eq "") {
#			print "發生錯誤 'conf' (Config Modify)\n"
#				, "你想設定的變數 $arg1 不存在.\n";
#		} elsif ($arg2 eq "value") {
#			print "$arg1 目前的值為 $config{$arg1}\n";
#		} else {
#			configModify($arg1, $arg2);
#		}

	} elsif ($switch eq "cri") {
		if ($currentChatRoom eq "") {
			print "發生錯誤 'cri' (Chat Room Information)\n"
				, "尚未進入聊天室, 輸入 'crl' 可查看聊天室列表.\n";
		} else {
			$~ = "CRI";
			print "----------------- 聊天室資訊 -----------------\n";
			$public_string = ($chatRooms{$currentChatRoom}{'public'}) ? "公" : "私";
			format CRI =
@< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<(@>/@>)
$public_string, $chatRooms{$currentChatRoom}{'title'}, $chatRooms{$currentChatRoom}{'num_users'}, $chatRooms{$currentChatRoom}{'limit'}
.
            write;
			print "----------------------------------------------\n";
			$~ = "CRIUSERS";
			print "#   名稱\n";
			for ($i = 0; $i < @currentChatRoomUsers; $i++) {
				next if ($currentChatRoomUsers[$i] eq "");
				$user_string = $currentChatRoomUsers[$i];
				$admin_string = ($chatRooms{$currentChatRoom}{'users'}{$currentChatRoomUsers[$i]} > 1) ? "(擁有者)" : "";
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
		print "--------------------------------- 聊天室列表 ---------------------------------\n";
		print "#   標題                                  擁有者                  人 數  公/私\n";
		for ($i = 0; $i < @chatRoomsID; $i++) {
			next if ($chatRoomsID[$i] eq "");
			$owner_string = ($chatRooms{$chatRoomsID[$i]}{'ownerID'} ne $accountID) ? $players{$chatRooms{$chatRoomsID[$i]}{'ownerID'}}{'name'} : $chars[$config{'char'}]{'name'};
			$public_string = ($chatRooms{$chatRoomsID[$i]}{'public'}) ? "Ｖ   " : "   Ｖ";
			format CRLIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @<<<<<<<<<<<<<<<<<<<<<< @>/@>  @<<<<
$i, $chatRooms{$chatRoomsID[$i]}{'title'}, $owner_string, $chatRooms{$chatRoomsID[$i]}{'num_users'}, $chatRooms{$chatRoomsID[$i]}{'limit'}, $public_string
.
			write;
		}
		print "------------------------------------------------------------------------------\n";
		print "請輸入 'join <聊天室編號> [<密碼>]' 進入聊天室\n";

	} elsif ($switch eq "deal") {
		@arg = split / /, $input;
		shift @arg;
		if (%currentDeal && $arg[0] =~ /^\d+$/) {
			print	"發生錯誤 'deal' (Deal a Player)\n"
				, "你已經在交易中.\n";
		} elsif (%incomingDeal && $arg[0] =~ /^\d+$/) {
			print	"發生錯誤 'deal' (Deal a Player)\n"
				, "你必須先終止進行中的交易.\n";
		} elsif ($arg[0] =~ /^\d+$/ && $playersID[$arg[0]] eq "") {
			print	"發生錯誤 'deal' (Deal a Player)\n"
				, "欲交易玩家 $arg[0] 不存在.\n";
		} elsif ($arg[0] =~ /^\d+$/) {
			$outgoingDeal{'ID'} = $playersID[$arg[0]];
			sendDeal(\$remote_socket, $playersID[$arg[0]]);
			print "你詢問 $players{$playersID[$arg[0]]}{'name'} 願不願意交易\n";

		} elsif ($arg[0] eq "no" && !%incomingDeal && !%outgoingDeal && !%currentDeal) {
			print	"發生錯誤 'deal' (Deal a Player)\n"
				, "沒有任何交易可以取消.\n";
		} elsif ($arg[0] eq "no" && (%incomingDeal || %outgoingDeal)) {
			sendDealCancel(\$remote_socket);
		} elsif ($arg[0] eq "no" && %currentDeal) {
			sendCurrentDealCancel(\$remote_socket);


		} elsif ($arg[0] eq "" && !%incomingDeal && !%currentDeal) {
			print	"發生錯誤 'deal' (Deal a Player)\n"
				, "沒有任何交易可以接受.\n";
		} elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && !$currentDeal{'other_finalize'}) {
			print	"發生錯誤 'deal' (Deal a Player)\n"
				, "無法完成交易 - $currentDeal{'name'} 尚未確認交易.\n";
		} elsif ($arg[0] eq "" && $currentDeal{'final'}) {
			print	"發生錯誤 'deal' (Deal a Player)\n"
				, "你已經確認開始交換.\n";
		} elsif ($arg[0] eq "" && %incomingDeal) {
			sendDealAccept(\$remote_socket);
		} elsif ($arg[0] eq "" && $currentDeal{'you_finalize'} && $currentDeal{'other_finalize'}) {
			sendDealTrade(\$remote_socket);
			$currentDeal{'final'} = 1;
			print "你確認開始交換\n";
			parseInput("dl");
		} elsif ($arg[0] eq "" && %currentDeal) {
			sendDealAddItem(\$remote_socket, 0, $currentDeal{'you_zenny'});
			sendDealFinalize(\$remote_socket);

		} elsif ($arg[0] eq "add" && !%currentDeal) {
			print	"發生錯誤 'deal add' (Add Item to Deal)\n"
				, "無法放入任何物品到交易欄 - 你沒有在交易.\n";
		} elsif ($arg[0] eq "add" && $arg[1] eq "") {
			print	"語法錯誤 'deal add' (Add Item to Deal)\n"
				, "使用方法: deal add <物品編號 | z=Zeny> [<數量>]\n";
		} elsif ($arg[0] eq "add" && $currentDeal{'you_finalize'}) {
			print	"發生錯誤 'deal add' (Add Item to Deal)\n"
				, "無法放入任何物品到交易欄 - 你已經確認交易.\n";
		} elsif ($arg[0] eq "add" && $arg[1] =~ /^\d+$/ && !%{$chars[$config{'char'}]{'inventory'}[$arg[1]]}) {
			print	"發生錯誤 'deal add' (Add Item to Deal)\n"
				, "欲交易物品 $arg[1] 不存在.\n";
		} elsif ($arg[0] eq "add" && $arg[2] ne "" && $arg[2] !~ /^\d+$/) {
			print	"發生錯誤 'deal add' (Add Item to Deal)\n"
				, "數量必需為數字, 且必須大於零.\n";
		} elsif ($arg[0] eq "add" && $arg[1] =~ /^\d+$/) {
			if ($currentDeal{'totalItems'} < 10) {
				if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'}) {
					$arg[2] = $chars[$config{'char'}]{'inventory'}[$arg[1]]{'amount'};
				}
				$currentDeal{'lastItemAmount'} = $arg[2];
				sendDealAddItem(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg[1]]{'index'}, $arg[2]);
			} else {
				print "發生錯誤 'deal add' (Add Item to Deal)\n"
					, "最多只能交換10樣物品.\n";
			}

		} elsif ($arg[0] eq "add" && $arg[1] eq "z" && $arg[2] !~ /^\d+$/) {
			print	"發生錯誤 'deal add z' (Add Zeny to Deal)\n"
				, "數量必需為數字, 且必須大於零.\n";
		} elsif ($arg[0] eq "add" && $arg[1] eq "z") {
			if (!$arg[2] || $arg[2] > $chars[$config{'char'}]{'zenny'}) {
				$arg[2] = $chars[$config{'char'}]{'zenny'};
			}
			$currentDeal{'you_zenny'} = $arg[2];
			print "你放了 ".toZeny($arg[2])." z 到交易欄\n";
			parseInput("dl");

		} else {
			print	"語法錯誤 'deal' (Deal a player)\n"
				, "使用方法: deal [<玩家編號 | no>]\n";
		}

	} elsif ($switch eq "dl") {
		if (!%currentDeal) {
			print "發生錯誤 'dl' (Deal List)\n"
				, "沒有交易視窗可顯示 - 你沒有在交易.\n";

		} else {
			print "---------------------------------- 交易視窗 ----------------------------------\n";
			$other_string = $currentDeal{'name'};
			$you_string = "你";
			if ($currentDeal{'other_finalize'}) {
				$other_string .= " - 已確認";
			} else {
				$other_string .= " - 未確認";
			}
			if ($currentDeal{'you_finalize'}) {
				$you_string .= " - 已確認";
			} else {
				$you_string .= " - 未確認";
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

己方出價:      @>>>>>>>>>>>> Zeny           對方出價:      @>>>>>>>>>>>> Zeny
               $you_string,                                $other_string
.
			write;
			print "------------------------------------------------------------------------------\n";
			if (!$currentDeal{'you_finalize'}) {
				print "請輸入 'deal add <物品編號 | z=Zeny> [<數量>]' 新增物品及金錢到交易欄\n";
				print "若不再新增物品, 請輸入 'deal' 確認交易, 或輸入 'deal no' 取消交易\n";
			} elsif (!$currentDeal{'other_finalize'}) {
				print "等待 $currentDeal{'name'} 確認此次交易, 或輸入 'deal no' 取消交易\n";
			} elsif (!$currentDeal{'final'}) {
				print "請輸入 'deal' 確認開始交換, 或輸入 'deal no' 取消交易\n";
			} else {
				print "等待 $currentDeal{'name'} 確認開始交換, 或輸入 'deal no' 取消交易\n";
			}
			print "\n";
		}


	} elsif ($switch eq "drop") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			print	"語法錯誤 'drop' (Drop Inventory Item)\n"
				, "使用方法: drop <物品編號> [<數量>]\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"發生錯誤 'drop' (Drop Inventory Item)\n"
				, "欲丟棄物品 $arg1 不存在.\n";
		} elsif (isEquipment($chars[$config{'char'}]{'inventory'}[$arg1]{'type'})) {
			print	"發生錯誤 'drop' (Drop Inventory Item)\n"
				, "無法丟棄物品 $arg1.\n";
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
			print	"語法錯誤 'e' (Emotion)\n"
				, "使用方法: e <表情編號>\n";
		$~ = "EMOTIONLIST";
		print "-------------- 額外說明 --------------\n";
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
						$equipment{'handRight'}{'name'} .= " -- 由 $charID_lut{$chars[$config{'char'}]{'inventory'}[$i]{'maker_charID'}} 製作";
					}
				}
				if ($chars[$config{'char'}]{'inventory'}[$i]{'equipped'} & 32) {
					$equipment{'handLeft'}{'index'} = $i;
					$equipment{'handLeft'}{'name'} = $chars[$config{'char'}]{'inventory'}[$i]{'name'};
					if ($chars[$config{'char'}]{'inventory'}[$i]{'maker_charID'}) {
						$equipment{'handLeft'}{'name'} .= " -- 由 $charID_lut{$chars[$config{'char'}]{'inventory'}[$i]{'maker_charID'}} 製作";
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
					$arrow_string = "箭筒裝著  $arrow_index_string $chars[$config{'char'}]{'inventory'}[$i]{'name'} x $chars[$config{'char'}]{'inventory'}[$i]{'amount'}";
				}
			}
			$~ = "EQUIPMENTLIST";
			print "------------------- 裝備欄 -------------------\n";
			print "裝備位置  #   名稱                            \n";
			format EQUIPMENTLIST =
頭戴(上)  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'headUp'}{'index'}, $equipment{'headUp'}{'name'}
頭戴(中)  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'headMiddle'}{'index'}, $equipment{'headMiddle'}{'name'}
頭戴(下)  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'headLow'}{'index'}, $equipment{'headLow'}{'name'}
身上穿著  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'body'}{'index'}, $equipment{'body'}{'name'}
右手拿著  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'handRight'}{'index'}, $equipment{'handRight'}{'name'}
左手拿著  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'handLeft'}{'index'}, $equipment{'handLeft'}{'name'}
肩上披著  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'about'}{'index'}, $equipment{'about'}{'name'}
腳上穿著  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'feet'}{'index'}, $equipment{'feet'}{'name'}
配件(右)  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'accessoryRight'}{'index'}, $equipment{'accessoryRight'}{'name'}
配件(左)  @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
			$equipment{'accessoryLeft'}{'index'}, $equipment{'accessoryLeft'}{'name'}
.
			write;
			print "----------------------------------------------\n";

			if ($arrow_index_string ne "") {
				print "$arrow_string\n";
				print "----------------------------------------------\n";
			}

		} elsif ($arg1 =~ /^\d+$/ && !%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"發生錯誤 'eq' (Equip Inventory Item)\n"
				, "欲裝備物品 $arg1 不存在.\n";
		# Equip arrow related
		} elsif ($arg1 =~ /^\d+$/ && !$chars[$config{'char'}]{'inventory'}[$arg1]{'type_equip'} && $chars[$config{'char'}]{'inventory'}[$arg1]{'type'} != 10) {
			print	"發生錯誤 'eq' (Equip Inventory Item)\n"
				, "物品 $arg1 無法裝備.\n";

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
			print	"語法錯誤 'eq' (Equip Inventory Item)\n"
				, "使用方法: eq [<物品編號>] [<left=左手位置>]\n";
		}

	} elsif ($switch eq "follow") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			print	"語法錯誤 'follow' (Follow Player)\n"
				, "使用方法: follow <玩家編號>\n";
		} elsif ($arg1 eq "stop") {
			aiRemove("follow");
#			configModify("follow", 0);
			scModify("config", "follow", 0, 2);
		} elsif ($playersID[$arg1] eq "") {
			print	"發生錯誤 'follow' (Follow Player)\n"
				, "欲跟隨玩家 $arg1 不存在.\n";
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
			print	"發生錯誤 'i' (Iventory Item Description)\n"
				, "欲檢視物品 $arg2 不存在.\n";
		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/) {

			printDesc(0, $chars[$config{'char'}]{'inventory'}[$arg2]{'nameID'}, fixingName(\%{$chars[$config{'char'}]{'inventory'}[$arg2]}));

		} else {
			print	"語法錯誤 'i' (Iventory List)\n"
				, "使用方法: i [<u | eq | nu | desc>] [<物品編號>]\n";
		}

	} elsif ($switch eq "identify") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			$~ = "IDENTIFY";
			print "--------------- 可鑑定物品清單 ---------------\n";
			print "#   名稱                                      \n";
			for ($i = 0; $i < @identifyID; $i++) {
				next if ($identifyID[$i] eq "");
				format IDENTIFY =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $chars[$config{'char'}]{'inventory'}[$identifyID[$i]]{'name'}
.
				write;
			}
			print "----------------------------------------------\n";
			print "請輸入 'identify <可鑑定物品編號>' 選擇\n";

		} elsif ($arg1 =~ /^\d+$/ && $identifyID[$arg1] eq "") {
			print	"發生錯誤 'identify' (Identify Item)\n"
				, "欲鑑定物品 $arg1 不存在.\n";

		} elsif ($arg1 =~ /^\d+$/) {
			sendIdentify(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$identifyID[$arg1]]{'index'});
		} else {
			print	"語法錯誤 'identify' (Identify Item)\n"
				, "使用方法: identify [<可鑑定物品編號>]\n";
		}


	} elsif ($switch eq "ignore") {
		($arg1, $arg2) = $input =~ /^[\s\S]*? (\d+) ([\s\S]*)/;
		if ($arg1 eq "" || $arg2 eq "" || ($arg1 ne "0" && $arg1 ne "1")) {
			print	"語法錯誤 'ignore' (Ignore Player/Everyone)\n"
				, "使用方法: ignore <0=開啟密語 | 1=關閉密語> <玩家名稱 | all>\n";
		} else {
			if ($arg2 eq "all") {
				sendIgnoreAll(\$remote_socket, !$arg1);
			} else {
				sendIgnore(\$remote_socket, $arg2, !$arg1);
			}
		}

	} elsif ($switch eq "il") {
		$~ = "ILIST";
		print "------------------ 物品列表 ------------------\n";
		print "#   名稱                                      \n";
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
#			print	"語法錯誤 'im' (Use Item on Monster)\n"
#				, "使用方法: im <物品編號> <怪物編號>\n";
#		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
#			print	"發生錯誤 'im' (Use Item on Monster)\n"
#				, "欲使用物品 $arg1 不存在.\n";
#		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
#			print	"發生錯誤 'im' (Use Item on Monster)\n"
#				, "欲使用物品 $arg1 不是可使用的.\n";
#		} elsif ($monstersID[$arg2] eq "") {
#			print	"發生錯誤 'im' (Use Item on Monster)\n"
#				, "怪物 $arg2 不存在.\n";
#		} else {
#			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $monstersID[$arg2]);
#		}
#
#	} elsif ($switch eq "ip") {
#		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
#		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
#		if ($arg1 eq "" || $arg2 eq "") {
#			print	"語法錯誤 'ip' (Use Item on Player)\n"
#				, "使用方法: ip <物品編號> <玩家編號>\n";
#		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
#			print	"發生錯誤 'ip' (Use Item on Player)\n"
#				, "欲使用物品 $arg1 不存在.\n";
#		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
#			print	"發生錯誤 'ip' (Use Item on Player)\n"
#				, "欲使用物品 $arg1 不是可使用的.\n";
#		} elsif ($playersID[$arg2] eq "") {
#			print	"發生錯誤 'ip' (Use Item on Player)\n"
#				, "玩家 $arg2 不存在.\n";
#		} else {
#			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'}, $playersID[$arg2]);
#		}
#
#	} elsif ($switch eq "is") {
#		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
#		if ($arg1 eq "") {
#			print	"語法錯誤 'is' (Use Item on Self)\n"
#				, "使用方法: is <物品編號>\n";
#		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
#			print	"發生錯誤 'is' (Use Item on Self)\n"
#				, "欲使用物品 $arg1 不存在.\n";
#		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'type'} > 2) {
#			print	"發生錯誤 'is' (Use Item on Self)\n"
#				, "欲使用物品 $arg1 不是可使用的.\n";
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
			$tmpVal{'text'} = "<物品編號>";
			$tmpVal{'text'} .= " <$tmpVal{'title'} ID>" if ($switch ne "is");
			$tmpVal{'type'} = 1;
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$params[1]]}) {
			$tmpVal{'text'} = "欲使用物品 $params[1] 不存在";
		} elsif ($chars[$config{'char'}]{'inventory'}[$params[1]]{'type'} > 2) {
			$tmpVal{'text'} = "欲使用物品 $params[1] 不是可使用的";
		} elsif ($tmpVal{'targetID'} eq "") {
			$tmpVal{'text'} = "$tmpVal{'title'} $params[2] 不存在";
		} else {
			sendItemUse(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$params[1]]{'index'}, $accountID);
		}

		printErr($switch, "Use Item on $tmpVal{'title'}", $tmpVal{'text'}, $tmpVal{'type'});

	} elsif ($switch eq "join") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ ([\s\S]*)$/;
		if ($arg1 eq "") {
			print	"語法錯誤 'join' (Join Chat Room)\n"
				, "使用方法: join <聊天室編號> [<密碼>]\n";
		} elsif ($currentChatRoom ne "") {
			print	"發生錯誤 'join' (Join Chat Room)\n"
				, "你已經在聊天室中了.\n";
		} elsif ($shop{'opened'}) {
			print	"發生錯誤 'join' (Join Chat Room)\n"
				, "擺\攤的時候必須專心, 不然可能會被順手牽羊噢.\n";
		} elsif ($chatRoomsID[$arg1] eq "") {
			print	"發生錯誤 'join' (Join Chat Room)\n"
				, "欲加入聊天室 $arg1 不存在.\n";
		} else {
			sendChatRoomJoin(\$remote_socket, $chatRoomsID[$arg1], $arg2);
		}

	} elsif ($switch eq "judge") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"語法錯誤 'judge' (Give an alignment point to Player)\n"
				, "使用方法: judge <玩家編號> <0=好 | 1=壞>\n";
		} elsif ($playersID[$arg1] eq "") {
			print	"發生錯誤 'judge' (Give an alignment point to Player)\n"
				, "欲評鑑玩家 $arg1 不存在.\n";
		} else {
			$arg2 = ($arg2 >= 1);
			sendAlignment(\$remote_socket, $playersID[$arg1], $arg2);
		}

	} elsif ($switch eq "kick") {
		($arg1) = $input =~ /^[\s\S]*? ([\s\S]*)/;
		if ($currentChatRoom eq "") {
			print	"發生錯誤 'kick' (Kick from Chat)\n"
				, "你不在聊天室裡.\n";
		} elsif ($arg1 eq "") {
			print	"語法錯誤 'kick' (Kick from Chat)\n"
				, "使用方法: kick <玩家編號>\n";
		} elsif ($currentChatRoomUsers[$arg1] eq "") {
			print	"發生錯誤 'kick' (Kick from Chat)\n"
				, "欲踢出玩家 $arg1 不存在.\n";
		} else {
			sendChatRoomKick(\$remote_socket, $currentChatRoomUsers[$arg1]);
		}

	} elsif ($switch eq "leave") {
		if ($currentChatRoom eq "") {
			print	"發生錯誤 'leave' (Leave Chat Room)\n"
				, "你不在聊天室裡.\n";
		} else {
			sendChatRoomLeave(\$remote_socket);
		}

	} elsif ($switch eq "look") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;

		my $z = getSex($chars[$config{'char'}]{'sex'}, 1);

		if (!isNum($params[1])) {
			printErr($switch, "Look a Direction", "<身體> [<頭部>]", 1);

			print "-------------- 額外說明 --------------\n";
			print "身體: １  ０  ７        頭部: 0=正前方\n";
			print "        ↖↑↗                        \n";
			print "      ２←$z→６              1=右前方\n";
			print "        ↙↓↘                        \n";
			print "      ３  ４  ５              2=左前方\n";
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
		print "---------------------------------- 怪物列表 ---------------------$mycoords----\n";
		print "#   Lv 名稱                          玩家給予傷害  玩家受到傷害   座   標 距離\n";
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
			print	"語法錯誤 'move' (Move Player)\n"
				, "使用方法: move <x座標> <y座標> &| <地圖名稱>\n";
		} elsif ($ai_v{'temp'}{'map'} eq "stop") {
			aiRemove("move");
			aiRemove("route");
			aiRemove("route_getRoute");
			aiRemove("route_getMapRoute");
			print "停止所有移動\n";

		} elsif ($ai_v{'temp'}{'map'} eq "ptl" && $arg2 eq "") {
			print	"語法錯誤 'move ptl' (Move Player to Portal)\n"
				, "使用方法: move ptl <傳點編號>\n";
		} elsif ($ai_v{'temp'}{'map'} eq "ptl" && $portalsID[$arg2] eq "") {
			print	"語法錯誤 'move ptl' (Move Player to Portal)\n"
				, "欲進入傳送點 $arg2 不存在.\n";
		} elsif ($ai_v{'temp'}{'map'} eq "ptl") {
			print "計算路徑前往指定傳送點 ($arg2) - $portals{$portalsID[$arg2]}{'name'} ".getFormattedCoords($portals{$portalsID[$arg2]}{'pos'}{'x'}, $portals{$portalsID[$arg2]}{'pos'}{'y'})."\n";
			ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $portals{$portalsID[$arg2]}{'pos'}{'x'}, $portals{$portalsID[$arg2]}{'pos'}{'y'}, $field{'name'}, 0, 0, 1);

		} else {
			$ai_v{'temp'}{'map'} = $field{'name'} if ($ai_v{'temp'}{'map'} eq "");
			if ($maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}) {
				if ($arg2 ne "") {
					print "計算路徑前往指定地點 - $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'}): ".getFormattedCoords($arg1, $arg2)."\n";
					$ai_v{'temp'}{'x'} = $arg1;
					$ai_v{'temp'}{'y'} = $arg2;
				} else {
					print "計算路徑前往指定地圖 - $maps_lut{$ai_v{'temp'}{'map'}.'.rsw'}($ai_v{'temp'}{'map'})\n";
					undef $ai_v{'temp'}{'x'};
					undef $ai_v{'temp'}{'y'};
				}
				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'x'}, $ai_v{'temp'}{'y'}, $ai_v{'temp'}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				print	"語法錯誤 'move' (Move Player)\n"
					, "指定地圖設定錯誤 - $sc_v{'path'}{'tables'}/maps.txt中找不到 $ai_v{'temp'}{'map'}.rsw\n";
			}
		}

	} elsif ($switch eq "nl") {
		# Add ID information to the list
		$~ = "NLIST";
		print "------------------ NPC 列表 ------------------\n";
		print "#   ID     名稱                       座   標 \n";
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
			print	"發生錯誤 'party' (Party Functions)\n"
				, "無法查詢隊伍資訊 - 你沒有隊伍.\n";
		} elsif ($arg1 eq "") {
			$~ = "PARTYUSERS";
			$share_string = ($chars[$config{'char'}]{'party'}{'share'}) ? "均等分配" : "各自取得";
			print "---------------------------------- 隊伍資訊 ----------------------------------\n";
			print "隊伍名稱: $chars[$config{'char'}]{'party'}{'name'}($share_string)\n";
			print "#   隊長  線上 名稱                    所在地圖     座   標                   \n";

			my ($i, $admin_string, $online_string, $name_string, $map_string, $coord_string, $hp_string);

			for ($i = 0; $i < @partyUsersID; $i++) {
				next if ($partyUsersID[$i] eq "");
				$coord_string = "";
				$hp_string = "";
				$name_string = $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'name'};
				$admin_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'admin'}) ? " ㊣ " : "";

				if ($partyUsersID[$i] eq $accountID) {
					$online_string = " Ｖ ";
					($map_string) = getMapID($map_name);
					$coord_string = getFormattedCoords($chars[$config{'char'}]{'pos'}{'x'}, $chars[$config{'char'}]{'pos'}{'y'});
					$hp_string = sprintf("%5d", $chars[$config{'char'}]{'hp'})."/".sprintf("%-5d", $chars[$config{'char'}]{'hp_max'})
							."(".sprintf("%3d", int(percent_hp(\%{$chars[$config{'char'}]})))
							."%)";
				} else {
					$online_string = ($chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$i]}{'online'}) ? " Ｖ " : "";
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

				FunctionError('party create', 'Organize Party', '你已經在隊伍裡面');

			} elsif ($params[2] eq "" && $config{'partyAutoCreate'}) {

				sendPartyOrganize(\$remote_socket, vocalString(14));
				# Party created by self
				$createPartyBySelf = 1;

			} elsif ($params[2] eq "") {
#				print	"語法錯誤 'party create' (Organize Party)\n"
#				,qq~使用方法: party create "<隊伍名稱>"\n~;

				printErr('party create', 'Organize Party', '"<隊伍名稱>"', 1);
			} else {
				sendPartyOrganize(\$remote_socket, $params[2]);
				# Party created by self
				$createPartyBySelf = 1;
			}

		} elsif ($arg1 eq "join" && $arg2 ne "1" && $arg2 ne "0") {
			print	"語法錯誤 'party join' (Accept/Deny Party Join Request)\n"
				, "使用方法: party join <0=拒絕 | 1=接受>\n";
		} elsif ($arg1 eq "join" && $incomingParty{'ID'} eq "") {
			print	"發生錯誤 'party join' (Join/Request to Join Party)\n"
				, "無法接受或拒絕隊伍邀請 - 沒有入隊邀請.\n";
		} elsif ($arg1 eq "join") {
			sendPartyJoin(\$remote_socket, $incomingParty{'ID'}, $arg2);
			undef %incomingParty;

		} elsif ($arg1 eq "request" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"發生錯誤 'party request' (Request to Join Party)\n"
				, "無法邀請加入 - 你沒有隊伍.\n";
		} elsif ($arg1 eq "request" && $playersID[$arg2] eq "") {
			print	"發生錯誤 'party request' (Request to Join Party)\n"
				, "無法邀請加入 - 欲邀請玩家 $arg2 不存在.\n";
		} elsif ($arg1 eq "request") {
			sendPartyJoinRequest(\$remote_socket, $playersID[$arg2]);

		} elsif ($arg1 eq "leave" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"發生錯誤 'party leave' (Leave Party)\n"
				, "無法脫離隊伍 - 你沒有隊伍.\n";
		} elsif ($arg1 eq "leave") {
			sendPartyLeave(\$remote_socket);


		} elsif ($arg1 eq "share" && !%{$chars[$config{'char'}]{'party'}}) {
			print	"發生錯誤 'party share' (Set Party Share EXP)\n"
				, "無法設定經驗值分配 - 你沒有隊伍.\n";
		} elsif ($arg1 eq "share" && !$chars[$config{'char'}]{'party'}{'users'}{$accountID}{'admin'}) {
			print	"發生錯誤 'party share' (Set Party Share EXP)\n"
				, "無法設定經驗值分配 - 你不是隊長.\n";
		} elsif ($arg1 eq "share" && $arg2 ne "1" && $arg2 ne "0") {
			print	"語法錯誤 'party share' (Set Party Share EXP)\n"
				, "使用方法: party share <0=各自取得 | 1=平均分配>\n";
		} elsif ($arg1 eq "share") {
			sendPartyShareEXP(\$remote_socket, $arg2);


#		} elsif ($arg1 eq "kick" && !%{$chars[$config{'char'}]{'party'}}) {
#			print	"發生錯誤 'party kick' (Kick Party Member)\n"
#				, "無法踢出玩家 - 你沒有隊伍.\n";
#		} elsif ($arg1 eq "kick" && $arg2 eq "") {
#			print	"語法錯誤 'party kick' (Kick Party Member)\n"
#				, "使用方法: party kick <隊伍成員編號>\n";
#		} elsif ($arg1 eq "kick" && $partyUsersID[$arg2] eq "") {
#			print	"發生錯誤 'party kick' (Kick Party Member)\n"
#				, "無法踢出玩家 - 欲踢出玩家 $arg2 不存在.\n";
#		} elsif ($arg1 eq "kick") {
#			sendPartyKick(\$remote_socket, $partyUsersID[$arg2]
#					, $chars[$config{'char'}]{'party'}{'users'}{$partyUsersID[$arg2]}{'name'});
#
#		}
		} elsif ($params[1] eq "kick") {
			@{$tmpVal{'err'}} = ('party kick', 'Kick Party Member');

			if (!%{$chars[$config{'char'}]{'party'}}) {
				$tmpVal{'err'}[2] = "無法踢出玩家 - 你沒有隊伍";
			} elsif ($params[2] eq "") {
				$tmpVal{'err'}[2] = "<隊伍成員編號>";
				$tmpVal{'err'}[3] = 1;
			} elsif ($partyUsersID[$params[2]] eq "") {
				$tmpVal{'err'}[2] = "無法踢出玩家 - 欲踢出玩家 $arg2 不存在";
			} elsif ($partyUsersID[$params[2]] eq $accountID) {
				$tmpVal{'err'}[2] = "你是隊長";
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
		print "------------------ 寵物列表 ------------------\n";
		print "#   種類               名稱                   \n";
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
			print	"語法錯誤 'pm' (Private Message)\n"
				,qq~使用方法: pm ("<玩家名稱>" | 密語列表編號) <訊息>\n~;
		} elsif ($type) {
			if ($arg1 - 1 >= @privMsgUsers) {
				print	"發生錯誤 'pm' (Private Message)\n"
				, "玩家 $arg1 不在你的密語列表中.\n";
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
		print "已將傳送密語時重複顯示之話語刪除\n";

	} elsif ($switch eq "pml") {
		$~ = "PMLIST";
		print "------------------ 密語列表 ------------------\n";
		print "#   名稱                                      \n";
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
		print "---------------------------------- 玩家列表 ---------------------$mycoords----\n";
		print "#   Lv 職業 性別 名稱                   所屬公會                  座   標 距離\n";
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
#		print "----------------- 傳送點列表 -----------------\n";

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
#		print "[攻擊狀態] $attack_string\n";
#		print "[外    觀] $outlook_string\n";
#		print "[禁    言] 禁言限制還剩下 $chars[$config{'char'}]{'skill_ban'}分鐘\n" if ($chars[$config{'char'}]{'skill_ban'});
#		print "[Ｐ ｖ Ｐ] 目前排名 $chars[$config{'char'}]{'pvp'}{'rank_num'}\n" if ($chars[$config{'char'}]{'pvp'}{'start'} == 1);
#		print "[氣 球 數] 目前擁有 $chars[$config{'char'}]{'spirits'}顆氣球\n" if ($chars[$config{'char'}]{'spirits'});
#
#		print "[特殊狀態Ａ] ".getMsgStrings('0119_A', $chars[$config{'char'}]{'param1'})."\n" if ($chars[$config{'char'}]{'param1'});
#
#		foreach (keys %{$messages_lut{'0119_B'}}) {
#			print "[特殊狀態Ｂ] ".getMsgStrings('0119_B', $_)."\n" if ($_ & $chars[$config{'char'}]{'param2'});
#		}
#		foreach (keys %{$messages_lut{'0119_C'}}) {
#			print "[特殊狀態Ｃ] ".getMsgStrings('0119_C', $_)."\n" if ($_ & $chars[$config{'char'}]{'param3'});
#		}
#		# Status icon
#		foreach (@{$chars[$config{'char'}]{'status'}}) {
#			next if ($_ == 27 || $_ == 28);
#			my $messages = getMsgStrings('0196', $_, 1);
#			$messages .= " -- $chars[$config{'char'}]{'autospell'}" if ($_ == 65);
#			print "[持續狀態] ${messages}\n";
#		}
		print subStrLine($t_exp_line);

	} elsif ($switch eq "sell") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "" && $talk{'buyOrSell'}) {
			sendGetSellList(\$remote_socket, $talk{'ID'});
		} elsif ($arg1 eq "") {
			print	"語法錯誤 'sell' (Sell Inventory Item)\n"
				, "使用方法: sell <物品編號> [<數量>]\n";

		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"發生錯誤 'sell' (Sell Inventory Item)\n"
				, "欲販賣物品 $arg1 不存在.\n";
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
			print	"語法錯誤 'sm' (Use Skill on Monster)\n"
				, "使用方法: sm <技能編號> <怪物編號> [<技能等級>]\n";
		} elsif ($monstersID[$arg2] eq "") {
			print	"發生錯誤 'sm' (Use Skill on Monster)\n"
				, "怪物 $arg2 不存在.\n";
		} elsif ($skillsID[$arg1] eq "") {
			print	"發生錯誤 'sm' (Use Skill on Monster)\n"
				, "欲使用技能 $arg1 不存在.\n";
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
			print "------------------- 技能欄 -------------------\n";
			print "#   名稱                          Lv   Sp     \n";
			for ($i=0; $i < @skillsID; $i++) {
				format SKILLS =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<  @>  @>>
$i, $skills_lut{$skillsID[$i]}, $chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'}, $skillsSP_lut{$skillsID[$i]}{$chars[$config{'char'}]{'skills'}{$skillsID[$i]}{'lv'}}
.
				write;
			}
			print "\n剩餘技能點數: $chars[$config{'char'}]{'points_skill'}\n";
			print "----------------------------------------------\n";


		} elsif ($arg1 eq "add" && $arg2 =~ /^\d+$/ && $skillsID[$arg2] eq "") {
			print	"發生錯誤 'skills add' (Add Skill Point)\n"
				, "技能 $arg2 不存在.\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /^\d+$/ && $chars[$config{'char'}]{'points_skill'} < 1) {
			print	"發生錯誤 'skills add' (Add Skill Point)\n"
				, "沒有足夠的技能點數可以提昇 $skills_lut{$skillsID[$arg2]} 的等級.\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /^\d+$/) {
			sendAddSkillPoint(\$remote_socket, $chars[$config{'char'}]{'skills'}{$skillsID[$arg2]}{'ID'});


		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/ && $skillsID[$arg2] eq "") {
			print	"發生錯誤 'skills desc' (Skill Description)\n"
				, "欲檢視技能 $arg2 不存在.\n";
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
			print "將技能對應編號寫入 SkillsList.txt\n";
#Karasu End
		} else {
			print	"語法錯誤 'skills' (Skills Functions)\n"
				, "使用方法: skills [<add | desc | log>] [<技能編號>]\n";
		}


	} elsif ($switch eq "sp") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \d+ \d+ (\d+)/;
		if ($arg1 eq "" || $arg2 eq "") {
			print	"語法錯誤 'sp' (Use Skill on Player)\n"
				, "使用方法: sp <技能編號> <玩家編號> [<技能等級>]\n";
		} elsif ($playersID[$arg2] eq "") {
			print	"發生錯誤 'sp' (Use Skill on Player)\n"
				, "玩家 $arg2 不存在.\n";
		} elsif ($skillsID[$arg1] eq "") {
			print	"發生錯誤 'sp' (Use Skill on Player)\n"
				, "欲使用技能 $arg1 不存在.\n";
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
			print	"語法錯誤 'ss' (Use Skill on Self)\n"
				, "使用方法: ss <技能編號> [<技能等級>]\n";
		} elsif ($skillsID[$arg1] eq "") {
			print	"發生錯誤 'ss' (Use Skill on Self)\n"
				, "欲使用技能 $arg1 不存在.\n";
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
		print "------------------ 角色素質 ------------------\n";
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
			print	"語法錯誤 'stat_add' (Add Status Point)\n"
			, "使用方法: stat_add <str | agi | vit | int | dex | luk>\n";
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
				print	"發生錯誤 'stat_add' (Add Status Point)\n"
					, "沒有足夠的點數可以分配到 $arg1.\n";
			} elsif ($chars[$config{'char'}]{$arg1} == 99 && $chars[$config{'char'}]{"points_$arg1"} > 0) {
				print "素質: $arg1 將會超過 99, 確定(y/n)？, $timeout{'cancelStatAdd_auto'}{'timeout'}秒後自動取消...\n";
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
			print	"發生錯誤 'storage add' (Add Item to Storage)\n"
				, "欲存入物品 $arg2 不存在.\n";
		} elsif ($arg1 eq "add" && $arg2 =~ /^\d+$/) {
			if (!$arg3 || $arg3 > $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'}) {
				$arg3 = $chars[$config{'char'}]{'inventory'}[$arg2]{'amount'};
			}
			sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, $arg3);
		} elsif ($arg1 eq "add" && $arg2 eq "") {
			print	"語法錯誤 'storage add' (Add Item to Storage)\n"
				, "使用方法: storage add <物品編號> [<數量>]\n";

		} elsif ($arg1 eq "get" && $arg2 =~ /^\d+$/ && !%{$storage{'inventory'}[$arg2]}) {
			print	"發生錯誤 'storage get' (Get Item from Storage)\n"
				, "欲提取物品 $arg2 不存在.\n";
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
			print	"語法錯誤 'storage get' (Get Item from Storage)\n"
				, "使用方法: storage get <倉庫物品編號> [<數量>] [<cart>]\n";

		} elsif ($arg1 eq "close") {
			sendStorageClose(\$remote_socket);

		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/ && !%{$storage{'inventory'}[$arg2]}) {
			print	"發生錯誤 'storage desc' (Storage Item Description)\n"
				, "欲檢視物品 $arg2 不存在.\n";
		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/) {

			printDesc(0, $storage{'inventory'}[$params[2]]{'nameID'}, fixingName(\%{$storage{'inventory'}[$params[2]]}));

		} else {
			print	"語法錯誤 'storage' (Storage List)\n"
				, "使用方法: storage [<u | eq | nu | desc>] [<倉庫物品編號>]\n";
		}

	} elsif ($switch eq "store") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "" && !$talk{'buyOrSell'}) {
			$~ = "STORELIST";
			print "---------------- 商店物品清單 ----------------\n";
			print "#   名稱                    種類      金 額(Z)\n";
			for ($i=0; $i < @storeList;$i++) {
				$price_string = toZeny($storeList[$i]{'price_dc'});
				format STORELIST =
@<< @<<<<<<<<<<<<<<<<<<<<<< @<<<<<<< @>>>>>>>>
$i, $storeList[$i]{'name'}, $itemTypes_lut{$storeList[$i]{'type'}}, $price_string
.
				write;
			}
			print "----------------------------------------------\n";
			print "$npcs{$talk{'ID'}}{'name'}: 請輸入 'buy <商店物品編號> [<數量>]' 購買物品\n"
				, "$npcs{$talk{'ID'}}{'name'}: 或輸入 'store' 查看商店物品清單\n";

		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/ && !%{$storeList[$arg2]}) {
			print	"發生錯誤 'store desc' (Store Item Description)\n"
				, "欲檢視商店物品 $arg2 不存在.\n";
		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/) {

			printDesc(0, $storeList[$arg2]{'nameID'}, $storeList[$arg2]{'name'});

		} else {
			print	"語法錯誤 'store' (Store Functions)\n"
				, "使用方法: store [<desc>] [<商店物品編號>]\n";

		}

	} elsif ($switch eq "take") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)$/;
		if ($arg1 eq "") {
			print	"語法錯誤 'take' (Take Item)\n"
				, "使用方法: take <物品編號>\n";
		} elsif ($itemsID[$arg1] eq "") {
			print	"發生錯誤 'take' (Take Item)\n"
				, "欲撿取物品 $arg1 不存在.\n";
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
			print	"發生錯誤 'talk' (Talk to NPC)\n"
				, "NPC $arg1 不存在.\n";
		} elsif ($arg1 =~ /^\d+$/) {
			sendTalk(\$remote_socket, $npcsID[$arg1]);

		} elsif ($arg1 eq "answer" && !%talk) {
			print	"發生錯誤 'talk answer' (Answer to NPC)\n"
				, "你還沒有跟任何 NPC 交談.\n";
		} elsif ($arg1 eq "answer" && $arg2 eq "") {
			print	"語法錯誤 'talk answer' (Answer to NPC)\n"
				, qq~使用方法: talk answer (數量 | "<文字>")\n~;
		} elsif ($arg1 eq "answer" && $arg2 ne "") {
			if ($type) {
				sendTalkAnswerNum(\$remote_socket, $talk{'ID'}, $arg2);
			} else {
				sendTalkAnswerWord(\$remote_socket, $talk{'ID'}, $arg2);
			}

		} elsif ($arg1 eq "resp" && !%talk) {
			print	"發生錯誤 'talk resp' (Respond to NPC)\n"
				, "你還沒有跟任何NPC交談.\n";
		} elsif ($arg1 eq "resp" && $arg2 eq "") {
			$~ = "RESPONSES";
			$display = $npcs{$talk{'ID'}}{'name'};
			print "------------------ 回應清單 ------------------\n";
			print "對象: $display\n\n";
			print "#   選項                                      \n";
			for ($i=0; $i < @{$talk{'responses'}};$i++) {
				format RESPONSES =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $talk{'responses'}[$i]
.
				write;
			}
			print "----------------------------------------------\n";
			print "$npcs{$talk{'ID'}}{'name'}: 請輸入 'talk resp <編號>' 選擇欲回應選項, 或輸入 'talk no' 取消對話\n"
				, "$npcs{$talk{'ID'}}{'name'}: 或輸入 'talk resp' 查看回應清單\n";

		} elsif ($arg1 eq "resp" && $arg2 ne "" && $talk{'responses'}[$arg2] eq "") {
			print	"發生錯誤 'talk resp' (Respond to NPC)\n"
				, "欲回應選項 $arg2 不存在.\n";
		} elsif ($arg1 eq "resp" && $arg2 ne "") {
			$arg2 += 1;
			sendTalkResponse(\$remote_socket, $talk{'ID'}, $arg2);

		} elsif ($arg1 eq "cont" && !%talk) {
			print	"發生錯誤 'talk cont' (Continue Talking to NPC)\n"
				, "你還沒有跟任何NPC交談.\n";
		} elsif ($arg1 eq "cont") {
			sendTalkContinue(\$remote_socket, $talk{'ID'});

		} elsif ($arg1 eq "no" && !%talk) {
			print	"發生錯誤 'talk no' (Talk to NPC)\n"
				, "你還沒有跟任何NPC交談.\n";
		} elsif ($arg1 eq "no") {
			$talk{'clientCancel'} = 1;
			sendTalkResponse(\$remote_socket, $talk{'ID'}, 255);

		} else {
			print	"語法錯誤 'talk' (Talk to NPC)\n"
				, qq~使用方法: talk <NPC編號 | cont | resp | answer | no> [<回應選項編號> | (數量 | "<文字>")]\n~;
		}


	} elsif ($switch eq "tank") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		if ($arg1 eq "") {
			print	"語法錯誤 'tank' (Tank for a Player)\n"
				, "使用方法: tank <玩家編號>\n";
		} elsif ($arg1 eq "stop") {
#			configModify("tankMode", 0);
			scModify("config", "tankMode", 0, 2);
		} elsif ($playersID[$arg1] eq "") {
			print	"發生錯誤 'tank' (Tank for a Player)\n"
				, "玩家 $arg1 不存在.\n";
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
#			print	"語法錯誤 'timeout' (Set a Timeout)\n"
#				, "使用方法: timeout <時間變數名稱> [<秒數>]\n";
#		} elsif ($timeout{$arg1} eq "") {
#			print	"發生錯誤 'timeout' (Set a Timeout)\n"
#				, "你想設定的時間變數 $arg1 不存在.\n";
#		} elsif ($arg2 eq "") {
#			print "時間變數 $arg1 目前的值為 $timeout{$arg1}{'timeout'}\n";
#		} else {
#			setTimeout($arg1, $arg2);
#		}

		print "$switch\n";

		if (!$params[1]) {
			print	"語法錯誤 '$switch' (Set a $switch)\n"
				, "使用方法: $switch <variable> [<value> | <null>]\n";
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
			print	"語法錯誤 'uneq' (Unequip Inventory Item)\n"
				, "使用方法: uneq <物品編號>\n";
		} elsif (!%{$chars[$config{'char'}]{'inventory'}[$arg1]}) {
			print	"發生錯誤 'uneq' (Unequip Inventory Item)\n"
				, "欲卸下裝備 $arg1 不存在.\n";
		} elsif ($chars[$config{'char'}]{'inventory'}[$arg1]{'equipped'} eq "") {
			print	"發生錯誤 'uneq' (Unequip Inventory Item)\n"
				, "你沒有裝備 $arg1.\n";
		} else {
			sendUnequip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg1]{'index'});
		}

	} elsif ($switch eq "where") {
		$map_string = getMapName($map_name, 1);
#		printC("目前位置 【$map_string: ".getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'})."】\n", "s");
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
			print	"發生錯誤 'ai pause' (Suspend AI Mission)\n"
				, "指定暫停秒數必需大於零.\n";
		} elsif ($arg1 eq "pause" && $arg2 =~ /^\d+$/) {
			print "暫停目前所有AI任務 $arg2秒\n";
			ai_clientSuspend(0, $arg2);

		} elsif ($arg1 eq "resume") {
			print "恢復目前所有AI任務\n";
			aiRemove("clientSuspend");

		} elsif ($arg1 eq "clear") {
			print "清除目前所有AI任務\n";
			undef @ai_seq;
			undef @ai_seq_args;

		} elsif ($arg1 eq "remove" && $arg2 && binFind(\@ai_seq, $arg2) eq "") {
			print	"發生錯誤 'ai remove' (Remove AI Mission)\n"
				, "欲移除任務 $arg2 不存在.\n";
		} elsif ($arg1 eq "remove" && $arg2) {
			print "移除AI任務 $arg2\n";
			aiRemove($arg2);
		} elsif ($arg1 eq "remove" && $arg2 eq "0" && !binSize(\@ai_seq)) {
			print	"發生錯誤 'ai remove' (Remove AI Mission)\n"
				, "目前並無任何AI任務.\n";
		} elsif ($arg1 eq "remove" && $arg2 eq "0") {
			print "移除第一個AI任務 $ai_seq[0]\n";
			aiRemove($ai_seq[0]);
		} elsif ($arg1 eq "remove") {
			print	"語法錯誤 'ai remove' (Remove AI Mission)\n"
				, "使用方法: ai remove <任務名稱 | 0=第一個任務>\n";
		} else {
			print	"語法錯誤 'ai' (AI Control)\n"
				, "使用方法: ai [<pause | resume | clear | remove>] [<暫停秒數 | 任務名稱 | 0=第一個任務>]\n";
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
		print "---------------------------------- 怪物列表 ---------------------$mycoords----\n";
		print "#   Lv 名稱                            你給予傷害    你受到傷害   座   標 距離\n";
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
			print "------------- 可製作箭矢物品清單 -------------\n";
			print "#   名稱                                      \n";
			for ($i = 0; $i < @arrowID; $i++) {
				next if ($arrowID[$i] eq "");
				format ARROWMAKING =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $items_lut{$arrowID[$i]}
.
				write;
			}
			print "----------------------------------------------\n";
			print "請輸入 'arrow <可製作箭矢物品編號>' 選擇\n";

		} elsif ($arg1 =~ /^\d+$/ && $arrowID[$arg1] eq "") {
			print	"發生錯誤 'arrow' (Make Arrow)\n"
				, "欲製作箭矢物品 $arg1 不存在.\n";

		} elsif ($arg1 =~ /^\d+$/) {
			sendArrowMake(\$remote_socket, $arrowID[$arg1]);
		} else {
			print	"語法錯誤 'arrow' (Make Arrow)\n"
				, "使用方法: arrow [<可製作箭矢物品編號>]\n";
		}

	} elsif ($switch eq "autospell") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			$~ = "AUTOSPELL";
			print "------------- 可自動念咒技能清單 -------------\n";
			print "#   名稱                                      \n";
			for ($i = 0; $i < @autospellID; $i++) {
				next if ($autospellID[$i] eq "");
				format AUTOSPELL =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $skillsID_lut{$autospellID[$i]}
.
				write;
			}
			print "----------------------------------------------\n";
			print "請輸入 'autospell <可自動念咒技能編號>' 選擇\n";

		} elsif ($arg1 =~ /^\d+$/ && $autospellID[$arg1] eq "") {
			print	"發生錯誤 'autospell' (Set Autospell Skill)\n"
				, "欲自動念咒技能 $arg1 不存在.\n";

		} elsif ($arg1 =~ /^\d+$/) {
			sendAutospell(\$remote_socket, $autospellID[$arg1]);
		} else {
			print	"語法錯誤 'autospell' (Set Autospell Skill)\n"
				, "使用方法: autospell [<可自動念咒技能編號>]\n";
		}

	} elsif ($switch eq "make") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		($arg3) = $input =~ /^[\s\S]*? \w+ \d+ (\d+)/;
		if ($arg1 eq "") {
			$~ = "MAKELIST";
			print "----------- 可鍛冶物品/配製藥瓶清單 ----------\n";
			print "#   名稱                                      \n";
			for ($i = 0; $i < @makeID; $i++) {
				next if ($makeID[$i] eq "");
				format MAKELIST =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $items_lut{$makeID[$i]}
.
				write;
			}
			print "----------------------------------------------\n";
			print "請輸入 'make <可鍛冶物品/配製藥瓶編號>' 選擇\n";
			print "請輸入 'make <可鍛冶物品編號> <屬性> <星角數量>' 鍛冶屬性或強悍武器\n"
				, "        <屬性: 0=無, 1=火, 2=水, 3=風, 4=地>\n";

		} elsif ($arg1 =~ /^\d+$/ && $makeID[$arg1] eq "") {
			print	"發生錯誤 'make' (Smithery and Pharmacy)\n"
				, "欲鍛冶物品/配製藥瓶 $arg1 不存在.\n";

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
					print	"發生錯誤 'make <可鍛冶物品編號> <屬性> <星角數量>' (Smithery and Pharmacy)\n"
					, "請檢查身上的 屬性石 以及 星星的角 的數量.\n";
				}
			} else {
				print	"發生錯誤 'make <可鍛冶物品編號> <屬性> <星角數量>' (Smithery and Pharmacy)\n"
					, "請檢查輸入的 <屬性> 以及 <星角數量> 是否有誤.\n";
			}

		} elsif ($arg1 eq "desc" && !$makeID[$arg2]) {
			print	"發生錯誤 'make desc' (Smithery Material Description)\n"
				, "欲檢視材料 $arg2 不存在.\n";
		} elsif ($arg1 eq "desc") {

			printDesc("make", $makeID[$params[2]], $items_lut{$makeID[$params[2]]});

		} else {
			print	"語法錯誤 'make' (Smithery and Pharmacy)\n"
				, "使用方法: make [<可鍛冶物品/配製藥瓶編號>] [<屬性>] [<星角數量>]\n"
				, "          make <desc> <可鍛冶物品/配製藥瓶編號>\n";
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

						$EstB_day = '∞' if ($EstB_day > 100);
						$EstB_day .= ' 天';
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

						$EstJ_day = '∞' if ($EstJ_day > 100);
						$EstJ_day .= ' 天';
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
			print "語法錯誤 'exp' (Show Exp Earning Speed)\n"
				, "使用方法: exp [<log | reset>]\n";
		}

	# Guild related
	} elsif ($switch eq "guild") {
#		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
#		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
#		my $ID = $chars[$config{'char'}]{'guild'}{'ID'};
#		if ($params[1] eq "" && !%{$chars[$config{'char'}]{'guild'}}) {
#			print	"發生錯誤 'guild' (Guild Functions)\n"
#				, "無法查詢公會資訊 - 你沒有公會.\n";
#		} elsif (switchInput($params[1], "i", "info", "", "information")) {
#			$~ = "GUILD";
#			$online_string = $guild{$ID}{'conMember'}."/".$guild{$ID}{'maxMember'};
#			$exp_string = $guild{$ID}{'exp'}."/".$guild{$ID}{'next_exp'};
#			print "------------------ 公會資訊 ------------------\n";
#			format GUILD =
#公會名稱: @<<<<<<<<<<<<<<<<<<<<<<
#          $guild{$ID}{'name'}
#公會等級: @>       經驗值: @>>>>>>>>>>>>>>>>>>
#          $guild{$ID}{'lvl'}, $exp_string
#會長名稱: @<<<<<<<<<<<<<<<<<<<<<<
#          $guild{$ID}{'master'}
#公會人數: @<<<<    公會成員平均等級: @>
#          $online_string, $guild{$ID}{'average'}
#
#[同盟公會]              [敵對公會]
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
#			print	"發生錯誤 'guild member' (Guild Functions)\n"
#				, "無法查詢公會成員 - 你沒有公會.\n";
#		} elsif ($params[1] eq "member") {
#			$~ = "GM";
#			print "---------------------------------- 公會成員 ----------------------------------\n";
#			print "線上 名稱                    職位                    職業     等級  繳納經驗值\n";
#			for ($i = 0; $i < $guild{$ID}{'members'}; $i++) {
#				$online_string = $guild{$ID}{'member'}[$i]{'online'} ? " Ｖ " : "";
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
#			print	"語法錯誤 'guild join' (Accept/Deny Guild Join Request)\n"
#				, "使用方法: guild join <0=拒絕 | 1=接受>\n";
#		} elsif ($params[1] eq "join" && $incomingGuild{'ID'} eq "") {
#			print	"發生錯誤 'guild join' (Join/Request to Join Guild)\n"
#				, "無法接受或拒絕公會邀請 - 沒有公會邀請.\n";
#		} elsif ($params[1] eq "join") {
#			sendGuildJoin(\$remote_socket, $incomingGuild{'ID'}, $params[2]);
#			undef %incomingGuild if ($params[2] eq "0");
#
#		} elsif ($params[1] eq "request" && !%{$chars[$config{'char'}]{'guild'}}) {
#			print	"發生錯誤 'guild request' (Request to Join Guild)\n"
#				, "無法邀請加入 - 你沒有公會.\n";
#		} elsif ($params[1] eq "request" && $playersID[$params[2]] eq "") {
#			print	"發生錯誤 'guild request' (Request to Join Guild)\n"
#				, "無法邀請加入 - 欲邀請玩家 $params[2] 不存在.\n";
#		} elsif ($params[1] eq "request") {
#			sendGuildJoinRequest(\$remote_socket, $playersID[$params[2]]);
#		}

		my $ID = $chars[$config{'char'}]{'guild'}{'ID'};

		$tmpVal{'tag'}		= $switch;
		$tmpVal{'title'}	= "Guild Functions";

		if (!switchInput($params[1], "join", "j") && !$chars[$config{'char'}]{'guild'}{'name'}) {

			$tmpVal{'text'} = "無法查詢公會資訊 - 你沒有公會";

		} elsif (!switchInput($params[1], "join", "j", "u", "user", "users") && (!%{$guild{$ID}} || !$guild{$ID}{'name'})) {

			sendGuildInfoRequest(\$remote_socket);

			for (my $i = 0; $i<=4 ; $i++) {
				sendGuildRequest(\$remote_socket, $i);
			}

		} elsif (switchInput($params[1], "i", "info", "", "information")) {

			$tmpVal{'line'} = "@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<";

			print subStrLine($tmpVal{'line'}, "Guild Info (ID: ".getHex($ID)." )", -1);

			print swrite(
				 "公會名稱: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<", [$guild{$ID}{'name'}]
				,"公會等級: @>       經驗值: @>>>>>>>>>>>>>>>>>> @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<", [$guild{$ID}{'lvl'}, "$guild{$ID}{'exp'}\/$guild{$ID}{'next_exp'}", (swrite2("(@>>>>%)",[($guild{$ID}{'exp'}/$guild{$ID}{'next_exp'} * 100)])." -".mathPercent($guild{$ID}{'exp'}, $guild{$ID}{'next_exp'}, 0, 0, 1))]
				,"會長名稱: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<", [$guild{$ID}{'master'}]
				,"公會人數: @<<<<    公會成員平均等級: @>",["$guild{$ID}{'conMember'}\/$guild{$ID}{'maxMember'}", $guild{$ID}{'average'}]
				,"Castle  : @<<<<<<<<<<<< offerPoint: @<<<<<<<<<<", [$guild{$ID}{'castle'}, $guild{$ID}{'offerPoint'}]
				,"@<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<", ['[同盟公會]', '[敵對公會]']
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

						$EstG_day = '∞' if ($EstG_day > 100);
						$EstG_day .= ' 天';
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
#				,["線上", "名稱", "職位", "職業", "等級", "繳納經驗值"]
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
				$tmpVal{'text'} = "<0=拒絕 | 1=接受>";
				$tmpVal{'type'} = 1;
			} elsif ($incomingGuild{'ID'} eq "") {
				$tmpVal{'text'} = "無法接受或拒絕公會邀請 - 沒有公會邀請";
			} else {
				sendGuildJoin(\$remote_socket, $incomingGuild{'ID'}, isBoolean($params[2], 1));
				undef %incomingGuild if (!isBoolean($params[2], 1));
			}
		} elsif (switchInput($params[1], "r", "request")) {
			$tmpVal{'tag'}  .= " $params[1]";
			$tmpVal{'title'} = "Request to Join Guild";

			if ($playersID[$params[2]] eq "") {
				$tmpVal{'text'} = "無法邀請加入工會 - 欲邀請玩家 $params[2] 不存在";
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
#			$tmpVal{'line'} = "#   名稱                          Lv";
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

				print swrite($tmpVal{'line'}, [$tmpVal{'idx'}++, ($chars[$config{'char'}]{'guild'}{'users'}{$_}{'onhere'}?"☆":""), "[".unpack("L1", $chars[$config{'char'}]{'guild'}{'users'}{$_}{'ID'})."] ".getName("player", $chars[$config{'char'}]{'guild'}{'users'}{$_}{'ID'}, 0, -1), posToCoordinate(\%{$chars[$config{'char'}]{'guild'}{'users'}{$_}{'pos'}}, 1)]);
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
			print "將指令 \'$arg1\' 的輸出結果寫入 $sc_v{'path'}{'def_logs'}"."$arg2.txt\n";
			logCommand(">> $sc_v{'path'}{'def_logs'}"."$arg2.txt", $arg1);
		} else {
			print	"語法錯誤 'log' (Log Command)\n"
				,qq~使用方法: log "<指令>" [<輸出檔名>]\n~;
		}

	# Pet related
	} elsif ($switch eq "pet") {
		($arg1) = $input =~ /^[\s\S]*? (\w+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		$~ = "PETSTATUS";
		if ($arg1 ne "catch" && $chars[$config{'char'}]{'pet'}{'online'}) {
			if ($arg1 eq ""){
				$modify_string       = ($chars[$config{'char'}]{'pet'}{'modified'}) ? "已命名" : "未命名";
				$feed_string         = ($config{'petAuto_feed'}) ? "<".sprintf("%4s", $config{'petAuto_feed'}) : "   無";
				$return_string       = ($config{'petAuto_return'}) ? ">".sprintf("%4s", $config{'petAuto_return'}) : "   無";
				$protect_string      = ($config{'petAuto_protect'}) ? "   有" : "  無";
				$temp1 = "自動收回";
				$temp2 = "裝飾品";
				$temp3 = "自動保護";
				print "------------------ 寵物資訊 ------------------\n";
				format PETSTATUS =
姓  名: @<<<<<<<<<<<<<<<<<<<<<<命  名:  @<<<<<
        $chars[$config{'char'}]{'pet'}{'name_given'}, $modify_string
種  類: @<<<<<<<<<<<<<<<       等  級:  @>>>>>
        $chars[$config{'char'}]{'pet'}{'name'}, $chars[$config{'char'}]{'pet'}{'lvl'}

滿足感: @>>>/100               自動餵食: @>>>>
        $chars[$config{'char'}]{'pet'}{'hunger'}, $feed_string
親密度: @>>>/1000              @>>>>>>>: @>>>>
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
				print "你將寵物回復成蛋的狀態\n";
			} elsif ($arg1 eq "uneq") {
				sendPetCommand(\$remote_socket, 4);
			} elsif ($arg1 eq "eq" && !%{$chars[$config{'char'}]{'inventory'}[$arg2]}) {
				print	"發生錯誤 'pet eq' (Equip Pet Accessory)\n"
					, "欲裝備物品 $arg2 不存在.\n";
			} elsif ($arg1 eq "eq") {
				sendEquip(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$arg2]{'index'}, 0);
			} else {
				print "語法錯誤 'pet' (Pet Functions)\n"
					, "使用方法: pet [<feed | show | eq | uneq | return>] [<寵物裝飾品編號>]\n";
			}
		} elsif ($arg1 eq "catch" && $arg2 eq "") {
			print	"語法錯誤 'pet catch' (Catch Pet)\n"
				, "使用方法: pet catch <怪物編號>\n";
		} elsif ($arg1 eq "catch" && $monstersID[$arg2] eq "") {
			print	"發生錯誤 'pet catch' (Catch Pet)\n"
				, "怪物 $arg2 不存在.\n";
		} elsif ($arg1 eq "catch") {
			sendPetCatch(\$remote_socket, $monstersID[$arg2]);

		} else {
			print	"發生錯誤 'pet' (Pet Functions)\n"
				, "請先輸入 'is <攜帶用孵蛋器編號>' 孵化寵物.\n";
		}

	# Pet call
	} elsif ($switch eq "call") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		if ($arg1 eq "") {
			$~ = "CALL";
			print "-------------- 可孵化寵物蛋清單 --------------\n";
			print "#   名稱                                      \n";
			for ($i = 0; $i < @callID; $i++) {
				next if ($callID[$i] eq "");
				format CALL =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $chars[$config{'char'}]{'inventory'}[$callID[$i]]{'name'}
.
				write;
			}
			print "----------------------------------------------\n";
			print "請輸入 'call <可孵化寵物蛋編號>' 選擇\n";

		} elsif ($arg1 =~ /^\d+$/ && $callID[$arg1] eq "") {
			print	"發生錯誤 'call' (Call Pet)\n"
				, "欲孵化寵物蛋 $arg1 不存在.\n";

		} elsif ($arg1 =~ /^\d+$/) {
			undef $callInvIndex;
			$callInvIndex = $callID[$arg1];
			sendPetCall(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$callID[$arg1]]{'index'});
		} else {
			print	"語法錯誤 'call' (Call Pet)\n"
				, "使用方法: call [<可孵化寵物蛋編號>]\n";
		}

	# Vendor related
	} elsif ($switch eq "shop") {
		($arg1) = $input =~ /^[\s\S]*? ([\w\d]+)/;
		($arg2) = $input =~ /^[\s\S]*? \w+ (\d+)/;
		if ($arg1 eq "" && !$shop{'opened'}) {
			print	"發生錯誤 'shop' (Browse Vending Shop)\n"
				, "請先輸入 'shop open' 擺\設你的攤位.\n";
		} elsif ($arg1 eq "") {
			$~ = "VENDORTITLE";
			$title_string = (length($myShop{'shop_title'}) > 36) ? substr($myShop{'shop_title'}, 0, 36) : $myShop{'shop_title'};
			$owner_string = $chars[$config{'char'}]{'name'};
			print "---------------------------------- 我的商店 ----------------------------------\n";
			format VENDORTITLE =
商店名稱: @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< 擁有者: @<<<<<<<<<<<<<<<<<<<<<<
          $title_string, $owner_string

.
			write;
			print "#   名稱                                       種類      數量  金  額(Z)  賣出\n";
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
			print "小計: 目前賺進 ".toZeny($shop{'earned'})." Zeny\n" if ($shop{'earned'});

		} elsif ($arg1 eq "close" && !$shop{'opened'}) {
			print	"發生錯誤 'shop close' (Close Vending Shop)\n"
				, "請先輸入 'shop open' 擺\設你的攤位.\n";
		} elsif ($arg1 eq "close") {

			event_shop_close();

		} elsif ($arg1 eq "open" && $currentChatRoom ne "") {
			print	"發生錯誤 'shop open' (Open Vending Shop)\n"
				, "你必須先離開聊天室.\n";
		} elsif ($arg1 eq "open" && $shop{'opened'}) {
				print	"發生錯誤 'shop open' (Open Vending Shop)\n"
					, "你已經擺\設好一個攤位了.\n";
		} elsif ($arg1 eq "open") {

			unshift @ai_seq, "shopauto";
			unshift @ai_seq_args, {};

#			if ($chars[$config{'char'}]{'sitting'}) {
#				stand();
#				print "請維持站立姿勢一會兒再輸入 'shop open' 指令, 以免引起懷疑\n";
#
#				ai_event_auto_parseInput("shop open");
#			} else {
				sendShopOpen(\$remote_socket);
#			}

		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/ && $shop{'opened'}) {
			if (!%{$articles[$arg2]}) {
				print	"發生錯誤 'shop desc' (Vending Shop Item Description)\n"
					, "欲檢視攤位物品 $arg2 不存在.\n";
			} else {
				printDesc(0, $articles[$arg2]{'itemID'}, fixingName(\%{$articles[$arg2]}));
			}
		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/ && $currentVendingShop ne "") {
			if (!%{$vendorItemList[$arg2]}) {
				print	"發生錯誤 'shop desc' (Vending Shop Item Description)\n"
					, "欲檢視攤位物品 $arg2 不存在.\n";
			} else {
				printDesc(0, $vendorItemList[$arg2]{'itemID'}, fixingName(\%{$vendorItemList[$arg2]}));
			}
		} elsif ($arg1 eq "desc" && $arg2 =~ /^\d+$/) {
			print	"發生錯誤 'shop desc' (Vending Shop Item Description)\n"
				, "欲檢視攤位物品 $arg2 不存在.\n";

		} elsif ($arg1 =~ /^\d+$/ && $vendorListID[$arg1] ne "" && $shop{'opened'}) {
			print	"發生錯誤 'shop' (Browse Vending Shop)\n"
				, "擺\攤的時候必須專心, 不然可能會被順手牽羊噢.\n";
		} elsif ($arg1 =~ /^\d+$/ && $vendorListID[$arg1] eq "") {
			print	"發生錯誤 'shop' (Browse Vending Shop)\n"
				, "欲瀏覽攤位 $arg1 不存在.\n";
		} elsif ($arg1 =~ /^\d+$/) {
			sendGetShopList(\$remote_socket, $vendorListID[$arg1]);

		} else {
			print "語法錯誤 'shop' (Vending Shop Functions)\n"
				, "使用方法: shop [<攤位編號 | open | close | desc>] [<攤位物品編號>]\n";
		}

	} elsif ($switch eq "pick") {
		($arg1) = $input =~ /^[\s\S]*? (\d+)/;
		($arg2) = $input =~ /^[\s\S]*? \d+ (\d+)$/;
		if ($arg1 eq "") {
			print	"語法錯誤 'pick' (Pick Vending Shop Item)\n"
				, "使用方法: pick <攤位物品編號> [<數量>]\n";
		} elsif ($currentVendingShop eq "") {
			print	"發生錯誤 'pick' (Pick Vending Shop Item)\n"
				, "尚未瀏覽攤位, 輸入 'vsl' 可查看攤位列表.\n";
		} elsif ($vendorItemList[$arg1] eq "") {
			print	"發生錯誤 'pick' (Pick Vending Shop Item)\n"
				, "欲挑選物品 $arg1 不存在.\n";
		} else {
			$arg2 = ($arg2 <= 0) ? 1 : $arg2;
			print "你挑選了: $vendorItemList[$arg1]{'name'} x $arg2 (from $vendorList{$currentVendingShop}{'title'})\n";
			sendBuyFromShop(\$remote_socket, $currentVendingShop, $arg2, $arg1);
		}

	} elsif ($switch eq "vsl") {
		$~ = "VENDORLIST";
		print "---------------------------------- 攤位列表 ----------------------------------\n";
		print "#   標題                                  擁有者                              \n";
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
		print "請輸入 'shop <攤位編號>' 瀏覽販賣物品\n";

	# Locational Skill List
	} elsif ($switch eq "sl") {
		$~ = "SLIST";
		$mycoords = getFormattedCoords($chars[$config{'char'}]{'pos_to'}{'x'}, $chars[$config{'char'}]{'pos_to'}{'y'});
		print "--------------------- 地面持續型技能列表 --------$mycoords----\n";
		print "類型 名稱          施術者                         座   標 距離\n";
		for ($i = 0; $i < @spellsID; $i++) {
			next if ($spellsID[$i] eq "");
			$slcoords = getFormattedCoords($spells{$spellsID[$i]}{'pos'}{'x'}, $spells{$spellsID[$i]}{'pos'}{'y'});
			$dSDist = int(distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$spells{$spellsID[$i]}{'pos'}}));
			if (%{$monsters{$spells{$spellsID[$i]}{'sourceID'}}}) {
				$name_string = "$monsters{$spells{$spellsID[$i]}{'sourceID'}}{'name'} ($monsters{$spells{$spellsID[$i]}{'sourceID'}}{'binID'})";
			} elsif (%{$players{$spells{$spellsID[$i]}{'sourceID'}}}) {
				$name_string = "$players{$spells{$spellsID[$i]}{'sourceID'}}{'name'} ($players{$spells{$spellsID[$i]}{'sourceID'}}{'binID'})";
			} elsif ($spells{$spellsID[$i]}{'sourceID'} eq $accountID) {
				$name_string = "你";
			} else {
				$name_string = "不明人物";
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
				print "-------------- 額外說明 --------------\n";
				print "  數  ↖  ↑  ↗  使用方法:           \n";
				print "  字    ７８９      依照想前進的方向輸\n";
				print "  盤  ←４  ６→    入 '數字 [<格數>]'\n";
				print "  ：    １２３      如未指定格數自動以\n";
				print "      ↙  ↓  ↘    基本步數($z)代入。\n";
				print "--------------------------------------\n";
				print "輸入 '5 <格數>' 可設定基本步數        \n";

			} else {
#				configModify($config{'handyMove_step'}, $arg1);
				scModify("config", "handyMove_step", $arg1, 2);
			}
		} elsif ($switch eq "6") {
			handyMove("東", $arg1);
		} elsif ($switch eq "4") {
			handyMove("西", $arg1);
		} elsif ($switch eq "2") {
			handyMove("南", $arg1);
		} elsif ($switch eq "8") {
			handyMove("北", $arg1);
		} elsif ($switch eq "9") {
			handyMove("東北", $arg1);
		} elsif ($switch eq "7") {
			handyMove("西北", $arg1);
		} elsif ($switch eq "3") {
			handyMove("東南", $arg1);
		} elsif ($switch eq "1") {
			handyMove("西南", $arg1);
		}

	} elsif ($switch eq "beep") {
		if ($params[1] eq "stop" && $playingWave ne "") {
			playWave("stop", "100%", "test");
		} elsif ($params[1] eq "stop" && $playingWave eq "") {
			print "發生錯誤 'beep stop' (Stop Beep)\n"
				, "目前沒有播放任何音效.\n";
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
			print	"語法錯誤 'beep' (Beep Functions)\n"
				, "使用方法: beep <death | gm | iif | iig | c | g | p | pm | s | stop>\n";
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
				$c = $charID_lut{$sc_v{'friend'}{'member'}[$i]{'AID'}}{'online'}?"☆":"";

				$text .= swrite2("@>> @>", [$i, $c])." $sc_v{'friend'}{'member'}[$i]{'name'}\n";

			}

			$text .= subStrLine(0);

			print $text;

		} elsif (isNum($params[1]) && $params[2] ne "") {
			if ($sc_v{'friend'}{'member'}[$params[1]]{'name'} eq "") {
				FunctionError($switch, "Private Message To Frineds", "玩家 $params[1] 不在你的朋友名單中");
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
		print "錯誤的指令 : $switch \n";
	}

END_IPPUT:
	undef %tmpVal, @params;
}

1;