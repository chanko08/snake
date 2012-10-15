#event.coffee
#an event framework for more than just mouse and keyboard input

class @EventHandler
    ###
    # constructor
    # Takes in an element id to the element it should attach event handlers such as keyboard and mouse to.
    ###
    constructor: (canvas_id) ->
        @canvas = document.getElementById(canvas_id)

        @event_queue = []



        #attach the base event handlers to the canvas element
        #all the other events are interpretted through data gained by these events
        self = this
        @canvas.addEventListener("focus",       ((e) -> self._on_focus(e)),         false)
        @canvas.addEventListener("blur",        ((e) -> self._on_blur(e)),          false)
        @canvas.addEventListener("click",       ((e) -> self._on_click(e)) ,        false)
        @canvas.addEventListener("keypress",    ((e) -> self._on_key_press(e)),     false)
        @canvas.addEventListener("keyrelease",  ((e) -> self._on_key_release(e)),   false)
        @canvas.addEventListener("mousedown",   ((e) -> self._on_mouse_down(e)),    false)
        @canvas.addEventListener("mouseup",     ((e) -> self._on_mouse_up(e)),      false)
        @canvas.addEventListener("contextmenu", ((e) -> self._on_context_menu(e)),  false)

    _on_blur: (e) ->
        e.preventDefault()

    _on_focus: (e) ->
        e.preventDefault()

    _on_key_press: (e) ->
        e.preventDefault()

    _on_key_release: (e) ->
        e.preventDefault()

    _on_click: (e) ->
        e.preventDefault()

    _on_mouse_down: (e) ->
        e.preventDefault()
        @signal_event("mousedown",@_make_canvas_mouse_event(e))


    _on_mouse_up: (e) ->
        e.preventDefault()
        @signal_event("mouseup",@_make_canvas_mouse_event(e))

    _make_canvas_mouse_event: (e) ->
        rect = @canvas.getBoundingClientRect()
        root = document.documentElement

        
        ev = 
            x:e.clientX - rect.top - root.scrollTop
            y:e.clientY - rect.left - root.scrollLeft
            button:e.button

        return pt



    _on_context_menu: (e) ->
        e.preventDefault()


    signal_event: (evname, evobj) ->
        ev =
            name:evname
            msg :evobj
        @event_queue.push(ev)

###
# EventTypes
# An object that enumerates the main types of events that all events are categorized as
###
EventTypes =
    MOUSE:0
    KEYBOARD:1
    USER:2

###
# CanvasEvents
###
CanvasEvents =
    KEYPRESS   :0
    KEYRELEASE :1
    MOUSEUP    :2
    MOUSEDOWN  :3
    USER:4

MouseButton =
    LEFT   :1
    MIDDLE :2
    RIGHT  :3
