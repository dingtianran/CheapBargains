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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //set zero margins for text view
        descView.textContainerInset = UIEdgeInsets(top: 8.0, left: 0, bottom: 0, right: 0)
    }
    
    func updateWithItem(_ item: FeedEntry) {
        //entry title
        titleLabel.text = item.title
        //entry date and author
        dateLabel.attributedText = item.subtitle
        //entry description
        descView.attributedText = item.desc
        //thumbnail image
        guard let url = URL(string: item.imageURL) else { return }
        thumbnail.af.setImage(withURL: url)
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
}
