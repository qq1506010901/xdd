

function getUserdataType(z)
	return z
end

auto = function(z)
	local t = type(z)
	if t == 'userdata' then
		t = getUserdataType(z)
		if t == 'player' then
			return playerTrack[z.name]:Track(z)
		elseif t == 'entity' then
			return EntityTrack(z)
		elseif t == 'monster' then
			return MonsterTrack(z)
		elseif t == 'weapon' then
			return WeaponTrack(z)
		elseif t == 'block' then
			return BlockTrack(z)
		elseif t == 'sync' then
			return SyncTrack(z)
		else
			return z
		end
	elseif t == 'table' then
		for k,v in pairs(z)do
			if type(v)=='userdata'then
				z[k]=auto(v)
			end
		end
		return z
	else
		return z
	end
end


--跟踪表元表
Track = {
	args = {},
}
function Track:New(...)
	local o = {}
	setmetatable(o,self)
	self.__index = self
	if ... then
		o.args = table.pack(...)
	end
	return o
end
function Track:OnValueChange(t, k, v)

end

function Track:WriteBase(t, k, v)
	t[k] = v
end
function Track:ReadBase(t, k)
	return t[k]
end
function Track:WriteRule(t, k, v)
	self:WriteBase(t, k, v)
end
function Track:ReadRule(t, k)
	return self:ReadBase(t,k)
end

function Track:Track(t,bool)
	local proxy
	if self.func then
		proxy = self.func--'t'的代理表
	else
		proxy={}
	end
	--userdata的元表
	local mt = {}
	mt = {
		__call=function(self,...)
			print(self)
		end,
		__index = function(_, k)
			if k=="origin" then
				return t
			end
			return self:ReadRule(t, k)
		end,
		__newindex = function(_, k, v)
			self:OnValueChange(t, k, v)
			self:WriteRule(t, k, v)
		end,
	}
	--table的元表
	local mt2 = {}
	mt2 = {
		__index = function(_, k)
			if k=="origin" then
				return t
			end
			return self:ReadRule(t, k)
		end,
		__newindex = function(_, k, v)
			self:OnValueChange(t, k, v)
			self:WriteRule(t, k, v)
		end,
		__pairs = function()
			return function(_, k)
				local nextkey, nextvalue = next(t, k)
				if nextkey ~= nil then
					--避免最后一个值
					--print("*元素*" .. tostring(nextkey))
				end
				return nextkey, nextvalue
			end
		end,
		__len = function()
			return #t
		end,
	}

	if type(t)=="table" then
		setmetatable(proxy, mt2)
	elseif type(t)=="userdata" then
		setmetatable(proxy,mt)
	end


	return proxy
end

Framework = {
	GamePlug = {},
	UIPlug = {},
	GameRule={
		--使用脚本来控制玩家血量变化（开启后能够突破玩家血量上限，但同时不能使用装置修改血量
		UseScriptControlPlayerHealth=false
	}
}


REGISTER = {
	count = 0,
}
function REGISTER:ReturnRule(...)
	local arg = table.pack(...)
	local result
	for i = 1, #self.Registry do
		if self.Registry[i] then
			result = self.Registry[i].fun(arg[1], arg[2], arg[3], arg[4], arg[5], arg[6])
			if self.Registry[i] then
				if self.Registry[i].modes.once==1 then
					self:UnRegister(self.Registry[i].fun)
				end
			end
		end
	end
	return result
end
function REGISTER:New(fun)
	local tab = {}
	setmetatable(tab, self)
	self.__index = self
	tab._Do = fun
	tab.Registry = {}
	return tab
end
function REGISTER:Do(...)
	return self._Do(...)
end
--mode：REGISTER_MODE
function REGISTER:Register(fun,num)
	if type(fun) == "function" then
		local isRepeat,funInfo=self:CheckRepeat(fun)

		if isRepeat and funInfo.modes.only==1 then
			print("该方法只能注册一次") return
		end

		if isRepeat and funInfo.modes.override==1 then
			funInfo.fun=fun print("方法已覆写") return
		end

		self.count = self.count + 1
		self.Registry[self.count]=self.Registry[self.count] or {}
		self.Registry[self.count].fun = fun
		self.Registry[self.count].modes = REGISTER.Mode:Create(num)
	else
		error('注册的对象当前仅支持function类型')
	end
end
function REGISTER:CheckRepeat(fun)
	for k,v in pairs(self.Registry) do
		if  v.fun==fun  then
			return true,v
		end
	end
	return false
end


--注册模式枚举
REGISTER_MODE=
{
	--执行一次就注销该方法
	once=1,
	--保证唯一的注册方法
	only=2,
	--覆写
	override=4,
}
REGISTER_MODE_NAME=
{
	"once",
	"only",
	"override",
}
REGISTER.Mode=
{
	once=0,
	only=0,
	override=0,
}
function REGISTER.Mode:Create(num)
	local modes={}
	setmetatable(modes,self)
	self.__index=self
	local count=1
	while	num and num>0 do
		local temp=num%2
		num=math.floor(num/2)
		modes[REGISTER_MODE_NAME[count]]=temp
		count=count+1
	end
	return modes
end

function REGISTER:UnRegister(fun)
	for i = 1, self.count do
		if self.Registry[i].fun == fun then
			self.Registry[i] = nil
			collectgarbage("collect")
			break
		end
	end
	--重新统计
	self.count = 0
	local temp = {}
	for i = 1, #self.Registry do
		if self.Registry[i] then
			self.count = self.count + 1
			temp[self.count] = self.Registry[i]
		end
	end
	self.Registry = temp
end

function REGISTER:Trigger(...)
	local arg = table.pack(...)
	for i = 1, arg.n do
		arg[i] = auto(arg[i])
	end
	--使用各自的返回规则
	return self:ReturnRule(arg[1], arg[2], arg[3], arg[4], arg[5], arg[6])
end

function splitString(z, b, a, i, f, g, j, b1, b2)
	b = b or ','
	a = {}
	i = 1
	f = string.find
	g = string.sub
	j = 1
	while 1 do
		b1, b2 = f(z, b, j, true)
		if b2 then
			a[i] = g(z, j, b1 - 1)
			j = b2 + 1
			i = i + 1
		else
			a[i] = g(z, j, #z)
			break
		end
	end
	return a
end
split = splitString
function limitNum(z, a, b)
	return z < a and a or (z > b and b or z)
end

hash = {
	clear = function(d)
		for k in pairs(d) do
			d[k] = nil
		end
	end
, size = function(z)
		local i = 0
		for k in pairs(z) do
			i = i + 1
		end
		return i
	end
}
function printHash(d, f)
	f = tostring
	for k, v in pairs(d) do
		print(f(k) .. ':' .. f(v))
	end
end

--FrameworkGame
if Game then
	isPlayer = Game.Player.__type.is
	isMonster = Game.Monster.__type.is
	isEntity = Game.Entity.__type.is
	isWeapon = Game.Weapon.__type.is
	isBlock = Game.EntityBlock.__type.is
	isSyncValue = Game.SyncValue.__type.is
	isWeaponOption = Common.WeaponOption.__type.is
	function getUserdataType(z)
		if isPlayer(z) then
			return 'player'
		end
		if isMonster(z) then
			return 'monster'
		end
		if isEntity(z) then
			return 'entity'
		end
		if isWeapon(z) then
			return 'weapon'
		end
		if isWeaponOption(z) then
			return 'weaponOption'
		end
		if isBlock(z) then
			return 'block'
		end
		if isSyncValue(z) then
			return 'sync'
		end
	end

	--全局默认设置
	Game.Rule.enemyfire = false
	Game.Rule.friendlyfire = false
	GameRuleEventList = split('OnUpdate OnRoundStart OnRoundStartFinished'
			.. ' OnPlayerConnect OnPlayerDisconnect OnPlayerJoiningSpawn OnPlayerSpawn OnPlayerAttack OnPlayerSignal'
			.. ' OnReceiveGameSave OnLoadGameSave OnGameSave OnClearGameSave OnPlayerKilled'
			.. ' OnTakeDamage OnKilled'
			.. ' CanBuyWeapon CanHaveWeaponInHand OnGetWeapon OnDeployWeapon OnSwitchWeapon PostFireWeapon OnReload OnReloadFinished', ' ')
	--注册
	d = split('OnKilled OnRoundStart OnRoundStartFinished OnPlayerSignal OnPlayerAttack OnTakeDamage OnPlayerKilled OnPlayerSpawn OnPlayerJoiningSpawn OnPlayerConnect OnPlayerDisconnect'
			.. ' OnGetWeapon OnGameSave OnReceiveGameSave OnLoadGameSave OnClearGameSave OnReload OnReloadFinished OnDeployWeapon OnSwitchWeapon PostFireWeapon CanBuyWeapon CanHaveWeaponInHand OnUpdate OnLaterUpdate'
			.. ' OnPlayerUpdate OnPlayerLaterUpdate', ' ')
	for k, v in pairs(d) do
		Framework.GamePlug[v] = REGISTER:New()
	end
	for k, v in pairs(GameRuleEventList) do
		load('function Game.Rule:' .. v .. '(...)Framework.GamePlug.' .. v .. ':Trigger(...)end')()
	end

	pus = {}
	MonstersAliveList = {}
	MonstersDeathList = {}
	playerTrack = {}
	function Game.Rule:OnPlayerConnect(p)
		pus[p.name] = {}
		playerTrack[p.name] = Track:New(p)
		--如果有冒号的用法就要定义这个表
		playerTrack[p.name].func={}
		for k, v in pairs(playerFunc) do
			--self==pTrack.func==proxy
			playerTrack[p.name].func[k] =playerFunc[k]
		end

		playerTrack[p.name].WriteBase = function(self, t, k, v)
			if playerAttrWrite[k] then
				playerAttrWrite[k](t, v)
			else
				t[k]=v
			end
		end
		--self是pTrack
		playerTrack[p.name].ReadBase = function(self, t, k)
			if playerAttrRead[k] then
				return playerAttrRead[k](t)
			end
			return t[k]
		end
		Framework.GamePlug.OnPlayerConnect:Trigger(p)
	end

	function Game.Rule:OnPlayerJoiningSpawn(p)
		local u=pus[p.name]
		u.health = p.health
		u.maxhealth = p.maxhealth
		u.armor =  p.armor
		u.maxarmor = p.maxarmor
		u.name=p.name
		Framework.GamePlug.OnPlayerJoiningSpawn:Trigger(p)
	end
	function Game.Rule:OnPlayerDisconnect(p)
		Framework.GamePlug.OnPlayerDisconnect:Trigger(p)
		pus[p.name] = nil
		playerTrack[p.name]=nil
		collectgarbage()
	end
	--重写返回规则
	function Framework.GamePlug.OnPlayerAttack:ReturnRule(p, k, d, wt, h,killerWeapon)
		local result
		local e = self.Registry
		for i = 1, #e do
			local a = e[i].fun(p, k, d, wt, h,killerWeapon)
			if type(a) == 'number' then
				result = (result or 0) + a
			end
		end
		return result
	end

	function Game.Rule:OnPlayerAttack(p, k, d, wt, h)
		local u = pus[p.name]
		
		local killerWeapon
		if k and k:IsPlayer() then
			local player=k:ToPlayer()
			player = pus[player.name]
			killerWeapon = player.postFireWeapon or player.deployWeapon
			player.postFireWeapon = nil
		end
		u.armor = p.armor
		u.maxarmor = p.maxarmor
		d = Framework.GamePlug.OnPlayerAttack:Trigger(p, k, d, wt, h,killerWeapon) or d
		--无敌
		if u.invincibility==true then
			d = 0
		end
		u.OnPlayerAttack_d = d
		u.OnPlayerAttack_health = u.health
		if Framework.GameRule.UseScriptControlPlayerHealth==false then
			return d
		end

		if d >= u.health then
			p.health = 1
			u.health = 0
			return 1
		else
			local a = u.health
			a = math.min(a - d, u.maxhealth)
			u.health = a
			a = math.min(a, 1000000)
			if d >= 1 then
				p.health = math.ceil(a + 1)
				return 1
			else
				p.health = math.ceil(a)
				return 0
			end
		end
	end
	function Game.Rule:OnPlayerSpawn(p)
		local u = pus[p.name]
		u.health = u.maxhealth
		p.health = p.maxhealth
		Framework.GamePlug.OnPlayerSpawn:Trigger(p)
	end
	--重写返回规则
	function Framework.GamePlug.OnTakeDamage:ReturnRule(v, k, d, wt, h,killerWeapon)
		local result
		local e = self.Registry
		for i = 1, #e do
			local a = e[i].fun(v, k, d, wt, h,killerWeapon)
			if type(a) == 'number' then
				result = (result or 0) + a
			end
		end
		return result
	end
	function Game.Rule:OnTakeDamage(v, k, d, wt, h)
		if v:IsMonster() then
			--使用自己的返回规则触发
			local killerWeapon
			if k:IsPlayer() then
				local player=k:ToPlayer()
				player = pus[player.name]
				killerWeapon = player.postFireWeapon or player.deployWeapon
				player.postFireWeapon = nil
			end
			d = Framework.GamePlug.OnTakeDamage:Trigger(v, k, d, wt, h ,killerWeapon) or d
			local m = v:ToMonster()
			local mu = MonstersAliveList[m.index]
			if not mu.createByScript then
				print("装置怪物受伤")
				return d
			end
			m:ShowOverheadDamage(d,k.index)
			if mu.invincibility then
				d = 0
			end
			if d >= mu.health then
				m.health = 1
				mu.health = 0
				return 1
			else
				mu.health = mu.health - d
				return 0
			end
		end
		if v:IsPlayer() then
			local p = v:ToPlayer()
			local u = pus[p.name]
			if not u then return end
			d = u.OnPlayerAttack_d
			u.health = u.OnPlayerAttack_health
			--使用自己的返回规则触发
			local killerWeapon
			if k:IsPlayer() then
				local player=k:ToPlayer()
				player = pus[player.name]
				killerWeapon = player.postFireWeapon or player.deployWeapon
				player.postFireWeapon = nil
			end
			d = Framework.GamePlug.OnTakeDamage:Trigger(v, k, d, wt, h, killerWeapon) or d
			if Framework.GameRule.UseScriptControlPlayerHealth==false then
				return d
			end
			p:ShowOverheadDamage(d,k.index)
			if d >= u.health then
				v.health = 1
				u.health = 0
				return 1
			else
				local a = u.health
				a = math.min(a - d, u.maxhealth)
				u.health = a
				a = math.min(a, 1000000)
				p.health = math.ceil(a)
				if d >= 1 then
					p.health = math.ceil(a + 1)
					return 1
				else
					return 0
				end
			end
		end
	end
	--2021/12/26怪物死亡的注册方法
	Framework.GamePlug.OnMonsterKilled=REGISTER:New()
	function Game.Rule:OnKilled(v, k)
		Framework.GamePlug.OnKilled:Trigger(v, k)
		if v:IsMonster() then
			local m = v:ToMonster()
			local mu = MonstersAliveList[m.index]
			if not mu then
				print("装置怪物死亡")
				return
			end
			MonstersDeathList[m.index] = mu
			MonstersDeathList[m.index].deadTime = Game.GetTime()
			Framework.GamePlug.OnMonsterKilled:Trigger(m,k)
			MonstersAliveList[m.index] = nil
			collectgarbage("collect")
		end
	end

	function Game.Rule:CanBuyWeapon(p, wid)
		local r = Framework.GamePlug.CanBuyWeapon:Trigger(p, wid)
		if type(r) == "boolean" then
			return r
		end
	end

	function Game.Rule:CanHaveWeaponInHand(p, wid, w)
		local r = Framework.GamePlug.CanHaveWeaponInHand:Trigger(p, wid, w)
		if type(r) == "boolean" then
			return r
		end
	end

	function Game.Rule:OnUpdate(t)
		Time.deltaTime = t - Time.t1
		frame = frame + 1
		if frame > 1 then
			Framework.GamePlug.OnLaterUpdate:Trigger(t)
		end
		Framework.GamePlug.OnUpdate:Trigger(t)
		for i, d in pairs(MonstersDeathList) do
			if t - d.deadTime > 4 then
				MonstersDeathList[i] = nil
				monsterTrack[i]=nil
				entityTrack[i]=nil
				d.deadTime=nil
			end
		end
		collectgarbage("collect")
		Time.t1 = t
	end

	Framework.GamePlug.OnDeployWeapon:Register (function(player, weapon)
		local player=player:ToPlayer()
		player.deployWeapon = weapon
	end)
	Framework.GamePlug.PostFireWeapon:Register (function(player, weapon, time)
		local player=player:ToPlayer()
		player.postFireWeapon = weapon
	end)

	--读属性
	playerAttrRead = {
		health = function(p)
			if Framework.GameRule.UseScriptControlPlayerHealth==false then
				return p.health
			else
				return pus[p.name].health
			end
		end,
		maxhealth = function(p)
			if Framework.GameRule.UseScriptControlPlayerHealth==false then
				return p.maxhealth
			else
				return pus[p.name].maxhealth
			end
		end,
		armor = function(p)
			return pus[p.name].armor
		end,
		maxarmor = function(p)
			return pus[p.name].maxarmor
		end,
		coin = function(p, z)
			return p.coin
		end,
		name = function(p)
			return p.name
		end,
		index = function(p)
			return p.index
		end,
		death = function(p)
			return p.death
		end,
		user = function(p)
			return p.user
		end,
		position = function(p)
			return Vector3:New(p.position)
		end,
		team = function(p)
			return p.team
		end,
		model = function(p)
			return p.model
		end,
		flinch = function(p)
			return p.flinch
		end,
		velocity = function(p)
			return Vector3:New(p.velocity)
		end,
		knockback = function(p)
			return p.knockback
		end,
		maxspeed = function(p)
			return p.maxspeed
		end,
		gravity = function(p)
			return p.gravity
		end,
		infiniteclip = function(p)
			return p.infiniteclip
		end,
		invincibility = function(p)
			local u = pus[p.name]
			u.invincibility =  u.invincibility or false
			return u.invincibility
		end,
		deployWeapon = function(p)
			local u = pus[p.name]
			return u.deployWeapon
		end,
		postFireWeapon = function(p)
			local u = pus[p.name]
			return u.postFireWeapon
		end
	}
	--写属性
	playerAttrWrite = {
		name = function()
			error('只读name')
		end,
		index = function()
			error('只读index')
		end,
		death = function()
			error('只读death')
		end,
		user = function(p, z)
			p.user = z
		end,
		health = function(p, z)
			if Framework.GameRule.UseScriptControlPlayerHealth==false then
				p.health = z
				return
			end
			local u = pus[p.name]
			if type(z) ~= 'number' then
				error('health 仅接受number类型')
			end
			u.health = z
			if z > u.maxhealth then
				u.maxhealth = z
			end
			z = math.floor(limitNum(z, 0, 1000000))
			p.health = z
			if z > p.maxhealth then
				p.maxhealth = z
			end
			if z <= 0 then
				p = auto(p)
				p:Kill()
			end
		end,
		maxhealth = function(p, z)
			if Framework.GameRule.UseScriptControlPlayerHealth==false then
				p.maxhealth = z
				return
			end
			local u = pus[p.name]
			if type(z) ~= 'number' then
				error('maxhealth 仅接受number类型')
			end
			u.maxhealth = z
			if z < u.health then
				u.health = z
			end
			z = math.floor(limitNum(z, 1, 1000000))
			p.maxhealth = z
			if z < p.health then
				p.health = z
			end
		end,
		armor = function(p, z)
			local u = pus[p.name]
			if not u or not u.maxarmor or not z then return end
			if type(z) ~= 'number' then
				error('armor 仅接受number类型')
			end
			u.armor = z
			if z > u.maxarmor then
				u.maxarmor = z
			end
			z = math.floor(limitNum(z, 0, 1000000))
			p.armor = z
			if z > p.maxarmor then
				p.maxarmor = z
			end
		end,
		maxarmor = function(p, z)
			local u = pus[p.name]
			if not u or not u.maxarmor or not z then return end
			if type(z) ~= 'number' then
				error('maxarmor 仅接受number类型')
			end
			u.maxarmor = z
			if z < u.armor then
				u.armor = z
			end
			z = math.floor(limitNum(z, 0, 1000000))
			p.maxarmor = z
			if z < p.armor then
				p.armor = z
			end
		end,
		coin = function(p, z)
			if type(z) ~= 'number' then
				error('coin 仅接受number类型')
			end
			p.coin = math.floor(limitNum(z, 0, 1000000000))
		end,
		position = function(p, d)
			if not isPosition(d) then
				error('position 仅接受有效的position')
			end
			p.position=d
		end,
		velocity = function(p, z)
			if type(z) == 'table' then
				p.velocity = z
			else
				error('velocity 仅接受有效的velocity')
			end
		end,
		team = function(p, z)
			if z ~= 1 and z ~= 2 then
				error('team 仅接受1或 2')
			end
			p.team = z
		end,
		model = function(p, z)
			if type(z) == 'number' and 0 <= z and z <= 48 and math.floor(z) == z then
				p.model = z
			else
				error('model 仅接受0~48的整数')
			end
		end,
		flinch = function(p, z)
			if type(z) ~= 'number' then
				error('flinch 仅接受number类型')
			end
			p.flinch = z
		end,
		knockback = function(p, z)
			if type(z) ~= 'number' then
				error('knockback 仅接受number类型')
			end
			p.knockback = z
		end,
		maxspeed = function(p, z)
			if type(z) ~= 'number' then
				error('maxspeed 仅接受number类型')
			end
			p.maxspeed = z
		end,
		gravity = function(p, z)
			if type(z) ~= 'number' then
				error('gravity 仅接受number类型')
			end
			p.gravity = z
		end,
		infiniteclip = function(p, z)
			if type(z) ~= 'boolean' then
				error('infiniteclip 仅接受boolean类型')
			end
			p.infiniteclip = z
		end,
		invincibility = function(p,v)
			if type(v) ~= 'boolean' then
				error('invincibility 仅接受boolean类型')
			end
			local u = pus[p.name]
			pus[p.name].invincibility = v
		end,
		deployWeapon = function(p,v)
			local u = pus[p.name]
			u.deployWeapon = v
		end,
		postFireWeapon = function(p,v)
			local u = pus[p.name]
			u.postFireWeapon = v
		end
	}
	--方法
	playerFunc = {
		Respawn = function(t, ...)
			t.origin:Respawn(...)
		end,
		Kill = function(t, ...)
			if t.invincibility then
				return
			end
			t.armor = 0

			t.origin:Kill(...)
		end,
		Win = function(t, ...)
			t.origin:Win(...)
		end,
		ShowBuymenu = function(t, ...)
			t.origin:ShowBuymenu(...)
		end,
		RemoveWeapon = function(t, ...)
			t.origin:RemoveWeapon(...)
		end,
		SetGameSave = function(t, ...)
			local args = table.pack(...)
			local k = args[1]
			local v = args[2]
			if type(k) ~= 'string' then
				error('存档键只能为string类型 当前为' .. type(k))
			end
			local a = type(v)
			if a == 'string' or a == 'boolean' or a == 'number' then
			else
				error('存档只能储存string/number/boolean类型 当前为' .. a)
			end
			t.origin:SetGameSave(k, v)
		end,
		GetGameSave = function(t, ...)
			local args = table.pack(...)
			local k = args[1]
			if type(k) ~= 'string' then
				error('存档键只能为string类型 当前为' .. type(k))
			end
			return t.origin:GetGameSave(k)
		end,
		SetFirstPersonView = function(t, ...)
			t.origin:SetFirstPersonView(...)
		end,
		SetThirdPersonView = function(t, ...)
			t.origin:SetThirdPersonView(...)
		end,
		SetThirdPersonFixedView = function(t, ...)
			t.origin:SetThirdPersonFixedView(...)
		end,
		SetThirdPersonFixedPlane = function(t, ...)
			t.origin:SetThirdPersonFixedPlane(...)
		end,
		ShowWeaponInven = function(t, ...)
			t.origin:ShowWeaponInven(...)
		end,
		ToggleWeaponInven = function(t, ...)
			t.origin:ToggleWeaponInven(...)
		end,
		SetRenderFX = function(t, ...)
			t.origin:SetRenderFX(...)
		end,
		SetRenderColor = function(t, ...)
			t.origin:SetRenderColor(...)
		end,
		Signal = function(t, ...)
			local args = table.pack(...)
			local a = args[1]
			if type(a) ~= 'number' then
				error('Signal只能为number类型 当前为' .. type(a))
			end
			if 0 <= a and a <= 255 then
			else
				error('Signal只能介于0~255 当前为' .. a)
			end
			t.origin:Signal(a)
		end,
		SetLevelUI = function(t, ...)
			local args = table.pack(...)
			local a = args[1]
			local b = args[2]
			if type(a) ~= 'number' then
				error('等级只能为number类型 当前为' .. type(a))
			end
			if 0 <= a and a <= 1000 then
			else
				error('等级只能介于0~1000 当前为' .. a)
			end
			if type(b) ~= 'number' then
				error('exp只能为number类型 当前为' .. type(b))
			end
			if 0 <= b and b <= 1 then
			else
				error('exp只能介于0~1 当前为' .. b)
			end
			t.origin:SetLevelUI(a, b)
		end,
		SetBuymenuLockedUI = function(t, ...)
			return t.origin:SetBuymenuLockedUI(...)
		end,
		SetWeaponInvenLockedUI = function(t, ...)
			local args = table.pack(...)
			local w = args[1]
			local uiLocked = args[2]
			local level = args[3]
			t.origin:SetWeaponInvenLockedUI(w.origin, uiLocked, level)
		end,
		GetPrimaryWeapon = function(t, ...)
			return t.origin:GetPrimaryWeapon(...)
		end,
		GetSecondaryWeapon = function(t, ...)
			return t.origin:GetSecondaryWeapon(...)
		end,
		GetWeaponInvenList = function(t, ...)
			return t.origin:GetWeaponInvenList(...)
		end,
		ClearWeaponInven = function(t, ...)
			return t.origin:ClearWeaponInven(...)
		end,
		ShowOverheadDamage = function(t, ...)
			local args = table.pack(...)
			local d = args[1]
			local i = args[2]
			if type(d) ~= 'number' then
				error('伤害应当为数值')
			end
			if -0x80000000 <= d and d <= 0x7fffffff then
			else
				error('伤害仅能接受int32可表达的范围 当前值为' .. d)
			end
			if type(i) ~= 'number' then
				error('ShowOverheadDamage中第二个参数playerindex应当为数值')
			end
			t.origin:ShowOverheadDamage(d, i)
		end,
		IsMonster = function(t, ...)
			return false
		end,
		IsPlayer = function(t, ...)
			return true
		end,
		ToMonster = function(t, ...)
			return
		end,
		ToPlayer = function(t, ...)
			return t
		end,
		GetSon = function(t, ...)
			return t
		end,
	}

	entityAttrRead = {
		index = function(p)
			return p.index
		end,
	}
	entityAttrWrite = {
		index = function()
			error('只读index')
		end,
	}
	monsterAttrRead = {
		user = function(p)
			return p.user
		end,
		health = function(p)
			return MonstersAliveList[p.index].health
		end,
		maxhealth = function(p)
			return MonstersAliveList[p.index].maxhealth
		end,
		armor = function(p)
			return MonstersAliveList[p.index].armor
		end,
		maxarmor = function(p)
			return MonstersAliveList[p.index].maxarmor
		end,
		index = function(p)
			return p.index
		end,
		type = function(p)
			return p.type
		end,
		coin = function(p)
			return p.coin
		end,
		damage = function(p)
			return p.damage
		end,
		speed = function(p)
			return p.speed
		end,
		viewDistance = function(p)
			return p.viewDistance
		end,
		checkAngle = function(p)
			return p.checkAngle
		end,
		applyKnockback = function(p)
			return p.applyKnockback
		end,
		canJump = function(p)
			return p.canJump
		end,
		position = function(p)
			return Vector3:New(p.position)
		end,
		velocity = function(p)
			return p.velocity
		end,
		name = function(p)
			if MonstersAliveList[p.index] then
				return MonstersAliveList[p.index].name
			end
		end,
		invincibility = function(m)
			return MonstersAliveList[m.index].invincibility or false
		end,
		createByScript = function(m)
			return MonstersAliveList[p.index].createByScript
		end,
	}
	monsterAttrWrite = {
		user = function(p, z)
			p.user = z
		end,
		index = function()
			error('只读 index')
		end,
		type = function()
			error('只读 type')
		end,
		health = function(p, z)
			local u = MonstersAliveList[p.index]
			if type(z) ~= 'number' then
				error('health 仅接受number类型')
			end
			u.health = z
			if z > u.maxhealth then
				u.maxhealth = z
			end
			if z <= 0 then
				p = auto(p)
				--怪物没有Kill方法
				--p:Kill()
			end
		end,
		maxhealth = function(p, z)
			local u = MonstersAliveList[p.index]
			if type(z) ~= 'number' then
				error('maxhealth 仅接受number类型')
			end
			if z <= 0 then
				error('maxhealth不能小于等于0')
			end
			u.maxhealth = z
			if z < u.health then
				u.health = z
			end
		end,
		armor = function(p, z)
			local u = MonstersAliveList[p.index]
			if type(z) ~= 'number' then
				error('armor 仅接受number类型')
			end
			u.armor = z
			if z > u.maxarmor then
				u.maxarmor = z
			end
		end,
		maxarmor = function(p, z)
			local u = MonstersAliveList[p.index]
			if type(z) ~= 'number' then
				error('maxarmor 仅接受number类型')
			end
			if z <= 0 then
				error('maxarmor 不能小于等于0')
			end
			u.maxarmor = z
			if z < u.armor then
				u.armor = z
			end
		end,
		coin = function(p, z)
			if type(z) ~= 'number' then
				error('coin 仅接受number类型')
			end
			p.coin = math.floor(limitNum(z, 0, 1000000000))
		end,
		damage = function(p, z)
			if type(z) ~= 'number' then
				error('damage 仅接受number类型')
			end
			MonstersAliveList[p.index].damage = z
			p.damage = math.floor(limitNum(z, 0, 0x7fffffff))
		end,
		speed = function(p, z)
			if type(z) ~= 'number' then
				error('speed 仅接受number类型')
			end
			p.speed = z
		end,
		viewDistance = function(p, z)
			if type(z) ~= 'number' then
				error('viewDistance 仅接受number类型')
			end
			p.viewDistance = z
		end,
		checkAngle = function(p, z)
			if type(z) ~= 'number' then
				error('checkAngle 仅接受number类型')
			end
			p.checkAngle = z
		end,
		applyKnockback = function(p, z)
			if type(z) ~= 'boolean' then
				error('applyKnockback 仅接受boolean类型')
			end
			p.applyKnockback = z
		end,
		canJump = function(p, z)
			if type(z) ~= 'boolean' then
				error('canJump 仅接受boolean类型')
			end
			p.canJump = z
		end,
		position = function(p, d)
			if not isPosition(d) then
				error('position 仅接受有效的position')
			end
			p.position = d
		end,
		velocity = function(p, z)
			if type(z) == 'table' then
				p.velocity = z
			else
				error('velocity 仅接受有效的velocity')
			end
		end,
		name = function(p,z)
			MonstersAliveList[p.index].name=z
		end,
		invincibility = function(m,v)
			MonstersAliveList[m.index].invincibility = v
		end,
		createByScript = function(m,v)
			MonstersAliveList[m.index].createByScript = v
		end,
	}
	weaponAttrRead = {
		user = function(p)
			return p.user
		end,
		weaponid = function(p)
			local a = p.weaponid
			if a == 0 then
				a = 1
				print('创造模式武器id异常bug')
			end
			return a
		end,
		color = function(p)
			return p.color
		end,
		damage = function(p)
			return p.damage
		end,
		speed = function(p)
			return p.speed
		end,
		flinch = function(p)
			return p.flinch
		end,
		knockback = function(p)
			return p.knockback
		end,
		criticalrate = function(p)
			return p.criticalrate
		end,
		criticaldamage = function(p)
			return p.criticaldamage
		end,
		bloodsucking = function(p)
			return p.bloodsucking
		end,
		infiniteclip = function(p)
			return p.infiniteclip
		end,
	}
	weaponAttrWrite = {
		user = function(p, z)
			p.user = z
		end,
		weaponid = function()
			--error('只读 weaponid')
		end,
		color = function(p, z)
			if type(z) ~= 'number' then
				error('color 仅接受0~6的整数')
			end
			if 0 <= z and z <= 6 then
			else
				error('color 仅接受0~6的整数')
			end
			p.color = z
		end,
		damage = function(p, z)
			p.damage = z
		end,
		flinch = function(p, z)
			p.flinch = z
		end,
		knockback = function(p, z)
			p.knockback = z
		end,
		speed = function(p, z)
			p.speed = z
		end,
		criticalrate = function(p, z)
			p.criticalrate = z
		end,
		criticaldamage = function(p, z)
			p.criticaldamage = z
		end,
		bloodsucking = function(p, z)
			p.bloodsucking = z
		end,
		infiniteclip = function(p, z)
			p.infiniteclip = z
		end,
	}
	blockAttrRead = {
		id = function(p)
			return p.id
		end,
		position = function(p)
			return p.position
		end,
		onoff = function(p)
			return p.onoff
		end,
	}
	blockAttrWrite = {
		id = function(p, z)
			error('只读 id')
		end,
		position = function(p, z)
			error('只读 position')
		end,
		onoff = function(p, z)
			p.onoff = z
		end,
	}
	syncAttrRead = {
		name = function(p)
			return p.name
		end,
		value = function(p)
			return p.value
		end,
	}
	syncAttrWrite = {
		name = function()
			error('只读 name')
		end,
		value = function(p, z)
			p.value = z
		end,
	}

	isVelocity = function(d)
		if type(d) ~= 'table' then
			return
		end
		local t
		t = type(d.x)
		if t ~= 'number' and t ~= 'nil' then
			return
		end
		t = type(d.y)
		if t ~= 'number' and t ~= 'nil' then
			return
		end
		t = type(d.z)
		if t ~= 'number' and t ~= 'nil' then
			return
		end
		return 1
	end
	isPosition = function(d)
		if type(d) ~= 'table' then
			return
		end
		if not checkType('int', d.x) then
			return
		end
		if not checkType('int', d.y) then
			return
		end
		if not checkType('int', d.z) then
			return
		end
		return 1
	end
	function isInt(z)
		return type(z) == 'number' and z == math.floor(z)
	end
	function isUint(z)
		return type(z) == 'number' and z >= 0 and z == math.floor(z)
	end
	checkType_func = {
		int = isInt,
		uint = isUint,
		position = isPosition,
		velocity = isVelocity,
	}
	checkType = function(t, z)
		return not (type(z) == t or getUserdataType(z) == t or not checkType_func[t](z))
	end
	checkTypes = function(t, z)
		for i = 1, #t do
			local b=t[i]
			local a=z[i]
			if type(b)=='table'then
				if not checkType(b[1],a) then
					return i
				end
				if b[2]<=a and a<=b[3]then else
					return i
				end
			else
				if not checkType(b, a) then
					return i
				end
			end
		end
	end


	function InZone(pos1, pos2, ppos)
		local x1, y1, z1, x2, y2, z2 = ChangePos(pos1.x, pos1.y, pos1.z, pos2.x, pos2.y, pos2.z)
		if ppos.x >= x1 and ppos.x <= x2 and ppos.y >= y1 and ppos.y <= y2 and ppos.z >= z1 and ppos.z <= z2 then
			return true
		end
		return false
	end
	function ChangePos(x1, y1, z1, x2, y2, z2)
		local a
		if x1 > x2 then
			a = x1
			x1 = x2
			x2 = a
		end
		if y1 > y2 then
			a = y1
			y1 = y2
			y2 = a
		end
		if z1 > z2 then
			a = z1
			z1 = z2
			z2 = a
		end
		return x1, y1, z1, x2, y2, z2
	end
end
Time = {
	deltaTime = 0.1,
}
if Game then
	Time.t1= Game.GetTime()
end
if UI then
	Time.t1= UI.GetTime()
end

frame = 0
--FrameworkUI
if UI then
	UI0 = UI
	UI = {}
	UI.ScreenSize = UI0.ScreenSize
	UI.Signal = UI0.Signal
	UI.StopPlayerControl = UI0.StopPlayerControl
	UI.PlayerIndex = UI0.PlayerIndex
	UI.GetTime = UI0.GetTime
	UI.Box = UI0.Box
	UI.Text = UI0.Text
	UI.KEY = UI0.KEY
	UI.Event = UI0.Event
	UI.SyncValue = UI0.SyncValue
	d = split('OnRoundStart OnSpawn OnKilled OnChat OnInput OnKeyDown OnKeyUp OnUpdate', ' ')
	for k, v in pairs(d) do
		Framework.UIPlug[v] = REGISTER:New()
		load('function UI.Event:' .. v .. '(...)Framework.UIPlug.' .. v .. ':Trigger(...)end')()
	end
	runErrorC = 0

	Framework.UIPlug.OnLaterUpdate=REGISTER:New()
	function UI.Event:OnUpdate(t)
		Time.deltaTime = t - Time.t1
		frame = frame + 1
		if frame > 1 then
			Framework.UIPlug.OnLaterUpdate:Trigger(t)
		end
		Time.t1 = t

		if runErrorC > 0 then
			return
		end
		runErrorC = runErrorC + 1
		Framework.UIPlug.OnUpdate:Trigger(t)
		runErrorC = runErrorC - 1
	end

	Framework.KEY =
	{
		NUM1 = 0,
		NUM2 = 1,
		NUM3 = 2,
		NUM4 = 3,
		NUM5 = 4,
		NUM6 = 5,
		NUM7 = 6,
		NUM8 = 7,
		NUM9 = 8,
		NUM0 = 9,
		A = 10,
		B = 11,
		C = 12,
		D = 13,
		E = 14,
		F = 15,
		G = 16,
		H = 17,
		I = 18,
		J = 19,
		K = 20,
		L = 21,
		M = 22,
		N = 23,
		O = 24,
		P = 25,
		Q = 26,
		R = 27,
		S = 28,
		T = 29,
		U = 30,
		V = 31,
		W = 32,
		X = 33,
		Y = 34,
		Z = 35,
		SHIFT = 36,
		SPACE = 37,
		ENTER = 38,
		UP = 39,
		DOWN = 40,
		LEFT = 41,
		RIGHT = 42,
		MOUSE1 = 43,
		MOUSE2 = 44
	}
	Framework.KeyDown={}
	Framework.KeyUp={}
	Framework.KeyInput={}
	Framework.KValue={}
	for k,v in pairs(Framework.KEY) do
		Framework.KeyDown[k]=REGISTER:New()
		Framework.KeyUp[k]=REGISTER:New()
		Framework.KeyInput[k]=REGISTER:New()
		Framework.KValue[v]=k
	end
	function UI.Event:OnKeyDown(inputs)
		Framework.UIPlug.OnKeyDown:Trigger(inputs)
		for k,v in pairs(inputs) do
			if inputs[k] then
				local KValue=Framework.KValue[k]
				Framework.KeyDown[KValue].isDown=true
				Framework.KeyDown[KValue]:Trigger(Framework.KeyDown)
			end
		end
	end
	function UI.Event:OnKeyUp(inputs)
		Framework.UIPlug.OnKeyUp:Trigger(inputs)
		for k,v in pairs(inputs) do
			if inputs[k] then
				local KValue=Framework.KValue[k]
				Framework.KeyDown[KValue].isDown=false
				Framework.KeyUp[KValue]:Trigger()
			end
		end
	end
	function UI.Event:OnInput(inputs)
		Framework.UIPlug.OnInput:Trigger(inputs)
		for k,v in pairs(inputs) do
			if inputs[k] then
				local KValue=Framework.KValue[k]
				Framework.KeyInput[KValue]:Trigger()
			end
		end
	end
end

if UI then
	Framework.UIPlug.OnSignal = REGISTER:New()
	function UI.Event:OnSignal(signal)
		Framework.UIPlug.OnSignal:Trigger(signal)
	end
end

--字符串转换方法
--字符串转换为Byte数组
function StringToByteArray(str)
	return { string.byte(str, 1, #str) }
end

--Byte数组转换为字符串数组
function ByteArrayToStringArray(byteArray)
	local results = {}
	local result
	local tempLength = 1
	for i = 1, #byteArray do
		if byteArray[tempLength] < 127 then
			result = string.char(byteArray[tempLength])
			results[#results + 1] = result
			tempLength = tempLength + 1
		else
			result = string.char(byteArray[tempLength], byteArray[tempLength + 1], byteArray[tempLength + 2])
			results[#results + 1] = result
			tempLength = tempLength + 3
			if tempLength > #byteArray then
				break
			end
		end
	end
	return results
end
--Byte数组转换为字符串
function ByteArrayToString(byteArray)
	local result = ""
	for i = 1, #byteArray do
		result = result .. string.char(byteArray[i])
	end
	return result
end



if Game then
	Game0 = Game
	Game = {}
	GameList = split('SyncValue RENDERFX Rule Entity EntityBlock Player Monster Weapon GetTime FindPlayerAt SetTrigger GetEntity RandomInt RandomFloat GetTriggerEntity GetScriptCaller KillAllMonsters TEAM MODEL WEAPONTYPE HITBOX ENTITYTYPE MONSTERTYPE WEAPONCOLOR THIRDPERSON_FIXED_PLANE', ' ')
	for k, v in pairs(GameList) do
		Game[v] = Game0[v]
	end
	Game.Player = {}
	function Game.GetTriggerEntity()
		return auto(Game0.GetTriggerEntity())
	end
	function Game.Player:Create(index)
		local player
		if not index then
			player=Game0.Player:Create(self)
		else
			player=Game0.Player:Create(index)
		end
		return auto(player)
	end
	Game.Monster = {}
	function Game.Monster:Create(arg1,arg2)
		local monster
		if type(arg1)=="table" then
			monster = auto(Game0.Monster:Create(self, arg1))
		else
			monster = auto(Game0.Monster:Create(arg1, arg2))
		end
		monster.createByScript = true
		return monster
	end
	Game.Weapon={}
	function Game.Weapon:CreateAndDrop(arg1,arg2)
		if type(arg2)=="table" then
			return auto(Game0.Weapon:CreateAndDrop(arg1,arg2))
		else
			return auto(Game0.Weapon:CreateAndDrop(self,arg1))
		end
	end
	Game.EntityBlock={}
	function  Game.EntityBlock:Create(position)
		if type(position)=="table" then
			return auto(Game0.EntityBlock:Create(position))
		else
			return auto(Game0.EntityBlock:Create(self))
		end
	end



	function  Game.GetEntity(index)
		local a=auto(Game0.GetEntity(index))
		if a then
			local b=a:ToMonster()
			if b then
				local d=MonstersAliveList[b.index] or MonstersDeathList[b.index]
				if not d.deadTime then
					return a
				end
			else
				return a
			end
		end
	end
end

if Game then

	entityFunc = {
		ShowOverheadDamage=function(t,d, i)
			if type(d) ~= 'number' then
				error('伤害应当为数值')
			end
			if -0x80000000 <= d and d <= 0x7fffffff then
			else
				error('伤害仅能接受int32可表达的范围 当前值为' .. d)
			end
			if type(i) ~= 'number' then
				error('playerindex应当为数值')
			end
			t.origin:ShowOverheadDamage(d, i)
		end,
		GetEntityType=function(t,...)
			return t.origin:GetEntityType(...)
		end,
		IsMonster=function(t,...)
			return t.origin:IsMonster(...)
		end,
		IsPlayer=function(t,...)
			return t.origin:IsPlayer(...)
		end,
		ToMonster=function(t,...)
			return auto(t.origin:ToMonster(...))
		end,
		ToPlayer=function(t,...)
			return auto(t.origin:ToPlayer(...))
		end,
		GetSon=function(t,...)
			return t
		end,
		SetRenderFX=function(t,...)
			return t.origin:SetRenderFX(...)
		end,
		SetRenderColor=function(t,...)
			return t.origin:SetRenderColor(...)
		end,
	}
	entityTrack = {}
	function EntityTrack(p)
		local i=p.index
		if not entityTrack[i] then
			entityTrack[i] = Track:New(p)
			entityTrack[i].func={}
		end
		for k, v in pairs(entityFunc) do
			entityTrack[i].func[k] = entityFunc[k]
		end
		entityTrack[i].WriteBase = function(self, t, k, v)
			if entityAttrWrite[k] then
				entityAttrWrite[k](t, v)
			else
				t[k]=v
			end
		end
		entityTrack[i].ReadBase = function(self, t, k)
			if entityAttrRead[k] then
				return entityAttrRead[k](t)
			end
			return t[k]
		end
		return entityTrack[i]:Track(p)
	end
	monsterFunc={
		IsMonster=function(t,...)
			return t.origin:IsMonster(...)
		end,
		IsPlayer=function(t,...)
			return t.origin:IsPlayer(...)
		end,
		ToMonster=function(t,...)
			return auto(t.origin:ToMonster(...))
		end,
		ToPlayer=function(t,...)
			return auto(t.origin:ToPlayer(...))
		end,
		SetRenderFX=function(t,...)
			t.origin:SetRenderFX(...)
		end,
		SetRenderColor=function(t,...)
			t.origin:SetRenderColor(...)
		end,
		ShowOverheadDamage=function(t,d, i)
			if type(d) ~= 'number' then
				error('伤害应当为数值')
			end
			if -0x80000000 <= d and d <= 0x7fffffff then
			else
				error('伤害仅能接受int32可表达的范围 当前值为' .. d)
			end
			if type(i) ~= 'number' then
				error('playerindex应当为数值')
			end
			t.origin:ShowOverheadDamage(d, i)
		end,
		AttackPlayer=function(t,a)
			if type(a) == 'number' then
				return t.origin:AttackPlayer(a)
			else
				error('AttackTo的参数应指定为玩家的index')
			end
		end,

		MoveTo=function(t,a)
			if not isPosition(a) then
				error('MoveTo 仅接受有效的position')
			end
			return t.origin:MoveTo(a)
		end,
		Hold=function(t,a)
			return t.origin:Hold(not not a)
		end,
	}
	monsterTrack = {}
	function MonsterTrack(p)
		local i=p.index
		local u=MonstersAliveList[i]

		if not monsterTrack[i] or u==nil then
			monsterTrack[i] = Track:New(p)
			monsterTrack[i].func={}
			MonstersAliveList[i]={}
			--2021_12_19
			MonstersAliveList[i].OnUpdate=REGISTER:New()
			u=MonstersAliveList[i]
		end
		for k, v in pairs(monsterFunc) do
			monsterTrack[i].func[k] = monsterFunc[k]
		end
		monsterTrack[i].WriteBase = function(self, t, k, v)
			if monsterAttrWrite[k] then
				if u.deadTime then
					error('怪物死了，写入报错'..k)
				else
					monsterAttrWrite[k](t, v)
				end
			else
				if v then
					t[k]=v
				else
					--error("向"..k.."写入nil")
				end

			end
		end
		monsterTrack[i].ReadBase = function(self, t, k)
			if monsterAttrRead[k] then
				return monsterAttrRead[k](t)
			end
			return t[k]
		end
		u.health = u.health or p.health
		u.maxhealth = u.maxhealth or p.maxhealth
		u.armor = u.armor or p.armor
		u.maxarmor = u.maxarmor or p.maxarmor

		return monsterTrack[i]:Track(p)
	end
	weaponFunc={
		GetWeaponType=function(t,...)
			return t.origin:GetWeaponType(...)
		end,
		AddClip1=function(t,...)
			return t.origin:AddClip1(...)
		end,
	}

	function WeaponTrack(p)
		local d=Track:New(p)
		d.func={}
		for k, v in pairs(weaponFunc) do
			d.func[k] = weaponFunc[k]
		end
		d.WriteBase = function(self, t, k, v)
			if weaponAttrWrite[k] then
				weaponAttrWrite[k](t, v)
			else
				t[k]=v
			end
		end
		d.ReadBase = function(self, t, k)
			if weaponAttrRead[k] then
				return weaponAttrRead[k](t)
			end
			return t[k]
		end
		return d:Track(p)
	end

	blockTracks={}
	blockFunc={
		Event=function(t,...)
			return t.origin:Event(...)
		end,
	}
	function BlockTrack(p)
		local a=blockTracks[positionToXyz(p.position)]
		if a then
			return a
		end
		local blockTrack =Track:New(p)
		blockTrack.func={}
		function p:OnUse(player)
			local b=self
			local a=blockTracks[positionToXyz(b.position)]
			if a.OnUse then
				a:OnUse(auto(player))
			end
		end
		function p:OnTouch(player)
			local b=self
			local a=blockTracks[positionToXyz(b.position)]
			if a.OnTouch then
				a:OnTouch(auto(player))
			end
		end
		for k, v in pairs(blockFunc) do
			blockTrack.func[k] = blockFunc[k]
		end

		blockTrack.WriteBase = function(self, t, k, v)
			if blockAttrWrite[k] then
				blockAttrWrite[k](t, v)
			elseif k=='OnUse'then
				rawset(blockTrack.func,k,v)
				rawset(blockTrack.func,"OnTouch",v)
			elseif k=='OnTouch'then
				rawset(blockTrack.func,k,v)
				rawset(blockTrack.func,"OnUse",v)
			else
				t[k]=v
			end
		end
		blockTrack.ReadBase = function(self, t, k)
			if blockAttrRead[k] then
				return blockAttrRead[k](t)
			end
			if k=='OnUse'then
				return rawget(blockTrack.func,'OnUse')
			elseif k=='OnTouch'then
				return rawget(blockTrack.func,'OnTouch')
			else

			end
			return t[k]
		end
		a=blockTrack:Track(p)
		blockTracks[positionToXyz(p.position)]=a
		return a
	end

	function positionToXyz(p)return p.x+200|p.y+200<<9|p.z+200<<18 end

	--function BlockTrack(p)
	--	blockTrack = Track:New(p)
	--	blockTrack.func={}
	--	for k, v in pairs(blockFunc) do
	--		blockTrack.func[k] = function(self, ...)
	--			return auto(v(p, ...))
	--		end
	--	end
	--	blockTrack.WriteBase = function(self, t, k, v)
	--		if blockAttrWrite[k] then
	--			blockAttrWrite[k](t, v)
	--		else
	--			t[k]=v
	--		end
	--	end
	--	blockTrack.ReadBase = function(self, t, k)
	--		if blockAttrRead[k] then
	--			return blockAttrRead[k](t)
	--		end
	--		return t[k]
	--	end
	--	return blockTrack:Track(p)
	--end
	syncFunc={

	}
	function SyncTrack(p)
		local d=Track:New(p)
		d.func={}
		for k, v in pairs(syncFunc) do
			d.func[k] = syncFunc[k]
		end
		d.WriteBase = function(self, t, k, v)
			if syncAttrWrite[k] then
				syncAttrWrite[k](t, v)
			else
				t[k]=v
			end
		end
		d.ReadBase = function(self, t, k)
			if syncAttrRead[k] then
				return syncAttrRead[k](t)
			end
			return t[k]
		end
		return d:Track(p)
	end
end

--2021/12/4增加OnPlayerUpdate
if Game then
	Framework.GamePlug.OnUpdate:Register(function(time)
		for i = 1, 24 do
			local player = Game.Player:Create(i)
			if player then
				Framework.GamePlug.OnPlayerUpdate:Trigger(player, time)
				--2021_12_19
				player.OnUpdate:Trigger(player,time)
			end
		end
	end)


	Framework.GamePlug.OnLaterUpdate:Register(function(time)
		for i = 1, 24 do
			local player = Game.Player:Create(i)
			if player then
				Framework.GamePlug.OnPlayerLaterUpdate:Trigger(player, time)
				player.OnLaterUpdate:Trigger(player,time)
			end
		end
	end)
	--2021/12/1增加SetUserSave，用于保存user数据
	--2024/10/14更新使用serialize和unserialize保存和读取
	playerFunc.SetTableSave = function(t, key, inTable)
		local s = Serialize(inTable)
		t:SetGameSave(key,s)
	end

	playerFunc.GetTableSave = function(t,key)
		local s = t:GetGameSave(key)
		return Unserialize(s)
	end
end

function FindKeyInTable(tab,key)
	if type(tab)=="table" then
		for k,v in pairs(tab) do
			if k==key then
				return true
			end
			if type(v)=="table" then
				FindKeyInTable(v,key)
			end
		end
	end
	return false
end
function SafeCreateTable(t,otherTab)
	if not t[otherTab] then
		t[otherTab]={}
	end
	return t
end
--2024/10/14 table的序列化与反序列化
function Serialize(obj)
	local lua = ""
	local t = type(obj)
	if t == "number" then
		lua = lua .. obj
	elseif t == "boolean" then
		lua = lua .. tostring(obj)
	elseif t == "string" then
		lua = lua .. string.format("%q", obj)
	elseif t == "table" then
		lua = lua .. "{\n"
		for k, v in pairs(obj) do
			lua = lua .. "[" .. Serialize(k) .. "]=" .. Serialize(v) .. ",\n"
		end
		local metatable = getmetatable(obj)
		if metatable ~= nil and type(metatable.__index) == "table" then
			for k, v in pairs(metatable.__index) do
				lua = lua .. "[" .. Serialize(k) .. "]=" .. Serialize(v) .. ",\n"
			end
		end
		lua = lua .. "}"
	elseif t == "nil" then
		return nil
	else
		error("can not serialize a " .. t .. " type.")
	end
	return lua
end

function Unserialize(lua)
	local t = type(lua)
	if t == "nil" or lua == "" then
		return nil
	elseif t == "number" or t == "string" or t == "boolean" then
		lua = tostring(lua)
	else
		error("can not unserialize a " .. t .. " type.")
	end
	lua = "return " .. lua
	local func = load(lua)
	if func == nil then
		return nil
	end
	return func()
end
-- 优化SignalPlus在长字符串下的网络性能
-- ===========================================
-- 初始化表
-- ===========================================
CommonlySignal = CommonlySignal or {}
CommonlySignalReverse = CommonlySignalReverse or {}

-- ===========================================
-- 工具函数
-- ===========================================
if Game then
	function LearnSignal(msg,player)
		-- 自学习信号表
		local tmp = PlayerCommonSignal[player.name]
		local signalUseCount=tmp.signalUseCount
		local signalIndex=tmp.signalIndex
		local commonlySignal=tmp.commonlySignal
		local commonlySignalReverse=tmp.commonlySignalReverse
		local sync=tmp.sync
		signalUseCount[msg] = (signalUseCount[msg] or 0) + 1
		if signalUseCount[msg] == 2 and not commonlySignal[msg] then
			commonlySignal[msg] = signalIndex
			commonlySignalReverse[signalIndex] = msg
			print(string.format("[GameLearned] '%s' → #%d", msg, signalIndex))
			sync.value = msg..","..signalIndex
			tmp.signalIndex = tmp.signalIndex + 1
		end
	end
else

	SyncCommonlySignal = UI.SyncValue:Create("CommonlySignalSync"..tostring(UI.PlayerIndex()))
	function SyncCommonlySignal:OnSync()
		if self.value then
			local args = splitstr_tostring(self.value)
			local msg=args[1]
			local signalIndex = tonumber(args[2])
			print(string.format("[UILearned] '%s' → #%d", msg, signalIndex))
			CommonlySignal[msg] = signalIndex
			CommonlySignalReverse[signalIndex] = msg
		end
	end
end

local function DecodeSignal(msg,player)
    -- 检查是否是编号信号
    if string.match(msg, "^#%d+$") then
        local index = tonumber(string.sub(msg, 2))
		local signalReverse = {}
		if Game then
			signalReverse = PlayerCommonSignal[player.name].commonlySignalReverse
		else
			signalReverse = CommonlySignalReverse
		end
		
        if index and signalReverse[index] then
            return signalReverse[index]
        else
            print("[Warning] Unknown signal index:", index)
        end
    end
    return msg
end
--Game中文信号插件2023/1/30
OnSignalPlus=true
if OnSignalPlus then
	local StartSignal ={ 123, 211, 4,42}

	local EndSignal ={  123, 211, 123,33}

	if UI then
		local startPos=1
		local endPos=1
		local start=false
		local over=false
		local result={}
		Framework.UIPlug.OnSignalPlus = REGISTER:New()

		Framework.UIPlug.OnSignal:Register(function(signal)
			if not start then
				if signal==StartSignal[startPos] then
					startPos=startPos+1
				elseif startPos>#StartSignal then
					start=true
				else
					startPos = 1
					result = {}
				end
			end

			if start and not over then
				table.insert(result,signal)
				if signal==EndSignal[endPos] then
					endPos=endPos+1
				else
					endPos=1
				end
				if endPos>#EndSignal then
					over=true
				end
			end

			if over then
				for i=1,#EndSignal do
					table.remove(result)
				end
				-- 字节转字符串
				local msg = ByteArrayToString(result)
				-- 自动解码信号（索引→原文）
				msg = DecodeSignal(msg,player)
				Framework.UIPlug.OnSignalPlus:Trigger(msg)
				startPos=1
				endPos=1
				result={}
				start=false
				over=false
			end
		end)
	end
	if Game then
		--2021/11/14增加SignalPlus，主要用于字符串的传递
		playerFunc.SignalPlus = function(t, ...)
			local args = table.pack(...)
			local data = args[1]
			if not data then return end
			if type(data) ~= "string" then
				data = tostring(data)
			end

			--句号的utf8
			for i = 1, #StartSignal do
				t:Signal(StartSignal[i])
			end
			-- 自动使用已知索引发送
			if CommonlySignal[data] then
				data = "#" .. tostring(CommonlySignal[data])
			else
				LearnSignal(data,t)
			end

			local array = StringToByteArray(data)
			for i = 1, #array do
				t:Signal(array[i])
			end
			--句号的utf8
			for i = 1, #EndSignal do
				t:Signal(EndSignal[i])
			end

		end
	end
end
--
--方法延迟执行2021/12/9
InvokeFunc=
{
	time=0,
	REGISTER={},
	targetTime=0,
}
InvokeFuncs= {}
InvokeFuncIndex=1
function InvokeFunc:New(f,t,args)
	local o={}
	self.__index=self
	setmetatable(o,self)
	o.REGISTER=REGISTER:New(f)
	o.REGISTER:Register(f)
	o.OnFinished=REGISTER:New()
	o.targetTime=t
	o.time=0
	o.index=InvokeFuncIndex
	if args then
		o.args=args
	end
	return o
end
function Invoke(f,t,args)
	local func=InvokeFunc:New(f,t,args)

	InvokeFuncs[func.index]=func

	InvokeFuncIndex=InvokeFuncIndex+1

	return func
end
function InvokeMain()
	for k,invokeFunc in pairs(InvokeFuncs) do
		invokeFunc.time=invokeFunc.time+Time.deltaTime
		if invokeFunc.time>invokeFunc.targetTime  then
			if type(invokeFunc.args)=="table" and #invokeFunc.args>0 then
				invokeFunc.REGISTER:Trigger(table.unpack(invokeFunc.args))
			else
				invokeFunc.REGISTER:Trigger(invokeFunc.args)
			end
			invokeFunc.OnFinished:Trigger()
			InvokeFuncs[invokeFunc.index]=nil
		end
	end
end
if Game then
	Framework.GamePlug.OnUpdate:Register(function(t)
		InvokeMain()
	end)
end
if UI then
	Framework.UIPlug.OnUpdate:Register(function(t)
		InvokeMain()
	end)
end

--UI中文信号插件2023/1/30
OnPlayerSignalPlus=true
if OnPlayerSignalPlus then

	local StartSignal ={ 123,42,23,77}
	local EndSignal ={ 31,32,2,3,32,74}

	if Game then
		Framework.GamePlug.OnPlayerSignalPlus=REGISTER:New()
		local PlayerSignalPlus={}
		PlayerCommonSignal={}
		Framework.GamePlug.OnPlayerConnect:Register(function(player)
			PlayerSignalPlus[player.name]={
				start=false,
				startPos=1,
				result={},
				over=false,
				endPos=1
			}
			PlayerCommonSignal[player.name]={
				signalUseCount = signalUseCount or {},
				commonlySignal = commonlySignal or {},
				commonlySignalReverse = commonlySignalReverse or {},
				signalIndex = signalIndex or 1,
				sync = Game.SyncValue:Create("CommonlySignalSync"..player.index)
			}

		end)
		Framework.GamePlug.OnPlayerDisconnect:Register(function(player)
			PlayerSignalPlus[player.name]=nil
			PlayerCommonSignal[player.name]=nil
		end)

		Framework.GamePlug.OnPlayerSignal:Register(function(player,signal)
			local tmp=PlayerSignalPlus[player.name]
			if not tmp.start then
				if signal==StartSignal[tmp.startPos] then
					tmp.startPos=tmp.startPos+1
				elseif tmp.startPos>#StartSignal then
					tmp.start=true
				else
					tmp.startPos = 1
					tmp.result = {}
				end
			end

			if tmp.start and not tmp.over then
				table.insert(tmp.result,signal)
				if signal==EndSignal[tmp.endPos] then
					tmp.endPos=tmp.endPos+1
				else
					tmp.endPos=1
				end
				if tmp.endPos>#EndSignal then
					tmp.over=true
				end
			end

			if tmp.over then
				for i=1,#EndSignal do
					table.remove(tmp.result)
				end
				 -- 字节转字符串
				local msg = ByteArrayToString(tmp.result)
				-- 自动解码信号（索引→原文）
				msg = DecodeSignal(msg,player)

				Framework.GamePlug.OnPlayerSignalPlus:Trigger(player,msg)
				tmp.startPos=1
				tmp.endPos=1
				tmp.result={}
				tmp.start=false
				tmp.over=false
			end
		end)
	end
	if UI then
		UI.SignalPlus=function(msg)
		    -- 自动使用已知索引发送
			-- todo 暂时不优化UI SignalPlus的发送

			local array=StringToByteArray(msg)
			for i=1,#StartSignal do
				UI.Signal(StartSignal[i])
			end
			for i=1,#array do
				UI.Signal(array[i])
			end
			for i=1,#EndSignal do
				UI.Signal(EndSignal[i])
			end
		end
	end
end

Framework.Utility= {}
--如果连续的signal和pointer（Stack）中相同返回true，否则使用originStack来重置pointer（Stack）
function Framework.Utility.SignalCheck(pointer, originQueue, signal)
	if type(signal)=="number" then
		if pointer.front and pointer.front.data==signal then
			pointer.front=pointer.front.next

			if pointer.front==nil then
				pointer.front= originQueue.front
				return true
			end
		else
			pointer.front= originQueue.front
			return false
		end
	end
end

--垃圾回收 内存监控
--CG=collectgarbage
--memeryCount=CG('count')*1024
--function OnUpdateMemeryMonitor()
--	local a=CG('count')*1024
--	if a>memeryCount then
--		print(Game and'g'or'u',' memery:',a,',',a-memeryCount)
--		memeryCount=a
--	end
--end
--
--if Game then
--	Framework.GamePlug.OnUpdate:Register(OnUpdateMemeryMonitor)
--end
--if UI then
--	Framework.UIPlug.OnUpdate:Register(OnUpdateMemeryMonitor)
--end


Node=
{
	next,
	last,
	data,
}
function Node:New(obj)
	local	node={}
	self.__index=self
	setmetatable(node,self)
	node.data=obj
	return node
end

Stack= {

	count=0
}

function Stack:New(list,count,reverse)
	local	stack={}
	self.__index=self
	setmetatable(stack,self)
	if type(list)=="table" then
		local count = count or #list
		for i=1,count do
			if reverse then
				stack:Push(list[count-i+1])
			else
				stack:Push(list[i])
			end
		end
	end
	return stack
end
function Stack:Clear()
	self.top=nil
	self=nil
end
function Stack:Peek()
	if self.top then
		return self.top.data
	end
	return nil
end
--移除并返回在 Stack 的顶部的对象
function Stack:Pop()
	if self.top then
		self.count=self.count-1
		local data=self.top.data
		self.top=self.top.next
		return data
	end
	return nil
end
--向 Stack 的顶部添加一个对象
function Stack:Push(obj)
	if self.top==nil then
		self.bottom=Node:New(obj)
		self.top=self.bottom
	else
		local temp=self.top
		self.top=Node:New(obj)
		self.top.next=temp
	end
	self.count=self.count+1
end
--复制 Stack 到一个新的数组中
function Stack:ToArray()
	local temp=self.top
	local array
	local count = self.count
	while temp~=nil do
		array=array or {}
		array[count]=temp.data
		temp=temp.next
		count = count - 1
	end
	return array
end
function Stack:Contains(key)
	local temp=self.top
	while temp~=nil do
		if key==temp.data then
			return
		else
			temp=temp.next
		end
	end
	return false
end
Stack.__tostring=function(stack)
	local temp=stack:ToArray()
	local str=""
	for i=1,#temp do
		if i==1 then
			str=str..temp[i]
		else
			str=str..","..temp[i]
		end
	end
	return str
end
--AI生成待验证
function Stack:InsertAtPosition(obj, position)
    if position < 1 or position > self.count + 1 then
        return  -- Invalid position
    end

    if position == 1 then
        self:Push(obj)  -- Insert at the beginning
        return
    end

    local currentPos = 1
    local currentNode = self.top
    local prevNode = nil

    while currentPos < position do
        prevNode = currentNode
        currentNode = currentNode.next
        currentPos = currentPos + 1
    end

    local newNode = Node:New(obj)
    prevNode.next = newNode
    newNode.next = currentNode
    self.count = self.count + 1
end
--AI生成待验证
function Stack:RemoveAtPosition(position)
    if position < 1 or position > self.count then
        return  -- Invalid position
    end

    if position == 1 then
        self:Pop()  -- Remove the element at the top
        return
    end

    local currentPos = 1
    local currentNode = self.top
    local prevNode = nil

    while currentPos < position do
        prevNode = currentNode
        currentNode = currentNode.next
        currentPos = currentPos + 1
    end

    prevNode.next = currentNode.next
    self.count = self.count - 1
end
--AI生成待验证
function Stack:FindElementAtPosition(position)
    if position < 1 or position > self.count then
        return nil  -- Invalid position
    end

    local currentPos = 1
    local currentNode = self.top

    while currentPos < position do
        currentNode = currentNode.next
        currentPos = currentPos + 1
    end

    return currentNode.data
end

Queue={
	back,
	front,
	count=0
}
function Queue:New(list,size)
	local	queue={}
	self.__index=self
	setmetatable(queue,self)
	if type(list)=="table" then
		for i = 1, size or #list do
			queue:Enqueue(list[i])
		end
	end
	return queue
end
--从 Queue 中移除所有的元素
function Queue:Clear()
	self.front=nil
end
--判断某个元素是否在 Queue 中
function Queue:Contains(obj)
	local pointer=self.front
	while	pointer~=nil do
		if pointer.data==obj then
			return true
		else
			pointer=pointer.next
		end
	end
	return false
end
--移除并返回在 Queue 的开头的对象
function Queue:Dequeue()
	if self.front then
		local data=self.front.data
		self.front=self.front.next
		self.count=self.count-1
		return data
	end
	return nil
end
--向 Queue 的末尾添加一个对象
function Queue:Enqueue(obj)
	if self.front==nil then
		self.front=Node:New(obj)
		self.back=self.front
	else
		self.back.next=Node:New(obj)
		self.back=self.back.next
	end
	self.count=self.count+1
end
--复制 Queue 到一个新的数组中
function Queue:ToArray()
	local temp=self.front
	local array={}
	local index=1
	local str=""
	while temp~=nil do
		array[index]=temp.data
		index=index+1
		temp=temp.next
	end
	setmetatable(array,{__len=function()return self.count  end})
	return array
end
function Queue:IsEmpty()
	if self.front==nil then
		return true
	else
		return false
	end
end

Queue.__tostring=function(queue)
	local temp=queue.front
	local str=""
	while temp~=nil do
		if temp.data==nil then
			temp.data="nil"
		end
		if temp.next==nil then
			str=str..temp.data
		else
			str=str..temp.data..","
		end
		temp=temp.next
	end
	return str
end

Mathf=
{
	Rad2Deg=360 / (math.pi * 2)--弧度到度换算常量（只读）
}


function Mathf.Lerp(fromfloat, tofloat, t)
	local temp = tofloat - fromfloat
	return fromfloat + temp * t
end
function Mathf.Prime(num)
	if num<3 then
		return num>1
	end
	if num%6 ~= 1 and num%6~=5 then
		return false
	end
	local sqrt=math.floor(math.sqrt(num))
	for i = 5,sqrt do
		if num%i==0 and num%(i+2)==0 then
			return false
		end
		sqrt=sqrt-6
	end
	return true
end

function Mathf.Euler(n)
	local res=n
	local a=n
	for i = 2, a do
		if a%i==0 then
			res=res/i*(i-1)
			while(a%i==0) do a=a/i  end
		end
		i=i*i
	end
	if a>1 then
		res=res/a*(a-1)
	end
	return res
end





Vector2={
	zero={x=0,y=0},
	magnitude,	--返回该向量的长度。（只读）
	normalized,	--返回 magnitude 为 1 时的该向量。（只读）
	x,
	y,
}


function Vector2:New(xOrTable,y,bool)
	local o={}
	setmetatable(o,self)
	self.__index=self
	if type(xOrTable)=="table" then
		o.x=xOrTable.x
		o.y=xOrTable.y
	else
		o.x=xOrTable
		o.y=y
	end

	o.magnitude=math.sqrt(o.x^2+o.y^2)

	if not bool then
		o.normalized=Vector2.Normalized(o)
	end
	return o
end
Vector2.__add=function(Vector2_1,Vector2_2)
	local newVector2=Vector2:New(Vector2_1.x+Vector2_2.x,Vector2_1.y+Vector2_2.y)
	return newVector2
end
Vector2.__sub= function(Vector2_1,Vector2_2)
	return Vector2:New(Vector2_1.x-Vector2_2.x,Vector2_1.y-Vector2_2.y)
end
Vector2.__eq=function(Vector2_1,Vector2_2)
	if Vector2_1.x==Vector2_2.x and Vector2_1.y==Vector2_2.y then
		return true
	else
		return false
	end
end

function Vector2.__mul(vec, scalar)
	if type(scalar)=="table" then
		local tmp = scalar
		scalar = vec
		vec = tmp
	end
	return Vector2:New(vec.x * scalar, vec.y * scalar)
end
function Vector2.__div(vec, scalar)
	if type(scalar)=="table" then
		local tmp = scalar
		scalar = vec
		vec = tmp
	end
	return Vector2:New(vec.x / scalar, vec.y / scalar)
end
Vector2.__tostring=function(Vector2)
	return "{"..Vector2.x..","..Vector2.y.."}"
end
--x−minmax−min
function Vector2.Normalized(V2)
	local v2=Vector2:New(V2.x,V2.y,true)
	if  v2.magnitude>0 then
		Vector2.Normalize(v2)
	else
		v2.x=0
		v2.y=0
	end
	return	v2
end
function Vector2.Normalize(V2)
	V2.x=V2.x/V2.magnitude
	V2.y=V2.y/V2.magnitude
end
function Vector2.Distance(fromVector, toVector)
	return math.sqrt((fromVector.x-toVector.x)^2+(fromVector.y-toVector.y)^2)
end

--两个向量之间的无符号锐角
function Vector2.Angle(fromVector, toVector)
	return math.acos(Vector2.Dot(fromVector.normalized,toVector.normalized))*Mathf.Rad2Deg
end

--点乘
function Vector2.Dot(V2_1,V2_2)
	return V2_1.x*V2_2.x+V2_1.y*V2_2.y
end
--叉乘
function Vector2.Cross(a,b)
	return Vector3:New((a.y*b.x-a.x*b.y)*Vector3:New(0,0,1))
end

Vector3 = {
	normalized,
	zero = { x = 0, y = 0, z = 0 },
	one = { x = 1, y = 1, z = 1 },
	magnitude,
	x,
	y,
	z,
}


--三维向量相加
Vector3.__add = function(Vector3_1, Vector3_2)
	local tempVector3 = {}
	tempVector3.x = Vector3_1.x + Vector3_2.x
	tempVector3.y = Vector3_1.y + Vector3_2.y
	tempVector3.z = Vector3_1.z + Vector3_2.z
	return Vector3:New(tempVector3)
end
--三维向量相减
Vector3.__sub = function(Vector3_1, Vector3_2)
	local tempVector3 = {}
	tempVector3.x = Vector3_1.x - Vector3_2.x
	tempVector3.y = Vector3_1.y - Vector3_2.y
	tempVector3.z = Vector3_1.z - Vector3_2.z
	return Vector3:New(tempVector3)
end
Vector3.__eq = function(Vector3_1, Vector3_2)
	if Vector3_1.x == Vector3_2.x and Vector3_1.y == Vector3_2.y and Vector3_1.z == Vector3_2.z then
		return true
	end
	return false
end
--三维向量相乘
Vector3.__mul = function(Vector3_1, float)
	local temp
	if type(Vector3_1) ~= "table" then
		temp = float
		float = Vector3_1
		Vector3_1 = temp
	end
	local tempVector3 = {}
	tempVector3.x = Vector3_1.x * float
	tempVector3.y = Vector3_1.y * float
	tempVector3.z = Vector3_1.z * float
	return Vector3:New(tempVector3)
end
Vector3.__tostring=function(Vector3)
	return "{"..Vector3.x..","..Vector3.y..","..Vector3.z.."}"
end

--新建三维向量
function Vector3:New(xOrTable,y,z,bool)
	local mvector3 = {}
	setmetatable(mvector3, self)
	self.__index = self
	if type(xOrTable)=="table" then
		mvector3.x = xOrTable.x
		mvector3.y = xOrTable.y
		mvector3.z = xOrTable.z
	else
		mvector3.x = xOrTable
		mvector3.y = y
		mvector3.z = z
	end

	mvector3.magnitude= math.sqrt(mvector3.x ^ 2 + mvector3.y ^ 2 + mvector3.z ^ 2)
	if not bool then
		mvector3.normalized=Vector3.Normalized(xOrTable,y,z)
	end

	return mvector3
end


function Vector3.Normalized(x,y,z)
	local mVector3 = Vector3:New(x,y,z,true)
	if mVector3.magnitude>0 then
		Vector3.Normalize(mVector3)
	else
		mVector3.x=0
		mVector3.y=0
		mVector3.z=0
	end
	return mVector3
end

function Vector3.Distance (formVector3, toVector3)
	if formVector3 == nil or toVector3 == nil then
		return	nil
	end
	return math.sqrt((toVector3.x - formVector3.x) ^ 2 + (toVector3.y - formVector3.y) ^ 2 + (toVector3.z - formVector3.z) ^ 2)
end

function Vector3.Normalize(Vector3)
	local temp = math.sqrt(Vector3.x ^ 2 + Vector3.y ^ 2 + Vector3.z ^ 2)
	if Vector3.magnitude>0 then
		Vector3.x = Vector3.x / temp
		Vector3.y = Vector3.y / temp
		Vector3.z = Vector3.z / temp
	end
end
function Vector3.Cross(V3_1,V3_2)
	return Vector3:New(
			V3_1.y*V3_2.z -V3_2.y*V3_1.z,
			V3_2.x*V3_1.z-V3_2.z*V3_1.x,
			V3_1.x*V3_2.y -V3_2.x*V3_1.y
	)
end

function Vector3.Dot(V3_1,V3_2)
	return V3_1.x*V3_2.x+ V3_1.y*V3_2.y+ V3_1.z*V3_2.z
end


if Game then
	-- 获取指定距离内最靠近指定实体的方块
	-- 无满足要求的方块时返回空值
	-- 多个方块距离相同时 返回在x,y,z 扫描顺序上的第一个方块
	playerFunc.FindBlockInZone=function(p,r)
		local minDistance=10000000
		local result
		for x=p.position.x-r,p.position.x+r do
			for y=p.position.y-r,p.position.y+r do
				for z=p.position.z-r,p.position.z+r do
					local block=Game.EntityBlock:Create({x=x,y=y,z=z})
					if block then
						local distance=Vector3.Distance(p.position,block.position)
						if 	distance<r then
							if minDistance>distance then
								minDistance=distance
								result=block
							end
						end
					end
				end
			end
		end
		return result
	end
	playerFunc.FindBlocksInZone=function(p,r)
		local result={}
		for x=p.position.x-r,p.position.x+r do
			for y=p.position.y-r,p.position.y+r do
				for z=p.position.z-r,p.position.z+r do
					local block=Game.EntityBlock:Create({x=x,y=y,z=z})
					if block then
						local distance=Vector3.Distance(p.position,block.position)
						if 	distance<r then
							table.insert(result,block)
						end
					end
				end
			end
		end
		return result
	end

	blockFunc.Reset=function(t,...)
		return t:Event({action="reset"},0)
	end
	blockFunc.Use=function(t,...)
		return t:Event({action="use"},0)
	end
	blockFunc.Trigger=function(t,...)
		t:Event({action="signal",value=false},0)
		t:Event({action="signal",value=true},0)
	end
	blockFunc.Signal=function(t,bool)
		return t:Event({action="signal",value=bool},0)
	end

	blockFunc.Touch=function(t,...)
		return t:Event({action="touch"},0)
	end

end
if Game then
	Framework.GamePlug.OnUpdate:Register(function(time)
		for i,u in pairs(MonstersAliveList) do
			local entity=Game.GetEntity(i)
			local monster
			if entity then
				monster=entity:ToMonster()
			end

			if monster then
				Framework.GamePlug.OnMonsterUpdate:Trigger( monster  ,time)
				--2021_12_19
				monster.OnUpdate:Trigger(monster,time)
			end
		end
	end)
	Framework.GamePlug.OnMonsterUpdate=REGISTER:New()
end

--2021_12_18
if Game then
	monsterFunc.FollowTo=function(m,e,a)
		local function FollowUpdate(monster,time)
			local m=monster
			local u=MonstersAliveList[m.index]
			local e=u.MuBiaoEntity
			if e then
				if Vector3.Distance(m.position,e.position)>=(u.MuBiaoJuLi or 1000) then
					m:Stop(true)
				else
					m:MoveTo(e.position)
				end
			end
		end
		local u=MonstersAliveList[m.index]
		u.monster=m
		u.MuBiaoEntity=e
		u.MuBiaoJuLi=a
		if Vector3.Distance(m.position,e.position)>=(u.MuBiaoJuLi or 1000) then
			m:Stop(true)
			u.OnUpdate:UnRegister(FollowUpdate)
		else
			m:MoveTo(e.position)
			u.OnUpdate:Register(FollowUpdate)
		end
	end
end
if Game then
	--每个方块大小
	Block={
		--单位m
		width=1.01600000103632,
		height=1.01600000103632
	}
	--单位m^2/s
	G=20.320000020726
end
if Game then
	playerAttrRead.OnUpdate=function(p)
		return pus[p.name].OnUpdate
	end
	playerAttrRead.OnLaterUpdate=function(p)
		return pus[p.name].OnLaterUpdate
	end
	monsterAttrRead.OnUpdate=function(m)
		return MonstersAliveList[m.index].OnUpdate
	end
	playerAttrWrite.OnUpdate=function()
		error("player.OnUpdate只读")
	end
	playerAttrWrite.OnLaterUpdate=function()
		error("player.OnLaterUpdate只读")
	end
	monsterAttrWrite.OnUpdate=function()
		error("monster.OnUpdate只读")
	end
end

--触发器
--Trigger
Framework.Trigger={
	pos1={},
	pos2={},
}
Framework.AllTrigger={}

if Game then
	function Framework.Trigger:New(pos1,pos2)
		local trigger={}
		setmetatable(trigger,self)
		self.__index=self
		trigger.pos1=Vector3:New(pos1)
		trigger.pos2=Vector3:New(pos2)
		trigger.OnTriggerEnter=REGISTER:New()
		trigger.OnTriggerExit=REGISTER:New()
		trigger.OnTriggerStay=REGISTER:New()
		trigger.entitys={}
		table.insert(Framework.AllTrigger,trigger)
		return trigger
	end
	function Framework.Trigger:Remove()
		for k,trigger in pairs(Framework.AllTrigger) do
			if trigger==self then
				Framework.AllTrigger[k]=nil
			end
		end
	end
	function Framework.TriggerFunc(entity)
		for k,trigger in pairs(Framework.AllTrigger) do
			if InZone(trigger.pos1,trigger.pos2,entity.position) then
				if not trigger.entitys[entity.index] then
					trigger.entitys[entity.index]=entity
					trigger.OnTriggerEnter:Trigger(entity)
				end
				trigger.OnTriggerStay:Trigger(entity)
			elseif trigger.entitys[entity.index]  then
				trigger.entitys[entity.index]=nil
				trigger.OnTriggerExit:Trigger(entity)
			end
		end
	end
	Framework.GamePlug.OnKilled:Register(function(monster,killer)
		if not monster:IsMonster() then return  end

		for k,trigger in pairs(Framework.AllTrigger) do
			if trigger.entitys[monster.index] then
				trigger.OnTriggerExit:Trigger(monster)
			end
		end
		for k,trigger in pairs(Framework.AllSphereTrigger) do
			if trigger.entitys[monster.index] then
				trigger.OnTriggerExit:Trigger(monster)
			end
		end
	end)
	Framework.GamePlug.OnPlayerKilled:Register(function(player)
		for k,trigger in pairs(Framework.AllTrigger) do
			if trigger.entitys[player.index] then
				trigger.OnTriggerExit:Trigger(player)
			end
		end
		for k,trigger in pairs(Framework.AllSphereTrigger) do
			if trigger.entitys[player.index] then
				trigger.OnTriggerExit:Trigger(player)
			end
		end
	end)
	Framework.GamePlug.OnPlayerUpdate:Register(function(player)
		Framework.TriggerFunc(player)
		Framework.SphereTriggerFunc(player)
	end)

	Framework.GamePlug.OnMonsterUpdate:Register(function(monster)
		Framework.TriggerFunc(monster)
		Framework.SphereTriggerFunc(monster)
	end)

end
if Game then
	Framework.GamePlug.OnPlayerConnect:Register(function(player)
		--2021_12_19
		pus[player.name].OnUpdate=REGISTER:New()
		pus[player.name].OnLaterUpdate=REGISTER:New()
	end)
end
--球形触发器
Framework.SphereTrigger={
	centerPos,
	r,
}
Framework.AllSphereTrigger={}
function Framework.SphereTrigger:New(posOrEntity,r)
	local trigger={}
	setmetatable(trigger,self)
	if posOrEntity.IsMonster or posOrEntity.IsPlayer then
		trigger.centerEntity=posOrEntity
	else
		trigger.centerPos=posOrEntity
	end
	trigger.r=r
	trigger.entitys={}
	trigger.OnTriggerEnter=REGISTER:New()
	trigger.OnTriggerExit=REGISTER:New()
	trigger.OnTriggerStay=REGISTER:New()
	table.insert(Framework.AllSphereTrigger,trigger)
	return trigger
end
function Framework.SphereTrigger:Remove()
	for k,trigger in pairs(Framework.SphereTrigger) do
		if trigger==self then
			Framework.SphereTrigger[k]=nil
		end
	end
end
function Framework.SphereTriggerFunc(entity)
	for k,trigger in pairs(Framework.AllSphereTrigger) do
		local pos
		if trigger.centerPos then
			pos=trigger.centerPos
		elseif trigger.centerEntity then
			pos=trigger.centerEntity.position
		end
		if Vector3.Distance(pos,entity.position)<=trigger.r then
			if not trigger.entitys[entity.index] then
				trigger.entitys[entity.index]=entity
				trigger.OnTriggerEnter:Trigger(entity)
			end
			trigger.OnTriggerStay:Trigger(entity)
		elseif trigger.entitys[entity.index]  then
			trigger.entitys[entity.index]=nil
			trigger.OnTriggerExit:Trigger(entity)
		end
	end
end

Framework.MonsterType={
	A101AR=1477,
	RUNNER0=247,
	NORMAL3=202,
	NORMAL5=204,
	RUNNER4=209,
	NONE=0,
	HEAVY1=244,
	A104RL=1478,
	RUNNER=210,
	NORMAL0=246,
	RUNNER2=207,
	NORMAL6=205,
	HEAVY2=245,
	RUNNER1=206,
	PUMPKIN_HEAD=1286,
	PUMPKIN=1285,
	RUNNER3=208,
	NORMAL1=200,
	NORMAL2=201,
	GHOST=1284,
	NORMAL4=203,
	RUNNER6=211,
	ALIEN_BEAST=1289,				--异形斗兽
	SOLDIER=688,					--黄巾士兵
	GENERAL=689,					--黄巾将领
	SNOWMAN=763,					--圣诞雪人
	MUSHROOM_KING=248,				--蘑菇王
	ORANGE_MUSHROOM=249,			--橙色蘑菇
	RED_MUSHROOM=250,				--红刺蘑菇王
	WATER_KING=251,					--水灵王
	GREEN_WATER=687,				--绿水灵
	RED_ROBOT=940,					--斗魂红色机
	BLUE_ROBOT=941,					--斗魂蓝色机
	GREEN_FANS=1097,				--绿衣狂热球迷
	RED_FANS=1098,					--红衣狂热球迷
	THROWING_ZOMBIES=1520,			--投掷僵尸
	EXPLODING_ZOMBIES=1521,			--自爆僵尸
	BATTERY=1509,					--生化炮塔
	DEAD_KING=1650,					--异域尸王
	DEAD_MAN1=1651,					--异域男僵尸1
	DEAD_MAN2=1652,					--异域男僵尸2
	DEAD_WOMAN=1653,				--异域女僵尸
	BROKEN_FACE=1950,				--破面重甲
	Titans = 1951,					--泰坦
}


if Game then
	--
	Framework.GamePlug.OnMonsterTakeDamage=REGISTER:New()
	function Framework.GamePlug.OnMonsterTakeDamage:ReturnRule(v, k, d, wt, h)
		local result
		local e = self.Registry
		for i = 1, #e do
			local a = e[i].fun(v, k, d, wt, h)
			if type(a) == 'number' then
				result = (result or 0) + a
			end
		end
		return result
	end

	--怪物攻击
	MonsterAttack=function(killer)
		if killer:IsPlayer() then return end
		local victim=MonstersAliveList[killer.index].target
		local distance=MonstersAliveList[killer.index].AttackRange
		if not MonstersAliveList[victim.index] then return end
		if victim.health>0 then
			if Vector3.Distance(victim.position,killer.position)>=distance then
				killer:MoveTo(victim.position)
			else
				local damage=Framework.GamePlug.OnMonsterTakeDamage:Trigger(victim,killer)
				victim.health=victim.health-damage
				victim:ShowOverheadDamage(damage,0)
				killer:Stop(true,Framework)
			end
		else
			Framework.GamePlug.OnMonsterKilled:Trigger(victim,killer)
			killer:Stop(false,Framework)
			killer.OnUpdate:UnRegister(MonsterAttack)
		end
	end

	monsterFunc.AttackTo=function(monster,pos,distance)
		if pos.IsMonster and pos:IsMonster()  then
			local victim=pos:ToMonster()
			local killer=MonstersAliveList[monster.index]
			killer.target=victim
			killer.AttackRange=distance or 1.4
			killer.OnUpdate:Register(MonsterAttack,REGISTER_MODE.override)
		elseif  isPosition(pos) then
			return monster.origin:AttackTo(pos)
		end
		--error('AttackTo 仅接受有效的position')
	end
	monsterFunc.Stop=function(t,a,user)
		local monster=MonstersAliveList[t.index]
		if user==Framework then
			return t.origin:Stop(not not a)
		else
			if a==true then
				--停止怪物攻击
				monster.target=nil
				monster.OnUpdate:UnRegister(MonsterAttack)
			end
			t.origin:Stop(a)
		end
	end
end
function splitstr_tonumber(inputstr)
	local t = {}
	for str in string.gmatch(inputstr, "([^,]*)") do
		table.insert(t, tonumber(str))
	end
	return t
end
function splitstr_tostring(inputstr)
	local t = {}
	for str in string.gmatch(inputstr, "([^,]*)") do
		table.insert(t, str)
	end
	return t
end
--合并table
function MergeTables(...)
	local tabs = {...}
	if not tabs then
		return {}
	end
	local origin = tabs[1]
	for i = 2,#tabs do
		if origin then
			if tabs[i] then
				for k,v in pairs(tabs[i]) do
					table.insert(origin,v)
				end
			end
		else
			origin = tabs[i]
		end
	end
	return origin
end
function MergeHashTables(...)
	local tabs = {...}
	if not tabs then
		return {}
	end
	local origin = tabs[1]
	for i = 2,#tabs do
		if origin then
			if tabs[i] then
				for k,v in pairs(tabs[i]) do
					origin[k]=v
				end
			end
		else
			origin = tabs[i]
		end
	end
	return origin
end
if UI then
	UI.Box={

	}
	UI.BoxesMgr = {
		boxes={}
	}
	function UITrack(uiObj)
		local uiTrack=Track:New()
		uiTrack.func={
			Set=function(uiObj,setArg)
				if uiObj.origin then
					uiObj.origin:Set(setArg)
				end
			end,
			Show=function(uiObj)
				if uiObj.origin then
					uiObj.origin:Show()
				end
			end,
			Hide=function(uiObj)
				if uiObj.origin then
					uiObj.origin:Hide()
				end
			end,
			Get=function(uiObj)
				if uiObj.origin then
					return uiObj.origin:Get()
				end
			end,
			IsVisible=function(uiObj)
				if uiObj.origin then
					return uiObj.origin:IsVisible()
				end
			end,
			Adaptation=function(uiObj,mode)
				if Draw and Draw.AdaptationSelf then
					Draw.AdaptationSelf(uiObj,mode)
				end
			end,
			DoMove=function(uiObj,startPos,endPos,time,type)
				if Draw and Draw.DoMove then
					Draw.DoMove(uiObj,startPos,endPos,time,type)
				end
			end,
			DoColor=function(uiObj,startColor,endColor,time,type)
				if Draw and Draw.DoColor then
					Draw.DoColor(uiObj,startColor,endColor,time,type)
				end
			end,
			DoScale=function(uiObj,startSize,endSize,time,type)
				if Draw and Draw.DoScale then
					Draw.DoScale(uiObj,startSize,endSize,time,type)
				end
			end,

			AddComponent = function(uiObj,component)
				if uiObj:HasComponent(component) then return end
				if not UI.BoxesMgr.boxes[uiObj] then
					UI.BoxesMgr.boxes[uiObj] = {
						box=uiObj,
						components={},
					}
				end

				print("添加组件"..component.name)
				UI.BoxesMgr.boxes[uiObj].components[component.name] = component
				component.box = uiObj
			end,
			HasComponent = function(uiObj,component)
				if not UI.BoxesMgr.boxes[uiObj] then return false end
				if 	UI.BoxesMgr.boxes[uiObj].components[component.name] then
					return true
				else
					return false
				end
			end,
			RemoveComponent=function(uiObj,component)
				if not UI.BoxesMgr.boxes[uiObj] then return false end
				UI.BoxesMgr.boxes[uiObj].components[component.name] = nil
				return true
			end,
			GetComponent = function(uiObj,component)
				if not component then print("缺少参数component或者参数为nil") return nil end
				if not UI.BoxesMgr.boxes[uiObj] then print("该box没有组件") return nil end
				return UI.BoxesMgr.boxes[uiObj].components[component.name]
			end,
			OnDoMoveStart = function(uiObj)
			end,
			OnDoMove= function(uiObj)
			end,
			OnDoMoveStart= function(uiObj)
			end,
			OnDoMoveEnd= function(uiObj)
			end,
			OnDoScale= function(uiObj)
			end,
			OnDoScaleStart= function(uiObj)
			end,
			OnDoScaleEnd= function(uiObj)
			end,
			OnDoColor= function(uiObj)
			end,
			OnDoColorStart= function(uiObj)
			end,
			OnDoColorEnd= function(uiObj)
			end,
		}
		return uiTrack:Track(uiObj)
	end

	function UI.Box.Create()
		return 	UITrack(UI0.Box.Create())
	end

	UI.Text={}
	UI.Text.Create=function()
		return 	UITrack(UI0.Text.Create())
	end

end

if Game then
	Buff={
		duration=3,
		layer=0,
		Id = nil
	}
	function Buff:Create(Id)
		local buff={}
		buff.OnAdd=REGISTER:New()
		buff.OnRemove=REGISTER:New()
		buff.OnUpdate=REGISTER:New()
		buff.Id = Id
		setmetatable(buff,self)
		self.__index = self
		return buff
	end
	function Buff.Add(entity,buff)
		buff.OnAdd:Trigger(entity)
		if entity:IsPlayer() then
			entity = pus[entity.name]
		else
			entity=MonstersAliveList[entity.index]
		end
		entity.buffList =entity.buffList or {}
		entity.buffList[buff.Id] = buff
	end
	function Buff.Remove(entity, buff)
		local buffId
		if type(buff)=="number" then
			buffId = buff
		else
			buffId = buff.Id
		end
		buff = entity.buffList[buffId]
		if buff then
			entity.buffList[buffId] = nil
			buff.OnRemove:Trigger(entity)
		else
			if entity:IsPlayer() then
				error("玩家".. entity.name.."的buff:"..buffId.."不存在")
			else
				error("怪物".. entity.index.."的buff:"..buffId.."不存在")
			end
		end
	end
	function Buff.Update(entity,time)
		for k,v in pairs(entity.buffList) do
			local buffId = k
			local buff = v
			buff.OnUpdate:Trigger(entity)
		end
	end
	function Buff.UpdateRegister(entity)
		if entity:IsMonster() then
			entity = entity:ToMonster()
		else
			entity = entity:ToPlayer()
		end
		entity.OnUpdate:Register(entity.BuffUpdate,REGISTER_MODE.only)
	end
	monsterFunc.AddBuff=function(m,buff)
		Buff.Add(m,buff)
		Buff.UpdateRegister(m)
	end
	monsterFunc.BuffUpdate=function(monster,time)
		Buff.Update(monster,time)
	end
	monsterFunc.RemoveBuff=function(m,buff)
		Buff.Remove(m,buff)
	end
	monsterAttrRead.buffList =function(m)
		local m=MonstersAliveList[m.index]
		if m then
			return m.buffList or {}
		end
	end
	monsterAttrWrite.buffList=function(m,v)
		MonstersAliveList[m.index].buffList = v
	end
	playerFunc.AddBuff=function(p,buff)
		Buff.Add(p,buff)
		Buff.UpdateRegister(p)
	end
	playerFunc.RemoveBuff= function(p,buff)
		Buff.Remove(p,buff)
	end
	playerFunc.BuffUpdate=function(entity,time)
		Buff.Update(entity,time)
	end
	playerAttrRead.buffList =function(p)
		local p = pus[p.name]
		if p then
			return p.buffList or {}
		end
	end
	playerAttrWrite.buffList =function(p,v)
		local p = pus[p.name]
		p.buffList = v
	end

	Framework.GamePlug.OnMonsterKilled:Register(function(m,k)
		if m and m.buffList then
			for k,v in pairs(m.buffList) do
				local buffId = k
				local buff = v
				buff.OnRemove:Trigger(m)
			end
		end
	end)
end
--Event , EventEnd
function Framework.GetSignalPlusArgs(msg,pattern,outArgs)
	if string.find(msg,pattern) then
		local s,e=string.find(msg,pattern)
		if s~=1 then return end
		if e-s+1~=#pattern then return end
		local args,_ = string.gsub(msg,pattern,"")
		outArgs.numArgs=splitstr_tonumber(args)
		outArgs.strArgs=splitstr_tostring(args)
		return true
	end
end
--2024/10/14新增简单的调试系统
DebugMode = true
if DebugMode==true then
	if UI then
		Framework.UIPlug.OnChat:Register(function(msg)
			local k,v=string.match(msg,"(%a+)丨(.+)")
			if k and v  then
				UI.SignalPlus("Debug"..k..","..v)
			end
		end)
	end
	if Game then
		Framework.GamePlug.OnPlayerSignalPlus:Register(function(player,msg)
			local outArgs={}
			if Framework.GetSignalPlusArgs(msg,"Debug",outArgs) then
				local key = outArgs.strArgs[1]
				local value = outArgs.strArgs[2]
				_G[key] = value
			end
		end)
	end
end
