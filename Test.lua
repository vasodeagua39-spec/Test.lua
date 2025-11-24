-- gm_menu_full.lua — Menú GM FINAL (versión con limpieza exhaustiva OHK)

local function safe_mod(name)
    local ok, m = pcall(require, name)
    if ok and m then return m end
    local ok2, m2 = pcall(function() return package.loaded[name] end)
    if ok2 and m2 then return m2 end
    return nil
end

local ok_combat, gm_combat = pcall(require, "hexm.client.debug.gm.gm_commands.gm_combat")
local ok_player, gm_player = pcall(require, "hexm.client.debug.gm.gm_commands.gm_player")
local ok_move, gm_move     = pcall(require, "hexm.client.debug.gm.gm_commands.gm_move")

if not ok_combat then print("[❌] No se pudo cargar gm_combat") end
if not ok_move   then print("[❌] No se pudo cargar gm_move") end
if not ok_player then print("[❌] No se pudo cargar gm_player") end

local player_id = 1
_G.GM_ONEHIT = _G.GM_ONEHIT or false
_G.GM_ONEHIT_DELTA = _G.GM_ONEHIT_DELTA or nil
_G.GM_ORIGINAL_DAMAGE = _G.GM_ORIGINAL_DAMAGE or 30

local eventOK = 0

-- GUI setup (igual que antes)
local director = cc.Director:getInstance()
local scene = director:getRunningScene()
if not scene then return end
local size = director:getVisibleSize()

if _G.GM_MENU then
    _G.GM_MENU:removeFromParent()
    _G.GM_MENU = nil
end

local panel = ccui.Layout:create()
panel:setContentSize(cc.size(420, 600))
panel:setPosition(cc.p(0, size.height / 2 - 300))
panel:setBackGroundColorType(1)
panel:setBackGroundColor(cc.c3b(18, 18, 18))
panel:setBackGroundColorOpacity(200)
scene:addChild(panel, 9999)
_G.GM_MENU = panel

local function makeButton(label, x, y)
    local b = ccui.Button:create()
    b:setTitleText(label)
    b:setTitleFontSize(26)
    b:setPosition(cc.p(x, y))
    panel:addChild(b)
    return b
end

local function bind(btn, func)
    btn:addTouchEventListener(function(sender, eventType)
        if eventType == eventOK then func(sender) end
    end)
end

-- Toggle god (simple)
local function toggle_god()
    if _G.GM_GODMODE then
        if ok_combat and gm_combat.gm_set_invincible then pcall(gm_combat.gm_set_invincible, 0) end
        if ok_combat and gm_combat.rm_buff then pcall(gm_combat.rm_buff, player_id, 70063) end
        _G.GM_GODMODE = false
        print("[✔] Godmode OFF")
    else
        if ok_combat and gm_combat.gm_set_invincible then pcall(gm_combat.gm_set_invincible, 1) end
        _G.GM_GODMODE = true
        print("[✔] Godmode ON")
    end
end

-- FUNCIONES AUXILIARES DE DIAGNÓSTICO (intentan mostrar estado)
local function diag_show_damage_panel()
    if ok_combat and gm_combat.gm_show_damage_panel_player then
        pcall(gm_combat.gm_show_damage_panel_player, player_id)
        print("[i] Ejecutado: gm_show_damage_panel_player(" .. tostring(player_id) .. ")")
    else
        print("[!] gm_show_damage_panel_player no disponible")
    end
end

local function diag_show_buffs()
    if ok_combat and gm_combat.show_buff then
        pcall(gm_combat.show_buff, player_id)
        print("[i] Ejecutado: show_buff(" .. tostring(player_id) .. ")")
    else
        print("[!] show_buff no disponible")
    end
end

-- ONE HIT KILL — limpieza agresiva y reversible
local function toggle_one_hit()
    local OHK_DELTA = 99999999

    if _G.GM_ONEHIT == true then
        print("[i] Desactivando One-Hit...")

        if ok_combat and gm_combat.add_attr and _G.GM_ONEHIT_DELTA then
            pcall(gm_combat.add_attr, player_id, "attack", -_G.GM_ONEHIT_DELTA)
        else
            pcall(gm_combat.add_attr, player_id, "attack", -OHK_DELTA)
        end

        if ok_combat and gm_combat.gm_add_damage then
            if _G.GM_ONEHIT_DELTA then
                pcall(gm_combat.gm_add_damage, player_id, -_G.GM_ONEHIT_DELTA)
            else
                pcall(gm_combat.gm_add_damage, player_id, -OHK_DELTA)
            end
        end

        if ok_combat and gm_combat.rm_buff then
            pcall(gm_combat.rm_buff, player_id, 1)
            pcall(gm_combat.rm_buff, player_id, 70063)
        end

        if ok_combat and gm_combat.gm_reset_combat_resource then
            pcall(gm_combat.gm_reset_combat_resource)
        end

        if ok_combat and gm_combat.gm_avatar_mortal then
            pcall(gm_combat.gm_avatar_mortal, player_id, true)
        end

        _G.GM_ONEHIT = false
        _G.GM_ONEHIT_DELTA = nil
        print("[✔] OHK OFF")
        return false
    end

    print("[i] Activando One-Hit...")

    if ok_combat and gm_combat.add_attr then
        pcall(gm_combat.add_attr, player_id, "attack", OHK_DELTA)
        _G.GM_ONEHIT_DELTA = OHK_DELTA
    end

    if ok_combat and gm_combat.gm_add_damage then
        pcall(gm_combat.gm_add_damage, player_id, OHK_DELTA)
    end

    if ok_combat and gm_combat.gm_add_buff then
        pcall(gm_combat.gm_add_buff, player_id, 1)
    end

    _G.GM_ONEHIT = true
    print("[✔] OHK ON")
    return true
end


-- Botones y UI
local y = 540
local function row(label, func)
    local b = makeButton(label, 210, y)
    bind(b, func)
    y = y - 50
    return b
end

local btn_god = row("Godmode: OFF", function(b)
    toggle_god()
    b:setTitleText("Godmode: " .. (_G.GM_GODMODE and "ON" or "OFF"))
end)

local btn_onehit = row("One-Hit Kill: OFF", function(b)
    local state = toggle_one_hit()
    b:setTitleText("One-Hit Kill: " .. (state and "ON" or "OFF"))
end)

local btn_close = makeButton("CERRAR MENU", 210, 40)
bind(btn_close, function()
    panel:removeFromParent()
    _G.GM_MENU = nil
end)

btn_god:setTitleText("Godmode: " .. (_G.GM_GODMODE and "ON" or "OFF"))
btn_onehit:setTitleText("One-Hit Kill: " .. (_G.GM_ONEHIT and "ON" or "OFF"))

return




