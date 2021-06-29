//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Kostas Lei on 28/04/2021.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegateFlowLayout{
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var noImagesLabel: UILabel!
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    var pin : Pin!
    let myPin:MKPointAnnotation = MKPointAnnotation()
    
    // Helps the url download new collection
    var photosInPage: Int = 1
    var saveObserverToken: Any?
    
    var downloadInProgressFlag: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the mapView
        mapViewSetup()
        
        // Set up the collectionView
        collectionViewSetup()
        
        // Set up the view objects when there is download action
        downloadingInProgressSetup()
        
        addSaveNotificationObserver()
        noImagesLabel.isHidden = true
    }
    
    // Deinitialize the observer
    deinit {
        removeSaveNotificationObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        fetchRequest()
        fetchedResultsController.delegate = self
        
        // If there are no stored data, it downloads and store a new photo collection
        if fetchedResultsController.fetchedObjects?.isEmpty == true{
            FlickerClient.downloadPhotos(dataController: dataController, pin: pin, noImagesLabel: noImagesLabel, pageNumber: 1)
        }
    }
    
    
    // Delete a photo at a given indexPath
    func deletePhoto(indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
    }
    
    // MARK: FETCH REQUEST
    func fetchRequest() {
        let predicate = NSPredicate(format: "pin == %@", pin)
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "img", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do{
            try fetchedResultsController.performFetch()
            
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: BUTTON ACTIONS
    @IBAction func okButtonAction(_ sender: Any) {
        mapView.removeAnnotation(myPin)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func newData(_ sender: Any) {
        // Delete previous stored photos
        for i in fetchedResultsController.fetchedObjects!{
            dataController.viewContext.delete(i)
            try? dataController.viewContext.save()
        }
        
        // Download and store a random photo collection from the available pages
        let object = dataController.viewContext.object(with: pin.objectID) as! Pin
        if Int(object.pages) >= 1 {
            FlickerClient.downloadPhotos(dataController: dataController, pin: pin, noImagesLabel: noImagesLabel, pageNumber: Int.random(in: 1...Int(object.pages)))
        }
        else {
            FlickerClient.downloadPhotos(dataController: dataController, pin: pin, noImagesLabel: noImagesLabel, pageNumber: 1)
        }
    }
    
    // MARK: VIEW SETUP
    func downloadingInProgressSetup() {
        let object = dataController.viewContext.object(with: pin.objectID) as! Pin
        if object.downloadStatus == true {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            newCollectionButton.isEnabled = false
            stackView.alpha = 0.6
        }
        else {
            activityIndicator.isHidden = true
            activityIndicator.stopAnimating()
            newCollectionButton.isEnabled = true
            stackView.alpha = 1
        }
    }
    
    // Makes the pin and centers the mapView
    func mapViewSetup() {
        myPin.coordinate.latitude = pin.latitude
        myPin.coordinate.longitude = pin.longitude
        mapView.addAnnotation(myPin)
        mapView.region.center = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        mapView.region.span = MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
    }
    
    // Set up the collectionViewLayout
    func collectionViewSetup() {
        collectionView.collectionViewLayout = collectionViewFlowLayout
        let space:CGFloat = 5.0
        let dimensionX = (collectionView.frame.size.width - (2 * space)) / 3.0
        let dimensionY = (collectionView.frame.size.height - (4 * space)) / 4.0
        collectionViewFlowLayout.minimumInteritemSpacing = space
        collectionViewFlowLayout.minimumLineSpacing = space
        collectionViewFlowLayout.itemSize = CGSize(width: dimensionX, height: dimensionY)
    }
}

// MARK: CollectionView setup extension
extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    // Number of sections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    // Number of cells
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    // Cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let object = dataController.viewContext.object(with: pin.objectID) as! Pin
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
        if object.downloadStatus == true{
            cell.imageView.image = UIImage(systemName: "photo.fill")
        }
        else{
            cell.imageView.image = UIImage(data: self.fetchedResultsController.object(at: indexPath).img!)
        }
        return cell
    }
    
    // When select a cell, deletes the image
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        deletePhoto(indexPath: indexPath)
    }
}

// MARK: NSFetchedResultsControllerDelegate extension
// Deletes from the store an item with a given indexPath
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate{

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
        default:
            break
        }
    }
}

// MARK: OBSERVER SETUP
extension PhotoAlbumViewController{
    // Adds an observer who observes when we try to save context in our store
    func addSaveNotificationObserver() {
        removeSaveNotificationObserver()
        saveObserverToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextWillSave, object: dataController.backgroundContext, queue: nil, using: handleSaveNotification(notification:))
    }
    
    // Removes the observer
    func removeSaveNotificationObserver() {
        if let token = saveObserverToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    // Action for the observer
    func handleSaveNotification(notification: Notification){
        DispatchQueue.main.async {
            self.fetchRequest()
            self.downloadingInProgressSetup()
            self.collectionView.reloadData()
        }
    }
}

// MapView Delegate. Sets pin.
extension PhotoAlbumViewController: MKMapViewDelegate{
    
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
}
