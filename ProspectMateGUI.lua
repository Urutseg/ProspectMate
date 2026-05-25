local addonName, PM = ...

local uiElements = {}
local filterButtons = {}
local filterState = {
  ores = true,
  herbs = true,
  gems = true,
  cloth = false,
}

local COLUMN_WIDTHS = {
  item = 190,
  yield = 310,
  profit = 150,
}

local function ClearUIElements()
  for _, element in ipairs(uiElements) do
    element:Hide()
    element:SetParent(nil)
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

local frame = CreateFrame("Frame", "ProspectMateFrame", UIParent, "UIPanelDialogTemplate")
frame:SetSize(720, 470)
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

  filterButtons[categoryKey] = checkbox
  return label
end

local lastFilterLabel
for _, categoryKey in ipairs(PM.Index.categoryOrder) do
  lastFilterLabel = CreateFilterButton(categoryKey, lastFilterLabel)
end

local headerItem = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerItem:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -60)
headerItem:SetWidth(COLUMN_WIDTHS.item)
headerItem:SetJustifyH("LEFT")
headerItem:SetText("|cff00ccffItem|r")

local headerYield = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerYield:SetPoint("TOPLEFT", headerItem, "TOPRIGHT", 10, 0)
headerYield:SetWidth(COLUMN_WIDTHS.yield)
headerYield:SetJustifyH("LEFT")
headerYield:SetText("|cff00ccffYield|r")

local headerProfit = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerProfit:SetPoint("TOPLEFT", headerYield, "TOPRIGHT", 10, 0)
headerProfit:SetWidth(COLUMN_WIDTHS.profit)
headerProfit:SetJustifyH("LEFT")
headerProfit:SetText("|cff00ccffProfit|r")

local headerDivider = frame:CreateTexture(nil, "ARTWORK")
headerDivider:SetHeight(1)
headerDivider:SetColorTexture(1, 1, 1, 0.5)
headerDivider:SetPoint("TOPLEFT", headerItem, "BOTTOMLEFT", -5, -5)
headerDivider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -25, -65)

local scrollFrame = CreateFrame("ScrollFrame", "ProspectMateScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(680, 340)
scrollFrame:SetPoint("TOPLEFT", 10, -80)

local childFrame = CreateFrame("Frame", "ProspectMateChildFrame", scrollFrame)
childFrame:SetSize(680, 340)
scrollFrame:SetScrollChild(childFrame)

local function AddDivider(parent, anchor, yOffset)
  local divider = TrackElement(parent:CreateTexture(nil, "ARTWORK"))
  divider:SetHeight(1)
  divider:SetColorTexture(1, 1, 1, 0.35)
  divider:SetPoint("TOPLEFT", anchor, "TOPLEFT", -5, yOffset)
  divider:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -5, yOffset)
end

local function AddEmptyState(parent, message)
  local emptyText = CreateText(parent, "GameFontDisable")
  emptyText:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
  emptyText:SetWidth(620)
  emptyText:SetJustifyH("LEFT")
  emptyText:SetText(message)
end

local function BuildRows()
  local rows = {}

  for reagentID, row in pairs(PM.GetReagentRows()) do
    if ShouldShowReagent(reagentID) and row.consumed and row.consumed > 0 then
      table.insert(rows, {
        reagentID = reagentID,
        data = row,
        sortName = GetItemSortName(reagentID),
      })
    end
  end

  table.sort(rows, function(a, b)
    return a.sortName < b.sortName
  end)

  return rows
end

local function BuildResultRows(results)
  local rows = {}

  for itemID, count in pairs(results or {}) do
    table.insert(rows, {
      itemID = itemID,
      count = count,
      sortName = GetItemSortName(itemID),
    })
  end

  table.sort(rows, function(a, b)
    return a.sortName < b.sortName
  end)

  return rows
end

local function AddReagentRow(parent, row, yOffset)
  local reagentID = row.reagentID
  local consumed = row.data.consumed or 0
  local reagentPrice = PM.GetAuctionPrice(reagentID)
  local totalReturn = 0

  local rowHeader = CreateText(parent)
  rowHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
  rowHeader:SetWidth(COLUMN_WIDTHS.item)
  rowHeader:SetJustifyH("LEFT")

  local headerText = GetItemDisplay(reagentID) .. ": " .. consumed
  if reagentPrice then
    headerText = headerText .. "\n(" .. PM.FormatMoney(reagentPrice) .. ")"
  end
  rowHeader:SetText(headerText)

  AddDivider(parent, rowHeader, 5)

  local resultYOffset = 0
  local resultRows = BuildResultRows(row.data.results)

  if #resultRows == 0 then
    local emptyYield = CreateText(parent, "GameFontDisable")
    emptyYield:SetPoint("TOPLEFT", rowHeader, "TOPRIGHT", 10, resultYOffset)
    emptyYield:SetWidth(COLUMN_WIDTHS.yield)
    emptyYield:SetJustifyH("LEFT")
    emptyYield:SetText("No tracked yield yet")
    resultYOffset = resultYOffset - 20
  end

  for _, result in ipairs(resultRows) do
    local resultPrice = PM.GetAuctionPrice(result.itemID)
    local rowText = GetItemDisplay(result.itemID) .. ": " .. result.count

    if resultPrice then
      rowText = rowText .. " (" .. PM.FormatMoney(resultPrice) .. ")"
      totalReturn = totalReturn + (resultPrice * result.count)
    end

    local rowData = CreateText(parent)
    rowData:SetPoint("TOPLEFT", rowHeader, "TOPRIGHT", 10, resultYOffset)
    rowData:SetWidth(COLUMN_WIDTHS.yield)
    rowData:SetJustifyH("LEFT")
    rowData:SetText(rowText)

    resultYOffset = resultYOffset - 20
  end

  local profitText = CreateText(parent)
  profitText:SetPoint("TOPLEFT", rowHeader, "TOPRIGHT", 10 + COLUMN_WIDTHS.yield, -5)
  profitText:SetWidth(COLUMN_WIDTHS.profit)
  profitText:SetJustifyH("LEFT")

  if reagentPrice and consumed > 0 then
    local profit = (totalReturn - reagentPrice * consumed) * 100 / consumed
    local label = profit < 0 and "Loss" or "Profit"
    profitText:SetText(label .. " per 100: " .. PM.FormatMoney(profit))
  else
    profitText:SetText("|cff999999No price|r")
  end

  return yOffset + math.min(-45, resultYOffset - 25)
end

function PM.UpdateUIFrame()
  ClearUIElements()

  if not IsAuctionatorReady() then
    AddEmptyState(childFrame, "Auctionator is required for ProspectMate pricing. Enable Auctionator, then reload your UI.")
    return
  end

  local rows = BuildRows()
  if #rows == 0 then
    AddEmptyState(childFrame, "No tracked data for the selected filters yet.")
    return
  end

  local yOffset = -10
  for _, row in ipairs(rows) do
    yOffset = AddReagentRow(childFrame, row, yOffset)
  end

  childFrame:SetHeight(math.max(340, math.abs(yOffset) + 30))
end

local resetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
resetButton:SetPoint("BOTTOMLEFT", 10, 10)
resetButton:SetSize(120, 30)
resetButton:SetText("Reset Data")

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
