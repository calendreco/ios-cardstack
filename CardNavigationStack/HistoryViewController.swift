//
//  HistoryViewController.swift
//  CardNavigationStack
//
//  Created by Stephen Silber on 6/22/17.
//  Copyright © 2017 calendre. All rights reserved.
//

import Foundation
import UIKit

public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

protocol HistoryViewDelegate: class {
    func historyView(_ viewController: HistoryViewController, didSelectCard card: CardViewController)
    func historyViewDidClearHistory(_ viewController: HistoryViewController)
}

class HistoryViewController: UITableViewController {
    weak var delegate: HistoryViewDelegate?
    
    var colors: [UIColor] = []
    
    var cards: [CardViewController] = []
    
    init(cards: [CardViewController]) {
        self.cards = cards.reversed()
        super.init(style: .plain)
        
        colors = cards.flatMap {
            return $0.child.scrollView.backgroundColor
        }.reversed()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.contentInset.top = 30
        tableView.separatorStyle = .none
        tableView.rowHeight = 60
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if indexPath.row == colors.count {
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.text = "Clear History"
        } else {
            let color = colors[indexPath.row]
            cell.textLabel?.text = "Card \(indexPath.row)".uppercased()
            cell.imageView?.image = UIImage(color: color, size: CGSize(width: 30, height: 30))
        }
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "HISTORY"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colors.count + 1
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y < -40 {
            dismiss(animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == colors.count {
            colors.removeAll()
            cards.removeAll()
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            delegate?.historyViewDidClearHistory(self)
        } else {
            let card = cards[indexPath.row]
            delegate?.historyView(self, didSelectCard: card)
        }
    }
}
