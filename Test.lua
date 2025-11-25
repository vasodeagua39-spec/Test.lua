-- gm_menu_full.lua — Menú GM FINAL (versión con limpieza exhaustiva OHK)

local function safe_mod(name)
    local ok, m = pcall(require, name)
    if ok and m then return m end
    local ok2, m2 = pcall(function() return package.loaded[name] end)
    if ok2 and m2 then return m2 end
    return nil
end

local FLAGS_TO_SET = {
    DEBUG                     = true,
    DISABLE_ACSDK             = true,
    ENABLE_DEBUG_PRINT        = true,
    ENABLE_FORCE_SHOW_GM      = true,
    FORCE_OPEN_DEBUG_SHORTCUT = true,
    GM_IS_OPEN_GUIDE          = true,
    GM_USE_PUBLISH            = true,
    acsdk_info_has_inited     = false,
}

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
_G.GM_STAMINA      = _G.GM_STAMINA or false

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

-----------------------------------------------------
-- STAMINA — REVERSIÓN EXACTA
-----------------------------------------------------
local function toggle_stamina()

    -- DESACTIVAR (revertir todo)
    if _G.GM_STAMINA == true then
        print("[✔] Stamina infinita OFF — restaurando estado original")

        if ok_combat and gm_combat then
            -- Restaurar cálculo original (0)
            pcall(gm_combat.gm_set_sp_calc, 0)

            -- Desbloquear consumo
            pcall(gm_combat.gm_lock_res_consume, false)

            -- Desactivar buceo infinito
            pcall(gm_combat.gm_unlimited_dive_resource, false)

            -- Restaurar recursos normales
            pcall(gm_combat.gm_reset_combat_resource)
        end

        _G.GM_STAMINA = false
        return false
    end

    -----------------------------------------------------
    -- ACTIVAR (igual que OHK pero versión stamina)
    -----------------------------------------------------
    print("[✔] Stamina infinita ON")

    if ok_combat and gm_combat then
        -- SP no se consume
        pcall(gm_combat.gm_set_sp_calc, 1)

        -- bloquear consumo interno
        pcall(gm_combat.gm_lock_res_consume, true)

        -- dive resource infinito (previene drenaje)
        pcall(gm_combat.gm_unlimited_dive_resource, true)

        -- limpiar recursos (para rellenar barra)
        pcall(gm_combat.gm_empty_combat_resource)
    end

    _G.GM_STAMINA = true
    return true
end

-- Función para forzar el idioma (si existe una opción de configuración)
local function force_language_to_chinese()
    local ok, err = pcall(function()
        local game_settings = package.loaded["hexm.client.settings.language"]  -- Este es solo un ejemplo, ajusta al módulo correcto
        if not game_settings then
            error("Módulo de configuración de idioma no cargado")
        end
        game_settings.set_language("chinese")  -- Asegúrate de que esta función exista en el módulo
    end)
    if ok then
        print("[✓] Idioma forzado a chino")
    else
        print(string.format("[✗] Error al forzar idioma: %s", tostring(err)))
    end
end

-- Función para abrir el nuevo menú con el idioma forzado
local function open_new_menu()
    force_language_to_chinese()  -- Forzar el idioma antes de abrir el menú

    local ok, err = pcall(function()
        local gm_combat = package.loaded["hexm.client.debug.gm.gm_commands.gm_combat"]
        if not gm_combat then
            error("GM combat module not loaded yet - inject earlier?")
        end
        gm_combat.gm_open_combat_train()  -- Llamar a la función para abrir el menú
    end)

    if ok then
        print("[✓] Nuevo Menú Abierto correctamente")
    else
        print(string.format("[✗] Error al abrir el menú: %s", tostring(err)))
    end
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

local btn_stamina = row("Stamina: OFF", function(b)
    local state = toggle_stamina()
    b:setTitleText("Stamina: " .. (state and "ON" or "OFF"))
end)

-- Botón en el menú principal para abrir el nuevo menú
row("GM menu", function()
  open_new_menu()  -- Llama a la función para abrir el nuevo menú
end)

local btn_close = makeButton("CLOSE MENU", 210, 40)
bind(btn_close, function()
    panel:removeFromParent()
    _G.GM_MENU = nil
end)

btn_god:setTitleText("Godmode: " .. (_G.GM_GODMODE and "ON" or "OFF"))
btn_onehit:setTitleText("One-Hit Kill: " .. (_G.GM_ONEHIT and "ON" or "OFF"))
btn_stamina:setTitleText("Stamina Infinita: " .. (_G.GM_STAMINA and "ON" or "OFF"))
return




