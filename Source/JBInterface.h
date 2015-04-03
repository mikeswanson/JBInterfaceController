//
//  JBInterface.h
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

#import <Foundation/Foundation.h>

/**
 *  @class  JBInterface
 *
 *  @brief  The @p JBInterface class represents an interface for managing visible content.
 */
@interface JBInterface : NSObject

/**
 *  @brief The receiver’s superinterface, or nil if it has none. (read-only)
 */
@property (nonatomic, readonly, weak)       JBInterface     *superinterface;

/**
 *  @brief The receiver’s immediate subinterfaces. (read-only)
 */
@property (nonatomic, readonly, strong)     NSArray         *subinterfaces;

/**
 *  Adds an interface to the end of the receiver’s list of subinterfaces.
 *
 *  This method establishes a strong reference to @p interface and sets its superinterface to the receiver.
 *
 *  Interfaces can have only one superinterface. If @p interface already has a superinterface and that
 *  interface is not the receiver, this method removes the previous superview before making the receiver
 *  its new superview.
 *
 *  @param  interface       The interface to be added.
 */
- (void)addSubinterface:(JBInterface *)interface;

/**
 *  Unlinks the interface from its superinterface.
 *
 *  If the interface’s superinterface is not nil, the superinterface releases the view.
 */
- (void)removeFromSuperinterface;

/**
 *  Marks the receiver as needing to be updated.
 *
 *  You can use this method to notify the system that your interface’s contents need to be updated.
 */
- (void)setNeedsUpdate;

/**
 *  Updates the interface and subinterfaces immediately.
 */
- (void)updateIfNeeded;

/**
 *  Updates the interface.
 *
 *  Subclasses can override this method as needed to update the interface. You should not call this method
 *  directly. If you want to force an interface update at the next opportunity, call the @p setNeedsUpdate
 *  method. If you want to update the interface immediately, call the @p updateIfNeeded method.
 */
- (void)updateInterface;

@end
