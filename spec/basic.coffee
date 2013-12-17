_ = require "underscore"
Backbone = require "backbone"
path = require "path"
assert = require "better-assert"
{CollectionWindow} = require "../index.js"


NumModel = Backbone.Model.extend {
	defaults:
		value: 0
}

NumCollection = Backbone.Collection.extend {
	model: NumModel
}

flatsplat = (list) ->
	if list.length is 1 and _.isArray(list[0])
		return list[0]
	else
		return list

asKey = (keyName) ->
	(val) ->
		_o = {}
		_o[keyName] = val
		_o

numsToValues = (numList...) ->
	numList = flatsplat numList
	_o = _.map numList, asKey("value")
	#console.log _o
	_o

numsToCollection = (numList...) ->
	numList = flatsplat numList
	_vals = numsToValues(numList)
	_coll = new NumCollection(_vals)

randomInt = (min, max) ->
	unless max?
		max = min
		min = 0
	_range = max - min
	_n = Math.random() * _range
	_n = Math.floor(_n) + min
	#console.log _n
	_n


extractVal = (model) ->
	_json = model.toJSON()
	_json.value

extractVals = (modelList) ->
	_vals = _.map modelList, extractVal
	_vals

nRandomInts = (n, min, max) ->
	_o = []
	unless max?
		max = min
		min = 0
	while n--
		_o.push randomInt(min, max)
	_o

arrayEq = (a, b) ->
	both = _.zip(a, b)
	_cmp = (pair) -> pair[0] is pair[1]
	_result = _.every(both, _cmp)
	_result

sliceVals = (collRef, start, end) ->
	end ?= collRef.length
	_models = collRef.slice(start, end)
	extractVals(_models)

equivSlice = (coll, collWindow) ->
	_r = collWindow._getRange()
	_equiv = sliceVals(coll, _r[0], _r[1])
	_equiv

describe "CollectionWindow", ->
	_nums = nRandomInts(10, 100, 200)
	coll = numsToCollection(_nums)
	#console.log coll.models
	_opts = {start: 0, size: 3}
	collWin = new CollectionWindow(coll, _opts)

	beforeEach ->
		collWin = new CollectionWindow(coll, _opts)

	it "contains `options.size` models.", ->
		_o = collWin.map extractVal
		assert( _o.length is _opts.size)

		_size2 = 6
		collWin = new CollectionWindow( coll, {start: 1, size: _size2} )
		_o = collWin.map extractVal
		assert( _o.length is _size2)

	it "begins at index `options.start`.", ->
		_i = _opts.start
		assert( collWin.at(0) is coll.at(_i) )

		_i2 = 3
		collWin = new CollectionWindow(coll, {start: _i2, size: 4})
		assert( collWin.at(0) is coll.at(_i2) )

	it "is equal to the equivalent slice from the parent collection.", ->
		_vals = collWin.map extractVal
		_equiv = equivSlice coll, collWin
		assert arrayEq(_vals, _equiv)

		collWin = new CollectionWindow(coll, {start: 3, size: 5})
		_vals = collWin.map extractVal
		_equiv = equivSlice coll, collWin
		assert arrayEq(_vals, _equiv)

	describe "#goForward", ->
		it "advances by one when called without arguments.", ->
			origRange = collWin._getRange()
			collWin.goForward()
			newRange = collWin._getRange()
			assert( newRange[0] is (origRange[0] + 1) )
			assert( newRange[1] is (origRange[1] + 1) )
			_all = sliceVals(coll, origRange[0], newRange[1])
			_forwarded = _all.slice 1
			_vals = collWin.map extractVal
			assert arrayEq(_forwarded, _vals)

		it "advances by `n` when called with int argument `n`.", ->
			origRange = collWin._getRange()
			_n = 3
			collWin.goForward(_n)
			newRange = collWin._getRange()
			assert( newRange[0] is (origRange[0] + _n) )
			assert( newRange[1] is (origRange[1] + _n) )
			_all = sliceVals(coll, origRange[0], newRange[1])
			_forwarded = _all.slice 3
			_vals = collWin.map extractVal
			assert arrayEq(_forwarded, _vals)

		it "does not advance beyond the end of the parent collection.", ->
			collSize = coll.length
			winSize = _opts.size
			_n = collSize
			origRange = collWin._getRange()		
			expectedRange = [collSize - winSize, collSize]

			collWin.goForward(_n)
			newRange = collWin._getRange()
			#console.log newRange
			assert( newRange[0] is expectedRange[0] )
			assert( newRange[1] is expectedRange[1] )
			_expectedVals = sliceVals coll, expectedRange[0], expectedRange[1]
			_vals = collWin.map extractVal
			assert arrayEq(_expectedVals, _vals)

		it "returns true if advancement occurs", ->
			assert( collWin.goForward() )
			assert( collWin.goForward(2) )

		it "returns false if already at the last possible window of the parent", ->
			collSize = coll.length
			winSize = _opts.size
			_n = collSize
			_res1 = collWin.goForward(_n)
			assert(_res1)

			_res2 = collWin.goForward()
			assert( _res2 is false )

			_res3 = collWin.goForward(3)
			assert( _res3 is false )

	describe "#goBack", ->
		it "goes back by one when called without arguments.", ->
			_size = 4
			_start = 3
			collWin = new CollectionWindow(coll, {start: _start, size: _size})
			_v = collWin.map extractVal
			#console.log _v
			origRange = collWin._getRange()
			collWin.goBack()
			newRange = collWin._getRange()
			#console.log newRange
			#console.log origRange
			assert( newRange[0] is (origRange[0] - 1) )
			#console.log newRange
			#console.log origRange
			assert( newRange[1] is (origRange[1] - 1) )
			_backed = sliceVals(coll, newRange[0], newRange[1])
			_vals = collWin.map extractVal
			#console.log _backed
			#console.log _vals

			assert arrayEq(_backed, _vals)

		it "goes back by `n` when called with int argument `n`.", ->
			_size = 3
			_start = 5
			collWin = new CollectionWindow(coll, {start: _start, size: _size})
			_v = collWin.map extractVal
			_n = 3
			origRange = collWin._getRange()
			collWin.goBack(_n)
			newRange = collWin._getRange()

			assert( newRange[0] is (origRange[0] - _n) )

			assert( newRange[1] is (origRange[1] - _n) )
			_backed = sliceVals(coll, newRange[0], newRange[1] + 1)
			_vals = collWin.map extractVal
			_all = sliceVals(coll, 0)

			assert arrayEq(_backed, _vals)

		it "does not go back beyond the beginning of the parent collection.", ->
			collSize = coll.length
			winSize = _opts.size
			_n = collSize
			origRange = collWin._getRange()		
			expectedRange = [0, winSize]

			collWin.goBack(_n)
			newRange = collWin._getRange()
			#console.log newRange
			assert( newRange[0] is expectedRange[0] )
			assert( newRange[1] is expectedRange[1] )
			_expectedVals = sliceVals coll, expectedRange[0], expectedRange[1]
			_vals = collWin.map extractVal
			assert arrayEq(_expectedVals, _vals)

		it "returns true if the window changes", ->
			_size = 3
			_start = 5
			collWin = new CollectionWindow(coll, {start: _start, size: _size})
			assert( collWin.goBack() )
			assert( collWin.goBack(2) )

		it "returns false if already at the last possible window of the parent", ->
			_size = 3
			_start = 5
			collWin = new CollectionWindow(coll, {start: _start, size: _size})
			collSize = coll.length
			winSize = _opts.size
			_n = _start
			_res1 = collWin.goBack(_n)
			assert(_res1)

			_res2 = collWin.goBack()
			assert( _res2 is false )

			_res3 = collWin.goBack(3)
			assert( _res3 is false )
