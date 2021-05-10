//
//  LoginViewController.swift
//  LoginViewController
//
//  Created by Judson Stephenson on 12/13/18.
//  Copyright © 2018 Judson Company, LLC. All rights reserved.
//

import UIKit
import RSBarcodes
import SCrypto
import AVFoundation

public class BarcodeLoginController: RSCodeReaderViewController {
    var isProcessing = false

    private static var sharedController: BarcodeLoginController = {
        let frameworkBundle = Bundle(identifier: "biz.judson.BarcodeLoginController")
        let storyboard = UIStoryboard(name: "BarcodeLoginController", bundle: frameworkBundle)
        let sharedController = storyboard.instantiateViewController(withIdentifier: "BarcodeLoginController")

        return sharedController as! BarcodeLoginController
    }()

    open var scanHandler: ((AVMetadataMachineReadableCodeObject) -> Void)?
    open var successfulScanHandler: ((_ barcode: String) -> Void) = { _ in return }

    public class func shared() -> BarcodeLoginController {
        return sharedController
    }
    
    func defaultScanHandler (barcode: AVMetadataMachineReadableCodeObject) -> Void {
        if(self.isProcessing){ return }
        self.isProcessing = true
        
        // If we have defined our own scanHandler, call it. Otherwise, go w/ the default
        if let scanHandler = self.scanHandler {
            scanHandler(barcode)
            self.isProcessing = false;
        } else {
            // Check that the barcode is a good scan
            let code = barcode.stringValue!
            let checkLowerBound = code.index(code.endIndex, offsetBy: -2)
            var key = String(code[..<checkLowerBound])
            var check = String(code[checkLowerBound...])
            
            let seperator = "|"
            let pipeCharLocation = code.rangeOfCharacter(from: CharacterSet(charactersIn: seperator))
            if(pipeCharLocation != nil)
            {
                let tok = code.components(separatedBy:seperator)
                key = tok[1]
                check = tok[2]
                
                if(key.SHA256().suffix(2) == check){
                    DispatchQueue.main.async(execute: {
                        self.dismiss(animated: true) {
                            self.isProcessing = false
                        }
                        self.successfulScanHandler(code)
                    });
                } else {
                    self.isProcessing = false
                }
            } else {
                // Get the check digits from the sha256 of the code
                let codeSum = key.SHA256()
                let codeSumCheckIndex = codeSum.index(code.startIndex, offsetBy: 2)
                let codeSumCheck = codeSum[..<codeSumCheckIndex]
                if(codeSumCheck == check){
                    DispatchQueue.main.async(execute: {
                        self.dismiss(animated: true) {
                            self.isProcessing = false
                        }
                        self.successfulScanHandler(code)
                    });
                } else {
                    self.isProcessing = false
                }
            }
        }
    }

    public func presentCameraController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "BarcodeLoginController")
        self.present(controller, animated: true, completion: nil)
    }

    override public var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.barcodesHandler = { barcodes in
            for barcode in barcodes {
                self.defaultScanHandler(barcode: barcode)
            }
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if(self.device?.position != AVCaptureDevice.Position.front){
            _ = self.switchCamera()
            self.view.setNeedsLayout()
        }
    }
    
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var dismissViewControllerButton: UIButton!
    
    @IBAction func requestedControllerDismissal(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func requestedCameraFlip(_ sender: Any) {
        _ = self.switchCamera()
        self.view.setNeedsLayout()
    }
}
