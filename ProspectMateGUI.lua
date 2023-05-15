local addonName, addonTable = ...

-- Keep track of the created UI elements
local uiElements = {}

-- Set column widths
local columnWidths = {
    rowHeader = 100,
    rowValue = 150,
}

-- Function to clear existing UI elements
local function ClearUIElements()
    for _, element in ipairs(uiElements) do
        element:SetText("") -- Clear the text of the font string
        element:Hide() -- Hide the font string
        element:SetParent(nil) -- Remove the element from its parent frame
    end
    uiElements = {} -- Clear the uiElements table
end

local function CreateRowHeader(frame, yOffset, oreName)
    local rowHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    table.insert(uiElements, rowHeader) -- Add the font string to the list of UI elements

    rowHeader:SetPoint("TOPLEFT", 10, yOffset)
    rowHeader:SetWidth(columnWidths.rowHeader)
    rowHeader:SetText(oreName)

    return rowHeader
end

local function UpdateUIFrame(frame)
    -- Clear existing UI elements
    ClearUIElements()

    -- Loop through the prospecting data and add rows to the table
    local yOffset = -30
    for oreID, results in pairs(SmartProspectorDB) do
        local oreName = GetItemInfo(oreID)
        if oreName then
            local rowHeader = CreateRowHeader(frame, yOffset, oreName)
            
            local itemName, itemTexture
            local prospectingResults = ""
            for itemID, count in pairs(results) do
                itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
                if itemName then
                    prospectingResults = prospectingResults .. itemName .. ": " .. count .. "\n"
                end
            end
            
            -- Create an icon texture
            local rowIcon = frame:CreateTexture(nil, "OVERLAY")
            table.insert(uiElements, rowIcon) -- Add the texture to the list of UI elements
            rowIcon:SetSize(20, 20)
            rowIcon:SetPoint("TOPLEFT", rowHeader, "TOPRIGHT", 10, 0)

            -- Set the texture for the icon
            rowIcon:SetTexture(itemTexture)

            -- Add a tooltip to the icon
            rowIcon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(itemID)
                GameTooltip:Show()
            end)
            rowIcon:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

            -- Create a table row
            local rowData = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            table.insert(uiElements, rowData) -- Add the font string to the list of UI elements
            rowData:SetPoint("TOPLEFT", rowIcon, "TOPRIGHT", 10, 0)
            rowData:SetWidth(columnWidths.rowValue)
            rowData:SetText(prospectingResults)

            -- Calculate the dynamic yOffset based on the number of newline characters
            local numLines = rowData:GetNumLines()
            yOffset = yOffset - (numLines * 15) -- Adjust the value (15) based on your font size and spacing

            -- Increase the yOffset by an additional value to add some padding between rows
            yOffset = yOffset - 5 -- Adjust the value as needed
        end
    end
end


-- Create the main frame for the table
local frame = CreateFrame("Frame", "ProspectMateFrame", UIParent, "UIPanelDialogTemplate")
frame:SetSize(500, 430)
frame:SetPoint("CENTER")
frame:Hide()

frame:SetMovable(true) -- Make the frame movable
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
refreshButton:SetPoint("BOTTOMRIGHT", -10, 10)
refreshButton:SetText("Refresh")


-- Create the scroll frame for the table
local scrollFrame = CreateFrame("ScrollFrame", "ProspectMateScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(460, 320)
scrollFrame:SetPoint("TOPLEFT", 10, -70)

-- Create the child frame for the table
local childFrame = CreateFrame("Frame", "ProspectMateChildFrame", scrollFrame)
childFrame:SetSize(460, 320)

-- Add the child frame to the scroll frame
scrollFrame:SetScrollChild(childFrame)

-- Create the header row for the table
local headerRow = childFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerRow:SetPoint("TOPLEFT", childFrame, "TOPLEFT", 10, -10)
headerRow:SetText("|cff00ccffOre Item|r")

local headerRow2 = childFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerRow2:SetPoint("TOPLEFT", headerRow, "TOPRIGHT", 10, 0)
headerRow2:SetText("|cff00ccffProspecting Results|r")


UpdateUIFrame(childFrame)

-- Set up the button click handler
refreshButton:SetScript("OnClick", function()
    UpdateUIFrame(childFrame) -- Call the function to update the UI
end)

function addonTable:ToggleWindow()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

SLASH_PROSPECTMATE1 = "/prospectmate"
SlashCmdList["PROSPECTMATE"] = function()
    addonTable:ToggleWindow()
end
