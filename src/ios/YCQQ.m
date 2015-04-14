
#import "YCQQ.h"
#import "AppDelegate.h"
#import <TencentOpenAPI/QQApi.h>
#import <TencentOpenAPI/QQApiInterface.h>

@implementation YCQQ
- (void)pluginInitialize {
    NSString* appId = [[self.commandDelegate settings] objectForKey:@"qq_app_id"];
    if (nil == self.tencentOAuth) {
        self.tencentOAuth = [[TencentOAuth alloc] initWithAppId:appId andDelegate:self];
    }
}

-(void)ssoLogin:(CDVInvokedUrlCommand *)command{
    self.permissions =[NSArray arrayWithObjects:
                     kOPEN_PERMISSION_GET_USER_INFO,
                     kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                     kOPEN_PERMISSION_ADD_ALBUM,
                     kOPEN_PERMISSION_ADD_IDOL,
                     kOPEN_PERMISSION_ADD_ONE_BLOG,
                     kOPEN_PERMISSION_ADD_PIC_T,
                     kOPEN_PERMISSION_ADD_SHARE,
                     kOPEN_PERMISSION_ADD_TOPIC,
                     kOPEN_PERMISSION_CHECK_PAGE_FANS,
                     kOPEN_PERMISSION_DEL_IDOL,
                     kOPEN_PERMISSION_DEL_T,
                     kOPEN_PERMISSION_GET_FANSLIST,
                     kOPEN_PERMISSION_GET_IDOLLIST,
                     kOPEN_PERMISSION_GET_INFO,
                     kOPEN_PERMISSION_GET_OTHER_INFO,
                     kOPEN_PERMISSION_GET_REPOST_LIST,
                     kOPEN_PERMISSION_LIST_ALBUM,
                     kOPEN_PERMISSION_UPLOAD_PIC,
                     kOPEN_PERMISSION_GET_VIP_INFO,
                     kOPEN_PERMISSION_GET_VIP_RICH_INFO,
                     kOPEN_PERMISSION_GET_INTIMATE_FRIENDS_WEIBO,
                     kOPEN_PERMISSION_MATCH_NICK_TIPS_WEIBO,
                     nil];
    self.callback=command.callbackId;
    if (self.tencentOAuth.isSessionValid) {
        NSMutableDictionary *Dic =[NSMutableDictionary dictionaryWithCapacity:2];
        [Dic setObject:self.tencentOAuth.openId forKey:@"userid"];
        [Dic setObject:self.tencentOAuth.accessToken forKey:@"access_token"];
        CDVPluginResult *pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:Dic];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callback];
    }else{
        [self.tencentOAuth authorize:self.permissions inSafari:YES];
    }


}
-(void)logout:(CDVInvokedUrlCommand *)command
{
    if(self.tencentOAuth.isSessionValid){
         [self.tencentOAuth logout:self];
    }
    CDVPluginResult *pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)shareToQQ:(CDVInvokedUrlCommand *)command{
    self.callback=command.callbackId;
    NSDictionary *args         = [command.arguments objectAtIndex:0];
    NSLog(@"%@",args);
    if(args){
        NSString *url = [args objectForKey:@"url"];
        //分享图预览图URL地址
        NSString *previewImageUrl = [args objectForKey:@"imageUrl"];
        QQApiNewsObject *newsObj = [QQApiNewsObject
                                    objectWithURL:[NSURL URLWithString:url]
                                    title: [args objectForKey:@"title"]
                                    description: [args objectForKey:@"description"]
                                    previewImageURL:[NSURL URLWithString:previewImageUrl]];
        SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
        
        QQApiSendResultCode sent = [QQApiInterface sendReq:req];
        [self handleSendResult:sent];
    }else{
        CDVPluginResult *pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

}
- (void)handleOpenURL:(NSNotification *)notification
{
    NSURL* url = [notification object];
    if ([url isKindOfClass:[NSURL class]])
    {     
        [TencentOAuth HandleOpenURL:url];
    }
}

- (void)tencentDidLogin{
    
    if (self.tencentOAuth.accessToken && 0 != [self.tencentOAuth.accessToken length])
    {
        NSMutableDictionary *Dic =[NSMutableDictionary dictionaryWithCapacity:2];
        [Dic setObject:self.tencentOAuth.openId forKey:@"userid"];
        [Dic setObject:self.tencentOAuth.accessToken forKey:@"access_token"];
        NSLog(@"开始保存 dic is %@",Dic);
        CDVPluginResult *pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:Dic];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callback];
    }else{
        CDVPluginResult *pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callback];
    }

}

-(void)tencentDidLogout{
    CDVPluginResult *pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callback];
    
}
-(void)tencentDidNotLogin:(BOOL)cancelled{
    if (cancelled) {
        CDVPluginResult *pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callback];
    }
    
}
-(void)tencentDidNotNetWork{
    CDVPluginResult *pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callback];
}

- (void)handleSendResult:(QQApiSendResultCode)sendResult
{
    switch (sendResult)
    {
        case EQQAPIAPPNOTREGISTED:
        case EQQAPIMESSAGECONTENTINVALID:
        case EQQAPIMESSAGECONTENTNULL:
        case EQQAPIMESSAGETYPEINVALID:
        case EQQAPIQQNOTINSTALLED:
        case EQQAPIQQNOTSUPPORTAPI:
        case EQQAPISENDFAILD:
        {
            CDVPluginResult *pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callback];
            
            break;
        }
        case EQQAPISENDSUCESS:
        {
            CDVPluginResult *pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callback];
        }
        default:
        {
            break;
        }
    }
}

@end
