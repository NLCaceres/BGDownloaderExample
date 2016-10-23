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
    
    
    var dataURLs : [String] = ["https://upload.wikimedia.org/wikipedia/commons/d/d8/NASA_Mars_Rover.jpg", "http://img2.tvtome.com/i/u/28c79aac89f44f2dcf865ab8c03a4201.png", "http://news.brown.edu/files/article_images/MarsRover1.jpg", "https://loveoffriends.files.wordpress.com/2012/02/love-of-friends-117.jpg", "http://www.nasa.gov/images/content/482643main_msl20100916-full.jpg", "http://www.facultyfocus.com/wp-content/uploads/images/iStock_000012443270Large150921.jpg", "http://mars.nasa.gov/msl/images/msl20110602_PIA14175.jpg",  "http://i.kinja-img.com/gawker-media/image/upload/iftylroaoeej16deefkn.jpg",  "http://www.ymcanyc.org/i/ADULTS%20groupspinning2%20FC.jpg",  "http://www.dogslovewagtime.com/wp-content/uploads/2015/07/Dog-Pictures.jpg",  "http://cdn.phys.org/newman/gfx/news/hires/2015/earthandmars.png"]
    // in the brackets just copy and paste all the URLs we receive
    // these URLs will correspond to pictures that will be downloaded
    
    var tableData : [UIImage] = []
    
    var facesFoundCount : [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func beginDownloadTapped(_ sender: AnyObject) {
        
        tableData = []
        facesFoundCount = []
        tableView.reloadData()
        
        // Unfortunately Swift 3.0 will not let this work...
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.low).async {
            
            var bTask : UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
            
            bTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                UIApplication.shared.endBackgroundTask(bTask)
                bTask = UIBackgroundTaskInvalid
            })
            
            for i in 0 ..< self.dataURLs.count {
                
                print("time left")
                print(UIApplication.shared.backgroundTimeRemaining)
                // More Swift 3.0 changes! Must find a solution to all this!
                // But once we find this background time we have left
                // we would use it to determine what we will do if it dies before finishing
                
                if (UIApplication.shared.backgroundTimeRemaining < 2.0) {
                    print("Not enough time, skipping")
                    break
                    // This break will jump out of the for loop entirely
                    // Saves you during background processing
                }
                
                
                print("getting image")
                
                let url = URL(string: self.dataURLs[i])
                let imageData = try? Data(contentsOf: url!, options: NSData.ReadingOptions.mappedIfSafe)
                let image = UIImage(data: imageData!)
                // Note this is probably not a good way to do it IRL
                // Might not work because never quite certain IRL if you'll get something back
                
                if let imageToAnalyze = image {
                    
                    let ciImage = CIImage(cgImage: imageToAnalyze.cgImage!)
                    
                    let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
                    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)!
                    
                    let faces = faceDetector.features(in: ciImage)
                    
                    
                    print("\(faces.count) found in this picture")
                    self.facesFoundCount.append(faces.count)
                    
                    if (faces.count > 0) {
                        
                        let context = CIContext(options: nil)
                        
                        if let currentFilter = CIFilter(name: "CIGaussianBlur") {
                            currentFilter.setValue(ciImage, forKey: kCIInputImageKey)
                            currentFilter.setValue(5.0, forKey: kCIInputRadiusKey)
                            
                            if let output = currentFilter.outputImage {
                                if let cgImg = context.createCGImage(output, from: output.extent) {
                                    let filteredImage = UIImage(cgImage: cgImg)
                                    
                                    self.tableData.append(filteredImage)
                                    print("Image had faces so gaussian blur was applied")
                                }
                                
                            }
                        }
                        
                        
                    }
                    
                    else {
                        let context = CIContext(options: nil)
                        
                        let hueFilter : CIFilter! = CIFilter(name: "CIHueAdjust")
                        hueFilter.setValue(ciImage, forKey: kCIInputImageKey)
                        hueFilter.setValue(5.0, forKey: kCIInputAngleKey)
                        let output = hueFilter.outputImage!
                        
                        
                        let exposureFilter : CIFilter! = CIFilter(name: "CIExposureAdjust")
                        exposureFilter.setValue(output, forKey: kCIInputImageKey)
                        exposureFilter.setValue(5.0, forKey: kCIInputEVKey)
                        let output2 = exposureFilter.outputImage!
                        
                        let cgImg : CGImage! = context.createCGImage(output2, from: output2.extent)
                        let filteredImage = UIImage(cgImage: cgImg)
                        
                        self.tableData.append(filteredImage)
                        print("Image had no faces so hue and exposure added")
                        
                    }
                    
                    print("Going to begin async call in a second")
                }
                
                // Nor will this work, but WE SHALL FIND A WAY!
                // Async would also work too if we wanted
                // However if things got hectic memory-wise, sync helps pause the background
                DispatchQueue.main.sync(execute: {
                    print("In the async")
                    let indexPath : IndexPath = IndexPath(row: i, section: 0)
                    self.tableView.insertRows(at: [indexPath], with: UITableViewRowAnimation.left)
                    // this sort of modification to the tableView must be done in the main thread
                    // just like android, some things simply gotta be done on the main thread
                    print("Out of the async")
                })
                
                print("got image")
                
                Thread.sleep(forTimeInterval: 3)
                
                print("quick nap time")
                
            }
            
            print("All done")
            
            UIApplication.shared.endBackgroundTask(bTask)
            bTask = UIBackgroundTaskInvalid
            // Good practice to end it at the very end of your async queue call
        }

    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    let cellId = "cellId1"
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: cellId)
        }
        
        cell?.imageView?.image = tableData[(indexPath as NSIndexPath).row]
        if (facesFoundCount[(indexPath as NSIndexPath).row] == 0) {
            cell?.textLabel?.text = "No faces detected"
        }
        else if (facesFoundCount[(indexPath as NSIndexPath).row] == 1) {
            cell?.textLabel?.text = "\(facesFoundCount[(indexPath as NSIndexPath).row]) face detected"
        }
        else {
            cell?.textLabel?.text = "\(facesFoundCount[(indexPath as NSIndexPath).row]) faces detected"
        }
        
        return cell!
    }


}

