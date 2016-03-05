//
//  LLMoveAbleTableView.h
//  LLMoveTableView
//
//  Created by cwli on 16/3/5.
//  Copyright © 2016年 lichengwu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LLMoveAbleTableView;

@protocol LLMoveAbleTableViewDelegate <NSObject, UITableViewDelegate>

@required

/**
 *  给receiver重新设置目标indexPath的机会
 *
 *  @param tableView                    当前的tableview
 *  @param sourceIndexPath              cell原来的indexPath
 *  @param proposedDestinationIndexPath cell新的indexPath
 *
 *  @return 想要移动到的实际的indexPath，如果不想特殊处理，直接将proposedDestinationIndexPath返回
 */
- (NSIndexPath *)moveableTableView:(LLMoveAbleTableView *)tableView
targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
               toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;

/**
 *  确认是否允许移动指定的cell
 *
 *  @param tableView 当前tableView
 *  @param indexPath 想要移动的cell的indexPath
 *
 *  @return 是否允许移动
 */
- (BOOL)moveableTableView:(LLMoveAbleTableView *)tableView
 shouldMoveRowAtIndexPath:(NSIndexPath *)indexPath;

///**
// *  将要移动指定的cell，暂时取消该方法
// *
// *  @param tableView 当前tableView
// *  @param indexPath 将要移动的cell的indexPath
// */
//- (void)moveableTableView:(FMMoveableTableView *)tableView willMoveRowAtIndexPath:(NSIndexPath *)indexPath;
/**
 *  cell完成移动后会回调此方法，用于对datasource进行相应的排序处理
 *
 *  @param tableView     当前tableview
 *  @param fromIndexPath cell原来的indexPath
 *  @param toIndexPath   cell新的indexPath
 */
- (void)moveableTableView:(LLMoveAbleTableView *)tableView
  didMoveRowFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

/**
 * 已经移动完成
 * @param tableView     当前tableview
 */
- (void)didEndMoveableTableView:(LLMoveAbleTableView *)tableView;


@end

@protocol LLMoveAbleTableViewDataSource <NSObject, UITableViewDataSource>

@end

@interface LLMoveAbleTableView : UITableView

@property (nonatomic, weak) id <LLMoveAbleTableViewDataSource> dataSource;
@property (nonatomic, weak) id <LLMoveAbleTableViewDelegate> delegate;

/**
 *  当前正在移动的cell的indexPath
 */
@property (nonatomic, strong) NSIndexPath *movingIndexPath;

/**
 *  将cell从indexPath移动到newIndexPath. 此接口不受 isCellMoveable 影响
 *
 *  @param indexPath    要移动的cell的初始indexPath
 *  @param newIndexPath 要移动的cell的新indexPath
 *  @warning 一定注意，这里要移动的cell (indexPath处)不能有动画，比如设置deselect的时候animation一定要为NO，否则会导致动画效果截图为空白
 */
- (void)moveRowFromIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;

@end
