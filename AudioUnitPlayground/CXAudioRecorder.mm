//
//  CXAudioRecorder.m
//  AudioUnitPlayground
//
//  Created by chenxiao on 2019/8/16.
//  Copyright © 2019 陈霄. All rights reserved.
//

#import "CXAudioRecorder.h"
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>
#include <mutex>

using namespace std;

#define kInputIdentifier 1

namespace {
    class InAudioRecorder {
        AudioComponentInstance componentInstance;
        NSUInteger spRate;
        NSUInteger chnlNum;
        NSUInteger bytesPerSp;
    
        void setup() {
            AudioComponentDescription acdesc;
            acdesc.componentType = kAudioUnitScope_Output;
            acdesc.componentSubType = kAudioUnitSubType_RemoteIO;
            acdesc.componentManufacturer = kAudioUnitManufacturer_Apple;
            acdesc.componentFlags = 0;
            acdesc.componentFlagsMask = 0;
            
            OSStatus status = AudioComponentInstanceNew(AudioComponentFindNext(NULL, &acdesc), &componentInstance);
            if (status != noErr) {
                return;
            }
            
            UInt32 flagOne = 1;
            AudioUnitSetProperty(componentInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputIdentifier, &flagOne, sizeof(flagOne));
        }

        AudioStreamBasicDescription audioDescriptionInstance() {
        
            AudioStreamBasicDescription strmDesc;
            memset(&strmDesc, 0, sizeof(strmDesc));
    
            strmDesc.mSampleRate = spRate; //44100
            strmDesc.mFormatID = kAudioFormatLinearPCM;
            strmDesc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
            strmDesc.mBytesPerPacket = (UInt32)bytesPerSp; //1 or 2 or ..
            strmDesc.mChannelsPerFrame = (UInt32)chnlNum; //单双声道

            return strmDesc;
        }
        
        
    public:
        InAudioRecorder(NSUInteger sampleRate, NSUInteger channelNum, NSUInteger bytesPerSample) : spRate(sampleRate), chnlNum(channelNum), bytesPerSp(bytesPerSample) {
            //todo:AudioSession去处理蓝牙连接, 播放互斥
            
            setup();
        }
        
        ~InAudioRecorder() {
            AudioOutputUnitStop(componentInstance);
            AudioComponentInstanceDispose(componentInstance);
        }
    };
}

@interface CXAudioRecorder ()

@end

@implementation CXAudioRecorder

static CXAudioRecorder *static_instance = nil;

+ (instancetype)recorder {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static_instance = [CXAudioRecorder new];
        
    });
    return static_instance;
}

//- (void)set


@end
