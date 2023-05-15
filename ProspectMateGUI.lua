local addonName, addonTable = ...

-- Keep track of the created UI elements
local uiElements = {}

-- Set column widths
local columnWidths = {
    rowHeader = 150,
    rowValue = 200,
}

-- Function to clear existing UI elements
local function ClearUIElements()
    for _, element in ipairs(uiElements) do
        if element.SetText then -- Check if the element has a SetText method
            element:SetText("") -- Clear the text of the font string
            element:Hide() -- Hide the font string
        end
        if element.SetTexture then -- Check if the element has a SetTexture method
            element:SetTexture(nil) -- Clear the texture of the divider
        end
        element:SetParent(nil) -- Remove the element from its parent frame
    end
    uiElements = {} -- Clear the uiElements table
end


local function CreateRowHeader(frame, yOffset, oreLink)
    local rowHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    table.insert(uiElements, rowHeader) -- Add the font string to the list of UI elements

    rowHeader:SetPoint("TOPLEFT", 10, yOffset)
    rowHeader:SetWidth(columnWidths.rowHeader)
    rowHeader:SetJustifyH("LEFT") -- Set text justification to left
    rowHeader:SetText(oreLink)

    return rowHeader
end

local function UpdateUIFrame(frame)
    -- Clear existing UI elements
    ClearUIElements()

    -- Loop through the prospecting data and add rows to the table
    local yOffsetHeader = 0
    for oreID, results in pairs(SmartProspectorDB) do
        local oreName, oreLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(oreID)
        if oreName then
            local rowHeader = CreateRowHeader(frame, yOffsetHeader, oreLink)
            local yOffsetRow = 0
            for itemID, count in pairs(results) do
                local itemName, itemLink, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemID)
                if itemName then

                    local rowData = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    table.insert(uiElements, rowData) -- Add the font string to the list of UI elements
                    rowData:SetPoint("TOPLEFT", rowHeader, "TOPRIGHT", 10, yOffsetRow)
                    rowData:SetWidth(columnWidths.rowValue)
                    rowData:SetJustifyH("LEFT") -- Set text justification to left
                    rowData:SetText(itemLink .. ": " .. count)

                    -- Calculate the dynamic yOffset based on the font string height
                    local _, rowItemHeight = rowData:GetFont()
                    yOffsetHeader = yOffsetHeader - rowItemHeight - 5 -- Adjust the value based on your font size
                    yOffsetRow = yOffsetRow - rowItemHeight - 5 -- Adjust the value based on your font size
                end
            end

            -- Create a horizontal divider
            local dividerTexture = frame:CreateTexture(nil, "ARTWORK")
            table.insert(uiElements, dividerTexture) -- Add the texture to the list of UI elements
            dividerTexture:SetHeight(1)
            dividerTexture:SetColorTexture(1, 1, 1, 0.5) -- Adjust the color and transparency as desired
            dividerTexture:SetPoint("TOPLEFT", rowHeader, "TOPLEFT", -5, 5)
            dividerTexture:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 5, 5)

            -- Increase the yOffset by an additional value to add some padding between rows
            yOffsetHeader = yOffsetHeader - 5 -- Adjust the value as needed
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

-- Create the header row for the table
local headerRow = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerRow:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -40)
headerRow:SetWidth(columnWidths.rowHeader)
headerRow:SetJustifyH("LEFT") -- Set text justification to left
headerRow:SetText("|cff00ccffOre Item|r")

local headerRow2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerRow2:SetPoint("TOPLEFT", headerRow, "TOPRIGHT", 10, 0)
headerRow2:SetWidth(columnWidths.rowValue)
headerRow2:SetJustifyH("LEFT") -- Set text justification to left
headerRow2:SetText("|cff00ccffProspecting Results|r")

-- Create a horizontal divider
local headerDivider = frame:CreateTexture(nil, "ARTWORK")
headerDivider:SetHeight(1)
headerDivider:SetColorTexture(1, 1, 1, 0.5) -- Adjust the color and transparency as desired
headerDivider:SetPoint("TOPLEFT", headerRow, "BOTTOMLEFT", -5, -5)
headerDivider:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 5, 5)

-- Create the scroll frame for the table
local scrollFrame = CreateFrame("ScrollFrame", "ProspectMateScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(460, 320)
scrollFrame:SetPoint("TOPLEFT", 10, -70)

-- Create the child frame for the table
local childFrame = CreateFrame("Frame", "ProspectMateChildFrame", scrollFrame)
childFrame:SetSize(460, 320)

-- Add the child frame to the scroll frame
scrollFrame:SetScrollChild(childFrame)

UpdateUIFrame(childFrame)

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
    frame:Show() -- Show the window
end
