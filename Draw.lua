MVC={
    width=1920,
    height=1080
}

Draw={}
Draw.Pictures=Draw.Pictures or {}
Draw.Texts=Draw.Texts or {}
Draw.TextsBase91=Draw.TextsBase91 or {}



function string.utf8tochars(input)
    local list={}
    local len=string.len(input)
    local index=1
    local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc}
    while index<=len do
        local pos
        for i = #arr, 1, -1 do

            if string.byte(input, index) >= arr[i] then

                pos = i

                break
            end

        end
        list[#list + 1] = string.sub(input, index, index + pos - 1)
        index=index+pos
    end
    return list
end

local UltraDecompressor = {}

-- ---------- Base91 解码表 ----------
local Base91Table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" ..
    "!#$%&()*+,./:;<=>?@[]^_`{|}~\""

local decodeMap = {}
for i = 1, #Base91Table do
    decodeMap[Base91Table:sub(i,i)] = i - 1
end

-- ---------- Base91 解码 ----------
function UltraDecompressor.fromBase91(str)
    local b = 0
    local n = 0
    local out = {}
    local v = -1

    for i = 1, #str do
        local c = str:sub(i, i)
        local val = decodeMap[c]
        if val == nil then error("invalid Base91 char: "..c) end

        if v < 0 then
            v = val
        else
            v = v + val * 91
            b = b | (v << n)
            if (v & 8191) > 88 then
                n = n + 13
            else
                n = n + 14
            end
            while n >= 8 do
                table.insert(out, string.char(b & 0xFF))
                b = b >> 8
                n = n - 8
            end
            v = -1
        end
    end

    if v >= 0 then
        b = b | (v << n)
        n = n + 13
        while n >= 8 do
            table.insert(out, string.char(b & 0xFF))
            b = b >> 8
            n = n - 8
        end
    end

    return table.concat(out)
end

-- ---------- 解包 ----------
function UltraDecompressor.unpackBits(byteStr)
    if #byteStr < 2 then return {} end
    local bytes = { byteStr:byte(1, #byteStr) }
    local bits = bytes[1]
    local length = bytes[2]
    local arr = {}
    local current = 0
    local bitCount = 0

    for i = 3, #bytes do
        local value = bytes[i]
        current = current | (value << bitCount)
        bitCount = bitCount + 8
        while bitCount >= bits and #arr < length do
            local v = current & ((1 << bits) - 1)
            table.insert(arr, v)
            current = current >> bits
            bitCount = bitCount - bits
        end
    end

    return arr
end


-- ---------- 总解码 ----------
function UltraDecompressor.decompress(str)
    local byteStr = UltraDecompressor.fromBase91(str)
    return UltraDecompressor.unpackBits(byteStr)
end

function Draw:Create(draw)
    local draw=draw or {}
    setmetatable(draw,self)
    self.__index=self
    draw.fontData=draw.fontData or {}
    draw.uiBoxArray=draw.uiBoxArray or {}
    draw.setArg= draw.setArg or Draw.SetArg:New()
    draw.OnDoMove=REGISTER:New()
    draw.OnDoMoveStart=REGISTER:New()
    draw.OnDoMoveEnd=REGISTER:New()
    draw.OnDoScale=REGISTER:New()
    draw.OnDoScaleStart=REGISTER:New()
    draw.OnDoScaleEnd=REGISTER:New()
    draw.OnDoColor=REGISTER:New()
    draw.OnDoColorStart=REGISTER:New()
    draw.OnDoColorEnd=REGISTER:New()
    return draw
end

Draw.SetArg={
    text=nil, --optional 在string 畫線顯示的文字
    font="small",--optional string 字體大小 (small, medium, large, verylarge)
    x=0, --optional int x 座標
    y=0, --optional int y 座標
    r=255, --optional int 文字顏色(紅色). 0~255 範圍
    g=255, --optional int 文字顏色(綠色). 0~255 範圍
    b=255, --optional int 文字顏色(藍色). 0~255 範圍
    a=255, --optional int 文字顏色(透明度). 0~255 範圍
    needBox=-1,
    isPicture = false,
    addHeight = 0,
    addWidth = 0,
}
--font的预设
Draw.SetArgSize={small=1, medium=2, large=3, verylarge=5}

function Draw.SetArg:New()
    local setArg={}
    setmetatable(setArg,self)
    self.__index=self
    return setArg
end
function Draw:SetText(text)
    if  text and self.setArg.text~=text then
        self.uiBoxArray={}
        self.setArg=Draw.SetArg:New()
        self.setArg.text=text
        if not Draw.Texts[text] and Draw.TextsBase91[text] then
            Draw.Texts[text]  = self:Decompress(Draw.TextsBase91[text])
        end
        if text=='\n' then
            self.fontData = {{},{0.001,12,0}}
        elseif not Draw.Texts[text] then
            self.fontData = {{},{11,12,0}}
            print("没有"..text.."字，用空格代替")
        end
        collectgarbage()
    end
end
function Draw:Decompress(dataStr)
       local data =UltraDecompressor.decompress(dataStr)
       local boxCount = table.remove(data)
       local totalHeight = table.remove(data)
       local totalWidth = table.remove(data)
       return {data,{totalWidth,totalHeight,boxCount}}
end
function Draw:SetFontData(tabOrtext)
    if Draw.Texts[tabOrtext] then
        self.fontData=Draw.Texts[tabOrtext]
    elseif type(tabOrtext)=="table" then
        self.fontData=tabOrtext
    end
end
--原始宽高只设置一次
function Draw:SetOriginWidthAndHeight(originWidth,originHeight)
    if not self.setArg.originHeight and not self.setArg.originWidth then
        self.setArg.originWidth= originWidth
        self.setArg.originHeight= originHeight
    end
end

function Draw:SetPos(x,y)
    self.setArg.x=x or self.setArg.x
    self.setArg.y=y or self.setArg.y
end
function Draw:SetColor(r,g,b)
    self.setArg.r=r or self.setArg.r
    self.setArg.g=g or self.setArg.g
    self.setArg.b=b or self.setArg.b
end
function Draw:SetWH(width,height)
    self.setArg.width=width or self.setArg.width
    self.setArg.height=height or self.setArg.height
end
function Draw:SetFontSize(size,font)
    local set=self.setArg
    set.size=size or Draw.SetArgSize[font]  or set.size or Draw.SetArgSize[set.font]  or 1
    if set.originWidth and set.originHeight then
        self:SetWH( set.originWidth*set.size,set.originHeight*set.size)
    end
end
function Draw:GetRatio()
    local set=self:Get()
    local ratio={width=1,height=1}
    if set.width  then
        if set.originWidth==nil then
            ratio.width=1
        else
            ratio.width=set.width/set.originWidth
        end
    end
    if set.height then
        if set.originHeight==nil then
            ratio.height=1
        else
            ratio.height=set.height/set.originHeight
        end
    end
    return ratio
end

function Draw:CreateBox()
    local data
    if #self.fontData==2 then
        data = self.fontData[1]
    else
        data = self.fontData
    end
    for i=1,#data/4 do
        self.uiBoxArray[i]=self.uiBoxArray[i] or UI.Box.Create()
        if  self.uiBoxArray[i]==nil then
            return false
        end
    end
    return true
end

function Draw:Set(args)
    self:SetText(args.text)

    self:SetFontData(args.text)

    if #self.fontData==2 and self.fontData[2][1] then
        self:SetOriginWidthAndHeight(self.fontData[2][1],self.fontData[2][2])
    else  --对于网页版生成器的适配
        self:SetOriginWidthAndHeight(11,12)
    end

    self:SetPos(args.x,args.y)
    self:SetColor(args.r,args.g,args.b)
    self:SetFontSize(args.size,args.font)
    self:SetWH(args.width,args.height)
    if not self:CreateBox() then return end
    local ratio=self:GetRatio()
    local ratioWidth=ratio.width
    local ratioHeight=ratio.height

    --每4个分割
    local maxX,maxY,minX,minY
    local index=1
    local data
    if #self.fontData == 2 then
        data = self.fontData[1]
    else
        data = self.fontData
    end
    for i=1 ,# data,4 do
        local x=data[i]*ratioWidth+self.setArg.x
        local y=data[i+1]*ratioHeight+self.setArg.y
        local width=data[i+2]*ratioWidth
        local height=data[i+3]*ratioHeight
        --大于等于1号字体的加粗
        if ratioWidth >1 then
            width = width + 1
            height = height + 1
        end
		--大图片有缝隙，需要拉伸
		if self.isPicture then
            if self.setArg.addHeight>0 then
                height = height + height*self.setArg.addHeight
            end
            if self.setArg.addWidth>0 then
                width = width + width*self.setArg.addWidth
            end
		end

        maxX=maxX or x+width
        maxY=maxY or y+height
        minX=minX or x
        minY=minY or y
        self.uiBoxArray[index]:Set({
            x=x,
            y=y,
            width= width,
            height=height,
            r=self.setArg.r,
            g=self.setArg.g,
            b=self.setArg.b,
            a=self.setArg.a})
        self.uiBoxArray[index]:Show()
        maxX=math.max(maxX,x+width)
        maxY=math.max(maxY,y+height)
        minX=math.min(x,minX)
        minY=math.min(y,minY)
        index=index+1
    end
    self.setArg.needBox=#self.uiBoxArray
    self:SetWH(self.setArg.originWidth*ratioWidth,self.setArg.originHeight*ratioHeight)
end

function Draw:Get()
    return self.setArg
end
function Draw:Hide()
    for i=1,#self.uiBoxArray do
        self.uiBoxArray[i]:Hide()
    end
end
function Draw:Show()
    for i=1,#self.uiBoxArray do
        self.uiBoxArray[i]:Show()
    end
end

function Draw.AdaptationSelf(self,mode)
    local x,y,width,height
    local screen=UI.ScreenSize()
    local selfArg= self.setArg
    local set=self:Get()

    selfArg={x=set.x,y=set.y,width=set.width,height=set.height}
    x=selfArg.x/MVC.width*screen.width
    y=selfArg.y/MVC.height*screen.height
    width=screen.width/MVC.width*selfArg.width
    height=screen.height/MVC.height*selfArg.height

    if mode=="center" then
        Draw.AdaptationCenter(self,x,y,width,height)
    elseif mode=="downLeft" then
        Draw.AdaptationDownLeft(self,x,y,width,height)
    elseif mode=="upRight" then
        Draw.AdaptationUpRight(self,x,y,width,height)
    elseif mode=="upCenter" then
        Draw.AdaptationUpCenter(self,x,y,width,height)
    elseif mode=="downCenter" then
        Draw.AdaptationDownCenter(self,x,y,width,height)
    elseif mode=="downRight" then
        Draw.AdaptationDownRight(self,x,y,width,height)

    elseif mode=="widthHeight" then
        Draw.AdaptationWidthHeight(self,x,y,width,height)
    else
        Draw.AdaptationDefault(self,x,y,width,height)
    end
    collectgarbage()
end
function  Draw.AdaptationDefault(self,x,y,width,height)
    self:Set({
        x=x,
        y=y,
        width = width,
        height =height,
    })
end
function Draw.AdaptationCenter(self,x,y,width,height)
    if self.lines and #self.lines>1 then
        for i = 1, #self.lines do
            local lineData = self.lines[i]
            local offSetX = lineData.width/2
            local offSetY = lineData.y - lineData.height/2
            for textIndex = lineData.textRange[1], lineData.textRange[2] do
                local childText=self:GetChildText(textIndex)
                childText:Set({x=childText:Get().x-offSetX,y=offSetY,width=childText:Get().width ,height=childText:Get().height})
            end
        end
    else
        Draw.AdaptationDefault(self,x,y,width,height)
        --平移位置
        self:Set({
            x = self:Get().x-self:Get().width/2,
            y = self:Get().y-self:Get().height/2
        })
    end
end
function Draw.AdaptationDownLeft(self,x,y,width,height)
    --先设置位置
    Draw.AdaptationDefault(self,x,y,width,height)
    --平移位置
    self:Set({
        x = self:Get().x,
        y = self:Get().y-self:Get().height
    })
end
function Draw.AdaptationUpRight(self,x,y,width,height)
    Draw.AdaptationDefault(self,x,y,width,height)
    self:Set({
        x = self:Get().x-self:Get().width,
        y = self:Get().y
    })
end
function Draw.AdaptationUpCenter(self,x,y,width,height)
    Draw.AdaptationDefault(self,x,y,width,height)
    self:Set({
        x = self:Get().x-self:Get().width/2,
        y = self:Get().y
    })
end
function Draw.AdaptationDownCenter(self,x,y,width,height)
    Draw.AdaptationDefault(self,x,y,width,height)
    self:Set({
        x = self:Get().x-self:Get().width/2,
        y = self:Get().y-self:Get().height
    })
end
function Draw.AdaptationDownRight(self,x,y,width,height)
    Draw.AdaptationDefault(self,x,y,width,height)
    self:Set({
        y = self:Get().y-self:Get().height,
        x = self:Get().x-self:Get().width
    })
end
function Draw.AdaptationWidthHeight(self,x,y,width,height)
    self:Set({
        width = width,
        height = height,
    })
end
--适配
function Draw:Adaptation(mode)
    Draw.AdaptationSelf(self,mode)
end
--DrawPicture Start
DrawPicture={}
DrawPicture.SetArg={
    picture=nil,--pictureName string
    size=1,
    originHeight=-1,
    originWidth=-1,
    addHeight = 0,
    addWidth = 0
}
function DrawPicture.SetArg:New()
    local setArg=Draw.SetArg:New()
    for k,v in pairs(self) do
        setArg[k]=v
    end
    return setArg
end
function DrawPicture:Create(drawPicture)
    local drawPicture=  drawPicture or {}
    setmetatable(drawPicture,self)
    self.__index=self
    drawPicture.setArg=DrawPicture.SetArg:New()
    drawPicture.OnDoMove=REGISTER:New()
    drawPicture.OnDoMoveStart=REGISTER:New()
    drawPicture.OnDoMoveEnd=REGISTER:New()
    drawPicture.OnDoScale=REGISTER:New()
    drawPicture.OnDoScaleStart=REGISTER:New()
    drawPicture.OnDoScaleEnd=REGISTER:New()
    return drawPicture
end
function DrawPicture:SetPic(pic)
    if pic and self.setArg.picture~=pic then
        self.drawArray=nil
        self.picData=Draw.Pictures[pic]
        if self.picData==nil then
            print("图片"..self.setArg.picture.."不存在")
            return
        end
        collectgarbage()
    end
end
function DrawPicture:SetSize(size)
    self.setArg.size=size or self.setArg.size
end
function DrawPicture:SetPos(x,y)
    self.setArg.x=x or self.setArg.x
    self.setArg.y=y or self.setArg.y
end
function DrawPicture:SetWH(width,height)
    self.setArg.width=width or self.setArg.width
    self.setArg.height=height or self.setArg.height
end
function DrawPicture:SetAddWH(addWidth,addHeight)
    self.setArg.addWidth=addWidth or self.setArg.addWidth
    self.setArg.addHeight=addHeight or self.setArg.addHeight
end
function DrawPicture:Set(args)
    self:SetPic(args.picture)
    self:SetPos(args.x,args.y)
    self:SetSize(args.size)
    self:SetWH(args.width,args.height)

    --引用图片数据
    if self.picData ==nil then
        print(self.setArg.picture.."图片不存在")
        return
    end
    local base=self.picData[1]
    local other=self.picData[2]

    self.setArg.originHeight= other[2]

    self.setArg.originWidth=  other[1]

    self.setArg.needBox=  other[3]

    local ratioWidth=1
    local ratioHeight=1

    self.setArg.width = self.setArg.width or self.setArg.originWidth*self.setArg.size
    self.setArg.height = self.setArg.height or self.setArg.originHeight*self.setArg.size

    ratioWidth = self.setArg.width/self.setArg.originWidth
    ratioHeight = self.setArg.height/self.setArg.originHeight


    self.drawArray=self.drawArray or {}

    for i=1,#base do
        local r=base[i][1][1]
        local g=base[i][1][2]
        local b=base[i][1][3]
        self.drawArray[i]=self.drawArray[i] or Draw:Create()
        --是图片，为了防止有缝隙所以需要适当拉升
        self.drawArray[i].isPicture=true
        self.drawArray[i].setArg.addHeight = self.setArg.addHeight
        self.drawArray[i].setArg.addWidth =self.setArg.addWidth
        self.drawArray[i]:SetFontData({base[i][2],{}})
        self.drawArray[i]:Set({text=self.setArg.picture,x=self.setArg.x,y=self.setArg.y,r=r,g=g,b=b,a=255})
        self.drawArray[i]:Set({width=self.drawArray[i]:Get().width*ratioWidth,height=self.drawArray[i]:Get().height*ratioHeight})
    end

    self.setArg.width=self.setArg.originWidth*ratioWidth

    self.setArg.height=self.setArg.originHeight*ratioHeight
end
function DrawPicture:Hide()
    for i=1,#self.drawArray do
        self.drawArray[i]:Hide()
    end
end
function DrawPicture:Show()
    for i=1,#self.drawArray do
        self.drawArray[i]:Show()
    end
end
function DrawPicture:Get()
    return self.setArg
end
function DrawPicture:Adaptation(mode)
    Draw.AdaptationSelf(self,mode)
end
--DrawPicture End
DrawText={
    kerning=1,--字间距
    nSet = nil, --换行符设置
}
--换行符设置
nSet={
    y=0,
    heightSpace=3,
}
function nSet:New()
    local o = {}
    setmetatable(o,self)
    self.__index=self
    return o
end
function DrawText:Create(drawText)
    local drawText=drawText or {}
    setmetatable(drawText,self)
    self.__index=self
    drawText.setArg=drawText.setArg or Draw.SetArg:New()
    drawText.setArg.kerning=drawText.setArg.kerning or self.kerning
    drawText.nSet = drawText.nSet or nSet:New()
    drawText.OnDoMove=REGISTER:New()
    drawText.OnDoMoveStart=REGISTER:New()
    drawText.OnDoMoveEnd=REGISTER:New()
    drawText.OnDoScale=REGISTER:New()
    drawText.OnDoScaleStart=REGISTER:New()
    drawText.OnDoScaleEnd=REGISTER:New()
    drawText.OnDoColor=REGISTER:New()
    drawText.OnDoColorStart=REGISTER:New()
    drawText.OnDoColorEnd=REGISTER:New()
    return drawText
end

function DrawText:SetWH(width,height)
    Draw.SetWH(self,width,height)
end
function DrawText:SetFontSize(size,font)
    if not size and not font then
        return
    end
    local set=self.setArg
    set.size=size or Draw.SetArgSize[font]  or set.size or Draw.SetArgSize[set.font]  or 1
    self:SetWH(self.setArg.originWidth*set.size,self.setArg.originHeight*set.size)
end

function DrawText:Set(args)
    self:SetText(args.text)
    self:SetPos(args.x,args.y)
    self:SetColor(args.r,args.g,args.b)
    self:SetWH(args.width,args.height)
    self.kerning=args.kerning or  self.kerning
    if self.setArg.text~="" then
        self:SetOriginWidthAndHeight()
        self:SetFontSize(args.size,args.font)
        self:SetMode(args.mode)
    end
end
function DrawText:SetText(text)
    if  text and self.setArg.text~=text then
        self.textArray={}
        self.setArg.text=text
        self.setArg.originWidth = nil
        collectgarbage()
    end
end
function DrawText:SetPos(x,y)
    self.setArg.x=x or self.setArg.x
    self.setArg.y=y or self.setArg.y
end

function DrawText:SetOriginWidthAndHeight()
    if self.setArg.originWidth then
        return
    end
    local setArg=self.setArg
    local x=setArg.x
    local y=setArg.y
    self.setArg.textFont=string.utf8tochars(self.setArg.text)
    local totalWidth=0
    local totalHeight=0
    local needBox=0
    for i = 1, #self.setArg.textFont do
        self.textArray[i]=self.textArray[i] or Draw:Create()
        self.textArray[i]:Set({text=self.setArg.textFont[i],x=x,y=y+self.nSet.y})
        local set=self.textArray[i]:Get()
        local width=set.width
        local height=set.height
        needBox=needBox+set.needBox
        x=x+width+self.kerning
        totalWidth = totalWidth+width+self.kerning
        totalHeight = math.max(height,totalHeight)
        self.textArray[i]:Hide()
    end
    local lastTextSet = self.textArray[#self.textArray]:Get()
    local firstTextSet = self.textArray[1]:Get()
    self.setArg.originWidth = lastTextSet.x + lastTextSet.width - firstTextSet.x
    self.setArg.originHeight = totalHeight
    self.setArg.needBox = needBox
end
function DrawText:SetColor(r,g,b)
    for k,v in pairs(self.textArray) do
        local originSet=self.textArray[k]:Get()
        self.textArray[k]:Set({r=r or originSet.r,g=g or originSet.g,b=b or originSet.b})
    end
    Draw.SetColor(self,r,g,b)
end
function DrawText:GetChildText(index)
    if index<=#self.textArray then
        return self.textArray[index]
    else
        print(index.."最大为:"..#self.textArray)
    end
end
function DrawText:SetMode(mode)
    self.mode = mode or self.mode
    if self.mode=="vertical" then
        self:SetVerticalMode()
    else
        self:SetNormalMode()
    end
end
function DrawText:SetVerticalMode()
    self.setArg.width = (self.setArg.width or self.setArg.originWidth)
    self.setArg.height = (self.setArg.height or self.setArg.originHeight)
    local ratioWidth = self.setArg.width/self.setArg.originWidth
    local ratioHeight = self.setArg.height/self.setArg.originHeight
    local setArg=self.setArg
    local x=setArg.x
    local y=setArg.y
    local totalHeight=0
    local totalWidth=0
    for i = 1, #self.setArg.textFont do
        self.textArray[i]=self.textArray[i] or Draw:Create()
        self.textArray[i]:Set({text=self.setArg.textFont[i],x=x,y=y,r=setArg.r,g=setArg.g,b=setArg.b})
        local set=self.textArray[i]:Get()
        self.textArray[i]:Set({width=set.width*ratioWidth,height=set.height*ratioHeight})
        set=self.textArray[i]:Get()
        local width=set.width
        local height=set.height
        y=y+height+self.kerning*ratioHeight
        self.textArray[i]:Show()
    end
end

function DrawText:SetNormalMode()
    self.setArg.width = (self.setArg.width or self.setArg.originWidth)
    self.setArg.height = (self.setArg.height or self.setArg.originHeight)
    local ratioWidth = self.setArg.width/self.setArg.originWidth
    local ratioHeight = self.setArg.height/self.setArg.originHeight
    local setArg=self.setArg
    local x=setArg.x
    local y=setArg.y
    local lineHeight=0
    self.lines = {}
    local lineTextRange = 1
    local lineCount = 1
    local nSetY = self.nSet.y
    local heightSpace = self.nSet.heightSpace
    for i = 1, #self.setArg.textFont do
        self.textArray[i]=self.textArray[i] or Draw:Create()
        if lineCount==1 then
            self.textArray[i]:Set({text=self.setArg.textFont[i],x=x,y=y})
        else
            self.textArray[i]:Set({text=self.setArg.textFont[i],x=x,y=y+nSetY})
        end
        local set=self.textArray[i]:Get()
        self.textArray[i]:Set({width=set.width*ratioWidth,height=set.height*ratioHeight,r=setArg.r,g=setArg.g,b=setArg.b})
        set=self.textArray[i]:Get()
        local width=set.width
        local height=set.height
        x=x+width+self.kerning
        lineHeight = math.max(lineHeight,height)
        if self.setArg.textFont[i]=='\n' then
            set=self.textArray[i-1]:Get()
            self.lines[lineCount]={x=setArg.x,y=set.y,width =set.width + set.x-setArg.x,height = lineHeight,textRange = {lineTextRange,i-1}}
            nSetY = nSetY + self.textArray[i]:Get().height+heightSpace
            x = setArg.x
            --每行字的index范围
            lineTextRange = i+1
            lineHeight = 0
            lineCount = lineCount+1
        end
        if i==#self.setArg.textFont then
            self.lines[lineCount]={x=setArg.x,y=set.y,width =set.width + set.x-setArg.x,height = lineHeight,textRange = {lineTextRange,i}}
            --TODO
            --如果有换行符这里获取的高度会不正确
            --self.setArg.height = lineHeight+set.y-setArg.y
        end
    	self.textArray[i]:Show()
    end
end
function DrawText:DisPlayMode(mode)
    self:SetMode(mode)
end
function DrawText:Get()
    local args={}
    for k,v in pairs(self.setArg) do
        args[k]=v
    end
    if #self.textArray>1 then
        local lastTextSet = self.textArray[#self.textArray]:Get()
        local firstTextSet = self.textArray[1]:Get()
        args.width = lastTextSet.x - firstTextSet.x+lastTextSet.width
    elseif #self.textArray==1 then
        local firstTextSet = self.textArray[1]:Get()
        args.width = firstTextSet.width
    end
    return args
end
function DrawText:Hide()
    for k,v in pairs(self.textArray) do
        v:Hide()
    end
end
function DrawText:Show()
    for k,v in pairs(self.textArray) do
        v:Show()
    end
end
function DrawText:BlinkShow(time)
    for i=1,#self.textArray do
        self.textArray[i]:Hide()
    end
    local t=0
    for i=1,#self.textArray do
        Invoke(self.textArray[i].Show,t,self.textArray[i])
        t=t+time
    end
end
function DrawText:Adaptation(mode)
    Draw.AdaptationSelf(self,mode)
end


if Framework then
    Framework.UIPlug.OnUpdate:Register(function()
        DoMoveManager:OnUpdate()
        DoColorManager:OnUpdate()
        DoScaleManager:OnUpdate()
    end)
end




function Evaluate(type,time,duration)
    if not type then
        type="OutQuad"
    end
    if type=="OutQuad" then
        return  -(time/duration)*(time/duration-2)
    end
    if type=="InQuad" then
        return  -(time/duration)*(time/duration)
    end
    if type=="InSine" then
        return -math.cos(time/duration*3.14*0.5)+1
    end
    if type=="OutSine" then
        return math.sin(time/duration*3.14*0.5)
    end
    if type=="InCubic" then
        return (time/duration)^3
    end
    if type=="OutCubic" then
        return (time/duration-1)^3+1
    end
    if type=="InExpo" then
        return 2^(duration*(time/duration-1))
    end
    if type=="OutExpo" then
        return -2^(-duration*(time/duration))+1
    end
    if type=="Linear" then
        return time/duration
    end
end


--画线
DrawLine={
}
DrawLine.SetArg={
    size=3,
    r=255,
    g=255,
    b=255,
    a=255,
    width=-1,
    height=-1,
    pos1={},
    pos2={},
    x=0,
    y=0
}

function DrawLine.SetArg:Create()
    local args={}
    setmetatable(args,self)
    self.__index=self
    args.pos1={x=0,y=0}
    args.pos2={x=0,y=0}
    return args
end

function DrawLine:Create()
    local drawLine={}
    setmetatable(drawLine,self)
    self.__index=self
    drawLine.setArg=DrawLine.SetArg:Create()
    drawLine.uiBoxArray={}
    drawLine.OnDoMove=REGISTER:New()
    drawLine.OnDoMoveStart=REGISTER:New()
    drawLine.OnDoMoveEnd=REGISTER:New()
    drawLine.OnDoScale=REGISTER:New()
    drawLine.OnDoScaleStart=REGISTER:New()
    drawLine.OnDoScaleEnd=REGISTER:New()
    drawLine.OnDoColor=REGISTER:New()
    drawLine.OnDoColorStart=REGISTER:New()
    drawLine.OnDoColorEnd=REGISTER:New()
    return drawLine
end

function DrawLine:Set(args)
    for k,v in pairs(args) do
        self.setArg[k]=args[k] or self.setArg[k]
    end
    if args.pos1 then
        self.setArg.x = self.setArg.pos1.x
        self.setArg.y = self.setArg.pos1.y
    end

    local x1= self.setArg.x
    local y1= self.setArg.y
    local x2= self.setArg.pos2.x
    local y2= self.setArg.pos2.y
    if args.pos2 then
        self.setArg.width = math.abs(x2-x1)
        self.setArg.height = math.abs(y2-y1)
    end
    if self.setArg.width then
        x2 = x1 + self.setArg.width
    end
    if self.setArg.height then
        y2 =y1 + self.setArg.height
    end

    local size= self.setArg.size

    self.uiBoxArray=self.uiBoxArray or {}
    local stepY=size
    local stepX=size
    if y2<y1 then
        stepY=-stepY
    end
    if x2<x1 then
        stepX=-stepX
    end

    local index = 0
    for y = y1,y2,stepY do
        local x=(y-y2)/ (y1-y2)*(x1-x2)+x2
        index= index + 1
        self.uiBoxArray[index]=self.uiBoxArray[index] or UI.Box.Create()
        if self.uiBoxArray[index] then
            self.uiBoxArray[index]:Set({ x=x , y=y, width=size, height=size, r= self.setArg.r, g= self.setArg.g, b= self.setArg.b, a= self.setArg.a})
        end

    end

    for x = x1,x2,stepX do
        local y= (x-x2)/ (x1-x2)* (y1-y2)+y2
        index=index + 1
        self.uiBoxArray[index]=self.uiBoxArray[index] or UI.Box.Create()
        if  self.uiBoxArray[index] then
            self.uiBoxArray[index]:Set({ x=x , y=y, width=size, height=size, r= self.setArg.r, g= self.setArg.g, b= self.setArg.b, a= self.setArg.a})
        end
    end
    self.setArg.needBox=#self.uiBoxArray
end

function DrawLine:SetPos(x,y)
    x=x or self.setArg.x
    y=y or self.setArg.y
    local offSetX=x-self.setArg.x
    local offSetY=y-self.setArg.y

    self.setArg.y=y
    self.setArg.x=x
    for i = 1, #self.uiBoxArray do
        self.uiBoxArray[i]:Set({x= self.uiBoxArray[i]:Get().x+offSetX,y=self.uiBoxArray[i]:Get().y+offSetY})
    end
end


function DrawLine:Show(args)
    for k,v in pairs(self.uiBoxArray) do
        v:Show()
    end
end

function DrawLine:Hide(args)
    for k,v in pairs(self.uiBoxArray) do
        v:Hide()
    end
end
function DrawLine:Adaptation(mode)
    Draw.AdaptationSelf(self,mode)
end
function DrawLine:Get()
    return self.setArg
end

function DrawLine:DoMove(startPos,endPos,time,type)
    DoMoveManager:Add(self,startPos,endPos,time,type)
end
function DrawLine:DoColor(startColor,endColor,time,type)
    DoColorManager:Add(self,startColor,endColor,time,type)
end
DrawPolygon ={}
DrawPolygon.SetArg ={
    n=4,
    radius=10,
    center={x=0,y=0},
    size=10,
    r=255,g=255,b=255,a=255
}
function DrawPolygon.SetArg:Create()
    local setArg={}
    setmetatable(setArg,self)
    self.__index=self
    setArg.vertex={}
    return setArg
end
function DrawPolygon:Create()
    local polygon ={}
    setmetatable(polygon,self)
    self.__index=self
    polygon.setArg= DrawPolygon.SetArg:Create()
    polygon.lineBox= {}
    polygon.OnDoMove=REGISTER:New()
    polygon.OnDoMoveStart=REGISTER:New()
    polygon.OnDoMoveEnd=REGISTER:New()
    polygon.OnDoScale=REGISTER:New()
    polygon.OnDoScaleStart=REGISTER:New()
    polygon.OnDoScaleEnd=REGISTER:New()
    polygon.OnDoColor=REGISTER:New()
    polygon.OnDoColorStart=REGISTER:New()
    polygon.OnDoColorEnd=REGISTER:New()
    return polygon
end
function DrawPolygon:Set(args)
    for k,v in pairs(DrawPolygon.SetArg) do
        self.setArg[k]=args[k] or  self.setArg[k]
    end
    local args=self.setArg
    --args.test={}
    local minX=100000
    local minY=100000
    local maxX=-1
    local maxY=-1
    for i = 1 ,args.n do
        self.lineBox[i]=self.lineBox[i] or {}
        local x=args.center.x + args.radius * math.cos(2 * math.pi * (i-1) / args.n)
        local y=args.center.y+ args.radius * math.sin(2 * math.pi * (i-1) / args.n)
        minX=math.min(x,minX)
        minY=math.min(y,minY)
        maxX=math.max(x,maxX)
        maxY=math.max(y,maxY)
        args.vertex[i]={x=x,y=y}
        if i>1 then
            self.lineBox[i]= DrawLine:Create()
            self.lineBox[i]:Set({
                pos1={x= args.vertex[i].x ,y=args.vertex[i].y},
                pos2={x= args.vertex[i-1].x,y= args.vertex[i-1].y},
                r=args.vertex[i-1].r,
                g=args.vertex[i-1].g,
                b=args.vertex[i-1].b,
                a=args.vertex[i-1].a
            })
        end
    end
    self.lineBox[1]=DrawLine:Create()
    self.lineBox[1]:Set({
        pos1={x= args.vertex[1].x,y=args.vertex[1].y, r=args.vertex[1].r, g=args.vertex[1].g, b=args.vertex[1].b, a=args.vertex[1].a},
        pos2={x= args.vertex[args.n].x,y= args.vertex[args.n].y, r=args.vertex[args.n].r, g=args.vertex[args.n].g, b=args.vertex[args.n].b, a=args.vertex[args.n].a }})
    self.setArg.width=maxX-minX
    self.setArg.height=maxY-minY
    self.setArg.x=minX
    self.setArg.y=minY
end
function DrawPolygon:Get(args)
    return self.setArg
end
function DrawPolygon:Adaptation(mode)
    for i = 1, #self.lineBox do
        Draw.AdaptationSelf( self.lineBox[i],mode)
    end
end
function DrawPolygon:DoMove(startPos,endPos,time,type)
    local timeCount=0
    local function update()
        timeCount=timeCount+Time.deltaTime
        local tmp=Evaluate(type,timeCount,time)
        collectgarbage()
        self:Set({center={x=startPos.x+(endPos.x-startPos.x)*tmp,y=startPos.y+(endPos.y-startPos.y)*tmp}})
        if tmp>0.999999 or timeCount>time then
            Framework.UIPlug.OnUpdate:UnRegister(update)
        end
    end
    Framework.UIPlug.OnUpdate:Register(update)
end


--DropDownMenu Start
if Framework then

    --DropDownMenu Start
    if Framework then
        Draw=Draw or {}
        Draw.MenuStrip={
            x=0,y=0,
            size=1,
            height=nil,
            width=nil,
            child=nil,
            parent=nil,
            focusIndex=1,
            BGColor={r=1,g=1,b=1,a=255},
            textColor={r=255,g=255,b=255,a=255},
            focusBGColor={r=111,g=111,b=111,a=255},
            onlyShowOnFocus=false,
            itemsHeight=50,
            itemsWidth=80,
            childPos = {x=0,y=0},
            isAbsoluteChildPos = false
        }
        Draw.MenuStrip.itemsData={name=nil,child = Draw.MenuStrip}
        MenuStripManager={

        }
        --主菜单
        function Draw.MenuStrip.CreateEvent(self)
            self.OnKeyDown={
                W=REGISTER:New(),
                S=REGISTER:New(),
                A=REGISTER:New(),
                D=REGISTER:New(),
                MOUSE1=REGISTER:New(),
            }
            self.OnSelect=REGISTER:New()
            self.OnFocusEvent=REGISTER:New()
        end

        function Draw.MenuStrip.OnRegisterEvent(self)
            self.keyDownS=function(self)
                if self.focus then
                    if self.itemsData[self.focusIndex+1] then
                        self.focusIndex=self.focusIndex+1
                        self:OnFocus(self.focusIndex)
                    end
                    if self.itemsData [self.focusIndex] and self.itemsData [self.focusIndex]. child then
                        self:ShowChild(self.focusIndex)
                    end
                    if self.itemsData [self.focusIndex-1] and self.itemsData [self.focusIndex-1]. child then
                        self:HideChild(self.focusIndex-1)
                    end
                    self:UpdateBG()
                    self:UpdateMenus()
                end
            end
            self.keyDownW=function(self)
                if not self.focus then return end
                if not self.itemsData[self.focusIndex-1] then return end
                self.focusIndex=self.focusIndex-1
                self:OnFocus(self.focusIndex)
                if self.itemsData [self.focusIndex] and self.itemsData [self.focusIndex]. child then
                    self:ShowChild(self.focusIndex)
                end
                if self.itemsData [self.focusIndex+1] and self.itemsData [self.focusIndex+1]. child then
                    self:HideChild(self.focusIndex+1)
                end
                self:UpdateBG()
                self:UpdateMenus()
            end
            self.keyDownA=function(self)
                if self.focus then
                    if  self. parent then
                        self.focus=false
                        self:Hide()
                        for i = 1, #self.itemsData do
                            if  self.itemsData [i].child then
                                self.itemsData [i].child:Hide()
                            end
                        end
                        self=self.parent
                        self:OnFocus(self.historyIndex)
                        return true
                    end
                end
                return false
            end
            self.keyDownMOUSE1=function(self)
                self.OnSelect:Trigger(self,self.focusIndex)
                if #self.items>0 then
                    self:Show()
                end
            end
            self.keyDownD=function(self)
                if self.focus then
                    if self.itemsData [self.focusIndex]. child  then
                        self:ShowChild(self.focusIndex)
                        self.focus=false
                        self.historyIndex=self.focusIndex
                        self=self.itemsData [self.focusIndex]. child
                        self:OnFocus(1)
                        if self.itemsData [self.focusIndex] and self.itemsData [self.focusIndex]. child  then
                            self:ShowChild(self.focusIndex)
                        end
                    end
                    return true
                end
                return false
            end
            self.OnKeyDown.A:Register(self.keyDownA)
            self.OnKeyDown.MOUSE1:Register(self.keyDownMOUSE1)
            self.OnKeyDown.D:Register(self.keyDownD)
            self.OnKeyDown.W:Register(self.keyDownW)
            self.OnKeyDown.S:Register(self.keyDownS)
            collectgarbage()
        end
        function  Draw.MenuStrip:ShowChild(index)
            if self.items and self.items[index] then
                local child = self.itemsData [index]. child
                if child.isAbsoluteChildPos then
                    child:SetPos({x=child.childPos.x,y=child.childPos.y,childPos =child.childPos,isAbsoluteChildPos = child.isAbsoluteChildPos })
                else
                    child:SetPos({x=self.x+self.itemsWidth+child.childPos.x,y=self.y+self.itemsHeight*(index-1)+child.childPos.y})
                end
                child:OnlyShowOnFocus(self.onlyShowOnFocus)
                child:Show()
            end
        end
        function  Draw.MenuStrip:HideChild(index)
            if self.items and self.items[index] and self.itemsData [index]. child then
                self.itemsData [index]. child:Hide()
            end
        end
        function Draw.MenuStrip:OnlyShowOnFocus(bool)
            if type(bool)=="boolean" then
                self.onlyShowOnFocus=bool
            end
        end
        function Draw.MenuStrip:Create(args)
            local menu={}
            setmetatable(menu,self)
            self.__index=self
            if args then
                menu.x=args.x
                menu.y=args.y
                menu.size=args.size
                menu.parent=args.parent
                menu.itemsHeight=args.itemsHeight
                menu.itemsWidth=args.itemsWidth
                menu.childPos = args.childPos
                menu.kerning = args.kerning
                menu.isAbsoluteChildPos = args.isAbsoluteChildPos
            end
            menu.BG=UI.Box.Create()
            menu.focusBG=UI.Box.Create()
            menu.focusBG:Set({r=100,g=100,b=100})

            menu.items={}
            menu.itemsData={}
            menu.BGColor ={}
            menu.textColor ={}
            menu.focusBGColor ={}

            setmetatable(menu.BGColor,self.BGColor)
            self.BGColor.__index= self.BGColor
            setmetatable(menu.textColor,self.TextColor)
            self.textColor.__index= self.textColor
            setmetatable(menu.focusBGColor,self.focusBGColor)
            self.focusBGColor.__index= self.focusBGColor

            Draw.MenuStrip.CreateEvent(menu)
            Draw.MenuStrip.OnRegisterEvent(menu)
            MenuStripManager[menu]=menu
            return menu
        end
        function Draw.MenuStrip:OnFocus(index)
            self.focusBG:Hide()
            if self.itemsData[index] then
                self.focusIndex=index
                self.focus=true
                if self.items[self.focusIndex] then
                    self.focusBG:Set(self.items[self.focusIndex]:Get())
                end
                self.focusBG:Set(self.focusBGColor)
                self.focusBG:Show()
                self.OnFocusEvent:Trigger(self,index)
            end
            for i = 1, #self.itemsData do
                if i~=index then
                    self:HideChild(i)
                end
            end
        end

        --释放菜单下所有的数据和控制权限
        function Draw.MenuStrip:Dispose()
            for i = 1, #self.itemsData do
                --删掉所有子节点
                if self.itemsData[i].child then
                    self.itemsData[i].child:Dispose()
                end
            end
            MenuStripManager[self]=nil
        end



        function Draw.MenuStrip:SetPos(args)
            self.isAbsoluteChildPos = args.isAbsoluteChildPos or false
            if args.childPos then
                self.childPos = {x = args.childPos.x, y = args.childPos.y}
            end
            self.x=args.x
            self.y=args.y
            --适配背景
            self:UpdateBG()
            self:UpdateMenus()
        end

        function Draw.MenuStrip:Add(name,index)
            if not index then
                index=#self.itemsData+1
            end
            table.insert(self.itemsData,index,{name=name})
        end

        --移除菜单的第pos项，包括它的数据
        function Draw.MenuStrip:Remove()
            --删除孩子下所有的box
            self:Hide()
            --删除孩子下所有的数据
            self:Dispose()

            collectgarbage()
        end

        function Draw.MenuStrip:Show()
            for i = 1, #self.itemsData do
                self.items[i]=self.items[i] or Draw.MenuStrip.Item:Create()
            end
            --适配背景
            self:UpdateBG()
            self:UpdateMenus()
        end

        function Draw.MenuStrip:GetName(index)
            if self.itemsData[index] then
                return self.itemsData[index].name
            end
        end
        function Draw.MenuStrip:Get()
            local args={
                x=self.x,
                y=self.y,
                height = self.height,
                width = self.width,
                focusIndex = self.focusIndex
            }
            return args
        end
        function Draw.MenuStrip:Set(args)
            args.isAbsoluteChildPos=self.isAbsoluteChildPos
            self:SetPos(args)
        end
        function Draw.MenuStrip:Adaptation(mode)
            Draw.AdaptationSelf(self,mode)
        end
        function Draw.MenuStrip:SetWidthHeight(itemsWidth,itemsHeight)
            self.itemsWidth=itemsWidth
            self.itemsHeight=itemsHeight
        end
        function Draw.MenuStrip:CreateChild(index)
            self.index=index
            if self.itemsData[index] then
                self.itemsData[index].child=Draw.MenuStrip:Create({parent=self,size=self.size,itemsWidth=self.itemsWidth,itemsHeight=self.itemsHeight,childPos = self.childPos,isAbsoluteChildPos=self.isAbsoluteChildPos})
            else
                print(index..'主菜单不存在')
            end
            self.itemsData[index].child.parent = self
            return self.itemsData[index].child
        end

        function Draw.MenuStrip:UpdateBG()
            self.BG=nil
            self.focusBG=nil
            collectgarbage()
            self.BG=UI.Box.Create()
            self.focusBG=UI.Box.Create()
            self:SetBGColor(self.BGColor.r,self.BGColor.g,self.BGColor.b,self.BGColor.a)
            self.BG:Set({y=self.y,x=self.x,height=self.itemsHeight*#self.items,width=self.itemsWidth})
            if self.items[self.focusIndex] then
                self.focusBG:Set(self.items[self.focusIndex]:Get())
            end
            self.focusBG:Set(self.focusBGColor)
            if #self.items==0 then
                self.focusBG:Hide()
                self.BG:Hide()
            end
            self.width = self.BG:Get().width
            self.height = self.BG:Get().height
        end

        function Draw.MenuStrip:SetBGColor(r,g,b,a)
            self.BGColor.r=r or self.BGColor.r
            self.BGColor.g=g or self.BGColor.g
            self.BGColor.b=b or self.BGColor.b
            self.BGColor.a=a or self.BGColor.a
            self.BG:Set( self.BGColor)
        end
        function Draw.MenuStrip:SetFocusBGColor(r,g,b,a)
            self.focusBGColor.r=r or self.focusBGColor.r
            self.focusBGColor.g=g or self.focusBGColor.g
            self.focusBGColor.b=b or self.focusBGColor.b
            self.focusBGColor.a=a or self.focusBGColor.a
            self.focusBG:Set(self.focusBGColor)
            self.focusBG:Hide()
        end
        function Draw.MenuStrip:SetTextColor(r,g,b)
            self.textColor.r=r or self.textColor.r
            self.textColor.g=g or self.textColor.g
            self.textColor.b=b or self.textColor.b
            for i = 1, #self.itemsData do
                self.items[i]:Set(self,{self.textColor})
            end
        end

        function Draw.MenuStrip:SetKerning(kerning)
            self.kerning=kerning
        end

        function Draw.MenuStrip:UpdateMenus()
            for i = 1, #self.items do
                local color=self.textColor
                if self.onlyShowOnFocus==true then
                    self.items[i]:Set(self,{name=" ",index=i,r=color.r,g=color.g,b=color.b,kerning = self.kerning})
                    if self.focusIndex==i then
                        self.items[i]:Set(self,{name=self.itemsData[i].name,index=i,r=color.r,g=color.g,b=color.b,kerning = self.kerning})
                    end
                else
                    self.items[i]:Set(self,{name=self.itemsData[i].name,index=i,r=color.r,g=color.g,b=color.b,kerning = self.kerning})
                end
            end

        end

        --隐藏菜单下的所有子菜单（box删除）
        function Draw.MenuStrip:Hide()
            for i = 1, #self.itemsData do
                if  self.itemsData[i].child then
                    self.itemsData[i].child:Hide()
                end
            end
            self.OnKeyDown.A:Trigger(self)
            self.items={}
            self.BG:Hide()
            self.focusBG:Hide()
            self.focusIndex=nil
            self.focus=false
            collectgarbage()
        end
        --选项
        Draw.MenuStrip.Item={
        }
        Draw.MenuStrip.ItemArgs={
            name=-1,
            index=1,
            r=255,g=255,b=255,
            kerning = 5
        }
        function Draw.MenuStrip.ItemArgs:New()
            local args={}
            setmetatable(args,self)
            self.__index=self
            return args
        end

        function Draw.MenuStrip.Item:Create()
            local item={}
            setmetatable(item,self)
            self.__index=self
            item.OnSelect=REGISTER:New()
            item.text=DrawText:Create()
            item.setArgs=Draw.MenuStrip.ItemArgs:New()
            return item
        end

        function Draw.MenuStrip.Item:Set(menuStrip,args)
            local items=menuStrip.items
            for k,v in pairs(Draw.MenuStrip.ItemArgs) do
                self.setArgs[k]=args[k] or self.setArgs[k]
            end
            local set=self.setArgs
            local index= set.index
            local name= set.name
            local x=menuStrip.x
            local y=menuStrip.y

            y=menuStrip.y+menuStrip.itemsHeight*(index-1)
            local textColor=menuStrip.textColor
            self.text=nil
            collectgarbage()
            if name~=" " then
                self.text=DrawText:Create()
                self.text:Set({size=menuStrip.size,text=name,r=textColor.r,g=textColor.g,b=textColor.b,kerning=self.setArgs.kerning})

                if menuStrip.itemsWidth < self.text:Get().width then
                    menuStrip.itemsWidth = self.text:Get().width+50
                    self.text:Set({x=x+menuStrip.itemsWidth/2-self.text:Get().width/2,y=y+(menuStrip.itemsHeight-self.text:Get().height)/2})
                    menuStrip:UpdateBG()
                    menuStrip:UpdateMenus()
                else
                    self.text:Set({x=x+menuStrip.itemsWidth/2-self.text:Get().width/2,y=y+(menuStrip.itemsHeight-self.text:Get().height)/2})
                end
                --box123=UI.Box.Create()
                --box123:Set(self.text:Get())
            end
            self.setArgs.height= menuStrip.itemsHeight
            self.setArgs.width=menuStrip.itemsWidth
            self.setArgs.x=x
            self.setArgs.y=y
            self.name=name
            self.drawText=self.text
        end

        function Draw.MenuStrip.Item:Get()
            return self.setArgs
        end
        Framework.KeyDown.MOUSE1:Register(function(inputs)
            for k,v in pairs(MenuStripManager) do
                if v.focus then
                    v.OnKeyDown.MOUSE1:Trigger(v)
                end
            end
        end)
        Framework.KeyDown.W:Register(function(inputs)
            for k,v in pairs(MenuStripManager) do
                v.OnKeyDown.W:Trigger(v)
            end
        end)
        Framework.KeyDown.S:Register(function(inputs)
            for k,v in pairs(MenuStripManager) do
                v.OnKeyDown.S:Trigger(v)
            end
        end)
        Framework.KeyDown.A:Register(function(inputs)
            for k,v in pairs(MenuStripManager) do
                if v.OnKeyDown.A:Trigger(v) then
                    return
                end
            end
        end)
        Framework.KeyDown.D:Register(function(inputs)
            for k,v in pairs(MenuStripManager) do
                if v.OnKeyDown.D:Trigger(v) then
                    return
                end
            end
        end)
    end
    --DropDownMenu End
end


function Draw:DoMove(startPos,endPos,time,type)
    DoMoveManager:Add(self,startPos,endPos,time,type)
end
function Draw:DoColor(startColor,endColor,time,type)
    DoColorManager:Add(self,startColor,endColor,time,type)
end
function Draw:DoScale(startSize,endSize,time,type)
    DoScaleManager:Add(self,startSize,endSize,time,type)
end

function DrawText:DoMove(startPos,endPos,time,type)
    self:Set({x=startPos.x,y=startPos.y})
    DoMoveManager:Add(self,startPos,endPos,time,type)
end
function DrawText:DoColor(startColor,endColor,time,type)
    DoColorManager:Add(self,startColor,endColor,time,type)
end
function DrawText:DoScale(startSize,endSize,time,type)
    DoScaleManager:Add(self,startSize,endSize,time,type)
end

function DrawPicture:DoMove(startPos,endPos,time,type)
    self:Set({x=startPos.x,y=startPos.y})
    DoMoveManager:Add(self,startPos,endPos,time,type)
end
function DrawPicture:DoScale(startSize,endSize,time,type)
    DoScaleManager:Add(self,startSize,endSize,time,type)
end

DoMoveManager={
    List={}
}
DoColorManager={
    List={}
}
DoScaleManager={
    List={}
}
function DoMoveManager:Add(ui,startPos,endPos,time,type)
    Do.Add(self,ui,startPos,endPos,time,type)
end
function DoScaleManager:Add(ui,startScale,endScale,time,doType)
    Do.Add(self,ui,startScale,endScale,time,doType)
    if type(startScale) == "table" then
        ui:Set({width=startScale.width,height=startScale.height})
    end
end
function DoColorManager:Add(ui,startColor,endColor,time,type)
    startColor.a=startColor.a or 255
    endColor.a=endColor.a or 255
    Do.Add(self,ui,startColor,endColor,time,type)
end

Do={
    OnDo=REGISTER:New(),
    OnStart=REGISTER:New(),
    OnEnd=REGISTER:New()
}
DoMoveManager=setmetatable(DoMoveManager,{__index=Do})
DoScaleManager=setmetatable(DoScaleManager,{__index=Do})
DoColorManager=setmetatable(DoColorManager,{__index=Do})

function Do:GetInfo(ui)
    local tab={}
    tab.ui= self.List[ui][1]
    tab.timeCount= self.List[ui][2]
    tab.startTab= self.List[ui][3]
    tab.endTab= self.List[ui][4]
    tab.time= self.List[ui][5]
    tab.type= self.List[ui][6]
    return tab
end
function Do:Add(ui,startTab,endTab,time,type)
    self.List[ui]={ui,0,startTab,endTab,time,type}
end
function Do:ChangeEndTab(ui,endTab)
    self.List[ui][4]=endTab
end
function Do:OnUpdate()
    local count=0
    for k,v in pairs(self.List) do
        if v[2]==0 then
            if self == DoMoveManager then
                if type (v[1].OnDoMoveStart)~="function" then
                    v[1].OnDoMoveStart:Trigger()
                else
                    v[1]:OnDoMoveStart()
                end
            end
            if self == DoScaleManager then
                if type (v[1].OnDoScaleStart)~="function" then
                    v[1].OnDoScaleStart:Trigger()
                else
                    v[1]:OnDoScaleStart()
                end
            end
            if self == DoColorManager then
                if type (v[1].OnDoColorStart)~="function" then
                    v[1].OnDoColorStart:Trigger()
                else
                    v[1]:OnDoColorStart()
                end
            end
            self.OnStart:Trigger(v[1])
        end

        v[2]=v[2]+Time.deltaTime
        local tmp=Evaluate(v[6],v[2],v[5])
        Do.Set(self,v,tmp)
        self.OnDo:Trigger(v[1])
        if self == DoMoveManager then
            if type (v[1].OnDoMove)~="function" then
                v[1].OnDoMove:Trigger()
            else
                v[1]:OnDoMove()
            end
        end
        if self == DoScaleManager then
            if type (v[1].OnDoScale)~="function" then
                v[1].OnDoScale:Trigger()
            else
                v[1]:OnDoScale()
            end
        end
        if self == DoColorManager then
            if type (v[1].OnDoColor)~="function" then
                v[1].OnDoColor:Trigger()
            else
                v[1]:OnDoColor()
            end
        end
        if tmp>0.999999 or v[2]>v[5] then
            self.OnEnd:Trigger(v[1])
            self.List[k]=nil
            if self == DoMoveManager then
                if type (v[1].OnDoMoveEnd)~="function" then
                    v[1].OnDoMoveEnd:Trigger()
                else
                    v[1]:OnDoMoveEnd()
                end
            end
            if self == DoScaleManager then
                if type (v[1].OnDoScaleEnd)~="function" then
                    v[1].OnDoScaleEnd:Trigger()
                else
                    v[1]:OnDoScaleEnd()
                end
            end
            if self == DoColorManager then
                if type (v[1].OnDoColorEnd)~="function" then
                    v[1].OnDoColorEnd:Trigger()
                else
                    v[1]:OnDoColorEnd()
                end
            end
        end
    end
end
--tmp[0,1]
function Do:Set(v,tmp)
    if self==DoColorManager then
        v[1]:Set({r=v[3].r+(v[4].r-v[3].r)*tmp,g=v[3].g+(v[4].g-v[3].g)*tmp,b=v[3].b+(v[4].b-v[3].b)*tmp,a=v[3].a+(v[4].a-v[3].a)*tmp})
    end
    if self==DoMoveManager then
        v[1]:Set({x=v[3].x+(v[4].x-v[3].x)*tmp,y=v[3].y+(v[4].y-v[3].y)*tmp})
    end
    if self==DoScaleManager then
        local addWidth = (v[4].width-v[3].width)*tmp
        local addHeight = (v[4].height-v[3].height)*tmp
        v[1]:Set({width=v[3].width+addWidth,
                  height=v[3].height+addHeight
        })
    end
end
if Framework then
    Framework.UIPlug.OnUpdate:Register(function()
        DoMoveManager:OnUpdate()
        DoColorManager:OnUpdate()
        DoScaleManager:OnUpdate()
    end)
end

Panel={
    x=0,
    y=0,
    width=UI.ScreenSize().width,
    height=UI.ScreenSize().height,
    name="panel_1",
    mode="leftUp",
    parent=nil
}
function Panel:New(name,x,y,width,height)
    local panel = {}
    setmetatable(panel,self)
    self.__index=self
    panel.width=width
    panel.height=height
    panel.x=x
    panel.y=y
    panel.name=name
    panel.childPanels={}
    panel.items={}
    return panel
end
--根据父节点相对位置添加
function Panel:AddPanel(name,percentageX,percentageY,percentageWidth,percentageHeight)
    local x,y,width,height=self:GetInfoWhenAdd(percentageX,percentageY,percentageWidth,percentageHeight)
    local panel=Panel:New(name,x,y,width,height)
    panel.parent=self
    --面板的子节点不允许重名
    if not self.childPanels[name] then
        self.childPanels[name]=panel
        self[name]=panel
    else
        print(self.name.."面板的子面板"..name.."重名")
    end
    return panel
end
function Panel:AddPicture(name,pictureName,percentageX,percentageY,percentageWidth,percentageHeight)
    self:AddPanel(name,percentageX,percentageY,percentageWidth,percentageHeight)
    local item=DrawPicture:Create()
    item:Set({picture=pictureName})
    self:AddItem(name,item,percentageX,percentageY,percentageWidth,percentageHeight)
end
function Panel:AddText(name,text,percentageX,percentageY,percentageWidth,percentageHeight,r,g,b)
    self:AddPanel(name,percentageX,percentageY,percentageWidth,percentageHeight)
    local item=DrawText:Create()
    item:Set({text=text,r=r,g=g,b=b})
    self:AddItem(name,item,percentageX,percentageY,percentageWidth,percentageHeight)
end
function Panel:AddUIBox(name,percentageX,percentageY,percentageWidth,percentageHeight,r,g,b)
    self:AddPanel(name,percentageX,percentageY,percentageWidth,percentageHeight)
    local item=UI.Box.Create()
    item:Set({r=r,g=g,b=b})
    self:AddItem(name,item,percentageX,percentageY,percentageWidth,percentageHeight)
end
function Panel:AddUIText(name,text,percentageX,percentageY,percentageWidth,percentageHeight,r,g,b)
    self:AddPanel(name,percentageX,percentageY,percentageWidth,percentageHeight)
    local item=UI.Text.Create()
    item:Set({text=text,r=r,g=g,b=b})
    self:AddItem(name,item,percentageX,percentageY,percentageWidth,percentageHeight)
end
function Panel:SetMode(mode)
    if not self.parent then
        print("根节点不能设置适配模式")
        return
    end
    local pos
    local parent=self.parent:Get()
    if mode == "center" and self.mode~="center" then
        pos={x=parent.x+parent.width/2,y=parent.y+parent.height/2}
        for k,v in pairs(self.childPanels) do
            local child=v:Get()
            v:Set({x=child.x+pos.x-child.width/2,
                   y=child.y+pos.y-child.height/2 })
        end
        self.mode="center"
    end
    if mode == "upCenter" and self.mode~="upCenter" then
        pos={x=parent.x+parent.width/2,y=parent.y}
        for k,v in pairs(self.childPanels) do
            local child=v:Get()
            v:Set({x=child.x+pos.x-child.width/2,
                   y=child.y+pos.y})
        end
        self.mode="upCenter"
    end
    if not mode then
        self.mode="leftUp"
        for k,v in pairs(self.childPanels) do
            v:Set({x=self.x, y=self.y })
        end
    end
end

function Panel:Set(args)
    local origin=self:Get()
    local offSetX=args.x-origin.x
    local offSetY=args.y-origin.y
    for k,v in pairs(self.childPanels) do
        v:Set(args)
    end

    for k,v in pairs(self.items) do
        local item=v:Get()
        v:Set({x=item.x+offSetX,y=item.y+offSetY,width=item.width,height=item.height})
    end

    self.x=args.x
    self.y=args.y
end
function Panel:Get()
    return {x=self.x,y=self.y,height=self.height,width=self.width}
end
function Panel:GetInfoWhenAdd(percentageX,percentageY,percentageWidth,percentageHeight)
    local width=nil
    local height=nil
    if percentageWidth then
        width=self.width*percentageWidth
    end
    if percentageHeight then
        height=self.height*percentageHeight
    end
    return self.x+self.width*percentageX,self.y+self.height*percentageY,width,height
end
function Panel:AddItem(name,item,percentageX,percentageY,percentageWidth,percentageHeight)
    --面板的子内容不允许重名
    if not self.items[name] then
        local x,y,width,height=self:GetInfoWhenAdd(percentageX,percentageY,percentageWidth,percentageHeight)
        self.items[name]=item
        self.items[name]:Set({x=x,y=y,width=width,height=height})
    else
        print(self.name.."面板的子节点"..name.."重名")
    end

end

function Panel:DoMove(startPos,endPos,time,type)
    local panelPos=self:Get()
    for k,v in pairs(self.items) do
        local item=v:Get()
        v:DoMove({x=item.x+panelPos.x+startPos.x,y=item.y+panelPos.y+startPos.y},
                {x=item.x+panelPos.x+endPos.x,y=item.y+panelPos.y+endPos.y},time,type)
    end
    for k,v in pairs(self.childPanels) do
        local child=v:Get()
        v:DoMove({x=panelPos.x+startPos.x+child.x,y=panelPos.y+startPos.y+child.y},
                {x=panelPos.x+child.x+endPos.x,y=panelPos.y+child.y+endPos.y},time,type)
    end
end



--function Panel:DoScale(startScale,endScale,time,type)
--    local panelPos=self:Get()
--    for k,v in pairs(self.items) do
--        local item=v:Get()
--        v:DoScale({width=item.width+panelPos.width+startScale.width,height=item.height+panelPos.height+startScale.height},
--                {width=item.width+panelPos.width+endScale.width,height=item.height+panelPos.height+endScale.height},time,type)
--    end
--    for k,v in pairs(self.childPanels) do
--        local child=v:Get()
--        v:DoScale({width=panelPos.width+startScale.width+child.width,height=panelPos.height+startScale.height+child.height},
--                {width=panelPos.width+child.width+endScale.width,height=panelPos.height+child.height+endScale.height},time,type)
--    end
--end

