//
//  AlbumModel.swift
//  iPad Picture Frame
//
//  Created by Chuck Norton on 11/7/17.
//  Copyright © 2017 Chuck Norton. All rights reserved.
//

import Photos

class AlbumModel {
    let name:String
    let count:Int
    let images:[PHAsset]
    init(name:String, count:Int, images:[PHAsset]) {

        self.name = name
        self.count = count
        self.images = images
    }
}
