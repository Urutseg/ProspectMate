local addonName, PM = ...

local uiElements = {}
local filterState = {
  ores = true,
  herbs = true,
  gems = true,
  cloth = false,
}

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

local function GetCategory(itemID)
  return PM.Index.categoryByItemID[itemID]
end

local function ShouldShowReagent(itemID)
  local category = GetCategory(itemID)
  return category and filterState[category]
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

local function CreateFilterButton(categoryKey, relativeTo)
  local category = PM.Data.categories[categoryKey]
  local checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  checkbox:SetSize(20, 20)
  checkbox:SetChecked(filterState[categoryKey])

  if relativeTo then
    checkbox:SetPoint("LEFT", relativeTo, "RIGHT", 10, 0)
  else
    checkbox:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
  end

  local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
  label:SetText(category.label)

  checkbox:SetScript("OnClick", function(self)
    filterState[categoryKey] = self:GetChecked()
    PM.UpdateUIFrame()
  end)

  return label
end

local lastFilterLabel
for _, categoryKey in ipairs(PM.Index.categoryOrder) do
  lastFilterLabel = CreateFilterButton(categoryKey, lastFilterLabel)
end

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

    local line = CreateText(parent, "GameFontHighlightSmall")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", ROW_PADDING, startY - ((index - 1) * RESULT_LINE_HEIGHT))
    line:SetWidth(ROW_WIDTH - ROW_PADDING * 2)
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

  local itemText = CreateText(panel, "GameFontNormalLarge")
  itemText:SetPoint("TOPLEFT", panel, "TOPLEFT", ROW_PADDING, -10)
  itemText:SetWidth(315)
  itemText:SetJustifyH("LEFT")
  itemText:SetText(GetItemDisplay(row.reagentID))

  local statusText = CreateText(panel, "GameFontNormal")
  statusText:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -ROW_PADDING, -10)
  statusText:SetWidth(165)
  statusText:SetJustifyH("RIGHT")
  statusText:SetText(ColorText(status, statusColor))

  local sampleText = CreateText(panel, "GameFontDisableSmall")
  sampleText:SetPoint("TOPLEFT", itemText, "BOTTOMLEFT", 0, -2)
  sampleText:SetWidth(315)
  sampleText:SetJustifyH("LEFT")
  local priceText = row.reagentPrice and PM.FormatMoney(row.reagentPrice) .. " each" or "No reagent price"
  sampleText:SetText("Sample: " .. row.consumed .. " consumed - " .. priceText)

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
  ClearUIElements()

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

StaticPopupDialogs["PROSPECTMATE_RESET_DATA_CONFIRMATION"] = {
  text = "All ProspectMate data will be deleted if you proceed.",
  button1 = "Confirm",
  button2 = "Cancel",
  timeout = 0,
  OnAccept = function()
    PM.ResetDB()
    PM.UpdateUIFrame()
  end,
  whileDead = true,
  hideOnEscape = true,
}

resetButton:SetScript("OnClick", function()
  StaticPopup_Show("PROSPECTMATE_RESET_DATA_CONFIRMATION")
end)

refreshButton:SetScript("OnClick", function()
  PM.UpdateUIFrame()
end)

frame:SetScript("OnKeyDown", function(self, key)
  if key == "ESCAPE" then
    self:Hide()
  end
end)

SLASH_PROSPECTMATE1 = "/prospectmate"
SlashCmdList["PROSPECTMATE"] = function()
  PM.UpdateUIFrame()
  frame:Show()
end
