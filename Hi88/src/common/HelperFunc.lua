require ("json")

WIN_SIZE = cc.Director:getInstance():getWinSize()


Helper = {}
local sharedDirector         = cc.Director:getInstance()
local sharedTextureCache     = cc.Director:getInstance():getTextureCache()
local sharedSpriteFrameCache = cc.SpriteFrameCache:getInstance()
local sharedAnimationCache   = cc.AnimationCache:getInstance()

function Helper.setTimeout(target, time, callback)
    target.updateCount = 0
    target:scheduleUpdateWithPriorityLua(function()
        target.updateCount = target.updateCount + 1
        if target.updateCount > time then
            target:unscheduleUpdate()
            target.updateCount = nil
            callback()
        end
    end, 1)
end

function Helper.clearTimeout(target)
    target:unscheduleUpdate()
end


Helper.TEXTURES_PIXEL_FORMAT = {}
--[[--

设置材质格式。


为了节约内存，我们会使用一些颜色品质较低的材质格式，例如针对背景图使用 cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565 格式。

display.setTexturePixelFormat() 可以指定材质文件的材质格式，这样在加载材质文件时就会使用指定的格式。

@param string filename 材质文件名
@param integer format 材质格式

@see Texture Pixel Format

]]
function Helper.setTexturePixelFormat(filename, format)
    Helper.TEXTURES_PIXEL_FORMAT[filename] = format
end

--[[--

将指定的 Sprite Sheets 材质文件及其数据文件载入图像帧缓存。

格式：

Helper.addSpriteFrames(数据文件名, 材质文件名)

~~~ lua

Helper.addSpriteFrames("Sprites.plist", "Sprites.png")

~~~

Sprite Sheets 通俗一点解释就是包含多张图片的集合。Sprite Sheets 材质文件由多张图片组成，而数据文件则记录了图片在材质文件中的位置等信息。

@param string plistFilename 数据文件名
@param string image 材质文件名

@see Sprite Sheets

]]
function Helper.addSpriteFrames(plistFilename, image, handler)
    local async = type(handler) == "function"
    local asyncHandler = nil
    if async then
        asyncHandler = function()
            -- printf("%s, %s async done.", plistFilename, image)
            local texture = sharedTextureCache:textureForKey(image)
            assert(texture, string.format("The texture %s, %s is unavailable.", plistFilename, image))
            sharedSpriteFrameCache:addSpriteFrames(plistFilename, texture)
            handler(plistFilename, image)
        end
    end

    if Helper.TEXTURES_PIXEL_FORMAT[image] then
        cc.Texture2D:setDefaultAlphaPixelFormat(Helper.TEXTURES_PIXEL_FORMAT[image])
        if async then
            sharedTextureCache:addImageAsync(image, asyncHandler)
        else
            sharedSpriteFrameCache:addSpriteFrames(plistFilename, image)
        end
        cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888)
    else
        if async then
            sharedTextureCache:addImageAsync(image, asyncHandler)
        else
            sharedSpriteFrameCache:addSpriteFrames(plistFilename, image)
        end
    end
end

--[[--

从图像帧缓存中删除一个图像。

有时候，某些图像仅在特定场景中使用，例如背景图。那么在场景退出时，就可以用 display.removeSpriteFrameByImageName() 从缓存里删除不再使用的图像数据。

此外，Scene 提供了 markAutoCleanupImage() 接口，可以指定场景退出时需要自动清理的图像，推荐使用。

@param string imageName 图像文件名

]]
function Helper.removeSpriteFrameByImageName(imageName)
    sharedSpriteFrameCache:removeSpriteFrameByName(imageName)
    cc.Director:getInstance():getTextureCache():removeTextureForKey(imageName)
end

--[[--

从内存中卸载 Sprite Sheets 材质和数据文件

@param string plistFilename 数据文件名
@param string image 材质文件名

]]
function Helper.removeSpriteFramesWithFile(plistFilename, imageName)
    sharedSpriteFrameCache:removeSpriteFramesFromFile(plistFilename)
    if imageName then
        Helper.removeSpriteFrameByImageName(imageName)
    end
end

--[[--

创建并返回一个图像帧对象。

~~~ lua

Helper.addSpriteFrames("Sprites.plist", "Sprites.png")

-- 创建一个 Sprite
local sprite = Helper.newSprite("#Yes.png")

-- 创建一个图像帧
local frameNo = Helper.newSpriteFrame("No.png")

-- 在需要时，修改 Sprite 的显示内容
sprite:setDisplayFrame(frameNo)

~~~

@param string 图像帧名称

@return SpriteFrameCache

]]
function Helper.newSpriteFrame(frameName)
    local frame = sharedSpriteFrameCache:getSpriteFrame(frameName)
    if not frame then
        printError("display.newSpriteFrame() - invalid frameName %s", tostring(frameName))
    end
    return frame
end


--[[--

以特定模式创建一个包含多个图像帧对象的数组。

~~~ lua

-- 创建一个数组，包含 Walk0001.png 到 Walk0008.png 的 8 个图像帧对象
local frames = display.newFrames("Walk%04d.png", 1, 8)

-- 创建一个数组，包含 Walk0008.png 到 Walk0001.png 的 8 个图像帧对象
local frames = display.newFrames("Walk%04d.png", 1, 8, true)

~~~

@param string pattern 模式字符串
@param integer begin 起始索引
@param integer length 长度
@param boolean isReversed 是否是递减索引

@return table 图像帧数组

]]
function Helper.newFrames(pattern, begin, length, isReversed)
    local frames = {}
    local step = 1
    local last = begin + length - 1
    if isReversed then
        last, begin = begin, last
        step = -1
    end

    for index = begin, last, step do
        local frameName = string.format(pattern, index)
        local frame = sharedSpriteFrameCache:getSpriteFrame(frameName)
        if not frame then
            printError("display.newFrames() - invalid frame, name %s", tostring(frameName))
            return
        end

        frames[#frames + 1] = frame
    end
    return frames
end

--[[--

以包含图像帧的数组创建一个动画对象。

~~~ lua

local frames = display.newFrames("Walk%04d.png", 1, 8)
local animation = display.newAnimation(frames, 0.5 / 8) -- 0.5 秒播放 8 桢
sprite:playAnimationOnce(animation) -- 播放一次动画

~~~

@param table frames 图像帧的数组
@param number time 每一桢动画之间的间隔时间


@return Animation Animation对象

]]
function Helper.newAnimation(frames, time)
    local count = #frames
    -- local array = Array:create()
    -- for i = 1, count do
    --     array:addObject(frames[i])
    -- end
    time = time or 1.0 / count
    return cc.Animation:createWithSpriteFrames(frames, time)
end

--[[

以指定名字缓存创建好的动画对象，以便后续反复使用。

~~~ lua

local frames = display.newFrames("Walk%04d.png", 1, 8)
local animation = display.newAnimation(frames, 0.5 / 8) -- 0.5 秒播放 8 桢
display.setAnimationCache("Walk", animation)

-- 在需要使用 Walk 动画的地方
sprite:playAnimationOnce(display.getAnimationCache("Walk")) -- 播放一次动画

~~~

@param string name 名字
@param Animation animation 动画对象


]]
function Helper.setAnimationCache(name, animation)
    sharedAnimationCache:addAnimation(animation, name)
end

--[[--

取得以指定名字缓存的动画对象，如果不存在则返回 nil。

@param string name

@return Animation

]]
function Helper.getAnimationCache(name)
    return sharedAnimationCache:getAnimation(name)
end

--[[--

删除指定名字缓存的动画对象。

@param string name

]]
function Helper.removeAnimationCache(name)
    sharedAnimationCache:removeAnimationByName(name)
end

function Helper.removeUnusedSpriteFrames()
    sharedSpriteFrameCache:removeUnusedSpriteFrames()
    sharedTextureCache:removeUnusedTextures()
end

function Helper.graySprite(sprite)
    if sprite then
        local shader = cc.GLProgram:create("shader/gray.vsh", "shader/gray.fsh")
        --shader:retain()
        shader:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION, cc.VERTEX_ATTRIB_POSITION)
        shader:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR, cc.VERTEX_ATTRIB_COLOR)
        shader:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD, cc.VERTEX_ATTRIB_TEX_COORDS)
        shader:link()
        shader:updateUniforms()
        sprite:setGLProgram(shader)
    end
end

function Helper.createNpcArmature(id)
    local map = require "config.define_npc_map"
    local npcInfoTab = require "config.define_npcs_info"
    local npcId = map[tostring(id)]
    local npcInfo = npcInfoTab[tostring(npcId)]
    local armatureFile = "image/battle/armature/"..npcInfo.name.."/"..npcInfo.name..".csb"
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(armatureFile)
    local armature = ccs.Armature:create(npcInfo.name)
    armature:getAnimation():playWithIndex(0)
    ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(armatureFile)
    return armature
end

------------------------------print JSON-------------------------------
function printJSON(t)
    if type(t) ~= "table" then
        cclog("print only support table")
        return
    end
    cclog(json.encode(t))
end

------------------------Flowing code from quick-cocos2d-x--------------------------------
function iskindof(obj, classname)
    local t = type(obj)
    local mt
    if t == "table" then
        mt = getmetatable(obj)
    elseif t == "userdata" then
        mt = tolua.getpeer(obj)
    end

    while mt do
        if mt.__cname == classname then
            return true
        end
        mt = mt.super
    end

    return false
end

--[[--

如果表格中指定 key 的值为 nil，或者输入值不是表格，返回 false，否则返回 true

@param table hashtable 要检查的表格
@param mixed key 要检查的键名

@return boolean

]]
function isset(hashtable, key)
    local t = type(hashtable)
    return (t == "table" or t == "userdata") and hashtable[key] ~= nil
end


--[[--

根据系统时间初始化随机数种子，让后续的 math.random() 返回更随机的值

]]
function math.newrandomseed()
    local ok, socket = pcall(function()
        return require("socket")
    end)

    if ok then
        -- 如果集成了 socket 模块，则使用 socket.gettime() 获取随机数种子
        math.randomseed(socket.gettime() * 1000)
    else
        math.randomseed(os.time())
    end
    math.random()
    math.random()
    math.random()
    math.random()
end

--[[--

对数值进行四舍五入，如果不是数值则返回 0

@param number value 输入值

@return number

]]
function math.round(value)
    return math.floor(value + 0.5)
end

function math.angle2radian(angle)
    return angle*math.pi/180
end

function math.radian2angle(radian)
    return radian/math.pi*180
end

--[[--

检查指定的文件或目录是否存在，如果存在返回 true，否则返回 false

可以使用 cc.FileUtils:fullPathForFilename() 函数查找特定文件的完整路径，例如：

~~~ lua

local path = cc.FileUtils:getInstance():fullPathForFilename("gamedata.txt")
if io.exists(path) then
....
end

~~~

@param string path 要检查的文件或目录的完全路径

@return boolean

]]
function io.exists(path)
    local file = io.open(path, "r")
    if file then
        io.close(file)
        return true
    end
    return false
end

--[[--

读取文件内容，返回包含文件内容的字符串，如果失败返回 nil

io.readfile() 会一次性读取整个文件的内容，并返回一个字符串，因此该函数不适宜读取太大的文件。

@param string path 文件完全路径

@return string

]]
function io.readfile(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        io.close(file)
        return content
    end
    return nil
end

--[[--

以字符串内容写入文件，成功返回 true，失败返回 false

"mode 写入模式" 参数决定 io.writefile() 如何写入内容，可用的值如下：

-   "w+" : 覆盖文件已有内容，如果文件不存在则创建新文件
-   "a+" : 追加内容到文件尾部，如果文件不存在则创建文件

此外，还可以在 "写入模式" 参数最后追加字符 "b" ，表示以二进制方式写入数据，这样可以避免内容写入不完整。

**Android 特别提示:** 在 Android 平台上，文件只能写入存储卡所在路径，assets 和 data 等目录都是无法写入的。

@param string path 文件完全路径
@param string content 要写入的内容
@param [string mode] 写入模式，默认值为 "w+b"

@return boolean

]]
function io.writefile(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

--[[--

拆分一个路径字符串，返回组成路径的各个部分

~~~ lua

local pathinfo  = io.pathinfo("/var/app/test/abc.png")

-- 结果:
-- pathinfo.dirname  = "/var/app/test/"
-- pathinfo.filename = "abc.png"
-- pathinfo.basename = "abc"
-- pathinfo.extname  = ".png"

~~~

@param string path 要分拆的路径字符串

@return table

]]
function io.pathinfo(path)
    local pos = string.len(path)
    local extpos = pos + 1
    while pos > 0 do
        local b = string.byte(path, pos)
        if b == 46 then -- 46 = char "."
            extpos = pos
        elseif b == 47 then -- 47 = char "/"
            break
        end
        pos = pos - 1
    end

    local dirname = string.sub(path, 1, pos)
    local filename = string.sub(path, pos + 1)
    extpos = extpos - pos
    local basename = string.sub(filename, 1, extpos - 1)
    local extname = string.sub(filename, extpos)
    return {
        dirname = dirname,
        filename = filename,
        basename = basename,
        extname = extname
    }
end

--[[--

返回指定文件的大小，如果失败返回 false

@param string path 文件完全路径

@return integer

]]
function io.filesize(path)
    local size = false
    local file = io.open(path, "r")
    if file then
        local current = file:seek()
        size = file:seek("end")
        file:seek("set", current)
        io.close(file)
    end
    return size
end

--[[--

计算表格包含的字段数量

Lua table 的 "#" 操作只对依次排序的数值下标数组有效，table.nums() 则计算 table 中所有不为 nil 的值的个数。

@param table t 要检查的表格

@return integer

]]
function table.nums(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

--[[--

返回指定表格中的所有键

~~~ lua

local hashtable = {a = 1, b = 2, c = 3}
local keys = table.keys(hashtable)
-- keys = {"a", "b", "c"}

~~~

@param table hashtable 要检查的表格

@return table

]]
function table.keys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end

--[[--

返回指定表格中的所有值

~~~ lua

local hashtable = {a = 1, b = 2, c = 3}
local values = table.values(hashtable)
-- values = {1, 2, 3}

~~~

@param table hashtable 要检查的表格

@return table

]]
function table.values(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end

--[[--

将来源表格中所有键及其值复制到目标表格对象中，如果存在同名键，则覆盖其值

~~~ lua

local dest = {a = 1, b = 2}
local src  = {c = 3, d = 4}
table.merge(dest, src)
-- dest = {a = 1, b = 2, c = 3, d = 4}

~~~

@param table dest 目标表格
@param table src 来源表格

]]
function table.merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

--[[--

在目标表格的指定位置插入来源表格，如果没有指定位置则连接两个表格

~~~ lua

local dest = {1, 2, 3}
local src  = {4, 5, 6}
table.insertto(dest, src)
-- dest = {1, 2, 3, 4, 5, 6}

dest = {1, 2, 3}
table.insertto(dest, src, 5)
-- dest = {1, 2, 3, nil, 4, 5, 6}

~~~

@param table dest 目标表格
@param table src 来源表格
@param [integer begin] 插入位置

]]
function table.insertto(dest, src, begin)
    begin = checkint(begin)
    if begin <= 0 then
        begin = #dest + 1
    end

    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end

--[[

从表格中查找指定值，返回其索引，如果没找到返回 false

~~~ lua

local array = {"a", "b", "c"}
print(table.indexof(array, "b")) -- 输出 2

~~~

@param table array 表格
@param mixed value 要查找的值
@param [integer begin] 起始索引值

@return integer

]]
function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then return i end
    end
    return false
end

--[[--

从表格中查找指定值，返回其 key，如果没找到返回 nil

~~~ lua

local hashtable = {name = "dualface", comp = "chukong"}
print(table.keyof(hashtable, "chukong")) -- 输出 comp

~~~

@param table hashtable 表格
@param mixed value 要查找的值

@return string 该值对应的 key

]]
function table.keyof(hashtable, value)
    for k, v in pairs(hashtable) do
        if v == value then return k end
    end
    return nil
end

--[[--

从表格中删除指定值，返回删除的值的个数

~~~ lua

local array = {"a", "b", "c", "c"}
print(table.removebyvalue(array, "c", true)) -- 输出 2

~~~

@param table array 表格
@param mixed value 要删除的值
@param [boolean removeall] 是否删除所有相同的值

@return integer

]]
function table.removebyvalue(array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table.remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end
 
-- Remove key k (and its value) from table t. Return a new (modified) table.
function table.removeKey(t, k)
    local i = 0
    local keys, values = {},{}
    for k,v in pairs(t) do
        i = i + 1
        keys[i] = k
        values[i] = v
    end
 
    while i>0 do
        if keys[i] == k then
            table.remove(keys, i)
            table.remove(values, i)
            break
        end
        i = i - 1
    end
 
    local a = {}
    for i = 1,#keys do
        a[keys[i]] = values[i]
    end
 
    return a
end

--[[--

对表格中每一个值执行一次指定的函数，并用函数返回值更新表格内容

~~~ lua

local t = {name = "dualface", comp = "chukong"}
table.map(t, function(v, k)
-- 在每一个值前后添加括号
return "[" .. v .. "]"
end)

-- 输出修改后的表格内容
for k, v in pairs(t) do
print(k, v)
end

-- 输出
-- name [dualface]
-- comp [chukong]

~~~

fn 参数指定的函数具有两个参数，并且返回一个值。原型如下：

~~~ lua

function map_function(value, key)
return value
end

~~~

@param table t 表格
@param function fn 函数

]]
function table.map(t, fn)
    for k, v in pairs(t) do
        t[k] = fn(v, k)
    end
end

--[[--

对表格中每一个值执行一次指定的函数，但不改变表格内容

~~~ lua

local t = {name = "dualface", comp = "chukong"}
table.walk(t, function(v, k)
-- 输出每一个值
print(v)
end)

~~~

fn 参数指定的函数具有两个参数，没有返回值。原型如下：

~~~ lua

function map_function(value, key)

end

~~~

@param table t 表格
@param function fn 函数

]]
function table.walk(t, fn)
    for k,v in pairs(t) do
        fn(v, k)
    end
end

--[[--

对表格中每一个值执行一次指定的函数，如果该函数返回 false，则对应的值会从表格中删除

~~~ lua

local t = {name = "dualface", comp = "chukong"}
table.filter(t, function(v, k)
return v ~= "dualface" -- 当值等于 dualface 时过滤掉该值
end)

-- 输出修改后的表格内容
for k, v in pairs(t) do
print(k, v)
end

-- 输出
-- comp chukong

~~~

fn 参数指定的函数具有两个参数，并且返回一个 boolean 值。原型如下：

~~~ lua

function map_function(value, key)
return true or false
end

~~~

@param table t 表格
@param function fn 函数

]]
function table.filter(t, fn)
    for k, v in pairs(t) do
        if not fn(v, k) then t[k] = nil end
    end
end

--[[--

遍历表格，确保其中的值唯一

~~~ lua

local t = {"a", "a", "b", "c"} -- 重复的 a 会被过滤掉
local n = table.unique(t)

for k, v in pairs(n) do
print(v)
end

-- 输出
-- a
-- b
-- c

~~~

@param table t 表格

@return table 包含所有唯一值的新表格

]]
function table.unique(t)
    local check = {}
    local n = {}
    for k, v in pairs(t) do
        if not check[v] then
            n[k] = v
            check[v] = true
        end
    end
    return n
end

string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set["\""] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

--[[--

将特殊字符转为 HTML 转义符

~~~ lua

print(string.htmlspecialchars("<ABC>"))
-- 输出 &lt;ABC&gt;

~~~

@param string input 输入字符串

@return string 转换结果

]]
function string.htmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, k, v)
    end
    return input
end

--[[--

将 HTML 转义符还原为特殊字符，功能与 string.htmlspecialchars() 正好相反

~~~ lua

print(string.restorehtmlspecialchars("&lt;ABC&gt;"))
-- 输出 <ABC>

~~~

@param string input 输入字符串

@return string 转换结果

]]
function string.restorehtmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string.gsub(input, v, k)
    end
    return input
end

--[[--

将字符串中的 \n 换行符转换为 HTML 标记

~~~ lua

print(string.nl2br("Hello\nWorld"))
-- 输出
-- Hello<br />World

~~~

@param string input 输入字符串

@return string 转换结果

]]
function string.nl2br(input)
    return string.gsub(input, "\n", "<br />")
end

--[[--

将字符串中的特殊字符和 \n 换行符转换为 HTML 转移符和标记

~~~ lua

print(string.nl2br("<Hello>\nWorld"))
-- 输出
-- &lt;Hello&gt;<br />World

~~~

@param string input 输入字符串

@return string 转换结果

]]
function string.text2html(input)
    input = string.gsub(input, "\t", "    ")
    input = string.htmlspecialchars(input)
    input = string.gsub(input, " ", "&nbsp;")
    input = string.nl2br(input)
    return input
end

--[[--

用指定字符或字符串分割输入字符串，返回包含分割结果的数组

~~~ lua

local input = "Hello,World"
local res = string.split(input, ",")
-- res = {"Hello", "World"}

local input = "Hello-+-World-+-Quick"
local res = string.split(input, "-+-")
-- res = {"Hello", "World", "Quick"}

~~~

@param string input 输入字符串
@param string delimiter 分割标记字符或字符串

@return array 包含分割结果的数组

]]
function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

--[[--

去除输入字符串头部的空白字符，返回结果

~~~ lua

local input = "  ABC"
print(string.ltrim(input))
-- 输出 ABC，输入字符串前面的两个空格被去掉了

~~~

空白字符包括：

-   空格
-   制表符 \t
-   换行符 \n
-   回到行首符 \r

@param string input 输入字符串

@return string 结果

@see string.rtrim, string.trim

]]
function string.ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end

--[[--

去除输入字符串尾部的空白字符，返回结果

~~~ lua

local input = "ABC  "
print(string.ltrim(input))
-- 输出 ABC，输入字符串最后的两个空格被去掉了

~~~

@param string input 输入字符串

@return string 结果

@see string.ltrim, string.trim

]]
function string.rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end

--[[--

去掉字符串首尾的空白字符，返回结果

@param string input 输入字符串

@return string 结果

@see string.ltrim, string.rtrim

]]
function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

--[[--

将字符串的第一个字符转为大写，返回结果

~~~ lua

local input = "hello"
print(string.ucfirst(input))
-- 输出 Hello

~~~

@param string input 输入字符串

@return string 结果

]]
function string.ucfirst(input)
    return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

local function urlencodechar(char)
    return "%" .. string.format("%02X", string.byte(char))
end

--[[--

将字符串转换为符合 URL 传递要求的格式，并返回转换结果

~~~ lua

local input = "hello world"
print(string.urlencode(input))
-- 输出
-- hello%20world

~~~

@param string input 输入字符串

@return string 转换后的结果

@see string.urldecode

]]
function string.urlencode(input)
    -- convert line endings
    input = string.gsub(tostring(input), "\n", "\r\n")
    -- escape all characters but alphanumeric, '.' and '-'
    input = string.gsub(input, "([^%w%.%- ])", urlencodechar)
    -- convert spaces to "+" symbols
    return string.gsub(input, " ", "+")
end

--[[--

将 URL 中的特殊字符还原，并返回结果

~~~ lua

local input = "hello%20world"
print(string.urldecode(input))
-- 输出
-- hello world

~~~

@param string input 输入字符串

@return string 转换后的结果

@see string.urlencode

]]
function string.urldecode(input)
    input = string.gsub (input, "+", " ")
    input = string.gsub (input, "%%(%x%x)", function(h) return string.char(checknumber(h,16)) end)
    input = string.gsub (input, "\r\n", "\n")
    return input
end

--[[--

计算 UTF8 字符串的长度，每一个中文算一个字符

~~~ lua

local input = "你好World"
print(string.utf8len(input))
-- 输出 7

~~~

@param string input 输入字符串

@return integer 长度

]]
function string.utf8len(input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

--[[--

将数值格式化为包含千分位分隔符的字符串

~~~ lua

print(string.formatnumberthousands(1924235))
-- 输出 1,924,235

~~~

@param number num 数值

@return string 格式化结果

]]
function string.formatnumberthousands(num)
    local formatted = tostring(checknumber(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

---BY JKK-----------------------------------
--

--[[--
@param string content 要显示的内容
@param string fontName 字体
@param number fontSize 字体大小
@param ccColor3B fontColor 文本颜色
@param ccColor3B outlinecolor 描边颜色
@param lineWidth 建议1
]]

function createLabelTextAddOutline(content,fontName,fontSize,fontColor,outlinecolor,lineWidth)
        --描边CCLabelTTF 左  
        local left = ccui.Text:create()
        left:setString(content)
        left:setFontName(fontName)
        left:setFontSize(fontSize)
        left:setColor(outlinecolor)
        
   
        
        --描边CCLabelTTF 右  
        local right=ccui.Text:create()
        right:setString(content)
        right:setFontName(fontName)
        right:setFontSize(fontSize)
        right:setColor(outlinecolor)  
        right:setPosition(cc.p(left:getContentSize().width*0.5+lineWidth*2,left:getContentSize().height*0.5))  
        left:addChild(right)  

        --描边CCLabelTTF 上  
        local up=ccui.Text:create()
        up:setString(content)
        up:setFontName(fontName)
        up:setFontSize(fontSize)
        up:setColor(outlinecolor);  
        up:setPosition(cc.p(left:getContentSize().width*0.5+lineWidth,left:getContentSize().height*0.5+lineWidth))  
        left:addChild(up)  

        --描边CCLabelTTF 下  
        local down=ccui.Text:create()
        down:setString(content)
        down:setFontName(fontName)
        down:setFontSize(fontSize)
        down:setColor(outlinecolor) 
        down:setPosition(cc.p(left:getContentSize().width*0.5+lineWidth,left:getContentSize().height*0.5-lineWidth))  
        left:addChild(down)  
        
        --正文CCLabelTTF  
        local center=ccui.Text:create()
        center:setString(content)
        center:setFontName(fontName)
        center:setFontSize(fontSize)
        center:setColor(fontColor);  
        center:setPosition(cc.p(left:getContentSize().width*0.5+lineWidth,left:getContentSize().height*0.5))  
        left:addChild(center)
        
        return left
end

--[[--
根据品质获得对应的颜色
]]

function getColorByQuality(quality)
    local color = cc.c3b(255,0,0)
    
    if  quality == 5 then
        color  = cc.c3b(238,78,78)
    elseif  quality == 4 then
        color  = cc.c3b(147,41,163)
    elseif  quality == 3 then
         color  = cc.c3b(25,118,189)
    elseif  quality == 2 then
        color  = cc.c3b(42,206,77)
    elseif  quality == 1 then
        color  = cc.c3b(0,0,0);
    end
    
    return color
end

--[[--

]]

function ConvertImg2Grayscale(pic)
        local targetSprite=cc.Sprite:create(pic)
        if (targetSprite == nil) then return end
      
        local spriteSize=targetSprite:getContentSize()
        
        local img = ccui.ImageView:create("tap_01.png")
        local data = img:getDescription()
        local colorPixel = 0
        local xLen=spriteSize.width
        local yLen=spriteSize.height
        for y=1,yLen do
            for  x=1,xLen do
                colorPixel = data+y*xLen*4+x*4
                local btGray=0.3*colorPixel[1]+0.59*colorPixel[2]+0.11*colorPixel[3]
                colorPixel[1]=btGray;
                colorPixel[2]=btGray;
                colorPixel[3]=btGray;
            end
        end
        
    local texture=cc.Texture2D:initWithString(data,cc.TEXTURE2_D_PIXEL_FORMAT_DEFAULT,1.0,spriteSize,xLen,yLen)
        return texture;
end


function SpriteSetGray(sprite)
    if sprite then
        if sprite ~= nil then
            local program = cc.GLProgram:create("gray.vsh", "gray.fsh")
            program:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION, cc.VERTEX_ATTRIB_POSITION) 
            program:bindAttribLocation(cc.ATTRIBUTE_NAME_COLOR, cc.VERTEX_ATTRIB_COLOR)
            program:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD, cc.VERTEX_ATTRIB_TEX_COORDS)
            program:link()
            program:updateUniforms()
            GrayProgram = program
        end
        sprite:setGLProgram(GrayProgram)
    end
end

function PositionToAngle(startPos,endPos)
    local len_y = endPos.y - startPos.y
    local len_x = endPos.x - startPos.x

    local tan_xy = math.abs(len_x)/math.abs(len_y)
    print(" math.atan(tan_yx)"..math.atan(tan_xy))
    local angle = 0
    if(len_y > 0 and len_x < 0) then
        angle = -math.atan(tan_xy)*180/math.pi - 90
    elseif (len_y > 0 and len_x > 0) then
        angle = -90 + math.atan(tan_xy)*180/math.pi
    elseif(len_y < 0 and len_x < 0) then
        angle = math.atan(tan_xy)*180/math.pi + 90
    elseif(len_y < 0 and len_x > 0) then
        angle = -math.atan(tan_xy)*180/math.pi +90
    end
    return angle
end

function arrowStratShootPos(endPos,angle,direction)
    local x
    local len_y = math.abs(endPos.y - WIN_SIZE.height*1.1)
    local len_x = len_y/math.tan(math.rad(angle))
    local x = endPos.x - len_x*direction
    
    return cc.p(x,WIN_SIZE.height*1.1)
end

--[[--抛物线
    @param sprite mSprite 需要做抛物线的精灵  
    @param point startPoint 起始位置  
    @param point endPoint 终止位置  
    @param float startA 起始角度  
    @param float endA 中止角度 
]]
function moveWithParabola(mSprite,startPoint,endPoint,startAngle,endAngle,time)   
    local sx = startPoint.x 
    local sy = startPoint.y   
    local ex = endPoint.x+50  
    local ey = endPoint.y+150  
    local h =  mSprite:getContentSize().height*0.5
    --设置精灵的起始角度  
    --mSprite.rotation=startAngle
    mSprite:setRotation(startAngle)
    
    local bezier ={
    cc.p(sx, sy) ,
    cc.p(sx+(ex-sx)*0.5, sy+(ey-sy)*0.5+200),
    cc.p(endPoint.x-30, endPoint.y+h),
    }
    local actionMove = cc.BezierTo:create(time,bezier) 
    --创建精灵旋转的动作  
    local actionRotate =cc.RotateTo:create(time,endAngle)
    --将两个动作封装成一个同时播放进行的动作  
    local action = cc.Spawn:create(actionMove,actionRotate)  
    mSprite:runAction(action)
end

--自定义动作
MyDIYAction = {}
--[[-- 箭矢抛物线
@param point startPoint 起始位置  
@param point endPoint 终止位置  
@param float rotateAngle 旋转角度  
@param float time 时间
@param float spriteheight 精灵高度
@param float height 控制点高度
]]
function MyDIYAction.arrowParabola(startPoint,endPoint,rotateAngle,time,spriteheight,direction,height)
    local sx = startPoint.x 
    local sy = startPoint.y   
    local ex = endPoint.x+50  
    local ey = endPoint.y+150  
    local h =  spriteheight

    local angle = 0.6
    local width = WIN_SIZE.width
    local abs = math.abs(ex - sx)
    if  abs < width*0.2 then
        angle = 0.8
    elseif  abs >= width*0.2 and abs < width*0.4 then
        angle = 0.7
    elseif  abs >= width*0.4 and abs < width*0.7 then
        angle = 0.65
    end

    local bezier ={
        cc.p(sx, sy+h) , --起始点
        cc.p(sx+(ex-sx)*0.3*direction, sy+(ey-sy)*0.5+height),--控制点
        cc.p(endPoint.x+50*direction, endPoint.y+h),--结束点
    }
    local actionMove = cc.BezierTo:create(time,bezier) 
    --创建精灵旋转的动作  
    local actionDelay = cc.DelayTime:create(time*0.3)
    local actionRotate1 =cc.RotateBy:create(time*0.05,rotateAngle*(0.3+angle))
    --local actionRotate3 =cc.RotateBy:create(time*0.2,rotateAngle*0.5)
    local hide = cc.Hide:create()
    local show = cc.Show:create()
    local actionSequence = cc.Sequence:create(hide,actionDelay,actionRotate1,cc.FadeIn:create(0.15),show)
    --将两个动作封装成一个同时播放进行的动作  
    local action = cc.Spawn:create(actionMove,actionSequence)  
    return action
end
--炮弹
function MyDIYAction.MissleParabola(startPoint,endPoint,startAngle,endAngle,time,spriteHeight,misssleHeight)   
    local sx = startPoint.x 
    local sy = startPoint.y   
    local ex = endPoint.x+50  
    local ey = endPoint.y+150  
    local h =  spriteHeight*0.5
    --设置精灵的起始角度  
    --mSprite.rotation=startAngle
    

    local bezier ={
        cc.p(sx, sy) ,
        cc.p(sx+(ex-sx)*0.5, sy+(ey-sy)*0.5+misssleHeight),
        cc.p(endPoint.x-30, endPoint.y+h),
    }
    local actionMove = cc.BezierTo:create(time,bezier) 
    --创建精灵旋转的动作  
    local actionRotate =cc.RotateTo:create(time,endAngle)
    --将两个动作封装成一个同时播放进行的动作  
    local action = cc.Spawn:create(actionMove,actionRotate)  
    return action
end

function MyDIYAction.MissleParabola(startPoint,endPoint,startAngle,endAngle,time,spriteHeight,misssleHeight)   
    local sx = startPoint.x 
    local sy = startPoint.y   
    local ex = endPoint.x+50  
    local ey = endPoint.y+150  
    local h =  spriteHeight*0.5
    --设置精灵的起始角度  
    --mSprite.rotation=startAngle


    local bezier ={
        cc.p(sx, sy) ,
        cc.p(sx+(ex-sx)*0.5, sy+(ey-sy)*0.5+misssleHeight),
        cc.p(endPoint.x-30, endPoint.y+h),
    }
    local actionMove = cc.BezierTo:create(time,bezier) 
    --创建精灵旋转的动作  
    local actionRotate =cc.RotateTo:create(time,endAngle)
    --将两个动作封装成一个同时播放进行的动作  
    local action = cc.Spawn:create(actionMove,actionRotate)  
    return action
end

function MyDIYAction.MissleParabola_NoRotate(startPoint,endPoint,startAngle,endAngle,time,spriteHeight,misssleHeight)   
    local sx = startPoint.x 
    local sy = startPoint.y   
    local ex = endPoint.x+50  
    local ey = endPoint.y+150  
    local h =  spriteHeight*0.5
    --设置精灵的起始角度  
    --mSprite.rotation=startAngle


    local bezier ={
        cc.p(sx, sy) ,
        cc.p(sx+(ex-sx)*0.5, sy+(ey-sy)*0.5+misssleHeight),
        cc.p(endPoint.x-30, endPoint.y+h),
    }
    local actionMove = cc.BezierTo:create(time,bezier) 

    return actionMove
end

--弓箭射落
function MyDIYAction.arrowShotDown(startPoint,endPoint,time,direction)
    local sx = startPoint.x 
    local sy = startPoint.y   
    local ex = endPoint.x-30*direction  
    local ey = endPoint.y 
    

    
    local width = WIN_SIZE.width
    local abs = math.abs(ex - sx)
    local angle =  45
    local arrowShowPos = arrowStratShootPos(endPoint,angle,direction)
    
    --local angle =  PositionToAngle(arrowShowPos,cc.p(ex,ey))
    --创建精灵旋转的动作  
    local actionRotate =cc.RotateTo:create(time*0.2,angle)
    if  direction == -1 then
        actionRotate = cc.RotateTo:create(time*0.2,180-angle)
    end
   
    
    local hide = cc.Hide:create()
    local show = cc.Show:create()
    local actionSequence = cc.Sequence:create(hide,cc.Spawn:create(cc.MoveTo:create(time*0.2,arrowShowPos),actionRotate))
    local actionMove = cc.MoveTo:create(time*0.8,cc.p(ex,ey))
    --将两个动作封装成一个同时播放进行的动作  
    local action = cc.Sequence:create(actionSequence,show,actionMove)  
    return action
end

--[[-- 掉落
cocos2d::CCPoint startPos ,float delayTime, float _speed
]]
function MyDIYAction.fallStrikeAction(startPos,delayTime,speed)
    local scaleBy = cc.ScaleBy:create(speed , 1/3.0 , 1/3.0)
    local moveTo = cc.MoveTo:create(speed , cc.p(startPos.x - 50 , startPos.y -100))
    local fadeIn = cc.FadeIn:create(speed)
    local spawn = cc.Spawn:create(scaleBy ,fadeIn,moveTo)
    local easeElas = cc.EaseExponentialIn:create(spawn)
    local rankAct = cc.Sequence:create(
        cc.Hide:create(),
        scaleBy:reverse(),
        cc.Place:create(startPos),
        cc.DelayTime:create(delayTime),
        cc.Show:create(),
        easeElas)
    return rankAct   
end

--[[-- 掉落2
cocos2d::CCPoint startPos ,float delayTime, float _speed, endPos
]]
function MyDIYAction.fallStrikeAction2(startPos,delayTime,speed,endPos)
    local scaleBy = cc.ScaleBy:create(speed/4 , 3.0 , 3.0)
    local moveTo = cc.MoveTo:create(speed , endPos)
    local fadeIn = cc.FadeIn:create(speed)
    local xuanzhuan = cc.RotateBy:create(speed,720)
    local spawn = cc.Spawn:create(scaleBy ,fadeIn,moveTo)
    local easeElas = cc.EaseExponentialIn:create(spawn)
    local rankAct = cc.Sequence:create(
        cc.Hide:create(),
        scaleBy:reverse(),
        cc.Place:create(startPos),
        cc.DelayTime:create(delayTime),
        cc.Show:create(),
        easeElas)
    return rankAct   
end

--滚动条滚动代码
function SetSlider(scrollView,slider)
    local h = scrollView:getInnerContainer():getContentSize().height - 440 --870是你的scrollview 外框大小 
    local p = 100-(scrollView:getInnerContainer():getPositionY() / h * (-100))
    if p>100 then
        p = 100
    elseif p<0 then
        p = 0
    end
    slider:setVisible(true)
    slider:setPercent(p)
    slider:runAction(cc.Sequence:create(cc.FadeIn:create(0),cc.FadeOut:create(2),cc.Hide:create()))

end

function SetTime(TimeNum)--服务端传来的是毫秒
    
    --ShowTrueTime为得到的显示时间
    local ShowTrueTime = ""
    
    local dateNum = math.floor(TimeNum/1000)
    
    --年
    local dateYear = os.date("%Y",dateNum)
        
    --月
    local dateMonth = os.date("%m",dateNum)
        
    --日
    local dateDay = os.date("%d",dateNum)
        
    --时
    local dateHour = os.date("%H",dateNum)--24小时制
    --local dateHour = os.date("%l",dateNum_1)--12小时制
        
    --分
    local dateMinute = os.date("%M",dateNum)
        
    ShowTrueTime = string.format(ShowTrueTime..dateYear.."-"..dateMonth.."-"..dateDay)--eg,2014-11-27
    
    --ShowTrueTime = string.format(ShowTrueTime..dateYear.."-"..dateMonth.."-"..dateDay.." "..dateHour..":"..dateMinute)
    --eg,2014-11-27 18:05
    
    return ShowTrueTime
    
end	

function SetTime_2(TimeNum)--服务端传来的是秒

    --ShowTrueTime为得到的显示时间
    local ShowTrueTime_2 = ""
    
    local dateNum_1 = TimeNum
   
    --年
    local dateYear = os.date("%Y",dateNum_1)

    --月
    local dateMonth = os.date("%m",dateNum_1)

    --日
    local dateDay = os.date("%d",dateNum_1)

    --时
    local dateHour = os.date("%H",dateNum_1)--24小时制

    --local dateHour = os.date("%l",dateNum_1)--12小时制

    --分
    local dateMinute = os.date("%M",dateNum_1)
        
    ShowTrueTime_2 = string.format(ShowTrueTime_2..dateYear.."-"..dateMonth.."-"..dateDay)--eg,2014-11-27
    --ShowTrueTime_2 = string.format(ShowTrueTime_2..dateYear.."-"..dateMonth.."-"..dateDay.." "..dateHour..":"..dateMinute)
    --eg,2014-11-27 18:05

    return ShowTrueTime_2

end 

function Helper.PlayBackGroundMuisc(musicname)
    if Roler:get("settingStatus")[4] == 1 then
        cc.SimpleAudioEngine:getInstance():playMusic(musicname,true)
    end
end
	
function Helper.StopBackGroundMuisc()
    cc.SimpleAudioEngine:getInstance():stopMusic()
end

function Helper.PlayEffectMusic(effectname)
    if Roler:get("settingStatus")[4] == 1 then
        cc.SimpleAudioEngine:getInstance():playEffect(effectname)
    end
end
