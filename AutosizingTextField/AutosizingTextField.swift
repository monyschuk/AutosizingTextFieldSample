//
//  AutosizingTextField.swift
//  Matrix
//
//  Created by Mark Onyschuk on 2014-06-14.
//  Copyright (c) 2014 Mark Onyschuk. All rights reserved.
//

import Cocoa

class AutosizingTextField: NSTextField {

    @IBInspectable var multiline: Bool = false {
    didSet {
        let cell = self.cell() as NSTextFieldCell
        
        cell.wraps      = multiline
        cell.scrollable = !multiline
    }}
    
    // Lifecycle
    
    init(frame: NSRect) {
        super.init(frame: frame)
        self.prepareAutosizingTextField()
    }

    init(coder: NSCoder!)  {
        super.init(coder: coder)
        self.prepareAutosizingTextField()
    }
    
    func prepareAutosizingTextField() {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let cell = self.cell() as NSTextFieldCell
        
        cell.wraps          = multiline
        cell.scrollable     = !multiline

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "geometryDidChange:", name: NSViewFrameDidChangeNotification, object: self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "geometryDidChange:", name: NSViewBoundsDidChangeNotification, object: self)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSViewFrameDidChangeNotification, object: self)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSViewBoundsDidChangeNotification, object: self)
    }

    // Autolayout
    
    func geometryDidChange(_: NSNotification!) {
        if multiline {
            self.preferredMaxLayoutWidth = NSWidth(self.bounds)
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override func textDidChange(notification: NSNotification!)  {
        super.textDidChange(notification)
        
        self.invalidateIntrinsicContentSize()
    }
    
    override var intrinsicContentSize: NSSize {
    get {
        var size: NSSize
        let bounds = self.bounds

        if let fieldEditor = self.currentEditor() as? NSTextView {
            
            if multiline {
                // the field editor may scroll slightly during edits
                // regardless of whether we specify the cell to be scrollable:
                // as a result, we fix the field editor's width prior to calculating height
                
                let superview   = fieldEditor.superview as NSView
                let superBounds = superview.bounds
                
                var frame       = fieldEditor.frame
                
                if NSWidth(frame) > NSWidth(superBounds) {
                    frame.size.width = NSWidth(superBounds)
                    
                    fieldEditor.frame = frame
                }
            }
            
            let textContainer = fieldEditor.textContainer
            let layoutManager = fieldEditor.layoutManager
            
            let usedRect    = layoutManager.usedRectForTextContainer(textContainer)
            let clipRect    = self.convertRect(fieldEditor.superview.bounds, fromView: fieldEditor.superview)
            
            let clipDelta   = NSSize(width: NSWidth(bounds) - NSWidth(clipRect), height:NSHeight(bounds) - NSHeight(clipRect))
            
            if multiline {
                let minHeight = layoutManager.defaultLineHeightForFont(self.font)
                
                size = NSSize(width: NSViewNoInstrinsicMetric, height: max(NSHeight(usedRect), minHeight) + clipDelta.height)
                
            } else {
                size = NSSize(width: ceil(NSWidth(usedRect) + clipDelta.width), height: NSHeight(usedRect) + clipDelta.height)
            }
            
        } else {
            let cell = self.cell() as NSTextFieldCell
            
            if multiline {
                // oddly, this sometimes gives incorrect results - 
                // if anyone has any ideas please issue a pull request
                
                size = cell.cellSizeForBounds(NSMakeRect(0, 0, NSWidth(bounds), CGFLOAT_MAX))
                
                size.width  = NSViewNoInstrinsicMetric
                size.height = ceil(size.height)
                
            } else {
                size = cell.cellSizeForBounds(NSMakeRect(0, 0, CGFLOAT_MAX, CGFLOAT_MAX))
                
                size.width = ceil(size.width)
                size.height = ceil(size.height)
            }
        }
        
        return size
    }}
}
