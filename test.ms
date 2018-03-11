fileIn "J:\Code\Lib.ms"
--delete $UpPlane*
InstanceObsAlong2Spline $Line001 $Line002 (selection as array) count:10
/*
sel = selection as array
numFeather= 20
poList =#()
for o in sel do append poList (GetInterp o total:numFeather)

for i = 1 to poList[1].Count do
(1
	pos1 = poList[1][i]
	pos2 = poList[2][i]
	dis = distance pos1 pos2
	print dis
	newFeather = CreateUpPlane pos:pos1 w:50 l:dis 
	AlignDir pos2 pos1 newFeather  dir:#z angles:180
)
*/