-- 淬体效果无限刷新 v4
-- 兼容 WindowEvent 可能传入 Window、contentPane、data 或事件对象的不同形式。

local Mod = GameMain:GetMod("BodyLabelRerollUnlimitedV4")
local WindowEvent = GameMain:GetMod("WindowEvent")

local registered = false

xlua.private_accessible(CS.XiaWorld.Wnd_BodyRollLabel)

local function Log(text)
    print("[BodyLabelRerollUnlimitedV4] " .. tostring(text))
end

local function SafeGet(obj, key)
    if obj == nil then
        return nil
    end

    local ok, value = pcall(function()
        return obj[key]
    end)

    if ok then
        return value
    end

    return nil
end

local function SafeCall(func)
    local ok, value = pcall(func)
    if ok then
        return value
    end
    return nil
end

local function GetTypeName(obj)
    if obj == nil then
        return "nil"
    end

    local value = SafeCall(function()
        return obj:GetType():ToString()
    end)

    if value ~= nil then
        return tostring(value)
    end

    return tostring(obj)
end

local function ShowMessage(text)
    local shown = pcall(function()
        CS.XiaWorld.InGame.Wnd_Message:Show(text)
    end)

    if not shown then
        pcall(function()
            CS.WorldLuaHelper():ShowMsgBox(text, "提示")
        end)
    end
end

local function HasAnchor(pane)
    if pane == nil then
        return false
    end

    local child = SafeCall(function()
        return pane:GetChild("m_n76")
    end)

    return child ~= nil
end

local function FindPaneAndWindow(...)
    local args = {...}
    local pane = nil
    local window = nil
    local data = nil

    local function CheckObject(obj)
        if obj == nil then
            return
        end

        local objType = GetTypeName(obj)
        Log("检查对象：" .. objType)

        if window == nil and string.find(objType, "Wnd_BodyRollLabel", 1, true) then
            window = obj
        end

        local directPane = SafeGet(obj, "contentPane")
        if directPane ~= nil and HasAnchor(directPane) then
            pane = pane or directPane
            window = window or obj
        end

        if pane == nil and HasAnchor(obj) then
            pane = obj
        end

        local nestedWindow = SafeGet(obj, "Window") or SafeGet(obj, "window")
        if nestedWindow ~= nil then
            local nestedType = GetTypeName(nestedWindow)
            if string.find(nestedType, "Wnd_BodyRollLabel", 1, true) then
                window = window or nestedWindow
            end

            local nestedPane = SafeGet(nestedWindow, "contentPane")
            if nestedPane ~= nil and HasAnchor(nestedPane) then
                pane = pane or nestedPane
            end
        end

        local objData = SafeGet(obj, "data")
        if objData ~= nil and SafeGet(objData, "QData") ~= nil then
            data = data or objData
        end

        if SafeGet(obj, "QData") ~= nil then
            data = data or obj
        end
    end

    for _, arg in ipairs(args) do
        CheckObject(arg)
    end

    if window ~= nil and data == nil then
        local windowData = SafeGet(window, "data")
        if windowData ~= nil then
            data = windowData
        end
    end

    return pane, window, data
end

local function GenerateLabels(window, data)
    data = data or SafeGet(window, "data")

    if data == nil then
        ShowMessage("淬体刷新：未找到窗口数据。")
        return false
    end

    local qdata = SafeGet(data, "QData")
    if qdata == nil then
        ShowMessage("淬体刷新：未找到 QData。")
        return false
    end

    local method = SafeGet(qdata, "method")
    local part = SafeGet(qdata, "part")
    local item = SafeGet(qdata, "item")

    if method == nil then
        ShowMessage("淬体刷新：未找到淬体方法。")
        return false
    end

    local practiceMgr = CS.XiaWorld.PracticeMgr.Instance
    local methodDef = practiceMgr:GetBodyQuenchingMethodDef(method)

    if methodDef == nil then
        ShowMessage("淬体刷新：无法读取淬体方法定义。")
        return false
    end

    local labelMoreCount = tonumber(methodDef.LabelMoreCount) or 0
    local randomCount = CS.XiaWorld.World.RandomRange(
        CS.XiaWorld.GMathUtl.RandomType.emBodyPractice,
        0,
        labelMoreCount + 1
    )

    local labels = practiceMgr:GetRandomQuenchingLabelList(
        method,
        part,
        item,
        randomCount
    )

    data.Labels = labels

    local updated = false

    if window ~= nil then
        updated = pcall(function()
            window:ShowOrUpdate(data)
        end)
    end

    if not updated then
        ShowMessage("词条已重新生成，但窗口刷新接口调用失败。")
        return false
    end

    Log("淬体结果已刷新。")
    return true
end

local function AddButton(pane, window, data)
    if pane == nil then
        return
    end

    local oldButton = SafeCall(function()
        return pane:GetChild("RerollBtn")
    end)

    if oldButton ~= nil then
        return
    end

    local anchor = SafeCall(function()
        return pane:GetChild("m_n76")
    end)

    if anchor == nil then
        return
    end

    local button = CS.XiaWorld.InGame.UI_Button.CreateInstance()
    button.name = "RerollBtn"
    button.title = "无限刷新"

    pane:AddChild(button)

    button.width = anchor.width
    button.height = anchor.height
    button.x = anchor.x
    button.y = anchor.y + anchor.height + 6

    button.onClick:Add(function()
        GenerateLabels(window, data)
    end)

    Log(
        "按钮已添加：x="
        .. tostring(button.x)
        .. ", y="
        .. tostring(button.y)
    )
end

local function OnWindowEvent(...)
    Log("收到 WindowEvent，参数数量：" .. tostring(select("#", ...)))

    local pane, window, data = FindPaneAndWindow(...)

    if pane ~= nil then
        Log("找到包含 m_n76 的 contentPane。")
        AddButton(pane, window, data)
    else
        Log("本次事件未找到 m_n76。")
    end
end

local function RegisterEvent()
    if registered then
        return
    end

    if WindowEvent == nil then
        Log("缺少 WindowEvent 前置。")
        ShowMessage("淬体无限刷新：缺少 WindowEvent 前置 MOD。")
        return
    end

    WindowEvent._Event:RegisterEvent(
        g_emEvent.WindowEvent,
        "BodyLabelRerollUnlimitedV4",
        OnWindowEvent
    )

    registered = true
    Log("WindowEvent 注册完成。")
end

function Mod:OnInit()
    RegisterEvent()
end

function Mod:OnEnter()
    RegisterEvent()
end

function Mod:OnLoad(tbLoad)
    RegisterEvent()
end
