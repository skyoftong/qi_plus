-- 淬体效果无限刷新 v3
-- 不使用自定义 FUI 包，直接调用游戏内置 UI_Button。

local Mod = GameMain:GetMod("BodyLabelRerollUnlimited")
local WindowEvent = GameMain:GetMod("WindowEvent")

local registered = false

xlua.private_accessible(CS.XiaWorld.Wnd_BodyRollLabel)

local function Log(text)
    print("[BodyLabelRerollUnlimited] " .. tostring(text))
end

local function ShowMessage(text)
    local ok = pcall(function()
        CS.XiaWorld.InGame.Wnd_Message:Show(text)
    end)

    if not ok then
        pcall(function()
            CS.WorldLuaHelper():ShowMsgBox(text, "提示")
        end)
    end
end

local function GetTypeName(obj)
    if obj == nil then
        return ""
    end

    local ok, result = pcall(function()
        return obj:GetType():ToString()
    end)

    if ok and result ~= nil then
        return tostring(result)
    end

    return tostring(obj)
end

local function ResolveWindow(...)
    local args = {...}

    for _, value in ipairs(args) do
        if value ~= nil then
            local ok1, window1 = pcall(function()
                return value.Window
            end)
            if ok1 and window1 ~= nil then
                return window1
            end

            local ok2, window2 = pcall(function()
                return value.window
            end)
            if ok2 and window2 ~= nil then
                return window2
            end

            if string.find(GetTypeName(value), "Wnd_BodyRollLabel", 1, true) then
                return value
            end
        end
    end

    return nil
end

local function Reroll(window)
    if window == nil or window.data == nil or window.data.QData == nil then
        ShowMessage("无法读取当前淬体数据。")
        return
    end

    local data = window.data
    local qdata = data.QData
    local practiceMgr = CS.XiaWorld.PracticeMgr.Instance

    local methodDef = practiceMgr:GetBodyQuenchingMethodDef(qdata.method)
    if methodDef == nil then
        ShowMessage("无法读取当前淬体方法。")
        return
    end

    local labelMoreCount = tonumber(methodDef.LabelMoreCount) or 0

    local randomCount = CS.XiaWorld.World.RandomRange(
        CS.XiaWorld.GMathUtl.RandomType.emBodyPractice,
        0,
        labelMoreCount + 1
    )

    data.Labels = practiceMgr:GetRandomQuenchingLabelList(
        qdata.method,
        qdata.part,
        qdata.item,
        randomCount
    )

    window:ShowOrUpdate(data)
    Log("已刷新淬体结果。")
end

local function AddButton(window)
    if window == nil or window.contentPane == nil then
        return
    end

    local pane = window.contentPane

    -- 避免同一个窗口重复添加。
    local oldButton = pane:GetChild("RerollBtn")
    if oldButton ~= nil then
        return
    end

    local anchor = pane:GetChild("m_n76")

    local button = CS.XiaWorld.InGame.UI_Button.CreateInstance()
    button.name = "RerollBtn"
    button.title = "无限刷新"

    pane:AddChild(button)

    if anchor ~= nil then
        button.width = anchor.width
        button.height = anchor.height

        -- 优先放在原按钮区域旁边；空间不足时放在上方。
        button.x = anchor.x + anchor.width + 8
        button.y = anchor.y

        if button.x + button.width > pane.width then
            button.x = anchor.x
            button.y = anchor.y - anchor.height - 8
        end
    else
        -- 找不到锚点时，使用窗口底部的保底位置。
        button.width = 110
        button.height = 32
        button.x = math.max(10, pane.width - button.width - 20)
        button.y = math.max(10, pane.height - button.height - 20)
        Log("未找到 m_n76，已使用保底位置。")
    end

    button.onClick:Add(function()
        Reroll(window)

        -- 某些版本 ShowOrUpdate 会重建内容，重新检查按钮。
        if pane:GetChild("RerollBtn") == nil then
            AddButton(window)
        end
    end)

    Log(
        "刷新按钮已添加，位置："
        .. tostring(button.x)
        .. ","
        .. tostring(button.y)
    )
end

local function OnWindowEvent(...)
    local window = ResolveWindow(...)
    if window == nil then
        return
    end

    local typeName = GetTypeName(window)
    if string.find(typeName, "Wnd_BodyRollLabel", 1, true) then
        Log("检测到淬体窗口：" .. typeName)
        AddButton(window)
    end
end

local function Register()
    if registered then
        return
    end

    if WindowEvent == nil then
        Log("未找到 WindowEvent 前置。")
        ShowMessage("淬体无限刷新：缺少 WindowEvent 前置 MOD。")
        return
    end

    WindowEvent._Event:RegisterEvent(
        g_emEvent.WindowEvent,
        "BodyLabelRerollUnlimited",
        OnWindowEvent
    )

    registered = true
    Log("窗口事件注册完成。")
end

function Mod:OnInit()
    Log("MOD 初始化完成。")
end

function Mod:OnEnter()
    Register()
end

function Mod:OnLoad(tbLoad)
    Register()
end
