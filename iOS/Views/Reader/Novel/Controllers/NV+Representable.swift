//
//  NV+Representable.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2023-07-27.
//

import UIKit
import SwiftUI



extension NovelViewer {
    struct ControllerRepresentable: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> UICollectionViewController {
            build(context: context)
        }
        
        func updateUIViewController(_ controller: UICollectionViewController, context: Context) {
            configure(controller, context: context)
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
    }
}

// MARK: Build
extension NovelViewer.ControllerRepresentable {
    private func build(context: Context) -> UICollectionViewController {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let controller = UICollectionViewController(collectionViewLayout: layout)
        controller.collectionView?.register(NovelViewer.ChapterCell.self, forCellWithReuseIdentifier: "cell")
        
        controller.collectionView.delegate = context.coordinator
        controller.collectionView.dataSource = context.coordinator
        controller.collectionView.contentInsetAdjustmentBehavior = .never
        
        context.coordinator.collectionView = controller.collectionView
        return controller
    }
}

// MARK: Configure
extension NovelViewer.ControllerRepresentable {
    private func configure(_ controller: UICollectionViewController, context: Context) {
        controller.collectionView.isPagingEnabled = true
        controller.collectionView.bounces = false
    }
}
