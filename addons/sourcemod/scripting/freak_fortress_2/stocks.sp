#define HEALTHBAR_CLASS "monster_resource"

public void GetDifficultyString(BossDifficulty difficulty, char[] diff, int buffer)
{
	char item[50];
	// TODO: 다국어 지원
	switch(difficulty)
	{
		case Difficulty_Easy:
		{
			Format(item, sizeof(item), "%s", "쉬움");
		}
		case Difficulty_Normal:
		{
			Format(item, sizeof(item), "%s", "보통");
		}
		case Difficulty_Hard:
		{
			Format(item, sizeof(item), "%s", "어려움");
		}
		case Difficulty_Tryhard:
		{
			Format(item, sizeof(item), "%s", "빡시게 어려움");
		}
		case Difficulty_Expert:
		{
			Format(item, sizeof(item), "%s", "전문가");
		}
		case Difficulty_Hell:
		{
			Format(item, sizeof(item), "%s", "불지옥");
		}
	}
	Format(diff, buffer, "%s", item);
}

stock bool IsFF2Map(char[] mapName)
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

		if(!StrContains(mapName, config, false) || !StrContains(config, "all", false))
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
	int healthBarIndex = FindEntityByClassname(-1, HEALTHBAR_CLASS);
	if(!IsValidEntity(healthBarIndex))
	{
		return healthBarIndex;
	}
	return -1;
}

stock bool MapHasMusic(bool forceRecalc = false)  //SAAAAAARGE
{
	bool hasMusic, found;
	if(forceRecalc)
	{
		found = false;
		hasMusic = false;
	}

	if(!found)
	{
		int entity=-1;
		char name[64];
		while((entity = FindEntityByClassname2(entity, "info_target"))!=-1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			if(!strcmp(name, "hale_no_music", false))
			{
				hasMusic = true;
			}
		}
		found = true;
	}
	return hasMusic;
}

stock RemovePlayerTarge(int client)
{
	int entity = MaxClients + 1;
	while((entity = FindEntityByClassname2(entity, "tf_wearable_demoshield")) != -1)
	{
		int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			if(index == 131
			|| index == 406
			|| index == 1099
			|| index == 1144)  //Chargin' Targe, Splendid Screen, Tide Turner, Festive Chargin' Targe
			{
				TF2_RemoveWearable(client, entity);
			}
		}
	}
}

stock bool IsDemoShield(int entity)
{
	int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");

	if(index==131 || index==406 || index==1099 || index==1144)  //Chargin' Targe, Splendid Screen, Tide Turner, Festive Chargin' Targe
	{
		return true;
	}

	return false;
}

stock RemovePlayerBack(int client, int[] indices, int length)
{
	if(length <= 0)
	{
		return;
	}

	int entity = MaxClients + 1;
	while((entity = FindEntityByClassname2(entity, "tf_wearable")) != -1)
	{
		char netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			{
				for(int i; i < length; i++)
				{
					if(index == indices[i])
					{
						TF2_RemoveWearable(client, entity);
					}
				}
			}
		}
	}
}

stock FindPlayerBack(int client, int index)
{
	int entity = MaxClients+1;
	while((entity = FindEntityByClassname2(entity, "tf_wearable")) != -1)
	{
		char netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass))
		&& StrEqual(netclass, "CTFWearable")
		&& GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == index
		&& GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client
		&& view_as<bool>(GetEntProp(entity, Prop_Send, "m_bDisguiseWearable")))
		{
			return entity;
		}
	}
	return -1;
}

stock int FindSentry(int client)
{
	int entity = -1;
	while((entity = FindEntityByClassname2(entity, "obj_sentrygun"))!=-1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder")==client)
		{
			return entity;
		}
	}
	return -1;
}

void ForceTeamWin(int team)
{
	int entity = FindEntityByClassname2(-1, "team_control_point_master");
	if(!IsValidEntity(entity))
	{
		entity = CreateEntityByName("team_control_point_master");
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(entity, "SetWinner");
}



stock void SetControlPoint(bool enable)
{
	int controlPoint = MaxClients+1;
	while((controlPoint = FindEntityByClassname2(controlPoint, "team_control_point"))!=-1)
	{
		if(controlPoint > MaxClients && IsValidEntity(controlPoint))
		{
			AcceptEntityInput(controlPoint, (enable ? "ShowModel" : "HideModel"));
			SetVariantInt(enable ? 0 : 1);
			AcceptEntityInput(controlPoint, "SetLocked");
		}
	}
}

stock void SetArenaCapEnableTime(float time)
{
	int entity = -1;
	if((entity = FindEntityByClassname2(-1, "tf_logic_arena")) != -1 && IsValidEntity(entity))
	{
		char timeString[32];
		FloatToString(time, timeString, sizeof(timeString));
		DispatchKeyValue(entity, "CapEnableDelay", timeString);
	}
}

stock AssignTeam(int client, int team)
{
	if(!GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))  //Living spectator check: 0 means that no class is selected
	{
		Debug("%N does not have a desired class!", client);
		if(IsBoss(client))
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", KvGetNum(BossKV[Boss[client].CharacterIndex], "class", 1));  //So we assign one to prevent living spectators
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
			TF2_SetPlayerClass(client, TFClassType:KvGetNum(BossKV[Boss[client].CharacterIndex], "class", 1));
		}
		else
		{
			Debug("Additional information: %N was not a boss");
			TF2_SetPlayerClass(client, TFClass_Scout);
		}
		TF2_RespawnPlayer(client);
	}
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, char[] att)
{
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL | FORCE_GENERATION);
	if(hWeapon == null)
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
				hWeapon.Close();
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

	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	hWeapon.Close();
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock int OnlyParisLeft(int bossTeam)
{
	int scouts;
	for(int client; client <= MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) != bossTeam)
		{
			if(TF2_GetPlayerClass(client) == TFClass_Scout
			|| (TF2_GetPlayerClass(client) == TFClass_Soldier && GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 237)
			|| (TF2_GetPlayerClass(client) == TFClass_Spy && (TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Stealthed)))
			)
			{
				scouts++;
			}
			else
			{
				return 0;
			}
		}
	}
	return scouts;
}

stock int GetIndexOfWeaponSlot(int client, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}

stock void StingShield(int client, int attacker, float position[3])
{
	EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
}


stock SpawnSmallHealthPackAt(int client, int team = 0)
{
	if(!IsValidClient(client, false) || !IsPlayerAlive(client))
	{
		return;
	}

	int healthpack = CreateEntityByName("item_healthkit_small");
	float position[3];
	GetClientAbsOrigin(client, position);
	position[2] += 20.0;
	if(IsValidEntity(healthpack))
	{
		DispatchKeyValue(healthpack, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(healthpack);
		SetEntProp(healthpack, Prop_Send, "m_iTeamNum", team, 4);
		SetEntityMoveType(healthpack, MOVETYPE_VPHYSICS);
		float velocity[3];//={float(GetRandomInt(-10, 10)), float(GetRandomInt(-10, 10)), 50.0};  //Q_Q
		velocity[0]=float(GetRandomInt(-10, 10)), velocity[1]=float(GetRandomInt(-10, 10)), velocity[2]=50.0;  //I did this because setting it on the creation of the vel variable was creating a compiler error for me.
		TeleportEntity(healthpack, position, NULL_VECTOR, velocity);
	}
}

stock void IncrementHeadCount(int client)
{
	if(!TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
	{
		TF2_AddCondition(client, TFCond_DemoBuff, -1.0);
	}

	int decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
	int health = GetClientHealth(client);
	SetEntProp(client, Prop_Send, "m_iDecapitations", decapitations + 1);
	SetEntityHealth(client, health + 15);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
}


stock int FindTeleOwner(int client)
{
	if(!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return -1;
	}

	int teleporter = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	char classname[32];

	if(IsValidEntity(teleporter)
	&& GetEntityClassname(teleporter, classname, sizeof(classname))
	&& !strcmp(classname, "obj_teleporter", false))
	{
		int owner = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
		if(IsValidClient(owner, false))
		{
			return owner;
		}
	}
	return -1;
}

stock void RandomlyDisguise(int client)	//Original code was mecha's, but the original code is broken and this uses a better method now.
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		int disguiseTarget = -1;
		int team = GetClientTeam(client);

		ArrayList disguiseArray = new ArrayList();
		for(int clientcheck; clientcheck <= MaxClients; clientcheck++)
		{
			if(IsValidClient(clientcheck) && GetClientTeam(clientcheck)==team && clientcheck!=client)
			{
				disguiseArray.Push(clientcheck);
			}
		}

		if(disguiseArray.Length <= 0)
		{
			disguiseTarget = client;
		}
		else
		{
			disguiseTarget = disguiseArray.Get(GetRandomInt(0, GetArraySize(disguiseArray)-1));
			if(!IsValidClient(disguiseTarget))
			{
				disguiseTarget = client;
			}
		}

		int class = GetRandomInt(0, 4);
		TFClassType classArray[] = {TFClass_Scout, TFClass_Pyro, TFClass_Medic, TFClass_Engineer, TFClass_Sniper};
		delete disguiseArray;

		if(TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			TF2_DisguisePlayer(client, view_as<TFTeam>(team), classArray[class], disguiseTarget);
		}
		else
		{
			TF2_AddCondition(client, TFCond_Disguised, -1.0);
			SetEntProp(client, Prop_Send, "m_nDisguiseTeam", team);
			SetEntProp(client, Prop_Send, "m_nDisguiseClass", classArray[class]);
			SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", disguiseTarget);
			SetEntProp(client, Prop_Send, "m_iDisguiseHealth", 200);
		}
	}
}

stock int ShowGameText(char[] buffer, any ...)
{
    int textIndex = CreateEntityByName("game_text_tf");
    if(IsValidEntity(textIndex))
    {
        char message[512];
        VFormat(message, sizeof(message), buffer, 2);
        DispatchKeyValue(textIndex,"message", message);
        DispatchKeyValue(textIndex,"display_to_team", "0");
        DispatchKeyValue(textIndex,"icon", "ico_notify_sixty_seconds");
        DispatchKeyValue(textIndex,"targetname", "game_text1");
        DispatchKeyValue(textIndex,"background", "0");
        DispatchSpawn(textIndex);
        AcceptEntityInput(textIndex, "Display", textIndex, textIndex);
        CreateTimer(2.5, KillGameText, textIndex);
        return textIndex;
    }
    return -1;
}

public Action KillGameText(Handle hTimer, any textIndex)
{
    if ((textIndex > 0) && IsValidEntity(textIndex))
        AcceptEntityInput(textIndex, "kill");
    return Plugin_Stop;
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


stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while(startEnt > -1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
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
