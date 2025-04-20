//
//  Log.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/11.
//  Copyright © 2025 Manic EMU. All rights reserved.
//
import XCGLogger
import SSZipArchive

let Log = XCGLogger(identifier: "XCGLogger", includeDefaultDestinations: false)

func LogSetup() {
#if DEBUG
    // Create a destination for the system console log (via NSLog)
    let systemDestination = AppleSystemLogDestination(identifier: "com.aoshuang.manicemu.log.console")
    
    // Optionally set some configuration options
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = true
    systemDestination.showThreadName = true
    systemDestination.showLevel = true
    systemDestination.showFileName = true
    systemDestination.showLineNumber = true
    systemDestination.showDate = true
    
    // Add the destination to the logger
    Log.add(destination: systemDestination)
#endif
    
    let fileDestination = AutoRotatingFileDestination(writeToFile: Constants.Path.Log,
                                                      identifier: "com.aoshuang.manicemu.log.file",
                                                      shouldAppend: true,
                                                      maxTimeInterval: 24*60*60,
                                                      archiveSuffixDateFormatter: Log.dateFormatter)
    
    // Optionally set some configuration options
    fileDestination.outputLevel = .debug
    fileDestination.showLogIdentifier = false
    fileDestination.showFunctionName = true
    fileDestination.showThreadName = true
    fileDestination.showLevel = true
    fileDestination.showFileName = true
    fileDestination.showLineNumber = true
    fileDestination.showDate = true
    
    // Process this destination in the background
    fileDestination.logQueue = XCGLogger.logQueue
    
    // Add the destination to the logger
    Log.add(destination: fileDestination)
    
    // Add basic app info, version info etc, to the start of the logs
    Log.logAppDetails()
}
