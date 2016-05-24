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
	joinRoomWithCode(accessCode)
	#window.history.pushState({}, null, "/")
	window.history.replaceState({}, null, "/")
