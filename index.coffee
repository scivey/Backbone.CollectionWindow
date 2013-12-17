

if typeof(window) is "undefined"
	_ = require "underscore"
	Backbone = require "backbone"
else
	_ = window._
	Backbone = window.Backbone

flatsplat = (list) ->
	if list.length is 1 and _.isArray(list[0])
		return list[0]
	else
		return list

isInList = (list...) ->
	list = flatsplat list
	_toMatch = {}
	for el in list
		_toMatch[el] = true
	(toTest) ->
		if _toMatch[toTest]?
			true
		else
			false

reverse = (list...) ->
	list = flatsplat list
	_o = []
	it = list.length - 1
	while it > 0
		_o.push list[it]
		it--
	_o




CollectionWindow = Backbone.Collection.extend ({
		constructor: (parent, options) ->
			if options?
				options = _.clone(options)
			else
				options = {}

			@_parent = parent
			options.start ?= 0
			options.size ?= 1
			@_currentStartIndex = options.start
			@_windowSize = options.size

			@_parentLength = ->
				@_parent.length

			Backbone.Collection.prototype.constructor.apply(this, [options])
			@refreshWindow()
			_eventPred = isInList("add", "remove", "reset", "sort")
			@listenTo parent, "all", (evtName, params) ->
				if _eventPred(evtName)
					@refreshWindow()

		refreshWindow: ->
			_range = @_getRange()
			@_reset()
			_mods = @_parent.slice(_range[0], _range[1])
			#console.log _mods
			@add _mods
			@trigger "window:changed"

		_getRange: ->
			_start = @_currentStartIndex
			_end = _start + @_windowSize
			[_start, _end]

		_getLastPossibleRange: ->
			_len = @_parentLength()
			_start = _len - @_windowSize
			_r = [_start, _len]
			# console.log _r
			_r

		_getFirstPossibleRange: ->
			_len = @_parentLength()
			_size = @_windowSize
			_start = 0
			if _len >= _size
				_end = _start + _size
			else
				_end = _len
			_r = [_start, _end]

		goForward: (n) ->
			n ?= 1
			_range = @_getRange()
			if (_range[1] + n) > @_parentLength()
				_lastRange = @_getLastPossibleRange()
				if _range[0] is _lastRange[0]
					if _range[1] is _lastRange[1]
						return false
				@_currentStartIndex = _lastRange[0]
			else
				@_currentStartIndex += n
				
			_newRange = @_getRange()
			if _newRange[0] > _range[1]
				@_reset()
				@add @_parent.slice(_newRange[0], _newRange[1])
			else
				_i = n
				while _i--
					@shift()
				@add @_parent.slice(_range[1], _newRange[1])
			@trigger "window:changed"
			return true

		goBack: (n) ->
			n ?= 1
			_range = @_getRange()
			if (_range[0] - n) < 0
				_firstRange = @_getFirstPossibleRange()
				if _range[0] is _firstRange[0]
					if _range[1] is _firstRange[1]
						return false
				@_currentStartIndex = _firstRange[0]
			else
				@_currentStartIndex -= n

			_newRange = @_getRange()
			#console.log "RANGES"
			#console.log _range
			#console.log _newRange
			if _newRange[1] < _range[0]
				@_reset()
				@add @_parent.slice(_newRange[0], _newRange[1])
			else
				_i = n
				while _i
					@pop()
					_i--

				_slice = @_parent.slice(_newRange[0] - 1, _range[0] + 1)
				_slice = reverse(_slice)
				for x in _slice
					@unshift x
			@trigger "window:changed"
			return true
})

Backbone.CollectionWindow = CollectionWindow

if module? and module.exports?
	module.exports.CollectionWindow = CollectionWindow

if exports?
	exports = module.exports
