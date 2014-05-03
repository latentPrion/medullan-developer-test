<%
	 '' FIXME:
	 ''

	''	EXPLANATION:
	 ' I think my plan here will be to just store each game
	 ' as an object within the "Application" collection, then
	 ' look them up. That will be the storage strategy.
	 '
	 ' Each ongoing game will be represented by a cGame object.
	 ' cGame instances will track the player names, the number of
	 ' players in a game (max of 2 per game), and the state of the
	 ' board.
	 '
	 ' The front-end page is really just an interface that informs the
	 ' back-end here of a particular player's actions. When an action is
	 ' taken, the logic in this file updates the cGame object for the
	 ' relevant ongoing game, and refreshes the page.
	 '
	 ' When establishing new games, the players are linked via the game
	 ' name, as specified in the task description.
	 ''

	 ''
	 ' For the most part, I'm just going to port over my javascript tic-tac-toe
	 ' and pretty much translate it into VBScript, because I'd like to potentially
	 ' also port my AI, since it would be nice to get the extra points the AI
	 ' backlog bonus task.
	 ''

' Ported over the plans from the JS implementation.
dim lossPlan
lossPlan = array( _
		"O", "O", "O", _
		"O", "O", "O", _
		"O", "O", "O" _
)

dim plans
plans = array ( _
		array( _
			"O", "O", "O", _
			"", "", "", _
			"", "", "" _
		), _
		array( _
			"", "", "", _
			"O", "O", "O", _
			"", "", "" _
		), _
		array( _
			"", "", "", _
			"", "", "", _
			"O", "O", "O" _
		), _
		array( _
			"O", "", "", _
			"O", "", "", _
			"O", "", "" _
		), _
		array( _
			"", "O", "", _
			"", "O", "", _
			"", "O", "" _
		), _
		array( _
			"", "", "O", _
			"", "", "O", _
			"", "", "O" _
		), _
		array( _
			"O", "", "", _
			"", "O", "", _
			"", "", "O" _
		), _
		array( _
			"", "", "O", _
			"", "O", "", _
			"O", "", "" _
		) _
	)


' Main is the entry point for the page.
main()

' Class that represents an ongoing game.
Class cGame
	public nPlayers
	public playerNames
	public gameName
	public grid
	public nEmpty
	public currentPlayer
	public lastPlayer
	public gameOver
	public gameWinner

	public function cmpGameName(name)
		if gameName = name then
			cmpGameName = 1
		else
			cmpGameName = 0
		end if
	end function

	public sub Class_Initialize()
		nPlayers = 0
		playerNames = array("", "")
		gameName = ""
		grid = Array("", "", "", "", "", "", "", "", "")
		nEmpty = 9
		currentPlayer = ""
		lastPlayer = ""
		gameOver = 0
		gameWinner = ""
	end sub
end Class

' Class that represents a POST or GET request.
Class cTttRequest
	public gameName
	public playerName
	public squarePlayed
	public isResetRequest

	sub Class_Initialize()
		gameName = null
		playerName = null
		squarePlayed = null
		isResetRequest = 0
	end sub
end class

Class cTttResponse
	public status
	public statusMessage
	public grid
	public gameOver
	public gameWinner

	Sub Class_Initialize()
		status = 0
		statusMessage = null
		grid = Array("", "", "", "", "", "", "", "", "")
		gameOver = 0
		gameWinner = null
	end sub
end Class

sub main()
	dim resp, req, gameIndex

	' Allocate our response object.
	set resp = new cTttResponse
	set req = new cTttRequest

	if isEmpty(Request.Form("ttt_gameName")) OR Request.Form("ttt_gameName") = "" _
		OR isEmpty(Request.Form("ttt_playerName")) OR request.form("ttt_playerName") = "" then

		' Game and player names are mandatory.
		resp.statusMessage = Server.urlEncode("Please fill both the ""game name"" and ""player"" fields")
		resp.status = 3
		ttt_writeJson(resp)
		exit sub
	end if

	if isEmpty(request.form("ttt_grid_action")) _
		OR (request.form("ttt_grid_action") = "play" AND request.form("ttt_grid_activeSquare") = "") _
		then

		' Can't submit the form without choosing an action.
		resp.statusMessage = Server.urlEncode("Try not to press <return> on your keyboard." &_
			"Use the 'reset' or 'refresh' buttons, or click a square on the grid to make a move." &_
			"If the grid is blank, refresh to see it again.")

		resp.status = 1
		ttt_writeJson(resp)
		exit sub
	end if

	req.gameName = request.form("ttt_gameName")
	req.playerName = request.form("ttt_playerName")

	' Do we need to create a new game, or does one with the POSTed name exist?
	gameIndex = ttt_getOngoingGameIndex(req.gameName)
	if gameIndex < 0 then
		ttt_createNewOngoingGame(req)
		gameIndex = ttt_getOngoingGameIndex(req.gameName)
	end if

	if CInt(application("tg_nPlayers")(gameIndex)) = 2 _
		AND (application("tg_playerNames")(gameIndex)(0) <> req.playerName _
		AND application("tg_playerNames")(gameIndex)(1) <> req.playerName) _
	then
		' Only 2 players are allowed per game.
		resp.status = 3
		resp.statusMessage = Server.URLEncode("Only two players are allowed per game")
		resp.grid = application("tg_grids")(gameIndex)
		ttt_writeJson(resp)
		exit sub
	end if

	if CInt(application("tg_nPlayers")(gameIndex)) = 1 _
		AND application("tg_playerNames")(gameIndex)(0) <> req.playerName _
	then
		dim		pnames, nplayers

		pnames = application("tg_playerNames")
		nplayers = application("tg_nPlayers")

		' Add the new player.
		pnames(gameIndex)(1) = req.playerName
		nplayers(gameIndex) = 2

		application("tg_playerNames") = pnames
		application("tg_nPlayers") = nplayers
		' Don't exit sub here. Continue to process the click event.
	end if

	if request.form("ttt_grid_action") = "reset" then
		req.isResetRequest = 1

		' Handle the reset request
		' Basically, reset the game and serve a blank grid to the browser.
		ttt_resetOngoingGame(gameIndex)
		resp.grid = application("tg_grids")(gameIndex)
		ttt_writeJson(resp)
		exit sub
	end if

	if request.form("ttt_grid_action") = "refresh" then
		' Just echo the current grid state back to the client.
		resp.grid = application("tg_grids")(gameIndex)
		resp.gameOver = application("tg_gameOvers")(gameIndex)
		resp.gameWinner = application("tg_gameWinners")(gameIndex)
		ttt_writeJson(resp)
		exit sub
	end if

	' Don't allow the same player to play twice in a row.
	if (req.playerName = application("tg_lastPlayers")(gameIndex)) then
		resp.status = 2
		resp.statusMessage = Server.URLEncode("It's not your turn")
		resp.grid = application("tg_grids")(gameIndex)
		ttt_writeJson(resp)
		exit sub
	end if

	' Else, handle the move made by the player.
	dim		result
	req.squarePlayed = CInt(request.form("ttt_grid_activeSquare"))
	result = ttt_clickEvent(gameIndex, req)

	if result = "occupied" then
		resp.status = 2
		resp.statusMessage = server.urlEncode("The square you chose is occupied")
		resp.grid = application("tg_grids")(gameIndex)
		ttt_writeJson(resp)
		exit sub
	end if

	' ttt_dumpOngoingGames
	resp.grid = application("tg_grids")(gameIndex)
	resp.gameOver = application("tg_gameOvers")(gameIndex)
	resp.gameWinner = application("tg_gameWinners")(gameIndex)

	ttt_writeJson(resp)
end sub

sub ttt_createNewOngoingGame(req)
	if isEmpty(application("tg_gameNames")) then
		application("tg_gameNames") = array()
		application("tg_playerNames") = array()
		application("tg_nPlayers") = array()
		application("tg_grids") = array()
		application("tg_nEmpties") = array()
		application("tg_currentPlayers") = array()
		application("tg_lastPlayers") = array()
		application("tg_gameOvers") = array()
		application("tg_gameWinners") = array()
	end if

	' Because VBScript is a retarded language, we have to use this hacky storage layout.
	' I had to waste a *LOT* of time before discovering that VBScript and ASP together
	' don't support storing custom class instances in the "Application" collection.
	'
	' Real terror, that wasted a LOT of my time.
	dim		tmpArr

	tmpArr = application("tg_gameNames")
	redim preserve tmpArr(ubound(tmpArr) + 1)
	tmpArr(ubound(tmpArr)) = req.gameName
	application("tg_gameNames") = tmpArr

	tmpArr = application("tg_playerNames")
	redim preserve tmpArr(ubound(tmpArr) + 1)
	tmpArr(ubound(tmpArr)) = array(req.playerName, "")
	application("tg_playerNames") = tmpArr

	tmpArr = application("tg_nPlayers")
	redim preserve tmpArr(ubound(tmpArr) + 1)
	tmpArr(ubound(tmpArr)) = 1
	application("tg_nPlayers") = tmpArr

	tmpArr = application("tg_grids")
	redim preserve tmpArr(ubound(tmpArr) + 1)
	tmpArr(ubound(tmpArr)) = array("", "", "", "", "", "", "", "", "")
	application("tg_grids") = tmpArr

	tmpArr = application("tg_nEmpties")
	redim preserve tmpArr(ubound(tmpArr) + 1)
	tmpArr(ubound(tmpArr)) = 9
	application("tg_nEmpties") = tmpArr

	tmpArr = application("tg_currentPlayers")
	redim preserve tmpArr(ubound(tmpArr) + 1)
	tmpArr(ubound(tmpArr)) = "X"
	application("tg_currentPlayers") = tmpArr

	tmpArr = application("tg_lastPlayers")
	redim preserve tmpArr(ubound(tmpArr) + 1)
	tmpArr(ubound(tmpArr)) = ""
	application("tg_lastPlayers") = tmpArr

	tmpArr = application("tg_gameOvers")
	redim preserve tmpArr(ubound(tmpArr) + 1)
	tmpArr(ubound(tmpArr)) = 0
	application("tg_gameOvers") = tmpArr

	tmpArr = application("tg_gameWinners")
	redim preserve tmpArr(ubound(tmpArr) + 1)
	tmpArr(ubound(tmpArr)) = ""
	application("tg_gameWinners") = tmpArr
end sub

function ttt_getOngoingGameIndex(gameName)
	dim		i, result, tmpObj
	dim		currGame

	'' Returns -1 if the a game with the specified name doesn't exist.
	ttt_getOngoingGameIndex = -1

	if isEmpty(Application("tg_gameNames")) then
		exit function
	end if

	i = 0
	for each currGame in application("tg_gameNames")
		if (currGame = gameName) then
			ttt_getOngoingGameIndex = i
			exit function
		end if

		i = i + 1
	next
end function

sub ttt_resetOngoingGame(index)
	dim		tmpArr

	' XXX: Probably buggy.
	tmpArr = application("tg_nEmpties")
	tmpArr(index) = 9
	application("tg_nEmpties") = tmpArr

	tmpArr = application("tg_grids")
	tmpArr(index) = array("", "", "", "", "", "", "", "", "")
	application("tg_grids") = tmpArr

	tmpArr = application("tg_gameOvers")
	tmpArr(index) = 0
	application("tg_gameOvers") = tmpArr

	tmpArr = application("tg_currentPlayers")
	tmpArr(index) = "X"
	application("tg_currentPlayers") = tmpArr

	tmpArr = application("tg_lastPlayers")
	tmpArr(index) = ""
	application("tg_lastPlayers") = tmpArr

	tmpArr = application("tg_gameWinners")
	tmpArr(index) = ""
	application("tg_gameWinners") = tmpArr
end sub

function ttt_clickEvent(gindex, req)
	' If they clicked on an filled-out board, or if
	' the game is already over, reject the event.
	if application("tg_gameOvers")(gindex) = 1 then
		ttt_clickEvent = application("tg_gameWinners")(gindex)
		exit function
	end if

	' If board is full or game is over, ignore.
	if application("tg_nEmpties")(gindex) = 0 then
		ttt_clickEvent = "ignore"
		exit function
	end if

	' Don't allow cheating: if the user clicked on an occupied square,
	' reject the event.
	if application("tg_grids")(gindex)(req.squarePlayed) <> "" then
		ttt_clickEvent = "occupied"
		exit function
	end if

	ttt_board_userPlay gindex, req.squarePlayed
	if ttt_board_checkForVictoryCondition(gindex, req) = 1 then
		ttt_clickEvent = application("tg_gameWinners")(gindex)
		exit function
	end if
	if ttt_board_checkForTieCondition(gindex, req) = 1 then
		ttt_clickEvent = application("tg_gameWinners")(gindex)
		exit function
	end if

	ttt_board_setLastPlayer gindex, req
	ttt_board_changePlayer gindex
	ttt_clickEvent = "continue"
end function

function ttt_board_checkForVictoryCondition(gindex, req)
	dim		i, currPlan, currSquare, xPoints, oPoints, grid

	grid = application("tg_grids")(gindex)
	ttt_board_checkForVictoryCondition = 0

	for each currPlan in plans

		xPoints = 0
		oPoints = 0

		i = 0
		for each currSquare in currPlan
			if currSquare <> "" then

				if grid(i) = "" then
					exit for
				end if

				if grid(i) = "X" then
					xPoints = xPoints + 1
				else
					oPoints = oPoints + 1
				end if

				if xPoints > 0 AND oPoints > 0 then
					exit for
				end if

				' Finally, check for victory.
				if (xPoints = 3 OR oPoints = 3) then
					dim		tmpArr

					tmpArr = application("tg_gameOvers")
					tmpArr(gindex) = 1
					application("tg_gameOvers") = tmpArr

					tmpArr = application("tg_gameWinners")
					tmpArr(gindex) = application("tg_currentPlayers")(gameIndex)
					application("tg_gameWinners") = tmpArr

					ttt_board_checkForVictoryCondition = 1
					exit function
				end if
			end if

			i = i + 1
		next
	next

end function

function ttt_board_checkForTieCondition(gindex, req)
	ttt_board_checkForTieCondition = 0
	if application("tg_nEmpties")(gindex) = 0 then
		dim		tmpArr

		tmpArr = application("tg_gameOvers")
		tmpArr(gindex) = 1
		application("tg_gameOvers") = tmpArr

		tmpArr = application("tg_gameWinners")
		tmpArr(gindex) = "tie"
		application("tg_gameWinners") = tmpArr

		ttt_board_checkForTieCondition = 1
	end if
end function

sub ttt_board_setSquare(gindex, square, mark)
	dim		tmpArr

	tmpArr = application("tg_grids")
	tmpArr(gindex)(square) = mark
	application("tg_grids") = tmpArr

	tmpArr = application("tg_nEmpties")
	tmpArr(gindex) = CInt(tmpArr(gindex)) - 1
	application("tg_nEmpties") = tmpArr
end sub

sub ttt_board_userPlay(gindex, square)
	ttt_board_setSquare gindex, square, application("tg_currentPlayers")(gindex)
end sub

sub ttt_board_changePlayer(gindex)
	dim		tmpArr

	tmpArr = application("tg_currentPlayers")

	if tmpArr(gindex) = "X" then
		tmpArr(gindex) = "O"
	else
		tmpArr(gindex) = "X"
	end if

	application("tg_currentPlayers") = tmpArr
end sub

sub ttt_board_setLastPlayer(gindex, req)
	tmpArr = application("tg_lastPlayers")
	tmpArr(gindex) = req.playerName
	application("tg_lastPlayers") =  tmpArr
end sub

sub ttt_dumpOngoingGames()
	dim		i

	if isEmpty(Application("tg_gameNames")) then
		exit sub
	end if

	Response.write "Dumping games:<br />"
	Response.write "<ul>"
	i = 0
	for each game in Application("tg_gameNames")
	%>
		<li>Name: <%=game%></li>
		<li>NPlayers: <%=application("tg_nPlayers")(i)%></li>
		<li>Player0: <%=application("tg_playerNames")(i)(0)%></li>
		<li>Player1: <%=application("tg_playerNames")(i)(1)%></li>
	<%
	i = i + 1
	next
	Response.write "</ul>"
end sub

sub ttt_writeJson(obj)
	dim		i

	' Set the HTTP headers first, since we're going to send out a response regardless.
	response.addHeader "Content-Type", "application/json; charset=utf8"
	response.addHeader "Cache-Control", "private, max-age=0, no-cache no-transform"

	response.write "{"
		response.write """status"": " & obj.status & ","
		response.write """statusMessage"": """ & obj.statusMessage & ""","
		response.write """gameOver"": " & obj.gameOver & ","
		response.write """gameWinner"": """ & obj.gameWinner & ""","
		response.write """grid"": ["
			for i = 0 to 7
				response.write """" & obj.grid(i) & ""","
			next
				
				response.write """" & obj.grid(8) & """"
		response.write "]"
	response.write "}"
end sub

sub dumpVar(v)
	For Each item in v
		If IsArray(item) Then
			for each i in item
			 Response.write(item & " : " & Application.Contents(item) & "<BR>")
			Next
		Else
			Response.write(item & " : " & Application.Contents(item) & "<BR>")
		End If
	next
end sub
%>
