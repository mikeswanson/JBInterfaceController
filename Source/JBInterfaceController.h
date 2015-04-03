//
//  JBInterfaceController.h
//
//  Created by Mike Swanson on 2/9/2015
//  Copyright (c) 2015 Mike Swanson. All rights reserved.
//  http://blog.mikeswanson.com
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "JBInterface.h"

@class JBInterfaceControllerConfigurator;

/**
 *  @class  JBInterfaceController
 *
 *  @brief  The @p JBInterfaceController class is a subclass of @p WKInterfaceController 
 *          that makes it easier to manage your Watch app’s interface.
 */
@interface JBInterfaceController : WKInterfaceController

/**
 *  @brief  The interface controller that presented this interface controller - if known. (read-only)
 */
@property (nonatomic, readonly, weak)       JBInterfaceController   *presentingController;

/**
 *  @brief  The interface controllers that have been presented by this interface controller. (read-only)
 */
@property (nonatomic, readonly, strong)     NSPointerArray          *presentedControllers;

/**
 *  @brief  The interface stored in this property represents the root interface for the interface
 *          controller's interface hierarchy. (read-only)
 */
@property (nonatomic, readonly, strong)     JBInterface             *interface;

/**
 *  @brief  A Boolean value that represents whether the interface is currently visible. (read-only)
 */
@property (nonatomic, readonly, assign,
           getter=isVisible)                BOOL                    visible;

/**
 *  @brief  A Boolean value that represents whether the interface is currently presenting
 *          another interface. (read-only)
 */
@property (nonatomic, readonly, assign,
           getter=isPresenting)             BOOL                    presenting;

/**
 *  Like @p presentControllerWithName:context:, but allows a configurator block.
 *
 *  @param  configurator    The configurator block used to configure the presented interface controller.
 */
- (void)presentControllerWithConfigurator:(JBInterfaceControllerConfigurator *)configurator;

/**
 *  Like @p presentControllerWithNames:contexts:, but allows an array of configurator blocks.
 *
 *  @param  configurators   An array of configurator blocks used to configure the presented interface
 *                          controllers.
 */
- (void)presentControllersWithConfigurators:(NSArray *)configurators;

/**
 *  Called to notify the interface controller to perform speculative work (like pre-caching an image).
 *
 *  NOTE: This is called when a prior interface controller (depending on paging direction) is activated.
 */
- (void)prepareForActivation;

/**
 *  Called to notify the interface controller that a presented interface controller has awakened.
 */
- (void)presentedController:(JBInterfaceController *)presentedController
        didAwakeWithContext:(id)context;

/**
 *  Called to notify the interface controller that a presented interface controller will activate.
 */
- (void)presentedControllerWillActivate:(JBInterfaceController *)presentedController;

/**
 *  Called to notify the interface controller that a presented interface controller did deactivate.
 */
- (void)presentedControllerDidDeactivate:(JBInterfaceController *)presentedController;

/**
 *  Called to notify the interface controller that its interface has just been updated.
 *  
 *  NOTE: This method can be called repeatedly for small interface updates, so update intelligently.
 */
- (void)didUpdateInterface;

/**
 *  Dismisses the current interface controller from the screen and executes the @p completion block.
 *
 *  @param  completion      The completion block to execute.
 */
- (void)dismissControllerWithCompletion:(void (^)(void))completion;

@end

/**
 *  @typedef    JBInterfaceControllerConfigureBlock
 *
 *  @brief      This block is used to configure a presented interface controller. For example, cast
 *              @p controller to a subtype and set a delegate, etc.
 */
typedef void (^JBInterfaceControllerConfigureBlock)(JBInterfaceController *controller);

/**
 *  @typedef    JBInterfaceControllerDismissBlock
 *
 *  @brief      This block is executed after a presented interface controller is dismissed.
 */
typedef void (^JBInterfaceControllerDismissBlock)(JBInterfaceController *controller);

/**
 *  @class  JBInterfaceControllerConfigurator
 *
 *  @brief  The @p JBInterfaceControllerConfigurator class encapsulates properties that are used to
 *          configure a presented interface controller.
 */
@interface JBInterfaceControllerConfigurator : NSObject

/**
 *  @brief  The name of the interface controller to display. (read-only)
 */
@property (nonatomic, readonly, copy)       NSString                                *name;

/**
 *  @brief  An object to pass to the new interface controller. (read-only)
 */
@property (nonatomic, readonly, strong)     id                                      context;

/**
 *  @brief  A block that is used to configure the new interface controller. (read-only)
 */
@property (nonatomic, readonly, copy)       JBInterfaceControllerConfigureBlock     configureBlock;

/**
 *  @brief  A block that is executed when the new interface controller is dismissed. (read-only)
 */
@property (nonatomic, readonly, copy)       JBInterfaceControllerDismissBlock       dismissBlock;

/**
 *  Creates a new interface controller configurator.
 *
 *  @param  name            The name of the interface controller you want to display.
 *                          This parameter must not be nil.
 *
 *  @param  context         An object to pass to the new interface controller.
 *
 *  @param  configureBlock  A block that is used to configure the new interface controller.
 *
 *  @param  dismissBlock    A block that is executed when the new interface controller is dismissed.
 */
+ (JBInterfaceControllerConfigurator *)configuratorWithName:(NSString *)name
                                                    context:(id)context
                                             configureBlock:(JBInterfaceControllerConfigureBlock)configureBlock
                                               dismissBlock:(JBInterfaceControllerDismissBlock)dismissBlock;

@end