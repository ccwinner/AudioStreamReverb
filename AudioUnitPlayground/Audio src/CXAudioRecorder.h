//
//  CXAudioRecorder.h
//  AudioUnitPlayground
//
//  Created by chenxiao on 2019/8/16.
//  Copyright © 2019 陈霄. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CXAudioRecorder : NSObject
@property (nonatomic, assign, readonly) NSUInteger channelNumber;
@property (nonatomic, assign, readonly) NSUInteger sampleRate;

@property (nonatomic, copy) void (^audioRecordCallback)(AudioBuffer audioBuffer, NSUInteger sampleRate, uint64_t timestampMs);

+ (instancetype)recorder;
- (void)configSampleRate:(NSUInteger)sampleRate channelNumber:(NSUInteger)channelNumber bytesPerSample:(NSUInteger)bytesPerSample;
- (void)startAudioRecord;
- (void)stopAudioRecord;

@end

NS_ASSUME_NONNULL_END
