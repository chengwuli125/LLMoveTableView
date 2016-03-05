//
//  UITableViewCell+LLAdd.h
//  LLMoveTableView
//
//  Created by cwli on 16/3/5.
//  Copyright © 2016年 lichengwu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableViewCell (LLAdd)

/**
 该cell将要进行移动，可在此设置透明度，隐藏一些元素等...
 */
- (void)prepareForMove;

@end
