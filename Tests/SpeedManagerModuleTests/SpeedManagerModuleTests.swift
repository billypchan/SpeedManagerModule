import XCTest
import Combine
@testable import SpeedManagerModule

final class SpeedManagerModuleTests: XCTestCase {

    var manager: SpeedManager?
    private var cancellables: Set<AnyCancellable> = []

    func test_speed() throws {
        let mockDelegate = SpeedManagerDelegateMock(testCase: self)
        manager = SpeedManager(speedUnit: .kilometersPerHour, trigger: self)
        manager?.delegate = mockDelegate

        mockDelegate.expectSpeed()
        manager?.startUpdatingSpeed()

        waitForExpectations(timeout: 1)

        let result = try XCTUnwrap(mockDelegate.speed)
        XCTAssertEqual(result, 12.2)
    }

    func test_speedAccuracy() throws {
        let mockDelegate = SpeedManagerDelegateMock(testCase: self)
        manager = SpeedManager(speedUnit: .kilometersPerHour, trigger: self)
        manager?.delegate = mockDelegate

        mockDelegate.expectSpeed()
        manager?.startUpdatingSpeed()

        waitForExpectations(timeout: 1)

        XCTAssertEqual(mockDelegate.speedAccuracy, 1)
    }

    func test_degrees() throws {
        // Given
        let mockDelegate = SpeedManagerDelegateMock(testCase: self)
        manager = SpeedManager(speedUnit: .kilometersPerHour, trigger: self)
        // Attach a subscription to observe published degrees
        mockDelegate.attach(to: manager!, storeIn: &cancellables)

        mockDelegate.expectDegrees()

        // When: set the published degrees (no delegate/trigger path exists for heading)
        manager?.degrees = 123.4

        // Then
        waitForExpectations(timeout: 1)
        XCTAssertEqual(mockDelegate.degrees, 123.4)
    }
}

extension SpeedManagerModuleTests: SpeedManagerTrigger {
    func startMonitoringSpeed() {
        guard let manager = manager else { return }
        self.manager?.delegate?.speedManager(manager,
                                             didUpdateSpeed: 12.2,
                                             speedAccuracy: 1)
    }
    
    func startUpdatingSpeed() {
        self.startMonitoringSpeed()
    }
}

class SpeedManagerDelegateMock: SpeedManagerDelegate {

    var speed: Double?
    var speedAccuracy: Double?
    var degrees: Double?

    private var expectation: XCTestExpectation?
    private var degreesExpectation: XCTestExpectation?
    private let testCase: XCTestCase
    
    var didUpdateSpeed: Bool = false
    var didFailWithError: Bool = false
    var didUpdateAuthorizationStatus: Bool = false
    var speedManagerDidFailWithLocationServicesUnavailable: Bool = false
    
    func speedManager(_ manager: SpeedManagerModule.SpeedManager, didUpdateSpeed speed: Double, speedAccuracy: Double) {
        didUpdateSpeed = true
        
        if expectation != nil {
            self.speed = speed
            self.speedAccuracy = speedAccuracy
        }
        expectation?.fulfill()
        expectation = nil
    }
    
    func speedManager(_ manager: SpeedManagerModule.SpeedManager, didFailWithError error: Error) {
        didFailWithError = true
    }
    
    func speedManager(_ speedManager: SpeedManagerModule.SpeedManager, didUpdateAuthorizationStatus status: SpeedManagerModule.SpeedManagerAuthorizationStatus) {
        didUpdateAuthorizationStatus = true
    }
    
    func speedManagerDidFailWithLocationServicesUnavailable(_ speedManager: SpeedManagerModule.SpeedManager) {
        speedManagerDidFailWithLocationServicesUnavailable = true
    }
    
    init(testCase: XCTestCase) {
        self.testCase = testCase
    }

    func expectSpeed() {
        expectation = testCase.expectation(description: "Expect speed")
    }

    func expectDegrees() {
        degreesExpectation = testCase.expectation(description: "Expect degrees")
    }

    // Subscribe to the manager's published degrees to capture updates for tests.
    func attach(to manager: SpeedManager, storeIn cancellables: inout Set<AnyCancellable>) {
        manager.$degrees
            .sink { [weak self] value in
                guard let self else { return }
                self.degrees = value
                if self.degreesExpectation != nil {
                    self.degreesExpectation?.fulfill()
                    self.degreesExpectation = nil
                }
            }
            .store(in: &cancellables)
    }
}
