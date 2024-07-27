import SwiftUI
import MapKit

struct CircleImage: View {
    var lycée: Lycée
    @State private var flyoverImage: UIImage?
    
    func getFlyoverSnapshot() async throws -> UIImage {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: lycée.coordonnéesLieu, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        options.mapType = .hybridFlyover
        
        let camera = MKMapCamera()
        camera.centerCoordinate = lycée.coordonnéesLieu
        camera.pitch = 55.0
        camera.centerCoordinateDistance = 400
        options.camera = camera
        
        let snapshotter = MKMapSnapshotter(options: options)
        return try await withCheckedThrowingContinuation { continuation in
            snapshotter.start { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    continuation.resume(returning: snapshot.image)
                } else {
                    continuation.resume(throwing: NSError(domain: "MKMapSnapshotter", code: -1, userInfo: nil))
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            if let image = flyoverImage {
                Image(uiImage: image)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(.white, lineWidth: 4)
                    }
                    .shadow(radius: 7)
            }
        }
        .onAppear {
            Task {
                do {
                    let image = try await getFlyoverSnapshot()
                    await MainActor.run {
                        flyoverImage = image
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
}
