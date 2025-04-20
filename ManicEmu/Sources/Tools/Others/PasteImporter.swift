//
//  PasteImporter.swift
//  ManicEmu
//
//  Created by Aushuang Lee on 2025/1/21.
//  Copyright © 2025 Manic EMU. All rights reserved.
//

import UniformTypeIdentifiers

struct PasteImporter {
    static func paste(supportedTypes: [UTType] = UTType.allInfoPlistTypes) {
        UIView.makeLoading()
        DispatchQueue.global().async {
            var errors: [ImportError] = []
            var urls: [URL] = []
            let pasteboard = UIPasteboard.general
            let items = pasteboard.items
            
            
            Thread.sleep(forTimeInterval: 0.5)
            
            for item in items {
                if let fileURLData = item["public.file-url"] as? Data,
                   let fileURLString = String(data: fileURLData, encoding: .utf8),
                   let fileURL = URL(string: fileURLString) {
                    let exten = fileURL.pathExtension
                    
                    guard let _ = FileType(fileExtension: exten) else { continue }
                    let fileName = fileURL.lastPathComponent
                    do {
                        
                        let dstUrl = URL(fileURLWithPath: Constants.Path.PasteWorkSpace.appendingPathComponent(fileName))
                        try FileManager.safeCopyItem(at: fileURL, to: dstUrl, shouldReplace: true)
                        
                        urls.append(dstUrl)
                    } catch {
                        
                        errors.append(.badCopy(fileName: fileName))
                    }
                }
            }
            
            let handleDataGroup = DispatchGroup()
            if urls.count == 0 {
                
                let supportIdentifiers = UTType.allTypes.reduce("") { partialResult, type in
                    return partialResult + " " + type.identifier
                }
                let itemProviders = pasteboard.itemProviders
                for itemProvider in itemProviders {
                    var supportIdentifier: String? = nil
                    for itemProviderIdentifier in itemProvider.registeredTypeIdentifiers {
                        if supportIdentifiers.contains(itemProviderIdentifier, caseSensitive: false) {
                            supportIdentifier = itemProviderIdentifier
                            break
                        }
                    }
                    if let supportIdentifier = supportIdentifier {
                        
                        if let utType = UTType(supportIdentifier),
                            let extens = utType.tags[.filenameExtension]?.first,
                            let suggestedName = itemProvider.suggestedName {
                            
                            let fileName = suggestedName + "." + extens
                            
                            let dstUrl = URL(fileURLWithPath: Constants.Path.PasteWorkSpace.appendingPathComponent(fileName))
                            handleDataGroup.enter()
                            itemProvider.loadFileRepresentation(forTypeIdentifier: supportIdentifier) { url, error in
                                if let url = url {
                                    do {
                                        try FileManager.safeCopyItem(at: url, to: dstUrl, shouldReplace: true)
                                        
                                        urls.append(dstUrl)
                                        handleDataGroup.leave()
                                    } catch {
                                        
                                        errors.append(.badCopy(fileName: fileName))
                                        handleDataGroup.leave()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            handleDataGroup.notify(queue: .main) {
                if urls.count == 0 {
                    
                    if errors.isEmpty {
                        errors.append(.pasteNoMatchContent)
                    }
                    UIView.hideLoading()
                    UIView.makeToast(message: String.errorMessage(from: errors))
                } else {
                    FilesImporter.importFiles(urls: urls, preErrors: errors)
                }
            }
        }
    }
}
