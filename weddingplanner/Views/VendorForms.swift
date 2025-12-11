import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Add Vendor View
struct ProductionAddVendorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let onSave: (Vendor) -> Void

    @State private var name = ""
    @State private var category: VendorCategory = .other
    @State private var contactName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var website = ""
    @State private var contractAmount = ""
    @State private var depositAmount = ""
    @State private var notes = ""
    @State private var specialInstructions = ""
    @State private var status: VendorStatus = .pending

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Vendor Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(VendorCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    Picker("Status", selection: $status) {
                        ForEach(VendorStatus.allCases, id: \.self) { stat in
                            Text(stat.rawValue).tag(stat)
                        }
                    }
                }

                Section("Contact Information") {
                    TextField("Contact Person", text: $contactName)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section("Financial") {
                    TextField("Contract Amount", text: $contractAmount)
                        .keyboardType(.decimalPad)
                    TextField("Deposit Amount", text: $depositAmount)
                        .keyboardType(.decimalPad)
                }

                Section("Notes") {
                    TextField("General Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Special Instructions", text: $specialInstructions, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Vendor")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveVendor()
                }
                .disabled(name.isEmpty)
            )
        }
    }

    private func saveVendor() {
        let vendor = Vendor(
            name: name,
            category: category,
            contractAmount: Double(contractAmount) ?? 0
        )

        vendor.contactName = contactName.isEmpty ? nil : contactName
        vendor.phone = phone.isEmpty ? nil : phone
        vendor.email = email.isEmpty ? nil : email
        vendor.website = website.isEmpty ? nil : website
        vendor.depositPaid = Double(depositAmount) ?? 0
        vendor.totalPaid = Double(depositAmount) ?? 0
        vendor.notes = notes.isEmpty ? nil : notes
        vendor.specialInstructions = specialInstructions.isEmpty ? nil : specialInstructions
        vendor.status = status
        vendor.isBooked = status == .booked || status == .confirmed

        onSave(vendor)
        dismiss()
    }
}

// MARK: - Edit Vendor View
struct ProductionEditVendorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let vendor: Vendor

    @State private var name = ""
    @State private var category: VendorCategory = .other
    @State private var contactName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var website = ""
    @State private var contractAmount = ""
    @State private var notes = ""
    @State private var specialInstructions = ""
    @State private var status: VendorStatus = .pending

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Vendor Name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(VendorCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    Picker("Status", selection: $status) {
                        ForEach(VendorStatus.allCases, id: \.self) { stat in
                            Text(stat.rawValue).tag(stat)
                        }
                    }
                }

                Section("Contact Information") {
                    TextField("Contact Person", text: $contactName)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Section("Financial") {
                    TextField("Contract Amount", text: $contractAmount)
                        .keyboardType(.decimalPad)

                    HStack {
                        Text("Total Paid")
                        Spacer()
                        Text(String(format: "$%.2f", vendor.totalPaid))
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Remaining")
                        Spacer()
                        Text(String(format: "$%.2f", vendor.remainingBalance))
                            .foregroundColor(vendor.remainingBalance > 0 ? .red : .green)
                    }
                }

                Section("Notes") {
                    TextField("General Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Special Instructions", text: $specialInstructions, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Edit Vendor")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveChanges()
                }
                .disabled(name.isEmpty)
            )
        }
        .onAppear {
            loadVendorData()
        }
    }

    private func loadVendorData() {
        name = vendor.name
        category = vendor.category
        contactName = vendor.contactName ?? ""
        phone = vendor.phone ?? ""
        email = vendor.email ?? ""
        website = vendor.website ?? ""
        contractAmount = String(format: "%.0f", vendor.contractAmount)
        notes = vendor.notes ?? ""
        specialInstructions = vendor.specialInstructions ?? ""
        status = vendor.status
    }

    private func saveChanges() {
        vendor.name = name
        vendor.category = category
        vendor.contactName = contactName.isEmpty ? nil : contactName
        vendor.phone = phone.isEmpty ? nil : phone
        vendor.email = email.isEmpty ? nil : email
        vendor.website = website.isEmpty ? nil : website
        vendor.contractAmount = Double(contractAmount) ?? 0
        vendor.notes = notes.isEmpty ? nil : notes
        vendor.specialInstructions = specialInstructions.isEmpty ? nil : specialInstructions
        vendor.status = status
        vendor.isBooked = status == .booked || status == .confirmed
        vendor.updatedAt = Date()

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            print("Error saving vendor: \(error)")
        }
    }
}

// MARK: - Add Payment View
struct ProductionAddPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let vendor: Vendor

    @State private var amount = ""
    @State private var date = Date()
    @State private var paymentMethod = "Credit Card"
    @State private var notes = ""

    private let paymentMethods = ["Cash", "Check", "Credit Card", "Bank Transfer", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Details") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(paymentMethods, id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    HStack {
                        Text("Current Balance")
                        Spacer()
                        Text(String(format: "$%.2f", vendor.remainingBalance))
                            .foregroundColor(.gray)
                    }

                    if let amountValue = Double(amount) {
                        HStack {
                            Text("New Balance")
                            Spacer()
                            Text(String(format: "$%.2f", max(0, vendor.remainingBalance - amountValue)))
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Add Payment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    savePayment()
                }
                .disabled(amount.isEmpty)
            )
        }
    }

    private func savePayment() {
        guard let amountValue = Double(amount) else { return }

        let payment = VendorPayment(amount: amountValue, date: date)
        payment.paymentMethod = paymentMethod
        payment.notes = notes.isEmpty ? nil : notes
        payment.vendor = vendor

        vendor.totalPaid += amountValue

        // Sync with BudgetItem if there's a linked one
        if let budgetItems = vendor.wedding?.budgetItems {
            for budgetItem in budgetItems {
                if budgetItem.vendor?.id == vendor.id {
                    budgetItem.amountSpent = vendor.totalPaid
                    budgetItem.isPaid = vendor.totalPaid >= vendor.contractAmount
                    budgetItem.paymentStatus = vendor.totalPaid >= vendor.contractAmount ? .fullyPaid :
                                              vendor.totalPaid > 0 ? .partiallyPaid : .pending
                }
            }
        }

        modelContext.insert(payment)

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            print("Error saving payment: \(error)")
        }
    }
}

// MARK: - Add Communication View
struct ProductionAddCommunicationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let vendor: Vendor

    @State private var type: CommunicationType = .email
    @State private var subject = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var hasFollowUp = false
    @State private var followUpDate = Date().addingTimeInterval(7 * 24 * 3600)

    var body: some View {
        NavigationStack {
            Form {
                Section("Communication Details") {
                    Picker("Type", selection: $type) {
                        ForEach(CommunicationType.allCases, id: \.self) { commType in
                            Text(commType.rawValue).tag(commType)
                        }
                    }

                    TextField("Subject/Topic", text: $subject)

                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Notes") {
                    TextField("Details (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Follow Up") {
                    Toggle("Needs Follow Up", isOn: $hasFollowUp)

                    if hasFollowUp {
                        DatePicker("Follow Up Date", selection: $followUpDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Log Communication")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    saveCommunication()
                }
                .disabled(subject.isEmpty)
            )
        }
    }

    private func saveCommunication() {
        let communication = VendorCommunication(type: type, subject: subject, date: date)
        communication.notes = notes.isEmpty ? nil : notes
        communication.followUpDate = hasFollowUp ? followUpDate : nil
        communication.vendor = vendor

        modelContext.insert(communication)

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            print("Error saving communication: \(error)")
        }
    }
}

// MARK: - Export Options View
struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    let vendors: [Vendor]

    @State private var showingShareSheet = false
    @State private var exportData: Data? = nil

    var body: some View {
        NavigationStack {
            List {
                Section("Export Options") {
                    Button(action: exportAsCSV) {
                        Label("Export as CSV", systemImage: "doc.text")
                    }

                    Button(action: exportAsPDF) {
                        Label("Export as PDF", systemImage: "doc.richtext")
                    }

                    Button(action: shareContacts) {
                        Label("Share Contact List", systemImage: "square.and.arrow.up")
                    }
                }

                Section("Summary") {
                    HStack {
                        Text("Total Vendors")
                        Spacer()
                        Text("\(vendors.count)")
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Total Budget")
                        Spacer()
                        Text(String(format: "$%.2f", vendors.reduce(0) { $0 + $1.contractAmount }))
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Total Paid")
                        Spacer()
                        Text(String(format: "$%.2f", vendors.reduce(0) { $0 + $1.totalPaid }))
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Export Vendors")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = exportData {
                ShareSheet(items: [data])
            }
        }
    }

    private func exportAsCSV() {
        var csv = "Name,Category,Contact,Phone,Email,Status,Contract Amount,Paid,Balance\n"

        for vendor in vendors {
            csv += "\"\(vendor.name)\","
            csv += "\"\(vendor.category.rawValue)\","
            csv += "\"\(vendor.contactName ?? "")\","
            csv += "\"\(vendor.phone ?? "")\","
            csv += "\"\(vendor.email ?? "")\","
            csv += "\"\(vendor.status.rawValue)\","
            csv += "\(vendor.contractAmount),"
            csv += "\(vendor.totalPaid),"
            csv += "\(vendor.remainingBalance)\n"
        }

        exportData = csv.data(using: .utf8)
        showingShareSheet = true
    }

    private func exportAsPDF() {
        // Create PDF (simplified version)
        let pdfMetaData = [
            kCGPDFContextCreator: "Wedding Planner",
            kCGPDFContextTitle: "Vendor List"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { (context) in
            context.beginPage()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20),
                .foregroundColor: UIColor.black
            ]

            "Wedding Vendor List".draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)

            var yPosition: CGFloat = 100

            for vendor in vendors {
                let vendorText = "\(vendor.name) - \(vendor.category.rawValue)"
                vendorText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black
                ])
                yPosition += 20
            }
        }

        exportData = data
        showingShareSheet = true
    }

    private func shareContacts() {
        var text = "Wedding Vendor Contacts\n\n"

        for vendor in vendors {
            text += "\(vendor.name)\n"
            text += "Category: \(vendor.category.rawValue)\n"
            if let contact = vendor.contactName {
                text += "Contact: \(contact)\n"
            }
            if let phone = vendor.phone {
                text += "Phone: \(phone)\n"
            }
            if let email = vendor.email {
                text += "Email: \(email)\n"
            }
            text += "\n"
        }

        exportData = text.data(using: .utf8)
        showingShareSheet = true
    }
}

// MARK: - Document Picker
struct ProductionDocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf, UTType.image, UTType.text])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: ProductionDocumentPicker

        init(_ parent: ProductionDocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onPick(url)
            }
        }
    }
}

// MARK: - Document Viewer
struct ProductionDocumentViewer: View {
    @Environment(\.dismiss) private var dismiss
    let document: VendorDocument

    var body: some View {
        NavigationStack {
            VStack {
                if document.documentType == .contract || document.documentType == .invoice {
                    // Show document preview
                    Text("Document: \(document.fileName)")
                        .font(.title2)
                        .padding()

                    Text("Type: \(document.documentType.rawValue)")
                        .foregroundColor(.gray)

                    Spacer()
                } else {
                    Text("Document Preview")
                    Spacer()
                }
            }
            .navigationTitle(document.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") { dismiss() }
            )
        }
    }
}