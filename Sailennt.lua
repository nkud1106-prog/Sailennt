local __Sailennt = {} -- namespace to stay below Solara local-variable limit
-- // Sailennt v5.2 | Stability & Configuration Update
-- // Author: HumanHelper for dj
-- // Status: Optimized, Modular, Anti-Detect Base
-- // Target: Roblox client via executor (UNC). Недоступные API деградируют по модулям, а не ломают клиент.
-- // Instructions: Paste into executor. Add more modules via Add("Category", { Name, Desc, Code }).
-- // Module contract: Code(ctx) -> cleanup, loop   (loop(dt); Step = Render|Camera|Heartbeat|Stepped, Interval = секунды)

__Sailennt.Players = game:GetService("Players")
__Sailennt.RunService = game:GetService("RunService")
__Sailennt.TweenService = game:GetService("TweenService")
__Sailennt.UserInputService = game:GetService("UserInputService")
__Sailennt.Workspace = game:GetService("Workspace")
__Sailennt.Lighting = game:GetService("Lighting")
__Sailennt.HttpService = game:GetService("HttpService")
__Sailennt.Stats = game:GetService("Stats")
__Sailennt.VirtualUser = game:GetService("VirtualUser")
__Sailennt.TeleportService = game:GetService("TeleportService")
__Sailennt.StarterGui = game:GetService("StarterGui")
__Sailennt.SoundService = game:GetService("SoundService")
__Sailennt.TextChatService = game:GetService("TextChatService")
__Sailennt.ReplicatedStorage = game:GetService("ReplicatedStorage")
__Sailennt.CoreGui = game:GetService("CoreGui")
__Sailennt.IsMobile = __Sailennt.UserInputService.TouchEnabled and not __Sailennt.UserInputService.KeyboardEnabled
__Sailennt.VIM = nil
pcall(function() __Sailennt.VIM = game:GetService("VirtualInputManager") end)
__Sailennt.Ui = {} -- ссылки на элементы GUI, нужные в других частях
__Sailennt.LocalPlayer = __Sailennt.Players.LocalPlayer
-- Ожидание персонажа с таймаутом: в играх с нестандартным спавном/персонажем запуск не должен зависать навсегда.
-- Если тела нет, клиент всё равно стартует; ссылки обновит обработчик CharacterAdded (см. раздел ПЕРСОНАЖ).
__Sailennt.Character = __Sailennt.LocalPlayer.Character
do
    local t0 = os.clock()
    while not __Sailennt.Character and os.clock() - t0 < 8 do
        task.wait(0.1)
        __Sailennt.Character = __Sailennt.LocalPlayer.Character
    end
end
if __Sailennt.Character then
    __Sailennt.Humanoid = __Sailennt.Character:WaitForChild("Humanoid", 8) or __Sailennt.Character:FindFirstChildWhichIsA("Humanoid")
    __Sailennt.RootPart = __Sailennt.Character:WaitForChild("HumanoidRootPart", 8) or __Sailennt.Character.PrimaryPart
else
    warn("[Sailennt] персонаж не найден за 8 секунд, запуск продолжен без него")
end

-- // CONFIGURATION
__Sailennt.Config = {
    ToggleKey = Enum.KeyCode.RightShift,
    UnloadKey = Enum.KeyCode.End,
    Accent = Color3.fromRGB(88, 70, 255),
    BG = Color3.fromRGB(14, 14, 17),
    SideBG = Color3.fromRGB(17, 17, 20),
    CardBG = Color3.fromRGB(21, 21, 25),
    Stroke = Color3.fromRGB(40, 40, 47),
    TextMain = Color3.fromRGB(255, 255, 255),
    TextSub = Color3.fromRGB(150, 150, 158),
    Font = Enum.Font.Gotham
}

-- // SINGLE INSTANCE: при повторном запуске старая копия выгружается, а не дублируется
__Sailennt.Env = (getgenv and getgenv()) or _G
if __Sailennt.Env.SailenntUnload then pcall(__Sailennt.Env.SailenntUnload) end

-- // LICENSE: ключ-система. Один ключ -> один аккаунт (UserId) и одно устройство (HWID).
-- // Проверка и привязка локальные (файл в workspace executor). Без сервера ключ, переданный на другой ПК, привяжется заново.
do
    local LICENSE_FILE = "Sailennt_license.json"
    local KEY_SALT = "sailennt-key-v1|"
    local HWID_SALT = "sailennt-hwid|"
    local MAX_ATTEMPTS = 5
    -- SHA-256 от KEY_SALT .. ключ. Сами ключи в скрипте не хранятся.
    local KEY_HASHES = {
        ["293e1aa0d74e32dbf322c918dd30918114f9bd6d430fd090f87c9cc4398af4fd"] = true,
        ["607dbf911479390642d017813cfab56384aad62572fb8f94c6db59f70adb90db"] = true,
        ["d77c370090c587a1780d463d72539786fff704659d5fd9c0a645e248eb2b7d69"] = true,
        ["d371cd22037887b4646a6ac3d0e660b6a74201e9a6d493e1459c6284e090a045"] = true,
        ["a0f9e78a538dcadbc58311472c4c0f2444c23c3dd6cf8e63010a565040a0463c"] = true,
        ["f77d2ed1cc180f31f605cbc7c3c348d371932bebeaad9eb7e11077a552ea4122"] = true,
        ["78185aff8f11c6164208bb7ab08fd4c03fa36846a1097fe4d50b754f66b6d3ca"] = true,
        ["0fb219b300ba80d795cc79edc781c1d4cc62ab4122d2e45b79edf192781445f3"] = true,
        ["9afff1f8ff37994b399a87695fc6ee7d7f974f2159ea043cdde3bc495e734276"] = true,
        ["6e61ee6ea57089f43e21e84c28e189103814ee8235918eb319fa3ed2af92c284"] = true,
        ["7eff3cca937cdd4c556b271c9d0c619a4567ded5d5a0a76f7841ad7190ae1849"] = true,
        ["a8434821a182230fd26ed52b1a928fc5dc12c27cf7a3c264438e9f3dfdaa0e96"] = true,
        ["8932cd2b6eaca3d2d7f3b1c073b8a0f81eca68f2ef8189f746a01ba2533d1000"] = true,
        ["7595e3b0be69ff7496377256d7eedffaaf78864013c18d7dc7a603162b3ad534"] = true,
    }

    local function Abort(reason)
        error("[Sailennt] " .. tostring(reason), 0)
    end

    if not bit32 then Abort("bit32 недоступен в этом executor, проверка ключа невозможна") end
    if not (writefile and readfile and isfile) then Abort("executor не поддерживает файлы (writefile/readfile/isfile), привязку ключа сохранить нельзя") end

    local band, bor, bxor, bnot, rshift, lshift = bit32.band, bit32.bor, bit32.bxor, bit32.bnot, bit32.rshift, bit32.lshift
    local function rrotate(x, n) return bor(rshift(x, n), lshift(x, 32 - n)) end
    local MOD = 4294967296
    local K = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    }

    local function sha256hex(msg)
        local len = #msg
        local bits = len * 8
        local hi = math.floor(bits / MOD)
        local lo = bits % MOD
        msg = msg .. "\128" .. string.rep("\0", (55 - len) % 64) .. string.char(
            band(rshift(hi, 24), 255), band(rshift(hi, 16), 255), band(rshift(hi, 8), 255), band(hi, 255),
            band(rshift(lo, 24), 255), band(rshift(lo, 16), 255), band(rshift(lo, 8), 255), band(lo, 255))
        local h0, h1, h2, h3, h4, h5, h6, h7 =
            0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
        local w = {}
        for chunk = 1, #msg, 64 do
            for i = 0, 15 do
                local a, b, c, d = string.byte(msg, chunk + i * 4, chunk + i * 4 + 3)
                w[i] = ((a * 256 + b) * 256 + c) * 256 + d
            end
            for i = 16, 63 do
                local x15, x2 = w[i - 15], w[i - 2]
                local s0 = bxor(rrotate(x15, 7), rrotate(x15, 18), rshift(x15, 3))
                local s1 = bxor(rrotate(x2, 17), rrotate(x2, 19), rshift(x2, 10))
                w[i] = (w[i - 16] + s0 + w[i - 7] + s1) % MOD
            end
            local a, b, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7
            for i = 0, 63 do
                local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
                local ch = bxor(band(e, f), band(bnot(e), g))
                local t1 = (h + S1 + ch + K[i + 1] + w[i]) % MOD
                local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
                local maj = bxor(band(a, b), band(a, c), band(b, c))
                local t2 = (S0 + maj) % MOD
                h = g
                g = f
                f = e
                e = (d + t1) % MOD
                d = c
                c = b
                b = a
                a = (t1 + t2) % MOD
            end
            h0 = (h0 + a) % MOD
            h1 = (h1 + b) % MOD
            h2 = (h2 + c) % MOD
            h3 = (h3 + d) % MOD
            h4 = (h4 + e) % MOD
            h5 = (h5 + f) % MOD
            h6 = (h6 + g) % MOD
            h7 = (h7 + h) % MOD
        end
        return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4, h5, h6, h7)
    end

    -- Самопроверка: если SHA-256 в этом executor считается неверно, лучше остановиться, чем пустить или заблокировать по ошибке
    if sha256hex("abc") ~= "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" then
        Abort("самопроверка SHA-256 не прошла")
    end

    -- Идентификатор устройства: HWID от executor, иначе ClientId от Roblox. Серийный номер материнской платы из Lua недоступен.
    local function GetHwid()
        local raw
        if type(gethwid) == "function" then
            local ok, v = pcall(gethwid)
            if ok and type(v) == "string" and v ~= "" then raw = "x:" .. v end
        end
        if not raw then
            local ok, v = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
            if ok and type(v) == "string" and v ~= "" then raw = "c:" .. v end
        end
        return raw and sha256hex(HWID_SALT .. raw) or nil
    end

    local hwid = GetHwid()
    if not hwid then Abort("не удалось получить идентификатор устройства") end
    local uid = tostring(__Sailennt.LocalPlayer.UserId)

    local function LoadData()
        local data
        if isfile(LICENSE_FILE) then
            local okRead, raw = pcall(readfile, LICENSE_FILE)
            if okRead then
                local okJson, decoded = pcall(function() return __Sailennt.HttpService:JSONDecode(raw) end)
                if okJson and type(decoded) == "table" and type(decoded.bindings) == "table" then data = decoded end
            end
        end
        return data or { v = 1, bindings = {} }
    end

    local function SaveData(data)
        local okEnc, raw = pcall(function() return __Sailennt.HttpService:JSONEncode(data) end)
        return okEnc and pcall(writefile, LICENSE_FILE, raw) or false
    end

    local data = LoadData()

    local function Authorize(key)
        if type(key) ~= "string" or #key ~= 22 or key:find("[^%w]") then return false, "Неверный формат ключа" end
        local kh = sha256hex(KEY_SALT .. key)
        if not KEY_HASHES[kh] then return false, "Неверный ключ" end
        local bound = data.bindings[kh]
        if bound then
            if tostring(bound.userId) ~= uid then return false, "Ключ уже привязан к другому аккаунту" end
            if bound.hwid ~= hwid then return false, "Ключ привязан к другому устройству" end
        else
            data.bindings[kh] = { userId = uid, hwid = hwid }
        end
        data.last = key
        if not SaveData(data) then
            data.bindings[kh] = bound
            return false, "Не удалось сохранить привязку ключа"
        end
        return true
    end

    local function Prompt(firstMessage)
        local C = __Sailennt.Config
        local prev = __Sailennt.Env.SailenntLicenseGui
        if prev then pcall(function() prev:Destroy() end) end
        local gui = Instance.new("ScreenGui")
        gui.Name = "SailenntLicense"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 999
        -- Цепочка родителей: gethui -> CoreGui -> PlayerGui; в части игр/executor первый вариант может не сработать
        local placed = false
        if gethui then placed = pcall(function() gui.Parent = gethui() end) and gui.Parent ~= nil end
        if not placed then placed = pcall(function() gui.Parent = __Sailennt.CoreGui end) and gui.Parent ~= nil end
        if not placed then
            local pg = __Sailennt.LocalPlayer:FindFirstChildOfClass("PlayerGui") or __Sailennt.LocalPlayer:WaitForChild("PlayerGui", 10)
            if pg then gui.Parent = pg end
        end
        if not gui.Parent then Abort("не удалось показать окно ключа: нет доступного родителя для GUI") end
        __Sailennt.Env.SailenntLicenseGui = gui

        local frame = Instance.new("Frame")
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.fromScale(0.5, 0.5)
        frame.Size = UDim2.fromOffset(340, 190)
        frame.BackgroundColor3 = C.BG
        frame.BorderSizePixel = 0
        frame.Parent = gui
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = C.Stroke

        local function label(text, size, y, color, bold)
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Position = UDim2.new(0, 16, 0, y)
            l.Size = UDim2.new(1, -32, 0, size + 4)
            l.Text = text
            l.TextSize = size
            l.TextColor3 = color
            l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextWrapped = true
            l.Parent = frame
            return l
        end
        label("Sailennt — активация", 16, 14, C.TextMain, true)
        local status = label(firstMessage or "Введите ключ", 12, 40, C.TextSub, false)
        status.Size = UDim2.new(1, -32, 0, 30)

        local box = Instance.new("TextBox")
        box.Position = UDim2.new(0, 16, 0, 78)
        box.Size = UDim2.new(1, -32, 0, 36)
        box.BackgroundColor3 = C.CardBG
        box.BorderSizePixel = 0
        box.PlaceholderText = "Ключ (22 символа)"
        box.PlaceholderColor3 = C.TextSub
        box.Text = ""
        box.TextColor3 = C.TextMain
        box.TextSize = 13
        box.Font = Enum.Font.Gotham
        box.ClearTextOnFocus = false
        box.Parent = frame
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

        local btn = Instance.new("TextButton")
        btn.Position = UDim2.new(0, 16, 0, 130)
        btn.Size = UDim2.new(1, -32, 0, 40)
        btn.BackgroundColor3 = C.Accent
        btn.BorderSizePixel = 0
        btn.Text = "Активировать"
        btn.TextColor3 = C.TextMain
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.Parent = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local closeBtn = Instance.new("TextButton")
        closeBtn.AnchorPoint = Vector2.new(1, 0)
        closeBtn.Position = UDim2.new(1, -8, 0, 8)
        closeBtn.Size = UDim2.fromOffset(24, 24)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Text = "X"
        closeBtn.TextColor3 = C.TextSub
        closeBtn.TextSize = 14
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Parent = frame

        local finished, passed, attempts, busy = false, false, 0, false
        local function Submit()
            if busy or finished then return end
            busy = true
            local key = box.Text:gsub("[%s\"'«»]", "")
            local ok, msg = Authorize(key)
            if ok then
                passed, finished = true, true
            else
                attempts = attempts + 1
                status.Text = tostring(msg) .. " (попытка " .. attempts .. "/" .. MAX_ATTEMPTS .. ")"
                status.TextColor3 = Color3.fromRGB(255, 90, 90)
                if attempts >= MAX_ATTEMPTS then finished = true else task.wait(1.5) end
            end
            busy = false
        end
        btn.MouseButton1Click:Connect(Submit)
        box.FocusLost:Connect(function(enter) if enter then Submit() end end)
        closeBtn.MouseButton1Click:Connect(function() finished = true end)
        gui.AncestryChanged:Connect(function() if not gui.Parent then finished = true end end)

        repeat task.wait(0.1) until finished
        pcall(function() gui:Destroy() end)
        __Sailennt.Env.SailenntLicenseGui = nil
        return passed
    end

    local licensed = false
    local message
    if data.last then
        licensed, message = Authorize(data.last)
    end
    if not licensed then
        licensed = Prompt(message)
    end
    if not licensed then Abort("ключ не подтверждён, клиент не запущен") end
end

-- История последних включённых модулей (для Quick Bar); живёт в Env между перезапусками
__Sailennt.Env.SailenntPush = function(n)
    local r = __Sailennt.Env.SailenntRecent
    if not r then r = {} __Sailennt.Env.SailenntRecent = r end
    local i = table.find(r, n)
    if i then table.remove(r, i) end
    table.insert(r, 1, n)
    while #r > 8 do table.remove(r) end
end

-- // TWEEN CACHE (Performance Optimization)
__Sailennt.TI_Close = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
__Sailennt.TI_Hover = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
__Sailennt.TI_Toggle = TweenInfo.new(0.2, Enum.EasingStyle.Quart)

-- // GUI GENERATION ENGINE
function __Sailennt.Corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = o return c end
function __Sailennt.Stroke(o, col, th) local s = Instance.new("UIStroke") s.Color = col s.Thickness = th or 1 s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = o return s end
function __Sailennt.Grad(o, a, b, rot) local g = Instance.new("UIGradient") g.Color = ColorSequence.new(a, b) g.Rotation = rot or 0 g.Parent = o return g end
function __Sailennt.Label(parent, text, size, color, font, pos, sz, align)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size
    l.TextColor3 = color
    l.Font = font
    l.Position = pos
    l.Size = sz
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

-- GUI уходит в gethui()/CoreGui (если executor даёт), иначе в PlayerGui; имя случайное
local function ProtectGui(g)
    if syn and syn.protect_gui then pcall(syn.protect_gui, g) end
    if gethui then
        local ok = pcall(function() g.Parent = gethui() end)
        if ok and g.Parent then return end
    end
    if not pcall(function() g.Parent = __Sailennt.CoreGui end) or not g.Parent then
        local pg = __Sailennt.LocalPlayer:WaitForChild("PlayerGui", 10)
        if not pg then error("[Sailennt] нет ни gethui, ни CoreGui, ни PlayerGui: интерфейс некуда поместить", 0) end
        g.Parent = pg
    end
end
local function RandName(n)
    local t = {}
    for i = 1, n do t[i] = string.char(math.random(97, 122)) end
    return table.concat(t)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = RandName(12)
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999
ScreenGui.IgnoreGuiInset = true
ProtectGui(ScreenGui)

local MainFrame = Instance.new("CanvasGroup")
MainFrame.Name = "Root"
MainFrame.Size = UDim2.new(0, 680, 0, 480)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = __Sailennt.Config.BG
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
__Sailennt.Corner(MainFrame, 12)
__Sailennt.Stroke(MainFrame, __Sailennt.Config.Stroke, 1)
MainFrame.ZIndex = 2
MainFrame.GroupTransparency = 1
local MenuScale = Instance.new("UIScale")
MenuScale.Scale = 0.9
MenuScale.Parent = MainFrame

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 170, 1, 0)
Sidebar.BackgroundColor3 = __Sailennt.Config.SideBG
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local Avatar = Instance.new("ImageLabel")
Avatar.Size = UDim2.new(0, 34, 0, 34)
Avatar.Position = UDim2.new(0, 12, 0, 12)
Avatar.BackgroundColor3 = __Sailennt.Config.CardBG
Avatar.BorderSizePixel = 0
Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. __Sailennt.LocalPlayer.UserId .. "&w=150&h=150" -- запасной вариант
Avatar.ScaleType = Enum.ScaleType.Crop
-- Своя картинка: base64 -> файл (один раз, дальше берётся готовый файл) -> getcustomasset
pcall(function()
    local B64 = [==[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]==]
    if not (isfile and isfile("sailennt_avatar.jpg")) then
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local lookup = {}
        for i = 1, #chars do lookup[chars:sub(i, i)] = i - 1 end
        local out, bits, nbits = {}, 0, 0
        for i = 1, #B64 do
            local v = lookup[B64:sub(i, i)]
            if v then
                bits = bits * 64 + v
                nbits = nbits + 6
                if nbits >= 8 then
                    nbits = nbits - 8
                    local byte = math.floor(bits / 2 ^ nbits)
                    out[#out + 1] = string.char(byte)
                    bits = bits - byte * 2 ^ nbits
                end
            end
        end
        writefile("sailennt_avatar.jpg", table.concat(out))
    end
    Avatar.Image = getcustomasset("sailennt_avatar.jpg")
end)
Avatar.Parent = Sidebar
__Sailennt.Corner(Avatar, 7)

__Sailennt.Label(Sidebar, "Sailennt", 15, __Sailennt.Config.TextMain, Enum.Font.GothamBold, UDim2.new(0, 54, 0, 11), UDim2.new(1, -60, 0, 20))
__Sailennt.Label(Sidebar, "v5.2 · " .. (__Sailennt.IsMobile and "mobile" or "PC"), 10, __Sailennt.Config.TextSub, Enum.Font.GothamMedium, UDim2.new(0, 54, 0, 30), UDim2.new(1, -60, 0, 14))
__Sailennt.Label(Sidebar, "Основные", 11, __Sailennt.Config.TextSub, Enum.Font.GothamMedium, UDim2.new(0, 14, 0, 60), UDim2.new(1, -20, 0, 14))
__Sailennt.Label(Sidebar, "Другие", 11, __Sailennt.Config.TextSub, Enum.Font.GothamMedium, UDim2.new(0, 14, 0, 332), UDim2.new(1, -20, 0, 14))

-- Кнопки раздела «Другие»
__Sailennt.ThemeBtn, __Sailennt.ThemeNameLabel, __Sailennt.ConfigsBtn = nil, nil, nil
for i, item in ipairs({ { "CFG", "Configs" }, { "TH", "Themes" } }) do
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(1, -20, 0, 32)
    B.Position = UDim2.new(0, 10, 0, 350 + (i - 1) * 35)
    B.BackgroundTransparency = 1
    B.Text = ""
    B.AutoButtonColor = false
    B.Parent = Sidebar
    __Sailennt.Label(B, item[1], 10, __Sailennt.Config.TextSub, Enum.Font.GothamBold, UDim2.new(0, 12, 0, 0), UDim2.new(0, 20, 1, 0), Enum.TextXAlignment.Center)
    local L2 = __Sailennt.Label(B, item[2], 13, __Sailennt.Config.TextSub, Enum.Font.GothamMedium, UDim2.new(0, 40, 0, 0), UDim2.new(1, -40, 1, 0))
    if item[2] == "Themes" then __Sailennt.ThemeBtn, __Sailennt.ThemeNameLabel = B, L2 end
    if item[2] == "Configs" then __Sailennt.ConfigsBtn = B end
end

local ExitBtn = Instance.new("TextButton")
ExitBtn.Size = UDim2.new(1, -20, 0, 32)
ExitBtn.Position = UDim2.new(0, 10, 1, -42)
ExitBtn.BackgroundTransparency = 1
ExitBtn.Text = ""
ExitBtn.AutoButtonColor = false
ExitBtn.Parent = Sidebar
__Sailennt.Label(ExitBtn, "X", 13, __Sailennt.Config.TextSub, Enum.Font.GothamBold, UDim2.new(0, 12, 0, 0), UDim2.new(0, 20, 1, 0), Enum.TextXAlignment.Center)
__Sailennt.Label(ExitBtn, "Выйти", 13, __Sailennt.Config.TextMain, Enum.Font.GothamMedium, UDim2.new(0, 40, 0, 0), UDim2.new(1, -40, 1, 0))

__Sailennt.Ui.Active = __Sailennt.Label(Sidebar, "• 0 активно", 10, __Sailennt.Config.TextSub, Enum.Font.GothamMedium, UDim2.new(0, 14, 0, 419), UDim2.new(1, -20, 0, 14))

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -170, 1, 0)
ContentArea.Position = UDim2.new(0, 170, 0, 0)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local SearchFrame = Instance.new("Frame")
SearchFrame.Size = UDim2.new(1, -24, 0, 34)
SearchFrame.Position = UDim2.new(0, 12, 0, 12)
SearchFrame.BackgroundColor3 = __Sailennt.Config.CardBG
SearchFrame.BorderSizePixel = 0
SearchFrame.Parent = ContentArea
__Sailennt.Corner(SearchFrame, 8)
__Sailennt.Stroke(SearchFrame, __Sailennt.Config.Stroke, 1)
__Sailennt.Label(SearchFrame, "Q", 12, __Sailennt.Config.TextSub, Enum.Font.GothamBold, UDim2.new(0, 8, 0, 0), UDim2.new(0, 20, 1, 0), Enum.TextXAlignment.Center)
for i, t in ipairs({ "C", "S" }) do
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(0, 24, 0, 24)
    B.Position = UDim2.new(1, -62 + (i - 1) * 28, 0, 5)
    B.BackgroundTransparency = 1
    B.Text = t
    B.TextSize = 15
    B.Font = Enum.Font.GothamBold
    B.TextColor3 = __Sailennt.Config.TextSub
    B.AutoButtonColor = false
    B.Parent = SearchFrame
    if i == 1 then __Sailennt.Ui.SearchCfg = B else __Sailennt.Ui.SearchSet = B end
end

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -190, 1, 0)
SearchBox.Position = UDim2.new(0, 32, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.PlaceholderText = "Поиск"
SearchBox.PlaceholderColor3 = __Sailennt.Config.TextSub
SearchBox.Text = ""
SearchBox.TextColor3 = __Sailennt.Config.TextMain
SearchBox.Font = __Sailennt.Config.Font
SearchBox.TextSize = 13
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = SearchFrame

local SortButton = Instance.new("TextButton")
SortButton.Size = UDim2.fromOffset(24, 24)
SortButton.Position = UDim2.new(1, -90, 0, 5)
SortButton.BackgroundTransparency = 1
SortButton.Text = "AZ"
SortButton.TextColor3 = __Sailennt.Config.TextSub
SortButton.TextSize = 16
SortButton.Font = Enum.Font.GothamBold
SortButton.AutoButtonColor = false
SortButton.Parent = SearchFrame
SortButton.Text = "AZ"

local ScaleDown = Instance.new("TextButton")
ScaleDown.Size = UDim2.fromOffset(22, 24)
ScaleDown.Position = UDim2.new(1, -146, 0, 5)
ScaleDown.BackgroundTransparency = 1
ScaleDown.Text = "A-"
ScaleDown.TextColor3 = __Sailennt.Config.TextSub
ScaleDown.TextSize = 11
ScaleDown.Font = Enum.Font.GothamBold
ScaleDown.AutoButtonColor = false
ScaleDown.Parent = SearchFrame
local ScaleUp = Instance.new("TextButton")
ScaleUp.Size = UDim2.fromOffset(22, 24)
ScaleUp.Position = UDim2.new(1, -120, 0, 5)
ScaleUp.BackgroundTransparency = 1
ScaleUp.Text = "A+"
ScaleUp.TextColor3 = __Sailennt.Config.TextSub
ScaleUp.TextSize = 11
ScaleUp.Font = Enum.Font.GothamBold
ScaleUp.AutoButtonColor = false
ScaleUp.Parent = SearchFrame

-- Список функций (2 колонки)
local FeatureContainer = Instance.new("ScrollingFrame")
FeatureContainer.Size = UDim2.new(1, -24, 1, -66)
FeatureContainer.Position = UDim2.new(0, 12, 0, 56)
FeatureContainer.BackgroundTransparency = 1
FeatureContainer.BorderSizePixel = 0
FeatureContainer.ScrollBarThickness = 2
FeatureContainer.ScrollBarImageColor3 = __Sailennt.Config.Accent
FeatureContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
FeatureContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
FeatureContainer.Parent = ContentArea

local GridLayout = Instance.new("UIGridLayout")
GridLayout.CellSize = UDim2.new(0.5, -4, 0, 58)
local function UpdateGrid()
    local width = ContentArea.AbsoluteSize.X
    GridLayout.CellSize = (width < 430) and UDim2.new(1, 0, 0, 58) or UDim2.new(0.5, -4, 0, 58)
end
ContentArea:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateGrid)
task.defer(UpdateGrid)
GridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
GridLayout.Parent = FeatureContainer
-- Поля вокруг сетки: карточка при hover/нажатии увеличивается (UIScale) и иначе обрезалась бы краем ScrollingFrame
do
    local GridPad = Instance.new("UIPadding")
    GridPad.PaddingLeft, GridPad.PaddingRight = UDim.new(0, 6), UDim.new(0, 6)
    GridPad.PaddingTop, GridPad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
    GridPad.Parent = FeatureContainer
end

-- // ============================================================
-- // CORE: состояние, конфиг, контекст модулей, диспетчер циклов
-- // ============================================================
local Conns = {}                 -- глобальные подключения (отключаются при Unload)
local Unloading = false
local UnloadClient = function() end -- переопределяется ниже
local Notify = function() end       -- переопределяется ниже (после создания GUI уведомлений)
local PlayEnableSound = function() end
local ApplySetting = function() end -- переопределяется ниже, после создания блюра/снега
local IsOpen = false                -- меню открыто (кликеры/триггербот при этом молчат)
local Noop = function() end

-- Недоступный API -> понятная ошибка карточки вместо падения клиента
local function Need(cond, msg)
    if not cond then error(msg, 0) end
    return cond
end
local function CleanErr(e)
    local s = tostring(e)
    s = s:gsub("^[^\n]-:%d+:%s", "", 1)
    return s
end

-- Drawing считается доступным только если реально создаются и настраиваются Square/Line/Text/Circle
-- (на части мобильных executor Drawing есть как заглушка). Принудительно отключить: getgenv().SailenntNoDrawing = true
local function DrawingWorks()
    if __Sailennt.Env.SailenntNoDrawing then return false end
    if not (Drawing and type(Drawing.new) == "function") then return false end
    local made = {}
    local ok = pcall(function()
        local s = Drawing.new("Square")
        made[#made + 1] = s
        s.Visible = false s.Thickness = 1 s.Filled = false s.Color = Color3.new(1, 1, 1)
        s.Position = Vector2.new(0, 0) s.Size = Vector2.new(1, 1)
        local l = Drawing.new("Line")
        made[#made + 1] = l
        l.Visible = false l.Thickness = 1 l.Color = Color3.new(1, 1, 1)
        l.From = Vector2.new(0, 0) l.To = Vector2.new(1, 1)
        local t = Drawing.new("Text")
        made[#made + 1] = t
        t.Visible = false t.Text = "x" t.Size = 13 t.Center = true t.Outline = true t.Color = Color3.new(1, 1, 1)
        t.Position = Vector2.new(0, 0)
        local c = Drawing.new("Circle")
        made[#made + 1] = c
        c.Visible = false c.Thickness = 1 c.Filled = false c.Radius = 5 c.Position = Vector2.new(0, 0)
    end)
    for _, d in ipairs(made) do
        if not pcall(function() d:Remove() end) then pcall(function() d:Destroy() end) end
    end
    return ok
end

-- Executor API (один раз, а не в каждом модуле)
local X = {
    request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request),
    queue = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport),
    clip = setclipboard or toclipboard or (syn and syn.setclipboard) or (Clipboard and Clipboard.set),
    fps = setfpscap,
    click = mouse1click,
    moveRel = mousemoverel,
    touch = firetouchinterest,
    cd = fireclickdetector,
    prompt = fireproximityprompt,
    save = saveinstance,
    rprint = rconsoleprint or rconsoleinfo,
    rname = rconsolename,
    draw = DrawingWorks(),
    name = (identifyexecutor and select(1, identifyexecutor())) or (getexecutorname and getexecutorname()) or "unknown",
}

-- Клик: mouse1click, а если его нет (часть executor'ов) — через VirtualInputManager
if not X.click and __Sailennt.VIM then
    X.click = function()
        local p
        if __Sailennt.IsMobile then
            local vp = __Sailennt.Workspace.CurrentCamera.ViewportSize
            p = Vector2.new(vp.X / 2, vp.Y / 2)
        else
            p = __Sailennt.UserInputService:GetMouseLocation()
        end
        __Sailennt.VIM:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 0)
        __Sailennt.VIM:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0)
    end
end

local DEX_URL = "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"
local SELF_FILE = "Sailennt.lua" -- под этим именем сохрани скрипт в workspace executor для Auto Execute On TP

local ConsoleOn = false
local function Log(msg)
    print("[Sailennt] " .. tostring(msg))
    if ConsoleOn and X.rprint then pcall(X.rprint, tostring(msg) .. "\n") end
end

-- // SETTINGS (глобальные флаги клиента) + CONFIG (файл)
local CONFIG_FILE = "Sailennt_config.json"
local CONFIG_BACKUP_FILE = "Sailennt_config.backup.json"
local CONFIG_VERSION = 2
local ActivityLog = {}
local ACTIVITY_LIMIT = 100
local function AddActivity(kind, message)
    ActivityLog[#ActivityLog + 1] = {
        time = os.date("%H:%M:%S"),
        kind = tostring(kind or "Info"),
        message = tostring(message or "")
    }
    while #ActivityLog > ACTIVITY_LIMIT do table.remove(ActivityLog, 1) end
end
local function ValidateConfig(data)
    if type(data) ~= "table" then return false, "корень конфига должен быть объектом" end
    if data.Opt ~= nil and type(data.Opt) ~= "table" then return false, "поле Opt повреждено" end
    if data.Binds ~= nil and type(data.Binds) ~= "table" then return false, "поле Binds повреждено" end
    if data.Enabled ~= nil and type(data.Enabled) ~= "table" then return false, "поле Enabled повреждено" end
    if data.Favorites ~= nil and type(data.Favorites) ~= "table" then return false, "поле Favorites повреждено" end
    if data.Enabled then
        for _, name in ipairs(data.Enabled) do
            if type(name) ~= "string" then return false, "список Enabled содержит неверное значение" end
        end
    end
    if data.Binds then
        for name, key in pairs(data.Binds) do
            if type(name) ~= "string" or (type(key) ~= "string" and key ~= false) then
                return false, "таблица Binds повреждена"
            end
        end
    end
    return true
end
-- Совместимость профиля: конфиг от более новой версии клиента не применяем вслепую
local function CheckConfigVersion(data)
    local v = data.ConfigVersion
    if v == nil then return true end
    if type(v) ~= "number" then return false, "поле ConfigVersion повреждено" end
    if v > CONFIG_VERSION then
        return false, "конфиг создан более новой версией (v" .. tostring(v) .. ", поддерживается до v" .. tostring(CONFIG_VERSION) .. ")"
    end
    return true
end
local function DecodeConfig(raw)
    if type(raw) ~= "string" or #raw > 2 * 1024 * 1024 then
        return nil, "неверный размер конфига"
    end
    local ok, data = pcall(function() return __Sailennt.HttpService:JSONDecode(raw) end)
    if not ok then return nil, "неверный JSON: " .. tostring(data) end
    local valid, why = ValidateConfig(data)
    if not valid then return nil, why end
    return data
end
local Settings = { Notifications = true, Sounds = true, Blur = false, Snow = false, AutoOpen = false, ReduceMotion = true, RestoreState = false, FloatBtn = __Sailennt.IsMobile, Theme = 1, Opacity = 0.92, Language = "ru", SortMode = "default" }
local Saved = { Opt = {}, Binds = {}, Enabled = {}, Favorites = {}, Meta = {} }
local FavoriteSet = {}
SortButton.Text = Settings.SortMode == "name" and "ZA" or "AZ"
local UIHook = { After = function() end, State = function() end } -- UI подписывается на события ядра
do
    local function ReadInitial(path)
        if not (isfile and readfile and isfile(path)) then return nil end
        local ok, raw = pcall(readfile, path)
        if not ok then return nil end
        return DecodeConfig(raw)
    end
    local data = ReadInitial(CONFIG_FILE)
    if not data then
        data = ReadInitial(CONFIG_BACKUP_FILE)
        if data then AddActivity("Config", "Загружена резервная копия конфигурации") end
    end
    if data then
        for k, v in pairs(data) do
            if Settings[k] ~= nil and type(v) == type(Settings[k]) then Settings[k] = v end
        end
        if type(data.Opt) == "table" then Saved.Opt = data.Opt end
        if type(data.Binds) == "table" then Saved.Binds = data.Binds end
        if type(data.Enabled) == "table" then Saved.Enabled = data.Enabled end
        if type(data.Favorites) == "table" then Saved.Favorites = data.Favorites end
        for _, n in ipairs(Saved.Favorites) do if type(n) == "string" then FavoriteSet[n] = true end end
    else
        AddActivity("Config", "Основной и резервный конфиги отсутствуют или повреждены")
    end
end

local Opt = {}               -- значения настроек модулей (общие по ключу)
local Binds = {}             -- Name -> Enum.KeyCode | false (явно очищено)
local BindOwner = {}         -- Enum.KeyCode -> Name
local Defs = {}              -- Name -> описание модуля
local ModuleLibrary = { Combat = {}, Movement = {}, Visuals = {}, Player = {}, World = {}, Misc = {}, Settings = {}, Favorites = {} }
local OpenDashboard, OpenActivityLog, ApplyLanguage
local ActiveLoops = {}       -- Name -> { entry, step }
local ActiveCleanups = {}    -- Name -> cleanup (наличие = модуль включён)
local ActiveCtx = {}         -- Name -> ctx

local function IsOn(name) return ActiveCleanups[name] ~= nil end

local function CollectConfig()
    local out = table.clone(Settings)
    out.ConfigVersion = CONFIG_VERSION
    out.Opt = table.clone(Opt)
    local b = {}
    for n, k in pairs(Binds) do b[n] = k and k.Name or "" end
    out.Binds = b
    local en = {}
    for n in pairs(ActiveCleanups) do
        local d = Defs[n]
        if d and not d.OneShot and d.Cat ~= "Settings" then en[#en + 1] = n end
    end
    table.sort(en)
    out.Enabled = en
    local fav = {}
    for n in pairs(FavoriteSet) do if Defs[n] then fav[#fav + 1] = n end end
    table.sort(fav)
    out.Favorites = fav
    return out
end
local function SaveConfig()
    if not writefile then return false, "writefile недоступен" end
    local okEncode, payload = pcall(function()
        local data = CollectConfig()
        data.ConfigVersion = CONFIG_VERSION
        data.SavedAt = os.time()
        return __Sailennt.HttpService:JSONEncode(data)
    end)
    if not okEncode then
        AddActivity("Error", "Не удалось сериализовать конфигурацию: " .. tostring(payload))
        return false, tostring(payload)
    end
    -- Сохраняем предыдущий корректный файл отдельно перед перезаписью.
    pcall(function()
        if isfile and readfile and isfile(CONFIG_FILE) then
            local previous = readfile(CONFIG_FILE)
            if DecodeConfig(previous) then writefile(CONFIG_BACKUP_FILE, previous) end
        end
    end)
    local okWrite, err = pcall(writefile, CONFIG_FILE, payload)
    if not okWrite then
        AddActivity("Error", "Ошибка записи конфигурации: " .. tostring(err))
        return false, tostring(err)
    end
    AddActivity("Config", "Конфигурация сохранена")
    return true
end
local SavePending = false
local function RequestSave()
    if SavePending or Unloading then return end
    SavePending = true
    task.delay(1, function()
        SavePending = false
        if not Unloading then SaveConfig() end
    end)
end
local function SetSetting(key, value)
    if Unloading then return end
    Settings[key] = value
    RequestSave()
    ApplySetting(key)
end

local function BindSet(name, key)
    local old = Binds[name]
    if old and BindOwner[old] == name then BindOwner[old] = nil end
    if key then
        local other = BindOwner[key]
        if other and other ~= name then
            Binds[other] = false
            local od = Defs[other]
            if od and od._refreshKey then od._refreshKey() end
        end
        BindOwner[key] = name
        Binds[name] = key
    else
        Binds[name] = false
    end
    local d = Defs[name]
    if d and d._refreshKey then d._refreshKey() end
end

-- Регистрация модуля: Add("Combat", { Name, Desc, Code, [OneShot, Silent, Opts, Key, Step, Interval, CharDep, Restart, DescFn] })
local function Add(Cat, def)
    assert(ModuleLibrary[Cat], "unknown category " .. tostring(Cat))
    assert(not Defs[def.Name], "duplicate module " .. tostring(def.Name))
    def.Cat = Cat
    Defs[def.Name] = def
    table.insert(ModuleLibrary[Cat], def)
    if def.Opts then
        for _, s in ipairs(def.Opts) do
            Saved.Meta[s.key] = s
            if Opt[s.key] == nil then
                local v = s.default
                local sv = Saved.Opt[s.key]
                if sv ~= nil and type(sv) == type(s.default) then v = sv end
                if s.kind == "num" then v = math.clamp(v, s.min or -math.huge, s.max or math.huge) end
                if s.kind == "choice" and not table.find(s.choices, v) then v = s.default end
                Opt[s.key] = v
            end
        end
    end
    local sb = Saved.Binds[def.Name]
    if sb == "" then
        Binds[def.Name] = false
    elseif sb ~= nil then
        local ok, kc = pcall(function() return Enum.KeyCode[sb] end)
        if ok and kc and not BindOwner[kc] then BindSet(def.Name, kc) end
    elseif def.Key and not BindOwner[def.Key] then
        BindSet(def.Name, def.Key)
    end
    return def
end

-- Описания настроек (переиспользуются разными модулями)
local O = {
    aimKey    = { key = "aimKey", label = "Клавиша наведения", kind = "choice", default = __Sailennt.IsMobile and "Always" or "RMB", choices = { "RMB", "LMB", "V", "Q", "E", "X", "Shift", "Always" } },
    aimMethod = { key = "aimMethod", label = "Способ", kind = "choice", default = "Camera", choices = { "Camera", "Mouse" } },
    aimPart   = { key = "aimPart", label = "Цель", kind = "choice", default = "Head", choices = { "Head", "HumanoidRootPart" } },
    aimMode   = { key = "aimMode", label = "Точка прицела", kind = "choice", default = __Sailennt.IsMobile and "Center" or "Mouse", choices = { "Mouse", "Center" } },
    aimFov    = { key = "aimFov", label = "FOV (px)", kind = "num", default = 120, min = 20, max = 600 },
    aimSmooth = { key = "aimSmooth", label = "Сглаживание", kind = "num", default = 0.2, min = 0, max = 0.95 },
    espMaxDist = { key = "espMaxDist", label = "Макс. дистанция (0 = без лимита)", kind = "num", default = 0, min = 0, max = 5000 },
}

-- // CONTEXT: всё, что модуль создаёт через ctx, гарантированно чистится при выключении
local function NewCtx(def)
    local ctx = { Def = def, Alive = true }
    local conns, insts, stops = {}, {}, {}
    ctx.Conn = function(c) conns[#conns + 1] = c return c end
    ctx.Inst = function(i) insts[#insts + 1] = i return i end
    ctx.OnStop = function(f) stops[#stops + 1] = f end
    ctx.Destroy = function()
        if not ctx.Alive then return end
        ctx.Alive = false
        for i = #stops, 1, -1 do pcall(stops[i]) end
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        for _, i in ipairs(insts) do pcall(function() i:Destroy() end) end
    end
    return ctx
end

-- // ЕДИНЫЙ ДИСПЕТЧЕР: одно подключение на тип шага вместо одного на модуль.
-- // Ошибка в цикле гасит только этот модуль (раньше сыпалась каждый кадр). Interval троттлит тяжёлые циклы.
local Steps = {
    Render = { name = "Render", list = {} },
    Camera = { name = "Camera", list = {} },
    Heartbeat = { name = "Heartbeat", list = {} },
    Stepped = { name = "Stepped", list = {} },
}

local function StepDisconnect(S)
    if S.conn then S.conn:Disconnect() S.conn = nil end
    if S.bound then pcall(function() __Sailennt.RunService:UnbindFromRenderStep("SailenntStep") end) S.bound = false end
end

local function StepCompact(S)
    local list, j = S.list, 0
    local n = #list
    for i = 1, n do
        local e = list[i]
        if not e.dead then
            j = j + 1
            list[j] = e
        end
    end
    for i = j + 1, n do list[i] = nil end
    if j == 0 then StepDisconnect(S) end
end

local Disable -- объявлена ниже (нужен SetModule)

local function StepRun(S, dt)
    local list = S.list
    local n = #list
    local dirty = false
    S.running = true
    for i = 1, n do
        local e = list[i]
        if e.dead then
            dirty = true
        else
            local d, go = dt, true
            if e.interval then
                e.acc = e.acc + dt
                if e.acc < e.interval then go = false else d = e.acc e.acc = 0 end
            end
            if go then
                local ok, err = pcall(e.fn, d)
                if not ok then
                    e.dead = true
                    dirty = true
                    warn("[Sailennt] " .. e.name .. ": " .. tostring(err))
                    Disable(e.name, "Ошибка: " .. CleanErr(err))
                end
            end
        end
    end
    S.running = false
    if dirty then StepCompact(S) end
end

local function StepEnsure(S)
    if S.conn or S.bound then return end
    if S.name == "Render" then
        S.conn = __Sailennt.RunService.RenderStepped:Connect(function(dt) StepRun(S, dt) end)
    elseif S.name == "Heartbeat" then
        S.conn = __Sailennt.RunService.Heartbeat:Connect(function(dt) StepRun(S, dt) end)
    elseif S.name == "Stepped" then
        S.conn = __Sailennt.RunService.Stepped:Connect(function(_, dt) StepRun(S, dt) end)
    else
        -- Camera: после камеры Roblox (иначе камерный скрипт перезаписывает наш CFrame)
        __Sailennt.RunService:BindToRenderStep("SailenntStep", Enum.RenderPriority.Camera.Value + 1, function(dt) StepRun(S, dt) end)
        S.bound = true
    end
end

local function LoopAdd(name, stepName, fn, interval)
    local S = Steps[stepName or "Render"]
    assert(S, "unknown step " .. tostring(stepName))
    local e = { name = name, fn = fn, interval = interval, acc = 0 }
    S.list[#S.list + 1] = e
    ActiveLoops[name] = { entry = e, step = S }
    StepEnsure(S)
end

local function LoopRemove(name)
    local L = ActiveLoops[name]
    if not L then return end
    ActiveLoops[name] = nil
    L.entry.dead = true
    if not L.step.running then StepCompact(L.step) end
end

-- // УПРАВЛЕНИЕ МОДУЛЯМИ
local function StopModule(Name)
    local cleanup = ActiveCleanups[Name]
    -- Сначала исключаем модуль из диспетчера, затем выполняем его очистку.
    LoopRemove(Name)
    if cleanup then
        ActiveCleanups[Name] = nil
        local ok, err = pcall(cleanup)
        if not ok then
            AddActivity("Error", "Cleanup " .. tostring(Name) .. ": " .. tostring(err))
            warn("[Sailennt] cleanup " .. tostring(Name) .. ": " .. tostring(err))
        end
    end
    local ctx = ActiveCtx[Name]
    if ctx then
        ActiveCtx[Name] = nil
        local ok, err = pcall(ctx.Destroy)
        if not ok then AddActivity("Error", "Context destroy " .. tostring(Name) .. ": " .. tostring(err)) end
    end
end

-- Включить/выключить/переключить модуль. silent = без уведомления. Возвращает итоговое состояние.
local function SetModule(def, on, silent)
    local name = def.Name
    local cur = ActiveCleanups[name] ~= nil
    if on == nil then on = not cur end
    if on == cur then return cur end
    if on then
        local ctx = NewCtx(def)
        local ok, cleanup, loop = pcall(def.Code, ctx)
        if not ok then
            ctx.Destroy()
            AddActivity("Error", "Запуск " .. name .. ": " .. tostring(cleanup))
            warn("[Sailennt] " .. name .. ": " .. tostring(cleanup))
            if not silent then Notify(name, false, "Ошибка: " .. CleanErr(cleanup)) end
            if def._visual then def._visual(true) end
            return false
        end
        ActiveCleanups[name] = cleanup or Noop
        ActiveCtx[name] = ctx
        if loop then
            local loopOK, loopErr = pcall(LoopAdd, name, def.Step, loop, def.Interval)
            if not loopOK then
                StopModule(name)
                AddActivity("Error", "Не удалось запустить цикл " .. name .. ": " .. tostring(loopErr))
                if not silent then Notify(name, false, "Ошибка запуска цикла") end
                return false
            end
        end
        AddActivity("Module", "Включён: " .. name)
        if not silent then
            Notify(name, true)
            PlayEnableSound()
            __Sailennt.Env.SailenntPush(name)
        end
    else
        StopModule(name)
        AddActivity("Module", "Выключен: " .. name)
        if not silent then
            Notify(name, false)
            PlayEnableSound()
        end
    end
    if def._visual then def._visual(true) end
    UIHook.State()
    RequestSave()
    return on
end

Disable = function(name, why)
    task.defer(function()
        local d = Defs[name]
        if d and IsOn(name) then
            SetModule(d, false, true)
            Notify(name, false, why or "Выключено")
        end
    end)
end

local function RunOneShot(def)
    local ok, res = pcall(def.Code)
    AddActivity(ok and "Action" or "Error", def.Name .. (ok and " выполнено" or (": " .. tostring(res))))
    if not ok then warn("[Sailennt] " .. def.Name .. ": " .. tostring(res)) end
    if not def.Silent then
        Notify(def.Name, ok, ok and (type(res) == "string" and res or "Выполнено") or ("Ошибка: " .. CleanErr(res)))
        if ok then PlayEnableSound() __Sailennt.Env.SailenntPush(def.Name) end
    end
    if def._refreshDesc then def._refreshDesc() end
    return ok
end

-- Активация из карточки / горячей клавиши
local function Activate(def)
    if def.OneShot then RunOneShot(def) else SetModule(def, nil, false) end
end

-- // CONFIG PROFILES: именованные конфиги, автозагрузка, экспорт/импорт JSON.
-- // Без файловых функций executor профили живут только в памяти сессии (экспорт/импорт работает всегда).
local Profiles = { Mem = {}, Index = { names = {}, autoload = "" }, Persistent = false }
do
    local FsOK = (writefile and readfile and isfile) and true or false
    local DirOK = (makefolder and isfolder) and true or false
    local PROFILE_DIR = "Sailennt/configs"
    Profiles.Persistent = FsOK

    local function Path(n)
        if DirOK then return PROFILE_DIR .. "/" .. n .. ".json" end
        return "Sailennt_cfg_" .. n .. ".json"
    end
    local function IndexPath() return DirOK and "Sailennt/profiles.json" or "Sailennt_profiles.json" end
    local function EnsureDirs()
        if DirOK then
            for _, d in ipairs({ "Sailennt", PROFILE_DIR }) do
                if not isfolder(d) then pcall(makefolder, d) end
            end
        end
    end

    function Profiles.CleanName(n)
        n = tostring(n or ""):gsub("[^%w%-_ \128-\255]", "")
        n = n:gsub("^%s+", ""):gsub("%s+$", "")
        return n:sub(1, 32)
    end
    function Profiles.LoadIndex()
        if not FsOK then return end
        pcall(function()
            local p = IndexPath()
            if isfile(p) then
                local d = __Sailennt.HttpService:JSONDecode(readfile(p))
                if type(d.names) == "table" then Profiles.Index.names = d.names end
                if type(d.autoload) == "string" then Profiles.Index.autoload = d.autoload end
            end
        end)
    end
    function Profiles.SaveIndex()
        if FsOK then pcall(function() EnsureDirs() writefile(IndexPath(), __Sailennt.HttpService:JSONEncode(Profiles.Index)) end) end
    end
    function Profiles.List() return Profiles.Index.names end

    function Profiles.Apply(data)
        for k, v in pairs(data) do
            if Settings[k] ~= nil and type(v) == type(Settings[k]) then Settings[k] = v end
        end
        if type(data.Favorites) == "table" then
            FavoriteSet = {}
            for _, n in ipairs(data.Favorites) do if type(n) == "string" and Defs[n] then FavoriteSet[n] = true end end
        end
        if type(data.Opt) == "table" then
            for k, v in pairs(data.Opt) do
                local meta = Saved.Meta[k]
                if meta and type(v) == type(meta.default) then
                    if meta.kind == "num" then v = math.clamp(v, meta.min or -math.huge, meta.max or math.huge) end
                    if meta.kind ~= "choice" or table.find(meta.choices, v) then Opt[k] = v end
                end
            end
        end
        if type(data.Binds) == "table" then
            for name, kn in pairs(data.Binds) do
                if Defs[name] then
                    if kn == "" then
                        BindSet(name, nil)
                    else
                        local ok, kc = pcall(function() return Enum.KeyCode[kn] end)
                        if ok and kc then BindSet(name, kc) end
                    end
                end
            end
        end
        for _, def in ipairs(ModuleLibrary.Settings) do
            if def.SettingKey then SetModule(def, Settings[def.SettingKey] and true or false, true) end
        end
        if type(data.Enabled) == "table" then
            local want = {}
            for _, n in ipairs(data.Enabled) do want[n] = true end
            for name, def in pairs(table.clone(Defs)) do
                if not def.OneShot and def.Cat ~= "Settings" then SetModule(def, want[name] == true, true) end
            end
        end
        RequestSave()
        UIHook.After()
    end

    function Profiles.Save(name)
        name = Profiles.CleanName(name)
        if name == "" then return false, "введи имя конфига" end
        local json = __Sailennt.HttpService:JSONEncode(CollectConfig())
        if FsOK then
            EnsureDirs()
            if not pcall(writefile, Path(name), json) then return false, "не удалось записать файл" end
        else
            Profiles.Mem[name] = json
        end
        if not table.find(Profiles.Index.names, name) then
            table.insert(Profiles.Index.names, name)
            table.sort(Profiles.Index.names)
        end
        Profiles.SaveIndex()
        return true, name
    end
    function Profiles.Load(name)
        local s
        if FsOK then
            local p = Path(name)
            if isfile(p) then
                local ok, r = pcall(readfile, p)
                if ok then s = r end
            end
        else
            s = Profiles.Mem[name]
        end
        if not s then return false, "конфиг не найден" end
        local data, decodeErr = DecodeConfig(s)
        if not data then
            AddActivity("Error", "Повреждён профиль " .. tostring(name) .. ": " .. tostring(decodeErr))
            return false, "файл повреждён: " .. tostring(decodeErr)
        end
        local compatible, why = CheckConfigVersion(data)
        if not compatible then
            AddActivity("Error", "Профиль " .. tostring(name) .. " несовместим: " .. tostring(why))
            return false, why
        end
        Profiles.Apply(data)
        AddActivity("Config", "Загружен профиль: " .. tostring(name))
        return true
    end
    function Profiles.Delete(name)
        local i = table.find(Profiles.Index.names, name)
        if i then table.remove(Profiles.Index.names, i) end
        if Profiles.Index.autoload == name then Profiles.Index.autoload = "" end
        Profiles.Mem[name] = nil
        if FsOK and delfile then pcall(delfile, Path(name)) end
        Profiles.SaveIndex()
    end
    function Profiles.SetAutoload(name)
        Profiles.Index.autoload = name or ""
        Profiles.SaveIndex()
    end
    function Profiles.Export()
        local d = CollectConfig()
        d.Opt.webhookUrl = nil -- не отдаём секрет при шаринге конфига
        return __Sailennt.HttpService:JSONEncode(d)
    end
    function Profiles.Import(str)
        local data, decodeErr = DecodeConfig(str)
        if not data then return false, "неверный JSON: " .. tostring(decodeErr) end
        local compatible, why = CheckConfigVersion(data)
        if not compatible then
            AddActivity("Error", "Импорт отклонён: " .. tostring(why))
            return false, why
        end
        Profiles.Apply(data)
        AddActivity("Config", "Конфигурация импортирована")
        return true
    end
end

-- // ПЕРСОНАЖ: актуальные ссылки + перезапуск модулей, зависящих от тела
local function Root()
    if __Sailennt.RootPart and __Sailennt.RootPart.Parent then return __Sailennt.RootPart end
    return nil
end
local function GetHum()
    if __Sailennt.Humanoid and __Sailennt.Humanoid.Parent then return __Sailennt.Humanoid end
    return nil
end

local RayParams = RaycastParams.new() -- общий фильтр «без моего персонажа» (не создаётся заново на каждый луч)
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.FilterDescendantsInstances = { __Sailennt.Character }

Conns[#Conns + 1] = __Sailennt.LocalPlayer.CharacterAdded:Connect(function(c)
    __Sailennt.Character = c
    AddActivity("Character", "Персонаж обновлён")
    __Sailennt.Humanoid = c:WaitForChild("Humanoid", 10)
    __Sailennt.RootPart = c:WaitForChild("HumanoidRootPart", 10)
    if not __Sailennt.Humanoid or not __Sailennt.RootPart then
        AddActivity("Error", "Персонаж загружен не полностью; CharDep-модули будут пропущены")
        return
    end
    RayParams.FilterDescendantsInstances = { c }
    task.wait(0.4)
    if Unloading then return end
    for name, def in pairs(table.clone(Defs)) do
        if def.CharDep and IsOn(name) then
            SetModule(def, false, true)
            SetModule(def, true, true)
            if not IsOn(name) then
                AddActivity("Error", "Не удалось восстановить модуль после респавна: " .. name)
                Notify(name, false, "Не удалось перезапустить после респавна")
            else
                AddActivity("Character", "Модуль восстановлен: " .. name)
            end
        end
    end
end)

-- // ИГРОКИ: список без LocalPlayer + кэш частей тела (вместо FindFirstChild каждый кадр)
local Others = {}
local PartsCache = setmetatable({}, { __mode = "k" })
for _, p in ipairs(__Sailennt.Players:GetPlayers()) do
    if p ~= __Sailennt.LocalPlayer then Others[#Others + 1] = p end
end
local PlayerRemovedHooks = {} -- сервисы подписываются, чтобы освобождать ресурсы игрока
Conns[#Conns + 1] = __Sailennt.Players.PlayerAdded:Connect(function(p)
    if p ~= __Sailennt.LocalPlayer then Others[#Others + 1] = p end
end)
Conns[#Conns + 1] = __Sailennt.Players.PlayerRemoving:Connect(function(p)
    local i = table.find(Others, p)
    if i then table.remove(Others, i) end
    PartsCache[p] = nil
    for _, f in ipairs(PlayerRemovedHooks) do pcall(f, p) end
end)

local function Parts(p)
    local c = p.Character
    if not c then return nil end
    local e = PartsCache[p]
    if not e then
        e = {}
        PartsCache[p] = e
    end
    if e.Char ~= c or not e.Hum or not e.Root or not e.Head then
        e.Char = c
        e.Hum = c:FindFirstChildOfClass("Humanoid")
        e.Root = c:FindFirstChild("HumanoidRootPart")
        e.Head = c:FindFirstChild("Head")
    end
    if not e.Hum or not e.Root or not e.Root.Parent then return nil end
    return e
end

local function IsEnemy(p)
    if __Sailennt.Env.SailenntWL and __Sailennt.Env.SailenntWL[p.UserId] then return false end -- белый список (Player List)
    if __Sailennt.Env.SailenntFr and ActiveCleanups["Whitelist Friends"] and __Sailennt.Env.SailenntFr[p.UserId] then return false end
    if ActiveCleanups["Team Check"] and p.Team and p.Team == __Sailennt.LocalPlayer.Team then return false end
    return true
end

local function GetTarget()
    local name = Opt.targetName
    if name and name ~= "nearest" then
        for i = 1, #Others do
            local p = Others[i]
            if p.Name == name or p.DisplayName == name then return p end
        end
    end
    local r = Root()
    local origin = r and r.Position or __Sailennt.Workspace.CurrentCamera.CFrame.Position
    local best, bd = nil, math.huge
    for i = 1, #Others do
        local p = Others[i]
        local e = Parts(p)
        if e and e.Hum.Health > 0 and IsEnemy(p) then
            local d = (e.Root.Position - origin).Magnitude
            if d < bd then best, bd = p, d end
        end
    end
    return best
end

-- Подписка на персонажей всех игроков: fn(player, char) -> destroyer. Чистится при выключении модуля.
local function ForEachCharacter(ctx, fn)
    local live, hooks = {}, {}
    local function clear(p)
        local d = live[p]
        live[p] = nil
        if d then pcall(d) end
    end
    local function attach(p, c)
        clear(p)
        local ok, d = pcall(fn, p, c)
        if not ok then warn("[Sailennt] " .. ctx.Def.Name .. ": " .. tostring(d)) end
        if ok and d then live[p] = d end
    end
    local function hook(p)
        if p == __Sailennt.LocalPlayer or hooks[p] then return end
        hooks[p] = {
            p.CharacterAdded:Connect(function(c) attach(p, c) end),
            p.CharacterRemoving:Connect(function() clear(p) end),
        }
        if p.Character then attach(p, p.Character) end
    end
    ctx.Conn(__Sailennt.Players.PlayerAdded:Connect(hook))
    ctx.Conn(__Sailennt.Players.PlayerRemoving:Connect(function(p)
        clear(p)
        local h = hooks[p]
        if h then
            h[1]:Disconnect()
            h[2]:Disconnect()
            hooks[p] = nil
        end
    end))
    ctx.OnStop(function()
        for p in pairs(table.clone(live)) do clear(p) end
        for p, h in pairs(hooks) do
            h[1]:Disconnect()
            h[2]:Disconnect()
        end
        table.clear(hooks)
    end)
    for _, p in ipairs(__Sailennt.Players:GetPlayers()) do hook(p) end
end

-- // AIM: общий выбор цели для Aimbot / Silent Aim (считается не чаще раза за кадр)
local Aim = { Part = nil, Pos = nil, Users = 0, Circle = nil, T = 0 }
local WHITE = Color3.new(1, 1, 1)

local function TargetVisible(part)
    local cam = __Sailennt.Workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local hit = __Sailennt.Workspace:Raycast(origin, part.Position - origin, RayParams)
    return (not hit) or hit.Instance:IsDescendantOf(part.Parent)
end

function Aim.Point()
    if Opt.aimMode == "Center" then
        local vp = __Sailennt.Workspace.CurrentCamera.ViewportSize
        return Vector2.new(vp.X / 2, vp.Y / 2)
    end
    return __Sailennt.UserInputService:GetMouseLocation()
end

function Aim.Update()
    local now = os.clock()
    if now - Aim.T < 0.002 then return end -- уже посчитано в этом кадре
    Aim.T = now
    local cam = __Sailennt.Workspace.CurrentCamera
    local point = Aim.Point()
    local wall = ActiveCleanups["Wall Check"] ~= nil
    local predict = ActiveCleanups["Velocity Prediction"] ~= nil
    local want = Opt.aimPart
    local best, bd = nil, math.huge
    local fov = Opt.aimFov
    for i = 1, #Others do
        local p = Others[i]
        local e = Parts(p)
        if e and e.Hum.Health > 0 and IsEnemy(p) then
            local part = (want == "Head" and e.Head) or (want == "HumanoidRootPart" and e.Root) or e.Char:FindFirstChild(want)
            if part then
                local sp, on = cam:WorldToViewportPoint(part.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - point).Magnitude
                    if d <= fov and d < bd and (not wall or TargetVisible(part)) then best, bd = part, d end
                end
            end
        end
    end
    Aim.Part = best
    if best then
        local pos = best.Position
        if predict then
            local lead = math.clamp((pos - cam.CFrame.Position).Magnitude / 1000, 0, 0.3)
            pos = pos + best.AssemblyLinearVelocity * lead
        end
        Aim.Pos = pos
    else
        Aim.Pos = nil
    end
    local c = Aim.Circle
    if c then
        c.Visible = true
        c.Position = point
        c.Radius = fov
    end
end

function Aim.Acquire()
    Aim.Users = Aim.Users + 1
    if Aim.Users == 1 and X.draw and not Aim.Circle then
        local ok, c = pcall(Drawing.new, "Circle")
        if ok and c then
            c.Thickness = 1
            c.Filled = false
            c.Color = WHITE
            c.Transparency = 0.6
            c.Visible = false
            Aim.Circle = c
        end
    end
    local done = false
    return function()
        if done then return end
        done = true
        Aim.Users = Aim.Users - 1
        if Aim.Users <= 0 then
            Aim.Users = 0
            Aim.Part, Aim.Pos = nil, nil
            if Aim.Circle then
                pcall(function() Aim.Circle:Remove() end)
                Aim.Circle = nil
            end
        end
    end
end

local AimKeys = { V = Enum.KeyCode.V, Q = Enum.KeyCode.Q, E = Enum.KeyCode.E, X = Enum.KeyCode.X, Shift = Enum.KeyCode.LeftShift }
local function AimKeyDown()
    local k = Opt.aimKey
    if k == "Always" then return true end
    if k == "RMB" then return __Sailennt.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    if k == "LMB" then return __Sailennt.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
    local kc = AimKeys[k]
    return kc ~= nil and __Sailennt.UserInputService:IsKeyDown(kc)
end

-- // HOOK: один общий __namecall (silent aim / anti-kick / anti-teleport / god / remote spy).
-- // Ставится только когда нужен; при выключении всех флагов handler сразу пропускает вызов дальше.
local Hook = { Installed = false, Old = nil, On = {}, Count = 0, Log = {}, LastSpy = 0 }
do
local gnm, snm = getnamecallmethod, setnamecallmethod

local function Serialize(...)
    local n = select("#", ...)
    local out = {}
    for i = 1, math.min(n, 8) do
        local v = select(i, ...)
        local ok, s = pcall(function()
            if typeof(v) == "Instance" then return v:GetFullName() end
            return tostring(v)
        end)
        out[i] = ok and s or "?"
    end
    local s = table.concat(out, ", ")
    return #s > 300 and s:sub(1, 300) .. "..." or s
end

local function NcHandler(self, ...)
    local method = gnm()
    if Hook.Count == 0 or checkcaller() then return Hook.Old(self, ...) end
    local On = Hook.On
    if On.antiKick and self == __Sailennt.LocalPlayer and type(method) == "string" and method:lower() == "kick" then return nil end
    if On.antiTp and self == __Sailennt.TeleportService and type(method) == "string" and method:find("Teleport") then return nil end
    if On.god and method == "BreakJoints" and __Sailennt.Character and typeof(self) == "Instance" and self:IsDescendantOf(__Sailennt.Character) then return nil end
    if On.spy and (method == "FireServer" or method == "InvokeServer") then
        local now = os.clock()
        if now - Hook.LastSpy > 0.03 then
            Hook.LastSpy = now
            local line = self:GetFullName() .. " :" .. method .. "(" .. Serialize(...) .. ")"
            table.insert(Hook.Log, 1, line)
            if #Hook.Log > 100 then table.remove(Hook.Log) end
            Log("[Remote] " .. line)
        end
    end
    if On.silent and Aim.Pos and self == __Sailennt.Workspace then
        -- подмена луча на цель; только для лучей из окрестности камеры (иначе ломается чужая логика игры)
        local cam = __Sailennt.Workspace.CurrentCamera
        local a1, a2 = ...
        if method == "Raycast" and typeof(a1) == "Vector3" and typeof(a2) == "Vector3" and (a1 - cam.CFrame.Position).Magnitude < 30 then
            local dir = Aim.Pos - a1
            if dir.Magnitude > 0 then
                if snm then snm(method) end
                return Hook.Old(self, a1, dir.Unit * a2.Magnitude, select(3, ...))
            end
        elseif (method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") and typeof(a1) == "Ray" and (a1.Origin - cam.CFrame.Position).Magnitude < 30 then
            local dir = Aim.Pos - a1.Origin
            if dir.Magnitude > 0 then
                if snm then snm(method) end
                return Hook.Old(self, Ray.new(a1.Origin, dir.Unit * a1.Direction.Magnitude), select(2, ...))
            end
        end
    end
    if snm then snm(method) end
    return Hook.Old(self, ...)
end

function Hook.Install()
    if Hook.Installed then return true end
    if not gnm or not checkcaller then return false end
    -- Состояние в Env: при перезапуске скрипта переиспользуем уже стоящий хук вместо наслоения нового
    local H = __Sailennt.Env.SailenntNc
    if not H then H = {} __Sailennt.Env.SailenntNc = H end
    H.Dispatch = NcHandler
    if H.Old then
        Hook.Old = H.Old
        Hook.Installed = true
        return true
    end
    local ok = pcall(function()
        local stub = function(self, ...) return H.Dispatch(self, ...) end
        local fn = newcclosure and newcclosure(stub) or stub
        if hookmetamethod then
            H.Old = hookmetamethod(game, "__namecall", fn)
            Hook.Old = H.Old
        elseif getrawmetatable and setreadonly then
            local mt = getrawmetatable(game)
            H.Old = mt.__namecall
            Hook.Old = H.Old
            setreadonly(mt, false)
            mt.__namecall = fn
            setreadonly(mt, true)
        end
    end)
    Hook.Installed = ok and Hook.Old ~= nil
    if not Hook.Installed then H.Old = nil end
    return Hook.Installed
end

function Hook.Acquire(flag)
    Need(Hook.Install(), "hookmetamethod недоступен в этом executor")
    if not Hook.On[flag] then Hook.Count = Hook.Count + 1 end
    Hook.On[flag] = true
    local done = false
    return function()
        if done then return end
        done = true
        if Hook.On[flag] then Hook.Count = Hook.Count - 1 end
        Hook.On[flag] = nil
    end
end

end

-- // DRAWING / ESP: один общий цикл на все ESP-модули, объекты создаются лениво и освобождаются при выключении
local Drawings = {}
local Esp = { Flags = {}, Pool = {}, Users = 0 }
local RED = Color3.fromRGB(255, 80, 80)
local HEAD_OFF, FOOT_OFF = Vector3.new(0, 0.6, 0), Vector3.new(0, 3, 0)
local ESP_KEYS = { "box", "name", "dist", "hpbg", "hp", "tracer" }
local EP = {
    box = { Thickness = 1, Filled = false, Color = RED },
    name = { Size = 13, Center = true, Outline = true, Color = WHITE },
    dist = { Size = 11, Center = true, Outline = true, Color = Color3.fromRGB(200, 200, 200) },
    hpbg = { Thickness = 2, Color = Color3.fromRGB(20, 20, 20) },
    hp = { Thickness = 2, Color = Color3.fromRGB(80, 220, 80) },
    tracer = { Thickness = 1, Color = RED },
}
local GREEN = Color3.fromRGB(80, 220, 80)

local function NewDraw(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do pcall(function() d[k] = v end) end -- неподдерживаемое свойство не должно ронять ESP
    pcall(function() d.Visible = false end)
    Drawings[d] = true
    return d
end
local function KillDraw(d)
    Drawings[d] = nil
    if not pcall(function() d:Remove() end) then pcall(function() d:Destroy() end) end
end
local function EspKill(p)
    local set = Esp.Pool[p]
    if not set then return end
    Esp.Pool[p] = nil
    for i = 1, #ESP_KEYS do
        local d = set[ESP_KEYS[i]]
        if d then KillDraw(d) end
    end
end
local function EspHide(set)
    for i = 1, #ESP_KEYS do
        local d = set[ESP_KEYS[i]]
        if d and d.Visible then d.Visible = false end
    end
end

local function EspLoop()
    local F = Esp.Flags
    local cam = __Sailennt.Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local camPos = cam.CFrame.Position
    local maxD = Opt.espMaxDist
    local teamCol = ActiveCleanups["ESP Team Color"] ~= nil
    local distCol = Opt.tracerDistColor
    local origin = (Opt.tracerFrom == "Center") and Vector2.new(vp.X / 2, vp.Y / 2) or Vector2.new(vp.X / 2, vp.Y)
    for i = 1, #Others do
        local p = Others[i]
        local set = Esp.Pool[p]
        local e = Parts(p)
        local drawn = false
        if e and e.Head and e.Hum.Health > 0 and IsEnemy(p) then
            local dist = (e.Root.Position - camPos).Magnitude
            if maxD <= 0 or dist <= maxD then
                local tp, on = cam:WorldToViewportPoint(e.Head.Position + HEAD_OFF)
                if on and tp.Z > 0 then
                    local bp = cam:WorldToViewportPoint(e.Root.Position - FOOT_OFF)
                    if not set then
                        set = { distTxt = "", nameTxt = "" }
                        Esp.Pool[p] = set
                    end
                    drawn = true
                    local hpx = math.abs(bp.Y - tp.Y)
                    local wpx = hpx * 0.55
                    local x, y = tp.X - wpx / 2, math.min(tp.Y, bp.Y)
                    local col = (teamCol and p.TeamColor) and p.TeamColor.Color or RED
                    if F.box then
                        local b = set.box or NewDraw("Square", EP.box)
                        set.box = b
                        b.Position = Vector2.new(x, y)
                        b.Size = Vector2.new(wpx, hpx)
                        b.Color = col
                        b.Visible = true
                    elseif set.box then set.box.Visible = false end
                    if F.name then
                        local n = set.name or NewDraw("Text", EP.name)
                        set.name = n
                        if set.nameTxt ~= p.Name then n.Text = p.Name set.nameTxt = p.Name end
                        n.Position = Vector2.new(tp.X, y - 16)
                        n.Color = col
                        n.Visible = true
                    elseif set.name then set.name.Visible = false end
                    if F.dist then
                        local d = set.dist or NewDraw("Text", EP.dist)
                        set.dist = d
                        local txt = math.floor(dist) .. "m"
                        if set.distTxt ~= txt then d.Text = txt set.distTxt = txt end
                        d.Position = Vector2.new(tp.X, y + hpx + 2)
                        d.Visible = true
                    elseif set.dist then set.dist.Visible = false end
                    if F.hp then
                        local bg = set.hpbg or NewDraw("Line", EP.hpbg)
                        local hp = set.hp or NewDraw("Line", EP.hp)
                        set.hpbg, set.hp = bg, hp
                        local frac = math.clamp(e.Hum.Health / math.max(e.Hum.MaxHealth, 1), 0, 1)
                        bg.From = Vector2.new(x - 5, y + hpx)
                        bg.To = Vector2.new(x - 5, y)
                        bg.Visible = true
                        hp.From = Vector2.new(x - 5, y + hpx)
                        hp.To = Vector2.new(x - 5, y + hpx - hpx * frac)
                        hp.Color = RED:Lerp(GREEN, frac)
                        hp.Visible = true
                    else
                        if set.hpbg then set.hpbg.Visible = false end
                        if set.hp then set.hp.Visible = false end
                    end
                    if F.tracer then
                        local t = set.tracer or NewDraw("Line", EP.tracer)
                        set.tracer = t
                        t.From = origin
                        t.To = Vector2.new(bp.X, bp.Y)
                        if distCol then
                            t.Color = (dist < 50 and Color3.fromRGB(255, 0, 0)) or (dist < 150 and Color3.fromRGB(255, 165, 0)) or Color3.fromRGB(0, 255, 0)
                        else
                            t.Color = col
                        end
                        t.Visible = true
                    elseif set.tracer then set.tracer.Visible = false end
                end
            end
        end
        if not drawn and set then EspHide(set) end
    end
end

PlayerRemovedHooks[#PlayerRemovedHooks + 1] = EspKill

-- Запасной ESP без Drawing (если executor его не даёт): Highlight-контур + BillboardGui, обновление 10 раз в секунду
local Fb = { Live = {} }
local function FbKill(p)
    local l = Fb.Live[p]
    if l then
        Fb.Live[p] = nil
        pcall(function() l.hl:Destroy() end)
        pcall(function() l.gui:Destroy() end)
    end
end
local function FbBuild(p, e)
    local hl = Instance.new("Highlight")
    hl.Adornee = e.Char
    hl.FillTransparency = 1
    hl.OutlineColor = RED
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = e.Char
    local gui = Instance.new("BillboardGui")
    gui.Adornee = e.Head
    gui.Size = UDim2.new(0, 100, 0, 44)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.Parent = e.Head
    local function txt(y, size)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, 0, 0, size + 4)
        t.Position = UDim2.new(0, 0, 0, y)
        t.BackgroundTransparency = 1
        t.TextColor3 = WHITE
        t.Font = Enum.Font.Code
        t.TextSize = size
        t.TextStrokeTransparency = 0
        t.Parent = gui
        return t
    end
    local nameL = txt(0, 14)
    nameL.Text = p.Name
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 5)
    bar.Position = UDim2.new(0, 0, 0, 20)
    bar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    bar.BorderSizePixel = 0
    bar.Parent = gui
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = GREEN
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local l = { char = e.Char, hl = hl, gui = gui, name = nameL, bar = bar, fill = fill, dist = txt(27, 12) }
    Fb.Live[p] = l
    return l
end
local function FbLoop()
    local F = Esp.Flags
    local camera = __Sailennt.Workspace.CurrentCamera
    if not camera then return end
    local camPos = camera.CFrame.Position
    local maxD = Opt.espMaxDist
    for i = 1, #Others do
        local p = Others[i]
        local e = Parts(p)
        local l = Fb.Live[p]
        local show = e and e.Head and e.Hum.Health > 0 and IsEnemy(p)
        if show then
            local dist = (e.Root.Position - camPos).Magnitude
            show = maxD <= 0 or dist <= maxD
            if show then
                if l and (l.char ~= e.Char or not l.gui.Parent) then FbKill(p) l = nil end
                l = l or FbBuild(p, e)
                l.hl.Enabled = F.box ~= nil
                l.gui.Enabled = (F.name or F.hp or F.dist) ~= nil
                l.name.Visible = F.name ~= nil
                l.bar.Visible = F.hp ~= nil
                l.dist.Visible = F.dist ~= nil
                if F.hp then
                    local f = math.clamp(e.Hum.Health / math.max(e.Hum.MaxHealth, 1), 0, 1)
                    l.fill.Size = UDim2.new(f, 0, 1, 0)
                    l.fill.BackgroundColor3 = RED:Lerp(GREEN, f)
                end
                if F.dist then l.dist.Text = math.floor(dist) .. "m" end
            end
        end
        if not show and l then
            l.hl.Enabled = false
            l.gui.Enabled = false
        end
    end
end
PlayerRemovedHooks[#PlayerRemovedHooks + 1] = FbKill

-- Тик ESP: Drawing-цикл под pcall; при ошибке рисование удаляется и включается запасной ESP (Highlight), с уведомлением
local FbAcc = 0
local function EspTick(dt)
    if Esp.UseFb or not X.draw then
        FbAcc = FbAcc + (dt or 0)
        if FbAcc < 0.1 then return end -- запасной ESP: 10 обновлений в секунду, не каждый кадр
        FbAcc = 0
        local fbOk, fbErr = pcall(FbLoop)
        if not fbOk then
            warn("[Sailennt] ESP fallback: " .. tostring(fbErr))
            Log("Запасной ESP: " .. CleanErr(fbErr))
        end
        return
    end
    local ok, err = pcall(EspLoop)
    if not ok then
        warn("[Sailennt] ESP Drawing: " .. tostring(err))
        Log("ESP Drawing сломался (" .. CleanErr(err) .. "), переключаюсь на запасной ESP")
        Esp.UseFb = true
        for p in pairs(table.clone(Esp.Pool)) do EspKill(p) end
        Notify("ESP", false, "Drawing не работает, включён запасной ESP")
    end
end

function Esp.Acquire(flag)
    if not X.draw then Need(flag ~= "tracer", "Tracers требуют Drawing API (его нет в этом executor)") end
    Esp.Flags[flag] = (Esp.Flags[flag] or 0) + 1
    Esp.Users = Esp.Users + 1
    if Esp.Users == 1 then LoopAdd("svc:esp", "Render", EspTick) end
    local done = false
    return function()
        if done then return end
        done = true
        Esp.Flags[flag] = Esp.Flags[flag] - 1
        if Esp.Flags[flag] <= 0 then Esp.Flags[flag] = nil end
        Esp.Users = Esp.Users - 1
        if Esp.Users <= 0 then
            Esp.Users = 0
            LoopRemove("svc:esp")
            for p in pairs(table.clone(Esp.Pool)) do EspKill(p) end
            for p in pairs(table.clone(Fb.Live)) do FbKill(p) end
        end
    end
end

-- // Общие фабрики модулей
local Mk = {}
function Mk.Setting(Name, Desc, Key)
    return {
        Name = Name,
        Desc = Desc,
        SettingKey = Key,
        Code = function()
            SetSetting(Key, true)
            return function() SetSetting(Key, false) end, nil
        end
    }
end

function Mk.Flag(Name, Desc)
    return { Name = Name, Desc = Desc, Code = function() return Noop end }
end

function Mk.Cycle(Name, Desc, key, choices, title)
    return {
        Name = Name,
        Desc = Desc,
        OneShot = true,
        Opts = { { key = key, label = title, kind = "choice", default = choices[1], choices = choices } },
        DescFn = function() return title .. ": " .. tostring(Opt[key]) end,
        Code = function()
            local i = table.find(choices, Opt[key]) or 0
            Opt[key] = choices[i % #choices + 1]
            RequestSave()
            return title .. " = " .. tostring(Opt[key])
        end
    }
end

function Mk.Lighting(Name, Desc, props)
    return {
        Name = Name,
        Desc = Desc,
        Step = "Heartbeat",
        Code = function()
            local Old = {}
            for k in pairs(props) do Old[k] = __Sailennt.Lighting[k] end
            local Loop = function()
                for k, v in pairs(props) do
                    if __Sailennt.Lighting[k] ~= v then __Sailennt.Lighting[k] = v end
                end
            end
            return function()
                for k, v in pairs(Old) do __Sailennt.Lighting[k] = v end
            end, Loop
        end
    }
end

function Mk.Effect(Name, Desc, ClassName, props)
    return {
        Name = Name,
        Desc = Desc,
        Code = function(ctx)
            local e = Instance.new(ClassName)
            e.Name = "Sailennt_" .. ClassName
            for k, v in pairs(props) do e[k] = v end
            e.Parent = __Sailennt.Lighting
            ctx.Inst(e)
            return nil, nil
        end
    }
end

local HudModule
do
-- Стек HUD-панелей слева сверху (под HUD Overlay)
local HudStack
local HudOrder = 0
local function GetHudStack()
    if HudStack and HudStack.Parent then return HudStack end
    HudStack = Instance.new("Frame")
    HudStack.Name = "HudStack"
    HudStack.Position = UDim2.new(0, 12, 0, 46)
    HudStack.Size = UDim2.new(0, 240, 0, 200)
    HudStack.BackgroundTransparency = 1
    HudStack.Parent = ScreenGui
    local L = Instance.new("UIListLayout")
    L.Padding = UDim.new(0, 6)
    L.SortOrder = Enum.SortOrder.LayoutOrder
    L.Parent = HudStack
    return HudStack
end

HudModule = function(Name, Desc, getText, height)
    return {
        Name = Name,
        Desc = Desc,
        Code = function(ctx)
            HudOrder = HudOrder + 1
            local P = Instance.new("Frame")
            P.Size = UDim2.new(0, 240, 0, height or 26)
            P.LayoutOrder = HudOrder
            P.BackgroundColor3 = __Sailennt.Config.CardBG
            P.BackgroundTransparency = 0.1
            P.BorderSizePixel = 0
            P.Parent = GetHudStack()
            ctx.Inst(P)
            __Sailennt.Corner(P, 6)
            __Sailennt.Stroke(P, __Sailennt.Config.Stroke, 1)
            local T = __Sailennt.Label(P, "", 12, __Sailennt.Config.TextMain, Enum.Font.GothamMedium, UDim2.new(0, 10, 0, 0), UDim2.new(1, -20, 1, 0))
            if height and height > 26 then
                T.TextYAlignment = Enum.TextYAlignment.Top
                T.Position = UDim2.new(0, 10, 0, 6)
                T.Size = UDim2.new(1, -20, 1, -12)
            end
            local Loop = function()
                local ok, txt = pcall(getText)
                if ok and T.Text ~= txt then T.Text = txt end
            end
            return nil, Loop
        end,
        Step = "Heartbeat",
        Interval = 0.2,
    }
end
end
do

-- // RENDER (Visuals) ---------------------------------------------
-- ESP на Drawing: коробки / имена / HP / дистанция / трассеры (один общий цикл, см. Esp)
local function EspModule(Name, Desc, flag, key)
    return {
        Name = Name,
        Desc = Desc,
        Key = key,
        Opts = { O.espMaxDist },
        Code = function() return Esp.Acquire(flag) end
    }
end
Add("Visuals", EspModule("ESP Boxes", "Рамки игроков (Drawing)", "box", Enum.KeyCode.B))
Add("Visuals", EspModule("ESP Names", "Ники над игроками (Drawing)", "name"))
Add("Visuals", EspModule("ESP Health", "Полоска HP рядом с рамкой (Drawing)", "hp"))
Add("Visuals", EspModule("ESP Distance", "Дистанция под игроком (Drawing)", "dist"))
Add("Visuals", {
    Name = "Tracers (Lines)",
    Desc = "Линии к игрокам (цвет по дистанции)",
    Opts = {
        { key = "tracerFrom", label = "Откуда", kind = "choice", default = "Bottom", choices = { "Bottom", "Center" } },
        { key = "tracerDistColor", label = "Цвет по дистанции", kind = "bool", default = true },
        O.espMaxDist,
    },
    Code = function() return Esp.Acquire("tracer") end
})
Add("Visuals", Mk.Flag("ESP Team Color", "Цвет ESP / Chams по TeamColor цели"))

-- ESP без Drawing: контур Highlight + BillboardGui (ник, HP, дистанция). Работает в любом executor.
-- Уважает Team Check и ESP Team Color; всё создаётся через ctx и удаляется при выключении.
Add("Visuals", {
    Name = "ESP Outline (No Drawing)",
    Desc = "Контур, ник, HP и дистанция без Drawing API",
    Step = "Heartbeat",
    Interval = 0.1,
    Opts = { O.espMaxDist },
    Code = function(ctx)
        local live = {}
        local box = ctx.Inst(Instance.new("Folder"))
        box.Name = RandName(10)
        ProtectGui(box)

        local function kill(p)
            local l = live[p]
            if not l then return end
            live[p] = nil
            pcall(function() l.hl:Destroy() end)
            pcall(function() l.gui:Destroy() end)
        end

        local function build(p, char, head)
            local hl = Instance.new("Highlight")
            hl.Adornee = char
            hl.FillTransparency = 0.85
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = box

            local gui = Instance.new("BillboardGui")
            gui.Adornee = head
            gui.Size = UDim2.fromOffset(120, 46)
            gui.StudsOffset = Vector3.new(0, 3, 0)
            gui.AlwaysOnTop = true
            gui.LightInfluence = 0
            gui.ResetOnSpawn = false
            gui.Parent = box

            local function label(y, size)
                local t = Instance.new("TextLabel")
                t.Size = UDim2.new(1, 0, 0, size + 4)
                t.Position = UDim2.new(0, 0, 0, y)
                t.BackgroundTransparency = 1
                t.TextColor3 = WHITE
                t.Font = Enum.Font.Code
                t.TextSize = size
                t.TextStrokeTransparency = 0
                t.Parent = gui
                return t
            end
            local nameL = label(0, 14)
            nameL.Text = (p.DisplayName ~= "" and p.DisplayName) or p.Name
            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, 0, 0, 5)
            bar.Position = UDim2.new(0, 0, 0, 20)
            bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            bar.BorderSizePixel = 0
            bar.Parent = gui
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(1, 0, 1, 0)
            fill.BackgroundColor3 = GREEN
            fill.BorderSizePixel = 0
            fill.Parent = bar

            local l = { char = char, head = head, hl = hl, gui = gui, name = nameL, fill = fill, dist = label(27, 12) }
            live[p] = l
            return l
        end

        ctx.Conn(__Sailennt.Players.PlayerRemoving:Connect(kill))
        ctx.OnStop(function()
            for p in pairs(table.clone(live)) do kill(p) end
        end)

        return Noop, function()
            local cam = __Sailennt.Workspace.CurrentCamera
            if not cam then return end
            local camPos = cam.CFrame.Position
            local maxD = Opt.espMaxDist
            local teamCol = ActiveCleanups["ESP Team Color"] ~= nil
            for i = 1, #Others do
                local p = Others[i]
                local e = Parts(p)
                local l = live[p]
                local show = e ~= nil and e.Head ~= nil and e.Hum.Health > 0 and IsEnemy(p)
                local dist = 0
                if show then
                    dist = (e.Root.Position - camPos).Magnitude
                    show = maxD <= 0 or dist <= maxD
                end
                if show then
                    if l and (l.char ~= e.Char or l.head ~= e.Head or not l.hl.Parent or not l.gui.Parent) then
                        kill(p)
                        l = nil
                    end
                    l = l or build(p, e.Char, e.Head)
                    local col = (teamCol and p.Team ~= nil and p.TeamColor and p.TeamColor.Color) or RED
                    l.hl.Enabled = true
                    l.hl.OutlineColor = col
                    l.hl.FillColor = col
                    l.gui.Enabled = true
                    l.name.TextColor3 = col
                    local f = math.clamp(e.Hum.Health / math.max(e.Hum.MaxHealth, 1), 0, 1)
                    l.fill.Size = UDim2.new(f, 0, 1, 0)
                    l.fill.BackgroundColor3 = RED:Lerp(GREEN, f)
                    l.dist.Text = math.floor(dist) .. "m"
                elseif l then
                    l.hl.Enabled = false
                    l.gui.Enabled = false
                end
            end
        end
    end
})

-- Chams: Highlight на персонажах, подписка на респавны (раньше после смерти игрока подсветка пропадала)
local function ChamsModule(Name, Desc, key, rainbow)
    return {
        Name = Name,
        Desc = Desc,
        Key = key,
        Restart = true,
        Step = rainbow and "Render" or nil,
        Opts = { { key = "chamsFill", label = "Прозрачность заливки", kind = "num", default = 0.65, min = 0, max = 1 } },
        Code = function(ctx)
            local list = {}
            local hue = 0
            local team = ActiveCleanups["ESP Team Color"] ~= nil
            ForEachCharacter(ctx, function(p, c)
                local h = Instance.new("Highlight")
                h.Adornee = c
                local col = Color3.fromRGB(255, 0, 0)
                if team and p.TeamColor then col = p.TeamColor.Color end
                h.FillColor = rainbow and Color3.fromHSV(hue, 1, 1) or col
                h.OutlineColor = WHITE
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.FillTransparency = Opt.chamsFill
                h.OutlineTransparency = 0.3
                h.Parent = c
                list[h] = true
                return function() list[h] = nil h:Destroy() end
            end)
            if not rainbow then return nil, nil end
            return nil, function(dt)
                hue = (hue + dt * 0.5) % 1
                local col = Color3.fromHSV(hue, 1, 1)
                for h in pairs(list) do h.FillColor = col end
            end
        end
    }
end
Add("Visuals", ChamsModule("Chams (Glow)", "Подсветка игроков сквозь стены", Enum.KeyCode.C, false))
Add("Visuals", ChamsModule("Rainbow Chams", "Радужная подсветка", Enum.KeyCode.R, true))

-- Full ESP Info: BillboardGui (работает и без Drawing). Строится на каждый респавн, обновляется 10 раз в секунду.
Add("Visuals", {
    Name = "Full ESP Info",
    Desc = "Имя, HP, расстояние без Drawing",
    Key = Enum.KeyCode.E,
    Step = "Render",
    Interval = 0.1,
    Code = function(ctx)
        local entries = {}
        ForEachCharacter(ctx, function(p, c)
            local alive = true
            local gui
            task.spawn(function()
                local head = c:WaitForChild("Head", 5)
                local hum = c:WaitForChild("Humanoid", 5)
                local root = c:WaitForChild("HumanoidRootPart", 5)
                if not alive or not head or not hum or not root then return end
                gui = Instance.new("BillboardGui")
                gui.Adornee = head
                gui.Size = UDim2.new(0, 100, 0, 60)
                gui.StudsOffset = Vector3.new(0, 3, 0)
                gui.AlwaysOnTop = true
                gui.LightInfluence = 0
                gui.Parent = head
                local Frame = Instance.new("Frame")
                Frame.Size = UDim2.new(1, 0, 1, 0)
                Frame.BackgroundTransparency = 1
                Frame.Parent = gui
                local NameTag = Instance.new("TextLabel")
                NameTag.Size = UDim2.new(1, 0, 0, 20)
                NameTag.BackgroundTransparency = 1
                NameTag.Text = p.Name
                NameTag.TextColor3 = WHITE
                NameTag.Font = Enum.Font.Code
                NameTag.TextSize = 14
                NameTag.TextStrokeTransparency = 0
                NameTag.Parent = Frame
                local HealthBar = Instance.new("Frame")
                HealthBar.Size = UDim2.new(1, 0, 0, 6)
                HealthBar.Position = UDim2.new(0, 0, 0, 22)
                HealthBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                HealthBar.BorderSizePixel = 0
                HealthBar.Parent = Frame
                local HealthFill = Instance.new("Frame")
                HealthFill.Size = UDim2.new(1, 0, 1, 0)
                HealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                HealthFill.BorderSizePixel = 0
                HealthFill.Parent = HealthBar
                local DistanceText = Instance.new("TextLabel")
                DistanceText.Size = UDim2.new(1, 0, 0, 18)
                DistanceText.Position = UDim2.new(0, 0, 0, 30)
                DistanceText.BackgroundTransparency = 1
                DistanceText.Text = "0m"
                DistanceText.TextColor3 = WHITE
                DistanceText.Font = Enum.Font.Code
                DistanceText.TextSize = 12
                DistanceText.TextStrokeTransparency = 0
                DistanceText.Parent = Frame
                entries[p] = { Health = HealthFill, Distance = DistanceText, Hum = hum, Root = root }
            end)
            return function()
                alive = false
                entries[p] = nil
                if gui then gui:Destroy() end
            end
        end)
        return nil, function()
            local me = Root()
            for _, d in pairs(entries) do
                local hp = d.Hum.Health / math.max(d.Hum.MaxHealth, 1)
                d.Health.Size = UDim2.new(math.clamp(hp, 0, 1), 0, 1, 0)
                d.Health.BackgroundColor3 = (hp > 0.7 and Color3.fromRGB(0, 255, 0)) or (hp > 0.3 and Color3.fromRGB(255, 165, 0)) or Color3.fromRGB(255, 0, 0)
                if me then d.Distance.Text = math.floor((d.Root.Position - me.Position).Magnitude) .. "m" end
            end
        end
    end
})

Add("Visuals", {
    Name = "X-Ray",
    Desc = "Прозрачность стен; на больших картах применяется порциями",
    Opts = { { key = "xrayAlpha", label = "Прозрачность", kind = "num", default = 0.75, min = 0.1, max = 1 } },
    Code = function(ctx)
        local changed = {}
        task.spawn(function()
            local n = 0
            for _, d in ipairs(__Sailennt.Workspace:GetDescendants()) do
                if not ctx.Alive then return end
                if d:IsA("BasePart") and d.Transparency < 0.5 then
                    local m = d:FindFirstAncestorOfClass("Model")
                    if not (m and __Sailennt.Players:GetPlayerFromCharacter(m)) then
                        changed[d] = d.Transparency
                        d.Transparency = Opt.xrayAlpha
                    end
                end
                n = n + 1
                if n % 400 == 0 then task.wait() end -- без фриза на тысячах частей
            end
        end)
        return function()
            for d, t in pairs(changed) do
                if d.Parent then d.Transparency = t end
            end
        end, nil
    end
})

-- Свет / атмосфера
Add("Visuals", {
    Name = "Fullbright",
    Desc = "Яркое освещение без теней и тумана",
    Step = "Heartbeat",
    Code = function()
        local props = {
            Brightness = 2, ClockTime = 14, FogEnd = 1e5, GlobalShadows = false,
            Ambient = WHITE, OutdoorAmbient = WHITE,
        }
        local Old = {}
        for k in pairs(props) do Old[k] = __Sailennt.Lighting[k] end
        return function()
            for k, v in pairs(Old) do __Sailennt.Lighting[k] = v end
        end, function()
            for k, v in pairs(props) do
                if __Sailennt.Lighting[k] ~= v then __Sailennt.Lighting[k] = v end
            end
        end
    end
})
Add("Visuals", Mk.Lighting("Always Day", "Всегда день (14:00)", { ClockTime = 14 }))
Add("Visuals", Mk.Lighting("Always Night", "Всегда ночь (00:00)", { ClockTime = 0 }))
Add("Visuals", {
    Name = "Time Of Day",
    Desc = "Фиксированное время суток (ClockTime)",
    Step = "Heartbeat",
    Opts = { { key = "timeOfDay", label = "Час (0–24)", kind = "num", default = 14, min = 0, max = 24 } },
    Code = function()
        local old = __Sailennt.Lighting.ClockTime
        return function() __Sailennt.Lighting.ClockTime = old end, function()
            if __Sailennt.Lighting.ClockTime ~= Opt.timeOfDay then __Sailennt.Lighting.ClockTime = Opt.timeOfDay end
        end
    end
})
Add("Visuals", {
    Name = "No Fog",
    Desc = "Убирает туман и плотность Atmosphere",
    Step = "Heartbeat",
    Code = function()
        local OldEnd, OldStart = __Sailennt.Lighting.FogEnd, __Sailennt.Lighting.FogStart
        local atm = __Sailennt.Lighting:FindFirstChildOfClass("Atmosphere")
        local OldDensity = atm and atm.Density
        return function()
            __Sailennt.Lighting.FogEnd, __Sailennt.Lighting.FogStart = OldEnd, OldStart
            if atm and atm.Parent and OldDensity then atm.Density = OldDensity end
        end, function()
            if __Sailennt.Lighting.FogEnd ~= 1e6 then __Sailennt.Lighting.FogEnd = 1e6 end
            if __Sailennt.Lighting.FogStart ~= 1e6 then __Sailennt.Lighting.FogStart = 1e6 end
            if atm and atm.Parent and atm.Density ~= 0 then atm.Density = 0 end
        end
    end
})
Add("Visuals", Mk.Lighting("White Ambient", "Ambient / OutdoorAmbient в белый", { Ambient = WHITE, OutdoorAmbient = WHITE }))
Add("Visuals", Mk.Lighting("No Shadows", "GlobalShadows = false", { GlobalShadows = false }))
Add("Visuals", Mk.Effect("Color Boost", "Насыщенные цвета и контраст", "ColorCorrectionEffect", { Saturation = 0.4, Contrast = 0.15 }))
Add("Visuals", Mk.Effect("Black & White", "Чёрно-белый фильтр", "ColorCorrectionEffect", { Saturation = -1 }))
Add("Visuals", Mk.Effect("Bloom Glow", "Мягкое свечение ярких объектов", "BloomEffect", { Intensity = 0.6, Size = 24, Threshold = 0.9 }))
Add("Visuals", Mk.Effect("Sun Rays", "Лучи солнца", "SunRaysEffect", { Intensity = 0.25, Spread = 0.8 }))
Add("Visuals", Mk.Effect("Depth of Field", "Кинематографичная глубина резкости", "DepthOfFieldEffect", { FarIntensity = 0.3, FocusDistance = 30, InFocusRadius = 30, NearIntensity = 0 }))
Add("Visuals", {
    Name = "Rainbow Ambient",
    Desc = "Переливающееся освещение мира",
    Code = function()
        local OldA, OldO = __Sailennt.Lighting.Ambient, __Sailennt.Lighting.OutdoorAmbient
        local h = 0
        return function()
            __Sailennt.Lighting.Ambient = OldA
            __Sailennt.Lighting.OutdoorAmbient = OldO
        end, function(dt)
            h = (h + (dt or 0.016) * 0.1) % 1
            local c = Color3.fromHSV(h, 0.6, 1)
            __Sailennt.Lighting.Ambient = c
            __Sailennt.Lighting.OutdoorAmbient = c
        end
    end
})

-- Камера
Add("Visuals", {
    Name = "FOV Changer",
    Desc = "Поле зрения камеры",
    Step = "Render",
    Opts = { { key = "fov", label = "FOV (30–120)", kind = "num", default = 100, min = 30, max = 120 } },
    Code = function()
        local Old = __Sailennt.Workspace.CurrentCamera.FieldOfView
        return function()
            local c = __Sailennt.Workspace.CurrentCamera
            if c then c.FieldOfView = Old end
        end, function()
            local c = __Sailennt.Workspace.CurrentCamera
            if c and c.FieldOfView ~= Opt.fov then c.FieldOfView = Opt.fov end
        end
    end
})
Add("Visuals", {
    Name = "Zoom (Hold Z)",
    Desc = "Плавный зум при зажатой клавише Z",
    Step = "Render",
    Code = function()
        local Base = __Sailennt.Workspace.CurrentCamera.FieldOfView
        return function()
            local c = __Sailennt.Workspace.CurrentCamera
            if c then c.FieldOfView = Base end
        end, function(dt)
            local c = __Sailennt.Workspace.CurrentCamera
            if not c then return end
            local target = (__Sailennt.UserInputService:IsKeyDown(Enum.KeyCode.Z) and not __Sailennt.UserInputService:GetFocusedTextBox()) and 25 or Base
            c.FieldOfView = c.FieldOfView + (target - c.FieldOfView) * math.min(1, (dt or 0.016) * 12)
        end
    end
})

-- Экранные оверлеи
Add("Visuals", {
    Name = "HUD Overlay",
    Desc = "FPS, пинг, время и executor в углу экрана",
    Step = "Render",
    Code = function(ctx)
        local Hud = Instance.new("Frame")
        Hud.Size = UDim2.new(0, 320, 0, 26)
        Hud.Position = UDim2.new(0, 12, 0, 12)
        Hud.BackgroundColor3 = __Sailennt.Config.CardBG
        Hud.BackgroundTransparency = 0.1
        Hud.BorderSizePixel = 0
        Hud.Parent = ScreenGui
        ctx.Inst(Hud)
        __Sailennt.Corner(Hud, 6)
        __Sailennt.Stroke(Hud, __Sailennt.Config.Stroke, 1)
        local Txt = __Sailennt.Label(Hud, "", 12, __Sailennt.Config.TextMain, Enum.Font.GothamMedium, UDim2.new(0, 10, 0, 0), UDim2.new(1, -20, 1, 0))
        local acc, frames = 0, 0
        return nil, function(dt)
            acc = acc + dt
            frames = frames + 1
            if acc >= 0.5 then
                local fps = math.floor(frames / acc + 0.5)
                acc, frames = 0, 0
                local ping = 0
                pcall(function() ping = math.floor(__Sailennt.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
                Txt.Text = string.format("Sailennt  |  %d FPS  |  %d ms  |  %s  |  %s", fps, ping, os.date("%H:%M"), X.name)
            end
        end
    end
})
Add("Visuals", {
    Name = "Custom Crosshair",
    Desc = "Свой прицел в центре экрана",
    Code = function(ctx)
        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.fromOffset(40, 40)
        Holder.AnchorPoint = Vector2.new(0.5, 0.5)
        Holder.Position = UDim2.new(0.5, 0, 0.5, 0)
        Holder.BackgroundTransparency = 1
        Holder.Parent = ScreenGui
        ctx.Inst(Holder)
        local function Bar(x, y, w, h)
            local f = Instance.new("Frame")
            f.Position = UDim2.fromOffset(x, y)
            f.Size = UDim2.fromOffset(w, h)
            f.BackgroundColor3 = __Sailennt.Config.Accent
            f.BorderSizePixel = 0
            f.Parent = Holder
        end
        Bar(19, 6, 2, 8) Bar(19, 26, 2, 8) Bar(6, 19, 8, 2) Bar(26, 19, 8, 2) Bar(19, 19, 2, 2)
        return nil, nil
    end
})
Add("Visuals", {
    Name = "Vignette",
    Desc = "Затемнение по краям экрана",
    Code = function(ctx)
        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.new(1, 0, 1, 0)
        Holder.BackgroundTransparency = 1
        Holder.ZIndex = 1
        Holder.Parent = ScreenGui
        ctx.Inst(Holder)
        local edges = {
            { UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0.18, 0), 90 },
            { UDim2.new(0, 0, 0.82, 0), UDim2.new(1, 0, 0.18, 0), 270 },
            { UDim2.new(0, 0, 0, 0), UDim2.new(0.12, 0, 1, 0), 0 },
            { UDim2.new(0.88, 0, 0, 0), UDim2.new(0.12, 0, 1, 0), 180 },
        }
        for _, e in ipairs(edges) do
            local F = Instance.new("Frame")
            F.Position, F.Size = e[1], e[2]
            F.BackgroundColor3 = Color3.new(0, 0, 0)
            F.BorderSizePixel = 0
            F.ZIndex = 1
            F.Parent = Holder
            local g = Instance.new("UIGradient")
            g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
            g.Rotation = e[3]
            g.Parent = F
        end
        return nil, nil
    end
})
Add("Visuals", {
    Name = "Cinematic Bars",
    Desc = "Чёрные полосы сверху и снизу экрана",
    Code = function(ctx)
        local Holder = Instance.new("Frame")
        Holder.Size = UDim2.new(1, 0, 1, 0)
        Holder.BackgroundTransparency = 1
        Holder.ZIndex = 1
        Holder.Parent = ScreenGui
        ctx.Inst(Holder)
        for _, y in ipairs({ 0, 0.9 }) do
            local F = Instance.new("Frame")
            F.Position = UDim2.new(0, 0, y, 0)
            F.Size = UDim2.new(1, 0, 0.1, 0)
            F.BackgroundColor3 = Color3.new(0, 0, 0)
            F.BorderSizePixel = 0
            F.ZIndex = 1
            F.Parent = Holder
        end
        return nil, nil
    end
})

local SessionStart = os.time()
local function RootPos()
    local c = __Sailennt.LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
Add("Visuals", HudModule("Coordinates HUD", "Ваши координаты на экране", function()
    local r = RootPos()
    if not r then return "XYZ: —" end
    local p = r.Position
    return string.format("XYZ: %d, %d, %d", math.floor(p.X), math.floor(p.Y), math.floor(p.Z))
end))
Add("Visuals", HudModule("Speedometer", "Ваша скорость в studs/s", function()
    local r = RootPos()
    return string.format("Speed: %.1f studs/s", r and r.AssemblyLinearVelocity.Magnitude or 0)
end))
Add("Visuals", HudModule("Session Timer", "Время в этой игре", function()
    local t = os.time() - SessionStart
    return string.format("Session: %02d:%02d", math.floor(t / 60), t % 60)
end))
Add("Visuals", HudModule("Keybind List", "Актуальные горячие клавиши на экране", function()
    local lines = {}
    for name, key in pairs(Binds) do
        if key then lines[#lines + 1] = key.Name .. " — " .. name end
    end
    table.sort(lines)
    table.insert(lines, 1, __Sailennt.Config.ToggleKey.Name .. " — меню")
    return table.concat(lines, "\n", 1, math.min(#lines, 8))
end, 124))

end
do

-- // PLAYER -------------------------------------------------------
Add("Player", {
    Name = "Auto Respawn",
    Desc = "LoadCharacter после смерти (клиент может не иметь права — зависит от игры)",
    Code = function(ctx)
        ctx.Conn(__Sailennt.LocalPlayer.CharacterRemoving:Connect(function()
            task.delay((__Sailennt.Players.RespawnTime or 5) + 1, function()
                if ctx.Alive and not __Sailennt.LocalPlayer.Character then
                    local ok = pcall(function() __Sailennt.LocalPlayer:LoadCharacter() end)
                    if not ok then Notify("Auto Respawn", false, "LoadCharacter запрещён в этой игре") end
                end
            end)
        end))
        return nil, nil
    end
})

Add("Player", {
    Name = "Anti-Kick",
    Desc = "Блок client-side Kick; серверный кик не ловится",
    Code = function() return Hook.Acquire("antiKick") end
})

Add("Player", {
    Name = "God Mode (client)",
    Desc = "Health lock + блок BreakJoints; серверный урон проходит",
    Step = "Heartbeat",
    Code = function()
        local rel = Hook.Install() and Hook.Acquire("god") or Noop
        return rel, function()
            local h = GetHum()
            if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
        end
    end
})

Add("Player", {
    Name = "Invisible (client)",
    Desc = "Локальная невидимость; репликация зависит от игры",
    Step = "Stepped",
    CharDep = true,
    Code = function(ctx)
        local c = Need(__Sailennt.Character, "персонаж не найден")
        local parts, orig = {}, {}
        local function track(d) if d:IsA("BasePart") or d:IsA("Decal") then parts[d] = true end end
        for _, d in ipairs(c:GetDescendants()) do track(d) end
        ctx.Conn(c.DescendantAdded:Connect(track))
        ctx.Conn(c.DescendantRemoving:Connect(function(d) parts[d] = nil orig[d] = nil end))
        return function()
            for d, t in pairs(orig) do
                if d.Parent then d.Transparency = t end
            end
        end, function()
            for d in pairs(parts) do
                if d.Transparency ~= 1 then
                    if orig[d] == nil then orig[d] = d.Transparency end
                    d.Transparency = 1
                end
            end
        end
    end
})

Add("Player", {
    Name = "Freeze Character",
    Desc = "Anchored + фиксация CFrame",
    Step = "Stepped",
    CharDep = true,
    Code = function()
        local root = Need(Root(), "персонаж не найден")
        local cf = root.CFrame
        pcall(function() root.Anchored = true end)
        return function()
            local r = Root()
            if r then pcall(function() r.Anchored = false end) end
        end, function()
            local r = Root()
            if r then
                r.CFrame = cf
                r.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end
})

Add("Player", {
    Name = "Fling",
    Desc = "Спин + таран цели; физика зависит от ownership, возможен self-fling",
    Step = "Render",
    CharDep = true,
    Code = function(ctx)
        local root = Need(Root(), "персонаж не найден")
        local bav = Instance.new("BodyAngularVelocity")
        bav.MaxTorque = Vector3.new(1, 1, 1) * math.huge
        bav.P = 1e6
        bav.AngularVelocity = Vector3.new(0, 50000, 0)
        bav.Parent = root
        ctx.Inst(bav)
        return function()
            bav:Destroy()
            local r = Root()
            if r then
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
            end
        end, function()
            local r = Root()
            if not r then return end
            local t = GetTarget()
            local e = t and Parts(t)
            if e then r.CFrame = e.Root.CFrame * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3)) end
        end
    end
})

Add("Player", {
    Name = "Spectate",
    Desc = "Камера на цели; выключение возвращает камеру",
    Step = "Heartbeat",
    Interval = 0.25,
    CharDep = true,
    Code = function()
        local t = GetTarget()
        local e = t and Parts(t)
        Need(e, "цель не найдена")
        __Sailennt.Workspace.CurrentCamera.CameraSubject = e.Hum
        Notify("Spectate", true, "Наблюдаю: " .. t.Name)
        return function()
            local me = GetHum()
            if me then __Sailennt.Workspace.CurrentCamera.CameraSubject = me end
        end, function()
            if not e.Hum.Parent then Disable("Spectate", "Цель пропала") end
        end
    end
})

Add("Player", {
    Name = "Chat Spam",
    Desc = "Сообщение с интервалом (legacy + TextChat)",
    Step = "Heartbeat",
    Opts = {
        { key = "chatMessage", label = "Сообщение", kind = "str", default = "Sailennt" },
        { key = "chatInterval", label = "Интервал (с)", kind = "num", default = 2, min = 0.5, max = 30 },
    },
    Code = function()
        local acc = 0
        return nil, function(dt)
            acc = acc + dt
            if acc < math.max(Opt.chatInterval, 0.5) then return end
            acc = 0
            local msg = tostring(Opt.chatMessage)
            local sent = false
            local legacy = __Sailennt.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            local say = legacy and legacy:FindFirstChild("SayMessageRequest")
            if say then sent = pcall(function() say:FireServer(msg, "All") end) end
            if not sent then
                pcall(function()
                    local ch = __Sailennt.TextChatService:FindFirstChild("TextChannels")
                    ch = ch and ch:FindFirstChild("RBXGeneral")
                    if ch then ch:SendAsync(msg) end
                end)
            end
        end
    end
})

-- // WORLD --------------------------------------------------------
local RADIUS = { key = "interactRadius", label = "Радиус", kind = "num", default = 200, min = 10, max = 2000 }
local function InRadius(part, pos)
    return not pos or (part.Position - pos).Magnitude <= Opt.interactRadius
end

Add("World", {
    Name = "Fire ClickDetectors",
    Desc = "Все ClickDetector в радиусе",
    OneShot = true,
    Opts = { RADIUS },
    Code = function()
        Need(X.cd, "fireclickdetector недоступен в этом executor")
        local r = Root()
        local pos = r and r.Position
        local n = 0
        for _, d in ipairs(__Sailennt.Workspace:GetDescendants()) do
            if d:IsA("ClickDetector") and d.Parent and d.Parent:IsA("BasePart") and InRadius(d.Parent, pos) then
                pcall(X.cd, d)
                n = n + 1
            end
        end
        return "ClickDetectors: " .. n
    end
})

Add("World", {
    Name = "Fire ProximityPrompts",
    Desc = "Все Prompts в радиусе",
    OneShot = true,
    Opts = { RADIUS },
    Code = function()
        Need(X.prompt, "fireproximityprompt недоступен в этом executor")
        local r = Root()
        local pos = r and r.Position
        local n = 0
        for _, d in ipairs(__Sailennt.Workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") and d.Parent and d.Parent:IsA("BasePart") and InRadius(d.Parent, pos) then
                pcall(X.prompt, d)
                n = n + 1
            end
        end
        return "Prompts: " .. n
    end
})

Add("World", {
    Name = "Fire TouchInterests",
    Desc = "Все TouchTransmitter в радиусе -> HRP",
    OneShot = true,
    Opts = { RADIUS },
    Code = function()
        Need(X.touch, "firetouchinterest недоступен в этом executor")
        local r = Need(Root(), "персонаж не найден")
        local n = 0
        for _, d in ipairs(__Sailennt.Workspace:GetDescendants()) do
            if d:IsA("TouchTransmitter") and d.Parent and d.Parent:IsA("BasePart") and InRadius(d.Parent, r.Position) then
                pcall(X.touch, r, d.Parent, 0)
                pcall(X.touch, r, d.Parent, 1)
                n = n + 1
            end
        end
        return "TouchInterests: " .. n
    end
})

Add("World", {
    Name = "Collect Drops",
    Desc = "Монеты / лут по именам + TouchTransmitter",
    OneShot = true,
    Opts = { RADIUS },
    Code = function()
        Need(X.touch, "firetouchinterest недоступен в этом executor")
        local r = Need(Root(), "персонаж не найден")
        local n = 0
        for _, d in ipairs(__Sailennt.Workspace:GetDescendants()) do
            if d:IsA("BasePart") and InRadius(d, r.Position) then
                local name = d.Name:lower()
                local match = name:find("coin") or name:find("cash") or name:find("drop") or name:find("pickup")
                    or name:find("gem") or name:find("orb") or name:find("loot")
                if match or d:FindFirstChildOfClass("TouchTransmitter") then
                    pcall(X.touch, r, d, 0)
                    pcall(X.touch, r, d, 1)
                    n = n + 1
                end
            end
        end
        return "Собрано: " .. n
    end
})

Add("World", {
    Name = "Auto Farm (generic)",
    Desc = "Цикл: ближайший ClickDetector / Prompt / Touch в радиусе",
    Step = "Heartbeat",
    Opts = {
        { key = "farmRadius", label = "Радиус", kind = "num", default = 60, min = 10, max = 500 },
        { key = "farmInterval", label = "Интервал (с)", kind = "num", default = 0.5, min = 0.1, max = 5 },
    },
    Code = function(ctx)
        -- кандидаты собираются один раз и ведутся через DescendantAdded/Removing (раньше полный обход Workspace каждые 0.5 с)
        local cand = {}
        local function track(d)
            if d:IsA("ClickDetector") and X.cd then cand[d] = "cd"
            elseif d:IsA("ProximityPrompt") and X.prompt then cand[d] = "pp"
            elseif d:IsA("TouchTransmitter") and X.touch then cand[d] = "tt" end
        end
        Need(X.cd or X.prompt or X.touch, "нужен fireclickdetector / fireproximityprompt / firetouchinterest")
        for _, d in ipairs(__Sailennt.Workspace:GetDescendants()) do track(d) end
        ctx.Conn(__Sailennt.Workspace.DescendantAdded:Connect(track))
        ctx.Conn(__Sailennt.Workspace.DescendantRemoving:Connect(function(d) cand[d] = nil end))
        local acc = 0
        return nil, function(dt)
            acc = acc + dt
            if acc < Opt.farmInterval then return end
            acc = 0
            local r = Root()
            if not r then return end
            local best, bd, bk = nil, Opt.farmRadius, nil
            for d, kind in pairs(cand) do
                local part = d.Parent
                if part and part:IsA("BasePart") then
                    local dist = (part.Position - r.Position).Magnitude
                    if dist < bd then best, bd, bk = d, dist, kind end
                end
            end
            if best then
                if bk == "cd" then pcall(X.cd, best)
                elseif bk == "pp" then pcall(X.prompt, best)
                else pcall(X.touch, r, best.Parent, 0) pcall(X.touch, r, best.Parent, 1) end
            end
        end
    end
})

Add("World", {
    Name = "Remove Seats",
    Desc = "Удалить Seat / VehicleSeat локально",
    OneShot = true,
    Code = function()
        local n = 0
        for _, d in ipairs(__Sailennt.Workspace:GetDescendants()) do
            if d:IsA("Seat") or d:IsA("VehicleSeat") then d:Destroy() n = n + 1 end
        end
        return "Удалено сидений: " .. n
    end
})

Add("World", {
    Name = "Unanchor Parts",
    Desc = "Anchored = false локально; сервер может ресинкать",
    OneShot = true,
    Code = function()
        local n = 0
        for _, d in ipairs(__Sailennt.Workspace:GetDescendants()) do
            if d:IsA("BasePart") and d.Anchored then
                local m = d:FindFirstAncestorOfClass("Model")
                if not (m and __Sailennt.Players:GetPlayerFromCharacter(m)) then
                    d.Anchored = false
                    n = n + 1
                end
            end
        end
        return "Unanchored: " .. n
    end
})

Add("World", {
    Name = "Delete Kill Bricks",
    Desc = "Эвристика по имени: kill / lava / death / void",
    OneShot = true,
    Code = function()
        local n = 0
        for _, d in ipairs(__Sailennt.Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                local name = d.Name:lower()
                if name:find("kill") or name:find("lava") or name:find("death") or name:find("void") then
                    d:Destroy()
                    n = n + 1
                end
            end
        end
        return "Удалено: " .. n
    end
})

Add("World", {
    Name = "Anti-Teleport",
    Desc = "Блок client-initiated TeleportService; серверный ТП не ловится",
    Code = function() return Hook.Acquire("antiTp") end
})

Add("World", {
    Name = "Part Magnet",
    Desc = "Unanchored части к себе; нужен network ownership",
    Step = "Heartbeat",
    Interval = 0.1,
    Opts = { { key = "magnetRadius", label = "Радиус", kind = "num", default = 30, min = 5, max = 200 } },
    Code = function()
        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        return nil, function()
            local r = Root()
            if not r then return end
            params.FilterDescendantsInstances = { __Sailennt.Character }
            for _, part in ipairs(__Sailennt.Workspace:GetPartBoundsInRadius(r.Position, Opt.magnetRadius, params)) do
                if not part.Anchored then
                    local m = part:FindFirstAncestorOfClass("Model")
                    if not (m and __Sailennt.Players:GetPlayerFromCharacter(m)) then
                        part.CFrame = r.CFrame * CFrame.new(0, 0, -3)
                    end
                end
            end
        end
    end
})

-- // UTIL (Misc) --------------------------------------------------
Add("Misc", {
    Name = "Anti-AFK",
    Desc = "Не даёт кикнуть за бездействие",
    Code = function(ctx)
        ctx.Conn(__Sailennt.LocalPlayer.Idled:Connect(function()
            __Sailennt.VirtualUser:CaptureController()
            __Sailennt.VirtualUser:ClickButton2(Vector2.new())
        end))
        return nil, nil
    end
})

Add("Misc", {
    Name = "Auto Rejoin",
    Desc = "Автоматический перезаход при дисконнекте",
    Code = function(ctx)
        pcall(function()
            local overlay = __Sailennt.CoreGui:WaitForChild("RobloxPromptGui", 3):WaitForChild("promptOverlay", 3)
            ctx.Conn(overlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" then
                    task.wait(2)
                    __Sailennt.TeleportService:Teleport(game.PlaceId, __Sailennt.LocalPlayer)
                end
            end))
        end)
        return nil, nil
    end
})

Add("Misc", {
    Name = "Discord Webhook",
    Desc = "Логи запуска/остановки в Discord (URL в настройках ...)",
    Opts = { { key = "webhookUrl", label = "Webhook URL", kind = "str", default = "" } },
    Code = function()
        Need(X.request, "request недоступен в этом executor")
        local function Send(message)
            local url = Opt.webhookUrl
            if type(url) ~= "string" or url == "" then return end
            pcall(function()
                X.request({
                    Url = url,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = __Sailennt.HttpService:JSONEncode({ content = message, username = "Sailennt Logger" }),
                })
            end)
        end
        if Opt.webhookUrl == "" then warn("[Sailennt] Discord Webhook: укажи Webhook URL в настройках модуля (кнопка ...)") end
        task.spawn(Send, "**Sailennt v5.2 Started** - Player: " .. __Sailennt.LocalPlayer.Name)
        return function() task.spawn(Send, "**Sailennt v5.2 Stopped**") end, nil
    end
})

Add("Misc", {
    Name = "FPS Boost",
    Desc = "Низкое качество, без теней и пост-эффектов",
    Code = function()
        local Rendering = settings().Rendering
        local OldQuality = Rendering.QualityLevel
        local OldShadows = __Sailennt.Lighting.GlobalShadows
        local Disabled = {}
        pcall(function() Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        __Sailennt.Lighting.GlobalShadows = false
        for _, e in ipairs(__Sailennt.Lighting:GetChildren()) do
            if e:IsA("PostEffect") and e.Name ~= "SailenntBlur" and e.Enabled then
                e.Enabled = false
                table.insert(Disabled, e)
            end
        end
        return function()
            pcall(function() Rendering.QualityLevel = OldQuality end)
            __Sailennt.Lighting.GlobalShadows = OldShadows
            for _, e in ipairs(Disabled) do
                if e.Parent then e.Enabled = true end
            end
        end, nil
    end
})

Add("Misc", {
    Name = "Camera Unlock",
    Desc = "Отдаление камеры (CameraMaxZoomDistance)",
    Restart = true,
    Opts = { { key = "maxZoom", label = "Макс. зум (studs)", kind = "num", default = 1000, min = 10, max = 10000 } },
    Code = function()
        local OldMax, OldMin = __Sailennt.LocalPlayer.CameraMaxZoomDistance, __Sailennt.LocalPlayer.CameraMinZoomDistance
        __Sailennt.LocalPlayer.CameraMaxZoomDistance = Opt.maxZoom
        __Sailennt.LocalPlayer.CameraMinZoomDistance = 0.5
        return function()
            __Sailennt.LocalPlayer.CameraMaxZoomDistance = OldMax
            __Sailennt.LocalPlayer.CameraMinZoomDistance = OldMin
        end, nil
    end
})

Add("Misc", {
    Name = "Rejoin Server",
    Desc = "Перезайти на этот же сервер",
    OneShot = true,
    Code = function()
        local ok = pcall(function() __Sailennt.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, __Sailennt.LocalPlayer) end)
        if not ok then __Sailennt.TeleportService:Teleport(game.PlaceId, __Sailennt.LocalPlayer) end
        return "Перезаход..."
    end
})

Add("Misc", {
    Name = "Server Hop",
    Desc = "Случайный публичный сервер через games API",
    OneShot = true,
    Silent = true,
    Code = function()
        Need(X.request, "request недоступен в этом executor")
        Notify("Server Hop", true, "Ищу сервер...")
        task.spawn(function()
            local ok, res = pcall(X.request, {
                Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
                Method = "GET",
            })
            if ok and res and res.Body then
                local okJson, data = pcall(function() return __Sailennt.HttpService:JSONDecode(res.Body) end)
                if okJson and type(data) == "table" then
                    local candidates = {}
                    for _, s in ipairs(data.data or {}) do
                        if s.playing < s.maxPlayers and s.id ~= game.JobId then table.insert(candidates, s.id) end
                    end
                    if #candidates > 0 then
                        __Sailennt.TeleportService:TeleportToPlaceInstance(game.PlaceId, candidates[math.random(1, #candidates)], __Sailennt.LocalPlayer)
                        return
                    end
                end
            end
            Notify("Server Hop", false, "Сервер не найден, обычный телепорт")
            __Sailennt.TeleportService:Teleport(game.PlaceId, __Sailennt.LocalPlayer)
        end)
    end
})

Add("Misc", {
    Name = "Copy Server ID",
    Desc = "Скопировать JobId сервера в буфер",
    OneShot = true,
    Code = function()
        Need(X.clip, "setclipboard не поддерживается")
        X.clip(game.JobId)
        return "JobId скопирован"
    end
})

Add("Misc", {
    Name = "Reset Character",
    Desc = "Быстро пересоздать персонажа",
    OneShot = true,
    Code = function()
        local h = GetHum()
        if h then h.Health = 0 elseif __Sailennt.Character then __Sailennt.Character:BreakJoints() end
    end
})

Add("Misc", {
    Name = "FPS Unlock",
    Desc = "Снимает ограничение FPS (до 999)",
    Code = function()
        Need(X.fps, "setfpscap не поддерживается")
        X.fps(999)
        return function() X.fps(60) end, nil
    end
})

Add("Misc", {
    Name = "No Particles",
    Desc = "Отключает частицы, трейлы и огонь",
    Code = function(ctx)
        local Off = {}
        local function check(o)
            if (o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles")) and o.Enabled then
                Off[o] = true
                o.Enabled = false
            end
        end
        for _, o in ipairs(__Sailennt.Workspace:GetDescendants()) do check(o) end
        ctx.Conn(__Sailennt.Workspace.DescendantAdded:Connect(check))
        return function()
            for o in pairs(Off) do
                if o.Parent then o.Enabled = true end
            end
        end, nil
    end
})

Add("Misc", {
    Name = "Mute Game Sounds",
    Desc = "Отключает звук игры",
    Code = function()
        local ugs = UserSettings():GetService("UserGameSettings")
        local Old = ugs.MasterVolume
        ugs.MasterVolume = 0
        return function() ugs.MasterVolume = Old end, nil
    end
})

Add("Misc", {
    Name = "Hide Chat",
    Desc = "Скрывает окно чата",
    Code = function()
        __Sailennt.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
        return function() __Sailennt.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true) end, nil
    end
})

Add("Misc", {
    Name = "Hide Player List",
    Desc = "Скрывает список игроков",
    Code = function()
        __Sailennt.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
        return function() __Sailennt.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true) end, nil
    end
})

Add("Misc", {
    Name = "Copy Place ID",
    Desc = "Скопировать PlaceId в буфер",
    OneShot = true,
    Code = function()
        Need(X.clip, "setclipboard не поддерживается")
        X.clip(tostring(game.PlaceId))
        return "Place ID: " .. game.PlaceId
    end
})

Add("Misc", {
    Name = "Copy Position",
    Desc = "Скопировать свои координаты",
    OneShot = true,
    Code = function()
        Need(X.clip, "setclipboard не поддерживается")
        local r = Need(Root(), "персонаж не найден")
        local p = r.Position
        local txt = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
        X.clip(txt)
        return txt
    end
})

Add("Misc", {
    Name = "Server Info",
    Desc = "Игроки на сервере и ваш пинг",
    OneShot = true,
    Code = function()
        local ping = 0
        pcall(function() ping = math.floor(__Sailennt.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        return string.format("Игроков %d/%d · %d ms", #__Sailennt.Players:GetPlayers(), __Sailennt.Players.MaxPlayers, ping)
    end
})

Add("Misc", {
    Name = "Reset Camera",
    Desc = "Вернуть камеру и FOV по умолчанию",
    OneShot = true,
    Code = function()
        local cam = __Sailennt.Workspace.CurrentCamera
        local h = GetHum()
        if h then cam.CameraSubject = h end
        cam.CameraType = Enum.CameraType.Custom
        cam.FieldOfView = 70
    end
})

Add("Misc", {
    Name = "Console Log",
    Desc = "Дублировать лог в executor-консоль (rconsole)",
    Code = function()
        Need(X.rprint, "rconsoleprint недоступен в этом executor")
        if X.rname then pcall(X.rname, "Sailennt") end
        ConsoleOn = true
        return function() ConsoleOn = false end, nil
    end
})

Add("Misc", {
    Name = "Remote Spy",
    Desc = "Лог FireServer / InvokeServer (namecall hook)",
    Code = function() return Hook.Acquire("spy") end
})

Add("Misc", {
    Name = "Copy Remote Log",
    Desc = "Скопировать последние записи Remote Spy",
    OneShot = true,
    Code = function()
        Need(X.clip, "setclipboard не поддерживается")
        Need(#Hook.Log > 0, "лог пуст — включи Remote Spy")
        X.clip(table.concat(Hook.Log, "\n"))
        return "Скопировано записей: " .. #Hook.Log
    end
})

Add("Misc", {
    Name = "Save Instance",
    Desc = "saveinstance() — дамп карты в workspace executor",
    OneShot = true,
    Silent = true,
    Code = function()
        Need(X.save, "saveinstance недоступен в этом executor")
        Notify("Save Instance", true, "Сохранение карты...")
        task.spawn(function()
            local ok, err = pcall(X.save)
            Notify("Save Instance", ok, ok and "Карта сохранена" or ("Ошибка: " .. CleanErr(err)))
        end)
    end
})

Add("Misc", {
    Name = "Dex Explorer",
    Desc = "Загрузка Dex по URL (внешний код — на твой риск)",
    OneShot = true,
    Silent = true,
    Code = function()
        Notify("Dex Explorer", true, "Загрузка...")
        task.spawn(function()
            local ok, err = pcall(function() loadstring(game:HttpGet(DEX_URL))() end)
            Notify("Dex Explorer", ok, ok and "Dex загружен" or ("Ошибка: " .. CleanErr(err)))
        end)
    end
})

Add("Misc", {
    Name = "Auto Execute On TP",
    Desc = "queue_on_teleport; сохрани скрипт как " .. SELF_FILE .. " в workspace executor",
    OneShot = true,
    Code = function()
        Need(X.queue, "queue_on_teleport недоступен в этом executor")
        Need(isfile and isfile(SELF_FILE), "сохрани скрипт как " .. SELF_FILE .. " в папке workspace executor")
        pcall(X.queue, 'loadstring(readfile("' .. SELF_FILE .. '"))()')
        return "Авто-запуск после телепорта включён"
    end
})

Add("Misc", {
    Name = "Clear Notifications",
    Desc = "Убрать все уведомления с экрана",
    OneShot = true,
    Silent = true,
    Code = function()
        local holder = ScreenGui:FindFirstChild("Notifications")
        if holder then
            for _, c in ipairs(holder:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
        end
    end
})

Add("Misc", {
    Name = "Test Notification",
    Desc = "Проверка уведомления и звука",
    OneShot = true,
    Code = function() return "Всё работает" end
})

Add("Misc", {
    Name = "Save Config",
    Desc = "Сохранить настройки, бинды и тему",
    OneShot = true,
    Code = function()
        Need(writefile, "writefile недоступен в этом executor")
        SaveConfig()
        return "Настройки сохранены"
    end
})

Add("Misc", {
    Name = "Load Config",
    Desc = "Применить последнюю сессию (профили — кнопка Configs)",
    OneShot = true,
    Code = function()
        Need(isfile and readfile and isfile(CONFIG_FILE), "файл конфига не найден")
        local data, err = DecodeConfig(readfile(CONFIG_FILE))
        Need(data, "конфиг повреждён: " .. tostring(err))
        Profiles.Apply(data)
        return "Сессионный конфиг применён"
    end
})

Add("Misc", {
    Name = "Executor Info",
    Desc = "Какие API доступны в этом executor (полный список — в консоли)",
    OneShot = true,
    Silent = true,
    Code = function()
        local caps = {
            { "Drawing", X.draw }, { "hook", hookmetamethod and getnamecallmethod and checkcaller }, { "click", X.click },
            { "firetouch", X.touch }, { "clickdetector", X.cd }, { "prompt", X.prompt }, { "mousemoverel", X.moveRel },
            { "clipboard", X.clip }, { "request", X.request }, { "files", writefile and readfile and isfile }, { "gethui", gethui },
        }
        local miss, all = {}, {}
        for _, c in ipairs(caps) do
            all[#all + 1] = c[1] .. (c[2] and " OK" or " X")
            if not c[2] then miss[#miss + 1] = c[1] end
        end
        Log(X.name .. (__Sailennt.IsMobile and " (mobile)" or " (PC)") .. " | " .. table.concat(all, ", "))
        Notify("Executor Info", #miss == 0, #miss == 0 and (X.name .. ": все API на месте") or (X.name .. " · нет: " .. table.concat(miss, ", ")))
    end
})

Add("Misc", {
    Name = "Unload Client",
    Desc = "Полностью выгрузить клиент (также клавиша End)",
    OneShot = true,
    Silent = true,
    Code = function() UnloadClient() end
})

-- // V5.2 EXTRA TOOLS
Add("Misc", {
    Name = "Dashboard",
    Desc = "Открыть панель состояния клиента и производительности",
    OneShot = true,
    Code = function()
        Need(OpenDashboard, "панель Dashboard ещё не инициализирована")
        OpenDashboard()
        return "Dashboard открыт"
    end
})
Add("Misc", {
    Name = "Activity Log",
    Desc = "История событий, модулей и ошибок",
    OneShot = true,
    Code = function()
        Need(OpenActivityLog, "журнал ещё не инициализирован")
        OpenActivityLog()
        return "Activity Log открыт"
    end
})
Add("Settings", {
    Name = "Language",
    Desc = "Переключить язык интерфейса RU / EN",
    OneShot = true,
    Code = function()
        Settings.Language = (Settings.Language == "ru") and "en" or "ru"
        if ApplyLanguage then ApplyLanguage() end
        RequestSave()
        return "Language: " .. string.upper(Settings.Language)
    end
})
Add("Misc", {
    Name = "Update History",
    Desc = "Список изменений Sailennt v5.2",
    OneShot = true,
    Code = function()
        Need(__Sailennt.Ui.OpenHistory, "страница ещё не инициализирована")
        __Sailennt.Ui.OpenHistory()
        return "История обновлений открыта"
    end
})
Add("Misc", {
    Name = "About",
    Desc = "Версия, горячие клавиши и краткая документация",
    OneShot = true,
    Code = function()
        Need(__Sailennt.Ui.OpenAbout, "страница ещё не инициализирована")
        __Sailennt.Ui.OpenAbout()
        return "About открыт"
    end
})

-- // SETTINGS -----------------------------------------------------
Add("Settings", Mk.Setting("Notifications", "Уведомления при включении функций", "Notifications"))
Add("Settings", Mk.Setting("Sounds", "Звук при включении функции", "Sounds"))
Add("Settings", Mk.Setting("Background Blur", "Размытие фона при открытии меню", "Blur"))
Add("Settings", Mk.Setting("Snowfall", "Снег при открытии меню", "Snow"))
Add("Settings", Mk.Setting("Auto-Open Menu", "Открывать меню сразу при запуске", "AutoOpen"))
Add("Settings", Mk.Setting("Reduce Motion", "Без каскада карточек (меньше анимаций)", "ReduceMotion"))
Add("Settings", Mk.Setting("Floating Button", "Плавающая кнопка открытия меню (для телефона)", "FloatBtn"))
Add("Settings", Mk.Setting("Restore Enabled", "Включать при запуске функции, что были включены", "RestoreState"))
Add("Settings", {
    Name = "UI Transparency", Desc = "Переключить прозрачность фона интерфейса", OneShot = true,
    Code = function()
        Settings.Opacity = (Settings.Opacity or 0.92) >= 0.9 and 0.78 or 0.92
        MainFrame.BackgroundTransparency = 1 - Settings.Opacity
        for _, obj in ipairs(ScreenGui:GetDescendants()) do
            if obj:IsA("Frame") and (obj.Name == "SailenntUtilityPanel" or obj.Name == "Card") then
                obj.BackgroundTransparency = 1 - Settings.Opacity
            end
        end
        RequestSave()
        return "Прозрачность: " .. tostring(math.floor(Settings.Opacity * 100)) .. "%"
    end
})

end
do

-- // ============================================================
-- // MODULE LIBRARY (THE BRAIN)
-- // Add("Category", { Name, Desc, Code = function(ctx) return cleanup, loop end, ... })
-- // ============================================================

-- // COMBAT -------------------------------------------------------
Add("Combat", {
    Name = "Smooth Aimbot",
    Desc = "Плавное наведение на цель (удерживай клавишу)",
    Step = "Camera",
    Opts = { O.aimKey, O.aimMethod, O.aimPart, O.aimMode, O.aimFov, O.aimSmooth },
    Code = function()
        local release = Aim.Acquire()
        return release, function(dt)
            Aim.Update()
            if IsOpen or not Aim.Pos or not AimKeyDown() or __Sailennt.UserInputService:GetFocusedTextBox() then return end
            local cam = __Sailennt.Workspace.CurrentCamera
            -- независимо от FPS: за секунду сглаживание даёт один и тот же результат
            local alpha = math.clamp(1 - Opt.aimSmooth ^ (dt * 60), 0.05, 1)
            if Opt.aimMethod == "Mouse" and X.moveRel then
                local sp, on = cam:WorldToViewportPoint(Aim.Pos)
                if on then
                    local step = (Vector2.new(sp.X, sp.Y) - __Sailennt.UserInputService:GetMouseLocation()) * alpha
                    if step.Magnitude > 60 then step = step.Unit * 60 end
                    X.moveRel(step.X, step.Y)
                end
            else
                cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, Aim.Pos), alpha)
            end
        end
    end
})

Add("Combat", {
    Name = "Silent Aim",
    Desc = "Подмена Raycast по цели в FOV; серверная валидация может ловить",
    Opts = { O.aimPart, O.aimMode, O.aimFov },
    Code = function()
        local relHook = Hook.Acquire("silent") -- ошибка здесь = hook недоступен, ничего не успело создаться
        local relAim = Aim.Acquire()
        return function() relHook() relAim() end, function() Aim.Update() end
    end
})

Add("Combat", {
    Name = "Triggerbot",
    Desc = "Автоклик по игроку под курсором",
    Step = "Heartbeat",
    Interval = 0.06,
    Code = function()
        Need(X.click, "mouse1click недоступен в этом executor")
        local mouse = __Sailennt.LocalPlayer:GetMouse()
        return nil, function()
            if IsOpen or __Sailennt.UserInputService:GetFocusedTextBox() then return end
            local t = mouse.Target
            if not t then return end
            local model = t:FindFirstAncestorOfClass("Model")
            local p = model and __Sailennt.Players:GetPlayerFromCharacter(model)
            if p and p ~= __Sailennt.LocalPlayer and IsEnemy(p) then
                local h = model:FindFirstChildOfClass("Humanoid")
                if h and h.Health > 0 then pcall(X.click) end
            end
        end
    end
})

Add("Combat", {
    Name = "Auto Clicker",
    Desc = "Клики с заданным CPS (не кликает при открытом меню)",
    Step = "Heartbeat",
    Opts = { { key = "clickCps", label = "CPS", kind = "num", default = 12, min = 1, max = 50 } },
    Code = function()
        Need(X.click, "mouse1click недоступен в этом executor")
        local acc = 0
        return nil, function(dt)
            if IsOpen then return end
            acc = acc + dt
            if acc >= 1 / math.max(Opt.clickCps, 1) then
                acc = 0
                pcall(X.click)
            end
        end
    end
})

Add("Combat", {
    Name = "Reach",
    Desc = "Увеличивает Handle инструмента; сервер может резать",
    Step = "Heartbeat",
    Interval = 0.5,
    CharDep = true,
    Opts = { { key = "reachSize", label = "Размер", kind = "num", default = 12, min = 5, max = 60 } },
    Code = function(ctx)
        local orig = {} -- Handle -> { Size, Massless, CanCollide }
        local function apply(tool)
            local h = tool:FindFirstChild("Handle")
            if h and h:IsA("BasePart") then
                if not orig[h] then orig[h] = { h.Size, h.Massless, h.CanCollide } end
                local s = Vector3.new(1, 1, 1) * Opt.reachSize
                if h.Size ~= s then h.Size = s end
                h.Massless = true
                h.CanCollide = false
            end
        end
        local function scan(c)
            for _, t in ipairs(c:GetChildren()) do
                if t:IsA("Tool") then apply(t) end
            end
        end
        local c = __Sailennt.Character
        scan(c)
        ctx.Conn(c.ChildAdded:Connect(function(t)
            if t:IsA("Tool") then
                task.wait(0.1)
                if ctx.Alive then apply(t) end
            end
        end))
        return function()
            for h, o in pairs(orig) do
                if h.Parent then
                    h.Size, h.Massless, h.CanCollide = o[1], o[2], o[3]
                end
            end
        end, function()
            if __Sailennt.Character then scan(__Sailennt.Character) end
        end
    end
})

Add("Combat", {
    Name = "Hitbox Expander",
    Desc = "HRP врагов крупнее; серверный хитбокс может ловить",
    Step = "Heartbeat",
    Interval = 0.5,
    Opts = { { key = "hitboxSize", label = "Размер", kind = "num", default = 8, min = 2, max = 30 } },
    Code = function()
        local orig = setmetatable({}, { __mode = "k" }) -- HRP -> { Size, Transparency, CanCollide }
        return function()
            for h, o in pairs(orig) do
                if h.Parent then
                    h.Size, h.Transparency, h.CanCollide = o[1], o[2], o[3]
                end
            end
        end, function()
            local size = Vector3.new(1, 1, 1) * Opt.hitboxSize
            for i = 1, #Others do
                local p = Others[i]
                local e = Parts(p)
                if e and IsEnemy(p) then
                    local h = e.Root
                    if not orig[h] then orig[h] = { h.Size, h.Transparency, h.CanCollide } end
                    if h.Size ~= size then
                        h.Size = size
                        h.Transparency = 0.7
                        h.CanCollide = false
                    end
                end
            end
        end
    end
})

Add("Combat", {
    Name = "Kill Aura",
    Desc = "firetouchinterest Handle по врагам рядом",
    Step = "Heartbeat",
    Interval = 0.1,
    Opts = { { key = "auraRadius", label = "Радиус", kind = "num", default = 25, min = 5, max = 100 } },
    Code = function()
        Need(X.touch, "firetouchinterest недоступен в этом executor")
        return nil, function()
            local root = Root()
            if not root or not __Sailennt.Character then return end
            local tool = __Sailennt.Character:FindFirstChildOfClass("Tool")
            local handle = tool and tool:FindFirstChild("Handle")
            if not handle then return end
            local radius = Opt.auraRadius
            for i = 1, #Others do
                local p = Others[i]
                local e = Parts(p)
                if e and e.Hum.Health > 0 and IsEnemy(p) and (e.Root.Position - root.Position).Magnitude <= radius then
                    pcall(X.touch, handle, e.Root, 0)
                    pcall(X.touch, handle, e.Root, 1)
                end
            end
        end
    end
})

Add("Combat", Mk.Flag("Team Check", "Не трогать тиммейтов (aim / esp / aura / hitbox)"))
Add("Combat", Mk.Flag("Wall Check", "Наводиться только на видимые цели"))
Add("Combat", Mk.Flag("Velocity Prediction", "Упреждение по AssemblyLinearVelocity"))
Add("Combat", Mk.Cycle("Aim Part", "Цель наведения: Head / HumanoidRootPart", "aimPart", O.aimPart.choices, "Цель"))
Add("Combat", Mk.Cycle("Aim Mode", "Точка прицела: Mouse / Center", "aimMode", O.aimMode.choices, "Точка"))
Add("Combat", {
    Name = "Target",
    Desc = "Цель для Teleport / Spectate / Fling",
    OneShot = true,
    Opts = { { key = "targetName", label = "Ник цели (nearest = ближайший)", kind = "str", default = "nearest" } },
    DescFn = function() return "Цель: " .. tostring(Opt.targetName) end,
    Code = function()
        local list = { "nearest" }
        for i = 1, #Others do list[#list + 1] = Others[i].Name end
        local idx = table.find(list, Opt.targetName) or 0
        Opt.targetName = list[idx % #list + 1]
        RequestSave()
        return "Цель = " .. Opt.targetName
    end
})

-- // MOVEMENT -----------------------------------------------------
Add("Movement", {
    Name = "Fly Mode",
    Desc = "Полёт: WASD + Space / Ctrl по взгляду камеры",
    Key = Enum.KeyCode.F,
    CharDep = true,
    Opts = { { key = "flySpeed", label = "Скорость", kind = "num", default = 60, min = 10, max = 500 } },
    Code = function(ctx)
        local root = Need(Root(), "персонаж не найден")
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
        bv.Velocity = Vector3.zero
        bv.Parent = root
        ctx.Inst(bv)
        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(1, 1, 1) * math.huge
        bg.P = 9e4
        bg.CFrame = __Sailennt.Workspace.CurrentCamera.CFrame
        bg.Parent = root
        ctx.Inst(bg)
        return function() bv:Destroy() bg:Destroy() end, function()
            local r = Root()
            if not r then return end
            if bv.Parent ~= r then bv.Parent = r bg.Parent = r end
            local cf = __Sailennt.Workspace.CurrentCamera.CFrame
            local dir = Vector3.zero
            if __Sailennt.IsMobile then
                -- телефон: джойстик задаёт направление, Jump = вверх, наклон камеры при движении = набор/снижение высоты
                local h = GetHum()
                if h then
                    dir = h.MoveDirection
                    if dir.Magnitude > 0 then dir = dir + Vector3.new(0, cf.LookVector.Y * 0.8, 0) end
                    if h.Jump then dir = dir + Vector3.new(0, 1, 0) end
                end
            elseif not __Sailennt.UserInputService:GetFocusedTextBox() then
                if __Sailennt.UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
                if __Sailennt.UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
                if __Sailennt.UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
                if __Sailennt.UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
                if __Sailennt.UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                if __Sailennt.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
            end
            bv.Velocity = (dir.Magnitude > 0 and dir.Unit or Vector3.zero) * Opt.flySpeed
            bg.CFrame = cf
        end
    end
})

Add("Movement", {
    Name = "Noclip",
    Desc = "Проход сквозь любые объекты",
    Key = Enum.KeyCode.N,
    Step = "Stepped",
    CharDep = true,
    Code = function(ctx)
        -- Roblox каждый кадр возвращает CanCollide, поэтому гасим в цикле; список частей кэшируется, а не собирается заново
        local c = Need(__Sailennt.Character, "персонаж не найден")
        local parts, changed = {}, {}
        local function track(d) if d:IsA("BasePart") then parts[d] = true end end
        for _, d in ipairs(c:GetDescendants()) do track(d) end
        ctx.Conn(c.DescendantAdded:Connect(track))
        ctx.Conn(c.DescendantRemoving:Connect(function(d) parts[d] = nil changed[d] = nil end))
        return function()
            for p in pairs(changed) do
                if p.Parent then p.CanCollide = true end
            end
        end, function()
            for p in pairs(parts) do
                if p.CanCollide then
                    changed[p] = true
                    p.CanCollide = false
                end
            end
        end
    end
})

Add("Movement", {
    Name = "Speedhack",
    Desc = "WalkSpeed с защитой от сброса игрой",
    Step = "Heartbeat",
    CharDep = true,
    Opts = { { key = "walkSpeed", label = "WalkSpeed", kind = "num", default = 60, min = 16, max = 500 } },
    Code = function()
        local h = Need(GetHum(), "персонаж не найден")
        local old = h.WalkSpeed
        return function()
            local hh = GetHum()
            if hh then hh.WalkSpeed = old end
        end, function()
            local hh = GetHum()
            if hh and hh.WalkSpeed ~= Opt.walkSpeed then hh.WalkSpeed = Opt.walkSpeed end
        end
    end
})

Add("Movement", {
    Name = "JumpPower",
    Desc = "UseJumpPower + защита от сброса",
    Step = "Heartbeat",
    CharDep = true,
    Opts = { { key = "jumpPower", label = "JumpPower", kind = "num", default = 100, min = 50, max = 500 } },
    Code = function()
        local h = Need(GetHum(), "персонаж не найден")
        local oldPower, oldUse = h.JumpPower, h.UseJumpPower
        return function()
            local hh = GetHum()
            if hh then
                hh.UseJumpPower = oldUse
                hh.JumpPower = oldPower
            end
        end, function()
            local hh = GetHum()
            if hh then
                if not hh.UseJumpPower then hh.UseJumpPower = true end
                if hh.JumpPower ~= Opt.jumpPower then hh.JumpPower = Opt.jumpPower end
            end
        end
    end
})

Add("Movement", {
    Name = "HipHeight",
    Desc = "Подъём модели над землёй",
    Step = "Heartbeat",
    CharDep = true,
    Opts = { { key = "hipHeight", label = "HipHeight", kind = "num", default = 2, min = 0, max = 20 } },
    Code = function()
        local h = Need(GetHum(), "персонаж не найден")
        local old = h.HipHeight
        return function()
            local hh = GetHum()
            if hh then hh.HipHeight = old end
        end, function()
            local hh = GetHum()
            if hh and hh.HipHeight ~= Opt.hipHeight then hh.HipHeight = Opt.hipHeight end
        end
    end
})

Add("Movement", {
    Name = "Gravity",
    Desc = "Workspace.Gravity с защитой от сброса",
    Step = "Heartbeat",
    Opts = { { key = "gravity", label = "Gravity", kind = "num", default = 80, min = 0, max = 196.2 } },
    Code = function()
        local old = __Sailennt.Workspace.Gravity
        return function() __Sailennt.Workspace.Gravity = old end, function()
            if __Sailennt.Workspace.Gravity ~= Opt.gravity then __Sailennt.Workspace.Gravity = Opt.gravity end
        end
    end
})

Add("Movement", {
    Name = "Infinite Jump",
    Desc = "Прыжок в воздухе без лимита",
    Key = Enum.KeyCode.J,
    Code = function(ctx)
        ctx.Conn(__Sailennt.UserInputService.JumpRequest:Connect(function()
            local h = GetHum()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end))
        return nil, nil
    end
})

Add("Movement", {
    Name = "Spinbot",
    Desc = "BodyAngularVelocity на HRP",
    Step = "Heartbeat",
    Interval = 0.25,
    CharDep = true,
    Opts = { { key = "spinSpeed", label = "Скорость", kind = "num", default = 30, min = 5, max = 200 } },
    Code = function(ctx)
        local root = Need(Root(), "персонаж не найден")
        local bav = Instance.new("BodyAngularVelocity")
        bav.MaxTorque = Vector3.new(1, 1, 1) * math.huge
        bav.P = 1e5
        bav.AngularVelocity = Vector3.new(0, Opt.spinSpeed, 0)
        bav.Parent = root
        ctx.Inst(bav)
        return function() bav:Destroy() end, function()
            bav.AngularVelocity = Vector3.new(0, Opt.spinSpeed, 0)
        end
    end
})

Add("Movement", {
    Name = "Platform Stand",
    Desc = "Невидимая платформа под ногами",
    Step = "Stepped",
    Code = function(ctx)
        local p = Instance.new("Part")
        p.Size = Vector3.new(6, 1, 6)
        p.Anchored = true
        p.CanCollide = true
        p.Transparency = 1
        p.Parent = __Sailennt.Workspace
        ctx.Inst(p)
        return nil, function()
            local r = Root()
            if r then p.CFrame = r.CFrame - Vector3.new(0, 3.5, 0) end
        end
    end
})

Add("Movement", {
    Name = "Anti-Void",
    Desc = "Возврат на последнюю безопасную точку",
    Step = "Heartbeat",
    Code = function()
        local safe = Root() and Root().CFrame
        return nil, function()
            local r, h = Root(), GetHum()
            if not r or not h then return end
            if h.FloorMaterial ~= Enum.Material.Air then
                safe = r.CFrame
            elseif safe and r.Position.Y < (__Sailennt.Workspace.FallenPartsDestroyHeight + 25) then
                r.CFrame = safe
                r.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end
})

Add("Movement", {
    Name = "Click Teleport",
    Desc = "ТП по курсору (повесь клавишу в настройках ...)",
    Key = Enum.KeyCode.T,
    OneShot = true,
    Code = function()
        local r = Need(Root(), "персонаж не найден")
        local mp = __Sailennt.UserInputService:GetMouseLocation()
        local ray = __Sailennt.Workspace.CurrentCamera:ViewportPointToRay(mp.X, mp.Y)
        local hit = __Sailennt.Workspace:Raycast(ray.Origin, ray.Direction * 2000, RayParams)
        Need(hit, "курсор не попал в мир")
        r.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
        return "Телепорт выполнен"
    end
})

Add("Movement", {
    Name = "Teleport To Player",
    Desc = "К выбранной цели (карточка Target в Combat)",
    OneShot = true,
    Code = function()
        local r = Need(Root(), "персонаж не найден")
        local t = GetTarget()
        local e = t and Parts(t)
        Need(e, "цель не найдена")
        r.CFrame = e.Root.CFrame * CFrame.new(0, 0, 3)
        return "ТП: " .. t.Name
    end
})

end

-- // ============================================================
-- // UI LOGIC HANDLERS
-- // ============================================================
local CurrentCategory = nil
local CategoryCells = {}   -- кэш карточек: строятся один раз на категорию
local IntroGen = 0

-- Пресеты твинов (создаются один раз)
local TI_Fade = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_Pop = TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TI_Slide = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_Blur = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_Press = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TI_Card = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local REST = UDim2.new(0.5, 0, 0.5, 0)

-- // THEMES (A = нечётные карточки и подсветка вкладки, B = чётные карточки)
local Themes = {
    { Name = "Violet",  A = { Color3.fromRGB(60, 120, 255), Color3.fromRGB(150, 70, 220) },  B = { Color3.fromRGB(235, 60, 80), Color3.fromRGB(110, 80, 230) },  Accent = Color3.fromRGB(88, 70, 255) },
    { Name = "Ocean",   A = { Color3.fromRGB(0, 170, 255), Color3.fromRGB(0, 90, 200) },     B = { Color3.fromRGB(0, 200, 180), Color3.fromRGB(0, 110, 220) },    Accent = Color3.fromRGB(0, 150, 255) },
    { Name = "Crimson", A = { Color3.fromRGB(235, 60, 80), Color3.fromRGB(160, 30, 120) },   B = { Color3.fromRGB(255, 120, 60), Color3.fromRGB(220, 40, 90) },   Accent = Color3.fromRGB(235, 60, 80) },
    { Name = "Emerald", A = { Color3.fromRGB(40, 200, 120), Color3.fromRGB(0, 140, 160) },   B = { Color3.fromRGB(120, 220, 60), Color3.fromRGB(30, 170, 110) },  Accent = Color3.fromRGB(40, 200, 120) },
    { Name = "Sunset",  A = { Color3.fromRGB(255, 140, 50), Color3.fromRGB(220, 50, 110) },  B = { Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 90, 90) },   Accent = Color3.fromRGB(255, 120, 70) },
}
local GradBlue = { Themes[1].A[1], Themes[1].A[2] }
local GradRed = { Themes[1].B[1], Themes[1].B[2] }
local ThemeIndex = 1

local function ApplyTheme(i)
    ThemeIndex = i
    Settings.Theme = i
    RequestSave()
    local T = Themes[i]
    GradBlue[1], GradBlue[2] = T.A[1], T.A[2]
    GradRed[1], GradRed[2] = T.B[1], T.B[2]
    __Sailennt.Config.Accent = T.Accent
    FeatureContainer.ScrollBarImageColor3 = T.Accent
    for _, d in ipairs(ScreenGui:GetDescendants()) do
        if d:IsA("UIGradient") then
            local slot = d:GetAttribute("ThemeSlot")
            local P = (slot == "A" and GradBlue) or (slot == "B" and GradRed)
            if P then d.Color = ColorSequence.new(P[1], P[2]) end
        end
    end
    __Sailennt.ThemeNameLabel.Text = "Themes · " .. T.Name
end

-- // NOTIFICATIONS (правый нижний угол) + звук
local NotifyHolder
do
NotifyHolder = Instance.new("Frame")
NotifyHolder.Name = "Notifications"
NotifyHolder.AnchorPoint = Vector2.new(1, 1)
NotifyHolder.Position = UDim2.new(1, -16, 1, -16)
NotifyHolder.Size = UDim2.new(0, 250, 0, 320)
NotifyHolder.BackgroundTransparency = 1
NotifyHolder.ZIndex = 10
NotifyHolder.Parent = ScreenGui

local NotifyList = Instance.new("UIListLayout")
NotifyList.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifyList.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifyList.SortOrder = Enum.SortOrder.LayoutOrder
NotifyList.Padding = UDim.new(0, 8)
NotifyList.Parent = NotifyHolder

end
local NotifyOrder = 0
local ColOn, ColOff = Color3.fromRGB(60, 220, 130), Color3.fromRGB(235, 70, 90)

-- один Sound на весь клиент
local EnableSound
pcall(function()
    EnableSound = Instance.new("Sound")
    EnableSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    EnableSound.Volume = 0.6
    EnableSound.PlaybackSpeed = 1.15
    EnableSound.Parent = __Sailennt.SoundService
end)
-- свой звук: встроенный mp3 -> файл (один раз) -> getcustomasset; если не вышло, остаётся стандартный пинг
pcall(function()
    if not (EnableSound and writefile and getcustomasset) then return end
    local FILE = "sailennt_enable_v2.mp3"
    if not (isfile and isfile(FILE)) then
        local B64 = [==[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RDBdkKCl0HTDUwQRCyRS//tSxDeAChlXP6YBotFGKuapB6sCDdDib9SjGr81rnvulAXQPEZv0wDjTgvSYu3+6mVVv+qGAWHHm//9RuR//////5zC1//6VUAALLQrW22gNn/00BVGSgJsHkopIqot1kiJj1ibCMl9I/5iJBavUnySYyDaDWbmLf8b1KQFnnP5sZIv/qOKpiN/6iQWPT//WokHv+v////40AEmMwAQAEADyLuXO87hnvW61WtV3MS3LnbFPSSvWrvU0Vmy6zluJCNDpMTBQ2Jarq5/WlB4LPX/+1LERAAKEVVDpry8EUkbZXWECtjXE1I0xyBcIWn/5nKzf9YUIM//Ku///kf/+HULVCAkmgpIdDjTIzKqqifqiKn0Rf/+q/1VP1X/Un2+/TT/1+m3+nS1vaqN///6//06Had36mU7oZVRT8UgsT4SQQQaoAAAyXbXSV1L7N96/v2/9f/+t/ub1//akRZ3NtwjuYJBD206UjkZT9X/N//2f+f/5/+/jzDPyvTm1mpoLPs88IGKjDELTdUWB30AQWEAAAyXa267pttX//9//f//yP/7UsRQgAexrxMthEFJLzZhNVCa+L//X5dyLxhliNzu5wF0E1Uym1PzUl/Xz/L/9bPl9nb/6i7s142Qg2qtzJ8K+AScB5ASyu6yYaDJdW97Ws2ybv1/Wrv////6//9fbrt6f8va9apovo+vp7l7L///v00+xNHmVX2cihkmDsHBMMEBgSypddiw85UIAADwAAGVzof////58pS//////1r7fpMzZnu52yc1M4FOEYXl/NZ4vy+fl/uXCqlL+MZ3ORX29dN0nXu6thIsswhwRIYJ//tSxGmASQGrCaqE18kRNmExUSc4HBUhwW+wSyQaEGS6jqZna3X1dfbUq7v/6///f/n757JZ9f18/KYzc+uRyW7////+bdtfvr+t/89Ge/NnW1HmndLWp4RPTQWBkx4AAARoChgAAAzIf/79XWr//rL///y/l79GspljKwSwITNG9i5hqPw2VWY9VEsmH8v7IM/87f9in+5LNQrLXrkdpaJSCKTpEAQJcNCJBJgAQAVS4YDK59b/7b7a2/f/////L/n+/dmv/iMiubK/RhEdSmb/+1LEgQBJMbUHKoU30Rm2ITVQmvlIkgFZAB1///7/t27/u3vbMq0mg7IdWy+G0Fag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Ynu7/TD1pNMoUzLcGROUiuSk//tSxOiAS2G0/gsNnsFvNqAxYSb40xML8nWNGVrJwZKZE/D/xyUz0spLt8ABsIDsOjwnSmLSmlhG8J5nMjlMnhIqM6fdl1/1u2y2900/bZLfZFTdnqWia+iOm6X9f+3/+qmneYpialMcjXUUxRpQalRgIxSA3SoZAAM9JGqhkQAUCpUJZooqrMDaksVuQhhCB4UkwZA2IJYH4klI/LJKQlZZKydEfHJwiJxVODYxLy81EkvH5ZJRTPC0SUNAKBTA4SDHrCRR6iRsLJFwkaVaJxX/+1LE6wBMdbUBiw2ewXu2IDVhp9lonPCRpWJGxqJ1qIlWjReVLwlLbNPs1eVMbTxstuU1o1MVkCZSQ4kOKiSapJKVS0oqk1SXrgs2ZLQcNRBhLgSBATwbIwCFl4QZ4ocFRCcLlF0joeD4yURsOhlbDI1YKCBA5ZYDBAgYJu8CiosLKFhcRu+KigtFhYVZ9YqLYsLs/WKahYV/ivULs/+LCtVMQU1FMy45OS41VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVf/7UsTngEvptQGrDT7BZLYhQcGJeFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV//tSxOkDU0UXCk0wy8kwC9sA9IzgVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVU=]==]
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local lookup = {}
        for i = 1, #chars do lookup[chars:sub(i, i)] = i - 1 end
        local out, bits, nbits = {}, 0, 0
        for i = 1, #B64 do
            local v = lookup[B64:sub(i, i)]
            if v then
                bits = bits * 64 + v
                nbits = nbits + 6
                if nbits >= 8 then
                    nbits = nbits - 8
                    local byte = math.floor(bits / 2 ^ nbits)
                    out[#out + 1] = string.char(byte)
                    bits = bits - byte * 2 ^ nbits
                end
            end
        end
        writefile(FILE, table.concat(out))
    end
    local id = getcustomasset(FILE)
    if id and id ~= "" then
        EnableSound.SoundId = id
        EnableSound.Volume = 0.7
        EnableSound.PlaybackSpeed = 1
    end
end)
PlayEnableSound = function()
    if not Settings.Sounds or not EnableSound then return end
    EnableSound.TimePosition = 0
    EnableSound:Play()
end

Notify = function(name, on, subText)
    Log(name .. ": " .. tostring(subText or (on and "ON" or "OFF")))
    if not Settings.Notifications then return end
    NotifyOrder = NotifyOrder + 1
    local list = {}
    for _, c in ipairs(NotifyHolder:GetChildren()) do
        if c:IsA("Frame") then table.insert(list, c) end
    end
    if #list >= 5 then
        table.sort(list, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
        list[1]:Destroy()
    end

    local Wrap = Instance.new("Frame")
    Wrap.Size = UDim2.new(1, 0, 0, 48)
    Wrap.BackgroundTransparency = 1
    Wrap.LayoutOrder = NotifyOrder
    Wrap.Parent = NotifyHolder

    local T = Instance.new("Frame")
    T.Size = UDim2.new(1, 0, 1, 0)
    T.Position = UDim2.new(1.3, 0, 0, 0)
    T.BackgroundColor3 = __Sailennt.Config.CardBG
    T.BorderSizePixel = 0
    T.ZIndex = 10
    T.Parent = Wrap
    __Sailennt.Corner(T, 8)
    __Sailennt.Stroke(T, __Sailennt.Config.Stroke, 1)

    local col = on and ColOn or ColOff
    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(0, 3, 1, -20)
    Bar.Position = UDim2.new(0, 0, 0, 10)
    Bar.BackgroundColor3 = col
    Bar.BorderSizePixel = 0
    Bar.ZIndex = 10
    Bar.Parent = T
    __Sailennt.Corner(Bar, 2)

    __Sailennt.Label(T, on and "OK" or "X", 12, col, Enum.Font.GothamBold, UDim2.new(0, 12, 0, 0), UDim2.new(0, 22, 1, 0), Enum.TextXAlignment.Center).ZIndex = 10
    local Tt = __Sailennt.Label(T, name, 13, __Sailennt.Config.TextMain, Enum.Font.GothamBold, UDim2.new(0, 42, 0, 7), UDim2.new(1, -52, 0, 18))
    Tt.ZIndex = 10
    Tt.TextTruncate = Enum.TextTruncate.AtEnd
    local St = __Sailennt.Label(T, subText or (on and "Функция включена" or "Функция выключена"), 11, __Sailennt.Config.TextSub, Enum.Font.Gotham, UDim2.new(0, 42, 0, 25), UDim2.new(1, -52, 0, 16))
    St.ZIndex = 10
    St.TextTruncate = Enum.TextTruncate.AtEnd

    __Sailennt.TweenService:Create(T, TI_Slide, { Position = UDim2.new(0, 0, 0, 0) }):Play()
    task.delay(2.5, function()
        if Wrap.Parent then
            local out = __Sailennt.TweenService:Create(T, __Sailennt.TI_Close, { Position = UDim2.new(1.3, 0, 0, 0) })
            out.Completed:Connect(function() Wrap:Destroy() end)
            out:Play()
        end
    end)
end

UIHook.State = function()
    local n = 0
    for name in pairs(ActiveCleanups) do
        local d = Defs[name]
        if d and d.Cat ~= "Settings" then n = n + 1 end
    end
    __Sailennt.Ui.Active.Text = "• " .. n .. " активно"
end

-- // SETTINGS POPUP (⚙ на карточке или ПКМ): горячая клавиша + настройки модуля
local OpenPopup, ClosePopup, HandleBindKey
do
local Popup = Instance.new("Frame")
Popup.Name = "Popup"
Popup.Size = UDim2.new(1, 0, 1, 0)
Popup.BackgroundTransparency = 1
Popup.Visible = false
Popup.ZIndex = 20
Popup.Parent = ContentArea

local PopupShade = Instance.new("TextButton")
PopupShade.Size = UDim2.new(1, 0, 1, 0)
PopupShade.BackgroundColor3 = Color3.new(0, 0, 0)
PopupShade.BackgroundTransparency = 0.45
PopupShade.BorderSizePixel = 0
PopupShade.AutoButtonColor = false
PopupShade.Text = ""
PopupShade.ZIndex = 20
PopupShade.Parent = Popup

local PopupPanel = Instance.new("Frame")
PopupPanel.AnchorPoint = Vector2.new(0.5, 0.5)
PopupPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
PopupPanel.Size = UDim2.new(0, 330, 0, 200)
PopupPanel.BackgroundColor3 = __Sailennt.Config.BG
PopupPanel.BorderSizePixel = 0
PopupPanel.ZIndex = 21
PopupPanel.Parent = Popup
__Sailennt.Corner(PopupPanel, 10)
__Sailennt.Stroke(PopupPanel, __Sailennt.Config.Stroke, 1)

local PopupTitle = __Sailennt.Label(PopupPanel, "", 14, __Sailennt.Config.TextMain, Enum.Font.GothamBold, UDim2.new(0, 14, 0, 10), UDim2.new(1, -56, 0, 18))
PopupTitle.ZIndex = 22
local PopupDesc = __Sailennt.Label(PopupPanel, "", 10, __Sailennt.Config.TextSub, Enum.Font.Gotham, UDim2.new(0, 14, 0, 29), UDim2.new(1, -28, 0, 14))
PopupDesc.ZIndex = 22
PopupDesc.TextTruncate = Enum.TextTruncate.AtEnd
local PopupClose = Instance.new("TextButton")
PopupClose.Size = UDim2.new(0, 24, 0, 24)
PopupClose.Position = UDim2.new(1, -34, 0, 8)
PopupClose.BackgroundTransparency = 1
PopupClose.Text = "X"
PopupClose.TextSize = 14
PopupClose.Font = Enum.Font.GothamBold
PopupClose.TextColor3 = __Sailennt.Config.TextSub
PopupClose.ZIndex = 22
PopupClose.Parent = PopupPanel

local PopupRows = Instance.new("Frame")
PopupRows.Position = UDim2.new(0, 14, 0, 52)
PopupRows.Size = UDim2.new(1, -28, 1, -62)
PopupRows.BackgroundTransparency = 1
PopupRows.ZIndex = 22
PopupRows.Parent = PopupPanel
local PopupList = Instance.new("UIListLayout")
PopupList.Padding = UDim.new(0, 6)
PopupList.SortOrder = Enum.SortOrder.LayoutOrder
PopupList.Parent = PopupRows

local PopupDef = nil
local ListeningBind = nil -- def, для которого ждём нажатие клавиши
local BindButton = nil

local function KeyText(def)
    local k = Binds[def.Name]
    return k and k.Name or "—"
end

local function PopupRow(order, text)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 28)
    Row.BackgroundColor3 = __Sailennt.Config.CardBG
    Row.BorderSizePixel = 0
    Row.LayoutOrder = order
    Row.ZIndex = 22
    Row.Parent = PopupRows
    __Sailennt.Corner(Row, 6)
    local L = __Sailennt.Label(Row, text, 12, __Sailennt.Config.TextMain, Enum.Font.GothamMedium, UDim2.new(0, 10, 0, 0), UDim2.new(1, -150, 1, 0))
    L.ZIndex = 23
    L.TextTruncate = Enum.TextTruncate.AtEnd
    return Row
end

local function PopupControl(Row, class, w)
    local C = Instance.new(class)
    C.AnchorPoint = Vector2.new(1, 0.5)
    C.Position = UDim2.new(1, -6, 0.5, 0)
    C.Size = UDim2.new(0, w, 0, 22)
    C.BackgroundColor3 = __Sailennt.Config.SideBG
    C.BorderSizePixel = 0
    C.TextColor3 = __Sailennt.Config.TextMain
    C.Font = Enum.Font.Gotham
    C.TextSize = 12
    C.ZIndex = 23
    C.Parent = Row
    __Sailennt.Corner(C, 5)
    return C
end

local function RestartIfNeeded(def)
    if def.Restart and IsOn(def.Name) then
        SetModule(def, false, true)
        SetModule(def, true, true)
    end
end

ClosePopup = function()
    ListeningBind = nil
    PopupDef = nil
    Popup.Visible = false
    RequestSave()
end

OpenPopup = function(def)
    ListeningBind = nil
    PopupDef = def
    for _, c in ipairs(PopupRows:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    PopupTitle.Text = def.Name
    PopupDesc.Text = def.Desc or ""
    local order = 0

    -- горячая клавиша
    order = order + 1
    local BRow = PopupRow(order, "Горячая клавиша")
    BindButton = PopupControl(BRow, "TextButton", 110)
    BindButton.Text = KeyText(def)
    BindButton.MouseButton1Click:Connect(function()
        ListeningBind = def
        BindButton.Text = "нажми клавишу…"
    end)

    for _, s in ipairs(def.Opts or {}) do
        order = order + 1
        local Row = PopupRow(order, s.label or s.key)
        if s.kind == "num" then
            local Box = PopupControl(Row, "TextBox", 90)
            Box.Text = tostring(Opt[s.key])
            Box.ClearTextOnFocus = false
            Box.FocusLost:Connect(function()
                local v = tonumber(Box.Text)
                if v then
                    v = math.clamp(v, s.min or -math.huge, s.max or math.huge)
                    Opt[s.key] = v
                    RestartIfNeeded(def)
                end
                Box.Text = tostring(Opt[s.key])
            end)
        elseif s.kind == "str" then
            local Box = PopupControl(Row, "TextBox", 150)
            Box.Text = tostring(Opt[s.key])
            Box.ClearTextOnFocus = false
            Box.ClipsDescendants = true
            Box.FocusLost:Connect(function()
                Opt[s.key] = Box.Text
                RestartIfNeeded(def)
            end)
        elseif s.kind == "bool" then
            local Btn = PopupControl(Row, "TextButton", 70)
            Btn.Text = Opt[s.key] and "ON" or "OFF"
            Btn.TextColor3 = Opt[s.key] and ColOn or __Sailennt.Config.TextSub
            Btn.MouseButton1Click:Connect(function()
                Opt[s.key] = not Opt[s.key]
                Btn.Text = Opt[s.key] and "ON" or "OFF"
                Btn.TextColor3 = Opt[s.key] and ColOn or __Sailennt.Config.TextSub
                RestartIfNeeded(def)
            end)
        else -- choice
            local Btn = PopupControl(Row, "TextButton", 130)
            Btn.Text = tostring(Opt[s.key])
            Btn.MouseButton1Click:Connect(function()
                local i = table.find(s.choices, Opt[s.key]) or 0
                Opt[s.key] = s.choices[i % #s.choices + 1]
                Btn.Text = tostring(Opt[s.key])
                RestartIfNeeded(def)
                if def._refreshDesc then def._refreshDesc() end
            end)
        end
    end
    PopupPanel.Size = UDim2.new(0, 330, 0, 62 + order * 34)
    Popup.Visible = true
end
__Sailennt.Ui.QuickBind = function(def)
    ListeningBind = def
    BindButton = nil
    Notify(def.Name, true, "Нажми клавишу (Esc — отмена, Backspace — очистить)")
end
PopupShade.MouseButton1Click:Connect(ClosePopup)
PopupClose.MouseButton1Click:Connect(ClosePopup)

-- Назначение клавиши (Esc — отмена, Backspace/Delete — очистить)
HandleBindKey = function(key)
    local def = ListeningBind
    if not def then return end
    ListeningBind = nil
    if key == Enum.KeyCode.Escape then
    elseif key == Enum.KeyCode.Backspace or key == Enum.KeyCode.Delete then
        BindSet(def.Name, nil)
    elseif key ~= __Sailennt.Config.ToggleKey and key ~= __Sailennt.Config.UnloadKey then
        BindSet(def.Name, key)
    end
    if BindButton and PopupDef == def then BindButton.Text = KeyText(def) end
    RequestSave()
end
__Sailennt.BindCaptureActive = function() return ListeningBind ~= nil end
__Sailennt.CaptureBindKey = function(key) HandleBindKey(key) end
__Sailennt.Ui.ClosePopup = ClosePopup

end


-- // CONFIG PANEL (кнопка Configs или ▤ в поиске): профили, автозагрузка, экспорт/импорт
do
    local Rt = Instance.new("Frame")
    Rt.Name = "Cfg"
    Rt.Size = UDim2.new(1, 0, 1, 0)
    Rt.BackgroundTransparency = 1
    Rt.Visible = false
    Rt.ZIndex = 30
    Rt.Parent = ContentArea
    local Shade = Instance.new("TextButton")
    Shade.Size = UDim2.new(1, 0, 1, 0)
    Shade.BackgroundColor3 = Color3.new(0, 0, 0)
    Shade.BackgroundTransparency = 0.45
    Shade.BorderSizePixel = 0
    Shade.AutoButtonColor = false
    Shade.Text = ""
    Shade.ZIndex = 30
    Shade.Parent = Rt
    local P = Instance.new("Frame")
    P.AnchorPoint = Vector2.new(0.5, 0.5)
    P.Position = UDim2.new(0.5, 0, 0.5, 0)
    P.Size = UDim2.new(0, 360, 0, 352)
    P.BackgroundColor3 = __Sailennt.Config.BG
    P.BorderSizePixel = 0
    P.ZIndex = 31
    P.Parent = Rt
    __Sailennt.Corner(P, 10)
    __Sailennt.Stroke(P, __Sailennt.Config.Stroke, 1)
    local function Z(o, z) o.ZIndex = z or 32 return o end
    Z(__Sailennt.Label(P, "Configs", 14, __Sailennt.Config.TextMain, Enum.Font.GothamBold, UDim2.new(0, 14, 0, 10), UDim2.new(1, -56, 0, 18)))
    local Sub = Z(__Sailennt.Label(P, Profiles.Persistent and "Профили сохраняются в файлах executor" or "Нет файлов в executor: профили живут до перезахода (используй экспорт)", 10, __Sailennt.Config.TextSub, Enum.Font.Gotham, UDim2.new(0, 14, 0, 29), UDim2.new(1, -28, 0, 14)))
    Sub.TextTruncate = Enum.TextTruncate.AtEnd
    local function Btn(text, w, pos, parent, col)
        local B = Instance.new("TextButton")
        B.Size = UDim2.new(0, w, 0, 26)
        B.Position = pos
        B.BackgroundColor3 = col or __Sailennt.Config.CardBG
        B.BorderSizePixel = 0
        B.Text = text
        B.TextSize = 11
        B.Font = Enum.Font.GothamMedium
        B.TextColor3 = __Sailennt.Config.TextMain
        B.AutoButtonColor = false
        B.ZIndex = 33
        B.Parent = parent
        __Sailennt.Corner(B, 6)
        return B
    end
    local function Box(ph, pos, size)
        local T = Instance.new("TextBox")
        T.Position = pos
        T.Size = size
        T.BackgroundColor3 = __Sailennt.Config.CardBG
        T.BorderSizePixel = 0
        T.PlaceholderText = ph
        T.PlaceholderColor3 = __Sailennt.Config.TextSub
        T.Text = ""
        T.TextColor3 = __Sailennt.Config.TextMain
        T.Font = Enum.Font.Gotham
        T.TextSize = 12
        T.ClearTextOnFocus = false
        T.ClipsDescendants = true
        T.ZIndex = 33
        T.Parent = P
        __Sailennt.Corner(T, 6)
        return T
    end
    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0, 24, 0, 24)
    Close.Position = UDim2.new(1, -34, 0, 8)
    Close.BackgroundTransparency = 1
    Close.Text = "X"
    Close.TextSize = 14
    Close.Font = Enum.Font.GothamBold
    Close.TextColor3 = __Sailennt.Config.TextSub
    Close.ZIndex = 33
    Close.Parent = P

    local NameBox = Box("имя конфига", UDim2.new(0, 14, 0, 50), UDim2.new(1, -112, 0, 28))
    local SaveBtn = Btn("Сохранить", 84, UDim2.new(1, -98, 0, 51), P, __Sailennt.Config.Accent)
    local List = Instance.new("ScrollingFrame")
    List.Position = UDim2.new(0, 14, 0, 88)
    List.Size = UDim2.new(1, -28, 0, 150)
    List.BackgroundTransparency = 1
    List.BorderSizePixel = 0
    List.ScrollBarThickness = 2
    List.CanvasSize = UDim2.new(0, 0, 0, 0)
    List.ZIndex = 32
    List.Parent = P
    local LL = Instance.new("UIListLayout")
    LL.Padding = UDim.new(0, 6)
    LL.SortOrder = Enum.SortOrder.LayoutOrder
    LL.Parent = List
    local ImportBox = Box("вставь JSON для импорта", UDim2.new(0, 14, 0, 248), UDim2.new(1, -112, 0, 28))
    local ImportBtn = Btn("Импорт", 84, UDim2.new(1, -98, 0, 249), P)
    local ExportBtn = Btn("Экспорт текущих настроек в буфер", 250, UDim2.new(0, 14, 0, 284), P)
    local MsgL = Z(__Sailennt.Label(P, "", 11, __Sailennt.Config.TextSub, Enum.Font.GothamMedium, UDim2.new(0, 14, 0, 318), UDim2.new(1, -28, 0, 26)))
    MsgL.TextWrapped = true
    MsgL.TextYAlignment = Enum.TextYAlignment.Top

    local function Msg(t, ok)
        MsgL.Text = t
        MsgL.TextColor3 = ok and ColOn or ColOff
    end
    local function Refresh()
        for _, c in ipairs(List:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        local names = Profiles.List()
        for i, n in ipairs(names) do
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, -6, 0, 28)
            Row.LayoutOrder = i
            Row.BackgroundColor3 = __Sailennt.Config.CardBG
            Row.BorderSizePixel = 0
            Row.ZIndex = 33
            Row.Parent = List
            __Sailennt.Corner(Row, 6)
            local isAuto = Profiles.Index.autoload == n
            local L = Z(__Sailennt.Label(Row, n .. (isAuto and "  [авто]" or ""), 12, __Sailennt.Config.TextMain, Enum.Font.GothamMedium, UDim2.new(0, 10, 0, 0), UDim2.new(1, -150, 1, 0)), 34)
            L.TextTruncate = Enum.TextTruncate.AtEnd
            local Load = Btn("Загрузить", 64, UDim2.new(1, -140, 0, 1), Row, __Sailennt.Config.SideBG)
            local Auto = Btn(isAuto and "[авто]" or "авто", 46, UDim2.new(1, -72, 0, 1), Row, __Sailennt.Config.SideBG)
            local Del = Btn("X", 22, UDim2.new(1, -26, 0, 1), Row, __Sailennt.Config.SideBG)
            for _, b in ipairs({ Load, Auto, Del }) do b.ZIndex = 34 b.Size = UDim2.new(0, b.Size.X.Offset, 0, 26) end
            Load.MouseButton1Click:Connect(function()
                local ok, err = Profiles.Load(n)
                Msg(ok and ("Загружен: " .. n) or tostring(err), ok)
                if ok then Notify("Configs", true, "Загружен: " .. n) end
            end)
            Auto.MouseButton1Click:Connect(function()
                Profiles.SetAutoload(isAuto and nil or n)
                Msg(isAuto and "Автозагрузка выключена" or ("Автозагрузка: " .. n), true)
                Refresh()
            end)
            Del.MouseButton1Click:Connect(function()
                Profiles.Delete(n)
                Msg("Удалён: " .. n, true)
                Refresh()
            end)
        end
        List.CanvasSize = UDim2.new(0, 0, 0, #names * 34)
    end
    SaveBtn.MouseButton1Click:Connect(function()
        local ok, r = Profiles.Save(NameBox.Text)
        if ok then
            Msg("Сохранён: " .. r, true)
            Notify("Configs", true, "Сохранён: " .. r)
            Refresh()
        else
            Msg(tostring(r), false)
        end
    end)
    ImportBtn.MouseButton1Click:Connect(function()
        local ok, r = Profiles.Import(ImportBox.Text)
        Msg(ok and "Импортировано и применено" or tostring(r), ok)
    end)
    ExportBtn.MouseButton1Click:Connect(function()
        local s = Profiles.Export()
        if X.clip then
            X.clip(s)
            Msg("JSON скопирован в буфер обмена", true)
        else
            ImportBox.Text = s
            Msg("Буфера нет: JSON помещён в поле выше, скопируй вручную", true)
        end
    end)
    __Sailennt.Ui.CloseCfg = function() Rt.Visible = false end
    __Sailennt.Ui.OpenCfg = function()
        if __Sailennt.Ui.ClosePopup then __Sailennt.Ui.ClosePopup() end
        if __Sailennt.Ui.CloseUtility then __Sailennt.Ui.CloseUtility() end
        Profiles.LoadIndex()
        Msg("", true)
        Refresh()
        Rt.Visible = true
    end
    Shade.MouseButton1Click:Connect(__Sailennt.Ui.CloseCfg)
    Close.MouseButton1Click:Connect(__Sailennt.Ui.CloseCfg)
end

-- // DASHBOARD + ACTIVITY LOG PANELS
local UtilityPanel = Instance.new("Frame")
UtilityPanel.Name = "SailenntUtilityPanel"
UtilityPanel.AnchorPoint = Vector2.new(0.5, 0.5)
UtilityPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
UtilityPanel.Size = UDim2.new(1, -28, 1, -82)
UtilityPanel.BackgroundColor3 = __Sailennt.Config.BG
UtilityPanel.BorderSizePixel = 0
UtilityPanel.Visible = false
UtilityPanel.ZIndex = 30
UtilityPanel.Parent = ContentArea
__Sailennt.Corner(UtilityPanel, 10)
__Sailennt.Stroke(UtilityPanel, __Sailennt.Config.Stroke, 1)

local UtilityTitle = __Sailennt.Label(UtilityPanel, "Dashboard", 15, __Sailennt.Config.TextMain, Enum.Font.GothamBold,
    UDim2.new(0, 14, 0, 10), UDim2.new(1, -54, 0, 22))
UtilityTitle.ZIndex = 31
local UtilityClose = Instance.new("TextButton")
UtilityClose.Size = UDim2.fromOffset(28, 26)
UtilityClose.Position = UDim2.new(1, -38, 0, 7)
UtilityClose.BackgroundTransparency = 1
UtilityClose.Text = "X"
UtilityClose.TextColor3 = __Sailennt.Config.TextSub
UtilityClose.TextSize = 14
UtilityClose.ZIndex = 31
UtilityClose.Parent = UtilityPanel

local UtilityBody = Instance.new("ScrollingFrame")
UtilityBody.Position = UDim2.new(0, 12, 0, 42)
UtilityBody.Size = UDim2.new(1, -24, 1, -54)
UtilityBody.BackgroundTransparency = 1
UtilityBody.BorderSizePixel = 0
UtilityBody.ScrollBarThickness = 2
UtilityBody.AutomaticCanvasSize = Enum.AutomaticSize.Y
UtilityBody.CanvasSize = UDim2.new()
UtilityBody.ZIndex = 31
UtilityBody.Parent = UtilityPanel
local UtilityLayout = Instance.new("UIListLayout")
UtilityLayout.Padding = UDim.new(0, 7)
UtilityLayout.SortOrder = Enum.SortOrder.LayoutOrder
UtilityLayout.Parent = UtilityBody

local UtilityRows = {}
local function ClearUtilityRows()
    for _, obj in ipairs(UtilityBody:GetChildren()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then obj:Destroy() end
    end
    table.clear(UtilityRows)
end
local function UtilityRow(text, order, height)
    local row = Instance.new("TextLabel")
    row.LayoutOrder = order
    row.Size = UDim2.new(1, -2, 0, height or 34)
    row.BackgroundColor3 = __Sailennt.Config.CardBG
    row.BackgroundTransparency = 1 - (Settings.Opacity or 0.92)
    row.BorderSizePixel = 0
    row.Text = "  " .. tostring(text)
    row.TextColor3 = __Sailennt.Config.TextMain
    row.TextSize = 12
    row.Font = Enum.Font.Gotham
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextWrapped = true
    row.ZIndex = 32
    row.Parent = UtilityBody
    __Sailennt.Corner(row, 6)
    UtilityRows[#UtilityRows + 1] = row
    return row
end
local function ShowUtility(title)
    UtilityTitle.Text = title
    ClearUtilityRows()
    UtilityPanel.Visible = true
    FeatureContainer.Visible = false
end
local PaletteOn = false -- Command Palette: результаты поиска по всем категориям в панели утилит
local function CloseUtility()
    PaletteOn = false
    UtilityPanel.Visible = false
    FeatureContainer.Visible = true
end
UtilityClose.MouseButton1Click:Connect(CloseUtility)

OpenDashboard = function()
    ShowUtility("Dashboard")
    local active = 0
    for name in pairs(ActiveCleanups) do
        local def = Defs[name]
        if def and def.Cat ~= "Settings" then active = active + 1 end
    end
    local ping = "n/a"
    pcall(function() ping = tostring(math.floor(__Sailennt.Stats.Network.ServerStatsItem["Data Ping"]:GetValue())) .. " ms" end)
    UtilityRow("Client: Sailennt v5.2", 1)
    UtilityRow("PlaceId: " .. tostring(game.PlaceId), 2)
    UtilityRow("Players: " .. tostring(#__Sailennt.Players:GetPlayers()) .. " / " .. tostring(__Sailennt.Players.MaxPlayers), 3)
    UtilityRow("Ping: " .. ping, 4)
    UtilityRow("Executor: " .. tostring(X.name), 5)
    UtilityRow("Active modules: " .. tostring(active), 6)
    UtilityRow("Performance: enable HUD Overlay for live FPS / Ping", 7)
    UtilityRow("Platform: " .. (__Sailennt.IsMobile and "Mobile" or "Desktop"), 8)
    UtilityRow("Config backup: " .. ((isfile and isfile(CONFIG_BACKUP_FILE)) and "available" or "not created yet"), 9)
    UtilityRow("Press Ctrl + K to open command search", 10)
end

__Sailennt.Ui.OpenAbout = function()
    ShowUtility("About")
    UtilityRow("Sailennt v5.2 — клиент-хаб для Roblox (Solara rebuild)", 1)
    UtilityRow("ConfigVersion: " .. tostring(CONFIG_VERSION) .. " · Executor: " .. tostring(X.name), 2)
    UtilityRow("Ctrl + K — Command Palette: поиск функций по всем категориям", 3)
    UtilityRow("ПКМ или кнопка ... на карточке — настройки функции и бинд клавиши", 4)
    UtilityRow("Dashboard — состояние клиента · Activity Log — события и ошибки · Executor Info — доступные API", 5, 40)
    UtilityRow("Configs — профили, автозагрузка, экспорт/импорт с проверкой версии; резервная копия делается при каждом сохранении", 6, 52)
end

__Sailennt.Ui.OpenHistory = function()
    ShowUtility("Update History")
    local notes = {
        "v5.2 — Command Palette (Ctrl+K) по всем категориям; страницы About и Update History",
        "v5.2 — проверка версии профиля при импорте/загрузке; экспорт без Webhook URL",
        "v5.2 — исправлены: сортировка AZ/ZA, карточки в Избранном, наслоение __namecall-хука при перезапуске, Reach после выключения",
        "v5.2 — карточки не обрезаются при увеличении и рисуются поверх соседних; иконки без нестандартных символов",
        "v5.2 — резервная копия конфигурации, Dashboard, Activity Log, Избранное, поиск",
    }
    for i, line in ipairs(notes) do UtilityRow(line, i, 44) end
end

local function PaletteRender()
    ShowUtility("Command Palette")
    PaletteOn = true
    local q = string.lower(SearchBox.Text)
    if q == "" then
        UtilityRow("Введи название или описание функции — поиск идёт по всем категориям", 1)
        return
    end
    local shown = 0
    for _, cat in ipairs({ "Combat", "Movement", "Visuals", "Player", "World", "Misc", "Settings" }) do
        for _, def in ipairs(ModuleLibrary[cat] or {}) do
            if shown < 30 and string.find(string.lower(def.Name .. " " .. (def.Desc or "")), q, 1, true) then
                shown = shown + 1
                local row = Instance.new("TextButton")
                row.LayoutOrder = shown
                row.Size = UDim2.new(1, -2, 0, 38)
                row.BackgroundColor3 = __Sailennt.Config.CardBG
                row.BackgroundTransparency = 1 - (Settings.Opacity or 0.92)
                row.BorderSizePixel = 0
                row.AutoButtonColor = true
                row.Text = "  [" .. cat .. "] " .. def.Name .. " — " .. tostring(def.Desc or "")
                row.TextColor3 = __Sailennt.Config.TextMain
                row.TextSize = 12
                row.Font = Enum.Font.Gotham
                row.TextXAlignment = Enum.TextXAlignment.Left
                row.TextTruncate = Enum.TextTruncate.AtEnd
                row.ZIndex = 32
                row.Parent = UtilityBody
                __Sailennt.Corner(row, 6)
                row.MouseButton1Click:Connect(function() Activate(def) end)
            end
        end
    end
    if shown == 0 then UtilityRow("Ничего не найдено", 1) end
end

OpenActivityLog = function()
    ShowUtility("Activity Log")
    if #ActivityLog == 0 then
        UtilityRow("Пока нет записанных событий", 1)
        return
    end
    local first = math.max(1, #ActivityLog - 39)
    local order = 0
    for i = #ActivityLog, first, -1 do
        local entry = ActivityLog[i]
        order = order + 1
        UtilityRow("[" .. entry.time .. "] " .. entry.kind .. ": " .. entry.message, order, 38)
    end
end

-- // CARDS
local LoadCategory
local function CreateCard(FuncData, Index)
    -- Cell управляется сеткой, Card внутри свободно анимируется
    local Cell = Instance.new("Frame")
    Cell.Name = FuncData.Name
    Cell.LayoutOrder = Index
    Cell.BackgroundTransparency = 1
    Cell.ClipsDescendants = false
    Cell.Visible = false
    Cell.Parent = FeatureContainer

    local Card = Instance.new("Frame")
    Card.AnchorPoint = Vector2.new(0.5, 0.5)
    Card.Position = REST
    Card.Size = UDim2.new(1, 0, 1, 0)
    Card.Name = "Card"
    Card.BackgroundColor3 = __Sailennt.Config.CardBG
    Card.BorderSizePixel = 0
    Card.ClipsDescendants = false
    Card.Parent = Cell
    __Sailennt.Corner(Card, 7)
    local ClickArea = Instance.new("TextButton")
    ClickArea.Name = "CardClickArea"
    ClickArea.Size = UDim2.fromScale(1, 1)
    ClickArea.BackgroundTransparency = 1
    ClickArea.Text = ""
    ClickArea.AutoButtonColor = false
    ClickArea.ZIndex = 1
    ClickArea.Parent = Card
    local Outline = __Sailennt.Stroke(Card, __Sailennt.Config.Stroke, 1)
    local CScale = Instance.new("UIScale")
    CScale.Parent = Card

    local Gradient = __Sailennt.Grad(Card, Index % 2 == 1 and GradBlue[1] or GradRed[1], Index % 2 == 1 and GradBlue[2] or GradRed[2], 0)
    Gradient:SetAttribute("ThemeSlot", (Index % 2 == 1) and "A" or "B")
    Gradient.Enabled = false

    local NameLabel = __Sailennt.Label(Card, FuncData.Name, 13, __Sailennt.Config.TextMain, Enum.Font.GothamBold, UDim2.new(0, 10, 0, 7), UDim2.new(1, -74, 0, 18))
    NameLabel.ZIndex = 2
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    local Desc = __Sailennt.Label(Card, FuncData.DescFn and FuncData.DescFn() or FuncData.Desc, 10, __Sailennt.Config.TextSub, Enum.Font.Gotham, UDim2.new(0, 10, 0, 27), UDim2.new(1, -20, 0, 16))
    Desc.ZIndex = 2
    Desc.TextTruncate = Enum.TextTruncate.AtEnd

    -- ⚙ открывает настройки (то же — ПКМ по карточке)
    local Gear = Instance.new("TextButton")
    Gear.Size = UDim2.new(0, 22, 0, 22)
    Gear.Position = UDim2.new(1, -26, 0, 4)
    Gear.BackgroundTransparency = 1
    Gear.Text = "..."
    Gear.TextSize = 14
    Gear.Font = Enum.Font.GothamBold
    Gear.TextColor3 = __Sailennt.Config.TextSub
    Gear.ZIndex = 4
    Gear.Parent = Card
    local KeyTag = Instance.new("TextButton")
    KeyTag.Size = UDim2.new(0, 38, 0, 16)
    KeyTag.Position = UDim2.new(1, -68, 0, 7)
    KeyTag.BackgroundColor3 = __Sailennt.Config.SideBG
    KeyTag.BackgroundTransparency = 0.2
    KeyTag.BorderSizePixel = 0
    KeyTag.AutoButtonColor = false
    KeyTag.Font = Enum.Font.GothamMedium
    KeyTag.TextSize = 9
    KeyTag.TextColor3 = __Sailennt.Config.TextSub
    KeyTag.TextTruncate = Enum.TextTruncate.AtEnd
    KeyTag.Visible = not __Sailennt.IsMobile
    KeyTag.ZIndex = 4
    KeyTag.Parent = Card
    __Sailennt.Corner(KeyTag, 5)
    KeyTag.MouseButton1Click:Connect(function() __Sailennt.Ui.QuickBind(FuncData) end)

    -- Одна функция может иметь несколько карточек (категория + Избранное): обновляем все живые
    FuncData._cards = FuncData._cards or {}
    local api = {}
    FuncData._cards[Card] = api
    local function Fan(fn, ...)
        for c, a in pairs(FuncData._cards) do
            if c.Parent then
                if a[fn] then a[fn](...) end
            else
                FuncData._cards[c] = nil
            end
        end
    end
    api.key = function()
        local k = Binds[FuncData.Name]
        KeyTag.Text = k and k.Name or "—"
    end
    api.desc = function()
        if FuncData.DescFn then Desc.Text = FuncData.DescFn() end
    end
    FuncData._refreshKey = function() Fan("key") end
    FuncData._refreshDesc = function() Fan("desc") end
    api.key()

    local FavoriteBtn = Instance.new("TextButton")
    FavoriteBtn.Size = UDim2.fromOffset(20, 20)
    FavoriteBtn.Position = UDim2.new(1, -94, 0, 5)
    FavoriteBtn.BackgroundTransparency = 1
    FavoriteBtn.Text = FavoriteSet[FuncData.Name] and "*" or "+"
    FavoriteBtn.TextColor3 = __Sailennt.Config.Accent
    FavoriteBtn.TextSize = 18
    FavoriteBtn.Font = Enum.Font.GothamBold
    FavoriteBtn.ZIndex = 4
    FavoriteBtn.Parent = Card
    api.fav = function()
        FavoriteBtn.Text = FavoriteSet[FuncData.Name] and "*" or "+"
    end
    FuncData._refreshFavorite = function() Fan("fav") end
    FavoriteBtn.MouseButton1Click:Connect(function()
        if FavoriteSet[FuncData.Name] then
            FavoriteSet[FuncData.Name] = nil
        else
            FavoriteSet[FuncData.Name] = true
        end
        FuncData._refreshFavorite()
        RequestSave()
        if CurrentCategory == "Favorites" then LoadCategory("Favorites") end
    end)

    local Hovering = false
    local ColorTween
    -- Увеличенная карточка должна рисоваться поверх соседних (ZIndexBehavior = Sibling, значит поднимаем Cell)
    local RaiseGen = 0
    local function Raise(on)
        RaiseGen = RaiseGen + 1
        local gen = RaiseGen
        if on then
            Cell.ZIndex = 10
        else
            task.delay(0.4, function()
                if gen == RaiseGen and not Hovering then Cell.ZIndex = 1 end
            end)
        end
    end

    -- Плавное включение: градиент проявляется (BG тёмный -> белый), при выключении гаснет
    local function Visual(animate)
        local On = ActiveCleanups[FuncData.Name] ~= nil
        if ColorTween then ColorTween:Cancel() end
        local goal = On and WHITE or __Sailennt.Config.CardBG
        Outline.Enabled = not On
        if not animate then
            Card.BackgroundColor3 = goal
            Gradient.Enabled = On
            Desc.TextColor3 = On and __Sailennt.Config.TextMain or __Sailennt.Config.TextSub
            return
        end
        if On then Gradient.Enabled = true end
        ColorTween = __Sailennt.TweenService:Create(Card, __Sailennt.TI_Toggle, { BackgroundColor3 = goal })
        ColorTween.Completed:Connect(function(st)
            if st == Enum.PlaybackState.Completed and ActiveCleanups[FuncData.Name] == nil then Gradient.Enabled = false end
        end)
        ColorTween:Play()
        __Sailennt.TweenService:Create(Desc, __Sailennt.TI_Toggle, { TextColor3 = On and __Sailennt.Config.TextMain or __Sailennt.Config.TextSub }):Play()
    end
    api.visual = Visual
    FuncData._visual = function(animate) Fan("visual", animate) end
    Visual(false)

    ClickArea.MouseButton1Click:Connect(function()
        -- «нажатие»: пружинистый возврат масштаба
        Raise(true)
        CScale.Scale = 0.95
        __Sailennt.TweenService:Create(CScale, TI_Press, { Scale = Hovering and 1.015 or 1 }):Play()
        Raise(false)
        Activate(FuncData)
    end)
    ClickArea.MouseButton2Click:Connect(function() OpenPopup(FuncData) end)
    Gear.MouseButton1Click:Connect(function() OpenPopup(FuncData) end)

    Card.MouseEnter:Connect(function()
        Hovering = true
        Raise(true)
        __Sailennt.TweenService:Create(CScale, __Sailennt.TI_Hover, { Scale = 1.015 }):Play()
        if ActiveCleanups[FuncData.Name] == nil then __Sailennt.TweenService:Create(Outline, __Sailennt.TI_Hover, { Color = __Sailennt.Config.Accent }):Play() end
    end)
    Card.MouseLeave:Connect(function()
        Hovering = false
        Raise(false)
        __Sailennt.TweenService:Create(CScale, __Sailennt.TI_Hover, { Scale = 1 }):Play()
        __Sailennt.TweenService:Create(Outline, __Sailennt.TI_Hover, { Color = __Sailennt.Config.Stroke }):Play()
    end)

    return { Cell = Cell, Card = Card, Scale = CScale, Name = FuncData.Name, Lower = string.lower(FuncData.Name .. " " .. (FuncData.Desc or "")) }
end

local function Matches(d, q)
    return q == "" or string.find(d.Lower, q, 1, true) ~= nil
end

-- Каскад: карточки по очереди «выползают» снизу с лёгкой пружиной
local function PlayIntro()
    IntroGen = IntroGen + 1
    local gen = IntroGen
    local q = string.lower(SearchBox.Text)
    if Settings.ReduceMotion then
        for _, d in ipairs(CategoryCells[CurrentCategory] or {}) do
            d.Cell.Visible = Matches(d, q)
            d.Card.Position = REST
            d.Scale.Scale = 1
        end
        return
    end
    local n = 0
    for _, d in ipairs(CategoryCells[CurrentCategory] or {}) do
        if Matches(d, q) then
            n = n + 1
            d.Cell.Visible = false
            d.Card.Position = UDim2.new(0.5, 0, 0.5, 18)
            d.Scale.Scale = 0.9
            task.delay(0.08 + math.min(n - 1, 14) * 0.045, function()
                if gen ~= IntroGen then return end
                d.Cell.Visible = true
                __Sailennt.TweenService:Create(d.Card, TI_Card, { Position = REST }):Play()
                __Sailennt.TweenService:Create(d.Scale, TI_Card, { Scale = 1 }):Play()
            end)
        else
            d.Cell.Visible = false
        end
    end
end

local function ApplySearch()
    if PaletteOn then PaletteRender() return end
    IntroGen = IntroGen + 1 -- отменяет незавершённый каскад
    local q = string.lower(SearchBox.Text)
    for _, d in ipairs(CategoryCells[CurrentCategory] or {}) do
        d.Cell.Visible = Matches(d, q)
        d.Card.Position = REST
        d.Scale.Scale = 1
    end
end
SearchBox:GetPropertyChangedSignal("Text"):Connect(ApplySearch)

-- Ctrl+K / Command Palette uses the existing live module search.
local function OpenCommandPalette()
    SearchBox.Text = ""
    PaletteRender()
    SearchBox:CaptureFocus()
    -- Ctrl+K успевает попасть в TextBox как "k": чистим на следующем кадре
    task.defer(function()
        task.wait()
        if SearchBox:IsFocused() and SearchBox.Text == "k" then SearchBox.Text = "" end
    end)
end


LoadCategory = function(CatName)
    for _, d in ipairs(CategoryCells[CurrentCategory] or {}) do d.Cell.Visible = false end
    if CatName == "Favorites" and CategoryCells.Favorites then
        for _, old in ipairs(CategoryCells.Favorites) do if old.Cell then old.Cell:Destroy() end end
        CategoryCells.Favorites = nil
    end
    CurrentCategory = CatName
    if not CategoryCells[CatName] then
        local cells = {}
        local source = table.clone(ModuleLibrary[CatName] or {}) -- копия: сортировка не должна менять исходный порядок библиотеки
        if CatName == "Favorites" then
            source = {}
            for _, category in ipairs({"Combat", "Movement", "Visuals", "Player", "World", "Misc", "Settings"}) do
                for _, def in ipairs(ModuleLibrary[category] or {}) do
                    if FavoriteSet[def.Name] then source[#source + 1] = def end
                end
            end
            table.sort(source, function(a, b) return a.Name < b.Name end)
        elseif Settings.SortMode == "name" then
            table.sort(source, function(a, b) return a.Name < b.Name end)
        end
        for i, func in ipairs(source) do cells[i] = CreateCard(func, i) end
        CategoryCells[CatName] = cells
    end
    FeatureContainer.CanvasPosition = Vector2.zero
    PlayIntro()
end

SortButton.MouseButton1Click:Connect(function()
    Settings.SortMode = (Settings.SortMode == "name") and "default" or "name"
    SortButton.Text = Settings.SortMode == "name" and "ZA" or "AZ"
    RequestSave()
    local current = CurrentCategory
    if CategoryCells[current] then
        for _, item in ipairs(CategoryCells[current]) do if item.Cell then item.Cell:Destroy() end end
        CategoryCells[current] = nil
    end
    LoadCategory(current)
end)

-- Автовключение сохранённых настроек клиента (Settings-модули)
local function AutoEnable(Name)
    local def = Defs[Name]
    if def and not ActiveCleanups[Name] then SetModule(def, true, true) end
end
for _, def in ipairs(ModuleLibrary["Settings"]) do
    local key = ({ ["Notifications"] = "Notifications", ["Sounds"] = "Sounds", ["Background Blur"] = "Blur", ["Snowfall"] = "Snow",
        ["Auto-Open Menu"] = "AutoOpen", ["Reduce Motion"] = "ReduceMotion", ["Restore Enabled"] = "RestoreState", ["Floating Button"] = "FloatBtn" })[def.Name]
    if key and Settings[key] then AutoEnable(def.Name) end
end

-- // NAVIGATION BUILD (фиксированный порядок, плавающая подсветка вкладки)
do
local NavOrder = {
    -- Иконки только ASCII: Gotham не содержит символов вроде ◎ ➤ ⚙ ★ (они рисуются прямоугольниками)
    { Key = "Combat",   Label = "Combat",   Icon = "CB" },
    { Key = "Movement", Label = "Movement", Icon = "MV" },
    { Key = "Visuals",  Label = "Render",   Icon = "RN" },
    { Key = "Player",   Label = "Player",   Icon = "PL" },
    { Key = "World",    Label = "World",    Icon = "WR" },
    { Key = "Misc",     Label = "Util",     Icon = "UT" },
    { Key = "Settings", Label = "Settings", Icon = "ST" },
    { Key = "Favorites", Label = "Favorites", Icon = "FV" },
}
local NavButtons = {}

local NavHighlight = Instance.new("Frame")
NavHighlight.Size = UDim2.new(1, -20, 0, 32)
NavHighlight.Position = UDim2.new(0, 10, 0, 78)
NavHighlight.BackgroundColor3 = WHITE
NavHighlight.BorderSizePixel = 0
NavHighlight.Visible = false
NavHighlight.Parent = Sidebar
__Sailennt.Corner(NavHighlight, 7)
local NavGrad = __Sailennt.Grad(NavHighlight, GradBlue[1], GradBlue[2], 0)
NavGrad:SetAttribute("ThemeSlot", "A")

local FirstNav = true
local function SelectNav(Key)
    CloseUtility()
    if __Sailennt.Ui.CloseCfg then __Sailennt.Ui.CloseCfg() end
    if __Sailennt.Ui.ClosePopup then __Sailennt.Ui.ClosePopup() end
    local target = NavButtons[Key]
    if not target then return end
    if FirstNav then
        NavHighlight.Position = target.Btn.Position
        NavHighlight.Visible = true
        FirstNav = false
    else
        __Sailennt.TweenService:Create(NavHighlight, TI_Slide, { Position = target.Btn.Position }):Play()
    end
    for k, d in pairs(NavButtons) do
        local col = (k == Key) and __Sailennt.Config.TextMain or __Sailennt.Config.TextSub
        __Sailennt.TweenService:Create(d.Icon, __Sailennt.TI_Hover, { TextColor3 = col }):Play()
        __Sailennt.TweenService:Create(d.Text, __Sailennt.TI_Hover, { TextColor3 = col }):Play()
    end
    if Key ~= CurrentCategory then LoadCategory(Key) end
end

local NavY = 78
for _, item in ipairs(NavOrder) do
    if ModuleLibrary[item.Key] then
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, -20, 0, 32)
        Btn.Position = UDim2.new(0, 10, 0, NavY)
        Btn.BackgroundTransparency = 1
        Btn.BorderSizePixel = 0
        Btn.Text = ""
        Btn.AutoButtonColor = false
        Btn.Parent = Sidebar
        local Icon = __Sailennt.Label(Btn, item.Icon, 11,__Sailennt.Config.TextSub, Enum.Font.GothamBold, UDim2.new(0, 12, 0, 0), UDim2.new(0, 20, 1, 0), Enum.TextXAlignment.Center)
        local Text = __Sailennt.Label(Btn, item.Label, 13, __Sailennt.Config.TextSub, Enum.Font.GothamMedium, UDim2.new(0, 40, 0, 0), UDim2.new(1, -40, 1, 0))
        NavButtons[item.Key] = { Btn = Btn, Icon = Icon, Text = Text }
        Btn.MouseButton1Click:Connect(function() SelectNav(item.Key) end)
        NavY = NavY + 35
    end
end
ApplyLanguage = function()
    local en = Settings.Language == "en"
    local labels = {
        Combat = en and "Combat" or "Бой",
        Movement = en and "Movement" or "Движение",
        Visuals = en and "Visuals" or "Визуал",
        Player = en and "Player" or "Игрок",
        World = en and "World" or "Мир",
        Misc = en and "Tools" or "Утилиты",
        Settings = en and "Settings" or "Настройки",
        Favorites = en and "Favorites" or "Избранное"
    }
    for key, entry in pairs(NavButtons) do
        entry.Text.Text = labels[key] or key
    end
    SearchBox.PlaceholderText = en and "Search modules…" or "Поиск функций…"
    __Sailennt.ThemeNameLabel.Text = (en and "Themes · " or "Темы · ") .. Themes[ThemeIndex].Name
end
ApplyLanguage()
SelectNav(NavOrder[1].Key)
__Sailennt.Ui.Select = SelectNav
end

ApplyTheme(Themes[Settings.Theme] and Settings.Theme or 1)
if ApplyLanguage then ApplyLanguage() end
MainFrame.BackgroundTransparency = 1 - math.clamp(Settings.Opacity or 0.92, 0, 1)
__Sailennt.ConfigsBtn.MouseButton1Click:Connect(function() __Sailennt.Ui.OpenCfg() end)
__Sailennt.Ui.SearchCfg.MouseButton1Click:Connect(function() __Sailennt.Ui.OpenCfg() end)
__Sailennt.Ui.SearchSet.MouseButton1Click:Connect(function() __Sailennt.Ui.Select("Settings") end)
UIHook.After = function()
    ApplyTheme(Themes[Settings.Theme] and Settings.Theme or 1)
    if ApplyLanguage then ApplyLanguage() end
    MainFrame.BackgroundTransparency = 1 - math.clamp(Settings.Opacity or 0.92, 0, 1)
    for _, d in pairs(Defs) do
        if d._refreshKey then d._refreshKey() end
        if d._refreshDesc then d._refreshDesc() end
        if d._refreshFavorite then d._refreshFavorite() end
    end
    ClosePopup()
end
__Sailennt.ThemeBtn.MouseButton1Click:Connect(function()
    if __Sailennt.Ui.CloseCfg then __Sailennt.Ui.CloseCfg() end
    if CloseUtility then CloseUtility() end
    if __Sailennt.Ui.ClosePopup then __Sailennt.Ui.ClosePopup() end
    ApplyTheme(ThemeIndex % #Themes + 1)
end)

-- // DRAG (за сайдбар; MouseMove-подписка живёт только пока тянем)
local RestPos = UDim2.new(0.5, 0, 0.5, 0)
local DragStart, StartPos, DragConn
Sidebar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        DragStart, StartPos = i.Position, MainFrame.Position
        if DragConn then DragConn:Disconnect() end
        DragConn = __Sailennt.UserInputService.InputChanged:Connect(function(ii)
            if ii.UserInputType == Enum.UserInputType.MouseMovement or ii.UserInputType == Enum.UserInputType.Touch then
                local d = ii.Position - DragStart
                MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + d.X, StartPos.Y.Scale, StartPos.Y.Offset + d.Y)
            end
        end)
    end
end)
Conns[#Conns + 1] = __Sailennt.UserInputService.InputEnded:Connect(function(i)
    if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and DragConn then
        DragConn:Disconnect()
        DragConn = nil
        RestPos = MainFrame.Position
    end
end)

-- // BACKGROUND BLUR
local Blur = Instance.new("BlurEffect")
Blur.Name = "SailenntBlur"
Blur.Size = 0
Blur.Parent = __Sailennt.Lighting

-- // SNOW (60 хлопьев; обновление только пока меню открыто или гаснет)
local SnowLayer = Instance.new("Frame")
SnowLayer.Name = "Snow"
SnowLayer.Size = UDim2.new(1, 0, 1, 0)
SnowLayer.BackgroundTransparency = 1
SnowLayer.BorderSizePixel = 0
SnowLayer.ClipsDescendants = true
SnowLayer.Visible = false
SnowLayer.ZIndex = 1
SnowLayer.Parent = ScreenGui

local Flakes = {}
do
local SNOW_COUNT = 30
for i = 1, SNOW_COUNT do
    local F = Instance.new("Frame")
    F.BackgroundColor3 = WHITE
    F.BorderSizePixel = 0
    F.ZIndex = 1
    F.Parent = SnowLayer
    local d = {
        Frame = F, X = math.random(), Y = math.random(), Size = math.random(2, 5),
        Speed = math.random(6, 18) / 100, Sway = math.random(5, 15) / 1000,
        Freq = math.random(5, 20) / 10, Phase = math.random() * 6.28, Op = math.random(5, 9) / 10,
    }
    F.Size = UDim2.fromOffset(d.Size, d.Size)
    if d.Size > 3 then __Sailennt.Corner(F, 8) end
    Flakes[i] = d
end

end
local SnowAlpha, SnowTarget, SnowConn, SnowTime, LastAlpha = 0, 0, nil, 0, -1
local function SetSnow(on)
    SnowTarget = on and 1 or 0
    if on then SnowLayer.Visible = true end
    if SnowConn then return end
    SnowConn = __Sailennt.RunService.RenderStepped:Connect(function(dt)
        SnowTime = SnowTime + dt
        SnowAlpha = SnowAlpha + (SnowTarget - SnowAlpha) * math.min(1, dt * 4)
        local changed = math.abs(SnowAlpha - LastAlpha) > 0.004
        LastAlpha = SnowAlpha
        for _, d in ipairs(Flakes) do
            d.Y = d.Y + d.Speed * dt
            if d.Y > 1.02 then
                d.Y = -0.02
                d.X = math.random()
            end
            d.Frame.Position = UDim2.new(d.X + math.sin(SnowTime * d.Freq + d.Phase) * d.Sway, 0, d.Y, 0)
            if changed then d.Frame.BackgroundTransparency = 1 - SnowAlpha * d.Op end
        end
        if SnowTarget == 0 and SnowAlpha < 0.02 then
            SnowConn:Disconnect()
            SnowConn = nil
            LastAlpha = -1
            SnowLayer.Visible = false
        end
    end)
end

-- // MAIN TOGGLE: окно «выползает» снизу с пружиной, при закрытии проваливается обратно
local CloseTween

local UserScale = 1
local function FitScale()
    local cam = __Sailennt.Workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local fit = math.max(0.45, math.min((vp.X - 24) / 680, (vp.Y - 24) / 480))
    local base = math.min(fit, 1)
    return math.clamp(math.min(base * UserScale, fit), 0.45, 1.15)
end
local function ChangeScale(delta)
    UserScale = math.clamp(UserScale + delta, 0.75, 1.15)
    if IsOpen then
        __Sailennt.TweenService:Create(MenuScale, __Sailennt.TI_Hover, { Scale = FitScale() }):Play()
    end
end
ScaleDown.MouseButton1Click:Connect(function() ChangeScale(-0.05) end)
ScaleUp.MouseButton1Click:Connect(function() ChangeScale(0.05) end)
do
    local function Watch()
        local cam = __Sailennt.Workspace.CurrentCamera
        if cam then
            Conns[#Conns + 1] = cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                if IsOpen then MenuScale.Scale = FitScale() end
            end)
        end
    end
    Watch()
    Conns[#Conns + 1] = __Sailennt.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(Watch)
end

ApplySetting = function(key)
    if key == "FloatBtn" and __Sailennt.Ui.Float then __Sailennt.Ui.FloatVisible(Settings.FloatBtn) end
    if not IsOpen then return end
    if key == "Blur" then __Sailennt.TweenService:Create(Blur, TI_Blur, { Size = Settings.Blur and 18 or 0 }):Play() end
    if key == "Snow" then SetSnow(Settings.Snow) end
end

local function SetOpen(state)
    IsOpen = state
    if CloseTween then CloseTween:Cancel() CloseTween = nil end
    if IsOpen then
        MainFrame.Visible = true
        MainFrame.Position = RestPos + UDim2.fromOffset(0, 40)
        MenuScale.Scale = 0.85 * FitScale()
        __Sailennt.TweenService:Create(MainFrame, TI_Fade, { GroupTransparency = 0, Position = RestPos }):Play()
        __Sailennt.TweenService:Create(MenuScale, TI_Pop, { Scale = FitScale() }):Play()
        __Sailennt.TweenService:Create(Blur, TI_Blur, { Size = Settings.Blur and 18 or 0 }):Play()
        SetSnow(Settings.Snow)
        PlayIntro()
    else
        ClosePopup()
        __Sailennt.Ui.CloseCfg()
        local t = __Sailennt.TweenService:Create(MainFrame, __Sailennt.TI_Close, { GroupTransparency = 1, Position = RestPos + UDim2.fromOffset(0, 24) })
        CloseTween = t
        t.Completed:Connect(function(st)
            if st == Enum.PlaybackState.Completed then MainFrame.Visible = false end
        end)
        t:Play()
        __Sailennt.TweenService:Create(MenuScale, __Sailennt.TI_Close, { Scale = 0.9 * FitScale() }):Play()
        __Sailennt.TweenService:Create(Blur, TI_Blur, { Size = 0 }):Play()
        SetSnow(false)
    end
end

__Sailennt.Ui.Toggle = function() SetOpen(not IsOpen) end
ExitBtn.MouseButton1Click:Connect(function() SetOpen(false) end)

-- // ПЛАВАЮЩАЯ КНОПКА (телефон): тап открывает меню, перетаскивается пальцем
do
    local Btn = Instance.new("TextButton")
    Btn.Name = "Float"
    Btn.Size = UDim2.new(0, 46, 0, 46)
    Btn.Position = UDim2.new(0, 14, 0.35, 0)
    Btn.BackgroundColor3 = __Sailennt.Config.CardBG
    Btn.Text = "S"
    Btn.TextSize = 20
    Btn.Font = Enum.Font.GothamBold
    Btn.TextColor3 = WHITE
    Btn.AutoButtonColor = false
    Btn.ZIndex = 50
    Btn.Visible = Settings.FloatBtn
    Btn.Parent = ScreenGui
    __Sailennt.Corner(Btn, 23)
    __Sailennt.Stroke(Btn, __Sailennt.Config.Accent, 2)
    local dragging, moved, sIn, sPos = false, false, nil, nil
    local function isPtr(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
    Btn.InputBegan:Connect(function(i)
        if isPtr(i) then
            dragging, moved, sIn, sPos = true, false, i.Position, Btn.Position
        end
    end)
    Conns[#Conns + 1] = __Sailennt.UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - sIn
            if d.Magnitude > 8 then moved = true end
            if moved then Btn.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y) end
        end
    end)
    Conns[#Conns + 1] = __Sailennt.UserInputService.InputEnded:Connect(function(i)
        if dragging and isPtr(i) then
            dragging = false
            if not moved then __Sailennt.Ui.Toggle() end
        end
    end)
    __Sailennt.Ui.Float = Btn
    __Sailennt.Ui.FloatVisible = function(v) Btn.Visible = v and true or false end
end

-- // INPUT: назначение клавиши, меню, выгрузка, горячие клавиши модулей
Conns[#Conns + 1] = __Sailennt.UserInputService.InputBegan:Connect(function(input, gp)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local key = input.KeyCode
    if __Sailennt.BindCaptureActive and __Sailennt.BindCaptureActive() then
        __Sailennt.CaptureBindKey(key)
        return
    end
    if gp then return end
    if key == Enum.KeyCode.K and (__Sailennt.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or __Sailennt.UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then OpenCommandPalette() return end
    if __Sailennt.UserInputService:GetFocusedTextBox() then return end
    if key == __Sailennt.Config.ToggleKey then SetOpen(not IsOpen) return end
    if key == __Sailennt.Config.UnloadKey then UnloadClient() return end
    local name = BindOwner[key]
    local def = name and Defs[name]
    if def then Activate(def) end
end)

-- // UNLOAD: полная выгрузка клиента (модули, подключения, GUI, блюр, Drawing)
UnloadClient = function()
    if Unloading then return end
    SaveConfig() -- сохраняем состояние до начала остановки модулей
    Unloading = true
    AddActivity("Lifecycle", "Выгрузка клиента начата")
    for name in pairs(table.clone(ActiveCleanups)) do
        local ok, err = pcall(StopModule, name)
        if not ok then warn("[Sailennt] unload module " .. tostring(name) .. ": " .. tostring(err)) end
    end
    for name in pairs(table.clone(ActiveLoops)) do pcall(LoopRemove, name) end
    for _, S in pairs(Steps) do pcall(StepDisconnect, S) end
    for d in pairs(table.clone(Drawings)) do pcall(KillDraw, d) end
    for k in pairs(Hook.On) do Hook.On[k] = nil end
    Hook.Count = 0 -- установленный executor-hook остаётся пассивным до завершения сессии
    do
        local H = __Sailennt.Env.SailenntNc
        if H and H.Old then H.Dispatch = function(self, ...) return H.Old(self, ...) end end
    end
    for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
    table.clear(Conns)
    if SnowConn then pcall(function() SnowConn:Disconnect() end) SnowConn = nil end
    if DragConn then pcall(function() DragConn:Disconnect() end) DragConn = nil end
    if EnableSound then pcall(function() EnableSound:Destroy() end) EnableSound = nil end
    if Blur then pcall(function() Blur:Destroy() end) end
    if UtilityPanel then pcall(function() UtilityPanel:Destroy() end) end
    if ScreenGui then pcall(function() ScreenGui:Destroy() end) end
    if __Sailennt.Env.SailenntUnload == UnloadClient then __Sailennt.Env.SailenntUnload = nil end
    AddActivity("Lifecycle", "Выгрузка клиента завершена")
end

-- Включить функции, что были включены в прошлый раз (если включено в Settings)
if Settings.RestoreState then
    for _, name in ipairs(Saved.Enabled) do
        local def = Defs[name]
        if def and not def.OneShot and def.Cat ~= "Settings" then
            local ok = pcall(SetModule, def, true, true)
            if not ok then Log("Restore: " .. tostring(name) .. " не удалось включить") end
        end
    end
end

-- Автозагрузка профиля (если выбран в Configs)
Profiles.LoadIndex()
if Profiles.Index.autoload ~= "" then
    local ok, err = Profiles.Load(Profiles.Index.autoload)
    Notify("Configs", ok, ok and ("Автозагрузка: " .. Profiles.Index.autoload) or tostring(err))
end
UIHook.State()
if Settings.AutoOpen then SetOpen(true) end
__Sailennt.Env.SailenntUnload = UnloadClient

do local Count = 0
for _, list in pairs(ModuleLibrary) do Count = Count + #list end
print("Sailennt v5.2 Full Update Loaded. Modules initialized: " .. Count .. " | " .. X.name) end
if not Hook.Installed and not (hookmetamethod and getnamecallmethod) then Log("namecall hook недоступен: Silent Aim / Anti-Kick / Anti-Teleport / Remote Spy отключены") end
if not X.draw then Log("Drawing недоступен: ESP Boxes/Names/Health/Distance/Tracers отключены, Chams и Full ESP Info работают") end
