import SwiftUI
import SpeedManagerModule

extension Double {
    /// Returns the double value fixed to one decimal place.
    func fixedToOneDecimal() -> String {
        return String(format: "%.1f", self)
    }
    
    func fixedToZeroDecimal() -> String {
        return String(format: "%.0f", self)
    }
}

struct ContentView: View {
    @StateObject var speedManager = SpeedManager(speedUnit: .kilometersPerHour)
    @State var progress: CGFloat = 0.0
    
    // Helper function to convert authorization status to string
    private func authorizationStatusString(_ status: SpeedManagerAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Determined"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            switch speedManager.authorizationStatus {
            case .authorized:
                Text("Speed Manager Demo")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Your current speed is:")
                    .monospaced()
                    .font(.headline)
                
                Text("\(speedManager.speed.fixedToOneDecimal()) km/h")
                    .monospaced()
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                // Simple progress bar instead of gauge
                VStack {
                    Text("Speed Progress")
                        .font(.caption)
                    
                    ProgressView(value: min(speedManager.speed / 200.0, 1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 200)
                    
                    Text("Max: 200 km/h")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // Additional speed information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Speed Details:")
                        .font(.headline)
                    
                    HStack {
                        Text("Authorization Status:")
                        Spacer()
                        Text(authorizationStatusString(speedManager.authorizationStatus))
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Speed Unit:")
                        Spacer()
                        Text("km/h")
                    }
                    
                    if speedManager.speed > 0 {
                        HStack {
                            Text("Speed in m/s:")
                            Spacer()
                            Text("\((speedManager.speed / 3.6).fixedToOneDecimal()) m/s")
                        }
                    }
                    
                    // Replace the mock heading calculation with a real value if available from SpeedManager (e.g., speedManager.headingDegrees)
                    HStack {
                        Text("Heading:")
                        Spacer()
                        let mockHeading = speedManager.speed.truncatingRemainder(dividingBy: 360).rounded()
                        Text("\(mockHeading.fixedToZeroDecimal())°")
                            .monospaced()
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
            default:
                VStack {
                    Image(systemName: "location.slash")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Location Access Required")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Please allow location access to use the speed manager")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    ProgressView()
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
