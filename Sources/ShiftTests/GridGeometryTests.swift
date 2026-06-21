import CoreGraphics
@testable import ShiftKit

func runGridGeometryTests() {
    R.suite("GridGeometry")

    let vf = CGRect(x: 0, y: 0, width: 2400, height: 1200)  // each cell = 100x100
    func frame(_ x: Int, _ y: Int, _ w: Int, _ h: Int,
               in visible: CGRect? = nil, gap: CGFloat = 0, screenGap: CGFloat = 0) -> CGRect {
        GridGeometry.frame(for: CellRect(x: x, y: y, w: w, h: h),
                           in: visible ?? vf, columns: 24, rows: 12, gap: gap, screenGap: screenGap)
    }

    R.equal(frame(0, 0, 12, 12), CGRect(x: 0, y: 0, width: 1200, height: 1200), "left half")
    R.equal(frame(12, 0, 12, 12), CGRect(x: 1200, y: 0, width: 1200, height: 1200), "right half")

    // Top of screen (row 0) → HIGH y in AppKit coords.
    R.equal(frame(0, 0, 24, 6), CGRect(x: 0, y: 600, width: 2400, height: 600), "top half is upper")
    R.equal(frame(0, 6, 24, 6), CGRect(x: 0, y: 0, width: 2400, height: 600), "bottom half is lower")

    // Quarters tile exactly.
    let tl = frame(0, 0, 12, 6), tr = frame(12, 0, 12, 6)
    let bl = frame(0, 6, 12, 6), br = frame(12, 6, 12, 6)
    R.equal(tl.width + tr.width, vf.width, "quarters cover width")
    R.equal(bl.height + tl.height, vf.height, "quarters cover height")
    R.ok(tl.maxX == tr.minX, "no horizontal gap between quarters")
    R.ok(bl.maxY == tl.minY, "no vertical gap between quarters")
    R.ok(tr.minX == br.minX, "right quarters aligned")

    // Thirds.
    let l = frame(0, 0, 8, 12), c = frame(8, 0, 8, 12), r = frame(16, 0, 8, 12)
    R.equal(l.width + c.width + r.width, vf.width, "thirds cover width")
    R.ok(l.maxX == c.minX && c.maxX == r.minX, "thirds tile with no gaps")

    R.equal(frame(0, 0, 24, 12), vf, "maximize cell fills visible frame")

    // Non-integral width still tiles with no gaps.
    let odd = CGRect(x: 0, y: 0, width: 2401, height: 1200)
    let oLeft = frame(0, 0, 12, 12, in: odd), oRight = frame(12, 0, 12, 12, in: odd)
    R.ok(oLeft.maxX == oRight.minX, "odd width: halves touch")
    R.equal(oLeft.width + oRight.width, odd.width, "odd width: full coverage")

    // Offset visible frame (menu bar / Dock insets).
    let inset = CGRect(x: 100, y: 50, width: 2400, height: 1100)
    R.equal(frame(0, 0, 24, 12, in: inset), inset, "offset frame respects origin")

    // Gaps and outer margin.
    R.equal(frame(0, 0, 12, 12, gap: 20),
            CGRect(x: 0, y: 0, width: 1200, height: 1200).insetBy(dx: 10, dy: 10), "gap insets each window")
    R.equal(frame(0, 0, 24, 12, screenGap: 10), vf.insetBy(dx: 10, dy: 10), "screen_gap adds outer margin")

    // Defensive clamping.
    let clamped = frame(20, 0, 12, 12)
    R.ok(clamped.maxX <= vf.maxX + 0.5 && clamped.minX >= vf.minX - 0.5, "out-of-bounds cell clamps inside grid")
}
