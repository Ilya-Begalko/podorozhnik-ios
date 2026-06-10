import WidgetKit
import SwiftUI

struct BalanceEntry: TimelineEntry {
    let date: Date
    let balance: Double
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BalanceEntry {
        BalanceEntry(date: Date(), balance: 250.0)
    }
    func getSnapshot(in context: Context, completion: @escaping (BalanceEntry) -> Void) {
        let balance = UserDefaults(suiteName: "group.podorozhnik")?.double(forKey: "balance") ?? 0
        completion(BalanceEntry(date: Date(), balance: balance))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceEntry>) -> Void) {
        let balance = UserDefaults(suiteName: "group.podorozhnik")?.double(forKey: "balance") ?? 0
        let entry = BalanceEntry(date: Date(), balance: balance)
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct PodorozhnikWidgetEntryView: View {
    var entry: BalanceEntry
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "tram.fill")
                .foregroundColor(.white.opacity(0.7))
            Text(String(format: "%.2f ₽", entry.balance))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Подорожник")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .containerBackground(Color(red: 0.07, green: 0.36, blue: 0.22), for: .widget)
    }
}

struct PodorozhnikWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PodorozhnikWidget", provider: Provider()) { entry in
            PodorozhnikWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Подорожник")
        .description("Остаток баланса карты")
        .supportedFamilies([.systemSmall])
    }
}
