//
//  ProfileViewModel.swift
//  MessengerUIKit2024
//
//  Created by Andrei Harnashevich on 12.09.24.
//

import Foundation

struct ProfileViewModel {
    let viewModelType : ProfileViewModelType
    let title : String
    let handler : (() -> Void)?
}

enum ProfileViewModelType {
    case info , logout
}
