

</font>




<hr style=" border:solid; width:100px; height:1px;" color=#000000 size=1">


# 前言

<font color=#999AAA >CSOL缔造者LUA的脚本多种多样。但是往往地图作者不会使用LUA，而LUA的编写者又不会做地图。或者当你需要移植其他作者的脚本却无从下手。为了建立起作者与脚本编写者的桥梁，为了能够让脚本能够模块化，更高的移植性，能够让不会编写LUA的作者们也能够轻易的使用，扩展，移植别人的插件，MaiMaiFramework诞生了</font>

<hr style=" border:solid; width:100px; height:1px;" color=#000000 size=1">

<font color=#999AAA >注意：这个LUA框架只能在CSOL缔造者游戏模式环境下使用
# 一、MaiMaiFramework是什么？


<font color=#999AAA >MaiMaiFramework是基于事件的隐式调用的CSOL缔造者框架。为了能够让不会LUA的作者也能够快速掌握使用、扩展、移植其他LUA脚本编写者的脚本。为了实现这一目标，脚本编写者必须按照一定的规则来编写脚本。这些脚本将作为插件通过注册的方式静态或者动态的载入到框架中。



# 二、插件使用者看这里
</font></font>


## 1.下载MaiMaiFramework.lua

下载main分支的MaiMaiFramework.lua[就是这个文件](https://gitee.com/UmaruIsBoy/MaiMaiFramework.lua/blob/main/MaiMaiFramework.lua).

## 2.更改project.json内容
```c
{
    "game": ["MaiMaiFramework.lua"], 
    "ui": ["MaiMaiFramework.lua"]
}
```
<font color=#999AAA >现在还没有插件，如果有，就像这样添加新的插件</font>
```c
{
    "game": ["MaiMaiFramework.lua", "ExamplePlug.lua"], 
    "ui": ["MaiMaiFramework.lua", "ExamplePlug.lua"]
}
```
<hr style=" border:solid; width:100px; height:1px;" color=#000000 size=1">
</font></font>

</font></font>

# 三、插件开发者看这里
</font></font>

## 1.新建一个插件
<font color=#999AAA >一般插件会同时写在Game和UI文件中，新建AddHealthPlug.lua放在工程目录下</font>

## 2.编写插件和注册方法

```lua

--编写插件
if Game then
    function MyGameFunc(player,msg)
        if string.find(msg,"增加生命值") then
            local value=string.gsub(msg,"增加生命值","")
            player.health=player.health+tonumber(value)
        end
    end
end
if UI then
    function MyUIFunc(msg)
        UI.SignalPlus(msg)
    end
end
--注册方法到框架中
if Game then
    Framework.GamePlug.OnPlayerSignalPlus:Register(MyGameFunc)
end
if UI then
    Framework.UIPlug.OnChat:Register(MyUIFunc)
end
```
<font color=#999AAA >聊天框输入增加生命值100，输入消息的玩家生命值增加100</font>
## 3.在json中添加插件
<font color=#999AAA >[下载MaiMaiFramework.lua](https://gitee.com/UmaruIsBoy/MaiMaiFramework.lua/releases)并且添加你的插件</font>
```c
{
    "game": ["MaiMaiFramework.lua", "AddHealthPlug.lua"], 
    "ui": ["MaiMaiFramework.lua", "AddHealthPlug.lua"]
}
```
<font color=#999AAA >在CSOL缔造者游戏模式中测试脚本查看效果</font>
# 四、开发文档
## 1、注册方法
<font color=#999AAA >例：服务端插件注册</font>

```lua
Framework.GamePlug.OnUpdate:Register()
Framework.GamePlug.OnUpdate:UnRegister()
```
<font color=#999AAA >例：客户端插件注册</font>
```lua
Framework.UIPlug.OnUpdate:Register()
Framework.UIPlug.OnUpdate:UnRegister()
```


</font></font>

</font></font>

<font color=#999AAA >服务端（Game）中能够注册的方法</font>   
 		
        OnKilled
        OnRoundStart
        OnRoundStartFinished
        OnPlayerJoiningSpawn
        OnPlayerSignal
        OnTakeDamage
        OnPlayerKilled
        OnPlayerSpawn
        OnPlayerConnect
        OnPlayerDisconnect
        OnGetWeapon
        OnGameSave
        OnLoadGameSave
        OnClearGameSave
        OnReload
        OnReloadFinished
        OnSwitchWeapon
        PostFireWeapon
        CanBuyWeapon
        CanHaveWeaponInHand
        OnUpdate
        OnPlayerUpdate
        OnPlayerLaterUpdate
        OnPlayerSignalPlus
        



<font color=#999AAA >客户端（UI）中能够注册的方法</font>    

        OnRoundStart
        OnSpawn
        OnKilled
        OnChat
        OnInput
        OnKeyDown
        OnKeyUp
        OnSignal
        OnKeyDown
        OnUpdate
        OnLaterUpdate
        OnSignalPlus

        
## 2、参数说明
</font></font>
### 1）官方方法
<font color=#999AAA >官方方法注册的方法参数看：[官方文档](https://tw.beanfun.com/cso/STUDIO/api/index.html)（已失效）  
</font>  
<font color=#999AAA>注册到官方客户端（UI）方法示例</font>				 
```lua
--注册匿名方法
Framework.UIPlug.OnUpdate:Register(
	function(t)
		print("在UI中每帧执行")
	end
)
--注册普通方法
function MyOnKeyDown(inputs)	
	if inputs[UI.KEY.A]==true then
		print("a key is pressed!")
	end
end
Framework.UIPlug.OnKeyDown:Register(MyOnKeyDown)

						 
```

### 2）部分扩展方法示例
<font color=#999AAA>服务端（Game）扩展方法</font>
				
      OnLaterUpdate

**OnLaterUpdate（time）**
<font color=#999AAA>会在OnUpdate的下一帧执行</font>
```lua
function MyOnLaterUpdate(time)

end
--注册你的方法
Framework.GamePlug.OnLaterUpdate:Register(MyOnLaterUpdate)
```

### 3）详细文档						 
[跳转](https://gitee.com/UmaruIsBoy/MaiMaiFramework.lua/wikis/Home)			 
# 五、交流群
**MaiMaiFramework框架/插件开发群691763332**
# 六、已知问题
同一个游戏lua脚本中player:Signal()和player:SignalPlus()不能混用
```lua
Framework.GamePlug.OnPlayerSignalPlus:Register(function(player,msg)
end)
```
和
```lua
Framework.GamePlug.OnPlayerSignal:Register(function(player,msg)
end)
```
不能混用
```lua
Framework.UIPlug.OnSignal:Register(function(signal)
end)
```
和
```lua
Framework.UIPlug.OnSignalPlus:Register(function(signal)
end)
```
不能混用

# Draw的文档

## 介绍
独立的绘制文字和图片的插件,用于在屏幕上绘制图片和文字

[下载文字图片生成器](https://gitee.com/UmaruIsBoy/MaiMaiFramework.lua/raw/dev_maimaiPlug/%E7%BB%98%E5%88%B6%E6%96%87%E5%AD%97%E5%92%8C%E5%9B%BE%E7%89%87/%E6%96%87%E5%AD%97%E5%9B%BE%E7%89%87%E7%94%9F%E6%88%90%E5%99%A8.msi)  

[文字图片生成器安装使用教程](https://gitee.com/UmaruIsBoy/MaiMaiFramework.lua/blob/dev_maimaiPlug/%E7%BB%98%E5%88%B6%E6%96%87%E5%AD%97%E5%92%8C%E5%9B%BE%E7%89%87/%E6%95%99%E7%A8%8B.md)  
[压缩字形的工具](https://gitee.com/UmaruIsBoy/MaiMaiFramework.lua/releases/download/v0.7.5/PackedFont.zip)  
如果你不想下载这里有线上的生成器  
[国外网页版生成器](http://104.168.157.239:61810/DrawCreater)    
[国内网页版生成器](http://8.138.151.215:61810/DrawCreater)  


## 一、添加引用，底下两种配置二选一

### 1·无需框架的绘制，部分功能无法使用
把Draw.lua放到project.json同文件夹下
```lua
    {
        "game": [], 
        "ui": ["Draw.lua"]
    }
```
### 2·框架版的绘制，完整功能  
把Draw.lua和MaiMaiFramework.lua放到project.json同文件夹下  
需要下载  
[Draw.lua](https://gitee.com/UmaruIsBoy/MaiMaiFramework.lua/blob/main/Draw.lua)最新版本和[MaiMaiFramework.lua](https://gitee.com/UmaruIsBoy/MaiMaiFramework.lua/blob/main/MaiMaiFramework.lua)最新版本
```lua
    {
        "game": ["MaiMaiFramework.lua"], 
        "ui": ["MaiMaiFramework.lua","Draw.lua"]
    }
```

## 二、创建你的ui文件
在project.json同文件夹下右键，新建文本文档  
更改命名为ui.lua  
## 添加ui.lua引用，底下两种配置二选一 
### 1·不使用框架
```lua
    {
        "game": [], 
        "ui": ["Draw.lua","ui.lua"]
    }
```
### 2·使用框架
```lua
    {
        "game": ["MaiMaiFramework.lua"], 
        "ui": ["MaiMaiFramework.lua","Draw.lua","ui.lua"]
    }
```

## 三、根据你实际情况的配置

比如1280*800是你在创作模式下的游戏设置里的屏幕分辨率  
则在Draw.lua中修改MVC的值为  
```lua
    MVC={
        width=1280,
        height=800
    }
```

## 四、复制下面的代码到ui.lua

Draw.Texts里面放文字的数据，数据是[生成器](https://gitee.com/UmaruIsBoy/MaiMaiFramework.lua/raw/dev_maimaiPlug/%E7%BB%98%E5%88%B6%E6%96%87%E5%AD%97%E5%92%8C%E5%9B%BE%E7%89%87/%E6%96%87%E5%AD%97%E5%9B%BE%E7%89%87%E7%94%9F%E6%88%90%E5%99%A8.msi)生成的  
Draw.TextsBase91里面放文字压缩后的数据，数据是[生成器](https://gitee.com/UmaruIsBoy/MaiMaiFramework.lua/raw/dev_maimaiPlug/%E7%BB%98%E5%88%B6%E6%96%87%E5%AD%97%E5%92%8C%E5%9B%BE%E7%89%87/%E6%96%87%E5%AD%97%E5%9B%BE%E7%89%87%E7%94%9F%E6%88%90%E5%99%A8.msi)生成后[压缩字形的工具](https://gitee.com/UmaruIsBoy/MaiMaiFramework.lua/releases/download/v0.7.5/PackedFont.zip)压缩的  
```lua
--存放文字数据
Draw.Texts={
    ['测']={{0,1,1,1,0,5,1,1,0,10,1,1,1,2,2,1,1,6,2,1,1,9,1,1,2,1,5,1,2,3,1,6,2,11,1,1,3,10,1,1,4,3,1,7,5,10,1,1,6,2,1,7,6,11,1,1,8,2,1,7,9,11,2,1,10,0,1,12},{11,12,17}},
    ['试']={{0,0,1,1,0,4,2,1,1,1,1,1,1,5,1,7,2,10,1,1,4,2,7,1,4,5,3,1,4,10,2,1,5,6,1,5,6,9,1,1,8,0,1,10,9,10,2,1,10,0,1,1,10,9,1,3},{11,12,14}},
    --字不存在时会用空格代替，11代表空格的宽，12代表空格的高
    [' ']={{},{11,12,0}},
}

--存放压缩后的文字数据
Draw.TextsBase91={
    ['欢'] = 'C<7FDDUE%ABN%F"CpB:"?(fLjLpBzw?(8M!W]C#F<tZ*nL$4>CO"Gu9MznfL?J+t;C$WbX>CYO("/Lg4bDtP3PA',
    ['迎'] = 'X|vWFtm"FYAMlHi<>ayi,nJx{WH,*nxw5uyc.ORgjB',
    ['杀'] = 'Bf,hbDGO&tmunLmG9FlBmB]W,L%F0InBquj"UMKOtBCy>W"i/FgA%A!M&y"C!M:twwpLs).A',
    ['敌'] = 'Yq7F{C5F*At5IA1B+"~LnL_QGAj"eGWOvBVE@W:i&FcA<vbYr?uGyWaE7y]W2uUcwcnB>0?([jCA',
}
--创建文字框架
myText=DrawText:Create()
--设置显示的文字为text为"测试欢迎杀敌",屏幕位置在x=500，y=800处，大小为2
myText:Set({text="测试欢迎杀敌",x=500,y=500,size=2})

```

## 以下是文档

```lua
    --存放文字数据
    Draw.Pictures={}  
    --存放图片数据
    Draw.Texts={}  
```

## Draw.SetArg类
```lua
Draw.SetArg=
    {
        text=nil, --optional string 在畫線顯示的文字
        font="medium",--optional string 字體大小 (small, medium, large, verylarge)
        x=0, --optional int x 座標
        y=0, --optional int y 座標
    
        r=255, --optional int 文字顏色(紅色). 0~255 範圍
        g=255, --optional int 文字顏色(綠色). 0~255 範圍
        b=255, --optional int 文字顏色(藍色). 0~255 範圍
        a=255, --optional int 文字顏色(透明度). 0~255 範圍

        --首次调用Set方法时内部自动赋值
        width=-1, --optional int 寬度
        height=-1, --optional int 高度  
        needBox=-1,   --需要的UI.Box数目
    }
```
## Draw类


### Draw:Create()
產生静态文字介面框架  

### Draw:Set(Draw.SetArg)
设置静态文字的属性

### Draw:Hide()
隐藏静态文字

### Draw:Show()
显示静态文字

### Draw:Adaptation([mode])  
根据Draw.lua中的MVC对屏幕进行适配 
 
开发模式下的屏幕分辨率
```lua
MVC={
    width=1280,
    height=800
}
```
[mode]  
文字的宽度和高度会随着分辨率的改变适配  
"center"        x向左移动width的1/2,y向上移动height的1/2  
"downLeft"      y向上移动height  
"upRight"       x向右移动width   
"upCenter"      x向右移动width的1/2  
"downCenter"    x向左移动width的1/2,y向上移动height    
"downRight"     x向左移动width,y向上移动height  

"widthHeight"   不改变位置，只适配宽高  

缺省mode：适配宽高和位置  




### Draw:Get()  
获取静态文字属性
返回Draw.SetArg

## DrawText类
继承Draw类所有方法


### DrawText:Create()
產生动态文字介面框架  

### DrawText:Set(DrawText.SetArg)
设置动态文字属性

### DrawText:DisPlayMode(mode)  
改变文字显示方向  
```lua
    "vertical" --从上往下显示
```

### DrawText:GetChildText(index)  
获得第index个文字信息  
返回Draw类  

### DrawText:Get()  
获得动态文字属性  
返回DrawText.SetArg  


## DrawText.SetArg类  
继承Draw.SetArg类  
```lua
DrawText.SetArg=
    {
        kerning, --number字间距
        text=nil, --optional string 在畫線顯示的文字
        font="medium",--optional string 字體大小 (small, medium, large, verylarge)
        x=0, --optional int x 座標
        y=0, --optional int y 座標
    
        r=255, --optional int 文字顏色(紅色). 0~255 範圍
        g=255, --optional int 文字顏色(綠色). 0~255 範圍
        b=255, --optional int 文字顏色(藍色). 0~255 範圍
        a=255, --optional int 文字顏色(透明度). 0~255 範圍
    
        --首次调用Set方法时内部自动赋值
        width=-1, --optional int 寬度
        height=-1, --optional int 高度  
        needBox=-1,   --需要的UI.Box数目
    }
```

## DrawPicture类
继承Draw类所有方法

### DrawPicture:Create()
產生图片的框架 

### DrawPicture:Set(DrawPicture.SetArg)
设置图片属性

### DrawPicture:Get()
获取图片属性
返回DrawPicture.SetArg

## DrawPicture.SetArg类
继承Draw.SetArg类
```lua
    DrawPicture.SetArg={
        picture=nil,    --图片名字 string
        size=1,        --图片大小 number
        x=0, --optional int x 座標
        y=0, --optional int y 座標
    
        --首次调用Set方法时内部自动赋值
        width=-1, --optional int 寬度
        height=-1, --optional int 高度  
        needBox=-1,   --需要的UI.Box数目
    }
```

##  DrawLine类
继承Draw类所有方法

### DrawLine:Create()
产生直线的框架（不会进行box拼接，因此可能会消耗大量的box）

### DrawLine:Set(DrawLine.SetArg)
设置直线属性

### DrawLine:Get()
获取直线属性
返回DrawLine.SetArg

## DrawLine.SetArg类
```lua
    DrawLine.SetArg={
        size=3,--size越小越清晰，消耗box越多
        r=255,
        g=255,
        b=255,
        a=255,
    
        pos1={} --起点
        pos2={} --始点
        --首次调用Set方法时内部自动赋值
        width=-1,
        height=-1,
        --最左侧，最上侧的坐标
        x=nil,
        y=nil
      
    }
```

## DrawPolygon类
继承Draw类所有方法

### DrawPolygon:Create()
产生多边形的框架（不会进行box拼接，因此可能会消耗大量的box）

### DrawPolygon:Set(DrawPolygon.SetArg)
设置多边形属性

### DrawPolygon:Get()
获取多边形属性
返回DrawPolygon.SetArg

## DrawPolygon.SetArg类
```lua
    DrawPolygon.SetArg ={
        n=4,    --顶点数
        radius=10,    --到顶点的距离
        center={x=0,y=0}, --中心坐标
        size=10,        --size越小越清晰，消耗box越多
        r=255,g=255,b=255,a=255,
        --首次调用Set方法时内部自动赋值
        width=nil,
        height=nil,
        --最左侧，最上侧的坐标
        x=nil,
        y=nil,
    }
```


## 例子

```lua
if UI then
    Draw.Pictures={
       ["马里奥"]={{{{236,62,1},{0,12,5,2,1,11,4,3,2,2,13,1,2,10,3,4,2,14,1,1,3,0,7,3,5,14,1,1,6,10,3,2,9,10,1,1,9,14,1,1,10,11,4,3,12,14,1,1,14,12,2,2}}, {{248,195,125},{0,14,2,4,2,4,1,3,2,15,1,2,3,7,6,3,3,14,2,1,5,4,4,1,6,3,3,7,9,5,1,2,9,8,4,2,10,3,2,2,10,14,2,1,12,4,3,3,12,15,4,2,13,14,3,4,15,5,1,2}}, {{115,53,42},{0,21,5,1,1,4,1,4,1,19,4,3,2,3,4,1,2,7,1,1,3,4,2,3,5,5,1,2,9,7,6,1,10,5,2,3,10,19,5,3,15,21,1,1}}, {{30,56,133},{2,17,11,2,3,15,9,4,5,10,1,4,6,12,3,7,9,11,1,3}}, {{16,17,21},{9,3,1,2}}},{16,22,45}},
    }
    Draw.Texts=
    {
        ['嗨']={{0,2,3,1,0,3,1,7,1,8,2,1,2,3,1,7,3,1,1,1,3,5,1,1,3,10,1,1,4,2,1,1,4,6,7,1,4,9,7,1,5,0,1,2,5,3,5,1,5,4,1,6,6,1,5,1,7,5,1,2,7,8,1,2,7,11,2,1,9,4,1,7},{11,12,18}},
        [' ']={{},{5,13,0}},
    }

    myPicture=DrawPicture:Create()    --创建一个產生图片的框架myPicture

    myPicture:Set({x=640,y=400,picture="马里奥",size=5})    --设置myPicture的属性，屏幕坐标x=640,800,(屏幕左上角坐标为x=0，y=0)，picture图片:马里奥，大小size:5(如果不是整数倍放大/缩小可能会出现问题)

    myPicture:Adaptation("center")    --图片的适配模式：居中(将图片向左移动 图片宽的1/2，向上移动图片高的1/2)

    myText=DrawText:Create()          --创建一个產生文字的框架myText
    myText:Set({x=640,y=400,text="嗨嗨           嗨嗨",font="small"})    --设置文字的屏幕坐标x=640,y=400,text文字:"嗨嗨           嗨嗨"，文字尺寸font:"small",除此之外还有small, medium, large, verylarge
    myText:Adaptation("center")    --适配模式：居中

    myUIBox=UI.Box.Create()        --创建绘制矩形的UI框架myUIBox
    myUIBox:Set(myPicture:Get())    --将myUIBox的属性设置为myPicture的属性
    myUIBox:Set({a=100})            --调整myUIBox的透明度：a=100
end


```
[效果](https://gitee.com/UmaruIsBoy/MaiMaiFramework.lua/blob/dev_maimaiPlug/%E7%BB%98%E5%88%B6%E6%96%87%E5%AD%97%E5%92%8C%E5%9B%BE%E7%89%87/%E6%95%88%E6%9E%9C.png)

## 以下方法只有在使用[MaiMaiFramework](https://gitee.com/UmaruIsBoy/MaiMaiFramework.lua/releases)的情况下才能使用（用最新的版本）

```lua
    DoMove.type=
    {
        OutQuad,     --default
        InQuad,
        InSine,
        OutSine,
        InCubic,
        OutCubic,
        InExpo,
        OutExpo,
        Linear,
    }
```
### DoMove
平滑的从屏幕一处移动到另一处

startPos  table {x=x,y=y}开始的屏幕坐标  
endPos  table {x=x,y=y}结束的屏幕坐标  
time  number 移动花费的时间  
[type]  DoMove.type  string 移动的类型  

Draw:DoMove(startPos,endPos,time,type)  
DrawText:DoMove(startPos,endPos,time,type)  
DrawPicture:DoMove(startPos,endPos,time,type)  
DrawPolygon:DoMove(startPos,endPos,time,type)  
DrawLine:DoMove(startPos,endPos,time,type)  


### DoColor
startColor  table  {r=r,g=g,b=b}开始时的颜色  
endColor  table  {r=r,g=g,b=b}结束时的颜色  
time  number  变化颜色花费的时间  
[type] DoMove.type  string  移动的类型  

Draw:DoColor(startColor,endColor,time,type)  
DrawText:DoColor(startColor,endColor,time,type)  

### DoScale
startSize  table {width=width,height=height}开始时的大小  
endSize  table {width=width,height=height}结束时的大小  
time  number 变化大小花费的时间  
[type]  DoMove.type  string 移动的类型  
Draw:DoScale(startSize,endSize,time,type)  
DrawText:DoScale(startSize,endSize,time,type)  
DrawPicture:DoScale(startSize,endSize,time,type)  

### UI.Text/UI.Box 扩展  

```lua
UI.Text:OnDoMoveStart()
UI.Text:OnDoMoveEnd()
UI.Text:OnDoColorStart()
UI.Text:OnDoColorEnd()

UI.Box:OnDoMoveStart()
UI.Box:OnDoMoveEnd()
UI.Box:OnDoColorStart()
UI.Box:OnDoColorEnd()
UI.Box:OnDoScaleStart()
UI.Box:OnDoScaleEnd()
```
### Do事件  
DrawEntity包括Draw,DrawText,DrawPicture,DrawLine,DrawPolygon  

 **DoMove**  
DoMove开始时触发  
```lua
DrawEntity.OnDoMoveStart:Register(function()
 
end)  
```
DoMove结束时触发  
```lua
DrawEntity.OnDoMoveEnd:Register(function()
   
end)  
```
DoMove时触发  
```lua
DrawEntity.OnDoMove:Register(function()
 
end)  
```

 **DoScale**  
DoScale开始时触发  
```lua
DrawEntity.OnDoScaleStart:Register(function()
 
end)  
```
DoScale结束时触发  
```lua
DrawEntity.OnDoScaleEnd:Register(function()
   
end)  
```
DoScale时触发  
```lua
DrawEntity.OnDoScale:Register(function()
 
end)  
```




### DrawText:BlinkShow

每个文字分开显示

time 每个字之间显示的间隔  

DrawText:BlinkShow(time)  


## Draw.MenuStrip类  
### Draw.MenuStrip:Create(args)  
产生菜单的框架
args    table参数表
参数：  
args.x  产生菜单的屏幕位置  
args.y  
[args.itemsHeight] 每个子菜单的高，默认30
[args.itemsWidth] 每个子菜单宽，默认100
[args.size] 文字显示大小,默认1

### Draw.MenuStrip:SetBGColor(r,g,b,a)  
设置背景颜色  

### Draw.MenuStrip:SetFocusBGColor(r,g,b,a)  
设置光标背景颜色  

### Draw.MenuStrip:SetTextColor(r,g,b)  
设置文字颜色  

### Draw.MenuStrip:Add(name)  
添加一个选项  
参数:  
name    string类型，添加选项的名字  

### Draw.MenuStrip:Remove(itemIndex)  
删除第（从上往下数）itemIndex选项
参数:
itemIndex number类型，第几个选项  

### Draw.MenuStrip:OnFocus(itemIndex)  
光标移动到菜单的第（从上往下数）itemIndex个选项  

参数:  
itemIndex   number类型，第几个选项  

### Draw.MenuStrip:CreateChild(itemIndex)  
在第（从上往下数）itemIndex个选项下创建子菜单  
参数:  
itemIndex   number类型，第几个选项  
返回:  
Draw.MenuStrip  

### Draw.MenuStrip:Show()
显示菜单  

### Draw.MenuStrip:OnlyShowOnFocus(boolean)  
是否只在光标处显示文字（用于长菜单节省box用）   
参数:  
boolean  boolean类型,true是,false否  

### Draw.MenuStrip:Hide()  
隐藏菜单包括他的子菜单  

### Draw.MenuStrip:Dispose()  
释放资源  
删除所有选项,包括子菜单,以及菜单子菜单数据，根节点需要手动删除 


### 注册方法
左键选择时调用  
参数:  
menu    Draw.MenuStrip  
focusIndex 当前选项编号（1开始从上往下增加）  
```lua
Draw.MenuStrip.OnSelect:Register(function(menu,focusIndex)  

end)
```

焦点改变时调用  
参数:  
menu    Draw.MenuStrip  
focusIndex 当前选项编号（1开始从上往下增加）  
```lua
 Draw.MenuStrip.OnFocusEvent:Register(function(menu,index)
   
end)
```

### Draw.MenuStrip例子:创建
```lua
    MainMenu=Draw.MenuStrip:Create({x=300,y=100,size=2,itemsHeight=30,itemsWidth=400})    --创建主菜单到屏幕x=300,y=300位置
                                                                                          --size文字大小2,[itemsHeight]每个子菜单高
                                                                                          --[itemsWidth]每个子菜单宽
    MainMenu:SetBGColor(255,0,0,255)                 --设置主菜单背景颜色
    MainMenu:SetFocusBGColor(0,255,0,255)            --设置主菜单光标颜色
    MainMenu:SetTextColor(0,0,255)                   --设置主菜单文字颜色
    MainMenu:Add("主菜单")                            --添加选项："主菜单"
    MainMenu:Add("主菜单1")                           --添加选项："主菜单1"
    MainMenu:Add("主菜单2")                           --添加选项："主菜单2"
    MainMenu:Add("主菜单3")                           --添加选项："主菜单3"
    MainMenu:Add("主菜单4")                           --添加选项："主菜单4"
    ChildMenu=MainMenu:CreateChild(3)                 --在主菜单3的位置添加子菜单
    ChildMenu:Add("子1菜单1")                          --添加子菜单选项:"子1菜单1"
    ChildMenu:Add("子1菜单3")                          --添加子菜单选项:"子1菜单3"
    ChildMenu:Add("子1菜单4")                          --添加子菜单选项:"子1菜单4"
    ChildMenu:Add("子1菜单2",2)                        --添加子菜单选项:"子1菜单2"到子菜单2号位置
    Child2Menu=ChildMenu:CreateChild(4)                --在子菜单3的位置添加子菜单的子菜单
    Child2Menu:Add("子2菜单1")
    Child2Menu:Add("子2菜单2")
    Child3Menu=Child2Menu:CreateChild(2)
    Child3Menu:Add("子3菜单1")
    Child3Menu:Add("子3菜单2")
    Child4Menu=Child3Menu:CreateChild(2)
    Child4Menu:Add("子4菜单1")
    Child4Menu:Add("子4菜单2")

    MainMenu:OnFocus(1)                                --设置主菜单光标到1号位置
    MainMenu:Show()                                    --显示主菜单
    
    --子菜单4被点击事件注册
    Child4Menu.OnSelect:Register(function(menu,focusIndex)
        print("子4菜单"..focusIndex.."被点击")
        if focusIndex==1 then
            MainMenu:Hide()
        end
    end)
    Child4Menu.OnFocusEvent:Register(function(menu,index)
       
    end)
```
### Draw.MenuStrip例子:隐藏
续上
```lua
    --隐藏菜单和他的子菜单，数据会被保留，以供下次打开
    --不会占用box
    MainMenu:Hide() 
```

### Draw.MenuStrip例子:释放
续上
```lua
    --如果要永久废弃掉这个菜单采用这个方法
    --否则可以使用Hide进行隐藏
    MainMenu:Dispose()    --释放菜单所有资源,包括子菜单以及他的数据,最顶级菜单需要手动删除 
    MainMenu=nil          --删除最顶级菜单的引用
    collectgarbage()      --垃圾回收
```



## 例子

```lua
    Draw.Pictures['picture']={{{{0,0,0},{0,6,1,1,0,8,1,1,0,10,1,1,1,0,1,1,1,3,1,2,1,14,1,1,1,16,1,1,2,1,1,1,2,17,1,1,5,0,1,1,5,23,1,1,6,2,1,1,6,32,1,1,7,28,1,2,8,5,1,1,8,34,2,1,9,6,1,1,11,35,1,1,12,36,1,1,13,9,1,1,14,37,2,1,15,12,1,1,16,13,1,1,16,36,2,1,18,14,1,1,18,37,1,1,19,15,1,1,20,30,1,4,21,18,1,1,21,34,1,1,21,36,3,1,21,38,1,2,22,19,1,1,22,30,1,1,22,41,1,1,23,27,1,3,23,34,1,3,24,26,1,1,24,29,1,2,24,32,1,1,24,38,1,2,24,41,1,1,25,21,1,1,25,30,1,1,26,23,1,2,26,27,3,1,26,31,1,2,27,26,1,3}},{{0,0,255},{0,7,1,1,0,9,1,1,1,6,1,1,1,10,1,4,2,14,1,3,3,18,2,1,4,19,1,2,5,21,1,2,6,23,1,3,7,24,1,1,7,27,1,1,7,30,2,1,7,31,1,4,8,29,1,2,9,18,3,2,10,15,1,1,11,23,2,2,12,20,1,7,12,35,1,1,13,22,1,1,13,25,1,2,13,28,1,1,14,26,1,1,14,29,1,2,15,27,1,2,15,30,1,1,15,34,1,1,16,19,1,1,16,23,1,1,16,29,1,1,16,32,1,2,16,37,1,1,18,27,1,1,19,28,1,1,19,31,1,1,19,35,1,2,20,25,1,2,20,36,1,1,21,26,1,1,22,35,1,1,23,25,1,1,23,31,1,2,23,39,1,1,27,29,1,1}},{{0,255,255},{1,5,4,1,2,2,1,6,2,11,8,1,3,3,1,10,3,17,1,1,4,6,1,9,5,7,1,10,5,20,1,1,6,8,1,10,6,26,2,1,7,9,1,12,7,25,1,2,8,10,1,12,8,27,1,2,8,31,4,1,8,32,3,1,8,33,2,1,9,12,1,6,9,20,3,3,9,28,2,1,9,29,1,5,10,13,2,2,10,16,4,1,10,17,3,1,10,23,1,3,10,34,5,1,11,15,2,3,11,25,1,2,12,18,1,2,12,27,3,1,12,28,1,3,13,19,1,3,13,23,3,1,13,24,2,1,13,29,1,3,14,22,2,2,14,25,2,1,14,28,1,1,14,31,4,1,14,32,2,2,14,35,1,1,15,18,1,1,15,21,1,3,15,26,2,1,15,29,1,1,15,36,1,1,16,27,2,1,16,30,1,2,16,34,3,1,17,32,1,4,18,28,1,1,18,33,1,4,19,37,1,2,20,22,1,1,20,29,1,1,21,27,1,1,22,31,1,1,22,38,2,1,22,39,1,2,23,37,1,2,23,40,1,2,26,28,1,1}},{{255,255,255},{1,7,1,3,2,8,1,3,2,12,1,2,3,2,1,1,3,13,1,4,4,3,1,2,4,15,1,3,5,6,1,1,5,17,1,3,6,7,1,1,6,18,1,5,7,21,1,3,8,9,1,1,8,22,1,5,9,10,3,1,9,23,1,5,10,11,2,2,10,26,1,2,10,29,2,2,10,33,4,1,11,27,1,4,11,32,3,2,12,13,1,2,12,31,1,3,13,14,1,2,13,18,1,1,13,35,1,2,14,16,1,1,14,19,1,3,14,36,1,1,15,20,1,1,16,16,1,1,16,18,2,1,17,17,1,3,18,20,3,1,19,21,1,1,20,27,1,1,21,22,1,2,21,30,1,1,22,24,1,1}},{{255,0,0},{2,0,1,1,3,1,3,1,4,2,2,1,5,3,2,1,6,4,2,2,7,6,2,1,10,7,1,2,11,8,1,1,12,9,1,3,13,10,1,3,14,12,1,2,15,13,1,1,16,14,2,1,17,15,2,2,17,24,1,1,19,16,1,3,20,18,1,2,21,19,1,1,22,20,2,1,23,21,2,3,24,24,2,2,25,22,2,1,25,23,1,4,26,26,1,1}},{{255,255,0},{5,4,1,2,6,6,1,1,7,7,3,2,9,9,3,1,12,12,1,1,13,13,1,1,13,17,4,1,14,14,2,2,14,18,1,1,15,16,1,2,16,15,1,1,18,17,1,3,19,19,1,1,20,21,3,1,21,20,1,2,22,22,1,2,23,24,1,1}},{{0,255,0},{15,19,1,1}},{{255,0,255},{22,28,1,1}},},{29,42,237}}
    myPic=DrawPicture:Create()
    myPic:Set({picture="picture",size=3})
    myPic:DoMove({x=0,y=0},{x=UI.ScreenSize().width,y=UI.ScreenSize().height},3)

```

## 例子2
```lua
    Draw.Texts={
    ['生']={{0,5,1,1,0,11,11,1,1,4,1,1,2,1,1,3,2,7,7,1,3,3,7,1,5,0,1,12},{11,12,7}},
    ['活']={{0,1,1,1,0,5,1,1,0,10,1,1,1,2,1,1,1,6,1,1,1,9,1,1,2,4,9,1,2,8,2,1,3,1,4,1,3,7,7,1,3,9,1,3,4,10,6,1,6,2,1,6,7,0,3,1,9,8,1,4},{11,12,15}},
    ['就']={{0,2,5,1,0,4,5,1,0,5,1,3,0,9,1,2,1,0,1,1,1,7,4,1,1,11,2,1,2,1,1,2,2,8,1,4,3,9,1,1,4,5,1,3,4,10,1,1,5,3,6,1,5,11,1,1,6,0,1,11,8,1,1,1,8,4,1,7,9,2,1,2,9,11,2,1,10,9,1,3},{11,12,20}},
    ['像']={{0,4,2,1,1,2,1,10,2,0,1,2,2,3,8,1,3,2,1,4,3,7,2,1,3,9,2,1,3,11,2,1,4,0,1,2,4,5,6,1,5,1,4,1,5,6,1,1,5,8,1,1,5,10,1,1,6,4,1,2,6,7,1,1,6,9,2,1,6,11,2,1,7,8,2,1,7,10,1,2,8,2,1,2,9,4,1,2,9,7,1,1,9,9,1,1,10,10,1,1},{11,12,25}},
    ['海']={{0,0,1,1,0,4,1,1,0,10,1,1,1,1,1,1,1,5,1,1,1,9,1,1,2,3,1,1,2,6,9,1,3,2,1,1,3,7,1,3,4,0,1,2,4,3,6,1,4,4,1,3,4,9,7,1,5,1,6,1,6,5,1,2,6,8,1,2,7,11,2,1,9,4,1,7},{11,12,19}},
    ['洋']={{0,1,1,1,0,5,1,1,0,10,1,1,1,2,1,1,1,6,1,1,1,9,1,1,2,8,9,1,3,2,7,1,3,5,7,1,4,0,1,1,5,1,1,2,6,3,1,9,7,1,1,2,8,0,1,1},{11,12,14}},
    ['，']={{0,6,2,2,0,9,1,1,1,8,1,1},{2,4,3}},
    ['只']={{0,11,1,1,1,1,9,1,1,2,1,5,1,10,1,1,2,6,8,1,2,9,1,1,8,9,1,1,9,2,1,5,9,10,1,1,10,11,1,1},{11,11,10}},
    ['有']={{0,2,11,1,0,6,1,1,1,5,2,1,2,4,8,1,2,6,8,1,2,7,1,5,3,3,1,2,3,8,7,1,4,0,1,3,8,11,2,1,9,5,1,7},{11,12,11}},
    ['意']={{0,3,11,1,0,11,1,1,1,1,9,1,1,9,1,2,2,4,1,4,3,2,1,2,3,5,6,1,3,7,6,1,3,9,1,2,4,11,5,1,5,0,1,2,5,8,1,1,6,9,1,1,7,2,1,2,8,4,1,4,8,10,1,2,9,9,1,1,10,10,1,2},{11,12,18}},
    ['志']={{0,2,11,1,0,10,1,1,1,5,9,1,1,8,1,2,3,8,1,3,4,11,5,1,5,0,1,6,5,7,1,1,6,8,1,2,8,10,1,2,9,8,1,1,10,9,1,2},{11,12,12}},
    ['坚']={{0,1,1,5,0,11,11,1,1,8,9,1,3,0,1,7,5,1,5,1,5,2,1,1,5,6,1,6,6,3,1,1,6,5,1,1,7,4,1,1,8,3,1,1,8,5,1,1,9,2,1,1,9,6,2,1},{11,12,14}},
    ['强']={{0,1,3,1,0,4,3,1,0,5,1,3,0,11,2,1,1,7,2,1,2,2,1,3,2,8,1,3,4,5,7,1,4,6,1,3,4,11,7,1,5,0,5,1,5,1,1,3,5,8,6,1,6,3,4,1,7,4,1,8,9,1,1,3,9,10,1,2,10,6,1,3},{11,12,18}},
    ['的']={{0,2,5,1,0,3,1,9,1,1,1,2,1,6,4,1,1,10,4,1,2,0,1,1,4,3,1,9,5,4,1,1,6,3,1,1,7,0,1,3,7,5,1,1,8,2,3,1,8,6,1,2,8,11,2,1,10,3,1,8},{11,12,15}},
    ['人']={{0,11,1,1,1,10,1,1,2,9,1,1,3,7,1,2,4,5,1,2,5,0,1,5,6,5,1,2,7,7,1,2,8,9,1,1,9,10,1,1,10,11,1,1},{11,12,11}},
    ['才']={{0,9,2,1,1,3,10,1,2,8,2,1,4,7,1,1,5,6,1,1,6,5,1,1,6,11,3,1,7,4,2,1,8,0,1,12},{11,12,9}},
    ['能']={{0,2,5,1,1,1,1,2,1,4,4,1,1,5,1,7,2,0,1,1,2,6,3,1,2,8,3,1,3,11,2,1,4,1,1,2,4,5,1,7,6,0,1,4,6,6,1,5,7,2,1,1,7,4,4,1,7,9,1,1,7,11,4,1,8,1,1,1,8,8,1,1,9,0,1,1,9,7,1,1,10,3,1,2,10,9,1,3},{11,12,22}},
    ['到']={{0,1,7,1,0,4,7,1,0,7,7,1,0,11,3,1,1,3,1,2,2,2,1,1,3,5,1,6,4,10,3,1,5,3,1,2,6,5,1,1,8,2,1,7,9,11,2,1,10,0,1,12},{11,12,13}},
    ['达']={{0,4,3,1,0,11,1,1,1,0,1,1,1,10,1,1,2,1,1,1,2,5,1,5,3,10,1,1,4,3,7,1,4,9,1,1,4,11,7,1,5,8,1,1,6,6,1,2,7,0,1,6,8,6,1,1,9,7,1,1,10,8,1,2},{11,12,16}},
    ['彼']={{0,3,1,1,0,6,1,1,1,2,1,1,1,5,2,1,2,1,1,1,2,4,1,8,3,0,1,1,3,3,2,1,3,11,1,1,4,2,7,1,4,4,1,7,5,5,5,1,5,11,1,1,6,6,1,3,6,10,1,1,7,0,1,6,7,9,1,1,8,8,1,1,8,10,1,1,9,6,1,2,9,11,2,1,10,3,1,1},{11,12,22}},
    ['岸']={{0,11,1,1,1,1,1,2,1,4,9,1,1,5,1,6,2,2,8,1,2,8,9,1,3,6,7,1,5,0,1,3,6,7,1,5,9,1,1,2},{11,12,10}},
}
myText=DrawText:Create()
myText:Set({text="生活就像海洋，只有意志坚强的人才能到达彼岸",x=UI.ScreenSize().width/2,y=UI.ScreenSize().height/2,kerning=5})
myText:Adaptation("center")
myText:BlinkShow(0.1)
```














						 
