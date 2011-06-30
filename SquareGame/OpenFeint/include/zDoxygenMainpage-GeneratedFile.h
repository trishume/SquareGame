/** @mainpage 
<div id="header">
	<div id="container">
		<div class="logo"> 
@image html of_devSupport.png 
		</div>
    </div>
</div>
			<h3>Platform: OpenFeint iOS SDK 2.10.1</h3>
			<h4>Readme.html for OpenFeint iOS SDK 2.10.1<br>Release date 04.08.2011 <br>
				Release Notes Copyright (c) 2009-2011 OpenFeint Inc. <br>
				All Rights Reserved. 
			</h4>
			Note: A version of this README can also be obtained <a href="http://support.openfeint.com/dev/readme-for-openfeint-ios-sdk-2-10-11/">here</a>; the on-line version may have updated information not included below.
			<h3>&nbsp;&nbsp;In this document&nbsp;&nbsp;</h3>
			<ul>
				<li><a href="#new">&nbsp;&nbsp;New in OpenFeint iOS SDK Version 2.10.1&nbsp;&nbsp;</a>
				<li><a href="#req">&nbsp;&nbsp;Prerequisites</a>
				<li><a href="#qs">&nbsp;&nbsp;OpenFeint iOS Quick Start Guide&nbsp;&nbsp;</a>
				<li><a href="#releasing">&nbsp;&nbsp;Releasing your title with OpenFeint&nbsp;&nbsp;</a>
				<li><a href="#using">&nbsp;&nbsp;How To Use OpenFeint&nbsp;&nbsp;</a>
				<li><a href="#changelog">&nbsp;&nbsp;Changelog&nbsp;&nbsp;</a>
			</ul>
<a name="new"></a><h3>New in OpenFeint iOS SDK Version 2.10.1</h3>
<ul>
	<li>Enhancements to offline database security
 </ul>

<a name="req"></a><h3>Prerequisites</h3>
<ul>
	<li>XCode version 3.2.2 or newer.
	<li>Build with Base SDK of 3.0 or newer.
</ul>
<a name="qs"></a><h3>OpenFeint iOS Quick Start Guide</h3>
To start developing your first OpenFeint-enabled game on iOS:
<ol>
 <li><a href="#devEnviron">Install and configure your development environment</a>
 <li><a href="#register">Register your game on the OpenFeint developer site</a>
 <li><a href="#sampleApp">Build and run the OpenFeint Sample Application</a>
 <li><a href="#enable">OpenFeint-enable your iOS game</a>
 <li><a href="http://support.openfeint.com/dev/test-users/" >Work with test users</a>
 <li><a href="http://support.openfeint.com/dev/approval-process-ios/" >The approval process</a>
</ol>
<a name="devEnviron"></a><h4>Install and configure your development environment</h4>
<ul>
	<li>XCode version 3.2.2 or newer. (This document is directed for the most part at users of Xcode 4.0.1 or later. Some remarks for older versions of Xcode are included.)
	<li>Build with Base SDK of 3.0 or newer.
</ul>
<a name="register"></a><h4>Register your game on the OpenFeint developer site</h4>
<a name="devDash"></a>The OpenFeint Developer Dashboard is the center of activity for developers working with OpenFeint. From here you will create your free developer account, download the OpenFeint SDK, and manage server side components of your projects.
	<ol>
		<li>Go to the OpenFeint Developer Dashboard 
        	(<a href="https://api.openfeint.com/dd" target="_NEW">https://api.openfeint.com/dd</a>)
        
        <li>Register or log in<br>
			Use an email address for your identity with your chosen password.
			<p><b>Note: </b>If you are already using an email address to log in as an OpenFeint game player, you will need to use a different email address to register as a developer.
		<li>Select an existing game description or register a new one.
		<li>Browse basic features<br>
			<ul>
			  <li>Achievements and leaderboards under the <b>Features</b> tab is a great place to start.
			  <li>Go ahead and define a new achievement or leaderboard as an experiment.
			</ul>
		
	</ol>
	For detailed information about how to register your game, <a href="http://support.openfeint.com/dev/registering-games-on-the-dashboard/" target="_NEW">read this</a>.	
<h4>Download the latest OpenFeint SDK for iOS</h4>
	On the <a href="http://api.openfeint.com/dd" target="_NEW">Developer Dashboard</a> ...
		<ol>
			<li>Click the <b>Downloads</b> tab at the top of the page.
			<li>Extract the downloaded package into a directory on your development computer.
			<li>Locate OpenFeint Documentation and Support Resources<br>
				The downloaded SDK includes a reference manual that you can open by clicking <b>documentation/README.html</b>.
		</ol> 
<a name="sampleApp"></a><h4>Build and run the OpenFeint Sample Application</h4>
OpenFeint provides a sample application in the release to let you experiment with OpenFeint features and see OpenFeint best practice coding conventions before you've integrated OpenFeint into your own app. Once you do begin working with your own app, it is frequently helpful to come back to the sample app to see how individual features work and how they can best be implemented.
<br>To build the sample application:
<ol>
	<li>In the MyOpenFeintSample folder of the unzipped OpenFeint download, double-click the <b>MyOpenFeintSample.xcodeproj</b> project.  XCode will launch.
	<li>In the SampleAppDelegate folder in the XCode project, edit the file <b>MyOpenFeintSampleAppDelegate</b> as follows:<br>
	Find the lines that read:<pre>
 [OpenFeint initializeWithProductKey:<i>your_product_key_here</i> 
	andSecret:<i>your_product_secret_here</i>
	andDisplayName:@"<i>sample_app_name</i>"
	andSettings:settings
	andDelegates:delegates];
	</pre>
	Put the product key of your game into the <i>your_product_secret_here</i> string.  Put the secret key of your game into the	<i>your_product_secret_here</i> string.  Put the displayable name of your application into the <i>sample_app_name</i> string.
	<br>The result will look something like this:
	<pre>
 [OpenFeint initializeWithProductKey:@"fllglfklgklglgks" 
	andSecret:@"fldjsfjkhjg5653k3jklg"
	andDisplayName:@"example"
	andSettings:settings
	andDelegates:delegates];
	</pre>
	
	<li>Save the file.
	<li>You might want to start by building for the Simulator. If so, you might want your build settings to look something <a href="http://support.openfeint.com/images/buildSettings.png">like this</a>.
@image html buildSettings.png
	
	<li>Build.
	<li>Run.
	<li>Play with the OpenFeint Dashboard, which will look something <a href="http://support.openfeint.com/images/sampleApp.png">like this</a>.
@image html sampleApp.png
    Note that many of the features, such as Leaderboards and Achievements, must be set up in the OpenFeint Developer Dashboard (<a href="https://api.openfeint.com/dd" target="_NEW">https://api.openfeint.com/dd</a>) before you can play with them in the sample application. Other features, like Social Network Posts, won't be enabled until your app has been approved by OpenFeint. 


</ol>

<a name="enable"></a><h4>OpenFeint-enable your iOS game</h4>

To OpenFeint-enable your iOS game:
<ol>
	<li>Make sure you have the current version of OpenFeint. Unzip the file.
    <li>If you have used earlier versions of OpenFeint for this project, do the following:
        <ol>
            <li>Remove all old versions of the  app from simulators and test devices. This will help prevent mix-ups and confusion about which version of OpenFeint is being used. 
	        <li>Delete the existing group reference from your project. To do this, go to the Project navigator (file-shaped icon in upper-left corner of Xcode 4), find any <b>OpenFeint.framework</b> and <b>OpenFeintFramework</b> references and delete them. When prompted, select "delete" to delete the old versions of OpenFeint from your project's folders. This is to make sure no old versions of OpenFeint are lingering around that might accidentally get used in your project.
	        <li>Perform the "clean" operation. To do this, go to the Xcode 4 menu bar and select <b>Product->Clean</b> from the top menu bar. This is to make sure no intermediate build products based on earlier versions of OpenFeint get incorporated into your newer builds. 
        </ol>
	<li>You may add OpenFeint as a framework or as individual source files.  Choose one of these and do one of the following:
	<ul>
		  <li>Add OpenFeint as a framework:
		    <ul>
		  	  <li>Drag and drop the <b>OpenFeint.framework</b> folder into the <b>Frameworks</b> folder in the project Navigator view in XCode.
			  <li>Drag and drop the correct OFResources configuration bundle into your project in XCode.  Choose the configuration bundle based on which platforms you support:
				<ul>
			        <li>If your game is iPhone landscape only, use <b>OFResources_iPhone_Landscape.bundle</b>.
			        <li>If your game is iPhone portrait only, use <b>OFResources_iPhone_Portrait.bundle</b>.
			        <li>If your game is iPad only, use <b>OFResources_iPad.bundle</b>.
			        <li>If your game is iPhone landscape and portrait, use <b>OFResources_iPhone_Universal.bundle</b>.
			        <li>All others use <b>OFResources_Universal.bundle</b>.
			    </ul>
			  
			  <li>In <b>(your project)->Build Settings->Linking</b>, add the value <code>-all_load</code> to <b>Other Linker Flags</b>. If you make the changes at the <b>PROJECT</b> level, make sure your settings aren't overridden at the <b>TARGET</b> level: Anything done at the <b>TARGET</b> level takes precedence.
			  <li>If your app supports iOS versions less than 4.0, you must weak-link libSystem for configurations that run on the device.
                <ul>
                  <li>For Xcode 4: For all configurations found under <b>(your project)->Build Settings->Linking->Other Linker Flags</b>:
                <ol>
                <li>Click <b>Add Build Setting</b> in the lower-right corner.
                <li>Select <b>Add Conditional Setting</b>.
                <li>Change <b>Any Architecture|Any SDK</b> to <b>Any iOS SDK</b>.
                <li>Change the value to include <code>-weak_library /usr/lib/libSystem.B.dylib</code>
                <li>Again, if you make the changes at the <b>PROJECT</b> level, make sure your settings aren't overridden at the <b>TARGET</b> level.
                </ol>
                
                  <li>For Xcode 3.22:
			    <ol>
				   <li>Select <b>Other Linker Flags</b> in the build settings.
			       <li>Choose <b>Add Build Setting Condition</b> in menu in the lower-left corner.
			       <li>Change <b>Any SDK</b> to <b>Any iOS</b>
				   <li>Change the value to include <code>-weak_library /usr/lib/libSystem.B.dylib</code>
                   <li>Again, if you make the changes at the <b>PROJECT</b> level, make sure your settings aren't overridden at the <b>TARGET</b> level.
			    </ol>
               </ul> 
			  
			</ul>
		  
		  <li>Add OpenFeint as individual source files:
			  <ul>
			    <li>Drag and drop the unzipped folder titled <b>OpenFeint</b> onto your project in XCode. Make sure it's included as a group and not a folder reference.
				<li>Remove unused asset folders. This is not a necessary step but helps cut down the application size. You need to do this every time you download a new OpenFeint project.  If you are using OpenFeint as a framework, you need to delete these from OpenFeintResources.bundle.  Right-click it in Finder, and "show package contents" to navigate to the files.  If you are using OpenFeint as individual source files, you will need to delete these asset groups directly in XCode.
			      <ul>
			        <li>If your game is landscape only or iPad only delete the <b>iPhone_Portrait</b> folder.
			        <li>If your game is portrait only or iPad only delete the <b>iPhone_Landscape</b> folder.
			        <li>If your game does not support the iPad delete the <b>iPad</b> folder.
			      </ul>
			    
			  </ul>
		  
	</ul>
	
	<li>You must have a prefix header. For default project templates, Xcode places a prefix header in (yourprojectname)/Supporting Files/(yourprojectname)-prefix.pch in Project navigator. If using OpenFeint as a framework, the following line must be in the prefix header: 
<pre>
#import "OpenFeint/OpenFeintPrefix.pch"
</pre>
If you are, however, using OpenFeint as individual source files, the following line must be in the prefix header:
<pre>
#import "OpenFeintPrefix.pch"
</pre>
It is important that the spelling and capitalization match exactly. 
	
	<li>Add necessary build flags:
        <ol>
            <li>Click on your project in the Project navigator. (Xcode 3.22: Right click on your project icon in the Groups & Files pane. Select Get Info.)</li>

	   		<li>Click on the "Build Settings" tab (Xcode 3.22: Select the Build tab. Make sure you have Configuration set to <b>All Configurations</b>.)
       		<li>Add the value <code>-ObjC</code> to all configurations under <b>Linking->Other Linker Flags</b>
			 <br><b>** NOTE:</b> If the current value says <code>&lt;Multiple values&gt;</code> then you may not add the <code>-ObjC</code> flag for <b>All Configurations</b>
			 <br>**       but you must instead do it one configuration at a time.
		    
		 	<li>Make sure that <b>Call C++ Default Ctors/Dtors in Objective-C</b> is "Yes" under the <b>LLVM GCC 4.2 - Code Generation</b> section.
		     <br><b>* NOTE:</b> If you are using an older version of Xcode, you may have to add this as a player-defined setting. 
             (Set <code>GCC_OBJC_CALL_CXX_CDTORS</code> to <code>YES</code>.)
            
		</ol>
    As always, if you make Build Settings changes at the <b>PROJECT</b> level, make sure your settings aren't overridden at the <b>TARGET</b> level.
	
	<li>Make sure that the following frameworks are included in your <b>Build Phases->Link Binaries With Libraries</b>:
    <ul>
			<li><code>Foundation</code>
			<li><code>UIKit	</code>
			<li><code>CoreGraphics</code>
			<li><code>QuartzCore</code>
			<li><code>Security</code>
			<li><code>SystemConfiguration</code>
			<li><code>libsqlite3.0.dylib</code>
			<li><code>MobileCoreServices</code>
			<li><code>CFNetwork</code>
			<li><code>AddressBook</code>
			<li><code>AddressBookUI</code>
			<li><code>GameKit</code>
			<li><code>CoreLocation</code>
			<li><code>MapKit</code>
			<li><code>libz.1.2.3.dylib</code> (unless using the compiler flag <code>OF_EXCLUDE_ZLIB</code> to turn off compression of high score and cloud storage data blobs.)
		</ul>
    To add a framework in Xcode 4:
    <ol> 
    <li>Click your project icon in the Project navigator.
    <li>Click on the target in the middle column.
    <li>Click the <b>Build Phases</b> tab.
    <li>Open the <b>Link Binary With Libraries</b> section.
    <li>Click the <b>+</b> button on the lower left.
    <li>Select the framework from the alphabetical list.
    </ol>
   (Xcode 3.22: do this by right clicking on your project and selecting <b>Add->Existing Frameworks...</b>)
		
	
	<li>We recommend that you specify the latest available released version of the iOS SDK as your base SDK and specify iOS 3.0 as the deployment target so that your app will also support older devices.  Specify the base SDK in <b>Build Settings->Architectures->Base SDK</b>. Specify the deployment target in <b>Build Settings->Deployment->iOS Deployment Target</b>. (As always, if you make Build Settings changes at the <b>PROJECT</b> level, make sure your settings aren't overridden at the <b>TARGET</b> level.) OpenFeint does not support versions of iOS older than iOS 3.0.
	
	<li>If you specify a deployment target older than the base SDK, the following frameworks should use "optional linking" (Xcode 3.22: weak linking):
       <ul>
    	   <li><code>Foundation</code> 
	       <li><code>UIKit</code>
	       <li><code>MapKit</code>
	       <li><code>GameKit</code>
	   </ul>
	   To specify optional linking, click your target in the Project navigator, go to <b>Build Phases->Link Binary With Libraries</b> and adjust the Required/Optional values on the right.  
       (Xcode 3.22: To specify weak linking, right click on the build target, select the "General" tab, and in the "type" column change from "Required" to "Weak" for the selected framework.)
	
	<li>Source files that reference OpenFeint in any way must be compiled with <b>Objective-C++</b> (Use <b>.mm</b> file extension, rather than <b>.m</b>). If you are starting from one of Xcode's default project templates, you may need to change the name of <b>(Your project)AppDelegate.m</b> to <b>(Your project)AppDelegate.mm</b>.
	<li>(Optional) Install the OpenFeint docset: In the <b>Documentation</b> directory in Finder, double-click on the file <code>Run-to-Install-Docs.command</code>. Or, in a terminal window in the <b>documentation</b> directory, run <code>./InstallDocSet.sh</code>.
</ol>
<a name="releasing"></a><h4>Releasing your title with OpenFeint</h4>
To release your title with OpenFeint:
<ul>
	<li>Register an Application on api.openfeint.com
	<li>Use the ProductKey and ProductSecret for your registered application.
	<li>When launching your app, OpenFeint will print out what servers it is using to the console/log using NSLog. 
	  <br>NOTE: Make sure your application is using https://api.openfeint.com/dd
	<li>Make sure your offline configuration XML file is up to date. This file is downloadable in the developer dashboard under the
		<b>Offline</b> section. Download this file again every time you change something in the developer dashboard.
	
</ul>
<a name="using"></a><h4>How To Use OpenFeint</h4>
<h5>Initializing OpenFeint</h5> 
Initialize OpenFeint on the title screen after you've displayed any splash screens. When you first initialize OpenFeint, it 
presents a modal dialog box to conform with Apple regulations.
To initialize OpenFeint, use this function call:<br> 
<pre>[OpenFeint initializeWithProductKey:andSecret:andDisplayName:andSettings:andDelegates:];</pre>
<ul> 
	<li><code>ProductKey</code> and <code>Secret</code> are strings obtained by registering your application at <a href="https://api.openfeint.com">https://api.openfeint.com</a> 
	<li><code>DisplayName</code> is the string name we will use to refer to your application throughout OpenFeint. 
	<li><code>Settings</code> is dictionary of settings (detailed below) that allow you to customize OpenFeint. 
	<li>Delegates is a container object that allows you to provide desired delegate objects pertaining to specific OpenFeint features. 
</ul> 
 
<h5>Shutting down OpenFeint</h5> 
To  shut OpenFeint down, make the following function call:
<pre>[OpenFeint shutdown];</pre> 


<p><b>OpenFeint configuration settings</b></p> 
Settings are provided to OpenFeint as an <code>NSDictionary</code>. Here is an example of how to create a settings dictionary for use with the
initialize method:
<pre> 
NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft], OpenFeintSettingDashboardOrientation,
    @"ShortName", OpenFeintSettingShortDisplayName, 
    NSNumber numberWithBool:YES], OpenFeintSettingEnablePushNotifications,
    [NSNumber numberWithBool:NO], OpenFeintSettingDisableChat,
    nil
]; 
</pre> 
More information about each of these settings can be found below. These settings are also described in <b>OpenFeintSettings.h</b>.<br> 
<ul> 
	<li><code>OpenFeintSettingRequireAuthorization</code> -  <em>deprecated</em>. 
	<li><code>OpenFeintSettingDashboardOrientation</code> -  Specifies orientation in which the OpenFeint dashboard will appear. 
	<li><code>OpenFeintSettingShortDisplayName</code> -  In certain areas where the application display name is too long, OpenFeint uses this more compact version of your application's display name. For example, this variable is used for the title of the current game tab in the OpenFeint dashboard. 
	<li><code>OpenFeintSettingEnablePushNotifications</code> -  Specifies whether or not your application will be enabling Push Notifications (for Social Challenges, currently). 
	<li><code>OpenFeintSettingDisableChat</code> -  Allows you to disable chat for your entire application. 
</ul> 
<b>What is the <code>OFDelegatesContainer</code>? Where is the <code>OpenFeintDelegate</code>?</b><br> 
<code>OFDelegatesContainer</code> provides a way for you to specify all of the various delegates that OpenFeint features may require.
<br><br>If you are only using an <code>OpenFeintDelegate</code> you may use the simple convenience constructor:
<pre>[OFDelegatesContainer containerWithOpenFeintDelegate:];</pre> 
<h5>What is OpenFeintDelegate for?</h5> 
This is the bread-and-butter OpenFeint delegate: 
<pre>- (void)dashboardWillAppear;</pre>
This method is invoked whenever the dashboard is about to appear. We suggest that application developers use this opportunity to pause any logic / drawing while OpenFeint is displaying. 
<pre> - (void)dashboardDidAppear;</pre>  
This method is invoked when the dashboard has finished its animated transition and is now fully visible.
<pre> - (void)dashboardWillDisappear;</pre>  
This method is invoked when the dashboard is about to animate off the screen. We suggest that applications that do not use OpenGL
resume drawing in this method.
<pre> - (void)dashboardDidDisappear;</pre>  
This method is invoked when the dashboard is completed off the screen. We suggest that OpenGL applications resume drawing here, and all applications resume any paused logic / gameplay here.
<pre> - (void)playerLoggedIn:(NSString*)playerId;</pre>  
This method is invoked whenever an application successfully connects to OpenFeint with a logged in player. The single parameter is the OpenFeint player id of the logged in player.
<pre> - (BOOL)showCustomOpenFeintApprovalScreen;</pre>  
This method is invoked when OpenFeint is about to show the welcome / approval screen that asks a player if they would like to use OpenFeint. 
You can learn more about customizing the approval screen <a href="http://support.openfeint.com/dev/approval-screen-overview-for-ios/" target="_NEW">here</a>.
<h5>OFNotificationDelegate</h5> 
This delegate deals with the in-game notification pop-ups that OpenFeint displays in response to certain events including high score submission, achievement unlocks, and social challenges. 

 You can find more details in the <a href="http://support.openfeint.com/dev/notification-pop-ups-in-ios/" target="_NEW">API feature article on notification pop-ups</a>.

<h5>OFChallengeDelegate</h5>
This delegate deals with the Social Challenges API feature. You can find more details in the <a href="http://support.openfeint.com/dev/introduction-to-challenges-in-ios/" target="_NEW">Social Challenges feature article</a>.
<p><b>Launching the OpenFeint dashboard</b></p> 
The most basic launch of the OpenFeint dashboard is accomplished with a single function call:<br> 
<pre>[OpenFeint launchDashboard];</pre>
You can also launch the dashboard with a specific <code>OpenFeintDelegate</code> for use only during this launch using:<br> 
<pre>[OpenFeint launchDashboardWithDelegate:];</pre>  
In addition, OpenFeint provides a suite of methods for launching the dashboard to a pre-defined tab or page. These are documented in the header file <b>OpenFeint+Dashboard.h</b>. 
<pre> + (void)launchDashboardWithListLeaderboardsPage;</pre>  
Invoke this method to launch the OpenFeint dashboard to the leaderboard list page for your application. 
<pre> +	(void)launchDashboardWithHighscorePage:(NSString*)leaderboardId;</pre>
Invoke this method to launch the OpenFeint dashboard to a specific leaderboard page. You must pass in a string representing the unique ID of the leaderboard you wish to view which can be obtained from the Developer Dashboard.
<pre> + (void)launchDashboardWithAchievementsPage;</pre>  
Invoke this method to launch the OpenFeint dashboard to the achievements list page for your application.
<pre> + (void)launchDashboardWithChallengesPage;</pre>  
Invoke this method to launch the OpenFeint dashboard to the challenge list page for your application.
<pre> + (void)launchDashboardWithFindFriendsPage;</pre>
Invoke this method to launch the OpenFeint dashboard to the <b>Find friends</b> page, which prompts the player to use Twitter, Facebook, or a playername search to locate friends in OpenFeint.
<pre> + (void)launchDashboardWithWhosPlayingPage;</pre>  
Invoke this method to launch the OpenFeint dashboard to a page which lists OpenFeint friends who are also playing your application. 
<h5>Orientation and View Controller information</h5> 
The OpenFeint dashboard can be displayed in <em>any</em> orientation you desire. It <em>will not</em>, however, change orientations while it is being displayed.
<p>Use the <code>OpenFeintSettingDashboardOrientation</code> to control the initial orientation. If you wish to change the orientation over the course of the application, call invoke:
<pre>[OpenFeint setDashboardOrientation:];</pre>  
Generally this is done by applications which want to support multiple orientations in the UIViewController method <code>didRotateFromInterfaceOrientation:</code>.
<br>If your application is using a view controller with a non-portrait layout, you must invoke and return the following method in your 
<code>UIViewController</code>'s <code>shouldAutorotateToInterfaceOrientation</code> method.
<pre>[OpenFeint shouldAutorotateToInterfaceOrientation:withSupportedOrientations:andCount:];</pre>
<br>Here is an example implementation of <code>shouldAutorotateToInterfaceOrientation:</code> 
<pre>- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    const unsigned int numOrientations = 4;
    UIInterfaceOrientation myOrientations[numOrientations] =  { 
        UIInterfaceOrientationPortrait, UIInterfaceOrientationLandscapeLeft, 
        UIInterfaceOrientationLandscapeRight, UIInterfaceOrientationPortraitUpsideDown
    };
 
    return [OpenFeint 
        shouldAutorotateToInterfaceOrientation:interfaceOrientation 
        withSupportedOrientations:myOrientations 
        andCount:numOrientations];
}</pre> 
<hr>
<a name="changelog"></a><h4>Changelog</h4>
<hr>
Version 2.10.1
<hr>
<ul>
<li>Enhancements to offline database security
</ul>
<hr>
Version 2.10
<hr>
<ul>
<li>User-facing Parental Controls
<li>Optimized OpenFeint Threading
</ul>
<hr>
Version 2.9
<hr>
<ul>
<li>xCode4, LLVM 2.0, and LLVM GCC 4.2, compatible.
<li> Fixed spelling of <code>OFSocialNotificationApi</code> Delegate callbacks.
<li><code>didSendSocialNotification</code> (fixed).
<li>Approval process and how to build sample app info added to readme.
<li>OpenFeintSettings.h information now included in API documentation.
<li>Added static framework.
<li>Sixed some social notification bugs.
<li>Fixed a bug where shutting down OpenFeint and then losing Internet connection would crash.
<li>Fixed many many memory leaks.
<li>Fixed a crash when trying to access the keychain in OF.
<li>Fixed a bug in using '%'s in HighScores text fields.
<li>Added an example to show how to delay OpenFeint signing process.
<li>Users can now remove games from their games list.
<li>Fixed achievement display for other games <code>+ (void)forceSyncGameCenterAchievements</code> was added to <b>OFAchievement.h</b>.
<li>Typo in high scores rank fixed from 99.999+ to 99,999+.
<li>Can send from a social notification keyboard.
<li>You no longer need to be logged in to get announcements and featured games from the OpenFeint API.
<li> New threads to enhance performance of server calls and bootstrapping.
</ul>
<hr>
Version 2.8
<hr>
<ul>
<li>New Facebook API and dashboard screen.
<li> Compiles for LLVM.
<li> Made deselection of cells immediate on iPad; they now work as they work on iPhone.
<li> Published Unity sample project.
<li><code>+ (OFRequestHandle)getHighScoresNearCurrentUserForLeaderboard:(OFLeaderboard*)leaderboard andBetterCount:(uint)betterCount andWorseCount:(uint)worseCount</code> added to <b>OFHighScore.h</b>
<li> No longer have options in the settings menu for "News Feed Integration" and "Twitter" integration since everything is user-prompted before it is sent.
<li> Added the ability to share a highscore or achievements from the corresponding dashboard pages.
<li> The following functions are deprecated, and no longer need to be called from the application delegate.  We now internally listen for these events:
  <ul>
  <li><code>[OpenFeint applicationWillResignActive]</code>
  <li><code>[OpenFeint applicationDidBecomeActive]</code>
  <li><code>[OpenFeint applicationDidEnterBackground]</code>
  <li><code>[OpenFeint applicationWillEnterForeground]</code>
  </ul>
<li> Added <code>+ (OFRequestHandle*)getServerTime</code> to <b>OFTimeStamp.h</b>.
<li> Disabled location-based leaderboard screen.
</ul>

<hr>
Version 2.7.5
<hr>
<ul>
<li>The close button on the nag screens now appears on load.
<li>&lt;application name&gt; on the iPad and iPhone_landscape version of openfeint on the intro screen's "game center integration" screen is fixed to display the correct game name.
<li> Made the percent complete a double for OFAchievements (since that is how GameCenter does it).
</ul>
<hr>
Version 2.7.4, 10.11.2010 
<hr>
<ul><li>Fixed an issue where high score blobs were not being uploaded if GameCenter failed to submit, but OpenFeint successfully submitted.
<li>Fixed issues where OpenFeint was pulling some information from the servers for the dashboard when the dashboard was not open and the information wasn't needed.
<li>Show correctly formatted scores in OpenFeint Leaderboards when displaying a GameCenter score in an OpenFeint Leaderboard view.
<li>Fixed returning of request handles on some apis that were not returning OFRequestHandles properly.
<li>Fixed the getFriends api in OFPlayer so that we always return you the OFPlayer's full list of friends with no duplicates.
<li>The sample App now includes a section in which you can launch directly to dashboard pages.
<li>Magnifying glass now works on IM input field.
<li>OFNotification's text now stretches properly in landscape.
<li>The player is now only prompted to login to GameCenter at initialization of an app that supports game center, not when the app is brought back to the foreground from being in the background.
<li>If updating from pre-2.7, achievements that are unlocked won't "unlock again".
<li>OpenFeint location queries are stopped if the app goes to the background, and restarted when coming to the foreground if they were stopped.
<li>The GameCenter intro page will no longer say <b>Now Playing &lt;Application Name&gt;</b>, but will actually state the name of your game.
</ul>
<hr>
Version 2.7.3, 9.28.2010
<hr>
<ul><li>Fixed an issue with timescoped leaderboards in GameCenter updating properly.
<li>Made opening to achievements page not crash
</ul>
<hr>
Version 2.7.1 9.16.2010 
<hr>
<ul><li>Fixed an issue that was preventing GameCenter submission if the player declined OpenFeint
</ul>
<hr>
Version 2.7 9.15.2010 
<hr>
<ul>
	<li>Achievements now accept a percent complete.  Passing 100.0 as the percent complete unlocks the achievement.
	<li>Game Center is now integrated into OpenFeint.  You may now link OpenFeint Achievements and Leaderboards to GameCenter Achievements and Leaderboards.
		  See OFGameCenter.plist to see how to defining the linking between GameCenter and OpenFeint Achievements and Leaderboards.
		  Also add [NSNumber numberWithBool:YES], OpenFeintSettingGameCenterEnabled to the settings dictionary that is passed when initializing OpenFeint to enable integration.
	<li>Notification have a new look.
	<li>Notifications pop in from the top and bottom on iPhone and from the corners on iPad. Add something like this to your settings dictionary to specify where the notifications should appear:
		  <pre>NSNumber numberWithUnsignedInt:ENotificationPosition_TOP], OpenFeintSettingNotificationPosition</pre>
		  For the iPhone you should choose one of these options:
		  <ul>
			<li><code>ENotificationPosition_TOP</code>
			<li><code>ENotificationPosition_BOTTOM</code>
		  </ul>
		 
</ul>
For iPad you should choose one of these options:
<ul>
	<li><code>ENotificationPosition_TOP_LEFT</code>
	<li><code>ENotificationPosition_BOTTOM_LEFT</code>
	<li><code>ENotificationPosition_TOP_RIGHT</code>
	<li><code>ENotificationPosition_BOTTOM_RIGHT</code>
	<li>Notifications no longer Open the dashboard if the player clicks them, they accept no more input from the player.
	<li>Social notifications now have a delegate to see if posting a social notification was successful or not.
	<li>Announcements now have a field for the original posting date of the announcement (the date is actually the date of the last reply to the announcement).
	<li>Time scoped leaderboard information is now available in the dashboard.
	<li>Fixed an issue that was preventing GameCenter submission if the player declined OpenFeint
	
</ul>
<hr>
Version 2.6.1 8.26.2010 
<hr>
<ul><li>Bugfixes</ul>
<hr>
Version 2.6. 8.18.2010 
<hr>
<ul>
	<li>Time-scoped Leaderboard view
		<ul>
			<li>All Time / This week / Today replace Global / Friends / Near Me tabs
			<li>Each page shows the player's score, friends scores, and global scores in different sections.
			<li>The compass/arrow icon in the upper right launches the map view</ul>
			<li>Out of Network Invites
				<br>Players can now choose from their Contact List and send invites via SMS or E-mail
			
		</ul>
	
</ul>
<hr>
Version 2.5.1, 7.14.2010 
<hr>
<ul><li>Unity support updated for iOS4
<li>A handful of bugfixes from 2.5

</ul>
<hr>
Version 2.5, 7.2.2010 
<hr>
<ul>
	<li>New and greatly improved (fully documented) APIs for:
		<ul>
			<li>Leaderboards
			<li>Scores
			<li>Announcements
			<li>Achievements
			<li>Challenges
			<li>Cloud Storage
			<li>Invites
			<li>Featured Games
			<li>Social Notifications
			<li>Current Player & other Players
		</ul>
	
	<li>Exposes easy to use advanced features such as announcements and invitations.
	<li>Old APIs remain untouched for compatibility.
	<li>All new APIs use doxygen style comments. A doxygen docset is included in <b>documents/OpenFeint_DocSet.zip</b> for the new APIs.
	<li>Find all new api header files and documentation in the include folder. 
	<li>Sample application has been updated to showcase all of the new APIs.
	<li>Added support for "distributed scores". A new feature used to pull down a wide set of highscores to show during gameplay. See <code>OFDistributedScoreEnumerator</code>.
	
</ul>
<hr>
Version 2.4.10 (6.10.2010)
<hr>
<ul><li>Fixes for iOS4 compatibility</ul>
<hr>
Version 2.4.9 (5.28.2010)
<hr>
<ul>
	<li>Primarily a maintenance release in preparation for OpenFeint 2.5.
	<li>Bug-fixes
	
</ul>
<hr>
Version 2.4.8 (5.12.2010)
<hr>
<ul>
	<li>Fixed a crash when viewing pressing the near me tab on a leaderboard on the iPad after removing all of the iPhone asset folders
	<li>Fixed some code introduced in 2.4.7 that didn't allow you to use the "Compile as ObjC++" flag anymore.
	
</ul>
<hr>
Version 2.4.7 (5.7.2010)
<hr>
<ul>
	<li>Support for universal builds between iPhone and iPad
	<li>Support for rotating the device while in the OpenFeint dashboard on iPad
	<li>Fixed a crash bug on iPad that could occur if the game does not use a view controller
	<li>Fix a bug that caused high scores to say "Not Ranked" if the player had a score but was ranked above 100.000
	<li>Fixed lots of minor bugs 
	
</ul>
<hr>
Version 2.4.6 (4.3.2010)
<hr>
<ul>
	<li>iPad support
	<li>Minor bug fixes
	
</ul>
<hr>
Version 2.4.5 (3.16.2010)
<hr>
<ul>
	<li>There is a new setting called <code>OpenFeintSettingDisableCloudStorageCompression</code>. Set it to true to disable compression. This is global for all high score blobs.
	<li>There is a new setting called <code>OpenFeintSettingOutputCloudStorageCompressionRatio</code>. When set to true it will print the compression ratio to the console whenever compressing a blob.
	<li>High Score blobs
    	<br>Attach a blob when uploading high scores. When a player views a high score with a blob the cell has a film strip button on it. 
	      <br>Pressing the film strip button downloads the blob and passes it off to the game through the OpenFeint delegate.<br>
	
	<li>Social Invites
    	<br>Player may from the Fan Club invite his friends to download the game. The functionality can also be use directly through the OFInviteService API.
	<li>Added post count to forum thread cells
	<li>Drastically improved load times on a majority of the screens with tables in them
	<li>Some minor bug fixes
	
</ul>
<hr>
Version 2.4.4 (2.18.2010)
<hr>
<ul>
	<li>Fixed the (null) : (null) errors when submitting incorrect data in various forms
	<li>Feint Five screen supports shaking the device to shuffle 
	<li>Sample application improvements and bugfixes
	<li>Updated Unity support
	
</ul>
<hr>
Version 2.4.3 (2.3.2010)
<hr>
<ul>
	<li>Replaced our use of NSXMLParser with the significantly faster Parsifal
		  <br>Specific information about Parsifal can be found here: <b>http://www.saunalahti.fi/~samiuus/toni/xmlproc/</b>
	<li>The SDK will now compile even if you are forcing everything to be compiled as Objective-C++ (<code>GCC_INPUT_FILETYPE</code>)
	<li>Various bugfixes:
		<ul>
			<li>Crash on 2.x devices when tapping the banner before it was populated
			<li>Failure to show a notification when posting the first high score to an ascending leaderboard
			<li>Deprecation warning in OFSelectProfilePictureController when iPhoneOS Deployment Target is set to 3.1 or higher
			
		</ul>
	
</ul>
<hr>
Version 2.4.2 (1.18.2010)
<hr>
<ul>
	<li>High Score notifications will only be shown when the new score is better than the old score.
	<li>This only applies to leaderboards where 'Allow Worse Scores' is not checked
	<li>This also means that high scores that are not better will not generate a server request
	<li>'Play Challenge' button is click-able again
	<li>Updated Unity support
	<li>Other bug fixes
	
</ul>
<hr>
Version 2.4.1 (1.7.2010)
<hr>
<ul>
	<li>Portrait support is back
	<li>Bug fixes!
	<li>Improved player experience in Forums
	
</ul>
<hr>
Version 2.4 (12.17.2009)
<hr>
<ul>
	<li>New UI:<br>New clean and player-friendly look.
    <li>New simplified organization with only three tabs. One for the game, one for the player and one for game discovery.
	<li>Cloud Storage
    <li>Upload data and store it on the OpenFeint servers.
    <li>Share save data between multiple devices so the player never has to lose his progress.
	<li>Geolocation
    	<ul>
    		<li>Allows players to compete with players nearby.
		    <li>Distance-based leaderboards.
		    <li>Map view with player scores near you.
		    <li>All location-based functionality is opt-in.
			
		</ul>
	<li>Presence
	    <ul>
	    	<li>The player can immediately see when his or her friends come online through in-game notification.
		    <li>Friends page has a section for all friends who are currently online.
		    <li>All presence functionality is opt-in.
		</ul>
	<li>IM
    	<ul>
    		<li>The player can send private messages to his or her friends.
		    <li>Real-time notifications of new messages are sent through presence.
		    <li>IM page is updated in real-time allowing synchronous chat.
		    <li>Messages can be received when offline and new messages are indicated with a badge within the OpenFeint dashboard.
		    <li>Conversation history with each player is preserved the same as in the SMS app.
			
		</ul>
	<li>Forums
    	<ul>
    		<li>Players can now form a community within the game itself.
		    <li>Global, developer and game specific forums.
		    <li>Forums can be moderated through the developer dashboard.
		    <li>Players can report other players, a certain number of reports will remove a post/thread and ban the player for a time period.
		    <li>Add a thread to My Conversations to get notified of new posts in it.
			
		</ul>
	<li>My Conversations
	    <br>A single go-to place where the player can see all of his or her IM conversations and favorite forum threads.
	<li>Custom Profile Picture
    	<br>Players can now upload a profile picture from their album or take one using the camera on the device.
	<li>Ticker
    	<ul>
    		<li>The OpenFeint dashboard now has a persistent marquee at the top of the screen.
		    <li>Ticker streams interesting information and advice to the player.
			
		</ul>
	<li>Cross Promotion
    	<ul>
    		<li>Cross promote between your own games or team up with other developers to cross promote their games.
		    <li>New banner on the dashboard landing page where you can cross promote other games.
		    <li>Add games to promote from the developer dashboard.
		    <li>OpenFeint reserves the right to promote gold games through the banner.
		    <li>Games you select to cross promote will also be available through the Fan Club and through the Discovery tab.
			
		</ul>
	<li>Developer Announcements
    	<ul>
    		<li>Send out announcements about updates, new releases and more to your players directly though your game.
		    <li>New announcements will be marked with a badge in the OpenFeint dashboard.
		    <li>Announcements may be linked to a game id and will generate a buy button that linked to the iPurchase page for the game.
		    <li>Announcements are added through the developer dashboard.
			
		</ul>
	<li>Developer Newsletter
    	<ul>
    		<li>Send out email newsletters to your players from the OpenFeint developer dashboard.
		    <li>Players may opt-in to developer newsletters from the Fan Club.
			
		</ul>
	<li>Suggest a feature
	    <ul>
	    	<li>Get feedback from your players straight from the game.
		    <li>Players may give feedback and comment on feedback from the Fan Club.
		    <li>Player suggestions can be viewed in the developer dashboard where you can also respond directly to the player.
			
		</ul>
	<li>Add Game as Favorite
	    <ul>
	    	<li>Players now have a way of showing their friends which OpenFeint enabled games are their favorites.
		    <li>Players can mark a game as a favorite from the Fan Club.
		    <li>The My Games tab has a new section for favorite games.
		    <li>When looking at a list of a friend's games; favorites are starred.
		    <li>When marking a game as favorite, players are asked to comment on why it's a favorite.
		    <li>When looking at an iPurchase page for a favorite game owned by a friend, comments on why the game is a favorite are displayed.
			
		</ul>
	<li>Discovery Tab
    	<ul>
    		<li>The third tab is now the game discovery tab. This is a place where players can come to find new games.
		    <li>Friends Games section lists games owned by the player's friends.
		    <li>The Feint Five section lists five random games. Press shuffle to list five new games.
		    <li>OpenFeint News provides news about the network.
		    <li>Featured games lists games featured by OpenFeint.
		    <li>More Games lists a larger group of games in the OpenFeint network.
		    <li>Developer Picks section lists games featured by the developer of the game being played.
			
		</ul>
	<li>Option to display OpenFeint notifications at the top of the screen instead of the bottom.
    	<br>Set <code>OpenFeintSettingInvertNotifications</code> to true when initializing OpenFeint to show notifications from top.
	<li>Automatically posting to Facebook and Twitter when unlocking an achievement is turned off by default.
    <li>Set <code>OpenFeintSettingPromptToPostAchievementUnlock</code> to true to enable automatic posting of social notifications.
	
</ul>
<hr>
Version 2.3 (10.05.2009)
<hr>
	<ul>
		<li>Multiple Accounts Per Device
		    <ul>
		    	<li>Multiple OpenFeint accounts may be attached to a single device.
			    <li>When starting a new game, player may choose which player to log in as if there are multiple players attached to his device
			    <li>When player switches account from the settings tab, he will be presented with a list of accounts tied to the device if there is more than one
			    <li>Facebook/Twitter may be tied to more than one account
			    <li>Player will no longer get an error message when trying to attach Facebook/Twitter to an account if that Facebook/Twitter account has already been used by OpenFeint.
				
			</ul>
		
		<li>Select Profile Picture Functionality
		    <br>From the settings tab, player can choose between profile picture from Facebook, Twitter and the standard OpenFeint profile picture.
		
		<li>Remove Account From Device
		    <br>Player can completely remove an account from the current device if he wants to sell his device etc.
		
		<li>Create New Player
		    <br/>From the OpenFeint intro flow or the Switch Player screen, the player may choose to create a new OpenFeint account.
		
		<li>Log Out
	    
	    <li>Player may from the settings tab log out of OpenFeint for the current game. When logged out OpenFeint will act as if you said no to OpenFeint in the first place and not make any server calls.
		
		<li>Remove Facebook/Twitter
		    <br>Option on the settings tab to disconnect Facebook or Twitter from the current account
		
	</ul>
<hr>
Version 2.2 (9.29.2009)
<hr>
<ul>
	<li>Game Profile Pages accessible for any game from any game. Game Profile Page allows you to:
	    <ul>
	    	<li>View Leaderboards
		    <li>View Achievements
		    <li>View Challenges
		    <li>Find out which of your friends are playing
			<li>Player Comparison. Tap 'Compare with a Friend' to see how you stack up against your OpenFeint friends!
		    <li>Browsing into a game profile page through another player's profile will default to comparing against that player.
		    <li>Game Profile page comparison shows a breakdown of the results for achievements, leaderboards and challenges
		    <li>Achievements page shows unlocked achievements for each player
		    <li>Challenges page shows pending challenges between the two players, number of won challenges/ties for each player and challenge history between the two players.
		    <li>Leaderboards page shows the result for each player for each leaderboard.
			
		</ul>
	
	<li>Unregistered player support. Now you can let OpenFeint manage all of your high score data!
    
    <li>Players who opt-out of OpenFeint can still open the dashboard and view their local high scores.
    
    <li>When the player signs up for OpenFeint, any previous scores are attributed to the new player.
	    <br><b>NOTE: </b>To implement this functionality, you <b>must</b> download an offline configuration XML file and add it to your project. You can download this file from the developer dashboard under the <b>Offline</b> section.
    	 See <a href="http://support.openfeint.com/dev/offline-support-for-ios/">http://support.openfeint.com/dev/offline-support-for-ios/</a> for more information. 
	
	<li>Improved offline support:
    	<ul>
    		<li>More obvious when a player is using OpenFeint in offline mode.
		    <li>Player no longer need has to be online once for offline leaderboards to work.
			
		</ul>
	
	<li>Improved friends list. 
    	 <br>Friends list now shows all friends in a alphabetical list.
	
</ul>
<hr>
Version 2.1.2 (9.09.2009)
<hr>
<ul>
	<li>Fixed an issue with OpenFeint not initializing properly when player says no to push notifications
	
</ul>
<hr>
Version 2.1.1 (8.28.2009)
<hr>
<ul>
	<li>Fixed compiling issues with Snow Leopard XCode 3.2
	
</ul>
<hr>
Version 2.0.2 (7.22.2009)
<hr>
<ul>
	<li>Added displayText option to highscores. If set this is displayed instead of the score (score is still used for sorting).
	<li>Removed status bar from the dashboard.
	<li>Fixed bug that showed a few black frames when opening the OpenFeint dashboard form an OpenGL game.
	
</ul>
<hr>
Version 2.0.1 (7.13.2009)
<hr>
<ul>
	<li>Improved OpenFeint "Introduction flow".
	<li>Player may set their name when first getting an account.
	<li>Player may import friends from Twitter or Facebook at any time.
	<li>Nicer landing page in the dashboard encourages player to import friends until he has some.
	<li>Fixed compatibility issues with using the 3.0 base sdk and 2.x deployment targets.
	
</ul>

<hr>
Version 2.0 (6.29.2009)
<hr>
<ul>
	<li>Friends:
		<ul>
			<li>A player can import friends from Twitter and Facebook.
			<li>A player can see all of his or her friends in one place.
			<li>Feint Library: A player can see all the games they've played in once place.
			<li>Social Player Profiles:
				<br>A player can see the name and avatar of the profile owner:
				<ul>
					<li>A player can see all the games the profile owner has played.
					<li>A player can see all the friends the profile owner has.
					
				</ul>
			
			<li>Achievements:
				<ul>
					<li>A developer can add up to 100 achievements to a game.
					<li>Each player has a gamerscore and earns points when unlocking achievements.
					<li>Achievements can be compared between friends for a particular game.
					<li>If a player does not have any achievements to be compared, there is an iPromote Page link with a call to action prominantly visible
					<li>Achievements can be unlocked by the game client when on or offline.
					  <br>	Achievements unlocked offline are syncronized when next online.
					
				</ul>
			<li>Friend Leaderboards:
				<ul>
					<li>	A leaderboard can be sorted by friends.
					<li>	Player avatars are visible on the leaderboard.
					
				</ul>
			
			<li>Chat Room:
				<ul>
					<li>Each chat message has a player's profile avatar next to it.
					<li>	Each chat message has some kind of visual representation of the game they are using.
					<li>	Clicking on a person's chat message takes you to their profile.
					<li>Chat Room Moderation:
						<ul>
							<li>A player report can optionally include a reason
							<li>A player can click <b>Report this player</b> on a player's profile.
							<li>A developer can give Moderator privileges to up to 5 players from the dashboard.
							<li>When a player has been flagged more than a certain number of times, they are not allowed to chat for a relative amount of time.
							<li>If a moderator reports a player, the player is immediately flagged.
						</ul>
					
				</ul>
			
		</ul>
	
	<li>Fixed iPhone SDK 3.0 compatibility issues.
	<li>Many bugfixes.
	<li>Lots of player interface changes.
	<li>Lots of Perforamnce improvements.
	<li>Fixed compatibility with iPod Music Picker.
	<li>Fixed glitch visual glitch in landscape when running on a 2.0 device and building with the 3.0 SDK
	
</ul>
<hr>
Version 1.7 (5.29.2009)
<hr>
<ul>
	<li>Simplified account setup
	<li>Players can access OpenFeint without setting up an account
	<li>Login is only required once per device instead of per app
	<li>3.0 compatibility fixes
	<li>Various bug fixes
	
</ul>
<hr>
Version 1.7 (5.22.2009)
<hr>
<ul>
	<li>Simplified account setup
	<li>Players can access OpenFeint without setting up an account
	<li>Login is only required once per device instead of per app
	<li>3.0 compatibility fixes
	<li>Various bug fixes
	
</ul>
<hr>
Version 1.6.1 (5.13.2009)
<hr>
<ul><li>OpenFeint works properly on 3.0 devices.</ul>
<hr>
Version 1.6 (4.29.2009)
<hr>
<ul>
	<li>Dashboard now supports landscape (interface orientation is a setting when initializing OF).
	<li>OpenFeint can now be compiled against any iPhone SDK version
	<li>Various minor bug-fixes
	
</ul>
<hr>
Version 1.5 (4.21.2009) 
<hr>
<ul>
	<li>One Touch iPromote
	<li>Keyboard can now be toggled in the chat rooms
	<li>Greatly improved performance and memory usage of chat rooms
	<li>Profanity Filter is now even more clean.
	<li>Massive scale improvements
	<li>Improved internal analytics for tracking OF usage
	<li>Player conversion rate tracking (view, buy, return)
	<li>Various minor bug-fixes
	
</ul>
<hr>
Version 1.0 (3.26.2009)
<hr>
<ul>
	<li>Players can login with their Facebook accounts (using FBConnect)
	<li>Every player now has proper account "settings"
	<li>Global "publishing" permissions are now present on account creation screens
	<li>Chat scrolling now works properly in 2.0, 2.1, 2.2, and 2.2.1.
	<li>DashboardDidAppear delegate implemented by request
	
</ul>

<hr>
Version 3.20.2009
<hr>
<ul>
	<li>Players can login with other account containers (Twitter)
	<li>Added global, developer, and game lobbies
	<li>Developer and game rooms can be configured from developer website
	<li>Account error handling improved
	<li>Polling system improvements: remote throttling, disabled when device locks
	<li>Improved versioning support
	<li>Leaderboard values can be 64 bit integers (requested feature!)
	<li>Removed profile screens
	<li>Added Settings tab with Logout button
	<li>Final tab organization and art integration
	<li>Lots of minor bug fixes and tweaks
	
</ul>
<hr>
Version 3.15.2009
<hr>
<ul>
	<li>Out of dashboard background notifications
	<li>Multiple leaderboards for each title (configurable via web site)
	<li>Landscape keyboard issue addressed
	<li>Startup time significantly reduced
	<li>Multi-threaded API calls now work properly
	<li>Added profanity filter to server
	<li>Basic request based version tracking
	<li>Now using HTTPS for all data communication
	
</ul>
<hr>
Version 3.10.2009
<hr>
<ul>
	<li>Robust connectivity and server error handling
	<li>Integration protocol no longer requires all callbacks
	<li>Various Bugfixes
	
</ul>
<hr>
Version 3.6.2009
<hr>
<ul>
	<li>Each game has a dedicated chat room
	<li>First implementation of background alerts
	<li>Framework preparation for future features
	<li>Framework enhancements for table views
	
</ul>
<hr>
Version 3.3.2009
<hr>
<ul>
	<li>First pass at Leaderboards ("Global" and "Near You")
	<li>Tabbed Dashboard with temporary icons
	<li>OFHighScore API for setting high score
	<li>OpenFeintDelegate now works
	<li>OpenFeint api changed to allow a per-dashboard delegate
	<li>Automatically prompt to setup account before submitting requests
	<li>Placeholder in-game alerts
	<li>Better offline and error support
	<li>Smaller library size (AuroraLib has been mostly removed)
	
</ul>
<hr>
Version 2.25.2009
<hr>
<ul>
	<li>First draft public API
	<li>Placeholder profile
	<li>Placeholder Dashboard
	<li>Account create, login, and logout 
	
</ul>
*/
