-- Clean Unit Frames for WoW 3.3.5 (WotLK)
-- Modern, clean player and target frames

local addonName = "CleanUnitFrames"
local CUF = CreateFrame("Frame", "CleanUnitFrames")

-- Default settings
local defaults = {
    playerX = -300,
    playerY = -150,
    targetX = 300,
    targetY = -150,
    width = 220,
    height = 45,
    scale = 1.0,
    hideBlizzard = true,
    showPercent = true,
    showValues = true,
    classColors = true,
    locked = true,
    showPortrait = true,
    showCastBar = true,
    bigDamageAlert = true,
    damageThreshold = 20,
}

-- Class colors
local ClassColors = {
    WARRIOR = { 0.78, 0.61, 0.43 },
    PALADIN = { 0.96, 0.55, 0.73 },
    HUNTER = { 0.67, 0.83, 0.45 },
    ROGUE = { 1.0, 0.96, 0.41 },
    PRIEST = { 1.0, 1.0, 1.0 },
    DEATHKNIGHT = { 0.77, 0.12, 0.23 },
    SHAMAN = { 0.0, 0.44, 0.87 },
    MAGE = { 0.41, 0.8, 0.94 },
    WARLOCK = { 0.58, 0.51, 0.79 },
    DRUID = { 1.0, 0.49, 0.04 },
}

-- Power colors
local PowerColors = {
    [0] = { 0.0, 0.4, 1.0 },      -- Mana (blue)
    [1] = { 1.0, 0.0, 0.0 },      -- Rage (red)
    [2] = { 1.0, 0.5, 0.25 },     -- Focus (orange)
    [3] = { 1.0, 1.0, 0.0 },      -- Energy (yellow)
    [4] = { 0.0, 1.0, 1.0 },      -- Happiness (cyan)
    [5] = { 0.5, 0.5, 0.5 },      -- Runes (grey)
    [6] = { 0.0, 0.82, 1.0 },     -- Runic Power (light blue)
}

-- Store previous health for damage flash
local previousHealth = {}

-- Create a unit frame
local function CreateUnitFrame(unit, name)
    local db = CleanUnitFramesDB or defaults
    local width = db.width or 220
    local height = db.height or 45
    
    local frame = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate")
    frame:SetWidth(width)
    frame:SetHeight(height + 30) -- Extra space for mana bar
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForClicks("AnyUp")
    frame:SetAttribute("unit", unit)
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("type2", "menu")
    frame.unit = unit
    
    -- Main background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetTexture(0, 0, 0, 0.8)
    
    -- Portrait (left side)
    frame.portrait = frame:CreateTexture(nil, "ARTWORK")
    frame.portrait:SetWidth(height + 25)
    frame.portrait:SetHeight(height + 25)
    frame.portrait:SetPoint("LEFT", frame, "LEFT", 3, 5)
    
    -- Portrait border
    frame.portraitBorder = frame:CreateTexture(nil, "OVERLAY")
    frame.portraitBorder:SetPoint("TOPLEFT", frame.portrait, "TOPLEFT", -3, 3)
    frame.portraitBorder:SetPoint("BOTTOMRIGHT", frame.portrait, "BOTTOMRIGHT", 3, -3)
    frame.portraitBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    frame.portraitBorder:SetBlendMode("ADD")
    frame.portraitBorder:SetVertexColor(0.8, 0.8, 0.8)
    
    local barOffset = height + 30
    
    -- Health bar background
    frame.healthBg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    frame.healthBg:SetPoint("TOPLEFT", frame, "TOPLEFT", barOffset, -3)
    frame.healthBg:SetPoint("RIGHT", frame, "RIGHT", -3, 0)
    frame.healthBg:SetHeight(height - 6)
    frame.healthBg:SetTexture(0.15, 0.15, 0.15, 1)
    
    -- Health bar
    frame.health = frame:CreateTexture(nil, "ARTWORK")
    frame.health:SetPoint("TOPLEFT", frame.healthBg, "TOPLEFT", 0, 0)
    frame.health:SetHeight(height - 6)
    frame.health:SetTexture(0.2, 0.9, 0.2, 1)
    
    -- Health flash overlay (for damage taken)
    frame.healthFlash = frame:CreateTexture(nil, "OVERLAY")
    frame.healthFlash:SetAllPoints(frame.healthBg)
    frame.healthFlash:SetTexture(1, 0, 0, 0)
    frame.healthFlash:SetBlendMode("ADD")
    
    -- Mana bar background
    frame.manaBg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    frame.manaBg:SetPoint("TOPLEFT", frame.healthBg, "BOTTOMLEFT", 0, -2)
    frame.manaBg:SetPoint("RIGHT", frame, "RIGHT", -3, 0)
    frame.manaBg:SetHeight(18)
    frame.manaBg:SetTexture(0.1, 0.1, 0.1, 1)
    
    -- Mana bar
    frame.mana = frame:CreateTexture(nil, "ARTWORK")
    frame.mana:SetPoint("TOPLEFT", frame.manaBg, "TOPLEFT", 0, 0)
    frame.mana:SetHeight(18)
    frame.mana:SetTexture(0.0, 0.4, 1.0, 1)
    
    -- Name text
    frame.name = frame:CreateFontString(nil, "OVERLAY")
    frame.name:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    frame.name:SetPoint("TOP", frame.portrait, "BOTTOM", 0, -2)
    frame.name:SetTextColor(1, 1, 1)
    frame.name:SetWidth(height + 25)
    frame.name:SetJustifyH("CENTER")
    
    -- Level text
    frame.level = frame:CreateFontString(nil, "OVERLAY")
    frame.level:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    frame.level:SetPoint("BOTTOMLEFT", frame.portrait, "BOTTOMLEFT", 0, 0)
    frame.level:SetTextColor(1, 0.82, 0)
    
    -- Health text (percentage - BIG)
    frame.healthPercent = frame:CreateFontString(nil, "OVERLAY")
    frame.healthPercent:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    frame.healthPercent:SetPoint("LEFT", frame.healthBg, "LEFT", 8, 0)
    frame.healthPercent:SetTextColor(1, 1, 1)
    
    -- Health text (values)
    frame.healthValue = frame:CreateFontString(nil, "OVERLAY")
    frame.healthValue:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    frame.healthValue:SetPoint("RIGHT", frame.healthBg, "RIGHT", -5, 0)
    frame.healthValue:SetTextColor(0.9, 0.9, 0.9)
    
    -- Mana text (percentage)
    frame.manaPercent = frame:CreateFontString(nil, "OVERLAY")
    frame.manaPercent:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    frame.manaPercent:SetPoint("LEFT", frame.manaBg, "LEFT", 5, 0)
    frame.manaPercent:SetTextColor(1, 1, 1)
    
    -- Mana text (values)
    frame.manaValue = frame:CreateFontString(nil, "OVERLAY")
    frame.manaValue:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    frame.manaValue:SetPoint("RIGHT", frame.manaBg, "RIGHT", -5, 0)
    frame.manaValue:SetTextColor(0.8, 0.8, 0.8)
    
    -- Damage taken text (flashes when you take big damage)
    frame.damageText = frame:CreateFontString(nil, "OVERLAY")
    frame.damageText:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
    frame.damageText:SetPoint("CENTER", frame.healthBg, "CENTER", 0, 0)
    frame.damageText:SetTextColor(1, 0, 0)
    frame.damageText:SetText("")
    
    -- Elite/Boss indicator
    frame.elite = frame:CreateFontString(nil, "OVERLAY")
    frame.elite:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    frame.elite:SetPoint("TOPRIGHT", frame.portrait, "TOPRIGHT", 2, 2)
    frame.elite:SetTextColor(1, 0.84, 0)
    
    -- PvP flag
    frame.pvp = frame:CreateFontString(nil, "OVERLAY")
    frame.pvp:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    frame.pvp:SetPoint("TOPLEFT", frame.portrait, "TOPLEFT", -2, 2)
    frame.pvp:SetTextColor(0, 1, 0)
    
    -- Unlock mode background
    frame.unlockBg = frame:CreateTexture(nil, "OVERLAY")
    frame.unlockBg:SetAllPoints()
    frame.unlockBg:SetTexture(0.2, 0.5, 0.8, 0.5)
    frame.unlockBg:Hide()
    
    frame.unlockText = frame:CreateFontString(nil, "OVERLAY")
    frame.unlockText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    frame.unlockText:SetPoint("CENTER")
    frame.unlockText:SetText(unit == "player" and "PLAYER\nDrag to move" or "TARGET\nDrag to move")
    frame.unlockText:Hide()
    
    -- Animation variables
    frame.flashAlpha = 0
    frame.damageTime = 0
    
    return frame
end

-- Format large numbers (1000 -> 1k, 1000000 -> 1m)
local function FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fm", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fk", num / 1000)
    else
        return tostring(num)
    end
end

-- Update unit frame
local function UpdateFrame(frame)
    local unit = frame.unit
    if not UnitExists(unit) then
        if unit == "target" then
            frame:Hide()
        end
        return
    end
    
    frame:Show()
    local db = CleanUnitFramesDB or defaults
    
    -- Name
    local name = UnitName(unit)
    if name and string.len(name) > 12 then
        name = string.sub(name, 1, 11) .. ".."
    end
    frame.name:SetText(name or "")
    
    -- Level
    local level = UnitLevel(unit)
    if level == -1 then
        frame.level:SetText("??")
        frame.level:SetTextColor(1, 0, 0)
    else
        frame.level:SetText(level)
        local color = GetQuestDifficultyColor(level)
        frame.level:SetTextColor(color.r, color.g, color.b)
    end
    
    -- Portrait
    SetPortraitTexture(frame.portrait, unit)
    
    -- Class color for health bar
    local _, class = UnitClass(unit)
    local healthColor = { 0.2, 0.9, 0.2 }
    if db.classColors and class and ClassColors[class] then
        healthColor = ClassColors[class]
    end
    
    -- If enemy, use red-ish health bar based on reaction
    if UnitIsEnemy("player", unit) then
        healthColor = { 0.9, 0.2, 0.2 }
    elseif not UnitIsFriend("player", unit) and unit ~= "player" then
        healthColor = { 1.0, 0.8, 0.0 }
    end
    
    -- Health
    local health = UnitHealth(unit)
    local healthMax = UnitHealthMax(unit)
    local healthPercent = 0
    if healthMax > 0 then
        healthPercent = (health / healthMax) * 100
    end
    
    -- Health bar width
    local barWidth = frame.healthBg:GetWidth() * (healthPercent / 100)
    if barWidth < 1 then barWidth = 1 end
    frame.health:SetWidth(barWidth)
    
    -- Health color (green -> yellow -> red based on %)
    if healthPercent > 50 then
        frame.health:SetTexture(healthColor[1], healthColor[2], healthColor[3], 1)
    elseif healthPercent > 25 then
        frame.health:SetTexture(1, 1, 0, 1) -- Yellow
    else
        frame.health:SetTexture(1, 0.2, 0.2, 1) -- Red
    end
    
    -- Health text
    if db.showPercent ~= false then
        frame.healthPercent:SetText(string.format("%.0f%%", healthPercent))
        -- Color based on health
        if healthPercent > 50 then
            frame.healthPercent:SetTextColor(1, 1, 1)
        elseif healthPercent > 25 then
            frame.healthPercent:SetTextColor(1, 1, 0)
        else
            frame.healthPercent:SetTextColor(1, 0.3, 0.3)
        end
    else
        frame.healthPercent:SetText("")
    end
    
    if db.showValues ~= false then
        frame.healthValue:SetText(FormatNumber(health) .. " / " .. FormatNumber(healthMax))
    else
        frame.healthValue:SetText("")
    end
    
    -- Power (Mana/Rage/Energy)
    local power = UnitPower(unit)
    local powerMax = UnitPowerMax(unit)
    local powerType = UnitPowerType(unit)
    local powerPercent = 0
    if powerMax > 0 then
        powerPercent = (power / powerMax) * 100
    end
    
    -- Power bar width
    local manaWidth = frame.manaBg:GetWidth() * (powerPercent / 100)
    if manaWidth < 1 then manaWidth = 1 end
    frame.mana:SetWidth(manaWidth)
    
    -- Power color
    local powerColor = PowerColors[powerType] or { 0.5, 0.5, 0.5 }
    frame.mana:SetTexture(powerColor[1], powerColor[2], powerColor[3], 1)
    
    -- Power text
    frame.manaPercent:SetText(string.format("%.0f%%", powerPercent))
    if db.showValues ~= false then
        frame.manaValue:SetText(FormatNumber(power) .. " / " .. FormatNumber(powerMax))
    else
        frame.manaValue:SetText("")
    end
    
    -- Elite/Boss dragon
    local classification = UnitClassification(unit)
    if classification == "worldboss" or classification == "boss" then
        frame.elite:SetText("BOSS")
        frame.elite:SetTextColor(1, 0.5, 0)
    elseif classification == "rareelite" then
        frame.elite:SetText("R+")
        frame.elite:SetTextColor(0.7, 0.7, 1)
    elseif classification == "elite" then
        frame.elite:SetText("+")
        frame.elite:SetTextColor(1, 0.84, 0)
    elseif classification == "rare" then
        frame.elite:SetText("R")
        frame.elite:SetTextColor(0.7, 0.7, 1)
    else
        frame.elite:SetText("")
    end
    
    -- PvP flag
    if UnitIsPVP(unit) then
        if UnitFactionGroup(unit) == "Horde" then
            frame.pvp:SetText("H")
            frame.pvp:SetTextColor(1, 0.2, 0.2)
        else
            frame.pvp:SetText("A")
            frame.pvp:SetTextColor(0.2, 0.4, 1)
        end
    else
        frame.pvp:SetText("")
    end
    
    -- Portrait border color based on class
    if class and ClassColors[class] then
        frame.portraitBorder:SetVertexColor(ClassColors[class][1], ClassColors[class][2], ClassColors[class][3])
    else
        frame.portraitBorder:SetVertexColor(0.8, 0.8, 0.8)
    end
    
    -- Check for big damage taken (player only)
    if unit == "player" and db.bigDamageAlert ~= false then
        local prevHealth = previousHealth[unit] or health
        local damageTaken = prevHealth - health
        local damagePercent = 0
        if healthMax > 0 then
            damagePercent = (damageTaken / healthMax) * 100
        end
        
        if damagePercent >= (db.damageThreshold or 20) then
            -- Show damage number and flash
            frame.damageText:SetText("-" .. FormatNumber(damageTaken))
            frame.damageTime = GetTime()
            frame.flashAlpha = 0.7
            frame.healthFlash:SetTexture(1, 0, 0, 0.7)
        end
        
        previousHealth[unit] = health
    end
end

-- Animation update
local function OnUpdate(self, elapsed)
    -- Update damage flash animation for player frame
    if PlayerFrame and PlayerFrame.flashAlpha then
        if PlayerFrame.flashAlpha > 0 then
            PlayerFrame.flashAlpha = PlayerFrame.flashAlpha - elapsed * 2
            if PlayerFrame.flashAlpha < 0 then PlayerFrame.flashAlpha = 0 end
            PlayerFrame.healthFlash:SetTexture(1, 0, 0, PlayerFrame.flashAlpha)
        end
        
        -- Fade out damage text
        if PlayerFrame.damageTime and GetTime() - PlayerFrame.damageTime > 1.5 then
            PlayerFrame.damageText:SetText("")
        end
    end
    
    -- Same for target
    if TargetFrame and TargetFrame.flashAlpha then
        if TargetFrame.flashAlpha > 0 then
            TargetFrame.flashAlpha = TargetFrame.flashAlpha - elapsed * 2
            if TargetFrame.flashAlpha < 0 then TargetFrame.flashAlpha = 0 end
            TargetFrame.healthFlash:SetTexture(1, 0, 0, TargetFrame.flashAlpha)
        end
    end
end

-- Hide default Blizzard frames
local function HideBlizzardFrames()
    local db = CleanUnitFramesDB or defaults
    if db.hideBlizzard == false then return end
    
    -- Player frame
    if _G["PlayerFrame"] then
        _G["PlayerFrame"]:UnregisterAllEvents()
        _G["PlayerFrame"]:Hide()
    end
    
    -- Target frame
    if _G["TargetFrame"] then
        _G["TargetFrame"]:UnregisterAllEvents()
        _G["TargetFrame"]:Hide()
    end
    
    -- Target of Target
    if _G["TargetFrameToT"] then
        _G["TargetFrameToT"]:UnregisterAllEvents()
        _G["TargetFrameToT"]:Hide()
    end
end

-- Create frames
local CUF_PlayerFrame
local CUF_TargetFrame

local function InitFrames()
    local db = CleanUnitFramesDB or defaults
    
    -- Create Player Frame
    CUF_PlayerFrame = CreateUnitFrame("player", "CUF_PlayerFrame")
    CUF_PlayerFrame:SetPoint("CENTER", UIParent, "CENTER", db.playerX or -300, db.playerY or -150)
    CUF_PlayerFrame:Show()
    PlayerFrame = CUF_PlayerFrame -- Store reference for OnUpdate
    
    -- Create Target Frame
    CUF_TargetFrame = CreateUnitFrame("target", "CUF_TargetFrame")
    CUF_TargetFrame:SetPoint("CENTER", UIParent, "CENTER", db.targetX or 300, db.targetY or -150)
    CUF_TargetFrame:Hide() -- Hidden until target selected
    TargetFrame = CUF_TargetFrame
    
    HideBlizzardFrames()
end

-- Event handler
CUF:RegisterEvent("ADDON_LOADED")
CUF:RegisterEvent("PLAYER_ENTERING_WORLD")
CUF:RegisterEvent("UNIT_HEALTH")
CUF:RegisterEvent("UNIT_MAXHEALTH")
CUF:RegisterEvent("UNIT_POWER")
CUF:RegisterEvent("UNIT_MAXPOWER")
CUF:RegisterEvent("UNIT_DISPLAYPOWER")
CUF:RegisterEvent("PLAYER_TARGET_CHANGED")
CUF:RegisterEvent("UNIT_PORTRAIT_UPDATE")
CUF:RegisterEvent("UNIT_LEVEL")
CUF:RegisterEvent("UNIT_FACTION")
CUF:RegisterEvent("UNIT_AURA")

CUF:SetScript("OnUpdate", OnUpdate)

CUF:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            if not CleanUnitFramesDB then
                CleanUnitFramesDB = {}
                for k, v in pairs(defaults) do
                    CleanUnitFramesDB[k] = v
                end
            end
            
            InitFrames()
            print("|cff00ff00[Clean Unit Frames]|r Loaded! Type /cuf for options.")
        end
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        HideBlizzardFrames()
        if CUF_PlayerFrame then
            previousHealth["player"] = UnitHealth("player")
            UpdateFrame(CUF_PlayerFrame)
        end
        if CUF_TargetFrame and UnitExists("target") then
            UpdateFrame(CUF_TargetFrame)
        end
        
    elseif event == "PLAYER_TARGET_CHANGED" then
        if CUF_TargetFrame then
            if UnitExists("target") then
                UpdateFrame(CUF_TargetFrame)
                CUF_TargetFrame:Show()
            else
                CUF_TargetFrame:Hide()
            end
        end
        
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or 
           event == "UNIT_POWER" or event == "UNIT_MAXPOWER" or
           event == "UNIT_DISPLAYPOWER" or event == "UNIT_PORTRAIT_UPDATE" or
           event == "UNIT_LEVEL" or event == "UNIT_FACTION" or event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" and CUF_PlayerFrame then
            UpdateFrame(CUF_PlayerFrame)
        elseif unit == "target" and CUF_TargetFrame then
            UpdateFrame(CUF_TargetFrame)
        end
    end
end)

-- Toggle lock mode
local function ToggleLock(lock)
    local db = CleanUnitFramesDB or defaults
    db.locked = lock
    
    if lock then
        -- Lock frames
        CUF_PlayerFrame:EnableMouse(true)
        CUF_PlayerFrame.unlockBg:Hide()
        CUF_PlayerFrame.unlockText:Hide()
        CUF_PlayerFrame:SetScript("OnDragStart", nil)
        CUF_PlayerFrame:SetScript("OnDragStop", nil)
        
        CUF_TargetFrame:EnableMouse(true)
        CUF_TargetFrame.unlockBg:Hide()
        CUF_TargetFrame.unlockText:Hide()
        CUF_TargetFrame:SetScript("OnDragStart", nil)
        CUF_TargetFrame:SetScript("OnDragStop", nil)
        
        print("|cff00ff00[CUF]|r Frames locked.")
    else
        -- Unlock frames
        CUF_PlayerFrame:EnableMouse(true)
        CUF_PlayerFrame:RegisterForDrag("LeftButton")
        CUF_PlayerFrame.unlockBg:Show()
        CUF_PlayerFrame.unlockText:Show()
        CUF_PlayerFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        CUF_PlayerFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local _, _, _, x, y = self:GetPoint()
            CleanUnitFramesDB.playerX = x
            CleanUnitFramesDB.playerY = y
        end)
        
        CUF_TargetFrame:Show()
        CUF_TargetFrame:EnableMouse(true)
        CUF_TargetFrame:RegisterForDrag("LeftButton")
        CUF_TargetFrame.unlockBg:Show()
        CUF_TargetFrame.unlockText:Show()
        CUF_TargetFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        CUF_TargetFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local _, _, _, x, y = self:GetPoint()
            CleanUnitFramesDB.targetX = x
            CleanUnitFramesDB.targetY = y
        end)
        
        print("|cff00ff00[CUF]|r Frames unlocked. Drag to move, then /cuf lock.")
    end
end

-- Slash commands
SLASH_CUF1 = "/cuf"
SLASH_CUF2 = "/cleanframes"
SlashCmdList["CUF"] = function(msg)
    local cmd = string.lower(msg or "")
    
    if cmd == "lock" then
        ToggleLock(true)
        
    elseif cmd == "unlock" then
        ToggleLock(false)
        
    elseif cmd == "reset" then
        CleanUnitFramesDB = {}
        for k, v in pairs(defaults) do
            CleanUnitFramesDB[k] = v
        end
        CUF_PlayerFrame:ClearAllPoints()
        CUF_PlayerFrame:SetPoint("CENTER", UIParent, "CENTER", defaults.playerX, defaults.playerY)
        CUF_TargetFrame:ClearAllPoints()
        CUF_TargetFrame:SetPoint("CENTER", UIParent, "CENTER", defaults.targetX, defaults.targetY)
        print("|cff00ff00[CUF]|r Settings reset.")
        
    elseif cmd == "blizzard" then
        CleanUnitFramesDB.hideBlizzard = not CleanUnitFramesDB.hideBlizzard
        print("|cff00ff00[CUF]|r Blizzard frames " .. (CleanUnitFramesDB.hideBlizzard and "hidden" or "shown") .. " (reload required)")
        
    elseif cmd == "classcolors" or cmd == "class" then
        CleanUnitFramesDB.classColors = not CleanUnitFramesDB.classColors
        print("|cff00ff00[CUF]|r Class colors " .. (CleanUnitFramesDB.classColors and "enabled" or "disabled"))
        UpdateFrame(CUF_PlayerFrame)
        if UnitExists("target") then UpdateFrame(CUF_TargetFrame) end
        
    elseif cmd == "percent" then
        CleanUnitFramesDB.showPercent = not CleanUnitFramesDB.showPercent
        print("|cff00ff00[CUF]|r Percent display " .. (CleanUnitFramesDB.showPercent and "enabled" or "disabled"))
        UpdateFrame(CUF_PlayerFrame)
        if UnitExists("target") then UpdateFrame(CUF_TargetFrame) end
        
    elseif cmd == "values" then
        CleanUnitFramesDB.showValues = not CleanUnitFramesDB.showValues
        print("|cff00ff00[CUF]|r Values display " .. (CleanUnitFramesDB.showValues and "enabled" or "disabled"))
        UpdateFrame(CUF_PlayerFrame)
        if UnitExists("target") then UpdateFrame(CUF_TargetFrame) end
        
    elseif cmd == "alert" then
        CleanUnitFramesDB.bigDamageAlert = not CleanUnitFramesDB.bigDamageAlert
        print("|cff00ff00[CUF]|r Big damage alert " .. (CleanUnitFramesDB.bigDamageAlert and "enabled" or "disabled"))
        
    elseif cmd:match("^threshold") then
        local val = tonumber(cmd:match("threshold%s*(%d+)"))
        if val and val >= 1 and val <= 100 then
            CleanUnitFramesDB.damageThreshold = val
            print("|cff00ff00[CUF]|r Damage alert threshold set to " .. val .. "%")
        else
            print("|cff00ff00[CUF]|r Usage: /cuf threshold <1-100>")
        end
        
    elseif cmd == "test" then
        -- Simulate damage taken flash
        if CUF_PlayerFrame then
            CUF_PlayerFrame.damageText:SetText("-12.5k")
            CUF_PlayerFrame.damageTime = GetTime()
            CUF_PlayerFrame.flashAlpha = 0.7
            CUF_PlayerFrame.healthFlash:SetTexture(1, 0, 0, 0.7)
            print("|cff00ff00[CUF]|r Simulated big damage hit!")
        end
        
    else
        print("|cff00ff00[Clean Unit Frames]|r Commands:")
        print("  /cuf unlock - Unlock frames to move")
        print("  /cuf lock - Lock frames")
        print("  /cuf classcolors - Toggle class color HP bars")
        print("  /cuf percent - Toggle HP/Mana percent")
        print("  /cuf values - Toggle HP/Mana values")
        print("  /cuf alert - Toggle big damage alert flash")
        print("  /cuf threshold <1-100> - Set damage alert % (default: 20)")
        print("  /cuf test - Test damage flash")
        print("  /cuf blizzard - Show/hide default frames (reload)")
        print("  /cuf reset - Reset to defaults")
    end
end
