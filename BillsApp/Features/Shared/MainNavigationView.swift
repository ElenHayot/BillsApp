//
//  MainNavigationView.swift
//  BillsApp
//
//  Created by Elen Hayot on 29/01/2026.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Main Navigation View
 
struct MainNavigationView: View {
    @Binding var navigationPath: NavigationPath
 
    var body: some View {
        NavigationStack(path: $navigationPath) {
            
            DashboardView(navigationPath: $navigationPath)
            .toolbar {
                ToolbarItem(placement: toolbarPlacement) {
                    SettingsMenuView()
                }
            }
            .navigationDestination(for: DashboardCategoryStats.self) { category in
                BillsListView(
                    categoryId: category.categoryId,
                    categoryName: category.categoryName,
                    categoryColor: category.categoryColor,
                    year: Calendar.current.component(.year, from: Date())
                )
                .toolbar {
                    ToolbarItem(placement: toolbarPlacement) {
                        SettingsMenuView()
                    }
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                Group {
//                    if destination == "categories" {
//                        CategoriesListView()
//                    } else if destination == "all-bills" {
//                        AllBillsListView(year: Calendar.current.component(.year, from: Date()))
//                    } else if destination == "providers" {
//                        ProvidersListView()
//                    }
                    switch destination {
                        case .categories(let year):
                            CategoriesListView(year: year)
                        case .allBills(let year):
                            AllBillsListView(year: year)
                        case .providers(let year):
                            ProvidersListView(year: year)
                        case .category(let categoryStats, let year):
                            BillsListView(
                                categoryId: categoryStats.categoryId,
                                categoryName: categoryStats.categoryName,
                                categoryColor: categoryStats.categoryColor,
                                year: year
                        )
                    }
                }
                .toolbar {
                    ToolbarItem(placement: toolbarPlacement) {
                        SettingsMenuView()
                    }
                }
            }
        }
    }
}

var toolbarPlacement: ToolbarItemPlacement {
    #if os(iOS)
    .navigationBarTrailing
    #else
    .primaryAction
    #endif
}
