import Foundation
import Capacitor
import BRLMPrinterKit
import BRPtouchPrinterKit

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(BrotherPrint)
public class BrotherPrint: CAPPlugin, BRPtouchNetworkDelegate {
    private var networkManager: BRPtouchNetworkManager?
    
    @objc func printImage(_ call: CAPPluginCall) {
        let encodedImage: String = call.getString("encodedImage") ?? "";
        if (encodedImage == "") {
            call.error("Error - Image data is not found.");
            return;
        }
        
        let newImageData = Data(base64Encoded: encodedImage, options: []);
        
        let printerType: String = call.getString("printerType") ?? "";
        if (printerType == "") {
            call.error("Error - printerType is not found.");
            return;
        }
        
        let allowedPrinters = ["QL-810W","QL-720NW","QL-820NWB","QL-1110NWB","QL-1115NWB"];
        
        if (!allowedPrinters.contains(printerType)) {
            // iOS非対応
            call.error("Error - connection is not found.");
            return;
        }
        
        
        // 検索からデバイス情報が得られた場合
        let localName: String = call.getString("localName") ?? "";
        let ipAddress: String = call.getString("ipAddress") ?? "";
        
        // メインスレッドにて処理
        DispatchQueue.main.async {
            var channel: BRLMChannel;
            if (localName != "") {
                channel = BRLMChannel(bleLocalName: localName);
            } else if (ipAddress != "") {
                channel = BRLMChannel(wifiIPAddress: ipAddress);
            } else {
                // iOSは有線接続ができない
                self.notifyListeners("onPrintFailedCommunication", data: [
                    "value": true
                ]);
                return;
            }
            
            let generateResult = BRLMPrinterDriverGenerator.open(channel);
            
            var printerOption = BRLMPrinterModel.unknown;
            
            if( printerType == "QL-810W" ){
                printerOption = BRLMPrinterModel.QL_810W;
            }
            else if( printerType == "QL-720NW" ){
                printerOption = BRLMPrinterModel.QL_720NW;
            }
            else if( printerType == "QL-820NWB" ){
                printerOption = BRLMPrinterModel.QL_820NWB;
            }
            else if( printerType == "QL-1110NWB" ){
                printerOption = BRLMPrinterModel.QL_1110NWB;
            }
            else if( printerType == "QL-1115NWB" ){
                printerOption = BRLMPrinterModel.QL_1115NWB;
            }
            
            guard generateResult.error.code == BRLMOpenChannelErrorCode.noError,
                let printerDriver = generateResult.driver
                else {
                    self.notifyListeners("onPrintError", data: [
                        "value": generateResult.error.code
                    ]);
                    NSLog("Error - Open Channel: \(generateResult.error.code)")
                    return
                }
            
            guard
                let decodedByte = UIImage(data: newImageData! as Data),
                let printSettings = BRLMQLPrintSettings(defaultPrintSettingsWith: printerOption)
                else {
                    printerDriver.closeChannel();
                    self.notifyListeners("onPrintError", data: [
                        "value": "Error - Image file is not found."
                    ]);
                    return
                }
            
            let labelNameIndex = call.getInt("labelNameIndex") ?? 16;
            printSettings.labelSize = labelNameIndex == 16 ?
                BRLMQLPrintSettingsLabelSize.rollW62 : BRLMQLPrintSettingsLabelSize.rollW62RB;
            printSettings.autoCut = true
            printSettings.numCopies = UInt(call.getInt("numberOfCopies") ?? 1);
            
            let printError = printerDriver.printImage(with: decodedByte.cgImage!, settings: printSettings);
            
            
            if printError.code != .noError {
                printerDriver.closeChannel();
                self.notifyListeners("onPrintError", data: [
                    "value": printError.code
                ]);
                return;
            }
            else {
                NSLog("Success - Print Image")
                printerDriver.closeChannel();
                call.success([
                    "value": true
                ]);
            }
        }
    }
    
    @objc func searchWiFiPrinter(_ call: CAPPluginCall) {
        NSLog("Start searchWiFiPrinter");
        let printerType: String = call.getString("printerType") ?? "";
        DispatchQueue.main.async {
            let manager = BRPtouchNetworkManager()
            manager.setPrinterName(printerType)
            manager.delegate = self
            manager.startSearch(5)
            self.networkManager = manager
        }
    }
    
    // BRPtouchNetworkDelegate
    public func didFinishSearch(_ sender: Any!) {
        NSLog("Start didFinishSearch");
        DispatchQueue.main.async {
            guard let manager = sender as? BRPtouchNetworkManager else {
                return
            }
            guard let devices = manager.getPrinterNetInfo() else {
                return
            }
            var resultList: [String] = [];
            for deviceInfo in devices {
                if let deviceInfo = deviceInfo as? BRPtouchDeviceInfo {
                    resultList.append(deviceInfo.strIPAddress);
                }
            }
            self.notifyListeners("onIpAddressAvailable", data: [
                "ipAddressList": resultList,
            ]);
        }
    }
    
    @objc func searchBLEPrinter(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            NSLog("Start searchBLEPrinter");
            BRPtouchBLEManager.shared().startSearch {
                (deviceInfo: BRPtouchDeviceInfo?) in
                if let deviceInfo = deviceInfo {
                    var resultList: [String] = [];
                    resultList.append(deviceInfo.strBLEAdvertiseLocalName);
                    self.notifyListeners("onBLEAvailable", data: [
                        "localNameList": resultList,
                    ]);
                }
            }
            self.notifyListeners("onBLEAvailable", data: [
                "localNameList": [],
            ]);
        }
    }
    
    @objc func stopSearchBLEPrinter(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            BRPtouchBLEManager.shared().stopSearch()
        }
    }
}
