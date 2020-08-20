;/--\--/--\--/--\--/--\--/--\
; GUI
;\--/--\--/--\--/--\--/--\--/
createGUI()
{
	global
	
	neutron := new NeutronWindow()
	neutron.load("html\index.html")
	neutron.Show("w1080 h1000")

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


fn_generateTable(param_data, param_columns:="")
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
	
	out := "<table class=""table""><thead>"
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