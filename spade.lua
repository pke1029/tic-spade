-- title:	shade
-- author:	pke1029
-- desc:	Realistic cel shader for a sphere.
-- script:	lua

PI = 3.1415
sin = math.sin
cos = math.cos
max = math.max
min = math.min
abs = math.abs
sqrt = math.sqrt
floor = math.floor

vec3d = {

	new = function(x, y, z)
		local v = {x, y, z}
		setmetatable(v, vec3d.mt)
		return v
	end,

	mt = {

		__add = function (u, v)
			return vec3d.new(u[1]+v[1], u[2]+v[2], u[3]+v[3])
		end,

		__sub = function(u, v)
			return vec3d.new(u[1]-v[1], u[2]-v[2], u[3]-v[3])
		end,

		__mul = function(k, v)
			if type(k) == "table" then
				return vec3d.new(k[1]*v[1], k[2]*v[2], k[3]*v[3])
			else
				return vec3d.new(k*v[1], k*v[2], k*v[3])
			end
		end,

		__div = function(v, k)
			if type(k) == "table" then
				return vec3d.new(v[1]/k[1], v[2]/k[2], v[3]/k[3])
			else
				return vec3d.new(v[1]/k, v[2]/k, v[3]/k)
			end
		end,

		__pow = function(v, k)
			return vec3d.new(v[1]^k, v[2]^k, v[3]^k)
		end,

		__eq = function(u, v)
			return u[1] == v[1] and u[2] == v[2] and u[3] == v[3]
		end,

		__tostring = function(v)
			return "(" .. v[1] .. "," .. v[2] .. "," .. v[3] .. ")"
		end,

		__concat = function(s, v)
			return s .. "(" .. v[1] .. "," .. v[2] .. "," .. v[3] .. ")"
		end,

		__index = {

			rotate = function(self, pivot, c, s, su)
				local v = self - pivot
				local k = vec3d.dot(su, v)
				local w = vec3d.cross(su, v)

				local nv = 2*k*su + (c*c-s*s)*v + 2*c*w + pivot
				self[1] = nv[1]
				self[2] = nv[2]
				self[3] = nv[3]
				return self
			end,

			normalise = function(self)
				local r = vec3d.norm(self)
				self[1] = self[1] / r
				self[2] = self[2] / r
				self[3] = self[3] / r
				return self
			end
		}
	},

	norm = function(v)
		return sqrt(v[1]*v[1] + v[2]*v[2] + v[3]*v[3])
	end,

	dot = function(u, v)
		return u[1]*v[1] + u[2]*v[2] + u[3]*v[3]
	end,

	cross = function(u, v)
		return vec3d.new(u[2]*v[3]-v[2]*u[3], v[1]*u[3]-u[1]*v[3], u[1]*v[2]-v[1]*u[2])
	end,

	avg = function(u)
		return (u[1] + u[2] + u[3]) / 3
	end
}

mathFun = {
	between = function(x, a, b)
		return x >= a and x < b
	end,

	clamp = function(x, a, b)
		if mathFun.between(x, a, b) then return x end
		if x < a then return a end
		if x >= b then return b end
	end,

	bool2int = function(a)
		return a and 1 or 0
	end
}

fog = {

	-- 8 bit address 0x6000
	-- 4 bit address 0xc000

	cls = function(color)
		color = color or 0
		local val = color + (color << 4)
		memset(0x6000, val, 8192)
	end,

	show = function(colorkey)
		for i = 0,127 do
			for j = 0,127 do
				pix(j+1, i+1, peek4(0xc000+i*128+j))
			end
		end
	end,

	prtSc = function()
		for i = 0,127 do
			for j = 0,127 do
				poke4(0xc000+j*128+i, pix(i+1,j+1))
			end
		end
	end,

	hLine = function(x, y, w, color)
		if mathFun.between(y, 0, 128) then
			for i = mathFun.clamp(x, 0, 128),mathFun.clamp(x+w-1, 0, 127) do
				poke4(0xc000+y*128+i, color)
			end
		end
	end,

	circ = function(x, y, r, color)
		local i = 0
		local j = r
		local d = 3 - 2 * r
		while j >= i do
			fog.hLine(x-i, y+j, 2*i+1, color)
			fog.hLine(x-i, y-j, 2*i+1, color)
			fog.hLine(x-j, y+i, 2*j+1, color)
			fog.hLine(x-j, y-i, 2*j+1, color)
			i = i + 1
			if d > 0 then
				j = j - 1
				d = d + 4 * (i - j) + 2
			else
				d = d + 4 * i + 2
			end
		end
	end,
}

sphere = {

	elemt = {},
	currRadius = 0,

	create = function()
		if currRadius == radius or gui.current == 1 then return end
		print("Generating normal map" ,1, 1)
		sphere.elemt = {}
		sphere.currRadius = radius
		fog.cls(0)
		fog.circ(x0, y0, radius, 15)
		for i = 0,127 do
			for j = 0,127 do
				if peek4(0xc000+i*128+j) == 15 then
					table.insert(sphere.elemt, {i, j, n = sphere.getNormal(i, j)})
				end
			end
		end
	end,

	getNormal = function(i, j)
		local x = i - x0
		local y = y0 - j
		local z = sqrt((radius+1)^2 - x^2 -y^2)
		return vec3d.new(x, y, z):normalise()
	end,

	getFlux = function(p)
		return vec3d.dot(p.n, light.v)
	end,

	draw = function()
		if gui.current == 1 then
			circ(x0+1, y0+1, radius, 15)
			gui.viewPortColor = 1
			return
		end
		sphere.blendColor()
		-- draw
		for i,p in pairs(sphere.elemt) do
			local flux = sphere.getFlux(p)
			for j = 0,shades do
				local w = 1 + cos(angleThresh*PI/180)
				if flux+1 < (2-w)*(j/shades)+w then
					pix(p[1]+1, p[2]+1, j+6)
					break
				end
			end
		end
	end,

	blendColor = function()
		-- set color
		setColor(0x3fc6, baseColor)
		setColor(0x3fc9, lightColor)
		setColor(0x3fcc, ambientColor)
		setColor(0x3fcf, 0.5 * ambientIntensity * ambientColor)
		-- blend color
		local obj = baseColor
		local amb = ambientIntensity * ambientColor	/ 255
		local one = vec3d.new(1, 1, 1)
		for i = 0,shades do
			local addr = 0x3fc0+(i+6)*3
			local lgt = (i/shades) * lightIntensity * lightColor / 255
			local k = amb * (one - lgt)
			-- setColor(addr, obj * lgt + amb * (255 * one - obj * lgt))
			-- setColor(addr, obj * (amb^2 + lgt^2) / (amb + lgt))
			setColor(addr, obj * (k * amb / (lgt + k) + lgt))
		end
	end
}

light = {
	
	v = vec3d.new(1, 1, 1):normalise(),
	pivot = vec3d.new(0, 0, 0),
	c = cos(0.01),
	s = sin(0.01),

	update = function()
		-- mouse controls
		if currMouseState[3] then
			if currMouseState[1] > 130 or currMouseState[2] > 130 then return end
			local dy = currMouseState[1] - prevMouseState[1]
			local dx = currMouseState[2] - prevMouseState[2]
			local sx = sin(dx / 70)
			local sy = sin(dy / 70)
			light.v:rotate(light.pivot, cos(dx / 70), sx, vec3d.new(sx, 0, 0))
			light.v:rotate(light.pivot, cos(dy / 70), sy, vec3d.new(0, sy, 0))
			return
		end 
		-- keyboard controls
		local u = vec3d.new(light.s, 0, 0)
		local v = vec3d.new(0, light.s, 0)
		local a = 0
		local b = 0
		if key(23) then a = a - 1 end
		if key(19) then a = a + 1 end
		light.v:rotate(light.pivot, abs(a)*(light.c-1)+1, a*light.s, a*u)
		if key(1) then b = b - 1 end
		if key(4) then b = b + 1 end
		light.v:rotate(light.pivot, abs(b)*(light.c-1)+1, b*light.s, b*v)
	end
}

gui = {

	current = 2,
	field1 = {},
	field2 = {},
	field3 = {},
	viewPortColor = 1,
	isHex = false,

	draw = function()
		cls(14)

		-- 3d view port
		rectb(0, 0, 130, 130, 14)
		rect(1, 1, 128, 128, gui.viewPortColor)
		rect(1, 129, 6, 6, 0)
		rect(7, 129, 6, 6, 1)
		rect(13, 129, 6, 6, 14)
		rect(19, 129, 6, 6, 15)
		rect(25, 129, 6, 6, 5)

		rect(109 - 20 * mathFun.bool2int(gui.isHex), 129, 20, 6, 5)
		print("hex", 90, 130)
		print("dec", 110, 130)
		

		gui.updateField()
		gui.drawWin(0, 0, 2, "SPHERE", gui.field1)
		gui.drawWin(0, 38, 3, "LIGHT", gui.field2)
		gui.drawWin(0, 90, 4, "AMBIENT", gui.field3)

		-- foot
		rect(130, 129, 109, 7, 15)
		spr(16, 130, 128, 1)
		print("SPADE", 137, 130, 0)
		print("@pke1029", 192, 130, 0)

		-- print(buttonState[1], 0, 130, 15)
		-- print(buttonState[2], 30, 130, 15)
	end,

	drawWin = function(x0, y0, col, header, field)
		local size = 7
		local x = x0 + 129
		local y = y0
		local w = 111
		local h = (#field + 1) * size + 1
		local isDark = mathFun.bool2int(vec3d.avg(getColor(0x3fc0+col*3)) < 127)

		rect(x, y, w, h + 2, col)	-- background
		rectb(x, y, w, h + 3, 14)	-- border
		rect(x, y, 54, 9, 14)	-- heading
		print(header, x + 2, y + 2)

		-- Dont stare at me! B...baka!!!!!!!!!!!!!!!!! >///<
		for i,v in pairs(field) do
			local width = print(v[1], 0, -6)
			print(v[1], x + 50 - width, y + (i)*size + 3, 16 - isDark)
			local s = string.format(v[3], v[2])
			width = print(s, 0, -6)
			if gui.current == v[4] then
				rect(x + 61, y + i*size + 2, 42, 7, 0)	-- selected box
				-- rectb(x + 61, y + i*size + 2, 42, 7, 14)	-- selected box
				rect(x + 54, y + i*size + 2, 7, 7, 14)	-- left arrow
				rect(x + 103, y + i*size + 2, 7, 7, 14) -- right arrow
				print("<           >", x + 57, y + i*size + 3, 15)
				print(s, x + 82 - width/2, y + i*size + 3, 15)
			else
				print("<           >", x + 57, y + i*size + 3, 16 - isDark)
				print(s, x + 82 - width/2, y + i*size + 3, 16 - isDark)
			end
		end
	end,

	load = function()
		gui.field1 = {
			{"radius", radius, "%i", 1},
			{"r", baseColor[1], "%i", 2},
			{"g", baseColor[2], "%i", 3},
			{"b", baseColor[3], "%i", 4}
		}
		gui.field2 = {
				{"intensity", lightIntensity, "%.3f", 5},
				{"r", lightColor[1], "%i", 6},
				{"g", lightColor[2], "%i", 7},
				{"b", lightColor[3], "%i", 8},
				{"shades", shades+1, "%i", 9},
				{"angle", angleThresh, "%i", 10}
			}
		gui.field3 = {
			{"intensity", ambientIntensity, "%.3f", 11},
			{"r", ambientColor[1], "%i", 12},
			{"g", ambientColor[2], "%i", 13},
			{"b", ambientColor[3], "%i", 14}
		}
	end,

	updateField = function()
		gui.field1[1][2] = radius
		gui.field1[2][2] = baseColor[1]
		gui.field1[3][2] = baseColor[2]
		gui.field1[4][2] = baseColor[3]
		gui.field2[1][2] = lightIntensity
		gui.field2[2][2] = lightColor[1]
		gui.field2[3][2] = lightColor[2]
		gui.field2[4][2] = lightColor[3]
		gui.field2[5][2] = shades + 1
		gui.field2[6][2] = angleThresh
		gui.field3[1][2] = ambientIntensity
		gui.field3[2][2] = ambientColor[1]
		gui.field3[3][2] = ambientColor[2]
		gui.field3[4][2] = ambientColor[3]

		local s = "%i"
		if gui.isHex then s = "%x" end
		gui.field1[2][3] = s
		gui.field1[3][3] = s
		gui.field1[4][3] = s
		gui.field2[2][3] = s
		gui.field2[3][3] = s
		gui.field2[4][3] = s
		gui.field3[2][3] = s
		gui.field3[3][3] = s
		gui.field3[4][3] = s
	end,

	update = function()
		if btnp(0) then gui.current = mathFun.clamp(gui.current - 1, 1, #var) end
		if btnp(1) then gui.current = mathFun.clamp(gui.current + 1, 1, #var) end
		local v = var[gui.current]
		if buttonState[1] then
			var[gui.current][1] = mathFun.clamp(v[1] - v[2], v[3], v[4])
		end
		if buttonState[2] then
			var[gui.current][1] = mathFun.clamp(v[1] + v[2], v[3], v[4])
		end
		if currMouseState[4] then
			if mathFun.between(currMouseState[2], 129, 136) then 
				local x = currMouseState[1]
				if mathFun.between(x, 1, 7) then gui.viewPortColor = 0
				elseif mathFun.between(x, 7, 13) then gui.viewPortColor = 1
				elseif mathFun.between(x, 13, 19) then gui.viewPortColor = 14
				elseif mathFun.between(x, 19, 25) then gui.viewPortColor = 15
				elseif mathFun.between(x, 25, 31) then gui.viewPortColor = 5
				elseif mathFun.between(x, 109, 129) then gui.isHex = false 
				elseif mathFun.between(x, 89, 109) then gui.isHex = true 
				end
			end
		end
		if mathFun.between(currMouseState[1], 183, 239) then
			local y = currMouseState[2]
			local btnYPos = {9, 16, 23, 30, 47, 54, 61, 68, 75, 82, 99, 106, 113, 120}
			for i,v in pairs(btnYPos) do
				if mathFun.between(y, v, v+7) then
					gui.current = i
					if buttonState[3] then
						local v = var[gui.current]
						if currMouseState[1] < 190 then 
							var[gui.current][1] = mathFun.clamp(v[1] - v[2], v[3], v[4])
						elseif currMouseState[1] > 231 then
							var[gui.current][1] = mathFun.clamp(v[1] + v[2], v[3], v[4])
						end
					end 
					return
				end
			end
		end
	end
}

function setColor(addr, color)
	poke(addr, color[1])
	poke(addr+1, color[2])
	poke(addr+2, color[3])
end

function getColor(addr)
	local r = peek(addr)
	local g = peek(addr+1)
	local b = peek(addr+2)
	return vec3d.new(r, g, b)
end

prevMouseState = {0, 0, false, false}
currMouseState = {0, 0, false, false}
function updateMouseState()
	local x, y, c = mouse()
	local d = not (prevMouseState[3] or (not c or false))
	prevMouseState = currMouseState
	currMouseState = {x, y, c, d}
end

t = 0
buttonState = {false, false, false}
function updateButtonState()
	if btn(2) or btn(3) or currMouseState[3] then
		if t == 0 or (t % 2 == 0 and t > 30) then 
			if btn(2) then buttonState[1] = true end
			if btn(3) then buttonState[2] = true end
			if currMouseState[3] then buttonState[3] = true end
		else
			buttonState = {false, false, false}
		end
		t = t + 1
	else
		t = 0
		buttonState = {false, false, false}
	end
end

var = {}
function loadVar()
	var = {
		{radius, 1, 1, 63},
		{baseColor[1], 1, 0, 255},
		{baseColor[2], 1, 0, 255},
		{baseColor[3], 1, 0, 255},
		{lightIntensity, 0.004, 0.0, 1.0},
		{lightColor[1], 1, 0, 255},
		{lightColor[2], 1, 0, 255},
		{lightColor[3], 1, 0, 255},
		{shades, 1, 1, 7},
		{angleThresh, 1, 0, 180},
		{ambientIntensity, 0.004, 0.0, 1.0},
		{ambientColor[1], 1, 0, 255},
		{ambientColor[2], 1, 0, 255},
		{ambientColor[3], 1, 0, 255}
	}
end

function syncVar()
	radius 			= var[1][1]
	baseColor[1] 	= var[2][1]
	baseColor[2] 	= var[3][1]
	baseColor[3] 	= var[4][1]
	lightIntensity 	= var[5][1]
	lightColor[1] 	= var[6][1]
	lightColor[2] 	= var[7][1]
	lightColor[3] 	= var[8][1]
	shades 			= var[9][1]
	angleThresh 	= var[10][1]
	ambientIntensity = var[11][1]
	ambientColor[1] = var[12][1]
	ambientColor[2] = var[13][1]
	ambientColor[3] = var[14][1]
end


-- parameters -------------------------------------------------------

x0 = 64
y0 = 64
radius = 31
baseColor = vec3d.new(0xb6, 0xff, 0xea)
lightIntensity = 1.0
lightColor = vec3d.new(255, 255, 255)
shades = 4
angleThresh = 90
ambientIntensity = 1.0
ambientColor = vec3d.new(0, 0, 50)

---------------------------------------------------------------------

-- system color
setColor(0x3fc0, {0x14, 0x0c, 0x1c})
setColor(0x3fc3, {0x44, 0x24, 0x34})
setColor(0x3fea, {0x75, 0x71, 0x61})
setColor(0x3fed, {0xde, 0xee, 0xd6})

loadVar()
gui:load()
sphere:create()

function TIC()

	updateMouseState()
	updateButtonState()

	gui:update()
	syncVar()
	sphere:create()
	light:update()

	gui:draw()
	sphere:draw()
	
end
