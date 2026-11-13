//
//  LocationSearchService.swift
//  SZSIM
//

import MapKit

/// Errors from address search.
enum LocationSearchError: Error {
    case notFound
}

/// An autocomplete suggestion.
struct SearchSuggestion: Identifiable, Hashable, Sendable {
    let title: String
    let subtitle: String
    var id: String { title + "\u{1F}" + subtitle }
}

/// Address autocomplete and resolution using only native MapKit.
///
/// `MKLocalSearchCompleter` is fed with a 300 ms debounce to honor Apple's
/// "at the user's pace" model — never a search per keystroke.
@MainActor
@Observable
final class LocationSearchService: NSObject {
    private(set) var suggestions: [SearchSuggestion] = []

    private let completer: MKLocalSearchCompleter
    private let debounceInterval: Duration
    private var debounceTask: Task<Void, Never>?

    init(debounceInterval: Duration = .milliseconds(300)) {
        self.debounceInterval = debounceInterval
        self.completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    /// Updates the search fragment with debounce.
    func update(query: String) {
        debounceTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestions = []
            completer.queryFragment = ""
            return
        }
        debounceTask = Task { [weak self, interval = debounceInterval] in
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            self?.completer.queryFragment = trimmed
        }
    }

    /// Resolves a suggestion into a coordinate via `MKLocalSearch`.
    func resolve(_ suggestion: SearchSuggestion) async throws -> CLLocationCoordinate2D {
        try await search("\(suggestion.title) \(suggestion.subtitle)")
    }

    /// Free-text search; also accepts a pasted "lat, lon".
    func search(_ text: String) async throws -> CLLocationCoordinate2D {
        if let coordinate = CoordinateParser.parse(text) {
            return coordinate
        }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else { throw LocationSearchError.notFound }
        return item.location.coordinate
    }
}

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results.map { SearchSuggestion(title: $0.title, subtitle: $0.subtitle) }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        suggestions = []
    }
}
