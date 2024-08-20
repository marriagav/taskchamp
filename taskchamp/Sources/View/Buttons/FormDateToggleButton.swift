import SwiftUI

public struct FormDateToggleButton: View {
    var isOnlyTime: Bool
    @Binding var date: Date
    @Binding var isSet: Bool
    @Binding var isDateShowing: Bool

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
                }
            }
        )
        .foregroundStyle(.primary)
        if isSet && isDateShowing {
            HStack {
                Spacer()
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
                .labelsHidden()
                Spacer()
            }
            .listRowInsets(.init(top: 0, leading: 10, bottom: 0, trailing: 10))
        }
    }
}
