Router.route '/', ->
	GAnalytics.pageview("main")
	@render 'main'
	if !Session.get('currentView')
		Session.set 'currentView', 'lobby'
	else
		Meteor.subscribe 'rooms', Session.get('roomID'), null, null
		Meteor.subscribe 'logs', Session.get('roomID')
	return

Router.route '/code/:accessCode', ->
	GAnalytics.pageview("code")
	@render 'main'
	accessCode = this.params.accessCode.trim().toLowerCase()
	if Session.get "roomID" # careful, this is reactive
		check = confirm "You are already in a game room. Are you sure you want to leave and join a new room with the access code '" + accessCode + "'?"
		if check
			joinRoomWithCode(accessCode)
	else
		joinRoomWithCode(accessCode)
	#window.history.pushState({}, null, "/")
	#window.history.replaceState({}, null, "/")
	this.redirect('/')
