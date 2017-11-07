//
//  ViewController.swift
//  iPad Picture Frame
//
//  Created by Chuck Norton on 11/7/17.
//  Copyright © 2017 Chuck Norton. All rights reserved.
//

import UIKit

class ViewController: UIViewController {


//    let imageViewController: ImageViewController = self.storyboard?.instantiateViewController(withIdentifier: "VC") as! ImageViewController

//    let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//    let imageViewController = storyBoard.instantiateViewController(withIdentifier: "ImageViewController") as! ImageViewController
    
    
    @IBOutlet var startButton: UIButton!
    
    @IBOutlet var StartHelperText: UITextField!
    
    
    let albums = Albums()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // only on first load - auto load images if albumIsReady
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let imageViewController = storyBoard.instantiateViewController(withIdentifier: "ImageViewController")
        if albums.albumIsReadyToShowPictures() {
            self.present(imageViewController, animated: true, completion: nil)
        }
        
        startButton.imageView?.image!.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        let blueColor = UIColor(rgb: 0x6abbda) // light blue hex is #6abbda
        startButton.imageView?.tintColor = blueColor
        
        // hide start helper text
        self.StartHelperText.alpha = 0
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if albums.albumIsReadyToShowPictures() {
            self.startButton.isEnabled = true
            self.startButton.alpha = 1
            self.StartHelperText.alpha = 0
        } else {
            self.startButton.isEnabled = false
            self.startButton.alpha = 0.2
            self.StartHelperText.alpha = 1
        }
    }

    
    
    

    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    

}


extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

