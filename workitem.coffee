TimeItem = require './timeitem'

class WorkItem

	constructor: (@start, @end, @project, @position, @description, @shortCut, @originalString) ->


	projectPosition: () ->
		#TODO

	

	hoursDuration: () ->
		TimeItem.difference(@start, @end);




module.exports = WorkItem