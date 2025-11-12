//
//  Models.swift
//  Maps
//
//  Created by Antimo Bucciero on 12/11/25.
//

import Foundation
import CoreLocation

// MARK: - Place Model
struct Place: Identifiable, Codable {
    let id: UUID
    var name: String
    var coordinate: CLLocationCoordinate2D
    var category: PlaceCategory
    var address: String?
    var notes: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        coordinate: CLLocationCoordinate2D,
        category: PlaceCategory,
        address: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.category = category
        self.address = address
        self.notes = notes
    }
    
    // Codable conformance per CLLocationCoordinate2D
    enum CodingKeys: String, CodingKey {
        case id, name, category, address, notes
        case latitude, longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(PlaceCategory.self, forKey: .category)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}

// MARK: - Place Category
enum PlaceCategory: String, CaseIterable, Codable {
    case home = "house.fill"
    case work = "briefcase.fill"
    case favorite = "star.fill"
    case restaurant = "fork.knife"
    case shopping = "cart.fill"
    case gym = "figure.run"
    case other = "mappin.circle.fill"
    
    var displayName: String {
        switch self {
        case .home: return "Casa"
        case .work: return "Lavoro"
        case .favorite: return "Preferito"
        case .restaurant: return "Ristorante"
        case .shopping: return "Shopping"
        case .gym: return "Palestra"
        case .other: return "Altro"
        }
    }
    
    var color: String {
        switch self {
        case .home: return "green"
        case .work: return "orange"
        case .favorite: return "yellow"
        case .restaurant: return "red"
        case .shopping: return "blue"
        case .gym: return "purple"
        case .other: return "gray"
        }
    }
}

// MARK: - Sample Data (per testing)
extension Place {
    static var samples: [Place] {
        [
            Place(
                name: "Casa",
                coordinate: CLLocationCoordinate2D(latitude: 41.0842, longitude: 14.3358),
                category: .home,
                address: "Via Roma 1, Benevento"
            ),
            Place(
                name: "Ufficio",
                coordinate: CLLocationCoordinate2D(latitude: 41.0862, longitude: 14.3378),
                category: .work,
                address: "Via Milano 10, Benevento"
            ),
            Place(
                name: "Ristorante Preferito",
                coordinate: CLLocationCoordinate2D(latitude: 41.0822, longitude: 14.3338),
                category: .restaurant,
                address: "Piazza Duomo 5, Benevento"
            )
        ]
    }
}
