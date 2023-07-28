//
//  NV+Page.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2023-07-27.
//

import UIKit
import WebKit

extension NovelViewer {
    class ChapterCell: UICollectionViewCell, WKNavigationDelegate {
        private var webView: WKWebView!
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            let webConfiguration = WKWebViewConfiguration()
            webView = WKWebView(frame: .zero, configuration: webConfiguration)
            webView.navigationDelegate = self
            webView.translatesAutoresizingMaskIntoConstraints = false
            
            webView.scrollView.bounces = false
            webView.scrollView.isPagingEnabled = true
            webView.scrollView.contentInsetAdjustmentBehavior = .never
            contentView.addSubview(webView)
            
            // Vertical
//            NSLayoutConstraint.activate([
//                webView.topAnchor.constraint(equalTo: contentView.topAnchor),
//                webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//                webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//                webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
//            ])
            
            NSLayoutConstraint.activate([
                webView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor),
                webView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
                webView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func loadChapter(htmlContent: String) {

//            // Paging with CSS
            let css = """
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
                overflow-y: hidden;

            }
            body {
            overflow-x: visible;
            }
            
            .content {
            height: 100vh;
            padding-left: 5vw;
            padding-right: 5vw;
            box-sizing: border-box;
            column-width: 90vw;
            column-gap: 10vw;
            font-size: 20px;
            overflow: hidden;
            }

            """
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                \(css)
                </style>
            <meta name="viewport" content="width=device-width, height=device-height, initial-scale=1" />

            </head>
            <body>
            <div class="content">
                \(htmlContent)
            </div>
            </body>
            
            <script>
            function updateContentWidth() {
                var viewportWidth = window.innerWidth;
            
                let content = document.querySelector('.content');
                let contentWidth = content.scrollWidth;
                var pageCount = Math.ceil(contentWidth / viewportWidth);
                let finalWidth = pageCount * viewportWidth + 'px';
                content.style.width = finalWidth
            
                let body = document.querySelector('body');
                body.style.width = finalWidth;
            }

            // Call it initially
            updateContentWidth();

            // Call it again whenever needed
            window.addEventListener('resize', updateContentWidth);

            </script>
            </html>
            """
            
            webView.loadHTMLString(html, baseURL: nil)
        }
    }
}
