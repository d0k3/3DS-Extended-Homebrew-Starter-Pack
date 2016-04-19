-- colors
c_white = Color.new(255, 255, 255)
c_grey = Color.new(127, 127, 127)
c_light_red = Color.new(255, 127, 127)
c_light_blue = Color.new(127, 127, 255)

-- print to screen
function print(x, y, text, clr)
    if not clr then
        clr = c_white
    end
    Screen.debugPrint(x, y, text, clr, TOP_SCREEN)
end
function printb(x, y, text, clr)
    if not clr then
        clr = c_white
    end
    Screen.debugPrint(x, y, text, clr, BOTTOM_SCREEN)
end
function displayError(err)
    local co = Console.new(BOTTOM_SCREEN)
    Console.append(co, "\n\n\n\n\n\n\nError details:\n\n"..err)
    Console.show(co)
end

-- credits
function drawMainInfo(clr)
    Screen.refresh()
    Screen.clear(TOP_SCREEN)
    Screen.clear(BOTTOM_SCREEN)
    if vp[2] ~= "%NOVERSION%" then
        print(5, 5, "Grid Launcher Update - Installed: "..vp[2], c_light_blue, true)
        print(5, 5, "Grid Launcher Update - Installed: ", c_grey, true)
    end
    print(5, 5, "Grid Launcher Update")
    printb(5, 5, "updater "..version, c_grey)
    printb(5, 25, "grid launcher by mashers", c_grey)
    printb(10, 40, "gbatemp.net/threads/397527/", c_grey)
    printb(5, 60, "updater by ihaveamac", c_grey)
    printb(10, 75, "ianburgwin.net/mglupdate", c_grey)
    Screen.fillEmptyRect(6, 394, 17, 18, clr, TOP_SCREEN)
end

-- update information on screen
lastState = ""
function updateState(stype, info)

    -- getting latest information
    if stype == "prepare" or stype == "cacheupdating" then
        drawMainInfo(Color.new(0, 0, 255))
        print(5, 25, "Please wait a moment.")
        Screen.flip()

    -- failed to get info, usually bad internet connection
    elseif stype == "noconnection" then
        drawMainInfo(Color.new(255, 0, 0))
        print(5, 25, "Couldn't get the latest version!", c_light_red)
        print(5, 40, "Check your connection to the Internet.")
        print(5, 60, "If this problem persists, you might need to")
        print(5, 75, "manually replace this updater.")
        print(5, 115, "Y: exit")
        displayError(info)
        Screen.flip()
        while true do
            if Controls.check(Controls.read(), KEY_Y) then
                exit()
            end
        end

    -- updater is disabled usually due to bad version pushed
    elseif stype == "disabled" then
        drawMainInfo(Color.new(255, 0, 0))
        print(5, 25, "The updater has been temporarily disabled.", c_light_red)
        print(5, 45, "This might be because a bad version was")
        print(5, 60, "accidentally pushed out, and would cause")
        print(5, 75, "problems launching homebrew.")
        print(5, 95, "Please try again later.")
        print(5, 115, "More information might be on the GBAtemp")
        print(5, 130, "thread on the bottom screen.")
        print(5, 170, "Y: exit")
        printb(10, 40, "gbatemp.net/threads/397527/", c_light_red)
        displayError(info)
        Screen.flip()
        while true do
            if Controls.check(Controls.read(), KEY_Y) then
                exit()
            end
        end

    -- updater is disabled usually due to bad version pushed
    elseif stype == "error" then
        drawMainInfo(Color.new(255, 0, 0))
        print(5, 25, "An error has occured.", c_light_red)
        print(5, 40, "Please check the bottom screen.")
        print(5, 60, "If the problem is related to ZIP extraction,")
        print(5, 75, "try running the updater again.")
        print(5, 95, "If it happens again, reboot your system.")
        print(5, 115, "If neither work, please go to the mglupdate")
        print(5, 130, "page and post the error on the bottom")
        print(5, 145, "screen.")
        print(5, 185, "Y: exit")
        print(5, 200, "L+X: reboot")
        printb(10, 75, "ianburgwin.net/mglupdate", c_light_red)
        displayError(info)
        Screen.flip()
        while true do
            if Controls.check(Controls.read(), KEY_Y) then
                exit(true)
                System.exit()
            elseif Controls.check(Controls.read(), KEY_L) and Controls.check(Controls.read(), KEY_X) then
                exit(true)
                Screen.refresh()
                -- strange workaround for what I think is double buffering
                Screen.fillRect(0, 399, 0, 239, Color.new(0, 0, 0), TOP_SCREEN)
                Screen.fillRect(0, 319, 0, 239, Color.new(0, 0, 0), BOTTOM_SCREEN)
                print(5, 200, "L+X: rebooting, see you soon!", Color.new(0, 127, 0))
                Screen.flip()
                System.reboot()
            end
        end

    -- show version and other information
    elseif stype == "showversion" then
        drawMainInfo(Color.new(85, 85, 255))
        -- crappy workaround to highlight specific words
        print(5, 25, "The latest version is "..info..".", c_light_blue)
        print(5, 25, "The latest version is")
        if force_path == "" then
            print(5, 45, "The launcher's detected location is:")
        else
            print(5, 45, "The launcher's manually set location is:")
        end
        print(5, 60, vp[1], c_light_blue)
        print(5, 80, "The updater will also be updated at:")
        print(5, 95, "/gridlauncher/update")
        print(5, 135, "A: download and install")
        print(5, 150, "X: display changes for "..info)
        print(5, 165, "B: exit")
        Screen.flip()
        while true do
            local pad = Controls.read()
            if Controls.check(pad, KEY_B) then exit()
            elseif Controls.check(pad, KEY_X) then
                local result = updateState("showchangelog", info)
                if not result then exit() end
            elseif Controls.check(pad, KEY_A) then return end
        end

    -- show changelog
    elseif stype == "showchangelog" then
        local chg = Console.new(TOP_SCREEN)
        local function drawChangelog(ver, installed_ver)
            Screen.refresh()
            Screen.clear(TOP_SCREEN)
            Screen.clear(BOTTOM_SCREEN)
            printb(5, 5, "Grid Launcher Update")
            Screen.fillEmptyRect(6, 314, 17, 18, Color.new(85, 85, 255), BOTTOM_SCREEN)
            Console.clear(chg)
            Console.append(chg, getChangelog("beta", ver))
            Console.show(chg)
            printb(5, 25, "Displaying changelog for "..ver)
            printb(5, 65, "Left/Up: newer version")
            printb(5, 80, "Down/Right: older version")
            printb(5, 95, "Y: latest version")
            printb(5, 135, "A: download and install "..installed_ver)
            printb(5, 150, "B: exit")
            Screen.flip()
        end
        drawChangelog(latest_version, latest_version)
        local selected_ver = latest_version
        local pad, oldpad
        while true do
            pad = Controls.read()
            if (Controls.check(pad, KEY_DLEFT) or Controls.check(pad, KEY_DUP)) and not (Controls.check(oldpad, KEY_DLEFT) or Controls.check(oldpad, KEY_DUP)) then
                -- there's some really crappy workaround here...
                if selected_ver ~= latest_version then
                    --noinspection UnusedDef
                    selected_ver = string.sub("b"..selected_ver:sub(2) + 1, 1, -3)
                    drawChangelog(selected_ver, latest_version)
                end
            elseif (Controls.check(pad, KEY_DDOWN) or Controls.check(pad, KEY_DRIGHT)) and not (Controls.check(oldpad, KEY_DDOWN) or Controls.check(oldpad, KEY_DRIGHT)) then
                if selected_ver ~= "b1" then
                    --noinspection UnusedDef
                    selected_ver = string.sub("b"..selected_ver:sub(2) - 1, 1, -3)
                    drawChangelog(selected_ver, latest_version)
                end
            elseif Controls.check(pad, KEY_Y) and not Controls.check(oldpad, KEY_Y) then
                --noinspection UnusedDef
                selected_ver = latest_version
                drawChangelog(selected_ver, latest_version)
            elseif Controls.check(pad, KEY_A) then return true
            elseif Controls.check(pad, KEY_B) then exit() end
            oldpad = pad
        end
    
    -- show version and other information if glinfo.txt is missing
    elseif stype == "showversion-noinstall" then
        drawMainInfo(Color.new(85, 85, 255))
        -- crappy workaround to highlight specific words
        print(5, 25, "The latest version is "..info..".", c_light_blue)
        print(5, 25, "The latest version is")
        print(5, 45, "You are missing /gridlauncher/glinfo.txt.")
        print(5, 65, "This might be because you are not using the")
        print(5, 80, "grid launcher yet, and are using this")
        print(5, 95, "program to install it.")
        if force_path == "" then
            print(5, 115, "The grid launcher will be installed to:")
        else
            print(5, 115, "The launcher's manually set location is:")
        end
        print(5, 130, vp[1], c_light_blue)
        print(5, 150, "The updater will also be updated at:")
        print(5, 165, "/gridlauncher/update")
        print(5, 205, "A: download and install")
        print(5, 220, "B: exit")
        Screen.flip()
        while true do
            local pad = Controls.read()
            if Controls.check(pad, KEY_B) then exit()
            elseif Controls.check(pad, KEY_A) then return end
        end

    -- downloading launcher.zip
    elseif stype == "downloading" then
        drawMainInfo(Color.new(127, 255, 127))
        print(5, 25, "-> Downloading "..info..", be patient!")
        print(5, 40, "    Extracting, sit tight!", c_grey)
        print(5, 55, "    Installing, this doesn't take long!", c_grey)
        print(5, 70, "    Done!", c_grey)
        print(5, 110, "Do not turn off the power.")
        Screen.flip()

    -- now comes the extraction
    elseif stype == "extracting" then
        drawMainInfo(Color.new(127, 255, 127))
        print(5, 25, "    Downloading "..info..", be patient!", c_grey)
        print(5, 40, "-> Extracting, sit tight!")
        print(5, 55, "    Installing, this doesn't take long!", c_grey)
        print(5, 70, "    Done!", c_grey)
        print(5, 110, "Do not turn off the power.")
        Screen.flip()

    -- now comes the extraction
    elseif stype == "installing" then
        drawMainInfo(Color.new(127, 255, 127))
        print(5, 25, "    Downloading "..info..", be patient!", c_grey)
        print(5, 40, "    Extracting, sit tight!", c_grey)
        print(5, 55, "-> Installing, this doesn't take long!")
        print(5, 70, "    Done!", c_grey)
        print(5, 110, "Do not turn off the power.")
        Screen.flip()

    -- and we're all done
    elseif stype == "done" then
        drawMainInfo(Color.new(0, 255, 0))
        print(5, 25, "    Downloading "..info..", be patient!", c_grey)
        print(5, 40, "    Extracting, sit tight!", c_grey)
        print(5, 55, "    Installing, this doesn't take long!", c_grey)
        print(5, 70, "-> Done!", Color.new(127, 255, 127))
        print(5, 70, "->")
        print(5, 110, "A/B: exit")
        Screen.flip()
        while true do
            if Controls.check(Controls.read(), KEY_A) or Controls.check(Controls.read(), KEY_B) then
                exit()
            end
        end

    -- prevent the program from automatically continuing if I make a mistake
    else
        drawMainInfo(Color.new(255, 0, 0))
        print(5, 25, "uh...")
        print(5, 40, "If you are reading this on your 3DS,")
        print(5, 55, "tell ihaveamac on GitHub.")
        print(5, 75, "Note this: "..lastState)
        print(5, 115, "Y: exit")
        Screen.flip()
        while true do
            if Controls.check(Controls.read(), KEY_Y) then
                exit()
            end
        end

    -- the end!!!
    end
end
