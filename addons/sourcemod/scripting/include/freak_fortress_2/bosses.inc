#if defined __freak_fortress_2_bosses_included
	#endinput
#endif

#define __freak_fortress_2_bosses_included

#define MAX_BOSS_SLOT_COUNT 16

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
	Boss_MaxRageCharge,
	Boss_Charge, // TODO: Remember. This is array.
	// NOTE: Everytime when you editing this enum, Keep this at first array.
	Boss_AbilityDuration, // TODO: Remember. This is array.
	Boss_MaxAbilityDuration, // TODO: Remember. This is array.
	Boss_AbilityCooldown, // TODO: Remember. This is array.
	Boss_MaxAbilityCooldown, // TODO: Remember. This is array.
	Boss_KeyValue // NOTE: Everytime when you editing this enum, Keep this at last.
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

		// TODO: Check Boss config file exist.

        KeyValues bossKv = new KeyValues("character");
        bossKv.FileToKeyValues(config);

        return view_as<FF2BossKeyValues>(bossKv);
    }
}

methodmap FF2Boss < ArrayList {
	public FF2Boss(int client)
	{
		int arraySize = (view_as<int>(Boss_KeyValues) + 1);
		ArrayList bossValues = new ArrayList(MAX_BOSS_SLOT_COUNT, arraySize); // 16 is boss ability slot.

		bossValues.Push(client); // first, push client index.
		for(int loop = 1; loop < arraySize; loop++) // 0 is client index.
		{
			if(loop >= view_as<int>(Boss_Charge) && view_as<int>(Boss_KeyValues) > loop)
			{
				bossValues.PushArray(null, MAX_BOSS_SLOT_COUNT);
			}
			else
			{
				bossValues.Push(null);
			}
		}

		return view_as<FF2Boss>(bossValues);
	}

	property int ClientIndex {
		public native get();
	}

	property int CharacterIndex {
			public native get();
	}

	property int HealthPoint {
			public native get();
			public native set(int healthPoint);
	}

	property int MaxHealthPoint {
		public native get();
		public native set(int healthPoint);
	}

	property int Lives {
		public native get();
		public native set(int lives);

	}

	property int MaxLives {
		public native get();
		public native set(int lives);
	}

	property int RageDamage {
		public native get();
		public native set(int damage);
	}

	property float MaxRageCharge {
		public native get();
		public native set(float maxRageCharge);
	}

	property FF2BossKeyValues KeyValue {
		public native get();
		public native set(FF2BossKeyValues keyValue);
	}

	/*
	public float GetCharge(const int index)
	{
		float charges[MAX_BOSS_SLOT_COUNT];
		this.GetArray(Boss_Charge, charges, MAX_BOSS_SLOT_COUNT);
		return charges[index];
	}

	public void SetCharge(const int index, const float charge)
	{
		float charges[MAX_BOSS_SLOT_COUNT];
		this.GetArray(Boss_Charge, charges, MAX_BOSS_SLOT_COUNT);
		charges[index] = charge;
		this.SetArray(Boss_Charge, charges, MAX_BOSS_SLOT_COUNT);
	}

	public float GetAbilityDuration(const int index)
	{
		float duration[MAX_BOSS_SLOT_COUNT];
		this.GetArray(Boss_AbilityDuration, duration, MAX_BOSS_SLOT_COUNT);
		return duration[index] - GetGameTime();
	}

	public void SetAbilityDuration(const int index, const float time)
	{
		float duration[MAX_BOSS_SLOT_COUNT];
		this.GetArray(Boss_AbilityDuration, duration, MAX_BOSS_SLOT_COUNT);
		duration[index] = time + GetGameTime();
		this.SetArray(Boss_AbilityDuration, duration, MAX_BOSS_SLOT_COUNT);
	}

	public float GetMaxAbilityDuration(const int index)
	{
		float duration[MAX_BOSS_SLOT_COUNT];
		this.GetArray(Boss_MaxAbilityDuration, duration, MAX_BOSS_SLOT_COUNT);
		return duration[index];
	}

	public void SetMaxAbilityDuration(const int index, const float time)
	{
		float duration[MAX_BOSS_SLOT_COUNT];
		this.GetArray(Boss_MaxAbilityDuration, duration, MAX_BOSS_SLOT_COUNT);
		duration[index] = time;
		this.SetArray(Boss_MaxAbilityDuration, duration, MAX_BOSS_SLOT_COUNT);
	}

	public float GetAbilityCooldown(const int index)
	{
		float cooldownTime[MAX_BOSS_SLOT_COUNT];
		this.GetArray(Boss_AbilityCooldown, cooldownTime, MAX_BOSS_SLOT_COUNT);
		return cooldownTime[index] - GetGameTime();
	}

	public void SetAbilityCooldown(const int index, const float time)
	{
		float cooldownTime[MAX_BOSS_SLOT_COUNT];
		this.GetArray(Boss_AbilityCooldown, cooldownTime, MAX_BOSS_SLOT_COUNT);
		cooldownTime[index] = time + GetGameTime();
		this.SetArray(Boss_AbilityCooldown, cooldownTime, MAX_BOSS_SLOT_COUNT);
	}

	public float GetMaxAbilityCooldown(const int index)
	{
		float cooldownTime[MAX_BOSS_SLOT_COUNT];
		this.GetArray(Boss_Charge, cooldownTime, MAX_BOSS_SLOT_COUNT);
		return cooldownTime[index];
	}

	public void SetMaxAbilityCooldown(const int index, const float time)
	{
		float cooldownTime[MAX_BOSS_SLOT_COUNT];
		this.GetArray(Boss_Charge, cooldownTime, MAX_BOSS_SLOT_COUNT);
		cooldownTime[index] = time;
		this.SetArray(Boss_Charge, cooldownTime, MAX_BOSS_SLOT_COUNT);
	}
	*/

}
