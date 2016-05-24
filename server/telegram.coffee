Meteor.startup ->
	TelegramBot.token = TELEGRAM_TOKEN
	TelegramBot.start()
	TelegramBot.addListener '/start', (c, u, o) ->
		'Welcome! Please type /help if you don\'t know how to use this bot'
	TelegramBot.addListener '/join', (c, u, o) ->
		room = Rooms.findOne({telegram: o.chat.id})
		if room
			return 'You are already in a game room as a normal player, please /leave first'
		room = Rooms.findOne({telegramMaster: o.chat.id})
		if room
			return 'You are already in a game room as spymaster, please /leave first'
		if c.length < 4
			return 'Please put the access code from the web app after /join'
		accessCode = c[1] + " " + c[2] + " " + c[3]
		accessCode = accessCode.trim().toLowerCase()
		room = Rooms.findOne({accessCode: accessCode})
		if room
			if room.telegram
				TelegramBot.method 'sendMessage',
					chat_id: room.telegram
					text: 'You have been disconnected from your room as a normal player'
			Rooms.update room._id, $set: telegram: o.chat.id, updatedAt: new Date
			createLog room._id, 'A telegram chat has been connected'
			TelegramBot.method 'sendMessage',
				chat_id: o.chat.id
				text: 'Joined room! Current state: '+room.state
			if room.state == "started"
				printGrid(o.chat.id, room, 0, true)
		else
			return 'Could not find room'
		false
	TelegramBot.addListener '/joinmaster', (c, u, o) ->
		room = Rooms.findOne({telegram: o.chat.id})
		if room
			return 'You are already in a game room as a normal player, please /leave first'
		room = Rooms.findOne({telegramMaster: o.chat.id})
		if room
			return 'You are already in a game room as spymaster, please /leave first'
		if c.length < 4
			return 'Please put the master code from the web app after /joinmaster'
		accessCode = c[1] + " " + c[2] + " " + c[3]
		accessCode = accessCode.trim().toLowerCase()
		room = Rooms.findOne({masterCode: accessCode})
		if room
			if room.telegramMaster
				TelegramBot.method 'sendMessage',
					chat_id: room.telegramMaster
					text: 'You have been disconnected from your room as spymaster'
			Rooms.update room._id, $set: telegramMaster: o.chat.id, updatedAt: new Date
			createLog room._id, 'A telegram chat has been connected as spymaster'
			TelegramBot.method 'sendMessage',
				chat_id: o.chat.id
				text: 'Joined room as spymaster! Current state: '+room.state
			if room.state == "started"
				printGrid(o.chat.id, room, 1, false)
		else
			return 'Could not find room'
		false
	TelegramBot.addListener '/guess', (c, u, o) ->
		room = Rooms.findOne({telegram: o.chat.id})
		if !room
			return 'Sorry, you are not in a game room as a normal player'
		if room.state != "started"
			return 'Sorry, you cannot guess as the game hasn\'t started yet'
		TelegramBot.method 'sendMessage',
			chat_id: o.chat.id
			text: 'Make your guess'
			reply_markup: makeKeyboard(getKeyboard(room))
		false
	TelegramBot.addListener '/g', (c, u, o) ->
		if c.length < 2
			return 'Please put a word'
		room = Rooms.findOne({telegram: o.chat.id})
		if !room
			return 'Sorry, you are not in a game room as a normal player'
		if room.state == "preparing"
			return 'Sorry, game hasn\'t started yet'
		grid = room.gridWords
		word = c[1..].join(' ')
		index = grid.indexOf(word)
		if index == -1
			return 'Sorry, word not found in current game'
		else
			gridO = room.gridOpened
			if gridO[index] >= 1
				return 'Word already guessed'
			else
				for i, val of gridO
					if gridO[i] > 1
						gridO[i]--
				gridO[index] = 4
				Rooms.update room._id, $set: gridOpened: gridO, updatedAt: new Date
				printGrid(o.chat.id, room, 0, false)
				if room.telegramMaster
					printGrid(room.telegramMaster, room, 1, false)
		false
	TelegramBot.addListener '/view', (c, u, o) ->
		room = Rooms.findOne({telegram: o.chat.id})
		if !room
			return 'Sorry, you are not in a game room as a normal player'
		printGrid(o.chat.id, room, 0, false)
		false
	TelegramBot.addListener '/read', (c, u, o) ->
		room = Rooms.findOne({telegram: o.chat.id})
		if !room
			return 'Sorry, you are not in a game room as a normal player'
		if room.record == ''
			return 'Room record is currently empty'
		else
			return room.record
	TelegramBot.addListener '/write', (c, u, o) ->
		room = Rooms.findOne({telegram: o.chat.id})
		if !room
			return 'Sorry, you are not in a game room as a normal player'
		if c.length < 2
			return 'Please put something after /write to save to the record'
		record = c[1..].join(' ')
		Rooms.update room._id, $set: record: record
		'Overwrote previous record!'
	TelegramBot.addListener '/leave', (c, u, o) ->
		room = Rooms.findOne({telegram: o.chat.id})
		roomM = Rooms.findOne({telegramMaster: o.chat.id})
		if room
			Rooms.update room._id, $set: telegram: null
			createLog room._id, 'A telegram chat has been disconnected'
			TelegramBot.method 'sendMessage',
				chat_id: o.chat.id
				text: 'Left room as a normal player!'
				reply_markup: noKeyboard()
			return
		else if roomM
			Rooms.update roomM._id, $set: telegramMaster: null
			createLog roomM._id, 'A spymaster telegram chat has been disconnected'
			return 'Left room as spymaster!'
		else
			return 'You are not in a game room anyway'
	TelegramBot.addListener '/web', (c, u, o) ->
		url = WEB_URL
		room = Rooms.findOne({telegram: o.chat.id})
		if room
			return url+"code/"+room.accessCode.replace(/ /g, "%20")
		else
			return url
	TelegramBot.addListener '/help', (c, u, o) ->
		"/join aaa bbb ccc \n
		Replace access code with the one for your room on the web app to link this chat to that room as a normal player \n\n

		/joinmaster aaa bbb ccc \n
		Replace master code with the one for your room on the web app to link this chat to that room as a spymaster \n\n

		/guess \n
		Show word keyboard \n\n

		/g aaa \n
		Take your turn and guess the word after /g \n\n

		/view \n
		Check the current state of the game board \n\n

		/read \n
		Read the current record \n\n

		/write this is text \n
		Overwrite the current record with your text to help everyone remember info about the game, e.g. who's on which team \n\n

		/leave \n
		Delink this chat from the current game room (spymaster or not) \n\n

		/web \n
		Get link to web app \n\n

		For the spymaster, the bolded word in your grid is the most recently guessed, and italicised words are guessed, and the normal text are unguessed
		"
	return

chunkArray = (array, chunkSize) ->
	[].concat.apply [], array.map((elem, i) ->
		if i % chunkSize then [] else [ array.slice(i, i + chunkSize) ]
	)
	
getKeyboard = (room) ->
	grid = room.gridWords
	grid = grid.map((item, index) ->
		"/g "+item
	)
	kb = chunkArray(grid, room.width)
	return kb

makeKeyboard = (kb) ->
	JSON.stringify keyboard: kb, one_time_keyboard: true
	
noKeyboard = ->
	JSON.stringify hide_keyboard: true
	
@printGrid = (chatID, room, isMaster, withKeyboard) ->
	grid = room.gridWords
	grid = grid.map((item, index) ->
		if isMaster
			if room.gridOpened[index] >= 4
				"*"+item+" ("+room.gridColours[index]+")*"
			else if room.gridOpened[index] >= 1
				"_"+item+" ("+room.gridColours[index]+")_"
			else
				item+" ("+room.gridColours[index]+")"
		else
			if room.gridOpened[index] >= 4
				"*"+item+" ("+room.gridColours[index]+")*"
			else if room.gridOpened[index] >= 2
				"_"+item+" ("+room.gridColours[index]+")_"
			else if room.gridOpened[index] >= 1
				item+" ("+room.gridColours[index]+")"
			else
				item
	)
	chunkedGrid = chunkArray(grid, room.width)
	draftGrid = []
	for row in chunkedGrid
		row = row.join(' | ')
		draftGrid.push(row)
	draftGrid = draftGrid.join('\n------------------------------------------\n')
	if withKeyboard
		TelegramBot.method 'sendMessage',
			chat_id: chatID
			text: draftGrid
			parse_mode: "Markdown"
			reply_markup: makeKeyboard(getKeyboard(room))
	else
		TelegramBot.method 'sendMessage',
			chat_id: chatID
			text: draftGrid
			parse_mode: "Markdown"

@messageFromWeb = (chatID, text, hideKeyboard) ->
	if hideKeyboard
		TelegramBot.method 'sendMessage',
			chat_id: chatID
			text: text
			reply_markup: noKeyboard()
	else
		TelegramBot.method 'sendMessage',
			chat_id: chatID
			text: text

createLog = (roomID, msg) ->
	log = 
		content: msg
		roomID: roomID
		createdAt: new Date
	Logs.insert log
	return
