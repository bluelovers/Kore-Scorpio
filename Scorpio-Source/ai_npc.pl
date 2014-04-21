
sub ai_event_npc_autoBuy {
	#####AUTO BUY#####

	if (switchInput($ai_seq[0], "", "route", "attack") && checkTimeOut('ai_buyAuto')) {
		undef $ai_v{'temp'}{'found'};
		$i = 0;
		while (1) {
			last if (!$config{"buyAuto_$i"} || !$config{"buyAuto_$i"."_npc"});
			$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
			if ($config{"buyAuto_$i"."_minAmount"} ne "" && $config{"buyAuto_$i"."_maxAmount"} ne ""
				&& ($ai_v{'temp'}{'invIndex'} eq ""
				|| ($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} <= $config{"buyAuto_$i"."_minAmount"}
				&& $chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"})
				)
				&& (
					!$config{"buyAuto_$i"."_inNpcMapOnly"}
					|| (
						$config{"buyAuto_$i"."_inNpcMapOnly"}
#						&& $field{'name'} eq $npcs_lut{$config{"buyAuto_$i"."_npc"}}{'map'}
						&& checkNpcMap($field{'name'}, $config{"buyAuto_$i"."_npc"})
					)
				)
				&& ai_checkZeny($config{"buyAuto_$i"."_zeny"})
			) {
				$ai_v{'temp'}{'found'} = 1;
				last;
			}
			$i++;
		}
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
			unshift @ai_seq, "talkAuto";
			unshift @ai_seq_args, {};
		}
		timeOutStart('ai_buyAuto');
	}

	return 0 if ($ai_seq[0] ne "buyAuto");

	if ($ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'talkAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'} = 1;
			unshift @ai_seq, "talkAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
			timeOutStart('ai_route_npcTalk');
		}
	} elsif (checkTimeOut('ai_buyAuto_wait') && timeOut(\%{$timeout{'ai_buyAuto_wait_buy'}})) {
		$i = 0;
		undef $ai_seq_args[0]{'index'};

		while (1) {
			last if (
				!$config{"buyAuto_$i"}
#				|| !%{$npcs_lut{$config{"buyAuto_$i"."_npc"}}}
				|| ai_npc_check($config{"buyAuto_$i"."_npc"})
			);

			$ai_seq_args[0]{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"buyAuto_$i"});
			if (!$ai_seq_args[0]{'index_failed'}{$i} && $config{"buyAuto_$i"."_maxAmount"} ne "" && ($ai_seq_args[0]{'invIndex'} eq ""
				|| $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} < $config{"buyAuto_$i"."_maxAmount"})) {
				$ai_seq_args[0]{'index'} = $i;
				last;
			}
			$i++;
		}
		if ($ai_seq_args[0]{'index'} eq ""
			|| ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'}
			&& checkTimeOut('ai_buyAuto_giveup'))) {
			$ai_seq_args[0]{'done'} = 1;
			return;
		}
		undef $ai_v{'temp'}{'do_route'};

#		ai_getNpc(\%{$ai_v{'temp'}{'npcData'}}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"});
#
#		if ($field{'name'} ne $ai_v{'temp'}{'npcData'}{'map'}) {
#			$ai_v{'temp'}{'do_route'} = 1;
#		} else {
#			$ai_v{'temp'}{'distance'} = distance(\%{$ai_v{'temp'}{'npcData'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
#			if ($ai_v{'temp'}{'distance'} > 14) {
#				$ai_v{'temp'}{'do_route'} = 1;
#			}
#		}
#
#		print "buyAuto_$ai_seq_args[0]{'index'} - do_route : $ai_v{'temp'}{'do_route'}\n";

		if ($field{'name'} ne $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			# Reset warpedToSave if not really do
#			if ($ai_seq_args[0]{'warpedToSave'} && (!$ai_seq_args[0]{'mapChanged'} || $field{'name'} ne $config{'saveMap'})) {
#				undef $ai_seq_args[0]{'warpedToSave'};
#			}

			ai_getNpcTalk_warpedToSave_reset($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"});

#			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} &&  (1 || !$cities_lut{$field{'name'}.'.rsw'}) && !$indoors_lut{$field{'name'}.'.rsw'}) {
			if (ai_getNpcTalk_warpedToSave($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				timeOutStart('ai_buyAuto_wait');
#Karasu Start
			# Buy position change
#			} elsif ($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"}){
##				getField(qq~$sc_v{'path'}{'fields'}/$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.fld~, \%{$ai_seq_args[0]{'dest_field'}});
#				getFieldNPC($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"});
#				do {
#					$ai_v{'temp'}{'randX'} = $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'} + int(rand() * ($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"} * 2 + 1)) - $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"};
#					$ai_v{'temp'}{'randY'} = $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'} + int(rand() * ($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"} * 2 + 1)) - $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"};
#				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
#							|| $ai_v{'temp'}{'randX'} == $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'} && $ai_v{'temp'}{'randY'} == $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'});
#				$coord_string = getFormattedCoords($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'});
#				print qq~計算路徑前往自動買物地點 - $maps_lut{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.'.rsw'}($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}): $coord_string\n~;
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}, 0, 0, 1, 0, 0, 1);
##Karasu End
#			} else {
#				$coord_string = getFormattedCoords($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'});
#				print qq~計算路徑前往自動買物地點 - $maps_lut{$npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}.'.rsw'}($npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}): $coord_string\n~;
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'x'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'pos'}{'y'}, $npcs_lut{$config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				ai_route_npc('買物', $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc_dist"});
			}
		} else {
			if ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $ai_seq_args[0]{'index'}) {
				undef $ai_seq_args[0]{'itemID'};
				if ($config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"} != $config{"buyAuto_$ai_seq_args[0]{'lastIndex'}"."_npc"}) {
					undef $ai_seq_args[0]{'sentBuy'};
				}
				timeOutStart('ai_buyAuto_giveup');
			}
			$ai_seq_args[0]{'lastIndex'} = $ai_seq_args[0]{'index'};
			if ($ai_seq_args[0]{'itemID'} eq "") {
				foreach (keys %items_lut) {
					if (lc($items_lut{$_}) eq lc($config{"buyAuto_$ai_seq_args[0]{'index'}"})) {
						$ai_seq_args[0]{'itemID'} = $_;
					}
				}
				if ($ai_seq_args[0]{'itemID'} eq "") {
					$ai_seq_args[0]{'index_failed'}{$ai_seq_args[0]{'index'}} = 1;
					print "autoBuy index $ai_seq_args[0]{'index'} failed\n" if ($config{'debug'});
					return;
				}
			}

#			if ($ai_seq_args[0]{'sentBuy'} <= 1) {
#				if (!$ai_seq_args[0]{'sentBuy'} && $config{'buyAuto_smartEquip'} ne "") {
#					ai_equip_special($config{'buyAuto_smartEquip'});
#					sleep(0.5);
#				}
#				sendTalk(\$remote_socket, pack("L1", $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) if !$ai_seq_args[0]{'sentBuy'};
#				sendGetStoreList(\$remote_socket, pack("L1", $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"})) if $ai_seq_args[0]{'sentBuy'};
#				$ai_seq_args[0]{'sentBuy'}++;
#				timeOutStart('ai_buyAuto_wait');
#				return;
#			}

			return if (ai_npc_autoTalk($ai_seq[0], \%{$ai_v{'temp'}{'npcData'}}));

			if ($ai_seq_args[0]{'invIndex'} ne "") {
				sendBuy(\$remote_socket, $ai_seq_args[0]{'itemID'}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'});
			} else {
				sendBuy(\$remote_socket, $ai_seq_args[0]{'itemID'}, $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxAmount"});
			}

#			koreSE2.2 //

			undef $ai_seq_args[0]{'rebuy'};
			if (
				$config{'cartAuto'}
				&& $cart{'weight_max'} > 0
				&& ($cart{'weight'}/$cart{'weight_max'})*100 < $config{'cartMaxWeight'}
				&& $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxCartAmount"} > 0
			) {
				$ai_v{'temp'}{'cartIndex'} = findIndexString_lc(\@{$cart{'inventory'}}, "name", $config{"buyAuto_$ai_seq_args[0]{'index'}"});
				if (
					$ai_v{'temp'}{'cartIndex'} eq ""
					|| ($cart{'inventory'}[$ai_v{'temp'}{'cartIndex'}]{'amount'} < $config{"buyAuto_$ai_seq_args[0]{'index'}"."_maxCartAmount"})
				) {
					$ai_seq_args[0]{'reBuy'} = 1;
					$timeout{'ai_buyAuto_giveup'}{'time'} = time;
				}
			}

#			// koreSE2.2

			timeOutStart('ai_buyAuto_wait_buy');
		}
	}
}

sub ai_event_npc_autoSell {
	#####AUTO SELL#####

#	$ai_v{'temp'}{'inNpcMap'} = (getMapID($field{'name'}) eq getMapID($npcs_lut{$config{"sellAuto_npc"}}{'map'}));

	$ai_v{'temp'}{'inNpcMap'} = checkNpcMap($field{'name'}, $config{"sellAuto_npc"});

	AUTOSELL: {

	if (
		switchInput($ai_seq[0], "", "route")
		&& $config{'sellAuto'}
		&& $config{'sellAuto_npc'} ne ""
#		&& percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}
		&& &getItemsMaxWeight()
		&& (
			!$config{"sellAuto_inNpcMapOnly"}
			|| (
				$config{"sellAuto_inNpcMapOnly"}
				&&
				$ai_v{'temp'}{'inNpcMap'}
			)
		)
	) {
		$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
		if ($ai_v{'temp'}{'ai_route_index'} ne "") {
			$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
		}
		if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_sellAutoCheck()) {
			unshift @ai_seq, "talkAuto";
			unshift @ai_seq_args, {};

			$sc_v{'temp'}{'ai'}{'itemsMaxWeight'} = 1;
		}
	}

	return 0 if ($ai_seq[0] ne "sellAuto");

	if ($ai_seq_args[0]{'done'}) {
		if ($ai_seq_args[0]{'sentSell'}) {
			$talk{'clientCancel'} = 1;
#			sendTalkResponse(\$remote_socket, pack("L1",$config{'sellAuto_npc'}), 255);
			sendTalkResponse(\$remote_socket, pack("L1",$ai_v{'temp'}{'npcData'}{'ID'}), 255);
		}
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'} = 1;
			unshift @ai_seq, "storageAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
			timeOutStart('ai_storageAuto');
		}
	} elsif (checkTimeOut('ai_sellAuto')) {
		if (
			!$config{'sellAuto'}
#			|| !%{$npcs_lut{$config{'sellAuto_npc'}}}
			|| ai_npc_check($config{'sellAuto_npc'})
			|| (
				!$ai_seq_args[0]{'sentSell'}
				&& !ai_sellAutoCheck()
			)
		) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOSELL;
		}

		undef $ai_v{'temp'}{'do_route'};

		ai_getNpc(\%{$ai_v{'temp'}{'npcData'}}, $config{'sellAuto_npc'});

		if ($field{'name'} ne $ai_v{'temp'}{'npcData'}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$ai_v{'temp'}{'npcData'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
#
#		if ($field{'name'} ne $npcs_lut{$config{'sellAuto_npc'}}{'map'}) {
#			$ai_v{'temp'}{'do_route'} = 1;
#		} else {
#			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'sellAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
#
#			if ($ai_v{'temp'}{'distance'} > 14) {
#				$ai_v{'temp'}{'do_route'} = 1;
#			}
#		}
		if ($ai_v{'temp'}{'do_route'}) {
			# Reset warpedToSave if not really do
#			if ($ai_seq_args[0]{'warpedToSave'} && (!$ai_seq_args[0]{'mapChanged'} || $field{'name'} ne $config{'saveMap'})) {
#				undef $ai_seq_args[0]{'warpedToSave'};
#			}

			ai_getNpcTalk_warpedToSave_reset();

#			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && (1 || !$cities_lut{$field{'name'}.'.rsw'}) && !$indoors_lut{$field{'name'}.'.rsw'}) {
			if (ai_getNpcTalk_warpedToSave($config{'sellAuto_npc'})) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				timeOutStart('ai_sellAuto');
#Karasu Start
			# Sell position change
#			} elsif ($config{'sellAuto_npc_dist'}) {
##				getField("$sc_v{'path'}{'fields'}/$npcs_lut{$config{'sellAuto_npc'}}{'map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
#				getFieldNPC($config{'sellAuto_npc'});
#				do {
#					$ai_v{'temp'}{'randX'} = $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'} + int(rand() * ($config{'sellAuto_npc_dist'} * 2 + 1)) - $config{'sellAuto_npc_dist'};
#					$ai_v{'temp'}{'randY'} = $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'} + int(rand() * ($config{'sellAuto_npc_dist'} * 2 + 1)) - $config{'sellAuto_npc_dist'};
#				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
#							|| $ai_v{'temp'}{'randX'} == $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'} && $ai_v{'temp'}{'randY'} == $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'});
#				print "計算路徑前往自動賣物地點 - $maps_lut{$npcs_lut{$config{'sellAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'sellAuto_npc'}}{'map'}): ".getFormattedCoords($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $npcs_lut{$config{'sellAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
##Karasu End
#			} else {
#				print "計算路徑前往自動賣物地點 - $maps_lut{$npcs_lut{$config{'sellAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'sellAuto_npc'}}{'map'}): ".getFormattedCoords($npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'sellAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'sellAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				ai_route_npc('賣物', $config{'sellAuto_npc'}, $config{'sellAuto_npc_dist'});
			}
		} else {
#			if ($ai_seq_args[0]{'sentSell'} <= 1) {
#				sendTalk(\$remote_socket, pack("L1", $config{'sellAuto_npc'})) if !$ai_seq_args[0]{'sentSell'};
#				sendGetSellList(\$remote_socket, pack("L1", $config{'sellAuto_npc'})) if $ai_seq_args[0]{'sentSell'};
#				$ai_seq_args[0]{'sentSell'}++;
#				timeOutStart('ai_sellAuto');
#				last AUTOSELL;
#			}

			last AUTOSELL if (ai_npc_autoTalk($ai_seq[0], \%{$ai_v{'temp'}{'npcData'}}));

			$ai_seq_args[0]{'done'} = 1;
			for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
				next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne "" || $chars[$config{'char'}]{'inventory'}[$i]{'borned'});
				if (
					$items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'sell'}
					&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}
				) {
					if (
						$ai_seq_args[0]{'lastIndex'} ne ""
						&& $ai_seq_args[0]{'lastIndex'} == $chars[$config{'char'}]{'inventory'}[$i]{'index'}
						&& checkTimeOut('ai_sellAuto_giveup')
					) {
						last AUTOSELL;
					} elsif (
						$ai_seq_args[0]{'lastIndex'} eq ""
						|| $ai_seq_args[0]{'lastIndex'} != $chars[$config{'char'}]{'inventory'}[$i]{'index'}
					) {
						timeOutStart('ai_sellAuto_giveup');
					}
					undef $ai_seq_args[0]{'done'};
					$ai_seq_args[0]{'lastIndex'} = $chars[$config{'char'}]{'inventory'}[$i]{'index'};
					sendSell(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'});
					timeOutStart('ai_sellAuto');
					last AUTOSELL;
				}
			}
		}
	}

	} #END OF BLOCK AUTOSELL
}

sub ai_event_npc_autoStorage {



#storageAuto - chobit aska 20030128
#####AUTO STORAGE#####

	AUTOSTORAGE: {

	if ($config{'storageAuto'} && $config{'storageAuto_npc'} ne "") {

#		if (switchInput($ai_seq[0], "", "route") && percent_weight(\%{$chars[$config{'char'}]}) >= $config{'itemsMaxWeight'}) {
		if (switchInput($ai_seq[0], "", "route") && &getItemsMaxWeight()) {
			$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
			if ($ai_v{'temp'}{'ai_route_index'} ne "") {
				$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
			}
			if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && ai_storageAutoCheck()) {
				unshift @ai_seq, "talkAuto";
				unshift @ai_seq_args, {};

				$sc_v{'temp'}{'ai'}{'itemsMaxWeight'} = 1;
			}
#storagegetAuto Start - Ayon 20030421
		} elsif (switchInput($ai_seq[0], "", "route", "attack") && $config{'storageAuto'} && $config{'storageAuto_npc'} ne "" && checkTimeOut('ai_storageAuto')) {
			undef $ai_v{'temp'}{'found'};
			my $inNpcMap = checkNpcMap($field{'name'}, $config{"storageAuto_npc"});

			$i = 0;
			while (1) {
				last if (!$config{"storagegetAuto_$i"});
				$ai_v{'temp'}{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"storagegetAuto_$i"});
				if (
					!$stockVoid{'storage'}[$i]
					&& (
						$ai_v{'temp'}{'invIndex'} eq ""
						|| mathInNum($chars[$config{'char'}]{'inventory'}[$ai_v{'temp'}{'invIndex'}]{'amount'}, $config{"storagegetAuto_$i"."_minAmount"}, $config{"storagegetAuto_$i"."_maxAmount"}, 2)
					)
					&& sc_isTrue($config{"storagegetAuto_$i"."_inNpcMapOnly"}, $inNpcMap)
					&& ai_checkZeny($config{"storagegetAuto_zeny"})
				) {
					$ai_v{'temp'}{'found'} = 1;
					last;
				}
				$i++;
			}
			$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
			if ($ai_v{'temp'}{'ai_route_index'} ne "") {
				$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
			}
			if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1) && $ai_v{'temp'}{'found'}) {
				unshift @ai_seq, "talkAuto";
				unshift @ai_seq_args, {};
			}
			timeOutStart(
				'ai_storageAuto'
			);
		}

	}
#storagegetAuto End - Ayon 20030421

	return 0 if ($ai_seq[0] ne "storageAuto");

	if ($ai_seq_args[0]{'done'}) {
		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'buyAuto'}) {
			$ai_v{'temp'}{'ai'}{'completedAI'}{'storageAuto'} = 1;
			unshift @ai_seq, "buyAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
			timeOutStart('ai_buyAuto_wait');
		}
	} elsif (checkTimeOut('ai_storageAuto')) {
#		if (!$config{'storageAuto'} || !%{$npcs_lut{$config{'storageAuto_npc'}}}) {
#			$ai_seq_args[0]{'done'} = 1;
#			last AUTOSTORAGE;
#		}
		if (!$config{'storageAuto'} || ai_npc_check($config{'storageAuto_npc'})) {
			$ai_seq_args[0]{'done'} = 1;
			last AUTOSTORAGE;
		}

		undef $ai_v{'temp'}{'do_route'};
#		if ($field{'name'} ne $npcs_lut{$config{'storageAuto_npc'}}{'map'}) {
#			$ai_v{'temp'}{'do_route'} = 1;
#		} else {
#			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$config{'storageAuto_npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
#			if ($ai_v{'temp'}{'distance'} > 14) {
#				$ai_v{'temp'}{'do_route'} = 1;
#			}
#		}

#		undef $ai_v{'temp'}{'npcData'};
		ai_getNpc(\%{$ai_v{'temp'}{'npcData'}}, $config{'storageAuto_npc'});

		if ($field{'name'} ne $ai_v{'temp'}{'npcData'}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$ai_v{'temp'}{'npcData'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}
		if ($ai_v{'temp'}{'do_route'}) {
			# Reset warpedToSave if not really do
#			if ($ai_seq_args[0]{'warpedToSave'} && (!$ai_seq_args[0]{'mapChanged'} || $field{'name'} ne $config{'saveMap'})) {
#				undef $ai_seq_args[0]{'warpedToSave'};
#			}

			ai_getNpcTalk_warpedToSave_reset();

#			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} &&  (1 || !$cities_lut{$field{'name'}.'.rsw'}) && !$indoors_lut{$field{'name'}.'.rsw'}) {
			if (ai_getNpcTalk_warpedToSave($config{'storageAuto_npc'})) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				timeOutStart('ai_storageAuto');
#Karasu Start
			# Storage position change
#			} elsif ($config{'storageAuto_npc_dist'}) {
##				getField("$sc_v{'path'}{'fields'}/$npcs_lut{$config{'storageAuto_npc'}}{'map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
#				getFieldNPC($config{'storageAuto_npc'});
#				do {
#					$ai_v{'temp'}{'randX'} = $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'} + int(rand() * ($config{'storageAuto_npc_dist'} * 2 + 1)) - $config{'storageAuto_npc_dist'};
#					$ai_v{'temp'}{'randY'} = $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'} + int(rand() * ($config{'storageAuto_npc_dist'} * 2 + 1)) - $config{'storageAuto_npc_dist'};
#				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
#							|| $ai_v{'temp'}{'randX'} == $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'} && $ai_v{'temp'}{'randY'} == $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'});
#				print "計算路徑前往自動存倉地點 - $maps_lut{$npcs_lut{$config{'storageAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'storageAuto_npc'}}{'map'}): ".getFormattedCoords($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $npcs_lut{$config{'storageAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
##Karasu End
#			} else {
#				print "計算路徑前往自動存倉地點 - $maps_lut{$npcs_lut{$config{'storageAuto_npc'}}{'map'}.'.rsw'}($npcs_lut{$config{'storageAuto_npc'}}{'map'}): ".getFormattedCoords($npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'x'}, $npcs_lut{$config{'storageAuto_npc'}}{'pos'}{'y'}, $npcs_lut{$config{'storageAuto_npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				ai_route_npc('存倉', $config{'storageAuto_npc'}, $config{'storageAuto_npc_dist'});
			}
		} else {
#Karasu Start
			# Let user define steps
#			if (!$ai_seq_args[0]{'npc'}{'sentStorage'}) {
#
#				if ($config{'storagegetAuto_uneqArrow'}){
#					for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
#						# Equip arrow related
#						next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne "0");
#
#						print "[EVENT] 開倉前自動卸下箭矢\n";
#
#						parseInput("uneq 0");
#
#						sleep(0.1);
#
#						last;
#					}
#				}
#
#				sendTalk(\$remote_socket, pack("L1", $config{'storageAuto_npc'}));
#				@{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $config{'storageAuto_npc_steps'});
#				$ai_seq_args[0]{'npc'}{'sentStorage'} = 1;
#				timeOutStart('ai_storageAuto');
#				last AUTOSTORAGE;
#			} elsif (defined(@{$ai_seq_args[0]{'npc'}{'steps'}})) {
#				if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
#					sendTalkContinue(\$remote_socket, pack("L1", $config{'storageAuto_npc'}));
#				} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
##					sendTalkCancel(\$remote_socket, pack("L1", $config{'storageAuto_npc'}));
#				} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i) {
#					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i;
#					if ($ai_v{'temp'}{'arg'} ne "") {
#						sendTalkAnswerNum(\$remote_socket, pack("L1", $config{'storageAuto_npc'}), $ai_v{'temp'}{'arg'});
#					}
#				} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i) {
#					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i;
#					if ($ai_v{'temp'}{'arg'} ne "") {
#						sendTalkAnswerWord(\$remote_socket, pack("L1", $config{'storageAuto_npc'}), $ai_v{'temp'}{'arg'});
#					}
#				} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i) {
#					($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
#					if ($ai_v{'temp'}{'arg'} ne "") {
#						$ai_v{'temp'}{'arg'}++;
#						sendTalkResponse(\$remote_socket, pack("L1", $config{'storageAuto_npc'}), $ai_v{'temp'}{'arg'});
#					}
#				} else {
#					undef @{$ai_seq_args[0]{'npc'}{'steps'}};
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#				timeOutStart('ai_storageAuto');
#				last AUTOSTORAGE;
#			}

			last AUTOSTORAGE if (ai_npc_autoTalk($ai_seq[0], \%{$ai_v{'temp'}{'npcData'}}));

			$ai_seq_args[0]{'done'} = 1 ;
#Karasu End
			if (!$ai_seq_args[0]{'storagegetStart'}) {
				for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}};$i++) {
					next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne "" || $chars[$config{'char'}]{'inventory'}[$i]{'borned'});
					if ($items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'storage'}
						&& $chars[$config{'char'}]{'inventory'}[$i]{'amount'} > $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'}) {
						if ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $chars[$config{'char'}]{'inventory'}[$i]{'index'}
							&& checkTimeOut('ai_storageAuto_giveup')) {
							last AUTOSTORAGE;
						} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $chars[$config{'char'}]{'inventory'}[$i]{'index'}) {
							timeOutStart('ai_storageAuto_giveup');
						}
						undef $ai_seq_args[0]{'done'};
						$ai_seq_args[0]{'lastIndex'} = $chars[$config{'char'}]{'inventory'}[$i]{'index'};
						sendStorageAdd(\$remote_socket, $chars[$config{'char'}]{'inventory'}[$i]{'index'}, $chars[$config{'char'}]{'inventory'}[$i]{'amount'} - $items_control{lc($chars[$config{'char'}]{'inventory'}[$i]{'name'})}{'keep'});
						timeOutStart('ai_storageAuto');
						last AUTOSTORAGE;
					}
				}
				last AUTOSTORAGE if (ai_event_itemToStorage());
			}
#storagegetAuto Start - Ayon 20030421
			if (!$ai_seq_args[0]{'storagegetStart'} && $ai_seq_args[0]{'done'} == 1) {
				$ai_seq_args[0]{'storagegetStart'} = 1;
				undef $ai_seq_args[0]{'done'};
				last AUTOSTORAGE;
			}
			$i = 0;
			undef $ai_seq_args[0]{'index'};
			while (1) {
				last if (!$config{"storagegetAuto_$i"});
				$ai_seq_args[0]{'invIndex'} = findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $config{"storagegetAuto_$i"});
				if (!$ai_seq_args[0]{'index_failed'}{$i} && $config{"storagegetAuto_$i"."_maxAmount"} ne "" && !$stockVoid{'storage'}[$i]
					&& ($ai_seq_args[0]{'invIndex'} eq ""
					|| $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'} < $config{"storagegetAuto_$i"."_maxAmount"})) {
					$ai_seq_args[0]{'index'} = $i;
					last;
				}
				$i++;
			}
			if ($ai_seq_args[0]{'index'} eq ""
				|| ($ai_seq_args[0]{'lastIndex'} ne "" && $ai_seq_args[0]{'lastIndex'} == $ai_seq_args[0]{'index'}
				&& checkTimeOut('ai_storageAuto_giveup'))) {
				$ai_seq_args[0]{'done'} = 1;
#Karasu Start
				if ($config{'recordStorage'}) {
					open(STORAGELOG, "> $sc_v{'path'}{'def_logs'}"."StorageLog.txt") if ($config{'recordStorage'} > 0);
#					open(STORAGELOG, ">> $sc_v{'path'}{'def_logs'}"."StorageLog.txt") if ($config{'recordStorage'} eq "2");
					select(STORAGELOG);
					print "[".getFormattedDate(int(time))."]\n";
					print "[".$servers[$config{'server'}]{'name'}." - ".$chars[$config{'char'}]{'name'}."]\n";
					close(STORAGELOG);
					logCommand(">> $sc_v{'path'}{'def_logs'}"."StorageLog.txt", "storage");
				}
#Karasu End
				sendStorageClose(\$remote_socket);
				last AUTOSTORAGE;
			} elsif ($ai_seq_args[0]{'lastIndex'} eq "" || $ai_seq_args[0]{'lastIndex'} != $ai_seq_args[0]{'index'}) {
				timeOutStart('ai_storageAuto_giveup');
			}

			undef $ai_seq_args[0]{'done'};
			undef $ai_seq_args[0]{'storageInvIndex'};

			$ai_seq_args[0]{'lastIndex'} = $ai_seq_args[0]{'index'};
			$ai_seq_args[0]{'storageInvIndex'} = findIndexString_lc(\@{$storage{'inventory'}}, "name", $config{"storagegetAuto_$ai_seq_args[0]{'index'}"});
			if ($ai_seq_args[0]{'storageInvIndex'} eq "") {
				$stockVoid{'storage'}[$ai_seq_args[0]{'index'}] = 1;
				last AUTOSTORAGE;
			} else {
				$storagegetAmount = ($ai_seq_args[0]{'invIndex'} ne "")
					? $config{"storagegetAuto_$ai_seq_args[0]{'index'}"."_maxAmount"} - $chars[$config{'char'}]{'inventory'}[$ai_seq_args[0]{'invIndex'}]{'amount'}
					: $config{"storagegetAuto_$ai_seq_args[0]{'index'}"."_maxAmount"};
				if ($storagegetAmount > $storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'amount'}) {
					$storagegetAmount = $storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'amount'};
					$stockVoid{'storage'}[$ai_seq_args[0]{'index'}] = 1;
				}
			}

			$record{"storageGet"}{$storage{'inventory'}[$ai_seq_args[0]{'storageInvIndex'}]{'nameID'}} += $storagegetAmount;

			sendStorageGet(\$remote_socket, $ai_seq_args[0]{'storageInvIndex'}, $storagegetAmount);

			timeOutStart('ai_storageAuto');
#storagegetAuto End - Ayon 20030421
		}
	}

	} #END OF BLOCK AUTOSTORAGE
}

sub ai_event_npc_autoTalk_data {
	my $tmp = "";
	my ($i, $mode) = @_;

	if ($config{'talkAuto'} > 1) {
		$i = int($i);

		$tmp = "_${i}";
	}

	if ($mode && $i > 0 && $config{'talkAuto'} == 1) {
		return "";
	} elsif ($mode) {
		return $config{"talkAuto${tmp}_npc"};
	} else {
		my $tdo = $sc_v{'temp'}{'ai'}{'talkAuto'}{'do'};

		undef %{$sc_v{'temp'}{'ai'}{'autoTalk'}};

		$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'}			= $tdo;
		$sc_v{'temp'}{'ai'}{'talkAuto'}{'index'}		= $i;

		$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}			= $config{"talkAuto${tmp}_npc"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'}		= $config{"talkAuto${tmp}_npc_dist"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_steps'}		= $config{"talkAuto${tmp}_npc_steps"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'hp'}			= $config{"talkAuto${tmp}_hp"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'sp'}			= $config{"talkAuto${tmp}_sp"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'peace'}		= $config{"talkAuto${tmp}_peace"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'}		= $config{"talkAuto${tmp}_broken"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'end_warpedToSave'}	= $config{"talkAuto${tmp}_end_warpedToSave"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'zeny'}			= $config{"talkAuto${tmp}_zeny"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'}		= $config{"talkAuto${tmp}_inNpcMapOnly"};

		$sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItem'}		= $config{"talkAuto${tmp}_checkItem"};
		$sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItemEx'}		= $config{"talkAuto${tmp}_checkItemEx"};

		$sc_v{'temp'}{'ai'}{'autoTalk'}{'loop'}			= $config{"talkAuto${tmp}_loop"};

	}
}

sub ai_event_npc_autoTalk {
	#Karasu Start
	#####AUTO TALK#####

	my $i = 0;

	AUTOTALK: {

	if (switchInput($ai_seq[0], "", "route", "sitAuto", "attack") && $config{'talkAuto'}) {

		undef $sc_v{'temp'}{'ai'}{'talkAuto'}{'do'};

		while (!$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} && ai_event_npc_autoTalk_data($i, 1) ne "") {

#			last if (ai_event_npc_autoTalk_data($i, 1) eq "");

			ai_event_npc_autoTalk_data($i);

#			$ai_v{'temp'}{'inNpcMap'} = inTargetMap($field{'name'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}, $sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'});
			$ai_v{'temp'}{'inNpcMap'} = inTargetNpcMap($field{'name'}, $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}, $sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'});

			if (
				(
					switchInput($ai_seq[0], "", "route", "sitAuto")
					|| (
						$ai_seq[0] eq "attack"
						&& !$sc_v{'temp'}{'ai'}{'autoTalk'}{'peace'}
					)
				)
#				&& %{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}}
				&& !ai_npc_check($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'})
				&& (
					(
						!$sc_v{'temp'}{'ai'}{'autoTalk'}{'hp'}
						|| ($sc_v{'temp'}{'ai'}{'autoTalk'}{'hp'} && percent_hp(\%{$chars[$config{'char'}]}) <= $sc_v{'temp'}{'ai'}{'autoTalk'}{'hp'})
					) && (
						!$sc_v{'temp'}{'ai'}{'autoTalk'}{'sp'}
						|| ($sc_v{'temp'}{'ai'}{'autoTalk'}{'sp'} && percent_sp(\%{$chars[$config{'char'}]}) <= $sc_v{'temp'}{'ai'}{'autoTalk'}{'sp'})
					)
				)
				&& (
					!$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'}
					|| (
						$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'}
						&&
						$ai_v{'temp'}{'inNpcMap'}
					)
				)
				&& (
					!$sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'}
					|| ($sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'} && getBrokenItems(\@{$chars[$config{'char'}]{'inventory'}}) >= $sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'})
				)
				&& ai_checkZeny($sc_v{'temp'}{'ai'}{'autoTalk'}{'zeny'})
			) {
				undef $ai_v{'temp'}{'found'};

				if (!$ai_v{'temp'}{'found'} && $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItem'}) {
					undef @array;
					splitUseArray(\@array, $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItem'}, ",");
					foreach (@array) {
						next if (!$_);
						if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) eq "") {
							$ai_v{'temp'}{'found'} = 1;
							last;
						}
					}
				}

				if (!$ai_v{'temp'}{'found'} && $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItemEx'}) {
					undef @array;
					undef $ai_v{'temp'}{'foundEx'};
					splitUseArray(\@array, $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItemEx'}, ",");
					foreach (@array) {
						next if (!$_);

						if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) ne "") {
							$ai_v{'temp'}{'foundEx'} = 1;
							last;
						}
					}
					$ai_v{'temp'}{'found'} = 1 if (!$ai_v{'temp'}{'foundEx'});
				}

				if (!$ai_v{'temp'}{'found'}) {
					$ai_v{'temp'}{'ai_route_index'} = binFind(\@ai_seq, "route");
					if ($ai_v{'temp'}{'ai_route_index'} ne "") {
						$ai_v{'temp'}{'ai_route_attackOnRoute'} = $ai_seq_args[$ai_v{'temp'}{'ai_route_index'}]{'attackOnRoute'};
					}
					if (!($ai_v{'temp'}{'ai_route_index'} ne "" && $ai_v{'temp'}{'ai_route_attackOnRoute'} <= 1)) {
						unshift @ai_seq, "talkAuto";
						unshift @ai_seq_args, {};

						$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
						$sc_v{'temp'}{'ai'}{'talkAuto'}{'index'} = $i;
					}
				}
			}
			$i++;
		}
	}

	return 0 if ($ai_seq[0] ne "talkAuto");

	if ($ai_seq_args[0]{'done'}) {

#		print "結束自動對話\n";

		undef %{$ai_v{'temp'}{'ai'}};
		%{$ai_v{'temp'}{'ai'}{'completedAI'}} = %{$ai_seq_args[0]{'completedAI'}};
		shift @ai_seq;
		shift @ai_seq_args;
		if (!$ai_v{'temp'}{'ai'}{'completedAI'}{'sellAuto'}) {

			if ($sc_v{'temp'}{'ai'}{'talkAuto'}{'do'}) {
				if ($sc_v{'temp'}{'ai'}{'autoTalk'}{'end_warpedToSave'} && $field{'name'} ne $config{'saveMap'}) {
					printC("[EVENT] talkAuto: end_warpedToSave 啟動順移回城\n", "event");

					delete $sc_v{'temp'}{'ai'}{'talkAuto'};

					useTeleport(2);
				} elsif ($field{'name'} ne $config{'saveMap'}) {
					delete $sc_v{'temp'}{'ai'}{'talkAuto'};
				}
				$ai_v{'temp'}{'ai'}{'completedAI'}{'talkAuto'} = 1;
				delete $sc_v{'temp'}{'ai'}{'itemsMaxWeight'};
			} else {
				$ai_v{'temp'}{'ai'}{'completedAI'}{'talkAuto'} = -1;
			}

			unshift @ai_seq, "sellAuto";
			unshift @ai_seq_args, {%{$ai_v{'temp'}{'ai'}}};
			timeOutStart('ai_sellAuto');
		}

	} elsif (checkTimeOut('ai_route_npcTalk') && !%{$sc_v{'temp'}{'ai'}{'autoTalk'}}) {

		$i = $sc_v{'temp'}{'ai'}{'talkAuto'}{'index'} if ($sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} > 0);

		ai_event_npc_autoTalk_data($i);

#		$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;

#		$ai_seq_args[0]{'done'} = 1 if (!%{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}});

		timeOutStart('ai_route_npcTalk');

	} elsif (checkTimeOut('ai_route_npcTalk')) {

#		ai_event_npc_autoTalk_data();

#		$ai_v{'temp'}{'inNpcMap'} = inTargetMap($field{'name'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}, $sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'});
		$ai_v{'temp'}{'inNpcMap'} = inTargetNpcMap($field{'name'}, $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}, $sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'});

		if (
			$config{'talkAuto'}
			&& $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'} ne ""
#			&& %{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}}
			&& !ai_npc_check($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'})
			&& (
				!$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'}
				|| (
					$sc_v{'temp'}{'ai'}{'autoTalk'}{'inNpcMapOnly'}
					&&
					$ai_v{'temp'}{'inNpcMap'}
				)
			)
			&& (
				!$sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'}
				|| ($sc_v{'temp'}{'ai'}{'autoTalk'}{'broken'} && getBrokenItems(\@{$chars[$config{'char'}]{'inventory'}}))
			)
			&& ai_checkZeny($sc_v{'temp'}{'ai'}{'autoTalk'}{'zeny'})
		) {

			undef $ai_v{'temp'}{'found'};

			if (!$ai_v{'temp'}{'found'} && $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItem'}) {
				undef @array;
				splitUseArray(\@array, $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItem'}, ",");
				foreach (@array) {
					next if (!$_);
					if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) eq "") {
						$ai_v{'temp'}{'found'} = 1;
						last;
					}
				}
			}

			if (!$ai_v{'temp'}{'found'} && $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItemEx'}) {
				undef @array;
				undef $ai_v{'temp'}{'foundEx'};
				splitUseArray(\@array, $sc_v{'temp'}{'ai'}{'autoTalk'}{'checkItemEx'}, ",");
				foreach (@array) {
					next if (!$_);

					if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) ne "") {
						$ai_v{'temp'}{'foundEx'} = 1;
						last;
					}
				}
				$ai_v{'temp'}{'found'} = 1 if (!$ai_v{'temp'}{'foundEx'});
			}

			if (!$ai_v{'temp'}{'found'}) {
				$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
				delete $sc_v{'temp'}{'ai'}{'itemsMaxWeight'};
			} else {
				delete $sc_v{'temp'}{'ai'}{'itemsMaxWeight'};

				$ai_seq_args[0]{'done'} = 1;
				last AUTOTALK;
			}
		} elsif ($sc_v{'temp'}{'ai'}{'itemsMaxWeight'} && $config{'saveMap'} ne $field{'name'} && $config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} && !$indoors_lut{$field{'name'}.'.rsw'}) {
			$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
			$ai_seq_args[0]{'warpedToSave'} = 1;
			useTeleport(2);
			timeOutStart('ai_route_npcTalk');
			last AUTOTALK;
		} else {
			delete $sc_v{'temp'}{'ai'}{'itemsMaxWeight'};

			$ai_seq_args[0]{'done'} = 1;

#			print "$config{'talkAuto'} 找不到對話npc $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'} ".ai_npc_check($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'})."\n";

			last AUTOTALK;
		}

		undef $ai_v{'temp'}{'do_route'};

		ai_getNpc(\%{$ai_v{'temp'}{'npcData'}}, $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'});

		if ($field{'name'} ne $ai_v{'temp'}{'npcData'}{'map'}) {
			$ai_v{'temp'}{'do_route'} = 1;
		} else {
			$ai_v{'temp'}{'distance'} = distance(\%{$ai_v{'temp'}{'npcData'}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
			if ($ai_v{'temp'}{'distance'} > 14) {
				$ai_v{'temp'}{'do_route'} = 1;
			}
		}

#		if ($field{'name'} ne $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}) {
#			$ai_v{'temp'}{'do_route'} = 1;
#		} else {
#			$ai_v{'temp'}{'distance'} = distance(\%{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}});
#			if ($ai_v{'temp'}{'distance'} > 14) {
#				$ai_v{'temp'}{'do_route'} = 1;
#			}
#		}
		if ($ai_v{'temp'}{'do_route'}) {
			# Reset warpedToSave if not really do
#			if ($ai_seq_args[0]{'warpedToSave'} && (!$ai_seq_args[0]{'mapChanged'} || $field{'name'} ne $config{'saveMap'})) {
#				undef $ai_seq_args[0]{'warpedToSave'};
#			}

			undef $ai_v{'temp'}{'found'};

			$ai_v{'temp'}{'found'} = 1 if ($field{'name'} eq $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'});

			if (!$ai_v{'temp'}{'found'} && @{$record{'warp'}{'memo'}}) {
				undef %{$sc_v{'ai'}{'warpTo'}};

				if ($config{'autoWarp_checkItem'} ne "") {
					undef @array;
					splitUseArray(\@array, $config{'autoWarp_checkItem'}, ",");
					foreach (@array) {
						next if (!$_);
						if (findIndexString_lc(\@{$chars[$config{'char'}]{'inventory'}}, "name", $_) eq "") {
							$ai_v{'temp'}{'found'} = 1;
							last;
						}
					}
				}

				if (!$ai_v{'temp'}{'found'}) {
					for ($i=0; $i<@{$record{'warp'}{'memo'}}; $i++) {
						next if ($record{'warp'}{'memo'}[$i] eq "" || $field{'name'} eq $record{'warp'}{'memo'}[$i] || $record{'warp'}{'memo'}[$i] eq $config{'saveMap'});

						if ($record{'warp'}{'memo'}[$i] eq $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}) {

							$sc_v{'ai'}{'warpTo'}{'map'} = $record{'warp'}{'memo'}[$i];

							$ai_v{'temp'}{'found'} = 1;

							$ai_seq_args[0]{'warpedToSave'} = 1;

#								print "preferRoute_warp $sc_v{'ai'}{'warpTo'}{'map'}\n";

							print "[talkAuto] 使用傳送之陣通往自動談話地點 ".getMapName($sc_v{'ai'}{'warpTo'}{'map'}, 1)."\n";

							parseInput("warp me");

#							last;
							last AUTOTALK;
						}
					}
				} else {
					undef $ai_v{'temp'}{'found'};
				}
			}

			ai_getNpcTalk_warpedToSave_reset();

#			if ($config{'saveMap'} ne "" && $config{'saveMap_warpToBuyOrSell'} && !$ai_seq_args[0]{'warpedToSave'} &&  (1 || !$cities_lut{$field{'name'}.'.rsw'}) && !$indoors_lut{$field{'name'}.'.rsw'}) {
			if (ai_getNpcTalk_warpedToSave($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'})) {
				$ai_seq_args[0]{'warpedToSave'} = 1;
				useTeleport(2);
				timeOutStart('ai_route_npcTalk');
#Karasu Start
			# Talk position change
#			} elsif ($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'}) {
##				getField("$sc_v{'path'}{'fields'}/$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
#				getFieldNPC($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'});
#				do {
#					$ai_v{'temp'}{'randX'} = $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'x'} + int(rand() * ($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'} * 2 + 1)) - $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'};
#					$ai_v{'temp'}{'randY'} = $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'y'} + int(rand() * ($sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'} * 2 + 1)) - $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'};
#				} while (ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
#							|| $ai_v{'temp'}{'randX'} == $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'x'} && $ai_v{'temp'}{'randY'} == $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'y'});
#				print "計算路徑前往自動談話地點: $maps_lut{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}.'.rsw'}($npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}): ".getFormattedCoords($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
##Karasu End
#			} else {
#				print "計算路徑前往自動談話地點: $maps_lut{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}.'.rsw'}($npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}): ".getFormattedCoords($npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'x'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'y'})."\n";
#				ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'x'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}{'y'}, $npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'map'}, 0, 0, 1, 0, 0, 1);
			} else {
				ai_route_npc('談話', $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}, $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_dist'});
			}
		} else {
#			$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'} = $config{"talkAuto_${i}_npc"};
#			$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_steps'} = $config{"talkAuto_${i}_npc_steps"};

			ai_npc_autoTalk($ai_seq[0], \%{$ai_v{'temp'}{'npcData'}});

#			if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
#				sendTalk(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}));
#				@{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_steps'});
#				$ai_seq_args[0]{'npc'}{'sentTalk'} = 1;
#
#				$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
#
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
#				sendTalkContinue(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}));
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
#				#sendTalkCancel(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}));
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i) {
#				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i;
#				if ($ai_v{'temp'}{'arg'} ne "") {
#					sendTalkAnswerNum(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}), $ai_v{'temp'}{'arg'});
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i) {
#				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i;
#				if ($ai_v{'temp'}{'arg'} ne "") {
#					sendTalkAnswerWord(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}), $ai_v{'temp'}{'arg'});
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			} else {
#				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
#				if ($ai_v{'temp'}{'arg'} ne "") {
#					$ai_v{'temp'}{'arg'}++;
#					sendTalkResponse(\$remote_socket, pack("L1", $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}), $ai_v{'temp'}{'arg'});
#				}
#				$ai_seq_args[0]{'npc'}{'step'}++;
#			}
##			$ai_seq_args[0]{'done'} = 1 if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "");
#			if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "") {
#				$ai_seq_args[0]{'done'} = 1;
#				$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
#			}
			timeOutStart('ai_route_npcTalk');
		}
	}
	} #END OF BLOCK AUTOTALK
#Karasu End
}

sub ai_route_npc {
	my ($tag, $ID, $dist) = @_;
#	my @parseNpc = split /\s/, $ID;
	my %tmpNpc;

	if ($config{'parseNpcAuto'} && !%{$npcs_lut{$ID}}) {
		my @parseNpc = split /\s/, $ID;
		$tmpNpc{'map'}		= $parseNpc[1];
		$tmpNpc{'pos'}{'x'}	= $parseNpc[2];
		$tmpNpc{'pos'}{'y'}	= $parseNpc[3];
	} elsif (%{$npcs_lut{$ID}}) {
		$tmpNpc{'map'}		= $npcs_lut{$ID}{'map'};
		$tmpNpc{'pos'}{'x'}	= $npcs_lut{$ID}{'pos'}{'x'};
		$tmpNpc{'pos'}{'y'}	= $npcs_lut{$ID}{'pos'}{'y'};
	}

#	if ($config{'parseNpcAuto'} && switchInput($parseNpc[0], "<npc>", "<auto>", "auto")) {
#		$tmpNpc{'map'}		= $parseNpc[1];
#		$tmpNpc{'pos'}{'x'}	= $parseNpc[2];
#		$tmpNpc{'pos'}{'y'}	= $parseNpc[3];
#	} else {
#		$tmpNpc{'map'}		= $npcs_lut{$ID}{'map'};
#		$tmpNpc{'pos'}{'x'}	= $npcs_lut{$ID}{'pos'}{'x'};
#		$tmpNpc{'pos'}{'y'}	= $npcs_lut{$ID}{'pos'}{'y'};
#	}

	if ($dist) {
#		getField("$sc_v{'path'}{'fields'}/$npcs_lut{$config{'storageAuto_npc'}}{'map'}.fld", \%{$ai_seq_args[0]{'dest_field'}});
		getFieldNPC($ID);
		do {
			$ai_v{'temp'}{'randX'} = $tmpNpc{'pos'}{'x'} + int(rand() * ($dist * 2 + 1)) - $dist;
			$ai_v{'temp'}{'randY'} = $tmpNpc{'pos'}{'y'} + int(rand() * ($dist * 2 + 1)) - $dist;
		} while (
			ai_route_getOffset(\%{$ai_seq_args[0]{'dest_field'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})
			|| $ai_v{'temp'}{'randX'} == $tmpNpc{'pos'}{'x'}
			&& $ai_v{'temp'}{'randY'} == $tmpNpc{'pos'}{'y'}
		);
		print "計算路徑前往自動${tag}地點 - $maps_lut{$tmpNpc{'map'}.'.rsw'}($tmpNpc{'map'}): ".getFormattedCoords($ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'})."\n";
		ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $ai_v{'temp'}{'randX'}, $ai_v{'temp'}{'randY'}, $tmpNpc{'map'}, 0, 0, 1, 0, 0, 1, $tag, $ID, $dist);
#Karasu End
	} else {
		print "計算路徑前往自動${tag}地點 - $maps_lut{$tmpNpc{'map'}.'.rsw'}($tmpNpc{'map'}): ".getFormattedCoords($tmpNpc{'pos'}{'x'}, $tmpNpc{'pos'}{'y'})."\n";
		ai_route(\%{$ai_v{'temp'}{'returnHash'}}, $tmpNpc{'pos'}{'x'}, $tmpNpc{'pos'}{'y'}, $tmpNpc{'map'}, 0, 0, 1, 0, 0, 1, $tag, $ID, $dist);
	}
}

sub getFieldNPC {
	my $ID = shift;
	my $npcMap;
#	my @parseNpc = split /\s/, $ID;

#	if ($config{'parseNpcAuto'} && switchInput($parseNpc[0], "<npc>", "<auto>", "auto")) {
#		$npcMap = $parseNpc[1];
#	} else {
#		$npcMap = $npcs_lut{$ID}{'map'};
#	}

	if ($npcs_lut{$ID}{'map'} ne "") {
		$npcMap = $npcs_lut{$ID}{'map'};
	} elsif ($config{'parseNpcAuto'}) {
		my @parseNpc = split /\s/, $ID;
		$npcMap = $parseNpc[1] if switchInput($parseNpc[0], "<npc>", "<auto>", "auto");
	}

	$npcMap = $sc_v{'parseMsg'}{'map'} if ($npcMap eq "");

	getField(qq~$sc_v{'path'}{'fields'}/${npcMap}.fld~, \%{$ai_seq_args[0]{'dest_field'}});
}

sub checkNpcMap {
	my ($name, $ID) = @_;
	my $val;

#	my @parseNpc = split(/ /, $npc);
#	my @parseNpc = split /\s/, $npc;

#	if ($config{'parseNpcAuto'} && switchInput($parseNpc[0], "<npc>", "<auto>", "auto")) {
#		$val = (getMapID($name) eq getMapID($parseNpc[1]));
#	} else {
#		$val = (getMapID($name) eq getMapID($npcs_lut{$npc}{'map'}));
#	}

	if ($npcs_lut{$ID}{'map'} ne "") {
		$val = (getMapID($name) eq getMapID($npcs_lut{$ID}{'map'}));
	} elsif ($config{'parseNpcAuto'}) {
		my @parseNpc = split /\s/, $ID;
		$val = (getMapID($name) eq getMapID($parseNpc[1])) if switchInput($parseNpc[0], "<npc>", "<auto>", "auto");
	}

#	print "checkNpcMap ( $name , $npc ) = $val\n";

	return $val;
}

sub ai_getNpcTalk_warpedToSave_reset {
#	my $ID = shift;

	if (
		$ai_seq_args[0]{'warpedToSave'}
		&& (
			!$ai_seq_args[0]{'mapChanged'}
#			|| (
#				$field{'name'} ne $config{'saveMap'}
##				&& !checkNpcMap($field{'name'}, $ID)
#			)
		)
	) {
		undef $ai_seq_args[0]{'warpedToSave'};
	}

#	if ($ai_seq_args[0]{'warpedToSave'} && !$ai_seq_args[0]{'mapChanged'} && $field{'name'} ne $config{'saveMap'}) {
#		undef $ai_seq_args[0]{'warpedToSave'};
#	}
}

sub ai_getNpcTalk_warpedToSave {
	my $ID = shift;

	return (
		$config{'saveMap'} ne ""
		&& $config{'saveMap_warpToBuyOrSell'}
		&& !$ai_seq_args[0]{'warpedToSave'}
		&&  (1 || !$cities_lut{$field{'name'}.'.rsw'})
		&& !$indoors_lut{$field{'name'}.'.rsw'}
		&& $field{'name'} ne $config{'saveMap'}
		&& !checkNpcMap($field{'name'}, $ID)
#		&& $field{'name'} ne $npcs_lut{$ID}{'map'}
	)?1:0;
}

sub ai_npc_check {
	my $ID = shift;
#	my @parseNpc = split /\s/, $ID;
	my $val;

#	if ($config{'parseNpcAuto'}) {
#		$val = (!%{$npcs_lut{$ID}} && !switchInput($parseNpc[0], "<npc>", "<auto>", "auto"));
#	} else {
#		$val = (!%{$npcs_lut{$ID}})?1:0;
#	}

	if ($config{'parseNpcAuto'} && !%{$npcs_lut{$ID}}) {
		my @parseNpc = split /\s/, $ID;
		$val = !switchInput($parseNpc[0], "<npc>", "<auto>", "auto");
	} elsif (!%{$npcs_lut{$ID}}) {
		$val = 1;
	}

#	print "ai_npc_check ( $ID ) = $val\n";

	return $val;
}

sub ai_getNpc {
	my ($tmpNpc, $ID) = @_;
#	my @parseNpc = split /\s/, $ID;

	if ($npcs_lut{$ID}{'map'} ne "") {
		$$tmpNpc{'ID'}		= $ID;
		$$tmpNpc{'map'}		= $npcs_lut{$ID}{'map'};
		$$tmpNpc{'pos'}{'x'}	= $npcs_lut{$ID}{'pos'}{'x'};
		$$tmpNpc{'pos'}{'y'}	= $npcs_lut{$ID}{'pos'}{'y'};
		$$tmpNpc{'init'}	= 1;
	} elsif ($config{'parseNpcAuto'}) {
		my @parseNpc = split /\s/, $ID;

		return 0 unless switchInput($parseNpc[0], "<npc>", "<auto>", "auto");

		$$tmpNpc{'ID'}		= $parseNpc[0] if (
			!$$tmpNpc{'init'}
			|| $$tmpNpc{'map'} ne $parseNpc[1]
			|| $$tmpNpc{'pos'}{'x'} ne $parseNpc[2]
			|| $$tmpNpc{'pos'}{'y'} ne $parseNpc[3]
		);
		$$tmpNpc{'map'}		= $parseNpc[1];
		$$tmpNpc{'pos'}{'x'}	= $parseNpc[2];
		$$tmpNpc{'pos'}{'y'}	= $parseNpc[3];
		$$tmpNpc{'init'}	= 1;
	}

#	if ($config{'parseNpcAuto'} && switchInput($parseNpc[0], "<npc>", "<auto>", "auto")) {
#		$$tmpNpc{'ID'}		= $parseNpc[0] if (
#			!$$tmpNpc{'init'}
#			|| $$tmpNpc{'map'} ne $parseNpc[1]
#			|| $$tmpNpc{'pos'}{'x'} ne $parseNpc[2]
#			|| $$tmpNpc{'pos'}{'y'} ne $parseNpc[3]
#		);
#		$$tmpNpc{'map'}		= $parseNpc[1];
#		$$tmpNpc{'pos'}{'x'}	= $parseNpc[2];
#		$$tmpNpc{'pos'}{'y'}	= $parseNpc[3];
#		$$tmpNpc{'init'}	= 1;
#	} else {
#		$$tmpNpc{'ID'}		= $ID;
#		$$tmpNpc{'map'}		= $npcs_lut{$ID}{'map'};
#		$$tmpNpc{'pos'}{'x'}	= $npcs_lut{$ID}{'pos'}{'x'};
#		$$tmpNpc{'pos'}{'y'}	= $npcs_lut{$ID}{'pos'}{'y'};
#		$$tmpNpc{'init'}	= 1;
#	}
}

sub ai_npc_autoTalk {
	my $key = shift;
	my $tmpNpc = shift;
	my $ID;
	my $val;

	if ($config{'parseNpcAuto'} && switchInput($$tmpNpc{'ID'}, "<npc>", "<auto>", "auto")) {
		undef $ai_v{'temp'}{'nearest_npc_id'};

		$ai_v{'temp'}{'nearest_distance'} = 9999;

		for ($i = 0; $i < @npcsID; $i++) {
			next if ($npcsID[$i] eq "");
			$ai_v{'temp'}{'distance'} = distance(\%{$npcs{$npcsID[$i]}{'pos'}}, \%{$chars[$config{'char'}]{'pos_to'}}, 1);

			if (
				$npcs{$npcsID[$i]}{'pos'}{'x'} == $$tmpNpc{'pos'}{'x'}
				&& $npcs{$npcsID[$i]}{'pos'}{'y'} == $$tmpNpc{'pos'}{'y'}
			) {
				$ai_v{'temp'}{'nearest_npc_id'} = $npcsID[$i];

				last;
			}
		}

		if ($ai_v{'temp'}{'nearest_npc_id'} eq "") {
			for ($i = 0; $i < @npcsID; $i++) {
				next if ($npcsID[$i] eq "");

				$ai_v{'temp'}{'distance'} = distance(\%{$npcs{$npcsID[$i]}{'pos'}}, \%{$$tmpNpc{'pos'}}, 1);

				if ($ai_v{'temp'}{'distance'} < $ai_v{'temp'}{'nearest_distance'}) {
					$ai_v{'temp'}{'nearest_npc_id'} = $npcsID[$i];
					$ai_v{'temp'}{'nearest_distance'} = $ai_v{'temp'}{'distance'};
				}
			}
		}

		if ($ai_v{'temp'}{'nearest_npc_id'} ne "") {
#			printC("$$tmpNpc{'ID'} Target NPC Pos: ".getFormattedCoords($$tmpNpc{'pos'}{'x'}, $$tmpNpc{'pos'}{'y'})."\n", "white");
#			printC("Found nearest NPC: $npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'nameID'} $npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'name'} ($npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'binID'}) ".getFormattedCoords($npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'pos'}{'x'}, $npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'pos'}{'y'})." - Dist: ".distance(\%{$chars[$config{'char'}]{'pos_to'}}, \%{$npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'pos'}}, 1)."\n", "white");

			$ID = $npcs{$ai_v{'temp'}{'nearest_npc_id'}}{'nameID'};
			$$tmpNpc{'ID'} = $ID;
		} else {
			printC("[ERROR] 錯誤: 找不到 NPC 接近 ".getFormattedCoords($$tmpNpc{'pos'}{'x'}, $$tmpNpc{'pos'}{'y'})." 該 NPC 可能被移除\n", "alert");
		}
	} else {
		$ID = $$tmpNpc{'ID'};
	}

	if ($key eq "storageAuto") {
		$ID = $config{'storageAuto_npc'} if (!$config{'parseNpcAuto'});

		if (!$ai_seq_args[0]{'npc'}{'sentStorage'}) {

			if ($config{'storagegetAuto_uneqArrow'}){
				for ($i = 0; $i < @{$chars[$config{'char'}]{'inventory'}}; $i++) {
					# Equip arrow related
					next if (!%{$chars[$config{'char'}]{'inventory'}[$i]} || $chars[$config{'char'}]{'inventory'}[$i]{'equipped'} ne "0");

					print "[EVENT] 開倉前自動卸下箭矢\n";

					parseInput("uneq 0");

					sleep(0.1);

					last;
				}
			}

			sendTalk(\$remote_socket, pack("L1", $ID));
			@{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $config{'storageAuto_npc_steps'});
			$ai_seq_args[0]{'npc'}{'sentStorage'} = 1;
#			timeOutStart('ai_storageAuto');

			$val = 1;

		} elsif (defined(@{$ai_seq_args[0]{'npc'}{'steps'}})) {
			if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
				sendTalkContinue(\$remote_socket, pack("L1", $ID));
			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
#					sendTalkCancel(\$remote_socket, pack("L1", $ID));
			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i) {
				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i;
				if ($ai_v{'temp'}{'arg'} ne "") {
					sendTalkAnswerNum(\$remote_socket, pack("L1", $ID), $ai_v{'temp'}{'arg'});
				}
			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i) {
				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i;
				if ($ai_v{'temp'}{'arg'} ne "") {
					sendTalkAnswerWord(\$remote_socket, pack("L1", $ID), $ai_v{'temp'}{'arg'});
				}
			} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i) {
				($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
				if ($ai_v{'temp'}{'arg'} ne "") {
					$ai_v{'temp'}{'arg'}++;
					sendTalkResponse(\$remote_socket, pack("L1", $ID), $ai_v{'temp'}{'arg'});
				}
			} else {
				undef @{$ai_seq_args[0]{'npc'}{'steps'}};
			}
			$ai_seq_args[0]{'npc'}{'step'}++;
#			timeOutStart('ai_storageAuto');

			$val = 1;
		}

		timeOutStart('ai_storageAuto') if $val;
	} elsif ($key eq "sellAuto") {
		$ID = $config{'sellAuto_npc'} if (!$config{'parseNpcAuto'});

		if ($ai_seq_args[0]{'sentSell'} <= 1) {
			sendTalk(\$remote_socket, pack("L1", $ID)) if !$ai_seq_args[0]{'sentSell'};
			sendGetSellList(\$remote_socket, pack("L1", $ID)) if $ai_seq_args[0]{'sentSell'};
			$ai_seq_args[0]{'sentSell'}++;
			timeOutStart('ai_sellAuto');

			$val = 1;

		}
	} elsif ($key eq "buyAuto") {
		$ID = $config{"buyAuto_$ai_seq_args[0]{'index'}"."_npc"} if (!$config{'parseNpcAuto'});

		if ($ai_seq_args[0]{'sentBuy'} <= 1) {
			if (!$ai_seq_args[0]{'sentBuy'} && $config{'buyAuto_smartEquip'} ne "") {
				ai_equip_special($config{'buyAuto_smartEquip'});
				sleep(0.5);
			}
			sendTalk(\$remote_socket, pack("L1", $ID)) if !$ai_seq_args[0]{'sentBuy'};
			sendGetStoreList(\$remote_socket, pack("L1", $ID)) if $ai_seq_args[0]{'sentBuy'};
			$ai_seq_args[0]{'sentBuy'}++;
			timeOutStart('ai_buyAuto_wait');

			$val = 1;
		}
	} elsif ($key eq "talkAuto") {
		$ID = $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'} if (!$config{'parseNpcAuto'} || 1);

		if (!$ai_seq_args[0]{'npc'}{'sentTalk'}) {
#			undef $ai_v{'temp'}{'pos'};
#			undef $ai_v{'temp'}{'nearest_npc_id'};
#			$ai_v{'temp'}{'nearest_distance'} = 9999;
#
#			%{$ai_v{'temp'}{'pos'}} = %{$npcs_lut{$sc_v{'temp'}{'ai'}{'autoTalk'}{'npc'}}{'pos'}};
#
#			for ($i = 0; $i < @npcsID; $i++) {
#				next if ($npcsID[$i] eq "");
#
#				if (
#					$npcs{$npcsID[$i]}{'pos'}{'x'} == $ai_v{'temp'}{'pos'}{'x'}
#					&& $npcs{$npcsID[$i]}{'pos'}{'x'} == $ai_v{'temp'}{'pos'}{'x'}
#				) {
##								$ai_v{'temp'}{'nearest_npc_id'} = $npcs{$npcsID[$i]}{'nameID'};
#
#					$ai_v{'temp'}{'nearest_npc_id'} = $npcsID[$i];
#
#					last;
#				}
#			}
#
#			if ($ai_v{'temp'}{'nearest_npc_id'} eq "") {
#				for ($i = 0; $i < @npcsID; $i++) {
#					next if ($npcsID[$i] eq "");
#					$ai_v{'temp'}{'distance'} = distance(\%{$npcs{$npcsID[$i]}{'pos'}}, \%{$ai_v{'temp'}{'pos'}});
#					if ($ai_v{'temp'}{'distance'} < $ai_v{'temp'}{'nearest_distance'}) {
#						$ai_v{'temp'}{'nearest_npc_id'} = $npcsID[$i];
#						$ai_v{'temp'}{'nearest_distance'} = $ai_v{'temp'}{'distance'};
#					}
#				}
#			}

			sendTalk(\$remote_socket, pack("L1", $ID));
			@{$ai_seq_args[0]{'npc'}{'steps'}} = split(/ /, $sc_v{'temp'}{'ai'}{'autoTalk'}{'npc_steps'});
			$ai_seq_args[0]{'npc'}{'sentTalk'} = 1;

			$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;

		} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /c/i) {
			sendTalkContinue(\$remote_socket, pack("L1", $ID));
			$ai_seq_args[0]{'npc'}{'step'}++;
		} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /n/i) {
			#sendTalkCancel(\$remote_socket, pack("L1", $ID));
			$ai_seq_args[0]{'npc'}{'step'}++;
		} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i) {
			($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a(\d+)/i;
			if ($ai_v{'temp'}{'arg'} ne "") {
				sendTalkAnswerNum(\$remote_socket, pack("L1", $ID), $ai_v{'temp'}{'arg'});
			}
			$ai_seq_args[0]{'npc'}{'step'}++;
		} elsif ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i) {
			($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /a"([\s\S]*?)"$/i;
			if ($ai_v{'temp'}{'arg'} ne "") {
				sendTalkAnswerWord(\$remote_socket, pack("L1", $ID), $ai_v{'temp'}{'arg'});
			}
			$ai_seq_args[0]{'npc'}{'step'}++;
		} else {
			($ai_v{'temp'}{'arg'}) = $ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] =~ /r(\d+)/i;
			if ($ai_v{'temp'}{'arg'} ne "") {
				$ai_v{'temp'}{'arg'}++;
				sendTalkResponse(\$remote_socket, pack("L1", $ID), $ai_v{'temp'}{'arg'});
			}
			$ai_seq_args[0]{'npc'}{'step'}++;
		}

		if ($ai_seq_args[0]{'npc'}{'steps'}[$ai_seq_args[0]{'npc'}{'step'}] eq "") {
			$ai_seq_args[0]{'done'} = 1;
			$sc_v{'temp'}{'ai'}{'talkAuto'}{'do'} = 1;
		}
	}

	return $val;
}

sub inTargetNpcMap {
	my ($map_now, $map_npc, $map_list) = @_;
	my $map_def;

	if ($npcs_lut{$map_npc}{'map'} ne "") {
		$map_def = $npcs_lut{$map_npc}{'map'};
	} elsif ($config{'parseNpcAuto'}) {
		my @parseNpc = split /\s/, $ID;
		$map_def = $parseNpc[1] if switchInput($parseNpc[0], "<npc>", "<auto>", "auto");
	}

	$map_now = getMapID($map_now);
	$map_def = getMapID($map_def);

	return (($map_now eq $map_def) || ($map_list ne "" && existsInList($map_list, $map_now)))?1:0;
}

1;
