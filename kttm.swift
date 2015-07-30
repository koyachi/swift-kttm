#!/usr/bin/env cato

import Foundation
import Cocoa
import Alamofire

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
        println("err = \(err)")
        return nil
    }

    return tempDirectoryTemplate
}

func fetchImage(url: String) {
    let tempDirectory = createTempDirectory("download")
    println("tempDirectory = \(tempDirectory)")
    if tempDirectory == nil {
        return
    }

    println("before download \(url)...")
    Alamofire.request(.GET, url)
             .response {
                 request, response, data, error in

                 if data == nil {
                     return
                 }

                 let parts = url.componentsSeparatedByString("/")
                 println("parts = \(parts)")
                 let fileName = tempDirectory!.stringByAppendingPathComponent(parts.last!)
                 println("fileName = \(fileName)")
                 println("before save \(fileName)...")
                 let rawData = data as! NSData
                 if !NSFileManager.defaultManager().createFileAtPath(fileName, contents: rawData, attributes: nil) {
                     println("create file failed: \(fileName)")
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
    //println(bitmap.size)
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
    println("\(imageFilePath): image.height = \(bitmap.size), minIndex = \(minIndex)")
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

                 var location: Int = 0;
                 var totalLength: Int = count(str);
                 var length: Int = totalLength
                 while (location <= totalLength) {
                     println("totalLength = \(totalLength), location = \(location), length = \(length)")
                     //let range = NSRange(location: location, length: length)
                     let range = NSMakeRange(location, length)
                     // 抜け無いか不安
                     var match = nsstr.rangeOfString("(http://whatthingsdo.com/wp-content/uploads/.*?.gif)", options: NSStringCompareOptions.RegularExpressionSearch, range: range)
                     if match.location != NSNotFound {
                         let url = nsstr.substringWithRange(match)
                         println("match! \(match): \(url)")
                         fetchImage(url)
                         location = match.location + match.length
                         length = totalLength - location
                         println("")
                     } else {
                         println("oh...")
                         break;
                     }
                 }
                 println(".")
             }

    println("end.")
    keepRunLoop()
    println("end.end.")
}
main()
