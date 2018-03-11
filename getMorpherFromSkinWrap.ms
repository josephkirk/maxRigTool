for i =1 to 14 do
(
	$[2].modifiers[#morpher][i].value=100
	mtarget = snapshot $[1]
	mtarget.name = $[2].modifiers[#morpher][i].name
	move mtarget [i*20,0,0]
	$[2].modifiers[#morpher][i].value=0
)