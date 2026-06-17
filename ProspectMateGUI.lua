local addonName, PM = ...

local uiElements = {}
local professionFilterState = {}
local professionCheckboxes = {}
local oldRecipesCheckbox
local professionDropdown
local professionDropdownMenu
local resetMenu
local resetMenuElements = {}
local resetOptionChecks = {}
local resetSelection
local resetApplyButton
local HideResetMenu

local COLORS = {
  cyan = "ff00ccff",
  green = "ff4dff2f",
  red = "ffff5050",
  gray = "ff999999",
  white = "ffffffff",
}

local ROW_WIDTH = 660
local ROW_PADDING = 10
local RESULT_LINE_HEIGHT = 18

local function ColorText(text, color)
  return "|c" .. color .. text .. "|r"
end

local function ClearUIElements()
  for _, element in ipairs(uiElements) do
    if element.Hide then
      element:Hide()
    end
    if element.SetParent then
      element:SetParent(nil)
    end
  end

  uiElements = {}
end

local function TrackElement(element)
  table.insert(uiElements, element)
  return element
end

local function CreateText(parent, template)
  return TrackElement(parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight"))
end

local function GetItemSortName(itemID)
  local itemName = PM.GetItemInfo(itemID)
  return itemName or tostring(itemID)
end

local function GetItemDisplay(itemID)
  local itemName, itemLink = PM.GetItemInfo(itemID)
  return itemLink or itemName or ("item:" .. tostring(itemID))
end

local function GetItemIconTexture(itemID)
  if C_Item and C_Item.GetItemIconByID then
    return C_Item.GetItemIconByID(itemID)
  end

  return _G.GetItemIcon and _G.GetItemIcon(itemID)
end

local function RequestItemLoad(itemID)
  if C_Item and C_Item.RequestLoadItemDataByID then
    pcall(C_Item.RequestLoadItemDataByID, itemID)
  end
end

local function ShowItemTooltip(owner, itemID)
  if not GameTooltip or not itemID then
    return
  end

  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  GameTooltip:ClearLines()

  local shown
  if GameTooltip.SetItemByID then
    shown = GameTooltip:SetItemByID(itemID)
  end

  if not shown and GameTooltip.SetHyperlink then
    shown = GameTooltip:SetHyperlink("item:" .. tostring(itemID))
  end

  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Inventory: " .. PM.GetItemCount(itemID), 0.75, 0.75, 0.75)
  GameTooltip:Show()
end

local function HideItemTooltip()
  if GameTooltip then
    GameTooltip:Hide()
  end
end

local function CreateItemHoverFrame(parent, itemID, width, height)
  RequestItemLoad(itemID)

  local hoverFrame = TrackElement(CreateFrame("Frame", nil, parent))
  hoverFrame:SetSize(width, height)
  hoverFrame:EnableMouse(true)
  hoverFrame:SetScript("OnEnter", function(self)
    ShowItemTooltip(self, itemID)
  end)
  hoverFrame:SetScript("OnLeave", HideItemTooltip)

  return hoverFrame
end

local function AddItemIcon(parent, itemID, size)
  local border = TrackElement(parent:CreateTexture(nil, "BACKGROUND"))
  border:SetSize(size + 2, size + 2)
  border:SetColorTexture(0, 0, 0, 0.55)

  local icon = TrackElement(parent:CreateTexture(nil, "ARTWORK"))
  icon:SetSize(size, size)
  icon:SetTexture(GetItemIconTexture(itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  if _G.Item and _G.Item.CreateFromItemID then
    local item = _G.Item:CreateFromItemID(itemID)
    if item and item.ContinueOnItemLoad then
      item:ContinueOnItemLoad(function()
        if icon and icon.SetTexture then
          icon:SetTexture(GetItemIconTexture(itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
        end
      end)
    end
  end

  border:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
  border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)

  return icon
end

local function GetCategory(itemID)
  PM.EnsureIndexes()

  return PM.Index.categoryByItemID[itemID]
end

local function GetCharacterKey()
  local name, realm = UnitFullName and UnitFullName("player")
  if not name or name == "" then
    return "default"
  end

  return name .. "-" .. (realm or GetRealmName() or "")
end

local function GetCharacterOptions()
  local options = PM.GetOptions()
  options.characters = options.characters or {}

  local characterKey = GetCharacterKey()
  options.characters[characterKey] = options.characters[characterKey] or {}

  return options.characters[characterKey]
end

local function HasSavedProfessionFilters(characterOptions)
  return type(characterOptions.professions) == "table"
end

local function SetDefaultProfessionFilters()
  PM.EnsureIndexes()

  local characterOptions = GetCharacterOptions()
  local includeLegacy = PM.GetOptions().showOldRecipes == true

  if HasSavedProfessionFilters(characterOptions) then
    professionFilterState = characterOptions.professions
    return
  end

  professionFilterState = {}

  for _, professionKey in ipairs(PM.Index.professionOrder) do
    local profession = PM.Data.professions[professionKey]
    if profession and (includeLegacy or not profession.legacy) then
      professionFilterState[professionKey] =
        PM.CharacterHasProfession(professionKey) and PM.CharacterKnowsProfessionRecipe(professionKey, includeLegacy)
    end
  end
end

local function SaveProfessionFilters()
  GetCharacterOptions().professions = professionFilterState
end

local function IsProfessionSelected(professionKey)
  return professionFilterState[professionKey] == true
end

local function ShouldShowOldRecipes()
  return PM.GetOptions().showOldRecipes == true
end

local function ShouldShowReagent(itemID)
  PM.EnsureIndexes()

  local category = GetCategory(itemID)
  local professionKey = PM.Index.professionByItemID[itemID]

  if not category or not IsProfessionSelected(professionKey) then
    return false
  end

  return ShouldShowOldRecipes() or not PM.Index.legacyByItemID[itemID]
end

local function IsAuctionatorReady()
  return Auctionator and Auctionator.API and Auctionator.API.v1 and Auctionator.Utilities
end

local function FormatSignedMoney(copper)
  local sign = copper < 0 and "-" or "+"
  return sign .. PM.FormatMoney(math.floor(math.abs(copper) + 0.5))
end

local function FormatPercent(value)
  return string.format("%.1f%%", value or 0)
end

local function CreatePanel(parent, width, height)
  local panel = TrackElement(CreateFrame("Frame", nil, parent))
  panel:SetSize(width, height)

  local bg = TrackElement(panel:CreateTexture(nil, "BACKGROUND"))
  bg:SetAllPoints(panel)
  bg:SetColorTexture(0, 0, 0, 0.22)

  local top = TrackElement(panel:CreateTexture(nil, "BORDER"))
  top:SetHeight(1)
  top:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
  top:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
  top:SetColorTexture(1, 1, 1, 0.18)

  local bottom = TrackElement(panel:CreateTexture(nil, "BORDER"))
  bottom:SetHeight(1)
  bottom:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
  bottom:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
  bottom:SetColorTexture(0, 0, 0, 0.45)

  return panel, bg
end

local frame = CreateFrame("Frame", "ProspectMateFrame", UIParent, "UIPanelDialogTemplate")
frame:SetSize(720, 500)
frame:SetPoint("CENTER")
frame:Hide()
frame:SetMovable(true)
frame:EnableMouse(true)
frame:EnableKeyboard(true)
if frame.SetPropagateKeyboardInput then
  frame:SetPropagateKeyboardInput(true)
end

frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.Title:SetPoint("TOP", frame, "TOP", 0, -10)
frame.Title:SetText("ProspectMate")

frame:SetScript("OnMouseDown", function(self, button)
  if button == "LeftButton" then
    self:StartMoving()
  end
end)

frame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" then
    self:StopMovingOrSizing()
  end
end)

local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
refreshButton:SetSize(100, 25)
refreshButton:SetPoint("TOPRIGHT", -10, -30)
refreshButton:SetText("Refresh")

local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
resetButton:SetPoint("BOTTOMLEFT", 10, 10)
resetButton:SetSize(120, 30)
resetButton:SetText("Reset Data")

local summaryText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
summaryText:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -66)
summaryText:SetWidth(650)
summaryText:SetJustifyH("LEFT")
summaryText:SetText(ColorText("Waiting for data", COLORS.gray))

local function CountSelectedProfessions()
  local selected = 0
  local selectedLabel

  for _, professionKey in ipairs(PM.Index.professionOrder) do
    local profession = PM.Data.professions[professionKey]
    if profession and IsProfessionSelected(professionKey) then
      selected = selected + 1
      selectedLabel = profession.label
    end
  end

  return selected, selectedLabel
end

local function UpdateProfessionDropdownText()
  if not professionDropdown then
    return
  end

  local selected, selectedLabel = CountSelectedProfessions()
  if selected == 0 then
    professionDropdown:SetText("Professions: None")
  elseif selected == 1 then
    professionDropdown:SetText("Profession: " .. selectedLabel)
  else
    professionDropdown:SetText("Professions: " .. selected)
  end
end

local function UpdateProfessionCheckboxes()
  for professionKey, checkbox in pairs(professionCheckboxes) do
    checkbox:SetChecked(IsProfessionSelected(professionKey))
  end
  UpdateProfessionDropdownText()
end

local function CreateProfessionDropdown()
  professionDropdown = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  professionDropdown:SetSize(180, 25)
  professionDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -35)

  professionDropdownMenu = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  professionDropdownMenu:SetSize(190, 18 + (#PM.Index.professionOrder * 24))
  professionDropdownMenu:SetPoint("TOPLEFT", professionDropdown, "BOTTOMLEFT", 0, -2)
  professionDropdownMenu:SetFrameStrata("DIALOG")
  professionDropdownMenu:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  professionDropdownMenu:Hide()

  local previous
  for _, professionKey in ipairs(PM.Index.professionOrder) do
    local profession = PM.Data.professions[professionKey]
    if profession then
      local checkbox = CreateFrame("CheckButton", nil, professionDropdownMenu, "UICheckButtonTemplate")
      checkbox:SetSize(20, 20)
      checkbox:SetChecked(IsProfessionSelected(professionKey))

      if previous then
        checkbox:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -4)
      else
        checkbox:SetPoint("TOPLEFT", professionDropdownMenu, "TOPLEFT", 10, -10)
      end

      local label = professionDropdownMenu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
      label:SetText(profession.label)

      checkbox:SetScript("OnClick", function(self)
        professionFilterState[professionKey] = self:GetChecked()
        SaveProfessionFilters()
        UpdateProfessionDropdownText()
        PM.UpdateUIFrame()
      end)

      professionCheckboxes[professionKey] = checkbox
      previous = checkbox
    end
  end

  professionDropdown:SetScript("OnClick", function()
    HideResetMenu()

    if professionDropdownMenu:IsShown() then
      professionDropdownMenu:Hide()
    else
      professionDropdownMenu:Show()
    end
  end)

  UpdateProfessionDropdownText()
end

local function CreateOldRecipesCheckbox()
  oldRecipesCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  oldRecipesCheckbox:SetSize(20, 20)
  oldRecipesCheckbox:SetPoint("LEFT", professionDropdown, "RIGHT", 14, 0)
  oldRecipesCheckbox:SetChecked(ShouldShowOldRecipes())

  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("LEFT", oldRecipesCheckbox, "RIGHT", 4, 0)
  label:SetText("Show old recipes")

  oldRecipesCheckbox:SetScript("OnClick", function(self)
    PM.GetOptions().showOldRecipes = self:GetChecked()
    PM.UpdateUIFrame()
  end)
end

HideResetMenu = function()
  if resetMenu then
    resetMenu:Hide()
  end
end

local function ClearResetMenuElements()
  for _, element in ipairs(resetMenuElements) do
    if element.Hide then
      element:Hide()
    end
    if element.SetParent then
      element:SetParent(nil)
    end
  end

  resetMenuElements = {}
  resetOptionChecks = {}
  resetSelection = nil
  resetApplyButton = nil
end

local function TrackResetMenuElement(element)
  table.insert(resetMenuElements, element)
  return element
end

local function UpdateResetSelection()
  for _, option in ipairs(resetOptionChecks) do
    option.checkbox:SetChecked(resetSelection and option.selectionType == resetSelection.selectionType and option.id == resetSelection.id)
  end

  if resetApplyButton then
    resetApplyButton:SetEnabled(resetSelection ~= nil)
  end
end

local function SelectResetTarget(selectionType, id, label)
  resetSelection = {
    selectionType = selectionType,
    id = id,
    label = label,
  }
  UpdateResetSelection()
end

local function AddResetOption(parent, text, yOffset, indent, selectionType, id, label, fontTemplate)
  local checkbox = TrackResetMenuElement(CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate"))
  checkbox:SetSize(20, 20)
  checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", indent, yOffset)

  local optionLabel = TrackResetMenuElement(parent:CreateFontString(nil, "OVERLAY", fontTemplate or "GameFontHighlightSmall"))
  optionLabel:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
  optionLabel:SetWidth(250 - indent)
  optionLabel:SetJustifyH("LEFT")
  optionLabel:SetWordWrap(false)
  optionLabel:SetText(text)

  local clickTarget = TrackResetMenuElement(CreateFrame("Button", nil, parent))
  clickTarget:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 0, 0)
  clickTarget:SetSize(292 - indent, 20)
  clickTarget:SetScript("OnClick", function()
    SelectResetTarget(selectionType, id, label)
  end)

  checkbox:SetScript("OnClick", function()
    SelectResetTarget(selectionType, id, label)
  end)

  table.insert(resetOptionChecks, {
    checkbox = checkbox,
    selectionType = selectionType,
    id = id,
  })

  return yOffset - 22
end

local function BuildResetProfessionRows()
  PM.EnsureIndexes()

  local rowsByProfession = {}

  for reagentID, row in pairs(PM.GetReagentRows()) do
    local professionKey = PM.Index.professionByItemID[reagentID]
    if professionKey and row and (row.consumed or 0) > 0 then
      rowsByProfession[professionKey] = rowsByProfession[professionKey] or {}
      table.insert(rowsByProfession[professionKey], {
        itemID = reagentID,
        label = GetItemDisplay(reagentID),
        sortName = GetItemSortName(reagentID),
      })
      RequestItemLoad(reagentID)
    end
  end

  for _, rows in pairs(rowsByProfession) do
    table.sort(rows, function(a, b)
      return a.sortName < b.sortName
    end)
  end

  return rowsByProfession
end

local function PopulateResetMenu()
  ClearResetMenuElements()

  local title = TrackResetMenuElement(resetMenu:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
  title:SetPoint("TOPLEFT", resetMenu, "TOPLEFT", 14, -12)
  title:SetText("Reset saved data")

  local resetAllButton = TrackResetMenuElement(CreateFrame("Button", nil, resetMenu, "UIPanelButtonTemplate"))
  resetAllButton:SetSize(140, 22)
  resetAllButton:SetPoint("TOPRIGHT", resetMenu, "TOPRIGHT", -12, -8)
  resetAllButton:SetText("Reset Everything")
  resetAllButton:SetScript("OnClick", function()
    HideResetMenu()
    StaticPopup_Show("PROSPECTMATE_RESET_ALL_CONFIRMATION")
  end)

  local helpText = TrackResetMenuElement(resetMenu:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"))
  helpText:SetPoint("TOPLEFT", resetMenu, "TOPLEFT", 14, -42)
  helpText:SetWidth(300)
  helpText:SetJustifyH("LEFT")
  helpText:SetText("Select a profession or one source item, then confirm.")

  local scrollFrame = TrackResetMenuElement(CreateFrame("ScrollFrame", nil, resetMenu, "UIPanelScrollFrameTemplate"))
  scrollFrame:SetSize(304, 235)
  scrollFrame:SetPoint("TOPLEFT", resetMenu, "TOPLEFT", 12, -68)

  local child = TrackResetMenuElement(CreateFrame("Frame", nil, scrollFrame))
  child:SetSize(286, 235)
  scrollFrame:SetScrollChild(child)

  local rowsByProfession = BuildResetProfessionRows()
  local yOffset = -4
  local hasRows = false

  for _, professionKey in ipairs(PM.Index.professionOrder) do
    local profession = PM.Data.professions[professionKey]
    local itemRows = rowsByProfession[professionKey]

    if profession and itemRows and #itemRows > 0 then
      hasRows = true
      yOffset = AddResetOption(child, profession.label, yOffset, 4, "profession", professionKey, profession.label, "GameFontNormal")

      for _, row in ipairs(itemRows) do
        yOffset = AddResetOption(child, row.label, yOffset, 28, "item", row.itemID, row.label, "GameFontHighlightSmall")
      end
    end
  end

  if not hasRows then
    local emptyText = TrackResetMenuElement(child:CreateFontString(nil, "OVERLAY", "GameFontDisable"))
    emptyText:SetPoint("TOPLEFT", child, "TOPLEFT", 8, -8)
    emptyText:SetWidth(260)
    emptyText:SetJustifyH("LEFT")
    emptyText:SetText("No saved sample data to reset.")
    yOffset = -42
  end

  child:SetHeight(math.max(235, math.abs(yOffset) + 8))

  resetApplyButton = TrackResetMenuElement(CreateFrame("Button", nil, resetMenu, "UIPanelButtonTemplate"))
  resetApplyButton:SetSize(116, 24)
  resetApplyButton:SetPoint("BOTTOMRIGHT", resetMenu, "BOTTOMRIGHT", -12, 12)
  resetApplyButton:SetText("Reset Selected")
  resetApplyButton:SetScript("OnClick", function()
    if not resetSelection then
      return
    end

    HideResetMenu()
    if resetSelection.selectionType == "profession" then
      StaticPopup_Show("PROSPECTMATE_RESET_PROFESSION_CONFIRMATION", resetSelection.label, nil, {
        professionKey = resetSelection.id,
      })
    elseif resetSelection.selectionType == "item" then
      StaticPopup_Show("PROSPECTMATE_RESET_ITEM_CONFIRMATION", resetSelection.label, nil, {
        itemID = resetSelection.id,
      })
    end
  end)

  local cancelButton = TrackResetMenuElement(CreateFrame("Button", nil, resetMenu, "UIPanelButtonTemplate"))
  cancelButton:SetSize(80, 24)
  cancelButton:SetPoint("RIGHT", resetApplyButton, "LEFT", -8, 0)
  cancelButton:SetText("Cancel")
  cancelButton:SetScript("OnClick", HideResetMenu)

  UpdateResetSelection()
end

local function CreateResetMenu()
  resetMenu = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  resetMenu:SetSize(340, 345)
  resetMenu:SetPoint("BOTTOMLEFT", resetButton, "TOPLEFT", 0, 2)
  resetMenu:SetFrameStrata("DIALOG")
  resetMenu:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  resetMenu:Hide()
end

CreateProfessionDropdown()
CreateOldRecipesCheckbox()
CreateResetMenu()

local scrollFrame = CreateFrame("ScrollFrame", "ProspectMateScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(680, 365)
scrollFrame:SetPoint("TOPLEFT", 10, -92)

local childFrame = CreateFrame("Frame", "ProspectMateChildFrame", scrollFrame)
childFrame:SetSize(680, 365)
scrollFrame:SetScrollChild(childFrame)

local function AddEmptyState(parent, message)
  local emptyText = CreateText(parent, "GameFontDisable")
  emptyText:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
  emptyText:SetWidth(620)
  emptyText:SetJustifyH("LEFT")
  emptyText:SetText(message)
end

local function BuildResultRows(results)
  local rows = {}

  for itemID, count in pairs(results or {}) do
    local price = PM.GetAuctionPrice(itemID)
    table.insert(rows, {
      itemID = itemID,
      count = count,
      price = price,
      value = (price or 0) * count,
      sortName = GetItemSortName(itemID),
    })
  end

  table.sort(rows, function(a, b)
    if a.value ~= b.value then
      return a.value > b.value
    end

    return a.sortName < b.sortName
  end)

  return rows
end

local function BuildRows()
  local rows = {}

  for reagentID, row in pairs(PM.GetReagentRows()) do
    local consumed = row.consumed or 0

    if ShouldShowReagent(reagentID) and consumed > 0 then
      local reagentPrice = PM.GetAuctionPrice(reagentID)
      local resultRows = BuildResultRows(row.results)
      local totalReturn = 0

      for _, result in ipairs(resultRows) do
        totalReturn = totalReturn + result.value
      end

      local cost = (reagentPrice or 0) * consumed
      local profitPer100
      local roi

      if reagentPrice then
        profitPer100 = (totalReturn - cost) * 100 / consumed
        roi = cost > 0 and ((totalReturn - cost) / cost * 100) or 0
      end

      table.insert(rows, {
        reagentID = reagentID,
        consumed = consumed,
        reagentPrice = reagentPrice,
        resultRows = resultRows,
        totalReturn = totalReturn,
        cost = cost,
        profitPer100 = profitPer100,
        roi = roi,
        sortName = GetItemSortName(reagentID),
      })
    end
  end

  table.sort(rows, function(a, b)
    local aProfit = a.profitPer100 or -math.huge
    local bProfit = b.profitPer100 or -math.huge

    if aProfit ~= bProfit then
      return aProfit > bProfit
    end

    return a.sortName < b.sortName
  end)

  return rows
end

local function GetOpportunity(row)
  if not row.profitPer100 then
    return "Unknown", COLORS.gray, 0.18, 0.18, 0.18
  end

  if row.profitPer100 > 0 then
    return "Pursue", COLORS.green, 0.04, 0.20, 0.05
  end

  return "Avoid", COLORS.red, 0.22, 0.04, 0.04
end

local function AddMetric(parent, label, value, x, y, width, color)
  local labelText = CreateText(parent, "GameFontDisableSmall")
  labelText:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  labelText:SetWidth(width)
  labelText:SetJustifyH("LEFT")
  labelText:SetText(label)

  local valueText = CreateText(parent, "GameFontHighlight")
  valueText:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -2)
  valueText:SetWidth(width)
  valueText:SetJustifyH("LEFT")
  valueText:SetWordWrap(false)
  valueText:SetText(color and ColorText(value, color) or value)
end

local function AddResultLines(parent, row, startY)
  local visibleResults = math.min(#row.resultRows, 4)

  if visibleResults == 0 then
    local noResults = CreateText(parent, "GameFontDisableSmall")
    noResults:SetPoint("TOPLEFT", parent, "TOPLEFT", ROW_PADDING, startY)
    noResults:SetWidth(ROW_WIDTH - ROW_PADDING * 2)
    noResults:SetJustifyH("LEFT")
    noResults:SetText("No tracked yield yet")
    return startY - RESULT_LINE_HEIGHT
  end

  for index = 1, visibleResults do
    local result = row.resultRows[index]
    local resultText = GetItemDisplay(result.itemID) .. " x" .. result.count

    if result.price then
      resultText = resultText .. "  " .. ColorText(PM.FormatMoney(result.price) .. " each", COLORS.gray)
    end

    local resultFrame = CreateItemHoverFrame(parent, result.itemID, ROW_WIDTH - ROW_PADDING * 2, RESULT_LINE_HEIGHT)
    resultFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", ROW_PADDING, startY - ((index - 1) * RESULT_LINE_HEIGHT))

    local icon = AddItemIcon(resultFrame, result.itemID, 14)
    icon:SetPoint("LEFT", resultFrame, "LEFT", 0, 0)

    local line = CreateText(resultFrame, "GameFontHighlightSmall")
    line:SetPoint("LEFT", icon, "RIGHT", 5, 0)
    line:SetWidth(ROW_WIDTH - ROW_PADDING * 2 - 22)
    line:SetJustifyH("LEFT")
    line:SetText(resultText)
  end

  if #row.resultRows > visibleResults then
    local more = CreateText(parent, "GameFontDisableSmall")
    more:SetPoint("TOPLEFT", parent, "TOPLEFT", ROW_PADDING, startY - (visibleResults * RESULT_LINE_HEIGHT))
    more:SetWidth(ROW_WIDTH - ROW_PADDING * 2)
    more:SetJustifyH("LEFT")
    more:SetText("+" .. (#row.resultRows - visibleResults) .. " more results")
    return startY - ((visibleResults + 1) * RESULT_LINE_HEIGHT)
  end

  return startY - (visibleResults * RESULT_LINE_HEIGHT)
end

local function AddOpportunityRow(parent, row, yOffset)
  local status, statusColor, bgR, bgG, bgB = GetOpportunity(row)
  local rowHeight = 126

  if #row.resultRows > 4 then
    rowHeight = 168
  elseif #row.resultRows == 4 then
    rowHeight = 150
  elseif #row.resultRows <= 1 then
    rowHeight = 108
  end

  local panel, bg = CreatePanel(parent, ROW_WIDTH, rowHeight)
  panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, yOffset)
  bg:SetColorTexture(bgR, bgG, bgB, 0.28)

  local accent = TrackElement(panel:CreateTexture(nil, "ARTWORK"))
  accent:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
  accent:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
  accent:SetWidth(4)
  if row.profitPer100 and row.profitPer100 > 0 then
    accent:SetColorTexture(0.20, 0.95, 0.18, 0.85)
  elseif row.profitPer100 then
    accent:SetColorTexture(0.95, 0.10, 0.10, 0.85)
  else
    accent:SetColorTexture(0.45, 0.45, 0.45, 0.85)
  end

  local itemFrame = CreateItemHoverFrame(panel, row.reagentID, 330, 32)
  itemFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", ROW_PADDING, -9)

  local itemIcon = AddItemIcon(itemFrame, row.reagentID, 28)
  itemIcon:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", 0, 0)

  local itemText = CreateText(itemFrame, "GameFontNormalLarge")
  itemText:SetPoint("TOPLEFT", itemIcon, "TOPRIGHT", 8, 0)
  itemText:SetWidth(285)
  itemText:SetJustifyH("LEFT")
  itemText:SetText(GetItemDisplay(row.reagentID))

  local statusText = CreateText(panel, "GameFontNormal")
  statusText:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -ROW_PADDING, -10)
  statusText:SetWidth(165)
  statusText:SetJustifyH("RIGHT")
  statusText:SetText(ColorText(status, statusColor))

  local sampleText = CreateText(itemFrame, "GameFontDisableSmall")
  sampleText:SetPoint("TOPLEFT", itemText, "BOTTOMLEFT", 0, -2)
  sampleText:SetWidth(285)
  sampleText:SetJustifyH("LEFT")
  local priceText = row.reagentPrice and PM.FormatMoney(row.reagentPrice) .. " each" or "No reagent price"
  sampleText:SetText("Sample: " .. row.consumed .. " consumed - " .. priceText .. " - Have: " .. PM.GetItemCount(row.reagentID))

  local profitText = row.profitPer100 and FormatSignedMoney(row.profitPer100) or "No price"
  local profitColor = row.profitPer100 and (row.profitPer100 >= 0 and COLORS.green or COLORS.red) or COLORS.gray

  AddMetric(panel, "Profit / 100", profitText, 355, -38, 130, profitColor)
  AddMetric(panel, "ROI", row.roi and FormatPercent(row.roi) or "No price", 490, -38, 75, profitColor)
  AddMetric(panel, "Yield Value", PM.FormatMoney(row.totalReturn), 570, -38, 80, COLORS.white)

  local divider = TrackElement(panel:CreateTexture(nil, "ARTWORK"))
  divider:SetHeight(1)
  divider:SetPoint("TOPLEFT", panel, "TOPLEFT", ROW_PADDING, -70)
  divider:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -ROW_PADDING, -70)
  divider:SetColorTexture(1, 1, 1, 0.14)

  AddResultLines(panel, row, -80)

  return yOffset - rowHeight - 8
end

local function UpdateSummary(rows)
  if #rows == 0 then
    summaryText:SetText(ColorText("No tracked data for the selected filters yet.", COLORS.gray))
    return
  end

  local best = rows[1]
  local profitable = 0

  for _, row in ipairs(rows) do
    if row.profitPer100 and row.profitPer100 > 0 then
      profitable = profitable + 1
    end
  end

  if best.profitPer100 then
    local bestText = GetItemDisplay(best.reagentID) .. "  " .. FormatSignedMoney(best.profitPer100) .. " per 100"
    summaryText:SetText(
      ColorText("Best: ", COLORS.cyan) ..
      ColorText(bestText, best.profitPer100 >= 0 and COLORS.green or COLORS.red) ..
      ColorText("   " .. profitable .. "/" .. #rows .. " profitable", COLORS.gray)
    )
  else
    summaryText:SetText(ColorText("No Auctionator prices found for the selected data.", COLORS.gray))
  end
end

function PM.UpdateUIFrame()
  PM.EnsureIndexes()

  ClearUIElements()
  SetDefaultProfessionFilters()
  UpdateProfessionCheckboxes()
  if oldRecipesCheckbox then
    oldRecipesCheckbox:SetChecked(ShouldShowOldRecipes())
  end

  if not IsAuctionatorReady() then
    summaryText:SetText(ColorText("Auctionator required", COLORS.red))
    AddEmptyState(childFrame, "Auctionator is required for ProspectMate pricing. Enable Auctionator, then reload your UI.")
    return
  end

  local rows = BuildRows()
  UpdateSummary(rows)

  if #rows == 0 then
    AddEmptyState(childFrame, "No tracked data for the selected filters yet.")
    return
  end

  local yOffset = -4
  for _, row in ipairs(rows) do
    yOffset = AddOpportunityRow(childFrame, row, yOffset)
  end

  childFrame:SetHeight(math.max(365, math.abs(yOffset) + 20))
end

StaticPopupDialogs["PROSPECTMATE_RESET_ALL_CONFIRMATION"] = {
  text = "All saved ProspectMate sample data will be deleted. Filters and options will be kept.",
  button1 = "Reset All",
  button2 = "Cancel",
  timeout = 0,
  OnAccept = function()
    PM.ResetDB()
    PM.UpdateUIFrame()
  end,
  whileDead = true,
  hideOnEscape = true,
}

StaticPopupDialogs["PROSPECTMATE_RESET_PROFESSION_CONFIRMATION"] = {
  text = "Delete all saved ProspectMate sample data for %s?",
  button1 = "Reset",
  button2 = "Cancel",
  timeout = 0,
  OnAccept = function(self, data)
    if data and data.professionKey then
      PM.ResetProfessionData(data.professionKey)
      PM.UpdateUIFrame()
    end
  end,
  whileDead = true,
  hideOnEscape = true,
}

StaticPopupDialogs["PROSPECTMATE_RESET_ITEM_CONFIRMATION"] = {
  text = "Delete saved ProspectMate sample data for %s?",
  button1 = "Reset",
  button2 = "Cancel",
  timeout = 0,
  OnAccept = function(self, data)
    if data and data.itemID then
      PM.ResetItemData(data.itemID)
      PM.UpdateUIFrame()
    end
  end,
  whileDead = true,
  hideOnEscape = true,
}

resetButton:SetScript("OnClick", function()
  if professionDropdownMenu and professionDropdownMenu:IsShown() then
    professionDropdownMenu:Hide()
  end

  if resetMenu:IsShown() then
    resetMenu:Hide()
  else
    PopulateResetMenu()
    resetMenu:Show()
  end
end)

refreshButton:SetScript("OnClick", function()
  HideResetMenu()
  PM.UpdateUIFrame()
end)

frame:SetScript("OnKeyDown", function(self, key)
  if key == "ESCAPE" then
    HideResetMenu()
    self:Hide()
  end
end)

SLASH_PROSPECTMATE1 = "/prospectmate"
SlashCmdList["PROSPECTMATE"] = function()
  HideResetMenu()
  frame:Show()
  PM.UpdateUIFrame()
end
