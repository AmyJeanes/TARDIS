-- GMod math library extensions for the headless harness.
-- Ported from GMod's lua/includes/extensions/math.lua (GMod-Lua !/!= -> Lua):
-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/extensions/math.lua

function math.Distance(x1, y1, x2, y2)
    local xd = x2 - x1
    local yd = y2 - y1
    return math.sqrt(xd * xd + yd * yd)
end

function math.Clamp(_in, low, high)
    return math.min(math.max(_in, low), high)
end

function math.Rand(low, high)
    return low + (high - low) * math.random()
end

function math.EaseInOut(frac, easeIn, easeOut)
    if frac == 0 or frac == 1 then return frac end
    if easeIn == nil then easeIn = 0 end
    if easeOut == nil then easeOut = 1 end

    local fSumEase = easeIn + easeOut
    if fSumEase == 0 then return frac end
    if fSumEase > 1 then
        easeIn = easeIn / fSumEase
        easeOut = easeOut / fSumEase
    end

    local fProgressCalc = 1 / (2 - easeIn - easeOut)
    if frac < easeIn then
        return ((fProgressCalc / easeIn) * frac * frac)
    elseif frac < 1 - easeOut then
        return (fProgressCalc * (2 * frac - easeIn))
    else
        frac = 1 - frac
        return (1 - (fProgressCalc / easeOut) * frac * frac)
    end
end

function math.Round(num, idp)
    local mult = 10 ^ (idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Rounds towards zero
function math.Truncate(num, idp)
    local mult = 10 ^ (idp or 0)
    return (num < 0 and math.ceil or math.floor)(num * mult) / mult
end

function math.Approach(cur, target, inc)
    if cur < target then
        return math.min(cur + math.abs(inc), target)
    end
    if cur > target then
        return math.max(cur - math.abs(inc), target)
    end
    return target
end

function math.NormalizeAngle(a)
    return (a + 180) % 360 - 180
end

function math.AngleDifference(a, b)
    local diff = math.NormalizeAngle(a - b)
    if diff < 180 then
        return diff
    end
    return diff - 360
end

function math.Remap(value, inMin, inMax, outMin, outMax)
    return outMin + (((value - inMin) / (inMax - inMin)) * (outMax - outMin))
end
