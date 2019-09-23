//
//  LobbyViewController.swift
//  TechMonsterOnline
//
//  Created by 大林拓実 on 2019/09/10.
//  Copyright © 2019 大林拓実. All rights reserved.
//

import UIKit
import Firebase
import Ballcap
import NVActivityIndicatorView

final class LobbyViewController: UIViewController {
    
    @IBOutlet private var nameLabel: UILabel!
    
    private let techMonManager = TechMonManager.shared
    private var opponentPlayerId: String = ""
    
    private var waitingListener: ListenerRegistration?
    private var searchingListener: ListenerRegistration?

    // UIブロッカー
    let activityData = ActivityData(size: nil, message: nil, messageFont: nil, messageSpacing: nil, type: .ballSpinFadeLoader, color: .white, padding: 0, displayTimeThreshold: nil, minimumDisplayTime: nil, backgroundColor: .clear, textColor: .white)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = "勇者"
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        techMonManager.playBGM(fileName: "lobby")
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        techMonManager.stopBGM()
    }
    
    
    @IBAction func waitingButtonTapped() {
        let db = Firestore.firestore().document("version/1")
        let playerRef = db.collection("player")
        
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(activityData)
        NVActivityIndicatorPresenter.sharedInstance.setMessage("待機中")

        // isWaitingをtrueにする
        playerRef.document(MyPlayer.sharedInstance.playerId)
            .setData(["isWaiting":true], merge: true)

        
        self.waitingListener =
            playerRef.document(MyPlayer.sharedInstance.playerId)
                .addSnapshotListener { documentSnapshot, error in
                    guard let document = documentSnapshot else {
                        print("Error fetching document: \(error!)")
                        return
                    }
                    guard let data = document.data() else {
                        print("Document data was empty.")
                        return
                    }
                    print("listening")
                    
                    if let opponentPlayerIdData = data["opponentPlayerId"] {
                        self.opponentPlayerId = opponentPlayerIdData as! String
                    }
                    print(self.opponentPlayerId)

                    playerRef.document(self.opponentPlayerId)
                        .getDocument{ (document, error) in
                            if let document = document, document.exists {
                                print("User \(self.opponentPlayerId) Exist")
                                NVActivityIndicatorPresenter.sharedInstance.setMessage("対戦相手が見つかりました")

                                playerRef.document(self.opponentPlayerId)
                                    .setData(["opponentPlayerId" : MyPlayer.sharedInstance.playerId], merge: true){ err in
                                        if let err = err {
                                            print("Error writing document: \(err)")
                                            return
                                        } else {
                                            print("Document successfully written!@\(String(describing: data["opponentPlayerId"]))")
                                            self.goToBattleView()
                                        }
                                }
                            } else {
                                print("User \(self.opponentPlayerId) Does not exist")
                            }
                    }
        }
    }
    
    @IBAction func searchingButtonTapped(){
        let db = Firestore.firestore().document("version/1")
        let playerRef = db.collection("player")
        var playablePlayersArray: [String] = []
        
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(activityData)
        NVActivityIndicatorPresenter.sharedInstance.setMessage("検索中")

        // 対戦可能相手をクエリ検索
        playerRef
            .whereField("isLogined", isEqualTo: true)
            .whereField("isWaiting", isEqualTo: true)
            .getDocuments(){ (querySnapshot, err) in
                if let err = err {
                    print("Error Getting documents \(err)")
                    return
                } else {
                    
                    for document in querySnapshot!.documents {
                        if document.documentID != MyPlayer.sharedInstance.playerId {
                            playablePlayersArray.append(document.documentID)
                        }
                    }
                    
                    // 対戦可能相手が存在する場合
                    if playablePlayersArray.count != 0 {
                        // 申し込み相手決定
                        let randomIndex = Int(arc4random_uniform(UInt32(playablePlayersArray.count)))
                        self.opponentPlayerId = playablePlayersArray[randomIndex]
                    } else {
                        NVActivityIndicatorPresenter.sharedInstance.setMessage("対戦可能なプレイヤーが見つかりませんでした")
                        NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
                        return
                    }
                }
                
                // 相手に自身のIDを書き込む
                playerRef.document(self.opponentPlayerId)
                    .setData(["opponentPlayerId" : MyPlayer.sharedInstance.playerId], merge: true){ err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!@\(self.opponentPlayerId)")
                            NVActivityIndicatorPresenter.sharedInstance.setMessage("対戦相手が見つかりました")
                        }
                
                    // 申し込み相手の応答監視
                        self.searchingListener = playerRef.document(MyPlayer.sharedInstance.playerId)
                        .addSnapshotListener { documentSnapshot, error in
                            guard let document = documentSnapshot else {
                                print("Error fetching document: \(error!)")
                                return
                            }
                            guard let data = document.data() else {
                                print("Document data was empty.")
                                return
                            }
                            print("listening")
                            if data["opponentPlayerId"] as! String == self.opponentPlayerId {
                                self.goToBattleView()
                            }
                            else {
                                print("not matching...")
                            }
                    }
                }
        }
    
    }
    
    func goToBattleView() {
        NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
        // 対戦相手のIDをシングルトンに記録
        MyPlayer.sharedInstance.opponentPlayerId = opponentPlayerId
        print("Matched!")
        searchingListener?.remove()
        waitingListener?.remove()
        
        // isWaitingをfalseにする
        let db = Firestore.firestore().document("version/1")
        let playerRef = db.collection("player")
        playerRef.document(MyPlayer.sharedInstance.playerId)
            .setData(["isWaiting":false], merge: true)

        // バトル画面に遷移
        self.performSegue(withIdentifier: "toBattleViewControllerSegue", sender: nil)
    }
    
}
