;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Renames FreePPs pdf files; then generates html for use with the normal FreePPs process.



;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
StartUp()
Version = Pre v2.0

;Dependencies
#Include %A_ScriptDir%\Functions
#Include inireadwrite
#Include sort_arrays

#Include util_arrays

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Startup special global variables
Sb_GlobalNameSpace()


;Clear the old html.txt ;added some filesize checking for added safety
g_HMTLFile = %A_ScriptDir%\html.txt
	IfExist, %g_HMTLFile%
	{
	FileGetSize, HTMLSize , %g_HMTLFile%, M
		If (HTMLSize <= 2) {
		FileDelete, %g_HMTLFile%
		}
	
	}


;Load the config file and check that it loaded the last line
settings = %A_ScriptDir%\config.ini
Fn_InitializeIni(settings)
Fn_LoadIni(settings)
	If (Ini_Loaded != 1)
	{
	Msgbox, Citizen! There was a problem reading the config.ini file. PPS2HTML will quit for your protection. (Copy a working replacement config.ini file to the same directory as PPS2HTML)
	ExitApp
	}

;DEPRECIATED. File will always have a date
	;Get Tomorrows name to be used in HTML
	;g_WeekdayName:= %A_Now%
	;g_WeekdayName+=1, d
	;FormatTime, g_WeekdayName,%g_WeekdayName%, dddd


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; File Renaming
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/



;### AUSTRALIA--------------------------------------------
Loop, %A_ScriptDir%\*.pdf {
	;Is this track Aus? They all have "ppAB" in the name; EX: DOOppAB0527.pdf
	regexmatch(A_LoopFileName, "ppAB(\d\d)(\d\d)\.", RE_Aus)
	If (RE_Aus1 != "") {
	The_DateTrack = 20%Options_Year%%RE_Aus1%%RE_Aus2%Australia
	Fn_InsertData("Australia", "Australia", The_DateTrack, A_LoopFileName)
	}
}

;### NEW ZEALAND--------------------------------------------
Loop, %A_ScriptDir%\*.pdf {
	;Is this track New Zealand? They all have "NZpp" in the name
	regexmatch(A_LoopFileName, "NZpp(\d\d)(\d\d)\.", RE_NZ)
	If (RE_NZ1 != "") {
	The_DateTrack = 20%Options_Year%%RE_NZ1%%RE_NZ2%New_Zealand
	Fn_InsertData("New_Zealand", "New_Zealand", The_DateTrack, A_LoopFileName)
	}
}



;### All Simo Central Renaming----------------
Loop, %A_ScriptDir%\*.pdf {
	;Is this track from Simo Central? They all have "_INTER_IRE." in the name; EX: 20140526DR(D)_INTER.pdf
	regexmatch(A_LoopFileName, "(\d\d\d\d)(\d\d)(\d\d)(\D+)\(D\)_INTER", RE_SimoCentralFile)
	;RE_1 is 2014; RE_2 is month; RE_3 is day; RE_4 is track code, usually 2 or 3 letters.
	
	
	If (RE_SimoCentralFile1 != "") {
	;If RegEx was a successful match, Find the Ini_[Key] in config.ini
	TrackTLA := RE_SimoCentralFile4
	Ini_Key := Fn_FindTrackIniKey(TrackTLA)
	
	;Now Trackname will be 'Warwick' in the case of [GB]_WAR
	TrackName := %Ini_Key%_%TrackTLA%
	The_DateTrack = %RE_SimoCentralFile1%%RE_SimoCentralFile2%%RE_SimoCentralFile3%%TrackName%
	Fn_InsertData(Ini_Key, TrackName, The_DateTrack, A_LoopFileName)
	
	StringReplace, TrackName, TrackName, %A_SPACE%, _, All
	
		;If [Key]_TLA has no associated track; tell user and exit
		If (TrackName = "") {
		Msgbox, There was no corresponding track found for %TrackTLA%, please update the config.ini file and run again. `n `n You should have something like this: `n[Key]`n %TrackTLA%=Track Name
		ExitApp
		}
		
	}
	
}



;Ask user to confirm weekday name
;InputBox, g_WeekdayName , Weekday name, %A_Tab%%A_Space%%A_Space%%A_Space%%A_Space%%A_Space% %Version%, , 180, 120, X, Y, , , %g_WeekdayName%



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; New HTML Generation
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/


;Sort all Array Content by DateTrack
Fn_Sort2DArrayFast(AllTracks_Array, "DateTrack")

;Export Each Track type to HTML.txt; also handles renaming files
Fn_Export("Australia")
Fn_Export("New_Zealand")
Fn_Export("GB#IRE")
Fn_Export("South_Africa")


;For Debugging. Show contents of the Array 
;Array_Gui(AllTracks_Array)









ExitApp






;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Old HTML Generation
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/




;~~~~~~~~~~~~~~~~~~~~~
; TVG3 HTML
;~~~~~~~~~~~~~~~~~~~~~
;Label TVG3 Section of HTML
FileAppend,
(
-=TVG 3=---------------------
), %A_ScriptDir%\html.txt
Fn_InsertBlank(void)
;Label Australia Section of HTML
FileAppend,`n      Australia`n, %A_ScriptDir%\html.txt
Fn_InsertBlank(void)


;Loop for all Australia pdf files
Loop, %A_ScriptDir%\*.pdf
{

	If (InStr(A_LoopFileName, "Australia") || InStr(A_LoopFileName, "NewZealand")) {
	g_FinalWeekdayName := Fn_GetWeekName(A_LoopFileName)
	FileAppend,
	(
	<a href="[current-domain:forms-url]%A_LoopFileName%" target="_blank">%g_FinalWeekdayName% PPs</a><br />
	
	), %A_ScriptDir%\html.txt
	}

}


Fn_InsertBlank(void)
Fn_InsertBlank(void)
;Label GB/IR Section of HTML
FileAppend,`n      Great Britain\Ireland`n, %A_ScriptDir%\html.txt
Fn_InsertBlank(void)


;Loop for all GB/IR pdf files
Loop, %A_ScriptDir%\*.pdf
{
If (InStr(A_LoopFileName, "Australia") || InStr(A_LoopFileName, "NewZealand")) {
	Continue
	}
regexmatch(A_LoopFileName, "(\D+)\d+-li", RE_TrackName)
	If (RE_TrackName != "")	{
	TrackName := RE_TrackName1
	StringReplace, TrackName, TrackName, _, %A_SPACE%, All
	StringReplace, A_LoopFileNameNoSpace, A_LoopFileName, %A_SPACE%, , All
	g_FinalWeekdayName := Fn_GetWeekName(A_LoopFileName)
FileAppend,
(
<a href="[current-domain:forms-url]%A_LoopFileNameNoSpace%" target="_blank">%Trackname%, %g_FinalWeekdayName% PPs</a><br />

), %A_ScriptDir%\html.txt
	}
}

;Add trailing <br>
FileAppend,
(
<br \>
), %A_ScriptDir%\html.txt


;Insert Blank area for separation between TVG3 and TVG2
Fn_InsertBlank(void)
Fn_InsertBlank(void)
Fn_InsertBlank(void)
Fn_InsertBlank(void)
Fn_InsertBlank(void)
Fn_InsertBlank(void)
Fn_InsertBlank(void)


;~~~~~~~~~~~~~~~~~~~~~
; TVG2 HTML
;~~~~~~~~~~~~~~~~~~~~~
;Label for TVG2
LineText = -=TVG 2=---------------------
Fn_InsertText(LineText)
FileAppend,`n      Australia`n, %A_ScriptDir%\html.txt
Fn_InsertBlank(void)

;Loop for all Australia pdf files
Loop, %A_ScriptDir%\*.pdf {

	If (InStr(A_LoopFileName, "Australia") || InStr(A_LoopFileName, "NewZealand"))
	{
	g_FinalWeekdayName := Fn_GetWeekName(A_LoopFileName)
	FileAppend,<a href="https://www.tvg.com/forms/%A_LoopFileName%" target="_blank">%g_FinalWeekdayName% PPs</a><br />`n, %A_ScriptDir%\html.txt
	}
}


Fn_InsertBlank(void)
Fn_InsertBlank(void)
FileAppend,`n      Great Britain\Ireland`n, %A_ScriptDir%\html.txt
Fn_InsertBlank(void)


;Loop for all GB/IR pdf files
Loop, %A_ScriptDir%\*.pdf {
	If (InStr(A_LoopFileName, "Australia") || InStr(A_LoopFileName, "NewZealand")) {
	Continue
	}
	
	
	regexmatch(A_LoopFileName, "(\D+)\d+-li", RE_TrackName)
	If (RE_TrackName != "")	{
	TrackName := RE_TrackName1
	StringReplace, TrackName, TrackName, _, %A_SPACE%, All
	StringReplace, A_LoopFileNameNoSpace, A_LoopFileName, %A_SPACE%, , All
	g_FinalWeekdayName := Fn_GetWeekName(A_LoopFileName)
	
	FileAppend,
(
<a href="https://www.tvg.com/forms/%A_LoopFileNameNoSpace%" target="_blank">%Trackname%, %g_FinalWeekdayName% PPs</a><br />`n
), %A_ScriptDir%\html.txt
	}

;take space out of FileName and put into a new variable so that the html link will match the no space filename

}

FileAppend,<br \>, %A_ScriptDir%\html.txt



;Ok we have everything done, just need to remove all spaces from all pdf filenames; spaces should not exist anyway at this point.
Loop, %A_ScriptDir%\*.pdf {
StringReplace, A_LoopFileNameNoSpace, A_LoopFileName, %A_SPACE%, , All
FileMove, %A_ScriptDir%\%A_LoopFileName%, %A_ScriptDir%\%A_LoopFileNameNoSpace%, 1
	If (Errorlevel)	{
	Msgbox, There was a problem removing spaces from the %A_LoopFileName% file. Permissions\Duplicate\Unknown
	}
}

;Finished, exit
ExitApp




;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/


;Gets the timestamp out of a filename and converts it into a full day of the week name
Fn_GetWeekName(para_String) ;Example Input: "20140730Scottsville"
{

regexmatch(para_String, "(\d{4})(\d{2})(\d{2})", RE_TimeStamp)
	If (RE_TimeStamp1 != "") {
	;dddd corresponds to Monday for example
	FormatTime, l_WeekdayName , %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3%, dddd
	}
	If (l_WeekdayName != "") {
	Return l_WeekdayName
	} 
	Else {
	;Return a fat error is nothing is found
	MSgbox, ERROR - %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3% - %para_String%
	Return "ERROR"
	}
}


;Changes a correct Timestamp 20140730 to a bad one! 071314
Fn_GetModifiedDate(para_String) ;Example Input: "20140730Scottsville"
{

regexmatch(para_String, "20(\d{2})(\d{2})(\d{2})", RE_TimeStamp)
	If (RE_TimeStamp1 != "") {
	l_NewDateFormat = %RE_TimeStamp2%%RE_TimeStamp3%%RE_TimeStamp1%
	Return l_NewDateFormat
	}
	Else
	{
	Msgbox, %para_String%
	}

}


Fn_FindTrackIniKey(para_TrackCode)
{
	Loop, Read, %A_ScriptDir%\config.ini 
	{
		;Remember the INI key value for each section until a match has been found
		IfInString, A_LoopReadLine, ]
		{
		l_CurrentIniKey = %A_LoopReadLine%
		}
		
		;Cut each track line into a psudo array and see if it matches the parameter track code
		StringSplit, ConfigArray, A_LoopReadLine, =,
		If (ConfigArray1 = para_TrackCode) {
		;Match found, remove brackets from current ini key and send back out of function
		StringReplace, l_CurrentIniKey, l_CurrentIniKey, [,,
		StringReplace, l_CurrentIniKey, l_CurrentIniKey, ],,
		Return %l_CurrentIniKey%
		}
	}
}


Fn_InsertData(para_Key, para_TrackName, para_DateTrack, para_OldFileName) 
{
Global

;AllTracks_ArraX := AllTracks_Array.MaxIndex()
;Msgbox, MAX  IS %X% ; FYI Max will never be blank because it is not created empty
	If (AllTracks_ArraX = "")
	{
	;Array is blank
	AllTracks_ArraX = 1
	}
;AllTracks_Array.Insert(1, para_key, para_TrackName, para_FileName)
;Msgbox, ------%AllTracks_ArraX% - %para_key%
AllTracks_Array[AllTracks_ArraX,"Key"] := para_Key
AllTracks_Array[AllTracks_ArraX,"TrackName"] := para_TrackName
AllTracks_Array[AllTracks_ArraX,"DateTrack"] := para_DateTrack
AllTracks_Array[AllTracks_ArraX,"FileName"] := para_OldFileName
;Msgbox % AllTracks_Array[AllTracks_ArraX,"Key"]
AllTracks_ArraX += 1
}


Fn_Export(para_Key) {
Global AllTracks_Array

	;Create HTML Title if any of that kind of track exist
	AllTracks_ArraX = 0
	Loop % AllTracks_Array.MaxIndex()
	{
		If (para_key = AllTracks_Array[A_Index,"Key"] )
		{
		AllTracks_ArraX += 1
		}
	}
	If ( AllTracks_ArraX >= 1)
	{
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_HTMLTitle(para_Key)
	}


	;Read each track in the array and write to HTML if it matches the current key (GB/IR, Australia, etc)
	Loop % AllTracks_Array.MaxIndex()
	{
		If (para_key = AllTracks_Array[A_Index,"Key"] )
		{
		l_key := AllTracks_Array[A_Index,"Key"]
		l_TrackName := AllTracks_Array[A_Index,"TrackName"]
		l_DateTrack := AllTracks_Array[A_Index,"DateTrack"]
		l_OldFileName := AllTracks_Array[A_Index,"FileName"]
		
		;Convert data out of l_DateTrack to get the weekdayname and new format of timestamp
		l_WeekdayName := Fn_GetWeekName(l_DateTrack)
		l_TimeFormat := Fn_GetModifiedDate(l_DateTrack)
		
		;Move file with new name; overwriting if necessary
		l_NewFileName = %l_TrackName%%l_TimeFormat%-li.pdf
		FileMove, %A_ScriptDir%\%l_OldFileName%, %A_ScriptDir%\%l_NewFileName%, 1
			;If the filemove was unsuccessful for any reason, tell user
			If (Errorlevel) 
			{
			Msgbox, There was a problem renaming the %l_OldFileName% file. Permissions\FileInUse
			}
			
		
		l_TrackName := Fn_ReplaceString("_", " ", l_TrackName)
			If (InStr(l_TrackName, "Australia") || InStr(l_TrackName, "New Zealand")) {
			l_CurrentLine = <a href="[current-domain:forms-url]%l_NewFileName%" target="_blank">%l_WeekdayName% PPs</a><br />
			}
			Else
			{
			l_CurrentLine = <a href="[current-domain:forms-url]%l_NewFileName%" target="_blank">%l_TrackName%, %l_WeekdayName% PPs</a><br />
			}
		Fn_InsertText(l_CurrentLine)
		

			
		}
	
	}
	
	If ( AllTracks_ArraX >= 1)
	{
	l_CurrentLine = <br />
	Fn_InsertText(l_CurrentLine)
	}
}


Fn_HTMLTitle(para_Text) {
para_Text := Fn_ReplaceString("#", "/", para_Text)
para_Text := Fn_ReplaceString("_", " ", para_Text)
l_CurrentLine = <span style="color: #0c9256;"><strong>%para_Text%</strong></span><br />
Fn_InsertText(l_CurrentLine)
	If (InStr(para_Text, "GB"))
	{
	l_CurrentLine = <a href="http://www.timeform.com/free/" target="_blank">TIMEFORM</a><br />
	Fn_InsertText(l_CurrentLine)
	}
}


Fn_ReplaceString(para_1,para_2,para_String) {
StringReplace, l_Newstring, para_String, %para_1%, %para_2%, All
Return l_Newstring
}

;This function just inserts a line of text
Fn_InsertText(para_Text) {
FileAppend, %para_Text%`n, %A_ScriptDir%\html.txt
}


;This function inserts a blank line. How worthless 
Fn_InsertBlank(void) {
FileAppend, `n, %A_ScriptDir%\html.txt
}


;/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/

;No Tray icon because it takes 2 seconds; Do not allow running more then one instance at a time
StartUp() {
#NoTrayIcon
#SingleInstance force
}

Sb_GlobalNameSpace() {
global

AllTracks_Array := {Key:"", TrackName:"", DateTrack:"", FileName:""}
AllTracks_ArraX = 1
}