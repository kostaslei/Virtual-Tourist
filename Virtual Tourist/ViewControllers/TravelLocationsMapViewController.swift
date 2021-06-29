//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Kostas Lei on 28/04/2021.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    var saveObserverToken: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Instantiate a TapGestureRecognizer
        let tap = UILongPressGestureRecognizer(target: self, action: #selector(tapMapView(_:)))
        tap.minimumPressDuration = 0.5
        navigationController?.navigationBar.isHidden = true
        mapViewSetup()
        mapView.addGestureRecognizer(tap)
        mapView.delegate = self
        
        addSaveNotificationObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        // Removes previous annotations
        mapView.removeAnnotations(mapView.annotations)
        fetchRequest()
        fetchedResultsController.delegate = self
        // Make the annotations from the stored data
        for i in fetchedResultsController.fetchedObjects! {
            let myPin:MKPointAnnotation = MKPointAnnotation()
            myPin.coordinate = CLLocationCoordinate2D(latitude: i.latitude, longitude: i.longitude)
            mapView.addAnnotation(myPin)
        }
    }
    // Deinitialize the observer
    deinit {
        removeSaveNotificationObserver()
    }
  
    // MARK: Helper Functions
    // Setup MapView: Controls the center,span of the map
    func mapViewSetup() {
        mapView.region.center = CLLocationCoordinate2D(latitude: 47.904175, longitude: 18.849911)
        mapView.region.span = MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
    }

    // Controls the tap gesture
    @objc func tapMapView(_ sender: UILongPressGestureRecognizer){
        //When lognpress is stopped
        if sender.state == UIGestureRecognizer.State.ended {
            
            // Gives the CGPoint the user tapped
            let location = sender.location(in: mapView)
            
            // Converts the CGPoint to CLLocationCoordinates2D
            let coordinates: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
            
            // Makes a pin to the mapView
            let myPin:MKPointAnnotation = MKPointAnnotation()
            myPin.coordinate = coordinates
            myPin.title = "\(coordinates)"
            mapView.addAnnotation(myPin)
            
            // Saves Pin in our store
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = coordinates.latitude
            pin.longitude = coordinates.longitude
            try? dataController.viewContext.save()
        }
    }
        
    // Fetch request, ask the code to show us a place in the storage
     func fetchRequest() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do{
            try fetchedResultsController.performFetch()
            
        } catch {
            fatalError("the fetch could not be performed: \(error.localizedDescription)")
        }
    }
}

// MARK: MapViewDelegate
extension TravelLocationsMapViewController: MKMapViewDelegate,NSFetchedResultsControllerDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let myPinIdentifier = "PinAnnotationIdentifier"
            
            // Generate pins.
            let myPinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: myPinIdentifier)
            
            // Add animation.
            myPinView.animatesDrop = true
            
            // Display callouts.
            myPinView.canShowCallout = true
            
            // Set annotation.
            myPinView.annotation = annotation
            return myPinView
        }
    
    // When the user selects a pin, is transfearing modally to the PhotoAlbumViewController.
    // Also data are injecting to the new ViewController.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let vc = storyboard?.instantiateViewController(identifier: "photoVC") as! PhotoAlbumViewController
        vc.dataController = dataController
        for i in fetchedResultsController.fetchedObjects!{
            if i.latitude == view.annotation?.coordinate.latitude && i.longitude == view.annotation?.coordinate.longitude {
                vc.pin = i
            }
        }
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
}

// MARK: OBSERVER EXTENSION
extension TravelLocationsMapViewController{
    func addSaveNotificationObserver() {
        removeSaveNotificationObserver()
        saveObserverToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave,object: dataController.viewContext,queue: nil, using: handleSaveNotification(notification:))
    }
    func removeSaveNotificationObserver() {
        if let token = saveObserverToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    func handleSaveNotification(notification: Notification){
        DispatchQueue.main.async {
            self.fetchRequest()
        }
    }
}
