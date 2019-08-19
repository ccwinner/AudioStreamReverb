//
//  CXAudioRecorder.m
//  AudioUnitPlayground
//
//  Created by chenxiao on 2019/8/16.
//  Copyright © 2019 陈霄. All rights reserved.
//

#import "CXAudioRecorder.h"
#import <AudioUnit/AudioUnit.h>
#include <string>
#include <iostream>
#include <mach/mach_time.h>

using namespace std;

#define kInputElement 1
#define kOutputElement 0

//方法放在定义上头会够不到class的定义。。。。
static OSStatus recordingCallback(void *                            inRefCon,
                  AudioUnitRenderActionFlags *    ioActionFlags,
                  const AudioTimeStamp *            inTimeStamp,
                  UInt32                            inBusNumber,
                  UInt32                            inNumberFrames,
                  AudioBufferList * __nullable    ioData);

class InAudioRecorder {
    AudioComponentInstance componentInstance;
    NSUInteger spRate;
    NSUInteger chnlNum;
    NSUInteger bytesPerSp;
    
    void setupMicrophoneSource() {
        //Remote IO Unit的input部分
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
        checkStatus(AudioUnitSetProperty(componentInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputElement, &flagOne, sizeof(flagOne)), "setProperty_error_enableIO_intputElement");
//        checkStatus(AudioUnitSetProperty(componentInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, kOutputElement, &flagOne, sizeof(flagOne)));

        AudioStreamBasicDescription audioStrmDesc = audioStreamDescriptionConfig();
//        checkStatus(AudioUnitSetProperty(componentInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, kOutputElement, &audioStrmDesc, sizeof(audioStrmDesc)));
        checkStatus(AudioUnitSetProperty(componentInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kInputElement, &audioStrmDesc, sizeof(audioStrmDesc)), "setProperty_error_streamFormat_intputElement");

        //采集回调 callback
        AURenderCallbackStruct callbackStruct;
        callbackStruct.inputProc = recordingCallback;
        callbackStruct.inputProcRefCon = this;

        checkStatus(AudioUnitSetProperty(componentInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, kInputElement, &callbackStruct, sizeof(callbackStruct)), "setProperty_error_inputCallbrk_intputElement");

        //给播放器使用，播放器调用回调方法去获取数据
//        callbackStruct.inputProc = playbackCallback;
//        callbackStruct.inputProcRefCon = this;
//        checkStatus(AudioUnitSetProperty(componentInstance, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, kOutputElement, &callbackStruct, sizeof(callbackStruct)));
        checkStatus(AudioUnitInitialize(componentInstance), "setProperty_error_initialize_componentInstance");
    }

    AudioStreamBasicDescription audioStreamDescriptionConfig() {
        AudioStreamBasicDescription strmDesc;
        memset(&strmDesc, 0, sizeof(strmDesc));
        
        strmDesc.mSampleRate = spRate; //44100
        strmDesc.mFormatID = kAudioFormatLinearPCM;
        strmDesc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        strmDesc.mFramesPerPacket = 1;
        strmDesc.mChannelsPerFrame = (UInt32)chnlNum; //单双声道

        if (bytesPerSp != 0) {
            strmDesc.mBytesPerPacket = (UInt32)bytesPerSp;
            strmDesc.mBytesPerFrame = strmDesc.mBytesPerPacket / strmDesc.mFramesPerPacket;
            strmDesc.mBitsPerChannel = strmDesc.mBytesPerFrame / strmDesc.mChannelsPerFrame * 8;
        } else {
            strmDesc.mBitsPerChannel = 16;
            strmDesc.mBytesPerFrame = (UInt32)(chnlNum * strmDesc.mBitsPerChannel / 8);
            strmDesc.mBytesPerPacket = (UInt32)(strmDesc.mBytesPerFrame * strmDesc.mFramesPerPacket); //1 or 2 or ..
        }
        return strmDesc;
    }

    void checkStatus(OSStatus status, string msg) {
        if (status != noErr) {
            cout<< "Error: " << status << "," << msg << endl;
        }
    }

public:
    InAudioRecorder(NSUInteger sampleRate, NSUInteger channelNum, NSUInteger bytesPerSample) : spRate(sampleRate), chnlNum(channelNum), bytesPerSp(bytesPerSample) {
        //todo:AudioSession去处理蓝牙连接, 播放互斥
        setupMicrophoneSource();
    }

    void startAudioRecord() {
        checkStatus(AudioOutputUnitStart(componentInstance), "start audio record failed");
    }
    
    void stopAudioRecord() {
        AudioOutputUnitStop(componentInstance);
    }
    
    AudioComponentInstance getComponentInstance() {
        return this->componentInstance;
    }
    
    NSUInteger getSampleRate() {
        return this->spRate;
    }

    ~InAudioRecorder() {
        AudioOutputUnitStop(componentInstance);
        AudioComponentInstanceDispose(componentInstance);
    }
};

//每个element包含input和output scope
static OSStatus recordingCallback(void *                            inRefCon,
                                  AudioUnitRenderActionFlags *    ioActionFlags,
                                  const AudioTimeStamp *            inTimeStamp,
                                  UInt32                            inBusNumber,
                                  UInt32                            inNumberFrames,
                                  AudioBufferList * __nullable    ioData) {
    
    InAudioRecorder *ref = static_cast<InAudioRecorder*>(inRefCon);
    if (!ref) {
        //错误处理
        return -1;
    } else {
        static mach_timebase_info_data_t info;
        if (info.denom == 0) {
            mach_timebase_info(&info);
        }
        //todo:可以打点看下ioData有咩有数据
        uint64_t timeStampMs = inTimeStamp->mHostTime * info.numer / info.denom / 1000000.0;
        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        buffer.mNumberChannels = 2;
        
        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = buffer;
        OSStatus fillDataStatus = AudioUnitRender(ref->getComponentInstance(), ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &buffers);
        if (fillDataStatus == noErr && [CXAudioRecorder recorder].audioRecordCallback) {
            [CXAudioRecorder recorder].audioRecordCallback(buffers.mBuffers[0], ref->getSampleRate(), timeStampMs);
        }
        return fillDataStatus;
    }
}

//static OSStatus playbackCallback(void *                            inRefCon,
//                                  AudioUnitRenderActionFlags *    ioActionFlags,
//                                  const AudioTimeStamp *            inTimeStamp,
//                                  UInt32                            inBusNumber,
//                                  UInt32                            inNumberFrames,
//                                  AudioBufferList * __nullable    ioData) {
//    return noErr;
//}

@interface CXAudioRecorder () {
    InAudioRecorder *_builtinAudioRecorder;
}

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

- (void)configSampleRate:(NSUInteger)sampleRate channelNumber:(NSUInteger)channelNumber bytesPerSample:(NSUInteger)bytesPerSample {
    if (_builtinAudioRecorder) {
        delete _builtinAudioRecorder;
    }
    _builtinAudioRecorder = new InAudioRecorder(sampleRate, channelNumber, bytesPerSample);
}

- (void)startAudioRecord {
    _builtinAudioRecorder->startAudioRecord();
}

- (void)stopAudioRecord {
    _builtinAudioRecorder->stopAudioRecord();
}

- (void)dealloc {
    if (_builtinAudioRecorder) {
        delete _builtinAudioRecorder;
    }
}

//- (void)set


@end
