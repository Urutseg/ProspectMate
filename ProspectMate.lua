local frame = CreateFrame("FRAME")
frame:RegisterEvent("TRADE_SKILL_ITEM_CRAFTED_RESULT")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("TRADE_SKILL_CRAFT_BEGIN")

local timer = nil
local timerDelay = 2.5
local trackedSpells = {
  374627, -- Prospecting
  395696, -- Crushing
  382981, -- Milling
  376562, -- Unravelling
}
local isTracked = false

-- Table of crafting reagents that will be tracked
Ores = {
  192880, -- Crumbled Stone
  190395, -- Serevite Ore 1
  190396, -- Serevite Ore 2
  190394, -- Serevite Ore 3
  189143, -- Draconium Ore 1
  188658, -- Draconium Ore 2
  190311, -- Draconium Ore 3
  190312, -- Khazgorite Ore 1
  190313, -- Khazgorite Ore 2
  190314, -- Khazgorite Ore 3
  194545, -- Prismatic Ore
}

Herbs = {
  191460, -- Hochenblume 1
  191461, -- Hochenblume 2
  191462, -- Hochenblume 3
  191470, -- Writhebark 1
  191471, -- Writhebark 2
  191472, -- Writhebark 3
  191467, -- Bubble Poppy 1
  191468, -- Bubble Poppy 2
  191469, -- Bubble Poppy 3
  191464, -- Saxifrage 1
  191465, -- Saxifrage 2
  191466, -- Saxifrage 3
}

Gems = {
  192849, -- Eternity Amber 1
  192850, -- Eternity Amber 2
  192851, -- Eternity Amber 3
  192866, -- Nozdorite 1
  192867, -- Nozdorite 2
  192868, -- Nozdorite 3
}

Cloth = {
  193922, -- Wildercloth
  193050, -- Tattered Wildercloth
  193924, -- Frostbitten Wildercloth
  193923, -- Decayed Wildercloth
  193925, -- Singed Wildercloth
}

local trackedReagents = {}
for _, val in pairs(Ores) do
  table.insert(trackedReagents, val)
end
for _, val in pairs(Herbs) do
  table.insert(trackedReagents, val)
end
for _, val in pairs(Gems) do
  table.insert(trackedReagents, val)
end
for _, val in pairs(Cloth) do
  table.insert(trackedReagents, val)
end

-- Table to store the quantity of each tracked reagent
local preCraftCounts = {}
local postCraftCounts = {}
local consumedItems = {}

local prospectResults = {}

-- Load the SmartProspectorDB saved variable if it exists
if SmartProspectorDB == nil then
  SmartProspectorDB = {}
end

-- Get the count of all tracked reagents in the player's bags
local function getTrackedReagentCounts()
  local counts = {}

  for _, itemId in ipairs(trackedReagents) do
    local count = GetItemCount(itemId, true, false, true)
    -- print("Counted " .. itemId .. " " .. count)
    counts[itemId] = count
  end

  return counts
end

local function findChangedItems(oldCounts, newCounts)
  local changedItems = {}

  for itemId, oldCount in pairs(oldCounts) do
    local newCount = newCounts[itemId]
    -- If we consumed something it's the thing we were prospecting
    if newCount and newCount < oldCount then
      changedItems[itemId] = oldCount - newCount
      print(tostring(itemId) .. " - old: " .. tostring(oldCount) .. ", new: " .. tostring(newCount))
    end
  end

  return changedItems
end

local function updateSmartProspectorDB()
  for consumedItemID, consumedItemCount in pairs(consumedItems) do
    if SmartProspectorDB[consumedItemID] == nil then
      SmartProspectorDB[consumedItemID] = {}
    end
    if SmartProspectorDB[consumedItemID][consumedItemID] == nil then
      SmartProspectorDB[consumedItemID][consumedItemID] = consumedItemCount
    else
      SmartProspectorDB[consumedItemID][consumedItemID] = SmartProspectorDB[consumedItemID][consumedItemID] +
      consumedItemCount
    end
    -- print("Updating counts for " .. tostring(consumedItemID))
    for itemId, quantity in pairs(prospectResults) do
      if SmartProspectorDB[consumedItemID][itemId] == nil then
        SmartProspectorDB[consumedItemID][itemId] = quantity
      else
        SmartProspectorDB[consumedItemID][itemId] = SmartProspectorDB[consumedItemID][itemId] + quantity
      end
    end
    prospectResults = {}
  end
end

local function isInTable(table, item)
  for _, id in ipairs(table) do
    if id == item then
      return true
    end
  end
  return false
end

local function GetSpellName(spellID)
  local name, _, _, _, _, _, _ = GetSpellInfo(spellID)
  return name
end

function frame:OnEvent(event, ...)
  self[event](self, event, ...)
end

function frame:TRADE_SKILL_ITEM_CRAFTED_RESULT(event, ...)
  if isTracked then
    local payload = ...
    local itemId = payload.itemID
    local quantity = payload.quantity

    -- Add the prospecting results to the prospectResults table
    if prospectResults[itemId] == nil then
      prospectResults[itemId] = quantity
    else
      prospectResults[itemId] = prospectResults[itemId] + quantity
    end
  end
end

function frame:TRADE_SKILL_CRAFT_BEGIN(event, spellID)
  isTracked = isInTable(trackedSpells, spellID)
  if isTracked then
    local spellName = GetSpellName(spellID)
    -- print("Doing trackable " .. spellName)
    -- print("counts before crafting")
    -- if this is the first cast, we get reagent counts, otherwise we do not update the values
    if timer == nil then
      preCraftCounts = getTrackedReagentCounts()
    end
  end
end

local function updateSmartProspectorDBDelayed()
  timer = nil
  -- print("counts after crafting")
  -- Get postCraftCounts and consumedItems
  postCraftCounts = getTrackedReagentCounts()
  consumedItems = findChangedItems(preCraftCounts, postCraftCounts)
  -- Update SmartProspectorDB with prospecting results
  updateSmartProspectorDB()
  consumedItems = {}
end

function frame:UNIT_SPELLCAST_SUCCEEDED(event, unitTarget, castGUID, spellID)
  -- print("did a cast")
  -- Cancel the previous timer if it exists
  if timer  then
    local isCancelled = timer:IsCancelled()
    if isCancelled == false then
      -- print("timer active, trying to cancel")
      timer:Cancel()
    end
  else
    -- print("no timer, nothing to cancel")
  end
    
  if isTracked then
    -- print("did a trackable cast" .. tostring(spellID))

    -- Check if the spell cast is a tracked spell
    if isInTable(trackedSpells, spellID) then
      timer = C_Timer.NewTimer(timerDelay, updateSmartProspectorDBDelayed)
    end
  end
end

frame:SetScript("OnEvent", frame.OnEvent)
