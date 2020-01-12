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
The_VersionNumb := "3.8.0"

;Dependencies
#Include gui.ahk
#Include %A_ScriptDir%\lib
#Include json.ahk\export.ahk
#Include util-misc.ahk\export.ahk
#Include sort-array.ahk\export.ahk
#Include wrappers.ahk\export.ahk
#Include transformStringVars.ahk\export.ahk
#Include util-array.ahk\export.ahk
#Include dateparser.ahk\export.ahk
#Include inireadwrite.ahk

; npm
#Include %A_ScriptDir%\node_modules
#Include biga.ahk\export.ahk
#Include string-similarity.ahk\export.ahk



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;;Startup special global variables
A := new biga()
GUI()
;; Make some special vars for config file date prediction
Tomorrow := %A_Now%
sb_IncrementDate()

;Check for CommandLineArguments
CL_Args = StrSplit(1 , "|")
if (A.includes(CL_Args,"auto")) {
	AUTOMODE := true
}


;;Import and parse settings file
FileRead, The_MemoryFile, % A_ScriptDir "\Data\settings.json"
Settings := JSON.parse(The_MemoryFile)
The_MemoryFile := ;blank
if (!IsObject(AllTracks_Array)) {
	AllTracks_Array := []
}

;;Import Existing Track DB File
FileRead, The_MemoryFile, % Settings.DBLocation
if (StrLen(The_MemoryFile) > 4) {
	AllTracks_Array := JSON.parse(The_MemoryFile)
} else {
	AllTracks_Array := []
}

;;Load the config file and check that it loaded completely
Fn_LoadIni()


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; MAIN
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

; Consider downloading files here


;; Loop all pdfs
Parse:
; reload ini track mappings
Fn_LoadIni()


The_ListofDirs := Settings.dirs
The_ListofDirs.push(A_ScriptDir)

;; New folder processing
if (Settings.parsing) {
	for key, value in Settings.parsing
	{
		;convert string in settings file to a fully qualifed var + string for searching
		searchdirstring := transformStringVars(value.dir "\*.pdf")
		if (value.recursive) {
			value.recursive := " R"
		}
		loop, Files, %searchdirstring%, % value.recursive
		{
			if (fn_InArray(AllTracks_Array,A_LoopFileName,"FinalFilename")) { ;; Exit out if the filename is found at all in the finalname array
				continue
			}
			
			sb_IncrementDate(A_Now)
			The_TrackName := false
			RegExResult := fn_QuickRegEx(A_LoopFileName,transformStringVars(value.filepattern))
			if (value.weeksearch true && RegExResult = false) { ;loop 7 days ahead if user is trying to use a specific date and the file wasn't already found
				loop, 7 {
					sb_IncrementDate()
					RegExResult := fn_QuickRegEx(A_LoopFileName,transformStringVars(value.filepattern))
					if (RegExResult != false) {
						break
					}
				}
			}

			; do for any regex pattern matches in settings file
			if (RegExResult != false) {

				; delete any duplicate downloads
				if (value.do = "delete") {
					FileDelete, % A_LoopFileFullPath
					continue
				}
				
				; parse the filename for a date
				dateSearchText := A_LoopFileName
				if (value.prependdate != "") { ;append the date
					dateSearchText := transformStringVars(value.prependdate) A_LoopFileName
				}
				if (value.weeksearch = true) { ;parse using config specified datestring
					dateSearchText := TOM_YYYY TOM_MM TOM_DD
				}
				The_Date := Fn_DateParser(dateSearchText)
				The_Country := value.association
				;; Pull Trackname from Regex if specified
				if (value.tracknameinfile) {
					The_TrackName := RegExResult
				}

				; change the date if specified
				if (value.do = "incrementday") {
					FormatTime, local_date, %The_Date%000000, yyyyMMddHHmmss
					local_date += 1, Days
					FormatTime, The_Date, %local_date%, yyyyMMdd
				}
				if (value.do = "decrementday") {
					FormatTime, local_date, %The_Date%000000, yyyyMMddHHmmss
					local_date += -1, Days
					FormatTime, The_Date, %local_date%, yyyyMMdd
					; msgbox, % "parsed date is " local_date "| decrementday is " The_Date
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
					vKey := A.trim(value.configkeylookup,"[]")
					var := transformStringVars("%vKey%_%RegExResult%")
					The_TrackName := %var%
					if (A.isUndefined(The_TrackName)) {
						msg("Searched config.ini under '" value.configkeylookup "' key for '" RegExResult "' and found nothing. Update the file")
					}
				}
				
				;; Insert data if a trackname and date was verified
				if (The_TrackName && The_Date) {
					; msg("inserting: " The_TrackName "(" A_LoopFileName ")  with the assosiation: " The_Country)
					Fn_InsertData(The_Country, Trim(The_TrackName), The_Date, A_LoopFileLongPath, value.brand, value.international)
				} else {
					; else is not handled in a seprate loop checking all files below
				}
			}
		}
	}

	;; Loop though all files once more and check for any unhandled files
	unhandledFiles := []
	for key, value in Settings.parsing
	{
		searchdirstring := transformStringVars(value.dir "\*.pdf")
		if (value.recursive) {
			value.recursive := " R"
		}
		loop, Files, %searchdirstring%, % value.recursive
		{
			if !(fn_InArray(AllTracks_Array,A_LoopFileName,"FinalFilename") || fn_InArray(AllTracks_Array,A_LoopFileLongPath,"FileName") || fn_InArray(unhandledFiles,A_LoopFileName)) {
				unhandledFiles.push(A_LoopFileName)
			}
		}
	}
	if (unhandledFiles.Length() > 0) {
		msg("Nothing handling the following files:`n" Array_Print(unhandledFiles) "`n`nUpdate .\Data\settings.json immediately and re-run. Renaming files by hand is NOT advised.")
	}
	

} else {
	msg("No .\Data\settings.json file found`n`nThe application will quit")
	ExitApp
}


;/--\--/--\--/--\
; Remove blacklisted tracks
;\--/--\--/--\--/
if (Settings.blacklist) {
	for key, value in Settings.blacklist
	{

	}
}


;Sort all Array Content by DateTrack ; No not do in descending order as this will flip the output. Sat,Fri,Thur
;Fn_Sort2DArrayFast(AllTracks_Array, "DateTrack")
AllTracks_Array := A.sortBy(AllTracks_Array,"DateTrack")
AllTracks_Array := A.sortBy(AllTracks_Array,"Key")

FormatTime, Today, , yyyyMMdd
LV_Delete()
; Array_Gui(AllTracks_Array)
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
FileDelete, % A_ScriptDir "\" Settings.AdminConsoleFileName
Data_json := []
loop, % AllTracks_Array.MaxIndex() {
	;msgbox, % AllTracks_Array[A_Index,"Date"] " vs " Today
	if (AllTracks_Array[A_Index,"Date"] >= Today && !InStr(AllTracks_Array[A_Index,"DateTrack"],"null")) {
		thistrack := {}
		; build the string to display on the site, defaulting to "[trackname], [weekday]" unless a user defined string exists
		if (!AllTracks_Array[A_Index,"String"]) {
			thistrack.name := AllTracks_Array[A_Index,"TrackName"] ", " Fn_GetWeekName(AllTracks_Array[A_Index,"Date"])
		} else {
			thistrack.name := AllTracks_Array[A_Index,"String"]
		}
		; Do not use the trackname if the track matches it's own key (IE Australia), only use the Weekday name
		if (AllTracks_Array[A_Index,"TrackName"] == AllTracks_Array[A_Index,"Key"]) {
			thistrack.name := Fn_GetWeekName(AllTracks_Array[A_Index,"Date"])
		}
		thistrack.filename := AllTracks_Array[A_Index,"FinalFilename"]
		thistrack.date := AllTracks_Array[A_Index,"Date"]
		thistrack.group := AllTracks_Array[A_Index,"Key"]
		thistrack.brand := AllTracks_Array[A_Index,"brand"]
		if (AllTracks_Array[A_Index,"International"] = true) {
			thistrack.international := true
		} else {
			thistrack.international := false
		}
		
		;replace some yesteryear placeholder characters
		thistrack.group := StrReplace(thistrack.group, "#" , "/")
		thistrack.group := StrReplace(thistrack.group, "_" , " ")
		;;Append the track to JSON output sorted as it was parsed
		Data_json.push(thistrack)
		;if backwards is needed:
		; Data_json.InsertAt(1,thistrack)
	}
}

if (Settings.AdminConsoleFileName) {
	FileAppend, % JSON.stringify(Data_json), % A_ScriptDir "\" Settings.AdminConsoleFileName
}




;Kick Array items over 30 days old out
Fn_RemoveDatedKeysInArray("DateTrack", AllTracks_Array)


;For Debugging. Show contents of the Array 
;Array_Gui(AllTracks_Array)

;;Export Array as a JSON file
The_MemoryFile := JSON.stringify(AllTracks_Array)
FileDelete, % Settings.DBLocation
FileAppend, %The_MemoryFile%, % Settings.DBLocation

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
	Goto, Parse
}
return

EditString:
selected := LV_GetNext(1, Focused)
if (selected > 0) {
	LV_GetText(INDEX, selected, 1) ;INDEX
	LV_GetText(RowText, selected, 2) ;TrackName
	msgtext := "Please enter a new STRING"
	InputBox, UserInput, %msgtext%, %msgtext%, , , , , , , ,%RowText%
	AllTracks_Array[INDEX,"String"] := UserInput
	Goto, Parse
}
return

;;Actually move and rename files now
Rename:
Sb_RenameFiles()
return


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Menu Options
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Menu_File-CustomTrack:
	selectedfile := FileSelectFile("", A_ScriptDir, "Please select the file", "*pdf")

	msgtext := "Please enter the track name"
	InputBox, u_trackname, %msgtext%, %msgtext%
	msgtext := "Please enter the date of racing for this file in YYYYMMDD format"
	InputBox, u_date, %msgtext%, %msgtext%
	msgtext := "Please enter the association of this file (France, Sweden, UK#IRE, etc)"
	defaultText := Fn_GuessAssociation(AllTracks_Array, u_trackname)
	InputBox, u_association, %msgtext%, %msgtext%, , , , , , , , defaultText
	; l_date := Fn_DateParser(u_date)
	msgtext := "Please enter the platforms for this track to appear on. Example: tvg,iowa,4njbets"
	InputBox, u_platforms, %msgtext%, %msgtext%
	l_platforms := StrSplit(u_platforms,",")
	if (!l_platforms.Length()) {
		msg("platforms not understood or erroneous. The application will restart")
		Reload
	}
	msgtext := "Enter 1 if this track is international, otherwise enter 0"
	InputBox, u_international, %msgtext%, %msgtext%
	if (u_international = "1") {
		l_international := 1
	} else if (u_international = "0") {
		l_international := 0
	} else {
		l_international := 1 ;default to 1 if input not understood
	}

	Fn_InsertData(u_association, u_trackname, u_date, selectedfile, l_platforms, l_international)
	Goto, Parse
return



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Sb_RenameFiles()
{
	global

	;Read each track in the array and write to HTML if it matches the current key (GB/IR, Australia, etc)
	Loop % AllTracks_Array.MaxIndex()
	{
		l_OldFileName := AllTracks_Array[A_Index,"FileName"]
		l_NewFileName := AllTracks_Array[A_Index,"FinalFilename"]

		if !FileExist(l_OldFileName) {
			continue
		} else {
			; msgbox, % l_OldFileName " exists atm"
		}
		if (!InStr(l_OldFileName,".pdf")) {
			continue
		}
		if (!A.isUndefinded(Settings.exportDir)) {
			exportPath := exportDir "\" l_NewFileName
		} else {
			exportPath := A_ScriptDir "\" l_NewFileName
		}
		FileCopy, %l_OldFileName%, %exportPath%, 1
		;if the filemove was unsuccessful for any reason, tell user
		if (Errorlevel != 0) {
			msg("There was a problem renaming the following: " l_OldFileName " (typically Permissions\FileInUse)")
		} else {
			if (InStr(l_OldFileName, A_ScriptDir)) { ;file is in same dir as exe, delete if move was success
				FileDelete, %l_OldFileName%
				if (Errorlevel != 0) {
					msg("There was a problem deleting the old file: " l_OldFileName " (typically Permissions\FileInUse)")
				}
			}
		}
	}
}



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Increment the date used for 
sb_IncrementDate(para_StartDate = "")
{
	global

	Tomorrow += 1, d
	if (para_StartDate != "") { ;set date with argument if supplied
		Tomorrow := para_StartDate
		if (para_StartDate.length <= 8) { ;append HHMMSS if missing
			Tomorrow := para_StartDate . "000000"
		}
	}
	FormatTime, TOM_DD, %Tomorrow%, dd
	FormatTime, TOM_MM, %Tomorrow%, MM
	FormatTime, TOM_YYYY, %Tomorrow%, yyyy
	FormatTime, TOM_YY, %Tomorrow%, yyyy
	TOM_YY := SubStr(TOM_YY, 3, 2)
	;some other more obscure stuff
	FormatTime, TOM_D, %Tomorrow%, d
	FormatTime, TOM_M, %Tomorrow%, M
}


;Gets the timestamp out of a filename and converts it into a day of the week name
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
		;throw error and return false if unsuccessful
		throw error
		return false
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
			break
		}
		;Convert data out of l_DateTrack to get the weekdayname and new format of timestamp
		l_WeekdayName := Fn_GetWeekName(l_DateTrack)
		
		;See if item is new enough to stay in the array
		FileDate := Fn_JustGetDate(l_DateTrack)
			if (FileDate < LastMonth) {
				para_Array.Remove(A_Index)
				break
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


;This function inserts each track to an array that later gets sorted and exported to HTML
Fn_InsertData(para_Key, para_TrackName, para_Date, para_OldFileName, para_brand, para_International := 1) 
{
	global

	;Find out how big the array is currently
	AllTracks_ArraX := AllTracks_Array.MaxIndex()
	if (AllTracks_ArraX = "") {
		;Array is blank, start at 0
		AllTracks_ArraX = 0
	}

	;See if the Track/Date is already present in the array. if yes, do not insert again
	loop, % AllTracks_Array.MaxIndex() {
		if (para_Date . para_TrackName = AllTracks_Array[A_Index,"Date"] . AllTracks_Array[A_Index,"TrackName"]) {
			; msg(para_TrackName para_Date " already exists in the db, cannot be added")
			return false
		}
	}

	AllTracks_ArraX += 1
	if (!para_Date || !para_TrackName) {
		return
	}

	AllTracks_Array[AllTracks_ArraX,"Key"] := para_Key
	AllTracks_Array[AllTracks_ArraX,"TrackName"] := para_TrackName
	AllTracks_Array[AllTracks_ArraX,"Date"] := para_Date
	AllTracks_Array[AllTracks_ArraX,"DateTrack"] := para_Date . para_TrackName
	AllTracks_Array[AllTracks_ArraX,"FileName"] := para_OldFileName
	AllTracks_Array[AllTracks_ArraX,"FinalFilename"] := Fn_Filename(AllTracks_Array[AllTracks_ArraX,"TrackName"], para_Date)
	AllTracks_Array[AllTracks_ArraX,"International"] := para_International
	AllTracks_Array[AllTracks_ArraX,"brand"] := para_brand
	if (AllTracks_Array[AllTracks_ArraX,"Date"] = "null") {
		msg("FATAL ERROR WITH " AllTracks_Array[AllTracks_ArraX,"FinalFilename"] " - " para_DateTrack)
		exitapp
	}
}


Fn_Export(para_Key, para_URLLead)
{
	global

	l_Today := A_YYYY A_MM A_DD
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
	loop % AllTracks_Array.MaxIndex() {
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
	global
	FileAppend, %para_Text%`n, % The_HMTLFile
}


;This function inserts a blank line. How worthless 
Fn_InsertBlank(void)
{
	global
	FileAppend, `n, % The_HMTLFile
}


; this function makes a best guess at the association of a track, else returns ""
Fn_GuessAssociation(param_alltracks, param_trackname)
{
	A := new biga()
	stringSimilarity := new stringsimilarity()

	tracknames := A.map(param_alltracks, "Trackname")
	associations := A.map(param_alltracks, "Key")
	minialltracks := A.zip(tracknames, associations)
	; msgbox, % A.printObj(minialltracks)
	matchingObj := A.find(minialltracks, [1, param_trackname])
	if (A.isUndefined(matchingObj.2)) {
		return false
	}
	return matchingObj.2
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
	global
	if (!Settings.suffix) {
		Settings.suffix := ""
	}
	if (!Settings.prefix) {
		Settings.prefix := ""
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
