local robot = require("robot")
local sides = require("sides")
local move = require("move")
local scanner = require("scanner")
local utils = require("utils")
local inventory = require("component").inventory_controller


local function checkFile(filename, name, count, maxSize)
    local res = {}
    local allFreeSize = 0
    local close, slotList = utils.listItems(filename)
    for counter, slot in slotList do
        if #slot.name ~= 0 then
            if slot.name == name then
                if slot.size < slot.maxSize then
                    res[counter] = slot.maxSize - slot.size
                    allFreeSize = allFreeSize + res[counter]
                end
            end
        elseif not name then
            res[counter] = false
            allFreeSize = allFreeSize + maxSize
        end
        if allFreeSize >= count then
            break
        end
    end
    close()
    return allFreeSize, res
end

local function checkDir(name, count, maxSize)
    local res = {}
    local allFreeSize = 0
    local close, chests = utils.listDir("chests")
    for filename in chests do
        local freeSize, val = checkFile("chests/" .. filename, name, count, maxSize)
        if freeSize > 0 then
            res[filename] = val
            allFreeSize = allFreeSize + freeSize
            if allFreeSize >= count then
                break
            end
        end
    end
    close()
    return res
end

local function saveSlot(slot)
    local chests = checkDir(slot.label, slot.size, slot.maxSize)
    local size = slot.size
    while size > 0 do
        for chest, slots in pairs(chests) do
            move:goTo(table.unpack(utils.extractNums(chest)))
            for slotNum, freeSize in pairs(slots) do
                inventory.dropIntoSlot(sides.front, slotNum, freeSize or slot.maxSize)
                size = size - (freeSize or slot.maxSize)
            end
            scanner.scanChest()
            if size <= 0 then
                break
            end
        end
        if size > 0 then
            chests = checkDir(nil, slot.size, slot.maxSize)
        end
    end
end

local function saveAll()
    for i = 1, robot.inventorySize() do
        local slot = inventory.getStackInInternalSlot(i)
        if slot then
            robot.select(i)
            saveSlot(slot)
        end
    end
    move:home()
end

return {saveAll = saveAll}