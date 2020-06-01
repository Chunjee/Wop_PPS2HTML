;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Renames FreePPs pdf files and generates metadata on each file

;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
SetBatchLines -1 ;Go as fast as CPU will allow
#NoTrayIcon
#SingleInstance force
The_ProjectName := "PPS2HTML"
The_VersionNumb := "3.11.1"

; Dependencies
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
#Include logs.ahk\export.ahk

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;; Startup special global variables
A := new biga()
GUI()

;; Make some special vars for config file date prediction
Tomorrow := A_Now
Sb_IncrementDate()

;; Import and parse settings file
FileRead, The_MemoryFile, % A_ScriptDir "\Data\settings.json"
Settings := JSON.parse(The_MemoryFile)
The_MemoryFile := ;blank
if (!IsObject(AllTracks_Array)) {
	AllTracks_Array := []
}

;; Setup log file
if (A.isUndefined(Settings.logfiledir)) {
	Settings.logfiledir := "C:\TVG\LogFiles\"
}
log := new log_class(The_ProjectName "-" A_YYYY A_MM A_DD, Settings.logfiledir)
log.add(The_ProjectName " launched from user " A_UserName " on the machine " A_ComputerName ". Version: v" The_VersionNumb)

;; Check for CommandLineArguments
AUTOMODE := false
if (A.includes(A_Args, "auto") || InStr(A_Args, "auto")) {
	AUTOMODE := true
	log.add("Automode enabled")
}


Settings.DBLocation := transformStringVarsGlobal(Settings.DBLocation)
Settings.trackMappingConfig := transformStringVarsGlobal(Settings.trackMappingConfig)
;; Import Existing Track DB File
FileRead, The_MemoryFile, % Settings.DBLocation
if (A.size(The_MemoryFile) > 10) {
	log.add("Parsing " Settings.DBLocation)
	AllTracks_Array := JSON.parse(The_MemoryFile)
} else {
	log.add("No existing DB found, creating new one in memory")
	AllTracks_Array := []
}

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; MAIN
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;; Loop all pdfs and parse them
Sb_ParseFiles()

;; Loop though all files once more and check for any unhandled files
unhandledFiles := []
for key, value in Settings.parsing
{
	searchdirstring := transformStringVarsGlobal(value.dir "\*.pdf")
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
if (unhandledFiles.Count() > 0 && Settings.showUnhandledFiles) {
	msg("Nothing handling the following files:`n" A.join(A.map(unhandledFiles, A.trim), ", ") "`n`nUpdate .\Data\settings.json immediately and re-run. Renaming files by hand is NOT advised.")
}



;/--\--/--\--/--\
; Remove blacklisted tracks
;\--/--\--/--\--/
Sb_RemoveBlackListedTracks()


; kick tracks out that are old AND refresh GUI display
Sb_RefreshAllTracksandGUI()


;/--\--/--\--/--\
; JSON Generation
;\--/--\--/--\--/
;For Debugging. Show contents of the Array 
;Array_Gui(AllTracks_Array)
Sb_GenerateJSON()

;;Export Array as a JSON file
Sb_GenerateDB()

if (AUTOMODE) {
	log.add("Automatically jumping to pull files as Automode is enabled")
	Sb_RenameFiles()
}
;;ALL DONE
return



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Menu Options
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Menu_File-CustomTrack:
	log.add(A_UserName " attempting to add custom track")
	selectedfile := FileSelectFile("", A_ScriptDir, "Please select the file", "*pdf")

	msgtext := "Please enter the track name"
	InputBox, u_trackname, %msgtext%, %msgtext%
	msgtext := "Please enter the date of racing for this file in YYYYMMDD format"
	InputBox, u_date, %msgtext%, %msgtext%
	msgtext := "Please enter the association of this file (France, Sweden, UK#IRE, etc)"
	defaultText := Fn_GuessAssociation(AllTracks_Array, u_trackname)
	InputBox, u_association, %msgtext%, %msgtext%, , , , , , , , % defaultText
	; l_date := Fn_DateParser(u_date)
	msgtext := "Please enter the platforms for this track to appear on. Example: tvg,iowa,4njbets"
	InputBox, u_platforms, %msgtext%, %msgtext%
	l_platforms := StrSplit(u_platforms,",")
	if (A.size(l_platforms) = 0) {
		msg("platforms not understood or erroneous. Please rety")
		return
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

	Fn_InsertData(u_association, u_trackname, u_date, selectedfile, l_platforms, l_international, "sp")
return



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Sb_ParseFiles()
{
	global

	; reload ini track mappings
	Fn_InitializeIni(transformStringVarsGlobal(Settings.trackMappingConfig))
	Fn_LoadIni(transformStringVarsGlobal(Settings.trackMappingConfig))

	The_ListofDirs := transformStringVarsGlobal(Settings.dirs)
	The_ListofDirs.push(A_ScriptDir)

	if (A.isUndefined(Settings.parsing)) { 
		msg("No parsers found in .\Data\settings.json file.`n`nThe application will quit")
		ExitApp
	}
	;; New folder processing
	for key, value in Settings.parsing {
		;convert string in settings file to a fully qualifed var + string for searching
		searchdirstring := transformStringVarsGlobal(value.dir "\*.pdf")
		if (value.recursive) {
			value.recursive := " R"
		}
		loop, Files, %searchdirstring%, % value.recursive
		{
			; Skip this file if already present
			existingObj := A.filter(AllTracks_Array, {"originalFilePath": A_LoopFileFullPath})
			if (A.size(existingObj) > 1) {
				continue
			}
			; skip files that return with old dates
			if (fn_DatePresentFuture(fn_DateParser(A_LoopFileName)) == false) {
				continue
			}

			Sb_IncrementDate(A_Now)
			The_TrackName := false
			RegExResult := fn_QuickRegEx(A_LoopFileName, transformStringVarsGlobal(value.filepattern))
			;loop 7 days ahead if user is trying to use a specific date and the file wasn't already found
			if (value.weeksearch true && RegExResult = false) {
				loop, 7 {
					Sb_IncrementDate()
					RegExResult := fn_QuickRegEx(A_LoopFileName, transformStringVarsGlobal(value.filepattern))
					if (RegExResult != false) {
						break
					}
				}
			}

			; do for any regex pattern matches in settings file
			if (RegExResult != false) {
				
				; if any "do" values or array
				if (value.do) {
					; delete any duplicate downloads
					if (A.includes(value.do, "delete")) {
						FileDelete, % A_LoopFileFullPath
						continue
					}
				}

				; parse the filename for a date
				dateSearchText := A_LoopFileName
				if (value.prependdate != "") { ;append the date
					dateSearchText := transformStringVarsGlobal(value.prependdate) A_LoopFileName
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
					l_text := fn_Parsepdf(A_LoopFileFullPath)
					The_TrackName := fn_QuickRegEx(l_text, value.pdftracknamepattern)
					if (!A.isUndefined(The_TrackName)) {
						log.add("Found the trackname: " The_TrackName " in {" A_LoopFileName "} with the RegEx {" value.pdftracknamepattern "}")
					}
				}
				;; Pull trackname from ini lookup if specified
				if (value.configkeylookup != "") {
					vKey := A.trim(value.configkeylookup,"[]")
					var := transformStringVarsGlobal("%vKey%_%RegExResult%")
					The_TrackName := %var%
					; msgbox, % var "  /   " The_TrackName
					if (A.isUndefined(The_TrackName) && A.findIndex(AllTracks_Array, {"originalFilePath": A_LoopFileFullPath}) = -1) {
						msgline := "Searched config.ini under '" value.configkeylookup "' key for '" RegExResult "' and found nothing. Update the file"
						log.add(msgline)
						if (Settings.showUnhandledFiles != false) {
							msg(msgline)
						}
					}
				}
				
				;; Insert data if a trackname and date was verified
				; msgbox, % The_TrackName " " The_Date " " The_Country
				if (The_TrackName && The_Date && The_Country) {
					; msg("inserting: " The_TrackName "(" A_LoopFileName ")  with the assosiation: " The_Country)
					Fn_InsertData(A.trim(The_Country), A.trim(The_TrackName), The_Date, A_LoopFileLongPath, value.brand, value.international, value.fileprefix)
				} else {
					; else is not handled in a seprate loop checking all files below
				}
			}
		}
	}
	log.add("Finished checking all parsers defined in config")
}


Sb_RefreshAllTracksandGUI()
{
	global

	FormatTime, Today, , yyyyMMdd
	;Kick Array items over 30 days old out
	AllTracks_Array := A.uniq(AllTracks_Array)
	AllTracks_Array := A.filter(AllTracks_Array, Func("helper_returnNewDates"))
	;Sort all Array Content by DateTrack ; No not do in descending order as this will flip the output. Sat,Fri,Thur
	AllTracks_Array := A.sortBy(AllTracks_Array, ["trackname", "date", "group"])
	Array_GUI(AllTracks_Array)

	FormatTime, Today, , yyyyMMdd
	log.add("Refreshing GUI display list")
	LV_Delete()
	; Array_Gui(AllTracks_Array)
	loop, % AllTracks_Array.Count() {
		LV_Add("",A_Index,AllTracks_Array[A_Index,"name"],AllTracks_Array[A_Index,"group"],AllTracks_Array[A_Index,"date"])
	}
	LV_ModifyCol()
}


Sb_RemoveBlackListedTracks()
{
	global

	; if a blacklist is supplied in the settings file
	if (Settings.blacklist) {
		; loop into each of the blacklist settings, user may have defined one or more
		for key, value in Settings.blacklist {
			; find objects that match the blacklisted properties
			RemovableTracks := A.filter(AllTracks_Array, value)
			; remove any matches from the larger array and re-assign
			AllTracks_Array := A.difference(AllTracks_Array, RemovableTracks)
			if (A.size(RemovableTracks) > 0) {
				log.add("Blacklisted tracks found, removed")
			}
		}
	}
}

Sb_GenerateJSON()
{
	global

	FormatTime, Today, , yyyyMMdd
	FileDelete, % A_ScriptDir "\" Settings.AdminConsoleFileName
	log.add("Building " Settings.AdminConsoleFileName)
	Data_json := []
	loop, % AllTracks_Array.Count() {
		;msgbox, % AllTracks_Array[A_Index,"Date"] " vs " Today
		if (AllTracks_Array[A_Index,"Date"] >= Today && !InStr(AllTracks_Array[A_Index,"DateTrack"],"null")) {
			thistrack := {}
			thistrack := AllTracks_Array[A_Index]		
			;replace some yesteryear placeholder characters
			thistrack.group := StrReplace(thistrack.group, "#" , "/")
			thistrack.group := StrReplace(thistrack.group, "_" , " ")
			;;Append the track to JSON output sorted as it was parsed
			Data_json.push(thistrack)
		}
	}
	if (A.isUndefined(Settings.AdminConsoleFileName)) {
		Settings.AdminConsoleFileName := "data.json"
	}
	FileAppend, % JSON.stringify(A.uniq(Data_json)), % A_ScriptDir "\" Settings.AdminConsoleFileName
	msgbox, % A_ScriptDir "\" Settings.AdminConsoleFileName " written"
}

Sb_GenerateDB()
{
	global

	log.add("Writing latest DB to " Settings.DBLocation)
	The_MemoryFile := JSON.stringify(AllTracks_Array)
	FileDelete, % Settings.DBLocation
	sleep, 600
	FileAppend, %The_MemoryFile%, % Settings.DBLocation
	msgbox, % "written " Settings.DBLocation
}

Sb_RenameFiles()
{
	global

	log.add("Pulling files and renaming...")
	; Read each track in the array and perform file renaming
	loop % AllTracks_Array.Count()
	{
		thisTrack := AllTracks_Array[A_Index]

		; skip this item if the original file is gone (doesn't need to be renamed because it doesn't exist)
		if !FileExist(thisTrack.originalFilePath) {
			continue
		}
		; skip if there is no export dir in settings
		exportDir := transformStringVarsGlobal(Settings.exportDir)
		if (A.isUndefined(exportDir)) {
			exportPath := A_ScriptDir "\" thisTrack.filename
		} else {
			exportPath := exportDir "\" thisTrack.filename
		}
		FileCopy, % thisTrack.originalFilePath, %exportPath%, 1
		; if the file move was unsuccessful for any reason, tell the user
		if (Errorlevel != 0) {
			msg("There was a problem renaming the following: " thisTrack.originalFilePath " (typically Permissions\FileInUse)")
		} else {
			if (InStr(thisTrack.originalFilePath, A_ScriptDir)) { ;file is in same dir as exe, delete if move was success
				FileDelete, % thisTrack.originalFilePath
				if (Errorlevel != 0) {
					msg("There was a problem deleting the old file: " thisTrack.originalFilePath " (typically Permissions\FileInUse)")
				}
			}
		}
	}
}

;Create Directory and install needed file(s)
Sb_InstallFiles()
{
	global

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

;Increment the date used for date searching thing. feature which I guess needs global scope -_-"
Sb_IncrementDate(para_StartDate := "")
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
Fn_GetWeekName(para_String) ;Example Input: "20140730"
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


Fn_JustGetDate(para_String)
{
	RegExMatch(para_String, "(\d{4})(\d{2})(\d{2})", RE_TimeStamp)
	if (RE_TimeStamp1 != "") {
		l_TimeStamp = %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3%
		return %l_TimeStamp%
	}
return ERROR
}


;Changes a correct Timestamp 20140730 to a bad one! 071314
Fn_GetModifiedDate(para_String) ;Example Input: "20140730Scottsville"
{
	RegExMatch(para_String, "(\d{4})(\d{2})(\d{2})", RE_TimeStamp)
	if (RE_TimeStamp1 != "") {
		l_NewDateFormat = %RE_TimeStamp2%%RE_TimeStamp3%%RE_TimeStamp1%
		return l_NewDateFormat
	} else {
		log.add(msg("Couldn't understand the date format of {" para_String "} Check for errors."))
	}
}


;This function inserts each track to an array that later gets sorted and exported to HTML
Fn_InsertData(para_key, para_trackname, para_date, para_originalfilepath, para_brand, para_international := 1, para_prefix := "")
{
	global AllTracks_Array
	global A
	
	thisTrack := { "brand": para_brand
				 , "date": para_date
				 , "filename": Fn_Filename(para_trackname, para_date, para_key, para_prefix)
				 , "group": para_key
				 , "international": para_international
				 , "name": fn_RestringExtenededAscii(para_trackname) ", " Fn_GetWeekName(para_date)
				 , "string": ""

				 , "trackname": fn_RestringExtenededAscii(para_trackname)
				 , "identity": para_key para_trackname para_date
				 , "originalFilePath": para_originalfilepath }
	; Do not use the trackname if the track matches it's own key (IE Australia), only use the Weekday name
	if (thisTrack.group = para_trackname) {
		thistrack.name := Fn_GetWeekName(thistrack.date)
	}

	; WhatAdminConsoleWants example object
	exampleObj := { "brand": ["tvg", "iowa"]
				  , "date": 20200318
				  , "filename": "Chantilly20200317.pdf"
				  , "group": "France"
				  , "international": 1
				  , "name": "Chantilly, Tuesday" }

	;See if the Track/Date is already present in the array. if yes, do not insert again
	if (A.indexOf(AllTracks_Array, thisTrack) != -1) {
		return false
	}

	; insert it into the array
	AllTracks_Array.push(thisTrack)
	log.add("Added track {" thisTrack.originalFilePath "} to memory")
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

fn_DatePresentFuture(param_date) {
    FormatTime, OutputVar, A_Now, yyyyMMdd
    if (OutputVar <= param_date) { ; return true for dates that are equaltoo or greater than today
        return true
    }
    if (OutputVar > param_date) {
        return false
    }
    ; parameter was not understood
    return -1
}

helper_returnNewDates(param_track)
{
	global A

	YesterdaysDate := A_Now
	YesterdaysDate += -1, d
	YesterdaysDate := A.join(A.slice(YesterdaysDate, 1, 8), "")
	if (!fn_DateValidate(param_track.date)) {
		return false
	}
	;See if item is new enough to stay in the array
	if (param_track.date > YesterdaysDate) {
		return true
	}
}

fn_Parsepdf(para_FilePath) {
	exepath := A_ScriptDir "\Data\PDFtoTEXT.exe"
	txtpath := A_ScriptDir "\Data\pdftext.txt"
	RunWait, "%exepath%" "%para_FilePath%" "%txtpath%",, Hide
	Sleep, 250
	;;Read the Trackname out of the converted text
	FileRead, File_PDFTEXT, %txtpath%
	FileDelete, %txtpath%
	return File_PDFTEXT
}

Fn_Filename(para_trackname,para_date,para_key,para_prefix)
{
	global

	if (!Settings.filesuffix) {
		Settings.suffix := ""
	}
	if (!Settings.fileprefix) {
		Settings.prefix := ""
	}
	para_trackname := StrReplace(para_trackname," ","_")
	if (para_prefix != "") {
		return para_prefix para_trackname . para_date . Options_suffix ".pdf"
	}
	return A.join(A.slice(para_key,1,3),"") "-" para_trackname . para_date . Options_suffix ".pdf"
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

fn_RestringExtenededAscii(param_value:="",param_map1:="",param_map2:="")
{
	; determine what kind of map is being provided
	; Object
	if (IsObject(param_map1)) {
		l_arr := StrSplit(param_value)
		; for each characters
		for l_key, l_char in l_arr {
			; assign output depending on availability in map
			if param_map1.HasKey(l_char) {
				l_output .= param_map1[l_char]
			} else {
				l_output .= l_char
			}
		}
		return l_output
	}

	; String
	if (!IsObject(param_map1)) {
		if (StrLen(param_map1) != StrLen(param_map2)) {
			return param_value
		}
		if (param_map1 = "") {
			param_map1 := "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ"
		}
		if (param_map2 = "") {
			param_map2 := "AAAAAAACEEEEIIIIDNOOOOOxOUUUUYPBaaaaaaaceeeeiiiionooooo%ouuuuypy"
		}
		l_array1 := StrSplit(param_map1)
		l_array2 := StrSplit(param_map2)
	}
	l_dataArr := StrSplit(param_value)
	l_output := ""

	; for each character in value
	for l_key, l_value in l_dataArr {
		if (Asc(l_value) > 126) {
			; scan the map array for matching character to change
			for l_key2, l_value2 in l_array1 {
				if (l_value = l_value2) {
					; assign output to matching character
					l_output .= l_array2[l_key2]
					;no need to check the rest of the map
					break
				}
			}
		} else {
			l_output .= l_value
		}
	}
	return l_output
}


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
	return
}

Parse:
AUTOMODE := false
Sb_ParseFiles()
return

Rename:
Sb_RenameFiles()
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
	AllTracks_Array[INDEX,"date"] := UserInput
	Sb_RefreshAllTracksandGUI()
}
return

EditAssoc:
selected := LV_GetNext(1, Focused)
if (selected > 0) {
	LV_GetText(INDEX, selected, 1) ;INDEX
	LV_GetText(RowText, selected, 3) ;assoc
	msgtext := "Please enter a new Association (Australia, UK_IRE, etc)"
	InputBox, UserInput, %msgtext%, %msgtext%, , , , , , , ,%RowText%
	AllTracks_Array[INDEX,"group"] := UserInput
	Sb_RefreshAllTracksandGUI()
}
return

EditName:
selected := LV_GetNext(1, Focused)
if (selected > 0) {
	LV_GetText(INDEX, selected, 1) ;INDEX
	LV_GetText(RowText, selected, 2) ;TrackName
	msgtext := "Please enter a new Trackname"
	InputBox, UserInput, %msgtext%, %msgtext%, , , , , , , ,%RowText%
	AllTracks_Array[INDEX,"name"] := UserInput
	AllTracks_Array[INDEX,"trackname"] := UserInput
	Sb_RefreshAllTracksandGUI()
}
return

Delete:
selected := LV_GetNext(1, Focused)
if (selected > 0) {
	LV_GetText(INDEX, selected, 1) ;INDEX
	msg("Deleting: " AllTracks_Array[INDEX,"DateTrack"])
	AllTracks_Array[INDEX,"Date"] := 20010101 ;Will be automatically purged because of old date
	Sb_RefreshAllTracksandGUI()
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
	Sb_RefreshAllTracksandGUI()
}
return
