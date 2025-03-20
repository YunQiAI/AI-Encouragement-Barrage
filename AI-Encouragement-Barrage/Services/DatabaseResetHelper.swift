//
//  DatabaseResetHelper.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation

struct DatabaseResetHelper {
    static func resetDatabase() {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        
        let storeURL = appSupportURL.appendingPathComponent("default.store")
        
        do {
            if fileManager.fileExists(atPath: storeURL.path) {
                try fileManager.removeItem(at: storeURL)
                print("数据库文件已成功删除")
            }
            
            // 清除与数据库相关的其他文件
            let storeFiles = [
                storeURL.appendingPathExtension("sqlite"),
                storeURL.appendingPathExtension("sqlite-shm"),
                storeURL.appendingPathExtension("sqlite-wal")
            ]
            
            for file in storeFiles {
                if fileManager.fileExists(atPath: file.path) {
                    try fileManager.removeItem(at: file)
                    print("删除相关文件: \(file.lastPathComponent)")
                }
            }
        } catch {
            print("删除数据库文件失败: \(error.localizedDescription)")
        }
    }
}
