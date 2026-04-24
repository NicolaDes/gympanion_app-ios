// GympanionApp/data/garmin/GarminMessageDedupFilter.swift
import Foundation

/// Drops duplicate `set_complete` and `session_result` payloads that arise
/// from the watch's on-watch buffer replaying sets after a reconnect.
///
/// Composite key schema:
///   • set_complete:   "set|<sessionId>|<blockIndex>|<exerciseIndex>|<setIndex>|<roundKey>"
///     where roundKey = roundIndex OR amrapRound OR "-" if neither is present
///   • session_result: "result|<sessionId>"
///
/// Payloads missing their identifying fields (e.g., a pre-upgrade watch that
/// doesn't send sessionId) are always accepted. Unknown payload types bypass
/// the filter entirely.
///
/// In-memory only. On app relaunch the set is empty — see plan header for
/// rationale (sessionRepo is idempotent on session_result).
actor GarminMessageDedupFilter {
    private var seen: LRUSet<String>

    init(capacity: Int = 1000) {
        self.seen = LRUSet<String>(capacity: capacity)
    }

    /// Returns `true` if the payload has not been seen before (caller should
    /// forward it downstream), `false` if it is a duplicate (caller should drop).
    func shouldAccept(_ payload: [String: Any]) -> Bool {
        guard let type = payload["type"] as? String else {
            return true  // no type → unroutable elsewhere, leave filter as no-op
        }

        let key: String?
        switch type {
        case "set_complete":
            key = keyForSetComplete(payload)
        case "session_result":
            key = keyForSessionResult(payload)
        default:
            return true  // liveStatus, workout_replace_response, error, etc.
        }

        guard let k = key else {
            // Missing identifying fields — accept rather than silently drop.
            return true
        }
        return seen.insert(k)
    }

    /// Session-typed overload used by consumers of `receiveSessionStream()`
    /// (e.g., `GarminRepositoryImpl`). Shares the seen-set with
    /// `shouldAccept(_:)` so raw-dict and typed paths can't double-ingest
    /// the same replayed `session_result`.
    func shouldAcceptSession(_ session: Session) -> Bool {
        // Must match keyForSessionResult so the raw-dict and typed paths
        // share a key and cannot double-ingest the same session_result.
        return seen.insert("result|\(session.id)")
    }

    private func keyForSetComplete(_ p: [String: Any]) -> String? {
        guard let sessionId = p["sessionId"] as? String,
              let bi = p["blockIndex"]    as? Int,
              let ei = p["exerciseIndex"] as? Int,
              let si = p["setIndex"]      as? Int
        else { return nil }
        // EMOM uses `roundIndex`, AMRAP uses `amrapRound`; sequential has neither.
        let roundKey: String
        if let ri = p["roundIndex"] as? Int      { roundKey = "r\(ri)" }
        else if let ar = p["amrapRound"] as? Int { roundKey = "a\(ar)" }
        else                                     { roundKey = "-"     }
        return "set|\(sessionId)|\(bi)|\(ei)|\(si)|\(roundKey)"
    }

    private func keyForSessionResult(_ p: [String: Any]) -> String? {
        guard let sessionId = p["sessionId"] as? String else { return nil }
        return "result|\(sessionId)"
    }
}
