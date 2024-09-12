//
//  LocationPickerViewController.swift
//  MessengerUIKit2024
//
//  Created by Andrei Harnashevich on 12.09.24.
//

import UIKit
import CoreLocation
import MapKit

final class LocationPickerViewController: UIViewController {
    
    public var completion : ((CLLocationCoordinate2D) -> Void)?
    private var  coordinates : CLLocationCoordinate2D?
    private var isPickable = true
    
    private let map : MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    init(coordinates : CLLocationCoordinate2D?) {
        if let coord = coordinates {
            self.coordinates = coord
            self.isPickable = false
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        if isPickable == true {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send location" , style: .done, target: self, action: #selector(didTapSendLocation))
            map.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
        } else {
            guard let coordinates else { return }
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        view.addSubview(map)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
    
    @objc func didTapSendLocation(){
        guard let coordinates else { return }
        navigationController?.popViewController(animated: true)
        completion?(coordinates)
    }
    
    @objc func didTapMap(_ gesture : UITapGestureRecognizer){
        let locationView = gesture.location(in: map)
        let coordinates = map.convert(locationView, toCoordinateFrom: map)
        
        self.coordinates = coordinates
        print(coordinates.latitude)
        print(coordinates.longitude)
        
        for annotation in map.annotations{
            map.removeAnnotation(annotation)
        }
        
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
    }
}
