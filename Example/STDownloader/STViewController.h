//
//  STViewController.h
//  STDownloader
//
//  Created by 游小彬 on 03/29/2018.
//  Copyright (c) 2018 游小彬. All rights reserved.
//

@import UIKit;

@interface STViewController : UIViewController
- (IBAction)simple:(id)sender;
- (IBAction)multi:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)startDownload:(id)sender;
- (IBAction)suspend:(id)sender;
- (IBAction)resume:(id)sender;
- (IBAction)StopAllTask:(id)sender;
- (IBAction)currentDownloads:(id)sender;

@end
