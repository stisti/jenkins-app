*********************
Jenkins in your Dock!
*********************

.. image:: http://koti.welho.com/stikka2/Jenkins-in-dock.png
   :align: right
   :alt: Jenkins icon in Dock

Are you a Mac user? Do you like Mac applications because they are easy
to install, uninstall, start and stop?

Are you a Mac user who likes Jenkins? Do you find Jenkins a bit hard
to install, uninstall, start and stop? Then Jenkins.app is for you.

(What is Jenkins? Jenkins is software for 
*continuous integration*. You can learn more about it at http://jenkins-ci.org)


News
====

Jenkins.app is not properly codesigned, which prevents you from running it on 
10.8 Mountain Lion. The workaround is to right-click Jenkins.app and choose Open.

Builds < 49 have a partial (and thus broken) codesignature, which prevents even the 
right-click open from working. Build 49 has been properly codesigned, but until I cough
up $99 for Apple, we have to settle for a self-signed signature.

I am finally convinced ant was a poor choice for a build tool. Ant is gone, make is 
the new ant.

Installation
=======

From ready-to-run packages:

1. Download Jenkins_NN.zip from http://jenkins-app.s3-website-eu-west-1.amazonaws.com/.
2. Double-click Jenkins_NN.zip to unpack Jenkins.app.
3. (Optional) Move Jenkins.app wherever you want.
4. You're done!

Or you can also build it from the source using make:

1. ``make``
2. You're done!


Starting Jenkins
==========

1. Double-click on Jenkins.app
2. If this is the first time you have run Jenkins.app, it will
   download the actual Jenkins server software.
3. When the Jenkins server is ready to run, a dialog will be shown,
   asking if you want to customize the JVM options. This is where you
   can increase heap size or set jmx ports.
4. Next, another dialog is shown asking if you want to customize the
   command-line used to start the Jenkins server. The command-line is
   explained at
   https://wiki.jenkins-ci.org/display/JENKINS/Starting+and+Accessing+Jenkins. You
   can also leave the command-line empty to go with the defaults.
5. When Jenkins is up and running, your web browser will automatically open the Jenkins UI.

All the dialogs above wait for your input for maximum of 15
seconds. This makes it possible to start Jenkins.app automatically and
unattended.

Jenkins.app will remember the JVM and command-line settings and the
next time you start, it will default to the same command-line you used
the last time.

Stopping Jenkins
===========

Quit Jenkins.app. It will warn you if Jenkins is busy building
something, to keep you from killing that long build you did not know
was running.

Upgrading Jenkins
=================

Because Jenkins.app is just a front-end for the actual Jenkins server,
they are updated independently of each other.

The Jenkins project usually releases a new version every week. You can
upgrade Jenkins normally in the Manage Jenkins page. Just tell Jenkins
to restart itself. You do not have to stop and restart Jenkins.app.

Jenkins.app will check for new version of itself every time it starts.
If there is a new version available, a prompt will appear.  If you
want to upgrade Jenkins.app, a browser window will open to the
Jenkins.app download site. Download the new version, unpack and drop
it on the old version.


Uninstalling Jenkins
=============

Drag Jenkins.app to the Trash.

If you used Jenkins for building software, running tests and such,
there are some files in ~/.jenkins that you may want to move to Trash
too.

How do I make Jenkins.app start automatically?
==============================

Jenkins.app is a Mac application, and you can make any app start
automatically when you log in by making it a *login item*. You do this
by right-clicking on the app's Dock icon when it is running and choose
to open it upon login.

If you need Jenkins.app to start automatically on boot, you need to
configure one user account to automatically log in on boot. You
probably also want to set up screensaver with a short idle period to
prevent anyone unauthorized from using the Mac.

Why would I want to use Jenkins.app?
====================================

The official Jenkins installer for Mac sets up Jenkins as a launch
daemon running under a dedicated user account. This has the advantage
that it starts up automatically when the Mac boots up. It also has the
disadvantage of not being able to access things in a user context,
like Keychain for code signing or the Windowserver for drawing
windows.

Jenkins.app runs Jenkins in your user session, so Jenkins and the
processes started by Jenkins have full access to e.g. Keychain or
Windowserver.

Jenkins.app is an alternative way to run Jenkins on the Mac. Or you
can use the official installer. You can choose the best for your
situation.

Security considerations
=======================

Jenkins is executes commands as you and the commands can be controlled
using the Jenkins web UI. This is a security nightmare, unless you
trust the network where your Mac sits and everyone in that network.

What can you do? 

First, you could create a dedicated user account for running
Jenkins. If you enable fast user switching, you can continue using
your Mac while Jenkins runs as another user.

If you are the only one who needs to use Jenkins, you could tell
Jenkins to bind to loopback interface only:
``--httpListenAddress=127.0.0.1``

If Jenkins needs to be usable to people on the network, you can turn
on Jenkins security, forcing people to log in before they can see
interesting things or make any changes. You can even assign people to
groups that have various permissions. See 
https://wiki.jenkins-ci.org/display/JENKINS/Securing+Jenkins for the
details. 

For extra security, you could do both of the above and run a reverse
proxy, which controls access to Jenkins. Proxy servers often have more
sophisticated access control mechanisms than Jenkins has.

A sample Apache config file for setting up such a proxy would be
something like:

::

  ProxyPass         /jenkins  http://localhost:8080/jenkins
  ProxyPassReverse  /jenkins  http://localhost:8080/jenkins
  ProxyRequests     Off
  <Proxy http://localhost:8080/jenkins*>
    Order allow,deny
    Allow from localhost
    Allow from 192.168.1
    Allow from .local
  </Proxy>

You could combine this with Jenkins command line:

::

  --httpListenAddress=127.0.0.1 --ajp13Port=-1 --prefix=/jenkins

There is no need to disable HTTPS port, because it is disabled by
default. The ``--prefix`` is needed to for Jenkins to operate
correctly after it is no longer at the root of the server.


Tips
====

If you want to move JENKINS_HOME directory (the directory where
Jenkins keeps the builds and job configurations), you can do it
by setting ``JENKINS_HOME`` environment variable. Because Jenkins.app
uses launchd to run Jenkins, you must ask launchd to set ``JENKINS_HOME``.

::

  launchctl setenv JENKINS_HOME /new/path/to/jenkins_home

You have to do it before starting Jenkins.app.


Technical details
=================

Jenkins.app is a simple AppleScript application. (Meaning, you start
AppleScript Editor, create a script, then save it as application
bundle.)

It is a stay-running-kind-of script. It just downloads jenkins.war,
asks the user to specify the command-line and then runs 
``java -jar jenkins.war``.

Or it doesn't actually run Jenkins, it outsources the responsibility
to launchd, which is better equipped to handle this anyway. An
AppleScript cannot wait until a subprocess dies and then restart
it. Launchd can. Another benefit is that anything written to stdout
and stderr by Jenkins automatically goes to system log. (You can
easily view the system log using the Console.app in
/Applications/Utilities.)


TODO
====

Improvement ideas and bugs can be submitted to
https://github.com/stisti/jenkins-app/issues

There are already a few and some of them are such that I think they
are beyond the capability of a simple AppleScript. I may have to
create an actual Cocoa app. (Although I have managed to push the
AppleScript much further than I originally thought possible.)


Contact me
==========

Either open an issue like described above or contact me in Twitter. My
handle is @sti. If you tweet about Jenkins.app, you might want to use
#jenkinsapp hashtag.
