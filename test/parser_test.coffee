should = require('chai').should()
expect = require('chai').expect

WorkDayParser = require('../parser')
ShortCut = require('../shortcut')
WorkDay = require('../workDay');
WorkItem = require('../workitem');
TimeItem = require('../timeitem');
WorkDayParserSettings = require ('../workdayparsersetting')
_ = require 'lodash'

describe 'WorkDayParser', () ->
	it '1 WDParser_EmptyString_ReturnError', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		workItemParserResult = wdp.parse("", wd)

		workItemParserResult.error.should.equal("Noch keine Eingabe")
		workItemParserResult.success.should.equal(false)
	
	it '2 WDParser_SingleItemWithDayStartTime_ReturnWorkItemWithOneItem', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		workItemParserResult = wdp.parse("7,2;11111", wd)

		console.log "Return Object: " + JSON.stringify(workItemParserResult)
		console.log "WorkDay Result: " + JSON.stringify(wd)
		console.log "WorkDay Items: " + JSON.stringify(wd.items)

		console.log "Test Espection:" + JSON.stringify([new WorkItem(new TimeItem(7), new TimeItem(9), "11111", "")])

		workItemParserResult.success.should.equal(true)
		should.equal(true, _.isEqual(wd.items, [new WorkItem(new TimeItem(7), new TimeItem(9), "11111", "")]))
		
	it '3 WDParser_SetEmptyStringAfterSuccessfulParsing_DeleteItems', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		workItemParserResult = wdp.parse("7,2;11111", wd)

		wd.originalString ""
		should.equal(true, _.isEqual(wd.items, []))

	it '4 WDParser_SingleItemWithDayStartTimeAndPos_ReturnWorkItemWithOneItem', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		workItemParserResult = wdp.parse("7,2;11111-111", wd)

		workItemParserResult.success.should.equal(true)
		should.equal(true, _.isEqual(wd.items, [new WorkItem(new TimeItem(7), new TimeItem(9), "11111", "111")]))

	it '5 WDParser_SingleItemWithOddDayStartTime_ReturnWorkItemWithOneItem', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		workItemParserResult = wdp.parse("7:30,2;11111-111", wd)

		workItemParserResult.success.should.equal(true)
		should.equal(true, _.isEqual(wd.items, [new WorkItem(new TimeItem(7,30), new TimeItem(9,30), "11111", "111")]))
		
	it '6 WDParser_SingleItemWithOddDayStartTimeAndOddHourCount_ReturnWorkItemWithOneItem', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		workItemParserResult = wdp.parse("7:30,1.5;11111-111", wd)

		workItemParserResult.success.should.equal(true)
		should.equal(true, _.isEqual(wd.items, [new WorkItem(new TimeItem(7,30), new TimeItem(9,0), "11111", "111")]))
		
	it '7 WDParser_MoreItems_ReturnWorkItemWithMoreItems', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		workItemParserResult = wdp.parse("7:30,1.5;11111-111,3;22222-222", wd)
		

		workItemParserResult.success.should.equal(true)
		should.equal(true, _.isEqual(wd.items, [new WorkItem(new TimeItem(7,30), new TimeItem(9,0), "11111", "111"), new WorkItem(new TimeItem(9,0), new TimeItem(12,0), "22222", "222")]))
		
	it '8 WDParser_MoreItemsAndDayBreak_ReturnWorkItemWithSplittedItems', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()

		settings = new WorkDayParserSettings()
		settings.insertDayBreak = true
		settings.dayBreakTime = new TimeItem(12,0)
		settings.dayBreakDurationInMinutes = 30
		#settings.dayBreakDurationTime = ??
		wdp.settings = settings
		workItemParserResult = wdp.parse("9:00,2;11111-111,3;22222-222", wd)

		expValue = [new WorkItem(new TimeItem(9), new TimeItem(11), "11111", "111"), 
					new WorkItem(new TimeItem(11,0), new TimeItem(12,0), "22222", "222"), 
					new WorkItem(new TimeItem(12,30), new TimeItem(14,30), "22222", "222")]
		workItemParserResult.success.should.equals(true)
		should.equal(true, _.isEqual(wd.items, expValue))
	
	it '9 WDParser_LokalBreakSettingsOptOut_IgnoreBreakSettings', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		
		settings = new WorkDayParserSettings()
		settings.insertDayBreak = true
		settings.dayBreakTime = new TimeItem(12,0)
		settings.dayBreakDurationInMinutes = 30
		wdp.settings = settings
		
		workItemParserResult = wdp.parse("//9:00,2;11111-111,3;22222-222", wd)
		expValue = [new WorkItem(new TimeItem(9), new TimeItem(11), "11111", "111"), 
					new WorkItem(new TimeItem(11,0), new TimeItem(14,0), "22222", "222")]
		workItemParserResult.success.should.equals(true)
		should.equal(true, _.isEqual(wd.items, expValue))		

	it '10 WDParser_WhiteSpace_StillWork', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		
		settings = new WorkDayParserSettings()
		settings.insertDayBreak = true
		settings.dayBreakTime = new TimeItem(12,0)
		settings.dayBreakDurationInMinutes = 30
		wdp.settings = settings
		
		workItemParserResult = wdp.parse("9 : 00 , 2; 11111   -111 , 3;   22222-222", wd)
		expValue = [new WorkItem(new TimeItem(9), new TimeItem(11), "11111", "111"), 
					new WorkItem(new TimeItem(11,0), new TimeItem(12,0), "22222", "222"), 
					new WorkItem(new TimeItem(12,30), new TimeItem(14,30), "22222", "222")]
		
		should.equal(true, _.isEqual(wd.items, expValue))		
		workItemParserResult.success.should.equals(true)

	it '11 WDParser_UseAbbreviations_ExpandAbbreviations', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		settings = new WorkDayParserSettings()
		settings.addShortCut(new ShortCut("ctb", "11111-111"))
		settings.addShortCut(new ShortCut("ktl", "22222-222"))
		settings.addShortCut(new ShortCut("u", "33333-333"))
		settings.addShortCut(new ShortCut("uu", "66666-333"))
		
		console.log "??????Extra Tests??????" 

		console.log "All SC: " + JSON.stringify(settings.shortCuts)
		console.log "Curr SC:" + JSON.stringify(settings.allCurrentShortcuts())
		
		wdp.settings = settings

		workItemParserResult = wdp.parse("9:00,2;ctb,1;u", wd)
		
		expValue = [new WorkItem(new TimeItem(9), new TimeItem(11), "11111", "111"), 
					new WorkItem(new TimeItem(11,0), new TimeItem(12,0), "33333", "333")]
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '12 WDParser_UseAbbreviationsReplacePosString_ExpandAbbreviations', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		settings = new WorkDayParserSettings()
		settings.addShortCut(new ShortCut("ctb", "11111-111"))
		settings.addShortCut(new ShortCut("ktl", "22222-222"))
		settings.addShortCut(new ShortCut("u", "33333-333"))
		wdp.settings = settings

		workItemParserResult = wdp.parse("9:00,2;ctb-444,1;u", wd)

		expValue = [new WorkItem(new TimeItem(9), new TimeItem(11), "11111", "444"), 
					new WorkItem(new TimeItem(11,0), new TimeItem(12,0), "33333", "333")]
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '13 WDParser_InsertTimeIntervalPauseItem_LeavePause', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		
		workItemParserResult = wdp.parse("7,1;11111-111,2!,2;11111-111", wd)

		expValue = [new WorkItem(new TimeItem(7), new TimeItem(8), "11111", "111"), 
					new WorkItem(new TimeItem(10,0), new TimeItem(12,0), "11111", "111")]

		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)
	
	it '14 WDParser_InsertTimeIntervalPauseItemWithComment_LeavePause', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()

		workItemParserResult = wdp.parse("7,1;11111-111,2(massage)!,2;11111-111", wd)

		expValue = [new WorkItem(new TimeItem(7), new TimeItem(8), "11111", "111"), 
					new WorkItem(new TimeItem(10,0), new TimeItem(12,0), "11111", "111")]
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)
	
	it '15 WDParser_InsertEndTimePauseItem_LeavePause', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()

		workItemParserResult = wdp.parse("7,1;11111-111,-10:30!,2;11111-111", wd)

		expValue = [new WorkItem(new TimeItem(7), new TimeItem(8), "11111", "111"), 
					new WorkItem(new TimeItem(10,30), new TimeItem(12,30), "11111", "111")]
		console.log "-------------------------"
		console.log "Error #{workItemParserResult.error} | Success: #{workItemParserResult.success}"
		console.log "Parser: " + JSON.stringify(wd.items)
		console.log "Should: " + JSON.stringify(expValue)
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)
	