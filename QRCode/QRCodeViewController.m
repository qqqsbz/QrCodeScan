//
//  QRCodeViewController.m
//  QRCode
//
//  Created by coder on 16/2/26.
//  Copyright © 2016年 coder. All rights reserved.
//

#import "QRCodeViewController.h"
#import "AVCaptureManager.h"
@interface QRCodeViewController ()<AVCaptureManagerDelegate,UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *qrcodeWindow;
@property (strong, nonatomic) IBOutlet UIView *scanIndicator;
@property (strong, nonatomic) IBOutlet UIView *maskView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *scanIndicatorTopConstraint;

@property (strong, nonatomic) AVCaptureManager  *captureManager;
@end

@implementation QRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _captureManager = [[AVCaptureManager alloc] init];
    _captureManager.delegate = self;
    
    __weak typeof(self) weakSelf = self;
    [_captureManager setupSessionSuccess:^(AVCaptureSession *session) {
        if ([[_captureManager.metadataOutput availableMetadataObjectTypes] containsObject:AVMetadataObjectTypeQRCode]) {
            [_captureManager.metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
            
            if ([_captureManager.backCamera lockForConfiguration:nil]) {
                if ([_captureManager.backCamera isAutoFocusRangeRestrictionSupported]) {
                    [_captureManager.backCamera setAutoFocusRangeRestriction:AVCaptureAutoFocusRangeRestrictionNear];
                }
                [_captureManager.backCamera unlockForConfiguration];
            }
            
            //[weakSelf.errorView removeFromSuperview];
            _captureManager.previewLayer.frame = self.view.bounds;
            [weakSelf.view.layer insertSublayer:_captureManager.previewLayer atIndex:0];
           // weakSelf.flashlightBtn.enabled = YES;
        } else {
            //不支持二维码扫描
            [weakSelf handleErrorWithText:NSLocalizedString(@"QRcode Recognition Not Supported", nil)];
        }
    } failure:^(NSError *error) {
        //没有允许app访问相机
        [weakSelf handleErrorWithText:NSLocalizedString(@"Camera Authorization Tips", nil)];
    }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.captureManager startRunningAsync];
    [self animateScanIndicator];
    self.scanIndicator.hidden = NO;
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.captureManager stopRunning];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGRect frame = self.maskView.bounds;
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = frame;
    maskLayer.fillColor = [UIColor blackColor].CGColor;
    
    CGRect rect = self.qrcodeWindow.frame;
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
    [path appendPath:[UIBezierPath bezierPathWithRect:frame]];
    maskLayer.path = path.CGPath;
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    
    self.maskView.layer.mask = maskLayer;
    
    [self.captureManager setRectOfInterestForRect:rect];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.captureManager.previewLayer.frame = self.view.bounds;
    [self.captureManager setPreviewLayerWithUIInterfaceOrientation:toInterfaceOrientation];
    [self.captureManager setRectOfInterestForRect:self.qrcodeWindow.frame];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self animateScanIndicator];
}

- (void)captureManager:(AVCaptureManager *)captureManager didOutputMetadataObjects:(NSArray *)metadataObjects
{
    NSString *decodedText = nil;
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            decodedText = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            break;
        }
    }
    
    if (!decodedText) {
        return;
    }
    
    self.scanIndicator.hidden = YES;
    [self.captureManager stopRunning];
    
    NSURL *candidateUrl = [NSURL URLWithString:decodedText];
    
    NSString *plantCode = [self plantCodeInURL:candidateUrl];
    if (plantCode && ([decodedText rangeOfString:@"showAtPenyou"].location != NSNotFound)) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        
    } else {
        [[[UIAlertView alloc] initWithTitle:@"二维码" message:decodedText delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil] show];
    }
    
}

- (NSString *)plantCodeInURL:(NSURL *)url
{
    NSString *queryString = url.query;
    if (queryString) {
        NSArray *components = [queryString componentsSeparatedByString:@"&"];
        for (NSString *kv in components) {
            NSArray  *pair  = [kv componentsSeparatedByString:@"="];
            NSString *key   = [pair.firstObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([key isEqualToString:@"plantCode"]) {
                NSString *value = [pair.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                return value;
            }
        }
    }
    return nil;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.captureManager startRunning];
    self.scanIndicator.hidden = NO;
}

- (void)animateScanIndicator
{
    [self.scanIndicator.layer removeAllAnimations];
    self.scanIndicatorTopConstraint.constant = 0;
    [self.view layoutIfNeeded];
    
    [UIView animateWithDuration:2.5f delay:0.f options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat animations:^{
        self.scanIndicatorTopConstraint.constant = (CGRectGetHeight(self.qrcodeWindow.frame) - CGRectGetHeight(self.scanIndicator.frame));
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)handleErrorWithText:(NSString *)text
{
//    self.errorLabel.text = text;
//    self.errorView.hidden = NO;
}

- (IBAction)toggleFlashlight:(id)sender
{
    [self.captureManager toggleFlashlight];
}



@end
