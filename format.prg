*==============================================================================
* Function:			Format
* Purpose:			Mimics the String.Format() and $ (string interpolation)
*						methods of .NET
* Author:			Doug Hennig
* Last revision:	04/22/2026
* Parameters:		tcFormat       - the format string
*					tuParameter0-9 - the values to insert into the string
*						(optional: if string interpolation is used, no
*						parameters are required or expected)
* Returns:			the formatted string
* Environment in:	none
* Environment out:	none
* Note:				1.	Adapted from:
*						http://saltydogllc.com/string-format-for-visual-foxpro/
*					2.	If string interpolation is used, the expressions in {}
*						must be visible to this program: variables must be
*						private or public, not local.
* Examples:
* 	Initialize some variables:
*		lcUser    = alltrim(substr(sys(0), at('#', sys(0)) + 1))
*		lnBalance = 12.3456
*	String.Format-like syntax:
*		Format('The balance for {0} on {1} is {2}', lcUser, datetime(), lnBalance)
*			&& returns "The balance for dhenn on 12/16/2023 8:23:53 AM is 12.3456"
*	String.Format-like syntax with formatting:
*		Format('The balance for {0} on {1:F} is {2:C2}', lcUser, datetime(), lnBalance)
*			&& returns "The balance for dhenn on December 16, 2023 8:23:53 AM is $12.35"
*	Interpolation:
*		Format('The balance for {lcUser} on {datetime()} is {lnBalance}')
*			&& returns "The balance for dhenn on 12/16/2023 8:25:10 AM is 12.3456"
*	Interpolation with formatting:
*		Format('The balance for {lcUser} on {datetime():F} is {lnBalance:C2}')
*			&& returns "The balance for dhenn on December 16, 2023 08:25:45 AM is $12.35"
*==============================================================================

lparameters tcFormat, ;
	tuParameter0, ;
	tuParameter1, ;
	tuParameter2, ;
	tuParameter3, ;
	tuParameter4, ;
	tuParameter5, ;
	tuParameter6, ;
	tuParameter7, ;
	tuParameter8, ;
	tuParameter9
local lcCharLeft, ;
	lcCharRight, ;
	lcReturn, ;
	lnCount, ;
	lcSearch, ;
	lcFormat, ;
	lcCount, ;
	lnSize, ;
	lnPos, ;
	luValue, ;
	lcType

* Determine what characters to use as the placeholder delimiters: {} (the
* default) or <>.

lcCharLeft  = '{'
lcCharRight = '}'
if not '{' $ tcFormat
	lcCharLeft  = '<'
	lcCharRight = '>'
endif not '{' $ tcFormat

* Handle escaped characters.

lcReturn = strtran(tcFormat, '\' + lcCharLeft,  chr(250))
lcReturn = strtran(lcReturn, '\' + lcCharRight, chr(251))
lcReturn = strtran(lcReturn, '\\r',             chr(252))
lcReturn = strtran(lcReturn, '\\n',             chr(253))

* Process the format string.

for lnCount = 1 to occurs(lcCharLeft, tcFormat)
	lcSearch = strextract(tcFormat, lcCharLeft, lcCharRight, lnCount, 4)
	lcFormat = strextract(lcSearch, ':', lcCharRight)
	lcCount  = chrtran(strtran(lcSearch, lcFormat, ''), ;
		lcCharLeft + ':' + lcCharRight, '')
	lnSize   = 0
	lnPos    = at(',', lcCount)
	if lnPos > 0
		lnSize  = val(substr(lcCount, lnPos + 1))
		lcCount = left(lcCount, lnPos - 1)
	endif lnPos > 0
	try
		if isdigit(left(lcCount, 1))
			luValue = evaluate('tuParameter' + lcCount)
		else
			luValue = evaluate(lcCount)
		endif isdigit(left(lcCount, 1))

* Handle special characters in the value.

		if vartype(luValue) = 'C'
			luValue = strtran(luValue, lcCharLeft,  chr(246))
			luValue = strtran(luValue, lcCharRight, chr(247))
			luValue = strtran(luValue, '\r',        chr(248))
			luValue = strtran(luValue, '\n',        chr(249))
		endif vartype(luValue) = 'C'
		if empty(lcFormat)
			lcReturn = strtran(lcReturn, lcSearch, transform(luValue))
		else
			lcType = vartype(luValue)
			do case

* Handle Date and DateTime values.

				case inlist(lcType, 'D', 'T')
					lcReturn = strtran(lcReturn, lcSearch, ;
						DateFormat(luValue, lcFormat))

* Handle numeric values.

				case inlist(lcType, 'N', 'Y')
					lcReturn = strtran(lcReturn, lcSearch, ;
						NumericFormat(luValue, lcFormat, lnSize))

* Handle all other values.

				otherwise
					lcReturn = strtran(lcReturn, lcSearch, ;
						transform(luValue, lcFormat))
			endcase
		endif empty(lcFormat)
	catch
	endtry
next lnCount

* Handle \r and \n.

lcReturn = strtran(lcReturn, '\r', chr(13))
lcReturn = strtran(lcReturn, '\n', chr(10))

* Handle escaped characters.

lcReturn = strtran(lcReturn, chr(246), lcCharLeft)
lcReturn = strtran(lcReturn, chr(247), lcCharRight)
lcReturn = strtran(lcReturn, chr(248), '\r')
lcReturn = strtran(lcReturn, chr(249), '\n')
lcReturn = strtran(lcReturn, chr(250), '\' + lcCharLeft)
lcReturn = strtran(lcReturn, chr(251), '\' + lcCharRight)
lcReturn = strtran(lcReturn, chr(252), '\\r')
lcReturn = strtran(lcReturn, chr(253), '\\n')
return lcReturn


function DateFormat(tuValue, tcFormat)
local lcResult, ;
	luValue, ;
	lcFormat, ;
	lcTimeZone, ;
	liBiasSeconds
lcResult = ''
luValue  = tuValue
lcFormat = tcFormat
if vartype(tuValue) = 'D'
	luValue = dtot(tuValue)
endif vartype(tuValue) = 'D'

* Handle single character formats specially.

if len(lcFormat) = 1

* For r, u, and U formats, adjust the time to GMT.

	if inlist(lcFormat, 'r', 'u', 'U')
		declare integer GetTimeZoneInformation in kernel32 ;
			string @lpTimeZoneInformation
		lcTimeZone = replicate(chr(0), 172)
		GetTimeZoneInformation(@lcTimeZone)
		liBiasSeconds = 60 * int(asc(substr(lcTimeZone, 1, 1)) + ;
			bitlshift(asc(substr(lcTimeZone, 2, 1)),  8) + ;
			bitlshift(asc(substr(lcTimeZone, 3, 1)), 16) + ;
			bitlshift(asc(substr(lcTimeZone, 4, 1)), 24))
		luValue = luValue - liBiasSeconds
	endif inlist(lcFormat, 'r', 'u', 'U')
*** TODO FUTURE: support locales e.g. fr-FR would be dd/MM/yyyy for short date
	do case

* Short date e.g. 12/07/2002

		case lcFormat = 'd'
			lcFormat = 'MM/dd/yyyy'

* Long date e.g. December 7, 2002

		case lcFormat = 'D'
			lcFormat = 'MMMM d, yyyy'

* Full date & time e.g. December 7, 2002 10:11 PM

		case lcFormat = 'f'
			lcFormat = 'MMMM d, yyyy hh:mm tt'

* Full date & time (long) e.g. December 7, 2002 10:11:29 PM

		case lcFormat = 'F'
			lcFormat = 'MMMM d, yyyy hh:mm:ss tt'

* General date & time e.g. 12/07/2002 10:11 PM

		case lcFormat = 'g'
			lcFormat = 'MM/dd/yyyy hh:mm tt'

* General date & time (long) e.g. 12/07/2002 10:11:29 PM

		case lcFormat = 'G'
			lcFormat = 'MM/dd/yyyy hh:mm:ss tt'

* Month day e.g. December 7

		case lcFormat = 'M'
			lcFormat = 'MMMM d'

* RFC1123 date string e.g. Tue, 7 Dec 2002 22:11:29 GMT

		case lcFormat = 'r'
			lcFormat = 'ddd, dd MMM yyyy hh:mm:ss GMT'

* Sortable date string e.g. 2002-12-10T22:11:29

		case lcFormat = 's'
			lcResult = ttoc(luValue, 3)

* Short time e.g. 10:11 PM

		case lcFormat = 't'
			lcFormat = 'hh:mm tt'

* Long time e.g. 10:11:29 PM

		case lcFormat = 'T'
			lcFormat = 'hh:mm:ss tt'

* Universal sortable, GMT e.g. 2002-12-07 22:13:50Z

		case lcFormat = 'u'
			lcFormat = 'yyyy-MM-dd hh:mm:ssZ'

* Universal sortable, GMT e.g. 2002-12-07 22:13:50 AM

		case lcFormat = 'U'
			lcFormat = 'yyyy-MM-dd hh:mm:ss tt'

* Year month e.g. December, 2002

		case lcFormat = 'Y'
			lcFormat = 'MMMM, yyyy'
	endcase
endif len(lcFormat) = 1
if empty(lcResult) and len(lcFormat) > 1
	lcResult = ParseDateFormat(lcFormat, luValue)
endif empty(lcResult) ...
return lcResult


function ParseDateFormat(tcFormat, tuValue)
local lcFormat
lcFormat = strtran(tcFormat, 'hh',   padl(hour(tuValue),   2, '0'))
lcFormat = strtran(lcFormat, 'mm',   padl(minute(tuValue), 2, '0'))
lcFormat = strtran(lcFormat, 'ss',   padl(sec(tuValue),    2, '0'))
lcFormat = strtran(lcFormat, 'MMMM', cmonth(tuValue))
lcFormat = strtran(lcFormat, 'MMM',  left(cmonth(tuValue), 3))
lcFormat = strtran(lcFormat, 'MM',   padl(month(tuValue),  2, '0'))
lcFormat = strtran(lcFormat, 'dddd', cdow(tuValue))
lcFormat = strtran(lcFormat, 'ddd',  left(cdow(tuValue), 3))
lcFormat = strtran(lcFormat, 'dd',   padl(day(tuValue), 2, '0'))
lcFormat = strtran(lcFormat, ' d',   ' ' + transform(day(tuValue)))
lcFormat = trim(strtran(lcFormat, 'd ', transform(day(tuValue))) + ' ')
lcFormat = strtran(lcFormat, 'yyyy', transform(year(tuValue)))
lcFormat = strtran(lcFormat, 'yy',   right(transform(year(tuValue)), 2))
lcFormat = strtran(lcFormat, 'tt',   iif(hour(tuValue) < 12, 'AM', 'PM'))
return lcFormat


function NumericFormat(tnValue, tcFormat, tnSize)
local lcFormat, ;
	lcChar, ;
	lnSize, ;
	llSize, ;
	lnCurrDecimals, ;
	lnValue, ;
	lnValueSize, ;
	lnDecimals, ;
	lcResult
lcFormat       = upper(tcFormat)
lcChar         = left(lcFormat, 1)
lnSize         = val(substr(lcFormat, 2))
llSize         = len(lcFormat) > 1
lnCurrDecimals = set('DECIMALS')
lnValue        = tnValue
if lcChar = 'P'
	lnValue = lnValue * 100
endif lcChar = 'P'
if lnValue = 0
	lnValueSize = 1
else
	lnValueSize = int(log10(abs(lnValue))) + 1
endif lnValue = 0
do case

* C<n> e.g. {0:c3} 12345.6789 -> $12,345.679
* C e.g. -12345.6789 -> $-12,345.68
* N<n> e.g. {0:n3} 12345.6789 -> 12,345.679
* N e.g. -12345.6789 -> -12,345.68

	case lcChar $ 'CN'
		lnDecimals = iif(llSize, lnSize, 2)
		lcFormat   = iif(lcChar = 'C', '@$ ', '') + ;
			GetFormat(lnValueSize + iif(lnValue < 0, 2, 1)) + ;
			iif(lnDecimals = 0, '', '.' + replicate('9', lnDecimals))
			&& Add 9 for $ and another 9 for - if value negative
		set decimals to lnSize

* D<n> e.g. {0:d8} 12345.6789 -> 00012345
* D e.g. {0:d} -12345.6789 -> -12345

	case lcChar = 'D'
		lnSize   = GetSize(lnSize, lnValueSize, lnValue)
		lcFormat = '@L ' + replicate('9', lnSize)

* F<n> e.g. {0:f3} 12345.6789 -> 12345.679
* F e.g. -12345.6789 -> -12345

	case lcChar = 'F'
		lnDecimals = iif(llSize, lnSize, 2)
		lnSize     = GetSize(lnValueSize, lnValueSize, lnValue)
		lcFormat   = replicate('9', lnSize) + ;
			iif(lnDecimals = 0, '', '.' + replicate('9', lnDecimals))
		set decimals to lnDecimals

* P<n> e.g. {0:p1} 0.6789 -> 67.9%
* P e.g. -0.6789 -> -67.89%

	case lcChar = 'P'
		lnDecimals = iif(llSize, lnSize, 2)
		lnSize     = GetSize(lnValueSize, lnValueSize, lnValue)
		lcFormat   = replicate('9', lnSize) + ;
			iif(lnDecimals = 0, '', '.' + replicate('9', lnDecimals)) + '%'
		set decimals to lnDecimals

* X e.g. {0:x} 123456789 -> 0x075BCD15

	case lcChar = 'X'
		lcFormat = '@0'
endcase
lcResult = alltrim(transform(lnValue, lcFormat))
do case
	case tnSize > 0
		lcResult = padl(lcResult, tnSize)
	case tnSize < 0
		lcResult = padr(lcResult, tnSize)
endcase
set decimals to lnCurrDecimals
return lcResult


function GetFormat(tnSize)
local lcFormat, ;
	lnCommas, ;
	lnI, ;
	lnPlaces
lcFormat = ''
lnCommas = int(tnSize/3)
for lnI = 1 to lnCommas
	lcFormat = lcFormat + iif(empty(lcFormat), '', ',') + '999'
next lnI
lnPlaces = tnSize - 3 * lnCommas
if lnPlaces > 0
	lcFormat = replicate('9', lnPlaces) + iif(lnCommas > 0, ',', '') + lcFormat
endif lnPlaces > 0
return lcFormat


function GetSize(tnSize, tnValueSize, tnValue)
local lnSize
lnSize = max(tnSize, 1)
if tnSize = 0 or lnSize < tnValueSize
	lnSize = tnValueSize
endif tnSize = 0 ...
if tnValue < 0
	lnSize = lnSize + 1
endif tnValue < 0
return lnSize
