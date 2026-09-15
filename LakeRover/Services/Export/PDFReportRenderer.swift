import CoreGraphics
import Foundation
import SwiftUI

/// Renders `ReportPage` to a one-page A4 PDF with `ImageRenderer`.
@MainActor
enum PDFReportRenderer {
    static func render(_ data: ReportData) -> URL? {
        let renderer = ImageRenderer(content: ReportPage(data: data))
        renderer.proposedSize = ProposedViewSize(ReportPage.size)

        let safeName = data.lakeName
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LakeRover-Laporan-\(safeName).pdf")

        var box = CGRect(origin: .zero, size: ReportPage.size)
        guard let consumer = CGDataConsumer(url: url as CFURL),
              let context = CGContext(consumer: consumer, mediaBox: &box, nil)
        else { return nil }

        renderer.render { size, renderInContext in
            context.beginPDFPage(nil)
            // Centre the rendered content on the page if the sizes differ slightly.
            context.translateBy(
                x: (box.width - size.width) / 2,
                y: (box.height - size.height) / 2
            )
            renderInContext(context)
            context.endPDFPage()
        }
        context.closePDF()
        return url
    }
}
