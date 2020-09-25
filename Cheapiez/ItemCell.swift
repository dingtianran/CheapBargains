//
//  ItemCell.swift
//  Cheapiez
//
//  Created by Tianran Ding on 23/09/20.
//

import UIKit
import AlamofireImage

class ItemCell: UITableViewCell {
    static var identifier = "ItemCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var descView: UITextView!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let hover = UIHoverGestureRecognizer(
              target: self,
              action: #selector(self.hovering(_:))
            )
            self.addGestureRecognizer(hover)
        }
    }
    
    func updateWithItem(_ item: RSSItem) {
        //entry title
        titleLabel.text = item.title
        //entry date and author
        dateLabel.attributedText = composeDateStringFrom(item)
        //entry description
        descView.attributedText = composeDescStringFrom(item)
        //thumbnail image
        guard let urlString = item.imageURL else { return }
        guard let url = URL(string: urlString) else { return }
        thumbnail.af.setImage(withURL: url)
    }
    
    func composeDateStringFrom(_ item: RSSItem) -> NSAttributedString {
        let attr = NSMutableAttributedString()
        
        return attr
    }
    
    func composeDescStringFrom(_ item: RSSItem) -> NSAttributedString? {
        guard let html = item.description else { return nil }
        let fullHtml = htmlHead + html + htmlTail
        let data = Data(fullHtml.utf8)
        return try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
    }
    
    @objc func hovering(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
          case .began, .changed:
            backgroundColor = UIColor(white: 0.95, alpha: 1.0)
          case .ended:
            backgroundColor = .white
          default:
            backgroundColor = .white
        }
    }
    
    let htmlHead = """
    <html>
    <body>
    """
    
    let htmlTail = """
    </body>
    </html>
    """
}
