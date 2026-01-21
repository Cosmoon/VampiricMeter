local VM = VampiricMeter

local MAX_ROWS = 10
local ROW_HEIGHT = 20
local COLS = {
  { key = "name", label = "Character" },
  { key = "vt", label = "Vamp Touch" },
  { key = "sf", label = "Shadowfiend" },
  { key = "mana", label = "Mana Used" },
  { key = "ve", label = "Vamp Embrace" },
}

function VM:CreateUI()
  if self.frame then
    return
  end

  local frame = CreateFrame("Frame", "VampiricMeterFrame", UIParent, "BackdropTemplate")
  frame:SetSize(520, 40 + (MAX_ROWS * ROW_HEIGHT))
  frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
  })
  frame:SetBackdropColor(0, 0, 0, 0.7)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    local point, _, relativePoint, x, y = frame:GetPoint()
    VM.db.frame.point = point
    VM.db.frame.relativePoint = relativePoint
    VM.db.frame.x = x
    VM.db.frame.y = y
  end)

  frame:SetPoint(VM.db.frame.point, UIParent, VM.db.frame.relativePoint, VM.db.frame.x, VM.db.frame.y)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  title:SetPoint("TOP", frame, "TOP", 0, -8)
  title:SetText("VampiricMeter")

  local header = CreateFrame("Frame", nil, frame)
  header:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -24)
  header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -24)
  header:SetHeight(ROW_HEIGHT)

  header.columns = {}
  for index, column in ipairs(COLS) do
    local fontString = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fontString:SetText(column.label)
    fontString:SetJustifyH("LEFT")
    fontString:SetPoint("LEFT", header, "LEFT", (index - 1) * 100, 0)
    header.columns[column.key] = fontString
  end

  frame.rows = {}
  for rowIndex = 1, MAX_ROWS do
    local row = CreateFrame("Button", nil, frame)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -24 - (rowIndex * ROW_HEIGHT))
    row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -24 - (rowIndex * ROW_HEIGHT))

    row.columns = {}
    for colIndex, column in ipairs(COLS) do
      local fontString = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      fontString:SetJustifyH("LEFT")
      fontString:SetPoint("LEFT", row, "LEFT", (colIndex - 1) * 100, 0)
      row.columns[column.key] = fontString
    end

    row:SetScript("OnEnter", function()
      VM:ShowTooltip(row.playerName)
    end)
    row:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    frame.rows[rowIndex] = row
  end

  self.frame = frame
end

function VM:UpdateVisibility()
  if not self.frame then
    return
  end
  if self.db.hidden then
    self.frame:Hide()
  else
    self.frame:Show()
  end
end

function VM:UpdateDisplay()
  if not self.frame then
    return
  end

  local order = self.fightData.order
  for index = 1, MAX_ROWS do
    local row = self.frame.rows[index]
    local name = order[index]
    if name then
      local data = self.fightData.players[name]
      row.playerName = name
      row.columns.name:SetText(name)
      row.columns.vt:SetText(data.vt)
      row.columns.sf:SetText(data.sf)
      row.columns.mana:SetText(data.mana)
      row.columns.ve:SetText(data.ve)
      row:Show()
    else
      row.playerName = nil
      row.columns.name:SetText("")
      row.columns.vt:SetText("")
      row.columns.sf:SetText("")
      row.columns.mana:SetText("")
      row.columns.ve:SetText("")
      row:Hide()
    end
  end
end

function VM:ShowTooltip(playerName)
  if not playerName then
    return
  end
  local data = self.fightData.players[playerName]
  if not data then
    return
  end

  GameTooltip:SetOwner(self.frame, "ANCHOR_RIGHT")
  GameTooltip:SetText(playerName)

  local hasTargets = false
  for targetName, totals in pairs(data.targets) do
    hasTargets = true
    GameTooltip:AddLine(targetName, 1, 0.82, 0)
    GameTooltip:AddDoubleLine("Vamp Touch", totals.vt, 1, 1, 1, 0.8, 0.8, 0.8)
    GameTooltip:AddDoubleLine("Shadowfiend", totals.sf, 1, 1, 1, 0.8, 0.8, 0.8)
    GameTooltip:AddDoubleLine("Vamp Embrace", totals.ve, 1, 1, 1, 0.8, 0.8, 0.8)
  end

  if not hasTargets then
    GameTooltip:AddLine("No target data yet.")
  end

  GameTooltip:Show()
end
