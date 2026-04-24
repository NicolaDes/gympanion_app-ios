// GympanionApp/data/garmin/LRUSet.swift
import Foundation

/// A bounded, insertion-ordered set. When `insert(_:)` would exceed `capacity`
/// the oldest entry is evicted. Re-inserting an existing element refreshes
/// its position (moves it to the tail) and returns `false`.
///
/// Not thread-safe — callers provide their own isolation (an actor, in the
/// case of `GarminMessageDedupFilter`).
struct LRUSet<Element: Hashable> {
    let capacity: Int
    private var members: Set<Element> = []
    private var order: [Element] = []

    init(capacity: Int) {
        precondition(capacity > 0)
        self.capacity = capacity
    }

    /// Returns `true` if the element was newly added, `false` if it was
    /// already present (in which case its position is still refreshed).
    @discardableResult
    mutating func insert(_ element: Element) -> Bool {
        if members.contains(element) {
            // Refresh position: remove from order, re-append to tail.
            if let idx = order.firstIndex(of: element) {
                order.remove(at: idx)
            }
            order.append(element)
            return false
        }
        members.insert(element)
        order.append(element)
        if order.count > capacity {
            let evicted = order.removeFirst()
            members.remove(evicted)
        }
        return true
    }

    var count: Int { order.count }
}
