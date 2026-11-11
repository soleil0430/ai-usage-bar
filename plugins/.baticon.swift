// 사용법: .baticon [--white] <라벨> <값> [<라벨> <값> ...]  → 나란히 그린 PNG를 base64로 출력
//   라벨: "/"로 시작하면 그 앱의 아이콘, SF Symbols 이름이면 그 아이콘, 그 외는 글자 그대로
//   값:   0~100이면 배터리(안에 숫자), "?"면 빈 배터리에 ?, "-"면 배터리 없이 라벨만, 그 외는 라벨 뒤에 글자 그대로(예: clock 2분)
//   예:   .baticon /Applications/Claude.app - clock 77 calendar 57
// 빌드: swiftc -O .baticon.swift -o .baticon
import AppKit

var args = Array(CommandLine.arguments.dropFirst())
// 컬러 앱 아이콘 때문에 템플릿 이미지를 못 쓰므로, 다크 모드용 흰색은 호출자가 지정한다
let ink: NSColor = args.first == "--white" ? .white : .black
if args.first == "--white" { args.removeFirst() }
precondition(!args.isEmpty && args.count % 2 == 0, "usage: baticon [--white] <label> <value> ...")

let H: CGFloat = 16, bw: CGFloat = 26, bh: CGFloat = 13, gap: CGFloat = 8, appSize: CGFloat = 15
let labelAttr: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10, weight: .medium), .foregroundColor: ink]
let numAttr: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: ink]
let symCfg = NSImage.SymbolConfiguration(pointSize: 11.5, weight: .medium)
    .applying(NSImage.SymbolConfiguration(paletteColors: [ink]))

struct Item {
    let labelSize: NSSize
    let drawLabel: (NSPoint) -> Void
    let value: String  // "0"..."100", "?", "-", 그 외 글자
    var hasBattery: Bool { value == "?" || Int(value) != nil }
    var hasText: Bool { value != "-" && !hasBattery }
    var textWidth: CGFloat { ceil((value as NSString).size(withAttributes: numAttr).width) }
    var width: CGFloat { ceil(labelSize.width) + (hasBattery ? 3 + bw + 3 : 0) + (hasText ? 2 + textWidth : 0) }
}

func makeItem(_ label: String, _ value: String) -> Item {
    if label.hasPrefix("/") {
        let img = NSWorkspace.shared.icon(forFile: label)
        let size = NSSize(width: appSize, height: appSize)
        return Item(labelSize: size, drawLabel: { img.draw(in: NSRect(origin: $0, size: size)) }, value: value)
    }
    if let img = NSImage(systemSymbolName: label, accessibilityDescription: nil)?.withSymbolConfiguration(symCfg) {
        return Item(labelSize: img.size, drawLabel: { img.draw(in: NSRect(origin: $0, size: img.size)) }, value: value)
    }
    let s = label as NSString
    return Item(labelSize: s.size(withAttributes: labelAttr), drawLabel: { s.draw(at: $0, withAttributes: labelAttr) }, value: value)
}

var items: [Item] = []
for i in stride(from: 0, to: args.count, by: 2) { items.append(makeItem(args[i], args[i + 1])) }
// 배터리 없는 라벨(서비스 아이콘) 뒤에는 간격을 좁혀 뒤따르는 배터리와 한 묶음으로 보이게 한다
func gapAfter(_ it: Item) -> CGFloat { it.value == "-" ? 4 : gap }
var W: CGFloat = 0
for it in items { W += it.width + gapAfter(it) }
W = ceil(W - gapAfter(items[items.count - 1]))

// 레티나용 2배 픽셀, 크기는 포인트로 지정
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W * 2), pixelsHigh: Int(H * 2), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
rep.size = NSSize(width: W, height: H)
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

var x: CGFloat = 0
for it in items {
    it.drawLabel(NSPoint(x: x, y: (H - it.labelSize.height) / 2))
    if it.hasBattery {
        let bx = x + ceil(it.labelSize.width) + 3
        let body = NSRect(x: bx + 0.5, y: (H - bh) / 2 + 0.5, width: bw - 1, height: bh - 1)
        ink.withAlphaComponent(0.55).setStroke()
        NSBezierPath(roundedRect: body, xRadius: 3.5, yRadius: 3.5).stroke()
        ink.withAlphaComponent(0.55).setFill()
        NSBezierPath(roundedRect: NSRect(x: bx + bw + 0.5, y: H / 2 - 2, width: 1.5, height: 4), xRadius: 0.75, yRadius: 0.75).fill()
        var text = "?"
        if let pct = Int(it.value) {
            let p = max(0, min(100, pct))
            text = "\(p)"
            let inner = body.insetBy(dx: 1.5, dy: 1.5)
            let fill = NSRect(x: inner.minX, y: inner.minY, width: inner.width * CGFloat(p) / 100, height: inner.height)
            ink.withAlphaComponent(0.3).setFill()
            NSBezierPath(roundedRect: fill, xRadius: 2, yRadius: 2).fill()
        }
        let n = text as NSString, ns = n.size(withAttributes: numAttr)
        n.draw(at: NSPoint(x: body.midX - ns.width / 2, y: (H - ns.height) / 2), withAttributes: numAttr)
    }
    if it.hasText {
        let t = it.value as NSString, ts = t.size(withAttributes: numAttr)
        t.draw(at: NSPoint(x: x + ceil(it.labelSize.width) + 2, y: (H - ts.height) / 2), withAttributes: numAttr)
    }
    x += it.width + gapAfter(it)
}
print(rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:])!.base64EncodedString())
