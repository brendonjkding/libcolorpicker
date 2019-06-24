#import "PFColorAlert.h"
#import "PFColorAlertViewController.h"
#import "UIColor+PFColor.h"
#import <objc/runtime.h>

extern void LCPShowTwitterFollowAlert(NSString *title, NSString *welcomeMessage, NSString *twitterUsername);


@interface PFColorAlert()
@property (nonatomic, retain) UIWindow *darkeningWindow;
@property (nonatomic, retain) PFColorAlertViewController *mainViewController;
@property (nonatomic, assign) BOOL isOpen;
@property (nonatomic, copy) void (^completionBlock)(UIColor *pickedColor);
@end


@implementation PFColorAlert

+ (PFColorAlert *)colorAlertWithStartColor:(UIColor *)startColor showAlpha:(BOOL)showAlpha {
    return [[PFColorAlert alloc] initWithStartColor:startColor showAlpha:showAlpha];
}

- (PFColorAlert *)initWithStartColor:(UIColor *)startColor showAlpha:(BOOL)showAlpha {
    self = [super init];

    self.isOpen = NO;

    self.darkeningWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.darkeningWindow.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f];

    CGRect winFrame = [UIScreen mainScreen].bounds;

    float winWidthCalc = winFrame.size.width * 0.09f;
    float winHeightCalc = winFrame.size.height * 0.09f;

    winFrame.origin.x = winWidthCalc / 2;
    winFrame.origin.y = winHeightCalc / 2;

    winFrame.size.width = winFrame.size.width - winWidthCalc;
    winFrame.size.height = winFrame.size.height - winHeightCalc;

    self.popWindow = [[UIWindow alloc] initWithFrame:winFrame];
    self.popWindow.layer.masksToBounds = true;
    self.popWindow.layer.cornerRadius = 15;

    self.mainViewController = [[PFColorAlertViewController alloc] initWithViewFrame:CGRectMake(0, 0, winFrame.size.width, winFrame.size.height)
                                                                         startColor:startColor
                                                                          showAlpha:showAlpha];

    self.darkeningWindow.hidden = NO;
    self.darkeningWindow.alpha = 0.0f;
    [self.darkeningWindow makeKeyAndVisible];

    self.popWindow.rootViewController = self.mainViewController;
    // self.darkeningWindow.windowLevel = UIWindowLevelAlert - 2;
    // self.popWindow.windowLevel = UIWindowLevelAlert - 1;
    self.popWindow.backgroundColor = UIColor.clearColor;
    self.popWindow.hidden = NO;
    self.popWindow.alpha = 0.0f;

    [self makeViewDynamic:self.popWindow];
    CGRect popWindowFrame = self.popWindow.frame;
    popWindowFrame.origin.y = ([UIScreen mainScreen].bounds.size.height - popWindowFrame.size.height) / 2;

    self.popWindow.frame = popWindowFrame;

    return self;
}

- (void)makeViewDynamic:(UIView *)view {
    CGRect dynamicFrame = view.frame;
    dynamicFrame.size.height = [self.mainViewController topMostSliderLastYCoordinate] +
                               self.mainViewController.view.frame.size.width / 6;

    view.frame = dynamicFrame;
}

- (void)displayWithCompletion:(void (^)(UIColor *pickedColor))completionBlock {
    if (self.isOpen)
        return;

    self.completionBlock = completionBlock;

    [self.popWindow makeKeyAndVisible];

    [UIView animateWithDuration:0.3f animations:^{
        self.darkeningWindow.alpha = 1.0f;
        self.popWindow.alpha = 1.0f;
    } completion:^(BOOL finished) {
        self.isOpen = YES;

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
        self.darkeningWindow.userInteractionEnabled = YES;
        [self.darkeningWindow addGestureRecognizer:tapGesture];

        NSString *prefPath = @"/var/mobile/Library/Preferences/com.pixelfiredev.libcolorpicker.plist";
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:prefPath];
        if (!dict)
            dict = [NSMutableDictionary new];

        NSString *kDidShow = @"didShowWelcomeScreen";
        if (!dict[kDidShow]) {
            LCPShowTwitterFollowAlert(@"Welcome to libcolorpicker!", @"Hey there! Thanks for installing libcolorpicker (the color picker library for devs)! If you'd like to follow our team on Twitter for more updates, tweak giveaways and other cool stuff, hit the button below!", @"PixelFireDev");
            [dict setObject:@YES forKey:kDidShow];
            [dict writeToFile:prefPath atomically:YES];
        }
    }];
}

- (void)showWithStartColor:(UIColor *)startColor showAlpha:(BOOL)showAlpha completion:(void (^)(UIColor *pickedColor))completionBlock {
    UIAlertView *deprecated = [[UIAlertView alloc] initWithTitle:@"libcolorpicker" message:@"Hey! It appears like this preference bundle is trying to use deprecated methods to invoke the color picker and requires an update. Please inform the dev of this tweak about it."
                                                        delegate:nil
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"OK", nil];
    [deprecated show];
}

- (void)chooseHexColor {
    UIAlertView *prompt = [[UIAlertView alloc] initWithTitle:@"Hex Color"
                                                     message:@"Enter a hex color or copy it to your pasteboard."
                                                    delegate:self
                                           cancelButtonTitle:@"Close"
                                           otherButtonTitles:@"Set", @"Copy", nil];
    prompt.delegate = self;
    [prompt setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[prompt textFieldAtIndex:0] setText:[UIColor hexFromColor:[self.mainViewController getColor]]];
    [prompt show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if ([[alertView textFieldAtIndex:0].text hasPrefix:@"#"] && [UIColor PF_colorWithHex:[alertView textFieldAtIndex:0].text])
            [self.mainViewController setPrimaryColor:[UIColor PF_colorWithHex:[alertView textFieldAtIndex:0].text]];
    } else if (buttonIndex == 2) {
        [[UIPasteboard generalPasteboard] setString:[UIColor hexFromColor:[self.mainViewController getColor]]];
    }
}

- (void)close {
    if (!self.isOpen)
        return;

    [UIView animateWithDuration:0.3f animations:^{
        self.darkeningWindow.alpha = 0.0f;
        self.popWindow.alpha = 0.0f;
    } completion:^(BOOL finished) {
        if (self.completionBlock)
            self.completionBlock([self.mainViewController getColor]);

        self.popWindow.hidden = YES;
        self.isOpen = NO;
    }];
}

@end
