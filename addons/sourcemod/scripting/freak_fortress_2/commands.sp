public Action Listener_Say(int client, const char[] command, int argc)
{
	if(!IsValidClient(client))	return Plugin_Continue;

	char chat[150];
	bool handleChat = false;

	GetCmdArgString(chat, sizeof(chat));

	// TODO: Use ConVar.

	if(strlen(chat) >= 2 ){
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
