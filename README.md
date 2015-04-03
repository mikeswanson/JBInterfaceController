JBInterfaceController
=====================

By [Mike Swanson](http://blog.mikeswanson.com/)

JBInterfaceController is a WKInterfaceController subclass that makes it easier to manage interface controllers with WatchKit.

I don't have time to write documentation at the moment, as I'm working on my own WatchKit app. I'd recommend looking at the example project and the headers. All that said, here are a few quick comments:

* The example shows how to present interface controllers that display a replacement status bar when the "modal bug" happens (the topic of this thread).
* The example also shows how to configure delegates if you need to communicate between a presented interface controller and its presenting controller.
* The subclasses make it easy to update interface elements by calling an updateInterface method (modeled lightly after UIView drawRect and layoutSubviews concepts).
* My table rows (which I didn't include in this example) are JBInterface subclasses that simply invalidate themselves. They're then updated at the next opportunity.
* There's a prepareForActivation method that lets your interface controller do speculative work like pre-caching an image before the next page is displayed.
* You can pass dismiss blocks when you present an interface controller.
* There are calls to the presenting controller letting it know about events that happen to a presented controller (like presentedControllerWillActivate:, etc.).

This was a pretty quick extraction, so I'm sure I didn't get everything right. But, I'm buried at the moment and figured that anything was better than nothing.

## Requirements

Because JBInterfaceController is based on WatchKit, it requires iOS 8.2 or later.