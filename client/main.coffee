$(document).ready ->
	lastTouchY = 0
	preventPullToRefresh = false
	$('body').on 'touchstart', (e) ->
		if e.originalEvent.touches.length != 1
			return
		lastTouchY = e.originalEvent.touches[0].clientY
		preventPullToRefresh = window.pageYOffset == 0
		return
	$('body').on 'touchmove', (e) ->
		touchY = e.originalEvent.touches[0].clientY
		touchYDelta = touchY - lastTouchY
		lastTouchY = touchY
		if preventPullToRefresh
			# To suppress pull-to-refresh it is sufficient to preventDefault the first overscrolling touchmove.
			preventPullToRefresh = false
			if touchYDelta > 0
				e.preventDefault()
				return
		return
	return

Template.registerHelper 'equals', (a, b) ->
	a == b

Template.registerHelper 'formatDateTime', (datetime) ->
	moment(datetime).format('D MMM hh:mm A')

Template.main.helpers
	whichView: ->
		Session.get 'currentView'

Template.lobby.events
	'click button#newRoom': ->
		roomID = generateNewRoom()
		room = Rooms.findOne(roomID)
		if room
			generateGridWords(room)
			generateGridColours(room)
			generateGridOpened(room)
			Meteor.subscribe "rooms", roomID, null,
				onReady: ->
					Session.set 'currentView', 'inGame'
					Session.set 'roomID', roomID
					Session.set "masterCode", room.masterCode
			Meteor.subscribe "logs", roomID
	'click button#joinRoom': ->
		accessCode = $('#accessCode').val().trim().toLowerCase()
		joinRoomWithCode(accessCode)

@joinRoomWithCode = (accessCode) ->
	Meteor.call 'findRoomByMaster', accessCode, (error, result) ->
		if error
			FlashMessages.sendError "Sorry, could not connect to server. Please try again later."
		else
			room = result
			roomID = null
			subAccessCode = accessCode
			if room
				roomID = room._id
				subAccessCode = null
			Meteor.subscribe 'rooms', roomID, subAccessCode,
				onReady: ->
					room = Rooms.findOne({accessCode: accessCode})
					isMaster = false
					if !room
						room = Rooms.findOne({masterCode: accessCode})
						isMaster = true
					if room
						Meteor.subscribe "logs", room._id
						Session.set 'currentView', 'inGame'
						Session.set 'roomID', room._id
						if isMaster
							Session.set 'masterCode', accessCode
							msg = "Someone has joined as a spymaster"
							createLog msg
							teleUpdate(null, msg)
					else
						FlashMessages.sendError "Sorry, could not find any room with that access code."
						# below is only necessary as this method is called from the access code route as well
						Session.set 'currentView', 'lobby'
						Session.set 'roomID', null

Template.inGame.helpers
	accessCode: ->
		room = getCurrentRoom()
		if room
			room.accessCode
	masterCode: ->
		room = getCurrentRoom()
		if room
			room.masterCode
	width: ->
		room = getCurrentRoom()
		if room
			room.width
	height: ->
		room = getCurrentRoom()
		if room
			room.height
	wordListTypes: ->
		room = getCurrentRoom()
		if room
			({key: key, value: value, selected: room.wordListType == key} for key, value of wordListTypes)
	wordListCustom: ->
		room = getCurrentRoom()
		if room
			room.wordListCustom.join(", ")
	customWordsFormClass: ->
		room = getCurrentRoom()
		if room
			if room.wordListType == "custom"
				""
			else
				"hidden"
	count1: ->
		room = getCurrentRoom()
		if room
			room.count1
	count2: ->
		room = getCurrentRoom()
		if room
			room.count2
	countA: ->
		room = getCurrentRoom()
		if room
			room.countA
	gridWords: ->
		room = getCurrentRoom()
		if room
			gridWords = room.gridWords.map((item, index) ->
				colour = room.gridColours[index]
				opened = room.gridOpened[index]
				openedWhen = "opened"+opened
				if opened > 1
					opened = 1
				{index: index, word: item, colour: colour, opened: opened, openedWhen: openedWhen}
			)
			gridWords
	isRoomState: (state) ->
		room = getCurrentRoom()
		if room
			room.state == state
	isSpymaster: ->
		room = getCurrentRoom()
		if room
			room.masterCode == Session.get 'masterCode'
		else
			false

Template.inGame.events
	'click .card.preparing': (event) ->
		room = getCurrentRoom()
		if !room
			return false
		index = $(event.target).attr('data-index')
		index = parseInt(index)
		newWord = prompt("Replace with:", "")
		if newWord
			newWord = newWord.trim()
			grid = room.gridWords
			existingIndex = grid.indexOf(newWord)
			existingIndex2 = grid.indexOf(newWord.toLowerCase())
			if existingIndex == -1 && existingIndex2 == -1
				grid[index] = newWord
				Rooms.update room._id, $set: gridWords: grid, updatedAt: new Date
			else
				alert("That's a duplicate of a word already on the board")
	'click .card.started': (event) ->
		room = getCurrentRoom()
		if !room
			return false
		index = $(event.target).attr('data-index')
		index = parseInt(index)
		grid = room.gridOpened
		if grid[index] > 0
			return false
		word = $(event.target).text()
		if $('#reqConfirm').is(":checked")
			choice = confirm "Are you sure you want to guess the word '"+word+"'?"
			if !choice
				return false
		for i, val of grid
			if grid[i] > 1
				grid[i]--
		grid[index] = 4
		Rooms.update room._id, $set: gridOpened: grid, updatedAt: new Date
		teleUpdate(room, "Word guessed: "+word)
		teleGrid(room, false)
	'click button#startGame': ->
		room = getCurrentRoom()
		if !room
			return false
		Rooms.update room._id, $set: state: 'started', updatedAt: new Date
		teleUpdate(room, "Game started")
		teleGrid(room, true)
	'click button#prepareGame': ->
		room = getCurrentRoom()
		if !room
			return false
		generateGridWords(room)
		generateGridColours(room)
		generateGridOpened(room)
		Rooms.update room._id, $set: state: 'preparing', updatedAt: new Date
		teleUpdateHideKeyboard(room, "Preparing new game")
		clearLogs()
	'change select#wordListType': ->
		room = getCurrentRoom()
		if !room
			return false
		wordListType = $('select#wordListType').val()
		Rooms.update room._id, $set: wordListType: wordListType, updatedAt: new Date
	'click button#becomeNormal': ->
		Session.set "masterCode", null
		msg = "Someone has stopped being a spymaster"
		createLog msg
		teleUpdate(null, msg)
	'click button#becomeMaster': ->
		room = getCurrentRoom()
		if !room
			return false
		masterCode = $('#masterCode').val().trim().toLowerCase()
		if masterCode == room.masterCode
			Session.set "masterCode", masterCode
			msg = "Someone has become a spymaster"
			createLog msg
			teleUpdate(null, msg)
		else
			FlashMessages.sendError "Sorry, wrong master code"
	'click button#resetMasterCode': ->
		room = getCurrentRoom()
		if !room
			return false
		newMasterCode = generateAccessCode()
		if room.telegramMaster
			teleUpdateFull(room, 'You have been disconnected from your room as spymaster', 1)
		Rooms.update room._id, $set: masterCode: newMasterCode, telegramMaster: null, updatedAt: new Date
		Session.set "masterCode", newMasterCode
		msg = "Someone has reset the master code and become a spymaster"
		createLog msg
		teleUpdate(null, msg)
	'click button#resetColours': ->
		room = getCurrentRoom()
		if !room
			return false
		count1 = parseInt($('#count1').val().trim())
		count2 = parseInt($('#count2').val().trim())
		countA = parseInt($('#countA').val().trim())
		if !checkNumber(count1) or !checkNumber(count2) or !checkNumber(countA)
			FlashMessages.sendError "Counts must be positive integers within a reasonable range"
			return false
		if room.width * room.height < count1 + count2 + countA
			FlashMessages.sendError "The total number of these card types must not exceed the total number of cards"
			return false
		Rooms.update room._id, $set: count1: count1, count2: count2, countA: countA, updatedAt: new Date
		room = Rooms.findOne(room._id)
		generateGridColours(room)
		generateGridOpened(room)
	'click button#resetWords': ->
		room = getCurrentRoom()
		if !room
			return false
		gridWidth = parseInt($('#gridWidth').val().trim())
		gridHeight = parseInt($('#gridHeight').val().trim())
		if !checkNumber(gridWidth) or !checkNumber(gridHeight)
			FlashMessages.sendError "Grid dimensions must be positive integers within a reasonable range"
			return false
		Rooms.update room._id, $set: width: gridWidth, height: gridHeight, updatedAt: new Date
		room = Rooms.findOne(room._id)
		generateGridWords(room)
		generateGridColours(room) #ensure match grid size
		generateGridOpened(room) #ensure match grid size
	'click button#toggleWords': ->
		$(".word").toggle()
	'click button#leaveRoom': ->
		Session.set 'currentView', 'lobby'
		Session.set 'roomID', null
		Session.set "masterCode", null

Template.logs.helpers
	logs: ->
		room = getCurrentRoom()
		if !room
			return null
		logs = Logs.find({ 'roomID': room._id }, sort: createdAt: -1).fetch()
		logs

createLog = (msg) ->
	room = getCurrentRoom()
	if !room
		return
	log = 
		content: msg
		roomID: room._id
		createdAt: new Date
	Logs.insert log
	return

clearLogs = ->
	room = getCurrentRoom()
	if !room
		return
	logs = Logs.find('roomID': room._id).fetch()
	logs.forEach (log) ->
		Logs.remove log._id
		return
	return

generateNewRoom = ->
	room = 
		accessCode: generateAccessCode()
		masterCode: generateAccessCode()
		state: 'preparing'
		record: ''
		gridWords: []
		gridColours: []
		gridOpened: []
		wordListType: 'original'
		wordListCustom: ["example 1", "example 2", "example 3"]
		width: 5
		height: 5
		count1: 9
		count2: 8
		countA: 1
		telegram: null
		telegramMaster: null
		createdAt: new Date
		updatedAt: new Date
	roomID = Rooms.insert(room)
	#room = Rooms.findOne(roomID);
	roomID

getCurrentRoom = ->
	roomID = Session.get 'roomID'
	if roomID
		return Rooms.findOne(roomID)
	return

getRandom = (length) ->
	#return Math.floor(Math.random() * length);
	Math.floor Random.fraction() * length
	
shuffleArray = (a) ->
	i = a.length
	while --i > 0
		j = ~~(Math.random() * (i + 1)) # ~~ is a common optimization for Math.floor
		t = a[j]
		a[j] = a[i]
		a[i] = t
	a

generateAccessCode = ->
	code = access[getRandom(access.length)] + ' ' + access[getRandom(access.length)] + ' ' + access[getRandom(access.length)]
	code

generateGridWords = (room) ->
	grid = []
	if room.wordListType == "custom"
		customWordsString = $('textarea#customWords').val()
		if customWordsString
			customWordsArray = customWordsString.split(',')
			customWordsArray = (string.trim() for string in customWordsArray)
			Rooms.update room._id, $set: wordListCustom: customWordsArray, updatedAt: new Date
			wordList = customWordsArray
		else
			wordList = room.wordListCustom
	else
		wordList = words[room.wordListType]
	length = room.width * room.height
	for x in [1..length]
		index = getRandom(wordList.length)
		word = wordList[index]
		wordList.splice(index, 1);
		grid.push(word)
	Rooms.update room._id, $set: gridWords: grid, updatedAt: new Date

generateGridColours = (room) ->
	grid = []
	length = room.width * room.height
	countB = length - room.count1 - room.count2 - room.countA
	if countB < 0
		return false
	order = ["red", "blue"]
	if getRandom(2)
		order = ["blue", "red"]
	for x in [1..room.count1]
		grid.push(order[0])
	for x in [1..room.count2]
		grid.push(order[1])
	for x in [1..room.countA]
		grid.push("black")
	for x in [1..countB]
		grid.push("yellow")
	shuffleArray(grid)
	Rooms.update room._id, $set: gridColours: grid, updatedAt: new Date

generateGridOpened = (room) ->
	grid = []
	length = room.width * room.height
	for x in [1..length]
		grid.push(0)
	Rooms.update room._id, $set: gridOpened: grid, updatedAt: new Date

checkNumber = (thingy) ->
	if !thingy or typeof thingy is not "number" or isNaN(thingy)
		return false
	if thingy < 0 or thingy > 25
		return false
	true

teleGrid = (room, withKeyboard) ->
	chatID = room.telegram
	if chatID
		Meteor.call 'printGrid', chatID, room, 0, withKeyboard
	chatIDm = room.telegramMaster
	if chatIDm
		Meteor.call 'printGrid', chatIDm, room, 1, withKeyboard

teleUpdate = (room, text) ->
	teleUpdateFull(room, text, 0, false)

teleUpdateHideKeyboard = (room, text) ->
	teleUpdateFull(room, text, 0, true)

teleUpdateFull = (room, text, isMaster, hideKeyboard) ->
	if !room
		room = getCurrentRoom()
	if !room
		return
	if isMaster
		chatID = room.telegramMaster
	else
		chatID = room.telegram
	if chatID
		Meteor.call 'messageFromWeb', chatID, text, hideKeyboard
