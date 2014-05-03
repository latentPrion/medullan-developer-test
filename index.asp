<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">

<head>
	<meta http-equiv="content-type" content="text/html; charset=utf8" />
	<title></title>

	<link rel="stylesheet" type="text/css" href="css/bootstrap.min.css" />
	<style type="text/css">
		table.ttt-grid, div.ttt-grid {
			width: 310px;
		}

    div.ttt-grid-container {
      width: 750px;
    }

    div.ttt-name-form {
      width: 400px;
    }

		td.ttt-grid {
			width: 100px;
		}

		tr.ttt-grid {
			height: 100px;
		}

		.ttt-grid-button {
			width: 100%;
			height: 100px;
		}

    .ttt-name-input {
      
    }

		h4.ttt-message {
		}
	</style>
</head>

<body>
	<div class="container">
		<h1 class="text-center">Medullan Developer Test</h1>
		<h2>Candidate name: Kofi Doku Atuah</h2>
		<h3 class="text-muted">Email: <a href="mailto:latentprion@gmail.com">latentprion@gmail.com</a></h3>
		<h3 class="text-muted">LinkedIn: <a href="http://www.linkedin.com/pub/kofi-doku-atuah/4a/205/14">http://www.linkedin.com/pub/kofi-doku-atuah/4a/205/14</a></h3>
		<h3 class="text-muted">Github: <a href="http://github.com/latentprion">http://github.com/latentprion</a></h3>

    <div class="ttt-grid-container center-block">
    <form method="post" action="logic.asp" id="ttt_grid_form">
      <input type="hidden" id="ttt_grid_activeSquare" name="ttt_grid_activeSquare" value="" />
      <input type="hidden" id="ttt_grid_action" name="ttt_grid_action" value="play" />
      <div class="ttt-name-form pull-left">
        <table>
        <tbody>
          <tr>
            <td>Player name:</td>
            <td><input class="ttt-name-input" type="text" id="ttt_playerName" name="ttt_playerName" /></td>
          </tr>
          <tr>
            <td>Game name:</td>
            <td><input class="ttt-name-input" type="text" id="ttt_gameName" name="ttt_gameName" /></td>
          </tr>
          <tr>
            <td colspan="2">
              <button type="button" class="btn btn-primary" onclick="javascript:ttt_sendRefreshRequest();">Refresh</button>
              <button type="button" class="btn btn-primary" onclick="javascript:ttt_sendResetRequest();">New game</button>
            </td>
          </tr>
        </tbody>
        </table>
      </div>

      <div class="ttt-grid pull-left">
			  <table class="ttt-grid">
			  <thead>
				  <tr>
					  <td class="ttt-grid" colspan="3"><h4 id="ttt_message_notice" class="ttt-message text-info"></h4></td>
				  </tr>
				  <tr>
					  <td class="ttt-grid" colspan="3"><h4 id="ttt_message_warning" class="ttt-message text-warning"></h4></td>
				  </tr>
				  <tr>
					  <td class="ttt-grid" colspan="3"><h4 id="ttt_message_error" class="ttt-message text-error"></h4></td>
				  </tr>
			  </thead>
			  <tbody  id="table_ttt_grid">
				  <tr class="ttt-grid">
            <td class="ttt-grid" ><button type="button" class="ttt-grid-button" onclick="javascript:ttt_form_setActiveSquareAndSubmit(0)"></button></td>
            <td class="ttt-grid" ><button type="button" class="ttt-grid-button" onclick="javascript:ttt_form_setActiveSquareAndSubmit(1)"></button></td>
					  <td class="ttt-grid" ><button type="button" class="ttt-grid-button" onclick="javascript:ttt_form_setActiveSquareAndSubmit(2)"></button></td>
				  </tr>
				  <tr class="ttt-grid">
					  <td class="ttt-grid" ><button type="button" class="ttt-grid-button" onclick="javascript:ttt_form_setActiveSquareAndSubmit(3)"></button></td>
					  <td class="ttt-grid" ><button type="button" class="ttt-grid-button" onclick="javascript:ttt_form_setActiveSquareAndSubmit(4)"></button></td>
					  <td class="ttt-grid" ><button type="button" class="ttt-grid-button" onclick="javascript:ttt_form_setActiveSquareAndSubmit(5)"></button></td>
				  </tr>
				  <tr class="ttt-grid">
					  <td class="ttt-grid" ><button type="button" class="ttt-grid-button" onclick="javascript:ttt_form_setActiveSquareAndSubmit(6)"></button></td>
					  <td class="ttt-grid" ><button type="button" class="ttt-grid-button" onclick="javascript:ttt_form_setActiveSquareAndSubmit(7)"></button></td>
					  <td class="ttt-grid" ><button type="button" class="ttt-grid-button" onclick="javascript:ttt_form_setActiveSquareAndSubmit(8)"></button></td>
				  </tr>
			  </tbody>
			  </table>
		  </div>
    </form>
    </div>
	</div>

  <script type="text/javascript" src="js/jquery.js"></script>
	<script type="text/javascript">
    function ttt_board_queryAndRedraw() {
      $.post(
        "logic.asp",
        {
          ttt_grid_action: document.getElementById("ttt_grid_action").value,
          ttt_grid_activeSquare: document.getElementById("ttt_grid_activeSquare").value,
          ttt_playerName: document.getElementById("ttt_playerName").value,
          ttt_gameName: document.getElementById("ttt_gameName").value
        },
        function(data, status, jqXhr) {
          var     i, msgElem, gridSquares;

//console.log(data); return;
          /* On successful post, re-render the grid and any messages
           * returned from the server.
           *
           * The server does all of the processing, and it then echoes out the
           * output in JSON. We just take the JSON object and use it to render the
           * new grid state to show the user what the grid currently looks like.
           *
           * We also check for the victor or the tie condition here.
           */
          if (data.gameOver) {
            var       msgElem2;
            
            msgElem2 = document.getElementById("ttt_message_notice");
            if (data.gameWinner == "tie") {
              msgElem2.innerHTML = "Game over: game was a tie.";
            } else {
              msgElem2.innerHTML = "Game over: " + data.gameWinner + " won!";
            };
            
            // Next, fill out the grid's squares.
            gridSquares = document.getElementById("table_ttt_grid").getElementsByTagName("button");
            for (i=0; i<data.grid.length; i++) { // >
              gridSquares[i].innerHTML = data.grid[i];
            };

            return;
          };

          data.statusMessage = decodeURIComponent(
            data.statusMessage.replace(/\+/g, " "));

          console.log("status "+data.status+", message: "+data.statusMessage+".");

          switch (data.status) {
          case 2:
            msgElem = document.getElementById("ttt_message_warning");
            break;
          case 3:
            msgElem = document.getElementById("ttt_message_error");
            break;
          default:
            msgElem = document.getElementById("ttt_message_notice");
            break;
          };

          msgElem.innerHTML = data.statusMessage;

          // Next, fill out the grid's squares.
          gridSquares = document.getElementById("table_ttt_grid").getElementsByTagName("button");
          for (i=0; i<data.grid.length; i++) { // >
            gridSquares[i].innerHTML = data.grid[i];
          };

        },
        "json").fail(function() {
          console.log("Error");
          console.lorg
        });
    }
 
    function ttt_sendResetRequest() {
      document.getElementById('ttt_grid_action').value = 'reset';
      ttt_board_queryAndRedraw();
    }

    function ttt_sendRefreshRequest() {
      document.getElementById('ttt_grid_action').value = 'refresh';
      ttt_board_queryAndRedraw();
    }

    function ttt_form_setActiveSquareAndSubmit(squareNo) {
      document.getElementById('ttt_grid_action').value = 'play';
      document.getElementById('ttt_grid_activeSquare').value = squareNo;
      ttt_board_queryAndRedraw();
    }
  </script>
</body>

</html>