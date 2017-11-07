//
//  SettingsViewController.swift
//  iPad Picture Frame
//
//  Created by Chuck Norton on 11/7/17.
//  Copyright © 2017 Chuck Norton. All rights reserved.
//

import UIKit
import Photos

class SettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {



    @IBOutlet var pickerView: UIPickerView!
    
    var pickerData: [String] = [String]()
    
    let albums = Albums()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerData = self.albums.listAlbumTitles()
        
        let startRow = self.albums.getChosenAlbumRow()
        pickerView.selectRow(startRow, inComponent: 0, animated: false)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // need to share uicolor extension from viewcontroller across app
//        let lightblueColor = UIColor(rgb: 0x6abbda) // light blue hex is #6abbda
//        self.navigationController?.navigationBar.tintColor = UIColor.lightblueColor
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //+ check for photos access from app via https://stackoverflow.com/a/35714577
    
 
    
    
    
    /*** PICKER ***/
    
    
    // Picker: how many columns to select
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Picker: Selected Title : The data to return for the row and component (column)
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    
    // Picker: number of items in array
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    
    // Picker: upon selecting do what
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        albums.saveChosenAlbumString(newChosenAlbumString: pickerData[row])
    }
    
}

