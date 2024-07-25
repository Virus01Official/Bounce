-- menu.lua
local menu = {}

function menu.load()
end

function menu.update(dt)
end

function menu.draw()

    love.graphics.print("Menu", love.graphics.getWidth() / 2, 0,0,1)
    love.graphics.print("1. Start Game", 100, 150)
    love.graphics.print("2. Edit Map", 100, 200)
end

function menu.keypressed(key)
    if key == "1" then
        switchScene("game")
    elseif key == "2" then
        switchScene("editor")
    elseif key == "escape" then
        love.event.quit()
    end
end

return menu
