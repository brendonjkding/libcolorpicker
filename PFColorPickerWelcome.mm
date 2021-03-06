#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import <objc/runtime.h>

extern "C" void LCPOpenTwitterUsername(NSString *username);

@interface LCPWelcomeTwitterHandler : NSObject <UIAlertViewDelegate>
@property (nonatomic, retain) NSString *username;
@end

@implementation LCPWelcomeTwitterHandler
@synthesize username;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
    switch (alertView.tag) {
        case 1: {
            if (index == 1)
                [self dropMeAFollow];
            break;
        }

        case 2: {
            NSArray *accounts = objc_getAssociatedObject(alertView, @selector(description));

            if (index == 0)
                for (ACAccount *currentAccount in accounts)
                    [self followWithAccount:currentAccount];
            else
                [self followWithAccount:accounts[index - 1]];

            UIAlertView *followedAlert = [[UIAlertView alloc] initWithTitle:@"Done <3" message:@"Just moving around a few things aaaaaand..... hah! Just kidding. Thanks for following me. Enjoy the tweak! :)" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Will do!", nil];
            [followedAlert show];
            break;
        }

        default:
            break;
    }
}

- (void)dropMeAFollow {
    ACAccountStore *accountStore = [ACAccountStore new];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
        if (granted) {
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            if ([accounts count] == 1) {
                [self followWithAccount:[accounts firstObject]];

                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *followedAlert = [[UIAlertView alloc] initWithTitle:@"Done <3" message:@"Awesome. Thanks for following me ^-^" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"You're welcome <3", nil];
                    [followedAlert show];
                });
            } else if ([accounts count] > 1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *pickAccountAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Looks like you have multiple Twitter accounts on this device. Which one would you like to use?" delegate:self cancelButtonTitle:@"All!" otherButtonTitles:nil];

                    for (ACAccount *account in accounts)
                        [pickAccountAlert addButtonWithTitle:account.username];

                    pickAccountAlert.tag = 2;

                    objc_setAssociatedObject(pickAccountAlert, @selector(show), self, OBJC_ASSOCIATION_RETAIN);
                    objc_setAssociatedObject(pickAccountAlert, @selector(description), accounts, OBJC_ASSOCIATION_RETAIN);

                    [pickAccountAlert show];
                });
            } else if ([accounts count] < 1)
                LCPOpenTwitterUsername(self.username);
        }
    }];
    #pragma clang diagnostic pop
}

- (void)followWithAccount:(ACAccount *)account {
    NSDictionary *postParameters = [NSDictionary dictionaryWithObjectsAndKeys:self.username, @"screen_name", @"FALSE", @"follow", nil];
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/friendships/create.json"] parameters:postParameters];

    [request setAccount:account];
    [request performRequestWithHandler:nil];
    // ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
    //     if ([urlResponse statusCode] == 200) {
    //         NSError *error;
    //         NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
    //         NSLog(@"Twitter response: %@", dict);
    //     } else {
    //         NSLog(@"Twitter error, HTTP response: %i", [urlResponse statusCode]);
    //     }
    // }];
}

@end

extern "C" void LCPShowTwitterFollowAlert(UIViewController *viewController,
                                          NSString *title,
                                          NSString *welcomeMessage,
                                          NSString *twitterUsername) {
    NSString *okChoice = @"I'd love to!";
    NSString *noThanks = @"No thanks";

    if (UIAlertController.class) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:welcomeMessage
                                                                preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:okChoice
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
            LCPOpenTwitterUsername(twitterUsername);
        }];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:noThanks
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];

        [alert addAction:defaultAction];
        [alert addAction:cancelAction];
        [viewController presentViewController:alert animated:YES completion:nil];
    } else {
        LCPWelcomeTwitterHandler *handler = [LCPWelcomeTwitterHandler new];
        handler.username = twitterUsername;
        UIAlertView *welcomeAlert = [[UIAlertView alloc] initWithTitle:title
                                                               message:welcomeMessage
                                                              delegate:handler
                                                     cancelButtonTitle:noThanks
                                                     otherButtonTitles:okChoice, nil];
        welcomeAlert.tag = 1;
        objc_setAssociatedObject(welcomeAlert, @selector(show), handler, OBJC_ASSOCIATION_RETAIN);
        [welcomeAlert show];
    }
}

extern "C" void LCPOpenTwitterUsername(NSString *username) {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"https://twitter.com/intent/follow?screen_name=" stringByAppendingString:username]]];
}
