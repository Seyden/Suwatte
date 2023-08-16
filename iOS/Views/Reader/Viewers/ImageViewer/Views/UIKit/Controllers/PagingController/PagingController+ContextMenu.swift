//
//  PagingController+ContextMenu.swift
//  Suwatte
//
//  Created by Mantton on 2023-08-15.
//

import UIKit

fileprivate typealias Controller = IVPagingController

extension Controller: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let point = interaction.location(in: collectionView)
        let indexPath = collectionView.indexPathForItem(at: point)
        
        guard let indexPath,
              case .page(let page) = dataSource.itemIdentifier(for: indexPath),
              let image = (interaction.view as? UIImageView)?.image
        else { return nil }
        
        let chapter = page.page.chapter
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ in
            
            // Image Actiosn menu
            // Save to Photos
            let saveToAlbum = UIAction(title: "Save Panel", image: UIImage(systemName: "square.and.arrow.down")) { _ in
                STTPhotoAlbum.shared.save(image)
                ToastManager.shared.info("Panel Saved!")
            }
            
            // Share Photo
            let sharePhotoAction = UIAction(title: "Share Panel", image: UIImage(systemName: "square.and.arrow.up")) { _ in
                let objectsToShare = [image]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                self.present(activityVC, animated: true, completion: nil)
            }
            
            let photoMenu = UIMenu(title: "", options: .displayInline, children: [saveToAlbum, sharePhotoAction])
            
            var menu = UIMenu(title: "Page \(page.page.index + 1)", children: [photoMenu])
            
            guard !STTHelpers.isInternalSource(chapter.sourceId) else { return menu }
            
            // Bookmark Actions
            
//            let isBookmarked = DataManager.shared.isBookmarked(chapter: chapter.toStored(), page: page.page.index)
//            let bkTitle = isBookmarked ? "Remove Bookmark" : "Bookmark Panel"
//            let bkSysImage = isBookmarked ? "bookmark.slash" : "bookmark"
//
//            let bookmarkAction = UIAction(title: bkTitle, image: UIImage(systemName: bkSysImage), attributes: isBookmarked ? [.destructive] : []) { _ in
//                DataManager.shared.toggleBookmark(chapter: chapter.toStored(), page: page.page.index)
//                ToastManager.shared.info("Bookmark \(isBookmarked ? "Removed" : "Added")!")
//            }
            
            menu = menu.replacingChildren([photoMenu])
            return menu
        })
    }
}
