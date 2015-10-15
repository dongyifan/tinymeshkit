//
//  MeshViewController.m
//  GemGallery
//
//  Created by DongYifan on 10/15/15.
//  Copyright © 2015 vanille. All rights reserved.
//

#import "MeshViewController.h"
#import "TinyMeshView.h"

@interface MeshViewController ()

@end

@implementation MeshViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //NSString * path1 = [[NSBundle mainBundle]pathForResource:@"model/tektas_6li/tektas_6li" ofType:@"dae"];
    TinyMeshView * meshView = [[TinyMeshView alloc] initWithFrame:self.view.bounds modelPath:self.modelPath];
    [self.view addSubview:meshView];
    
   

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
