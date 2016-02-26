//
//  AVCaptureManager.m
//  iPenYou
//
//  Created by coder on 14-5-4.
//  Copyright (c) 2014年 vbuy. All rights reserved.
//

#import "AVCaptureManager.h"

AVCaptureVideoOrientation UIInterfaceOrientationToAVCaptureVideoOrientation(UIInterfaceOrientation orientation)
{
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        default:
            return AVCaptureVideoOrientationPortrait;
    }
}

@interface AVCaptureManager () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, assign, getter = isSessionDispatched) BOOL sessionDispatched;

@end

@implementation AVCaptureManager

@synthesize previewLayer = _previewLayer;

- (void)startRunning
{
    if (![self.session isRunning]) {
        [self.session startRunning];
    }
}

- (void)startRunningAsync
{
    if (!self.isSessionDispatched && ![self.session isRunning]) {
        self.sessionDispatched = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.session startRunning];
            self.sessionDispatched = NO;
        });
    }
}

- (void)stopRunning
{
    [self.session stopRunning];
}

- (void)setupSessionSuccess:(void (^)(AVCaptureSession *session))success failure:(void (^)(NSError *error))failure
{
    NSError *error = nil;
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:&error];
    if (!input) {
        if (failure) {
            failure(error);
        }
        return;
    }
    
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    if ([session canAddInput:input]) {
        [session addInput:input];
    }
    if ([session canAddOutput:output]) {
        [session addOutput:output];
    }
    _backCamera = videoDevice;
    _metadataOutput = output;
    _session = session;
    
    if (success) {
        success(session);
    }
}

- (void)toggleFlashlight
{
    if (self.backCamera.hasTorch && self.backCamera.torchAvailable) {
        if ([self.backCamera lockForConfiguration:nil]) {
            if (self.backCamera.torchActive) {
                self.backCamera.torchMode = AVCaptureTorchModeOff;
            } else {
                self.backCamera.torchMode = AVCaptureTorchModeOn;
            }
            [self.backCamera unlockForConfiguration];
        }
    }
}

- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (_previewLayer == nil) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    }
    return _previewLayer;
}

- (void)setPreviewLayerWithUIInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    self.previewLayer.connection.videoOrientation = UIInterfaceOrientationToAVCaptureVideoOrientation(orientation);
}

- (void)setRectOfInterestForRect:(CGRect)rectInLayerCoordinates
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.metadataOutput.rectOfInterest = [self.previewLayer metadataOutputRectOfInterestForRect:rectInLayerCoordinates];
    });
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if ([self.delegate respondsToSelector:@selector(captureManager:didOutputMetadataObjects:)]) {
        [self.delegate captureManager:self didOutputMetadataObjects:metadataObjects];
    }
}

@end
