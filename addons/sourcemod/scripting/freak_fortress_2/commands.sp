/*
public Action Listener_Say(int client, const char[] command, int argc)
{
	if(!IsValidClient(client))	return Plugin_Continue;

	char chat[150];
	bool handleChat = false;

	GetCmdArgString(chat, sizeof(chat));

	// TODO: Use ConVar.

	if(strlen(chat) >= 2 ) {
		if(chat[1] == '!') handleChat = false;
		else if(chat[1] == '/') handleChat = true;
		else return Plugin_Continue;
	}
	else{
		return Plugin_Continue;
	}
	chat[strlen(chat)-1]='\0';

	char specialtext[2][100];
	ExplodeString(chat[2], " ", specialtext, sizeof(specialtext), sizeof(specialtext[]));


	if(StrEqual("프리크", chat[2], true) ||
	StrEqual("ㄹㄹ2", chat[2], true))
	{
		FF2Panel(client, 0);
	}

	else if(StrEqual("음악", chat[2], true) ||
	StrEqual("보스음악", chat[2], true) ||
	StrEqual("ㄹㄹ2ㅡㅕ냧", chat[2], true))
	{
		MusicTogglePanel(client);
	}

	else if(StrEqual("외부음악", chat[2], true))
	{
		ViewClientMusicMenu(client);
	}

	else if(StrEqual("난이도", chat[2], true) ||
	StrEqual("보스난이도", chat[2], true) ||
	StrEqual("ㅗ미드ㅐㅇㄷ", chat[2], true))
	{
		CallDifficultyMenu(client);
	}

	else if(StrEqual("패치", chat[2], true) ||
	StrEqual("업데이트", chat[2], true) ||
	StrEqual("ㄹㄹ2ㅜㄷㅈ", chat[2], true))
	{
		NewPanel(client, maxVersion);
	}

	else if(StrEqual("대기열", chat[2], true) ||
	StrEqual("보스대기열", chat[2], true) ||
	StrEqual("ㄹㄹ2ㅜㄷㅌㅅ", chat[2], true))
	{
		QueuePanelCmd(client, 0);
	}

	else if(StrEqual("정보", chat[2], true) ||
	StrEqual("보스정보", chat[2], true) ||
	StrEqual("ㄹㄹ2ㅠㅐㄴ냐ㅜ래", chat[2], true))
	{
		HelpPanelBoss(client);
	}

	else if(StrEqual("병과정보", chat[2], true) ||
	StrEqual("내정보", chat[2], true) ||
	StrEqual("ㄹㄹ2침ㄴ냐ㅜ래", chat[2], true))
	{
		HelpPanelClass(client);
	}

	else if(StrEqual("you", specialtext[0], true) ||
	StrEqual("너", specialtext[0], true))
	{
		SetYouSpecialString(client, chat[strlen(specialtext[0])+3]);
	}
	return handleChat ? Plugin_Handled : Plugin_Continue;

}
*/

public Action Command_DevMode(int client, int args)
{
	if(DEVmode)
		DEVmode = false;
	else
		DEVmode = true;

	CPrintToChatAll("{olive}[FF2]{default} DEVmode: %s", DEVmode ? "ON" : "OFF");

	return Plugin_Continue;
}

public Action OnSuicide(int client, const char[] command, int args)
{
	bool canBossSuicide = GetConVarBool(cvarBossSuicide);
	if(Enabled && IsBoss(client) && (canBossSuicide ? !CheckRoundState() : true) && CheckRoundState()!=2)
	{
		CPrintToChat(client, "{olive}[FF2]{default} %t", canBossSuicide ? "Boss Suicide Pre-round" : "Boss Suicide Denied");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnChangeClass(int client, const char[] command, int args)
{
	if(Enabled && IsBoss(client) && IsPlayerAlive(client))
	{
		//Don't allow the boss to switch classes but instead set their *desired* class (for the next round)
		char class[16];
		GetCmdArg(1, class, sizeof(class));
		if(TF2_GetClass(class) != TFClass_Unknown)  //Ignore cases where the client chooses an invalid class through the console
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TF2_GetClass(class));
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnJoinTeam(int client, const char[] command, int args)
{
	if(!Enabled || RoundCount < arenaRounds || CheckRoundState() == -1) // 1.10.15
	{
		return Plugin_Continue;
	}

	// autoteam doesn't come with arguments
 	if(StrEqual(command, "autoteam", false))
 	{
 		int team = view_as<int>(TFTeam_Unassigned), oldTeam = GetClientTeam(client);
 		if(IsBoss(client))
 		{
 			team = BossTeam;
 		}
 		else
 		{
 			team = OtherTeam;
 		}

 		if(team != oldTeam)
 		{
 			ChangeClientTeam(client, team);
 		}
 		return Plugin_Handled;
 	}

	if(!args)
 	{
 		return Plugin_Continue;
 	}

	int team = view_as<int>(TFTeam_Unassigned), oldTeam = GetClientTeam(client);
	char teamString[10];
	GetCmdArg(1, teamString, sizeof(teamString));

	if(StrEqual(teamString, "red", false))
	{
		team = view_as<int>(TFTeam_Red);
	}
	else if(StrEqual(teamString, "blue", false))
	{
		team = view_as<int>(TFTeam_Blue);
	}
	else if(StrEqual(teamString, "auto", false))
	{
		team = view_as<int>(OtherTeam);
	}
	else if(StrEqual(teamString, "spectate", false) && !IsBoss(client) && GetConVarBool(FindConVar("mp_allowspectators")))
	{
		team = view_as<int>(TFTeam_Spectator);
	}

	if(team == BossTeam && !IsBoss(client))
	{
		team = OtherTeam;
	}
	else if(team == OtherTeam && IsBoss(client))
	{
		team = BossTeam;
	}

	if(team > view_as<int>(TFTeam_Unassigned) && team != oldTeam)
	{
		ChangeClientTeam(client, team);
	}

	if(CheckRoundState() != 1 && !IsBoss(client) || !IsPlayerAlive(client))  //No point in showing the VGUI if they can't change teams
	{
		switch(team)
		{
			case TFTeam_Red:
			{
				ShowVGUIPanel(client, "class_red");
			}
			case TFTeam_Blue:
			{
				ShowVGUIPanel(client, "class_blue");
			}
		}
	}
	return Plugin_Handled;
}
