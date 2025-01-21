/*

 HOTDOG

 Copyright (c) 2020 Arthur Choung. All rights reserved.

 Email: arthur -at- hotdogpucko.com

 This file is part of HOTDOG.

 HOTDOG is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.

 */

#import "HOTDOG.h"

#ifdef BUILD_FOR_FREEBSD

#include <fcntl.h>
#include <sys/soundcard.h>

#define DEFAULT_AUDIO_DEVICE "/dev/dsp"

@interface AudioOutput : IvarObject
{
    int _fd;

    int _sampleRate;
    int _numberOfChannels;
    int _bitsPerChannel;
}
@end
@implementation AudioOutput
- (id)init
{
    self = [super init];
    if (self) {
        _fd = -1;
    }
    return self;
}

- (void)openAudioWithSampleRate:(int)sampleRate frameCount:(int)frameCount channels:(int)channels bitsPerChannel:(int)bitsPerChannel
{
    int fmt = 0;

    if (bitsPerChannel == 16) {
        fmt = AFMT_S16_LE;
    } else if (bitsPerChannel == 8) {
        fmt = AFMT_S8;
    } else {
NSLog(@"error, %d bits per channel not supported", bitsPerChannel);
        exit(1);
    }

    _sampleRate = sampleRate;
    _numberOfChannels = channels;
    _bitsPerChannel = bitsPerChannel;
    
    _fd = open(DEFAULT_AUDIO_DEVICE, O_WRONLY, 0);
    if (_fd < 0) {
NSLog(@"unable to open audio device '%s", DEFAULT_AUDIO_DEVICE);
        exit(1);
    }

    if (ioctl(_fd, SNDCTL_DSP_SETFMT, &fmt) == -1) {
NSLog(@"unable to set audio format");
        exit(1);
    }

    if (ioctl(_fd, SNDCTL_DSP_CHANNELS, &_numberOfChannels) == -1) {
NSLog(@"unable to set audio channels");
        exit(1);
    }
    if (_numberOfChannels != channels) {
NSLog(@"error, audio device does not support %d channels", channels);
        exit(1);
    }

    if (ioctl(_fd, SNDCTL_DSP_SPEED, &_sampleRate) == -1) {
NSLog(@"unable to set audio sample rate");
        exit(1);
    }
}   

- (void)writeAudio:(uint16_t *)buf frameCount:(int)frameCount
{
    if (_fd < 0) {
        return;
    }
    int len = frameCount * (_bitsPerChannel/8) * _numberOfChannels;
    int n = write(_fd, buf, len);
    if (n != len) {
NSLog(@"unable to write to audio device, frameCount %d result %d", frameCount, n);
    }
}

- (void)closeAudio
{
    if (_fd >= 0) {
        close(_fd);
        _fd = -1;
    }
}
@end

#endif

#ifdef BUILD_FOR_LINUX
@interface AudioOutput : IvarObject
{
    id _aplay;
    int _sampleRate;
    int _numberOfChannels;
    int _bitsPerChannel;
}
@end
@implementation AudioOutput

- (void)openAudioWithSampleRate:(int)sampleRate frameCount:(int)frameCount channels:(int)channels bitsPerChannel:(int)bitsPerChannel
{
    _sampleRate = sampleRate;
    _numberOfChannels = channels;
    _bitsPerChannel = bitsPerChannel;
    
    id cmd = nsarr();
    [cmd addObject:@"aplay"];
    [cmd addObject:@"-t"];
    [cmd addObject:@"raw"];
    [cmd addObject:@"-r"];
    [cmd addObject:nsfmt(@"%d", sampleRate)];
    [cmd addObject:@"-c"];
    [cmd addObject:nsfmt(@"%d", channels)];
    [cmd addObject:@"-f"];
    if (bitsPerChannel == 8) {
        [cmd addObject:@"S8"];
    } else {
        [cmd addObject:@"S16_LE"];
    }
    [cmd addObject:@"-"];
    id aplay = [cmd runCommandAndReturnProcess];
    [self setValue:aplay forKey:@"aplay"];
}   

- (void)writeAudio:(uint16_t *)buffer frameCount:(int)frameCount
{
    [_aplay writeBytes:(unsigned char *)buffer length:_numberOfChannels*(_bitsPerChannel/8)*frameCount];
}

- (void)closeAudio
{
    [self setValue:nil forKey:@"aplay"];
}
@end
#endif

