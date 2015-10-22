//
//  GKImagePicker.m
//  GKImagePicker
//
//  Created by Georg Kitz on 6/1/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//

#import "GKImagePicker.h"

#import "GKImageCropViewController.h"

@interface GKImagePicker ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, GKImageCropControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, weak) UIView *popoverView;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
- (void)_hideController;
@end

@implementation GKImagePicker

#pragma mark -
#pragma mark Getter/Setter

@synthesize cropSize, delegate, resizeableCropArea;

#pragma mark -
#pragma mark Init Methods

- (id)init{
    if (self = [super init]) {
        self.cropImage = YES;
        self.cropSize = CGSizeMake(320, 320);
        self.resizeableCropArea = NO;
    }
    return self;
}

# pragma mark -
# pragma mark Private Methods

- (void)_hideController{
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
        [self.popoverController dismissPopoverAnimated:YES];
    } else {
        [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    }

}

#pragma mark -
#pragma mark UIImagePickerDelegate Methods

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    
    if ([self.delegate respondsToSelector:@selector(imagePickerDidCancel:)]) {
        [self.delegate imagePickerDidCancel:self];
    } else {
        [self _hideController];
    }
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if (!_cropImage) {
        [self imageCropController:nil didFinishWithCroppedImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
        
        return;
    }
    
    GKImageCropViewController *cropController = [[GKImageCropViewController alloc] init];
    cropController.enforceRatioLimits = self.enforceRatioLimits;
    cropController.maxWidthRatio = self.maxWidthRatio;
    cropController.minWidthRatio = self.minWidthRatio;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    cropController.preferredContentSize = picker.preferredContentSize;
#else
    cropController.contentSizeForViewInPopover = picker.contentSizeForViewInPopover;
#endif
    cropController.sourceImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    cropController.resizeableCropArea = self.resizeableCropArea;
    cropController.cropSize = self.cropSize;
    cropController.delegate = self;
    [picker pushViewController:cropController animated:YES];
    
}

#pragma mark -
#pragma GKImagePickerDelegate

- (void)imageCropController:(GKImageCropViewController *)imageCropController didFinishWithCroppedImage:(UIImage *)croppedImage{
    
    if ([self.delegate respondsToSelector:@selector(imagePicker:pickedImage:)]) {
        [self _hideController];
        [self.delegate imagePicker:self pickedImage:croppedImage];
    }
}


#pragma mark -
#pragma mark - Action Sheet and Image Pickers

- (void)showActionSheetOnViewController:(UIViewController *)viewController onPopoverFromView:(UIView *)popoverView
{
    self.presentingViewController = viewController;
    self.popoverView = popoverView;
    NSString *fromCameraString = NSLocalizedString(@"Take Photo", @"Take Photo");
    NSString *fromLibraryString = NSLocalizedString(@"Photo Library", @"Photo Library");
    NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Cancel");
    
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        UIAlertAction *fromCameraAction = [UIAlertAction actionWithTitle:fromCameraString style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showCameraImagePicker];
        }];
        
        UIAlertAction *fromLibraryAction = [UIAlertAction actionWithTitle:fromLibraryString style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showGalleryImagePicker];
        }];
        
        [alertController addAction:cancelAction];
        [alertController addAction:fromLibraryAction];
        [alertController addAction:fromCameraAction];
        
        [viewController presentViewController:alertController animated:YES completion:^{
            
        }];
    }
    else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:(id)self
                                                        cancelButtonTitle:cancelTitle
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:fromCameraString, fromLibraryString, nil];
        actionSheet.delegate = self;
        
        if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
            [actionSheet showFromRect:self.popoverView.frame inView:self.presentingViewController.view animated:YES];
        } else {
            if (self.presentingViewController.navigationController.toolbar) {
                [actionSheet showFromToolbar:self.presentingViewController.navigationController.toolbar];
            } else {
                [actionSheet showInView:self.presentingViewController.view];
            }
        }
    }
}

- (void)presentImagePickerController
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.imagePickerController];
        [self.popoverController presentPopoverFromRect:self.popoverView.frame
                                                inView:self.presentingViewController.view
                              permittedArrowDirections:UIPopoverArrowDirectionAny
                                              animated:YES];
        
    } else {
        
        [self.presentingViewController presentViewController:self.imagePickerController animated:YES completion:nil];
        
    }
}

- (void)showCameraImagePicker {

#if TARGET_IPHONE_SIMULATOR

    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Simulator" message:@"Camera not available." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    
#elif TARGET_OS_IPHONE
    
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePickerController.delegate = self;
    self.imagePickerController.allowsEditing = NO;
    
    if (self.useFrontCameraAsDefault){
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
    [self presentImagePickerController];
#endif

}

- (void)showGalleryImagePicker {
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.imagePickerController.delegate = self;
    self.imagePickerController.allowsEditing = NO;

    [self presentImagePickerController];
}

#pragma mark -
#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self showCameraImagePicker];
            break;
        case 1:
            [self showGalleryImagePicker];
            break;
    }
}

@end
