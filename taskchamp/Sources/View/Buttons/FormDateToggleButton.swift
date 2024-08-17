import SwiftUI

public struct FormDateToggleButton: View {
    var isOnlyTime: Bool
    @Binding var date: Date
    @Binding var isSet: Bool
    @State private var isDateShowing: Bool = false

    public var body: some View {
        Button(
            action: {
                if isSet {
                    withAnimation {
                        isDateShowing.toggle()
                    }
                }
            },
            label: {
                Toggle(isOn: $isSet) {
                    Label {
                        HStack {
                            Text(isOnlyTime ? "Time" : "Date")
                                .foregroundStyle(.primary)
                            if isSet {
                                Text(" • ")
                                    .foregroundStyle(.tertiary)
                                Text(date, style: isOnlyTime ? .time : .date)
                                    .foregroundStyle(.tint)
                                    .font(.footnote)
                            }
                        }
                    } icon: {
                        Image(systemName: isOnlyTime ? SFSymbols.clockFill.rawValue : SFSymbols.calendar.rawValue)
                            .foregroundStyle(.tint)
                    }
                }.onChange(of: isSet) { _, newValue in
                    withAnimation {
                        isDateShowing = newValue
                    }
                }
            }
        )
        .foregroundStyle(.primary)
        if isSet && isDateShowing {
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
