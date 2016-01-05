/*
The MIT License (MIT)

Copyright (c) 2015 Dick Verweij dickydick1969@hotmail.com, d.verweij@afas.nl

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
*/
#import "ChromeCastRemoteDisplay.h"
#import <Cordova/CDV.h>

#import <GoogleCastRemoteDisplay/GCKRemoteDisplayChannel.h>
#import <GoogleCast/GCKDeviceManager.h>

#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation ChromeCastRemoteDisplay



- (void)remoteDisplayChannelDidConnect:(GCKRemoteDisplayChannel*)channel {
    GCKRemoteDisplayConfiguration* configuration = [[GCKRemoteDisplayConfiguration alloc] init];
    configuration.videoStreamDescriptor.frameRate = GCKRemoteDisplayFrameRate30p;
    
    if (![channel beginSessionWithConfiguration:configuration error:NULL]){

    }
}

- (void)remoteDisplayChannel:(GCKRemoteDisplayChannel*)channel
 deviceRejectedConfiguration:(GCKRemoteDisplayConfiguration*)configuration
                       error:(NSError*)error {
    [[ChromecastDeviceController sharedInstance] disconnect];
    
}


- (void) remoteDisplayChannel:(GCKRemoteDisplayChannel *)channel didBeginSession:(id<GCKRemoteDisplaySession>)session {
    [ChromecastDeviceController sharedInstance].remoteDisplaySession = session;
    
    _castInput = [[GCKViewVideoFrameInput alloc] initWithSession:session];
    _castInput.frameInterval = 4;
    _castInput.view = self.webView;
    
    if (callbackId != nil) {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:NO]];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId: callbackId];
        callbackId = nil;
    }
}

- (void) endCast:(CDVInvokedUrlCommand*)command {
    [[ChromecastDeviceController sharedInstance] disconnect];

    
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
    
}

- (void) startCast:(CDVInvokedUrlCommand*)command {
    [[ChromecastDeviceController sharedInstance] enableLogging];
    
    didConnect = false;
    // Set the receiver application ID to initialise scanning.
    [ChromecastDeviceController sharedInstance].applicationID = command.arguments[0];
    callbackId = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        BOOL remoteDisplayAvailable = [GCKRemoteDisplayChannel isRemoteDisplaySupported];
        NSLog(@"Cast Remote Display is %@", (remoteDisplayAvailable) ? @"supported" : @"not supported");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (remoteDisplayAvailable) {
                
                
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"CastRemoteDisplayAvailableNotification"
                 object:nil];
            } else {
              
                UIAlertView* alert =
                [[UIAlertView alloc] initWithTitle:@"Cast Remote Display is not available."
                                           message:@"iOS 8 and app support are required."
                                          delegate:nil
                                 cancelButtonTitle:@"Dismiss"
                                 otherButtonTitles:nil];
                [alert show];
            }
        });
    });
    
    [ChromecastDeviceController sharedInstance].delegate = self;
    
    // Listen for updates to the Cast status. See ChromecastDeviceManager.h.
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(chromeCastStatusUpdate)
     name:@"castScanStatusUpdated"
     object:nil];
    
    callbackId =command.callbackId;
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    [pluginResult setKeepCallback: [NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId: command.callbackId];
    
}

-(void) didConnectToDevice:(GCKDevice *)device{
    didConnect = true;
    ChromecastDeviceController *deviceController = [ChromecastDeviceController sharedInstance];
    
    // Try to initialise the Remote Display session.
    deviceController.remoteDisplayChannel = [[GCKRemoteDisplayChannel alloc] init];
    deviceController.remoteDisplayChannel.delegate = self;
    [deviceController.deviceManager addChannel:deviceController.remoteDisplayChannel];
    
}
-(void) didDisconnect{
    didConnect = false;
}
- (void) selectDevice {
    
    if (!didConnect && callbackId != nil) {
        if ([ChromecastDeviceController sharedInstance].deviceScanner.devices.count>0){
            [[ChromecastDeviceController sharedInstance] chooseDevice:self.viewController];
            
        }
    }
}

- (void) chromeCastStatusUpdate{
    
    activeDevices = [ChromecastDeviceController sharedInstance].deviceScanner.devices.count ;
    
    if (activeDevices> 0) {
        [self selectDevice];
    }
}


@end
