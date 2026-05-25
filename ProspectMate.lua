local addonName, addon = ...

local PM = addon
_G.ProspectMate = PM

PM.DB_VERSION = 2
PM.SESSION_TIMEOUT = 2.5

PM.Data = {
  spells = {
    374627, -- Dragon Isles Prospecting
    395696, -- Dragon Isles Crushing
    382981, -- Dragon Isles Milling
    376562, -- Dragon Isles Unravelling
    1231127, -- Midnight Prospecting
    1231132, -- Midnight Crushing
    1269575, -- Midnight Milling
  },
  categories = {
    ores = {
      label = "Ore",
      items = {
        192880, -- Crumbled Stone
        190395, 190396, 190394, -- Serevite Ore
        189143, 188658, 190311, -- Draconium Ore
        190312, 190313, 190314, -- Khaz'gorite Ore
        194545, -- Prismatic Ore
        237359, 237361, -- Refulgent Copper Ore
        237362, 237363, -- Umbral Tin Ore
        237364, 237365, -- Brilliant Silver Ore
        237366, -- Dazzling Thorium
      },
    },
    herbs = {
      label = "Herbs",
      items = {
        191460, 191461, 191462, -- Hochenblume
        191470, 191471, 191472, -- Writhebark
        191467, 191468, 191469, -- Bubble Poppy
        191464, 191465, 191466, -- Saxifrage
        236761, 236767, -- Tranquility Bloom
        236776, 236777, -- Argentleaf
        236774, 236775, -- Azeroot
        236778, 236779, -- Mana Lily
        236771, -- Sanguithorn
        236780, -- Nocturnal Lotus
      },
    },
    gems = {
      label = "Gems",
      items = {
        192849, 192850, 192851, -- Eternity Amber
        192837, 192838, 192839, -- Queen's Ruby
        192856, 192857, 192858, -- Malygite
        192866, 192867, 192868, -- Nozdorite
        192862, 192863, 192865, -- Neltharite
        192852, 192853, 192855, -- Alexstraszite
        192859, 192860, 192861, -- Ysemerald
        242553, 242723, -- Sanguine Garnet
        242554, 242722, -- Amani Lapis
        242607, 242720, -- Harandar Peridot
        242606, 242721, -- Tenebrous Amethyst
        242610, -- Flawless Harandar Peridot
        242611, 242725, -- Flawless Tenebrous Amethyst
        242612, -- Flawless Amani Lapis
        242712, -- Eversong Diamond
      },
    },
    cloth = {
      label = "Cloth",
      legacy = true,
      items = {
        193922, -- Wildercloth
        193050, -- Tattered Wildercloth
        193924, -- Frostbitten Wildercloth
        193923, -- Decayed Wildercloth
        193925, -- Singed Wildercloth
      },
    },
  },
}

PM.State = {
  timer = nil,
  active = false,
  preCraftCounts = {},
  results = {},
}

PM.Index = {
  trackedSpells = {},
  trackedReagents = {},
  categoryByItemID = {},
  categoryOrder = { "ores", "herbs", "gems", "cloth" },
}

local function AddSetIndex(destination, values)
  for _, value in ipairs(values) do
    destination[value] = true
  end
end

function PM.BuildIndexes()
  AddSetIndex(PM.Index.trackedSpells, PM.Data.spells)

  for categoryKey, category in pairs(PM.Data.categories) do
    for _, itemID in ipairs(category.items) do
      PM.Index.trackedReagents[itemID] = true
      PM.Index.categoryByItemID[itemID] = categoryKey
    end
  end
end

function PM.GetItemCount(itemID)
  if C_Item and C_Item.GetItemCount then
    return C_Item.GetItemCount(itemID, true, false, true, true) or 0
  end

  return GetItemCount(itemID, true, false, true) or 0
end

function PM.GetItemInfo(itemID)
  if C_Item and C_Item.GetItemInfo then
    return C_Item.GetItemInfo(itemID)
  end

  return GetItemInfo(itemID)
end

function PM.GetSpellName(spellID)
  if C_Spell and C_Spell.GetSpellInfo then
    local spellInfo = C_Spell.GetSpellInfo(spellID)
    return spellInfo and spellInfo.name
  end

  local name = GetSpellInfo and GetSpellInfo(spellID)
  return name
end

function PM.GetAuctionPrice(itemID)
  if not Auctionator or not Auctionator.API or not Auctionator.API.v1 then
    return nil
  end

  return Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID)
end

function PM.FormatMoney(copper)
  if Auctionator and Auctionator.Utilities and Auctionator.Utilities.CreatePaddedMoneyString then
    return Auctionator.Utilities.CreatePaddedMoneyString(copper)
  end

  return GetMoneyString(copper or 0)
end

local function EnsureDB()
  if type(SmartProspectorDB) ~= "table" then
    SmartProspectorDB = {}
  end

  if SmartProspectorDB.version == PM.DB_VERSION and type(SmartProspectorDB.reagents) == "table" then
    return
  end

  local migrated = {
    version = PM.DB_VERSION,
    reagents = {},
  }

  for reagentID, legacyResults in pairs(SmartProspectorDB) do
    if type(reagentID) == "number" and type(legacyResults) == "table" then
      migrated.reagents[reagentID] = {
        consumed = tonumber(legacyResults[reagentID]) or 0,
        results = {},
      }

      for itemID, quantity in pairs(legacyResults) do
        if itemID ~= reagentID and type(itemID) == "number" then
          migrated.reagents[reagentID].results[itemID] = tonumber(quantity) or 0
        end
      end
    end
  end

  SmartProspectorDB = migrated
end

function PM.GetReagentRows()
  EnsureDB()
  return SmartProspectorDB.reagents
end

function PM.ResetDB()
  SmartProspectorDB = {
    version = PM.DB_VERSION,
    reagents = {},
  }
end

local function GetTrackedReagentCounts()
  local counts = {}

  for itemID in pairs(PM.Index.trackedReagents) do
    counts[itemID] = PM.GetItemCount(itemID)
  end

  return counts
end

local function FindConsumedItems(oldCounts, newCounts)
  local consumedItems = {}

  for itemID, oldCount in pairs(oldCounts) do
    local newCount = newCounts[itemID]
    if newCount and newCount < oldCount then
      consumedItems[itemID] = oldCount - newCount
    end
  end

  return consumedItems
end

local function CommitSession()
  local postCraftCounts = GetTrackedReagentCounts()
  local consumedItems = FindConsumedItems(PM.State.preCraftCounts, postCraftCounts)

  EnsureDB()

  for consumedItemID, consumedItemCount in pairs(consumedItems) do
    local row = SmartProspectorDB.reagents[consumedItemID]

    if not row then
      row = {
        consumed = 0,
        results = {},
      }
      SmartProspectorDB.reagents[consumedItemID] = row
    end

    row.consumed = row.consumed + consumedItemCount

    for itemID, quantity in pairs(PM.State.results) do
      row.results[itemID] = (row.results[itemID] or 0) + quantity
    end
  end

  PM.State.timer = nil
  PM.State.active = false
  PM.State.preCraftCounts = {}
  PM.State.results = {}
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("TRADE_SKILL_ITEM_CRAFTED_RESULT")
eventFrame:RegisterEvent("TRADE_SKILL_CRAFT_BEGIN")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" then
    local loadedAddonName = ...
    if loadedAddonName == addonName then
      PM.BuildIndexes()
      EnsureDB()
    end
    return
  end

  if event == "TRADE_SKILL_CRAFT_BEGIN" then
    local spellID = ...
    PM.State.active = PM.Index.trackedSpells[spellID] == true

    if PM.State.active and not PM.State.timer then
      PM.State.preCraftCounts = GetTrackedReagentCounts()
    end
    return
  end

  if event == "TRADE_SKILL_ITEM_CRAFTED_RESULT" then
    if PM.State.active then
      local payload = ...
      if payload and payload.itemID and payload.quantity then
        PM.State.results[payload.itemID] = (PM.State.results[payload.itemID] or 0) + payload.quantity
      end
    end
    return
  end

  if event == "UNIT_SPELLCAST_SUCCEEDED" then
    local unitTarget, _, spellID = ...
    if unitTarget ~= "player" or not PM.State.active or not PM.Index.trackedSpells[spellID] then
      return
    end

    if PM.State.timer and not PM.State.timer:IsCancelled() then
      PM.State.timer:Cancel()
    end

    PM.State.timer = C_Timer.NewTimer(PM.SESSION_TIMEOUT, CommitSession)
  end
end)
