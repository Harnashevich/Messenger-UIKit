//
//  ChatViewController.swift
//  MessengerUIKit2024
//
//  Created by Andrei Harnashevich on 6.09.24.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation

final class ChatViewController: MessagesViewController {
    
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    
    public static let dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false
    public let otherUserEmail: String
    private var conversationId: String?
    
    private var messages = [Message]()
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        return Sender(senderId: safeEmail, displayName: "Me", photoURL: "")
    }
    
    init(with email: String, id: String?){
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemPink
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setUpInputButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom : true)
        }
    }
    
    private func listenForMessages(id : String, shouldScrollToBottom : Bool){
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] result in
            switch result{
            case .success(let messages):
                print("success case")
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                print("found the messages")
                print(messages)
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom{
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let error):
                print("Error while finding messages \(error)")
            }
        }
    }
    
    private func setUpInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside{ [weak self] _ in
            self?.presentInputAction()
            
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    func presentInputAction(){
        let actionsheet = UIAlertController(title: "Attach media", message: "What would you like to attach", preferredStyle: .actionSheet)
        
        actionsheet.addAction(UIAlertAction(title: "Photo", style: .default) { [weak self] _ in
            self?.photoInputActionsheet()
        })
        
        actionsheet.addAction(UIAlertAction(title: "Video", style: .default) { [weak self] _ in
            self?.videoInputActionsheet()
            
        })
        
        actionsheet.addAction(UIAlertAction(title: "Location", style: .default) { [weak self] _ in
            self?.presentLocationPicker()
        })
        
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionsheet,animated: true)
    }
    
    private func photoInputActionsheet() {
        let actionsheet = UIAlertController(title: "Attach photo", message: "From where would you like to attach photo from ?", preferredStyle: .actionSheet)
        
        actionsheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker,animated: true)
        }))
        
        actionsheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker,animated: true)
        }))
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionsheet,animated: true)
    }
    
    private func presentLocationPicker(){
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        
        vc.completion = {[weak self] selectedCoordinates in
            guard
                let self,
                let conversationId = self.conversationId,
                let name = self.title,
                let selfSender,
                let messageId = createMessageId()
            else {
                return
            }
            
            let longitude:Double = selectedCoordinates.longitude
            let lattitude:Double = selectedCoordinates.latitude
            
            let location = Location(location: CLLocation(latitude: lattitude, longitude: longitude), size: .zero)
            let message = Message(
                sender: selfSender,
                messageId: messageId,
                sentDate: Date(),
                kind: .location(location)
            )
            
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { success in
                if success{
                    print("sent location message")
                }
                else {
                    print("could not send location message")
                }
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func videoInputActionsheet(){
        let actionsheet = UIAlertController(title: "Attach Video", message: "From where would you like to attach Video from ?", preferredStyle: .actionSheet)
        
        actionsheet.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker,animated: true)
        })
        
        actionsheet.addAction(UIAlertAction(title: "Library", style: .default) { [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker,animated: true)
        })
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionsheet,animated: true)
    }
    
    private func createMessageId() -> String? {
        //date , otherUserEmail , SenderMail , randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newId = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        return newId
    }
}

extension ChatViewController : InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }
        
        let message = Message(
            sender: selfSender,
            messageId: messageId,
            sentDate: Date(),
            kind: .text(text)
        )
        
        inputBar.inputTextView.text = ""
        
        if isNewConversation{
            //create Convo in db
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message) { [weak self] success in
                guard let self else { return }
                if success{
                    print("message sent")
                    self.isNewConversation = false
                    let newConversationId = "conversation_\(message.messageId)"
                    self.conversationId = newConversationId
                    self.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                    self.messageInputBar.inputTextView.text = nil
                } else{
                    print("failed to send")
                }
            }
        }
        else {
            guard let conversationId = conversationId, let name = self.title else { return }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail : otherUserEmail , name: name, newMessage: message) { [weak self] success in
                if success{
                    self?.messageInputBar.inputTextView.text = nil
                    print("message sent")
                }
                else{
                    print("failed to send message")
                }
            }
        }
    }
}

extension ChatViewController:  MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        if let sender = selfSender{
            return sender
        }
        fatalError("self sender is nil email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind{
        case .photo(let media):
            
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            return .link
        }
        
        return .secondarySystemBackground
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        
        if sender.senderId == selfSender?.senderId {
            if let currentUserImageURL = self.senderPhotoURL {
                avatarView.sd_setImage(with: currentUserImageURL)
            } else {
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return }
                
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.senderPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
        else {
            if let otherUserPhotoURL = self.otherUserPhotoURL {
                avatarView.sd_setImage(with: otherUserPhotoURL)
            } else {
                let email = otherUserEmail
                
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.otherUserPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard
            let conversationId = conversationId,
            let name = self.title,
            let selfSender = self.selfSender,
            let messageId = createMessageId()
        else {
            return
        }
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage ,let imageData = image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let urlString):
                    //ready to send message
                    print("Uploaded message photo \(urlString)")
                    guard
                        let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus")
                    else {
                        return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    let message = Message(
                        sender: selfSender,
                        messageId: messageId,
                        sentDate: Date(),
                        kind: .photo(media)
                    )
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { success in
                        if success{
                            print("sent photo message")
                        }
                        else{
                            print("could not send photo message")
                        }
                    }
                case .failure(let error):
                    print("message photo upload error \(error)")
                }
            }
        }
        else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "photo_message_"+messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            //upload video
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName) { [weak self] result in
                guard let self else { return }
                switch result{
                case .success(let urlString):
                    //ready to send message
                    print("Uploaded message Video \(urlString)")
                    guard
                        let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus")
                    else {
                        return
                    }
                    let media = Media(
                        url: url,
                        image: nil,
                        placeholderImage: placeholder,
                        size: .zero
                    )
                    
                    let message = Message(
                        sender: selfSender,
                        messageId: messageId,
                        sentDate: Date(),
                        kind: .video(media)
                    )
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { success in
                        if success{
                            print("sent Video message")
                        }
                        else{
                            print("could not send video message")
                        }
                    }
                case .failure(let error):
                    print("message photo upload error \(error)")
                }
            }
        }
    }
}

extension ChatViewController: MessageCellDelegate{
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind{
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.title = "Location"
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind{
        case .photo(let media):
            guard let imageUrl = media.url else { return }
            let vc = PhotoViewerViewController(with: imageUrl)
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else { return }
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc,animated: true)
        default:
            break
        }
    }
}
