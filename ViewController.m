//
//  ViewController.m
//  TestAudioProj
//
//  Created by Ksenya on 22.02.16.
//  Copyright © 2016 Ksenya. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (nonatomic) AudioUnit audioUnit;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *stringPath = [[NSBundle mainBundle] pathForResource:@"Video_AudioDemo" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:stringPath];
    AVAsset *asset = [AVAsset assetWithURL:url];
    [self getAudioFromVideo:asset withComplition:^(BOOL success, NSString *inputPath) {
        if (success) {
            [self reversePlayAudio:inputPath];
        }
    }];
}

- (void)getAudioFromVideo:(AVAsset *)asset withComplition:(void(^)(BOOL success, NSString *outputPath))completion
{
    __block Float64 assetDuration;
    
    void(^completionBlock) (void) = ^ {
        
        float startTime = 0;
        float endTime = assetDuration;
        
        //Getting Converted Audio File Path
    
        NSString *audioPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"OriginalAudio.m4a"];
    
        //Here is Original Video File Path
        //Get Audio From Original Video
        
        AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
        
        exportSession.outputURL = [NSURL fileURLWithPath:audioPath];
        exportSession.outputFileType = AVFileTypeAppleM4A;
        
        CMTime vocalStartMarker = CMTimeMake((int)(floor(startTime * 100)), 100);
        CMTime vocalEndMarker = CMTimeMake((int)(ceil(endTime * 100)), 100);
        
        CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(vocalStartMarker, vocalEndMarker);
        exportSession.timeRange = exportTimeRange;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:audioPath])
        {
            [[NSFileManager defaultManager] removeItemAtPath:audioPath error:nil];
        }
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if (exportSession.status == AVAssetExportSessionStatusFailed)
            {
                if (completion)
                {
                    completion(NO, nil);
                }
                NSLog(@"failed");
            }
            else if (exportSession.status == AVAssetExportSessionStatusCompleted)
            {
                if (completion)
                {
                    completion(YES, audioPath);
                }
            }
        }];
    };
    
//    NSError *error = nil;
    NSArray *key = @[@"duration"];
//    [asset statusOfValueForKey:@"duration" error:&error];
    
    [asset loadValuesAsynchronouslyForKeys:key completionHandler:^{
        NSError *errorInBlock = nil;
        AVKeyValueStatus playableStatus = [asset statusOfValueForKey:@"duration" error:&errorInBlock];
        
        switch (playableStatus) {
                
            case AVKeyValueStatusLoaded:
            {
                // duration is now known, so we can fetch it without blocking
                assetDuration = CMTimeGetSeconds(asset.duration);
                completionBlock();
                break;
            }
            case AVKeyValueStatusFailed:
            {
                NSLog(@"failed");
                break;
            }
            default:
                break;
        }
    }];
}

- (void)reversePlayAudio:(NSString *)inputPath
{
    OSStatus theErr = noErr;
    UInt64 fileDataSize = 0;
    AudioFileID inputAudioFile;
    AudioStreamBasicDescription theFileFormat;
    UInt32 thePropertySize = sizeof(theFileFormat);
    
    theErr = AudioFileOpenURL((__bridge CFURLRef)[NSURL URLWithString:inputPath], kAudioFileReadPermission, 0, &inputAudioFile);
    
    thePropertySize = sizeof(fileDataSize);
    theErr = AudioFileGetProperty(inputAudioFile, kAudioFilePropertyAudioDataByteCount, &thePropertySize, &fileDataSize);
    
    UInt32 ps = sizeof(AudioStreamBasicDescription) ;
    AudioFileGetProperty(inputAudioFile, kAudioFilePropertyDataFormat, &ps, &theFileFormat);
    
    UInt64 dataSize = fileDataSize;
    void *theData = malloc(dataSize);
    
    // set up output file
    AudioFileID outputAudioFile;
    
    AudioStreamBasicDescription myPCMFormat;
//    UInt32 floatByteSize   = sizeof(float);
//    myPCMFormat.mChannelsPerFrame = 2;
//    myPCMFormat.mBitsPerChannel   = 8 * floatByteSize;
//    myPCMFormat.mBytesPerFrame    = floatByteSize;
//    myPCMFormat.mFramesPerPacket  = 1;
//    myPCMFormat.mBytesPerPacket   = myPCMFormat.mFramesPerPacket * myPCMFormat.mBytesPerFrame;
//    myPCMFormat.mFormatFlags      = kAudioFormatFlagIsFloat|kAudioFormatFlagIsNonInterleaved;
//
//    myPCMFormat.mFormatID         = kAudioFormatLinearPCM;
//    myPCMFormat.mSampleRate       = 44100;
    
//    AudioComponentDescription desc;
//    desc.componentType = kAudioUnitType_Output;
//    desc.componentSubType = kAudioUnitSubType_RemoteIO;
//    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
//    desc.componentFlags = 0;
//    desc.componentFlagsMask = 0;
////
//    AudioComponent defaultOutput = AudioComponentFindNext(NULL, &desc);
//    AudioComponentInstanceNew(defaultOutput ,&_audioUnit);
    
    myPCMFormat.mSampleRate       = 44100;
    myPCMFormat.mFormatID         = kAudioFormatLinearPCM;
    myPCMFormat.mFormatFlags      = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
    myPCMFormat.mChannelsPerFrame = 1;
    myPCMFormat.mFramesPerPacket  = 1;
    myPCMFormat.mBitsPerChannel   = 32;
    myPCMFormat.mBytesPerPacket   = (myPCMFormat.mBitsPerChannel / 8) * myPCMFormat.mChannelsPerFrame;
    myPCMFormat.mBytesPerFrame    = myPCMFormat.mBytesPerPacket;
    
  
    
    NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"ReverseAudio.caf"];
    NSURL *outputURL = [NSURL fileURLWithPath:exportPath];
    
    theErr = AudioFileCreateWithURL((__bridge CFURLRef)outputURL,
                           kAudioFileCAFType,
                           &myPCMFormat,
                           kAudioFileFlags_EraseFile,
                           &outputAudioFile);
    
    
    
//    AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &myPCMFormat, sizeof(myPCMFormat));
    
    //Read data into buffer
    SInt64 readPoint  = dataSize-1;
    UInt64 writePoint = 0;
    
    while(readPoint > 0)
    {
        UInt32 bytesToRead = 2;
        AudioFileReadBytes(inputAudioFile, false, readPoint, &bytesToRead, theData);
        // bytesToRead is now the amount of data actually read
        
        UInt32 bytesToWrite = bytesToRead;
        AudioFileWriteBytes(outputAudioFile, false, writePoint, &bytesToWrite, theData);
        // bytesToWrite is now the amount of data actually written
        // NOTE: You are assuming bytesToWrite == bytesToRead, which is not necessarily true.
        // You should ensure all the data is written before you read again.
        // I'm leaving that up to you.
        
        writePoint += bytesToWrite;
        readPoint -= bytesToRead;
    }
    
    free(theData);
    AudioFileClose(inputAudioFile);
    AudioFileClose(outputAudioFile);
}

@end
