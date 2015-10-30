_ = require 'lodash'
S = require 'string'

class StringParserUtils
	# <summary>
	#   small convenience method to access token (parts) of a string
	#   <example>
	#     "la-li-lu".Token('-', 1) == "la"
	#     "la-li-lu".Token('-', 4) == fallback
	#     "la-li-lu".Token('-', 0) == "la-li-lu"
	#     "la-li-lu".Token('-', -1) == "lu"
	#     String.empty.Token('-', x) == fallback // for all x
	#   </example>
	#   <remarks>
	#     the index is not nullbased!! so the first token is 1 and the last token is -1
	#   </remarks>
	# </summary>
	# <param name = "s">the given string to split</param>
	# <param name = "separator">the separator the split is done with</param>
	# <param name = "token">index of token to use, this is 1-based</param>
	# <param name="fallback">what will be returned if separator is not found</param>
	# <returns></returns>
	@token: (s, separator, token, fallback='') ->
		if !S(s).isEmpty() && S(s).contains(separator)
			tokens = s.split(separator)
			if token > 0
				# means: start at the beginning
				idx = token - 1
				if idx < tokens.length
					return tokens[idx]
				
			else if token < 0
				#  mean: start from end
				idx = tokens.length + token
				if idx >= 0
					return tokens[idx]
			else
				return s
		return fallback

	# <summary>
	#   small convenience method to access token (parts) of a string
	#   <example>
	#     "la-li-lu".Token('-', 1) == "la"
	#     "la-li-lu".Token('-', 4) == string.empty
	#     "la-li-lu".Token('-', 0) == "la-li-lu"
	#     "la-li-lu".Token('-', -1) == "lu"
	#     String.empty.Token('-', x) == string.empty // for all x
	#   </example>
	#   <remarks>
	#     the index is not nullbased!! so the first token is 1 and the last token is -1
	#   </remarks>
	# </summary>
	# <param name = "s">the given string to split</param>
	# <param name = "separator">the separator the split is done with</param>
	# <param name = "token">index of token to use, this is 1-based</param>
	# <returns></returns>

	@splitOnFirst: (s, separator) ->
		if !S(s).isEmpty()
			if !S(separator).isEmpty()
				idx = s.indexOf(separator)
				if idx >= 0
					return [s.substring(0, idx), s.substring(idx + separator.length)]
				return [s, s]
			return [s, s]
		return ['', '']

	@splitOnLast: (s, separator) ->
		if !S(s).isEmpty()
			if !S(separator).isEmpty()
				idx = s.lastIndexOf(separator)
				if idx >= 0
					return [s.substring(0, idx), s.substring(idx + separator.length)]
				return [s, s]
			return [s, s]
		return ['', '']

	# <summary>
	#   small convenience method to access token (parts) of a string
	#   <example>
	#     "la-li-lu".Token('-', 1) == "la"
	#     "la-li-lu".Token('-', 4) == input
	#     "la-li-lu".Token('-', 0) == "la-li-lu"
	#     "la-li-lu".Token('-', -1) == "lu"
	#     String.empty.Token('-', x) == input // for all x
	#   </example>
	#   <remarks>
	#     the index is not nullbased!! so the first token is 1 and the last token is -1
	#   </remarks>
	# </summary>
	# <param name = "s">the given string to split</param>
	# <param name = "separator">the separator the split is done with</param>
	# <param name = "token">index of token to use, this is 1-based</param>
	# <returns></returns>
	@tokenReturnInputIfFail: (s, separator, token) ->
		@token(s, separator, token, s)

	@splitWithIgnoreRegions: (s, separators, ignoreregions...) ->
		if !separators?
			throw new Error("separators")

		if !ignoreregions? or !_.any(ignoreregions)
			throw new Error("ignoreregions")


		splitted = []
		irStack = []
		if !S(s).isEmpty()
			tmp = ''
			for c in s
				irMatch = _.first(ignoreregions, (ir) -> ir.start == c)
				boo = _.any(separators, (sep) => sep == c);
				#console.log "Current c: #{c} Stack: #{irStack} irMatch: #{JSON.stringify irMatch}"

				if _.any(irStack) and irStack[0] == c
					# found end of ignoreregion, remove last region info
					irStack.pop()
					tmp += c
				else if irMatch[0]? #!(S(irMatch).isEmpty())
					# found start of ignoreregion
					irStack.push(irMatch[0].end)
					tmp += c
				else if _.any(separators, (sep) => sep == c) and !_.any(irStack)
					# found valid separator, do split, but check if there are pending ignore regions in stack
					splitted.push(tmp)
					tmp = ''
				else
					tmp += c
			splitted.push(tmp)
			return splitted
		return []

class IgnoreRegion
	constructor: (@start, @end) ->

module.exports.spu = StringParserUtils	
module.exports.ir = IgnoreRegion	
