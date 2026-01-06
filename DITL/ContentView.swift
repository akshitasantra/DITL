import SwiftUI

// MARK: - Root View
enum AppTab {
    case today
    case stats
    case video
}

struct ContentView: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    @State private var selectedTab: AppTab = .today

    // Existing state
    @State private var showingSettings = false
    @State private var showingManualStart = false
    @State private var editingActivity: Activity? = nil
    @State private var addingActivity: Bool = false
    @State private var currentActivity: Activity? = nil
    @State private var timeline: [Activity] = []
    @State private var settingsSourceTab: AppTab? = nil

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {

                // TODAY TAB
                TodayView(
                    currentActivity: $currentActivity,
                    timeline: $timeline,
                    onSettingsTapped: {
                        settingsSourceTab = .today
                        showingSettings = true
                    },
                    onWrappedTapped: { selectedTab = .stats },
                    onQuickStart: startActivity,
                    onManualStartTapped: { showingManualStart = true },
                    onEditTimelineEntry: { editingActivity = $0 },
                    onAddTimelineEntry: { addingActivity = true },
                    reloadToday: reloadToday
                )
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }
                .tag(AppTab.today)

                // STATS TAB
                SQLDashboardView (
                    onSettingsTapped: {
                        settingsSourceTab = .stats
                        showingSettings = true
                    }
                )
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .tag(AppTab.stats)

                // VIDEO TAB
                VideoView(
                    onSettingsTapped: {
                        settingsSourceTab = .video
                        showingSettings = true
                    }
                )
                    .tabItem {
                        Label("Video", systemImage: "video.fill")
                    }
                    .tag(AppTab.video)
            }

            // SETTINGS OVERLAY
            if showingSettings {
                SettingsView {
                    showingSettings = false
                    if let source = settingsSourceTab {
                        selectedTab = source
                    }
                }
                .zIndex(1)
            }
        }
        .preferredColorScheme(appTheme == .dark ? .dark : .light)
        .onAppear {
            TabBarStyler.apply(theme: appTheme)
            reloadToday()
        }
        .onChange(of: appTheme) { newTheme in
            TabBarStyler.apply(theme: newTheme)
        }
        .sheet(isPresented: $showingManualStart) {
            ManualStartSheet { title in
                startActivity(title: title)
                showingManualStart = false
            }
        }
        .sheet(item: $editingActivity) { activity in
            EditActivitySheet(activity: activity) { newTitle, newStart, newEnd in
                let duration = Int(newEnd.timeIntervalSince(newStart) / 60)

                DatabaseManager.shared.updateActivity(
                    id: activity.id,
                    newTitle: newTitle,
                    newEnd: newEnd,
                    newDuration: duration
                )

                reloadToday()
            }
        }
        .sheet(isPresented: $addingActivity) {
            let dummy = Activity(
                id: -1,
                title: "",
                startTime: Date(),
                endTime: Date(),
                durationMinutes: 0
            )
            EditActivitySheet(activity: dummy) { title, start, end in
                let duration = Int(end.timeIntervalSince(start) / 60)
                DatabaseManager.shared.createActivity(
                    title: title,
                    start: start,
                    end: end,
                    duration: duration
                )
                reloadToday()
            }
        }
        
    }

    // MARK: - DB
    private func reloadToday() {
        timeline = DatabaseManager.shared.fetchTodayActivities()
    }

    // MARK: - Activity
    private func startActivity(title: String) {
        guard currentActivity == nil else { return }

        currentActivity = Activity(
            id: -1,
            title: title,
            startTime: Date(),
            endTime: nil,
            durationMinutes: nil
        )
    }
}



// MARK: Today View
struct TodayView: View {
    @Binding var currentActivity: Activity?
    @Binding var timeline: [Activity]

    @AppStorage("appTheme") private var appTheme: AppTheme = .light

    let onSettingsTapped: () -> Void
    let onWrappedTapped: () -> Void
    let onQuickStart: (String) -> Void
    let onManualStartTapped: () -> Void
    let onEditTimelineEntry: (Activity) -> Void
    let onAddTimelineEntry: () -> Void
    let reloadToday: () -> Void
    
    let defaultQuickStarts = ["Homework", "Scroll", "Code", "Eat"]

    var body: some View {
        ZStack {
            AppColors.background(for: appTheme)
                .ignoresSafeArea()

            ScrollView{
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        
                        // Settings Button on the right
                        Button(action: onSettingsTapped) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(Color.black)
                                .padding(10)
                                .background(AppColors.lavenderQuick(for: appTheme))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, AppLayout.screenPadding)
                    
                    // Header
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Image("star")
                                .resizable()
                                .rotationEffect(.degrees(45))
                                .frame(width: 24, height: 24)
                            
                            Text("Today")
                                .font(AppFonts.vt323(42))
                                .foregroundColor(AppColors.pinkPrimary(for: appTheme))
                            
                            Image("star")
                                .resizable()
                                .rotationEffect(.degrees(45))
                                .frame(width: 24, height: 24)
                        }
                        
                        Text(formattedDate())
                            .font(AppFonts.rounded(16))
                            .foregroundColor(AppColors.pinkPrimary(for: appTheme))
                    }
                    
                    // Current Activity
                    Group {
                        if let activity = currentActivity {
                            CurrentActivityCard(
                                activity: activity,
                                onEnd: endCurrentActivity
                            )
                        } else {
                            NoActivityCard(
                                onStartTapped: onManualStartTapped
                            )
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, AppLayout.screenPadding)
                    
                    // Quick Start
                    QuickStartRow(
                        activities: resolvedQuickStarts(),
                        disabled: currentActivity != nil,
                        onStart: onQuickStart
                    )
                    .padding(.top, 16)
                    
                    // Timeline
                    VStack(spacing: 12) {
                        Text("Today’s Timeline")
                            .font(AppFonts.vt323(40))
                            .foregroundColor(AppColors.black(for: appTheme))
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                        
                        let displayTimeline: [Activity] = {
                            if let current = currentActivity {
                                return timeline + [current]
                            }
                            else {
                                return timeline
                            }
                        }()
                        
                        if displayTimeline.isEmpty {
                            EmptyTimelineView()
                                .padding(.horizontal, AppLayout.screenPadding)
                        } else {
                            TimelineSection(
                                timeline: timeline,
                                currentActivity: currentActivity,
                                onDelete: { activity in
                                    DatabaseManager.shared.deleteActivity(id: activity.id)
                                    reloadToday()
                                },
                                onEdit: { activity in
                                    onEditTimelineEntry(activity)
                                }
                            )
                        }
                    }
                    .padding(.top, 24)
                    
                    Spacer()
                    
                    Button {
                        onAddTimelineEntry()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.black)
                            .padding(8)
                            .background(AppColors.lavenderQuick(for: appTheme))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    private func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "MM-dd · EEEE · h:mm a"
        return f.string(from: Date())
    }
    
    func endCurrentActivity() {
        guard let activity = currentActivity else { return }

        let end = Date()
        let duration = Int(end.timeIntervalSince(activity.startTime) / 60)

        DatabaseManager.shared.createActivity(
                title: activity.title,
                start: activity.startTime,
                end: end,
                duration: duration
            )

        currentActivity = nil

        // Reload timeline from DB
        timeline = DatabaseManager.shared.fetchTodayActivities()
    }

    func resolvedQuickStarts() -> [String] {
        let top = DatabaseManager.shared.topQuickStartActivities()
        
        if top.count == 4 {
            return top
        }
        
        // Fill missing slots with defaults
        let remaining = defaultQuickStarts.filter { !top.contains($0) }
        return top + remaining.prefix(4 - top.count)
    }

}


// MARK: Settings View
struct SettingsView: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    
    var onBack: () -> Void

    var body: some View {
        ZStack {
            AppColors.background(for: appTheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.black)
                            .padding(10)
                            .background(AppColors.lavenderQuick(for: appTheme))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.horizontal, AppLayout.screenPadding)

                VStack(spacing: 32) {
                    HStack(spacing: 8) {
                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)

                        Text("Settings")
                            .font(AppFonts.vt323(42))
                            .foregroundColor(AppColors.pinkPrimary(for: appTheme))

                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)
                    }

                    PreferencesCard()
                    AboutSection()
                }
                .padding(.top, 43)
                .padding(.horizontal, AppLayout.screenPadding)

                Spacer()
            }
        }
    }
}
// MARK: SQLDashboard
struct SQLDashboardView: View {
    @State private var totalToday: Int = 0
    @State private var mostTimeConsuming: [(Activity, Int)] = []

    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    
    let onSettingsTapped: () -> Void

    var body: some View {
        ZStack {
            AppColors.background(for: appTheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    
                    Button {
                        onSettingsTapped()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.black)
                            .padding(10)
                            .background(AppColors.lavenderQuick(for: appTheme))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, AppLayout.screenPadding)

                // Header (matches Today / Settings)
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)

                        Text("DITL Wrapped")
                            .font(AppFonts.vt323(42))
                            .foregroundColor(AppColors.pinkPrimary(for: appTheme))

                        Image("star")
                            .resizable()
                            .rotationEffect(.degrees(45))
                            .frame(width: 24, height: 24)
                    }

                    Text("Your day, summarized")
                        .font(AppFonts.rounded(16))
                        .foregroundColor(AppColors.pinkPrimary(for: appTheme))
                }
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 24) {

                        // Total Time Card
                        WrappedTotalTimeCard(totalMinutes: totalToday)

                        // Most Time-Consuming Activities
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Most Time-Consuming Activities")
                                .font(AppFonts.vt323(28))
                                .foregroundColor(AppColors.black(for: appTheme))

                            ForEach(mostTimeConsuming, id: \.0.id) { activity, minutes in
                                WrappedActivityRow(
                                    activity: activity,
                                    minutes: minutes
                                )
                            }
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, AppLayout.screenPadding)
                }

                Spacer()
            }
        }
        .onAppear {
            loadSQLData()
        }
    }

    private func loadSQLData() {
        totalToday = DatabaseManager.shared.totalTimeToday()
        mostTimeConsuming = Array(
            DatabaseManager.shared
                .mostTimeConsumingActivities()
                .prefix(5)
        )
    }
}

// MARK: Video View
struct VideoView: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .light
    
    let onSettingsTapped: () -> Void

    var body: some View {
        ZStack {
            AppColors.background(for: appTheme)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()

                    Button {
                        onSettingsTapped()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.black)
                            .padding(10)
                            .background(AppColors.lavenderQuick(for: appTheme))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, AppLayout.screenPadding)

                Text("Video Diary")
                    .font(AppFonts.vt323(42))
                    .foregroundColor(AppColors.pinkPrimary(for: appTheme))

                Text("Coming soon 🎥")
                    .font(AppFonts.rounded(18))
                    .foregroundColor(AppColors.black(for: appTheme))

                Image(systemName: "video.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(AppColors.lavenderQuick(for: appTheme))
            }
        }
    }
}
