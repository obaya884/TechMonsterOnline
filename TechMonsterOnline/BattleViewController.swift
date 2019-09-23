//
//  BattleViewController.swift
//  TechMonsterOnline
//
//  Created by 大林拓実 on 2019/09/10.
//  Copyright © 2019 大林拓実. All rights reserved.
//

import UIKit
import Firebase
import Ballcap
import NVActivityIndicatorView

final class BattleViewController: UIViewController {

    private var enemyAttackTimer: Timer!
    let db = Firestore.firestore().document("version/1")

    @IBOutlet private var attackButton: UIButton!
    @IBOutlet private var chargeButton: UIButton!
    @IBOutlet private var magicButton: UIButton!

    @IBOutlet private var playerNameLabel: UILabel!
    @IBOutlet private var playerImageView: UIImageView!
    @IBOutlet private var playerHPLabel: UILabel!
    @IBOutlet private var playerMPLabel: UILabel!
    @IBOutlet private var playerTPLabel: UILabel!

    @IBOutlet private var opponentNameLabel: UILabel!
    @IBOutlet private var opponentImageView: UIImageView!
    @IBOutlet private var opponentHPLabel: UILabel!
    @IBOutlet private var opponentMPLabel: UILabel!
    @IBOutlet private var opponentTPLabel: UILabel!

    private let techMonManager = TechMonManager.shared
    private var gameTimer = Timer()
    
    private var myPlayerListener: ListenerRegistration?
    private var opponentPlayerListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerNameLabel.text = "勇者"
        playerImageView.image = UIImage(named: "yusya.png")
        opponentNameLabel.text = "ドラゴン"
        opponentImageView.image = UIImage(named: "monster.png")        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        techMonManager.playBGM(fileName: "BGM_battle001")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        battleListen()
        gameTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(recoverPlayerMP), userInfo: nil, repeats: true)
        gameTimer.fire()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        techMonManager.stopBGM()
    }
    
    @objc func recoverPlayerMP() {
        let playerRef = db.collection("player")

        if MyPlayer.sharedInstance.isRecoverPlayerMP {
            playerRef.document(MyPlayer.sharedInstance.playerId)
                .setData(["currentMP" : FieldValue.increment(Int64(1))], merge: true)
        }
    }

    func battleListen() {
        let playerRef = db.collection("player")
        
        // 自身のステータス監視
        self.myPlayerListener = playerRef.document(MyPlayer.sharedInstance.playerId)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                
                // 勝敗判定（プレイヤー敗北）
                if (data["currentHP"] as! Int) <= 0 {
                    self.finishBattle(vanishImageView: self.playerImageView, isPlayerWin: false)
                }
                
                // MP回復可否判定
                if data["currentMP"] as! Int >= data["maxMP"] as! Int {
                    MyPlayer.sharedInstance.isRecoverPlayerMP = false
                }
                else {
                    MyPlayer.sharedInstance.isRecoverPlayerMP = true
                }
                
                // TP上昇可否判定
                if data["currentTP"] as! Int >= data["maxTP"] as! Int {
                    MyPlayer.sharedInstance.isRisePlayerTP = false
                    // currentが上限超えてたら上限に戻す
                    playerRef.document(MyPlayer.sharedInstance.playerId)
                        .setData(["currentTP" : data["maxTP"] as Any], merge: true)
                }
                else {
                    MyPlayer.sharedInstance.isRisePlayerTP = true
                }

                // UI更新メソッドの呼び出し
                self.updateMyPlayerStatus(currentHP: data["currentHP"] as! Int,
                                                currentMP: data["currentMP"] as! Int,
                                                currentTP: data["currentTP"] as! Int,
                                                maxHP: data["maxHP"] as! Int,
                                                maxMP: data["maxMP"] as! Int,
                                                maxTP: data["maxTP"] as! Int)
        }
        
        // 対戦相手のステータス監視
        self.opponentPlayerListener = playerRef.document(MyPlayer.sharedInstance.opponentPlayerId)
            .addSnapshotListener{ documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                
                // 勝敗判定（プレイヤー敗北）
                if (data["currentHP"] as! Int) <= 0 {
                    self.finishBattle(vanishImageView: self.opponentImageView, isPlayerWin: true)
                }

                // UI更新メソッドの呼び出し
                self.updateOpponentPlayerStatus(currentHP: data["currentHP"] as! Int,
                                           currentMP: data["currentMP"] as! Int,
                                           currentTP: data["currentTP"] as! Int,
                                           maxHP: data["maxHP"] as! Int,
                                           maxMP: data["maxMP"] as! Int,
                                           maxTP: data["maxTP"] as! Int)
            }
    }
    
    func updateMyPlayerStatus(currentHP: Int, currentMP: Int, currentTP: Int, maxHP: Int, maxMP: Int, maxTP: Int){
        playerHPLabel?.text = "\(currentHP) / \(maxHP)"
        playerMPLabel?.text = "\(currentMP) / \(maxMP)"
        playerTPLabel?.text = "\(currentTP) / \(maxTP)"
    
        // 攻撃可否判定
        if currentMP >= 20 {
            MyPlayer.sharedInstance.isPlayerAttackAvailable = true
        } else {
            MyPlayer.sharedInstance.isPlayerAttackAvailable = false
        }

        if MyPlayer.sharedInstance.isPlayerAttackAvailable {
            attackButton?.isEnabled = true
            chargeButton?.isEnabled = true
            if currentTP >= 40 {
                magicButton?.isEnabled = true
            }
        } else {
            attackButton?.isEnabled = false
            chargeButton?.isEnabled = false
            magicButton?.isEnabled = false
        }
    }
    
    func updateOpponentPlayerStatus(currentHP: Int, currentMP: Int, currentTP: Int, maxHP: Int, maxMP: Int, maxTP: Int){
        opponentHPLabel?.text = "\(currentHP) / \(maxHP)"
        opponentMPLabel?.text = "\(currentMP) / \(maxMP)"
        opponentTPLabel.text = "\(currentTP) / \(maxTP)"

    }

    func finishBattle(vanishImageView: UIImageView, isPlayerWin: Bool) {

        techMonManager.stopBGM()
        techMonManager.vanishAnimation(imageView: vanishImageView)
        gameTimer.invalidate()
        myPlayerListener?.remove()
        opponentPlayerListener?.remove()

        var finishMessage: String = ""
        if isPlayerWin {
            techMonManager.playSE(fileName: "SE_fanfare")
            finishMessage = "勇者の勝利！"
        } else {
            techMonManager.playSE(fileName: "SE_gameover")
            finishMessage = "勇者の敗北！"
        }

        let alert = UIAlertController(title: "バトル終了", message: finishMessage, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(action)
        self.present(alert, animated: true, completion: resetPlayerStatus)
    }
    
    func resetPlayerStatus() {
        let document: Document<Player> = Document(id: MyPlayer.sharedInstance.playerId)
        document.save()
    }

    @IBAction func attackAction() {
        techMonManager.damageAnimation(imageView: opponentImageView)
        techMonManager.playSE(fileName: "SE_attack")
        
        let playerRef = db.collection("player")
        
        // MP消費
        playerRef.document(MyPlayer.sharedInstance.playerId)
            .setData(["currentMP" : FieldValue.increment(Int64(-20))], merge: true)
        
        // ダメージ付与
        playerRef.document(MyPlayer.sharedInstance.opponentPlayerId)
            .setData(["currentHP" : FieldValue.increment(Int64(-MyPlayer.sharedInstance.attackPoint))], merge: true)

        // TP上昇
        if MyPlayer.sharedInstance.isRisePlayerTP {
            playerRef.document(MyPlayer.sharedInstance.playerId)
                .setData(["currentTP" : FieldValue.increment(Int64(10))], merge: true)
        }
    }

    @IBAction func chargeAction() {
        techMonManager.playSE(fileName: "SE_charge")
        
        let playerRef = db.collection("player")
        
        // MP消費
        playerRef.document(MyPlayer.sharedInstance.playerId)
            .setData(["currentMP" : FieldValue.increment(Int64(-20))], merge: true)
        
        // TP上昇
        if MyPlayer.sharedInstance.isRisePlayerTP {
            playerRef.document(MyPlayer.sharedInstance.playerId)
                .setData(["currentTP" : FieldValue.increment(Int64(40))], merge: true)
        }
    }

    @IBAction func MagicAction() {
        techMonManager.damageAnimation(imageView: opponentImageView)
        techMonManager.playSE(fileName: "SE_fire")
        
        let playerRef = db.collection("player")
        
        // MP消費
        playerRef.document(MyPlayer.sharedInstance.playerId)
            .setData(["currentMP" : FieldValue.increment(Int64(-20))], merge: true)

        // TP消費
        if MyPlayer.sharedInstance.isRisePlayerTP {
            playerRef.document(MyPlayer.sharedInstance.playerId)
                .setData(["currentTP" : FieldValue.increment(Int64(-40))], merge: true)
        }

        // ダメージ付与
        playerRef.document(MyPlayer.sharedInstance.opponentPlayerId)
            .setData(["currentHP" : FieldValue.increment(Int64(-MyPlayer.sharedInstance.specialAttackPoint))], merge: true)
    }

}
