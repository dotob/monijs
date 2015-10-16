should = require('chai').should()
WorkDayParser = require('../parser')
WorkDay = require('../workDay');

describe 'WorkDayParser', () ->
	it 'WDParser_EmptyString_ReturnError', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		workItemParserResult = wdp.parse("", wd)

		console.log workItemParserResult

		workItemParserResult.error.should.equal("Noch keine Eingabe")
		workItemParserResult.success.should.equal(false)
	
	it 'WDParser_SingleItemWithDayStartTime_ReturnWorkItemWithOneItem', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		workItemParserResult = wdp.parse("7,2;11111", wd)

