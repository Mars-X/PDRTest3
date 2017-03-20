//
//  ViewController.swift
//  PDRtest3
//
//  Created by lixun on 2017/3/17.
//  Copyright © 2017年 lixun. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation

class ViewController: UIViewController,CLLocationManagerDelegate {
    
//MARK:IBOutlet
    @IBOutlet weak var Label_Distance: UILabel!
    @IBOutlet weak var Label_Heading: UILabel!
    @IBOutlet weak var TextView_Distance: UITextView!
    @IBOutlet weak var TextView_Heading: UITextView!
    @IBOutlet weak var Label_x: UILabel!
    @IBOutlet weak var Label_y: UILabel!
    
//MARK:全局变量、常量
    /////宏
    let HEADINGLIMIT = 50 //超过这个值时保存记录
    
    var currentPosition:CGPoint = CGPoint.init(x: 0, y: 0)
    
    /////////各种管理器
    var locationManage:CLLocationManager = CLLocationManager.init()
    let fileManager = FileManager.default
    let motionManager:CMMotionManager = CMMotionManager.init()
    
    ////////数据采集器
    let pedometer = CMPedometer.init()
    

    //////////////跟日期相关的对象
    let dateFormatter = DateFormatter.init()
    let calendar = Calendar.current
    var dateCom = DateComponents.init()
    var nowTime:Date? = nil
    var min5Time:Date? = nil
    
    //////////////让连续的航向显示变为离散所用到的对象
    static var changedValue = 0
    var currentHeading = 0.0
    var currentAcceleration:CMAcceleration? = CMAcceleration.init()

    
    //////两个TextView显示用到的数组
    var Arr_TV_Distance:[String] = []
    var Arr_TV_Heading:[String] = []
    var Str_TV_Distance:String? = ""
    var Str_TV_Heading:String? = ""
    
    
    //////文件存储路径
    let Str_FileSave_HomePathWithDocuments:String? = NSHomeDirectory() + "/Documents/"
    var Str_FileSave_fileName:String? = ""  //这个文件名可以设置为当前日期
    let Str_FileSave_suffix:String? = ".txt"
    var Str_FileSave_fullDirect:String? = ""    //用于存储文件最终生成的路径
    
    //////////////计时器
    var timer:Timer? = nil
    var Int_Timer_currentSecond = 0
    
    
//MARK:-
//MARK: 初始化函数
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        ///////////初始化VIEW
        self.Label_Distance.text = String(0.0)
        self.Label_Heading.text = String(0.0)
        self.TextView_Distance.text = "null"
        self.TextView_Heading.text = "null"
        self.Label_x.text = String(describing: currentPosition.x)
        self.Label_y.text = String(describing: currentPosition.y)
        
        /////////////////初始化管理器
//        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale.current
        
        ///////////////设置代理
        self.locationManage.delegate = self

        
        //////////输出测试语句
       // print(Str_FileSave_HomePathWithDocuments!)

    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

    
    //////开始更新Btn
    @IBAction func Btn_Action_Start(_ sender: Any) {
        if CMPedometer.isDistanceAvailable()
        {
            
            self.nowTime = Date()
            
            let tempSet:Set<Calendar.Component> = [Calendar.Component.year,Calendar.Component.month,Calendar.Component.day,Calendar.Component.hour,Calendar.Component.minute,Calendar.Component.second,Calendar.Component.nanosecond]
            //calendar.component(tempSet, from: Date())
            dateCom = calendar.dateComponents(tempSet, from: self.nowTime!)
            
            dateCom.second = dateCom.second! + 5 //减去5秒
            min5Time = calendar.date(from: dateCom)
            print("nowtime:\(self.nowTime!)")
            print("min5time:\(self.min5Time!)")
            
//            self.pedometer.queryPedometerData(from: nowTime!, to: min5Time!, withHandler: { (data, error) in
//                //每次启动都尝试计算当前减去5秒的时间段内行走的距离 怎样呢？ 这样 就不应该放到按钮响应事件里面了 应该创建一个计时器
//                self.Label_Distance.text = "\((data?.distance)!)" //刚开始 这里是没有值的 所以 似乎更应该先使用startUpdates来记录一些值？ 这里的疑问就是 是否distance连续时间记录 只是离散时间输出呢？ 还是这两者之间究竟有什么规律？
//            })//end of closure
            
           //MARK:开始更新计步器
//            self.pedometer.startUpdates(from: Date(), withHandler: { (data, error) in
//                if error != nil
//                {
//                    self.Label_Distance.text = "距离检测错误:\(error)"
//                }else{
//                    self.Label_Distance.text = "\((data?.distance)!)"       //注意 这里会是累积计算行走距离 因为是从按下按钮的当前时间开始的
////                    self.Str_TV_Distance = "\(self.dateFormatter.string(from: Date())) \(Int((data?.distance)!))米\n".appending(self.Str_TV_Distance!)
////                    self.TextView_Distance.text = self.Str_TV_Distance
//                }
//            })//end of closure
            if (self.timer == nil)
            {
                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
            }
            
            var tempQueue = OperationQueue.init()
            self.motionManager.startAccelerometerUpdates(to: tempQueue , withHandler: { (data, error) in
//                print((data?.acceleration.y)!)
               self.currentAcceleration = data?.acceleration //实时更新acceleration
            })
            
        }// end of if
        
        self.locationManage.startUpdatingHeading()
    }//end of action func
    
    
    //////停止更新Btn
    @IBAction func Btn_Action_Stop(_ sender: Any) {
        self.motionManager.stopAccelerometerUpdates()
//        self.pedometer.stopUpdates()
        self.locationManage.stopUpdatingHeading()
    }
    
    //MARK:-
    //MARK:代理方法
    ////////////以下是代理方法////////////////
    
    ///////航向更新时 UI如何处理
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.Label_Heading.text = "\(newHeading.trueHeading)"
        
        ViewController.changedValue += abs(Int(newHeading.trueHeading - self.currentHeading))
        
        if ViewController.changedValue > HEADINGLIMIT
        {
            Str_TV_Heading = "\(self.dateFormatter.string(from: Date())) \(Int(newHeading.trueHeading))º\n".appending(Str_TV_Heading!)
            
            self.TextView_Heading.text = Str_TV_Heading
 
            
            let tempDateFormate = dateFormatter.dateFormat
            dateFormatter.dateFormat = "yyyy-MM-dd"
            Str_FileSave_fileName = self.dateFormatter.string(from: Date())
            Str_FileSave_fullDirect = "\(Str_FileSave_HomePathWithDocuments!)\(Str_FileSave_fileName!)\(Str_FileSave_suffix!)"
            dateFormatter.dateFormat = tempDateFormate
//            print("测试最终生成的文件路径\(Str_FileSave_fullDirect!)")
            
            do{
            try! Str_TV_Heading?.write(toFile: Str_FileSave_fullDirect!, atomically: true, encoding: .utf8)
            }catch{ }
            
            ViewController.changedValue = 0
        }
        self.currentHeading = newHeading.trueHeading
    }
    
//    func calculation() -> CGPoint {
////        currentPosition.
//        
//    }
    
    //MARK:-
    //MARK:自定义方法
    func timerAction()
    {
//        print("1")
//        self.Int_Timer_currentSecond = self.Int_Timer_currentSecond + 1
        self.Label_x.text = "\(Int((currentAcceleration!.z)))"
        self.Label_y.text = "\(Int((currentHeading)))"

    }
    
}

