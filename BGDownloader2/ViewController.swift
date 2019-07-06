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
    
    
    let dataURLs : [String] = ["https://upload.wikimedia.org/wikipedia/commons/d/d8/NASA_Mars_Rover.jpg", "http://img2.tvtome.com/i/u/28c79aac89f44f2dcf865ab8c03a4201.png", "http://news.brown.edu/files/article_images/MarsRover1.jpg", "https://loveoffriends.files.wordpress.com/2012/02/love-of-friends-117.jpg", "http://www.nasa.gov/images/content/482643main_msl20100916-full.jpg", "http://www.facultyfocus.com/wp-content/uploads/images/iStock_000012443270Large150921.jpg", "http://mars.nasa.gov/msl/images/msl20110602_PIA14175.jpg",  "http://i.kinja-img.com/gawker-media/image/upload/iftylroaoeej16deefkn.jpg",  "http://www.ymcanyc.org/i/ADULTS%20groupspinning2%20FC.jpg",  "http://www.dogslovewagtime.com/wp-content/uploads/2015/07/Dog-Pictures.jpg",  "http://cdn.phys.org/newman/gfx/news/hires/2015/earthandmars.png"]
    // Bracketed init for [String]
    
    var tableData : [UIImage] = []
    
    var facesFoundCount : [Int] = []
    
    var indicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        activityIndicator()
    }
    
    func activityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.style = .gray
        indicator.center = self.view.center
        self.tableView.addSubview(indicator)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func beginDownloadTapped(_ sender: AnyObject) {
        
        tableData.removeAll()
        facesFoundCount.removeAll()
        tableView.reloadData()
        
        indicator.startAnimating()
        indicator.backgroundColor = UIColor.clear
        DispatchQueue.global(qos: .background).async {
            var bTask : UIBackgroundTaskIdentifier = .invalid
            
            bTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                UIApplication.shared.endBackgroundTask(bTask)
                bTask = .invalid
            })
            
            var cellIndex = 0
            for i in 0 ..< self.dataURLs.count {
                //print(UIApplication.shared.backgroundTimeRemaining) Can't check BGTime from async (Swift 3.0 change)
//                if (UIApplication.shared.backgroundTimeRemaining < 2.0) {
//                    print("Not enough time, skipping backgroundTask")
//                    break // Will break entire loop
//                }
                print("getting image")
                guard let url = URL(string: self.dataURLs[i]) else {
                    print("URL couldn't be converted from string")
                    continue
                }
                guard let imageData = try? Data(contentsOf: url, options: .mappedIfSafe) else {
                    print("Couldn't grab data from URL into image info")
                    continue
                }
                guard let image = UIImage(data: imageData) else {
                    print("Couldn't convert into image")
                    continue
                }
                
                let ciImage = CIImage(cgImage: image.cgImage!)
                
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
                
                // Async would also work too if we wanted but with hectic memory sync will pause things (or deadlock things so careful!)
                DispatchQueue.main.sync { [weak self] in
                    guard let self = self else {
                        return
                    }
                    print("In the async")
                    let indexPath : IndexPath = IndexPath(row: cellIndex, section: 0)
                    cellIndex += 1
                    self.tableView.insertRows(at: [indexPath], with: .left)
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    // UI Updates = MAIN THREAD WORK!
                    print("Out of the async")
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.indicator.stopAnimating()
            }
            
            print("All done")
            UIApplication.shared.endBackgroundTask(bTask)
            bTask = .invalid // Good practice at end of background task
        }

    }
    
    // MARK: TABLEVIEW Data/Delegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
    
    let cellId = "cellId1"
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        if (cell == nil) {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellId)
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

