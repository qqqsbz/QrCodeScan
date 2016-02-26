//
//  AVCaptureManager.h
//  iPenYou
//
//  Created by coder on 14-5-4.
//  Copyright (c) 2014年 vbuy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

AVCaptureVideoOrientation UIInterfaceOrientationToAVCaptureVideoOrientation(UIInterfaceOrientation orientation);

@protocol AVCaptureManagerDelegate;


@interface AVCaptureManager : NSObject

@property (nonatomic, weak) id<AVCaptureManagerDelegate> delegate;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic, strong) AVCaptureDevice *backCamera;

- (void)setupSessionSuccess:(void (^)(AVCaptureSession *session))success failure:(void (^)(NSError *error))failure;

- (void)startRunning;

- (void)startRunningAsync;

- (void)stopRunning;

- (void)toggleFlashlight;

- (void)setPreviewLayerWithUIInterfaceOrientation:(UIInterfaceOrientation)orientation;

- (void)setRectOfInterestForRect:(CGRect)rectInLayerCoordinates;

@end

@protocol AVCaptureManagerDelegate <NSObject>

- (void)captureManager:(AVCaptureManager *)captureManager didOutputMetadataObjects:(NSArray *)metadataObjects;

@end
