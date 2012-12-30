# [Zepto.js](http://zeptojs.com/) is used for DOM manipulation.
$ = Zepto

# Create a new instance of the game and run it
$ ->
  initGame()

window.requestAnimationFrame = (() ->
  return window.requestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.msRequestAnimationFrame ||
    window.oRequestAnimationFrame ||
    (f) ->
      window.setTimeout(f,1e3/60)
)()

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

  # create new rows periodically
  # (timer is handled in game loop)
  NEW_ROW_INTERVAL = 5000
  nextRowAt = 0

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

    nextRowAt = new Date().getTime() + NEW_ROW_INTERVAL

  # generate initial rows
  for rowIndex in [0..INITIAL_ROWS - 1]
    addRow()

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

      searched = []
      toSearch = []
      toDelete = []
      for rowIndex in [columnBalls.length - 1..deleteToIndex]
        toSearch.push [pushedColumnIndex, rowIndex]

      while toSearch.length > 0
        [x, y] = toSearch.shift()
        if tupleExists [x, y], searched
          continue
        searched.push [x, y]

        if !balls[x] || !balls[x][y]
          continue

        if balls[x][y].data('colour') != pushedColour
          continue

        toDelete.push [x, y]
        toSearch.push [x + 1, y]
        toSearch.push [x - 1, y]
        toSearch.push [x, y + 1]
        toSearch.push [x, y - 1]

      for [x, y] in toDelete
        balls[x][y].addClass 'remove'
        balls[x].splice y, 1

      # then clean up afterwards
      setTimeout ->
        $('.ball.remove').remove()
      , 300

  tupleExists = (tuple, array) ->
    [x, y] = tuple
    for [ax, ay], i in array
      if ax == x && ay == y
        return true
    false

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
    if characterBalls.length > 0
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

  keys = []
  window.onkeydown = (e) ->
    keys.push e.keyCode

    # prevent window scrolling from arrow keys
    if e.keyCode == 40 || e.keyCode == 38
      false

  handleKeyboardInput = ->
    while keys.length > 0
      key = keys.shift()
      switch key
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

    keys = []

  handleTimers = ->
    now = new Date().getTime()
    if now > nextRowAt
      addRow()

  gameLoop = ->
    unless alive
      return initGame()

    requestAnimationFrame gameLoop
    handleKeyboardInput()
    handleTimers()

  requestAnimationFrame gameLoop
