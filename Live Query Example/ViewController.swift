//
//  ViewController.swift
//  BasicUserRegistration-Swift
//
//  Created by Ramon Vitor on 09/10/16.
//  Copyright © 2016 back4app. All rights reserved.
//

import UIKit
import Parse
import ParseLiveQuery
import BoltsSwift

let liveQueryClient: Client = ParseLiveQuery.Client(server: "http://back4applivequery.back4app.io")

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    private var subscription: Subscription<PFObject>!
    var messagesArray : [PFObject] = [PFObject]()
    var msgQuery = PFQuery(className: "Messages").whereKeyExists("message")
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.chatTableView.delegate = self
        self.chatTableView.dataSource = self
        self.textField.delegate = self
        
        self.textField.placeholder = "Say something"
        
        try! self.messagesArray =  PFCloud.callFunction("getMessages", withParameters: nil) as! [PFObject]
        print(self.messagesArray )
        
        subscription = liveQueryClient.subscribe(msgQuery).handleSubscribe { [weak self] (_) in
            print(self?.messagesArray ?? "Default value printed")
            }.handleEvent { [weak self] (_, event) in
                self?.handleEvent(event: event)
        }
    }
    
    private func handleEvent(event: Event<PFObject>) {
        print("Started Handle Event")
        if Thread.current != Thread.main {
            return DispatchQueue.main.async {
                self.handleEvent(event: event)
            }
        } else {
            switch event {
            case .created(let obj):
                try! obj.fetchIfNeeded()
                print("Object received", obj)
                self.messagesArray.insert(obj, at: 0)
                self.chatTableView.insertRows(at: [IndexPath.init(row: self.messagesArray.count-1, section: 0)], with: .automatic)
                print(messagesArray)
                break
            case .deleted(let obj):
                print(obj)
                try! obj.fetchIfNeeded()
                var index = 0
                for item in self.messagesArray {
                    if (item["message"] as! String) == (obj["message"] as! String) {
                        index = self.messagesArray.index(of: item)!
                    }
                }
                self.messagesArray.remove(at: index)
                self.chatTableView.deleteRows(at: [IndexPath(row: index, section:0)], with: .automatic)
                
                break
            case .updated(let obj):
                print(obj)
                try! obj.fetchIfNeeded()
                var index = 0
                for item in self.messagesArray {
                    if (item.objectId! as String) == (obj.objectId! as String) {
                        index = self.messagesArray.index(of: item)!
                    }
                }
                self.messagesArray[index] = obj
                self.chatTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            default: break
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        let message: PFObject = PFObject(className: "Messages")
        message["message"] = self.textField.text
        
        message.saveInBackground { (_, er) in
            if !(er != nil) {
                print("Message uploaded to back4app")
            } else {
                print(er as Any)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        try! self.messagesArray =  PFCloud.callFunction("getMessages", withParameters: nil) as! [PFObject]
        return messagesArray.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        try! self.messagesArray =  PFCloud.callFunction("getMessages", withParameters: nil) as! [PFObject]
        // Create a table cell
        let cell = self.chatTableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)
        // Customize the cell
        
        cell.textLabel?.text = self.messagesArray[indexPath.row]["message"] as! String?
        
        return cell
    }

}

