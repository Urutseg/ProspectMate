local addonName, addonTable = ...

-- Create the main frame for the table
local frame = CreateFrame("Frame", "ProspectMateFrame", UIParent, "UIPanelDialogTemplate")
frame:SetSize(500, 400)
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

-- Loop through the prospecting data and add rows to the table
local yOffset = -30
for oreID, results in pairs(SmartProspectorDB) do
    local oreName = GetItemInfo(oreID)
    if oreName then
        local row = childFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row:SetPoint("TOPLEFT", 10, yOffset)
        row:SetText(oreName)

        local prospectingResults = ""
        for itemID, count in pairs(results) do
            local itemName = GetItemInfo(itemID)
            if itemName then
                prospectingResults = prospectingResults .. itemName .. ": " .. count .. "\n"
            end
        end

        local resultsRow = childFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        resultsRow:SetPoint("LEFT", row, "RIGHT", 10, 0)
        resultsRow:SetText(prospectingResults)

        yOffset = yOffset - 20
    end
end

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
