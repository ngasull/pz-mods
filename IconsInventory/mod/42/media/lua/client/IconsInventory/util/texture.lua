local texture = {}

local corners = { {}, {}, {}, {} }

---@param x integer
---@param n integer
---@return integer
local function modulo(x, n)
    local res = math.fmod(x, n) ---@cast res integer
    return res < 0 and res + n or res
end

---@param ui ISUIElement
---@param tex Texture
---@param centerX number
---@param centerY number
---@param quarters integer
---@param w number
---@param h number
---@param r number
---@param g number
---@param b number
---@param a number
local function rotateQuarters(ui, tex, centerX, centerY, quarters, w, h, r, g, b, a)
    local rx, ry = w / 2, h / 2
    corners[1][1], corners[1][2] = centerX - rx, centerY - ry
    corners[2][1], corners[2][2] = centerX + rx, centerY - ry
    corners[3][1], corners[3][2] = centerX + rx, centerY + ry
    corners[4][1], corners[4][2] = centerX - rx, centerY + ry

    local tl = corners[1 + modulo(0 + quarters, 4)]
    local tr = corners[1 + modulo(1 + quarters, 4)]
    local br = corners[1 + modulo(2 + quarters, 4)]
    local bl = corners[1 + modulo(3 + quarters, 4)]

    ui:drawTextureAllPoint(tex, tl[1], tl[2], tr[1], tr[2], br[1], br[2], bl[1], bl[2], r, g, b, a)
end

---@param ui ISUIElement
---@param tex Texture
---@param centerX number
---@param centerY number
---@param angle number
---@param w? number
---@param h? number
---@param r? number
---@param g? number
---@param b? number
---@param a? number
function texture.drawAngle(ui, tex, centerX, centerY, angle, w, h, r, g, b, a)
    centerX = ui:getAbsoluteX() + ui:getXScroll() + centerX
    centerY = ui:getAbsoluteY() + ui:getYScroll() + centerY
    w = w or tex:getWidth()
    h = h or tex:getHeight()
    r = r or 1
    g = g or 1
    b = b or 1
    a = a or 1

    if angle % 90 == 0 then
        -- Optimise quarter angle rotations as we do a lot of them to draw ring
        return rotateQuarters(ui, tex, centerX, centerY, math.floor(angle / 90), w, h, r, g, b, a)
    end

    -- DrawTextureAngle can't scale: same corner math at ring size, fed to the
    -- quad DrawTexture (raw screen space, absolute position and scroll added here)
    local radian = math.rad(180 + angle)
    local cos, sin = math.cos(radian), math.sin(radian)
    local rx, ry = w / 2, h / 2
    local wCos, wSin = cos * rx, sin * rx
    local hCos, hSin = cos * ry, sin * ry
    ui:drawTextureAllPoint(
        tex,
        centerX + wCos - hSin, centerY + hCos + wSin,
        centerX - wCos - hSin, centerY + hCos - wSin,
        centerX - wCos + hSin, centerY - hCos - wSin,
        centerX + wCos + hSin, centerY - hCos + wSin,
        r, g, b, a
    )
end

---@param tex Texture
---@param s number
function texture.fitInSquare(tex, s)
    local h, w = tex:getHeight(), tex:getWidth()
    local rs, f = math.modf(s / h)
    if rs == 0 then
        rs = 1 / math.floor(0.99 + 1 / f) -- Find the first integral fraction of the size
    elseif f >= .5 then
        rs = rs + .5
    end
    return w * rs, h * rs
end

return texture
