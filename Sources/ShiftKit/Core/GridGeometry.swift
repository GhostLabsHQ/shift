import Cocoa

/// Pure geometry: maps a `CellRect` to an AppKit-coordinate frame (bottom-left
/// origin, screen-local) within a visible frame. No window APIs are touched here,
/// so this is fully unit-testable.
///
/// The grid uses a TOP-LEFT origin (row 0 = top). Each grid *line* is rounded to
/// a whole pixel and frames are derived from the differences, so adjacent cells
/// tile perfectly with no gaps or overlaps.
enum GridGeometry {
    static func frame(for cell: CellRect,
                      in visibleFrame: CGRect,
                      columns: Int,
                      rows: Int,
                      gap: CGFloat = 0,
                      screenGap: CGFloat = 0) -> CGRect {
        let cols = max(1, columns)
        let rws = max(1, rows)

        // Outer margin first, then divide what's left into cells.
        let vf = screenGap > 0 ? visibleFrame.insetBy(dx: screenGap, dy: screenGap) : visibleFrame

        // Clamp the cell into the grid defensively (bad config shouldn't crash).
        let cx = clamp(cell.x, lo: 0, hi: cols - 1)
        let cy = clamp(cell.y, lo: 0, hi: rws - 1)
        let cw = clamp(cell.w, lo: 1, hi: cols - cx)
        let ch = clamp(cell.h, lo: 1, hi: rws - cy)

        let cellW = vf.width / CGFloat(cols)
        let cellH = vf.height / CGFloat(rws)

        let left   = vf.minX + (cellW * CGFloat(cx)).rounded()
        let right  = vf.minX + (cellW * CGFloat(cx + cw)).rounded()
        // y is measured from the top; AppKit's top edge is maxY.
        let top    = vf.maxY - (cellH * CGFloat(cy)).rounded()
        let bottom = vf.maxY - (cellH * CGFloat(cy + ch)).rounded()

        var rect = CGRect(x: left, y: bottom, width: right - left, height: top - bottom)
        if gap > 0 {
            rect = rect.insetBy(dx: gap / 2, dy: gap / 2)
        }
        return rect
    }

    /// Convenience overload using an `NSScreen` and `GridSettings`.
    static func frame(for cell: CellRect, on screen: NSScreen, settings: GridSettings) -> CGRect {
        frame(for: cell,
              in: screen.visibleFrame,
              columns: settings.columns,
              rows: settings.rows,
              gap: settings.gap,
              screenGap: settings.screenGap)
    }

    private static func clamp(_ v: Int, lo: Int, hi: Int) -> Int {
        max(lo, min(max(lo, hi), v))
    }
}
