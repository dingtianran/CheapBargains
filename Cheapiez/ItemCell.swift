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
        descView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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
    
    private static var rssFormatter: DateFormatter {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy - hh:mm"
            dateFormatter.locale = NSLocale.current
            return dateFormatter
        }
    }
    
    func composeDateStringFrom(_ item: RSSItem) -> NSAttributedString {
        let attr = NSMutableAttributedString()
        //creator
        let creator = item.creator ?? "N/A"
        let attributesCreator: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor(red: 1.0/256.0, green: 25.0/256.0, blue: 147.0/256.0, alpha: 1.0),
        ]
        let creatorAttr = NSAttributedString(string: creator, attributes: attributesCreator)
        attr.append(creatorAttr)
        //date
        let attributesDate: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.lightGray,
        ]
        if let date = item.pubDate {
            let dateStr = " on " + ItemCell.rssFormatter.string(from: date)
            let on = NSAttributedString(string: dateStr, attributes: attributesDate)
            attr.append(on)
        }
        
        return attr
    }
    
    func composeDescStringFrom(_ item: RSSItem) -> NSAttributedString? {
        guard let input = item.description else { return nil }
        let html = formattingDescription(input)
        let fullHtml = htmlHead + html + htmlTail
        let data = Data(fullHtml.utf8)
        return try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
    }
    
    //Get rid of the first div which is a web hack for thumbnail
    func formattingDescription(_ input: String) -> String {
        var processed = input.replacingOccurrences(of: "\n", with: "")
        let regex1 = try? NSRegularExpression(pattern: "\\<div(.*)\\<\\/div\\>", options: .caseInsensitive)
        let matches = regex1!.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
        if let match = matches.first {
            let range = match.range(at:0)
            if let divRange = Range(range, in: input) {
                processed.removeSubrange(divRange)
            }
        }
        //get rid of all tables
        processed = processed.replacingOccurrences(of: "\\<table[^>]*\\>(.*?)\\<\\/table\\>", with: "", options: .regularExpression)
        return processed
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
    <head>
    <style>
    p {
      font-size: 12px;
    }
    </style>
    </head>
    <body>
    """
    
    let htmlTail = """
    </body>
    </html>
    """
}
