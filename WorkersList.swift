import SwiftUI
import Foundation
import Combine

// MARK: - Model

struct Worker: Codable, Identifiable {
    let userID: Int
    let userName: String
    var locationName: String?
    var id: Int { userID }
}

enum SortOption: String, CaseIterable, Identifiable {
    case name     = "Name"
    case location = "Standort"
    var id: Self { self }
}

// Helper to decode JSON
private func decodeMitarbeiter() -> [Worker] {
    guard let url = Bundle.main.url(forResource: "Mitarbeiter", withExtension: "json") else {
        return []
    }
    do {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Worker].self, from: data)
    } catch {
        print("Fehler beim Laden der Mitarbeiter: \(error)")
        return []
    }
}

// MARK: - ViewModel

final class WorkersListViewModel: ObservableObject {
    // Eingaben
    @Published var sortOption: SortOption = .name
    @Published var searchText: String = ""
    
    // Rohdaten
    @Published private(set) var allWorkers: [Worker] = []
    
    // Gefilterte und sortierte Ausgabe
    var filteredWorkers: [Worker] {
        let filtered = allWorkers.filter { worker in
            searchText.isEmpty || worker.userName.localizedCaseInsensitiveContains(searchText)
        }
        switch sortOption {
        case .name:
            return filtered.sorted { $0.userName < $1.userName }
        case .location:
            return filtered.sorted {
                switch ($0.locationName, $1.locationName) {
                case let (a?, b?):    return a < b
                case (_?, nil):       return true
                case (nil, _?):       return false
                case (nil, nil):      return $0.userName < $1.userName
                }
            }
        }
    }
    
    init() {
        loadWorkers()
    }
    
    private func loadWorkers() {
        allWorkers = decodeMitarbeiter()
    }
}

// MARK: - View

struct WorkersListView: View {
    @StateObject private var viewModel = WorkersListViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Sortieren nach:")
                        .padding(.horizontal, 30)
                    Picker("Sortieren nach", selection: $viewModel.sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.trailing, 30)
                }
                
                List(viewModel.filteredWorkers) { worker in
                    HStack {
                        Image(systemName: worker.locationName == nil
                              ? "person.crop.circle.badge.xmark"
                              : "person.crop.circle.badge.checkmark")
                            .foregroundColor(worker.locationName == nil ? .red : .green)
                        
                        Text(worker.userName)
                        Spacer()
                        if let loc = worker.locationName {
                            Text(loc)
                                .foregroundStyle(.gray)
                        } else {
                            Text("Abwesend")
                                .foregroundStyle(.red)
                        }
                    }
                }
                .searchable(
                    text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Namen suchen"
                )
            }
            .navigationTitle("Mitarbeiter Suche")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// Preview
struct WorkersListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkersListView()
    }
}
