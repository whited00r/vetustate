#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore2.h>
#import <QuartzCore/CAAnimation.h>
#import <IOSurface/IOSurface.h>
#import <UIKit/UIGraphics.h>
#import <Foundation/Foundation.h>
//#import <SpringBoard/SpringBoard.h>
//#import <substrate.h>
#import <GraphicsServices/GSEvent.h>
#import <Foundation/NSObject.h>
//#import <logos/logos.h>

//Stack blur is the fastest blur I have found thus far for 3.1.3.
#import "UIImage+StackBlur.h"
#import "UIImage+Resize.h"
#import "UIImage+LiveBlur.h"
#import <QuartzCore/QuartzCore.h>

#define VETUSTATE_SettingsReloadNotification "com.whited00r.vetustate.reloadPrefs" //Used later on for something maybe?
#define VETUSTATE_SettingsPlistPath "/var/mobile/Library/Preferences/com.whited00r.vetustate.plist"




//----------------------------------------Categories---------------------------\\
//Used for getting the blur just right.
@interface UIImage (CropThis)

- (UIImage *)croppedToRect:(CGRect)rect;
@end

@implementation UIImage (CropThis)
- (UIImage *)croppedToRect:(CGRect)rect {

   CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef); 
    return cropped;
}
@end

//Going to be used for overlaying a general tint colour defined in the settings app
@interface UIImage (Tint)

- (UIImage *)tintedImageUsingColor:(UIColor *)tintColor;

@end

@implementation UIImage (Tint)

- (UIImage *)tintedImageUsingColor:(UIColor *)tintColor {
  UIGraphicsBeginImageContext(self.size);
  CGRect drawRect = CGRectMake(0, 0, self.size.width, self.size.height);
  [self drawInRect:drawRect];
  [tintColor set];
  UIRectFillUsingBlendMode(drawRect, kCGBlendModeSourceAtop);
  UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return tintedImage;
}

@end


//--------------------------------Interfaces----------------------------\\
@interface VetustateController : NSObject
- (void)updateWindowLevel:(NSNotification *)notification;
-(void)loadVetustate;
-(void)unloadVetustate;
- (void)openedVetustate:(NSString *)animationID finished:(BOOL)finished context:(void *)context;
- (void)closedVetustate:(NSString *)animationID finished:(BOOL)finished context:(void *)context;
@end

@interface VetustateWindow : UIWindow

@end

@interface VetustateSwiper : UIImageView
CGPoint startLocation;
@property (nonatomic, assign) id  delegate;
@end


//------------------------Static Variables---------------------------------\\

static VetustateSwiper * vSwiper;

static VetustateWindow * vWindow;

static VetustateController * vController;

static BOOL vIsShowing = FALSE;

static UIImage *vBackgroundImage;

static UIImageView *vBackgroundImageView;

static BOOL blurBackground = TRUE;

static BOOL shouldUpdateBackground = TRUE;

static BOOL tintBlur = FALSE;

static BOOL loadedPrefs = FALSE;

static void loadPrefs();


//-------------------------Implementations------------------------------------\\



static void loadPrefs(){

  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
    if([[NSFileManager defaultManager] fileExistsAtPath:@VETUSTATE_SettingsPlistPath]){
        NSDictionary *prefs=[[NSDictionary alloc] initWithContentsOfFile:@VETUSTATE_SettingsPlistPath];
        blurBackground = [[prefs objectForKey:@"blurBackground"] boolValue];
        tintBlur = TRUE; //FIXME[[prefs objectForKey:@"tintBlur"] boolValue];
        [prefs release];

    }
    else{
        NSDictionary *prefs=[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithBool:TRUE],@"blurBackground", [NSNumber numberWithBool:FALSE], @"tintBlur", nil];
        [prefs writeToFile:@VETUSTATE_SettingsPlistPath atomically:YES];
        [prefs release];
    }
//CFNotificationCenterAddObserver( CFNotificationCenterGetDarwinNotifyCenter(), NULL, (void (*)(CFNotificationCenterRef, void *, CFStringRef, const void *, CFDictionaryRef))ReloadPreferences, CFSTR("com.whited00r.controlcenter.reloadPrefs"), NULL, CFNotificationSuspensionBehaviorHold );
    loadedPrefs = TRUE;
    [pool drain];
}

@implementation VetustateController 

-(id)init{
	self = [super init];
	if(self){

	}
	return self;
}

- (void)updateWindowLevel:(NSNotification *)notification{

vWindow.hidden = FALSE;
[vWindow makeKeyAndVisible];
vWindow.windowLevel = 9000;	
}

-(void)loadVetustate{
NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
shouldUpdateBackground = FALSE; //So it doesn't update when open.
[UIView beginAnimations:@"curlup" context:nil];
[UIView setAnimationDelegate:self];
[UIView setAnimationDuration:0.3];
[UIView setAnimationDidStopSelector:@selector(openedVetustate:finished:context:)];

if(blurBackground){
vBackgroundImageView.image = [vBackgroundImage croppedToRect:CGRectMake(0,vWindow.frame.origin.y , vWindow.frame.size.width, vWindow.frame.size.height)];
vBackgroundImageView.frame = CGRectMake(0,0,vWindow.frame.size.width, vWindow.frame.size.height);
}
[UIView commitAnimations];
 //now its opened, swipe downnnn to close :3
[pool drain];
}

- (void)openedVetustate:(NSString *)animationID finished:(BOOL)finished context:(void *)context{
 vIsShowing = TRUE;
 if(blurBackground){
 vBackgroundImageView.image = [vBackgroundImage croppedToRect:CGRectMake(0,vWindow.frame.origin.y , vWindow.frame.size.width, vWindow.frame.size.height)];

vBackgroundImageView.frame = CGRectMake(0,0,vWindow.frame.size.width, vWindow.frame.size.height);
}
}

-(void)unloadVetustate{
shouldUpdateBackground = TRUE; //So it recreates the image it on load up of the next time :p
[UIView beginAnimations:@"curldown" context:nil];
[UIView setAnimationDelegate:self];
[UIView setAnimationDuration:0.3];
[UIView setAnimationDidStopSelector:@selector(closedVetustate:finished:context:)]; //call off a method after the animation completes.

vBackgroundImageView.frame = CGRectMake(0,0,vWindow.frame.size.width, 0);
[UIView commitAnimations];
}

-(void)closedVetustate:(NSString *)animationID finished:(BOOL)finished context:(void *)context{
vWindow.frame = CGRectMake(0,-vWindow.frame.size.height + 20,vWindow.frame.size.width, vWindow.frame.size.height);
vIsShowing = FALSE;
}


@end



@implementation VetustateSwiper
@synthesize delegate;
- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
 
 
startLocation = [[touches anyObject] locationInView:vWindow]; //Saving the start position...
[[self superview] bringSubviewToFront:self]; //Might need to be done, doesn't do any harm if it doesn't.
vWindow.frame = CGRectMake(0,0,vWindow.frame.size.width,vWindow.frame.size.height);
//So it doesn't remake the blur when it's open
if(blurBackground){
if(shouldUpdateBackground){

vBackgroundImage = nil;
vBackgroundImage = [UIImage liveBlurForScreenWithQuality:4 interpolation:4 blurRadius:15];
if(tintBlur){
	vBackgroundImage = [vBackgroundImage tintedImageUsingColor:[UIColor colorWithRed:82.0/255.0 green:140.0/255.0 blue:246.0/255.0 alpha:0.4]];
}
[vBackgroundImage retain];
vBackgroundImageView.frame = CGRectMake(0,0,vWindow.frame.size.width,0);
vBackgroundImageView.image = vBackgroundImage;

//vBackgroundImage = [UIImage imageWithCGImage:screen];


}
}
}
 
 
- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
// Calculate offset
if(vWindow){

CGRect screenSize = [[UIScreen mainScreen] bounds];
float screenWidth = screenSize.size.width;
float screenHeight = screenSize.size.height;

CGPoint pt = [[touches anyObject] locationInView:vWindow]; //Changed this only so it knows the actual location :P
float dx = pt.x - startLocation.x;
float dy = pt.y - startLocation.y;
 
float newCenterY = pt.y;


//vWindow.center = CGPointMake(vWindow.center.x, newCenterY);
//Moving the blur background thing to match
if(blurBackground){
vBackgroundImageView.image = [vBackgroundImage croppedToRect:CGRectMake(0,0 , screenWidth, newCenterY )];
vBackgroundImageView.frame = CGRectMake(0,0, screenWidth, newCenterY );
}
}


 
}
 
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event{

//For when the swipe is released :3

//Okay, so I changed it. It doesn't so much detect swipes as much as changes in frame. less customizable and more expandable. 
CGRect screenSize = [[UIScreen mainScreen] bounds];
float screenWidth = screenSize.size.width;
float screenHeight = screenSize.size.height;
CGPoint pt = [[touches anyObject] locationInView:self];
float dx = pt.x - startLocation.x;
float dy = pt.y - startLocation.y;

// < is equal to up
// > is equal to down
// y is down/up
// x is left/right

if(vBackgroundImageView.frame.size.height >= 60 && !vIsShowing){
 [vController loadVetustate]; //Has it been swiped up?  As you go up, you substract from 480 on the screen. 
}

if(vBackgroundImageView.frame.size.height >= screenHeight - 60 && vIsShowing){
 [vController loadVetustate]; //Has it been swiped up even more and it is already open? Shouldn't close, but rather revert the view back to normal.
}

if(vBackgroundImageView.frame.size.height <= screenHeight - 120 && vIsShowing){
 [vController unloadVetustate]; //Was it swiped down? Lets unload it.
}

if(vBackgroundImageView.frame.size.height >= screenHeight - 119 && vIsShowing){
 [vController loadVetustate]; //Is it just above where it should recognize the swipe and close? If so, close!
}

if(vBackgroundImageView.frame.size.height <= 60 && !vIsShowing){
 [vController unloadVetustate]; //Is it below the height needed to open it? Then lets revert it back to hiding.
}



}
@end


@implementation VetustateWindow 
-(id)initWithFrame:(CGRect)frame{
	self = [super initWithFrame:frame];
	if(self){

if(blurBackground){
vBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,frame.size.width, frame.size.height )];
vBackgroundImageView.image = [UIImage imageWithContentsOfFile:@"/Library/Vetustate/Background.png"]; // Doesn't have a blur on the background the first time -__-



[self addSubview:vBackgroundImageView];
[vBackgroundImageView release];
}

	}
	return self;
}

@end

//-----------------------------------Hooks----------------------------------------\\

%hook SBAwayView
-(id)initWithFrame:(CGRect)frame{
self = %orig;
if(self){

//If the vWindow doesn't exist, make it once.
if(!vWindow){
if(!loadedPrefs){
    loadPrefs(); 
}

if(!vController){
	vController = [[VetustateController alloc] init];
}

CGRect screenSize = [[UIScreen mainScreen] bounds];
float screenWidth = screenSize.size.width;
float screenHeight = screenSize.size.height;

vWindow = [[VetustateWindow alloc] initWithFrame:CGRectMake(0, -screenHeight + 20, screenWidth, screenHeight )]; //x, y, width, height
vWindow.windowLevel = 9000;
vWindow.alpha = 1.0;
vWindow.userInteractionEnabled = TRUE;
vWindow.backgroundColor = [UIColor clearColor];

[vWindow makeKeyAndVisible];

vWindow.hidden = FALSE;

//allocate the swiperecognizer we just coded
vSwiper = [[VetustateSwiper alloc] initWithFrame:CGRectMake(0,screenHeight - 20 ,screenWidth,20)];
vSwiper.image = [UIImage imageWithContentsOfFile:@"/Library/Vetustate/SwipeIt.png"]; //Set the image as the image not the background color...
//swipeIt.backgroundColor = [UIColor blueColor];
vSwiper.delegate = vController; //So now the subclass has a reference to the main code ;) (or rather the instance of ControlCenter now)
vSwiper.userInteractionEnabled = TRUE;

[vWindow addSubview:vSwiper];

[[NSNotificationCenter defaultCenter] addObserver:vController  selector:@selector(updateWindowLevel:)  name:UIApplicationDidFinishLaunchingNotification  object:nil];
//[vController release];
}


 //otherwise, if the vWindow exist, make it do this
vWindow.hidden = FALSE;
[vWindow makeKeyAndVisible];
vWindow.windowLevel = 900000;

}

/*else{
UIAlertView *roar = [[UIAlertView alloc] initWithTitle:@"BUGGER" message:@"This only works on wd7 ;)" delegate:self cancelButtonTitle:@"I am stupid, sorry" otherButtonTitles:nil];
[roar show];
[roar release];
}*/

return self;

}


%end


%hook SBAwayController
-(void)lock{ //Hooking this to handle when the screen locks.
 %orig;
 if(vIsShowing && vController){
  [vController unloadVetustate];
 }
//isLocked = TRUE;
}

-(void)_undimScreen{ //Hooked this to handle when the screen is locked and the control center is open.
 %orig;
 if(vIsShowing && vController){
  [vController unloadVetustate];
 }
}

-(BOOL)handleMenuButtonTap{ //Lockscreen handles home button presses itself.
 if(vIsShowing && vController){
  [vController unloadVetustate];
 }

 return %orig;

}

-(BOOL)handleMenuButtonDoubleTap{ //Double press it. Oh yes.
 if(vIsShowing && vController){
  [vController unloadVetustate];
 }

 return %orig;
}

-(void)unlockWithSound:(BOOL)sound{
%orig;
//isLocked = FALSE;
}

%end

%hook SBUIController
-(BOOL)clickedMenuButton{ //Might screw with bruce and a lotttt of other things... Maybe it's best to return %orig always. I say that because bruce and this tweak even rely on it closing to the homescreen and it would require re-writing this and more logic code in all the tweaks that depend on it to make it only do it for this.
 if(vIsShowing && vController){
  [vController unloadVetustate];
  //if(closeAndHome){
  // closeAndHome = FALSE; //Resetting it...
   //return %orig;
  //}
 }
else{
 return %orig; //It's not showing vController... run the original code!
}

}

%end