--get second string from filter string with filter "_"

fn getObname ob = 
(
	obstrlist = filterstring ob.name "_"
	if obstrlist.count != 1 then
	(
		obstrlast = obstrlist[obstrlist.count]
		if (classof (obstrlast as integer)) != undefined then
		(
			obname = obstrlist[obstrlist.count-1]
		) else obname = ostrlast
	) else obname = ob.name
	obname
)
--Attach Point to select vertex
fn PointAttachtoMesh ob = 
(
	obmesh = ob.mesh
	vertsel = getVertSelection obmesh
	facecorner = #([0,0],[1,0],[0,1],[1,1])
	outloop = false
	oblist = #()
	for v in vertsel do 
	(
		--CreatePointHelper with attachment Constraint
		attachob = Point size:10 box:true wirecolor:yellow
		append oblist attachob
		attachob.position.controller = Attachment()
		obpctr = attachob.position.controller
		obpctr.node =ob
		addNewKey obpctr 0f
		attachkey = AttachCtrl.getKey obpctr 1
		
		in coordsys ob vertpos = getVert obmesh v
		vertface=(meshop.getPolysUsingVert obmesh v)as array
		outloop = true
		for f in vertface while outloop do
		(
			attachkey.face = f
			
			for c in facecorner while outloop do
			(
				attachkey.coord = c
				AttachCtrl.update obpctr
				in coordsys ob testpos = attachob.pos
				--testcon=(dot (normalize vertpos) (normalize testpos)) as integer
				testcon = floor(distance vertpos testpos)
				format "at Face:% corner:% Point pos:% compare to VertPos:% equal %\n" f c testpos vertpos testcon
				if testcon ==0 do
				(
					attachkey.coord = c
					AttachCtrl.update obpctr
					outloop=false
					print outloop
				)
			)
		)
	)
	oblist
)
--Alternate resetXform 1
fn ResetTForm obj =
(
	in coordsys parent obj.Pos  = [0,0,0]
	in coordsys parent obj.Rotation = (quat 0 0 0 1)
	in coordsys parent obj.Scale = [1,1,1]
)
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
	convertToPoly obj
	return obj
	)
----Alternate resetXform 2 reserve Instance
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
 fn createControlText na te= -- CreateText Ob
 (
	 Ctr = text name:na text:te pos:[0,0,-50] size:20 rotation:(eulerangles -90 0 0)
 )
 fn CreateHalftCircleHelper rad c dis = -- Create Halft Circle Ob
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
fn CreateCircleHelper rad c dis = -- Create Circle Ob
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
fn CreateSphereHelper rad = -- CreateSphere Spline Ob
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
-- Create Upright PLane
fn CreateUpPlane pos:[0,0,0] n:"upPlane" w:2 l:24 Lsegs:4 Wsegs:2 =
(
	p1 = PLane name:(uniquename n) width:w length:l LengthSegs:Lsegs WidthSegs:Wsegs
	cb=getCenterMinMax p1 axis:2
	in coordsys local (p1.pivot = cb[1])
	p1.pos=pos
	rotate p1 (angleaxis 90 [1,0,0])
	slibResetXform p1
)
--Create 1 Stretch Bone Chain
fn createStretchBone a b= 
(
	bone1 =Bonesys.createbone a b [0,0,1]
	bone2 = copy bone1
	bone2.boneEnable=true
	bone2.pos = b
	bone2.parent = bone1
	bone1.resetBoneStretch()
	bone2.length = bone2.width
	poRoot = createRoot bone1
	poUpnode = copy poRoot
	poUpnode.name = bone1.name +"_Upnode"
	--print (classof poUpnode)
	in coordsys local move poUpnode [0,20,0]
	poUpnode.wirecolor = color 255 0 255
	cirRoot = CreateSphereHelper 10
	cirRoot.wirecolor = color 8 110 135
	cirRoot.pos = bone2.pos
	addLookAt poRoot cirRoot upnode:poUpnode
	pc = position_constraint()
	bone2.position.controller =pc
	pc.appendTarget cirRoot 100
	poRoot.rotation.controller.lookat_vector_length = 2
	poUpnode.parent= cirRoot
	#(poRoot,cirRoot)
)
-- Make Bones in array Stretch 
fn makeStrechBone oblist loop:false = 
(
	poRootlist =#()
	SpRootlist =#()
	for b=1 to oblist.count do
	(
			bonEnd = copy oblist[b]
			bonEnd.boneEnable=true
			bonEnd.parent = oblist[b]
			bonEnd.length = oblist[b].width
			in coordsys parent bonEnd.pos =[oblist[b].length,0,0]
			poRoot= CreateRoot oblist[b]
			append poRootlist poRoot
			oblist[b].resetBoneStretch()
			if b!=1 do poRoot.parent=SpRootlist[(b-1)]
			poUpnode = copy poRoot
			in coordsys local move poUpnode [0,20,0]
			SpRoot = CreateSphereHelper 10
			SpRoot.wirecolor = color 8 110 135
			SpRoot.pos = bonEnd.pos
			bonEnd.position.controller = position_constraint()
			bonEnd.position.controller.appendTarget SpRoot 100
			append SpRootlist spRoot
			addLookat poRoot SpRoot upnode:poUpnode
			poUpnode.parent = SpRoot
			poUpnode.wirecolor = color 255 0 255
			poUpnode.name = (oblist[b].name +"_Upnode")
			poRoot.rotation.controller.lookat_vector_length = 2
	)
	if loop == true do
	(
		loopbone = createStretchBone SpRootlist[SpRootlist.count].pos poRootlist[1].pos 
		loopbone[1].parent = SpRootlist[SpRootlist.count]
		poRootlist[1].parent = loopbone[2]
	)
)
-- Reverse array
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
mapped fn addLookAt ob tar unaffectChildren:False upnode:undefined axis:2 keepOffset:true =
(
	if unaffectChildren do
	(
	obparent = ob.parent
	obchildren = #()
	for o in ob.children do 
	(
		append obchildren o
		o.parent=undefined
	)
	ob.parent=undefined
	)
	ob.rotation.controller = Euler_XYZ()
	rc = Lookat_constraint ()
	ob.rotation.controller = rc
	rc.target_axis = axis
	rc.relative = keepOffset
	rc.lookat_vector_length =1
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
	if unaffectChildren do
	(
	ob.parent=obparent
	for obc in obchildren do obc.parent = ob
	)
)

 -- add custom attributes target to floatScript
fn addTarget ob ctr =
(
	if classof ctr != undefined do
	(
		ob.AddTarget "Sframe" ctr.Custom_Attributes[#StartFrame]
		ob.AddTarget "Eframe" ctr.Custom_Attributes[#EndFrame]
		ob.AddTarget "cycle" ctr.Custom_Attributes[#Cycle]
		ob.AddTarget "volume" ctr.Custom_Attributes[#Volume]
		ob.AddTarget "reverse" ctr.Custom_Attributes[#Reverse]
		ob.AddTarget "col_interval" ctr.Custom_Attributes[#ColumnInterval]
		ob.AddTarget "row_interval" ctr.Custom_Attributes[#RowInterval]
		ob.AddTarget "YZtiming" ctr.Custom_Attributes[#YZtiming]
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
		local baseYScript = "if reverse then direct_rot = -1\n"
		baseYScript += "else direct_rot = 1\n"
		baseYScript += "rad2deg = 3.14159265358979/180.0\n"
		baseYScript += "sin(F*direct_rot*(360.0/(Eframe-Sframe))*cycle + row_interval*ROW - col_interval*COL)*rad2deg * volume * DECAY"
		local baseZScript = "if reverse then direct_rot = -1\n"
		baseZScript += "else direct_rot = 1\n"
		baseZScript += "rad2deg = 3.14159265358979/180.0\n"
		baseZScript += "sin(F*direct_rot*(360.0/(Eframe-Sframe))*cycle + row_interval*ROW - col_interval*COL + YZtiming)*rad2deg * volume * DECAY"
		NO= ("COL = " + no as string +"\n") as string
		for i=1 to ls.count do 
		(
			--add rotationlist
			ls[i].rotation.controller =Euler_XYZ()
			rlist= Rotation_List()
			ls[i].rotation.controller = rlist
			ls[i].rotation.controller.Available.controller= Euler_XYZ()
			--  variables
			Ob= ("ROW = " + (i+offset) as string+"\n") as string
			TC= ("DECAY = " + (0.1*i) as string+"\n") as string
			
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
	lastbone.boneEnable=True
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
-- get BoundingBox Center min and max
mapped fn getCenterMinMax ob axis:3 =
(
		bb = nodeGetBoundingBox ob ob.transform
		bb2 = deepcopy bb
		bb2[1][axis]=bb[2][axis]
		bb2[2][axis]=bb[1][axis]
		avgmin = (bb[1]+bb2[2])/2
		avgmax = (bb[2]+bb2[1])/2
		#(avgmin,avgmax)
)
-- get Position Interpolate between 2 Point
fn pointInterpolate sPos ePos total =
(
	vec = (ePos-sPos)
	dis = distance sPos ePos
	inc = dis/total
	for i=0 to total collect (sPos+(inc*i/dis)*vec)
)
--Create Bone Along Object Axis
fn bonesAlongLength ob direction:3 boneCount:3 boneaxis:"z" =
(
	cc=getCenterMinMax ob axis:direction
	in coordsys ob tempobmin = Point pos:cc[1]
	in coordsys ob tempobmax = Point pos:cc[2]
	ccbetween = pointInterpolate tempobmin.pos tempobmax.pos boneCount
	case boneaxis of
	(
		"x":axisval=[1,0,0]
		"y":axisval=[0,1,0]
		"z":axisval=[0,0,1]
		"-x":axisval=[-1,0,0]
		"-y":axisval=[0,-1,0]
		"-z":axisval=[0,0,-1]
	)
	bonels = BonesFromArray ccbetween axis:axisval
	delete tempobmin
	delete tempobmax
	pols=#()
	for b in bonels do
	(
		poRoot = CreateRoot b
		poRoot.boneEnable=True
		append pols poRoot
	)
	#(pols,bonels)
)
--Create Orient Constraint between 2 op
fn OrientConstraint ls stOb:undefined enOb:undefined =
(
	if stOb == undefined or enOb == undefined then 
	(
		startOb = ls[1]
		endOb = ls[ls.count]
		obList = for i=2 to (ls.count-1) collect ls[i]
	) else 
	(
		startOb = stob
		endOb = en
		oblist =ls
	)
	inc=100.0/(oblist.count+1)
	print inc
	oc=Orientation_Constraint()
	oc.appendTarget startOb 100
	oc.appendTarget endOb 100
	
	for o=1 to oblist.count do 
	(
		i =o
		oblist[o].rotation.controller=copy oc
		oblist[o].rotation.controller.setWeight 1 (100-inc*i)
		oblist[o].rotation.controller.setWeight 2 (inc*i)
	)
)
--Prepare max to add Bone to Skin Modifier
fn SkinOp _pNode bonels:undefined= 
(	
	
	--convertTo _pnode Editable_Poly
	--with redraw off
	addModifier _pnode (Skin())
	-- Select @_pNode if needed.
	if not _pNode.IsSelected do 
	(
	Select _pNode
	)

	-- Unfreeze @_pNode if needed.
	if _pNode.IsFrozen do 
	(
	Unfreeze _pNode DoLayer:true
	)
	-- Set Modify Panel active if needed.
	if GetCommandPanelTaskMode() != #modify do 
	(
	SetCommandPanelTaskMode mode:#modify
	)
	-- Set @_pNode skin modifier as current object in modpanel if needed.
	if ModPanel.GetCurrentObject() != _pNode.skin do 
	(
	ModPanel.SetCurrentObject _pNode.skin
	)
	
	if bonels != undefined do
	(
		for b=1 to bonels.count do
		(
			udi=0
			if b==bonels.count do udi=-1 
			skinOps.addbone _pnode.skin bonels[b] udi
		)
	)
	
)
--add Object to Layer
mapped fn addtoLayer ob layername =
(
	if classof layername == String do 
	(
		layer = LayerManager.getLayerFromName layername
		layer.addnode ob
	)
)

fn createPoRoot name:"ofd_Sway+Sim_top" =
(
	Point name:name size:20.0 centermarker:false axistripod:false cross:false box:true constantscreensize:false wirecolor:(color 14 255 2)
)
fn createPo name:(uniquename "ofd_sim_point") =
(
	Point name:name size:5.0 centermarker:false axistripod:false cross:true box:true constantscreensize:false wirecolor:(color 14 255 2)
)
--Duplicate Bone Hierachy
fn SelectChild sel =
(
	if isvalidnode sel do
	(
		local selarray = #()
		while sel != undefined do
			(
				append selarray sel
				sel=sel.children[1]
			)
		selArray
	)
)
fn renameList List prefix:"" base:"" suffix:"" =
(
	ar = List as Array 
	if suffix != undefined and suffix != "" then suffix = (formattedPrint (suffix as integer) format:"2.2d") else suffix =""
	for i=1 to ar.count do
	(
		ar[i].name =prefix+base+suffix+"_"+(formattedPrint i format:"3.3d")
	)		
)
fn Breakname ob =
(
	FilterString ob.name "_"
)
fn DupBoneList ob boname boneColor:(color 255 0 0) prefix:1 =
(
	if isvalidnode ob do
	(
		n=ob
		local obarray = #()
		while n != undefined do
			(
				append obarray n
				n=n.children[1]
			)
		print obarray
		maxOps.cloneNodes obarray cloneType:#copy newNodes:&nols
		for o =1 to obarray.count do
		(
			
			NameBreak =  (FilterString obarray[o].name "_")
			BoneCol = NameBreak[(2+prefix)] as string
			BoneNum = NameBreak[(3+prefix)] as string
			nols[o].name = boname+"_"+BoneCol+"_"+BoneNum
			nols[o].taper = 10
			nols[o].backfin = off
			nols[o].wirecolor = Bonecolor
		)
		nols
	)
)
-- SetUp ChainIk
fn Set_Chain_IK layername bolist =
(
	p4list = #()
	iklist = #()
	potemp = CreatePo()
	for a=1 to bolist.count do (
		if a != bolist.count do (
			b=a+1
			ik1 = IKSys.ikChain bolist[a] bolist[b] (IKSys.solverName 1)
			ik1.transform.controller.goalSize = 5
			p4 = instance potemp
			p4.wirecolor = potemp.wirecolor
			p4.pos = ik1.pos
			ik1.parent = p4
			append p4list p4
			append iklist ik1
			addtolayer ik1 layername
			addtolayer p4 layername
		)
	)
	delete potemp
	#(p4list,iklist)
)
fn AttachObtoMesh obs Att_mesh =
(
  AttachObj = obs
  AttachTo = Att_mesh
  undo "AttachToNearVertex" on (
    if (isKindOf AttachTo Editable_mesh) then (
      for p in AttachObj do (
        pos1 = p.pos
        dtc = 100000
        local face = 1
        for j = 1 to (getNumFaces AttachTo) do (
          pos2 = meshop.getFaceCenter AttachTo j
          if (distance pos1 pos2) <= dtc then (
            dtc = (distance pos1 pos2)
            face = j
          )
        )
        p.pos.controller = Attachment ()
        p.pos.controller.node = AttachTo
        a = AttachCtrl.addNewKey p.pos.controller 0
        a.face = (face-1) with animate on at time 0 ()
        a.coord = [0.0,0.0] with animate on at time 0 ()
        dA = (distance pos1 p.pos)
        a.coord = [1.0,0.0] with animate on at time 0 ()
        dB = (distance pos1 p.pos)
        a.coord = [0.0,1.0] with animate on at time 0 ()
        dC = (distance pos1 p.pos)
        if (dA <= dB and dA <= dC) then (a.coord = [0.0,0.0] with animate on at time 0 ())
        if (dB <= dA and dB <= dC) then (a.coord = [1.0,0.0] with animate on at time 0 ())
        if (dC <= dB and dC <= dA) then (a.coord = [0.0,1.0] with animate on at time 0 ())
      )
    )
  )
)
fn AttachObtoPoly obs Att_mesh =
(
  AttachObj = obs
  AttachTo = Att_mesh
  undo "AttachToNearVertex" on (
    if (isKindOf AttachTo Editable_Poly) then (
      for p in AttachObj do (
        pos1 = p.pos
        dtc = 100000
        local face = 1
        for j = 1 to (polyop.getNumFaces AttachTo) do (
          pos2 = polyop.getSafeFaceCenter AttachTo j
          if (distance pos1 pos2) <= dtc then (
            dtc = (distance pos1 pos2)
            face = j
          )
        )
        p.pos.controller = Attachment ()
        p.pos.controller.node = AttachTo
        a = AttachCtrl.addNewKey p.pos.controller 0
        a.face = (face-1) with animate on at time 0 ()
        a.coord = [0.0,0.0] with animate on at time 0 ()
        dA = (distance pos1 p.pos)
        a.coord = [1.0,0.0] with animate on at time 0 ()
        dB = (distance pos1 p.pos)
        a.coord = [0.0,1.0] with animate on at time 0 ()
        dC = (distance pos1 p.pos)
        if (dA <= dB and dA <= dC) then (a.coord = [0.0,0.0] with animate on at time 0 ())
        if (dB <= dA and dB <= dC) then (a.coord = [1.0,0.0] with animate on at time 0 ())
        if (dC <= dB and dC <= dA) then (a.coord = [0.0,1.0] with animate on at time 0 ())
      )
    )
  )
)

fn AddSwayControllAttributes SwayController name:"Sway Attribute" = 
(
	addModifier SwayController (EmptyModifier name:name)
	local SwayCtrlCA = attributes Custom_Attributes (
		parameters main rollout:params (
			StartFrame type:#integer ui:StartFrame default:0
			EndFrame type:#integer ui:EndFrame default:60
			Cycle type:#integer ui:Cycle default:2
			Volume type:#float ui:Volume default:0.0
			Reverse type:#boolean ui:Reverse default:false
			ColumnInterval type:#float ui:ColumnInterval default:25.0
			RowInterval type:#float ui:RowInterval default:30.0
			YZtiming type:#float ui:YZtiming default:60.0
		)
		rollout params "Custom Attributes" (
			spinner StartFrame "Start Frame:" range:[-99999,99999,0] scale:1 fieldwidth:50 type:#integer align:#right
			spinner EndFrame "End Frame:" range:[-99999,99999,60] scale:1 fieldwidth:50 type:#integer align:#right
			spinner Cycle "Cycle:" range:[1,99999,2] scale:1 fieldwidth:50 type:#integer align:#right
			spinner Volume "Volume:" range:[-99999,99999,0.0] scale:0.1 fieldwidth:50 type:#float align:#right
			checkbox Reverse "Reverse" checked:false type:#boolean align:#right
			spinner ColumnInterval "Column Interval:" range:[-99999,99999,25.0] scale:0.1 fieldwidth:50 type:#float align:#right
			spinner RowInterval "Row Interval:" range:[-99999,99999,30.0] scale:0.1 fieldwidth:50 type:#float align:#right
			spinner YZtiming "YZtiming:" range:[-99999,99999,60.0] scale:0.1 fieldwidth:50 type:#float align:#right
		)
	)
	custAttributes.add SwayController.modifiers[1] SwayCtrlCA
)
fn AddOffsetAttributes OffsetController= 
(
	addModifier OffsetController (EmptyModifier name:"OffsetOrient")
	local OffsetCtrlCA = attributes Custom_Attributes (
		parameters main rollout:params (
			ModAttr type:#float ui:modUI default:1.0
			OffsetAttr type:#float ui:OffsetUI default:1.0
			NoiseStr type:#float ui:NoiseStrUI default:1.0
			NoiseFreq type:#float ui:NoiseFreqUI default:1.0
		)
		rollout params "Custom Attributes" (
			spinner modUI "Modifier:" range:[0.0,2.0,1.0] scale:0.01 fieldwidth:50 type:#float align:#right
			spinner OffsetUI "Offset:" range:[0.01,5.0,1.0] scale:0.01 fieldwidth:50 type:#float align:#right
			spinner NoiseStrUI "Noise Strength:" range:[0.0,20.0,1.0] scale:0.1 fieldwidth:50 type:#float align:#right
			spinner NoiseFreqUI "Noise Frequency:" range:[0.0,20.0,1.0] scale:0.1 fieldwidth:50 type:#float align:#right
		)
	)
	custAttributes.add OffsetController.modifiers[1] OffsetCtrlCA
)
fn addSwaySwitchAtt ob = (
	addModifier ob (EmptyModifier name:"Sway Sim Switch")
	local SwitchCa = attributes Custom_Attributes
	(
		parameters main rollout:params
		(
			SimAnimSwitch type:#float ui:SimAnimSwitchUI default:0.0
		)
		rollout params "Custom Attributes"
		(
			Slider SimAnimSwitchUI ": Sway <                > Sim :" range:[0,1,0.0] scale:0.1 fieldwidth:140 type:#float align:#center
		)
	)
	custAttributes.add ob.modifiers[("Sway Sim Switch")]  SwitchCa
)

fn createOCSwitch switchob ob tar1 tar2 =
(
	ob.rotation.controller = Orientation_Constraint()
	ob.rotation.controller.appendTarget tar1 100
	ob.rotation.controller.appendTarget tar2 100
	paramwire.Connect switchob.modifiers[#Sway_Sim_Switch].Custom_Attributes[#SimAnimSwitch] ob.rotation.controller[#Orientation_Weight_0] "1-SimAnimSwitch"
	paramwire.Connect switchob.modifiers[#Sway_Sim_Switch].Custom_Attributes[#SimAnimSwitch] ob.rotation.controller[#Orientation_Weight_1] "SimAnimSwitch"
)
fn checkname ob =
(
	for i in ob do 
	(
		NameBreak = (FilterString i.name "_")
		if NameBreak ==3 then true else 
		(
			MessageBox "Rename Skin Bone system to this format 'SkinBone_01_001'"
			false
		)
	)
)
fn OffsetOrient ls tar:undefined stOb:undefined enOb:undefined =
(
	if tar != undefined then
	(
		if tar.modifiers[#OffsetOrient]== undefined do AddOffsetAttributes tar
		tarmod = tar.modifiers[#OffsetOrient]
		if stOb == undefined or enOb == undefined then 
		(
			startOb = ls[1]
			endOb = ls[ls.count]
			obList = for i=2 to (ls.count-1) collect ls[i]
		) else 
		(
			startOb = stob
			endOb = en
			oblist =ls
		)
		inc=100.0/(oblist.count+1)
		print inc
		oc=Orientation_Constraint()
		oc.appendTarget startOb 100
		oc.appendTarget endOb 100
		
		for o=1 to oblist.count do 
		(
			i =o
			oblist[o].rotation.controller=copy oc
			oblist[o].rotation.controller[1].controller = Float_Expression()
			Weight1 = oblist[o].rotation.controller[1].controller
			Weight1val = (inc*i)
			Weight1.AddScalarConstant #Wval Weight1val
			Weight1.AddScalarTarget #Offset tarmod.Custom_Attributes[1]
			Weight1.AddScalarTarget #Random tarmod.Custom_Attributes[3]
			Weight1.SetExpression "100-Wval*offset"
			oblist[o].rotation.controller[2].controller = Float_Expression()
			Weight2 = oblist[o].rotation.controller[2].controller
			Weight2val = (inc*i)
			Weight2.AddScalarConstant #Wval Weight2val
			Weight2.AddScalarTarget #Offset tarmod.Custom_Attributes[2]
			Weight2.AddScalarTarget #Random tarmod.Custom_Attributes[3]
			Weight2.AddScalarTarget #Freq tarmod.Custom_Attributes[4]
			Weight2expr = "Wval*offset+(sin(360*NT*freq)*random)"
			Weight2.SetExpression Weight2expr
		)
	) else
	(
		if stOb == undefined or enOb == undefined then 
		(
			startOb = ls[1]
			endOb = ls[ls.count]
			obList = for i=2 to (ls.count-1) collect ls[i]
		) else 
		(
			startOb = stob
			endOb = en
			oblist =ls
		)
		inc=100.0/(oblist.count+1)
		print inc
		oc=Orientation_Constraint()
		oc.appendTarget startOb 100
		oc.appendTarget endOb 100
		
		for o=1 to oblist.count do 
		(
			i =o
			oblist[o].rotation.controller=copy oc
			oblist[o].rotation.controller.setWeight 1 (100-inc*i)
			oblist[o].rotation.controller.setWeight 2 (inc*i)
		)
	)
)
fn SetSway boneList SwayCtr =
(
	undo "Assign Sway System" on (
		local row = 1
		for b in BoneList do (
			local col = 1
			while b != undefined do (
				-- rotation controller  list
				Try (
					b.rotation.controller = Euler_Xyz()
					b.rotation.controller = Rotation_list()
					b.rotation.controller.available.controller = Euler_xyz() 
					b.rotation.controller.setname 2 "Loopable_Sway"	
					b.rotation.controller.SetActive 1
				)
				Catch()
				-- assign script controller rotY
				local ystr = "COL = " + (col as string) + "\n"
				ystr += "DECAY = " + ((col*0.1) as string) + "\n"
				ystr += "ROW = " + (row as string) + "\n"
				ystr += "if reverse then direct_rot = -1\n"
				ystr += "else direct_rot = 1\n"
				ystr += "rad2deg = 3.14159265358979/180.0\n"
				ystr += "sin(F*direct_rot*(360.0/(Eframe-Sframe))*cycle + row_interval*ROW - col_interval*COL)*rad2deg * volume * DECAY"
				local yctrl = Float_Script()
				b[3][2][2][2].controller = yctrl
				yctrl.AddTarget "Sframe" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#StartFrame]
				yctrl.AddTarget "Eframe" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#EndFrame]
				yctrl.AddTarget "cycle" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#Cycle]
				yctrl.AddTarget "volume" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#Volume]
				yctrl.AddTarget "reverse" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#Reverse]
				yctrl.AddTarget "col_interval" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#ColumnInterval]
				yctrl.AddTarget "row_interval" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#RowInterval]
				yctrl.AddTarget "YZtiming" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#YZtiming]
				yctrl.script = ystr
				-- assign script controller rotZ
				local zstr = "COL = " + (col as string) + "\n"
				zstr += "DECAY = " + ((col*0.1) as string) + "\n"
				zstr += "ROW = " + (row as string) + "\n"
				zstr += "if reverse then direct_rot = -1\n"
				zstr += "else direct_rot = 1\n"
				zstr += "rad2deg = 3.14159265358979/180.0\n"
				zstr += "sin(F*direct_rot*(360.0/(Eframe-Sframe))*cycle + row_interval*ROW - col_interval*COL + YZtiming)*rad2deg * volume * DECAY"
				local zctrl = Float_Script()
				b[3][2][2][3].controller = zctrl
				zctrl.AddTarget "Sframe" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#StartFrame]
				zctrl.AddTarget "Eframe" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#EndFrame]
				zctrl.AddTarget "cycle" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#Cycle]
				zctrl.AddTarget "volume" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#Volume]
				zctrl.AddTarget "reverse" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#Reverse]
				zctrl.AddTarget "col_interval" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#ColumnInterval]
				zctrl.AddTarget "row_interval" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#RowInterval]
				zctrl.AddTarget "YZtiming" SwayCtr.modifiers[#Sway_Attribute].Custom_Attributes[#YZtiming]
				zctrl.script = zstr
				
				b = b.children[1]
				col += 1
			)
			row += 1
		)
	)
)
-- align object between 2 point
fn AlignDir _StartPos _EndPos Ob dir:#z angles:90.0=
(
	local dirvector = (normalize (_Startpos-_EndPos))
	local MN=MatrixFromNormal dirvector
	case dir of
	(
		#x:PreRotateY MN angles
		#y:PreRotateX MN angles
		#z:PreRotateZ MN angles
	)
	local SM = ob.transform
	MN.row4=SM.row4
	ob.transform=MN
	
)
fn scaleALongNumber _ob _dis =
(
	local cb= Getcenterminmax _ob
	local cbdis = distance cb[2] cb[1]
	local inc = _dis/cbdis
	_ob.scale =[_ob.scale[1],_ob.scale[2],inc]
)
fn AlignObsAlong2Spline _Spline1 _Spline2 Oblist =
(
	local numOb = Oblist.count
	local poList =#()
	pos1Ls=GetInterp _Spline1 total:numOb
	pos2Ls=GetInterp _Spline2 total:numOb
	for i = 1 to numOb do
	(
		pos1 = pos1Ls[i]
		pos2 = pos2Ls[i]
		dis = distance pos2 pos1
		Oblist[i].pos = pos1
		
		AlignDir pos2 pos1 Oblist[i] dir:#z angles:180
		scaleALongNumber Oblist[i] dis
	)
)
fn constraintPath _ob _path percent:0.0=
(
	local pc = path_constraint()
	_ob.position.controller = pc
	pc.path = _path
	pc.percent = percent
	deleteKeys _ob.position.controller #allkeys
)
fn CreateIKCtr _SplineShape =
(
	if _SplineShape.modifiers[#Spline_IK_Control]==undefined do
	(
		addModifier _SplineShape (Spline_IK_Control ()) 
		_SplineShape.modifiers[#Spline_IK_Control].noLinking()
		_SplineShape.modifiers[#Spline_IK_Control].createHelper (_SplineShape.modifiers[#Spline_IK_Control].getknotcount())
	)
)
fn InstanceObsAlong2Spline _Spline1 _Spline2 ob count:10 createBone:False SwayTarget:undefined =
(
	local numOb = count
	local poList =#()
	local boList =#()
	local NewObs = #()
	pos1Ls=GetInterp _Spline1 total:(numOb-1)
	pos2Ls=GetInterp _Spline2 total:(numOb-1)
	--CreateIKCtr _Spline1
	
	for i = 1 to numOb do
	(
		local pos1 = pos1Ls[i]
		local pos2 = pos2Ls[i]
		local dis = distance pos2 pos1
		if ob.count !=1 then
		(
			local obID = random 1 ob.count
			local Obsel = reference ob[obID]
		) else local Obsel = reference ob[1]
		Obsel.pos = pos1
		local pointRoot=createRoot Obsel
		local pointRootLATA = CreateHelper()
		pointRootLATA.pos = pos2
		addLookat pointRoot pointRootLATA keepOffset:False
		--constraintPath pointRoot _Spline1 percent:((100/(numOb+1))*i)
		--constraintPath pointRootLATA _Spline2 percent:((100/(numOb+1))*i)
		--AlignDir pos2 pos1 Obsel dir:#z angles:180
		scaleALongNumber Obsel dis
		if createBone do
		(
			local blist =#()
			blist = bonesAlongLength Obsel
			Obsel.parent=undefined
			blist[1][1].parent=pointRoot
			SkinOp Obsel bonels:blist[2]
			if (isvalidnode SwayTarget) do SwayArray blist[2] i SwayTarget.modifiers[#Sway_Attribute]
		)
		append newObs Obsel
		--append polist blist[1]
		--append bolist blist[2]
	)
	newObs
	--print polist
	/*
	for p = 1 to polist[1].count do
	(
		local poRootList = (for k =1 to polist.count collect polist[k][p])
		OffsetOrient poRootList 
	)
	CreateIKCtr _Spline2
	*/
	--print bolist
)
fn randselect ob =
(
	if ob.count !=1 then
	(
		local obID = random 1 ob.count
		local Obsel = reference ob[obID]
		obsel.wirecolor = ob[obID].wirecolor
	) else 
	(
		local Obsel = reference ob[1]
		obsel.wirecolor = ob[1].wirecolor
	)
	Obsel
)
fn CreateFeather _Spline1 _Spline2 oblist:undefined opType:3 count:10 createbone:False SwayTarget:undefined=
(
	local numOb = count
	if opType==1 then if oblist.count!=0 then numOb = oblist.count else optype=3;numOb = count
	local rootlist =#()
	local poList =#()
	local NewObs = #()
	local LAnodeList =#()
	local UpnodeList =#()
	pos1Ls=GetInterp _Spline1 total:(numOb-1)
	--pos2Ls=GetInterp _Spline2 total:(numOb-1)
	for i = 1 to numOb do
	(
		--constraintPath pointRoot _Spline1 percent:((100/(numOb+1))*i)
		--constraintPath pointRootLATA _Spline2 percent:((100/(numOb+1))*i)
		pos1 = pos1Ls[i]
		--pos2 = pos2Ls[i]
		--dis = distance pos1 pos2
		
		--inc = 
		local pointRoot=CreateHelper()
		pointRoot.pos=pos1
	
		local pointRootLATA = CreateHelper type:#Sphere size:3 wirecolor:orange
		--constraintPath pointRoot _Spline1 percent:((100/(numOb-1))*(i-1))
		constraintPath pointRootLATA _Spline2 percent:((100/(numOb-1))*(i-1))
		dis = distance pointRoot.pos pointRootLATA.pos
		case opType of
		(
			1: (newFeather = oblist[i])
			2: (newFeather = randselect oblist)
			3: (newFeather = CreateUpPlane pos:pointRoot.pos w:10 l:dis)
		)
		
		local pointRootLA=Point parent:pointRoot wirecolor:green size:1
		local pointRootLAUN=Point parent:pointRoot wirecolor:red size:1
		ResetTForm pointRootLA
		ResetTForm pointRootLAUN
		in coordsys parent pointRootLAUN.pos =[0,-20,0] 
		newFeather.parent= pointRootLA
		ResetTForm newFeather
		if opType != 3 do 
		(
			scaleALongNumber newFeather dis
			--in coordsys parent newFeather.rotation.z =1
		)
		addLookat pointRootLA pointRootLATA keepOffset:False upnode:pointRootLAUN
		
		append rootlist pointRoot
		append NewObs newFeather
		append LAnodeList #(PointRootLA,PointRootLATA)
		append upnodeList pointRootLAUN
		if createBone do
		(
			local blist =#()
			blist = bonesAlongLength newFeather
			newFeather.parent=undefined
			blist[1][1].parent=pointRootLA
			SkinOp newFeather bonels:blist[2]
			if (isvalidnode SwayTarget) do SwayArray blist[2] i SwayTarget.modifiers[#Sway_Attribute]
			--append poList blist[1]
			--append poList blist[2]
		)
	)
	if rootlist.count!=0 do
	(
		local Possum = 0
		RootAll = CreateHelper size:10 wireColor:blue
		for u in rootlist do Possum+=u.pos
		RootAll.pos = Possum/rootlist.count
		for u in rootlist do u.parent = RootAll
	)
	if UPnodelist.count!=0 do
	(
		Possum = 0
		UpRootAll = CreateHelper type:#Sphere size:10 wireColor:Orange
		for u in Upnodelist do Possum+=u.pos
		UpRootAll.pos = Possum/UPnodelist.count
		for u in Upnodelist do u.parent = UpRootAll
	)
	--print poList
	/*
	if createBone do 
	(
		LAnodeList[1][2].position.controller = Position_XYZ()
		LAnodeList[LAnodeList.count][2].position.controller = Position_XYZ()
		tempob=CreateHelper type:#Sphere size:4 wirecolor:Red
		LAnodeList[1][2].baseobject = LAnodeList[LAnodeList.count][2].baseobject =tempob.baseobject
		LAnodeList[1][2].wirecolor = LAnodeList[LAnodeList.count][2].wirecolor =tempob.wirecolor
		delete tempob
		tempob2 =CreateHelper type:#Circle size:3 wirecolor:(color 0 125 255)
		rotate tempob2 (angleaxis 90 [0,1,0])
		resetXform tempob2
		collapseStack tempob2
		local LActrStack =#()
		for p = 1 to (polist[1].count-1) do
		(
			local LaCtrlInner = copy LAnodeList[1][2]
			if LActrStack.count == 0 then LaCtrlInner.parent = LAnodeList[1][2] else LaCtrlInner.parent=LaCtrStack[p-1][1]
			LaCtrlInner.scale =[1-0.1*p,1-0.1*p,1-0.1*p]
			local LACtrlOuter = copy LAnodeList[LAnodeList.count][2]
			if LActrStack.count == 0 then LACtrlOuter.parent = LAnodeList[LAnodeList.count][2] else LaCtrlOuter.parent=LaCtrStack[p-1][2]
			LACtrlOuter.scale =[1-0.1*p,1-0.1*p,1-0.1*p]
			append LACtrStack #(LaCtrlInner,LACtrlOuter)
			polist[1][p].baseobject=tempob2.baseobject
			polist[1][p].wirecolor=tempob2.wireColor
			addLookat polist[1][p] LaCtrlInner
			polist[polist.count][p].baseobject=tempob2.baseobject
			polist[polist.count][p].wirecolor=tempob2.wireColor
			addLookat polist[polist.count][p] LACtrlOuter
			setTransformLockFlags polist[1] #{1..3, 7..9}
			setTransformLockFlags polist[polist.count] #{1..3, 7..9}
			local poRootList = (for k =1 to polist.count collect polist[k][p])
			--print poRootList
			OffsetOrient poRootList tar:LAnodeList[LAnodeList.count][2]
			if p==1 do for o=2 to (poRootlist.count-1) do 
			(
				poRootlist[o].parent.rotation.controller=Euler_XYZ()
				LAnodeList[o][1].children[1].parent = LAnodeList[o][1].parent 
				delete LAnodeList[o][1]
				delete LAnodeList[o][2]
			)
		)
		
		delete tempob2
		
	)
	*/
	NewObs
)
fn GetInterp _Splineshape total:10=
(
	local inc = 1.0/(total)
	for f=0 to total collect (lengthInterp _SplineShape 1 (f*inc))
)
fn ImportOK =
()
-------