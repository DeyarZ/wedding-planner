import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @Binding var showPermissionScreen: Bool

    @State private var animateIn = false

    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [
                    Color(hex: "FDF8F3"),
                    Color(hex: "FAF2E9")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Icon with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "E8C4B8").opacity(0.3), Color(hex: "D4B5A9").opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateIn ? 1 : 0.8)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(Color(hex: "D4B5A9"))
                        .scaleEffect(animateIn ? 1 : 0)
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateIn)

                // Title and description
                VStack(spacing: 16) {
                    Text("Stay on Track")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundColor(Color(hex: "2C2C2C"))

                    Text("Get gentle reminders for tasks, vendor appointments, and special milestones on your wedding journey")
                        .font(.system(size: 16, weight: .thin))
                        .foregroundColor(Color(hex: "7A7A7A"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 20)
                .animation(.easeOut(duration: 0.8).delay(0.2), value: animateIn)

                // Benefits list
                VStack(alignment: .leading, spacing: 20) {
                    NotificationBenefit(
                        icon: "sunrise.fill",
                        title: "Morning Check-ins",
                        description: "Start each day with motivation"
                    )

                    NotificationBenefit(
                        icon: "calendar.badge.clock",
                        title: "Task Reminders",
                        description: "Never miss an important deadline"
                    )

                    NotificationBenefit(
                        icon: "sparkles",
                        title: "Milestone Celebrations",
                        description: "Celebrate every step of your journey"
                    )
                }
                .padding(.horizontal, 40)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.4), value: animateIn)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        notificationManager.requestPermission()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                showPermissionScreen = false
                            }
                        }
                    }) {
                        Text("Enable Notifications")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "D4B5A9"), Color(hex: "B89B91")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                    }

                    Button(action: {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showPermissionScreen = false
                        }
                    }) {
                        Text("Maybe Later")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(hex: "9B9B9B"))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.6), value: animateIn)
            }
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }
}

struct NotificationBenefit: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(Color(hex: "D4B5A9"))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Text(description)
                    .font(.system(size: 12, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
            }

            Spacer()
        }
    }
}