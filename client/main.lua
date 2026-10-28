-- client/main.lua — runs the tour in client/steps.lua.
--
-- First join: once the player is in the world and idle, the tour opens on its
-- own. Finishing or leaving it is remembered on this PC (resource KVP), and
-- /tutorial (or the pause menu tile) plays it again.
--
-- Input: the tour page holds NUI focus the whole time, re-taken after each
-- screen it opens, so Enter / Backspace / arrows / Esc and the card's buttons
-- always reach it while the opened screen stays visible underneath.

local KVP_DONE = "spz_tutorial_done_v1"

local active  = false
local idx     = 1
local closeFn = nil
local token   = 0      -- bumps on every step, so stale focus timers do nothing

-- ── Keys ─────────────────────────────────────────────────────────────────────

local function keyFor(cmd, def)
    if def == nil or def == "" then return cmd end   -- [[E]] → literal key
    local ok, k = pcall(function() return exports["spz-core"]:KeyFor(cmd, def) end)
    return (ok and k and k ~= "") and k or def
end

local function render(text)
    return (text:gsub("%[%[([^%]|]+)|?([^%]]*)%]%]", function(a, b)
        return "<kbd>" .. keyFor(a, b) .. "</kbd>"
    end))
end

-- ── Theme ────────────────────────────────────────────────────────────────────

local function pushTheme(theme)
    if theme and next(theme) then SendNUIMessage({ action = "theme", theme = theme }) end
end
AddEventHandler("SPZ:themeUpdated", pushTheme)

-- ── Steps ────────────────────────────────────────────────────────────────────

local function available(s)
    return not s.needs or GetResourceState(s.needs) == "started"
end

local function leaveStep()
    if closeFn then
        local fn = closeFn
        closeFn = nil
        pcall(fn)
    end
end

local function takeFocus(t)
    if active and t == token then
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    end
end

local function visibleCount()
    local n, pos = 0, 0
    for i, s in ipairs(TourSteps) do
        if available(s) then
            n = n + 1
            if i == idx then pos = n end
        end
    end
    return n, pos
end

local function showStep(i, dir)
    leaveStep()
    dir = dir or 1
    while TourSteps[i] and not available(TourSteps[i]) do i = i + dir end
    if not TourSteps[i] then
        i = dir > 0 and #TourSteps or 1
    end
    idx = i
    token = token + 1
    local t, s = token, TourSteps[idx]

    closeFn = s.close
    if s.open then
        CreateThread(function()
            -- Several screens refuse to open while ANY page holds NUI focus
            -- (ox_lib's radial, for one), so let go for a moment first.
            SetNuiFocus(false, false)
            Wait(80)
            if not active or t ~= token then return end
            -- Own thread: some openers block until their screen closes.
            CreateThread(function()
                local ok, err = pcall(s.open)
                if not ok then print(("[spz-tutorial] step %d open failed: %s"):format(idx, tostring(err))) end
            end)
            -- The screen just opened takes focus for itself; take it back so the
            -- tour keeps the keyboard and the card stays clickable.
            for _, ms in ipairs({ 250, 600, 1200 }) do SetTimeout(ms, function() takeFocus(t) end) end

            -- A screen that can tell us it is up (s.isOpen) gets one more try if
            -- the focus hand-off closed it.
            if s.isOpen then
                Wait(1400)
                if active and t == token then
                    local ok, up = pcall(s.isOpen)
                    if ok and not up then
                        CreateThread(function() pcall(s.open) end)
                        SetTimeout(300, function() takeFocus(t) end)
                    end
                end
            end
        end)
    else
        takeFocus(t)
    end

    local total, pos = visibleCount()
    SendNUIMessage({
        action = "step",
        step = {
            section = s.section, title = s.title, body = render(s.body or ""),
            spot = (type(s.spot) == "function") and s.spot() or s.spot,
            dim = s.dim ~= false, card = s.card or "auto",
            welcome = s.welcome == true, finale = s.finale == true,
            index = pos, total = total,
        },
    })
end

local function markDone() SetResourceKvpInt(KVP_DONE, 1) end

local function stopTour()
    if not active then return end
    leaveStep()
    active = false
    token = token + 1
    markDone()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "hide" })
    TriggerEvent("spz-tutorial:finished")
end

local function canStart()
    local st = LocalPlayer.state
    if st.inRace or st.inQueue or st.inMinigame or st.mgRoom or st.inTimeTrial or st.spawnMenuOpen then return false end
    if IsPauseMenuActive() then return false end
    return true
end

local function startTour()
    if active then return end
    if not canStart() then
        lib.notify({ title = "Tutorial", description = "Finish what you're doing first (race, queue or minigame).", type = "error" })
        return
    end
    active = true
    local ok, theme = pcall(function() return exports["spz-core"]:GetTheme() end)
    if ok then pushTheme(theme) end
    showStep(1, 1)
end

-- ── NUI ──────────────────────────────────────────────────────────────────────

RegisterNUICallback("next", function(_, cb)
    cb(1)
    if not active then return end
    local last = idx
    for i = idx + 1, #TourSteps do
        if available(TourSteps[i]) then last = i break end
    end
    if last == idx then stopTour() else showStep(last, 1) end
end)

RegisterNUICallback("back", function(_, cb)
    cb(1)
    if not active then return end
    for i = idx - 1, 1, -1 do
        if available(TourSteps[i]) then showStep(i, -1) return end
    end
end)

RegisterNUICallback("exit", function(_, cb)
    cb(1)
    stopTour()
end)

-- ── Entry points ─────────────────────────────────────────────────────────────

RegisterCommand("tutorial", function() startTour() end, false)
TriggerEvent("chat:addSuggestion", "/tutorial", "Replay the server tour")
exports("Start", startTour)
exports("IsActive", function() return active end)

-- Something pulled the player into a race / minigame mid-tour: get out of the way.
CreateThread(function()
    while true do
        Wait(1000)
        if active then
            local st = LocalPlayer.state
            if st.inRace or st.inMinigame or st.spawnMenuOpen then stopTour() end
        end
    end
end)

AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() and active then
        leaveStep()
        SetNuiFocus(false, false)
    end
end)

-- First join: start as soon as the player is in the world with nothing else on
-- screen. It used to also need them standing still for 6s in a row, and any
-- movement restarted the count, so new players who drove off right away got
-- the tour minutes late. Now ~1.5s of ready is enough, moving or not.
CreateThread(function()
    if GetResourceKvpInt(KVP_DONE) == 1 then return end
    local calm = 0
    while calm < 3 do
        Wait(500)
        local st = LocalPlayer.state
        local ready = st.spawned ~= false and not st.spawnMenuOpen
            and NetworkIsPlayerActive(PlayerId()) and IsScreenFadedIn()
            and not IsNuiFocused() and not IsPlayerSwitchInProgress()
            and canStart()
        calm = ready and (calm + 1) or 0
    end
    if GetResourceKvpInt(KVP_DONE) ~= 1 then startTour() end
end)
