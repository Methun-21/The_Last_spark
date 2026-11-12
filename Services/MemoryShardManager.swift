import SwiftUI
import Combine

public class MemoryShardManager: ObservableObject {
    public static let shared = MemoryShardManager()
    
    @Published public private(set) var shardsPerLevel: [Int: Set<Int>] = [:]
    
    private init() {
        loadShards()
    }
    
    private func loadShards() {
        var loaded: [Int: Set<Int>] = [:]
        for level in 1...30 {
            if let array = UserDefaults.standard.array(forKey: "memory_shards_lvl_\(level)") as? [Int] {
                loaded[level] = Set(array)
            } else {
                loaded[level] = []
            }
        }
        self.shardsPerLevel = loaded
    }
    
    public func collectShard(level: Int, shardIndex: Int) {
        var current = shardsPerLevel[level] ?? []
        guard !current.contains(shardIndex) else { return }
        
        current.insert(shardIndex)
        shardsPerLevel[level] = current
        UserDefaults.standard.set(Array(current), forKey: "memory_shards_lvl_\(level)")
        
        // Award bonus currency for finding rare narrative shards!
        StoreManager.shared.balance += 150
    }
    
    public func shardCount(for level: Int) -> Int {
        return shardsPerLevel[level]?.count ?? 0
    }
    
    public var totalShardsCollected: Int {
        shardsPerLevel.values.reduce(0) { $0 + $1.count }
    }
    
    public func isLoreUnlocked(for level: Int) -> Bool {
        // Unlocked if level is completed OR at least 1 shard is found
        let highestUnlocked = UserDefaults.standard.integer(forKey: "unlockedLevels")
        return level < highestUnlocked || shardCount(for: level) > 0
    }
}

