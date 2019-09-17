//
//  AudioUnitFactory.cpp
//  AudioUnitPlayground
//
//  Created by chenxiao on 2019/9/11.
//  Copyright © 2019 陈霄. All rights reserved.
//

#include "AudioUnitDescriptionFactory.h"

using namespace CXAudio;

AudioComponentDescription AudioUnitDescriptionFactory :: unitDescriptionFor(DescriptionType type) {
    AudioComponentDescription desc;
    switch (type) {
        case DescriptionType::Reverb:
            desc.componentType = kAudioUnitType_Effect;
            desc.componentSubType = kAudioUnitSubType_Reverb2;
            desc.componentManufacturer = kAudioUnitManufacturer_Apple;
            desc.componentFlags = 0;
            desc.componentFlagsMask = 0;
            break;
        case DescriptionType::io:
            desc.componentType = kAudioUnitType_Output;
            desc.componentSubType = kAudioUnitSubType_RemoteIO;
            desc.componentManufacturer = kAudioUnitManufacturer_Apple;
            desc.componentFlags = 0;
            desc.componentFlagsMask = 0;
            break;
        case DescriptionType::output:
            desc.componentType = kAudioUnitType_Output;
            desc.componentSubType = kAudioUnitSubType_GenericOutput;
            desc.componentManufacturer = kAudioUnitManufacturer_Apple;
            desc.componentFlags = 0;
            desc.componentFlagsMask = 0;
            break;
        default:
            break;
    }
    return desc;
}


