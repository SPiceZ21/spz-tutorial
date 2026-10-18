-- client/steps.lua — the tour, in order.
--
-- Each step:
--   section  chip above the title
--   title    / body   body is HTML; [[cmd|DEFAULT]] prints the player's live key
--                     for that command, [[E]] prints a literal key
--   spot     the area to light up, in CSS terms: left/right/top/bottom/width/
--            height as px numbers or "Nvw"/"Nvh" strings; cx = centred
--            horizontally. nil = no cut-out.
--   dim      false = no dim at all (a full-screen UI is the subject)
--   card     where the text card sits: auto (next to the spot), center,
--            tl / tr / bl / br, top, bottom, left, right
--   needs    resource that must be started, or the step is skipped
--   open     shows the UI / demo; close takes it down again (also called when
--            the tour is left from this step)

local function Run(cmd) return function() ExecuteCommand(cmd) end end
local function CloseUIs() TriggerEvent("spz-tutorial:closeUI") end
local function me() return GetPlayerServerId(PlayerId()) end
local function myName()
    local st = LocalPlayer.state
    return st['spz:name'] or st.username or GetPlayerName(PlayerId()) or "YOU"
end

local MINIMAP = { left = "1.5vw", bottom = "2vh", width = "14.1vw", height = "17.6vh" }

TourSteps = {
    -- ── Welcome ──────────────────────────────────────────────────────────────
    {
        section = "Welcome", card = "center", welcome = true,
        title = "Welcome to SPiceZ Racing",
        body = [==[This quick tour opens every screen on the server, lights up where it lives and tells you what it does.<br><br>
<b>Enter</b> / <b>→</b> next &nbsp;·&nbsp; <b>Backspace</b> / <b>←</b> back &nbsp;·&nbsp; <b>Esc</b> leave the tour<br><br>
You can replay it any time with <b>/tutorial</b> or from the pause menu.]==],
    },

    -- ── Freeroam HUD ─────────────────────────────────────────────────────────
    {
        section = "Freeroam", title = "Minimap",
        spot = MINIMAP,
        body = [==[Your map. Race starts, minigame spots, the hub and speed cameras are all blipped here.<br>
Open the full map from the pause menu (<b>Esc</b> → Map) to set a waypoint.]==],
    },
    {
        section = "Freeroam", title = "Join a race — anywhere", needs = "spz-raceUI",
        spot = { cx = true, bottom = "3.5vh", width = 300, height = 52, zoom = 1.1 },
        body = [==[This pill is the race queue. Press [[E]] from anywhere to join the next race and [[E]] again to leave.<br><br>
The first joiner starts a short countdown, then everyone in the queue votes. Missed it? Pressing [[E]] during the <b>warmup</b> still gets you a grid slot.<br>
Joining a minigame takes you out of the queue automatically.]==],
    },
    {
        section = "Freeroam", title = "Notifications",
        -- Follows the real toast anchor (ox_lib reads the same convar).
        spot = function()
            local pos = GetConvar("spz_notify_position", "center-right")
            local w, h = 440, "34vh"
            local zone = {
                -- middle anchors stack upward from the screen's centre line
                ["center-right"] = { right = 10, top = "18vh" },
                ["center-left"]  = { left = 10,  top = "18vh" },
                ["top-right"]    = { right = 10, top = 10 },
                ["top-left"]     = { left = 10,  top = 10 },
                ["top"]          = { cx = true,  top = 10 },
                ["top-center"]   = { cx = true,  top = 10 },
                ["bottom-right"] = { right = 10, bottom = 10 },
                ["bottom-left"]  = { left = 10,  bottom = 10 },
                ["bottom"]       = { cx = true,  bottom = 10 },
                ["bottom-center"]= { cx = true,  bottom = 10 },
            }
            local z = zone[pos] or zone["center-right"]
            z.width, z.height = w, h
            return z
        end,
        open = function()
            lib.notify({ title = "Like this", description = "Rewards, invites and race news show up here.", type = "success", duration = 8000 })
        end,
        body = [==[Messages from the server pop up here: credits and XP you earn, minigame invites, race results and warnings.]==],
    },
    {
        section = "Freeroam", title = "Chat", needs = "spz-chat",
        spot = { left = "16.1vw", bottom = "3vh", width = 460, height = "34vh" },
        open = Run("spz_chat_open"), close = CloseUIs, card = "right",
        body = [==[Press [[spz_chat_open|T]] to talk.<br>
<b>/c</b> message → your crew &nbsp;·&nbsp; <b>/w name</b> message → whisper<br>
Type <b>/</b> to see every command with hints. Orange <b>TIP</b> lines are server tips, and <b>/help</b> lists every feature.]==],
    },
    {
        section = "Freeroam", title = "Speedometer", needs = "spz-speedometer",
        spot = { right = "0.8vw", bottom = "2.5vh", width = "23vw", height = "23vw" },
        open = function() exports["spz-speedometer"]:Demo(true) end,
        close = function() exports["spz-speedometer"]:Demo(false) end,
        body = [==[Shows up whenever you drive: speed, gear and the rev needle. The numbers grow as the needle nears them, so you can read it at a glance.<br>
In a race it also shows your rewind charge.]==],
    },
    {
        section = "Freeroam", title = "Nametags", needs = "spz-nametag", card = "center",
        body = [==[Players carry a nametag with their name, crew and rank. Press [[togglenametags|F10]] to hide or show them.]==],
    },

    -- ── Menus ────────────────────────────────────────────────────────────────
    {
        section = "Menus", title = "Pause menu", needs = "spz-pausemenu", dim = false, card = "br",
        open = function() exports["spz-pausemenu"]:Open() end,
        close = function() exports["spz-pausemenu"]:Close(true) end,
        body = [==[<b>Esc</b> opens this. Map, teleport to the hub, leave the queue / race / minigame, settings and quick tiles for the car spawner, leaderboard, crew and your character.]==],
    },
    {
        section = "Menus", title = "Quick menu",
        spot = { cx = true, cy = true, width = "46vh", height = "46vh" }, card = "right",
        open = function() lib.showRadialMenu() end,
        close = function() lib.hideRadial() end,
        body = [==[Hold [[Z]] for the radial menu: <b>Racing</b> (join, last checkpoint, flip, standings, raceline, spectate), <b>Minigames</b>, <b>Vehicle</b> (spawn, repair, tune, customs, save build), <b>Appearance</b>, <b>Leaderboard</b> and <b>Crew</b>.]==],
    },
    {
        section = "Menus", title = "Car spawner", needs = "spz-carspawner", dim = false, card = "br",
        open = Run("car"), close = CloseUIs,
        body = [==[[[car|F5]] opens the garage. Search by name, filter by class and spawn any car — add-on cars included. Free roam only.]==],
    },
    {
        section = "Menus", title = "Tuning & customs", needs = "spz-tunners", card = "center",
        body = [==[Type <b>/tune</b> (or <b>/customs</b>) while driving to change engine, brakes, suspension, paint, wheels and more. Your build saves to the car.<br><br>
In a race warmup press [[spz_warmuptune|Y]] to tune your race car before the lights go out.]==],
    },
    {
        section = "Menus", title = "Leaderboard", needs = "spz-leaderboard", dim = false, card = "br",
        open = Run("leaderboard"), close = CloseUIs,
        body = [==[[[leaderboard|F6]] opens results and rankings: your last race, track records, driver ratings and season standings.]==],
    },
    {
        section = "Menus", title = "Crew", needs = "spz-crew", dim = false, card = "br",
        open = Run("crew"), close = CloseUIs,
        body = [==[<b>/crew</b> opens the crew dashboard: create or join a crew, see members, and get a crew tag next to your name.<br>
<b>/crewradio</b> toggles crew voice, <b>/c</b> is crew chat.]==],
    },
    {
        section = "Menus", title = "Speed cameras", needs = "spz-speedcam", dim = false, card = "br",
        open = Run("speedrecords"), close = CloseUIs,
        body = [==[Speed traps sit around the map and record how fast you pass. [[speedrecords|F7]] shows the records — beat them for bragging rights.]==],
    },
    {
        section = "Menus", title = "Racing line & ghost", needs = "spz-raceline",
        spot = { right = "25vw", top = "11vh", width = 330, height = 260 }, card = "left",
        open = Run("racelinepanel"), close = function() lib.hideContext(false) end,
        isOpen = function() return lib.getOpenContextMenu() ~= nil end,
        body = [==[[[racelinepanel|F3]] opens the raceline panel: draw the ideal line on the road and race a ghost of your best lap, the track record or a pace car.]==],
    },
    {
        section = "Menus", title = "Replays", needs = "spz-replay", dim = false, card = "br",
        open = Run("replays"), close = CloseUIs,
        body = [==[<b>/replays</b> lists recorded races. Watch from any driver: <b>Space</b> play, <b>←/→</b> seek, <b>Q/E</b> change driver, <b>C</b> camera, <b>H</b> hide UI, <b>Backspace</b> exit.]==],
    },

    -- ── Racing ───────────────────────────────────────────────────────────────
    {
        section = "Racing", title = "The vote", needs = "spz-poll", dim = false, card = "top",
        open = function()
            exports["spz-poll"]:StartPoll({
                phase = "track", timer = 30, duration = 30, step = 1, steps = 3,
                reroll = { enabled = false },
                options = {
                    { label = "Downtown Grand Prix", type = "circuit", laps = 3, checkpointCount = 18 },
                    { label = "Vinewood Hills Sprint", type = "sprint", laps = 1, checkpointCount = 24 },
                    { label = "Reroll", reroll = true, subtext = "None of these tracks" },
                },
            })
        end,
        close = function() exports["spz-poll"]:StopPoll() end,
        body = [==[When a race starts everyone votes: <b>track</b>, then <b>car</b> (with photos), then <b>traffic</b> and police. Don't like the choice? Vote <b>Reroll</b> for a new set, as many times as you like.<br>
<i>This is a demo, nothing is sent.</i>]==],
    },
    {
        section = "Racing", title = "Warmup", needs = "spz-raceUI",
        spot = { cx = true, top = 20, width = 640, height = 125, zoom = 1.1 },
        open = function()
            exports["spz-raceUI"]:ShowWarmup({ remaining = 45, total = 60, track = "DOWNTOWN GRAND PRIX", class = "A", gridPos = 3, tuneKey = "Y" })
        end,
        close = function() exports["spz-raceUI"]:HideWarmup() end,
        body = [==[Before the start you get free laps to learn the track. Press [[spz_warmuptune|Y]] to tune your car. When the timer ends everyone goes back to the grid for the 3-2-1.]==],
    },
    {
        section = "Racing", title = "Standings", needs = "spz-raceUI",
        spot = { left = 24, top = 24, width = 310, height = 250, zoom = 1.1 },
        open = function()
            local you = me()
            exports["spz-raceUI"]:SetRaceOverlayVisible(true)
            exports["spz-raceUI"]:UpdateRaceOverlay({
                lapNum = 2, totalLaps = 3, checkpoint = 12, totalCheckpoints = 24,
                bestLapTime = 72450, allTimeBest = 71200, mySource = you,
                positions = {
                    { source = -101, name = "DRIFT_KING",  position = 1, gap = "LEADER", licenseClass = "S", nation = "jp", raceNumber = 7 },
                    { source = you,  name = myName(),      position = 2, gap = "+1.25", gapMs = 1250, licenseClass = "B", raceNumber = 21 },
                    { source = -102, name = "SHADOW_GRID", position = 3, gap = "+3.42", gapMs = 3420, licenseClass = "A", nation = "de", raceNumber = 44 },
                    { source = -103, name = "APEX_HUNTER", position = 4, gap = "+5.10", gapMs = 5100, licenseClass = "A", nation = "fr", raceNumber = 88 },
                },
            })
        end,
        close = function() exports["spz-raceUI"]:HideAll() end,
        body = [==[Live positions with the gap to the car ahead. You are highlighted. Press [[standingstoggle|N]] to hide or show the list. The keys under it are your race controls.]==],
    },
    {
        section = "Racing", title = "Lap, position & timing", needs = "spz-raceUI",
        spot = { right = 24, top = 24, width = 420, height = 140, zoom = 1.1 }, card = "left",
        open = function()
            exports["spz-raceUI"]:SetRaceOverlayVisible(true)
            exports["spz-raceUI"]:UpdateRaceOverlay({ lapNum = 2, totalLaps = 3, checkpoint = 12, totalCheckpoints = 24, bestLapTime = 72450, allTimeBest = 71200 })
        end,
        close = function() exports["spz-raceUI"]:HideAll() end,
        body = [==[Your lap, place, lap clock, sectors (purple = fastest of anyone, green = your best) and the checkpoint counter. Drive through the floating gates in order.]==],
    },
    {
        section = "Racing", title = "Race keys", card = "center",
        body = [==[[[spz_respawn_cp|F4]] back to your last checkpoint<br>
[[spz_flip_car|K]] flip your car upright<br>
[[B]] hold to rewind a few seconds (limited charge)<br>
[[standingstoggle|N]] standings on / off<br>
[[raceboard|F9]] race board size &nbsp;·&nbsp; [[raceboard_hide|F11]] hide it<br><br>
Leaving mid-race (pause menu → Leave race) counts as a DNF.]==],
    },
    {
        section = "Racing", title = "Results, XP & rank", card = "center",
        body = [==[Finishing earns <b>credits</b>, <b>XP</b> and rating. The results card shows your time, best lap and rank progress — press [[leaderboard|F6]] for the full results.<br>
Clean racing raises your safety rating; contact and DNFs lower it.]==],
    },
    {
        section = "Racing", title = "Practice & 1v1", card = "center",
        body = [==[<b>/timetrail</b> — solo laps on any track, [[tt_restart|BACKSPACE]] restarts, <b>/quittt</b> stops.<br>
<b>/duel player track stake</b> — challenge someone 1v1 for credits.<br>
<b>/rival</b> — see your rival.<br>
<b>/spectate</b> — watch a race that is running.]==],
    },

    -- ── Minigames ────────────────────────────────────────────────────────────
    {
        section = "Minigames", title = "Minigame hub", needs = "spz-minigames", dim = false, card = "br",
        open = function() exports["spz-minigames"]:OpenHub() end, close = CloseUIs,
        body = [==[[[minigames|M]] opens the hub: <b>Bomb Tag</b>, <b>Demolition</b>, <b>Color Rush</b>, <b>Cyclone</b>, <b>Escalation</b>, <b>Rocket League</b>, <b>Hot Pursuit</b> and <b>Hide &amp; Seek</b>.<br>
Pick a game to see its rooms and rules.]==],
    },
    {
        section = "Minigames", title = "Rooms & invites", card = "center",
        body = [==[<b>Create</b> a room (public or invite-only) or <b>join</b> one. Invite friends from the list — people who are busy in another game or a race aren't shown.<br>
The host presses <b>Start</b>. Most games are free to join and pay out credits for winning.<br>
Leave any time from the pause menu.]==],
    },

    -- ── Driving ──────────────────────────────────────────────────────────────
    {
        section = "Driving", title = "Car controls", card = "center",
        body = [==[[[vehfunc_leftSignal|LEFT]] / [[vehfunc_rightSignal|RIGHT]] indicators &nbsp;·&nbsp; [[vehfunc_hazards|J]] hazards<br>
[[+vehfunc_flashHeadlights|L]] flash headlights &nbsp;·&nbsp; [[H]] headlights<br>
[[taunt_horn|G]] horn taunt &nbsp;·&nbsp; <b>/fix</b> repair (free roam)]==],
    },
    {
        section = "Driving", title = "Gearbox & grip", needs = "spz-physics", card = "center",
        body = [==[Manual gears: [[physshiftup|LSHIFT]] up, [[physshiftdown|LCONTROL]] down, hold [[+physclutch|LMENU]] for clutch.<br>
<b>/transmode</b> switch auto / manual &nbsp;·&nbsp; <b>/tcs</b> traction control &nbsp;·&nbsp; <b>/tires</b> tyre compound &nbsp;·&nbsp; <b>/pp</b> your car's performance rating.]==],
    },

    -- ── You ──────────────────────────────────────────────────────────────────
    {
        section = "You", title = "Character & emotes", card = "center",
        body = [==[<b>/appearance</b> edit your driver &nbsp;·&nbsp; <b>/saveoutfit</b> keep it &nbsp;·&nbsp; <b>/resetoutfit</b> undo<br>
<b>/emote</b> name plays an emote.]==],
    },
    {
        section = "You", title = "Your keys, your way", card = "center",
        body = [==[Every key on this server can be changed: <b>Esc → Settings → Key Bindings → FiveM</b>. Hints on screen follow your bindings.]==],
    },

    -- ── Done ─────────────────────────────────────────────────────────────────
    {
        section = "Done", title = "You're ready", card = "center", finale = true,
        body = [==[Press [[E]] to join your first race, or [[minigames|M]] for a minigame.<br><br>
Forgot something? <b>/help</b> lists everything, and <b>/tutorial</b> replays this tour.]==],
    },
}
