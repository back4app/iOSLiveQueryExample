//
//  LiveTableViewController.swift
//  BasicUserRegistration-Swift
//
//  Created by Ayrton Alves on 12/12/16.
//  Copyright © 2016 back4app. All rights reserved.
//

import Foundation
import UIKit
import Parse
import ParseLiveQuery
import BoltsSwift

protocol TableViewCellSupport {
    var title: String? { get }
    var details: String? { get }
}

class LiveTableViewController<T: PFObject>: UITableViewController {
    
    private var subscription: Subscription<T>!
    let query: PFQuery<T>
    let client: Client
    var results = [T]()
    var selectionHandler: ((T) -> Void)?
    
    required init(query pfQuery: PFQuery<T>, client liveQueryClient: Client = ParseLiveQuery.Client.shared, style: UITableViewStyle = .plain) {
        query = pfQuery
        client = liveQueryClient
        super.init(style: style)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // Start the subscription
        subscription = client.subscribe(query).handleSubscribe { [weak self]  (_) in
            // Fetch the objects on subscription to not miss any
            self?.fetchObjects()
            }.handleEvent { [weak self] (_, event) in
                self?.handleEvent(event: event)
        }
    }
    
    private func index(ofResult result: T) -> Array<T>.Index? {
        return results.index(where: {
            $0.objectId == result.objectId
        })
    }
    
    private func handleEvent(event: Event<T>) {
        // Make sure we're on main thread
        if Thread.current != Thread.main {
            return DispatchQueue.main.async { [weak self] _ in
                self?.handleEvent(event: event)
            }
        }
        navigationController?.navigationBar.backgroundColor = .red
        UIView.animate(withDuration: 1.0, animations: {
            self.navigationController?.navigationBar.backgroundColor = .clear
        })
        
        switch event {
        case .created(let obj),
             .entered(let obj):
            
            results.insert(obj, at: 0)
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            
        case .updated(let obj):
            
            guard let index = index(ofResult: obj) else { break }
            results.remove(at: index)
            results.insert(obj, at: 0)
            tableView.moveRow(at: IndexPath(row: index, section: 0), to: IndexPath(row: 0, section: 0))
            tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            
        case .deleted(let obj),
             .left(let obj):
            
            guard let index = index(ofResult: obj) else { break }
            results.remove(at: index)
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            
        }
    }
    
    private func fetchObjects() {
        query.findObjectsInBackground().continue(with: BFExecutor.mainThread(), with: { (task) -> Any? in
            guard let objects = task.result as? [T] else {
                return nil
            }
            self.results = objects
            self.tableView.reloadData()
            return nil
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if let object = results[indexPath.row] as? TableViewCellSupport {
            cell.textLabel?.text = object.title!
            cell.detailTextLabel?.text = object.details
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let object = results[indexPath.row]
        selectionHandler?(object)
    }
    
}
