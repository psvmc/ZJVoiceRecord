//
//  VoiceRecordTableViewCell.m
//  ZJVoiceRecord
//
//  Created by 张剑 on 16/4/5.
//  Copyright © 2016年 PSVMC. All rights reserved.
//

#import "VoiceRecordTableViewCell.h"

@implementation VoiceRecordTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.masksToBounds = true;
    self.layer.cornerRadius = 6;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setImageByVoiceVolume:(int) volume{
    if(volume<=1){
        [self topImageView].image = [UIImage imageNamed:@"voice_record01"];
    }else if(volume==2){
        [self topImageView].image = [UIImage imageNamed:@"voice_record02"];
    }else if(volume==3){
        [self topImageView].image = [UIImage imageNamed:@"voice_record03"];
    }else if(volume==4){
        [self topImageView].image = [UIImage imageNamed:@"voice_record04"];
    }else if(volume==5){
        [self topImageView].image = [UIImage imageNamed:@"voice_record05"];
    }else if(volume==6){
        [self topImageView].image = [UIImage imageNamed:@"voice_record06"];
    }else if(volume==7){
        [self topImageView].image = [UIImage imageNamed:@"voice_record07"];
    }else if(volume==8){
        [self topImageView].image = [UIImage imageNamed:@"voice_record08"];
    }else if(volume==9){
        [self topImageView].image = [UIImage imageNamed:@"voice_record09"];
    }else{
        [self topImageView].image = [UIImage imageNamed:@"voice_record10"];
    }
}

@end
