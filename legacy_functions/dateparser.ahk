; /--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Date Parsing
; \--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
fn_DateParser(str)
{
	date_array := []
	d_array := []

	;Get the century
	FormatTime, local_century, A_Now, yyyy
	local_century := SubStr(local_century, 1, 2)

	;remove all spaces and non-numbers
	str := regexreplace(regexreplace(regexreplace(str
				  , "[^,\d]+", " ")
				  , ",", "")
				  , "^\s*(\S.*\S|\S)\s*$", "$1")

	try {
		RegExMatch(str, "(\d{8})", RE_Match)
		if (RE_Match1 != "") {
			FormatTime, local_date, %RE_Match1%000000, yyyyMMddHHmmss
			if (fn_DateValidate(local_date)) {
				date_array.push(StringTrimRight(local_date,6))
			}
		}
	}
	catch {
	}
	if (d_array.MaxIndex() > 0) {
		skipalternitives := true
	}
	

	if (skipalternitives != true) {
		try {
			RegExMatch(str, "(\d{4}).*(\d{2}).*(\d{2})", RE_Match)
			if (RE_Match3 != "") {
				FormatTime, local_date, %RE_Match1%%RE_Match2%%RE_Match3%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
				FormatTime, local_date, %RE_Match1%%RE_Match3%%RE_Match2%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
			}
		}
		catch {
		}

		try {
			RegExMatch(str, "(\d{2}).*(\d{2}).*(\d{4})", RE_Match)
			if (RE_Match3 != "") {
				FormatTime, local_date, %RE_Match3%%RE_Match1%%RE_Match2%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				} 
				FormatTime, local_date, %RE_Match3%%RE_Match2%%RE_Match1%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
			}
		}
		catch {
		}

		;Try placing the century in the start of the date
		try {
			RegExMatch(str, "(\d{2}).*(\d{2}).*(\d{2})", RE_Match)
			if (RE_Match3 != "") {
				FormatTime, local_date, %local_century%%RE_Match1%%RE_Match2%%RE_Match3%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
				FormatTime, local_date, %local_century%%RE_Match1%%RE_Match3%%RE_Match2%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
				FormatTime, local_date, %local_century%%RE_Match2%%RE_Match1%%RE_Match3%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
				FormatTime, local_date, %local_century%%RE_Match2%%RE_Match3%%RE_Match1%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
				FormatTime, local_date, %local_century%%RE_Match3%%RE_Match1%%RE_Match2%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
				FormatTime, local_date, %local_century%%RE_Match3%%RE_Match2%%RE_Match3%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
			}
		}
		catch {
		}

		try {
			RegExMatch(str, "(\d{2}).?(\d{2}).?(\d{2})", RE_Match)
			if (RE_Match3 != "") {
				FormatTime, local_date, %local_century%%RE_Match1%%RE_Match2%%RE_Match3%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
				FormatTime, local_date, %local_century%%RE_Match1%%RE_Match3%%RE_Match2%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
				FormatTime, local_date, %local_century%%RE_Match2%%RE_Match1%%RE_Match3%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
				FormatTime, local_date, %local_century%%RE_Match2%%RE_Match3%%RE_Match1%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
				FormatTime, local_date, %local_century%%RE_Match3%%RE_Match1%%RE_Match2%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
				FormatTime, local_date, %local_century%%RE_Match3%%RE_Match2%%RE_Match3%000000, yyyyMMddHHmmss
				if (fn_DateValidate(local_date)) {
					date_array.push(StringTrimRight(local_date,6))
				}
			}
		}
		catch {
		}
		

		try {
			static e2 = "i)(?:(\d{1,2}+)[\s\.\-\/,]+)?(\d{1,2}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*)[\s\.\-\/,]+(\d{2,4})"
			str := RegExReplace(str, "((?:" . SubStr(e2, 42, 47) . ")\w*)(\s*)(\d{1,2})\b", "$3$2$1", "", 1)
			if RegExMatch(str, "i)^\s*(?:(\d{4})([\s\-:\/])(\d{1,2})\2(\d{1,2}))?"
				. "(?:\s*[T\s](\d{1,2})([\s\-:\/])(\d{1,2})(?:\6(\d{1,2})\s*(?:(Z)|(\+|\-)?"
				. "(\d{1,2})\6(\d{1,2})(?:\6(\d{1,2}))?)?)?)?\s*$", i)
				d3 := i1, d2 := i3, d1 := i4, t1 := i5, t2 := i7, t3 := i8
			Else if !RegExMatch(str, "^\W*(\d{1,2}+)(\d{2})\W*$", t)
				RegExMatch(str, "i)(\d{1,2})\s*:\s*(\d{1,2})(?:\s*(\d{1,2}))?(?:\s*([ap]m))?", t)
					, RegExMatch(str, e2, d)
			f = %A_FormatFloat%
			SetFormat, Float, 02.0
			d := (d3 ? (StrLen(d3) = 2 ? 20 : "") . d3 : A_YYYY)
				. ((d2 := d2 + 0 ? d2 : (InStr(e2, SubStr(d2, 1, 3)) - 40) // 4 + 1.0) > 0
					? d2 + 0.0 : A_MM) . ((d1 += 0.0) ? d1 : A_DD) . t1
					+ (t1 = 12 ? t4 = "am" ? -12.0 : 0.0 : t4 = "am" ? 0.0 : 12.0) . t2 + 0.0 . t3 + 0.0
			SetFormat, Float, %f%
			date_array.push(StringTrimRight(d,6))
		}
		catch {
		}
	} 
	

	Loop, % date_array.MaxIndex() {
		if (StrLen(date_array[A_Index]) != 8) {
			continue
		}
		d_array[A_Index,"date"] := date_array[A_Index]
		d_array[A_Index,"distance"] := fn_DateDifference(date_array[A_Index], A_Now,"days")
	}
	biga.sortBy(d_array, "date")
	biga.sortBy(d_array, "distance")
	; Array_Gui(d_array)
	;return tomorrows date if exists
	TomorrowsDate := A_Now
	TomorrowsDate += 1, days
	;return first possible positive date (NOT including today)
	Loop, % d_array.MaxIndex() {
		if (d_array[A_Index,"date"] = FormatTime(TomorrowsDate, "yyyyMMdd")) {
			; msgbox, % "returning tomorrow"
			return d_array[A_Index,"date"]
		}
	}
	Loop, % d_array.MaxIndex() {
		if (d_array[A_Index,"distance"] >= 0 && d_array[A_Index,"distance"] < 30) {
			; msgbox, % "returning " d_array[A_Index,"date"]
			return d_array[A_Index,"date"]
		}
	}
	Loop, % d_array.MaxIndex() {
		if (d_array[A_Index,"distance"] = 0) {
			; msgbox, % "returning today"
			return d_array[A_Index,"date"]
		}
	}
	;return false if no good results
	return false
}

fn_DateDifference(DateTime1, DateTime2, TimeUnits)
{
	EnvSub DateTime1, %DateTime2%, %TimeUnits%
	return DateTime1
}

fn_DateValidate(para_Input) {
	FormatTime, local_date, %para_Input%, yyyyMMddHHmmss
	if (local_date != 000000) {
		return true
	} else {
		return false
	}
}