should = require('chai').should()
TimeItem = require('../timeitem')

describe 'TimeItem', () ->
	describe 'parse', () ->
		it 'TryParse_EmptyString_NoSuccess', () ->
			ti = TimeItem.parse ""
			should.not.exist(ti)
