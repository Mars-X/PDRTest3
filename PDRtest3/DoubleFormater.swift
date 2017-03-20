//
//  DoubleFormater.swift
//  PDRtest3
//
//  Created by lixun on 2017/3/20.
//  Copyright © 2017年 lixun. All rights reserved.
//

import Foundation

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}
