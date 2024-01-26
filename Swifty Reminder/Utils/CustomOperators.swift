//
//  CustomOperators.swift
//  Swifty Reminder
//
//  Created by Aman Bind on 20/09/23.
//

import Foundation
import SwiftUI

public func ?? <T>(lhs: Binding<T?>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
