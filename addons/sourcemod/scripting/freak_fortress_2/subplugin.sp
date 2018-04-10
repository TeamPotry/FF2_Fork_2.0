bool areSubPluginsEnabled;

#if defined _steamtools_included
bool steamtools=false;
#endif

#if defined _tf2attributes_included
bool tf2attributes=false;
#endif

#if defined _goomba_included
bool goomba=false;
#endif

void EnableSubPlugins(bool force = false)
{
	if(areSubPluginsEnabled && !force)
	{
		return;
	}

	areSubPluginsEnabled = true;
	char path[PLATFORM_MAX_PATH], filename[PLATFORM_MAX_PATH], filename_old[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "plugins/freaks");
	FileType filetype;
	DirectoryListing directory = OpenDirectory(path);
	while(directory.GetNext(filename, PLATFORM_MAX_PATH, filetype))
	{
		if(filetype == FileType_File && StrContains(filename, ".smx", false) != -1)
		{
			Format(filename_old, PLATFORM_MAX_PATH, "%s/%s", path, filename);
			ReplaceString(filename, PLATFORM_MAX_PATH, ".smx", ".ff2", false);
			Format(filename, PLATFORM_MAX_PATH, "%s/%s", path, filename);
			DeleteFile(filename);
			RenameFile(filename, filename_old);
		}
	}

	directory = OpenDirectory(path);
	while(directory.GetNext(filename, PLATFORM_MAX_PATH, filetype))
	{
		if(filetype == FileType_File && StrContains(filename, ".ff2", false) != -1)
		{
			ServerCommand("sm plugins load freaks/%s", filename);
		}
	}
}


void DisableSubPlugins(bool force = false)
{
	if(!areSubPluginsEnabled && !force)
	{
		return;
	}

    char path[PLATFORM_MAX_PATH], filename[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "plugins/freaks");
    FileType filetype;
    DirectoryListing directory = OpenDirectory(path);
    while(directory.GetNext(filename, PLATFORM_MAX_PATH, filetype))
    {
        if(filetype == FileType_File && StrContains(filename, ".ff2", false) != -1)
        {
        	InsertServerCommand("sm plugins unload freaks/%s", filename);  //ServerCommand will not work when switching maps
        }
    }
    ServerExecute();
    areSubPluginsEnabled = false;
}
