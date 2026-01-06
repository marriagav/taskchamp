import Foundation

/// Represents the volume preset options for critical alerts
public enum TCCriticalAlertVolumePreset: String, Codable, Hashable, CaseIterable {
    case full = "100"
    case threeQuarter = "75"
    case half = "50"
    case quarter = "25"
    case custom = "custom"

    public var displayName: String {
        switch self {
        case .full:
            return "100%"
        case .threeQuarter:
            return "75%"
        case .half:
            return "50%"
        case .quarter:
            return "25%"
        case .custom:
            return "Custom"
        }
    }

    public var volumeValue: Float {
        switch self {
        case .full:
            return 1.0
        case .threeQuarter:
            return 0.75
        case .half:
            return 0.5
        case .quarter:
            return 0.25
        case .custom:
            return 1.0
        }
    }
}

/// Represents critical alert settings for a task reminder
public struct TCCriticalAlert: Codable, Hashable, Equatable {
    public var isEnabled: Bool
    public var volumePreset: TCCriticalAlertVolumePreset
    public var customVolume: Float

    public init(
        isEnabled: Bool = false,
        volumePreset: TCCriticalAlertVolumePreset = .full,
        customVolume: Float = 1.0
    ) {
        self.isEnabled = isEnabled
        self.volumePreset = volumePreset
        self.customVolume = max(0.1, min(1.0, customVolume))
    }

    /// Returns the effective volume based on preset or custom value
    public var effectiveVolume: Float {
        if volumePreset == .custom {
            return customVolume
        }
        return volumePreset.volumeValue
    }
}
