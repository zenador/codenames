@markWordAsGuessed = (grid, index, room) ->
	for i, val of grid
		if grid[i] > 1
			grid[i]--
	grid[index] = 4

	openedColour = room.gridColours[index]
	if openedColour == room.colourList[0]
		room.pointsList[0] += 1
	else if openedColour == room.colourList[1]
		room.pointsList[1] += 1

	Rooms.update room._id, $set: gridOpened: grid, pointsList: room.pointsList, updatedAt: new Date
