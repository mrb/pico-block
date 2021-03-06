//
//  UserPrefs.swift
//  pblock
//
//  Created by Will Fleming on 8/22/15.
//  Copyright © 2015 PBlock. All rights reserved.
//

import Foundation

class UserPrefs {
  static let sharedInstance = UserPrefs()

  private let defaults = NSUserDefaults.standardUserDefaults()
  private let firstRunKey = "hasRun"

  func firstRun(fn: () -> Void) {
    if !defaults.boolForKey(firstRunKey) {
      defaults.setBool(true, forKey: firstRunKey)
      defaults.synchronize()
      fn()
    }
  }
}