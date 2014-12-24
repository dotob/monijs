should = require('chai').should()
TimeItem = require('../timeitem')

describe 'TimeItem', () ->
	describe 'parse', () ->
		it 'EmptyString_NoSuccess', () ->
			ti = TimeItem.parse ""
			should.not.exist(ti)

		it 'OnlyHour_Success', () ->
			ti = TimeItem.parse "1"
			ti.hour.should.equal(1)
			ti.minute.should.equal(0)

		it 'HourAndMinute_ParseIt', () ->
			ti = TimeItem.parse "1:2"
			ti.hour.should.equal(1)
			ti.minute.should.equal(2)

		it 'HourAndMinuteNoColon-1_ParseIt', () ->
			ti = TimeItem.parse "1600"
			ti.hour.should.equal(16)
			ti.minute.should.equal(0)

		it 'HourAndMinuteNoColon-2_ParseIt', () ->
			ti = TimeItem.parse "630"
			ti.hour.should.equal(6)
			ti.minute.should.equal(30)

		it 'OutOfRange_Throw', () ->
			should.Throw(() -> TimeItem.parse("25:0"))
			should.Throw(() -> TimeItem.parse("-1:0"))
			should.Throw(() -> TimeItem.parse("0:61"))
			should.Throw(() -> TimeItem.parse("0:-1"))

	describe 'add', () ->
		it 'AddHours_Work', () ->
			ti = new TimeItem(1,0)
			res = ti.add(1)
			res.hour.should.equal(2)
			res.minute.should.equal(0)

