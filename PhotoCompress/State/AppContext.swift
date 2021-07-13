//
//  AppContext.swift
//  PhotoCompress
//
//  Created by Cirno MainasuK on 2021-7-12.
//  Copyright © 2021 MainasuK. All rights reserved.
//

import Foundation
import Combine

class AppContext: ObservableObject {

    @Published private(set) var photoService = PhotoService()

    // MARK: - Singleton
    public static let shared = AppContext()

    private init() { }

}
