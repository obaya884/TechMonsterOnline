//
//  MyPlayer.swift
//  TechMonsterOnline
//
//  Created by 大林拓実 on 2019/09/21.
//  Copyright © 2019 大林拓実. All rights reserved.
//

import Foundation
import UIKit

class MyPlayer: NSObject {
    
    //  マッチング記録用
    var playerId: String = ""
    var opponentPlayerId: String = ""

    // バトル制御
    var isPlayerAttackAvailable: Bool = false
    var isRecoverPlayerMP: Bool = true
    var isRisePlayerTP: Bool = true

    var attackPoint: Int = 30
    var specialAttackPoint: Int = 80
    
    class var sharedInstance: MyPlayer {
        struct Static {
            static let instance : MyPlayer = MyPlayer()
        }
        return Static.instance
    }
    
}
