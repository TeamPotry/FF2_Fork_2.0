public Action OnBroadcast(Event event, const char[] name, bool dontBroadcast)
{
    char sound[PLATFORM_MAX_PATH];
    event.GetString("sound", sound, sizeof(sound));
    if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action OnCallForMedic(int client, const char[] command, int args)
{
	if(!Enabled || !IsPlayerAlive(client) || CheckRoundState() != 1 || !IsBoss(client) || args != 2)
	{
		return Plugin_Continue;
	}

	int boss = GetBossIndex(client);
	if(boss == -1 || !Boss[boss].ClientIndex || !IsValidEntity(Boss[boss].ClientIndex))
	{
		return Plugin_Continue;
	}

	char arg1[4], arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
	{
		return Plugin_Continue;
	}

	if(RoundFloat(Boss[boss].GetCharge(0))>=100)
	{
		bool doUpgradeRage = (RoundFloat(Boss[boss].GetCharge(0)) >= 200) ? true : false;
		//
		doUpgradeRage = false;
		//
		bool hasUpgradeRage = false;
		if(Boss[boss].GetAbilityDuration(0) > 0.0 || Boss[boss].GetAbilityCooldown(0) > 0.0 || (!DEVmode && FF2flags[client] & FF2FLAG_NOTALLOW_RAGE))
		{
			CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_can_not_rage");
			return Plugin_Continue;
		}

		bool isSoloRage = false;

		char ability[10], lives[MAXRANDOMS][3];

		for(int i = 1; i < MAXRANDOMS; i++) // 강화 분노 체크용도로만.
		{
			Format(ability, sizeof(ability), "ability%i", i);
			KvRewind(BossKV[Boss[boss].CharacterIndex]);
			if(KvJumpToKey(BossKV[Boss[boss].CharacterIndex], ability))
			{
				if(KvGetNum(BossKV[Boss[boss].CharacterIndex], "arg0", 0))
				{
					continue;
				}

				KvGetString(BossKV[Boss[boss].CharacterIndex], "life", ability, sizeof(ability));
				if(!ability[0])
				{
					char abilityName[64], pluginName[64];
					KvGetString(BossKV[Boss[boss].CharacterIndex], "plugin_name", pluginName, sizeof(pluginName));
					KvGetString(BossKV[Boss[boss].CharacterIndex], "name", abilityName, sizeof(abilityName));
					if(doUpgradeRage)
					{
						if(KvGetNum(BossKV[Boss[boss].CharacterIndex], "is_upgrade_rage", 0) <= 0)
							continue;
						else
							hasUpgradeRage = true;
					}
					else
					{
						if(KvGetNum(BossKV[Boss[boss].CharacterIndex], "is_upgrade_rage", 0) > 0)
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
					int count = ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
					for(int j; j < count; j++)
					{
						if(StringToInt(lives[j]) == Boss[boss].Lives)
						{
							char abilityName[64], pluginName[64];
							KvGetString(BossKV[Boss[boss].CharacterIndex], "plugin_name", pluginName, sizeof(pluginName));
							KvGetString(BossKV[Boss[boss].CharacterIndex], "name", abilityName, sizeof(abilityName));

							if(doUpgradeRage)
							{
								if(KvGetNum(BossKV[Boss[boss].CharacterIndex], "is_upgrade_rage", 0) <= 0)
									continue;
								else
									hasUpgradeRage = true;
							}
							else
							{
								if(KvGetNum(BossKV[Boss[boss].CharacterIndex], "is_upgrade_rage", 0) > 0)
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
			for(int i = 1; i < MAXRANDOMS; i++)
			{
				Format(ability, sizeof(ability), "ability%i", i);
				KvRewind(BossKV[Boss[boss].CharacterIndex]);
				if(KvJumpToKey(BossKV[Boss[boss].CharacterIndex], ability))
				{
					if(KvGetNum(BossKV[Boss[boss].CharacterIndex], "arg0", 0))
					{
						continue;
					}

					KvGetString(BossKV[Boss[boss].CharacterIndex], "life", ability, sizeof(ability));
					if(!ability[0])
					{
						char abilityName[64], pluginName[64];
						KvGetString(BossKV[Boss[boss].CharacterIndex], "plugin_name", pluginName, sizeof(pluginName));
						KvGetString(BossKV[Boss[boss].CharacterIndex], "name", abilityName, sizeof(abilityName));

						if(!UseAbility(abilityName, pluginName, boss, 0))
						{
							return Plugin_Continue;
						}
					}
					else
					{
						int count = ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
						for(int j; j < count; j++)
						{
							if(StringToInt(lives[j]) == Boss[boss].Lives)
							{
								char abilityName[64], pluginName[64];
								KvGetString(BossKV[Boss[boss].CharacterIndex], "plugin_name", pluginName, sizeof(pluginName));
								KvGetString(BossKV[Boss[boss].CharacterIndex], "name", abilityName, sizeof(abilityName));

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
			KvRewind(BossKV[Boss[boss].CharacterIndex]);
			Boss[boss].SetAbilityDuration(0, KvGetFloat(BossKV[Boss[boss].CharacterIndex], "upgrade_ability_duration"));
			Boss[boss].SetCharge(0, Boss[boss].GetCharge(0) - 200.0);
		}
		else
		{
			IsUpgradeRage[boss] = false;
			Boss[boss].SetAbilityDuration(0, Boss[boss].GetMaxAbilityDuration(0));

			if(doUpgradeRage)
				CPrintToChat(client, "{olive}[FF2]{default} 이 보스에게 강화분노가 등록되지 않아서 일반 분노로 대체됩니다!");
			Boss[boss].SetCharge(0, Boss[boss].GetCharge(0) - 100.0);
		}

		float position[3];
		float victimPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		float rageDist=KvGetFloat(BossKV[Boss[boss].CharacterIndex], "ragedist", 300.0);
		char bossName[80];
		int find = 0; TFTeam team;

		GetEntPropVector(Boss[boss].ClientIndex, Prop_Send, "m_vecOrigin", position);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && IsPlayerAlive(i))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", victimPos);
				team = TF2_GetClientTeam(i);
				if(GetVectorDistance(position, victimPos) <= rageDist && _:team != BossTeam)
					find++;
			}
		}

		if(find  ==  1)
		{
			isSoloRage = true;
			KvRewind(BossKV[Boss[boss].CharacterIndex]);
			KvGetString(BossKV[Boss[boss].CharacterIndex], "name", bossName, sizeof(bossName), "ERROR NAME");
			CPrintToChatAll("{olive}[FF2]{default} %t", "oneperson_rage", bossName);
			Boss[boss].SetAbilityDuration(0, Boss[boss].GetMaxAbilityDuration(0) + 2.0);

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
			Boss[boss].SetAbilityDuration(0, Boss[boss].GetMaxAbilityDuration(0));
		}

		if(!isSoloRage)
		{
			for(int i=1; i<MAXRANDOMS; i++)
			{
				Format(ability, sizeof(ability), "ability%i", i);
				KvRewind(BossKV[Boss[boss].CharacterIndex]);
				if(KvJumpToKey(BossKV[Boss[boss].CharacterIndex], ability))
				{
					if(KvGetNum(BossKV[Boss[boss].CharacterIndex], "arg0", 0))
					{
						continue;
					}

					KvGetString(BossKV[Boss[boss].CharacterIndex], "life", ability, sizeof(ability));
					if(!ability[0])
					{
						char abilityName[64], pluginName[64];
						KvGetString(BossKV[Boss[boss].CharacterIndex], "plugin_name", pluginName, sizeof(pluginName));
						KvGetString(BossKV[Boss[boss].CharacterIndex], "name", abilityName, sizeof(abilityName));
						if(doUpgradeRage)
						{
							if(KvGetNum(BossKV[Boss[boss].CharacterIndex], "is_upgrade_rage", 0) <= 0)
								continue;
							else
								hasUpgradeRage = true;
						}
						else
						{
							if(KvGetNum(BossKV[Boss[boss].CharacterIndex], "is_upgrade_rage", 0) > 0)
								continue;
						}
						if(!UseAbility(abilityName, pluginName, boss, 0))
						{
							return Plugin_Continue;
						}
					}
					else
					{
						int count = ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
						for(int j; j < count; j++)
						{
							if(StringToInt(lives[j]) == Boss[boss].Lives)
							{
								char abilityName[64], pluginName[64];
								KvGetString(BossKV[Boss[boss].CharacterIndex], "plugin_name", pluginName, sizeof(pluginName));
								KvGetString(BossKV[Boss[boss].CharacterIndex], "name", abilityName, sizeof(abilityName));

								if(doUpgradeRage)
								{
									if(KvGetNum(BossKV[Boss[boss].CharacterIndex], "is_upgrade_rage", 0) <= 0)
										continue;
									else
										hasUpgradeRage = true;
								}
								else
								{
									if(KvGetNum(BossKV[Boss[boss].CharacterIndex], "is_upgrade_rage", 0) > 0)
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


		char sound[PLATFORM_MAX_PATH];
		if(RandomSoundAbility("sound_ability", sound, sizeof(sound), boss))
		{
			FF2flags[Boss[boss].ClientIndex]|=FF2FLAG_TALKING;
			EmitSoundToAll(sound, client, _, _, _, _, _, client, position);
			EmitSoundToAll(sound, client, _, _, _, _, _, client, position);

			for(int target=1; target<=MaxClients; target++)
			{
				if(IsClientInGame(target) && target!=Boss[boss].ClientIndex)
				{
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
				}
			}
			FF2flags[Boss[boss].ClientIndex]&=~FF2FLAG_TALKING;
		}
		emitRageSound[boss]=true;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
