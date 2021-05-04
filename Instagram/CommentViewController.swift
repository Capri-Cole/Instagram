//
//  CommentViewController.swift
//  Instagram
//
//  Created by CapriCole on 2021/04/26.
//

import UIKit
import Firebase
import SVProgressHUD

class CommentViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    //投稿データを格納用
    var postData: PostData!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //背景をタップしたらdismissKeyboardを呼ぶ
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        //テキストビューの枠線の設定
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 5.0
        textView.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
    }
    
    @objc func dismissKeyboard() {
        //キーボードを閉じる
        view.endEditing(true)
    }
    //投稿ボタン押下時処理
    @IBAction func handleCommentPost(_ sender: Any) {
        
        //コメントの確認
        if let comment = textView.text {
            if comment.isEmpty {
                SVProgressHUD.showError(withStatus: "コメントが入力されていません。")
                return
            }
        }
        
        //コメントデータを登録する
        if let myid = Auth.auth().currentUser?.uid {
            let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
            let commentData = ["userid": myid, "comment": textView.text!]
            let updateValue = FieldValue.arrayUnion([commentData])
            postRef.updateData(["comments": updateValue])
        }
        
        //HUDで完了を表示する
        SVProgressHUD.showSuccess(withStatus: "コメントしました")
        
        //画面を閉じる
        self.dismiss(animated: true, completion: nil)
        
    }
    
    //キャンセルボタン押下時処理
    @IBAction func handleCommentCancel(_ sender: Any) {
        //画面を閉じる
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
