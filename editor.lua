-- editor.lua
local editor = {}
local map = {}
local spawnPoint = { x = 100, y = 100 }
local currentBlock = { x = 0, y = 0, width = 50, height = 50 }
local placingMode = "block" -- block, spawn, finish, resize
local camera = { x = 0, y = 0, speed = 200 }
local resizingBlock = nil
local mousePressed = false
local filenameInputMode = false
local filenameBuffer = ""
local mapFiles = {}
local selectedMapIndex = 1
local loadingMap = false
local serpent = require("serpent")

function editor.load()
    editor.loadMapFiles()
end

function editor.update(dt)
    if filenameInputMode or loadingMap then return end

    local x, y = love.mouse.getPosition()
    local adjustedX, adjustedY = x + camera.x, y + camera.y

    -- Update block positions and sizes
    if placingMode == "spawn" then
        spawnPoint.x = adjustedX
        spawnPoint.y = adjustedY
    elseif placingMode == "resize" and resizingBlock and mousePressed then
        -- Update the dimensions of the resizing block only while the mouse is pressed
        resizingBlock.width = math.max(1, adjustedX - resizingBlock.x)
        resizingBlock.height = math.max(1, adjustedY - resizingBlock.y)
    else
        currentBlock.x = adjustedX - currentBlock.width / 2
        currentBlock.y = adjustedY - currentBlock.height / 2
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
    love.graphics.print("Press F to place finish block", 10, 110)
    love.graphics.print("Press R to resize blocks", 10, 130)
    love.graphics.print("Use arrow keys to scroll", 10, 150)
    love.graphics.print("Press ESC to return to the menu", 10, 170)
    love.graphics.print("Current mode: " .. placingMode, 10, 190)

    if filenameInputMode then
        love.graphics.print("Enter filename and press Enter:", 10, 210)
        love.graphics.print(filenameBuffer, 10, 230)
    end

    if loadingMap then
        love.graphics.print("Select a map to load:", 10, 210)
        for i, filename in ipairs(mapFiles) do
            local y = 230 + 20 * (i - 1)
            if i == selectedMapIndex then
                love.graphics.print("> " .. filename, 10, y)
            else
                love.graphics.print(filename, 10, y)
            end
        end
    end
end

function editor.keypressed(key)
    if filenameInputMode then
        if key == "backspace" then
            filenameBuffer = filenameBuffer:sub(1, -2)
        elseif key == "return" then
            editor.saveMap("maps/" .. filenameBuffer .. ".bmap")
            filenameInputMode = false
            filenameBuffer = ""
        else
            filenameBuffer = filenameBuffer .. key
        end
    elseif loadingMap then
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
            editor.loadMap(mapFiles[selectedMapIndex])
            loadingMap = false
        elseif key == "escape" then
            loadingMap = false
        end
    else
        if key == "s" then
            filenameInputMode = true
        elseif key == "l" then
            loadingMap = true
        elseif key == "p" then
            placingMode = "spawn"
        elseif key == "f" then
            placingMode = "finish"
        elseif key == "r" then
            placingMode = "resize"
        else
            placingMode = "block"
        end
    end
end

function editor.mousepressed(x, y, button)
    local adjustedX, adjustedY = x + camera.x, y + camera.y

    if button == 1 then
        mousePressed = true
        if placingMode == "spawn" then
            placingMode = "block"
        elseif placingMode == "finish" then
            table.insert(map, { x = currentBlock.x, y = currentBlock.y, width = currentBlock.width, height = currentBlock.height, finish = true })
            placingMode = "block"
        elseif placingMode == "resize" then
            resizingBlock = nil
            for _, block in ipairs(map) do
                if adjustedX >= block.x and adjustedX <= block.x + block.width and adjustedY >= block.y and adjustedY <= block.y + block.height then
                    resizingBlock = block
                    break
                end
            end
        else
            table.insert(map, { x = currentBlock.x, y = currentBlock.y, width = currentBlock.width, height = currentBlock.height })
        end
    elseif button == 2 then
        for i = #map, 1, -1 do
            local block = map[i]
            if adjustedX >= block.x and adjustedX <= block.x + block.width and adjustedY >= block.y and adjustedY <= block.y + block.height then
                table.remove(map, i)
                break
            end
        end
    end
end

function editor.mousereleased(x, y, button)
    if button == 1 then
        mousePressed = false
        resizingBlock = nil
    end
end

function editor.saveMap(filename)
    local data = { map = map, spawnPoint = spawnPoint }
    local serializedData = serpent.block(data)
    love.filesystem.write(filename, serializedData)
end

function editor.loadMap(filename)
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
end

function editor.loadMapFiles()
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

return editor
