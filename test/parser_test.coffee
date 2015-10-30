should = require('chai').should()
expect = require('chai').expect

dp = require('../descriptionparser')
DescriptionParser = dp.DescriptionParser
DescriptionParserResult = dp.DescriptionParserResult

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
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)#

	it '16 WDParser_InsertEndTimePauseItemWithComment_LeavePause', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()

		workItemParserResult = wdp.parse("7,1;11111-111,-10:30(massage)!,2;11111-111", wd)

		expValue = [new WorkItem(new TimeItem(7), new TimeItem(8), "11111", "111"), 
					new WorkItem(new TimeItem(10,30), new TimeItem(12,30), "11111", "111")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '17 WDParser_ParseHourFragment_MultiplyBy60', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()

		workItemParserResult = wdp.parse("7,1.75;11111-111", wd)

		expValue = [new WorkItem(new TimeItem(7), new TimeItem(8,45), "11111", "111")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '18 WDParser_ParseHourFragment2_MultiplyBy60', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()

		workItemParserResult = wdp.parse("9:15,7.25;11111-111", wd)

		expValue = [new WorkItem(new TimeItem(9,15), new TimeItem(16,30), "11111", "111")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '19 WDParser_ParseDescription_GetDesc', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()

		workItemParserResult = wdp.parse("9:15,7.25;11111-111(lalala)", wd, true)

		expValue = [new WorkItem(new TimeItem(9,15),
								 new TimeItem(16,30), 
								 "11111", "111", "lalala", null, "7.25;11111-111(lalala)")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

		
	it '20 WDParser_ParseDescriptionWithItemSeparator_GetDesc', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()

		workItemParserResult = wdp.parse("9:15,7.25;11111-111(lal,ala)", wd, true)

		expValue = [new WorkItem(new TimeItem(9,15),
								 new TimeItem(16,30), 
								 "11111", "111", "lal,ala", null, "7.25;11111-111(lal,ala)")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)


	it '21 WDParser_ParseDescriptionWithDescriptionSeparator_GetDesc', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()

		workItemParserResult = wdp.parse("9:15,7.25;11111-111(lal(123)ala)", wd, true)

		expValue = [new WorkItem(new TimeItem(9,15),
								 new TimeItem(16,30), 
								 "11111", "111", "lal(123)ala", null, "7.25;11111-111(lal(123)ala)")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '22 WDParser_ParseDescriptionWithDescriptionSeparatorMissing_GetDesc', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()

		workItemParserResult = wdp.parse("9:15,7.25;11111-111(lal(123)ala", wd, true)

		expValue = [new WorkItem(new TimeItem(9,15),
								 new TimeItem(16,30), 
								 "11111", "111", "lal(123", null, "7.25;11111-111(lal(123)ala")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '23 WDParser_ParseDescriptionWithSemicolon_GetDesc', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()

		workItemParserResult = wdp.parse("9:15,7.25;11111-111(lala;123)", wd, true)

		expValue = [new WorkItem(new TimeItem(9,15),
								 new TimeItem(16,30), 
								 "11111", "111", "lala;123", null, "7.25;11111-111(lala;123)")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '24 WDParser_UseAbbreviationsAndDesc_ExpandAbbreviationsAndOverwriteDescFromAbbr', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		settings = new WorkDayParserSettings()
		ctb = new ShortCut("ctb", "11111-111(donotuseme)")
		ktl = new ShortCut("ktl", "22222-222(useme)")
		settings.addShortCut(ctb)
		settings.addShortCut(ktl)
		wdp.settings = settings

		workItemParserResult = wdp.parse("9:00,2;ctb(useme),2;ktl", wd, true)

		expValue = [new WorkItem(new TimeItem(9), new TimeItem(11), 
								 "11111", "111", "useme", ctb, "2;ctb(useme)"),
					new WorkItem(new TimeItem(11), new TimeItem(13), 
								 "22222", "222", "useme", ktl, "2;ktl")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '25 WDParser_UseAbbreviationsAndDescAndPosReplace_ExpandAbbreviationsAndOverwriteDescFromAbbr', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		settings = new WorkDayParserSettings()
		ctb = new ShortCut("ctb", "11111-111(donotuseme)")
		ktl = new ShortCut("ktl", "22222-222(useme)")
		settings.addShortCut(ctb)
		settings.addShortCut(ktl)
		wdp.settings = settings

		workItemParserResult = wdp.parse("9:00,2;ctb-444(useme),2;ktl", wd, true)

		expValue = [new WorkItem(new TimeItem(9), new TimeItem(11), 
								 "11111", "444", "useme", ctb, "2;ctb-444(useme)"),
					new WorkItem(new TimeItem(11), new TimeItem(13), 
								 "22222", "222", "useme", ktl, "2;ktl")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '26 WDParser_UseAbbreviationsAndDesc_ExpandAbbreviationsAndAppendToDescFromAbbr', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		settings = new WorkDayParserSettings()
		ctb = new ShortCut("ctb", "11111-111(prefix)")
		ktl = new ShortCut("ktl", "22222-222(useme)")
		settings.addShortCut(ctb)
		settings.addShortCut(ktl)
		wdp.settings = settings

		workItemParserResult = wdp.parse("9:00,2;ctb(+ suffix),2;ktl", wd, true)

		expValue = [new WorkItem(new TimeItem(9), new TimeItem(11), 
								 "11111", "111", "prefix suffix", ctb, "2;ctb(+ suffix)"),
					new WorkItem(new TimeItem(11), new TimeItem(13), 
								 "22222", "222", "useme", ktl, "2;ktl")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '27 WDParser_UseAbbreviationsAndDescAndPosReplace_ExpandAbbreviationsAndAppendToDescFromAbbr', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		settings = new WorkDayParserSettings()
		ctb = new ShortCut("ctb", "11111-111(prefix)")
		ktl = new ShortCut("ktl", "22222-222(useme)")
		settings.addShortCut(ctb)
		settings.addShortCut(ktl)
		wdp.settings = settings

		workItemParserResult = wdp.parse("9:00,2;ctb-444(+ suffix),2;ktl", wd, true)

		expValue = [new WorkItem(new TimeItem(9), new TimeItem(11), 
								 "11111", "111", "prefix suffix", ctb, "2;ctb-444(+ suffix)"),
					new WorkItem(new TimeItem(11), new TimeItem(13), 
								 "22222", "222", "useme", ktl, "2;ktl")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '28 WDParser_InsteadOfHoursICanTellAnEndTime_UseEndTime', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		settings = new WorkDayParserSettings()
		ctb = new ShortCut("ctb", "11111-111")
		ktl = new ShortCut("ktl", "22222-222")
		settings.addShortCut(ctb)
		settings.addShortCut(ktl)
		wdp.settings = settings

		workItemParserResult = wdp.parse("9:00,-12;ctb,-15;ktl", wd, true)

		expValue = [new WorkItem(new TimeItem(9), new TimeItem(12), 
								 "11111", "111", "", ctb, "-12;ctb"),
					new WorkItem(new TimeItem(12), new TimeItem(15), 
								 "22222", "222", "", ktl, "-15;ktl")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '29 WDParser_UsingEndTimeAndBreak_CalculateBreak', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		settings = new WorkDayParserSettings()
		ctb = new ShortCut("ctb", "11111-111")
		ktl = new ShortCut("ktl", "22222-222")
		settings.addShortCut(ctb)
		settings.addShortCut(ktl)
		settings.insertDayBreak = true
		settings.dayBreakTime = new TimeItem(12)
		settings.dayBreakDurationInMinutes = 30
		wdp.settings = settings

		workItemParserResult = wdp.parse("9:00,-14;ctb,-16;ktl", wd, true)

		expValue = [new WorkItem(new TimeItem(9), new TimeItem(12), 
								 "11111", "111", "", ctb, "-14;ctb"),
					new WorkItem(new TimeItem(12,30), new TimeItem(14), 
								 "11111", "111", "", ctb, "-14;ctb"),
					new WorkItem(new TimeItem(14), new TimeItem(16),
								 "22222", "222", "", ktl, "-16;ktl")]
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '30 WDParser_BrokenHours_CalculateCorrectly', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		
		workItemParserResult = wdp.parse("8:15,-15:30;11111-111,1;11111-111", wd, true)

		expValue = [new WorkItem(new TimeItem(8,15), new TimeItem(15,30), 
								 "11111", "111", "", null, "-15:30;11111-111"),
					new WorkItem(new TimeItem(15,30), new TimeItem(16,30), 
								 "11111", "111", "", null, "1;11111-111")]

		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '31 WDParser_BrokenHoursWithBreak_CalculateCorrectly', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		settings = new WorkDayParserSettings()
		settings.insertDayBreak = true
		settings.dayBreakTime = new TimeItem(12)
		settings.dayBreakDurationInMinutes = 30
		wdp.settings = settings

		workItemParserResult = wdp.parse("8:15,-15:30;11111-111,1;11111-111", wd, true)

		expValue = [new WorkItem(new TimeItem(8,15), new TimeItem(12), 
								 "11111", "111", "", null, "-15:30;11111-111"),
					new WorkItem(new TimeItem(12,30), new TimeItem(15,30), 
								 "11111", "111", "", null, "-15:30;11111-111"),
					new WorkItem(new TimeItem(15, 30), new TimeItem(16,30),
								 "11111", "111", "", null, "1;11111-111")]
		console.log "-------------------------"
		console.log "Error #{workItemParserResult.error} | Success: #{workItemParserResult.success}"
		console.log "Parser: " + JSON.stringify(wd.items)
		console.log "Should: " + JSON.stringify(expValue)
		
		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

	it '32 WDParser_PartEndsAtBreakTime_AddBreakCorrectly', () ->
		wd = new WorkDay(1,1,1,null)
		wdp = new WorkDayParser()
		settings = new WorkDayParserSettings()
		settings.insertDayBreak = true
		settings.dayBreakTime = new TimeItem(12)
		settings.dayBreakDurationInMinutes = 30
		wdp.settings = settings		

		workItemParserResult = wdp.parse("8,4;11111-111,4;11111-111", wd, true)
		expValue = [new WorkItem(new TimeItem(8), new TimeItem(12), 
								 "11111", "111", "", null, "4;11111-111"),
					new WorkItem(new TimeItem(12,30), new TimeItem(16,30), 
								 "11111", "111", "", null, "4;11111-111")]

		should.equal(true, _.isEqual(wd.items, expValue))
		workItemParserResult.success.should.equals(true)

		

		