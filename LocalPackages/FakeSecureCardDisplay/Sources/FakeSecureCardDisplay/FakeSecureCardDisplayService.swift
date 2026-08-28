import UIKit
import UniformTypeIdentifiers

public actor FakeSecureCardDisplayService: SecureCardDisplayService {
    // Fake PAN "4111111111111111" / PIN "1234", held as raw ASCII bytes —
    // never as a String literal, and never a String at rest. Each accessor
    // converts to String only for the duration of the call.
    private var panBytes: [UInt8]? = [
        0x34, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31,
        0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31, 0x31,
    ]
    private var pinBytes: [UInt8]? = [0x31, 0x32, 0x33, 0x34]

    public init() {}

    public func getCardDataImage() async -> UIImage {
        guard let bytes = panBytes else { return Self.render("WIPED") }
        return Self.render(Self.grouped(String(decoding: bytes, as: UTF8.self)))
    }

    public func getCardPinImage() async -> UIImage {
        guard let bytes = pinBytes else { return Self.render("WIPED") }
        return Self.render(String(decoding: bytes, as: UTF8.self))
    }

    public func copyPanToClipboard() async {
        guard let bytes = panBytes else { return }
        let pan = String(decoding: bytes, as: UTF8.self)
        UIPasteboard.general.setItems(
            [[UTType.utf8PlainText.identifier: pan]],
            options: [.expirationDate: Date().addingTimeInterval(30)]
        )
    }

    public func wipe() async {
        zero(&panBytes)
        zero(&pinBytes)
    }

    private func zero(_ bytes: inout [UInt8]?) {
        bytes?.withUnsafeMutableBufferPointer { buffer in
            for i in buffer.indices { buffer[i] = 0 }
        }
        bytes = nil
    }

    private static func grouped(_ digits: String) -> String {
        digits.enumerated().map { i, c in
            (i > 0 && i.isMultiple(of: 4)) ? " \(c)" : "\(c)"
        }.joined()
    }

    private static func render(_ text: String) -> UIImage {
        let size = CGSize(width: 300, height: 60)
        return UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.black.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            let attributed = NSAttributedString(string: text, attributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 22, weight: .medium),
                .foregroundColor: UIColor.white,
            ])
            let textSize = attributed.size()
            attributed.draw(at: CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            ))
        }
    }
}
