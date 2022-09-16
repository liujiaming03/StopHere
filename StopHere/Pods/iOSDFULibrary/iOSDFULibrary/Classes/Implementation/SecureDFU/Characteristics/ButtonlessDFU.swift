/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import CoreBluetooth

internal enum ButtonlessDFUOpCode : UInt8 {
    /// Jump from the main application to Secure DFU bootloader (DFU mode).
    case enterBootloader = 0x01
    /// Set a new advertisement name when jumping to Secure DFU bootloader (DFU mode).
    case setName         = 0x02
    /// The response code.
    case responseCode    = 0x20
    
    var code: UInt8 {
        return rawValue
    }
}

extension ButtonlessDFUOpCode : CustomStringConvertible {
    
    var description: String {
        switch self {
        case .enterBootloader:   return "Enter Bootloader"
        case .setName:           return "Set Name"
        case .responseCode:      return "Response Code"
        }
    }
}

internal enum ButtonlessDFUResultCode : UInt8 {
    /// The operation completed successfully.
    case success            = 0x01
    /// The provided opcode was invalid.
    case opCodeNotSupported = 0x02
    /// The operation failed.
    case operationFailed    = 0x04
    /// The requested advertisement name was invalid (empty or too long).
    /// Only available without bond support.
    case invalidAdvName     = 0x05
    /// The request was rejected due to an ongoing asynchronous operation.
    case busy               = 0x06
    /// The request was rejected because no bond was created.
    case notBonded          = 0x07
    
    // Note: When more result codes are added, the corresponding DFUError
    //       case needs to be added. See `error(ofType:)` method below.
    
    var code: UInt8 {
        return rawValue
    }
    
    func error(ofType remoteError: DFURemoteError) -> DFUError {
        return remoteError.with(code: code)
    }
}

extension ButtonlessDFUResultCode : CustomStringConvertible {
    
    var description: String {
        switch self {
        case .success:            return "Success"
        case .opCodeNotSupported: return "Operation not supported"
        case .operationFailed:    return "Operation failed"
        case .invalidAdvName:     return "Invalid advertisment name"
        case .busy:               return "Busy"
        case .notBonded:          return "Device not bonded"
        }
    }
    
}

internal enum ButtonlessDFURequest {
    case enterBootloader
    case set(name: String)
    
    var data: Data {
        switch self {
        case .enterBootloader:
            return Data([ButtonlessDFUOpCode.enterBootloader.code])
        case .set(let name):
            var data = Data([ButtonlessDFUOpCode.setName.code])
            data += UInt8(name.lengthOfBytes(using: String.Encoding.utf8))
            data += name.utf8
            return data
        }
    }
}

extension ButtonlessDFURequest : CustomStringConvertible {
    
    var description: String {
        switch self {
        case .enterBootloader: return "Enter Bootloder"
        case .set(let name):   return "Set Name (Name = \(name))"
        }
    }
    
}

internal struct ButtonlessDFUResponse {
    let opCode        : ButtonlessDFUOpCode
    let requestOpCode : ButtonlessDFUOpCode
    let status        : ButtonlessDFUResultCode

    init?(_ data: Data) {
        // The correct response is always 3 bytes long: Response Op Code,
        // Request Op Code and Status.
        guard data.count >= 3,
              let opCode = ButtonlessDFUOpCode(rawValue: data[0]),
              let requestOpCode = ButtonlessDFUOpCode(rawValue: data[1]),
              let status = ButtonlessDFUResultCode(rawValue: data[2]),
              opCode == .responseCode else {
            return nil
        }
        
        self.opCode        = opCode
        self.requestOpCode = requestOpCode
        self.status        = status
    }
}

extension ButtonlessDFUResponse : CustomStringConvertible {
    
    var description: String {
        return "Response (Op Code = \(requestOpCode), Status = \(status))"
    }
    
}

internal class ButtonlessDFU : NSObject, CBPeripheralDelegate, DFUCharacteristic {
    
    internal var characteristic: CBCharacteristic
    internal var logger: LoggerHelper
    internal var uuidHelper: DFUUuidHelper!

    private var success: Callback?
    private var report:  ErrorCallback?
    
    internal var valid: Bool {
        return (characteristic.properties.isSuperset(of: [.write, .notify])
            &&  characteristic.uuid.isEqual(uuidHelper.buttonlessExperimentalCharacteristic))
            ||  characteristic.properties.isSuperset(of: [.write, .indicate])
    }
    
    /**
     Returns `true` if the device address is expected to change. In that case,
     the service should scan for another device using `DFUPeripheralSelectorDelegate`.
     */
    internal var newAddressExpected: Bool {
        return characteristic.uuid.isEqual(uuidHelper.buttonlessExperimentalCharacteristic)
            || characteristic.uuid.isEqual(uuidHelper.buttonlessWithoutBonds)
    }
    
    /**
     Returns whether the characteristic is an instance of Experimental Buttonless
     DFU Service from SDK 12.
     */
    internal var isExperimental: Bool {
        return characteristic.uuid.isEqual(uuidHelper.buttonlessExperimentalCharacteristic)
    }
    
    /**
     Returns `true` for a buttonless DFU characteristic that may support setting
     bootloader's name. This feature has been added in SDK 14.0 to Buttonless
     service without bond sharing (the one with bond sharing does not change 
     device address so this feature is not needed). 
     The same characteristic from SDK 13.0 does not support it. Sending this 
     command to that characteristic will end with
     `ButtonlessDFUResultCode.opCodeNotSupported`.
     */
    internal var maySupportSettingName: Bool {
        return characteristic.uuid.isEqual(uuidHelper.buttonlessWithoutBonds)
    }
    
    // MARK: - Initialization
    
    required init(_ characteristic: CBCharacteristic, _ logger: LoggerHelper) {
        self.characteristic = characteristic
        self.logger = logger
    }
    
    // MARK: - Characteristic API methods
    
    /**
     Enables notifications or indications for the DFU Control Point characteristics,
     depending on the characteristic property. Reports success or an error using
     callbacks.
     
     - parameter success: Method called when notifications were successfully enabled.
     - parameter report:  Method called in case of an error.
     */
    func enable(onSuccess success: Callback?, onError report: ErrorCallback?) {
        // Get the peripheral object.
        let optService: CBService? = characteristic.service
        guard let peripheral = optService?.peripheral else {
            report?(.invalidInternalState, "Assert characteristic.service?.peripheral != nil failed")
            return
        }
        
        // Save callbacks.
        self.success = success
        self.report  = report
        
        // Set the peripheral delegate to self.
        peripheral.delegate = self
        
        if characteristic.properties.contains(.indicate) {
            logger.v("Enabling indications for \(characteristic.uuid.uuidString)...")
        } else {
            logger.v("Enabling notifications for \(characteristic.uuid.uuidString)...")
        }
        logger.d("peripheral.setNotifyValue(true, for: \(characteristic.uuid.uuidString))")
        peripheral.setNotifyValue(true, for: characteristic)
    }
    
    /**
     Sends given request to the Buttonless DFU characteristic.
     Reports success or an error using callbacks.
     
     - parameter request: Request to be sent.
     - parameter success: Method called when peripheral reported with status success.
     - parameter report:  Method called in case of an error.
     */
    func send(_ request: ButtonlessDFURequest,
              onSuccess success: Callback?, onError report: ErrorCallback?) {
        // Get the peripheral object.
        let optService: CBService? = characteristic.service
        guard let peripheral = optService?.peripheral else {
            report?(.invalidInternalState, "Assert characteristic.service?.peripheral != nil failed")
            return
        }
        
        // Save callbacks and parameter.
        self.success = success
        self.report  = report
        
        // Set the peripheral delegate to self.
        peripheral.delegate = self
        
        let buttonlessUUID = characteristic.uuid.uuidString
        
        logger.v("Writing to characteristic \(buttonlessUUID)...")
        logger.d("peripheral.writeValue(0x\(request.data.hexString), for: \(buttonlessUUID), type: .withResponse)")
        peripheral.writeValue(request.data, for: characteristic, type: .withResponse)
    }
    
    // MARK: - Peripheral Delegate callbacks
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error {
            if characteristic.properties.contains(.indicate) {
                logger.e("Enabling indications failed")
                logger.e(error)
                report?(.enablingControlPointFailed, "Enabling indications failed")
            } else {
                logger.e("Enabling notifications failed")
                logger.e(error)
                report?(.enablingControlPointFailed, "Enabling notifications failed")
            }
            return
        }
        if characteristic.properties.contains(.indicate) {
            logger.v("Indications enabled for \(characteristic.uuid.uuidString)")
            logger.a("Buttonless DFU indications enabled")
        } else {
            logger.v("Notifications enabled for \(characteristic.uuid.uuidString)")
            logger.a("Buttonless DFU notifications enabled")
        }
        success?()
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error {
            logger.e("Writing to characteristic failed")
            logger.e(error)
            report?(.writingCharacteristicFailed, "Writing to characteristic failed")
            return
        }
        logger.i("Data written to \(characteristic.uuid.uuidString)")
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        // Ignore updates received for other characteristics.
        guard self.characteristic.isEqual(characteristic) else {
            return
        }

        if let error = error {
            // This characteristic is never read, the error may only pop up when notification/indication
            // is received.
            logger.e("Receiving response failed")
            logger.e(error)
            report?(.receivingNotificationFailed, "Receiving response failed")
            return
        }
        
        guard let characteristicValue = characteristic.value else { return }
        
        if characteristic.properties.contains(.indicate) {
            logger.i("Indication received from \(characteristic.uuid.uuidString), value (0x):\(characteristicValue.hexString)")
        } else {
            logger.i("Notification received from \(characteristic.uuid.uuidString), value (0x):\(characteristicValue.hexString)")
        }
        
        // Parse response received.
        guard let dfuResponse = ButtonlessDFUResponse(characteristicValue) else {
            logger.e("Unknown response received: 0x\(characteristicValue.hexString)")
            report?(.unsupportedResponse, "Unsupported response received: 0x\(characteristicValue.hexString)")
            return
        }
        
        guard dfuResponse.status == .success else {
            logger.e("Error \(dfuResponse.status.code): \(dfuResponse.status)")
            let type = isExperimental ?
                DFURemoteError.experimentalButtonless :
                DFURemoteError.buttonless
            report?(dfuResponse.status.error(ofType: type), dfuResponse.status.description)
            return
        }
        
        logger.a("\(dfuResponse) received")
        success?()
    }
}
