//
//  ProfileTableViewCell.swift
//  MessengerUIKit2024
//
//  Created by Andrei Harnashevich on 12.09.24.
//

import UIKit

class ProfileTableViewCell : UITableViewCell{
    
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel : ProfileViewModel) {
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType{
        case .info:
            self.textLabel?.textAlignment = .left
            self.selectionStyle = .none
        case .logout:
            self.textLabel?.textAlignment = .center
            self.textLabel?.textColor = .red
            
        }
    }
}
