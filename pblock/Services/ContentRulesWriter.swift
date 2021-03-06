//
//  ContentRulesWriter.swift
//  pblock
//
//  Created by Will Fleming on 8/29/15.
//  Copyright © 2015 PBlock. All rights reserved.
//

import Foundation
import CoreData
import ReactiveCocoa

// for writing all active rules in the DB into our content blocking json
class ContentRulesWriter {
  // TODO: find out the best value for this -- it needs to go up
  static let maxRules = 20000 // note this seems to differ by platform: this value is for iOS

  private let mgr = CoreDataManager.sharedInstance
  private var ctx: NSManagedObjectContext
  private let pageSize = 50
  private let filePathURL = rulesJSONPath()
  private var recordsWritten = 0

  required init() {
    ctx = mgr.childManagedObjectContext()!
  }

  func writeRulesSignal() -> RACSignal {
    return RACSignal.createSignal { (sub: RACSubscriber!) -> RACDisposable! in
      self.writeRules()
      sub.sendNext(self.recordsWritten)
      sub.sendCompleted()

      return RACDisposable()
    }
  }

  func writeRules() {
    logToGroupLogFile("app.content-rules-writer.write")

    let fm = NSFileManager.defaultManager()

    do {
      dlog("writing rules to \(filePathURL)")
      "".dataUsingEncoding(NSUTF8StringEncoding)?.writeToURL(filePathURL, atomically: true)
      let fh = try NSFileHandle(forWritingToURL: filePathURL)
      defer {
        fh.closeFile()
      }

      fh.writeData("[".dataUsingEncoding(NSUTF8StringEncoding)!)

      var currentPage = 0,
          currentRules = self.enabledRules(currentPage)
      while currentRules.count > 0 {
        currentRules.forEach {
          do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject($0.asJSON(),
              options: NSJSONWritingOptions.init(rawValue: 0)
            )
            if recordsWritten > 0 {
              fh.writeData(",".dataUsingEncoding(NSUTF8StringEncoding)!)
            }
            fh.writeData(jsonData)
            recordsWritten += 1
          } catch {
            dlog("ContentRulesWriter failed to write rule: \(error)")
          }
        }

        dlog("ContentRulesWriter finished writing page \(currentPage)")

        if recordsWritten >= (self.dynamicType.maxRules - pageSize) {
          dlog("wrote \(recordsWritten) rules: stopping now to avoid going over limit")
          fh.writeData("]".dataUsingEncoding(NSUTF8StringEncoding)!)
          return
        }

        currentPage += 1
        currentRules = self.enabledRules(currentPage)
      }

      fh.writeData("]".dataUsingEncoding(NSUTF8StringEncoding)!)

      dlog("ContentRulesWriter finished writing \(recordsWritten) rules")
    } catch {
      dlog("ContentRulesWriter failed to write to file: \(error)")
    }
  }

  private func enabledRules(pageIndex: Int) -> Array<Rule> {
    let fetchRequest = mgr.managedObjectModel!.fetchRequestTemplateForName("EnabledRules")?
      .copy() as! NSFetchRequest
    // taking advantage of the fact that sorting this way 1) groups by action, which docs say is
    // good for perf, and 2) puts whitelist actions at the end, which is neccesary
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "actionTypeRaw", ascending: true)]
    fetchRequest.fetchLimit = pageSize
    fetchRequest.fetchOffset = (pageIndex * pageSize)
    do {
      return try ctx.executeFetchRequest(fetchRequest) as! Array<Rule>
    } catch {
      dlog("failed fetching: \(error)")
      return []
    }
  }
}