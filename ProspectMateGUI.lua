local addonName, addonTable = ...

local frame = CreateFrame("Frame", "ProspectMateFrame", UIParent, "UIPanelDialogTemplate")
frame:SetSize(500, 400)
frame:SetPoint("CENTER")
frame:Hide()

local scrollFrame = CreateFrame("ScrollFrame", "ProspectMateScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetSize(480, 320)
scrollFrame:SetPoint("TOPLEFT", 10, -70)

local childFrame = CreateFrame("Frame", "ProspectMateChildFrame", scrollFrame)
childFrame:SetSize(480, 320)
scrollFrame:SetScrollChild(childFrame)

local headerRow = childFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerRow:SetPoint("TOPLEFT", 10, -10)
headerRow:SetText("|cff00ccffOre Item|r   |cff00ccffProspecting Results|r")

local function CreateProspectingRow(oreID, results, yOffset)
    local oreName = GetItemInfo(oreID)
    if not oreName then
        return yOffset
    end
    
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

    return yOffset - 20
end

local function UpdateProspectingTable()
    local yOffset = -30
    for oreID, results in pairs(SmartProspectorDB) do
        yOffset = CreateProspectingRow(oreID, results, yOffset)
    end
end

UpdateProspectingTable()

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

function addonTable:SetInitialVisibility(visible)
    if visible then
        frame:Show()
    else
        frame:Hide()
    end
end
