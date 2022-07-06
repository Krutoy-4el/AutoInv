local base = "https://github.com/Krutyi-4el/AutoInv/raw/main/"
local files = {
    "autoinv.lua",
    "itemReceiver.lua",
    "itemSaver.lua",
    "move.lua",
    "scanner.lua",
    "utils.lua"
}
local configs = {"size.cfg"}

local shell = require("shell")
local fs = require("filesystem")

local args, options = shell.parse(...)
local dir
if #args < 1 then
    dir = "autoinv"
else
    dir = args[1]
end
dir = fs.concat(os.getenv("PWD"), dir)

print("Target directory: " .. dir)
fs.makeDirectory(dir)

local wget_path = shell.resolve("wget", "lua")
local wget = loadfile(wget_path)

print("Starting download.")

for _, file in pairs(files) do
    if not wget("-f", base .. file, fs.concat(dir, file)) then
        io.stderr:write("Failed.")
        return
    end
end
for _, file in pairs(configs) do
    if not fs.exists(fs.concat(dir, file)) then
        if not wget(base .. file, fs.concat(dir, file)) then
            io.stderr:write("Failed.")
            return
        end
    end
end

print("Finished.")