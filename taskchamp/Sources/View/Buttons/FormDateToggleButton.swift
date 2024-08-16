import SwiftUI

public struct FormDateToggleButton: View {
    var isOnlyTime: Bool
    @Binding var date: Date
    @State private var isDateSet: Bool = false
    @State private var isDateShowing: Bool = false

    public var body: some View {
        Button(
            action: {
                if isDateSet {
                    withAnimation {
                        isDateShowing.toggle()
                    }
                }
            },
            label: {
                Toggle(isOn: $isDateSet) {
                    Label {
                        HStack {
                            Text(isOnlyTime ? "Time" : "Date")
                                .foregroundStyle(.primary)
                            if isDateSet {
                                Text(" • ")
                                    .foregroundStyle(.tertiary)
                                Text(date, style: isOnlyTime ? .time : .date)
                                    .foregroundStyle(.tint)
                                    .font(.footnote)
                            }
                        }
                    } icon: {
                        Image(systemName: isOnlyTime ? "clock.fill" : "calendar")
                            .foregroundStyle(.tint)
                    }
                }.onChange(of: isDateSet) { _, newValue in
                    withAnimation {
                        isDateShowing = newValue
                    }
                }
            }
        )
        .foregroundStyle(.primary)
        if isDateSet && isDateShowing {
            DatePicker(
                isOnlyTime ? "Time" : "Date",
                selection: $date,
                displayedComponents: [isOnlyTime ? .hourAndMinute : .date]
            )
            .if(isOnlyTime) { view in
                view.datePickerStyle(.wheel)
            }
            .if(!isOnlyTime) { view in
                view.datePickerStyle(.graphical)
            }
        }
    }
}
