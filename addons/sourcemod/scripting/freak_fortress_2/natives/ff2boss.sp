public int Native_FF2Boss_ClientIndex_Get(Handle plugin, int numParams)
{
    return view_as<FF2Boss>(GetNativeCell(1)).Get(view_as<int>(Boss_ClientIndex));
}

public int Native_FF2Boss_CharacterIndex_Get(Handle plugin, int numParams)
{
    return view_as<FF2Boss>(GetNativeCell(1)).Get(view_as<int>(Boss_CharacterIndex));
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

public int Native_FF2Boss_KeyValue_Get(Handle plugin, int numParams)
{
    return view_as<FF2Boss>(GetNativeCell(1)).Get(view_as<int>(Boss_KeyValue));
}

public int Native_FF2Boss_KeyValue_Set(Handle plugin, int numParams)
{
    view_as<FF2Boss>(GetNativeCell(1)).Set(view_as<int>(Boss_KeyValue), GetNativeCell(2));
}
