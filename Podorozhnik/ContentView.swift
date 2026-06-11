import SwiftUI
import WidgetKit
 
struct TripRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let amount: Double
    let type: RecordType
 
    enum RecordType: String, Codable {
        case trip = "Поездка"
        case topup = "Пополнение"
        case edit = "Изменение"
    }
}
 
struct ContentView: View {
    @State private var balance: Double = {
        guard let data = try? Data(contentsOf: ContentView.dataURL()),
              let decoded = try? JSONDecoder().decode(ContentView.AppData.self, from: data)
        else { return 0.0 }
        // сразу дублируем в UserDefaults для виджета
        UserDefaults(suiteName: "group.podorozhnik")?.set(decoded.balance, forKey: "balance")
        return decoded.balance
    }()
    
    @State private var records: [TripRecord] = {
        guard let data = try? Data(contentsOf: ContentView.dataURL()),
              let decoded = try? JSONDecoder().decode(ContentView.AppData.self, from: data)
        else { return [] }
        return decoded.records
    }()
 
    @State private var showTopUp = false
    @State private var showEdit = false
    @State private var showHistory = false
    @State private var showResetAlert = false
    @State private var topUpText = ""
    @State private var editText = ""
 
    let farePrice: Double = 65.0
    
    var remainingTrips: Int {
        Int(balance / farePrice)
    }
 
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.36, blue: 0.22)
                .ignoresSafeArea()
 
            VStack(spacing: 32) {
                HStack {
                    Button(action: {
                        editText = String(format: "%.2f", balance)
                        showEdit = true
                    }) {
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
 
                    Spacer()
 
                    Button(action: { showHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
 
                Spacer()
 
                VStack(spacing: 8) {
                    Image(systemName: "tram.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Подорожник")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
 
                VStack(spacing: 4) {
                    Text("Баланс")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    Text(String(format: "%.2f ₽", balance))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("≈ \(remainingTrips) поездок")
                        .font(.system(size: 35, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button(action: {
                        topUpText = ""
                        showTopUp = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("Пополнить")
                                .fontWeight(.semibold)
                                .font(.system(size: 18))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .foregroundColor(Color(red: 0.07, green: 0.36, blue: 0.22))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }
 
                    Button(action: {
                        if balance >= farePrice {
                            balance -= farePrice
                            addRecord(amount: -farePrice, type: .trip)
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                            Text("Оплатить проезд  −\(Int(farePrice)) ₽")
                                .fontWeight(.semibold)
                                .font(.system(size: 18))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(balance >= farePrice ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                        .foregroundColor(balance >= farePrice ? .white : .white.opacity(0.3))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(balance < farePrice)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
 
        .sheet(isPresented: $showTopUp) {
            VStack(spacing: 20) {
                Text("Пополнение")
                    .font(.headline)
                    .padding(.top, 20)
                TextField("Сумма", text: $topUpText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                Button(action: {
                    if let value = Double(topUpText.replacingOccurrences(of: ",", with: ".")) {
                        balance += value
                        addRecord(amount: value, type: .topup)
                    }
                    showTopUp = false
                }) {
                    Text("Пополнить")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.07, green: 0.36, blue: 0.22))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                Spacer()
            }
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
        }
 
        .sheet(isPresented: $showEdit) {
            VStack(spacing: 20) {
                Text("Изменить баланс")
                    .font(.headline)
                    .padding(.top, 20)
                TextField("Баланс", text: $editText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                Button(action: {
                    if let value = Double(editText.replacingOccurrences(of: ",", with: ".")) {
                        let diff = value - balance
                        balance = value
                        addRecord(amount: diff, type: .edit)
                    }
                    showEdit = false
                }) {
                    Text("Сохранить")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.07, green: 0.36, blue: 0.22))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                Spacer()
            }
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
        }
 
        .sheet(isPresented: $showHistory) {
            NavigationView {
                Group {
                    if records.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "clock")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("История пуста")
                                .foregroundColor(.gray)
                        }
                    } else {
                        List {
                            ForEach(records.reversed()) { record in
                                HStack {
                                    Image(systemName: iconFor(record.type))
                                        .foregroundColor(colorFor(record.type))
                                        .frame(width: 32)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(record.type.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(formatDate(record.date))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Text(String(format: "%+.2f ₽", record.amount))
                                        .fontWeight(.semibold)
                                        .foregroundColor(record.amount < 0 ? .red : .green)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .navigationTitle("История")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Закрыть") { showHistory = false }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showResetAlert = true }) {
                            Label("Сбросить", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                .alert("Сбросить всё?", isPresented: $showResetAlert) {
                    Button("Сбросить", role: .destructive) {
                        balance = 0.0
                        records = []
                        save()
                    }
                    Button("Отмена", role: .cancel) {}
                } message: {
                    Text("Баланс и история будут удалены безвозвратно")
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
 
    // MARK: — Storage
 
    static func dataURL() -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("podorozhnik.json")
    }
 
    struct AppData: Codable {
        var balance: Double
        var records: [TripRecord]
    }
 
    func save() {
        let data = AppData(balance: balance, records: records)
        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: Self.dataURL(), options: .atomic)
        }
        // дублируем баланс в UserDefaults для виджета
        UserDefaults(suiteName: "group.podorozhnik")?.set(balance, forKey: "balance")
        WidgetCenter.shared.reloadAllTimelines()
    }
 
    func addRecord(amount: Double, type: TripRecord.RecordType) {
        records.append(TripRecord(id: UUID(), date: Date(), amount: amount, type: type))
        save()
    }
 
    func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM, HH:mm"
        f.locale = Locale(identifier: "ru_RU")
        return f.string(from: date)
    }
 
    func iconFor(_ type: TripRecord.RecordType) -> String {
        switch type {
        case .trip: return "tram.fill"
        case .topup: return "plus.circle.fill"
        case .edit: return "pencil.circle.fill"
        }
    }
 
    func colorFor(_ type: TripRecord.RecordType) -> Color {
        switch type {
        case .trip: return .red
        case .topup: return .green
        case .edit: return .blue
        }
    }
}
