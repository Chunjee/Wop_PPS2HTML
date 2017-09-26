; Version 0.5 of all around useful functions

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Quick RegEx for quick matches. Remember to include match parenthesis (\d+).+ Returns matched value
;Fn_QuickRegEx(A_LoopRealLine,"(\d+)")
Fn_QuickRegEx(para_Input,para_RegEx,para_ReturnValue := 1)
{
	RegExMatch(para_Input, para_RegEx, RE_Match)
	If (RE_Match%para_ReturnValue% != "")
	{
	ReturnValue := RE_Match%para_ReturnValue%
	Return %ReturnValue%
	}
Return "null"
}

Fn_ReplaceString(para_1,para_2,para_String)
{
	Return	StrReplace(para_String, para_1, para_2)
}

Fn_InArray(Obj,para_Search,para_Table := "")
{
	If (para_Table = "") {
		Loop % Obj.MaxIndex() {
			If(Obj[A_Index] = para_Search)	{
			Return 1
			}
		}
		;Return 0 if the search did not find any match
		Return 0
	}
	
	If (para_Table != "") {
		Loop % Obj.MaxIndex() {
			If(Obj[A_Index,para_Table] = para_Search)	{
			Return 1
			}
		}
		;Return 0 if the search did not find any match
		Return 0
	}
Return 0
}

Fn_SearchArrayReturnOther(Obj,para_Search,para_SearchTable,para_ReturnTable)
{
	Loop % Obj.MaxIndex() {
		If(Obj[A_Index,para_SearchTable] = para_Search)	{
		Return Obj[A_Index,para_ReturnTable]
		}
	}
Return "null"
}


Fn_SearchArrayReturnTrue(Obj,para_Search,para_SearchTable)
{
	Loop % Obj.MaxIndex() {
		If(Obj[A_Index,para_SearchTable] = para_Search) {
		Return True
		}
	}
Return False
}


Fn_SearchSimpleArray(Obj,para_Search)
{
	Loop % Obj.MaxIndex() {
		If (Obj[A_Index] = para_Search) {
		Return True
		}
	}
Return False
}


Fn_ParseDate(str) {
	static e2 = "i)(?:(\d{1,2}+)[\s\.\-\/,]+)?(\d{1,2}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*)[\s\.\-\/,]+(\d{2,4})"
	str := RegExReplace(str, "((?:" . SubStr(e2, 42, 47) . ")\w*)(\s*)(\d{1,2})\b", "$3$2$1", "", 1)
	If RegExMatch(str, "i)^\s*(?:(\d{4})([\s\-:\/])(\d{1,2})\2(\d{1,2}))?"
		. "(?:\s*[T\s](\d{1,2})([\s\-:\/])(\d{1,2})(?:\6(\d{1,2})\s*(?:(Z)|(\+|\-)?"
		. "(\d{1,2})\6(\d{1,2})(?:\6(\d{1,2}))?)?)?)?\s*$", i)
		d3 := i1, d2 := i3, d1 := i4, t1 := i5, t2 := i7, t3 := i8, t4 := t1 >11 ? "pm" : "am"
	Else If !RegExMatch(str, "x)^\W*   (\d{1,2}?)   (\d{2})   (\d{2}+)? (?:\s*([ap]m))?  \W*  $", t)
		RegExMatch(str, "ix)(\d{1,2})  \s*  :  \s*  (\d{1,2})   (?:(?:\s*:\s*) (\d{1,2}))?   (?:\s*([ap]m))?", t)
			, RegExMatch(str, e2, d)
	f = %A_FormatFloat%
	SetFormat, Float, 02.0
	d := (d3 ? (StrLen(d3) = 2 ? 20 : "") . d3 : A_YYYY)
		. ((d2 := d2 + 0 ? d2 : (InStr(e2, SubStr(d2, 1, 3)) - 40) // 4 + 1.0) > 0
			? d2 + 0.0 : A_MM) . ((d1 += 0.0) ? d1 : A_DD) . t1
			+ (((t4 = "pm") && (t1 < 12)) ? +12.0 : 0.0) . t2 +0.0 . t3 + 0.0

	SetFormat, Float, %f%
	Return, SubStr(d,1,4) SubStr(d,7,2) SubStr(d,5,2) SubStr(d,9)
}


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Allows for remote shutdown
Sb_RemoteShutDown()
{
SetTimer, RemoteShutDown, 2520000 ;42 mins
Return
RemoteShutDown:
l_Shutdownfile = %A_ScriptDir%\shutdown.cmd
	If (FileExist(l_Shutdownfile)) {
	ExitApp
	}
Return
}

;Debug_Msg is for showing a variable or two instead of msgbox
Debug_Msg(message)
{
Progress, 100, %message%, , , 
;Arial
}