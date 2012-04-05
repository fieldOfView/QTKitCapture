//
//  QTKitCapturePlugIn.h
//  QTKitCapture
//
//  Copyright (c) Aldo Hoeben / fieldOfView
//  All rights reserved.
//
//  A large portion of the plug-in is based on code posted by Adam Fenn on Kineme.net:
//  http://kineme.net/forum/Programming/SelectableVideoInput
//  
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that
//  the following conditions are met:
//  
//  * Redistributions of source code must retain the above copyright notice, this list of conditions and
//  the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
//  the following disclaimer in the documentation and/or other materials provided with the distribution.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
//  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
//  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
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
