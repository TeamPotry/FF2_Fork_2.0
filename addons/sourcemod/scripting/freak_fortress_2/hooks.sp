public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if(Enabled && IsBoss(client) && CheckRoundState() == 1 && !TF2_IsPlayerCritBuffed(client))
	{
		result = BossCrits;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
