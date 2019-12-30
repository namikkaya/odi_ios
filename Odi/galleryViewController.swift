//
//  galleryViewController.swift
//  Odi
//
//  Created by Nok Danışmanlık on 24.10.2019.
//  Copyright © 2019 bilal. All rights reserved.
//

import UIKit

class galleryViewController: UIViewController, collectionViewModelDelegate {
    let TAG:String = "galleryViewController:"
    
    var dbMan:kayaDbManager?

    @IBOutlet var collectionViewi: UICollectionView!
    
    private var collectionViewManager:collectionViewModel?
    var collectionData:[videoModel] = []
    
    var onCallback:( (_ status:Bool?, _ dataModel:videoModel?) -> () )?
    var selectedHolder:videoModel?
    @IBOutlet var commentText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        dbMan = kayaDbManager.sharedInstance
        
        collectionData = collectionData.reversed()
        collectionViewManager = collectionViewModel(collectionView: collectionViewi, context: self, collectionViewData: collectionData)
        
        if collectionData.count > 0 {
            dbMan?.getProjectData(projectId: collectionData[0].projectId, onCallback: { (status, data:projectModel?) in
                if let status = status {
                    if status {
                        if let data = data {
                            let createDate:Date = data.createDate!.toDate()!
                            print("galerry: today: \(Date()) - createDate: \(createDate)")
                            let diffDate = Date().daysBetween(date: createDate)
                            print("galerry: zaman: \(5 + diffDate)")
                            let day = 5+diffDate
                            var str:String = ""
                            if (day < 1) {
                                str = "En iyi odilemeni seç ve yükle. Yüklemediğin videolar bugün içinde silinecek."
                            }else {
                                let daySTR = String(day)
                                str = "En iyi odilemeni seç ve yükle. Yüklemediğin videolar \(daySTR) gün içinde silinecek."
                            }
                            self.commentText.text = str
                        }
                    }
                }
            })
        }
        
        
        
        /*
        let createDate:Date = (data![i].createDate?.toDate())!
        print("diff: today: \(Date()) - createDate: \(createDate)")
        let diffDate = Date().daysBetween(date: createDate)
        print("diff: \(diffDate)")
        if(diffDate < -5) { // 5 günden daha fazla ise
            self.deleteProject(projectId: data![i].projectId) { (status) in
                if let status = status {
                    if status {
                        print("diff: proje silindi")
                    }
                }
                
                
            }
        }*/
    }

    
    func collectionViewModel_selected(row: Int) {
        selectedHolder = collectionData[row]
        self.dismiss(animated: true) {
            self.onCallback!(true,self.selectedHolder)
        }
    }

    @IBAction func closeButtonEvent(_ sender: Any) {
        self.dismiss(animated: true) {
            self.onCallback!(false,nil)
        }
    }
    
    func collectionViewModel_emptyData() {
        self.dismiss(animated: true) {
            self.onCallback!(false,nil)
        }
    }
    
}
