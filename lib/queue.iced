events = require 'events'

# Simple Sidekiq-like queue
module.exports = class Queue extends events.EventEmitter
  constructor: (@pauseOnError)->
    @_tasks = []
    @_active = null
    @isPaused = false
    if @pauseOnError
      @on 'error', =>
        @isPaused = true

    @on 'new', =>
      @_launch() unless @_active? || @isPaused

    @on 'complete', =>
      @_launch() unless @isPaused

  jump: (func)->
    @_tasks.unshift func
    @emit 'new'

  enqueue: (func)->
    @_tasks.push func
    @emit 'new'

  pause: ()->
    @isPaused = true

  resume: ()->
    @isPaused = false
    @_launch() unless @_active?

  busy: ()->
    @size() || @_active?

  size: ()->
    @_tasks.length

  empty: ()->
    @_tasks = []

  _launch: ->
    @_active = func = @_tasks.shift()
    if func?
      func (e)=>
        throw "Queue: cb called twice!!! Something wrong!!!" unless func is @_active
        @_active = null
        @emit 'error', e if e
        @emit 'complete', null, Array.prototype.slice.call arguments, 1
    else
      @emit 'empty'

  






