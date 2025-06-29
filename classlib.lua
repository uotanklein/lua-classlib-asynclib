-- ClassLib

local classlib = {}
classlib.classes = {}

local istable = function(val) return type(val) == "table" end
local isstring = function(val) return type(val) == "string" end
local isfunction = function(val) return type(val) == "function" end
local table_copy = function(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

local string_match = string.match
local string_format = string.format
local string_rep = string.rep
local math_random = math.random
local error = error
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local tostring = tostring
local type = type

function classlib.is(val)
    return istable(val) and string_match(tostring(val), "class%[(.-)%]")
end

function classlib.is_instance(val)
    return istable(val) and string_match(tostring(val), "instance%[(.-)%]")
end

function classlib.is_serialized_instance(val)
    return istable(val) and val.__is_instance and isstring(val.__class)
end

function classlib:get(name)
    return name and self.classes[name]
end

local class_meta = {}
class_meta.__index = class_meta

function class_meta:extends(name)
    return class(self, name)
end

function class_meta:get_parents()
    return self.__parents or {}
end

function class_meta:get___name()
    return self.__name
end

function class_meta:get___ctor()
    return self.ctor
end

function class_meta:super(instance, props)
    props = props or {}
    if not instance then return end
    local parents = self:get_parents()
    if parents then
        for _, parent in ipairs(parents) do
            local ctor = parent:get___ctor()
            if not ctor then return end
            ctor(instance, props, parent)
        end
    end
end

function class_meta:abstract(name)
    self[name] = function()
        error(string_format("Abstract method '%s' must be implemented in class '%s'", name, self.__name))
    end
end

function class_meta:__call(name, parents)
    if not name then error("The class needs to be given a name.") end
    parents = classlib.is(parents) and {parents} or parents
    
    local new_class = setmetatable({
        __name = name,
        __parents = parents,
        __is_class = true,
    }, {
        __index = function(tbl, key)
            if parents then
                for _, parent in ipairs(parents) do
                    local val = parent[key]
                    if val ~= nil then return val end
                end
            end
            return class_meta[key]
        end,
        __call = self.__call,
        __tostring = function() return "class[" .. name .. "]" end,
    })

    new_class.__index = new_class
    classlib.classes[name] = new_class
    return new_class
end

local instance_meta = {}

function instance_meta:get_class()
    return self.__class
end

function instance_meta:__get_id()
    return self.__id_generator(self)
end

function instance_meta:serialize()
    return classlib.Serializer():_serialize(self)
end

instance_meta.__instanceof_cache = instance_meta.__instanceof_cache or {}

function instance_meta:instanceof(other_class)
    local cache_key = tostring(self.__class) .. "|" .. tostring(other_class)
    if instance_meta.__instanceof_cache[cache_key] ~= nil then 
        return instance_meta.__instanceof_cache[cache_key] 
    end
    
    local visited = {}
    local queue = {self:get_class()}
    
    while #queue > 0 do
        local current = table.remove(queue, 1)
        if visited[current] then 
            goto continue 
        end
        visited[current] = true
        
        if current == other_class then
            instance_meta.__instanceof_cache[cache_key] = true
            return true
        end

        local parents = current:get_parents()
        if parents then
            for _, parent in ipairs(parents) do
                if not visited[parent] then 
                    table.insert(queue, parent) 
                end
            end
        end
        ::continue::
    end

    instance_meta.__instanceof_cache[cache_key] = false
    return false
end

local function random_hex(bits)
    return string_format("%0" .. (bits / 4) .. "x", math_random(0, 2 ^ bits - 1))
end

local id_system = {
    simple_counter = 0,
    uuid_counter = 0,
    uuid_mode = true
}

function id_system:generate_simple_id()
    self.simple_counter = self.simple_counter + 1
    return self.simple_counter
end

function id_system:generate_uuid()
    if not self.uuid_mode then
        self.uuid_mode = true
    end
    self.uuid_counter = self.uuid_counter + 1
    return string_format("obj_%d_%d_%d", 
        os.time(), math_random(1000, 9999), self.uuid_counter)
end

function id_system:needs_uuid()
    return self.uuid_mode
end

function classlib.generate_uuid()
    return id_system:generate_simple_id()
end

function classlib.generate_uuid_if_needed()
    if id_system:needs_uuid() then
        return id_system:generate_uuid()
    else
        return id_system:generate_simple_id()
    end
end

function classlib.enable_uuid_mode()
    id_system.uuid_mode = true
end

function classlib.disable_uuid_mode()
    id_system.uuid_mode = false
end

local class = setmetatable({}, class_meta)

function class:__call(props)
    props = props or {}
    local copy_instance_meta = table_copy(instance_meta)
    copy_instance_meta.__index = copy_instance_meta
    
    local instance = setmetatable({
        __class = self,
        __is_instance = true,
        __id_generator = function(instance)
            if not instance.__id then
                instance.__id = classlib.generate_uuid_if_needed()
            end
            return instance.__id
        end
    }, {
        __index = setmetatable(copy_instance_meta, self),
        __tostring = function() return "instance[" .. self:get___name() .. "]" end,
    })

    local ctor = self:get___ctor()
    if ctor then ctor(instance, props, self) end
    return instance
end

local Serializer = class("Serializer")

function Serializer:ctor()
    self.instances = {}
end

local not_valid_types = {
    ["function"] = true,
    ["thread"] = true,
    ["userdata"] = true
}

function Serializer:_serialize(tbl)
    classlib.enable_uuid_mode()
    
    local tbl_copy = {}
    
    if classlib.is_instance(tbl) then
        local id = tbl.__id_generator(tbl)
        self.instances[id] = true
        tbl_copy.__class = tbl:get_class():get___name()
    end

    for k, v in pairs(tbl) do
        local t = type(v)
        if not_valid_types[t] then
            goto continue
        elseif t == "table" then
            if k == "__class" or k == "__id_generator" then goto continue end
            if classlib.is_instance(v) then
                if self.instances[v.__id_generator(v)] then
                    tbl_copy[k] = v.__id_generator(v)
                else
                    tbl_copy[k] = self:_serialize(v)
                end
            else
                tbl_copy[k] = self:_serialize(v)
            end
        else
            tbl_copy[k] = v
        end
        ::continue::
    end
    
    return tbl_copy
end

function Serializer:deserialize(tbl)
    local copy_tbl = {}
    
    if classlib.is_serialized_instance(tbl) then
        local instance_class = classlib:get(tbl.__class)
        if instance_class then
            copy_tbl = instance_class(tbl)
            self.instances[tbl.__id] = copy_tbl
        end
    end

    for k, v in pairs(tbl) do
        if k == "__class" then goto continue end
        if classlib.is_uuid(v) and k ~= "__id" then
            copy_tbl[k] = self.instances[v]
        elseif classlib.is_serialized_instance(v) or istable(v) then
            copy_tbl[k] = self:deserialize(v)
        else
            copy_tbl[k] = v
        end
        ::continue::
    end
    
    return copy_tbl
end

classlib.Serializer = Serializer

function classlib.is_uuid(uuid)
    if type(uuid) ~= "string" and type(uuid) ~= "number" then return false end
    if type(uuid) == "number" then
        return uuid > 0
    else
        return string_match(uuid, "^obj_%d+_%d+_%d+$") ~= nil
    end
end

return {
    class = class,
    classlib = classlib,
    istable = istable,
    isstring = isstring,
    isfunction = isfunction,
    table_copy = table_copy
}