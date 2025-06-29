-- AsyncLib

local classlib_module = require("classlib")
local class = classlib_module.class
local classlib = classlib_module.classlib

local promiselib = {}

local STATE_PENDING = 1
local STATE_FULFILLED = 2
local STATE_REJECTED = 3

local table_insert = table.insert
local ipairs = ipairs
local pcall = pcall
local coroutine = coroutine
local error = error
local unpack = unpack or table.unpack
local isfunction = classlib_module.isfunction

local function create_timer(ms, callback)
    local start_time = os.time()
    local function check()
        if os.time() - start_time >= ms / 1000 then
            callback()
        else
            local dummy = 0
            for i = 1, 1000000 do
                dummy = dummy + 1
            end
            check()
        end
    end
    check()
end

local Promise = class("Promise")

function Promise:ctor(props)
    local func = props.func
    self[1] = STATE_PENDING
    self[2] = nil
    self[3] = {}
    self[4] = {}
    func(function(res) self:resolve(res) end, function(err) self:reject(err) end)
end

function Promise:resolve(res)
    if self[1] == STATE_PENDING then
        self[1] = STATE_FULFILLED
        self[2] = res
        for _, cb in ipairs(self[3]) do
            cb(res)
        end
    end
end

function Promise:reject(res)
    if self[1] == STATE_PENDING then
        self[1] = STATE_REJECTED
        self[2] = res
        for _, cb in ipairs(self[4]) do
            cb(res)
        end
    end
end

function Promise:after(then_func)
    return promiselib:new(function(resolve, reject)
        local function handle(val)
            local ok, res = pcall(then_func, val)
            if not ok then
                reject(res)
                return
            end
            if promiselib.is(res) then
                res:after(resolve):catch(reject)
            else
                resolve(res)
            end
        end

        if self[1] == STATE_FULFILLED then
            handle(self[2])
        elseif self[1] == STATE_PENDING then
            table_insert(self[3], handle)
        elseif self[1] == STATE_REJECTED then
            reject(self[2])
        end
    end)
end

function Promise:catch(catch_func)
    return promiselib:new(function(resolve, reject)
        local function handle(err_val)
            local ok, res = pcall(catch_func, err_val)
            if not ok then
                reject(res)
                return
            end
            if promiselib.is(res) then
                res:after(resolve):catch(reject)
            else
                resolve(res)
            end
        end
        
        if self[1] == STATE_REJECTED then
            handle(self[2])
        elseif self[1] == STATE_PENDING then
            table_insert(self[4], handle)
        elseif self[1] == STATE_FULFILLED then
            resolve(self[2])
        end
    end)
end

function promiselib:new(func)
    return Promise({
        func = func,
    })
end

function promiselib:all(promises)
    return self:new(function(resolve, reject)
        local results = {}
        local remaining = #promises
        
        for i, promise in ipairs(promises) do
            promise:after(function(res)
                results[i] = res
                remaining = remaining - 1
                if remaining == 0 then resolve(results) end
            end):catch(reject)
        end
    end)
end

function promiselib:race(promises)
    return self:new(function(resolve, reject)
        for _, promise in ipairs(promises) do
            promise:after(resolve):catch(reject)
        end
    end)
end

function promiselib:resolve(value)
    return self:new(function(resolve) resolve(value) end)
end

function promiselib:reject(error)
    return self:new(function(resolve, reject) reject(error) end)
end

function promiselib:timeout(promise, ms)
    return self:race({
        promise,
        self:new(function(resolve, reject)
            create_timer(ms, function()
                reject("timeout")
            end)
        end)
    })
end

function promiselib.is(val)
    return val and classlib.is_instance(val) and val:instanceof(Promise)
end

local function async(func)
    return function(...)
        local co = coroutine.create(func)
        local args = {...}
        local promise = promiselib:new(function(resolve, reject)
            local function step(...)
                local ok, res = coroutine.resume(co, ...)
                if not ok then
                    reject(res)
                    return
                end

                local co_status = coroutine.status(co)
                if co_status == "suspended" then
                    if not promiselib.is(res) then
                        reject("Invalid promise returned from await: " .. tostring(res))
                        return
                    end

                    res:after(function(val) step(val) end):catch(function(err) reject(err) end)
                elseif co_status == "dead" then
                    resolve(res)
                end
            end

            step(unpack(args))
        end)
        return promise
    end
end

local function await(promise_or_func)
    local co = coroutine.running()
    if not co then error("await can only be called inside an async function") end
    
    local promise
    if isfunction(promise_or_func) then
        promise = promiselib:new(promise_or_func)
    else
        promise = promise_or_func
    end
    
    if not promiselib.is(promise) then
        error("await expects a Promise or function that returns a Promise")
    end
    
    return coroutine.yield(promise)
end

function promiselib:delay(ms)
    return self:new(function(resolve)
        create_timer(ms, resolve)
    end)
end

function promiselib:retry(func, max_attempts, delay_ms)
    max_attempts = max_attempts or 3
    delay_ms = delay_ms or 1000
    
    return self:new(function(resolve, reject)
        local attempts = 0
        
        local function try()
            attempts = attempts + 1
            
            local promise = isfunction(func) and promiselib:new(func) or func
            
            promise:after(resolve):catch(function(err)
                if attempts >= max_attempts then
                    reject(err)
                else
                    promiselib:delay(delay_ms):after(try)
                end
            end)
        end
        
        try()
    end)
end

return {
    promiselib = promiselib,
    async = async,
    await = await,
    Promise = Promise
} 