//
//  MenuScan.swift
//  MenuSnap
//
//  Created by Eric Stimmel on 1/10/26.
//

import Foundation
import SwiftData
import UIKit

@Model
class MenuScan {
    var id: UUID
    var restaurantName: String
    var scanDate: Date
    @Attribute(.externalStorage) var imageData: Data?
    var menuItemsJSON: Data?

    init(restaurantName: String, image: UIImage, menuItems: [MenuItem]) {
        self.id = UUID()
        self.restaurantName = restaurantName
        self.scanDate = Date()
        self.imageData = image.jpegData(compressionQuality: 0.7)
        self.menuItemsJSON = try? JSONEncoder().encode(menuItems)
    }

    var menuItems: [MenuItem] {
        guard let data = menuItemsJSON else { return [] }
        return (try? JSONDecoder().decode([MenuItem].self, from: data)) ?? []
    }

    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }

    var formattedDate: String {
        scanDate.formatted(date: .abbreviated, time: .shortened)
    }
}
