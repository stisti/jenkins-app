(* AppleScript wrapper for Jenkins CI server.

Because Jenkins is an application with no GUI
(other than the Web UI), this little app can be used
to easily start and stop it.

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

property jenkins_command_args : ""
property java_command_args : ""
property jenkins_url : "http://localhost:8080/"

on logger(message)
	try
		do shell script "logger -t Jenkins.app '" & message & "'"
	end try
end logger

on get_my_version()
	tell application "Finder"
		info for (path to me)
		return short version of the result
	end tell
end get_my_version

on this_is_latest_version()
	set myver to get_my_version()
	logger("Current version: " & myver)
	set latest to do shell script "curl -sfL https://github.com/downloads/stisti/jenkins-app/latest"
	logger("Latest available version: " & latest)
	if myver is less than latest then
		return false
	else
		return true
	end if
end this_is_latest_version

on busy_executors()
	try
		set n to do shell script "curl -sfk '" & jenkins_url & "/computer/api/xml?xpath=/*/busyExecutors/text()'"
		logger("Number of busy executors: " & n)
		return (n as number)
	on error eMsg number eNum
		logger("Error in busy check: " & eMsg & " (" & eNum & ")")
		return 0
	end try
end busy_executors

on set_shutdown_mode(onoff)
	if onoff then
		logger("Preparing for shutdown")
		set command to "/quietDown"
	else
		logger("Canceling shutdown")
		set command to "/cancelQuietDown"
	end if
	try
		do shell script "curl -sfk " & jenkins_url & command
	end try
end set_shutdown_mode

on run
	tell application "Finder"
		set utils to load script (path to resource "utils.scpt" in bundle (path to me))
	end tell
	set path_to_wait to POSIX path of (path to resource "wait_for_jenkins.sh" in bundle (path to me))
	set path_to_war to ""
	set path_to_icon to (path to resource "Jenkins.icns" in bundle (path to me))
	
	-- Version check might fail, so guard against it.
	try
		if this_is_latest_version() then
			logger("Update check: This Jenkins.app is the latest version")
		else
			logger("Update check: There is a newer Jenkins.app available")
			display dialog "A newer version of Jenkins.app is available. Would you like to update?" with title "Jenkins" with icon path_to_icon buttons {"Maybe later", "Update now"} default button "Update now"
			if button returned of the result is equal to "Update now" then
				open location "https://github.com/stisti/jenkins-app/downloads"
				quit
				(* To force quit to happen without continuing to the end of the handler, use the return statement to immediately return from handler. *)
				return
			end if
		end if
	end try
	
	tell application "Finder"
		-- Find Cache folder or create it if it did not exist
		try
			set cache_folder to folder "Caches" of folder (path to library folder from user domain) as alias
		on error
			set cache_folder to (make new folder at (path to library folder from user domain) with properties {name:"Caches"}) as alias
		end try
		-- Create a folder for Jenkins
		try
			set jenkins_cache_folder to folder "org.jenkins-ci.jenkins" of folder cache_folder as alias
		on error
			set jenkins_cache_folder to (make new folder at cache_folder with properties {name:"org.jenkins-ci.jenkins"}) as alias
		end try
		my logger("Jenkins cache folder is " & jenkins_cache_folder)
		
		try
			set war to file "jenkins.war" of folder jenkins_cache_folder
			-- Stupid workaround
			if exists war then
				do shell script "test -f " & (quoted form of POSIX path of (war as alias))
			end if
			set path_to_war to POSIX path of (war as alias)
			my logger("jenkins.war exists at " & path_to_war)
		on error
			try
				move file (path to resource "jenkins.war" in bundle (path to me)) to jenkins_cache_folder
				set war to the result as alias
				set path_to_war to POSIX path of (war as alias)
				my logger("jenkins.war moved from bundle to " & path_to_war)
			end try
		end try
	end tell
	
	if path_to_war is equal to "" then
		display dialog "Click OK to start downloading jenkins.war. Another dialog will appear when download has finished." buttons {"OK"} default button 1 with title "Jenkins" with icon path_to_icon
		set path_to_war to ((POSIX path of (jenkins_cache_folder as alias)) as text) & "jenkins.war"
		logger("downloading jenkins.war to " & path_to_war)
		try
			-- http://mirrors.jenkins-ci.org/war/latest/jenkins.war
			do shell script "curl -sfL http://mirrors.jenkins-ci.org/war/latest/jenkins.war -o " & (quoted form of path_to_war) & " 2>&1"
		on error err_msg number err_num
			display alert "Something went wrong in downloading jenkins.war. Download it manually into " & (jenkins_cache_folder as text) message "curl error: " & err_msg & return & "curl exit code was " & err_num
			quit
			(* To force quit to happen without continuing to the end of the handler, use the return statement to immediately return from handler. *)
			return
		end try
	end if
	
	
	set jenkins_is_running to true
	try
		do shell script "launchctl list org.jenkins-ci.jenkins >/dev/null"
	on error
		set jenkins_is_running to false
	end try
	
	if jenkins_is_running then
		display dialog "Found an already-running Jenkins and adopted that." with title "Jenkins" with icon path_to_icon buttons {"OK"}
	else
		try
			display dialog "Use these arguments for JVM:" & return & "(e.g. -Xmx2G É It is OK to leave it empty too.)" default answer java_command_args with title "Jenkins" with icon path_to_icon
			set java_command_args to (text returned of the result)
			
			display dialog "Run Jenkins with these arguments:" & return & "(e.g. --httpPort=N --prefix=/jenkins ... It is OK to leave it empty too.)" default answer jenkins_command_args with title "Jenkins" with icon path_to_icon
			set jenkins_command_args to (text returned of the result)
			
			tell utils
				set jenkins_url to create_jenkins_url from jenkins_command_args
			end tell
			
			logger("Calculated Jenkins URL: " & jenkins_url)
			
			do shell script "launchctl submit -l org.jenkins-ci.jenkins -- env SSH_AUTH_SOCK=$SSH_AUTH_SOCK java " & java_command_args & " -jar " & (quoted form of path_to_war) & " " & jenkins_command_args
			try
				do shell script (quoted form of path_to_wait) & " " & jenkins_url
				open location jenkins_url
			on error
				display alert "Unable to find Jenkins in port 8080" message "If you changed the default port, you must open the browser to Jenkins yourself." as informational
			end try
		on error errMsg number errNum
			if errNum is equal to -128 then
				quit
			else
				display alert "Failed to launch Jenkins. Sorry." message errMsg as critical
				quit
			end if
		end try
	end if
end run

on quit
	set_shutdown_mode(true)
	set b to busy_executors()
	if b is greater than 0 then
		if b is equal to 1 then
			set xxx to "There is 1 build in progress."
		else
			set xxx to "There are " & b & " builds in progress."
		end if
		display alert "Jenkins is busy building something." & return & "Are you sure you want to quit?" message xxx as critical buttons {"Quit", "Cancel", "Go to Jenkins"}
		if button returned of the result is equal to "Go to Jenkins" then
			set_shutdown_mode(false)
			open location jenkins_url
			return
		else if button returned of the result is equal to "Cancel" then
			set_shutdown_mode(false)
			return
		end if
	end if
	try
		do shell script "launchctl remove org.jenkins-ci.jenkins"
	end try
	continue quit
end quit