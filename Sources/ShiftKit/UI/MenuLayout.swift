import Foundation

/// One section of the menu bar: a category that becomes a submenu (or, when
/// `title` is empty, loose top-level items for an uncategorized config).
/// Pure data so the menu structure is unit-testable without AppKit.
struct MenuSection: Equatable {
    let title: String              // category name; "" = uncategorized (rendered inline)
    let positionIndices: [Int]     // indices into the flat positions array
    let separatorBefore: Bool      // draw a divider before this section
}

enum MenuLayout {
    /// Groups positions by `category` (preserving first-appearance order) and
    /// decides separators: a section is set apart when it — or the section just
    /// before it — only throws windows between displays. So layout categories
    /// (Basic, Custom, …) cluster, while "Displays" stands on its own.
    static func sections(for positions: [Position]) -> [MenuSection] {
        var order: [String] = []
        var groups: [String: [Int]] = [:]
        for (index, position) in positions.enumerated() {
            let key = position.category ?? ""
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(index)
        }

        func isDisplayOnly(_ indices: [Int]) -> Bool {
            indices.allSatisfy { positions[$0].kind == .nextDisplay || positions[$0].kind == .previousDisplay }
        }

        return order.enumerated().map { i, key in
            let indices = groups[key]!
            var separator = false
            if i > 0 {
                separator = isDisplayOnly(indices) || isDisplayOnly(groups[order[i - 1]]!)
            }
            return MenuSection(title: key, positionIndices: indices, separatorBefore: separator)
        }
    }
}
