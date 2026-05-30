Common.UseWeaponInven (true)
if UI then
    Framework.UIPlug.OnSignalPlus:Register(function(msg)
        print(msg)
    end)
    Framework.KeyDown.E:Register(function()
        UI.SignalPlus("测试")
    end)
    Framework.KeyInput.E:Register(function()
        UI.SignalPlus("测试")
    end)
end
if Game then
    Framework.GamePlug.OnPlayerAttack:Register(function(p, k, d, wt, h,killerWeapon)
        print("护甲")
        print(p.armor)
        print("最大护甲")
        print(p.maxarmor)
    end)
    --Invoke(function()
    --    local p=Game.Player:Create(1)
    --    local m=Game.Monster:Create(1951,p.position)
    --    p.armor=1000
    --    myBuff = Buff:Create(123)
    --    myBuff2 = Buff:Create(456)
    --    myBuff.OnAdd:Register(function(entity)
    --        print("myBuff.OnAdd")
    --        --entity.health=1
    --    end)
    --    myBuff2.OnAdd:Register(function(entity)
    --        print("myBuff2.OnAdd")
    --    end)
    --    myBuff.OnUpdate:Register(function(entity)
    --        print("myBuff.OnUpdate")
    --        entity:ShowOverheadDamage(1,0)
    --    end)
    --    myBuff2.OnUpdate:Register(function(entity)
    --        print("myBuff2.OnUpdate")
    --        entity:ShowOverheadDamage(2,0)
    --    end)
    --    myBuff.OnRemove:Register(function(entity)
    --        print("myBuff.OnRemove")
    --        print(entity.name)
    --    end)
    --    myBuff2.OnRemove:Register(function(entity)
    --        print("myBuff2.OnRemove")
    --    end)
    --    Invoke(function(m)
    --        print("entity.RemoveBuff")
    --        m:RemoveBuff(123)
    --    end,3,p)
    --    Invoke(function(m)
    --        print("entity.RemoveBuff2")
    --        m:RemoveBuff(myBuff2)
    --    end,4,p)
    --    p:AddBuff(myBuff)
    --    p:AddBuff(myBuff2)
    --    m:AddBuff(myBuff)
    --    m:AddBuff(myBuff2)
    --    Invoke(function(m)
    --        print("entity.RemoveBuff")
    --        m:RemoveBuff(123)
    --    end,3,m)
    --    Invoke(function(m)
    --        print("entity.RemoveBuff2")
    --        m:RemoveBuff(myBuff2)
    --    end,4,m)
    --    --p:SignalPlus("测试")
    --    --TestTrigger=Framework.SphereTrigger:New(m,10)
    --    --TestTrigger.OnTriggerEnter:Register(function(entity)
    --    --    if entity:IsPlayer() then
    --    --        local player=entity:ToPlayer()
    --    --        print(player.name.."进入僵尸范围")
    --    --    end
    --    --end)
    --    --TestTrigger.OnTriggerExit:Register(function(entity)
    --    --    if entity:IsPlayer() then
    --    --        local player=entity:ToPlayer()
    --    --        print(player.name.."离开僵尸范围")
    --    --    end
    --    --end)
    --end,1)

    Framework.GamePlug.OnTakeDamage:Register(function(v, k, d, wt, h)
        if v:IsMonster() then
            v=v:ToMonster()
            --v.invincibility = true
        end
    end)
    Framework.GamePlug.OnPlayerAttack:Register(function(player, killer, d, wt, h)
        return 1
    end)

end


if Game then
    Game.Rule.respawnTime=0
    function Test(call)
        if call then
            local player=Game.GetTriggerEntity()
            if player:IsPlayer() then
                player=player:ToPlayer()
                player:SignalPlus("测试")
            end
        end
    end
    --Framework.GamePlug.OnPlayerJoiningSpawn:Register(function(player)
    --    local monster1=Game.Monster.Create(Framework.MonsterType.NORMAL0,{x=2,y=3,z=1})
    --    monster1.user.name="monster1"
    --
    --    local monster2=Game.Monster.Create(Framework.MonsterType.NORMAL0,player.position)
    --    monster2.user.name="monster2"
    --
    --    monster2:Stop(true)
    --    monster1:AttackTo(monster2)
    --end)
    --
    --Framework.GamePlug.OnMonsterTakeDamage:Register(function(victim,attacker)
    --    print(attacker.user.name.."正在攻击"..victim.user.name)
    --    return 1.1
    --end)
    --Framework.GamePlug.OnMonsterKilled:Register(function(victim,killer)
    --    if not killer then return end
    --    print(killer.user.name.."杀了"..victim.user.name)
    --end)

end
if Game then
    Framework.GamePlug.OnPlayerSignalPlus:Register(function(player,msg)
        if msg=="保存" then
            player.user.saveExample={
                ["宠物"]={1,0,2,3,4},
                ["技能"]={1,2,3,4},
                ["等级"]={10},
                ["字符串"]={"abc","def"},
                ["bool"]= { true,false,true },
                tab={
                    a={"2b","9s" },
                    b={1,2},
                    c={1,2,3},
                    d={e={1},f={g={h={i={"最里层",2,3}}}}}
                },
                numbers={
                    a={1,2},
                    b={3,4},
                    c={5,6}
                },
                number={1},
                level={"10"},
            }
            player:SetTableSave("example",player.user.saveExample)
        end
        if msg=="读取" then
            player.user.saveExample=player:GetTableSave("example")
            print(player.user.saveExample.tab.d.f.g.h.i[1])
        end
    end)
end
if UI then
    Framework.UIPlug.OnChat:Register(function(msg)
        if msg=="保存" then
            UI.SignalPlus(msg)
        end
        if msg=="读取" then
            UI.SignalPlus(msg)
        end
    end)
end
