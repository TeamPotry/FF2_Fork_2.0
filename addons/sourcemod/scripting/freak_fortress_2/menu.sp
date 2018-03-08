public Action Command_SetDifficulty(int client, int args)
{
	CallDifficultyMenu(client);
	return Plugin_Continue;
}

void CallDifficultyMenu(int client)
{
    Menu menu = CreateMenu(Menu_SetDifficulty);
    char item[80]; // TODO: 다국어

    GetDifficultyString(GetClientDifficultyCookie(client), item, sizeof(item));

    menu.SetTitle("보스 난이도 설정 (현재 난이도: %s)", item);
    menu.AddItem("이지", "쉬움: 엥? 이거 완전 \"응애\" 난이도 아니냐!?", ITEMDRAW_DISABLED);
    Format(item, sizeof(item), "%t", "difficulty_normal");
    menu.AddItem("노말", item);
    Format(item, sizeof(item), "%t", "difficulty_hard");
    menu.AddItem("어려움", item);
    Format(item, sizeof(item), "%t", "difficulty_veryhard");
    menu.AddItem("매우 어려움", item);
    Format(item, sizeof(item), "%t", "difficulty_tryhard");
    menu.AddItem("너무 어려움", item);
    Format(item, sizeof(item), "%t", "difficulty_nothuman");
    menu.AddItem("사람이 아니다.", item);
    SetMenuExitButton(menu, true);
    menu.Display(client, 60);
}

public Menu_SetDifficulty(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
        case MenuAction_End:
        {
            delete menu;
        }
        case MenuAction_Select:
        {
            char itemString[50];

            switch(item)
            {
                case 0:
                {
                    CPrintToChat(client, "그거 참 흥미롭네요.. {red}대체 어떻게 이걸 고른거죠{default}?");
                }
                case 1:
                {
                    SetClientDifficultyCookie(client, 1);
                }
                    case 2:
                {
                    SetClientDifficultyCookie(client, 2);
                }
                case 3:
                {
                    SetClientDifficultyCookie(client, 3);
                }
                case 4:
                {
                    SetClientDifficultyCookie(client, 4);
                }
                case 5:
                {
                    SetClientDifficultyCookie(client, 5);
                }
            }
            GetDifficultyString(GetClientDifficultyCookie(client), itemString, sizeof(itemString));
            CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_set_difficulty", itemString);
        }
    }
}

public Action VoiceTogglePanelCmd(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	VoiceTogglePanel(client);
	return Plugin_Handled;
}

public Action VoiceTogglePanel(int client)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	Handle panel = CreatePanel();
	SetPanelTitle(panel, "보스들의 대사/효과음을..");
	DrawPanelItem(panel, "켜기");
	DrawPanelItem(panel, "끄기");
	SendPanelToClient(panel, client, VoiceTogglePanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Continue;
}

public VoiceTogglePanelH(Handle:menu, MenuAction:action, client, selection)
{
	if(IsValidClient(client))
	{
		if(action == MenuAction_Select)
		{
			if(selection==2)
			{
				SetClientSoundOptions(client, SOUNDEXCEPT_VOICE, false);
			}
			else
			{
				SetClientSoundOptions(client, SOUNDEXCEPT_VOICE, true);
			}

			CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_voice", selection==2 ? "off" : "on");
			if(selection==2)
			{
				CPrintToChat(client, "%t", "ff2_voice2");
			}
		}
	}
}
