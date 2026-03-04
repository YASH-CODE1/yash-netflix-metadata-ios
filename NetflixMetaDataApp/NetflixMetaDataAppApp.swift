//
//  NetflixMetaDataAppApp.swift
//  NetflixMetaDataApp
//
//  Created by Yash sharma on 12/02/26.
//

import SwiftUI
import CoreData

@main
struct NetflixMetaDataAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

