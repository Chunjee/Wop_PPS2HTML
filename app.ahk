;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Renames FreePPs pdf files; then generates html for use with the normal FreePPs process.



;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
SetBatchLines -1 ;Go as fast as CPU will allow
#NoTrayIcon
#SingleInstance force
The_ProjectName := "PPS2HTML"
The_VersionNumb := "3.4.4"

;Dependencies
#include %A_ScriptDir%\Functions
#include inireadwrite.ahk
#include sort_array.ahk
#include json.ahk
#include util_misc.ahk
#include time.ahk
#include wrappers.ahk

;For Debug Only
#include util_arrays.ahk

;new
#include %A_ScriptDir%\Lib
#include transformStringVars.ahk\export.ahk



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;;Startup special global variables
Sb_GlobalNameSpace()
Sb_InstallFiles()
GUI()



;Check for CommandLineArguments
CL_Args = StrSplit(1 , "|")
if (Fn_InArray(CL_Args,"auto")) {
	AUTOMODE := true
}

;;Load the config file and check that it loaded completely
settings_fileloc := A_ScriptDir "\Data\config.ini"
Fn_InitializeIni(settings_fileloc)
Fn_LoadIni(settings_fileloc)
if (Ini_Loaded != 1) {
	msg("There was a problem reading the config.ini file. " The_ProjectName " will quit. (Copy a working replacement config.ini file to " A_ScriptDir)
	exitapp
}


;Just a quick conversion
Options_TVG3PrefixURL := fn_ReplaceStrings("{", "[", Options_TVG3PrefixURL)
Options_TVG3PrefixURL := fn_ReplaceStrings("}", "]", Options_TVG3PrefixURL)


;;Import Existing Track DB File
FileCreateDir, %Options_DBLocation%
FileRead, The_MemoryFile, %Options_DBLocation%\DB.json
AllTracks_Array := JSON.parse(The_MemoryFile)
if (!AllTracks_Array) {
	AllHorses_Array := []
}

;;Import and parse settings file
FileRead, The_MemoryFile, % A_ScriptDir "\Data\settings.json"
Settings := JSON.parse(The_MemoryFile)
The_MemoryFile := ;blank

; msgbox, % Settings.downloads[1].site
; Goto AutoDownload

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; MAIN
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
;;Loop all pdfs
Parse:

;;Clear the old html file ;added some filesize checking for added safety
The_HMTLFile := A_ScriptDir "\html.txt"
IfExist, %The_HMTLFile%
{
	FileGetSize, HTMLSize , %The_HMTLFile%, M
	if (HTMLSize <= 2) {
		FileDelete, %The_HMTLFile%
	}
}

The_ListofDirs := Settings.dirs
The_ListofDirs.push(A_ScriptDir)

;; New folder processing
if (Settings.parsing) {
	for key, value in Settings.parsing
	{
		;convert string in settings file to a fully qualifed var + string for searching
		searchdir := transformStringVars(value.dir "\*.pdf")
		loop, %searchdir%, R
		{
			if (fn_InArray(AllTracks_Array,A_LoopFileName,"FinalFilename")) { ;; Exit out if the filename is found at all in the finalname array
				continue
			}
			The_TrackName := false
			RegExResult := fn_QuickRegEx(A_LoopFileName,value.filepattern)
			; msgbox, % fn_QuickRegEx(A_LoopFileName,value.filepattern)
			if (RegExResult != false) {
				if (value.prependdate != "") {
					dateSearchText := transformStringVars(value.prependdate) A_LoopFileName
				} else {
					dateSearchText := A_LoopFileName
				}
				The_Date := Fn_DateParser(dateSearchText)
				The_Country := value.association
				;; Pull Trackname from Regex if specified
				if (value.tracknameinfile) {
					The_TrackName := RegExResult
				}


				;; Pull trackname from pdf text if specified
				if (value.pdftracknamepattern != "") {
					text := fn_Parsepdf(A_LoopFileFullPath)
					The_TrackName := fn_QuickRegEx(text, value.pdftracknamepattern)
					if (!The_TrackName) {
						msg("Couldn't find a trackname in '" A_LoopFileName "' with the RegEx '" value.pdftracknamepattern "'")
					}
				}
				;; Pull trackname from ini lookup if specified
				if (value.configkeylookup != "") {
					The_TrackName := fn_iniTrackLookup(value.configkeylookup, RegExResult)
					if (!The_TrackName) {
						msg("Searched config.ini under '" value.configkeylookup "' key for '" RegExResult "' and found nothing. Update the file")
					}
				}
				
				;; Insert data if a trackname and date was verified
				msgbox, % The_TrackName " + " The_Date
				if (The_TrackName && The_Date) {
					; msg("inserting: " The_TrackName "(" A_LoopFileName ")  with the assosiation: " The_Country)
					Fn_InsertData(The_Country, The_TrackName, The_Date, A_LoopFileFullPath, value.brands, value.international)
				} else {
					msg(A_LoopFileName " was not handled by any setting in .\Data\settings.json `n Fix this immediately, renaming files by hand is not advised.")
				}
			}
		}
	}
}


; Old folder processing
; loop, % The_ListofDirs.MaxIndex()
; {
; 	currentsearch := The_ListofDirs[A_Index]
; 	loop, %currentsearch%\*.pdf, R 
; 	{
; 		;; process any file encountered by recursive search:
; 		fn_ProcessFile(A_LoopFileFullPath)
; 	}
; }




;Sort all Array Content by DateTrack ; No not do in descending order as this will flip the output. Sat,Fri,Thur
;Fn_Sort2DArrayFast(AllTracks_Array, "DateTrack")
Fn_Sort2DArray(AllTracks_Array,"DateTrack")
Fn_Sort2DArray(AllTracks_Array,"Key")


FormatTime, Today, , yyyyMMdd
LV_Delete()
; Array_Gui(AllTracks_Array)
LV_Add("","","","","")
loop, % AllTracks_Array.MaxIndex() {
	if (Today <= AllTracks_Array[A_Index,"Date"]) {
		LV_Add("",A_Index,AllTracks_Array[A_Index,"TrackName"],AllTracks_Array[A_Index,"Key"],AllTracks_Array[A_Index,"Date"])
	}
}
LV_ModifyCol()

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; JSON Generation
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
FormatTime, Today, , yyyyMMdd
FileDelete, %A_ScriptDir%\%Options_AdminConsoleFileName%
Data_json := []
loop, % AllTracks_Array.MaxIndex() {
	;msgbox, % AllTracks_Array[A_Index,"Date"] " vs " Today
	if (AllTracks_Array[A_Index,"Date"] >= Today && !InStr(AllTracks_Array[A_Index,"DateTrack"],"null")) {
		thistrack := {}
		thistrack.name := AllTracks_Array[A_Index,"TrackName"]
		thistrack.filename := AllTracks_Array[A_Index,"FinalFilename"]
		thistrack.date := AllTracks_Array[A_Index,"Date"]
		thistrack.group := AllTracks_Array[A_Index,"Key"]
		thistrack.brands := AllTracks_Array[A_Index,"brands"]
		if (AllTracks_Array[A_Index,"International"] = true) {
			thistrack.international := true
		} else {
			thistrack.international := false
		}
		
		;replace some yesteryear placeholder characters
		thistrack.group := StrReplace(thistrack.group, "#" , "/")
		thistrack.group := StrReplace(thistrack.group, "_" , " ")
		;AllTracks_Array[AllTracks_ArraX,"Key"]
		Data_json.push(thistrack)
	}
}

if (Options_ExportAdminConsole = 1) {
	FileAppend, % JSON.stringify(Data_json), %A_ScriptDir%\%Options_AdminConsoleFileName%
}

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; HTML Generation
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
if (Options_ExportDrupalHTML = 1) {
	Fn_InsertText("<!--=TVG Drupal=---------------------------------------->")
	
	Keys := []
	loop, % AllTracks_Array.MaxIndex() {
		x := AllTracks_Array[A_Index,"Key"]
		if (fn_InArray(Keys,x) = false) { ; push new item if missing from the array
			; msgbox, % "pushing " . x
			Keys.push(x)
		}
	}
	Fn_SortArray(Keys)
	;;Export Each Track type to HTML
	loop, % Keys.MaxIndex() {
		Fn_Export(Keys[A_Index], Options_TVG3PrefixURL)
	}


	;;Aus, NZ, and Japan must be handled explicitly because they don't follow SimoCentral rules
	; Fn_Export("Australia", Options_TVG3PrefixURL)
	; Fn_Export("New_Zealand", Options_TVG3PrefixURL)
	; Fn_Export("South Korea", Options_TVG3PrefixURL)
	; Fn_Export("Japan", Options_TVG3PrefixURL)
	; ;Loop all others
	; loop, %inisections%
	; {
	; 	Fn_Export(section%A_Index%, Options_TVG3PrefixURL)
	; }
	; Fn_Export("Other", Options_TVG3PrefixURL)
}
	

;Kick Array items over 30 days old out
Fn_RemoveDatedKeysInArray("DateTrack", AllTracks_Array)


;For Debugging. Show contents of the Array 
;Array_Gui(AllTracks_Array)

;Export Array as a JSON file
The_MemoryFile := JSON.stringify(AllTracks_Array)
FileDelete, %Options_DBLocation%\DB.json
FileAppend, %The_MemoryFile%, %Options_DBLocation%\DB.json

if (AUTOMODE) {
	Sb_RenameFiles()
}
;;ALL DONE
return



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Buttons
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
AutoDownload:
for key in Settings.downloads {
	; msgbox, % A_Index . " " . Array_GUI(Settings.downloads[A_Index])
	Page := Fn_DownloadtoFile(Settings.downloads[A_Index].site)
	for index, line in StrSplit(Page,"`n") {
		; if (fn_QuickRegEx(line,Settings.downloads[A_Index].regex).Count() != 0) {
		; 	msg( fn_QuickRegEx(line,Settings.downloads[A_Index].regex).Count() )
		; }
	}
	; Array_GUI(StrSplit(Page,"`n"))
}
exitapp
return

;/--\--/--\--/--\
; Edit Buttons
;\--/--\--/--\--/
EditDate:
selected := LV_GetNext(1, Focused)
if (selected > 0) { ;if a number
	LV_GetText(INDEX, selected, 1) ;INDEX
	LV_GetText(RowText, selected, 4) ;date
	msgtext := "Please enter a new date in YYYYMMDD format"
	InputBox, UserInput, %msgtext%, %msgtext%, , , , , , , ,%RowText%
	AllTracks_Array[INDEX,"Date"] := UserInput
	Goto, Parse
}
return

EditAssoc:
selected := LV_GetNext(1, Focused)
if (selected > 0) {
	LV_GetText(l_INDEX, selected, 1) ;INDEX
	LV_GetText(RowText, selected, 3) ;assoc
	msgtext := "Please enter a new Association (Australia, UK_IRE, etc)"
	InputBox, UserInput, %msgtext%, %msgtext%, , , , , , , ,%RowText%
	AllTracks_Array[l_INDEX,"Key"] := UserInput
	Goto, Parse
}
return

EditName:
selected := LV_GetNext(1, Focused)
if (selected > 0) {
	LV_GetText(INDEX, selected, 1) ;INDEX
	LV_GetText(RowText, selected, 2) ;TrackName
	msgtext := "Please enter a new Trackname"
	InputBox, UserInput, %msgtext%, %msgtext%, , , , , , , ,%RowText%
	AllTracks_Array[INDEX,"TrackName"] := UserInput
	Goto, Parse
}
return


Delete:
selected := LV_GetNext(1, Focused)
if (selected > 0) {
	LV_GetText(INDEX, selected, 1) ;INDEX
	msg("Deleting: " AllTracks_Array[INDEX,"DateTrack"])
	AllTracks_Array[INDEX,"Date"] := 20100101 ;Will be automatically purged because of old date
	; AllTracks_Array.Remove(INDEX)
	Goto, Parse
}
return

;;Actually move and rename files now
Rename:
Sb_RenameFiles()
return

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

		IfNotExist, %l_OldFileName%
		{
			continue
		}
		if (!InStr(l_OldFileName,".pdf")) {
			continue
		}
		FileCopy, %l_OldFileName%, %A_ScriptDir%\%l_NewFileName%, 1
		; FileMove, %A_ScriptDir%\%l_OldFileName%, %A_ScriptDir%\%l_NewFileName%, 1
		;if the filemove was unsuccessful for any reason, tell user
		if (Errorlevel != 0) {
			msg("There was a problem renaming the " l_OldFileName " file. Permissions\FileInUse")
		} else {
			if (InStr(l_OldFileName, A_ScriptDir)) { ;file is in same dir as exe, delete if move was success
				FileDelete, %l_OldFileName%
			}
		}
		
	}
}



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Large Functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

; fn_ProcessFile(para_FilePath) {
; global

; 	if (Fn_QuickRegEx(para_FilePath,"(_INTER)") != "null") {
; 		RegExMatch(para_FilePath, "(\d{4})(\d{2})(\d{2})(\D{2,})\(D\)_INTER", RE_SimoCentralFile)
; 		;RE_1 is 2014; RE_2 is month; RE_3 is day; RE_4 is track code, usually 2 or 3 letters.
		
; 		if (RE_SimoCentralFile1 != "") {
; 		;if RegEx was a successful match, Find the Ini_[Key] in config.ini
; 		TrackTLA := RE_SimoCentralFile4
; 		Ini_Key := Fn_FindTrackIniKey(TrackTLA)
		
; 		;Now Trackname will be 'Warwick' in the case of [GB]_WAR. Convert Spaces to Underscores
; 		TrackName := %Ini_Key%_%TrackTLA%
; 		The_Date := Fn_DateParser(para_FilePath)
; 			;;if [Key]_TLA has no associated track; tell user and exit
; 			if (TrackName = "") {
; 				msg("There was no corresponding track found for " TrackTLA ", please update the config.ini file and run again. `n `n You should have something like this: `n[Key]`n TrackTLA%=Track Name")
; 				return false
; 			} else {
; 				Fn_InsertData(Ini_Key, TrackName, The_Date, para_FilePath)		
; 				return false
; 			}
; 		}
; 	}

; 	;### Attempt All Sky Racing--------------------------------------------
; 	;;Is this track from sky racing? They all have "pp" in the filename
; 	trackdate := Fn_QuickRegEx(para_FilePath,"(\w{2,4})ppAB(\d{4})",2)
; 	if (trackdate != "null") {
; 		RegExMatch(para_FilePath, "(\d{2})(\d{2})\.", RE_match)
; 		if (RE_match1 != "") {
; 			; command = "%exepath%" "%para_FilePath%" "%txtpath%"
; 			RunWait, "%exepath%" "%para_FilePath%" "%txtpath%",, Hide
; 			Sleep, 200

; 			;;Read the Trackname out of the converted text
; 			FileRead, File_PDFTEXT, %txtpath%
; 			FileDelete, %txtpath%
; 			Country := Fn_QuickRegEx(File_PDFTEXT,"([A-Za-z ]{6,})\s+\(([A-Z][\w- ]+)\)")
; 			TrackName := Fn_QuickRegEx(File_PDFTEXT,"([A-Za-z ]{6,})\s+\(([A-Z][\w- ]+)\)",2)
; 			if (Country = "null") {
; 				clipboard := File_PDFTEXT
; 				msg("Couldn't extract Region from the file: " para_FilePath ". Troubleshoot or process manually.")
; 				return false
; 			}
; 			if (TrackName = "null") {
; 				clipboard := File_PDFTEXT
; 				msg("Couldn't extract trackname from the file: " para_FilePath ". Troubleshoot or process manually.")
; 				return false
; 			}
; 			if ( InStr(TrackName,")") || InStr(TrackName,"(") ) {
; 				clipboard := File_PDFTEXT
; 				msg("The trackname found contains ')' which would be a problem. Alert " The_ProjectName " author for improvements required.")
; 				return false
; 			}
; 			if InStr(Country,"Australia") {
; 				TrackName := Country
; 			}
; 			The_Date = %tomorrowsyear%%RE_match1%%RE_match2%
; 			Fn_InsertData(Country, TrackName, The_Date, para_FilePath)
; 			return true
; 		}
; 	}

; 	;### SWEDEN--------------------------------------------
; 	The_TrackCode := Fn_QuickRegEx(para_FilePath,"\d+_([a-zA-Z\d]+)_+Epp") ;This is catching Sweden Tracks
; 	The_Date := Fn_DateParser(para_FilePath)
; 	Ini_Key := Fn_FindTrackIniKey(The_TrackCode)
; 	TrackName := %Ini_Key%_%The_TrackCode%
; 	if (Ini_Key = "Sweden") {
; 		if (TrackName != "" && The_Date != false) { ;if NOT empty for both
; 			Fn_InsertData("Sweden", TrackName, The_Date, para_FilePath)
; 			return true
; 		}
; 	}

; 	;### FRANCE--------------------------------------------
; 	The_TrackCode := Fn_QuickRegEx(para_FilePath,"([a-zA-Z]{3,4}).*(\d{8})\D*-\${4}-RF11") ;This is catching France Tracks
; 	The_Date := Fn_DateParser(para_FilePath)
; 	Ini_Key := Fn_FindTrackIniKey(The_TrackCode)
; 	TrackName := %Ini_Key%_%The_TrackCode%
; 	if (TrackName != "" && The_Date != false && Ini_Key = "France") { ;if NOT empty for both
; 		Fn_InsertData("France", TrackName, The_Date, para_FilePath)
; 		return true
; 	}

; 	;### JAPAN--------------------------------------------
; 	;;Is this track Japan? They all have "Japan" in the filename
; 	if (InStr(para_FilePath, "Japan"))	{
; 		;Grab the date
; 		The_Date := Fn_DateParser(para_FilePath)
; 		if (RE_JP1 && The_Date != false) {
; 			Fn_InsertData("Japan", "Japan", The_Date, para_FilePath)
; 			return true
; 		}
; 	}

; 	;### Other PDFs ###--------------------------------------------
; 	;;Only handle when specified in config settings
; 	if (Options_HandleExtraFiles = 1) {
; 		;Skip any file already handled
; 		loop, % AllTracks_Array.MaxIndex() {
; 			if (AllTracks_Array[A_Index,"FinalFilename"] = para_FilePath || AllTracks_Array[A_Index,"FileName"] = para_FilePath) { ;new and old file names
; 				return false
; 			}
; 		}
; 		The_Date := Fn_DateParser(para_FilePath)
; 		if (The_Date = false) {
; 			InputBox, The_Date, %The_ProjectName%, % "Enter the racedate for " para_FilePath ": `nPlease format as YYYYMMDD",,,,,,,, % tomorrow_date
; 			The_Date := Fn_DateParser(The_Date)
; 			if (The_Date = false) {
; 				msg("What you entered was not understood. This file will be skipped")
; 				return false
; 			}
; 		}
		
; 		if (fn_DateDifference(The_Date, A_Now,"days") > 30) {
; 			msg(para_FilePath " measured as 30+ days in the future. Check the date and try again.`n`n" para_FilePath "was interpreted as " FormatTime(The_Date, "LongDate"))
; 			return false
; 		}
; 		;InputBox, UserInput_Country, %The_ProjectName%, Group/Country: (Examples- Australia, Melbourne Racing Cup, Other)
; 		InputBox, UserInput_TrackName, %The_ProjectName%, % "Enter a track name for the file: " para_FilePath

; 		KnownInternationalTracks := "BusanSeoulAustraliaZealand"
; 		UserInput_International := 1
; 		if (!InStr(KnownInternationalTracks, UserInput_TrackName)) {
; 			InputBox, UserInput_International, %The_ProjectName%, % "Is this track international?`n`nYes/No"
; 			if (InStr(UserInput_International, "n") || InStr(UserInput_International, "N")) {
; 				UserInput_International := 0
; 			} ;else handled above
; 		}
; 		; Insert data if acceptable input
; 		if (InStr("BusanSeoul", UserInput_TrackName) && UserInput_TrackName != "") {
; 			Fn_InsertData("Korea", UserInput_TrackName, The_Date, para_FilePath, UserInput_International)
; 			return true
; 		}

; 		InputBox, UserInput_Association, %The_ProjectName%, % "Enter an association for: " para_FilePath "`n`n(Australia, GB_IRE, Melbourne Racing Cup, etc)"
; 		if (UserInput_TrackName != "") {
; 			Fn_InsertData(UserInput_Association, UserInput_TrackName, The_Date, para_FilePath, UserInput_International)
; 			return true
; 		}
; 	}
; }

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Gets the timestamp out of a filename and converts it into a full day of the week name
Fn_GetWeekName(para_String) ;Example Input: "20140730Scottsville"
{
RegExMatch(para_String, "(\d{4})(\d{2})(\d{2})", RE_TimeStamp)
	if (RE_TimeStamp1 != "") {
		;dddd corresponds to Monday for example
		FormatTime, l_WeekdayName , %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3%, dddd
	}
	if (l_WeekdayName != "") {
		return l_WeekdayName
	} else {
		;return a fat error is nothing is found
		;Msgbox, ERROR - %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3% - %para_String%
		return "ERROR"
	}
}

Fn_RemoveDatedKeysInArray(para_Key,para_Array)
{
	LastMonth :=
	LastMonth += -4, d
	StringTrimRight, LastMonth, LastMonth, 6
	loop, 33
	{
		Loop % para_Array.MaxIndex() {
		l_DateTrack := para_Array[A_Index,para_Key]
		if (!fn_DateValidate(para_Array[A_Index,"Date"])) {
			; Msgbox, % "Really kick out " . para_Array[A_Index,"FinalFilename"] . "? The date ( " . para_Array[A_Index,"Date"] . ") is invalid. Format is ALWAYS YYYYMMDD"
			para_Array.Remove(A_Index)
			Break
		}
		;Convert data out of l_DateTrack to get the weekdayname and new format of timestamp
		l_WeekdayName := Fn_GetWeekName(l_DateTrack)
		
		;See if item is new enough to stay in the array
		FileDate := Fn_JustGetDate(l_DateTrack)
			if (FileDate < LastMonth) {
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
	if (RE_TimeStamp1 != "") {
		l_TimeStamp = %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3%
		return %l_TimeStamp%
	}
;Else
return ERROR
}

Fn_GetWeekNameOLD(para_String) ;Example Input: "073014Scottsville"
{
	RegExMatch(para_String, "\d{2}(\d{2})(\d{2})(\d{2})", RE_TimeStamp)
	if (RE_TimeStamp1 != "") {
		;dddd corresponds to Monday for example
		FormatTime, l_WeekdayName , 20%RE_TimeStamp3%%RE_TimeStamp1%%RE_TimeStamp2%, dddd
	}
	if (l_WeekdayName != "") {
		return l_WeekdayName
	}
	;return a fat error if nothing is found
	msg("Couldn't understand the date format in " para_String)
	return "ERROR"
}


;Changes a correct Timestamp 20140730 to a bad one! 071314
Fn_GetModifiedDate(para_String) ;Example Input: "20140730Scottsville"
{
	RegExMatch(para_String, "(\d{4})(\d{2})(\d{2})", RE_TimeStamp)
	if (RE_TimeStamp1 != "") {
		l_NewDateFormat = %RE_TimeStamp2%%RE_TimeStamp3%%RE_TimeStamp1%
		return l_NewDateFormat
	} else {
		msg("Couldn't understand the date format of " para_String ". Check for errors.")
	}
}

fn_iniTrackLookup(para_iniSection,para_TrackCode)
{
Global settings_fileloc

	loop, Read, %settings_fileloc%
	{
		;Remember the INI key value for each section until a match has been found
		if (InStr(A_LoopReadLine, "]")) {
			l_CurrentIniKey := A_LoopReadLine
		}
		
		;Cut each track line into a psudo array and see if it matches the parameter track code
		ConfigArray := StrSplit(A_LoopReadLine, "=")
		if (l_CurrentIniKey = para_iniSection && ConfigArray[1] = para_TrackCode) {
			return % ConfigArray[2]
		}
	}
	return false
}


Fn_FindTrackIniKey(para_TrackCode)
{
Global settings_fileloc

	loop, Read, %settings_fileloc%
	{
		;Remember the INI key value for each section until a match has been found
		IfInString, A_LoopReadLine, ]
		{
			l_CurrentIniKey := A_LoopReadLine
		}
		
		;Cut each track line into a psudo array and see if it matches the parameter track code
		ConfigArray := StrSplit(A_LoopReadLine, "=")
		if (ConfigArray[1] = para_TrackCode && para_TrackCode != "null" && para_TrackCode != "") {
			;Match found, remove brackets from current ini key and return result
			StringReplace, l_CurrentIniKey, l_CurrentIniKey, [,,
			StringReplace, l_CurrentIniKey, l_CurrentIniKey, ],,
			return % l_CurrentIniKey
		}
	}
	return "null"
}


;This function inserts each track to an array that later gets sorted and exported to HTML
Fn_InsertData(para_Key, para_TrackName, para_Date, para_OldFileName, para_brands, para_International := 1) 
{
Global

	;Find out how big the array is currently
	AllTracks_ArraX := AllTracks_Array.MaxIndex()
	if (AllTracks_ArraX = "") {
		;Array is blank, start at 0
		AllTracks_ArraX = 0
	}

	;See if the Track/Date is already present in the array. if yes, do not insert again
	loop, % AllTracks_Array.MaxIndex()
	{
		if (para_Date . para_TrackName = AllTracks_Array[A_Index,"Date"] . AllTracks_Array[A_Index,"TrackName"]) {
			;Msgbox, %para_TrackName% for %para_Date% already exists in this array
			return
		}
	}

	;;International Track declaration
	;Just trusts para_International to be accurate

	AllTracks_ArraX += 1
	if (!para_Date || !para_TrackName) {
		return
	}

	AllTracks_Array[AllTracks_ArraX,"Key"] := para_Key
	AllTracks_Array[AllTracks_ArraX,"TrackName"] := fn_ReplaceStrings(" ", "_", para_TrackName)
	AllTracks_Array[AllTracks_ArraX,"Date"] := para_Date
	AllTracks_Array[AllTracks_ArraX,"DateTrack"] := para_Date . para_TrackName
	AllTracks_Array[AllTracks_ArraX,"FileName"] := para_OldFileName
	AllTracks_Array[AllTracks_ArraX,"FinalFilename"] := Fn_Filename(AllTracks_Array[AllTracks_ArraX,"TrackName"], para_Date)
	AllTracks_Array[AllTracks_ArraX,"International"] := para_International
	AllTracks_Array[AllTracks_ArraX,"brands"] := para_brands
	if (AllTracks_Array[AllTracks_ArraX,"Date"] = "null") {
		msg("FATAL ERROR WITH " AllTracks_Array[AllTracks_ArraX,"FinalFilename"] " - " para_DateTrack)
		exitapp
	}
}



Fn_Export(para_Key, para_URLLead)
{
Global

	l_Today = %A_YYYY%%A_MM%%A_DD%
	outputflag := false
	
	;Create HTML Title if any of that kind of track exist
	l_count = 0
	loop % AllTracks_Array.MaxIndex() {
		l_FileTimeStamp := AllTracks_Array[A_Index,"Date"]
		;Only add HTML title if [Key] Tracks are in the array AND are scheduled today or greater
		if (para_key = AllTracks_Array[A_Index,"Key"] && l_FileTimeStamp >= l_Today) {
			l_count += 1
		}
	}
	if (l_count >= 1) {
		Fn_InsertBlank(void)
		Fn_InsertBlank(void)
		Fn_InsertBlank(void)
		Fn_HTMLTitle(para_Key)
	} else {
		return ;exit the function as there is nothing worth doing here
	}

	;Read each track in the array and write to HTML if it matches the current key (GB/IR, Australia, etc)
	loop % AllTracks_Array.MaxIndex()
	{
		if (para_key = AllTracks_Array[A_Index,"Key"])	{
			l_Key := AllTracks_Array[A_Index,"Key"]
			l_TrackName := AllTracks_Array[A_Index,"TrackName"]
			l_DateTrack := AllTracks_Array[A_Index,"DateTrack"]
			l_FinalFilename := AllTracks_Array[A_Index,"FinalFilename"]
			
			;Convert data out of l_DateTrack to get the weekdayname and new format of timestamp
			l_WeekdayName := Fn_GetWeekName(l_DateTrack)
			
			;See if array item is new enough to be used in HTML
			if (AllTracks_Array[A_Index,"Date"] < l_Today) {
				;Skip to next item because this is older than today
				continue
			}
			
			l_TrackName := fn_ReplaceStrings("_", " ", l_TrackName)
			l_Key := fn_ReplaceStrings("_", " ", l_Key)
			;if the TrackName matches the Key, only output day in the HTML Name (This is for Australia/New Zealand/Japan)
			if (l_TrackName = l_Key) {
				l_CurrentLine = <a href="%Options_TVG3PrefixURL%%l_FinalFilename%" target="_blank">%l_WeekdayName% PPs</a><br />
			} else {
				l_CurrentLine = <a href="%Options_TVG3PrefixURL%%l_FinalFilename%" target="_blank">%l_TrackName%, %l_WeekdayName% PPs</a><br />
			}
			
			;Check for UK-IRE/other country with many tracks and separate with <br> if new weekday is detected
			if (l_count >= 7) {
				if (outputflag != true) {
					LastDate := l_WeekdayName
				} else if (LastDate != l_WeekdayName) {
					Fn_InsertText("<br />")
					LastDate := l_WeekdayName
				}
			}
			Fn_InsertText(l_CurrentLine)
			outputflag := true
		}
	}
	
	if ( AllTracks_ArraX >= 1) {
		Fn_InsertText("<br />")
	}
}


Fn_HTMLTitle(para_Text)
{
para_Text := fn_ReplaceStrings("-", "/", para_Text)
para_Text := fn_ReplaceStrings("_", " ", para_Text)
l_CurrentLine = <span style="color: #0c9256;"><strong>%para_Text%</strong></span><br />
Fn_InsertText(l_CurrentLine)
	if (InStr(para_Text, "GB"))	{
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
Gui, Add, Text, x2 y4 w220 +Center, %The_ProjectName%
Gui, Font, s10 w70, Arial
Gui, Add, Text, x168 y0 w50 +Right, v%The_VersionNumb%

Gui, Font


Gui,Add,Button,x0 y60 w43 h30 gParse,PARSE ;gMySubroutine
Gui,Add,Button,x50 y60 w120 h30 gRename,RENAME FILES ;gMySubroutine

Gui,Add,Button,x200 y60 w143 h30 gEditAssoc,EDIT ASSOC
Gui,Add,Button,x350 y60 w143 h30 gEditName,EDIT TRACK NAME
Gui,Add,Button,x500 y60 w143 h30 gEditDate,EDIT DATE

Gui,Add,Button,x650 y60 w143 h30 gDelete,DELETE RECORD
Gui,Add,ListView,x0 y100 w800 h450 Grid vGUI_Listview, Index|Track|Assoc|Date
	; Gui, Add, ListView, x2 y70 w490 h536 Grid NoSort +ReDraw gDoubleClick vGUI_Listview, #|Status|RC|Name|Race|

Gui,Show,h600 w800, %The_ProjectName%


;Menu
Menu, FileMenu, Add, E&xit`tCtrl+Q, Menu_File-Quit
Menu, FileMenu, Add, R&estart`tCtrl+R, Menu_File-Restart
Menu, MenuBar, Add, &File, :FileMenu  ; Attach the sub-menu that was created above

Menu, HelpMenu, Add, &About, Menu_About
Menu, HelpMenu, Add, &Confluence`tCtrl+H, Menu_Confluence
Menu, MenuBar, Add, &Help, :HelpMenu

Gui, Menu, MenuBar
return

;Menu Shortcuts
Menu_Confluence:
Run https://betfairus.atlassian.net/wiki/spaces/wog/pages/10650365/Ops+Tool+-+PPS2HTML+Automates+Free+Past+Performance+File+Renaming+and+HTML
return

Menu_About:
Msgbox, Renames Free PP files and generated HTML from all files run through the system. `nv%The_VersionNumb%
return

Menu_File-Restart:
Reload

Menu_File-Quit:
exitapp

GuiClose:
exitapp
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

Sb_GlobalNameSpace()
{
global

Path_PDFtoHTML = %A_ScriptDir%\Data\
AllTracks_Array := {Key:"", TrackName:"", DateTrack:"", FileName:""}
AllTracks_ArraX = 1
FirstGBLoop = 1
;pdf parsing paths
exepath := A_ScriptDir "\Data\PDFtoTEXT.exe"
txtpath := A_ScriptDir "\Data\TEMPPDFTEXT.txt"

tomorrow := a_now	
tomorrow += 1, days
formattime, tomorrowsyear, %tomorrow%, yyyy 
formattime, tomorrow_date, %tomorrow%, yyyyMMdd
}


;/--\--/--\--/--\--/--\--/--\
; Small functions
;\--/--\--/--\--/--\--/--\--/

fn_Parsepdf(para_FilePath) {
	global

	RunWait, "%exepath%" "%para_FilePath%" "%txtpath%",, Hide
	Sleep, 200

	;;Read the Trackname out of the converted text
	FileRead, File_PDFTEXT, %txtpath%
	FileDelete, %txtpath%
	return File_PDFTEXT
}


Fn_Filename(para_trackname,para_date)
{
Global
	if (!Options_suffix) {
		Options_suffix := ""
	}
	para_trackname := StrReplace(para_trackname," ","_")
	return para_trackname . para_date . Options_suffix ".pdf"
}

Fn_DownloadtoFile(para_URL)
{
	;Download Page directly to memory
	httpObject:=ComObjCreate("WinHttp.WinHttpRequest.5.1") ;Create the Object
	httpObject.Open("GET",para_URL) ;Open communication
	httpObject.Send() ;Send the "get" request
	Response := httpObject.ResponseText ;Set the "text" variable to the response
	if (Response != "") {
		return % Response
	} else {
		return false
	}
}
