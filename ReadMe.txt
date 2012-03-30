Quartz Composer Plugin

CommandLineTool					
A Quartz Composer plug-in that captures video from a QCKit Capture device such as a webcam.

About the plugin
The builtin Video Input patch always captures at the highest resolution available with the connected device, often resulting in a low framerate (at high resolution). This plugin is an alternative to the builtin Video Input patch and provides the capture class a target-width and -height. QCKit Capture is smart enough to initialise capture at a resolution close to the requested resolution, thus offering higher framerates at lower resolution.

Credits
A large portion of the plug-in is based on code posted by Adam on stackoverflow:
http://stackoverflow.com/questions/7975329/creating-a-selectable-video-input-patch-for-quartz-muxed-inputs-fail