import SwiftUI

struct TaskDetailSheet: View {
    let task: WeddingTask
    let dataManager: DataManager
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isCompleted: Bool = false
    @State private var notes: String = ""
    @State private var dueDate: Date = Date()
    @State private var showDatePicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Task header
                    VStack(spacing: 16) {
                        Image(systemName: task.category.icon)
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(Color(hex: "D4B5A9"))

                        Text(task.title)
                            .font(.system(size: 24, weight: .light, design: .serif))
                            .foregroundColor(Color(hex: "2C2C2C"))
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Label(task.category.rawValue, systemImage: task.category.icon)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color(hex: "7A7A7A"))

                            if task.priority == .urgent {
                                Label("Urgent", systemImage: "exclamationmark.circle.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "F4B5A0"))
                            }
                        }
                    }
                    .padding(.top, 20)

                    // Complete button
                    Button(action: {
                        completeTask()
                    }) {
                        HStack {
                            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))

                            Text(isCompleted ? "Completed" : "Mark as Complete")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(isCompleted ? Color(hex: "66BB6A") : Color(hex: "D4B5A9"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isCompleted ? Color(hex: "66BB6A") : Color(hex: "D4B5A9"), lineWidth: 1.5)
                        )
                    }

                    // Due date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Due Date")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "7A7A7A"))

                        Button(action: {
                            showDatePicker.toggle()
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16))

                                Text(formatDate(dueDate))
                                    .font(.system(size: 15))

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .rotationEffect(.degrees(showDatePicker ? 180 : 0))
                            }
                            .foregroundColor(Color(hex: "2C2C2C"))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "F8F8F8"))
                            )
                        }

                        if showDatePicker {
                            DatePicker("", selection: $dueDate, displayedComponents: [.date])
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .padding(.top, 8)
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "7A7A7A"))

                        TextEditor(text: $notes)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "2C2C2C"))
                            .padding(8)
                            .frame(minHeight: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "F8F8F8"))
                            )
                    }

                    // Save button
                    Button(action: {
                        saveChanges()
                    }) {
                        Text("Save Changes")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "D4B5A9"), Color(hex: "B89B91")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                        onDismiss()
                    }
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(hex: "D4B5A9"))
                }
            }
        }
        .onAppear {
            isCompleted = task.isCompleted
            notes = task.notes ?? ""
            dueDate = task.dueDate ?? Date()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func completeTask() {
        isCompleted.toggle()
        task.isCompleted = isCompleted
        task.completedDate = isCompleted ? Date() : nil
        task.updatedAt = Date()
        dataManager.updateWedding()

        if isCompleted {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func saveChanges() {
        task.notes = notes
        task.dueDate = dueDate
        task.updatedAt = Date()
        dataManager.updateWedding()

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
        onDismiss()
    }
}