//
//  ViewController.swift
//  Video Editor
//
//  Created by Tatsuya Suganuma on 2014/07/09.
//  Copyright (c) 2014年 redmorado. All rights reserved.
//

import UIKit
import AVFoundation
import QuartzCore

import MobileCoreServices

class ViewController: UIViewController, VideoEditManagerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
                            
    @IBOutlet var btnExecute: UIButton
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    
    // MARK: - private func
    
    func buildOverlayLayer(videoSize: CGSize) -> CALayer {
        
        // wrapper layer
        let layer:CALayer = CALayer();
        layer.bounds = CGRectMake(0, 0, videoSize.width, videoSize.height);
//        layer.backgroundColor = UIColor.redColor().CGColor;
        layer.anchorPoint = CGPoint.zeroPoint;
        layer.position = CGPoint.zeroPoint;
        
        
        // animation layer
        let animationObject:CALayer = CALayer();
        animationObject.backgroundColor = UIColor.blackColor().CGColor;
        animationObject.frame = CGRectMake(0, 0, 40, 40);
        
        
        // animation
        var transform:CATransform3D = CATransform3DMakeTranslation(videoSize.width, videoSize.height, 0.0);
        transform = CATransform3DScale(transform, 0.5, 0.5, 1);
        
        var animTrans:CABasicAnimation = CABasicAnimation(keyPath: "transform");
        animTrans.toValue = NSValue(CATransform3D: transform);
        var animOpacity:CABasicAnimation = CABasicAnimation(keyPath: "opacity");
        animOpacity.toValue = 0;
        
        var animGroup:CAAnimationGroup = CAAnimationGroup();
        animGroup.beginTime = AVCoreAnimationBeginTimeAtZero + 1; // delay 1 sec
        animGroup.duration = 1;
        animGroup.repeatCount = 3;
        animGroup.removedOnCompletion = false;
        animGroup.fillMode = kCAFillModeForwards;
        animGroup.animations = [animTrans, animOpacity];
        
        // add animation to layer
        animationObject.addAnimation(animGroup, forKey: nil);
        
        // add layer to wrapper layer
        layer.addSublayer(animationObject);
        
        return layer;
    }
    

    
    
    
    
    
    // MARK: - IBAction

    @IBAction func onTouchedExecute(sender: AnyObject) {
        
        let picker:UIImagePickerController = UIImagePickerController();
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary;
        picker.mediaTypes =  [String(kUTTypeMovie)];
        picker.allowsEditing = false;
        picker.delegate = self;
        
        // select video
        self.presentViewController(picker, animated:true, completion:nil);
    }
    
    
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: NSDictionary!) {
        
        let mediaType:String = info.objectForKey(UIImagePickerControllerMediaType) as String;
        if mediaType == String(kUTTypeMovie) {
            // get video URL
            let url:NSURL = info.objectForKey(UIImagePickerControllerMediaURL) as NSURL;
            
            let asset:AVURLAsset = AVURLAsset(URL: url, options: nil);
            let videoTrack:AVAssetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack;
            
            let vem:VideoEditManager = VideoEditManager(originalVideoURL: url, animationLayer: self.buildOverlayLayer(VideoEditManager.getVideoSize(videoTrack)));
            vem.delegate = self;
            vem.beginComposition();
        }
        
        self.btnExecute.enabled = false;
        self.dismissViewControllerAnimated(true, completion:nil);
    }
    
    
    
    
    // MARK: - VideoEditManagerDelegate
    
    func success(filePath: NSString) {
        NSLog("output success!");
        
        // save to camera roll
        UISaveVideoAtPathToSavedPhotosAlbum(filePath, nil, nil, nil);
        
        self.btnExecute.enabled = true;
    }
    
    func failure(error: NSError) {
        NSLog("output error! : %@", error);
        
        self.btnExecute.enabled = true;
    }

}

