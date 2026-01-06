import CoreLocation
import Foundation
import UserNotifications

public struct TCLocationReminder: Codable, Hashable, Equatable {
    public var locationName: String
    public var latitude: Double
    public var longitude: Double
    public var radius: Double
    public var triggerOnArrival: Bool
    public var triggerOnDeparture: Bool

    public init(
        locationName: String,
        latitude: Double,
        longitude: Double,
        radius: Double = 50,
        triggerOnArrival: Bool = true,
        triggerOnDeparture: Bool = false
    ) {
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.triggerOnArrival = triggerOnArrival
        self.triggerOnDeparture = triggerOnDeparture
    }

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

public enum LocationAuthorizationStatus {
    case notDetermined
    case denied
    case authorizedWhenInUse
    case authorizedAlways
    case restricted

    public var canMonitorRegions: Bool {
        self == .authorizedAlways
    }

    public var isAuthorized: Bool {
        self == .authorizedWhenInUse || self == .authorizedAlways
    }
}

public class LocationService: NSObject {
    public static let shared = LocationService()

    private let locationManager = CLLocationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let maxMonitoredRegions = 20

    public var authorizationStatus: LocationAuthorizationStatus {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorizedWhenInUse:
            return .authorizedWhenInUse
        case .authorizedAlways:
            return .authorizedAlways
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }

    public var canMonitorRegions: Bool {
        CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
            && authorizationStatus.canMonitorRegions
    }

    public var currentMonitoredRegionCount: Int {
        locationManager.monitoredRegions.count
    }

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    public func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    public func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    public func startMonitoringRegion(for task: TCTask) {
        guard let locationReminder = task.locationReminder else {
            return
        }

        guard canMonitorRegions else {
            print("Location monitoring not available or not authorized")
            return
        }

        if currentMonitoredRegionCount >= maxMonitoredRegions {
            print("Maximum monitored regions reached (\(maxMonitoredRegions))")
            return
        }

        let region = CLCircularRegion(
            center: locationReminder.coordinate,
            radius: min(locationReminder.radius, locationManager.maximumRegionMonitoringDistance),
            identifier: task.uuid
        )

        region.notifyOnEntry = locationReminder.triggerOnArrival
        region.notifyOnExit = locationReminder.triggerOnDeparture

        locationManager.startMonitoring(for: region)
    }

    public func stopMonitoringRegion(for taskUuid: String) {
        for region in locationManager.monitoredRegions where region.identifier == taskUuid {
            locationManager.stopMonitoring(for: region)
            break
        }
    }

    public func stopMonitoringAllRegions() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
    }

    public func reregisterGeofences(for tasks: [TCTask]) {
        stopMonitoringAllRegions()

        let tasksWithLocation = tasks
            .filter { $0.locationReminder != nil && $0.status == .pending }
            .sorted { task1, task2 in
                if let due1 = task1.due, let due2 = task2.due {
                    return due1 < due2
                } else if task1.due != nil {
                    return true
                } else {
                    return false
                }
            }

        let tasksToMonitor = Array(tasksWithLocation.prefix(maxMonitoredRegions))

        for task in tasksToMonitor {
            startMonitoringRegion(for: task)
        }
    }

    public func isMonitoring(taskUuid: String) -> Bool {
        locationManager.monitoredRegions.contains { $0.identifier == taskUuid }
    }

    private func createLocationNotification(for region: CLRegion, isEntering: Bool) {
        guard let circularRegion = region as? CLCircularRegion else {
            return
        }

        let taskUuid = circularRegion.identifier

        Task { @MainActor in
            do {
                let task = try TaskchampionService.shared.getTask(uuid: taskUuid)

                guard task.status == .pending else {
                    self.stopMonitoringRegion(for: taskUuid)
                    return
                }

                guard let locationReminder = task.locationReminder else {
                    return
                }

                let content = UNMutableNotificationContent()
                content.title = task.description

                let triggerType = isEntering ? "Arrived at" : "Left"
                content.body = "\(triggerType) \(locationReminder.locationName)"
                content.sound = .default
                content.interruptionLevel = .timeSensitive
                content.userInfo = ["deepLink": task.url.description]

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

                let request = UNNotificationRequest(
                    identifier: "location-\(taskUuid)-\(Date().timeIntervalSince1970)",
                    content: content,
                    trigger: trigger
                )

                self.notificationCenter.add(request)
            } catch {
                print("Failed to get task for location notification: \(error)")
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        NotificationCenter.default.post(
            name: .TCLocationAuthorizationChanged,
            object: authorizationStatus
        )
    }

    public func locationManager(_: CLLocationManager, didEnterRegion region: CLRegion) {
        createLocationNotification(for: region, isEntering: true)
    }

    public func locationManager(_: CLLocationManager, didExitRegion region: CLRegion) {
        createLocationNotification(for: region, isEntering: false)
    }

    public func locationManager(_: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Region monitoring failed for \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
    }

    public func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
}

public extension NSNotification.Name {
    static let TCLocationAuthorizationChanged = NSNotification.Name("TCLocationAuthorizationChanged")
}
