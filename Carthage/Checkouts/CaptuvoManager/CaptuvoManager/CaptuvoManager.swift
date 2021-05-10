//
//  CaptuvoManager.swift
//

import Foundation

public class CaptuvoManager: NSObject, CaptuvoEventsProtocol {
    
    public static let sharedManager = CaptuvoManager()
    
    public static let batteryReadyNotification = Notification.Name("BatteryReady")
    public static let msrReadyNotification = Notification.Name("MSRReady")
    public static let scannerReadyNotification = Notification.Name("ScannerReady")
    public static let batteryDetailNotification = Notification.Name("BatteryDetail")
    public static let decoderDataReceivedNotification = Notification.Name("DataReceived")
    public static let msrDataReceivedNotification = Notification.Name("MSRDataReceived")
    
    private let notificationCenter = NotificationCenter.default
    
    override init() {
        
        super.init()
        
        Captuvo.sharedCaptuvoDevice().addDelegate(self)
        Captuvo.sharedCaptuvoDevice().startDecoderHardware()
        
        Captuvo.sharedCaptuvoDevice().startMSRHardware()
        Captuvo.sharedCaptuvoDevice().setMSRTrackSelection(TrackSelectionRequire1and2)
        
        Captuvo.sharedCaptuvoDevice().startPMHardware()
        
    }
    
    public func decoderDataReceived(_ data: String!) {
        
        self.notificationCenter.post(name: CaptuvoManager.decoderDataReceivedNotification, object: self, userInfo: ["data":data!])
        
    }
    
    public func msrStringDataReceived(_ data: String!, validData status: Bool) {
        self.notificationCenter.post(name: CaptuvoManager.msrDataReceivedNotification, object: self, userInfo: ["data":data!, "validData":status])
    }
    
    public func pmReady(){
        
        self.notificationCenter.post(name: CaptuvoManager.batteryReadyNotification, object: self, userInfo:nil)
    }
    
    public func msrReady() {
        self.notificationCenter.post(name: CaptuvoManager.msrReadyNotification, object: self, userInfo:nil)
    }
    
    public func decoderReady() {
        self.notificationCenter.post(name: CaptuvoManager.scannerReadyNotification, object: self, userInfo:nil)
    }
    
    func responseBatteryDetailInformation(batteryInfo:cupertinoBatteryDetailInfo)
    {
        self.notificationCenter.post(name: CaptuvoManager.batteryDetailNotification, object: self, userInfo: ["batteryInfo":batteryInfo])
    }
    
    public func connect(){
        Captuvo.sharedCaptuvoDevice().startDecoderHardware()
        
        Captuvo.sharedCaptuvoDevice().startMSRHardware()
        Captuvo.sharedCaptuvoDevice().setMSRTrackSelection(TrackSelectionRequire1and2)
        
        Captuvo.sharedCaptuvoDevice().startPMHardware()
    }
    
    public func disconnect(){
        Captuvo.sharedCaptuvoDevice().stopDecoderHardware()
        Captuvo.sharedCaptuvoDevice().stopMSRHardware();
        Captuvo.sharedCaptuvoDevice().stopPMHardware()
    }
    
    public func captuvoConnected(){
        
        Captuvo.sharedCaptuvoDevice().startDecoderHardware()
        Captuvo.sharedCaptuvoDevice().startMSRHardware()
        Captuvo.sharedCaptuvoDevice().startPMHardware()
        
    }
    
    public func captuvoDisconnected()
    {
        Captuvo.sharedCaptuvoDevice().stopDecoderHardware()
        Captuvo.sharedCaptuvoDevice().stopMSRHardware();
        Captuvo.sharedCaptuvoDevice().stopPMHardware()
    }
    
    public func beep()
    {
        let goodBeep = NSData(bytes: [0x16,0x4d,0x0d,0x42,0x45,0x50,0x45,0x58,0x45,0x31,0x2e] as [UInt8], length: 11)
        
        Captuvo.sharedCaptuvoDevice().decoderPassThrough(goodBeep as Data, expectingReturnData: false)
    }
    
    public func razz()
    {
        let badBeep = NSData(bytes: [0x16,0x4d,0x0d,0x42,0x45,0x50,0x45,0x58,0x45,0x34,0x2e] as [UInt8], length: 11)
        
        Captuvo.sharedCaptuvoDevice().decoderPassThrough(badBeep as Data, expectingReturnData: false)
    }
}
