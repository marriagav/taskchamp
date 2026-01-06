import SwiftUI
import taskchampShared

public struct LocationReminderButton: View {
    @Binding var locationReminder: TCLocationReminder?
    let action: () -> Void

    public init(locationReminder: Binding<TCLocationReminder?>, action: @escaping () -> Void) {
        _locationReminder = locationReminder
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: locationReminder != nil ? "location.fill" : "location")
                    .foregroundColor(locationReminder != nil ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    if let reminder = locationReminder {
                        Text(reminder.locationName)
                            .foregroundColor(.primary)
                        HStack(spacing: 4) {
                            Text(triggerDescription(for: reminder))
                            Text("\(Int(reminder.radius))m radius")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    } else {
                        Text("Add Location")
                            .foregroundColor(.primary)
                        Text("Get reminded at a specific place")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if locationReminder != nil {
                    Button {
                        withAnimation {
                            locationReminder = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func triggerDescription(for reminder: TCLocationReminder) -> String {
        if reminder.triggerOnArrival && reminder.triggerOnDeparture {
            return "Arrive & Leave"
        } else if reminder.triggerOnArrival {
            return "Arrive"
        } else if reminder.triggerOnDeparture {
            return "Leave"
        }
        return ""
    }
}
