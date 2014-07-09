//
//  VideoEditManager.swift
//  FrameQR
//
//  Created by Tatsuya Suganuma on 2014/07/09.
//  Copyright (c) 2014年 redmorado. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import CoreMedia
import QuartzCore

class VideoEditManager {
    
    let originalURLAsset:AVURLAsset;
    let animationLayer:CALayer;
    
    var delegate:VideoEditManagerDelegate?;
    
    var composition:AVComposition?;
    var videoComposition:AVVideoComposition?;
    
    
    init(originalVideoURL: NSURL, animationLayer: CALayer) {
        self.originalURLAsset = AVURLAsset(URL: originalVideoURL, options: nil);
        self.animationLayer = animationLayer;
    }
    
    
    
    
    
    // MARK: - class function
    
    class func getVideoSize(videoTrack:AVAssetTrack) -> CGSize {
        var videoSize:CGSize = videoTrack.naturalSize;
        var transform:CGAffineTransform = videoTrack.preferredTransform;
        if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0)) {
            videoSize = CGSizeMake(videoSize.height, videoSize.width);
        }
        return videoSize;
    }
    
    
    
    
    
    // MARK: - private function
    
    func beginComposition() {
        
        // build composition and videoComposition
        self.buildComposition();
        
        
        // file path
        let filePath:String = self.getFilePath();
        
        let session:AVAssetExportSession = AVAssetExportSession(asset:self.composition, presetName:AVAssetExportPresetMediumQuality);
        session.videoComposition = self.videoComposition;
        session.outputURL = NSURL.fileURLWithPath(filePath);
        session.outputFileType = AVFileTypeMPEG4;
        session.exportAsynchronouslyWithCompletionHandler({
            dispatch_async(dispatch_get_main_queue(), {
                if session.status == AVAssetExportSessionStatus.Completed {
                    self.delegate?.success?(filePath);
                } else {
                    self.delegate?.failure?(session.error);
                }
                })
            });
        
    }
    
    func buildComposition() {
        let composition:AVMutableComposition = AVMutableComposition();
        let compositionVideoTrack:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID:0);
        
        
        let timeRange:CMTimeRange = CMTimeRangeMake(kCMTimeZero, originalURLAsset.duration);
        let videoTrack:AVAssetTrack = originalURLAsset.tracksWithMediaType(AVMediaTypeVideo)[0] as AVAssetTrack;
        compositionVideoTrack.insertTimeRange(timeRange, ofTrack: videoTrack, atTime: kCMTimeZero, error: nil);
        
        
        let instruction:AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction();
        instruction.timeRange = timeRange;
        
        let layerInstruction:AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack);
        
        let videoSize:CGSize = VideoEditManager.getVideoSize(videoTrack);
        let transform:CGAffineTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(CGFloat(M_PI_2)), CGAffineTransformMakeTranslation(videoSize.width, 0));
        
        layerInstruction.setTransform(transform, atTime: kCMTimeZero);
        instruction.layerInstructions = [layerInstruction];
        
        
        let parentLayer:CALayer = CALayer();
        let videoLayer:CALayer = CALayer();
        parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        parentLayer.addSublayer(videoLayer);
        parentLayer.addSublayer(self.animationLayer);
        
        let videoComposition:AVMutableVideoComposition = AVMutableVideoComposition();
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer:videoLayer, inLayer:parentLayer);
        videoComposition.renderSize = CGSizeMake(videoSize.width, videoSize.height);
        videoComposition.instructions = [instruction];
        videoComposition.frameDuration = CMTimeMake(1, 30); // FPS
        
        self.composition = composition;
        self.videoComposition = videoComposition;
    }
    
    func getFilePath() -> NSString {
        
        let app:AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate;
        
        let filePath:NSString = NSTemporaryDirectory().stringByAppendingPathComponent("output.mp4");
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            NSFileManager.defaultManager().removeItemAtPath(filePath, error: nil);
        }
        
        return filePath;
    }
    
    
}



@objc protocol VideoEditManagerDelegate {
    @optional func success(filePath: NSString) -> Void
    @optional func failure(error: NSError) -> Void
}


