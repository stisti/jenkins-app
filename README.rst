*********************
Jenkins in your Dock!
*********************

.. image:: http://koti.welho.com/stikka2/Jenkins-in-dock.png
   :align: right
   :alt: Jenkins icon in Dock

Are you a Mac user? Do you like Mac applications because they are easy to install, uninstall, start and stop?

Are you a Mac user who likes Jenkins? Do you find Jenkins a bit hard to install, uninstall, start and stop? Then Jenkins.app is for you.

(What is Jenkins? Jenkins is software for *continuous integration*. You can learn more about it at http://jenkins-ci.org)

Installation
=======

From ready-to-run packages:

1. Download Jenkins_NN.zip from https://github.com/stisti/jenkins-app/downloads.
2. Double-click Jenkins_NN.zip to unpack Jenkins.app.
3. (Optional) Move Jenkins.app wherever you want.
4. You're done!

Or you can also build it from the source using ant_ (which should be pre-installed on any Mac):

1. ``export BUILD_NUMBER=0 # Or any other number you want``
2. ``ant``
3. You're done!


Starting Jenkins
==========

1. Double-click on Jenkins.app
2. If this is the first time you have run Jenkins.app, it will download the actual Jenkins server software.
3. When the Jenkins server is ready to run, a dialog will be shown, asking if you want to customize the command-line used to start the Jenkins server. The command-line is explained at https://wiki.jenkins-ci.org/display/JENKINS/Starting+and+Accessing+Jenkins. You can also leave the command-line empty to go with the defaults.
4. Click on OK to start the Jenkins server.
5. Your web browser will automatically open the Jenkins UI.

Jenkins.app will remember the command-line and the next time you start, it will default to the same command-line you used the last time.

Stopping Jenkins
===========

Quit Jenkins.app. It will warn you if Jenkins is busy building something, to keep you from killing
that long build you did not know was running.

Upgrading Jenkins
=================

Jenkins project usually releases a new version every week. You can upgrade Jenkins normally in the Manage Jenkins page. Just tell Jenkins to restart itself. You do not have to stop and restart Jenkins.app. 

Jenkins.app will check if there is a newer version available every time it starts.
If you want to upgrade Jenkins.app, a browser window will open to the Jenkins.app
download site. Download the new version, unpack and drop it on the old version.

Unfortunately this will make Jenkins.app forget the last command-line. I do not yet know why this happens.

Uninstalling Jenkins
=============

Drag Jenkins.app to the Trash.

If you used Jenkins for building software, running tests and such, there are some files in ~/.jenkins that you may want to move to Trash too.

How do I make Jenkins.app start automatically?
==============================

Jenkins.app is a Mac application, and you can make any app start automatically when you log in by making it a *login item*. You do this by right-clicking on the app's Dock icon when it is running and choose to open it upon login.

If you need Jenkins.app to start automatically on boot, you need to configure one user account to automatically log in on boot. You probably also want to set up screensaver with a short idle period to prevent anyone unauthorized from using the Mac.

Why would I want to use Jenkins.app?
====================================

The official Jenkins installer for Mac sets up Jenkins as a launch daemon running under a dedicated user account. This has the advantage that it starts up automatically when the Mac boots up. It also has the disadvantage of not being able to access things in a user context, like Keychain for code signing or the Windowserver for drawing windows.

Jenkins.app runs Jenkins in your user session, so Jenkins and the processes started by Jenkins have full access to e.g. Keychain or Windowserver.

Jenkins.app is an alternative way to run Jenkins on the Mac. Or you can use the official installer. You can choose the best for your situation.


Technical details
=================

Jenkins.app is a simple AppleScript application. (Meaning, you start AppleScript Editor, create a script, then save it as application bundle.)

It is a stay-running-kind-of script. It just downloads jenkins.war, asks the user to specify the command-line and then runs ``java -jar jenkins.war``. 

Or it doesn't actually run Jenkins, it outsources the responsibility to launchd, which is better equipped to handle this anyway. An AppleScript cannot wait until a subprocess dies and then restart it. Launchd can. Another benefit is that anything written to stdout and stderr by Jenkins automatically goes to system log. (You can easily view the system log using the Console.app in /Applications/Utilities.)


TODO
====

Improvement ideas and bugs can be submitted to https://github.com/stisti/jenkins-app/issues

There are already a few and some of them are such that I think they are beyond the capability of a simple AppleScript. I may have to create an actual Cocoa app. (Although I have managed to push the AppleScript much further than I originally thought possible.)


Contact me
==========

Either open an issue like described above or contact me in Twitter. My handle is @sti. If you tweet about Jenkins.app, you might want to use #jenkinsapp hashtag.

.. _ant: http://ant.apache.org/