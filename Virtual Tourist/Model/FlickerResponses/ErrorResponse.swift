//
//  File.swift
//  Virtual Tourist
//
//  Created by Kostas Lei on 29/04/2021.
//

import Foundation


struct ErrorResponse: Codable{
    let stat: String
    let code: Int
    let message: String
    
    
}

extension ErrorResponse:LocalizedError{
    var errorDescription: String? {
        return message
    }
}
