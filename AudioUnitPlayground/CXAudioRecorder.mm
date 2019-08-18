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

#define kInputElement 1
#define kOutputElement 0
//每个element包含input和output scope

static OSStatus recordingCallback(void *                            inRefCon,
                                  AudioUnitRenderActionFlags *    ioActionFlags,
                                  const AudioTimeStamp *            inTimeStamp,
                                  UInt32                            inBusNumber,
                                  UInt32                            inNumberFrames,
                                  AudioBufferList * __nullable    ioData) {
    return noErr;
}

static OSStatus playbackCallback(void *                            inRefCon,
                                  AudioUnitRenderActionFlags *    ioActionFlags,
                                  const AudioTimeStamp *            inTimeStamp,
                                  UInt32                            inBusNumber,
                                  UInt32                            inNumberFrames,
                                  AudioBufferList * __nullable    ioData) {
    return noErr;
}

class InAudioRecorder {
    AudioComponentInstance componentInstance;
    NSUInteger spRate;
    NSUInteger chnlNum;
    NSUInteger bytesPerSp;
    
    void setupMicrophoneStream() {
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
        //element id: 输入元素 标号为1
        checkStatus(AudioUnitSetProperty(componentInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputElement, &flagOne, sizeof(flagOne)));
        checkStatus(AudioUnitSetProperty(componentInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, kOutputElement, &flagOne, sizeof(flagOne)));

        AudioStreamBasicDescription audioStrmDesc = audioStreamDescriptionConfig();
        checkStatus(AudioUnitSetProperty(componentInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, kOutputElement, &audioStrmDesc, sizeof(audioStrmDesc)));
        checkStatus(AudioUnitSetProperty(componentInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kInputElement, &audioStrmDesc, sizeof(audioStrmDesc)));

        //采集回调 callback
        AURenderCallbackStruct callbackStruct;
        callbackStruct.inputProc = recordingCallback;
        callbackStruct.inputProcRefCon = this;

        checkStatus(AudioUnitSetProperty(componentInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, kInputElement, &callbackStruct, sizeof(callbackStruct)));

        //给播放器使用，播放器调用回调方法去获取数据
        callbackStruct.inputProc = playbackCallback;
        callbackStruct.inputProcRefCon = this;
        checkStatus(AudioUnitSetProperty(componentInstance, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, kOutputElement, &callbackStruct, sizeof(callbackStruct)));
    }

    AudioStreamBasicDescription audioStreamDescriptionConfig() {
        
        AudioStreamBasicDescription strmDesc;
        memset(&strmDesc, 0, sizeof(strmDesc));

        strmDesc.mSampleRate = spRate; //44100
        strmDesc.mFormatID = kAudioFormatLinearPCM;
        strmDesc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        strmDesc.mFramesPerPacket = 1;
        strmDesc.mChannelsPerFrame = (UInt32)chnlNum; //单双声道
        strmDesc.mBitsPerChannel = 16;
        strmDesc.mBytesPerPacket = (UInt32)(16 * chnlNum * strmDesc.mFramesPerPacket / 8); //1 or 2 or ..
        strmDesc.mBytesPerFrame = (UInt32)(chnlNum * 16 / 8);
        return strmDesc;
    }

    void checkStatus(OSStatus status) {
        if (status != noErr) {
            printf("Error: %d\n", status);
        }
    }

public:
    InAudioRecorder(NSUInteger sampleRate, NSUInteger channelNum, NSUInteger bytesPerSample) : spRate(sampleRate), chnlNum(channelNum), bytesPerSp(bytesPerSample) {
        //todo:AudioSession去处理蓝牙连接, 播放互斥

        setupMicrophoneStream();
    }

    ~InAudioRecorder() {
        AudioOutputUnitStop(componentInstance);
        AudioComponentInstanceDispose(componentInstance);
    }
};


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
