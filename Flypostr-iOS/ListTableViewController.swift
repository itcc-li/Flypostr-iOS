//
//  ListTableViewController.swift
//  Flypostr-iOS
//
//  Created by Christian Schweig on 30.07.16.
//  Copyright © 2016 itcc. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage

class ListTableViewController: UITableViewController, CLLocationManagerDelegate  {
    
    let locationManager = CLLocationManager()
    var currentPosition = CLLocationCoordinate2D()
    var regionQuery = GFRegionQuery()
    var keyArray = NSMutableArray()
    var postingsArray = [PostrAnnotation]()
    let geoFire = GeoFire(firebaseRef: FIRDatabase.database().reference(withPath: "geofire"))
    let postings = FIRDatabase.database().reference(withPath: "postings")
    var postrToPass = PostrAnnotation(key: "", title: "", subtitle: "", coordinate: CLLocation().coordinate, authorId: "", author: "", imageId: "", createdAt: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        let dummyLocation = CLLocation()
        let span = MKCoordinateSpanMake(0.800, 0.800)
        let region = MKCoordinateRegionMake(dummyLocation.coordinate, span)
        self.regionQuery = (geoFire?.query(with: region))!
        
        /*
        self.regionQuery.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
            print("Key '\(key)' entered the search area and is at location '\(location)'")
            
            var found = false
            
            for item in self.keyArray {
                if (item as! String == key) {
                    found = true
                    break
                }
            }
            if !found {
                self.keyArray.add(key)
                
                self.geoFire.getLocationForKey(key as String, withCallback: { (location, error) in
                    if (error != nil) {
                        print("An error occurred getting the location for \(key): \(error.localizedDescription)")
                    } else if (location != nil) {
                        print("Location for \(key) is [\(location.coordinate.latitude), \(location.coordinate.longitude)]")
                        
                        let postrAnno = PostrAnnotation(key: key, title: "", subtitle: "", coordinate: location.coordinate, authorId: "", author: "", imageId: "", createdAt: "")
                        
                        self.postings.child(key).observe(FIRDataEventType.value, with: { (snapshot) in
                            let postDict = snapshot.value as! [String : AnyObject]
                            postrAnno.title = postDict["title"] as! String?
                            postrAnno.subtitle = postDict["text"] as! String?
                            postrAnno.authorId = postDict["authorId"] as! String?
                            postrAnno.author = postDict["author"] as! String?
                            postrAnno.imageId = postDict["imageId"] as! String?
                            postrAnno.createdAt = postDict["createdAt"] as! String?
                            self.postingsArray.append(postrAnno)
                        })
                    } else {
                        print("GeoFire does not contain a location for \"firebase-hq\"")
                    }
                })
                
            }
        })*/
        /*
        self.regionQuery.observe(.keyExited, with: { (key: String!, location: CLLocation!) in
            print("Key '\(key)' exited the search area and is at location '\(location)'")
            var index = 0
            for item: PostrAnnotation in self.postingsArray {
                if (item.key == key) {
                    self.postingsArray.remove(at: index)
                }
                index = index + 1
            }
            self.keyArray.remove(key)
        })
         */
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = manager.location!.coordinate
        self.currentPosition = newLocation
        
        let userLocation = CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude)
        let span = MKCoordinateSpanMake(0.800, 0.800)
        let region = MKCoordinateRegionMake(userLocation.coordinate, span)
        self.regionQuery.region = region
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.postingsArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        
        cell.textLabel!.text = self.postingsArray[indexPath.row].title
        cell.detailTextLabel!.text = self.postingsArray[indexPath.row].subtitle
        let storage = FIRStorage.storage()
        let storageRef = storage.reference(forURL: "gs://flypostr-cd317.appspot.com/thumbnails/")
        if (self.postingsArray[indexPath.row].imageId != nil) {
            let imageRef = storageRef.child(self.postingsArray[indexPath.row].imageId!)
            imageRef.data(withMaxSize: 1 * 1024 * 1024) { (data, error) -> Void in
                if (error != nil) {
                    print("Error while downloading some Firebase Storage")
                } else {
                    let image: UIImage! = UIImage(data: data!)
                    //let imageView = UIImageView(image: image)
                    //imageView.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
                    cell.imageView?.image = image
                }
            }
        }
        cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.postrToPass = self.postingsArray[indexPath.row]
        self.performSegue(withIdentifier: "showDetails", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            let targetController = segue.destination as! DetailTableViewController
            targetController.postr = self.postrToPass
        }
    }
    
}
