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

property commandlineArgs : ""

on logger(message)
	try
		do shell script "logger -t Jenkins.app '" & message & "'"
	end try
end logger

on run
	set path_to_wait to POSIX path of (path to resource "wait_for_jenkins.sh" in bundle (path to me))
	set path_to_war to ""
	
	tell application "Finder"
		set cache_folder to folder "Caches" of folder (path to library folder from user domain) as alias
		try
			make new folder at cache_folder with properties {name:"org.jenkins-ci.jenkins"}
		end try
		set jenkins_cache_folder to folder "org.jenkins-ci.jenkins" of folder cache_folder as alias
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
		try
			display dialog "Click OK to start downloading jenkins.war. Another dialog will appear when download has finished." buttons {"OK"} default button 1 with title "Jenkins" with icon (path to resource "Jenkins.icns" in bundle (path to me))
			set path_to_war to ((POSIX path of (jenkins_cache_folder as alias)) as text) & "jenkins.war"
			logger("downloading jenkins.war to " & path_to_war)
			do shell script "curl -sfL http://mirrors.jenkins-ci.org/war/latest/jenkins.war -o " & (quoted form of path_to_war)
		on error
			display alert "Something went wrong in downloading jenkins.war. Download it manually into " & (jenkins_cache_folder as text)
			quit
		end try
	end if
	
	
	set jenkins_is_running to true
	try
		do shell script "launchctl list org.jenkins-ci.jenkins >/dev/null"
	on error
		set jenkins_is_running to false
	end try
	
	if jenkins_is_running then
		display dialog "Found an already-running Jenkins and adopted that." with title "Jenkins" with icon (path to resource "Jenkins.icns" in bundle (path to me)) buttons {"OK"}
	else
		try
			display dialog "Run Jenkins with these arguments:" & return & "(e.g. --httpPort=N --prefix=/jenkins ... It is OK to leave it empty too.)" default answer commandlineArgs with title "Jenkins" with icon (path to resource "Jenkins.icns" in bundle (path to me))
			set commandlineArgs to (text returned of the result)
			do shell script "launchctl submit -l org.jenkins-ci.jenkins -- env SSH_AUTH_SOCK=$SSH_AUTH_SOCK java -jar " & (quoted form of path_to_war) & " " & commandlineArgs
			try
				do shell script (quoted form of path_to_wait) & " http://localhost:8080/"
				open location "http://localhost:8080/"
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
	try
		do shell script "launchctl remove org.jenkins-ci.jenkins"
	end try
	continue quit
end quit