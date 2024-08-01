-- game.lua
local game = {}
local cube = { x = 100, y = 100, size = 20, speed = 200, dx = 1, dy = 1 }
local map = {}
local spawnPoint = { x = 100, y = 100 }
local camera = { x = 0, y = 0, speed = 200 }
local serpent = require("serpent")

local mapFiles = {}
local selectedMapIndex = 1
local selectingMap = false

function game.load()
    game.loadMapFiles()
    game.resetCube()
    game.loadMap(mapFiles[selectedMapIndex])
end

function game.update(dt)
    if selectingMap then return end

    cube.x = cube.x + cube.dx * cube.speed * dt
    cube.y = cube.y + cube.dy * cube.speed * dt

    -- Update the camera position to follow the cube
    camera.x = cube.x - love.graphics.getWidth() / 2
    camera.y = cube.y - love.graphics.getHeight() / 2

    -- Check for collision with blocks and respond based on wall hit
    for _, block in ipairs(map) do
        if checkCollision(cube, block) then
            if block.finish then
                -- Collision with finish block
                game.resetCube()
                switchScene("menu")
                return
            end
            
            -- Resolve collisions
            resolveCollision(cube, block)
            love.audio.newSource("bounce.ogg", "static"):play()
        end
    end
end

function game.draw()
    if selectingMap then
        love.graphics.print("Select a map to load:", 10, 10)
        for i, filename in ipairs(mapFiles) do
            local y = 30 + 20 * (i - 1)
            if i == selectedMapIndex then
                love.graphics.print("> " .. filename, 10, y)
            else
                love.graphics.print(filename, 10, y)
            end
        end
        return
    end

    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    for _, block in ipairs(map) do
        love.graphics.rectangle("fill", block.x, block.y, block.width, block.height)
    end
    love.graphics.rectangle("fill", cube.x, cube.y, cube.size, cube.size)

    love.graphics.pop()
end

function game.keypressed(key)
    if selectingMap then
        if key == "up" then
            selectedMapIndex = selectedMapIndex - 1
            if selectedMapIndex < 1 then
                selectedMapIndex = #mapFiles
            end
        elseif key == "down" then
            selectedMapIndex = selectedMapIndex + 1
            if selectedMapIndex > #mapFiles then
                selectedMapIndex = 1
            end
        elseif key == "return" then
            game.loadMap(mapFiles[selectedMapIndex])
            selectingMap = false
        elseif key == "escape" then
            selectingMap = false
        end
    else
        if key == "l" then
            selectingMap = true
        end
    end
end

function game.loadMapFiles()
    local files = love.filesystem.getDirectoryItems("maps")
    for _, file in ipairs(files) do
        if file:match("%.bmap$") then
            table.insert(mapFiles, "maps/" .. file)
        end
    end
    if #mapFiles == 0 then
        error("No map files found in the 'maps' folder")
    end
end

function game.loadMap(filename)
    local data, size = love.filesystem.read(filename)
    if not data then
        error("Failed to read map file: " .. tostring(filename))
    end
    
    local func, err = load("return " .. data)
    if not func then
        error("Failed to load map data: " .. tostring(err))
    end
    
    local success, mapData = pcall(func)
    if not success then
        error("Error while running map data: " .. tostring(mapData))
    end

    map = mapData.map
    spawnPoint = mapData.spawnPoint
    game.resetCube()
end

function game.resetCube()
    cube.x = spawnPoint.x
    cube.y = spawnPoint.y
    cube.dx = 1
    cube.dy = 1
end

function checkCollision(cube, block)
    return cube.x < block.x + block.width and
           cube.x + cube.size > block.x and
           cube.y < block.y + block.height and
           cube.y + cube.size > block.y
end

function resolveCollision(cube, block)
    local dx1 = block.x + block.width - cube.x
    local dx2 = cube.x + cube.size - block.x
    local dy1 = block.y + block.height - cube.y
    local dy2 = cube.y + cube.size - block.y

    local overlapX = math.min(dx1, dx2)
    local overlapY = math.min(dy1, dy2)

    if overlapX < overlapY then
        if cube.x + cube.size / 2 < block.x + block.width / 2 then
            cube.x = cube.x - overlapX
            cube.dx = -math.abs(cube.dx) -- Reflect the velocity
        else
            cube.x = cube.x + overlapX
            cube.dx = math.abs(cube.dx) -- Reflect the velocity
        end
    else
        if cube.y + cube.size / 2 < block.y + block.height / 2 then
            cube.y = cube.y - overlapY
            cube.dy = -math.abs(cube.dy) -- Reflect the velocity
        else
            cube.y = cube.y + overlapY
            cube.dy = math.abs(cube.dy) -- Reflect the velocity
        end
    end
end

return game
