//
//  AudioUnitFactory.hpp
//  AudioUnitPlayground
//
//  Created by chenxiao on 2019/9/11.
//  Copyright © 2019 陈霄. All rights reserved.
//

#ifndef AudioUnitFactory_hpp
#define AudioUnitFactory_hpp
#import <AVFoundation/AVFoundation.h>
/*
 Generic Output unit
 
 Supports converting to and from linear PCM format; can be used to start and stop a graph.
 
 kAudioUnitType_Output
 kAudioUnitSubType_GenericOutput
 
 
 Remote I/O unit
 
 Connects to device hardware for input, output, or simultaneous input and output.
 
 kAudioUnitType_Output
 kAudioUnitSubType_RemoteIO
 
 */
namespace CXAudio {
    enum class DescriptionType : int {
        Default,
        io,
        Reverb,
        output
    };
}

class AudioUnitDescriptionFactory {

public:
    static AudioComponentDescription unitDescriptionFor(CXAudio::DescriptionType type);
};

#endif /* AudioUnitFactory_hpp */
