local particleSize = 2
local width = 1920 / particleSize
local height = 1080 / particleSize
local simulation = nil
local size = 50
local UI
local setColor = love.graphics.setColor
local points = love.graphics.points
local line = love.graphics.line
local circle = love.graphics.circle
local isMouseDown = love.mouse.isDown
local floor = math.floor
local timer
local printThread

-- Global variables
particleCount = 0
currentType = 2
debug = false
paused = nil
particleTypes = nil
mouseDx = 0
mouseDy = 0
mouseX = 0
mouseY = 0
lastMouseX = 0
lastMouseY = 0
-- End Global Variables

local pChannel = love.thread.getChannel ("print")

function print(string)
    pChannel:push(string)
end

function love.load()

    success = love.window.setMode(width * particleSize, height * particleSize, {vsync=true})
    printThread=love.thread.newThread( [[
        while true do
            local str = love.thread.getChannel( 'print' ):pop()  
            if(str) then
                print(str)
            end
        end ]] ) 
    print("Starting Particles Simulation")
    printThread:start()
    love.graphics.setDefaultFilter("nearest", "nearest", 0)
    simulation = require'Resources.scripts.simulation'.new(width,height,particleSize)
    particleTypes = simulation.particleTypes
    
    -- Hide the mouse Cursor
    love.mouse.setVisible(false)

    timer= require 'Resources.lib.hump.timer'

    UI=require'Resources.scripts.UI'.load()

end

function love.update(dt)

    timer.update(dt)
    if not UI.showButtons then
        if isMouseDown(1) then
            --draw a circle filed of particles (every pixel filled)
            for y = floor(-size/simulation.particleSize), floor(size/simulation.particleSize) + 1 do
                for x = floor(-size/simulation.particleSize), floor(size/simulation.particleSize) + 1 do
                    if (x*x + y*y) < (size*size) / (simulation.particleSize * simulation.particleSize) then
                        local offsetX = floor(mouseX / simulation.particleSize)
                        local offsetY = floor(mouseY / simulation.particleSize)
                        local index = simulation:calculate_index(offsetX + x, offsetY + y)
                        local type, success = simulation:get_index(offsetX + x, offsetY + y)
                        if type == 1 and success and currentType ~= 1 then
                            simulation:set_index(offsetX + x, offsetY + y, currentType)
                        elseif currentType == 1 and type ~= 1 and success then
                            simulation:set_index(offsetX + x, offsetY + y, currentType)
                        end
                    end
                end
            end
        end
    end

    size = math.clamp(size, 1, 1000)
    UI:update(dt)
    if paused then
        return
    end
    simulation:update(dt)
end


function love.draw()

    local selectedTextY = 10 -- verify this variable position, probably should be inside the Draw function below.


    love.graphics.setLineWidth(1)
    if(not love.mouse.getRelativeMode()) then
        mouseX, mouseY = love.mouse.getPosition() -- same as mouseX = love.mouse.getX() + mouseY = love.mouse.getY()
    end

    love.graphics.setPointSize(particleSize)
    simulation:draw()
    UI:draw()

    love.graphics.setColor(0, 0, 0)

    if(debug) then
        love.graphics.print("FPS: "..love.timer.getFPS(), 5, 10) -- get the FPS from the timer library and print at location 5, 10
        love.graphics.print("Particles: "..particleCount, 5, 24) -- print our particleCount at location 5, 24
    end
    
    if paused then
        love.graphics.print("PAUSED", love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    end

    love.graphics.print("Selected particle type: "..particleTypes[currentType][1],5,selectedTextY)

    line(mouseX-8,mouseY,mouseX-3,mouseY)
    line(mouseX+8,mouseY,mouseX+3,mouseY)
    line(mouseX,mouseY-8,mouseX,mouseY-3)
    line(mouseX,mouseY-8,mouseX,mouseY+3)

    circle("line",mouseX,mouseY,size,200)

    if love.mouse.getRelativeMode() then
        love.graphics.setLineWidth(3)
        line(mouseX,mouseY, love.mouse.getX(),love.mouse.getY())
    end
end



function math.clamp(value, min, max)
    if(value > max) then
        value = max
    elseif value < min then
        value = min
    end
    return value
end

function love.mousepressed(x, y, button)

    if button == 1 then
        u.pressed(x,y)
    elseif button == 2 then
        showButtons = true
        lastMouseX = x
        lastMouseY = y
        love.mouse.setRelativeMode(true)
    end
end


function love.mousereleased(x, y, button)
    if button==1 then
        u.released(x, y)
    elseif button==2 then
        showButtons=false
        love.mouse.setRelativeMode(false)
        love.mouse.setPosition(lastMouseX,lastMouseY)
    end
end

function love.mousemoved(x,y,dx,dy,isTouch)
    mouseDx=dx
    mouseDy=dy
end


function love.wheelmoved(x, y)
    if(not UI.showButtons)then
        size=size+y
    end
end

function love.keypressed(key)
    if(key=='lalt')then
        debug=not debug
        selectedTextY = debug and 38 or 10
    end
    if(key=='p')then
        paused=not paused
    end
    if(key=="[")then
		size=size/2
	elseif(key=="]")then
		size=size*2
    end
end