--gitChanged
---variable-definition---------------------------------------------------------------------
filein "J:\Code\Lib.ms" quiet:True
global DVOpenCloseUi
global DVDefineUI
global DvTypeName
global DVRollOut
global DvFloater
global InstanceObs =#()
global NewObs =#()
---function-------------------------------------------------------------------------------
fn DVOpenCloseUI =
	(
	if DVFloater != undefined then CloseRolloutFloater DVFloater
	InstanceObs =#()
	NewObs =#()
	DVDefineUI()
	DVFloater = newRolloutFloater "Feather Rig" 200 550
	addRollout DVRollout DVFloater category:2
	)

fn DVDefineUI = 
(
	rollout DVRollOut "Main"
	(
		label insplb "Inner Spline:"
		pickbutton InnerSplineOb "Select Object" 
		label outsplb "Outer Spline:" offset:[0,5]
		pickbutton OuterSplineOb "Select Object" 
		label swctrlb "Sway Control Object:" offset:[0,5]
		pickbutton SwayTarOb "Select Object" 
		label obslistlb "Object List:" offset:[0,5]
		multilistbox ObsLIst
		Button addOBbt "Add" offset:[-45,0]
		Button RemoveOBbt "Remove" offset:[45,-25]
		group "Create Option:"
		(
		dropdownlist Operatetypelist "Type" items:#("AddSway","Instance Object In List","Create Plane") align:#center width:150 height:20
		label numFeatherlb "Feather count:"
		Spinner NumFeatherSp  range:[3,100,10] type:#integer align:#center
		checkbox Createbonecb "Create Bone?" align:#center
		)
		Button Applybt "Create Feathers"
		Button Skinbt "Skin Object"
		Button Deletebt "DeleteAll"
		on Operatetypelist selected type do print Operatetypelist.selection
		on InnerSplineOb picked Ob do 
		(
			InnerSplineOb.object=Ob
			InnerSplineOb.text = Ob.name
		)
		on InnerSplineOb rightClick do 
		(
			InnerSplineOb.object=(selection as array)[1]
			InnerSplineOb.text = (selection as array)[1].name
		)
		on OuterSplineOb picked Ob do 
		(
			OuterSplineOb.object=Ob
			OuterSplineOb.text = Ob.name
		)
		on OuterSplineOb rightclick do 
		(
			OuterSplineOb.object=(selection as array)[1]
			OuterSplineOb.text = (selection as array)[1].name
		)
		on SwayTarOb picked Ob do
		(
			if isvalidnode Ob do
			(
				if Ob.modifiers[#Sway_Attribute] ==undefined do AddSwayControllAttributes Ob
				SwayTarOb.text = Ob.name
				SwayTarOb.object = ob
			)
		)
		on SwayTarOb rightclick do 
		(
			if isvalidnode (selection as array)[1] do
			(
				if (selection as array)[1].modifiers[#Sway_Attribute] ==undefined do AddSwayControllAttributes (selection as array)[1]
				SwayTarOb.text = (selection as array)[1].name
				SwayTarOb.object = (selection as array)[1]
			)
		)
		on AddObbt pressed do 
		(
			for o in (selection as array) do if (superclassof o) ==GeometryClass do appendIfUnique InstanceObs o
			Obslist.items = for i in InstanceObs collect i.name
			Obslist.selection =#(1)
		)
		on Obslist doubleClicked obid do
		(
			select InstanceObs[obid]
		)
		on RemoveOBbt pressed do 
		(
			if (Obslist.selection as array).count != 0 do
			(
				for sel in Obslist.selection do deleteItem InstanceObs sel
			)
			Obslist.items = for i in InstanceObs collect i.name
		)
		on RemoveOBbt rightClick do 
		(
			if InstanceObs.count !=0 do for i=1 to InstanceObs.count do deleteItem InstanceObs 1
			Obslist.items = for i in InstanceObs collect i.name
		)
		on Applybt pressed do
		(
			if(isValidnode InnerSplineOb.object) and (isValidnode OuterSplineOb.object) and Operatetypelist.selection !=1 then
			(
				
				NewObs = CreateFeather InnerSplineOb.object OuterSplineOb.object oblist:InstanceObs optype:Operatetypelist.selection count:NumFeatherSp.value dir:#x createbone:Createbonecb.checked SwayTarget:SwayTarOb.object
				if Createbonecb.checked do
				(
					CreateIKCtr OuterSplineOb.object
					IKHelper=OuterSplineOb.object.modifiers[#Spline_IK_Control].helper_list
					tempob=CreateHelper type:#Sphere size:6
					for i in IKHelper do 
					(
						i.baseobject = tempob.baseobject
						i.wirecolor = red
					)
					delete tempob
				)
			) else
			(
				if (isvalidnode SwayTarOb.object) and InstanceObs.count >0 do
				(
					local oSwaylist =#()
					for o in InstanceObs do
					(
						oRoot = CreateRoot o size:3 wirecolor:blue
						oSway = CreateRoot o type:#Sphere size:3 wirecolor:orange
						append oSwayList oSway
					)
					SwayArray oSwaylist 1 SwayTarOb.object.modifiers[#Sway_Attribute]
				)
			)
		)
		on Deletebt pressed do 
		(
			if NewObs.count != 0 do for o in NewObs do delete o
				NewObs =#()
		)
		
	)
)
---Execution--------------------------------------------------------------------------------------------
DVOpenCloseUI()