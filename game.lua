-- game.lua
local game = {}
local cube = { x = 100, y = 100, size = 20, speed = 200, dx = 1, dy = 1 }
local map = {} -- Initialize map as an empty table
local spawnPoint = { x = 100, y = 100 }
local camera = { x = 0, y = 0, speed = 200 }
local serpent = require("serpent")

function game.load()
    game.resetCube()
    game.loadMap("map.bmap")
end

function game.update(dt)
    cube.x = cube.x + cube.dx * cube.speed * dt
    cube.y = cube.y + cube.dy * cube.speed * dt

    -- Update the camera position to follow the cube
    camera.x = cube.x - love.graphics.getWidth() / 2
    camera.y = cube.y - love.graphics.getHeight() / 2

    -- Check for collision with blocks and respond based on wall hit
    if map then
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
end

function game.draw()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    if map then
        for _, block in ipairs(map) do
            love.graphics.rectangle("fill", block.x, block.y, block.width, block.height)
        end
    end

    love.graphics.rectangle("fill", cube.x, cube.y, cube.size, cube.size)

    love.graphics.pop()
end

function game.keypressed(key)
    if key == "l" then
        game.loadMap("map.bmap")
    end
end

function game.loadMap(filename)
    local data, size = love.filesystem.read(filename)
    if not data then
        print("No map found or failed to read map file. Using default empty map.")
        map = {} -- Initialize to an empty map if file read fails
        return
    end

    local func, err = load("return " .. data)
    if not func then
        error("Failed to load map data: " .. tostring(err))
    end

    local success, mapData = pcall(func)
    if not success then
        error("Error while running map data: " .. tostring(mapData))
    end

    map = mapData.map or {}
    spawnPoint = mapData.spawnPoint or { x = 100, y = 100 }
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
