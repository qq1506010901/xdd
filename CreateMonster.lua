--==================CreateMonster.lua========================
--脚本编写CSOL（网一）巴机斯坦
--巴机斯坦的缔造群:709527645
--2021/6/20
--=======================================================

--具备波次的僵尸召唤
--如有Bug找群主反馈

MonsterSet=
{
[1]={	
		kind=Game.MONSTERTYPE.NORMAL0,--怪物种类
		health=100,			--血量
		speed=1,			--速度
		damage=50,			--伤害
		coin=100,			--掉落金钱
		applyKnockback=true,--是否可以被击退，是填写true，否填写false
		canJump=true,		--是否可以跳跃
		checkAngle=360,		--锁敌角度
		viewDistance=1000,	--锁敌距离
		SetRenderFX=true,	--是否具备光泽
		SetRenderColor={r=255,g=0,b=0},--颜色
	},
[2]={	
	kind=Game.MONSTERTYPE.NORMAL1,health=100,speed=1,damage=1,coin=1,applyKnockback=true,canJump=true,checkAngle=360,viewDistance=1000,SetRenderFX=true,SetRenderColor={r=255,g=0,b=0},
	},
}

--同一组所有怪物死亡，填写Group+groupid的红色控制方块开启
--填写例子：Group1
function CreateMonstersBody(victim,killer)
	if victim==nil then return end	
	if victim:IsMonster() then
		local monster=victim
		local groupid=monster.user.groupid
		if	groupid then
			monster.user.wave:Create(groupid)
			monsterGroupCnt[groupid] = monsterGroupCnt[groupid] - 1
			if monsterGroupCnt[groupid] <= 0 then
				monsterGroupCnt[groupid] = nil
				Game.SetTrigger("Group"..groupid,true)
			end
		end
	end
end

--如需整合请把“CreateMonstersBody(victim,killer)”放入你脚本的“Game.Rule:OnKilled(victim,killer)”中
Framework.GamePlug.OnKilled:Register(function(victim,killer)
	CreateMonstersBody(victim,killer)
end)

monsterGroupCnt = {}						--同一组怪物的数量
MonsterWave = {KindID,Cnt=0,Num=0,Pos={}}--存储波次的信息


function MonsterWave:new(o)
	o=o or {}
	setmetatable(o,self)
	self.__index=self
	return o
end

function MonsterWave:Set(KindID,Cnt,Num,Pos)
	self.Pos.x=Pos.x
	self.Pos.y=Pos.y
	self.Pos.z=Pos.z
	self.Num=Num
	self.Cnt=Cnt
	self.KindID=KindID
end

function MonsterWave:Create(groupid)
	local kind=MonsterSet[self.KindID].kind
	local monster
	self.Cnt=self.Cnt-1	
	if	self.Cnt>0 then
		for i=1,self.Num do 
			monster=SetMonster(Game.Monster:Create(kind,self.Pos),self.KindID)
			monster.user.groupid=groupid
			monster.user.wave=MonsterWave:new(o)		
			monster.user.wave:Set(self.KindID,self.Cnt,self.Num,self.Pos)
			if monsterGroupCnt[groupid] then
				monsterGroupCnt[groupid] = monsterGroupCnt[groupid] + 1
			else
				monsterGroupCnt[groupid] = 1;
			end
		end
	end

end
--[[
使用蓝色脚本调用方块召唤怪物
4个参数，index,num,groupid,[waveCnt],[waveNum]（编号，第一次刷新数量，组号，【波次】，【第一波之后的刷新数量】）
带括号为选填

例1：
脚本函数名填写：CreateMonsters
参数填写：1,2,1
效果：预设MonsterSet[1]的僵尸被召唤2只。当所有僵尸被击杀时，填写Group1的红色控制方块开启

例2：
脚本函数名填写：CreateMonsters
参数填写：1,2,2,1
效果：预设MonsterSet[1]的僵尸被召唤2只,每当有怪物死亡时重新召唤2只，效果持续1次。当所有僵尸被击杀时，填写Group2的红色控制方块开启

例3：
脚本函数名填写：CreateMonsters
参数填写：2,3,3,2,4
效果：预设MonsterSet[2]的僵尸被召唤3只,每当有怪物死亡时重新召唤4只，效果持续2次。当所有僵尸被击杀时，填写Group3的红色控制方块开启
--]]


function CreateMonsters(call,args)
	if call then
		local arg=splitstr_tonumber(args)
		local pos=Game.GetScriptCaller().position
		local kindIndex=arg[1]	--怪物设置种类id
		local num=arg[2]
		local groupid=arg[3]
		local waveCnt=arg[4]
		local waveNum=arg[5]
		local kind=MonsterSet[kindIndex].kind
		local Set={}
		local monster
		--没有设置波次怪物数量，使用召唤时的怪物数量
		if not  waveNum then waveNum=num end
		for i=1,num do 
			monster=SetMonster(Game.Monster:Create(kind,pos),kindIndex)
			monster.user.groupid=groupid
			monster.user.wave=MonsterWave:new(o)	
			monster.user.wave:Set(kindIndex,waveCnt,waveNum,pos)
			if monsterGroupCnt[groupid] then
				monsterGroupCnt[groupid] = monsterGroupCnt[groupid] + 1
			else
				monsterGroupCnt[groupid] = 1;
			end
		end

	end	
end

---
--设置怪物属性
--传入参数（怪物，设置编号）
--传出monster
function SetMonster(monster,index)
	if not monster then return end
	local Set={}
	Set=MonsterSet[index]
	
	monster.health=Set.health
	monster.speed=Set.speed
	monster.damage=Set.damage
	monster.coin=Set.coin
	monster.applyKnockback=Set.applyKnockback
	monster.canJump=Set.canJump
	monster.checkAngle=Set.checkAngle
	monster.viewDistance=Set.viewDistance
	if Set.SetRenderFX==true then
		monster:SetRenderFX(Game.RENDERFX.GLOWSHELL)
		monster:SetRenderColor(Set.SetRenderColor)
	end
	return monster
end

function splitstr_tonumber(inputstr)
	local t = {}
	for str in string.gmatch(inputstr, "([^,]*)") do
		table.insert(t, tonumber(str))
	end
	return t
end



Framework.GamePlug.OnTakeDamage:Register (function(v, k, d, wt, h,killerWeapon)
	print("PostFireWeapon2")
	local player=k:ToPlayer()
	if killerWeapon then
		print(killerWeapon.weaponid)
	end
end)