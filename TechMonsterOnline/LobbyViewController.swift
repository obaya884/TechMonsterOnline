//
//  LobbyViewController.swift
//  TechMonsterOnline
//
//  Created by 大林拓実 on 2019/09/10.
//  Copyright © 2019 大林拓実. All rights reserved.
//

import UIKit

final class LobbyViewController: UIViewController {
    
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var staminaLabel: UILabel!
    
    private let techMonManager = TechMonManager.shared
    
    private var stamina: Int = 100
    private var staminaTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameLabel.text = "勇者"
        staminaLabel.text = "\(stamina) / 100"
        
        staminaTimer = Timer.scheduledTimer(
            timeInterval: 3.0,
            target: self,
            selector: #selector(updateStaminaValue),
            userInfo: nil,
            repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        techMonManager.playBGM(fileName: "lobby")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        techMonManager.stopBGM()
    }
    
    @IBAction func toBattleViewButtonTapped(){
        if stamina >= 20 {
            stamina = stamina - 20
            staminaLabel.text = "\(stamina) / 100"
            performSegue(withIdentifier: "toBattleViewControllerSegue", sender: nil)
        } else {
            let alert = UIAlertController(title: "スタミナ不足", message: "スタミナが20以上必要です", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func updateStaminaValue(){
        if stamina < 100 {
            stamina += 1
            staminaLabel.text = "\(stamina) / 100"
        }
    }
}
