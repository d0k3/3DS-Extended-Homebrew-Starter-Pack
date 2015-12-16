--ihaveamac--
-- updater issues go to https://github.com/ihaveamac/mashers-gl-updater/issues
-- licensed under the MIT license: https://github.com/ihaveamac/mashers-gl-updater/blob/master/LICENSE.md
version = "2.2"

-- temporary workaround due to a mistake in the current lpp-3ds build
FREAD = 0
FWRITE = 1
FCREATE = 2

-- site urls
enabled_url = "http://ianburgwin.net/mglupdate-2/enabled"
versionh_url = "http://ianburgwin.net/mglupdate-2/version.h"
launcherzip_url = "http://ianburgwin.net/mglupdate-2/launcher.zip"
changelog_url = "http://ianburgwin.net/mglupdate-2/Updating-Changelog.md"
changelog_beta_url = "http://ianburgwin.net/mglupdate-2/Updating-Changelog-Beta.md"

changelog = false;

-- get changelog
--noinspection UnusedDef
function getChangelog(type, version)
	-- type is currently unused
	if not changelog then
		changelog = {}
		local tmp_changelog = Network.requestString(changelog_beta_url)
		local current_ver
		for v in string.gmatch(tmp_changelog, '([^\n]+)') do
			if v:sub(1, 4) == "<!--" or v:sub(1, 2) == "- " or v:sub(1, 3) == "-->" or v == "" then
				-- nothing.
			elseif v:sub(1, 8) == "## Beta " then
				current_ver = v:sub(9)
				changelog["b"..current_ver] = ""
			else
				changelog["b"..current_ver] = changelog["b"..current_ver]..v.."\n"
			end
		end
	end

	if not changelog[version] then
		error("bad changelog version: \""..version.."\"")
	end
	return changelog[version]
end

-- default updater config contents
skip_info = false
force_path = ""

function formatConfig()
    return "skip_info = "..tostring(skip_info).."\nforce_path = \""..force_path.."\" -- leave this as \"\" to automatically detect launcher location"
end
-- check for local version and updater config
-- vp[1] = launcher location
-- vp[2] = launcher version
vp = {"/boot.3dsx", "%NOVERSION%" }
if System.doesFileExist("/gridlauncher/glinfo.txt") then
    local gli_file = io.open("/gridlauncher/glinfo.txt", FREAD) -- format: "sdmc:/boot1.3dsx|76"
    local gli = {}
    for v in string.gmatch(io.read(gli_file, 0, io.size(gli_file)), '([^|]+)') do
        table.insert(gli, v)
    end
    vp[1] = gli[1]:sub(6)
    vp[2] = gli[2]:sub(1, gli[2]:len() - 1)
end

local cfgfile
if System.doesFileExist("/gridlauncher/updater.cfg") then
    dofile("/gridlauncher/updater.cfg")
    --noinspection UnusedDef
    cfgfile = io.open("/gridlauncher/updater.cfg", FWRITE)
else
    cfgfile = io.open("/gridlauncher/updater.cfg", FCREATE)
end
local cfgfile_d = formatConfig()
io.write(cfgfile, 0, formatConfig(), cfgfile_d:len())
io.close(cfgfile)
if force_path ~= "" then
    vp[1] = force_path
end

-- exit - hold L to keep the temporary files
function exit(noErr)
    if not Controls.check(Controls.read(), KEY_L) then
        deleteDirContents("/mgl_temp")
        System.deleteDirectory("/mgl_temp")
    end
    if not noErr then
        -- prevents a second error from showing when there's already an error
        error("%EXIT%")
    end
end

-- delete directory contents (custom function)
function deleteDirContents(dir)
    local cont = System.listDirectory(dir)
    for _, v in pairs(cont) do
        if v.directory then
            deleteDirContents(dir.."/"..v.name)
            System.deleteDirectory(dir.."/"..v.name)
        else
            System.deleteFile(dir.."/"..v.name)
        end
    end
end

-- since the drawing code has become big
dofile(System.currentDirectory().."/drawing.lua")

Screen.waitVblankStart()

-- error handling so cleanup can still happen
status, err = pcall(function()
    -- show preparing
    updateState("prepare")
    System.createDirectory("/mgl_temp")

    -- if allow_force_error is set outside of this script then an error can be forced
    if allow_force_error and Controls.check(Controls.read(), KEY_L) then
        error("forced error")
    end

    -- check network connection
    --noinspection UnusedDef
    local enabled = "no"
    local n_status, n_err = pcall(function()
        enabled = Network.requestString(enabled_url)
        if enabled ~= "yes" then
            error("manually disabled")
        end
    end)
    if not n_status then
        if n_err:sub(-17) == "manually disabled" then
            updateState("disabled", n_err)
            -- trying to forcibly enable the updater is not a good idea
            -- because you will most likely download a broken grid launcher
        else
            updateState("noconnection", n_err)
        end
    end

    -- get state of the server (if still downloading to cache the latest file)
    local state = ""
    local function getServerState()
        state = Network.requestString(versionh_url)
    end
    getServerState()

    -- if the server is still caching
    if fullstate == "notready" then
        -- expects launcher.zip to be cached on the server quickly. normally won't take more than 1-2 seconds
        updateState("cacheupdating")
        local ti = Timer.new()
        Timer.resume(ti)
        while Timer.getTime(ti) <= 3000 do end
        Timer.destroy(ti)
        getServerState()
    end

    local latest_ver = state:sub(25, -2)
    -- display version information
    if vp[2] == "%NOVERSION%" then
        updateState("showversion-noinstall", latest_ver)
    else
        if not skip_info or vp[2] == latest_ver then
            updateState("showversion", latest_ver)
        end
    end

    -- download launcher.zip
    updateState("downloading", latest_ver)
    System.deleteFile("/mgl_temp/launcher.zip")
    Network.downloadFile(launcherzip_url, "/mgl_temp/launcher.zip")

    -- extract launcher.zip
    updateState("extracting", latest_ver)
    System.extractZIP("/mgl_temp/launcher.zip", "/mgl_temp")

    -- install the files
    updateState("installing", latest_ver)
    System.createDirectory("/gridlauncher/update")
    deleteDirContents("/gridlauncher/update")
    local new_update = System.listDirectory("/mgl_temp/gridlauncher/update")
    for _, v in pairs(new_update) do
        if v.directory then
            System.renameDirectory("/mgl_temp/gridlauncher/update/"..v.name, "/gridlauncher/update/"..v.name)
        else
            System.renameFile("/mgl_temp/gridlauncher/update/"..v.name, "/gridlauncher/update/"..v.name)
        end
    end
    System.deleteFile(vp[1])
    System.renameFile("/mgl_temp/boot.3dsx", vp[1])

    -- done!
    if skip_info then
        exit()
    else
        updateState("done", latest_ver)
    end
end)
if not status then
    if err:sub(-6) == "%EXIT%" then
        System.exit()
    else
        updateState("error", err)
    end
end
