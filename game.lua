-- game.lua
local game = {}
local cube = { x = 100, y = 100, size = 20, speed = 200, dx = 1, dy = 1 }
local map = {}
local spawnPoint = { x = 100, y = 100 }
local camera = { x = 0, y = 0, speed = 200 }

function game.load()
    game.resetCube()
end

function game.update(dt)
    cube.x = cube.x + cube.dx * cube.speed * dt
    cube.y = cube.y + cube.dy * cube.speed * dt

    -- Update the camera position to follow the cube
    camera.x = cube.x - love.graphics.getWidth() / 2
    camera.y = cube.y - love.graphics.getHeight() / 2

    -- Check for collision with blocks and respond based on wall hit
    for _, block in ipairs(map) do
        if checkCollision(cube, block) then
            if block.finish and checkCollision(cube, block) then
                game.resetCube()
                switchScene("menu")
                return
            end
            
            if cube.x + cube.size > block.x and cube.x < block.x + block.width then
                -- Vertical collision
                if cube.y < block.y then
                    -- Top edge
                    cube.dy = -math.abs(cube.dy)
                else
                    -- Bottom edge
                    cube.dy = math.abs(cube.dy)
                end
            end

            if cube.y + cube.size > block.y and cube.y < block.y + block.height then
                -- Horizontal collision
                if cube.x < block.x then
                    -- Left edge
                    cube.dx = -math.abs(cube.dx)
                else
                    -- Right edge
                    cube.dx = math.abs(cube.dx)
                end
            end

            love.audio.newSource("bounce.ogg", "static"):play()
        end
    end
end

function game.draw()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    for _, block in ipairs(map) do
        love.graphics.rectangle("fill", block.x, block.y, block.width, block.height)
    end
    love.graphics.rectangle("fill", cube.x, cube.y, cube.size, cube.size)

    love.graphics.pop()
end

function game.keypressed(key)
    if key == "l" then
        game.loadMap("map.lua")
    end
end

function game.loadMap(filename)
    local mapFile = love.filesystem.load(filename)
    if mapFile then
        local loadedData = mapFile()
        map = loadedData.map
        spawnPoint = loadedData.spawnPoint
        game.resetCube()
    end
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

return game
