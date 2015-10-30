_ = require 'lodash'
S = require 'string'
WorkItem = require ('./workitem')
TimeItem = require ('./timeitem.coffee')
ShortCut = require ('./shortcut.coffee')
WorkDayParserSettings = require ('./workdayparsersetting')
util = require('./stringparserutils')
spu = util.spu
IgnoreRegion = util.ir
dp = require('./descriptionparser')
DescriptionParser = dp.DescriptionParser
DescriptionParserResult = dp.DescriptionParserResult

class WorkDayParser

	#Constants
	dayStartSeparator = ','
	hourProjectInfoSeparator = ';'
	itemSeparator = ','
	endTimeStartChar = '-'
	pauseChar = '!'
	projectPositionSeparator = '-'
	automaticPauseDeactivation = "//"
	#before:
	#settings
	settings=null

	constructor: (@settings) ->

	@instance: ->

	parse: (userInput, wdToFill, insertMetaData=false) ->
		@insertMetaData = insertMetaData

		console.log "Input: #{userInput}"

		# remove newlines		
		userInput = S(userInput).replaceAll('\n', '').s
		
		#check whole day shortcuts
		[userInput, wholeDayShortcut] = @preProcessWholeDayExpansion(userInput, wdToFill.dateTime(), wholeDayShortcut)
		
		# check for // and remove it (remember it was there)
		ignoreBreakSettings = userInput.startsWith(automaticPauseDeactivation)
		if ignoreBreakSettings 
			userInput = userInput.substring(2)

		#return Object; if input is empty return an error
		ret = new WorkDayParserResult()
		if !S(userInput).isEmpty()
			
			# should be like "<daystarttime>,..."
			# eg 7,... or 7:30,...
			[dayStartTime, remainingString, success, error] = @getDayStartTime(userInput)
			console.log "Startzeit: #{dayStartTime.hour}:#{dayStartTime.minute} S: #{success} E: #{error}"
			
			if dayStartTime
				# proceed with parsing items
				parts = spu.splitWithIgnoreRegions(remainingString, [itemSeparator], new IgnoreRegion('(',')'))
				console.log "PARTS: #{parts[0]} + #{parts[1]}"
				wdItemsAsString = _.filter(parts, (p) -> !S(p).isEmpty())

				console.log "Split String: #{wdItemsAsString}"

				if _.any(wdItemsAsString)
					tmpList = []
					for wdItemString in wdItemsAsString
						console.log "Cur In Str: #{wdItemString}"
						[workItem, success, error] = @getWDTempItem(wdItemString, wdToFill.dateTime(), wholeDayShortcut)
						if workItem?
							console.log "Push to tmpList: #{JSON.stringify(workItem)}"
							tmpList.push(workItem)
						else
							console.log "Strange Error 123"
							ret.error = error
							ret.success = false
							# todo: fail fast??

					console.log "Temp List: #{JSON.stringify(tmpList)}"
					resultList = []
					[resultList, success, error] = @processTempWorkItems(dayStartTime, tmpList, ignoreBreakSettings)
					
					console.log "Result list: #{JSON.stringify(resultList)}"
					console.log "Result 1: #{JSON.stringify(resultList[0])}"
					console.log "Result 2: #{JSON.stringify(resultList[1])}"
					console.log "Result 3: #{JSON.stringify(resultList[2])}"
					console.log "Result 4: #{JSON.stringify(resultList[3])}"
					console.log "Error:#{error}"

					console.log "WorkDayObject: #{JSON.stringify(wdToFill)}"

					if _.any(resultList)
						wdToFill.clear()
						for workItem in resultList
							wdToFill.addWorkItem(workItem)
						ret.success = true
					else
						ret.error = error
				else
					# this is no error for now
					ret.success = true
					ret.error = "Noch keine Einträge gemacht"
			else
				ret.error = error
		else
			console.log "Input empty"
			ret.error = "Noch keine Eingabe"
		ret

	preProcessWholeDayExpansion: (userInput, dateTime) ->
		if @settings?
			currentShortcuts = @settings.getValidShortCuts(dateTime)
			if _.any(currentShortcuts, (sc) -> sc.WholeDayExpansion)
				dic = _(currentShortcuts).filter((sc) -> sc.WholeDayExpansion).first((sc) -> sc.key == userInput).value
				if dic?
					return [dic.expansion, dic]
		return [userInput, null]

	processTempWorkItems: (dayStartTime, tmpList, ignoreBreakSettings) ->
		success = false
		error = ''
		resultListTmp = []
		lastTime = dayStartTime
		for workItemTemp in tmpList
			try
				# check for pause
				if workItemTemp.isPause
					if workItemTemp.desiredEndtime?
						lastTime = workItemTemp.desiredEndtime
					else
						lastTime = lastTime.add(workItemTemp.hourCount)
				else
					endTimeMode = false # if endTimeMode do not add, but substract break!
					
					if workItemTemp.desiredEnttime?
						currentEndTime = workItemTemp.desiredEnttime
						endTimeMode = true
					else
						currentEndTime = lastTime.add(workItemTemp.hourCount)
					# check for split
					if @settings?.insertDayBreak and !ignoreBreakSettings
						# the break is in an item
						if @settings.dayBreakTime.is_between(lastTime, currentEndTime)
							# insert new item        !!!!WorkItem!!!!
							resultListTmp.push(new WorkItem(lastTime, this.settings.dayBreakTime, workItemTemp.projectString, workItemTemp.posString))#, workItemTemp.description, workItemTemp.shortCut, workItemTemp.originalString))
							lastTime = @settings.dayBreakTime.add(@settings.dayBreakDurationInMinutes / 60)
							console.log "+++ Last Time: #{JSON.stringify(lastTime)}"
							if !endTimeMode
								# fixup currentEndTime, need to add the dayshiftbreak
								currentEndTime = currentEndTime.add(this.settings.dayBreakDurationInMinutes / 60)
						else if @settings.dayBreakTime == lastTime
							lastTime = lastTime.add(@settings.dayBreakDurationInMinutes / 60)
							if !endTimeMode
								currentEndTime = currentEndTime.add(@settings.dayBreakDurationInMinutes / 60)
					
					workItem = new WorkItem(lastTime, currentEndTime, workItemTemp.projectString, workItemTemp.posString)#, workItemTemp.description, workItemTemp.shortCut, workItemTemp.originalString))
					if(@insertMetaData)
						workItem.description = workItemTemp.description;
						workItem.originalString = workItemTemp.originalString;
						workItem.shortCut = workItemTemp.shortCut;
					resultListTmp.push(workItem)

					lastTime = currentEndTime
					success = true
			catch e
				error = "Beim Verarbeiten von #{workItemTemp.originalString} ist dieser Fehler aufgetreten: #{e}"
				success = false
		resultList = resultListTmp
		#success
		[resultList, success, error]

	getWDTempItem: (wdItemString, dateTime, wholeDayShortcut) ->
		success = false
		workItem = null
		error = ''
		# check for pause item
		if S(wdItemString).endsWith(pauseChar)
			if S(wdItemString).startsWith(endTimeStartChar)
				ti = TimeItem.parse(wdItemString.substring(1, wdItemString.length - 1))
				if ti?
					workItem = new WorkItemTemp(wdItemString)
					workItem.desiredEndtime = ti
					workItem.isPause = true
					success = true
			else
				pauseDuration = parseFloat(wdItemString.substring(0, wdItemString.length - 1))
				workItem = new WorkItemTemp(wdItemString)
				workItem.hourCount = pauseDuration
				workItem.isPause = true
				success = true
		else
			# workitem: <count of hours|-endtime>;<projectnumber>-<positionnumber>[(<description>)]
			timeString = spu.token(wdItemString, hourProjectInfoSeparator, 1, wdItemString).trim()
			if !S(timeString).isEmpty()
				if S(timeString).startsWith(endTimeStartChar)
					ti = TimeItem.parse(timeString.substring(1))
					if ti?
						workItem = new WorkItemTemp(wdItemString)
						workItem.desiredEnttime = ti
					else
						error = string.Format("Die Endzeit kann nicht erkannt werden: #{timeString}")
				else
					hours = parseFloat(timeString)
					workItem = new WorkItemTemp(wdItemString)
					workItem.hourCount = hours
				if workItem?
					projectPosDescString = wdItemString.substring(wdItemString.indexOf(hourProjectInfoSeparator)+1).trim()
					if !S(projectPosDescString).isEmpty()
						# expand abbreviations
						if @settings?
							abbrevStringNoComment = spu.tokenReturnInputIfFail(projectPosDescString, "(", 1).trim()
							abbrevString = spu.tokenReturnInputIfFail(abbrevStringNoComment, "-", 1).trim()
							posReplaceString = spu.token(abbrevStringNoComment, "-", 2).trim()

							shortCut = _.chain(@settings.getValidShortCuts(dateTime)).filter((s) -> !s.wholeDayExpansion).filter((s) -> s.key == abbrevString).value()
							if shortCut? && _.any(shortCut) # TODO why is shortCut an array??
								workItem.shortCut = shortCut[0]
								expanded = shortCut[0].expansion
								# if there is an desc given use its value instead of the one in the abbrev
								desc = DescriptionParser.parseDescription(projectPosDescString)
								descExpanded = DescriptionParser.parseDescription(expanded)
								if !S(desc.description).isEmpty() and desc.usedAppendDelimiter
									# append description in expanded
									expanded = "#{descExpanded.beforeDescription}(#{descExpanded.description}#{desc.description})"
								else if !S(desc.description).isEmpty()
									# replace to description in expanded
									test = @replacePosIfNecessary(descExpanded.beforeDescription, posReplaceString)
									expanded = "#{test}(#{desc.description})"
								else
									expanded = @replacePosIfNecessary(expanded, posReplaceString)

								projectPosDescString = expanded
							else if wholeDayShortcut?
								workItemshortCut = wholeDayShortcut

						projectPosString = spu.tokenReturnInputIfFail(projectPosDescString, "(", 1)
						parts = _.map(projectPosString.split(projectPositionSeparator), (s) -> s.trim())
						if _.any(parts)
							workItem.projectString = parts[0]
							workItem.posString = if parts[1] then parts[1] else ''
							success = true
						else
							error = "Projektnummer kann nicht erkannt werden: #{projectPosDescString}"
						descNoExpand = DescriptionParser.parseDescription(projectPosDescString)
						if !S(descNoExpand.description).isEmpty()
							workItem.description = descNoExpand.description
					else
						error = "Projektnummer ist leer: #{wdItemString}"
			else
				error = "Stundenanzahl kann nicht erkannt werden: #{wdItemString}"
		[workItem, success, error]

	replacePosIfNecessary: (bevoreDes, posReplacement) ->
		if(!S(posReplacement).isEmpty())
			return spu.token(bevoreDes,"-",1,bevoreDes) + "-" + posReplacement
		bevoreDes

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
		return [dayStartTime, remainingString, success, error]
		#success

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
	description: ""
	originalString: null
	shortCut: null

	toString: () ->
		"WorkItemTemp: isPause:#{@isPause}, hourCount:#{@hourCount}, desiredEndtime:#{@desiredEndtime}, projectString:#{@projectString}, posString:#{@posString}, description:#{@description}, originalString:#{@originalString}, shortCut:#{@shortCut}"

module.exports = WorkDayParser
