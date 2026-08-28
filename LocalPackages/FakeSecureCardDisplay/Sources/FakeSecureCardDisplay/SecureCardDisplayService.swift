import UIKit

/// Stand-in for a proprietary native card-display SDK (e.g. IDEMIA's
/// CardSecureDisplay): the full PAN/PIN never crosses this boundary as a
/// `String` — callers only ever receive a rendered `UIImage`.
public protocol SecureCardDisplayService: Sendable {
    func getCardDataImage() async -> UIImage
    func getCardPinImage() async -> UIImage
    func copyPanToClipboard() async
    /// Zeroes the in-memory plaintext buffers. Call on backgrounding.
    func wipe() async
}
