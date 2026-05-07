import SwiftUI

struct LocationsSheet: View {
    @Bindable var store: LocationStore
    let geocoder: any GeocodingClient

    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var results: [GeocodingResult] = []
    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("Search Results") {
                        if isSearching {
                            HStack { Spacer(); ProgressView(); Spacer() }
                        } else if results.isEmpty {
                            Text("No matches")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(results) { result in
                                Button {
                                    add(result)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.name)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Section("My Locations") {
                    ForEach(store.locations) { location in
                        Button {
                            store.select(location.id)
                            dismiss()
                        } label: {
                            HStack {
                                if location.isCurrentLocation {
                                    Image(systemName: "location.fill")
                                        .foregroundStyle(.blue)
                                }
                                Text(location.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if location.id == store.selectedID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        for i in offsets {
                            let loc = store.locations[i]
                            store.remove(loc)
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search city or zip")
            .onChange(of: query) { _, newValue in
                searchTask?.cancel()
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 2 else {
                    results = []
                    isSearching = false
                    return
                }
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    if Task.isCancelled { return }
                    isSearching = true
                    let r = (try? await geocoder.search(trimmed)) ?? []
                    if Task.isCancelled { return }
                    results = r
                    isSearching = false
                }
            }
            .navigationTitle("Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func add(_ result: GeocodingResult) {
        let added = store.add(name: result.name, coordinate: result.coordinate)
        store.select(added.id)
        dismiss()
    }
}
