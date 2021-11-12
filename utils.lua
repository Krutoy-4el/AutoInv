local utils = {}


function utils.listDir(path)
    local entry = io.popen("list " .. path)

    local function close()
        entry:close()
    end

    local function nextEntry()
        return entry:read()
    end

    return close, nextEntry
end

function utils.listItems(filename)
    local file = io.open(filename)
    file:read()
    local slotNum = 0

    local function close()
        file:close()
    end

    local function nextSlot()
        local line = file:read()
        if not line then
            return nil
        end
        slotNum = slotNum + 1
        local slotInfo = {name = line}
        if #line ~= 0 then
            slotInfo.size = tonumber(file:read())
            slotInfo.maxSize = tonumber(file:read())
        end
        return slotNum, slotInfo
    end

    return close, nextSlot
end

function utils.extractNums(str)
    local res = {}
    local numbers = str:gmatch("-?%d+")
    local num = numbers()
    while num do
        table.insert(res, tonumber(num))
        num = numbers()
    end
    return res
end

function utils.contains(aTable, value)
    for _, v in pairs(aTable) do
        if v == value then
            return true
        end
    end
    return false
end

return utils