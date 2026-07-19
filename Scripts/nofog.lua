local NOFOG = GameMain:GetMod("nofog");
local time = 0;
local flag = 0;


function NOFOG:OnStep(dt)
if flag == 0 then
time = time + dt;
if time >= 10 then
flag = 1;
CS.GameMain.Instance.NoFog = true
;
CS.MapRender.Instance.Fog.enabled = false;
end
end
end
