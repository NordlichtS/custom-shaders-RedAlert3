-- made by Nordlicht on 2024,nov,09
-- visit my other tools : https://github.com/NordlichtS/custom-shaders-RedAlert3

global list1 = #()
global list2 = #()
global list3 = #()
global baseObj = undefined  -- Make baseObj global so we can reference it between button actions

-- Step 1: Filter and prepare objects based on criteria
fn filterAndPrepareObjects = (
    local validObjects = #()
    local sceneObjects = objects as array

    -- Filter objects that meet criteria
    for obj in sceneObjects do (
        if isValidNode obj and 
           (isKindOf obj Editable_Mesh or isKindOf obj Editable_Poly) and 
           isValidNode obj.parent and obj.modifiers.count == 0 then 
        (  
            append validObjects obj  
        )
    )

    -- Show selection dialog
    local userSelection = selectByName title:"Select Objects for Binding" objs:validObjects multiple:true preselect:#()
    list1 = #()
    list2 = #()

    -- Populate lists based on selection
    for obj in userSelection do (
        append list1 obj
        append list2 obj.parent
    )

    simpleRigidBindTool.lblOutput.text = "Total objects prepared for skinning: " + list1.count as string
)

-- Step 2: Copy geometry and prepare for merging
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

-- Step 3: Create the base skin object as an editable poly with dummy geometry
fn createBaseSkinWithDummy = (
    local dummy = Box width:1 length:1 height:0.25 wirecolor:green
    convertToPoly dummy
    dummy.name = "NEWSKIN"
    dummy  -- Return the base object with dummy geometry retained
)

-- Step 4: Add bones to the skin modifier and get their IDs
fn addBonesAndRetrieveIDs skinMod = (
    local boneIDMap = #()
    for i = 1 to list2.count do (
        if isValidNode list2[i] then (
            skinOps.addBone skinMod list2[i] 1
            -- Find bone ID in skin modifier
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

-- Step 5: Attach objects and populate vertex-bone assignments
fn attachObjectsAndPopulateBoneIDs baseObj boneIDMap = (
    local vertexBoneIDs = #()

    -- Reserve space for the dummy vertices at the start of vertexBoneIDs
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
            simpleRigidBindTool.lblOutput.text =  " count: " + i as string + "\n total: " + list3.count as string + "\n current: " + objName as string 
        )
    )
    vertexBoneIDs  -- Return the full array of bone IDs for all vertices
)

-- Step 6: Finalize vertex assignments by setting weights for each vertex
fn finalizeVertexAssignments skinMod vertexBoneIDs = (
    -- Apply weights to all vertices
    for v = 1 to vertexBoneIDs.count do (
        skinOps.SetVertexWeights skinMod v vertexBoneIDs[v] 1.0
    )
)

-- Main function to initialize the base object
fn initializeBaseObject = (
    baseObj = createBaseSkinWithDummy()
    baseObj != undefined  -- Return true if baseObj was created successfully
)

-- Main function to combine everything into a skinned mesh
fn combineIntoSkinnedMesh = (
    -- Only proceed if baseObj is initialized and has dummy vertices
    if not initializeBaseObject() then return false

    local skinMod = Skin()
    addModifier baseObj skinMod

    if not (isKindOf skinMod Skin) then (
        simpleRigidBindTool.lblOutput.text = "Error: Unable to add Skin modifier to " + baseObj.name
        return false
    )

    -- Retrieve bone IDs and attach objects
    local boneIDMap = addBonesAndRetrieveIDs skinMod
    local vertexBoneIDs = attachObjectsAndPopulateBoneIDs baseObj boneIDMap

    -- Finalize all vertex assignments
    finalizeVertexAssignments skinMod vertexBoneIDs

    simpleRigidBindTool.lblOutput.text = "Skinned mesh created with " + list2.count as string + " bones. \n please examine NEWSKIN, if everything is correct, you may delete the old parts"
)

-- Rollout UI to trigger each function in sequence
rollout simpleRigidBindTool "Simple Rigid Bind Tool" width:320 height:320
(

    label lblGuide "make sure your mesh parts are all linked to their bones \n (as scene hiearchy, not as skins) \n click start and hold ctrl to multi select them. \n don't select bones or already skinned parts. \n Must collapse all modifiers. \n the cube at center is neccessary for the script to run, you can delete it manually" \
    align:#left offset:[10,10] height:120 width:280 

    button btnStart "Start" pos:[10,120] width:200 height:40
    label lblOutput "progress output line. \n the script is only tested in max2023, \n need further testing for max 9 \n w3x tools seem to hinder the script's auto copy?" \
    align:#left  offset:[10,40] height:120 width:280 


    on btnStart pressed do (
        filterAndPrepareObjects()
        if list1.count > 0 then (
            copyAndPrepareGeometry()
            combineIntoSkinnedMesh()
        ) else (
            simpleRigidBindTool.lblOutput.text = "No valid objects found. Please check your selection. \n they must be liked to a parent object first, \n has no modifiers, except editable poly or editable mesh"
        )
    )
)

createdialog simpleRigidBindTool
