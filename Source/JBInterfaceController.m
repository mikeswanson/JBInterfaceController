//
//  JBInterfaceController.m
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

#import "JBInterfaceController_Protected.h"
#import "JBInterface_Protected.h"

typedef NS_ENUM(NSInteger, JBInterfaceControllerPagingDirection) {
    
    JBInterfaceControllerPagingDirectionUnknown,
    JBInterfaceControllerPagingDirectionForwards,
    JBInterfaceControllerPagingDirectionBackwards
};

#pragma mark - JBInterfaceControllerContext class

/**
 *  @class  JBInterfaceControllerContext
 *
 *  @brief  Additional context to use when presenting interface controllers.
 */
@interface JBInterfaceControllerContext : NSObject

@property (nonatomic, readwrite, weak)      JBInterfaceController   *presentingController;
@property (nonatomic, readwrite, assign)    NSUInteger              index;
@property (nonatomic, readwrite, strong)    id                      context;

+ (JBInterfaceControllerContext *)contextWithPresentingController:(JBInterfaceController *)presentingController
                                                            index:(NSUInteger)index
                                                          context:(id)context;

@end

@implementation JBInterfaceControllerContext

+ (JBInterfaceControllerContext *)contextWithPresentingController:(JBInterfaceController *)presentingController
                                                            index:(NSUInteger)index
                                                          context:(id)context {
    
    NSParameterAssert(presentingController);
    
    JBInterfaceControllerContext *controllerContext = [[JBInterfaceControllerContext alloc] init];
    controllerContext.presentingController = presentingController;
    controllerContext.index = index;
    controllerContext.context = context;
    
    return controllerContext;
}

@end

#pragma mark - JBInterfaceControllerConfigurator class

@interface JBInterfaceControllerConfigurator ()

@property (nonatomic, readwrite, copy)      NSString                                *name;
@property (nonatomic, readwrite, strong)    id                                      context;
@property (nonatomic, readwrite, copy)      JBInterfaceControllerConfigureBlock     configureBlock;
@property (nonatomic, readwrite, copy)      JBInterfaceControllerDismissBlock       dismissBlock;

@end

@implementation JBInterfaceControllerConfigurator

+ (JBInterfaceControllerConfigurator *)configuratorWithName:(NSString *)name
                                                    context:(id)context
                                             configureBlock:(JBInterfaceControllerConfigureBlock)configureBlock
                                               dismissBlock:(JBInterfaceControllerDismissBlock)dismissBlock {
    
    NSParameterAssert(name && name.length > 0);
    
    JBInterfaceControllerConfigurator *configurator = [[JBInterfaceControllerConfigurator alloc] init];
    configurator.name = name;
    configurator.context = context;
    configurator.configureBlock = configureBlock;
    configurator.dismissBlock = dismissBlock;
    
    return configurator;
}

@end

#pragma mark - JBInterfaceController class

static BOOL isInBackground = NO;

@interface JBInterfaceController ()

@property (nonatomic, readwrite, weak)      JBInterfaceController                   *presentingController;
@property (nonatomic, readwrite, strong)    JBInterface                             *interface;
@property (nonatomic, readwrite, assign,
           getter=isVisible)                BOOL                                    visible;
@property (nonatomic, readwrite, copy)      void                                    (^dismissCompletion)(void);
@property (nonatomic, readwrite, strong)    NSPointerArray                          *presentedControllers;
@property (nonatomic, readwrite, assign)    NSUInteger                              lastActivatedIndex;
@property (nonatomic, readwrite, assign)    JBInterfaceControllerPagingDirection    pagingDirection;
@property (nonatomic, readwrite, strong)    NSArray                                 *configurators;

@property (nonatomic, readonly, assign)     BOOL                                    isMenuBugPossible;
@property (nonatomic, readonly, assign)     BOOL                                    isInBackground;
@property (nonatomic, readwrite, weak)      JBInterfaceController                   *lastActivatedController;

@end

@implementation JBInterfaceController

#pragma mark - Class methods

+ (void)initialize {
    
    if (self == [JBInterfaceController class]) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(extensionHostWillEnterForegroundNotification:)
                                                     name:NSExtensionHostWillEnterForegroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(extensionHostWillResignActiveNotification:)
                                                     name:NSExtensionHostWillResignActiveNotification
                                                   object:nil];
    }
}

+ (void)extensionHostWillEnterForegroundNotification:(NSNotification *)notification {
    
    isInBackground = NO;
}

+ (void)extensionHostWillResignActiveNotification:(NSNotification *)notification {

    isInBackground = YES;
}

#pragma mark - Object management

- (void)dealloc {

    if (_interface) {
        
        [_interface removeObserver:self forKeyPath:@"needsUpdate"];
    }
}

#pragma mark - Methods

- (void)awakeWithContext:(id)context {

    [super awakeWithContext:context];   // NOTE: WKInterfaceController's implementatation does nothing

    // If we recognize our context, unwrap and process
    if ([context isKindOfClass:[JBInterfaceControllerContext class]]) {
        
        JBInterfaceControllerContext *controllerContext = (JBInterfaceControllerContext *)context;
        self.presentingController = controllerContext.presentingController;
        NSUInteger index = controllerContext.index;
        
        [self.presentingController configurePresentedController:self index:index];
        
        [self.presentingController presentedController:self
                                   didAwakeWithContext:controllerContext.context];
    }
}

- (void)willActivate {

    [super willActivate];   // NOTE: WKInterfaceController's implementatation does nothing
    
    // If we're presenting (and now becoming visible), dismiss our presented controllers
    if (self.isPresenting) {
        
        [self dismissPresentedControllers];
    }
    
    self.visible = YES;
    
    [self updateInterfaceIfNeeded];
    
    // Called after modal dismiss
    if (self.dismissCompletion) {
        
        self.dismissCompletion();
        self.dismissCompletion = nil;
    }
    
    if (self.presentingController) {
        
        [self.presentingController prepareNextControllerForActivationWithPresentedController:self];
        [self.presentingController presentedControllerWillActivate:self];
    }
}

- (void)didDeactivate {

    [super didDeactivate];  // NOTE: WKInterfaceController's implementatation does nothing
    
    self.visible = NO;
    
    if (self.presentingController) {
        
        [self.presentingController presentedControllerDidDeactivate:self];
    }
}

- (void)didDismiss {
    
    // Override in subclass
}

#pragma mark - Properties

- (BOOL)isMenuBugPossible {
    
    NSOperatingSystemVersion version = [NSProcessInfo processInfo].operatingSystemVersion;

    // Assume this is fixed after 8.2.0 (but we'll have to change this if that isn't the case)
    return (version.majorVersion == 8 &&
            version.minorVersion == 2 &&
            version.patchVersion == 0);
}

- (JBInterface *)interface {
    
    if (!_interface) {
        
        _interface = [[JBInterface alloc] init];
        
        [_interface addObserver:self
                     forKeyPath:@"needsUpdate"
                        options:NSKeyValueObservingOptionNew
                        context:nil];
    }
    
    return _interface;
}

- (BOOL)isPresenting {
    
    // While it's simply the inverse of isVisible (at least for now), it's handy mentally
    return !_visible;
}

- (BOOL)isInBackground {
    
    return isInBackground;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([keyPath isEqualToString:@"needsUpdate"]) {
        
        if (self.isVisible) {

            [self updateInterfaceIfNeeded];
        }
    }
}

#pragma mark - Context handling

- (id)wrappedContext:(id)context index:(NSUInteger)index {
    
    id wrappedContext = nil;
    
    if ([context isKindOfClass:[JBInterfaceControllerContext class]]) {
        
        JBInterfaceControllerContext *controllerContext = (JBInterfaceControllerContext *)context;
        controllerContext.presentingController = self;
        controllerContext.index = index;
        
        wrappedContext = controllerContext;
    }
    else {
        
        wrappedContext = [JBInterfaceControllerContext contextWithPresentingController:self
                                                                                 index:index
                                                                               context:context];
    }
    
    return wrappedContext;
}

- (NSArray *)wrappedContexts:(NSArray *)contexts {
    
    NSMutableArray *wrappedContexts = [NSMutableArray array];
    for (NSUInteger index = 0; index < contexts.count; index++) {
        
        id context = contexts[index];
        
        [wrappedContexts addObject:[self wrappedContext:context index:index]];
    }
    
    return [NSArray arrayWithArray:wrappedContexts];
}

- (id)unwrappedContext:(id)context {
    
    return ([context isKindOfClass:[JBInterfaceControllerContext class]] ?
            ((JBInterfaceControllerContext *)context).context :
            context);
}

#pragma mark - Presented controller management

- (void)configurePresentedController:(JBInterfaceController *)presentedController
                               index:(NSUInteger)index {
    
    NSParameterAssert(presentedController);
    NSParameterAssert(index < self.presentedControllers.count);
    
    [self.presentedControllers replacePointerAtIndex:index withPointer:(__bridge void *)(presentedController)];
    
    // Have a a configuration block?
    if (self.configurators) {
        
        JBInterfaceControllerConfigurator *configurator = self.configurators[index];
        if (configurator.configureBlock) {
            
            configurator.configureBlock(presentedController);
            
            // No need to keep configuration blocks
            configurator.configureBlock = nil;
        }
    }
    
    // If this is our first controller, give it a chance to prepare
    if (index == 0) {
        
        [presentedController prepareForActivation];
    }
}

- (NSUInteger)indexOfPresentedController:(JBInterfaceController *)presentedInterfaceController {
    
    NSParameterAssert(presentedInterfaceController);
    
    NSUInteger index = NSNotFound;
    
    for (NSUInteger searchIndex = 0; searchIndex < self.presentedControllers.count; searchIndex++) {
        
        if (presentedInterfaceController == [self.presentedControllers pointerAtIndex:searchIndex]) {
            
            index = searchIndex;
            break;
        }
    }
    
    return index;
}

- (void)prepareNextControllerForActivationWithPresentedController:(JBInterfaceController *)presentedController {
    
    NSParameterAssert(presentedController);
    
    // Let the next interface controller (if we have one) know that it can prepare for activation
    
    NSUInteger index = [self indexOfPresentedController:presentedController];
    
    NSAssert(index != NSNotFound, @"Incorrect presentedControllers state");
    
    // Determine direction
    self.pagingDirection = (index < self.lastActivatedIndex ?
                            JBInterfaceControllerPagingDirectionBackwards :
                            JBInterfaceControllerPagingDirectionForwards);
    self.lastActivatedIndex = index;
    
    // Depending on direction, find the "next" interface controller
    id nextController = nil;
    if (self.pagingDirection == JBInterfaceControllerPagingDirectionBackwards) {
        
        if (index > 0) {
            
            nextController = [self.presentedControllers pointerAtIndex:(index - 1)];
        }
    }
    else if (self.pagingDirection == JBInterfaceControllerPagingDirectionForwards) {
        
        if (index < (self.presentedControllers.count - 1)) {
            
            nextController = [self.presentedControllers pointerAtIndex:(index + 1)];
        }
    }
    
    if (nextController) {
        
        JBInterfaceController *controller = (JBInterfaceController *)nextController;
        
        [controller prepareForActivation];
    }
    
    // Check for modal bug
    if (presentedController == self.lastActivatedController) {
        
        [self informPresentedControllersOfMenuBug];
    }
    
    self.lastActivatedController = presentedController;
}

- (void)informPresentedControllersOfMenuBug {
    
    // 3/26/2015 - While nobody has confirmed when (or even if) this bug will be fixed, we assume it's bad enough that
    //             it'll be fixed in the next update. If we're wrong, we'll have to issue an update that modifies this
    //             logic. But honestly, we'd have to issue an update anyway, so this guess is worth it.
    
    if (self.isMenuBugPossible) {
        
        // NOTE: willActivate: is called *before* we're informed on the extension notification. So, we can
        //       use our current state to determine if we've just come from the background.
        if (!self.isInBackground) {
            
            for (JBInterfaceController *controller in self.presentedControllers) {
                
                [controller fixMenuBug];
            }
        }
    }
}

- (void)dismissPresentedControllers {
    
    for (NSUInteger index = 0; index < self.presentedControllers.count; index++) {
        
        JBInterfaceController *presentedController = [self.presentedControllers pointerAtIndex:index];
        JBInterfaceControllerConfigurator *configurator = self.configurators[index];
        
        if (self.configurators) {
            
            // Have a a dismiss block?
            if (configurator.dismissBlock) {
                
                configurator.dismissBlock(presentedController);
                
                // No need to keep dismiss blocks
                configurator.dismissBlock = nil;
            }
        }
        
        [presentedController didDismiss];
        
        // Drop our strong reference
        [self.presentedControllers replacePointerAtIndex:index withPointer:nil];
    }
}

#pragma mark - Presented controller status

- (void)presentedController:(JBInterfaceController *)presentedController
        didAwakeWithContext:(id)context {
    
    // Override in subclass
}

- (void)presentedControllerWillActivate:(JBInterfaceController *)presentedController {

    // Override in subclass
}

- (void)presentedControllerDidDeactivate:(JBInterfaceController *)presentedController {
    
    // Override in subclass
}

- (void)presentedControllerDidDismiss:(JBInterfaceController *)presentedController {
    
    // Override in subclass
}

- (void)fixMenuBug {
    
    // Override in subclass to fix menu bug
}

- (void)prepareForActivation {
    
    // Override in subclass to perform speculative work (like pre-caching an image)
}

#pragma mark - Presentation overrides

- (void)pushControllerWithName:(NSString *)name context:(id)context {
    
    self.configurators = nil;
    [self prepareToPresentControllerCount:1];
    
    [super pushControllerWithName:name
                          context:[self wrappedContext:context index:0]];
}

- (void)popController {
    
    [super popController];
}

- (void)popToRootController {
    
    [super popToRootController];
}

- (void)presentControllerWithName:(NSString *)name context:(id)context {
    
    self.configurators = nil;
    [self prepareToPresentControllerCount:1];

    [super presentControllerWithName:name context:[self wrappedContext:context index:0]];
}

- (void)presentControllerWithNames:(NSArray *)names contexts:(NSArray *)contexts {
    
    self.configurators = nil;
    [self prepareToPresentControllerCount:contexts.count];
    
    [super presentControllerWithNames:names contexts:[self wrappedContexts:contexts]];
}

- (void)dismissController {
    
    [super dismissController];
}

- (void)dismissControllerWithCompletion:(void (^)(void))completion {
    
    self.dismissCompletion = completion;
    
    [self dismissController];
}

- (void)presentTextInputControllerWithSuggestions:(NSArray *)suggestions
                                 allowedInputMode:(WKTextInputMode)inputMode
                                       completion:(void (^)(NSArray *))completion {
    
    self.configurators = nil;
    [self prepareToPresentControllerCount:1];
    
    [super presentTextInputControllerWithSuggestions:suggestions
                                    allowedInputMode:inputMode
                                          completion:completion];
}

- (void)dismissTextInputController {
    
    [super dismissTextInputController];
}

- (void)prepareToPresentControllerCount:(NSUInteger)count {
    
    NSParameterAssert(count > 0);
    
    self.visible = NO;
    
    self.presentedControllers = [NSPointerArray strongObjectsPointerArray];
    self.presentedControllers.count = count;
    self.lastActivatedIndex = 0;
}

#pragma mark - Interface update logic

- (void)updateInterfaceIfNeeded {
    
    BOOL needsUpdate = self.interface.needsUpdate;
    
    [self.interface updateIfNeeded];

    if (needsUpdate) {
        
        [self didUpdateInterface];
    }
}

- (void)didUpdateInterface {
    
    // Override in subclasses. Called after interfaces have been updated.
}

#pragma mark - Extensions

- (void)presentControllerWithConfigurator:(JBInterfaceControllerConfigurator *)configurator {

    NSParameterAssert(configurator);
    
    [self presentControllersWithConfigurators:@[ configurator ]];
}

- (void)presentControllersWithConfigurators:(NSArray *)configurators {
    
    NSParameterAssert(configurators && configurators.count > 0);
    
    self.configurators = configurators;
    [self prepareToPresentControllerCount:configurators.count];
    
    NSMutableArray *names = [NSMutableArray array];
    NSMutableArray *contexts = [NSMutableArray array];
    for (JBInterfaceControllerConfigurator *configurator in self.configurators) {
        
        [names addObject:configurator.name];
        [contexts addObject:configurator.context];
    }
    
    [super presentControllerWithNames:[NSArray arrayWithArray:names]
                             contexts:[self wrappedContexts:contexts]];
}

@end



