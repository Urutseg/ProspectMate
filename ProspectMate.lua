local addonName, addon = ...

local PM = addon
_G.ProspectMate = PM

PM.DB_VERSION = 3
PM.SESSION_TIMEOUT = 2.5

PM.Data = {
  spells = {
    { id = 374627, profession = "jewelcrafting", legacy = true }, -- Dragon Isles Prospecting
    { id = 395696, profession = "jewelcrafting", legacy = true }, -- Dragon Isles Crushing
    { id = 382981, profession = "inscription", legacy = true }, -- Dragon Isles Milling
    { id = 376562, profession = "tailoring", legacy = true }, -- Dragon Isles Unravelling
    { id = 1231127, profession = "jewelcrafting" }, -- Midnight Prospecting
    { id = 1231132, profession = "jewelcrafting" }, -- Midnight Crushing
    { id = 1269575, profession = "inscription" }, -- Midnight Milling
    { id = 1259655, profession = "cooking" }, -- Thalassian Filet
    { id = 1229930, profession = "engineering" }, -- Recycling
  },
  professions = {
    jewelcrafting = {
      label = "Jewelcrafting",
      skillLineID = 755,
      recipeSpells = { 1231127, 1231132, 374627, 395696 },
    },
    inscription = {
      label = "Inscription",
      skillLineID = 773,
      recipeSpells = { 1269575, 382981 },
    },
    cooking = {
      label = "Cooking",
      skillLineID = 185,
      recipeSpells = { 1259655 },
    },
    engineering = {
      label = "Engineering",
      skillLineID = 202,
      recipeSpells = { 1229930 },
    },
    tailoring = {
      label = "Tailoring",
      skillLineID = 197,
      recipeSpells = { 376562 },
      legacy = true,
    },
  },
  categories = {
    ores = {
      label = "Ore",
      profession = "jewelcrafting",
      items = {
        { id = 192880, legacy = true }, -- Crumbled Stone
        { id = 190395, legacy = true }, { id = 190396, legacy = true }, { id = 190394, legacy = true }, -- Serevite Ore
        { id = 189143, legacy = true }, { id = 188658, legacy = true }, { id = 190311, legacy = true }, -- Draconium Ore
        { id = 190312, legacy = true }, { id = 190313, legacy = true }, { id = 190314, legacy = true }, -- Khaz'gorite Ore
        { id = 194545, legacy = true }, -- Prismatic Ore
        237359, 237361, -- Refulgent Copper Ore
        237362, 237363, -- Umbral Tin Ore
        237364, 237365, -- Brilliant Silver Ore
        237366, -- Dazzling Thorium
      },
    },
    herbs = {
      label = "Herbs",
      profession = "inscription",
      items = {
        { id = 191460, legacy = true }, { id = 191461, legacy = true }, { id = 191462, legacy = true }, -- Hochenblume
        { id = 191470, legacy = true }, { id = 191471, legacy = true }, { id = 191472, legacy = true }, -- Writhebark
        { id = 191467, legacy = true }, { id = 191468, legacy = true }, { id = 191469, legacy = true }, -- Bubble Poppy
        { id = 191464, legacy = true }, { id = 191465, legacy = true }, { id = 191466, legacy = true }, -- Saxifrage
        236761, 236767, -- Tranquility Bloom
        236776, 236777, -- Argentleaf
        236778, 236779, -- Mana Lily
        236770, 236771, -- Sanguithorn
      },
    },
    gems = {
      label = "Gems",
      profession = "jewelcrafting",
      items = {
        { id = 192849, legacy = true }, { id = 192850, legacy = true }, { id = 192851, legacy = true }, -- Eternity Amber
        { id = 192837, legacy = true }, { id = 192838, legacy = true }, { id = 192839, legacy = true }, -- Queen's Ruby
        { id = 192856, legacy = true }, { id = 192857, legacy = true }, { id = 192858, legacy = true }, -- Malygite
        { id = 192866, legacy = true }, { id = 192867, legacy = true }, { id = 192868, legacy = true }, -- Nozdorite
        { id = 192862, legacy = true }, { id = 192863, legacy = true }, { id = 192865, legacy = true }, -- Neltharite
        { id = 192852, legacy = true }, { id = 192853, legacy = true }, { id = 192855, legacy = true }, -- Alexstraszite
        { id = 192859, legacy = true }, { id = 192860, legacy = true }, { id = 192861, legacy = true }, -- Ysemerald
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
      profession = "tailoring",
      legacy = true,
      items = {
        193922, -- Wildercloth
        193050, -- Tattered Wildercloth
        193924, -- Frostbitten Wildercloth
        193923, -- Decayed Wildercloth
        193925, -- Singed Wildercloth
      },
    },
    fish = {
      label = "Fish",
      profession = "cooking",
      items = {
        238371, -- Arcane Wyrmfish
        238377, -- Blood Hunter
        238369, -- Bloomtail Minnow
        238383, -- Eversong Trout
        238375, -- Fungalskin Pike
        238382, -- Gore Guppy
        238381, -- Hollow Grouper
        238366, -- Lynxfish
        238376, -- Lucky Loa
        238380, -- Null Voidfish
        238373, -- Ominous Octopus
        238372, -- Restored Songfish
        238367, -- Root Crab
        238370, -- Shimmer Spinefish
        238378, -- Shimmersiren
        238365, -- Sin'dorei Swarmer
        238384, -- Sunwell Fish
        238374, -- Tender Lumifin
        238368, -- Twisted Tetra
        238379, -- Warping Wise
      },
    },
    recycling = {
      label = "Recycling",
      profession = "engineering",
      items = {
        239700, 239701, -- Bright Linen Bolt
        245807, 245808, -- Powder Pigment
        238197, 238198, -- Refulgent Copper Ingot
        243574, 243575, -- Song Gear
        239702, 239703, -- Imbued Bright Linen Bolt
        243576, 243577, -- Soul Sprocket
        238202, 238203, -- Gloaming Alloy
        238204, 238205, -- Sterling Alloy
        245803, 245804, -- Argentleaf Pigment
        245801, 245802, -- Munsell Ink
        245805, 245806, -- Sienna Ink
        245764, 245765, -- Codified Azeroot
        245766, 245767, -- Soul Cipher
        239198, 239200, -- Arcanoweave Bolt
        239201, 239202, -- Sunfire Silk Bolt
        240164, 240165, -- Sunfire Silk Lining
        240166, 240167, -- Arcanoweave Lining
        244631, 244632, -- Scalewoven Hide
        244633, 244634, -- Infused Scalewoven Hide
        244635, 244636, -- Sin'dorei Armor Banding
        244637, 244638, -- Silvermoon Weapon Wrap
        244674, 244675, -- Devouring Banding
        244603, 244604, -- Blessed Pango Charm
        244607, 244608, -- Primal Spore Binding
        245781, 245782, -- Thalassian Missive of the Aurora
        245783, 245784, -- Thalassian Missive of the Feverflare
        245785, 245786, -- Thalassian Missive of the Fireflash
        245787, 245788, -- Thalassian Missive of the Harmonious
        245789, 245790, -- Thalassian Missive of the Peerless
        245791, 245792, -- Thalassian Missive of the Quickblade
        245814, 245815, -- Thalassian Missive of Ingenuity
        245816, 245817, -- Thalassian Missive of Resourcefulness
        245818, 245819, -- Thalassian Missive of Multicraft
        245820, 245821, -- Thalassian Missive of Crafting Speed
        245822, 245823, -- Thalassian Missive of Finesse
        245824, 245825, -- Thalassian Missive of Perception
        245826, 245827, -- Thalassian Missive of Deftness
        245871, 245872, -- Darkmoon Sigil: Blood
        245873, 245874, -- Darkmoon Sigil: Void
        245875, 245876, -- Darkmoon Sigil: Hunt
        245877, 245878, -- Darkmoon Sigil: Rot
      },
    },
  },
  resultItems = {
    245807, 245808, -- Powder Pigment
    245803, 245804, -- Argentleaf Pigment
    245866, 245867, -- Mana Lily Pigment
    245864, 245865, -- Sanguithorn Pigment
    243581, 243582, -- Evercore
    243578, 243579, -- Aetherlume
    253403, -- Thalassian Fillet
  },
}

PM.State = {
  timer = nil,
  active = false,
  activeSpellID = nil,
  capturedSpellID = nil,
  capturedReagents = {},
  preCraftCounts = {},
  preResultCounts = {},
  results = {},
}

PM.Index = {
  ready = false,
  trackedSpells = {},
  trackedReagents = {},
  trackedResults = {},
  categoryByItemID = {},
  professionByItemID = {},
  legacyByItemID = {},
  spellProfessionByID = {},
  spellLegacyByID = {},
  categoryOrder = { "ores", "herbs", "gems", "fish", "recycling", "cloth" },
  professionOrder = { "jewelcrafting", "inscription", "cooking", "engineering", "tailoring" },
}

local function AddSetIndex(destination, values)
  for _, value in ipairs(values) do
    local id = type(value) == "table" and value.id or value
    destination[id] = true
  end
end

function PM.BuildIndexes()
  PM.Index.trackedSpells = {}
  PM.Index.trackedReagents = {}
  PM.Index.trackedResults = {}
  PM.Index.categoryByItemID = {}
  PM.Index.professionByItemID = {}
  PM.Index.legacyByItemID = {}
  PM.Index.spellProfessionByID = {}
  PM.Index.spellLegacyByID = {}

  AddSetIndex(PM.Index.trackedSpells, PM.Data.spells)
  AddSetIndex(PM.Index.trackedResults, PM.Data.resultItems)

  for _, spell in ipairs(PM.Data.spells) do
    local spellID = type(spell) == "table" and spell.id or spell
    PM.Index.spellProfessionByID[spellID] = type(spell) == "table" and spell.profession or nil
    PM.Index.spellLegacyByID[spellID] = type(spell) == "table" and spell.legacy == true or false
  end

  for categoryKey, category in pairs(PM.Data.categories) do
    for _, itemID in ipairs(category.items) do
      local item = type(itemID) == "table" and itemID or { id = itemID }
      PM.Index.trackedReagents[item.id] = true
      PM.Index.categoryByItemID[item.id] = categoryKey
      PM.Index.professionByItemID[item.id] = category.profession
      PM.Index.legacyByItemID[item.id] = category.legacy == true or item.legacy == true
    end
  end

  PM.Index.ready = true
end

function PM.EnsureIndexes()
  if not PM.Index.ready then
    PM.BuildIndexes()
  end
end

local function IsSpellKnown(spellID)
  if C_SpellBook and C_SpellBook.IsSpellKnown then
    local ok, known = pcall(C_SpellBook.IsSpellKnown, spellID)
    if ok and known then
      return true
    end

    ok, known = pcall(C_SpellBook.IsSpellKnown, spellID, true)
    return ok and known == true
  end

  if IsPlayerSpell then
    local ok, known = pcall(IsPlayerSpell, spellID)
    return ok and known == true
  end

  return false
end

function PM.CharacterKnowsProfessionRecipe(professionKey, includeLegacy)
  PM.EnsureIndexes()

  local profession = PM.Data.professions[professionKey]
  if not profession then
    return false
  end

  for _, spellID in ipairs(profession.recipeSpells or {}) do
    if (includeLegacy or not PM.Index.spellLegacyByID[spellID]) and IsSpellKnown(spellID) then
      return true
    end
  end

  return false
end

function PM.CharacterHasProfession(professionKey)
  local profession = PM.Data.professions[professionKey]
  if not profession or not profession.skillLineID or not GetProfessions or not GetProfessionInfo then
    return false
  end

  local ok, prof1, prof2, archaeology, fishing, cooking = pcall(GetProfessions)
  if not ok then
    return false
  end

  local indexes = { prof1, prof2, archaeology, fishing, cooking }
  for indexPosition = 1, 5 do
    local index = indexes[indexPosition]
    if index then
      local infoOk, name, icon, skillLevel, maxSkillLevel, numAbilities, spellOffset, skillLineID = pcall(GetProfessionInfo, index)
      if skillLineID == profession.skillLineID then
        return true
      end
    end
  end

  return false
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
    options = {},
  }

  if type(SmartProspectorDB.reagents) == "table" then
    migrated.reagents = SmartProspectorDB.reagents
  else
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
  end

  if type(SmartProspectorDB.options) == "table" then
    migrated.options = SmartProspectorDB.options
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
    options = type(SmartProspectorDB) == "table" and SmartProspectorDB.options or {},
  }
end

function PM.GetOptions()
  EnsureDB()
  if type(SmartProspectorDB.options) ~= "table" then
    SmartProspectorDB.options = {}
  end

  return SmartProspectorDB.options
end

function PM.ShouldTrackSpell(spellID)
  PM.EnsureIndexes()

  local options = PM.GetOptions()
  return PM.Index.trackedSpells[spellID] == true and (options.showOldRecipes == true or not PM.Index.spellLegacyByID[spellID])
end

local function AddCapturedReagent(itemID)
  PM.EnsureIndexes()

  if itemID and PM.Index.trackedReagents[itemID] then
    PM.State.capturedReagents[itemID] = true

    if PM.State.active and PM.State.preCraftCounts[itemID] == nil then
      PM.State.preCraftCounts[itemID] = PM.GetItemCount(itemID)
    end
  end
end

local function GetItemIDFromItemLocation(itemLocation)
  if not itemLocation then
    return nil
  end

  if C_Item and C_Item.GetItemID then
    local ok, itemID = pcall(C_Item.GetItemID, itemLocation)
    if ok and itemID then
      return itemID
    end
  end

  if itemLocation.GetItemID then
    local ok, itemID = pcall(itemLocation.GetItemID, itemLocation)
    if ok and itemID then
      return itemID
    end
  end

  return nil
end

local function CaptureCraftingReagents(recipeSpellID, craftingReagents)
  if not PM.ShouldTrackSpell(recipeSpellID) then
    return
  end

  if not PM.State.timer and PM.State.capturedSpellID ~= recipeSpellID then
    PM.State.capturedReagents = {}
    PM.State.capturedSpellID = recipeSpellID
  end

  if type(craftingReagents) ~= "table" then
    return
  end

  for _, reagentInfo in ipairs(craftingReagents) do
    local reagent = reagentInfo and (reagentInfo.reagent or reagentInfo)
    AddCapturedReagent(reagent and reagent.itemID)
  end
end

local function CaptureSalvageTarget(recipeSpellID, itemTarget)
  if not PM.ShouldTrackSpell(recipeSpellID) then
    return
  end

  if not PM.State.timer and PM.State.capturedSpellID ~= recipeSpellID then
    PM.State.capturedReagents = {}
    PM.State.capturedSpellID = recipeSpellID
  end

  AddCapturedReagent(GetItemIDFromItemLocation(itemTarget))
end

local function GetItemCounts(itemIDs)
  PM.EnsureIndexes()

  local counts = {}

  for itemID in pairs(itemIDs) do
    counts[itemID] = PM.GetItemCount(itemID)
  end

  return counts
end

local function HasCapturedReagents()
  return next(PM.State.capturedReagents) ~= nil
end

local function GetCraftReagentCounts()
  if HasCapturedReagents() then
    return GetItemCounts(PM.State.capturedReagents)
  end

  return GetItemCounts(PM.Index.trackedReagents)
end

local function GetTrackedResultCounts()
  PM.EnsureIndexes()

  local counts = {}

  for itemID in pairs(PM.Index.trackedResults) do
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

local function FindProducedItems(oldCounts, newCounts)
  local producedItems = {}

  for itemID, newCount in pairs(newCounts) do
    local oldCount = oldCounts[itemID] or 0
    if newCount > oldCount then
      producedItems[itemID] = newCount - oldCount
    end
  end

  return producedItems
end

local function MergeProducedItems()
  local postResultCounts = GetTrackedResultCounts()
  local producedItems = FindProducedItems(PM.State.preResultCounts, postResultCounts)

  for itemID, quantity in pairs(producedItems) do
    PM.State.results[itemID] = math.max(PM.State.results[itemID] or 0, quantity)
  end
end

local function CommitSession()
  local postCraftCounts = GetCraftReagentCounts()
  local consumedItems = FindConsumedItems(PM.State.preCraftCounts, postCraftCounts)

  EnsureDB()
  MergeProducedItems()

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
  PM.State.activeSpellID = nil
  PM.State.capturedSpellID = nil
  PM.State.capturedReagents = {}
  PM.State.preCraftCounts = {}
  PM.State.preResultCounts = {}
  PM.State.results = {}
end

local function StartTrackingSession(spellID)
  if PM.State.active and PM.State.timer then
    if not PM.State.timer:IsCancelled() then
      PM.State.timer:Cancel()
    end
    CommitSession()
  end

  PM.State.active = PM.ShouldTrackSpell(spellID)
  PM.State.activeSpellID = PM.State.active and spellID or nil

  if not PM.State.active then
    PM.State.capturedSpellID = nil
    PM.State.capturedReagents = {}
    return
  end

  if not PM.State.timer then
    if PM.State.capturedSpellID and PM.State.capturedSpellID ~= spellID then
      PM.State.capturedSpellID = nil
      PM.State.capturedReagents = {}
    end

    PM.State.preCraftCounts = GetCraftReagentCounts()
    PM.State.preResultCounts = GetTrackedResultCounts()
  end
end

local function InstallCraftHooks()
  if not hooksecurefunc or not C_TradeSkillUI then
    return
  end

  if C_TradeSkillUI.CraftRecipe then
    hooksecurefunc(C_TradeSkillUI, "CraftRecipe", function(recipeSpellID, numCasts, craftingReagents)
      local reagents = craftingReagents
      if not reagents and type(numCasts) == "table" then
        reagents = numCasts
      end

      CaptureCraftingReagents(recipeSpellID, reagents)
    end)
  end

  if C_TradeSkillUI.CraftSalvage then
    hooksecurefunc(C_TradeSkillUI, "CraftSalvage", function(recipeSpellID, numCasts, itemTarget)
      local target = itemTarget
      if not target and type(numCasts) ~= "number" then
        target = numCasts
      end

      CaptureSalvageTarget(recipeSpellID, target)
    end)
  end
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
      InstallCraftHooks()
    end
    return
  end

  if event == "TRADE_SKILL_CRAFT_BEGIN" then
    local spellID = ...
    StartTrackingSession(spellID)
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
    if unitTarget ~= "player" or not PM.State.active or not PM.ShouldTrackSpell(spellID) then
      return
    end

    if PM.State.timer and not PM.State.timer:IsCancelled() then
      PM.State.timer:Cancel()
    end

    PM.State.timer = C_Timer.NewTimer(PM.SESSION_TIMEOUT, CommitSession)
  end
end)
