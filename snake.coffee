
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

#BEGIN GAME CODE###############################################################

#Direction enumeration for possible directions, as well as some nice methods
#for use with directions
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
        else if dir == Direction.UP
            return Direction.DOWN
        else if dir == Direction.DOWN
            return Direction.UP

#Simple enumeration of colors that are used in the game
Color =
    WHITE:"#ffffff"
    BLACK:"#000000"
    GREEN:"#00ff00"
    BLUE :"#0000ff"
    GRAY:"#dddddd"

#The window object contains the necessary information regarding the main
#canvas size, the number of rows and cols of cells there are,
#as well as the canvas context so that things may be drawn to it.
#There is also a reference to the current state of the game that is used for
#update calls for the game
Window =
    COLS:   40
    ROWS:   40
    WIDTH:  400
    HEIGHT: 400
    FPS:    60


    div:{}
    context:{}

#The cell object contains information regarding a cells dimensions
Cell =
    WIDTH: Math.floor(Window.WIDTH / Window.COLS)
    HEIGHT: Math.floor(Window.HEIGHT / Window.ROWS)

GameScreen =
    snake:
        reset: false
        cells: []
        direction: Direction.RIGHT
        move_interval: 100
        last_move: 0
        eaten: 0
        growth: 0
        bitmap: undefined

        #returns the cell the snake's head is located
        #before this used to vary so this was a necessary abstraction
        head: -> this.cells[0]

    food :
        cell: []
        bitmap: undefined

    #--PUBLIC METHODS--#
    #loads necessary images for game screen, initializes/resets entities
    initialize: ->
        #init snake entity, include loading of its canvas
        this._init_snake()
        this.snake.bitmap = document.createElement('canvas')
        this.snake.bitmap.width = Cell.WIDTH
        this.snake.bitmap.height = Cell.HEIGHT
        c = this.snake.bitmap.getContext('2d')
        draw_cell([0,0], c)

        #init food entity, include loading of its canvas
        this._init_food()
        this.food.bitmap = document.createElement('canvas')
        this.food.bitmap.width = Cell.WIDTH
        this.food.bitmap.height = Cell.HEIGHT
        c = this.food.bitmap.getContext('2d')
        draw_cell([0,0], c)

        #create the div that holds the score for the game
        Window.div.html('bottom', "<div id='snake_score'></div>")
        this._update_score()

    #does an update and draw pass for the GameScreen
    run: (time_delta, now) ->
        this.update(time_delta, now)
        clear_context()
        this.draw()

    #draws the entities of the game screen
    draw: ->
        Window.context.drawImage(this.snake.bitmap, c[0] * Cell.WIDTH, c[1] * Cell.HEIGHT) for c in this.snake.cells
        c = this.food.cell
        Window.context.drawImage(this.food.bitmap, c[0] * Cell.WIDTH, c[1] * Cell.HEIGHT)

    #updates the entities of the game screen
    update: (time_delta, now) ->
        this._move_snake(time_delta, now)
        this._eat_food()

    #makes the snake react to certain keypresses to direct it.
    keyboard_callback: (event) ->
        s = this.snake
        if event.keyCode == 37 and Direction.opposite(s.direction) != Direction.LEFT
            s.direction = Direction.LEFT
        else if event.keyCode == 38 and Direction.opposite(s.direction) != Direction.UP
            s.direction = Direction.UP
        else if event.keyCode == 39 and Direction.opposite(s.direction) != Direction.RIGHT
            s.direction = Direction.RIGHT
        else if event.keyCode == 40 and Direction.opposite(s.direction) != Direction.DOWN
            s.direction = Direction.DOWN

    #---PRIVATE METHODS---#
    #initializes/resets the food entity
    _init_food: ->
        this.food.cell = [
            Math.floor(Math.random() * Window.COLS),
            Math.floor(Math.random() * Window.ROWS)
        ]
        if this.food.cell in this.snake.cells
            this._init_food()

    #initializes/resets the snake entity
    _init_snake: ->
        if Window.COLS > 5
            this.snake.cells = ([i,0] for i in [5..0])
        else
            this.snake.cells = []


        this.snake.direction = Direction.RIGHT
        this.snake.last_move = +new Date()
        this.snake.reset = false
        this.snake.eaten = 0
        this.snake.growth = 0

    #updates the score that is displayed.
    _update_score: ->
        score = "Score: " + this.snake.eaten.toString()
        x$('#snake_score').html(score)

    #updates movements of the snake
    _move_snake: (time_delta, now) ->
        if this.snake.reset
            this._reset_entities()
            return

        if (now - this.snake.last_move) < this.snake.move_interval
            return

        #front = snake.cells[snake.cells.length - 1]
        front = this.snake.head()

        if this.snake.direction == Direction.RIGHT
            front = [front[0] + 1, front[1]]
        else if this.snake.direction == Direction.LEFT
            front = [front[0] - 1, front[1]]
        else if this.snake.direction == Direction.UP
            front = [front[0], front[1] - 1]
        else if this.snake.direction == Direction.DOWN
            front = [front[0], front[1] + 1]

        if not this.snake.growth
            this.snake.cells.pop()
        else
            this.snake.growth = this.snake.growth - 1

        this.snake.cells.unshift(front)
        this.snake.last_move = now

        if front[0] >= Window.COLS or front[0] < 0 or front[1] >= Window.ROWS or front[1] < 0
            this.snake.reset = true

        this.snake.reset = this.snake.reset or this._snake_hits_self()

    #a check method for the snake hitting its own body
    _snake_hits_self: ->
        front = this.snake.head()
        collide_count = 0
        for c in this.snake.cells
            if front[0] == c[0] and front[1] == c[1]
                collide_count = collide_count + 1
                if 1 < collide_count then return true
        return false

    #reset method for starting a game over
    _reset_entities: ->
        this._init_snake()
        this._init_food()
        this._update_score()

    #an update method for handling when a piece of food is eaten
    _eat_food: ->
        front = this.snake.head()
        if front[0] == this.food.cell[0] and front[1] == this.food.cell[1]
            this.snake.eaten = this.snake.eaten + 1
            this.snake.growth = this.snake.eaten
            this._init_food()
            this._update_score()

TitleScreen =
    title_bitmap: undefined
    play_button:
        pos:[]
        bitmap: undefined

    initialize: ->
        console.log('init')

        #the title bitmap
        this.title_bitmap = document.createElement('canvas')
        this.title_bitmap.width = Window.WIDTH
        this.title_bitmap.height = Window.HEIGHT / 4
        c = this.title_bitmap.getContext('2d')
        c.textAlign = "center"
        c.font = (Window.HEIGHT / 4).toString() + "px Sans-Serif"
        c.fillStyle = "blue"
        c.fillText("Snake", Window.WIDTH / 2,  Window.HEIGHT / 4)

        #play button bitmap
        bitmap = document.createElement('canvas')
        bitmap.width = Window.WIDTH / 3
        bitmap.height = Window.HEIGHT / 8
        c = bitmap.getContext('2d')
        c.textAlign = 'center'
        c.font = (Window.HEIGHT / 8).toString() + "pt Sans-Serif"
        c.fillText("Play", Window.WIDTH / 6, Window.HEIGHT / 8)
        this.play_button.bitmap = bitmap
        this.play_button.pos = [Window.WIDTH / 3, 2 * Window.HEIGHT / 4]

        




    run: (time_delta, now) ->
        this.update(time_delta, now)
        this.draw()

    update: (time_delta, now) -> return null
    draw: ->
        clear_context()
        Window.context.drawImage(this.title_bitmap, 0, 0)
        c = this.play_button.pos
        Window.context.drawImage(this.play_button.bitmap, c[0], c[1] )

    keyboard_callback: (event) -> null

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
    if Window.screen.keyboard_callback?
        Window.screen.keyboard_callback(event)

run = (time_delta, now) ->
    Window.screen.run(time_delta, now)


#returns an object containing necessary snake functionality
#also ties event listeners to the canvas, and adds a interval
#function for drawing
initialize = (div_selector) ->
    #initialize the div to be a certain size, and make it contain a canvas element
    div = x$(div_selector)
    div.css({border:'2px solid black', width:Window.WIDTH.toString() + "px"})

    canvas_stuff = "<canvas id='snake_canvas' tabindex='1'></canvas>"
    div.html(canvas_stuff)

    canvas = x$("#snake_canvas").attr('width', Window.WIDTH).attr('height', Window.HEIGHT)
    x$(document).on('keydown', keyboard_callback)

    #tie the context to the game
    context = canvas.first().getContext("2d")
    canvas.first().focus()
    Window.context = context
    Window.div = div

    TitleScreen.initialize()
    GameScreen.initialize()
    #Window.screen = GameScreen
    Window.screen = TitleScreen
    window.animLoop(run)


x$.ready(() -> initialize("#snake"))

