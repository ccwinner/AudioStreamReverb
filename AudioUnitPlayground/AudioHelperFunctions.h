//
//  CXAudioHelperFunctions.h
//  AudioUnitPlayground
//
//  Created by chenxiao on 2019/9/16.
//  Copyright © 2019 陈霄. All rights reserved.
//

#ifndef AudioHelperFunctions_h
#define AudioHelperFunctions_h
#import <Foundation/Foundation.h>

static void checkStatus(OSStatus status, const char *msg) {
    if (status != noErr) {
        char fourCC[16];
        *(UInt32 *)fourCC = CFSwapInt32HostToBig(status);
        fourCC[4] = '\0';
        if (isprint(fourCC[0]) && isprint(fourCC[1]) &&
            isprint(fourCC[2]) && isprint(fourCC[4])) {
            printf("%s, %s\n", msg, fourCC);
        } else {
            printf("%s, %d\n", msg, status);
        }
        std::terminate();
    }
}

#endif /* CXAudioHelperFunctions_h */
