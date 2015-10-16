_ = require 'lodash'
S = require 'string'
util = require('./stringparserutils')
spu = util.spu
IgnoreRegion = util.ir
dp = require('./descriptionparser')
DescriptionParser = dp.DescriptionParser
DescriptionParserResult = dp.DescriptionParserResult

class WorkDayParser

	dayStartSeparator = ','
	hourProjectInfoSeparator = ';'
	itemSeparator = ','
	endTimeStartChar = '-'
	pauseChar = '!'
	projectPositionSeparator = '-'
	automaticPauseDeactivation = "//"
	#before:
	#settings
	settings={}

	constructor: (@settings) ->

	@instance: ->

	parse: (userInput, wdToFill) ->
		# remove newlines
		
		userInput = S(userInput).replaceAll('\n', '').s
		
		[userInput, wholeDayShortcut] = @preProcessWholeDayExpansion(userInput, wdToFill.dateTime(), wholeDayShortcut)
		
		# check for // and remove it (remember it was there)
		ignoreBreakSettings = userInput.startsWith(automaticPauseDeactivation)
		if ignoreBreakSettings 
			userInput = userInput.substring(2)

		ret = new WorkDayParserResult()
		if !S(userInput).isEmpty()
			
			# should be like "<daystarttime>,..."
			# eg 7,... or 7:30,...
			[dayStartTime, remainingString, error] = @getDayStartTime(userInput)
			if dayStartTime
				# proceed with parsing items
				parts = spu.splitWithIgnoreRegions(remainingString, [itemSeparator], new IgnoreRegion('(',')'))
				wdItemsAsString = _.filter(parts, (p) -> !S(p).isEmpty())
				if _.any(wdItemsAsString)
					tmpList = []
					for wdItemString in wdItemsAsString
						[workItem, error] = @getWDTempItem(wdItemString, wdToFill.dateTime(), wholeDayShortcut)
						if workItem?
							tmpList.push(workItem)
						else
							ret.error = error
							ret.succes = false
							# todo: fail fast??

					resultList = []
					[resultList, error] = @processTempWorkItems(dayStartTime, tmpList, ignoreBreakSettings)
					if _.any(resultList)
						wdToFill.clear()
						for workItem in resultList
							wdToFill.addWorkItem(workItem)
						ret.succes = true
					else
						ret.error = error
				else
					# this is no error for now
					ret.succes = true
					ret.error = "Noch keine Einträge gemacht"
			else
				ret.error = error
		else
			ret.error = "Noch keine Eingabe"
		ret

	preProcessWholeDayExpansion: (userInput, dateTime) ->
		if @settings?
			currentShortcuts = @settings.getValidShortCuts(dateTime)
			if _.any(currentShortcuts, (sc) -> sc.WholeDayExpansion)
				dic = _.filter(currentShortcuts, (sc) -> sc.WholeDayExpansion).first((sc) -> sc.Key == userInput)
				if dic?
					return [dic.Expansion, dic]
		return [userInput, null]

	processTempWorkItems: (dayStartTime, tmpList, ignoreBreakSettings) ->
		success = false
		error = ''
		resultListTmp = []
		lastTime = dayStartTime
		for workItemTemp in tmpList
			try
				# check for pause
				if workItemTemp.IsPause
					if workItemTemp.DesiredEndtime?
						lastTime = workItemTemp.DesiredEndtime
					else
						lastTime += workItemTemp.HourCount
				else
					endTimeMode = false # if endTimeMode do not add, but substract break!
					currentEndTime
					if workItemTemp.DesiredEndtime?
						currentEndTime = workItemTemp.DesiredEndtime
						endTimeMode = true
					else
						currentEndTime = lastTime + workItemTemp.HourCount
					# check for split
					if @settings?.InsertDayBreak and !ignoreBreakSettings
						# the break is in an item
						if @settings.DayBreakTime.is_between(lastTime, currentEndTime)
							# insert new item
							resultListTmp.push(new WorkItem(lastTime, this.settings.DayBreakTime, workItemTemp.ProjectString, workItemTemp.PosString, workItemTemp.Description, workItemTemp.ShortCut, workItemTemp.OriginalString))
							lastTime = @settings.DayBreakTime + @settings.DayBreakDurationInMinutes / 60
							if !endTimeMode
								# fixup currentEndTime, need to add the dayshiftbreak
								currentEndTime = currentEndTime + this.settings.DayBreakDurationInMinutes / 60
						else if @settings.DayBreakTime == lastTime
							lastTime = lastTime + @settings.DayBreakDurationInMinutes / 60
							if !endTimeMode
								currentEndTime = currentEndTime + @settings.DayBreakDurationInMinutes / 60
					
					resultListTmp.push(new WorkItem(lastTime, currentEndTime, workItemTemp.ProjectString, workItemTemp.PosString, workItemTemp.Description, workItemTemp.ShortCut, workItemTemp.OriginalString))
					lastTime = currentEndTime
					success = true
			catch e
				error = "Beim Verarbeiten von #{workItemTemp.OriginalString} ist dieser Fehler aufgetreten: #{e}"
				success = false
		resultList = resultListTmp
		success

	getWDTempItem: (wdItemString, dateTime, wholeDayShortcut) ->
		success = false
		workItem = null
		error = ''
		# check for pause item
		if S(wdItemString).endsWith(pauseChar)
			if S(wdItemString).startsWith(endTimeStartChar)
				ti = TimeItem.parse(wdItemString.substring(1, wdItemString.Length - 2))
				if ti?
					workItem = new WorkItemTemp(wdItemString)
					workItem.DesiredEndtime = ti
					workItem.IsPause = true
					success = true
			else
				pauseDuration = parseFloat(wdItemString.substring(0, wdItemString.Length - 1))
				workItem = new WorkItemTemp(wdItemString)
				workItem.HourCount = pauseDuration
				workItem.IsPause = true
				success = true
		else
			# workitem: <count of hours|-endtime>;<projectnumber>-<positionnumber>[(<description>)]
			timeString = spu.token(wdItemString, hourProjectInfoSeparator, 1, wdItemString).trim()
			if !S(timeString).isEmpty()
				if S(timeString).startsWith(endTimeStartChar)
					ti = TimeItem.parse(timeString.substring(1))
					if ti?
						workItem = new WorkItemTemp(wdItemString)
						workItem.DesiredEndtime = ti
					else
						error = string.Format("Die Endzeit kann nicht erkannt werden: {0}", timeString)
				else
					hours = parseFloat(timeString)
					workItem = new WorkItemTemp(wdItemString)
					workItem.HourCount = hours
				if workItem?
					projectPosDescString = wdItemString.substring(wdItemString.indexOf(hourProjectInfoSeparator)+1).trim()
					if !S(projectPosDescString).isEmpty()
						# expand abbreviations
						if @settings?
							abbrevString = spu.tokenReturnInputIfFail(projectPosDescString, "(", 1).trim()
							shortCut = _.filter(@settings.getValidShortCuts(dateTime), (s) -> !s.WholeDayExpansion).first((s) -> s.Key == abbrevString)
							if shortCut?
								workItem.ShortCut = shortCut
								expanded = shortCut.Expansion
								# if there is an desc given use its value instead of the one in the abbrev
								desc = DescriptionParser.parseDescription(projectPosDescString)
								descExpanded = DescriptionParser.parseDescription(expanded)
								if !S(desc.Description).isEmpty() and desc.UsedAppendDelimiter
									# append description in expanded
									expanded = "#{descExpanded.BeforeDescription}(#{descExpanded.Description}#{desc.Description})"
								else if !S(desc.Description).isEmpty()
									# replace to description in expanded
									expanded = "#{descExpanded.BeforeDescription}(#{desc.Description})"
								projectPosDescString = expanded
							else if wholeDayShortcut?
								workItem.ShortCut = wholeDayShortcut

						projectPosString = spu.tokenReturnInputIfFail(projectPosDescString, "(", 1)
						parts = _.map(projectPosString.split(projectPositionSeparator), (s) -> s.trim())
						if _.any(parts)
							workItem.ProjectString = parts[0]
							workItem.PosString = if parts[1] then parts[1] else ''
							success = true
						else
							error = "Projektnummer kann nicht erkannt werden: #{projectPosDescString}"
						descNoExpand = DescriptionParser.parseDescription(projectPosDescString)
						if !S(descNoExpand.Description).isEmpty()
							workItem.Description = descNoExpand.Description
					else
						error = "Projektnummer ist leer: #{wdItemString}"
			else
				error = "Stundenanzahl kann nicht erkannt werden: #{wdItemString}"
		success

	getDayStartTime: (input) ->
		success = false
		dayStartToken = spu.token(input, dayStartSeparator, 1, input) # do not trim here, need original length later
		if !S(dayStartToken.trim()).isEmpty()
			dayStartTime = TimeItem.parse(dayStartToken)
			if dayStartTime?
				remainingString = if dayStartToken.length < input.length then input.substring(dayStartToken.length + 1) else '' # seems like no daystartseparator
				error = ''
				success = true
			else
				remainingString = input
				error = "Tagesbeginn wird nicht erkannt: #{dayStartToken}"
		else
			error = "no daystart found"
			dayStartTime = null
			remainingString = input
		success

	addCurrentTime: (originalString) ->
		# test for daystart
		newString = originalString
		if S(originalString).isEmpty()
			newString += TimeItem.now.to_string()
		else
			if !S(originalString).endsWith(itemSeparator)
				newString += itemSeparator
			newString += endTimeStartChar + TimeItem.now.to_string()
		newString

class WorkDayParserResult
	constructor: () ->
		@success= false
		@error= ''

class WorkItemTemp
	constructor: (@originalString) ->

	isPause: false
	hourCount: 0
	desiredEndtime: null
	projectString: null
	posString: null
	description: null
	originalString: null
	shortCut: null

module.exports = WorkDayParser