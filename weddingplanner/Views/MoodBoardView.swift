import SwiftUI
import SwiftData
import PhotosUI

struct MoodBoardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var dataManager: DataManager
    @Query(sort: \Photo.createdAt, order: .reverse) private var photos: [Photo]

    @State private var selectedCategory: PhotoCategory? = nil
    @State private var showingImagePicker = false
    @State private var selectedItems = [PhotosPickerItem]()
    @State private var animateIn = false
    @State private var showingPhotoDetail: Photo? = nil

    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 170), spacing: 12)
    ]

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    var filteredPhotos: [Photo] {
        photos.filter { photo in
            selectedCategory == nil || photo.category == selectedCategory
        }
    }

    var body: some View {
        NavigationView {
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

                VStack(spacing: 0) {
                    // Header with categories
                    VStack(spacing: 20) {
                        HStack {
                            Text("Vision Board")
                                .font(.system(size: 32, weight: .light, design: .serif))
                                .foregroundColor(Color(hex: "2C2C2C"))

                            Spacer()

                            if dataManager.canUploadPhoto() {
                                PhotosPicker(
                                    selection: $selectedItems,
                                    maxSelectionCount: 10,
                                    matching: .images
                                ) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(hex: "D4B5A9"))
                                }
                            } else {
                                Button(action: {
                                    dataManager.showPaywallIfNeeded(for: "photo")
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(hex: "D4B5A9").opacity(0.5))
                                }
                            }
                        }

                        // Category filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                PhotoCategoryChip(
                                    category: nil,
                                    label: "All",
                                    isSelected: selectedCategory == nil
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCategory = nil
                                        impactFeedback.impactOccurred()
                                    }
                                }

                                ForEach(PhotoCategory.allCases, id: \.self) { category in
                                    PhotoCategoryChip(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedCategory = selectedCategory == category ? nil : category
                                            impactFeedback.impactOccurred()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        Color.white
                            .shadow(color: Color.black.opacity(0.04), radius: 10, y: 5)
                    )

                    if filteredPhotos.isEmpty {
                        EmptyMoodBoardState {
                            if dataManager.canUploadPhoto() {
                                showingImagePicker = true
                                impactFeedback.impactOccurred()
                            } else {
                                dataManager.showPaywallIfNeeded(for: "photo")
                            }
                        }
                    } else {
                        // Photo grid
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(Array(filteredPhotos.enumerated()), id: \.element.id) { index, photo in
                                    MoodBoardCard(photo: photo) {
                                        showingPhotoDetail = photo
                                        impactFeedback.impactOccurred()
                                    }
                                    .opacity(animateIn ? 1 : 0)
                                    .scaleEffect(animateIn ? 1 : 0.8)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.7)
                                        .delay(Double(index) * 0.03),
                                        value: animateIn
                                    )
                                }
                            }
                            .padding(24)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $showingPhotoDetail) { photo in
                PhotoDetailView(photo: photo)
            }
            .onAppear {
                withAnimation {
                    animateIn = true
                }
                impactFeedback.prepare()
            }
            .onChange(of: selectedItems) { _, _ in
                Task {
                    await loadPhotos()
                }
            }
        }
    }

    private func loadPhotos() async {
        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let photo = Photo(
                    imageData: data,
                    category: selectedCategory ?? .inspiration,
                    title: "Inspiration"
                )
                photo.wedding = dataManager.wedding
                modelContext.insert(photo)
            }
        }

        try? modelContext.save()
        selectedItems = []
    }
}

struct PhotoCategoryChip: View {
    let category: PhotoCategory?
    var label: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.system(size: 12))
                }

                Text(label ?? category?.rawValue ?? "")
                    .font(.system(size: 13, weight: .regular))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "7A7A7A"))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: category?.color ?? "D4B5A9") : Color(hex: "F0F0F0"))
            )
        }
    }
}

struct MoodBoardCard: View {
    let photo: Photo
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                if let imageData = photo.thumbnailData ?? photo.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "F0F0F0"))
                        .frame(height: 140)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "C4C4C4"))
                        )
                }

                if photo.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "FFB5BA"))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 4)
                        )
                        .padding(8)
                }
            }
            .shadow(color: Color.black.opacity(isPressed ? 0.15 : 0.08), radius: isPressed ? 4 : 8, y: isPressed ? 2 : 4)
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct EmptyMoodBoardState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(Color(hex: "D4B5A9"))

            VStack(spacing: 12) {
                Text("Start Your Vision Board")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundColor(Color(hex: "2C2C2C"))

                Text("Save photos that inspire your perfect day")
                    .font(.system(size: 14, weight: .thin))
                    .foregroundColor(Color(hex: "9B9B9B"))
                    .multilineTextAlignment(.center)
            }

            Button(action: onAdd) {
                Text("Add Photos")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "D4B5A9"), Color(hex: "B89B91")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }

            Spacer()
        }
    }
}

struct PhotoDetailView: View {
    let photo: Photo

    @Environment(\.dismiss) private var dismiss
    @State private var notes = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let imageData = photo.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label(photo.category.rawValue, systemImage: photo.category.icon)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: photo.category.color))

                            Spacer()

                            Button(action: {
                                photo.isFavorite.toggle()
                            }) {
                                Image(systemName: photo.isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "FFB5BA"))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "7A7A7A"))

                            TextEditor(text: $notes)
                                .font(.system(size: 14))
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: "F8F8F8"))
                                )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle(photo.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        photo.notes = notes
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            notes = photo.notes ?? ""
        }
    }
}