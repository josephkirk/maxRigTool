fn sLibResetXForm obj = 
	(
	local ntm = obj.transform
	obj.transform=transMatrix obj.pos
	local piv=obj.objecttransform * inverse obj.transform
	obj.objectoffsetPos  = [0,0,0]
	obj.objectoffsetRot = (quat 0 0 0 1)
	obj.objectoffsetScale = [1,1,1]
	ntm.translation=[0,0,0]
	ntm = piv * ntm
	local xformMod=xform()
	addmodifier obj xformMod
	xformMod.gizmo.transform=ntm
	xformMod.name = "Reset Xform"
	return obj
	)
fn xFormResetter xFRCollapse xFRCopyOrRef = 
	(
	undo "xFormResetter" on
		(
		if selection.count != 0 then
			(
			allObjects = #()
			rigarray = #()
			error = false

			-- Check if groups
			for obj in selection do
				(
				if isgroupmember obj == false and isgrouphead obj == false then
					(
					append allObjects obj
					)
				else error = true
				)
			if error == true then MessageBox "At least one object in your selection is a group and cannot be affected by this script. Please ungroup the objects." title:"xFormResetter"
			else
				(		
				--record hierarchy
				for obj in allObjects do
					(
					par = obj.parent
					kids = obj.children
					append rigarray #(obj, par, kids)
					)

				--dispose of hierarchy
				for obj in allObjects do
					(
					kids = obj.children
					obj.parent = undefined
					for i in kids do
						(
						i.parent = undefined
						)			
					)		

				if xFRCopyOrRef == 2 then
					(
					-- Convert To Reference
					a = #()
					for obj in allObjects do
						(
						if (sLibGetInstancesOfObject obj).count != 0 then append a obj
						)
					while a.count !=0 do
						(
						b = (sLibGetInstancesOfObject a[1]) + a[1]
						sLibConvertsInstancesToReferences b
						a = sLibRemoveItemsFromArray a b				
						)
					)
				else
					(
					-- Uninstance
					for obj in allObjects do 
						(
						if (InstanceMgr.CanMakeObjectsUnique obj) == true then InstanceMgr.MakeObjectsUnique obj #individual
						)
					)

				-- Reset Xform
				for obj in allObjects do 
					(
					flipme = false
					
					-- Reset				
					--if obj.scale.x < 0 or obj.scale.y < 0 or obj.scale.z < 0 then flipme = true
					sLibResetXForm obj
					if flipme == true then 
						(
						local normalMod = Normalmodifier()
						addmodifier obj normalMod
						normalMod.name = ("xFR_NormalFlip")
						normalMod.flip = on
						)
					if xFRCollapse == true then 
						(
						if ((canConvertTo obj SplineShape) == true) and (obj.baseobject.DisplayRenderMesh != true) then 
							(
							convertTo obj SplineShape
							)
						else if (canConvertTo obj Editable_Poly) == true then
							(
							convertTo obj PolyMeshObject
							) else  maxOps.CollapseNode obj on
						)
					)

				-- Pur Hierarchy Back
				for i in rigarray do
					(
					i[1].parent = i[2]
					for w in i[3] do
						(
						w.parent = i[1]
						)	
					)
				)
			)
		)
	)

--create Control
 fn createControlText na te=
 (
	 Ctr = text name:na text:te pos:[0,0,-50] size:20 rotation:(eulerangles -90 0 0)
 )
 fn CreateHalftCircleHelper rad c dis = 
(
	div = 1.8123
	sp = splineShape()
	for i =1 to c do
	(
	dismul=(i-1)*dis
	addnewSpline sp
	addKnot sp i #beziercorner #curve  [0,rad,dismul] [0,rad,dismul] [rad/div,rad,dismul]
	addKnot sp i #bezier #curve [rad,0,dismul] [rad,rad/div,dismul] [rad,-rad/div,dismul]
	addKnot sp i #beziercorner #curve  [0,-rad,dismul] [rad/div,-rad,dismul] [0,-rad,dismul] 
	close sp i
	weldSpline sp 21.0
	)
	updateShape sp
	move sp [0,0,(-(dis*(c-1))/2.0)]
	sp.pivot =[0,0,0]
	collapseStack sp
	sp
)
fn CreateCircleHelper rad c dis = 
(
	div = 1.8123
	sp = splineShape()
	for i =1 to c do
	(
		dismul=(i-1)*dis
	addnewSpline sp
	addKnot sp i #bezier #curve  [0,rad,dismul] [-rad/div,rad,dismul] [rad/div,rad,dismul]
	addKnot sp i #bezier #curve [rad,0,dismul] [rad,rad/div,dismul] [rad,-rad/div,dismul]
	addKnot sp i #bezier #curve  [0,-rad,dismul] [rad/div,-rad,dismul] [-rad/div,-rad,dismul]
	addKnot sp i #bezier #curve [-rad,0,dismul] [-rad,-rad/div,dismul] [-rad,rad/div,dismul]
	close sp i
	weldSpline sp 21.0
	)
	updateShape sp
	move sp [0,0,(-(dis*(c-1))/2.0)]
	sp.pivot =[0,0,0]
	collapseStack sp
	select sp
	sp
)
fn CreateSphereHelper rad =
(
		div = 1.8123
	sp = splineShape()
	addnewSpline sp
	addKnot sp 1 #bezier #curve  [0,rad,0] [-rad/div,rad,0] [rad/div,rad,0]
	addKnot sp 1 #bezier #curve [rad,0,0] [rad,rad/div,0] [rad,-rad/div,0]
	addKnot sp 1 #bezier #curve  [0,-rad,0] [rad/div,-rad,0] [-rad/div,-rad,0]
	addKnot sp 1 #bezier #curve [-rad,0,0] [-rad,-rad/div,0] [-rad,rad/div,0]
	close sp 1
	weldSpline sp 21.0
	addnewSpline sp
	addKnot sp 2 #bezier #curve  [0,0,rad] [0,-rad/div,rad] [0,rad/div,rad]
	addKnot sp 2 #bezier #curve [0,rad,0] [0,rad,rad/div] [0,rad,-rad/div]
	addKnot sp 2 #bezier #curve  [0,0,-rad] [0,rad/div,-rad] [0,-rad/div,-rad]
	addKnot sp 2 #bezier #curve [0,-rad,0] [0,-rad,-rad/div] [0,-rad,rad/div]
	close sp 2
	weldSpline sp 21.0
	updateShape sp
	addnewSpline sp
	addKnot sp 3 #bezier #curve  [rad,0,0] [rad,0,-rad/div] [rad,0,rad/div]
	addKnot sp 3 #bezier #curve [0,0,rad] [rad/div,0,rad] [-rad/div,0,rad]
	addKnot sp 3 #bezier #curve  [-rad,0,0] [-rad,0,rad/div] [-rad,0,-rad/div]
	addKnot sp 3 #bezier #curve [0,0,-rad] [-rad/div,0,-rad] [rad/div,0,-rad]
	close sp 3
	weldSpline sp 21.0
	updateShape sp
	sp
)
mapped fn CreateSphereRoot ls rad =
(
	exparent = ls.parent
	na= ls.name+"_root"
	boRoot = CreateSphereHelper rad
	boRoot.pos = ls.pos
	MatchRotation boRoot ls
	ls.parent = boRoot
	boRoot.parent = exparent
	boRoot
)
fn createStretchBone length:20=
(
	bone1 =Bonesys.createbone [0,0,0] [length,0,0] [0,0,1]
	bone2 = copy bone1
	bone2.pos = [length,0,0]
	bone2.parent = bone1
	bone2.length = bone2.width
	poRoot = createRoot bone1
	cirRoot = CreateSphereRoot bone2 10
	cirRoot.parent = undefined
	addLookAt poRoot cirRoot
	pc = position_constraint()
	bone2.position.controller =pc
	pc.appendTarget cirRoot 100
	
)
 -- drawFreeSpline macros.run "Java" "FreeSpline"

global old_pos
global new_spline
global second_knot_set
global distant = 20
 
fn get_mouse_pos pen_pos old_pen_pos dis:10 =
(
dis = distant
 if old_pos == undefined then old_pos = old_pen_pos
 if distance pen_pos old_pos > dis then
 (
  if second_knot_set then
   addKnot new_spline 1 #smooth #curve pen_pos
  else
  (
   setKnotPoint new_spline 1 2 pen_pos
   second_knot_set = true
  )
  old_pos = pen_pos
  updateShape new_spline
 )-- end if
)-- end fn
fn draw_new_line old_pen_pos =
(
 pickPoint snap:#3D mouseMoveCallback:#(get_mouse_pos,old_pen_pos)
)
fn drawSpline dis:10=
(
	distant=dis
undo"Free Spline"on
(
 new_spline = splineShape ()
 old_pen_pos = pickPoint snap:#3D
 if old_pen_pos == #RightClick then
 (
  delete new_spline
 )
 else
 (
  select new_spline
  new_spline.pos = old_pen_pos
  addNewSpline new_spline
  addKnot new_spline 1 #smooth #curve old_pen_pos
  addKnot new_spline 1 #smooth #curve old_pen_pos
  second_knot_set = false
  draw_new_line old_pen_pos
  new_spline
 )--end else
)--end undo
)
	 -- reverse array
 fn reverseArray a =
(
	ra=#()
	for i=1 to a.count do
	(
		ri = a.count+1-i
		append ra a[ri]
	)
	for i=1 to a.count do
	(
		a[i] = ra[i]
	)
)

 -- matchRotation
fn matchRotation a b =
(
	a.transform = translate (b.transform.rotation as matrix3) a.transform.pos
	r = a.transform.rotation * (inverse b.transform.rotation)
	a.rotation *= r
)

-- AddLookat constraintss
mapped fn addLookAt ob tar upnode:undefined =
(
	obparent = ob.parent
	obchildren = #()
	for o in ob.children do 
	(
		append obchildren o
		o.parent=undefined
	)
	ob.parent=undefined
	ob.rotation.controller = Euler_XYZ()
	rc = Lookat_constraint ()
	ob.rotation.controller = rc
	rc.target_axis = 0
	rc.relative = true
	
	rc.appendTarget tar 100.0
	if upnode!=undefined do
	(
		rc.pickUpNode = upnode
		rc.upnode_world =false
		rc.upnode_axis = 2
		rc.upnode_ctrl = 0
		rc.STOUP_axis =1
		--rc.viewline_length=2
	)
	ob.parent=obparent
	for obc in obchildren do obc.parent = ob
	
)

 -- add custom attributes target to floatScript
fn addTarget ob ctr =
(
	if classof ctr != undefined do
	(
		ob.addTarget "SFrame" ctr.Custom_Attributes[1]
		ob.addTarget "eframe" ctr.Custom_Attributes[2]
		ob.addTarget "cycle" ctr.Custom_Attributes[3]
		ob.addTarget "volume" ctr.Custom_Attributes[4]
		ob.addTarget "reverse" ctr.Custom_Attributes[5]
		ob.addTarget "interval" ctr.Custom_Attributes[6]
		ob.addTarget "row_interval" ctr.Custom_Attributes[7]
		ob.addTarget "YZtimming" ctr.Custom_Attributes[8]
	)
)

 -- add Rotation list controller to the bone
fn SwayTree ob no tar =
(
	if (isValidNode ob) do
	(
		--baseScript
		baseYScript =  "if reverse then direct_rot = -1
else direct_rot = 1
rad2deg = 3.14159265358979/180.0
sin(F*direct_rot*(360.0/(Eframe-Sframe))*cycle + row_interval*NO - interval*OB)*rad2deg * volume * TC"
baseZScript = "if reverse then direct_rot = -1
else direct_rot = 1
rad2deg = 3.14159265358979/180.0
sin(F*direct_rot*(360.0/(Eframe-Sframe))*cycle + row_interval*NO - interval*OB)*rad2deg * volume * TC"
		
		obtree =  for i in execute("$"+ob.name+"...*") collect i
		for i=1 to obtree.count do 
		(
			--add rotationlist
			rlist= Rotation_List()
			obtree[i].rotation.controller = rlist
			obtree[i].rotation.controller.Available.controller= Euler_XYZ()
			--  variables
			Ob= ("OB = " + i as string+"\n") as string
			TC= ("TC = " + (0.1*i) as string+"\n") as string
			NO= ("NO = " + no as string +"\n") as string
			--createfloatscript
			xctr = float_script()
			yctr = float_script()
			zctr = float_script()
			
			--add floatscript
			rlist[2][1].controller = xctr
			rlist[2][2].controller = yctr
			rlist[2][3].controller = zctr
			--define float script
			
			addTarget rlist[2][1].controller tar
			addTarget rlist[2][2].controller tar
			addTarget rlist[2][3].controller tar
			yscript = Ob + TC + NO+ baseYScript
			zscript = Ob + TC + NO+ baseZScript
			yctr.script = yscript
			zctr.script = zscript
		)
	)
)

fn SwayArray ls no tar offset:0 =
(
	if (ls!=undefined) and ls.count>0 do
	(
		--baseScript
		baseYScript =  "if reverse then direct_rot = -1
else direct_rot = 1
rad2deg = 3.14159265358979/180.0
sin(F*direct_rot*(360.0/(Eframe-Sframe))*cycle + row_interval*NO - interval*OB)*rad2deg * volume * TC"
baseZScript = "if reverse then direct_rot = -1
else direct_rot = 1
rad2deg = 3.14159265358979/180.0
sin(F*direct_rot*(360.0/(Eframe-Sframe))*cycle + row_interval*NO - interval*OB)*rad2deg * volume * TC"
		NO= ("NO = " + no as string +"\n") as string
		for i=1 to ls.count do 
		(
			--add rotationlist
			ls[i].rotation.controller =Euler_XYZ()
			rlist= Rotation_List()
			ls[i].rotation.controller = rlist
			ls[i].rotation.controller.Available.controller= Euler_XYZ()
			--  variables
			Ob= ("OB = " + (i+offset) as string+"\n") as string
			TC= ("TC = " + (0.1*i) as string+"\n") as string
			
			--createfloatscript
			xctr = float_script()
			yctr = float_script()
			zctr = float_script()
			
			--add floatscript
			rlist.setname 2 "Loop"
			rlist[2][1].controller = xctr
			rlist[2][2].controller = yctr
			rlist[2][3].controller = zctr
			--define float script
			
			addTarget rlist[2][1].controller tar
			addTarget rlist[2][2].controller tar
			addTarget rlist[2][3].controller tar
			yscript = Ob + TC + NO+ baseYScript
			zscript = Ob + TC + NO+ baseZScript
			yctr.script = yscript
			zctr.script = zscript
		)
	)
)

 -- add Modifier contain Sway customparameter
fn AddSwayControl no na =
(
	if (isvalidnode no) do
	(
	addModifier no (EmptyModifier ())
	CusAttr= no.modifiers[1]
	CusAttr.name =na
	Sway_def = attributes Custom_Attributes
	(
		Parameters main rollout:params
		(
			startframe type:#integer ui:sframe default:0
			Endframe type:#integer ui:eframe default:60
			Cycle type:#integer ui:cy default:2
			Volume type:#float ui:vol default:0
			Reverse type:#boolean ui:rev default:false
			Interval type:#float ui:inter default:25
			RowInterval type:#float ui:Rointer default:30
			YZtiming type:#float ui:yz default:60
		)
		rollout params "Custom Attributes"
		(
			spinner sframe "Start Frame" type:#integer align:#center
			spinner eframe "End Frame" type:#integer align:#center
			spinner cy "Cycle" type:#integer align:#center
			spinner vol "Volume"range:[-99999,99999,0] type:#float align:#center
			checkbox rev "Reverse" type:#boolean align:#center
			spinner inter "Interval" range:[-99999,99999,25] type:#float align:#center
			spinner Rointer "RowInterval" range:[-99999,99999,30] type:#float align:#center
			spinner yz "YZtiming" range:[-99999,99999,60] type:#float align:#center
		)
	)
	CustAttributes.add CusAttr Sway_Def
	)
)

-- make rollout to controlmod
fn Controlmod tar =
(
	
	try (CloseRolloutFloater SmodControl_RF) catch()
	rollout SmodCtr "Sway mod control"
		(
			spinner sframe "Start Frame" type:#integer align:#center
			spinner eframe "End Frame" type:#integer align:#center
			spinner cy "Cycle" type:#integer align:#center
			spinner vol "Volume" type:#float align:#center
			checkbox rev "Reverse" type:#boolean align:#center
			spinner inter "Interval" type:#float align:#center
			spinner Rointer "RowInterval" type:#float align:#center
			spinner yz "YZtiming" type:#float align:#center
			on sframe changed do
			(
				sctr.Custom_Attributes[1] =sframe.value
			)
			on eframe changed do
			(
				sctr.Custom_Attributes[2] =eframe.value
			)
			on cy changed do
			(
				sctr.Custom_Attributes[3] =cy.value
			)
			on vol changed do
			(
				sctr.Custom_Attributes[4] =vol.value
			)
			on rev changed do
			(
				sctr.Custom_Attributes[5] =rev.state
			)
			on inter changed do
			(
				sctr.Custom_Attributes[6] =inter.value
			)
			on Rointer changed do
			(
				sctr.Custom_Attributes[7] =Rointer.value
			)
			on yz changed do
			(
				sctr.Custom_Attributes[8] =yz.value
			)
		)
	SmodControl_RF = newrolloutfloater "Sway Mod control" 200 210 
	addRollout SmodCtr SmodControl_RF rolledUp:false
)

-- createBone from position Array
fn BonesFromArray ar bonewidth:5 boneTaper:20 upnode:undefined axis: [0,0,1] name:"SwayBone_" wirecolor:green =
(
	total = ar.count
	Sposlist = copy ar #nomap
	EposList = copy ar #nomap
	deleteItem Sposlist total
	deleteItem Eposlist 1
	bonels =#()
	for i =1 to (total-1) do
	(
		posLs = #(SposList[i],EposList[i])
		if upnode!= undefined then
		(
			alignvector =(normalize(posLs[1]-upnode.pos))
			crossvector = cross alignvector axis
			bo = BoneSys.createBone posLs[1] posLs[2] crossvector
		) else
		(
			bo = BoneSys.createBone posLs[1] posLs[2] axis
		)
		append bonels bo
		if i != 1 do
		(
			bo.parent=bonels[i-1]
		)
		bo.wirecolor = wirecolor
		bo.name = (uniquename name)
	)
	bonels.frontfin=on
	bonels.width=bonewidth
	bonels.height=bonewidth
	bonels.Taper = boneTaper
	lastbone = copy bonels[total-1]
	append bonels lastbone
	lastbone.length = lastbone.width
	lastbone.wirecolor = wirecolor
	lastbone.pos = Eposlist[total-1]
	lastbone.parent=bonels[total-1]
	bonels
)

-- createBone from Vert selection
fn BoneFromVerts ob inverts:true upnode:undefined  =
(
	vertlist = (polyop.getVertSelection ob) as array 
	if vertlist.count >2 do
	(
		vertposlist = for i in vertlist collect polyop.getVert ob i
		if inverts do reverseArray vertposlist
		bonels = BonesFromArray vertposlist  upnode:upnode
		bonels
	)
)
fn BoneFromSpline sp upnode:undefined =
(
	if (isvalidnode sp) and superclassOf sp == shape do
	(
		for s = 1 to (numSplines sp) do
		(
			Knotcount = numKnots sp s
			KnotposList = #()
			for k=1 to Knotcount do
			(
				Knotpos = getKnotPoint sp s k
				append KnotposList Knotpos
			)
			bonels = BonesFromArray KnotposLIst upnode:upnode
			bonels
		)
	)
)

-- create Bone chain root point
mapped fn CreateRoot ls size:2 type:#Point axis:#z wirecolor:yellow =
(
	if ls!= undefined do
	(
		exparent = ls.parent
		na= ls.name+"_root"
		boRoot = case type of
		(
		#Point: Point box:true size:size
		#Circle: Circle radius:size
		#CircleHalf: CreateHalftCircleHelper size 1 0
		#Circle3: CreateCircleHelper size 3 (size/10.0)
		#Circle3Half: CreateHalftCircleHelper size 3 (size/10.0)
		#Sphere: CreateSphereHelper size
		default: Point box:true size:size
		)
		if (classof boRoot)!= Point do
		(
			case axis of
			(
			1: rotate boRoot (angleaxis -90 [1,0,0])
			2: (rotate boRoot (angleaxis 90 [0,0,1]);rotate boRoot (angleaxis 90 [0,1,0]))
			3: rotate boRoot (angleaxis -90 [0,1,0])
			4: rotate boRoot (angleaxis 90 [1,0,0])
			5: (rotate boRoot (angleaxis -90 [0,0,1]);rotate boRoot (angleaxis 90 [0,1,0]))
			6: rotate boRoot (angleaxis 90 [0,1,0])
			)
			resetXform boRoot
			collapseStack boRoot
		)
		boRoot.pos = ls.pos
		boRoot.wirecolor=wirecolor
		boRoot.name=na
		MatchRotation boRoot ls
		ls.parent = boRoot
		boRoot.parent = exparent
		addmodifier boRoot (EmptyModifier ())
		boRoot
	)
)
fn CreateHelper type:#Point size:2 wirecolor:yellow = 
(
	boRoot = case type of
	(
	#Point: Point box:true size:size
	#Circle: Circle radius:(size*2)
	#CircleHalf: CreateHalftCircleHelper (size*2) 1 0
	#Circle3: CreateCircleHelper (size*2) 3 (size/10.0)
	#Circle3Half: CreateHalftCircleHelper (size*2) 3 (size/10.0)
	#Sphere: CreateSphereHelper size
	default: Point box:true
	)
	boRoot.wirecolor = wirecolor
	boRoot.name = (type as string) +"_Root"
	addmodifier boRoot (EmptyModifier ())
	boRoot
)
--RemoveRoot
mapped fn RemoveRoot ob=
(
	if ob!= undefined do
	(
	exchildren = #()
	for c in ob.children do append exchildren c
	exparent = ob.parent
	delete ob
	for i in exchildren do i.parent = exparent
	)
)