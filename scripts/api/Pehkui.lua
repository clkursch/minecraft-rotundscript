--@class Pehkui
local pehkui = {}

-- LIBRARIES
local queueLib

for _, path in ipairs(listFiles("/", true)) do
    if string.find(path, "Queue") then queueLib = require(path) end
end
assert(queueLib, "Missing Queue file! Make sure to download that from the GitHub too!")

-- VARIABLES
pehkui.options = {
    ["pehkui:base"]             = true,
    ["pehkui:width"]            = true,
    ["pehkui:height"]           = true,
    ["pehkui:hitbox_width"]     = true,
    ["pehkui:hitbox_height"]    = true,
    ["pehkui:eye_height"]       = true,
    ["pehkui:model_width"]      = true,
    ["pehkui:model_height"]     = true,
    ["pehkui:third_person"]     = true,
    ["pehkui:motion"]           = true,
    ["pehkui:step_height"]      = true,
    ["pehkui:view_bobbing"]     = true,
    ["pehkui:falling"]          = true,
    ["pehkui:flight"]           = true,
    ["pehkui:jump_height"]      = true,
    ["pehkui:visibility"]       = true,
    ["pehkui:reach"]            = true,
    ["pehkui:block_reach"]      = true,
    ["pehkui:entity_reach"]     = true,
    ["pehkui:held_item"]        = true,
    ["pehkui:drops"]            = true,
    ["pehkui:projectiles"]      = true,
    ["pehkui:explosions"]       = true,
    ["pehkui:attack"]           = true,
    ["pehkui:defense"]          = true,
    ["pehkui:knockback"]        = true,
    ["pehkui:health"]           = true,
    ["pehkui:mining_speed"]     = true,
    ["pehkui:attack_speed"]     = true
}

local queueTimer = 0
local commandQueue = queueLib:new()

-- FLAGS
local function loadConfig()
    for k, default in pairs(pehkui.options) do
        local stored = config:load(k)
        if stored == nil then
            config:save(k, default)
            -- log("Created config entry: " .. k .. " = " .. tostring(default))
        else
            pehkui.options[k] = stored
            -- log("Loaded config entry: " .. k .. " = " .. tostring(stored))
        end
    end
end

--- Sets the state of a flag
--- @param scale string The scaling option as string
--- @param state boolean Whether the script should scale this option
function pehkui.setScaleState(scale, state)
    assert(pehkui.options[scale] ~= nil, 'Unknown scaling option')
    pehkui.options[scale] = state
    config:save(scale, state)
end

-- EVENTS
function events.entity_init()
    if not host:isHost() then return end
	pehkui.pehkuiCheck = client:isModLoaded("pehkui")
	pehkui.p4aCheck = client:isModLoaded("pehkui4all")
    pehkui.opCheck = player:getPermissionLevel() == 4   

    -- COMMENT THIS CODE BLOCK OUT IF YOU DISLIKE THE STARTUP MESSAGE \/

    if pehkui.pehkuiCheck then
        if pehkui.opCheck then
            --print("OP detected!\nYou have full, unrestricted access to Pehkui scaling. Have fun!")
        elseif pehkui.p4aCheck then
            print("P4A detected!\nYou have basic access to Pehkui scaling.")
        else
            print("Insufficient permissions for Pehkui scaling. Module has been disabled")
        end	
    else
        print("Pehkui isn't installed, scaling has been disabled!")
    end

    -- COMMENT THIS CODE BLOCK OUT IF YOU DISLIKE THE STARTUP MESSAGE /\

    loadConfig()
end

function events.tick()
    if queueTimer > 20 then 
        queueTimer = 0

        if commandQueue:isEmpty() then return end

        local command = commandQueue:pop()

        host:sendChatCommand(command)
    else queueTimer = queueTimer + 1 end
end

-- SCALING
--- Sends scaling command with provided values. Can be forced.
--- @param scale string The scaling option as string
--- @param value number The value of the scaling option
--- @param forceScaling boolean If true, forces the function to push a command regardless of the flag state
function pehkui.setScale(scale, value, forceScaling)
    if not host:isHost() then return end
    if pehkui.options[scale] == false and not forceScaling then return end

    if pehkui.pehkuiCheck then
        if pehkui.opCheck then host:sendChatCommand('scale set '..scale..' '..value..' @s')
        elseif pehkui.p4aCheck then
            local str = string.format('p4ascale set "%s" %s', scale, value) -- the command
            local IndexToReplace

            for index,param in pairs(commandQueue.data) do
                if string.find(param, scale) then
                    IndexToReplace = index
                    break
                end
            end

            if IndexToReplace then
                queueTimer = 0
                commandQueue.data[IndexToReplace] = str
            else commandQueue:push(str) end
        end
    end
end

return pehkui
