#if defined __freak_fortress_2_bosses_included
	#endinput
#endif

#define __freak_fortress_2_bosses_included

enum BossValues
{
	Boss_ClientIndex = 0,
	Boss_BossIndex,
	Boss_CharacterIndex,
	Boss_HP,
	Boss_MaxHP,
	Boss_Lives,
	Boss_MaxLives,
	Boss_RageDamage,
	Boss_Charge, // TODO: Remember. This is array.
	Boss_MaxRageCharge,
	Boss_AbilityDuration, // TODO: Remember. This is array.
	Boss_MaxAbilityDuration, // TODO: Remember. This is array.
	Boss_AbilityCooldown, // TODO: Remember. This is array.
	Boss_MaxAbilityCooldown, // TODO: Remember. This is array.
	Boss_KeyValues // NOTE: Everytime when you editing this, Keep this at last.
};

methodmap FF2BossKeyValues < KeyValues {
    public FF2BossKeyValues(int characterIndex)
    {
        // TODO: FF2_OnLoadCharacterSet 지원 여부
        char config[PLATFORM_MAX_PATH], character[64], key[4];
        BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/freak_fortress_2/characters.cfg");
        IntToString(character, key, sizeof(key));

        if(!FileExists(config))
        {
            LogError("[FF2] Freak Fortress 2 disabled-can not find characters.cfg!");
            // TODO: Disable FF2
            return null;
        }

        KeyValues Kv = new KeyValues("");
        Kv.FileToKeyValues(config);
        Kv.Rewind();
        Kv.GetString(key, character, 64);

        delete Kv;

        BuildPath(Path_SM, config, sizeof(config), "configs/freak_fortress_2/%s.cfg", character);

        KeyValues bossKv = new KeyValues("character");
        bossKv.FileToKeyValues(config);

        return view_as<FF2BossKeyValues>(bossKv);
    }
}

methodmap FF2Boss < ArrayList {
	// not sure about this.
}
