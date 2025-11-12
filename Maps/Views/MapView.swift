import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var locationManager: LocationManager
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    // MARK: - Bottom Sheet Properties
    @State private var showBottomSheet = true
    @State private var sheetDetent: PresentationDetent = .height(80)
    @State private var sheetHeight: CGFloat = 0
    @State private var animationDuration: CGFloat = 0
    @State private var toolbarOpacity: CGFloat = 1
    @State private var safeAreaBottomInset: CGFloat = 0
    
    // MARK: - Constants
    private enum SheetDetents {
        static let collapsed: CGFloat = 80
        static let medium: CGFloat = 350
    }
    
    var body: some View {
        Map(position: $cameraPosition) {
            if let location = locationManager.userLocation {
                Annotation("Tu sei qui", coordinate: location) {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.3))
                            .frame(width: 32, height: 32)
                        Circle()
                            .fill(.blue)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            )
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .sheet(isPresented: $showBottomSheet) {
            BottomSheetView(
                locationManager: locationManager,
                sheetDetent: $sheetDetent,
                onCenterMap: centerOnUser
            )
            .presentationDetents(
                [.height(SheetDetents.collapsed), .height(SheetDetents.medium), .large],
                selection: $sheetDetent
            )
            .presentationBackgroundInteraction(.enabled(upThrough: .height(SheetDetents.medium)))
            .presentationCornerRadius(20)
            .presentationBackground(.ultraThinMaterial)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGFloat.self) {
                max(min($0.size.height, 400 + safeAreaBottomInset), 0)
            } action: { oldValue, newValue in
                updateSheetMetrics(oldHeight: oldValue, newHeight: newValue)
            }
            .ignoresSafeArea()
            .interactiveDismissDisabled()
        }
        .overlay(alignment: .bottomTrailing) {
            bottomFloatingToolbar
        }
        .onGeometryChange(for: CGFloat.self) {
            $0.safeAreaInsets.bottom
        } action: { newValue in
            safeAreaBottomInset = newValue
        }
        .onChange(of: locationManager.locationUpdateTrigger) { _, _ in
            guard let location = locationManager.userLocation else { return }
            
            if cameraPosition == .automatic {
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    )
                }
            }
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private var bottomFloatingToolbar: some View {
        VStack(spacing: 15) {
            // Bottone navigazione
            Button {
                // TODO: Implementare navigazione
            } label: {
                Image(systemName: "car.fill")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
            .frame(width: 48, height: 48)
            .background(.ultraThinMaterial, in: Circle())
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            
            // Bottone centra sulla posizione
            Button {
                centerOnUser()
            } label: {
                Image(systemName: locationManager.userLocation != nil ? "location.fill" : "location")
                    .font(.title3)
                    .foregroundStyle(locationManager.userLocation != nil ? .blue : .primary)
            }
            .frame(width: 48, height: 48)
            .background(.ultraThinMaterial, in: Circle())
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 10)
        .opacity(toolbarOpacity)
        .offset(y: -sheetHeight)
        .animation(
            .interpolatingSpring(duration: animationDuration, bounce: 0),
            value: sheetHeight
        )
    }
    
    // MARK: - Helper Methods
    private func updateSheetMetrics(oldHeight: CGFloat, newHeight: CGFloat) {
        sheetHeight = min(newHeight, SheetDetents.medium + safeAreaBottomInset)
        
        // Calcolo opacità toolbar
        let progress = max(
            min((newHeight - (SheetDetents.medium + safeAreaBottomInset)) / 50, 1),
            0
        )
        toolbarOpacity = 1 - progress
        
        // Calcolo durata animazione
        let diff = abs(newHeight - oldHeight)
        animationDuration = max(min(diff / 100, 0.3), 0)
    }
    
    private func centerOnUser() {
        guard let location = locationManager.userLocation else {
            locationManager.requestLocation()
            return
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        }
    }
}

// MARK: - Bottom Sheet View
struct BottomSheetView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var sheetDetent: PresentationDetent
    let onCenterMap: () -> Void
    
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 20) {
                ForEach(locationManager.savedPlaces){ place in
                    PlaceRow(place: place)
                }
                if !isFocused {
                    quickActionsSection
                }
            }
            .padding(.top, 90)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            searchHeader
        }
        .animation(
            .interpolatingSpring(duration: 0.3, bounce: 0),
            value: isFocused
        )
        .onChange(of: isFocused) { _, newValue in
            withAnimation {
                sheetDetent = newValue ? .large : .height(350)
            }
        }
    }
    
    // MARK: - Search Header
    @ViewBuilder
    private var searchHeader: some View {
        HStack(spacing: 10) {
            // Search Field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Cerca luoghi", text: $searchText)
                    .focused($isFocused)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.quaternary, in: Capsule())
            
            // Profile/Close Button
            Button {
                if isFocused {
                    isFocused = false
                } else {
                    // TODO: Azione profilo
                }
            } label: {
                ZStack {
                    if isFocused {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .frame(width: 48, height: 48)
                            .background(.ultraThinMaterial, in: Circle())
                            .transition(.blurReplace)
                    } else {
                        Text("AB")
                            .font(.title3.bold())
                            .frame(width: 48, height: 48)
                            .foregroundStyle(.white)
                            .background(.blue, in: Circle())
                            .transition(.blurReplace)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 80)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Quick Actions
    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Azioni Rapide")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionCard(
                        icon: "location.fill",
                        title: "La mia posizione",
                        color: .blue
                    ) {
                        onCenterMap()
                    }
                    
                    QuickActionCard(
                        icon: "house.fill",
                        title: "Casa",
                        color: .green
                    ) {
                        // TODO: Navigazione casa
                    }
                    
                    QuickActionCard(
                        icon: "briefcase.fill",
                        title: "Lavoro",
                        color: .orange
                    ) {
                        // TODO: Navigazione lavoro
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(width: 100, height: 80)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Place Row Component
struct PlaceRow: View {
    let place: Place
    
    var body: some View {
        HStack(spacing: 12) {
            // Icona categoria
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: place.category.rawValue)
                    .foregroundStyle(categoryColor)
                    .font(.title3)
            }
            
            // Info luogo
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.headline)
                
                if let address = place.address {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Indicatore
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var categoryColor: Color {
        switch place.category {
        case .home: return .green
        case .work: return .orange
        case .favorite: return .yellow
        case .restaurant: return .red
        case .shopping: return .blue
        case .gym: return .purple
        case .other: return .gray
        }
    }
}

#Preview {
    MapView(locationManager: LocationManager())
}
