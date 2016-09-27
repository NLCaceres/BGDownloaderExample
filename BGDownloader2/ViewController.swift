//
//  ViewController.swift
//  BGDownloader2
//
//  Created by Nicholas L Caceres on 9/25/16.
//  Copyright © 2016 Nicholas L Caceres. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    
    var dataURLs : [String] = ["https://upload.wikimedia.org/wikipedia/commons/d/d8/NASA_Mars_Rover.jpg",
                               "http://www.wired.com/wp-content/uploads/images_blogs/wiredscience/2012/08/Mars-in-95-Rover1.jpg",
                               "http://news.brown.edu/files/article_images/MarsRover1.jpg",
                               "http://www.nasa.gov/images/content/482643main_msl20100916-full.jpg",
                               "https://upload.wikimedia.org/wikipedia/commons/f/fa/Martian_rover_Curiosity_using_ChemCam_Msl20111115_PIA14760_MSL_PIcture-3-br2.jpg",
                               "http://mars.nasa.gov/msl/images/msl20110602_PIA14175.jpg",
                               "http://i.kinja-img.com/gawker-media/image/upload/iftylroaoeej16deefkn.jpg",
                               "http://www.nasa.gov/sites/default/files/thumbnails/image/journey_to_mars.jpeg",
                               "http://i.space.com/images/i/000/021/072/original/mars-one-colony-2025.jpg?1375634917",
                               "http://cdn.phys.org/newman/gfx/news/hires/2015/earthandmars.png"]
    // in the brackets just copy and paste all the URLs we receive
    // these URLs will correspond to pictures that will be downloaded
    
    var tableData : [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func beginDownloadTapped(sender: AnyObject) {
        
        tableData = []
        tableView.reloadData()
        
        // Unfortunately Swift 3.0 will not let this work...
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            
            var bTask : UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
            
            bTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
                UIApplication.sharedApplication().endBackgroundTask(bTask)
                bTask = UIBackgroundTaskInvalid
            })
            
            for(var i = 0; i < self.dataURLs.count; i++) {
                
                print("time left")
                print(UIApplication.sharedApplication().backgroundTimeRemaining)
                // More Swift 3.0 changes! Must find a solution to all this!
                // But once we find this background time we have left
                // we would use it to determine what we will do if it dies before finishing
                
                if (UIApplication.sharedApplication().backgroundTimeRemaining < 2.0) {
                    print("Not enough time, skipping")
                    break
                    // This break will jump out of the for loop entirely
                    // Saves you during background processing
                }
                
                
                print("getting image")
                
                let url = NSURL(string: self.dataURLs[i])
                let imageData = NSData(contentsOfURL: url!)
                let image = UIImage(data: imageData!)
                // Note this is probably not a good way to do it IRL
                // Might not work because never quite certain IRL if you'll get something back
                
                self.tableData.append(image!)
                
                // Nor will this work, but WE SHALL FIND A WAY!
                // Async would also work too if we wanted
                // However if things got hectic memory-wise, sync helps pause the background
                dispatch_sync(dispatch_get_main_queue(), {
                    let indexPath : NSIndexPath = NSIndexPath(forRow: i, inSection: 0)
                    self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
                    // this sort of modification to the tableView must be done in the main thread
                    // just like android, some things simply gotta be done on the main thread
                })
                
                print("got image")
                
                NSThread.sleepForTimeInterval(3)
                
                print("quick nap time")
                
            }
            
            print("All done")
            
            UIApplication.sharedApplication().endBackgroundTask(bTask)
            bTask = UIBackgroundTaskInvalid
            // Good practice to end it at the very end of your async queue call
        }

    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    let cellId = "cellId1"
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellId)
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: cellId)
        }
        
        cell?.imageView?.image = tableData[indexPath.row]
        cell?.textLabel?.text = dataURLs[indexPath.row]
        
        return cell!
    }


}

