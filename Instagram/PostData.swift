//
//  PostData.swift
//  Instagram
//
//  Created by CapriCole on 2021/04/20.
//

import UIKit
import Firebase

class PostData: NSObject {
    var id: String
    var name: String?
    var caption: String?
    var date: Date?
    var likes: [String] = []
    var isLiked: Bool = false
    var uid: String?
    var comments: [[String:String]] = []
    var isCommented: Bool = false
    
    init(document: QueryDocumentSnapshot) {
        self.id = document.documentID
        
        let postDic = document.data()
        
        self.name = postDic["name"] as? String
        
        self.caption = postDic["caption"] as? String
        
        let timestamp = postDic["date"] as? Timestamp
        self.date = timestamp?.dateValue()
        
        if let likes = postDic["likes"] as? [String] {
            self.likes = likes
        }
        
        if let myid = Auth.auth().currentUser?.uid {
            //likesの配列の中にmyidが含まれているかチェックすることで、自分がいいねを押しているかを判断
            if self.likes.firstIndex(of: myid) != nil {
                //myidがあれば、いいねを押していると認識する。
                self.isLiked = true
            }
        }
        
        self.uid = postDic["uid"] as? String
        
        //コメントを辞書配列で格納
        if var comments = postDic["comments"] as? [[String:String]] {
            //辞書にdisplaynameを追加
            for i in 0 ..< comments.count {
                comments[i]["displayname"] = ""
            }
            
            self.comments = comments
        }
        
        //コメントがある場合、trueを設定
        if self.comments.count > 0 {
            self.isCommented = true
        }
        
    }
    
    
}
