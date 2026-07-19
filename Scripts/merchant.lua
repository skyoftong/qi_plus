local MOD = GameMain:NewMod("merchant")

local function ApplyTraderInterval()
    CS.XiaWorld.WalkTraderData.NextComeDay_Min = 5
    CS.XiaWorld.WalkTraderData.NextComeDay_Max = 5
    CS.XiaWorld.WalkTraderData.FirstComeDay = 5
end

function MOD:OnInit()
    ApplyTraderInterval()
end

function MOD:OnEnter()
    ApplyTraderInterval()
end

function MOD:OnLoad(tbLoad)
    ApplyTraderInterval()
end