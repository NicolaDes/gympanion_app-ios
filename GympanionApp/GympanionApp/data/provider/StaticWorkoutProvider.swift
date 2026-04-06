// GympanionApp/data/provider/StaticWorkoutProvider.swift
import Foundation

final class StaticWorkoutProvider: WorkoutProvider {

    private let workouts: [Workout]

    init() {
        let now = Date()
        workouts = [
            Self.workoutA(createdAt: now),
        ]
    }

    func getAllWorkouts() -> [Workout] { workouts }

    func getWorkout(byId id: String) -> Workout? {
        workouts.first { $0.id == id }
    }

    // MARK: - Workout Definitions

    private static func workoutA(createdAt: Date) -> Workout {
        // Block 1: Sequential — Squat 3RM @8 backoff
        let squat3rm = SequentialExerciseDef(
            id: "ex_squat_3rm",
            name: "Back Squat (3RM)",
            sets: (0..<3).map { i in
                BlockSetParams(setIndex: i, reps: 3, weightKg: 110, durationSeconds: nil, distanceMeters: nil, restSeconds: 120)
            }
        )

        // Block 2: Sequential — Squat Backoff 2×7 @ 88kg (20% less)
        let squatBackoff = SequentialExerciseDef(
            id: "ex_squat_backoff",
            name: "Back Squat (Backoff)",
            sets: (0..<2).map { i in
                BlockSetParams(setIndex: i, reps: 7, weightKg: 88, durationSeconds: nil, distanceMeters: nil, restSeconds: 120)
            }
        )

        // Block 3: Sequential — Bench Press 3RM @8 backoff
        let bench3rm = SequentialExerciseDef(
            id: "ex_bench_3rm",
            name: "Bench Press (3RM)",
            sets: (0..<3).map { i in
                BlockSetParams(setIndex: i, reps: 3, weightKg: 85, durationSeconds: nil, distanceMeters: nil, restSeconds: 120)
            }
        )

        // Block 4: Sequential — Bench Press Backoff 2×7 @ 68kg (20% less)
        let benchBackoff = SequentialExerciseDef(
            id: "ex_bench_backoff",
            name: "Bench Press (Backoff)",
            sets: (0..<2).map { i in
                BlockSetParams(setIndex: i, reps: 7, weightKg: 68, durationSeconds: nil, distanceMeters: nil, restSeconds: 120)
            }
        )

        let strengthBlock = WorkoutBlock.sequential(
            name: "Strength",
            exercises: [squat3rm, squatBackoff, bench3rm, benchBackoff]
        )

        // Block 5: EMOM — Pull-ups 3 reps every minute for 10 minutes
        let emomRounds = (0..<10).map { i in
            EmomRound(roundIndex: i, sets: [
                EmomSetDef(exerciseId: "ex_pullups", exerciseName: "Pull-ups", reps: 3, weightKg: nil, durationSeconds: nil, distanceMeters: nil)
            ])
        }
        let emomBlock = WorkoutBlock.emom(name: "Pull-ups EMOM", intervalSeconds: 60, rounds: emomRounds)

        // Block 6: Sequential — Accessories
        let zPress = SequentialExerciseDef(
            id: "ex_single_z_press",
            name: "Single Z Press",
            sets: (0..<3).map { i in
                BlockSetParams(setIndex: i, reps: 10, weightKg: nil, durationSeconds: nil, distanceMeters: nil, restSeconds: 60)
            }
        )
        let latMachine = SequentialExerciseDef(
            id: "ex_single_lat_machine",
            name: "Single Lat Machine",
            sets: (0..<3).map { i in
                BlockSetParams(setIndex: i, reps: 10, weightKg: nil, durationSeconds: nil, distanceMeters: nil, restSeconds: 60)
            }
        )
        let accessoryBlock = WorkoutBlock.sequential(name: "Accessories", exercises: [zPress, latMachine])

        // Flat exercises for v1 compatibility (ordered to match block sequence)
        let allDefs: [(SequentialExerciseDef, [MuscleGroup], [MuscleGroup], String?)] = [
            (squat3rm,     [.quadriceps, .glutes],  [.hamstrings, .core],   nil),
            (squatBackoff, [.quadriceps, .glutes],  [.hamstrings, .core],   nil),
            (bench3rm,     [.chest],                [.triceps, .shoulders], nil),
            (benchBackoff, [.chest],                [.triceps, .shoulders], nil),
            (zPress,       [.shoulders],            [.core, .triceps],      "8-12 reps"),
            (latMachine,   [.back],                 [.biceps],              "8-12 reps"),
        ]
        var exercises: [WorkoutExercise] = allDefs.enumerated().map { order, tuple in
            let (def, primary, secondary, notes) = tuple
            let adjustedOrder = order < 4 ? order : order + 1  // leave slot 4 for pull-ups
            return WorkoutExercise(
                id: def.id,
                exercise: Exercise(
                    id: def.id, name: def.name, description: nil,
                    category: .strength, primaryMuscleGroups: primary,
                    secondaryMuscleGroups: secondary,
                    defaultParams: ExerciseParams(sets: def.sets.count, reps: def.sets.first?.reps, durationSeconds: nil, distanceMeters: nil, weightKg: def.sets.first?.weightKg, restSeconds: def.sets.first?.restSeconds),
                    isCustom: false, createdAt: createdAt, updatedAt: createdAt
                ),
                order: adjustedOrder,
                params: ExerciseParams(sets: def.sets.count, reps: def.sets.first?.reps, durationSeconds: nil, distanceMeters: nil, weightKg: def.sets.first?.weightKg, restSeconds: def.sets.first?.restSeconds),
                notes: notes
            )
        }
        // Insert pull-ups (EMOM) at position 4 (between bench backoff and accessories)
        exercises.insert(WorkoutExercise(
            id: "ex_pullups",
            exercise: Exercise(
                id: "ex_pullups", name: "Pull-ups", description: nil,
                category: .strength, primaryMuscleGroups: [.back],
                secondaryMuscleGroups: [.biceps, .forearms],
                defaultParams: ExerciseParams(sets: 10, reps: 3, durationSeconds: nil, distanceMeters: nil, weightKg: nil, restSeconds: 60),
                isCustom: false, createdAt: createdAt, updatedAt: createdAt
            ),
            order: 4,
            params: ExerciseParams(sets: 10, reps: 3, durationSeconds: nil, distanceMeters: nil, weightKg: nil, restSeconds: 60),
            notes: "EMOM 10 min"
        ), at: 4)

        return Workout(
            id: "workout_a",
            name: "Workout A",
            description: "Squat & Bench 3RM + backoff, Pull-ups EMOM, accessories",
            exercises: exercises,
            estimatedDurationMinutes: 75,
            createdAt: createdAt,
            updatedAt: createdAt,
            blocks: [strengthBlock, emomBlock, accessoryBlock]
        )
    }
}
