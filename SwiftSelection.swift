// https://github.com/alexandr-vp/SwiftSelection
//
// Requires ApplicationServices.framework
//
// Entitlements:
// <key>com.apple.security.temporary-exception.apple-events</key>
// <array>
//    <string>com.apple.systemevents</string>
// </array>
// <key>com.apple.security.automation.apple-events</key>
// <true/>
//


import Cocoa

class SwiftSelection {
    public enum Browser: String {
        case none = ""
        case chrome = "Google Chrome"
        //TODO: support Safari and maybe Firefox
    }
    
    static func getSelectedText(_ browser:Browser = .none) -> String? {
        if let selectedTextInUI = getSelectedTextInUI() {
            return selectedTextInUI
        }
        if browser == .chrome {
            if let selectedTextInHTML = getSelectedTextInChromeHTML() {
                return selectedTextInHTML
            }
        }
        if let selectedTextInGeneral = getSelectedTextInGeneral() {
            return selectedTextInGeneral
        }
        return nil
    }
    
    private static func getSelectedTextInChromeHTML() -> String? {
        let script = """
        tell application "Google Chrome"
            set selectedText to execute front window's active tab javascript "window.getSelection().toString();"
            return selectedText
        end tell
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script), let output = appleScript.executeAndReturnError(&error).stringValue {
            if !output.isEmpty {
                print("getSelectedTextInHTML:", output)
                return output
            }
        } else {
            print("AppleScriptError: \(String(describing: error))")
        }
        return nil
    }
    
    private static func getSelectedTextInUI() -> String? {
        let systemWideElement = AXUIElementCreateSystemWide()

        var selectedTextValue: AnyObject?
        let errorCode = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &selectedTextValue)
        
        if errorCode == .success {
            let selectedTextElement = selectedTextValue as! AXUIElement
            var selectedText: AnyObject?
            let textErrorCode = AXUIElementCopyAttributeValue(selectedTextElement, kAXSelectedTextAttribute as CFString, &selectedText)
            
            if textErrorCode == .success, let selectedTextString = selectedText as? String {
                print("getSelectedTextInUI:", selectedTextString)
                return selectedTextString
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    private static func getSelectedTextInGeneral() -> String? {
        let script = """
        -- https://apple.stackexchange.com/questions/271161/how-to-get-the-selected-text-into-an-applescript-without-copying-the-text-to-th#271844

        set savedClipboard to my fetchStorableClipboard()
        
        delay 0.5

        set thePasteboard to current application's NSPasteboard's generalPasteboard()
        set theCount to thePasteboard's changeCount()
        tell application "System Events" to keystroke "c" using {command down}
        repeat 50 times
            if thePasteboard's changeCount() is not theCount then exit repeat
            delay 0.1
        end repeat

        set theSelectedText to the clipboard
        
        set theSelectedTextContent to "" & theSelectedText  -- TODO: is it needed?

        my putOnClipboard:savedClipboard

        return theSelectedTextContent

        use AppleScript version "2.4"
        use scripting additions
        use framework "Foundation"
        use framework "AppKit"

        on fetchStorableClipboard()
            set aMutableArray to current application's NSMutableArray's array() -- used to store contents
            -- get the pasteboard and then its pasteboard items
            set thePasteboard to current application's NSPasteboard's generalPasteboard()
            -- loop through pasteboard items
            repeat with anItem in thePasteboard's pasteboardItems()
                -- make a new pasteboard item to store existing item's stuff
                set newPBItem to current application's NSPasteboardItem's alloc()'s init()
                -- get the types of data stored on the pasteboard item
                set theTypes to anItem's types()
                -- for each type, get the corresponding data and store it all in the new pasteboard item
                repeat with aType in theTypes
                    set theData to (anItem's dataForType:aType)'s mutableCopy()
                    if theData is not missing value then
                        (newPBItem's setData:theData forType:aType)
                    end if
                end repeat
                -- add new pasteboard item to array
                (aMutableArray's addObject:newPBItem)
            end repeat
            return aMutableArray
        end fetchStorableClipboard

        on putOnClipboard:theArray
            -- get pasteboard
            set thePasteboard to current application's NSPasteboard's generalPasteboard()
            -- clear it, then write new contents
            thePasteboard's clearContents()
            thePasteboard's writeObjects:theArray
        end putOnClipboard:        
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script), let output = appleScript.executeAndReturnError(&error).stringValue {
            print("getSelectedTextInGeneral:", output)
            return output.replacingOccurrences(of: "\r", with: "\n")
        } else {
            print("AppleScriptError: \(String(describing: error))")
            return nil
        }
    }
    
    static func selectAll() {
        let script = """
        delay 0.5
        tell application "System Events" to keystroke "a" using {command down}
        delay 0.5
        """
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
        if let error = error {
            print("AppleScriptError: \(String(describing: error))")
        }
    }

}
