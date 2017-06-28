//
//  LXKalman.swift
//  testSingleKalman
//
//  Created by MarsX on 2017/6/26.
//  Copyright © 2017年 MarsX. All rights reserved.
//

import Foundation

class LXKalman:NSObject {
    var X:Double = 0.0 //状态
    var K:Double = 0.5 //卡尔曼增益
    var Q:Double = 1.0 //过程噪音协方差
    var R:Double = 1.0 //测量噪音协方差
    var P:Double = 0.8 // 方差？但实话说 暂时不知道这个值是谁
    var P_post:Double = 0.0 //
    
    var z:Double = 0.0 //观测值
    var a:Double = 0.5 //参数A
    var b:Double = 0.5 //参数B
    
   init(Q q:Double,R r:Double,X0 x0:Double,P0 p0:Double)
    {
       
        self.Q = q
        self.R = r
        self.X = x0
        self.P = p0
        self.K = 0
        self.P_post = p0
    }
    

    func filterStep(Observation observation:Double)->Double
    {
        //预测
        //预测阶段的x公式应该引入雅可比矩阵 但是这里还没有用到矩阵方法。
        self.P = self.P_post
        
        //更新
        self.K = self.P/(self.P+self.R)
        self.X = self.X + self.K*(observation - self.X)
        self.P_post = self.P
        self.P = (1-self.K)*self.P + self.Q
        
        return self.X
    }
    
    
}
