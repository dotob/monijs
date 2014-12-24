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

		it 'AddMinutes_Work', () ->
			ti = new TimeItem(1,0)
			res = ti.add(0.5)
			res.hour.should.equal(1)
			res.minute.should.equal(30)

		it 'AddMinutes_HourOverflow_Work', () ->
			ti = new TimeItem(1,30)
			res = ti.add(0.75)
			res.hour.should.equal(2)
			res.minute.should.equal(15)

		it 'AddMinutesExact60_HourOverflow_Work', () ->
			ti = new TimeItem(1,30)
			res = ti.add(0.5)
			res.hour.should.equal(2)
			res.minute.should.equal(0)

		it 'AddHoursAndMinutes_Work', () ->
			ti = new TimeItem(1,0)
			res = ti.add(1.5)
			res.hour.should.equal(2)
			res.minute.should.equal(30)
		

		it 'AddHoursInMinutes_Work', () ->
			ti = new TimeItem(1,30)
			res = ti.add(1.5)
			res.hour.should.equal(3)
			res.minute.should.equal(0)
		

	describe 'subtract', () ->
		it 'SubtractHours_Work', () ->
			ti = new TimeItem(2,0)
			res = ti.subtract(1)
			res.hour.should.equal(1)
			res.minute.should.equal(0)
		

		it 'SubtractMinutes_Work', () ->
			ti = new TimeItem(1,0)
			res = ti.subtract(0.5)
			res.hour.should.equal(0)
			res.minute.should.equal(30)

		it 'SubtractMinutes_HourOverflow_Work', () ->
			ti = new TimeItem(1,30)
			res = ti.subtract(0.75)
			res.hour.should.equal(0)
			res.minute.should.equal(45)
		

		it 'SubtractMinutesExact60_HourOverflow_Work', () ->
			ti = new TimeItem(1,30)
			res = ti.subtract(0.5)
			res.hour.should.equal(1)
			res.minute.should.equal(0)
		

		it 'SubtractHoursAndMinutes_Work', () ->
			ti = new TimeItem(4,0)
			res = ti.subtract(1.5)
			res.hour.should.equal(2)
			res.minute.should.equal(30)
		

		it 'SubtractHoursInMinutes_Work', () ->
			ti = new TimeItem(3,30)
			res = ti.subtract(1.5)
			res.hour.should.equal(2)
			res.minute.should.equal(0)
		

		it 'OutOfRange_Fail', () ->
			ti = new TimeItem(1,0)
			#should.Throw(() => { i = ti.subtract(5) })
		

	describe 'is_between', () ->
		it 'InsideHourLevel_Work', () ->
			new TimeItem(12).is_between(new TimeItem(11), new TimeItem(13)).should.be.true
		
		it 'InsideMinuteLevel_Work', () ->
			new TimeItem(12).is_between(new TimeItem(11,58), new TimeItem(12,2)).should.be.true

		it 'OutsideHourLevel_Fail', () ->
			new TimeItem(13).is_between(new TimeItem(11), new TimeItem(12)).should.be.false
		
		it 'OutsideMinuteLevel_Fail', () ->
			new TimeItem(13,13).is_between(new TimeItem(11,11), new TimeItem(12,12)).should.be.false
		

	describe 'compares', () ->
		it 'IsSmaller_Works', () ->
			new TimeItem(10).is_smaller_than(new TimeItem(11)).should.be.true
			new TimeItem(10,10).is_smaller_than(new TimeItem(10,11)).should.be.true
			new TimeItem(10,10).is_smaller_than(new TimeItem(11,9)).should.be.true

		it 'IsSmaller_WorksNot', () ->
			new TimeItem(11).is_smaller_than(new TimeItem(10)).should.be.false
			new TimeItem(10,11).is_smaller_than(new TimeItem(10,10)).should.be.false
			new TimeItem(11,9).is_smaller_than(new TimeItem(10,10)).should.be.false

		it 'IsBigger_Works', () ->
			new TimeItem(11).is_bigger_than(new TimeItem(10)).should.be.true
			new TimeItem(10, 11).is_bigger_than(new TimeItem(10, 10)).should.be.true
			new TimeItem(11, 9).is_bigger_than(new TimeItem(10, 10)).should.be.true
				
		
		it 'IsEqual_Works', () ->
			new TimeItem(10).is_equal(new TimeItem(10)).should.be.true
			new TimeItem(10, 10).is_equal(new TimeItem(10, 10)).should.be.true
		

	describe 'diff', () ->
		it 'Calc_DoitRight_1', () ->
			TimeItem.difference(new TimeItem(1,1), new TimeItem(1,1)).should.be.equal(0)
		it 'Calc_DoitRight_2', () ->
			TimeItem.difference(new TimeItem(1,0), new TimeItem(1,30)).should.be.equal(0.5)
		it 'Calc_DoitRight_3', () ->
			TimeItem.difference(new TimeItem(1,30), new TimeItem(1,0)).should.be.equal(0.5)
		it 'Calc_DoitRight_4', () ->
			TimeItem.difference(new TimeItem(1,0), new TimeItem(2,30)).should.be.equal(1.5)
		it 'Calc_DoitRight_5', () ->
			TimeItem.difference(new TimeItem(1,40), new TimeItem(2,10)).should.be.equal(0.5)
		it 'Calc_DoitRight_6', () ->
			TimeItem.difference(new TimeItem(2,10), new TimeItem(1,40)).should.be.equal(0.5)
		

	describe 'to_monlist_string', () ->
		it 'normal', () ->
			new TimeItem(10, 10).to_monlist_string().should.be.equal("10:10")
		it 'leading zeros', () ->
			new TimeItem(1, 1).to_monlist_string().should.be.equal("01:01")		


	describe 'to_string', () ->
		it 'normal', () ->
			new TimeItem(10, 10).to_string().should.be.equal("10:10")
		it 'no leading zeros', () ->
			new TimeItem(1, 1).to_string().should.be.equal("1:01")


	describe 'to_short_string', () ->
		it 'normal', () ->
			new TimeItem(10, 10).to_short_string().should.be.equal("10:10")
		it 'no leading zeros', () ->
			new TimeItem(1, 1).to_short_string().should.be.equal("1:01")
		it 'no minute', () ->
			new TimeItem(1, 0).to_short_string().should.be.equal("1")