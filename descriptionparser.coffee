S = require 'string'
spu = require('./stringparserutils').spu

class DescriptionParser
	@parseDescription: (s) ->
		ret = new DescriptionParserResult()
		if !S(s).isEmpty()
			if S(s).contains("(+")
				[first, second] = spu.splitOnFirst(s, "(+")
				ret.BeforeDescription = first
				ret.Description = spu.SplitOnLast(second, ")")[0]
				ret.UsedAppendDelimiter = true
			else if S(s).contains("(")
				[first, second] = spu.splitOnFirst(s, "(")
				ret.BeforeDescription = first
				ret.Description = spu.SplitOnLast(second, ")")[0]
			else
				ret.BeforeDescription = s
		ret

class DescriptionParserResult
	beforeDescription: ''
	description: ''
	usedAppendDelimiter: false

module.exports.DescriptionParser = DescriptionParser
module.exports.DescriptionParserResult = DescriptionParserResult