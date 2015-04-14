;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Renames FreePPs pdf files; then generates html for use with the normal FreePPs process.



;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
StartUp()
Version_Name = v2.4.1

;Dependencies
#Include %A_ScriptDir%\Functions
#Include inireadwrite
#Include sort_arrays
#Include json_obj
#Include util_misc

;For Debug Only
#Include util_arrays

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;;Startup special global variables
Sb_GlobalNameSpace()
Sb_InstallFiles()

;;Load the config file and check that it loaded completely
settings = %A_ScriptDir%\Data\config.ini
Fn_InitializeIni(settings)
Fn_LoadIni(settings)
	If (Ini_Loaded != 1)
	{
	Msgbox, Citizen! There was a problem reading the config.ini file. PPS2HTML will quit for your protection. (Copy a working replacement config.ini file to the same directory as PPS2HTML)
	ExitApp
	}

;Just a quick conversion
Options_TVG3PrefixURL := Fn_ReplaceString("{", "[", Options_TVG3PrefixURL)
Options_TVG3PrefixURL := Fn_ReplaceString("}", "]", Options_TVG3PrefixURL)


GUI()
;;Clear the old html.txt ;added some filesize checking for added safety
g_HMTLFile = %A_ScriptDir%\html.txt
	IfExist, %g_HMTLFile%
	{
	FileGetSize, HTMLSize , %g_HMTLFile%, M
		If (HTMLSize <= 2) {
		FileDelete, %g_HMTLFile%
		}
	}

;;Import Existing Track DB File
FileCreateDir, %Options_DBLocation%
FileRead, The_MemoryFile, %Options_DBLocation%\DB.json
AllTracks_Array := Fn_JSONtooOBJ(The_MemoryFile)
The_MemoryFile :=

;For Debugging. Show contents of the Array 
;Array_Gui(AllTracks_Array)

;DEPRECIATED. File will always have a date
	;Get Tomorrows name to be used in HTML
	;g_WeekdayName:= %A_Now%
	;g_WeekdayName+=1, d
	;FormatTime, g_WeekdayName,%g_WeekdayName%, dddd


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; MAIN
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
;; Read each pdf file in the same directory and save it to the Track DB if it matches the expected filename pattern. See Confluence table


;### AUSTRALIA--------------------------------------------
Loop, %A_ScriptDir%\*.pdf {
	;;Is this track Aus? They all have "ppAB" in the filename; EX: DOOppAB0527.pdf
	RegExMatch(A_LoopFileName, "ppAB(\d\d)(\d\d)\.", RE_Aus)
	If (RE_Aus1 != "") {
	The_DateTrack = 20%Options_Year%%RE_Aus1%%RE_Aus2%Australia
	Fn_InsertData("Australia", "Australia", The_DateTrack, A_LoopFileName)
	}
}

;### NEW ZEALAND--------------------------------------------
Loop, %A_ScriptDir%\*.pdf {
	;;Is this track New Zealand? They all have "NZpp" in the filename
	RegExMatch(A_LoopFileName, "NZpp(\d\d)(\d\d)\.", RE_NZ)
	If (RE_NZ1 != "") {
	The_DateTrack = 20%Options_Year%%RE_NZ1%%RE_NZ2%New_Zealand
	
	;; NZ files get exported to txt, so we can read the trackname
	FileCopy, %A_ScriptDir%\Data\PDFtoTEXT, %A_ScriptDir%\Data\PDFtoTEXT.exe
	RunWait, %comspec% /c %A_ScriptDir%\Data\PDFtoTEXT.exe %A_LoopFileFullPath% %A_ScriptDir%\Data\Temp\%A_LoopFileName%.txt,,Hide
	FileDelete, %A_ScriptDir%\Data\PDFtoTEXT.exe
	
	Sleep, 200
	;;Read the Trackname out of the Converted Text, after a short rest
	FileRead, File_PDFTEXT, %A_ScriptDir%\Data\Temp\%A_LoopFileName%.txt
	FileDelete, %A_ScriptDir%\Data\Temp\%A_LoopFileName%.txt
	TrackName := Fn_QuickRegEx(File_PDFTEXT,"New Zealand \(([\w ]+)\)")
		If (TrackName = "null") {
		Msgbox, couldn't extract NZ trackname from file: %A_LoopFileName%. Troubleshoot or process manually.
		Continue
		}
		If (InStr(TrackName,")")) {
		Msgbox, The trackname found contains ")" which would be a problem. Alert PPS2HTML author for improvements required.
		Continue
		}
	TrackName := Fn_ReplaceString(" ", "_", TrackName)
	Fn_InsertData("New_Zealand", TrackName, The_DateTrack, A_LoopFileName)
	}
}

;### JAPAN--------------------------------------------
Loop, %A_ScriptDir%\*.pdf {
	;;Is this track Japan? They all have "Japan" in the filename
	If (InStr(A_LoopFileName, "Japan"))	{
		;Grab the date
		RegExMatch(A_LoopFileName, "(\d{2}).*(\d{2}).*(\d{2})", RE_JP)
		If (RE_JP1 != "") {
		The_DateTrack = 20%RE_JP3%%RE_JP1%%RE_JP2%Japan
		Fn_InsertData("Japan", "Japan", The_DateTrack, A_LoopFileName)
		}
	}
}



;### All Simo Central----------------
Loop, %A_ScriptDir%\*.pdf {
	;;Is this track from Simo Central? They all have "_INTER_IRE." in the filename; EX: 20140526DR(D)_INTER.pdf
	RegExMatch(A_LoopFileName, "(\d\d\d\d)(\d\d)(\d\d)(\D+)\(D\)_INTER", RE_SimoCentralFile)
	;RE_1 is 2014; RE_2 is month; RE_3 is day; RE_4 is track code, usually 2 or 3 letters.
	
	
	If (RE_SimoCentralFile1 != "") {
	;If RegEx was a successful match, Find the Ini_[Key] in config.ini
	TrackTLA := RE_SimoCentralFile4
	Ini_Key := Fn_FindTrackIniKey(TrackTLA)
	
	;Now Trackname will be 'Warwick' in the case of [GB]_WAR. Convert Spaces to Underscores
	TrackName := %Ini_Key%_%TrackTLA%
	TrackName := Fn_ReplaceString(" ", "_", TrackName)
	
	The_DateTrack = %RE_SimoCentralFile1%%RE_SimoCentralFile2%%RE_SimoCentralFile3%%TrackName%
	Fn_InsertData(Ini_Key, TrackName, The_DateTrack, A_LoopFileName)
	
	StringReplace, TrackName, TrackName, %A_SPACE%, _, All
	
		;;If [Key]_TLA has no associated track; tell user and exit
		If (TrackName = "") {
		Msgbox, There was no corresponding track found for %TrackTLA%, please update the config.ini file and run again. `n `n You should have something like this: `n[Key]`n %TrackTLA%=Track Name
		ExitApp
		}
	}
}



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; New HTML Generation
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/


;;Sort all Array Content by DateTrack ; No not do in descending order as this will flip the output. Sat,Fri,Thur instead on Thur,Fri,Sat
Fn_Sort2DArrayFast(AllTracks_Array, "DateTrack")
	LineText = <!--=TVG 3 Drupal=---------------------------------------->
	Fn_InsertText(LineText)
;;Export Each Track type to HTML.txt; also handles renaming files
;;Aus, NZ, and Japan must be handled explicitly because they don't follow SimoCentral rules
Fn_Export("Australia", Options_TVG3PrefixURL)
Fn_Export("New_Zealand", Options_TVG3PrefixURL)
Fn_Export("Japan", Options_TVG3PrefixURL)
	;Loop all others
	Loop, %inisections%
	{
	Fn_Export(section%A_Index%, Options_TVG3PrefixURL)
	}

	

	
	
;; Export all the tracks again in basic HTML format if user specified TVG2HTML = 1 in their config file
	If (Options_TVG2HTML = 1) {
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	LineText = <!--=TVG 2=---------------------------------------->
	Fn_InsertText(LineText)
	Fn_Export("Australia", Options_TVG2PrefixURL)
	Fn_Export("New_Zealand", Options_TVG2PrefixURL)
	Fn_Export("Japan", Options_TVG2PrefixURL)

		Loop, %inisections%
		{
		Fn_Export(section%A_Index%, Options_TVG2PrefixURL)
		}
	}


;Kick Array items over 30 days old out
	LastMonth :=
	LastMonth += -30, d
	StringTrimRight, LastMonth, LastMonth, 6
Loop, 33
{
	Loop % AllTracks_Array.MaxIndex()
	{
	l_DateTrack := AllTracks_Array[A_Index,"DateTrack"]
	;Convert data out of l_DateTrack to get the weekdayname and new format of timestamp
	l_WeekdayName := Fn_GetWeekName(l_DateTrack)
	
	;See if array item is new enough to stay in the array
	FileTimeStamp := Fn_JustGetDate(l_DateTrack)
	;Msgbox, %A_Index% %l_FileTimeStamp% > %l_Today%
		If (FileTimeStamp < LastMonth)
		{
		;Msgbox, %FileTimeStamp% is older than today: %LastMonth%`; removing
		AllTracks_Array.Remove(A_Index)
		Break
		;Must break out because A_Index will no longer corrilate to correct array index
		}
	}
}

;For Debugging. Show contents of the Array 
;Array_Gui(AllTracks_Array)


;Export Array as a JSON file
The_MemoryFile := Fn_JSONfromOBJ(AllTracks_Array)
FileDelete, %Options_DBLocation%\DB.json
FileAppend, %The_MemoryFile%, %Options_DBLocation%\DB.json




















;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Old HTML Generation
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;; Export all the tracks again in NON-DRUPAL format if user specified OldTVG3HTML = 1 in their config file
If (Options_OldTVG3HTML = 1)
{
	;Insert Blank area for separation between TVG3 and TVG2
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	
	;Label TVG3 Section of HTML
	FileAppend,
	(
	<!--=TVG 3=---------------------------------------->
	), %A_ScriptDir%\html.txt
	Fn_InsertBlank(void)
	;Label Australia Section of HTML
	FileAppend,`n      Australia\New Zealand`n, %A_ScriptDir%\html.txt
	Fn_InsertBlank(void)


	;Loop for all Australia pdf files
	Loop, %A_ScriptDir%\*.pdf
	{

		If (InStr(A_LoopFileName, "Australia") || InStr(A_LoopFileName, "New_Zealand")) {
		g_FinalWeekdayName := Fn_GetWeekNameOLD(A_LoopFileName)
		FileAppend,
		(
		<a href="/forms/%A_LoopFileName%" target="_blank">%g_FinalWeekdayName% PPs</a><br />
		
		), %A_ScriptDir%\html.txt
		}

	}


	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	;Label GB/IR Section of HTML
	FileAppend,`n      Simo-Central Files`n, %A_ScriptDir%\html.txt
	Fn_InsertBlank(void)


	;Loop for all SimoCentral pdf files
	Loop, %A_ScriptDir%\*.pdf
	{
	If (InStr(A_LoopFileName, "Australia") || InStr(A_LoopFileName, "New_Zealand")) {
		Continue
		}
	RegExMatch(A_LoopFileName, "(\D+)\d+-li", RE_TrackName)
		If (RE_TrackName != "")	{
		TrackName := RE_TrackName1
		StringReplace, TrackName, TrackName, _, %A_SPACE%, All
		StringReplace, A_LoopFileNameNoSpace, A_LoopFileName, %A_SPACE%, , All
		g_FinalWeekdayName := Fn_GetWeekNameOLD(A_LoopFileName)
	FileAppend,
	(
	<a href="/forms/%A_LoopFileNameNoSpace%" target="_blank">%Trackname%, %g_FinalWeekdayName% PPs</a><br />

	), %A_ScriptDir%\html.txt
		}
	}

	;Add trailing <br>
	FileAppend,
	(
	<br \>
	), %A_ScriptDir%\html.txt
}


;~~~~~~~~~~~~~~~~~~~~~
; TVG2 HTML
;~~~~~~~~~~~~~~~~~~~~~

;; Export all the tracks again in NON-DRUPAL Basic format if user specified OldTVG2HTML = 1 in their config file
If (Options_OldTVG2HTML = 1)
{
	;Insert Blank area for separation between TVG3 and TVG2
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	
	;Label for TVG2
	LineText = <!--=TVG 2=---------------------------------------->
	Fn_InsertText(LineText)
	FileAppend,`n      Australia\New Zealand`n, %A_ScriptDir%\html.txt
	Fn_InsertBlank(void)

	;Loop for all Australia pdf files
	Loop, %A_ScriptDir%\*.pdf {

		If (InStr(A_LoopFileName, "Australia") || InStr(A_LoopFileName, "New_Zealand"))
		{
		g_FinalWeekdayName := Fn_GetWeekNameOLD(A_LoopFileName)
		FileAppend,<a href="https://www.tvg.com/forms/%A_LoopFileName%" target="_blank">%g_FinalWeekdayName% PPs</a><br />`n, %A_ScriptDir%\html.txt
		}
	}


	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	FileAppend,`n      Simo-Central Files`n, %A_ScriptDir%\html.txt
	Fn_InsertBlank(void)


	;Loop for all SimoCentral pdf files
	Loop, %A_ScriptDir%\*.pdf {
		If (InStr(A_LoopFileName, "Australia") || InStr(A_LoopFileName, "New_Zealand")) {
		Continue
		}
		
		
		RegExMatch(A_LoopFileName, "(\D+)\d+-li", RE_TrackName)
		If (RE_TrackName != "")	{
		TrackName := RE_TrackName1
		StringReplace, TrackName, TrackName, _, %A_SPACE%, All
		StringReplace, A_LoopFileNameNoSpace, A_LoopFileName, %A_SPACE%, , All
		g_FinalWeekdayName := Fn_GetWeekNameOLD(A_LoopFileName)
		
		FileAppend,
	(
	<a href="https://www.tvg.com/forms/%A_LoopFileNameNoSpace%" target="_blank">%Trackname%, %g_FinalWeekdayName% PPs</a><br />`n
	), %A_ScriptDir%\html.txt
		}

	;take space out of FileName and put into a new variable so that the html link will match the no space filename

	}
	FileAppend,<br \>, %A_ScriptDir%\html.txt
}
;Add Done Message
Gui, Font, s14 w700, Arial
Gui, Add, Text, x2 y30 w220 h40 cGreen +Center, Done!

;Finished, exit after 40 second nap
Sleep 40000
ExitApp




;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/


;Gets the timestamp out of a filename and converts it into a full day of the week name
Fn_GetWeekName(para_String) ;Example Input: "20140730Scottsville"
{

RegExMatch(para_String, "(\d{4})(\d{2})(\d{2})", RE_TimeStamp)
	If (RE_TimeStamp1 != "") {
	;dddd corresponds to Monday for example
	FormatTime, l_WeekdayName , %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3%, dddd
	}
	If (l_WeekdayName != "") {
	Return l_WeekdayName
	}
	Else {
	;Return a fat error is nothing is found
	Msgbox, ERROR - %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3% - %para_String%
	Return "ERROR"
	}
}


Fn_JustGetDate(para_String)
{
;local
	RegExMatch(para_String, "(\d{4})(\d{2})(\d{2})", RE_TimeStamp)
	If (RE_TimeStamp1 != "")
	{
	l_TimeStamp = %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3%
	Return %l_TimeStamp%
	}
;Else
Return ERROR
}

Fn_GetWeekNameOLD(para_String) ;Example Input: "073014Scottsville"
{

RegExMatch(para_String, "(\d{2})(\d{2})(\d{2})", RE_TimeStamp)
	If (RE_TimeStamp1 != "")
	{
	;dddd corresponds to Monday for example
	FormatTime, l_WeekdayName , 20%RE_TimeStamp3%%RE_TimeStamp1%%RE_TimeStamp2%, dddd
	}
		If (l_WeekdayName != "") 
		{
		Return l_WeekdayName
		}
;Return a fat error if nothing is found
Msgbox, Couldn't understand the date format in %para_String%
Return "ERROR"
}


;Changes a correct Timestamp 20140730 to a bad one! 071314
Fn_GetModifiedDate(para_String) ;Example Input: "20140730Scottsville"
{

RegExMatch(para_String, "20(\d{2})(\d{2})(\d{2})", RE_TimeStamp)
	If (RE_TimeStamp1 != "") {
	l_NewDateFormat = %RE_TimeStamp2%%RE_TimeStamp3%%RE_TimeStamp1%
	Return l_NewDateFormat
	}
	Else
	{
	Msgbox, Couldn't understand the date format of %para_String%. Check for Errors.
	}

}


Fn_FindTrackIniKey(para_TrackCode)
{
global settings

	Loop, Read, %settings%
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


;This function inserts each track to an array that later gets sorted and exported to HTML
Fn_InsertData(para_Key, para_TrackName, para_DateTrack, para_OldFileName) 
{
Global

;Find out how big the array is currently
AllTracks_ArraX := AllTracks_Array.MaxIndex()
l_ExistsAlreadyFlag := 0
	If (AllTracks_ArraX = "")
	{
	;Array is blank, start at 0
	AllTracks_ArraX = 0
	}

	;See if the Track/Date is already present in the array. If yes, do not insert again
	Loop, %AllTracks_ArraX%
	{
		If (para_DateTrack = AllTracks_Array[A_Index,"DateTrack"])
		{
		;Msgbox, %para_DateTrack% exists in this array already
		l_ExistsAlreadyFlag := 1
		}
	}
	
	If (l_ExistsAlreadyFlag = 0)
	{
	;Increment for the next track input
	AllTracks_ArraX += 1	
	;Msgbox, %AllTracks_ArraX%
	;Insert each parameter into the appropriate array key
	AllTracks_Array[AllTracks_ArraX,"Key"] := para_Key
	AllTracks_Array[AllTracks_ArraX,"TrackName"] := para_TrackName
	AllTracks_Array[AllTracks_ArraX,"DateTrack"] := para_DateTrack
	AllTracks_Array[AllTracks_ArraX,"FileName"] := para_OldFileName
	}
}


Fn_Export(para_Key, para_URLLead) {
Global AllTracks_Array
Global FirstGBLoop

l_Today = %A_YYYY%%A_MM%%A_DD%

	;Create HTML Title if any of that kind of track exist
	AllTracks_ArraX = 0
	Loop % AllTracks_Array.MaxIndex()
	{
	l_FileTimeStamp := Fn_JustGetDate(AllTracks_Array[A_Index,"DateTrack"])
		;Only add HTML title if [Key] Tracks are in the array AND are scheduled today or greater
		If (para_key = AllTracks_Array[A_Index,"Key"] && l_FileTimeStamp >= l_Today)
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
		l_Key := AllTracks_Array[A_Index,"Key"]
		l_TrackName := AllTracks_Array[A_Index,"TrackName"]
		l_DateTrack := AllTracks_Array[A_Index,"DateTrack"]
		l_OldFileName := AllTracks_Array[A_Index,"FileName"]
		
		;Convert data out of l_DateTrack to get the weekdayname and new format of timestamp
		l_WeekdayName := Fn_GetWeekName(l_DateTrack)
		l_TimeFormat := Fn_GetModifiedDate(l_DateTrack)
			If (l_Key = "null" || l_TrackName = "null" || l_DateTrack = "null") {
			Msgbox, there was a problem reading the data associated with %l_OldFileName%. Troubleshoot and try again.
			Continue
			}
		;Move file with new name; overwriting if necessary
		l_NewFileName = %l_TrackName%%l_TimeFormat%-li.pdf
		;l_NewFileName := Fn_ReplaceString(" ", "_", l_NewFileName) ;PATIENCE! See further below where HTML is appended
		FileMove, %A_ScriptDir%\%l_OldFileName%, %A_ScriptDir%\%l_NewFileName%, 1
			;If the filemove was unsuccessful for any reason, tell user
			If (Errorlevel) 
			{
			Msgbox, There was a problem renaming the %l_OldFileName% file. Permissions\FileInUse
			}
		
		;See if array item is new enough to be used in HTML
		l_FileTimeStamp := Fn_JustGetDate(l_DateTrack)
			If (l_FileTimeStamp < l_Today)
			{
			;Skip to next item because this is older than today
			Continue
			}
			
		l_TrackName := Fn_ReplaceString("_", " ", l_TrackName)
		l_Key := Fn_ReplaceString("_", " ", l_Key)
		;If the TrackName matches the Key, only output day in the HTML Name (This is for Australia/New Zealand/Japan)
			If (l_TrackName = l_Key) {
			l_CurrentLine = <a href="%para_URLLead%%l_NewFileName%" target="_blank">%l_WeekdayName% PPs</a><br />
			;<a href="[current-domain:forms-url]%l_NewFileName%" target="_blank">%l_WeekdayName% PPs</a><br />
			}
			Else
			{
			l_CurrentLine = <a href="%para_URLLead%%l_NewFileName%" target="_blank">%l_TrackName%, %l_WeekdayName% PPs</a><br />
			;<a href="[current-domain:forms-url]%l_NewFileName%" target="_blank">%l_TrackName%, %l_WeekdayName% PPs</a><br />
			}
			
			;Check for UK/IRE and insert a </ br> if needed between dates
			If (AllTracks_Array[A_Index,"Key"] = "UK#IRE" || AllTracks_Array[A_Index,"Key"] = "New_Zealand")
			{
				If (FirstGBLoop = 1 && AllTracks_Array[A_Index,"Key"] = "UK#IRE")
				{
				LastDate := l_WeekdayName ;My understanding is that this var "LastDate" is local but somehow it is remembered each time. Interesting.
				FirstGBLoop := 0
				}
				If (LastDate != l_WeekdayName && AllTracks_Array[A_Index,"Key"] = "UK#IRE")
				{
				br := "<br />"
				Fn_InsertText(br)
				LastDate := l_WeekdayName
				}
				
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

;This function just inserts a line of text
Fn_InsertText(para_Text) {
FileAppend, %para_Text%`n, %A_ScriptDir%\html.txt
}


;This function inserts a blank line. How worthless 
Fn_InsertBlank(void) {
FileAppend, `n, %A_ScriptDir%\html.txt
}

;/--\--/--\--/--\--/--\--/--\
; GUI
;\--/--\--/--\--/--\--/--\--/
GUI()
{
global
;Title
Gui, Font, s14 w70, Arial
Gui, Add, Text, x2 y4 w220 +Center, PPS2HTML
Gui, Font, s10 w70, Arial
Gui, Add, Text, x168 y0 w50 +Right, %Version_Name%


;User Input
;Gui, Add, Text, x8 y110 w100 h30 +Right, Domain\Account:
;Gui, Add, Edit, x110 y110 w100 h20 vThe_UserINPUT,

;Gui, Add, Text, x8 y135 w100 h30 +Right, Pass:
;Gui, Add, Edit, x110 y135 w100 h20 Password vThe_PassINPUT,

;Gui, Add, Button, x4 y30 w80 h40 gSelect, Select File
;Gui, Add, Button, x84 y30 w130 h40 gRun default, Run


;Large Progress Bar UNUSED
;Gui, Add, Progress, x4 y130 w480 h20 , 100

Gui, Show, h80 w220, PPS2HTML


;Menu
Menu, FileMenu, Add, E&xit`tCtrl+Q, Menu_File-Quit
Menu, MenuBar, Add, &File, :FileMenu  ; Attach the sub-menu that was created above

Menu, HelpMenu, Add, &About, Menu_About
Menu, HelpMenu, Add, &Confluence`tCtrl+H, Menu_Confluence
Menu, MenuBar, Add, &Help, :HelpMenu

Gui, Menu, MenuBar
Return

;Menu Shortcuts
Menu_Confluence:
Run http://confluence.tvg.com/pages/viewpage.action?pageId=11075658
Return

Menu_About:
Msgbox, Renames Free PP files and generated HTML from all files run through the system. `n%Version_Name%
Return

Menu_File-Quit:
ExitApp
}


;/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/

;Create Directory and install needed file(s)
Sb_InstallFiles()
{
FileCreateDir, %A_ScriptDir%\Data\
FileCreateDir, %A_ScriptDir%\Data\Temp\
FileInstall, Data\PDFtoTEXT, %A_ScriptDir%\Data\PDFtoTEXT, 1
}

;No Tray icon because it takes 2 seconds; Do not allow running more then one instance at a time
StartUp() {
#NoTrayIcon
#SingleInstance force
}

Sb_GlobalNameSpace() {
global

Path_PDFtoHTML = %A_ScriptDir%\Data\
AllTracks_Array := {Key:"", TrackName:"", DateTrack:"", FileName:""}
AllTracks_ArraX = 1
FirstGBLoop = 1
}