#!/usr/bin/env swift
import Foundation

let iconNames = [
    "icon_16x16.png",
    "icon_16x16@2x.png",
    "icon_32x32.png",
    "icon_32x32@2x.png",
    "icon_128x128.png",
    "icon_128x128@2x.png",
    "icon_256x256.png",
    "icon_256x256@2x.png",
    "icon_512x512.png",
    "icon_512x512@2x.png",
]

let statusBarNames = [
    "statusbar_16.png",
    "statusbar_16@2x.png",
    "statusbar_18.png",
    "statusbar_18@2x.png",
    "statusbar_20.png",
    "statusbar_20@2x.png",
    "statusbar_22.png",
    "statusbar_22@2x.png",
    "statusbar_24.png",
    "statusbar_24@2x.png",
]

let permissionNames = [
    "permission_512.png",
    "permission_512@2x.png",
]

struct Arguments {
    let source: URL
    let destination: URL
    let statusBarDestination: URL?
    let permissionDestination: URL?
}

func parseArguments() -> Arguments? {
    var source: URL?
    var destination: URL?
    var statusBarDestination: URL?
    var permissionDestination: URL?

    var iterator = CommandLine.arguments.dropFirst().makeIterator()
    while let arg = iterator.next() {
        switch arg {
        case "--source":
            if let value = iterator.next() {
                source = URL(fileURLWithPath: value)
            }
        case "--destination":
            if let value = iterator.next() {
                destination = URL(fileURLWithPath: value)
            }
        case "--statusbar-destination":
            if let value = iterator.next() {
                statusBarDestination = URL(fileURLWithPath: value)
            }
        case "--permission-destination":
            if let value = iterator.next() {
                permissionDestination = URL(fileURLWithPath: value)
            }
        default:
            break
        }
    }

    guard let source, let destination else {
        return nil
    }
    return Arguments(
        source: source,
        destination: destination,
        statusBarDestination: statusBarDestination,
        permissionDestination: permissionDestination
    )
}

func syncIcons(_ args: Arguments) throws {
    let fileManager = FileManager.default
    try fileManager.createDirectory(at: args.destination, withIntermediateDirectories: true)

    var missing: [String] = []
    for name in iconNames {
        let src = args.source.appendingPathComponent("app_icon").appendingPathComponent(name)
        if !fileManager.fileExists(atPath: src.path) {
            missing.append(name)
            continue
        }
        let dest = args.destination.appendingPathComponent(name)
        if fileManager.fileExists(atPath: dest.path) {
            try fileManager.removeItem(at: dest)
        }
        try fileManager.copyItem(at: src, to: dest)
    }

    if let statusBarDestination = args.statusBarDestination {
        try fileManager.createDirectory(at: statusBarDestination, withIntermediateDirectories: true)
        for name in statusBarNames {
            let src = args.source.appendingPathComponent("status_bar").appendingPathComponent(name)
            if !fileManager.fileExists(atPath: src.path) {
                missing.append(name)
                continue
            }
            let dest = statusBarDestination.appendingPathComponent(name)
            if fileManager.fileExists(atPath: dest.path) {
                try fileManager.removeItem(at: dest)
            }
            try fileManager.copyItem(at: src, to: dest)
        }
    }

    if let permissionDestination = args.permissionDestination {
        try fileManager.createDirectory(at: permissionDestination, withIntermediateDirectories: true)
        for name in permissionNames {
            let src = args.source.appendingPathComponent("permission_icon").appendingPathComponent(name)
            if !fileManager.fileExists(atPath: src.path) {
                missing.append(name)
                continue
            }
            let dest = permissionDestination.appendingPathComponent(name)
            if fileManager.fileExists(atPath: dest.path) {
                try fileManager.removeItem(at: dest)
            }
            try fileManager.copyItem(at: src, to: dest)
        }
    }

    if !missing.isEmpty {
        let missingList = missing.joined(separator: ", ")
        throw NSError(
            domain: "SyncIcons",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Missing generated icons: \(missingList)"]
        )
    }
}

guard let args = parseArguments() else {
    fputs("Usage: sync_icons.swift --source <dir> --destination <dir> [--statusbar-destination <dir>] [--permission-destination <dir>]\n", stderr)
    exit(1)
}

do {
    try syncIcons(args)
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
