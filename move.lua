local robot = require("robot")
local sides = require("sides")
local utils = require("utils")


local home
local home_cfg = io.open("home.cfg")
if home_cfg then
    home = utils.extractNums(home_cfg:read("*all"))
    home_cfg:close()
else
    home = {0, 0, 0}
end


local mySides = {
    [sides.front] = 1,
    [sides.right] = 2,
    [sides.back] = 3,
    [sides.left] = 4
}

local condTurn = {
    [ -3 ] = robot.turnRight,
    [ -2 ] = robot.turnAround,
    [ -1 ] = robot.turnLeft,
    [ 0 ] = function () end,
    [ 1 ] = robot.turnRight,
    [ 2 ] = robot.turnAround,
    [ 3 ] = robot.turnLeft
}

local move = {
    side = sides.front,
    x = home[1],
    y = home[2],
    z = home[3],
    forward = function (self)
        self:turn(sides.front)
        while not robot.forward() do end
        self.x = self.x + 1
    end,
    back = function (self)
        self:turn(sides.back)
        while not robot.forward() do end
        self.x = self.x - 1
    end,
    right = function (self)
        self:turn(sides.right)
        while not robot.forward() do end
        self.y = self.y + 1
    end,
    left = function (self)
        self:turn(sides.left)
        while not robot.forward() do end
        self.y = self.y - 1
    end,
    up = function (self)
        while not robot.up() do end
        self.z = self.z + 1
    end,
    down = function (self)
        while not robot.down() do end
        self.z = self.z - 1
    end,
    home = function (self)
        self:goTo(home[1], home[2], home[3], sides.front)
    end,
    goTo = function (self, x, y, z, side)
        if self.y ~= y or self.x ~= x then
            while self.z ~= 0 do
                if self.z > 0 then
                    self:down()
                else
                    self:up()
                end
            end
        end
        if self.x ~= x then
            while self.y ~= 0 do
                if self.y > 0 then
                    self:left()
                else
                    self:right()
                end
            end
        end
        while self.x ~= x do
            if self.x > x then
                self:back()
            else
                self:forward()
            end
        end
        while self.y ~= y do
            if self.y > y then
                self:left()
            else
                self:right()
            end
        end
        while self.z ~= z do
            if self.z > z then
                self:down()
            else
                self:up()
            end
        end
        self:turn(side)
    end,
    turn = function (self, side)
        condTurn[ mySides[side] - mySides[self.side] ]()
        self.side = side
    end
}

return move