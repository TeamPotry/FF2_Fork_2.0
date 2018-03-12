enum ClientValues
{
	Client_Index = 0,
    Client_Damage,
    Client_Assist,
    Client_GlowTime,
    Client_Flags,
    Client_EnabledSpecialAttack, // NOTE: This is array.
    Client_SpecialAttackCount, // NOTE: This is array.
    Client_MusicData // NOTE: This is array.
};

/*
    Create when client is connented.
    Deleted when client is disconnected.
*/
