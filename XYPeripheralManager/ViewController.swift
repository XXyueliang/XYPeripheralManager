//
//  ViewController.swift
//  XYCBPeripheralManager
//
//  Created by macvivi on 2020/12/8.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController{
    let peripheralName = "蓝牙外设app"
    let serviceUUID = CBUUID(string: "FFA0")
    let characteristicWriteUUID = CBUUID(string: "FFA1")
    let characteristicNofifyUUID = CBUUID(string: "FFA3")
    let characteristicReadUUID = CBUUID(string: "FFA2")
    let characteristicWriteWithoutResponseUUID = CBUUID(string: "FFA4")
    
    @IBOutlet var writeTextView: UITextView!
    @IBOutlet var notifyTextView: UITextView!
    @IBOutlet var writeWithoutResponseTextView: UITextView!
    @IBOutlet var readTextView: UITextView!
    
    
    @IBAction func editBtnClick(_ sender: Any) {
        let vc: CollectionViewVC = XYHelper.getViewController(storyboardStr: nil, viewController: "CollectionViewVC") as! CollectionViewVC
        vc.backClosure = { backStr in
            self.notifyTextView.text =  self.notifyTextView.text + "\n\n" + self.currentTime() + backStr
            printXY(backStr, obj: self, line: #line)
            self.manager?.updateValue(backStr.hexadecimal()!, for: self.notify!, onSubscribedCentrals: nil)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    var readValue: Data?
    
    @IBAction func editReadValueBtnClick(_ sender: Any) {
        let vc: CollectionViewVC = XYHelper.getViewController(storyboardStr: nil, viewController: "CollectionViewVC") as! CollectionViewVC
        vc.backClosure = { backStr in
            self.readTextView.text =  backStr
            printXY(backStr, obj: self, line: #line)
            self.readValue = backStr.hexadecimal()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
//        print(CBPeripheralManager.authorization.rawValue)
        //这里如果不用self.manager而是用let manager的话，会不弹出蓝牙授权框
        self.manager = CBPeripheralManager.init(delegate: self, queue: nil, options: nil)
        title = peripheralName
        readTextView.text = "1234"
        self.readValue = readTextView.text.hexadecimal()
       
        //可用滚动，但不能编辑
        notifyTextView.inputView = UIView()
        writeTextView.inputView = UIView()
        writeWithoutResponseTextView.inputView = UIView()
    }

    var manager: CBPeripheralManager?
    var myService: CBMutableService?
    var notify: CBMutableCharacteristic?
    var read: CBMutableCharacteristic?

    func addPeripheral() {
//        print(CBPeripheralManager.authorization.rawValue)
       //71DA3FD1-7E10-41C1-B16F-4430B506CDE7
        let write =  CBMutableCharacteristic(type: characteristicWriteUUID, properties: .write, value: nil, permissions: .writeable)
        let notify = CBMutableCharacteristic(type: characteristicNofifyUUID, properties: .notify, value: nil, permissions: .writeable)
        self.notify = notify
        //'Characteristics with cached values must be read-only' Data(bytes: [9, 10, 11])
        let read = CBMutableCharacteristic(type: characteristicReadUUID, properties: .read, value: nil, permissions: .readable)
        self.read = read
        let writeWithoutResponse =  CBMutableCharacteristic(type: characteristicWriteWithoutResponseUUID, properties: .writeWithoutResponse, value: nil, permissions: .writeable)
      
        myService = CBMutableService(type: serviceUUID, primary: true)
        myService!.characteristics = [write,read,notify,writeWithoutResponse]
        self.manager!.add(myService!)
    }
}

extension ViewController {
    func currentTime() -> String {
      getCurrentTimeWithDateFormatString("mm:ss.SSS   ")
    }
}


extension ViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print(#function)
        print(peripheral.state.rawValue)
        addPeripheral()
        //得在这个方法调用，peripheral: CBPeripheralManager状态为poweredOn的时候再添加service。 得用这个CBPeripheralManager添加service.如果你新创建一个CBPeripheralManager，用这个新的CBPeripheralManager添加service,由于系统不知道这个新的CBPeripheralManager状态还是会报上面的错误
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print(#function)
        print(error)
        manager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [myService?.uuid], CBAdvertisementDataLocalNameKey : peripheralName])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print(#function)
        print(error)
        if(error == nil){
            print("已开始广播")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print(central.maximumUpdateValueLength)
        print(#function)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print(#function)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print(#function)
        print(request)
        request.value = self.readValue  //蓝牙中心read到的值
        peripheral.respond(to: request, withResult: .success)
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        print(#function)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        peripheral.respond(to: requests[0], withResult: .success)
        print(#function)
        print(requests)
        let request: CBATTRequest = requests[0]
        if let data: Data =  request.value {
            print(NSData(data: data))
            if request.characteristic.properties == .write {
                writeTextView.text = writeTextView.text + "\n\n" + currentTime() + data.hexadecimal()
            }else {
                writeWithoutResponseTextView.text = writeWithoutResponseTextView.text + "\n\n" + currentTime() + data.hexadecimal()
            }
        }
    }
    
    
}


