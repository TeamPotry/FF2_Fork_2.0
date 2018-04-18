int RPSLoser[MAXPLAYERS+1];

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

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || !CheckRoundState())
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int boss = GetBossIndex(client);
	int damage = GetEventInt(event, "damageamount");
	int custom = GetEventInt(event, "custom");
	// bool changeResult = false;

	if(boss == -1 || !Boss[boss].ClientIndex || !IsValidEntity(Boss[boss].ClientIndex) || client == attacker)
	{
		return Plugin_Continue;
	}

	if(custom == TF_CUSTOM_TELEFRAG)
	{
		damage=IsPlayerAlive(attacker) ? 9001 : 1;
	}
	else if(custom == TF_CUSTOM_BOOTS_STOMP)
	{
		if(IsBoss(attacker))
			damage *= 50;

		else
			damage *= 5;
	}

	if(GetEventBool(event, "minicrit") && GetEventBool(event, "allseecrit"))
	{
		event.SetBool("allseecrit", false);
	}

	if(custom == TF_CUSTOM_TELEFRAG || custom == TF_CUSTOM_BOOTS_STOMP)
	{
		event.SetInt("damageamount", damage);
	}

/*
	if(Boss[boss].HealthPoint - damage < 1 && Boss[boss].Difficulty > 1 &&
		(FF2_GetGameState() != Game_LastManStanding && FF2_GetGameState() != Game_SpecialLastManStanding)
	&& POTRY_IsClientVIP(client) && POTRY_IsClientEnableVIPEffect(client, VIPEffect_BossStandard))
	{
		// changeResult = true;
		// BossCharge[boss][0] = 100.0;
		Boss[boss].Difficulty = 1;
		FormulaBossHealth(boss, false);

		SetEntityHealth(client, Boss[boss].HealthPoint - Boss[boss].MaxHealthPoint * (Boss[boss].Lives-1));

		CPrintToChatAll("{olive}[FF2]{default} 이 보스는 {red}보스 스탠다드 플레이{default}가 활성화된 상태입니다. '{green}보통{default}' 난이도로 되돌아가 다시 싸웁니다!");
		event.SetInt("damageamount", 0);
		return Plugin_Changed;
	}
*/


	for(int lives = 1; lives < Boss[boss].Lives; lives++)
	{
		if(Boss[boss].HealthPoint - damage <= Boss[boss].MaxHealthPoint * lives)
		{
			SetEntityHealth(client, (Boss[boss].HealthPoint - damage) - Boss[boss].MaxHealthPoint * (lives - 1)); //Set the health early to avoid the boss dying from fire, etc.

			int bossLives = Boss[boss].Lives;  //Used for the forward
			Action action = Plugin_Continue;
			Call_StartForward(OnLoseLife);
			Call_PushCell(boss);
			Call_PushCellRef(bossLives);
			Call_PushCell(Boss[boss].MaxLives);
			Call_Finish(action);
			if(action == Plugin_Stop || action == Plugin_Handled)
			{
				return action;
			}
			else if(action == Plugin_Changed)
			{
				if(bossLives > Boss[boss].MaxLives)
				{
					Boss[boss].MaxLives = bossLives;
				}
				Boss[boss].Lives = bossLives;
			}

			char ability[PLATFORM_MAX_PATH];
			for(int n = 1; n < MAXRANDOMS; n++)
			{
				Format(ability, 10, "ability%i", n);
				KvRewind(BossKV[Boss[boss].CharacterIndex]);
				if(KvJumpToKey(BossKV[Boss[boss].CharacterIndex], ability))
				{
					if(KvGetNum(BossKV[Boss[boss].CharacterIndex], "arg0", 0) != -1)
					{
						continue;
					}

					KvGetString(BossKV[Boss[boss].CharacterIndex], "life", ability, 10);
					if(!ability[0])
					{
						char abilityName[64], pluginName[64];
						KvGetString(BossKV[Boss[boss].CharacterIndex], "plugin_name", pluginName, sizeof(pluginName));
						KvGetString(BossKV[Boss[boss].CharacterIndex], "name", abilityName, sizeof(abilityName));
						UseAbility(abilityName, pluginName, boss, -1);
					}
					else
					{
						char stringLives[MAXRANDOMS][3];
						int count = ExplodeString(ability, " ", stringLives, MAXRANDOMS, 3);
						for(int j; j < count; j++)
						{
							if(StringToInt(stringLives[j]) == Boss[boss].Lives)
							{
								char abilityName[64], pluginName[64];
								KvGetString(BossKV[Boss[boss].CharacterIndex], "plugin_name", pluginName, sizeof(pluginName));
								KvGetString(BossKV[Boss[boss].CharacterIndex], "name", abilityName, sizeof(abilityName));
								UseAbility(abilityName, pluginName, boss, -1);
								break;
							}
						}
					}
				}
			}
			Boss[boss].Lives = lives;

			char bossName[64];
			KvRewind(BossKV[Boss[boss].CharacterIndex]);
			KvGetString(BossKV[Boss[boss].CharacterIndex], "name", bossName, sizeof(bossName), "=Failed name=");

			strcopy(ability, sizeof(ability), Boss[boss].Lives == 1 ? "ff2_life_left" : "ff2_lives_left");
			for(int target = 1; target <= MaxClients; target++)
			{
				if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
				{
					PrintCenterText(target, "%t", ability, bossName, Boss[boss].Lives);
				}
			}

			if(Boss[boss].Lives == 1 && RandomSound("sound_last_life", ability, sizeof(ability), boss))
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

	Boss[boss].HealthPoint -= damage;
	Boss[boss].SetCharge(0, Boss[boss].GetCharge(0) + (damage * 100.0 / Boss[boss].RageDamage));

	if(!(FF2ServerFlag & FF2SERVERFLAG_UNCOLLECTABLE_DAMAGE)) Damage[attacker]+=damage;

	int healers[MAXPLAYERS];
	int healerCount;
	for(int target; target <= MaxClients; target++)
	{
		if(IsValidClient(target) && IsPlayerAlive(target) && (GetHealingTarget(target, true) == attacker))
		{
			healers[healerCount]=target;
			healerCount++;
		}
	}

	for(int target; target < healerCount; target++)
	{
		if(IsValidClient(healers[target]) && IsPlayerAlive(healers[target]))
		{
			if(damage < 10 || uberTarget[healers[target]] == attacker)
			{
				Damage[healers[target]]+=damage;
			}
			else
			{
				Damage[healers[target]] += damage / (healerCount + 1);
			}
		}
	}

	if(IsValidClient(attacker))
	{
		int weapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
		if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 1104)  //Air Strike-moved from OTD
		{//
			static airStrikeDamage;
			airStrikeDamage += damage;
			if(airStrikeDamage >= 200)
			{
				SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations") + 1);
				airStrikeDamage -= 200;
			}
		}
		// 이 코드는 타인의 코드에서 따옴.
		if(!IsBoss(attacker) && IsValidEntity(weapon))
		{
			static kStreakCount;
			kStreakCount += damage;
			if(kStreakCount >= 200)// TODO: 헬 예아.
			{
				SetEntProp(attacker, Prop_Send, "m_nStreaks", GetEntProp(attacker, Prop_Send, "m_nStreaks") + 1);
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
				kStreakCount -= 200;
			}
		}
	}
	// return changeResult ? Plugin_Handled : Plugin_Continue;
	return Plugin_Continue;
}
