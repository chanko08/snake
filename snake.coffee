
###
#Sets up the drawing callback to use the requestAnimationFrame if possible
#otherwise falls back on a setTimeout
###
raf = window.requestAnimationFrame     ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame    ||
    window.msRequestAnimationFrame

window.animLoop = (render, element) ->
    running = undefined
    last_frame = new Date
    window_loop = (now) ->
        #stop rendering if the render function returned false at some point
        if running == false
            return

        if raf
            raf(window_loop, element)
        else
            setTimeout(window_loop, 16)

        now = if now and now > 1e4 then now else +new Date
        deltaT = now - last_frame

        if deltaT < 160
            running = render(deltaT, now)
        last_frame = now
    window_loop()


Direction =
    RIGHT :0
    LEFT  :1
    UP    :2
    DOWN  :3

    opposite : (dir) ->
        if dir == Direction.RIGHT
            return Direction.LEFT
        else if dir == Direction.LEFT
            return Direction.RIGHT
        else if dir == Direction.TOP
            return Direction.DOWN
        else if dir == Direction.DOWN
            return Direction.UP


Color =
    WHITE:"#ffffff"
    BLACK:"#000000"
    GREEN:"#00ff00"
    BLUE :"#0000ff"
    GRAY:"#dddddd"


Window =
    COLS:   40
    ROWS:   40
    WIDTH:  400
    HEIGHT: 500
    FPS:    60
    PLAY_WINDOW_RECT: [[0,100],[400,400]]
    SCORE_RECT: [[0,0],[400,100]]


    canvas:{}

Cell =
    WIDTH: Math.floor(Window.WIDTH / Window.COLS)
    HEIGHT: Math.floor(Window.HEIGHT / Window.ROWS)

snake =
    reset: false
    cells:[]
    direction:1
    previous_direction:undefined
    move_interval:100
    last_move:0
    eaten: 0

food =
    cell:[]

#reset the snake's location and direction
create_snake = () ->
    if Window.COLS > 5
        snake.cells = ([i,0] for i in [0..5])
    else
        snake.cells = []

    snake.direction = Direction.RIGHT
    snake.last_move = +new Date()
    snake.reset = false
    snake.eaten = 0

move_snake = (time_delta, now) ->
    if snake.reset
        create_snake()
        return

    if (now - snake.last_move) < snake.move_interval
        return

    front = snake.cells[snake.cells.length - 1]

    if snake.direction == Direction.RIGHT
        front = [front[0] + 1, front[1]]
    else if snake.direction == Direction.LEFT
        front = [front[0] - 1, front[1]]
    else if snake.direction == Direction.UP
        front = [front[0], front[1] - 1]
    else if snake.direction == Direction.DOWN
        front = [front[0], front[1] + 1]

    snake.cells.shift()
    snake.cells.push(front)
    snake.last_move = now

    if front[0] >= Window.COLS or front[0] < 0 or front[1] >= Window.ROWS or front[1] < 0
        snake.reset = true

    snake.reset = snake.reset or snake_hits_self()


snake_hits_self = () ->
    front = snake.cells[snake.cells.length - 1]
    for c in snake.cells[0..(snake.cells.length - 2)]
        if front[0] == c[0] and front[1] == c[1]
            return true
    return false

eat_food = () ->
    front = snake.cells[snake.cells.length - 1]

    if front[0] == food.cell[0] and front[1] == food.cell[1]
        snake.cells.push(front)
        snake.eaten = snake.eaten + 1
        create_food()


#sets the food's location
create_food = () ->
    food.cell = [
        Math.floor(Math.random() * Window.COLS),
        Math.floor(Math.random() * Window.ROWS)
    ]
    if food.cell in snake.cells
        create_food()

draw_cell =  (cell, canvas) ->
    canvas.fillStyle = Color.WHITE
    canvas.strokeStyle = Color.BLUE
    canvas.fillRect(
        cell[0] * Cell.WIDTH  + Window.PLAY_WINDOW_RECT[0][0],
        cell[1] * Cell.HEIGHT + Window.PLAY_WINDOW_RECT[0][1],
        Cell.WIDTH,
        Cell.HEIGHT
    )
    canvas.strokeRect(
        cell[0] * Cell.WIDTH  + Window.PLAY_WINDOW_RECT[0][0],
        cell[1] * Cell.HEIGHT + Window.PLAY_WINDOW_RECT[0][1],
        Cell.WIDTH,
        Cell.HEIGHT
    )

clear_canvas = () ->
    Window.canvas.fillStyle = Color.WHITE
    Window.canvas.strokeStyle = Color.BLACK
    console.log(Window.PLAY_WINDOW_RECT)

    #background for the snake window
    Window.canvas.fillRect(
        Window.PLAY_WINDOW_RECT[0][0],
        Window.PLAY_WINDOW_RECT[0][1],
        Window.PLAY_WINDOW_RECT[1][0],
        Window.PLAY_WINDOW_RECT[1][1]
    )
    Window.canvas.strokeRect(
        Window.PLAY_WINDOW_RECT[0][0],
        Window.PLAY_WINDOW_RECT[0][1],
        Window.PLAY_WINDOW_RECT[1][0],
        Window.PLAY_WINDOW_RECT[1][1]
    )

    Window.canvas.fillStyle = Color.GRAY
    #background for the score board
    Window.canvas.fillRect(
        Window.SCORE_RECT[0][0],
        Window.SCORE_RECT[0][1],
        Window.SCORE_RECT[1][0],
        Window.SCORE_RECT[1][1]
    )

    Window.canvas.strokeRect(
        Window.SCORE_RECT[0][0],
        Window.SCORE_RECT[0][1],
        Window.SCORE_RECT[1][0],
        Window.SCORE_RECT[1][1]
    )

keyboard_callback = (event) ->
    event.preventDefault()
    if event.keyCode == 37 and Direction.opposite(snake.direction) != Direction.LEFT
        snake.direction = Direction.LEFT
    else if event.keyCode == 38 and Direction.opposite(snake.direction) != Direction.UP
        snake.direction = Direction.UP
    else if event.keyCode == 39 and Direction.opposite(snake.direction) != Direction.RIGHT
        snake.direction = Direction.RIGHT
    else if event.keyCode == 40 and Direction.opposite(snake.direction) != Direction.DOWN
        snake.direction = Direction.DOWN

run = (time_delta, now) ->
    move_snake(time_delta, now)
    eat_food()
    clear_canvas()
    draw_cell(c, Window.canvas) for c in snake.cells
    draw_cell(food.cell, Window.canvas)

#returns an object containing necessary snake functionality
#also ties event listeners to the canvas, and adds a interval
#function for drawing
initialize = (canvas_id) ->
    canvas = document.getElementById(canvas_id)
    canvas.width = Window.WIDTH
    canvas.height = Window.HEIGHT
    canvas.addEventListener('keydown', keyboard_callback)
    context = canvas.getContext("2d")
    Window.canvas = context


    create_snake()
    create_food()

    window.animLoop(run)



window.onload = () ->
    initialize("snake")

