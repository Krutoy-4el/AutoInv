print("Starting...")

local receiver = require("itemReceiver")
local saver = require("itemSaver")
local scanner = require("scanner")
local utils = require("utils")

local term = require("term")
local thread = require("thread")
local gpu = require("component").gpu
local unicode = require("unicode")
local keys = require("keyboard").keys

local function center(text)
    term.clearLine()
    local _, oldY = term.getCursor()
    local width, _ = gpu.getResolution()
    term.setCursor(width / 2 - unicode.len(text) / 2, oldY)
    term.write(text)
    term.setCursor(1, oldY + 1)
end

local function inputBuffer(prompt)
    local buffer = ""
    local lastUpdate = os.time()
    term.clearLine()
    term.write(prompt)

    local function get()
        return buffer
    end

    local function getTime()
        return lastUpdate
    end

    local function update()
        local _, _, key, code, _ = term.pull("key_down")
        lastUpdate = os.time()
        if code == keys.enter then
            return false
        elseif code == keys.back then
            buffer = unicode.sub(buffer, 1, unicode.len(buffer) - 1)
        elseif key ~= 0 then
            buffer = buffer .. unicode.char(key)
        end
        term.clearLine()
        term.write(prompt .. buffer)
        return true
    end

    return get, update, getTime
end

local function getKey()
    local _, _, _, code, _ = term.pull("key_down")
    local key = keys[code]
    if #key == 1 then
        term.write(key)
    end
    return key
end

local function clearBottom()
    local oldX, oldY = term.getCursor()
    local _, height = gpu.getResolution()
    for i = oldY + 1, height do
        term.setCursor(1, i)
        term.clearLine()
    end
    term.setCursor(oldX, oldY)
end

local function getItemMatches(name, limit)
    term.write("Loading...")
    limit = limit or 5
    local matches = {}
    local closeDir, fileList = utils.listDir("chests")
    for file in fileList do
        local closeFile, itemList = utils.listItems("chests/" .. file)
        for slotNum, slotInfo in itemList do
            if #slotInfo.name ~= 0
            and unicode.lower(slotInfo.name):match(unicode.lower(name))
            and not utils.contains(matches, slotInfo.name) then
                table.insert(matches, slotInfo.name)
            end
            if #matches >= limit then
                break
            end
        end
        closeFile()
        if #matches >= limit then
            break
        end
    end
    closeDir()
    term.clearLine()
    return matches
end

local function matchPrinter(data, time)
    return thread.create(
        function ()
            local prev = data()
            while true do
                os.sleep(0.1)
                if prev ~= data() and os.difftime(os.time(), time()) > 100 then
                    clearBottom()
                    local oldX, oldY = term.getCursor()
                    term.setCursor(1, oldY + 1)
                    for _, name in pairs(getItemMatches(data())) do
                        print(name)
                    end
                    term.setCursor(oldX, oldY)
                    prev = data()
                end
            end
        end
    )
end

local function askItemName()
    term.clear()
    local resName
    local getBuffer, updateBuffer, lastUpdate = inputBuffer("Item: ")
    local p = matchPrinter(getBuffer, lastUpdate)
    while updateBuffer() do
        -- os.sleep(0.01)
    end
    p:kill()
    term.clear()
    if #getBuffer() == 0 then
        return nil
    end
    local matches = getItemMatches(getBuffer(), 10)
    if #matches > 1 then
        for num, name in pairs(matches) do
            print(num .. " " .. name)
        end
        term.write("Enter your choice: ")
        resName = matches[tonumber(term.read())]
    elseif #matches < 1 then
        return nil
    else
        resName = matches[1]
    end
    return resName
end

local function askItemQuantity()
    term.write("Enter quantity: ")
    return tonumber(term.read())
end

local function getItemQuantity(name)
    term.write("Loading...")
    local quantity = 0
    local closeDir, fileList = utils.listDir("chests")
    for file in fileList do
        local closeFile, itemList = utils.listItems("chests/" .. file)
        for slotNum, slotInfo in itemList do
            if slotInfo.name == name then
                quantity = quantity + slotInfo.size
            end
        end
        closeFile()
    end
    closeDir()
    term.clearLine()
    return math.floor(quantity)
end

local function menu()
    term.clear()
    center("Main menu")
    print("s - store all items from robot's inventory")
    print("g - give you items from storage")
    print("c - shows total quantity of item in storage")
    print("u - update chests data (rescan storage)")
    print("q - quit\n")

    repeat
        term.write("Input: ")
        local key = getKey()
        print()

        if key == "s" then
            term.write("Saving items...\n")
            saver.saveAll()
            term.write("Done!")
            os.sleep(2.5)
            return
        elseif key == "u" then
            term.write("Updating chests data...\n")
            scanner.scanAll()
            term.write("Done!")
            os.sleep(2.5)
            return
        elseif key == "g" then
            local itemList = {}
            while true do
                local name = askItemName()
                if name then
                    print(name)
                    itemList[name] = askItemQuantity()
                    print(name .. " was added to the list.")
                else
                    print("The list wasn't updated.")
                end
                local yesOrNo
                repeat
                    term.clearLine()
                    term.write("Do you want to add more items (y/n): ")
                    yesOrNo = getKey()
                until yesOrNo == "y" or yesOrNo == "n"
                if yesOrNo == "n" then
                    break
                end
            end
            term.clear()
            term.write("Wait a minute...\n")
            receiver.bring(itemList)
            term.write("Done!")
            os.sleep(2.5)
            return
        elseif key == "c" then
            local name = askItemName()
            if name then
                print(name)
                term.write(getItemQuantity(name))
            else
                term.write("Item not selected!")
            end
            print("\nPress enter to continue...")
            term.read()
            return
        end
        local _, posY = term.getCursor()
        term.setCursor(1, posY - 1)
    until key == "q"
    term.clear()
    return true
end

while menu() ~= true do end