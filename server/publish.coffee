Meteor.publish 'rooms', (eyedee, accessCode) ->
	Rooms.find $or: [{_id: eyedee},{accessCode: accessCode}]

Meteor.publish 'logs', (roomID) ->
	Logs.find roomID: roomID
