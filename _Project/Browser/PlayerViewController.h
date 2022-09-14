//
//  UIViewController+PlayerViewController.h
//  BananaATVBrowser
//
//  Created by 花心胡萝卜 on 9/14/22.
//  Copyright © 2022 High Caffeine Content. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerViewController: UIViewController

@property (nonatomic, strong) IBOutlet UIView *movieView;
- (IBAction)playandPause:(id)sender;

@end

NS_ASSUME_NONNULL_END
