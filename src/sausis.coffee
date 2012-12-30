# [Zepto.js](http://zeptojs.com/) is used for DOM manipulation.
$ = Zepto

# Create a new instance of the game and run it
$ ->
  game = new Game {
    renderComponent: new DomRenderComponent $('#sausis')
    inputComponent: new KeyboardInputComponent
  }
  game.start()

window.requestAnimationFrame = (() ->
  return window.requestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.msRequestAnimationFrame ||
    window.oRequestAnimationFrame ||
    (f) ->
      window.setTimeout(f,1e3/60)
)()

class NullInputComponent
  start: -> true
  update: -> true
  moveLeft: -> false
  moveRight: -> false
  pullBall: -> false
  pushBall: -> false

class KeyboardInputComponent extends NullInputComponent
  start: ->
    @keys = []
    window.onkeydown = (e) =>
      @keys[e.keyCode] = true

      # prevent window scrolling from arrow keys
      if e.keyCode == 40 || e.keyCode == 38
        false

  update: ->
    @shouldMoveLeft = @keys[37] # left arrow
    @shouldMoveRight = @keys[39] # right arrow
    @shouldPullBall = @keys[40] # down arrow
    @shouldPushBall = @keys[38] # up arrow
    @keys = []

  moveLeft: ->
    @shouldMoveLeft

  moveRight: ->
    @shouldMoveRight

  pullBall: ->
    @shouldPullBall

  pushBall: ->
    @shouldPushBall

class NullRenderComponent
  start: -> true
  update: -> true
  buildGameBoard: -> true
  buildColumn: (columnIndex) -> true
  addNewBallToColumn: (ballObject, columnIndex) -> true
  popBallFromColumn: (ballObject, columnIndex) -> true
  pushBallToColumn: (ballObject, columnIndex) -> true
  destroyBallFromColumn: (ballObject, columnIndex) -> true
  buildCharacterOnColumn: (columnIndex) -> true

  startGameLoop: (callback) ->
    @gameLoopTimer = setInterval =>
      callback()
    , 1e3 / 10

  stopGameLoop: ->
    clearTimeout @gameLoopTimer

class DomRenderComponent extends NullRenderComponent
  running: false

  constructor: (@parent = $('body')) ->
    true

  start: ->
    @ballsToRemove = []

  update: ->
    timestamp = getTimestamp()
    while @ballsToRemove.length > 0 && timestamp > @ballsToRemove[0].timestamp
      ball = @ballsToRemove.shift()
      @removeBall ball.id

  buildGameBoard: ->
    # Remove old board (if any)
    @parent.find('.board').remove()

    # Create the new game board
    @board = $('<div/>')
    @board.addClass 'board'
    @parent.append @board

  buildColumn: (columnIndex) ->
    column = $('<div />')
    column.addClass 'column'
    column.data 'x', columnIndex
    @board.append column

  addNewBallToColumn: (ballObject, columnIndex) ->
    ball = createElementForBall ballObject
    ball.addClass 'new'

    column = @board.find(".column[data-x='#{columnIndex}']")
    column.prepend ball

  pushBallToColumn: (ballObject, columnIndex) ->
    ball = createElementForBall ballObject
    column = @board.find(".column[data-x='#{columnIndex}']")
    column.append ball

  popBallFromColumn: (ballObject, columnIndex) ->
    @removeBall ballObject.id

  destroyBallFromColumn: (ballObject, columnIndex) ->
    column = @board.find(".column[data-x='#{columnIndex}']")
    ball = column.find(".ball[data-id='#{ballObject.id}']")
    ball.addClass 'remove'
    @removeBallInMs ballObject.id, 300

  buildCharacterOnColumn: (columnIndex) ->
    @board.find(".character").remove()
    character = $('<div/>')
    character.addClass 'character'

    column = @board.find(".column[data-x='#{columnIndex}']")
    column.append character

  startGameLoop: (callback) ->
    @gameLoopCallback = callback
    @running = true
    @gameLoop()

  stopGameLoop: ->
    @running = false

  # private

  removeBall: (ballId) ->
    ball = @board.find(".ball[data-id='#{ballId}']")
    ball.remove()

  removeBallInMs: (ballId, ms) ->
    @ballsToRemove.push {
      id: ballId,
      timestamp: getTimestamp() + ms
    }

  gameLoop: =>
    if @running
      window.requestAnimationFrame @gameLoop
      @gameLoopCallback()

  createElementForBall = (ballObject) ->
    ball = $('<div />')
    ball.addClass 'ball'
    ball.data 'colour', ballObject.colour
    ball.data 'id', ballObject.id

  getTimestamp = ->
    new Date().getTime()

class Ball
  colours = ['red', 'blue', 'green']
  lastBallId = 0

  constructor: ->
    @id = lastBallId++
    @colour = pickColour()

  # private

  pickColour = ->
    _.first _.shuffle colours

class Character
  constructor: (@options) ->
    @column = Math.floor @options.columns / 2
    true

  start: ->
    @moveToColumn @column

  moveLeft: ->
    if @column > 1
      @moveToColumn @column - 1

  moveRight: ->
    if @column < @options.columns
      @moveToColumn @column + 1

  # private
  moveToColumn: (column) ->
    @column = column
    @options.renderComponent.buildCharacterOnColumn @column

class Game
  running: false

  defaults:
    columns: 7
    initialRows: 4
    inputComponent: new NullInputComponent
    renderComponent: new NullRenderComponent
    newRowInterval: 5000
    maxRows: 12

  constructor: (@options = {}) ->
    _.defaults @options, @defaults

  start: ->
    @options.inputComponent.start()
    @options.renderComponent.start()
    @buildGameBoard()
    @options.renderComponent.startGameLoop(@gameLoop)
    @running = true

  gameLoop: =>
    @options.inputComponent.update()
    @handleInput()
    @handleTimers()
    @options.renderComponent.update()

  # private

  buildGameBoard: ->
    @options.renderComponent.buildGameBoard()

    # initialise 2D array of balls
    @balls = []

    # initialise array of balls held by character
    @characterBalls = []

    # build columns
    @buildColumn(x) for x in [1..@options.columns]

    # build initial rows
    @buildRow() for y in [1..@options.initialRows]

    @buildCharacter()

  buildColumn: (columnIndex) ->
    @options.renderComponent.buildColumn columnIndex

    # add the y dimension for this column
    @balls.push []

  buildRow: ->
    if @countRows() >= @options.maxRows
      return @triggerGameOver()

    for x in [1..@options.columns]
      # initialize ball
      ball = new Ball()

      # add to the beginning of our 2D array (so it appears at the top)
      @balls[x - 1].unshift ball

      # render
      @options.renderComponent.addNewBallToColumn ball, x

    @buildNextRowAt = getTimestamp() + @options.newRowInterval

  buildCharacter: ->
    @character = new Character {
      renderComponent: @options.renderComponent,
      columns: @options.columns
    }
    @character.start()

  handleInput: ->
    # character movement
    if @options.inputComponent.moveLeft()
      @character.moveLeft()
    else if @options.inputComponent.moveRight()
      @character.moveRight()

    # ball movement
    if @options.inputComponent.pullBall()
      @pullBall @character.column
    else if @options.inputComponent.pushBall()
      @pushBall @character.column

  pullBall: (x) ->
    columnBalls = @balls[x - 1]

    # get the last ball
    ball = columnBalls[columnBalls.length - 1]

    if ball
      # check it's colour matches that of the last pushed ball
      lastPulledBall = @characterBalls[0]

      if !lastPulledBall || lastPulledBall.colour == ball.colour
        # if so remove it
        ball = columnBalls.pop()
        @options.renderComponent.popBallFromColumn ball, x

        # add to balls stored by character
        @characterBalls.push ball

  pushBall: (x) ->
    columnBalls = @balls[x - 1]

    while @characterBalls.length > 0
      # get the last ball
      ball = @characterBalls.pop()

      # add it to the start of the column
      columnBalls.push ball

      # render
      @options.renderComponent.pushBallToColumn ball, x

    @findAndDestroyBalls x

  findAndDestroyBalls: (x) ->
    pushedColumnIndex = x - 1
    columnBalls = @balls[pushedColumnIndex]

    if columnBalls.length < 3
      return

    # get the colour of the last pushed ball
    pushedColour = columnBalls[columnBalls.length - 1].colour

    # go up the column until we find a non matching ball (we skip
    # the first ball as that as what we are comparing against)
    for rowIndex in [columnBalls.length - 2..0]
      if columnBalls[rowIndex].colour != pushedColour
        break

    # if the non matching has an index of 3 or more, we can remove balls
    if (columnBalls.length - 1) - rowIndex >= 3
      # simple pop them off, and add the remove class
      # which trigger the remove animation
      deleteToIndex = rowIndex + 1

      # do a queue-based flood fill to find balls to remove
      searched = []
      toSearch = []
      toDelete = []
      for rowIndex in [columnBalls.length - 1..deleteToIndex]
        toSearch.push [pushedColumnIndex, rowIndex]

      # TODO see if underscore has something we can use,
      # or if there is a nicer way to do this
      tupleExists = (tuple, array) ->
        [x, y] = tuple
        for [ax, ay], i in array
          if ax == x && ay == y
            return true
        false

      while toSearch.length > 0
        [x, y] = toSearch.shift()
        if tupleExists [x, y], searched
          continue
        searched.push [x, y]

        if !@balls[x] || !@balls[x][y]
          continue

        if @balls[x][y].colour != pushedColour
          continue

        toDelete.push [x, y]
        toSearch.push [x + 1, y]
        toSearch.push [x - 1, y]
        toSearch.push [x, y + 1]
        toSearch.push [x, y - 1]

      # remove the balls we found
      for [x, y] in toDelete
        ball = @balls[x][y]
        @balls[x].splice y, 1
        @options.renderComponent.destroyBallFromColumn ball, x + 1

  handleTimers: ->
    timestamp = getTimestamp()

    # periodically create a new row
    if timestamp > @buildNextRowAt
      @buildRow()

  countRows: ->
    rows = 0
    for columnBalls in @balls
      if columnBalls.length > rows
        rows = columnBalls.length
    rows

  triggerGameOver: ->
    @running = false
    @options.renderComponent.stopGameLoop()
    # TODO autorestart

  getTimestamp = ->
    new Date().getTime()
