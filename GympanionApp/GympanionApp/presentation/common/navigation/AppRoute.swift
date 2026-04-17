// GympanionApp/presentation/common/navigation/AppRoute.swift
import Foundation

enum AppRoute: Hashable {
    // Auth
    case login
    case register

    // Exercises
    case exerciseList
    case exerciseDetail(String)
    case exerciseEditor(String?)

    // Workouts
    case workoutList
    case workoutDetail(String)
    case workoutBuilder(String?)

    // Sessions
    case sessionHistory
    case sessionDetail(String)

    // Analytics
    case dashboard
    case exerciseProgress(String)
    case prList

    // Social
    case feed
    case profile(String?)

    // Watch
    case watchSync
    case liveSession
}
