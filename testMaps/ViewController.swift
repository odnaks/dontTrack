//
//  ViewController.swift
//  testMaps
//
//  Created by Kseniya Lukoshkina on 25.09.2020.
//

import UIKit
import GoogleMaps
import RealmSwift

class ViewController: UIViewController {
    @IBOutlet weak var mapView: GMSMapView!
    
    private var locationManager: CLLocationManager?
    
    @IBOutlet weak var playImage: UIImageView!
    @IBOutlet weak var stopImage: UIImageView!
    
    var polyline: GMSPolyline?
    var path: GMSMutablePath?
    
    var isRunning: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLocationManager()
        locationManager?.delegate = self
        
        updateButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateButton()
    }
    
    private func updateButton() {
        if isRunning {
            playImage.isHidden = true
            stopImage.isHidden = false
        } else {
            playImage.isHidden = false
            stopImage.isHidden = true
        }
    }

    @IBAction func clickButton(_ sender: Any) {
        if !isRunning {
            start()
        } else {
            stop()
        }
        isRunning = !isRunning
        updateButton()
    }
    
    private func start() {
        locationManager?.startUpdatingLocation()
        polyline?.map = nil
        polyline = GMSPolyline()
        polyline?.strokeWidth = 5
        polyline?.strokeColor = .red
        polyline?.map = mapView
        path = GMSMutablePath()
    }
    
    private func stop() {
        locationManager?.stopUpdatingLocation()
        
        do {
            let realm = try Realm()
            print(realm.configuration.fileURL)
            let path = realm.objects(PathEntity.self)
            realm.beginWrite()
            if path.isEmpty {
                let firstPath = PathEntity()
                firstPath.encodedPath = self.path?.encodedPath()
                realm.add(firstPath)
            } else {
                path[0].encodedPath = self.path?.encodedPath()
            }
            try realm.commitWrite()
        } catch {
            print(error)
        }

    }
    
    private func configureLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
//        locationManager?.requestWhenInUseAuthorization()
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.startMonitoringSignificantLocationChanges()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestAlwaysAuthorization()
//        locationManager?.startUpdatingLocation()
    }
    
    private func addMarker(coordinate: CLLocationCoordinate2D) {
        let marker = GMSMarker(position: coordinate)
        marker.map = mapView
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else {return}
        
        path?.add(location.coordinate)
        polyline?.path = path
        
        let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 15)
//        mapView.camera = camera
//        addMarker(coordinate: location.coordinate)
        mapView.animate(to: camera)
    }
}
