//
//  UIViewController+PlayerViewController.m
//  BananaATVBrowser
//
//  Created by 花心胡萝卜 on 9/14/22.
//  Copyright © 2022 High Caffeine Content. All rights reserved.
//

#import "PlayerViewController.h"
#import <TVVLCKit/TVVLCKit.h>

@interface PlayerViewController() <VLCMediaPlayerDelegate>
{
    VLCMediaPlayer *_mediaplayer;
}

@end

@implementation PlayerViewController: UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    /* setup the media player instance, give it a delegate and something to draw into */
    _mediaplayer = [[VLCMediaPlayer alloc] init];
    _mediaplayer.delegate = self;
    _mediaplayer.drawable = self.movieView;

    /* create a media object and give it to the player */
    NSString *videoUrl = [[NSUserDefaults standardUserDefaults] objectForKey: @"videoUrl"];
    NSLog(@"PPPPPPPPPPPPPlay: %@", videoUrl);
    _mediaplayer.media = [VLCMedia mediaWithURL:[NSURL URLWithString:videoUrl]];
    [_mediaplayer play];
}

- (IBAction)playandPause:(id)sender
{
    if (_mediaplayer.isPlaying)
        [_mediaplayer pause];

    [_mediaplayer play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
