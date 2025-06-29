-- Example of using ClassLib and AsyncLib for Lua
-- Run: lua example.lua

-- Local variables for frequently used Lua functions (performance optimization)
local print = print
local pairs = pairs
local string_format = string.format
local table_concat = table.concat
local math_random = math.random
local math_pi = math.pi

-- Import libraries
local classlib_module = require("classlib")
local asynclib_module = require("asynclib")

local class = classlib_module.class
local classlib = classlib_module.classlib
local promiselib = asynclib_module.promiselib
local async = asynclib_module.async
local await = asynclib_module.await

print("=== Example of using ClassLib and AsyncLib for Lua ===\n")

-- Example 1: Simple class
print("1. Creating a simple class:")
local Animal = class("Animal")

function Animal:ctor(props)
    self.name = props.name or "Unknown"
    self.age = props.age or 0
    print("Created animal:", self.name)
end

function Animal:speak()
    return "Some sound"
end

function Animal:get_info()
    return string_format("Name: %s, Age: %d", self.name, self.age)
end

local animal = Animal({ name = "Generic Animal", age = 5 })
print("Animal info:", animal:get_info())
print("Animal speaks:", animal:speak())
print()

-- Example 2: Inheritance
print("2. Inheritance:")
local Dog = class("Dog", Animal)

function Dog:ctor(props)
    -- Call parent constructor
    Animal.ctor(self, props)
    self.breed = props.breed or "Unknown"
end

function Dog:speak()
    return "Woof!"
end

function Dog:get_breed()
    return self.breed
end

local dog = Dog({ name = "Buddy", age = 3, breed = "Golden Retriever" })
print("Dog info:", dog:get_info())
print("Dog breed:", dog:get_breed())
print("Dog speaks:", dog:speak())
print("Dog instanceof Animal:", dog:instanceof(Animal))
print("Dog instanceof Dog:", dog:instanceof(Dog))
print()

-- Example 3: Abstract methods
print("3. Abstract methods:")
local AbstractShape = class("AbstractShape")

function AbstractShape:ctor(props)
    self.color = props.color or "black"
end

AbstractShape:abstract("calculate_area")
AbstractShape:abstract("calculate_perimeter")

function AbstractShape:get_color()
    return self.color
end

local Circle = class("Circle", AbstractShape)

function Circle:ctor(props)
    AbstractShape.ctor(self, props)
    self.radius = props.radius or 1
end

function Circle:calculate_area()
    return math_pi * self.radius * self.radius
end

function Circle:calculate_perimeter()
    return 2 * math_pi * self.radius
end

local circle = Circle({ color = "red", radius = 5 })
print("Circle color:", circle:get_color())
print("Circle area:", circle:calculate_area())
print("Circle perimeter:", circle:calculate_perimeter())
print()

-- Example 4: Serialization
print("4. Serialization:")
local serialized = dog:serialize()
print("Serialized dog:")
for k, v in pairs(serialized) do
    print("  " .. k .. ":", v)
end

local deserialized = classlib.Serializer():deserialize(serialized)
print("Deserialized dog name:", deserialized.name)
print("Deserialized dog breed:", deserialized:get_breed())
print()

-- Example 5: Simple Promises
print("5. Simple Promises:")
local promise1 = promiselib:new(function(resolve, reject)
    print("  Executing asynchronous operation...")
    local start_time = os.time()
    while os.time() - start_time < 1 do
        -- Simple busy wait
        local dummy = 0
        for i = 1, 100000 do
            dummy = dummy + 1
        end
    end
    resolve("Operation completed successfully!")
end)

promise1:after(function(result)
    print("  Result:", result)
end):catch(function(error)
    print("  Error:", error)
end)
print()

-- Example 6: Async/Await
print("6. Async/Await:")
local async_function = async(function(name)
    print("  Starting async function for", name)
    
    -- Simulate delay using promiselib:delay
    await(promiselib:delay(100))
    
    print("  After delay for", name)
    
    -- Return result
    return "Hello, " .. name .. "!"
end)

-- Run async function
async_function("World"):after(function(result)
    print("  Async function result:", result)
end):catch(function(error)
    print("  Error in async function:", error)
end)
print()

-- Example 7: Promise.all
print("7. Promise.all:")
local promises = {
    promiselib:resolve("First"),
    promiselib:resolve("Second"),
    promiselib:resolve("Third")
}

promiselib:all(promises):after(function(results)
    print("  All Promises completed:", table_concat(results, ", "))
end)
print()

-- Example 8: Promise.race
print("8. Promise.race:")
local race_promises = {
    promiselib:delay(300):after(function() return "Slow" end),
    promiselib:delay(100):after(function() return "Fast" end),
    promiselib:delay(200):after(function() return "Medium" end)
}

promiselib:race(race_promises):after(function(result)
    print("  Race winner:", result)
end)
print()

-- Example 9: Retry mechanism
print("9. Retry mechanism:")
local failing_operation = function()
    return promiselib:new(function(resolve, reject)
        local random = math_random(1, 10)
        if random > 7 then
            resolve("Success!")
        else
            reject("Temporary error")
        end
    end)
end

promiselib:retry(failing_operation, 3, 100):after(function(result)
    print("  Retry successful:", result)
end):catch(function(error)
    print("  Retry failed:", error)
end)
print()

print("=== All examples completed! ===") 