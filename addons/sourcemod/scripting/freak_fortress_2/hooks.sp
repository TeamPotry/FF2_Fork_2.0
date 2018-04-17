public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if(Enabled && IsBoss(client) && CheckRoundState() == 1 && !TF2_IsPlayerCritBuffed(client) && !BossCrits)
	{
		result = false;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int client, int &attacker,  int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!Enabled || !IsValidEntity(attacker))
	{
		return Plugin_Continue;
	}

	static bool foundDmgCustom, bool dmgCustomInOTD;
	bool Change = false;

	if(!foundDmgCustom)
	{
		dmgCustomInOTD = (GetFeatureStatus(FeatureType_Capability, "SDKHook_DmgCustomInOTD") == FeatureStatus_Available);
		foundDmgCustom = true;
	}

	if(attacker <= 0 || client == attacker)
	{
		if(IsBoss(client))
		{
			if(IsBossYou[client] && attacker > 0)
			{
				Boss[GetBossIndex(client)].HealthPoint -= RoundFloat(damage);
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
		damage *= 0.0;
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
				damage *= 0.3;
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffMmmph))
			{
				damage *= 9;
				TF2_AddCondition(client, TFCond_Bonked, 0.1);
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
			{
				damage *= 0.25;
				return Plugin_Changed;
			}

			if(shield[client] && damage > 30.0)
			{
				Change = true;

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

			if(TF2_GetPlayerClass(client) == TFClass_Soldier && IsValidEntity((weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)))
			&& GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 226 && !(FF2flags[client] & FF2FLAG_ISBUFFED))  //Battalion's Backup
			{
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
			}

			if(damagecustom == TF_CUSTOM_BOOTS_STOMP)
			{
				damage *= 13.0;
				Change = true;
			}
/*
			if(damage <= 160.0)  //TODO: Wat
			{
				damage *= 3;
				return Plugin_Changed;
			}
*/
		}
	}
	else
	{
		int boss = GetBossIndex(client);
		if(boss != -1)
		{
			if(attacker <= MaxClients)
			{
				bool bIsTelefrag, bIsBackstab, bIsFacestab;
				if(dmgCustomInOTD)
				{
					char classname[32];

					if(damagecustom == TF_CUSTOM_BACKSTAB)
					{
						bIsBackstab = true;
					}
					else if(FF2Userflags[attacker] & FF2USERFLAG_ALLOW_FACESTAB &&
					IsValidEntity(weapon) && GetEntityClassname(weapon, classname, sizeof(classname)) &&
						!StrContains(classname, "tf_weapon_knife", false) && !(damagecustom & TF_CUSTOM_BACKSTAB))
					{
						bIsFacestab = true;
					}
					else if(damagecustom == TF_CUSTOM_TELEFRAG)
					{
						bIsTelefrag = true;
					}
				}
				else if(weapon != 4095 && IsValidEntity(weapon) && weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) && damage>1000.0)
				{
					char classname[32];
					if(GetEntityClassname(weapon, classname, sizeof(classname)) && !StrContains(classname, "tf_weapon_knife", false))
					{
						bIsBackstab = true;
					}
				}
				else if(!IsValidEntity(weapon) && (damagetype & DMG_CRUSH) == DMG_CRUSH && damage == 1000.0)
				{
					bIsTelefrag = true;
				}
				/////////////////
				if(GetClientButtons(client) & IN_DUCK && GetEntityFlags(client) & FL_ONGROUND)
				{
					Change = true;
					damagetype |= DMG_PREVENT_PHYSICS_FORCE;
				}
				////////////////

				if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
				{
					Change = true;
					damagetype |= ~DMG_CRIT;
				}

				int index;
				char classname[64];
				if(IsValidEntity(weapon) && weapon>MaxClients && attacker <= MaxClients)
				{
					GetEntityClassname(weapon, classname, sizeof(classname));
					if(!StrContains(classname, "eyeball_boss"))  //Dang spell Monoculuses
					{
						index = -1;
						Format(classname, sizeof(classname), "");
					}
					else
					{
						index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
					}
				}
				else
				{
					index = -1;
					Format(classname, sizeof(classname), "");
				}

				//Sniper rifles aren't handled by the switch/case because of the amount of reskins there are
				if(!StrContains(classname, "tf_weapon_sniperrifle"))
				{
					if(CheckRoundState() != 2)
					{
						float charge = (IsValidEntity(weapon) && weapon>MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
						if(index == 752)  //Hitman's Heatmaker
						{
							float focus = 10 + (charge / 10);
							if(TF2_IsPlayerInCondition(attacker, TFCond_FocusBuff))
							{
								focus /= 3;
							}
							float rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
							SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage + focus > 100) ? 100.0 : rage + focus);
						}
						else if(index != 230 && index != 402 && index != 526 && index != 30665)  //Sydney Sleeper, Bazaar Bargain, Machina, Shooting Star
						{
							float time = (GlowTimer[boss] > 10 ? 1.0 : 2.0);
							time += (GlowTimer[boss] > 10 ? (GlowTimer[boss] > 20 ? 1.0 : 2.0) : 4.0) * (charge / 100.0);
							SetClientGlow(Boss[boss].ClientIndex, time);
							if(GlowTimer[boss] > 30.0)
							{
								GlowTimer[boss] = 30.0;
							}
						}

						if(!(damagetype & DMG_CRIT))
						{
							if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
							{
								damage *= 3.0;
							}
							else
							{
								float clientPos[3];
								float attackerPos[3];
								GetClientEyePosition(client, clientPos);
								GetClientEyePosition(attacker, attackerPos);

								if(GetVectorDistance(clientPos, attackerPos) > 700.0)
								{
									damagetype |= DMG_PREVENT_PHYSICS_FORCE;
								}

								if(index != 230)  //Sydney Sleeper
								{
									damage *= damagecustom == TF_CUSTOM_HEADSHOT ? 3.5 : 1.8;
								}
								else
								{
									if(damagecustom & TF_CUSTOM_HEADSHOT)
									{
										Boss[boss].SetCharge(0, Boss[boss].GetCharge(0) - 8.0);
									}

									damage *= damagecustom == TF_CUSTOM_HEADSHOT ? 3.5 : 1.8;
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
						Change = true;
						ScaleVector(damageForce, 0.5);
					}
				}

				if(TF2_GetPlayerClass(attacker) == TFClass_Heavy)
				{
					// if(!(damagetype & DMG_CRIT))
					Change = true;
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
							damagetype |= DMG_PREVENT_PHYSICS_FORCE;
						}
						else if(sentryCount > 1)
						{
							ScaleVector(damageForce, 1.0 / float(sentryCount));
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
						if(damagecustom == TF_CUSTOM_HEADSHOT)
						{
							if(damage < 85.0)	damage = 85.0;  //Final damage 255
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
						int health = GetClientHealth(attacker);
						int newhealth = health + 50;
						if(newhealth <= GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
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
						int health = GetClientHealth(attacker);
						int newhealth = health + 50;
						if(newhealth <= GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
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
						int health = GetClientHealth(attacker);
						int newhealth = health + 25;
						if(newhealth <= GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
						{
							SetEntityHealth(attacker, newhealth);
						}

						if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
						{
							TF2_RemoveCondition(attacker, TFCond_OnFire);
						}

						float charge = GetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter");
						if(charge + 25.0 >= 100.0)
						{
							SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", 100.0);
						}
						else
						{
							SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", charge + 25.0);
						}
					}
					case 355:  //Fan O' War
					{
						Boss[boss].SetCharge(0, (Boss[boss].GetCharge(0) - 7.0));
					}
					case 357:  //Half-Zatoichi
					{
						SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
						if(GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy") < 1)
						{
							SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
						}

						int health = GetClientHealth(attacker);
						int max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						int newhealth = health + 50;
						if(health < max + 100)
						{
							if(newhealth > max + 100)
							{
								newhealth = max + 100;
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

							bool bIsGroundMarket = FF2Userflags[attacker] & FF2USERFLAG_ALLOW_GROUNDMARKET && !TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping) && index != 307;

							char playerName[50];
							GetClientName(attacker, playerName, sizeof(playerName));

							char bossName[64];
							KvRewind(BossKV[Boss[boss].CharacterIndex]);
							KvGetString(BossKV[Boss[boss].CharacterIndex], "name", bossName, sizeof(bossName), "ERROR NAME");

							damage = (((float(Boss[boss].MaxHealthPoint) * float(Boss[boss].MaxLives)) * 0.07) / 3.0);
							damagetype |= DMG_CRIT;

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
							Call_PushCell(index == 307 ? Percent_Ullapool : bIsGroundMarket ? Percent_GroundMarketed : Percent_Marketed);
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
							Call_PushCell(index == 307 ? Percent_Ullapool : bIsGroundMarket ? Percent_GroundMarketed : Percent_Marketed);
							Call_PushCell(damage);
							Call_Finish();

							if(CheckedFirstRound)
							{
								Handle hStreak = CreateEvent("player_death", false);
								SetEventString(hStreak, "weapon", index == 307 ? "ullapool_caber_explosion" : "market_gardener");
								SetEventString(hStreak, "weapon_logclassname", index == 307 ? "ullapool_caber_explosion" : "market_gardener");
								SetEventInt(hStreak, "attacker", GetClientUserId(attacker));
								SetEventInt(hStreak, "userid", GetClientUserId(client));
								SetEventInt(hStreak, "death_flags", TF_DEATHFLAG_DEADRINGER);
								SetEventInt(hStreak, "kill_streak_wep", ++Marketed[attacker]);
								FireEvent(hStreak);
							}

							PrintHintText(attacker, "%t", index == 307 ? "Ullapool" : "Market Gardener");  //You just market-gardened the boss!
							PrintHintText(client, "%t", index == 307 ? "Ullapooled" : "Market Gardened");  //You just got market-gardened!


							CPrintToChatAll("{olive}[FF2]{default} %t", "Someone_do", playerName, index == 307 ? "울라풀 막대 공격" : bIsGroundMarket ? "지면 마켓가든" : "마켓가든", bossName, RoundFloat(damage*(255.0/85.0)), Marketed[attacker]);
							EmitSoundToClient(attacker, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);
							EmitSoundToClient(client, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);

							if(index == 307 && allowedDetonations - (++detonations[attacker]))
							{
								PrintHintText(attacker, "%t", "Detonations Left", allowedDetonations - detonations[attacker]);
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
							damage = 85.0;  //255 final damage
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
						for(int healer; healer <= MaxClients; healer++)
						{
							if(IsValidClient(healer) && IsPlayerAlive(healer) && (GetHealingTarget(healer, true) == attacker))
							{
								healers[healerCount] = healer;
								healerCount++;
							}
						}

						for(int healer; healer < healerCount; healer++)
						{
							if(IsValidClient(healers[healer]) && IsPlayerAlive(healers[healer]))
							{
								int medigun = GetPlayerWeaponSlot(healers[healer], TFWeaponSlot_Secondary);
								if(IsValidEntity(medigun))
								{
									char medigunClassname[64];
									GetEntityClassname(medigun, medigunClassname, sizeof(medigunClassname));
									if(StrEqual(medigunClassname, "tf_weapon_medigun", false))
									{
										float uber = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel") + (0.1 / healerCount);
										if(uber > 1.0)
										{
											uber = 1.0;
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
							damage /= 2.0;
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
						airStrikeDamage += damage;
						if(airStrikeDamage>=200.0)
						{
							SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
							airStrikeDamage-=200.0;
						}
					}*/
				}

				if(bIsBackstab || bIsFacestab)
				{
					float sliencedTime = 6.0; // TODO: 광역변수.
					bool slienced = false;

					damage = (((float(Boss[boss].MaxHealthPoint) * float(Boss[boss].MaxLives)) * 0.075) / 3.0);

					if(damage < 200.0)
					{
						damage = 500.0;
					}
					if(bIsFacestab)
					{
						damage /= 2.0;
					}

					damagetype |= DMG_CRIT;
					damagecustom = 0;


					EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
					EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
					EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+2.0);

					int viewmodel = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
					if(viewmodel > MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker) == TFClass_Spy)
					{
						int melee = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
						int animation = 41;
						switch(melee)
						{
							case 225, 356, 423, 461, 574, 649, 1071:  //Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan
							{
								animation = 15;
							}
							case 638:  //Sharp Dresser
							{
								animation = 31;
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

					if(index == 225 || index == 574 || bIsFacestab)  //Your Eternal Reward, Wanga Prick
					{
						slienced = true;
						// BossAbilityCooldown[boss][0] += sliencedTime; // TODO: 딜레이 1초로 변경
						CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
					}
					else if(index == 356)  //Conniver's Kunai
					{
						int health = GetClientHealth(attacker) + 200;
						if(health > 500)
						{
							health = 500;
						}
						SetEntityHealth(attacker, health);
					}
					else if(index == 461)  //Big Earner
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
						damage += 500.0 / 3.0;
					}

					if(GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 525)  //Diamondback
					{
						SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits") + 2);
					}

					char sound[PLATFORM_MAX_PATH];
					if(RandomSound("sound_stabbed", sound, sizeof(sound), boss))
					{
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, Boss[boss].ClientIndex, _, _, false);
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, Boss[boss].ClientIndex, _, _, false);
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
					KvRewind(BossKV[Boss[boss].CharacterIndex]);
					KvGetString(BossKV[Boss[boss].CharacterIndex], "name", bossName, sizeof(bossName), "ERROR NAME");

					CPrintToChatAll("{olive}[FF2]{default} %t", "Someone_do", playerName, bIsFacestab ? "페이스스탭" : "백스탭", bossName, RoundFloat(damage*(255.0/85.0)), Stabbed[attacker]);
					// if(slienced) CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_slienced", RoundFloat(BossAbilityCooldown[boss][0]));
					return Plugin_Changed;
				}
				else if(bIsTelefrag)
				{
					damagecustom = 0;
					if(!IsPlayerAlive(attacker))
					{
						damage = 1.0;
						return Plugin_Changed;
					}
					damage = (Boss[boss].HealthPoint > 9001 ? 9001.0 : float(GetEntProp(Boss[boss].ClientIndex, Prop_Send, "m_iHealth"))+90.0);

					int teleowner = FindTeleOwner(attacker);
					if(IsValidClient(teleowner) && teleowner != attacker)
					{
						Damage[teleowner] += 9001 * 3 / 5;
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
				char classname[64];
				if(GetEntityClassname(attacker, classname, sizeof(classname)) && !strcmp(classname, "trigger_hurt", false))
				{
					Action action = Plugin_Continue;
					Call_StartForward(OnTriggerHurt);
					Call_PushCell(boss);
					Call_PushCell(attacker);
					float damage2 = damage;
					Call_PushFloatRef(damage2);
					Call_Finish(action);
					if(action != Plugin_Stop && action != Plugin_Handled)
					{
						if(action == Plugin_Changed)
						{
							damage = damage2;
						}

						if(damage > 1500.0)
						{
							damage = 1500.0;
						}

						if(!strcmp(currentmap, "arena_arakawa_b3", false) && damage>1000.0)
						{
							damage = 490.0;
						}
						Boss[boss].HealthPoint -= RoundFloat(damage);
						Boss[boss].SetCharge(0, Boss[boss].GetCharge(0) + (damage * 100.0 / Boss[boss].RageDamage));
						if(Boss[boss].HealthPoint <= 0)  //Wat
						{
							damage *= 5;
						}

						return Plugin_Changed;
					}
					else
					{
						return action;
					}
				}
			}
		}
		else
		{
			int index = (IsValidEntity(weapon) && weapon>MaxClients && attacker <= MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if(index == 307)  //Ullapool Caber
			{
				if(detonations[attacker] < allowedDetonations)
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

			if(IsValidClient(client, false) && TF2_GetPlayerClass(client) == TFClass_Soldier)  //TODO: LOOK AT THIS
			{
				if(damagetype & DMG_FALL)
				{
					int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(secondary <= 0 || !IsValidEntity(secondary))
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
