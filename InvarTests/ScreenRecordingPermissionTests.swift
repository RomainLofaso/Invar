//
//  ScreenRecordingPermissionTests.swift
//  InvarTests
//

import XCTest
@testable import InvarCore

@MainActor
final class ScreenRecordingPermissionTests: XCTestCase {
    private static var retained: [AnyObject] = []

    private func retainForTestLifetime(_ object: AnyObject) {
        ScreenRecordingPermissionTests.retained.append(object)
    }

    func testRefresh_setsMissingPermission_whenPreflightFalse() {
        let authorizer = MockScreenRecordingAuthorizer(preflightResult: false, requestResult: false)
        let store = ScreenRecordingPermissionStore(authorizer: authorizer)
        retainForTestLifetime(authorizer)
        retainForTestLifetime(store)
        store.refresh()

        XCTAssertEqual(store.state, .missingPermission)
        XCTAssertEqual(authorizer.preflightCallCount, 1)
        XCTAssertEqual(authorizer.requestCallCount, 0)
    }

    func testRefresh_setsGranted_whenPreflightTrue() {
        let authorizer = MockScreenRecordingAuthorizer(preflightResult: true, requestResult: false)
        let store = ScreenRecordingPermissionStore(authorizer: authorizer)
        retainForTestLifetime(authorizer)
        retainForTestLifetime(store)
        store.refresh()

        XCTAssertEqual(store.state, .granted)
        XCTAssertEqual(authorizer.preflightCallCount, 1)
        XCTAssertEqual(authorizer.requestCallCount, 0)
    }

    func testRequest_setsRequesting_thenRefreshesState() async {
        let authorizer = MockScreenRecordingAuthorizer(preflightResult: false, requestResult: true)
        authorizer.requestDelayNanoseconds = 200_000_000
        let store = ScreenRecordingPermissionStore(authorizer: authorizer)
        retainForTestLifetime(authorizer)
        retainForTestLifetime(store)

        let requestTask = Task {
            await store.requestAccess()
        }

        await Task.yield()
        XCTAssertEqual(store.state, .requesting)
        XCTAssertEqual(authorizer.requestCallCount, 1)

        authorizer.preflightResult = true
        _ = await requestTask.value

        XCTAssertEqual(store.state, .granted)
        XCTAssertEqual(authorizer.preflightCallCount, 1)
    }

    func testRequest_isIdempotent_whenAlreadyRequesting_doesNotCallSystemTwice() async {
        let authorizer = MockScreenRecordingAuthorizer(preflightResult: false, requestResult: false)
        authorizer.requestDelayNanoseconds = 200_000_000
        let store = ScreenRecordingPermissionStore(authorizer: authorizer)
        retainForTestLifetime(authorizer)
        retainForTestLifetime(store)

        let firstRequest = Task {
            await store.requestAccess()
        }
        await Task.yield()
        let secondRequest = Task {
            await store.requestAccess()
        }

        await Task.yield()
        XCTAssertEqual(store.state, .requesting)
        XCTAssertEqual(authorizer.requestCallCount, 1)

        _ = await firstRequest.value
        _ = await secondRequest.value

        XCTAssertEqual(authorizer.requestCallCount, 1)
    }

    func testRefresh_doesNotTriggerRequest() {
        let authorizer = MockScreenRecordingAuthorizer(preflightResult: false, requestResult: true)
        let store = ScreenRecordingPermissionStore(authorizer: authorizer)
        retainForTestLifetime(authorizer)
        retainForTestLifetime(store)
        store.refresh()
        store.refresh()

        XCTAssertEqual(authorizer.preflightCallCount, 2)
        XCTAssertEqual(authorizer.requestCallCount, 0)
    }

    func testRefresh_updatesState_whenPreflightChangesBetweenCalls() {
        let authorizer = MockScreenRecordingAuthorizer(preflightResult: false, requestResult: false)
        let store = ScreenRecordingPermissionStore(authorizer: authorizer)
        retainForTestLifetime(authorizer)
        retainForTestLifetime(store)
        store.refresh()
        XCTAssertEqual(store.state, .missingPermission)

        authorizer.preflightResult = true
        store.refresh()
        XCTAssertEqual(store.state, .granted)
        XCTAssertEqual(authorizer.preflightCallCount, 2)
    }

    func testStartOverlay_aborts_whenPermissionMissing() {
        let authorizer = MockScreenRecordingAuthorizer(preflightResult: false, requestResult: false)
        let store = ScreenRecordingPermissionStore(authorizer: authorizer)
        retainForTestLifetime(authorizer)
        retainForTestLifetime(store)
        let gate = CaptureGate(permissionStore: store)
        var started = false
        var missing = false
        gate.attemptStart(
            onGranted: { started = true },
            onMissing: { missing = true }
        )

        XCTAssertFalse(started)
        XCTAssertTrue(missing)
    }

    func testStartOverlay_succeeds_whenPermissionGranted() {
        let authorizer = MockScreenRecordingAuthorizer(preflightResult: true, requestResult: false)
        let store = ScreenRecordingPermissionStore(authorizer: authorizer)
        retainForTestLifetime(authorizer)
        retainForTestLifetime(store)
        let gate = CaptureGate(permissionStore: store)
        var started = false
        var missing = false
        gate.attemptStart(
            onGranted: { started = true },
            onMissing: { missing = true }
        )

        XCTAssertTrue(started)
        XCTAssertFalse(missing)
    }
}

final class MockScreenRecordingAuthorizer: ScreenRecordingAuthorizing, @unchecked Sendable {
    var preflightResult: Bool
    var requestResult: Bool
    var preflightCallCount = 0
    var requestCallCount = 0
    var requestDelayNanoseconds: UInt64?

    init(preflightResult: Bool, requestResult: Bool) {
        self.preflightResult = preflightResult
        self.requestResult = requestResult
    }

    func preflight() -> Bool {
        preflightCallCount += 1
        return preflightResult
    }

    func requestAccess() async -> Bool {
        requestCallCount += 1
        if let requestDelayNanoseconds {
            try? await Task.sleep(nanoseconds: requestDelayNanoseconds)
        }
        return requestResult
    }
}
