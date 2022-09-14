//
//  UINavigationController+UIChooseNavigationController.m
//  BananaATVBrowser
//
//  Created by 花心胡萝卜 on 9/9/22.
//  Copyright © 2022 High Caffeine Content. All rights reserved.
//

#import "UIChooseNavigationController.h"

@interface UIChooseNavigationController()

@end

@implementation UIChooseNavigationController

- (void) viewDidLoad {
    [super viewDidLoad];

    // 检查配置值
    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"unlockerBrowser"]) {
        NSLog(@"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBrowser page!");
        //[self showBrowser];
        //获取storyboard: 通过bundle根据storyboard的名字来获取我们的storyboard,
        UIStoryboard *story = [UIStoryboard storyboardWithName: @"Main" bundle: [NSBundle mainBundle]];
        //由storyboard根据myView的storyBoardID来获取我们要切换的视图
        UIViewController *browserView = [story instantiateViewControllerWithIdentifier: @"browserView"];
        //由navigationController推向我们要推向的view
        [self pushViewController: browserView animated: YES];
    } else {
        NSLog(@"OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO page!");
        //获取storyboard: 通过bundle根据storyboard的名字来获取我们的storyboard,
        UIStoryboard *story = [UIStoryboard storyboardWithName: @"Startup" bundle: [NSBundle mainBundle]];
        //由storyboard根据myView的storyBoardID来获取我们要切换的视图
        UIViewController *startupView = [story instantiateViewControllerWithIdentifier: @"startupView"];
        //由navigationController推向我们要推向的view
        [self pushViewController: startupView animated: YES];
    }
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
