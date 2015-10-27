TimeItem = require './timeitem'
_ = require 'lodash'
S = require 'string'

class WorkDayParserSettings

	@insertDayBreak
	@dayBreakTime
	@dayBreakDurationTime
	@dayBreakDurationInMinutes
	@shortCuts
	@shortCutGroups

	constructor: () ->
		@shortCutGroups = []
		@shortCuts = []

	allCurrentShortcuts: () ->
		#@getValidShortCuts(DateTime.now)
		@getValidShortCuts(0)

	getValidShortCuts: (from) ->
		all = @shortCuts
		@validShortCuts(all, from)

	validShortCuts: (allShortcuts, testDate) ->
		ret = []
		groupedByKey = _(allShortcuts).groupBy((sc) -> sc.key)

		for key in groupedByKey.keys().value()
			keyedShortcut = groupedByKey.value()[key]

			#TODO falls if(true) ist
			if (_.size(keyedShortcut)>1)
				for groupedByExpansionType in _(keyedShortcut).groupBy((sc)->sc.wholeDayExpansion)
					lastOrDefault = _(groupedByExpansionType).orderBy((sc)->sc.validFrom).first().value()
					if lastOrDefault?
						ret.push lastOrDefault
			else
				ret.push keyedShortcut[0]
		ret

	addShortCut: (shortCut) ->
		@shortCuts.push shortCut
		
module.exports = WorkDayParserSettings