//
//  StartupViewController.h
//  BananaATVBrowser
//
//  Created by 花心胡萝卜 on 9/7/22.
//  Copyright © 2022 High Caffeine Content. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface StartupViewController : UIViewController

#pragma mark 文本框输入内容
@property (nonatomic, strong) IBOutlet UITextField *txtSearch;

#pragma mark 滚动视图
@property (nonatomic, strong) IBOutlet UIScrollView *subView;
#pragma mark 滚动子视图
@property (nonatomic, strong) IBOutlet UIView *subViewDisplay;

#pragma mark 搜索事件
- (IBAction)search:(UIButton *) btnSearch;

#pragma mark 弹出提示框
- (void)showToast:(NSString *) msg title:(NSString*)title;

#pragma mark 特殊的提示框 会退出程序
- (void)showToastAndExit:(NSString *) msg title:(NSString*)title;

//定义确定和取消按钮
@property (strong, nonatomic) UIAlertAction *okBtn;
@property (strong, nonatomic) UIAlertAction *cancelBtn;
#pragma mark 弹出提示框 确定/取消
- (void)showToastTwoBtn:(NSString *) msg;

#pragma mark 判断是否是空字符串
- (BOOL)isBlankString:(NSString *)val;

#pragma mark 启动浏览器界面
- (void)showBrowser;

@end

NS_ASSUME_NONNULL_END
