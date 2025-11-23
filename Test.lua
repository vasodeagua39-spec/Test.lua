-- gm_menu_full.lua — Menú GM FINAL (eventType == 0)

local function safe_mod(name)
    local ok, m = pcall(require, name)
    if ok and m then return m end
    local ok2, m2 = pcall(function() return package.loaded[name] end)
    if ok2 and m2 then return m2 end
    return nil
end

-- Módulos correctos
local gm = safe_mod("hexm.client.debug.gm.gm_commands.gm_combat")
local ok_combat, gm_combat = pcall(require, "hexm.client.debug.gm.gm_commands.gm_combat")
local ok_player, gm_player = pcall(require, "hexm.client.debug.gm.gm_commands.gm_player")
local ok_move, gm_move     = pcall(require, "hexm.client.debug.gm.gm_commands.gm_move")

-- ========= ALWAYS-ON CHEATS =========
local player_id = 1
local xp_multiplier = 2  -- Multiplicador de experiencia (cambia este valor para ajustar)
-- Estados globales

_G.GM_GODMODE = _G.GM_GODMODE or false
_G.GM_NOCLIP = _G.GM_NOCLIP or false
_G.GM_INVISIBLE = _G.GM_INVISIBLE or false
_G.GM_ONEHIT = _G.GM_ONEHIT or false
_G.GM_STAMINA = _G.GM_STAMINA or false
_G.GM_FOV = _G.GM_FOV or 60
_G.GM_XP_MULTIPLIER = _G.GM_XP_MULTIPLIER or 2
_G.GM_ORIGINAL_DAMAGE = 30    -- Daño real del jugador (base confirmado)
_G.GM_ORIGINAL_STAMINA = 100
_G.GM_XP_AMOUNT = 1000

local eventOK = 0

local director = cc.Director:getInstance()
local scene = director:getRunningScene()
if not scene then return end
local size = director:getVisibleSize()

-- Si existe menú previo, eliminarlo
if _G.GM_MENU then
    _G.GM_MENU:removeFromParent()
    _G.GM_MENU = nil
end

-----------------------------------------------------
-- PANEL
-----------------------------------------------------

local panel = ccui.Layout:create()
panel:setContentSize(cc.size(420, 600))
panel:setPosition(cc.p(0, size.height / 2 - 300))
panel:setBackGroundColorType(1)
panel:setBackGroundColor(cc.c3b(18, 18, 18))
panel:setBackGroundColorOpacity(200)
scene:addChild(panel, 9999)
_G.GM_MENU = panel

-----------------------------------------------------
-- UTILIDADES
-----------------------------------------------------

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

-----------------------------------------------------
-- FUNCIONES GM
-----------------------------------------------------

local function toggle_god()
    if _G.GM_GODMODE then
        if gm then pcall(gm.gm_set_invincible, false) end
        if gm then pcall(gm.gm_remove_buff, 70063) end
        _G.GM_GODMODE = false
    else
        if gm then pcall(gm.gm_set_invincible, 1) end
        _G.GM_GODMODE = true
    end
end

-- Función para añadir experiencia multiplicada
local function addMultipliedXP(player_id, base_xp)
    local xp_to_add = base_xp * xp_multiplier  -- Multiplicamos la XP obtenida por el multiplicador
    print("[✔] XP multiplicada: " .. xp_to_add .. " XP.")
    gm_add_xp(player_id, xp_to_add)  -- Llamar a la función original para añadir la XP
end

local function toggle_noclip()
    _G.GM_NOCLIP = not _G.GM_NOCLIP
end

local function toggle_invisible()
    _G.GM_INVISIBLE = not _G.GM_INVISIBLE
end

-- ===============================
-- FUNCIONES DE STAMINA
-- ===============================

_G.GM_ORIGINAL_STAMINA = 100  -- Este valor debe ser el valor base o máximo de Stamina en tu juego.

-- Variable para controlar si Stamina infinita está activa
_G.GM_STAMINA = false  -- Inicialmente Stamina está desactivada

-- ===============================
-- CONTROLADO LOOP DE STAMINA (SIN WHILE TRUE)
-- ===============================

-- Temporizador que se activa solo cuando la Stamina infinita está activada
local function apply_stamina_loop()
    if _G.GM_STAMINA then
        -- Aplicar Stamina infinita si está activada
        if ok_player and gm_player then
            -- Establecer Stamina infinita (valor razonable)
            if gm_player.gm_set_stamina then pcall(gm_player.gm_set_stamina, 1000) end
            if gm_player.gm_add_stamina then pcall(gm_player.gm_add_stamina, 1000) end
            if gm_player.gm_full_stamina then pcall(gm_player.gm_full_stamina) end
        end
    end
end

-- Crear un hilo para actualizar Stamina a intervalos regulares

-----------------------------------------------------
-- CREACIÓN DE BOTONES
-----------------------------------------------------

local y = 540

local function row(label, func)
    local b = makeButton(label, 210, y)
    bind(b, func)
    y = y - 50
    return b
end

-----------------------------------------------------
-- BOTONES DEL MENU
-----------------------------------------------------

local btn_god = row("Godmode: OFF", function(b)
    toggle_god()
    b:setTitleText("Godmode: " .. (_G.GM_GODMODE and "ON" or "OFF"))
end)

local btn_add_xp = row("Añadir XP", function(b)
    add_experience()  -- Llamamos a la función para añadir experiencia
    b:setTitleText("XP Añadido: " .. _G.GM_XP_AMOUNT)  -- Actualizamos el texto del botón
end)

local btn_noclip = row("Noclip: OFF", function(b)
    toggle_noclip()
    b:setTitleText("Noclip: " .. (_G.GM_NOCLIP and "ON" or "OFF"))
end)

local btn_invis = row("Invisible: OFF", function(b)
    toggle_invisible()
    b:setTitleText("Invisible: " .. (_G.GM_INVISIBLE and "ON" or "OFF"))
end)

local btn_stamina = row("Stamina: OFF", function(b)
    toggle_stamina()
    b:setTitleText("Stamina: " .. (_G.GM_STAMINA and "ON" or "OFF"))
end)

row("FOV +", fov_up)
row("FOV -", fov_down)

-- Crear el botón para modificar el multiplicador de XP
local btn_xp_multiplier = row("Multiplicador XP: " .. xp_multiplier .. "x", function(b)
    -- Aumentar el multiplicador cuando se presiona el botón
    xp_multiplier = xp_multiplier + 1  -- Aumentar el multiplicador (puedes ajustarlo a tu gusto)
    b:setTitleText("Multiplicador XP: " .. xp_multiplier .. "x")
end)

local btn_onehit = row("One-hit Kill: OFF", function(b)
    toggle_onehit()
    b:setTitleText("One-hit Kill: " .. (_G.GM_ONEHIT and "ON" or "OFF"))
end)

-----------------------------------------------------
-- BOTÓN CERRAR (ABAJITO SEPARADO)
-----------------------------------------------------

local btn_close = makeButton("CERRAR MENU", 210, 40)
bind(btn_close, function()
    panel:removeFromParent()
    _G.GM_MENU = nil
end)

-----------------------------------------------------
-- ESTADO VISUAL INICIAL
-----------------------------------------------------

btn_god:setTitleText("Godmode: " .. (_G.GM_GODMODE and "ON" or "OFF"))
btn_noclip:setTitleText("Noclip: " .. (_G.GM_NOCLIP and "ON" or "OFF"))
btn_invis:setTitleText("Invisible: " .. (_G.GM_INVISIBLE and "ON" or "OFF"))
btn_stamina:setTitleText("Stamina: " .. (_G.GM_STAMINA and "ON" or "OFF"))
btn_onehit:setTitleText("One-hit Kill: " .. (_G.GM_ONEHIT and "ON" or "OFF"))

-- Hook universal de daño
local function on_attack(attacker, target)
    if gm and gm.gm_add_damage then
        if _G.GM_ONEHIT then
            -- Forzar daño extremo
            gm.gm_add_damage(1, 99999999)
        else
            -- Restaurar daño normal
            gm.gm_add_damage(1, _G.GM_ORIGINAL_DAMAGE)
        end
    end
end

-- Registrar hook si existe la función (tu motor sí la tiene)
if gm and gm.register_attack_callback then
    gm.register_attack_callback(on_attack)
end

gm_open_combat_train()  -- Llama a la interfaz gráfica de entrenamiento de combate

-- Llamar a la función para agregar XP multiplicada al jugador
addMultipliedXP(1, 100)  -- Ejemplo: agregar 100 XP multiplicados por el factor

return



