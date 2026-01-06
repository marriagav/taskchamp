import CoreLocation
import MapKit
import SwiftUI
import taskchampShared

public struct LocationPickerView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var locationReminder: TCLocationReminder?

    @State var searchText = ""
    @State var searchResults: [MKLocalSearchCompletion] = []
    @State var selectedLocation: CLLocationCoordinate2D?
    @State var selectedLocationName = ""
    @State var radius: Double = 50
    @State var triggerOnArrival = true
    @State var triggerOnDeparture = false

    @State var cameraPosition: MapCameraPosition = .automatic
    @State var isSearching = false
    @State var showAuthorizationAlert = false
    @State var authorizationAlertMessage = ""

    @StateObject var searchCompleter = LocationSearchCompleter()

    let minRadius: Double = 50
    let maxRadius: Double = 500

    public init(locationReminder: Binding<TCLocationReminder?>) {
        _locationReminder = locationReminder

        if let existing = locationReminder.wrappedValue {
            _selectedLocation = State(initialValue: existing.coordinate)
            _selectedLocationName = State(initialValue: existing.locationName)
            _radius = State(initialValue: existing.radius)
            _triggerOnArrival = State(initialValue: existing.triggerOnArrival)
            _triggerOnDeparture = State(initialValue: existing.triggerOnDeparture)
            _cameraPosition = State(
                initialValue: .region(
                    MKCoordinateRegion(
                        center: existing.coordinate,
                        latitudinalMeters: existing.radius * 4,
                        longitudinalMeters: existing.radius * 4
                    )
                )
            )
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                    .padding()

                if isSearching && !searchResults.isEmpty {
                    searchResultsList
                } else {
                    mapView
                        .overlay(alignment: .bottom) {
                            if selectedLocation != nil {
                                locationConfigCard
                            }
                        }
                }
            }
            .navigationTitle("Location Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLocation()
                    }
                    .disabled(selectedLocation == nil)
                    .bold()
                }
            }
            .onAppear {
                checkLocationAuthorization()
            }
            .onChange(of: searchCompleter.results) { _, newResults in
                searchResults = newResults
            }
            .alert("Location Access", isPresented: $showAuthorizationAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(authorizationAlertMessage)
            }
        }
    }
}
