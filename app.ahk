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
The_VersionNumb := "4.0.0"

; GUI
#Include html-gui.ahk

; Dependencies
#Include %A_ScriptDir%\legacy_functions
#Include util-misc.ahk
#Include inireadwrite.ahk
; #Include util-array.ahk\export.ahk
#Include dateparser.ahk

; npm
#Include %A_ScriptDir%\node_modules
#Include biga.ahk\export.ahk
#Include array.ahk\export.ahk
#Include json.ahk\export.ahk
#Include neutron.ahk\export.ahk
#Include logs.ahk\export.ahk
#Include wrappers.ahk\export.ahk
#Include transformStringVars.ahk\export.ahk

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;; Startup special global variables
A := new biga()
gui_Create()

;; Make some special vars for config file date prediction
Tomorrow := A_Now
sb_IncrementDate()

;; Import and parse settings file
Settings := sb_ReadSettings()

if (!IsObject(AllTracks_Array)) {
	AllTracks_Array := []
}

;; Setup log file
if (A.isUndefined(Settings.logfiledir)) {
	Settings.logfiledir := "C:\TVG\LogFiles\"
}
log := new log_class(The_ProjectName "-" A_YYYY A_MM A_DD, Settings.logfiledir)
log.set_applicationname(The_ProjectName)
logMsgAndGui(The_ProjectName " launched from user " A_UserName " on the machine " A_ComputerName ". Version: v" The_VersionNumb)

;; Check for CommandLineArguments
AUTOMODE := false
if (A.includes(A_Args, "auto") || InStr(A_Args, "auto")) {
	AUTOMODE := true
	logMsgAndGui("Automode enabled")
}
if (A.includes(A_Args, "cleardir")) {
	Gosub, Menu_File-DeletePDFs
}


Settings.DBLocation := transformStringVars(Settings.DBLocation)
Settings.trackMappingConfig := transformStringVars(Settings.trackMappingConfig)
Settings.exportDir := transformStringVars(Settings.exportDir)
FileCreateDir(Settings.exportDir)
;; Import Existing Track DB File
FileRead, The_MemoryFile, % Settings.DBLocation
if (A.size(The_MemoryFile) > 2) {
	logMsgAndGui("Parsing " Settings.DBLocation)
	AllTracks_Array := JSON.parse(The_MemoryFile)
} else {
	logMsgAndGui("No existing DB found, creating new one at {" Settings.DBLocation "}")
	AllTracks_Array := []
}
; msgbox, % A.print(A.filter(AllTracks_Array, {"originalFilePath": "\\10.209.2.60\Incoming\trackdata\200701_79_Epp.pdf"}))


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; MAIN
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
;; Loop all pdfs and parse them
sb_ParseFiles()

; more ideal main loop
; for key, value in Settings.parsing {
; 	; input is parser and array of filepaths, output is tracks <--

; 	; input is parser, output is array of files?
; 	; input is parser, output is array of tracks?
; }

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
if (unhandledFiles.Count() > 0 && Settings.showUnhandledFiles) {
	msg("Nothing handling the following files:`n" A.join(A.uniq(A.map(unhandledFiles, A.trim)), ", ") "`n`nUpdate .\data\settings.json immediately and re-run. Renaming files by hand is NOT advised.")
}



;/--\--/--\--/--\
; Remove blacklisted tracks
;\--/--\--/--\--/
sb_RemoveBlackListedTracks(AllTracks_Array, Settings.blacklist)


; kick tracks out that are old AND refresh GUI display
sb_RefreshAllTracksandGUI()


;/--\--/--\--/--\
; JSON Generation
;\--/--\--/--\--/
sb_GenerateJSON()

;;Export DB as a JSON file
sb_GenerateDB()

if (AUTOMODE) {
	logMsgAndGui("Automatically jumping to pull files as Automode is enabled")
	sb_RenameFiles()
}

;;ALL DONE
if (AUTOMODE == true) {
	ExitApp
}
return
;/--\--/--\--/--\
; MAIN END
;\--/--\--/--\--/



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Menu Options
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Menu_File-CustomTrack:
	logMsgAndGui(A_UserName " attempting to add custom track")
	selectedfile := FileSelectFile("", A_ScriptDir, "Please select the file", "*pdf")

	msgtext := "Please enter the track name"
	InputBox, u_trackname, %msgtext%, %msgtext%
	msgtext := "Please enter the date of racing for this file in YYYYMMDD format"
	InputBox, u_date, %msgtext%, %msgtext%
	msgtext := "Please enter the association of this file (France, Sweden, UK#IRE, etc)"
	defaultText := fn_GuessAssociation(AllTracks_Array, u_trackname)
	InputBox, u_association, %msgtext%, %msgtext%, , , , , , , , % defaultText
	; l_date := fn_DateParser(u_date)
	msgtext := "Please enter the platforms for this track to appear on. Example: tvg,iowa,4njbets"
	InputBox, u_platforms, %msgtext%, %msgtext%
	u_platforms := A.replace(u_platforms, " ", "")
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

	fn_InsertData(u_association, u_trackname, u_date, selectedfile, l_platforms, l_international, "sp")
	sb_RefreshAllTracksandGUI()
return

Menu_File-DeletePDFs:
loop, Files, %A_ScriptDir%\*.pdf, 
{
	FileDelete, % A_LoopFileFullPath
}
return

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

sb_ReadSettings() {
	global

	settings_loc := A_ScriptDir "\data\settings.json"
	FileRead, The_MemoryFile, % settings_loc
	l_settings := JSON.parse(The_MemoryFile)
	The_MemoryFile := ;blank
	

	; update gui with all paths
	pathsAndAssoc := []
	for _, obj in l_settings.parsing {
		pathsAndAssoc.push(A.pick(obj, ["name", "association", "dir"]))
	}
	pathsAndAssoc := A.uniq(pathsAndAssoc)
	html := gui_generateTable(pathsAndAssoc, ["name", "association", "dir"])
	neutron.qs("#pathsOutput").innerHTML := html

	return l_settings
}


sb_ParseFiles(param_neutron:="")
{
	global

	; reload all settings
	Settings := sb_ReadSettings()

	errorStorage := []

	; reload ini track mappings
	fn_InitializeIni(transformStringVars(Settings.trackMappingConfig))
	fn_LoadIni(transformStringVars(Settings.trackMappingConfig))

	if (A.isUndefined(Settings.parsing)) { 
		logMsgAndGui(msg("No parsers found in " settings_loc " file.`n`nThe application will quit"))
		ExitApp
	}
	; clear Gui
	html := gui_generateTable([], ["trackname", "date", "group", "originalFilePath"])
	neutron.qs("#mainOutput").innerHTML := html

	;; New folder processing
	for key, value in Settings.parsing {
		; update GUI
		html := gui_genProgress(A_Index / Settings.parsing.Count())
		neutron.qs("#footerContent").innerHTML := html
		; fn_guiUpdateProgressBar("The_ProgressIndicatorBar", key / Settings.parsing.Count())

		;convert string in settings file to a fully qualifed var + string for searching
		searchdirstring := transformStringVars(value.dir "\*.pdf")
		if (value.recursive) {
			value.recursive := " R"
		}
		logMsgAndGui("Looking in " searchdirstring " for files")
		loop, Files, %searchdirstring%, % value.recursive
		{
			; skip files that return with old dates
			; Doesn't work since AUS tracks don't use full date
			; if (fn_DatePresentFuture(fn_DateParser(A_LoopFileName)) == false) {
			; 	continue
			; }

			; Skip this file if already present
			existingObj := A.filter(AllTracks_Array, {"originalFilePath": A_LoopFileFullPath})
			; msgbox, % A_LoopFileFullPath "`npre-existing: " A.print(existingObj)
			if (A.isUndefined(existingObj)) {
				continue
			}

			sb_IncrementDate(A_Now)
			The_TrackName := false
			RegExResult := fn_QuickRegEx(A_LoopFileName, transformStringVars(value.filepattern))
			;loop 7 days ahead if user is trying to use a specific date and the file wasn't already found
			if (value.weeksearch true && RegExResult = false) {
				loop, 7 {
					sb_IncrementDate()
					RegExResult := fn_QuickRegEx(A_LoopFileName, transformStringVars(value.filepattern))
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
					dateSearchText := transformStringVars(value.prependdate) A_LoopFileName
				}
				if (value.weeksearch = true) { ;parse using config specified datestring
					dateSearchText := TOM_YYYY TOM_MM TOM_DD
				}
				The_Date := fn_DateParser(dateSearchText)
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
				

				;; Pull trackname from ini lookup if specified
				if (value.configkeylookup != "") {
					vKey := A.trim(value.configkeylookup,"[]")
					trackCode := A.replace(RegExResult, "[\W*]", "")
					var := transformStringVars("%vKey%_%trackCode%")
					The_TrackName := %var%
				}
				;; Pull trackname from pdf text if specified
				if (value.pdftracknamepattern != "") {
					l_text := fn_Parsepdf(A_LoopFileFullPath)
					The_TrackName := fn_QuickRegEx(l_text, value.pdftracknamepattern)
					if (!A.isUndefined(The_TrackName)) {
						logMsgAndGui("Found the trackname: " The_TrackName " in {" A_LoopFileName "} with the RegEx {" value.pdftracknamepattern "} which was determined as not-acceptable")
					}
				}
				

				;; Re-search for trackname in pdf if specified
				if (value.relookuptrackname != "") {
					
				}


				;; Insert data if enough information collected
				; msgbox, % The_TrackName " " The_Date " " The_Country
				if (The_TrackName && The_Date && The_Country) {
					; msg("inserting: " The_TrackName "(" A_LoopFileName ")  with the assosiation: " The_Country)
					fn_InsertData(A.trim(The_Country), A.trim(The_TrackName), The_Date, A_LoopFileLongPath, value.brand, value.international, value.fileprefix)
				} else {
					; else is not handled in a seprate loop checking all files below
				}
			}
		}
	}
	; fn_guiUpdateProgressBar("The_ProgressIndicatorBar", 0)

	loop, % errorStorage.Count() {
		if (A.isUndefined(The_TrackName) && A.size(A.filter(AllTracks_Array, {"originalFilePath": A_LoopFileFullPath})) == 0) {
			errorStorage.push(A_LoopFileFullPath)
			msgbox, % A.print(A.filter(AllTracks_Array, {"originalFilePath": A_LoopFileFullPath})) " `n" A_LoopFileFullPath
			msgline := "Searched config.ini under '" value.configkeylookup "' key for '" RegExResult "' and found nothing. Update the file"
			logMsgAndGui(msgline)
			if (Settings.showUnhandledFiles != false) {
				msg(msgline)
			}
		}
	}

	logMsgAndGui("Finished checking all parsers defined in config")
}


sb_RefreshAllTracksandGUI()
{
	global

	Today := FormatTime(A_Now, "yyyyMMdd")
	;Kick Array items over 30 days old out
	AllTracks_Array := A.filter(AllTracks_Array, Func("helper_returnNewDates"))
	;Kick out duplicates 
	AllTracks_Array := sb_KickOutDuplicatesCustom(AllTracks_Array)
	;Sort all Array Content by DateTrack ; No not do in descending order as this will flip the output. Sat,Fri,Thur
	AllTracks_Array := A.sortBy(AllTracks_Array, ["trackname", "date", "group"])

	Today := FormatTime(A_Now, "yyyyMMdd")
	logMsgAndGui("Refreshing GUI display list")
	LV_Delete()

	html := gui_generateTable(AllTracks_Array, ["trackname", "date", "group", "originalFilePath"])
	neutron.qs("#mainOutput").innerHTML := html
}

sb_KickOutDuplicatesCustom(param_alltracksArray) {
	global A

	newarray := []
	temparray := []
	loop, % param_alltracksArray.Count() {
		thistrack := param_alltracksArray[A_Index]
		if (A.indexOf(temparray, thistrack.filename) == -1) {
			newarray.push(thistrack)
		}
		temparray.push(thistrack.filename)
	}
	return newarray
}


sb_RemoveBlackListedTracks(param_Alltracks, param_blacklist:="")
{
	global A

	; if a blacklist is supplied in the settings file
	if (isObject(param_blacklist)) {
		; loop into each of the blacklist settings, user may have defined one or more
		for key, value in param_blacklist {
			; find objects that match the blacklisted properties
			RemovableTracks := A.filter(param_Alltracks, value)
			; remove any matches from the larger array and re-assign
			param_Alltracks := A.difference(param_Alltracks, RemovableTracks)
			if (A.size(RemovableTracks) > 0) {
				logMsgAndGui("Blacklisted tracks found, removed")
			}
		}
	}
	return param_Alltracks
}

sb_GenerateJSON()
{
	global

	FormatTime, Today, , yyyyMMdd
	FileDelete, % A_ScriptDir "\" Settings.AdminConsoleFileName
	logMsgAndGui("Building " Settings.AdminConsoleFileName)
	data_json := []
	for l_key, l_value in AllTracks_Array {
		thistrack := l_value
		thistrack.group := StrReplace(thistrack.group, "#" , "/")
		thistrack.group := StrReplace(thistrack.group, "_" , " ")
		data_json.push(thistrack)
	}
	if (A.isUndefined(Settings.AdminConsoleFileName)) {
		Settings.AdminConsoleFileName := "data.json"
	}
	; declutter metadata
	data_json := A.map(data_json, Func("hfn_decluttermetadata"))
	FileAppend, % JSON.stringify(A.uniq(data_json)), % transformStringVars(Settings.exportDir Settings.AdminConsoleFileName)
	logMsgAndGui(Settings.AdminConsoleFileName " written to " transformStringVars(Settings.exportDir Settings.AdminConsoleFileName))
}

sb_GenerateDB()
{
	global

	Settings.DBLocation := transformStringVars(Settings.DBLocation)
	logMsgAndGui("Writing latest DB to " Settings.DBLocation)
	The_MemoryFile := JSON.stringify(AllTracks_Array)
	FileDelete, % Settings.DBLocation
	sleep, 600
	FileAppend, %The_MemoryFile%, % Settings.DBLocation
}

sb_RenameFiles(param_neutron:="", param_event:="")
{
	global

	logMsgAndGui("Pulling files and renaming...")
	; Read each track in the array and perform file renaming
	loop % AllTracks_Array.Count()
	{
		; fn_guiUpdateProgressBar("The_ProgressIndicatorBar", A_Index / AllTracks_Array.Count())
		thisTrack := AllTracks_Array[A_Index]

		; skip this item if the original file is gone (doesn't need to be renamed because it doesn't exist)
		if !FileExist(thisTrack.originalFilePath) {
			continue
		}
		; skip if there is no export dir in settings
		exportDir := transformStringVars(Settings.exportDir)
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
	; fn_guiUpdateProgressBar("The_ProgressIndicatorBar", 0)
}

;Create Directory and install needed file(s)
sb_InstallFiles()
{
	global

	FileCreateDir, %A_ScriptDir%\data\
	FileCreateDir, %A_ScriptDir%\data\Temp\
	FileInstall, data\PDFtoTEXT.exe, %A_ScriptDir%\data\PDFtoTEXT.exe, 1
}

sb_GlobalNameSpace()
{
	global

	AllTracks_Array := {Key:"", TrackName:"", DateTrack:"", FileName:""}
	AllTracks_ArraX = 1
	FirstGBLoop = 1
	;pdf parsing paths
	exepath := A_ScriptDir "\data\PDFtoTEXT.exe"
	txtpath := A_ScriptDir "\data\TEMPPDFTEXT.txt"

	tomorrow := a_now	
	tomorrow += 1, days
	formattime, tomorrowsyear, %tomorrow%, yyyy 
	formattime, tomorrow_date, %tomorrow%, yyyyMMdd
}

;Increment the date used for date searching thing. feature which I guess needs global scope -_-"
sb_IncrementDate(para_StartDate := "")
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
fn_GetWeekName(para_String) ;Example Input: "20140730"
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


fn_JustGetDate(para_String)
{
	RegExMatch(para_String, "(\d{4})(\d{2})(\d{2})", RE_TimeStamp)
	if (RE_TimeStamp1 != "") {
		l_TimeStamp = %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3%
		return %l_TimeStamp%
	}
return error
}


;Changes a correct Timestamp 20140730 to a bad one! 071314
fn_GetModifiedDate(para_String) ;Example Input: "20140730Scottsville"
{
	RegExMatch(para_String, "(\d{4})(\d{2})(\d{2})", RE_TimeStamp)
	if (RE_TimeStamp1 != "") {
		l_NewDateFormat = %RE_TimeStamp2%%RE_TimeStamp3%%RE_TimeStamp1%
		return l_NewDateFormat
	} else {
		logMsgAndGui(msg("Couldn't understand the date format of {" para_String "} Check for errors."))
	}
}


;This function inserts each track to an array that later gets sorted and exported to HTML
fn_InsertData(para_key, para_trackname, para_date, para_originalfilepath, para_brand, para_international := 1, para_prefix := "")
{
	global AllTracks_Array
	global A
	
	thisTrack := { "brand": para_brand
				 , "date": para_date
				 , "filename": fn_Filename(para_trackname, para_date, para_key, para_prefix)
				 , "group": para_key
				 , "international": para_international
				 , "name": fn_RestringExtenededAscii(para_trackname) ", " fn_GetWeekName(para_date)
				 , "string": ""

				 , "trackname": fn_RestringExtenededAscii(para_trackname)
				 , "identity": para_key para_trackname para_date
				 , "originalFilePath": para_originalfilepath }
	; Do not use the trackname if the track matches it's own key (IE Australia), only use the Weekday name
	if (thisTrack.group = para_trackname) {
		thistrack.name := fn_GetWeekName(thistrack.date)
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
	logMsgAndGui("Added track {" thisTrack.originalFilePath "} to memory")
}


; this function makes a best guess at the association of a track, else returns ""
fn_GuessAssociation(param_alltracks, param_trackname)
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

; return true for dates that are equaltoo or greater than comparisonDate (defaults to today)
fn_DatePresentFuture(param_queryDate, param_comparisonDate:="") {
	if (param_comparisonDate == "") {
		param_comparisonDate := A_Now
	}

	; prepare data
	FormatTime, OutputVar, %param_comparisonDate%, yyyyMMdd
	
	; perform
	if (OutputVar <= param_queryDate) {
		return true
	}
	if (OutputVar > param_queryDate) {
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
	exepath := A_ScriptDir "\data\PDFtoTEXT.exe"
	txtpath := A_ScriptDir "\data\pdftext.txt"
	RunWait, "%exepath%" "%para_FilePath%" "%txtpath%",, Hide
	Sleep, 250
	;;Read the Trackname out of the converted text
	FileRead, File_PDFTEXT, %txtpath%
	FileDelete, %txtpath%
	return File_PDFTEXT
}

fn_Filename(para_trackname,para_date,para_key,para_prefix)
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

fn_DownloadtoFile(para_URL)
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


;/--\--/--\--/--\--/--\--/--\
; Small functions
;\--/--\--/--\--/--\--/--\--/

hfn_decluttermetadata(obj)
{
	return biga.pick(obj, ["name", "brand", "date", "filename", "group", "international"])
}

logMsgAndGui(param_message)
{
	global log
	global neutron

	; append to log
	log.add(param_message)

	; append to gui
	liItem := neutron.doc.createElement("li")
	liItem.innerHTML := param_message
	neutron.qs("#logsOutput").appendChild(liItem)
}


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Buttons
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Parse:
AUTOMODE := false
sb_ParseFiles()
return

Rename:
sb_RenameFiles()
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
	Goto, Parse
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
	AllTracks_Array[INDEX,"name"] := UserInput
	Goto, Parse
}
return

Delete:
selected := LV_GetNext(1, Focused)
if (selected > 0) {
	LV_GetText(INDEX, selected, 1) ;INDEX
	msg("Deleting: " AllTracks_Array[INDEX,"DateTrack"])
	AllTracks_Array[INDEX,"Date"] := 20010101 ;Will be automatically purged because of old date
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



;/--\--/--\--/--\--/--\--/--\
; GUI Subroutines
;\--/--\--/--\--/--\--/--\--/

