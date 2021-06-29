//
//  FlickerClient.swift
//  Virtual Tourist
//
//  Created by Kostas Lei on 29/04/2021.
//

import Foundation
import CoreData
import UIKit

class FlickerClient {
    
    
    // ENDPOINTS ENUM: Stores all of my urls as strings and then it transforms them to URL type
    enum Endpoints{
        static let key = "&api_key=11ae8dc296220a7263ae248d40d615df"
        static let baseSearch = "https://www.flickr.com/services/rest"
        static let searchPhotoMethod = "/?method=flickr.photos.search"
        static let searchPhotoMethodEnd = "&radius=5&format=json&nojsoncallback=1"
        
        case searchPhoto(Double,Double, Int)
        case downloadPhoto(String, String, String)
        
        var stringValue:String {
            switch self {
            case .searchPhoto(let lat, let lon, let page): return (Endpoints.baseSearch + Endpoints.searchPhotoMethod + Endpoints.key + "&lat=\(lat)" + "&lon=\(lon)" + "&page=\(page)" + Endpoints.searchPhotoMethodEnd)
            case .downloadPhoto(let server, let id, let secret): return "https://live.staticflickr.com/\(server)/\(id)_\(secret)_w.jpg"
            }
        }
        
        // Make url's from strings
        var url: URL{
            return URL(string: stringValue)!
        }
    }
    
    // TASK_FOR_GET_REQUEST FUNC: It communicates with a given url and return the
    // data with a completion handler
    @discardableResult class func taskForGETRequest<ResponseType:Decodable>(url:URL, response:ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask{
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async{
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do{
                    let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil,errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async{
                        completion(nil, error)}
                }
            }
        }
        task.resume()
        
        return task
    }
    
   
    // Downloads and stores the photos
    class func downloadPhotos(dataController: DataController, pin: Pin, noImagesLabel: UILabel, pageNumber: Int) {
        
        FlickerClient.taskForGETRequest(url: FlickerClient.Endpoints.searchPhoto(pin.latitude, pin.longitude, pageNumber).url, response: SearchPhotosResponse.self) { response, error in
            
            let backgroundContext:NSManagedObjectContext! = dataController.backgroundContext
            let pinID = pin.objectID
            
            if let response = response{
                // If there are photos for the given location
                if response.photos.photo.count > 0 {
                    // Download and store photos on a background thread
                    backgroundContext.perform {
                        // Makes an instance of the pin using the id, stores number of pages, download status and the photos
                        let backgroundPin = backgroundContext.object(with: pinID) as! Pin
                        backgroundPin.pages = Int16(response.photos.pages)
                        backgroundPin.downloadStatus = true
                        for i in response.photos.photo {
                            let photo = Photo(context: dataController.backgroundContext)
                            let url = FlickerClient.Endpoints.downloadPhoto(i.server, i.id, i.secret).url
                            if let data = try? Data(contentsOf: url) {
                                // Create Image and Update Image View
                                photo.img = data
                                photo.pin = backgroundPin
                            }
                            try? backgroundContext.save()
                        }
                        backgroundPin.downloadStatus = false
                        try? backgroundContext.save()
                    }
                }
                // If there are no photos for this location
                else{
                    noImagesLabel.isHidden = false
                }
            }
            else {
                print("Error", fatalError())
            }
        }
    }
}
