--=========== Copyright © 2017, Planimeter, All rights reserved. ===========--
--
-- Purpose: Engine client handlers
--
--==========================================================================--

local bind    = bind
local config  = config
local convar  = convar
local engine  = engine
local gui     = gui
local love    = love
local point   = point
local require = require
local scheme  = scheme
local string  = string
local unpack  = unpack
local _G      = _G

module( "engine.client" )

function load( arg )
	require( "common.color" )
	love.graphics.setBackgroundColor( 31, 35, 36, 255 )
	love.graphics.setDefaultFilter( "nearest", "nearest" )
	gui.load()

	local c = config.getConfig()
	love.audio.setVolume( c.sound.volume )

	if ( _G._DEBUG ) then
		convar.setConvar( "perf_draw_frame_rate", "1" )
		convar.setConvar( "con_enable", "1" )
	end

	bind.readBinds()
end

function keypressed( key, scancode, isrepeat )
	require( "engine.client.input" )
	if ( _G.input.isKeyTrapped( key ) ) then return end
	if ( gui.keypressed( key, scancode, isrepeat ) ) then return end

	-- TODO: Move to bind system!!
	local mainmenu = _G.g_MainMenu
	if ( key == "escape" and mainmenu and isConnected() ) then
		if ( mainmenu:isVisible() ) then
			mainmenu:close()
		else
			mainmenu:activate()
		end
	end

	bind.keypressed( key, scancode, isrepeat )
end

function keyreleased( key, scancode )
	if ( gui.keyreleased( key, scancode ) ) then return end
	bind.keyreleased( key, scancode )
end

function textinput( t )
	gui.textinput( t )
end

function textedited( text, start, length )
	gui.textedited( text, start, length )
end

function mousepressed( x, y, button, istouch )
	require( "engine.client.input" )
	if ( _G.input.isKeyTrapped( button ) ) then return end
	if ( gui.mousepressed( x, y, button, istouch ) ) then return end
	if ( _G.g_MainMenu:isVisible() ) then return end
	bind.mousepressed( x, y, button, istouch )
end

function mousereleased( x, y, button, istouch )
	if ( gui.mousereleased( x, y, button, istouch ) ) then return end
	bind.mousereleased( x, y, button, istouch )
end

function wheelmoved( x, y )
	local mx, my = love.mouse.getPosition()
	local button = nil
	if ( y < 0 ) then
		button = "wd"
	elseif ( y > 0 ) then
		button = "wu"
	end

	require( "engine.client.input" )
	if ( _G.input.isKeyTrapped( button ) ) then return end
	if ( gui.wheelmoved( x, y ) ) then return end
	if ( _G.g_MainMenu:isVisible() ) then return end

	bind.mousepressed( mx, my, button, false )
end

local function updateDesktopSound( f )
	local snd_desktop = convar.getConvar( "snd_desktop" )
	if ( snd_desktop:getBoolean() ) then return end

	if ( not f ) then
		love.audio.setVolume( 0 )
	else
		local snd_volume = convar.getConvar( "snd_volume" )
		love.audio.setVolume( snd_volume:getNumber() )
	end
end

function focus( f )
	updateDesktopSound( f )
end

function quit()
end

function resize( w, h )
	gui.invalidateTree()
end

function update( dt )
	local game = _G.game and _G.game.client or nil
	if ( game ) then game.update( dt ) end
	local network = engine.client.network
	if ( network ) then network.update( dt ) end
end

local perf_draw_frame_rate = convar( "perf_draw_frame_rate", "0", nil, nil,
                                     "Draws the frame rate" )

local function drawFrameRate()
	local scheme = scheme.getProperty
	local font   = scheme( "Default", "font" )
	love.graphics.setFont( font )
	local fps    = love.timer.getFPS() .. " FPS"
	local ms     = 1000 * love.timer.getAverageDelta()
	ms           = string.format( "%.3f", ms ) .. " ms"
	local time   = fps .. " / " .. ms
	local width  = love.graphics.getWidth()
	local height = love.graphics.getHeight()
	local margin = gui.scale( 96 )
	local x      = width  - font:getWidth( time ) - margin
	local y      = height - font:getHeight()      - margin + point( 1 )
	local color  = scheme( "Default", "mainmenubutton.dark.textColor" )
	love.graphics.setColor( color )
	love.graphics.print( time, x, y - point( 1 ) )
end

local r_draw_grid = convar( "r_draw_grid", "0", nil, nil,
                            "Draws a grid overlay" )
local r_focus     = convar( "r_focus", "0", nil, nil,
                            "Draw only when the engine has focus" )

function draw()
	if ( r_focus:getBoolean() and not love.window.hasFocus() ) then
		return
	end

	if ( isInGame() ) then
		if ( not gui._viewportFramebuffer ) then
			gui._viewportFramebuffer = love.graphics.newCanvas()
		end

		love.graphics.setCanvas( gui._viewportFramebuffer )
			love.graphics.clear()
			_G.game.client.draw()
		love.graphics.setCanvas()
		love.graphics.setColor( unpack( _G.color.white ) )
		love.graphics.draw( gui._viewportFramebuffer )
	end

	gui.draw()

	if ( perf_draw_frame_rate:getBoolean() ) then
		drawFrameRate()
	end
end