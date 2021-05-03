//
//  PostTableViewCell.swift
//  Instagram
//
//  Created by CapriCole on 2021/04/20.
//

import UIKit
import FirebaseUI
import Firebase

class PostTableViewCell: UITableViewCell {
    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var commentsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //PostDataの内容をセルに表示
    func setPostData(_ postData: PostData) {
        //画像の表示
        postImageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
        let imageRef = Storage.storage().reference().child(Const.ImagePath).child(postData.id + ".jpg")
        postImageView.sd_setImage(with: imageRef)
                
        //キャプションの表示
        self.captionLabel.text = "\(postData.name!) : \(postData.caption!)"
        
        //表示名を取得してキャプションのnameをdisplayNameに変更
        let profileRef = Firestore.firestore().collection(Const.ProfilePath).document(postData.uid!)
        profileRef.getDocument { (document, error) in
            if let error = error {
                print("DEBUG_PRINT: getDocumentの取得が失敗しました。\(error)")
                return
            }

            if let document = document, document.exists {
                if let profileDic = document.data() {
                let displayName = profileDic["displayname"] as? String
                //キャプションの再表示
                self.captionLabel.text = "\(displayName!) : \(postData.caption!)"
                }
            }
        }
        
        //日時の表示
        self.dateLabel.text = ""
        if let date = postData.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let dateString = formatter.string(from: date)
            self.dateLabel.text = dateString
        }
        
        //いいね数の表示
        let likeNumber = postData.likes.count
        likeLabel.text = "\(likeNumber)"
        
        //いいねボタンの表示
        if postData.isLiked {
            let buttonImage = UIImage(named: "like_exist")
            self.likeButton.setImage(buttonImage, for: .normal)
        } else {
            let buttonImage = UIImage(named: "like_none")
            self.likeButton.setImage(buttonImage, for: .normal)
        }
        
        //コメントの表示
        //コメントがある場合
        if postData.comments.count > 0 {
            let commentArray = postData.comments
            
            //コメントの数だけループ
            for i in 0 ..< postData.comments.count {
                
                let commentDic = commentArray[i]
                let commentname = commentDic["displayname"]
                let commenttext = commentDic["comment"]
                
                //初回は代入して設定
                if i == 0 {
                    self.commentsLabel.text? = "＜コメント＞\n\(commentname!)：\(commenttext!)"
                } else {
                    //2つ目以降は連結して設定
                    self.commentsLabel.text? += "\n\(commentname!)：\(commenttext!)"
                }
           }
        } else {
            //コメントがない場合
            commentsLabel.text = ""
        }

    }
}
