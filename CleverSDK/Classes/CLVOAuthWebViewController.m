//
//  CLVOAuthWebViewController.m
//  CleverSDK
//
//  Created by Nikhil Pandit on 4/3/15.
//  Copyright (c) 2015 Clever, Inc. All rights reserved.
//

#import "CLVOAuthWebViewController.h"
#import "CLVOAuthManager.h"

#import <WebKit/WebKit.h>

@interface CLVOAuthWebViewController ()

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, weak) UIViewController *parent;
@property (nonatomic, strong) NSString *districtId;

@end

@implementation CLVOAuthWebViewController

- (id)initWithParent:(UIViewController *)viewController districtId:(NSString *)districtId {
    self = [super init];
    if (self) {
        self.parent = viewController;
        self.districtId = districtId;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessTokenReceived:) name:CLVAccessTokenReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(oauthAuthorizeFailed:) name:CLVOAuthAuthorizeFailedNotification object:nil];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    NSString *script = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:script injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUScript];
    
    config.userContentController = wkUController;
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    [self.view addSubview:self.webView];
    [self.webView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|[_webView]|"
                               options:0
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(_webView)]];
    
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|[_webView]|"
                               options:0
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(_webView)]];
    
    if ([CLVOAuthManager clientIdIsNotSet]) {
        [[[UIAlertView alloc] initWithTitle:@"Error"
                                    message:@"Clever Client ID is not set"
                                   delegate:nil
                          cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"https://clever.com/oauth/authorize?response_type=token&client_id=%@&redirect_uri=%@",
                           [CLVOAuthManager clientId], [CLVOAuthManager redirectUri]];
    if (self.districtId) {
        urlString = [NSString stringWithFormat:@"%@&district_id=%@", urlString, self.districtId];
    }
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
}

- (void)accessTokenReceived:(NSNotification *)notification {
    [self dismissViewControllerAnimated:NO completion:^{
        [CLVOAuthManager callSucessHandler];
    }];
}

- (void)oauthAuthorizeFailed:(NSNotification *)notification {
    [self dismissViewControllerAnimated:NO completion:^{
        [CLVOAuthManager callFailureHandler];
    }];
}

@end
