//
//  JBModalInterfaceController.h
//  JBInterfaceController
//
//  Created by Michael Swanson on 4/2/15.
//  Copyright (c) 2015 Michael Swanson. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "JBInterfaceController.h"

@protocol JBModalInterfaceControllerDelegate;

@interface JBModalInterfaceController : JBInterfaceController

@property (nonatomic, readwrite, weak)      id<JBModalInterfaceControllerDelegate>  delegate;

@end

@protocol JBModalInterfaceControllerDelegate <NSObject>

@optional
- (void)modalInterfaceController:(JBModalInterfaceController *)controller didSelectOption:(NSString *)option;

@end