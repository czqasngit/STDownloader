//
//  STViewController.m
//  STDownloader
//
//  Created by 游小彬 on 03/29/2018.
//  Copyright (c) 2018 游小彬. All rights reserved.
//

#import "STViewController.h"
#import <STDownloader/STDownloader.h>

@interface STViewController ()

@end

@implementation STViewController
{
    STDownloadReceipt *downloadReceipt  ;
    STDownloader *downloader ;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (IBAction)simple:(id)sender {
    NSString *downloadUrlString = @"https://dldir1.qq.com/qqfile/qq/TIM2.1.5/23141/TIM2.1.5.exe" ;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrlString]] ;
    NSUUID *receiptID = [NSUUID UUID] ;
    STDownloadSuccess success = ^(NSURLRequest *request,NSString *downloadFilePath) {
        NSLog(@"Download Success:%@",downloadFilePath) ;
        
    } ;
    STDownloadProgress progress = ^(NSURLRequest *request,NSUInteger receiveDataLength,NSUInteger totalDataLength,NSData *receiveData) {
        NSLog(@"Download Progress:%.2f",receiveDataLength * 1.0f / totalDataLength) ;
    };
    STDownloadFailure failure = ^(NSURLRequest *request,NSError *error) {
        NSLog(@"Download Failure:%@",error) ;
    } ;
    [[STDownloader defaultInstance] downloadFileForURLRequest:request receiptID:receiptID success:success progress:progress failure:failure] ;
}

- (IBAction)multi:(id)sender {
    NSString *defaultDownloadDirectory = nil ;
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] ;
    NSString *defaultDownloadDirName = @"com.st.download";
    defaultDownloadDirectory = [cacheDir stringByAppendingPathComponent:defaultDownloadDirName] ;
    
    STDownloader *downloader = [[STDownloader alloc] initWithMaximumDownloadCount:3 downloadDirectory:defaultDownloadDirectory] ;
    
    NSArray<NSString *> *urlStringArr = @[@"https://dldir1.qq.com/qqfile/qq/TIM2.1.5/23141/TIM2.1.5.exe",
                                         @"http://118.112.22.159/sqdd.myapp.com/myapp/qqteam/tim/down/tim.apk?mkey=5abc702f14de7f2f&f=2d80&c=0&p=.apk",
                                         @"https://dldir1.qq.com/music/clntupate/mac/QQMusicMac_Mgr.dmg"] ;
    for(NSString *downloadUrlString in urlStringArr) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrlString]] ;
        NSUUID *receiptID = [NSUUID UUID] ;
        STDownloadSuccess success = ^(NSURLRequest *request,NSString *downloadFilePath) {
            NSLog(@"[%@]Download Success:%@",receiptID,downloadFilePath) ;
            
        } ;
        STDownloadProgress progress = ^(NSURLRequest *request,NSUInteger receiveDataLength,NSUInteger totalDataLength,NSData *receiveData) {
            NSLog(@"[%@]Download Progress:%.2f",receiptID,receiveDataLength * 1.0f / totalDataLength) ;
        };
        STDownloadFailure failure = ^(NSURLRequest *request,NSError *error) {
            NSLog(@"[%@]Download Failure:%@",receiptID,error) ;
        } ;
        [downloader downloadFileForURLRequest:request receiptID:receiptID success:success progress:progress failure:failure] ;
    }
    
}

- (IBAction)cancel:(id)sender {
    
    
    [downloader safelyCancelTaskWithReceipt:downloadReceipt] ;
    
}

- (IBAction)startDownload:(id)sender {
    
    NSString *defaultDownloadDirectory = nil ;
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] ;
    NSString *defaultDownloadDirName = @"com.st.download";
    defaultDownloadDirectory = [cacheDir stringByAppendingPathComponent:defaultDownloadDirName] ;
    
    downloader = [[STDownloader alloc] initWithMaximumDownloadCount:2 downloadDirectory:defaultDownloadDirectory] ;
    
    NSArray<NSString *> *urlStringArr = @[@"https://dldir1.qq.com/qqfile/qq/TIM2.1.5/23141/TIM2.1.5.exe",
                                          @"http://118.112.22.159/sqdd.myapp.com/myapp/qqteam/tim/down/tim.apk?mkey=5abc702f14de7f2f&f=2d80&c=0&p=.apk",
                                          @"https://dldir1.qq.com/music/clntupate/mac/QQMusicMac_Mgr.dmg"] ;
    
    for(NSString *downloadUrlString in urlStringArr) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrlString]] ;
        NSUUID *receiptID = [NSUUID UUID] ;
        STDownloadSuccess success = ^(NSURLRequest *request,NSString *downloadFilePath) {
            NSLog(@"[%@]Download Success:%@",receiptID,downloadFilePath) ;
            
        } ;
        STDownloadProgress progress = ^(NSURLRequest *request,NSUInteger receiveDataLength,NSUInteger totalDataLength,NSData *receiveData) {
            NSLog(@"[%@]Download Progress:%.2f",receiptID,receiveDataLength * 1.0f / totalDataLength) ;
        };
        STDownloadFailure failure = ^(NSURLRequest *request,NSError *error) {
            NSLog(@"[%@]Download Failure:%@",receiptID,error) ;
        } ;
        STDownloadReceipt *__downloadReceipt = [downloader downloadFileForURLRequest:request receiptID:receiptID success:success progress:progress failure:failure] ;
        if(!downloadReceipt) {
            downloadReceipt = __downloadReceipt ;
        }
    }
}

- (IBAction)suspend:(id)sender {
    [downloader safelySuspendTask:downloadReceipt];
}

- (IBAction)resume:(id)sender {
    [downloader safelyResumeTask:downloadReceipt] ;
}

- (IBAction)StopAllTask:(id)sender {
    [downloader safelyCleanTask] ;
}

- (IBAction)currentDownloads:(id)sender {
    NSArray * tmps = [downloader safelyDownloadingTasks] ;
    NSLog(@"---%@",tmps) ;
}

@end
