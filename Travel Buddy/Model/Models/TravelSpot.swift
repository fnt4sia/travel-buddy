import CoreLocation
import Foundation

enum TravelSpotCategory: String, CaseIterable, Identifiable {
    case activities
    case food
    case nature

    var id: String { rawValue }
}

struct TravelSpot: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let category: TravelSpotCategory
    let coordinate: CLLocationCoordinate2D
    let imageURL: URL
    let description: String

    static let ubudSamples: [TravelSpot] = [
        TravelSpot(
            name: "Ubud Monkey Forest",
            address: "Jl. Monkey Forest, Ubud, Kecamatan Ubud, Kabupaten Gianyar, Bali 80571, Indonesia",
            category: .nature,
            coordinate: CLLocationCoordinate2D(latitude: -8.5194, longitude: 115.2606),
            imageURL: URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/Juvenile_monkey_at_Ubud_Monkey_Forest.jpg?width=900")!,
            description: "The sanctuary is a popular tourist attraction. It includes forest paths, ancient temples, and hundreds of Balinese long-tailed macaques living around Padangtegal village."
        ),
        TravelSpot(
            name: "Ubud Art Market",
            address: "Jl. Raya Ubud No.35, Ubud, Kecamatan Ubud, Kabupaten Gianyar, Bali 80571, Indonesia",
            category: .activities,
            coordinate: CLLocationCoordinate2D(latitude: -8.5069, longitude: 115.2624),
            imageURL: URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/UbudMarket.jpg?width=900")!,
            description: "A central market for woven bags, handmade crafts, textiles, souvenirs, and small local finds near Ubud Palace."
        ),
        TravelSpot(
            name: "Campuhan Ridge Walk",
            address: "Kelusa, Payangan, Kabupaten Gianyar, Bali 80571, Indonesia",
            category: .nature,
            coordinate: CLLocationCoordinate2D(latitude: -8.4977, longitude: 115.2525),
            imageURL: URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/Campuhan_Ridge_Walk%2C_Ubud%2C_Bali_%2815003876588%29.jpg?width=900")!,
            description: "A scenic ridge path with open greenery, soft morning light, and a calmer walking route just outside the busy center of Ubud."
        ),
        TravelSpot(
            name: "Pura Taman Saraswati",
            address: "Jl. Kajeng, Ubud, Kecamatan Ubud, Kabupaten Gianyar, Bali 80571, Indonesia",
            category: .activities,
            coordinate: CLLocationCoordinate2D(latitude: -8.5065, longitude: 115.2622),
            imageURL: URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/Pura_Taman_Saraswati.JPG?width=900")!,
            description: "A Balinese temple known for its lotus pond, carved stone details, and central location near cafes and art spaces."
        ),
        TravelSpot(
            name: "Ubud Night Market",
            address: "Jl. Raya Andong, Ubud, Kecamatan Ubud, Kabupaten Gianyar, Bali 80571, Indonesia",
            category: .food,
            coordinate: CLLocationCoordinate2D(latitude: -8.5008, longitude: 115.2668),
            imageURL: URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/Ubud_Night_Market_in_Bali.jpg?width=900")!,
            description: "A simple evening food stop with local snacks, warm dishes, and a busier street atmosphere after sunset."
        )
    ]
}
