-- Mage Shield Tracker for WoW 3.3.5 (WotLK)
-- Tracks Ice Barrier, Mana Shield and Fire Ward absorb remaining

local addonName = "MageShieldTracker"
local MST = CreateFrame("Frame", "MageShieldTracker")

-- Default settings
local defaults = {
    iconSize = 48,
    spacing = 5,
    showPercent = true,
    showAmount = true,
    lowThreshold = 20,
    warnSound = true,
    locked = false,
    xOffset = 0,
    yOffset = -200,
    hideWhenEmpty = true,
    vertical = false,
}

-- Shield spell IDs and max absorb values for WoW 3.3.5
-- Ice Barrier ranks (Frost talent)
local IceBarrierSpells = {
    [11426] = 438,   -- Rank 1
    [13031] = 549,   -- Rank 2
    [13032] = 678,   -- Rank 3
    [13033] = 818,   -- Rank 4
    [27134] = 925,   -- Rank 5
    [33405] = 1075,  -- Rank 6
    [43038] = 2780,  -- Rank 7 (Level 75)
    [43039] = 3300,  -- Rank 8 (Level 80)
}

-- Mana Shield ranks
local ManaShieldSpells = {
    [1463]  = 120,   -- Rank 1
    [8494]  = 210,   -- Rank 2
    [8495]  = 300,   -- Rank 3
    [10191] = 390,   -- Rank 4
    [10192] = 480,   -- Rank 5
    [10193] = 570,   -- Rank 6
    [27131] = 715,   -- Rank 7
    [43019] = 1080,  -- Rank 8 (Level 79)
    [43020] = 1330,  -- Rank 9 (Level 80)
}

-- Fire Ward ranks
local FireWardSpells = {
    [543]   = 165,   -- Rank 1
    [8457]  = 290,   -- Rank 2
    [8458]  = 470,   -- Rank 3
    [10223] = 675,   -- Rank 4
    [10225] = 875,   -- Rank 5
    [27128] = 1125,  -- Rank 6
    [43010] = 1950,  -- Rank 7 (Level 80)
}

-- Frost Ward ranks
local FrostWardSpells = {
    [6143]  = 165,   -- Rank 1
    [8461]  = 290,   -- Rank 2
    [8462]  = 470,   -- Rank 3
    [10177] = 675,   -- Rank 4
    [28609] = 875,   -- Rank 5
    [32796] = 1125,  -- Rank 6
    [43012] = 1950,  -- Rank 7 (Level 80)
}

-- Combined lookup table
local ShieldSpells = {}
local ShieldTypes = {}

for id, val in pairs(IceBarrierSpells) do 
    ShieldSpells[id] = val 
    ShieldTypes[id] = "Ice Barrier"
end
for id, val in pairs(ManaShieldSpells) do 
    ShieldSpells[id] = val 
    ShieldTypes[id] = "Mana Shield"
end
for id, val in pairs(FireWardSpells) do 
    ShieldSpells[id] = val 
    ShieldTypes[id] = "Fire Ward"
end
for id, val in pairs(FrostWardSpells) do 
    ShieldSpells[id] = val 
    ShieldTypes[id] = "Frost Ward"
end

-- Active shields tracking
local ActiveShields = {}

-- Shield display frames
local ShieldFrames = {}

-- Main anchor frame
local AnchorFrame = CreateFrame("Frame", "MST_Anchor", UIParent)
AnchorFrame:SetWidth(200)
AnchorFrame:SetHeight(60)
AnchorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
AnchorFrame:SetMovable(true)
AnchorFrame:EnableMouse(false)
AnchorFrame:SetClampedToScreen(true)

-- Background for unlock mode
AnchorFrame.bg = AnchorFrame:CreateTexture(nil, "BACKGROUND")
AnchorFrame.bg:SetAllPoints()
AnchorFrame.bg:SetTexture(0, 0, 0, 0.5)
AnchorFrame.bg:Hide()

AnchorFrame.text = AnchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
AnchorFrame.text:SetPoint("CENTER")
AnchorFrame.text:SetText("Mage Shield Tracker\nDrag to move")
AnchorFrame.text:Hide()

-- Shield colors
local ShieldColors = {
    ["Ice Barrier"] = { 0.4, 0.8, 1.0 },      -- Light blue
    ["Mana Shield"] = { 0.4, 0.4, 1.0 },      -- Blue
    ["Fire Ward"] = { 1.0, 0.4, 0.2 },        -- Orange/Red
    ["Frost Ward"] = { 0.6, 0.9, 1.0 },       -- Cyan
}

-- Shield icons
local ShieldIcons = {
    ["Ice Barrier"] = "Interface\\Icons\\Spell_Ice_Lament",
    ["Mana Shield"] = "Interface\\Icons\\Spell_Shadow_DetectLesserInvisibility",
    ["Fire Ward"] = "Interface\\Icons\\Spell_Fire_FireArmor",
    ["Frost Ward"] = "Interface\\Icons\\Spell_Frost_FrostWard",
}

-- Create a shield display frame
local function CreateShieldFrame(shieldType)
    local frame = CreateFrame("Frame", nil, UIParent)
    local db = MageShieldTrackerDB or defaults
    local size = db.iconSize or defaults.iconSize
    
    frame:SetWidth(size + 80)
    frame:SetHeight(size)
    frame:SetFrameStrata("MEDIUM")
    
    -- Icon
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetWidth(size)
    frame.icon:SetHeight(size)
    frame.icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
    frame.icon:SetTexture(ShieldIcons[shieldType])
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    -- Icon border
    frame.border = frame:CreateTexture(nil, "OVERLAY")
    frame.border:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", -2, 2)
    frame.border:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 2, -2)
    frame.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    frame.border:SetBlendMode("ADD")
    local color = ShieldColors[shieldType] or {1, 1, 1}
    frame.border:SetVertexColor(color[1], color[2], color[3])
    
    -- Background bar
    frame.barBg = frame:CreateTexture(nil, "BACKGROUND")
    frame.barBg:SetWidth(70)
    frame.barBg:SetHeight(size - 8)
    frame.barBg:SetPoint("LEFT", frame.icon, "RIGHT", 4, 0)
    frame.barBg:SetTexture(0.1, 0.1, 0.1, 0.8)
    
    -- Absorb bar
    frame.bar = frame:CreateTexture(nil, "ARTWORK")
    frame.bar:SetWidth(70)
    frame.bar:SetHeight(size - 8)
    frame.bar:SetPoint("LEFT", frame.icon, "RIGHT", 4, 0)
    frame.bar:SetTexture(color[1], color[2], color[3], 0.8)
    
    -- Percent text
    frame.percent = frame:CreateFontString(nil, "OVERLAY")
    frame.percent:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    frame.percent:SetPoint("CENTER", frame.barBg, "CENTER", 0, 8)
    frame.percent:SetTextColor(1, 1, 1)
    
    -- Amount text
    frame.amount = frame:CreateFontString(nil, "OVERLAY")
    frame.amount:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    frame.amount:SetPoint("CENTER", frame.barBg, "CENTER", 0, -6)
    frame.amount:SetTextColor(0.8, 0.8, 0.8)
    
    -- Shield name
    frame.name = frame:CreateFontString(nil, "OVERLAY")
    frame.name:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    frame.name:SetPoint("BOTTOM", frame.icon, "TOP", 0, 2)
    frame.name:SetTextColor(color[1], color[2], color[3])
    frame.name:SetText(shieldType)
    
    frame.shieldType = shieldType
    frame.maxAbsorb = 0
    frame.currentAbsorb = 0
    frame:Hide()
    
    return frame
end

-- Get or create shield frame
local function GetShieldFrame(shieldType)
    if not ShieldFrames[shieldType] then
        ShieldFrames[shieldType] = CreateShieldFrame(shieldType)
    end
    return ShieldFrames[shieldType]
end

-- Update shield frame display
local function UpdateShieldFrame(frame)
    if not frame then return end
    
    local db = MageShieldTrackerDB or defaults
    local percent = 0
    
    if frame.maxAbsorb > 0 then
        percent = (frame.currentAbsorb / frame.maxAbsorb) * 100
    end
    
    -- Update bar width
    local barWidth = 70 * (percent / 100)
    if barWidth < 1 then barWidth = 1 end
    frame.bar:SetWidth(barWidth)
    
    -- Update colors based on threshold
    local color = ShieldColors[frame.shieldType] or {1, 1, 1}
    if percent <= (db.lowThreshold or 20) then
        -- Red/warning color when low
        frame.bar:SetTexture(1, 0.2, 0.2, 0.8)
        frame.percent:SetTextColor(1, 0.3, 0.3)
    elseif percent <= 50 then
        -- Yellow when medium
        frame.bar:SetTexture(1, 1, 0.2, 0.8)
        frame.percent:SetTextColor(1, 1, 0.3)
    else
        -- Normal color
        frame.bar:SetTexture(color[1], color[2], color[3], 0.8)
        frame.percent:SetTextColor(1, 1, 1)
    end
    
    -- Update text
    if db.showPercent ~= false then
        frame.percent:SetText(string.format("%.0f%%", percent))
    else
        frame.percent:SetText("")
    end
    
    if db.showAmount ~= false then
        frame.amount:SetText(string.format("%d / %d", frame.currentAbsorb, frame.maxAbsorb))
    else
        frame.amount:SetText("")
    end
end

-- Reposition all visible shield frames
local function RepositionFrames()
    local db = MageShieldTrackerDB or defaults
    local visibleFrames = {}
    
    for shieldType, frame in pairs(ShieldFrames) do
        if frame:IsShown() then
            table.insert(visibleFrames, frame)
        end
    end
    
    local spacing = db.spacing or 5
    local vertical = db.vertical
    
    for i, frame in ipairs(visibleFrames) do
        frame:ClearAllPoints()
        if vertical then
            frame:SetPoint("TOP", AnchorFrame, "TOP", 0, -((i-1) * (frame:GetHeight() + spacing)))
        else
            frame:SetPoint("LEFT", AnchorFrame, "LEFT", (i-1) * (frame:GetWidth() + spacing), 0)
        end
    end
end

-- Calculate absorb value with talents and stats
local function CalculateMaxAbsorb(spellID, baseAbsorb)
    local maxAbsorb = baseAbsorb
    
    -- Ice Barrier scales with spellpower
    if IceBarrierSpells[spellID] then
        local spellPower = GetSpellBonusDamage(4) -- Frost spell power
        -- Ice Barrier coefficient is approximately 0.8068
        maxAbsorb = baseAbsorb + (spellPower * 0.8068)
    end
    
    -- Mana Shield scales with spellpower (coefficient ~0.8053)
    if ManaShieldSpells[spellID] then
        local spellPower = GetSpellBonusDamage(7) -- Arcane spell power
        maxAbsorb = baseAbsorb + (spellPower * 0.8053)
    end
    
    -- Fire Ward scales with spellpower (coefficient ~0.8053)
    if FireWardSpells[spellID] then
        local spellPower = GetSpellBonusDamage(3) -- Fire spell power
        maxAbsorb = baseAbsorb + (spellPower * 0.8053)
    end
    
    -- Frost Ward scales with spellpower
    if FrostWardSpells[spellID] then
        local spellPower = GetSpellBonusDamage(4) -- Frost spell power
        maxAbsorb = baseAbsorb + (spellPower * 0.8053)
    end
    
    return math.floor(maxAbsorb)
end

-- Shield was applied
local function OnShieldApplied(spellID)
    local baseAbsorb = ShieldSpells[spellID]
    local shieldType = ShieldTypes[spellID]
    
    if not baseAbsorb or not shieldType then return end
    
    local maxAbsorb = CalculateMaxAbsorb(spellID, baseAbsorb)
    
    ActiveShields[shieldType] = {
        spellID = spellID,
        maxAbsorb = maxAbsorb,
        currentAbsorb = maxAbsorb,
        applied = GetTime(),
    }
    
    local frame = GetShieldFrame(shieldType)
    frame.maxAbsorb = maxAbsorb
    frame.currentAbsorb = maxAbsorb
    frame:Show()
    UpdateShieldFrame(frame)
    RepositionFrames()
    
    print(string.format("|cff00ff00[MST]|r %s applied: %d absorb", shieldType, maxAbsorb))
end

-- Shield absorbed damage
local function OnShieldAbsorbed(shieldType, amount)
    if not ActiveShields[shieldType] then return end
    
    local shield = ActiveShields[shieldType]
    shield.currentAbsorb = shield.currentAbsorb - amount
    if shield.currentAbsorb < 0 then shield.currentAbsorb = 0 end
    
    local frame = GetShieldFrame(shieldType)
    frame.currentAbsorb = shield.currentAbsorb
    UpdateShieldFrame(frame)
    
    -- Check if below threshold
    local db = MageShieldTrackerDB or defaults
    local percent = (shield.currentAbsorb / shield.maxAbsorb) * 100
    
    if percent <= (db.lowThreshold or 20) and percent > 0 then
        if db.warnSound ~= false then
            PlaySound("RaidWarning")
        end
    end
end

-- Shield was removed
local function OnShieldRemoved(shieldType)
    ActiveShields[shieldType] = nil
    
    local frame = ShieldFrames[shieldType]
    if frame then
        frame:Hide()
    end
    
    RepositionFrames()
end

-- Scan current buffs for shields
local function ScanBuffs()
    for i = 1, 40 do
        local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellID = UnitBuff("player", i)
        if not name then break end
        
        if spellID and ShieldSpells[spellID] then
            local shieldType = ShieldTypes[spellID]
            if not ActiveShields[shieldType] then
                OnShieldApplied(spellID)
            end
        end
    end
    
    -- Check for removed shields
    for shieldType, data in pairs(ActiveShields) do
        local found = false
        for i = 1, 40 do
            local name, _, _, _, _, _, _, _, _, _, spellID = UnitBuff("player", i)
            if not name then break end
            if spellID and ShieldTypes[spellID] == shieldType then
                found = true
                break
            end
        end
        if not found then
            OnShieldRemoved(shieldType)
        end
    end
end

-- Combat log event handler
local function OnCombatLogEvent(...)
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = select(1, ...)
    local spellID, spellName = select(9, ...)
    local amount = select(12, ...)
    
    local playerGUID = UnitGUID("player")
    
    -- Shield applied to player
    if event == "SPELL_AURA_APPLIED" and destGUID == playerGUID then
        if ShieldSpells[spellID] then
            OnShieldApplied(spellID)
        end
    end
    
    -- Shield removed from player
    if event == "SPELL_AURA_REMOVED" and destGUID == playerGUID then
        if ShieldSpells[spellID] then
            OnShieldRemoved(ShieldTypes[spellID])
        end
    end
    
    -- Damage absorbed - WoW 3.3.5 specific
    -- We need to track SPELL_AURA_REMOVED_DOSE or calculate from damage events
    if event == "SWING_DAMAGE" or event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" or event == "RANGE_DAMAGE" then
        if destGUID == playerGUID then
            -- Check absorbed amount (position varies by event type)
            local absorbed
            if event == "SWING_DAMAGE" then
                absorbed = select(15, ...) or 0
            else
                absorbed = select(18, ...) or 0
            end
            
            if absorbed and absorbed > 0 then
                -- Try to determine which shield absorbed
                for shieldType, data in pairs(ActiveShields) do
                    if data.currentAbsorb > 0 then
                        OnShieldAbsorbed(shieldType, absorbed)
                        break
                    end
                end
            end
        end
    end
    
    -- SPELL_ABSORBED event (more reliable in some versions)
    if event == "SPELL_ABSORBED" then
        if destGUID == playerGUID then
            local absorbSpellID = select(12, ...)
            local absorbAmount = select(15, ...)
            if absorbSpellID and ShieldTypes[absorbSpellID] then
                OnShieldAbsorbed(ShieldTypes[absorbSpellID], absorbAmount or 0)
            end
        end
    end
end

-- Update timer to periodically check buffs
local updateElapsed = 0
local function OnUpdate(self, elapsed)
    updateElapsed = updateElapsed + elapsed
    if updateElapsed < 0.5 then return end
    updateElapsed = 0
    
    ScanBuffs()
end

-- Event handler
MST:RegisterEvent("ADDON_LOADED")
MST:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
MST:RegisterEvent("UNIT_AURA")
MST:RegisterEvent("PLAYER_ENTERING_WORLD")

MST:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            if not MageShieldTrackerDB then
                MageShieldTrackerDB = {}
                for k, v in pairs(defaults) do
                    MageShieldTrackerDB[k] = v
                end
            end
            
            -- Apply saved position
            if MageShieldTrackerDB.xOffset and MageShieldTrackerDB.yOffset then
                AnchorFrame:ClearAllPoints()
                AnchorFrame:SetPoint("CENTER", UIParent, "CENTER",
                    MageShieldTrackerDB.xOffset, MageShieldTrackerDB.yOffset)
            end
            
            print("|cff00ff00[Mage Shield Tracker]|r Loaded! Type /mst for options.")
        end
        
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatLogEvent(...)
        
    elseif event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" then
            ScanBuffs()
        end
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Clear and rescan
        for shieldType, _ in pairs(ActiveShields) do
            OnShieldRemoved(shieldType)
        end
        ScanBuffs()
    end
end)

MST:SetScript("OnUpdate", OnUpdate)

-- Slash commands
SLASH_MST1 = "/mst"
SLASH_MST2 = "/mageshield"
SlashCmdList["MST"] = function(msg)
    local cmd = string.lower(msg or "")
    
    if cmd == "lock" then
        MageShieldTrackerDB.locked = true
        AnchorFrame:EnableMouse(false)
        AnchorFrame.bg:Hide()
        AnchorFrame.text:Hide()
        print("|cff00ff00[MST]|r Frame locked.")
        
    elseif cmd == "unlock" then
        MageShieldTrackerDB.locked = false
        AnchorFrame:EnableMouse(true)
        AnchorFrame:RegisterForDrag("LeftButton")
        AnchorFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        AnchorFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local _, _, _, x, y = self:GetPoint()
            MageShieldTrackerDB.xOffset = x
            MageShieldTrackerDB.yOffset = y
        end)
        AnchorFrame.bg:Show()
        AnchorFrame.text:Show()
        print("|cff00ff00[MST]|r Frame unlocked. Drag to move.")
        
    elseif cmd == "test" then
        -- Simulate shields for testing
        local testShields = {
            { type = "Ice Barrier", max = 8500 },
            { type = "Mana Shield", max = 4200 },
            { type = "Fire Ward", max = 4800 },
        }
        for _, shield in ipairs(testShields) do
            ActiveShields[shield.type] = {
                maxAbsorb = shield.max,
                currentAbsorb = shield.max * 0.75, -- 75% remaining
                applied = GetTime(),
            }
            local frame = GetShieldFrame(shield.type)
            frame.maxAbsorb = shield.max
            frame.currentAbsorb = shield.max * 0.75
            frame:Show()
            UpdateShieldFrame(frame)
        end
        RepositionFrames()
        print("|cff00ff00[MST]|r Test shields added (75% absorb).")
        
    elseif cmd == "testlow" then
        -- Test with low shields
        local testShields = {
            { type = "Ice Barrier", max = 8500, current = 800 },
        }
        for _, shield in ipairs(testShields) do
            ActiveShields[shield.type] = {
                maxAbsorb = shield.max,
                currentAbsorb = shield.current,
                applied = GetTime(),
            }
            local frame = GetShieldFrame(shield.type)
            frame.maxAbsorb = shield.max
            frame.currentAbsorb = shield.current
            frame:Show()
            UpdateShieldFrame(frame)
        end
        RepositionFrames()
        print("|cff00ff00[MST]|r Test low shield added (should be red!).")
        
    elseif cmd == "clear" then
        for shieldType, _ in pairs(ActiveShields) do
            OnShieldRemoved(shieldType)
        end
        print("|cff00ff00[MST]|r Shields cleared.")
        
    elseif cmd:match("^threshold") then
        local val = tonumber(cmd:match("threshold%s*(%d+)"))
        if val and val >= 0 and val <= 100 then
            MageShieldTrackerDB.lowThreshold = val
            print("|cff00ff00[MST]|r Low threshold set to " .. val .. "%")
        else
            print("|cff00ff00[MST]|r Usage: /mst threshold <0-100>")
        end
        
    elseif cmd:match("^size") then
        local val = tonumber(cmd:match("size%s*(%d+)"))
        if val and val >= 24 and val <= 100 then
            MageShieldTrackerDB.iconSize = val
            -- Recreate frames with new size
            for shieldType, frame in pairs(ShieldFrames) do
                frame:Hide()
            end
            ShieldFrames = {}
            ScanBuffs()
            print("|cff00ff00[MST]|r Icon size set to " .. val)
        else
            print("|cff00ff00[MST]|r Usage: /mst size <24-100>")
        end
        
    elseif cmd == "sound" then
        MageShieldTrackerDB.warnSound = not MageShieldTrackerDB.warnSound
        print("|cff00ff00[MST]|r Warning sound " .. (MageShieldTrackerDB.warnSound and "enabled" or "disabled"))
        
    elseif cmd == "vertical" then
        MageShieldTrackerDB.vertical = not MageShieldTrackerDB.vertical
        RepositionFrames()
        print("|cff00ff00[MST]|r Layout: " .. (MageShieldTrackerDB.vertical and "vertical" or "horizontal"))
        
    elseif cmd == "reset" then
        MageShieldTrackerDB = {}
        for k, v in pairs(defaults) do
            MageShieldTrackerDB[k] = v
        end
        AnchorFrame:ClearAllPoints()
        AnchorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
        print("|cff00ff00[MST]|r Settings reset.")
        
    else
        print("|cff00ff00[Mage Shield Tracker]|r Commands:")
        print("  /mst unlock - Unlock to move")
        print("  /mst lock - Lock position")
        print("  /mst test - Show test shields (75%)")
        print("  /mst testlow - Show low shield (warning)")
        print("  /mst clear - Clear test shields")
        print("  /mst threshold <0-100> - Set low warning % (default: 20)")
        print("  /mst size <24-100> - Icon size")
        print("  /mst sound - Toggle warning sound")
        print("  /mst vertical - Toggle vertical/horizontal layout")
        print("  /mst reset - Reset settings")
    end
end
