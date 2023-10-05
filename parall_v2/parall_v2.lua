local ui_menu_size,renderer_rectangle,ui_menu_position,ui_mouse_position = ui.menu_size,renderer.rectangle,ui.menu_position,ui.mouse_position
local anti_aim_funcs = require ("gamesense/antiaim_funcs") or error("Failed to retrieve antiaim_funcs | https://gamesense.pub/forums/viewtopic.php?id=29665")
local clipboard = require("gamesense/clipboard") or error("Failed to load clipboard | https://gamesense.pub/forums/viewtopic.php?id=28678")
local base64 = require("gamesense/base64") or error("Failed to load base64 | https://gamesense.pub/forums/viewtopic.php?id=21619")
local csgo_weapons = require("gamesense/csgo_weapons") or error("Failed to load csgo_weapons")
local ent = require "gamesense/entity" or error("Failed to load entity | https://gamesense.pub/forums/viewtopic.php?id=27529")
local trace = require "gamesense/trace" or error("Failed to load trace")
local http = require "gamesense/http" or error("Failed to load http | https://gamesense.pub/forums/viewtopic.php?id=19253")
local images = require("gamesense/images") or error("Failed to load images | https://gamesense.pub/forums/viewtopic.php?id=22917")
local vector = require "vector"
local obex_data = obex_fetch and obex_fetch() or {username = 'Puwpl', build = 'dev', discord=''}
local tab,place =  "AA","Anti-aimbot angles"
local ffi = require 'ffi'

local what_noti_image = nil

http.get("https://i.imgur.com/8AeuI7l.png", function(s, r)
    if s and r.status == 200 then
        what_noti_image = images.load(r.body)
    else
        error("error getting image - error  " .. response.status_message)
    end
end)


function rounded_rectangle(x, y, w, h, r, g, b, a, radius, thickness)
    y = y + radius
    local data_circle = {
        {x + radius, y, 180},
        {x + w - radius, y, 270},
        {x + radius, y + h - radius * 2, 90},
        {x + w - radius, y + h - radius * 2, 0},
    }

    local data = {
        {x + radius, y - radius, w - radius * 2, thickness},
        {x + radius, y + h - radius - thickness, w - radius * 2, thickness},
        {x, y, thickness, h - radius * 2},
        {x + w - thickness, y, thickness, h - radius * 2},
    }

    for _, data in next, data_circle do
        renderer.circle_outline(data[1], data[2], r, g, b, a, radius, data[3], 0.25, thickness)
    end

    for _, data in next, data do
        renderer.rectangle(data[1], data[2], data[3], data[4], r, g, b, a)
    end
end

local function table_contains(tbl, val)
    for i=1,#tbl do
        if tbl[i] == val then
            return true
        end
    end
    return false
end

local x, o = '\x14\x14\x14\xFF', '\x0c\x0c\x0c\xFF'
local pattern = table.concat{
  x,x,o,x,
  o,x,o,x,
  o,x,x,x,
  o,x,o,x
}

table.contains = function(source, target)
    local source_element = ui.get(source)
    for id, name in pairs(source_element) do
        if name == target then
            return true
        end
    end

    return false
end

local c_entity = require("gamesense/entity")
local E_POSE_PARAMETERS = {
    STRAFE_YAW = 0,
    STAND = 1,
    LEAN_YAW = 2,
    SPEED = 3,
    LADDER_YAW = 4,
    LADDER_SPEED = 5,
    JUMP_FALL = 6,
    MOVE_YAW = 7,
    MOVE_BLEND_CROUCH = 8,
    MOVE_BLEND_WALK = 9,
    MOVE_BLEND_RUN = 10,
    BODY_YAW = 11,
    BODY_PITCH = 12,
    AIM_BLEND_STAND_IDLE = 13,
    AIM_BLEND_STAND_WALK = 14,
    AIM_BLEND_STAND_RUN = 14,
    AIM_BLEND_CROUCH_IDLE = 16,
    AIM_BLEND_CROUCH_WALK = 17,
    DEATH_YAW = 18
}

local is_on_ground = false

local w,h = client.screen_size()
local tex_id = renderer.load_rgba(pattern, 4, 4)

local menu_reference = {
    enabled = ui.reference("AA", "Anti-aimbot angles", "Enabled"),
    pitch = { ui.reference("AA", "Anti-aimbot angles", "pitch") },
    roll = ui.reference("AA", "Anti-aimbot angles", "roll"),
    yawbase = ui.reference("AA", "Anti-aimbot angles", "Yaw base"),
    yaw = {ui.reference("AA", "Anti-aimbot angles", "Yaw")},
    fsbodyyaw = ui.reference("AA", "anti-aimbot angles", "Freestanding body yaw"),
    edgeyaw = ui.reference("AA", "Anti-aimbot angles", "Edge yaw"),
    dtholdaim = ui.reference("misc", "settings", "sv_maxusrcmdprocessticks_holdaim"),
    fakeduck = ui.reference("RAGE", "Other", "Duck peek assist"),
    minimum_damage = ui.reference("RAGE", "Aimbot", "Minimum damage"),
    safepoint = ui.reference("RAGE", "Aimbot", "Force safe point"),
    forcebaim = ui.reference("RAGE", "Aimbot", "Force body aim"),
    player_list = ui.reference("PLAYERS", "Players", "Player list"),
    reset_all = ui.reference("PLAYERS", "Players", "Reset all"),
    apply_all = ui.reference("PLAYERS", "Adjustments", "Apply to all"),
    load_cfg = ui.reference("Config", "Presets", "Load"),
    fl_limit = ui.reference("AA", "Fake lag", "Limit"),
    dt_limit = ui.reference("RAGE", "Aimbot", "Double tap fake lag limit"),
    quickpeek = {ui.reference("RAGE", "Other", "Quick peek assist")},
    yawjitter = {ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")},
    bodyyaw = {ui.reference("AA", "Anti-aimbot angles", "Body yaw")},
    freestand = {ui.reference("AA", "Anti-aimbot angles", "Freestanding")},
    freestand_body = {ui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw")},
    os = {ui.reference("AA", "Other", "On shot anti-aim")},
    slow = {ui.reference("AA", "Other", "Slow motion")},
    dt = {ui.reference("RAGE", "Aimbot", "Double tap")},
    fakelag = {ui.reference("AA", "Fake lag", "Limit")},
    fakelag_variance = ui.reference("AA", "Fake lag", "Variance"),
    fake_lag_amount = ui.reference("AA", "Fake lag", "Amount"),
    leg_movement = ui.reference("AA", "Other", "Leg movement"),
    ammo = ui.reference("VISUALS","Player ESP","Ammo"),
    weapon_text = ui.reference("VISUALS","Player ESP","Weapon text"),
    weapon_icon = ui.reference("VISUALS","Player ESP","Weapon icon"),
    ping = { ui.reference("MISC","Miscellaneous","Ping spike") },
    clan_tag_spammer = ui.reference("MISC","Miscellaneous","Clan tag spammer"),
    min_dmg_override = { ui.reference("RAGE","Aimbot","Minimum damage override") },
    menu_key = { ui.reference("MISC","Settings","Menu key") },
    dpi_scale = ui.reference("MISC","Settings","DPI scale"),
    slidewalk_directory = ui.reference("AA", "other", "leg movement"),
}

local find_material = materialsystem.find_material

local engine_client = ffi.cast(ffi.typeof('void***'), client.create_interface('engine.dll', 'VEngineClient014'))
local console_is_visible = ffi.cast(ffi.typeof('bool(__thiscall*)(void*)'), engine_client[0][11])

local elect_svg = renderer.load_svg("<svg id=\"svg\" version=\"1.1\" width=\"608\" height=\"689\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" ><g id=\"svgg\"><path id=\"path0\" d=\"M185.803 18.945 C 184.779 19.092,182.028 23.306,174.851 35.722 C 169.580 44.841,157.064 66.513,147.038 83.882 C 109.237 149.365,100.864 163.863,93.085 177.303 C 88.686 184.901,78.772 202.072,71.053 215.461 C 63.333 228.849,53.959 245.069,50.219 251.505 C 46.480 257.941,43.421 263.491,43.421 263.837 C 43.421 264.234,69.566 264.530,114.025 264.635 L 184.628 264.803 181.217 278.618 C 179.342 286.217,174.952 304.128,171.463 318.421 C 167.974 332.714,160.115 364.836,153.999 389.803 C 147.882 414.770,142.934 435.254,143.002 435.324 C 143.127 435.452,148.286 428.934,199.343 364.145 C 215.026 344.243,230.900 324.112,234.619 319.408 C 238.337 314.704,254.449 294.276,270.423 274.013 C 286.397 253.750,303.090 232.582,307.519 226.974 C 340.870 184.745,355.263 166.399,355.263 166.117 C 355.263 165.937,323.554 165.789,284.798 165.789 C 223.368 165.789,214.380 165.667,214.701 164.831 C 215.039 163.949,222.249 151.366,243.554 114.474 C 280.604 50.317,298.192 19.768,298.267 19.444 C 298.355 19.064,188.388 18.576,185.803 18.945 \" stroke=\"none\" fill=\"#fff200\" fill-rule=\"evenodd\"></path></g></svg>", 25, 25)

local lua_color = {r = 190, g = 190, b = 255}

local new_menu_references = {
    --extra_label = ui.new_label(tab,place,"~ aa extras tab ~"),
    aa_tab = ui.new_combobox(tab,place,"\aaac8fbffanti-aim\affffffff extras",{"Main","Jitter","Bruteforce"}),
   
    ["aa"] = {
        
        
        aa_state_menu = ui.new_combobox(tab,place,"\aaac8fbffanti-aim\affffffff state",{"Stand","Walk","In-Air","Air duck","Duck","Slow","Manual","Fakelag","Legit"}),
        freestanding_disabler = ui.new_multiselect(tab, place, "Freestanding [\aaac8fbffdisablers\affffffff]",{"Stand","Walk","In-Air","Air duck","Duck","Slow","Fakelag"}),
        aa_state = {},
        anti_kniv = ui.new_checkbox(tab, place, "Anti-knife"),
        safe_dangerous = ui.new_checkbox(tab, place, "safe knife | taser"),
        label_jitter_ways = ui.new_label(tab,place,"Only works if you enable jitter ways"),
        
    },

    ["visuals"] = {
        
        enable_indicators = ui.new_combobox(tab,place,"Indicators",{"off","default","minimal","yeat"}),
        indicator_color = ui.new_color_picker(tab, place, "indicatorz", 101, 130, 190, 255),
        --scoped_animation = ui.new_checkbox(tab, place, "Scoped animation"),
        enable_manual = ui.new_combobox(tab, place, "Manual arrows",{"off","ts","minimal"}),
        indicator_manual_color = ui.new_color_picker(tab, place, "indicatorzmanual", 255, 255, 255, 255),
        enable_velocity_adaptive = ui.new_checkbox(tab, place, "velocity adaptive"),
        enable_defensive_indicator = ui.new_checkbox(tab, place, "defensive indicator"),
        indicator_defensive_color = ui.new_color_picker(tab, place, "indicatorzdefensive", 255, 255, 255, 255),
        slow_indicator = ui.new_checkbox(tab, place, "slow down indicator"),
        indicator_slow_color = ui.new_color_picker(tab, place, "indicatorzslow", 255, 255, 255, 255),
        enable_min_dmg_ovrrd = ui.new_checkbox(tab, place, "minimum damage indicator"),
        enable_desync_indicator = ui.new_checkbox(tab, place, "desync indicator"),
        indicator_desync_color = ui.new_color_picker(tab, place, "indicatorzdesync", 255, 255, 255, 255),
        draw_logs = ui.new_checkbox(tab, place, "console logs"),
        zeus = ui.new_multiselect(tab, place, "> zeus indicator",{"Zeus warning"}),
        --zeus_warning = ui.new_checkbox(tab, place, "Zeus warning"),
        extra_visuals = ui.new_multiselect(tab, place, "> extras",{"beta logs", "at target flag", "edge yaw", "discharge exploit"}),
        --noti_timer = ui.new_slider(tab,place,"notifcation timer", 1, 10, 5,1,"s"),
        --noti_padding = ui.new_slider(tab,place,"notifcation padding", 0, 50, 10,1,"px"),
        --aim_logs_label = ui.new_label(tab,place,"aim logs outline"),
        --aim_logs_outline_color = ui.new_color_picker(tab,place,"aim logs outlinez",101,130,190,255),
        watermark_label = ui.new_checkbox(tab,place,"watermark"),
        watermark_color = ui.new_color_picker(tab,place,"water_colorz",101,130,190,255),

        collisionControl = ui.new_checkbox(tab, place, "Thirdperson"),
        distanceControl = ui.new_slider(tab, place, "Thirdperson distance", 30, 200, 125),

        --hitmarker = ui.new_checkbox(tab, place, "Hitmarker"),
        hitmarker = ui.new_combobox(tab, place, "Hitmarker",{"Off", "Default", "Default + circle"}),
        hitmarker_color = ui.new_color_picker(tab, place, "hitmarker_color_smb", 255, 255, 255, 255),

        console_col_label = ui.new_checkbox(tab, place, 'Console color'),
        recolor_console = ui.new_color_picker(tab, place, 'console_color_smb', 81, 81, 81, 210),

        tracer = ui.new_combobox(tab,place,"Bullet tracers",{"off","default","glow"}),
        color = ui.new_color_picker(tab, place, "tracer_color", 255, 255, 255, 255),
        logs = ui.new_checkbox(tab, place, "On Screen Logs"),
        logsClr = ui.new_color_picker(tab, place, "Logs Color", lua_color.r, lua_color.g, lua_color.b, 255),
        logOffset = ui.new_slider(tab, place, "Offset", 0, 500, 100, true, "px", 1),
        --aimer_legs = ui.new_checkbox(tab, place, "aimer_lugs"),
        --whatsappi = ui.new_checkbox(tab, place, "whatsappi"),
    },

    ["misc"] = {
        
        enable_clan_tag = ui.new_checkbox(tab, place, "synced tag"),
        enable_kill_say = ui.new_combobox(tab, place, "kill say",{"Disabled","Starlight","Yeat"}),
        enable_sun_rise = ui.new_checkbox(tab, place, "sun rise mode"),
        sun_pitch = ui.new_slider(tab, place, "Pitch\n", -89, 89, 0),
        sun_yaw = ui.new_slider(tab, place, "Yaw\n", 0, 180, 0),
        sun_distance = ui.new_slider(tab, place, "Distance\n", 50, 1500, 0),
        --sun_label = ui.new_label(tab,place,"Sun color"),
        --sun_color = ui.new_slider(tab, place, "Sun color hui", 0, 255, 0, false),
        enable_nigthermode = ui.new_checkbox(tab, place, "nightmode v2"),
        debug_ragebot = ui.new_multiselect(tab, place, "[\aaac8fbffdebug\affffffff] ragebot enhancer",{"defensive aa resolver (exprimental)","safe point enhancer"}),
        safe_point = ui.new_multiselect(tab, place, "safe point enhancer",{"Stand","on lethal","default","wide jitter"}),
        m_elements = ui.new_multiselect(tab, place, "Animbreakes", {"Adjust body lean", "Slide slow-walking", "Reset pitch on land", "Break legs while in air", "Break legs while landing"}),
        slide_elements = ui.new_multiselect(tab, place, "Sliding elements", {"While walking", "While running", "While crouching"}),
        body_lean_value = ui.new_slider(tab, place, "Body lean value", 0, 100, 0, true, "%", 0.01, {[0] = "Disabled", [35] = "Small", [50] = "Medium", [75] = "High", [100] = "Extreme"}),
        break_air_value = ui.new_slider(tab, place, "Breakable air value", 0, 10, 5, true, "%", 0.1, {[0] = "Disabled", [5] = "Default", [10] = "Maximum"}),
        break_land_value = ui.new_slider(tab, place, "Breakable land value", 0, 10, 5, true, "%", 0.1, {[0] = "Slowest", [5] = "Fastest", [10] = "Disabled"}),
        console_filter = ui.new_checkbox(tab, place, "Console filter"),
        --dtDischarge = ui.new_checkbox(tab, place, "Discharge Exploit"),
    },

    ["keys"] = {
        enable_key = ui.new_checkbox(tab, place, "keys"),
        manual_left = ui.new_hotkey(tab,place, "- manual left",false),
        manual_right = ui.new_hotkey(tab,place, "- manual right",false),
        manual_forward = ui.new_hotkey(tab,place, "- manual forward",false),
        manual_reset =ui.new_hotkey(tab,place, "- reset angles",false),
        global_fs = ui.new_hotkey(tab,place, "- freestanding",false),
        edgeYawHotkey = ui.new_hotkey(tab, place, "- edge yaw", false),
        dtDischarge = ui.new_hotkey(tab, place, "- discharge exploit", false),
    },

    ["config"] = {
       
    },

    ["bruteforce"] = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
        [4] = 0,
    },
}

local func = {
    fclamp = function(x, min, max)
        return math.max(min, math.min(x, max));
    end,
    frgba = function(hex)
        hex = hex:gsub("#", "");
    
        local r = tonumber(hex:sub(1, 2), 16);
        local g = tonumber(hex:sub(3, 4), 16);
        local b = tonumber(hex:sub(5, 6), 16);
        local a = tonumber(hex:sub(7, 8), 16) or 255;
    
        return r, g, b, a;
    end,
    render_text = function(x, y, ...)
        local x_Offset = 0
        
        local args = {...}
    
        for i, line in pairs(args) do
            local r, g, b, a, text = unpack(line)
            local size = vector(renderer.measure_text("-d", text))
            renderer.text(x + x_Offset, y, r, g, b, a, "-d", 0, text)
            x_Offset = x_Offset + size.x
        end
    end,
    easeInOut = function(t)
        return (t > 0.5) and 4*((t-1)^3)+1 or 4*t^3;
    end,
    rec = function(x, y, w, h, radius, color)
        radius = math.min(x/2, y/2, radius)
        local r, g, b, a = unpack(color)
        renderer.rectangle(x, y + radius, w, h - radius*2, r, g, b, a)
        renderer.rectangle(x + radius, y, w - radius*2, radius, r, g, b, a)
        renderer.rectangle(x + radius, y + h - radius, w - radius*2, radius, r, g, b, a)
        renderer.circle(x + radius, y + radius, r, g, b, a, radius, 180, 0.25)
        renderer.circle(x - radius + w, y + radius, r, g, b, a, radius, 90, 0.25)
        renderer.circle(x - radius + w, y - radius + h, r, g, b, a, radius, 0, 0.25)
        renderer.circle(x + radius, y - radius + h, r, g, b, a, radius, -90, 0.25)
    end,
    rec_outline = function(x, y, w, h, radius, thickness, color)
        radius = math.min(w/2, h/2, radius)
        local r, g, b, a = unpack(color)
        if radius == 1 then
            renderer.rectangle(x, y, w, thickness, r, g, b, a)
            renderer.rectangle(x, y + h - thickness, w , thickness, r, g, b, a)
        else
            renderer.rectangle(x + radius, y, w - radius*2, thickness, r, g, b, a)
            renderer.rectangle(x + radius, y + h - thickness, w - radius*2, thickness, r, g, b, a)
            renderer.rectangle(x, y + radius, thickness, h - radius*2, r, g, b, a)
            renderer.rectangle(x + w - thickness, y + radius, thickness, h - radius*2, r, g, b, a)
            renderer.circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, thickness)
            renderer.circle_outline(x + radius, y + h - radius, r, g, b, a, radius, 90, 0.25, thickness)
            renderer.circle_outline(x + w - radius, y + radius, r, g, b, a, radius, -90, 0.25, thickness)
            renderer.circle_outline(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25, thickness)
        end
    end,
    clamp = function(x, min, max)
        return x < min and min or x > max and max or x
    end,
    includes = function(tbl, value)
        for i = 1, #tbl do
            if tbl[i] == value then
                return true
            end
        end
        return false
    end,
    findDist = function (x1, y1, z1, x2, y2, z2)
        return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
    end,
    type_from_string = function(input)
        if type(input) ~= "string" then return input end

        local value = input:lower()

        if value == "true" then
            return true
        elseif value == "false" then
            return false
        elseif tonumber(value) ~= nil then
            return tonumber(value)
        else
            return tostring(input)
        end
    end,
    lerp = function(start, vend, time)
        return start + (vend - start) * time
    end,
    vec_angles = function(angle_x, angle_y)
        local sy = math.sin(math.rad(angle_y))
        local cy = math.cos(math.rad(angle_y))
        local sp = math.sin(math.rad(angle_x))
        local cp = math.cos(math.rad(angle_x))
        return cp * cy, cp * sy, -sp
    end,
    hex = function(arg)
        local result = "\a"
        for key, value in next, arg do
            local output = ""
            while value > 0 do
                local index = math.fmod(value, 16) + 1
                value = math.floor(value / 16)
                output = string.sub("0123456789ABCDEF", index, index) .. output 
            end
            if #output == 0 then 
                output = "00" 
            elseif #output == 1 then 
                output = "0" .. output 
            end 
            result = result .. output
        end 
        return result .. "FF"
    end,
    split = function( inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
    end,
    RGBAtoHEX = function(redArg, greenArg, blueArg, alphaArg)
        return string.format('%.2x%.2x%.2x%.2x', redArg, greenArg, blueArg, alphaArg)
    end,
    create_color_array = function(r, g, b, string)
        local colors = {}
        for i = 0, #string do
            local color = {r, g, b, 255 * math.abs(1 * math.cos(2 * math.pi * globals.curtime() / 4 + i * 5 / 30))}
            table.insert(colors, color)
        end
        return colors
    end,
    textArray = function(string)
        local result = {}
        for i=1, #string do
            result[i] = string.sub(string, i, i)
        end
        return result
    end,
    gradient_text = function(r1, g1, b1, a1, r2, g2, b2, a2, text)
        local output = ''
    
        local len = #text-1
    
        local rinc = (r2 - r1) / len
        local ginc = (g2 - g1) / len
        local binc = (b2 - b1) / len
        local ainc = (a2 - a1) / len
    
        for i=1, len+1 do
            output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, text:sub(i, i))
    
            r1 = r1 + rinc
            g1 = g1 + ginc
            b1 = b1 + binc
            a1 = a1 + ainc
        end
    
        return output
    end,    
    time_to_ticks = function(t)
        return math.floor(0.5 + (t / globals.tickinterval()))
    end,
    headVisible = function(enemy)
        local local_player = entity.get_local_player()
        if local_player == nil then return end
        local ex, ey, ez = entity.hitbox_position(enemy, 1)
    
        local hx, hy, hz = entity.hitbox_position(local_player, 1)
        local head_fraction, head_entindex_hit = client.trace_line(enemy, ex, ey, ez, hx, hy, hz)
        if head_entindex_hit == local_player or head_fraction == 1 then return true else return false end
    end,
    defensive = {
        cmd = 0,
        check = 0,
        defensive = 0,
    },
    aa_clamp = function(x) if x == nil then return 0 end x = (x % 360 + 360) % 360 return x > 180 and x - 360 or x end,
}

local color_text = function( string, r, g, b, a)
    local accent = "\a" .. func.RGBAtoHEX(r, g, b, a)
    local white = "\a" .. func.RGBAtoHEX(255, 255, 255, a)

    local str = ""
    for i, s in ipairs(func.split(string, "$")) do
        str = str .. (i % 2 ==( string:sub(1, 1) == "$" and 0 or 1) and white or accent) .. s
    end

    return str
end

local animate_text = function(time, string, r, g, b, a)
    local t_out, t_out_iter = { }, 1

    local l = string:len( ) - 1

    local r_add = (255 - r)
    local g_add = (255 - g)
    local b_add = (255 - b)
    local a_add = (165 - a)

    for i = 1, #string do
        local iter = (i - 1)/(#string - 1) + time
        t_out[t_out_iter] = "\a" .. func.RGBAtoHEX( r + r_add * math.abs(math.cos( iter )), g + g_add * math.abs(math.cos( iter )), b + b_add * math.abs(math.cos( iter )), a + a_add * math.abs(math.cos( iter )) )

        t_out[t_out_iter + 1] = string:sub( i, i )

        t_out_iter = t_out_iter + 2
    end

    return t_out
end

local glow_module = function(x, y, w, h, width, rounding, accent, accent_inner)
    local thickness = 1
    local Offset = 1
    local r, g, b, a = unpack(accent)
    if accent_inner then
        func.rec(x, y, w, h + 1, rounding, accent_inner)
    end
    for k = 0, width do
        if a * (k/width)^(1) > 5 then
            local accent = {r, g, b, a * (k/width)^(2)}
            func.rec_outline(x + (k - width - Offset)*thickness, y + (k - width - Offset) * thickness, w - (k - width - Offset)*thickness*2, h + 1 - (k - width - Offset)*thickness*2, rounding + thickness * (width - k + Offset), thickness, accent)
        end
    end
end

local colorful_text = {
    lerp = function(self, from, to, duration)
        if type(from) == 'table' and type(to) == 'table' then
            return { 
                self:lerp(from[1], to[1], duration), 
                self:lerp(from[2], to[2], duration), 
                self:lerp(from[3], to[3], duration) 
            };
        end
    
        return from + (to - from) * duration;
    end,
    console = function(self, ...)
        for i, v in ipairs({ ... }) do
            if type(v[1]) == 'table' and type(v[2]) == 'table' and type(v[3]) == 'string' then
                for k = 1, #v[3] do
                    local l = self:lerp(v[1], v[2], k / #v[3]);
                    client.color_log(l[1], l[2], l[3], v[3]:sub(k, k) .. '\0');
                end
            elseif type(v[1]) == 'table' and type(v[2]) == 'string' then
                client.color_log(v[1][1], v[1][2], v[1][3], v[2] .. '\0');
            end
        end
    end,
    text = function(self, ...)
        local menu = false;
        local alpha = 255
        local f = '';
        
        for i, v in ipairs({ ... }) do
            if type(v) == 'boolean' then
                menu = v;
            elseif type(v) == 'number' then
                alpha = v;
            elseif type(v) == 'string' then
                f = f .. v;
            elseif type(v) == 'table' then
                if type(v[1]) == 'table' and type(v[2]) == 'string' then
                    f = f .. ('\a%02x%02x%02x%02x'):format(v[1][1], v[1][2], v[1][3], alpha) .. v[2];
                elseif type(v[1]) == 'table' and type(v[2]) == 'table' and type(v[3]) == 'string' then
                    for k = 1, #v[3] do
                        local g = self:lerp(v[1], v[2], k / #v[3])
                        f = f .. ('\a%02x%02x%02x%02x'):format(g[1], g[2], g[3], alpha) .. v[3]:sub(k, k)
                    end
                end
            end
        end
    
        return ('%s\a%s%02x'):format(f, (menu) and 'cdcdcd' or 'ffffff', alpha);
    end,
    log = function(self, ...)
        for i, v in ipairs({ ... }) do
            if type(v) == 'table' then
                if type(v[1]) == 'table' then
                    if type(v[2]) == 'string' then
                        self:console({ v[1], v[1], v[2] })
                        if (v[3]) then
                            self:console({ { 255, 255, 255 }, '\n' })
                        end
                    elseif type(v[2]) == 'table' then
                        self:console({ v[1], v[2], v[3] })
                        if v[4] then
                            self:console({ { 255, 255, 255 }, '\n' })
                        end
                    end
                elseif type(v[1]) == 'string' then
                    self:console({ { 205, 205, 205 }, v[1] });
                    if v[2] then
                        self:console({ { 255, 255, 255 }, '\n' })
                    end
                end
            end
        end
    end
}

local anim_time = 0.5
local max_notifs = 6
local data = {}
local notifications = {
    new = function(string, r, g, b)
        table.insert(data, {
            time = globals.curtime(),
            string = string,
            color = {r, g, b, 255},
            fraction = 0
        })
        local time = 5
        for i = #data, 1, -1 do
            local notif = data[i]
            if #data - i + 1 > max_notifs and notif.time + time - globals.curtime() > 0 then
                notif.time = globals.curtime() - time
            end
        end
    end,

    render = function()
        local x, y = client.screen_size()
        local to_remove = {}
        local Offset = 0
        for i = 1, #data do
            local notif = data[i]

            local data = {rounding = 4, size = 3, glow = 2, time = 2}

            if notif.time + data.time - globals.curtime() > 0 then
                notif.fraction = func.clamp(notif.fraction + globals.frametime() / anim_time, 0, 1)
            else
                notif.fraction = func.clamp(notif.fraction - globals.frametime() / anim_time, 0, 1)
            end

            if notif.fraction <= 0 and notif.time + data.time - globals.curtime() <= 0 then
                table.insert(to_remove, i)
            end
            local fraction = func.easeInOut(notif.fraction)

            local r, g, b, a = unpack(notif.color)
            local string = color_text(notif.string, r, g, b, a * fraction)

            local strw, strh = renderer.measure_text("", string)
            local strw2 = renderer.measure_text("b", "")

            local paddingx, paddingy = 7, data.size
            local offsetY = ui.get(new_menu_references["visuals"].logOffset)

            Offset = Offset + (strh + paddingy*2 + 	math.sqrt(data.glow/10)*10 + 5) * fraction
            glow_module(x/2 - (strw + strw2)/2 - paddingx, y - offsetY - strh/2 - paddingy - Offset, strw + strw2 + paddingx*2, strh + paddingy*2, data.glow, data.rounding, {r, g, b, 45 * fraction}, {25,25,25,140 * fraction})
            renderer.text(x/2 + strw2/2, y - offsetY - Offset, 255, 255, 255, 255 * fraction, "c", 0, string)
        end

        for i = #to_remove, 1, -1 do
            table.remove(data, to_remove[i])
        end
    end,

    clear = function()
        data = {}
    end
}

local color_text = function( string, r, g, b, a)
    local accent = "\a" .. func.RGBAtoHEX(r, g, b, a)
    local white = "\a" .. func.RGBAtoHEX(255, 255, 255, a)

    local str = ""
    for i, s in ipairs(func.split(string, "$")) do
        str = str .. (i % 2 ==( string:sub(1, 1) == "$" and 0 or 1) and white or accent) .. s
    end

    return str
end

local vars = {
    localPlayer = 0,
    hitgroup_names = { 'Generic', 'Head', 'Chest', 'Stomach', 'Left arm', 'Right arm', 'Left leg', 'Right leg', 'Neck', '?', 'Gear' },
}

local function onHit(e)
    local group = vars.hitgroup_names[e.hitgroup + 1] or '?'
	local r, g, b, a = ui.get(new_menu_references["visuals"].logsClr)
	notifications.new(string.format("Hit %s's $%s$ for $%d$ damage ($%d$ health remaining)", entity.get_player_name(e.target), group:lower(), e.damage, entity.get_prop(e.target, 'm_iHealth')), r, g, b) 

end

local refs = {
    legit = ui.reference("LEGIT", "Aimbot", "Enabled"),
    dmgOverride = {ui.reference("RAGE", "Aimbot", "Minimum damage override")},
    fakeDuck = ui.reference("RAGE", "Other", "Duck peek assist"),
    minDmg = ui.reference("RAGE", "Aimbot", "Minimum damage"),
    hitChance = ui.reference("RAGE", "Aimbot", "Minimum hit chance"),
    safePoint = ui.reference("RAGE", "Aimbot", "Force safe point"),
    forceBaim = ui.reference("RAGE", "Aimbot", "Force body aim"),
    dtLimit = ui.reference("RAGE", "Aimbot", "Double tap fake lag limit"),
    quickPeek = {ui.reference("RAGE", "Other", "Quick peek assist")},
    dt = {ui.reference("RAGE", "Aimbot", "Double tap")},
    enabled = ui.reference("AA", "Anti-aimbot angles", "Enabled"),
    pitch = {ui.reference("AA", "Anti-aimbot angles", "pitch")},
    roll = ui.reference("AA", "Anti-aimbot angles", "roll"),
    yawBase = ui.reference("AA", "Anti-aimbot angles", "Yaw base"),
    yaw = {ui.reference("AA", "Anti-aimbot angles", "Yaw")},
    flLimit = ui.reference("AA", "Fake lag", "Limit"),
    fsBodyYaw = ui.reference("AA", "anti-aimbot angles", "Freestanding body yaw"),
    edgeYaw = ui.reference("AA", "Anti-aimbot angles", "Edge yaw"),
    yawJitter = {ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")},
    bodyYaw = {ui.reference("AA", "Anti-aimbot angles", "Body yaw")},
    freeStand = {ui.reference("AA", "Anti-aimbot angles", "Freestanding")},
    os = {ui.reference("AA", "Other", "On shot anti-aim")},
    slow = {ui.reference("AA", "Other", "Slow motion")},
    fakeLag = {ui.reference("AA", "Fake lag", "Limit")},
    legMovement = ui.reference("AA", "Other", "Leg movement"),
    indicators = {ui.reference("VISUALS", "Other ESP", "Feature indicators")},
    ping = {ui.reference("MISC", "Miscellaneous", "Ping spike")},
}

local function onMiss(e)
    local group = vars.hitgroup_names[e.hitgroup + 1] or '?'
    local ping = math.min(999, client.real_latency() * 1000)
    local ping_col = (ping >= 100) and { 255, 0, 0 } or { 150, 200, 60 }
    local hc = math.floor(e.hit_chance + 0.5);
    local hc_col = (hc < ui.get(refs.hitChance)) and { 255, 0, 0 } or { 150, 200, 60 };
    e.reason = e.reason == "?" and "resolver" or e.reason
	notifications.new(string.format("Missed %s's $%s$ due to $%s$", entity.get_player_name(e.target), group:lower(), e.reason), 255, 120, 120)
end

ui.set_callback(new_menu_references["visuals"].logs, function() 
    local callback = ui.get(new_menu_references["visuals"].logs) and client.set_event_callback or client.unset_event_callback
    callback("aim_miss", onMiss)
    callback("aim_hit", onHit)
end)

local function thirdpersonValues()
    if ui.get(new_menu_references["visuals"].collisionControl) == true then
        cvar.c_mindistance:set_int(ui.get(new_menu_references["visuals"].distanceControl))
        cvar.c_maxdistance:set_int(ui.get(new_menu_references["visuals"].distanceControl))
    else
        cvar.c_mindistance:set_int(100)
        cvar.c_maxdistance:set_int(100)
    end
end

ui.set_callback(new_menu_references["visuals"].collisionControl, thirdpersonValues)
ui.set_callback(new_menu_references["visuals"].distanceControl, thirdpersonValues)
thirdpersonValues()

local queue = {}

local queue1 = {}

local function aim_fire(c)
	queue[globals.tickcount()] = {c.x,c.y,c.z, globals.curtime() + 2}
end

local function glow_line(x, y, x2, y2, r, g, b, a)
    for i = 1, 5 do
        renderer.line(x - (5 - i), y - (5 - i), x2 - (5 - i), y2 - (5 - i), r, g, b, i * 20)
        --renderer.line(x + (5 - i), y + (5 - i), x2 + (5 - i), y2 + (5 - i), r, g, b, i * 60)
    end
end

client.set_event_callback("bullet_impact", function(e)
    if ui.get(new_menu_references["visuals"].tracer) == "off" then
        return
    end
    if client.userid_to_entindex(e.userid) ~= entity.get_local_player() then
        return
    end
    local lx, ly, lz = client.eye_position()
    queue1[globals.tickcount()] = {lx, ly, lz, e.x, e.y, e.z, globals.curtime() + 2}
end)

client.set_event_callback("paint", function()

    if table_contains(ui.get(new_menu_references["visuals"].extra_visuals),"edge yaw") then
        if ui.get(new_menu_references["keys"].edgeYawHotkey) then
            if not entity.is_alive(vars.localPlayer) then return end
            renderer.indicator(181, 179, 179, 255, "EDGE YAW")
        end
    end

    if table_contains(ui.get(new_menu_references["visuals"].extra_visuals),"discharge exploit") then
        if ui.get(new_menu_references["keys"].dtDischarge) then
            if not entity.is_alive(vars.localPlayer) then return end
            renderer.indicator(181, 179, 179, 255, "DE")
        end
    end

    if ui.get(new_menu_references["visuals"].tracer) == "off" then
        return
    end
    local tracer_col = { ui.get(new_menu_references["visuals"].color) }
    for tick, data in pairs(queue1) do
        if globals.curtime() <= data[7] then
            local x1, y1 = renderer.world_to_screen(data[1], data[2], data[3])
            local x2, y2 = renderer.world_to_screen(data[4], data[5], data[6])
            if x1 ~= nil and x2 ~= nil and y1 ~= nil and y2 ~= nil then
                if ui.get(new_menu_references["visuals"].tracer) == "default" then
                    renderer.line(x1, y1, x2, y2, ui.get(new_menu_references["visuals"].color))
                elseif ui.get(new_menu_references["visuals"].tracer) == "glow" then
                    glow_line(x1, y1, x2, y2, tracer_col[1], tracer_col[2], tracer_col[3], tracer_col[4])
                end
            end
        end
    end
end)

client.set_event_callback("round_start", function()
    if ui.get(new_menu_references["visuals"].tracer) == "off" then
        return
    end
    queue1 = {}
end)

client.set_event_callback("round_prestart", function()
    if ui.get(new_menu_references["visuals"].tracer) == "off" then
        return
    end
    queue = {}
end)

local function paint(c)
    local hitmarker_color = { ui.get(new_menu_references["visuals"].hitmarker_color) }

    if ui.get(new_menu_references["visuals"].hitmarker) == "Default" then
        for tick, data in pairs(queue) do
            if globals.curtime() <= data[4] then
                local x1, y1 = renderer.world_to_screen(data[1], data[2], data[3])
                if x1 ~= nil and y1 ~= nil then
                --renderer.circle_outline(x1,y1,255,255,255,255,5,0,1.0,1)
                
                renderer.line(x1 - 6,y1,x1 + 6,y1,0, hitmarker_color[1],hitmarker_color[2],hitmarker_color[3], hitmarker_color[4])
                renderer.line(x1,y1 - 6,x1,y1 + 6, hitmarker_color[1],hitmarker_color[2],hitmarker_color[3], hitmarker_color[4])
                end
            end
        end
    end
    if ui.get(new_menu_references["visuals"].hitmarker) == "Default + circle" then
        for tick, data in pairs(queue) do
            if globals.curtime() <= data[4] then
                local x1, y1 = renderer.world_to_screen(data[1], data[2], data[3])
                if x1 ~= nil and y1 ~= nil then
                renderer.circle_outline(x1,y1,255,255,255,255,5,0,1.0,1)
                
                renderer.line(x1 - 6,y1,x1 + 6,y1,0, hitmarker_color[1],hitmarker_color[2],hitmarker_color[3], hitmarker_color[4])
                renderer.line(x1,y1 - 6,x1,y1 + 6, hitmarker_color[1],hitmarker_color[2],hitmarker_color[3], hitmarker_color[4])
                end
            end
        end
    end
end

local materials = { 'vgui_white', 'vgui/hud/800corner1', 'vgui/hud/800corner2', 'vgui/hud/800corner3', 'vgui/hud/800corner4' }

client.set_event_callback('paint', function()
    local r, g, b, a = ui.get(new_menu_references["visuals"].recolor_console)

    if not console_is_visible(engine_client) then
        r, g, b, a = 255, 255, 255, 255
    end

    if ui.get(new_menu_references["visuals"].console_col_label) == true then
        for _, mat in pairs(materials) do
            find_material(mat):alpha_modulate(a)
            find_material(mat):color_modulate(r, g, b)
        end
    else
        for _, mat in pairs(materials) do
            find_material(mat):alpha_modulate(255)
            find_material(mat):color_modulate(255, 255, 255)
        end
    end
end)

client.set_event_callback("aim_fire",aim_fire)
client.set_event_callback("paint",paint)

client.set_event_callback("round_prestart", function()
    queue = {}
end)

ui.set_callback(new_menu_references["misc"].console_filter, function()
    cvar.con_filter_text:set_string("cool text")
    cvar.con_filter_enable:set_int(1)
end)

local function get_player_weapons(idx)
	local list = {}

    for i = 0, 64 do
        local cwpn = entity.get_prop(idx, "m_hMyWeapons", i)

		if cwpn ~= nil then
			table.insert(list, cwpn)
		end
	end

	return list
end

client.set_event_callback("setup_command", function(cmd)
    is_on_ground = cmd.in_jump == 0

    vars.localPlayer = entity.get_local_player()

    if table.contains(new_menu_references["misc"].m_elements, "Break legs while landing") then
        ui.set(menu_reference.slidewalk_directory, cmd.command_number % 3 == 0 and "Off" or "Always slide")
    end

    if ui.get(new_menu_references["keys"].dtDischarge) then
        if dtEnabled == nil then
            dtEnabled = true
        end
        local enemies = entity.get_players(true)
        local vis = false
        local health = entity.get_prop(vars.localPlayer, "m_iHealth")
        for i=1, #enemies do
            local entindex = enemies[i]
            local body_x,body_y,body_z = entity.hitbox_position(entindex, 1)
            if client.visible(body_x, body_y, body_z + 20) then
                vis = true
            end
        end	

        if vis then
            ui.set(menu_reference.dt[1],false)
            client.delay_call(0.01, function() 
                ui.set(menu_reference.dt[1],true)
            end)
        end
    else
        if dtEnabled == true then
            ui.set(menu_reference.dt[1], dtEnabled)
            dtEnabled = false
        end
    end

    ui.set(menu_reference.edgeyaw, ui.get(new_menu_references["keys"].edgeYawHotkey))
end)

client.set_event_callback("paint", function()
    local me = entity.get_local_player()

    local call_back = ui.get(new_menu_references["visuals"].logs) and client.set_event_callback or client.unset_event_callback

    notifications.render()

    if not table_contains(ui.get(new_menu_references["visuals"].zeus),"Zeus warning") or elect_svg == nil or me == nil or not entity.is_alive(me) then
        return 
    end
    
    for _, i in pairs(entity.get_players(true)) do
        local esp_data = entity.get_esp_data(i)

        if esp_data ~= nil then
            local has_taser = 0
            local x1, y1, x2, y2, a = entity.get_bounding_box(i)

            if esp_data.weapon_id == 31 then
                has_taser = 2
            end

            for _, v in pairs(get_player_weapons(i)) do
                if v ~= nil and has_taser == 0 and entity.get_prop(v, "m_iItemDefinitionIndex") == 31 then
                    has_taser = 1
                end
            end

            if x1 ~= 0 and a > 0.000 and has_taser > 0 then
                local g, b = 255, 255

                if has_taser == 2 then
                    g, b = 0, 0
                end

                renderer.texture(elect_svg, x1 - 24, y1, 25, 25, 255, g, b, a*255)
            end
        end
    end
end)

client.set_event_callback("pre_render", function()
    local self = entity.get_local_player()
    if not self or not entity.is_alive(self) then
        return
    end

    local self_index = c_entity.new(self)
    local self_anim_state = self_index:get_anim_state()

    if not self_anim_state then
        return
    end

    if table.contains(new_menu_references["misc"].m_elements, "Slide slow-walking") then
        if table.contains(new_menu_references["misc"].slide_elements, "While walking") then
            entity.set_prop(self, "m_flPoseParameter", 0, E_POSE_PARAMETERS.MOVE_BLEND_WALK)
        end

        if table.contains(new_menu_references["misc"].slide_elements, "While running") then
            entity.set_prop(self, "m_flPoseParameter", 0, E_POSE_PARAMETERS.MOVE_BLEND_RUN)
        end

        if table.contains(new_menu_references["misc"].slide_elements, "While crouching") then
            entity.set_prop(self, "m_flPoseParameter", 0, E_POSE_PARAMETERS.MOVE_BLEND_CROUCH)
        end
    end

    if table.contains(new_menu_references["misc"].m_elements, "Break legs while in air") then
        entity.set_prop(self, "m_flPoseParameter", ui.get(new_menu_references["misc"].break_air_value) / 10, E_POSE_PARAMETERS.JUMP_FALL)
    end

    if table.contains(new_menu_references["misc"].m_elements, "Break legs while landing") then
        entity.set_prop(self, "m_flPoseParameter", E_POSE_PARAMETERS.STAND, globals.tickcount() % 4 > 1 and ui.get(new_menu_references["misc"].break_land_value) / 10 or 1)
    end
    
    if table.contains(new_menu_references["misc"].m_elements, "Adjust body lean") then
        local self_anim_overlay = self_index:get_anim_overlay(12)
        if not self_anim_overlay then
            return
        end

        local x_velocity = entity.get_prop(self, "m_vecVelocity[0]")
        if math.abs(x_velocity) >= 3 then
            self_anim_overlay.weight = ui.get(new_menu_references["misc"].body_lean_value) / 100
        end
    end

    if table.contains(new_menu_references["misc"].m_elements, "Reset pitch on land") then
        if not self_anim_state.hit_in_ground_animation or not is_on_ground then
            return
        end

        entity.set_prop(self, "m_flPoseParameter", 0.5, E_POSE_PARAMETERS.BODY_PITCH)
    end
end)

local aa_functions = {
    aa_number = "Stand",
    jitter_way_number = 1,
    old_weapon = 0,
    actual_weapon = 0,
    actual_tick = 0,
    to_start = false,
    to_jitter = false,  
    bomb_was_bombed = false,
    bomb_was_defused = false,
    can_defensive = false,
    def_ticks = 0,
}

local visual_functions = {
    indicator_bottom = 0,
    damage_indi = "0",
    dt_indicator_animation = 0,
    hs_indicator_animation = 0,
    offset = 0,
    offset2 = 0,
    defensive_ready = false,
    is_defensive = false,
    outline_text_alpha = 255,
    text_alpha = 255,
    is_defensive_state = false,
    is_defensive_ticks = 0,
    is_defensive_disable = false,
    ticks = 0,
    old_weapon = 0,
    current_weapon = 0,
    is_in_attack = false,
    in_fire = false,
    move = false,
    damage_predict_string_calc = "",
    calc_dmg = 0,
    chance = 0,
    bt = 0,
    predicted_damage = 0,
    predicted_hitgroup = 0,
}

local misc_functions = {
    kill_say = {["Starlight"] = {"U think u good? luckily im here #STARLIGHT","youre value compared to me  is but a grain of sand","all romanian(you) will die to me(gypys king)",
    "this isnt phasmaphobia: global offensive please dont speak","starlight trap house","I guarntee youre loss forever and always","𝕡𝕣𝕠𝕓𝕝𝕖𝕞?","cope",
    " 格拉格拉 < you? 无功无过 < me B) #STARLIGHT","in hvh war i will win","below average performance starlight performance","SPEAK BULGARIAN? WILL TALK CN",
    "you are loss it is decided with my starlight.lua","you do not perform this hvh against starlight","qahahaha i am top of this region","this weak snail is spoke of victory but is door unhinged to loss",
    "you do not have the impression of owning the performance-enhancing software known as Gamesense.pub","how you will feel knowing im skeethaving and u will skeetless #starlight",
    "your mexican familia never make it out from trailer #starlight","cant understand u. any noname translator? #STARLIGHT","you waste aka fecal matter/shit(you)","sorry for u loss, me always better like life",
    "better luck next round, oh wait i alr won BAHAHHA","ur lua & u sucks get STARLIGHT >.<","when you spawn tell me why u die to me","how hit chance in deagle? i sit.",
    "shitting on your cheat speedrun any% WR run feat starlight","smelly lapdog dreams of success in 1x1 but is handed 9 casualities","dude where are my diamonds?","all weak dogs fall to starlight","WOW STARLIGHT .。GYPSY 的科技 (TECHNOLOGY) ? "},
    ["Yeat"] = {"I got beef with my kidney, he said that we got a problem","first my money twerk, now its lifting weights money in the gym, now its heavyweight",
    "I just popped a X pill and half my body glitched", "Yeah, this percy got me snail, you should call me Gary","Mad bout that"}},
    clan_tag = {"", "st","sta","star","starl","starli","starlig","starligh","starlight","starligh","starlig","starli","starl","star","sta","st"},
    ct_tick = 0,
    ct_old_tick = 0,
    save_tick = 0,
    clan_tag_change_potential = "change",
    was_ct_enabled_before = false,
    ground_ticks = 1,
    end_time = 0,
}

local function lerp(a, b, t)
    return a + (b - a) * t
end


local ui_menu = {
    tabs_names = {"","","","",""},
    selected_tab = 1,
    selected_color = { {20, 20, 20, 255}, {210,210,210,255} },
    selected_col = "88A6F391",
    menu_alpha = 255,
    is_hovered = false,
    dpi_scaling_y = {{84,149},{100,181},{116,213},{132,245},{148,276}},
    pesadelo_na_cozinha2 = {597,741,885,1030,1173 },
    selected_gs_tab = false,
    mouse_press = false,
    old_mpos = {0,0}
}

function ui_menu:is_aa_tab()
    local menu_size = { ui_menu_size() }
  
    
    local menu_pos = { ui_menu_position() }
    local mouse_pos = { ui_mouse_position() }

   local scale = {0,0}
   local scale_x = 0
   local pesadelo_no_direito = 0

    

    if ui.get(menu_reference.dpi_scale) == "100%" then
        scale = { ui_menu.dpi_scaling_y[1][1],ui_menu.dpi_scaling_y[1][2] }
        scale_x = 76
        pesadelo_no_direito = ui_menu.pesadelo_na_cozinha2[1]
    elseif ui.get(menu_reference.dpi_scale)  == "125%" then
        scale = { ui_menu.dpi_scaling_y[2][1],ui_menu.dpi_scaling_y[2][2] }
        scale_x = 95
        pesadelo_no_direito = ui_menu.pesadelo_na_cozinha2[2]
    elseif ui.get(menu_reference.dpi_scale)  == "150%" then
        scale = { ui_menu.dpi_scaling_y[3][1],ui_menu.dpi_scaling_y[3][2] }
        scale_x = 113
        pesadelo_no_direito = ui_menu.pesadelo_na_cozinha2[3]
    elseif ui.get(menu_reference.dpi_scale)  == "175%" then
        scale = { ui_menu.dpi_scaling_y[4][1],ui_menu.dpi_scaling_y[4][2] }
        scale_x = 132
        pesadelo_no_direito = ui_menu.pesadelo_na_cozinha2[4]
    elseif ui.get(menu_reference.dpi_scale)  == "200%" then
        scale = { ui_menu.dpi_scaling_y[5][1],ui_menu.dpi_scaling_y[5][2] }
        scale_x = 151
        pesadelo_no_direito = ui_menu.pesadelo_na_cozinha2[5]
    end

    if ui_menu.mouse_press == false then
        ui_menu.old_mpos = mouse_pos
    end      

    if client.key_state(0x1) then
        if not ui_menu.mouse_press then
            ui_menu.mouse_press = true
            if mouse_pos[1] > menu_pos[1] + 5 and mouse_pos[1] < menu_pos[1] + 5 + scale_x then
                if mouse_pos[2] > menu_pos[2] + scale[1] and mouse_pos[2] < menu_pos[2] + scale[2] then
                    ui_menu.selected_gs_tab = true
                    
                elseif mouse_pos[2] > menu_pos[2] + 19 and (menu_size[2] >= pesadelo_no_direito and mouse_pos[2] < menu_pos[2] + menu_size[2] or mouse_pos[2] < menu_pos[2] + pesadelo_no_direito) and ui_menu.selected_gs_tab == true then
                    ui_menu.selected_gs_tab = false
                end
            end
        end
    else
        ui_menu.mouse_press = false
    end
end

function ui_menu:new_tab()

    ui_menu.is_hovered = false
    if not ui.is_menu_open()  then
        ui_menu.menu_alpha = lerp(ui_menu.menu_alpha,0,globals.frametime() * 50)
    else
        ui_menu.menu_alpha = lerp(ui_menu.menu_alpha,255,globals.frametime() * 5)
    end

    if ui_menu.menu_alpha < 50 then return end

    local menu_size = { ui_menu_size() }
    local divide_menu = (menu_size[1] - 12) / #ui_menu.tabs_names
    
    local menu_pos = { ui_menu_position() }
    local mouse_pos = { ui_mouse_position() }

    if not ui_menu.selected_gs_tab then return end
    
    for k,v in ipairs(ui_menu.tabs_names) do

        if ui_menu.selected_tab == k then
            ui_menu.selected_color[1] = {20, 20, 20}
            ui_menu.selected_color[2] = {210, 210, 210}
            --ui_menu.selected_col = "\aD2D2D2FF"
        else
            ui_menu.selected_color[1] = {12, 12, 12}
            ui_menu.selected_color[2] = {90, 90, 90}
            --ui_menu.selected_col = "\a4E4E4E97"
        end
       
       
        renderer.rectangle(menu_pos[1] + 6 , menu_pos[2] - 47,menu_size[1] - 6,2, ui_menu.selected_color[1][1], ui_menu.selected_color[1][2], ui_menu.selected_color[1][3], ui_menu.menu_alpha )
        renderer.rectangle(menu_pos[1] + 6 + (divide_menu * k) - divide_menu, menu_pos[2] - 45,divide_menu + 1,50 , ui_menu.selected_color[1][1], ui_menu.selected_color[1][2], ui_menu.selected_color[1][3], ui_menu.menu_alpha )
        renderer.texture(tex_id, menu_pos[1] + 6 + (divide_menu * ui_menu.selected_tab) - divide_menu, menu_pos[2] - 45,divide_menu + 1,50, 255, 255, 255, ui_menu.menu_alpha, 'r')
        
        if obex_data.username == "Kib" then
            renderer.text(menu_pos[1] + (divide_menu * k) - divide_menu / 2 ,menu_pos[2] - 25,ui_menu.selected_color[2][1], ui_menu.selected_color[2][2], ui_menu.selected_color[2][3],ui_menu.menu_alpha,"cd+",0,"Kibby")
        else
            renderer.text(menu_pos[1] + (divide_menu * k) - divide_menu / 2 ,menu_pos[2] - 25,ui_menu.selected_color[2][1], ui_menu.selected_color[2][2], ui_menu.selected_color[2][3],ui_menu.menu_alpha,"cd+",0,v)
        end

        if mouse_pos[1] > menu_pos[1] + (divide_menu * k) -  divide_menu and mouse_pos[1] < menu_pos[1] + (divide_menu * k) and mouse_pos[2] > menu_pos[2] - 50 and mouse_pos[2] < menu_pos[2] then
            ui_menu.is_hovered = true
            if  client.key_state(0x1) then
                ui_menu.selected_tab = k
            end
        end
    end
    if obex_data.username == "Kib" then
        renderer.text(menu_pos[1] + (divide_menu * ui_menu.selected_tab) - divide_menu / 2 ,menu_pos[2] - 25,210, 210, 210,ui_menu.menu_alpha,"cd+",0,"Kibby")
    else
        renderer.text(menu_pos[1] + (divide_menu * ui_menu.selected_tab) - divide_menu / 2 ,menu_pos[2] - 25,210, 210, 210,ui_menu.menu_alpha,"cd+",0,ui_menu.tabs_names[ui_menu.selected_tab])
    end
end

function ui_menu:outside_bar()
    
    if not ui_menu.selected_gs_tab then return end

    if ui_menu.menu_alpha < 50 then return end

    local menu_size = { ui_menu_size() }
    local menu_pos = { ui_menu_position() }
 


    --top bar
    renderer_rectangle(menu_pos[1] ,menu_pos[2] - 53,menu_size[1] ,1 ,12,12,12,ui_menu.menu_alpha) -- black
    renderer_rectangle(menu_pos[1] + 2,menu_pos[2] - 52,menu_size[1] - 4,5 ,60,60,60,ui_menu.menu_alpha) -- outlines
    renderer_rectangle(menu_pos[1] + 2,menu_pos[2] - 51,menu_size[1] - 4,3 ,40,40,40,ui_menu.menu_alpha) -- inner

    --left bar
    renderer_rectangle(menu_pos[1] ,menu_pos[2] - 53,1,53 ,12,12,12,ui_menu.menu_alpha) -- black
    renderer_rectangle(menu_pos[1] + 1,menu_pos[2] - 52,4,52 ,60,60,60,ui_menu.menu_alpha) -- outlines
    renderer_rectangle(menu_pos[1] + 2,menu_pos[2] - 51,3,51 ,40,40,40,ui_menu.menu_alpha) -- inner
    renderer_rectangle(menu_pos[1] + 5,menu_pos[2] - 48,1,48 ,60,60,60,ui_menu.menu_alpha) -- outlines

    --right bar
    renderer_rectangle(menu_pos[1] + menu_size[1] - 1,menu_pos[2] - 53,1,53 ,12,12,12,ui_menu.menu_alpha) -- black
    renderer_rectangle(menu_pos[1] + menu_size[1] - 3,menu_pos[2] - 52,2,52 ,60,60,60,ui_menu.menu_alpha) -- outlines
    renderer_rectangle(menu_pos[1] + menu_size[1] - 5,menu_pos[2] - 51,3,51 ,40,40,40,ui_menu.menu_alpha) -- inner
    renderer_rectangle(menu_pos[1] + menu_size[1] - 6,menu_pos[2] - 48,1,48 ,60,60,60,ui_menu.menu_alpha) -- outlines

    renderer.gradient(menu_pos[1] + 7,menu_pos[2] - 46,
    menu_size[1]/2,1, 59, 175, 222, 255, 202, 70, 205, 255,true)
            
    renderer.gradient(menu_pos[1] + 7 + menu_size[1]/2 ,menu_pos[2] - 46,
    menu_size[1]/2 - 14, 1,202, 70, 205, 255,204, 227, 53, 255,true)
end

local aa = {
    aa_states = {"Stand","Walk","In-Air","Air duck","Duck","Slow","Manual","Fakelag","Legit"},
    manual_state = "reset",
    color_left = {120,120,120,255},
    color_right = {120,120,120,255},
    color_body_r = {120,120,120,255},
    color_body_l = {120,120,120,255},
    last_pressed = 0,
}

local brute_stage = {
    brute = {},
    last_miss = 0,
    to_death_reset = false,
    to_reset = false,
    round_starting = false,
}

local light_blue = "\aaac8fbff"
local white = "\affffffff: "
-- menu aa ui
for k,v in ipairs(aa.aa_states) do
    
    
    brute_stage.brute[v] = {}
    local y = string.sub(v,1,1)
    local new_streng = string.gsub(v,y,string.upper(y))
    new_menu_references["aa"].aa_state[v] = {}
    new_menu_references["aa"].aa_state[v].jway_counter = ui.new_slider(tab,place, "jitter slider \n" .. new_streng, 2, 12, 2)
    new_menu_references["aa"].aa_state[v].enabled = ui.new_checkbox(tab,place,"enable '" .. light_blue .. new_streng .. "'" .. "\affffffff" )
    new_menu_references["aa"].aa_state[v].pitch = ui.new_combobox(tab,place,light_blue .. new_streng .. white .."pitch\n" .. v,{"off", "default", "down", "minimal","custom"})
    new_menu_references["aa"].aa_state[v].pitch_slider = ui.new_slider(tab,place,"\n" .. light_blue .. new_streng .. white .. "custom pitch", -89, 89, 0)


    new_menu_references["aa"].aa_state[v].yawbase = ui.new_combobox(tab,place,light_blue .. new_streng .. white .."yaw base\n" .. v,{"local view", "at targets"})
    new_menu_references["aa"].aa_state[v].yaw = ui.new_combobox(tab,place,light_blue .. new_streng .. white .."yaw\n" .. v,{"off", "180", "180 z", "crosshair","jittery","delayed","l & r"})
    
    new_menu_references["aa"].aa_state[v].yawadd = ui.new_slider(tab,place, light_blue .. new_streng .. white .."yaw right\n" .. v, -180, 180, k == 9 and 180 or 0)

    if k ~= "manual" and k ~= "leigt" then
        new_menu_references["aa"].aa_state[v].yawaddleft = ui.new_slider(tab,place, light_blue .. new_streng .. white .."yaw left \n" .. v, -180, 180, 0)
        new_menu_references["aa"].aa_state[v].ticker_slider = ui.new_slider(tab,place, light_blue .. new_streng .. white .."ticks delay \n" .. v, 1, 10, 1)
    end
    new_menu_references["aa"].aa_state[v].yawjitter = ui.new_combobox( tab,place,light_blue .. new_streng .. white .."yaw jitter\n" .. v,{"off", "offset", "center", "random","skitter","jitter ways","sway","l & r"})
    new_menu_references["aa"].aa_state[v].yawjitteradd = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "yaw jitter" , -180, 180, 0)
    new_menu_references["aa"].aa_state[v].yawjitteradd2 = ui.new_slider(tab,place, light_blue .. new_streng .. white .."yaw jitter left", -180, 180, 0)
    new_menu_references["aa"].aa_state[v].swaym = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "sway min\n" .. v, -180, 180, 0)
    new_menu_references["aa"].aa_state[v].swaymx = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "sway max\n" .. v, -180, 180, 0)
    new_menu_references["aa"].aa_state[v].swayspeed = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "sway speed\n" .. v, 1, 10,1)
    new_menu_references["aa"].aa_state[v].sway_value = 0
    new_menu_references["aa"].aa_state[v].to_sway = false
    new_menu_references["aa"].aa_state[v].gs_bodyyaw = ui.new_combobox( tab,place,light_blue .. new_streng .. white .."body yaw\n" .. v,{"off","jitter", "static","anti bruteforce","auto jitter","delayed yaw"})
    new_menu_references["aa"].aa_state[v].delayed_method = ui.new_combobox( tab,place,light_blue .. new_streng .. white .."delayed method\n" .. v,{"simple","advanced"})
    new_menu_references["aa"].aa_state[v].gs_bodyyawadd = ui.new_slider(tab,place,"\n" .. light_blue .. new_streng .. white .. "body yaw\n" .. v, -180, 180, 0)

    new_menu_references["aa"].aa_state[v].pedro_aas2 = { ui.new_slider(tab,place, light_blue .. new_streng .. white .."jitter way 1 \n" .. k, -180, 180, 0),ui.new_slider(tab,place, "jitter way 2\n" .. k, -180, 180, 0)
    ,ui.new_slider(tab,place,light_blue .. new_streng .. white .. "jitter way 3 \n".. k, -180, 180, 0),ui.new_slider(tab,place,light_blue .. new_streng .. white .. "jitter way 4 \n" .. k, -180, 180, 0)
    ,ui.new_slider(tab,place, light_blue .. new_streng .. white .."jitter way 5 \n".. k, -180, 180, 0),ui.new_slider(tab,place,light_blue .. new_streng .. white .. "jitter way 6\n" .. k, -180, 180, 0)
    ,ui.new_slider(tab,place, light_blue .. new_streng .. white .."jitter way 7 \n".. k, -180, 180, 0),ui.new_slider(tab,place,light_blue .. new_streng .. white .. "jitter way 8\n" .. k, -180, 180, 0)
    ,ui.new_slider(tab,place, light_blue .. new_streng .. white .."jitter way 9 \n" .. k, -180, 180, 0),ui.new_slider(tab,place,light_blue .. new_streng .. white .. "jitter way 10\n" .. k, -180, 180, 0),ui.new_slider(tab,place, "jitter way 11\n".. k, -180, 180, 0)
    ,ui.new_slider(tab,place,light_blue .. new_streng .. white .. "jitter way 12\n".. k, -180, 180, 0)}

    if k ~= "manual" and k ~= "fakelag" and k ~= "Legit" then
        new_menu_references["aa"].aa_state[v].enabled_exploit = ui.new_checkbox(tab,place,light_blue .. new_streng .. white .."enable defensive\n " .. v)
        new_menu_references["aa"].aa_state[v].enabled_defensive_force = ui.new_checkbox(tab,place,light_blue .. new_streng .. white .."force defensive\n " .. v)
        new_menu_references["aa"].aa_state[v].pitch_defensive = ui.new_combobox(tab,place,light_blue .. new_streng .. white .."pitch defensive\n" .. v,{"off", "up", "random","zero", "custom"})
        new_menu_references["aa"].aa_state[v].pitch_defensive_slider = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "custom pitch defensive\n" .. v, -89, 89,0)
        new_menu_references["aa"].aa_state[v].yaw_defensive = ui.new_combobox(tab,place,light_blue .. new_streng .. white .."yaw defensive\n" .. v,{"off", "180", "spin"})
        new_menu_references["aa"].aa_state[v].yawadd_defensive = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "add defensive\n" .. v, -180, 180,0)
        new_menu_references["aa"].aa_state[v].skitter_defensive = ui.new_checkbox(tab,place,light_blue .. new_streng .. white .."skitter defensive\n " .. v)
        new_menu_references["aa"].aa_state[v].skitter_slider_defensive = ui.new_slider(tab,place,light_blue .. new_streng .. white .. "skitter add defensive\n" .. v, -180, 180,0)
    end

    brute_stage.brute[v].missed_bullets = 0
end

for f = 1,4 do
    new_menu_references["bruteforce"][f] = ui.new_slider(tab,place, "bruteforce stage " .. f .. "\n" .. f, -180, 180, 0)
end

local jitter_add = ui.new_button(tab,place,"add jitter",function()
    local get_value = new_menu_references["aa"].aa_state[ui.get(new_menu_references["aa"].aa_state_menu)].jway_counter
    local nigga = ui.get(get_value)

    if nigga >= 12 then
        print("Can't go over 12 jitter angles")
        return 
    end

    ui.set(get_value,nigga + 1)
end)

local jitter_remove = ui.new_button(tab,place,"remove jitter",function()
    local get_value = new_menu_references["aa"].aa_state[ui.get(new_menu_references["aa"].aa_state_menu)].jway_counter
    local nigga = ui.get(get_value)

    if nigga <= 2 then
        print("Can't go lower than 2 jitter angles")
        return 
    end

    ui.set(get_value,nigga - 1)
end)

local function get_velocity(player)
    local x, y, z = entity.get_prop(player, "m_vecVelocity")
    if x == nil then
        return
    end
    return math.sqrt(x * x + y * y + z * z)
end

local function clamp(value, minVal, maxVal)
    return math.max(minVal, math.min(value, maxVal))
end



local prev_simulation_time = 0
function aa_functions:sim_diff() 
    local current_simulation_time = math.floor(0.5 + (entity.get_prop(entity.get_local_player(), "m_flSimulationTime") / globals.tickinterval())) 
    local diff = current_simulation_time - prev_simulation_time
    prev_simulation_time = current_simulation_time
    return diff
end

local tick = 0
local ticker = 0
local lerp_alpha = 0
function visual_functions:defensive_indicator()

    visual_functions.ticks = aa_functions.sim_diff()
    if ui.get(new_menu_references["visuals"].enable_defensive_indicator) then

        local w,h = client.screen_size()
        
    
        local defensive = {ui.get(new_menu_references["visuals"].indicator_defensive_color)}
        if visual_functions.ticks < 0 and ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) and not ui.get(menu_reference.fakeduck) then
            tick = globals.tickcount()
            visual_functions.defensive_ready = true
            ticker = 0
            lerp_alpha = 255
        end
    
        if visual_functions.defensive_ready == true then
    
            local expand = visual_functions.is_defensive and 98 or ticker * 98 / 175
    
            renderer.text(w / 2 , visual_functions.is_defensive and h / 2  * 0.5 - 20 or h / 2  * 0.5 - 10 ,255,255,255,lerp_alpha,"c",0,visual_functions.is_defensive and "defensive" or "- defensive -")
            if visual_functions.is_defensive then
                renderer.text(w / 2 , h / 2  * 0.5 - 10 ,255,255,255,lerp_alpha,"c+",0,"∞")
            end
            renderer.rectangle(w / 2 - 50, h / 2  * 0.5, 100, 4, 12, 12, 12,lerp_alpha <= 150 and lerp_alpha or 150)
            renderer.rectangle(w / 2 - 49, h / 2  * 0.5 + 1,expand,2,defensive[1],defensive[2],defensive[3],lerp_alpha)
    
           

            if ticker > 155 then 
                lerp_alpha = lerp(lerp_alpha,0,globals.frametime() * 30)

                if lerp_alpha < 20 then
                    visual_functions.defensive_ready = false
                end
            end
            ticker = ticker + 1
        end
    end
end

function visual_functions:slow_indicator()

    if not ui.get(new_menu_references["visuals"].slow_indicator) then return end

    local NOVINHA_QUEISSO = entity.get_prop(entity.get_local_player(),"m_flVelocityModifier") * 100

    if NOVINHA_QUEISSO < 100 then

        local sizer = vector(client.screen_size())
    
        local size_bar = NOVINHA_QUEISSO * 98 / 100

        local defensive = {ui.get(new_menu_references["visuals"].indicator_slow_color)}
        
        renderer.text(sizer.x /2,sizer.y/2- 240,230,230,230,255,"c",nil,string.format("slowed by %s",math.floor(100 - NOVINHA_QUEISSO)) .. "%")
        renderer.rectangle(sizer.x / 2 - 50,sizer.y/2 - 232,100,4,12,12,12,180)
        renderer.rectangle(sizer.x / 2-49,sizer.y/2 - 231,size_bar,2,defensive[1],defensive[2],defensive[3],defensive[4])
    
    end
end

function aa_functions:manual_anti_aim()
    if ui.get(new_menu_references["aa"].aa_state["Manual"].enabled) then
        
        ui.set(new_menu_references["aa"].aa_state["Manual"].yaw,"180")
        if ui.get(new_menu_references["keys"].manual_right) and aa.last_pressed + 0.2 < globals.curtime() then
            aa.manual_state = aa.manual_state == "right" and "reset" or "right"
            aa.last_pressed = globals.curtime()
        elseif ui.get(new_menu_references["keys"].manual_left) and aa.last_pressed + 0.2 < globals.curtime() then
            aa.manual_state = aa.manual_state == "left" and "reset" or "left"
            aa.last_pressed = globals.curtime()
        elseif ui.get(new_menu_references["keys"].manual_forward) and aa.last_pressed + 0.2 < globals.curtime() then
            aa.manual_state = aa.manual_state == "forward" and "reset" or "forward"
            aa.last_pressed = globals.curtime()
        elseif ui.get(new_menu_references["keys"].manual_reset) and aa.last_pressed + 0.2 < globals.curtime() then
            aa.manual_state = "reset"
            aa.last_pressed = globals.curtime()
        elseif aa.last_pressed > globals.curtime() then
            aa.last_pressed = globals.curtime()
        end
    
        if aa.manual_state ~= "reset" then
            ui.set(menu_reference.yawbase,"At targets")
        end

        if aa.manual_state == "right" then
            ui.set(menu_reference.yaw[1],"180")
            ui.set(menu_reference.yaw[2],90)
        elseif aa.manual_state == "left" then
            ui.set(menu_reference.yaw[1],"180")
            ui.set(menu_reference.yaw[2],-90)
        elseif aa.manual_state == "forward" then
            ui.set(menu_reference.yaw[1],"180")
            ui.set(menu_reference.yaw[2],-180)
        end
    end
end

function aa_functions.anti_brute_bullet_impact(event)

    local me = entity.get_local_player()

	if not entity.is_alive(me) then return end

    if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyaw ) ~= "anti bruteforce" then return end

    if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw) == "l & r" or ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw) == "delayed" or ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw) == "jittery" then
        return
    end

	local shooter_id = event.userid
	local shooter = client.userid_to_entindex(shooter_id)

	if not entity.is_enemy(shooter) or entity.is_dormant(shooter) then return end

	local lx, ly, lz = entity.hitbox_position(me, "head_0")
	
	local ox, oy, oz = entity.get_prop(me, "m_vecOrigin")
	local ex, ey, ez = entity.get_prop(shooter, "m_vecOrigin")

	local dist = ((event.y - ey)*lx - (event.x - ex)*ly + event.x*ey - event.y*ex) / math.sqrt((event.y-ey)^2 + (event.x - ex)^2)
    
	
	if math.abs(dist) <= 35 and globals.curtime() - brute_stage.last_miss > 0.015 then
        brute_stage.last_miss = globals.curtime()

        
        brute_stage.brute[aa_functions.aa_number].missed_bullets = brute_stage.brute[aa_functions.aa_number].missed_bullets + 1

        if  brute_stage.brute[aa_functions.aa_number].missed_bullets >= 5 then 
            brute_stage.brute[aa_functions.aa_number].missed_bullets = 1
            print("Back to stage 1 | Stages were superior than 4")
        end
        print("anti-bruteforce [" .. aa_functions.aa_number ..  "] stage:" .. brute_stage.brute[aa_functions.aa_number].missed_bullets)

    end
    
end

function aa_functions:anti_brute_anti_aim()

    if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyaw) ~= "anti bruteforce" then return end

    if not entity.is_alive(entity.get_local_player()) then return end

    if brute_stage.brute[aa_functions.aa_number].missed_bullets >= 1 then

        if  brute_stage.brute[aa_functions.aa_number].missed_bullets == 1 then
            ui.set(menu_reference.bodyyaw[1],"Static")
            ui.set(menu_reference.bodyyaw[2],ui.get(new_menu_references["bruteforce"][1]))
        elseif  brute_stage.brute[aa_functions.aa_number].missed_bullets == 2 then
            ui.set(menu_reference.bodyyaw[1],"Static")
            ui.set(menu_reference.bodyyaw[2],ui.get(new_menu_references["bruteforce"][2]))
        elseif  brute_stage.brute[aa_functions.aa_number].missed_bullets == 3 then
            ui.set(menu_reference.bodyyaw[1],"Static")
            ui.set(menu_reference.bodyyaw[2],ui.get(new_menu_references["bruteforce"][3]))
        elseif  brute_stage.brute[aa_functions.aa_number].missed_bullets == 4 then
            ui.set(menu_reference.bodyyaw[1],"Static")
            ui.set(menu_reference.bodyyaw[2],ui.get(new_menu_references["bruteforce"][4]))
        end
    else
        ui.set(menu_reference.bodyyaw[1],"Jitter")
        ui.set(menu_reference.bodyyaw[2],1)
    end

end

function aa_functions:anti_knife()

    if ui.get(new_menu_references["aa"].anti_kniv)then
        local players = entity.get_players(true)
        local opos = vector(entity.get_prop(entity.get_local_player(), "m_vecOrigin"))
        local yaw, yaw_slider = ui.reference("AA", "Anti-aimbot angles", "Yaw")
        local pitch = ui.reference("AA", "Anti-aimbot angles", "Pitch")

        for i = 1, #players do
            local plpos = vector(entity.get_prop(players[i], "m_vecOrigin"))
            
            local weapon = entity.get_player_weapon(players[i])

            if entity.get_classname(weapon) == "CKnife" and opos:dist(plpos) < 200 then
                local eyepos = vector(client.eye_position())
                local hxpl = vector(entity.hitbox_position(players[i],4))
              
                local fraction, entindex_hit = client.trace_line(players[i], hxpl.x, hxpl.y, hxpl.z,eyepos.x,eyepos.y, eyepos.z)

                if entindex_hit == entity.get_local_player() or fraction == 1 then
                    ui.set(menu_reference.yawbase,"At targets")
                    ui.set(menu_reference.yaw[1],"180")
                    ui.set(menu_reference.yaw[2],180)
                    ui.set(menu_reference.yawjitter[1],"Off")
                    ui.set(menu_reference.yawjitter[2],60)
                    ui.set(menu_reference.bodyyaw[1],"jitter")
                    ui.set(menu_reference.bodyyaw[2],0)
                    ui.set(pitch, "Default")
                end
            end
        end
    end
end


function aa_functions:legit_aa(cmd)

    if not ui.get(new_menu_references["aa"].aa_state["Legit"].enabled) then return end

    local in_use = cmd.in_use == 1
    local in_bombsite = entity.get_prop(entity.get_local_player(), "m_bInBombZone") > 0
    local nTeam = entity.get_prop(entity.get_local_player(), "m_iTeamNum")
    lx,ly,lz = entity.get_origin(entity.get_local_player())
    ui.set(new_menu_references["aa"].aa_state["Legit"].yaw,"180")

    local from = vector(client.eye_position())
	local to = from + vector():init_from_angles(client.camera_angles()) * 1024

    local tr = trace.line(from, to, { skip = entity.get_local_player(), mask = "MASK_SHOT" })

    local local_pos = vector(entity.get_origin(entity.get_local_player()))

    if tr.fraction >= 1 then
        tr.entindex = 0
    end
   
   if entity.get_classname(tr.entindex) ~= "CWorld" and entity.get_classname(tr.entindex) ~= "CCSPlayer" and entity.get_classname(tr.entindex) ~= "CFuncBrush" and entity.get_classname(tr.entindex) ~= "CBaseButton" and entity.get_classname(tr.entindex) ~= "CDynamicProp" and entity.get_classname(tr.entindex) ~= "CPhysicsPropMultiplayer" and entity.get_classname(tr.entindex) ~= "CBaseEntity" and entity.get_classname(tr.entindex) ~= "CC4" then 
      
        local not_wepwep = vector(entity.get_origin(tr.entindex))

        if entity.get_classname(tr.entindex) == "CPropDoorRotating" or (entity.get_classname(tr.entindex) == "CHostage" and nTeam == 3) then
            
            if local_pos:dist(not_wepwep) < 125 then

                return false
            end

        elseif entity.get_classname(tr.entindex) ~= "CPropDoorRotating" and entity.get_classname(tr.entindex) ~= "CHostage" then

            if local_pos:dist(not_wepwep) < 200 then
                return false
            end
        end
   end
  
    local bomb_table    = entity.get_all("CPlantedC4")
    local bomb_planted  = #bomb_table > 0
    local bomb_distance = 100

    if bomb_planted then
        local bomb_entity = bomb_table[#bomb_table]
        local bomb_pos = vector(entity.get_origin(bomb_entity))
        bomb_distance = local_pos:dist(bomb_pos)
    end

    local defusing = bomb_distance < 50 and nTeam == 3 and aa_functions.bomb_was_bombed == false and aa_functions.bomb_was_defused == false

    if defusing then return false end

    if in_use then
        cmd.in_use = 0
        return true
    end
    return false
end

function aa_functions:static_in_aerophobic(cmd)

    if not ui.get(new_menu_references["aa"].safe_dangerous) then return end
    local local_player = entity.get_local_player()

    if not entity.is_alive(local_player) then return end
    local on_ground = bit.band(entity.get_prop(local_player, "m_fFlags"), 1) == 1 and cmd.in_jump == 0
    local weapon_ent = entity.get_player_weapon(local_player)
    if weapon_ent == nil then return end

    local weapon_idx = entity.get_prop(weapon_ent, "m_iItemDefinitionIndex")
    local weapon = csgo_weapons[weapon_idx]
    if weapon_ent == nil then return end

    if weapon.type == "knife" or weapon.type == "taser" then
        if not on_ground or (not on_ground and cmd.in_duck == 1) then

            ui.set(menu_reference.yawbase,"At targets")
            ui.set(menu_reference.yaw[1],"180")
            ui.set(menu_reference.yaw[2],0)
            ui.set(menu_reference.yawjitter[1],"Off")
            ui.set(menu_reference.yawjitter[2],0)
            ui.set(menu_reference.bodyyaw[1],"Static")
            ui.set(menu_reference.bodyyaw[2],0)
        end
    end
end

local old_def_state = "Stand"
function aa_functions:defensive_setup(cmd)

    if not ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].enabled) then return end

    visual_functions.is_defensive = false

    aa_functions.old_weapon =  aa_functions.actual_weapon
    aa_functions.actual_weapon = entity.get_player_weapon(entity.get_local_player())
    
    if aa_functions.old_weapon ~= aa_functions.actual_weapon then
        aa_functions.to_start = true
    end
    
    if entity.get_player_weapon(entity.get_local_player()) ~= aa_functions.old_weapon then
        aa_functions.actual_tick = 0
        aa_functions.to_start = true
    end
    
    if aa_functions.to_start == true and aa_functions.actual_tick < 100 then
        aa_functions.actual_tick = aa_functions.actual_tick + 1
    elseif aa_functions.actual_tick >= 100 then
        aa_functions.actual_tick = 0
        aa_functions.to_start = false
    end
    
    aa_functions.old_weapon = entity.get_player_weapon(entity.get_local_player())

    if aa_functions.can_defensive then
        if ui.get(new_menu_references["aa"].aa_state[old_def_state].enabled_exploit) ~= ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].enabled_exploit) then
            aa_functions.can_defensive = false
        end
    end
    old_def_state = aa_functions.aa_number

    if aa_functions.can_defensive  then
        aa_functions.def_ticks = 27
        aa_functions.can_defensive = false
    end

       if aa_functions.def_ticks > 0 then
          aa_functions.def_ticks = aa_functions.def_ticks - 1
       else
         aa_functions.can_defensive = false
       end

    if aa_functions.to_start == true then return end

    if aa_functions.aa_number ~= "manual" and aa_functions.aa_number ~= "Legit" and aa_functions.aa_number ~= "fakelag" then
        if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].enabled_exploit) and (ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) or ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2])) and not ui.get(menu_reference.fakeduck)  then
           
            if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].enabled_defensive_force) then 
                cmd.force_defensive = true
            end
           if cmd.force_defensive == true then visual_functions.is_defensive = true end

           if cmd.force_defensive then
                if globals.tickcount() % 10 <= 2 then
                    cmd.force_defensive = false
                    return
                end
           end

           if aa_functions.def_ticks > 0 or cmd.force_defensive == true then 
            if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch_defensive) == "custom" then
                ui.set(menu_reference.pitch[2], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch_defensive_slider))
            end
            if  ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch_defensive) == "zero" then
                ui.set(menu_reference.pitch[1],"Off")
           elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch_defensive) ~= "off" or ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch_defensive) ~= "custom" then
               ui.set(menu_reference.pitch[1],ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch_defensive))
           end
           
           if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw_defensive) ~= "off" then
               ui.set(menu_reference.yaw[1],ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw_defensive))
               ui.set(menu_reference.yaw[2],ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawadd_defensive))
           end
   
           if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].skitter_defensive) then
               ui.set(menu_reference.yawjitter[1],"Skitter")
               ui.set(menu_reference.yawjitter[2],ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].skitter_slider_defensive))
           end
           end
        end
    end
end

local QUEISSO = false
local current_tickcount = 0
local side = nil
local setting_secret_1 = nil
local setting_secret_2 = nil
function aa_functions:setup(cmd)

    if not entity.is_alive(entity.get_local_player()) then return end

    local lp = entity.get_local_player()
    local on_ground = bit.band(entity.get_prop(entity.get_local_player(), "m_fFlags"), 1) == 1 and cmd.in_jump == 0
    local is_slow = ui.get(menu_reference.slow[1]) and ui.get(menu_reference.slow[2])

    local bodyyaw = entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11) * 120 - 60

    if ui.get(new_menu_references["aa"].aa_state["Legit"].enabled) and aa_functions:legit_aa(cmd) then
        aa_functions.aa_number = "Legit"
    elseif  ui.get(new_menu_references["aa"].aa_state["Manual"].enabled) and aa.manual_state ~= "reset" then
        aa_functions.aa_number = "Manual"
    elseif  ui.get(new_menu_references["aa"].aa_state["Fakelag"].enabled) and not ui.get(menu_reference.dt[2]) and not ui.get(menu_reference.os[2]) then
        aa_functions.aa_number = "Fakelag"
    elseif on_ground and cmd.in_duck == 1 then
        aa_functions.aa_number = "Duck"
    elseif not on_ground and cmd.in_duck == 1 then
        aa_functions.aa_number = "Air duck"
    elseif not on_ground then
        aa_functions.aa_number = "In-Air"
    elseif is_slow then
        aa_functions.aa_number = "Slow"
    elseif on_ground and get_velocity(lp) < 3 then
        aa_functions.aa_number = "Stand"
    elseif on_ground and get_velocity(lp) >= 3 then
        aa_functions.aa_number = "Walk"
    end

    if cmd.chokedcommands == 0 then
        side = bodyyaw > 0 and true or false
        
        if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitter) == "jitter ways" then
       
            aa_functions.jitter_way_number = aa_functions.jitter_way_number + 1 
        
        
            if aa_functions.jitter_way_number > ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].jway_counter) then
                aa_functions.jitter_way_number = 1
            end
        elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitter) == "sway" then
    
           
          
                ui.set(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaym,math.min(ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaym),ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaymx)))
                local number = ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swayspeed) 
                local number_to_add = new_menu_references["aa"].aa_state[aa_functions.aa_number].to_sway and number or -number
                
                new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value = new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value + number_to_add
                if new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value < ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaym) then
                    new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value = ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaym)
                elseif new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value > ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaymx) then
                    new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value = ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaymx)
                end
            
                    if new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value >= ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaymx) and new_menu_references["aa"].aa_state[aa_functions.aa_number].to_sway then
                        new_menu_references["aa"].aa_state[aa_functions.aa_number].to_sway = false
                    elseif new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value <= ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].swaym) and not new_menu_references["aa"].aa_state[aa_functions.aa_number].to_sway  then
                        new_menu_references["aa"].aa_state[aa_functions.aa_number].to_sway = true
                    end
        end
    end



    if aa_functions.aa_number ~= "Legit" and aa_functions.aa_number ~= "manual" then
        if globals.tickcount() > current_tickcount + ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].ticker_slider)  then
            if cmd.chokedcommands == 0 then
               aa_functions.to_jitter = not aa_functions.to_jitter
               current_tickcount = globals.tickcount()
            end
        elseif globals.tickcount() <  current_tickcount then
            current_tickcount = globals.tickcount()
        end

    end
    
    ui.set(menu_reference.enabled,ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].enabled))
  
    ui.set(menu_reference.pitch[1], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch))

    ui.set(menu_reference.pitch[2], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pitch_slider))
        
    
    ui.set(menu_reference.yawbase, ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawbase))

    if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw) == "jittery" then
        ui.set(menu_reference.yaw[1], "180")
        if cmd.chokedcommands == 0 then
            aa_functions.random_extrapolated = client.random_int(0,1) == 1
            ui.set(menu_reference.yaw[2],  aa_functions.random_extrapolated and ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawaddleft) or ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawadd))
        end
        elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw) == "delayed" then

        ui.set(menu_reference.yaw[1], "180")
        if cmd.chokedcommands == 0 then
            ui.set(menu_reference.yaw[2],  aa_functions.to_jitter and ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawaddleft) or ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawadd))
        end
        elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw) == "l & r" then
        ui.set(menu_reference.yaw[1], "180")
        if cmd.chokedcommands == 0 then
            if side ~= nil then 
                ui.set(menu_reference.yaw[2], side and ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawaddleft) or ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawadd))
            end
        end
    
    else
        ui.set(menu_reference.yaw[1], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yaw))
        ui.set(menu_reference.yaw[2], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawadd))
    end

    if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitter) == "jitter ways" then
        
        ui.set(menu_reference.yawjitter[1],"Center")
        ui.set(menu_reference.yawjitter[2], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].pedro_aas2[aa_functions.jitter_way_number]))
        
    elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitter) == "sway" then
        
        ui.set(menu_reference.yawjitter[1],"Center")
        
            ui.set(menu_reference.yawjitter[2], new_menu_references["aa"].aa_state[aa_functions.aa_number].sway_value)
        
    elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitter) == "l & r" then
        --if cmd.chokedcommands == 0 then
            ui.set(menu_reference.yawjitter[1], "Center")
            ui.set(menu_reference.yawjitter[2], side and ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitteradd) or ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitteradd2))
       -- end
    else
        ui.set(menu_reference.yawjitter[1], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitter))
        ui.set(menu_reference.yawjitter[2], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].yawjitteradd))
    end

    if cmd.chokedcommands == 0 then
        if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyaw) == "anti bruteforce" then
            aa_functions.anti_brute_anti_aim()
        elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyaw) == "auto jitter" then
            ui.set(menu_reference.bodyyaw[1], "Jitter")
            ui.set(menu_reference.bodyyaw[2], ui.get(menu_reference.yawjitter[2]))
        elseif ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyaw) == "delayed yaw" then
            if ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].delayed_method) == "simple" then
                ui.set(menu_reference.bodyyaw[1], "Static")
                ui.set(menu_reference.bodyyaw[2],aa_functions.to_jitter and -115 or 115)
            else
                ui.set(menu_reference.bodyyaw[1], "Static")
                ui.set(menu_reference.bodyyaw[2], ui.get(menu_reference.yaw[2]))
            end
        else
            ui.set(menu_reference.bodyyaw[1], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyaw))
            ui.set(menu_reference.bodyyaw[2], ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].gs_bodyyawadd))
        end
    end
    

    if ui.get(new_menu_references["keys"].global_fs) and aa_functions.aa_number ~= "Legit" and aa_functions.aa_number ~= "manual" and not table_contains(ui.get(new_menu_references["aa"].freestanding_disabler),aa_functions.aa_number) then
        ui.set(menu_reference.freestand[1],true)
        ui.set(menu_reference.freestand[2],"Always on")
      
    elseif not ui.get(new_menu_references["keys"].global_fs) or aa_functions.aa_number == "Legit" or aa_functions.aa_number == "manual" or table_contains(ui.get(new_menu_references["aa"].freestanding_disabler),aa_functions.aa_number) then
        ui.set(menu_reference.freestand[1],false)
    end
    
    aa_functions:manual_anti_aim()
    aa_functions:static_in_aerophobic(cmd)
    aa_functions:defensive_setup(cmd)
    aa_functions:anti_knife()
end

local text_anim = {0,0,0,0,0}
local add_y = {0,0}
local bottom = 0
local addition = 0 
function visual_functions:indicators()

   
    local w,h = client.screen_size()
    local scoped = entity.get_prop(entity.get_local_player(),"m_bIsScoped") == 1 and true or false
    --local scoped_and_box = ui.get(new_menu_references["visuals"].scoped_animation) and scoped
    local indicator_color = { ui.get(new_menu_references["visuals"].indicator_color) }

    renderer.text(w / 2 + math.ceil(text_anim[1])-1,h / 2 + 24,indicator_color[1],indicator_color[2],indicator_color[3],indicator_color[4],"c-",0,"S  T  A  R  L  I  G  H  T")
   
    if ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) then 
        renderer.text(w / 2 + math.ceil(text_anim[2])-1,h / 2 + 24 + math.ceil(add_y[1]),255,255,255,anti_aim_funcs.get_double_tap() and 255 or 130 ,"c-",0,"DT")
    end

    if ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) and not ui.get(menu_reference.dt[2]) then
        renderer.text(w / 2 + math.ceil(text_anim[3])-1,h / 2 + 24+ math.ceil(add_y[2]),255,255,255,255 ,"c-",0,"HS")
    end

    if ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) then
        addition = add_y[1]
    elseif ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) and not ui.get(menu_reference.dt[2]) then
        addition = add_y[2]
    else 
        addition = lerp(addition,0,globals.frametime() * 15)
    end
    

    renderer.text(w / 2 - 2 + math.ceil(text_anim[4]) ,h / 2 + 33 + math.ceil(addition),255,255,255,ui.get(menu_reference.freestand[1]) and 255 or 130,"c-",0,"FS")
    renderer.text(w / 2 - 18 + math.ceil(text_anim[4]),h / 2 + 33 + math.ceil(addition),255,255,255,ui.get(menu_reference.forcebaim) and 255 or 130,"c-",0,"BAIM")
    renderer.text(w / 2 + 16 +  math.ceil(text_anim[4]),h / 2 + 33 + math.ceil(addition),255,255,255,ui.get(menu_reference.quickpeek[2]) and ui.get(menu_reference.quickpeek[1]) and 255 or 130,"c-",0,"QUICK")

    local text = {"S  T  A  R  L  I  G  H  T","DT","HS","BAIM"}
    for i = 1,#text do
        local measure = vector(renderer.measure_text("c-", text[i]))
        --local can2 = scoped_and_box

        --[[if i == 4 then
            text_anim[i] = lerp(text_anim[i],can2 and measure.x/2 + 19 or 0,globals.frametime() * 15)
        else
            text_anim[i] = lerp(text_anim[i],can2 and measure.x/2 + 2 or 0,globals.frametime() * 15)
        end]]

        if i < 3 then
            if i == 1 then
                add_y[i] = lerp(add_y[i],(ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2])) and 9 or 0,globals.frametime() * 15)
            else
                local can = ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) and not ui.get(menu_reference.dt[2])
                add_y[i] = lerp(add_y[i],can and 9 or 0,globals.frametime() * 15)
            end
        end
    end
end

local function text_plus(update_tick,text,speed)
    string_size = string.len(text)
    
    if update_tick < #text then
        update_tick = update_tick + 1 * globals.frametime() * speed
    else
        update_tick = update_tick
    end

    string_minus = string_size - string_size + update_tick

    text_render = string.sub(text,1,string_minus)

    return update_tick,text_render
end


local last_state = "Stand"
local text_index,text_string = 0,"Stand"
function visual_functions:indicators2()
    local w,h = client.screen_size()
    local scoped = entity.get_prop(entity.get_local_player(),"m_bIsScoped") == 1 and true or false
    --local scoped_and_box = ui.get(new_menu_references["visuals"].scoped_animation) and scoped
    local indicator_color = { ui.get(new_menu_references["visuals"].indicator_color) }

    if last_state ~= aa_functions.aa_number then
        if #last_state < #aa_functions.aa_number then
            text_index = #last_state
        else
            text_index = #aa_functions.aa_number / 2
        end
    end

    last_state = aa_functions.aa_number


    text_index,text_string = text_plus(text_index,aa_functions.aa_number,50)
    

    renderer.text(w / 2 + math.ceil(text_anim[1]),h / 2 + 24,indicator_color[1],indicator_color[2],indicator_color[3],indicator_color[4],"c",0,"starlight")
    renderer.text(w / 2 + math.ceil(text_anim[2]),h / 2 + 36,255,255,255,255,"c",0,"- " .. text_string .. " -")
   
    if ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) then 
        renderer.text(w / 2 + math.ceil(text_anim[3]),h / 2 + 36 + math.ceil(add_y[1]),255,255,255,anti_aim_funcs.get_double_tap() and 255 or 130 ,"c",0,"double tap")
    end

    if ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) and not ui.get(menu_reference.dt[2]) then
        renderer.text(w / 2 + math.ceil(text_anim[4]),h / 2 + 36+ math.ceil(add_y[2]),255,255,255,255 ,"c",0,"on shot")
    end

    if ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) then
        addition = add_y[1]
    elseif ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) and not ui.get(menu_reference.dt[2]) then
        addition = add_y[2]
    else 
        addition = lerp(addition,0,globals.frametime() * 15)
    end



    renderer.text(w / 2 + math.ceil(text_anim[5]) ,h / 2 + 48 + math.ceil(addition),255,255,255,ui.get(menu_reference.freestand[1]) and 255 or 130,"c",0,"fs")
    renderer.text(w / 2 - 18 + math.ceil(text_anim[5]),h / 2 + 48 + math.ceil(addition),255,255,255,ui.get(menu_reference.forcebaim) and 255 or 130,"c",0,"baim")
    renderer.text(w / 2 + 18 +  math.ceil(text_anim[5]),h / 2 + 48 + math.ceil(addition),255,255,255,ui.get(menu_reference.quickpeek[2]) and ui.get(menu_reference.quickpeek[1]) and 255 or 130,"c",0,"quick")

    local text = {"starlight","- " .. text_string .. " -","double tap","on shot","baim"}
    for i = 1,#text do
        local measure = vector(renderer.measure_text("c", text[i]))
        --local can2 = scoped_and_box

        --[[if i == 5 then
            text_anim[i] = lerp(text_anim[i],can2 and measure.x/2 + 19 or 0,globals.frametime() * 15)
        else
            text_anim[i] = lerp(text_anim[i],can2 and measure.x/2 + 2 or 0,globals.frametime() * 15)
        end]]

        if i < 3 then
            if i == 1 then
                add_y[i] = lerp(add_y[i],(ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2])) and 12 or 0,globals.frametime() * 15)
            else
                local can = ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) and not ui.get(menu_reference.dt[2])
                add_y[i] = lerp(add_y[i],can and 12 or 0,globals.frametime() * 15)
            end
        end
    end
end


function visual_functions:indicators3()

    visual_functions.indicator_bottom = 0
    local w,h = client.screen_size()
    local indicator_color = { ui.get(new_menu_references["visuals"].indicator_color) }

    renderer.text(w / 2 + visual_functions.offset,h / 2 + 25,indicator_color[1],indicator_color[2],indicator_color[3],indicator_color[4],"c-",0,string.format("LUH\a96C83C%02XGËEK",indicator_color[4],indicator_color[4]))
    
    if ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) then
        visual_functions.indicator_bottom = visual_functions.indicator_bottom + 10
        visual_functions.dt_indicator_animation = lerp(visual_functions.dt_indicator_animation,visual_functions.indicator_bottom,globals.frametime() * 15)
        renderer.text(w / 2 + visual_functions.offset,h / 2 + 25 + visual_functions.dt_indicator_animation,255,255,255,anti_aim_funcs.get_double_tap() and 255 or 50, "c-", 0,"DOUBLË")
        
    end

    if ui.get(menu_reference.os[1]) and ui.get(menu_reference.os[2]) then
        visual_functions.indicator_bottom = visual_functions.indicator_bottom + 10
        visual_functions.hs_indicator_animation = lerp(visual_functions.hs_indicator_animation,visual_functions.indicator_bottom,globals.frametime() * 15)

        renderer.text(w / 2 + visual_functions.offset,h / 2 + 25 + visual_functions.hs_indicator_animation, 255,255,255,not ui.get(menu_reference.dt[2]) and 255 or 50, "c-", 0, "SHHHH")
        
        
    end
    
    bottom = lerp(bottom,visual_functions.indicator_bottom + 10,globals.frametime() * 15)
    renderer.text(w / 2 + visual_functions.offset ,h / 2 + 25 + bottom,255,255,255,ui.get(menu_reference.freestand[1]) and 255 or 50,"c-",0,"FS")
    renderer.text(w / 2 - 15 + visual_functions.offset,h / 2 + 25 + bottom,255,255,255,ui.get(menu_reference.forcebaim) and 255 or 50,"c-",0,"BAIM")
    renderer.text(w / 2 + 18 +  visual_functions.offset,h / 2 + 25 + bottom,255,255,255,ui.get(menu_reference.quickpeek[2]) and ui.get(menu_reference.quickpeek[1]) and 255 or 50,"c-",0,"QUICK")


    if not ui.get(menu_reference.dt[2]) then
        visual_functions.dt_indicator_animation = 0
    end

    if not ui.get(menu_reference.os[2]) then
        visual_functions.hs_indicator_animation = 0
    end
end

local DT_Color = {}
function visual_functions:green_dt_skeet_beta()

  
    if ui.get(menu_reference.dt[1]) and ui.get(menu_reference.dt[2]) then
    
       
    
        if visual_functions.ticks <= -1 then
            visual_functions.is_defensive_state = true
        end


        if visual_functions.is_in_attack or visual_functions.in_fire then
            visual_functions.is_defensive_state = false
            visual_functions.is_defensive_ticks = 0
            visual_functions.is_defensive_disable = false
        end


        if visual_functions.is_defensive_state == true then
            
            if  visual_functions.is_defensive_ticks < 100 then
                visual_functions.is_defensive_ticks =  visual_functions.is_defensive_ticks + 1
            elseif  visual_functions.is_defensive_ticks >= 100 then
                visual_functions.is_defensive_state = false
                visual_functions.is_defensive_ticks = 0
            end
        else
            visual_functions.is_defensive_ticks = 0
        end

        if ui.get(menu_reference.fakeduck) then
            visual_functions.is_defensive_disable = false
        end

        if visual_functions.is_defensive_state == true then
            DT_Color = {143,194,21,255}
            visual_functions.is_defensive_disable = true
        elseif not anti_aim_funcs.get_double_tap() then

            DT_Color = {255,0,50,255}
            if visual_functions.ticks >= 0 and visual_functions.is_defensive_disable == true then
                DT_Color = {205,205,205,255}
            end

        elseif anti_aim_funcs.get_double_tap() then
            DT_Color = {205,205,205,255}
            visual_functions.is_defensive_disable = true
        end

    

       renderer.indicator(DT_Color[1], DT_Color[2], DT_Color[3], DT_Color[4], "DT")

       visual_functions.in_fire = false
    end

end

function visual_functions:manual_indicator()

    local w,h = client.screen_size()
    local bodyyaw = entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11) * 120 - 60

    aa.color_left = {12,12,12,130}
    aa.color_right = {12,12,12,130}
    if aa.manual_state == "left" then
        aa.color_left = {ui.get(new_menu_references["visuals"].indicator_manual_color)}
    elseif aa.manual_state == "right" then
        aa.color_right = {ui.get(new_menu_references["visuals"].indicator_manual_color)}
    end

    if ui.get(new_menu_references["visuals"].enable_manual) == "ts" then


        aa.color_body_l = {12,12,12,130}
        aa.color_body_r = {12,12,12,130}
        if bodyyaw < -10 then
            aa.color_body_r = {ui.get(new_menu_references["visuals"].indicator_manual_color)}
        elseif bodyyaw > 10 then
            aa.color_body_l = {ui.get(new_menu_references["visuals"].indicator_manual_color)}
        end
    
        local vel_adap = (ui.get(new_menu_references["visuals"].enable_velocity_adaptive) and get_velocity(entity.get_local_player()) * 45 / 300)  or 0


        renderer.triangle(w / 2 + 55 + vel_adap, h / 2 + 2, w / 2 + 42 + vel_adap, h / 2 - 7, w / 2 + 42 + vel_adap, h / 2 + 11, aa.color_right[1],aa.color_right[2],aa.color_right[3],aa.color_right[4]) 

        renderer.triangle(w / 2 - 55 + -vel_adap, h / 2 + 2, w / 2 - 42 + -vel_adap, h / 2 - 7, w / 2 - 42 + -vel_adap, h / 2 + 11, aa.color_left[1],aa.color_left[2],aa.color_left[3],aa.color_left[4]) 

        renderer.rectangle(w / 2 + 38 + vel_adap, h / 2 - 7, 2, 18, aa.color_body_r[1],aa.color_body_r[2],aa.color_body_r[3],aa.color_body_r[4])
       renderer.rectangle(w / 2 - 40 + -vel_adap, h / 2 - 7, 2, 18,aa.color_body_l[1],aa.color_body_l[2],aa.color_body_l[3],aa.color_body_l[4])
    elseif ui.get(new_menu_references["visuals"].enable_manual) == "minimal" then
    
        local vel_adap = (ui.get(new_menu_references["visuals"].enable_velocity_adaptive) and get_velocity(entity.get_local_player()) * 45 / 300)  or 0
        renderer.text(w / 2 + 35 + vel_adap, h / 2 ,aa.color_right[1],aa.color_right[2],aa.color_right[3],aa.color_right[4],"cb",0,"⮞")
        renderer.text(w / 2 - 35 + -vel_adap, h / 2 ,aa.color_left[1],aa.color_left[2],aa.color_left[3],aa.color_left[4],"cb",0,"⮜")
    end
end

function visual_functions:min_dmg_indicator()

    if ui.get(new_menu_references["visuals"].enable_min_dmg_ovrrd) then

        local w,h = client.screen_size()

        if ui.get(menu_reference.min_dmg_override[1]) and ui.get(menu_reference.min_dmg_override[2]) then
            if ui.get(menu_reference.min_dmg_override[3]) == 0 then
                visual_functions.damage_indi = "auto"
            elseif ui.get(menu_reference.min_dmg_override[3]) > 100 then
                visual_functions.damage_indi = "HP+" .. ui.get(menu_reference.min_dmg_override[3]) - 100
            elseif ui.get(menu_reference.min_dmg_override[3]) <= 100 then
                visual_functions.damage_indi = ui.get(menu_reference.min_dmg_override[3])
            end
           
        elseif  not ui.get(menu_reference.min_dmg_override[1]) or not ui.get(menu_reference.min_dmg_override[2]) then 
    
            if ui.get(menu_reference.minimum_damage) == 0 then
                visual_functions.damage_indi = "auto"
            elseif ui.get(menu_reference.minimum_damage) > 100 then
                visual_functions.damage_indi = "HP+" .. ui.get(menu_reference.minimum_damage) - 100
            elseif ui.get(menu_reference.minimum_damage) <= 100 then
                visual_functions.damage_indi = ui.get(menu_reference.minimum_damage)
            end
        end
    
        renderer.text(w / 2 + 13, h / 2 - 15 , 255, 255, 255, 255,"c-",0,tostring(visual_functions.damage_indi):upper())
    end
end

function visual_functions:desync_indicator()

    if ui.get(new_menu_references["visuals"].enable_desync_indicator) then

        local scoped = entity.get_prop(entity.get_local_player(),"m_bIsScoped") == 1 and true or false
       --local scoped_and_box = ui.get(new_menu_references["visuals"].scoped_animation) and scoped
       --visual_functions.offset2 = lerp(visual_functions.offset2,scoped_and_box and 17 or 0,globals.frametime() * 15)

        local w,h = client.screen_size()
        local desync_color = {ui.get(new_menu_references["visuals"].indicator_desync_color)}

        local desync =  math.floor(math.min(60, (entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11) * 120 - 60)))

        if desync < 0 then
            desync = -desync
        end

        local desync_bar = desync * 26 / 60
    
        --local indicator_set = ui.get(new_menu_references["visuals"].enable_indicators) == "default" and visual_functions.offset or visual_functions.offset2
        --renderer.rectangle(w / 2 - 14 + indicator_set , h / 2 + 13,29,4,0,0,0,255)
        --renderer.gradient(w / 2 - 13 + indicator_set, h / 2 + 14,desync_bar,2,desync_color[1],desync_color[2],desync_color[3],desync_color[4],  desync_color[1],desync_color[2],desync_color[3],0,true)
    end 
end

function misc_functions:global_counter()

    if ui.get(new_menu_references["misc"].enable_clan_tag) then

        if ui.get(menu_reference.clan_tag_spammer) then
            misc_functions.was_ct_enabled_before = true
            ui.set(menu_reference.clan_tag_spammer,false)
        end
        
        misc_functions.clan_tag_change_potential = "change"
        local not_string = globals.tickcount()

        local el_string = tonumber(tostring(not_string):sub(-3))

    
        misc_functions.ct_old_tick = misc_functions.ct_tick
        if el_string < 100 then
            misc_functions.ct_tick = 1
        elseif el_string > 100 and el_string < 155 then
           misc_functions.ct_tick = 2
        elseif el_string > 155 and el_string < 210 then
            misc_functions.ct_tick = 3
        elseif el_string > 210 and el_string < 265 then
            misc_functions.ct_tick = 4
        elseif el_string > 265 and el_string < 320 then
           misc_functions.ct_tick = 5
        elseif el_string > 320 and el_string < 375 then
            misc_functions.ct_tick = 6
        elseif el_string > 375 and el_string < 430 then
            misc_functions.ct_tick = 7
        elseif el_string > 430 and el_string < 485 then
            misc_functions.ct_tick = 8
        elseif el_string > 540 and el_string < 595 then
            misc_functions.ct_tick = 9
        elseif el_string > 595 and el_string < 650 then
            misc_functions.ct_tick = 10
        elseif el_string > 650 and el_string < 705 then
            misc_functions.ct_tick = 11
        elseif el_string > 705 and el_string < 760 then
            misc_functions.ct_tick = 12
        elseif el_string > 760 and el_string < 815 then
            misc_functions.ct_tick = 13
        elseif el_string > 815 and el_string < 870 then
            misc_functions.ct_tick = 14
        elseif el_string > 870 and el_string < 925 then
            misc_functions.ct_tick = 15
        elseif el_string > 925 and el_string < 999 then
            misc_functions.ct_tick = 16
        end

        if misc_functions.ct_old_tick ~= misc_functions.ct_tick then
            client.set_clan_tag(misc_functions.clan_tag[misc_functions.ct_tick])
        end
        

        misc_functions.save_tick = globals.tickcount()
    elseif not ui.get(new_menu_references["misc"].enable_clan_tag) then

        if misc_functions.was_ct_enabled_before == true then
            ui.set(menu_reference.clan_tag_spammer,true)
            misc_functions.was_ct_enabled_before = false
        else
            if misc_functions.save_tick + 5 > globals.tickcount() then return end

            if misc_functions.clan_tag_change_potential == "change" then
                client.set_clan_tag("")
                misc_functions.clan_tag_change_potential = "dont change"
            end
        end
    end
end


local old_sun = {0,0,0}
local old_dist = 100
local old_color
function misc_functions:sunset()
    local sun_prop = entity.get_all('CCascadeLight')[1]
    local new_sun = vector(entity.get_prop(sun_prop, "m_envLightShadowDirection"))
    local color = entity.get_prop(sun_prop, "m_LightColor")
    local color2 = entity.get_prop(sun_prop, "m_LightColorScale")
    old_color = color2

    --client.error_log(old_color)

    if ui.get(new_menu_references["misc"].enable_sun_rise) then
        old_sun = vector(entity.get_prop(sun_prop, "m_envLightShadowDirection"))
        old_dist = vector(entity.get_prop(sun_prop, "m_flMaxShadowDist"))
        entity.set_prop(sun_prop,"m_envLightShadowDirection",ui.get(new_menu_references["misc"].sun_pitch),ui.get(new_menu_references["misc"].sun_yaw),0)
        entity.set_prop(sun_prop,"m_flMaxShadowDist", ui.get(new_menu_references["misc"].sun_distance))
        --entity.set_prop(sun_prop, "m_LightColor", new_menu_references["misc"].sun_color)
    elseif not ui.get(new_menu_references["misc"].enable_sun_rise) then
            entity.set_prop(sun_prop,"m_envLightShadowDirection",old_sun.x,old_sun.y,old_sun.z)
            entity.set_prop(sun_prop,"m_flMaxShadowDist", old_dist)
            --entity.set_prop(sun_prop, "m_LightColor", old_color)
    end
end

client.register_esp_flag("AT", 255, 255, 255, function(ent)
    if table_contains(ui.get(new_menu_references["visuals"].extra_visuals),"at target flag") then
        if ent == client.current_threat() then
            return true
        end
    end
end)


local function rotate_around_center(ang, center, point, point2)
	local s, c = math.sin(ang), math.cos(ang)
	point.x,point.y,point2.x,point2.y=point.x-center.x,point.y-center.y,point2.x-center.x,point2.y-center.y

	local x, y = point.x*c - point.y*s, point.x*s + point.y*c
	local x2, y2 = point2.x*c - point2.y*s, point2.x*s + point2.y*c

	return x+center.x, y+center.y, x2+center.x, y2+center.y
end

local zeus_table = {}
local to_add_y = 0
function visual_functions:zeus_indicator()

    --if not table_contains(ui.get(features.visuals.extra_options),"zeus warning") then return end

    zeus_table = {}
    to_add_y = 0
    local originnigga = vector(entity.get_origin(entity.get_local_player()))


    if ui.get(menu_reference.weapon_text) then
        to_add_y = to_add_y + 15
    end
    if ui.get(menu_reference.weapon_icon) then
        to_add_y = to_add_y + 12
    end
    local zeus_load = images.get_weapon_icon("weapon_taser")

    local pl = entity.get_players(true)
    for i = 1, #pl do
   
        local ent = pl[i]
        local bounding_box = {entity.get_bounding_box(ent)}
        local has_zeus = false

        local weapon_ent = entity.get_player_weapon(ent)
        if weapon_ent == nil then return end

        local weapon = csgo_weapons(weapon_ent)
        if weapon == nil then return end

        for index = 0, 64 do
            local a = entity.get_prop(ent, "m_hMyWeapons", index)
            if a ~= nil then
                local wep = csgo_weapons(a)
                if wep ~= nil and wep.name == "Zeus x27" then
                    has_zeus = true
                end
            end
        end

        local weapon = csgo_weapons[entity.get_prop(weapon_ent, "m_iItemDefinitionIndex")]
        local weapon_icon = images.get_weapon_icon(weapon)
        local weapon_zeus = images.get_weapon_icon("weapon_taser")
        local ent_gin = vector(entity.get_origin(ent))

    end
end


local overwritten = false
local function entity_override()
    local ent_map = entity.get_all("CEnvTonemapController")[1]

    if ui.get(new_menu_references["misc"].enable_nigthermode) and overwritten == false then
        entity.set_prop(ent_map, "m_bUseCustomAutoExposureMin", 1)
        entity.set_prop(ent_map, "m_bUseCustomAutoExposureMax",1)
        entity.set_prop(ent_map, "m_flCustomAutoExposureMin", 0.1)
        entity.set_prop(ent_map, "m_flCustomAutoExposureMax", 0.1)
        overwritten = true
    elseif not ui.get(new_menu_references["misc"].enable_nigthermode) and overwritten then
        entity.set_prop(ent_map, "m_bUseCustomAutoExposureMin", 0)
        entity.set_prop(ent_map, "m_bUseCustomAutoExposureMax",0)
        overwritten = false
    end
end


local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
         return maxValue
    end

    return value
end

local rgba_to_hex = function(b, c, d, e)
    return string.format('%02x%02x%02x%02x', b, c, d, e)
end

local function text_fade_animation(x, y, speed, color1, color2, text)
    local final_text = ''
    local curtime = globals.curtime()
    for i = 0, #text do
        local x = i * 10  
        local wave = math.cos(2 * speed * curtime / 4 + x / 50)
        local color = rgba_to_hex(
            lerp(color1.r, color2.r, clamp(wave, 0, 1)),
            lerp(color1.g, color2.g, clamp(wave, 0, 1)),
            lerp(color1.b, color2.b, clamp(wave, 0, 1)),
            color1.a
        ) 
        final_text = final_text .. ' \a' .. color .. text:sub(i, i) 
    end
    
    renderer.text(x, y, color1.r, color1.g, color1.b, color1.a, "c", nil, final_text)
end


function visual_functions:watermark()
    local w,h = client.screen_size()
    local wm = { ui.get(new_menu_references["visuals"].watermark_color) }
    
    if ui.get(new_menu_references["visuals"].watermark_label) == true then
        text_fade_animation(w - 50,h / 2,5,{r=255,g=255,b=255,a=255},{r=wm[1],g=wm[2],b=wm[3],a=wm[4]},"starlight")
    end
end


local function str_to_sub(input, sep)
    local t = {}
    for str in string.gmatch(input, "([^"..sep.."]+)") do
        t[#t + 1] = string.gsub(str, "\n", "")
    end
    return t
end

local function to_boolean(str)
    if str == "true" or str == "false" then
        return (str == "true")
    else
        return str
    end
end

new_menu_references.config.export_file = ui.new_button(tab,place, "export to clipboard", function()

    local str = ""

    for k,v in ipairs(aa.aa_states) do
       
		str = str
		.. tostring(ui.get(new_menu_references["aa"].aa_state[v].enabled)) .. "|"
		.. tostring(ui.get(new_menu_references["aa"].aa_state[v].pitch)) .. "|"
		.. tostring(ui.get(new_menu_references["aa"].aa_state[v].yawbase)) .. "|"
		.. tostring(ui.get(new_menu_references["aa"].aa_state[v].yaw)) .. "|"
		.. tostring(ui.get(new_menu_references["aa"].aa_state[v].yawadd)) .. "|"
		.. tostring(ui.get(new_menu_references["aa"].aa_state[v].ticker_slider)) .. "|"
        .. tostring(ui.get(new_menu_references["aa"].aa_state[v].yawaddleft)) .. "|"
		.. tostring(ui.get(new_menu_references["aa"].aa_state[v].yawjitter)) .. "|"
		.. tostring(ui.get(new_menu_references["aa"].aa_state[v].yawjitteradd)) .. "|"
        .. tostring(ui.get(new_menu_references["aa"].aa_state[v].yawjitteradd2)) .. "|"
        .. tostring(ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw)) .. "|"
        .. tostring(ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyawadd)) .. "|"   
        .. tostring(ui.get(new_menu_references["aa"].aa_state[v].delayed_method)) .. "|"


        for b = 1,12 do
            str = str .. tostring(ui.get(new_menu_references["aa"].aa_state[v].pedro_aas2[b])) .. "|"   
        end
    end

    str = str
    .. tostring(ui.get(new_menu_references["aa"].anti_kniv)) .. "|"
    .. tostring(ui.get(new_menu_references["aa"].safe_dangerous)) .. "|"
    .. tostring(ui.get(new_menu_references["aa"].label_jitter_ways)) .. "|"
    .. tostring(ui.get(new_menu_references["aa"].freestanding_disabler)) .. "|"

    .. tostring(ui.get(new_menu_references["visuals"].enable_indicators)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].indicator_color)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].enable_manual)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].indicator_manual_color)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].enable_velocity_adaptive)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].enable_defensive_indicator)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].indicator_defensive_color)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].slow_indicator)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].indicator_slow_color)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].enable_min_dmg_ovrrd)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].enable_desync_indicator)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].indicator_desync_color)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].draw_logs)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].zeus)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].extra_visuals)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].watermark_label)) .. "|"
    .. tostring(ui.get(new_menu_references["visuals"].watermark_color)) .. "|"

    .. tostring(ui.get(new_menu_references["misc"].enable_clan_tag)) .. "|"
    .. tostring(ui.get(new_menu_references["misc"].enable_kill_say)) .. "|"
    .. tostring(ui.get(new_menu_references["misc"].enable_sun_rise)) .. "|"
    .. tostring(ui.get(new_menu_references["misc"].enable_nigthermode)) .. "|"
    .. tostring(ui.get(new_menu_references["misc"].debug_ragebot)) .. "|"
    .. tostring(ui.get(new_menu_references["misc"].safe_point)) .. "|"
    .. tostring(ui.get(new_menu_references["misc"].m_elements)) .. "|"
    .. tostring(ui.get(new_menu_references["misc"].slide_elements)) .. "|"
    .. tostring(ui.get(new_menu_references["misc"].body_lean_value)) .. "|"
    .. tostring(ui.get(new_menu_references["misc"].break_air_value)) .. "|"
    .. tostring(ui.get(new_menu_references["misc"].break_land_value)) .. "|"

    .. tostring(ui.get(new_menu_references["keys"].enable_key)) .. "|"
    .. tostring(ui.get(new_menu_references["keys"].manual_left)) .. "|"
    .. tostring(ui.get(new_menu_references["keys"].manual_right)) .. "|"
    .. tostring(ui.get(new_menu_references["keys"].manual_forward)) .. "|"
    .. tostring(ui.get(new_menu_references["keys"].manual_reset)) .. "|"
    .. tostring(ui.get(new_menu_references["keys"].global_fs)) .. "|"

    for i = 1,4 do
        str = str .. tostring(tostring(ui.get(new_menu_references["bruteforce"][i]))) .. "|"
    end

    clipboard.set(base64.encode(str,'base64'))
end)


new_menu_references.config.import_config = ui.new_button(tab,place,"import from clipboard",function()


    local tbl = str_to_sub(base64.decode(clipboard.get(), 'base64'), "|")
    local crescente = 1
    
    --aa
    for k,v in ipairs(aa.aa_states) do
    
        ui.set(new_menu_references["aa"].aa_state[v].enabled, to_boolean(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].pitch, tostring(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].yawbase, tostring(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].yaw, tostring(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].yawadd, tonumber(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].ticker_slider, tonumber(tbl[crescente]))
		crescente = crescente + 1
        ui.set(new_menu_references["aa"].aa_state[v].yawaddleft, tonumber(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].yawjitter, tostring(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].yawjitteradd, tonumber(tbl[crescente]))
        crescente = crescente + 1
        ui.set(new_menu_references["aa"].aa_state[v].yawjitteradd2, tonumber(tbl[crescente]))
        crescente = crescente + 1
        ui.set(new_menu_references["aa"].aa_state[v].gs_bodyyaw, tostring(tbl[crescente]))
        crescente = crescente + 1
        ui.set(new_menu_references["aa"].aa_state[v].gs_bodyyawadd, tonumber(tbl[crescente]))
        crescente = crescente + 1
        ui.set(new_menu_references["aa"].aa_state[v].delayed_method, tostring(tbl[crescente]))
        crescente = crescente + 1

        for b = 1,12 do
            ui.set(new_menu_references["aa"].aa_state[v].pedro_aas2[b],tonumber(tbl[crescente]))
            crescente = crescente + 1
        end
    end

    --aa2
    ui.set(new_menu_references["aa"].anti_kniv, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["aa"].safe_dangerous, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["aa"].freestanding_disabler, tostring(tbl[crescente]))
    crescente = crescente + 1

    --visuals
    ui.set(new_menu_references["visuals"].enable_indicators, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["visuals"].enable_manual, tostring(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["visuals"].enable_velocity_adaptive, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["visuals"].enable_defensive_indicator, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["visuals"].slow_indicator, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["visuals"].enable_min_dmg_ovrrd, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["visuals"].enable_desync_indicator, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["visuals"].draw_logs, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    --ui.set(new_menu_references["visuals"].zeus, tostring(tbl[crescente]))
    --crescente = crescente + 1
    --ui.set(new_menu_references["visuals"].extra_visuals, tostring(tbl[crescente]))
    --crescente = crescente + 1

    --misc
    ui.set(new_menu_references["misc"].enable_key, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["misc"].enable_kill_say, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["misc"].enable_sun_rise, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["misc"].enable_nigthermode, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    --ui.set(new_menu_references["misc"].debug_ragebot, tostring(tbl[crescente]))
    --crescente = crescente + 1
    --ui.set(new_menu_references["misc"].safe_point, tostring(tbl[crescente]))
    --crescente = crescente + 1
    --ui.set(new_menu_references["misc"].m_elements, tostring(tbl[crescente]))
    --crescente = crescente + 1
    --ui.set(new_menu_references["misc"].slide_elements, tostring(tbl[crescente]))
    --crescente = crescente + 1
    ui.set(new_menu_references["misc"].body_lean_value, tonumber(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["misc"].break_air_value, tonumber(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["misc"].break_land_value, tonumber(tbl[crescente]))
    crescente = crescente + 1

    --keys
    ui.set(new_menu_references["keys"].enable_key, to_boolean(tbl[crescente]))
    crescente = crescente + 1

    --bruteforce
    for i = 1, 4 do
        ui.set(new_menu_references["bruteforce"][i], tonumber(tbl[crescente]))
        crescente = crescente + 1
    end
end)

new_menu_references.config.default_config = ui.new_button(tab,place,"default config",function()
    local clipboard = "dHJ1ZXxtaW5pbWFsfGF0IHRhcmdldHN8ZGVsYXllZHwxOXw2fC0yMXxzd2F5fDB8MHxkZWxheWVkIHlhd3wwfGFkdmFuY2VkfDB8MHwwfDB8MHwwfDB8MHwwfDB8MHwwfHRydWV8bWluaW1hbHxhdCB0YXJnZXRzfGRlbGF5ZWR8MzJ8M3wtMzJ8c3dheXwwfDB8ZGVsYXllZCB5YXd8MHxhZHZhbmNlZHwwfDB8MHwwfDB8MHwwfDB8MHwwfDB8MHx0cnVlfG1pbmltYWx8YXQgdGFyZ2V0c3xkZWxheWVkfDIxfDN8LTIxfHN3YXl8MHwwfGRlbGF5ZWQgeWF3fDB8YWR2YW5jZWR8MHwwfDB8MHwwfDB8MHwwfDB8MHwwfDB8dHJ1ZXxtaW5pbWFsfGF0IHRhcmdldHN8ZGVsYXllZHwyNXwzfC0yNXxzd2F5fDB8MHxkZWxheWVkIHlhd3wwfGFkdmFuY2VkfDB8MHwwfDB8MHwwfDB8MHwwfDB8MHwwfHRydWV8bWluaW1hbHxhdCB0YXJnZXRzfGRlbGF5ZWR8MzZ8NHwtMjh8c3dheXwwfDB8ZGVsYXllZCB5YXd8MHxhZHZhbmNlZHwwfDB8MHwwfDB8MHwwfDB8MHwwfDB8MHx0cnVlfG1pbmltYWx8YXQgdGFyZ2V0c3xkZWxheWVkfDMyfDN8LTMyfHN3YXl8MHwwfGRlbGF5ZWQgeWF3fDB8YWR2YW5jZWR8MHwwfDB8MHwwfDB8MHwwfDB8MHwwfDB8dHJ1ZXxtaW5pbWFsfGxvY2FsIHZpZXd8MTgwfDB8MXwwfG9mZnwwfDB8c3RhdGljfDE4MHxzaW1wbGV8MHwwfDB8MHwwfDB8MHwwfDB8MHwwfDB8ZmFsc2V8b2ZmfGxvY2FsIHZpZXd8b2ZmfDB8MXwwfG9mZnwwfDB8b2ZmfDB8c2ltcGxlfDB8MHwwfDB8MHwwfDB8MHwwfDB8MHwwfHRydWV8b2ZmfGxvY2FsIHZpZXd8MTgwfDE4MHwxfDB8b2ZmfDB8MHxhdXRvIGppdHRlcnwwfHNpbXBsZXwwfDB8MHwwfDB8MHwwfDB8MHwwfDB8MHx0cnVlfHRydWV8T25seSB3b3JrcyBpZiB5b3UgZW5hYmxlIGppdHRlciB3YXlzfFN0YXRpY3x0YWJsZTogTlVMTHxvZmZ8MTc2fGZhbHNlfG9mZnwyNTV8ZmFsc2V8dHJ1ZXwxNjh8dHJ1ZXwyNTV8dHJ1ZXx0cnVlfDE2OHxmYWxzZXx0YWJsZTogTlVMTHx0YWJsZTogTlVMTHx0cnVlfDEwMXxmYWxzZXxEaXNhYmxlZHx0cnVlfGZhbHNlfHRhYmxlOiBOVUxMfHRhYmxlOiBOVUxMfHRhYmxlOiBOVUxMfHRhYmxlOiBOVUxMfDUwfDV8NXx0cnVlfGZhbHNlfGZhbHNlfGZhbHNlfGZhbHNlfGZhbHNlfC0zMHwyNXwxNHwwfA=="

    local tbl = str_to_sub(base64.decode(clipboard, 'base64'), "|")
    local crescente = 1

    for k,v in ipairs(aa.aa_states) do
    
        ui.set(new_menu_references["aa"].aa_state[v].enabled, to_boolean(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].pitch, tostring(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].yawbase, tostring(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].yaw, tostring(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].yawadd, tonumber(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].ticker_slider, tonumber(tbl[crescente]))
		crescente = crescente + 1
        ui.set(new_menu_references["aa"].aa_state[v].yawaddleft, tonumber(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].yawjitter, tostring(tbl[crescente]))
        crescente = crescente + 1
		ui.set(new_menu_references["aa"].aa_state[v].yawjitteradd, tonumber(tbl[crescente]))
        crescente = crescente + 1
        ui.set(new_menu_references["aa"].aa_state[v].yawjitteradd2, tonumber(tbl[crescente]))
        crescente = crescente + 1
        ui.set(new_menu_references["aa"].aa_state[v].gs_bodyyaw, tostring(tbl[crescente]))
        crescente = crescente + 1
        ui.set(new_menu_references["aa"].aa_state[v].gs_bodyyawadd, tonumber(tbl[crescente]))
        crescente = crescente + 1
        ui.set(new_menu_references["aa"].aa_state[v].delayed_method, tostring(tbl[crescente]))
        crescente = crescente + 1

        for b = 1,12 do
            ui.set(new_menu_references["aa"].aa_state[v].pedro_aas2[b],tonumber(tbl[crescente]))
            crescente = crescente + 1
        end
    end

    --aa2
    ui.set(new_menu_references["aa"].anti_kniv, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["aa"].safe_dangerous, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    --ui.set(new_menu_references["aa"].freestanding_options, tostring(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["aa"].freestanding_disabler, tostring(tbl[crescente]))
    crescente = crescente + 1

    --visuals
    --ui.set(new_menu_references["visuals"].enable_indicators, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    --ui.set(new_menu_references["visuals"].scoped_animation, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    --ui.set(new_menu_references["visuals"].enable_manual, tostring(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["visuals"].enable_velocity_adaptive, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    --ui.set(new_menu_references["visuals"].enable_defensive_indicator, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    --ui.set(new_menu_references["visuals"].slow_indicator, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["visuals"].enable_min_dmg_ovrrd, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["visuals"].enable_desync_indicator, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    --ui.set(new_menu_references["visuals"].draw_logs, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    --ui.set(new_menu_references["visuals"].zeus, tostring(tbl[crescente]))
    --crescente = crescente + 1
    --ui.set(new_menu_references["visuals"].extra_visuals, tostring(tbl[crescente]))
    --crescente = crescente + 1

    --misc
    --ui.set(new_menu_references["misc"].enable_key, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    --ui.set(new_menu_references["misc"].enable_kill_say, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["misc"].enable_sun_rise, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    ui.set(new_menu_references["misc"].enable_nigthermode, to_boolean(tbl[crescente]))
    crescente = crescente + 1
    --ui.set(new_menu_references["misc"].debug_ragebot, tostring(tbl[crescente]))
    --crescente = crescente + 1
    --ui.set(new_menu_references["misc"].safe_point, tostring(tbl[crescente]))
    --crescente = crescente + 1
    --ui.set(new_menu_references["misc"].m_elements, tostring(tbl[crescente]))
    --crescente = crescente + 1
    --ui.set(new_menu_references["misc"].slide_elements, tostring(tbl[crescente]))
    --crescente = crescente + 1
    --ui.set(new_menu_references["misc"].body_lean_value, tonumber(tbl[crescente]))
    crescente = crescente + 1
    --ui.set(new_menu_references["misc"].break_air_value, tonumber(tbl[crescente]))
    crescente = crescente + 1
    --ui.set(new_menu_references["misc"].break_land_value, tonumber(tbl[crescente]))
    crescente = crescente + 1

    --keys
    --ui.set(new_menu_references["keys"].enable_key, to_boolean(tbl[crescente]))
    crescente = crescente + 1

    --bruteforce
    for i = 1, 4 do
        --ui.set(new_menu_references["bruteforce"][i], tonumber(tbl[crescente]))
        crescente = crescente + 1
    end
end)

local function hide_default_aa(conditions)
    ui.set_visible(menu_reference.enabled,conditions)
    ui.set_visible(menu_reference.pitch[1], conditions)
    ui.set_visible(menu_reference.pitch[2], conditions)
    ui.set_visible(menu_reference.roll, conditions)
    ui.set_visible(menu_reference.yawbase, conditions)
    ui.set_visible(menu_reference.yaw[1], conditions)
    ui.set_visible(menu_reference.yaw[2], conditions)
    ui.set_visible(menu_reference.yawjitter[1], conditions)
    ui.set_visible(menu_reference.yawjitter[2], conditions)
    ui.set_visible(menu_reference.bodyyaw[1], conditions)
    ui.set_visible(menu_reference.bodyyaw[2], conditions)
    ui.set_visible(menu_reference.freestand[1], conditions)
    ui.set_visible(menu_reference.freestand[2], conditions)
    ui.set_visible(menu_reference.fsbodyyaw,conditions)
    ui.set_visible(menu_reference.edgeyaw, conditions)
end

-- aa = 1,visuals = 2,misc = 3,config = 4

local function new_menu_visibility()

    local manual_page = ui.get(new_menu_references["aa"].aa_state_menu) == "Manual"
    local main_page = ui.get(new_menu_references.aa_tab) == "Main"
    local jitter_page = ui.get(new_menu_references.aa_tab) == "Jitter"
    local bruteforce_page = ui.get(new_menu_references.aa_tab) == "Bruteforce"
   
    --aa
   -- ui.set_visible(new_menu_references["aa"].aa_label,ui_menu.selected_tab == 1)
    ui.set_visible(new_menu_references["aa"].aa_state_menu,ui_menu.selected_tab == 1 or ui_menu.selected_tab == 2 and jitter_page)
    ui.set_visible(new_menu_references.aa_tab,ui_menu.selected_tab == 2)
    
    --local anti_bruteforce = ui.get(new_menu_references["aa"]_tab) == "bruteforce"
    for k,v in ipairs(aa.aa_states) do
        ui.set_visible(new_menu_references["aa"].aa_state[v].enabled,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v)
        ui.set_visible( new_menu_references["aa"].aa_state[v].pitch,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v)
        ui.set_visible( new_menu_references["aa"].aa_state[v].pitch_slider,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].pitch) == "custom")
        ui.set_visible( new_menu_references["aa"].aa_state[v].yawbase,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and not manual_page) 
        ui.set_visible( new_menu_references["aa"].aa_state[v].yaw,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and k ~= 7 and k ~= 9) 
        ui.set_visible( new_menu_references["aa"].aa_state[v].yawadd,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and not manual_page and ui.get(new_menu_references["aa"].aa_state[v].yaw) ~= "off") 
        ui.set_visible( new_menu_references["aa"].aa_state[v].yawjitter,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v)  
        ui.set_visible( new_menu_references["aa"].aa_state[v].yawjitteradd,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) ~= "off" and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) ~= "jitter ways" and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) ~= "sway")  
        ui.set_visible( new_menu_references["aa"].aa_state[v].yawjitteradd2,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) == "l & r")  
        ui.set_visible( new_menu_references["aa"].aa_state[v].gs_bodyyaw,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v) 
        ui.set_visible( new_menu_references["aa"].aa_state[v].delayed_method,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) == "delayed yaw") 
        ui.set_visible( new_menu_references["aa"].aa_state[v].gs_bodyyawadd,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) ~= "off" and ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) ~= "anti bruteforce" and ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) ~= "auto jitter" and  ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) ~= "delayed yaw") 
        ui.set_visible(new_menu_references["aa"].aa_state[v].jway_counter,false)
        ui.set_visible(new_menu_references["aa"].aa_state[v].swaym, ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) == "sway")
        ui.set_visible(new_menu_references["aa"].aa_state[v].swaymx, ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) == "sway")
        ui.set_visible(new_menu_references["aa"].aa_state[v].swayspeed, ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yawjitter) == "sway")

        if  k ~= "Legit" and k ~= "manual" then
            ui.set_visible(new_menu_references["aa"].aa_state[v].yawaddleft, ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and (ui.get(new_menu_references["aa"].aa_state[v].yaw) == "jittery" or ui.get(new_menu_references["aa"].aa_state[v].yaw) == "delayed" or ui.get(new_menu_references["aa"].aa_state[v].yaw) == "l & r"))
            ui.set_visible(new_menu_references["aa"].aa_state[v].ticker_slider, ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yaw) == "delayed")
        end
        
        if k ~= "fakelag" and k ~= "Legit" and k ~= "manual" then
            ui.set_visible(new_menu_references["aa"].aa_state[v].enabled_exploit,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v)
            ui.set_visible( new_menu_references["aa"].aa_state[v].enabled_defensive_force,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit)) 
            ui.set_visible( new_menu_references["aa"].aa_state[v].pitch_defensive,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit)) 
            ui.set_visible( new_menu_references["aa"].aa_state[v].pitch_defensive_slider,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit) and ui.get(new_menu_references["aa"].aa_state[v].pitch_defensive) == "custom") 
            ui.set_visible( new_menu_references["aa"].aa_state[v].yaw_defensive,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit)) 
            ui.set_visible( new_menu_references["aa"].aa_state[v].yawadd_defensive,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].yaw_defensive) ~= "off" and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit)) 
            ui.set_visible( new_menu_references["aa"].aa_state[v].skitter_defensive,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit)) 
            ui.set_visible(new_menu_references["aa"].aa_state[v].skitter_slider_defensive,ui_menu.selected_tab == 1 and ui.get(new_menu_references["aa"].aa_state_menu) == v and ui.get(new_menu_references["aa"].aa_state[v].skitter_defensive) and ui.get(new_menu_references["aa"].aa_state[v].enabled_exploit))
        end

        ui.set_visible(new_menu_references["aa"].label_jitter_ways,ui_menu.selected_tab == 2 and jitter_page and ui.get(new_menu_references["aa"].aa_state[ui.get(new_menu_references["aa"].aa_state_menu)].yawjitter) ~= "jitter ways")
        for i = 1, 12 do
            ui.set_visible( new_menu_references["aa"].aa_state[v].pedro_aas2[i]  ,ui_menu.selected_tab == 2 and ui.get(new_menu_references["aa"].aa_state_menu) == v and i <= ui.get(new_menu_references["aa"].aa_state[v].jway_counter) and jitter_page and ui.get(new_menu_references["aa"].aa_state[ui.get(new_menu_references["aa"].aa_state_menu)].yawjitter) == "jitter ways")
            --print(new_menu_references["aa"].aa_state[v].slider[i])
        end
    end

    --aa2
    
    local keys = ui.get(new_menu_references["keys"].enable_key)
    ui.set_visible(new_menu_references["aa"].freestanding_disabler, ui_menu.selected_tab == 2 and main_page)
    ui.set_visible(jitter_add, ui_menu.selected_tab == 2 and jitter_page and ui.get(new_menu_references["aa"].aa_state[ui.get(new_menu_references["aa"].aa_state_menu)].yawjitter) == "jitter ways" )
    ui.set_visible(jitter_remove, ui_menu.selected_tab == 2 and jitter_page and ui.get(new_menu_references["aa"].aa_state[ui.get(new_menu_references["aa"].aa_state_menu)].yawjitter) == "jitter ways")
    ui.set_visible(new_menu_references["keys"].enable_key, ui_menu.selected_tab == 2 and main_page)
    ui.set_visible(new_menu_references["keys"].manual_forward, ui_menu.selected_tab == 2 and main_page and keys)
    ui.set_visible(new_menu_references["keys"].manual_left, ui_menu.selected_tab == 2 and main_page and keys)
    ui.set_visible(new_menu_references["keys"].manual_right, ui_menu.selected_tab == 2 and main_page and keys)
    ui.set_visible(new_menu_references["keys"].manual_reset, ui_menu.selected_tab == 2 and main_page and keys)
    ui.set_visible(new_menu_references["keys"].global_fs, ui_menu.selected_tab == 2 and main_page and keys)
    ui.set_visible(new_menu_references["keys"].edgeYawHotkey, ui_menu.selected_tab == 2 and main_page and keys)
    ui.set_visible(new_menu_references["keys"].dtDischarge, ui_menu.selected_tab == 2 and main_page and keys)
    ui.set_visible(new_menu_references["aa"].anti_kniv, ui_menu.selected_tab == 2 and main_page)
    ui.set_visible(new_menu_references["aa"].safe_dangerous, ui_menu.selected_tab == 2 and main_page)
   

    for h = 1, 4 do
       
        ui.set_visible(new_menu_references["bruteforce"][h],ui_menu.selected_tab == 2 and bruteforce_page)
    end

    --visuals
    --ui.set_visible(new_menu_references["visuals"].visual_label,ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].zeus,ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].enable_indicators,ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].draw_logs,ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].indicator_color,ui_menu.selected_tab == 3 and ui.get(new_menu_references["visuals"].enable_indicators) ~= "off")
    --ui.set_visible(new_menu_references["visuals"].scoped_animation,ui_menu.selected_tab == 3 )
    ui.set_visible(new_menu_references["visuals"].indicator_manual_color,ui_menu.selected_tab == 3 and ui.get(new_menu_references["visuals"].enable_manual) ~= "off")
    ui.set_visible(new_menu_references["visuals"].enable_manual,ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].enable_min_dmg_ovrrd,ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].enable_desync_indicator,ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].enable_velocity_adaptive, ui_menu.selected_tab == 3 and ui.get(new_menu_references["visuals"].enable_manual) ~= "off")
    ui.set_visible(new_menu_references["visuals"].enable_defensive_indicator,ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].slow_indicator,ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].indicator_desync_color,ui_menu.selected_tab == 3 and ui.get(new_menu_references["visuals"].enable_desync_indicator))
    ui.set_visible(new_menu_references["visuals"].indicator_defensive_color,ui_menu.selected_tab == 3 and ui.get(new_menu_references["visuals"].enable_defensive_indicator))
    ui.set_visible(new_menu_references["visuals"].indicator_slow_color,ui_menu.selected_tab == 3 and ui.get(new_menu_references["visuals"].slow_indicator))
    --ui.set_visible(new_menu_references["visuals"].aim_logs_label, ui_menu.selected_tab == 3)
    --ui.set_visible(new_menu_references["visuals"].aim_logs_outline_color, ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].watermark_color, ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].watermark_label, ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].extra_visuals,ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].collisionControl, ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].distanceControl, ui_menu.selected_tab == 3 and ui.get(new_menu_references["visuals"].collisionControl))

    ui.set_visible(new_menu_references["visuals"].hitmarker, ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].hitmarker_color, ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].console_col_label, ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].recolor_console, ui_menu.selected_tab == 3)

    ui.set_visible(new_menu_references["visuals"].tracer, ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].color, ui_menu.selected_tab == 3)

    ui.set_visible(new_menu_references["visuals"].logs, ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].logsClr, ui_menu.selected_tab == 3)
    ui.set_visible(new_menu_references["visuals"].logOffset, ui_menu.selected_tab == 3 and ui.get(new_menu_references["visuals"].logs))

    --ui.set_visible(new_menu_references["visuals"].noti_timer,ui_menu.selected_tab == 3)
    --ui.set_visible(new_menu_references["visuals"].noti_padding,ui_menu.selected_tab == 3)
    
    --misc
    --ui.set_visible(new_menu_references["misc"].misc_label,ui_menu.selected_tab == 4)
    ui.set_visible(new_menu_references["misc"].enable_clan_tag,ui_menu.selected_tab == 4)
    ui.set_visible(new_menu_references["misc"].enable_kill_say,ui_menu.selected_tab == 4)
    ui.set_visible(new_menu_references["misc"].enable_sun_rise,ui_menu.selected_tab == 4)

    ui.set_visible(new_menu_references["misc"].sun_pitch, ui_menu.selected_tab == 4 and ui.get(new_menu_references["misc"].enable_sun_rise))
    ui.set_visible(new_menu_references["misc"].sun_yaw, ui_menu.selected_tab == 4 and ui.get(new_menu_references["misc"].enable_sun_rise))
    ui.set_visible(new_menu_references["misc"].sun_distance, ui_menu.selected_tab == 4 and ui.get(new_menu_references["misc"].enable_sun_rise))
    --ui.set_visible(new_menu_references["misc"].sun_label, ui_menu.selected_tab == 4 and ui.get(new_menu_references["misc"].enable_sun_rise))
    --ui.set_visible(new_menu_references["misc"].sun_color, ui_menu.selected_tab == 4 and ui.get(new_menu_references["misc"].enable_sun_rise))

    ui.set_visible(new_menu_references["misc"].enable_nigthermode,ui_menu.selected_tab == 4)
    ui.set_visible(new_menu_references["misc"].safe_point,ui_menu.selected_tab == 4 and table_contains(ui.get(new_menu_references["misc"].debug_ragebot),"safe point enhancer"))
    ui.set_visible(new_menu_references["misc"].debug_ragebot,ui_menu.selected_tab == 4)
    ui.set_visible(new_menu_references["misc"].m_elements, ui_menu.selected_tab == 4)
    ui.set_visible(new_menu_references["misc"].slide_elements, ui_menu.selected_tab == 4 and table.contains(new_menu_references["misc"].m_elements, "Slide slow-walking"))
    ui.set_visible(new_menu_references["misc"].body_lean_value, ui_menu.selected_tab == 4 and table.contains(new_menu_references["misc"].m_elements, "Adjust body lean"))
    ui.set_visible(new_menu_references["misc"].break_air_value, ui_menu.selected_tab == 4 and table.contains(new_menu_references["misc"].m_elements, "Break legs while in air"))
    ui.set_visible(new_menu_references["misc"].break_land_value, ui_menu.selected_tab == 4 and table.contains(new_menu_references["misc"].m_elements, "Break legs while landing"))
    ui.set_visible(new_menu_references["misc"].console_filter, ui_menu.selected_tab == 4)

    --config
    --ui.set_visible(new_menu_references.config.config_label,ui_menu.selected_tab == 5)
    ui.set_visible(new_menu_references.config.export_file,ui_menu.selected_tab == 5)
    ui.set_visible(new_menu_references.config.import_config,ui_menu.selected_tab == 5)
    ui.set_visible(new_menu_references.config.default_config,ui_menu.selected_tab == 5)
end

client.set_event_callback("player_death",function(ent)

    if client.userid_to_entindex(ent.userid) == entity.get_local_player() then
        brute_stage.last_miss = 0
        for k,v in ipairs(aa.aa_states) do

            if ui.get(new_menu_references["aa"].aa_state[v].yaw) == "l & r" or ui.get(new_menu_references["aa"].aa_state[v].yaw) == "delayed" or ui.get(new_menu_references["aa"].aa_state[v].yaw) == "jittery" then
                break
            end
          
            if ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) == "anti bruteforce" and not brute_stage.to_reset then
                brute_stage.brute[v].missed_bullets = 0
                print("Anti bruteforce angles were resetted due to death")
                brute_stage.to_reset = true
            end
        end
    end

    if ui.get(new_menu_references["misc"].enable_kill_say) ~= "Disabled" and client.userid_to_entindex(ent.attacker) == entity.get_local_player() and entity.get_prop(client.userid_to_entindex(ent.userid),"m_iTeamNum") ~= entity.get_prop(entity.get_local_player(),"m_iTeamNum") then
       
        client.exec("say " .. misc_functions.kill_say[ui.get(new_menu_references["misc"].enable_kill_say)][client.random_int(1, #misc_functions.kill_say[ui.get(new_menu_references["misc"].enable_kill_say)])])
    end
end)


client.set_event_callback("round_end",function(e)
   brute_stage.round_starting = true  
end)

client.set_event_callback("round_start",function(ent)
    if brute_stage.round_starting == true and brute_stage.to_reset == false then
       
        for k,v in ipairs(aa.aa_states) do

            if ui.get(new_menu_references["aa"].aa_state[v].yaw) == "l & r" or ui.get(new_menu_references["aa"].aa_state[v].yaw) == "delayed" or ui.get(new_menu_references["aa"].aa_state[v].yaw) == "jittery" then
                break
            end

            if ui.get(new_menu_references["aa"].aa_state[v].gs_bodyyaw) == "anti bruteforce" then
                
                brute_stage.brute[v].missed_bullets = 0
                print("Anti bruteforce angles were resetted due to round start")
                brute_stage.round_starting = false
            end
        end
        
    end

    miss_sp = {}
    brute_stage.to_reset = false
    aa_functions.bomb_was_bombed = false
    aa_functions.bomb_was_defused = false
end)


function misc_functions:local_animations()

    if not entity.is_alive(entity.get_local_player()) then
        misc_functions.end_time = 0
        misc_functions.ground_ticks = 0
        return
    end
end

client.set_event_callback("bullet_impact", aa_functions.anti_brute_bullet_impact)

client.set_event_callback("pre_render", function()
    misc_functions:local_animations()
end)

local aim_logs = {}
local reason = "spread"

local hitgroup_names = {'Generic', 'Head', 'Chest', 'Stomach', 'Left arm', 'Right arm', 'Left leg', 'Right leg', 'Neck', '?', 'Gear'}

local player_hp_on_fire = 100
client.set_event_callback("aim_fire",function(ent)
    player_hp_on_fire = entity.get_prop(ent.target,"m_iHealth")
    visual_functions.in_fire = true

    visual_functions.chance = math.floor(ent.hit_chance)
    visual_functions.bt = globals.tickcount() - ent.tick
    visual_functions.predicted_damage = ent.damage
    visual_functions.predicted_hitgroup = ent.hitgroup
end)

local random_resolver_value = {"B","SBY","SBAY","BY","SE","SB","SBM","S"}

local miss_sp = {}

client.set_event_callback("aim_miss",function(ent)

    local group = hitgroup_names[ent.hitgroup + 1] or "?"
    local name = entity.get_player_name(ent.target)
    local hp_left = entity.get_prop(ent.target, "m_iHealth")
    local js = panorama.open()
    local persona_api = js.MyPersonaAPI
    local username = persona_api.GetName()  
    local targetname = name;
    local hitbox = group;
    local hc = visual_functions.chance;
    local backtrack = visual_functions.bt;

    if ent.reason == "?" then
        reason = "unknown"
    else
        reason = ent.reason
    end

    miss_sp[#miss_sp + 1] = 
    {
        nigga = ent.target,
        hp = entity.get_prop(ent.target, "m_iHealth"),
    }
   
    aim_logs[#aim_logs + 1] = 
    {
        text = string.format("Missed \aFF0032FF%s\aFFFFFFFF in the \aFF0032FF%s\aFFFFFFFF shot due to \aFF0032FF%s\aFFFFFFFF",name,string.lower(hitbox),string.lower(reason)),
        timer = globals.tickcount() * globals.tickinterval(),
        alpha = 255,
        hit = false,
    }

    if ui.get(new_menu_references["visuals"].draw_logs) then
        print(string.format("Missed shot due to %s",reason))
    end


    if table_contains(ui.get(new_menu_references["visuals"].extra_visuals),"beta logs") then
      
        if get_velocity(ent.target) > 2 then
            visual_functions.move = 1
        else
            visual_functions.move = 0
        end


        local beta_string =  client.color_log(255,130,120, string.format("[-] Missed %s's %s for %s damage (%s) due to %s bt=%dms (%s) [2:1:27⁺:16⁺] %s move=%s t=%s boneyaw=%s.%s%s%s",name,hitbox,visual_functions.predicted_damage,hc .. "%",reason, tonumber(totime(backtrack) * 1000),backtrack,random_resolver_value[client.random_int(1,#random_resolver_value)]
    ,visual_functions.move,client.random_int(0,30),client.random_int(-100,100),client.random_int(00,99),client.random_int(00,99),client.random_int(00,99)));
    end
end)

client.set_event_callback("aim_hit",function(ent)

   local left_hp = player_hp_on_fire - ent.damage 

   local group = hitgroup_names[ent.hitgroup + 1] or "?"
   local name = entity.get_player_name(ent.target)
   local damage = ent.damage
   local hp_left = entity.get_prop(ent.target, "m_iHealth")
   local js = panorama.open()
   local persona_api = js.MyPersonaAPI
   local username = persona_api.GetName()  
   local targetname = name
   local hitbox = group
   local dmg = damage
   local hc = visual_functions.chance
   local backtrack = visual_functions.bt;
   local predicted_group = hitgroup_names[visual_functions.predicted_hitgroup + 1] or "?"

   if left_hp < 0 then
    left_hp = 0
   end

    aim_logs[#aim_logs + 1] = 
    {
        text = string.format("Hit \a96C83CFF%s\aFFFFFFFF in the \a96C83CFF%s\aFFFFFFFF for \a96C83CFF%s\aFFFFFFFF damage (\a96C83CFF%s\aFFFFFFFF health remaining)",entity.get_player_name(ent.target),string.lower(hitgroup_names[ent.hitgroup +  1]),ent.damage,left_hp),
        timer = globals.tickcount() * globals.tickinterval(),
        alpha = 255,
        state = true,
    }

    if ui.get(new_menu_references["visuals"].draw_logs) then
        print(string.format("Hit %s in the %s for %s damage (%s health remaining)",entity.get_player_name(ent.target),hitgroup_names[ent.hitgroup +  1],ent.damage,left_hp))
    end

    if table_contains(ui.get(new_menu_references["visuals"].extra_visuals),"beta logs") then
        if visual_functions.predicted_damage > damage then
            visual_functions.calc_dmg = visual_functions.predicted_damage - damage
            visual_functions.damage_predict_string_calc = "-" .. tostring(visual_functions.calc_dmg)
        elseif visual_functions.predicted_damage < damage then
            visual_functions.calc_dmg = damage - visual_functions.predicted_damage
            visual_functions.damage_predict_string_calc = "+" .. tostring(visual_functions.calc_dmg)
        elseif visual_functions.predicted_damage == damage then
            visual_functions.damage_predict_string_calc = "+0"
        end

        if get_velocity(ent.target) > 2 then
            visual_functions.move = 1
        else
            visual_functions.move = 0
        end


        local beta_string =  client.color_log(160,180,100, string.format("[+] Hit %s's %s for %s (%s) damage (%s) bt=%dms (%s) [2:1:27⁺:16⁺] %s move=%s t=%s boneyaw=%s.%s%s%s",name,hitbox,damage,visual_functions.damage_predict_string_calc,hc .. "%", tonumber(totime(backtrack) * 1000),backtrack,random_resolver_value[client.random_int(1,#random_resolver_value)]
    ,visual_functions.move,client.random_int(0,30),client.random_int(-100,100),client.random_int(00,99),client.random_int(00,99),client.random_int(00,99)));
    end
end)

local function right_alpha(condition,alpha1,alpha2)
    if condition == true then
        return alpha2
    end

    return alpha1
end

function visual_functions:notifcation()


    
end

function visual_functions:whatsapp_notifications()
    local w,h = client.screen_size()

    for i=1,#aim_logs do

        if not aim_logs[i].init then 
            aim_logs[i].pos_animation = -50
            aim_logs[i].x_animation = 0
            aim_logs[i].init = true
        end

        if what_noti_image == nil then break end

        aim_logs[i].pos_animation = lerp(aim_logs[i].pos_animation,10 + i * 45,globals.frametime() * 10)

        local actual_string = nil
        if aim_logs[i].state then
            actual_string = string.sub(aim_logs[i].text,5,#aim_logs[i].text)
          else
              actual_string = string.sub(aim_logs[i].text,8,#aim_logs[i].text)
          end   

        local measure = { renderer.measure_text("c", actual_string) }

        local not_x = ui.get(new_menu_references["visuals"].noti_padding)
        
        rounded_rectangle(w / 2 - measure[1]/2 - 7,math.ceil(aim_logs[i].pos_animation) - 37 + not_x, measure[1] + 50,40,50,50,50,200,6,15)
        rounded_rectangle(w / 2 - measure[1]/2 - 10,math.ceil(aim_logs[i].pos_animation) - 40 + not_x, measure[1] + 50,40,0,0,0,255,6,15)
        renderer.rectangle(w / 2 - measure[1]/2,math.ceil(aim_logs[i].pos_animation) - 40 + not_x, measure[1] + 30,40,0,0,0,255)

        renderer.text(w/ 2 - measure[1]/2 + 30,math.ceil(aim_logs[i].pos_animation) - 32 + not_x,220,220,220,255,"",nil, aim_logs[i].state == true and "Starlight ~ \a96C83CFFHit\aFFFFFFFF" or "Starlight ~ \aFF0032FFMiss\aFFFFFFFF")
        

        renderer.text(w/ 2 - measure[1]/2 + 30,math.ceil(aim_logs[i].pos_animation) - 20 + not_x,220,220,220,255,"",nil, actual_string)

        what_noti_image:draw(w / 2 - measure[1]/2 - 5, math.ceil(aim_logs[i].pos_animation) - 35 + not_x,30,30,255,255,255,255,true,nil)

        if globals.tickcount() * globals.tickinterval() >= aim_logs[i].timer + ui.get(new_menu_references["visuals"].noti_timer) then
            table.remove(aim_logs,i)
            break
        end

        if i > 4 then
            table.remove(aim_logs,1)
            break
        end
    end
end

local all_players = {}
local function get_bots_players()

    for k,v in ipairs(entity.get_players(true)) do 
        table.insert(all_players,{index=v,old_pos=0,timeframe=entity.get_prop(v, "m_flSimulationTime") / globals.tickinterval(),wjitter=false,loop=0})
       
        local was_found = true
        local times_found = 0
        for i,n in ipairs(all_players) do 
            if entity.get_player_name(n.index) == entity.get_player_name(entity.get_local_player()) then 
                table.remove(all_players,i)
                break 
            end

            if n.index == v then
                times_found = times_found + 1
                was_found = false
                if times_found >= 2 then
                    was_found = true 
                    table.remove(all_players,i)
                    break
                end
            else
                was_found = false
            end
        end
    end
end

local atimer = 60
local is_hover_logs = false
local is_hover_logs_2 = false
local lerp_alpha2 = 0
local lerp_alpha3 = 0

client.register_esp_flag("FS",255,255,255, function(ent)
    if plist.get(ent,"Override safe point") == "On" then return "FS" end
end)

local intro = {}

function visual_functions:welcome_to_starlight()
   local w,h = client.screen_size()
    intro[#intro + 1] ={
        message = "Welcome to starlight, ",
        username = obex_data.username .. '.',
        alpha = 240,
        timer = 600,
        x = w / 2 - 150,
        y = h + h / 2,
    }
end

visual_functions.welcome_to_starlight()

function visual_functions:start_intro()


    local w,h = client.screen_size()
    for i = 1,#intro do

        if intro[i] == nil then break end

        renderer.rectangle(0, 0, w, h, 12, 12, 12, intro[i].alpha)
        renderer.text(w / 2, h / 2,255,255,255,intro[i].alpha,"c+",0,intro[i].message .. intro[i].username)
        renderer.text(w / 2, h / 2 + 25,101,130,190,intro[i].alpha,"c+",0,"build " .. string.lower(obex_data.build))

        local size = intro[i].timer * 1 / 600
        renderer.circle_outline(w / 2, h / 2 + 50,101,130,190,intro[i].alpha,10,0,size,2)

        if intro[i].timer < 255 then
            intro[i].alpha = intro[i].alpha - 1
        end
        

        intro[i].timer = intro[i].timer - 1 

        if intro[i].timer < 1 then
            table.remove(intro,#intro)
        end
    end
end


client.set_event_callback("paint",function()
    get_bots_players()
    local scoped = entity.get_prop(entity.get_local_player(),"m_bIsScoped") == 1 and true or false
    --local scoped_and_box = ui.get(new_menu_references["visuals"].scoped_animation) and scoped
    --visual_functions.offset = lerp(visual_functions.offset,scoped_and_box and 30 or 0,globals.frametime() * 15)

    --aa_functions.can_defensive = false
    if visual_functions.ticks <= -1 and aa_functions.to_start == false and ui.get(new_menu_references["aa"].aa_state[aa_functions.aa_number].enabled_exploit) then
        aa_functions.can_defensive = true
    end
    
    entity_override()
    local screen = vector(client.screen_size())
   
    if entity.is_alive(entity.get_local_player()) then

        visual_functions.slow_indicator()
        if ui.get(new_menu_references["visuals"].enable_indicators) == "default" then
            visual_functions.indicators()
        elseif ui.get(new_menu_references["visuals"].enable_indicators) == "minimal" then
            visual_functions.indicators2()
        elseif ui.get(new_menu_references["visuals"].enable_indicators) == "yeat" then
            visual_functions.indicators3()
        end
        
        visual_functions.zeus_indicator()
        --visual_functions.zeus_nigga()
        visual_functions.min_dmg_indicator()
        visual_functions.desync_indicator()
        visual_functions.manual_indicator()
    end


    misc_functions.sunset()
    visual_functions.defensive_indicator()

    
    
    --
    misc_functions.global_counter()
    visual_functions.watermark()
end)

function misc_functions:safe_point()


    if table_contains(ui.get(new_menu_references["misc"].debug_ragebot),"safe point enhancer") then
        for i,n in ipairs(all_players) do
            local amount_of_shots = 0
            local hp_shot = 0
    
           if not entity.is_alive(n.index) then table.remove(all_players,i) break end
    
            if table_contains(ui.get(new_menu_references["misc"].safe_point),"default") or table_contains(ui.get(new_menu_references["misc"].safe_point),"on lethal") then
                for k,v in ipairs(miss_sp) do
                    if v.nigga == n.index then
                       
                        if v.hp <= 50 and table_contains(ui.get(new_menu_references["misc"].safe_point),"on lethal")  then 
                            hp_shot = hp_shot + 1 
                        end
    
                        if table_contains(ui.get(new_menu_references["misc"].safe_point),"default") == true then 
                            amount_of_shots = amount_of_shots + 1 
                        end
                    end
                end
            end
    
            local eyes = vector(entity.get_prop(n.index,"m_angEyeAngles"))
            
    
            local mathed = math.floor(eyes.y) - math.floor(n.old_pos)
    
            if mathed == 0 then
                n.loop = n.loop + 1
    
                if n.loop > 4 then 
                    n.wjitter = false
                    n.loop = 0
                end
            else
                n.loop = 0
            end
                
        
            if mathed > 180 or mathed < -180 then
    
                local true_math = 0
    
                if mathed > 0 then
                    true_math = 199 - mathed
                else
                    true_math = -199 - mathed
                end
                
                if true_math > 80 or true_math < -80 then
                    --n.wjitter = false
                elseif (true_math <= 80 or true_math >= -80 and true_math <= -1) and mathed ~= 0 then 
                    n.wjitter = true
                end
            elseif mathed < 180 or mathed > -180 then
                if mathed > 80 or mathed < -80 then
                    n.wjitter = true
                elseif (mathed < 80 or mathed > -80 and mathed <= -1) and mathed ~= 0 then
                    --n.wjitter = false
                end

            elseif mathed == 0 and n.wjitter == true then 
                n.wjitter = true 
            end
    
            local is_wide_jitter_maybe = false 
           
            local velocity = vector(entity.get_prop(n.index,"m_vecVelocity"))
            local on_ground = bit.band(entity.get_prop(n.index, "m_fFlags"), 1) == 1
    
            
    
            if (hp_shot >= 1 and table_contains(ui.get(new_menu_references["misc"].safe_point),"on lethal") ) or (amount_of_shots >= 2 and table_contains(ui.get(new_menu_references["misc"].safe_point),"default")) or ( velocity:length2dsqr() < 2 and on_ground and table_contains(ui.get(new_menu_references["misc"].safe_point),"Stand")) or 
            (n.wjitter == true and (not on_ground or velocity:length2d() > 3 and entity.get_prop(n.index,"m_flDuckAmount") <= 0 and on_ground) and table_contains(ui.get(new_menu_references["misc"].safe_point),"wide jitter")) then
                plist.set(n.index, "Override safe point", "On")
            else
                plist.set(n.index, "Override safe point", "-")
            end
    
            local tempo = entity.get_prop(n.index, "m_flSimulationTime") / globals.tickinterval()
    
            if mathed == 0 then
            end
    
            if n.timeframe < tempo then
                n.timeframe = tempo
               
                n.old_pos = eyes.y
            end
        
        end 
    end
end

local debug_resolver = false
function aa_functions:resolver()

    if table_contains(ui.get(new_menu_references["misc"].debug_ragebot),"defensive aa resolver (exprimental)") then
        debug_resolver = true
        for k,ent in ipairs(entity.get_players(true)) do
            local ent_jumping = bit.band(entity.get_prop(ent, "m_fFlags"), 1) 
            local y,p = entity.get_prop(ent,"m_angEyeAngles")
            local ent_flags = entity.get_esp_data(ent).flags
            
    
            if ent_jumping == 0 then
                if y < -1 then
                    plist.set(ent,"Force pitch",true)
                    plist.set(ent,"Force pitch value",0)
                    plist.set(ent,"Force body yaw",true)
                    plist.set(ent,"Force body yaw value",0)
                else
                    plist.set(ent,"Force pitch",false)
                    plist.set(ent,"Force body yaw",false)
                end
            else
                plist.set(ent,"Force pitch",false)
                plist.set(ent,"Force body yaw",false)
            end
        end
    elseif not table_contains(ui.get(new_menu_references["misc"].debug_ragebot),"defensive aa resolver (exprimental)") and debug_resolver == true then
        for k,ent in ipairs(entity.get_players(true)) do
            plist.set(ent,"Force pitch",false)
            plist.set(ent,"Force body yaw",false)
        end
        debug_resolver = false
    end

end

client.set_event_callback("net_update_end", misc_functions.safe_point)

client.set_event_callback("setup_command",function(cmd)
    aa_functions:setup(cmd)
    aa_functions:resolver()


    if is_hover_logs or ui_menu.is_hovered or is_hover_logs_2 then
        cmd.in_attack = false
    end

    visual_functions.is_in_attack = cmd.in_attack == 1 and true or false
end)

client.set_event_callback("paint_ui", function()

    if ui.get(new_menu_references["aa"].aa_state_menu) == "Legit" and (ui.get(new_menu_references["aa"].aa_state["Legit"].yaw) == "jittery" or ui.get(new_menu_references["aa"].aa_state["Legit"].yaw) == "delayed")then
        ui.set(new_menu_references["aa"].aa_state[9].yaw,"180")
    end
    
    --visual_functions.negros()
    --visual_functions.NIGGASSSSSS()
    if atimer < 71 then
        atimer = atimer + 1
    end
    visual_functions.start_intro()
    if ui.is_menu_open() then
        hide_default_aa(false)
        new_menu_visibility()
    end
end)


client.set_event_callback("paint_ui", ui_menu.is_aa_tab)
client.set_event_callback("paint_ui", ui_menu.new_tab)
client.set_event_callback("paint_ui", ui_menu.outside_bar)

client.set_event_callback("shutdown", function()
    if yes == true then
        local sun_prop = entity.get_all('CCascadeLight')[1]
        entity.set_prop(sun_prop,"m_envLightShadowDirection",old_sun.x,old_sun.y,old_sun.z)
    end

    if overwritten == true then 
        local ent_map = entity.get_all("CEnvTonemapController")[1]
        entity.set_prop(ent_map, "m_bUseCustomAutoExposureMin", 0)
        entity.set_prop(ent_map, "m_bUseCustomAutoExposureMax",0)
    end

    if debug_resolver == true then
        for k,ent in ipairs(entity.get_players(true)) do
            plist.set(ent,"Force pitch",false)
            plist.set(ent,"Force body yaw",false)
        end
    end

    hide_default_aa(true)
end)

client.set_event_callback("bomb_exploded",function()
    aa_functions.bomb_was_bombed = true
end)

client.set_event_callback("bomb_defused",function()
    aa_functions.bomb_was_defused = true
end)
