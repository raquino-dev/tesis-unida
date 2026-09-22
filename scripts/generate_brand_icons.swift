import AppKit
import Foundation

// Render vector geometry at 1024 px. Use sips to derive each platform size.
let size = 1024
let bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil,
  pixelsWide: size,
  pixelsHigh: size,
  bitsPerSample: 8,
  samplesPerPixel: 4,
  hasAlpha: true,
  isPlanar: false,
  colorSpaceName: .deviceRGB,
  bytesPerRow: 0,
  bitsPerPixel: 0
)!
let graphics = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphics

NSColor(calibratedRed: 0.968, green: 1, blue: 0.981, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

NSColor(calibratedRed: 0.903, green: 0.980, blue: 0.942, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 109, y: 109, width: 806, height: 806)).fill()

let leaf = NSBezierPath()
leaf.move(to: NSPoint(x: 253, y: 246))
leaf.curve(to: NSPoint(x: 776, y: 777),
  controlPoint1: NSPoint(x: 201, y: 561),
  controlPoint2: NSPoint(x: 449, y: 800))
leaf.curve(to: NSPoint(x: 253, y: 246),
  controlPoint1: NSPoint(x: 798, y: 466),
  controlPoint2: NSPoint(x: 566, y: 199))
leaf.close()
leaf.addClip()
NSGradient(starting: NSColor(calibratedRed: 0.52, green: 0.89, blue: 0.67, alpha: 1),
  ending: NSColor(calibratedRed: 0, green: 0.52, blue: 0.35, alpha: 1))!
  .draw(in: NSRect(x: 180, y: 180, width: 680, height: 680), angle: 135)

graphics.flushGraphics()
NSGraphicsContext.restoreGraphicsState()
let output = CommandLine.arguments.count > 1
  ? CommandLine.arguments[1]
  : "/tmp/finanza-icon.png"
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
