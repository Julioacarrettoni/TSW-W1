import Foundation
import Combine
import UIKit

/// Struct that holds the minimum data that can be rendered on a UITableView using cells with the `UITableViewCell.CellStyle.subtitle` style.
struct Entity {
    let title: String
    let subtitle: String
}

/// Simple UITableView DataSource implementation based on an array of elements that shows cells with the `UITableViewCell.CellStyle.subtitle` style.
final class TableViewHandler: NSObject {
    weak var tableView: UITableView?
    
    let reuseIdentifier = "cell"
    var entities = [Entity]() {
        didSet {
            self.tableView?.reloadData()
            self.reloaded = ()
        }
    }
    
    init(tableView: UITableView) {
        self.tableView = tableView
        super.init()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    @Published var selectedIndex: IndexPath? = nil
    @Published var reloaded: Void = ()
}

/// Very standard and regular code to populate a UITableView based on an array of elements, nothing fancy
extension TableViewHandler: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier) ?? UITableViewCell(style: .value1, reuseIdentifier: self.reuseIdentifier)
        
        cell.textLabel?.text = entities[indexPath.row].title
        cell.detailTextLabel?.text = entities[indexPath.row].subtitle
        
        return cell
    }
}

extension TableViewHandler: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = indexPath
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.selectedIndex = nil
    }
}
