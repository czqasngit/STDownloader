# STDownloader

A light weight data download libiary.

[![CI Status](http://img.shields.io/travis/游小彬/STDownloader.svg?style=flat)](https://travis-ci.org/游小彬/STDownloader)
[![Version](https://img.shields.io/cocoapods/v/STDownloader.svg?style=flat)](http://cocoapods.org/pods/STDownloader)
[![License](https://img.shields.io/cocoapods/l/STDownloader.svg?style=flat)](http://cocoapods.org/pods/STDownloader)
[![Platform](https://img.shields.io/cocoapods/p/STDownloader.svg?style=flat)](http://cocoapods.org/pods/STDownloader)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Installation

STDownloader is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'STDownloader'
```

## Sample Code

```Objective-C
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
```
## Author

czqasn,czqasn_6@163.com

## License

STDownloader is available under the MIT license. See the LICENSE file for more info.
