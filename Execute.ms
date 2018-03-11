fileIn "lib.ms"
bonelist=#()
poList=#()
bonenum = 3
sel = selection as array
bonelist = for i in sel collect bonesAlongLength i boneCount:bonenum
--create Orient Offset 
for b =1 to bonenum do
(
	poList = for i = 1 to bonelist.count collect bonelist[i][1][b]
	OffsetOrient poList --tar:$Point001 --Target Offset Controller
)
-- addSwayto all bone
-- call and skin all  feather object
for b=1 to boneList.count do
(
	--print boneList[b][2]
	bList = for i=1 to boneList[b][2].count collect bonelist[b][2][i]
	--print sel[b]
	--format "%\n" bList
	SkinOp sel[b] bonels:blist
)
/* -- attach Point to mesh
	poList = for i = 1 to bonelist.count collect bonelist[i][1][1]
	poRoot = for p=1 to poList.count collect Point pos:polist[p].pos
	AttachObtoMesh poRoot $
	for p=1 to PoList.count do poList[p].parent = poRoot[p]
	
*/
--OrientConstraint poList
/*
	setCommandPanelTaskMode #modify
	convertTo ob Editable_Poly
	addModifier ob (Skin())
	modPanel.setCurrentObject (Skin()) node:ob ui:True
	for b=1 to bonels.count do
	(
		udi=0
		if b==bonels.count do udi=-1 
		skinOps.addbone ob.Modifiers[#skin] bonels[b] udi
	)
*/