---@class IconsInventory_MetaModData
---@field name string
---@field data table
---@field d 1 | 2
local MetaModData = {}
MetaModData._index = MetaModData

-- Custom encoding logic because `serialize` and `deserialize` are not reliably usable
-- Indie Stone removed them without warning on 2026-08-26
local encode = {
    ["true"] = true,
    ["false"] = false,
}

---@param name string
---@param i 1 | 2
local function getFileName(name, i)
    return "IconsInventory/" .. name .. tostring(i) .. ".ini"
end

---@param name string
---@param i 1 | 2
---@return table?
local function readFile(name, i)
    local reader = getFileReader(getFileName(name, i), false)
    if reader then
        local data = {}
        local line
        repeat
            line = reader:readLine()
            if line then
                local k, v = string.match(line, "^([^=]+)=(.*)$")
                if k then
                    local primitive = string.match(v, "^([^:]*)$")
                    if primitive then
                        if k == "nil" or k == "" then
                            data[k] = nil
                        elseif encode[primitive] ~= nil then
                            data[k] = encode[primitive]
                        else
                            data[k] = tonumber(primitive)
                        end
                    else
                        data[k] = string.sub(v, 2)
                    end
                end
            end
        until line == nil
        reader:close()

        if type(data._v) == "number" then
            return data
        end
    end
end

---@param name string
function MetaModData.load(name)
    local self = setmetatable({}, MetaModData) ---@cast self IconsInventory_MetaModData
    self.name = name

    local data1 = readFile(name, 1)
    local data2 = readFile(name, 2)

    self.d = (
        data1 and (not data2 or (
            data1._v and (not data2._v or data2._v < data1._v)
        ))
    ) and 1 or 2

    self.data = self.d == 1 and data1 or data2 or {}

    return self
end

function MetaModData:save()
    -- Alternate write on 2 files to avoid data loss (getFileWriter() clears the file)
    local dNext = self.d == 1 and 2 or 1
    local vNext = (self.data._v or 0) + 1

    local lines = {}
    for k, v in pairs(self.data) do
        if k ~= "_v" then
            local encoded = type(v) == "string" and ":" .. v or tostring(v)
            table.insert(lines, k .. "=" .. encoded)
        end
    end
    -- In the end as guarantee of file validity
    table.insert(lines, "_v=" .. tostring(vNext))

    local writer = getFileWriter(getFileName(self.name, dNext), true, false) ---@cast writer -nil
    for _, v in ipairs(lines) do
        writer:writeln(v)
    end
    writer:close()

    self.d = dNext
    self.data._v = vNext
end

return MetaModData
