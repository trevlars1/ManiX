//
//  GBCEmulatorBridge.m
//  ManicEmu
//
//  Created by Riley Testut on 4/11/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//
//  Created by Aushuang Lee on 2025/3/6.
//  Copyright © 2025 Manic EMU. All rights reserved.

#import "GBCEmulatorBridge.h"

#import <ManicEmuCore/DeltaTypes.h>
#import <ManicEmuCore/DLTAMuteSwitchMonitor.h>

#import <GLKit/GLKit.h>
#import <MetalKit/MetalKit.h>
#import <AVFoundation/AVFoundation.h>
#import <ManicEmuCore/ManicEmuCore-Swift.h>

#include "gambatte.h"
#include "cpu.h"

#include "inputgetter.h"

class GBCInputGetter : public gambatte::InputGetter
{
public:
    GBCInputGetter();
    ~GBCInputGetter();
    
    void activateInput(unsigned input);
    void deactivateInput(unsigned input);
    void resetInputs();
    
    unsigned inputs();
    
    unsigned operator()();
    
private:
    unsigned inputs_;
};

GBCInputGetter::GBCInputGetter()
{
    inputs_ = 0;
}

GBCInputGetter::~GBCInputGetter()
{
}

void GBCInputGetter::activateInput(unsigned input)
{
    inputs_ |= input;
}

void GBCInputGetter::deactivateInput(unsigned input)
{
    inputs_ &= ~input;
}

void GBCInputGetter::resetInputs()
{
    inputs_ = 0;
}

unsigned GBCInputGetter::inputs()
{
    return inputs_;
}

unsigned GBCInputGetter::operator()()
{
    return this->inputs();
}

@interface GBCCheat : NSObject

@property (copy, nonatomic, readonly) NSString *code;
@property (copy, nonatomic, readonly) CheatType type;

- (nullable instancetype)initWithCode:(NSString *)code type:(CheatType)type;

- (instancetype)init NS_UNAVAILABLE;

@end

@implementation GBCCheat

- (instancetype)initWithCode:(NSString *)code type:(CheatType)type
{
    if (([type isEqualToString:@"GameGenie"] && code.length != 11) || ([type isEqualToString:@"GameShark"] && code.length != 8))
    {
        return nil;
    }
    
    NSMutableCharacterSet *legalCharactersSet = [NSMutableCharacterSet hexadecimalCharacterSet];
    if ([type isEqualToString:@"GameGenie"])
    {
        [legalCharactersSet addCharactersInString:@"-"];
    }
    
    if ([code rangeOfCharacterFromSet:[legalCharactersSet invertedSet]].location != NSNotFound)
    {
        return nil;
    }
    
    self = [super init];
    if (self)
    {
        _code = [code copy];
        _type = [type copy];
    }
    
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[GBCCheat class]])
    {
        return NO;
    }
    
    GBCCheat *cheat = (GBCCheat *)object;
    return [self.code isEqualToString:cheat.code] && [self.type isEqualToString:cheat.type];
}

- (NSUInteger)hash
{
    return [self.code hash] ^ [self.type hash];
}

@end

@interface GBCEmulatorBridge () <MANCEmulatorBase>

@property (nonatomic, copy, nullable, readwrite) NSURL *gameURL;
@property (nonatomic, copy, nonnull, readonly) NSURL *gameSaveDirectory;

@property (nonatomic, assign, readonly) std::shared_ptr<gambatte::GB> gambatte;
@property (nonatomic, assign, readonly) std::shared_ptr<GBCInputGetter> inputGetter;

@property (nonatomic, readonly) NSMutableSet<GBCCheat *> *cheats;

@end

@implementation GBCEmulatorBridge
@synthesize audioRenderer = _audioRenderer;
@synthesize videoRenderer = _videoRenderer;
@synthesize saveUpdateHandler = _saveUpdateHandler;

+ (instancetype)sharedBridge
{
    static GBCEmulatorBridge *_emulatorBridge = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _emulatorBridge = [[self alloc] init];
    });
    
    return _emulatorBridge;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _gameSaveDirectory = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
        
        std::shared_ptr<GBCInputGetter> inputGetter(new GBCInputGetter());
        _inputGetter = inputGetter;
        
        std::shared_ptr<gambatte::GB> gambatte(new gambatte::GB());
        gambatte->setInputGetter(inputGetter.get());
        gambatte->setSaveDir(_gameSaveDirectory.fileSystemRepresentation);
        _gambatte = gambatte;
        
        _cheats = [NSMutableSet set];
    }
    
    return self;
}

#pragma mark - Emulation State -

- (void)startWithGameURL:(NSURL *)gameURL
{
    self.gameURL = gameURL;
    
    gambatte::LoadRes result = self.gambatte->load(gameURL.fileSystemRepresentation, gambatte::GB::MULTICART_COMPAT);
    NSLog(@"Started Gambatte with result: %@", @(result));
}

- (void)stop
{
    self.gambatte->reset();
}

- (void)pause
{
    
}

- (void)resume
{
    
}

#pragma mark - Game Loop -

- (void)runFrameAndProcessVideo:(BOOL)processVideo
{
    size_t samplesCount = 35112;
    
    // Each audio frame = 2 16-bit channel frames (32-bits total per audio frame).
    // Additionally, Gambatte may return up to 2064 audio samples more than requested, so we need to add 2064 to the requested audioBuffer size.
    gambatte::uint_least32_t audioBuffer[samplesCount + 2064];
    size_t samples = samplesCount;
    
    while (self.gambatte->runFor((gambatte::uint_least32_t *)self.videoRenderer.videoBuffer, 160, audioBuffer, samples) == -1)
    {
        [self.audioRenderer.audioBuffer writeBuffer:(uint8_t *)audioBuffer size:samples * 4];
        
        samples = samplesCount;
    }
    
    [self.audioRenderer.audioBuffer writeBuffer:(uint8_t *)audioBuffer size:samples * 4];
    
    if (processVideo)
    {
        [self.videoRenderer processFrame];
    }
}

#pragma mark - Inputs -

- (void)activateInput:(NSInteger)input value:(double)value playerIndex:(NSInteger)playerIndex
{
    self.inputGetter->activateInput((unsigned)input);
}

- (void)deactivateInput:(NSInteger)input playerIndex:(NSInteger)playerIndex
{
    self.inputGetter->deactivateInput((unsigned)input);
}

- (void)resetInputs
{
    self.inputGetter->resetInputs();
}

#pragma mark - Save States -

- (void)saveSaveStateToURL:(NSURL *)URL
{
    self.gambatte->saveState(NULL, 0, URL.fileSystemRepresentation);
}

- (void)loadSaveStateFromURL:(NSURL *)URL
{
    self.gambatte->loadState(URL.fileSystemRepresentation);
}

#pragma mark - Game Saves -

- (void)saveGameSaveToURL:(NSURL *)URL
{
    // Cannot directly set the URL for saving game saves, so we save it to the temporary directory and then move it to the correct place.
    
    self.gambatte->saveSavedata();
    
    NSString *gameFilename = self.gameURL.lastPathComponent.stringByDeletingPathExtension;
    NSURL *temporarySaveURL = [self.gameSaveDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sav", gameFilename]];
    
    if ([self safelyCopyFileAtURL:temporarySaveURL toURL:URL])
    {
        NSURL *rtcURL = [[URL URLByDeletingPathExtension] URLByAppendingPathExtension:@"rtc"];
        NSURL *temporaryRTCURL = [self.gameSaveDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.rtc", gameFilename]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryRTCURL.path])
        {
            [self safelyCopyFileAtURL:temporaryRTCURL toURL:rtcURL];
        }
    }
}

- (void)loadGameSaveFromURL:(NSURL *)URL
{
    NSString *gameFilename = self.gameURL.lastPathComponent.stringByDeletingPathExtension;
    NSURL *temporarySaveURL = [self.gameSaveDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sav", gameFilename]];
    
    if ([self safelyCopyFileAtURL:URL toURL:temporarySaveURL])
    {
        NSURL *rtcURL = [[URL URLByDeletingPathExtension] URLByAppendingPathExtension:@"rtc"];
        NSURL *temporaryRTCURL = [self.gameSaveDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.rtc", gameFilename]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:rtcURL.path])
        {
            [self safelyCopyFileAtURL:rtcURL toURL:temporaryRTCURL];
        }
    }
    
    // Hacky pointer manipulation to obtain the underlying CPU struct, then explicitly call loadSavedata().
    gambatte::CPU *cpu = (gambatte::CPU *)self.gambatte->p_;
    (*cpu).loadSavedata();
}

#pragma mark - Cheats -

- (BOOL)addCheatCode:(NSString *)cheatCode type:(CheatType)type
{
    NSArray<NSString *> *codes = [cheatCode componentsSeparatedByString:@"\n"];
    for (NSString *code in codes)
    {
        GBCCheat *cheat = [[GBCCheat alloc] initWithCode:code type:type];
        if (cheat == nil)
        {
            return NO;
        }
        
        [self.cheats addObject:cheat];
    }
    
    return YES;
}

- (void)resetCheats
{
    [self.cheats removeAllObjects];
    
    self.gambatte->setGameGenie("");
    self.gambatte->setGameShark("");
}

- (void)updateCheats
{
    NSMutableString *gameGenieCodes = [NSMutableString string];
    NSMutableString *gameSharkCodes = [NSMutableString string];
    
    for (GBCCheat *cheat in self.cheats.copy)
    {
        NSMutableString *codes = nil;
        
        if ([cheat.type isEqualToString:@"GameGenie"])
        {
            codes = gameGenieCodes;
        }
        else if ([cheat.type isEqualToString:@"GameShark"])
        {
            codes = gameSharkCodes;
        }
        
        [codes appendString:cheat.code];
        [codes appendString:@";"];
    }
    
    self.gambatte->setGameGenie([gameGenieCodes UTF8String]);
    self.gambatte->setGameShark([gameSharkCodes UTF8String]);
}

#pragma mark - Private -

- (BOOL)safelyCopyFileAtURL:(NSURL *)URL toURL:(NSURL *)destinationURL
{
    NSError *error = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:destinationURL.path])
    {
        if (![[NSFileManager defaultManager] removeItemAtPath:destinationURL.path error:&error])
        {
            NSLog(@"%@", error);
            return NO;
        }
    }
    
    // Copy saves to ensure data is never lost.
    if (![[NSFileManager defaultManager] copyItemAtURL:URL toURL:destinationURL error:&error])
    {
        NSLog(@"%@", error);
        return NO;
    }
    
    return YES;
}

#pragma mark - Getters/Setters -

- (NSTimeInterval)frameDuration
{
    return (1.0 / 60.0);
}

@end
