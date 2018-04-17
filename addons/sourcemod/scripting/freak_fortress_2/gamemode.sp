int FF2flags[MAXPLAYERS+1];
int FF2Userflags[MAXPLAYERS+1];
int FF2ServerFlag;

char currentmap[99];
bool checkDoors=false;
bool bMedieval;
bool firstBlood;

bool CheckedFirstRound=false;
int RoundCount;
int playing;
int healthcheckused;
int RedAlivePlayers;
int BlueAlivePlayers;
bool DEVmode=false;
int timeleft;
float AFKTime;
bool Enabled=true;
bool Enabled2=true;
int PointDelay=6;
float Announce=120.0;
int AliveToEnable=5;
int PointType;
int arenaRounds;
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

int tf_arena_use_queue;
int mp_teams_unbalance_limit;
int tf_arena_first_blood;
int mp_forcecamera;
int tf_dropped_weapon_lifetime;
float tf_feign_death_activate_damage_scale;
float tf_feign_death_damage_scale;
char mp_humans_must_join_team[16];

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

float circuitStun;
Handle cvarNextmap;
int changeGamemode;

void FF2Cvar_Init()
{
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
}

public CvarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
    if(convar == cvarPointDelay)
    {
        PointDelay = StringToInt(newValue);
        if(PointDelay < 0)
        {
            PointDelay *= -1;
        }
    }
    else if(convar == cvarAnnounce)
    {
        Announce = StringToFloat(newValue);
    }
    else if(convar == cvarPointType)
    {
        PointType = StringToInt(newValue);
    }
    else if(convar == cvarPointDelay)
    {
        PointDelay = StringToInt(newValue);
    }
    else if(convar == cvarAliveToEnable)
    {
        AliveToEnable = StringToInt(newValue);
    }
    else if(convar == cvarCrits)
    {
        BossCrits = StringToInt(newValue) > 0;
    }
    else if(convar == cvarFirstRound)  //DEPRECATED
    {
        if(StringToInt(newValue) != -1)
        {
            arenaRounds = StringToInt(newValue) ? 0 : 1;
        }
    }
    else if(convar == cvarArenaRounds)
    {
        arenaRounds = StringToInt(newValue);
    }
    else if(convar == cvarCircuitStun)
    {
        circuitStun = StringToFloat(newValue);
    }
    else if(convar == cvarCountdownPlayers)
    {
        countdownPlayers = StringToInt(newValue);
    }
    else if(convar == cvarCountdownTime)
    {
        countdownTime = StringToInt(newValue);
    }
    else if(convar == cvarCountdownHealth)
    {
        countdownHealth = StringToInt(newValue);
    }
    else if(convar == cvarLastPlayerGlow)
    {
        lastPlayerGlow = StringToInt(newValue) > 0;
    }
    else if(convar == cvarSpecForceBoss)
    {
        SpecForceBoss = StringToInt(newValue) > 0;
    }
    else if(convar == cvarBossTeleporter)
    {
        bossTeleportation = StringToInt(newValue) > 0;
    }
    else if(convar == cvarShieldCrits)
    {
        shieldCrits = StringToInt(newValue);
    }
    else if(convar == cvarCaberDetonations)
    {
        allowedDetonations = StringToInt(newValue);
    }
    else if(convar == cvarGoombaDamage)
    {
        GoombaDamage = StringToFloat(newValue);
    }
    else if(convar == cvarGoombaRebound)
    {
        reboundPower = StringToFloat(newValue);
    }
    else if(convar == cvarBossRTD)
    {
        canBossRTD = StringToInt(newValue) > 0;
    }
    else if(convar == cvarEnabled)
    {
        StringToInt(newValue) ? (changeGamemode = Enabled ? 0 : 1) : (changeGamemode = !Enabled ? 0 : 2);
    }
}
