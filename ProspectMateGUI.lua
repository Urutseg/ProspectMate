local addonName, addonTable = ...

-- Keep track of the created UI elements
local uiElements = {}

-- Function to clear existing UI elements
local function ClearUIElements()
    for _, element in ipairs(uiElements) do
        element:SetText("") -- Clear the text of the font string
        element:Hide() -- Hide the font string
        element:SetParent(nil) -- Remove the element from its parent frame
    end
    uiElements = {} -- Clear the uiElements table
end


local function UpdateUIFrame(frame)
    -- Clear existing UI elements
    ClearUIElements()

-- Loop through the prospecting data and add rows to the table
    local yOffset = -30
    for oreID, results in pairs(SmartProspectorDB) do
        -- print(oreID)
        local oreName = GetItemInfo(oreID)
        if oreName then
            local row = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            table.insert(uiElements, row) -- Add the font string to the list of UI elements

            row:SetPoint("TOPLEFT", 10, yOffset)
            row:SetText(oreName)

            local prospectingResults = ""
            for itemID, count in pairs(results) do
                local itemName = GetItemInfo(itemID)
                if itemName then
                    prospectingResults = prospectingResults .. itemName .. ": " .. count .. "\n"
                end
            end

            local resultsRow = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            table.insert(uiElements, resultsRow) -- Add the font string to the list of UI elements
            resultsRow:SetPoint("LEFT", row, "RIGHT", 10, 0)
            resultsRow:SetText(prospectingResults)

            yOffset = yOffset - 20
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
headerRow:SetPoint("TOPLEFT", 10, -10)
headerRow:SetText("|cff00ccffOre Item|r   |cff00ccffProspecting Results|r")

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
