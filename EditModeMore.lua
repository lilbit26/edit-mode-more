local name, emm = ...

local function toRoundedNumber(text)
    local num = tonumber(text)
    if num == nil then
        return nil
    else
        return math.floor(num + 0.5)
    end
end

local function updateCurrentSettings(systemFrame)
    local point, relativeTo, relativePoint, offsetX, offsetY = systemFrame:GetPoint()

    -- cache current frame info
    emm.selectedFrame = systemFrame
    emm.point = point
    emm.relativeTo = relativeTo
    emm.relativePoint = relativePoint
    emm.offsetX = offsetX
    emm.offsetY = offsetY

    -- update edit boxes
    emm.frame.xOffsetContainer.editBox:SetText(tostring(toRoundedNumber(offsetX)))
    emm.frame.yOffsetContainer.editBox:SetText(tostring(toRoundedNumber(offsetY)))
end

local function updateDialog(systemFrame)
    if not EditModeSystemSettingsDialog:IsShown() then return end

    -- divider + x offset + y offset + anchor
    local height = EditModeSystemSettingsDialog:GetHeight() + (16 + 32 + 32 + 32)
    EditModeSystemSettingsDialog:SetHeight(height)

    emm.frame:ClearAllPoints()
    emm.frame:SetPoint("TOPLEFT", EditModeSystemSettingsDialog.Buttons, "BOTTOMLEFT", 0, -2)
    emm.frame:SetPoint("BOTTOMRIGHT", EditModeSystemSettingsDialog, "BOTTOMRIGHT", -16, 16)

    updateCurrentSettings(systemFrame)
end

local function applySettings()
    emm.selectedFrame:SetPoint(emm.point, emm.relativeTo, emm.relativePoint, emm.offsetX, emm.offsetY)
    emm.selectedFrame:OnSystemPositionChange()
end

local function setupLabel(label)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
end

local function setupEditBox(editBox)
    editBox:SetAutoFocus(false)

    editBox:SetScript("OnEditFocusGained", function()
        emm.oldText = editBox:GetText()
    end)
    editBox:HookScript("OnEscapePressed", function()
        editBox:SetText(emm.oldText)
    end)
end

-- main function
local function main()
    -- settings frame
    local frame = CreateFrame("Frame", "EditModeMoreFrame", UIParent)
    frame:SetFrameStrata(EditModeSystemSettingsDialog:GetFrameStrata())
    frame:SetFrameLevel(EditModeSystemSettingsDialog:GetFrameLevel())
    emm.frame = frame

    hooksecurefunc(EditModeSystemSettingsDialog, "UpdateDialog", function(_, systemFrame)
        updateDialog(systemFrame)
    end)

    hooksecurefunc(EditModeSystemSettingsDialog, "AttachToSystemFrame", function(_, systemFrame)
        updateDialog(systemFrame)
    end)

    EditModeSystemSettingsDialog:HookScript("OnShow", function()
        emm.frame:Show()
    end)
    EditModeSystemSettingsDialog:HookScript("OnHide", function()
        emm.frame:Hide()
    end)

    -- divider
    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    divider:SetSize(330, 16)
    frame.divider = divider

    -- x offset
    local xOffsetContainer = CreateFrame("Frame", nil, frame)
    xOffsetContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -16)
    xOffsetContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -16)
    xOffsetContainer:SetHeight(32)
    frame.xOffsetContainer = xOffsetContainer

    local xOffsetLabel = xOffsetContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    setupLabel(xOffsetLabel)
    xOffsetLabel:SetText("X Offset")
    xOffsetLabel:SetPoint("TOPLEFT", xOffsetContainer, "TOPLEFT", 0, 0)
    xOffsetLabel:SetSize(100, 32)
    frame.xOffsetContainer.label = xOffsetLabel

    local xOffsetEditBox = CreateFrame("EditBox", nil, xOffsetContainer, "InputBoxTemplate")
    setupEditBox(xOffsetEditBox)
    xOffsetEditBox:SetPoint("TOPLEFT", xOffsetLabel, "TOPRIGHT", 0, 0)
    xOffsetEditBox:SetSize(110, 32)
    xOffsetEditBox:SetScript("OnEnterPressed", function()
        local offset = toRoundedNumber(xOffsetEditBox:GetText())
        if offset == nil then
            xOffsetEditBox:SetText(emm.oldText)
        else
            emm.offsetX = offset
            applySettings()
        end
    end)
    frame.xOffsetContainer.editBox = xOffsetEditBox

    local xOffsetLeftButton = CreateFrame("Button", nil, xOffsetContainer, "UIPanelSquareButton")
    SquareButton_SetIcon(xOffsetLeftButton, "LEFT")
    xOffsetLeftButton:SetPoint("TOPLEFT", xOffsetEditBox, "TOPRIGHT", 10, -2)
    xOffsetLeftButton:SetSize(28, 28)
    xOffsetLeftButton:SetScript("OnClick", function()
        if IsShiftKeyDown() then
            emm.offsetX = emm.offsetX - 10
        else
            emm.offsetX = emm.offsetX - 1
        end
        applySettings()
    end)
    frame.xOffsetContainer.leftButton = xOffsetLeftButton

    local xOffsetRightButton = CreateFrame("Button", nil, xOffsetContainer, "UIPanelSquareButton")
    SquareButton_SetIcon(xOffsetRightButton, "RIGHT")
    xOffsetRightButton:SetPoint("TOPLEFT", xOffsetLeftButton, "TOPRIGHT", 4, 0)
    xOffsetRightButton:SetSize(28, 28)
    xOffsetRightButton:SetScript("OnClick", function()
        if IsShiftKeyDown() then
            emm.offsetX = emm.offsetX + 10
        else
            emm.offsetX = emm.offsetX + 1
        end
        applySettings()
    end)
    frame.xOffsetContainer.rightButton = xOffsetRightButton

    -- y offset
    local yOffsetContainer = CreateFrame("Frame", nil, frame)
    yOffsetContainer:SetPoint("TOPLEFT", xOffsetContainer, "BOTTOMLEFT", 0, 0)
    yOffsetContainer:SetPoint("TOPRIGHT", xOffsetContainer, "BOTTOMRIGHT", 0, 0)
    yOffsetContainer:SetHeight(32)
    frame.yOffsetContainer = yOffsetContainer

    local yOffsetLabel = yOffsetContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    setupLabel(yOffsetLabel)
    yOffsetLabel:SetText("Y Offset")
    yOffsetLabel:SetPoint("TOPLEFT", yOffsetContainer, "TOPLEFT", 0, 0)
    yOffsetLabel:SetSize(100, 32)
    frame.yOffsetContainer.label = yOffsetLabel

    local yOffsetEditBox = CreateFrame("EditBox", nil, yOffsetContainer, "InputBoxTemplate")
    setupEditBox(yOffsetEditBox)
    yOffsetEditBox:SetPoint("TOPLEFT", yOffsetLabel, "TOPRIGHT", 0, 0)
    yOffsetEditBox:SetSize(110, 32)
    yOffsetEditBox:SetScript("OnEnterPressed", function()
        local offset = toRoundedNumber(yOffsetEditBox:GetText())
        if offset == nil then
            yOffsetEditBox:SetText(emm.oldText)
        else
            emm.offsetY = offset
            applySettings()
        end
    end)
    frame.yOffsetContainer.editBox = yOffsetEditBox

    local yOffsetUpButton = CreateFrame("Button", nil, yOffsetContainer, "UIPanelSquareButton")
    SquareButton_SetIcon(yOffsetUpButton, "UP")
    yOffsetUpButton:SetPoint("TOPLEFT", yOffsetEditBox, "TOPRIGHT", 10, -2)
    yOffsetUpButton:SetSize(28, 28)
    yOffsetUpButton:SetScript("OnClick", function()
        if IsShiftKeyDown() then
            emm.offsetY = emm.offsetY + 10
        else
            emm.offsetY = emm.offsetY + 1
        end
        applySettings()
    end)
    frame.yOffsetContainer.upButton = yOffsetUpButton

    local yOffsetDownButton = CreateFrame("Button", nil, yOffsetContainer, "UIPanelSquareButton")
    SquareButton_SetIcon(yOffsetDownButton, "DOWN")
    yOffsetDownButton:SetPoint("TOPLEFT", yOffsetUpButton, "TOPRIGHT", 4, 0)
    yOffsetDownButton:SetSize(28, 28)
    yOffsetDownButton:SetScript("OnClick", function()
        if IsShiftKeyDown() then
            emm.offsetY = emm.offsetY - 10
        else
            emm.offsetY = emm.offsetY - 1
        end
        applySettings()
    end)
    frame.yOffsetContainer.downButton = yOffsetDownButton
end

-- fire on addon loaded
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, addOnName)
    if addOnName == name then
        main()
    end
end)
