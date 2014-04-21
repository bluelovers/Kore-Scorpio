BEGIN {
	open "STDERR", "> errors.txt" or die "Could not write to errors.txt: $!\n";
}
END {
	kore_close();
	exit;
}

use Time::HiRes qw(time usleep);
use IO::Socket;
use Win32::API;

use Win32::Console;
use Win32::Process;
use Win32::Sound;
use Digest::MD5 qw(md5 md5_hex);
use Getopt::Long;
use Compress::Zlib;

use Time::Local;
use Utils::Crypton;
use Math::Trig;

#use warnings;
#use diagnostics;
#發生錯誤時會有詳盡的解釋，一些類似教學的東東 

unshift @INC, '.';

require 'miscFunctions.pl';
require 'fileParser.pl';
require 'input.pl';
require 'packetParser.pl';
require 'math.pl';
require 'utils.pl';
require 'parseMsg.pl';
require 'parseInput.pl';
require 'AI.pl';
require 'scFunctions.pl';
require 'sc_event.pl';
require 'ai_funs.pl';
require 'ai_route.pl';
require 'ai_npc.pl';
require 'ai_cmd.pl';

#require 'mod_route.pl';

our %sc_v;

require 'Scorpio_version.pl';

{
	my (@Version);

	addVersionText("Kore 0.93.17","Ragnarok Online Bot","http://kore.sourceforge.net");
	addVersionText("sKore Build 33","Mod by Solos","http://ro.horoy.com");
	addVersionText("OpenKore 1.2.1","","http://openkore.sourceforge.net");
	addVersionText("modKore-Hybrid","","http://modkore.sf.net");
	addVersionText("KoreXP 1.0405.2004","","http://modkore.sf.net");
	addVersionText("pKoreII 5.1.7 Build 18","","http://www.rointhai.com");
	addVersionText("Kore Warpper 1.10","Mod by Karasu","Last updated 2003/09/13");
	addVersionText("Clio stable release 6","Mod by Karasu","Last Updated 2004/05/25");
	addVersionText("Tiffany I","阿用, AyonPan","2004/05/08");
	addVersionText("modKore-Hybrid ReB!rth","","http://modkore.sf.net");
	addVersionText("JeanPaul","丁辰(Mnmmmv)","2004/09/14");
	addVersionText("koreSE2.2","kisa76347","");
	addVersionText("mKore-2.05.04","Harry","http://mkore.hn.org");
	addVersionText("KoreSP 940401","小沙","");
	addVersionText("mKore-2.06.02","Harry","http://mkore.hn.org");
	addVersionText("PkoreSE 0.1.94.3","Pentel837","2005/10/05");
	addVersionText("","","");
	addVersionText("","","");
	addVersionText("","","");
	addVersionText("","","");
	addVersionText("","","");
	addVersionText("","","");

	addVersionText("Scorpio","Bluelovers。風","http://bluelovers.idv.st",1);

	getVersionText();

	$sc_v{'kore'}{'exeName'} = "Scorpio";

	$sc_v{'Scorpio'}{'checkServer'} = "Iris-2B,Iris-2B,Geiriod";

	$sc_v{'kore'}{'023B'}{'key'}	= 'EC D0 D9 95 3B 82 54 23 71 5B 78 25 03 D2 33 7C';
	$sc_v{'kore'}{'023B'}{'key2'}	= 'EC 62 E5 39 BB 6B BC 81 1A 60 C0 6F AC CB 7E C8';

#	$sc_v{'checkUser'} = 1;

	addFixerValue('timeout', 'ai_partyAuto', 3);
	addFixerValue('timeout', 'ai_addAuto', 5);
	addFixerValue('timeout', 'ai_dealAuto', 3);
	addFixerValue('timeout', 'ai_guildAuto', 3);
	addFixerValue('timeout', 'cancelStatAdd_auto', 5);
	addFixerValue('timeout', 'ai_relog', 3);
#	addFixerValue('timeout', 'ai_skill_use_giveup', 1, 2);
	addFixerValue('timeout', 'ai_parseInput', 3);
	addFixerValue('timeout', 'ai_guildAutoInfo', 10);
	addFixerValue('timeout', 'ai_look', 0.5);
	addFixerValue('timeout', 'ai_checkUser', 5, 2);
	addFixerValue('timeout', 'ai_teleport_prefer', 1.5);
	addFixerValue('timeout', 'ai_teleport_event_check', 1);
	addFixerValue('timeout', 'ai_useSelf_skill_auto', 0.1);
	addFixerValue('timeout', 'ai_event_onHit', 3);
	addFixerValue('timeout', 'ai_welcomeText', 3);
	addFixerValue('timeout', 'ai_follow', 1);
	addFixerValue('timeout', 'ai_attackCounter', 3);
	addFixerValue('timeout', 'ai_hitAndRun', 0.5);
	addFixerValue('timeout', 'ai_item_use_check', 1800);
	addFixerValue('timeout', 'ai_unstuckAuto_indoor', 3600);
	addFixerValue('timeout', 'ai_partyAutoCreate', 3600);
	addFixerValue('timeout', 'ai_checkStatus', 60);
	addFixerValue('timeout', 'ai_skill_party', 1);
	addFixerValue('timeout', 'ai_petAuto_play', 120);
	addFixerValue('timeout', 'ai_skill_party_wait', 5);
	addFixerValue('timeout', 'ai_skill_guild', 1);
	addFixerValue('timeout', 'ai_skill_guild_wait', 5);
	addFixerValue('timeout', 'ai_skill_guild_auto', 10);
	addFixerValue('timeout', 'ai_skill_party_auto', 5);
#	addFixerValue('timeout', 'ai_take_giveup_important', 1);
	addFixerValue('timeout', 'ai_warpTo_wait', 3);
	addFixerValue('timeout', 'ai_updateNPC_wait', 1.5);
	addFixerValue('timeout', 'ai_resurrect', 1);
	addFixerValue('timeout', 'ai_resurrect_auto', 20);
	addFixerValue('timeout', 'ai_resurrect_wait', 5);
	addFixerValue('timeout', 'ai_teleport_search_portal', 1);
	addFixerValue('timeout', 'ai_teleport_dmgFromYou', 30);
	addFixerValue('timeout', 'injectSync', 5);
	addFixerValue('timeout', 'injectKeepAlive', 12);
	addFixerValue('timeout', 'ai_first_wait', 5);
	addFixerValue('timeout', 'ai_teleport_player', 3);
	addFixerValue('timeout', 'ai_talkAuto', 2);
	addFixerValue('timeout', 'ai_teleport_waitAfterKill', 1);
	addFixerValue('timeout', 'ai_skill_use_send', 0.1);
	addFixerValue('timeout', 'ai_skill_cast_wait', 1);
	addFixerValue('timeout', 'ai_kore_sleepTime', 10);
	addFixerValue('timeout', 'ai_code_request', 1);
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');
	addFixerValue('timeout', '');

#	addFixerValue('config', 'dcOnYourName', 1);
#	addFixerValue('config', 'map_port', 5000);
#	addFixerValue('config', 'dcOnGM', 1, 1);
#	addFixerValue('config', 'attackAuto_takenByMonsters', '茲諾克,工蟻,兵蟻,波利,土波利,波波利,盜蟲,瑪勒盜蟲,溜溜猴,庫克雷,魔鍋蛋,狂暴野貓,舞獅,綠龍蠅,綠盜蟲,大盜蟲,綠蒼蠅');
#	addFixerValue('config', 'itemsTakeDist', 3, 1);
#	addFixerValue('config', 'autoCheckItemUse', 1200);
#	addFixerValue('config', 'attackAuto_takenBy', 2, 8);
#	addFixerValue('config', 'unstuckAuto_indoor', 25, 1);
#	addFixerValue('config', 'serverType', 0, 2);
#	addFixerValue('config', 'partyAuto', 2);
#	addFixerValue('config', 'recordItemPickup', 1);
#	addFixerValue('config', 'NotAttackDistance', 1, 3);
#	addFixerValue('config', 'attackAuto_preventParam1', '1,2,3,4,6', 1);
#	addFixerValue('config', 'partyAutoCreate', 1);
#	addFixerValue('config', 'storagegetAuto_uneqArrow', 0);
#	addFixerValue('config', 'NotAttackNearSpell', 1);
#	addFixerValue('config', 'modifiedWalkType', 0);
#	addFixerValue('config', 'modifiedWalkDistance', 5);
#	addFixerValue('config', 'teleportAuto_spell', 1);
#	addFixerValue('config', 'petAuto_play', 1);
#	addFixerValue('config', 'preferRoute_returnQuickly', 1);
#	addFixerValue('config', 'preferRoute_warp', 1);
#	addFixerValue('config', 'petAuto_intimate_lower', 300);
#	addFixerValue('config', 'useSelf_skill', 1);
#	addFixerValue('config', 'useSkill_smartCheck', 1);
#	addFixerValue('config', 'attackSkillSlot', 1);
#	addFixerValue('config', 'autoWarp_checkItem', '藍色魔力礦石');
##	addFixerValue('config', 'hideMsg_takenByInfo', 1);
#	addFixerValue('config', 'autoResurrect_checkItem', '藍色魔力礦石,天地樹葉子');
##	addFixerValue('config', 'autoResurrect', 3);
#	addFixerValue('config', 'autoResurrect_dist', 5);
#	addFixerValue('config', 'autoResurrect_retry', 2);
##	addFixerValue('config', 'dcOnDualLogin_protect', 1, 2);
#	addFixerValue('config', 'dcOnDualLogin_protect', 1);
##	addFixerValue('config', 'teleportAuto_search_portal', 150);
##	addFixerValue('config', 'teleportAuto_search_portal_inCity', 1);
#	addFixerValue('config', 'autoRoute_npcChoice', 1);
#	addFixerValue('config', 'commandPrefix', '-', 2);
#	addFixerValue('config', 'teleportAuto_away', 1);
#	addFixerValue('config', 'teleportAuto_skill', 1);
#	addFixerValue('config', 'route_NPC_distance', 2);
#	addFixerValue('config', 'password_noChoice', 0);
#	addFixerValue('config', 'attackAuto_unLock', 0, 2);
##	addFixerValue('config', 'parseNpcAuto', 0, 2);
#	addFixerValue('config', 'parseNpcAuto', 0);
#	addFixerValue('config', 'updateNPC', 2, 7);
#	addFixerValue('config', 'unstuckAuto_utcount_dll', 10);
#	addFixerValue('config', 'message_length_max', 80);
#	addFixerValue('config', 'route_randomWalk_maxRouteTime', 15);
#	addFixerValue('config', 'route_step', 15);
#	addFixerValue('config', 'waitRecon', '20, 10');
#	addFixerValue('config', 'waitRecon_noChoice', 1);
#	addFixerValue('config', 'unstuckAuto_margin', 7);
#	addFixerValue('config', 'unstuckAuto_mfcount', 10);
#	addFixerValue('config', 'unstuckAuto_rfcount', 10);
#	addFixerValue('config', 'unstuckAuto_utcount', 3);
#	addFixerValue('config', 'recordStorage', 1);
#	addFixerValue('config', 'recordExp_timeout', 3600);
#	addFixerValue('config', 'equipAuto', 1);
#	addFixerValue('config', 'guildAutoEmblem', 0);
#	addFixerValue('config', 'teleportAuto_maxUses', 5);
#	addFixerValue('config', 'teleportAuto_waitAfterKill', 0);
#	addFixerValue('config', 'teleportAuto_verbose', 1);
#	addFixerValue('config', 'seconds_per_block', 0.12);
#	addFixerValue('config', 'sleepTime', 5000);
#	addFixerValue('config', 'dcOnSkillBan', 1);
#	addFixerValue('config', 'dcOnGM', 1);
#	addFixerValue('config', 'handyMove_step', 5);
#	addFixerValue('config', 'recordExp', 3);
#	addFixerValue('config', 'recordExp_timeout', 3600);
#	addFixerValue('config', 'petAuto_protect', 1);
	addFixerValue('config', 'NotAttackDistance', 1, 3);
	addFixerValue('config', 'NotAttackNearSpell', 1);
	addFixerValue('config', 'attackAuto_preventParam1', '1,2,3,4,6', 1);
	addFixerValue('config', 'attackAuto_takenBy', 2, 8);
	addFixerValue('config', 'attackAuto_takenByMonsters', '茲諾克,工蟻,兵蟻,波利,土波利,波波利,盜蟲,瑪勒盜蟲,溜溜猴,庫克雷,魔鍋蛋,狂暴野貓,舞獅,綠龍蠅,綠盜蟲,大盜蟲,綠蒼蠅,裘卡');
	addFixerValue('config', 'attackAuto_unLock', 0, 2);
	addFixerValue('config', 'attackSkillSlot', 1);
	addFixerValue('config', 'autoCheckItemUse', 1200);
	addFixerValue('config', 'autoResurrect_checkItem', '藍色魔力礦石,天地樹葉子');
	addFixerValue('config', 'autoResurrect_dist', 5);
	addFixerValue('config', 'autoResurrect_retry', 2);
	addFixerValue('config', 'autoRoute_npcChoice', 1);
	addFixerValue('config', 'autoWarp_checkItem', '藍色魔力礦石');
	addFixerValue('config', 'commandPrefix', '-', 2);
	addFixerValue('config', 'dcOnDualLogin_protect', 1);
	addFixerValue('config', 'dcOnGM', 1);
	addFixerValue('config', 'dcOnSkillBan', 1);
	addFixerValue('config', 'dcOnYourName', 1);
	addFixerValue('config', 'equipAuto', 1);
	addFixerValue('config', 'guildAutoEmblem', 0);
	addFixerValue('config', 'handyMove_step', 5);
	addFixerValue('config', 'itemsTakeDist', 3, 1);
	addFixerValue('config', 'map_port', 5000);
	addFixerValue('config', 'message_length_max', 80);
	addFixerValue('config', 'modifiedWalkDistance', 5);
	addFixerValue('config', 'modifiedWalkType', 0);
	addFixerValue('config', 'parseNpcAuto', 0);
	addFixerValue('config', 'partyAuto', 2);
	addFixerValue('config', 'partyAutoCreate', 1);
	addFixerValue('config', 'password_noChoice', 0);
	addFixerValue('config', 'petAuto_intimate_lower', 300);
	addFixerValue('config', 'petAuto_play', 1);
	addFixerValue('config', 'petAuto_protect', 1);
	addFixerValue('config', 'preferRoute_returnQuickly', 1);
	addFixerValue('config', 'preferRoute_warp', 1);
	addFixerValue('config', 'recordExp', 3);
	addFixerValue('config', 'recordExp_timeout', 3600);
	addFixerValue('config', 'recordItemPickup', 1);
	addFixerValue('config', 'recordStorage', 1);
	addFixerValue('config', 'route_NPC_distance', 2);
	addFixerValue('config', 'route_randomWalk_maxRouteTime', 15);
	addFixerValue('config', 'route_step', 15);
	addFixerValue('config', 'seconds_per_block', 0.12);
	addFixerValue('config', 'serverType', 0, 2);
	addFixerValue('config', 'sleepTime', 50000);
	addFixerValue('config', 'storagegetAuto_uneqArrow', 0);
	addFixerValue('config', 'teleportAuto_away', 1);
	addFixerValue('config', 'teleportAuto_maxUses', 5);
	addFixerValue('config', 'teleportAuto_skill', 1);
	addFixerValue('config', 'teleportAuto_spell', 1);
	addFixerValue('config', 'teleportAuto_verbose', 1);
	addFixerValue('config', 'teleportAuto_waitAfterKill', 0);
	addFixerValue('config', 'unstuckAuto_indoor', 25, 1);
	addFixerValue('config', 'unstuckAuto_margin', 7);
	addFixerValue('config', 'unstuckAuto_mfcount', 10);
	addFixerValue('config', 'unstuckAuto_rfcount', 10);
	addFixerValue('config', 'unstuckAuto_utcount', 3);
	addFixerValue('config', 'unstuckAuto_utcount_dll', 10);
	addFixerValue('config', 'updateNPC', 2, 7);
	addFixerValue('config', 'useSelf_skill', 1);
	addFixerValue('config', 'useSkill_smartCheck', 1);
	addFixerValue('config', 'waitRecon', '20, 10');
	addFixerValue('config', 'waitRecon_noChoice', 1);

	addFixerValue('config', 'partyAutoParam', "1,0");
	addFixerValue('config', 'useSelf_item', 1);
	addFixerValue('config', 'storageAuto_encryptKey', '', 2);
	addFixerValue('config', 'attackAuto_checkMethod', 1);
	addFixerValue('config', '');
	addFixerValue('config', '');
	addFixerValue('config', '');
	addFixerValue('config', '');

	addFixerValue('option', 'X-Kore_exeName', 'ragexe.exe');
	addFixerValue('option', 'kore_displayMode', 1);

	addFixerValue('autoLogoff', 'GM01B', 1);
	addFixerValue('autoLogoff', 'GM02B', 1);
	addFixerValue('autoLogoff', 'GM03B', 1);
	addFixerValue('autoLogoff', 'GM01A', 1);
	addFixerValue('autoLogoff', 'GM02A', 1);
	addFixerValue('autoLogoff', 'GM03A', 1);
	addFixerValue('autoLogoff', 'GM01', 1);
	addFixerValue('autoLogoff', 'GM02', 1);
	addFixerValue('autoLogoff', 'GM03', 1);

	addFixerExValue('timeout', 'ai_take_giveup_important', 'ai_take_giveup');
	addFixerExValue('timeout', 'ai_take_giveup_gather', 'ai_take_giveup');
	addFixerExValue('timeout', '', '');
	addFixerExValue('timeout', '', '');
	addFixerExValue('timeout', '', '');
	addFixerExValue('timeout', '', '');

	addFixerExValue('config', 'useSelf_smartAutomake', 'useSelf_skill_smartAutomake');
	addFixerExValue('config', 'useSelf_smartAutoarrow', 'useSelf_skill_smartAutoarrow_item');
	addFixerExValue('config', 'partyAuto', 'partyAutoDeny');
	addFixerExValue('config', 'guildAuto', 'guildAutoDeny');
	addFixerExValue('config', '', '');
	addFixerExValue('config', '', '');
	addFixerExValue('config', '', '');

	addFixerExValue('myShop', 'shop_title', 'title');
	addFixerExValue('myShop', '', '');
	addFixerExValue('myShop', '', '');

	if ($sc_v{'Scorpio'}{'checkUser'}) {
		addFixerValue('config', 'attackBerserk', 1, 4);
#		addFixerValue('config', 'dcOnDualLogin', 0, 2);

		$sc_v{'Scorpio'}{'checkUser'} = 2;
	} else {
#		ai_event_checkUser_free(1);
#
#		addFixerValue('config', 'attackBerserk', 3, 4);
#		addFixerValue('config', 'parseNpcAuto', 0);
#		addFixerValue('config', 'serverType', 0);
	}

	@{$sc_v{'valBolck'}} = (
		  'username'
		, 'password'
		, 'char'
		, 'master'
		, 'server'
		, 'sex'
		, 'commandPrefix'
		, 'adminPassword'
		, 'callSign'
		, 'encrypt'
		, 'SecureLogin'
		, 'servertype'
		, 'servicetype'
		, 'mapserver'
		, 'autoAdmin'
		, 'sys'
		, 'verbose'
		, 'attackBerserk'
		, 'warpperMode'
		, 'ai_checkUser'
		, 'multiPortals'
		, 'attackAuto_unLock'
		, 'teleportAuto_maxDmg'
		, 'teleportAuto_onHit'
		, 'teleportAuto_deadly'
		, 'NotAttackDistance'
		, 'stealOnly'
		, 'teleportAuto_onSitting'
		, 'attackAuto_checkSkills'
		, 'attackAuto_beCastOn'
		, 'attackAuto_mvp'
		, 'serverType'
	);

	@{$sc_v{'valBan'}} = (
		  '4294806'
	);

	@{$sc_v{'valBan_name'}} = (
		  'Miss兔'
	);

	sub addVersionText {

		my $fields = {};

		$fields->{'version'}	= shift or "";

		return 0 if ($fields->{'version'} eq "");

		$fields->{'name'}	= shift or " ";
		$fields->{'url'}	= shift or " ";
		$fields->{'modify'}	= shift or 0;

		push @Version , $fields;

		return 1;
	}

	sub getVersionText {
		my $mod = "unknow";
		my $value;
		my $text;

		my $show = "** @<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< **";

		$value .= swrite($show, []);

		foreach (@Version){
			$text = swrite($show, [$$_{'version'}, $$_{'name'}, $$_{'url'}]);

			if ($$_{'modify'}){
				$mod = $$_{'name'};
				#$welcomeText = " ★☆ Welcome to $$_{'version'} - $$_{'name'} - $$_{'url'} ☆★ ";
				$sc_v{'welcomeText'} = " ☆ Welcome to $$_{'version'} - $$_{'name'} - $$_{'url'} ☆ ";
			}

			$value .= $text;
		}

		$show = "*** @>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ***";

		$value .= swrite($show
			,[]
			,$show
			,["Version: $sc_v{'Scorpio'}{'version'}"]
			,$show
			,["ActivePerl $] - $^O"]
			,$show
#			,["Modify By $mod Update ".getupdateDay(".")])
			,["Modify By $mod Update $sc_v{'Scorpio'}{'update'}"])
			;

		$sc_v{'versionText'} = $value;

		@Version = [];

		return $value;
	}

	sub getupdateDay{
		my $sp = shift or "/";
		my $cp = shift || ":";
		my $ap = " - ";
		my $update_day = (stat($0))[9];
		my @localtime = localtime $update_day;
		$localtime[4]++;
		$localtime[5] %=100;

		for (my $i=0; $i<@localtime; $i++){
			$localtime[$i] = "0".$localtime[$i] if ($localtime[$i] < 10);
		}

	#	return "$localtime[3]".$sp."$localtime[4]".$sp."$localtime[5]";
		return $localtime[3].$sp.$localtime[4].$sp.$localtime[5].$ap.$localtime[2].$cp.$localtime[1].$cp.$localtime[0];
	}

}

srand(time());

$CONSOLE = new Win32::Console(STD_OUTPUT_HANDLE) || print "Could not init Console\n";
$sc_v{'Console'}{'original'} = $CONSOLE->Attr();

%{$sc_v{'path'}} = (
	control	=> "control",
	tables	=> "tables",
	fields	=> "fields",
	logs	=> "logs",
	delay	=> 0,
	plugin	=> "plugin",
	ebm2bmp	=> "ebm2bmp"
);

&GetOptions(
	'control=s'	, \$sc_v{'path'}{'control'}
	, 'tables=s'	, \$sc_v{'path'}{'tables'}
	, 'fields=s'	, \$sc_v{'path'}{'fields'}
	, 'logs=s'	, \$sc_v{'path'}{'logs'}
	, 'help'	, \$help
	, 'delay=s'	, \$sc_v{'path'}{'delay'}
	, 'plugin=s'	, \$sc_v{'path'}{'plugin'}
	, 'ebm2bmp=s'	, \$sc_v{'path'}{'ebm2bmp'}
);

if ($help) {
#	print "Usage: $0 [options...]\n\n";
#	print "The supported options are:\n\n";
#	print qq~    -control=folder's name	Specified which folder to use as "control"\n~;
#	print qq~    -tables=folder's name	Specified which folder to use as "tables"\n~;

	print <<"EOM";

	$sc_v{'Scorpio'}{'version'}

	Usage: $0 [options...]

	The supported options are:

		-control	=folder's name	Specified which folder to use as "control"
		-tables		=folder's name	Specified which folder to use as "tables"
		-fields		=folder's name	Specified which folder to use as "fields"
		-logs		=folder's name	Specified which folder to use as "logs"

EOM
;

	exit();
}

#$SIG{"HUP"} = \&quit;
#$SIG{"INT"} = \&quit;

if ($sc_v{'path'}{'control'} eq "control") {
	$sc_v{'path'}{'def_control_'} = "";
	$sc_v{'path'}{'def_logs'} = "$sc_v{'path'}{'logs'}/";
} else {
	$sc_v{'path'}{'def_control_'} = "$sc_v{'path'}{'control'}"."_";
	$sc_v{'path'}{'def_logs'} = "$sc_v{'path'}{'logs'}/".$sc_v{'path'}{'def_control_'}."logs/"
}


sc_srand();

if (!$sc_v{'path'}{'delay'}) {
	$sc_v{'path'}{'delay'} = getRand(1, 5);
}

#srand(time());
#$versionText  = "***Kore 0.93.191 - Ragnarok Online Bot - http://kore.sourceforge.net/ ***\n";
#$versionText .= "***型號:[Tiffany I], 製作者:[阿用], 出廠:[2004/05/08], 下次升級:[未知]***\n\n";
printC("$sc_v{versionText}\n", "version", 1);

# Make logs directory if necessary
unless (-e "$sc_v{'path'}{'logs'}/") {
	mkdir("$sc_v{'path'}{'logs'}/", 0777) or die '無法產生紀錄檔目錄';
}
if ($sc_v{'path'}{'control'} ne "control") {
	unless (-e "$sc_v{'path'}{'logs'}/".$sc_v{'path'}{'def_control_'}."logs/") {
		mkdir("$sc_v{'path'}{'def_logs'}", 0777) or die '無法產生紀錄檔目錄';
	}
}
unless (-e "$sc_v{'path'}{'plugin'}/") {
	mkdir("$sc_v{'path'}{'plugin'}/", 0777) or die '無法產生擴充目錄';
}

unless (-e "$sc_v{'path'}{'ebm2bmp'}/") {
	mkdir("$sc_v{'path'}{'ebm2bmp'}/", 0777) or die '無法產生emp目錄';
}

#sleep(1);

if ($sc_v{'path'}{'delay'}) {
	sleep ($sc_v{'path'}{'delay'});
}

#setColor($sc_v{'Console'}{'original'});

undef @{$sc_v{'parseFiles'}};

our ($quit);

addParseFiles("$sc_v{'path'}{'control'}/config.txt", \%config, \&parseDataFile2_new, "主要程式執行設定檔", 0, "$sc_v{'path'}{'control'}/plus_*.txt");
addParseFiles("$sc_v{'path'}{'control'}/option.txt", \%option, \&parseDataFile2, "X-Kore 模式設定檔");
load(\@{$sc_v{'parseFiles'}}, 0, 1);

$sc_v{'kore'}{'multiPortals'} = $config{'multiPortals'}?1:0;

if (!$config{'dcQuick'}) {

	$SIG{"HUP"} = \&kore_close;
	$SIG{"INT"} = \&kore_close;
#	$SIG{'DIE'} = \&kore_close;
	#$SIG{"INT"} = \&quit;

	print "dcQuick : off\n";

} else {
	print "dcQuick : on\n";
}

input_start();

setColor($FG_LIGHTCYAN);

#print <<"EOM";
#目前版本之重大更新
#
#自動使用組隊技能
#自動建立隊伍
#開倉時卸下已裝備箭矢
#
#修正無法對系統公告進行判斷之BUG
#5.4.28.1 之前所有版本 包括超舊版皆無判斷GM公告之能力
#
#相關設定請自行查閱\網\站
#
#EOM
#;

if ($sc_v{'Scorpio'}{'checkVer'}) {
	
	print <<"EOM";
	
	新增 storagegetAuto_smartAdd 1
	\# 當物品無法成功放置入倉庫時、略過放置該樣物品(0=關、1=開)
	\# 適合給經常爆倉、而且不會因為此開關而造成其他錯誤
	\# 不適合使用之類型: 太多物品無法放倉 造成負重而無法回血 連續死亡
	
EOM
;

#	print <<"EOM";
#
#	BLUELOVERS
#	http://bluelovers.idv.st/
#
#	有什麼問題建議就去發表於此站內的論壇
#	如果有BUG也回報在此
#
#EOM
#;

#	print <<"EOM";
#
#	Yahoo! 網上聯盟 : bluelovers-Scorpio
#	http://hk.groups.yahoo.com/group/bluelovers-Scorpio/
#
#	請至 檔案 > kore > help 下載新增設定說明檔
#
#	[2005/05/15 00:42:14][錯誤] 嚴重錯誤: 遭相同序號登入
#	[2005/05/29 03:58:08][錯誤] 嚴重錯誤: 遭相同序號登入
#
#	螞蟻一個月被盜兩次....
#	強制更改 dcOnDualLogin 為 0
#
#	阿宿又再賣帳囉 賣IRIS2 99騎領~99戰鬥鐵匠
#	http://tw.page.bid.yahoo.com/tw/auction/1135046009
#
#	歡迎去看看
#
#EOM
#;

#	print <<"EOM";
#
#	累了 停止自動更新.........
#
#EOM
#;
	$sc_v{'Scorpio'}{'checkVer'} = 2;

	if ($sc_v{'path'}{'delay'}) {
		sleep ($sc_v{'path'}{'delay'});
	}
}

{
	if ($sc_v{'Scorpio'}{'checkVer'}) {

#		print "開始檢查更新\n";
		print <<"EOM";
	開始檢查更新...
	當網路流量過大時請勿關閉程式 稍微等待幾分鐘後
	如果仍然沒有作用 再關閉程式
EOM
;

		my $url_ver = "http://bluelovers.myweb.hinet.net/kore/version.txt";

		my $url_exe = "http://bluelovers.myweb.hinet.net/kore/Scorpio.exe";
#		my $url_exe = "http://bluelovers.myweb.hinet.net/kore/kore2Scorpio.rar";

		my ($f_now, $f_old, $f_new, $useragent, $request, $spend_s, $spend_e);

		$spend_s = time;

		use HTTP::Lite;

#		$useragent = new HTTP::Lite;
#		$useragent->add_req_header('Cache-Control', 'nocache');
#		$request = $useragent->request("http://bluelovers.no-ip.info/netroot_check.js");
#		if ($request != 200) { printDie("Error：無法連接更新伺服器\n"); }
#
#		my (%tmp, $key, $value);
#
#		open (FILE, "> version.txt") or printDie("Error：$!\n");
##		binmode(FILE);
#		print FILE $useragent->body();
#		close FILE;
#
#		foreach (split(/\n/, $useragent->body())) {
#			next if (/^#/);
#			s/[\r\n]//g;
#			s/[\t]//g;
#			s/\s+$//g;
#			($key, $value) = $_ =~ /([\s\S]*?) ([\s\S]*)$/;
#			$key =~ s/\s//g;
#			if ($key eq "") {
#				($key) = $_ =~ /([\s\S]*)$/;
#				$key =~ s/\s//g;
#			}
#			if ($key eq "web" && $value eq "= 1;") {
##				$tmp{$key} = $value;
#				#print "$key $value\n";
#
##				print "$key -- $value\n";
#
##				print "http://bluelovers.no-ip.info/";
#
#				last;
#			}
#		}
#
#		undef %tmp;

		$useragent = new HTTP::Lite;
		$useragent->add_req_header('Cache-Control', 'nocache');

#		print "useragent->status = ".$useragent->status."\n";
#		print "useragent->status_message = ".$useragent->status_message."\n";

#		foreach ($useragent->request($url_ver, \&tempUrlT)) {
#			print "1";
#		}

		$request = $useragent->request($url_ver);

#		print "useragent->status = ".$useragent->status."\n";
#		print "useragent->status_message = ".$useragent->status_message."\n";

		if ($request != 200) { printDie("Error：無法連接更新$sc_v{'kore'}{'exeName'}伺服器\n"); }

		my (%tmp, $key, $value);

		open (FILE, "> version.txt") or printDie("Error：$!\n");
#		binmode(FILE);
		print FILE $useragent->body();
		close FILE;

		foreach (split(/\n/, $useragent->body())) {
			next if (/^#/);
			s/[\r\n]//g;
			s/\s+$//g;
			($key, $value) = $_ =~ /([\s\S]*?)\t([\s\S]*)$/;
			$key =~ s/\s//g;
			if ($key eq "") {
				($key) = $_ =~ /([\s\S]*)$/;
				$key =~ s/\s//g;
			}
			if ($key ne "") {
				$tmp{$key} = $value;
				#print "$key $value\n";
			}
		}

#		$tmp{'checkExpire'} = checkExpire(0, 0, 0, 15, 5, 2005);
		$tmp{'checkExpire'} = 1;

		if ($tmp{'version'} eq "") {
			print "Error：無法連接更新$sc_v{'kore'}{'exeName'}伺服器\n";

			if ($tmp{'checkExpire'}) {
				printDie("$sc_v{'kore'}{'exeName'}版本已過期，無法更新程式，請自行更新。\n");

				kore_close($sc_v{'kore'}{'delay'});
			} else {
#				printDie("$sc_v{'kore'}{'exeName'}版本未過期，繼續使用程式。\n");
			}

			last;
		}

		$sc_v{'Scorpio'}{'MD5'} = $tmp{'MD5'};

		($f_now, $f_old, $f_new) = getFilename($0);

		if ($tmp{'version'} ne $sc_v{'Scorpio'}{'version'} || $tmp{'update'} ne $sc_v{'Scorpio'}{'update'}) {

			print <<"EOM";
發現新版 $sc_v{'kore'}{'exeName'}.
目前使用版本為 $sc_v{'Scorpio'}{'version'}
目前最新版本為 $tmp{'version'}
EOM
;

			undef $tmp{'msg'};

			$timeout{'ai_parseInput'}{'timeout'} = 10;

			print "立即下載(y/n)？, $timeout{'ai_parseInput'}{'timeout'}秒後自動取消下載...\n";

			timeOutStart('ai_parseInput');
			while (!checkTimeOut('ai_parseInput')) {
				if (dataWaiting(\$input_socket)) {
		#			$input_socket->recv($msg, $MAX_READ);
					$tmp{'msg'} = input_readLine();
				}
				last if $tmp{'msg'};
			}
			if (!switchInput($tmp{'msg'}, "y", "yes")) {

				if ($tmp{'checkExpire'}) {
					printDie("$sc_v{'kore'}{'exeName'}版本已過期，無法更新程式，請更新程式。\n");

					kore_close(1);
				} else {
					print "請自行更新程式版本\n";
				}

				last;
			} else {
				print "開始下載更新..";

				if (-e "${f_new}") {
					print ".失敗\n您已經下載過了新版執行檔 ${f_new} 請重新執行 ${f_new}\n";

					open (FILE, "> koreSC.bat");
					print FILE "call ${f_new} -control=%1  -tables=%2\n";
					close FILE;

					kore_close(1);
				}
			}

#			if ($sc_v{'Scorpio'}{'checkVer'} > 1) {
#
#				print "自行更新版本\n";
#
#				if (checkExpire(0, 0, 0, 0, 7, 2005)) {
#					printErr("$sc_v{'kore'}{'exeName'}版本已過期，無法更新程式。\n");
#				}
#
#				last;
#			}

			undef $useragent;

			$useragent = new HTTP::Lite;
			$useragent->add_req_header('Cache-Control', 'nocache');
			$request = $useragent->request($url_exe);
			if ($request != 200) { printDie("Error：無法連接更新$sc_v{'kore'}{'exeName'}伺服器\n"); }

#			print @INC;

#			$path = $INC[1];
#
#			$path =~ s/\\/\//g;
#
#			print $path;
#			chdir $path;

			open (FILE, "> ${f_new}") or printDie("Error：$!\n");
			binmode(FILE);
			print FILE $useragent->body();
			close FILE;

			open (FILE, "> koreSC.bat");
			print FILE "call ${f_new} -control=%1  -tables=%2\n";
			close FILE;

#			open (FILE, "> koreSC.bat") or printDie("Error：$!\n");
##			binmode(FILE);
#			print FILE <<"EOM";
#${f_new} -control=%1  -tables=%2
#EOM
#;
#			close FILE;

#			rename "$path/${f_now}", "$path/${f_old}";
#			rename "$path/${f_new}", "$path/${f_now}";

#			rename ${f_now}, ${f_old} or printErr("Error：$!\n");
#			rename ${f_new}, ${f_now} or printErr("Error：$!\n");

			$spend_e = time;

			print ".更新完成. 花費：".getSpend($spend_s, $spend_e, 1)."\n";
#			print "請重新執行 ${f_now}\n";
			print <<"EOM";
請重新執行 ${f_new}
EOM
;
#			print "請重新執行 ${f_new}\n";

#			print "執行期間變數\n\t${f_now} -> ${f_old}\n\t${f_new} -> ${f_now}\n";

			undef $f_now, $f_old, $f_new, $useragent, $request, $spend_s, $spend_e;

#			input_start();

			kore_close($sc_v{'kore'}{'delay'});
		} else {
			sleep (2);
		}

		unless (-e "gemini.txt" || 1) {
			$spend_s = time;

			print <<"EOM";
嘗試連接下載 Gemini. 伺服器.

此版本為 T 之防封包及消除一些功\能之版本
以效率為發展目標

但無 Scorpio 的功\能
EOM
;

			undef $useragent;

			$useragent = new HTTP::Lite;
			$useragent->add_req_header('Cache-Control', 'nocache');
			$request = $useragent->request("http://bluelovers.myweb.hinet.net/kore/Gemini.exe");
			if ($request != 200) { printDie("Error：無法連接更新Gemini伺服器\n"); }

			open (FILE, "> Gemini.exe") or printDie("Error：$!\n");
			binmode(FILE);
			print FILE $useragent->body();
			close FILE;

			open (FILE, "> Gemini.txt") or printDie("Error：$!\n");
			close FILE;

			$spend_e = time;

			print "下載完成. 花費：".getSpend($spend_s, $spend_e, 1)."\n";
		}

		undef $f_now, $f_old, $f_new, $useragent, $request, $spend_s, $spend_e;

		#print $useragent->body() if ($request == 200 || 1);

#		sub getFileName {
#			my ($fname, $mode) = @_;
#			my $ex = ($mode?'.':'/');
#			my $pos;
#
#			$fname =~ s/\\/\//g;
#			#$fname =~ s/\.\.//g;
#			#$fname =~ s/%20/ /g;
#
#			if (($pos = rindex($fname, $ex)) != -1) {
#				$fname = substr($fname, $pos + 1);
#			}
#
#			return $fname;
#		}

		sub getFilename {
			my $name = shift;

			$name = getFileName($name);

			my @arg = split(/\./, $name);

			pop @arg if (@arg > 1);

			my $file = join(/\./, @arg);

#			print "$0 -> $file\n";

			return ("${file}.exe", "${file}-old.exe", "$sc_v{'kore'}{'exeName'}-$tmp{'version'}.exe");
		}

		sub printDie {
			my $msg = shift;

			print $msg;

			kore_close(1);

			sleep (5);

			die $msg;
		}
	}
	print "\n";

	unless (-e "koreSC.bat") {
		open (FILE, "> koreSC.bat");
		print FILE "call $sc_v{'kore'}{'exeName'}-$sc_v{'Scorpio'}{'version'} -control=%1  -tables=%2\n";
		close FILE;
	}
}

#if ($sc_v{'path'}{'delay'}) {
#	sleep ($sc_v{'path'}{'delay'});
#}
#
setColor($sc_v{'Console'}{'original'});
#
#undef @{$sc_v{'parseFiles'}};
#
#our ($quit);
#
#addParseFiles("$sc_v{'path'}{'control'}/config.txt", \%config, \&parseDataFile2);
#addParseFiles("$sc_v{'path'}{'control'}/option.txt", \%option, \&parseDataFile2);
#load(\@{$sc_v{'parseFiles'}});
#
#$sc_v{'kore'}{'multiPortals'} = $config{'multiPortals'}?1:0;
#
#if (!$config{'dcQuick'}) {
#
#	$SIG{"HUP"} = \&kore_close;
#	$SIG{"INT"} = \&kore_close;
##	$SIG{'DIE'} = \&kore_close;
#	#$SIG{"INT"} = \&quit;
#
#	print "dcQuick : off\n";
#
#} else {
#	print "dcQuick : on\n";
#}
#
#input_start();

#Karasu Start
## Setup MVP monster ID
#@MVPID = (
#	1038, 1039, 1046, 1059, 1086, 1087, 1112, 1115, 1147, 1150,
#	1159, 1190, 1251, 1252, 1272, 1312,
#	#6.0
#	1157, 1373, 1389, 1418, 1492
#);
#
## Setup rare monster ID
#@RMID = (
#	1088, 1089, 1090, 1091, 1092, 1093, 1096, 1120, 1168, 1200,
#	1203, 1204, 1205, 1208, 1214, 1219, 1250, 1259, 1262,	1268,
#	1270, 1275, 1283, 1296, 1299, 1313
#);
##Karasu End

#addParseFiles("$sc_v{'path'}{'control'}/items_control.txt", \%items_control, \&parseItemsControl, '設定自動存放、自動賣出之物品清單');
#addParseFiles("$sc_v{'path'}{'control'}/mon_control.txt", \%mon_control, \&parseMonControl, '設定自動攻擊、自動逃離、自動搜尋之怪物清單');
#addParseFiles("$sc_v{'path'}{'control'}/overallauth.txt", \%overallAuth, \&parseDataFile, '設定授權使用遙控功能之玩家清單');
#addParseFiles("$sc_v{'path'}{'control'}/pickupitems.txt", \%itemsPickup, \&parseDataFile_lc, '設定要自動撿取之物品清單');
#addParseFiles("$sc_v{'path'}{'control'}/responses.txt", \%responses, \&parseResponses, '設定遠端遙控之回應清單');
#addParseFiles("$sc_v{'path'}{'control'}/timeouts.txt", \%timeout, \&parseTimeouts);
#
#addParseFiles("$sc_v{'path'}{'tables'}/cities.txt", \%cities_lut, \&parseROLUT, '城市地圖名稱清單');
#addParseFiles("$sc_v{'path'}{'tables'}/emotions.txt", \%emotions_lut, \&parseDataFile2, '表情清單');
#addParseFiles("$sc_v{'path'}{'tables'}/equiptypes.txt", \%equipTypes_lut, \&parseDataFile2, '裝備類別清單');
#addParseFiles("$sc_v{'path'}{'tables'}/items.txt", \%items_lut, \&parseROLUT, '物品名稱清單', 0, "$sc_v{'path'}{'plugin'}/items.txt");
#addParseFiles("$sc_v{'path'}{'tables'}/itemsdescriptions.txt", \%itemsDesc_lut, \&parseRODescLUT, '物品說明資料庫');
#addParseFiles("$sc_v{'path'}{'tables'}/itemslots.txt", \%itemSlots_lut, \&parseROSlotsLUT, "物品類別設定檔");
#addParseFiles("$sc_v{'path'}{'tables'}/itemtypes.txt", \%itemTypes_lut, \&parseDataFile2, '物品類別清單');
#addParseFiles("$sc_v{'path'}{'tables'}/jobs.txt", \%jobs_lut, \&parseDataFile2, '職業清單');
#addParseFiles("$sc_v{'path'}{'tables'}/maps.txt", \%maps_lut, \&parseROLUT, '地圖名稱清單', 0, "$sc_v{'path'}{'plugin'}/maps.txt");
#addParseFiles("$sc_v{'path'}{'tables'}/monsters.txt", \%monsters_lut, \&parseDataFile2, '怪物名稱清單', 0, "$sc_v{'path'}{'plugin'}/monsters.txt");
#addParseFiles("$sc_v{'path'}{'tables'}/npcs.txt", \%npcs_lut, \&parseNPCs, ' NPC 清單');
#addParseFiles("$sc_v{'path'}{'tables'}/portals.txt", \%portals_lut, \&parsePortals, '傳點設定檔包含NPC傳點', 0, "$sc_v{'path'}{'tables'}/portals_*.txt");
#addParseFiles("$sc_v{'path'}{'tables'}/portalsLOS.txt", \%portals_los, \&parsePortalsLOS, '已編譯之傳點路徑');
#addParseFiles("$sc_v{'path'}{'tables'}/sex.txt", \%sex_lut, \&parseDataFile2, '性別清單');
#addParseFiles("$sc_v{'path'}{'tables'}/skills.txt", \%skills_lut, \&parseSkillsLUT, '技能清單');
#addParseFiles("$sc_v{'path'}{'tables'}/skills.txt", \%skillsID_lut, \&parseSkillsIDLUT);
#addParseFiles("$sc_v{'path'}{'tables'}/skills.txt", \%skills_rlut, \&parseSkillsReverseLUT_lc);
#addParseFiles("$sc_v{'path'}{'tables'}/skillsdescriptions.txt", \%skillsDesc_lut, \&parseRODescLUT, '技能說明資料庫');
#addParseFiles("$sc_v{'path'}{'tables'}/skillssp.txt", \%skillsSP_lut, \&parseSkillsSPLUT);
#
#addParseFiles("$sc_v{'path'}{'control'}/autologoff.txt", \%autoLogoff, \&parseDataFile_quote, '設定自動下線之人物清單');
#addParseFiles("$sc_v{'path'}{'control'}/gmaid.txt", \%GMAID_lut, \&parseGMAIDLUT, '設定自動下線之人物AID清單');
#addParseFiles("$sc_v{'path'}{'control'}/importantitems.txt", \@importantItems, \&parseDataFile3, '設定強制撿取之重要物品清單');
#addParseFiles("$sc_v{'path'}{'control'}/map_control.txt", \%map_control, \&parseMapControl, '設定限制瞬移及指定活動之地圖清單');
#addParseFiles("$sc_v{'path'}{'control'}/pfroute.txt", \@preferRoute, \&parsePreferRoute, '設定指定行走之偏好路徑清單');
#addParseFiles("$sc_v{'path'}{'control'}/shop.txt", \%myShop, \&parseDataFile2_new, '設定自動擺攤商品');
#addParseFiles("$sc_v{'path'}{'tables'}/cards.txt", \%cards_lut, \&parseROLUT, '卡片名稱清單');
#addParseFiles("$sc_v{'path'}{'tables'}/elements.txt", \%attribute_lut, \&parseROLUT, '屬性清單');
#addParseFiles("$sc_v{'path'}{'tables'}/materialdescriptions.txt", \%materialDesc_lut, \&parseRODescLUT, '鍛造物品說明資料庫');
#addParseFiles("$sc_v{'path'}{'tables'}/msgstrings.txt", \%messages_lut, \&parseMsgStrings, '狀態清單');
#addParseFiles("$sc_v{'path'}{'tables'}/stars.txt", \%stars_lut, \&parseROLUT, '武器強悍清單');
#addParseFiles("$sc_v{'path'}{'tables'}/mapalias.txt", \%mapAlias_lut, \&parseROLUT2, '相同地圖設定');
#
##addParseFiles("$sc_v{'path'}{'tables'}/recvpackets.txt", \%rpackets, \&parseDataFile2, '封包控制檔', 1);
#addParseFiles("$sc_v{'path'}{'tables'}/recvpackets.txt", \%rpackets, \&parsePacketsFile, '封包接收控制檔', 1);
#addParseFiles("$sc_v{'path'}{'tables'}/sendpackets.txt", \%spackets, \&parsePacketsFile, '封包送出控制檔');
#
#addParseFiles("$sc_v{'path'}{'tables'}/mon_mvp.txt", \@MVPID, \&parseDataFile3, ' MVP 怪物清單');
#addParseFiles("$sc_v{'path'}{'tables'}/mon_rm.txt", \@RMID, \&parseDataFile3, ' RM 怪物清單');
#
#addParseFiles("$sc_v{'path'}{'tables'}/indoor.txt", \%indoors_lut, \&parseROLUT, '室內地圖名稱清單');
#
#addParseFiles("$sc_v{'path'}{'tables'}/modifiedWalk.txt", \%modifiedWalk, \&parseDataFile2, '移動時使用修正座標資料檔');
#
#addParseFiles("$sc_v{'path'}{'tables'}/guilds.txt", \%guilds_lut, \&parseDataFile2, '工會名稱清單');

addParseFiles("$sc_v{'path'}{'control'}/autologoff.txt", \%autoLogoff, \&parseDataFile_quote, '設定自動下線之人物清單');
addParseFiles("$sc_v{'path'}{'control'}/gmaid.txt", \%GMAID_lut, \&parseGMAIDLUT, '設定自動下線之人物AID清單');
addParseFiles("$sc_v{'path'}{'control'}/importantitems.txt", \@importantItems, \&parseDataFile3, '設定強制撿取之重要物品清單');
addParseFiles("$sc_v{'path'}{'control'}/items_control.txt", \%items_control, \&parseItemsControl, '設定自動存放、自動賣出之物品清單');
addParseFiles("$sc_v{'path'}{'control'}/map_control.txt", \%map_control, \&parseMapControl, '設定限制瞬移及指定活動之地圖清單');
addParseFiles("$sc_v{'path'}{'control'}/mon_control.txt", \%mon_control, \&parseMonControl, '設定自動攻擊、自動逃離、自動搜尋之怪物清單');
addParseFiles("$sc_v{'path'}{'control'}/overallauth.txt", \%overallAuth, \&parseDataFile, '設定授權使用遙控功能之玩家清單');
addParseFiles("$sc_v{'path'}{'control'}/pfroute.txt", \@preferRoute, \&parsePreferRoute, '設定指定行走之偏好路徑清單');
addParseFiles("$sc_v{'path'}{'control'}/pickupitems.txt", \%itemsPickup, \&parseDataFile_lc, '設定要自動撿取之物品清單');
#addParseFiles("$sc_v{'path'}{'control'}/responses.txt", \%responses, \&parseResponses, '設定遠端遙控之回應清單');
addParseFiles("$sc_v{'path'}{'control'}/shop.txt", \%myShop, \&parseDataFile2_new, '設定自動擺攤商品');
addParseFiles("$sc_v{'path'}{'control'}/timeouts.txt", \%timeout, \&parseTimeouts, 'Timeouts控制設定');
addParseFiles("$sc_v{'path'}{'tables'}/cards.txt", \%cards_lut, \&parseROLUT, '卡片名稱清單');
addParseFiles("$sc_v{'path'}{'tables'}/cities.txt", \%cities_lut, \&parseROLUT, '城市地圖名稱清單');
addParseFiles("$sc_v{'path'}{'tables'}/elements.txt", \%attribute_lut, \&parseROLUT, '屬性清單');
addParseFiles("$sc_v{'path'}{'tables'}/emotions.txt", \%emotions_lut, \&parseDataFile2, '表情清單');
addParseFiles("$sc_v{'path'}{'tables'}/equiptypes.txt", \%equipTypes_lut, \&parseDataFile2, '裝備物品類別清單');
addParseFiles("$sc_v{'path'}{'tables'}/guilds.txt", \%guilds_lut, \&parseDataFile2, '工會名稱清單');
addParseFiles("$sc_v{'path'}{'tables'}/indoor.txt", \%indoors_lut, \&parseROLUT, '室內地圖名稱清單');
addParseFiles("$sc_v{'path'}{'tables'}/items.txt", \%items_lut, \&parseROLUT, '物品名稱清單', 0, "$sc_v{'path'}{'plugin'}/items.txt");
addParseFiles("$sc_v{'path'}{'tables'}/itemsdescriptions.txt", \%itemsDesc_lut, \&parseRODescLUT, '物品說明資料庫');
addParseFiles("$sc_v{'path'}{'tables'}/itemslots.txt", \%itemSlots_lut, \&parseROSlotsLUT, "裝備物品類別設定檔");
addParseFiles("$sc_v{'path'}{'tables'}/itemtypes.txt", \%itemTypes_lut, \&parseDataFile2, '物品類別清單');
addParseFiles("$sc_v{'path'}{'tables'}/jobs.txt", \%jobs_lut, \&parseDataFile2, '職業清單');
addParseFiles("$sc_v{'path'}{'tables'}/mapalias.txt", \%mapAlias_lut, \&parseROLUT2, '相同地圖設定');
addParseFiles("$sc_v{'path'}{'tables'}/maps.txt", \%maps_lut, \&parseROLUT, '地圖名稱清單', 0, "$sc_v{'path'}{'plugin'}/maps.txt");
addParseFiles("$sc_v{'path'}{'tables'}/materialdescriptions.txt", \%materialDesc_lut, \&parseRODescLUT, '鍛造物品說明資料庫');
addParseFiles("$sc_v{'path'}{'tables'}/modifiedWalk.txt", \%modifiedWalk, \&parseDataFile2, '移動時使用修正座標資料檔');
addParseFiles("$sc_v{'path'}{'tables'}/mon_mvp.txt", \@MVPID, \&parseDataFile3, ' MVP 怪物清單');
addParseFiles("$sc_v{'path'}{'tables'}/mon_rm.txt", \@RMID, \&parseDataFile3, ' RM 怪物清單');
addParseFiles("$sc_v{'path'}{'tables'}/monsters.txt", \%monsters_lut, \&parseDataFile2, '怪物名稱清單', 0, "$sc_v{'path'}{'plugin'}/monsters.txt");
addParseFiles("$sc_v{'path'}{'tables'}/msgstrings.txt", \%messages_lut, \&parseMsgStrings, '狀態清單');
addParseFiles("$sc_v{'path'}{'tables'}/npcs.txt", \%npcs_lut, \&parseNPCs, ' NPC 清單');
addParseFiles("$sc_v{'path'}{'tables'}/portals.txt", \%portals_lut, \&parsePortals, '傳點設定檔包含NPC傳點', 0, "$sc_v{'path'}{'tables'}/portals_*.txt");
addParseFiles("$sc_v{'path'}{'tables'}/portalsLOS.txt", \%portals_los, \&parsePortalsLOS, '已編譯之傳點路徑');
addParseFiles("$sc_v{'path'}{'tables'}/recvpackets.txt", \%rpackets, \&parsePacketsFile, '封包接收控制檔', 1);
addParseFiles("$sc_v{'path'}{'tables'}/sendpackets.txt", \%spackets, \&parsePacketsFile, '封包送出控制檔');
addParseFiles("$sc_v{'path'}{'tables'}/sex.txt", \%sex_lut, \&parseDataFile2, '性別清單');
addParseFiles("$sc_v{'path'}{'tables'}/skills.txt", \%skillsID_lut, \&parseSkillsIDLUT);
addParseFiles("$sc_v{'path'}{'tables'}/skills.txt", \%skills_lut, \&parseSkillsLUT, '技能清單');
addParseFiles("$sc_v{'path'}{'tables'}/skills.txt", \%skills_rlut, \&parseSkillsReverseLUT_lc);
addParseFiles("$sc_v{'path'}{'tables'}/skillsdescriptions.txt", \%skillsDesc_lut, \&parseRODescLUT, '技能說明資料庫');
addParseFiles("$sc_v{'path'}{'tables'}/skillssp.txt", \%skillsSP_lut, \&parseSkillsSPLUT, '技能SP清單');
addParseFiles("$sc_v{'path'}{'tables'}/stars.txt", \%stars_lut, \&parseROLUT, '武器強悍清單');

load(\@{$sc_v{'parseFiles'}});

goto KORECLOSE if ($quit);

#Karasu Start
importDynaLib();
#Karasu End
{
	my ($msg, $found, $i);

#	# Auto generate if null
#	if ($config{'adminPassword'} eq 'x' x 10 || $config{'adminPassword'} eq "") {
#		print "\n隨機產生遠端控制授權密碼\n";
##		configModify("adminPassword", vocalString(10));
#		scModify("config", "adminPassword", vocalString(10), 1);
#	}
#
#	# Auto generate if null
#	if ($config{'callSign'} eq 'x' x 10 || $config{'callSign'} eq "") {
#		print "\n隨機產生遠端控制前置字詞\n";
##		configModify("callSign", vocalString(10));
#		scModify("config", "callSign", vocalString(10), 1);
#	}

	###COMPILE PORTALS###

	print "\n檢查是否有新傳送點資料... ";
	compilePortals_check(\$found);

	if ($found) {
		print "發現新傳送點資料！\n";
		print "立即編譯(y/n)？, $timeout{'compilePortals_auto'}{'timeout'}秒後自動編譯...\n";

		timeOutStart('compilePortals_auto');

		undef $msg;
		while (!checkTimeOut('compilePortals_auto')) {
			if (dataWaiting(\$input_socket)) {
	#			$input_socket->recv($msg, $MAX_READ);
				$msg = input_readLine();
			}
			last if $msg;
		}
		if ($msg =~ /y/ || $msg eq "") {
			print "開始編譯\n";
			compilePortals();
		} else {
			print "取消編譯\n";
		}
	} else {
		print "無新傳送點資料\n";
	}

	if (!$option{'X-Kore'}) {
		undef $msg;

		print "\n為保護帳密安全，輸入的資料將不會顯示於畫面上\n" if (!$config{'username'} || !$config{'password'});

		if (!$config{'username'}) {
			print "請輸入遊戲帳號:\n";
			setColor($FG_BLACK);

			$msg = input_readLine();
			$config{'username'} = $msg;
#			writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);

#			updateDataFile2_new("$sc_v{'path'}{'control'}/config.txt", \%config);

#			scUpdate("config");

			setColor($sc_v{'Console'}{'original'});
		}
		if (!$config{'password'}) {
			print "請輸入遊戲密碼:\n";
			setColor($FG_BLACK);

			$msg = input_readLine();
			$config{'password'} = $msg;
#			writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);

#			updateDataFile2_new("$sc_v{'path'}{'control'}/config.txt", \%config);

#			scUpdate("config");

			setColor($sc_v{'Console'}{'original'});
		}

		if ($config{'master'} eq "") {
			$i = 0;
			$~ = "MASTERS";
			print "------------------ 主伺服器 ------------------\n";
			print "#   名稱                                      \n";
			while ($config{"master_name_$i"} ne "") {
				format MASTERS =
@<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$i, $config{"master_name_$i"}
.
				write;
				$i++;
			}
			print "----------------------------------------------\n";
			print "選擇主伺服器, 請輸入編號:\n";
			$msg = input_readLine();
			$config{'master'} = $msg;
#			writeDataFileIntact("$sc_v{'path'}{'control'}/config.txt", \%config);

#			updateDataFile2_new("$sc_v{'path'}{'control'}/config.txt", \%config);

#			scUpdate("config");
		}

		scUpdate("config") if ($msg ne "");

	} else {
		$timeout{'injectSync'}{'time'} = time;
	}

	undef $msg;
}

$sc_v{'input'}{'conState'} = 1;
$sc_v{'input'}{'startTime'} = time;
#Ayon Start
$sc_v{'input'}{'FirstStart'} = 1;
$sc_v{'input'}{'MinWaitRecon'} = 1;
$sc_v{'kore'}{'startTime'} = time;
$sc_v{'input'}{'errorCount'} = 0;
$sc_v{'input'}{'waitingForInput'} = 0;
#Ayon End

$sc_v{'parseMsg'}{'server_name'} = "x-kore";

our ($input, $msg, $msg_length);
our ($accountID, $sessionID);

our ($ai_cmdQue_shift, @ai_cmdQue);

while ($quit != 1) {
	usleep($config{'sleepTime'});

	if ($option{'X-Kore'}) {
		if (timeOut(\%{$timeout{'injectKeepAlive'}})) {
			$conState = 1;
			my $printed = 0;
			my $procID = 0;
			do {
				$procID = $GetProcByName->Call($option{'X-Kore_exeName'});
				if (!$procID) {
					print "Error: Could not locate process $option{'X-Kore_exeName'}.\nWaiting for you to start the process..." if (!$printed);
					$printed = 1;
				}
				sleep 2;
			} while (!$procID && !$quit);

			if ($printed == 1) {
				print "Process found\n";
			}
			my $InjectDLL = new Win32::API("Tools", "InjectDLL", "NP", "I");
			my $retVal = $InjectDLL->Call($procID, $injectDLL_file) || die "Could not inject DLL";

			print "Waiting for InjectDLL to connect...\n";
			$remote_socket = $injectServer_socket->accept();
			(inet_aton($remote_socket->peerhost()) == inet_aton('localhost')) || die "Inject Socket must be connected from localhost";
			print "InjectDLL Socket connected - Ready to start botting\n";
			$timeout{'injectKeepAlive'}{'time'} = time;


#			等待溝通協定連結中...
#			溝通協定連結完成 - 準備進入自動控制狀態
		}
		if (timeOut(\%{$timeout{'injectSync'}})) {
			sendSyncInject(\$remote_socket);
			$timeout{'injectSync'}{'time'} = time;
		}
	}

	if (dataWaiting(\$input_socket)) {
#		$stop = 1;
		$input = input_readLine();
		parseInput($input, 1);
	} elsif (!$option{'X-Kore'} && dataWaiting(\$remote_socket)) {
		$remote_socket->recv($new, $MAX_READ);
		$msg .= $new;
		$msg_length = length($msg);
		while ($msg ne "") {
			$msg = parseMsg($msg);
			last if ($msg_length == length($msg));
			$msg_length = length($msg);
		}
	} elsif ($option{'X-Kore'} && dataWaiting(\$remote_socket)) {
		my $injectMsg;
		$remote_socket->recv($injectMsg, $MAX_READ);
		while ($injectMsg ne "") {
			if (length($injectMsg) < 3) {
				undef $injectMsg;
				break;
			}
			my $type = substr($injectMsg, 0, 1);
			my $len = unpack("S",substr($injectMsg, 1, 2));
			my $newMsg = substr($injectMsg, 3, $len);
			$injectMsg = (length($injectMsg) >= $len+3) ? substr($injectMsg, $len+3, length($injectMsg) - $len - 3) : "";
			if ($type eq "R") {
				$msg .= $newMsg;
				$msg_length = length($msg);
				while ($msg ne "") {
					$msg = parseMsg($msg);
					last if ($msg_length == length($msg));
					$msg_length = length($msg);
				}
			} elsif ($type eq "S") {
				parseSendMsg($newMsg);
			}
			$timeout{'injectKeepAlive'}{'time'} = time;
		}
	}
#	$ai_cmdQue_shift = 0;
#	do {
#		AI(\%{$ai_cmdQue[$ai_cmdQue_shift]}) if (
#			!$ai_v{'teleOnGM'}
#			&& $sc_v{'input'}{'conState'} == 5
#			&& checkTimeOut('ai')
#			&& $remote_socket
#			&& $remote_socket->connected()
#		);
#		undef %{$ai_cmdQue[$ai_cmdQue_shift++]};
#		$ai_cmdQue-- if ($ai_cmdQue > 0);
#	} while ($ai_cmdQue > 0);
	
	AI() if (
		!$ai_v{'teleOnGM'}
		&& $sc_v{'input'}{'conState'} == 5
		&& checkTimeOut('ai')
		&& $remote_socket
		&& $remote_socket->connected()
	);

	checkConnection();
}
#close($input_server_socket);
#close($input_socket);
#kill 9, $input_pid;
#killConnection(\$remote_socket);
##Karasu Start
## EXPs gained per hour
#parseInput("exp log") if ($config{'recordExp'} && $record{'exp'}{'start'} ne "" && !(($sc_v{'input'}{'conState'} == 2 || $sc_v{'input'}{'conState'} == 3) && $sc_v{'input'}{'waitingForInput'}));
##Karasu End
#
##if ($restartNow == 1 && $config{'unstuckAuto_utcount_exeName'}) {
##	Win32::Process::Create($Process, $config{'unstuckAuto_utcount_exeName'}, "", 0, CREATE_SEPARATE_WOW_VDM, ".");
##}
#sleep(2);

KORECLOSE:

kore_close($sc_v{'kore'}{'delay'});

exit;


#Ayon End
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             