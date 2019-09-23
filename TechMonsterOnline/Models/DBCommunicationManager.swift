//
//  DBCommunicationManager.swift
//  TechMonsterOnline
//
//  Created by 大林拓実 on 2019/09/21.
//  Copyright © 2019 大林拓実. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import Ballcap

final class DBCommunicatoinManager {
   
    static func anonymousLogIn(_ completionHandler: @escaping ((Document<Player>?) -> Void)) {
        
        // 匿名ログイン
        Auth.auth().signInAnonymously{ (auth, error) in
            if let error = error {
                print(error.localizedDescription)
                completionHandler(nil)
                return
            }
            
            guard let currentPlayer = Auth.auth().currentUser else {
                completionHandler(nil)
                return
            }
            
            // 初回ログインの場合ドキュメントを新規生成
            Document<Player>.get(id: currentPlayer.uid){(player, _) in
                if let player = player {
                    print("Success login of an existing user")
                    completionHandler(player)
                } else {
                    let u: Document<Player> = Document(id: auth!.user.uid)
                    u.save(completion: { _ in
                        print("Success login of a new user")
                        completionHandler(u)
                    })
                }
            }
            
            // 自身のIDをシングルトンに記録
            MyPlayer.sharedInstance.playerId = currentPlayer.uid
            
        }
    }
    
    // 対戦相手受付
    static func WaitingForMatch() {
        
    }

}

