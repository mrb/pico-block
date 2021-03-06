//
//  AppDelegate.swift
//  pblock
//
//  Created by Will Fleming on 7/9/15.
//  Copyright © 2015 PBlock. All rights reserved.
//

import UIKit
import CoreData
import ReactiveCocoa
import SafariServices

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  private var splitViewDelegate = SplitViewDelegate()

  func application(application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    UserPrefs.sharedInstance.firstRun {
      DefaultData.setup()
    }

    // setup bits of view that can't be done in UI builder
    let tabViewController = self.window!.rootViewController as? UITabBarController
    let splitViewController = tabViewController?.viewControllers?.first as? UISplitViewController
    let navController = splitViewController?.viewControllers.last as? UINavigationController
    navController?.topViewController?.navigationItem.leftBarButtonItem = splitViewController?
      .displayModeButtonItem()
    splitViewController?.delegate = splitViewDelegate

    return true
  }

  func applicationWillResignActive(application: UIApplication) {
    /* Sent when the application is about to move from active to inactive state.
     * This can occur for certain types of temporary interruptions (such as an incoming phone call
     * or SMS message) or when the user quits the application and it begins the transition to the
     * background state.
     * Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame
     * rates. Games should use this method to pause the game.
     */
  }

  func applicationDidEnterBackground(application: UIApplication) {
    /* Use this method to release shared resources, save user data, invalidate timers, and store
     * enough application state information to restore your application to its current state in case
     * it is terminated later.
     * If your application supports background execution, this method is called instead of
     * applicationWillTerminate: when the user quits.
     */
  }

  func applicationWillEnterForeground(application: UIApplication) {
    /* Called as part of the transition from the background to the inactive state; here you can
     *  undo many of the changes made on entering the background.
     */
  }

  var racsub: RACSubscriber?

  func applicationDidBecomeActive(application: UIApplication) {
    if !isTest() {
      logToGroupLogFile("app.active")
      Async.background {
        let signal = RuleUpdater.forAllEnabledSources().doUpdate().takeLast(1)
        signal.toSignalProducer().on(next: {
          if let updatedSources = $0 as? Int where updatedSources > 0 {
            ContentRulesWriter().writeRulesSignal().toSignalProducer().on(next: {
              if let writtenRules = $0 as? Int where writtenRules > 0 {
                self.refreshExtension()
              }
            }).start()
          }
        }).start()
      }
    }
  }

  func applicationWillTerminate(application: UIApplication) {
    /* Called when the application is about to terminate. Save data if appropriate.
     * See also applicationDidEnterBackground:.
     */
  }

  func refreshExtension() {
    logToGroupLogFile("app.request-extension-refresh")
    SFContentBlockerManager.reloadContentBlockerWithIdentifier(
      "com.willfleming.pblock.pblock-extension") { (error: NSError?) -> Void in
      if let err = error {
        dlog("extension rules failed to load: \(err)")
      } else {
        dlog("successfully reloaded extension rules")
      }
    }
  }
}
