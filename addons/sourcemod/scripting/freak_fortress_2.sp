/*
===Freak Fortress 2===

By Rainbolt Dash: programmer, modeller, mapper, painter.
Author of Demoman The Pirate: http://www.randomfortress.ru/thepirate/
And one of two creators of Floral Defence: http://www.polycount.com/forum/showthread.php?t=73688
And author of VS Saxton Hale Mode
And notoriously famous for creating plugins with terrible code and then abandoning them.

Plugin thread on AlliedMods: http://forums.alliedmods.net/showthread.php?t=182108

Updated by Otokiru, Powerlord, and RavensBro after Rainbolt Dash got sucked into DOTA2

Updated by Wliu, Chris, Lawd, and Carge after Powerlord quit FF2
*/
// #pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>
#include <POTRY>
#include <adt_array>
#include <clientprefs>
#include <morecolors>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
// #include <custompart>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
//#tryinclude <smac>
#tryinclude <goomba>
#tryinclude <rtd>
#tryinclude <tf2attributes>

#include <freak_fortress_2/bosses>

#include "freak_fortress_2/stocks.sp"
#include "freak_fortress_2/natives/ff2boss.sp"

#define REQUIRE_PLUGIN

#define MAJOR_REVISION "1"
#define MINOR_REVISION "15"
#define STABLE_REVISION "3"
#define DEV_REVISION "(NEXT 2.0)"
#define BUILD_NUMBER "manual"  //This gets automagically updated by Jenkins
#if !defined DEV_REVISION
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION  //1.10.14
#else
	#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION..." "...DEV_REVISION
#endif

// #define UPDATE_URL "http://50dkp.github.io/FF2-Official/update.txt"

#define MAXENTITIES 2048
#define MAXSPECIALS 64
#define MAXRANDOMS 16

#define SOUNDEXCEPT_MUSIC 0
#define SOUNDEXCEPT_VOICE 1

#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX 255
#define MONOCULUS "eyeball_boss"
#define DISABLED_PERKS "toxic,noclip,uber,ammo,instant,jump,tinyplayer"

#if defined _steamtools_included
bool steamtools=false;
#endif

#if defined _tf2attributes_included
bool tf2attributes=false;
#endif

#if defined _goomba_included
bool goomba=false;
#endif

bool smac=false;
bool CheckedFirstRound=false;
// bool MapIsRunning=false;

int OtherTeam=2;
int BossTeam=3;
int playing;
int healthcheckused;
int RedAlivePlayers;
int BlueAlivePlayers;
int RoundCount;
// int RPSWinner;
int RPSLoser[MAXPLAYERS+1];
int Special[MAXPLAYERS+1];
int Incoming[MAXPLAYERS+1];

int Damage[MAXPLAYERS+1];
int curHelp[MAXPLAYERS+1];
int uberTarget[MAXPLAYERS+1];
int shield[MAXPLAYERS+1];
int detonations[MAXPLAYERS+1];
int GoombaCount[MAXPLAYERS+1];
int selectedBGM[MAXPLAYERS+1];
bool playBGM[MAXPLAYERS+1]=true;

char currentBGM[MAXPLAYERS+1][PLATFORM_MAX_PATH];

int FF2flags[MAXPLAYERS+1];
int FF2Userflags[MAXPLAYERS+1];
int FF2ServerFlag;

int DPSTick;
float PlayerDamageDPS[MAXPLAYERS+1][5];
int HighestDPSClient;
float HighestDPS;

int MainBoss;
int Boss[MAXPLAYERS+1];
int BossDiff[MAXPLAYERS+1];
int BossHealthMax[MAXPLAYERS+1];
int BossHealth[MAXPLAYERS+1];
int BossHealthLast[MAXPLAYERS+1];
int BossLives[MAXPLAYERS+1];
int BossLivesMax[MAXPLAYERS+1];
int BossRageDamage[MAXPLAYERS+1];
// char BossRageName[MAXPLAYERS+1][9][68];

char BossRageName[MAXPLAYERS+1][68];
char BossUpgradeRageName[MAXPLAYERS+1][68];
bool IsUpgradeRage[MAXPLAYERS+1];

float BossAbilityCooldown[MAXPLAYERS+1][9];
float BossAbilityCooldownMax[MAXPLAYERS+1][9];
float BossAbilityDuration[MAXPLAYERS+1][9];
float BossAbilityDurationMax[MAXPLAYERS+1][9];

float BossCharge[MAXPLAYERS+1][9];
float BossMaxRageCharge[MAXPLAYERS+1];
bool IsBossYou[MAXPLAYERS+1];
int Stabbed[MAXPLAYERS+1];
int Marketed[MAXPLAYERS+1];
float KSpreeTimer[MAXPLAYERS+1];
// float playerDPS=0.0;
int KSpreeCount[MAXPLAYERS+1];
float GlowTimer[MAXPLAYERS+1];
int shortname[MAXPLAYERS+1];
bool emitRageSound[MAXPLAYERS+1];
bool bossHasReloadAbility[MAXPLAYERS+1];
bool bossHasRightMouseAbility[MAXPLAYERS+1];
bool playingCustomBossBGM[MAXPLAYERS+1];
bool playingCustomBGM[MAXPLAYERS+1];
bool DEVmode=false;

int timeleft;
float AFKTime;
bool IsBossDoing[MAXPLAYERS+1];

Handle cvarVersion;
Handle cvarPointDelay;
Handle cvarAnnounce;
Handle cvarEnabled;
Handle cvarAliveToEnable;
Handle cvarPointType;
Handle cvarCrits;
Handle cvarFirstRound;  //DEPRECATED
Handle cvarArenaRounds;
Handle cvarCircuitStun;
Handle cvarSpecForceBoss;
Handle cvarCountdownPlayers;
Handle cvarCountdownTime;
Handle cvarCountdownHealth;
Handle cvarCountdownResult;
Handle cvarEnableEurekaEffect;
Handle cvarForceBossTeam;
Handle cvarHealthBar;
Handle cvarLastPlayerGlow;
Handle cvarBossTeleporter;
Handle cvarBossSuicide;
Handle cvarShieldCrits;
Handle cvarCaberDetonations;
Handle cvarGoombaDamage;
Handle cvarGoombaRebound;
Handle cvarBossRTD;
Handle cvarDebug;
Handle cvarPreroundBossDisconnect;
// Handle cvarStunTime;
// Handle cvarStunRange;
// Database FF2Database;

Handle FF2Cookies;
Handle YouSpecial;

Handle jumpHUD;
Handle rageHUD;
Handle livesHUD;
Handle timeleftHUD;
Handle abilitiesHUD;
Handle infoHUD;

bool Enabled=true;
bool Enabled2=true;
int PointDelay=6;
float Announce=120.0;
int AliveToEnable=5;
int PointType;
bool BossCrits = true;
int arenaRounds;
float circuitStun;
int countdownPlayers=1;
int countdownTime=120;
int countdownHealth=2000;
bool SpecForceBoss;
bool lastPlayerGlow=true;
bool bossTeleportation=true;
int shieldCrits;
int allowedDetonations;
float GoombaDamage=0.05;
float reboundPower=300.0;
bool canBossRTD;
bool HasCompanions;
bool NoticedLastman=false;

Handle MusicTimer[MAXPLAYERS+1];
// Handle BossSoloRageDelayTimer[MAXPLAYERS+1];
Handle BossInfoTimer[MAXPLAYERS+1][2];
Handle DrawGameTimer;
Handle doorCheckTimer;
Handle LoadedMusicData;

int botqueuepoints;
float HPTime;
char currentmap[99];
bool checkDoors=false;
bool bMedieval;
bool firstBlood;

int tf_arena_use_queue;
int mp_teams_unbalance_limit;
int tf_arena_first_blood;
int mp_forcecamera;
int tf_dropped_weapon_lifetime;
float tf_feign_death_activate_damage_scale;
float tf_feign_death_damage_scale;
char mp_humans_must_join_team[16];

Handle cvarNextmap;
bool areSubPluginsEnabled;

int FF2CharSet;
int validCharsets[64];
char FF2CharSetString[42];
bool isCharSetSelected=false;

int healthBar=-1;
int g_Monoculus=-1;

static bool executed=false;
static bool executed2=false;

int changeGamemode;

enum Operators
{
	Operator_None=0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent,
};

static const char ff2versiontitles[][]=
{
	"1.0",
	"1.01",
	"1.01",
	"1.02",
	"1.03",
	"1.04",
	"1.05",
	"1.05",
	"1.06",
	"1.06c",
	"1.06d",
	"1.06e",
	"1.06f",
	"1.06g",
	"1.06h",
	"1.07 beta 1",
	"1.07 beta 1",
	"1.07 beta 1",
	"1.07 beta 1",
	"1.07 beta 1",
	"1.07 beta 4",
	"1.07 beta 5",
	"1.07 beta 6",
	"1.07",
	"1.0.8",
	"1.0.8",
	"1.0.8",
	"1.0.8",
	"1.0.8",
	"1.9.0",
	"1.9.0",
	"1.9.1",
	"1.9.2",
	"1.9.2",
	"1.9.3",
	"1.10.0",
	"1.10.0",
	"1.10.0",
	"1.10.0",
	"1.10.0",
	"1.10.0",
	"1.10.0",
	"1.10.0",
	"1.10.1",
	"1.10.1",
	"1.10.1",
	"1.10.1",
	"1.10.1",
	"1.10.2",
	"1.10.3",
	"1.10.3",
	"1.10.3",
	"1.10.3",
	"1.10.3",
	"1.10.4",
	"1.10.4",
	"1.10.4",
	"1.10.4",
	"1.10.4",
	"1.10.5",
	"1.10.6",
	"1.10.6",
	"1.10.6",
	"1.10.6",
	"1.10.7",
	"1.10.7",
	"1.10.7",
	"1.10.8",
	"1.10.9",
	"1.10.9",
	"1.10.9",
	"1.10.9",
	"1.10.9",
	"1.10.10",
	"1.10.11",
	"1.10.12",
	"1.10.13",
	"1.10.14"
};

static const char ff2versiondates[][]=
{
	"6 April 2012",			//1.0
	"14 April 2012",		//1.01
	"14 April 2012",		//1.01
	"17 April 2012",		//1.02
	"19 April 2012",		//1.03
	"21 April 2012",		//1.04
	"29 April 2012",		//1.05
	"29 April 2012",		//1.05
	"1 May 2012",			//1.06
	"22 June 2012",			//1.06c
	"3 July 2012",			//1.06d
	"24 Aug 2012",			//1.06e
	"5 Sep 2012",			//1.06f
	"5 Sep 2012",			//1.06g
	"6 Sep 2012",			//1.06h
	"8 Oct 2012",			//1.07 beta 1
	"8 Oct 2012",			//1.07 beta 1
	"8 Oct 2012",			//1.07 beta 1
	"8 Oct 2012",			//1.07 beta 1
	"8 Oct 2012",			//1.07 beta 1
	"11 Oct 2012",			//1.07 beta 4
	"18 Oct 2012",			//1.07 beta 5
	"9 Nov 2012",			//1.07 beta 6
	"14 Dec 2012",			//1.07
	"October 30, 2013",		//1.0.8
	"October 30, 2013",		//1.0.8
	"October 30, 2013",		//1.0.8
	"October 30, 2013",		//1.0.8
	"October 30, 2013",		//1.0.8
	"March 6, 2014",		//1.9.0
	"March 6, 2014",		//1.9.0
	"March 18, 2014",		//1.9.1
	"March 22, 2014",		//1.9.2
	"March 22, 2014",		//1.9.2
	"April 5, 2014",		//1.9.3
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"August 28, 2014",		//1.10.1
	"August 28, 2014",		//1.10.1
	"August 28, 2014",		//1.10.1
	"August 28, 2014",		//1.10.1
	"August 28, 2014",		//1.10.1
	"August 28, 2014",		//1.10.2
	"November 6, 2014",		//1.10.3
	"November 6, 2014",		//1.10.3
	"November 6, 2014",		//1.10.3
	"November 6, 2014",		//1.10.3
	"November 6, 2014",		//1.10.3
	"March 1, 2015",		//1.10.4
	"March 1, 2015",		//1.10.4
	"March 1, 2015",		//1.10.4
	"March 1, 2015",		//1.10.4
	"March 1, 2015",		//1.10.4
	"March 13, 2015",		//1.10.5
	"August 10, 2015",		//1.10.6
	"August 10, 2015",		//1.10.6
	"August 10, 2015",		//1.10.6
	"August 10, 2015",		//1.10.6
	"November 19, 2015",	//1.10.7
	"November 19, 2015",	//1.10.7
	"November 19, 2015",	//1.10.7
	"November 24, 2015",		//1.10.8
	"May 3, 2016",  //1.10.9
	"May 3, 2016",  //1.10.9
	"May 3, 2016", //1.10.9
	"May 3, 2016", //1.10.9
	"May 3, 2016",  //1.10.9
	"July 24, 2016",			//1.10.10
	"August 1, 2016",		//1.10.11
	"August 3, 2016",		//1.10.12
	"September 1, 2016",		//1.10.13
	"October 21, 2016"		//1.10.14
};

stock FindVersionData(Handle:panel, versionIndex)
{
	switch(versionIndex)
	{
		case 77:  //1.10.14
 		{
 			DrawPanelText(panel, "1) Fixed minions occasionally spawning on the wrong team (Wliu from various)");
 			DrawPanelText(panel, "2) Fixed ff2_start_music at the start of the round causing music to overlap (naydef)");
 			DrawPanelText(panel, "3) Fixed new clients not hearing music in certain circumstances (naydef)");
 		}
		case 76:  //1.10.13
 		{
 			DrawPanelText(panel, "1) Fixed insta-backstab issues (Wliu from tom0034)");
 			DrawPanelText(panel, "2) Fixed team-changing exploit (Wliu from Edge_)");
 			DrawPanelText(panel, "3) [Server] Fixed an error message logging the wrong values (Wliu)");
		}
		case 75:  //1.10.12
 		{
 			DrawPanelText(panel, "1) Actually fixed BGMs not looping (Wliu from WakaFlocka, again)");
 			DrawPanelText(panel, "2) Fixed new clients not respecting the current music state (Wliu from shadow93)");
 		}
		case 74:  //1.10.11
 		{
 			DrawPanelText(panel, "1) Fixed BGMs not looping (Wliu from WakaFlocka)");
 		}
		case 73:  //1.10.10
 		{
 			DrawPanelText(panel, "1) Fixed multiple BGM issues in 1.10.9 (Wliu, shadow93, Nopied, WakaFlocka, and others)");
 			DrawPanelText(panel, "2) Automatically start BGMs for new clients (Wliu)");
 			DrawPanelText(panel, "3) Fixed the top damage dealt sometimes displaying as 0 damage (naydef)");
 			DrawPanelText(panel, "4) Added back Shortstop reload penalty to reflect its buff in the Meet Your Match update (Wliu)");
 			DrawPanelText(panel, "5) [Server] Fixed an invalid client error in ff2_1st_set_abilities.sp (Wliu)");
 			DrawPanelText(panel, "6) [Server] Fixed a GetEntProp error (Wliu from Hemen353)");
 		}
		case 72:  //1.10.9
 		{
 			DrawPanelText(panel, "1) Fixed a critical exploit related to sv_cheats (naydef)");
 			DrawPanelText(panel, "2) Updated weapons for the Tough Break update (Wliu)");
 			DrawPanelText(panel, "Partially synced with VSH (all changes listed courtesy of VSH contributors and shadow93)");
 			DrawPanelText(panel, "2) VSH: Don't play end-of-round announcer sounds");
 			DrawPanelText(panel, "3) VSH: Increase boss damage to 210%% (up from 200%%)");
 			DrawPanelText(panel, "See next page (press 1)");
 		}
 		case 71:  //1.10.9
 		{
 			DrawPanelText(panel, "4) VSH: Give scout bosses +3 capture rate instead of +4");
 			DrawPanelText(panel, "5) VSH: Don't actually call for medic when activating rage");
 			DrawPanelText(panel, "6) VSH: Override attributes for all mediguns and syringe guns");
 			DrawPanelText(panel, "7) Fixed Ambassador, Diamondback, Phlogistinator, and the Manmelter not dealing the correct damage (Dalix)");
 			DrawPanelText(panel, "8) Adjusted medgiun and Dead Ringer mechanics to provide a more native experience (Wliu)");
 			DrawPanelText(panel, "See next page (press 1)");
 		}
 		case 70:  //1.10.9
 		{
 			DrawPanelText(panel, "9) Prevent `autoteam` spam and possible crashes (naydef)");
 			DrawPanelText(panel, "10) Fixed boss's health not appearing correctly before round start (Wliu)");
 			DrawPanelText(panel, "11) Fixed ff2_alive...again (Wliu from Dalix)");
 			DrawPanelText(panel, "12) Fixed BossInfoTimer (that thing no one knows about because it never worked) (Wliu)");
 			DrawPanelText(panel, "13) Reset clone status properly (Wliu)");
 			DrawPanelText(panel, "See next page (press 1)");
 		}
 		case 69:  //1.10.9
 		{
 			DrawPanelText(panel, "13) Don't allow sound_kill_* and sound_hit to overlap each other (Wliu from WakaFlocka)");
 			DrawPanelText(panel, "14) Prevent sound_lastman sounds from overlapping with regular kill sounds (Wliu from WakaFlocka)");
 			DrawPanelText(panel, "15) [Server] Make sure the entity is valid before creating a healthbar (shadow93)");
 			DrawPanelText(panel, "16) [Server] Fixed invalid client errors originating from ff2_1st_set_abilities.sp (Wliu)");
 			DrawPanelText(panel, "17) [Server] Added ff2_start_music command for symmetry (Wliu from WakaFlocka)");
 			DrawPanelText(panel, "See next page (press 1)");
 		}
 		case 68:  //1.10.9
 		{
 			DrawPanelText(panel, "18) [Dev] Actually make FF2_OnMusic work (Wliu from shadow93)");
 			DrawPanelText(panel, "19) [Dev] Rewrote BGM code (Wliu)");
 			DrawPanelText(panel, "20) [Dev] Fixed ability sounds playing even if the ability was canceled in FF2_PreAbility (Wliu from xNanoChip)");
 		}
		case 67:  //1.10.8
		{
			DrawPanelText(panel, "1) Fixed the Powerjack and Kunai killing the boss in one hit (naydef)");
		}
		case 66:  //1.10.7
		{
			DrawPanelText(panel, "1) Fixed companions always having default rage damage and lives, even if specified otherwise (Wliu from Shadow)");
			DrawPanelText(panel, "2) Fixed bosses instantly losing if a boss disconnected while there were still other bosses alive (Shadow from Spyper)");
			DrawPanelText(panel, "3) Fixed minions receiving benefits intended only for normal players (Wliu)");
			DrawPanelText(panel, "4) Removed Shortstop reload penalty (Starblaster64)");
			DrawPanelText(panel, "5) Whitelisted the Shooting Star (Wliu)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 65:  //1.10.7
		{
			DrawPanelText(panel, "6) Fixed large amounts of lives being cut off when being displayed (Wliu)");
			DrawPanelText(panel, "7) More living spectator fixes (naydef, Shadow)");
			DrawPanelText(panel, "8) Fixed health bar not updating when goomba-ing the boss (Wliu from Akuba)");
			DrawPanelText(panel, "9) [Server] Added arg12 to rage_cloneattack to determine whether or not clones die after their boss dies (Wliu");
			DrawPanelText(panel, "10) [Server] Fixed 'UTIL_SetModel not precached' crashes when using 'model_projectile_replace' (Wliu from Shadow)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 64:  //1.10.7
		{
			DrawPanelText(panel, "11) [Server] 'ff2_crits' now defaults to 0 instead of 1 (Wliu from Spyper)");
			DrawPanelText(panel, "12) [Server] Fixed divide by 0 errors (Wliu)");
			DrawPanelText(panel, "13) [Dev] Fixed FF2_OnAlivePlayersChanged not returning the number of minions (Wliu)");
			DrawPanelText(panel, "14) [Dev] Fixed PDAs and sappers not being usable when given to bosses (Shadow)");
		}
		case 63:  //1.10.6
		{
			DrawPanelText(panel, "1) Updated the default health formula to match VSH's (Wliu)");
			DrawPanelText(panel, "2) Updated for compatability with the Gunmettle update (Wliu, Shadow, Starblaster64, Chdata, sarysa, and others)");
			DrawPanelText(panel, "3) Fixed boss weapon animations sometimes not working (Chdata)");
			DrawPanelText(panel, "4) Disconnecting bosses now get replaced by the person with the second-highest queue points (Shadow)");
			DrawPanelText(panel, "5) Fixed bosses rarely becoming 'living spectators' during the first round (Shadow/Wliu)");
			DrawPanelText(panel, "See next page (press 1");
		}
		case 62:  //1.10.6
		{
			DrawPanelText(panel, "6) Fixed large amounts of damage insta-killing multi-life bosses (Wliu from Shadow)");
			DrawPanelText(panel, "7) Fixed death effects triggering when FF2 wasn't active (Shadow)");
			DrawPanelText(panel, "8) Fixed 'sound_fail' playing even when the boss won (Shadow)");
			DrawPanelText(panel, "9) Fixed charset voting again (Wliu from Shadow)");
			DrawPanelText(panel, "10) Fixed bravejump sounds not playing (Wliu from Maximilian_)");
			DrawPanelText(panel, "See next page (press 1");
		}
		case 61:  //1.10.6
		{
			DrawPanelText(panel, "11) Fixed end-of-round text occasionally showing random symbols and file paths (Wliu)");
			DrawPanelText(panel, "12) Updated Russian translations (Maximilian_)");
			DrawPanelText(panel, "13) [Server] Fixed 'UTIL_SetModel not precached' crashes-see #18 for the underlying fix (Shadow/Wliu)");
			DrawPanelText(panel, "14) [Server] Fixed Array Index Out of Bounds errors when there are more than 32 chances (Wliu from Maximilian_)");
			DrawPanelText(panel, "15) [Server] Fixed invalid client errors in easter_abilities.sp (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 60:  //1.10.6
		{
			DrawPanelText(panel, "16) [Server] Missing boss files are now logged (Shadow)");
			DrawPanelText(panel, "17) [Dev] Added FF2_StartMusic that was missing from the include file (Wliu from Shadow)");
			DrawPanelText(panel, "18) [Dev] FF2_GetBossIndex now makes sure the client index passed is valid (Wliu)");
			DrawPanelText(panel, "19) [Dev] Rewrote the health formula parser and fixed a few bugs along the way (WildCard65/Wliu)");
			DrawPanelText(panel, "20) [Dev] Prioritized exact matches in OnSpecialSelected and added a 'preset' bool (Wliu from Shadow)");
			DrawPanelText(panel, "21) [Dev] Removed deprecated FCVAR_PLUGIN cvar flags (Wliu)");
		}
		case 59:  //1.10.5
		{
			DrawPanelText(panel, "1) Fixed slow-mo being extremely buggy (Wliu from various)");
			DrawPanelText(panel, "2) Fixed the Festive SMG not getting crits (Wliu from Dalix)");
			DrawPanelText(panel, "3) Fixed teleport sounds not being played (Wliu from Dalix)");
			DrawPanelText(panel, "4) !ff2_stop_music can now target specific clients (Wliu)");
			DrawPanelText(panel, "5) [Server] Fixed multiple sounds not working after TF2 changed the default sound extension type (Wliu)");
			DrawPanelText(panel, "6) [Dev] Fixed rage damage not resetting after using FF2_SetBossRageDamage (Wliu from WildCard65)");
		}
		case 58:  //1.10.4
		{
			DrawPanelText(panel, "1) Fixed players getting overheal after winning as a boss (Wliu/FlaminSarge)");
			DrawPanelText(panel, "2) Rebalanced the Baby Face's Blaster (Shadow)");
			DrawPanelText(panel, "3) Fixed the Baby Face's Blaster being unusable when FF2 was disabled (Wliu from Curtgust)");
			DrawPanelText(panel, "4) Fixed the Darwin's Danger Shield getting replaced by the SMG (Wliu)");
			DrawPanelText(panel, "5) Added the Tide Turner and new festive weapons to the weapon whitelist (Wliu)");
			DrawPanelText(panel, "See next page (press 1");
		}
		case 57:  //1.10.4
		{
			DrawPanelText(panel, "6) Fixed Market Gardener backstabs (Wliu)");
			DrawPanelText(panel, "7) Improved class switching after you finish the round as a boss (Wliu)");
			DrawPanelText(panel, "8) Fixed the !ff2 command again (Wliu)");
			DrawPanelText(panel, "9) Fixed bosses not ducking when teleporting (CapnDev)");
			DrawPanelText(panel, "10) Prevented dead companion bosses from becoming clones (Wliu)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 56:  //1.10.4
		{
			DrawPanelText(panel, "11) [Server] Fixed 'ff2_alive' never being shown (Wliu from various)");
			DrawPanelText(panel, "12) [Server] Fixed invalid healthbar errors (Wliu from ClassicGuzzi)");
			DrawPanelText(panel, "13) [Server] Fixed OnTakeDamage errors from spell Monoculuses (Wliu from ClassicGuzzi)");
			DrawPanelText(panel, "14) [Server] Added 'ff2_arena_rounds' and deprecated 'ff2_first_round' (Wliu from Spyper)");
			DrawPanelText(panel, "15) [Server] Added 'ff2_base_jumper_stun' to disable the parachute on stun (Wliu from Shadow)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 55:  //1.10.4
		{
			DrawPanelText(panel, "16) [Server] Prevented FF2 from loading if it gets loaded in the /plugins/freaks/ directory (Wliu)");
			DrawPanelText(panel, "17) [Dev] Fixed 'sound_fail' (Wliu from M76030)");
			DrawPanelText(panel, "18) [Dev] Allowed companions to emit 'sound_nextlife' if they have it (Wliu from M76030)");
			DrawPanelText(panel, "19) [Dev] Added 'sound_last_life' (Wliu from WildCard65)");
			DrawPanelText(panel, "20) [Dev] Added FF2_OnAlivePlayersChanged and deprecated FF2_Get{Alive|Boss}Players (Wliu from Shadow)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 54:  //1.10.4
		{
			DrawPanelText(panel, "21) [Dev] Fixed AIOOB errors in FF2_GetBossUserId (Wliu)");
			DrawPanelText(panel, "22) [Dev] Improved FF2_OnSpecialSelected so that only part of a boss name is needed (Wliu)");
			DrawPanelText(panel, "23) [Dev] Added FF2_{Get|Set}BossRageDamage (Wliu from WildCard65)");
		}
		case 53:  //1.10.3
		{
			DrawPanelText(panel, "1) Fixed bosses appearing to be overhealed (War3Evo/Wliu)");
			DrawPanelText(panel, "2) Rebalanced many weapons based on misc. feedback (Wliu/various)");
			DrawPanelText(panel, "3) Fixed not being able to use strange syringe guns or mediguns (Chris from Spyper)");
			DrawPanelText(panel, "4) Fixed the Bread Bite being replaced by the GRU (Wliu from Spyper)");
			DrawPanelText(panel, "5) Fixed Mantreads not giving extra rocket jump height (Chdata");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 52:  //1.10.3
		{
			DrawPanelText(panel, "6) Prevented bosses from picking up ammo/health by default (friagram)");
			DrawPanelText(panel, "7) Fixed a bug with respawning bosses (Wliu from Spyper)");
			DrawPanelText(panel, "8) Fixed an issue with displaying boss health in chat (Wliu)");
			DrawPanelText(panel, "9) Fixed an edge case where player crits would not be applied (Wliu from Spyper)");
			DrawPanelText(panel, "10) Fixed not being able to suicide as boss after round end (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 51:  //1.10.3
		{
			DrawPanelText(panel, "11) Updated Russian translations (wasder) and added German translations (CooliMC)");
			DrawPanelText(panel, "12) Fixed Dead Ringer deaths being too obvious (Wliu from AliceTaylor12)");
			DrawPanelText(panel, "13) Fixed many bosses not voicing their catch phrases (Wliu)");
			DrawPanelText(panel, "14) Updated Gentlespy, Easter Bunny, Demopan, and CBS (Wliu, configs need to be updated)");
			DrawPanelText(panel, "15) [Server] Added new cvar 'ff2_countdown_result' (Wliu from Shadow)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 50:  //1.10.3
		{
			DrawPanelText(panel, "16) [Server] Added new cvar 'ff2_caber_detonations' (Wliu)");
			DrawPanelText(panel, "17) [Server] Fixed a bug related to 'cvar_countdown_players' and the countdown timer (Wliu from Spyper)");
			DrawPanelText(panel, "18) [Server] Fixed 'nextmap_charset' VFormat errors (Wliu from BBG_Theory)");
			DrawPanelText(panel, "19) [Server] Fixed errors when Monoculus was attacking (Wliu from ClassicGuzzi)");
			DrawPanelText(panel, "20) [Dev] Added 'sound_first_blood' (Wliu from Mr-Bro)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 49:  //1.10.3
		{
			DrawPanelText(panel, "21) [Dev] Added 'pickups' to set what the boss can pick up (Wliu)");
			DrawPanelText(panel, "22) [Dev] Added FF2FLAG_ALLOW_{HEALTH|AMMO}_PICKUPS (Powerlord)");
			DrawPanelText(panel, "23) [Dev] Added FF2_GetFF2Version (Wliu)");
			DrawPanelText(panel, "24) [Dev] Added FF2_ShowSync{Hud}Text wrappers (Wliu)");
			DrawPanelText(panel, "25) [Dev] Added FF2_SetAmmo and fixed setting clip (Wliu/friagram for fixing clip)");
			DrawPanelText(panel, "26) [Dev] Fixed weapons not being hidden when asked to (friagram)");
			DrawPanelText(panel, "27) [Dev] Fixed not being able to set constant health values for bosses (Wliu from braak0405)");
		}
		case 48:  //1.10.2
		{
			DrawPanelText(panel, "1) Fixed a critical bug that rendered most bosses as errors without sound (Wliu; thanks to slavko17 for reporting)");
			DrawPanelText(panel, "2) Reverted escape sequences change, which is what caused this bug");
		}
		case 47:  //1.10.1
		{
			DrawPanelText(panel, "1) Fixed a rare bug where rage could go over 100% (Wliu)");
			DrawPanelText(panel, "2) Updated to use Sourcemod 1.6.1 (Powerlord)");
			DrawPanelText(panel, "3) Fixed goomba stomp ignoring demoshields (Wliu)");
			DrawPanelText(panel, "4) Disabled boss from spectating (Wliu)");
			DrawPanelText(panel, "5) Fixed some possible overlapping HUD text (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 46:  //1.10.1
		{
			DrawPanelText(panel, "6) Fixed ff2_charset displaying incorrect colors (Wliu)");
			DrawPanelText(panel, "7) Boss info text now also displays in the chat area (Wliu)");
			DrawPanelText(panel, "--Partially synced with VSH 1.49 (all VSH changes listed courtesy of Chdata)--");
			DrawPanelText(panel, "8) VSH: Do not show HUD text if the scoreboard is open");
			DrawPanelText(panel, "9) VSH: Added market gardener 'backstab'");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 45:  //1.10.1
		{
			DrawPanelText(panel, "10) VSH: Removed Darwin's Danger Shield from the blacklist (Chdata) and gave it a +50 health bonus (Wliu)");
			DrawPanelText(panel, "11) VSH: Rebalanced Phlogistinator");
			DrawPanelText(panel, "12) VSH: Improved backstab code");
			DrawPanelText(panel, "13) VSH: Added ff2_shield_crits cvar to control whether or not demomen get crits when using shields");
			DrawPanelText(panel, "14) VSH: Reserve Shooter now deals crits to bosses in mid-air");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 44:  //1.10.1
		{
			DrawPanelText(panel, "15) [Server] Fixed conditions still being added when FF2 was disabled (Wliu)");
			DrawPanelText(panel, "16) [Server] Fixed a rare healthbar error (Wliu)");
			DrawPanelText(panel, "17) [Server] Added convar ff2_boss_suicide to control whether or not the boss can suicide after the round starts (Wliu)");
			DrawPanelText(panel, "18) [Server] Changed ff2_boss_teleporter's default value to 0 (Wliu)");
			DrawPanelText(panel, "19) [Server] Updated translations (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 43:  //1.10.1
		{
			DrawPanelText(panel, "20) [Dev] Added FF2_GetAlivePlayers and FF2_GetBossPlayers (Wliu/AliceTaylor)");
			DrawPanelText(panel, "21) [Dev] Fixed a bug in the main include file (Wliu)");
			DrawPanelText(panel, "22) [Dev] Enabled escape sequences in configs (Wliu)");
		}
		case 42:  //1.10.0
		{
			DrawPanelText(panel, "1) Rage is now activated by calling for medic (Wliu)");
			DrawPanelText(panel, "2) Balanced Goomba Stomp and RTD (WildCard65)");
			DrawPanelText(panel, "3) Fixed BGM not stopping if the boss suicides at the beginning of the round (Wliu)");
			DrawPanelText(panel, "4) Fixed Jarate, etc. not disappearing immediately on the boss (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 41:  //1.10.0
		{
			DrawPanelText(panel, "5) Fixed ability timers not resetting when the round was over (Wliu)");
			DrawPanelText(panel, "6) Fixed bosses losing momentum when raging in the air (Wliu)");
			DrawPanelText(panel, "7) Fixed bosses losing health if their companion left at round start (Wliu)");
			DrawPanelText(panel, "8) Fixed bosses sometimes teleporting to each other if they had a companion (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 40:  //1.10.0
		{
			DrawPanelText(panel, "9) Optimized the health calculation system (WildCard65)");
			DrawPanelText(panel, "10) Slightly tweaked default boss health formula to be more balanced (Eggman)");
			DrawPanelText(panel, "11) Fixed and optimized the leaderboard (Wliu)");
			DrawPanelText(panel, "12) Fixed medic minions receiving the medigun (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 39:  //1.10.0
		{
			DrawPanelText(panel, "13) Fixed Ninja Spy slow-mo bugs (Wliu/Powerlord)");
			DrawPanelText(panel, "14) Prevented players from changing to the incorrect team or class (Powerlord/Wliu)");
			DrawPanelText(panel, "15) Fixed bosses immediately dying after using the dead ringer (Wliu)");
			DrawPanelText(panel, "16) Fixed a rare bug where you could get notified about being the next boss multiple times (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 38:  //1.10.0
		{
			DrawPanelText(panel, "17) Fixed gravity not resetting correctly after a weighdown if using non-standard gravity (Wliu)");
			DrawPanelText(panel, "18) [Server] FF2 now properly disables itself when required (Wliu/Powerlord)");
			DrawPanelText(panel, "19) [Server] Added ammo, clip, and health arguments to rage_cloneattack (Wliu)");
			DrawPanelText(panel, "20) [Server] Changed how BossCrits works...again (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 37:  //1.10.0
		{
			DrawPanelText(panel, "21) [Server] Removed convar ff2_halloween (Wliu)");
			DrawPanelText(panel, "22) [Server] Moved convar ff2_oldjump to the main config file (Wliu)");
			DrawPanelText(panel, "23) [Server] Added convar ff2_countdown_players to control when the timer should appear (Wliu/BBG_Theory)");
			DrawPanelText(panel, "24) [Server] Added convar ff2_updater to control whether automatic updating should be turned on (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 36:  //1.10.0
		{
			DrawPanelText(panel, "25) [Server] Added convar ff2_goomba_jump to control how high players should rebound after goomba stomping the boss (WildCard65)");
			DrawPanelText(panel, "26) [Server] Fixed hale_point_enable/disable being registered twice (Wliu)");
			DrawPanelText(panel, "27) [Server] Fixed some convars not executing (Wliu)");
			DrawPanelText(panel, "28) [Server] Fixed the chances and charset systems (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 35:  //1.10.0
		{
			DrawPanelText(panel, "29) [Dev] Added more natives and one additional forward (Eggman)");
			DrawPanelText(panel, "30) [Dev] Added sound_full_rage which plays once the boss is able to rage (Wliu/Eggman)");
			DrawPanelText(panel, "31) [Dev] Fixed FF2FLAG_ISBUFFED (Wliu)");
			DrawPanelText(panel, "32) [Dev] FF2 now checks for sane values for \"lives\" and \"health_formula\" (Wliu)");
			DrawPanelText(panel, "Big thanks to GIANT_CRAB, WildCard65, and kniL for their devotion to this release!");
		}
		case 34:  //1.9.3
		{
			DrawPanelText(panel, "1) Fixed a bug in 1.9.2 where the changelog was off by one version (Wliu)");
			DrawPanelText(panel, "2) Fixed a bug in 1.9.2 where one dead player would not be cloned in rage_cloneattack (Wliu)");
			DrawPanelText(panel, "3) Fixed a bug in 1.9.2 where sentries would be permanently disabled after a rage (Wliu)");
			DrawPanelText(panel, "4) [Server] Removed ff2_halloween (Wliu)");
		}
		case 33:  //1.9.2
		{
			DrawPanelText(panel, "1) Fixed a bug in 1.9.1 that allowed the same player to be the boss over and over again (Wliu)");
			DrawPanelText(panel, "2) Fixed a bug where last player glow was being incorrectly removed on the boss (Wliu)");
			DrawPanelText(panel, "3) Fixed a bug where the boss would be assumed dead (Wliu)");
			DrawPanelText(panel, "4) Fixed having minions on the boss team interfering with certain rage calculations (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 32:  //1.9.2
		{
			DrawPanelText(panel, "5) Fixed a rare bug where the rage percentage could go above 100% (Wliu)");
			DrawPanelText(panel, "6) [Server] Fixed possible special_noanims errors (Wliu)");
			DrawPanelText(panel, "7) [Server] Added int arguments to rage_cloneattack-no updates necessary (friagram/Wliu)");
			DrawPanelText(panel, "8) [Server] Certain cvars that SMAC detects are now automatically disabled while FF2 is running (Wliu)");
			DrawPanelText(panel, "            Servers can now safely have smac_cvars enabled");
		}
		case 31:  //1.9.1
		{
			DrawPanelText(panel, "1) Fixed some minor leaderboard bugs and also improved the leaderboard text (Wliu)");
			DrawPanelText(panel, "2) Fixed a minor round end bug (Wliu)");
			DrawPanelText(panel, "3) [Server] Fixed improper unloading of subplugins (WildCard65)");
			DrawPanelText(panel, "4) [Server] Removed leftover console messages (Wliu)");
			DrawPanelText(panel, "5) [Server] Fixed sound not precached warnings (Wliu)");
		}
		case 30:  //1.9.0
		{
			DrawPanelText(panel, "1) Removed checkFirstHale (Wliu)");
			DrawPanelText(panel, "2) [Server] Fixed invalid healthbar entity bug (Wliu)");
			DrawPanelText(panel, "3) Changed default medic ubercharge percentage to 40% (Wliu)");
			DrawPanelText(panel, "4) Whitelisted festive variants of weapons (Wliu/BBG_Theory)");
			DrawPanelText(panel, "5) [Server] Added convars to control last player glow and timer health cutoff (Wliu");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 29:  //1.9.0
		{
			DrawPanelText(panel, "6) [Dev] Added int natives/stocks: Debug, FF2_SetClientGlow and FF2_GetClientGlow (Wliu)");
			DrawPanelText(panel, "7) Fixed a few minor !whatsnew bugs (BBG_Theory)");
			DrawPanelText(panel, "8) Fixed Easter Abilities (Wliu)");
			DrawPanelText(panel, "9) Minor grammar/spelling improvements (Wliu)");
			DrawPanelText(panel, "10) [Server] Minor subplugin load/unload fixes (Wliu)");
		}
		case 28:  //1.0.8
		{
			DrawPanelText(panel, "Wliu, Chris, Lawd, and Carge of 50DKP have taken over FF2 development");
			DrawPanelText(panel, "1) Prevented spy bosses from changing disguises (Powerlord)");
			DrawPanelText(panel, "2) Added Saxton Hale stab sounds (Powerlord/AeroAcrobat)");
			DrawPanelText(panel, "3) Made sure that the boss doesn't have any invalid weapons/items (Powerlord)");
			DrawPanelText(panel, "4) Tried fixing the visible weapon bug (Powerlord)");
			DrawPanelText(panel, "5) Whitelisted some more action slot items (Powerlord)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 27:  //1.0.8
		{
			DrawPanelText(panel, "6) Festive Huntsman has the same attributes as the Huntsman now (Powerlord)");
			DrawPanelText(panel, "7) Medigun now overheals 50% more (Powerlord)");
			DrawPanelText(panel, "8) Made medigun transparent if the medic's melee was the Gunslinger (Powerlord)");
			DrawPanelText(panel, "9) Slight tweaks to the view hp commands (Powerlord)");
			DrawPanelText(panel, "10) Whitelisted the Silver/Gold Botkiller Sniper Rifle Mk.II (Powerlord)");
			DrawPanelText(panel, "11) Slight tweaks to boss health calculation (Powerlord)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 26:  //1.0.8
		{
			DrawPanelText(panel, "12) Made sure that spies couldn't quick-backstab the boss (Powerlord)");
			DrawPanelText(panel, "13) Made sure the stab animations were correct (Powerlord)");
			DrawPanelText(panel, "14) Made sure that healthpacks spawned from the Candy Cane are not respawned once someone uses them (Powerlord)");
			DrawPanelText(panel, "15) Healthpacks from the Candy Cane are no longer despawned (Powerlord)");
			DrawPanelText(panel, "16) Slight tweaks to removing laughs (Powerlord)");
			DrawPanelText(panel, "17) [Dev] Added a clip argument to special_noanims.sp (Powerlord)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 25:  //1.0.8
		{
			DrawPanelText(panel, "18) [Dev] sound_bgm is now precached automagically (Powerlord)");
			DrawPanelText(panel, "19) Seeldier's minions can no longer cap (Wliu)");
			DrawPanelText(panel, "20) Fixed sometimes getting stuck when teleporting to a ducking player (Powerlord)");
			DrawPanelText(panel, "21) Multiple English translation improvements (Wliu/Powerlord)");
			DrawPanelText(panel, "22) Fixed Ninja Spy and other bosses that use the matrix ability getting stuck in walls/ceilings (Chris)");
			DrawPanelText(panel, "23) [Dev] Updated item attributes code per the TF2Items update (Powerlord)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 24:  //1.0.8
		{
			DrawPanelText(panel, "24) Fixed duplicate sound downloads for Saxton Hale (Wliu)");
			DrawPanelText(panel, "25) [Server] FF2 now require morecolors, not colors (Powerlord)");
			DrawPanelText(panel, "26) [Server] Added a Halloween mode which will enable characters_halloween.cfg (Wliu)");
			DrawPanelText(panel, "27) Hopefully fixed multiple round-related issues (Wliu)");
			DrawPanelText(panel, "28) [Dev] Started to clean up/format the code (Wliu)");
			DrawPanelText(panel, "29) Changed versioning format to x.y.z and month day, year (Wliu)");
			DrawPanelText(panel, "HAPPY HALLOWEEN!");
		}
		case 23:  //1.07
		{
			DrawPanelText(panel, "1) [Players] Holiday Punch is now replaced by Fists");
			DrawPanelText(panel, "2) [Players] Bosses will have any disguises removed on round start");
			DrawPanelText(panel, "3) [Players] Bosses can no longer see all players health, as it wasn't working any more");
			DrawPanelText(panel, "4) [Server] ff2_addpoints no longer targets SourceTV or replay");
		}
		case 22:  //1.07 beta 6
		{
			DrawPanelText(panel, "1) [Dev] Fixed issue with sound hook not stopping sound when sound_block_vo was in use");
			DrawPanelText(panel, "2) [Dev] If ff2_charset was used, don't run the character set vote");
			DrawPanelText(panel, "3) [Dev] If a vote is already running, Character set vote will retry every 5 seconds or until map changes ");
		}
		case 21:  //1.07 beta 5
		{
			DrawPanelText(panel, "1) [Dev] Fixed issue with character sets not working.");
			DrawPanelText(panel, "2) [Dev] Improved IsValidClient replay check");
			DrawPanelText(panel, "3) [Dev] IsValidClient is now called when loading companion bosses");
			DrawPanelText(panel, "   This should prevent GetEntProp issues with m_iClass");
		}
		case 20:  //1.07 beta 4
		{
			DrawPanelText(panel, "1) [Players] Dead Ringers have no cloak defense buff. Normal cloaks do.");
			DrawPanelText(panel, "2) [Players] Fixed Sniper Rifle reskin behavior");
			DrawPanelText(panel, "3) [Players] Boss has small amount of stun resistance after rage");
			DrawPanelText(panel, "4) [Players] Various bugfixes and changes 1.7.0 beta 1");
		}
		case 19:  //1.07 beta
		{
			DrawPanelText(panel, "22) [Dev] Prevent boss rage from being activated if the boss is already taunting or is dead.");
			DrawPanelText(panel, "23) [Dev] Cache the result of the newer backstab detection");
			DrawPanelText(panel, "24) [Dev] Reworked Medic damage code slightly");
		}
		case 18:  //1.07 beta
		{
			DrawPanelText(panel, "16) [Server] The Boss queue now accepts negative points.");
			DrawPanelText(panel, "17) [Server] Bosses can be forced to a specific team using the int ff2_force_team cvar.");
			DrawPanelText(panel, "18) [Server] Eureka Effect can now be enabled using the int ff2_enable_eureka cvar");
			DrawPanelText(panel, "19) [Server] Bosses models and sounds are now precached the first time they are loaded.");
			DrawPanelText(panel, "20) [Dev] Fixed an issue where FF2 was trying to read cvars before config files were executed.");
			DrawPanelText(panel, "    This change should also make the game a little more multi-mod friendly.");
			DrawPanelText(panel, "21) [Dev] Fixed OnLoadCharacterSet not being fired. This should fix the deadrun plugin.");
			DrawPanelText(panel, "Continued on next page");
		}
		case 17:  //1.07 beta
		{
			DrawPanelText(panel, "10) [Players] Heatmaker gains Focus on hit (varies by charge)");
			DrawPanelText(panel, "11) [Players] Crusader's Crossbow damage has been adjusted to compensate for its speed increase.");
			DrawPanelText(panel, "12) [Players] Cozy Camper now gives you an SMG as well, but it has no crits and reduced damage.");
			DrawPanelText(panel, "13) [Players] Bosses get short defense buff after rage");
			DrawPanelText(panel, "14) [Server] Now attempts to integrate tf2items config");
			DrawPanelText(panel, "15) [Server] Changing the game description now requires Steam Tools");
			DrawPanelText(panel, "Continued on next page");
		}
		case 16:  //1.07 beta
		{
			DrawPanelText(panel, "6) [Players] Removed crits from sniper rifles, now do 2.9x damage");
			DrawPanelText(panel, "   Sydney Sleeper does 2.4x damage, 2.9x if boss's rage is >90pct");
			DrawPanelText(panel, "   Minicrit- less damage, more knockback");
			DrawPanelText(panel, "7) [Players] Baby Face's Blaster will fill boost normally, but will hit 100 and drain+minicrits.");
			DrawPanelText(panel, "8) [Players] Phlogistinator Pyros are invincible while activating the crit-boost taunt.");
			DrawPanelText(panel, "9) [Players] Can't Eureka+destroy dispenser to insta-teleport");
			DrawPanelText(panel, "Continued on next page");
		}
		case 15:  //1.07 beta
		{
			DrawPanelText(panel, "1) [Players] Reworked the crit code a bit. Should be more reliable.");
			DrawPanelText(panel, "2) [Players] Help panel should stop repeatedly popping up on round start.");
			DrawPanelText(panel, "3) [Players] Backstab disguising should be smoother/less obvious");
			DrawPanelText(panel, "4) [Players] Scaled sniper rifle glow time a bit better");
			DrawPanelText(panel, "5) [Players] Fixed Dead Ringer spy death icon");
			DrawPanelText(panel, "Continued on next page");
		}
		case 14:  //1.06h
		{
			DrawPanelText(panel, "1) [Players] Remove MvM powerup_bottle on Bosses. (RavensBro)");
		}
		case 13:  //1.06g
		{
			DrawPanelText(panel, "1) [Players] Fixed vote for charset. (RavensBro)");
		}
		case 12:  //1.06f
		{
			DrawPanelText(panel, "1) [Players] Changelog now divided into [Players] and [Dev] sections. (Otokiru)");
			DrawPanelText(panel, "2) [Players] Don't bother reading [Dev] changelogs because you'll have no idea what it's stated. (Otokiru)");
			DrawPanelText(panel, "3) [Players] Fixed civilian glitch. (Otokiru)");
			DrawPanelText(panel, "4) [Players] Fixed hale HP bar. (Valve) lol?");
			DrawPanelText(panel, "5) [Dev] Fixed \"GetEntProp\" reported: Entity XXX (XXX) is invalid on checkFirstHale(). (Otokiru)");
		}
		case 11:  //1.06e
		{

			DrawPanelText(panel, "1) [Players] Remove MvM water-bottle on hales. (Otokiru)");
			DrawPanelText(panel, "2) [Dev] Fixed \"GetEntProp\" reported: Property \"m_iClass\" not found (entity 0/worldspawn) error on checkFirstHale(). (Otokiru)");
			DrawPanelText(panel, "3) [Dev] Change how FF2 check for player weapons. Now also checks when spawned in the middle of the round. (Otokiru)");
			DrawPanelText(panel, "4) [Dev] Changed some FF2 warning messages color such as \"First-Hale Checker\" and \"Change class exploit\". (Otokiru)");
		}
		case 10:  //1.06d
		{
			DrawPanelText(panel, "1) Fix first boss having missing health or abilities. (Otokiru)");
			DrawPanelText(panel, "2) Health bar now goes away if the boss wins the round. (Powerlord)");
			DrawPanelText(panel, "3) Health bar cedes control to Monoculus if he is summoned. (Powerlord)");
			DrawPanelText(panel, "4) Health bar instantly updates if enabled or disabled via cvar mid-game. (Powerlord)");
		}
		case 9:  //1.06c
		{
			DrawPanelText(panel, "1) Remove weapons if a player tries to switch classes when they become boss to prevent an exploit. (Otokiru)");
			DrawPanelText(panel, "2) Reset hale's queue points to prevent the 'retry' exploit. (Otokiru)");
			DrawPanelText(panel, "3) Better detection of backstabs. (Powerlord)");
			DrawPanelText(panel, "4) Boss now has optional life meter on screen. (Powerlord)");
		}
		case 8:  //1.06
		{
			DrawPanelText(panel, "1) Fixed attributes key for weaponN block. Now 1 space needed for explode string.");
			DrawPanelText(panel, "2) Disabled vote for charset when there is only 1 not hidden chatset.");
			DrawPanelText(panel, "3) Fixed \"Invalid key value handle 0 (error 4)\" when when round starts.");
			DrawPanelText(panel, "4) Fixed ammo for special_noanims.ff2\\rage_new_weapon ability.");
			DrawPanelText(panel, "Coming soon: weapon balance will be moved into config file.");
		}
		case 7:  //1.05
		{
			DrawPanelText(panel, "1) Added \"hidden\" key for charsets.");
			DrawPanelText(panel, "2) Added \"sound_stabbed\" key for characters.");
			DrawPanelText(panel, "3) Mantread stomp deals 5x damage to Boss.");
			DrawPanelText(panel, "4) Minicrits will not play loud sound to all players");
			DrawPanelText(panel, "5-11) See next page...");
		}
		case 6:  //1.05
		{
			DrawPanelText(panel, "6) For mappers: Add info_target with name 'hale_no_music'");
			DrawPanelText(panel, "    to prevent Boss' music.");
			DrawPanelText(panel, "7) FF2 renames *.smx from plugins/freaks/ to *.ff2 by itself.");
			DrawPanelText(panel, "8) Third Degree hit adds uber to healers.");
			DrawPanelText(panel, "9) Fixed hard \"ghost_appearation\" in default_abilities.ff2.");
			DrawPanelText(panel, "10) FF2FLAG_HUDDISABLED flag blocks EVERYTHING of FF2's HUD.");
			DrawPanelText(panel, "11) Changed FF2_PreAbility native to fix bug about broken Boss' abilities.");
		}
		case 5:  //1.04
		{
			DrawPanelText(panel, "1) Seeldier's minions have protection (teleport) from pits for first 4 seconds after spawn.");
			DrawPanelText(panel, "2) Seeldier's minions correctly dies when owner-Seeldier dies.");
			DrawPanelText(panel, "3) Added multiplier for brave jump ability in char.configs (arg3, default is 1.0).");
			DrawPanelText(panel, "4) Added config key sound_fail. It calls when Boss fails, but still alive");
			DrawPanelText(panel, "4) Fixed potential exploits associated with feign death.");
			DrawPanelText(panel, "6) Added ff2_reload_subplugins command to reload FF2's subplugins.");
		}
		case 4:  //1.03
		{
			DrawPanelText(panel, "1) Finally fixed exploit about queue points.");
			DrawPanelText(panel, "2) Fixed non-regular bug with 'UTIL_SetModel: not precached'.");
			DrawPanelText(panel, "3) Fixed potential bug about reducing of Boss' health by healing.");
			DrawPanelText(panel, "4) Fixed Boss' stun when round begins.");
		}
		case 3:  //1.02
		{
			DrawPanelText(panel, "1) Added isNumOfSpecial parameter into FF2_GetSpecialKV and FF2_GetBossSpecial natives");
			DrawPanelText(panel, "2) Added FF2_PreAbility forward. Plz use it to prevent FF2_OnAbility only.");
			DrawPanelText(panel, "3) Added FF2_DoAbility native.");
			DrawPanelText(panel, "4) Fixed exploit about queue points...ow wait, it done in 1.01");
			DrawPanelText(panel, "5) ff2_1st_set_abilities.ff2 sets kac_enabled to 0.");
			DrawPanelText(panel, "6) FF2FLAG_HUDDISABLED flag disables Boss' HUD too.");
			DrawPanelText(panel, "7) Added FF2_GetQueuePoints and FF2_SetQueuePoints natives.");
		}
		case 2:  //1.01
		{
			DrawPanelText(panel, "1) Fixed \"classmix\" bug associated with Boss' class restoring.");
			DrawPanelText(panel, "3) Fixed other little bugs.");
			DrawPanelText(panel, "4) Fixed bug about instant kill of Seeldier's minions.");
			DrawPanelText(panel, "5) Now you can use name of Boss' file for \"companion\" Boss' keyvalue.");
			DrawPanelText(panel, "6) Fixed exploit when dead Boss can been respawned after his reconnect.");
			DrawPanelText(panel, "7-10) See next page...");
		}
		case 1:  //1.01
		{
			DrawPanelText(panel, "7) I've missed 2nd item.");
			DrawPanelText(panel, "8) Fixed \"Random\" charpack, there is no vote if only one charpack.");
			DrawPanelText(panel, "9) Fixed bug when boss' music have a chance to DON'T play.");
			DrawPanelText(panel, "10) Fixed bug associated with ff2_enabled in cfg/sourcemod/FreakFortress2.cfg and disabling of pugin.");
		}
		case 0:  //1.0
		{
			DrawPanelText(panel, "1) Boss' health devided by 3,6 in medieval mode");
			DrawPanelText(panel, "2) Restoring player's default class, after his round as Boss");
			DrawPanelText(panel, "===UPDATES OF VS SAXTON HALE MODE===");
			DrawPanelText(panel, "1) Added !ff2_resetqueuepoints command (also there is admin version)");
			DrawPanelText(panel, "2) Medic is credited 100% of damage done during ubercharge");
			DrawPanelText(panel, "3) If map changes mid-round, queue points not lost");
			DrawPanelText(panel, "4) Dead Ringer will not be able to activate for 2s after backstab");
			DrawPanelText(panel, "5) Added ff2_spec_force_boss cvar");
		}
		default:
		{
			DrawPanelText(panel, "-- Somehow you've managed to find a glitched version page!");
			DrawPanelText(panel, "-- Congratulations.  Now go and fight!");
		}
	}
}

static const int maxVersion=sizeof(ff2versiontitles)-1;
//
int Specials;
Handle BossKV[MAXSPECIALS];
Handle PreAbility;
Handle OnAbility;
Handle OnMusic;
Handle OnTriggerHurt;
Handle OnSpecialSelected;
Handle OnAddQueuePoints;
Handle OnLoadCharacterSet;
Handle OnLoseLife;
Handle OnAlivePlayersChanged;
Handle OnAbilityTime;
Handle OnAbilityTimeEnd;
Handle OnPlayBoss;
Handle OnTakePercentDamage;
Handle OnTakePercentDamagePost;

bool bBlockVoice[MAXSPECIALS];
float BossSpeed[MAXSPECIALS];
//float BossRageDamage[MAXSPECIALS];

char ChancesString[512];
int chances[MAXSPECIALS*2];  //This is multiplied by two because it has to hold both the boss indices and chances
int chancesIndex;

public Plugin myinfo=
{
	name="Freak Fortress 2",
	author="Rainbolt Dash, FlaminSarge, Powerlord, the 50DKP team ()",
	description="RUUUUNN!! COWAAAARRDSS!",
	version=PLUGIN_VERSION,
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:plugin[PLATFORM_MAX_PATH];
	GetPluginFilename(myself, plugin, sizeof(plugin));
	if(!StrContains(plugin, "freaks/"))  //Prevent plugins/freaks/freak_fortress_2.ff2 from loading if it exists -.-
	{
		strcopy(error, err_max, "There is a duplicate copy of Freak Fortress 2 inside the /plugins/freaks folder.  Please remove it");
		return APLRes_Failure;
	}

	CreateNative("FF2_IsFF2Enabled", Native_IsEnabled);
	CreateNative("FF2_GetFF2Version", Native_FF2Version);
	CreateNative("FF2_GetBossUserId", Native_GetBoss);
	CreateNative("FF2_GetBossIndex", Native_GetIndex);
	CreateNative("FF2_GetBossTeam", Native_GetTeam);
	CreateNative("FF2_GetBossSpecial", Native_GetSpecial);
	CreateNative("FF2_GetBossHealth", Native_GetBossHealth);
	CreateNative("FF2_SetBossHealth", Native_SetBossHealth);
	CreateNative("FF2_GetBossMaxHealth", Native_GetBossMaxHealth);
	CreateNative("FF2_SetBossMaxHealth", Native_SetBossMaxHealth);
	CreateNative("FF2_GetBossLives", Native_GetBossLives);
	CreateNative("FF2_SetBossLives", Native_SetBossLives);
	CreateNative("FF2_GetBossMaxLives", Native_GetBossMaxLives);
	CreateNative("FF2_SetBossMaxLives", Native_SetBossMaxLives);
	CreateNative("FF2_GetBossCharge", Native_GetBossCharge);
	CreateNative("FF2_SetBossCharge", Native_SetBossCharge);
	CreateNative("FF2_GetBossRageDamage", Native_GetBossRageDamage);
	CreateNative("FF2_SetBossRageDamage", Native_SetBossRageDamage);
	CreateNative("FF2_GetClientDamage", Native_GetDamage);
	CreateNative("FF2_SetClientDamage", Native_SetDamage);
	CreateNative("FF2_GetRoundState", Native_GetRoundState);
	CreateNative("FF2_GetSpecialKV", Native_GetSpecialKV);
	CreateNative("FF2_LoadMusicData", Native_LoadMusicData);
	CreateNative("FF2_StartMusic", Native_StartMusic);
	CreateNative("FF2_StopMusic", Native_StopMusic);
	CreateNative("FF2_GetRageDist", Native_GetRageDist);
	CreateNative("FF2_HasAbility", Native_HasAbility);
	CreateNative("FF2_DoAbility", Native_DoAbility);
	CreateNative("FF2_GetAbilityArgument", Native_GetAbilityArgument);
	CreateNative("FF2_GetAbilityArgumentFloat", Native_GetAbilityArgumentFloat);
	CreateNative("FF2_GetAbilityArgumentString", Native_GetAbilityArgumentString);
	CreateNative("FF2_RandomSound", Native_RandomSound);
	CreateNative("FF2_GetFF2flags", Native_GetFF2flags);
	CreateNative("FF2_SetFF2flags", Native_SetFF2flags);
	CreateNative("FF2_GetQueuePoints", Native_GetQueuePoints);
	CreateNative("FF2_SetQueuePoints", Native_SetQueuePoints);
	CreateNative("FF2_GetClientGlow", Native_GetClientGlow);
	CreateNative("FF2_SetClientGlow", Native_SetClientGlow);
	CreateNative("FF2_GetAlivePlayers", Native_GetAlivePlayers);  //TODO: Deprecated, remove in 2.0.0
	CreateNative("FF2_GetBossPlayers", Native_GetBossPlayers);  //TODO: Deprecated, remove in 2.0.0
	CreateNative("FF2_Debug", Native_Debug);
	CreateNative("FF2_GetServerFlags", Native_GetServerFlags);
	CreateNative("FF2_SetServerFlags", Native_SetServerFlags);
	CreateNative("FF2_GetFF2Userflags", Native_GetFF2Userflags);
	CreateNative("FF2_SetFF2Userflags", Native_SetFF2Userflags);
	CreateNative("FF2_GetAbilityDuration", Native_GetAbilityDuration);
	CreateNative("FF2_SetAbilityDuration", Native_SetAbilityDuration);
	CreateNative("FF2_GetAbilityCooldown", Native_GetAbilityCooldown);
	CreateNative("FF2_SetAbilityCooldown", Native_SetAbilityCooldown);
	CreateNative("FF2_GetBossMaxRageCharge", Native_GetBossMaxRageCharge);
	CreateNative("FF2_SetBossMaxRageCharge", Native_SetBossMaxRageCharge);
	CreateNative("FF2_MakeClientToBoss", Native_MakeClientToBoss);

	CreateNative("FF2Boss.ClientIndex.get", Native_FF2Boss_ClientIndex_Get);
	CreateNative("FF2Boss.CharacterIndex.get", Native_FF2Boss_CharacterIndex_Get);
	CreateNative("FF2Boss.CharacterIndex.set", Native_FF2Boss_CharacterIndex_Set);
	CreateNative("FF2Boss.HealthPoint.get", Native_FF2Boss_HealthPoint_Get);
	CreateNative("FF2Boss.HealthPoint.set", Native_FF2Boss_HealthPoint_Set);
	CreateNative("FF2Boss.MaxHealthPoint.get", Native_FF2Boss_MaxHealthPoint_Get);
	CreateNative("FF2Boss.MaxHealthPoint.set", Native_FF2Boss_MaxHealthPoint_Set);
	CreateNative("FF2Boss.Lives.get", Native_FF2Boss_Lives_Get);
	CreateNative("FF2Boss.Lives.set", Native_FF2Boss_Lives_Set);
	CreateNative("FF2Boss.MaxLives.get", Native_FF2Boss_MaxLives_Get);
	CreateNative("FF2Boss.MaxLives.set", Native_FF2Boss_MaxLives_Set);
	CreateNative("FF2Boss.RageDamage.get", Native_FF2Boss_RageDamage_Get);
	CreateNative("FF2Boss.RageDamage.set", Native_FF2Boss_RageDamage_Set);
	CreateNative("FF2Boss.MaxRageCharge.get", Native_FF2Boss_MaxRageCharge_Get);
	CreateNative("FF2Boss.MaxRageCharge.set", Native_FF2Boss_MaxRageCharge_Set);
	CreateNative("FF2Boss.KeyValue.get", Native_FF2Boss_KeyValue_Get);
	CreateNative("FF2Boss.KeyValue.set", Native_FF2Boss_KeyValue_Set);
	CreateNative("FF2Boss.Difficulty.get", Native_FF2Boss_Difficulty_Get);
	CreateNative("FF2Boss.Difficulty.set", Native_FF2Boss_Difficulty_Set);
	CreateNative("FF2Boss.GetCharge", Native_FF2Boss_GetCharge);
	CreateNative("FF2Boss.SetCharge", Native_FF2Boss_SetCharge);
	CreateNative("FF2Boss.GetAbilityDuration", Native_FF2Boss_GetAbilityDuration);
	CreateNative("FF2Boss.SetAbilityDuration", Native_FF2Boss_SetAbilityDuration);
	CreateNative("FF2Boss.GetMaxAbilityDuration", Native_FF2Boss_GetMaxAbilityDuration);
	CreateNative("FF2Boss.SetMaxAbilityDuration", Native_FF2Boss_SetMaxAbilityDuration);
	CreateNative("FF2Boss.GetAbilityCooldown", Native_FF2Boss_GetAbilityCooldown);
	CreateNative("FF2Boss.SetAbilityCooldown", Native_FF2Boss_SetAbilityCooldown);
	CreateNative("FF2Boss.GetMaxAbilityCooldown", Native_FF2Boss_GetMaxAbilityCooldown);
	CreateNative("FF2Boss.SetMaxAbilityCooldown", Native_FF2Boss_SetMaxAbilityCooldown);


	PreAbility=CreateGlobalForward("FF2_PreAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_CellByRef);  //Boss, plugin name, ability name, slot, enabled
	OnAbility=CreateGlobalForward("FF2_OnAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell);  //Boss, plugin name, ability name, status
	OnMusic=CreateGlobalForward("FF2_OnMusic", ET_Hook, Param_String, Param_FloatByRef, Param_FloatByRef, Param_String, Param_String, Param_Cell, Param_Cell, Param_Cell);
	OnTriggerHurt=CreateGlobalForward("FF2_OnTriggerHurt", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	OnSpecialSelected=CreateGlobalForward("FF2_OnSpecialSelected", ET_Hook, Param_Cell, Param_CellByRef, Param_String, Param_Cell);  //Boss, character index, character name, preset
	OnAddQueuePoints=CreateGlobalForward("FF2_OnAddQueuePoints", ET_Hook, Param_Array);
	OnLoadCharacterSet=CreateGlobalForward("FF2_OnLoadCharacterSet", ET_Hook, Param_CellByRef, Param_String);
	OnLoseLife=CreateGlobalForward("FF2_OnLoseLife", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);  //Boss, lives left, max lives
	OnAlivePlayersChanged=CreateGlobalForward("FF2_OnAlivePlayersChanged", ET_Hook, Param_Cell, Param_Cell);  //Players, bosses
	OnAbilityTime=CreateGlobalForward("FF2_OnBossAbilityTime", ET_Hook, Param_Cell, Param_String, Param_Cell, Param_FloatByRef, Param_FloatByRef);
	OnAbilityTimeEnd=CreateGlobalForward("FF2_OnAbilityTimeEnd", ET_Hook, Param_Cell, Param_Cell);
	OnPlayBoss=CreateGlobalForward("FF2_OnPlayBoss", ET_Hook, Param_Cell, Param_Cell); // client, bossindex
	OnTakePercentDamage=CreateGlobalForward("FF2_OnTakePercentDamage", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell, Param_FloatByRef); // victim, attacker, damagetype, damage
	OnTakePercentDamagePost=CreateGlobalForward("FF2_OnTakePercentDamage_Post", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_Cell); // victim, attacker, damagetype, damage

	RegPluginLibrary("freak_fortress_2");

	AskPluginLoad_VSH();
	#if defined _steamtools_included
	MarkNativeAsOptional("Steam_SetGameDescription");
	#endif

	#if defined _tf2attributes_included
	MarkNativeAsOptional("TF2Attrib_SetByDefIndex");
	MarkNativeAsOptional("TF2Attrib_RemoveByDefIndex");
	#endif
	return APLRes_Success;
}

public OnPluginStart()
{
	LogMessage("===Freak Fortress 2 Initializing-v%s===", PLUGIN_VERSION);

	cvarVersion=CreateConVar("ff2_version", PLUGIN_VERSION, "Freak Fortress 2 Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarPointType=CreateConVar("ff2_point_type", "0", "0-Use ff2_point_alive, 1-Use ff2_point_time", _, true, 0.0, true, 1.0);
	cvarPointDelay=CreateConVar("ff2_point_delay", "6", "Seconds to add to the point delay per player");
	cvarAliveToEnable=CreateConVar("ff2_point_alive", "5", "The control point will only activate when there are this many people or less left alive");
	cvarAnnounce=CreateConVar("ff2_announce", "120", "Amount of seconds to wait until FF2 info is displayed again.  0 to disable", _, true, 0.0);
	cvarEnabled=CreateConVar("ff2_enabled", "1", "0-Disable FF2 (WHY?), 1-Enable FF2", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	cvarCrits=CreateConVar("ff2_crits", "0", "Can the boss get random crits?", _, true, 0.0, true, 1.0);
	cvarFirstRound=CreateConVar("ff2_first_round", "-1", "This cvar is deprecated.  Please use 'ff2_arena_rounds' instead by setting this cvar to -1", _, true, -1.0, true, 1.0);  //DEPRECATED
	cvarArenaRounds=CreateConVar("ff2_arena_rounds", "1", "Number of rounds to make arena before switching to FF2 (helps for slow-loading players)", _, true, 0.0);
	cvarCircuitStun=CreateConVar("ff2_circuit_stun", "2", "Amount of seconds the Short Circuit stuns the boss for.  0 to disable", _, true, 0.0);
	cvarCountdownPlayers=CreateConVar("ff2_countdown_players", "1", "Amount of players until the countdown timer starts (0 to disable)", _, true, 0.0);
	cvarCountdownTime=CreateConVar("ff2_countdown", "120", "Amount of seconds until the round ends in a stalemate");
	cvarCountdownHealth=CreateConVar("ff2_countdown_health", "2000", "Amount of health the Boss has remaining until the countdown stops", _, true, 0.0);
	cvarCountdownResult=CreateConVar("ff2_countdown_result", "0", "0-Kill players when the countdown ends, 1-End the round in a stalemate", _, true, 0.0, true, 1.0);
	cvarSpecForceBoss=CreateConVar("ff2_spec_force_boss", "0", "0-Spectators are excluded from the queue system, 1-Spectators are counted in the queue system", _, true, 0.0, true, 1.0);
	cvarEnableEurekaEffect=CreateConVar("ff2_enable_eureka", "0", "0-Disable the Eureka Effect, 1-Enable the Eureka Effect", _, true, 0.0, true, 1.0);
	cvarForceBossTeam=CreateConVar("ff2_force_team", "0", "0-Boss is always on Blu, 1-Boss is on a random team each round, 2-Boss is always on Red", _, true, 0.0, true, 3.0);
	cvarHealthBar=CreateConVar("ff2_health_bar", "0", "0-Disable the health bar, 1-Show the health bar", _, true, 0.0, true, 1.0);
	cvarLastPlayerGlow=CreateConVar("ff2_last_player_glow", "1", "0-Don't outline the last player, 1-Outline the last player alive", _, true, 0.0, true, 1.0);
	cvarBossTeleporter=CreateConVar("ff2_boss_teleporter", "0", "-1 to disallow all bosses from using teleporters, 0 to use TF2 logic, 1 to allow all bosses", _, true, -1.0, true, 1.0);
	cvarBossSuicide=CreateConVar("ff2_boss_suicide", "0", "Allow the boss to suicide after the round starts?", _, true, 0.0, true, 1.0);
	cvarPreroundBossDisconnect=CreateConVar("ff2_replace_disconnected_boss", "1", "If a boss disconnects before the round starts, use the next player in line instead? 0 - No, 1 - Yes", _, true, 0.0, true, 1.0);
	cvarCaberDetonations=CreateConVar("ff2_caber_detonations", "5", "Amount of times somebody can detonate the Ullapool Caber");
	cvarShieldCrits=CreateConVar("ff2_shield_crits", "0", "0 to disable grenade launcher crits when equipping a shield, 1 for minicrits, 2 for crits", _, true, 0.0, true, 2.0);
	cvarGoombaDamage=CreateConVar("ff2_goomba_damage", "0.05", "How much the Goomba damage should be multipled by when goomba stomping the boss (requires Goomba Stomp)", _, true, 0.01, true, 1.0);
	cvarGoombaRebound=CreateConVar("ff2_goomba_jump", "300.0", "How high players should rebound after goomba stomping the boss (requires Goomba Stomp)", _, true, 0.0);
	cvarBossRTD=CreateConVar("ff2_boss_rtd", "0", "Can the boss use rtd? 0 to disallow boss, 1 to allow boss (requires RTD)", _, true, 0.0, true, 1.0);
	cvarDebug=CreateConVar("ff2_debug", "0", "0-Disable FF2 debug output, 1-Enable debugging (not recommended)", _, true, 0.0, true, 1.0);
//	cvarStunTime=CreateConVar("ff2_stun_time", "야구공 스턴 시간", "7.0", _, true, 0.0);
// 	cvarStunRange=CreateConVar("ff2_stun_range", "야구공 최대 스턴을 위한 체공 시간", "2.0", _, true, 0.0);

	//The following are used in various subplugins
	CreateConVar("ff2_oldjump", "0", "Use old Saxton Hale jump equations", _, true, 0.0, true, 1.0);
	CreateConVar("ff2_base_jumper_stun", "0", "Whether or not the Base Jumper should be disabled when a player gets stunned", _, true, 0.0, true, 1.0);

	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("teamplay_broadcast_audio", OnBroadcast, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("post_inventory_application", OnPostInventoryApplication, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre); //  첫라운드 버그가 문제야..
	HookEvent("rps_taunt_event", OnRPS, EventHookMode_Pre);
	// HookEvent("player_chargedeployed", OnUberDeployed);
	// HookEvent("throwable_hit", CheckPlayerStun, EventHookMode_Pre);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("object_destroyed", OnObjectDestroyed, EventHookMode_Pre);
	HookEvent("object_deflected", OnObjectDeflected, EventHookMode_Pre);
	HookEvent("deploy_buff_banner", OnDeployBackup);
	HookEvent("player_healed", OnPlayerHealed);

	HookUserMessage(GetUserMessageId("PlayerJarated"), OnJarate);  //Used to subtract rage when a boss is jarated (not through Sydney Sleeper)

	AddCommandListener(Listener_Say, "say");
	AddCommandListener(Listener_Say, "say_team");
	AddCommandListener(OnCallForMedic, "voicemenu");    //Used to activate rages
	AddCommandListener(OnSuicide, "explode");           //Used to stop boss from suiciding
	AddCommandListener(OnSuicide, "kill");              //Used to stop boss from suiciding
	AddCommandListener(OnSuicide, "spectate");			//Used to stop boss from suiciding
	AddCommandListener(OnJoinTeam, "jointeam");         //Used to make sure players join the right team
	AddCommandListener(OnJoinTeam, "autoteam");         //Used to make sure players don't kill themselves and change team
	AddCommandListener(OnChangeClass, "joinclass");     //Used to make sure bosses don't change class

	HookConVarChange(cvarEnabled, CvarChange);
	HookConVarChange(cvarPointDelay, CvarChange);
	HookConVarChange(cvarAnnounce, CvarChange);
	HookConVarChange(cvarPointType, CvarChange);
	HookConVarChange(cvarPointDelay, CvarChange);
	HookConVarChange(cvarAliveToEnable, CvarChange);
	HookConVarChange(cvarCrits, CvarChange);
	HookConVarChange(cvarCircuitStun, CvarChange);
	HookConVarChange(cvarHealthBar, HealthbarEnableChanged);
	HookConVarChange(cvarCountdownPlayers, CvarChange);
	HookConVarChange(cvarCountdownTime, CvarChange);
	HookConVarChange(cvarCountdownHealth, CvarChange);
	HookConVarChange(cvarLastPlayerGlow, CvarChange);
	HookConVarChange(cvarSpecForceBoss, CvarChange);
	HookConVarChange(cvarBossTeleporter, CvarChange);
	HookConVarChange(cvarShieldCrits, CvarChange);
	HookConVarChange(cvarCaberDetonations, CvarChange);
	HookConVarChange(cvarGoombaDamage, CvarChange);
	HookConVarChange(cvarGoombaRebound, CvarChange);
	HookConVarChange(cvarBossRTD, CvarChange);
	HookConVarChange(cvarNextmap=FindConVar("sm_nextmap"), CvarChangeNextmap);

	RegConsoleCmd("ff2", FF2Panel);
	RegConsoleCmd("ff2_hp", Command_GetHPCmd);
	RegConsoleCmd("ff2hp", Command_GetHPCmd);
	RegConsoleCmd("ff2_next", QueuePanelCmd);
	RegConsoleCmd("ff2next", QueuePanelCmd);
	RegConsoleCmd("ff2_classinfo", Command_HelpPanelClass);
	RegConsoleCmd("ff2classinfo", Command_HelpPanelClass);
	RegConsoleCmd("ff2_bossinfo", Command_HelpBossPanel);
	RegConsoleCmd("ff2bossinfo", Command_HelpBossPanel);
	RegConsoleCmd("ff2mode", Command_SetDifficulty);
	RegConsoleCmd("ff2_new", NewPanelCmd);
	RegConsoleCmd("ff2new", NewPanelCmd);
	RegConsoleCmd("ff2music", MusicTogglePanelCmd);
	RegConsoleCmd("ff2_music", MusicTogglePanelCmd);
	RegConsoleCmd("ff2tracklist", MusicListCmd);
	RegConsoleCmd("ff2_tracklist", MusicListCmd);
	RegConsoleCmd("ff2voice", VoiceTogglePanelCmd);
	RegConsoleCmd("ff2_voice", VoiceTogglePanelCmd);
	RegConsoleCmd("ff2_resetpoints", ResetQueuePointsCmd);
	RegConsoleCmd("ff2resetpoints", ResetQueuePointsCmd);

	RegConsoleCmd("hale", FF2Panel);
	RegConsoleCmd("hale_hp", Command_GetHPCmd);
	RegConsoleCmd("halehp", Command_GetHPCmd);
	RegConsoleCmd("halemode", Command_SetDifficulty);
	RegConsoleCmd("hale_next", QueuePanelCmd);
	RegConsoleCmd("halenext", QueuePanelCmd);
	RegConsoleCmd("hale_classinfo", Command_HelpPanelClass);
	RegConsoleCmd("haleclassinfo", Command_HelpPanelClass);
	RegConsoleCmd("hale_new", NewPanelCmd);
	RegConsoleCmd("halenew", NewPanelCmd);
	RegConsoleCmd("halemusic", MusicTogglePanelCmd);
	RegConsoleCmd("hale_music", MusicTogglePanelCmd);
	RegConsoleCmd("haletracklist", MusicListCmd);
	RegConsoleCmd("hale_tracklist", MusicListCmd);
	RegConsoleCmd("halevoice", VoiceTogglePanelCmd);
	RegConsoleCmd("hale_voice", VoiceTogglePanelCmd);
	RegConsoleCmd("hale_resetpoints", ResetQueuePointsCmd);
	RegConsoleCmd("haleresetpoints", ResetQueuePointsCmd);

	RegConsoleCmd("nextmap", Command_Nextmap);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	RegAdminCmd("ff2_special", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage:  ff2_special <boss>.  Forces next round to use that boss");
	RegAdminCmd("ff2_addpoints", Command_Points, ADMFLAG_CHEATS, "Usage:  ff2_addpoints <target> <points>.  Adds queue points to any player");
	RegAdminCmd("ff2_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable the control point if ff2_point_type is 0");
	RegAdminCmd("ff2_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable the control point if ff2_point_type is 0");
	RegAdminCmd("ff2_start_music", Command_StartMusic, ADMFLAG_CHEATS, "Start the Boss's music");
	RegAdminCmd("ff2_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently playing Boss music");
	RegAdminCmd("ff2_resetqueuepoints", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("ff2_resetq", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("ff2_charset", Command_Charset, ADMFLAG_CHEATS, "Usage:  ff2_charset <charset>.  Forces FF2 to use a given character set");
	RegAdminCmd("ff2_reload_subplugins", Command_ReloadSubPlugins, ADMFLAG_RCON, "Reload FF2's subplugins.");
	RegAdminCmd("ff2_devmode", Command_DevMode, ADMFLAG_CHEATS, "enable DEVmode");

	RegAdminCmd("hale_select", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage:  hale_select <boss>.  Forces next round to use that boss");
	RegAdminCmd("hale_special", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage:  hale_select <boss>.  Forces next round to use that boss");
	RegAdminCmd("hale_addpoints", Command_Points, ADMFLAG_CHEATS, "Usage:  hale_addpoints <target> <points>.  Adds queue points to any player");
	RegAdminCmd("hale_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable the control point if ff2_point_type is 0");
	RegAdminCmd("hale_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable the control point if ff2_point_type is 0");
	RegAdminCmd("hale_start_music", Command_StartMusic, ADMFLAG_CHEATS, "Start the Boss's music");
	RegAdminCmd("hale_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently playing Boss music");
	RegAdminCmd("hale_resetqueuepoints", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("hale_resetq", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");

	AutoExecConfig(true, "FreakFortress2");

	FF2Cookies=RegClientCookie("ff2_cookies_mk2", "", CookieAccess_Protected); // TODO: 삭제
	YouSpecial=RegClientCookie("ff2_you_special", "", CookieAccess_Protected);

	jumpHUD=CreateHudSynchronizer();
	rageHUD=CreateHudSynchronizer();
	livesHUD=CreateHudSynchronizer();
	abilitiesHUD=CreateHudSynchronizer();
	timeleftHUD=CreateHudSynchronizer();
	infoHUD=CreateHudSynchronizer();

// 	currentBGMData=CreateDataPack(); // PATH | NAME | ARTIST

	decl String:oldVersion[64];
	GetConVarString(cvarVersion, oldVersion, sizeof(oldVersion));
	if(strcmp(oldVersion, PLUGIN_VERSION, false))
	{
		PrintToServer("[FF2] Warning: Your config may be outdated. Back up tf/cfg/sourcemod/FreakFortress2.cfg and delete it, and this plugin will generate a new one that you can then modify to your original values.");
	}

	LoadTranslations("freak_fortress_2.phrases");
	LoadTranslations("common.phrases");

	AddNormalSoundHook(HookSound);

	AddMultiTargetFilter("@hale", BossTargetFilter, "모든 보스", false);
	AddMultiTargetFilter("@!hale", BossTargetFilter, "보스를 제외한 대상들", false);
	AddMultiTargetFilter("@boss", BossTargetFilter, "모든 보스", false);
	AddMultiTargetFilter("@!boss", BossTargetFilter, "보스를 제외한 대상들", false);

	#if defined _steamtools_included
	steamtools=LibraryExists("SteamTools");
	#endif

	#if defined _goomba_included
	goomba=LibraryExists("goomba");
	#endif

	#if defined _tf2attributes_included
	tf2attributes=LibraryExists("tf2attributes");
	#endif
}

public Action:OnPlayerHealed(Handle:event, const String:name[], bool:dont)
{
	// int client = GetClientOfUserId(GetEventInt(event, "patient"));
	int healer = GetClientOfUserId(GetEventInt(event, "healer"));
	int healed = GetEventInt(event, "amount");

	if(CheckRoundState() != 1)
		return Plugin_Continue;

	if(IsBoss(healer) && IsBossYou[healer])
	{
		BossHealth[GetBossIndex(healer)] += healed;
		UpdateHealthBar();
	}
	else if(!IsBoss(healer))
	{
		Damage[healer] += healed/2;
	}

	return Plugin_Continue;
}

public Action:Listener_Say(client, const String:command[], argc)
{
	if(!IsValidClient(client))	return Plugin_Continue;

	char chat[150];
	bool handleChat=false;

	GetCmdArgString(chat, sizeof(chat));

	if(strlen(chat)>=2 ){
		if(chat[1]=='!') handleChat=false;
		else if(chat[1]=='/') handleChat=true;
		else return Plugin_Continue;
		}  // start++; && (chat[1]=='!' || chat[1]=='/')
	else{
		return Plugin_Continue;
	}
	chat[strlen(chat)-1]='\0';

	char specialtext[2][100];
	ExplodeString(chat[2], " ", specialtext, sizeof(specialtext), sizeof(specialtext[]));

	if(StrEqual("프리크", chat[2], true) ||
	StrEqual("ㄹㄹ2", chat[2], true))
	{
		FF2Panel(client, 0);
	}

	else if(StrEqual("음악", chat[2], true) ||
	StrEqual("보스음악", chat[2], true) ||
	StrEqual("ㄹㄹ2ㅡㅕ냧", chat[2], true))
	{
		MusicTogglePanel(client);
	}

	else if(StrEqual("외부음악", chat[2], true))
	{
		ViewClientMusicMenu(client);
	}

	else if(StrEqual("난이도", chat[2], true) ||
	StrEqual("보스난이도", chat[2], true) ||
	StrEqual("ㅗ미드ㅐㅇㄷ", chat[2], true))
	{
		CallDifficultyMenu(client);
	}

	else if(StrEqual("패치", chat[2], true) ||
	StrEqual("업데이트", chat[2], true) ||
	StrEqual("ㄹㄹ2ㅜㄷㅈ", chat[2], true))
	{
		NewPanel(client, maxVersion);
	}

	else if(StrEqual("대기열", chat[2], true) ||
	StrEqual("보스대기열", chat[2], true) ||
	StrEqual("ㄹㄹ2ㅜㄷㅌㅅ", chat[2], true))
	{
		QueuePanelCmd(client, 0);
	}

	else if(StrEqual("정보", chat[2], true) ||
	StrEqual("보스정보", chat[2], true) ||
	StrEqual("ㄹㄹ2ㅠㅐㄴ냐ㅜ래", chat[2], true))
	{
		HelpPanelBoss(client);
	}

	else if(StrEqual("병과정보", chat[2], true) ||
	StrEqual("내정보", chat[2], true) ||
	StrEqual("ㄹㄹ2침ㄴ냐ㅜ래", chat[2], true))
	{
		HelpPanelClass(client);
	}

	else if(StrEqual("you", specialtext[0], true) ||
	StrEqual("너", specialtext[0], true))
	{
		SetYouSpecialString(client, chat[strlen(specialtext[0])+3]);
	}
	return handleChat ? Plugin_Handled : Plugin_Continue;
}

public Action:OnRPS(Handle:event, const String:name[], bool:dont)
{
	int winner = GetEventInt(event, "winner");
	int loser = GetEventInt(event, "loser");

	if(!IsValidClient(winner) || !IsValidClient(loser)) // Check for valid clients
	{
			return;
	}
	if(!IsBoss(winner) && IsBoss(loser) && GetBossIndex(loser)>=0) // Boss Loses on RPS? Kill current boss.
	{
			// RPSWinner=winner;
			RPSLoser[winner]=loser;
			CreateTimer(3.1, OnRPS_Timer, winner);
			return;
	}
}

public Action:OnRPS_Timer(Handle:timer, any:client)
{
	if(!IsValidClient(RPSLoser[client])) return Plugin_Continue;
	if(!IsValidClient(client)) ForcePlayerSuicide(RPSLoser[client]);

	SDKHooks_TakeDamage(RPSLoser[client], client, client, float(FF2_GetBossHealth(GetBossIndex(RPSLoser[client]))), DMG_GENERIC, -1);
	return Plugin_Continue;
}

public Action:Command_SetDifficulty(client, args)
{
	CallDifficultyMenu(client);
	return Plugin_Continue;
}

public Action:MusicListCmd(client, args)
{
	ViewClientMusicMenu(client);
	return Plugin_Continue;
}

CallDifficultyMenu(client)
{
	// int BossDifficulty:difficulty=GetClientDifficultyCookie(client);
	Handle menu=CreateMenu(Menu_SetDifficulty);
	char item[80];

	GetDifficultyString(GetClientDifficultyCookie(client), item, sizeof(item));

	SetMenuTitle(menu, "보스 난이도 설정 (현재 난이도: %s)", item);
	AddMenuItem(menu, "이지", "쉬움: 엥? 이거 완전 \"응애\" 난이도 아니냐!?", ITEMDRAW_DISABLED);
	Format(item, sizeof(item), "%t", "difficulty_normal");
	AddMenuItem(menu, "노말", item);
	Format(item, sizeof(item), "%t", "difficulty_hard");
	AddMenuItem(menu, "어려움", item);
	Format(item, sizeof(item), "%t", "difficulty_veryhard");
	AddMenuItem(menu, "매우 어려움", item);
	Format(item, sizeof(item), "%t", "difficulty_tryhard");
	AddMenuItem(menu, "너무 어려움", item);
	Format(item, sizeof(item), "%t", "difficulty_nothuman");
	AddMenuItem(menu, "사람이 아니다.", item);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
}

public Menu_SetDifficulty(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
	  case MenuAction_End:
	  {
	  	CloseHandle(menu);
	  }
	  case MenuAction_Select:
		{
			char item[50];
			switch(param2)
			{
			  case 0:
			  {
			    CPrintToChat(param1, "그거 참 흥미롭네요.. {red}대체 어떻게 이걸 고른거죠{default}?");
			  }
				case 1:
				{
					SetClientDifficultyCookie(param1, 1);
				}
				case 2:
				{
					SetClientDifficultyCookie(param1, 2);
				}
				case 3:
				{
					SetClientDifficultyCookie(param1, 3);
				}
				case 4:
				{
					SetClientDifficultyCookie(param1, 4);
				}
				case 5:
				{
					SetClientDifficultyCookie(param1, 5);
				}
			}
			GetDifficultyString(GetClientDifficultyCookie(param1), item, sizeof(item));
			CPrintToChat(param1, "{olive}[FF2]{default} %t", "ff2_set_difficulty", item);
		}
	}
}

SetClientDifficultyCookie(client, difficulty)
{
	char CookieV[24];
	char CookieExpV[8][5];
	GetClientCookie(client, FF2Cookies, CookieV, sizeof(CookieV));

	ExplodeString(CookieV, " ", CookieExpV, 8, 5);
	Format(CookieV, sizeof(CookieV), "%s %s %s %s %i %s %s %s", CookieExpV[0], CookieExpV[1], CookieExpV[2], CookieExpV[3], difficulty, CookieExpV[5], CookieExpV[6], CookieExpV[7]);
	SetClientCookie(client, FF2Cookies, CookieV);
}

stock GetClientDifficultyCookie(client)
{
	char CookieV[24];
	char CookieExpV[8][5];
	if(!IsValidClient(client) || !AreClientCookiesCached(client))
	{
		return 0;
	}
	GetClientCookie(client, FF2Cookies, CookieV, sizeof(CookieV));

	ExplodeString(CookieV, " ", CookieExpV, 8, 5);
	return StringToInt(CookieExpV[4]);
}

public Action Command_HelpBossPanel(client, args)
{
	HelpPanelBoss(client);
	return Plugin_Continue;
}

public Action Command_DevMode(int client, int args)
{
	if(DEVmode)
		DEVmode = false;
	else
		DEVmode = true;

	CPrintToChatAll("{olive}[FF2]{default} DEVmode: %s", DEVmode ? "ON" : "OFF");

	return Plugin_Continue;
}

public bool:BossTargetFilter(const String:pattern[], Handle:clients)
{
	bool non=StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && FindValueInArray(clients, client)==-1)
		{
			if(Enabled && IsBoss(client))
			{
				if(!non)
				{
					PushArrayCell(clients, client);
				}
			}
			else if(non)
			{
				PushArrayCell(clients, client);
			}
		}
	}
	return true;
}

public OnLibraryAdded(const String:name[])
{
	#if defined _steamtools_included
	if(!strcmp(name, "SteamTools", false))
	{
		steamtools=true;
	}
	#endif

	#if defined _tf2attributes_included
	if(!strcmp(name, "tf2attributes", false))
	{
		tf2attributes=true;
	}
	#endif

	#if defined _goomba_included
	if(!strcmp(name, "goomba", false))
	{
		goomba=true;
	}
	#endif

	if(!strcmp(name, "smac", false))
	{
		smac=true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	#if defined _steamtools_included
	if(!strcmp(name, "SteamTools", false))
	{
		steamtools=false;
	}
	#endif

	#if defined _tf2attributes_included
	if(!strcmp(name, "tf2attributes", false))
	{
		tf2attributes=false;
	}
	#endif

	#if defined _goomba_included
	if(!strcmp(name, "goomba", false))
	{
		goomba=false;
	}
	#endif

	if(!strcmp(name, "smac", false))
	{
		smac=false;
	}
}

public OnConfigsExecuted()
{
	tf_arena_use_queue=GetConVarInt(FindConVar("tf_arena_use_queue"));
	mp_teams_unbalance_limit=GetConVarInt(FindConVar("mp_teams_unbalance_limit"));
	tf_arena_first_blood=GetConVarInt(FindConVar("tf_arena_first_blood"));
	mp_forcecamera=GetConVarInt(FindConVar("mp_forcecamera"));
	tf_dropped_weapon_lifetime=bool:GetConVarInt(FindConVar("tf_dropped_weapon_lifetime"));
	tf_feign_death_activate_damage_scale=GetConVarFloat(FindConVar("tf_feign_death_activate_damage_scale"));
	tf_feign_death_damage_scale=GetConVarFloat(FindConVar("tf_feign_death_damage_scale"));
	GetConVarString(FindConVar("mp_humans_must_join_team"), mp_humans_must_join_team, sizeof(mp_humans_must_join_team));

	if(IsFF2Map(currentmap) && GetConVarBool(cvarEnabled))
	{
		EnableFF2();
	}
	else
	{
		DisableFF2();
	}
}

public OnMapStart()
{
	HPTime=0.0;
	doorCheckTimer=INVALID_HANDLE;
	RoundCount=0;
	FF2ServerFlag=0;
	CheckedFirstRound=false;
	GetCurrentMap(currentmap, sizeof(currentmap));
	CloseLoadMusicTimer();

	for(int client; client<=MaxClients; client++)
	{
		KSpreeTimer[client]=0.0;
		FF2flags[client]=0;
		FF2Userflags[client]=0;
		Incoming[client]=-1;
		MusicTimer[client]=INVALID_HANDLE;
	}

	for(int specials; specials<MAXSPECIALS; specials++)
	{
		if(BossKV[specials]!=INVALID_HANDLE)
		{
			CloseHandle(BossKV[specials]);
			BossKV[specials]=INVALID_HANDLE;
		}
	}
}

public OnMapEnd()
{
	// MapIsRunning = false;
	if(Enabled || Enabled2)
	{
		DisableFF2();
	}
}

public OnPluginEnd()
{
	OnMapEnd();
}

public EnableFF2()
{
	Enabled=true;
	Enabled2=true;

	//Cache cvars
	SetConVarString(FindConVar("ff2_version"), PLUGIN_VERSION);
	Announce=GetConVarFloat(cvarAnnounce);
	PointType=GetConVarInt(cvarPointType);
	PointDelay=GetConVarInt(cvarPointDelay);
	if(PointDelay<0)
	{
		PointDelay*=-1;
	}
	GoombaDamage=GetConVarFloat(cvarGoombaDamage);
	reboundPower=GetConVarFloat(cvarGoombaRebound);
	canBossRTD=GetConVarBool(cvarBossRTD);
	AliveToEnable=GetConVarInt(cvarAliveToEnable);
	BossCrits=GetConVarBool(cvarCrits);
	if(GetConVarInt(cvarFirstRound)!=-1)
	{
		arenaRounds=GetConVarInt(cvarFirstRound) ? 0 : 1;
	}
	else
	{
		arenaRounds=GetConVarInt(cvarArenaRounds);
	}
	circuitStun=GetConVarFloat(cvarCircuitStun);
	countdownHealth=GetConVarInt(cvarCountdownHealth);
	countdownPlayers=GetConVarInt(cvarCountdownPlayers);
	countdownTime=GetConVarInt(cvarCountdownTime);
	lastPlayerGlow=GetConVarBool(cvarLastPlayerGlow);
	bossTeleportation=GetConVarBool(cvarBossTeleporter);
	shieldCrits=GetConVarInt(cvarShieldCrits);
	allowedDetonations=GetConVarInt(cvarCaberDetonations);

	//Set some Valve cvars to what we want them to be
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_forcecamera"), 0);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 0);
	SetConVarFloat(FindConVar("tf_feign_death_activate_damage_scale"), 0.3);
	SetConVarFloat(FindConVar("tf_feign_death_damage_scale"), 0.0);
	SetConVarString(FindConVar("mp_humans_must_join_team"), "any");

	float time=Announce;
	if(time>1.0)
	{
		CreateTimer(time, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	CheckToChangeMapDoors();
	MapHasMusic(true);
	FindCharacters();
	strcopy(FF2CharSetString, 2, "");

	if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE)
	{
		ServerCommand("smac_removecvar sv_cheats");
		ServerCommand("smac_removecvar host_timescale");
	}

	bMedieval=FindEntityByClassname(-1, "tf_logic_medieval")!=-1 || bool:GetConVarInt(FindConVar("tf_medieval"));
	healthBar = FindHealthBar();

	#if defined _steamtools_included
	if(steamtools)
	{
		decl String:gameDesc[64];
		Format(gameDesc, sizeof(gameDesc), "POTRY %s", PLUGIN_VERSION);
		Steam_SetGameDescription(gameDesc);
	}
	#endif

	changeGamemode=0;
}

public DisableFF2()
{
	Enabled=false;
	Enabled2=false;

	DisableSubPlugins();

	SetConVarInt(FindConVar("tf_arena_use_queue"), tf_arena_use_queue);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), mp_teams_unbalance_limit);
	SetConVarInt(FindConVar("tf_arena_first_blood"), tf_arena_first_blood);
	SetConVarInt(FindConVar("mp_forcecamera"), mp_forcecamera);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), tf_dropped_weapon_lifetime);
	SetConVarFloat(FindConVar("tf_feign_death_activate_damage_scale"), tf_feign_death_activate_damage_scale);
	SetConVarFloat(FindConVar("tf_feign_death_damage_scale"), tf_feign_death_damage_scale);
	SetConVarString(FindConVar("mp_humans_must_join_team"), mp_humans_must_join_team);

	if(doorCheckTimer!=INVALID_HANDLE)
	{
		KillTimer(doorCheckTimer);
		doorCheckTimer=INVALID_HANDLE;
	}
	CloseLoadMusicTimer();
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(BossInfoTimer[client][1]!=INVALID_HANDLE)
			{
				KillTimer(BossInfoTimer[client][1]);
				BossInfoTimer[client][1]=INVALID_HANDLE;
			}
		}

		if(MusicTimer[client]!=INVALID_HANDLE)
		{
			KillTimer(MusicTimer[client]);
			MusicTimer[client]=INVALID_HANDLE;
		}
		else if(MusicTimer[client])
		{
			Debug("NOT INVALID_HANDLE!!!");
			KillTimer(MusicTimer[client]);
			MusicTimer[client]=INVALID_HANDLE;
		}

		bossHasReloadAbility[client]=false;
		bossHasRightMouseAbility[client]=false;
	}

	if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE)
	{
		ServerCommand("smac_addcvar sv_cheats replicated ban 0 0");
		ServerCommand("smac_addcvar host_timescale replicated ban 1.0 1.0");
	}

	#if defined _steamtools_included
	if(steamtools)
	{
		decl String:gameDesc[64];
		Format(gameDesc, sizeof(gameDesc), "POTRY %s", PLUGIN_VERSION);
		Steam_SetGameDescription(gameDesc);
	}
	#endif

	changeGamemode=0;
}

public FindCharacters()  //TODO: Investigate KvGotoFirstSubKey; KvGotoNextKey
{
	char config[PLATFORM_MAX_PATH], key[4], charset[42];
	Specials = 0;
	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/characters.cfg");

	if(!FileExists(config))
	{
		LogError("[FF2] Freak Fortress 2 disabled-can not find characters.cfg!");
		Enabled2=false;
		return;
	}

	Handle Kv = CreateKeyValues("");
	FileToKeyValues(Kv, config);
	int NumOfCharSet = FF2CharSet;

	Action action = Plugin_Continue;
	Call_StartForward(OnLoadCharacterSet);
	Call_PushCellRef(NumOfCharSet);
	strcopy(charset, sizeof(charset), FF2CharSetString);
	Call_PushStringEx(charset, sizeof(charset), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(action);
	if(action == Plugin_Changed)
	{
		int i=-1;
		if(strlen(charset))
		{
			KvRewind(Kv);
			for(i=0; ; i++)
			{
				KvGetSectionName(Kv, config, sizeof(config));
				if(!strcmp(config, charset, false))
				{
					FF2CharSet=i;
					strcopy(FF2CharSetString, PLATFORM_MAX_PATH, charset);
					KvGotoFirstSubKey(Kv);
					break;
				}

				if(!KvGotoNextKey(Kv))
				{
					i=-1;
					break;
				}
			}
		}

		if(i==-1)
		{
			FF2CharSet=NumOfCharSet;
			for(i=0; i<FF2CharSet; i++)
			{
				KvGotoNextKey(Kv);
			}
			KvGotoFirstSubKey(Kv);
			KvGetSectionName(Kv, FF2CharSetString, sizeof(FF2CharSetString));
		}
	}

	KvRewind(Kv);
	for(int i; i<FF2CharSet; i++)
	{
		KvGotoNextKey(Kv);
	}

	for(int i=1; i<MAXSPECIALS; i++)
	{
		IntToString(i, key, sizeof(key));
		KvGetString(Kv, key, config, PLATFORM_MAX_PATH);
		if(!config[0])  //TODO: Make this more user-friendly (don't immediately break-they might have missed a number)
		{
			break;
		}
		LoadCharacter(config);
	}

	KvGetString(Kv, "chances", ChancesString, sizeof(ChancesString));
	CloseHandle(Kv);

	if(ChancesString[0])
	{
		decl String:stringChances[MAXSPECIALS*2][8];

		int amount=ExplodeString(ChancesString, ";", stringChances, MAXSPECIALS*2, 8);
		if(amount % 2)
		{
			LogError("[FF2 Bosses] Invalid chances string, disregarding chances");
			strcopy(ChancesString, sizeof(ChancesString), "");
			amount=0;
		}

		chances[0]=StringToInt(stringChances[0]);
		chances[1]=StringToInt(stringChances[1]);
		for(chancesIndex=2; chancesIndex<amount; chancesIndex++)
		{
			if(chancesIndex % 2)
			{
				if(StringToInt(stringChances[chancesIndex])<=0)
				{
					LogError("[FF2 Bosses] Character %i cannot have a zero or negative chance, disregarding chances", chancesIndex-1);
					strcopy(ChancesString, sizeof(ChancesString), "");
					break;
				}
				chances[chancesIndex]=StringToInt(stringChances[chancesIndex])+chances[chancesIndex-2];
			}
			else
			{
				chances[chancesIndex]=StringToInt(stringChances[chancesIndex]);
			}
		}
	}

	if(FileExists("sound/saxton_hale/9000.wav", true))
	{
		AddFileToDownloadsTable("sound/saxton_hale/9000.wav");
		PrecacheSound("saxton_hale/9000.wav", true);
	}
	PrecacheSound("vo/announcer_am_capincite01.mp3", true);
	PrecacheSound("vo/announcer_am_capincite03.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled01.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled02.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled03.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled04.mp3", true);
	PrecacheSound("weapons/barret_arm_zap.wav", true);
	PrecacheSound("vo/announcer_ends_5min.mp3", true);
	PrecacheSound("vo/announcer_ends_2min.mp3", true);
	PrecacheSound("player/doubledonk.wav", true);
	isCharSetSelected=false;
}

EnableSubPlugins(bool:force=false)
{
	if(areSubPluginsEnabled && !force)
	{
		return;
	}

	areSubPluginsEnabled = true;
	char path[PLATFORM_MAX_PATH], filename[PLATFORM_MAX_PATH], filename_old[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "plugins/freaks");
	FileType filetype;
	Handle directory = OpenDirectory(path);
	while(ReadDirEntry(directory, filename, PLATFORM_MAX_PATH, filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".smx", false)!=-1)
		{
			Format(filename_old, PLATFORM_MAX_PATH, "%s/%s", path, filename);
			ReplaceString(filename, PLATFORM_MAX_PATH, ".smx", ".ff2", false);
			Format(filename, PLATFORM_MAX_PATH, "%s/%s", path, filename);
			DeleteFile(filename);
			RenameFile(filename, filename_old);
		}
	}

	directory=OpenDirectory(path);
	while(ReadDirEntry(directory, filename, PLATFORM_MAX_PATH, filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".ff2", false)!=-1)
		{
			ServerCommand("sm plugins load freaks/%s", filename);
		}
	}
}

DisableSubPlugins(bool:force=false)
{
	if(!areSubPluginsEnabled && !force)
	{
		return;
	}

	decl String:path[PLATFORM_MAX_PATH], String:filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "plugins/freaks");
	decl FileType:filetype;
	Handle directory=OpenDirectory(path);
	while(ReadDirEntry(directory, filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".ff2", false)!=-1)
		{
			InsertServerCommand("sm plugins unload freaks/%s", filename);  //ServerCommand will not work when switching maps
		}
	}
	ServerExecute();
	areSubPluginsEnabled=false;
}

public LoadCharacter(const String:character[])
{
	char extensions[][]={".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"};
	decl String:config[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, config, sizeof(config), "configs/freak_fortress_2/%s.cfg", character);
	if(!FileExists(config))
	{
		LogError("[FF2 Bosses] Character %s does not exist!", character);
		return;
	}
	BossKV[Specials]=CreateKeyValues("character");
	FileToKeyValues(BossKV[Specials], config);
/*
	int version=KvGetNum(BossKV[Specials], "version", 1);
	if(version!=StringToInt(MAJOR_REVISION))
	{
		LogError("[FF2 Bosses] Character %s is only compatible with FF2 v%i!", character, version);
		return;
	}
*/

	for(int i=1; ; i++)
	{
		Format(config, 10, "ability%i", i);
		if(KvJumpToKey(BossKV[Specials], config))
		{
			decl String:plugin_name[64];
			KvGetString(BossKV[Specials], "plugin_name", plugin_name, 64);
			BuildPath(Path_SM, config, sizeof(config), "plugins/freaks/%s.ff2", plugin_name);
			if(!FileExists(config))
			{
				LogError("[FF2 Bosses] Character %s needs plugin %s!", character, plugin_name);
				return;
			}
		}
		else
		{
			break;
		}
	}
	KvRewind(BossKV[Specials]);

	decl String:key[PLATFORM_MAX_PATH], String:section[64];
	KvSetString(BossKV[Specials], "filename", character);
	KvGetString(BossKV[Specials], "name", config, sizeof(config));
	bBlockVoice[Specials]=bool:KvGetNum(BossKV[Specials], "sound_block_vo", 0);
	BossSpeed[Specials]=KvGetFloat(BossKV[Specials], "maxspeed", 340.0);
	//BossRageDamage[Specials]=KvGetFloat(BossKV[Specials], "ragedamage", 1900.0);
	KvGotoFirstSubKey(BossKV[Specials]);

	while(KvGotoNextKey(BossKV[Specials]))
	{
		KvGetSectionName(BossKV[Specials], section, sizeof(section));
		if(!strcmp(section, "download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[Specials], key, config, sizeof(config));
				if(!config[0])
				{
					break;
				}

				if(FileExists(config, true))
				{
					AddFileToDownloadsTable(config);
				}
				else
				{
					LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, config);
				}
			}
		}
		else if(!strcmp(section, "mod_download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[Specials], key, config, sizeof(config));
				if(!config[0])
				{
					break;
				}

				for(int extension; extension<sizeof(extensions); extension++)
				{
					Format(key, PLATFORM_MAX_PATH, "%s%s", config, extensions[extension]);
					if(FileExists(key, true))
					{
						AddFileToDownloadsTable(key);
					}
					else
					{
						LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, key);
					}
				}
			}
		}
		else if(!strcmp(section, "mat_download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[Specials], key, config, sizeof(config));
				if(!config[0])
				{
					break;
				}
				Format(key, sizeof(key), "%s.vtf", config);
				if(FileExists(key, true))
				{
					AddFileToDownloadsTable(key);
				}
				else
				{
					LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, key);
				}
				Format(key, sizeof(key), "%s.vmt", config);
				if(FileExists(key, true))
				{
					AddFileToDownloadsTable(key);
				}
				else
				{
					LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, key);
				}
			}
		}
	}
	Specials++;
}

public PrecacheCharacter(characterIndex)
{
	decl String:file[PLATFORM_MAX_PATH], String:filePath[PLATFORM_MAX_PATH], String:key[8], String:section[16], String:bossName[64];
	KvRewind(BossKV[characterIndex]);
	KvGetString(BossKV[characterIndex], "filename", bossName, sizeof(bossName));
	KvGotoFirstSubKey(BossKV[characterIndex]);
	while(KvGotoNextKey(BossKV[characterIndex]))
	{
		KvGetSectionName(BossKV[characterIndex], section, sizeof(section));
		if(StrEqual(section, "sound_bgm") || StrEqual(section, "sound_hell_bgm"))
		{
			for(int i=1; ; i++)
			{
				Format(key, sizeof(key), "path%d", i);
				KvGetString(BossKV[characterIndex], key, file, sizeof(file));
				if(!file[0])
				{
					break;
				}

				Format(filePath, sizeof(filePath), "sound/%s", file);  //Sounds doesn't include the sound/ prefix, so add that
				if(FileExists(filePath, true))
				{
					PrecacheSound(file);
				}
				else
				{
					LogError("[FF2 Bosses] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
				}
			}
		}
		else if(StrEqual(section, "mod_precache") || !StrContains(section, "sound_") || StrEqual(section, "catch_phrase"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[characterIndex], key, file, sizeof(file));
				if(!file[0])
				{
					break;
				}

				if(StrEqual(section, "mod_precache"))
				{
					if(FileExists(file, true))
					{
						PrecacheModel(file);
					}
					else
					{
						LogError("[FF2 Bosses] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
					}
				}
				else
				{
					Format(filePath, sizeof(filePath), "sound/%s", file);  //Sounds doesn't include the sound/ prefix, so add that
					if(FileExists(filePath, true))
					{
						PrecacheSound(file);
					}
					else
					{
						LogError("[FF2 Bosses] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
					}
				}
			}
		}
	}
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar==cvarPointDelay)
	{
		PointDelay=StringToInt(newValue);
		if(PointDelay<0)
		{
			PointDelay*=-1;
		}
	}
	else if(convar==cvarAnnounce)
	{
		Announce=StringToFloat(newValue);
	}
	else if(convar==cvarPointType)
	{
		PointType=StringToInt(newValue);
	}
	else if(convar==cvarPointDelay)
	{
		PointDelay=StringToInt(newValue);
	}
	else if(convar==cvarAliveToEnable)
	{
		AliveToEnable=StringToInt(newValue);
	}
	else if(convar==cvarCrits)
	{
		BossCrits = StringToInt(newValue) > 0;
	}
	else if(convar==cvarFirstRound)  //DEPRECATED
	{
		if(StringToInt(newValue)!=-1)
		{
			arenaRounds=StringToInt(newValue) ? 0 : 1;
		}
	}
	else if(convar==cvarArenaRounds)
	{
		arenaRounds=StringToInt(newValue);
	}
	else if(convar==cvarCircuitStun)
	{
		circuitStun=StringToFloat(newValue);
	}
	else if(convar==cvarCountdownPlayers)
	{
		countdownPlayers=StringToInt(newValue);
	}
	else if(convar==cvarCountdownTime)
	{
		countdownTime=StringToInt(newValue);
	}
	else if(convar==cvarCountdownHealth)
	{
		countdownHealth=StringToInt(newValue);
	}
	else if(convar==cvarLastPlayerGlow)
	{
		lastPlayerGlow=bool:StringToInt(newValue);
	}
	else if(convar==cvarSpecForceBoss)
	{
		SpecForceBoss=bool:StringToInt(newValue);
	}
	else if(convar==cvarBossTeleporter)
	{
		bossTeleportation=bool:StringToInt(newValue);
	}
	else if(convar==cvarShieldCrits)
	{
		shieldCrits=StringToInt(newValue);
	}
	else if(convar==cvarCaberDetonations)
	{
		allowedDetonations=StringToInt(newValue);
	}
	else if(convar==cvarGoombaDamage)
	{
		GoombaDamage=StringToFloat(newValue);
	}
	else if(convar==cvarGoombaRebound)
	{
		reboundPower=StringToFloat(newValue);
	}
	else if(convar==cvarBossRTD)
	{
		canBossRTD=bool:StringToInt(newValue);
	}
	else if(convar==cvarEnabled)
	{
		StringToInt(newValue) ? (changeGamemode=Enabled ? 0 : 1) : (changeGamemode=!Enabled ? 0 : 2);
	}
}
/* TODO: Re-enable in 2.0.0
#if defined _smac_included
public Action:SMAC_OnCheatDetected(client, const String:module[], DetectionType:type, Handle:info)
{
	Debug("SMAC: Cheat detected!");
	if(type==Detection_CvarViolation)
	{
		Debug("SMAC: Cheat was a cvar violation!");
		decl String:cvar[PLATFORM_MAX_PATH];
		KvGetString(info, "cvar", cvar, sizeof(cvar));
		Debug("Cvar was %s", cvar);
		if((StrEqual(cvar, "sv_cheats") || StrEqual(cvar, "host_timescale")) && !(FF2flags[Boss[client]] & FF2FLAG_CHANGECVAR))
		{
			Debug("SMAC: Ignoring violation");
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
#endif
*/
public Action:Timer_Announce(Handle:timer)
{
	static announcecount=-1;
	announcecount++;
	if(Announce>1.0 && Enabled2)
	{
		switch(announcecount)
		{
			/*
			case 0:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_last_update", PLUGIN_VERSION, ff2versiondates[maxVersion]);
			}
			*/
			case 1:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_1");
			}
			case 2:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_2");
			}
			case 3:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_3");
			}
			case 4:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_4");
			}
			case 5:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_5");
			}
			case 6:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_6");
			}
			case 7:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_7");
			}
			case 8:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_8");
			}
			case 9:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_9");
			}
			case 10:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_10");
			}
			case 11:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_11");
			}
			case 12:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_12");
			}
			case 13:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_13");
			}
			case 14:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_14");
			}
			case 15:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_15");
			}
			case 16:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_16");
			}
			case 17:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_17");
			}
			case 18:
			{
				CPrintToChatAll("{lightblue}[POTRY]{default} %t", "potry_announce_18");
			}


			default:
			{
				announcecount=0;
				CPrintToChatAll("{olive}[FF2]{default} %t", "type_ff2_to_open_menu");
			}
		}
	}
	return Plugin_Continue;
}

stock bool:CheckToChangeMapDoors()
{
	if(!Enabled || !Enabled2)
	{
		return;
	}

	decl String:config[PLATFORM_MAX_PATH];
	checkDoors=false;
	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/doors.cfg");
	if(!FileExists(config))
	{
		if(!strncmp(currentmap, "vsh_lolcano_pb1", 15, false))
		{
			checkDoors=true;
		}
		return;
	}

	Handle file=OpenFile(config, "r");
	if(file==INVALID_HANDLE)
	{
		if(!strncmp(currentmap, "vsh_lolcano_pb1", 15, false))
		{
			checkDoors=true;
		}
		return;
	}

	while(!IsEndOfFile(file) && ReadFileLine(file, config, sizeof(config)))
	{
		Format(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
		{
			continue;
		}

		if(StrContains(currentmap, config, false)!=-1 || !StrContains(config, "all", false))
		{
			CloseHandle(file);
			checkDoors=true;
			return;
		}
	}
	CloseHandle(file);
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(changeGamemode==1)
	{
		EnableFF2();
	}
	else if(changeGamemode==2)
	{
		DisableFF2();
	}

	if(!GetConVarBool(cvarEnabled))
	{
		#if defined _steamtools_included
		if(steamtools)
		{
			Steam_SetGameDescription("Team Fortress");
		}
		#endif
		Enabled2=false;
	}

	Enabled=Enabled2;
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	if(FileExists("bNextMapToFF2"))
	{
		DeleteFile("bNextMapToFF2");
	}

	bool blueBoss;
	switch(GetConVarInt(cvarForceBossTeam))
	{
		case 1:
		{
			blueBoss=bool:GetRandomInt(0, 1);
		}
		case 2:
		{
			blueBoss=false;
		}
		default:
		{
			blueBoss=true;
		}
	}

	if(blueBoss)
	{
		SetTeamScore(_:TFTeam_Red, GetTeamScore(OtherTeam));
		SetTeamScore(_:TFTeam_Blue, GetTeamScore(BossTeam));
		OtherTeam=_:TFTeam_Red;
		BossTeam=_:TFTeam_Blue;
	}
	else
	{
		SetTeamScore(_:TFTeam_Red, GetTeamScore(BossTeam));
		SetTeamScore(_:TFTeam_Blue, GetTeamScore(OtherTeam));
		OtherTeam=_:TFTeam_Blue;
		BossTeam=_:TFTeam_Red;
	}

	playing=0;
	HighestDPS=0.0;
	HighestDPSClient=0;
	NoticedLastman=false;
	for(int client=1; client<=MaxClients; client++)
	{
		Damage[client]=0;
		uberTarget[client]=-1;
		emitRageSound[client]=true;
		FF2Userflags[client]=0;
		for(int loop=0; loop<sizeof(PlayerDamageDPS[]); loop++)
		{
		  PlayerDamageDPS[client][loop]=0.0;
		}
		if(IsValidClient(client) && GetClientTeam(client)>_:TFTeam_Spectator)
		{
			playing++;
		}
	}

	if(GetClientCount()<=1 || playing<=1)  //Not enough players D:
	{
		CPrintToChatAll("{olive}[FF2]{default} %t", "needmoreplayers");
		Enabled=false;
		CheckedFirstRound=false;
		DisableSubPlugins();
		SetControlPoint(true);
		return Plugin_Continue;
	}
	else if(RoundCount<arenaRounds)  //We're still in arena mode
	{
		CPrintToChatAll("{olive}[FF2]{default} %t", "arena_round", arenaRounds-RoundCount);
		Enabled=false;
		DisableSubPlugins();
		SetArenaCapEnableTime(60.0);
		CreateTimer(71.0, Timer_EnableCap, _, TIMER_FLAG_NO_MAPCHANGE);
		bool toRed;
		TFTeam team;
		for(int client; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && (team = view_as<TFTeam>(GetClientTeam(client))) > TFTeam_Spectator)
			{
				SetEntProp(client, Prop_Send, "m_lifeState", 2);
				if(toRed && team!=TFTeam_Red)
				{
					ChangeClientTeam(client, _:TFTeam_Red);
				}
				else if(!toRed && team!=TFTeam_Blue)
				{
					ChangeClientTeam(client, _:TFTeam_Blue);
				}
				SetEntProp(client, Prop_Send, "m_lifeState", 0);
				TF2_RespawnPlayer(client);
				toRed=!toRed;
			}
		}
		return Plugin_Continue;
	}

	for(int client; client<=MaxClients; client++)
	{
		Boss[client]=0;
		if(IsValidClient(client) && IsPlayerAlive(client) && !(FF2flags[client] & FF2FLAG_HASONGIVED))
		{
			TF2_RespawnPlayer(client);
		}
	}

	Enabled=true;
	EnableSubPlugins();
	CheckArena();

	SetConVarBool(FindConVar("mp_friendlyfire"), false, _, false);

	bool omit[MAXPLAYERS+1];
	Boss[0]=GetClientWithMostQueuePoints(omit);
	omit[Boss[0]]=true;

	bool teamHasPlayers[4];
	for(int client=1; client<=MaxClients; client++)  //Find out if each team has at least one player on it
	{
		if(IsValidClient(client))
		{
			TFTeam team = view_as<TFTeam>(GetClientTeam(client));
			if(team>TFTeam_Spectator)
			{
				teamHasPlayers[team]=true;
			}

			if(teamHasPlayers[TFTeam_Blue] && teamHasPlayers[TFTeam_Red])
			{
				break;
			}
		}
	}

	if(!teamHasPlayers[TFTeam_Blue] || !teamHasPlayers[TFTeam_Red])  //If there's an empty team make sure it gets populated
	{
		if(IsValidClient(Boss[0]) && GetClientTeam(Boss[0])!=BossTeam)
		{
			AssignTeam(Boss[0], BossTeam);
		}

		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && !IsBoss(client) && GetClientTeam(client)!=OtherTeam)
			{
				CreateTimer(0.1, MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		return Plugin_Continue;  //NOTE: This is needed because OnRoundStart gets fired a second time once both teams have players
	}

	PickCharacter(0, 0);
	if((Special[0]<0) || !BossKV[Special[0]])
	{
		LogError("[FF2 Bosses] Couldn't find a boss!");
		return Plugin_Continue;
	}

	FindCompanion(0, playing, omit);  //Find companions for the boss!

	for(int boss; boss<=MaxClients; boss++)
	{
		BossInfoTimer[boss][0]=INVALID_HANDLE;
		BossInfoTimer[boss][1]=INVALID_HANDLE;
		IsBossYou[boss]=false;
		if(Boss[boss])
		{
			CreateTimer(0.3, MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
			BossInfoTimer[boss][0]=CreateTimer(30.2, BossInfoTimer_Begin, boss, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	CreateTimer(3.5, StartResponseTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(9.1, StartBossTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(9.58, ReUpdateBossHealth, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(9.6, MessageTimer, _, TIMER_FLAG_NO_MAPCHANGE);

	for(int entity=MaxClients+1; entity<MAXENTITIES; entity++)
	{
		if(!IsValidEntity(entity))
		{
			continue;
		}

		decl String:classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!strcmp(classname, "func_regenerate"))
		{
			AcceptEntityInput(entity, "Kill");
		}
		else if(!strcmp(classname, "func_respawnroomvisualizer"))
		{
			AcceptEntityInput(entity, "Disable");
		}
	}

	healthcheckused=0;
	firstBlood=true;
	return Plugin_Continue;
}

public Action:ReUpdateBossHealth(Handle timer)
{
	int boss;
	for(int client = 1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && (boss = GetBossIndex(client)) != -1)
		{
			FormulaBossHealth(boss);
		}
	}
}

public Action:Timer_EnableCap(Handle:timer)
{
	if((Enabled || Enabled2) && CheckRoundState()==-1)
	{
		SetControlPoint(true);
		if(checkDoors)
		{
			int ent=-1;
			while((ent=FindEntityByClassname2(ent, "func_door"))!=-1)
			{
				AcceptEntityInput(ent, "Open");
				AcceptEntityInput(ent, "Unlock");
			}

			if(doorCheckTimer==INVALID_HANDLE)
			{
				doorCheckTimer=CreateTimer(5.0, Timer_CheckDoors, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:BossInfoTimer_Begin(Handle:timer, any:boss)
{
	BossInfoTimer[boss][0]=INVALID_HANDLE;
	BossInfoTimer[boss][1]=CreateTimer(0.2, BossInfoTimer_ShowInfo, boss, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:BossInfoTimer_ShowInfo(Handle:timer, any:boss)
{
	if(!IsValidClient(Boss[boss]))
 	{
 		BossInfoTimer[boss][1]=INVALID_HANDLE;
 		return Plugin_Stop;
 	}

	if(bossHasReloadAbility[boss])
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		SetGlobalTransTarget(Boss[boss]);
		if(bossHasRightMouseAbility[boss])
		{
			FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t\n%t", "ff2_buttons_reload", "ff2_buttons_rmb");
		}
		else
		{
			FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t", "ff2_buttons_reload");
		}
	}
	else if(bossHasRightMouseAbility[boss])
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		SetGlobalTransTarget(Boss[boss]);
		FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t", "ff2_buttons_rmb");
	}
	else
	{
		BossInfoTimer[boss][1]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_CheckDoors(Handle:timer)
{
	if(!checkDoors)
	{
		doorCheckTimer=INVALID_HANDLE;
		return Plugin_Stop;
	}

	if((!Enabled && CheckRoundState()!=-1) || (Enabled && CheckRoundState()!=1))
	{
		return Plugin_Continue;
	}

	int entity=-1;
	while((entity=FindEntityByClassname2(entity, "func_door"))!=-1)
	{
		AcceptEntityInput(entity, "Open");
		AcceptEntityInput(entity, "Unlock");
	}
	return Plugin_Continue;
}

public CheckArena()
{
	if(PointType)
	{
		SetArenaCapEnableTime(float(45+PointDelay*(playing-1)));
	}
	else
	{
		SetArenaCapEnableTime(0.0);
		SetControlPoint(false);
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundCount++;
	HasCompanions=false;

	if(!Enabled)
	{
		return Plugin_Continue;
	}
 	// mp_friendlyfire
	SetConVarBool(FindConVar("mp_friendlyfire"), true, _, false);

	DEVmode=false;
	FF2ServerFlag=0;
	DPSTick=0;

	CheckedFirstRound=true;
	executed=false;
	executed2=false;
	bool bossWin=false;
	decl String:sound[PLATFORM_MAX_PATH];
	if((GetEventInt(event, "team")==BossTeam))
	{
		bossWin=true;
		if(RandomSound("sound_win", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, Boss[0], _, _, false);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, Boss[0], _, _, false);
		}
	}

	StopMusic();
	DrawGameTimer=INVALID_HANDLE;
	CloseLoadMusicTimer();

	bool isBossAlive;
	for(int boss; boss<=MaxClients; boss++)
	{
		selectedBGM[boss]=0;
		playingCustomBossBGM[boss]=false;
		playingCustomBGM[boss]=false;
		if(IsValidClient(Boss[boss]))
		{
			SetClientGlow(Boss[boss], 0.0, 0.0);
			SDKUnhook(boss, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal
			if(IsPlayerAlive(Boss[boss]))
			{
				isBossAlive=true;
			}

			for(int slot=0; slot<9; slot++)
			{
				BossCharge[boss][slot]=0.0;
				BossAbilityDuration[boss][slot]=0.0;
				BossAbilityCooldown[boss][slot]=0.0;
				BossAbilityDurationMax[boss][slot]=0.0;
				BossAbilityCooldownMax[boss][slot]=0.0;
			}
			bossHasReloadAbility[boss]=false;
			bossHasRightMouseAbility[boss]=false;
		}
		else if(IsValidClient(boss))  //Boss here is actually a client index
		{
			SetClientGlow(boss, 0.0, 0.0);
			shield[boss]=0;
			detonations[boss]=0;
			GoombaCount[boss]=0;
			Marketed[boss]=0;
			Stabbed[boss]=0;
		}

		for(int timer; timer<=1; timer++)
		{
			if(BossInfoTimer[boss][timer]!=INVALID_HANDLE)
			{
				KillTimer(BossInfoTimer[boss][timer]);
				BossInfoTimer[boss][timer]=INVALID_HANDLE;
			}
		}
	}

	int boss;
	if(isBossAlive)
	{
		char text[128];  //Do not decl this
	 //	decl String:bossName[64], String:lives[8];
		for(int target; target<=MaxClients; target++)
		{
			/*
			if(IsBoss(target))
			{
				boss=Boss[target];
				KvRewind(BossKV[Special[boss]]);
				KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName), "=Failed name=");
				BossLives[boss]>1 ? Format(lives, sizeof(lives), "x%i", BossLives[boss]) : strcopy(lives, 2, "");
				Format(text, sizeof(text), "%s\n%t", text, "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
				CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
			}
			*/
			// TODO: 보스 이름을 광역변수로 정해둘것.
		}

		SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
		for(int client; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				FF2_ShowHudText(client, -1, "%s", text);
			}
		}

		if(!bossWin && RandomSound("sound_fail", sound, sizeof(sound), boss))
		{
			EmitSoundToAll(sound);
			EmitSoundToAll(sound);
		}
	}

	int top[3];
	Damage[0]=0;

	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || Damage[client]<=0 || IsBoss(client))
		{
			continue;
		}

		if(Damage[client]>=Damage[top[0]])
		{
			top[2]=top[1];
			top[1]=top[0];
			top[0]=client;
		}
		else if(Damage[client]>=Damage[top[1]])
		{
			top[2]=top[1];
			top[1]=client;
		}
		else if(Damage[client]>=Damage[top[2]])
		{
			top[2]=client;
		}
	}

	if(Damage[top[0]]>9000)
	{
		CreateTimer(1.0, Timer_NineThousand, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	decl String:leaders[3][32];
	for(int i; i<=2; i++)
	{
		if(IsValidClient(top[i]))
		{
			GetClientName(top[i], leaders[i], 32);
		}
		else
		{
			Format(leaders[i], 32, "---");
			top[i]=0;
		}
	}

	SetHudTextParams(-1.0, 0.3, 10.0, 255, 255, 255, 255);
	PrintCenterTextAll("");

	char temp[10];
	Format(temp, sizeof(temp), "%.1f", HighestDPS);

	char text[128];  //Do not decl this
	for(int client; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			SetGlobalTransTarget(client);
			//TODO:  Clear HUD text here
			if(IsBoss(client))
			{
				FF2_ShowSyncHudText(client, infoHUD, "%s\n%t\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t\n\n%t", text, "top_3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], (bossWin ? "boss_win" : "boss_lose"), "notice_DPS", HighestDPSClient, temp);
			}
			else
			{
				FF2_ShowSyncHudText(client, infoHUD, "%s\n%t\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t", text, "top_3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], "notice_DPS", HighestDPSClient, temp);
			}
		}
	}

	CreateTimer(3.0, Timer_CalcQueuePoints, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar();
	return Plugin_Continue;
}

public Action:OnBroadcast(Handle:event, const String:name[], bool:dontBroadcast)
{
    decl String:sound[PLATFORM_MAX_PATH];
    GetEventString(event, "sound", sound, sizeof(sound));
    if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action:Timer_NineThousand(Handle:timer)
{
	EmitSoundToAll("saxton_hale/9000.wav", _, _, _, _, _, _, _, _, _, false);
	EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, SNDCHAN_VOICE, _, _, _, _, _, _, _, false);
	EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, SNDCHAN_VOICE, _, _, _, _, _, _, _, false);
	return Plugin_Continue;
}

public Action Timer_CalcQueuePoints(Handle timer)
{
	int damage;
	botqueuepoints+=5;
	int add_points[MAXPLAYERS+1];
	int add_points2[MAXPLAYERS+1];
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			damage=Damage[client];
			Handle event=CreateEvent("player_escort_score", true);
			SetEventInt(event, "player", client);

			int points;
			while(damage-600>0)
			{
				damage-=600;
				points++;
			}
			SetEventInt(event, "points", points);
			FireEvent(event);

			if(IsBoss(client))
			{
				if(IsFakeClient(client))
				{
					botqueuepoints=0;
				}
				else
				{
					int boss=GetBossIndex(client);
					if(boss == MainBoss)
					{
						add_points[client]=-GetClientQueuePoints(client);
						add_points2[client]=add_points[client];
					}
				}
			}
			else if(!IsFakeClient(client) && (GetClientTeam(client)>_:TFTeam_Spectator || SpecForceBoss))
			{
				add_points[client]=10;
				add_points2[client]=10;
			}
		}
	}

	Action action;
	Call_StartForward(OnAddQueuePoints);
	Call_PushArrayEx(add_points2, MaxClients+1, SM_PARAM_COPYBACK);
	Call_Finish(action);
	switch(action)
	{
		case Plugin_Stop, Plugin_Handled:
		{
			return;
		}
		case Plugin_Changed:
		{
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					if(add_points2[client]>0)
					{
						CPrintToChat(client, "{olive}[FF2]{default} %t", "add_points", add_points2[client]);
					}
					SetClientQueuePoints(client, GetClientQueuePoints(client)+add_points2[client]);
				}
			}
		}
		default:
		{
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					if(add_points[client]>0)
					{
						CPrintToChat(client, "{olive}[FF2]{default} %t", "add_points", add_points[client]);
					}
					SetClientQueuePoints(client, GetClientQueuePoints(client)+add_points[client]);
				}
			}
		}
	}
}

public Action:StartResponseTimer(Handle:timer)
{
	decl String:sound[PLATFORM_MAX_PATH];
	if(RandomSound("sound_begin", sound, sizeof(sound)))
	{
		EmitSoundToAll(sound);
		EmitSoundToAll(sound);
	}
	return Plugin_Continue;
}

public Action:StartBossTimer(Handle:timer)
{
	CreateTimer(0.1, Timer_Move, _, TIMER_FLAG_NO_MAPCHANGE);
	bool isBossAlive;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
		{
			isBossAlive=true;
			SetEntityMoveType(Boss[boss], MOVETYPE_NONE);
		}
	}

	if(!isBossAlive)
	{
		return Plugin_Continue;
	}

	playing=0;
	for(int client=1; client<=MaxClients; client++)
	{
		IsBossDoing[client] = false;
		if(IsValidClient(client) && !IsBoss(client) && IsPlayerAlive(client))
		{
			playing++;
			CreateTimer(0.15, MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);  //TODO:  Is this needed?
		}
	}

	AFKTime = GetGameTime() + 8.0;

	CreateTimer(0.05, BossTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, CheckAlivePlayers, 0, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, StartRound, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.0, Timer_PrepareBGM, 0, TIMER_FLAG_NO_MAPCHANGE);

	if(!PointType)
	{
		SetControlPoint(false);
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(CheckRoundState() != 1) return Plugin_Continue;

	if(IsBoss(client) && AFKTime > GetGameTime())
	{
		if(buttons > 0)
		{
			IsBossDoing[client] = true;
		}
	}

	return Plugin_Continue;
}

public Action:Timer_PrepareBGM(Handle:timer, any:userid)
{
	int client=GetClientOfUserId(userid);
	if(CheckRoundState()!=1 || (!client && MapHasMusic()) || (!client && userid)) // || (!client && userid)
	{
		return Plugin_Stop;
	}

	if(!client)
	{
		for(client=MaxClients;client;client--)
		{
			if(IsValidClient(client))
			{
				// if(CheckRoundState()==1 && (!currentBGM[client][0] || !StrEqual(currentBGM[client], "ff2_stop_music", false)))
				// if(CheckRoundState()==1 && playBGM[client] && !currentBGM[client][0])
				if(playBGM[client])
				{
					StopMusic(client);
					PlayBGM(client);
				}
				else if(MusicTimer[client]!=INVALID_HANDLE)
				{
					KillTimer(MusicTimer[client]);
					MusicTimer[client]=INVALID_HANDLE;
				}
				continue;
			}

			if(MusicTimer[client]!=INVALID_HANDLE)
			{
				KillTimer(MusicTimer[client]);
				MusicTimer[client]=INVALID_HANDLE;
			}
		}
	}
	else
	{
		// if(CheckRoundState()==1 && (!currentBGM[client][0] || !StrEqual(currentBGM[client], "ff2_stop_music", false)))
		// if(CheckRoundState()==1 && playBGM[client] && !currentBGM[client][0])
		if(playBGM[client])
		{
			StopMusic(client);
			PlayBGM(client);
		}
		else if(MusicTimer[client]!=INVALID_HANDLE)
		{
			KillTimer(MusicTimer[client]);
			MusicTimer[client]=INVALID_HANDLE;
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

StartMusic(client=0)
{
	if(client<=0)  //Start music for all clients
	{
		StopMusic();
		for(int target; target<=MaxClients; target++)
 		{
 			playBGM[target]=true; // This includes the 0th index

			if(target > 0 && IsClientInGame(target))
				CreateTimer(0.0, Timer_PrepareBGM, GetClientUserId(target), TIMER_FLAG_NO_MAPCHANGE);
 		}
	}
	else
	{
		StopMusic(client);
		playBGM[client]=true;
		CreateTimer(0.0, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

StopMusic(client=0, bool:permanent=false)
{
	if(client<=0)  //Stop music for all clients
	{
		if(permanent)
 		{
 			playBGM[0]=false;
 		}

		for(client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				StopSound(client, SNDCHAN_AUTO, currentBGM[client]);
				StopSound(client, SNDCHAN_AUTO, currentBGM[client]);
			}
			if(MusicTimer[client]!=INVALID_HANDLE)
			{
				KillTimer(MusicTimer[client]);
				MusicTimer[client]=INVALID_HANDLE;
			}
			//if(!StrEqual(currentBGM[client], "ff2_stop_music"))
			// strcopy(currentBGM[client], PLATFORM_MAX_PATH, !permanent ? "" : "ff2_stop_music");
			strcopy(currentBGM[client], PLATFORM_MAX_PATH, "");
			if(permanent)
			{
				playBGM[client]=false;
			}
		}
	}
	else
	{
		StopSound(client, SNDCHAN_AUTO, currentBGM[client]);
		StopSound(client, SNDCHAN_AUTO, currentBGM[client]);

		if(MusicTimer[client]!=INVALID_HANDLE)
		{
			KillTimer(MusicTimer[client]);
			MusicTimer[client]=INVALID_HANDLE;
		}
/*		if(!StrEqual(currentBGM[client], "ff2_stop_music"))
			strcopy(currentBGM[client], PLATFORM_MAX_PATH, !permanent ? "" : "ff2_stop_music");
*/
		strcopy(currentBGM[client], PLATFORM_MAX_PATH, "");
		if(permanent)
		{
			playBGM[client]=false;
		}
	}
}

PlayBGM(client)
{
	Handle musicKv;
	bool selected = playingCustomBossBGM[client] || playingCustomBGM[client];

	if(selected && LoadedMusicData)
		musicKv=CloneHandle(LoadedMusicData);
	else
		musicKv=CloneHandle(BossKV[Special[0]]);

	KvRewind(musicKv);
	if((!selected &&
		(((FF2_GetGameState() == Game_SpecialLastManStanding && KvJumpToKey(musicKv, "sound_special_bgm")) || (BossDiff[MainBoss] >= 5 && KvJumpToKey(musicKv, "sound_hell_bgm"))))
	|| KvJumpToKey(musicKv, "sound_bgm"))
	)
	{
		// char keyName[80];
		// KvGetSectionName(musicKv, keyName, sizeof(keyName));
		// Debug("key: %s", keyName);

		// Debug("%N", client);

		char music[PLATFORM_MAX_PATH];
		char artist[80];
		char name[100];
		bool notice=true;

		int maxIndex;
		int index;
		do
		{
			maxIndex++;
			Format(music, 10, "time%i", maxIndex);
		}
		while(KvGetFloat(musicKv, music)>1);

		if(!client)
		{
			index = GetRandomInt(1, maxIndex-1);
		}
		else if(!selected)
		{
			char code[100];
			int maxCount=0;
			int[] indexArray = new int[maxIndex];

			for(int count=1; count<maxIndex; count++)
			{
				Format(music, 10, "path%i", count);
				KvGetString(musicKv, music, music, sizeof(music));

				GetSoundCode(music, code, sizeof(code));

				if(CheckSoundException(client, SOUNDEXCEPT_MUSIC, code))
				{
					indexArray[maxCount++] = count;
				}
				else
				{
					Debug("%N: %s is muted.", client, code);
				}
			}

			if(maxCount > 0)
				index = indexArray[GetRandomInt(0, maxCount-1)];
			else
				return;
		}
		else if(selected)
		{
			index = selectedBGM[client];
		}

		Format(music, 10, "time%i", index);
		float time = KvGetFloat(musicKv, music);
		float time2 = time;

		Format(music, 10, "volume%i", index);
		float volume = KvGetFloat(musicKv, music, 1.0);
		float volume2 = volume;

		char artist2[80];
		Format(artist, sizeof(artist), "artist%i", index);
		KvGetString(musicKv, artist, artist2, sizeof(artist2));
		KvGetString(musicKv, artist, artist, sizeof(artist));


		char name2[100];
		Format(name, sizeof(name), "name%i", index);
		KvGetString(musicKv, name, name2, sizeof(name2));
		KvGetString(musicKv, name, name, sizeof(name));

		Format(music, 10, "path%i", index);
		KvGetString(musicKv, music, music, sizeof(music));
		char temp[PLATFORM_MAX_PATH];

		Action action;
		Call_StartForward(OnMusic);
		bool notice2 = notice;
		strcopy(temp, sizeof(temp), music);
		Call_PushStringEx(temp, sizeof(temp), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushFloatRef(time2);
		Call_PushFloatRef(volume2);
		Call_PushStringEx(artist2, sizeof(artist2), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushStringEx(name2, sizeof(name2), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCell(notice2);
		Call_PushCell(client);
		Call_PushCell(selected ? 1 : 0);
		Call_Finish(action);

		switch(action)
		{
			case Plugin_Stop, Plugin_Handled:
			{
				return;
			}
			case Plugin_Changed:
			{
				if(!(FF2ServerFlag & FF2SERVERFLAG_UNCHANGE_BGM_SERVER))
				{
					strcopy(music, sizeof(music), temp);
					strcopy(artist, sizeof(artist), artist2);
					strcopy(name, sizeof(name), name2);
					notice = notice2;
					time = time2;
					volume = volume2;
				}
			}
		}

		Format(temp, sizeof(temp), "sound/%s", music);
		if(FileExists(temp, true))
		{
			// Debug("Now checking %N's SoundException..", client);
			if(CheckSoundException(client, SOUNDEXCEPT_MUSIC))
			{
				strcopy(currentBGM[client], PLATFORM_MAX_PATH, music);

				if(!IsSoundPrecached(music))
					PrecacheSound(music);
				EmitSoundToClient(client, music, _, _, _, _, volume);
				if(time>1)
				{
					MusicTimer[client] = CreateTimer(time, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				}
				if(notice) 	CPrintToChat(client, "{olive}[FF2]{default} Now Playing: {green}%s{default} - {orange}%s{default}", artist, name);
			}
		}
		else
		{
			decl String:bossName[64];
			KvRewind(musicKv);
			KvGetString(musicKv, "filename", bossName, sizeof(bossName));
			PrintToServer("[FF2 Bosses] Character %s is missing BGM file '%s'!", bossName, music);
		}
		CloseHandle(musicKv);
	}
}

stock EmitSoundToAllExcept(exceptiontype=SOUNDEXCEPT_MUSIC, const String:sample[], entity=SOUND_FROM_PLAYER, channel=SNDCHAN_AUTO, level=SNDLEVEL_NORMAL, flags=SND_NOFLAGS, Float:volume=SNDVOL_NORMAL, pitch=SNDPITCH_NORMAL, speakerentity=-1, const Float:origin[3]=NULL_VECTOR, const Float:dir[3]=NULL_VECTOR, bool:updatePos=true, Float:soundtime=0.0)
{
	int clients[MAXPLAYERS+1], total;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsClientInGame(client))
		{
			if(CheckSoundException(client, exceptiontype))
			{
				clients[total++]=client;
			}
		}
	}

	if(!total)
	{
		return;
	}

	EmitSound(clients, total, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}

stock bool:CheckSoundException(client, soundException, String:code[]="")
{
	if(!IsValidClient(client))
	{
		return false;
	}

	if(IsFakeClient(client) || !AreClientCookiesCached(client))
	{
		return true;
	}

	char cookies[24];
	char cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	if(soundException==SOUNDEXCEPT_VOICE)
	{
		return StringToInt(cookieValues[2])==1;
	}
	else if(code[0] != '\0')
	{
		char cookieName[PLATFORM_MAX_PATH];
		Format(cookieName, sizeof(cookieName), "ff2mc_%s", code);
		Handle soundCookie = FindClientCookie(cookieName);
		if(soundCookie == INVALID_HANDLE)
		{
			soundCookie = RegClientCookie(cookieName, "", CookieAccess_Protected);
		}

		GetClientCookie(client, soundCookie, cookies, sizeof(cookies));

		return StringToInt(cookies)!=1;
	}

	return StringToInt(cookieValues[1])==1;
}

SetClientSoundOptions(client, soundException, bool:enable, String:code[]="")
{
	if(!IsValidClient(client) || IsFakeClient(client) || !AreClientCookiesCached(client))
	{
		return;
	}

	decl String:cookies[24];
	decl String:cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	if(soundException==SOUNDEXCEPT_VOICE)
	{
		if(enable)
		{
			cookieValues[2][0]='1';
		}
		else
		{
			cookieValues[2][0]='0';
		}
	}
	else
	{
		if(enable)
		{
			cookieValues[1][0]='1';
		}
		else
		{
			cookieValues[1][0]='0';
		}

		if(code[0] != '\0')
		{
			char cookieName[PLATFORM_MAX_PATH];
			Format(cookieName, sizeof(cookieName), "ff2mc_%s", code);
			Handle soundCookie = FindClientCookie(cookieName);
			if(soundCookie == INVALID_HANDLE)
			{
				soundCookie = RegClientCookie(cookieName, "", CookieAccess_Protected);
			}

			SetClientCookie(client, soundCookie, enable ? "0" : "1");

			return;
		}
	}
	Format(cookies, sizeof(cookies), "%s %s %s %s %s %s %s %s", cookieValues[0], cookieValues[1], cookieValues[2], cookieValues[3], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
	SetClientCookie(client, FF2Cookies, cookies);
}

public Action:Timer_Move(Handle:timer)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client))
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
}

public Action:StartRound(Handle:timer)
{
	CreateTimer(10.0, Timer_NextBossPanel, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar();
	return Plugin_Handled;
}

public Action:Timer_NextBossPanel(Handle:timer)
{
	int clients;
	bool added[MAXPLAYERS+1];
	while(clients<3)  //TODO: Make this configurable?
	{
		int client=GetClientWithMostQueuePoints(added);
		if(!IsValidClient(client))  //No more players left on the server
		{
			break;
		}

		if(!IsBoss(client))
		{
			CPrintToChat(client, "{olive}[FF2]{default} %t", "to0_near");  //"You will become the Boss soon. Type {olive}/ff2next{default} to make sure."
			clients++;
		}
		added[client]=true;
	}
}

public Action:MessageTimer(Handle:timer)
{
	if(CheckRoundState())
	{
		return Plugin_Continue;
	}

	if(checkDoors)
	{
		int entity=-1;
		while((entity=FindEntityByClassname2(entity, "func_door"))!=-1)
		{
			AcceptEntityInput(entity, "Open");
			AcceptEntityInput(entity, "Unlock");
		}

		if(doorCheckTimer==INVALID_HANDLE)
		{
			doorCheckTimer=CreateTimer(5.0, Timer_CheckDoors, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
	char text[512];  //Do not decl this
	decl String:textChat[512];
	decl String:lives[8];
	decl String:name[64];
	// decl String:teamname[80];
	decl String:specialApproach[64];

/*	KvRewind(BossKV[Special[MainBoss]]);
	KvGetString(BossKV[Special[MainBoss]], "team_name", name, sizeof(name), "");

	if(teamname[0] != '\0')
	{
		int bosseshp=0;
		int boss;
		hasTeamname=true;

		for(int client=1; client<=MaxClients; client++)
		{
			if((boss=GetBossIndex(client)) != -1) bosseshp+=BossHealth[boss];
		}
		Format(text, sizeof(text), "%t", "ff2_start_team", Boss[boss], teamname, bosseshp);
	}
*/

	/*if(HasCompanions)
	{
		int collectHp=0;
		// int mainbossClient;

		KvRewind(BossKV[Special[MainBoss]]);
		KvGetString(BossKV[Special[MainBoss]], "team_name", teamname, sizeof(teamname), "=Failed name=");
		KvGetString(BossKV[Special[MainBoss]], "special_approach", specialApproach, sizeof(specialApproach), "");
		for(int client; client<=MaxClients; client++)
		{
			if(IsBoss(client))
			{
				collectHp+=BossHealth[GetBossIndex(client)];
			}
		}
		Format(text, sizeof(text), "%t", text, "ff2_start_team", Boss[MainBoss], teamname, collectHp, specialApproach);
		Format(textChat, sizeof(textChat), "{olive}[FF2]{default} %t!", "ff2_start_team", Boss[MainBoss], teamname, collectHp, specialApproach);
		CPrintToChatAll("%s", textChat);
	}*/
//	else
	for(int client; client<=MaxClients; client++)
	{
		if(IsBoss(client))
		{
			int boss=Boss[client];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", name, sizeof(name), "=Failed name=");
			KvGetString(BossKV[Special[boss]], "special_approach", specialApproach, sizeof(specialApproach), "");

			if(BossLives[boss]>1)
			{
				Format(lives, sizeof(lives), "x%i", BossLives[boss]);
			}
			else
			{
				strcopy(lives, 2, "");
			}

			if(IsBossYou[client])
			{
				GetYouSpecialString(client, specialApproach, sizeof(specialApproach));
				Format(text, sizeof(text), "%s\n%t", text, "ff2_start_you", Boss[boss], BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives, specialApproach);
				Format(textChat, sizeof(textChat), "{olive}[FF2]{default} %t!", "ff2_start_chat_you", Boss[boss], BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
			}
			else
			{
				Format(text, sizeof(text), "%s\n%t", text, "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives, specialApproach);
				Format(textChat, sizeof(textChat), "{olive}[FF2]{default} %t!", "ff2_start_chat", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
			}

			ReplaceString(textChat, sizeof(textChat), "\n", "");  //Get rid of newlines
			// CPrintToChatAll("%s", textChat);
			CPrintToChatAll("%s", textChat);

			char diff[25];
			bool gotHard=BossDiff[boss]>1;

			if(gotHard)
			{
				GetDifficultyString(BossDiff[boss], diff, sizeof(diff));
				CPrintToChatAll("{olive}[FF2]{default} 이 보스는 난이도가 {green}%s{default}입니다!", diff);
			}
		}
	}



	for(int client; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			SetGlobalTransTarget(client);
			FF2_ShowSyncHudText(client, infoHUD, text);
		}
	}
	return Plugin_Continue;
}

public Action:MakeModelTimer(Handle:timer, any:client)
{
	if(IsValidClient(Boss[client]) && IsPlayerAlive(Boss[client]) && CheckRoundState()!=2)
	{
		decl String:model[PLATFORM_MAX_PATH];
		KvRewind(BossKV[Special[client]]);
		KvGetString(BossKV[Special[client]], "model", model, PLATFORM_MAX_PATH);
		SetVariantString(model);
		AcceptEntityInput(Boss[client], "SetCustomModel");
		SetEntProp(Boss[client], Prop_Send, "m_bUseClassAnimations", 1);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

EquipBoss(boss)
{
	int client=Boss[boss];
	DoOverlay(client, "");
	TF2_RemoveAllWeapons(client);
	decl String:key[10], String:classname[64], String:attributes[256];
	for(int i=1; ; i++)
	{
		KvRewind(BossKV[Special[boss]]);
		Format(key, sizeof(key), "weapon%i", i);
		if(KvJumpToKey(BossKV[Special[boss]], key))
		{
			KvGetString(BossKV[Special[boss]], "name", classname, sizeof(classname));
			KvGetString(BossKV[Special[boss]], "attributes", attributes, sizeof(attributes));

			if(attributes[0]!='\0')
			{
				Format(attributes, sizeof(attributes), "68 ; %i ; 259 ; 1.0 ; %s", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2 ,attributes);
					//68: +2 cap rate
					//2: x3.1 damage
			}
			else
			{
				Format(attributes, sizeof(attributes), "68 ; %i ; 2 ; 3.1 ; 259 ; 1.0", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2);
					//68: +2 cap rate
					//2: x3.1 damage
			}

			if(i == 1)
			{
				Format(attributes, sizeof(attributes), "%s ; 252 ; 0.5", attributes);
			}

			int index=KvGetNum(BossKV[Special[boss]], "index");
			int weapon=SpawnWeapon(client, classname, index, 101, GetRandomInt(0, 15), attributes);
			if(StrEqual(classname, "tf_weapon_builder", false) && index!=735)  //PDA, normal sapper
			{
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
			}
			else if(StrEqual(classname, "tf_weapon_sapper", false) || index==735)  //Sappers
			{
				SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
				SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
			}

			if(!KvGetNum(BossKV[Special[boss]], "show", 0))
			{
				SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 0.001);
			}
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		}
		else
		{
			break;
		}
	}

	KvGoBack(BossKV[Special[boss]]);
	TFClassType class = view_as<TFClassType>(KvGetNum(BossKV[Special[boss]], "class", 1));
	if(TF2_GetPlayerClass(client) != class)
	{
		TF2_SetPlayerClass(client, class, _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	}
}

public Action:MakeBoss(Handle:timer, any:boss)
{
	int client = Boss[boss];
	if(!IsValidClient(client) || CheckRoundState()==-1)
	{
		return Plugin_Continue;
	}

	if(!IsPlayerAlive(client))
	{
		if(!CheckRoundState())
		{
			TF2_RespawnPlayer(client);
		}
		else
		{
			return Plugin_Continue;
		}
	}

	Call_StartForward(OnPlayBoss);
	Call_PushCell(client);
	Call_PushCell(boss);
	Call_Finish();

	/*
	Handle testDeath=CreateEvent("player_death", true);
	SetEventInt(testDeath, "userid", GetClientUserId(client));
	SetEventBool(testDeath, "silent_kill", true);
	FireEvent(testDeath);
	TF2_RespawnPlayer(client);
	*/
	// FormulaBossHealth

	KvRewind(BossKV[Special[boss]]);

	if(GetClientTeam(client)!=BossTeam)
	{
		AssignTeam(client, BossTeam);
	}


	decl String:bossName[64];
	KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName));

	BossRageDamage[boss]=KvGetNum(BossKV[Special[boss]], "ragedamage", 1900);
	if(BossRageDamage[boss]<=0)
	{
		// KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName));
		PrintToServer("[FF2 Bosses] Warning: Boss %s's rage damage is 0 or below, setting to 1900", bossName);
		BossRageDamage[boss]=1900;
	}
/*
	BossLivesMax[boss]=KvGetNum(BossKV[Special[boss]], "lives", 1);
	if(BossLivesMax[boss]<=0)
	{
		// KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName));
		PrintToServer("[FF2 Bosses] Warning: Boss %s has an invalid amount of lives, setting to 1", bossName);
		BossLivesMax[boss]=1;
	}
*/
	BossDiff[boss] = GetClientDifficultyCookie(client);
	FormulaBossHealth(boss);

	if(StrEqual(bossName, "You", true) ||
	StrEqual(bossName, "당신", true))
	{
		IsBossYou[client] = true;
	}
	// BossLives[boss]=BossLivesMax[boss];
	// BossHealth[boss]=BossHealthMax[boss]*BossLivesMax[boss];
	// BossHealthLast[boss]=BossHealth[boss];
	KvGetString(BossKV[Special[boss]], "ability_name", BossRageName[boss], sizeof(BossRageName[]));
	KvGetString(BossKV[Special[boss]], "upgrade_ability_name", BossUpgradeRageName[boss], sizeof(BossUpgradeRageName[]));

	for(int slot=0; slot<8; slot++)
	{
	 	char durationItem[20];
		char cooltimeItem[20];

		if(slot == 0)
		{
			Format(durationItem, sizeof(durationItem), "ability_duration");
			Format(cooltimeItem, sizeof(cooltimeItem), "cooldown");
		}
		else
		{
			Format(durationItem, sizeof(durationItem), "ability_duration_slot%i", slot);
			Format(cooltimeItem, sizeof(cooltimeItem), "cooldown_slot%i", slot);
		}

		BossAbilityDurationMax[boss][slot] = KvGetFloat(BossKV[Special[boss]], durationItem, 5.0);
		BossAbilityCooldownMax[boss][slot] = KvGetFloat(BossKV[Special[boss]], cooltimeItem, 10.0);
	}

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	TF2_RemovePlayerDisguise(client);

	if(!IsBossYou[client])
		TF2_SetPlayerClass(client, TFClassType:KvGetNum(BossKV[Special[boss]], "class", 1), _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal

	switch(KvGetNum(BossKV[Special[boss]], "pickups", 0))  //Check if the boss is allowed to pickup health/ammo
	{
		case 1:
		{
			FF2flags[client]|=FF2FLAG_ALLOW_HEALTH_PICKUPS;
		}
		case 2:
		{
			FF2flags[client]|=FF2FLAG_ALLOW_AMMO_PICKUPS;
		}
		case 3:
		{
			FF2flags[client]|=FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS;
		}
	}
	if(IsBossYou[client])
	{
		FF2flags[client]|=FF2FLAG_NOTALLOW_RAGE;
		FF2flags[client]|=FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS;
	}

	CreateTimer(0.2, MakeModelTimer, boss, TIMER_FLAG_NO_MAPCHANGE);
	if(!IsVoteInProgress())
	{
		HelpPanelBoss();
	}

	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	int entity=-1;
	if(!IsBossYou[client])
	{
		while((entity=FindEntityByClassname2(entity, "tf_wear*"))!=-1)
		{
			if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
			{
				switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
				{
					case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:  //Action slot items				{
					{
						// NOOOOOOOOP
					}
					default:
					{
						TF2_RemoveWearable(client, entity);
					}
				}
			}
		}
	}

	if(!IsBossYou[client])
	{
		entity=-1;
		while((entity=FindEntityByClassname2(entity, "tf_powerup_bottle"))!=-1)
		{
			if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
			{
				TF2_RemoveWearable(client, entity);
			}
		}
	}

	if(!IsBossYou[client])
		EquipBoss(boss);

	KSpreeCount[boss]=0;
	BossCharge[boss][0]=0.0;
	BossMaxRageCharge[boss] = 100.0;


	// BossHealthMax[boss]=RoundFloat(float(BossHealth[boss])/float(BossLivesMax[boss]))+1; // TODO: wat.
	//

	if (boss == MainBoss) SetClientQueuePoints(client, 0);
	return Plugin_Continue;
}

void MakeClientToBoss(int boss)
{
	int client = Boss[boss];
	if(!IsValidClient(client) || CheckRoundState()==-1)
	{
		return;
	}

	if(!IsPlayerAlive(client))
	{
		TF2_RespawnPlayer(client);
	}

	Call_StartForward(OnPlayBoss);
	Call_PushCell(client);
	Call_PushCell(boss);
	Call_Finish();

	Debug("OnPlayBoss: %N %i", client, boss);

	KvRewind(BossKV[Special[boss]]);

	decl String:bossName[64];
	KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName));

	Debug("OnPlayBoss: %s", bossName);

	BossRageDamage[boss]=KvGetNum(BossKV[Special[boss]], "ragedamage", 1900);
	if(BossRageDamage[boss]<=0)
	{
		// KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName));
		PrintToServer("[FF2 Bosses] Warning: Boss %s's rage damage is 0 or below, setting to 1900", bossName);
		BossRageDamage[boss]=1900;
	}

	BossDiff[boss] = GetClientDifficultyCookie(client);
	FormulaBossHealth(boss);

	if(StrEqual(bossName, "You", true) ||
	StrEqual(bossName, "당신", true))
	{
		IsBossYou[client] = true;
	}
	// BossLives[boss]=BossLivesMax[boss];
	// BossHealth[boss]=BossHealthMax[boss]*BossLivesMax[boss];
	// BossHealthLast[boss]=BossHealth[boss];
	KvGetString(BossKV[Special[boss]], "ability_name", BossRageName[boss], sizeof(BossRageName[]));
	KvGetString(BossKV[Special[boss]], "upgrade_ability_name", BossUpgradeRageName[boss], sizeof(BossUpgradeRageName[]));

	for(int slot=0; slot<8; slot++)
	{
	 	char durationItem[20];
		char cooltimeItem[20];

		if(slot == 0)
		{
			Format(durationItem, sizeof(durationItem), "ability_duration");
			Format(cooltimeItem, sizeof(cooltimeItem), "cooldown");
		}
		else
		{
			Format(durationItem, sizeof(durationItem), "ability_duration_slot%i", slot);
			Format(cooltimeItem, sizeof(cooltimeItem), "cooldown_slot%i", slot);
		}

		BossAbilityDurationMax[boss][slot] = KvGetFloat(BossKV[Special[boss]], durationItem, 5.0);
		BossAbilityCooldownMax[boss][slot] = KvGetFloat(BossKV[Special[boss]], cooltimeItem, 10.0);
	}

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	TF2_RemovePlayerDisguise(client);

	if(!IsBossYou[client])
		TF2_SetPlayerClass(client, TFClassType:KvGetNum(BossKV[Special[boss]], "class", 1), _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal

	switch(KvGetNum(BossKV[Special[boss]], "pickups", 0))  //Check if the boss is allowed to pickup health/ammo
	{
		case 1:
		{
			FF2flags[client]|=FF2FLAG_ALLOW_HEALTH_PICKUPS;
		}
		case 2:
		{
			FF2flags[client]|=FF2FLAG_ALLOW_AMMO_PICKUPS;
		}
		case 3:
		{
			FF2flags[client]|=FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS;
		}
	}
	if(IsBossYou[client])
	{
		FF2flags[client]|=FF2FLAG_NOTALLOW_RAGE;
		FF2flags[client]|=FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS;
	}

	CreateTimer(0.2, MakeModelTimer, boss, TIMER_FLAG_NO_MAPCHANGE);
	if(!IsVoteInProgress())
	{
		HelpPanelBoss();
	}

	if(!IsPlayerAlive(client))
	{
		return;
	}

	int entity=-1;
	if(!IsBossYou[client])
	{
		while((entity=FindEntityByClassname2(entity, "tf_wear*"))!=-1)
		{
			if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
			{
				switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
				{
					case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:  //Action slot items				{
					{
						// NOOOOOOOOP
					}
					default:
					{
						TF2_RemoveWearable(client, entity);
					}
				}
			}
		}
	}

	if(!IsBossYou[client])
	{
		entity=-1;
		while((entity=FindEntityByClassname2(entity, "tf_powerup_bottle"))!=-1)
		{
			if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
			{
				TF2_RemoveWearable(client, entity);
			}
		}
	}

	if(!IsBossYou[client])
		EquipBoss(boss);

	KSpreeCount[boss]=0;
	BossCharge[boss][0]=0.0;
	BossMaxRageCharge[boss] = 100.0;
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:item)
{
	if(!Enabled /*|| item!=INVALID_HANDLE*/)
	{
		return Plugin_Continue;
	}

	// Debug("TF2Items_OnGiveNamedItem: %N", client);
	switch(iItemDefinitionIndex)
	{
		case 38, 457:  //Axtinguisher, Postal Pummeler
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "", true);
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 15, 202, 298:
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "87 ; 0.40", true);
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}


/*		case 45:
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1", true);
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
*/
		case 39, 351, 1081:  //Flaregun, Detonator, Festive Flaregun
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "25 ; 0.5 ; 58 ; 3.2 ; 144 ; 1.0 ; 207 ; 1.33", true);
				//25: -50% ammo
				//58: 220% self damage force
				//144: NOPE
				//207: +33% damage to self
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 40, 1146:  //Backburner, Festive Backburner
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "165 ; 1.0");
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 224:  //L'etranger
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.8 ; 166 ; -8 ; 85 ; 0.5 ; 157 ; 1.0 ; 253 ; 1.0");
				//85: +50% time needed to regen cloak
				//157: +1 second needed to fully disguise
				//253: +1 second needed to fully cloak

				/*
				case 224:  // 이방인
				{
					Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.8 ; 166 ; 8 ; 83 ; 0.6");
						//179: Crit instead of mini-critting
					if(itemOverride!=INVALID_HANDLE)
					{
						item=itemOverride;
						return Plugin_Changed;
					}
				}
				*/
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 239, 1084, 1100:  //GRU, Festive GRU, Bread Bite
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.5 ; 107 ; 1.5 ; 128 ; 1 ; 772 ; 1.5", true);
				//1: -50% damage
				//107: +50% move speed
				//128: Only when weapon is active
				//191: -7 health/second
				//772: Holsters 50% slower
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 56, 1005, 1092:  //Huntsman, Festive Huntsman, Fortified Compound
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.5 ; 76 ; 2");
				//2: +50% damage
				//76: +100% ammo
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		/*case 132, 266, 482:  //Eyelander, HHHH, Nessie's Nine Iron - commented out because
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "202 ; 0.5 ; 125 ; -15", true);
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}*/
		case 265:  //Stickybomb Jumper
		{
			Handle itemOverride=PrepareItemHandle(item, _, 265, "89 ; 0.2 ; 96 ; 1.6 ; 120 ; 99999.0 ; 3 ; 1.0 ; 89 ; -6.0 ; 280 ; 4 ; 477 ; 1.0");
				//241: No reload penalty
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 220:  //Shortstop
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "241 ; 1.0");
				//241: No reload penalty
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 226:  //Battalion's Backup
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "140 ; 10.0");
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 231:  //Darwin's Danger Shield
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 50");  //+50 health
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 305, 1079:  //Crusader's Crossbow, Festive Crusader's Crossbow
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.2 ; 17 ; 0.15");
				//2: +20% damage
				//17: +15% uber on hit
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 331:  //Fists of Steel
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "205 ; 0.8 ; 206 ; 2.0 ; 772 ; 2.0", true);
				//205: -80% damage from ranged while active
				//206: +100% damage from melee while active
				//772: Holsters 100% slower
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 415:  //Reserve Shooter
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.1 ; 3 ; 0.5 ; 114 ; 1 ; 179 ; 1 ; 547 ; 0.6", true);
				//2: +10% damage bonus
				//3: -50% clip size
				//114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
				//179: Minicrits become crits
				//547: Deploys 40% faster
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 444:  //Mantreads
		{
			/*Handle itemOverride=PrepareItemHandle(item, _, _, "58 ; 1.5");
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}*/

			#if defined _tf2attributes_included
			if(tf2attributes)
			{
				TF2Attrib_SetByDefIndex(client, 58, 1.5);
			}
			#endif
		}
		case 648:  //Wrap Assassin
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "279 ; 3.0");
				//279: 2 ornaments
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 656:  //Holiday Punch
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "199 ; 0 ; 547 ; 0 ; 358 ; 0 ; 362 ; 0 ; 363 ; 0 ; 369 ; 0", true);
				//199: Holsters 100% faster
				//547: Deploys 100% faster
				//Other attributes: Because TF2Items doesn't feel like stripping the Holiday Punch's attributes for some reason
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 772:  //Baby Face's Blaster
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.25 ; 109 ; 0.5 ; 125 ; -25 ; 394 ; 0.85 ; 418 ; 1 ; 419 ; 100 ; 532 ; 0.5 ; 651 ; 0.5 ; 709 ; 1", true);
				//2: +25% damage bonus
				//109: -50% health from packs on wearer
				//125: -25 max health
				//394: 15% firing speed bonus hidden
				//418: Build hype for faster speed
				//419: Hype resets on jump
				//532: Hype decays
				//651: Fire rate increases as health decreases
				//709: Weapon spread increases as health decreases
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 1103:  //Back Scatter
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "179 ; 1");
				//179: Crit instead of mini-critting
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		case 460:  // 집행자
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.3 ; 166 ; -20");
				//179: Crit instead of mini-critting
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
	}

	if(TF2_GetPlayerClass(client)==TFClass_Spy && (!StrContains(classname, "tf_weapon_invis", false)))
	{
		Handle itemOverride;

		if(iItemDefinitionIndex == 59)
		{
			itemOverride = PrepareItemHandle(item, _, _, "729 ; 0.1 ; 50 ; 1.5");
		}
		else
		{
			itemOverride = PrepareItemHandle(item, _, _, "50 ; 0.8");
		}

		if(itemOverride!=INVALID_HANDLE)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}

	if(TF2_GetPlayerClass(client)==TFClass_Soldier && (!StrContains(classname, "tf_weapon_rocketlauncher", false)))
	{
		Handle itemOverride;
		if(iItemDefinitionIndex == 127)  //Direct Hit
		{
			itemOverride=PrepareItemHandle(item, _, _, "114 ; 1 ; 179 ; 1.0");
				//114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
				//179: Mini-crits become crits
		}
		else if(iItemDefinitionIndex == 237)
		{
			itemOverride=PrepareItemHandle(item, _, 237, "114 ; 1 ; 5 ; 1.8 ; 96 ; 1.8 ; 3 ; 0.25");
		}
		else if(iItemDefinitionIndex == 228 ||
			iItemDefinitionIndex == 1104 ||
			iItemDefinitionIndex == 441 ||
			iItemDefinitionIndex == 414 ||
			iItemDefinitionIndex == 1085 ||
			iItemDefinitionIndex == 730
			)
		{
			itemOverride=PrepareItemHandle(item, _, _, "114 ; 1");
		}
		else
		{
			itemOverride=PrepareItemHandle(item, _, _, "114 ; 1 ; 488 ; 1");
				//114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
				//488: 로켓 특화.
		}

		if(itemOverride!=INVALID_HANDLE)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}

	if(TF2_GetPlayerClass(client)==TFClass_Soldier && !StrContains(classname, "tf_weapon_shotgun", false))
	{
		Handle itemOverride = PrepareItemHandle(item, _, _, "114 ; 1");
		// 114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
		// 488: 로켓 특화.

		if(itemOverride!=INVALID_HANDLE)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}

	if(!StrContains(classname, "tf_weapon_syringegun_medic"))  //Syringe guns
	{
		Handle itemOverride=PrepareItemHandle(item, _, _, "17 ; 0.05 ; 144 ; 1", true);
			//17: 5% uber on hit
			//144: Sets weapon mode?????
		if(itemOverride!=INVALID_HANDLE)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	else if(!StrContains(classname, "tf_weapon_medigun"))  //Mediguns
	{
		Handle itemOverride;
		switch(iItemDefinitionIndex)
		{
			case 35: // 크리츠크리그
			{
				itemOverride=PrepareItemHandle(item, _, _, "10 ; 1.2 ; 11 ; 1.25 ; 18 ; 1.0 ; 144 ; 2.0 ; 199 ; 0.75 ; 547 ; 0.75 ; 314 ; 10.0", true);
			}
			case 411: // 응급조치
			{
				itemOverride=PrepareItemHandle(item, _, _, "10 ; 1.35 ; 11 ; 0.5 ; 144 ; 2.0 ; 199 ; 0.75 ; 231 ; 2 ; 547 ; 0.75 ; 314 ; 8.0", true);
			}
		  	default:
		  	{
			  itemOverride=PrepareItemHandle(item, _, _, "10 ; 1.6 ; 11 ; 1.5 ; 13 ; 2.0 ; 144 ; 2.0", true);
		  	}
		}

		if(itemOverride!=INVALID_HANDLE)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}

	if(!StrContains(classname, "tf_weapon_pda_engineer_build"))
	{
		Handle itemOverride;
		// 276: 양방향 텔레포터
		// 345: 디스펜서 범위

		switch(iItemDefinitionIndex)
		{
			case 142:
			{
				itemOverride=PrepareItemHandle(item, _, _, "124 ; 1 ; 351 ; 1", true);
			}

			default:
			{
				itemOverride=PrepareItemHandle(item, _, _, "276 ; 1 ; 345 ; 4", true);
			}
		}


		// 124: 미니 센트리
		// 351: 일회용 센트리 하나.
		if(itemOverride!=INVALID_HANDLE)
		{
			item=itemOverride;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:Timer_NoHonorBound(Handle:timer, any:userid)
{
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		int melee=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		int index=((IsValidEntity(melee) && melee>MaxClients) ? GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex") : -1);
		int weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		char classname[64];
		if(IsValidEntity(weapon))
		{
			GetEntityClassname(weapon, classname, sizeof(classname));
		}
		if(index==357 && weapon==melee && !strcmp(classname, "tf_weapon_katana", false))
		{
			SetEntProp(melee, Prop_Send, "m_bIsBloody", 1);
			if(GetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy")<1)
			{
				SetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
			}
		}
	}
}

stock Handle:PrepareItemHandle(Handle:item, String:name[]="", index=-1, const String:att[]="", bool:dontPreserve=false)
{
	static Handle:weapon;
	int addattribs;

	char weaponAttribsArray[32][32];
	int attribCount=ExplodeString(att, ";", weaponAttribsArray, 32, 32);

	if(attribCount % 2)
	{
		--attribCount;
	}

	int flags=OVERRIDE_ATTRIBUTES;
	if(!dontPreserve)
	{
		flags|=PRESERVE_ATTRIBUTES;
	}

	if(weapon==INVALID_HANDLE)
	{
		weapon=TF2Items_CreateItem(flags);
	}
	else
	{
		TF2Items_SetFlags(weapon, flags);
	}
	//Handle weapon=TF2Items_CreateItem(flags);  //INVALID_HANDLE;  Going to uncomment this since this is what Randomizer does

	if(item!=INVALID_HANDLE)
	{
		addattribs=TF2Items_GetNumAttributes(item);
		if(addattribs>0)
		{
			for(int i; i<2*addattribs; i+=2)
			{
				bool dontAdd=false;
				int attribIndex=TF2Items_GetAttributeId(item, i);
				for(int z; z<attribCount+i; z+=2)
				{
					if(StringToInt(weaponAttribsArray[z])==attribIndex)
					{
						dontAdd=true;
						break;
					}
				}

				if(!dontAdd)
				{
					IntToString(attribIndex, weaponAttribsArray[i+attribCount], 32);
					FloatToString(TF2Items_GetAttributeValue(item, i), weaponAttribsArray[i+1+attribCount], 32);
				}
			}
			attribCount+=2*addattribs;
		}

		if(weapon!=item)  //FlaminSarge: Item might be equal to weapon, so closing item's handle would also close weapon's
		{
			CloseHandle(item);  //probably returns false but whatever (rswallen-apparently not)
		}
	}

	if(name[0]!='\0')
	{
		flags|=OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(weapon, name);
	}

	if(index!=-1)
	{
		flags|=OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(weapon, index);
	}

	if(attribCount>0)
	{
		TF2Items_SetNumAttributes(weapon, attribCount/2);
		int i2;
		for(int i; i<attribCount && i2<16; i+=2)
		{
			int attrib=StringToInt(weaponAttribsArray[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", weaponAttribsArray[i], weaponAttribsArray[i+1]);
				CloseHandle(weapon);
				return INVALID_HANDLE;
			}

			TF2Items_SetAttribute(weapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}
	TF2Items_SetFlags(weapon, flags);
	return weapon;
}

public Action:MakeNotBoss(Handle:timer, any:userid)
{
	int client=GetClientOfUserId(userid);
	if(!IsValidClient(client) || !IsPlayerAlive(client) || CheckRoundState()==2 || IsBoss(client) || (FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		return Plugin_Continue;
	}
/*
	if(!IsVoteInProgress() && GetClientBossInfoCookie(client) && !(FF2flags[client] & FF2FLAG_CLASSHELPED))
	{

	}
*/

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);  //This really shouldn't be needed but I've been noticing players who still have glow

	SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client)); //Temporary: Reset health to avoid an overheal bug
	if(GetClientTeam(client)==BossTeam)
	{
		AssignTeam(client, OtherTeam);
	}

	CreateTimer(0.1, CheckItems, userid, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:CheckItems(Handle:timer, any:userid)
{
	int client=GetClientOfUserId(userid);
	if(!IsValidClient(client) || !IsPlayerAlive(client) || CheckRoundState()==2 || (IsBoss(client) && !IsBossYou[client]) || (FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		return Plugin_Continue;
	}

	SetEntityRenderColor(client, 255, 255, 255, 255);
	shield[client]=0;
	int index=-1;
	int civilianCheck[MAXPLAYERS+1];

	//Cloak and Dagger is NEVER allowed, even in Medieval mode
	int weapon=GetPlayerWeaponSlot(client, 4);
	if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==60)  //Cloak and Dagger
	{
		TF2_RemoveWeaponSlot(client, 4);
		SpawnWeapon(client, "tf_weapon_invis", 30, 1, 0, "");
	}

	if(bMedieval)
	{
		return Plugin_Continue;
	}

	weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(weapon))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch(index)
		{
			case 41:  //Natascha
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				SpawnWeapon(client, "tf_weapon_minigun", 15, 1, 0, "");
			}
			/*
			case 237:  //Rocket Jumper
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				SpawnWeapon(client, "tf_weapon_rocketlauncher", 237, 1, 0, "114 ; 1 ; 2 ; 1.45 ; 5 ; 1.4 ; 96 ; 1.4 ; 99 ; 1.8 ; 3 ; 0.5");
					//114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
				FF2_SetAmmo(client, weapon, 20);
			}
			*/
			case 402:  //Bazaar Bargain
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
				SpawnWeapon(client, "tf_weapon_sniperrifle", 14, 1, 0, "");
			}
		}//
	}
	else
	{
		civilianCheck[client]++;
	}

	weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(weapon))
	{
		/*
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch(index)
		{

			case 265:  //Stickybomb Jumper
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
				SpawnWeapon(client, "tf_weapon_pipebomblauncher", 265, 1, 0, "89 ; 0.2 ; 96 ; 1.6 ; 120 ; 99999.0 ; 3 ; 1.0 ; 89 ; -4.0");
				FF2_SetAmmo(client, weapon, 24);
			}

		}
		*/

		if(TF2_GetPlayerClass(client)==TFClass_Medic)
		{
			if(GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee)==142)  //Gunslinger (Randomizer, etc. compatability)
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, 255, 255, 255, 75);
			}
		}
	}
	else
	{
		civilianCheck[client]++;
	}

	int playerBack=FindPlayerBack(client, 57);  //Razorback
	shield[client]=IsValidEntity(playerBack) ? playerBack : 0;
	if(IsValidEntity(FindPlayerBack(client, 642)))  //Cozy Camper
	{
		SpawnWeapon(client, "tf_weapon_smg", 16, 1, 6, "149 ; 1.5 ; 15 ; 0.0 ; 1 ; 0.85");
	}

	#if defined _tf2attributes_included
	if(tf2attributes)
	{
		if(IsValidEntity(FindPlayerBack(client, 444)))  //Mantreads
		{
			TF2Attrib_SetByDefIndex(client, 58, 1.5);  //+50% increased push force
		}
		else
		{
			TF2Attrib_RemoveByDefIndex(client, 58);
		}
	}
	#endif

	int shieldEntity=-1, razorbackEntity=-1;
	while((shieldEntity=FindEntityByClassname2(shieldEntity, "tf_wearable_demoshield"))!=-1)  //Demoshields
	{
		if(GetEntPropEnt(shieldEntity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(shieldEntity, Prop_Send, "m_bDisguiseWearable"))
		{
			shield[client]=shieldEntity;
		}
	}
	while((razorbackEntity=FindEntityByClassname2(razorbackEntity, "tf_wearable_razorback"))!=-1)  //Razorback
	{
		if(GetEntPropEnt(razorbackEntity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(razorbackEntity, Prop_Send, "m_bDisguiseWearable"))
		{
			shield[client]=razorbackEntity;
		}
	}

	weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(weapon))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch(index)
		{
			case 43:  //KGB
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				SpawnWeapon(client, "tf_weapon_fists", 239, 1, 6, "1 ; 0.5 ; 107 ; 1.5 ; 128 ; 1 ; 191 ; -7 ; 772 ; 1.5");  //GRU
					//1: -50% damage
					//107: +50% move speed
					//128: Only when weapon is active
					//191: -7 health/second
					//772: Holsters 50% slower
			}
			case 357:  //Half-Zatoichi
			{
				CreateTimer(1.0, Timer_NoHonorBound, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
			case 589:  //Eureka Effect
			{
				if(!GetConVarBool(cvarEnableEurekaEffect))
				{
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
					SpawnWeapon(client, "tf_weapon_wrench", 7, 1, 0, "");
				}
			}
		}
	}
	else
	{
		civilianCheck[client]++;
	}

	if(civilianCheck[client]==3)
	{
		civilianCheck[client]=0;
		Debug("Respawning %N to avoid civilian bug", client);
		TF2_RespawnPlayer(client);
	}
	civilianCheck[client]=0;
	return Plugin_Continue;
}

public Action:OnObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enabled)
	{
		int attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
		if(!GetRandomInt(0, 2) && IsBoss(attacker))
		{
			decl String:sound[PLATFORM_MAX_PATH];
			if(RandomSound("sound_kill_buildable", sound, sizeof(sound)))
			{
				EmitSoundToAll(sound);
				EmitSoundToAll(sound);
			}
		}
	}
	return Plugin_Continue;
}

/*
public Action:OnUberDeployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(Enabled && IsValidClient(client) && IsPlayerAlive(client))
	{
		int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(medigun))
		{
			decl String:classname[64];
			GetEntityClassname(medigun, classname, sizeof(classname));
			if(StrEqual(classname, "tf_weapon_medigun"))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5, client);
				int target=GetHealingTarget(client);
				if(IsValidClient(target, false) && IsPlayerAlive(target))
				{
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5, client);
					uberTarget[client]=target;
				}
				else
				{
					uberTarget[client]=-1;
				}
				CreateTimer(0.4, Timer_Uber, EntIndexToEntRef(medigun), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}


public Action:Timer_Uber(Handle:timer, any:medigunid)
{
	int medigun=EntRefToEntIndex(medigunid);
	if(medigun && IsValidEntity(medigun) && CheckRoundState()==1)
	{
		int client=GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
		float charge=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
		if(IsValidClient(client, false) && IsPlayerAlive(client) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")==medigun)
		{
			int target=GetHealingTarget(client);
			if(charge>0.05)
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5);
				if(IsValidClient(target, false) && IsPlayerAlive(target))
				{
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5);
					uberTarget[client]=target;
				}
				else
				{
					uberTarget[client]=-1;
				}
			}
			else
			{
				return Plugin_Stop;
			}
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
*/

public Action:Command_GetHPCmd(client, args)
{
	if(!IsValidClient(client) || !Enabled || CheckRoundState()!=1)
	{
		return Plugin_Continue;
	}

	Command_GetHP(client);
	return Plugin_Handled;
}
// HasCompanions
public Action:Command_GetHP(client)  //TODO: This can rarely show a very large negative number if you time it right
{
	if(IsBoss(client) || GetGameTime()>=HPTime)
	{
		char text[512];  //Do not decl this
		decl String:lives[8], String:name[64];
		for(int target; target<=MaxClients; target++)
		{
			if(IsBoss(target) && IsPlayerAlive(target))
			{
				int boss=Boss[target];
				KvRewind(BossKV[Special[boss]]);
				KvGetString(BossKV[Special[boss]], "name", name, sizeof(name), "=Failed name=");
				if(BossLives[boss]>1)
				{
					Format(lives, sizeof(lives), "x%i", BossLives[boss]);
				}
				else
				{
					strcopy(lives, 2, "");
				}
				char diffItem[50];
				GetDifficultyString(BossDiff[boss], diffItem, sizeof(diffItem));
				if(IsBossYou[target])
				{
					char playerName[50];
					GetClientName(target, playerName, sizeof(playerName));
					Format(text, sizeof(text), "%s\n%t", text, "ff2_hp", playerName, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives, (!IsFakeClient(target) ? diffItem : "BOT"));
				}

				else
					Format(text, sizeof(text), "%s\n%t", text, "ff2_hp", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives, (!IsFakeClient(target) ? diffItem : "BOT"));

				if(IsBossYou[target])
				{
					char playerName[50];
					GetClientName(target, playerName, sizeof(playerName));
					CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_hp", playerName, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives, (!IsFakeClient(target) ? diffItem : "BOT"));

				}
				else
					CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_hp", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives, (!IsFakeClient(target) ? diffItem : "BOT"));

				BossHealthLast[boss]=BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
			}
		}
		if(HasCompanions)
			for(int target; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
				{
					SetGlobalTransTarget(target);
					PrintCenterText(target, text);
				}
			}
		else ShowGameText(text);

		if(GetGameTime()>=HPTime)
		{
			healthcheckused++;
			HPTime=GetGameTime()+(healthcheckused<3 ? 20.0 : 80.0);
		}
		return Plugin_Continue;
	}

	if(RedAlivePlayers>1)
	{
		char waitTime[128];
		for(int target; target<=MaxClients; target++)
		{
			if(IsBoss(target))
			{
				Format(waitTime, sizeof(waitTime), "%s %i,", waitTime, BossHealthLast[Boss[target]]);
			}
		}
		CPrintToChat(client, "{olive}[FF2]{default} %t", "wait_hp", RoundFloat(HPTime-GetGameTime()), waitTime);
	}
	return Plugin_Continue;
}

public Action:Command_SetNextBoss(client, args)
{
	decl String:name[64], String:boss[64];

	if(args<1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_special <boss>");
		return Plugin_Handled;
	}
	GetCmdArgString(name, sizeof(name));

	for(int config; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		if(StrContains(boss, name, false)!=-1)
		{
			Incoming[0]=config;
			CReplyToCommand(client, "{olive}[FF2]{default} Set the next boss to %s", boss);
			return Plugin_Handled;
		}

		KvGetString(BossKV[config], "filename", boss, sizeof(boss));
		if(StrContains(boss, name, false)!=-1)
		{
			Incoming[0]=config;
			KvGetString(BossKV[config], "name", boss, sizeof(boss));
			CReplyToCommand(client, "{olive}[FF2]{default} Set the next boss to %s", boss);
			return Plugin_Handled;
		}
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Boss could not be found!");
	return Plugin_Handled;
}

public Action:Command_Points(client, args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	if(args!=2)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_addpoints <target> <points>");
		return Plugin_Handled;
	}

	decl String:stringPoints[8];
	decl String:pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, stringPoints, sizeof(stringPoints));
	int points=StringToInt(stringPoints);

	char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches>1)
	{
		for(int target; target<matches; target++)
		{
			if(!IsClientSourceTV(targets[target]) && !IsClientReplay(targets[target]))
			{
				SetClientQueuePoints(targets[target], GetClientQueuePoints(targets[target])+points);
				LogAction(client, targets[target], "\"%L\" added %d queue points to \"%L\"", client, points, targets[target]);
			}
		}
	}
	else
	{
		SetClientQueuePoints(targets[0], GetClientQueuePoints(targets[0])+points);
		LogAction(client, targets[0], "\"%L\" added %d queue points to \"%L\"", client, points, targets[0]);
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Added %d queue points to %s", points, targetName);
	return Plugin_Handled;
}

public Action:Command_StartMusic(client, args)
{
	if(Enabled2)
	{
		if(args)
		{
			decl String:pattern[MAX_TARGET_LENGTH];
			GetCmdArg(1, pattern, sizeof(pattern));
			char targetName[MAX_TARGET_LENGTH];
			int targets[MAXPLAYERS], matches;
			bool targetNounIsMultiLanguage;
			if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
			{
				ReplyToTargetError(client, matches);
				return Plugin_Handled;
			}

			if(matches>1)
			{
				for(int target; target<matches; target++)
				{
					StartMusic(targets[target]);
				}
			}
			else
			{
				StartMusic(targets[0]);
			}
			CReplyToCommand(client, "{olive}[FF2]{default} Started boss music for %s.", targetName);
		}
		else
		{
			StartMusic();
			CReplyToCommand(client, "{olive}[FF2]{default} Started boss music for all clients.");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_StopMusic(client, args)
{
	if(Enabled2)
	{
		if(args)
		{
			decl String:pattern[MAX_TARGET_LENGTH];
			GetCmdArg(1, pattern, sizeof(pattern));
			char targetName[MAX_TARGET_LENGTH];
			int targets[MAXPLAYERS], matches;
			bool targetNounIsMultiLanguage;
			if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
			{
				ReplyToTargetError(client, matches);
				return Plugin_Handled;
			}

			if(matches>1)
			{
				for(int target; target<matches; target++)
				{
					StopMusic(targets[target], true);
				}
			}
			else
			{
				StopMusic(targets[0], true);
			}
			CReplyToCommand(client, "{olive}[FF2]{default} Stopped boss music for %s.", targetName);
		}
		else
		{
			StopMusic(_, true);
			CReplyToCommand(client, "{olive}[FF2]{default} Stopped boss music for all clients.");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_Charset(client, args)
{
	if(!args)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_charset <charset>");
		return Plugin_Handled;
	}

	decl String:charset[32], String:rawText[16][16];
	GetCmdArgString(charset, sizeof(charset));
	int amount=ExplodeString(charset, " ", rawText, 16, 16);
	for(int i; i<amount; i++)
	{
		StripQuotes(rawText[i]);
	}
	ImplodeStrings(rawText, amount, " ", charset, sizeof(charset));

	decl String:config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/characters.cfg");

	Handle Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	for(int i; ; i++)
	{
		KvGetSectionName(Kv, config, sizeof(config));
		if(StrContains(config, charset, false)>=0)
		{
			CReplyToCommand(client, "{olive}[FF2]{default} Charset for nextmap is %s", config);
			isCharSetSelected=true;
			FF2CharSet=i;
			break;
		}

		if(!KvGotoNextKey(Kv))
		{
			CReplyToCommand(client, "{olive}[FF2]{default} Charset not found");
			break;
		}
	}
	CloseHandle(Kv);
	return Plugin_Handled;
}

public Action:Command_ReloadSubPlugins(client, args)
{
	if(Enabled)
	{
		DisableSubPlugins(true);
		EnableSubPlugins(true);
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Reloaded subplugins!");
	return Plugin_Handled;
}

public Action:Command_Point_Disable(client, args)
{
	if(Enabled)
	{
		SetControlPoint(false);
	}
	return Plugin_Handled;
}

public Action:Command_Point_Enable(client, args)
{
	if(Enabled)
	{
		SetControlPoint(true);
	}
	return Plugin_Handled;
}

public OnClientPostAdminCheck(client) // OnClientPutInServer
{
	// TODO: Hook these inside of EnableFF2() or somewhere instead
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);

	FF2flags[client]=0;
	FF2Userflags[client]=0;
	Damage[client]=0;
	uberTarget[client]=-1;
	Marketed[client]=0;
	GoombaCount[client]=0;
	Stabbed[client]=0;

	if(AreClientCookiesCached(client))
	{
		char buffer[24];
		GetClientCookie(client, FF2Cookies, buffer, sizeof(buffer));
		if(!buffer[0])
		{
			SetClientCookie(client, FF2Cookies, "0 1 1 1 1 3 3");
			//Queue points | music exception | voice exception | class info | DIFFICULTY | UNUSED | UNUSED
		}
	}

	//We use the 0th index here because client indices can change.
 	//If this is false that means music is disabled for all clients, so don't play it for int clients either.
	if(playBGM[0])
	{
		playBGM[client]=true;
	 	if(Enabled)
	 	{
	 		// reateTimer(0.0, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			StartMusic(client);
	 	}
	}

}

public OnClientDisconnect(client)
{
	if(Enabled)
	{
		if(IsBoss(client) && !CheckRoundState() && GetConVarBool(cvarPreroundBossDisconnect))
		{
			int boss=GetBossIndex(client);
			bool omit[MAXPLAYERS+1];
			omit[client]=true;
			Boss[boss]=GetClientWithMostQueuePoints(omit);

			if(Boss[boss])
			{
				CreateTimer(0.1, MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
				CPrintToChat(Boss[boss], "{olive}[FF2]{default} %t", "Replace Disconnected Boss");
				CPrintToChatAll("{olive}[FF2]{default} %t", "Boss Disconnected", client, Boss[boss]);
			}
		}

		if(IsClientInGame(client) && IsPlayerAlive(client) && CheckRoundState()==1)
		{
			CreateTimer(0.1, CheckAlivePlayers, 0, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	FF2flags[client]=0;
	FF2Userflags[client]=0;
	Damage[client]=0;
	uberTarget[client]=-1;
	playBGM[client]=false; // This is reset accordingly in OnClientPostAdminCheck
	if(MusicTimer[client]!=INVALID_HANDLE)
	{
		KillTimer(MusicTimer[client]);
		MusicTimer[client]=INVALID_HANDLE;
	}
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	FF2Userflags[client] = 0;

	if(!Enabled || !IsValidClient(client))	return Plugin_Continue;

	if(GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 173) // 비타 쏘우
	{
		int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		char classname[60];
		if(IsValidEntity(medigun))
		{
			GetEntityClassname(medigun, classname, sizeof(medigun));
			if(!StrContains(classname, "tf_weapon_medigun", false))
			{
				SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 1.0);
			}
		}
	}

	if(CheckRoundState()==1)
	{
		// FF2Userflags[GetEventInt(event, "userid")] = 0;
		CreateTimer(0.1, CheckAlivePlayers, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action:OnPostInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");

	if(IsBoss(client))
	{
		CreateTimer(0.1, MakeBoss, GetBossIndex(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	if(!(FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		if(!(FF2flags[client] & FF2FLAG_HASONGIVED))
		{
			/*if(!(FF2flags[client] & FF2FLAG_HASONGIVED))
			{
				FF2flags[client]|=FF2FLAG_HASONGIVED;
				RemovePlayerBack(client, {57, 133, 405, 444, 608, 642}, 7);
				RemovePlayerTarge(client);
				TF2_RemoveAllWeapons(client);
				TF2_RegeneratePlayer(client);
				CreateTimer(0.1, Timer_RegenPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
			CreateTimer(0.2, MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			CreateTimer(0.1, CheckItems, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
			*/
			FF2flags[client]|=FF2FLAG_HASONGIVED;
 			RemovePlayerBack(client, {57, 133, 405, 444, 608, 642}, 7);
 			RemovePlayerTarge(client);
 			TF2_RemoveAllWeapons(client);
 			TF2_RegeneratePlayer(client);
 			CreateTimer(0.1, Timer_RegenPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}

		CreateTimer(0.2, MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	FF2flags[client]&=~(FF2FLAG_UBERREADY|FF2FLAG_ISBUFFED|FF2FLAG_TALKING|FF2FLAG_ALLOWSPAWNINBOSSTEAM|FF2FLAG_USINGABILITY|FF2FLAG_CLASSHELPED|FF2FLAG_CHANGECVAR|FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS|FF2FLAG_NOTALLOW_RAGE);
	// remove FF2FLAG_ROCKET_JUMPING
	FF2flags[client]|=FF2FLAG_USEBOSSTIMER;
	return Plugin_Continue;
}

public Action:Timer_RegenPlayer(Handle:timer, any:userid)
{
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2_RegeneratePlayer(client);
	}
}

public Action:ClientTimer(Handle:timer)
{
	if(!Enabled || CheckRoundState()==2 || CheckRoundState()==-1)
	{
		return Plugin_Stop;
	}

	decl String:classname[32];
	TFCond cond;

	DPSTick++;
	if(sizeof(PlayerDamageDPS[])-1<DPSTick)
	{
		DPSTick=0;
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !IsBoss(client) && !(FF2flags[client] & FF2FLAG_CLASSTIMERDISABLED))
		{
			/*
			PlayerDamageDPS[client][DPSTick]-=10.0;
			if(PlayerDamageDPS[client][DPSTick]<0.0)
				PlayerDamageDPS[client][DPSTick]=0.0;
			*/
			if(PlayerDamageDPS[client][DPSTick]>0.0) PlayerDamageDPS[client][DPSTick]/=1.5;

			SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
			if(!IsPlayerAlive(client))
			{
				int observer=GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if(IsValidClient(observer))
				{
					if(!IsBoss(observer) && observer!=client)
					{
						FF2_ShowSyncHudText(client, rageHUD, "데미지: %d - %N님의 데미지: %d (DPS: %.1f)", Damage[client], observer, Damage[observer], GetPlayerDPS(observer));
					}
					else if(IsBoss(observer) && observer!=client)
					{
						char temp[150];
						int boss = GetBossIndex(observer);

						if(BossLives[boss]>1)
						{
							Format(temp, sizeof(temp), "%t", "ff2_client_timer_observer_lifes", BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], BossLives[boss]);
						}
						else
						{
							Format(temp, sizeof(temp), "%t", "ff2_client_timer_observer_nolife", BossHealth[boss], BossHealthMax[boss]);
							// RoundFloat(BossCharge[boss][0]), 100, ragemeter, BossRageDamage[boss]
						}

						if(DEVmode)
						{
							Format(temp, sizeof(temp), "%s | %t", temp, "rage_meter_DEVmode");
						}
						if(FF2flags[observer] & FF2FLAG_NOTALLOW_RAGE)
						{
							Format(temp, sizeof(temp), "%s | %t", temp, "ff2_notallow_rage");
						}
						else if(BossAbilityDuration[boss][0] > 0.0 || BossAbilityCooldown[boss][0] > 0.0)
						{
							char temp2[25];
							if(BossAbilityDuration[boss][0] > 0.0)
							{
								Format(temp2, sizeof(temp), "%.1f", BossAbilityDuration[boss][0]);
								Format(temp, sizeof(temp), "%s | %t", temp, "rage_meter_duration", IsUpgradeRage[boss] ? BossUpgradeRageName[boss] : BossRageName[boss], temp2);
							}
							else if(BossAbilityCooldown[boss][0]>0.0)
							{
								Format(temp2, sizeof(temp), "%.1f", BossAbilityCooldown[boss][0]);
								Format(temp, sizeof(temp), "%s | %t", temp, "rage_meter_cooldown_easy", temp2);
							}
						}
						else
						{
							int ragemeter = RoundFloat(BossCharge[boss][0]*(BossRageDamage[boss]/100.0));
							Format(temp, sizeof(temp), "%s | %t", temp, "observer_rage_meter", RoundFloat(BossCharge[boss][0]), RoundFloat(BossMaxRageCharge[boss]), ragemeter, BossRageDamage[boss]);
						}
						FF2_ShowSyncHudText(client, rageHUD, "%s", temp);
						continue;
					}
				}
				// 	FF2_ShowSyncHudText(client, rageHUD, "데미지: %d (DPS: %.1f)", Damage[client], (Damage[client]*1.0)/playerDPS);
				continue;
			}
			FF2_ShowSyncHudText(client, rageHUD, "데미지: %d (DPS: %.1f)", Damage[client], GetPlayerDPS(client));

			TFClassType class = TF2_GetPlayerClass(client);
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(weapon <= MaxClients || !IsValidEntity(weapon) || !GetEntityClassname(weapon, classname, sizeof(classname)))
			{
				strcopy(classname, sizeof(classname), "");
			}
			bool validwep = !StrContains(classname, "tf_weapon", false);

			int index = (validwep ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if(class == TFClass_Medic)
			{
				/*
				if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
				{
					if(IsValidEntity(weapon))
					{
						decl String:medigunClassname[64];
						GetEntityClassname(weapon, medigunClassname, sizeof(medigunClassname));
						if(StrEqual(medigunClassname, "tf_weapon_medigun", false))
						{
							if(index != 35 &&
								index != 411 &&
								index != 998)
							{
								if(GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") > 0.0 && GetEntProp(weapon, Prop_Send, "m_bChargeRelease")) // m_bChargeRelease
								{
									TF2_RemoveCondition(client, TFCond_Ubercharged);
									TF2_AddCondition(client, TFCond_Ubercharged, 0.22);
								}
							}
						}
					}
				}
				*/

				if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
				{
					int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					decl String:mediclassname[64];
					if(IsValidEntity(medigun) && GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
					{
						int charge=RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
						SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
						FF2_ShowSyncHudText(client, jumpHUD, "%T: %i", "uber-charge", client, charge);

						if(charge==100 && !(FF2flags[client] & FF2FLAG_UBERREADY))
						{
							FakeClientCommandEx(client, "voicemenu 1 7");
							FF2flags[client]|=FF2FLAG_UBERREADY;
						}
					}
				}
				else if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
				{
					int healtarget=GetHealingTarget(client, true);
					if(IsValidClient(healtarget) && (TF2_GetPlayerClass(healtarget)==TFClass_Scout || index==411)) // 응급조치
					{
						TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.3);
					}
				}

				if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary) && index==35) // 크리츠
				{
					int healtarget=GetHealingTarget(client, true);
					if(IsValidClient(healtarget))
					{
						TF2_AddCondition(healtarget, TFCond_Buffed, 0.3);
					}
				}
			}
			else if(class==TFClass_Soldier)
			{
				if((FF2flags[client] & FF2FLAG_ISBUFFED) && !(GetEntProp(client, Prop_Send, "m_bRageDraining")))
				{
					FF2flags[client]&=~FF2FLAG_ISBUFFED;
				}
			}

			if(RedAlivePlayers==1 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Stealthed))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.3);
				if(class==TFClass_Engineer && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(classname, "tf_weapon_sentry_revenge", false))
				{
					SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
				}
				TF2_AddCondition(client, TFCond_Buffed, 0.3);

				if(lastPlayerGlow)
				{
					SetClientGlow(client, 3600.0);
				}
				continue;
			}
			else if(RedAlivePlayers==2 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				TF2_AddCondition(client, TFCond_Buffed, 0.3);
			}

			if(bMedieval)
			{
				continue;
			}

			cond=TFCond_HalloweenCritCandy;
			if(TF2_IsPlayerInCondition(client, TFCond_CritCola) && (class==TFClass_Scout || class==TFClass_Heavy))
			{
				TF2_AddCondition(client, cond, 0.3);
				continue;
			}

			int healer=-1;
			for(int healtarget=1; healtarget<=MaxClients; healtarget++)
			{
				if(IsValidClient(healtarget) && IsPlayerAlive(healtarget) && GetHealingTarget(healtarget, true)==client)
				{
					healer=healtarget;
					break;
				}
			}

			bool addthecrit=false;
			if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) && StrContains(classname, "tf_weapon_knife", false)==-1)  //Every melee except knives
			{
				addthecrit=true;

				if(index==416)  //Market Gardener
				{
					addthecrit=false;
					//FF2flags[client] & FF2FLAG_ROCKET_JUMPING ? true : false;
				}
			}
			else if((!StrContains(classname, "tf_weapon_smg") && index!=751) ||  //Cleaner's Carbine
			         !StrContains(classname, "tf_weapon_compound_bow") ||
			         !StrContains(classname, "tf_weapon_crossbow") ||
			         !StrContains(classname, "tf_weapon_pistol") ||
			         !StrContains(classname, "tf_weapon_handgun_scout_secondary"))
			{
				addthecrit=true;
				if(class==TFClass_Scout && cond==TFCond_HalloweenCritCandy)
				{
					cond=TFCond_Buffed;
				}
			}
			else if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary) && cond!=TFCond_HalloweenCritCandy)
			{
				addthecrit=true;
				cond=TFCond_Buffed;
			}

			if(index==16 && IsValidEntity(FindPlayerBack(client, 642)))  //SMG, Cozy Camper
			{
				addthecrit=false;
			}

			switch(class)
			{
				case TFClass_Pyro:
				{
					if(weapon!=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
					{
						addthecrit=true;
						cond=TFCond_Buffed;
					}
				}
				case TFClass_Medic:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
					{
						int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
						decl String:mediclassname[64];
						if(IsValidEntity(medigun) && GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
						{
							SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
							int charge=RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
							FF2_ShowHudText(client, -1, "%T: %i", "uber-charge", client, charge);
							if(charge==100 && !(FF2flags[client] & FF2FLAG_UBERREADY))
							{
								FakeClientCommand(client, "voicemenu 1 7");  //"I am fully charged!"
								FF2flags[client]|= FF2FLAG_UBERREADY;
							}
						}
					}
					else if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
					{
						int healtarget=GetHealingTarget(client, true);
						if(IsValidClient(healtarget) && TF2_GetPlayerClass(healtarget)==TFClass_Scout)
						{
							TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.3);
						}
					}
				}
				case TFClass_DemoMan:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && !IsValidEntity(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)) && shieldCrits)  //Demoshields
					{
						addthecrit=true;
						if(shieldCrits==1)
						{
							cond=TFCond_Buffed;
						}
					}
				}
				case TFClass_Spy:
				{
					if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
					{
						if(!TF2_IsPlayerCritBuffed(client) && !TF2_IsPlayerInCondition(client, TFCond_Buffed) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Disguised))
						{
							TF2_AddCondition(client, TFCond_CritCola, 0.3);
						}
					}
				}
				case TFClass_Engineer:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(classname, "tf_weapon_sentry_revenge", false))
					{
						int sentry=FindSentry(client);
						if(IsValidEntity(sentry) && IsBoss(GetEntPropEnt(sentry, Prop_Send, "m_hEnemy")))
						{
							SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
							TF2_AddCondition(client, TFCond_Kritzkrieged, 0.3);
						}
						else
						{
							if(GetEntProp(client, Prop_Send, "m_iRevengeCrits"))
							{
								SetEntProp(client, Prop_Send, "m_iRevengeCrits", 0);
							}
							else if(TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) && !TF2_IsPlayerInCondition(client, TFCond_Healing))
							{
								TF2_RemoveCondition(client, TFCond_Kritzkrieged);
							}
						}
					}
				}
			}

			if(addthecrit)
			{
				TF2_AddCondition(client, cond, 0.3);
				if(healer!=-1 && cond!=TFCond_Buffed)
				{
					TF2_AddCondition(client, TFCond_Buffed, 0.3);
				}
			}
		}
	}
	return Plugin_Continue;
}



public Action:BossTimer(Handle:timer)
{
	if(!Enabled || CheckRoundState()==2)
	{
		return Plugin_Stop;
	}

	bool validBoss=false;
	for(int boss; boss<=MaxClients; boss++)
	{
		int client=Boss[boss];

		if(!IsValidClient(client) || !IsPlayerAlive(client) || !(FF2flags[client] & FF2FLAG_USEBOSSTIMER))
		{
			continue;
		}
		validBoss=true;
		if(DEVmode)
		{
			BossCharge[boss][0] = BossMaxRageCharge[boss];
		}
		else if(FF2flags[client] & FF2FLAG_NOTALLOW_RAGE)
		{
			BossCharge[boss][0] = 0.0;
			BossMaxRageCharge[boss] = 0.0;
		}

		if(!IsFakeClient(client) && GetGameTime() >= AFKTime && !IsBossDoing[client])
		{
			KickClientEx(client, "보스인 상태에서 잠수가 감지되어 퇴장됩니다..");
			continue;
		}

		//
		if(!IsBossYou[client] && IsBoss(client))
		{
			if(BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1) > BossHealthMax[boss])
				SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", BossSpeed[Special[boss]]+0.7);

			else
				SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", BossSpeed[Special[boss]]+0.7*(100-BossHealth[boss]*100/BossLivesMax[boss]/BossHealthMax[boss]));
		}
		//

		if(BossHealth[boss]<=0 && IsPlayerAlive(client))  //Wat.  TODO:  Investigate
		{
			BossHealth[boss]=1;
		}

		if(BossLivesMax[boss]>1)
		{
			SetHudTextParams(-1.0, 0.77, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, livesHUD, "%t", "Boss Lives Left", BossLives[boss], BossLivesMax[boss]);
		}

		if(BossCharge[boss][0] >= 100.0)
		{
			// bool isUpgradeRage = BossCharge[boss][0] >= 200.0 ? true : false;
			if(IsFakeClient(client) && !(FF2flags[client] & FF2FLAG_BOTRAGE))
			{
				CreateTimer(1.0, Timer_BotRage, boss, TIMER_FLAG_NO_MAPCHANGE);
				FF2flags[client]|=FF2FLAG_BOTRAGE;
			}
			else
			{
				SetHudTextParams(-1.0, 0.83, 0.04, 255, 64, 64, 255);

				char temp[150];
				char temp3[100];

				if(BossAbilityDuration[boss][0] > 0.0 || BossAbilityCooldown[boss][0] > 0.0)
				{
					char temp2[30];
					if(BossAbilityDuration[boss][0] > 0.0)
					{
						Format(temp3, sizeof(temp3), "%t |", "rage_meter", RoundFloat(BossCharge[boss][0]), RoundFloat(BossMaxRageCharge[boss]), RoundFloat(BossCharge[boss][0]*(BossRageDamage[boss]/100.0)), BossRageDamage[boss]);
						Format(temp2, sizeof(temp2), "%.1f", BossAbilityDuration[boss][0]);
						SetHudTextParams(-1.0, 0.83, 0.04, 64, 255, 64, 255);
						Format(temp, sizeof(temp), "%s %t", temp3, "rage_meter_duration", IsUpgradeRage[boss] ? BossUpgradeRageName[boss] : BossRageName[boss], temp2);
					}
					else if(BossAbilityCooldown[boss][0] > 0.0)
					{
						Format(temp3, sizeof(temp3), "%t |", "rage_meter", RoundFloat(BossCharge[boss][0]), RoundFloat(BossMaxRageCharge[boss]), RoundFloat(BossCharge[boss][0]*(BossRageDamage[boss]/100.0)), BossRageDamage[boss]);
						Format(temp2, sizeof(temp2), "%.1f", BossAbilityCooldown[boss][0]);
						SetHudTextParams(-1.0, 0.83, 0.04, 255, 255, 255, 255);
						Format(temp, sizeof(temp), "%s %t", temp3, "rage_meter_cooldown_easy", temp2);
					}
				}
				else
				{
					Format(temp, sizeof(temp), "%t", "rage_meter", RoundFloat(BossCharge[boss][0]), RoundFloat(BossMaxRageCharge[boss]), RoundFloat(BossCharge[boss][0]*(BossRageDamage[boss]/100.0)), BossRageDamage[boss]);
					Format(temp, sizeof(temp), "%s | %t", temp, "do_rage");

					/*
					if(BossCharge[boss][0] >= 200.0)
					{
						Format(temp, sizeof(temp), "%s | %t", temp, "do_upgrade_rage");
					}
					else
					{
						Format(temp, sizeof(temp), "%s | %t", temp, "do_rage");
					}
					*/

				}
				if(DEVmode)
				{
					Format(temp, sizeof(temp), "%s | %t", temp, "rage_meter_DEVmode");
				}
				if(FF2flags[client] & FF2FLAG_NOTALLOW_RAGE)
				{
					SetHudTextParams(-1.0, 0.83, 0.04, 255, 255, 255, 255);
					Format(temp, sizeof(temp), "%t", "ff2_notallow_rage");
				}
				FF2_ShowSyncHudText(client, rageHUD, "%s", temp);

				decl String:sound[PLATFORM_MAX_PATH];
				if(RandomSound("sound_full_rage", sound, sizeof(sound), boss) && emitRageSound[boss])
				{
					float position[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

					FF2flags[client]|=FF2FLAG_TALKING;
					EmitSoundToAll(sound, client, _, _, _, _, _, client, position);
					EmitSoundToAll(sound, client, _, _, _, _, _, client, position);

					for(int target=1; target<=MaxClients; target++)
					{
						if(IsClientInGame(target) && target!=client)
						{
							EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
							EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
						}
					}
					FF2flags[client]&=~FF2FLAG_TALKING;
					emitRageSound[boss]=false;
				}
			}
		}
		else
		{
			SetHudTextParams(-1.0, 0.83, 0.04, 255, 255, 255, 255);
			if(DEVmode)
			{
				FF2_ShowSyncHudText(client, rageHUD, "%t", "rage_meter_DEVmode");
			}
			else if(FF2flags[client] & FF2FLAG_NOTALLOW_RAGE)
			{
				SetHudTextParams(-1.0, 0.83, 0.04, 255, 255, 255, 255);
				FF2_ShowSyncHudText(client, rageHUD, "%t", "ff2_notallow_rage");
			}
			else if(BossAbilityDuration[boss][0] > 0.0 || BossAbilityCooldown[boss][0] > 0.0)
			{
				char temp[42];
				char temp3[100];

				if(BossAbilityDuration[boss][0] > 0.0)
				{
					Format(temp3, sizeof(temp3), "%t |", "rage_meter", RoundFloat(BossCharge[boss][0]), RoundFloat(BossMaxRageCharge[boss]), RoundFloat(BossCharge[boss][0]*(BossRageDamage[boss]/100.0)), BossRageDamage[boss]);
					Format(temp, sizeof(temp), "%.1f", BossAbilityDuration[boss][0]);
					SetHudTextParams(-1.0, 0.83, 0.04, 64, 255, 64, 255);
					FF2_ShowSyncHudText(client, rageHUD, "%s %t", temp3, "rage_meter_duration", IsUpgradeRage[boss] ? BossUpgradeRageName[boss] : BossRageName[boss], temp);
				}
				else if(BossAbilityCooldown[boss][0] > 0.0)
				{
					Format(temp3, sizeof(temp3), "%t |", "rage_meter", RoundFloat(BossCharge[boss][0]), RoundFloat(BossMaxRageCharge[boss]), RoundFloat(BossCharge[boss][0]*(BossRageDamage[boss]/100.0)), BossRageDamage[boss]);
					Format(temp, sizeof(temp), "%.1f", BossAbilityCooldown[boss][0]);
					FF2_ShowSyncHudText(client, rageHUD, "%s %t", temp3, "rage_meter_cooldown_easy", temp);
				}
			}
			else	FF2_ShowSyncHudText(client, rageHUD, "%t", "rage_meter", RoundFloat(BossCharge[boss][0]), RoundFloat(BossMaxRageCharge[boss]), RoundFloat(BossCharge[boss][0]*(BossRageDamage[boss]/100.0)), BossRageDamage[boss]);
		}

		Handle slotNamePack = CreateArray();

		for(int slot=0; slot<9; slot++)
		{
			ClearArray(slotNamePack);
			// bool skiploop = false;

			int slotNameCount = 0;

			for(int i=1; ; i++)
			{
				decl String:ability[10];
				Format(ability, sizeof(ability), "ability%i", i);
				KvRewind(BossKV[Special[boss]]);
				if(KvJumpToKey(BossKV[Special[boss]], ability))
				{
					// decl String:plugin_name[64];
					// KvGetString(BossKV[Special[boss]], "plugin_name", plugin_name, sizeof(plugin_name));
					int targetSlot = KvGetNum(BossKV[Special[boss]], "arg0", 0);
					// int buttonmode=KvGetNum(BossKV[Special[boss]], "buttonmode", 0);
					if(targetSlot == slot)
					{
						char ability_name[64];
						slotNameCount++;
						KvGetString(BossKV[Special[boss]], "name", ability_name, sizeof(ability_name));
						PushArrayString(slotNamePack, ability_name);
					}
					else
					{
						// skiploop = true;
						continue;
					}
					// UseAbility(ability_name, plugin_name, boss, slot, buttonmode);
				}
				else
				{
					break;
				}
			}

			if(BossAbilityDuration[boss][slot] > 0.0)
			{
				BossAbilityDuration[boss][slot]-=0.1;

				if(BossAbilityDuration[boss][slot] <= 0.0)
				{
					if(IsPlayerAlive(client))
					{
						for(int count=0; count<slotNameCount; count++)
						{
							char abilityName[64];

							GetArrayString(slotNamePack, count, abilityName, sizeof(abilityName));

							Call_StartForward(OnAbilityTimeEnd);
							Call_PushCell(boss);
							Call_PushCell(slot);
							Call_Finish();
						}
					}
				}
			}
			else if(BossAbilityCooldown[boss][slot] > 0.0)
			{
				BossAbilityCooldown[boss][slot] -= 0.1;
			}
			else
			{
				continue;
			}
			// Format(temp, sizeof(temp), "%s", IsUpgradeRage[boss] ? BossUpgradeRageName[boss] : BossRageName[boss]);

			for(int count=0; count<slotNameCount; count++)
			{
				float temp2=BossAbilityDuration[boss][slot];
				float temp3=BossAbilityCooldown[boss][slot];
				char abilityName[64];
				Action action;

				GetArrayString(slotNamePack, count, abilityName, sizeof(abilityName));

				Call_StartForward(OnAbilityTime);
				Call_PushCell(boss);
				Call_PushStringEx(abilityName, sizeof(abilityName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCell(slot);
				Call_PushFloatRef(temp2);
				Call_PushFloatRef(temp3);
				Call_Finish(action);

				switch(action)
				{
					case Plugin_Changed:
					{
						BossAbilityDuration[boss][slot]=temp2;
						BossAbilityCooldown[boss][slot]=temp3;
						// Format(BossRageName[boss], sizeof(BossRageName[]), "%s", temp);
				  	}
				}
			}
		}
		CloseHandle(slotNamePack);

		if(IsBossYou[client])
		{
			int weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) || FF2ServerFlag & FF2SERVERFLAG_ISLASTMAN)
			{
				TF2_AddCondition(client, TFCond_Buffed, 0.1);
			}
		}

		SetHudTextParams(-1.0, 0.88, 0.04, 255, 255, 255, 255);
		SetClientGlow(client, -0.2);

		decl String:lives[MAXRANDOMS][3];
		for(int i=1; ; i++)
		{
			decl String:ability[10];
			Format(ability, sizeof(ability), "ability%i", i);
			KvRewind(BossKV[Special[boss]]);
			if(KvJumpToKey(BossKV[Special[boss]], ability))
			{
				decl String:plugin_name[64];
				KvGetString(BossKV[Special[boss]], "plugin_name", plugin_name, sizeof(plugin_name));
				int slot=KvGetNum(BossKV[Special[boss]], "arg0", 0);
				int buttonmode=KvGetNum(BossKV[Special[boss]], "buttonmode", 0);
				if(slot<1)
				{
					continue;
				}

				KvGetString(BossKV[Special[boss]], "life", ability, sizeof(ability), "");
				if(!ability[0])
				{
					decl String:ability_name[64];
					KvGetString(BossKV[Special[boss]], "name", ability_name, sizeof(ability_name));
					UseAbility(ability_name, plugin_name, boss, slot, buttonmode);
				}
				else
				{
					int count=ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
					for(int n; n<count; n++)
					{
						if(StringToInt(lives[n])==BossLives[boss])
						{
							decl String:ability_name[64];
							KvGetString(BossKV[Special[boss]], "name", ability_name, sizeof(ability_name));
							UseAbility(ability_name, plugin_name, boss, slot, buttonmode);
							break;
						}
					}
				}
			}
			else
			{
				break;
			}
		}

		if(RedAlivePlayers==1)
		{
			char message[512];  //Do not decl this
			decl String:name[64];
			for(int target; target<=MaxClients; target++)  //TODO: Why is this for loop needed when we're already in a boss for loop
			{
				if(IsBoss(target) && IsPlayerAlive(target))
				{
					int boss2=GetBossIndex(target);
					KvRewind(BossKV[Special[boss2]]);
					KvGetString(BossKV[Special[boss2]], "name", name, sizeof(name), "=Failed name=");
					//Format(bossLives, sizeof(bossLives), ((BossLives[boss2]>1) ? ("x%i", BossLives[boss2]) : ("")));
					decl String:bossLives[10];
					if(BossLives[boss2]>1)
					{
						Format(bossLives, sizeof(bossLives), "x%i", BossLives[boss2]);
					}
					else
					{
						Format(bossLives, sizeof(bossLives), "");
					}

					char diffItem[50];
					GetDifficultyString(BossDiff[boss2], diffItem, sizeof(diffItem));

					if(IsBossYou[target])
					{
						char playerName[50];
						GetClientName(target, playerName, sizeof(playerName));
						Format(message, sizeof(message), "%s\n%t", message, "ff2_hp", playerName, BossHealth[boss2]-BossHealthMax[boss2]*(BossLives[boss2]-1), BossHealthMax[boss2], bossLives, (!IsFakeClient(target) ? diffItem : "BOT"));
					}

					else
						Format(message, sizeof(message), "%s\n%t", message, "ff2_hp", name, BossHealth[boss2]-BossHealthMax[boss2]*(BossLives[boss2]-1), BossHealthMax[boss2], bossLives, (!IsFakeClient(target) ? diffItem : "BOT"));

				}
			}
			if(HasCompanions)
				for(int target; target<=MaxClients; target++)
				{
					if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
					{
						SetGlobalTransTarget(target);
						PrintCenterText(target, message);
					}
				}
			else ShowGameText(message);

			if(lastPlayerGlow)
			{
				SetClientGlow(client, 3600.0);
			}
		}

		if(BossCharge[boss][0]<BossMaxRageCharge[boss])
		{
			BossCharge[boss][0] += (OnlyParisLeft(BossTeam)*0.2)/3.5;
			if(BossCharge[boss][0] > BossMaxRageCharge[boss])
			{
				BossCharge[boss][0] = BossMaxRageCharge[boss];
			}
		}

		HPTime-=0.2;
		if(HPTime<0)
		{
			HPTime=0.0;
		}

		for(int client2; client2<=MaxClients; client2++)
		{
			if(KSpreeTimer[client2]>0)
			{
				KSpreeTimer[client2]-=0.2;
			}
		}
	}

	if(!validBoss)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_BotRage(Handle:timer, any:bot)
{
	if(IsValidClient(Boss[bot], false))
	{
		FakeClientCommandEx(Boss[bot], "voicemenu 0 0");
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(Enabled)
	{
		if(IsBoss(client) && (condition==TFCond_Jarated || condition==TFCond_MarkedForDeath || (condition==TFCond_Dazed && TF2_IsPlayerInCondition(client, TFCond:42))))
		{
			TF2_RemoveCondition(client, condition);
		}
/*		else if(!IsBoss(client) && condition==TFCond_BlastJumping)
		{
			FF2flags[client]|=FF2FLAG_ROCKET_JUMPING;
		}
*/
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(Enabled)
	{
		if(TF2_GetPlayerClass(client)==TFClass_Scout && condition==TFCond_CritHype)
		{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
		}
/*
		else if(TF2_GetPlayerClass(client) == TFClass_Medic && condition == TFCond_Ubercharged)
		{
			int medigun = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(medigun))
			{
				decl String:medigunClassname[64];
				GetEntityClassname(medigun, medigunClassname, sizeof(medigunClassname));
				if(StrEqual(medigunClassname, "tf_weapon_medigun", false))
				{
					int index = GetEntProp(medigun, Prop_Send, "m_iItemDefinitionIndex");
					if(index == 35 ||
						index == 411 ||
						index == 998)
						return;

					if(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel") > 0.0 && GetEntProp(medigun, Prop_Send, "m_bChargeRelease")) // m_bChargeRelease
						TF2_AddCondition(client, TFCond_Ubercharged, TFCondDuration_Infinite, medigun);
				}
			}
		}
*/
/*
		else if(!IsBoss(client) && condition==TFCond_BlastJumping)
		{
			FF2flags[client]&=~FF2FLAG_ROCKET_JUMPING;
		}
*/
	}
}

public Action:OnCallForMedic(client, const String:command[], args)
{
	if(!Enabled || !IsPlayerAlive(client) || CheckRoundState()!=1 || !IsBoss(client) || args!=2)
	{
		return Plugin_Continue;
	}

	int boss=GetBossIndex(client);
	if(boss==-1 || !Boss[boss] || !IsValidEntity(Boss[boss]))
	{
		return Plugin_Continue;
	}

	decl String:arg1[4], String:arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
	{
		return Plugin_Continue;
	}

	if(RoundFloat(BossCharge[boss][0])>=100)
	{
		bool doUpgradeRage = (RoundFloat(BossCharge[boss][0]) >= 200) ? true : false;
		//
		doUpgradeRage = false;
		//
		bool hasUpgradeRage = false;
		if(BossAbilityDuration[boss][0] > 0.0 || BossAbilityCooldown[boss][0] > 0.0 || (!DEVmode && FF2flags[client] & FF2FLAG_NOTALLOW_RAGE))
		{
			CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_can_not_rage");
			return Plugin_Continue;
		}

		bool isSoloRage = false;

		decl String:ability[10], String:lives[MAXRANDOMS][3];

		for(int i=1; i<MAXRANDOMS; i++) // 강화 분노 체크용도로만.
		{
			Format(ability, sizeof(ability), "ability%i", i);
			KvRewind(BossKV[Special[boss]]);
			if(KvJumpToKey(BossKV[Special[boss]], ability))
			{
				if(KvGetNum(BossKV[Special[boss]], "arg0", 0))
				{
					continue;
				}

				KvGetString(BossKV[Special[boss]], "life", ability, sizeof(ability));
				if(!ability[0])
				{
					decl String:abilityName[64], String:pluginName[64];
					KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
					KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
					if(doUpgradeRage)
					{
						if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) <= 0)
							continue;
						else
							hasUpgradeRage = true;
					}
					else
					{
						if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) > 0)
							continue;
					}
					/*
					if(!UseAbility(abilityName, pluginName, boss, 0))
					{
						return Plugin_Continue;
					}
					*/
				}
				else
				{
					int count=ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
					for(int j; j<count; j++)
					{
						if(StringToInt(lives[j])==BossLives[boss])
						{
							decl String:abilityName[64], String:pluginName[64];
							KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
							KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));

							if(doUpgradeRage)
							{
								if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) <= 0)
									continue;
								else
									hasUpgradeRage = true;
							}
							else
							{
								if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) > 0)
									continue;
							}
							/*
							if(!UseAbility(abilityName, pluginName, boss, 0))
							{
								return Plugin_Continue;
							}
							*/
							break;
						}
					}
				}
			}
		}

		if(doUpgradeRage && !hasUpgradeRage)
		{
			for(int i=1; i<MAXRANDOMS; i++)
			{
				Format(ability, sizeof(ability), "ability%i", i);
				KvRewind(BossKV[Special[boss]]);
				if(KvJumpToKey(BossKV[Special[boss]], ability))
				{
					if(KvGetNum(BossKV[Special[boss]], "arg0", 0))
					{
						continue;
					}

					KvGetString(BossKV[Special[boss]], "life", ability, sizeof(ability));
					if(!ability[0])
					{
						decl String:abilityName[64], String:pluginName[64];
						KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
						KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));

						if(!UseAbility(abilityName, pluginName, boss, 0))
						{
							return Plugin_Continue;
						}
					}
					else
					{
						int count=ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
						for(int j; j<count; j++)
						{
							if(StringToInt(lives[j])==BossLives[boss])
							{
								decl String:abilityName[64], String:pluginName[64];
								KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
								KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));

								if(!UseAbility(abilityName, pluginName, boss, 0))
								{
									return Plugin_Continue;
								}
								break;
							}
						}
					}
				}
			}
		}

		if(doUpgradeRage && hasUpgradeRage)
		{
			IsUpgradeRage[boss] = true;
			KvRewind(BossKV[Special[boss]]);
			BossAbilityDuration[boss][0] = KvGetFloat(BossKV[Special[boss]], "upgrade_ability_duration");
			BossCharge[boss][0] -= 200.0;
		}
		else
		{
			IsUpgradeRage[boss] = false;
			BossAbilityDuration[boss][0] = BossAbilityDurationMax[boss][0];

			if(doUpgradeRage)
				CPrintToChat(client, "{olive}[FF2]{default} 이 보스에게 강화분노가 등록되지 않아서 일반 분노로 대체됩니다!");
			BossCharge[boss][0] -= 100.0;
		}

		float position[3];
		float victimPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		float rageDist=KvGetFloat(BossKV[Special[boss]], "ragedist", 300.0);
		char bossName[80];
		int find=0; TFTeam team;

		GetEntPropVector(Boss[boss], Prop_Send, "m_vecOrigin", position);
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsValidClient(i) && IsPlayerAlive(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", victimPos);
				team=TF2_GetClientTeam(i);
				if(GetVectorDistance(position, victimPos) <= rageDist && _:team != BossTeam)
					find++;
			}
		}

		if(find == 1)
		{
			isSoloRage = true;
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName), "ERROR NAME");
			CPrintToChatAll("{olive}[FF2]{default} %t", "oneperson_rage", bossName);
			BossAbilityDuration[boss][0]=BossAbilityDurationMax[boss][0]+2.0;

			Handle SoloRageDelay;
			CreateDataTimer(2.0, SoloRageDelayTimer, SoloRageDelay, TIMER_FLAG_NO_MAPCHANGE);

			WritePackCell(SoloRageDelay, client);
			// WritePackCell(SoloRageDelay, boss);
			WritePackCell(SoloRageDelay, doUpgradeRage);
			// WritePackCell(SoloRageDelay, doUpgradeRage);
			ResetPack(SoloRageDelay);
		}
		else
		{
			BossAbilityDuration[boss][0]=BossAbilityDurationMax[boss][0];
		}

		if(!isSoloRage)
		{
			for(int i=1; i<MAXRANDOMS; i++)
			{
				Format(ability, sizeof(ability), "ability%i", i);
				KvRewind(BossKV[Special[boss]]);
				if(KvJumpToKey(BossKV[Special[boss]], ability))
				{
					if(KvGetNum(BossKV[Special[boss]], "arg0", 0))
					{
						continue;
					}

					KvGetString(BossKV[Special[boss]], "life", ability, sizeof(ability));
					if(!ability[0])
					{
						decl String:abilityName[64], String:pluginName[64];
						KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
						KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
						if(doUpgradeRage)
						{
							if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) <= 0)
								continue;
							else
								hasUpgradeRage = true;
						}
						else
						{
							if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) > 0)
								continue;
						}
						if(!UseAbility(abilityName, pluginName, boss, 0))
						{
							return Plugin_Continue;
						}
					}
					else
					{
						int count=ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
						for(int j; j<count; j++)
						{
							if(StringToInt(lives[j])==BossLives[boss])
							{
								decl String:abilityName[64], String:pluginName[64];
								KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
								KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));

								if(doUpgradeRage)
								{
									if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) <= 0)
										continue;
									else
										hasUpgradeRage = true;
								}
								else
								{
									if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) > 0)
										continue;
								}
								if(!UseAbility(abilityName, pluginName, boss, 0))
								{
									return Plugin_Continue;
								}
								break;
							}
						}
					}
				}
			}
		}


		decl String:sound[PLATFORM_MAX_PATH];
		if(RandomSoundAbility("sound_ability", sound, sizeof(sound), boss))
		{
			FF2flags[Boss[boss]]|=FF2FLAG_TALKING;
			EmitSoundToAll(sound, client, _, _, _, _, _, client, position);
			EmitSoundToAll(sound, client, _, _, _, _, _, client, position);

			for(int target=1; target<=MaxClients; target++)
			{
				if(IsClientInGame(target) && target!=Boss[boss])
				{
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
				}
			}
			FF2flags[Boss[boss]]&=~FF2FLAG_TALKING;
		}
		emitRageSound[boss]=true;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action SoloRageDelayTimer(Handle timer, Handle data)
{
	if(CheckRoundState()!=1)
		return Plugin_Continue;

	int client = ReadPackCell(data);
	int boss = GetBossIndex(client);
	bool doUpgradeRage = ReadPackCell(data);

	if(boss == -1) return Plugin_Continue;

	char ability[10], lives[MAXRANDOMS][3];
	for(int i=1; i<MAXRANDOMS; i++)
	{
		Format(ability, sizeof(ability), "ability%i", i);
		KvRewind(BossKV[Special[boss]]);
		if(KvJumpToKey(BossKV[Special[boss]], ability))
		{
			if(KvGetNum(BossKV[Special[boss]], "arg0", 0))
			{
				continue;
			}

			KvGetString(BossKV[Special[boss]], "life", ability, sizeof(ability));
			if(!ability[0])
			{
				decl String:abilityName[64], String:pluginName[64];
				KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
				KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
				if(doUpgradeRage)
				{
					if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) <= 0)
						continue;
				}
				else
				{
					if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) > 0)
						continue;
				}
				if(!UseAbility(abilityName, pluginName, boss, 0))
				{
					return Plugin_Continue;
				}
			}
			else
			{
				int count=ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
				for(int j; j<count; j++)
				{
					if(StringToInt(lives[j])==BossLives[boss])
					{
						decl String:abilityName[64], String:pluginName[64];
						KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
						KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));

						if(doUpgradeRage)
						{
							if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) <= 0)
								continue;

						}
						else
						{
							if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) > 0)
								continue;
						}
						if(!UseAbility(abilityName, pluginName, boss, 0))
						{
							return Plugin_Continue;
						}
						break;
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:OnSuicide(client, const String:command[], args)
{
	bool canBossSuicide=GetConVarBool(cvarBossSuicide);
	if(Enabled && IsBoss(client) && (canBossSuicide ? !CheckRoundState() : true) && CheckRoundState()!=2)
	{
		CPrintToChat(client, "{olive}[FF2]{default} %t", canBossSuicide ? "Boss Suicide Pre-round" : "Boss Suicide Denied");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnChangeClass(client, const String:command[], args)
{
	if(Enabled && IsBoss(client) && IsPlayerAlive(client))
	{
		//Don't allow the boss to switch classes but instead set their *desired* class (for the next round)
		decl String:class[16];
		GetCmdArg(1, class, sizeof(class));
		if(TF2_GetClass(class)!=TFClass_Unknown)  //Ignore cases where the client chooses an invalid class through the console
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TF2_GetClass(class));
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnJoinTeam(client, const String:command[], args)
{
	if(!Enabled || RoundCount<arenaRounds || CheckRoundState() == -1) // 1.10.15
	{
		return Plugin_Continue;
	}

	// autoteam doesn't come with arguments
 	if(StrEqual(command, "autoteam", false))
 	{
 		int team=_:TFTeam_Unassigned, oldTeam=GetClientTeam(client);
 		if(IsBoss(client))
 		{
 			team=BossTeam;
 		}
 		else
 		{
 			team=OtherTeam;
 		}

 		if(team!=oldTeam)
 		{
 			ChangeClientTeam(client, team);
 		}
 		return Plugin_Handled;
 	}

	if(!args)
 	{
 		return Plugin_Continue;
 	}

	int team = view_as<int>(TFTeam_Unassigned), oldTeam = GetClientTeam(client);
	char teamString[10];
	GetCmdArg(1, teamString, sizeof(teamString));

	if(StrEqual(teamString, "red", false))
	{
		team = view_as<int>(TFTeam_Red);
	}
	else if(StrEqual(teamString, "blue", false))
	{
		team = view_as<int>(TFTeam_Blue);
	}
	else if(StrEqual(teamString, "auto", false))
	{
		team = view_as<int>(OtherTeam);
	}
	else if(StrEqual(teamString, "spectate", false) && !IsBoss(client) && GetConVarBool(FindConVar("mp_allowspectators")))
	{
		team = view_as<int>(TFTeam_Spectator);
	}

	if(team == BossTeam && !IsBoss(client))
	{
		team = OtherTeam;
	}
	else if(team == OtherTeam && IsBoss(client))
	{
		team = BossTeam;
	}

	if(team > view_as<int>(TFTeam_Unassigned) && team != oldTeam)
	{
		ChangeClientTeam(client, team);
	}

	if(CheckRoundState()!=1 && !IsBoss(client) || !IsPlayerAlive(client))  //No point in showing the VGUI if they can't change teams
	{
		switch(team)
		{
			case TFTeam_Red:
			{
				ShowVGUIPanel(client, "class_red");
			}
			case TFTeam_Blue:
			{
				ShowVGUIPanel(client, "class_blue");
			}
		}
	}
	return Plugin_Handled;
}

public Action:OnPlayerDeath(Handle:event, const String:eventName[], bool:dontBroadcast)
{
	if(!Enabled || CheckRoundState()!=1)
	{
		return Plugin_Continue;
	}

	CreateTimer(0.1, CheckAlivePlayers, 0, TIMER_FLAG_NO_MAPCHANGE);

	int client=GetClientOfUserId(GetEventInt(event, "userid")), attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	decl String:sound[PLATFORM_MAX_PATH];
	// CreateTimer(0.1, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	DoOverlay(client, "");

	if(!IsBoss(client))
	{
		if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			CreateTimer(1.0, Timer_Damage, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}

		if(IsBoss(attacker))
		{
			int boss=GetBossIndex(attacker);
			if(firstBlood)  //TF_DEATHFLAG_FIRSTBLOOD is broken
			{
				if(RandomSound("sound_first_blood", sound, sizeof(sound), boss))
				{
					EmitSoundToAll(sound);
					EmitSoundToAll(sound);
				}
				firstBlood=false;
			}

			if(RedAlivePlayers!=1)  //Don't conflict with end-of-round sounds
			{
				if(GetRandomInt(0, 1) && RandomSound("sound_hit", sound, sizeof(sound), boss))
				{
					EmitSoundToAll(sound);
					EmitSoundToAll(sound);
				}
				else if(!GetRandomInt(0, 2))  //1/3 chance for "sound_kill_<class>"
				{
					char classnames[][]={"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
					decl String:class[32];
					Format(class, sizeof(class), "sound_kill_%s", classnames[TF2_GetPlayerClass(client)]);
					if(RandomSound(class, sound, sizeof(sound), boss))
					{
						EmitSoundToAll(sound);
						EmitSoundToAll(sound);
					}
				}
			}

			if(GetGameTime()<=KSpreeTimer[boss])
			{
				KSpreeCount[boss]++;
			}
			else
			{
				KSpreeCount[boss]=1;
			}

			if(KSpreeCount[boss]==3)
			{
				if(RandomSound("sound_kspree", sound, sizeof(sound), boss))
				{
					EmitSoundToAll(sound);
					EmitSoundToAll(sound);
				}
				KSpreeCount[boss]=0;
			}
			else
			{
				KSpreeTimer[boss]=GetGameTime()+5.0;
			}
		}
	}
	else if(IsBoss(client))
	{
		int boss=GetBossIndex(client);
		if(boss==-1)
		{
			return Plugin_Continue;
		}
		else if(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
		{
			return Plugin_Handled;
		}

		if(RandomSound("sound_death", sound, sizeof(sound), boss))
		{
			EmitSoundToAll(sound);
			EmitSoundToAll(sound);
		}

		BossHealth[boss]=0;
		// 확인용
		UpdateHealthBar();

	}

	if(TF2_GetPlayerClass(client)==TFClass_Engineer && !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		decl String:name[PLATFORM_MAX_PATH];
		FakeClientCommand(client, "destroy 2");
		for(int entity=MaxClients+1; entity<MAXENTITIES; entity++)
		{
			if(IsValidEntity(entity))
			{
				GetEntityClassname(entity, name, sizeof(name));
				if(!StrContains(name, "obj_sentrygun") && (GetEntPropEnt(entity, Prop_Send, "m_hBuilder")==client))
				{
					SetVariantInt(GetEntPropEnt(entity, Prop_Send, "m_iMaxHealth")+1);
					AcceptEntityInput(entity, "RemoveHealth");

					Handle eventRemoveObject=CreateEvent("object_removed", true);
					SetEventInt(eventRemoveObject, "userid", GetClientUserId(client));
					SetEventInt(eventRemoveObject, "index", entity);
					FireEvent(eventRemoveObject);
					AcceptEntityInput(entity, "kill");
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action:Timer_Damage(Handle:timer, any:userid)
{
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client, false))
	{
		CPrintToChat(client, "{olive}[FF2] %t. %t{default}", "damage", Damage[client], "scores", RoundFloat(Damage[client]/400.0));
	}
	return Plugin_Continue;
}

public Action:OnObjectDeflected(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!Enabled || GetEventInt(event, "weaponid"))  //0 means that the client was airblasted, which is what we want
	{
		return Plugin_Continue;
	}

	int boss=GetBossIndex(GetClientOfUserId(GetEventInt(event, "ownerid")));
	if(boss!=-1 && BossCharge[boss][0] < BossMaxRageCharge[boss])
	{
		BossCharge[boss][0]+=7.0;  //TODO: Allow this to be customizable
		if(BossCharge[boss][0] > BossMaxRageCharge[boss])
		{
			BossCharge[boss][0] = BossMaxRageCharge[boss];
		}
	}
	return Plugin_Continue;
}

public Action:OnJarate(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	int client=BfReadByte(bf);
	int victim=BfReadByte(bf);
	int boss=GetBossIndex(victim);
	if(boss!=-1)
	{
		int jarate=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(jarate!=-1)
		{
			int index=GetEntProp(jarate, Prop_Send, "m_iItemDefinitionIndex");
			if((index==58 || index==1083 || index==1105) && GetEntProp(jarate, Prop_Send, "m_iEntityLevel")!=-122)  //-122 is the Jar of Ants which isn't really Jarate
			{
				BossCharge[boss][0]-=8.0;  //TODO: Allow this to be customizable
				if(BossCharge[boss][0]<0.0)
				{
					BossCharge[boss][0]=0.0;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnDeployBackup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(Enabled && GetEventInt(event, "buff_type")==2)
	{
		FF2flags[GetClientOfUserId(GetEventInt(event, "buff_owner"))]|=FF2FLAG_ISBUFFED;
	}
	return Plugin_Continue;
}

public Action:CheckAlivePlayers(Handle:timer, int except)
{
	if(CheckRoundState()==2)
	{
		return Plugin_Continue;
	}

	RedAlivePlayers=0;
	BlueAlivePlayers=0;

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(GetClientTeam(client)==OtherTeam)
			{
				RedAlivePlayers++;
			}
			else if(GetClientTeam(client)==BossTeam)
			{
				BlueAlivePlayers++;
			}
		}
	}

	Call_StartForward(OnAlivePlayersChanged);  //Let subplugins know that the number of alive players just changed
	Call_PushCell(RedAlivePlayers);
	Call_PushCell(BlueAlivePlayers);
	Call_Finish();

	if(!RedAlivePlayers)
	{
		if(except)	ForceTeamWin(BossTeam);
		else CreateTimer(0.05, CheckAlivePlayers, 1);
	}
	else if(RedAlivePlayers==1 && BlueAlivePlayers && Boss[0] && !DrawGameTimer && !NoticedLastman)
	{
		decl String:sound[PLATFORM_MAX_PATH];
		NoticedLastman=true;
		if(RandomSound("sound_lastman", sound, sizeof(sound)))
		{
			EmitSoundToAll(sound);
			EmitSoundToAll(sound);
		}
	}
	else if(!PointType && RedAlivePlayers<=AliveToEnable && !executed)
	{
		PrintHintTextToAll("%t", "point_enable", AliveToEnable);
		if(RedAlivePlayers==AliveToEnable)
		{
			char sound[64];
			if(GetRandomInt(0, 1))
			{
				Format(sound, sizeof(sound), "vo/announcer_am_capenabled0%i.mp3", GetRandomInt(1, 4));
			}
			else
			{
				Format(sound, sizeof(sound), "vo/announcer_am_capincite0%i.mp3", GetRandomInt(0, 1) ? 1 : 3);
			}
			EmitSoundToAll(sound);
		}
		SetControlPoint(true);
		executed=true;
	}

	if(RedAlivePlayers<=countdownPlayers && BossHealth[0]>countdownHealth && countdownTime>1 && !executed2)
	{
		if(FindEntityByClassname2(-1, "team_control_point")!=-1)
		{
			timeleft=countdownTime;
			DrawGameTimer=CreateTimer(1.0, Timer_DrawGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		executed2=true;
	}
	return Plugin_Continue;
}

public Action:Timer_DrawGame(Handle:timer)
{
	if(BossHealth[0]<countdownHealth || CheckRoundState()!=1 || RedAlivePlayers>countdownPlayers)
	{
		executed2=false;
		return Plugin_Stop;
	}

	int time=timeleft;
	timeleft--;
	decl String:timeDisplay[6];
	if(time/60>9)
	{
		IntToString(time/60, timeDisplay, sizeof(timeDisplay));
	}
	else
	{
		Format(timeDisplay, sizeof(timeDisplay), "0%i", time/60);
	}

	if(time%60>9)
	{
		Format(timeDisplay, sizeof(timeDisplay), "%s:%i", timeDisplay, time%60);
	}
	else
	{
		Format(timeDisplay, sizeof(timeDisplay), "%s:0%i", timeDisplay, time%60);
	}

	SetHudTextParams(-1.0, 0.17, 1.1, 255, 255, 255, 255);
	for(int client; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			FF2_ShowSyncHudText(client, timeleftHUD, timeDisplay);
		}
	}

	switch(time)
	{
		case 300:
		{
			EmitSoundToAll("vo/announcer_ends_5min.mp3");
		}
		case 120:
		{
			EmitSoundToAll("vo/announcer_ends_2min.mp3");
		}
		case 60:
		{
			EmitSoundToAll("vo/announcer_ends_60sec.mp3");
		}
		case 30:
		{
			EmitSoundToAll("vo/announcer_ends_30sec.mp3");
		}
		case 10:
		{
			EmitSoundToAll("vo/announcer_ends_10sec.mp3");
		}
		case 1, 2, 3, 4, 5:
		{
			decl String:sound[PLATFORM_MAX_PATH];
			Format(sound, PLATFORM_MAX_PATH, "vo/announcer_ends_%isec.mp3", time);
			EmitSoundToAll(sound);
		}
		case 0:
		{
			if(!GetConVarBool(cvarCountdownResult))
			{
				for(int client=1; client<=MaxClients; client++)  //Thx MasterOfTheXP
				{
					if(IsClientInGame(client) && IsPlayerAlive(client))
					{
						ForcePlayerSuicide(client);
					}
				}
			}
			else
			{
				ForceTeamWin(0);  //Stalemate
			}
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!Enabled || !CheckRoundState())
	{
		return Plugin_Continue;
	}

	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	int boss=GetBossIndex(client);
	int damage=GetEventInt(event, "damageamount");
	int custom=GetEventInt(event, "custom");
	// bool changeResult=false;

	if(boss==-1 || !Boss[boss] || !IsValidEntity(Boss[boss]) || client==attacker)
	{
		return Plugin_Continue;
	}

	if(custom==TF_CUSTOM_TELEFRAG)
	{
		damage=IsPlayerAlive(attacker) ? 9001 : 1;
	}
	else if(custom==TF_CUSTOM_BOOTS_STOMP)
	{
		if(IsBoss(attacker))
			damage*=50;

		else
			damage*=5;
	}

	if(GetEventBool(event, "minicrit") && GetEventBool(event, "allseecrit"))
	{
		SetEventBool(event, "allseecrit", false);
	}

	if(custom==TF_CUSTOM_TELEFRAG || custom==TF_CUSTOM_BOOTS_STOMP)
	{
		SetEventInt(event, "damageamount", damage);
	}


	if(BossHealth[boss] - damage < 1 && BossDiff[boss] > 1 &&
		(FF2_GetGameState() != Game_LastManStanding && FF2_GetGameState() != Game_SpecialLastManStanding)
	&& POTRY_IsClientVIP(client) && POTRY_IsClientEnableVIPEffect(client, VIPEffect_BossStandard)) // TODO: 특정인만 가능하게.
	{
		// changeResult = true;
		// BossCharge[boss][0] = 100.0;
		BossDiff[boss] = 1;
		FormulaBossHealth(boss, false);

		SetEntityHealth(client, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1));

		CPrintToChatAll("{olive}[FF2]{default} 이 보스는 {red}보스 스탠다드 플레이{default}가 활성화된 상태입니다. '{green}보통{default}' 난이도로 되돌아가 다시 싸웁니다!");
		SetEventInt(event, "damageamount", 0);
		return Plugin_Changed;
	}



	for(int lives=1; lives<BossLives[boss]; lives++)
	{
		if(BossHealth[boss]-damage<=BossHealthMax[boss]*lives)
		{
			SetEntityHealth(client, (BossHealth[boss]-damage)-BossHealthMax[boss]*(lives-1)); //Set the health early to avoid the boss dying from fire, etc.

			int bossLives = BossLives[boss];  //Used for the forward
			Action action=Plugin_Continue;
			Call_StartForward(OnLoseLife);
			Call_PushCell(boss);
			Call_PushCellRef(bossLives);
			Call_PushCell(BossLivesMax[boss]);
			Call_Finish(action);
			if(action==Plugin_Stop || action==Plugin_Handled)
			{
				return action;
			}
			else if(action==Plugin_Changed)
			{
				if(bossLives>BossLivesMax[boss])
				{
					BossLivesMax[boss]=bossLives;
				}
				BossLives[boss]=bossLives;
			}

			decl String:ability[PLATFORM_MAX_PATH];
			for(int n=1; n<MAXRANDOMS; n++)
			{
				Format(ability, 10, "ability%i", n);
				KvRewind(BossKV[Special[boss]]);
				if(KvJumpToKey(BossKV[Special[boss]], ability))
				{
					if(KvGetNum(BossKV[Special[boss]], "arg0", 0)!=-1)
					{
						continue;
					}

					KvGetString(BossKV[Special[boss]], "life", ability, 10);
					if(!ability[0])
					{
						decl String:abilityName[64], String:pluginName[64];
						KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
						KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
						UseAbility(abilityName, pluginName, boss, -1);
					}
					else
					{
						decl String:stringLives[MAXRANDOMS][3];
						int count=ExplodeString(ability, " ", stringLives, MAXRANDOMS, 3);
						for(int j; j<count; j++)
						{
							if(StringToInt(stringLives[j])==BossLives[boss])
							{
								decl String:abilityName[64], String:pluginName[64];
								KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
								KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
								UseAbility(abilityName, pluginName, boss, -1);
								break;
							}
						}
					}
				}
			}
			BossLives[boss]=lives;

			decl String:bossName[64];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName), "=Failed name=");

			strcopy(ability, sizeof(ability), BossLives[boss]==1 ? "ff2_life_left" : "ff2_lives_left");
			for(int target=1; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
				{
					PrintCenterText(target, "%t", ability, bossName, BossLives[boss]);
				}
			}

			if(BossLives[boss]==1 && RandomSound("sound_last_life", ability, sizeof(ability), boss))
			{
				EmitSoundToAll(ability);
				EmitSoundToAll(ability);
			}
			else if(RandomSound("sound_nextlife", ability, sizeof(ability), boss))
			{
				EmitSoundToAll(ability);
				EmitSoundToAll(ability);
			}

			UpdateHealthBar();
			break;
		}
	}

	BossHealth[boss]-=damage;
	BossCharge[boss][0]+=damage*100.0/BossRageDamage[boss];

	if(BossCharge[boss][0] > BossMaxRageCharge[boss])
	{
		BossCharge[boss][0] = BossMaxRageCharge[boss];
	}

	if(!(FF2ServerFlag & FF2SERVERFLAG_UNCOLLECTABLE_DAMAGE)) Damage[attacker]+=damage;

	int healers[MAXPLAYERS];
	int healerCount;
	for(int target; target<=MaxClients; target++)
	{
		if(IsValidClient(target) && IsPlayerAlive(target) && (GetHealingTarget(target, true)==attacker))
		{
			healers[healerCount]=target;
			healerCount++;
		}
	}

	for(int target; target<healerCount; target++)
	{
		if(IsValidClient(healers[target]) && IsPlayerAlive(healers[target]))
		{
			if(damage<10 || uberTarget[healers[target]]==attacker)
			{
				Damage[healers[target]]+=damage;
			}
			else
			{
				Damage[healers[target]]+=damage/(healerCount+1);
			}
		}
	}

	if(IsValidClient(attacker))
	{
		int weapon=GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
		if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==1104)  //Air Strike-moved from OTD
		{//
			static airStrikeDamage;
			airStrikeDamage+=damage;
			if(airStrikeDamage>=200)
			{
				SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
				airStrikeDamage-=200;
			}
		}
		// 이 코드는 타인의 코드에서 따옴.
		if(!IsBoss(attacker) && IsValidEntity(weapon))
		{
			static kStreakCount;
			kStreakCount+=damage;
			if(kStreakCount>=200)// TODO: 헬 예아.
			{
				SetEntProp(attacker, Prop_Send, "m_nStreaks", GetEntProp(attacker, Prop_Send, "m_nStreaks")+1);
				switch(GetEntProp(attacker, Prop_Send, "m_nStreaks"))
				{
				  case 5, 10, 15, 20, 25, 50, 75, 100, 150, 200, 250, 500, 750, 1000:
				  {
						if(CheckedFirstRound)
						{
							Handle hStreak=CreateEvent("player_death", false);
							SetEventInt(hStreak, "attacker", GetClientUserId(attacker));
							SetEventInt(hStreak, "userid", GetClientUserId(client));
							SetEventInt(hStreak, "death_flags", TF_DEATHFLAG_DEADRINGER);
							SetEventInt(hStreak, "kill_streak_wep", GetEntProp(attacker, Prop_Send, "m_nStreaks"));
							SetEventInt(hStreak, "kill_streak_total", GetEntProp(attacker, Prop_Send, "m_nStreaks"));
							FireEvent(hStreak, true);
						}
				  }
				}
				kStreakCount-=200;
			}
		}
	}

	if(BossCharge[boss][0] > BossMaxRageCharge[boss])
	{
		BossCharge[boss][0] = BossMaxRageCharge[boss];
	}
	// return changeResult ? Plugin_Handled : Plugin_Continue;
	return Plugin_Continue;
}

/*
public void CheckPlayerStun(Handle:datapack)
{
	if(!Enabled || !CheckRoundState())
	{
		return;
	}

	ResetPack(datapack);

	int attacker = ReadPackCell(datapack);
	int entIndex = ReadPackCell(datapack);
	int victim = ReadPackCell(datapack);

	CloseHandle(datapack);

	if(!IsValidEntity(entIndex))
		return;

	TF2_RemoveCondition(victim, TFCond_Dazed);

	float simTime = GetEntPropFloat(entIndex, Prop_Send, "m_flAnimTime");
	Debug("%.1f", simTime);
	float duration = GetConVarFloat(cvarStunRange);

	float realDuration = GetConVarFloat(cvarStunTime) * (simTime / duration);

	if(realDuration > duration)
		realDuration = duration;

	bool bigbonk = (simTime / duration) >= 1.0;

	int flags = bigbonk ?  TF_STUNFLAGS_BIGBONK : TF_STUNFLAGS_SMALLBONK;

	TF2_StunPlayer(victim, realDuration, 0.1, flags, attacker);

	return;
}
*/


public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(!Enabled || !IsValidEntity(attacker))
	{
		return Plugin_Continue;
	}

	static bool:foundDmgCustom, bool:dmgCustomInOTD;
	bool Change=false;

	if(!foundDmgCustom)
	{
		dmgCustomInOTD=(GetFeatureStatus(FeatureType_Capability, "SDKHook_DmgCustomInOTD")==FeatureStatus_Available);
		foundDmgCustom=true;
	}

	if(attacker<=0 || client==attacker)
	{
		if(IsBoss(client))
		{
			if(IsBossYou[client] && attacker > 0)
			{
				BossHealth[GetBossIndex(client)] -= RoundFloat(damage);
				return Plugin_Continue;
			}
			else if(damagetype & DMG_FALL)
			{
				damage = 1.0;
				return Plugin_Changed;
			}
			return Plugin_Handled;
		}
	}

	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
	{
		return Plugin_Continue;
	}

	if(!CheckRoundState() && IsBoss(client))
	{
		damage*=0.0;
		return Plugin_Changed;
	}

	float position[3];
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);
	if(IsBoss(attacker))
	{
		if(IsValidClient(client) && !IsBoss(client) && !TF2_IsPlayerInCondition(client, TFCond_Bonked))
		{
			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
			{
				ScaleVector(damageForce, 9.0);
				damage*=0.3;
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffMmmph))
			{
				damage*=9;
				TF2_AddCondition(client, TFCond_Bonked, 0.1);
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
			{
				damage*=0.25;
				return Plugin_Changed;
			}

			if(shield[client] && damage > 30.0)
			{
				Change=true;

				if(IsDemoShield(shield[client]) && GetEntPropFloat(client, Prop_Send, "m_flChargeMeter") > 3.0)
				{
					float chargedamage = damage * 0.5;

					StingShield(client, attacker, position);

					if(GetEntPropFloat(client, Prop_Send, "m_flChargeMeter") >= chargedamage)
					{
						damage -= chargedamage;

						SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", GetEntPropFloat(client, Prop_Send, "m_flChargeMeter") - chargedamage);

					}
					else
					{
						float mustdamaged = chargedamage - GetEntPropFloat(client, Prop_Send, "m_flChargeMeter");

						damage -= mustdamaged;

						SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", 0.0);
					}
				}
				else
				{
					RemoveShield(client, attacker, position);
					return Plugin_Handled;
				}

				// damage *= (0.75 - ((GetEntPropFloat(client, Prop_Send, "m_flChargeMeter") / 100.0) / 4.0));




			}

			if(TF2_GetPlayerClass(client)==TFClass_Soldier && IsValidEntity((weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)))
			&& GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==226 && !(FF2flags[client] & FF2FLAG_ISBUFFED))  //Battalion's Backup
			{
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
			}

			if(damagecustom == TF_CUSTOM_BOOTS_STOMP)
			{
				damage*=13.0;
				Change=true;
			}
/*
			if(damage<=160.0)  //TODO: Wat
			{
				damage*=3;
				return Plugin_Changed;
			}
*/
		}
	}
	else
	{
		int boss=GetBossIndex(client);
		if(boss!=-1)
		{
			if(attacker<=MaxClients)
			{
				bool bIsTelefrag, bIsBackstab, bIsFacestab;
				if(dmgCustomInOTD)
				{
					decl String:classname[32];

					if(damagecustom==TF_CUSTOM_BACKSTAB)
					{
						bIsBackstab=true;
					}
					else if(FF2Userflags[attacker] & FF2USERFLAG_ALLOW_FACESTAB &&
					IsValidEntity(weapon) && GetEntityClassname(weapon, classname, sizeof(classname)) &&
						!StrContains(classname, "tf_weapon_knife", false) && !(damagecustom & TF_CUSTOM_BACKSTAB))
					{
						bIsFacestab=true;
					}
					else if(damagecustom==TF_CUSTOM_TELEFRAG)
					{
						bIsTelefrag=true;
					}
				}
				else if(weapon!=4095 && IsValidEntity(weapon) && weapon==GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) && damage>1000.0)
				{
					decl String:classname[32];
					if(GetEntityClassname(weapon, classname, sizeof(classname)) && !StrContains(classname, "tf_weapon_knife", false))
					{
						bIsBackstab=true;
					}
				}
				else if(!IsValidEntity(weapon) && (damagetype & DMG_CRUSH)==DMG_CRUSH && damage==1000.0)
				{
					bIsTelefrag=true;
				}
				/////////////////
				if(GetClientButtons(client) & IN_DUCK && GetEntityFlags(client) & FL_ONGROUND)
				{
					Change=true;
					damagetype|=DMG_PREVENT_PHYSICS_FORCE;
				}
				////////////////

				if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
				{
					Change=true;
					damagetype |= ~DMG_CRIT;
				}
/*
				if(BossHealth[boss] - RoundFloat(damage) <= 0 && BossDiff[boss] != 1)
				{
					return Plugin_Handled;
				} */

				int index;
				decl String:classname[64];
				if(IsValidEntity(weapon) && weapon>MaxClients && attacker<=MaxClients)
				{
					GetEntityClassname(weapon, classname, sizeof(classname));
					if(!StrContains(classname, "eyeball_boss"))  //Dang spell Monoculuses
					{
						index=-1;
						Format(classname, sizeof(classname), "");
					}
					else
					{
						index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
					}
				}
				else
				{
					index=-1;
					Format(classname, sizeof(classname), "");
				}

				//Sniper rifles aren't handled by the switch/case because of the amount of reskins there are
				if(!StrContains(classname, "tf_weapon_sniperrifle"))
				{
					if(CheckRoundState()!=2)
					{
						float charge=(IsValidEntity(weapon) && weapon>MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
						if(index==752)  //Hitman's Heatmaker
						{
							float focus=10+(charge/10);
							if(TF2_IsPlayerInCondition(attacker, TFCond_FocusBuff))
							{
								focus/=3;
							}
							float rage=GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
							SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage+focus>100) ? 100.0 : rage+focus);
						}
						else if(index!=230 && index!=402 && index!=526 && index!=30665)  //Sydney Sleeper, Bazaar Bargain, Machina, Shooting Star
						{
							float time=(GlowTimer[boss]>10 ? 1.0 : 2.0);
							time+=(GlowTimer[boss]>10 ? (GlowTimer[boss]>20 ? 1.0 : 2.0) : 4.0)*(charge/100.0);
							SetClientGlow(Boss[boss], time);
							if(GlowTimer[boss]>30.0)
							{
								GlowTimer[boss]=30.0;
							}
						}

						if(!(damagetype & DMG_CRIT))
						{
							if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
							{
								damage*=3.0;
							}
							else
							{
								float clientPos[3];
								float attackerPos[3];
								GetClientEyePosition(client, clientPos);
								GetClientEyePosition(attacker, attackerPos);

								if(GetVectorDistance(clientPos, attackerPos) > 700.0)
								{
									damagetype|=DMG_PREVENT_PHYSICS_FORCE;
								}

								if(index!=230)  //Sydney Sleeper
								{
									damage *= damagecustom == TF_CUSTOM_HEADSHOT ? 3.5 : 1.8;
								}
								else
								{
									if(damagecustom & TF_CUSTOM_HEADSHOT)
									{
										BossCharge[boss][0] -= 8.0;

										if(BossCharge[boss][0] < 0.0)
										{
											BossCharge[boss][0] = 0.0;
										}
									}

									damage*=damagecustom == TF_CUSTOM_HEADSHOT ? 3.5 : 1.8;
								}
							}
							return Plugin_Changed;
						}
						else
						{
							damage *= damagecustom == TF_CUSTOM_HEADSHOT ? 1.5 : 1.0;
							return Plugin_Changed;
						}
					}
				} // tf_weapon_stickbomb
				if(!StrContains(classname, "tf_weapon_stickbomb"))
				{
					if(damagetype & DMG_CRIT)
					{
						Change=true;
						ScaleVector(damageForce, 0.5);
					}
				}

				if(TF2_GetPlayerClass(attacker) == TFClass_Heavy)
				{
					// if(!(damagetype & DMG_CRIT))
					Change=true;
					ScaleVector(damageForce, 1.5);
				}

				if (IsValidEntity(inflictor))
				{
					GetEntityClassname(inflictor, classname, sizeof(classname));
					int weaponIdx = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
					if ((!strcmp("obj_sentrygun", classname)) || weaponIdx == 140) // included wrangler just in case
					{
						Change = true;

						int sentryCount = 0;
						int ent = -1;
						int clientTeam = GetClientTeam(attacker);

						while((ent = FindEntityByClassname(ent, "obj_sentrygun")) != -1)
						{
							if(GetEntProp(ent, Prop_Send, "m_iTeamNum") == clientTeam)
							{
								sentryCount++;
							}
						}

						if(sentryCount > 4)
						{
							damagetype|=DMG_PREVENT_PHYSICS_FORCE;
						}
						else if(sentryCount > 1)
						{
							ScaleVector(damageForce, 1.0/float(sentryCount));
						}
						else
						{
							Change = false;
						}
					}
				}
/*
				if(IsValidEntity(inflictor))
				{
					char inflictorClassname[64];
					GetEntityClassname(inflictor, inflictorClassname, sizeof(inflictorClassname));

					if(!StrContains(inflictorClassname, "tf_projectile_stun_ball", false))
					{
						Handle datapack = CreateDataPack();
						// attacker, entindex, victim

						WritePackCell(datapack, attacker);
						WritePackCell(datapack, inflictor);
						WritePackCell(datapack, client);

						// ResetPack(datapack);

						RequestFrame(CheckPlayerStun, CloneHandle(datapack));
						CloseHandle(datapack);
					}
				}
*/

				switch(index)
				{
					case 61, 1006:  //Ambassador, Festive Ambassador
					{
						if(damagecustom==TF_CUSTOM_HEADSHOT)
						{
							if(damage<85.0)	damage=85.0;  //Final damage 255
							return Plugin_Changed;
						}
					}
					case 132, 266, 482, 1082:  //Eyelander, HHHH, Nessie's Nine Iron, Festive Eyelander
					{
						IncrementHeadCount(attacker);
					}
					case 153:
					{
						/*
						if(TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping)) //TFCond_BlastJumping
						{
							char playerName[50];
							GetClientName(attacker, playerName, sizeof(playerName));

							TF2_StunPlayer(client, 5.0, 1.00, TF_STUNFLAGS_BIGBONK, attacker);
							CPrintToChatAll("{olive}[FF2]{default} %s님이 {orangered}가정파괴범{default}으로 보스를 5초 기절시킵니다!", playerName);
							// TF_STUNFLAGS_BIGBONK
						}
						*/
					}
					case 214:  //Powerjack
					{
						int health=GetClientHealth(attacker);
						int newhealth=health+50;
						if(newhealth<=GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						{
							SetEntityHealth(attacker, newhealth);
						}

						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}
					}
					case 310:  //Warrior's Spirit
					{
						int health=GetClientHealth(attacker);
						int newhealth=health+50;
						if(newhealth<=GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						{
							SetEntityHealth(attacker, newhealth);
						}

						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}
					}
					case 317:  //Candycane
					{
						SpawnSmallHealthPackAt(client, GetClientTeam(attacker));
					}
					case 327:  //Claidheamh Mòr
					{
						int health=GetClientHealth(attacker);
						int newhealth=health+25;
						if(newhealth<=GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						{
							SetEntityHealth(attacker, newhealth);
						}

						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}

						float charge=GetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter");
						if(charge+25.0>=100.0)
						{
							SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", 100.0);
						}
						else
						{
							SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", charge+25.0);
						}
					}
					case 355:  //Fan O' War
					{
						if(BossCharge[boss][0]>0.0)
						{
							BossCharge[boss][0]-=6.0;
							if(BossCharge[boss][0]<0.0)
							{
								BossCharge[boss][0]=0.0;
							}
						}
					}
					case 357:  //Half-Zatoichi
					{
						SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
						if(GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy")<1)
						{
							SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
						}

						int health=GetClientHealth(attacker);
						int max=GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						int newhealth=health+50;
						if(health<max+100)
						{
							if(newhealth>max+100)
							{
								newhealth=max+100;
							}
							SetEntityHealth(attacker, newhealth);
						}
						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}
					}
					case 460: // 집행자
					{
						float cloakmeter = GetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter") - 8.0;
						if(cloakmeter < 0.0)
						{
							cloakmeter = 0.0;
						}
						SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", cloakmeter);
					}
					case 307, 416:  //Market Gardener (courtesy of Chdata) and 울라풀 막대
					{
						if(FF2Userflags[attacker] & FF2USERFLAG_ALLOW_GROUNDMARKET || TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping)) //TFCond_BlastJumping
						{
							if(index == 307 && GetEntProp(weapon, Prop_Send, "m_iDetonated") == 1)
								return Plugin_Continue;

							bool bIsGroundMarket = FF2Userflags[attacker] & FF2USERFLAG_ALLOW_GROUNDMARKET && !TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping) && index!=307;

							char playerName[50];
							GetClientName(attacker, playerName, sizeof(playerName));

							char bossName[64];
							KvRewind(BossKV[Special[boss]]);
							KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName), "ERROR NAME");

							damage=(((float(BossHealthMax[boss])*float(BossLivesMax[boss]))*0.07)/3.0);
							damagetype|=DMG_CRIT;

							if(damage < 200.0)
								damage = 200.0;
							if(bIsGroundMarket)
								damage /= 2.0;

							Action action;
							float tempDamage = damage * 3.0;
							int tempAttacker = attacker;

							Call_StartForward(OnTakePercentDamage);
							Call_PushCell(client);
							Call_PushCellRef(tempAttacker);
							Call_PushCell(index==307 ? Percent_Ullapool : bIsGroundMarket ? Percent_GroundMarketed : Percent_Marketed);
							Call_PushFloatRef(tempDamage);
							Call_Finish(action);

							if(action == Plugin_Changed)
							{
								attacker = tempAttacker;
								damage = tempDamage / 3.0;
							}
							else if(action == Plugin_Handled)
							{
								return Plugin_Handled;
							}

							Call_StartForward(OnTakePercentDamagePost);
							Call_PushCell(client);
							Call_PushCell(attacker);
							Call_PushCell(index==307 ? Percent_Ullapool : bIsGroundMarket ? Percent_GroundMarketed : Percent_Marketed);
							Call_PushCell(damage);
							Call_Finish();

							if(CheckedFirstRound)
							{
								Handle hStreak = CreateEvent("player_death", false);
								SetEventString(hStreak, "weapon", index==307 ? "ullapool_caber_explosion" : "market_gardener");
								SetEventString(hStreak, "weapon_logclassname", index==307 ? "ullapool_caber_explosion" : "market_gardener");
								SetEventInt(hStreak, "attacker", GetClientUserId(attacker));
								SetEventInt(hStreak, "userid", GetClientUserId(client));
								SetEventInt(hStreak, "death_flags", TF_DEATHFLAG_DEADRINGER);
								SetEventInt(hStreak, "kill_streak_wep", ++Marketed[attacker]);
								FireEvent(hStreak);
							}

							PrintHintText(attacker, "%t", index==307 ? "Ullapool" : "Market Gardener");  //You just market-gardened the boss!
							PrintHintText(client, "%t", index==307 ? "Ullapooled" : "Market Gardened");  //You just got market-gardened!


							CPrintToChatAll("{olive}[FF2]{default} %t", "Someone_do", playerName, index==307 ? "울라풀 막대 공격" : bIsGroundMarket ? "지면 마켓가든" : "마켓가든", bossName, RoundFloat(damage*(255.0/85.0)), Marketed[attacker]);
							EmitSoundToClient(attacker, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);
							EmitSoundToClient(client, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);

							if(index==307 && allowedDetonations-(++detonations[attacker]))
							{
								PrintHintText(attacker, "%t", "Detonations Left", allowedDetonations-detonations[attacker]);
								SetEntProp(weapon, Prop_Send, "m_bBroken", 0);
								SetEntProp(weapon, Prop_Send, "m_iDetonated", 0);
							}
							return Plugin_Changed;
						}
						else return Plugin_Continue;
					}
					case 525, 595:  //Diamondback, Manmelter
					{
						if(GetEntProp(attacker, Prop_Send, "m_iRevengeCrits"))  //If a revenge crit was used, give a damage bonus
						{
							damage=85.0;  //255 final damage
							return Plugin_Changed;
						}
					}
					case 528:  //Short Circuit
					{
						if(circuitStun)
						{
							TF2_StunPlayer(client, circuitStun, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
							EmitSoundToAll("weapons/barret_arm_zap.wav", client);
							EmitSoundToClient(client, "weapons/barret_arm_zap.wav");
						}
					}
					case 593:  //Third Degree
					{
						int healers[MAXPLAYERS];
						int healerCount;
						for(int healer; healer<=MaxClients; healer++)
						{
							if(IsValidClient(healer) && IsPlayerAlive(healer) && (GetHealingTarget(healer, true)==attacker))
							{
								healers[healerCount]=healer;
								healerCount++;
							}
						}

						for(int healer; healer<healerCount; healer++)
						{
							if(IsValidClient(healers[healer]) && IsPlayerAlive(healers[healer]))
							{
								int medigun=GetPlayerWeaponSlot(healers[healer], TFWeaponSlot_Secondary);
								if(IsValidEntity(medigun))
								{
									decl String:medigunClassname[64];
									GetEntityClassname(medigun, medigunClassname, sizeof(medigunClassname));
									if(StrEqual(medigunClassname, "tf_weapon_medigun", false))
									{
										float uber=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+(0.1/healerCount);
										if(uber>1.0)
										{
											uber=1.0;
										}
										SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);
									}
								}
							}
						}
					}
					case 594:  //Phlogistinator
					{
						if(!TF2_IsPlayerInCondition(attacker, TFCond_CritMmmph))
						{
							damage/=2.0;
							return Plugin_Changed;
						}
					}
					case 1099:  //Tide Turner
					{
						SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", 100.0);
					}


					/*case 1104:  //Air Strike-moved to OnPlayerHurt for now since OTD doesn't display the actual damage :/
					{
						static Float:airStrikeDamage;
						airStrikeDamage+=damage;
						if(airStrikeDamage>=200.0)
						{
							SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
							airStrikeDamage-=200.0;
						}
					}*/
				}

				if(bIsBackstab || bIsFacestab)
				{
					float sliencedTime=6.0; // TODO: 광역변수.
					bool slienced=false;

					damage=(((float(BossHealthMax[boss])*float(BossLivesMax[boss]))*0.075)/3.0);

					if(damage < 200.0)
					{
						damage = 500.0;
					}
					if(bIsFacestab)
					{
						damage /= 2.0;
					}

					damagetype|=DMG_CRIT;
					damagecustom=0;


					EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
					EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
					EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+2.0);

					int viewmodel=GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
					if(viewmodel>MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker)==TFClass_Spy)
					{
						int melee=GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
						int animation=41;
						switch(melee)
						{
							case 225, 356, 423, 461, 574, 649, 1071:  //Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan
							{
								animation=15;
							}
							case 638:  //Sharp Dresser
							{
								animation=31;
							}
						}
						SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
					}

					if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(attacker, "%t", "Backstab");
					}

					if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(client, "%t", "Backstabbed");
					}

					if(index==225 || index==574 || bIsFacestab)  //Your Eternal Reward, Wanga Prick
					{
						slienced=true;
						BossAbilityCooldown[boss][0] += sliencedTime;
						CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
					}
					else if(index==356)  //Conniver's Kunai
					{
						int health=GetClientHealth(attacker)+200;
						if(health>500)
						{
							health=500;
						}
						SetEntityHealth(attacker, health);
					}
					else if(index==461)  //Big Earner
					{
						SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", 100.0);  //Full cloak
						TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0);  //Speed boost
					}
					else if(index == 4 ||
					index == 194 ||
					index == 665 ||
					index == 727 ||
					index == 794 ||
					index == 803 ||
					index == 883 ||
					index == 892 ||
					index == 901 ||
					index == 910 ||
					index == 959 ||
					index == 968 ||
					index == 1071)
					{
						damage+=500.0/3.0;
					}

					if(GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary)==525)  //Diamondback
					{
						SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits")+2);
					}

					decl String:sound[PLATFORM_MAX_PATH];
					if(RandomSound("sound_stabbed", sound, sizeof(sound), boss))
					{
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, Boss[boss], _, _, false);
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, Boss[boss], _, _, false);
					}

					Action action;
					float tempDamage = damage * 3.0;
					int tempAttacker = attacker;

					Call_StartForward(OnTakePercentDamage);
					Call_PushCell(client);
					Call_PushCellRef(tempAttacker);
					Call_PushCell(bIsFacestab ? Percent_Facestab : Percent_Backstab);
					Call_PushFloatRef(tempDamage);
					Call_Finish(action);

					if(action == Plugin_Changed)
					{
						attacker = tempAttacker;
						damage = tempDamage / 3.0;
					}
					else if(action == Plugin_Handled)
					{
						return Plugin_Handled;
					}

					Call_StartForward(OnTakePercentDamagePost);
					Call_PushCell(client);
					Call_PushCell(attacker);
					Call_PushCell(bIsFacestab ? Percent_Facestab : Percent_Backstab);
					Call_PushCell(damage);
					Call_Finish();

					if(CheckedFirstRound)
					{
					 	Handle hStreak = CreateEvent("player_death", false);
					 	SetEventString(hStreak, "weapon", "knife");
					 	SetEventString(hStreak, "weapon_logclassname", "backstab");
					 	SetEventInt(hStreak, "attacker", GetClientUserId(attacker));
					 	SetEventInt(hStreak, "userid", GetClientUserId(client));
					 	SetEventInt(hStreak, "death_flags", TF_DEATHFLAG_DEADRINGER);
					 	SetEventInt(hStreak, "kill_streak_wep", ++Stabbed[attacker]);
				 		FireEvent(hStreak);
					}

					char playerName[50];
					GetClientName(attacker, playerName, sizeof(playerName));

					char bossName[64];
					KvRewind(BossKV[Special[boss]]);
					KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName), "ERROR NAME");

					CPrintToChatAll("{olive}[FF2]{default} %t", "Someone_do", playerName, bIsFacestab ? "페이스스탭" : "백스탭", bossName, RoundFloat(damage*(255.0/85.0)), Stabbed[attacker]);
					if(slienced) CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_slienced", RoundFloat(BossAbilityCooldown[boss][0]));
					return Plugin_Changed;
				}
				else if(bIsTelefrag)
				{
					damagecustom=0;
					if(!IsPlayerAlive(attacker))
					{
						damage=1.0;
						return Plugin_Changed;
					}
					damage=(BossHealth[boss]>9001 ? 9001.0 : float(GetEntProp(Boss[boss], Prop_Send, "m_iHealth"))+90.0);

					int teleowner=FindTeleOwner(attacker);
					if(IsValidClient(teleowner) && teleowner!=attacker)
					{
						Damage[teleowner]+=9001*3/5;
						if(!(FF2flags[teleowner] & FF2FLAG_HUDDISABLED))
						{
							PrintHintText(teleowner, "텔레프래그 어시스트! 설치 잘하셨어요!");
						}
					}

					if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(attacker, "텔레프래그! 프로군요!");
					}

					if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
					{
						PrintHintText(client, "텔레프래그! 주변에 돌아가는 물체를 조심하세요!");
					}
					return Plugin_Changed;
				}
			}
			else
			{
				decl String:classname[64];
				if(GetEntityClassname(attacker, classname, sizeof(classname)) && !strcmp(classname, "trigger_hurt", false))
				{
					Action action=Plugin_Continue;
					Call_StartForward(OnTriggerHurt);
					Call_PushCell(boss);
					Call_PushCell(attacker);
					float damage2=damage;
					Call_PushFloatRef(damage2);
					Call_Finish(action);
					if(action!=Plugin_Stop && action!=Plugin_Handled)
					{
						if(action==Plugin_Changed)
						{
							damage=damage2;
						}

						if(damage>1500.0)
						{
							damage=1500.0;
						}

						if(!strcmp(currentmap, "arena_arakawa_b3", false) && damage>1000.0)
						{
							damage=490.0;
						}
						BossHealth[boss]-=RoundFloat(damage);
						BossCharge[boss][0]+=damage*100.0/BossRageDamage[boss];
						if(BossHealth[boss]<=0)  //Wat
						{
							damage*=5;
						}

						if(BossCharge[boss][0] > BossMaxRageCharge[boss])
						{
							BossCharge[boss][0] = BossMaxRageCharge[boss];
						}
						return Plugin_Changed;
					}
					else
					{
						return action;
					}
				}
			}

			if(BossCharge[boss][0] > BossMaxRageCharge[boss])
			{
				BossCharge[boss][0] = BossMaxRageCharge[boss];
			}
		}
		else
		{
			int index=(IsValidEntity(weapon) && weapon>MaxClients && attacker<=MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if(index==307)  //Ullapool Caber
			{
				if(detonations[attacker]<allowedDetonations)
				{
					detonations[attacker]++;
					PrintHintText(attacker, "%t", "Detonations Left", allowedDetonations-detonations[attacker]);
					if(allowedDetonations-detonations[attacker])  //Don't reset their caber if they have 0 detonations left
					{
						SetEntProp(weapon, Prop_Send, "m_bBroken", 0);
						SetEntProp(weapon, Prop_Send, "m_iDetonated", 0);
					}
				}
			}

			if(IsValidClient(client, false) && TF2_GetPlayerClass(client)==TFClass_Soldier)  //TODO: LOOK AT THIS
			{
				if(damagetype & DMG_FALL)
				{
					int secondary=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(secondary<=0 || !IsValidEntity(secondary))
					{
						damage/=8.0;
						return Plugin_Changed;
					}
				}
			}
		}
	}
	return Change ? Plugin_Changed : Plugin_Continue;
}

public Action:TF2_OnPlayerTeleport(client, teleporter, &bool:result)
{
	if(Enabled && IsBoss(client))
	{
		switch(bossTeleportation)
		{
			case -1:  //No bosses are allowed to use teleporters
			{
				result=false;
			}
			case 1:  //All bosses are allowed to use teleporters
			{
				result=true;
			}
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower, &combo)
{
	if(!Enabled || !IsValidClient(attacker) || !IsValidClient(victim) || attacker==victim)
	{
		return Plugin_Continue;
	}

	if(IsBoss(attacker))
	{
		/*
		if(shield[victim])
		{
			float position[3];
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);

			RemoveShield(victim, attacker, position);
			return Plugin_Handled;
		}
		*/
		damageMultiplier=900.0;
		JumpPower=0.0;
		return Plugin_Changed;
	}
	else if(IsBoss(victim) && GoombaDamage > 0.0) // TODO: 굼바 플러그인 내의 데미지 고정 삭제
	{
		Call_StartForward(OnTakePercentDamagePost);
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_PushCell(Percent_Goomba);
		Call_PushCell(damageBonus);
		Call_Finish();

		char playerName[50];
		GetClientName(attacker, playerName, sizeof(playerName));

		if(CheckedFirstRound)
		{
			Handle hStreak = CreateEvent("player_death", false);
			SetEventString(hStreak, "weapon", "mantreads");
			SetEventString(hStreak, "weapon_logclassname", "mantreads");
			SetEventInt(hStreak, "attacker", GetClientUserId(attacker));
			SetEventInt(hStreak, "userid", GetClientUserId(victim));
			SetEventInt(hStreak, "death_flags", TF_DEATHFLAG_DEADRINGER);
			SetEventInt(hStreak, "kill_streak_wep", combo);
			FireEvent(hStreak);
		}

		damageMultiplier=1.0;
		JumpPower=reboundPower;
		PrintHintText(victim, "%t", "ff2_goomba_boss");
		PrintHintText(attacker, "%t", "ff2_goomba_user");

		char bossName[64];
		KvRewind(BossKV[Special[GetBossIndex(victim)]]);
		KvGetString(BossKV[Special[GetBossIndex(victim)]], "name", bossName, sizeof(bossName), "ERROR NAME");

		CPrintToChatAll("{olive}[FF2]{default} %t", "Someone_do", playerName, "굼바 스톰프", bossName, !TF2_IsPlayerInCondition(attacker, TFCond_Buffed) ? 180*combo : 243*combo, combo); // 굼바 데미지는 굼바 플러그인에서 고정데미지로 정함.
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnStompPost(attacker, victim, Float:damageMultiplier, Float:damageBonus, Float:jumpPower, combo)
{
	if(Enabled && IsBoss(victim))
	{
		UpdateHealthBar();
	}
}

public Action:RTD_CanRollDice(client)
{
	if(Enabled && IsBoss(client) && !canBossRTD)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnGetMaxHealth(client, &maxHealth)
{
	if(Enabled && IsBoss(client))
	{
		int boss=GetBossIndex(client);
		SetEntityHealth(client, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1));
		maxHealth=BossHealthMax[boss];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock TF2_IsPlayerCritBuffed(client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, TFCond:34) || TF2_IsPlayerInCondition(client, TFCond:35) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph));
}

public Action:Timer_DisguiseBackstab(Handle:timer, any:userid)
{
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client, false))
	{
		RandomlyDisguise(client);
	}
	return Plugin_Continue;
}

stock AssignTeam(client, team)
{
	if(!GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))  //Living spectator check: 0 means that no class is selected
	{
		Debug("%N does not have a desired class!", client);
		if(IsBoss(client))
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", KvGetNum(BossKV[Special[Boss[client]]], "class", 1));  //So we assign one to prevent living spectators
		}
		else
		{
			Debug("%N was not a boss and did not have a desired class!  Please report this to https://github.com/50DKP/FF2-Official");
		}
	}

	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	TF2_RespawnPlayer(client);

	if(GetEntProp(client, Prop_Send, "m_iObserverMode") && IsPlayerAlive(client))  //Welp
	{
		Debug("%N is a living spectator!  Please report this to https://github.com/50DKP/FF2-Official", client);
		if(IsBoss(client))
		{
			TF2_SetPlayerClass(client, TFClassType:KvGetNum(BossKV[Special[Boss[client]]], "class", 1));
		}
		else
		{
			Debug("Additional information: %N was not a boss");
			TF2_SetPlayerClass(client, TFClass_Scout);
		}
		TF2_RespawnPlayer(client);
	}
}

stock GetClientWithMostQueuePoints(bool:omit[])
{
	int winner;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && GetClientQueuePoints(client)>=GetClientQueuePoints(winner) && !omit[client])
		{
			if(SpecForceBoss || GetClientTeam(client)>_:TFTeam_Spectator)
			{
				winner=client;
			}
		}
	}
	return winner;
}

stock LastBossIndex()
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(!Boss[client])
		{
			return client-1;
		}
	}
	return 0;
}

stock GetBossIndex(client)
{
	if(client == 0)
	{
		return MainBoss;
	}

	if(client>0 && client<=MaxClients)
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(Boss[boss]==client)
			{
				return boss;
			}
		}
	}
	return -1;
}

stock Operate(Handle:sumArray, &bracket, Float:value, Handle:_operator)
{
	float sum=GetArrayCell(sumArray, bracket);
	switch(GetArrayCell(_operator, bracket))
	{
		case Operator_Add:
		{
			SetArrayCell(sumArray, bracket, sum+value);
		}
		case Operator_Subtract:
		{
			SetArrayCell(sumArray, bracket, sum-value);
		}
		case Operator_Multiply:
		{
			SetArrayCell(sumArray, bracket, sum*value);
		}
		case Operator_Divide:
		{
			if(!value)
			{
				LogError("[FF2 Bosses] Detected a divide by 0!");
				bracket=0;
				return;
			}
			SetArrayCell(sumArray, bracket, sum/value);
		}
		case Operator_Exponent:
		{
			SetArrayCell(sumArray, bracket, Pow(sum, value));
		}
		default:
		{
			SetArrayCell(sumArray, bracket, value);  //This means we're dealing with a constant
		}
	}
	SetArrayCell(_operator, bracket, Operator_None);
}

stock OperateString(Handle:sumArray, &bracket, String:value[], size, Handle:_operator)
{
	if(!StrEqual(value, ""))  //Make sure 'value' isn't blank
	{
		Operate(sumArray, bracket, StringToFloat(value), _operator);
		strcopy(value, size, "");
	}
}

stock ParseFormula(boss, const String:key[], const String:defaultFormula[], defaultValue)
{
	decl String:formula[1024], String:bossName[64];
	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName), "=Failed name=");
	KvGetString(BossKV[Special[boss]], key, formula, sizeof(formula), defaultFormula);

	int size=1;
	int matchingBrackets;
	for(int i; i<=strlen(formula); i++)  //Resize the arrays once so we don't have to worry about it later on
	{
		if(formula[i]=='(')
		{
			if(!matchingBrackets)
			{
				size++;
			}
			else
			{
				matchingBrackets--;
			}
		}
		else if(formula[i]==')')
		{
			matchingBrackets++;
		}
	}

	Handle sumArray = CreateArray(_, size);
	Handle _operator = CreateArray(_, size);
	int bracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	SetArrayCell(sumArray, 0, 0.0);  //TODO:  See if these can be placed naturally in the loop
	SetArrayCell(_operator, bracket, Operator_None);

	char character[2], value[16];  //We don't decl value because we directly append characters to it and there's no point in decl'ing character
	for(int i; i<=strlen(formula); i++)
	{
		character[0]=formula[i];  //Find out what the next char in the formula is
		switch(character[0])
		{
			case ' ', '\t':  //Ignore whitespace
			{
				continue;
			}
			case '(':
			{
				bracket++;  //We've just entered a new parentheses so increment the bracket value
				SetArrayCell(sumArray, bracket, 0.0);
				SetArrayCell(_operator, bracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				if(GetArrayCell(_operator, bracket)!=Operator_None)  //Something like (5*)
				{
					LogError("[FF2 Bosses] %s's %s formula has an invalid operator at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}

				if(--bracket<0)  //Something like (5))
				{
					LogError("[FF2 Bosses] %s's %s formula has an unbalanced parentheses at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}

				Operate(sumArray, bracket, GetArrayCell(sumArray, bracket+1), _operator);
			}
			case '\0':  //End of formula
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(value, sizeof(value), character);  //Constant?  Just add it to the current value
			}
			case 'n', 'x':  //n and x denote player variables
			{
				Operate(sumArray, bracket, float(playing), _operator);
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				switch(character[0])
				{
					case '+':
					{
						SetArrayCell(_operator, bracket, Operator_Add);
					}
					case '-':
					{
						SetArrayCell(_operator, bracket, Operator_Subtract);
					}
					case '*':
					{
						SetArrayCell(_operator, bracket, Operator_Multiply);
					}
					case '/':
					{
						SetArrayCell(_operator, bracket, Operator_Divide);
					}
					case '^':
					{
						SetArrayCell(_operator, bracket, Operator_Exponent);
					}
				}
			}
		}
	}

	int result=RoundFloat(GetArrayCell(sumArray, 0));
	CloseHandle(sumArray);
	CloseHandle(_operator);
	if(result<=0)
	{
		LogError("[FF2] %s has an invalid %s formula, using default!", bossName, key);
		return defaultValue;
	}

	if(bMedieval)
	{
		return RoundFloat(result/3.6);  //TODO: Make this configurable
	}
	return result;
}

stock GetAbilityArgument(index,const String:plugin_name[],const String:ability_name[],arg,defvalue=0)
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
		return 0;
	KvRewind(BossKV[Special[index]]);
	decl String:s[10];
	for(int i=1; i<MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if(KvJumpToKey(BossKV[Special[index]],s))
		{
			if(IsUpgradeRage[index])
			{
				if(KvGetNum(BossKV[Special[index]], "is_upgrade_rage", 0) <= 0)
					continue;
			}
			else
			{
				if(KvGetNum(BossKV[Special[index]], "is_upgrade_rage", 0) > 0)
					continue;
			}

			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if(strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			decl String:plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name,plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s,10,"arg%i",arg);
			return KvGetNum(BossKV[Special[index]], s,defvalue);
		}
	}
	return 0;
}

stock Float:GetAbilityArgumentFloat(index,const String:plugin_name[],const String:ability_name[],arg,Float:defvalue=0.0)
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
		return 0.0;
	KvRewind(BossKV[Special[index]]);
	decl String:s[10];
	for(int i=1; i<MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if(KvJumpToKey(BossKV[Special[index]],s))
		{
			if(IsUpgradeRage[index])
			{
				if(KvGetNum(BossKV[Special[index]], "is_upgrade_rage", 0) <= 0)
					continue;
			}
			else
			{
				if(KvGetNum(BossKV[Special[index]], "is_upgrade_rage", 0) > 0)
					continue;
			}

			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if(strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			decl String:plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name,plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s,10,"arg%i",arg);
			float see=KvGetFloat(BossKV[Special[index]], s,defvalue);
			return see;
		}
	}
	return 0.0;
}

stock GetAbilityArgumentString(index,const String:plugin_name[],const String:ability_name[],arg,String:buffer[],buflen,const String:defvalue[]="")
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
	{
		strcopy(buffer,buflen,"");
		return;
	}
	KvRewind(BossKV[Special[index]]);
	decl String:s[10];
	for(int i=1; i<MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if(KvJumpToKey(BossKV[Special[index]],s))
		{
			if(IsUpgradeRage[index])
			{
				if(KvGetNum(BossKV[Special[index]], "is_upgrade_rage", 0) <= 0)
					continue;
			}
			else
			{
				if(KvGetNum(BossKV[Special[index]], "is_upgrade_rage", 0) > 0)
					continue;
			}

			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if(strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			decl String:plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name,plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s,10,"arg%i",arg);
			KvGetString(BossKV[Special[index]], s,buffer,buflen,defvalue);
		}
	}
}

public void GetSoundCode(String:musicPath[],  String:codeString[], int buffer)
{
	if(musicPath[0] == '\0')
		return;

	// int boss = MainBoss;
	// Handle clonedHandle = CloneHandle(BossKV[Special[boss]]);
	int sizeString = strlen(musicPath);
	// int startcount = strlen(codeString) - 1;
	// char code[1];

	Format(codeString, buffer, "%i-%s", sizeString, musicPath[sizeString - 15]);
	/*
	for(int count=startcount; count > startcount - 30; count--)
	{
		if(strlen(codeString) >= buffer || sizeString < (startcount - count))
		{
			break;
		}

		// int code = view_as<int>(musicPath[count]);
		Format(code, 1, "%c", musicPath[count]);
		Format(codeString, buffer, "%s%d", codeString, code);
	}
	*/
}

stock bool:RandomSound(const String:sound[], String:file[], length, boss=0)
{
	if(boss<0 || Special[boss]<0 || !BossKV[Special[boss]])
	{
		return false;
	}

	KvRewind(BossKV[Special[boss]]);
	if(!KvJumpToKey(BossKV[Special[boss]], sound))
	{
		KvRewind(BossKV[Special[boss]]);
		return false;  //Requested sound not implemented for this boss
	}

	decl String:key[4];
	int sounds;
	while(++sounds)  //Just keep looping until there's no keys left
	{
		IntToString(sounds, key, sizeof(key));
		KvGetString(BossKV[Special[boss]], key, file, length);
		if(!file[0])
		{
			sounds--;  //This sound wasn't valid, so don't include it
			break;  //Assume that there's no more sounds
		}
	}

	if(!sounds)
	{
		return false;  //Found sound, but no sounds inside of it
	}

	int randomNum = GetRandomInt(1, sounds);
	IntToString(randomNum, key, sizeof(key));
	KvGetString(BossKV[Special[boss]], key, file, length);  //Populate file
/*
	Format(key, sizeof(key), "text%i", randomNum);
	if(KvJumpToKey(BossKV[Special[boss]], key))
	{
		Handle kv = CreateKeyValues("text");
		char item[100];

		KvGetString(BossKV[Special[boss]], "title", item, sizeof(item));
		KvSetString(kv, "title", item);
		Debug("%s", item);

		KvGetString(BossKV[Special[boss]], "msg", item, sizeof(item));
		KvSetString(kv, "msg", item);

		KvGetString(BossKV[Special[boss]], "color", item, sizeof(item));
		KvSetString(kv, "color", item);

		KvGetString(BossKV[Special[boss]], "level", item, sizeof(item), "1");
		KvSetString(kv, "level", item);

		KvGetString(BossKV[Special[boss]], "time", item, sizeof(item), "15");
		KvSetString(kv, "time", item);

		for(int client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client) && CheckSoundException(client, SOUNDEXCEPT_VOICE))
				CreateDialog(client, kv, DialogType_Text);
		}
		CloseHandle(kv);
	}
*/
	return true;
}

stock bool:RandomSoundAbility(const String:sound[], String:file[], length, boss=0, slot=0)
{
	if(boss<0 || Special[boss]<0 || !BossKV[Special[boss]])
	{
		return false;
	}

	KvRewind(BossKV[Special[boss]]);
	if(!KvJumpToKey(BossKV[Special[boss]], sound))
	{
		return false;  //Sound doesn't exist
	}

	decl String:key[10];
	int sounds, matches, match[MAXRANDOMS];
	while(++sounds)
	{
		IntToString(sounds, key, 4);
		KvGetString(BossKV[Special[boss]], key, file, length);
		if(!file[0])
		{
			break;  //Assume that there's no more sounds
		}

		Format(key, sizeof(key), "slot%i", sounds);
		if(KvGetNum(BossKV[Special[boss]], key, 0)==slot)
		{
			match[matches]=sounds;  //Found a match: let's store it in the array
			matches++;
		}
	}

	if(!matches)
	{
		return false;  //Found sound, but no sounds inside of it
	}
	int randomNum = GetRandomInt(0, matches-1);
	IntToString(match[randomNum], key, 4);
	KvGetString(BossKV[Special[boss]], key, file, length);  //Populate file

/*
	Format(key, sizeof(key), "text%i", randomNum);
	if(KvJumpToKey(BossKV[Special[boss]], key))
	{
		Handle kv = CreateKeyValues("text");
		char item[100];

		KvGetString(BossKV[Special[boss]], "title", item, sizeof(item));
		KvSetString(kv, "title", item);
		Debug("%s", item);

		KvGetString(BossKV[Special[boss]], "msg", item, sizeof(item));
		KvSetString(kv, "msg", item);

		KvGetString(BossKV[Special[boss]], "color", item, sizeof(item));
		KvSetString(kv, "color", item);

		KvGetString(BossKV[Special[boss]], "level", item, sizeof(item), "1");
		KvSetString(kv, "level", item);

		KvGetString(BossKV[Special[boss]], "time", item, sizeof(item), "15");
		KvSetString(kv, "time", item);

		for(int client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client) && CheckSoundException(client, SOUNDEXCEPT_VOICE))
				CreateDialog(client, kv, DialogType_Text);
		}
		CloseHandle(kv);
	}
*/
	return true;
}

public bool:PickCharacter(boss, companion)
{
	if(boss==companion)
	{
		Special[boss]=Incoming[boss];
		Incoming[boss]=-1;
		if(Special[boss]!=-1)  //We've already picked a boss through Command_SetNextBoss
		{
			Action action;
			Call_StartForward(OnSpecialSelected);
			Call_PushCell(boss);
			int characterIndex=Special[boss];
			Call_PushCellRef(characterIndex);
			decl String:newName[64];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", newName, sizeof(newName));
			Call_PushStringEx(newName, sizeof(newName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(true);  //Preset
			Call_Finish(action);
			if(action==Plugin_Changed)
			{
				if(newName[0])
				{
					decl String:characterName[64];
					int foundExactMatch=-1, foundPartialMatch=-1;
					for(int character; BossKV[character] && character<MAXSPECIALS; character++)
					{
						KvRewind(BossKV[character]);
						KvGetString(BossKV[character], "name", characterName, sizeof(characterName));
						if(StrEqual(newName, characterName, false))
						{
							foundExactMatch=character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(newName, characterName, false)!=-1)
						{
							foundPartialMatch=character;
						}

						//Do the same thing as above here, but look at the filename instead of the boss name
						KvGetString(BossKV[character], "filename", characterName, sizeof(characterName));
						if(StrEqual(newName, characterName, false))
						{
							foundExactMatch=character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(newName, characterName, false)!=-1)
						{
							foundPartialMatch=character;
						}
					}

					if(foundExactMatch!=-1)
					{
						Special[boss]=foundExactMatch;
					}
					else if(foundPartialMatch!=-1)
					{
						Special[boss]=foundPartialMatch;
					}
					else
					{
						return false;
					}
					PrecacheCharacter(Special[boss]);
					return true;
				}
				Special[boss]=characterIndex;
				PrecacheCharacter(Special[boss]);
				return true;
			}
			PrecacheCharacter(Special[boss]);
			return true;
		}

		char banMaps[500];
		char map[128];
		GetCurrentMap(map, sizeof(map));

		for(int tries; tries<100; tries++)
		{
			if(ChancesString[0])
			{
				int characterIndex=chancesIndex;  //Don't touch chancesIndex since it doesn't get reset
				int i=GetRandomInt(0, chances[characterIndex-1]);

				while(characterIndex>=2 && i<chances[characterIndex-1])
				{
					Special[boss]=chances[characterIndex-2]-1;
					characterIndex-=2;
				}
			}
			else
			{
				Special[boss]=GetRandomInt(0, Specials-1);
			}

			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "ban_map", banMaps, sizeof(banMaps), "");
			/*
			if(KvGetNum(BossKV[Special[boss]], "blocked"))
			{
				Special[boss]=-1;
				continue;
			}
			*/
			if(KvGetNum(BossKV[Special[boss]], "not_able_in_random"))
			{
				Special[boss]=-1;
				continue;
			}
			else if(banMaps[0] != '\0' &&  !StrContains(banMaps, map, false))
			{
				Special[boss]=-1;
				continue;
			}
			break;
		}
	}
	else
	{
		MainBoss=boss;
		decl String:bossName[64], String:companionName[64];
		KvRewind(BossKV[Special[boss]]);
		KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName), "=Failed companion name=");

		int character;
		while(character<Specials)  //Loop through all the bosses to find the companion we're looking for
		{
			KvRewind(BossKV[character]);
			KvGetString(BossKV[character], "name", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				Special[companion]=character;
				break;
			}

			KvGetString(BossKV[character], "filename", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				Special[companion]=character;
				break;
			}
			character++;
		}

		if(character==Specials)  //Companion not found
		{
			return false;
		}
	}

	//All of the following uses `companion` because it will always be the boss index we want
	Action action;
	Call_StartForward(OnSpecialSelected);
	Call_PushCell(companion);
	int characterIndex=Special[companion];
	Call_PushCellRef(characterIndex);
	decl String:newName[64];
	KvRewind(BossKV[Special[companion]]);
	KvGetString(BossKV[Special[companion]], "name", newName, sizeof(newName));
	Call_PushStringEx(newName, sizeof(newName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(false);  //Not preset
	Call_Finish(action);
	if(action==Plugin_Changed)
	{
		if(newName[0])
		{
			decl String:characterName[64];
			int foundExactMatch=-1, foundPartialMatch=-1;
			for(int character; BossKV[character] && character<MAXSPECIALS; character++)
			{
				KvRewind(BossKV[character]);
				KvGetString(BossKV[character], "name", characterName, sizeof(characterName));
				if(StrEqual(newName, characterName, false))
				{
					foundExactMatch=character;
					break;  //If we find an exact match there's no reason to keep looping
				}
				else if(StrContains(newName, characterName, false)!=-1)
				{
					foundPartialMatch=character;
				}

				//Do the same thing as above here, but look at the filename instead of the boss name
				KvGetString(BossKV[character], "filename", characterName, sizeof(characterName));
				if(StrEqual(newName, characterName, false))
				{
					foundExactMatch=character;
					break;  //If we find an exact match there's no reason to keep looping
				}
				else if(StrContains(newName, characterName, false)!=-1)
				{
					foundPartialMatch=character;
				}
			}

			if(foundExactMatch!=-1)
			{
				Special[companion]=foundExactMatch;
			}
			else if(foundPartialMatch!=-1)
			{
				Special[companion]=foundPartialMatch;
			}
			else
			{
				return false;
			}
			PrecacheCharacter(Special[companion]);
			return true;
		}
		Special[companion]=characterIndex;
		PrecacheCharacter(Special[companion]);
		return true;
	}
	PrecacheCharacter(Special[companion]);
	return true;
}

FindCompanion(boss, players, bool:omit[])
{
	static playersNeeded=3;
	decl String:companionName[64];
	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName));
	if(playersNeeded<players && strlen(companionName))  //Only continue if we have enough players and if the boss has a companion
	{
		int companion=GetClientWithMostQueuePoints(omit);
		Boss[companion]=companion;  //Woo boss indexes!
		omit[companion]=true;
		if(PickCharacter(boss, companion))  //TODO: This is a bit misleading
		{
			playersNeeded++;
			HasCompanions=true;
			FindCompanion(companion, players, omit);  //Make sure this companion doesn't have a companion of their own
		}
		else  //Can't find the companion's character, so just play without the companion
		{
			LogError("[FF2 Bosses] Could not find boss %s!", companionName);
			Boss[companion]=0;
			omit[companion]=false;
		}
	}
	playersNeeded=3;  //Reset the amount of players needed back to 3 after we're done
}

stock SpawnWeapon(client, String:name[], index, level, qual, String:att[])
{
	Handle hWeapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon==INVALID_HANDLE)
	{
		return -1;
	}

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count=ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
	{
		--count;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2;
		for(int i; i<count; i+=2)
		{
			int attrib=StringToInt(atts[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				CloseHandle(hWeapon);
				return -1;
			}

			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}

	int entity=TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

public HintPanelH(Handle:menu, MenuAction:action, client, selection)
{
	if(IsValidClient(client) && (action==MenuAction_Select || (action==MenuAction_Cancel && selection==MenuCancel_Exit)))
	{
		FF2flags[client]|=FF2FLAG_CLASSHELPED;
	}
	return;
}

public QueuePanelH(Handle:menu, MenuAction:action, client, selection)
{
	if(action==MenuAction_Select && selection==10)
	{
		TurnToZeroPanel(client, client);
	}
	return false;
}


public Action:QueuePanelCmd(client, args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	decl String:text[64];
	int items;
	bool added[MAXPLAYERS+1];

	Handle panel=CreatePanel();
	SetGlobalTransTarget(client);
	Format(text, sizeof(text), "%t", "thequeue");  //"Boss Queue"
	SetPanelTitle(panel, text);
	for(int boss; boss<=MaxClients; boss++)  //Add the current bosses to the top of the list
	{
		if(IsBoss(boss))
		{
			added[boss]=true;  //Don't want the bosses to show up again in the actual queue list
			Format(text, sizeof(text), "%N-%i", boss, GetClientQueuePoints(boss));
			DrawPanelItem(panel, text);
			items++;
		}
	}

	DrawPanelText(panel, "---");
	do
	{
		int target=GetClientWithMostQueuePoints(added);  //Get whoever has the highest queue points out of those who haven't been listed yet
		if(!IsValidClient(target))  //When there's no players left, fill up the rest of the list with blank lines
		{
			DrawPanelItem(panel, "");
			items++;
			continue;
		}

		Format(text, sizeof(text), "%N-%i", target, GetClientQueuePoints(target));
		if(client!=target)
		{
			DrawPanelItem(panel, text);
			items++;
		}
		else
		{
			DrawPanelText(panel, text);  //DrawPanelText() is white, which allows the client's points to stand out
		}
		added[target]=true;
	}
	while(items<9);

	Format(text, sizeof(text), "%t (%t)", "your_points", GetClientQueuePoints(client), "to0");  //"Your queue point(s) is {1} (set to 0)"
	DrawPanelItem(panel, text);

	SendPanelToClient(panel, client, QueuePanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

public Action:ResetQueuePointsCmd(client, args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	if(client && !args)  //Normal players
	{
		TurnToZeroPanel(client, client);
		return Plugin_Handled;
	}

	if(!client)  //No confirmation for console
	{
		TurnToZeroPanelH(INVALID_HANDLE, MenuAction_Select, client, 1);
		return Plugin_Handled;
	}

	AdminId admin=GetUserAdmin(client);	 //Normal players
	if((admin==INVALID_ADMIN_ID) || !GetAdminFlag(admin, Admin_Cheats))
	{
		TurnToZeroPanel(client, client);
		return Plugin_Handled;
	}

	if(args!=1)  //Admins
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_resetqueuepoints <target>");
		return Plugin_Handled;
	}

	decl String:pattern[MAX_TARGET_LENGTH];
	GetCmdArg(1, pattern, sizeof(pattern));
	char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, 1, 0, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches>1)
	{
		for(int target; target<matches; target++)
		{
			TurnToZeroPanel(client, targets[target]);  //FIXME:  This can only handle one client currently and doesn't iterate through all clients
		}
	}
	else
	{
		TurnToZeroPanel(client, targets[0]);
	}
	return Plugin_Handled;
}

public TurnToZeroPanelH(Handle:menu, MenuAction:action, client, position)
{
	if(action==MenuAction_Select && position==1)
	{
		if(shortname[client]==client)
		{
			CPrintToChat(client,"{olive}[FF2]{default} %t", "to0_done");  //Your queue points have been reset to {olive}0{default}
		}
		else
		{
			CPrintToChat(client, "{olive}[FF2]{default} %t", "to0_done_admin", shortname[client]);  //{olive}{1}{default}'s queue points have been reset to {olive}0{default}
			CPrintToChat(shortname[client], "{olive}[FF2]{default} %t", "to0_done_by_admin", client);  //{olive}{1}{default} reset your queue points to {olive}0{default}
			LogAction(client, shortname[client], "\"%L\" reset \"%L\"'s queue points to 0", client, shortname[client]);
		}
		SetClientQueuePoints(shortname[client], 0);
	}
}

public Action:TurnToZeroPanel(client, target)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	Handle panel=CreatePanel();
	decl String:text[128];
	SetGlobalTransTarget(client);
	if(client==target)
	{
		Format(text, sizeof(text), "%t", "to0_title");  //Do you really want to set your queue points to 0?
	}
	else
	{
		Format(text, sizeof(text), "%t", "to0_title_admin", target);  //Do you really want to set {1}'s queue points to 0?
	}

	PrintToChat(client, text);
	SetPanelTitle(panel, text);
	Format(text, sizeof(text), "네");
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "아니요");
	DrawPanelItem(panel, text);
	shortname[client]=target;
	SendPanelToClient(panel, client, TurnToZeroPanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

bool:GetClientBossInfoCookie(client)
{
	if(!IsValidClient(client) || IsFakeClient(client))
	{
		return false;
	}

	if(!AreClientCookiesCached(client))
	{
		return true;
	}

	decl String:cookies[24];
	decl String:cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	return StringToInt(cookieValues[3])==1;
}

GetClientQueuePoints(client)
{
	if(!IsValidClient(client) || !AreClientCookiesCached(client))
	{
		return 0;
	}

	if(IsFakeClient(client))
	{
		return botqueuepoints;
	}

	decl String:cookies[24], String:cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	return StringToInt(cookieValues[0]);
}

SetClientQueuePoints(client, points)
{
	if(IsValidClient(client) && !IsFakeClient(client) && AreClientCookiesCached(client))
	{
		decl String:cookies[24], String:cookieValues[8][5];
		GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
		ExplodeString(cookies, " ", cookieValues, 8, 5);
		Format(cookies, sizeof(cookies), "%i %s %s %s %s %s %s %s", points, cookieValues[1], cookieValues[2], cookieValues[3], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
		SetClientCookie(client, FF2Cookies, cookies);
	}
}

stock bool:IsBoss(client)
{
	if(IsValidClient(client))
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(Boss[boss]==client)
			{
				return true;
			}
		}
	}
	return false;
}

public FF2PanelH(Handle:menu, MenuAction:action, client, selection)
{
	if(action==MenuAction_Select)
	{
		switch(selection)
		{
			case 1:
			{
				Command_GetHP(client);
			}
			case 2:
			{
				HelpPanelClass(client);
			}
			case 3:
			{
				NewPanel(client, maxVersion);
			}
			case 4:
			{
				QueuePanelCmd(client, 0);
			}
			case 5:
			{
				MusicTogglePanel(client);
			}
			case 6:
			{
				VoiceTogglePanel(client);
			}
			case 7:
			{
				HelpPanel3(client);
			}
			default:
			{
				return;
			}
		}
	}
}

public Action:FF2Panel(client, args)  //._.
{
	if(Enabled2 && IsValidClient(client, false))
	{
		Handle panel=CreatePanel();
		decl String:text[256];
		SetGlobalTransTarget(client);
		Format(text, sizeof(text), "%t", "menu_1");  //What's up?
		SetPanelTitle(panel, text);
		Format(text, sizeof(text), "%t", "menu_2");  //Investigate the boss's current health level (/ff2hp)
		DrawPanelItem(panel, text);
		//Format(text, sizeof(text), "%t", "menu_3");  //Help about FF2 (/ff2help).
		//DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "menu_7");  //Changes to my class in FF2 (/ff2classinfo)
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "menu_4");  //What's new? (/ff2new).
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "menu_5");  //Queue points
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "menu_8");  //Toggle music (/ff2music)
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "menu_9");  //Toggle monologues (/ff2voice)
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "menu_9a");  //Toggle info about changes of classes in FF2
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%t", "menu_6");  //Exit
		DrawPanelItem(panel, text);
		SendPanelToClient(panel, client, FF2PanelH, MENU_TIME_FOREVER);
		CloseHandle(panel);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public NewPanelH(Handle:menu, MenuAction:action, param1, param2)
{
	if(action==MenuAction_Select)
	{
		switch(param2)
		{
			case 1:
			{
				if(curHelp[param1]<=0)
					NewPanel(param1, 0);
				else
					NewPanel(param1, --curHelp[param1]);
			}
			case 2:
			{
				if(curHelp[param1]>=maxVersion)
					NewPanel(param1, maxVersion);
				else
					NewPanel(param1, ++curHelp[param1]);
			}
			default: return;
		}
	}
}

public Action:NewPanelCmd(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	NewPanel(client, maxVersion);
	return Plugin_Handled;
}

public Action:NewPanel(client, versionIndex)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	curHelp[client]=versionIndex;
	Handle panel=CreatePanel();
	decl String:whatsNew[90];

	SetGlobalTransTarget(client);
	Format(whatsNew, 90, "=%t:=", "whatsnew", ff2versiontitles[versionIndex], ff2versiondates[versionIndex]);
	SetPanelTitle(panel, whatsNew);
	FindVersionData(panel, versionIndex);
	if(versionIndex>0)
	{
		Format(whatsNew, 90, "%t", "older");
	}
	else
	{
		Format(whatsNew, 90, "%t", "noolder");
	}

	DrawPanelItem(panel, whatsNew);
	if(versionIndex<maxVersion)
	{
		Format(whatsNew, 90, "%t", "newer");
	}
	else
	{
		Format(whatsNew, 90, "%t", "nonewer");
	}

	DrawPanelItem(panel, whatsNew);
	Format(whatsNew, 512, "%t", "menu_6");
	DrawPanelItem(panel, whatsNew);
	SendPanelToClient(panel, client, NewPanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Continue;
}

public Action:HelpPanel3Cmd(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	HelpPanel3(client);
	return Plugin_Handled;
}

public Action:HelpPanel3(client)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	Handle panel=CreatePanel();
	SetPanelTitle(panel, "보스 능력 설명을..");
	DrawPanelItem(panel, "켜기");
	DrawPanelItem(panel, "끄기");
	SendPanelToClient(panel, client, ClassInfoTogglePanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}


public ClassInfoTogglePanelH(Handle:menu, MenuAction:action, client, selection)
{
	if(IsValidClient(client))
	{
		if(action==MenuAction_Select)
		{
			decl String:cookies[24];
			decl String:cookieValues[8][5];
			GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
			ExplodeString(cookies, " ", cookieValues, 8, 5);
			if(selection==2)
			{
				Format(cookies, sizeof(cookies), "%s %s %s 0 %s %s %s", cookieValues[0], cookieValues[1], cookieValues[2], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
			}
			else
			{
				Format(cookies, sizeof(cookies), "%s %s %s 1 %s %s %s", cookieValues[0], cookieValues[1], cookieValues[2], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
			}
			SetClientCookie(client, FF2Cookies, cookies);
			CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_classinfo", selection==2 ? "끄기" : "켜기");
		}
	}
}

public Action:Command_HelpPanelClass(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	HelpPanelClass(client);
	return Plugin_Handled;
}

public Action:HelpPanelClass(client)
{
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	int boss = GetBossIndex(client);
	if(boss != MainBoss && boss != -1)
	{
		HelpPanelBoss(client);
		return Plugin_Continue;
	}

	decl String:text[512];
	TFClassType class=TF2_GetPlayerClass(client);
	SetGlobalTransTarget(client);
	switch(class)
	{
		case TFClass_Scout:
		{
			Format(text, sizeof(text), "%t", "help_scout");
		}
		case TFClass_Soldier:
		{
			Format(text, sizeof(text), "%t", "help_soldier");
		}
		case TFClass_Pyro:
		{
			Format(text, sizeof(text), "%t", "help_pyro");
		}
		case TFClass_DemoMan:
		{
			Format(text, sizeof(text), "%t", "help_demo");
		}
		case TFClass_Heavy:
		{
			Format(text, sizeof(text), "%t", "help_heavy");
		}
		case TFClass_Engineer:
		{
			Format(text, sizeof(text), "%t", "help_eggineer");
		}
		case TFClass_Medic:
		{
			Format(text, sizeof(text), "%t", "help_medic");
		}
		case TFClass_Sniper:
		{
			Format(text, sizeof(text), "%t", "help_sniper");
		}
		case TFClass_Spy:
		{
			Format(text, sizeof(text), "%t", "help_spie");
		}
		default:
		{
			Format(text, sizeof(text), "");
		}
	}

	if(class!=TFClass_Sniper)
	{
		Format(text, sizeof(text), "%t\n%s", "help_melee", text);
	}

	Handle panel=CreatePanel();
	SetPanelTitle(panel, text);
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, HintPanelH, 20);
	CloseHandle(panel);
	return Plugin_Continue;
}

HelpPanelBoss(client=0)
{
	decl String:text[1024];
	int bossIndex = GetBossIndex(client);

	if(bossIndex == -1)
	{
		KvRewind(BossKV[Special[MainBoss]]);
		KvGetString(BossKV[Special[MainBoss]], "description", text, sizeof(text));  // NO 다국어 지원.
	}
	else
	{
		KvRewind(BossKV[Special[bossIndex]]);
		KvGetString(BossKV[Special[bossIndex]], "description", text, sizeof(text));  // NO 다국어 지원.
	}
	if(!text[0])
	{
		return;
	}
	ReplaceString(text, sizeof(text), "\\n", "\n");
	//KvSetEscapeSequences(BossKV[Special[boss]], false);  //We don't want to interfere with the download paths

	Handle panel=CreatePanel();
	SetPanelTitle(panel, text);
	DrawPanelItem(panel, "그렇군요!");
	if(client == 0)
	{
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsValidClient(i) && GetClientBossInfoCookie(i))	SendPanelToClient(panel, i, HintPanelH, 20);
		}
	}
	else
	{
		SendPanelToClient(panel, client, HintPanelH, 20);
	}
	CloseHandle(panel);
}
stock RemoveShield(client, attacker, Float:position[3])
{
	TF2_RemoveWearable(client, shield[client]);
	EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	TF2_AddCondition(client, TFCond_Bonked, 0.1); // Shows "MISS!" upon breaking shield
	shield[client]=0;
}

stock StingShield(client, attacker, Float:position[3])
{
	EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
}

public Action:MusicTogglePanelCmd(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	MusicTogglePanel(client);
	return Plugin_Handled;
}

public Action:MusicTogglePanel(client)
{
	if(!Enabled || !IsValidClient(client))
	{
		return Plugin_Continue;
	}
	Handle menu=CreateMenu(MusicTogglePanelH);

	SetMenuTitle(menu, "보스들의 BGM을..");
	AddMenuItem(menu, "켜기", "켜기");
	AddMenuItem(menu, "끄기", "끄기");
	AddMenuItem(menu, "곡 선택하기", "현재 보스 BGM 선택", !KvJumpToKey(BossKV[Special[0]], "sound_bgm") || FF2ServerFlag & FF2SERVERFLAG_UNCHANGE_BOSSBGM_USER ? ITEMDRAW_DISABLED : 0);
	AddMenuItem(menu, "외부 곡 선택하기", "현재 외부 BGM 선택", !LoadedMusicData || FF2ServerFlag & FF2SERVERFLAG_UNCHANGE_BGM_USER ? ITEMDRAW_DISABLED : 0);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

public MusicTogglePanelH(Handle:menu, MenuAction:action, client, selection)
{
	if(!IsValidClient(client) || action==MenuAction_End) CloseHandle(menu);
	else if(action==MenuAction_Select)
	{
		switch(selection)
		{
			case 0:
			{
				if(!CheckSoundException(client, SOUNDEXCEPT_MUSIC))
				{
					SetClientSoundOptions(client, SOUNDEXCEPT_MUSIC, true);
					StartMusic(client);
					CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_music", selection==1 ? "끄기" : "켜기");
				}
			 }
	 	 	case 1:
			{
				/*
				SetClientSoundOptions(client, SOUNDEXCEPT_MUSIC, false);
				StopMusic(client, true);
				CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_music", selection==1 ? "끄기" : "켜기");
				*/

				CreateClientMuteMenu(client);
			}
			case 2:
			{
				ViewClientBossMusicMenu(client);
			}
			case 3:
			{
			 	ViewClientMusicMenu(client);
			}
		}
	}
}


void CreateClientMuteMenu(client)
{
	// Handle BossMusicKv = CloneHandle(LoadedMusicData ? LoadedMusicData : BossKV[Special[0]]);

	Handle menu=CreateMenu(BossMuteSelectionMenu);

	SetMenuTitle(menu, "끌 음악을 선택해주십시요.");

	AddMenuItem(menu, "", "전체 음악 끄기", 0);
	AddMenuItem(menu, "", "현재 보스 음악 선택 끄기", FF2ServerFlag & FF2SERVERFLAG_UNCHANGE_BOSSBGM_USER ? ITEMDRAW_DISABLED : 0);
	AddMenuItem(menu, "", "현재 외부 음악 선택 끄기", FF2ServerFlag & FF2SERVERFLAG_UNCHANGE_BGM_USER ? ITEMDRAW_DISABLED : 0);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public BossMuteSelectionMenu(Handle:menu, MenuAction:action, client, selection)
{
	if(!IsValidClient(client) || action==MenuAction_End) CloseHandle(menu);
	else if(action==MenuAction_Select)
	{
		switch(selection)
		{
		  	case 0:
		  	{
				SetClientSoundOptions(client, SOUNDEXCEPT_MUSIC, false);
				StopMusic(client, true);
				CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_music", selection==0 ? "끄기" : "켜기");
		  	}
			case 1:
		  	{
				ViewClientBossMusicMenu(client, true);
		  	}
			case 2:
		  	{
				ViewClientMusicMenu(client, true);
		  	}
		}
	}
}


void ViewClientBossMusicMenu(client, bool enableMute = false)
{
	Handle clonedHandle = CloneHandle(BossKV[Special[0]]);
	KvRewind(clonedHandle);
	if(!KvJumpToKey(clonedHandle, "sound_bgm"))
	{
		CPrintToChat(client, "{olive}[FF2]{default} 사운드 리스트를 로드할 수 없거나 해당 보스에게 BGM이 없습니다. 잠시 뒤에 다시 확인해주세요.");
		return;
	}

	char temp[PLATFORM_MAX_PATH];
	char artist[100];
	char name[100];
	char code[100];
	int i=1;
	bool compilerNo=true;

	Handle menu;

	if(enableMute)
	{
		menu=CreateMenu(MuteClientBossMusic);

		Format(temp, sizeof(temp), "차단할 곡을 선택해주세요.");
	}
	else
	{
		menu=CreateMenu(BossMusicSelectionMenu);

		Format(temp, sizeof(temp), "들으실 곡을 선택해주세요. %s", FF2ServerFlag & FF2SERVERFLAG_UNCHANGE_BOSSBGM_USER ? "지금은 곡을 설정할 수 없습니다!" : "");
	}


	SetMenuTitle(menu, temp);
	while(compilerNo)
	{
		Format(temp, sizeof(temp), "path%i", i);
		KvGetString(clonedHandle, temp, temp, sizeof(temp), "");

		if(temp[0] == '\0') break;
		else
		{
			GetSoundCode(temp, code, sizeof(code));
		}
		Format(temp, sizeof(temp), "artist%i", i);
		KvGetString(clonedHandle, temp, artist, sizeof(artist), "이름 없는 아티스트");

		Format(temp, sizeof(temp), "name%i", i);
		KvGetString(clonedHandle, temp, name, sizeof(name), "이름 없는 곡");

		if(enableMute)
		{
			Format(temp, sizeof(temp), "[%s] %s - %s", !CheckSoundException(client, SOUNDEXCEPT_MUSIC, code) ? "*" : "", artist, name);
		}
		else
		{
			Format(temp, sizeof(temp), "%s - %s", artist, name);
		}

		AddMenuItem(menu, "곡", temp, (!enableMute && (FF2ServerFlag & FF2SERVERFLAG_UNCHANGE_BOSSBGM_USER || !CheckSoundException(client, SOUNDEXCEPT_MUSIC, code))) ? ITEMDRAW_DISABLED : 0);
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MuteClientBossMusic(Handle:menu, MenuAction:action, client, selection)
{
	if(!IsValidClient(client) || action==MenuAction_End) CloseHandle(menu);
	else if(action==MenuAction_Select)
	{
		Handle clonedHandle = CloneHandle(BossKV[Special[0]]);
		KvRewind(clonedHandle);
		if(!KvJumpToKey(clonedHandle, "sound_bgm"))
		{
			return;
		}

		char temp[PLATFORM_MAX_PATH];
		char code[100];

		Format(temp, sizeof(temp), "path%i", selection + 1);
		KvGetString(clonedHandle, temp, temp, sizeof(temp), "");
		GetSoundCode(temp, code, 100);

		SetClientSoundOptions(client, SOUNDEXCEPT_MUSIC, !CheckSoundException(client, SOUNDEXCEPT_MUSIC, code) ? true : false, code);

		CPrintToChat(client, "{olive}[FF2]{default} 선택하신 곡을 {yellow}%s{default}했습니다.", CheckSoundException(client, SOUNDEXCEPT_MUSIC, code) ? "차단 해체" : "차단");

		if(StrEqual(temp, currentBGM[client], true))
			StartMusic(client);

		ViewClientBossMusicMenu(client, true);
	}
}

public BossMusicSelectionMenu(Handle:menu, MenuAction:action, client, selection)
{
	if(!IsValidClient(client) || action==MenuAction_End) CloseHandle(menu);
	else if(action==MenuAction_Select)
	{
		playingCustomBGM[client]=false;
		playingCustomBossBGM[client]=true;
		selectedBGM[client]=selection+1;
		CPrintToChat(client, "{olive}[FF2]{default} 선택하신 곡으로 재생합니다..");
		StartMusic(client);
	}
}

public MuteClientMusic(Handle:menu, MenuAction:action, client, selection)
{
	if(!IsValidClient(client) || action==MenuAction_End) CloseHandle(menu);
	else if(action==MenuAction_Select)
	{
		Handle clonedHandle = CloneHandle(LoadedMusicData);
		KvRewind(clonedHandle);
		if(!KvJumpToKey(clonedHandle, "sound_bgm"))
		{
			return;
		}

		char temp[PLATFORM_MAX_PATH];
		char code[100];

		Format(temp, sizeof(temp), "path%i", selection + 1);
		KvGetString(clonedHandle, temp, temp, sizeof(temp), "");
		GetSoundCode(temp, code, 100);

		SetClientSoundOptions(client, SOUNDEXCEPT_MUSIC, false, code);

		CPrintToChat(client, "{olive}[FF2]{default} 선택하신 곡을 차단했습니다.");

		if(StrEqual(temp, currentBGM[client], true))
			StartMusic(client);

		ViewClientMusicMenu(client, true);
	}
}

void ViewClientMusicMenu(client, bool enableMute = false)
{
	if(!LoadedMusicData)
	{
		CPrintToChat(client, "{olive}[FF2]{default} 현재 등록된 외부음악이 없습니다!");
		return;
	}
	KvRewind(LoadedMusicData);
	if(!KvJumpToKey(LoadedMusicData, "sound_bgm"))
	{
		CPrintToChat(client, "{olive}[FF2]{default} 사운드 리스트를 로드할 수 없습니다. 잠시 뒤에 다시 확인해주세요.");
		return;
	}

	char temp[PLATFORM_MAX_PATH];
	char artist[100];
	char name[100];
	char code[100];
	int i=1;
	bool compilerNo=true;

	Handle menu;
	if(enableMute)
	{
		menu = CreateMenu(MuteClientMusic);

		Format(temp, sizeof(temp), "차단할 곡을 선택해주세요.");
	}
	else
	{
		menu = CreateMenu(MusicSelectionMenu);

		Format(temp, sizeof(temp), "들으실 곡을 선택해주세요. %s", FF2ServerFlag & FF2SERVERFLAG_UNCHANGE_BGM_USER ? "지금은 곡을 설정할 수 없습니다!" : "");
	}

	SetMenuTitle(menu, temp);
	while(compilerNo)
	{
		Format(temp, sizeof(temp), "path%i", i);
		KvGetString(LoadedMusicData, temp, temp, sizeof(temp), "");

		if(temp[0] == '\0') break;
		else
		{
			GetSoundCode(temp, code, sizeof(code));
		}
		Format(temp, sizeof(temp), "artist%i", i);
		KvGetString(LoadedMusicData, temp, artist, sizeof(artist), "이름 없는 아티스트");

		Format(temp, sizeof(temp), "name%i", i);
		KvGetString(LoadedMusicData, temp, name, sizeof(name), "이름 없는 곡");

		Format(temp, sizeof(temp), "%s - %s", artist, name);

		if(enableMute)
			Format(temp, sizeof(temp), "[%s] %s - %s", !CheckSoundException(client, SOUNDEXCEPT_MUSIC, code) ? "*" : "", artist, name);
		else
			Format(temp, sizeof(temp), "%s - %s", artist, name);

		AddMenuItem(menu, "곡", temp,
		(!enableMute && (FF2ServerFlag & FF2SERVERFLAG_UNCHANGE_BGM_USER || !CheckSoundException(client, SOUNDEXCEPT_MUSIC, code))) ? ITEMDRAW_DISABLED : 0);
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MusicSelectionMenu(Handle:menu, MenuAction:action, client, selection)
{
	if(!IsValidClient(client) || action==MenuAction_End) CloseHandle(menu);
	else if(action==MenuAction_Select)
	{
		playingCustomBGM[client]=true;
		playingCustomBossBGM[client]=false;
		selectedBGM[client]=selection+1;
		CPrintToChat(client, "{olive}[FF2]{default} 선택하신 곡으로 재생합니다..");
		StartMusic(client);
	}
}

public Action:VoiceTogglePanelCmd(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	VoiceTogglePanel(client);
	return Plugin_Handled;
}

public Action:VoiceTogglePanel(client)
{
	if(!Enabled || !IsValidClient(client))
	{
		return Plugin_Continue;
	}

	Handle panel=CreatePanel();
	SetPanelTitle(panel, "보스들의 대사/효과음을..");
	DrawPanelItem(panel, "켜기");
	DrawPanelItem(panel, "끄기");
	SendPanelToClient(panel, client, VoiceTogglePanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Continue;
}

public VoiceTogglePanelH(Handle:menu, MenuAction:action, client, selection)
{
	if(IsValidClient(client))
	{
		if(action==MenuAction_Select)
		{
			if(selection==2)
			{
				SetClientSoundOptions(client, SOUNDEXCEPT_VOICE, false);
			}
			else
			{
				SetClientSoundOptions(client, SOUNDEXCEPT_VOICE, true);
			}

			CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_voice", selection==2 ? "off" : "on");
			if(selection==2)
			{
				CPrintToChat(client, "%t", "ff2_voice2");
			}
		}
	}
}

//Ugly compatability layer since HookSound's arguments changed in 1.8
#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=7
public Action:HookSound(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &client, &channel, &Float:volume, &level, &pitch, &flags)
#else
public Action:HookSound(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &client, &channel, &Float:volume, &level, &pitch, &flags, String:soundEntry[PLATFORM_MAX_PATH], &seed)
#endif
{
	if(!Enabled || !IsValidClient(client) || channel<1)
	{
		return Plugin_Continue;
	}

	int boss=GetBossIndex(client);
	if(boss==-1)
	{
		return Plugin_Continue;
	}

	if(channel==SNDCHAN_VOICE && !(FF2flags[Boss[boss]] & FF2FLAG_TALKING))
	{
		decl String:newSound[PLATFORM_MAX_PATH];
		if(RandomSound("catch_phrase", newSound, PLATFORM_MAX_PATH, boss))
		{
			strcopy(sound, PLATFORM_MAX_PATH, newSound);
			return Plugin_Changed;
		}

		if(bBlockVoice[Special[boss]])
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public CvarChangeNextmap(Handle:convar, const String:oldValue[], const String:newValue[])
{
	CreateTimer(0.1, Timer_DisplayCharsetVote, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_DisplayCharsetVote(Handle:timer)
{
	if(isCharSetSelected)
	{
		return Plugin_Continue;
	}

	if(IsVoteInProgress())
	{
		CreateTimer(5.0, Timer_DisplayCharsetVote, _, TIMER_FLAG_NO_MAPCHANGE);  //Try again in 5 seconds if there's a different vote going on
		return Plugin_Continue;
	}

	Handle menu=CreateMenu(Handler_VoteCharset, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "%t", "select_charset");  //"Please vote for the character set for the next map."
	//SetVoteResultCallback(menu, Handler_VoteCharset);

	decl String:config[PLATFORM_MAX_PATH], String:charset[64];
	BuildPath(Path_SM, config, sizeof(config), "configs/freak_fortress_2/characters.cfg");

	Handle Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	//AddMenuItem(menu, "0 Random", "Random");
	AddMenuItem(menu, "Random", "Random");
	int total, charsets;
	do
	{
		total++;
		if(KvGetNum(Kv, "hidden", 0))  //Hidden charsets are hidden for a reason :P
		{
			continue;
		}
		charsets++;
		validCharsets[charsets]=total;

		KvGetSectionName(Kv, charset, sizeof(charset));
		//Format(charset, sizeof(charset), "%i %s", charsets, config);
		//AddMenuItem(menu, charset, config);
		AddMenuItem(menu, charset, charset);
	}
	while(KvGotoNextKey(Kv));
	CloseHandle(Kv);

	if(charsets>1)  //We have enough to call a vote
	{
		FF2CharSet=charsets;  //Temporary so that if the vote result is random we know how many valid charsets are in the validCharset array
		Handle voteDuration=FindConVar("sm_mapvote_voteduration");
		VoteMenuToAll(menu, voteDuration ? GetConVarInt(voteDuration) : 20);
	}
	return Plugin_Continue;
}
public Handler_VoteCharset(Handle:menu, MenuAction:action, param1, param2)
{
	/*if(action==MenuAction_Select && param2==1)
	{
		int clients[1];
		clients[0]=param1;
		if(!IsVoteInProgress())
		{
			VoteMenu(menu, clients, param1, 1, MENU_TIME_FOREVER);
		}
	}
	else */if(action==MenuAction_VoteEnd)
	{
		FF2CharSet=param1 ? param1-1 : validCharsets[GetRandomInt(1, FF2CharSet)]-1;  //If param1 is 0 then we need to find a random charset

		decl String:nextmap[32];
		GetConVarString(cvarNextmap, nextmap, sizeof(nextmap));
		GetMenuItem(menu, param1, FF2CharSetString, sizeof(FF2CharSetString));
		CPrintToChatAll("{olive}[FF2]{default} %t", "nextmap_charset", nextmap, FF2CharSetString);  //"The character set for {1} will be {2}."
		isCharSetSelected=true;
	}
	else if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

/*public Handler_VoteCharset(Handle:menu, votes, clients, const clientInfo[][2], items, const itemInfo[][2])
{
	decl String:item[42], String:display[42], String:nextmap[42];
	GetMenuItem(menu, itemInfo[0][VOTEINFO_ITEM_INDEX], item, sizeof(item), _, display, sizeof(display));
	if(item[0]=='0')  //!StringToInt(item)
	{
		FF2CharSet=GetRandomInt(0, FF2CharSet);
	}
	else
	{
		FF2CharSet=item[0]-'0'-1;  //Wat
		//FF2CharSet=StringToInt(item)-1
	}

	GetConVarString(cvarNextmap, nextmap, sizeof(nextmap));
	strcopy(FF2CharSetString, 42, item[StrContains(item, " ")+1]);
	CPrintToChatAll("{olive}[FF2]{default} %t", "nextmap_charset", nextmap, FF2CharSetString);  //display
	isCharSetSelected=true;
}*/

public Action:Command_Nextmap(client, args)
{
	if(FF2CharSetString[0])
	{
		decl String:nextmap[42];
		GetConVarString(cvarNextmap, nextmap, sizeof(nextmap));
		CPrintToChat(client, "{olive}[FF2]{default} %t", "nextmap_charset", nextmap, FF2CharSetString);
	}
	return Plugin_Handled;
}

public Action:Command_Say(client, args)
{
	decl String:chat[128];
	if(GetCmdArgString(chat, sizeof(chat))<1 || !client)
	{
		return Plugin_Continue;
	}

	if(!strcmp(chat, "\"nextmap\"") && FF2CharSetString[0])
	{
		Command_Nextmap(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool UseAbility(const String:ability_name[], const String:plugin_name[], boss, slot, buttonMode=0)
{
	bool enabled=true;
	Call_StartForward(PreAbility);
	Call_PushCell(boss);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
	Call_PushCell(slot);
	Call_PushCellRef(enabled);
	Call_Finish();

	if(!enabled)
	{
		return false;
	}

	Action action=Plugin_Continue;
	Call_StartForward(OnAbility);
	Call_PushCell(boss);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
	if(slot==-1)
	{
		Call_PushCell(3);  //Status - we're assuming here a life-loss ability will always be in use if it gets called
		Call_Finish(action);
	}
	else if(!slot)
	{
		if(FF2flags[Boss[boss]] & FF2FLAG_NOTALLOW_RAGE) return false;
		FF2flags[Boss[boss]]&=~FF2FLAG_BOTRAGE;
		Call_PushCell(3);  //Status - we're assuming here a rage ability will always be in use if it gets called
		Call_Finish(action);
		// BossCharge[boss][slot]=0.0;
	}
	else
	{
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
		int button;
		switch(buttonMode)
		{
			case 2:
			{
				button=IN_RELOAD;
				bossHasReloadAbility[boss]=true;
			}
			default:
			{
				button=IN_DUCK|IN_ATTACK2;
				bossHasRightMouseAbility[boss]=true;
			}
		}

		if(GetClientButtons(Boss[boss]) & button)
		{
			for(int timer; timer<=1; timer++)
			{
				if(BossInfoTimer[boss][timer]!=INVALID_HANDLE)
				{
					KillTimer(BossInfoTimer[boss][timer]);
					BossInfoTimer[boss][timer]=INVALID_HANDLE;
				}
			}

			if(BossCharge[boss][slot]>=0.0)
			{
				Call_PushCell(2);  //Status
				Call_Finish(action);
				float charge=100.0*0.1/GetAbilityArgumentFloat(boss, plugin_name, ability_name, 1, 1.5);
				if(BossCharge[boss][slot]+charge<100.0)
				{
					BossCharge[boss][slot]+=charge;
				}
				else
				{
					BossCharge[boss][slot]=100.0;
				}
			}
			else
			{
				Call_PushCell(1);  //Status
				Call_Finish(action);
				BossCharge[boss][slot]+=0.1;
			}
		}
		else if(BossCharge[boss][slot]>0.3)
		{
			float angles[3];
			GetClientEyeAngles(Boss[boss], angles);
			if(angles[0]<-45.0)
			{
				Call_PushCell(3);
				Call_Finish(action);
				Handle data;
				CreateDataTimer(0.1, Timer_UseBossCharge, data);
				WritePackCell(data, boss);
				WritePackCell(data, slot);
				WritePackFloat(data, -1.0*GetAbilityArgumentFloat(boss, plugin_name, ability_name, 2, 5.0));
				ResetPack(data);
			}
			else
			{
				Call_PushCell(0);  //Status
				Call_Finish(action);
				BossCharge[boss][slot]=0.0;
			}
		}
		else if(BossCharge[boss][slot]<0.0)
		{
			Call_PushCell(1);  //Status
			Call_Finish(action);
			BossCharge[boss][slot]+=0.1;
		}
		else
		{
			Call_PushCell(0);  //Status
			Call_Finish(action);
		}
	}

	return true;
}

public Action:Timer_UseBossCharge(Handle:timer, Handle:data)
{
	BossCharge[ReadPackCell(data)][ReadPackCell(data)]=ReadPackFloat(data);
	return Plugin_Continue;
}

public Native_IsEnabled(Handle:plugin, numParams)
{
	return Enabled;
}

public Native_MakeClientToBoss(Handle:plugin, numParams)
{

	// int goalboss;
	int client = GetNativeCell(1);
	int boss = GetNativeCell(2);
	// char bossName[120];
	// char name[120];
	// GetNativeString(2, name, sizeof(name));
	// bool validBoss = false;

	// Debug("MakeClientToBoss: %N %s", client, name);

	// 	ArrayList bossArray = int ArrayList();
	// int bossCount=0;

	/*
	for(int config; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		KvGetString(BossKV[config], "name", bossName, sizeof(bossName));
		if(!StrContains(bossName, name, false))
		{
			// bossArray.Push(config);
			// bossCount++;
			boss = config;
			// validBoss = true;
			break;
		}

		KvGetString(BossKV[config], "filename", bossName, sizeof(bossName));
		if(!StrContains(bossName, name, false))
		{
			// bossArray.Push(config);
			// bossCount++;
			boss = config;
			// validBoss = true;
			break;
		}
	}
	*/
	// boss = bossArray.Get(GetRandomInt(0, bossCount-1));
	IsBossDoing[client] = true;
	if(boss > 0 && Boss[boss] <= 0)
	{
		Boss[boss] = client;
		Special[boss] = boss;

		Debug("MakeClientToBoss: %N %i", client, boss);
		MakeClientToBoss(boss);
	}
}

public Native_FF2Version(Handle:plugin, numParams)
{
	int version[3];  //Blame the compiler for this mess -.-
	version[0]=StringToInt(MAJOR_REVISION);
	version[1]=StringToInt(MINOR_REVISION);
	version[2]=StringToInt(STABLE_REVISION);
	SetNativeArray(1, version, sizeof(version));
	#if !defined DEV_REVISION
		return false;
	#else
		return true;
	#endif
}

public Native_GetBoss(Handle:plugin, numParams)
{
	int boss=GetNativeCell(1);
	if(boss>=0 && boss<=MaxClients && IsValidClient(Boss[boss]))
	{
		return GetClientUserId(Boss[boss]);
	}
	return -1;
}

public Native_GetIndex(Handle:plugin, numParams)
{
	return GetBossIndex(GetNativeCell(1));
}

public Native_GetTeam(Handle:plugin, numParams)
{
	return BossTeam;
}

public Native_GetSpecial(Handle:plugin, numParams)
{
	int index=GetNativeCell(1), dstrlen=GetNativeCell(3), see=GetNativeCell(4);
	decl String:s[dstrlen];
	if(see)
	{
		if(index<0) return false;
		if(!BossKV[index]) return false;
		KvRewind(BossKV[index]);
		KvGetString(BossKV[index], "name", s, dstrlen);
		SetNativeString(2, s,dstrlen);
	}
	else
	{
		if(index<0) return false;
		if(Special[index]<0) return false;
		if(!BossKV[Special[index]]) return false;
		KvRewind(BossKV[Special[index]]);
		KvGetString(BossKV[Special[index]], "name", s, dstrlen);
		SetNativeString(2, s,dstrlen);
	}
	return true;
}

public Native_GetBossHealth(Handle:plugin, numParams)
{
	return BossHealth[GetNativeCell(1)];
}

public Native_SetBossHealth(Handle:plugin, numParams)
{
	BossHealth[GetNativeCell(1)]=GetNativeCell(2);

	UpdateHealthBar();
}

public Native_GetBossMaxHealth(Handle:plugin, numParams)
{
	UpdateHealthBar();
	return BossHealthMax[GetNativeCell(1)];
}

public Native_SetBossMaxHealth(Handle:plugin, numParams)
{
	BossHealthMax[GetNativeCell(1)]=GetNativeCell(2);
}

public Native_GetBossLives(Handle:plugin, numParams)
{
	return BossLives[GetNativeCell(1)];
}

public Native_SetBossLives(Handle:plugin, numParams)
{
	BossLives[GetNativeCell(1)]=GetNativeCell(2);
}

public Native_GetBossMaxLives(Handle:plugin, numParams)
{
	return BossLivesMax[GetNativeCell(1)];
}

public Native_SetBossMaxLives(Handle:plugin, numParams)
{
	BossLivesMax[GetNativeCell(1)]=GetNativeCell(2);
}

public Native_GetBossCharge(Handle:plugin, numParams)
{
	return _:BossCharge[GetNativeCell(1)][GetNativeCell(2)];
}

public Native_SetBossCharge(Handle:plugin, numParams)  //TODO: This duplicates logic found in Timer_UseBossCharge
{
	BossCharge[GetNativeCell(1)][GetNativeCell(2)]=Float:GetNativeCell(3);
}

public Native_GetBossRageDamage(Handle:plugin, numParams)
{
	return BossRageDamage[GetNativeCell(1)];
}

public Native_SetBossRageDamage(Handle:plugin, numParams)
{
	BossRageDamage[GetNativeCell(1)]=GetNativeCell(2);
}

public Native_GetRoundState(Handle:plugin, numParams)
{
	if(CheckRoundState()<=0)
	{
		return 0;
	}
	return CheckRoundState();
}

public Native_GetRageDist(Handle:plugin, numParams)
{
	int index=GetNativeCell(1);
	decl String:plugin_name[64];
	GetNativeString(2,plugin_name,64);
	decl String:ability_name[64];
	GetNativeString(3,ability_name,64);

	if(!BossKV[Special[index]]) return _:0.0;
	KvRewind(BossKV[Special[index]]);
	decl Float:see;
	if(!ability_name[0])
	{
		return _:KvGetFloat(BossKV[Special[index]],"ragedist",400.0);
	}
	decl String:s[10];
	for(int i=1; i<MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if(KvJumpToKey(BossKV[Special[index]],s))
		{
			decl String:ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if(strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			if((see=KvGetFloat(BossKV[Special[index]],"dist",-1.0))<0)
			{
				KvRewind(BossKV[Special[index]]);
				see=KvGetFloat(BossKV[Special[index]],"ragedist",400.0);
			}
			return _:see;
		}
	}
	return _:0.0;
}

public Native_HasAbility(Handle:plugin, numParams)
{
	char pluginName[64], abilityName[64];

	int boss=GetNativeCell(1);
	GetNativeString(2, pluginName, sizeof(pluginName));
	GetNativeString(3, abilityName, sizeof(abilityName));
	// bool IsUpgradeRage = false;
	if(boss==-1 || Special[boss]==-1 || !BossKV[Special[boss]])
	{
		return false;
	}

/*
	if(numParams >= 4)
	{
		IsUpgradeRage = GetNativeCell(4);
	}
*/
	KvRewind(BossKV[Special[boss]]);
	if(!BossKV[Special[boss]])
	{
		LogError("Failed KV: %i %i", boss, Special[boss]);
		return false;
	}

	char ability[12];
	for(int i=1; i<MAXRANDOMS; i++)
	{
		Format(ability, sizeof(ability), "ability%i", i);
		if(KvJumpToKey(BossKV[Special[boss]], ability))  //Does this ability number exist?
		{
			char abilityName2[64];
			KvGetString(BossKV[Special[boss]], "name", abilityName2, sizeof(abilityName2));
			if(StrEqual(abilityName, abilityName2))  //Make sure the ability names are equal
			{
				char pluginName2[64];
				KvGetString(BossKV[Special[boss]], "plugin_name", pluginName2, sizeof(pluginName2));
				if(!pluginName[0] || !pluginName2[0] || StrEqual(pluginName, pluginName2))  //Make sure the plugin names are equal
				{
					/*
					if(IsUpgradeRage)
					{
						if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) <= 0)
							continue;
					}
					else
					{
						if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) > 0)
							continue;
					}
					*/

					if(KvGetNum(BossKV[Special[boss]], "is_upgrade_rage", 0) > 0)
						continue;

					return true;
				}
			}
			KvGoBack(BossKV[Special[boss]]);
		}
	}
	return false;
}

public Native_DoAbility(Handle:plugin, numParams)
{
	decl String:plugin_name[64];
	decl String:ability_name[64];
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	UseAbility(ability_name,plugin_name, GetNativeCell(1), GetNativeCell(4), GetNativeCell(5));
}

public Native_GetAbilityArgument(Handle:plugin, numParams)
{
	decl String:plugin_name[64];
	decl String:ability_name[64];
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	return GetAbilityArgument(GetNativeCell(1),plugin_name,ability_name,GetNativeCell(4),GetNativeCell(5));
}

public Native_GetAbilityArgumentFloat(Handle:plugin, numParams)
{
	decl String:plugin_name[64];
	decl String:ability_name[64];
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	return _:GetAbilityArgumentFloat(GetNativeCell(1),plugin_name,ability_name,GetNativeCell(4),GetNativeCell(5));
}

public Native_GetAbilityArgumentString(Handle:plugin, numParams)
{
	decl String:plugin_name[64];
	GetNativeString(2,plugin_name,64);
	decl String:ability_name[64];
	GetNativeString(3,ability_name,64);
	int dstrlen = GetNativeCell(6);
	char[] s = new char[dstrlen+1];
	GetAbilityArgumentString(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), s, dstrlen);
	SetNativeString(5,s,dstrlen);
}

public Native_GetDamage(Handle:plugin, numParams)
{
	int client=GetNativeCell(1);
	if(!IsValidClient(client))
	{
		return 0;
	}
	return Damage[client];
}

public Native_SetDamage(Handle:plugin, numParams)
{
	Damage[GetNativeCell(1)] = GetNativeCell(2);
}

public Native_GetFF2flags(Handle:plugin, numParams)
{
	return FF2flags[GetNativeCell(1)];
}

public Native_SetFF2flags(Handle:plugin, numParams)
{
	FF2flags[GetNativeCell(1)]=GetNativeCell(2);
}

public Native_GetFF2Userflags(Handle:plugin, numParams)
{
	return FF2Userflags[GetNativeCell(1)];
}

public Native_SetFF2Userflags(Handle:plugin, numParams)
{
	FF2Userflags[GetNativeCell(1)]=GetNativeCell(2);
}

public Native_GetQueuePoints(Handle:plugin, numParams)
{
	return GetClientQueuePoints(GetNativeCell(1));
}

public Native_SetQueuePoints(Handle:plugin, numParams)
{
	SetClientQueuePoints(GetNativeCell(1), GetNativeCell(2));
}

public Native_GetSpecialKV(Handle:plugin, numParams)
{
	int index=GetNativeCell(1);
	bool isNumOfSpecial=bool:GetNativeCell(2);
	if(isNumOfSpecial)
	{
		if(index!=-1 && index<Specials)
		{
			if(BossKV[index]!=INVALID_HANDLE)
			{
				KvRewind(BossKV[index]);
			}
			return _:BossKV[index];
		}
	}
	else
	{
		if(index!=-1 && index<=MaxClients && Special[index]!=-1 && Special[index]<MAXSPECIALS)
		{
			if(BossKV[Special[index]]!=INVALID_HANDLE)
			{
				KvRewind(BossKV[Special[index]]);
			}
			return _:BossKV[Special[index]];
		}
	}
	return _:INVALID_HANDLE;
}

public Native_LoadMusicData(Handle:plugin, numParams)
{
	LoadedMusicData=Handle:GetNativeCell(1);
}

public Native_StartMusic(Handle:plugin, numParams)
{
	StartMusic(GetNativeCell(1));
}

public Native_StopMusic(Handle:plugin, numParams)
{
	StopMusic(GetNativeCell(1));
}

public Native_RandomSound(Handle:plugin, numParams)
{
	int length=GetNativeCell(3)+1;
	int boss=GetNativeCell(4);
	int slot=GetNativeCell(5);
	char[] sound = new char[length];
	int kvLength;

	GetNativeStringLength(1, kvLength);
	kvLength++;

	decl String:keyvalue[kvLength];
	GetNativeString(1, keyvalue, kvLength);

	bool soundExists;
	if(!strcmp(keyvalue, "sound_ability"))
	{
		soundExists=RandomSoundAbility(keyvalue, sound, length, boss, slot);
	}
	else
	{
		soundExists=RandomSound(keyvalue, sound, length, boss);
	}
	SetNativeString(2, sound, length);
	return soundExists;
}

public Native_GetClientGlow(Handle:plugin, numParams)
{
	int client=GetNativeCell(1);
	if(IsValidClient(client))
	{
		return _:GlowTimer[client];
	}
	else
	{
		return -1;
	}
}

public Native_SetClientGlow(Handle:plugin, numParams)
{
	SetClientGlow(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public Native_GetAlivePlayers(Handle:plugin, numParams)
{
	return RedAlivePlayers;
}

public Native_GetBossPlayers(Handle:plugin, numParams)
{
	return BlueAlivePlayers;
}

public Native_Debug(Handle:plugin, numParams)
{
	return GetConVarBool(cvarDebug);
}

public Native_IsVSHMap(Handle:plugin, numParams)
{
	return false;
}

public Native_GetServerFlags(Handle:plugin, numParams)
{
	return FF2ServerFlag;
}

public Native_SetServerFlags(Handle:plugin, numParams)
{
	FF2ServerFlag=GetNativeCell(1);
}

public Native_GetAbilityDuration(Handle:plugin, numParams)
{
	return _:BossAbilityDuration[GetNativeCell(1)][GetNativeCell(2)];
}

public Native_SetAbilityDuration(Handle:plugin, numParams)
{
	BossAbilityDuration[GetNativeCell(1)][GetNativeCell(3)]=GetNativeCell(2);
}

public Native_GetAbilityCooldown(Handle:plugin, numParams)
{
	return _:BossAbilityCooldown[GetNativeCell(1)][GetNativeCell(2)];
}

public Native_SetAbilityCooldown(Handle:plugin, numParams)
{
	BossAbilityCooldown[GetNativeCell(1)][GetNativeCell(3)]=GetNativeCell(2);
}
// Native_GetBossMaxRageCharge
public Native_GetBossMaxRageCharge(Handle:plugin, numParams)
{
	return _:BossMaxRageCharge[GetNativeCell(1)];
}

public Native_SetBossMaxRageCharge(Handle:plugin, numParams)
{
	BossMaxRageCharge[GetNativeCell(1)]=GetNativeCell(2);
}

public Action:VSH_OnIsSaxtonHaleModeEnabled(&result)
{
	if((!result || result==1) && Enabled)
	{
		result=2;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSaxtonHaleTeam(&result)
{
	if(Enabled)
	{
		result=BossTeam;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSaxtonHaleUserId(&result)
{
	if(Enabled && IsClientConnected(Boss[0]))
	{
		result=GetClientUserId(Boss[0]);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSpecialRoundIndex(&result)
{
	if(Enabled)
	{
		result=Special[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSaxtonHaleHealth(&result)
{
	if(Enabled)
	{
		result=BossHealth[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetSaxtonHaleHealthMax(&result)
{
	if(Enabled)
	{
		result=BossHealthMax[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetClientDamage(client, &result)
{
	if(Enabled)
	{
		result=Damage[client];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:VSH_OnGetRoundState(&result)
{
	if(Enabled)
	{
		result=CheckRoundState();
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnTakeDamagePost(client, attacker, inflictor, Float:damage, damagetype)
{
	if(Enabled && IsBoss(client))
	{
		UpdateHealthBar();

		if(IsValidClient(attacker))
		{
			PlayerDamageDPS[attacker][DPSTick-1 < 0 ? sizeof(PlayerDamageDPS[])-1 : DPSTick-1] += damagetype & DMG_CRIT ? damage*3.0 : damage;
			// FIXME: 배열 크기 에러.

			if(GetPlayerDPS(attacker) > HighestDPS){
				HighestDPSClient=attacker;
				HighestDPS=GetPlayerDPS(attacker);
			}
		}

	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(GetConVarBool(cvarHealthBar))
	{
		if(StrEqual(classname, HEALTHBAR_CLASS))
		{
			healthBar=entity;
		}

		if(!IsValidEntity(g_Monoculus) && StrEqual(classname, MONOCULUS))
		{
			g_Monoculus=entity;
		}
	}

	if(!StrContains(classname, "item_healthkit", false) || !StrContains(classname, "item_ammopack", false) || StrEqual(classname, "tf_ammo_pack"))
	{
		SDKHook(entity, SDKHook_Spawn, OnItemSpawned);
	}
}

public OnEntityDestroyed(entity)
{
	if(entity==g_Monoculus)
	{
		g_Monoculus=FindEntityByClassname(-1, MONOCULUS);
		if(g_Monoculus==entity)
		{
			g_Monoculus=FindEntityByClassname(entity, MONOCULUS);
		}
	}
}

public OnItemSpawned(entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPickup);
	SDKHook(entity, SDKHook_Touch, OnPickup);
}

public Action:OnPickup(entity, client)  //Thanks friagram!
{
	if(IsBoss(client))
	{
		char classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!StrContains(classname, "item_healthkit", false))
		{
			if(!(FF2flags[client] & FF2FLAG_ALLOW_HEALTH_PICKUPS))
				return Plugin_Handled;

			if(TF2_IsPlayerInCondition(client, TFCond_OnFire))
				ExtinguishEntity(client);
			if(TF2_IsPlayerInCondition(client, TFCond_Bleeding))
				TF2_RemoveCondition(client, TFCond_Bleeding);

			return Plugin_Handled;
		}
		else if((!StrContains(classname, "item_ammopack", false) || StrEqual(classname, "tf_ammo_pack")))
		{
			if(!(FF2flags[client] & FF2FLAG_ALLOW_AMMO_PICKUPS))
				return Plugin_Handled;

			if(TF2_GetPlayerClass(client) == TFClass_Spy)
			{
				float cloakMeter = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter") + 0.2;
				if(cloakMeter > 100.0)
					cloakMeter = 100.0;

				SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", cloakMeter);  //Full cloak
			}

			for(int i=0; i<4; i++)
			{
				GivePlayerAmmo(client, 1, i, false);
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
		{
			return -1;
		}
		case RoundState_StartGame, RoundState_Preround:
		{
			return 0;
		}
		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
		{
			return 1;
		}
		default:
		{
			return 2;
		}
	}
	return -1;  //Compiler bug-doesn't recognize 'default' as a valid catch-all
}

public HealthbarEnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(Enabled && GetConVarBool(cvarHealthBar) && IsValidEntity(healthBar))
	{
		UpdateHealthBar();
	}
	else if(!IsValidEntity(g_Monoculus) && IsValidEntity(healthBar))
	{
		SetEntProp(healthBar, Prop_Send, HEALTHBAR_PROPERTY, 0);
	}
}

FormulaBossHealth(boss, bool:includeHealth=true)
{
	// int client=Boss[boss];
	int damaged = (BossHealthMax[boss]*BossLivesMax[boss]) - BossHealth[boss];

	KvRewind(BossKV[Special[boss]]);

	BossLivesMax[boss]=KvGetNum(BossKV[Special[boss]], "lives", 1);
	if(BossLivesMax[boss]<=0)
	{
		char bossName[80];
		KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName));
		PrintToServer("[FF2 Bosses] Warning: Boss %s has an invalid amount of lives, setting to 1", bossName);
		BossLivesMax[boss]=1;
	}

	BossHealthMax[boss]=ParseFormula(boss, "health_formula", "(((960.8+n)*(n-1))^1.0341)+2046", RoundFloat(Pow((760.8+float(playing))*(float(playing)-1.0), 1.0341)+2046.0));
	BossHealthLast[boss]=BossHealth[boss];
/*
	if(FF2Boss_IsPlayerBlasterReady(client))
		BossDiff[boss]=1;
*/

	switch(BossDiff[boss])
	{
	  case 2: // 하드
	  {
			BossHealthMax[boss]-=RoundFloat(float(BossHealthMax[boss])*0.2);
	  }
		case 3: // 배리 하드
		{
			BossHealthMax[boss]-=RoundFloat(float(BossHealthMax[boss])*0.3);
		}
		case 4:
		{
			BossHealthMax[boss]-=RoundFloat(float(BossHealthMax[boss])*0.4);
		}
		case 5:
		{
			BossHealthMax[boss]-=RoundFloat(float(BossHealthMax[boss])*0.5);
			// FF2flags[client]|=FF2FLAG_NOTALLOW_RAGE;
		}
	}

	BossHealth[boss]=BossHealthMax[boss]*BossLivesMax[boss];
	BossLives[boss]=BossLivesMax[boss];

	if(!includeHealth)
	{
		BossHealth[boss] -= damaged;

		while(damaged > BossHealthMax[boss])
		{
		  damaged -= BossHealthMax[boss];
		  BossLives[boss]--;
		}
	}

	if(BossHealth[boss] < 1)
		BossHealth[boss] = 100;
}

UpdateHealthBar()
{
	if(!Enabled || !GetConVarBool(cvarHealthBar) || IsValidEntity(g_Monoculus) || !IsValidEntity(healthBar) || CheckRoundState()==-1)
	{
		return;
	}

	int healthAmount, maxHealthAmount, bosses, healthPercent;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
		{
			bosses++;
			healthAmount+=BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
			maxHealthAmount+=BossHealthMax[boss];
		}
	}

	if(bosses)
	{
		healthPercent=RoundToCeil(float(healthAmount)/float(maxHealthAmount)*float(HEALTHBAR_MAX));
		if(healthPercent>HEALTHBAR_MAX)
		{
			healthPercent=HEALTHBAR_MAX;
		}
		else if(healthPercent<=0)
		{
			healthPercent=1;
		}
	}
	SetEntProp(healthBar, Prop_Send, HEALTHBAR_PROPERTY, healthPercent);
}

SetClientGlow(client, Float:time1, Float:time2=-1.0)
{
	if(IsValidClient(client))
	{
		GlowTimer[client]+=time1;
		if(time2>=0)
		{
			GlowTimer[client]=time2;
		}

		if(GlowTimer[client]<=0.0)
		{
			GlowTimer[client]=0.0;
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
		}
	}
}

CloseLoadMusicTimer()
{
	if(LoadedMusicData)
	{
		CloseHandle(LoadedMusicData);
		LoadedMusicData=INVALID_HANDLE;
	}
}

float GetPlayerDPS(int client)
{
	if(!IsValidClient(client) || IsBoss(client)) return 0.0;

	float damage;
	for(int loop=0; loop<sizeof(PlayerDamageDPS[]); loop++)
	{
		damage+=PlayerDamageDPS[client][loop];
	}

	return damage/float(sizeof(PlayerDamageDPS[]));
}

public GetYouSpecialString(client, String:cookie[], buffer)
{
	GetClientCookie(client, YouSpecial, cookie, buffer);
}

SetYouSpecialString(client, String:cookie[])
{
	SetClientCookie(client, YouSpecial, cookie);
	CPrintToChat(client, "{olive}[FF2]{default} {green}%s{default}로 설정되었습니다.", cookie);
}

#include <freak_fortress_2_vsh_feedback>
