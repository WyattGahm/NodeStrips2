//
//  ViewController.swift
//  LEDControl
//
//  Created by Wyatt Gahm on 11/11/20.
//
import Starscream
import UIKit
import Network
import Colorful

class ViewController: UIViewController, WebSocketDelegate {
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        //essential but i defined elsewhere
    }
    
    var colorSpace: HRColorSpace = .sRGB
    
    var websocket:WebSocket? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        colorPicker.addTarget(self, action: #selector(self.handleColorChanged(picker:)), for: .valueChanged)
        colorPicker.set(color: UIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 1), colorSpace: colorSpace)
        handleColorChanged(picker: colorPicker)
        
        
        
        StatusLabel.textColor = UIColor.red;
        StatusLabel.text = "Not Connected";
        let url = URL(string: "ws://192.168.1.34:81/")!
        let request = URLRequest(url: url)
        websocket = WebSocket(request: request)
        websocket!.connect()
        websocket!.onEvent = { event in
            switch event{
            case .connected(_):
                self.StatusLabel.textColor = UIColor.green;
                self.StatusLabel.text = "Connected!!!";
                
                self.websocket!.write(string: "X")
                break
            case .disconnected(_, _):
                self.StatusLabel.textColor = UIColor.red;
                self.StatusLabel.text = "Disconnected";
                self.websocket!.connect()
            case .text(let text):
                print(text)
                if text.starts(with: "X") {
                    let args = text.split(separator: " ")
                    for arg in args {print(arg)}
                    self.SpeedSlider.value = Float(args[1]) ?? self.SpeedSlider.value
                    var red: CUnsignedInt = 0, blue: CUnsignedInt = 0, green: CUnsignedInt = 0
                    Scanner(string: String(args[2])).scanHexInt32(&red)
                    Scanner(string: String(args[3])).scanHexInt32(&blue)
                    Scanner(string: String(args[4])).scanHexInt32(&green)
                    let ledColor = UIColor(red:CGFloat(red) / 255, green: CGFloat(green) / 255, blue:  CGFloat(blue) / 255, alpha: 1.0)
                    self.colorPicker.set(color: ledColor, colorSpace: HRColorSpace.sRGB)
                }
            case .binary(_):
                break
            case .pong(_):
                break
            case .ping(_):
                break
            case .error(_):
                break
            case .viabilityChanged(_):
                break
            case .reconnectSuggested(_):
                break
            case .cancelled:
                break
            }
        }
        
    }
    
    deinit {
        websocket!.disconnect()
        websocket!.delegate = nil
    }
    
    func hexStringFromColor(color: UIColor) -> String {
        let components = color.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0

        let hexString = String.init(format: "C%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        print(hexString)
        return hexString
     }
    
    @objc func handleColorChanged(picker: ColorPicker){
        if modeSelector.selectedSegmentIndex == 1 {
        let color = UIColor(cgColor: picker.color.cgColor)
        print(hexStringFromColor(color: color))
        guard websocket == nil else{
            websocket!.write(string: hexStringFromColor(color: color))
            return
        }
        }
    }
    
    
    @IBOutlet weak var modeSelector: UISegmentedControl!
    
    @IBOutlet weak var colorPicker: ColorPicker!
    @IBOutlet weak var SpeedSlider: UISlider!
    @IBOutlet weak var StatusLabel: UILabel!
    
    @IBAction func sliderMoved(_ sender: Any) {
        let speed = NSInteger(SpeedSlider.value)
        websocket!.write(string: "S" + (SpeedSlider.value < 10.0 ? "0" : "" ) + String(speed))
        print("S" + (SpeedSlider.value < 10.0 ? "0" : "" ) + String(speed))
    }
    @IBAction func modeChanged(_ sender: Any) {
        switch modeSelector.selectedSegmentIndex {
        case 0:
            websocket!.write(string: "ON")
            break
        case 1:
            websocket!.write(string: hexStringFromColor(color: UIColor(cgColor: self.colorPicker.color.cgColor)))
            break
        case 2:
            websocket!.write(string: "OFF")
            break
        default:
            break
        }
    }
    
    @IBAction func refreshButton(_ sender: Any) {
        websocket!.write(string: "X")
    }

}

