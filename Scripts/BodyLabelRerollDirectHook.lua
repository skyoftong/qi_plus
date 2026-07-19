-- 淬体无限刷新：直接挂接基础版
-- 不依赖 WindowEvent，不依赖旧版 MOD。
-- 直接挂接 Wnd_BodyRollLabel.ShowOrUpdate，在窗口显示后加入按钮。

local Mod = GameMain:NewMod("BodyLabelRerollDirectHook")
local util = require "xlua.util"

local hooked = false

xlua.private_accessible(CS.XiaWorld.Wnd_BodyRollLabel)

local function Reroll(window)
    if window == nil or window.data == nil or window.data.QData == nil then
        return
    end

    local data = window.data
    local qdata = data.QData
    local mgr = CS.XiaWorld.PracticeMgr.Instance
    local methodDef = mgr:GetBodyQuenchingMethodDef(qdata.method)

    if methodDef == nil then
        return
    end

    local moreCount = tonumber(methodDef.LabelMoreCount) or 0
    local count = CS.XiaWorld.World.RandomRange(
        CS.XiaWorld.GMathUtl.RandomType.emBodyPractice,
        0,
        moreCount + 1
    )

    data.Labels = mgr:GetRandomQuenchingLabelList(
        qdata.method,
        qdata.part,
        qdata.item,
        count
    )

    window:ShowOrUpdate(data)
end

local function AddRefreshButton(window)
    if window == nil or window.contentPane == nil then
        return
    end

    local pane = window.contentPane
    local old = pane:GetChild("DirectRerollBtn")
    if old ~= nil then
        return
    end

    local button = CS.XiaWorld.InGame.UI_Button.CreateInstance()
    button.name = "DirectRerollBtn"
    button.title = "↻ 重新随机"
    button.width = 150
    button.height = 42

    -- 固定放在淬体弹窗内部左上角。
    -- 不再依赖 m_n76 或其他可能已经变化的控件名。
    button.x = 18
    button.y = 18

    pane:AddChild(button)
    pane:SetChildIndex(button, pane.numChildren - 1)

    button.onClick:Add(function()
        Reroll(window)
    end)
end

local function InstallHook()
    if hooked then
        return
    end

    -- hotfix_ex 中可通过 self:ShowOrUpdate(data) 调用原始方法。
    util.hotfix_ex(
        CS.XiaWorld.Wnd_BodyRollLabel,
        "ShowOrUpdate",
        function(self, data)
            self:ShowOrUpdate(data)
            AddRefreshButton(self)
        end
    )

    hooked = true
end

function Mod:OnInit()
    InstallHook()
end

function Mod:OnEnter()
    InstallHook()
end

function Mod:OnLoad(tbLoad)
    InstallHook()
end
