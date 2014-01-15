//
//  SPLBokehBackgroundView.m
//  waiter
//
//  Created by Oliver Letterer on 14.01.14.
//  Copyright 2014 SparrowLabs. All rights reserved.
//

#import "SPLBokehBackgroundView.h"
#import <SpriteKit/SpriteKit.h>
#import <CoreMotion/CoreMotion.h>

#ifndef ARC4RANDOM_MAX
#define ARC4RANDOM_MAX 0x100000000
#endif

static CGFloat additionalSpace = 100.0;

static double randomNumber(void)
{
    return (double)arc4random() / ARC4RANDOM_MAX;
}

static void updateSpriteNode(SKSpriteNode *spriteNode, NSArray *textures)
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    size.width += 2.0 * additionalSpace;
    size.height += 2.0 * additionalSpace;
    
    double random1 = randomNumber();
    double random2 = randomNumber();
    double random3 = randomNumber();
    int textureIndex = (int)(random3 * textures.count);
    double randomScale = (randomNumber() + textureIndex) / textures.count;
    randomScale = MAX(1.0 / textures.count, randomScale);

    spriteNode.position = CGPointMake(size.width * random1 - additionalSpace, size.height * random2 - additionalSpace);
    [spriteNode setScale:randomScale];

    spriteNode.texture = textures[textureIndex];
    spriteNode.physicsBody.mass = 1.0 - random3;
}

@interface SPLBokehWorldScene : SKScene

@property (nonatomic, strong) SKSpriteNode *backgroundNode;
@property (nonatomic, strong) SKEffectNode *world;
@property (nonatomic, strong) NSArray *textures;
@property (nonatomic, strong) CMMotionManager *motionManager;

@end

@implementation SPLBokehWorldScene

- (instancetype)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        self.backgroundNode = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImageNamed:@"SPLBokehBackgroundView.bundle/gradient"]];
        [self addChild:self.backgroundNode];

        self.world = [SKEffectNode node];
        self.world.name = @"World";
        [self addChild:self.world];

        if ([UIImage imageNamed:@"bokeh"]) {
            SKTexture *texture = [SKTexture textureWithImageNamed:@"bokeh"];

            self.textures = @[
                              [SKTexture textureWithRect:CGRectMake(0,          0.203125,   0.37109375, 0.37109375) inTexture:texture],
                              [SKTexture textureWithRect:CGRectMake(0,          0.578125,   0.421875,   0.421875)   inTexture:texture],
                              [SKTexture textureWithRect:CGRectMake(0.375,      0.234375,   0.33984375, 0.33984375) inTexture:texture],
                              [SKTexture textureWithRect:CGRectMake(0.375,      0.0078125,  0.22265625, 0.22265625) inTexture:texture],
                              [SKTexture textureWithRect:CGRectMake(0.71875,    0.1796875,  0.23828125, 0.23828125) inTexture:texture],
                              [SKTexture textureWithRect:CGRectMake(0.71875,    0.421875,   0.27734375, 0.27734375) inTexture:texture],
                              [SKTexture textureWithRect:CGRectMake(0.7265625,  0.74609375, 0.25390625, 0.25390625) inTexture:texture],
                              [SKTexture textureWithRect:CGRectMake(0.42578125, 0.703125,   0.296875,   0.296875)   inTexture:texture],
                              ];
        } else {
            NSMutableArray *textures = [NSMutableArray array];
            for (int i = 0; i < 8; i++) {
                [textures addObject:[SKTexture textureWithImageNamed:[NSString stringWithFormat:@"SPLBokehBackgroundView.bundle/bokeh_%d", i]]];
            }
            self.textures = textures;
        }

        for (int i = 0; i < 15; i++) {
            [self _createNewSpriteNode];
        }

        __unsafe_unretained SKEffectNode *world = self.world;
        self.motionManager = [[CMMotionManager alloc] init];
        self.motionManager.deviceMotionUpdateInterval = 0.5;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
            if (error) {
                return;
            }

            for (SKNode *node in world.children) {
                [node.physicsBody applyImpulse:CGVectorMake(motion.rotationRate.y * 25.0, - motion.rotationRate.x * 25.0)];
            }
            
        }];
    }
    return self;
}

- (void)update:(NSTimeInterval)currentTime
{
    [super update:currentTime];

    CGSize size = [UIScreen mainScreen].bounds.size;

    for (SKNode *node in self.world.children) {
        CGPoint position = node.position;
        BOOL madeChanges = NO;

        if (position.x > size.width + additionalSpace) {
            position.x = - additionalSpace;
            madeChanges = YES;
        } else if (position.x < -additionalSpace) {
            position.x = size.width + additionalSpace;
            madeChanges = YES;
        }

        if (position.y > size.height + additionalSpace) {
            position.y = - additionalSpace;
            madeChanges = YES;
        } else if (position.y < -additionalSpace) {
            position.y = size.height + additionalSpace;
            madeChanges = YES;
        }

        if (madeChanges) {
            node.position = position;
        }
    }
}

- (void)_createNewSpriteNode
{
    SKSpriteNode *spriteNode = [SKSpriteNode spriteNodeWithTexture:self.textures.firstObject];
    spriteNode.alpha = 0.0;
    spriteNode.color = [UIColor colorWithRed:0.657683 green:0.816659 blue:0.896046 alpha:0.75];
    spriteNode.colorBlendFactor = 1.0;
    spriteNode.blendMode = SKBlendModeAlpha;
    spriteNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:10.0];
    spriteNode.physicsBody.collisionBitMask = 0;
    spriteNode.physicsBody.allowsRotation = NO;
    spriteNode.physicsBody.affectedByGravity = NO;
    spriteNode.physicsBody.linearDamping = 0.75;
    [self.world addChild:spriteNode];

    updateSpriteNode(spriteNode, self.textures);

    static CGFloat shrinkScale = 0.985000;
    static CGFloat growScale = 1.015228;

    SKAction *xScaleAction = [SKAction sequence:@[
                                                  [SKAction scaleXBy:shrinkScale y:1.0 duration:0.2],
                                                  [SKAction waitForDuration:0.2 withRange:0.3],
                                                  [SKAction scaleXBy:growScale y:1.0 duration:0.2],
                                                  [SKAction waitForDuration:0.2 withRange:0.3],
                                                  ]];

    SKAction *yScaleAction = [SKAction sequence:@[
                                                  [SKAction scaleXBy:1.0 y:shrinkScale duration:0.2],
                                                  [SKAction waitForDuration:0.2 withRange:0.3],
                                                  [SKAction scaleXBy:1.0 y:growScale duration:0.2],
                                                  [SKAction waitForDuration:0.2 withRange:0.3],
                                                  ]];

    SKAction *wobble = [SKAction repeatActionForever:[SKAction group:@[ [SKAction repeatActionForever:xScaleAction], [SKAction repeatActionForever:yScaleAction] ]]];

    double flickerScale = randomNumber();
    double scaleDuration = randomNumber();
    double waitDuration = randomNumber();
    double waitRange = randomNumber();
    SKAction *flickerSequence = [SKAction sequence:@[
                                                     [SKAction fadeAlphaBy:flickerScale duration:scaleDuration],
                                                     [SKAction waitForDuration:waitRange withRange:waitDuration],
                                                     [SKAction fadeAlphaBy:flickerScale duration:scaleDuration],
                                                     [SKAction waitForDuration:waitRange withRange:waitDuration],
                                                     ]];

    __weakObject(spriteNode);
    __weakSelf;

    SKAction *removeFlickerAction = [SKAction runBlock:^{
        __strongObject(spriteNode);
        [strong_spriteNode removeActionForKey:@"flicker"];
    }];

    SKAction *addFlickerAction = [SKAction runBlock:^{
        __strongObject(spriteNode);
        [strong_spriteNode runAction:[SKAction repeatActionForever:flickerSequence] withKey:@"flicker"];
    }];


    SKAction *resetAction = [SKAction runBlock:^{
        __strongObject(spriteNode);
        __strongSelf;

        updateSpriteNode(strong_spriteNode, strongSelf.textures);
    }];

    double fadeInDuration = randomNumber() * 10.0 + 5.0;
    double fadeOutDuration = randomNumber() * 10.0 + 5.0;

    SKAction *transitionInAction = [SKAction sequence:@[
                                                        [SKAction fadeInWithDuration:fadeInDuration],
                                                        addFlickerAction,
                                                        [SKAction waitForDuration:5.0 withRange:7.0],
                                                        removeFlickerAction,
                                                        [SKAction fadeOutWithDuration:fadeOutDuration],
                                                        resetAction,
                                                        ]];

    [spriteNode runAction:[SKAction repeatActionForever:[SKAction rotateByAngle:randomNumber() * 100.0 + 50.0 duration:randomNumber() * 100.0 + 50.0]] withKey:@"spin"];
    [spriteNode runAction:wobble withKey:@"wobble"];
    [spriteNode runAction:[SKAction repeatActionForever:transitionInAction] withKey:@"transitionIn"];
}

@end



@interface SPLBokehBackgroundView ()
@property (SK_NONATOMIC_IOSONLY, readonly) SPLBokehWorldScene *scene;
@end

@implementation SPLBokehBackgroundView

#pragma mark - setters and getters

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    self.scene.backgroundNode.texture = [SKTexture textureWithImage:backgroundImage];
}

- (void)setTextures:(NSArray *)textures
{
    self.scene.textures = textures;
}

- (NSArray *)textures
{
    return self.scene.textures;
}

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        CGSize size = [UIScreen mainScreen].bounds.size;

        SPLBokehWorldScene *scene = [SPLBokehWorldScene sceneWithSize:size];
        scene.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
        scene.backgroundColor = [UIColor orangeColor];
        [self presentScene:scene];
    }
    return self;
}

#pragma mark - Memory management

- (void)dealloc
{
    
}

#pragma mark - Private category implementation ()

@end
