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
    local point, attachFrame, attachPoint, xOffset, yOffset = systemFrame:GetPoint()

    -- cache current frame info
    emm.selectedFrame = systemFrame
    emm.point = point
    emm.attachFrame = attachFrame
    emm.attachPoint = attachPoint
    emm.xOffset = xOffset
    emm.yOffset = yOffset

    -- update current settings values
    emm.frame.xOffsetContainer.editBox:SetText(tostring(toRoundedNumber(xOffset)))
    emm.frame.yOffsetContainer.editBox:SetText(tostring(toRoundedNumber(yOffset)))
    emm.frame.pointContainer.dropdown:GenerateMenu()
    emm.frame.attachFrameContainer.editBox:SetText(attachFrame:GetName())
    emm.frame.attachPointContainer.dropdown:GenerateMenu()
    emm.frame.frameNameContainer.editBox:SetText(systemFrame:GetName())
end

local function disableOffsetSettings()
    emm.frame.xOffsetContainer.editBox:Disable()
    emm.frame.xOffsetContainer.leftButton:Disable()
    emm.frame.xOffsetContainer.rightButton:Disable()
    emm.frame.yOffsetContainer.editBox:Disable()
    emm.frame.yOffsetContainer.downButton:Disable()
    emm.frame.yOffsetContainer.upButton:Disable()
    emm.frame.pointContainer.dropdown:Disable()
    emm.frame.attachFrameContainer.editBox:Disable()
    emm.frame.attachPointContainer.dropdown:Disable()

    emm.frame.disabledMessage:Show()
end

local function enableOffsetSettings()
    emm.frame.xOffsetContainer.editBox:Enable()
    emm.frame.xOffsetContainer.leftButton:Enable()
    emm.frame.xOffsetContainer.rightButton:Enable()
    emm.frame.yOffsetContainer.editBox:Enable()
    emm.frame.yOffsetContainer.downButton:Enable()
    emm.frame.yOffsetContainer.upButton:Enable()
    emm.frame.pointContainer.dropdown:Enable()
    emm.frame.attachFrameContainer.editBox:Enable()
    emm.frame.attachPointContainer.dropdown:Enable()

    emm.frame.disabledMessage:Hide()
end

local function updateDialog(systemFrame)
    if not EditModeSystemSettingsDialog:IsShown() then return end

    updateCurrentSettings(systemFrame)
    if emm.selectedFrame.isManagedFrame and emm.selectedFrame:IsInDefaultPosition() and emm.attachFrame:GetName() == "UIParentBottomManagedFrameContainer" then
        disableOffsetSettings()
    else
        enableOffsetSettings()
    end

    emm.frame:ClearAllPoints()
    emm.frame:SetPoint("TOPLEFT", EditModeSystemSettingsDialog.Buttons, "BOTTOMLEFT", 0, -2)

    local height = 16 + 32 * 6 -- divider and settings
    if emm.frame.disabledMessage:IsShown() then
        height = height + 32   -- disabled message
    end
    emm.frame:SetSize(360, height)

    if EditModeSystemSettingsDialog:GetTop() and emm.frame:GetBottom() then
        EditModeSystemSettingsDialog:SetHeight(EditModeSystemSettingsDialog:GetTop() - emm.frame:GetBottom() + 20)
    end
end

local function applySettings()
    if not emm.selectedFrame:CanBeMoved() then return end

    if emm.selectedFrame.isManagedFrame and emm.selectedFrame:IsInDefaultPosition() then
        emm.selectedFrame:BreakFromFrameManager()
    end

    if emm.selectedFrame == PlayerCastingBarFrame then
        EditModeManagerFrame:OnSystemSettingChange(emm.selectedFrame, Enum.EditModeCastBarSetting.LockToPlayerFrame, 0);
    end

    emm.selectedFrame:ClearFrameSnap()
    emm.selectedFrame:StopMovingOrSizing();

    emm.selectedFrame:ClearAllPoints()
    emm.selectedFrame:SetPoint(emm.point, emm.attachFrame, emm.attachPoint, emm.xOffset, emm.yOffset)

    if emm.selectedFrame.OnSystemPositionChange then
        emm.selectedFrame:OnSystemPositionChange()
    elseif EditModeManagerFrame.OnSystemPositionChange then -- TODO: remove when 12.0 is live
        EditModeManagerFrame:OnSystemPositionChange(emm.selectedFrame)
    end
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

local function setupPointDropdown(dropdown)
    local function isSelected(index)
        if emm.point == "CENTER" then
            return index == 0
        elseif emm.point == "TOP" then
            return index == 1
        elseif emm.point == "BOTTOM" then
            return index == 2
        elseif emm.point == "LEFT" then
            return index == 3
        elseif emm.point == "RIGHT" then
            return index == 4
        elseif emm.point == "TOPLEFT" then
            return index == 5
        elseif emm.point == "TOPRIGHT" then
            return index == 6
        elseif emm.point == "BOTTOMLEFT" then
            return index == 7
        elseif emm.point == "BOTTOMRIGHT" then
            return index == 8
        end
    end

    local function SetSelected(index)
        if index == 0 then
            emm.point = "CENTER"
        elseif index == 1 then
            emm.point = "TOP"
        elseif index == 2 then
            emm.point = "BOTTOM"
        elseif index == 3 then
            emm.point = "LEFT"
        elseif index == 4 then
            emm.point = "RIGHT"
        elseif index == 5 then
            emm.point = "TOPLEFT"
        elseif index == 6 then
            emm.point = "TOPRIGHT"
        elseif index == 7 then
            emm.point = "BOTTOMLEFT"
        elseif index == 8 then
            emm.point = "BOTTOMRIGHT"
        end

        applySettings()
    end

    dropdown:SetupMenu(function(_, rootDescription)
        rootDescription:CreateRadio("CENTER", isSelected, SetSelected, 0);
        rootDescription:CreateRadio("TOP", isSelected, SetSelected, 1);
        rootDescription:CreateRadio("BOTTOM", isSelected, SetSelected, 2);
        rootDescription:CreateRadio("LEFT", isSelected, SetSelected, 3);
        rootDescription:CreateRadio("RIGHT", isSelected, SetSelected, 4);
        rootDescription:CreateRadio("TOPLEFT", isSelected, SetSelected, 5);
        rootDescription:CreateRadio("TOPRIGHT", isSelected, SetSelected, 6);
        rootDescription:CreateRadio("BOTTOMLEFT", isSelected, SetSelected, 7);
        rootDescription:CreateRadio("BOTTOMRIGHT", isSelected, SetSelected, 8);
    end)
end

local function setupRelativePointDropdown(dropdown)
    local function isSelected(index)
        if emm.attachPoint == "CENTER" then
            return index == 0
        elseif emm.attachPoint == "TOP" then
            return index == 1
        elseif emm.attachPoint == "BOTTOM" then
            return index == 2
        elseif emm.attachPoint == "LEFT" then
            return index == 3
        elseif emm.attachPoint == "RIGHT" then
            return index == 4
        elseif emm.attachPoint == "TOPLEFT" then
            return index == 5
        elseif emm.attachPoint == "TOPRIGHT" then
            return index == 6
        elseif emm.attachPoint == "BOTTOMLEFT" then
            return index == 7
        elseif emm.attachPoint == "BOTTOMRIGHT" then
            return index == 8
        end
    end

    local function SetSelected(index)
        if index == 0 then
            emm.attachPoint = "CENTER"
        elseif index == 1 then
            emm.attachPoint = "TOP"
        elseif index == 2 then
            emm.attachPoint = "BOTTOM"
        elseif index == 3 then
            emm.attachPoint = "LEFT"
        elseif index == 4 then
            emm.attachPoint = "RIGHT"
        elseif index == 5 then
            emm.attachPoint = "TOPLEFT"
        elseif index == 6 then
            emm.attachPoint = "TOPRIGHT"
        elseif index == 7 then
            emm.attachPoint = "BOTTOMLEFT"
        elseif index == 8 then
            emm.attachPoint = "BOTTOMRIGHT"
        end

        applySettings()
    end

    dropdown:SetupMenu(function(_, rootDescription)
        rootDescription:CreateRadio("CENTER", isSelected, SetSelected, 0);
        rootDescription:CreateRadio("TOP", isSelected, SetSelected, 1);
        rootDescription:CreateRadio("BOTTOM", isSelected, SetSelected, 2);
        rootDescription:CreateRadio("LEFT", isSelected, SetSelected, 3);
        rootDescription:CreateRadio("RIGHT", isSelected, SetSelected, 4);
        rootDescription:CreateRadio("TOPLEFT", isSelected, SetSelected, 5);
        rootDescription:CreateRadio("TOPRIGHT", isSelected, SetSelected, 6);
        rootDescription:CreateRadio("BOTTOMLEFT", isSelected, SetSelected, 7);
        rootDescription:CreateRadio("BOTTOMRIGHT", isSelected, SetSelected, 8);
    end)
end

-- main function
local function main()
    -- settings frame
    local frame = CreateFrame("Frame", "EditModeMoreFrame", UIParent)
    frame:SetFrameStrata(EditModeSystemSettingsDialog:GetFrameStrata())
    frame:SetFrameLevel(EditModeSystemSettingsDialog:GetFrameLevel())
    emm.frame = frame

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
    xOffsetEditBox:SetPoint("LEFT", xOffsetLabel, "RIGHT", 10, 0)
    xOffsetEditBox:SetSize(110, 32)
    xOffsetEditBox:SetScript("OnEnterPressed", function()
        local offset = toRoundedNumber(xOffsetEditBox:GetText())
        if offset == nil then
            xOffsetEditBox:SetText(emm.oldText)
        else
            emm.xOffset = offset
            applySettings()
        end
    end)
    frame.xOffsetContainer.editBox = xOffsetEditBox

    local xOffsetLeftButton = CreateFrame("Button", nil, xOffsetContainer, "UIPanelSquareButton")
    SquareButton_SetIcon(xOffsetLeftButton, "LEFT")
    xOffsetLeftButton:SetPoint("LEFT", xOffsetEditBox, "RIGHT", 10, 0)
    xOffsetLeftButton:SetSize(28, 28)
    xOffsetLeftButton:SetScript("OnClick", function()
        if IsShiftKeyDown() then
            emm.xOffset = emm.xOffset - 10
        else
            emm.xOffset = emm.xOffset - 1
        end
        applySettings()
    end)
    frame.xOffsetContainer.leftButton = xOffsetLeftButton

    local xOffsetRightButton = CreateFrame("Button", nil, xOffsetContainer, "UIPanelSquareButton")
    SquareButton_SetIcon(xOffsetRightButton, "RIGHT")
    xOffsetRightButton:SetPoint("LEFT", xOffsetLeftButton, "RIGHT", 4, 0)
    xOffsetRightButton:SetSize(28, 28)
    xOffsetRightButton:SetScript("OnClick", function()
        if IsShiftKeyDown() then
            emm.xOffset = emm.xOffset + 10
        else
            emm.xOffset = emm.xOffset + 1
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
    yOffsetEditBox:SetPoint("LEFT", yOffsetLabel, "RIGHT", 10, 0)
    yOffsetEditBox:SetSize(110, 32)
    yOffsetEditBox:SetScript("OnEnterPressed", function()
        local offset = toRoundedNumber(yOffsetEditBox:GetText())
        if offset == nil then
            yOffsetEditBox:SetText(emm.oldText)
        else
            emm.yOffset = offset
            applySettings()
        end
    end)
    frame.yOffsetContainer.editBox = yOffsetEditBox

    local yOffsetDownButton = CreateFrame("Button", nil, yOffsetContainer, "UIPanelSquareButton")
    SquareButton_SetIcon(yOffsetDownButton, "DOWN")
    yOffsetDownButton:SetPoint("LEFT", yOffsetEditBox, "RIGHT", 10, 0)
    yOffsetDownButton:SetSize(28, 28)
    yOffsetDownButton:SetScript("OnClick", function()
        if IsShiftKeyDown() then
            emm.yOffset = emm.yOffset - 10
        else
            emm.yOffset = emm.yOffset - 1
        end
        applySettings()
    end)
    frame.yOffsetContainer.downButton = yOffsetDownButton

    local yOffsetUpButton = CreateFrame("Button", nil, yOffsetContainer, "UIPanelSquareButton")
    SquareButton_SetIcon(yOffsetUpButton, "UP")
    yOffsetUpButton:SetPoint("LEFT", yOffsetDownButton, "RIGHT", 4, 0)
    yOffsetUpButton:SetSize(28, 28)
    yOffsetUpButton:SetScript("OnClick", function()
        if IsShiftKeyDown() then
            emm.yOffset = emm.yOffset + 10
        else
            emm.yOffset = emm.yOffset + 1
        end
        applySettings()
    end)
    frame.yOffsetContainer.upButton = yOffsetUpButton

    -- point
    local pointContainer = CreateFrame("Frame", nil, frame)
    pointContainer:SetPoint("TOPLEFT", yOffsetContainer, "BOTTOMLEFT", 0, 0)
    pointContainer:SetPoint("TOPRIGHT", yOffsetContainer, "BOTTOMRIGHT", 0, 0)
    pointContainer:SetHeight(32)
    frame.pointContainer = pointContainer

    local pointLabel = pointContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    setupLabel(pointLabel)
    pointLabel:SetText("Point")
    pointLabel:SetPoint("TOPLEFT", pointContainer, "TOPLEFT", 0, 0)
    pointLabel:SetSize(100, 32)
    frame.pointContainer.label = pointLabel

    local pointDropdown = CreateFrame("DropdownButton", nil, pointContainer, "WowStyle1DropdownTemplate")
    setupPointDropdown(pointDropdown)
    pointDropdown:SetPoint("LEFT", pointLabel, "RIGHT", 5, 0)
    pointDropdown:SetSize(225, 26)
    frame.pointContainer.dropdown = pointDropdown

    -- attach frame
    local attachFrameContainer = CreateFrame("Frame", nil, frame)
    attachFrameContainer:SetPoint("TOPLEFT", pointContainer, "BOTTOMLEFT", 0, 0)
    attachFrameContainer:SetPoint("TOPRIGHT", pointContainer, "BOTTOMRIGHT", 0, 0)
    attachFrameContainer:SetHeight(32)
    frame.attachFrameContainer = attachFrameContainer

    local attachFrameLabel = attachFrameContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    setupLabel(attachFrameLabel)
    attachFrameLabel:SetText("Attach to")
    attachFrameLabel:SetPoint("TOPLEFT", attachFrameContainer, "TOPLEFT", 0, 0)
    attachFrameLabel:SetSize(100, 32)
    frame.attachFrameContainer.label = attachFrameLabel

    local attachFrameEditBox = CreateFrame("EditBox", nil, attachFrameContainer, "InputBoxTemplate")
    setupEditBox(attachFrameEditBox)
    attachFrameEditBox:SetPoint("LEFT", attachFrameLabel, "RIGHT", 10, 0)
    attachFrameEditBox:SetSize(220, 32)
    attachFrameEditBox:SetScript("OnEnterPressed", function()
        local frameName = attachFrameEditBox:GetText()
        if _G[frameName] ~= nil and C_Widget.IsFrameWidget(_G[frameName]) then
            emm.attachFrame = _G[frameName]
            applySettings()
        else
            attachFrameEditBox:SetText(emm.oldText)
        end
    end)
    frame.attachFrameContainer.editBox = attachFrameEditBox

    -- attach point
    local attachPointContainer = CreateFrame("Frame", nil, frame)
    attachPointContainer:SetPoint("TOPLEFT", attachFrameContainer, "BOTTOMLEFT", 0, 0)
    attachPointContainer:SetPoint("TOPRIGHT", attachFrameContainer, "BOTTOMRIGHT", 0, 0)
    attachPointContainer:SetHeight(32)
    frame.attachPointContainer = attachPointContainer

    local attachPointLabel = attachPointContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    setupLabel(attachPointLabel)
    attachPointLabel:SetText("Attach Point")
    attachPointLabel:SetPoint("TOPLEFT", attachPointContainer, "TOPLEFT", 0, 0)
    attachPointLabel:SetSize(100, 32)
    frame.attachPointContainer.label = attachPointLabel

    local attachPointDropdown = CreateFrame("DropdownButton", nil, attachPointContainer, "WowStyle1DropdownTemplate")
    setupRelativePointDropdown(attachPointDropdown)
    attachPointDropdown:SetPoint("LEFT", attachPointLabel, "RIGHT", 5, 0)
    attachPointDropdown:SetSize(225, 26)
    frame.attachPointContainer.dropdown = attachPointDropdown

    -- attach frame
    local frameNameContainer = CreateFrame("Frame", nil, frame)
    frameNameContainer:SetPoint("TOPLEFT", attachPointContainer, "BOTTOMLEFT", 0, 0)
    frameNameContainer:SetPoint("TOPRIGHT", attachPointContainer, "BOTTOMRIGHT", 0, 0)
    frameNameContainer:SetHeight(32)
    frame.frameNameContainer = frameNameContainer

    local frameNameLabel = frameNameContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    setupLabel(frameNameLabel)
    frameNameLabel:SetText("Frame Name (Copy Only)")
    frameNameLabel:SetPoint("TOPLEFT", frameNameContainer, "TOPLEFT", 0, 0)
    frameNameLabel:SetSize(100, 32)
    frame.frameNameContainer.label = frameNameLabel

    local frameNameEditBox = CreateFrame("EditBox", nil, frameNameContainer, "InputBoxTemplate")
    setupEditBox(frameNameEditBox)
    frameNameEditBox:SetPoint("LEFT", frameNameLabel, "RIGHT", 10, 0)
    frameNameEditBox:SetSize(220, 32)
    frameNameEditBox:SetScript("OnEnterPressed", function()
        frameNameEditBox:SetText(emm.oldText)
    end)
    frame.frameNameContainer.editBox = frameNameEditBox

    -- disabled message
    local disabledMessage = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    disabledMessage:SetText("** Drag to unlock **")
    disabledMessage:SetTextColor(1, 0, 0)
    disabledMessage:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    disabledMessage:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    disabledMessage:SetHeight(32)
    disabledMessage:Hide()
    frame.disabledMessage = disabledMessage

    -- hooks
    hooksecurefunc(EditModeSystemSettingsDialog, "UpdateDialog", function(_, systemFrame)
        updateDialog(systemFrame)
    end)

    hooksecurefunc(EditModeManagerFrame, "SelectSystem", function(_, selectFrame)
        if selectFrame ~= emm.selectedFrame then
            updateDialog(selectFrame)
        end
    end)

    hooksecurefunc(EditModeManagerFrame, "ClearSelectedSystem", function()
        emm.selectedFrame = nil
    end)
end

-- fire on addon loaded
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, addOnName)
    if addOnName == name then
        main()
    end
end)
