#define HEALTHBAR_CLASS "monster_resource"

public void GetDifficultyString(int difficulty, char[] diff, buffer)
{
	char item[50];
	// TODO: 다국어 지원
	switch(difficulty)
	{
	  case 1:
	  {
			Format(item, sizeof(item), "%s", "보통");
	  }
		case 2:
		{
			Format(item, sizeof(item), "%s", "어려움");
		}
		case 3:
		{
			Format(item, sizeof(item), "%s", "매우 어려움");
		}
		case 4:
		{
			Format(item, sizeof(item), "%s", "너무 어려움");
		}
		case 5:
		{
			Format(item, sizeof(item), "%s", "불지옥");
		}
	}
	Format(diff, buffer, "%s", item);
}

stock int FindHealthBar()
{
	int healthBar = FindEntityByClassname(-1, HEALTHBAR_CLASS);
	if(!IsValidEntity(healthBar))
	{
		return CreateEntityByName(HEALTHBAR_CLASS);
	}
	return -1;
}

stock int GetHealingTarget(int client, bool checkgun = false)
{
	int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!checkgun)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
		{
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
		}
		return -1;
	}

	if(IsValidEntity(medigun))
	{
		char classname[64];
		GetEntityClassname(medigun, classname, sizeof(classname));
		if(!strcmp(classname, "tf_weapon_medigun", false))
		{
			if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			{
				return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
			}
		}
	}
	return -1;
}

stock bool IsValidClient(int client, bool replaycheck = true)
{
	if(client <= 0 || client > MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}
