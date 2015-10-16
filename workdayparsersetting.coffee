class WorkDayParserSettings

	constructor: () ->
		@shortCutGroups = []
		@shortCuts = []

	getValidShortCuts: (from) ->
		all = @shortCuts
		