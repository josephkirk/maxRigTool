oblist = selection
for i=2 to oblist.count do
(
	oldpos = oblist[i].pos
	oblist[i].pos = oblist[1].pos
	oblist[i].pivot = [0,0,0]
	resetxform oblist[i]
	collapseStack oblist[i]
	oblist[i].pos = oldpos
)