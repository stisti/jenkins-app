(* Utility methods for Jenkins.app

Copyright (c) 2011, 2012 Sami Tikka

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE. *)

to make_list of string_arg by separator
	set old_delims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to separator
	set string_as_list to every text item of string_arg
	set AppleScript's text item delimiters to old_delims
	return string_as_list
end make_list

on parsed_command_line from jenkins_command_line
	set return_args to {httpPort:"8080", httpsPort:"-1", prefix:"/"}
	
	set list_of_args to (make_list of jenkins_command_line by " ")
	
	repeat with one_arg in list_of_args
		if one_arg starts with "--httpPort=" then
			set httpPort of return_args to (item 2 of (make_list of one_arg by "="))
		else if one_arg starts with "--httpsPort=" then
			set httpsPort of return_args to (item 2 of (make_list of one_arg by "="))
		else if one_arg starts with "--prefix=" then
			set prefix of return_args to (item 2 of (make_list of one_arg by "="))
		end if
	end repeat
	
	return return_args
end parsed_command_line

to create_jenkins_url from jenkins_command_line
	set parsed_args to parsed_command_line from jenkins_command_line
	if httpPort of parsed_args is not equal to "-1" then
		set jenkins_url to "http://localhost:" & httpPort of parsed_args
	else
		set jenkins_url to "https://localhost:" & httpsPort of parsed_args
	end if
	set jenkins_url to jenkins_url & prefix of parsed_args
	if jenkins_url does not end with "/" then
		set jenkins_url to jenkins_url & "/"
	end if
	return jenkins_url
end create_jenkins_url

on save_prefs(plistfile_path, prefs)
	tell application "System Events"
		set the parent_dictionary to make new property list item with properties {kind:record}
		--		set the plistfile_path to "~/Library/Preferences/org.jenkins-ci.jenkins.plist"
		set pl to make new property list file with properties {contents:parent_dictionary, name:plistfile_path}
		tell pl
			make new property list item at end with properties {kind:string, name:"java_command_args", value:(java_command_args of prefs)}
			make new property list item at end with properties {kind:string, name:"jenkins_command_args", value:(jenkins_command_args of prefs)}
		end tell
	end tell
end save_prefs

on get_prefs(plistfile_path)
	try
		tell application "System Events"
			set plf to property list file (plistfile_path)
			return value of plf
		end tell
	on error
		return {java_command_args:"", jenkins_command_args:""}
	end try
end get_prefs

-- Unit tests (execute by hitting cmd+R)
on run
	set as_list to make_list of "a b c" by " "
	if as_list is not equal to {"a", "b", "c"} then
		error "make_list (basic case) does not work: " & (as_list as string)
	end if
	
	set parsed_args to parsed_command_line from ""
	if parsed_args is not equal to {httpPort:"8080", httpsPort:"-1", prefix:"/"} then
		error "parsed_command_line does not work" & (parsed_args as string)
	end if
	
	set parsed_args to parsed_command_line from "--httpPort=80 --prefix=/jenkins"
	if parsed_args is not equal to {httpPort:"80", httpsPort:"-1", prefix:"/jenkins"} then
		error "parsed_command_line does not work" & (parsed_args as string)
	end if
	
	set parsed_args to parsed_command_line from "--httpPort=-1 --httpsPort=8443 --prefix=/jenkins"
	if parsed_args is not equal to {httpPort:"-1", httpsPort:"8443", prefix:"/jenkins"} then
		error "parsed_command_line does not work" & (parsed_args as string)
	end if
	
	if (create_jenkins_url from "") is not equal to "http://localhost:8080/" then
		error "create_jenkins_url does not work"
	end if
	
	if (create_jenkins_url from "--httpPort=80 --prefix=/jenkins") is not equal to "http://localhost:80/jenkins/" then
		error
	end if
	
	if (create_jenkins_url from "--httpsPort=8443 --httpPort=-1 --prefix=/jenkins") is not equal to "https://localhost:8443/jenkins/" then
		error
	end if
	
	set java to "abc"
	set jenkins to "def"
	save_prefs("/tmp/jenkins-app-unit-prefs.plist", {java_command_args:java, jenkins_command_args:jenkins})
	set dict to get_prefs("/tmp/jenkins-app-unit-prefs.plist")
	
	if (java_command_args of dict) is not equal to java then
		error java & " is not " & (java_command_args of dict)
	end if
	
	if (jenkins_command_args of dict) is not equal to jenkins then
		error jenkins & " is not " & (jenkins_command_args of dict)
	end if
	
	set dict2 to get_prefs("/tmp/jenkins-app-unit-not.plist")
	
	if (java_command_args of dict2) is not equal to "" then
		error "java_command_args should have been empty"
	end if
	
	if (jenkins_command_args of dict2) is not equal to "" then
		error "jenkins_command_args should have been empty"
	end if
end run