Chromecast remote display (IOS) plugin for Cordova
==========================
This plugin will cast your cordova app to a chromecast

Requirements
-------------
- iOS 8 or higher
- Cordova 3.0 or higher

    Installation
-------------
    cordova plugin add nl-afas-cordova-plugin-chromecastremotedisplay

	(assuming you installed cocoapods)

	add a "Podfile" to your platforms/ios folder with following contents:

	-----------------
	platform :ios, '8.0'
	
	pod 'google-cast-sdk'
	pod 'google-cast-remote-display-sdk'
	-----------------

	run "pod install"



Usage
------
   
    cordova.plugins.CordovaChromeCastRemoteDisplay.startCast(publishId); 
	// this will show the selection screen and casting will start after selection
	// you need to have a published chrome cast remote display app. See https://developers.google.com/cast/docs/registration

	cordova.plugins.CordovaChromeCastRemoteDisplay.endCast();
	// end the cast
	

LICENSE
--------
The MIT License (MIT)

Copyright (c) 2015 dickydick1969@hotmail.com Dick Verweij AFAS Software BV - d.verweij@afas.nl

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
