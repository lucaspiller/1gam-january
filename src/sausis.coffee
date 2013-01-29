# [Zepto.js](http://zeptojs.com/) is used for DOM manipulation.
$ = Zepto

# Create a new instance of the game and run it
$ ->
  levelSelect = new LevelSelect $('#sausis .level-select')
  levelSelect.start()

# Helper for raf so we can avoid all the browser
# inconsistencies later on
window.requestAnimationFrame = (() ->
  return window.requestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.msRequestAnimationFrame ||
    window.oRequestAnimationFrame ||
    (f) ->
      window.setTimeout(f,1e3/60)
)()

#
# Level Select / Menus / etc
#

class LevelSelect
  constructor: (@domElement) ->
    @highscores = new HighScores
    true

  start: ->
    $(@domElement).on 'click', '[data-level]', (e) =>
      level = $(e.currentTarget).data 'level'
      if @levelUnlocked level
        @playLevel level
      else
        # TODO show a nicer message
        alert 'Locked!'
    @highscores.loadScores()
    @show()

  hide: ->
    @domElement.hide()

  show: ->
    @updateScores()
    @domElement.show()

  updateScores: ->
    @domElement.find('[data-level]').each (_, e) =>
      level = $(e).data 'level'
      highscore = @highscores.get level
      $(e).find('.score').text highscore.score
      $(e).find('.distance').text highscore.distance

  levelUnlocked: (level) ->
    # TODO
    true

  playLevel: (level) ->
    # TODO inject dependencies of game to level select
    @game = new Game {
      renderComponent: new DomRenderComponent $('#sausis .game')
      inputComponent: new KeyboardInputComponent
      endGameCallback: @gameEnded
      level: level
    }
    @hide()
    @game.start()

  gameEnded: (level, score, distance) =>
    distance *= 10
    @highscores.set level, score, distance
    @game.destroy()
    @game = undefined
    @show()

class HighScores
  constructor: ->
    @scores = {}

  # gets the high score for a level (if any)
  get: (level) =>
    @scores[level] || { score: 0, distance: 0 }

  # updates the high score, if this score
  # is greater than the current score
  set: (level, score, distance) =>
    @scores[level] ||= { score: 0, distance: 0 }

    if score > @scores[level].score
      @scores[level].score = score

    if distance > @scores[level].distance
      @scores[level].distance = distance

    # save scores asynchronously
    setTimeout(@saveScores, 0)

  saveScores: =>
    json = JSON.stringify @scores
    localStorage.setItem 'scores', json

  loadScores: =>
    json = localStorage.getItem 'scores'
    if json
      @scores = JSON.parse json

#
# Game Engine
#

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

  destroy: ->
    window.onkeydown = undefined

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
  updateScore: (score) -> true
  updateTimer: (time, totalTime) -> true
  buildGameBoard: -> true
  buildColumn: (columnIndex) -> true
  addRow: -> true
  addNewBallToColumn: (ballObject, columnIndex) -> true
  popBallFromColumn: (ballObject, columnIndex) -> true
  pushBallToColumn: (ballObject, columnIndex) -> true
  destroyBallFromColumn: (ballObject, columnIndex) -> true
  buildCharacterOnColumn: (columnIndex, oldColumnIndex) -> true
  showGameOverScreen: (finalScore, finalDistance) -> true

  startGameLoop: (callback) ->
    @gameLoopTimer = setInterval =>
      callback()
    , 1e3 / 10

  stopGameLoop: ->
    clearTimeout @gameLoopTimer

class DomRenderComponent extends NullRenderComponent
  running: false
  progressWidth: 328

  constructor: (@parent) ->
    true

  start: ->
    @parent.show()
    @ballsToRemove = []

  destroy: ->
    @parent.hide()

  update: (deltaLength) ->
    timestamp = getTimestamp()
    while @ballsToRemove.length > 0 && timestamp > @ballsToRemove[0].timestamp
      ball = @ballsToRemove.shift()
      @removeBall ball.id

    if -@expectedOffset > @offset
      @offset += lengthToPx deltaLength * 4
    else
      @offset += lengthToPx deltaLength
    @board.css 'top', @offset
    @columns.css 'top', @columnsOffset

  updateScore: (score) ->
    @parent.find('.game-score').text formatScore score

  updateTimer: (time, totalTime) ->
    remainingTime = totalTime - time
    @parent.find('.timer .text').text formatTime Math.floor(remainingTime)

    if time == totalTime
      @parent.find('.timer .progress').remove()
    else
      @parent.find('.timer .progress').css 'width', (remainingTime / totalTime) * @progressWidth

  buildGameBoard: (@length) ->
    # Hide gameover screen (if any)
    @parent.find('.game-over').hide()

    # Remove old board (if any)
    @parent.find('.board').remove()

    # Create the new game board
    @board = $('<div/>')
    @board.addClass 'board'

    @height = lengthToPx(@length) + window.innerHeight
    @expectedOffset = lengthToPx(@length) + 200
    @board.css 'height', @height

    @offset = -lengthToPx @length
    @board.css 'top', @offset

    @columns = $('<div/>')
    @columns.addClass 'columns'
    @columnsOffset = lengthToPx(@length) + 270
    @columns.css 'top', @columnsOffset
    @board.append @columns

    @parent.append @board

    # Score indicator
    score = $('<div/>')
    score.addClass 'game-score'
    @parent.append score

    # Timer
    timer = $('<div/>')
    timer.addClass 'timer'

    progress = $('<div/>')
    progress.addClass 'progress'
    timer.append progress

    frame = $('<div/>')
    frame.addClass 'frame'
    timer.append frame

    time = $('<div/>')
    time.addClass 'text'
    time.text '0:00'
    timer.append time

    @parent.append timer

  buildColumn: (columnIndex) ->
    column = $('<div />')
    column.addClass 'column'
    column.data 'x', columnIndex
    @columns.append column

  addNewBallToColumn: (ballObject, columnIndex) ->
    ball = createElementForBall ballObject
    ball.addClass 'new'

    column = @board.find(".column[data-x='#{columnIndex}']")
    column.prepend ball

  addRow: ->
    @columnsOffset -= 50
    @expectedOffset -= 50

  pushBallToColumn: (ballObject, columnIndex) ->
    ball = createElementForBall ballObject
    ball.addClass 'push'
    column = @board.find(".column[data-x='#{columnIndex}']")
    column.append ball

  popBallFromColumn: (ballObject, columnIndex) ->
    column = @board.find(".column[data-x='#{columnIndex}']")
    ball = column.find(".ball[data-id='#{ballObject.id}']")
    ball.addClass 'pop'
    @removeBallInMs ballObject.id, 150

  destroyBallFromColumn: (ballObject, columnIndex) ->
    column = @board.find(".column[data-x='#{columnIndex}']")
    ball = column.find(".ball[data-id='#{ballObject.id}']")
    if ball.hasClass 'push'
      ball.removeClass 'push'
      ball.addClass 'push-remove'
    else
      ball.addClass 'remove'
    @removeBallInMs ballObject.id, 450

  buildCharacterOnColumn: (columnIndex, oldColumnIndex) ->
    @parent.find(".character").remove()
    character = $('<div/>')
    character.addClass 'character'
    character.css 'left', (columnIndex * 50) - 18
    if columnIndex < oldColumnIndex
      character.addClass 'reverse'
    @parent.append character

  startGameLoop: (callback) ->
    @gameLoopCallback = callback
    @running = true
    @gameLoop()

  stopGameLoop: ->
    @running = false

  showGameOverScreen: (finalScore, finalDistance, returnToLevelSelectCallback) ->
    gameover = @parent.find('.game-over')
    gameover.find('.score').text formatScore finalScore
    gameover.find('.distance').text formatDistance finalDistance
    @parent.find('.game-over').show()
    @parent.on 'click', '.game-over button.play-again', =>
      @parent.find('.game-over').hide()
      @parent.off 'click'
      returnToLevelSelectCallback()

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

  formatScore = (score) ->
    "#{score}".replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")

  formatDistance = (distance) ->
    "#{distance * 10}m"

  formatTime = (time) ->
    minutes = Math.floor time / 60
    seconds = time % 60
    seconds = "0#{seconds}" if seconds < 10
    "#{minutes}:#{seconds}"

  lengthToPx = (length) ->
    length * 50

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
    @column = Math.ceil @options.columns / 2
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
    @options.renderComponent.buildCharacterOnColumn column, @column
    @column = column

class Game
  running: false

  defaults:
    columns: 7
    initialRows: 6
    length: 200
    inputComponent: new NullInputComponent
    renderComponent: new NullRenderComponent
    endGameCallback: null
    level: null
    newRowInterval: 5000
    maxRows: 9
    totalTime: 120 # two minutes

  constructor: (@options = {}) ->
    _.defaults @options, @defaults

  start: ->
    @options.inputComponent.start()
    @options.renderComponent.start()
    @buildGameBoard()
    @lastRenderMs = getTimestamp()
    @startTime = getTimestamp()
    @options.renderComponent.startGameLoop(@gameLoop)
    @running = true
    @distance = 0
    @score = 0
    @rowsGenerated = 0

  gameLoop: =>
    @distance = @rowsGenerated - @countRows()
    @distance = 0 if @distance < 0
    timeElapsed = (getTimestamp() - @startTime) / 1000
    if timeElapsed > @options.totalTime
      timeElapsed = @options.totalTime
      @triggerGameOver()
    @options.renderComponent.updateTimer timeElapsed, @options.totalTime

    @options.inputComponent.update()
    @handleInput()
    @handleTimers()
    @options.renderComponent.updateScore @score

    # build a new row if there aren't enough
    if @countRows() < @options.initialRows
      @buildRow()

    # pass the elapsed time to the renderer to tell it how far to scroll
    deltaMs = getTimestamp() - @lastRenderMs
    deltaLength = deltaMs * (1 / @options.newRowInterval)
    @options.renderComponent.update deltaLength

    @lastRenderMs = getTimestamp()

  # private

  buildGameBoard: ->
    @options.renderComponent.buildGameBoard(@options.length)

    # initialise 2D array of balls
    @balls = []

    # initialise array of balls held by character
    @characterBalls = []

    # build columns
    @buildColumn(x) for x in [1..@options.columns]

    @buildCharacter()

  buildColumn: (columnIndex) ->
    @options.renderComponent.buildColumn columnIndex

    # add the y dimension for this column
    @balls.push []

  buildRow: ->
    if @countRows() >= @options.maxRows
      return @triggerGameOver()

    @options.renderComponent.addRow()

    for x in [1..@options.columns]
      # initialize ball
      ball = new Ball()

      # add to the beginning of our 2D array (so it appears at the top)
      @balls[x - 1].unshift ball

      # render
      @options.renderComponent.addNewBallToColumn ball, x

    @rowsGenerated++
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

    # get the colour of the last ball in the column
    pulledColour = columnBalls[columnBalls.length - 1].colour

    # go up the column until we find a non matching ball (we skip
    # the first ball as that as what we are comparing against)
    for rowIndex in [columnBalls.length - 1..0]
      # get the ball
      ball = columnBalls[rowIndex]

      # check it's colour matches that of the last bull in column
      unless ball.colour == pulledColour
        return

      # check it's colour matches that of the last pushed ball
      lastPulledBall = @characterBalls[0]
      unless !lastPulledBall || lastPulledBall.colour == ball.colour
        return

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
      scoreForMove = Math.floor(@rowsGenerated * (toDelete.length / 3)) * 10
      for [x, y] in toDelete
        ball = @balls[x][y]
        @balls[x].splice y, 1
        @options.renderComponent.destroyBallFromColumn ball, x + 1

      @score += scoreForMove

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
    @options.renderComponent.showGameOverScreen @score, @distance, @returnToLevelSelect

  returnToLevelSelect: =>
    if @options.endGameCallback
      @options.endGameCallback @options.level, @score, @distance

  destroy: =>
    @options.renderComponent.destroy()
    @options.inputComponent.destroy()

  getTimestamp = ->
    new Date().getTime()

  rowsForLength = (length) ->
    length
