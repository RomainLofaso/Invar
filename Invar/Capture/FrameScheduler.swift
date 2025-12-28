//
//  FrameScheduler.swift
//  Invar
//

import Foundation

final class FrameScheduler {
    var onTick: (() -> Void)?

    private var timer: DispatchSourceTimer?
    private var fps: Int = 60
    private var slowFrameCount = 0

    func start() {
        stop()
        scheduleTimer()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func recordFrame(duration: TimeInterval) {
        let budget = 1.0 / Double(fps)
        if duration > budget {
            slowFrameCount += 1
        } else {
            slowFrameCount = max(0, slowFrameCount - 1)
        }

        if fps == 60 && slowFrameCount >= 10 {
            fps = 30
            restart()
        } else if fps == 30 && slowFrameCount == 0 {
            fps = 60
            restart()
        }
    }

    private func scheduleTimer() {
        let interval = 1.0 / Double(fps)
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(2))
        timer.setEventHandler { [weak self] in
            self?.onTick?()
        }
        timer.resume()
        self.timer = timer
    }

    private func restart() {
        stop()
        scheduleTimer()
    }
}
