//
//  STDownloader.m
//  STDownloader.h
//
//  Created by legendry on 2018/1/8.
//  Copyright © 2018年 legendry. All rights reserved.
//

#import "STDownloader.h"





@implementation STDownloadResponseHandler
- (instancetype)initWithUUID:(NSUUID *)uuid
                     success:(STDownloadSuccess)success
                       progress:(STDownloadProgress)progress
                        failure:(STDownloadFailure)failure
{
    self = [super init];
    if (self) {
        self.uuid = uuid ;
        self.success = success ;
        self.progress = progress ;
        self.failure = failure ;
    }
    return self;
}
@end


@implementation STDownloadReceipt
- (instancetype)initWithReceiptID:(NSUUID * _Nonnull)receiptID task:(NSURLSessionDataTask * _Nonnull)task
{
    self = [super init];
    if (self) {
        self.receiptID = receiptID ;
        self.task = task ;
    }
    return self;
}
@end



@implementation STWriter
{
    NSString *_filePath ;
}
- (instancetype)initWithDirectory:(NSString *)directory
{
    self = [super init];
    if (self) {
        _filePath = [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",[NSUUID UUID].UUIDString]] ;
        self.stream = [[NSOutputStream alloc] initToFileAtPath:_filePath append:NO] ;
        [self.stream open] ;
    }
    return self;
}
- (NSUInteger)writeData:(NSData *)data {
    if(data && data.length > 0) {
        return [self.stream write:data.bytes maxLength:data.length] ;
    }
    return 0 ;
}

- (void)close {
    [self.stream close] ;
}
- (NSString *)filePath {
    return _filePath ;
}
@end


@implementation STDownloaderTask
{
    NSString *_directoryDownload ;
}
- (instancetype)initWithURLIdentifier:(NSString *)URLIdentifier uuid:(NSUUID *)uuid task:(NSURLSessionDataTask *)task downloadDirectory:(NSString *)directoryDownload
{
    self = [super init];
    if (self) {
        self.URLIdentifier = URLIdentifier ;
        self.uuid = uuid ;
        self.task = task ;
        _directoryDownload = directoryDownload ;
        self.handlers = [[NSMutableArray<STDownloadResponseHandler *> alloc] init] ;
    }
    return self;
}
- (void)addResponseHandler:(STDownloadResponseHandler *)handler {
    [self.handlers addObject:handler] ;
}
- (void)removeAllHandlers {
    [self.handlers removeAllObjects] ;
}
- (void)receiveRequestSize:(NSUInteger)total {
    self.total = total ;
    self.writer = [[STWriter alloc] initWithDirectory:_directoryDownload] ;
}
- (void)received:(NSData *)data {
    if([self.writer writeData:data] > 0) {
        self.received += data.length ;
    }
    [self.handlers enumerateObjectsUsingBlock:^(STDownloadResponseHandler * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        !obj.progress ? : obj.progress(self.task.originalRequest,self.received,self.total,data);
    }] ;
}
- (void)success{
    [self.handlers enumerateObjectsUsingBlock:^(STDownloadResponseHandler * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        !obj.success ? : obj.success(self.task.originalRequest,self.writer.filePath);
    }] ;
}
- (void)failureWithError:(NSError *)error {
    [self.handlers enumerateObjectsUsingBlock:^(STDownloadResponseHandler * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        !obj.failure ? : obj.failure(self.task.originalRequest,error);
    }];
    [self.writer close] ;
}

- (void)complete {
    !self.completeBlock ? : self.completeBlock(self.task.originalRequest,self.writer.filePath);
    [self.writer close] ;
}
@end

@interface STDownloader()<NSURLSessionDelegate,NSURLSessionDataDelegate>
@property (nonatomic,nonnull,strong)NSURLSession *session;
@property (nonatomic,nonnull,strong)dispatch_queue_t syncharonizationQueue ;
@property (nonatomic,nonnull,strong)NSMutableDictionary *tasksRelationship ;
@property (nonatomic,nonnull,strong)NSMutableArray<STDownloaderTask *> *tasks;
@property (nonatomic,assign)NSUInteger maximumActiveDownloadCount;
@property (nonatomic,assign)NSUInteger activeRequestDownloadCount;

@end


@implementation STDownloader
{
    NSString *_directoryDownload ;
}
+ (instancetype)defaultInstance {
    static STDownloader *sharedInstance = nil ;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[STDownloader alloc] init] ;
    });
    return sharedInstance ;
}

- (instancetype)init {
    NSString *defaultDownloadDirectory = nil ;
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] ;
    NSString *defaultDownloadDirName = @"com.st.download";
    defaultDownloadDirectory = [cacheDir stringByAppendingPathComponent:defaultDownloadDirName] ;
    return [self initWithMaximumDownloadCount:1 downloadDirectory:defaultDownloadDirectory] ;
}

- (instancetype)initWithMaximumDownloadCount:(NSUInteger)maximumActiveDownloadCount downloadDirectory:(NSString * _Nonnull)downloadDirectory
{
    self = [super init];
    if (self) {
        NSAssert(downloadDirectory, @"downloadDirectory can't be nil") ;
        _directoryDownload = downloadDirectory ;
        NSFileManager *fileManager = [NSFileManager defaultManager] ;
        if(![fileManager fileExistsAtPath:_directoryDownload]) {
            [fileManager createDirectoryAtPath:_directoryDownload withIntermediateDirectories:YES attributes:NULL error:NULL] ;
        }
        self.maximumActiveDownloadCount = maximumActiveDownloadCount ;
        NSString *queueName = [NSString stringWithFormat:@"st.downloader.queue-%@",[NSUUID UUID]] ;
        self.syncharonizationQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL) ;
        [self setup] ;
    }
    return self;
}

- (void)setup {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration] ;
    sessionConfiguration.timeoutIntervalForRequest = 30.0f;
    sessionConfiguration.URLCache = nil ;
    self.session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[[NSOperationQueue alloc] init]] ;
    self.tasks = [[NSMutableArray<STDownloaderTask *> alloc] init] ;
    self.tasksRelationship = [[NSMutableDictionary alloc] init] ;
}

- (STDownloadReceipt * _Nullable)downloadFileForURLRequest:(NSURLRequest * _Nonnull)request
                                                     receiptID:(NSUUID * _Nonnull)receiptId
                                                       success:(STDownloadSuccess _Nullable)success
                                                      progress:(STDownloadProgress _Nullable)progress
                                                       failure:(STDownloadFailure _Nullable)failure {
    return [self downloadFileForURLRequest:request receiptID:receiptId success:success progress:progress failure:failure complete:nil] ;
}
- (STDownloadReceipt * _Nullable)downloadFileForURLRequest:(NSURLRequest * _Nonnull)request
                                                      receiptID:(NSUUID * _Nonnull)receiptId
                                                        success:(STDownloadSuccess _Nullable)success
                                                       progress:(STDownloadProgress _Nullable)progress
                                                        failure:(STDownloadFailure _Nullable)failure complete:(STDownloadComplete _Nullable)complete{

    __block NSURLSessionDataTask *task = nil ;
    dispatch_sync(self.syncharonizationQueue, ^{
        NSString *URLIdentifier = request.URL.absoluteString ;
        if(!URLIdentifier) {
            //请求无效
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil] ;
            !failure ?: failure(request,error) ;
            return ;
        }
        
        
        STDownloadResponseHandler *handler = [[STDownloadResponseHandler alloc] initWithUUID:receiptId
                                                                                             success:success
                                                                                            progress:progress
                                                                                             failure:failure] ;
        STDownloaderTask *existingTask = self.tasksRelationship[URLIdentifier] ;
       
        if(existingTask) {
            
            [existingTask addResponseHandler:handler] ;
            task = existingTask.task ;
            NSLog(@"任务已经存在") ;
            return ;
        }
        NSURLSessionDataTask *newTask = [self.session dataTaskWithURL:request.URL] ;
        
        
        STDownloaderTask *downloadTask = [[STDownloaderTask alloc] initWithURLIdentifier:URLIdentifier uuid:receiptId task:newTask downloadDirectory:_directoryDownload] ;
        downloadTask.completeBlock = complete ;
        [downloadTask addResponseHandler:handler] ;
        self.tasksRelationship[URLIdentifier] = downloadTask ;
        task = newTask ;
       
        if([self isActiveRequestBelowMaximum]) {
            [self startTask:downloadTask] ;
        } else {
            [self enqueueTask:downloadTask] ;
        }
    });
    if(task) {
        return [[STDownloadReceipt alloc] initWithReceiptID:receiptId task:task] ;
    }
    return nil ;
}

#pragma mark -
- (void)enqueueTask:(STDownloaderTask *)task {
    if(!task) return ;
    [self.tasks addObject:task] ;
}
- (STDownloaderTask *)dequeueTask {
    STDownloaderTask *task = nil ;
    if(self.tasks.count > 0) {
        task = self.tasks.firstObject ;
        [self.tasks removeObject:task] ;
    }
    return task ;
}
- (BOOL)isActiveRequestBelowMaximum {
    return self.activeRequestDownloadCount < self.maximumActiveDownloadCount ;
}
- (void)startTask:(STDownloaderTask *)task {
    [task.task resume] ;
    self.activeRequestDownloadCount ++ ;
}
- (void)safelyStartNextTaskIfNecessary {
    dispatch_async(self.syncharonizationQueue, ^{
        if([self isActiveRequestBelowMaximum]) {
            STDownloaderTask *task = [self dequeueTask] ;
            if(task) {
                [self startTask:task] ;
            }
        }
    });
}
- (void)safelyDecrementActiveTaskCount {
    dispatch_async(self.syncharonizationQueue, ^{
        if(self.activeRequestDownloadCount > 0) {
            self.activeRequestDownloadCount -- ;
        }
    });
}

- (void)safelyRemoveTaskWithURLIdentifier:(NSString *)URLIdentifier {
    dispatch_async(self.syncharonizationQueue, ^{
        [self.tasksRelationship removeObjectForKey:URLIdentifier] ;
    });
}

#pragma mark -

- (void)resetSession {
    [self.tasks removeAllObjects] ;
    [self.tasksRelationship removeAllObjects] ;
    [self setup] ;
}

#pragma mark -


- (void)safelyCancelTaskWithReceipt:(STDownloadReceipt *)receipt {
    dispatch_async(self.syncharonizationQueue, ^{
        NSString *URLIdentifier = receipt.task.originalRequest.URL.absoluteString ;
        STDownloaderTask *task = self.tasksRelationship[URLIdentifier] ;
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil] ;
        [task failureWithError:error] ;
        [task.task cancel] ;
        [self safelyRemoveTaskWithURLIdentifier:URLIdentifier] ;
        
    });
}


- (void)safelySuspendTask:(STDownloadReceipt *)receipt {
    dispatch_async(self.syncharonizationQueue, ^{
        NSString *URLIdentifier = receipt.task.originalRequest.URL.absoluteString ;
        if(!URLIdentifier) return ;
        STDownloaderTask *task = self.tasksRelationship[URLIdentifier] ;
        if(!task) return ;
        [task.task suspend] ;
    });
}

- (void)safelyResumeTask:(STDownloadReceipt *)receipt {
    dispatch_async(self.syncharonizationQueue, ^{
        NSString *URLIdentifier = receipt.task.originalRequest.URL.absoluteString ;
        if(!URLIdentifier) return ;
        STDownloaderTask *task = self.tasksRelationship[URLIdentifier] ;
        if(!task) return ;
        if(task.task.state == NSURLSessionTaskStateSuspended) {
            [task.task resume] ;            
        }
    });
}

- (void)safelyCleanTask {
    dispatch_async(self.syncharonizationQueue, ^{
        [self.session invalidateAndCancel] ;
        [self.session finishTasksAndInvalidate] ;
        [self.tasks enumerateObjectsUsingBlock:^(STDownloaderTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil] ;
            [obj failureWithError:error] ;
        }] ;
        [self resetSession] ;
    });
}

- (NSArray<STDownloaderTask *> *)safelyDownloadingTasks {
    NSMutableArray<STDownloaderTask *> *tmps = [[NSMutableArray<STDownloaderTask*> alloc] init] ;
    dispatch_sync(self.syncharonizationQueue, ^{
        [self.tasksRelationship enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, STDownloaderTask *  _Nonnull obj, BOOL * _Nonnull stop) {
            [tmps addObject:obj] ;
        }];
    });
    return tmps ;
}

- (STDownloaderTask *)safelyFindDownloaderTaskWithReceipt:(NSUUID *)receipt {
    __block STDownloaderTask *task = nil ;
    dispatch_sync(self.syncharonizationQueue, ^{
        NSUInteger index = [self.tasks indexOfObjectPassingTest:^BOOL(STDownloaderTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.uuid.UUIDString isEqualToString:receipt.UUIDString] ;
        }];
        if(index != NSNotFound) {
            task = self.tasks[index] ;
        }
    });
    return task ;
}



#pragma mark -
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    dispatch_async(self.syncharonizationQueue, ^{
        NSString *URLIdentifier = dataTask.originalRequest.URL.absoluteString ;
        STDownloaderTask *task = self.tasksRelationship[URLIdentifier] ;
        [task received:data] ;
    });
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    dispatch_async(self.syncharonizationQueue, ^{
        NSString *URLIdentifier = dataTask.originalRequest.URL.absoluteString ;
        STDownloaderTask *task = self.tasksRelationship[URLIdentifier] ;
        [task receiveRequestSize:response.expectedContentLength] ;
    });
    completionHandler(NSURLSessionResponseAllow) ;
    
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDataTask *)dataTask didCompleteWithError:(NSError *)error
{
    NSString *URLIdentifier = dataTask.originalRequest.URL.absoluteString ;
    STDownloaderTask *task = self.tasksRelationship[URLIdentifier] ;
    dispatch_async(self.syncharonizationQueue, ^{
        if(!task) return ;
        if(error) {
            [task failureWithError:error] ;
        } else {
            [task success] ;
        }
    });
    [self safelyDecrementActiveTaskCount] ;
    [self safelyRemoveTaskWithURLIdentifier:URLIdentifier] ;
    dispatch_async(self.syncharonizationQueue, ^{
        if(!task) return ;
        [task complete] ;
    });
    [self safelyStartNextTaskIfNecessary] ;
}
@end
