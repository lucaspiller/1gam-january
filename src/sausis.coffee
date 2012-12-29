# [Zepto.js](http://zeptojs.com/) is used for DOM manipulation.
$ = Zepto

# Create a new instance of the game and run it, using 
$ ->
  # Get the game board
  board = $('#sausis .board')

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
  rows = 0
  COLOURS = ['red', 'blue', 'green']

  addRow = ->
    # Create a rows of balls
    rowIndex = rows++
    for columnIndex in [0..columns]
      column = $(".column[data-x='#{columnIndex}']")
      colour = COLOURS[Math.floor Math.random() * COLOURS.length]
      ball = $('<div />')
      ball.addClass 'ball'
      ball.addClass colour
      ball.data 'x', columnIndex
      ball.data 'y', rowIndex
      column.prepend ball

  for rowIndex in [0..INITIAL_ROWS - 1]
    addRow()

  # create new rows
  NEW_ROW_INTERVAL = 2500
  setInterval addRow, NEW_ROW_INTERVAL
