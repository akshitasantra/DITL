import SwiftUI

struct PreferencesCard: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .light

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                PreferenceButton(
                    title: "Theme",
                    iconName: themeIcon
                ) {
                    toggleTheme()
                }

                PreferenceButton(title: "Notifications", iconName: "notification") {}
                PreferenceButton(title: "Sound", iconName: "high-volume") {}
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(AppColors.pinkCard(for: appTheme))
            .cornerRadius(AppLayout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppColors.black(for: appTheme), lineWidth: 1)
            )
            .shadow(color: AppColors.black(for: appTheme).opacity(0.10), radius: 12, x: 0, y: 4)

            // Decorative icons anchored to card corners
            .overlay(alignment: .topLeading) {
                Image("love")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(12)
            }
            .overlay(alignment: .topTrailing) {
                Image("love-always-wins")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(12)
            }
            .overlay(alignment: .bottomLeading) {
                Image("love-always-wins")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(12)
            }
            .overlay(alignment: .bottomTrailing) {
                Image("love")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding(12)
            }
        }
    }
    
    private var themeIcon: String {
        appTheme == .light ? "cloudy" : "dark-cloudy"
    }
    
    private func toggleTheme() {
            appTheme = (appTheme == .light) ? .dark : .light
        }
}


struct PreferenceButton: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    
    let title: String
    let iconName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(iconName)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.leading, 16) // shift right
                    .frame(width: 40, alignment: .leading) // keep consistent x-position

                Text(title)
                    .font(AppFonts.rounded(18))
                    .foregroundColor(.black)

                Spacer() // push text left, keep button width consistent
            }
            .padding(.vertical, 16)
            .frame(width: 200)
            .background(AppColors.lavenderQuick(for: appTheme))
            .cornerRadius(AppLayout.cornerRadius)
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                .stroke(AppColors.black(for: appTheme), lineWidth: 1)
        )
        .shadow(color: AppColors.black(for: appTheme).opacity(0.1), radius: 12, x: 0, y: 4)
    }
}


