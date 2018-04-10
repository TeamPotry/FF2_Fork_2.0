public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle &item)
{
	if(!Enabled /*|| item != null*/)
	{
		return Plugin_Continue;
	}

	// Debug("TF2Items_OnGiveNamedItem: %N", client);
	switch(iItemDefinitionIndex)
	{
		case 38, 457:  //Axtinguisher, Postal Pummeler
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "", true);
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 15, 202, 298:
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "87 ; 0.40", true);
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}


/*		case 45:
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1", true);
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
*/
		case 39, 351, 1081:  //Flaregun, Detonator, Festive Flaregun
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "25 ; 0.5 ; 58 ; 3.2 ; 144 ; 1.0 ; 207 ; 1.33", true);
				//25: -50% ammo
				//58: 220% self damage force
				//144: NOPE
				//207: +33% damage to self
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 40, 1146:  //Backburner, Festive Backburner
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "165 ; 1.0");
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 224:  //L'etranger
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.8 ; 166 ; -8 ; 85 ; 0.5 ; 157 ; 1.0 ; 253 ; 1.0");
				//85: +50% time needed to regen cloak
				//157: +1 second needed to fully disguise
				//253: +1 second needed to fully cloak

				/*
				case 224:  // 이방인
				{
					Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.8 ; 166 ; 8 ; 83 ; 0.6");
						//179: Crit instead of mini-critting
					if(itemOverride != null)
					{
						item = itemOverride;
						return Plugin_Changed;
					}
				}
				*/
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 239, 1084, 1100:  //GRU, Festive GRU, Bread Bite
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.5 ; 107 ; 1.5 ; 128 ; 1 ; 772 ; 1.5", true);
				//1: -50% damage
				//107: +50% move speed
				//128: Only when weapon is active
				//191: -7 health/second
				//772: Holsters 50% slower
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 56, 1005, 1092:  //Huntsman, Festive Huntsman, Fortified Compound
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "2 ; 1.5 ; 76 ; 2");
				//2: +50% damage
				//76: +100% ammo
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		/*case 132, 266, 482:  //Eyelander, HHHH, Nessie's Nine Iron - commented out because
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "202 ; 0.5 ; 125 ; -15", true);
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}*/
		case 265:  //Stickybomb Jumper
		{
			Handle itemOverride = PrepareItemHandle(item, _, 265, "89 ; 0.2 ; 96 ; 1.6 ; 120 ; 99999.0 ; 3 ; 1.0 ; 89 ; -6.0 ; 280 ; 4 ; 477 ; 1.0");
				//241: No reload penalty
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 220:  //Shortstop
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "241 ; 1.0");
				//241: No reload penalty
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 226:  //Battalion's Backup
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "140 ; 10.0");
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 231:  //Darwin's Danger Shield
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "26 ; 50");  //+50 health
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 305, 1079:  //Crusader's Crossbow, Festive Crusader's Crossbow
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "2 ; 1.2 ; 17 ; 0.15");
				//2: +20% damage
				//17: +15% uber on hit
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 331:  //Fists of Steel
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "205 ; 0.8 ; 206 ; 2.0 ; 772 ; 2.0", true);
				//205: -80% damage from ranged while active
				//206: +100% damage from melee while active
				//772: Holsters 100% slower
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 415:  //Reserve Shooter
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "2 ; 1.1 ; 3 ; 0.5 ; 114 ; 1 ; 179 ; 1 ; 547 ; 0.6", true);
				//2: +10% damage bonus
				//3: -50% clip size
				//114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
				//179: Minicrits become crits
				//547: Deploys 40% faster
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 444:  //Mantreads
		{
			/*Handle itemOverride = PrepareItemHandle(item, _, _, "58 ; 1.5");
			if(itemOverride != null)
			{
				item = itemOverride;
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
			Handle itemOverride = PrepareItemHandle(item, _, _, "279 ; 3.0");
				//279: 2 ornaments
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 656:  //Holiday Punch
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "199 ; 0 ; 547 ; 0 ; 358 ; 0 ; 362 ; 0 ; 363 ; 0 ; 369 ; 0", true);
				//199: Holsters 100% faster
				//547: Deploys 100% faster
				//Other attributes: Because TF2Items doesn't feel like stripping the Holiday Punch's attributes for some reason
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 772:  //Baby Face's Blaster
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "2 ; 1.25 ; 109 ; 0.5 ; 125 ; -25 ; 394 ; 0.85 ; 418 ; 1 ; 419 ; 100 ; 532 ; 0.5 ; 651 ; 0.5 ; 709 ; 1", true);
				//2: +25% damage bonus
				//109: -50% health from packs on wearer
				//125: -25 max health
				//394: 15% firing speed bonus hidden
				//418: Build hype for faster speed
				//419: Hype resets on jump
				//532: Hype decays
				//651: Fire rate increases as health decreases
				//709: Weapon spread increases as health decreases
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 1103:  //Back Scatter
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "179 ; 1");
				//179: Crit instead of mini-critting
			if(itemOverride != null)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		case 460:  // 집행자
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "2 ; 1.3 ; 166 ; -20");
				//179: Crit instead of mini-critting
			if(itemOverride != null)
			{
				item = itemOverride;
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

		if(itemOverride != null)
		{
			item = itemOverride;
			return Plugin_Changed;
		}
	}

	if(TF2_GetPlayerClass(client)==TFClass_Soldier && (!StrContains(classname, "tf_weapon_rocketlauncher", false)))
	{
		Handle itemOverride;
		if(iItemDefinitionIndex == 127)  //Direct Hit
		{
			itemOverride = PrepareItemHandle(item, _, _, "114 ; 1 ; 179 ; 1.0");
				//114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
				//179: Mini-crits become crits
		}
		else if(iItemDefinitionIndex == 237)
		{
			itemOverride = PrepareItemHandle(item, _, 237, "114 ; 1 ; 5 ; 1.8 ; 96 ; 1.8 ; 3 ; 0.25");
		}
		else if(iItemDefinitionIndex == 228 ||
			iItemDefinitionIndex == 1104 ||
			iItemDefinitionIndex == 441 ||
			iItemDefinitionIndex == 414 ||
			iItemDefinitionIndex == 1085 ||
			iItemDefinitionIndex == 730
			)
		{
			itemOverride = PrepareItemHandle(item, _, _, "114 ; 1");
		}
		else
		{
			itemOverride = PrepareItemHandle(item, _, _, "114 ; 1 ; 488 ; 1");
				//114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
				//488: 로켓 특화.
		}

		if(itemOverride != null)
		{
			item = itemOverride;
			return Plugin_Changed;
		}
	}

	if(TF2_GetPlayerClass(client)==TFClass_Soldier && !StrContains(classname, "tf_weapon_shotgun", false))
	{
		Handle itemOverride = PrepareItemHandle(item, _, _, "114 ; 1");
		// 114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
		// 488: 로켓 특화.

		if(itemOverride != null)
		{
			item = itemOverride;
			return Plugin_Changed;
		}
	}

	if(!StrContains(classname, "tf_weapon_syringegun_medic"))  //Syringe guns
	{
		Handle itemOverride = PrepareItemHandle(item, _, _, "17 ; 0.05 ; 144 ; 1", true);
			//17: 5% uber on hit
			//144: Sets weapon mode?????
		if(itemOverride != null)
		{
			item = itemOverride;
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
				itemOverride = PrepareItemHandle(item, _, _, "10 ; 1.2 ; 11 ; 1.25 ; 18 ; 1.0 ; 144 ; 2.0 ; 199 ; 0.75 ; 547 ; 0.75 ; 314 ; 10.0", true);
			}
			case 411: // 응급조치
			{
				itemOverride = PrepareItemHandle(item, _, _, "10 ; 1.35 ; 11 ; 0.5 ; 144 ; 2.0 ; 199 ; 0.75 ; 231 ; 2 ; 547 ; 0.75 ; 314 ; 8.0", true);
			}
		  	default:
		  	{
			  itemOverride = PrepareItemHandle(item, _, _, "10 ; 1.6 ; 11 ; 1.5 ; 13 ; 2.0 ; 144 ; 2.0", true);
		  	}
		}

		if(itemOverride != null)
		{
			item = itemOverride;
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
				itemOverride = PrepareItemHandle(item, _, _, "124 ; 1 ; 351 ; 1", true);
			}

			default:
			{
				itemOverride = PrepareItemHandle(item, _, _, "276 ; 1 ; 345 ; 4", true);
			}
		}


		// 124: 미니 센트리
		// 351: 일회용 센트리 하나.
		if(itemOverride != null)
		{
			item = itemOverride;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
