moment = require 'moment'
S = require 'string'

class WorkDay
	dayType: 'WORKDAY'
	specialDay: ''
	items: []

	constructor: (@year, @month, @day, @specialDays) ->
		@m = moment([@year, @month, @day])
		@dayOfWeek = @m.day() # sunday = 0, saturday = 6
		[@dayType, @specialDay] = this.calculateDayType(@m, @dayOfWeek, @specialDays)

	calculateDayType: (dt, dayOfWeek, specialDays) ->
		if specialDays?
			foundSpecialDay = specialDays[dt.format()]

		if foundSpecialDay?
			return ['HOLIDAY', foundSpecialDay]

		ret = 'UNKNOWN'
		if dayOfWeek > 0 and dayOfWeek < 6
			ret = 'WORKDAY'
		else
			ret = 'WEEKEND'
		[ret, null]

	name: () ->
		if @isToday then 'today' else "#{@year}_#{@month}_#{@day}"

	# HACK
	originalString: (o) ->
		console.log "***************"
		if o?
			@oString = o
			@isChanged = true
			if S(@oString).isEmpty()
				@items = []
			else
				@parseData(@oString)
		else
			@oString

	parseData: (value) ->
		# do parsing
		if WorkDayParser.Instance?
			@lastParseResult = WorkDayParser.Instance.parse(value)

	clear: () ->
		@items = []

	reparse: () ->
		@parseData(@oString)

	hoursDuration: () ->
		sum = 0
		for i in @items
			sum += i.hoursDuration
		sum

	dateTime: () ->
		@m

	isToday: () ->
		now = moment.now()
		now.isSame(@m, 'day')

	to_string: () ->
		"#{dayOfWeek},items:#{@items.length},origString:#{@oString}"

	addWorkItem: (workItem) ->
		@items.push(workItem)
		# !!!!!!!!!!!! JSON Problem !!!!!!!!!!
		#workItem.workDay = @

module.exports = WorkDay