;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Renames FreePPs pdf files; then generates html for use with the normal FreePPs process.



;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
;SetBatchLines -1 ;Go as fast as CPU will allow
StartUp()
Version_Name = v2.6.0

;Dependencies
#Include %A_ScriptDir%\Functions
#Include inireadwrite.ahk
#Include sort_arrays.ahk
#Include json.ahk
#Include util_misc.ahk

;For Debug Only
#Include util_arrays.ahk

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
If (Ini_Loaded != 1) {
	Msgbox, There was a problem reading the config.ini file. PPS2HTML will quit. (Copy a working replacement config.ini file to the same directory as PPS2HTML)
	ExitApp
}

;Just a quick conversion
Options_TVG3PrefixURL := Fn_ReplaceString("{", "[", Options_TVG3PrefixURL)
Options_TVG3PrefixURL := Fn_ReplaceString("}", "]", Options_TVG3PrefixURL)


GUI()
;;Clear the old html file ;added some filesize checking for added safety
The_HMTLFile = %A_ScriptDir%\html.txt
IfExist, %The_HMTLFile%
{
	FileGetSize, HTMLSize , %The_HMTLFile%, M
	If (HTMLSize <= 2) {
	FileDelete, %The_HMTLFile%
	}
}

;;Import Existing Track DB File
FileCreateDir, %Options_DBLocation%
FileRead, The_MemoryFile, %Options_DBLocation%\DB.json
AllTracks_Array := JSON.parse(The_MemoryFile)
The_MemoryFile :=


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; MAIN
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
;; Read each pdf file in the same directory and save it to the Track DB if it matches the expected filename pattern. See Confluence table


;;Loop all pdfs
Loop, %A_ScriptDir%\*.pdf {

	;### All Simo Central----------------
	;;Is this track from Simo Central? They all have "_INTER" in the filename; EX: 20140526DR(D)_INTER.pdf
	If (Fn_QuickRegEx(A_LoopFileName,"(_INTER)") != "null") {
		RegExMatch(A_LoopFileName, "(\d{4})(\d{2})(\d{2})(\D{2,})\(D\)_INTER", RE_SimoCentralFile)
		;RE_1 is 2014; RE_2 is month; RE_3 is day; RE_4 is track code, usually 2 or 3 letters.
		
		
		If (RE_SimoCentralFile1 != "") {
		;If RegEx was a successful match, Find the Ini_[Key] in config.ini
		TrackTLA := RE_SimoCentralFile4
		Ini_Key := Fn_FindTrackIniKey(TrackTLA)
		
		;Now Trackname will be 'Warwick' in the case of [GB]_WAR. Convert Spaces to Underscores
		TrackName := %Ini_Key%_%TrackTLA%
		TrackName := Fn_ReplaceString(" ", "_", TrackName)
		
		The_Date = %RE_SimoCentralFile1%%RE_SimoCentralFile2%%RE_SimoCentralFile3%
		Fn_InsertData(Ini_Key, TrackName, The_Date, A_LoopFileName)
		StringReplace, TrackName, TrackName, %A_SPACE%, _, All
			;;If [Key]_TLA has no associated track; tell user and exit
			If (TrackName = "") {
				Msgbox, There was no corresponding track found for %TrackTLA%, please update the config.ini file and run again. `n `n You should have something like this: `n[Key]`n %TrackTLA%=Track Name
				ExitApp
			}
		}
		Continue
	}

	;### Attempt All Sky Racing--------------------------------------------
	;;Is this track from sky racing? They all have "pp" in the filename
	If (Fn_QuickRegEx(A_LoopFileName,"(\w{2,})pp\w{0,3}(\d{4})",2) != "null") {
		RegExMatch(A_LoopFileName, "(\d\d)(\d\d)\.", RE_match)
		If (RE_match1 != "") {
			FileCopy, %A_ScriptDir%\Data\PDFtoTEXT, %A_ScriptDir%\Data\PDFtoTEXT.exe
			RunWait, %comspec% /c %A_ScriptDir%\Data\PDFtoTEXT.exe %A_LoopFileFullPath% %A_ScriptDir%\Data\Temp\%A_LoopFileName%.txt,,Hide
			
			Sleep, 200
			;;Read the Trackname out of the converted text
			FileRead, File_PDFTEXT, %A_ScriptDir%\Data\Temp\%A_LoopFileName%.txt
			FileDelete, %A_ScriptDir%\Data\Temp\%A_LoopFileName%.txt
			Country := Fn_QuickRegEx(File_PDFTEXT,"([A-Za-z ]{6,})\s+\(([A-Z][\w- ]+)\)")
			TrackName := Fn_QuickRegEx(File_PDFTEXT,"([A-Za-z ]{6,})\s+\(([A-Z][\w- ]+)\)",2)
			If (Country = "null") {
				Msgbox, couldn't extract Region from file: %A_LoopFileName%. Troubleshoot or process manually.
				Continue
			}
			If (TrackName = "null") {
				Msgbox, couldn't extract trackname from file: %A_LoopFileName%. Troubleshoot or process manually.
				Continue
			}
			If InStr(TrackName,")") {
				Msgbox, The trackname found contains ")" which would be a problem. Alert PPS2HTML author for improvements required.
				Continue
			}
			If InStr(Country,"Australia") { 
				TrackName := Country
			}
			;Country := Fn_ReplaceString(" ", "_", Country) ;;CHECK INTO THIS
			TrackName := Fn_ReplaceString(" ", "_", TrackName)
			The_Date = %tomorrowsyear%%RE_match1%%RE_match2%
			Fn_InsertData(Country, TrackName, The_Date, A_LoopFileName)
			Continue
		}
	}


	;### JAPAN--------------------------------------------
	;;Is this track Japan? They all have "Japan" in the filename
	If (InStr(A_LoopFileName, "Japan"))	{
		;Grab the date
		RegExMatch(A_LoopFileName, "(\d{2}).*(\d{2}).*(\d{2})", RE_JP)
		If (RE_JP1 != "") {
			The_Date = 20%RE_JP3%%RE_JP1%%RE_JP2%
			Fn_InsertData("Japan", "Japan", The_Date, A_LoopFileName)
			Continue
		}
	}
}



;Sort all Array Content by DateTrack ; No not do in descending order as this will flip the output. Sat,Fri,Thur
;Fn_Sort2DArrayFast(AllTracks_Array, "DateTrack")
Fn_Sort2DArray(AllTracks_Array,"Key")
Fn_Sort2DArray(AllTracks_Array,"DateTrack")


;;Actually move and rename files now
Sb_RenameFiles()


;;Generate HTML and JSON outputs as specified by user
;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Upload JSON Generation
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
FormatTime, Today, , yyyyMMdd
FileDelete, %A_ScriptDir%\%Options_AdminConsoleFileName%
Data_json := []
loop, % AllTracks_Array.MaxIndex() {
	;msgbox, % AllTracks_Array[A_Index,"Date"] " vs " Today
	If (AllTracks_Array[A_Index,"Date"] >= Today && !InStr(AllTracks_Array[A_Index,"DateTrack"],"null")) {
		thistrack := {}
		thistrack.name := AllTracks_Array[A_Index,"TrackName"]
		thistrack.filename := AllTracks_Array[A_Index,"FinalFilename"]
		thistrack.date := AllTracks_Array[A_Index,"Date"]
		thistrack.group := AllTracks_Array[A_Index,"Key"]
		;replace some yesteryear placeholder characters
		thistrack.group := StrReplace(thistrack.group, "#" , "/")
		thistrack.group := StrReplace(thistrack.group, "_" , " ")
		;AllTracks_Array[AllTracks_ArraX,"Key"]
		Data_json.push(thistrack)
	}
}

If (Options_ExportAdminConsole = 1) {
	FileAppend, % JSON.stringify(Data_json), %A_ScriptDir%\%Options_AdminConsoleFileName%
}


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; New HTML Generation
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
If (Options_ExportDrupalHTML = 1) {
	LineText = <!--=TVG Drupal=---------------------------------------->
	Fn_InsertText(LineText)
	;;Export Each Track type to HTML; also handles renaming files
	;;Aus, NZ, and Japan must be handled explicitly because they don't follow SimoCentral rules
	Fn_Export("Australia", Options_TVG3PrefixURL)
	Fn_Export("New_Zealand", Options_TVG3PrefixURL)
	Fn_Export("South Korea", Options_TVG3PrefixURL)
	Fn_Export("Japan", Options_TVG3PrefixURL)
	;Loop all others
	Loop, %inisections%
	{
		Fn_Export(section%A_Index%, Options_TVG3PrefixURL)
	}
}
	
	



;Kick Array items over 30 days old out
Fn_RemoveDatedKeysInArray("DateTrack", AllTracks_Array)


;For Debugging. Show contents of the Array 
;Array_Gui(AllTracks_Array)

;Export Array as a JSON file
The_MemoryFile := JSON.stringify(AllTracks_Array)
FileDelete, %Options_DBLocation%\DB.json
FileAppend, %The_MemoryFile%, %Options_DBLocation%\DB.json












;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Super old Basic site formatting
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
If (Options_ExportOldTVG2HTML = 1) {
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	LineText = <!--=TVG 2=---------------------------------------->
	Fn_InsertText(LineText)
	Fn_Export("Australia", Options_TVG2PrefixURL)
	Fn_Export("New_Zealand", Options_TVG2PrefixURL)
	Fn_Export("Japan", Options_TVG2PrefixURL)
	;SimoCentral files
	Loop, %inisections%
	{
		Fn_Export(section%A_Index%, Options_TVG2PrefixURL)
	}
}

;~~~~~~~~~~~~~~~~~~~~~
; TVG2 HTML
;~~~~~~~~~~~~~~~~~~~~~
;; Export all the tracks again in NON-DRUPAL Basic format if user specified OldTVG2HTML = 1 in their config file
If (Options_ExportOldTVG2HTML = 1)
{
	;Insert Blank area for separation between TVG3 and TVG2
	Loop, 6
	{
		Fn_InsertBlank(void)
	}
	
	;Label for TVG2
	LineText = <!--=TVG 2=---------------------------------------->
	Fn_InsertText(LineText)
	FileAppend,`n      Australia\New Zealand`n, % The_HMTLFile
	Fn_InsertBlank(void)

	;Loop for all Australia pdf files
	Loop, %A_ScriptDir%\*.pdf {

		If (InStr(A_LoopFileName, "Australia") || InStr(A_LoopFileName, "New_Zealand"))
		{
		g_FinalWeekdayName := Fn_GetWeekNameOLD(A_LoopFileName)
		FileAppend,<a href="https://www.tvg.com/forms/%A_LoopFileName%" target="_blank">%g_FinalWeekdayName% PPs</a><br />`n, % The_HMTLFile
		}
	}


	Fn_InsertBlank(void)
	Fn_InsertBlank(void)
	FileAppend,`n      Simo-Central Files`n, % The_HMTLFile
	Fn_InsertBlank(void)


	;Loop for all SimoCentral pdf files
	Loop, %A_ScriptDir%\*.pdf {
		If (InStr(A_LoopFileName, "Australia") || InStr(A_LoopFileName, "New_Zealand")) {
			Continue
		}
		
		RegExMatch(A_LoopFileName, "(\D+)\d+[-li]*", RE_TrackName) ; -li optional
		If (RE_TrackName != "")	{
		TrackName := RE_TrackName1
		StringReplace, TrackName, TrackName, _, %A_SPACE%, All
		StringReplace, A_LoopFileNameNoSpace, A_LoopFileName, %A_SPACE%, , All
		g_FinalWeekdayName := Fn_GetWeekNameOLD(A_LoopFileName)
		
		FileAppend,
	(
	<a href="https://www.tvg.com/forms/%A_LoopFileNameNoSpace%" target="_blank">%Trackname%, %g_FinalWeekdayName% PPs</a><br />`n
	), % The_HMTLFile
		}

	;take space out of FileName and put into a new variable so that the html link will match the no space filename

	}
	FileAppend,<br \>, % The_HMTLFile
}
;Add Done Message
Gui, Font, s14 w700, Arial
Gui, Add, Text, x2 y30 w220 h40 cGreen +Center, Done!

;Finished, exit after 40 second nap
Sleep 40000
ExitApp




;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Sb_RenameFiles()
{
Global

	;Read each track in the array and write to HTML if it matches the current key (GB/IR, Australia, etc)
	Loop % AllTracks_Array.MaxIndex()
	{
		l_OldFileName := AllTracks_Array[A_Index,"FileName"]
		l_NewFileName := AllTracks_Array[A_Index,"FinalFilename"]

		IfNotExist, %A_ScriptDir%\%l_OldFileName%
		{
			Continue
		}
		If (!InStr(l_OldFileName,".pdf")) {
			Continue
		}
		;Msgbox, moving %l_OldFileName% to %l_NewFileName%
		FileMove, %A_ScriptDir%\%l_OldFileName%, %A_ScriptDir%\%l_NewFileName%, 1
		;If the filemove was unsuccessful for any reason, tell user
		If (Errorlevel) {
			Msgbox, There was a problem renaming the %l_OldFileName% file. Permissions\FileInUse
		}
	}
}



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
	} Else {
		;Return a fat error is nothing is found
		Msgbox, ERROR - %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3% - %para_String%
		Return "ERROR"
	}
}

Fn_RemoveDatedKeysInArray(para_Key,para_Array)
{
	LastMonth :=
	LastMonth += -4, d
	StringTrimRight, LastMonth, LastMonth, 6
	Loop, 33
	{
		Loop % para_Array.MaxIndex()
		{
		l_DateTrack := para_Array[A_Index,para_Key]
		;Convert data out of l_DateTrack to get the weekdayname and new format of timestamp
		l_WeekdayName := Fn_GetWeekName(l_DateTrack)
		
		;See if item is new enough to stay in the array
		FileDate := Fn_JustGetDate(l_DateTrack)
			If (FileDate < LastMonth) {
				para_Array.Remove(A_Index)
				Break
				;Must break out because A_Index will no longer corrilate to correct array index
			}
		}
	}
}

Fn_JustGetDate(para_String)
{
;local
	RegExMatch(para_String, "(\d{4})(\d{2})(\d{2})", RE_TimeStamp)
	If (RE_TimeStamp1 != "") {
		l_TimeStamp = %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3%
		Return %l_TimeStamp%
	}
;Else
Return ERROR
}

Fn_GetWeekNameOLD(para_String) ;Example Input: "073014Scottsville"
{
	RegExMatch(para_String, "\d{2}(\d{2})(\d{2})(\d{2})", RE_TimeStamp)
	If (RE_TimeStamp1 != "") {
		;dddd corresponds to Monday for example
		FormatTime, l_WeekdayName , 20%RE_TimeStamp3%%RE_TimeStamp1%%RE_TimeStamp2%, dddd
	}
	If (l_WeekdayName != "") {
		Return l_WeekdayName
	}
	;Return a fat error if nothing is found
	Msgbox, Couldn't understand the date format in %para_String%
	Return "ERROR"
}


;Changes a correct Timestamp 20140730 to a bad one! 071314
Fn_GetModifiedDate(para_String) ;Example Input: "20140730Scottsville"
{
RegExMatch(para_String, "(\d{4})(\d{2})(\d{2})", RE_TimeStamp)
	If (RE_TimeStamp1 != "") {
		l_NewDateFormat = %RE_TimeStamp2%%RE_TimeStamp3%%RE_TimeStamp1%
		Return l_NewDateFormat
	} Else {
		Msgbox, Couldn't understand the date format of %para_String%. Check for Errors.
	}
}


Fn_FindTrackIniKey(para_TrackCode)
{
Global settings

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
Fn_InsertData(para_Key, para_TrackName, para_Date, para_OldFileName) 
{
Global

	;Find out how big the array is currently
	AllTracks_ArraX := AllTracks_Array.MaxIndex()
	If (AllTracks_ArraX = "") {
		;Array is blank, start at 0
		AllTracks_ArraX = 0
	}

	;See if the Track/Date is already present in the array. If yes, do not insert again
	Loop, % AllTracks_Array.MaxIndex()
	{
		If (para_Date . para_TrackName = AllTracks_Array[A_Index,"Date"] . AllTracks_Array[A_Index,"TrackName"]) {
			;Msgbox, %para_TrackName% for %para_Date% already exists in this array
			return
		}
	}

	AllTracks_ArraX += 1
	If(!para_Date || !para_TrackName) {
		return
	}
	AllTracks_Array[AllTracks_ArraX,"Key"] := para_Key
	AllTracks_Array[AllTracks_ArraX,"TrackName"] := para_TrackName
	AllTracks_Array[AllTracks_ArraX,"Date"] := para_Date
	AllTracks_Array[AllTracks_ArraX,"DateTrack"] := para_Date . para_TrackName
	AllTracks_Array[AllTracks_ArraX,"FileName"] := para_OldFileName
	AllTracks_Array[AllTracks_ArraX,"FinalFilename"] := Fn_Filename(para_TrackName, para_Date)
	if (AllTracks_Array[AllTracks_ArraX,"Date"] = "null") {
		Msgbox, % "FATAL ERROR WITH " AllTracks_Array[AllTracks_ArraX,"FinalFilename"] " - " para_DateTrack 
		ExitApp
	}
}



Fn_Export(para_Key, para_URLLead)
{
Global

	l_Today = %A_YYYY%%A_MM%%A_DD%
	;Create HTML Title if any of that kind of track exist
	AllTracks_ArraX = 0
	Loop % AllTracks_Array.MaxIndex()
	{
		l_FileTimeStamp := AllTracks_Array[A_Index,"Date"]
		;Only add HTML title if [Key] Tracks are in the array AND are scheduled today or greater
		If (para_key = AllTracks_Array[A_Index,"Key"] && l_FileTimeStamp >= l_Today) {
			AllTracks_ArraX += 1
		}
	}
	If ( AllTracks_ArraX >= 1) {
		Fn_InsertBlank(void)
		Fn_InsertBlank(void)
		Fn_InsertBlank(void)
		Fn_HTMLTitle(para_Key)
	}


	;Read each track in the array and write to HTML if it matches the current key (GB/IR, Australia, etc)
	Loop % AllTracks_Array.MaxIndex()
	{
		If (para_key = AllTracks_Array[A_Index,"Key"])	{
			l_Key := AllTracks_Array[A_Index,"Key"]
			l_TrackName := AllTracks_Array[A_Index,"TrackName"]
			l_DateTrack := AllTracks_Array[A_Index,"DateTrack"]
			l_OldFileName := AllTracks_Array[A_Index,"FileName"]
			
			;Convert data out of l_DateTrack to get the weekdayname and new format of timestamp
			l_WeekdayName := Fn_GetWeekName(l_DateTrack)
			;Move file with new name; overwriting if necessary
			l_NewFileName := AllTracks_Array[A_Index,"FinalFilename"]
			
			;See if array item is new enough to be used in HTML
			If (AllTracks_Array[A_Index,"Date"] < l_Today) {
				;Skip to next item because this is older than today
				Continue
			}
				
			l_TrackName := Fn_ReplaceString("_", " ", l_TrackName)
			l_Key := Fn_ReplaceString("_", " ", l_Key)
			;If the TrackName matches the Key, only output day in the HTML Name (This is for Australia/New Zealand/Japan)
			If (l_TrackName = l_Key) {
				l_CurrentLine = <a href="%para_URLLead%%l_NewFileName%" target="_blank">%l_WeekdayName% PPs</a><br />
			} Else {
				l_CurrentLine = <a href="%para_URLLead%%l_NewFileName%" target="_blank">%l_TrackName%, %l_WeekdayName% PPs</a><br />
			}
			
			;Check for UK/IRE and insert a </ br> if new weekday is detected
			If (InStr(AllTracks_Array[A_Index,"Key"],"UK")) {
				If (FirstGBLoop = 1 && AllTracks_Array[A_Index,"Key"] = "UK#IRE") {
					LastDate := l_WeekdayName
					FirstGBLoop := 0
				}
				If (LastDate != l_WeekdayName && AllTracks_Array[A_Index,"Key"] = "UK#IRE") {
					Fn_InsertText("<br />")
					LastDate := l_WeekdayName
				}
			}
			Fn_InsertText(l_CurrentLine)
		}
	}
	
	If ( AllTracks_ArraX >= 1) {
		Fn_InsertText("<br />")
	}
}


Fn_HTMLTitle(para_Text)
{
para_Text := Fn_ReplaceString("#", "/", para_Text)
para_Text := Fn_ReplaceString("_", " ", para_Text)
l_CurrentLine = <span style="color: #0c9256;"><strong>%para_Text%</strong></span><br />
Fn_InsertText(l_CurrentLine)
	If (InStr(para_Text, "GB"))	{
		l_CurrentLine = <a href="http://www.timeform.com/free/" target="_blank">TIMEFORM</a><br />
		Fn_InsertText(l_CurrentLine)
	}
}


;This function just inserts a line of text
Fn_InsertText(para_Text) 
{
Global

	FileAppend, %para_Text%`n, % The_HMTLFile
}


;This function inserts a blank line. How worthless 
Fn_InsertBlank(void)
{
Global

	FileAppend, `n, % The_HMTLFile
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
Run https://betfairus.atlassian.net/wiki/spaces/wog/pages/10650365/Ops+Tool+-+PPS2HTML+Automates+Free+Past+Performance+File+Renaming+and+HTML
Return

Menu_About:
Msgbox, Renames Free PP files and generated HTML from all files run through the system. `n%Version_Name%
Return

Menu_File-Quit:
ExitApp

GuiClose:
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
FileInstall, Data\PDFtoTEXT.exe, %A_ScriptDir%\Data\PDFtoTEXT.exe, 1
}

;No Tray icon because it takes 2 seconds; Do not allow running more then one instance at a time
StartUp()
{
#NoTrayIcon
#SingleInstance force
}

Sb_GlobalNameSpace()
{
global

Path_PDFtoHTML = %A_ScriptDir%\Data\
AllTracks_Array := {Key:"", TrackName:"", DateTrack:"", FileName:""}
AllTracks_ArraX = 1
FirstGBLoop = 1


tomorrowsyear := a_now
tomorrowsyear += 1, days
formattime, tomorrowsyear, %tomorrowsyear%, yyyy
}




Fn_Filename(para_trackname,para_date)
{
Global
	If (!Options_suffix) {
		Options_suffix := ""
	}
	;msgbox, % para_trackname . para_date ".pdf"
	return para_trackname . para_date ".pdf"
}
