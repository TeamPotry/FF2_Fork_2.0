FF2Boss Boss[MAXPLAYERS+1];
int BossHealthLast[MAXPLAYERS+1];
bool IsBossDoing[MAXPLAYERS+1];
bool BossCrits = false;

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
