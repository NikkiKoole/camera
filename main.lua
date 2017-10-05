Camera = require "camera"
Gamestate = require "gamestate"
utils = require "utils"
flux = require "flux"

cos = math.cos
sin = math.sin

pan_zoom_mode = {}

-- TODO tweens might get in places where they would be clamped if they got there by touch
-- TODO use screen aspect ratio for centering too
-- TODO extract screen padding for camera


function pan_zoom_mode:init()
   self.touches = {}
end

function pan_zoom_mode:touchpressed( id, x, y, dx, dy, pressure )
   table.insert(self.touches,
                {id=id, x=x, y=y, dx=dx, dy=dy, pressure=pressure})

   if #self.touches == 1 then
      local wx, wy = camera:worldCoords(x,y)

      for i, o in ipairs(objs) do
         local cdx = camera.x - camera.x * o.layer_speed
         local cdy = camera.y - camera.y * o.layer_speed
         objs[i].hit = utils.pointInRect(wx, wy,
                                         o.x+cdx,
                                         o.y+cdy,
                                         o.w, o.h)
      end
      -- stop active tweens on camera
      for key,value in ipairs(camera.tweens) do
         value:stop()
      end

   elseif #self.touches == 2 then
      self.initial_distance = utils.distance(self.touches[1].x,
                                             self.touches[1].y,
                                             self.touches[2].x,
                                             self.touches[2].y)
      self.initial_angle =  math.atan2(self.touches[1].x - self.touches[2].x,
                                       self.touches[1].y - self.touches[2].y)
      self.initial_center =  {x=utils.center(self.touches[1].x,
                                             self.touches[2].x),
                              y=utils.center(self.touches[1].y,
                                             self.touches[2].y)}
   else
   end
end

function pan_zoom_mode:touchreleased( id, x, y, dx, dy, pressure )
   camera.tweens[1] = flux.to(camera, .5, {x=camera.x - self.lastdelta.x*5,
                                           y=camera.y - self.lastdelta.y*5}):ease('sineout'):onupdate(function() updatePolygons(camera) end)
   local index = utils.tablefind_id(self.touches, tostring(id))
   table.remove(self.touches, index)
end

function pan_zoom_mode:touchmoved( id, x, y, dx, dy, pressure )
   local index = utils.tablefind_id(self.touches, tostring(id))
   if (index > 0) then
      self.touches[index].x = x
      self.touches[index].y = y
      self.touches[index].dx = dx
      self.touches[index].dy = dy
      self.touches[index].pressure = pressure
   end
   if #self.touches == 1 then
      local c,s = cos(-camera.rot), sin(-camera.rot)
      dx,dy = c*dx - s*dy, s*dx + c*dy
      self.lastdelta = {x=dx, y=dy}
      camera:move(-dx / camera.scale, -dy / camera.scale)
   elseif #self.touches == 2 then
      self.lastdelta = {x=0, y=0}

      local new_center = {x=utils.center(self.touches[1].x, self.touches[2].x),
                          y=utils.center(self.touches[1].y, self.touches[2].y)}
      -- rotation
      --local angleRadians = math.atan2(self.touches[1].x - self.touches[2].x, self.touches[1].y - self.touches[2].y);
      --camera:rotate(self.initial_angle - angleRadians)
      --self.initial_angle = angleRadians

      --scale
      local d = utils.distance(self.touches[1].x, self.touches[1].y,
                               self.touches[2].x, self.touches[2].y)
      local scale_diff = (d - self.initial_distance) / self.initial_distance
      --local mul = d / self.initial_distance
      zoom(scale_diff, new_center)
      self.initial_distance = d

      -- translate
      local dx2 = self.initial_center.x - new_center.x
      local dy2 = self.initial_center.y - new_center.y
      self.initial_center = new_center

      local c,s = cos(-camera.rot), sin(-camera.rot)
      dx2, dy2 = c*dx2 - s*dy2, s*dx2 + c*dy2
      camera:move(dx2 / camera.scale, dy2 / camera.scale)
   else
   end
   updatePolygons(camera)
   clamp_camera()

end

function zoom(scaleDiff, center)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local new_x = center.x - w/2
    local new_y = center.y - h/2
    local offsetX = new_x/(camera.scale* (1 + scaleDiff)) - new_x/camera.scale
    local offsetY = new_y/(camera.scale * (1 + scaleDiff)) - new_y/camera.scale

    camera:move(-offsetX, -offsetY )
    camera:zoom(1 + scaleDiff)
    clamp_camera()
end


function clamp(v, min, max)
   if v < min then return min end
   if v > max then return max end
   return v
end

function clamp_camera()
   local w,h = love.graphics.getWidth(), love.graphics.getHeight()
   local offsetX,offsetY = (w/camera.scale)/2, (h/camera.scale)/2
   local clamp_style = "fancy"
   local x,y,zoom
   local minzoomX = w/(bounds.br.x - bounds.tl.x)
   local minzoomY = h/(bounds.br.y - bounds.tl.y)
   local minzoom = math.max(minzoomX, minzoomY)

   if (clamp_style == "fancy") then
      zoom = clamp(camera.scale, minzoom, math.huge)
      camera.scale = zoom
      offsetX,offsetY = (w/camera.scale)/2, (h/camera.scale)/2
      x = clamp(camera.x, bounds.tl.x + offsetX, bounds.br.x - offsetX)
      y = clamp(camera.y, bounds.tl.y + offsetY, bounds.br.y - offsetY)
   else
      -- less fancy clamping
      x = clamp(camera.x, bounds.tl.x, bounds.br.x)
      y = clamp(camera.y, bounds.tl.y, bounds.br.y)
   end

   camera.x = x
   camera.y = y
end



function build_world()

	local cb_back = {
		h_min=110,
		h_max=140,
		s_min=20,
		s_max=120,
		l_min=60,
		l_max=200
	}
	local cb_middle = {
		h_min=10,
		h_max=40,
		s_min=80,
		s_max=120,
		l_min=60,
		l_max=80
	}
	local cb_fore = {
		h_min=80,
		h_max=140,
		s_min=80,
		s_max=120,
		l_min=80,
		l_max=150
	}


	local layers = {
       back   = {
          speed=1.0,
          items=create_many_polygons(1000, cb_back)
       },
       middle = {
          speed=1.2,
          items=create_many_polygons(1000, cb_middle)
       },
       fore   = {
          speed=1.4,
          items=create_many_polygons(120,  cb_fore)
       }
	}
    -- a bit hacky, but i make the world bigger after init, to accomondate extra padding for pan/zoom
    -- and so i am sure its only done here once
    local f = 500

     bounds = {
       tl={x = bounds.tl.x - f,  y = bounds.tl.y - f},
        br={x = bounds.br.x + f, y = bounds.br.y + f}
	 }
    return layers
end


function create_many_polygons(amount, color_bounds)
   local objects = {}
   local rnd = love.math.random
	for _=0,amount do
		local r,g,b = HSL(rnd(color_bounds.h_min, color_bounds.h_max),
                          rnd(color_bounds.s_min, color_bounds.s_max),
                          rnd(color_bounds.l_min, color_bounds.l_max))

		local polygon = generatePolygon(
           rnd(bounds.tl.x, bounds.br.x),
           rnd(bounds.tl.y, bounds.br.y),
           100,
           0.5, 0.5,
           math.floor(rnd(3, 10)))
		table.insert(objects, {vertices=polygon, r=r, g=g, b=b })
	end
	return objects
end






function love.load()
   if arg[#arg] == "-debug" then require("mobdebug").start() end
   love.window.setMode(800, 800, {resizable=true, vsync=true, fullscreen=false})
   objs = {}
   camera = Camera(0, 0)
   camera.tweens = {}
   bounds = {
       tl={x = -1000,  y = -1000},
       br={x = 1000, y = 1000}
	}

   layers = build_world()
   updatePolygons(camera)
   objs[1] = {kind="rectangle",hit=false, layer_speed=1.0,
              x=-500, y=-100, w=200, h=200, r=200, g=100, b=100}
   objs[2] = {kind="rectangle",hit=false, layer_speed=1.0,
              x=-0, y=-100, w=200, h=200, r=100, g=200, b=0}
   objs[3] = {kind="rectangle",hit=false, layer_speed=1.0,
              x=500, y=-100, w=200, h=200, r=0, g=200, b=100}

   Gamestate.registerEvents()
   Gamestate.switch(pan_zoom_mode)
end

function love.update(dt)
   flux.update(dt)
   if love.keyboard.isDown("escape") then love.event.quit() end
end



function love.keyreleased(key)
   local w = love.graphics.getWidth()
   local h = love.graphics.getHeight()

   if key == "." then zoom(0.1, {x=love.mouse.getX(),
                                 y=love.mouse.getY()})
   end
   if key == "," then zoom(-0.1, {x=love.mouse.getX(),
                                  y=love.mouse.getY()})
   end
   if key == '1' then
      local filled = 0.5
      local zoom = w/(objs[1].w / filled)

      camera.tweens[1] = flux.to(camera, 1.3, { scale=zoom}):ease("backout")


      camera.tweens[2] = flux.to(camera, 1, { x = objs[1].x + objs[1].w/2,
                           y = objs[1].y + objs[1].h/2,
                         }):onupdate(function() updatePolygons(camera) end)
   end
   if key == '2' then
      local filled = 0.7
      local zoom = w/(objs[2].w / filled)
      camera.tweens[1] = flux.to(camera, 1, { x = objs[2].x + objs[2].w/2,
                           y = objs[2].y + objs[2].h/2,
                           scale=zoom}):onupdate(function() updatePolygons(camera) end)
   end

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

function updatePolygons(camera)
   for key,value in ipairs(layers.back.items) do
      local cdx = camera.x - camera.x * layers.back.speed
      local cdy = camera.y - camera.y * layers.back.speed
      local verts =  transformPolygon(cdx, cdy,  value.vertices)
      layers.back.items[key].wp = verts
   end
   for key,value in ipairs(layers.middle.items) do
      local cdx = camera.x - camera.x * layers.middle.speed
      local cdy = camera.y - camera.y * layers.middle.speed
      local verts =  transformPolygon(cdx, cdy,  value.vertices)
      layers.middle.items[key].wp = verts
   end
   for key,value in ipairs(layers.fore.items) do
      local cdx = camera.x - camera.x * layers.fore.speed
      local cdy = camera.y - camera.y * layers.fore.speed
      local verts =  transformPolygon(cdx, cdy,  value.vertices)
      layers.fore.items[key].wp = verts
   end


end



function love.draw()
   camera:attach()

   for _,value in ipairs(layers.back.items) do
      love.graphics.setColor(value.r, value.g, value.b)
      love.graphics.polygon("fill", value.wp)
   end
   for _,value in ipairs(layers.middle.items) do
      love.graphics.setColor(value.r, value.g, value.b)
      love.graphics.polygon("fill", value.wp)
   end
   for _,value in ipairs(layers.fore.items) do
      love.graphics.setColor(value.r, value.g, value.b)
      love.graphics.polygon("fill", value.wp)
   end

   for i, o in ipairs(objs) do
       local cdx = camera.x - camera.x * o.layer_speed
       local cdy = camera.y - camera.y * o.layer_speed

       if o.hit then
          love.graphics.setColor(200,0,0)
       else
          love.graphics.setColor(o.r, o.g, o.b)
       end
       love.graphics.rectangle("fill",o.x+cdx ,o.y+cdy , o.w, o.h)
   end


    camera:detach()
end
