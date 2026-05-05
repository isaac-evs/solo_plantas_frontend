//
//  ARGardenViewModel.swift
//  VirtualGarden
//
//  Created by Isaac Vazquez Sandoval on 21/02/26.
//

import SwiftUI

@MainActor
class ARGardenViewModel: ObservableObject {

    enum GrowthState: Equatable {
        case scanning
        case placed
        case seeded
        case growing(day: Int)
        case blooming
    }

    let plant: PlantSpecies
    @Published var state: GrowthState
    @Published var currentIteration: Int = 0
    @Published var showPlantingFlash: Bool = false
    let overrideIteration: Int?

    private var timeTask: Task<Void, Never>?

    private let impactHeavy  = UIImpactFeedbackGenerator(style: .heavy)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactLight  = UIImpactFeedbackGenerator(style: .light)
    private let notification = UINotificationFeedbackGenerator()

    init(plant: PlantSpecies, isFullyGrown: Bool = false, overrideIteration: Int? = nil) {
        self.plant = plant
        self.overrideIteration = overrideIteration
        if isFullyGrown {
            self.state = .blooming
            self.currentIteration = 4
        } else {
            self.state = .scanning
            self.currentIteration = 0
        }
    }

    func markPotPlaced() {
        guard state == .scanning else { return }
        impactHeavy.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.impactMedium.impactOccurred()
        }
        state = .placed
    }

    func plantSeed() {
        guard state == .placed else { return }

        impactLight.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { self.impactMedium.impactOccurred() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { self.impactHeavy.impactOccurred() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { self.notification.notificationOccurred(.success) }

        showPlantingFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { self.showPlantingFlash = false }

        state = .seeded
        startTimer()
    }

    private func startTimer() {
        timeTask?.cancel()
        let totalDays  = plant.growthMilestones.last ?? 30
        let nanoPerDay = UInt64((15.0 / Double(totalDays)) * 1_000_000_000)

        timeTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: nanoPerDay)
                guard !Task.isCancelled else { break }
                advanceTime()
            }
        }
    }

    private func advanceTime() {
        var currentDay = 0
        if case .growing(let day) = state { currentDay = day }
        else if state == .seeded { currentDay = 0 }
        else { return }

        currentDay += 1

        let previousIteration = currentIteration
        let m = plant.growthMilestones
        guard m.count >= 4 else { return }

        if currentDay >= m[3] {
            state = .blooming
            currentIteration = 4
            timeTask?.cancel()
            notification.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { self.impactHeavy.impactOccurred() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { self.impactMedium.impactOccurred() }
        } else {
            state = .growing(day: currentDay)
            if currentDay == m[0] { currentIteration = 1 }
            if currentDay == m[1] { currentIteration = 2 }
            if currentDay == m[2] { currentIteration = 3 }
        }

        if currentIteration != previousIteration && currentIteration > 0 {
            impactMedium.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.impactLight.impactOccurred() }
        }
    }

    func cleanUp() { timeTask?.cancel() }
}
