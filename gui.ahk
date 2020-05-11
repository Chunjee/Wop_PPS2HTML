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


Gui,Add,Button,x0 y60 w43 h30 gParse,PARSE
Gui,Add,Button,x50 y60 w120 h30 gRename,RENAME FILES

Gui,Add,Button,x200 y60 w143 h30 gEditAssoc,EDIT ASSOC
Gui,Add,Button,x350 y60 w143 h30 gEditName,EDIT TRACK NAME
Gui,Add,Button,x350 y26 w143 h30 gEditString,EDIT STRING
Gui,Add,Button,x500 y60 w143 h30 gEditDate,EDIT DATE

Gui,Add,Button,x650 y60 w143 h30 gDelete,DELETE RECORD
Gui,Add,ListView,x0 y100 w800 h450 Grid vGUI_Listview, Index|Track|Assoc|Date
	; Gui, Add, ListView, x2 y70 w490 h536 Grid NoSort +ReDraw gDoubleClick vGUI_Listview, #|Status|RC|Name|Race|

Gui,Show,h600 w800, %The_ProjectName%


;Menu
Menu, FileMenu, Add, E&xit`tCtrl+Q, Menu_File-Quit
Menu, FileMenu, Add, R&estart`tCtrl+R, Menu_File-Restart
Menu, FileMenu, Add, I&nsert Track`tCtrl+I, Menu_File-CustomTrack
Menu, MenuBar, Add, &File, :FileMenu  ; Attach the sub-menu that was created above

Menu, HelpMenu, Add, &About, Menu_About
Menu, HelpMenu, Add, &Confluence`tCtrl+H, Menu_Confluence
Menu, HelpMenu, Add, View all Variables (Debug), Menu_Vars
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

Menu_Vars:
ListVars
return

Menu_File-Restart:
log.finalizeLog()
Reload

Menu_File-Quit:
GuiClose:
log.finalizeLog()
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
