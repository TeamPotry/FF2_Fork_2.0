Handle jumpHUD;
Handle rageHUD;
Handle livesHUD;
Handle timeleftHUD;
Handle abilitiesHUD;
Handle infoHUD;

public Action InitialBossInfo(Handle timer, any bossInfoTimer)
{
    FF2BossInfoTimer timerArray = view_as<FF2BossInfoTimer>(bossInfoTimer);

    CreateTimer(0.2, BossInfoTimer_Loop, timerArray, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Stop;
}

// TODO: Finish this.

public Action BossInfoTimer_Loop(Handle timer, any bossInfoTimer)
{
    // FF2BossInfoTimer timerArray = view_as<FF2BossInfoTimer>(bossInfoTimer);

    return Plugin_Continue;
}
