//
//  UIViewController+PDFViewController.h
//  BananaATVBrowser
//
//  Created by 花心胡萝卜 on 9/9/22.
//  Copyright © 2022 High Caffeine Content. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDFViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIScrollView* scrollView;



// MARK: PDF相关功能
- (CGPDFDocumentRef)openPDFLocal:(NSString *)pdfURL;

- (CGPDFDocumentRef)openPDFURL:(NSString *)pdfURL;

- (CGPDFDocumentRef)openPDF:(NSURL *)NSUrl;

- (void)drawDocument:(CGPDFDocumentRef)pdfDocument;

- (void)addImagesToScrollView:(NSMutableArray *)imageArray;

- (void)downloadFile:(NSString *) dwUrl;

- (void)showToast:(NSString *) msg  title:(NSString*)title;


@end

NS_ASSUME_NONNULL_END
