//
//  JBInterface.m
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

#import "JBInterface_Protected.h"

@interface JBInterface ()

@property (nonatomic, readwrite, weak)      JBInterface     *superinterface;
@property (nonatomic, readwrite, strong)    NSMutableArray  *mutableSubinterfaces;

@end

@implementation JBInterface

#pragma mark - Object management

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        _superinterface = nil;
        _mutableSubinterfaces = [NSMutableArray array];
        _needsUpdate = YES;
    }
    return self;
}

#pragma mark - Properties

- (NSArray *)subinterfaces {
    
    return [NSArray arrayWithArray:_mutableSubinterfaces];
}

#pragma mark - Methods

- (void)addSubinterface:(JBInterface *)interface {
    
    NSParameterAssert(interface);
    NSAssert(![self.mutableSubinterfaces containsObject:interface], @"Interface has already been added");

    if (interface.superinterface &&
        interface.superinterface != self) {
        
        [interface removeFromSuperinterface];
    }
    else {
    
        interface.superinterface = self;
    }
    
    [self.mutableSubinterfaces addObject:interface];
    
    // Make sure we do an update pass on our new child
    [interface setNeedsUpdate];
}

- (void)removeSubinterface:(JBInterface *)interface {
    
    NSParameterAssert(interface);
    NSAssert([self.mutableSubinterfaces containsObject:interface], @"Interface not found");
    
    interface.superinterface = nil;
    [self.mutableSubinterfaces removeObject:interface];
}

- (void)removeFromSuperinterface {

    if (self.superinterface) {

        [self.superinterface removeSubinterface:self];
    }
}

- (void)setNeedsUpdate {
    
    self.needsUpdate = YES;
    
    // Up the chain
    if (self.superinterface) {
        
        [self.superinterface setNeedsUpdate];
    }
}

- (void)updateIfNeeded {
    
    if (self.needsUpdate) {
        
        [self updateInterface];
        
        NSAssert(!self.needsUpdate, @"updateInterface must call super");
        
        for (JBInterface *interface in self.mutableSubinterfaces) {
            
            [interface updateIfNeeded];
        }
    }
}

- (void)updateInterface {
    
    self.needsUpdate = NO;
}

@end
