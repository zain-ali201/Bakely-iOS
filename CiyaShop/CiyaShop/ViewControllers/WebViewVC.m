//
//  WebViewVC.m
//  QuickClick
//
//  Created by Kaushal PC on 28/07/17.
//  Copyright © 2017 Potenza. All rights reserved.
//

#import "WebViewVC.h"
#import "ThankYouVC.h"

@interface WebViewVC ()<UIWebViewDelegate>

@property (strong,nonatomic) IBOutlet UIView *vwHeader;
@property (strong, nonatomic) IBOutlet UIView *vwAllData;
@property (strong, nonatomic) IBOutlet UIButton *btnBack;

@property (strong, nonatomic) IBOutlet UIImageView *imgHeaderImage;

@end

@implementation WebViewVC {
    UIView *vw;
    NSMutableArray *arrCheckoutOptions;
}
@synthesize delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    arrCheckoutOptions = [[NSMutableArray alloc] initWithArray:appDelegate.arrCheckoutOptions];
    
    if (![self.urlThankYou isEqualToString:@""] && self.urlThankYou != nil)
    {
        [arrCheckoutOptions addObject:self.urlThankYou];
    }
    if (![self.urlThankYouEndPoint isEqualToString:@""] && self.urlThankYouEndPoint != nil)
    {
        [arrCheckoutOptions addObject:self.urlThankYouEndPoint];
    }
    if([Util getStringData:kAppNameWhiteImage] !=nil){
        
        [self.imgHeaderImage sd_setImageWithURL:[Util EncodedURL:[Util getStringData:kAppNameWhiteImage]] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (image == nil)
            {
                self.imgHeaderImage.image = [UIImage imageNamed:@"HeaderClickShop"];
            }
            else
            {
                self.imgHeaderImage.image = image;
            }
        }];
    }
    
    NSURL *url = [NSURL URLWithString:self.url];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL: url];
    [request setHTTPMethod: @"POST"];

    if (appDelegate.isWpmlActive)
    {
        NSString *body = [NSString stringWithFormat: @"lang_is=%@", [Util getStringData:kLanguageText] ];
        [request setHTTPBody: [body dataUsingEncoding: NSUTF8StringEncoding]];
    }
    [self.webview loadRequest: request];
    self.webview.scrollView.bounces = NO;
    self.webview.keyboardDisplayRequiresUserAction = false;
    self.webview.delegate = self;

    [Util setHeaderColorView:self.vwHeader];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.vwAllData.frame = CGRectMake(0, statusBarSize.height, self.vwAllData.frame.size.width, SCREEN_SIZE.height - statusBarSize.height);
    vw = [[UIView alloc]initWithFrame:CGRectMake(0, 0, statusBarSize.width, statusBarSize.height)];
    [Util setHeaderColorView:vw];
    [self.view addSubview:vw];
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [Util setHeaderColorView:vw];
    
    if (appDelegate.isRTL) {
        [[UIView appearance] setSemanticContentAttribute:UISemanticContentAttributeForceRightToLeft];
        self.btnBack.transform = CGAffineTransformMakeRotation(M_PI);
    }
}
#pragma mark - Button Click
/*!
 * @discussion It will take you to PreviousView
 * @param sender For indentifying sender
 */
- (IBAction)btnBackClicked:(id)sender
{
    appDelegate.isFromBuyNow = NO;
    [Util setArray:nil setData:kBuyNow];
    HIDE_PROGRESS;

    if ([self.webview canGoBack])
    {
        [self.webview goBack];
    }
    else
    {
        [self logoutUser];
    }
}

#pragma mark - UIWebView Delegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL isRemoved = false;
    NSArray *arr = [[[request URL] absoluteString] componentsSeparatedByString:@"?"];
    
    if (arr.count > 0)
    {
        NSString *urlLoad = [arr objectAtIndex:0];
        
        for (int i = 0; i < arrCheckoutOptions.count; i++)
        {
            NSString *strUrl = [arrCheckoutOptions objectAtIndex:i];
            
            if ([strUrl hasPrefix:@"/"] && [strUrl length] > 1) {
                strUrl = [strUrl substringFromIndex:1];
            }
            
            if ([strUrl hasSuffix:@"/"] && [strUrl length] > 1) {
                strUrl = [strUrl substringToIndex:[strUrl length] - 1];
            }
            
            if ([strUrl isEqualToString:@""])
            {
                continue;
            }
            else if ([urlLoad containsString:strUrl])
            {
                // Facebook Pixel for Product Purchased
                NSMutableArray *arrMyCart = [[NSMutableArray alloc] init];
                
                if (appDelegate.isFromBuyNow) {
                    //For Buy Now code
                    arrMyCart = [[NSMutableArray alloc] initWithArray:[[Util getArrayData:kBuyNow] mutableCopy]];
                }
                else
                {
                    //For My Cart code
                    arrMyCart = [[NSMutableArray alloc] initWithArray:[[Util getArrayData:kMyCart] mutableCopy]];
                }
                for (int i = 0; i < arrMyCart.count; i++)
                {
                    AddToCartData *object;
                    if([[arrMyCart objectAtIndex:i] isKindOfClass:[NSData class]])
                    {
                        object = [Util loadCustomObjectWithKey:[arrMyCart objectAtIndex:i]];
                    }
                    else
                    {
                        object = [arrMyCart objectAtIndex:i];
                    }
                    // Facebook Pixel For Purchase Event
                    [Util logPurchasedEvent:object.quantity contentType:object.name contentId:[NSString stringWithFormat:@"%d", object.productId] currency:appDelegate.strCurrencySymbol valToSum:object.price];
                }
                
                isRemoved = true;
                [Util setArray:nil setData:kMyCart];
                [self.navigationController popViewControllerAnimated:YES];
                if (delegate)
                {
                    [delegate setThankYouPage:YES];
                }
                break;
            }
        }
    }
    
    if (isRemoved)
    {
        return NO;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    SHOW_LOADER_ANIMTION();
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    HIDE_PROGRESS;
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    HIDE_PROGRESS;
}


#pragma mark - API calls
/*!
 * @discussion Webservice call for LogOut User
 */
- (void)logoutUser
{
    SHOW_LOADER_ANIMTION();
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict = nil;
    [CiyaShopAPISecurity userLogout:^(BOOL success, NSString *message, NSDictionary *dictionary) {
        
        HIDE_PROGRESS;
        if(success==YES)
        {
            //no error
            if (dictionary.count>0)
            {
                if ([[dictionary valueForKey:@"status"] isEqualToString:@"success"])
                {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
            else
            {
                [Util setArray:nil setData:kWishList];
            }
        }
    }];
}


#pragma mark - Hide Bottom bar

-(BOOL)hidesBottomBarWhenPushed
{
    return YES;
}



#pragma mark - StatusBar Delegate
/*!
 * @discussion This method is used to set Status bar text color
 */
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
