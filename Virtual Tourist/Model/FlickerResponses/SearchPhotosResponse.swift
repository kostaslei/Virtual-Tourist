//
//  SearchPhotosResponse.swift
//  Virtual Tourist
//
//  Created by Kostas Lei on 29/04/2021.
//

import Foundation

struct SearchPhotosResponse: Codable{
    let photos: Photos
    let stat : String
}

struct PhotoDetails: Codable{
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}

struct Photos: Codable{
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [PhotoDetails]
}
