import Foundation

struct DiagnosticThermalPolicy: Sendable {
    var read: @Sendable () -> ProcessInfo.ThermalState = { ProcessInfo.processInfo.thermalState }

    func skipReason() -> String? {
        switch read() {
        case .nominal, .fair:
            return nil
        case .serious:
            return String(localized: "Test skipped because the device thermal state is serious. Let the device cool before running diagnostics again.")
        case .critical:
            return String(localized: "Test skipped because the device thermal state is critical. Let the device cool before running diagnostics again.")
        @unknown default:
            return String(localized: "Test skipped because the device thermal state is unknown.")
        }
    }
}
