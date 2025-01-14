//
//  ViewController.m
//  Browser
//
//  Created by Steven Troughton-Smith on 20/09/2015.
//  Improved by Jip van Akker on 14/10/2015 through 10/01/2019
//

// Icons made by https://www.flaticon.com/authors/daniel-bruce Daniel Bruce from https://www.flaticon.com/ Flaticon" is licensed by  http://creativecommons.org/licenses/by/3.0/  CC 3.0 BY


#import "ViewController.h"

#pragma mark - UI

static UIColor *kTextColor() {
    if (@available(tvOS 13, *)) {
        return UIColor.labelColor;
    } else {
        return UIColor.blackColor;
    }
}

static UIImage *kDefaultCursor() {
    static UIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        image = [UIImage imageNamed: @"Cursor"];
    });
    return image;
}

static UIImage *kPointerCursor() {
    static UIImage *image;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        image = [UIImage imageNamed: @"Pointer"];
    });
    return image;
}

@interface ViewController()

@property id webview;
@property NSString *requestURL;
@property NSString *previousURL;
@property UIImageView *cursorView;
@property BOOL cursorMode;
@property BOOL displayedHintsOnLaunch;
@property BOOL scrollViewAllowBounces;
@property CGPoint lastTouchLocation;
@property NSUInteger textFontSize;
@property(readonly) BOOL topMenuShowing;
@property(readonly) CGFloat topMenuBrowserOffset;
@property UITapGestureRecognizer *touchSurfaceDoubleTapRecognizer;
@property UITapGestureRecognizer *playPauseDoubleTapRecognizer;

@end

@implementation ViewController
@synthesize textFontSize = _textFontSize;

- (void) viewDidAppear: (BOOL) animated {
    [super viewDidAppear: animated];
    //loadingSpinner.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
    [self webViewDidAppear];
    _displayedHintsOnLaunch = YES;
}

- (void) webViewDidAppear {
    if ([[NSUserDefaults standardUserDefaults] stringForKey: @"savedURLtoReopen"] != nil) {
        [self.webview loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] stringForKey: @"savedURLtoReopen"]]]];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"savedURLtoReopen"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if ([self.webview request] == nil) {
        //[self requestURLorSearchInput];
        [self loadHomePage];
    }

    if (![[NSUserDefaults standardUserDefaults] boolForKey: @"DontShowHintsOnLaunch"] && !_displayedHintsOnLaunch) {
        [self showHintsAlert];
    }
}

- (void) loadHomePage {
    if ([[NSUserDefaults standardUserDefaults] stringForKey: @"homepage"] != nil) {
        [self.webview loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] stringForKey: @"homepage"]]]];
    } else {
#pragma mark 记得改回来!
        // FIXME: 记得改回来!!!
        [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString: @"http://www.bing.com"]]];
        // [self.webview loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: @"https://v.youku.com/v_show/id_XNTIwMjY2MzMzMg==.html"]]];
        // [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString: @"http://www.youku.com"]]];
    }
}

- (void) initWebView {
    if (@available(tvOS 11.0, *)) {
        self.additionalSafeAreaInsets = UIEdgeInsetsZero;
    }

    self.webview = [[NSClassFromString(@"UIWebView") alloc] init];
    [self.webview setTranslatesAutoresizingMaskIntoConstraints: false];
    [self.webview setClipsToBounds: false];
    [self.webview setAllowsInlineMediaPlayback: YES];
    [self.webview setMediaPlaybackRequiresUserAction: YES];
    [self.webview setMediaPlaybackAllowsAirPlay: YES];
    [self.webview setAllowsPictureInPictureMediaPlayback: YES];
    //[self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.bing.com"]]];
    //[self.view addSubview: self.webview];
    [self.browserContainerView addSubview: self.webview];
    [self.webview setFrame: self.view.bounds];
    [self.webview setDelegate: self];
    [self.webview setLayoutMargins: UIEdgeInsetsZero];
    UIScrollView *scrollView = [self.webview scrollView];
    [scrollView setLayoutMargins: UIEdgeInsetsZero];

    if (@available(tvOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    NSNumber *showTopNavBar = [[NSUserDefaults standardUserDefaults] objectForKey: @"ShowTopNavigationBar"];
    self.topMenuView.hidden = !(showTopNavBar ? showTopNavBar.boolValue : YES);
    [self updateTopNavAndWebView];
    //scrollView.contentOffset = CGPointMake(0, topHeight);
    scrollView.contentOffset = CGPointZero;
    scrollView.contentInset = UIEdgeInsetsZero;
    scrollView.frame = self.view.bounds;
    scrollView.clipsToBounds = NO;
    [scrollView setNeedsLayout];
    [scrollView layoutIfNeeded];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    scrollView.bounces = self.scrollViewAllowBounces;
    scrollView.panGestureRecognizer.allowedTouchTypes = @[ @(UITouchTypeIndirect) ];
    scrollView.scrollEnabled = NO;
    [self.webview setUserInteractionEnabled: NO];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    self.definesPresentationContext = YES;
    [self initWebView];
    self.scrollViewAllowBounces = YES;
    self.touchSurfaceDoubleTapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget: self action: @selector(handleTouchSurfaceDoubleTap:)];
    self.touchSurfaceDoubleTapRecognizer.numberOfTapsRequired = 2;
    self.touchSurfaceDoubleTapRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger: UIPressTypeSelect]];
    [self.view addGestureRecognizer: self.touchSurfaceDoubleTapRecognizer];
    self.playPauseDoubleTapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget: self action: @selector(handlePlayPauseDoubleTap:)];
    self.playPauseDoubleTapRecognizer.numberOfTapsRequired = 2;
    self.playPauseDoubleTapRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger: UIPressTypePlayPause]];
    [self.view addGestureRecognizer: self.playPauseDoubleTapRecognizer];
    self.cursorView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0, 64, 64)];
    self.cursorView.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
    self.cursorView.image = kDefaultCursor();
    [self.view addSubview: self.cursorView];
    // Spinner now also in Storyboard.
    /*loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
     loadingSpinner.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
     loadingSpinner.tintColor = [UIColor blackColor];*/
    self.loadingSpinner.hidesWhenStopped = true;
    //[loadingSpinner startAnimating];
    //[self.view addSubview:loadingSpinner];
    //[self.browserContainerView addSubview:loadingSpinner]; // Now in Storyboard
    //[self.view bringSubviewToFront:loadingSpinner];
    //ENABLE CURSOR MODE INITIALLY
    self.cursorMode = YES;
    self.cursorView.hidden = NO;
}

#pragma mark - Font Size
- (NSUInteger) textFontSize {
    if (_textFontSize == 0) {
        NSNumber *textFontSizeValue = [[NSUserDefaults standardUserDefaults] objectForKey: @"TextFontSize"];

        if (textFontSizeValue != nil) {
            // Limit font size
            NSUInteger textFontSize = textFontSizeValue.unsignedIntegerValue;
            _textFontSize = MIN(200, MAX(50, textFontSize));
        } else {
            // Default font size
            _textFontSize = 100;
        }
    }

    return _textFontSize;
}

- (void) setTextFontSize: (NSUInteger) textFontSize {
    if (textFontSize == _textFontSize) {
        return;
    }

    // Limit font size
    textFontSize = MIN(200, MAX(50, textFontSize));
    _textFontSize = textFontSize;
    [[NSUserDefaults standardUserDefaults] setObject: @(textFontSize) forKey: @"TextFontSize"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) updateTextFontSize {
    NSString *jsString = [[NSString alloc] initWithFormat: @"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%lu%%'",
                                           (unsigned long)self.textFontSize];
    [self.webview stringByEvaluatingJavaScriptFromString: jsString];
}

#pragma mark - Top Navigation Bar

- (BOOL) topMenuShowing {
    return !self.topMenuView.isHidden;
}

- (CGFloat) topMenuBrowserOffset {
    if (self.topMenuShowing) {
        return self.topMenuView.frame.size.height;
    } else {
        return 0;
    }
}

- (void) hideTopNav {
    [self.topMenuView setHidden: YES];
    [self updateTopNavAndWebView];
    [[NSUserDefaults standardUserDefaults] setObject: @(NO) forKey: @"ShowTopNavigationBar"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) showTopNav {
    [self.topMenuView setHidden: NO];
    [self updateTopNavAndWebView];
    [[NSUserDefaults standardUserDefaults] setObject: @(YES) forKey: @"ShowTopNavigationBar"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) updateTopNavAndWebView {
    if (self.topMenuShowing) {
        [self.webview setFrame: CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y + self.topMenuBrowserOffset, self.view.bounds.size.width, self.view.bounds.size.height - self.topMenuBrowserOffset)];
    } else {
        [self.webview setFrame: self.view.bounds];
    }
}

- (void) showAdvancedMenu {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle: NSLocalizedString(@"Advanced Menu", nil)
                                          message: @""
                                          preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *topBarAction;

    if (self.topMenuShowing == YES) {
        topBarAction = [UIAlertAction
                        actionWithTitle: NSLocalizedString(@"Hide Top Navigation bar", nil)
                        style: UIAlertActionStyleDefault
        handler: ^ (UIAlertAction * action) {
            [self hideTopNav];
        }];
    } else {
        topBarAction = [UIAlertAction
                        actionWithTitle: NSLocalizedString(@"Show Top Navigation bar", nil)
                        style: UIAlertActionStyleDefault
        handler: ^ (UIAlertAction * action) {
            [self showTopNav];
        }];
    }

    UIAlertAction *loadHomePageAction = [UIAlertAction
                                         actionWithTitle: NSLocalizedString(@"Go To Home Page", nil)
                                         style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        [self loadHomePage];
    }];
    UIAlertAction *setHomePageAction = [UIAlertAction
                                        actionWithTitle: NSLocalizedString(@"Set Current Page As Home Page", nil)
                                        style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        NSURLRequest *request = [self.webview request];

        if (request != nil) {
            if (![request.URL.absoluteString isEqual: @""]) {
                [[NSUserDefaults standardUserDefaults] setObject: request.URL.absoluteString forKey: @"homepage"];
            }
        }
    }];
    UIAlertAction *showHintsAction = [UIAlertAction
                                      actionWithTitle: NSLocalizedString(@"Usage Guide", nil)
                                      style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        [self showHintsAlert];
    }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle: nil
                                   style: UIAlertActionStyleCancel
                                   handler: nil];
    UIAlertAction *viewFavoritesAction = [UIAlertAction
                                          actionWithTitle: NSLocalizedString(@"Favorites", nil)
                                          style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        NSArray *indexableArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"FAVORITES"];
        UIAlertController *historyAlertController = [UIAlertController
                alertControllerWithTitle: NSLocalizedString(@"Favorites", nil)
                message: @""
                preferredStyle: UIAlertControllerStyleAlert];
        UIAlertAction *editFavoritesAction = [UIAlertAction
                                              actionWithTitle: NSLocalizedString(@"Delete a Favorite", nil)
                                              style: UIAlertActionStyleDestructive
        handler: ^ (UIAlertAction * action) {
            NSArray *editingIndexableArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"FAVORITES"];
            UIAlertController *editHistoryAlertController = [UIAlertController
                    alertControllerWithTitle: @"Delete a Favorite"
                    message: NSLocalizedString(@"Select a Favorite to Delete", nil)
                    preferredStyle: UIAlertControllerStyleAlert];

            if (editingIndexableArray != nil) {
                for (int i = 0; i < [editingIndexableArray count]; i++) {
                    NSString *objectTitle = editingIndexableArray[i][1];
                    NSString *objectSubtitle = editingIndexableArray[i][0];

                    if (![[objectSubtitle stringByReplacingOccurrencesOfString: @" " withString: @""] isEqualToString: @""]) {
                        if ([[objectTitle stringByReplacingOccurrencesOfString: @" " withString: @""] isEqualToString: @""]) {
                            objectTitle = objectSubtitle;
                        }

                        UIAlertAction *favoriteItem = [UIAlertAction
                                                       actionWithTitle: objectTitle
                                                       style: UIAlertActionStyleDefault
                        handler: ^ (UIAlertAction * action) {
                            NSMutableArray *editingArray = [editingIndexableArray mutableCopy];
                            [editingArray removeObjectAtIndex: i];
                            NSArray *toStoreArray = editingArray;
                            [[NSUserDefaults standardUserDefaults] setObject: toStoreArray forKey: @"FAVORITES"];
                            [[NSUserDefaults standardUserDefaults] synchronize];
                        }];
                        [editHistoryAlertController addAction: favoriteItem];
                    }
                }
            }

            [editHistoryAlertController addAction: cancelAction];
            [self presentViewController: editHistoryAlertController animated: YES completion: nil];
        }];
        UIAlertAction *addToFavoritesAction = [UIAlertAction
                                               actionWithTitle: NSLocalizedString(@"Add Current Page to Favorites", nil)
                                               style: UIAlertActionStyleDefault
        handler: ^ (UIAlertAction * action) {
            NSString *theTitle = [self.webview stringByEvaluatingJavaScriptFromString: @"document.title"];
            NSURLRequest *request = [self.webview request];
            NSString *currentURL = request.URL.absoluteString;
            UIAlertController *favoritesAddToController = [UIAlertController
                    alertControllerWithTitle: NSLocalizedString(@"Name New Favorite", nil)
                    message: currentURL
                    preferredStyle: UIAlertControllerStyleAlert];
            [favoritesAddToController addTextFieldWithConfigurationHandler: ^ (UITextField * textField) {
                                         textField.keyboardType = UIKeyboardTypeDefault;
                                         textField.placeholder = NSLocalizedString(@"Name New Favorite", nil);
                textField.text = theTitle;
                textField.textColor = kTextColor();
                [textField setReturnKeyType: UIReturnKeyDone];
                [textField addTarget: self
                           action: @selector(alertTextFieldShouldReturn:)
                           forControlEvents: UIControlEventEditingDidEnd];
            }];
            UIAlertAction *saveAction = [UIAlertAction
                                         actionWithTitle: NSLocalizedString(@"Save", nil)
                                         style: UIAlertActionStyleDestructive
            handler: ^ (UIAlertAction * action) {
                UITextField *titleTextField = favoritesAddToController.textFields[0];
                NSString *savedTitle = titleTextField.text;

                if ([savedTitle isEqualToString: @""]) {
                    // Use raw URL if no title
                    savedTitle = currentURL;
                }

                NSArray *toSaveItem = [NSArray arrayWithObjects: currentURL, savedTitle, nil];
                NSMutableArray *historyArray = [NSMutableArray arrayWithObjects: toSaveItem, nil];

                if ([[NSUserDefaults standardUserDefaults] arrayForKey: @"FAVORITES"] != nil) {
                    historyArray = [[[NSUserDefaults standardUserDefaults] arrayForKey: @"FAVORITES"] mutableCopy];
                    [historyArray addObject: toSaveItem];
                }

                NSArray *toStoreArray = historyArray;
                [[NSUserDefaults standardUserDefaults] setObject: toStoreArray forKey: @"FAVORITES"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }];
            [favoritesAddToController addAction: saveAction];
            [favoritesAddToController addAction: cancelAction];
            [self presentViewController: favoritesAddToController animated: YES completion: nil];
            //UITextField *textFieldAlert = favoritesAddToController.textFields[0];
            //[textFieldAlert becomeFirstResponder];
        }];

        if (indexableArray != nil) {
            for (int i = 0; i < [indexableArray count]; i++) {
                NSString *objectTitle = indexableArray[i][1];
                NSString *objectURL = indexableArray[i][0];

                if ([[objectTitle stringByReplacingOccurrencesOfString: @" " withString: @""] isEqualToString: @""]) {
                    // Use raw URL if no title
                    objectTitle = objectURL;
                }

                UIAlertAction *favoriteItem = [UIAlertAction
                                               actionWithTitle: objectTitle
                                               style: UIAlertActionStyleDefault
                handler: ^ (UIAlertAction * action) {
                    [self.webview loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: objectURL]]];
                }];
                [historyAlertController addAction: favoriteItem];
            }
        }

        if ([[NSUserDefaults standardUserDefaults] arrayForKey: @"FAVORITES"] != nil) {
            if ([[[NSUserDefaults standardUserDefaults] arrayForKey: @"FAVORITES"] count] > 0) {
                [historyAlertController addAction: editFavoritesAction];
            }
        }

        [historyAlertController addAction: addToFavoritesAction];
        [historyAlertController addAction: cancelAction];
        [self presentViewController: historyAlertController animated: YES completion: nil];
    }];
    UIAlertAction *viewHistoryAction = [UIAlertAction
                                        actionWithTitle: NSLocalizedString(@"History", nil)
                                        style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        NSArray *indexableArray = [[NSUserDefaults standardUserDefaults] arrayForKey: @"HISTORY"];
        UIAlertController *historyAlertController = [UIAlertController
                alertControllerWithTitle: NSLocalizedString(@"History", nil)
                message: @""
                preferredStyle: UIAlertControllerStyleAlert];
        UIAlertAction *clearHistoryAction = [UIAlertAction
                                             actionWithTitle: NSLocalizedString(@"Clear History", nil)
                                             style: UIAlertActionStyleDestructive
        handler: ^ (UIAlertAction * action) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey: @"HISTORY"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }];

        if ([[NSUserDefaults standardUserDefaults] arrayForKey: @"HISTORY"] != nil) {
            [historyAlertController addAction: clearHistoryAction];
        }

        for (int i = 0; i < [indexableArray count]; i++) {
            NSString *objectTitle = indexableArray[i][1];
            NSString *objectSubtitle = indexableArray[i][0];

            if (![[objectSubtitle stringByReplacingOccurrencesOfString: @" " withString: @""] isEqualToString: @""]) {
                if ([[objectTitle stringByReplacingOccurrencesOfString: @" " withString: @""] isEqualToString: @""]) {
                    objectTitle = objectSubtitle;
                } else {
                    objectTitle = [NSString stringWithFormat: @"%@ - %@", objectTitle, objectSubtitle ];
                }

                UIAlertAction *historyItem = [UIAlertAction
                                              actionWithTitle: objectTitle
                                              style: UIAlertActionStyleDefault
                handler: ^ (UIAlertAction * action) {
                    [self.webview loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: indexableArray[i][0]]]];
                }];
                [historyAlertController addAction: historyItem];
            }
        }

        [historyAlertController addAction: cancelAction];
        [self presentViewController: historyAlertController animated: YES completion: nil];
    }];
    UIAlertAction *mobileModeAction = [UIAlertAction
                                       actionWithTitle: NSLocalizedString(@"Switch To Mobile Mode", nil)
                                       style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: @"Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Mobile/15E148 Safari/604.1", @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults: dictionary];
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"MobileMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSURLRequest *request = [self.webview request];

        if (request != nil) {
            if (![request.URL.absoluteString isEqual: @""]) {
                [[NSUserDefaults standardUserDefaults] setObject: request.URL.absoluteString forKey: @"savedURLtoReopen"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }

        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];

        for (NSHTTPCookie * cookie in [storage cookies]) {
            [storage deleteCookie: cookie];
        }

        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSURLSession sharedSession] resetWithCompletionHandler: ^ {
                                         dispatch_sync(dispatch_get_main_queue(), ^{
                                             [self.webview removeFromSuperview];
                [self initWebView];
                [self.view bringSubviewToFront: self.cursorView];
                //[self.view bringSubviewToFront:self->loadingSpinner];
                [self webViewDidAppear];

            });
        }];
    }];
    UIAlertAction *desktopModeAction = [UIAlertAction
                                        actionWithTitle: NSLocalizedString(@"Switch To Desktop Mode", nil)
                                        style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0 Safari/605.1.15", @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults: dictionary];
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"MobileMode"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSURLRequest *request = [self.webview request];

        if (request != nil) {
            if (![request.URL.absoluteString isEqual: @""]) {
                [[NSUserDefaults standardUserDefaults] setObject: request.URL.absoluteString forKey: @"savedURLtoReopen"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }

        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];

        for (NSHTTPCookie * cookie in [storage cookies]) {
            [storage deleteCookie: cookie];
        }

        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSURLSession sharedSession] resetWithCompletionHandler: ^ {
                                         dispatch_sync(dispatch_get_main_queue(), ^{
                                             [self.webview removeFromSuperview];
                [self initWebView];
                [self.view bringSubviewToFront: self.cursorView];
                //[self.view bringSubviewToFront:self->loadingSpinner];
                [self webViewDidAppear];

            });
        }];
    }];
    UIAlertAction *scalePageToFitAction = [UIAlertAction
                                           actionWithTitle: NSLocalizedString(@"Scale Pages to Fit", nil)
                                           style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"ScalePagesToFit"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.webview setScalesPageToFit: YES];
        [self.webview setContentMode: UIViewContentModeScaleAspectFit];
        [self.webview reload];
    }];
    UIAlertAction *stopScalePageToFitAction = [UIAlertAction
            actionWithTitle: NSLocalizedString(@"Stop Scaling Pages to Fit", nil)
            style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"ScalePagesToFit"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.webview setScalesPageToFit: NO];
        [self.webview reload];
    }];
    UIAlertAction *increaseFontSizeAction = [UIAlertAction
                                            actionWithTitle: NSLocalizedString(@"Increase Font Size", nil)
                                            style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        self.textFontSize += 5;
        [self updateTextFontSize];
    }];
    UIAlertAction *decreaseFontSizeAction = [UIAlertAction
                                            actionWithTitle: NSLocalizedString(@"Decrease Font Size", nil)
                                            style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        self.textFontSize -= 5;
        [self updateTextFontSize];
    }];
    UIAlertAction *clearCacheAction = [UIAlertAction
                                       actionWithTitle: NSLocalizedString(@"Clear Cache", nil)
                                       style: UIAlertActionStyleDestructive
    handler: ^ (UIAlertAction * action) {
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.previousURL = @"";
        [self.webview reload];
    }];
    UIAlertAction *clearCookiesAction = [UIAlertAction
                                         actionWithTitle: NSLocalizedString(@"Clear Cookies", nil)
                                         style: UIAlertActionStyleDestructive
    handler: ^ (UIAlertAction * action) {
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];

        for (NSHTTPCookie * cookie in [storage cookies]) {
            [storage deleteCookie: cookie];
        }

        [[NSUserDefaults standardUserDefaults] synchronize];
        self.previousURL = @"";
        [self.webview reload];
    }];
    UIAlertAction *lockAction = [UIAlertAction
                                 actionWithTitle: NSLocalizedString(@"Lock Browser", nil)
                                 style: UIAlertActionStyleDestructive
    handler: ^ (UIAlertAction * action) {
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"unlockerBrowser"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        exit(0);
    }];
    /*
    UIAlertAction *reloadAction = [UIAlertAction
    actionWithTitle:@"Reload Page"
    style:UIAlertActionStyleDefault
    handler:^(UIAlertAction *action) {
        _inputViewVisible = NO;
        previousURL = @"";
        [self.webview reload];
    }];
    if (self.webview.request != nil) {
        if (![self.webview.request.URL.absoluteString  isEqual: @""]) {
            [alertController addAction:reloadAction];
        }
    }
    */
    [alertController addAction: lockAction];
    [alertController addAction: viewFavoritesAction];
    [alertController addAction: viewHistoryAction];
    [alertController addAction: loadHomePageAction];
    [alertController addAction: setHomePageAction];

    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"MobileMode"]) {
        [alertController addAction: desktopModeAction];
    } else {
        [alertController addAction: mobileModeAction];
    }

    [alertController addAction: topBarAction];

    if ([self.webview scalesPageToFit]) {
        [alertController addAction: stopScalePageToFitAction];
    } else {
        [alertController addAction: scalePageToFitAction];
    }

    [alertController addAction: increaseFontSizeAction];
    [alertController addAction: decreaseFontSizeAction];
    [alertController addAction: clearCacheAction];
    [alertController addAction: clearCookiesAction];
    [alertController addAction: showHintsAction];
    [alertController addAction: cancelAction];
    [self presentViewController: alertController animated: YES completion: nil];
}

#pragma mark - Gesture
- (void) handlePlayPauseDoubleTap: (UITapGestureRecognizer *) sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self showAdvancedMenu];
    }
}
- (void) handleTouchSurfaceDoubleTap: (UITapGestureRecognizer *) sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self toggleMode];
    }
}

- (void) showInputURLorSearchGoogle {
    UIAlertController *alertController2 = [UIAlertController
                                           alertControllerWithTitle: NSLocalizedString(@"Enter URL or Search Terms", nil)
                                           message: @""
                                           preferredStyle: UIAlertControllerStyleAlert];
    [alertController2 addTextFieldWithConfigurationHandler: ^ (UITextField * textField) {
                         textField.keyboardType = UIKeyboardTypeURL;
                         textField.placeholder = NSLocalizedString(@"Enter URL or Search Terms", nil);
        textField.textColor = kTextColor();
        [textField setReturnKeyType: UIReturnKeyDone];
        [textField addTarget: self
                   action: @selector(alertTextFieldShouldReturn:)
                   forControlEvents: UIControlEventEditingDidEnd];
    }];
    UIAlertAction *goAction = [UIAlertAction
                               actionWithTitle: NSLocalizedString(@"Go To Website", nil)
                               style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        UITextField *urltextfield = alertController2.textFields[0];
        NSString *toMod = urltextfield.text;

        /*
         if ([toMod containsString:@" "] || ![temporaryURL containsString:@"."]) {
         toMod = [toMod stringByReplacingOccurrencesOfString:@" " withString:@"+"];
         toMod = [toMod stringByReplacingOccurrencesOfString:@"." withString:@"+"];
         toMod = [toMod stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
         toMod = [toMod stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
         toMod = [toMod stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
         toMod = [toMod stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
         if (toMod != nil) {
         [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/search?q=%@", toMod]]]];
         }
         else {
         [self requestURLorSearchInput];
         }
         }
         else {
         */
        if (![toMod isEqualToString: @""]) {
            if ([toMod containsString: @"http://"] || [toMod containsString: @"https://"]) {
                [self.webview loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: [NSString stringWithFormat: @"%@", toMod]]]];
            } else {
                [self.webview loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: [NSString stringWithFormat: @"http://%@", toMod]]]];
            }
        } else {
            [self requestURLorSearchInput];
        }

        //}
    }];
    UIAlertAction *searchAction = [UIAlertAction
                                   actionWithTitle: NSLocalizedString(@"Search Google", nil)
                                   style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        UITextField *urltextfield = alertController2.textFields[0];
        NSString *toMod = urltextfield.text;
        toMod = [toMod stringByReplacingOccurrencesOfString: @" " withString: @"+"];
        toMod = [toMod stringByReplacingOccurrencesOfString: @"." withString: @"+"];
        toMod = [toMod stringByReplacingOccurrencesOfString: @"++" withString: @"+"];
        toMod = [toMod stringByReplacingOccurrencesOfString: @"++" withString: @"+"];
        toMod = [toMod stringByReplacingOccurrencesOfString: @"++" withString: @"+"];
        toMod = [toMod stringByAddingPercentEncodingWithAllowedCharacters: [NSCharacterSet URLQueryAllowedCharacterSet]];

        if (toMod != nil) {
            [self.webview loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: [NSString stringWithFormat: @"https://www.google.com/search?q=%@", toMod]]]];
        } else {
            [self requestURLorSearchInput];
        }
    }];
    UIAlertAction *pdfAction = [UIAlertAction
                                actionWithTitle: NSLocalizedString(@"Open PDF", nil)
                                style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        UITextField *urltextfield = alertController2.textFields[0];
        NSString *toMod = urltextfield.text;

        if (![toMod isEqualToString: @""]) {
            NSString *realUrl;

            if ([toMod containsString: @"http://"] || [toMod containsString: @"https://"]) {
                realUrl = [NSString stringWithFormat: @"%@", toMod];
            } else {
                realUrl = [NSString stringWithFormat: @"http://%@", toMod];
            }

            [[NSUserDefaults standardUserDefaults] setObject: realUrl forKey: @"pdfUrl"];
            // TODO: 打开PDF页面
            //获取storyboard: 通过bundle根据storyboard的名字来获取我们的storyboard,
            UIStoryboard *story = [UIStoryboard storyboardWithName: @"PdfViewer" bundle: [NSBundle mainBundle]];
            //由storyboard根据myView的storyBoardID来获取我们要切换的视图
            UIViewController *pdfViewer = [story instantiateViewControllerWithIdentifier: @"pdfViewer"];
            // 设置主显示
            //[self.view.window setRootViewController:pdfViewer];
            [self.navigationController pushViewController: pdfViewer animated: YES];
        } else {
            [self requestURLorSearchInput];
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle: nil
                                   style: UIAlertActionStyleCancel
                                   handler: nil];
    [alertController2 addAction: searchAction];
    [alertController2 addAction: goAction];
    [alertController2 addAction: pdfAction];
    [alertController2 addAction: cancelAction];
    [self presentViewController: alertController2 animated: YES completion: nil];
    NSURLRequest *request = [self.webview request];

    if (request == nil) {
        UITextField *loginTextField = alertController2.textFields[0];
        [loginTextField becomeFirstResponder];
    } else if (![request.URL.absoluteString  isEqual: @""]) {
        UITextField *loginTextField = alertController2.textFields[0];
        [loginTextField becomeFirstResponder];
    }
}

- (void) requestURLorSearchInput {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle: NSLocalizedString(@"Quick Menu", nil)
                                          message: @""
                                          preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *forwardAction = [UIAlertAction
                                    actionWithTitle: NSLocalizedString(@"Go Forward", nil)
                                    style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        [self.webview goForward];
    }];
    UIAlertAction *reloadAction = [UIAlertAction
                                   actionWithTitle: NSLocalizedString(@"Reload Page", nil)
                                   style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        self.previousURL = @"";
        [self.webview reload];
    }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle: nil
                                   style: UIAlertActionStyleCancel
                                   handler: nil];
    UIAlertAction *inputAction = [UIAlertAction
                                  actionWithTitle: NSLocalizedString(@"Input URL or Search with Google", nil)
                                  style: UIAlertActionStyleDefault
    handler: ^ (UIAlertAction * action) {
        [self showInputURLorSearchGoogle];
    }];

    if ([self.webview canGoForward]) {
        [alertController addAction: forwardAction];
    }

    [alertController addAction: inputAction];
    NSURLRequest *request = [self.webview request];

    if (request != nil) {
        if (![request.URL.absoluteString  isEqual: @""]) {
            [alertController addAction: reloadAction];
        }
    }

    [alertController addAction: cancelAction];
    [self presentViewController: alertController animated: YES completion: nil];
}
#pragma mark - UIWebViewDelegate
- (void) webViewDidStartLoad: (id) webView {
    //[self.view bringSubviewToFront:loadingSpinner];
    if (![self.previousURL isEqualToString: self.requestURL]) {
        [self.loadingSpinner startAnimating];
    }

    self.previousURL = self.requestURL;
    NSLog(@"=======================> DidStartLoad URL: %@", self.requestURL);
}

- (void) webViewDidFinishLoad: (id) webView {
    [self.loadingSpinner stopAnimating];
    //[self.view bringSubviewToFront:loadingSpinner];
    NSString *theTitle = [webView stringByEvaluatingJavaScriptFromString: @"document.title"];
    NSURLRequest *request = [webView request];
    NSString *currentURL = request.URL.absoluteString;
    self.lblUrlBar.text = currentURL;
    // Update font size
    [self updateTextFontSize];
    NSArray *toSaveItem = [NSArray arrayWithObjects: currentURL, theTitle, nil];
    NSMutableArray *historyArray = [NSMutableArray arrayWithObjects: toSaveItem, nil];

    if ([[NSUserDefaults standardUserDefaults] arrayForKey: @"HISTORY"] != nil) {
        NSMutableArray *savedArray = [[[NSUserDefaults standardUserDefaults] arrayForKey: @"HISTORY"] mutableCopy];

        if ([savedArray count] > 0) {
            if ([savedArray[0][0] isEqualToString: currentURL]) {
                [historyArray removeObjectAtIndex: 0];
            }
        }

        [historyArray addObjectsFromArray: [[NSUserDefaults standardUserDefaults] arrayForKey: @"HISTORY"]];
    }

    while ([historyArray count] > 100) {
        [historyArray removeLastObject];
    }

    NSArray *toStoreArray = historyArray;
    [[NSUserDefaults standardUserDefaults] setObject: toStoreArray forKey: @"HISTORY"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 获取HTML内容
    // NSString *lJs = @"document.documentElement.innerHTML";
    // NSString *lHtml = [webView stringByEvaluatingJavaScriptFromString:lJs];
    // NSLog(@"html内容:%@",lHtml);
    
    // 获取Video
    static NSString *const jsGetVideoObj =
            @"function getVideoObj(){\
                var objs = document.getElementsByTagName(\"video\");\
                return JSON.stringify(objs);\
            };";
    [webView stringByEvaluatingJavaScriptFromString: jsGetVideoObj]; //注入js方法
    NSString *urlVideoResurlt = [webView stringByEvaluatingJavaScriptFromString: @"getVideoObj()"];
    if (urlVideoResurlt.length < 20) {
        return;
    }
    
    NSLog(@"Video为 = %@", urlVideoResurlt);
        
    // 获取Video的播放地址
    static NSString *const jsGetVideos =
        @"function getVideos(){\
        var objs = document.getElementsByTagName(\"video\");\
        var videoScr = '';\
        for(var i=0;i<objs.length;i++){\
            videoScr = videoScr + objs[i].src + '+';\
        };\
        return videoScr;\
    };";
    [webView stringByEvaluatingJavaScriptFromString: jsGetVideos]; //注入js方法
    NSString *urlResurlt = [webView stringByEvaluatingJavaScriptFromString: @"getVideos()"];
    NSMutableArray *_mUrlArray = [NSMutableArray arrayWithArray: [urlResurlt componentsSeparatedByString: @"+"]];

    for (NSString* url in _mUrlArray) {
        if ([self isBlankString:url]) {
            continue;
        }
        
        NSRange range = [url rangeOfString:@"EXTM3U"];
        if (range.length) {
            NSLog(@"视频地址为 = %@\n======================================\n开始解析视频地址", url);
            NSArray *arr = [url componentsSeparatedByString:@"#EXT-X-STREAM-INF"];
            NSString *lastPlayUrl = @"";
            for (NSString* subUrl in arr) {
                // (https?:\/\/.*m3u8.*)
                if ([subUrl rangeOfString:@"STREAMTYPE="].length) {
                    NSLog(@"Regex Split: %@", subUrl);
                    /*
                    typedef NS_OPTIONS(NSUInteger, NSRegularExpressionOptions) {
                       NSRegularExpressionCaseInsensitive             = 1 << 0, //不区分字母大小写的模式
                       NSRegularExpressionAllowCommentsAndWhitespace  = 1 << 1, //忽略掉正则表达式中的空格和#号之后的字符
                       NSRegularExpressionIgnoreMetacharacters        = 1 << 2, //将正则表达式整体作为字符串处理
                       NSRegularExpressionDotMatchesLineSeparators    = 1 << 3, //允许.匹配任何字符，包括换行符
                       NSRegularExpressionAnchorsMatchLines           = 1 << 4, //允许^和$符号匹配行的开头和结尾
                       NSRegularExpressionUseUnixLineSeparators       = 1 << 5, //设置\n为唯一的行分隔符，否则所有的都有效。
                       NSRegularExpressionUseUnicodeWordBoundaries    = 1 << 6 //使用Unicode TR#29标准作为词的边界，否则所有传统正则表达式的词边界都有效
                    };
                    */
                    NSError *error = NULL;
                    // 创建一个正则
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(https?://.*m3u8.*)" options:NSRegularExpressionCaseInsensitive error:&error];
                    /********************** 匹配方法 ************************/
                    //仅取出第一条匹配记录
                    NSTextCheckingResult *firstResult = [regex firstMatchInString:subUrl options:0 range:NSMakeRange(0, [subUrl length])];
                    if (firstResult) {
                        lastPlayUrl = [subUrl substringWithRange:firstResult.range];
                        
                        if ([lastPlayUrl hasSuffix:@"#EXT-X-ENDLIST"]) {
                            lastPlayUrl = [lastPlayUrl stringByReplacingOccurrencesOfString:@"#EXT-X-ENDLIST" withString:@""];
                        }
                        
                        NSLog(@"firstResult:%@", lastPlayUrl);
                    }
                    /*
                    //遍历所有匹配记录
                    NSArray *matches = [regex matchesInString:searchText
                                        options:0
                                        range:NSMakeRange(0, searchText.length)];
                    for (NSTextCheckingResult *match in matches) {
                        NSRange range = [match range];
                        NSString *mStr = [searchText substringWithRange:range];
                        NSLog(@"AllResult:%@", mStr);
                    }
                    */
                }
            }   // for
            if (![self isBlankString:lastPlayUrl]) {
                [[NSUserDefaults standardUserDefaults] setObject: lastPlayUrl forKey: @"videoUrl"];
                //获取storyboard: 通过bundle根据storyboard的名字来获取我们的storyboard,
                UIStoryboard *story = [UIStoryboard storyboardWithName: @"VLCPlayer" bundle: [NSBundle mainBundle]];
                //由storyboard根据myView的storyBoardID来获取我们要切换的视图
                UIViewController *playerView = [story instantiateViewControllerWithIdentifier: @"vlcPlayer"];
                //由navigationController推向我们要推向的view
                [self.navigationController pushViewController:playerView animated:YES];
                break;
            }
        }   // if (range.length)
    }   // for (NSString* url in _mUrlArray) {
        
    // 获取图片地址
    //static NSString *const jsGetImages =
    //    @"function getImages(){\
    //    var objs = document.getElementsByTagName(\"img\");\
    //    var imgScr = '';\
    //    for(var i=0;i<objs.length;i++){\
    //        imgScr = imgScr + objs[i].src + '+';\
    //    };\
    //    return imgScr;\
    //};";
    //[webView stringByEvaluatingJavaScriptFromString: jsGetImages]; //注入js方法
    //NSString *urlResurlt = [webView stringByEvaluatingJavaScriptFromString: @"getImages()"];
    //NSMutableArray *_mUrlArray = [NSMutableArray arrayWithArray: [urlResurlt componentsSeparatedByString: @"+"]];

    //if (_mUrlArray.count >= 2) {
    //    [_mUrlArray removeLastObject];
    //}

    //NSLog(@"图片地址为 = %@", _mUrlArray[0]);
}

- (BOOL) webView: (id) webView shouldStartLoadWithRequest: (NSURLRequest *) request navigationType: (NSInteger) navigationType {
    self.requestURL = request.URL.absoluteString;
    NSLog(@"=======================> shouldStartLoadWithRequest URL: %@", request.URL.absoluteString);
    return YES;
}

- (void) webView: (id) webView didFailLoadWithError: (NSError *) error {
    [self.loadingSpinner stopAnimating];

    if (![[NSString stringWithFormat: @"%lid", (long)error.code] containsString: @"999"] && ![[NSString stringWithFormat: @"%lid", (long)error.code] containsString: @"204"]) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle: NSLocalizedString(@"Could Not Load Webpage", nil)
                                              message: [error localizedDescription]
                                              preferredStyle: UIAlertControllerStyleAlert];
        UIAlertAction *searchAction = [UIAlertAction
                                       actionWithTitle: NSLocalizedString(@"Google This Page", nil)
                                       style: UIAlertActionStyleDefault
        handler: ^ (UIAlertAction * action) {
            if (self.requestURL != nil) {
                if ([self.requestURL length] > 1) {
                    NSString *lastChar = [self.requestURL substringFromIndex: [self.requestURL length] - 1];

                    if ([lastChar isEqualToString: @"/"]) {
                        NSString *newString = [self.requestURL substringToIndex: [self.requestURL length] - 1];
                        self.requestURL = newString;
                    }
                }
                self.requestURL = [self.requestURL stringByReplacingOccurrencesOfString: @"http://" withString: @""];
                self.requestURL = [self.requestURL stringByReplacingOccurrencesOfString: @"https://" withString: @""];
                self.requestURL = [self.requestURL stringByReplacingOccurrencesOfString: @"www." withString: @""];
                [self.webview loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: [NSString stringWithFormat: @"https://www.google.com/search?q=%@", self.requestURL]]]];
            }
        }];
        UIAlertAction *reloadAction = [UIAlertAction
                                       actionWithTitle: NSLocalizedString(@"Reload Page", nil)
                                       style: UIAlertActionStyleDefault
        handler: ^ (UIAlertAction * action) {
            self.previousURL = @"";
            [self.webview reload];
        }];
        UIAlertAction *newurlAction = [UIAlertAction
                                       actionWithTitle: NSLocalizedString(@"Enter a URL or Search", nil)
                                       style: UIAlertActionStyleDefault
        handler: ^ (UIAlertAction * action) {
            [self requestURLorSearchInput];
        }];
        UIAlertAction *cancelAction = [UIAlertAction
                                       actionWithTitle: nil
                                       style: UIAlertActionStyleCancel
                                       handler: nil];

        if (self.requestURL != nil) {
            if ([self.requestURL length] > 1) {
                [alertController addAction: searchAction];
            }
        }

        NSURLRequest *request = [self.webview request];

        if (request != nil) {
            if (![request.URL.absoluteString  isEqual: @""]) {
                [alertController addAction: reloadAction];
            } else {
                [alertController addAction: newurlAction];
            }
        } else {
            [alertController addAction: newurlAction];
        }

        [alertController addAction: cancelAction];
        [self presentViewController: alertController animated: YES completion: nil];
    }
}
#pragma mark - Helper
- (void) toggleMode {
    self.cursorMode = !self.cursorMode;
    UIScrollView *scrollView = [self.webview scrollView];

    if (self.cursorMode) {
        scrollView.scrollEnabled = NO;
        [self.webview setUserInteractionEnabled: NO];
        self.cursorView.hidden = NO;
    } else {
        scrollView.scrollEnabled = YES;
        [self.webview setUserInteractionEnabled: YES];
        self.cursorView.hidden = YES;
    }
}
- (void) showHintsAlert {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle: NSLocalizedString(@"Usage Guide", nil)
                                          message: NSLocalizedString(@"Double press the touch area to switch between cursor & scroll mode.\nPress the touch area while in cursor mode to click.\nSingle tap to Menu button to Go Back, or Exit on root page.\nSingle tap the Play/Pause button to: Go Forward, Enter URL or Reload Page.\nDouble tap the Play/Pause to show the Advanced Menu with more options.", nil)
                                          preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *hideForeverAction = [UIAlertAction
                                        actionWithTitle: NSLocalizedString(@"Don't Show This Again", nil)
                                        style: UIAlertActionStyleDestructive
    handler: ^ (UIAlertAction * action) {
        [[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"DontShowHintsOnLaunch"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
    UIAlertAction *showForeverAction = [UIAlertAction
                                        actionWithTitle: NSLocalizedString(@"Always Show On Launch", nil)
                                        style: UIAlertActionStyleDestructive
    handler: ^ (UIAlertAction * action) {
        [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"DontShowHintsOnLaunch"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle: NSLocalizedString(@"Dismiss", nil)
                                   style: UIAlertActionStyleCancel
    handler: ^ (UIAlertAction * action) {
    }];

    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"DontShowHintsOnLaunch"]) {
        [alertController addAction: showForeverAction];
    } else {
        [alertController addAction: hideForeverAction];
    }

    [alertController addAction: cancelAction];
    [self presentViewController: alertController animated: YES completion: nil];
}
- (void) alertTextFieldShouldReturn: (UITextField *) sender {
    /*
     _inputViewVisible = NO;
     UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
     if (alertController) {
     [alertController dismissViewControllerAnimated:true completion:nil];

     if ([temporaryURL containsString:@" "] || ![temporaryURL containsString:@"."]) {
     temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@" " withString:@"+"];
     temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"." withString:@"+"];
     temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
     temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
     temporaryURL = [temporaryURL stringByReplacingOccurrencesOfString:@"++" withString:@"+"];
     temporaryURL = [temporaryURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
     if (temporaryURL != nil) {
     [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/search?q=%@", temporaryURL]]]];
     } else {
     [self requestURLorSearchInput];
     }
     temporaryURL = nil;
     } else {
     if (temporaryURL != nil) {
     if ([temporaryURL containsString:@"http://"] || [temporaryURL containsString:@"https://"]) {
     [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", temporaryURL]]]];
     temporaryURL = nil;
     } else {
     [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", temporaryURL]]]];
     temporaryURL = nil;
     }
     } else {
     [self requestURLorSearchInput];
     }
     }
     }
     */
}
#pragma mark - Remote Button
- (void) pressesEnded: (NSSet<UIPress *> *) presses withEvent: (UIPressesEvent *) event {
    if (presses.anyObject.type == UIPressTypeMenu) {
        if ([self.webview canGoBack]) {
            [self.webview goBack];
        } else {
            UIAlertController *alertController = (UIAlertController *)self.presentedViewController;

            if (alertController) {
                [self.presentedViewController dismissViewControllerAnimated: true completion: nil];
            /*} else if ([self.webview canGoBack]) {
                [self.webview goBack];*/
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Exit App?", nil) message: nil preferredStyle: UIAlertControllerStyleAlert];
                [alert addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"Exit", nil) style: UIAlertActionStyleDestructive handler: ^ (UIAlertAction * _Nonnull action) {
                          exit(EXIT_SUCCESS);
                      }]];
                [alert addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"Dismiss", nil) style: UIAlertActionStyleCancel handler: nil]];
                [self presentViewController: alert animated: YES completion: nil];
            }
        }
    } else if (presses.anyObject.type == UIPressTypeUpArrow) {
        // Zoom testing (needs work) (requires old remote for up arrow)
        // UIScrollView * sv = self.webview.scrollView;
        // [sv setZoomScale:30];
    } else if (presses.anyObject.type == UIPressTypeDownArrow) {
    } else if (presses.anyObject.type == UIPressTypeSelect) { // Handle the normal single Touchpad press with our virtual cursor
        if (!self.cursorMode) {
            // [self toggleMode]; // This is now done in Double-tap
        } else {
            // Handle the virtual cursor
            CGPoint point = [self.view convertPoint: self.cursorView.frame.origin toView: self.webview];

            if (point.y < 0) {
                // Handle menu buttons press
                point = [self.view convertPoint: self.cursorView.frame.origin toView: self.topMenuView];
                CGRect backBtnFrameExtra = self.btnImageBack.frame;
                backBtnFrameExtra.origin.y = 0; // Enable cursor in upper right corner
                backBtnFrameExtra.size.height = backBtnFrameExtra.size.height + 8; // Enable cursor in upper right corner

                if (CGRectContainsPoint(backBtnFrameExtra, point)) {
                    [self.webview goBack];
                } else if (CGRectContainsPoint(self.btnImageRefresh.frame, point)) {
                    [self.webview reload];
                } else if (CGRectContainsPoint(self.btnImageForward.frame, point)) {
                    [self.webview goForward];
                } else if (CGRectContainsPoint(self.btnImageHome.frame, point)) {
                    [self loadHomePage];
                } else if (CGRectContainsPoint(self.lblUrlBar.frame, point)) {
                    [self showInputURLorSearchGoogle];
                } else if (CGRectContainsPoint(self.btnImageFullScreen.frame, point)) {
                    // Hide/show top bar:
                    if (self.topMenuShowing) {
                        [self hideTopNav];
                    } else {
                        [self showTopNav];
                    }
                }

                CGRect menuBtnFrameExtra = self.btnImgMenu.frame;
                menuBtnFrameExtra.origin.y = 0; // Enable cursor in upper right corner
                menuBtnFrameExtra.size.width = menuBtnFrameExtra.size.width + 100; // Enable cursor in upper right corner
                menuBtnFrameExtra.size.height = menuBtnFrameExtra.size.height + 100; // Enable cursor in upper right corner

                if (CGRectContainsPoint(menuBtnFrameExtra, point)) {
                    // Show advanced menu:
                    [self showAdvancedMenu];
                }
            } else { // Handle Press in the Browser view
                int displayWidth = [[self.webview stringByEvaluatingJavaScriptFromString: @"window.innerWidth"] intValue];
                CGFloat scale = [self.webview frame].size.width / displayWidth;
                point.x /= scale;
                point.y /= scale;
                [self.webview stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat: @"document.elementFromPoint(%i, %i).click()", (int)point.x, (int)point.y]];
                // Make the UIWebView method call
                NSString *fieldType = [self.webview stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat: @"document.elementFromPoint(%i, %i).type;", (int)point.x, (int)point.y]];
                /*
                if (fieldType == nil) {
                    NSString *contentEditible = [self.webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).getAttribute('contenteditable');", (int)point.x, (int)point.y]];
                    NSLog(contentEditible);
                    if ([contentEditible isEqualToString:@"true"]) {
                        fieldType = @"text";
                    }
                } else if ([[fieldType stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString: @""]) {
                    NSString *contentEditible = [self.webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).getAttribute('contenteditable');", (int)point.x, (int)point.y]];
                    NSLog(contentEditible);
                    if ([contentEditible isEqualToString:@"true"]) {
                        fieldType = @"text";
                    }
                }
                NSLog(fieldType);
                */
                fieldType = fieldType.lowercaseString;

                if ([fieldType isEqualToString: @"date"] || [fieldType isEqualToString: @"datetime"] || [fieldType isEqualToString: @"datetime-local"] || [fieldType isEqualToString: @"email"] || [fieldType isEqualToString: @"month"] || [fieldType isEqualToString: @"number"] || [fieldType isEqualToString: @"password"] || [fieldType isEqualToString: @"search"] || [fieldType isEqualToString: @"tel"] || [fieldType isEqualToString: @"text"] || [fieldType isEqualToString: @"time"] || [fieldType isEqualToString: @"url"] || [fieldType isEqualToString: @"week"]) {
                    NSString *fieldTitle = [self.webview stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat: @"document.elementFromPoint(%i, %i).title;", (int)point.x, (int)point.y]];

                    if ([fieldTitle isEqualToString: @""]) {
                        fieldTitle = fieldType;
                    }

                    NSString *placeholder = [self.webview stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat: @"document.elementFromPoint(%i, %i).placeholder;", (int)point.x, (int)point.y]];

                    if ([placeholder isEqualToString: @""]) {
                        if (![fieldTitle isEqualToString: fieldType]) {
                            placeholder = [NSString stringWithFormat: @"%@ Input", fieldTitle];
                        } else {
                            placeholder = @"Text Input";
                        }
                    }

                    NSString *testedFormResponse = [self.webview stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat: @"document.elementFromPoint(%i, %i).form.hasAttribute('onsubmit');", (int)point.x, (int)point.y]];
                    UIAlertController *alertController = [UIAlertController
                                                          alertControllerWithTitle: @"Input Text"
                                                          message: [fieldTitle capitalizedString]
                                                          preferredStyle: UIAlertControllerStyleAlert];
                    [alertController addTextFieldWithConfigurationHandler: ^ (UITextField * textField) {
                                        if ([fieldType isEqualToString: @"url"]) {
                                            textField.keyboardType = UIKeyboardTypeURL;
                        } else if ([fieldType isEqualToString: @"email"]) {
                            textField.keyboardType = UIKeyboardTypeEmailAddress;
                        } else if ([fieldType isEqualToString: @"tel"] || [fieldType isEqualToString: @"number"] || [fieldType isEqualToString: @"date"] || [fieldType isEqualToString: @"datetime"] || [fieldType isEqualToString: @"datetime-local"]) {
                            textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                        } else {
                            textField.keyboardType = UIKeyboardTypeDefault;
                        }

                        textField.placeholder = [placeholder capitalizedString];

                        if ([fieldType isEqualToString: @"password"]) {
                            textField.secureTextEntry = YES;
                        }

                        textField.text = [self.webview stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat: @"document.elementFromPoint(%i, %i).value;", (int)point.x, (int)point.y]];
                        textField.textColor = kTextColor();
                        [textField setReturnKeyType: UIReturnKeyDone];
                        [textField addTarget: self
                                   action: @selector(alertTextFieldShouldReturn:)
                                   forControlEvents: UIControlEventEditingDidEnd];
                    }];
                    UIAlertAction *inputAndSubmitAction = [UIAlertAction
                                                           actionWithTitle: @"Submit"
                                                           style: UIAlertActionStyleDefault
                    handler: ^ (UIAlertAction * action) {
                        UITextField *inputViewTextField = alertController.textFields[0];
                        NSString *javaScript = [NSString stringWithFormat: @"var textField = document.elementFromPoint(%i, %i);"
                                                         "textField.value = '%@';"
                                                         "textField.form.submit();"
                                                         //"var ev = document.createEvent('KeyboardEvent');"
                                                         //"ev.initKeyEvent('keydown', true, true, window, false, false, false, false, 13, 0);"
                                                         //"document.body.dispatchEvent(ev);"
                                                         , (int)point.x, (int)point.y, inputViewTextField.text];
                        [self.webview stringByEvaluatingJavaScriptFromString: javaScript];
                    }];
                    UIAlertAction *inputAction = [UIAlertAction
                                                  actionWithTitle: @"Done"
                                                  style: UIAlertActionStyleDefault
                    handler: ^ (UIAlertAction * action) {
                        UITextField *inputViewTextField = alertController.textFields[0];
                        NSString *javaScript = [NSString stringWithFormat: @"var textField = document.elementFromPoint(%i, %i);"
                                                         "textField.value = '%@';", (int)point.x, (int)point.y, inputViewTextField.text];
                        [self.webview stringByEvaluatingJavaScriptFromString: javaScript];
                    }];
                    UIAlertAction *cancelAction = [UIAlertAction
                                                   actionWithTitle: nil
                                                   style: UIAlertActionStyleCancel
                                                   handler: nil];
                    [alertController addAction: inputAction];

                    if (testedFormResponse != nil) {
                        if ([testedFormResponse isEqualToString: @"true"]) {
                            [alertController addAction: inputAndSubmitAction];
                        }
                    }

                    [alertController addAction: cancelAction];
                    [self presentViewController: alertController animated: YES completion: nil];
                    UITextField *inputViewTextField = alertController.textFields[0];

                    if ([[inputViewTextField.text stringByReplacingOccurrencesOfString: @" " withString: @""] isEqualToString: @""]) {
                        [inputViewTextField becomeFirstResponder];
                    }
                } else {
                    //[self.webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.elementFromPoint(%i, %i).click()", (int)point.x, (int)point.y]];
                }

                //[self toggleMode];
            }
        }
    } else if (presses.anyObject.type == UIPressTypePlayPause) {
        UIAlertController *alertController = (UIAlertController *)self.presentedViewController;

        if (alertController) {
            [self.presentedViewController dismissViewControllerAnimated: true completion: nil];
        } else {
            [self requestURLorSearchInput];
        }
    }
}

#pragma mark - Cursor Input

- (void) touchesBegan: (NSSet<UITouch *> *) touches withEvent: (UIEvent *) event {
    self.lastTouchLocation = CGPointMake(-1, -1);
}

- (void) touchesMoved: (NSSet<UITouch *> *) touches withEvent: (UIEvent *) event {
    for (UITouch * touch in touches) {
        CGPoint location = [touch locationInView: self.webview];

        if (self.lastTouchLocation.x == -1 && self.lastTouchLocation.y == -1) {
            // Prevent cursor from recentering
            self.lastTouchLocation = location;
        } else {
            CGFloat xDiff = location.x - self.lastTouchLocation.x;
            CGFloat yDiff = location.y - self.lastTouchLocation.y;
            CGRect rect = self.cursorView.frame;

            if (rect.origin.x + xDiff >= 0 && rect.origin.x + xDiff <= 1920) {
                rect.origin.x += xDiff;    //location.x - self.startPos.x;//+= xDiff; //location.x;
            }

            if (rect.origin.y + yDiff >= 0 && rect.origin.y + yDiff <= 1080) {
                rect.origin.y += yDiff;    //location.y - self.startPos.y;//+= yDiff; //location.y;
            }

            self.cursorView.frame = rect;
            self.lastTouchLocation = location;
        }

        // Try to make mouse cursor become pointer icon when pointer element is clickable
        self.cursorView.image = kDefaultCursor();

        if ([self.webview request] == nil) {
            return;
        }

        if (self.cursorMode) {
            CGPoint point = [self.view convertPoint: self.cursorView.frame.origin toView: self.webview];

            if (point.y < 0) {
                return;
            }

            int displayWidth = [[self.webview stringByEvaluatingJavaScriptFromString: @"window.innerWidth"] intValue];
            CGFloat scale = [self.webview frame].size.width / displayWidth;
            point.x /= scale;
            point.y /= scale;
            // Seems not so low, check everytime when touchesMoved
            NSString *containsLink = [self.webview stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat: @"document.elementFromPoint(%i, %i).closest('a, input') !== null", (int)point.x, (int)point.y]];

            if ([containsLink isEqualToString: @"true"]) {
                self.cursorView.image = kPointerCursor();
            }
        }

        // We only use one touch, break the loop
        break;
    }
}

- (BOOL) isBlankString: (NSString *) val {
    if (!val) {
        return YES;
    }

    if ([val isKindOfClass: [NSNull class]]) {
        return YES;
    }

    if (!val.length) {
        return YES;
    }

    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmedStr = [val stringByTrimmingCharactersInSet: set];

    if (!trimmedStr.length) {
        return YES;
    }

    return NO;
}

@end
