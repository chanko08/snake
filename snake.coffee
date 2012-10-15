#TODO add keyboard controls
class @Main
    constructor: (window, width, height) ->
        game = new Game(window, width, height)
        setInterval game.runInterval, (1000.0 / game.fps)


class Game
    fps: 30

    #boilerplate for getting how much time has passed since runInterval was last called
    constructor: (@window, @width, @height) ->
        @time = new Date().getTime()

        @grid_dim =
            w: 40
            h: 40

        #compute how wide/high a cell should be if we want a 40*40 grid
        @cell_dim =
            w: @width  / @grid_dim.w
            h: @height / @grid_dim.h



        #once we have the height and width of a cell, we need to make sure there is no left over space
        #so reduce the window width and height to accomodate only the 40*40 grid
        @width  = @cell_dim.w * @grid_dim.w
        @height = @cell_dim.h * @grid_dim.h

        @food  = new Food(@cell_dim, @grid_dim)
        @snake = new Snake(@cell_dim, @grid_dim)


    runInterval: =>
        #console.log "dt is", @get_dt()
        @update(@get_dt())
        @draw()
        @update_dt()

    get_dt: ->
        new_time = new Date().getTime()
        new_time - @time

    update_dt: ->
        @time = new Date().getTime()

    draw: ->
        #clear screen and draw border
        @window.fillStyle = Color.WHITE
        @window.fillRect(0,0,@width,@height)

        @window.strokeStyle = Color.BLACK
        @window.strokeRect(0,0,@width,@height)

        draw_cells(@window, @food)
        draw_cells(@window, @snake)

    update: (dt) ->
        @snake.move()


class Food
    constructor: (@cell_dim, @grid_dim) ->
        @bgcolor = Color.GREEN
        @fgcolor = Color.BLACK

        @cells = null
        @reset()

    reset: ->
        cell =
            x:0
            y:0

        cell.x = Math.floor( Math.random() * @grid_dim.w)
        cell.y = Math.floor( Math.random() * @grid_dim.h)

        @cells = [cell]

class Snake
    constructor: (@cell_dim, @grid_dim) ->
        @bgcolor = Color.BLUE
        @fgcolor = Color.BLACK

        @cells = null
        @direction = null
        @reset()

    move: ->
        c =
            x:@cells[0].x
            y:@cells[0].y

        if @direction == Direction.UP
            c.y -= 1
        else if @direction == Direction.DOWN
            c.y += 1
        else if @direction == Direction.LEFT
            c.x -= 1
        else if @direction == Direction.RIGHT
            c.x += 1
        else
            console.log("Invalid direction was given!")

        #push new cell to front, pop cell from back
        @cells.unshift(c)
        @cells.pop()


        #check if we are over bounds somewhere
        hit_wall = false
        if @cells[0].x >= @grid_dim.w
            console.log("hit right wall")
            hit_wall = true
        else if @cells[0].x < 0
            console.log("hit left wall")
            hit_wall = true

        if @cells[0].y >= @grid_dim.h
            console.log("hit bottom wall")
            hit_wall = true
        else if @cells[0].y < 0
            console.log("hit top wall")
            hit_wall = true

        if hit_wall
            #game over, reset everything
            console.log("hit a wall")

    eat: (food)->
        ate_something = false

        head = @cells[0]
        for f in food.cells
            if f.x == head.x && f.y == head.y
                ate_something = true
                break

        #TODO add points
        if ate_something
            #increase game points, reset food
            food.reset()

    reset: ->
        @cells = ({x:i, y:0} for i in [5..0])
        @direction = Direction.RIGHT

draw_cells = (window, drawable) ->
    window.fillStyle   = drawable.bgcolor
    window.strokeStyle = drawable.fgcolor
    dim = drawable.cell_dim

    window.fillRect(   c.x * dim.w, c.y * dim.h, dim.w, dim.h) for c in drawable.cells
    window.strokeRect( c.x * dim.w, c.y * dim.w, dim.w, dim.h) for c in drawable.cells


Color =
    WHITE:"#ffffff"
    BLACK:"#000000"
    GREEN:"#00ff00"
    BLUE :"#0000ff"

Direction =
    UP   :0
    DOWN :1
    LEFT :2
    RIGHT:3