//
//  CXAudioProcessManager.m
//  AudioUnitPlayground
//
//  Created by chenxiao on 2019/9/11.
//  Copyright © 2019 陈霄. All rights reserved.
//

#import "CXAudioProcessManager.h"
#import "AudioUnitDescriptionFactory.h"
#include <mutex>
#import "AudioHelperFunctions.h"

using namespace CXAudio;

@interface CXAudioProcessManager () {
    AUGraph auGraph;
}
@property (nonatomic, assign) double graphSampleRate;
@end

@implementation CXAudioProcessManager

+ (instancetype)defaultManager {
    std::once_flag flag;
    static CXAudioProcessManager *_instance = nil;
    std::call_once(flag, [](){
        _instance = [CXAudioProcessManager new];
    });
    return _instance;
}

- (void)requestForPermission:(void (^)(BOOL granted))completion {
    [[AVAudioSession sharedInstance] requestRecordPermission:completion];
}

- (void)constructGraph {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setPreferredSampleRate:44100. error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    self.graphSampleRate = [[AVAudioSession sharedInstance] sampleRate];
    
    AUGraph graph;
    checkStatus(NewAUGraph(&graph), "error on new augraph");
    
    AUNode reverbNode;
    AudioComponentDescription reverbDesc = AudioUnitDescriptionFactory::unitDescriptionFor(DescriptionType::Reverb);
    checkStatus(AUGraphAddNode(graph, &reverbDesc, &reverbNode), "error on add reverb node");

    AUNode ioNode;
    AudioComponentDescription ioDesc = AudioUnitDescriptionFactory::unitDescriptionFor(DescriptionType::io);
    checkStatus(AUGraphAddNode(graph, &ioDesc, &ioNode), "error on add io node");

    checkStatus(AUGraphOpen(graph), "error on open graph");
    
    AudioUnit reverbUnit;
    checkStatus(AUGraphNodeInfo(graph, reverbNode, &reverbDesc, &reverbUnit), "error on get reverb unit");
    AudioUnit ioUnit;
    checkStatus(AUGraphNodeInfo(graph, ioNode, &ioDesc, &ioUnit), "error on get io unit");

    //给混响音效 io setProperty
    AudioStreamBasicDescription asbd;
    bzero(&asbd, sizeof(asbd));
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mSampleRate = self.graphSampleRate;
    asbd.mChannelsPerFrame = 1;
    asbd.mFramesPerPacket = 1;
    asbd.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    asbd.mBitsPerChannel = 8 * 2; //bytePerSample = 2
    asbd.mBytesPerFrame = asbd.mBitsPerChannel / 8 * asbd.mChannelsPerFrame;
    asbd.mBytesPerPacket = asbd.mBytesPerFrame * asbd.mFramesPerPacket;

    UInt32 maxFPS = 4096;
    checkStatus(AudioUnitSetProperty(ioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, sizeof(maxFPS)), "error on set prop maxim f/slice iounit");
    checkStatus(AudioUnitSetProperty(reverbUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, sizeof(maxFPS)), "error on set prop maxim f/slice revrbunit")
    ;

    [self setupStreamFormatForUnit:&reverbUnit elementOfInputScope:0 elementOfOutputScope:0 descption:&asbd];
    [self setupStreamFormatForUnit:&ioUnit elementOfInputScope:1 elementOfOutputScope:0 descption:&asbd];

    AUGraphClearConnections(graph);
    //remoteIO的input是麦克风 注意!
    checkStatus(AUGraphConnectNodeInput(graph, reverbNode, 0, ioNode, 0), "error on connect reverb to ioNode");
    //开启采集
    UInt32 flag = 1;
    checkStatus(AudioUnitSetProperty(ioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, sizeof(flag)), "error on enable record IO");
    //参考这个地址吧 https://www.jianshu.com/p/f8bb0cc1075e
    
    
//    checkStatus(AudioUnitSetProperty(ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &asbd, sizeof(asbd)), "error in set streamFormat");
    
//    checkStatus(AudioUnitSetProperty(reverbUnit,
//                                  kAudioUnitProperty_StreamFormat,
//                                  kAudioUnitScope_Input, 0, asbd, sizeof(AudioStreamBasicDescription)),
//             "kAudioUnitProperty_StreamFormat kAudioUnitScope_Input err");
//
//    checkStatus(AudioUnitSetProperty(reverbUnit,
//                                  kAudioUnitProperty_StreamFormat,
//                                  kAudioUnitScope_Output, 0, asbd, sizeof(AudioStreamBasicDescription)),
//             "kAudioUnitProperty_StreamFormat kAudioUnitScope_Output err");
//
//    // Set audio unit maximum frames per slice to max frames.
//    checkStatus(AudioUnitSetProperty(reverbUnit,
//                                  kAudioUnitProperty_MaximumFramesPerSlice,
//                                  kAudioUnitScope_Global, 0, &maxFrame, (UInt32)sizeof(UInt32)),
//             "set kAudioUnitProperty_MaximumFramesPerSlice err");
    
}

- (void)setupStreamFormatForUnit:(AudioUnit *)unit elementOfInputScope:(int)inputbus elementOfOutputScope:(int)outputbus descption:(AudioStreamBasicDescription *)descption {
    OSStatus status = noErr;
    UInt32 size = sizeof(AudioStreamBasicDescription);
    
    status = AudioUnitSetProperty(*unit, kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input, inputbus, descption, size);
    checkStatus(status, "error on streamformat inputScope inputbus");
    if (noErr == status)
        status = AudioUnitSetProperty(*unit, kAudioUnitProperty_StreamFormat,
                                      kAudioUnitScope_Output, outputbus, descption, size);
    else
        checkStatus(status, "error on streamformat outputScope outputbus");
}


@end
