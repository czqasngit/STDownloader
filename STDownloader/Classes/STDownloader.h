//
//  STDownloader.h
//  STDownloader.h
//
//  Created by legendry on 2018/1/8.
//  Copyright © 2018年 legendry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>


typedef void (^STDownloadSuccess)(NSURLRequest * _Nonnull request,NSString *_Nonnull downloadFilePath);
typedef void (^STDownloadFailure)(NSURLRequest * _Nonnull request,NSError * _Nullable error);
typedef void (^STDownloadProgress)(NSURLRequest *_Nonnull,NSUInteger receiveDataLength,NSUInteger totalDataLength,NSData *_Nonnull receiveData);
typedef void (^STDownloadComplete)(NSURLRequest * _Nonnull request,NSString * _Nonnull downloadFilePath);


@interface STDownloadReceipt : NSObject

@property (nonatomic,strong) NSURLSessionDataTask * _Nonnull task ;
@property (nonatomic,strong) NSUUID * _Nonnull receiptID;

@end

@interface STWriter : NSObject
@property (nonatomic,strong)NSOutputStream * _Nonnull stream ;
@property (nonatomic,strong,readonly)NSString * _Nonnull filePath ;
@end

@interface STDownloadResponseHandler : NSObject
@property (nonatomic,nonnull,strong)NSUUID *uuid;
@property (nonatomic,nullable,copy)STDownloadSuccess success;
@property (nonatomic,nullable,copy)STDownloadProgress progress;
@property (nonatomic,nullable,copy)STDownloadFailure failure;

@end



@interface STDownloaderTask : NSObject
@property (nonnull,nonatomic,strong)NSString *URLIdentifier ;
@property (nonnull,nonatomic,strong)NSURLSessionDataTask *task ;
@property (nonnull,nonatomic,strong)NSUUID *uuid;
@property (nonnull,nonatomic,strong)STWriter *writer ;
@property (nonatomic,nullable,copy)STDownloadComplete completeBlock;
@property (nonatomic,assign)NSUInteger total;
@property (nonatomic,assign)NSUInteger received;
@property (nonatomic,nonnull,strong)NSMutableArray<STDownloadResponseHandler *> *handlers;
- (void)addResponseHandler:(STDownloadResponseHandler *_Nonnull)handler;
- (void)removeAllHandlers;
@end

@interface STDownloader : NSObject

/*! max download size 1*/
+ (instancetype _Nonnull )defaultInstance ;
- (instancetype _Nonnull )initWithMaximumDownloadCount:(NSUInteger)maximumActiveDownloadCount downloadDirectory:(NSString * _Nonnull)downloadDirectory;
- (STDownloadReceipt * _Nullable)downloadFileForURLRequest:(NSURLRequest * _Nonnull)request
                                                      receiptID:(NSUUID * _Nonnull)receiptId
                                                        success:(STDownloadSuccess _Nullable)success
                                                       progress:(STDownloadProgress _Nullable)progress
                                                        failure:(STDownloadFailure _Nullable)failure ;
- (STDownloadReceipt * _Nullable)downloadFileForURLRequest:(NSURLRequest * _Nonnull)request
                                                     receiptID:(NSUUID * _Nonnull)receiptId
                                                       success:(STDownloadSuccess _Nullable)success
                                                      progress:(STDownloadProgress _Nullable)progress
                                                       failure:(STDownloadFailure _Nullable)failure
                                                      complete:(STDownloadComplete _Nullable)complete;
/*! cancel */
- (void)safelyCancelTaskWithReceipt:(STDownloadReceipt * _Nonnull)receipt ;
/*! suspend */
- (void)safelySuspendTask:(STDownloadReceipt * _Nonnull)receipt;
/*! resume */
- (void)safelyResumeTask:(STDownloadReceipt * _Nonnull)receipt;
/*! stop and clean */
- (void)safelyCleanTask;
/*! get current downloading tasks */
- (NSArray<STDownloaderTask *> *_Nullable)safelyDownloadingTasks;
/*! find task by receipt */
- (STDownloaderTask * _Nonnull )safelyFindDownloaderTaskWithReceipt:(NSUUID * _Nonnull )receipt;
@end
