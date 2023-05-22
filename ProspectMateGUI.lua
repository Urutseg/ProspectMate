local addonName, addonTable = ...

-- Keep track of the created UI elements
local uiElements = {}

-- Set column widths
local columnWidths = {
    rowHeader = 170,
    rowValue = 300,
    profitValue = 150
}

-- Function to clear existing UI elements
local function ClearUIElements()
    for _, element in ipairs(uiElements) do
        if element.SetText then     -- Check if the element has a SetText method
            element:SetText("")     -- Clear the text of the font string
            element:Hide()          -- Hide the font string
        end
        if element.SetTexture then  -- Check if the element has a SetTexture method
            element:SetTexture(nil) -- Clear the texture of the divider
        end
        element:SetParent(nil)      -- Remove the element from its parent frame
    end
    uiElements = {}                 -- Clear the uiElements table
end


local function CreateRowHeader(frame, yOffset, reagentLink)
    local rowHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    table.insert(uiElements, rowHeader) -- Add the font string to the list of UI elements

    rowHeader:SetPoint("TOPLEFT", 10, yOffset)
    rowHeader:SetWidth(columnWidths.rowHeader)
    rowHeader:SetJustifyH("LEFT") -- Set text justification to left
    rowHeader:SetText(reagentLink)

    return rowHeader
end

local function IsValueInTable(value, tableToCheck)
    for _, entry in pairs(tableToCheck) do
        if entry == value then
            return true
        end
    end
    return false
end

-- Create the main frame for the table
local frame = CreateFrame("Frame", "ProspectMateFrame", UIParent, "UIPanelDialogTemplate")
frame:SetSize(700, 460)
frame:SetPoint("CENTER")
frame:Hide()

frame:SetMovable(true)  -- Make the frame movable
frame:EnableMouse(true) -- Allow the user to interact with the frame

-- Create a title bar for the frame
frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.Title:SetPoint("TOP", frame, "TOP", 0, -10)
frame.Title:SetText("ProspectMate")

-- Set up the drag functionality for the frame
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

-- Create the refresh button
local refreshButton = CreateFrame("Button", "ProspectMateRefreshButton", frame, "UIPanelButtonTemplate")
refreshButton:SetSize(100, 25)
refreshButton:SetPoint("TOPRIGHT", -10, -30)
refreshButton:SetText("Refresh")

-- Create the checkboxes
local checkboxOre = CreateFrame("CheckButton", "ProspectMateCheckbox", frame, "UICheckButtonTemplate")
checkboxOre:SetSize(20, 20)
checkboxOre:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
-- checkboxOre:SetChecked(true)
local checkboxOreLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
checkboxOreLabel:SetPoint("LEFT", checkboxOre, "RIGHT", 5, 0)
checkboxOreLabel:SetText("Ore")

local checkboxHerb = CreateFrame("CheckButton", "ProspectMateCheckbox", frame, "UICheckButtonTemplate")
checkboxHerb:SetSize(20, 20)
checkboxHerb:SetPoint("LEFT", checkboxOreLabel, "RIGHT", 10, 0)
-- checkboxHerb:SetChecked(true)
local checkboxHerbLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
checkboxHerbLabel:SetPoint("LEFT", checkboxHerb, "RIGHT", 5, 0)
checkboxHerbLabel:SetText("Herbs")

local checkboxGem = CreateFrame("CheckButton", "ProspectMateCheckbox", frame, "UICheckButtonTemplate")
checkboxGem:SetSize(20, 20)
checkboxGem:SetPoint("LEFT", checkboxHerbLabel, "RIGHT", 10, 0)
-- checkboxGem:SetChecked(true)
local checkboxGemLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
checkboxGemLabel:SetPoint("LEFT", checkboxGem, "RIGHT", 5, 0)
checkboxGemLabel:SetText("Gems")

local checkboxCloth = CreateFrame("CheckButton", "ProspectMateCheckbox", frame, "UICheckButtonTemplate")
checkboxCloth:SetSize(20, 20)
checkboxCloth:SetPoint("LEFT", checkboxGemLabel, "RIGHT", 10, 0)
-- checkboxGem:SetChecked(true)
local checkboxClothLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
checkboxClothLabel:SetPoint("LEFT", checkboxCloth, "RIGHT", 5, 0)
checkboxClothLabel:SetText("Cloth")

local function UpdateUIFrame(frameToUpdate)
    -- Clear existing UI elements
    ClearUIElements()

    -- Loop through the prospecting data and add rows to the table
    local yOffsetHeader = -20
    local showItem = false
    local sortedRows = {}
    for reagentID, results in pairs(SmartProspectorDB) do
        -- Check the state of the checkboxes and determine if the item should be shown
        if (IsValueInTable(reagentID, Ores) and checkboxOre:GetChecked()) or
            (IsValueInTable(reagentID, Herbs) and checkboxHerb:GetChecked()) or
            (IsValueInTable(reagentID, Gems) and checkboxGem:GetChecked()) or
            (IsValueInTable(reagentID, Cloth) and checkboxCloth:GetChecked()) then
            showItem = true
        end

        -- inserting the reagents into interim table to sort them and display sorted.
        if showItem then
            local reagentName, reagentLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(reagentID)
            table.insert(sortedRows, { reagentID = reagentID, reagentLink = reagentLink })
        end
        -- Resetting the value
        showItem = false
    end

    table.sort(sortedRows, function(a, b)
        local aLink = a.reagentLink or ""  -- Use an empty string if a.reagentLink is nil
        local bLink = b.reagentLink or ""  -- Use an empty string if b.reagentLink is nil
        return aLink < bLink
    end)

    for _, row in ipairs(sortedRows) do
        -- Retrieve the necessary data from the row table
        local reagentID = row.reagentID
        local results = SmartProspectorDB[reagentID]
        local reagentName, reagentLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(reagentID)
        if reagentName then
            local reagentCount = results[reagentID]
            local headerText = reagentLink .. ": " .. reagentCount
            local reagentPrice = Auctionator.API.v1.GetAuctionPriceByItemID(addonName, reagentID)
            if reagentPrice then
                headerText = headerText ..
                    "\n(" .. Auctionator.Utilities.CreatePaddedMoneyString(reagentPrice) .. ")"
            end
            local rowHeader = CreateRowHeader(frameToUpdate, yOffsetHeader, headerText)
            local yOffsetRow = 0
            local totalReturn = 0

            for itemID, count in pairs(results) do
                -- if the data is about consumed material, we skip it, since it's already in the first column
                if itemID ~= reagentID then
                    local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
                    if itemName then
                        local rowText = itemLink .. ": " .. count
                        local resultPrice = Auctionator.API.v1.GetAuctionPriceByItemID(addonName, itemID)
                        if resultPrice then
                            rowText = rowText ..
                                " (" .. Auctionator.Utilities.CreatePaddedMoneyString(resultPrice) .. ")"
                            totalReturn = resultPrice * count + totalReturn
                        end
                        local rowData = frameToUpdate:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        table.insert(uiElements, rowData)     -- Add the font string to the list of UI elements
                        rowData:SetPoint("TOPLEFT", rowHeader, "TOPRIGHT", 10, yOffsetRow)
                        rowData:SetWidth(columnWidths.rowValue)
                        rowData:SetJustifyH("LEFT")     -- Set text justification to left
                        rowData:SetText(rowText)

                        -- Calculate the dynamic yOffset based on the font string height
                        local _, rowItemHeight = rowData:GetFont()
                        yOffsetHeader = yOffsetHeader - rowItemHeight - 5     -- Adjust the value based on your font size
                        yOffsetRow = yOffsetRow - rowItemHeight - 5           -- Adjust the value based on your font size
                    end
                end
            end

            if reagentPrice then
                -- Create profit column
                local returnData = frameToUpdate:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                table.insert(uiElements, returnData)     -- Add the font string to the list of UI elements
                returnData:SetPoint("TOPLEFT", rowHeader, "TOPRIGHT", 10 + columnWidths.rowValue, -5)
                returnData:SetWidth(columnWidths.profitValue)
                returnData:SetJustifyH("LEFT")     -- Set text justification to left
                local profit = (totalReturn - reagentPrice * reagentCount) * 100 / reagentCount
                local profitGold = Auctionator.Utilities.CreatePaddedMoneyString(profit)
                local profitLoss = profit < 0 and "Loss" or "Profit"
                local profitability = profitLoss .. " per 100: " .. profitGold

                local profitText =
                    returnData:SetText(profitability)
            end

            -- Create a horizontal divider
            local dividerTexture = frameToUpdate:CreateTexture(nil, "ARTWORK")
            table.insert(uiElements, dividerTexture)         -- Add the texture to the list of UI elements
            dividerTexture:SetHeight(1)
            dividerTexture:SetColorTexture(1, 1, 1, 0.5)     -- Adjust the color and transparency as desired
            dividerTexture:SetPoint("TOPLEFT", rowHeader, "TOPLEFT", -5, 5)
            dividerTexture:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 5, 5)

            -- Increase the yOffset by an additional value to add some padding between rows
            yOffsetHeader = yOffsetHeader - 20     -- Adjust the value as needed
        end
    end
end

-- Create the header row for the table
local headerRow = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerRow:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -60)
headerRow:SetWidth(columnWidths.rowHeader)
headerRow:SetJustifyH("LEFT") -- Set text justification to left
headerRow:SetText("|cff00ccffItem|r")

local headerRow2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerRow2:SetPoint("TOPLEFT", headerRow, "TOPRIGHT", 10, 0)
headerRow2:SetWidth(columnWidths.rowValue)
headerRow2:SetJustifyH("LEFT") -- Set text justification to left
headerRow2:SetText("|cff00ccffYield|r")

-- Create a horizontal divider
local headerDivider = frame:CreateTexture(nil, "ARTWORK")
headerDivider:SetHeight(1)
headerDivider:SetColorTexture(1, 1, 1, 0.5) -- Adjust the color and transparency as desired
headerDivider:SetPoint("TOPLEFT", headerRow, "BOTTOMLEFT", -5, -5)
headerDivider:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -25, 5)

-- Create the scroll frame for the table
local scrollFrame = CreateFrame("ScrollFrame", "ProspectMateScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(660, 340)
scrollFrame:SetPoint("TOPLEFT", 10, -80)

-- Create the child frame for the table
local childFrame = CreateFrame("Frame", "ProspectMateChildFrame", scrollFrame)
childFrame:SetSize(660, 340)

-- Add the child frame to the scroll frame
scrollFrame:SetScrollChild(childFrame)

-- Assign the OnClick handlers for the checkboxes
checkboxOre:SetScript("OnClick", function(self)
    UpdateUIFrame(childFrame)
end)
checkboxHerb:SetScript("OnClick", function(self)
    UpdateUIFrame(childFrame)
end)
checkboxGem:SetScript("OnClick", function(self)
    UpdateUIFrame(childFrame)
end)
checkboxCloth:SetScript("OnClick", function(self)
    UpdateUIFrame(childFrame)
end)

local resetButton = CreateFrame("Button", "ResetButton", frame, "UIPanelButtonTemplate")
resetButton:SetPoint("BOTTOMLEFT", 10, 10)
resetButton:SetSize(120, 30)
resetButton:SetText("Reset Data")

StaticPopupDialogs["RESET_DATA_CONFIRMATION"] = {
    text = "All the data will be deleted if you proceed.",
    button1 = "Confirm",
    button2 = "Cancel",
    timeout = 0,
    OnAccept = function()
        SmartProspectorDB = {}    -- Clear the data
        UpdateUIFrame(childFrame) -- Update the frame
    end,
    OnCancel = function()
        -- Nothing needs to be done here
    end,
    whileDead = true,
    hideOnEscape = true,
}

local function ShowConfirmationDialog()
    local dialog = StaticPopupDialogs["RESET_DATA_CONFIRMATION"] -- Unique dialog name
    -- Show the dialog
    StaticPopup_Show("RESET_DATA_CONFIRMATION")
end

resetButton:SetScript("OnClick", ShowConfirmationDialog)


-- Set up the button click handler
refreshButton:SetScript("OnClick", function()
    UpdateUIFrame(childFrame) -- Call the function to update the UI
end)

-- Add an event handler for the OnKeyDown event
frame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        self:Hide() -- Hide the window
    end
end)

SLASH_PROSPECTMATE1 = "/prospectmate"
SlashCmdList["PROSPECTMATE"] = function()
    UpdateUIFrame(childFrame) -- Call the function to update the UI
    frame:Show()              -- Show the window
end
