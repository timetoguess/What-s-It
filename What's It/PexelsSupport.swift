//
//  PexelsSupport.swift
//  What's It
//
//  Created by Prabhunes on 8/12/19.
//  Copyright © 2019 prabhunes. All rights reserved.
//

import Foundation

struct PexelsData {
    static let baseUrl = "https://api.pexels.com/v1/search?query="
    static let queryDetailsUrlPart = "+query&per_page=100&page=1"
    static let queryTypes = ["potted%20plants%20living%20room", "dining%20table%20house", "pizza%20drinks", "meeting",
                             "bicycle%20car", "bicycle%20race", "bicycles", "motorbikes", "airport", "airplanes",
                             "aeroplanes", "bus%20road", "trains", "train%20station", "trucks%20road", "boats",
                             "boats%20race", "boats%20harbor", "traffic", "traffic%20light%20road",
                             "traffic%20light%20road%20kids", "road%20intersection", "fire%20hydrant%20road",
                             "park%20benches", "beach%20benches", "birds", "cat%20and%20people",
                             "dogs%20race", "horses%20race", "sheep%20farm", "cows%20barn", "elephant%20people",
                             "zebra%20people", "rain%20umbrella", "handbag%20phone", "suitcase", "frisbee", "skis",
                             "snowboard", "sports%20ball", "kite", "base%20ball", "baseball%20glove", "skateboard",
                             "surfboard", "tennis%20racket", "bottles%20wine%20glass", "bottles%20lab", "spoon%20bowl",
                             "fork%20knife", "banana%20apple%20orange", "broccoli%20carrot", "donuts",
                             "cake%20birthday", "bedroom", "bathroom", "kitchen", "cafe", "office"]
    static let localImagesInfo = [
        // Notes for GitHub usage:
        // These images from Pexels are in the 'Images' folder. The Images folder has been added to .gitignore.
        // You can add any local images as appropriate; these will be used if WiFi and mobile broadband connections
        // are not available (a random image from one of these will be displayed).
        // Also, city_skyline.jpeg from this folder is used in the LaunchScreen.storyboard. You can download and use
        // this image or any other image by referencing that file in the storyboard.
        LocalPexelsImageInfo(imageName: "pexels-photo-1391373.jpeg", photographer: "rawpixel.com"),
        LocalPexelsImageInfo(imageName: "pexels-photo-2231158.jpeg", photographer: "malcolm garret"),
        LocalPexelsImageInfo(imageName: "pexels-photo-1599791.jpeg", photographer: "Jean van der Meulen"),
        LocalPexelsImageInfo(imageName: "pexels-photo-1098770.jpeg", photographer: "Suzy Hazelwood"),
        LocalPexelsImageInfo(imageName: "airport-aircraft-departure-travel.jpg", photographer: "Pixabay"),
        LocalPexelsImageInfo(imageName: "pexels-photo-2446564.jpeg", photographer: "K’LeAnn"),
        LocalPexelsImageInfo(imageName: "pexels-photo-378570.jpeg", photographer: "Nout Gons"),
        LocalPexelsImageInfo(imageName: "pexels-photo-2435503.jpeg", photographer: "Eugene Chystiakov"),
        LocalPexelsImageInfo(imageName: "pexels-photo-709860.jpeg", photographer: "Carlos Pernalete Tua")]
}

struct PexelsSrc: Decodable {
    var original: String
    var large2x: String
    var large: String
    var medium: String
    var small: String
    var portrait: String
    var landscape: String
    var tiny: String
}

struct PexelsPhotos: Decodable {
    var id: Int
    var width: Int
    var height: Int
    var url: String
    var photographer: String
    var photographer_url: String
    var photographer_id: Int
    var src: PexelsSrc
}

struct PexelsResponse: Decodable {
    var total_results: Int
    var page: Int
    var per_page: Int
    var photos: [PexelsPhotos]
    var next_page: String
}

struct LocalPexelsImageInfo {
    var imageName = ""
    var photographer = ""
}
