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

		console.log "-=-=-=-=-=-=-=-=-=-=-=-"
		for key in groupedByKey.keys().value()
			keyedShortcut = groupedByKey.value()[key]
			console.log JSON.stringify(keyedShortcut) + " | " + key + " | " + _.size(keyedShortcut)
			#TODO falls if(true) ist
			if (_.size(keyedShortcut)>1)
				groupedByExpansionType = _(keyedShortcut).groupBy((sc)->sc.wholeDayExpansion)
				console.log "#{JSON.stringify groupedByExpansionType}"
				console.log "#{JSON.stringify groupedByExpansionType.keys().value()}"
				for type in groupedByExpansionType.keys().value()
					typeShortcut = groupedByExpansionType.value()[type]
					console.log "#{JSON.stringify typeShortcut}"
					#lastOrDefault = _(typeShortcut).orderBy((sc)->sc.validFrom).first().value()
					lastOrDefault = _(_.sortBy(typeShortcut, 'validFrom')).first()
					console.log "L O D"
					console.log JSON.stringify lastOrDefault
					console.log "???"
					if lastOrDefault?
						ret.push lastOrDefault
			else
				ret.push keyedShortcut[0]
		ret

	addShortCut: (shortCut) ->
		@shortCuts.push shortCut
		
module.exports = WorkDayParserSettings