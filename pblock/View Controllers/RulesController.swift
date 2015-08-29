//
//  RulesController.swift
//  pblock
//
//  Created by Will Fleming on 8/29/15.
//  Copyright © 2015 PBlock. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class RulesController: UITableViewController, NSFetchedResultsControllerDelegate, DetailViewController {
  private var coreDataMgr: CoreDataManager?
  var ruleSource: RuleSource? {
    didSet {
      _fetchedResultsController = nil
      if let frc = fetchedResultsController {
        controllerWillChangeContent(frc)
      }
    }
  }
  var detailItem: AnyObject? {
    get {
      return ruleSource
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    coreDataMgr = CoreDataManager.sharedInstance
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


  // MARK: - Table View

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return self.fetchedResultsController?.sections?.count ?? 0
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sectionInfo = self.fetchedResultsController!.sections![section]
    return sectionInfo.numberOfObjects
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    self.configureCell(cell, atIndexPath: indexPath)
    return cell
  }

  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return false
  }

  func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
    let rule = self.fetchedResultsController!.objectAtIndexPath(indexPath) as? Rule
    cell.textLabel?.text = rule?.actionType.jsonValue()
  }

  // MARK: - Fetched results controller

  private var fetchedResultsController: NSFetchedResultsController? {
    get {
      if nil == _fetchedResultsController {
        if let ruleSource = ruleSource {
          // we can return real results
          coreDataMgr = CoreDataManager.sharedInstance //WTF? this gets set, then is nil
          let fetchRequest: NSFetchRequest? = coreDataMgr?.managedObjectModel?
            .fetchRequestFromTemplateWithName("RulesInSource",
              substitutionVariables: [ "SOURCE": ruleSource ]
            )
          fetchRequest?.sortDescriptors = [ NSSortDescriptor(key: "sourceText", ascending: true) ]
          if let fr = fetchRequest {
            _fetchedResultsController = NSFetchedResultsController(
              fetchRequest: fr,
              managedObjectContext: self.coreDataMgr!.managedObjectContext!,
              sectionNameKeyPath: nil,
              cacheName: nil
            )
            _fetchedResultsController?.delegate = self

            do {
              try _fetchedResultsController?.performFetch()
            } catch {
              dlog("Failed fetch \(error)")
              abort() // crash!
            }
          }
        }
      }

      return _fetchedResultsController
    }

    set(val) {
      _fetchedResultsController = val
    }
  }
  private var _fetchedResultsController: NSFetchedResultsController?

  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    self.tableView.beginUpdates()
  }

  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    switch type {
    case .Insert:
      self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
    case .Delete:
      self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
    default:
      return
    }
  }

  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    switch type {
    case .Insert:
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
    case .Delete:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
    case .Update:
      self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
    case .Move:
      tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
      tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
    }
  }

  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    self.tableView.endUpdates()
  }

}