//
//  LLTestMoveTableViewController.m
//  LLMoveTableView
//
//  Created by cwli on 16/3/5.
//  Copyright © 2016年 lichengwu. All rights reserved.
//

#import "LLTestMoveTableViewController.h"
#import "LLMoveAbleTableView.h"

typedef NS_ENUM(NSInteger,LLMoveType){
    LLMoveTypeDisEnable = 0,
    LLMoveTypeEnable = 1
};


@interface LLMoveData : NSObject

@property (nonatomic, copy) NSString *moveName;
@property (nonatomic, copy) NSNumber *moveID;
@property (nonatomic, assign) LLMoveType moveType;


- (instancetype)initWithIndex:(NSInteger)index;

@end

@implementation LLMoveData

- (instancetype)initWithIndex:(NSInteger)index {
    self = [super init];
    if (self) {
        _moveName = [NSString stringWithFormat:@"move test ^-^ index = %ld",index];
        _moveID = [NSNumber numberWithInteger:index];
        if (index > 7) {
            _moveType = LLMoveTypeDisEnable;
        } else _moveType = LLMoveTypeEnable;
    }
    return self;
}

@end

@interface LLTestMoveTableViewController ()<LLMoveAbleTableViewDataSource,LLMoveAbleTableViewDelegate>

@property (nonatomic, strong) LLMoveAbleTableView *moveTableView;
@property (nonatomic, strong) NSMutableArray<LLMoveData *> *moveDatas;

@end

@implementation LLTestMoveTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"MoveTableView";
    
    for (NSInteger i = 0; i < 10; i++) {
        LLMoveData *move = [[LLMoveData alloc] initWithIndex:i];
        [self.moveDatas addObject:move];
    }
    
    [self.view addSubview:self.moveTableView];
    [self.moveTableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (LLMoveAbleTableView *)moveTableView {
    if (nil  == _moveTableView) {
        _moveTableView  = [[LLMoveAbleTableView alloc] initWithFrame:self.view.bounds
                                                               style:UITableViewStylePlain];
        _moveTableView.delegate = self;
        _moveTableView.dataSource = self;
    }
    return _moveTableView;
}

- (NSMutableArray *)moveDatas {
    if (nil == _moveDatas) {
        _moveDatas = [[NSMutableArray alloc] init];
    }
    return _moveDatas;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.moveDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellDentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellDentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellDentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textLabel.text = [self.moveDatas objectAtIndex:indexPath.row].moveName;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 70.f;
}

#pragma mark - FMMoveableTableViewDelegate
- (NSIndexPath *)moveableTableView:(LLMoveAbleTableView *)tableView
targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
               toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath{
    LLMoveData *move = [self.moveDatas objectAtIndex:proposedDestinationIndexPath.row];
    if (move.moveType  == LLMoveTypeDisEnable) {
        return sourceIndexPath;
    } else {
        return proposedDestinationIndexPath;
    }
}

- (BOOL)moveableTableView:(LLMoveAbleTableView *)tableView shouldMoveRowAtIndexPath:(NSIndexPath *)indexPath{
    LLMoveData *move = [self.moveDatas objectAtIndex:indexPath.row];
    NSAssert(move, @"cardModel is nil");
    return move.moveType == LLMoveTypeEnable;
}

- (void)moveableTableView:(LLMoveAbleTableView *)tableView didMoveRowFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    LLMoveData *move = [self.moveDatas objectAtIndex:fromIndexPath.row];
    [self.moveDatas removeObjectAtIndex:fromIndexPath.row];
    [self.moveDatas insertObject:move atIndex:toIndexPath.row];
}

- (void)didEndMoveableTableView:(LLMoveAbleTableView *)tableView{
    if (tableView){
        [self.moveTableView reloadData];    
    }
}



@end
