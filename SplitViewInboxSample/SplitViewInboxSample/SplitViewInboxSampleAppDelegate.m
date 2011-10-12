/*
 Copyright 2009-2011 Urban Airship Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.

 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "UAViewUtils.h"
#import "UAInboxAlertHandler.h"
#import "UAInbox.h"
#import "UAInboxPushHandler.h"
#import "UAInboxMessageListController.h"

#define UA_INBOX_TR(key) [[UAInboxUI shared].localizationBundle localizedStringForKey:key value:@"" table:nil]

/**
 * This class is the default rich push UI impelementation.  When it is
 * designated as the [UAInbox uiClass], launching the inbox will cause it
 * to be displayed in a modal view controller.
 */
@interface UAInboxUI : NSObject <UAInboxUIProtocol, UAInboxPushHandlerDelegate> {
  @private
    NSBundle *localizationBundle;
	UAInboxAlertHandler *alertHandler;
    UIViewController *rootViewController;
    UAInboxMessageListController *messageListController;
    UIViewController *inboxParentController;
    BOOL useOverlay;
    BOOL isVisible;
}

/**
 * Set this property to YES if the class should display in-app messages
 * using UAInboxOverlayController, and NO if it should navigate to the
 * inbox and display the message as though it had been selected.
 */
@property (nonatomic, assign) BOOL useOverlay;

/**
 * The parent view controller the inbox will be launched from.
 */
@property (nonatomic, retain) UIViewController *inboxParentController;

@property (nonatomic, retain) NSBundle *localizationBundle;

SINGLETON_INTERFACE(UAInboxUI);

///---------------------------------------------------------------------------------------
/// @name UAInboxUIProtocol Methods
///---------------------------------------------------------------------------------------
+ (void)quitInbox;
+ (void)displayInbox:(UIViewController *)viewController animated:(BOOL)animated;
+ (void)displayMessage:(UIViewController *)viewController message:(NSString*)messageID;
+ (void)loadLaunchMessage;

///---------------------------------------------------------------------------------------
/// @name UAInboxPushHandlerDelegate Methods
///---------------------------------------------------------------------------------------
- (void)newMessageArrived:(NSDictionary *)message;

@end
#import "UAirship.h"
#import "UAInboxSplitUI.h"
#import "UAInboxMessageList.h"
#import "SplitViewInboxSampleAppDelegate.h"

@implementation SplitViewInboxSampleAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Register for notifications
    [[UIApplication sharedApplication]
     registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                         UIRemoteNotificationTypeSound |
                                         UIRemoteNotificationTypeAlert)];
    
    /*
     * Step 2a: Initialize Airship and root view controller
     */
    
    //Init Airship launch options
    NSMutableDictionary *takeOffOptions = [[[NSMutableDictionary alloc] init] autorelease];
    [takeOffOptions setValue:launchOptions forKey:UAirshipTakeOffOptionsLaunchOptionsKey];
    
    // Create Airship singleton that's used to talk to Urban Airship servers.
    // Please populate AirshipConfig.plist with your info from http://go.urbanairship.com
    [UAirship takeOff:takeOffOptions];
    
    // Set the application to use the UAInboxSplitUI we've defined here.
    [UAInbox useCustomUI:[UAInboxSplitUI class]];
    
    // Set the root view controller to the split view controller
    [self.window setRootViewController:[UAInboxSplitUI shared].splitViewController];
    
    [self.window makeKeyAndVisible];    
    
    /*
     * Step 3b: Connect the push handler delegate
     */
    
    [UAInbox shared].pushHandler.delegate = [UAInboxSplitUI shared];
    
    [UAInboxPushHandler handleLaunchOptions:launchOptions];
    
    if([[UAInbox shared].pushHandler hasLaunchMessage]) {
        [[[UAInbox shared] uiClass] loadLaunchMessage];
    }
    
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     * Step 2c: Set an icon badge number, if any.
     */
    
    UAInbox *inbox = [UAInbox shared];
    if (inbox != nil && inbox.messageList != nil && inbox.messageList.unreadCount >= 0) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:inbox.messageList.unreadCount];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    UALOG(@"APN device token: %@", deviceToken);
    // Updates the device token and registers the token with UA
    [[UAirship shared] registerDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *) error {
    UALOG(@"did Fail To Register For Remote Notifications With Error: %@", error);
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [UAirship land];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [UAInboxPushHandler handleNotification:userInfo];
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

@end
