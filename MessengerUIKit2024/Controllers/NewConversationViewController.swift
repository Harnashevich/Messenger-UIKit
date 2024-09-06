//
//  NewConversationViewController.swift
//  MessengerUIKit2024
//
//  Created by Andrei Harnashevich on 5.09.24.
//

import UIKit

class NewConversationViewController: UIViewController {
    
    private let searchBar : UISearchBar = {
        let searchBar = UISearchBar()
        
        searchBar.placeholder = "Search for users"
        return searchBar
    }()
    
    private let tableView : UITableView = {
       let table = UITableView()
        table.isHidden = true
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        return table
    }()
    
    private let noResultsLabel : UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No results"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubviews(noResultsLabel, tableView)
//        tableView.delegate = self
//        tableView.dataSource = self
        searchBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "cancel", style: .done, target: self, action: #selector(dismissSelf))

        searchBar.becomeFirstResponder()
    }
}

extension NewConversationViewController {
    
    @objc private func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }
}
 
extension NewConversationViewController : UISearchBarDelegate{
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    }
}

//extension NewConversationViewController:  UITableViewDelegate,UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return results.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let model = results[indexPath.row]
//        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
//        cell.configure(with: model)
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//        //start convo here
//        
//        let targetUserData = results[indexPath.row]
//        dismiss(animated: true) { [weak self] in
//            self?.completion?(targetUserData)
//        }
//    }
//    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 90
//    }
//}
