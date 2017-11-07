//
//  Albums.swift
//  iPad Picture Frame
//
//  Created by Chuck Norton on 11/7/17.
//  Copyright © 2017 Chuck Norton. All rights reserved.
//

import Foundation
import Photos

// local storage keys
struct defaultsKeys {
    static let chosenAlbum = "chosenAlbum"
    static let todaysImageDate = "todaysImageDate"
    static let todaysImageLocalIdentifier = "todaysImageLocalIdentifier"
    static let usedImageIdentifiers = "usedImageIdentifiers"
}

class Albums {
    
    
    let defaults = UserDefaults.standard
    var albumTitles: [String] = [String]()
    var chosenAlbumString:String = ""
    var chosenAlbum: AlbumModel?
//    let timeStringFormatToCheckForChanges = "yyyyMMddmm" // testing every minute
//    let timeStringFormatToCheckForChanges = "yyyyMMddHH" // testing every hour
    let timeStringFormatToCheckForChanges = "yyyyMMdd" // production 24 hrs "yyyyMMdd"
    
    init() {
        self.setupChosenAlbum()
    }
    
    
    /*** ALBUMS ***/
    
    func getAlbums() -> [PHFetchResult<PHAssetCollection>] {
        
        //+ Check to see if albums contains images
        
        // user albums
        let userAlbumsOptions = PHFetchOptions()
        // limit to 1 or  image in that album
        userAlbumsOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
       
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.any, options: userAlbumsOptions)
        
        // smart albums
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil) // Here you can specify Photostream, etc. as PHAssetCollectionSubtype.xxx
        
        
        // combine
        let allAlbums = [userAlbums, smartAlbums]
        
        return allAlbums
        
    }
    
    func setupAlbums() {
        
        
        for (_, albumCollection) in self.getAlbums().enumerated() {
            
            albumCollection.enumerateObjects(_:) { (album, count, stop) in
                
                // doing some legwork on images so we don't show album if there are none
                let optionsToFilterImage = PHFetchOptions()
                optionsToFilterImage.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                // Fetching the asset with the predicate to filter just images
                let justImages = PHAsset.fetchAssets(in: album, options: optionsToFilterImage)
                
                let albumTitle = String(describing: album.localizedTitle ?? "")
                
                if justImages.count > 0 {
                    self.albumTitles.append(albumTitle)
                }
                
                
            }
            
        }
        
    }
    
    func listAlbumTitles() -> [String] {
    
        if self.albumTitles.isEmpty {
            self.setupAlbums()
        }

        return self.albumTitles

    }
    
    
    func saveChosenAlbumString(newChosenAlbumString: String) {
        
        // clear old settings
        self.clearAllSavedData()
        
        // save
        self.chosenAlbumString = newChosenAlbumString
        self.defaults.set(chosenAlbumString, forKey: defaultsKeys.chosenAlbum)
        
        // rerun setup
        self.setupChosenAlbum()

    }
    
    
    func getChosenAlbumString() -> String {
        
        if let retrievedChosenAlbumString = defaults.string(forKey: defaultsKeys.chosenAlbum) {
            self.chosenAlbumString = retrievedChosenAlbumString
        }
        
        return self.chosenAlbumString

    }
    
    func albumIsReadyToShowPictures() -> Bool {
        
        var isReady = false
        
        if self.getChosenAlbumString() != "" {
            isReady = true
        }
        
        return isReady
    }

    func getChosenAlbumRow() -> Int {
        
        let retrievedChosenAlbumString = self.getChosenAlbumString()
        
        var rowNumber = 0
        for (index, albumTitle) in albumTitles.enumerated() {
            if albumTitle == retrievedChosenAlbumString {
                rowNumber = index
            }
        }
        return rowNumber
    }
    
    
    func setupChosenAlbum() {
        
        let retrievedChosenAlbumString = self.getChosenAlbumString()
        let retrievedAlbums = self.getAlbums()
        
        // find album
        for (_, albumCollection) in retrievedAlbums.enumerated() {
            
            albumCollection.enumerateObjects(_:) { (album, count, stop) in
                
                let albumTitle = String(describing: album.localizedTitle ?? "")
                
                if albumTitle == retrievedChosenAlbumString {
                    
                    // setup images
                    var images:[PHAsset] = []
                    //let options = PHFetchOptions() //+ troubleshoot a way to look for newly added/removed photos from shared albums
                    let photoAssets: PHFetchResult = PHAsset.fetchAssets(in: album, options: nil)
                    
                    photoAssets.enumerateObjects{
                        (object: AnyObject!, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in
                        
                        if object is PHAsset{
                            let asset = object as! PHAsset
                            images.append(asset)
                        }
            
                    }
                    
                    // save album model
                    self.chosenAlbum = AlbumModel(
                        name: album.localizedTitle!,
                        count: album.estimatedAssetCount,
                        images: images)
                }
                
            }
            
        }
        
    }
    

    
    
    func getTodaysImageAsset(reset: Bool = false) -> PHAsset? {
        
        // resetup chosen album image assets in case we add new ones during the day
        self.setupChosenAlbum()
        
        // return nil if for some reason the album can't be found
        if (self.chosenAlbum == nil) {
            return nil
        }
        
        
        let albumImages = self.chosenAlbum!.images
    
        var todaysImageAsset: PHAsset?
        
        
        // check to see if we have an image for today already
        var alreadyChoseTodaysImage = false
        let previouslySavedTodaysImageDate = defaults.string(forKey: defaultsKeys.todaysImageDate)
        let todaysDate = self.getTodaysDate()
        if !reset && previouslySavedTodaysImageDate != nil {
            if previouslySavedTodaysImageDate! == todaysDate {
                alreadyChoseTodaysImage = true
            }
        }
        
        if alreadyChoseTodaysImage {
            let todaysImageLocalIdentifier = defaults.string(forKey: defaultsKeys.todaysImageLocalIdentifier)

            if let previouslySavedTodaysImageLocalIdentifier = todaysImageLocalIdentifier {

                // get images with identifier


                let todaysImageCollection = PHAsset.fetchAssets(withLocalIdentifiers: [previouslySavedTodaysImageLocalIdentifier], options: nil)


                var previouslySavedTodaysImageAsset: PHAsset?

                todaysImageCollection.enumerateObjects{
                    (object: AnyObject!, count: Int, stop: UnsafeMutablePointer<ObjCBool>) in

                    if object is PHAsset{
                        let asset = object as! PHAsset
                        previouslySavedTodaysImageAsset = asset
                    }

                }

                if let successfulTodaysImageAsset =  previouslySavedTodaysImageAsset{
                    return successfulTodaysImageAsset
                }

            }


        }
        
        // otherwise choose one at random
    
        var possibleImages: [PHAsset] = []
        var previouslyUsedImageIdentifiers = defaults.object(forKey: defaultsKeys.usedImageIdentifiers) as? [String] ?? [String]()

        for (_, asset) in albumImages.enumerated() {
            
            //print("asset.originalFilename \(asset.originalFilename)")
            // Skip Already Shown Assets
            if previouslyUsedImageIdentifiers.contains(asset.localIdentifier) {
                continue
            }
            
            possibleImages.append(asset)
        }
        
        // if no images selected - choose from all album images
        if possibleImages.count == 0 {
            previouslyUsedImageIdentifiers = [String]()
            possibleImages = albumImages
        }
       
        if possibleImages.count > 0 {
        
            // Choose at Random from remaining images
            todaysImageAsset = possibleImages.randomElement
            
            if todaysImageAsset != nil {
                // Save Date & Asset Key
                self.defaults.set(todaysDate, forKey: defaultsKeys.todaysImageDate)
                self.defaults.set(todaysImageAsset!.localIdentifier, forKey: defaultsKeys.todaysImageLocalIdentifier)
                
                
                // Save so we don't show again in future rotation
                previouslyUsedImageIdentifiers.append(todaysImageAsset!.localIdentifier)
                self.defaults.set(previouslyUsedImageIdentifiers,forKey: defaultsKeys.usedImageIdentifiers)
            }
            
            
        }
        
        
        
        return todaysImageAsset
        
    }
    
    func getTodaysDate() -> String {
        
        let date : Date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = self.timeStringFormatToCheckForChanges
        let todaysDate = dateFormatter.string(from: date)
        
        return todaysDate
    }
    
    
    //+ CLEAR ALL SAVED VARIABLES
    func clearAllSavedData() {
        print("clearingData")
        self.defaults.removeObject(forKey: defaultsKeys.chosenAlbum)
        self.defaults.removeObject(forKey: defaultsKeys.todaysImageDate)
        self.defaults.removeObject(forKey: defaultsKeys.todaysImageLocalIdentifier)
        self.defaults.removeObject(forKey: defaultsKeys.usedImageIdentifiers)
    }
    
    
    
}

private extension Array {
    var randomElement: Element {
        let index = Int(arc4random_uniform(UInt32(count)))
        return self[index]
    }
}

extension PHAsset {
    
    var originalFilename: String? {
        
        var fname:String?
        
        if #available(iOS 9.0, *) {
            let resources = PHAssetResource.assetResources(for: self)
            if let resource = resources.first {
                fname = resource.originalFilename
            }
        }
        
        if fname == nil {
            // this is an undocumented workaround that works as of iOS 9.1
            fname = self.value(forKey: "filename") as? String
        }
        
        return fname
    }
}
