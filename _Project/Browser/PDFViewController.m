//
//  UIViewController+PDFViewController.m
//  BananaATVBrowser
//
//  Created by 花心胡萝卜 on 9/9/22.
//  Copyright © 2022 High Caffeine Content. All rights reserved.
//

#import "PDFViewController.h"
#import "SVProgressHUD.h"

@interface PDFViewController()

@end


@implementation PDFViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //    _pdfUrl = ;
    NSString *pdfUrl = [[NSUserDefaults standardUserDefaults] objectForKey: @"pdfUrl"];
    __block int sleepTime = 1;
    __block BOOL downloadFinished = NO;

    //    if ([pdfUrl isEqual: @"http://111"])
    //        pdfUrl = @"https://www.ndrc.gov.cn/fggz/gdzctz/tzfg/201411/W020191104862163498574.pdf";
    if ([pdfUrl containsString: @"https://"]) {
        //[self downloadFile:pdfUrl];
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_async(group, queue, ^ {
            NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            NSString *savePath = [cachePath stringByAppendingPathComponent: @"pdf.pdf"];

            if ([[NSFileManager defaultManager] fileExistsAtPath: savePath]) {
                [[NSFileManager defaultManager] removeItemAtPath: savePath error: nil];
            }

            //1.创建url
            NSString *urlStr = pdfUrl;

            //urlStr =[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSURL *url = [NSURL URLWithString: urlStr];
            //2.创建请求
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];

            //3.创建会话（这里使用了一个全局会话）并且启动任务
            NSURLSession *session = [NSURLSession sharedSession];

            [ SVProgressHUD showWithStatus: NSLocalizedString(@" Loading ...", nil) ];
            NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest: request completionHandler: ^ (NSURL * location, NSURLResponse * response, NSError * error) {
                        if (!error) {
                            //注意location是下载后的临时保存路径,需要将它移动到需要保存的位置
                            NSError *saveError;
                    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
                    NSString *savePath = [cachePath stringByAppendingPathComponent: @"pdf.pdf"];
                    NSLog(@"%@", savePath);
                    NSURL *saveUrl = [NSURL fileURLWithPath: savePath];
                    [[NSFileManager defaultManager] copyItemAtURL: location toURL: saveUrl error: &saveError];

                    if (!saveError) {
                        NSLog(@"save sucess.");
                        downloadFinished = YES;
                        [ SVProgressHUD dismiss ];
                    } else {
                        [ SVProgressHUD showErrorWithStatus: [error localizedDescription ]];
                        NSLog(@"error is :%@", saveError.localizedDescription);
                    }
                } else {
                    [ SVProgressHUD showErrorWithStatus: [error localizedDescription ]];
                    NSLog(@"error is :%@", error.localizedDescription);
                }
            }];

            [downloadTask resume];
        });
        dispatch_group_async(group, queue, ^ {
            NSLog(@"Task SLEEP ==== >>: %@", [NSThread currentThread]);

            while (!downloadFinished || sleepTime-- > 0) {
                [NSThread sleepForTimeInterval: 1.0f];
            }
            NSLog(@"Task SLEEP FINISHED ==== >>: %@", [NSThread currentThread]);
        });
        dispatch_group_async(group, queue, ^ {
            NSLog(@"Task 2 ==== >>: %@", [NSThread currentThread]);
        });
        dispatch_group_async(group, queue, ^ {
            NSLog(@"Task 3 ==== >>: %@", [NSThread currentThread]);
        });
        dispatch_group_notify(group, queue, ^ {
            NSLog(@"Task NOTIFY ==== >>: %@", [NSThread currentThread]);
            dispatch_async(dispatch_get_main_queue(), ^{
                //回调或者说是通知主线程刷新，
                NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
                NSString *savePath = [cachePath stringByAppendingPathComponent: @"pdf.pdf"];
                CGPDFDocumentRef pdfDocument = [self openPDFLocal: savePath];
                [self drawDocument: pdfDocument];

            });
        });
        //        dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //            // 处理耗时操作的代码块...
        //            UIImage *img = [self getImgeWith:[urlArr objectForIndex:i]];
        //            //通知主线程刷新
        //            dispatch_async(dispatch_get_main_queue(), ^{
        //                //回调或者说是通知主线程刷新，
        //                [myImgV[i] setImage:img];
        //            });
    } else {
        CGPDFDocumentRef pdfDocument = [self openPDFURL: pdfUrl];
        [self drawDocument: pdfDocument];
    }
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// MARK: PDF相关功能
- (CGPDFDocumentRef) openPDFLocal: (NSString *) pdfURL {
    NSURL *NSUrl = [NSURL fileURLWithPath: pdfURL];
    NSLog(@"LocalURL is %@", NSUrl);
    return [self openPDF: NSUrl];
}

- (CGPDFDocumentRef) openPDFURL: (NSString *) pdfURL {
    NSURL *NSUrl = [NSURL URLWithString: pdfURL];
    return [self openPDF: NSUrl];
}

- (CGPDFDocumentRef) openPDF: (NSURL *) NSUrl {
    CFURLRef url = (CFURLRef)CFBridgingRetain(NSUrl);
    CGPDFDocumentRef myDocument;
    myDocument = CGPDFDocumentCreateWithURL(url);

    if (myDocument == NULL) {
        NSLog(@"can't open %@", NSUrl);
        [self showToast: NSLocalizedString(@"Open PDF Fail!", nil) title: NSLocalizedString(@"Info", nil)];
        CFRelease(url);
        return nil;
    }

    CFRelease(url);

    if (CGPDFDocumentGetNumberOfPages(myDocument) == 0) {
        CGPDFDocumentRelease(myDocument);
        return nil;
    }

    return myDocument;
}
- (void) drawDocument: (CGPDFDocumentRef) pdfDocument {
    // Get the total number of pages for the whole PDF document
    int  totalPages = (int)CGPDFDocumentGetNumberOfPages(pdfDocument);
    NSMutableArray *pageImages = [[NSMutableArray alloc] init];

    // Iterate through the pages and add each page image to an array
    for (int i = 1; i <= totalPages; i++) {
        // Get the first page of the PDF document
        CGPDFPageRef page = CGPDFDocumentGetPage(pdfDocument, i);
        CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
        // Begin the image context with the page size
        // Also get the grapgics context that we will draw to
        UIGraphicsBeginImageContext(pageRect.size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        // Rotate the page, so it displays correctly
        CGContextTranslateCTM(context, 0.0, pageRect.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextConcatCTM(context, CGPDFPageGetDrawingTransform(page, kCGPDFMediaBox, pageRect, 0, true));
        // Draw to the graphics context
        CGContextDrawPDFPage(context, page);
        // Get an image of the graphics context
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [pageImages addObject: image];
    }

    // Set the image of the PDF to the current view
    [self addImagesToScrollView: pageImages];
}

- (void) addImagesToScrollView: (NSMutableArray *) imageArray {
    int heigth = 0;

    for (UIImage * image in imageArray) {
        UIImageView *imgView = [[UIImageView alloc] initWithImage: image];
        imgView.frame = CGRectMake(0, heigth, imgView.frame.size.width, imgView.frame.size.height);
        [_scrollView addSubview: imgView];
        heigth += imgView.frame.size.height;
    }
}

- (void) downloadFile: (NSString *) dwUrl {
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *savePath = [cachePath stringByAppendingPathComponent: @"pdf.pdf"];

    if ([[NSFileManager defaultManager] fileExistsAtPath: savePath]) {
        [[NSFileManager defaultManager] removeItemAtPath: savePath error: nil];
    }

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *savePath = [cachePath stringByAppendingPathComponent: @"pdf.pdf"];
        CGPDFDocumentRef pdfDocument = [self openPDFLocal: savePath];
        [self drawDocument: pdfDocument];
    });
    //1.创建url
    NSString *urlStr = dwUrl;
    //urlStr =[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString: urlStr];
    //2.创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
    //3.创建会话（这里使用了一个全局会话）并且启动任务
    NSURLSession *session = [NSURLSession sharedSession];
    [ SVProgressHUD showWithStatus: NSLocalizedString(@" Loading ...", nil) ];
    dispatch_group_enter(group);
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest: request completionHandler: ^ (NSURL * location, NSURLResponse * response, NSError * error) {
                if (!error) {
                    //注意location是下载后的临时保存路径,需要将它移动到需要保存的位置
                    NSError *saveError;
            NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            NSString *savePath = [cachePath stringByAppendingPathComponent: @"pdf.pdf"];
            NSLog(@"%@", savePath);
            NSURL *saveUrl = [NSURL fileURLWithPath: savePath];
            [[NSFileManager defaultManager] copyItemAtURL: location toURL: saveUrl error: &saveError];

            if (!saveError) {
                NSLog(@"save sucess.");
                [ SVProgressHUD dismiss ];
                [NSThread sleepForTimeInterval: 1.0f];
                dispatch_group_leave(group);
            } else {
                dispatch_group_leave(group);
                [ SVProgressHUD showErrorWithStatus: [error localizedDescription ]];
                NSLog(@"error is :%@", saveError.localizedDescription);
            }
        } else {
            dispatch_group_leave(group);
            [ SVProgressHUD showErrorWithStatus: [error localizedDescription ]];
            NSLog(@"error is :%@", error.localizedDescription);
        }
    }];
    [downloadTask resume];
}

- (void) showToast: (NSString *) msg  title: (NSString *) title {
    //初始化弹窗
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: title message: msg preferredStyle: UIAlertControllerStyleAlert];
    [alert addAction: [UIAlertAction actionWithTitle: NSLocalizedString(@"OK", nil) style: UIAlertActionStyleDefault handler: nil]];
    //弹出提示框
    [self presentViewController: alert animated: true completion: nil];
}

@end
