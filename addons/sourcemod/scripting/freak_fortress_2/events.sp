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
