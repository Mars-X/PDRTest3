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
    @IBOutlet weak var Label_StepCount: UILabel!
    @IBOutlet weak var TextView_Debug: UITextView!
    
//MARK:全局变量、常量
    /////宏
    let HEADINGLIMIT = 50 //超过这个值时保存记录
    let TIMEINTERVAL = 0.2    //获取数据的时间间隔
    let STEPTIME = 0.6//方法2：0.6//方法1：3.0  //1.65??
    
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
    var calHeading = 0.0
    var lastHeading = 0.0
    var firstRun = true
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
    var timerForStepCount:Timer? = nil
    
    //全局变量
    var calACC:Double = 0.0
    var stepCount:Int = 0
    var calACC_Array:[Double] = [Double]()
    var calHeading_Array:[Double] = [Double]()
    /////////////后台运行相关
    var backID = UIBackgroundTaskInvalid
    var aa = 0
    
//    var bgTaskIdList : NSMutableArray?  //
    var bgTaskIdList :[UIBackgroundTaskIdentifier]? = []
    var bgTaskIdList2:NSMutableArray = NSMutableArray.init()
    var masterTaskId : UIBackgroundTaskIdentifier? = UIBackgroundTaskInvalid
    var timerForBG:Timer? = nil
    var timerForBGDelay10second:Timer? = nil
    
    struct coornidate {
        var x:Double = 0.0
        var y:Double = 0.0
    }
    
    var localCoornidate : coornidate = coornidate()
    
    struct coornidate_sign{ //这个结构体用来表示符号
        var x_sign:Bool = false
        var y_sign:Bool = false //false表示负的
    }
    
    var coornidateSign :coornidate_sign = coornidate_sign()
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
        
        //////////////授权
        self.locationManage.requestAlwaysAuthorization()
        
        self.locationManage.pausesLocationUpdatesAutomatically = false
        self.locationManage.allowsBackgroundLocationUpdates = true
//        
//        self.locMgr.pausesLocationUpdatesAutomatically=NO;
//        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
//            //[_locationManager requestWhenInUseAuthorization];
//            [self.locMgr requestAlwaysAuthorization];
//        }
//        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9) {
//            self.locMgr.allowsBackgroundLocationUpdates = YES;
//        }
        
        
        /////////////////初始化管理器
//        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale.current
        
        
        
        ///////////////设置代理
        self.locationManage.delegate = self


        
        ///////////////后台运行
        NotificationCenter.default.addObserver(self, selector: Selector("applicationEnterBackground"), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        self.locationManage.startUpdatingLocation()

        //////////输出测试语句
       // print(Str_FileSave_HomePathWithDocuments!)
//        testPrint()
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
                //MARK:计步器时间
                timerForStepCount = Timer.scheduledTimer(timeInterval: TimeInterval(self.STEPTIME), target: self, selector: #selector(timerActionForStepCount), userInfo: nil, repeats: true)
                
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
//                self.currentHeading = newHeading.trueHeading //- 25 //把newHeading传出去 让currentHeading作为当前方向
        //注意上面的25是在课题室做实验的补偿 为了好计算距离坐标 不能在这里补偿
        
//        如果拿在手上 可以直接让self.currentHeading = newHeading.trueHeading
// 这个补偿180 是放在口袋里 并且是几乎横着放的
        if newHeading.trueHeading < 180 {
            self.currentHeading = 360.0 + newHeading.trueHeading - 180.0
        }
        else
        {
             self.currentHeading = newHeading.trueHeading - 180.0
        }
//        self.currentHeading = (newHeading.trueHeading - 90).truncatingRemainder(dividingBy: 360)
        self.calHeading_Array.append(self.currentHeading)
        
//        if firstRun{
//            var timerForDelay3Seconds = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(Delay3Seconds), userInfo: nil, repeats: false)
//            lastHeading
//        firstRun = false
//        }
    }
    
//    func Delay3Seconds()
//    {
//        //啥也不执行 只是为了静静地度过你人生中的三秒钟而已
//    }
//    
   
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSLog("调用location的update方法")
        
        
        if self.timerForBG != nil {
            return
        }
        
        self.actBackground()
        
        self.timerForBG = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(restartUpdating), userInfo: nil, repeats: false)
        
       if self.timerForBGDelay10second != nil
        {
            self.timerForBGDelay10second?.invalidate()
            self.timerForBGDelay10second = nil
        }
        
        self.timerForBGDelay10second = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(stopUpdating), userInfo: nil, repeats: false)
    }
    
    
    //MARK:-
    //MARK:自定义方法
    
    func stopUpdating()
    {

//        if timerForBG != nil {
//            timerForBG?.invalidate()
//            timerForBG = nil
//        }
        
        self.locationManage.stopUpdatingLocation()
        NSLog("locationManager stop Updating after 10 seconds");
//        timer?.invalidate()
//        timer = nil
//        timerForBG?.invalidate()
//        timerForBG = nil
//        timerForStepCount?.invalidate()
//        timerForStepCount = nil
//        timerForBGDelay10second?.invalidate()
//        timerForBGDelay10second = nil
    }
    
    func restartUpdating()
    {
        if timerForBG != nil {
            timerForBG?.invalidate()
            timerForBG = nil
        }
        
        self.locationManage.startUpdatingLocation()
    }
    
    
    func timerAction()
    {
//        print("1")
//        self.Int_Timer_currentSecond = self.Int_Timer_currentSecond + 1
//        self.Label_x.text = "\(Int((currentAcceleration!.z)))"
//        self.Label_y.text = "\(Int((currentHeading)))"
        
//        self.Label_x.text = "\((currentAcceleration!.z).format(f: ".2"))
//        self.Label_y.text = "\((currentHeading).format(f: ".2"))"
        
        
        pow(currentAcceleration!.z,2.0)
        pow(currentAcceleration!.x,2.0)
        pow(currentAcceleration!.y,2.0)
        //只用z轴改成求模
        calACC = 9.8 * sqrt(pow(currentAcceleration!.z,2.0) + pow(currentAcceleration!.x,2.0) + pow(currentAcceleration!.y,2.0))
        calACC_Array.append(calACC)

        
        
        self.TextView_Distance.text = "\((calACC).format(f: ".2"))\n".appending(self.TextView_Distance.text)
        
//        if ViewController.changedValue > HEADINGLIMIT  ////////这个是用来控制变动范围的 目前暂时弃用
//        {                                                                               ////////这个是用来控制变动范围的 目前暂时弃用
            Str_FileSave_singleItem = "\(self.dateFormatter.string(from: Date())) || \(currentHeading.format(f: ".2"))º || \((calACC).format(f: ".2"))\n" //调整单条记录格式
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

        
        
        
        /////MARK:-
 
        
        /////MARK:-
        
        
    }
    
    //MARK: 计步器时间函数
    /////方法1
    func timerActionForStepCount()
    {
        var switch_Step = true //计步的开关 设想就是每3秒大概走1步 不能再多了？
        var countStep_thisloop = 0
        var currentSub = 0.0//相隔几个
        var last = 9.8
        if Double(calACC_Array.count) >= STEPTIME*5.0
        {
            var current = calACC_Array[0]


//            print("可以分析了cout:\(calACC_Array.count)")
//            var max = calACC_Array[0]
//            var min = calACC_Array[0]
            var i = 0
            while i < calACC_Array.count
            {
                current = calACC_Array[i]
                
                if (current - last > 2.5)//&&(countStep_thisloop < 10) //每3秒最多走3步
                {
                    stepCount += 1
                    countStep_thisloop += 1
                    print("走了\(stepCount)步")
                    //                    var distanceCount = stepCount *
                    Label_StepCount.text = "走了\(stepCount)步,行走共计约\(Double(stepCount)*0.45)米"
                    
                    //MARK- 不知道读数中的0°怎么来的 并且可能导致前计步的行走距离是错误的
//                    currentHeading += 25//补偿25°
                    if abs(currentHeading - lastHeading) > 10.0 {
                        //航向偏移了超过10° 需要重新判断方向
//                        if currentHeading > (0.0 * M_PI )/180.0 && currentHeading <= (90.0 * M_PI)/180.0
                      if currentHeading > 0.0 && currentHeading <= 90.0
                        {
                            calHeading = currentHeading
                            coornidateSign.x_sign = true
                            coornidateSign.y_sign = true
//                            TextView_Debug.text.append("0 < currentHeading < 90")
//                        }else if currentHeading > (90 * M_PI )/180.0 && currentHeading <= (180.0 * M_PI)/180.0
                        }else if currentHeading > 90.0 && currentHeading <= 180.0
                        {
                            calHeading = 180.0 - currentHeading
                            coornidateSign.x_sign = true
                            coornidateSign.y_sign = false
//                            TextView_Debug.text.append("90 < currentHeading < 180")
//                        }else if currentHeading > (180.0 * M_PI )/180.0 && currentHeading <= (270.0 * M_PI)/180.0
                        }else if currentHeading > 180.0 && currentHeading <= 270.0
                        {
                            calHeading = currentHeading - 180.0
                            coornidateSign.x_sign = false
                            coornidateSign.y_sign = false
//                            TextView_Debug.text.append("180 < currentHeading < 270")
//                        }else if currentHeading > (270.0 * M_PI )/180.0 && currentHeading <= (360.0 * M_PI)/180.0
                        }else if currentHeading > 270.0 && currentHeading <= 360.0
                        {
                            calHeading = 360.0 - currentHeading
                            coornidateSign.x_sign = false
                            coornidateSign.y_sign = true
//                            TextView_Debug.text.append("270 < currentHeading < 360")
                        }
                    }

                    calHeading = (calHeading * M_PI)/180.0
                    if coornidateSign.x_sign {
                        self.localCoornidate.x += sin(calHeading) * 0.45
                    }else
                    {
                        self.localCoornidate.x -= sin(calHeading)  * 0.45
                    }
                    
                    if coornidateSign.y_sign {
                        self.localCoornidate.y += cos(calHeading) * 0.45
                    }else
                    {
                        self.localCoornidate.y -= cos(calHeading) * 0.45
                    }
                    lastHeading = currentHeading
                    Label_x.text = "\(self.localCoornidate.x.format(f: ".2"))"
                    Label_y.text = "\(self.localCoornidate.y.format(f: ".2"))"
                    
                    print("current:\(current.format(f: ".2")),last:\(last.format(f: ".2"))")
                    //                    switch_Step = false
                }
                //                last = current
//                if i > 10
//                {
//                    last = calACC_Array[i-10]
//                    
//                }
                i += 1
                
            }
            
//            for item in calACC_Array
//            {
//                current = item

//                if (current - last > 2.5)//&&(countStep_thisloop < 10) //每3秒最多走3步
//                {
//                    stepCount += 1
//                    countStep_thisloop += 1
//                    print("走了\(stepCount)步")
////                    var distanceCount = stepCount *
//                    Label_StepCount.text = "走了\(stepCount)步,大概\(Double(stepCount)*0.45)米"
//                    
//                    Label_x.text = "\(self.localCoornidate.x+0.45)"
//                    Label_y.text = "\(self.localCoornidate.y+0.45)"
////                    switch_Step = false
//                }
////                last = current

//            }
//            switch_Step = true
            countStep_thisloop = 0

            calACC_Array.removeAll()
            
        }
        
        
    }
    
//        /////方法2
//        func timerActionForStepCount()
//        {
//            if Double(calACC_Array.count) > STEPTIME * 5.0
//            {
//                var current = calACC_Array[0]
//                var last = calACC_Array[0]
//                var i = 0.0
//                while i < STEPTIME * 5.0
//                {
//                    if calACC_Array[Int(i)] > 1.0 || calACC_Array[Int(i)] < -0.8
//                    {
//                            stepCount += 1
//                            Label_StepCount.text = "走了\(stepCount)步,大概\(Double(stepCount)*0.45)米"
//        
//                            Label_x.text = "\(self.localCoornidate.x+0.45)"
//                            Label_y.text = "\(self.localCoornidate.y+0.45)"
//                        break
//                    }
//                }
//                calACC_Array.removeAll()
//            }
//        }
    func applicationEnterBackground() {
        NSLog("已进入后台")
        self.locationManage.startUpdatingLocation()//
        
       self.actBackground()
        
//        if timerForBG == nil {
//            timerForBG = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(go), userInfo: nil, repeats: true)
//        }

        
    }
    
    //MARK: 判断方向针对坐标应该加还是减
//    func chooseSignForCoornidate()
//    {
//        coornidateSign.x_sign
//        coornidateSign.y_sign
//    }
    
//    func go()
//    {
//        //        NSLog("%@ == %d", Date(),aa)
//        print("\(Date())==\(aa)")
//        aa += 1
//    }
    
    func actBackground() {
        //        print("执行了这个进入后台的方法 但是没有开始计时")//如果不申请下面的后台执行 那么很快就结束了
        /*
         backID = UIApplication.shared.beginBackgroundTask {
         NSLog("进入后台")

         //            self.timer?.invalidate()
         //            self.timer = nil
         //            if (self.timer == nil)
         //            {
         ////                NSLog("开始了新的计时器")
         //                self.Label_x.text = "开始了新的计时器"
         //                self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.TIMEINTERVAL), target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
         //            }
         
         //            UIApplication.shared.endBackgroundTask(self.backID)
         
         //            self.backID = UIBackgroundTaskInvalid
         //            self.                      timer = nil
         }
         
         if timerForBG == nil {
         timerForBG = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(go), userInfo: nil, repeats: true)
         }
         
         
         }
         
         func go()
         {
         //        NSLog("%@ == %d", Date(),aa)
         print("\(Date())==\(aa)")
         aa += 1
         }
         */
        
        
        //        print("开始了新的后台时间")
        
        
        //        if timerForBG == nil {
        //            timerForBG = Timer.scheduledTimer(timeInterval: 120, target: self, selector: #selector(applicationEnterBackground), userInfo: nil, repeats: true)
        //        }
        
        let application : UIApplication = UIApplication.shared
        var bgTaskId : UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
//        NSLog("%@", bgTaskId)
        //        self.locationManage.startUpdatingLocation()

//        if application.responds(to: Selector("beginBackgroundTaskWithExpirationHandler")){
//            if application.responds(to: #selector("beginBackgroundTask(expirationHandler:)") {
//            print("RESPONDS TO SELECTOR")

        
        

        
        
            bgTaskId = application.beginBackgroundTask(expirationHandler: {
                print("background task \(bgTaskId as Int) expired\n")
//                 self.bgTaskIdList?.remove(at: bgTaskId)
//                self.bgTaskIdList2.removeObject(at: bgTaskId)
//                self.bgTaskIdList?.remove(at: bgTaskId)
//                self.bgTaskIdList?.removeFirst()                        //这里面 就没打算让它执行。
                application.endBackgroundTask(bgTaskId)
                bgTaskId = UIBackgroundTaskInvalid;
            })
//        }
        
        if self.masterTaskId == UIBackgroundTaskInvalid {
            self.masterTaskId = bgTaskId
            print("started master task \(self.masterTaskId!)\n")    //这个就计划执行以此 把第一次的task存入master中
        } else {
            // add this ID to our list
            print("started background task \(bgTaskId as Int)\n")
            self.bgTaskIdList!.append(bgTaskId)
//            self.bgTaskIdList2.add(bgTaskId)
            //self.endBackgr
            //////////////////////
            self.endBackgroundTasks()
//        }
        
//        if (self.timer == nil)
//        {
//            NSLog("这里似乎没有执行")
//            self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.TIMEINTERVAL), target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
//        }
            
    }
}
    
    func endBackgroundTasks() {
        self.drainBGTaskList(all: false)
    }
    
    
    func drainBGTaskList(all:Bool)
    {
        let application:UIApplication = UIApplication.shared
//        if application .responds(to: #selector(endBackgroundTasks)) {
            let count = self.bgTaskIdList?.count
//            var count = self.bgTaskIdList2.count
            var i = 1 //x先只考虑False的情况
            while i < count! {
//                var bgTaskId:UIBackgroundTaskIdentifier = Int(self.bgTaskIdList![0])
                let bgTaskId:UIBackgroundTaskIdentifier = (self.bgTaskIdList![0] as AnyObject).intValue
                NSLog("ending background task with id %lu", bgTaskId)
                application.endBackgroundTask(bgTaskId)
//                bgTaskIdList?.remove(at: 0)
                bgTaskIdList?.removeFirst()
                
//                bgTaskIdList2.removeObject(at: 0)
                i += 1
            }
            
            if (self.bgTaskIdList?.count)! > 0 {
//                NSLog("kept background task id %@", self.bgTaskIdList![0]);
                print("kept background task id \(self.bgTaskIdList![0])")
            }
            
            
            NSLog("kept master background task id %lu", self.masterTaskId!);

            
//        }
    }


    
}//end of class

