ClassicRaidAssistFury = LibStub("AceAddon-3.0"):NewAddon("ClassicRaidAssistFury", "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")
_G['ClassicRaidAssistFury'] = ClassicRaidAssistFury
_G['cooldownFrames'] = {}

local MAX_NUMBER_OF_UNITS = 100
local curr_unit_pointer = 1

local list_of_units = {}
for i=1, MAX_NUMBER_OF_UNITS do
    list_of_units[i] = nil
end

local announcePrefix = "CRAF_a"
local questionPrefix = "CRAF_q"
local scanSendPrefix = "CRAF_ss"
local scanRecievePrefix = "CRAF_sr"
local questionItemPrefix = "CRAF_qi"
local sendItemPrefix = "CRAF_si"
local sendBadItemPrefix = "CRAF_sbi"
local consumableQuestionItemPrefix = "CRAF_cqi"
local consumableSendItemPrefix = "CRAF_csi"
local consumableQuestionBuffPrefix = "CRAF_cqb"
local consumableSendBuffPrefix = "CRAF_csb"

local version = GetAddOnMetadata("ClassicRaidAssistFury", "Version")
ClassicRaidAssistFury.version = version

local name, _ = UnitName("player")
local _, thisPlayerClass, _ = UnitClass("player")
thisPlayerClass = string.lower(thisPlayerClass):gsub("^%l", string.upper)
ClassicRaidAssistFury.thisPlayerClass = thisPlayerClass
local faction, _ = UnitFactionGroup("player")
ClassicRaidAssistFury.faction = faction
ClassicRaidAssistFury.thisPlayerSpec = "Loading"

local hasScanned = false

function ClassicRaidAssistFury:Scan()
    hasScanned = true
    self.raid[name] = version
    ClassicRaidAssistFury:SendMessage(version, scanSendPrefix)
end

function ClassicRaidAssistFury:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ClassicRaidAssistFuryDB", {
        factionrealm = {
            minimapButton = {hide = false}
        },
        char = {
            buffsToCheckFor = {},
            worldBuffsToCheckFor = {},
            paladinBuffsToCheckFor = {},
            consumablesToCheckFor = {
                ["All Classes"] = {
                    ["ITEM"] = {},
                    ["BUFF"] = {}
                }
            },
            CurrentRaidBuffsOutputChannel = "RAID",
            CurrentWorldBuffsOutputChannel = "RAID",
            CurrentRaidItemsOutputChannel = "RAID",
            CurrentConsumablesOutputChannel = "RAID",
            CurrentPaladinBuffsOutputChannel = "RAID",
            CurrentReadyCheckOutputChannel = "RAID",
            CurrentRaidItemCheck = "Aqual Quintessence",
            smartBuffFiltering = true,
            readyCheckOutput = false,
            allowItemScanning = true,
            raidItemsContainer = nil,
            settingsContainer = nil,
            consumablesContainer = nil,
            currentTab = "raidBuffs",
            currentSpecTab = "All Classes",
            currentConsumableType = "ITEM"
        }
    }, true)
    
    self.raid = {}
    self.unit = {}
    
    self:RegisterComm(announcePrefix, "OnAnnounce")
    self:RegisterComm(questionPrefix, "OnQuestion")
    self:RegisterComm(scanSendPrefix, "OnScanSend")
    self:RegisterComm(scanRecievePrefix, "OnScanRecieve")
    self:RegisterComm(questionItemPrefix, "OnQuestionItem")
    self:RegisterComm(sendItemPrefix, "OnSendItem")
    self:RegisterComm(sendBadItemPrefix, "OnSendBadItem")
    self:RegisterComm(consumableQuestionItemPrefix, "OnConsumableQuestionItem")
    self:RegisterComm(consumableSendItemPrefix, "OnConsumableSendItem")
    self:RegisterComm(consumableQuestionBuffPrefix, "OnConsumableQuestionBuff")
    self:RegisterComm(consumableSendBuffPrefix, "OnConsumableSendBuff")
    
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(self)
        ClassicRaidAssistFury.thisPlayerSpec = determineSpec(ClassicRaidAssistFury.thisPlayerClass)
        ClassicRaidAssistFuryGUI_frame:SetStatusText("v" .. ClassicRaidAssistFury.version .. " Spec: " .. ClassicRaidAssistFury.thisPlayerSpec .. " Class: " .. ClassicRaidAssistFury.thisPlayerClass)
    end)

    local readyCheckFrame = CreateFrame("Frame")
    readyCheckFrame:RegisterEvent("READY_CHECK")
    readyCheckFrame:SetScript("OnEvent", function(self)
        ClassicRaidAssistFury:ReadyCheckOutput()
    end)

    ClassicRaidAssistFury:SetUpMouseEvent()
    ClassicRaidAssistFuryGUI:SetUpGUI()
    ClassicRaidAssistFury:SetUpMinimapIcon()
    
    local options = {
        name = 'ClassicRaidAssistFury',
        type = 'group'
    }
    LibStub("AceConfig-3.0"):RegisterOptionsTable("ClassicRaidAssistFury", options)
end 

function ClassicRaidAssistFury:ClearCooldowns()
    for key, value in pairs(cooldownFrames) do
        value:Hide()
    end
    cooldownFrames  = {}
end

function ClassicRaidAssistFury:SendMessage(msg, prefix)
    local instance, instanceType = IsInInstance()
    if(instance) then
        if(instanceType == "raid") then
            ClassicRaidAssistFury:SendCommMessage(prefix, msg, "RAID")
        elseif(instanceType == "party") then
            ClassicRaidAssistFury:SendCommMessage(prefix, msg, "PARTY")
        else
            ClassicRaidAssistFury:SendCommMessage(prefix, msg, "INSTANCE_CHAT")
        end
    elseif(IsInRaid()) then
        ClassicRaidAssistFury:SendCommMessage(prefix, msg, "RAID")
    elseif(IsInGroup()) then
        ClassicRaidAssistFury:SendCommMessage(prefix, msg, "PARTY")
    end
end

function ClassicRaidAssistFury:ConsumableQuestion(spec, item)
    ClassicRaidAssistFury:SendMessage(spec .. "--" .. item, consumableQuestionItemPrefix)
end

function ClassicRaidAssistFury:QuestionBuffs(spec, buff)
    ClassicRaidAssistFury:SendMessage(spec .. "--" .. buff, consumableQuestionBuffPrefix)
end

function ClassicRaidAssistFury:OnConsumableQuestionItem(prefix, message, distribution, sender)
    if not ClassicRaidAssistFury.db.char.allowItemScanning then
        return
    end

    local tokens = splitString(message, "--")
    -- local tokens = string.gmatch(message, "[^--]+")
    local spec = tokens[1]
    local item = tokens[2]
    local specs = ConsumablesTab:getConsumables()
    if spec == ClassicRaidAssistFury.thisPlayerSpec or spec == "All Classes" then
        for key, value in pairs(specs[spec]['consumables']) do
            if(value['itemId'] == item) then
                -- check to see if this players spec and the item checking for is in the consumables list, protects against malicious
                local count = GetItemCount(item)
                if count == 0 and value['secondaryItemId'] ~= nil then
                    count = GetItemCount(value['secondaryItemId'])
                end
                ClassicRaidAssistFury:SendMessage(item .. "--" .. count .. "--" .. spec, consumableSendItemPrefix)
                return
            end
        end
    end
end

function ClassicRaidAssistFury:OnConsumableSendItem(prefix, message, distribution, sender)
    local specs = ConsumablesTab:getConsumables()
    local tokens = splitString(message, "--")
    local item = tokens[1]
    local count = tonumber(tokens[2])
    local currentSpec = tokens[3]

    if(specs[currentSpec] == nil) then
        return
    end

    if(specs[currentSpec]['currentItems'][sender] == nil) then
        specs[currentSpec]['currentItems'][sender] = {}
    end
    
    local to_add = "0"
    if(count > 0) then
        to_add = "1"
    end
    
    for key, value in pairs(specs[currentSpec]['consumables']) do
        if(value['itemId'] == item) then
            specs[currentSpec]['currentItems'][sender][key] = to_add
            break
        end
    end

    CRA_wait(1, function() 
        if(ClassicRaidAssistFury.db.char.currentTab == "consumables" and ClassicRaidAssistFuryGUI_Shown) then
            ClassicRaidAssistFury.db.char.consumablesContainer:ReleaseChildren()
            ConsumablesTab:DrawConsumables(ClassicRaidAssistFury.db.char.consumablesContainer)
        end
    end, "consumables")
    
    CRA_wait(1, function()
        if(ClassicRaidAssistFuryReadyCheck) then
            RaidBuffsTab:outputMissingDebuff(ClassicRaidAssistFury.db.char.CurrentReadyCheckOutputChannel)
            if not (ClassicRaidAssistFury.faction == "Horde") then
                PaladinBuffsTab:outputMissingDebuff(ClassicRaidAssistFury.db.char.CurrentReadyCheckOutputChannel)
            end
            ConsumablesTab:outputBuffs(ClassicRaidAssistFury.db.char.CurrentReadyCheckOutputChannel, "BUFF", "All Classes")
            ClassicRaidAssistFuryReadyCheck = false
        end
    end, "readyCheck")
end

function ClassicRaidAssistFury:OnConsumableQuestionBuff(prefix, message, distribution, sender)
    local tokens = splitString(message, "--")
    -- local tokens = string.gmatch(message, "[^--]+")
    local spec = tokens[1]
    local buff = tokens[2]
    local specs = ConsumablesTab:getConsumables()
    if spec == ClassicRaidAssistFury.thisPlayerSpec or spec == "All Classes" then
        for key, value in pairs(specs[spec]['consumables']) do
            if(value['buffId'] == buff) then
                -- check to see if this players spec and the item checking for is in the consumables list, protects against malicious
                local hasBuff, duration, expirationTime = CheckUnitForBuff("player", buff)
                if not hasBuff then
                    expirationTime = 0
                end
                if expirationTime == 0 and value['secondaryBuffId'] ~= nil then
                    hasBuff, duration, expirationTime = CheckUnitForBuff("player", value['secondaryBuffId'])
                    if not hasBuff then
                        expirationTime = 0
                    end
                end
                ClassicRaidAssistFury:SendMessage(buff .. "--" .. expirationTime .. "--" .. spec, consumableSendBuffPrefix)
                return
            end
        end
    end
end

function ClassicRaidAssistFury:OnConsumableSendBuff(prefix, message, distribution, sender)
    local specs = ConsumablesTab:getConsumables()
    local tokens = splitString(message, "--")
    local buff = tokens[1]
    local expirationTime = tonumber(tokens[2])
    local currentSpec = tokens[3]

    if(specs[currentSpec] == nil) then
        return
    end

    if(specs[currentSpec]['currentBuffs'][sender] == nil) then
        specs[currentSpec]['currentBuffs'][sender] = {}
    end

    local to_add = "0"
    if(expirationTime > 0) then
        to_add = "1"
    end
    
    for key, value in pairs(specs[currentSpec]['consumables']) do
        if(value['buffId'] == buff) then
            specs[currentSpec]['currentBuffs'][sender][key] = to_add
            break
        end
    end
        
    CRA_wait(1, function() 
        if(ClassicRaidAssistFury.db.char.currentTab == "consumables" and ClassicRaidAssistFuryGUI_Shown) then
            ClassicRaidAssistFury.db.char.consumablesContainer:ReleaseChildren()
            ConsumablesTab:DrawConsumables(ClassicRaidAssistFury.db.char.consumablesContainer)
        end
    end, "consumables")

    CRA_wait(1, function()
        if(ClassicRaidAssistFuryReadyCheck) then
            RaidBuffsTab:outputMissingDebuff(ClassicRaidAssistFury.db.char.CurrentReadyCheckOutputChannel)
            if not (ClassicRaidAssistFury.faction == "Horde") then
                PaladinBuffsTab:outputMissingDebuff(ClassicRaidAssistFury.db.char.CurrentReadyCheckOutputChannel)
            end
            ConsumablesTab:outputBuffs(ClassicRaidAssistFury.db.char.CurrentReadyCheckOutputChannel, "BUFF", "All Classes")
            ClassicRaidAssistFuryReadyCheck = false
        end
    end, "readyCheck")
end

function ClassicRaidAssistFury:DetermineLooter(guid)
    canLoot, inRange = CanLootUnit(guid)
    if canLoot then
        local localizedClass, englishClass, classIndex = UnitClass("player")
        ClassicRaidAssistFury:SendMessage(guid, announcePrefix)
        return name, englishClass, false
    else
        ClassicRaidAssistFury:SendMessage(guid, questionPrefix)
        return _, _, true
    end
end

function ClassicRaidAssistFury:ScanForItem(message)
    ClassicRaidAssistFury:SendMessage(message, questionItemPrefix)
end

function ClassicRaidAssistFury:OnQuestionItem(prefix, message, distribution, sender)
    if not ClassicRaidAssistFury.db.char.allowItemScanning then
        return
    end

    for key, value in pairs(RaidItemsTab.raidItems) do
        if (key == message) then
            for k, v in pairs(value['itemIds']) do
                count  = GetItemCount(v)
                if count > 0 then
                    ClassicRaidAssistFury:SendMessage(message, sendItemPrefix)
                    return
                end
            end
            ClassicRaidAssistFury:SendMessage(message, sendBadItemPrefix)
            return
        end
    end
end

function ClassicRaidAssistFury:OnSendItem(prefix, message, distribution, sender)
    for key, value in pairs(RaidItemsTab.raidItems) do
        if(key == message) then
            value['hasThisItem'][sender] = true
            CRA_wait(1, function() 
                if(ClassicRaidAssistFury.db.char.currentTab == "raidItems") then
                    ClassicRaidAssistFury.db.char.raidItemsContainer:ReleaseChildren() 
                    RaidItemsTab:DrawRaidItems(ClassicRaidAssistFury.db.char.raidItemsContainer) 
                end
            end, "RaidItems")
            break
        end
    end
end

function ClassicRaidAssistFury:OnSendBadItem(prefix, message, distribution, sender)
    for key, value in pairs(RaidItemsTab.raidItems) do
        if(key == message) then
            value['hasThisItem'][sender] = false
            CRA_wait(1, function() 
                if(ClassicRaidAssistFury.db.char.currentTab == "raidItems") then
                    ClassicRaidAssistFury.db.char.raidItemsContainer:ReleaseChildren() 
                    RaidItemsTab:DrawRaidItems(ClassicRaidAssistFury.db.char.raidItemsContainer) 
                end
            end, "RaidItems")
            break
        end
    end
end

function ClassicRaidAssistFury:OnQuestion(prefix, message, distribution, sender)
    canLoot, inRange = CanLootUnit(message)
    if canLoot then
        local localizedClass, englishClass, classIndex = UnitClass("player")
        ClassicRaidAssistFury:SendMessage(message, announcePrefix)
        ClassicRaidAssistFury:AddToUnits(message, name, englishClass)
    end
end

function ClassicRaidAssistFury:OnAnnounce(prefix, message, distribution, sender)
    local localizedClass, englishClass, classIndex = UnitClass(sender)
    ClassicRaidAssistFury:AddToUnits(message, sender, englishClass)
    
    -- drawGameToolTip()
end

function ClassicRaidAssistFury:OnScanSend(prefix, message, distribution, sender)
    -- if(sender ~= name) then
    ClassicRaidAssistFury:SendMessage(version, scanRecievePrefix)
    -- end
end

function ClassicRaidAssistFury:OnScanRecieve(prefix, message, distribution, sender)
    self.raid[sender] = message
    
    CRA_wait(1, function() 
        if(ClassicRaidAssistFury.db.char.currentTab == "settings") then
            ClassicRaidAssistFury.db.char.settingsContainer:ReleaseChildren()
            ClassicRaidAssistFuryGUI:DrawSettings(ClassicRaidAssistFury.db.char.settingsContainer)
        end
    end, "settings")
end

function ClassicRaidAssistFury:AddToUnits(guid, looter, class)
    if(list_of_units[curr_unit_pointer] ~= nil)  then
        ClassicRaidAssistFury.unit[list_of_units[curr_unit_pointer]] = nil
    end
    
    ClassicRaidAssistFury.unit[guid] = {
        ["looter"] = looter,
        ["unitClassColor"] = RAID_CLASS_COLORS[class].colorStr
    }
    list_of_units[curr_unit_pointer] = guid
    curr_unit_pointer = curr_unit_pointer + 1
    if(curr_unit_pointer > MAX_NUMBER_OF_UNITS) then
        curr_unit_pointer = 1
    end
end

function ClassicRaidAssistFury:SetUpMouseEvent()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    frame:SetScript("OnEvent", function(self)
        drawGameToolTip()
    end)
end

function drawGameToolTip()
    if(IsInRaid() or IsInGroup()) then
        local name = UnitName("mouseover")
        local guid = UnitGUID("mouseover")
        local friend = UnitIsFriend("mouseover", "player")
        local dead = UnitIsDead("mouseover")
        local creatureType = UnitCreatureType("mouseover")
        local tapped = UnitIsTapDenied("mouseover")
        
        if name == nil or friend or not dead or creatureType == "Critter" or tapped then return end
        
        if ClassicRaidAssistFury.unit[guid] == nil then
            playerName, playerClass, not_found = ClassicRaidAssistFury:DetermineLooter(guid)
        
            if not not_found then
                ClassicRaidAssistFury:AddToUnits(guid, playerName, playerClass)
            end
        end
        
        if ClassicRaidAssistFury.unit[guid] == nil then
            GameTooltip:AddLine("Looter: |cababababUnknown|r", 1, 1, 1)
            GameTooltip:Show()
        else
            -- GameTooltipTextLeft3:SetText("Looter: |c" .. ClassicRaidAssistFury.unit[guid].unitClassColor .. ClassicRaidAssistFury.unit[guid].looter .. "|r", 1, 1, 1)
            GameTooltip:AddLine("Looter: |c" .. ClassicRaidAssistFury.unit[guid].unitClassColor .. ClassicRaidAssistFury.unit[guid].looter .. "|r", 1, 1, 1)
            GameTooltip:Show()
        end
    end
end

function ClassicRaidAssistFury:SetUpMinimapIcon()
	LibStub("LibDBIcon-1.0"):Register("ClassicRaidAssistFury", LibStub("LibDataBroker-1.1"):NewDataObject("ClassicRaidAssistFury",
	{
		type = "data source",
		text = "Classic Raid Assist Fury",
		icon = "Interface\\Icons\\ability_creature_disease_02",
		OnClick = function(self, button) 
			if (button == "LeftButton") then
				ClassicRaidAssistFuryGUI:Toggle()
            end
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddDoubleLine(format("%s", "Classic Raid Assist Fury"), format("|cff777777v%s", GetAddOnMetadata("ClassicRaidAssistFury", "Version")));
			tooltip:AddLine("|cFFCFCFCFLeft Click: |rShow GUI");
		end
	}), self.db.factionrealm.minimapButton);
end

function ClassicRaidAssistFury:ReadyCheckOutput()
    if not ClassicRaidAssistFury.db.char.readyCheckOutput then
        return
    end

    if(UnitIsRaidOfficer("player") or UnitIsGroupLeader("player")) then
        RaidBuffsTab:ScanRaidBuffs()
        PaladinBuffsTab:ScanPaladinBuffs()
        ConsumablesTab:ScanConsumables("BUFF", "All Classes")

        _G["ClassicRaidAssistFuryReadyCheck"] = true

        CRA_wait(1, function()
            if(ClassicRaidAssistFuryReadyCheck) then
                RaidBuffsTab:outputMissingDebuff(ClassicRaidAssistFury.db.char.CurrentReadyCheckOutputChannel)
                if not (ClassicRaidAssistFury.faction == "Horde") then
                    PaladinBuffsTab:outputMissingDebuff(ClassicRaidAssistFury.db.char.CurrentReadyCheckOutputChannel)
                end
                ConsumablesTab:outputBuffs(ClassicRaidAssistFury.db.char.CurrentReadyCheckOutputChannel, "BUFF", "All Classes")
                ClassicRaidAssistFuryReadyCheck = false
            end
        end, "readyCheck")
    end
end