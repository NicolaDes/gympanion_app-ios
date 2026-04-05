// GympanionApp/data/provider/StaticWorkoutProvider.swift
import Foundation

final class StaticWorkoutProvider: WorkoutProvider {

    private let workouts: [Workout]

    init() {
        let now = Date()
        workouts = [
            Self.pushDay(createdAt: now),
            Self.pullDay(createdAt: now),
            Self.fridayWod(createdAt: now),
        ]
    }

    func getAllWorkouts() -> [Workout] { workouts }

    func getWorkout(byId id: String) -> Workout? {
        workouts.first { $0.id == id }
    }

    // MARK: - Workout Definitions

    private static func pushDay(createdAt: Date) -> Workout {
        let benchPress = SequentialExerciseDef(
            id: "ex_bench_press",
            name: "Bench Press",
            sets: (0..<4).map { i in
                BlockSetParams(setIndex: i, reps: 10, weightKg: 60, durationSeconds: nil, distanceMeters: nil, restSeconds: 90)
            }
        )
        let ohp = SequentialExerciseDef(
            id: "ex_ohp",
            name: "Overhead Press",
            sets: (0..<3).map { i in
                BlockSetParams(setIndex: i, reps: 10, weightKg: 40, durationSeconds: nil, distanceMeters: nil, restSeconds: 90)
            }
        )
        let dips = SequentialExerciseDef(
            id: "ex_tricep_dips",
            name: "Tricep Dips",
            sets: (0..<3).map { i in
                BlockSetParams(setIndex: i, reps: 12, weightKg: nil, durationSeconds: nil, distanceMeters: nil, restSeconds: 60)
            }
        )

        let block = WorkoutBlock.sequential(name: nil, exercises: [benchPress, ohp, dips])

        // Build flat exercises list for v1 compatibility
        let exercises = [benchPress, ohp, dips].enumerated().map { order, def in
            WorkoutExercise(
                id: def.id,
                exercise: Exercise(
                    id: def.id, name: def.name, description: nil,
                    category: .strength, primaryMuscleGroups: [.chest],
                    secondaryMuscleGroups: [.triceps, .shoulders],
                    defaultParams: ExerciseParams(sets: def.sets.count, reps: def.sets.first?.reps, durationSeconds: nil, distanceMeters: nil, weightKg: def.sets.first?.weightKg, restSeconds: def.sets.first?.restSeconds),
                    isCustom: false, createdAt: createdAt, updatedAt: createdAt
                ),
                order: order,
                params: ExerciseParams(sets: def.sets.count, reps: def.sets.first?.reps, durationSeconds: nil, distanceMeters: nil, weightKg: def.sets.first?.weightKg, restSeconds: def.sets.first?.restSeconds),
                notes: nil
            )
        }

        return Workout(
            id: "workout_push_day",
            name: "Push Day",
            description: "Chest, shoulders & triceps",
            exercises: exercises,
            estimatedDurationMinutes: 45,
            createdAt: createdAt,
            updatedAt: createdAt,
            blocks: [block]
        )
    }

    private static func pullDay(createdAt: Date) -> Workout {
        let deadlift = SequentialExerciseDef(
            id: "ex_deadlift",
            name: "Deadlift",
            sets: (0..<3).map { i in
                BlockSetParams(setIndex: i, reps: 5, weightKg: 100, durationSeconds: nil, distanceMeters: nil, restSeconds: 180)
            }
        )
        let row = SequentialExerciseDef(
            id: "ex_barbell_row",
            name: "Barbell Row",
            sets: (0..<4).map { i in
                BlockSetParams(setIndex: i, reps: 8, weightKg: 60, durationSeconds: nil, distanceMeters: nil, restSeconds: 90)
            }
        )
        let pullups = SequentialExerciseDef(
            id: "ex_pullups",
            name: "Pull-ups",
            sets: (0..<3).map { i in
                BlockSetParams(setIndex: i, reps: 10, weightKg: nil, durationSeconds: nil, distanceMeters: nil, restSeconds: 60)
            }
        )

        let block = WorkoutBlock.sequential(name: nil, exercises: [deadlift, row, pullups])

        let exercises = [
            (deadlift, [MuscleGroup.back, .hamstrings], [MuscleGroup.glutes, .forearms]),
            (row,      [.back],                         [.biceps, .forearms]),
            (pullups,  [.back],                         [.biceps, .forearms]),
        ].enumerated().map { order, tuple in
            let (def, primary, secondary) = tuple
            return WorkoutExercise(
                id: def.id,
                exercise: Exercise(
                    id: def.id, name: def.name, description: nil,
                    category: .strength, primaryMuscleGroups: primary,
                    secondaryMuscleGroups: secondary,
                    defaultParams: ExerciseParams(sets: def.sets.count, reps: def.sets.first?.reps, durationSeconds: nil, distanceMeters: nil, weightKg: def.sets.first?.weightKg, restSeconds: def.sets.first?.restSeconds),
                    isCustom: false, createdAt: createdAt, updatedAt: createdAt
                ),
                order: order,
                params: ExerciseParams(sets: def.sets.count, reps: def.sets.first?.reps, durationSeconds: nil, distanceMeters: nil, weightKg: def.sets.first?.weightKg, restSeconds: def.sets.first?.restSeconds),
                notes: nil
            )
        }

        return Workout(
            id: "workout_pull_day",
            name: "Pull Day",
            description: "Back, biceps & grip",
            exercises: exercises,
            estimatedDurationMinutes: 50,
            createdAt: createdAt,
            updatedAt: createdAt,
            blocks: [block]
        )
    }

    private static func fridayWod(createdAt: Date) -> Workout {
        // Block 1: Sequential — Back Squat
        let squat = SequentialExerciseDef(
            id: "ex_back_squat",
            name: "Back Squat",
            sets: (0..<5).map { i in
                BlockSetParams(setIndex: i, reps: 5, weightKg: 80, durationSeconds: nil, distanceMeters: nil, restSeconds: 120)
            }
        )
        let sequentialBlock = WorkoutBlock.sequential(name: "Strength", exercises: [squat])

        // Block 2: EMOM — Burpees
        let emomRounds = (0..<10).map { i in
            EmomRound(roundIndex: i, sets: [
                EmomSetDef(exerciseId: "ex_burpees", exerciseName: "Burpees", reps: 5, weightKg: nil, durationSeconds: nil, distanceMeters: nil)
            ])
        }
        let emomBlock = WorkoutBlock.emom(name: "Conditioning", intervalSeconds: 60, rounds: emomRounds)

        // Block 3: AMRAP — KB Swings + Box Jumps
        let amrapSets = [
            AmrapSetDef(exerciseId: "ex_kb_swings", exerciseName: "KB Swings", reps: 10, weightKg: 24, durationSeconds: nil, distanceMeters: nil),
            AmrapSetDef(exerciseId: "ex_box_jumps", exerciseName: "Box Jumps", reps: 10, weightKg: nil, durationSeconds: nil, distanceMeters: nil),
        ]
        let amrapBlock = WorkoutBlock.amrap(name: "Finisher", timeCapSeconds: 480, sets: amrapSets)

        // Flat exercises for v1 compatibility (just the sequential ones — EMOM/AMRAP don't map cleanly)
        let exercises = [
            WorkoutExercise(
                id: "ex_back_squat",
                exercise: Exercise(
                    id: "ex_back_squat", name: "Back Squat", description: nil,
                    category: .strength, primaryMuscleGroups: [.quadriceps, .glutes],
                    secondaryMuscleGroups: [.hamstrings, .core],
                    defaultParams: ExerciseParams(sets: 5, reps: 5, durationSeconds: nil, distanceMeters: nil, weightKg: 80, restSeconds: 120),
                    isCustom: false, createdAt: createdAt, updatedAt: createdAt
                ),
                order: 0,
                params: ExerciseParams(sets: 5, reps: 5, durationSeconds: nil, distanceMeters: nil, weightKg: 80, restSeconds: 120),
                notes: nil
            )
        ]

        return Workout(
            id: "workout_friday_wod",
            name: "Friday WOD",
            description: "Squat, EMOM conditioning, AMRAP finisher",
            exercises: exercises,
            estimatedDurationMinutes: 40,
            createdAt: createdAt,
            updatedAt: createdAt,
            blocks: [sequentialBlock, emomBlock, amrapBlock]
        )
    }
}
