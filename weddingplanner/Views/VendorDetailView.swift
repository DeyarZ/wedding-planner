import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Vendor Detail View
struct ProductionVendorDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vendor: Vendor

    @State private var showingEditView = false
    @State private var showingAddPayment = false
    @State private var showingAddCommunication = false
    @State private var showingDocumentPicker = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedDocument: VendorDocument? = nil
    @State private var animateIn = false

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(hex: "FDFBF7"),
                        Color(hex: "FAF6F2")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Vendor header card
                        vendorHeaderCard
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(.easeOut(duration: 0.6), value: animateIn)

                        // Contact actions
                        contactActionsRow
                            .padding(.horizontal, 24)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.1), value: animateIn)

                        // Payment tracking
                        paymentSection
                            .padding(.horizontal, 24)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)

                        // Contract & Documents
                        documentsSection
                            .padding(.horizontal, 24)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.3), value: animateIn)

                        // Notes & Special Instructions
                        notesSection
                            .padding(.horizontal, 24)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)

                        // Communication history
                        communicationSection
                            .padding(.horizontal, 24)
                            .opacity(animateIn ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.5), value: animateIn)

                        // Delete button
                        deleteButton
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    dismiss()
                }
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "B89B91")),
                trailing: Button("Edit") {
                    showingEditView = true
                    impactFeedback.impactOccurred()
                }
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "B89B91"))
            )
        }
        .sheet(isPresented: $showingEditView) {
            ProductionEditVendorView(vendor: vendor)
        }
        .sheet(isPresented: $showingAddPayment) {
            ProductionAddPaymentView(vendor: vendor)
        }
        .sheet(isPresented: $showingAddCommunication) {
            ProductionAddCommunicationView(vendor: vendor)
        }
        .sheet(isPresented: $showingDocumentPicker) {
            ProductionDocumentPicker { url in
                addDocument(from: url)
            }
        }
        .sheet(item: $selectedDocument) { document in
            ProductionDocumentViewer(document: document)
        }
        .confirmationDialog("Delete Vendor", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteVendor()
            }
        } message: {
            Text("Are you sure you want to delete \(vendor.name)? This action cannot be undone.")
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
            impactFeedback.prepare()
            notificationFeedback.prepare()
        }
    }

    // MARK: - Components

    private var vendorHeaderCard: some View {
        VStack(spacing: 16) {
            // Icon and status
            HStack {
                Image(systemName: vendor.category.icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color(hex: "D4B5A9"))
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(Color(hex: "D4B5A9").opacity(0.1))
                    )

                Spacer()

                ProductionStatusBadge(status: vendor.status)
            }

            // Name and category
            VStack(alignment: .leading, spacing: 8) {
                Text(vendor.name)
                    .font(.system(size: 24, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(vendor.category.rawValue)
                    .font(.system(size: 14, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))

                if let contactName = vendor.contactName {
                    HStack(spacing: 4) {
                        Image(systemName: "person")
                            .font(.system(size: 12, weight: .light))
                        Text(contactName)
                            .font(.system(size: 13, weight: .regular))
                    }
                    .foregroundColor(Color(hex: "7A7A7A"))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 2)
        )
    }

    private var contactActionsRow: some View {
        HStack(spacing: 12) {
            if let phone = vendor.phone {
                VendorContactActionButton(
                    icon: "phone.fill",
                    label: "Call",
                    color: Color(hex: "66BB6A")
                ) {
                    if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            if let email = vendor.email {
                VendorContactActionButton(
                    icon: "envelope.fill",
                    label: "Email",
                    color: Color(hex: "42A5F5")
                ) {
                    if let url = URL(string: "mailto:\(email)") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            if let phone = vendor.phone {
                VendorContactActionButton(
                    icon: "message.fill",
                    label: "Message",
                    color: Color(hex: "B89B91")
                ) {
                    if let url = URL(string: "sms://\(phone.replacingOccurrences(of: " ", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                }
            }

            if let website = vendor.website {
                VendorContactActionButton(
                    icon: "globe",
                    label: "Website",
                    color: Color(hex: "FFA726")
                ) {
                    if let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Payment Status")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Spacer()

                Button(action: {
                    showingAddPayment = true
                    impactFeedback.impactOccurred()
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "D4B5A9"))
                }
            }

            // Payment overview card
            VStack(spacing: 12) {
                // Contract amount
                HStack {
                    Text("Total Contract")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "7A7A7A"))
                    Spacer()
                    Text(String(format: "$%.2f", vendor.contractAmount))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "2C2C2C"))
                }

                // Amount paid
                HStack {
                    Text("Amount Paid")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "7A7A7A"))
                    Spacer()
                    Text(String(format: "$%.2f", vendor.totalPaid))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "66BB6A"))
                }

                // Remaining balance
                HStack {
                    Text("Remaining")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "7A7A7A"))
                    Spacer()
                    Text(String(format: "$%.2f", vendor.remainingBalance))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(vendor.remainingBalance > 0 ? Color(hex: "EF5350") : Color(hex: "66BB6A"))
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "E0E0E0"))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: vendor.paymentStatus.color))
                            .frame(width: geometry.size.width * vendor.paymentProgress, height: 8)
                    }
                }
                .frame(height: 8)
                .padding(.top, 8)

                // Payment status badge
                HStack {
                    Spacer()
                    Text(vendor.paymentStatus.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: vendor.paymentStatus.color))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
            )

            // Payment history
            if let payments = vendor.payments, !payments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Payment History")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "7A7A7A"))

                    ForEach(payments.sorted { $0.date > $1.date }, id: \.self) { payment in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatDate(payment.date))
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(hex: "2C2C2C"))

                                if let method = payment.paymentMethod {
                                    Text(method)
                                        .font(.system(size: 11, weight: .thin))
                                        .foregroundColor(Color(hex: "9B9B9B"))
                                }
                            }

                            Spacer()

                            Text(String(format: "$%.2f", payment.amount))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "66BB6A"))
                        }
                        .padding(.vertical, 6)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Documents")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Spacer()

                Button(action: {
                    showingDocumentPicker = true
                    impactFeedback.impactOccurred()
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "D4B5A9"))
                }
            }

            if let documents = vendor.documents, !documents.isEmpty {
                VStack(spacing: 8) {
                    ForEach(documents.sorted { $0.uploadDate > $1.uploadDate }, id: \.id) { document in
                        VendorDocumentRow(document: document) {
                            selectedDocument = document
                        }
                    }
                }
            } else {
                Text("No documents uploaded yet")
                    .font(.system(size: 13, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "F8F8F8"))
                    )
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes & Special Instructions")
                .font(.system(size: 18, weight: .light, design: .serif))
                .foregroundColor(Color(hex: "2C2C2C"))

            if let notes = vendor.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "5A5A5A"))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "F8F8F8"))
                    )
            }

            if let instructions = vendor.specialInstructions, !instructions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "FFA726"))

                        Text("Special Instructions")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "FFA726"))
                    }

                    Text(instructions)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "5A5A5A"))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "FFF3E0"))
                )
            }

            if vendor.notes == nil && vendor.specialInstructions == nil {
                Text("No notes or special instructions")
                    .font(.system(size: 13, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "F8F8F8"))
                    )
            }
        }
    }

    private var communicationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Communication History")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Spacer()

                Button(action: {
                    showingAddCommunication = true
                    impactFeedback.impactOccurred()
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "D4B5A9"))
                }
            }

            if let communications = vendor.communications, !communications.isEmpty {
                VStack(spacing: 12) {
                    ForEach(communications.sorted { $0.date > $1.date }.prefix(5), id: \.self) { communication in
                        VendorCommunicationRow(communication: communication)
                    }
                }
            } else {
                Text("No communications logged")
                    .font(.system(size: 13, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "F8F8F8"))
                    )
            }
        }
    }

    private var deleteButton: some View {
        Button(action: {
            showingDeleteConfirmation = true
            impactFeedback.impactOccurred()
        }) {
            Text("Delete Vendor")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "EF5350"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "EF5350"), lineWidth: 1)
                )
        }
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func addDocument(from url: URL) {
        guard let data = try? Data(contentsOf: url) else { return }

        let document = VendorDocument(
            fileName: url.lastPathComponent,
            fileData: data,
            documentType: .other
        )
        document.vendor = vendor

        modelContext.insert(document)

        do {
            try modelContext.save()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error saving document: \(error)")
        }
    }

    private func deleteVendor() {
        modelContext.delete(vendor)

        do {
            try modelContext.save()
            dismiss()
            notificationFeedback.notificationOccurred(.success)
        } catch {
            print("Error deleting vendor: \(error)")
        }
    }
}

// MARK: - Supporting Components

struct VendorContactActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color)
                    )

                Text(label)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(hex: "7A7A7A"))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct VendorDocumentRow: View {
    let document: VendorDocument
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "doc.fill")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(hex: "B89B91"))

                VStack(alignment: .leading, spacing: 2) {
                    Text(document.fileName)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "2C2C2C"))
                        .lineLimit(1)

                    Text(document.documentType.rawValue)
                        .font(.system(size: 11, weight: .thin))
                        .foregroundColor(Color(hex: "9B9B9B"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: "C4C4C4"))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 3, y: 1)
            )
        }
    }
}

struct VendorCommunicationRow: View {
    let communication: VendorCommunication

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: getIcon(for: communication.type))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "B89B91"))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(communication.subject)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: "2C2C2C"))

                HStack {
                    Text(communication.type.rawValue)
                        .font(.system(size: 11, weight: .thin))
                        .foregroundColor(Color(hex: "9B9B9B"))

                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "C4C4C4"))

                    Text(formatDate(communication.date))
                        .font(.system(size: 11, weight: .thin))
                        .foregroundColor(Color(hex: "9B9B9B"))
                }

                if let notes = communication.notes {
                    Text(notes)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "7A7A7A"))
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "F8F8F8"))
        )
    }

    private func getIcon(for type: CommunicationType) -> String {
        switch type {
        case .email: return "envelope"
        case .phone: return "phone"
        case .meeting: return "person.2"
        case .text: return "message"
        case .whatsapp: return "message.circle"
        case .videoCall: return "video"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}