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

stock bool IsFF2Map(char[] currentmap)
{
	char config[PLATFORM_MAX_PATH];

	if(FileExists("bNextMapToFF2"))
	{
		return true;
	}

	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/maps.cfg");
	if(!FileExists(config))
	{
		LogError("[FF2] Unable to find %s, disabling plugin.", config);
		return false;
	}

	Handle file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogError("[FF2] Error reading maps from %s, disabling plugin.", config);
		return false;
	}

	int tries;
	while(ReadFileLine(file, config, sizeof(config)) && tries < 100)
	{
		tries++;
		if(tries == 100)
		{
			LogError("[FF2] Breaking infinite loop when trying to check the map.");
			return false;
		}

		Format(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
		{
			continue;
		}

		if(!StrContains(currentmap, config, false) || !StrContains(config, "all", false))
		{
			CloseHandle(file);
			return true;
		}
	}
	CloseHandle(file);
	return false;
}

stock void DoOverlay(const int client, const char[] overlay)
{
	int flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", flags);
}

stock int FindHealthBar()
{
	int healthBar = FindEntityByClassname(-1, HEALTHBAR_CLASS);
	if(!IsValidEntity(healthBar))
	{
		return healthBar;
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

stock int GetClientCloakIndex(int client)
{
	if(!IsValidClient(client, false))
	{
		return -1;
	}

	int weapon = GetPlayerWeaponSlot(client, 4);
	if(!IsValidEntity(weapon))
	{
		return -1;
	}

	char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if(strncmp(classname, "tf_wea", 6, false))
	{
		return -1;
	}
	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
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
