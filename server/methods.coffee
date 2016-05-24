Meteor.methods
	'findRoomByMaster': (masterCode) ->
		Rooms.findOne masterCode: masterCode
	'printGrid': (chatID, room, isMaster, withKeyboard) ->
		printGrid(chatID, room, isMaster, withKeyboard)
	'messageFromWeb': (chatID, text, hideKeyboard) ->
		messageFromWeb(chatID, text, hideKeyboard)
