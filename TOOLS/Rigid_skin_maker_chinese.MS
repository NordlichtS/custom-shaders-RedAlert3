-- NORDLICHT的机械体绑定脚本，赶在我的chatgpt会员到期最后一天搓出来了

global list1 = #()
global list2 = #()
global list3 = #()
global baseObj = undefined  -- Make baseObj global so we can reference it between button actions

-- 第一步，过滤一遍所有的物体，选出能绑定的
fn filterAndPrepareObjects = (
    local validObjects = #()
    local sceneObjects = objects as array

    -- 过滤条件
    for obj in sceneObjects do (
        if isValidNode obj and 
           (isKindOf obj Editable_Mesh or isKindOf obj Editable_Poly) and 
           isValidNode obj.parent and obj.modifiers.count == 0 then 
        (  
            append validObjects obj  
        )
    )

    -- 打开选择窗口
    local userSelection = selectByName title:"Select Objects for Binding" objs:validObjects multiple:true preselect:#()
    list1 = #()
    list2 = #()

    -- Populate lists based on selection
    for obj in userSelection do (
        append list1 obj
        append list2 obj.parent
    )

    simpleRigidBindTool.lblOutput.text = "找到了可以绑定的零件数量: " + list1.count as string
)

-- 第二步，复制所有零件做成列表
fn copyAndPrepareGeometry = (
    list3 = for obj in list1 collect (
        local copiedObj = copy obj
        if isValidNode copiedObj then (
            convertToPoly copiedObj  -- Convert to Editable Poly
            if copiedObj.material != undefined do (
                delete copiedObj.material  -- Delete material safely if it exists
            )
            copiedObj.parent = undefined  -- Unlink from parent
        )
        copiedObj  -- Return copied object for list3
    )
)

-- 第三步，在世界坐标中心创建一个base小方块，转成可编辑多边形
fn createBaseSkinWithDummy = (
    local dummy = Box width:0.0001 length:0.0001 height:0.0001 wirecolor:green
    convertToPoly dummy
    dummy.name = "NEWSKIN"
    dummy  -- Return the base object with dummy geometry retained
)

-- 第四步，把所有骨骼加进新的蒙皮修改器里
fn addBonesAndRetrieveIDs skinMod = (
    local boneIDMap = #()
    for i = 1 to list2.count do (
        if isValidNode list2[i] then (
            skinOps.addBone skinMod list2[i] 1
            -- 因为重复骨骼存在，必须在修改器里重新挖一遍，正确的骨骼ID列表
            for b = 1 to skinOps.GetNumberBones skinMod do (
                if skinOps.GetBoneNode skinMod b == list2[i] then (
                    append boneIDMap b
                    exit
                )
            )
        )
    )
    boneIDMap  -- Return array of bone IDs
)

-- 第五步，附加所有几何体，然后对应顶点与各自骨骼
fn attachObjectsAndPopulateBoneIDs baseObj boneIDMap = (
    local vertexBoneIDs = #()

    -- 需要在数组里保留占位物体的几个顶点，不然会错位
    local numDummyVerts = polyOp.getNumVerts baseObj
    for i = 1 to numDummyVerts do (
        append vertexBoneIDs boneIDMap[1]  -- Assign first bone ID for dummy vertices
    )

    -- Attach objects one by one and populate bone IDs for new vertices
    for i = 1 to list3.count do (
        if isValidNode list3[i] then (
            local objName = list3[i].name
            local numVertsBefore = polyOp.getNumVerts baseObj
            convertToPoly list3[i]  -- Convert to Editable Poly
            polyOp.attach baseObj list3[i]
            local numVertsAfter = polyOp.getNumVerts baseObj
            local numNewVerts = numVertsAfter - numVertsBefore

            -- Assign bone IDs for each vertex of the newly attached object
            local boneID = boneIDMap[i]
            if boneID != undefined then (
                for v = 1 to numNewVerts do (
                    append vertexBoneIDs boneID
                )
            )
            simpleRigidBindTool.lblOutput.text =  "已完成: " + i as string + "\n 总共: " + list3.count as string + "\n 当前零件: " + objName as string 
        )
    )
    vertexBoneIDs  -- Return the full array of bone IDs for all vertices
)

-- 第六步，根据之前估算出的列表给每个顶点加上权重
fn finalizeVertexAssignments skinMod vertexBoneIDs = (
    -- Apply weights to all vertices
    for v = 1 to vertexBoneIDs.count do (
        skinOps.SetVertexWeights skinMod v vertexBoneIDs[v] 1.0
    )
)

-- 确保创建一个base物体的函数（这个好像有点画蛇添足？可以删了）
fn initializeBaseObject = (
    baseObj = createBaseSkinWithDummy()
    baseObj != undefined  -- Return true if baseObj was created successfully
)

-- 最重要的方程，用来把所有东西合并成一个蒙皮
fn combineIntoSkinnedMesh = (
    -- max禁止对没有顶点的空物体进行ploy操作，所以要确保有个base小方块
    if not initializeBaseObject() then return false

    local skinMod = Skin()
    addModifier baseObj skinMod

    if not (isKindOf skinMod Skin) then (
        simpleRigidBindTool.lblOutput.text = "Error: 无法添加蒙皮修改器到 " + baseObj.name
        return false
    )

    -- 获取 bone IDs 然后把几何体都贴上去
    local boneIDMap = addBonesAndRetrieveIDs skinMod
    local vertexBoneIDs = attachObjectsAndPopulateBoneIDs baseObj boneIDMap

    -- 最后过一遍权重
    finalizeVertexAssignments skinMod vertexBoneIDs

    simpleRigidBindTool.lblOutput.text = "新蒙皮创建完成，总骨骼数：" + list2.count as string + "\n 请检查NEWSKIN，没有问题就可以把绑定前的零件删了"
)

-- Rollout UI 用户界面，用来触发其他功能
rollout simpleRigidBindTool "Simple Rigid Bind Tool" width:320 height:320
(

    label lblGuide "请确保你要绑定的几何体，已经连接到各自的父对象（即骨骼）而且已经塌陷所有修改器！\n 点击start后，按住ctrl多选你要绑的几何体，再确定，他们会变成蒙皮。\n 骨骼不要选。已绑定过的几何体不要选，可以先去掉蒙皮再重新绑定。 \n 中间的小方块是脚本必要的，可以绑定好后手动删掉" \
    align:#left offset:[10,10] height:120 width:280 

    button btnStart "Start" pos:[10,120] width:200 height:40
    label lblOutput "这行用来输出进度。\n 此脚本在max2023已经运行成功。不清楚在max9中 \n 或与w3x工具同时使用的兼容性。 \n 似乎w3x工具会阻止脚本的批量复制。需进一步测试" \ 
    align:#left offset:[10,40] height:100


    on btnStart pressed do (
        filterAndPrepareObjects()
        if list1.count > 0 then (
            copyAndPrepareGeometry()
            combineIntoSkinnedMesh()
        ) else (
            simpleRigidBindTool.lblOutput.text = "你所选的物体中，没有符合绑定条件的，请检查"
        )
    )
)

createdialog simpleRigidBindTool
