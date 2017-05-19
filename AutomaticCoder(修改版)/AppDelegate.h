//
//  AppDelegate.h
//  AutomaticCoder(修改版)
//
//  Created by 尹现伟 on 14-11-13.
//  Copyright (c) 2014年 DNE Technology Co.,Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
typedef enum
{
    kString = 0,
    kNumber = 1,
    kArray  = 2,
    kDictionary = 3,
    kBool   = 4,
}JsonValueType;

@interface AppDelegate : NSObject <NSApplicationDelegate>{
    
    NSString *path;
    
}

@property (assign) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView *jsonTF;
@property (weak) IBOutlet NSTextField *nameTF;
@property (weak) IBOutlet NSTextField *preTF;
@property (weak) IBOutlet NSButton *button;

- (IBAction)createClass:(id)sender;

@end

