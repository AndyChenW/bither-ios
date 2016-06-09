//
//  ColdAddressListHDCell.m
//  bither-ios
//
//  Created by 宋辰文 on 15/7/16.
//  Copyright (c) 2015年 Bither. All rights reserved.
//

#import <Bitheri/NSString+Base58.h>
#import "ColdAddressListHDCell.h"
#import "DialogProgress.h"
#import "DialogPassword.h"
#import "DialogXrandomInfo.h"
#import "DialogWithActions.h"
#import "DialogBlackQrCode.h"
#import "DialogHDMSeedWordList.h"
#import "DialogHDColdFirst20Addresses.h"

@interface ColdAddressListHDCell () <DialogPasswordDelegate> {
    BTHDAccountCold *_account;
    NSString *password;
    SEL passwordSelector;
    DialogProgress *dp;
}
@property(weak, nonatomic) IBOutlet UIImageView *ivXRandom;
@property(weak, nonatomic) IBOutlet UIImageView *ivType;

@property(strong, nonatomic) UILongPressGestureRecognizer *longPress;
@property(strong, nonatomic) UILongPressGestureRecognizer *xrandomLongPress;
@end

@implementation ColdAddressListHDCell

- (void)setAccount:(BTHDAccountCold *)account {
    _account = account;
    if (!self.longPress) {
        self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTableviewCellLongPressed:)];
    }
    if (!self.xrandomLongPress) {
        self.xrandomLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleXrandomLabelLongPressed:)];
    }
    if (![self.ivType.gestureRecognizers containsObject:self.longPress]) {
        [self.ivType addGestureRecognizer:self.longPress];
    }
    if (![self.ivXRandom.gestureRecognizers containsObject:self.xrandomLongPress]) {
        [self.ivXRandom addGestureRecognizer:self.xrandomLongPress];
    }
    if (!dp) {
        dp = [[DialogProgress alloc] initWithMessage:NSLocalizedString(@"Please wait…", nil)];
    }
    self.ivXRandom.hidden = !_account.isFromXRandom;
}

- (BTHDAccountCold *)account {
    return _account;
}

- (IBAction)seedPressed:(id)sender {
    [[[DialogWithActions alloc] initWithActions:@[
            [[Action alloc] initWithName:NSLocalizedString(@"add_hd_account_seed_qr_code", nil) target:self andSelector:@selector(showSeedQRCode)],
            [[Action alloc] initWithName:NSLocalizedString(@"add_hd_account_seed_qr_phrase", nil) target:self andSelector:@selector(showPhrase)],
            [[Action alloc] initWithName:NSLocalizedString(@"hd_account_cold_first_20_addresses", nil) target:self andSelector:@selector(showFirst20Addresses)]
    ]] showInWindow:self.window];
}


- (IBAction)qrPressed:(id)sender {
    [[[DialogWithActions alloc] initWithActions:@[
            [[Action alloc] initWithName:NSLocalizedString(@"add_cold_hd_account_monitor_qr", nil) target:self andSelector:@selector(showAccountQrCode)]
    ]] showInWindow:self.window];
}

- (void)showAccountQrCode {
    if (!password) {
        passwordSelector = @selector(showAccountQrCode);
        [[[DialogPassword alloc] initWithDelegate:self] showInWindow:self.window];
        return;
    }
    NSString *p = password;
    password = nil;
    __weak __block DialogProgress *d = dp;
    [d showInWindow:self.window completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSString *pub = [[self.account xPub:p] serializePubB58];
            dispatch_async(dispatch_get_main_queue(), ^{
                [d dismissWithCompletion:^{
                    DialogBlackQrCode *d = [[DialogBlackQrCode alloc] initWithContent:pub andTitle:NSLocalizedString(@"add_cold_hd_account_monitor_qr", nil)];
                    [d showInWindow:self.window];
                }];
            });
        });
    }];
}

- (void)showPhrase {
    if (!password) {
        passwordSelector = @selector(showPhrase);
        [[[DialogPassword alloc] initWithDelegate:self] showInWindow:self.window];
        return;
    }
    NSString *p = password;
    password = nil;
    __weak __block DialogProgress *d = dp;
    [d showInWindow:self.window completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSArray *words = [self.account seedWords:p];
            dispatch_async(dispatch_get_main_queue(), ^{
                [d dismissWithCompletion:^{
                    [[[DialogHDMSeedWordList alloc] initWithWords:words] showInWindow:self.window];
                }];
            });
        });
    }];
}

- (void)showFirst20Addresses {
    if (!password) {
        passwordSelector = @selector(showFirst20Addresses);
        [[[DialogPassword alloc] initWithDelegate:self] showInWindow:self.window];
        return;
    }
    [[[DialogHDColdFirst20Addresses alloc]initWithAccount:self.account andPassword:password] showInWindow:self.window];
}

- (void)showSeedQRCode {
    if (!password) {
        passwordSelector = @selector(showSeedQRCode);
        [[[DialogPassword alloc] initWithDelegate:self] showInWindow:self.window];
        return;
    }
    password = nil;
    __weak __block DialogProgress *d = dp;
    [d showInWindow:self.window completion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            __block NSString *pub = [self.account getQRCodeFullEncryptPrivKey];
            dispatch_async(dispatch_get_main_queue(), ^{
                [d dismissWithCompletion:^{
                    DialogBlackQrCode *d = [[DialogBlackQrCode alloc] initWithContent:pub andTitle:NSLocalizedString(@"add_hd_account_seed_qr_code", nil)];
                    [d showInWindow:self.window];
                }];
            });
        });
    }];
}


- (void)onPasswordEntered:(NSString *)p {
    password = p;
    if (passwordSelector && [self respondsToSelector:passwordSelector]) {
        [self performSelector:passwordSelector];
    }
    passwordSelector = nil;
}

- (void)handleXrandomLabelLongPressed:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [[[DialogXrandomInfo alloc] init] showInWindow:self.window];
    }
}

- (void)handleTableviewCellLongPressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self seedPressed:nil];
    }
}
@end
