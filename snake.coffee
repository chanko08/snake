
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
    HEIGHT: 400
    FPS:    60


    context:{}

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
    growth: 0
    cell_bitmap:undefined

#snakes length = 5 + 2 * eaten
food =
    cell:[]
    cell_bitmap:undefined

snake_head = () ->
    #snake.cells[snake.cells.length - 1]
    snake.cells[0]

#reset the snake's location and direction
create_snake = () ->
    if Window.COLS > 5
        snake.cells = ([i,0] for i in [5..0])
    else
        snake.cells = []


    snake.direction = Direction.RIGHT
    snake.last_move = +new Date()
    snake.reset = false
    snake.eaten = 0
    snake.growth = 0

move_snake = (time_delta, now) ->
    if snake.reset
        game_reset()
        return

    if (now - snake.last_move) < snake.move_interval
        return

    #front = snake.cells[snake.cells.length - 1]
    front = snake_head()

    if snake.direction == Direction.RIGHT
        front = [front[0] + 1, front[1]]
    else if snake.direction == Direction.LEFT
        front = [front[0] - 1, front[1]]
    else if snake.direction == Direction.UP
        front = [front[0], front[1] - 1]
    else if snake.direction == Direction.DOWN
        front = [front[0], front[1] + 1]
    
    if not snake.growth 
        snake.cells.pop()
    else
        snake.growth = snake.growth - 1
        console.log("increasing length to ", snake.cells.length + snake.growth, "currently at", snake.cells.length)
    snake.cells.unshift(front)
    snake.last_move = now

    if front[0] >= Window.COLS or front[0] < 0 or front[1] >= Window.ROWS or front[1] < 0
        snake.reset = true

    snake.reset = snake.reset or snake_hits_self()

game_reset = () ->
    create_snake()
    create_food()
    create_score()

snake_hits_self = () ->
    front = snake_head()
    collide_count = 0
    for c in snake.cells
        if front[0] == c[0] and front[1] == c[1]
            collide_count = collide_count + 1
            if 1 < collide_count then return true
    return false

eat_food = () ->
    front = snake_head() 

    if front[0] == food.cell[0] and front[1] == food.cell[1]
        snake.eaten = snake.eaten + 1
        snake.growth = snake.eaten
        #snake.cells.push(front) for i in [0..snake.eaten]
        create_food()
        update_score()

update_score = () ->
    create_score()

create_score = () ->
    score = "Score: " + snake.eaten.toString()
    x$('#snake_score').html(score)



#sets the food's location
create_food = () ->
    food.cell = [
        Math.floor(Math.random() * Window.COLS),
        Math.floor(Math.random() * Window.ROWS)
    ]
    if food.cell in snake.cells
        create_food()

draw_cell =  (cell, context) ->
    context.fillStyle = Color.WHITE
    context.strokeStyle = Color.BLUE
    context.fillRect(
        cell[0] * Cell.WIDTH
        cell[1] * Cell.HEIGHT
        Cell.WIDTH,
        Cell.HEIGHT
    )
    context.strokeRect(
        cell[0] * Cell.WIDTH
        cell[1] * Cell.HEIGHT
        Cell.WIDTH,
        Cell.HEIGHT
    )

clear_context = () ->
    Window.context.fillStyle = Color.WHITE
    Window.context.strokeStyle = Color.BLACK

    #background for the snake window
    Window.context.fillRect(0,0,Window.WIDTH,Window.HEIGHT)
    Window.context.strokeRect(0,0,Window.WIDTH,Window.HEIGHT)

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
    clear_context()
    #draw_cell(c, Window.context) for c in snake.cells
    Window.context.drawImage(snake.cell_bitmap, c[0] * Cell.WIDTH, c[1] * Cell.HEIGHT) for c in snake.cells
    c = food.cell
    Window.context.drawImage(food.cell_bitmap, c[0] * Cell.WIDTH, c[1] * Cell.HEIGHT)
    #draw_cell(food.cell, Window.context)

#returns an object containing necessary snake functionality
#also ties event listeners to the canvas, and adds a interval
#function for drawing
initialize = (div_selector) ->

    #initialize the div to be a certain size, and make it contain a canvas element
    div = x$(div_selector)
    div.css({border:'2px solid black', width:Window.WIDTH.toString() + "px"})

    canvas_stuff = "<canvas id='snake_canvas' tabindex='1'></canvas><div id='snake_score'></div>"
    div.html(canvas_stuff)

    canvas = x$("#snake_canvas").attr('width', Window.WIDTH).attr('height', Window.HEIGHT)
    x$(document).on('keydown', keyboard_callback)

    #tie the context to the game
    context = canvas.first().getContext("2d")
    canvas.first().focus()
    Window.context = context


    create_snake()
    snake.cell_bitmap = document.createElement('canvas')
    snake.cell_bitmap.width = Cell.WIDTH
    snake.cell_bitmap.height = Cell.HEIGHT
    c = snake.cell_bitmap.getContext('2d')
    draw_cell([0,0], c)

    


    create_food()
    food.cell_bitmap = document.createElement('canvas')
    food.cell_bitmap.width = Cell.WIDTH
    food.cell_bitmap.height = Cell.HEIGHT
    c = food.cell_bitmap.getContext('2d')
    draw_cell([0,0], c)
    create_score()

    console.log(food.cell_bitmap)

    window.animLoop(run)



x$.ready(() ->initialize ("#snake"))

