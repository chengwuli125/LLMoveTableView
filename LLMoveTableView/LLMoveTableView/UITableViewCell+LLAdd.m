//
//  UITableViewCell+LLAdd.m
//  LLMoveTableView
//
//  Created by cwli on 16/3/5.
//  Copyright © 2016年 lichengwu. All rights reserved.
//

#import "UITableViewCell+LLAdd.h"

@implementation UITableViewCell (LLAdd)

- (void)prepareForMove {
    self.contentView.alpha = 0.1f;
}

@end
