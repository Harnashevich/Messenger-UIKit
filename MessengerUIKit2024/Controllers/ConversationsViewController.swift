//
//  ConversationsViewController.swift
//  MessengerUIKit2024
//
//  Created by Andrei Harnashevich on 5.09.24.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

final class ConversationsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()
    
    private let tableView : UITableView = {
        let table = UITableView(frame: CGRect(), style: .insetGrouped)
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConversationsLabel : UILabel = {
        let label = UILabel()
        label.text = "No Conversations"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21,weight : .medium)
        label.isHidden = true
        return label
    }()
    
    private var loginObserver:NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        view.backgroundColor = .systemBackground
        setupTableView()
        view.addSubviews(tableView, noConversationsLabel)
        startListeningForConversations()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification,object: nil,queue: .main) { [weak self] _  in
            guard let self else {return}
            self.startListeningForConversations()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        validateAuth()
        startListeningForConversations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noConversationsLabel.frame = CGRect(
            x: 10,
            y: (view.height - 100)/2,
            width: view.width - 20,
            height: 100
        )
    }
}

extension ConversationsViewController {
    
    private func startListeningForConversations(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return
        }
        if let observer = loginObserver{
            NotificationCenter.default.removeObserver(observer)
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    self?.tableView.isHidden = true
                    self?.noConversationsLabel.isHidden = false
                    return
                }
                self?.tableView.isHidden = false
                self?.noConversationsLabel.isHidden = true
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("Failed to get convos \(error)")
                self?.tableView.isHidden = true
                self?.noConversationsLabel.isHidden = false
            }
        }
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav,animated: false)
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func createNewConversation(result : SearchResult) {
        let name = result.name
        let email = DatabaseManager.safeEmail(emailAddress: result.email)
        
        DatabaseManager.shared.conversationExists(with: email) { [weak self] result in
            guard let self else{ return }
            switch result {
            case .success(let conversationId):
                let vc = ChatViewController(with: email,id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
            case .failure(let error):
                print("error occured due to \(error)")
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationsViewController()
        
        vc.completion = { [weak self] result in
            guard let self else { return }
            let currentConversations = self.conversations
            
            if let targetConversation = currentConversations.first(where:{
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }){
                let vc = ChatViewController(with: targetConversation.otherUserEmail,id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                self.createNewConversation(result: result)
            }
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC,animated: true)
    }
}

extension ConversationsViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        let model = conversations[indexPath.row]
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = conversations[indexPath.row]
        
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title =  model.otherUserEmail
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let conversationId = conversations[indexPath.row].id
            tableView.beginUpdates()
            conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            
            DatabaseManager.shared.deleteConversation(conversationId: conversationId) { success in
                if !success {
                    print("failed to delete")
                }
            }
            tableView.endUpdates()
        }
    }
}
