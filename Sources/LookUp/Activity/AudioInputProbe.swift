import CoreAudio

enum AudioInputProbe {
    static func isInUse(excluding ownPID: pid_t) -> Bool {
        processes().contains { pid(of: $0) != ownPID && isRunningInput($0) }
    }

    private static func processes() -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let system = AudioObjectID(kAudioObjectSystemObject)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
        var processes = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &processes) == noErr else { return [] }
        return Array(processes.prefix(Int(size) / MemoryLayout<AudioObjectID>.size))
    }

    private static func pid(of process: AudioObjectID) -> pid_t? {
        var pid: pid_t = 0
        return read(kAudioProcessPropertyPID, of: process, into: &pid) ? pid : nil
    }

    private static func isRunningInput(_ process: AudioObjectID) -> Bool {
        var running: UInt32 = 0
        return read(kAudioProcessPropertyIsRunningInput, of: process, into: &running) && running != 0
    }

    private static func read<T: BitwiseCopyable>(_ selector: AudioObjectPropertySelector, of object: AudioObjectID, into value: inout T) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<T>.size)
        return AudioObjectGetPropertyData(object, &address, 0, nil, &size, &value) == noErr
    }
}
