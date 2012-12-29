# [Zepto.js](http://zeptojs.com/) is used for DOM manipulation.
$ = Zepto

# Create a new instance of the game and run it, using 
$ ->
  # Get the game board
  board = $('#sausis .board')

  # Create the columns
  COLUMNS = 5
  ROWS = 5
  COLOURS = ['red', 'blue', 'green']

  for columnIndex in [0..COLUMNS - 1]
    column = $('<div />')
    column.addClass 'column'
    column.data 'x', columnIndex

    # Create the rows of balls
    for rowIndex in [0..ROWS - 1]
      colour = COLOURS[Math.floor Math.random() * COLOURS.length]
      ball = $('<div />')
      ball.addClass 'ball'
      ball.addClass colour
      ball.data 'x', columnIndex
      ball.data 'y', rowIndex
      column.append ball

    board.append column
