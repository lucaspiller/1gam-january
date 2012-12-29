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
  INITIAL_COLUMNS = 7
  columns = INITIAL_COLUMNS
  balls = []

  for columnIndex in [0..INITIAL_COLUMNS - 1]
    column = $('<div />')
    column.addClass 'column'
    column.data 'x', columnIndex
    board.append column
    balls.push []

  # create the rows
  INITIAL_ROWS = 4
  MAX_ROWS = 12
  rows = 0
  COLOURS = ['red', 'blue', 'green']

  countRows = ->
    maxBalls = 0
    for column in balls
      if column.length > maxBalls
        maxBalls = column.length
    maxBalls

  addRow = ->
    # Create a rows of balls
    rowIndex = rows++

    # Game over :(
    if countRows() >= MAX_ROWS
      alive = false
      return

    # Add a new ball to each column
    for columnIndex in [0..columns - 1]
      column = $(".column[data-x='#{columnIndex}']")
      colour = COLOURS[Math.floor Math.random() * COLOURS.length]
      ball = $('<div />')
      ball.addClass 'ball'
      ball.data 'colour', colour
      ball.addClass 'new'
      ball.data 'x', columnIndex
      ball.data 'y', rowIndex

      balls[columnIndex].unshift ball
      column.prepend ball

  # generate initial rows
  for rowIndex in [0..INITIAL_ROWS - 1]
    addRow()

  # create new rows periodically
  NEW_ROW_INTERVAL = 5000
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

  findAndDestroyBalls = (pushedColumnIndex) ->
    columnBalls = balls[pushedColumnIndex]
    if columnBalls.length < 3
      return

    # get the colour of the last pushed ball
    pushedColour = columnBalls[columnBalls.length - 1].data 'colour'

    # go up the column until we find a non matching ball
    for rowIndex in [columnBalls.length - 2..0]
      if columnBalls[rowIndex].data('colour') != pushedColour
        break

    # if the non matching has an index of 3 or more, we can remove balls
    if (columnBalls.length - 1) - rowIndex >= 3
      # simple pop them off, and add the remove class
      # which trigger the remove animation
      deleteToIndex = rowIndex + 1
      for rowIndex in [columnBalls.length - 1..deleteToIndex]
        ball = columnBalls.pop()
        ball.addClass 'remove'

      # then clean up afterwards
      setTimeout ->
        $('.ball.remove').remove()
        ball.remove()
      , 300

  characterBalls = []
  pullBall = (columnIndex) ->
    # get the first (bottom) ball from the column
    columnBalls = balls[columnIndex]
    ball = columnBalls[columnBalls.length - 1]
    if ball
      # check it's colour matches that of the last pushed ball
      lastPulledBall = characterBalls[0]
      if !lastPulledBall || lastPulledBall.data('colour') == ball.data('colour')
        # if so remove it
        ball = columnBalls.pop()
        ball.removeClass 'new'
        ball.remove()

        # add to balls stored by character
        characterBalls.push ball

  pushBall = (columnIndex) ->
    # don't push if we have exceeded the limit
    if countRows() >= MAX_ROWS
      return false

    while characterBalls.length > 0
      # unlike the columns this is LIFO
      ball = characterBalls.pop()

      # add the ball to the start of the column
      balls[columnIndex].push ball
      $(".column[data-x='#{columnIndex}']").append(ball)

    findAndDestroyBalls(columnIndex)

  # prevent window scrolling from arrow keys
  window.onkeydown = (e) ->
    if e.keyCode == 40 || e.keyCode == 38
      false

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
        when 40 # down, pull
          pullBall characterColumn
        when 38 # up, push
          pushBall characterColumn
          false
