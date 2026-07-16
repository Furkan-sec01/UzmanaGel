import SwiftUI

struct ScheduleView: View {
    @StateObject private var viewModel = ScheduleViewModel()
    @State private var selectedDate = Date()
    @State private var showingDayDetail = false
    @State private var showingBatchSettings = false
    @State private var showingRecurringSettings = false
    
    // Calendar layout properties
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let calendar = Calendar.current
    private let weekdays = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.spacingL) {
                        
                        // 1. Legend Bar
                        legendRow
                            .padding(.horizontal)
                            .padding(.top, Constants.paddingS)
                        
                        // 2. Custom Grid Calendar
                        calendarGridCard
                            .padding(.horizontal)
                        
                        // 3. Setup Panels
                        VStack(spacing: Constants.spacingM) {
                            Button {
                                showingBatchSettings = true
                            } label: {
                                HStack {
                                    Image(systemName: "calendar.badge.plus")
                                    Text("Toplu Müsaitlik Düzenle")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .glassmorphic(cornerRadius: Constants.radiusM)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                            
                            Button {
                                showingRecurringSettings = true
                            } label: {
                                HStack {
                                    Image(systemName: "timer")
                                    Text("Çalışma Gün ve Saatleri")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .glassmorphic(cornerRadius: Constants.radiusM)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                }
                
                if let success = viewModel.successMessage {
                    toastOverlay(message: success)
                }
            }
            .navigationTitle("Çalışma Takvimi")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadAvailability()
            }
            .sheet(isPresented: $showingDayDetail) {
                dayDetailSheet
            }
            .sheet(isPresented: $showingBatchSettings) {
                batchSettingsSheet
            }
            .sheet(isPresented: $showingRecurringSettings) {
                recurringSettingsSheet
            }
        }
    }
    
    // MARK: - Subviews
    
    private var legendRow: some View {
        HStack(spacing: 12) {
            legendItem(color: Color.themeSuccess, title: "Müsait")
            legendItem(color: Color.themeWarning, title: "Kısmi Dolu")
            legendItem(color: Color.themeError, title: "Dolu / Kapalı")
            legendItem(color: Color.themeBorder, title: "Planlanmamış")
        }
        .font(.caption2)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .foregroundColor(Color.themeSecondaryText)
        }
    }
    
    private var calendarGridCard: some View {
        CardView {
            VStack(spacing: Constants.spacingM) {
                // Header (Current month name)
                Text(currentMonthName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.themeText)
                
                // Weekday headers
                HStack {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.themeSecondaryText)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Grid Days
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(0..<daysInMonthRange.count, id: \.self) { index in
                        if let date = daysInMonthRange[index] {
                            Button {
                                selectedDate = date
                                showingDayDetail = true
                            } label: {
                                VStack {
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.footnote)
                                        .fontWeight(.semibold)
                                        .foregroundColor(calendar.isDateInToday(date) ? .white : Color.themeText)
                                }
                                .frame(width: 34, height: 34)
                                .background(
                                    Group {
                                        if calendar.isDateInToday(date) {
                                            Color.themePrimary
                                        } else {
                                            viewModel.getDayColor(for: date).opacity(0.2)
                                        }
                                    }
                                )
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(viewModel.getDayColor(for: date), lineWidth: calendar.isDateInToday(date) ? 0 : 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Text("")
                                .frame(width: 34, height: 34)
                        }
                    }
                }
            }
        }
    }
    
    private var dayDetailSheet: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                VStack(spacing: Constants.spacingL) {
                    Text(dateHeaderString(for: selectedDate))
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    if let slot = viewModel.availabilitySlots.first(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) {
                        let dayReservations = viewModel.reservations(for: selectedDate)
                        CardView {
                            Toggle("Bugün Hizmete Açık", isOn: Binding(
                                get: { slot.isAvailable },
                                set: { _ in
                                    Task {
                                        await viewModel.toggleDayAvailability(slotId: slot.id)
                                    }
                                }
                            ))
                            .tint(Color.themeSuccess)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        }
                        .padding(.horizontal)
                        
                        // Time slots list
                        VStack(alignment: .leading, spacing: Constants.spacingS) {
                            Text("Saat Dilimleri")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.themeSecondaryText)
                                .padding(.horizontal)
                            
                            ScrollView {
                                VStack(spacing: 10) {
                                    ForEach(slot.timeSlots, id: \.timeString) { tSlot in
                                        HStack {
                                            Text(tSlot.timeString)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                            Spacer()
                                            
                                            Button {
                                                viewModel.toggleSlotBooking(slotId: slot.id, timeString: tSlot.timeString)
                                            } label: {
                                                Text(tSlot.isBooked ? "Dolu (Randevu Alındı)" : "Müsait")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(tSlot.isBooked ? Color.themeError : Color.themeSuccess)
                                                    .clipShape(Capsule())
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                        .padding()
                                        .background(Color.themeCardBackground)
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.themeBorder, lineWidth: 1))
                                    }
                                }
                                .padding(.horizontal)
                            }
                            if !dayReservations.isEmpty {
                                VStack(alignment: .leading, spacing: Constants.spacingS) {
                                    Text("Günün Rezervasyonları")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.themeSecondaryText)
                                        .padding(.horizontal)

                                    VStack(spacing: 10) {
                                        ForEach(dayReservations) { reservation in
                                            HStack(alignment: .top, spacing: 12) {
                                                Image(systemName: "calendar.badge.clock")
                                                    .foregroundColor(viewModel.statusColor(for: reservation.status))
                                                    .frame(width: 28, height: 28)

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(reservation.serviceTitle)
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(Color.themeText)

                                                    Text(reservation.customerName)
                                                        .font(.caption)
                                                        .foregroundColor(Color.themeSecondaryText)

                                                    Text(dateTimeString(for: reservation.reservationDate))
                                                        .font(.caption2)
                                                        .foregroundColor(Color.themeSecondaryText)
                                                }

                                                Spacer()

                                                Text(reservation.status.title)
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 5)
                                                    .background(viewModel.statusColor(for: reservation.status))
                                                    .clipShape(Capsule())
                                            }
                                            .padding()
                                            .background(Color.themeCardBackground)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.themeBorder, lineWidth: 1)
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            };if !dayReservations.isEmpty {
                                VStack(alignment: .leading, spacing: Constants.spacingS) {
                                    Text("Günün Rezervasyonları")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.themeSecondaryText)
                                        .padding(.horizontal)

                                    VStack(spacing: 10) {
                                        ForEach(dayReservations) { reservation in
                                            HStack(alignment: .top, spacing: 12) {
                                                Image(systemName: "calendar.badge.clock")
                                                    .foregroundColor(viewModel.statusColor(for: reservation.status))
                                                    .frame(width: 28, height: 28)

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(reservation.serviceTitle)
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(Color.themeText)

                                                    Text(reservation.customerName)
                                                        .font(.caption)
                                                        .foregroundColor(Color.themeSecondaryText)

                                                    Text(dateTimeString(for: reservation.reservationDate))
                                                        .font(.caption2)
                                                        .foregroundColor(Color.themeSecondaryText)
                                                }

                                                Spacer()

                                                Text(reservation.status.title)
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 5)
                                                    .background(viewModel.statusColor(for: reservation.status))
                                                    .clipShape(Capsule())
                                            }
                                            .padding()
                                            .background(Color.themeCardBackground)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.themeBorder, lineWidth: 1)
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    } else {
                        EmptyStateView(iconName: "calendar.badge.clock", title: "Müsaitlik Girilmemiş", message: "Bu gün için çalışma planı bulunmamaktadır.")
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Gün Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        showingDayDetail = false
                    }
                }
            }
        }
    }
    
    private var batchSettingsSheet: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                VStack(spacing: Constants.spacingL) {
                    CardView {
                        VStack(spacing: Constants.spacingM) {
                            DatePicker("Başlangıç Tarihi", selection: $viewModel.batchStartDate, displayedComponents: .date)
                            Divider()
                            DatePicker("Bitiş Tarihi", selection: $viewModel.batchEndDate, displayedComponents: .date)
                            Divider()
                            Toggle("Hizmete Açık (Müsait)", isOn: $viewModel.batchIsAvailable)
                                .tint(Color.themeSuccess)
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    
                    Button {
                        Task {
                            await viewModel.applyBatchAvailability()
                            showingBatchSettings = false
                        }
                    } label: {
                        Text("Müsaitliği Uygula")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.themePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Toplu Düzenleme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        showingBatchSettings = false
                    }
                }
            }
        }
    }
    
    private var recurringSettingsSheet: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.spacingL) {
                        CardView {
                            VStack(alignment: .leading, spacing: Constants.spacingM) {
                                Text("Standart Çalışma Saatleri")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                HStack {
                                    TextField("09:00", text: $viewModel.recurringStartHour)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                    Text("ile")
                                    TextField("18:00", text: $viewModel.recurringEndHour)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                    Text("arası")
                                    Spacer()
                                }
                                .font(.footnote)
                            }
                        }
                        .padding(.horizontal)
                        
                        CardView {
                            VStack(alignment: .leading, spacing: Constants.spacingM) {
                                Text("Çalışılan Günler")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                ForEach(1...7, id: \.self) { day in
                                    Toggle(dayOfWeekName(for: day), isOn: Binding(
                                        get: { viewModel.recurringWorkingDays.contains(day) },
                                        set: { active in
                                            if active {
                                                viewModel.recurringWorkingDays.insert(day)
                                            } else {
                                                viewModel.recurringWorkingDays.remove(day)
                                            }
                                        }
                                    ))
                                    .tint(Color.themePrimary)
                                    .font(.footnote)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Button {
                            viewModel.saveRecurringSettings()
                            showingRecurringSettings = false
                        } label: {
                            Text("Varsayılan Ayarları Kaydet")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.themePrimary)
                                .clipShape(RoundedRectangle(cornerRadius: Constants.radiusM))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Çalışma Ayarları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        showingRecurringSettings = false
                    }
                }
            }
        }
    }
    
    // MARK: - Date Helpers
    
    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    private var daysInMonthRange: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: Date()) else { return [] }
        let components = calendar.dateComponents([.year, .month], from: Date())
        
        var days: [Date?] = []
        
        // Find starting weekday offset
        var firstDayComponents = components
        firstDayComponents.day = 1
        if let firstDay = calendar.date(from: firstDayComponents) {
            let weekday = calendar.component(.weekday, from: firstDay)
            // Shift weekday offset (Sun=1, Mon=2, so Mon should be 0 shift)
            let offset = (weekday + 5) % 7
            for _ in 0..<offset {
                days.append(nil)
            }
        }
        
        for day in range {
            var dayComponents = components
            dayComponents.day = day
            if let date = calendar.date(from: dayComponents) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func dateTimeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd MMM yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    private func dayOfWeekName(for day: Int) -> String {
        let names = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]
        return names[day - 1]
    }
    
    private func dateHeaderString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd MMMM yyyy, EEEE"
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    private func toastOverlay(message: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text(message)
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .padding()
            .background(Color.themeSuccess)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(radius: 5)
            .padding(.bottom, Constants.paddingXL)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    viewModel.successMessage = nil
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: viewModel.successMessage)
    }
}

#Preview {
    ScheduleView()
}
