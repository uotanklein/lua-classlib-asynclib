# Lua ClassLib & AsyncLib

## Key Features

### 🏗️ **ClassLib - Object-Oriented Programming**
- **Clean syntax** for class creation and inheritance
- **Multiple inheritance** support
- **Abstract methods** for interface-like behavior
- **Optimized ID system** with lazy UUID generation
- **Object serialization** for persistence and networking

### ⚡ **AsyncLib - Asynchronous Programming**
- **Promise-based** async operations
- **Async/await syntax** for readable async code
- **Promise.all/race** for complex async patterns
- **Retry mechanisms** with configurable attempts
- **Timeout support** for reliable operations

## Features

### ClassLib
- ✅ Class creation syntax
- ✅ Multiple inheritance
- ✅ Abstract methods
- ✅ Optimized ID system (lazy UUID generation)
- ✅ Object serialization/deserialization
- ✅ Instance caching and performance optimization

### AsyncLib
- ✅ Promise compatibility
- ✅ Async/await syntax
- ✅ Promise.all, Promise.race
- ✅ Retry mechanism with configurable attempts
- ✅ Timeout support

## Installation

### Option 1: Direct Copy
1. Copy files to your project:
   - `classlib.lua`
   - `asynclib.lua`

2. Import in your code:
```lua
local classlib_module = require("classlib")
local asynclib_module = require("asynclib")
```

### Option 2: Git Clone
```bash
git clone <repository-url>
cd lua-classlib-asynclib
```

### Option 3: Package Manager
*Coming soon: Package manager support for LuaRocks and other package managers*

## Quick Start

### Creating Classes

```lua
local class = classlib_module.class

-- Simple class
local Animal = class("Animal")

function Animal:ctor(props)
    self.name = props.name or "Unknown"
    self.age = props.age or 0
end

function Animal:speak()
    return "Some sound"
end

-- Create instance
local animal = Animal({ name = "Buddy", age = 5 })
print(animal:speak()) -- "Some sound"
```

### Inheritance

```lua
local Dog = class("Dog", Animal)

function Dog:ctor(props)
    -- Call parent constructor
    Animal.ctor(self, props)
    self.breed = props.breed or "Unknown"
end

function Dog:speak()
    return "Woof!"
end

local dog = Dog({ name = "Rex", age = 3, breed = "German Shepherd" })
print(dog:speak()) -- "Woof!"
print(dog:instanceof(Animal)) -- true
```

### Abstract Methods

```lua
local AbstractShape = class("AbstractShape")

function AbstractShape:ctor(props)
    self.color = props.color or "black"
end

-- Declare abstract method
AbstractShape:abstract("calculate_area")

local Circle = class("Circle", AbstractShape)

function Circle:ctor(props)
    AbstractShape.ctor(self, props)
    self.radius = props.radius or 1
end

-- Implement abstract method
function Circle:calculate_area()
    return math.pi * self.radius * self.radius
end
```

### Serialization

```lua
local classlib = classlib_module.classlib

-- Serialize
local serialized = dog:serialize()

-- Deserialize
local deserialized = classlib.Serializer():deserialize(serialized)
print(deserialized.name) -- "Rex"
```

### Optimized ID System

The library uses an intelligent ID system that optimizes performance:

```lua
local obj = MyClass({})

-- Simple numeric ID by default (fast)
print(obj:__get_id()) -- 1, 2, 3, etc.

-- UUID format when serialization is used
local serialized = obj:serialize()
print(obj:__get_id()) -- "obj_1234567890_1234_1"

-- Manual UUID mode control
classlib.enable_uuid_mode()  -- Force UUID generation
classlib.disable_uuid_mode() -- Return to simple IDs

-- Check if ID is valid
print(classlib.is_uuid(obj:__get_id())) -- true
```

**Benefits:**
- ⚡ **Performance**: Simple IDs for most use cases
- 🔄 **Lazy generation**: ID generated only when accessed
- 🎯 **Smart switching**: UUID only when needed (serialization)
- 💾 **Memory efficient**: No unnecessary UUID storage

### Asynchronous Programming

```lua
local promiselib = asynclib_module.promiselib
local async = asynclib_module.async
local await = asynclib_module.await

-- Simple Promise
local promise = promiselib:new(function(resolve, reject)
    -- Async work
    resolve("Result")
end)

promise:after(function(result)
    print(result) -- "Result"
end):catch(function(error)
    print("Error:", error)
end)

-- Async/await
local async_function = async(function(name)
    -- Simulate delay
    await(promiselib:delay(1000))
    return "Hello, " .. name .. "!"
end)

async_function("World"):after(function(result)
    print(result) -- "Hello, World!"
end)
```

### Promise.all

```lua
local promises = {
    promiselib:resolve("First"),
    promiselib:resolve("Second"),
    promiselib:resolve("Third")
}

promiselib:all(promises):after(function(results)
    print(table.concat(results, ", ")) -- "First, Second, Third"
end)
```

### Promise.race

```lua
local race_promises = {
    promiselib:delay(3000):after(function() return "Slow" end),
    promiselib:delay(1000):after(function() return "Fast" end)
}

promiselib:race(race_promises):after(function(result)
    print(result) -- "Fast"
end)
```

### Retry Mechanism

```lua
local failing_operation = function()
    return promiselib:new(function(resolve, reject)
        if math.random() > 0.5 then
            resolve("Success!")
        else
            reject("Error")
        end
    end)
end

promiselib:retry(failing_operation, 3, 1000):after(function(result)
    print("Success after retry:", result)
end):catch(function(error)
    print("Failed after 3 attempts:", error)
end)
```

## API Reference

### ClassLib

#### `class(name, [parents])`
Creates a new class with multiple inheritance support.

#### `classlib.is(val)`
Checks if value is a class.

#### `classlib.is_instance(val)`
Checks if value is an instance.

#### `instance:instanceof(class)`
Checks if instance inherits from class (with caching).

#### `instance:serialize()`
Serializes instance to table.

#### `classlib.Serializer():deserialize(data)`
Deserializes data to instance.

#### `class:abstract(method_name)`
Declares an abstract method.

#### `instance:__get_id()`
Returns the instance ID (lazy generated).

#### `classlib.is_uuid(id)`
Checks if ID is valid (supports both simple IDs and UUIDs).

#### `classlib.enable_uuid_mode()`
Forces UUID generation mode for all future instances.

#### `classlib.disable_uuid_mode()`
Returns to simple ID generation mode.

### AsyncLib

#### `promiselib:new(executor)`
Creates a new Promise with executor function.

#### `promise:after(then_func)`
Adds success handler.

#### `promise:catch(catch_func)`
Adds error handler.

#### `promiselib:all(promises)`
Waits for all Promises and returns array of results.

#### `promiselib:race(promises)`
Returns result of first completed Promise.

#### `promiselib:resolve(value)`
Creates Promise that resolves immediately with value.

#### `promiselib:reject(error)`
Creates Promise that rejects immediately with error.

#### `promiselib:delay(ms)`
Creates Promise with delay.

#### `promiselib:retry(func, max_attempts, delay_ms)`
Retries function execution on error.

#### `promiselib:timeout(promise, ms)`
Adds timeout to Promise.

#### `async(func)`
Creates async function.

#### `await(promise_or_func)`
Waits for Promise completion (only inside async function).

## Testing

Run the comprehensive test suite:

```bash
lua test_libraries.lua
```

This will test all features of both libraries including:
- Class creation and inheritance
- Abstract methods
- Serialization/deserialization
- Optimized ID system
- All Promise features
- Async/await functionality
- Integration between libraries

## Examples

See `example.lua` for detailed usage examples and `test_libraries.lua` for comprehensive testing.
