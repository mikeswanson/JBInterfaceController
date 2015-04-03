//
//  InterfaceController.m
//  JBInterfaceController WatchKit Extension
//
//  Created by Michael Swanson on 4/2/15.
//  Copyright (c) 2015 Michael Swanson. All rights reserved.
//

#import "InterfaceController.h"
#import "JBModalInterfaceController.h"

@interface InterfaceController() <JBModalInterfaceControllerDelegate>

@property (nonatomic, readwrite, weak)      IBOutlet    WKInterfaceButton   *modalButton;
@property (nonatomic, readwrite, copy)                  NSString            *selectedOption;

@end

@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)doPresentModal {

    JBInterfaceControllerConfigureBlock configureBlock = ^(JBInterfaceController *controller) {
        
        // Configure the presented controller
        ((JBModalInterfaceController *)controller).delegate = self;
    };
    
    NSArray *configurators = @[
                               [JBInterfaceControllerConfigurator
                                configuratorWithName:@"modal"
                                context:@"Force Touch, then cancel to see the replacement status bar appear"
                                configureBlock:configureBlock
                                dismissBlock:^(JBInterfaceController *controller) {
                                    
                                    NSLog(@"First controller was dismissed");
                                }],
                               [JBInterfaceControllerConfigurator
                                configuratorWithName:@"modal"
                                context:@"Notice how the replacement status bar appears here too"
                                configureBlock:configureBlock
                                dismissBlock:^(JBInterfaceController *controller) {
                                    
                                    NSLog(@"Second controller was dismissed");
                                }]
                               ];
    
    [self presentControllersWithConfigurators:configurators];
}

- (void)didUpdateInterface {
    
    if (self.selectedOption) {
        
        [self.modalButton setTitle:self.selectedOption];
    }
}

#pragma mark - JBModalInterfaceControllerDelegate

- (void)modalInterfaceController:(JBModalInterfaceController *)controller
                 didSelectOption:(NSString *)option {
    
    NSLog(@"Selection option: %@", option);
    
    self.selectedOption = option;
    [self.interface setNeedsUpdate];
}

@end



