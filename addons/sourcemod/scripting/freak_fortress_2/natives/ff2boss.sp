public int Native_FF2Boss_ClientIndex_Get(Handle plugin, int numParams)
{
    return view_as<FF2Boss>(GetNativeCell(1)).Get(view_as<int>(Boss_ClientIndex));
}

public int Native_FF2Boss_CharacterIndex_Get(Handle plugin, int numParams)
{
    return view_as<FF2Boss>(GetNativeCell(1)).Get(view_as<int>(Boss_CharacterIndex));
}

public int Native_FF2Boss_CharacterIndex_Set(Handle plugin, int numParams)
{
    view_as<FF2Boss>(GetNativeCell(1)).Set(view_as<int>(Boss_CharacterIndex), GetNativeCell(2));
}

public int Native_FF2Boss_HealthPoint_Get(Handle plugin, int numParams)
{
    return view_as<FF2Boss>(GetNativeCell(1)).Get(view_as<int>(Boss_HP));
}

public int Native_FF2Boss_HealthPoint_Set(Handle plugin, int numParams)
{
    view_as<FF2Boss>(GetNativeCell(1)).Set(view_as<int>(Boss_HP), GetNativeCell(2));
}

public int Native_FF2Boss_MaxHealthPoint_Get(Handle plugin, int numParams)
{
    return view_as<FF2Boss>(GetNativeCell(1)).Get(view_as<int>(Boss_MaxHP));
}

public int Native_FF2Boss_MaxHealthPoint_Set(Handle plugin, int numParams)
{
    view_as<FF2Boss>(GetNativeCell(1)).Set(view_as<int>(Boss_MaxHP), GetNativeCell(2));
}

public int Native_FF2Boss_Lives_Get(Handle plugin, int numParams)
{
    return view_as<FF2Boss>(GetNativeCell(1)).Get(view_as<int>(Boss_Lives));
}

public int Native_FF2Boss_Lives_Set(Handle plugin, int numParams)
{
    view_as<FF2Boss>(GetNativeCell(1)).Set(view_as<int>(Boss_Lives), GetNativeCell(2));
}

public int Native_FF2Boss_MaxLives_Get(Handle plugin, int numParams)
{
    return view_as<FF2Boss>(GetNativeCell(1)).Get(view_as<int>(Boss_MaxLives));
}

public int Native_FF2Boss_MaxLives_Set(Handle plugin, int numParams)
{
    view_as<FF2Boss>(GetNativeCell(1)).Set(view_as<int>(Boss_MaxLives), GetNativeCell(2));
}

public int Native_FF2Boss_RageDamage_Get(Handle plugin, int numParams)
{
    return view_as<FF2Boss>(GetNativeCell(1)).Get(view_as<int>(Boss_RageDamage));
}

public int Native_FF2Boss_RageDamage_Set(Handle plugin, int numParams)
{
    view_as<FF2Boss>(GetNativeCell(1)).Set(view_as<int>(Boss_RageDamage), GetNativeCell(2));
}

public int Native_FF2Boss_MaxRageCharge_Get(Handle plugin, int numParams)
{
    return view_as<FF2Boss>(GetNativeCell(1)).Get(view_as<int>(Boss_MaxRageCharge));
}

public int Native_FF2Boss_MaxRageCharge_Set(Handle plugin, int numParams)
{
    view_as<FF2Boss>(GetNativeCell(1)).Set(view_as<int>(Boss_MaxRageCharge), GetNativeCell(2));
}

public int Native_FF2Boss_Difficulty_Get(Handle plugin, int numParams)
{
    return view_as<FF2Boss>(GetNativeCell(1)).Get(view_as<int>(Boss_Difficulty));
}

public int Native_FF2Boss_Difficulty_Set(Handle plugin, int numParams)
{
    view_as<FF2Boss>(GetNativeCell(1)).Set(view_as<int>(Boss_Difficulty), GetNativeCell(2));
}

public int Native_FF2Boss_KeyValue_Get(Handle plugin, int numParams)
{
    return view_as<FF2Boss>(GetNativeCell(1)).Get(view_as<int>(Boss_KeyValue));
}

public int Native_FF2Boss_KeyValue_Set(Handle plugin, int numParams)
{
    view_as<FF2Boss>(GetNativeCell(1)).Set(view_as<int>(Boss_KeyValue), GetNativeCell(2));
}

public int Native_FF2Boss_GetCharge(Handle plugin, int numParams)
{
    FF2Boss boss = view_as<FF2Boss>(GetNativeCell(1));
    int index = GetNativeCell(2);
    float charges[MAX_BOSS_SLOT_COUNT];

    boss.GetArray(view_as<int>(Boss_Charge), charges, MAX_BOSS_SLOT_COUNT);
    return view_as<any>(charges[index]);
}

public int Native_FF2Boss_SetCharge(Handle plugin, int numParams)
{
    FF2Boss boss = view_as<FF2Boss>(GetNativeCell(1));
    int index = GetNativeCell(2);
    float charge = GetNativeCell(3);
    float charges[MAX_BOSS_SLOT_COUNT];

    boss.GetArray(view_as<int>(Boss_Charge), charges, MAX_BOSS_SLOT_COUNT);
    charges[index] = charge;

    if(charges[index] < 0.0)
        charges[index] = 0.0;
    else if(charge[index] > boss.MaxRageCharge)
        charges[index] = boss.MaxRageCharge;

    boss.SetArray(view_as<int>(Boss_Charge), charges, MAX_BOSS_SLOT_COUNT);
}

public int Native_FF2Boss_GetAbilityDuration(Handle plugin, int numParams)
{
    FF2Boss boss = view_as<FF2Boss>(GetNativeCell(1));
    int index = GetNativeCell(2);
    float duration[MAX_BOSS_SLOT_COUNT];

    boss.GetArray(view_as<int>(Boss_AbilityDuration), duration, MAX_BOSS_SLOT_COUNT);
    return view_as<any>(duration[index] - GetGameTime());
}

public int Native_FF2Boss_SetAbilityDuration(Handle plugin, int numParams)
{
    FF2Boss boss = view_as<FF2Boss>(GetNativeCell(1));
    int index = GetNativeCell(2);
    float time = GetNativeCell(3);
    float duration[MAX_BOSS_SLOT_COUNT];

    boss.GetArray(view_as<int>(Boss_AbilityDuration), duration, MAX_BOSS_SLOT_COUNT);
    duration[index] = time + GetGameTime();

    if(duration[index] < GetGameTime())
        duration[index] = -1.0;
    boss.SetArray(view_as<int>(Boss_AbilityDuration), duration, MAX_BOSS_SLOT_COUNT);
}

public int Native_FF2Boss_GetMaxAbilityDuration(Handle plugin, int numParams)
{
    FF2Boss boss = view_as<FF2Boss>(GetNativeCell(1));
    int index = GetNativeCell(2);
    float duration[MAX_BOSS_SLOT_COUNT];

    boss.GetArray(view_as<int>(Boss_MaxAbilityDuration), duration, MAX_BOSS_SLOT_COUNT);
    return view_as<any>(duration[index]);
}

public int Native_FF2Boss_SetMaxAbilityDuration(Handle plugin, int numParams)
{
    FF2Boss boss = view_as<FF2Boss>(GetNativeCell(1));
    int index = GetNativeCell(2);
    float time = GetNativeCell(3);
    float duration[MAX_BOSS_SLOT_COUNT];

    boss.GetArray(view_as<int>(Boss_MaxAbilityDuration), duration, MAX_BOSS_SLOT_COUNT);
    duration[index] = time;
    boss.SetArray(view_as<int>(Boss_MaxAbilityDuration), duration, MAX_BOSS_SLOT_COUNT);
}

public int Native_FF2Boss_GetAbilityCooldown(Handle plugin, int numParams)
{
    FF2Boss boss = view_as<FF2Boss>(GetNativeCell(1));
    int index = GetNativeCell(2);
    float cooldownTime[MAX_BOSS_SLOT_COUNT];

    boss.GetArray(view_as<int>(Boss_AbilityCooldown), cooldownTime, MAX_BOSS_SLOT_COUNT);
    return view_as<any>(cooldownTime[index] - GetGameTime());
}

public int Native_FF2Boss_SetAbilityCooldown(Handle plugin, int numParams)
{
    FF2Boss boss = view_as<FF2Boss>(GetNativeCell(1));
    int index = GetNativeCell(2);
    float time = GetNativeCell(3);
    float duration = boss.GetAbilityDuration(index);
    float cooldownTime[MAX_BOSS_SLOT_COUNT];

    boss.GetArray(view_as<int>(Boss_AbilityCooldown), cooldownTime, MAX_BOSS_SLOT_COUNT);
    if(duration > 0.0) {
        cooldownTime[index] = time + duration;
    }
    else {
        cooldownTime[index] = GetGameTime();
    }


    if(cooldownTime[index] < GetGameTime())
    {
        cooldownTime[index] = -1.0;
    }

    boss.SetArray(view_as<int>(Boss_AbilityCooldown), cooldownTime, MAX_BOSS_SLOT_COUNT);
}

public int Native_FF2Boss_GetMaxAbilityCooldown(Handle plugin, int numParams)
{
    FF2Boss boss = view_as<FF2Boss>(GetNativeCell(1));
    int index = GetNativeCell(2);
    float cooldownTime[MAX_BOSS_SLOT_COUNT];

    boss.GetArray(view_as<int>(Boss_MaxAbilityCooldown), cooldownTime, MAX_BOSS_SLOT_COUNT);
    return view_as<any>(cooldownTime[index]);
}

public int Native_FF2Boss_SetMaxAbilityCooldown(Handle plugin, int numParams)
{
    FF2Boss boss = view_as<FF2Boss>(GetNativeCell(1));
    int index = GetNativeCell(2);
    float time = GetNativeCell(3);
    float cooldownTime[MAX_BOSS_SLOT_COUNT];

    boss.GetArray(view_as<int>(Boss_MaxAbilityCooldown), cooldownTime, MAX_BOSS_SLOT_COUNT);
    cooldownTime[index] = time;
    boss.SetArray(view_as<int>(Boss_MaxAbilityCooldown), cooldownTime, MAX_BOSS_SLOT_COUNT);
}
