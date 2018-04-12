#define MAXSPECIALS 64
#define MAXRANDOMS 16

Handle BossKV[MAXSPECIALS];
bool bBlockVoice[MAXSPECIALS];
float BossSpeed[MAXSPECIALS];

FF2Boss Boss[MAXPLAYERS+1];
int MainBoss;
int BossHealthLast[MAXPLAYERS+1];
bool IsBossDoing[MAXPLAYERS+1];
bool BossCrits = false;
bool IsUpgradeRage[MAXPLAYERS+1];

bool emitRageSound[MAXPLAYERS+1];

int OtherTeam=2; // TODO: DELETE IT.
int BossTeam=3;

stock bool IsBoss(int client)
{
	if(IsValidClient(client))
	{
		for(int boss; boss <= MaxClients; boss++)
		{
			if(Boss[boss].ClientIndex == client)
			{
				return true;
			}
		}
	}
	return false;
}

stock int GetBossIndex(int client)
{
	if(client == 0)
	{
		return MainBoss;
	}

	if(client > 0 && client<=MaxClients)
	{
		for(int boss = 0; boss <= MaxClients; boss++)
		{
			if(Boss[boss].ClientIndex == client)
			{
				return boss;
			}
		}
	}
	return -1;
}
