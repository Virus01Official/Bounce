-- main.lua
local menu = require("menu")
local game = require("game")
local editor = require("editor")
local intro = require("intro")

local currentScene = "intro"

function love.load()
    menu.load()
    game.load()
    editor.load()
    intro.load()
end

function love.update(dt)
    if currentScene == "menu" then
        menu.update(dt)
    elseif currentScene == "game" then
        game.update(dt)
    elseif currentScene == "editor" then
        editor.update(dt)
    elseif currentScene == "intro" then
        intro.update(dt)
    end
end

function love.draw()
    if currentScene == "menu" then
        menu.draw()
    elseif currentScene == "game" then
        game.draw()
    elseif currentScene == "editor" then
        editor.draw()
    elseif currentScene == "intro" then
        intro.draw()
    end
end

function love.keypressed(key)
    if currentScene == "menu" then
        menu.keypressed(key)
    elseif currentScene == "game" then
        game.keypressed(key)
    elseif currentScene == "editor" then
        editor.keypressed(key)
    end

    if key == "escape" then
        currentScene = "menu"
    end
end

function love.mousepressed(x, y, button)
    if currentScene == "editor" then
        editor.mousepressed(x, y, button)
    end
end

function switchScene(scene)
    currentScene = scene
end

function backToMenu()
    currentScene = "menu"
end