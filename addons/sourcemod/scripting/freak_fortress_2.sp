#include <sourcemod>
#include <freak_fortress_2>
// #include <POTRY>
// #include <adt_array>
// #include <clientprefs>
#include <morecolors>
// #include <sdkhooks>
// #include <tf2_stocks>
// #include <tf2items>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#tryinclude <rtd>
#tryinclude <tf2attributes>

#include "freak_fortress_2/commands.sp"

#define PLUGIN_VERSION "2.0?"

#if defined _steamtools_included
bool steamtools = false;
#endif

#if defined _tf2attributes_included
bool tf2attributes = false;
#endif

#if defined _goomba_included
bool goomba = false;
#endif

public Plugin myinfo=
{
	name="Freak Fortress 2",
	author="Rainbolt Dash, FlaminSarge, Powerlord, the 50DKP team (Forked by Nopied)",
	description="RUUUUNN!! COWAAAARRDSS!",
	version = PLUGIN_VERSION,
};

public void OnPluginStart()
{

    #if defined _steamtools_included
	steamtools = LibraryExists("SteamTools");
	#endif

	#if defined _goomba_included
	goomba = LibraryExists("goomba");
	#endif

	#if defined _tf2attributes_included
	tf2attributes = LibraryExists("tf2attributes");
	#endif
}

public void OnLibraryAdded(const char[] name)
{
	#if defined _steamtools_included
	if(!strcmp(name, "SteamTools", false))
	{
		steamtools = true;
	}
	#endif

	#if defined _tf2attributes_included
	if(!strcmp(name, "tf2attributes", false))
	{
		tf2attributes = true;
	}
	#endif

	#if defined _goomba_included
	if(!strcmp(name, "goomba", false))
	{
		goomba = true;
	}
	#endif

}

public void OnLibraryRemoved(const char[] name)
{
	#if defined _steamtools_included
	if(!strcmp(name, "SteamTools", false))
	{
		steamtools = false;
	}
	#endif

	#if defined _tf2attributes_included
	if(!strcmp(name, "tf2attributes", false))
	{
		tf2attributes = false;
	}
	#endif

	#if defined _goomba_included
	if(!strcmp(name, "goomba", false))
	{
		goomba = false;
	}
	#endif

}
