S = require 'string'
spu = require('./stringparserutils').spu

class DescriptionParser
	@parseDescription: (s) ->
		ret = new DescriptionParserResult()
		if !S(s).isEmpty()
			if S(s).contains("(+")
				[first, second] = spu.splitOnFirst(s, "(+")
				ret.beforeDescription = first
				ret.description = spu.splitOnLast(second, ")")[0]
				ret.usedAppendDelimiter = true
			else if S(s).contains("(")
				[first, second] = spu.splitOnFirst(s, "(")
				ret.beforeDescription = first
				ret.description = spu.splitOnLast(second, ")")[0]
			else
				ret.beforeDescription = s
		ret

class DescriptionParserResult
	beforeDescription: ''
	description: ''
	usedAppendDelimiter: false

module.exports.DescriptionParser = DescriptionParser
module.exports.DescriptionParserResult = DescriptionParserResult