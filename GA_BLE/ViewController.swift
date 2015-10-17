//
//  ViewController.swift
//  GA_BLE
//
//  Created by houjianan on 15/9/23.
//  Copyright (c) 2015年 houjianan. All rights reserved.
//

import UIKit
import CoreBluetooth
/*
peripheral  外围设备
*/
class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    
    var peripheral: CBPeripheral!
    var writeCharacteristic: CBCharacteristic!
    
    //保存收到的蓝牙设备
    var deviceList:NSMutableArray = NSMutableArray()
    
    //服务和特征的UUID
    let kServiceUUID = [CBUUID(string:"FFE0")]
    let kCharacteristicUUID = [CBUUID(string:"FFE1")]
    
    @IBAction func action(sender: UIButton) {
        let paramStr = "baidumap://map/geocoder?location=39.94384188087471,116.48768627258201&mode=walking&coord_type=gcj02&src=G"
        println(paramStr)
        let url = NSURL(string: paramStr.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
        println(url)
        UIApplication.sharedApplication().openURL(url!)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate:self, queue: dispatch_get_global_queue(0, 0))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //    MARK: CBCentralManagerDelegate
    /**
    主设备状态改变的委托代理，在初始化CBCentralManager时候打开设备，设备打开了才能使用其他代理
    
    :param: central CBCentralManager 设备中心管理上下文
    */
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        println("centralManagerDidUpdateState")
        switch central.state {
        case CBCentralManagerState.PoweredOff:
            println("PoweredOff")
            break
        case CBCentralManagerState.PoweredOn:
            println("PoweredOn")
            //蓝牙打开成功 扫描周围 扫描到设备之后会进入
            //            func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!)
            centralManager.scanForPeripheralsWithServices(nil, options: nil)
//            centralManager.scanForPeripheralsWithServices(kServiceUUID, options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
            break
        case CBCentralManagerState.Resetting:
            println("Resetting")
            break
        case CBCentralManagerState.Unauthorized:
            println("Unauthorized")
            break
        case CBCentralManagerState.Unknown:
            println("Unknown")
            break
        case CBCentralManagerState.Unsupported:
            println("Unsupported")
            break
        default :
            break
        }
    }
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
        println("willRestoreState")
    }
    
    func centralManager(central: CBCentralManager!, didRetrievePeripherals peripherals: [AnyObject]!) {
        println("didRetrievePeripherals")
    }
    
    func centralManager(central: CBCentralManager!, didRetrieveConnectedPeripherals peripherals: [AnyObject]!) {
        println("didRetrieveConnectedPeripherals")
    }
    /**
    扫描到设备调用
    */
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println("didDiscoverPeripheral")
        println(peripheral)
        println(advertisementData)
        println(RSSI)
        /**
        一个主设备最多能连7个外设，每个外设最多只能给一个主设备连接,连接成功，失败，断开会进入各自的委托
        会调用 连接成功、连接失败、断开连接三个代理
        */
        centralManager.connectPeripheral(peripheral, options: nil)
        
        if(!self.deviceList.containsObject(peripheral)){
            self.deviceList.addObject(peripheral)
        }
        
        self.tableView.reloadData()
    }
    
    /**
    连接失败
    */
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println("didFailToConnectPeripheral")
    }
    /**
    断开连接
    */
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println("didDisconnectPeripheral")
    }
    
    /**
    连接成功
    */
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        println("didConnectPeripheral")
        println("连接设备名 == \(peripheral.name)")
        //停止扫描
        self.centralManager.stopScan()
        self.peripheral = peripheral
        //设置CBPeripheral代理
        self.peripheral.delegate = self
        //搜索服务
        self.peripheral.discoverServices(nil)
    }
    //    MARK: CBPeripheralDelegate
    /**
    搜索服务
    */
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if error != nil {
            println(error)
            return
        }
        var i: Int = 0
        //扫描每个服务的Characteristics 扫描到走代理didDiscoverCharacteristicsForService
        for service in peripheral.services {
            i++
            //发现给定格式的服务的特性
            //            if (service.UUID == CBUUID(string:"FFE0")) {
            //                peripheral.discoverCharacteristics(kCharacteristicUUID, forService: service as! CBService)
            //            }
            peripheral.discoverCharacteristics(nil, forService: service as! CBService)
        }
    }
    /**
    搜索到服务
    */
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if error != nil {
            println(error)
            return
        }
        
        for  characteristic in service.characteristics  {
            //罗列出所有特性，看哪些是notify方式的，哪些是read方式的，哪些是可写入的。
            println("服务UUID:\(service.UUID)         特征UUID:\(characteristic.UUID)")
            //特征的值被更新，用setNotifyValue:forCharacteristic
            switch characteristic.UUID.description {
            case "FFE1":
                //如果以通知的形式读取数据，则直接发到didUpdateValueForCharacteristic方法处理数据。
                self.peripheral.setNotifyValue(true, forCharacteristic: characteristic as! CBCharacteristic)
            case "2A37":
                //通知关闭，read方式接受数据。则先发送到didUpdateNotificationStateForCharacteristic方法，再通过readValueForCharacteristic发到didUpdateValueForCharacteristic方法处理数据。
                self.peripheral.readValueForCharacteristic(characteristic as! CBCharacteristic)
            case "2A38":
                self.peripheral.readValueForCharacteristic(characteristic as! CBCharacteristic)
                
            case "Battery Level":
                self.peripheral.setNotifyValue(true, forCharacteristic: characteristic as! CBCharacteristic)
                
            case "Manufacturer Name String":
                self.peripheral.readValueForCharacteristic(characteristic as! CBCharacteristic)
                
            case "6E400003-B5A3-F393-E0A9-E50E24DCCA9E":
                self.peripheral.setNotifyValue(true, forCharacteristic: characteristic as! CBCharacteristic)
                
            case "6E400002-B5A3-F393-E0A9-E50E24DCCA9E":
                self.peripheral.readValueForCharacteristic(characteristic as! CBCharacteristic)
                self.writeCharacteristic = characteristic as! CBCharacteristic
                let heartRate: NSString = "ZhuHai XY"
                let dataValue: NSData = heartRate.dataUsingEncoding(NSUTF8StringEncoding)!
                //写入数据
                self.writeValue(service.UUID.description, characteristicUUID: characteristic.UUID.description, peripheral: self.peripheral, data: dataValue)
            default:
                break
            }
        }
        
        
        /*
        //        获取Characteristic的值，获取到走代理didUpdateValueForCharacteristic
        for characteristic in service.characteristics {
        peripheral.readValueForCharacteristic(characteristic as! CBCharacteristic)
        }
        //        搜索Characteristic的Descriptors，读到数据走代理didDiscoverDescriptorsForCharacteristic
        for characteristic in service.characteristics {
        peripheral.discoverDescriptorsForCharacteristic(characteristic as! CBCharacteristic)
        }
        */
    }
    /**
    获取的charateristic的值
    */
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        //打印characteristic的UUID和value
        //这里看数据类型 然后去解析
        println("UUID 和 data \(characteristic.UUID, characteristic.value)")
        
        switch characteristic.UUID.description {
        case "FFE1":
            println("=\(characteristic.UUID)特征发来的数据是:\(characteristic.value)=")
            
        case "2A37":
            println("=\(characteristic.UUID.description):\(characteristic.value)=")
            
        case "2A38":
            var dataValue: Int = 0
            characteristic.value.getBytes(&dataValue, range:NSRange(location: 0, length: 1))
            println("2A38的值为:\(dataValue)")
            
        case "Battery Level":
            //如果发过来的是Byte值，在Objective-C中直接.getBytes就是Byte数组了，在swift目前就用这个方法处理吧！
            var batteryLevel: Int = 0
            characteristic.value.getBytes(&batteryLevel, range:NSRange(location: 0, length: 1))
            println("当前为你检测了\(batteryLevel)秒！")
            
        case "Manufacturer Name String":
            //如果发过来的是字符串，则用NSData和NSString转换函数
            let manufacturerName: NSString = NSString(data: characteristic.value, encoding: NSUTF8StringEncoding)!
            println("制造商名称为:\(manufacturerName)")
            
        case "6E400003-B5A3-F393-E0A9-E50E24DCCA9E":
            println("=\(characteristic.UUID)特征发来的数据是:\(characteristic.value)=")
            
        case "6E400002-B5A3-F393-E0A9-E50E24DCCA9E":
            println("返回的数据是:\(characteristic.value)")
            
        default:
            break
        }
    }
    /**
    搜索到Characteristic的Descriptors
    */
    func peripheral(peripheral: CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        println(characteristic.UUID)
        for descriptor in characteristic.descriptors {
            println(descriptor.UUIDString)
        }
    }
    /**
    获取到Descriptors的值
    */
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForDescriptor descriptor: CBDescriptor!, error: NSError!) {
        println("\(descriptor.UUID, descriptor.value)")
    }
    
    //写入数据
    func writeValue(serviceUUID: String, characteristicUUID: String, peripheral: CBPeripheral!, data: NSData!){
        peripheral.writeValue(data, forCharacteristic: self.writeCharacteristic, type: CBCharacteristicWriteType.WithResponse)
        println("手机向蓝牙发送的数据为:\(data)")
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! UITableViewCell
        var device:CBPeripheral=self.deviceList.objectAtIndex(indexPath.row) as! CBPeripheral
        //主标题
        cell.textLabel?.text = device.name
        //副标题
        cell.detailTextLabel?.text = device.identifier.UUIDString
        return cell
        
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceList.count
    }
    
    //通过选择来连接和断开外设
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        if(self.peripheralList.containsObject(self.deviceList.objectAtIndex(indexPath.row))){
//            self.manager.cancelPeripheralConnection(self.deviceList.objectAtIndex(indexPath.row) as! CBPeripheral)
//            self.peripheralList.removeObject(self.deviceList.objectAtIndex(indexPath.row))
//            println("蓝牙已断开！")
//        }else{
//            self.manager.connectPeripheral(self.deviceList.objectAtIndex(indexPath.row) as! CBPeripheral, options: nil)
//            self.peripheralList.addObject(self.deviceList.objectAtIndex(indexPath.row))
//            println("蓝牙已连接！ \(self.peripheralList.count)")
//        }
    }
}

