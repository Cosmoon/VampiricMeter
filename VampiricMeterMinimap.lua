local VM = VampiricMeter

local function UpdateMinimapPosition(button)
  local angle = VM.db.minimap.angle or 220
  local radius = 80
  local x = math.cos(math.rad(angle)) * radius
  local y = math.sin(math.rad(angle)) * radius
  button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function VM:CreateMinimapButton()
  if self.minimapButton then
    return
  end

  local button = CreateFrame("Button", "VampiricMeterMinimapButton", Minimap)
  button:SetSize(32, 32)
  button:SetFrameStrata("MEDIUM")
  button:SetNormalTexture("Interface\\AddOns\\VampiricMeter\\Media\\VampIcon")
  local normal = button:GetNormalTexture()
  normal:SetSize(20, 20)
  normal:SetPoint("CENTER", button, "CENTER", 0, 0)

  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\UI-Minimap-TrackingBorder")
  border:SetSize(54, 54)
  border:SetPoint("TOPLEFT", button, "TOPLEFT", -11, 11)
  button.border = border

  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "LeftButton" then
      VM.db.hidden = not VM.db.hidden
      VM:UpdateVisibility()
    else
      InterfaceOptionsFrame_OpenToCategory(VM.optionsPanel)
      InterfaceOptionsFrame_OpenToCategory(VM.optionsPanel)
    end
  end)

  button:RegisterForDrag("LeftButton")
  button:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  button:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local mx, my = Minimap:GetCenter()
    x = x / scale
    y = y / scale
    local angle = math.deg(math.atan2(y - my, x - mx))
    VM.db.minimap.angle = angle
    UpdateMinimapPosition(self)
  end)

  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("VampiricMeter")
    GameTooltip:AddLine("Left Click: Toggle window", 1, 1, 1)
    GameTooltip:AddLine("Right Click: Options", 1, 1, 1)
    GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  UpdateMinimapPosition(button)
  button:SetMovable(true)
  button:EnableMouse(true)

  self.minimapButton = button
  self:CreateOptionsPanel()
end

function VM:CreateOptionsPanel()
  if self.optionsPanel then
    return
  end
  local panel = CreateFrame("Frame", "VampiricMeterOptions", InterfaceOptionsFramePanelContainer)
  panel.name = "VampiricMeter"

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
  title:SetText("VampiricMeter Options")

  local description = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  description:SetText("Right-click the minimap icon to open this panel.")

  InterfaceOptions_AddCategory(panel)
  self.optionsPanel = panel
end
