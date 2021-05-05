//
//  HomeViewController.swift
//  Instagram
//
//  Created by CapriCole on 2021/04/13.
//

import UIKit
import Firebase

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    //投稿データを格納する配列
    var postArray: [PostData] = []
    
    //Firestoreのリスナー
    var listener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        //カスタムセルを登録する
        let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "Cell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRINT: viewWillAppear")
        //ログイン済みか確認
        if Auth.auth().currentUser != nil {
            //listenerを登録して投稿データの更新を監視する
            let postsRef = Firestore.firestore().collection(Const.PostPath).order(by: "date", descending: true)
            listener = postsRef.addSnapshotListener() { (querySnapshot, error) in
                if let error = error {
                    print("DEBUG_PRINT: snapshotの取得が失敗しました。\(error)")
                    return
                }
                
                //取得したdocumentをもとにPostDataを作成し、postArrayの配列にする
                self.postArray = querySnapshot!.documents.map { document in
                    print("DEBUG_PRINT: documet取得\(document.documentID)")
                    let postData = PostData(document: document)
                   return postData
                }
                
                //コメントがある最終インデックスを格納する用(初期値は-1）
                var lastIndex = -1
                
                //コメントが存在する最終インデックスを求める
                for i in (0 ..< self.postArray.count).reversed() {
                    if self.postArray[i].isCommented == true {
                        lastIndex = i
                        break
                    }
                }
                
                //コメントがある場合、コメント者の表示名を取得して設定。ない場合、tableViewreloadData
                if lastIndex == -1 {
                    self.tableView.reloadData()
                } else {
                    //postArray分ループ
                    for i in 0 ..< self.postArray.count {
                        
                        //コメント分ループ
                        for j in 0 ..< self.postArray[i].comments.count {
                            
                            let commentDic = self.postArray[i].comments[j]
                            let commentuid = commentDic["userid"]

                            //useridでドキュメント取得（displaynameを取得）
                            let profileRef = Firestore.firestore().collection(Const.ProfilePath).document(commentuid!)

                            profileRef.getDocument { (document, error) in
                                if let error = error {
                                    print("DEBUG_PRINT: getDocumentの取得が失敗しました。\(error)")
                                    return
                                }

                                if let document = document, document.exists {
                                    if let profileDic = document.data() {
                                        //コメント辞書配列にdisplayname要素を追加
                                        let displayName = profileDic["displayname"] as? String
                                        self.postArray[i].comments[j]["displayname"] = displayName!

                                        //コメントがある最終インデックスかつ最後のコメントにdisplaynameが設定されている場合、tableView最新化
                                        if self.postArray[lastIndex].comments[self.postArray[lastIndex].comments.count - 1]["displayname"] != "" {
                                            print("DEBUG_PRINT: reloadData1")
                                            self.tableView.reloadData()
                                        }
                                    }
                                } else {
                                    //displaynameを取得できなかった（ドキュメントが存在しない）場合コメント投稿時のnameを設定
                                    self.postArray[i].comments[j]["displayname"] = self.postArray[i].comments[j]["name"]

                                    //コメントがある最終インデックスかつ最後のコメントにdisplaynameが設定されている場合、tableView最新化
                                    if self.postArray[lastIndex].comments[self.postArray[lastIndex].comments.count - 1]["displayname"] != "" {
                                        print("DEBUG_PRINT: reloadData2")
                                        self.tableView.reloadData()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("DEBUG_PRINT: viewWillDisappear")
        //listenerを削除して監視を停止する
        listener?.remove()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //セルを取得してデータを設定する
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PostTableViewCell
        cell.setPostData(postArray[indexPath.row])
        
        //セル内のボタンのアクションをソースコードで設定する
        cell.likeButton.addTarget(self, action:#selector(handleButton(_:forEvent:)), for: .touchUpInside)
        
        //セル内のコメントボタンのアクションを設定
        cell.commentButton.addTarget(self, action:#selector(handleCommentButton(_:forEvent:)), for: .touchUpInside)
        
        return cell
    }
    
    @objc func handleButton(_ sender: UIButton, forEvent event: UIEvent) {
        print("DEBUG_PRINT: likeボタンがタップされました。")
        
        //タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        //配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]
        
        //likesを更新する
        if let myid = Auth.auth().currentUser?.uid {
            //更新データを作成する
            var updateValue: FieldValue
            if postData.isLiked {
                //すでにいいねをしている場合は、いいね解除のためmyidを取り除く更新データを作成
                updateValue = FieldValue.arrayRemove([myid])
            } else {
                //今回新たにいいねを押した場合、myidを追加する更新データを作成
                updateValue = FieldValue.arrayUnion([myid])
            }
            
            //likesに更新データを書き込む
            let postRef = Firestore.firestore().collection(Const.PostPath).document(postData.id)
            postRef.updateData(["likes": updateValue])
        }
        
    }
    
    @objc func handleCommentButton(_ sender: UIButton, forEvent event: UIEvent) {
        print("DEBUG_PRINT: commentボタンがタップされました。")
        
        //タップされたセルのインデックスを求める
        let touch = event.allTouches?.first
        let point = touch!.location(in: self.tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        //配列からタップされたインデックスのデータを取り出す
        let postData = postArray[indexPath!.row]
        
        //postDataを渡してコメント入力画面に遷移
        let commentViewController = storyboard!.instantiateViewController(withIdentifier: "Comment") as! CommentViewController
        commentViewController.postData = postData
        self.present(commentViewController, animated: true, completion: nil)
        
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
