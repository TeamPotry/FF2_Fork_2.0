public Action InitialBossInfo(Handle timer, any timer)
{
    FF2BossInfoTimer timerArray = view_as<FF2BossInfoTimer>(timer);

    CreateTimer(0.2, BossInfoTimer_Loop, timerArray, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Stop;
}

// TODO: Finish this.

public Action BossInfoTimer_Loop(Handle timer, any timer)
{
    // FF2BossInfoTimer timerArray = view_as<FF2BossInfoTimer>(timer);

    return Plugin_Continue;
}

public int Native_OnKillInfoTImer(Handle plugin, int numParams)
{
    FF2BossInfoTimer timerArray = view_as<FF2BossInfoTimer>(GetNativeCell(1));
    Handle timer = timerArray.Get(view_as<int>(Info_Timer)
    KillTimer(timer);
    delete timer;
}
