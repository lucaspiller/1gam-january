# [Zepto.js](http://zeptojs.com/) is used for DOM manipulation.
$ = Zepto

# Create a new instance of the game and run it, using 
$ ->
  initGame()

# Setup a new game
initGame = ->
  # Remove old board (if any)
  $('#sausis .board').remove()

  # Create the new game board
  board = $('<div/>')
  board.addClass 'board'
  $('#sausis').append board

  alive = true

  # Create the columns
  INITIAL_COLUMNS = 5
  columns = INITIAL_COLUMNS

  for columnIndex in [0..INITIAL_COLUMNS - 1]
    column = $('<div />')
    column.addClass 'column'
    column.data 'x', columnIndex
    board.append column

  # create the rows
  INITIAL_ROWS = 5
  MAX_ROWS = 8
  rows = 0
  COLOURS = ['red', 'blue', 'green']

  addRow = ->
    # Create a rows of balls
    rowIndex = rows++

    # Game over :(
    if rowIndex == MAX_ROWS
      alive = false
      return

    # Add a new ball to each column
    for columnIndex in [0..columns]
      column = $(".column[data-x='#{columnIndex}']")
      colour = COLOURS[Math.floor Math.random() * COLOURS.length]
      ball = $('<div />')
      ball.addClass 'ball'
      ball.addClass colour
      ball.data 'x', columnIndex
      ball.data 'y', rowIndex
      column.prepend ball

  # generate initial rows
  for rowIndex in [0..INITIAL_ROWS - 1]
    addRow()

  # create new rows periodically
  NEW_ROW_INTERVAL = 2500
  addRowOrRestartGame = ->
    if alive
      addRow()
      setTimeout addRowOrRestartGame, NEW_ROW_INTERVAL
    else
      initGame()
  setTimeout addRowOrRestartGame, NEW_ROW_INTERVAL

  # generate character
  INITIAL_CHARACTER_COLUMN = 2
  characterColumn = null

  moveCharacterToColumn = (columnIndex) ->
    unless columnIndex == characterColumn
      characterColumn = columnIndex
      $(".character").remove()
      character = $('<div/>')
      character.addClass 'character'
      column = $(".column[data-x='#{characterColumn}']")
      column.append character
  moveCharacterToColumn INITIAL_CHARACTER_COLUMN

  window.onkeyup = (e) ->
    if alive
      e = e.keyCode
      switch e
        when 37 # left
          if characterColumn > 0
            moveCharacterToColumn characterColumn - 1
        when 39 # right
          if characterColumn < INITIAL_COLUMNS - 1
            moveCharacterToColumn characterColumn + 1
