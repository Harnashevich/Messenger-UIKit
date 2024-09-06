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

class ChatViewController: MessagesViewController {
    
    private var messages = [Message]()
    private var selfSender = Sender(
        senderId: "1",
        displayName: "Andrei Harnashevich",
        photoURL: ""
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello world")
            )
        )
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello world Hello world Hello world Hello world")
            )
        )
        
        view.backgroundColor = .systemPink
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
//        messagesCollectionView.messageCellDelegate = self
//        messageInputBar.delegate = self
    }
}

extension ChatViewController:  MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> MessageKit.SenderType {
        self.selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        messages.count
    }
}
