local sides = require("sides")
local move = require("move")
local inventory = require("component").inventory_controller
local utils = require("utils")


local size_cfg = io.open("size.cfg")
local sizes = utils.extractNums(size_cfg:read("*all"))
size_cfg:close()

local limits = {
    back = sizes[1],
    front = sizes[2],
    left = sizes[3],
    right = sizes[4],
    bottom = sizes[5],
    top = sizes[6]
}
for k, v in pairs(limits) do
    limits[k] = tonumber(v)
end

local function scanChest()
    local size = inventory.getInventorySize(sides.front)
    if size then
        local chest_save = io.open("chests/" .. move.x .. "_" .. move.y .. "_" .. move.z .. "_" .. move.side, "w")
        for i = 1, size do
            chest_save:write("\n")
            local slot = inventory.getStackInSlot(sides.front, i)
            if slot then
                chest_save:write(slot.label .. "\n")
                chest_save:write(slot.size .. "\n")
                chest_save:write(slot.maxSize)
            end
        end
        chest_save:close()
    end
end

local function scanHere()
    local turn1, turn2 = sides.back, sides.front
    if move.z % 2 == 1 then
        turn1, turn2 = turn2, turn1
    end
    move:turn(turn1)
    scanChest()
    move:turn(turn2)
    scanChest()
end

local function scanZ()
    for _ = 1, limits.bottom do
        move:down()
    end
    while move.z < limits.top do
        scanHere()
        move:up()
    end
    scanHere()
    while move.z > 0 do
        move:down()
    end
end

local function scanY()
    for _ = 1, limits.left do
        move:left()
    end
    while move.y < limits.right do
        scanZ()
        move:right()
    end
    scanZ()
    while move.y > 0 do
        move:left()
    end
end

local function scanAll()
    os.execute("rm -r -f chests")
    os.execute("mkdir chests")
    move:goTo(0, 0, 0, sides.front)
    for _ = 1, limits.back do
        move:back()
    end
    while move.x < limits.front do
        scanY()
        move:forward()
        move:forward()
        move:forward()
    end
    scanY()
    move:home()
end


return {scanAll = scanAll, scanChest = scanChest}