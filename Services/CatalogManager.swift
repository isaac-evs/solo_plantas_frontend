import Foundation
import Combine

@MainActor
class CatalogManager: ObservableObject {
    static let shared = CatalogManager()
    
    @Published var cachedCatalog: [PlantSpecies] = []
    @Published var recommendedPlants: [PlantSpecies] = []
    private var hasFetchedCatalog = false
    
    private init() {}
    
    func fetchCatalog(forceRefresh: Bool = false) async throws {
        if hasFetchedCatalog && !forceRefresh && !cachedCatalog.isEmpty {
            return
        }
        
        let fetched: [PlantSpecies] = try await NetworkManager.shared.request(
            endpoint: "/catalog",
            method: "GET"
        )
        
        self.cachedCatalog = fetched
        self.hasFetchedCatalog = true
    }
    
    func fetchRecommendations(lat: Double = 0, lon: Double = 0) async throws {
        let fetched: [PlantSpecies] = try await NetworkManager.shared.request(
            endpoint: "/catalog/recommendations?lat=\(lat)&lon=\(lon)",
            method: "GET"
        )
        self.recommendedPlants = fetched
    }
    
    func refresh() async throws {
        try await fetchCatalog(forceRefresh: true)
        try await fetchRecommendations()
    }
}
