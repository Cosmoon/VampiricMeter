local ADDON_NAME = ...

VampiricMeter = {}
local VM = VampiricMeter

local VT_MANA_COEFF = 0.05
local SHADOWFIEND_MANA_COEFF = 0.5

local EVENTS = {
  "ADDON_LOADED",
  "PLAYER_REGEN_DISABLED",
  "PLAYER_REGEN_ENABLED",
  "GROUP_ROSTER_UPDATE",
  "COMBAT_LOG_EVENT_UNFILTERED",
}

VM.defaults = {
  frame = {
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
  },
  hidden = false,
  minimap = {
    angle = 220,
  },
}

VM.fightData = {
  players = {},
  order = {},
}

VM.petOwners = {}
VM.lastDamageTarget = {}

local function CopyDefaults(source, target)
  if type(target) ~= "table" then
    target = {}
  end
  for key, value in pairs(source) do
    if type(value) == "table" then
      target[key] = CopyDefaults(value, target[key])
    elseif target[key] == nil then
      target[key] = value
    end
  end
  return target
end

local function GetPlayerInfo(guid)
  local _, class = GetPlayerInfoByGUID(guid)
  return class
end

local function GetPlayerData(name)
  if not name then
    return nil
  end
  local entry = VM.fightData.players[name]
  if not entry then
    entry = {
      vt = 0,
      sf = 0,
      mana = 0,
      ve = 0,
      targets = {},
    }
    VM.fightData.players[name] = entry
    table.insert(VM.fightData.order, name)
  end
  return entry
end

local function AddTargetValue(playerData, targetName, key, value)
  if not targetName or value <= 0 then
    return
  end
  local target = playerData.targets[targetName]
  if not target then
    target = { vt = 0, sf = 0, ve = 0 }
    playerData.targets[targetName] = target
  end
  target[key] = target[key] + value
end

function VM:ResetFight()
  self.fightData = {
    players = {},
    order = {},
  }
  self.petOwners = {}
  self.lastDamageTarget = {}
  self:UpdateDisplay()
end

function VM:Initialize()
  VampiricMeterDB = CopyDefaults(self.defaults, VampiricMeterDB or {})
  self.db = VampiricMeterDB

  self:CreateUI()
  self:CreateMinimapButton()
  self:UpdateVisibility()
  self:UpdateDisplay()
end

function VM:HandleCombatLog()
  local timestamp, event, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, _, _, spellId, spellName, _, amount, powerType = CombatLogGetCurrentEventInfo()

  if event == "SPELL_PERIODIC_DAMAGE" or event == "SPELL_DAMAGE" then
    if spellName == "Vampiric Touch" and sourceName then
      local class = GetPlayerInfo(sourceGUID)
      if class == "PRIEST" then
        local playerData = GetPlayerData(sourceName)
        if playerData then
          local manaGain = math.floor((amount or 0) * VT_MANA_COEFF + 0.5)
          playerData.vt = playerData.vt + manaGain
          AddTargetValue(playerData, destName, "vt", manaGain)
          self:UpdateDisplay()
        end
      end
    end

    if bit.band(sourceFlags or 0, COMBATLOG_OBJECT_TYPE_PET) > 0 and spellName then
      local owner = self.petOwners[sourceGUID]
      if owner then
        self.lastDamageTarget[owner] = destName
        if sourceName == "Shadowfiend" then
          local playerData = GetPlayerData(owner)
          if playerData then
            local manaGain = math.floor((amount or 0) * SHADOWFIEND_MANA_COEFF + 0.5)
            playerData.sf = playerData.sf + manaGain
            AddTargetValue(playerData, destName, "sf", manaGain)
            self:UpdateDisplay()
          end
        end
      end
    end

    if sourceName then
      self.lastDamageTarget[sourceName] = destName
    end
  end

  if event == "SPELL_HEAL" and spellName == "Vampiric Embrace" and sourceName then
    local class = GetPlayerInfo(sourceGUID)
    if class == "PRIEST" then
      local playerData = GetPlayerData(sourceName)
      if playerData then
        local healAmount = amount or 0
        playerData.ve = playerData.ve + healAmount
        AddTargetValue(playerData, self.lastDamageTarget[sourceName], "ve", healAmount)
        self:UpdateDisplay()
      end
    end
  end

  if event == "SPELL_ENERGIZE" and spellName == "Shadowfiend" and sourceGUID and destName then
    self.petOwners[sourceGUID] = destName
  end

  if event == "SPELL_CAST_SUCCESS" and sourceName and spellId then
    local class = GetPlayerInfo(sourceGUID)
    if class == "PRIEST" then
      local costInfo = GetSpellPowerCost and GetSpellPowerCost(spellId)
      if costInfo and costInfo[1] and costInfo[1].cost and costInfo[1].type == 0 then
        local playerData = GetPlayerData(sourceName)
        if playerData then
          playerData.mana = playerData.mana + costInfo[1].cost
          self:UpdateDisplay()
        end
      end
    end
  end
end

function VM:OnEvent(event, ...)
  if event == "ADDON_LOADED" then
    local addonName = ...
    if addonName == ADDON_NAME then
      self:Initialize()
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    self:ResetFight()
  elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
    self:HandleCombatLog()
  end
end

function VM:RegisterEvents(frame)
  for _, event in ipairs(EVENTS) do
    frame:RegisterEvent(event)
  end
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, ...)
  VM:OnEvent(event, ...)
end)
VM:RegisterEvents(eventFrame)
