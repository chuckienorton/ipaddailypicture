//
//  ImageViewController.swift
//  iPad Picture Frame
//
//  Created by Chuck Norton on 11/7/17.
//  Copyright © 2017 Chuck Norton. All rights reserved.
//

import UIKit
import Photos

class ImageViewController: UIViewController {


    @IBOutlet var imageView: UIImageView!
    
    let albums = Albums()
    
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var refreshButton: UIButton!
    
    var closeButtonIsVisible = false
    
    var changeImage: Timer!
    let changeTimeIntervalInSeconds: Double = 60
    var dragToChangeAlphaStartingPoint:CGFloat = 0.0
    var dragToChangeAlphaImageAlpha: CGFloat = 1
    
    var todaysImageAsset:PHAsset?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        // load image
        self.loadImage()
        
        
        // hide close and refresh button to start
        self.closeButton.alpha = 0
        self.refreshButton.alpha = 0
        self.closeButtonIsVisible = false

        // add close gesture to image
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ImageViewController.handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        self.imageView.addGestureRecognizer(tapGesture)
        self.imageView.isUserInteractionEnabled = true

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ImageViewController.dragUpDown(_:)))
        panRecognizer.minimumNumberOfTouches = 2
        self.imageView.addGestureRecognizer(panRecognizer)
        
        // start timer
        changeImage = Timer.scheduledTimer(timeInterval: changeTimeIntervalInSeconds, target: self, selector: #selector(ImageViewController.runChangeImageTimer), userInfo: nil, repeats: true)

        // hiding statusBarAppearance
        self.modalPresentationCapturesStatusBarAppearance = true
        UIApplication.shared.statusBarView?.backgroundColor = UIColor(white: 1, alpha: 0.5)

        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // disable idle timer
        UIApplication.shared.isIdleTimerDisabled = true
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // reenable idle timer
        UIApplication.shared.isIdleTimerDisabled = false

    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        
        let tmpController :UIViewController! = self.presentingViewController;
        
        self.dismiss(animated: true, completion: {()->Void in
            tmpController.dismiss(animated: true, completion: nil);
        });
        
    }
    
    @IBAction func refreshButtonAction(_ sender: Any) {
        
        print("refresh touched")
        self.loadImage(reset: true)
        
    }
    
    
   
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        // handle close button visibility
        if self.closeButtonIsVisible {
            self.closeButton.alpha = 0.0
            self.refreshButton.alpha = 0.0
            self.closeButtonIsVisible = false
            
            //+ handle hide status bar funciton -- refer to https://stackoverflow.com/questions/35028262/how-to-hide-status-bar-of-a-single-view-controller-in-ios-9
            //+ and add way to toggle on/off with similar if on return false, if off return true
            self.statusBarHidden = true
            self.setNeedsStatusBarAppearanceUpdate()
            
        } else {
            self.closeButton.alpha = 0.6
            self.refreshButton.alpha = 0.02
            self.closeButtonIsVisible = true
            self.statusBarHidden = false
            self.setNeedsStatusBarAppearanceUpdate()

        }
        
        
    }
    
    var statusBarHidden: Bool = true
    override var prefersStatusBarHidden: Bool {
        return self.statusBarHidden
    }
    
    
//    override var prefersStatusBarHidden: Bool{
//        return true
//    }
//
//    func setNeedsStatusBarAppearanceUpdate(turnOff: Bool = true) -> Bool {
//        return turnOff
//    }
    
    
    // Change Alpha on image based on 2 finger drag up/down
    
    @objc func dragUpDown(_ sender:UIPanGestureRecognizer) {
        
        // if we are begining a drag - start at 0
        if(sender.state == UIGestureRecognizerState.began)
        {
            self.dragToChangeAlphaStartingPoint = sender.location(ofTouch: 0, in: self.imageView).y
        }
        
        if sender.numberOfTouches == 2 {
            let currentPoint = sender.location(ofTouch: 0, in: self.imageView).y
            let changedAlpha = -(((currentPoint - self.dragToChangeAlphaStartingPoint) / 1000) / 10)
            let newAlpha = (self.dragToChangeAlphaImageAlpha + changedAlpha)

            if newAlpha <= 1.0 && newAlpha >= 0.1 {
                changeImageAlpha(alpha: newAlpha)
            }
            
        }
        
        
    }
    
    func changeImageAlpha(alpha: CGFloat) {
        self.dragToChangeAlphaImageAlpha = alpha
        self.imageView.alpha = alpha
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func loadImage(reset: Bool = false) {
        
        
        // check for new images
        albums.setupChosenAlbum()
        
    
        let availableWidth = UIScreen.main.bounds.size.width
        let availableHeight = UIScreen.main.bounds.size.height
        let ratio = availableWidth / availableHeight

        var newWidth: CGFloat = availableWidth
        var newHeight: CGFloat = availableHeight
        
        if self.view.frame.width > self.view.frame.height {
            newHeight = self.view.frame.width / ratio
        } else {
            newWidth = self.view.frame.height * ratio
        }
        
    
        
        
        
//        let todaysImage = albums.getTodaysImage(dimensions: CGSize(width: newWidth, height: newHeight))
//        self.imageView.image = todaysImage
        
        let newlyCheckedTodaysImageAsset = albums.getTodaysImageAsset(reset: reset)
        
        // only reload image if it's not the same one
        if newlyCheckedTodaysImageAsset != nil && newlyCheckedTodaysImageAsset != self.todaysImageAsset {
        
            self.todaysImageAsset = newlyCheckedTodaysImageAsset
            
            print("todays image: ", todaysImageAsset!.originalFilename!)
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.version = PHImageRequestOptionsVersion.current
            options.resizeMode = PHImageRequestOptionsResizeMode.exact
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.opportunistic // will load twice for new images... first time will be degraded, second time for full size image
            options.isSynchronous = false // set to false if we later add a progress handler
            manager.requestImage(for: todaysImageAsset!, targetSize: CGSize(width: newWidth, height: newHeight), contentMode: .aspectFit, options: options, resultHandler: {(result, info)->Void in
                // if we are good to go
                if result != nil{
                    self.imageView.image = result // load results into image frame
                // else - reload and try again
                } else {
                    print("problem loading image. Trying again")
                    self.loadImage(reset: true)
                }
            })
            
            
        }
        
        
        
        self.imageView.alpha = self.dragToChangeAlphaImageAlpha
    
    }
    
    
    func resizeUIImage (sourceImage:UIImage, scaledToWidth: CGFloat) -> UIImage {
        let oldWidth = sourceImage.size.width
        let scaleFactor = scaledToWidth / oldWidth
        let newHeight = sourceImage.size.height * scaleFactor
        let newWidth = oldWidth * scaleFactor
        

        
        UIGraphicsBeginImageContext(CGSize(width:newWidth, height:newHeight))
        sourceImage.draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    
    @objc func runChangeImageTimer() {
        self.loadImage()
    }
    
    
    
}

extension UIApplication {
    var statusBarView: UIView? {
        return value(forKey: "statusBar") as? UIView
    }
}
