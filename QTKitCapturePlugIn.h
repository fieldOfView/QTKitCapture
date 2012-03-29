//
//  QTKitCapturePlugIn.h
//  QTKitCapture
//
//  Created by Aldo Hoeben on 3/29/12.
//  Copyright (c) 2012 fieldOfView. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <QTKit/QTkit.h>

@interface QTKitCapturePlugIn : QCPlugIn
{
	QTCaptureSession					*mCaptureSession;
	QTCaptureDeviceInput				*mCaptureDeviceInput;
	QTCaptureDecompressedVideoOutput	*mCaptureDecompressedVideoOutput;
	
	CVImageBufferRef					mCurrentImageBuffer;

	NSUInteger							_currentDevice;
	NSUInteger							_currentWidth;
	NSUInteger							_currentHeight;
}

/*
Declare here the Obj-C 2.0 properties to be used as input and output ports for the plug-in e.g.
@property double inputFoo;
@property(assign) NSString* outputBar;
You can access their values in the appropriate plug-in methods using self.inputFoo or self.inputBar
*/

/* Declare a property input for the port with the key "inputDevice" */
@property(assign) NSUInteger inputDevice;
/* Declare a property input port of type "Number" and with the key "inputWidth" */
@property(assign) NSUInteger inputWidth;
/* Declare a property input for the port "Number" and with the key "inputHeight" */
@property(assign) NSUInteger inputHeight;

/* Declare a property output for the port with the key "outputImage" */
@property(assign) id<QCPlugInOutputImageProvider> outputImage;

@end
