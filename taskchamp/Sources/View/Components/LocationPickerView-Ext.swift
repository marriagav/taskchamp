import CoreLocation
import MapKit
import SwiftUI
import taskchampShared

// MARK: - LocationPickerView Subviews

extension LocationPickerView {
    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search for a location", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onChange(of: searchText) { _, newValue in
                    isSearching = !newValue.isEmpty
                    searchCompleter.search(query: newValue)
                }
                .onSubmit {
                    if let first = searchResults.first {
                        selectSearchResult(first)
                    }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    isSearching = false
                    searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    var searchResultsList: some View {
        List(searchResults, id: \.self) { result in
            Button {
                selectSearchResult(result)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .foregroundColor(.primary)
                    if !result.subtitle.isEmpty {
                        Text(result.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    var mapView: some View {
        Map(position: $cameraPosition) {
            if let location = selectedLocation {
                Marker(selectedLocationName, coordinate: location)
                    .tint(.blue)

                MapCircle(center: location, radius: radius)
                    .foregroundStyle(.blue.opacity(0.2))
                    .stroke(.blue, lineWidth: 2)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }

    var locationConfigCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text(selectedLocationName)
                        .font(.headline)
                        .lineLimit(1)
                    Text("Tap map to change location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(role: .destructive) {
                    clearLocation()
                } label: {
                    Image(systemName: "trash")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Radius: \(Int(radius))m")
                        .font(.subheadline)
                    Spacer()
                }

                Slider(value: $radius, in: minRadius ... maxRadius, step: 10) {
                    Text("Radius")
                }
                .onChange(of: radius) { _, newRadius in
                    updateMapRegion(with: newRadius)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Trigger when:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Toggle("Arriving", isOn: $triggerOnArrival)
                        .toggleStyle(.button)
                        .buttonStyle(.bordered)
                        .tint(triggerOnArrival ? .blue : .gray)

                    Toggle("Leaving", isOn: $triggerOnDeparture)
                        .toggleStyle(.button)
                        .buttonStyle(.bordered)
                        .tint(triggerOnDeparture ? .blue : .gray)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .padding()
    }
}

// MARK: - LocationPickerView Methods

extension LocationPickerView {
    func selectSearchResult(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)

        search.start { response, error in
            if let error {
                print("Search error: \(error.localizedDescription)")
                return
            }

            guard let mapItem = response?.mapItems.first else {
                return
            }

            let coordinate = mapItem.placemark.coordinate
            selectedLocation = coordinate
            selectedLocationName = result.title

            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: radius * 4,
                    longitudinalMeters: radius * 4
                )
            )

            searchText = ""
            isSearching = false
            searchResults = []
        }
    }

    func updateMapRegion(with newRadius: Double) {
        guard let location = selectedLocation else { return }

        cameraPosition = .region(
            MKCoordinateRegion(
                center: location,
                latitudinalMeters: newRadius * 4,
                longitudinalMeters: newRadius * 4
            )
        )
    }

    func clearLocation() {
        selectedLocation = nil
        selectedLocationName = ""
        radius = 50
        triggerOnArrival = true
        triggerOnDeparture = false
        cameraPosition = .automatic
    }

    func saveLocation() {
        guard let location = selectedLocation else {
            dismiss()
            return
        }

        locationReminder = TCLocationReminder(
            locationName: selectedLocationName,
            latitude: location.latitude,
            longitude: location.longitude,
            radius: radius,
            triggerOnArrival: triggerOnArrival,
            triggerOnDeparture: triggerOnDeparture
        )

        dismiss()
    }

    func checkLocationAuthorization() {
        let status = LocationService.shared.authorizationStatus

        switch status {
        case .notDetermined:
            LocationService.shared.requestWhenInUseAuthorization()
        case .denied, .restricted:
            authorizationAlertMessage =
                "Location access is required for location-based reminders. Please enable location access in Settings."
            showAuthorizationAlert = true
        case .authorizedWhenInUse:
            if locationReminder != nil {
                // swiftlint:disable:next line_length
                authorizationAlertMessage = "For location reminders to work in the background, please enable 'Always' location access in Settings."
                showAuthorizationAlert = true
            }
        case .authorizedAlways:
            break
        }
    }
}
