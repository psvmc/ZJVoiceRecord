//
//  VoiceRecordTableViewCell.h
//  ZJVoiceRecord
//
//  Created by 张剑 on 16/4/5.
//  Copyright © 2016年 PSVMC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VoiceRecordTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *topImageView;
- (void)setImageByVoiceVolume:(int) volume;
@end
