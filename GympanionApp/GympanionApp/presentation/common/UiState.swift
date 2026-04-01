// GympanionApp/presentation/common/UiState.swift
enum UiState<T> {
    case idle
    case loading
    case success(T)
    case error(String)
}
