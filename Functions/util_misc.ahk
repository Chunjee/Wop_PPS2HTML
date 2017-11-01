; Version 0.5 of all around useful functions

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Quick RegEx for quick matches. Remember to include match parenthesis (\d+).+ Returns matched value
;Fn_QuickRegEx(A_LoopRealLine,"(\d+)")
Fn_QuickRegEx(para_Input,para_RegEx,para_ReturnValue := 1)
{
	RegExMatch(para_Input, para_RegEx, RE_Match)
	If (RE_Match%para_ReturnValue% != "") {
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
		Return true
		}
	}
Return false
}


Fn_SearchSimpleArray(Obj,para_Search)
{
	Loop % Obj.MaxIndex() {
		If (Obj[A_Index] = para_Search) {
		Return true
		}
	}
Return false
}


Fn_DateParser(str)
{
	try {
		RegExMatch(str, "(\d{8})", RE_Match)
		if (RE_Match1 != "") {
			FormatTime, local_date, %RE_Match1%, yyyyMMddHHmmss
			if (local_date != 000000) {
				return local_date
			} else {
				throw, error
			}
		}
	}
	catch {
	}
	
	try {
		RegExMatch(str, "(\d{4}).*(\d{2}).*(\d{2})", RE_Match)
		if (RE_Match3 != "") {
			FormatTime, local_date, %RE_Match1%%RE_Match2%%RE_Match3%, yyyyMMddHHmmss
			if (local_date != 000000 && Fn_IsValidDate(local_date)) {
				return local_date
			}
			FormatTime, local_date, %RE_Match1%%RE_Match3%%RE_Match2%, yyyyMMddHHmmss
			if (local_date != 000000 && Fn_IsValidDate(local_date)) {
				return local_date
			}
		}
	}
	catch {
	}

	try {
		RegExMatch(str, "(\d{2}).*(\d{2}).*(\d{4})", RE_Match)
		if (RE_Match3 != "") {
			FormatTime, local_date, %RE_Match3%%RE_Match1%%RE_Match2%, yyyyMMddHHmmss
			if (local_date != 000000 && Fn_IsValidDate(local_date)) {
				return local_date
			} 
			FormatTime, local_date, %RE_Match3%%RE_Match2%%RE_Match1%, yyyyMMddHHmmss
			if (local_date != 000000 && Fn_IsValidDate(local_date)) {
				return local_date
			} else {
				throw, error
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
		Return, d
	}
	catch {
		return "null"
	}
}

Fn_IsValidDate(para_Input) {
	FormatTime, local_date, %para_Input%, yyyyMMddHHmmss
	if (local_date != 000000) {
		return true
	} else {
		return false
	}
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
}


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Wrappers
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Functions() {
	Return, true
}

IfBetween(ByRef var, LowerBound, UpperBound) {
	If var between %LowerBound% and %UpperBound%
		Return, true
}
IfNotBetween(ByRef var, LowerBound, UpperBound) {
	If var not between %LowerBound% and %UpperBound%
		Return, true
}
IfIn(ByRef var, MatchList) {
	If var in %MatchList%
		Return, true
}
IfNotIn(ByRef var, MatchList) {
	If var not in %MatchList%
		Return, true
}
IfContains(ByRef var, MatchList) {
	If var contains %MatchList%
		Return, true
}
IfNotContains(ByRef var, MatchList) {
	If var not contains %MatchList%
		Return, true
}
IfIs(ByRef var, type) {
	If var is %type%
		Return, true
}
IfIsNot(ByRef var, type) {
	If var is not %type%
		Return, true
}

ControlGet(Cmd, Value = "", Control = "", WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	ControlGet, v, %Cmd%, %Value%, %Control%, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
ControlGetFocus(WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	ControlGetFocus, v, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
ControlGetText(Control = "", WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	ControlGetText, v, %Control%, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
DriveGet(Cmd, Value = "") {
	DriveGet, v, %Cmd%, %Value%
	Return, v
}
DriveSpaceFree(Path) {
	DriveSpaceFree, v, %Path%
	Return, v
}
EnvGet(EnvVarName) {
	EnvGet, v, %EnvVarName%
	Return, v
}
FileGetAttrib(Filename = "") {
	FileGetAttrib, v, %Filename%
	Return, v
}
FileGetShortcut(LinkFile, ByRef OutTarget = "", ByRef OutDir = "", ByRef OutArgs = "", ByRef OutDescription = "", ByRef OutIcon = "", ByRef OutIconNum = "", ByRef OutRunState = "") {
	FileGetShortcut, %LinkFile%, OutTarget, OutDir, OutArgs, OutDescription, OutIcon, OutIconNum, OutRunState
}
FileGetSize(Filename = "", Units = "") {
	FileGetSize, v, %Filename%, %Units%
	Return, v
}
FileGetTime(Filename = "", WhichTime = "") {
	FileGetTime, v, %Filename%, %WhichTime%
	Return, v
}
FileGetVersion(Filename = "") {
	FileGetVersion, v, %Filename%
	Return, v
}
FileRead(Filename) {
	FileRead, v, %Filename%
	Return, v
}
FileReadLine(Filename, LineNum) {
	FileReadLine, v, %Filename%, %LineNum%
	Return, v
}
FileSelectFile(Options = "", RootDir = "", Prompt = "", Filter = "") {
	FileSelectFile, v, %Options%, %RootDir%, %Prompt%, %Filter%
	Return, v
}
FileSelectFolder(StartingFolder = "", Options = "", Prompt = "") {
	FileSelectFolder, v, %StartingFolder%, %Options%, %Prompt%
	Return, v
}
FormatTime(YYYYMMDDHH24MISS = "", Format = "") {
	FormatTime, v, %YYYYMMDDHH24MISS%, %Format%
	Return, v
}
GetKeyState(WhichKey , Mode = "") {
	GetKeyState, v, %WhichKey%, %Mode%
	Return, v
}
GuiControlGet(Subcommand = "", ControlID = "", Param4 = "") {
	GuiControlGet, v, %Subcommand%, %ControlID%, %Param4%
	Return, v
}
ImageSearch(ByRef OutputVarX, ByRef OutputVarY, X1, Y1, X2, Y2, ImageFile) {
	ImageSearch, OutputVarX, OutputVarY, %X1%, %Y1%, %X2%, %Y2%, %ImageFile%
}
IniRead(Filename, Section, Key, Default = "") {
	IniRead, v, %Filename%, %Section%, %Key%, %Default%
	Return, v
}
Input(Options = "", EndKeys = "", MatchList = "") {
	Input, v, %Options%, %EndKeys%, %MatchList%
	Return, v
}
InputBox(Title = "", Prompt = "", HIDE = "", Width = "", Height = "", X = "", Y = "", Font = "", Timeout = "", Default = "") {
	InputBox, v, %Title%, %Prompt%, %HIDE%, %Width%, %Height%, %X%, %Y%, , %Timeout%, %Default%
	Return, v
}
MouseGetPos(ByRef OutputVarX = "", ByRef OutputVarY = "", ByRef OutputVarWin = "", ByRef OutputVarControl = "", Mode = "") {
	MouseGetPos, OutputVarX, OutputVarY, OutputVarWin, OutputVarControl, %Mode%
}
PixelGetColor(X, Y, RGB = "") {
	PixelGetColor, v, %X%, %Y%, %RGB%
	Return, v
}
PixelSearch(ByRef OutputVarX, ByRef OutputVarY, X1, Y1, X2, Y2, ColorID, Variation = "", Mode = "") {
	PixelSearch, OutputVarX, OutputVarY, %X1%, %Y1%, %X2%, %Y2%, %ColorID%, %Variation%, %Mode%
}
Random(Min = "", Max = "") {
	Random, v, %Min%, %Max%
	Return, v
}
RegRead(RootKey, SubKey, ValueName = "") {
	RegRead, v, %RootKey%, %SubKey%, %ValueName%
	Return, v
}
Run(Target, WorkingDir = "", Mode = "") {
	Run, %Target%, %WorkingDir%, %Mode%, v
	Return, v	
}
SoundGet(ComponentType = "", ControlType = "", DeviceNumber = "") {
	SoundGet, v, %ComponentType%, %ControlType%, %DeviceNumber%
	Return, v
}
SoundGetWaveVolume(DeviceNumber = "") {
	SoundGetWaveVolume, v, %DeviceNumber%
	Return, v
}
StatusBarGetText(Part = "", WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	StatusBarGetText, v, %Part%, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
SplitPath(ByRef InputVar, ByRef OutFileName = "", ByRef OutDir = "", ByRef OutExtension = "", ByRef OutNameNoExt = "", ByRef OutDrive = "") {
	SplitPath, InputVar, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
}
StringGetPos(ByRef InputVar, SearchText, Mode = "", Offset = "") {
	StringGetPos, v, InputVar, %SearchText%, %Mode%, %Offset%
	Return, v
}
StringLeft(ByRef InputVar, Count) {
	StringLeft, v, InputVar, %Count%
	Return, v
}
StringLen(ByRef InputVar) {
	StringLen, v, InputVar
	Return, v
}
StringLower(ByRef InputVar, T = "") {
	StringLower, v, InputVar, %T%
	Return, v
}
StringMid(ByRef InputVar, StartChar, Count , L = "") {
	StringMid, v, InputVar, %StartChar%, %Count%, %L%
	Return, v
}
StringReplace(ByRef InputVar, SearchText, ReplaceText = "", All = "") {
	StringReplace, v, InputVar, %SearchText%, %ReplaceText%, %All%
	Return, v
}
StringRight(ByRef InputVar, Count) {
	StringRight, v, InputVar, %Count%
	Return, v
}
StringTrimLeft(ByRef InputVar, Count) {
	StringTrimLeft, v, InputVar, %Count%
	Return, v
}
StringTrimRight(ByRef InputVar, Count) {
	StringTrimRight, v, InputVar, %Count%
	Return, v
}
StringUpper(ByRef InputVar, T = "") {
	StringUpper, v, InputVar, %T%
	Return, v
}
SysGet(Subcommand, Param3 = "") {
	SysGet, v, %Subcommand%, %Param3%
	Return, v
}
Transform(Cmd, Value1, Value2 = "") {
	Transform, v, %Cmd%, %Value1%, %Value2%
	Return, v
}
WinGet(Cmd = "", WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	WinGet, v, %Cmd%, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
WinGetActiveTitle() {
	WinGetActiveTitle, v
	Return, v
}
WinGetClass(WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	WinGetClass, v, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
WinGetText(WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	WinGetText, v, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
WinGetTitle(WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
	WinGetTitle, v, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
	Return, v
}
