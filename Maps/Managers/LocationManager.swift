import Foundation
import Combine
import CoreLocation
import MapKit

@MainActor
final class LocationManager: NSObject, ObservableObject {
    
    // MARK: - Properties
    private let manager = CLLocationManager()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = true
    @Published var locationUpdateTrigger = UUID() // Trigger per onChange
    @Published var savedPlaces: [Place] = []
    // MARK: - Computed Properties
    var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: userLocation ?? CLLocationCoordinate2D(latitude: 41.0842, longitude: 14.3358),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
    
    func addPlace(_ place:Place){
        savedPlaces.append(place)
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Public Methods
    func startUpdating() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    func centerOnUserLocation() {
        // Trigger per aggiornare la camera position
        objectWillChange.send()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            isLoading = false
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        isLoading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️ Errore nel recupero posizione: \(error.localizedDescription)")
        isLoading = false
    }
}
