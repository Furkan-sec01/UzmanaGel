import SwiftUI
import PDFKit

struct Kvkk: View {

    @Binding var hasRead: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var reachedLastPage = false

    private let pdfName = "kvkk"

    var body: some View {
        VStack(spacing: 12) {

            Text("KVKK / Gizlilik Politikası")
                .font(.headline)
                .padding(.top, 8)

            PDFKitView(pdfName: pdfName, reachedLastPage: $reachedLastPage)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

            Button {
                // burada true dönüyor
                hasRead = true
                dismiss()
            } label: {
                Text("Okudum ve Kabul Ediyorum")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(reachedLastPage ? Color.blue : Color.gray)
                    .cornerRadius(14)
                    .padding(.horizontal)
            }
            .disabled(!reachedLastPage)

            
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)

        //son sayfaya gelmeden sheet kapanmasın (aşağı çekme / X vs.)
        .interactiveDismissDisabled(!reachedLastPage)
    }
}

private struct PDFKitView: UIViewRepresentable {

    let pdfName: String
    @Binding var reachedLastPage: Bool

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true)

        if let url = Bundle.main.url(forResource: pdfName, withExtension: "pdf"),
           let document = PDFDocument(url: url) {
            pdfView.document = document
        } else {
            print("❌ PDF bulunamadı: \(pdfName).pdf (Target Membership kontrol et)")
        }

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: Notification.Name.PDFViewPageChanged,
            object: pdfView
        )

        // ilk açılış kontrolü (tek sayfa pdf ise hemen last sayfa sayılabilir)
        DispatchQueue.main.async {
            context.coordinator.updateReachedLastPage(for: pdfView)
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(reachedLastPage: $reachedLastPage)
    }

    final class Coordinator: NSObject {
        @Binding var reachedLastPage: Bool

        init(reachedLastPage: Binding<Bool>) {
            _reachedLastPage = reachedLastPage
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView else { return }
            updateReachedLastPage(for: pdfView)
        }

        func updateReachedLastPage(for pdfView: PDFView) {
            guard let doc = pdfView.document,
                  let current = pdfView.currentPage,
                  doc.pageCount > 0
            else { return }

            let last = doc.page(at: doc.pageCount - 1)
            reachedLastPage = (current == last)
        }
    }
}
