;/--\--/--\--/--\--/--\--/--\
; GUI
;\--/--\--/--\--/--\--/--\--/
gui_Create()
{
	global

	neutron := new NeutronWindow()
	neutron.load("html\index.html")
	neutron.Show("w2080 h1000")
	neutron.Maximize()

}


nc_btnClose(neutron)
{
	global log

	log.add("GUI closed by user. Exiting.")
	log.finalizeLog()
	WinClose, % "ahk_id" neutron.Close()
	Exitapp
}


nr_setByID(para_id, param_html)
{
	global neutron

	try {
		neutron.qs(para_id).innerHTML := param_html
	}
	catch {
		return false
	}
	return true
}


gui_generateTable(param_data, param_columns:="", param_style:="table-bordered table-striped")
{
	static nw := NeutronWindow

	if !param_columns
	{
		param_columns := []
		for _, object in param_data {
			for key, value in object {
				if (param_columns.indexOf(key) = -1) {
					param_columns.push(key)
				}
			}
		}
	}

	out := "<table class=""table " param_style " ""><thead class=""thead-dark"">"
	for _, title in param_columns
		out .= nw.FormatHTML("<td>{}</td>", title)
	out .= "</thead>"

	out .= "<tbody>"
	for y, row in param_data
	{
		out .= "<tr>"
		for _, title in param_columns
			out .= nw.FormatHTML("<td>{}</td>", row[title])
		out .= "</tr>"
	}
	out .= "</tbody></table>"

	return out
}


gui_genProgress(param_fill, param_style:="")
{
	progressPercent := param_fill * 100
	if (progressPercent >= 100) {
		return "<div></div>"
	}
	return "<div class=""progress""><div class=""progress-bar progress-bar-striped progress-bar-animated"" " param_style "role=""progressbar"" style=""width: " progressPercent "%"" aria-valuemin=""0"" aria-valuemax=""100""></div></div>"
}


btn_Parse(param_neutron:="", param_event:="")
{
	AUTOMODE := false
	sb_ParseFiles()
	sb_GenerateJSON()
}

btn_Rename(param_neutron:="", param_event:="")
{
	sb_RenameFiles()
	sb_GenerateJSON()
}

btn_HandleCustomTrack(param_neutron:="", param_event:="")
{
	sb_HandleCustomTrack()
	sb_GenerateJSON()
}

btn_DeletePDFs(param_neutron:="", param_event:="")
{
	loop, Files, %A_ScriptDir%\*.pdf
	{
		FileDelete, % A_LoopFileFullPath
	}
}

nc_btnOpenLogs(param_neutron:="") {
	global log

	explorerpath:= log.logDir
	Run, %explorerpath%
}
