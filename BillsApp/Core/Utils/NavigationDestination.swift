//
//  NavigationDestination.swift
//  BillsApp
//
//  Created by Elen Hayot on 03/02/2026.
//

import Foundation

enum NavigationDestination: Hashable {
    case categories(year: Int)
    case allBills(year: Int)
    case providers(year: Int)
    case category(DashboardCategoryStats, year: Int)
}
