local sides = require("sides")
local move = require("move")
local scanner = require("scanner")
local utils = require("utils")
local inventory = require("component").inventory_controller


local function scanFile(filename, name, count)
    local res = {}
    local allSize = 0
    local close, itemList = utils.listItems(filename)
    for counter, item in itemList do
        if item.name == name then
            res[counter] = item.size
            allSize = allSize + item.size
            if count - allSize <= 0 then
                break
            end
        end
    end
    close()
    return allSize, res
end

local function scanDir(name, count)
    local res = {}
    local allSize = 0
    local close, fileList = utils.listDir("chests")
    for filename in fileList do
        local size, val = scanFile("chests/" .. filename, name, count)
        if size > 0 then
            res[filename] = val
            allSize = allSize + size
            if allSize >= count then
                break
            end
        end
    end
    close()
    return res
end

local function take(name, count)
    if count <= 0 then
        return
    end
    local chests = scanDir(name, count)
    for chest, slots in pairs(chests) do
        move:goTo(table.unpack(utils.extractNums(chest)))
        for slot, size in pairs(slots) do
            count = count - (inventory.suckFromSlot(sides.front, slot, count) or 0)
        end
        scanner.scanChest()
        if count <= 0 then
            break
        end
    end
end

local function bring(items)
    for item, count in pairs(items) do
        take(item, count)
    end
    move:home()
end

return {bring = bring}