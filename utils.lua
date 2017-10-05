function clip(value, min, max)
   if (min > max) then return value
   elseif (value < min) then return min
   elseif (value > max) then return max
   else return value end
end

function gaussian(mean, stdev)
   -- TODO get rid of returning a function, just return the result already
   local y2
   local use_last = false
   return function()
      local y1
      if (use_last) then
         y1 = y2
         use_last = false
      else
         local x1=0
         local x2=0
         local w=0
         x1 = 2.0 * love.math.random() - 1.0
         x2 = 2.0 * love.math.random() - 1.0
         w  = x1 * x1 + x2 * x2
         while( w >= 1.0) do
             x1 = 2.0 * love.math.random() - 1.0
             x2 = 2.0 * love.math.random() - 1.0
             w  = x1 * x1 + x2 * x2
         end
          w = math.sqrt((-2.0 * math.log(w))/w)
          y1 = x1 * w
          y2 = x2 * w
          use_last = true
      end
      local retval = mean + stdev * y1
      if (retval > 0) then return retval end
      return -retval
   end
end

function generatePolygon(ctrX, ctrY, aveRadius, irregularity, spikeyness, numVerts)
   irregularity = clip( irregularity, 0,1 ) * 2 * math.pi / numVerts
   spikeyness = clip( spikeyness, 0,1 ) * aveRadius

   angleSteps = {}
   lower = (2 * math.pi / numVerts) - irregularity
   upper = (2 * math.pi / numVerts) + irregularity
   sum = 0

   for i=0,numVerts-1 do
      local tmp =lower +  love.math.random()*(upper-lower)
      angleSteps[i] = tmp;
      sum = sum + tmp;
   end

   k = sum / (2 * math.pi)
   for i=0,numVerts-1 do
      angleSteps[i] = angleSteps[i] / k
   end

   points = {}
   angle = love.math.random()*(2.0*math.pi)
   for i=0,numVerts-1 do
      r_i = clip(gaussian(aveRadius, spikeyness)(), 0, 2*aveRadius)
      x = ctrX + r_i * math.cos(angle)
      y = ctrY + r_i * math.sin(angle)
      points[1 + i * 2 + 0] = math.floor(x)
      points[1 + i * 2 + 1] = math.floor(y)
      angle = angle + angleSteps[i]
   end
   return points
end

function HSL(h, s, l, a)
	if s<=0 then return l,l,l,a end
	h, s, l = h/256*6, s/255, l/255
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end return (r+m)*255,(g+m)*255,(b+m)*255,a
end

function transformPolygon(tx, ty, polygon)
	local result = {}
	local n = table.getn(polygon)
	for i=1,n,2 do
		result[i + 0] = polygon[i + 0] + tx
		result[i + 1] = polygon[i + 1] + ty
	end
	return result
end

function tablefind_id(tab, id)
    for index, value in pairs(tab) do
       if tostring(value.id) == id then
            return index
        end
    end
    return -1
end

function distance(x, y, x1, y1)
   local dx = x - x1
   local dy = y - y1
   local dist = math.sqrt(dx * dx + dy * dy)
   return dist
end
function center(x, x1)
   local dx = x - x1
   return x1 + dx/2
end
function pointInRect(x,y, rx, ry, rw, rh)
   if x < rx or y < ry then return false end
   if x > rx+rw or y > ry+rh then return false end
   return true
end
function pointInCircle(x,y, cx, cy, radius)
   if distance(x,y,cx,cy) < radius then
      return true
   else
      return false
   end
end

return {
   HSL=HSL,
   generatePolygon=generatePolygon,
   transformPolygon=transformPolygon,
   tablefind_id = tablefind_id,
   distance=distance,
   center=center,
   pointInRect=pointInRect,
   pointInCircle=pointInCircle
}
