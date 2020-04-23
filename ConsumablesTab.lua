local ConsumablesTab =  {}
_G["ConsumablesTab"] = ConsumablesTab

local AceGUI = LibStub("AceGUI-3.0")

local specs = {
    ["All Classes"] = {
        ["englishClass"] = "",
        ["currentBuffs"] = {},
        ["currentItems"] = {},
        ["consumables"] = {
            ["Greater Fire Protection Potion"] = {
                ["icon"] = "Interface\\Icons\\inv_potion_24",
                ["id"] = "13457",
                ["checked"] = true,
                ["toolTip"] = nil,
                ["buffId"] = "17543",
                ["itemId"] = "13457",
                ["secondaryItemId"] = "6049",
                ["secondaryBuffId"] = "7233",
                ["playerCheckBuff"] = false
            },
            ["Greater Nature Protection Potion"] = {
                ["icon"] = "Interface\\Icons\\inv_potion_22",
                ["id"] = "13458",
                ["checked"] = true,
                ["toolTip"] = nil,
                ["buffId"] = "17546",
                ["itemId"] = "13458",
                ["secondaryItemId"] = "6052",
                ["secondaryBuffId"] = "7254",
                ["playerCheckBuff"] = false
            },
            ["Greater Frost Protection Potion"] = {
                ["icon"] = "Interface\\Icons\\inv_potion_20",
                ["id"] = "13456",
                ["checked"] = true,
                ["toolTip"] = nil,
                ["buffId"] = "17544",
                ["itemId"] = "13456",
                ["secondaryItemId"] = "6050",
                ["secondaryBuffId"] = "7239",
                ["playerCheckBuff"] = false
            },
            ["Greater Shadow Protection Potion"] = {
                ["icon"] = "Interface\\Icons\\inv_potion_23",
                ["id"] = "13459",
                ["checked"] = true,
                ["toolTip"] = nil,
                ["buffId"] = "17548",
                ["itemId"] = "13459",
                ["secondaryItemId"] = "6048",
                ["secondaryBuffId"] = "7242",
                ["playerCheckBuff"] = false
            },
            ["Greater Arcane Protection Potion"] = {
                ["icon"] = "Interface\\Icons\\inv_potion_83",
                ["id"] = "13461",
                ["checked"] = true,
                ["toolTip"] = nil,
                ["buffId"] = "17549",
                ["itemId"] = "13461",
                ["secondaryItemId"] = nil,
                ["secondaryBuffId"] = nil,
                ["playerCheckBuff"] = false
            }
        }
    }
}

local function OnValueChanged(spellName)
    local currType = ClassicRaidAssistFury.db.char.currentConsumableType
    local currSpec = ClassicRaidAssistFury.db.char.currentSpecTab
    if(ClassicRaidAssistFury.db.char.consumablesToCheckFor[currSpec][currType][spellName] == false or ClassicRaidAssistFury.db.char.consumablesToCheckFor[currSpec][currType][spellName] == nil) then
        ClassicRaidAssistFury.db.char.consumablesToCheckFor[currSpec][currType][spellName] = true
    else
        ClassicRaidAssistFury.db.char.consumablesToCheckFor[currSpec][currType][spellName] = false
    end
end


function ConsumablesTab:getConsumables()
    return specs
end

-- buff or item scan
function ConsumablesTab:ScanConsumables(type, spec)
    if type == "ITEM" then
        specs[spec]['currentItems'] = {}
        
        for key, value in pairs(specs[spec]['consumables']) do
            
            -- if(value['checked']) then
            if(ClassicRaidAssistFury.db.char.consumablesToCheckFor[spec][type][key]) then
                ClassicRaidAssistFury:ConsumableQuestion(spec, value['itemId'])
            end
        end
    elseif type == "BUFF" then
        specs[spec]['currentBuffs'] = {}
    
        for key, value in pairs(specs[spec]['consumables']) do
            -- if(value['checked']) then
            
            if(ClassicRaidAssistFury.db.char.consumablesToCheckFor[spec][type][key]) then
                if (value['buffId'] ~= nil) then
                    ClassicRaidAssistFury:QuestionBuffs(spec, value['buffId'])
                end
            end
        end
    end
end

local function DrawCurrentClassConsumables()
    local currentSpec = ClassicRaidAssistFury.db.char.currentSpecTab
    local raidContainer = AceGUI:Create("SimpleGroup")
    raidContainer:SetFullWidth(true)
    raidContainer:SetLayout("Flow")

    local groupContainer = AceGUI:Create("SimpleGroup")
    groupContainer:SetRelativeWidth(1)
    groupContainer:SetLayout("List")
    groupContainer:SetFullWidth(true)

    local currentTypeIteration = {}

    if ClassicRaidAssistFury.db.char.currentConsumableType == "ITEM" then
        currentTypeIteration = specs[currentSpec]['currentItems']
    elseif ClassicRaidAssistFury.db.char.currentConsumableType == "BUFF" then
        currentTypeIteration = specs[currentSpec]['currentBuffs']
    end

    local spellsPerRow = 15
    local currentSpells = 0

    for key, value in pairs(currentTypeIteration) do
        local playerContainer = AceGUI:Create("SimpleGroup")
        playerContainer:SetLayout("Flow")
        playerContainer:SetFullWidth(true)

        local spellContainer = nil
        local currName = AceGUI:Create("Label")
        currName:SetWidth(90)
        local _, englishClass, classIndex = UnitClass(key);
        currName:SetText("|c" .. RAID_CLASS_COLORS[englishClass].colorStr .. key .. "|r")

        spellContainer = AceGUI:Create("SimpleGroup")
        spellContainer:SetLayout("Flow")
        spellContainer:SetFullWidth(true)

        spellContainer:AddChild(currName)

        currentSpells = 0
        for spellName, hasConsume in pairs(value) do
            if(spellContainer == nil or currentSpells > spellsPerRow) then

                currName = AceGUI:Create("Label")
                currName:SetWidth(90)

                if(currentSpells >= spellsPerRow) then
                    currentSpells = 0
                    playerContainer:AddChild(spellContainer)
                else
                    currName:SetText("|c" .. RAID_CLASS_COLORS[specs[currentSpec]['englishClass']].colorStr .. key .. "|r")
                end

                spellContainer = AceGUI:Create("SimpleGroup")
                spellContainer:SetLayout("Flow")
                spellContainer:SetFullWidth(true)

                spellContainer:AddChild(currName)
                end
            local currSpell = AceGUI:Create("Icon")
            if(hasConsume == "-1") then
                currSpell:SetImage("Interface\\Icons\\inv_misc_questionmark")
            else
                currSpell:SetImage(specs[currentSpec]['consumables'][spellName]["icon"])
            end
            currSpell:SetImageSize("16", "16")
            -- currSpell:SetDisabled(true)
            -- currSpell.frame:SetScript("OnEnter", function() end)
            -- currSpell.frame:SetScript("OnLeave", function() end)
            currSpell.image:SetAllPoints()
            currSpell:SetWidth(16)
            currSpell:SetHeight(16)

            currSpell.frame:SetScript("OnEnter", function()
                if(specs[currentSpec]['consumables'][spellName]['toolTip'] == nil) then
                    specs[currentSpec]['consumables'][spellName]['toolTip'] = CreateFrame( "GameTooltip", spellName .. currentSpec .. currentSpec .. key, nil, "GameTooltipTemplate" )
                end
                MyToolTip = specs[currentSpec]['consumables'][spellName]['toolTip']
                MyToolTip:SetOwner(WorldFrame, "ANCHOR_CURSOR")
                MyToolTip:SetItemByID(specs[currentSpec]['consumables'][spellName]['id']) -- , 1, .82, 0, true)
                MyToolTip:Show() 
            end)
            currSpell.frame:SetScript("OnLeave", function() 
                MyToolTip:Hide() 
            end)

            if hasConsume == "0" then
                currSpell.image:SetVertexColor(1, 1, 1, 0.1)
            else
                currSpell.image:SetVertexColor(1, 1, 1, 1)
            end
            currentSpells = currentSpells + 1
            
            local spacer = AceGUI:Create("Label")
            spacer:SetWidth(2)

            spellContainer:AddChild(currSpell)
            spellContainer:AddChild(spacer)
            -- end
        end
        playerContainer:AddChild(spellContainer)
        groupContainer:AddChild(playerContainer)
    end
    raidContainer:AddChild(groupContainer)
    return raidContainer
end

function ConsumablesTab:outputBuffs(channel, type, spec)
    if type ~= "ITEM" and type ~= "BUFF" then
        return
    end

    local knownPlayers = {}
    for key, value in pairs(specs[spec][(type == "ITEM" and "currentItems" or "currentBuffs")]) do
        knownPlayers[key] = true
    end

    local missingItemsOrBuffs = {}
    for key, value in pairs(specs[spec][(type == "ITEM" and "currentItems" or "currentBuffs")]) do
        for k, v in pairs(value) do
            if(missingItemsOrBuffs[k] == nil) then
                missingItemsOrBuffs[k] = {}
            end

            if(v == "0") then
                table.insert(missingItemsOrBuffs[k], key)
            end
        end
    end

    local introMessage = "[Classic Raid Assist Fury] Ouputting " .. spec .." Missing Consumable " .. (type == "ITEM" and "Items" or "Buffs") .. ": "

    local initialMessageSent = true
    local stringCompose = ""
    for key, value in pairs(missingItemsOrBuffs) do
        local beginningString = key .. ":"
        stringCompose = beginningString
        for k, v in pairs(value) do
            local stringToAdd = v .. ","
            if ( string.len(stringCompose) + string.len(stringToAdd) ) >= 255 then    
                if initialMessageSent then
                    initialMessageSent = false
                    CRA_SendChatMessage(introMessage, channel)
                end
                CRA_SendChatMessage(stringCompose:sub(1, -2), channel)
                stringCompose = beginningString
            end
            stringCompose = stringCompose .. " " .. stringToAdd
        end
        if(stringCompose ~= beginningString) then
            if initialMessageSent then
                initialMessageSent = false
                CRA_SendChatMessage(introMessage, channel)
            end
            CRA_SendChatMessage(stringCompose:sub(1, -2), channel)
        end
    end

    -- List players with unknown item/buff status
    local unknownPlayersBeginning = "Unknown:"
    stringCompose = unknownPlayersBeginning
    for i = 1, MAX_RAID_MEMBERS do
        local tempPlayerName, _, subgroup, _, class, englishClass = GetRaidRosterInfo(i)
        if(tempPlayerName ~= nil and class ~= nil) then
            if not knownPlayers[tempPlayerName] then
                local stringToAdd = tempPlayerName .. ","
                if ( string.len(stringCompose) + string.len(stringToAdd) ) >= 255 then    
                    if initialMessageSent then
                        initialMessageSent = false
                        CRA_SendChatMessage(introMessage, channel)
                    end
                    CRA_SendChatMessage(stringCompose:sub(1, -2), channel)
                    stringCompose = unknownPlayersBeginning
                end
                stringCompose = stringCompose .. " " .. stringToAdd
            end
        end
    end
    if(stringCompose ~= unknownPlayersBeginning) then
        if initialMessageSent then
            initialMessageSent = false
            CRA_SendChatMessage(introMessage, channel)
        end
        CRA_SendChatMessage(stringCompose:sub(1, -2), channel)
    end
end

local function drawClassTab(spec)
    local rowSize = 6
    local spacerWidth = 10
    local tabWidth = 385
    local fullTab = AceGUI:Create("SimpleGroup")
    fullTab:SetWidth(tabWidth)
    fullTab:SetLayout("Flow")

    local totalConsumables = 0
    for key, value in pairs(specs[spec]['consumables']) do
        if (ClassicRaidAssistFury.db.char.currentConsumableType == "ITEM" or value['buffId'] ~= nil) then
            totalConsumables = totalConsumables + 1
        end
    end
    local remainingConsumables = totalConsumables

    if(totalConsumables % rowSize == 1 or totalConsumables % rowSize == 2) then
        rowSize = rowSize - 1
    end
        
    if(totalConsumables % rowSize == 1 or totalConsumables % rowSize == 2) then
        rowSize = rowSize + 2
    end

    local totalWidth = (tabWidth-30-spacerWidth)/(rowSize)

    local consumableCheckBoxRows = {}
    local consumableCheckBox = AceGUI:Create("InlineGroup")
    consumableCheckBox:SetTitle("Check for these Consumables:")
    consumableCheckBox:SetFullWidth(true)
    consumableCheckBox:SetLayout("Flow")

    local consumableCheckBoxRow = nil
    -- AceGUI:Create("Simple Group")
    -- consumableCheckBox:SetFullWidth(true)
    -- consumableCheckBox:SetLayout("Flow")

    -- local spacerGroup = AceGUI:Create("Label")
    -- spacerGroup:SetWidth(10)
    -- consumableCheckBox:AddChild(spacerGroup)

    local currentRowSize = 0
    for consumable, consumableValues in pairs(specs[spec]['consumables']) do
        if(ClassicRaidAssistFury.db.char.currentConsumableType == "ITEM" or consumableValues['buffId'] ~= nil) then
            if(currentRowSize >= rowSize or currentRowSize == 0) then
                if(consumableCheckBoxRow ~= nil) then
                    remainingConsumables = remainingConsumables - rowSize
                    table.insert(consumableCheckBoxRows, consumableCheckBoxRow)
                end
                if remainingConsumables < rowSize then
                    spacerWidth = spacerWidth * (rowSize - remainingConsumables + 1)
                    totalWidth = (tabWidth-30-spacerWidth)/(remainingConsumables)
                end
                consumableCheckBoxRow = AceGUI:Create("SimpleGroup")
                consumableCheckBoxRow:SetFullWidth(true)
                consumableCheckBoxRow:SetLayout("Flow")
                
                local spacerGroup = AceGUI:Create("Label")
                spacerGroup:SetWidth(spacerWidth)
                consumableCheckBoxRow:AddChild(spacerGroup)
                currentRowSize = 0
            end
            local tempCheckBox = AceGUI:Create("CheckBox")
            tempCheckBox:SetWidth(totalWidth)
            tempCheckBox:SetLabel("")
            tempCheckBox:SetValue(ClassicRaidAssistFury.db.char.consumablesToCheckFor[spec][ClassicRaidAssistFury.db.char.currentConsumableType][consumable])
            -- tempCheckBox:SetValue(consumableValues['checked'])
            tempCheckBox:SetImage(consumableValues["icon"])
            tempCheckBox:SetCallback("OnValueChanged", function() OnValueChanged(consumable) end)
            tempCheckBox:SetCallback("OnEnter", function() 
                if(consumableValues['toolTip'] == nil) then
                    consumableValues['toolTip'] = CreateFrame( "GameTooltip", consumable .. spec .. ClassicRaidAssistFury.db.char.currentConsumableType .. "checkbox" , nil, "GameTooltipTemplate" )
                end
                MyToolTip = consumableValues['toolTip']
                MyToolTip:SetOwner(tempCheckBox.frame, "ANCHOR_CURSOR")
                MyToolTip:SetItemByID(consumableValues['id']) -- , 1, .82, 0, true)
                MyToolTip:Show() 
            end)
            tempCheckBox:SetCallback("OnLeave", function() 
                MyToolTip:Hide() 
            end)
            consumableCheckBoxRow:AddChild(tempCheckBox)
            currentRowSize = currentRowSize + 1
        else
            
            ClassicRaidAssistFury.db.char.consumablesToCheckFor[spec][ClassicRaidAssistFury.db.char.currentConsumableType][consumable] = false
            -- consumableValues['checked'] = false
        end
    end
    table.insert(consumableCheckBoxRows, consumableCheckBoxRow)
    for key, value in pairs(consumableCheckBoxRows) do
        -- print(key)
        consumableCheckBox:AddChild(value)
    end
    fullTab:AddChild(consumableCheckBox)
    fullTab:AddChild(DrawCurrentClassConsumables())
    return fullTab
end

function ConsumablesTab:DrawConsumables(container)
    ClassicRaidAssistFury:ClearCooldowns()

    local specChoosingGroup = AceGUI:Create("SimpleGroup")
    specChoosingGroup:SetFullWidth(true)
    specChoosingGroup:SetLayout("Flow")

    local specChoosingLabel = AceGUI:Create("Label")
    specChoosingLabel:SetWidth(175)
    specChoosingLabel:SetText("Choose Item or Buff and Class to Check for:")
    specChoosingGroup:AddChild(specChoosingLabel)

    local typeDropdown = AceGUI:Create("Dropdown")
    typeDropdown:SetWidth(75)
    typeDropdown:SetList({["ITEM"] = "Item", ["BUFF"] = "Buff"})
    typeDropdown:SetValue(ClassicRaidAssistFury.db.char.currentConsumableType)
    typeDropdown:SetCallback("OnValueChanged", function(widget, event, key)
        container:ReleaseChildren()
        ClassicRaidAssistFury.db.char.currentConsumableType = key
        ClassicRaidAssistFury.db.char.consumablesContainer = container
        ConsumablesTab:DrawConsumables(container)
    end)
    specChoosingGroup:AddChild(typeDropdown)

    local specDropDown = AceGUI:Create("Dropdown")
    specDropDown:SetWidth(150)
    local dropdown = {}
    for key, value in pairs(specs) do
        dropdown[key] = key
    end
    specDropDown:SetList(dropdown)
    specDropDown:SetValue(ClassicRaidAssistFury.db.char.currentSpecTab)
    specDropDown:SetCallback("OnValueChanged", function(widget, event, key)
        container:ReleaseChildren()
        ClassicRaidAssistFury.db.char.currentSpecTab = key
        ClassicRaidAssistFury.db.char.consumablesContainer = container
        ConsumablesTab:DrawConsumables(container)
    end)
    specChoosingGroup:AddChild(specDropDown)
    container:AddChild(specChoosingGroup)

    local spacer = AceGUI:Create("SimpleGroup")
    spacer:SetFullWidth(true)
    spacer:SetLayout("Flow")
    spacer:SetHeight(80)
    
    local scanBtn = AceGUI:Create("Button")
    scanBtn:SetText("Scan " .. ClassicRaidAssistFury.db.char.currentSpecTab) --.. " consumables")
    scanBtn:SetWidth(200)
    if not (IsInGroup() or IsInRaid()) then
        scanBtn:SetDisabled(true)
        scanBtn:SetText("Can't scan, not in a group")
    end
    scanBtn:SetCallback("OnClick", function()
        container:ReleaseChildren()
        ClassicRaidAssistFury.db.char.consumablesContainer = container
        ConsumablesTab:ScanConsumables(ClassicRaidAssistFury.db.char.currentConsumableType, ClassicRaidAssistFury.db.char.currentSpecTab)
        ConsumablesTab:DrawConsumables(container)
    end)
    spacer:AddChild(scanBtn)
    
    local reportBtn = AceGUI:Create("Button")
    reportBtn:SetText("Report")
    reportBtn:SetWidth(100)
    reportBtn:SetCallback("OnClick", function()
        ConsumablesTab:outputBuffs(ClassicRaidAssistFury.db.char.CurrentConsumablesOutputChannel, ClassicRaidAssistFury.db.char.currentConsumableType, ClassicRaidAssistFury.db.char.currentSpecTab)
    end)
    spacer:AddChild(reportBtn)

    local reportDropdown = AceGUI:Create("Dropdown")
    reportDropdown:SetWidth(100)
    reportDropdown:SetList(GetChatChannels())
    reportDropdown:SetValue(ClassicRaidAssistFury.db.char.CurrentConsumablesOutputChannel)
    reportDropdown:SetCallback("OnValueChanged", function(widget, event, key)
        ClassicRaidAssistFury.db.char.CurrentConsumablesOutputChannel = key
    end)
    spacer:AddChild(reportDropdown)

    container:AddChild(spacer)

    local scrollContainer = AceGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetHeight(300)
    scrollContainer:SetLayout("Fill")

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scrollContainer:AddChild(scroll)

    local raidContainer = AceGUI:Create("SimpleGroup")
    
    scroll:AddChild(drawClassTab(ClassicRaidAssistFury.db.char.currentSpecTab))
    container:AddChild(scrollContainer)
    
    local bottomNote = AceGUI:Create("Label")
    bottomNote:SetFullWidth(true)
    bottomNote:SetText("Everyone in the raid needs the addon to be shown here.")
    container:AddChild(bottomNote)
end