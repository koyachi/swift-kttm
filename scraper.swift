#!/usr/bin/env cato

import Foundation
import Cocoa
import Alamofire

func drintln(msg: String) {
    let debug = true
    if debug {
        println(msg)
    }
}

// via http://stackoverflow.com/questions/25126471/cfrunloop-in-swift-command-line-program
var shouldKeepRunning = true        // global
func keepRunLoop() {
    let theRL = NSRunLoop.currentRunLoop()
    while shouldKeepRunning && theRL.runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture() as! NSDate) { }
}

// via http://stackoverflow.com/questions/24281362/accessing-temp-directory-in-swift
func createTempDirectory(dirName: String) -> String? {
    let tempDirectoryTemplate = NSTemporaryDirectory().stringByAppendingPathComponent(dirName)
    var err: NSError?
    if !NSFileManager.defaultManager().createDirectoryAtPath(tempDirectoryTemplate, withIntermediateDirectories: true, attributes: nil, error: &err) {
        drintln("err = \(err)")
        return nil
    }

    return tempDirectoryTemplate
}

func fetchImage(url: String) {
    let tempDirectory = createTempDirectory("download")
    drintln("tempDirectory = \(tempDirectory)")
    if tempDirectory == nil {
        return
    }

    drintln("before download \(url)...")
    Alamofire.request(.GET, url)
             .response {
                 request, response, data, error in

                 if data == nil {
                     return
                 }

                 let parts = url.componentsSeparatedByString("/")
                 drintln("parts = \(parts)")
                 let fileName = tempDirectory!.stringByAppendingPathComponent(parts.last!)
                 drintln("fileName = \(fileName)")
                 drintln("before save \(fileName)...")
                 let rawData = data as! NSData
                 if !NSFileManager.defaultManager().createFileAtPath(fileName, contents: rawData, attributes: nil) {
                     drintln("create file failed: \(fileName)")
                 }
                 // TODO:画像をkindleサイズに分割
                 let cols = columns(fileName)
                 if cols > 3 {
                     // TODO:分割
                     // - 奇数コマだと適切な分割が難しそう -> opencv?
                 }
             }
}

func columns(imageFilePath: String) -> Int {
    let image = NSImage(contentsOfFile: imageFilePath)!
    let bitmap = NSBitmapImageRep(data: image.TIFFRepresentation!)!
    //drintln(bitmap.size)
    let baseHeight = 539.0
    var minIndex = 1
    var minDiff = baseHeight * (12 + 1)
    for i in 1...12 {
        let height = baseHeight * Double(i)
        let diff = abs(Double(bitmap.size.height) - height)
        if diff < minDiff {
            minDiff = diff
            minIndex = i
        }
    }
    drintln("\(imageFilePath): image.height = \(bitmap.size), minIndex = \(minIndex)")
    return minIndex
}

func main() {
    // onoでhtmlパースしようと思ったけどhtml構造によってはまともに動かない？っぽいので正規表現で解析する
    Alamofire.request(.GET, "http://whatthingsdo.com/comic/keeping-two/")
             .responseString(encoding: NSUTF8StringEncoding) {
                 request, response, data, error in

                 if data == nil {
                     return
                 }

                 let str: String = data!
                 let nsstr = str as NSString

                 var location: Int = 0
                 var totalLength: Int = count(str)
                 var length: Int = totalLength
                 var index: Int = 0
                 var urlIndex = [String: NSString]()
                 while (location <= totalLength) {
                     drintln("totalLength = \(totalLength), location = \(location), length = \(length)")
                     //let range = NSRange(location: location, length: length)
                     let range = NSMakeRange(location, length)
                     // 抜け無いか不安
                     var match = nsstr.rangeOfString("(http://whatthingsdo.com/wp-content/uploads/.*?.gif)", options: NSStringCompareOptions.RegularExpressionSearch, range: range)
                     if match.location != NSNotFound {
                         let url = nsstr.substringWithRange(match)
                         drintln("match! \(match): \(url)")
                         fetchImage(url)
                         urlIndex[String(index)] = url
                         location = match.location + match.length
                         length = totalLength - location
                         drintln("")
                     } else {
                         drintln("oh...")
                         break;
                     }

                     index++
                 }

                 let tempDirectory = createTempDirectory("download")
                 drintln("tempDirectory = \(tempDirectory)")
                 if tempDirectory == nil {
                     return
                 }
                 let fileName = tempDirectory!.stringByAppendingPathComponent("urlIndex.json")
                 var error: NSError?
                 let json = NSJSONSerialization.dataWithJSONObject(urlIndex, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
                 if error != nil {
                     drintln("error = \(error)")
                 }
                 //println(json)
                 if !NSFileManager.defaultManager().createFileAtPath(fileName, contents: json, attributes: nil) {
                     drintln("create file failed: \(fileName)")
                 }
                 drintln(".")
             }

    drintln("end.")
    keepRunLoop()
    drintln("end.end.")
}
main()
