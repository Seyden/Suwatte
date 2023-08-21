//
//  Panel+Watcher.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2023-08-06.
//

import Foundation
import Combine



final class PanelPublisher {
    static let shared = PanelPublisher()
    
    let willSplitPage = PassthroughSubject<PanelPage, Never>()
    let sliderPct = PassthroughSubject<Double, Never>()
    let didEndScrubbing = PassthroughSubject<Void, Never>()
    let didChangeHorizontalDirection = PassthroughSubject<Void, Never>()
    let didChangeSplitMode = PassthroughSubject<Void, Never>()
    let autoScrollDidStart = PassthroughSubject<Bool, Never>()
    let autoScrollDidStop = PassthroughSubject<Void, Never>()
}
