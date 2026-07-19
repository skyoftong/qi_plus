local Mod = GameMain:GetMod("MoreDisciples")

local MAX_DISCIPLES = {48, 48, 60, 72}

local function ApplyMaxDisciples()
    CS.XiaWorld.GameDefine.SchoolMaxNpc = MAX_DISCIPLES
    CS.XiaWorld.GameDefine.SchoolMaxDNpc = MAX_DISCIPLES
end

function Mod:OnInit()
    ApplyMaxDisciples()
end

function Mod:OnLoad()
    ApplyMaxDisciples()
end

function Mod:OnEnter()
    ApplyMaxDisciples()
end