// Copyright: 2015, Ableton AG, Berlin. All rights reserved.

#import "ViewController.h"
#import "AudioEngine.h"

@interface ViewController ()

@property (strong, nonatomic) UIView *ablSyncIndicatorView;

-(void) setIsPlaying:(BOOL)isPlaying atTempo:(Float32)bpm;
-(void) setConnectionState:(BOOL)state;

@end

#pragma mark - ABLSync Callbacks
static void receivedConnectionState(bool connectionState, void *context) {
    ViewController *vc = (__bridge ViewController *)context;
    [vc setConnectionState:connectionState];
}

static void receivedEvent(ABLSharedTime _sharedTime, bool isPlaying, Float32 sharedBpm, void *context) {
    ViewController *vc = (__bridge ViewController *)context;
    [vc setIsPlaying:isPlaying atTempo:sharedBpm];
}

@implementation ViewController {
  AudioEngine *_audioEngine;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    _audioEngine = [AudioEngine new];
    _ablSyncIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];

    [self setConnectionState:NO];
    [self setIsPlaying:ABLSyncGetIsTransportPlaying(_audioEngine.ablSync)
               atTempo:ABLSyncGetSharedBpm(_audioEngine.ablSync)];

    ABLSyncSetConnectionStateCallback(_audioEngine.ablSync, &receivedConnectionState, (__bridge void*)self);
    ABLSyncSetEventCallback(_audioEngine.ablSync, &receivedEvent, (__bridge void*)self);

    [_audioEngine start];
}

- (void)setIsPlaying:(BOOL)isPlaying atTempo:(Float32)bpm {
    self.transportButton.selected = isPlaying;
    self.bpmLabel.text = [NSString stringWithFormat:@"%.1f bpm", bpm];
    // The stepper is interpretted as a delta from the last set bpm value, so we
    // reset it whenever the value is updated.
    self.bpmStepper.value = 0;
}

- (void)setConnectionState:(BOOL)isConnected {
    self.ablSyncIndicatorView.backgroundColor = isConnected
        ? [UIColor colorWithRed:1 green:0.76f blue:0.01f alpha:1]
        : [UIColor lightGrayColor];
}

#pragma mark - UI Actions
- (IBAction)transportButtonAction:(UIButton *)sender {
    if (sender.selected) {
        ABLSyncProposeTransportStop(_audioEngine.ablSync);
    }
    else {
        // Propose starting transport at shared time 0 since we don't have a way to
        // specify custom timeline values in the UI
        ABLSyncProposeTransportStart(_audioEngine.ablSync, 0);
    }
}

- (IBAction)bpmStepperAction:(UIStepper *)sender {
    Float32 currentBpm = ABLSyncGetSharedBpm(_audioEngine.ablSync);
    ABLSyncProposeBpm(_audioEngine.ablSync, currentBpm + sender.value);
}

- (IBAction)connectivitySwitchAction:(UISwitch *)sender {
    if (sender.on) {
        ABLSyncActivateConnectivity(_audioEngine.ablSync);
        [self.view addSubview:self.ablSyncIndicatorView];
    }
    else {
        ABLSyncDeactivateConnectivity(_audioEngine.ablSync);
        [self.ablSyncIndicatorView removeFromSuperview];
    }
}

@end
