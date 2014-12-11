_ = require 'lodash'
S = require 'string'

class TimeItem

	constructor: (@hour, @minute=0) ->
		if @hour > 24
			throw "hour darf nicht größer als 24 sein"
		if @hour < 0
			throw "hour darf nicht kleiner als 0 sein"
		if @minute > 60
			throw "minute darf nicht größer als 60 sein"
		if @minute < 0
			throw "minute darf nicht kleiner als 0 sein"
		
		if @minute > 60
			@hour += 1
			@minute = 0

	is_bigger_than = (other) ->
		if @hour == other.hour
			@minute > other.minute
		else
			@hour > other.hour

	is_smaller_than = (other) ->
		if @hour == other.hour
			@minute < other.minute
		else
			@hour < other.hour

	is_equal = (other) ->
		@hour==other.hour and @minute==other.minute

	@now = () ->
		now = new Date()
		minutes = now.Minute - (now.Minute % 15)
		new TimeItem now.Hour, minutes

	@is_between = (from, to) ->
		@.is_bigger_than from and @.is_smaller_than to

	@parse = (s) ->
		if !S(s).isEmpty()
			parts = _.select(s.split(':'), p => S(s).Trim().s)
			if _.any(parts)
				hour = S(parts[0]).toInt()
				if parts.count() > 1
					min = S(parts[1]).toInt()
					new TimeItem(hour, min)
				else
					if hour > 100 and hour <= 2400
						#success = TryParse(hour.ToString("00:00"), out ti)
					else
						new TimeItem(hour, 0)
		else
			null

	add = (hours) ->
		partBeforeKomma = Math.floor hours
		partAfterKomma = hours - partBeforeKomma
		minutes = Math.round(partAfterKomma * 60) + @minute
		if minutes >= 60
			partBeforeKomma++
			minutes -= 60
		new TimeItem(@hour + partBeforeKomma, minutes)

	subtract = (hours) ->
		partBeforeKomma = Math.floor hours
		partAfterKomma = hours - partBeforeKomma
		minutes = @minute - Math.round(partAfterKomma * 60)
		if minutes < 0
			partBeforeKomma++
			minutes += 60
		new TimeItem(@our - partBeforeKomma, minutes)

	@difference = (a, b) ->
		if a? and b?
			if a.is_equal b
				return 0
			if a.is_bigger_than a
				return @difference b, a
			# do the real math, we know a is smaller than b here
			if a.hour == b.hour
				return (b.minute - a.minute) / 60
			minutes = 60 - a.minute + b.minute
			hours = b.hour - (a.hour + 1) # +1 because we took the minutes from the started hour into minutes
			return (hours * 60 + minutes) / 60
		0

	to_string = () ->
		"#{@hour}:#{@minute}"

	to_monlist_string = () ->
		"#{@hour}:#{@minute}"

	to_short_string = () ->
		if @minute == 0
			"#{@hour}"
		@.to_String()

module.exports = TimeItem	