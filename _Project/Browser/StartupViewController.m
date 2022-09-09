//
//  StartupViewController.m
//  BananaATVBrowser
//
//  Created by 花心胡萝卜 on 9/7/22.
//  Copyright © 2022 High Caffeine Content. All rights reserved.
//

#import "StartupViewController.h"
#import "SVProgressHUD.h"

@interface StartupViewController ()

@end

@implementation StartupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
   
    [self->_subView setUserInteractionEnabled:YES];
    // Swift写法
    // scrollView.panGestureRecognizer.allowedTouchTypes = [NSNumber(value:UITouchType.indirect.rawValue)]
    // 下面2个写法都对
    //self.subView.panGestureRecognizer.allowedTouchTypes = @[ @(UITouchTypeIndirect) ];
    self.subView.panGestureRecognizer.allowedTouchTypes = @[ [NSNumber numberWithInt:UITouchTypeIndirect] ];
    self.subViewDisplay.backgroundColor = UIColor.lightGrayColor;
    //    self.subView.setNeedsFocusUpdate();
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)search:(UIButton *)btnSearch{
    //if ([_phoneNumber.text isEqual:@"123"]&&[_password.text isEqual:@"456"]) {
    //    NSLog(@"登录成功！");
    //}
    NSString *val = _txtSearch.text;
    NSLog(@"Input Value is %@", val);
    //    [self showToast: val];    // Test OK
    //    [self showToastTwoBtn: val];  // Test OK
    
    if ([_txtSearch.text isEqual:@"!banana"]) {
        // TODO: 保存配置 下次直接进入Browser页面
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"unlockerBrowser"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self showToastAndExit: NSLocalizedString(@"Enabled Browser!\nApplication will exit!", nil) title: NSLocalizedString(@"Info", nil)];
            
        // 不知道为什么不能跳转过去 只能退出
        //[self showBrowser];
    } else {
        if ([self isBlankString:val]) {
            [self showToast: NSLocalizedString(@"Please Input the AppID!", nil) title: NSLocalizedString(@"Info", nil)];
            return;
        }
        for (UIView *v in self.subViewDisplay.subviews) {
            if ([v isKindOfClass:[UILabel class]]) {
                [v removeFromSuperview];
            }
        }
        
        // 密码不正确, 改个别的功能
        [ SVProgressHUD showWithStatus : NSLocalizedString(@" Loading ...", nil) ];
        
        NSString *targetUrl = [[NSString alloc] initWithFormat: @"https://itunes.apple.com/rss/customerreviews/page=1/id=%@/sortby=mostrecent/json?l=en&&cc=cn", val];
        NSLog(@"TARGET is: %@", targetUrl);
        NSURL *url = [NSURL URLWithString:targetUrl];
        // 一下代码过时了
        //NSURLRequest *request = [ NSURLRequest requestWithURL :url];
        //NSOperationQueue *operatonQueue = [ NSOperationQueue mainQueue ];
        //[ NSURLConnection sendAsynchronousRequest :request queue :operatonQueue completionHandler :^( NSURLResponse *response, NSData *data, NSError *connectionError) {
        //    if (!connectionError) {
        //        [ SVProgressHUD dismiss ];
        //        NSDictionary *cateDict  = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        //        NSLog(cateDict);
        //        // 返回NSDictionay或者NSArray
        //    } else {
        //        [ SVProgressHUD showErrorWithStatus :[connectionError localizedDescription ]];
        //    }
        //}];
        
        // 使用新方法
        // MARK: 1.创建 NSURLSessionConfiguration 对象，进行 Session 会话配置
        // 默认会话配置
        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        // MARK: 2.配置默认会话的缓存行为
        // Caches 目录：NSCachesDirectory
        NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        // 在 Caches 目录下创建创建子目录
        NSString *cachePath = [cachesDirectory stringByAppendingPathComponent:@"MyCache"];
        /*
         Note:
         iOS 需要设置相对路径:〜/Library/Caches
         OS X 要设置绝对路径。
         */
        NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:16384
                                                          diskCapacity:268435456
                                                              diskPath:cachePath];
        defaultConfig.URLCache = cache;
        defaultConfig.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        
        // MARK: 3.创建 NSURLSession 对象
        NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];
        
        NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfig
                                                                     delegate:nil
                                                                delegateQueue:operationQueue];
        
        // MARK: 4.创建 NSURLSessionTask
        NSURLSessionTask *sessionTask = [defaultSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            // 响应对象是一个 NSHTTPURLResponse 对象实例
            // NSLog(@"Got response %@ with error %@.\n", response, error);
            // NSLog(@"默认会话返回数据:\n%@ \nEND DATA\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            // 返回NSDictionay或者NSArray
            if (!error) {
                [ SVProgressHUD dismiss ];
                NSString* jsonData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                // NSLog(@"DDDDDData: %@\n\n\n", jsonData);
                NSData *nsData = [jsonData dataUsingEncoding:NSUTF8StringEncoding];
                NSError *err;
                NSDictionary *cateDict  = [NSJSONSerialization JSONObjectWithData:nsData options:NSJSONReadingMutableContainers error:&err];
                // NSLog(@"############## %@", cateDict);
                // NSLog(@"&&&&&&&&&&&&&&& %@", [[[[[cateDict objectForKey:@"feed"] arrayForKey:@"entry"] objectAtIndex:0] objectForKey:@"content"] objectForKey:@"label"]);
                
                //NSLog(@"Start...");
                id dict = [cateDict objectForKey:@"feed"];
                //NSLog(@"get dict... %@", [dict class]);
                NSArray* entry = [dict valueForKey:@"entry"];
                //NSLog(@"get entry... %@ %lu", [entry class], entry.count);
                int x = 0, y = 0, /*width = 0, */height = 0;
                for (NSDictionary *obj in entry) {
                    NSString *nameLabel = @"", *ratingLabel = @"", *contentLabel = @"";
                    // 昵称
                    {
                        NSDictionary *author = [obj valueForKey:@"author"];
                        //NSLog(@"get author... %@ %@", [author class], author);
                        NSDictionary *name = [author valueForKey:@"name"];
                        nameLabel = [name objectForKey:@"label"];
                        //NSLog(@"Name: %@", nameLabel);
                    }
                    // 评分
                    {
                        NSDictionary *rating = [obj valueForKey:@"im:rating"];
                        //NSLog(@"get rating... %@ %@", [rating class], rating);
                        ratingLabel = [rating objectForKey:@"label"];
                        //NSLog(@"Rating: %@", ratingLabel);
                    }
                    // 评论
                    {
                        NSDictionary *content = [obj valueForKey:@"content"];
                        //NSLog(@"get content... %@ %@", [content class], content);
                        contentLabel = [content objectForKey:@"label"];
                        //NSLog(@"Content: %@",contentLabel);
                    }
                    
                    NSString* value = [[NSString alloc] initWithFormat:NSLocalizedString(@"%@ said:\n%@\n\nRate:%@\n----------------------------------------------", nil), nameLabel, contentLabel, ratingLabel];
                    
                    UILabel *bodyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
                    bodyLabel.textColor = [UIColor whiteColor];
                    bodyLabel.backgroundColor = [UIColor clearColor];
                    // tvOS不支持
                    // bodyLabel.textAlignment = UITextAlignmentLeft;
                    // bodyLabel.lineBreakMode = UILineBreakModeWordWrap;
                    bodyLabel.text = value;
                    //bodyLabel.font=[UIFont systemFontOfSize:16.0];
                    [bodyLabel setNumberOfLines:0];
                    // 这两个好像是一样的?
                    // bodyLabel.numberOfLines = 0;
                    //if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
                        NSAttributedString *att = [[NSAttributedString alloc] initWithString:bodyLabel.text attributes:@{NSFontAttributeName:bodyLabel.font}];
                        CGRect rect = [att boundingRectWithSize:CGSizeMake(self->_subView.frame.size.width, self->_subView.frame.size.height) options:NSStringDrawingUsesLineFragmentOrigin context:NULL];//获取aLabel内容大小
                        [bodyLabel setFrame:CGRectMake(x, y, rect.size.width, rect.size.height)]; //修改frame大小
                    //}else{
                    //    // 以下这句话tvOS不支持
                    //    CGSize size = [value sizeWithFont:[UIFont systemFontOfSize:18] constrainedToSize:CGSizeMake(320, 1000000)];//兼容7.0之前版本 调用方法
                    //    [bodyLabel setFrame:CGRectMake(0, 0, size.width, size.height)];
                    //}

                    [self->_subViewDisplay addSubview:bodyLabel];
                    
                    //if (rect.size.height > height)
                    //{
                    //    height = rect.size.height;
                    //}
                    //x += rect.size.width + 20;
                    //if ((x + 300) > self->_subView.frame.size.width) {
                    //    x = 0;
                    //    y += height + 20;
                    //}
                    
                    x = 0;
                    y += rect.size.height + 20;
                    
                    //NSLog(@"LabelSize: %@ x: %d y: %d w: %d h: %d, %@",
                    //      NSStringFromCGSize(rect.size),
                    //      x, y, width, height,
                    //      NSStringFromCGSize(self->_subView.frame.size));
                }
                
                height = y + 300;
                
                [self->_subViewDisplay setFrame:CGRectMake(0, 0, self->_subView.frame.size.width, height + 300)];
                [self->_subView setContentSize:CGSizeMake(self->_subView.frame.size.width, height + 300)];
                NSLog(@"ViewSize: %@ SS: %@ height: %d",
                      NSStringFromCGSize(self.subViewDisplay.frame.size),
                      NSStringFromCGSize(self.subView.contentSize),
                      height);
                [self->_subView updateFocusIfNeeded];
                
            } else {
                [ SVProgressHUD showErrorWithStatus :[error localizedDescription ]];
            }
        }];
        
        // MARK: 开启任务
        [sessionTask resume];
    }
}

- (void)showToast:(NSString *) msg  title:(NSString*)title{
    //初始化弹窗
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:nil]];
    //弹出提示框
    [self presentViewController:alert animated:true completion:nil];
}

- (void)showToastAndExit:(NSString *) msg title:(NSString*)title {
    //初始化弹窗
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        NSLog(@"点击了确定按钮!!!!!!!!!!!");
        exit(0);
    }]];
    //弹出提示框
    [self presentViewController:alert animated:true completion:nil];
}

- (void) showToastTwoBtn:(NSString *) msg {
    // 初始化对话框
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:msg preferredStyle:UIAlertControllerStyleAlert];
    // 确定按钮监听
    _okBtn = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        NSLog(@"点击了确定按钮");
    }];
    _cancelBtn =[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
        NSLog(@"点击了取消按钮");
    }];
    //添加按钮到弹出上
    [alert addAction:_okBtn];
    [alert addAction:_cancelBtn];
    // 弹出对话框
    [self presentViewController:alert animated:true completion:nil];
}

- (BOOL)isBlankString:(NSString *)val {
    if (!val) {
        return YES;
    }
    if ([val isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if (!val.length) {
        return YES;
    }
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmedStr = [val stringByTrimmingCharactersInSet:set];
    if (!trimmedStr.length) {
        return YES;
    }
    return NO;
}

- (void)showBrowser { 
    //获取storyboard: 通过bundle根据storyboard的名字来获取我们的storyboard,
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    //由storyboard根据myView的storyBoardID来获取我们要切换的视图
    UIViewController *browserView = [story instantiateViewControllerWithIdentifier:@"browserView"];
    //由navigationController推向我们要推向的view
    //[self.navigationController pushViewController:browserView animated:YES];
    [self.view.window setRootViewController:browserView];
}

@end
