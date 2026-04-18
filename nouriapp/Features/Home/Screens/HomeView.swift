import SwiftUI


struct HomeView: View {
    @EnvironmentObject var onboardingData: OnboardingData
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
    @State private var showCalendar = false
    @State private var showForbiddenList = false
    @State private var dayOffset: Int = 0 
    
    private var selectedDate: Date {
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date())
    }
    
    var body: some View {
        ZStack {
            NouriColors.canvas.ignoresSafeArea()
            VStack(spacing: 0) {
                headerView.padding(.horizontal, 20).padding(.vertical, 16)
                
                TabView(selection: $dayOffset) {
                    ForEach(-365...365, id: \.self) { offset in
                        let date = Calendar.current.startOfDay(
                            for: Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                        )
                        MainInputArea(date: date)
                            .id(offset)
                            .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: dayOffset) { _ in haptic(.light) }
                
                HomeBottomBar(onForbidden: { showForbiddenList = true })
                    .padding(.horizontal, 20).padding(.bottom, 16).padding(.top, 8)
            }
        }
        // Flush notes when app moves to background
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                let email = KeychainManager.read(key: KeychainManager.userEmailKey) ?? ""
                let date = selectedDate
                Task { await NouriDailyNotes.shared.flushAll(email: email) }
            }
        }
        .fullScreenCover(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showForbiddenList) {
            ForbiddenListSheet(isPresented: $showForbiddenList).environmentObject(onboardingData).nouriSheet()
        }
        .sheet(isPresented: $showCalendar) {
            CalendarSheet(selectedDate: Binding(
                get: { selectedDate },
                set: { newDate in
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: newDate))
                    dayOffset = components.day ?? 0
                    haptic(.medium)
                }
            )).nouriSheet()
        }
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        .alert("Existing Profile Found", isPresented: $onboardingData.showConflictAlert) {
            Button("Keep Existing", role: .cancel) { onboardingData.resetConflict() }
            Button("Update Profile") {
                Task {
                    await NouriAuth.shared.saveOnboardingData(email: onboardingData.pendingEmail, data: onboardingData.toDictionary())
                    onboardingData.resetConflict()
                }
            }
        } message: { Text("Update profile for \(onboardingData.pendingEmail)?") }
    }
    
    // MARK: - Senior Subviews
    private var headerView: some View {
        ZStack {
            HStack {
                Image.bundled("nouri").resizable().scaledToFit().frame(width: 70, height: 26).offset(y: -2)
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { haptic(.light); showForbiddenList = true }) { Image(systemName: "nosign") }.buttonStyle(.plain)
                    Button(action: { haptic(.light); showSettings = true }) { Image(systemName: "gearshape") }.buttonStyle(.plain)
                }.font(.system(size: 15, weight: .semibold)).foregroundStyle(NouriColors.title).nouriPill()
            }
            
            HStack(spacing: 0) {
                arrowBtn(icon: "chevron.left") { updateDay(by: -1) }
                Button(action: { haptic(.medium); showCalendar = true }) {
                    Text(Calendar.current.isDateInToday(selectedDate) ? "Today" : selectedDate.formatted(.dateTime.month().day()))
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(NouriColors.title).padding(.vertical, 8)
                }.buttonStyle(.plain)
                arrowBtn(icon: "chevron.right") { updateDay(by: 1) }
            }.background(Capsule().fill(NouriColors.iconBgColor))
        }
    }
    
    @ViewBuilder private func arrowBtn(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(.black.opacity(0.4)).padding(.vertical, 8).padding(.horizontal, 14).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
    
    private func updateDay(by amount: Int) {
        haptic(.light)
        withAnimation { dayOffset += amount }
    }
    
    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Components
private struct MainInputArea: View {
    let date: Date

    private var email: String { KeychainManager.read(key: KeychainManager.userEmailKey) ?? "" }

    @StateObject private var vm: DailyNoteViewModel

    init(date: Date) {
        self.date = date
        // StateObject must be initialised with a wrappedValue here so SwiftUI
        // can identity-track it per date tab.
        _vm = StateObject(wrappedValue: DailyNoteViewModel(
            email: KeychainManager.read(key: KeychainManager.userEmailKey) ?? "",
            date: date
        ))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Custom Binding — only triggers onTextChanged on USER edits, not during load().
            // Using onChange is dangerous because vm.load() also sets vm.text, which would
            // start the debounce timer unnecessarily.
            let editBinding = Binding<String>(
                get: { vm.text },
                set: { newValue in
                    vm.text = newValue
                    vm.onTextChanged()
                }
            )

            NouriTextEditor(
                text: editBinding,
                font: .systemFont(ofSize: 18),
                lineSpacing: 2,
                paragraphSpacing: 10,
                foregroundColor: UIColor(NouriColors.title)
            )
            .padding(.horizontal, 16)

            if vm.text.isEmpty {
                Text("What did you eat today?")
                    .font(.system(size: 18))
                    .foregroundStyle(.gray.opacity(0.6))
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                    .allowsHitTesting(false)
            }
        }
        // 300 ms delay before loading — prevents TabView's pre-rendered adjacent pages
        // from firing unnecessary network calls when the user is just swiping past a day.
        .task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await vm.load()
        }
        .onDisappear { Task { await vm.flush() } }
    }
}


private struct HomeBottomBar: View {
    var onForbidden: () -> Void
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                IconHelper(icon: "sparkles", size: 40, fg: NouriColors.sparkleColor, bg: NouriColors.sparkleBgColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAILY SCORE").font(.system(size: 9, weight: .bold)).foregroundStyle(NouriColors.subtitle).tracking(1)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("87").font(.system(size: 24, weight: .bold)).foregroundStyle(NouriColors.title)
                        Text("/ 100").font(.system(size: 12, weight: .medium)).foregroundStyle(NouriColors.subtitle)
                    }
                }
            }
            Spacer()
            HStack(spacing: 10) {
                IconHelper(icon: "mic")
                IconHelper(icon: "camera")
                IconHelper(icon: "barcode.viewfinder")
            }
        }.padding(14).background(RoundedRectangle(cornerRadius: 32).fill(.white).shadow(color: .black.opacity(0.06), radius: 15, y: 10))
    }
}

@ViewBuilder func IconHelper(icon: String, size: CGFloat = 38, fg: Color = NouriColors.title, bg: Color = NouriColors.iconBgColor, action: @escaping () -> Void = {}) -> some View {
    Button(action: { UIImpactFeedbackGenerator(style: .light).impactOccurred(); action() }) {
        Image(systemName: icon).font(.system(size: size * 0.45)).foregroundStyle(fg).frame(width: size, height: size).background(Circle().fill(bg))
    }.buttonStyle(.plain)
}

extension OnboardingData {
    func resetConflict() { self.wasOnboarded = false; self.pendingEmail = "" }
}

extension View {
    func nouriPill() -> some View { self.padding(.horizontal, 16).padding(.vertical, 8).background(Capsule().fill(NouriColors.iconBgColor)) }
    func nouriSheet() -> some View { self.presentationDetents([.medium, .large]).presentationDragIndicator(.hidden).presentationCornerRadius(28) }
}

#Preview { HomeView().environmentObject(OnboardingData()) }
