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
    let TIMEINTERVAL = 0.2    //获取数据的时间间隔
    
    var currentPosition:CGPoint = CGPoint.init(x: 0, y: 0)
    
    /////////运动检测相关
    var locationManage:CLLocationManager = CLLocationManager.init()
    let motionManager:CMMotionManager = CMMotionManager.init()

    ///////////文件操作相关
    let fileManager = FileManager.default
    var fileHandle:FileHandle? = nil
    
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
    var Str_FileSave_singleItem:String? = ""    //保存构造的单独一条记录 可以在文件追加时候直接保存进去就好了
    
    //////////////计时器
    var timer:Timer? = nil
    var Int_Timer_currentSecond = 0
    
    /////////////后台运行相关
    var backID = UIBackgroundTaskInvalid
    
    
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

        ///////////////后台运行
        NotificationCenter.default.addObserver(self, selector: Selector("applicationEnterBackground"), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
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
                timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.TIMEINTERVAL), target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
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
//        self.pedometer.stopUpdates()//暂时弃用 因为不再使用ios sdk提供的距离测量
        self.locationManage.stopUpdatingHeading()
        self.timer?.invalidate()
        self.timer = nil
        
    }
    
    //MARK:-
    //MARK:代理方法
    ////////////以下是代理方法////////////////
    
    ///////航向更新时 UI如何处理
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.Label_Heading.text = "\(newHeading.trueHeading)"
        
//        ViewController.changedValue += abs(Int(newHeading.trueHeading - self.currentHeading))  ////////这个是用来控制变动范围的 目前暂时弃用
                self.currentHeading = newHeading.trueHeading //把newHeading传出去 让currentHeading作为当前方向
    }
    
    //MARK:-
    //MARK:自定义方法
    func timerAction()
    {
//        print("1")
//        self.Int_Timer_currentSecond = self.Int_Timer_currentSecond + 1
//        self.Label_x.text = "\(Int((currentAcceleration!.z)))"
//        self.Label_y.text = "\(Int((currentHeading)))"
        
//        self.Label_x.text = "\((currentAcceleration!.z).format(f: ".2"))
//        self.Label_y.text = "\((currentHeading).format(f: ".2"))"
        
        self.TextView_Distance.text = "\((currentAcceleration!.z).format(f: ".2"))\n".appending(self.TextView_Distance.text)
        
//        if ViewController.changedValue > HEADINGLIMIT  ////////这个是用来控制变动范围的 目前暂时弃用
//        {                                                                               ////////这个是用来控制变动范围的 目前暂时弃用
            Str_FileSave_singleItem = "\(self.dateFormatter.string(from: Date())) || \(currentHeading.format(f: ".2"))º || \((currentAcceleration!.z).format(f: ".2"))\n" //调整单条记录格式
            Str_TV_Heading = Str_FileSave_singleItem!.appending(Str_TV_Heading!)  //可以通过种类来调节倒序还是正序显示
            
            self.TextView_Heading.text = Str_TV_Heading
            
            let tempDateFormate = dateFormatter.dateFormat
            dateFormatter.dateFormat = "yyyy-MM-dd"
            Str_FileSave_fileName = self.dateFormatter.string(from: Date())
            Str_FileSave_fullDirect = "\(Str_FileSave_HomePathWithDocuments!)\(Str_FileSave_fileName!)\(Str_FileSave_suffix!)"
            dateFormatter.dateFormat = tempDateFormate
            //            print("测试最终生成的文件路径\(Str_FileSave_fullDirect!)")
            
            do{ //添加了文件读写时用到的追加模式
                if !fileManager.fileExists(atPath: Str_FileSave_fullDirect!) {
                    try! Str_TV_Heading?.write(toFile: Str_FileSave_fullDirect!, atomically: true, encoding: .utf8)
                }else
                {
                    try!  fileHandle = FileHandle.init(forUpdating: URL.init(string: Str_FileSave_fullDirect!)!)
                    fileHandle?.seekToEndOfFile()
                    let tempData = Str_FileSave_singleItem!.data(using: .utf8)
                    fileHandle?.write(tempData!)
                    fileHandle?.closeFile()
                }
                
            }catch{ }
            
//            ViewController.changedValue = 0  ////////这个是用来控制变动范围的 目前暂时弃用
//        }                                                       ////////这个是用来控制变动范围的 目前暂时弃用

        
        

    }
 
    func applicationEnterBackground() {
//        print("执行了这个进入后台的方法 但是没有开始计时")//如果不申请下面的后台执行 那么很快就结束了
        
        backID = UIApplication.shared.beginBackgroundTask {
            NSLog("进入后台")
           
            self.timer?.invalidate()
            self.timer = nil
            if (self.timer == nil)
            {
//                NSLog("开始了新的计时器")
                self.Label_x.text = "开始了新的计时器"
                self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.TIMEINTERVAL), target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
            }

//            self.timerAction()
            //            UIApplication.shared.endBackgroundTask(self.backID)
            
            //            self.backID = UIBackgroundTaskInvalid
            //            self.                      timer = nil
        }
    }
    
    
}

