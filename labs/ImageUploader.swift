//
//  ImageUploader.swift
//  labs
//
//  Created by 방정호 on 2015. 10. 22..
//  Copyright © 2015년 dropbeat. All rights reserved.
//

import UIKit

enum ImageType {
    case Profile
    case Cover
}

class ImageUploader {
    static func uploadImage(image:UIImage, type:ImageType, callback:((url:String?, error:NSError?)->Void)) {
        let uploader = ImageUploader()
        uploader.image = image
        uploader.type = type
        uploader.callback = callback
        uploader.getUploadImageUrl()
    }
    
    private var image: UIImage!
    private var type: ImageType!
    private var callback: ((url:String?, error:NSError?)->Void)!

    private var uploadImageUrl: String!
    private var reversedSessionId: String?

    private func getUploadImageUrl() {
        let req = Requests.sendGet(ApiPath.metaUploadHost, auth: false) {
            (result, error) -> Void in
            guard let r = result, host = JSON(r)["host"].string else {
                print("Can't fetch upload host.")
                self.callback(url: nil, error: error)
                return
            }
            
            let port = hostType == .Dropbeat ? 19090 : 19091
            self.uploadImageUrl = "http://\(host):\(port)/upload_image/"
            print(self.uploadImageUrl)
            
            self.postImageToUploadServer()
        }
        
        if let cookieStorage = req.session.configuration.HTTPCookieStorage,
            cookies = cookieStorage.cookiesForURL((req.request?.URL)!),
            sessionId = cookies.filter({ $0.name == "sessionid" }).first?.value {
                let halfIndex = sessionId.length / 2
                self.reversedSessionId =
                    (sessionId as NSString).substringFromIndex(halfIndex) +
                    (sessionId as NSString).substringToIndex(halfIndex)
                print("Reversed session id: \(self.reversedSessionId!)")
        }
    }
    
    private func postImageToUploadServer() {
        guard let reversedSessionId = self.reversedSessionId else {
            print("Can't load session ID.")
            self.callback(url: nil, error: NSError(
                domain: "ImageUploader",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey:"Can't get session ID."])
            )
            return
        }
        
        guard let imageData = UIImageJPEGRepresentation(self.image, 0.8) else {
            print("Image conversion failed.")
            self.callback(url: nil, error: NSError(
                domain: "ImageUploader",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey:"Can't convert image."])
            )
            return
        }
        
        let adapter = WebAdapter(url: self.uploadImageUrl, method: .POST, params: nil, auth: true, background:false)
        adapter.manager.upload(.POST, self.uploadImageUrl,
            headers: [
                "contentType":"multipart/form-data",
                "dbt_key":reversedSessionId
            ],
            multipartFormData: { (data: MultipartFormData) -> Void in
                data.appendBodyPart(
                    data: "jpg".dataUsingEncoding(NSUTF8StringEncoding)!,
                    name: "ext")

                let typeString = self.type == .Profile ? "p" : "pc"
                data.appendBodyPart(
                    data: typeString.dataUsingEncoding(NSUTF8StringEncoding)!,
                    name: "type")
            
                data.appendBodyPart(data: imageData,
                    name: "content",
                    fileName: "content",
                    mimeType: "image/jpeg")
            },
            encodingMemoryThreshold: Manager.MultipartFormDataEncodingMemoryThreshold,
            encodingCompletion: { (encodingResult) -> Void in
                switch encodingResult {
                case .Success(let req, _, _):
                    self.handleUploadingImage(req)
                case .Failure(let encodingError):
                    print("Request encoding error: \(encodingError)")
                    self.callback(url: nil, error: NSError(
                        domain: "ImageUploader",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey:"Can't encode image."])
                    )
                }
        })
    }
    
    private func handleUploadingImage(request: Request) {
        request
            .progress { (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
                print("\(totalBytesWritten) / \(totalBytesExpectedToWrite)")
            }
            .responseData { (request, response, data) in
                if let result = data.value,
                    url = String(data: result, encoding: NSUTF8StringEncoding) {
                        self.postNewImageURL(url)
                } else {
                    print("Image uploading failed: \(data.error)")
                    self.callback(url: nil, error: NSError(
                        domain: "ImageUploader",
                        code: -4,
                        userInfo: [NSLocalizedDescriptionKey:"Can't upload image."])
                    )
                }
        }
    }
    
    private func postNewImageURL(url: String) {
        print("URL of uploaded image: \(url)")
        let path = self.type == .Profile ?
            ApiPath.userChangeProfileImage :
            ApiPath.userChangeCoverImage
        
        Requests.sendPost(path, params: ["url": url], auth: true) { (result, error) -> Void in
            if error == nil {
                print("Image uploading SUCCESS.")
                self.callback(url: url, error: nil)
            } else {
                self.callback(url: nil, error: error)
            }
        }
    }
}
