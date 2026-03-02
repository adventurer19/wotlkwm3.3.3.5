-- Enemy Cooldown Tracker for WoW 3.3.5 (WotLK)
-- Tracks important enemy cooldowns in PvP

local addonName = "EnemyCooldownTracker"
local ECT = CreateFrame("Frame", "EnemyCooldownTracker")

-- Default settings
local defaults = {
    iconSize = 64,
    spacing = 8,
    maxIcons = 8,
    showInArena = true,
    showInBattleground = true,
    showInWorld = true,
    showDuration = true,
    playSound = true,
    lockFrame = false,
    xOffset = 0,
    yOffset = 150,
}

-- Important enemy cooldowns database
-- Format: [spellID] = { duration = buff/effect duration, cooldown = actual CD, name = display name, priority = 1-10 }
local TrackedSpells = {
    -- ROGUE
    [51713] = { duration = 6, cooldown = 60, name = "Shadow Dance", priority = 10, class = "ROGUE" },
    [13750] = { duration = 15, cooldown = 180, name = "Adrenaline Rush", priority = 8, class = "ROGUE" },
    [13877] = { duration = 15, cooldown = 120, name = "Blade Flurry", priority = 6, class = "ROGUE" },
    [31224] = { duration = 5, cooldown = 90, name = "Cloak of Shadows", priority = 9, class = "ROGUE" },
    [26889] = { duration = 10, cooldown = 180, name = "Vanish", priority = 8, class = "ROGUE" },
    [14177] = { duration = 20, cooldown = 180, name = "Cold Blood", priority = 7, class = "ROGUE" },
    [51690] = { duration = 2, cooldown = 120, name = "Killing Spree", priority = 9, class = "ROGUE" },
    [14185] = { duration = 0, cooldown = 480, name = "Preparation", priority = 7, class = "ROGUE" },
    [2094]  = { duration = 10, cooldown = 180, name = "Blind", priority = 6, class = "ROGUE" },
    [1856]  = { duration = 3, cooldown = 180, name = "Vanish", priority = 8, class = "ROGUE" },
    [36554] = { duration = 0, cooldown = 30, name = "Shadowstep", priority = 5, class = "ROGUE" },
    [5277]  = { duration = 5, cooldown = 180, name = "Evasion", priority = 7, class = "ROGUE" },
    
    -- WARRIOR
    [46924] = { duration = 6, cooldown = 90, name = "Bladestorm", priority = 10, class = "WARRIOR" },
    [871]   = { duration = 12, cooldown = 300, name = "Shield Wall", priority = 8, class = "WARRIOR" },
    [12292] = { duration = 30, cooldown = 180, name = "Death Wish", priority = 7, class = "WARRIOR" },
    [1719]  = { duration = 12, cooldown = 300, name = "Recklessness", priority = 8, class = "WARRIOR" },
    [18499] = { duration = 10, cooldown = 30, name = "Berserker Rage", priority = 5, class = "WARRIOR" },
    [12975] = { duration = 20, cooldown = 180, name = "Last Stand", priority = 7, class = "WARRIOR" },
    [23920] = { duration = 5, cooldown = 10, name = "Spell Reflection", priority = 8, class = "WARRIOR" },
    [3411]  = { duration = 10, cooldown = 30, name = "Intervene", priority = 4, class = "WARRIOR" },
    [20230] = { duration = 12, cooldown = 300, name = "Retaliation", priority = 6, class = "WARRIOR" },
    [55694] = { duration = 10, cooldown = 180, name = "Enraged Regeneration", priority = 6, class = "WARRIOR" },
    
    -- MAGE
    [45438] = { duration = 10, cooldown = 300, name = "Ice Block", priority = 10, class = "MAGE" },
    [12472] = { duration = 20, cooldown = 180, name = "Icy Veins", priority = 7, class = "MAGE" },
    [12043] = { duration = 15, cooldown = 180, name = "Presence of Mind", priority = 6, class = "MAGE" },
    [12042] = { duration = 15, cooldown = 180, name = "Arcane Power", priority = 8, class = "MAGE" },
    [11958] = { duration = 0, cooldown = 480, name = "Cold Snap", priority = 7, class = "MAGE" },
    [66]    = { duration = 0, cooldown = 180, name = "Invisibility", priority = 6, class = "MAGE" },
    [31687] = { duration = 45, cooldown = 180, name = "Summon Water Elemental", priority = 5, class = "MAGE" },
    [44572] = { duration = 4, cooldown = 30, name = "Deep Freeze", priority = 7, class = "MAGE" },
    [11129] = { duration = 10, cooldown = 120, name = "Combustion", priority = 6, class = "MAGE" },
    
    -- PALADIN
    [642]   = { duration = 12, cooldown = 300, name = "Divine Shield", priority = 10, class = "PALADIN" },
    [1022]  = { duration = 10, cooldown = 300, name = "Hand of Protection", priority = 9, class = "PALADIN" },
    [6940]  = { duration = 12, cooldown = 120, name = "Hand of Sacrifice", priority = 7, class = "PALADIN" },
    [1044]  = { duration = 6, cooldown = 25, name = "Hand of Freedom", priority = 6, class = "PALADIN" },
    [31884] = { duration = 20, cooldown = 180, name = "Avenging Wrath", priority = 9, class = "PALADIN" },
    [498]   = { duration = 12, cooldown = 180, name = "Divine Protection", priority = 7, class = "PALADIN" },
    [64205] = { duration = 6, cooldown = 120, name = "Divine Sacrifice", priority = 8, class = "PALADIN" },
    [20066] = { duration = 6, cooldown = 60, name = "Repentance", priority = 5, class = "PALADIN" },
    [31842] = { duration = 15, cooldown = 180, name = "Divine Illumination", priority = 5, class = "PALADIN" },
    [54428] = { duration = 15, cooldown = 60, name = "Divine Plea", priority = 4, class = "PALADIN" },
    
    -- HUNTER
    [19263] = { duration = 5, cooldown = 90, name = "Deterrence", priority = 9, class = "HUNTER" },
    [3045]  = { duration = 15, cooldown = 300, name = "Rapid Fire", priority = 7, class = "HUNTER" },
    [34490] = { duration = 3, cooldown = 20, name = "Silencing Shot", priority = 6, class = "HUNTER" },
    [19574] = { duration = 18, cooldown = 120, name = "Bestial Wrath", priority = 8, class = "HUNTER" },
    [19503] = { duration = 4, cooldown = 30, name = "Scatter Shot", priority = 6, class = "HUNTER" },
    [23989] = { duration = 0, cooldown = 180, name = "Readiness", priority = 7, class = "HUNTER" },
    [53271] = { duration = 4, cooldown = 60, name = "Master's Call", priority = 6, class = "HUNTER" },
    [34600] = { duration = 30, cooldown = 30, name = "Snake Trap", priority = 3, class = "HUNTER" },
    [60192] = { duration = 20, cooldown = 30, name = "Freezing Arrow", priority = 5, class = "HUNTER" },
    [19386] = { duration = 12, cooldown = 60, name = "Wyvern Sting", priority = 6, class = "HUNTER" },
    
    -- PRIEST
    [33206] = { duration = 8, cooldown = 180, name = "Pain Suppression", priority = 9, class = "PRIEST" },
    [47585] = { duration = 6, cooldown = 120, name = "Dispersion", priority = 9, class = "PRIEST" },
    [10060] = { duration = 15, cooldown = 120, name = "Power Infusion", priority = 7, class = "PRIEST" },
    [6346]  = { duration = 180, cooldown = 180, name = "Fear Ward", priority = 5, class = "PRIEST" },
    [47788] = { duration = 10, cooldown = 180, name = "Guardian Spirit", priority = 9, class = "PRIEST" },
    [34433] = { duration = 15, cooldown = 300, name = "Shadowfiend", priority = 5, class = "PRIEST" },
    [64044] = { duration = 3, cooldown = 120, name = "Psychic Horror", priority = 7, class = "PRIEST" },
    [15487] = { duration = 5, cooldown = 45, name = "Silence", priority = 7, class = "PRIEST" },
    [64843] = { duration = 8, cooldown = 480, name = "Divine Hymn", priority = 6, class = "PRIEST" },
    
    -- WARLOCK
    [18708] = { duration = 15, cooldown = 180, name = "Fel Domination", priority = 6, class = "WARLOCK" },
    [47241] = { duration = 30, cooldown = 180, name = "Metamorphosis", priority = 10, class = "WARLOCK" },
    [47847] = { duration = 6, cooldown = 30, name = "Shadowfury", priority = 5, class = "WARLOCK" },
    [17928] = { duration = 3, cooldown = 40, name = "Howl of Terror", priority = 7, class = "WARLOCK" },
    [18288] = { duration = 8, cooldown = 180, name = "Amplify Curse", priority = 4, class = "WARLOCK" },
    [30283] = { duration = 3, cooldown = 20, name = "Shadowfury", priority = 6, class = "WARLOCK" },
    [6229]  = { duration = 30, cooldown = 30, name = "Shadow Ward", priority = 3, class = "WARLOCK" },
    [19647] = { duration = 6, cooldown = 24, name = "Spell Lock", priority = 8, class = "WARLOCK" },
    [48020] = { duration = 0, cooldown = 30, name = "Demonic Circle: Teleport", priority = 6, class = "WARLOCK" },
    [59672] = { duration = 6, cooldown = 24, name = "Metamorphosis: Immolation Aura", priority = 5, class = "WARLOCK" },
    
    -- DRUID
    [22812] = { duration = 12, cooldown = 60, name = "Barkskin", priority = 6, class = "DRUID" },
    [17116] = { duration = 0, cooldown = 180, name = "Nature's Swiftness", priority = 7, class = "DRUID" },
    [61336] = { duration = 12, cooldown = 180, name = "Survival Instincts", priority = 8, class = "DRUID" },
    [22842] = { duration = 10, cooldown = 180, name = "Frenzied Regeneration", priority = 6, class = "DRUID" },
    [50334] = { duration = 15, cooldown = 180, name = "Berserk", priority = 9, class = "DRUID" },
    [33891] = { duration = 0, cooldown = 0, name = "Tree of Life", priority = 4, class = "DRUID" },
    [48505] = { duration = 0, cooldown = 90, name = "Starfall", priority = 6, class = "DRUID" },
    [53201] = { duration = 10, cooldown = 60, name = "Starfall", priority = 6, class = "DRUID" },
    [5229]  = { duration = 10, cooldown = 60, name = "Enrage", priority = 4, class = "DRUID" },
    [52610] = { duration = 30, cooldown = 0, name = "Savage Roar", priority = 3, class = "DRUID" },
    [48447] = { duration = 0, cooldown = 480, name = "Tranquility", priority = 6, class = "DRUID" },
    
    -- SHAMAN
    [16188] = { duration = 0, cooldown = 120, name = "Nature's Swiftness", priority = 7, class = "SHAMAN" },
    [16166] = { duration = 0, cooldown = 180, name = "Elemental Mastery", priority = 7, class = "SHAMAN" },
    [30823] = { duration = 15, cooldown = 60, name = "Shamanistic Rage", priority = 7, class = "SHAMAN" },
    [51533] = { duration = 30, cooldown = 180, name = "Feral Spirit", priority = 8, class = "SHAMAN" },
    [2825]  = { duration = 40, cooldown = 600, name = "Bloodlust", priority = 9, class = "SHAMAN" },
    [32182] = { duration = 40, cooldown = 600, name = "Heroism", priority = 9, class = "SHAMAN" },
    [57994] = { duration = 2, cooldown = 6, name = "Wind Shear", priority = 4, class = "SHAMAN" },
    [16190] = { duration = 12, cooldown = 300, name = "Mana Tide Totem", priority = 6, class = "SHAMAN" },
    [8177]  = { duration = 45, cooldown = 15, name = "Grounding Totem", priority = 6, class = "SHAMAN" },
    
    -- DEATH KNIGHT
    [48792] = { duration = 12, cooldown = 120, name = "Icebound Fortitude", priority = 8, class = "DEATHKNIGHT" },
    [48707] = { duration = 5, cooldown = 45, name = "Anti-Magic Shell", priority = 8, class = "DEATHKNIGHT" },
    [51271] = { duration = 20, cooldown = 60, name = "Unbreakable Armor", priority = 7, class = "DEATHKNIGHT" },
    [49028] = { duration = 12, cooldown = 90, name = "Dancing Rune Weapon", priority = 7, class = "DEATHKNIGHT" },
    [49206] = { duration = 30, cooldown = 180, name = "Summon Gargoyle", priority = 8, class = "DEATHKNIGHT" },
    [55233] = { duration = 10, cooldown = 60, name = "Vampiric Blood", priority = 6, class = "DEATHKNIGHT" },
    [49039] = { duration = 10, cooldown = 120, name = "Lichborne", priority = 7, class = "DEATHKNIGHT" },
    [51052] = { duration = 10, cooldown = 120, name = "Anti-Magic Zone", priority = 8, class = "DEATHKNIGHT" },
    [49222] = { duration = 20, cooldown = 60, name = "Bone Shield", priority = 5, class = "DEATHKNIGHT" },
    [47568] = { duration = 15, cooldown = 300, name = "Empower Rune Weapon", priority = 6, class = "DEATHKNIGHT" },
    [47476] = { duration = 5, cooldown = 120, name = "Strangulate", priority = 7, class = "DEATHKNIGHT" },
    [47528] = { duration = 4, cooldown = 10, name = "Mind Freeze", priority = 5, class = "DEATHKNIGHT" },
    
    -- TRINKETS (PvP)
    [42292] = { duration = 0, cooldown = 120, name = "PvP Trinket", priority = 10, class = "ALL" },
    [59752] = { duration = 0, cooldown = 120, name = "Every Man for Himself", priority = 10, class = "ALL" },
    [7744]  = { duration = 0, cooldown = 120, name = "Will of the Forsaken", priority = 10, class = "ALL" },
}

-- Class colors for icons
local ClassColors = {
    ROGUE = { 1, 0.96, 0.41 },
    WARRIOR = { 0.78, 0.61, 0.43 },
    MAGE = { 0.41, 0.8, 0.94 },
    PALADIN = { 0.96, 0.55, 0.73 },
    HUNTER = { 0.67, 0.83, 0.45 },
    PRIEST = { 1, 1, 1 },
    WARLOCK = { 0.58, 0.51, 0.79 },
    DRUID = { 1, 0.49, 0.04 },
    SHAMAN = { 0, 0.44, 0.87 },
    DEATHKNIGHT = { 0.77, 0.12, 0.23 },
    ALL = { 1, 1, 1 },
}

-- Fallback spell icons for test mode (in case GetSpellInfo fails)
local FallbackIcons = {
    [51713] = "Interface\\Icons\\Ability_Rogue_ShadowDance",
    [46924] = "Interface\\Icons\\Ability_Warrior_Bladestorm",
    [45438] = "Interface\\Icons\\Spell_Frost_Frost",
    [31224] = "Interface\\Icons\\Spell_Shadow_NetherCloak",
    [642]   = "Interface\\Icons\\Spell_Holy_DivineShield",
    [31884] = "Interface\\Icons\\Spell_Holy_AvengeWrath",
    [47241] = "Interface\\Icons\\Spell_Shadow_DemonForm",
    [48792] = "Interface\\Icons\\Spell_Deathknight_IceboundFortitude",
    [48707] = "Interface\\Icons\\Spell_Shadow_AntiMagicShell",
    [50334] = "Interface\\Icons\\Ability_Druid_Berserk",
    [19263] = "Interface\\Icons\\Ability_Hunter_Readiness",
    [33206] = "Interface\\Icons\\Spell_Holy_PainSuppression",
    [2825]  = "Interface\\Icons\\Spell_Nature_Bloodlust",
    [42292] = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02",
}

-- Icon pool
local IconPool = {}
local ActiveIcons = {}

-- Create main anchor frame (3.3.5 compatible)
local AnchorFrame = CreateFrame("Frame", "ECT_Anchor", UIParent)
AnchorFrame:SetWidth(300)
AnchorFrame:SetHeight(80)
AnchorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
AnchorFrame:SetMovable(true)
AnchorFrame:EnableMouse(false)
AnchorFrame:SetClampedToScreen(true)

-- Create background for drag mode (3.3.5 compatible - use solid texture)
AnchorFrame.bg = AnchorFrame:CreateTexture(nil, "BACKGROUND")
AnchorFrame.bg:SetAllPoints()
AnchorFrame.bg:SetTexture(0, 0, 0, 0.5)
AnchorFrame.bg:Hide()

AnchorFrame.text = AnchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
AnchorFrame.text:SetPoint("CENTER")
AnchorFrame.text:SetText("Enemy Cooldown Tracker\nDrag to move")
AnchorFrame.text:Hide()

-- Create an icon frame (3.3.5 compatible)
local function CreateIcon()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetWidth(defaults.iconSize)
    frame:SetHeight(defaults.iconSize)
    frame:SetFrameStrata("HIGH")
    
    -- Icon texture
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetAllPoints()
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    -- Cooldown frame (3.3.5 compatible)
    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints()
    frame.cooldown:SetReverse(true)
    
    -- Border glow
    frame.border = frame:CreateTexture(nil, "OVERLAY")
    frame.border:SetPoint("TOPLEFT", -4, 4)
    frame.border:SetPoint("BOTTOMRIGHT", 4, -4)
    frame.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    frame.border:SetBlendMode("ADD")
    
    -- Duration text (big number in center)
    frame.duration = frame:CreateFontString(nil, "OVERLAY")
    frame.duration:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    frame.duration:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.duration:SetTextColor(1, 1, 1)
    
    -- Spell name (below icon)
    frame.name = frame:CreateFontString(nil, "OVERLAY")
    frame.name:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    frame.name:SetPoint("TOP", frame, "BOTTOM", 0, -2)
    frame.name:SetTextColor(1, 1, 1)
    
    -- Source name (above icon)
    frame.source = frame:CreateFontString(nil, "OVERLAY")
    frame.source:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    frame.source:SetPoint("BOTTOM", frame, "TOP", 0, 2)
    frame.source:SetTextColor(0.8, 0.8, 0.8)
    
    frame:Hide()
    return frame
end

-- Get an icon from pool or create new
local function GetIcon()
    local icon = tremove(IconPool)
    if not icon then
        icon = CreateIcon()
    end
    return icon
end

-- Return icon to pool
local function ReleaseIcon(icon)
    icon:Hide()
    icon.spellID = nil
    icon.sourceGUID = nil
    icon.endTime = nil
    tinsert(IconPool, icon)
    
    for i, activeIcon in ipairs(ActiveIcons) do
        if activeIcon == icon then
            tremove(ActiveIcons, i)
            break
        end
    end
end

-- Reposition all active icons
local function RepositionIcons()
    local db = EnemyCooldownTrackerDB or defaults
    local iconSize = db.iconSize or defaults.iconSize
    local spacing = db.spacing or defaults.spacing
    local totalWidth = #ActiveIcons * iconSize + (#ActiveIcons - 1) * spacing
    local startX = -totalWidth / 2 + iconSize / 2
    
    for i, icon in ipairs(ActiveIcons) do
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", AnchorFrame, "CENTER", startX + (i - 1) * (iconSize + spacing), 0)
        icon:SetWidth(iconSize)
        icon:SetHeight(iconSize)
    end
end

-- Add a new cooldown to track
local function AddCooldown(spellID, sourceGUID, sourceName)
    local spellData = TrackedSpells[spellID]
    if not spellData then 
        print("|cffff0000[ECT Debug]|r Spell not found in TrackedSpells: " .. tostring(spellID))
        return 
    end
    
    local db = EnemyCooldownTrackerDB or defaults
    
    -- Check max icons
    if #ActiveIcons >= (db.maxIcons or defaults.maxIcons) then 
        print("|cffff0000[ECT Debug]|r Max icons reached")
        return 
    end
    
    -- Check if already tracking this spell from this source
    for _, icon in ipairs(ActiveIcons) do
        if icon.spellID == spellID and icon.sourceGUID == sourceGUID then
            return
        end
    end
    
    -- Get spell info
    local name, rank, iconTexture = GetSpellInfo(spellID)
    
    -- Use fallback icon if GetSpellInfo failed
    if not iconTexture then
        iconTexture = FallbackIcons[spellID] or "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    if not name then
        name = spellData.name
    end
    
    local iconFrame = GetIcon()
    iconFrame.icon:SetTexture(iconTexture)
    iconFrame.name:SetText(spellData.name or name or "Unknown")
    iconFrame.source:SetText(sourceName or "Unknown")
    iconFrame.spellID = spellID
    iconFrame.sourceGUID = sourceGUID
    
    -- For instant spells (duration = 0), show for 3 seconds
    local duration = spellData.duration
    if duration == 0 then
        duration = 3
    end
    iconFrame.endTime = GetTime() + duration
    iconFrame.duration:SetText("")
    
    -- Set border color based on class
    local color = ClassColors[spellData.class] or ClassColors.ALL
    iconFrame.border:SetVertexColor(color[1], color[2], color[3])
    
    -- Start cooldown spiral
    if spellData.duration > 0 then
        iconFrame.cooldown:SetCooldown(GetTime(), spellData.duration)
        iconFrame.cooldown:Show()
    else
        iconFrame.cooldown:Hide()
    end
    
    tinsert(ActiveIcons, iconFrame)
    iconFrame:Show()
    
    -- Play sound
    if db.playSound ~= false then
        PlaySound("RaidWarning")
    end
    
    RepositionIcons()
    
    print("|cff00ff00[ECT]|r Tracking: " .. (spellData.name or name) .. " from " .. (sourceName or "Unknown"))
end

-- Update function
local updateElapsed = 0
local function OnUpdate(self, elapsed)
    updateElapsed = updateElapsed + elapsed
    if updateElapsed < 0.1 then return end
    updateElapsed = 0
    
    local db = EnemyCooldownTrackerDB or defaults
    local currentTime = GetTime()
    
    for i = #ActiveIcons, 1, -1 do
        local icon = ActiveIcons[i]
        local remaining = icon.endTime - currentTime
        
        if remaining <= 0 then
            ReleaseIcon(icon)
            RepositionIcons()
        elseif db.showDuration ~= false then
            icon.duration:SetText(string.format("%.1f", remaining))
        end
    end
end

-- Check if in valid zone
local function IsInValidZone()
    local db = EnemyCooldownTrackerDB or defaults
    local _, instanceType = IsInInstance()
    
    if instanceType == "arena" then
        return db.showInArena ~= false
    elseif instanceType == "pvp" then
        return db.showInBattleground ~= false
    else
        return db.showInWorld ~= false
    end
end

-- Combat log event handler for WoW 3.3.5
local function OnCombatLogEvent(...)
    if not IsInValidZone() then return end
    
    -- WoW 3.3.5 combat log format
    local timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = select(1, ...)
    local spellID, spellName, spellSchool = select(9, ...)
    
    -- Only track enemy spells
    if not sourceGUID or sourceGUID == UnitGUID("player") then return end
    
    -- Check if hostile
    if sourceFlags then
        local isHostile = bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
        if not isHostile then return end
    end
    
    -- Track SPELL_CAST_SUCCESS and SPELL_AURA_APPLIED
    if event == "SPELL_CAST_SUCCESS" or event == "SPELL_AURA_APPLIED" then
        if TrackedSpells[spellID] then
            AddCooldown(spellID, sourceGUID, sourceName)
        end
    end
end

-- Event handlers
ECT:RegisterEvent("ADDON_LOADED")
ECT:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
ECT:RegisterEvent("PLAYER_ENTERING_WORLD")

ECT:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            -- Initialize saved variables
            if not EnemyCooldownTrackerDB then
                EnemyCooldownTrackerDB = {}
                for k, v in pairs(defaults) do
                    EnemyCooldownTrackerDB[k] = v
                end
            end
            
            -- Apply saved position
            if EnemyCooldownTrackerDB.xOffset and EnemyCooldownTrackerDB.yOffset then
                AnchorFrame:ClearAllPoints()
                AnchorFrame:SetPoint("CENTER", UIParent, "CENTER", 
                    EnemyCooldownTrackerDB.xOffset, EnemyCooldownTrackerDB.yOffset)
            end
            
            print("|cff00ff00[Enemy Cooldown Tracker]|r Loaded! Type /ect for options.")
            print("|cff00ff00[ECT]|r Use /ect test to try it out!")
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatLogEvent(...)
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Clear all active cooldowns on zone change
        for i = #ActiveIcons, 1, -1 do
            ReleaseIcon(ActiveIcons[i])
        end
    end
end)

ECT:SetScript("OnUpdate", OnUpdate)

-- Slash commands
SLASH_ECT1 = "/ect"
SLASH_ECT2 = "/enemycd"
SlashCmdList["ECT"] = function(msg)
    local cmd = string.lower(msg or "")
    
    if cmd == "lock" then
        EnemyCooldownTrackerDB.lockFrame = true
        AnchorFrame:EnableMouse(false)
        AnchorFrame.bg:Hide()
        AnchorFrame.text:Hide()
        print("|cff00ff00[ECT]|r Frame locked.")
        
    elseif cmd == "unlock" then
        EnemyCooldownTrackerDB.lockFrame = false
        AnchorFrame:EnableMouse(true)
        AnchorFrame:RegisterForDrag("LeftButton")
        AnchorFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        AnchorFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local _, _, _, x, y = self:GetPoint()
            EnemyCooldownTrackerDB.xOffset = x
            EnemyCooldownTrackerDB.yOffset = y
        end)
        AnchorFrame.bg:Show()
        AnchorFrame.text:Show()
        print("|cff00ff00[ECT]|r Frame unlocked. Drag to move, then type /ect lock.")
        
    elseif cmd == "test" or cmd:match("^test") then
        local testType = cmd:match("test%s*(%w*)")
        local t = GetTime()
        
        if testType == "" or not testType or testType == "rogue" then
            AddCooldown(51713, "test-rogue-"..t, "ShadowyRogue")
        end
        if testType == "" or not testType or testType == "warrior" then
            AddCooldown(46924, "test-warrior-"..t, "AngryWarrior")
        end
        if testType == "" or not testType or testType == "mage" then
            AddCooldown(45438, "test-mage-"..t, "FrostyMage")
        end
        if testType == "paladin" or testType == "pala" then
            AddCooldown(642, "test-pala-"..t, "HolyPaladin")
            AddCooldown(31884, "test-pala2-"..t, "HolyPaladin")
        end
        if testType == "hunter" then
            AddCooldown(19263, "test-hunt-"..t, "PewPewHunter")
        end
        if testType == "priest" then
            AddCooldown(33206, "test-priest-"..t, "HealyPriest")
        end
        if testType == "warlock" or testType == "lock" then
            AddCooldown(47241, "test-lock-"..t, "DemoLock")
        end
        if testType == "druid" then
            AddCooldown(50334, "test-druid-"..t, "FeralDruid")
        end
        if testType == "shaman" or testType == "sham" then
            AddCooldown(2825, "test-sham-"..t, "EnhanceSham")
        end
        if testType == "dk" or testType == "deathknight" then
            AddCooldown(48792, "test-dk-"..t, "UnholyDK")
            AddCooldown(48707, "test-dk2-"..t, "UnholyDK")
        end
        if testType == "trinket" then
            AddCooldown(42292, "test-trinket-"..t, "SomeEnemy")
        end
        if testType == "all" then
            AddCooldown(51713, "test-1-"..t, "Rogue")
            AddCooldown(46924, "test-2-"..t, "Warrior")
            AddCooldown(45438, "test-3-"..t, "Mage")
            AddCooldown(642, "test-4-"..t, "Paladin")
            AddCooldown(47241, "test-5-"..t, "Warlock")
            AddCooldown(50334, "test-6-"..t, "Druid")
            AddCooldown(48792, "test-7-"..t, "DeathKnight")
            AddCooldown(19263, "test-8-"..t, "Hunter")
        end
        
    elseif cmd == "reset" then
        EnemyCooldownTrackerDB = {}
        for k, v in pairs(defaults) do
            EnemyCooldownTrackerDB[k] = v
        end
        AnchorFrame:ClearAllPoints()
        AnchorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
        print("|cff00ff00[ECT]|r Settings reset to defaults.")
        
    elseif cmd == "clear" then
        for i = #ActiveIcons, 1, -1 do
            ReleaseIcon(ActiveIcons[i])
        end
        print("|cff00ff00[ECT]|r Active cooldowns cleared.")
        
    elseif cmd:match("^size") then
        local size = tonumber(cmd:match("size%s*(%d+)"))
        if size and size >= 24 and size <= 128 then
            EnemyCooldownTrackerDB.iconSize = size
            RepositionIcons()
            print("|cff00ff00[ECT]|r Icon size set to " .. size)
        else
            print("|cff00ff00[ECT]|r Usage: /ect size <24-128>")
        end
        
    elseif cmd == "sound" then
        EnemyCooldownTrackerDB.playSound = not EnemyCooldownTrackerDB.playSound
        print("|cff00ff00[ECT]|r Sound " .. (EnemyCooldownTrackerDB.playSound and "enabled" or "disabled"))
        
    elseif cmd == "arena" then
        EnemyCooldownTrackerDB.showInArena = not EnemyCooldownTrackerDB.showInArena
        print("|cff00ff00[ECT]|r Arena tracking " .. (EnemyCooldownTrackerDB.showInArena and "enabled" or "disabled"))
        
    elseif cmd == "bg" then
        EnemyCooldownTrackerDB.showInBattleground = not EnemyCooldownTrackerDB.showInBattleground
        print("|cff00ff00[ECT]|r Battleground tracking " .. (EnemyCooldownTrackerDB.showInBattleground and "enabled" or "disabled"))
        
    elseif cmd == "world" then
        EnemyCooldownTrackerDB.showInWorld = not EnemyCooldownTrackerDB.showInWorld
        print("|cff00ff00[ECT]|r World PvP tracking " .. (EnemyCooldownTrackerDB.showInWorld and "enabled" or "disabled"))
        
    elseif cmd == "debug" then
        print("|cff00ff00[ECT Debug]|r Active icons: " .. #ActiveIcons)
        print("|cff00ff00[ECT Debug]|r Icon pool: " .. #IconPool)
        print("|cff00ff00[ECT Debug]|r Zone valid: " .. tostring(IsInValidZone()))
        
    else
        print("|cff00ff00[Enemy Cooldown Tracker]|r Commands:")
        print("  /ect unlock - Unlock frame to move")
        print("  /ect lock - Lock frame position")
        print("  /ect test - Show test cooldowns (Shadow Dance, Bladestorm, Ice Block)")
        print("  /ect test <class> - Test specific class (rogue/warrior/mage/pala/hunter/priest/lock/druid/sham/dk/all)")
        print("  /ect clear - Clear active cooldowns")
        print("  /ect size <24-128> - Set icon size")
        print("  /ect sound - Toggle sound alerts")
        print("  /ect arena - Toggle arena tracking")
        print("  /ect bg - Toggle battleground tracking")
        print("  /ect world - Toggle world PvP tracking")
        print("  /ect reset - Reset to defaults")
        print("  /ect debug - Show debug info")
    end
end
