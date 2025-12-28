//
//  InversionDisplayWindow.swift
//  Invar
//

import AppKit

protocol InversionDisplayWindow: AnyObject {
    var nsWindow: NSWindow { get }
    func present()
    func close()
    func update(image: CGImage?)
    func setFrame(_ frame: CGRect, display: Bool)
}
