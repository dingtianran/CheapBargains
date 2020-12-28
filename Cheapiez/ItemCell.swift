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
    @IBOutlet weak var votingsLabel: UILabel!
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
        titleLabel.attributedText = item.title
        //entry date and author
        dateLabel.attributedText = item.subtitle
        //entry description
        descView.attributedText = item.desc
        //votings
        votingsLabel.attributedText = item.votings
        //thumbnail image
        guard let url = URL(string: item.imageURL) else { return }
        thumbnail.af.setImage(withURL: url)
    }
    
    @objc func hovering(_ recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
          case .began, .changed:
            backgroundColor = .systemTeal
            votingsLabel.textColor = .white
          case .ended:
            backgroundColor = .systemBackground
            votingsLabel.textColor = .systemTeal
          default:
            backgroundColor = .systemBackground
            votingsLabel.textColor = .systemTeal
        }
    }
}
