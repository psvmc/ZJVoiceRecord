//
//  ViewController.m
//  ZJVoiceRecord
//
//  Created by 张剑 on 16/4/4.
//  Copyright © 2016年 PSVMC. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "VoiceRecordTableViewCell.h"
#import "EMVoiceConverter.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *voiceRecordButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *playAmrButton;
@property (weak, nonatomic) IBOutlet UILabel *filePathLabel;
@property (weak, nonatomic) IBOutlet UILabel *voiceLengthLabel;

@end

@implementation ViewController

NSURL *recordedTmpFile;
AVAudioRecorder *recorder;
NSError *error;
VoiceRecordTableViewCell *voiceRecordView;

- (void)viewDidLoad {
    [super viewDidLoad];
    [_voiceRecordButton addTarget:self action:@selector(voiceButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [_voiceRecordButton addTarget:self action:@selector(voiceButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [_voiceRecordButton addTarget:self action:@selector(voiceButtonTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    
    [_playButton addTarget:self action:@selector(playButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [_playAmrButton addTarget:self action:@selector(playAmrButtonTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    voiceRecordView = [[NSBundle mainBundle]loadNibNamed:@"VoiceRecordTableViewCell" owner:self options:nil].firstObject;
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    voiceRecordView.frame = CGRectMake((screenWidth-120)/2, (screenHeight-140)/2, 120, 140);
    voiceRecordView.hidden = YES;
    [self.view addSubview:voiceRecordView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
 
}

- (void)voiceButtonTouchDown:(UIButton *) button{
    voiceRecordView.hidden = NO;
    NSLog(@"开始录音");
    if (![self.audioRecorder isRecording]) {
        [self setAudioSession];
        [self.audioRecorder record];//首次使用应用时如果调用record方法会询问用户是否允许使用麦克风
        self.timer.fireDate=[NSDate distantPast];
    }
}

- (void)voiceButtonTouchUpInside:(UIButton *) button{
    voiceRecordView.hidden = YES;
    [self.audioRecorder stop];
    self.timer.fireDate=[NSDate distantFuture];
    NSLog(@"松开录音按钮");
}

- (void)voiceButtonTouchUpOutside:(UIButton *) button{
    NSLog(@"取消录音");
    voiceRecordView.hidden = YES;
    [self.audioRecorder stop];
    self.timer.fireDate=[NSDate distantFuture];
}

//播放录制的音频文件
- (void)playButtonTouchUpInside:(UIButton *) button{
    recordedTmpFile = [self getSavePath];
    self.audioPlayer = [self myAudioPlayer];
    if (![self.audioPlayer isPlaying]) {
        [self addDistanceNotification];
        [self setAudioSessionPlay];
        [self.audioPlayer play];
        NSLog(@"播放录制的WAV");
    }
}

//播放WAV-->AMR-->WAV文件 ios不支持AMR格式直接播放
- (void)playAmrButtonTouchUpInside:(UIButton *) button{
    recordedTmpFile = [self getSavePath];
    
    //WAV-->AMR
    [EMVoiceConverter wavToAmr:[[self getSavePath] path] amrSavePath:[[self getSavePathAmr] path]];
    NSInteger amrFileSize = [self getFileSize:[[self getSavePathAmr] path]];
    NSLog(@"AMR文件的大小为：%li kb",(long)amrFileSize/1024);
    
    //AMR-->WAV
    [EMVoiceConverter amrToWav:[[self getSavePathAmr] path] wavSavePath:[[self getSavePath] path]];
    NSInteger wavFileSize2 = [self getFileSize:[[self getSavePath] path]];
    NSLog(@"WAV文件的大小为：%li kb",(long)wavFileSize2/1024);
    
    self.audioPlayer = [self myAudioPlayer];
    if (![self.audioPlayer isPlaying]) {
        [self addDistanceNotification];
        [self setAudioSessionPlay];
        [self.audioPlayer play];
        
        NSLog(@"播放AMR转化的WAV");
    }
}

#pragma mark - 获取文件大小
- (NSInteger) getFileSize:(NSString*) path{
    NSFileManager * filemanager = [[NSFileManager alloc]init];
    if([filemanager fileExistsAtPath:path]){
        NSDictionary * attributes = [filemanager attributesOfItemAtPath:path error:nil];
        NSNumber *theFileSize;
        if ( (theFileSize = [attributes objectForKey:NSFileSize]) )
            return  [theFileSize intValue];
        else
            return -1;
    }
    else{
        return -1;
    }
}

#pragma mark - 录音机代理方法
/**
 *  录音完成，录音完成后播放录音
 *
 *  @param recorder 录音机对象
 *  @param flag     是否成功
 */
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"录音完成!");
    _filePathLabel.text = [[self getSavePath] absoluteString];
    float voiceDurationSeconds = [self getVoiceDurationSeconds];
    _voiceLengthLabel.text = [NSString stringWithFormat:@"%.1lf",voiceDurationSeconds];
}


#pragma mark - 播放器代理方法
//播放完毕后取消距离监听
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"播放器播放完毕");
    [self removeDistanceNotification];
}



#pragma mark - 私有方法
/**
 *  设置音频会话
 */
-(void)setAudioSession{
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    //设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
}

/**
 *  设置音频会话
 */
-(void)setAudioSessionPlay{
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
}

/**
 *  取得录音文件保存路径
 *
 *  @return 录音文件路径
 */
-(NSURL *)getSavePath{
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr=[urlStr stringByAppendingPathComponent:@"myrecord.wav"];
    NSURL *url=[NSURL fileURLWithPath:urlStr];
    return url;
}


-(NSURL *)getSavePathAmr{
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr=[urlStr stringByAppendingPathComponent:@"myrecord.amr"];
    NSURL *url=[NSURL fileURLWithPath:urlStr];
    return url;
}

-(float)getVoiceDurationSeconds{
    NSURL * nsurl = [self getSavePath];
  
    AVURLAsset* audioAsset =[AVURLAsset URLAssetWithURL:nsurl options:nil];
    
    CMTime audioDuration = audioAsset.duration;
    
    float audioDurationSeconds =CMTimeGetSeconds(audioDuration);
    return audioDurationSeconds;
}

/**
 *  取得录音文件设置
 *
 *  @return 录音设置
 */
-(NSDictionary *)getAudioSetting{
    NSMutableDictionary *dicM=[NSMutableDictionary dictionary];
    //设置录音格式
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(8000) forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [dicM setObject:@(1) forKey:AVNumberOfChannelsKey];
    //每个采样点位数,分为8、16、24、32
    [dicM setObject:@(16) forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    //....其他设置等
    return dicM;
}

/**
 *  获得录音机对象
 *
 *  @return 录音机对象
 */
-(AVAudioRecorder *)audioRecorder{
    if (!_audioRecorder) {
        NSLog(@"AVAudioRecorder初始化了");
        //创建录音文件保存路径
        NSURL *url=[self getSavePath];
        //创建录音格式设置
        NSDictionary *setting=[self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        _audioRecorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        _audioRecorder.delegate=self;
        _audioRecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}

/**
 *  创建播放器
 *
 *  @return 播放器
 */
-(AVAudioPlayer *)myAudioPlayer{
    NSLog(@"AVAudioPlayer初始化了");

    NSError *error=nil;
    _audioPlayer=[[AVAudioPlayer alloc]initWithContentsOfURL:recordedTmpFile error:&error];
    _audioPlayer.numberOfLoops=0;
    [_audioPlayer prepareToPlay];
    _audioPlayer.delegate = self;
    if (error) {
        NSLog(@"创建播放器过程中发生错误，错误信息：%@",error.localizedDescription);
        return nil;
    }
  
    return _audioPlayer;
}

/**
 *  录音声波监控定制器
 *
 *  @return 定时器
 */
-(NSTimer *)timer{
    if (!_timer) {
        _timer=[NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(audioPowerChange) userInfo:nil repeats:YES];
    }
    return _timer;
}

/**
 *  录音声波状态设置
 */
-(void)audioPowerChange{
    [self.audioRecorder updateMeters];//更新测量值
    float power= [self.audioRecorder averagePowerForChannel:0];//取得第一个通道的音频，注意音频强度范围时-160到0
    CGFloat progress=(1.0/50.0)*(power+60.0);
    [voiceRecordView setImageByVoiceVolume:(int)(progress*10)];
    NSLog(@"音频强度%f",power);
}

/**
 *  添加距离通知
 */
- (void)addDistanceNotification{
    //添加近距离事件监听，添加前先设置为YES，如果设置完后还是NO的读话，说明当前设备没有近距离传感器
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    if ([UIDevice currentDevice].proximityMonitoringEnabled == YES) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorStateChange:)name:UIDeviceProximityStateDidChangeNotification object:nil];
    }
}

/**
 *  删除距离通知
 */
- (void)removeDistanceNotification{
    //添加近距离事件监听，添加前先设置为YES，如果设置完后还是NO的读话，说明当前设备没有近距离传感器
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    if ([UIDevice currentDevice].proximityMonitoringEnabled == YES) {
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
    }
}


#pragma mark - 处理近距离监听触发事件
- (void)sensorStateChange:(NSNotificationCenter *)notification;
{
    //如果此时手机靠近面部放在耳朵旁，那么声音将通过听筒输出，并将屏幕变暗（省电啊）
    if ([[UIDevice currentDevice] proximityState] == YES)//传感器已启动前提条件下，如果用户接近 近距离传感器，此时属性值为YES
    {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        
    }else
    {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}

@end
