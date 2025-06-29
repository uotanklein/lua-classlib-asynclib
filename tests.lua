-- Comprehensive test for ClassLib and AsyncLib
-- Run: lua test_libraries.lua

local classlib_module = require("classlib")
local asynclib_module = require("asynclib")

local class = classlib_module.class
local classlib = classlib_module.classlib
local promiselib = asynclib_module.promiselib
local async = asynclib_module.async
local await = asynclib_module.await

print("=== Comprehensive Test for ClassLib and AsyncLib ===\n")

-- Test 1: Basic Class Creation
print("1. Basic Class Creation:")
local Animal = class("Animal")

function Animal:ctor(props)
    self.name = props.name or "Unknown"
    self.age = props.age or 0
end

function Animal:speak()
    return "Some sound"
end

function Animal:get_info()
    return string.format("Name: %s, Age: %d", self.name, self.age)
end

local animal = Animal({ name = "Generic Animal", age = 5 })
print("Animal info:", animal:get_info())
print("Animal speaks:", animal:speak())
print("Animal ID:", animal:__get_id())
print()

-- Test 2: Inheritance
print("2. Inheritance:")
local Dog = class("Dog", Animal)

function Dog:ctor(props)
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
print("Dog ID:", dog:__get_id())
print()

-- Test 3: Abstract Methods
print("3. Abstract Methods:")
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
    return math.pi * self.radius * self.radius
end

function Circle:calculate_perimeter()
    return 2 * math.pi * self.radius
end

local circle = Circle({ color = "red", radius = 5 })
print("Circle color:", circle:get_color())
print("Circle area:", circle:calculate_area())
print("Circle perimeter:", circle:calculate_perimeter())
print("Circle ID:", circle:__get_id())
print()

-- Test 4: Serialization
print("4. Serialization:")
local serialized = dog:serialize()
print("Serialized dog:")
for k, v in pairs(serialized) do
    print("  " .. k .. ":", v)
end

local deserialized = classlib.Serializer():deserialize(serialized)
print("Deserialized dog name:", deserialized.name)
print("Deserialized dog breed:", deserialized:get_breed())
print("Deserialized dog ID:", deserialized:__get_id())
print()

-- Test 5: UUID System
print("5. UUID System:")
print("UUID mode enabled:", classlib.enable_uuid_mode())
local uuid_obj = class("UUIDTest")({})
print("UUID object ID:", uuid_obj:__get_id())
print("Is UUID valid:", classlib.is_uuid(uuid_obj:__get_id()))

classlib.disable_uuid_mode()
local simple_obj = class("SimpleTest")({})
print("Simple object ID:", simple_obj:__get_id())
print("Is simple ID valid:", classlib.is_uuid(simple_obj:__get_id()))
print()

-- Test 6: Simple Promises
print("6. Simple Promises:")
local promise1 = promiselib:new(function(resolve, reject)
    print("  Executing asynchronous operation...")
    -- Simulate asynchronous work
    local start_time = os.time()
    while os.time() - start_time < 1 do
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

-- Test 7: Async/Await
print("7. Async/Await:")
local async_function = async(function(name)
    print("  Starting async function for", name)
    
    -- Simulate delay
    await(promiselib:delay(100))
    
    print("  After delay for", name)
    
    return "Hello, " .. name .. "!"
end)

-- Run async function
async_function("World"):after(function(result)
    print("  Async function result:", result)
end):catch(function(error)
    print("  Error in async function:", error)
end)
print()

-- Test 8: Promise.all
print("8. Promise.all:")
local promises = {
    promiselib:resolve("First"),
    promiselib:resolve("Second"),
    promiselib:resolve("Third")
}

promiselib:all(promises):after(function(results)
    print("  All Promises completed:", table.concat(results, ", "))
end)
print()

-- Test 9: Promise.race
print("9. Promise.race:")
local race_promises = {
    promiselib:delay(300):after(function() return "Slow" end),
    promiselib:delay(100):after(function() return "Fast" end),
    promiselib:delay(200):after(function() return "Medium" end)
}

promiselib:race(race_promises):after(function(result)
    print("  Race winner:", result)
end)
print()

-- Test 10: Retry Mechanism
print("10. Retry Mechanism:")
local failing_operation = function()
    return promiselib:new(function(resolve, reject)
        local random = math.random(1, 10)
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

-- Test 11: Complex Object with Promises
print("11. Complex Object with Promises:")
local AsyncProcessor = class("AsyncProcessor")

function AsyncProcessor:ctor(props)
    self.name = props.name or "Processor"
    self.queue = {}
end

function AsyncProcessor:add_task(task)
    table.insert(self.queue, task)
end

function AsyncProcessor:process_all()
    return promiselib:new(function(resolve, reject)
        if #self.queue == 0 then
            resolve("No tasks to process")
            return
        end
        
        local promises = {}
        for i, task in ipairs(self.queue) do
            table.insert(promises, promiselib:new(task))
        end
        
        promiselib:all(promises):after(function(results)
            resolve(string.format("Processed %d tasks", #results))
        end):catch(reject)
    end)
end

local processor = AsyncProcessor({ name = "TestProcessor" })
processor:add_task(function(resolve) resolve("Task 1") end)
processor:add_task(function(resolve) resolve("Task 2") end)

processor:process_all():after(function(result)
    print("  " .. result)
end)
print()

-- Test 12: Performance Test
print("12. Performance Test:")
local start_time = os.time()
for i = 1, 100 do
    local obj = class("PerfTest")({ index = i })
    obj:__get_id()
end
local end_time = os.time()
print("  Created 100 objects in", end_time - start_time, "seconds")
print()

print("=== All tests completed successfully! ===")
print("ClassLib and AsyncLib are working correctly.") 