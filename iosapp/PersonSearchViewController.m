//
//  PersonSearchViewController.m
//  iosapp
//
//  Created by chenhaoxiang on 12/26/14.
//  Copyright (c) 2014 oschina. All rights reserved.
//

#import "PersonSearchViewController.h"
#import "PeopleTableViewController.h"

@interface PersonSearchViewController () <UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) PeopleTableViewController *resultsTableVC;

@end

@implementation PersonSearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"找人";
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancelButtonClicked)];
    
    [self initSubviews];
    [self setAutoLayout];
}

- (void)cancelButtonClicked
{
    [_searchBar resignFirstResponder];
    
    if (self.navigationController.viewControllers.count <= 1) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (_searchBar.text.length == 0) {return;}
    
    [searchBar resignFirstResponder];
    
    _resultsTableVC.queryString = _searchBar.text;
    [_resultsTableVC refresh];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    [searchBar resignFirstResponder];
}


- (void)initSubviews
{
    _searchBar = [UISearchBar new];
    _searchBar.placeholder = @"输入用户昵称";
    _searchBar.delegate = self;
    [self.view addSubview:_searchBar];
    [_searchBar becomeFirstResponder];
    
    _resultsTableVC = [PeopleTableViewController new];
    [self addChildViewController:_resultsTableVC];
    [self.view addSubview:_resultsTableVC.tableView];
}

- (void)setAutoLayout
{
    for (UIView *view in self.view.subviews) {view.translatesAutoresizingMaskIntoConstraints = NO;}
    NSDictionary *views = @{@"_searchBar": _searchBar, @"resultsTable": _resultsTableVC.tableView};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_searchBar]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_searchBar][resultsTable]|"
                                                                      options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight
                                                                      metrics:nil
                                                                        views:views]];
}



@end
