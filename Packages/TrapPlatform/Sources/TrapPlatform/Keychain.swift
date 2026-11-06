import Foundation
import Security

/// A place for small secrets, keyed by name. The app uses the Keychain; tests and demo mode use memory.
public protocol SecretStore: AnyObject, Sendable {
    /// The stored bytes, or nil when nothing is stored under `key`.
    func data(for key: String) throws -> Data?
    /// Stores `data` under `key`, replacing what was there.
    func set(_ data: Data, for key: String) throws
    /// Removes `key`; no error when it was not there.
    func remove(_ key: String) throws
}

/// A Keychain call that failed, with its `OSStatus` for the log. Never shown to the shooter as is.
public struct KeychainError: Error, Equatable, Sendable {
    public let status: OSStatus
    public init(_ status: OSStatus) { self.status = status }
}

/// Generic passwords in the app's Keychain, readable only while the device is unlocked and never synced or
/// restored to another device (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`).
public final class KeychainStore: SecretStore, @unchecked Sendable {
    private let service: String

    /// - Parameter service: the Keychain service the items are filed under.
    public init(service: String = TrapLog.subsystem + ".accounts") { self.service = service }

    private func query(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: key]
    }

    public func data(for key: String) throws -> Data? {
        var q = query(key)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: CFTypeRef?
        let status = SecItemCopyMatching(q as CFDictionary, &out)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError(status) }
        return out as? Data
    }

    public func set(_ data: Data, for key: String) throws {
        let attributes: [String: Any] = [kSecValueData as String: data,
                                         kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        let status = SecItemUpdate(query(key) as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let add = query(key).merging(attributes) { _, new in new }
            let added = SecItemAdd(add as CFDictionary, nil)
            guard added == errSecSuccess else { throw KeychainError(added) }
        } else if status != errSecSuccess {
            throw KeychainError(status)
        }
    }

    public func remove(_ key: String) throws {
        let status = SecItemDelete(query(key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status) }
    }
}

/// Secrets in memory, for tests, previews and demo mode.
public final class MemorySecretStore: SecretStore, @unchecked Sendable {
    private var items: [String: Data] = [:]
    private let lock = NSLock()
    public init() {}
    public func data(for key: String) throws -> Data? { lock.withLock { items[key] } }
    public func set(_ data: Data, for key: String) throws { lock.withLock { items[key] = data } }
    public func remove(_ key: String) throws { lock.withLock { items[key] = nil } }
}
