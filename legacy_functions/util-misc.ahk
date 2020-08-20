; /--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Misc useful functions
; \--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
util_misc_ver := 1.2.0

fn_QuickRegEx(para_Input,para_RegEx,para_ReturnValue := 1)
{	;Quick RegEx for quick matches. Remember to include match parenthesis (\d+).+ Returns matched value
	;fn_QuickRegEx(A_LoopRealLine,"(\d+)")
	if (para_ReturnValue = 0) {
		para_RegEx := "O)" para_RegEx
	}
	RegExMatch(para_Input, para_RegEx, RE_Match)
	if (para_ReturnValue = 0) {
		return RE_Match
	}
	if (RE_Match%para_ReturnValue% != "") {
		ReturnValue := RE_Match%para_ReturnValue%
		return ReturnValue
	}
return false
}


fn_ReplaceStrings(para_1,para_2,para_String)
{	; para_1 is the text to replace, para_2 is the text to replace with, para_String is the Haystack to look in
	StringReplace, l_Newstring, para_String, %para_1%, %para_2%, All
	return l_Newstring
}


fn_findClosestNumber(param_number,param_array) {
	canidateArray := []
	for Key, Value in param_array {
		element := {}
		element.param_number := Value
		element.difference := abs(param_number - Value)

		if (canidateArray[canidateArray.Count()].difference > element.difference || canidateArray.Count() == 0) {
			canidateArray.push(element)
		}
	}
	return canidateArray[canidateArray.Count()].param_number
}


; /--\--/--\--/--\
; Array searching functions
; \--/--\--/--\--/

fn_InArray(Obj, para_Search, para_Table := "")
{
	if (para_Table = "") {
		loop % Obj.MaxIndex() {
			if (Obj[A_Index] = para_Search)	{
				return true
			}
		}
		; Return false if the search did not find any match
		return false
	}
	
	if (para_Table != "") {
		loop % Obj.MaxIndex() {
			if (Obj[A_Index,para_Table] = para_Search) {
				return true
			}
		}
		; Return false if the search did not find any match
		return false
	}
return false
}


fn_2DArray_FieldEqual(Obj,para_key)
{ 	; compairs values a 2D array to all be the same or not
	; fn_MultiArray_FieldEqual(array,"key_bool/string")
	loop % Obj.MaxIndex() {
		var1 := Obj[A_Index,para_key]
		if (A_Index = 1) {
			var2 := var1
			continue
		}
		if (var2 != var1) {
			return false
		}
		var2 := var1		
	}
return true
}

fn_MD5(para_string, case := 0)
{
	static MD5_DIGEST_LENGTH := 16
	hModule := DllCall("LoadLibrary", "Str", "advapi32.dll", "Ptr")
	, VarSetCapacity(MD5_CTX, 104, 0), DllCall("advapi32\MD5Init", "Ptr", &MD5_CTX)
	, DllCall("advapi32\MD5Update", "Ptr", &MD5_CTX, "AStr", para_string, "UInt", StrLen(para_string))
	, DllCall("advapi32\MD5Final", "Ptr", &MD5_CTX)
	loop % MD5_DIGEST_LENGTH
		o .= Format("{:02" (case ? "X" : "x") "}", NumGet(MD5_CTX, 87 + A_Index, "UChar"))
	return o, DllCall("FreeLibrary", "Ptr", hModule)
}


; /--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Subroutines
; \--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

msg(para_message,para_timeout := 20)
{	
	global

	msgbox, , %The_ProjectName%, %para_message%, %para_timeout%
}