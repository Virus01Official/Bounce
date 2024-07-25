-- editor.lua
local editor = {}
local map = {}
local spawnPoint = { x = 100, y = 100 }
local currentBlock = { x = 0, y = 0, width = 50, height = 50 }
local placingMode = "block" -- block, spawn
local camera = { x = 0, y = 0, speed = 200 }

function editor.load()
end

function editor.update(dt)
    local x, y = love.mouse.getPosition()
    if placingMode == "spawn" then
        spawnPoint.x = x + camera.x
        spawnPoint.y = y + camera.y
    else
        currentBlock.x = x + camera.x - currentBlock.width / 2
        currentBlock.y = y + camera.y - currentBlock.height / 2
    end

    -- Handle camera movement
    if love.keyboard.isDown("left") then
        camera.x = camera.x - camera.speed * dt
    end
    if love.keyboard.isDown("right") then
        camera.x = camera.x + camera.speed * dt
    end
    if love.keyboard.isDown("up") then
        camera.y = camera.y - camera.speed * dt
    end
    if love.keyboard.isDown("down") then
        camera.y = camera.y + camera.speed * dt
    end
end

function editor.draw()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    -- Draw blocks
    for _, block in ipairs(map) do
        love.graphics.rectangle("line", block.x, block.y, block.width, block.height)
    end
    
    -- Draw current block
    love.graphics.rectangle("line", currentBlock.x, currentBlock.y, currentBlock.width, currentBlock.height)
    
    -- Draw spawn point
    love.graphics.circle("line", spawnPoint.x, spawnPoint.y, 10)

    love.graphics.pop()

    -- Display instructions and current mode
    love.graphics.print("Press S to save the map", 10, 10)
    love.graphics.print("Press L to load the map", 10, 30)
    love.graphics.print("Click to place blocks", 10, 50)
    love.graphics.print("Right click to delete blocks", 10, 70)
    love.graphics.print("Press P to place spawn point", 10, 90)
    love.graphics.print("Use arrow keys to scroll", 10, 110)
    love.graphics.print("Press ESC to return to the menu", 10, 130)
    love.graphics.print("Current mode: " .. placingMode, 10, 150)
end

function editor.keypressed(key)
    if key == "s" then
        editor.saveMap("map.lua")
    elseif key == "l" then
        editor.loadMap("map.lua")
    elseif key == "p" then
        placingMode = "spawn"
    else
        placingMode = "block"
    end
end

function editor.mousepressed(x, y, button)
    if button == 1 then
        if placingMode == "spawn" then
            placingMode = "block"
        else
            table.insert(map, { x = currentBlock.x, y = currentBlock.y, width = currentBlock.width, height = currentBlock.height })
        end
    elseif button == 2 then
        local adjustedX, adjustedY = x + camera.x, y + camera.y
        for i = #map, 1, -1 do
            local block = map[i]
            if adjustedX >= block.x and adjustedX <= block.x + block.width and adjustedY >= block.y and adjustedY <= block.y + block.height then
                table.remove(map, i)
                return
            end
        end
    end
end

function editor.saveMap(filename)
    local mapString = "return {\n    map = " .. tableToString(map) .. ",\n    spawnPoint = { x = " .. spawnPoint.x .. ", y = " .. spawnPoint.y .. " }\n}"
    love.filesystem.write(filename, mapString)
end

function editor.loadMap(filename)
    local mapFile = love.filesystem.load(filename)
    if mapFile then
        local loadedData = mapFile()
        map = loadedData.map
        spawnPoint = loadedData.spawnPoint
    end
end

function tableToString(tbl)
    local result = "{\n"
    for _, item in ipairs(tbl) do
        result = result .. string.format("        { x = %d, y = %d, width = %d, height = %d },\n", item.x, item.y, item.width, item.height)
    end
    result = result .. "    }"
    return result
end

return editor
