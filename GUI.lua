local GUI = {}
_G["ClassicRaidAssistFuryGUI"] = GUI
_G["ClassicRaidAssistFuryGUI_Shown"] = false
local AceGUI = LibStub("AceGUI-3.0")

LibStub("AceHook-3.0"):Embed(GUI)

local version = GetAddOnMetadata("ClassicRaidAssistFury", "Version")

local AceGUI = LibStub("AceGUI-3.0")
local frame = nil
local tabGroup = nil

function GUI:ReloadTab()
    tabGroup:SelectTab(ClassicRaidAssistFury.db.char.currentTab)
end


function GUI:Toggle()
    if(frame:IsShown()) then
        ClassicRaidAssistFuryGUI_Shown = false
        frame:Hide()
    else
        -- refresh tab on toggle in
        ClassicRaidAssistFuryGUI_Shown = true
        tabGroup:SelectTab(ClassicRaidAssistFury.db.char.currentTab)
        frame:Show()
    end
end

function GUI:DrawSettings(container)
    ClassicRaidAssistFury:ClearCooldowns()

    local settingsContainer = AceGUI:Create("InlineGroup")
    settingsContainer:SetTitle("Settings:")
    settingsContainer:SetFullWidth(true)
    settingsContainer:SetLayout("Flow")

    container:AddChild(settingsContainer)

    local leftSettings = AceGUI:Create("SimpleGroup")
    local rightSettings = AceGUI:Create("SimpleGroup")
    leftSettings:SetWidth(180)
    leftSettings:SetLayout("Flow")
    rightSettings:SetWidth(180)
    rightSettings:SetLayout("Flow")
    settingsContainer:AddChild(leftSettings)
    settingsContainer:AddChild(rightSettings)

    local itemScanningCheckBox = AceGUI:Create("CheckBox")
    -- itemScanningCheckBox:SetWidth(90)
    itemScanningCheckBox:SetValue(ClassicRaidAssistFury.db.char.allowItemScanning)
    itemScanningCheckBox:SetLabel("Allow Item Scanning")
    itemScanningCheckBox:SetCallback("OnValueChanged", function() ClassicRaidAssistFury.db.char.allowItemScanning = not ClassicRaidAssistFury.db.char.allowItemScanning end)

    leftSettings:AddChild(itemScanningCheckBox)

    
    local smartBuffFilteringOption = AceGUI:Create("CheckBox")
    -- itemScanningCheckBox:SetWidth(90)
    smartBuffFilteringOption:SetValue(ClassicRaidAssistFury.db.char.smartBuffFiltering)
    smartBuffFilteringOption:SetLabel("Smart Buff Filtering")
    smartBuffFilteringOption:SetCallback("OnValueChanged", function() ClassicRaidAssistFury.db.char.smartBuffFiltering = not ClassicRaidAssistFury.db.char.smartBuffFiltering end)

    rightSettings:AddChild(smartBuffFilteringOption)


    local checkBoxGroup = AceGUI:Create("SimpleGroup")
    local dropdownGroup = AceGUI:Create("SimpleGroup")
    checkBoxGroup:SetWidth(295)
    checkBoxGroup:SetLayout("Flow")
    dropdownGroup:SetWidth(85)
    dropdownGroup:SetLayout("Flow")
    settingsContainer:AddChild(checkBoxGroup)
    settingsContainer:AddChild(dropdownGroup)

    
    local readyCheckOption = AceGUI:Create("CheckBox")
    readyCheckOption:SetFullWidth(true)
    readyCheckOption:SetValue(ClassicRaidAssistFury.db.char.readyCheckOutput)
    readyCheckOption:SetLabel("On Ready Check Print Buffs (Raid Assist Only)")
    readyCheckOption:SetCallback("OnValueChanged", function() ClassicRaidAssistFury.db.char.readyCheckOutput = not ClassicRaidAssistFury.db.char.readyCheckOutput end)

    checkBoxGroup:AddChild(readyCheckOption)

    local reportDropdown = AceGUI:Create("Dropdown")
    reportDropdown:SetFullWidth(true)
    reportDropdown:SetList(GetChatChannels())
    reportDropdown:SetValue(ClassicRaidAssistFury.db.char.CurrentReadyCheckOutputChannel)
    reportDropdown:SetCallback("OnValueChanged", function(widget, event, key)
        ClassicRaidAssistFury.db.char.CurrentReadyCheckOutputChannel = key
    end)
    dropdownGroup:AddChild(reportDropdown)


    local scanBtn = AceGUI:Create("Button")
    scanBtn:SetText("Scan for versions")
    scanBtn:SetWidth(400)
    if not (IsInGroup() or IsInRaid()) then
        scanBtn:SetDisabled(true)
        scanBtn:SetText("Can't scan, not in a group")
    end
    scanBtn:SetCallback("OnClick", function()
        ClassicRaidAssistFury:Scan()
        ClassicRaidAssistFury.db.char.settingsContainer = container
        container:ReleaseChildren()
        GUI:DrawSettings(container)
    end)
    container:AddChild(scanBtn)


    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetHeight(250)
    scrollContainer:SetLayout("Fill")

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scrollContainer:AddChild(scroll)

    local raidContainer = AceGUI:Create("SimpleGroup")
    
    scroll:AddChild(raidContainer)

    local leftContainer = AceGUI:Create("SimpleGroup")
    local rightContainer = AceGUI:Create("SimpleGroup")
    raidContainer:SetFullWidth(true)
    raidContainer:SetLayout("Flow")
    leftContainer:SetWidth(180)
    leftContainer:SetLayout("Flow")
    rightContainer:SetWidth(180)
    rightContainer:SetLayout("Flow")
    currentCount = 0
    for i = 1, MAX_RAID_MEMBERS do
        local tempPlayerName, _, _, _, class, englishClass = GetRaidRosterInfo(i)
        if(tempPlayerName ~= nil and class ~= nil) then
            currentCount = currentCount + 1
            local currPlayerName, currPlayerRealm = UnitName(tempPlayerName)
            local playerContainer = AceGUI:Create("SimpleGroup")
            playerContainer:SetLayout("Flow")
            playerContainer:SetWidth(180)

            local curr_name = AceGUI:Create("Label")
            curr_name:SetWidth(80)
            curr_name:SetText("|c" .. RAID_CLASS_COLORS[englishClass].colorStr .. currPlayerName .. "|r")

            local status = AceGUI:Create("Label")
            status:SetWidth(80)
            
            if(ClassicRaidAssistFury.raid[currPlayerName] == nil) then
                status:SetText("|cffff0000MISSING|r")
            elseif(ClassicRaidAssistFury.raid[currPlayerName] ~= version) then
                status:SetText("|cffffff00" .. ClassicRaidAssistFury.raid[currPlayerName] .. "|r")
            elseif(ClassicRaidAssistFury.raid[currPlayerName] == version) then
                status:SetText("|cff00b300" .. ClassicRaidAssistFury.raid[currPlayerName] .. "|r")
            end
            playerContainer:AddChild(curr_name)
            playerContainer:AddChild(status)
            if(i <= 20) then
                leftContainer:AddChild(playerContainer)
            else
                rightContainer:AddChild(playerContainer)
            end
        end
    end
    
    -- Keep spacing in scan raid tab, fill in with blanks
    if(currentCount <= 20) then
        for i = currentCount, 20 do
            local playerContainer = AceGUI:Create("SimpleGroup")
            playerContainer:SetLayout("Flow")
            playerContainer:SetWidth(200)

            local curr_name = AceGUI:Create("Label")
            curr_name:SetWidth(100)
            curr_name:SetText(" ")
            playerContainer:AddChild(curr_name)
            leftContainer:AddChild(playerContainer)
        end
    else
        for i = currentCount, 39 do
            local playerContainer = AceGUI:Create("SimpleGroup")
            playerContainer:SetLayout("Flow")
            playerContainer:SetWidth(200)

            local curr_name = AceGUI:Create("Label")
            curr_name:SetWidth(100)
            curr_name:SetText(" ")
            playerContainer:AddChild(curr_name)
            rightContainer:AddChild(playerContainer)
        end
    end

    raidContainer:AddChild(leftContainer)
    raidContainer:AddChild(rightContainer)
    container:AddChild(scrollContainer)
end

local function SelectGroup(container, event, group)
    container:ReleaseChildren()
    ClassicRaidAssistFury.db.char.currentTab = group
    if group == "settings" then
        GUI:DrawSettings(container)
    elseif group == "raidBuffs" then
        RaidBuffsTab:DrawRaidBuffs(container)
    elseif group == "worldBuffs" then
        WorldBuffsTab:DrawWorldBuffs(container)
    elseif group == "paladinBuffs" then
        PaladinBuffsTab:DrawPaladinBuffs(container)
    elseif group == "raidItems" then
        RaidItemsTab:DrawRaidItems(container)
    elseif group == "consumables" then
        ConsumablesTab:DrawConsumables(container)
    end
end

function GUI:SetUpGUI()
    frame = AceGUI:Create("Frame")
    _G["ClassicRaidAssistFuryGUI_frame"] = frame
    frame:Hide()
    frame:EnableResize(false)
    frame:SetWidth(460)
    frame:SetTitle("Classic Raid Assist Fury")
    frame:SetStatusText("v" .. ClassicRaidAssistFury.version .. " Spec: " .. ClassicRaidAssistFury.thisPlayerSpec .. " Class: " .. ClassicRaidAssistFury.thisPlayerClass)
    tinsert(UISpecialFrames, "ClassicRaidAssistFuryGUI_frame")
    frame:SetLayout("Fill")
    tabGroup = AceGUI:Create("TabGroup")
    
    if (ClassicRaidAssistFury.faction == "Horde") then
        tabGroup:SetTabs({
            {value = "raidBuffs", text = "Raid Buffs" },
            {value = "worldBuffs", text = "World Buffs" },
            {value = "raidItems", text = "Raid Items" },
            {value = "consumables", text = "Consumables" },
            {value = "settings", text = "Settings" },
        })
    else
        tabGroup:SetTabs({
            {value = "raidBuffs", text = "Raid Buffs" },
            {value = "worldBuffs", text = "World Buffs" },
            {value = "paladinBuffs", text = "Paladin Buffs" },
            {value = "raidItems", text = "Raid Items" },
            {value = "consumables", text = "Consumables" },
            {value = "settings", text = "Settings" },
        })
    end
    tabGroup:SetCallback("OnGroupSelected", SelectGroup)
    tabGroup:SelectTab(ClassicRaidAssistFury.db.char.currentTab)
    frame:AddChild(tabGroup)
end