//
//  BattleViewController.swift
//  TechMonsterOnline
//
//  Created by 大林拓実 on 2019/09/10.
//  Copyright © 2019 大林拓実. All rights reserved.
//

import UIKit

final class BattleViewController: UIViewController {
    
    private var enemyAttackTimer: Timer!
    
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
    
    private let techMonManager = TechMonManager.shared
    
    private var player: Character!
    private var opponent: Character!
    
    private var gameTimer = Timer()
    private var isPlayerAttackAvailable: Bool = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        player = techMonManager.player
        opponent = techMonManager.enemy
    
        playerNameLabel.text = player.name
        playerImageView.image = player.image
        
        opponentNameLabel.text = "ドラゴン"
        opponentImageView.image = UIImage(named: "monster.png")
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateGame), userInfo: nil, repeats: true)
        gameTimer.fire()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        techMonManager.playBGM(fileName: "BGM_battle001")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        techMonManager.stopBGM()
    }
    
    @objc func updateGame() {
        player.currentMP += 1
        if player.currentMP >= 20 {
            isPlayerAttackAvailable = true
            player.currentMP = 20
        } else {
            isPlayerAttackAvailable = false
        }
        
        opponent.currentMP += 1
        if opponent.currentMP >= 35 {
            opponentAttack()
            opponent.currentMP -= 35
        }
        
        updateUI()
    }
    
    func updateUI() {
        playerHPLabel.text = "\(player.currentHP) / \(player.maxHP)"
        playerMPLabel.text = "\(player.currentMP) / \(player.maxMP)"
        playerTPLabel.text = "\(player.currentTP) / \(player.maxTP)"

        opponentHPLabel.text = "\(opponent.currentHP) / \(opponent.maxHP)"
        opponentMPLabel.text = "\(opponent.currentMP) / \(opponent.maxMP)"
        
        if isPlayerAttackAvailable {
            attackButton.isEnabled = true
            chargeButton.isEnabled = true
            if player.currentTP >= 40 {
                magicButton.isEnabled = true
            }
        } else {
            attackButton.isEnabled = false
            chargeButton.isEnabled = false
            magicButton.isEnabled = false
        }
    }
    
    func judgeBattleFinish() {
        if player.currentHP <= 0 {
            finishBattle(vanishImageView: playerImageView, isPlayerWin: false)
        } else if opponent.currentHP <= 0 {
            finishBattle(vanishImageView: opponentImageView, isPlayerWin: true)
        }
    }
    
    func finishBattle(vanishImageView: UIImageView, isPlayerWin: Bool) {
        
        techMonManager.stopBGM()
        techMonManager.vanishAnimation(imageView: playerImageView)
        gameTimer.invalidate()
        isPlayerAttackAvailable = false
        
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
        self.present(alert, animated: true, completion: nil)
    }
    
    func opponentAttack() {
        techMonManager.damageAnimation(imageView: playerImageView)
        techMonManager.playSE(fileName: "SE_attack")
        
        player.currentHP -= opponent.attackPoint
        
        updateUI()
        judgeBattleFinish()
    }
    
    @IBAction func attackAction() {
        if isPlayerAttackAvailable{
            techMonManager.damageAnimation(imageView: opponentImageView)
            techMonManager.playSE(fileName: "SE_attack")

            opponent.currentHP -= player.attackPoint
            player.currentMP -= 20
            
            player.currentTP += 10
            player.currentTP = min(player.currentTP, player.maxTP)
            
            updateUI()
            judgeBattleFinish()
        }
    }
    
    @IBAction func chargeAction() {
        if isPlayerAttackAvailable {
            techMonManager.playSE(fileName: "SE_charge")
            player.currentTP += 40
            player.currentTP = min(player.currentTP, player.maxTP)
            player.currentMP -= 20
            
            updateUI()
        }
    }
    
    @IBAction func MagicAction() {
        if isPlayerAttackAvailable && player.currentTP >= 40 {
            techMonManager.damageAnimation(imageView: opponentImageView)
            techMonManager.playSE(fileName: "SE_fire")
            
            opponent.currentHP -= 100
            player.currentMP -= 20
            
            player.currentTP -= 40
            player.currentTP = max(player.currentTP, 0)
            
            updateUI()
            judgeBattleFinish()

        }
    }
    
}
