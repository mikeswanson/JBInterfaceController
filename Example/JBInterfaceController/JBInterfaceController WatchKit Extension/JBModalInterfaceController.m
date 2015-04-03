//
//  JBModalInterfaceController.m
//  JBInterfaceController
//
//  Created by Michael Swanson on 4/2/15.
//  Copyright (c) 2015 Michael Swanson. All rights reserved.
//

#import "JBModalInterfaceController.h"
#import "JBInterfaceController_Protected.h"

@interface JBModalInterfaceController()

@property (nonatomic, readwrite, weak)      IBOutlet    WKInterfaceLabel    *label;
@property (nonatomic, readwrite, copy)                  NSString            *message;
@property (nonatomic, readwrite, weak)      IBOutlet    WKInterfaceGroup    *replacementStatusBarGroup;
@property (nonatomic, readwrite, assign)                BOOL                fixMenu;

@end

@implementation JBModalInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Configure interface objects here.
    
    // Make sure we unwrap our context
    self.message = [self unwrappedContext:context];
    
    [self addMenuItemWithItemIcon:WKMenuItemIconAdd
                            title:@"Add"
                           action:@selector(didSelectAdd)];

    [self addMenuItemWithItemIcon:WKMenuItemIconTrash
                            title:@"Delete"
                           action:@selector(didSelectDelete)];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    [self.label setText:self.message];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)doClose {
    
    [self dismissController];
}

- (void)didSelectAdd {
    
    [self didSelectOption:@"Add"];
}

- (void)didSelectDelete {
    
    [self didSelectOption:@"Delete"];
}

- (void)didSelectOption:(NSString *)option {
    
    // Inform delegate
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(modalInterfaceController:didSelectOption:)]) {
        
        [self.delegate modalInterfaceController:self didSelectOption:option];
    }
}

- (void)fixMenuBug {
    
    [super fixMenuBug];
    
    self.fixMenu = YES;
    [self.interface setNeedsUpdate];
}

- (void)didUpdateInterface {
    
    [super didUpdateInterface];
    
    if (self.fixMenu) {
        
        [self.replacementStatusBarGroup setHidden:NO];
        self.fixMenu = NO;
    }
}


@end



