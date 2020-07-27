//
//  MasterViewController.swift
//  DrawingPad
//
//  Created by xiang on 7/24/20.
//  Copyright © 2020 test. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var projects:ProjectsManager = ProjectsManager.getLocalProjectManager()
    
    var blocktag:Int = 0 {
        didSet{
            if(blocktag == 0){
                blockInteraction(false)
            }
            else{
                blockInteraction(true)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem = editButtonItem
        splitViewController?.preferredDisplayMode = .primaryOverlay
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        projects.openProjects { [weak self](success) in
            if success == true{
                self?.tableView.reloadData()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    func blockInteraction(_ enable:Bool){
        
    }
    
    @objc
    func insertNewObject(_ sender: Any) {
        blocktag = 2
        projects.addCanvas(modelSaveFinishedHandler: { [weak self] (success) in
            if success == true {
                self?.tableView.reloadData()
                //self?.tableView.insertRows(at: [IndexPath(row: (self?.projects.count ?? 1)-1, section: 0)], with: .automatic)
            }
            self?.blocktag -= 1
        }) {[weak self] (success, canvasObject) in
            self?.blocktag -= 1
            if success == true {
                self?.tableView.selectRow(at: IndexPath(row: (self?.projects.count ?? 1)-1, section: 0), animated: true, scrollPosition: .none)
                self?.performSegue(withIdentifier: "showDetail", sender: nil)
            }
        }
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow{
                
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
                detailViewController = controller
                projects.openCanvas(at: indexPath.row) {[weak controller] (success, _canvasObject) in
                    controller?.canvasObject=_canvasObject
                }
            }
           
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ProjectBrifeTableViewCell
        if let object = projects[indexPath.row]{
            cell.createdTimeLable.text = "created on \(object.createdTime)"
        }
        return cell
    }

    /*/override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }*/

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
           //objects.remove(at: indexPath.row)
            blocktag = 1
            projects.deleteCanvas(at: indexPath.row) {[weak self] (success) in
                self?.blocktag = 0
                if(success == true){
                    self?.tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    


}



