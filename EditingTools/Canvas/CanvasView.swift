

import SwiftUI
import PencilKit

@available(iOS 14.0, *)
struct CanvasView<T: PKCanvasView>: UIViewControllerRepresentable {
    typealias UIViewControllerType = CanvasViewController<T>
    
    /// PKCanvasView object
    @Binding var canvas: T
    
    /// Canvas drawing changed
    var onChanged: ((PKDrawing) -> Void)?
    
    /// Selected subview changed
    var onSelectionChanged: ((UIView?) -> Void)?
    
    /// Set as main responder for UIWindow
    var shouldBecameFirstResponder: Bool = true
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        CanvasViewController(
            canvas: canvas,
            onChanged: onChanged,
            onSelectionChanged: onSelectionChanged,
            shouldBecameFirstResponder: shouldBecameFirstResponder
        )
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}

@available(iOS 14.0, *)
struct CanvasView_Previews: PreviewProvider {
    @State static private var canvas = PKCanvasView()

    static var previews: some View {
        CanvasView(canvas: $canvas, onChanged: { drawing in
            print("Drawing changed")
        })
    }
}

