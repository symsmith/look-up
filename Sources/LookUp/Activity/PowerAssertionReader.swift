import Foundation
import IOKit.pwr_mgt
import LookUpCore

enum PowerAssertionReader {
    static func current() -> [PowerAssertion] {
        var unmanaged: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&unmanaged) == kIOReturnSuccess,
              let byProcess = unmanaged?.takeRetainedValue() as NSDictionary? as? [NSNumber: [[String: Any]]]
        else { return [] }

        return byProcess.flatMap { pid, assertions in
            assertions.compactMap { assertion -> PowerAssertion? in
                if let level = assertion[kIOPMAssertionLevelKey] as? Int, level == 0 { return nil }
                return PowerAssertion(
                    pid: pid.int32Value,
                    processName: assertion["Process Name"] as? String ?? processName(pid: pid.int32Value),
                    type: assertion[kIOPMAssertionTypeKey] as? String ?? "",
                    name: assertion[kIOPMAssertionNameKey] as? String ?? ""
                )
            }
        }
    }

    private static func processName(pid: Int32) -> String {
        var buffer = [UInt8](repeating: 0, count: 256)
        let length = proc_name(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return "" }
        return String(decoding: buffer.prefix(Int(length)), as: UTF8.self)
    }
}
