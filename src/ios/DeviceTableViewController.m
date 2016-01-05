// Copyright 2015 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "AppDelegate.h"
#import "DeviceTableViewController.h"

#import <GoogleCast/GCKDevice.h>
#import <GoogleCast/GCKDeviceManager.h>
#import <GoogleCast/GCKDeviceScanner.h>
#import <GoogleCast/GCKImage.h>
#import <GoogleCast/GCKMediaControlChannel.h>
#import <GoogleCast/GCKMediaInformation.h>
#import <GoogleCast/GCKMediaMetadata.h>
#import <GoogleCast/GCKMediaStatus.h>

static NSString * const kVersionFooter = @"v";

@implementation DeviceTableViewController {
  BOOL _isManualVolumeChange;
  UISlider *_volumeSlider;
  UIStatusBarStyle _statusBarStyle;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  if (_delegate.deviceScanner) {
    // Disable passive scan when we appear to get latest updates.
    _delegate.deviceScanner.passiveScan = NO;
  }
  _statusBarStyle = [UIApplication sharedApplication].statusBarStyle;
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(volumeDidChange)
                                               name:@"castVolumeChanged"
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(scanDidChange)
                                               name:@"castScanStatusUpdated"
                                             object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  if (_delegate.deviceScanner) {
    // Enable passive scan after the user has finished interacting.
    _delegate.deviceScanner.passiveScan = YES;
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[UIApplication sharedApplication] setStatusBarStyle:_statusBarStyle];
}

- (void)scanDidChange {
  [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  // Return the number of sections - section 0 is main list, section 1 is version footer.
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == 1) {
    return 1;
  }
  // Return the number of rows in the section.
  if (_delegate.deviceManager.connectionState != GCKConnectionStateConnected) {
    self.title = @"Connect to";
    return _delegate.deviceScanner.devices.count;
  } else {
    self.title =
        [NSString stringWithFormat:@"%@", _delegate.deviceManager.device.friendlyName];
    return 3;
  }
}

// Return a configured version table view cell.
- (UITableViewCell *)tableView:(UITableView *)tableView
  versionCellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdForVersion = @"version";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdForVersion
                                                          forIndexPath:indexPath];
  NSString *ver = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  [cell.textLabel setText:[NSString stringWithFormat:@"%@ %@", kVersionFooter, ver]];
  return cell;
}

// Return a configured device table view cell.
- (UITableViewCell *)tableView:(UITableView *)tableView
  deviceCellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdForDeviceName = @"deviceName";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdForDeviceName
                                                          forIndexPath:indexPath];
    
        
    GCKDevice *device = [_delegate.deviceScanner.devices
                          objectAtIndex:indexPath.row];
  cell.textLabel.text = device.friendlyName;
  cell.detailTextLabel.text = device.statusText ? device.statusText : device.modelName;
    
  return cell;
}

// Return a configured volume control table view cell.
- (UITableViewCell *)tableView:(UITableView *)tableView
    volumeCellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdForVolumeControl = @"volumeController";
  static int TagForVolumeSlider = 201;
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdForVolumeControl
                                                          forIndexPath:indexPath];

  _volumeSlider = (UISlider *)[cell.contentView viewWithTag:TagForVolumeSlider];
  _volumeSlider.minimumValue = 0;
  _volumeSlider.maximumValue = 1.0;
  _volumeSlider.value = _delegate.deviceManager.deviceVolume;
  _volumeSlider.continuous = NO;
  [_volumeSlider addTarget:self
                    action:@selector(sliderValueChanged:)
          forControlEvents:UIControlEventValueChanged];
  return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdForReadyStatus = @"readyStatus";
  static NSString *CellIdForDisconnectButton = @"disconnectButton";

  UITableViewCell *cell;

  if (indexPath.section == 1) {
    // Version string.
    cell = [self tableView:tableView versionCellForRowAtIndexPath:indexPath];
  } else if (_delegate.deviceManager.applicationConnectionState != GCKConnectionStateConnected) {
    // Device chooser.
    cell = [self tableView:tableView deviceCellForRowAtIndexPath:indexPath];
  } else {
    // Connection manager.
    if (indexPath.row == 0) {
      // Display the ready status message.
      cell = [tableView dequeueReusableCellWithIdentifier:CellIdForReadyStatus
                                             forIndexPath:indexPath];
    } else if (indexPath.row == 1) {
      // Display the volume controller.
      cell = [self tableView:tableView volumeCellForRowAtIndexPath:indexPath];
    } else if (indexPath.row == 2) {
      // Display disconnect control as last cell.
      cell = [tableView dequeueReusableCellWithIdentifier:CellIdForDisconnectButton
                                             forIndexPath:indexPath];
    }
  }

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  GCKDeviceManager *deviceManager = _delegate.deviceManager;
  GCKDeviceScanner *deviceScanner = _delegate.deviceScanner;
  if (deviceManager.applicationConnectionState != GCKConnectionStateConnected) {
    if (indexPath.row < deviceScanner.devices.count) {
      GCKDevice *device = [deviceScanner.devices objectAtIndex:indexPath.row];
      NSLog(@"Selecting device:%@", device.friendlyName);
      [_delegate connectToDevice:device];
    }
  }
  // Dismiss the view.
  [self dismiss];
}

- (void)tableView:(UITableView *)tableView
    accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"Accesory button tapped");
}

- (IBAction)disconnectDevice:(id)sender {
  [_delegate disconnect];

  // Dismiss the view.
  [self dismiss];
}

- (IBAction)dismissView:(id)sender {
  [self dismiss];
}

- (void)dismiss {
  if (self.viewController) {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

# pragma mark - volume

- (void)volumeDidChange {
  if (_volumeSlider) {
    _volumeSlider.value = _delegate.deviceManager.deviceVolume;
  }
}

- (IBAction)sliderValueChanged:(id)sender {
  UISlider *slider = (UISlider *) sender;
  NSLog(@"Got new slider value: %.2f", slider.value);
  [_delegate.deviceManager setVolume:slider.value];
}

@end