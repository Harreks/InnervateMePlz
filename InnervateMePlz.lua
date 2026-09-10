--Initial Setup
local _, NS = ...
IMPLZ_DB = IMPLZ_DB or {}
local playerClass = select(2, UnitClass('player'))

local defaults = {
    displayType = '3',
    manaThreshold = 70,
    highlightThickness = 2,
    highlightColor = 'FF00FF00',
    iconSize = 60
}

local borderContainer = CreateFrame('Frame')
local borderData = {
    top = { sideOne = 'TOPLEFT', sideTwo = 'TOPRIGHT', size = 'height'},
    bottom = { sideOne = 'BOTTOMLEFT', sideTwo = 'BOTTOMRIGHT', size = 'height'},
    left = { sideOne = 'TOPLEFT', sideTwo = 'BOTTOMLEFT', size = 'width' },
    right = { sideOne = 'TOPRIGHT', sideTwo = 'BOTTOMRIGHT', size = 'width' }
}

local hCR, hCG, hCB = CreateColorFromHexString(IMPLZ_DB.highlightColor or defaults.highlightColor):GetRGB()
local highlightColor = { r = hCR, g = hCG, b = hCB }

for side, data in pairs(borderData) do
    local border = borderContainer:CreateTexture(nil, 'OVERLAY')
    border:SetColorTexture(highlightColor.r, highlightColor.g, highlightColor.b, 1)
    border:SetPoint(data.sideOne, borderContainer, data.sideOne)
    border:SetPoint(data.sideTwo, borderContainer, data.sideTwo)
    if data.size == 'height' then
        border:SetHeight(IMPLZ_DB.highlightThickness or defaults.highlightThickness)
    else
        border:SetWidth(IMPLZ_DB.highlightThickness or defaults.highlightThickness)
    end
    borderContainer[side] = border
end
borderContainer:Hide()

local iconContainer = CreateFrame('Frame', 'IMPLZ_Icon', UIParent)
iconContainer:SetSize(IMPLZ_DB.iconSize or defaults.iconSize, IMPLZ_DB.iconSize or defaults.iconSize)
iconContainer:SetPoint('CENTER')
iconContainer:SetMovable(true)
iconContainer:SetScript('OnMouseDown', function(self) self:StartMoving() end)
iconContainer:SetScript('OnMouseUp', function(self) self:StopMovingOrSizing() end)

iconContainer.icon = iconContainer:CreateTexture(nil, 'OVERLAY')
iconContainer.icon:SetTexture(136048)
iconContainer.icon:SetPoint('TOPLEFT', iconContainer, 'TOPLEFT')
iconContainer.icon:SetPoint('BOTTOMRIGHT', iconContainer, 'BOTTOMRIGHT')
iconContainer.icon:SetVertexColor(1, 1, 1, 0)

iconContainer.text = iconContainer:CreateFontString(nil, 'OVERLAY')
iconContainer.text:SetFont('Fonts\\FRIZQT__.TTF', 16, 'OUTLINE')
iconContainer.text:SetPoint('CENTER')
iconContainer.text:SetText('Innervate\n' .. (IMPLZ_DB.target or ''))
iconContainer.text:SetVertexColor(1, 1, 1, 0)

--Transparency Curve
local powerPercentCurve = C_CurveUtil.CreateCurve()
powerPercentCurve:SetType(Enum.LuaCurveType.Step)
powerPercentCurve:AddPoint(0.0, 1)
powerPercentCurve:AddPoint((IMPLZ_DB.manaThreshold or defaults.manaThreshold) / 100, 0)

--Create Options Menu
local settings = {
    {
        key = 'displayType',
        type = 'dropdown',
        text = 'Display Type',
        default = defaults.displayType,
        items = {
            { text = 'Frame Highlight', value = '1' },
            { text = 'Spell Icon', value = '2' },
            { text = 'Both', value = '3' }
        },
        tooltip = 'Select the way the addon shows that you need to innervate.'
    },
    {
        key = 'manaThreshold',
        type = 'slider',
        text = 'Mana Percentage Threshold',
        default = defaults.manaThreshold,
        min = 0,
        max = 100,
        step = 1,
        tooltip = 'Select the mana percentage at which the alert will trigger.',
        func = function(newThreshold)
            powerPercentCurve:ClearPoints()
            powerPercentCurve:AddPoint(0.0, 1)
            powerPercentCurve:AddPoint(newThreshold / 100, 0)
        end
    },
    {
        key = 'highlightThickness',
        type = 'slider',
        text = 'Highlight Thickness',
        default = defaults.highlightThickness,
        min = 1,
        max = 10,
        step = 1,
        tooltip = 'Select the thickness of the frame highlight.',
        func = function(newThickness)
            for side, data in pairs(borderData) do
                if data.size == 'height' then
                    borderContainer[side]:SetHeight(newThickness)
                else
                    borderContainer[side]:SetWidth(newThickness)
                end
            end
        end
    },
    {
        key = 'highlightColor',
        type = 'color',
        text = 'Highlight Color',
        default = defaults.highlightColor,
        tooltip = 'Select the color of the frame highlight.',
        func = function(newColorHex)
            local cR, cG, cB = CreateColorFromHexString(newColorHex):GetRGB()
            for side, _ in pairs(borderData) do
                borderContainer[side]:SetColorTexture(cR, cG, cB, 1)
            end
            highlightColor = { r = cR, g = cG, b = cB }
        end
    },
    {
        key = 'iconSize',
        type = 'slider',
        text = 'Icon Size',
        default = defaults.iconSize,
        min = 2,
        max = 200,
        step = 1,
        tooltip = 'Select the size of the icon display.',
        func = function(newSize)
            iconContainer:SetSize(newSize, newSize)
        end
    }
}
local LAMB = NS.LibAdvancedMenuBuilder
local category = LAMB.CreateOptionsPanel(settings, IMPLZ_DB, 'Innervate Me Plz', 'vertical')

--Main loop
local targetUnitId = nil
borderContainer:SetScript('OnEvent', function()
    if targetUnitId then
        local powerAlpha = UnitPowerPercent(targetUnitId, Enum.PowerType.Mana, false, powerPercentCurve)
        local innervateCooldown = C_Spell.GetSpellCooldown(29166)
        local shouldCastInnervate = (not (innervateCooldown.isActive and not innervateCooldown.isOnGCD))
        --Frame Highlight
        local shouldShowHighlight = shouldCastInnervate and (IMPLZ_DB.displayType == '1' or IMPLZ_DB.displayType == '3')
        for side, _ in pairs(borderData) do
            borderContainer[side]:SetVertexColor(highlightColor.r, highlightColor.g, highlightColor.b, powerAlpha)
        end
        borderContainer:SetShown(shouldShowHighlight)
        --Spell Icon
        local shouldShowIcon = shouldCastInnervate and (IMPLZ_DB.displayType == '2' or IMPLZ_DB.displayType == '3')
        iconContainer:SetShown(shouldShowIcon)
        iconContainer.icon:SetVertexColor(1, 1, 1, powerAlpha)
        iconContainer.text:SetVertexColor(1, 1, 1, powerAlpha)
    end
end)

--Utilities
local function SendChatMessage(msg)
    local intro = '|cFFFF9900InnervateMePlz:|r '
    print(intro .. msg)
end

local function AttachBordersToFrame(frame)
    borderContainer:ClearAllPoints()
    borderContainer:SetPoint('TOPLEFT', frame, 'TOPLEFT')
    borderContainer:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT')
end

local LGF = LibStub('LibGetFrame-1.0')
LGF.RegisterCallback('InnervateMePlz', 'GETFRAME_REFRESH', function()
    local frame = LGF.GetUnitFrame(targetUnitId)
    if frame then
        AttachBordersToFrame(frame)
    end
end)

local function GetUnitNameString(token)
    local name, server = UnitFullName(token)
    if name then
        if server then
            return name .. '-' .. server
        elseif UnitRealmRelationship(token) == 1 then
            local _, playerServer = UnitFullName('player')
            return name .. '-' .. playerServer
        end
    else
        return nil
    end
end

local function UpdateTargetUnit()
    borderContainer:UnregisterAllEvents()
    targetUnitId = nil
    if IsInRaid() then
        for i = 1, 40 do
            local currentUnit = 'raid' .. i
            local fullName = GetUnitNameString(currentUnit)
            if fullName and fullName == IMPLZ_DB.target then
                targetUnitId = currentUnit
                break
            end
        end
    elseif IsInGroup() then
        for i = 1, 4 do
            local currentUnit = 'party' .. i
            local fullName = GetUnitNameString(currentUnit)
            if fullName and fullName == IMPLZ_DB.target then
                targetUnitId = currentUnit
                break
            end
        end
    end
    if targetUnitId then
        borderContainer:RegisterUnitEvent('UNIT_POWER_UPDATE', targetUnitId)
        LGF:ScanForUnitFrames()
    end
end

local rosterUpdate = CreateFrame('Frame')
rosterUpdate:SetScript('OnEvent', function()
    UpdateTargetUnit()
end)
if playerClass == 'DRUID' then
    UpdateTargetUnit()
    rosterUpdate:RegisterEvent('GROUP_ROSTER_UPDATE')
end

--Intro
if playerClass ~= 'DRUID' then
    SendChatMessage('Addon only works for Druids')
elseif IMPLZ_DB.target then
    SendChatMessage('Your current Innervate target is ' .. IMPLZ_DB.target)
end

--Slash Commands
SLASH_IMPLZ1, SLASH_IMPLZ2, SLASH_IMPLZ3 = '/innervate', '/inner', '/vate'
SlashCmdList.IMPLZ = function(msg)
    if InCombatLockdown() then
        SendChatMessage('You can\'t change settings while in combat')
    else
        if msg == 'tar' or msg == 'target' then
            if playerClass ~= 'DRUID' then
                SendChatMessage('Addon only works for Druids')
            else
                local fullName = GetUnitNameString('target')
                if fullName then
                    IMPLZ_DB.target = fullName
                    iconContainer.text:SetText('Innervate\n' .. IMPLZ_DB.target)
                    SendChatMessage('Your new innervate target is ' .. IMPLZ_DB.target)
                    UpdateTargetUnit()
                end
            end
        else
            Settings.OpenToCategory(category.ID)
        end
    end
end