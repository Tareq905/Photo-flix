
import SwiftUI
import Combine

extension UIView {
    func copyView<T: UIView>() -> T {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as! T
    }
}

extension CALayer {
    var copied: CALayer {
        NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as! CALayer
    }
}

extension Color {
    /// Main background color
    static let dark = Color(red: 35/255, green: 34/255, blue: 35/255)
    
    /// Main foreground color
    static let light = Color(red: 244/255, green: 244/255, blue: 244/255)
    
    /// Color used for views background which is differ from main background
    static let darkHighlight = Color(red: 44/255, green: 44/255, blue: 44/255)
    
    static let permissionsBackground = Color(red: 29/255, green: 28/255, blue: 30/255)
}

extension UIColor {
    /// Main background color
    static let dark = UIColor(red: 35/255, green: 34/255, blue: 35/255, alpha: 1.0)
    
    /// Main foreground color
    static let light = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1.0)
}


import PencilKit

extension PKCanvasView {
    /// Append shape and register undo action
    func drawShape(_ shape: DrawingShape) {
        let bounds = CGRect(x: bounds.width/3, y: bounds.height/3, width: bounds.width/3, height: bounds.width/3)
        
        let drawing = PKDrawing(with: shape, in: bounds, tool: tool as? PKInkingTool)
        let original = self.drawing
        
        undoManager?.registerUndo(withTarget: self, handler: {
            $0.drawing = original
        })
        self.drawing.append(drawing)
        
        undoManager?.setActionName("Undo adding \(shape.rawValue)")
    }
}
