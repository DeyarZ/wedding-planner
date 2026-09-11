import SwiftUI

/// The one place a couple can change what they told us during onboarding.
///
/// Until 1.7 the couple names, date, venue, guest count and total budget were
/// written exactly once, by the onboarding flow, and never again — a bride who
/// mistyped her budget had to delete the app (and every guest, vendor and
/// payment with it) to fix a number. The currency choice lives here too, for
/// the couple whose device region does not match the wedding.
///
/// Edits are staged in local state and written on Save only, so Cancel never
/// leaves a half-typed name in the SwiftData store.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: DataManager

    @State private var coupleNames = ""
    @State private var weddingDate = Date()
    @State private var venue = ""
    @State private var guestCount = 0
    @State private var totalBudget: Double = 0
    /// Empty follows the device region; otherwise an ISO 4217 code.
    @State private var currencyChoice = ""
    @State private var showCurrencyList = false
    /// `onAppear` fires again every time the currency list pops back, so the
    /// stored values must only be loaded once or they wipe unsaved edits.
    @State private var hasLoaded = false

    private var trimmedNames: String {
        coupleNames.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSaveDisabled: Bool {
        trimmedNames.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Couple names") {
                        TextField("Couple names", text: $coupleNames)
                            .textInputAutocapitalization(.words)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("settings.coupleNames")
                    }

                    DatePicker("Wedding date", selection: $weddingDate, displayedComponents: .date)

                    LabeledContent("Venue") {
                        TextField("Optional", text: $venue)
                            .textInputAutocapitalization(.words)
                            .multilineTextAlignment(.trailing)
                    }

                    LabeledContent("Guest count") {
                        TextField("0", value: $guestCount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("settings.guestCount")
                    }
                } header: {
                    Text("Your wedding")
                }

                Section {
                    LabeledContent("Total Budget") {
                        HStack(spacing: 4) {
                            // Follows the pending choice, not the saved one.
                            Text(BudgetCurrency.symbol(for: currencyChoice.isEmpty ? BudgetCurrency.automaticCode : currencyChoice))
                                .foregroundStyle(.secondary)
                            TextField("0", value: $totalBudget, format: .number.precision(.fractionLength(0...2)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .accessibilityIdentifier("settings.totalBudget")
                        }
                    }

                    // Not a `.navigationLink` Picker: inside a sheet its
                    // selection pops via the environment `dismiss`, which
                    // tears down the whole sheet instead of the pushed list.
                    Button {
                        showCurrencyList = true
                    } label: {
                        LabeledContent("Currency") {
                            HStack(spacing: 6) {
                                Text(CurrencyListView.label(for: currencyChoice))
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("settings.currency")
                } header: {
                    Text("Budget")
                } footer: {
                    Text("Amounts are never converted. Changing the currency only changes the symbol and number format. Category estimates stay as they are when you change the total.")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showCurrencyList) {
                CurrencyListView(selection: $currencyChoice, isPresented: $showCurrencyList)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(isSaveDisabled)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !hasLoaded, let wedding = dataManager.wedding else { return }
        hasLoaded = true
        coupleNames = wedding.coupleNames
        weddingDate = wedding.date
        venue = wedding.venue ?? ""
        guestCount = wedding.guestCount
        totalBudget = wedding.totalBudget
        currencyChoice = BudgetCurrency.override ?? ""
    }

    private func save() {
        // The currency is a device preference, not wedding data, so it is
        // written even when the wedding row is somehow missing.
        BudgetCurrency.override = currencyChoice.isEmpty ? nil : currencyChoice

        if let wedding = dataManager.wedding {
            let trimmedVenue = venue.trimmingCharacters(in: .whitespacesAndNewlines)

            wedding.coupleNames = trimmedNames
            wedding.date = weddingDate
            wedding.venue = trimmedVenue.isEmpty ? nil : trimmedVenue
            wedding.guestCount = max(0, guestCount)
            wedding.totalBudget = max(0, totalBudget)
            wedding.updatedAt = Date()

            // Saves and re-syncs the T-60 win-back, which hangs off the date.
            dataManager.updateWedding()
        }

        // Screens format amounts inline with `formatBudget()`; nothing they
        // observe changes when only the currency did, so nudge them.
        dataManager.objectWillChange.send()
        dismiss()
    }
}

/// The pushed currency list. Pops itself through `isPresented` rather than
/// `dismiss`, see the note in `SettingsView`.
struct CurrencyListView: View {
    @Binding var selection: String
    @Binding var isPresented: Bool

    static func label(for code: String) -> String {
        if code.isEmpty {
            return String(localized: "Automatic (\(BudgetCurrency.automaticCode))")
        }
        return "\(BudgetCurrency.localizedName(for: code)) (\(code))"
    }

    var body: some View {
        List {
            row("")
            ForEach(BudgetCurrency.selectableCodes, id: \.self) { code in
                row(code)
            }
        }
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ code: String) -> some View {
        Button {
            selection = code
            isPresented = false
        } label: {
            HStack {
                Text(Self.label(for: code))
                Spacer()
                if code == selection {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
            }
        }
        .foregroundStyle(.primary)
        .accessibilityAddTraits(code == selection ? .isSelected : [])
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager())
}
