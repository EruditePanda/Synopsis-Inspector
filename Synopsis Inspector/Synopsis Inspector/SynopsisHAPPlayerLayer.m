//
//  SynopsisHAPPlayerLayer.m
//  Synopsis Inspector
//
//  Created by vade on 7/24/17.
//  Copyright © 2017 v002. All rights reserved.
//

#import "SynopsisHAPPlayerLayer.h"
#import "SynopsisInspectorMediaCache.h"
#import <OpenGL/gl.h>

@interface SynopsisHAPPlayerLayer ()
{
    CVOpenGLTextureRef currentTextureRef;
    CVOpenGLTextureCacheRef textureCache;
}

@property (readwrite) AVPlayer* player;
@property (readwrite) AVPlayerItemVideoOutput* videoOutput;
@property (nonatomic, readwrite, getter=isReadyForDisplay) BOOL readyForDisplay;

@end

@implementation SynopsisHAPPlayerLayer

- (CGLPixelFormatObj)copyCGLPixelFormatForDisplayMask:(uint32_t)mask
{
    const CGLPixelFormatAttribute attributes[] = {
        kCGLPFAOpenGLProfile, kCGLOGLPVersion_Legacy,
        kCGLPFADoubleBuffer,
        kCGLPFAAccelerated,
        kCGLPFAColorSize, 32,
        kCGLPFADepthSize, 24,
        kCGLPFANoRecovery,
        kCGLPFADisplayMask, mask,
        (CGLPixelFormatAttribute)0,
    };
    
    CGLPixelFormatObj pf;
    GLint npix;
    CGLChoosePixelFormat(attributes, &pf, &npix);
    return pf;
}

- (CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf
{
    CGLContextObj context;
    
//    CGLContextObj shareContext = [SynopsisInspectorMediaCache sharedMediaCache].glContext.CGLContextObj;
    
    CGLCreateContext(pf, NULL, &context);
    
    NSDictionary* cacheAttributes = @{ (NSString*)kCVOpenGLTextureCacheChromaSamplingModeKey : (NSString*)kCVOpenGLTextureCacheChromaSamplingModeBestPerformance};
    
    CVOpenGLTextureCacheCreate(kCFAllocatorDefault,
                               CFBridgingRetain(cacheAttributes),
                               context,
                               pf,
                               NULL,
                               &textureCache);
    
    self.player = [[AVPlayer alloc] init];
    self.player.volume = 0;
    
//    [self.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    return context;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
//    if(object == self.player)
//    {
//        if(self.player.status == AVPlayerStatusReadyToPlay)
//        {
//            NSLog(@"Player Ready to Play");
//            self.readyForDisplay = YES;
//        }
//        else
//        {
//            NSLog(@"Player NOT Ready to Play");
//            self.readyForDisplay = NO;
//        }
//    }
    if([object isKindOfClass:[AVPlayerItem class]])
    {
        AVPlayerItem* item = (AVPlayerItem*) object;
        if(item.status == AVPlayerItemStatusReadyToPlay)
        {
            self.readyForDisplay = YES;
        }
        else
            self.readyForDisplay = NO;
    }
    
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) replacePlayerItemWithItem:(AVPlayerItem*)item
{
    self.readyForDisplay = NO;

    if(currentTextureRef)
    {
        CVOpenGLTextureRelease(currentTextureRef);
        currentTextureRef = NULL;
    }
    
    if(self.player.currentItem)
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];

    [self.player replaceCurrentItemWithPlayerItem:item];
    
    self.videoOutput = (AVPlayerItemVideoOutput*)[item.outputs lastObject];    
}

- (void)drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf
            forLayerTime:(CFTimeInterval)t displayTime:(nullable const CVTimeStamp *)ts
{
    
    if(self.readyForDisplay)
    {
    CGLSetCurrentContext(ctx);

    CMTime time = [self.videoOutput itemTimeForHostTime:t];
    
    if([self.videoOutput hasNewPixelBufferForItemTime:time])
    {
        CVPixelBufferRef currentPixelBuffer = [self.videoOutput copyPixelBufferForItemTime:time itemTimeForDisplay:NULL];
        
        if(currentTextureRef != NULL)
        {
            CVOpenGLTextureRelease(currentTextureRef);
        }

        CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                   textureCache,
                                                   currentPixelBuffer,
                                                   NULL,
                                                   &currentTextureRef);
    }
    
    if(currentTextureRef != NULL)
    {
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        GLfloat texCoords[8];
        
        GLuint texture = CVOpenGLTextureGetName(currentTextureRef);
        GLenum target = CVOpenGLTextureGetTarget(currentTextureRef);
        
        BOOL flipped = CVImageBufferIsFlipped(currentTextureRef);
        
        glEnable(target);
        
        glBindTexture(target, texture);
        
        CVOpenGLTextureGetCleanTexCoords(currentTextureRef,
                                         (!flipped ? &texCoords[6] : &texCoords[0]), // lower left
                                         (!flipped ? &texCoords[4] : &texCoords[2]), // lower right
                                         (!flipped ? &texCoords[2] : &texCoords[4]), // upper right
                                         (!flipped ? &texCoords[0] : &texCoords[6])  // upper left
                                         );
        
        GLfloat width = texCoords[2] - texCoords[0];
        GLfloat height = texCoords[7] - texCoords[1];
        
        GLfloat _width = self.frame.size.width;
        GLfloat _height = self.frame.size.height;
        GLfloat _ox = self.bounds.origin.x;
        GLfloat _oy = self.bounds.origin.y;
        
        GLfloat _bwidth = self.bounds.size.width;
        GLfloat _bheight = self.bounds.size.height;
        
        GLfloat xRatio = width / _width;
        GLfloat yRatio = height / _height;
        GLfloat xoffset = _ox * xRatio;
        GLfloat yoffset = _oy * yRatio;
        GLfloat xinset = ((GLfloat)_width - (_ox + _bwidth)) * xRatio;
        GLfloat yinset = ((GLfloat)_height - (_oy + _bheight)) * yRatio;
        
        texCoords[0] += xoffset;
        texCoords[1] += yoffset;
        texCoords[2] -= xinset;
        texCoords[3] += yoffset;
        texCoords[4] -= xinset;
        texCoords[5] -= yinset;
        texCoords[6] += xoffset;
        texCoords[7] -= yinset;
        
        glColor4f(1.0, 1.0, 1.0, 1.0);
        
        CGSize displaySize = CVImageBufferGetDisplaySize(currentTextureRef);
        
        GLfloat aspect = displaySize.height/displaySize.width;
        
        GLfloat vertexCoords[8] =
        {
            -1.0,	-aspect,
            1.0,	-aspect,
            1.0,	 aspect,
            -1.0,	 aspect
        };
        
        glEnableClientState( GL_TEXTURE_COORD_ARRAY );
        glTexCoordPointer(2, GL_FLOAT, 0, texCoords );
        glEnableClientState(GL_VERTEX_ARRAY);
        glVertexPointer(2, GL_FLOAT, 0, vertexCoords );
        glDrawArrays( GL_TRIANGLE_FAN, 0, 4 );
        glDisableClientState( GL_TEXTURE_COORD_ARRAY );
        glDisableClientState(GL_VERTEX_ARRAY);
        
        [super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime:ts];
    }
    else
    {
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT);
        [super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime:ts];
    }
    }
}

- (void) beginOptimize
{
    [self.player pause];
    self.asynchronous = NO;

    if(textureCache)
        CVOpenGLTextureCacheFlush(textureCache, 0);

    self.opacity = 0.0;
    
    self.readyForDisplay = NO;

}

- (void) endOptimize
{
    if(self.readyForDisplay)
    {
        self.opacity = 1.0;

        self.asynchronous = YES;
    }
}



@end
