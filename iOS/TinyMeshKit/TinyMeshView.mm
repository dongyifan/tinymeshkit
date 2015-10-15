//
//  TinyMeshView.m
//  GemGallery
//
//  Created by DongYifan on 10/14/15.
//  Copyright © 2015 vanille. All rights reserved.
//

#import "TinyMeshView.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#include <Mesh.h>
#include <array>

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_TEXTURE,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

@interface TinyMeshView () {
    
    CGSize viewSize_;
    std::array<float, 2> rotate;
    std::array<GLint, NUM_UNIFORMS> uniforms;
    
    GLuint _program;
    
    Mesh mesh;
}

@property (nonatomic, strong) NSData * modelContent;
@property (nonatomic, strong) NSString * modelPath;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation TinyMeshView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    //glClearColor(0x16/(GLfloat)0xFF, 0xB6/(GLfloat)0xFF, 0xFA/(GLfloat)0xFF, 1.0f);
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // Render the object again with ES2
    glUseProgram(_program);
    
    mesh.Render(self.bounds.size.width, self.bounds.size.height, uniforms, rotate);
    rotate[0] = 0;
    rotate[1] = 0;
}

-(instancetype) initWithFrame:(CGRect)frame modelPath:(NSString*) path {
    
//    NSString * path1 = [[NSBundle mainBundle]pathForResource:@"model/tektas_6li/tektas_6li" ofType:@"dae"];
//    NSString * path2 = [[NSBundle mainBundle]pathForResource:@"model/Brillant/Brillant" ofType:@"dae"];
//    NSString * path3 = [[NSBundle mainBundle]pathForResource:@"model/diamond/diamond" ofType:@"dae"];
//    NSArray<NSString*> *a = @[path2, path1, path3];
//    NSString * path = a[self.index];
    
    EAGLContext * context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self = [super initWithFrame:frame context:context];
    if (self) {
        NSData * data = [NSData dataWithContentsOfFile:path];
        
        self.modelContent = data;
        self.modelPath = path;
        
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!self.context) {
            NSLog(@"Failed to create ES context");
        }
        
        self.backgroundColor = [UIColor clearColor];
        self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        
        [self setupGL];
        mesh.LoadMesh(self.modelContent.bytes, self.modelContent.length, self.modelPath);
        
        UIPanGestureRecognizer * panGes = [[UIPanGestureRecognizer alloc] initWithTarget: self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGes];
        rotate[0] = 0;
        rotate[1] = 0;
        UIPinchGestureRecognizer * pinchGes = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
        [self addGestureRecognizer:pinchGes];
    }
    return self;
    

}

-(void)handlePan:(UIPanGestureRecognizer*)gestureRecognizer
{
    // TODO: handle velocity
    // CGPoint velocity = [gestureRecognizer velocityInView:self.view];
    // NSLog(@"the velocity is %f, %f", velocity.x, velocity.y);
    
    CGPoint translation = [gestureRecognizer translationInView:self];
    rotate[0] = translation.x * 0.05;
    rotate[1] = translation.y * 0.05;
    [gestureRecognizer setTranslation:CGPointMake(0.0, 0.0) inView:self];
    [self setNeedsDisplay];
    
}

-(void)handlePinch:(UIPinchGestureRecognizer*)gestureRecognizer
{
    NSLog(@"scale change: %f", gestureRecognizer.scale);
    // TODO: handle velocity
    // CGPoint velocity = [gestureRecognizer velocityInView:self.view];
    // NSLog(@"the velocity is %f, %f", velocity.x, velocity.y);
    mesh.normalizedScale = mesh.normalizedScale * gestureRecognizer.scale;
    [gestureRecognizer setScale:1];
    [self setNeedsDisplay];
    
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    glEnable(GL_DEPTH_TEST);

    self.drawableMultisample = GLKViewDrawableMultisample4X;
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"AssimpShader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"AssimpShader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, 0, "position");
    glBindAttribLocation(_program, 2, "normal");
    glBindAttribLocation(_program, 1, "texcoord0");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    uniforms[UNIFORM_DIFFUSECOLOR] = glGetUniformLocation(_program, "diffuseColor");
    uniforms[UNIFORM_S_DIFFERUSE] = glGetUniformLocation(_program, "s_diffuse");
    
    
    int err = glGetError();
    GLint unit = 0;
    glUniform1i(uniforms[UNIFORM_S_DIFFERUSE], unit);
    err = glGetError();
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

@end
