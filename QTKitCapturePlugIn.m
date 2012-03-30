//
//  QTKitCapturePlugIn.m
//  QTKitCapture
//
//  Copyright (c) Aldo Hoeben / fieldOfView
//  All rights reserved.
//
//  A large portion of the plug-in is based on code posted by Adam on stackoverflow:
//  http://stackoverflow.com/questions/7975329/creating-a-selectable-video-input-patch-for-quartz-muxed-inputs-fail
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

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "QTKitCapturePlugIn.h"

#define	kQCPlugIn_Name				@"QTKit Capture"
#define	kQCPlugIn_Description		@"Video input using the QTKit Capture framework"


@implementation QTKitCapturePlugIn

/*
Here you need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation
@dynamic inputFoo, outputBar;
*/
@dynamic inputDevice, inputWidth, inputHeight, outputImage;

+ (NSDictionary*) attributes
{
	/*
	Return a dictionary of attributes describing the plug-in (QCPlugInAttributeNameKey, QCPlugInAttributeDescriptionKey...).
	*/
	
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSArray*) sortedPropertyPortKeys
{
    return [NSArray arrayWithObjects:@"inputDevice",
            @"inputWidth",
            @"inputHeight",
			nil];
} 

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/*
	Specify the optional attributes for property based ports (QCPortAttributeNameKey, QCPortAttributeDefaultValueKey...).
	*/
	if([key isEqualToString:@"inputDevice"]) {
        NSArray *videoDevices= [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo];
        NSArray *muxedDevices= [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed];
		
        NSMutableArray *mutableArrayOfDevice = [[NSMutableArray alloc] init ];
        [mutableArrayOfDevice addObjectsFromArray:videoDevices];
        [mutableArrayOfDevice addObjectsFromArray:muxedDevices];
		
        NSArray *devices = [NSArray arrayWithArray:mutableArrayOfDevice];
        [mutableArrayOfDevice release];
		
        NSMutableArray *deviceNames= [NSMutableArray array];
		
        int i, ic= [devices count];
		
		
        for(i= 0; i<ic; i++) {
            [deviceNames addObject:[[devices objectAtIndex:i] description]];
            // be sure not to add CT to the list
        }
		
        return [NSDictionary dictionaryWithObjectsAndKeys:
                @"Device", QCPortAttributeNameKey,
                QCPortTypeIndex,QCPortAttributeTypeKey,
                [NSNumber numberWithInt:0], QCPortAttributeMinimumValueKey,
                deviceNames, QCPortAttributeMenuItemsKey,
                [NSNumber numberWithInt:ic-1], QCPortAttributeMaximumValueKey,
                nil];
    }
	
	if([key isEqualToString:@"inputWidth"])
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:640], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithInt:4], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithInt:2560], QCPortAttributeMaximumValueKey,
				@"Width", QCPortAttributeNameKey,
				nil];
	
	if([key isEqualToString:@"inputHeight"])
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:480], QCPortAttributeDefaultValueKey,				
				[NSNumber numberWithInt:3], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithInt:1920], QCPortAttributeMaximumValueKey,
				@"Height", QCPortAttributeNameKey,
				nil];	
	
	if([key isEqualToString:@"outputImage"])
		return [NSDictionary dictionaryWithObject:@"Image" forKey:QCPortAttributeNameKey];
	
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	/*
	Return the execution mode of the plug-in: kQCPlugInExecutionModeProvider, kQCPlugInExecutionModeProcessor, or kQCPlugInExecutionModeConsumer.
	*/
	
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode) timeMode
{
	/*
	Return the time dependency mode of the plug-in: kQCPlugInTimeModeNone, kQCPlugInTimeModeIdle or kQCPlugInTimeModeTimeBase.
	*/
	
	return kQCPlugInTimeModeIdle;
}

- (id) init
{
	if(self = [super init]) {
		/*
		Allocate any permanent resource required by the plug-in.
		*/
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(_devicesDidChange:) 
													 name:QTCaptureDeviceWasConnectedNotification 
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(_devicesDidChange:) 
													 name:QTCaptureDeviceWasDisconnectedNotification 
												   object:nil];
	}
	
	return self;
}

- (void) finalize
{
	/*
	Release any non garbage collected resources created in -init.
	*/
	
	[super finalize];
}

- (void) dealloc
{
	/*
	Release any resources created in -init.
	*/
	
    if (mCaptureSession)					[mCaptureSession release];  
    if (mCaptureDecompressedVideoOutput)	[mCaptureDecompressedVideoOutput release];
    if (mCaptureDeviceInput)				[mCaptureDeviceInput release]; 	
	
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

@end

@implementation QTKitCapturePlugIn (Execution)

- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
	Return NO in case of fatal failure (this will prevent rendering of the composition to start).
	*/
	
	return YES;
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
	/*
	 Called by Quartz Composer when rendering of the composition stops: perform any required cleanup for the plug-in.
	 */
	
	if (mCaptureSession)					[mCaptureSession stopRunning]; 
}

- (void) enableExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
	*/
}

- (void) disableExecution:(id<QCPlugInContext>)context
{
	/*
	 Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
	 */
 	
}

static void _BufferReleaseCallback(const void* address, void* info)
{
    CVPixelBufferUnlockBaseAddress(info, 0); 
	
    CVBufferRelease(info);
}


- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	/*
	Called by Quartz Composer whenever the plug-in instance needs to execute.
	Only read from the plug-in inputs and produce a result (by writing to the plug-in outputs or rendering to the destination OpenGL context) within that method and nowhere else.
	Return NO in case of failure during the execution (this will prevent rendering of the current frame to complete).
	
	The OpenGL context for rendering can be accessed and defined for CGL macros using:
	CGLContextObj cgl_ctx = [context CGLContextObj];
	*/
	
	
	if ( !mCaptureSession || [mCaptureSession isRunning] == NO || _currentDevice != self.inputDevice ||
		_currentWidth != self.inputWidth || _currentHeight != self.inputHeight ){
        NSError *error = nil;
        BOOL success;
		
        NSArray *videoDevices= [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo];
        NSArray *muxedDevices= [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed];
		
        NSMutableArray *mutableArrayOfDevice = [[NSMutableArray alloc] init ];
        [mutableArrayOfDevice addObjectsFromArray:videoDevices];
        [mutableArrayOfDevice addObjectsFromArray:muxedDevices];
		
        NSArray *devices = [NSArray arrayWithArray:mutableArrayOfDevice];
        [mutableArrayOfDevice release];
		
		
        NSUInteger d= self.inputDevice;
        if (!(d<[devices count])) {
            d= 0;
        }
        QTCaptureDevice *device = [devices objectAtIndex:d];
        success = [device open:&error];
        if (!success) {
            NSLog(@"Could not open device %@", device);
            self.outputImage = nil; 
            return YES;
        } 
        NSLog(@"Opened device successfully");
		
		
		
		
        [mCaptureSession release];
        mCaptureSession = [[QTCaptureSession alloc] init];
		
        [mCaptureDeviceInput release];
        mCaptureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
		
        // if the device is a muxed connection  make sure to get the right connection
        if ([muxedDevices containsObject:device]) {
            NSLog(@"Disabling audio connections");
            NSArray *ownedConnections = [mCaptureDeviceInput connections];
            for (QTCaptureConnection *connection in ownedConnections) {
                NSLog(@"MediaType: %@", [connection mediaType]);
                if ( [[connection mediaType] isEqualToString:QTMediaTypeSound]) {
                    [connection setEnabled:NO];
                    NSLog(@"disabling audio connection");
					
                }
            }
        }
		
		
		
        success = [mCaptureSession addInput:mCaptureDeviceInput error:&error];
		
        if (!success) {
            NSLog(@"Failed to add Input");
            self.outputImage = nil; 
            if (mCaptureSession) {
                [mCaptureSession release];
                mCaptureSession= nil;
            }
            if (mCaptureDeviceInput) {
                [mCaptureDeviceInput release];
                mCaptureDeviceInput= nil;
				
            }
            return YES;
        }
		
		
		
		
        NSLog(@"Adding output");
		
        [mCaptureDecompressedVideoOutput release];
        mCaptureDecompressedVideoOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
		
        [mCaptureDecompressedVideoOutput setPixelBufferAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
		  [NSNumber numberWithUnsignedInt: self.inputWidth], kCVPixelBufferWidthKey,
		  [NSNumber numberWithUnsignedInt: self.inputHeight], kCVPixelBufferHeightKey,
          [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLCompatibilityKey,
          [NSNumber numberWithLong:k32ARGBPixelFormat], kCVPixelBufferPixelFormatTypeKey, nil]];
		
        [mCaptureDecompressedVideoOutput setDelegate:self];
        success = [mCaptureSession addOutput:mCaptureDecompressedVideoOutput error:&error];
		
        if (!success) {
            NSLog(@"Failed to add output");
            self.outputImage = nil; 
            if (mCaptureSession) {
                [mCaptureSession release];
                mCaptureSession= nil;
            }
            if (mCaptureDeviceInput) {
                [mCaptureDeviceInput release];
                mCaptureDeviceInput= nil;
            }
            if (mCaptureDecompressedVideoOutput) {
                [mCaptureDecompressedVideoOutput release];
                mCaptureDecompressedVideoOutput= nil;
            }
            return YES;
        }
		
        [mCaptureSession startRunning]; 
        _currentDevice = self.inputDevice;
		
		_currentWidth = self.inputWidth;
		_currentHeight = self.inputHeight;
    }
	
	
    CVImageBufferRef imageBuffer = CVBufferRetain(mCurrentImageBuffer);
	
    if (imageBuffer) {
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        //NSLog(@"ColorSpace: %@", CVImageBufferGetColorSpace(imageBuffer));
        //NSLog(@"ColorSpace: %@ Height: %@ Width: %@", CVImageBufferGetColorSpace(imageBuffer), CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer));
        id provider= [context outputImageProviderFromBufferWithPixelFormat:QCPlugInPixelFormatARGB8           
                                                                pixelsWide:CVPixelBufferGetWidth(imageBuffer)
                                                                pixelsHigh:CVPixelBufferGetHeight(imageBuffer)
                                                               baseAddress:CVPixelBufferGetBaseAddress(imageBuffer)
                                                               bytesPerRow:CVPixelBufferGetBytesPerRow(imageBuffer)
                                                           releaseCallback:_BufferReleaseCallback
                                                            releaseContext:imageBuffer
                                                                colorSpace:CVImageBufferGetColorSpace(imageBuffer)
                                                          shouldColorMatch:YES];
        if(provider == nil) {
            return NO; 
        }
        self.outputImage = provider;
    } 
    else 
        self.outputImage = nil; 	
	
	return YES;
}



- (void)captureOutput:(QTCaptureOutput *)captureOutput
  didOutputVideoFrame:(CVImageBufferRef)videoFrame 
     withSampleBuffer:(QTSampleBuffer *)sampleBuffer 
       fromConnection:(QTCaptureConnection *)connection
{    
    //NSLog(@"connection type: %@", [connection mediaType]);
    CVImageBufferRef imageBufferToRelease;
    CVBufferRetain(videoFrame);
    imageBufferToRelease = mCurrentImageBuffer;
	
	
    @synchronized (self) {
        mCurrentImageBuffer = videoFrame;
    }
    CVBufferRelease(imageBufferToRelease);
}


- (void)_devicesDidChange:(NSNotification *)aNotification
{
	//NSLog(@"Devices changed");
}


@end
