--import
fileIn "javascripts/Java_lib.ms"
--main
clearListener()
try (CloseRolloutFloater JavaRig_RF) catch()
--var
global CHname =""
global SwayCtr =undefined
global SwayCtrmods =#()
global RF_width = 200 --Define RolloutFloater Width
global RF_height = 750 --Define RolloutFloater Height
if maxFilename !="" do
(
	maxnamestrlist= filterstring maxFileName "_"
	if maxnamestrlist.count >2 do CHname =maxnamestrlist[2]
	SwayCtrname = (Chname +"_ond_sway")
	if isvalidnode (getnodebyname SwayCtrname) do
	(
	SwayCtr = getnodebyname SwayCtrname
	SwayCtrmods =for i in SwayCtr.modifiers collect i.name
	)
)
-- local function
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

--UI def
rollout RigCreationUI "RigCreationTool"
(
	--UI
	
	label chnamelabel "Character name:" align:#left
	edittext Chnamebt align:#left text:CHname
	button CreateCtr "CreateSwayCtrl" align:#right
	label botoollab "Create Bone Tools:" align:#left pos:[15,80]
	button botools "Bone Tools" align:#left pos:[110,80]
	button drawsp "DrawSpline" align:#left pos:[20,115] width:70  height:20
	spinner disValue "Distance" range:[0,100,10] type:#integer align:#right pos:[117,115] width:60 height:20
	button Sptobo "SplinetoBone" align:#left pos:[20,140] width:70  height:20
	spinner bonumValue "# bones" range:[0,100,5] type:#integer align:#left pos:[96,140] width:60 height:20
	label roottoollab "Create Helper:" align:#left pos:[15,165]
	spinner borootsizesp "size" range:[0,10000,10] type:#float pos:[130,185] width:50 height:20
	button createRootbt "Create" tooltip:"RightClick to create on selected vertices" align:#left pos:[15,210] width:50 height:20
	dropdownlist roottypelist items:#("Point","Circle","CircleHalf","Circle3","Circle3Half","Sphere") width:100 height:20 pos:[15,185]
	button deleteRootbt "Delete" align:#right pos:[65,210] width:50 height:20
	button Modsizebt "Modify" align:#right pos:[130,210] width:50 height:20
	checkbox isrootcheckb "Is Root?" align:#right pos:[15,235] width:60 height:20
	checkbox ischildcheckb "Is Children?" align:#right pos:[15,270] width:160 height:20
	checkbox intrcb "Instance Transform?" align:#right pos:[15,290] width:160 height:20
	checkbox inposcb "Instance Position Controller?" align:#right pos:[15,310] width:160 height:20
	radiobuttons axispick columns:3 labels:#("x","y","z","-x","-y","-z")default:3  align:#right pos:[80,235] width:160 height:40 visible:false
	colorpicker Colorbt color:[255,255,0] modal:false align:#center pos:[130,160] width:50 height:20


	--Function
	
	on CreateCtr pressed do
	(
		if SwayCtr == undefined then
		(
			if Chnamebt.text!= "" then
			(
				strlist = filterstring Chnamebt.text "-"
				ctrname= Chnamebt.text +"_ond_sway"
				ctrtext = (substring strlist[2] 1 (strlist[2].count-1)) +"-Sway"
				SwayCtr = createControlText ctrname ctrtext
				select SwayCtr
			) else
			(
				SwayCtr = createControlText "Sway_Controller" "Sway Controller"
			)
		) else select SwayCtr
	)
	on drawsp pressed do
	(
		drawSpline dis:disValue.value
	)
	on Sptobo pressed do
	(
		for i in selection do
		(
			for s = 1 to (numSplines i) do
			(
				pls = #()
				kcount = boNumvalue.value
				for k=1 to (kcount+1) do
				(
					kpos=interpCurve3D i s ((k-1)*(1.0/kcount))
					append pls kpos
				)
				BonesFromArray pls
			)
		)
	)
	on botools pressed do
	(
		macros.run "Animation Tools" "BoneAdjustmentTools"
	)
	on isrootcheckb changed rootStage do
	(
		if rootStage then axispick.visible=true else axispick.visible=false
	)
	on createRootbt pressed do
	(
		if isrootcheckb.checked then
		(
			axis = axispick.state
			CreateRoot $ type:(roottypelist.selected as name) axis:axis size:borootsizesp.value wirecolor:colorbt.color
		) else if ischildcheckb.checked then
		(
			if selection.count!= 0 then
			(
				for o in selection do
				(
					if (isvalidnode o) do
					(
						oldchild = o.children
						pointob = CreateHelper type:(roottypelist.selected as name) size:borootsizesp.value wirecolor:colorbt.color
						pointob.pos=o.pos
						for ob in oldchild do ob.parent = pointob
						pointob.parent =o
					)
				)
			)
		) else
		(
			if selection.count != 0 then
			(
				for i in selection do
				(
					rootob = CreateHelper type:(roottypelist.selected as name) size:borootsizesp.value wirecolor:colorbt.color
					rootob.pos = i.pos
					if intrcb.checked do rootob.controller = i.controller
					if inposcb.checked do rootob.position.controller = i.position.controller
				)
			) else CreateHelper type:(roottypelist.selected as name) size:borootsizesp.value wirecolor:colorbt.color
		)
	)
	on createRootbt rightclick do
	(
		if $!= undefined and (classof $ == Editable_Poly) do
		(
			vertlist = (polyop.getVertSelection $) as array 
			if vertlist.count >0 do
			(
				vertposlist = for i in vertlist collect polyop.getVert $ i
				for v in vertposlist do
				(
					pobject= CreateHelper type:(roottypelist.selected as name) size:borootsizesp.value wirecolor:colorbt.color
					pobject.pos = v
				)
			)
		)
	)
	on deleteRootbt pressed do
	(
		RemoveRoot $
	)
	on modsizebt pressed do
	(
		if selection.count != 0 do
		(
			for i in selection do
			(
				if (superclassof i) == Helper or (Superclassof i) == shape then
				(
					tempOb =  CreateHelper type:(roottypelist.selected as name) size:borootsizesp.value wirecolor:colorbt.color
					i.baseobject =tempOb.baseobject
					delete tempOb
				)
			)
		)
	)
)
Rollout RigmanageUI "Rig Management Tool"
(
	--Ui
	
	label bomlabel "Bone name:" align:#left
	edittext  boname align:#left text:"__bonename"
	button getbonamebt "GetName" align:#left pos:[15,50] width:80 height:30
	spinner bocolnum range:[0,100,0] type:#integer align:#right pos:[150,50] width:35 height:30
	button renamebobt "Rename" align:#right pos:[100,50] width:50 height:30
	label bocolorlabel "Bone Color:" align:#left
	colorpicker Colorbt color:[0,0255,0] modal:false align:#center pos:[70,85] width:50 height:20
	button recolorbobt "Apply" align:#right pos:[125,85] width:50 height:20
	label palabel "Boneparent:" align:#lef
	edittext  panametx align:#left text:"_no Target"
	pickbutton pickpa "Pick Parent"align:#left pos:[15,150] width:105 height:20
	button linkpa "Apply" align:#right pos:[125,150] width:50 height:20
	label lalabel "Lookat:" align:#left
	edittext  lanametx align:#left text:"_no Target"
	pickbutton picklabt "Pick Target" align:#left pos:[15,220] width:105 height:20
	pickbutton pickunbt "Pick Upnode" align:#left pos:[15,240] width:105 height:20
	button lookatbt "Apply" align:#right pos:[125,220] width:50 height:20
	spinner viewlengthspinner "LA ViewLenght" align:#left pos:[15,270]
	--Function
	on viewlengthspinner changed val do
	(
		for i in selection do
		(
			if (classof i.rotation.controller) == Lookat_constraint do
			(
				i.rotation.controller.lookat_vector_length = val
			)
		)
	)
	on pickpa picked ob do
	(
			panametx.text = ob.name
	)
	on linkpa pressed do
	(
		if pickpa.object != undefined do
		(
			for i in selection do
			(
				undo on 
				(
				i.parent= pickpa.object
				)
			)
		)
	)
	
	on picklabt picked ob do
	(
			lanametx.text = ob.name
	)
	on pickunbt picked ob do
	(
			pickunbt.text = ob.name
	)
	on lookatbt pressed do
	(
		undo on
		(
		addLookAt selection picklabt.object upnode:pickunbt.object
		)
	)
	on getbonamebt pressed do
	(
		if (isvalidnode $) do
		(
			obname = getobname $
			boname.text = CHname +"_bon_" + obname
		)
	)
	on renamebobt pressed do
	(
		if selection.count !=0 then
		(
			for i in selection do
			(
				if bocolnum != 0 then
				(
					i.name = uniquename (boname.text+"_"+bocolnum.value as string+"_")
				) else i.name = uniquename (boname.text+"_")
			)
		) else 
		(
			if bocolnum != 0 then
			(
				$.name = uniquename (boname.text+"_"+bocolnum.value as string+"_")
			) else $.name = uniquename (boname.text+"_")
		)
	)
	on recolorbobt pressed do
	(
		for i in selection do
		(
			if (isvalidnode i) do
			(
				i.wirecolor = colorbt.color
			)
		)
	)
)
RollOut SwayUi "Make Bone Sway Tool"
(
	--UI

	label swnamelabel "Sway modifiers:" align:#left
	dropdownlist moddroplist items:SwayCtrmods selection:1 width:100 height:20 pos:[15,30]
	edittext  Smname align:#left text:"Sway Atrribute" width:100
	button updatemodlsbt "reload" align:#left pos:[120,5] width:50 height:20
	button addmodbt "AddThis" align:#left pos:[115,55] width:60 height:20
	button openmodbt "ControlThis" align:#right pos:[115,30] width:60 height:20
	label seplabel1 "----------------------------------------" align:#left pos:[15,80]
	spinner noValue "NO" range:[0,100,1] type:#integer align:#right pos:[127,100] width:45 height:20
	spinner obValue "OB offset" range:[0,100,0] type:#integer align:#right pos:[114,120] width:58 height:20
	button makeswaybt "Sway It" tooltip:"when marimba rhythms start to play" align:#left pos:[15,100] width:65 height:40
	
	--Function
	on addmodbt pressed do
	(
		if SwayCtr!=undefined and (not validmodifier SwayCtr SwayCtr.modifiers[smname.text as name]) do
		(
			AddSwayControl SwayCtr smname.text
		)
		SwayCtrmods = for i in SwayCtr.modifiers collect i.name
		moddroplist.items = SwayCtrmods
	)
	on makeswaybt pressed do
	(
		if SwayCtr!=undefined and (validmodifier SwayCtr SwayCtr.modifiers[moddroplist.selected as name]) do
		(
			SwayCtr.modifiers[moddroplist.selected as name].Custom_Attributes.volume = 0
			modtarget = SwayCtr.modifiers[moddroplist.selected as name]
			SwayArray selection noValue.value modtarget offset:obvalue.value
		)
	)
	on openmodbt pressed do
	(
		max modify mode
		if validmodifier SwayCtr SwayCtr.modifiers[moddroplist.selected as name] do
		(
			modPanel.setCurrentObject SwayCtr.modifiers[moddroplist.selected as name]
		)
	)
	on updatemodlsbt pressed do
	(
		SwayCtrmods = for i in SwayCtr.modifiers collect i.name
		moddroplist.items = SwayCtrmods
	)
)
rollout EyeRigUI "Facial Rig Tool" width:185 height:100
(
	button InsTran "Instance Transform CTR" pos:[15,10] width:150 height:20
	button InsPos "Instance Position CTR" pos:[15,35] width:150 height:20
	group "EyeRig"
	(
		label eyeoblab "Select Eyes Meshes:"
		pickbutton EyeL "Select Eye Left"  width:150 height:25
		pickbutton EyeR "Select Eye Right"  width:150 height:25
		label eyeclab "Select Eyes Control:"
		pickbutton EyeMCtr "Main" width:150 height:25
		pickbutton EyeLCtr "Left"width:150 height:25
		pickbutton EyeRCtr "Right" width:150 height:25
		button WireXform "Apply" width:160 height:40
	)
	button ResetXf "ResetXform" width:150 height:35
	on InsTran pressed  do
	(
		if selection != undefined and selection.count>1 then
		(
			masterCtr= $[1].controller
			for i=2 to selection.count do
			(
				$[i].controller = masterCtr
			)
		) else messageBox "pick 2 or more object starting with the master"
	)
	on EyeL picked obj do
	(
		EyeL.text = obj.name
	)
	on EyeR picked obj do
	(
		EyeR.text = obj.name
	)
	on EyeMCtr picked obj do
	(
		EyeMCtr.text = obj.name
	)
	on EyeLCtr picked obj do
	(
		EyeLCtr.text = obj.name
	)
	on EyeRCtr picked obj do
	(
		EyeRCtr.text = obj.name
	)
	on InsPos pressed  do
	(
		if selection != undefined and selection.count>1 then
		(
			masterCtr= $[1].position.controller
			for i=2 to selection.count do
			(
				$[i].position.controller = masterCtr
			)
		) else messageBox "pick 2 or more object starting with the master"
	)
	on ResetXf pressed  do
	(
		xFormResetter true 1
	)
	on WireXform pressed  do
	(
		
		ELob = EyeL.object
		ERob = EyeR.object
		EMCob = EyeMCtr.object
		ELCob = EyeLCtr.object
		ERCob = EyeRCtr.object
		sLibResetXForm EMCob
		maxOps.CollapseNode EMCob on
		if EMCob.parent != undefined then 
		(
			sLibResetXForm EMCob.parent 
			maxOps.CollapseNode EMCob.parent on
		if ELob != undefined and ELCob != undefined and EMCob != undefined and ERCob != undefined then
		(
			in coordsys parent EMCobX = EMCob[3][1][1].value
			in coordsys parent EMCobZ = EMCob[3][1][3].value
			in coordsys parent ELCobX = ELCob[3][1][1].value
			in coordsys parent ELCobZ = ELCob[3][1][3].value
			in coordsys parent ERCobX = ERCob[3][1][1].value
			in coordsys parent ERCobZ = ERCob[3][1][3].value
			Ex = "X_Position-(" + EMCobX as string +")"
			Ez = "Z_Position-(" + EMCobZ as string +")"
			ExL = "X_Position-(" + ELCobX as string +")"
			EzL = "Z_Position-(" + ELCobZ as string +")"
			ExR = "X_Position-(" + ERCobX as string +")"
			EzR = "Z_Position-(" + ERCobZ as string +")"
			resetc = bezier_float ()
			tm = Elob.modifiers.count
			ELob.modifiers[#XForm][1][#X_Position].controller = resetc
			ELob.modifiers[#XForm][1][#Z_Position].controller = resetc
			ELob.modifiers[#'XForm-L'][2][1][#X_Position].controller = resetc
			ELob.modifiers[#'XForm-L'][2][1][#Z_Position].controller = resetc
			ERob.modifiers[#'XForm-R'][2][1][#X_Position].controller = resetc
			ERob.modifiers[#'XForm-R'][2][1][#Z_Position].controller = resetc
			
			if classOf ELob.modifiers[tm] ==Xform and classOf ELob.modifiers[tm-1] ==Xform then
				(
					paramWire.connect EMCob[3][1][#X_Position] ELob.modifiers[#XForm][1][#X_Position] Ex
					paramWire.connect EMCob[3][1][#Z_Position] ELob.modifiers[#XForm][1][#Z_Position] Ez
					paramWire.connect ELCob[3][1][#X_Position] ELob.modifiers[#'XForm-L'][2][1][#X_Position] ExL
					paramWire.connect ELCob[3][1][#Z_Position] ELob.modifiers[#'XForm-L'][2][1][#Z_Position] EzL
					paramWire.connect ERCob[3][1][#X_Position] ERob.modifiers[#'XForm-R'][2][1][#X_Position] ExR
					paramWire.connect ERCob[3][1][#Z_Position] ERob.modifiers[#'XForm-R'][2][1][#Z_Position] EzR
					paramWire.connect ELCob[3][3] ELob.modifiers[#'XForm-L'][2][3] "Scale"
					paramWire.connect ERCob[3][3] ERob.modifiers[#'XForm-R'][2][3] "Scale"
				) else messageBox "Eye Mehes don't have xform modifier or not in the right position"
		) else messageBox "Pick Object?"
		) else messageBox "Eye Main is not linked to headpart"
	)
)
RollOut InfoUi "Info"
(
	label Scrnamelabel "Java Rig Helper v0.1"
	label makerlabel "Created by Nguyen Phi Hung"
	label datelabel "2016"
)
JavaRig_RF = newrolloutfloater "Java Rig Helper" 200 735 1450 170
addRollout RigCreationUi JavaRig_RF category:1 rolledUp:false
addRollout RigManageUi JavaRig_RF category:2 rolledUp:true
addRollout SwayUi JavaRig_RF category:3 rolledUp:true
addRollout EyeRigUi JavaRig_RF category:4 rolledUp:true
addRollout InfoUi JavaRig_RF category:5
--AddSubRollout mainUI.RigCreationSubrollout RigCreationUi