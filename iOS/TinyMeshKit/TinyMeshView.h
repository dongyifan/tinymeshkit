//
//  TinyMeshView.h
//  GemGallery
//
//  Created by DongYifan on 10/14/15.
//  Copyright © 2015 vanille. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface TinyMeshView : GLKView

-(instancetype) initWithFrame:(CGRect)frame modelPath:(NSString*) path;

@property (nonatomic, assign) NSInteger index;


@end
