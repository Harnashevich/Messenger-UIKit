//
//  PhotoViewerViewController.swift
//  MessengerUIKit2024
//
//  Created by Andrei Harnashevich on 5.09.24.
//

import UIKit
import SDWebImage

final class PhotoViewerViewController: UIViewController {
    
    private let url: URL
    
    init(with url : URL){
        self.url = url
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .black
        view.addSubview(imageView)
        self.imageView.sd_setImage(with: self.url, completed: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
    }
}
