//
//  AppDelegate.m
//  AutomaticCoder(修改版)
//
//  Created by 尹现伟 on 14-11-13.
//  Copyright (c) 2014年 DNE Technology Co.,Ltd. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate {
    NSMutableString *_templateH;
    NSMutableString *_templateM;
    
    NSMutableString *_import;
    NSMutableString *_protocol;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    //准备模板
    _templateH =[[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"txt"]
                                                                       encoding:NSUTF8StringEncoding
                                                                          error:nil];
    _templateM =[[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json2" ofType:@"txt"]
                                                                       encoding:NSUTF8StringEncoding
                                                                          error:nil];

    _import = [NSMutableString string];
    _protocol = [NSMutableString string];

}

- (IBAction)createClass:(id)sender {
    
    if (!self.nameTF.stringValue.length) {
        [self message:@"没有输入Class名！" defStr:@""];
        return;
    }
    else if (!self.jsonTF.string.length){
        [self message:@"Json无数据" defStr:@""];
        return;
    }
    NSString *jsonStr = [self.jsonTF.string stringByReplacingOccurrencesOfString:@"“" withString:@"\""];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"”" withString:@"\""];
    //将请求的url数据放到NSData对象中
    NSData *response = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    //IOS5自带解析类NSJSONSerialization从response中解析出数据放到字典中
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableLeaves error:nil];
    
    if ([dict isKindOfClass:[NSDictionary class]]) {
        
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        panel.canChooseDirectories = YES;
        panel.canChooseFiles = NO;
        __weak AppDelegate * weakApp = self;
        [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
            if(result == 0)
                return ;
            
            path = [panel.URL path];
            [weakApp generateClass:weakApp.nameTF.stringValue forDic:dict];
            
            [weakApp writeToFile];
            
        }];
    }
    else{
        [self message:@"JSON格式不正确！" defStr:self.jsonTF.string];
    }
}

- (void)writeToFile {
    
    [_templateM replaceOccurrencesOfString:@"#name#"
                                withString:[NSString stringWithFormat:@"%@Model", self.nameTF.stringValue]
                                   options:NSCaseInsensitiveSearch
                                     range:NSMakeRange(0, _templateM.length)];
    
    [_templateH replaceOccurrencesOfString:@"#protocol#"
                                withString:_protocol
                                   options:NSCaseInsensitiveSearch
                                     range:NSMakeRange(0, _templateH.length)];
    
    
    //创建时间
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [_templateH replaceOccurrencesOfString:@"#time#"
                                withString:[formatter stringFromDate:[NSDate date]]
                                   options:NSCaseInsensitiveSearch
                                     range:NSMakeRange(0, _templateH.length)];
    [_templateM replaceOccurrencesOfString:@"#time#"
                                withString:[formatter stringFromDate:[NSDate date]]
                                   options:NSCaseInsensitiveSearch
                                     range:NSMakeRange(0, _templateM.length)];
    
    
    [_templateH writeToFile:[NSString stringWithFormat:@"%@/%@Model.h", path, self.nameTF.stringValue]
                 atomically:NO
                   encoding:NSUTF8StringEncoding
                      error:nil];
    [_templateM writeToFile:[NSString stringWithFormat:@"%@/%@Model.m", path, self.nameTF.stringValue]
                 atomically:NO
                   encoding:NSUTF8StringEncoding
                      error:nil];
}

- (void)message:(NSString *)str defStr:(NSString *)str2{
    NSString *string = [str2 copy];
    self.jsonTF.string = str;
    self.jsonTF.textColor = [NSColor redColor];
    self.jsonTF.font = [NSFont systemFontOfSize:50];
    self.button.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.jsonTF.string = string;
        self.button.enabled = YES;
        self.jsonTF.textColor = [NSColor blackColor];
        self.jsonTF.font = [NSFont systemFontOfSize:12];
    });
}

- (void)changeJsonTF:(NSString *)str{
    self.jsonTF.string = str;
}



-(void)generateClass:(NSString *)name forDic:(NSDictionary *)json
{

    //准备模板
    NSMutableString *templateH =[[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"oneModel_h" ofType:@"txt"]
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
    NSMutableString *templateM =[[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"oneModel_m" ofType:@"txt"]
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil];
#pragma mark - .h
    //name
    //property
    NSMutableString *proterty = [NSMutableString string];

    
    NSString *prefix = [self.preTF.stringValue uppercaseString];
    
    if (![name isEqualToString:self.nameTF.stringValue]) {
        name = [NSString stringWithFormat:@"%@%@Model", prefix, name];
    }else {
        name = [NSString stringWithFormat:@"%@Model", name];
    }
    
    
//    NSLog(@"name:%@\n\n", name);
    for(NSString *key in [json allKeys])
    {
//        NSLog(@"key:%@\n", key);
        JsonValueType type = [self type:[json objectForKey:key]];
        switch (type) {
            case kString:
            case kNumber:
                [proterty appendFormat:@"@property (nonatomic, retain) %@ *%@;\n\n", [self typeName:type], key];
                break;
            case kArray:
            {
                if([self isDataArray:[json objectForKey:key]])
                {
                    [proterty appendFormat:@"@property (nonatomic, retain) NSMutableArray<%@%@Model> *%@;\n\n", [self.preTF.stringValue uppercaseString], [self uppercaseFirstChar:key], key];
                    [_import appendFormat:@"#import \"%@%@Model.h\"\n", [self.preTF.stringValue uppercaseString], [self uppercaseFirstChar:key]];
                    [_protocol appendFormat:@"@protocol %@%@Model <NSObject>\n@end\n\n", [self.preTF.stringValue uppercaseString], [self uppercaseFirstChar:key]];
                    [self generateClass:[NSString stringWithFormat:@"%@",[self uppercaseFirstChar:key]] forDic:[[json objectForKey:key]objectAtIndex:0]];
                }
            }
                break;
            case kDictionary:
                [proterty appendFormat:@"@property (nonatomic, retain) %@%@Model *%@;\n\n", [self.preTF.stringValue uppercaseString], [self uppercaseFirstChar:key], key];
                [_import appendFormat:@"#import \"%@%@Model.h\"\n", [self.preTF.stringValue uppercaseString], [self uppercaseFirstChar:key]];
                [self generateClass:[NSString stringWithFormat:@"%@",[self uppercaseFirstChar:key]] forDic:[json objectForKey:key]];
                
                break;
            case kBool:
                [proterty appendFormat:@"@property (nonatomic, assign) %@ %@;\n\n", [self typeName:type], key];
                break;
            default:
                break;
        }
    }
    
    [templateH replaceOccurrencesOfString:@"#name#"
                               withString:name
                                  options:NSCaseInsensitiveSearch
                                    range:NSMakeRange(0, templateH.length)];
//    [templateH replaceOccurrencesOfString:@"#import#"
//                               withString:import
//                                  options:NSCaseInsensitiveSearch
//                                    range:NSMakeRange(0, templateH.length)];
    [templateH replaceOccurrencesOfString:@"#property#"
                               withString:proterty
                                  options:NSCaseInsensitiveSearch
                                    range:NSMakeRange(0, templateH.length)];
//    [templateH replaceOccurrencesOfString:@"#protocol#"
//                               withString:protocol
//                                  options:NSCaseInsensitiveSearch
//                                    range:NSMakeRange(0, templateH.length)];
    
    
#pragma mark - .m
    
    //NSCoding
    //name
    [templateM replaceOccurrencesOfString:@"#name#"
                               withString:name
                                  options:NSCaseInsensitiveSearch
                                    range:NSMakeRange(0, templateM.length)];
    /*
    
//    NSMutableString *config = [NSMutableString string];
//    NSMutableString *encode = [NSMutableString string];
//    NSMutableString *decode = [NSMutableString string];
    NSMutableString *description = [NSMutableString string];
    
    NSDictionary *list =  @{
//                            @"config":config,
//                            @"encode":encode,
//                            @"decode":decode,
                            @"description":description
                            };
    
    
    for(NSString *key in [json allKeys])
    {
        JsonValueType type = [self type:[json objectForKey:key]];
        switch (type) {
            case kString:
            case kNumber:
//                [config appendFormat:@"self.%@%@  = [json objectForKey:@\"%@\"];\n ",self.preTF.stringValue,key,key];
//                [encode appendFormat:@"[aCoder encodeObject:self.%@%@ forKey:@\"zx_%@\"];\n",self.preTF.stringValue,key,key];
//                [decode appendFormat:@"self.%@%@ = [aDecoder decodeObjectForKey:@\"zx_%@\"];\n ",self.preTF.stringValue,key,key];
                [description appendFormat:@"result = [result stringByAppendingFormat:@\"%@ : %%@\\n\",self.%@];\n\n    ", key, key];
                break;
            case kArray:
            {
                if([self isDataArray:[json objectForKey:key]])
                {
//                    [config appendFormat:@"self.%@%@ = [NSMutableArray array];\n",self.preTF.stringValue,key];
//                    [config appendFormat:@"for(NSDictionary *item in [json objectForKey:@\"%@\"])\n",key];
//                    [config appendString:@"{\n"];
//                    [config appendFormat:@"[self.%@%@ addObject:[[%@ alloc] initWithJson:item]];\n",self.preTF.stringValue,key,[self uppercaseFirstChar:key]];
//                    [config appendString:@"}\n"];
//                    [encode appendFormat:@"[aCoder encodeObject:self.%@%@ forKey:@\"zx_%@\"];\n",self.preTF.stringValue,key,key];
//                    [decode appendFormat:@"self.%@%@ = [aDecoder decodeObjectForKey:@\"zx_%@\"];\n ",self.preTF.stringValue,key,key];
                    [description appendFormat:@"result = [result stringByAppendingFormat:@\"%@ : %%@\\n\",self.%@];\n\n    ", key, key];
                }
            }
                break;
            case kDictionary:
//                [config appendFormat:@"self.%@%@  = [[%@ alloc] initWithJson:[json objectForKey:@\"%@\"]];\n ",self.preTF.stringValue,key,[self uppercaseFirstChar:key],key];
//                [encode appendFormat:@"[aCoder encodeObject:self.%@%@ forKey:@\"zx_%@\"];\n",self.preTF.stringValue,key,key];
//                [decode appendFormat:@"self.%@%@ = [aDecoder decodeObjectForKey:@\"zx_%@\"];\n ",self.preTF.stringValue,key,key];
                [description appendFormat:@"result = [result stringByAppendingFormat:@\"%@ : %%@\\n\",self.%@];\n\n    ", key, key];
                
                break;
            case kBool:
//                [config appendFormat:@"self.%@%@ = [[json objectForKey:@\"%@\"]boolValue];\n ",self.preTF.stringValue,key,key];
//                [encode appendFormat:@"[aCoder encodeBool:self.%@%@ forKey:@\"zx_%@\"];\n",self.preTF.stringValue,key,key];
//                [decode appendFormat:@"self.%@%@ = [aDecoder decodeBoolForKey:@\"zx_%@\"];\n",self.preTF.stringValue,key,key];
                [description appendFormat:@"result = [result stringByAppendingFormat:@\"%@ : %%@\\n\",self.%@];\n\n    ", key, key];
                break;
            default:
                break;
        }
    }
    
    //修改模板
    for(NSString *key in [list allKeys])
    {
        [templateM replaceOccurrencesOfString:[NSString stringWithFormat:@"#%@#",key]
                                   withString:[list objectForKey:key]
                                      options:NSCaseInsensitiveSearch
                                        range:NSMakeRange(0, templateM.length)];
    }
    */
    
    //写文件
    NSLog(@"%@",[NSString stringWithFormat:@"%@/%@.h", path, name]);
//    [_templateH writeToFile:[NSString stringWithFormat:@"%@/%@.h", path, name]
//                atomically:NO
//                  encoding:NSUTF8StringEncoding
//                     error:nil];
//    [_templateM writeToFile:[NSString stringWithFormat:@"%@/%@.m",path, name]
//                atomically:NO
//                  encoding:NSUTF8StringEncoding
//                     error:nil];

    [_templateH appendString:templateH];
    [_templateM appendString:templateM];
}


//表示该数组内有且只有字典 并且 结构一致。
-(BOOL)isDataArray:(NSArray *)theArray
{
    if(theArray.count <=0 ) return NO;
    for(id item in theArray)
    {
        if([self type:item] != kDictionary)
        {
            return NO;
        }
    }
    
    NSMutableSet *keys = [NSMutableSet set];
    for(NSString *key in [[theArray objectAtIndex:0] allKeys])
    {
        [keys addObject:key];
    }
    
    
    for(id item in theArray)
    {
        NSMutableSet *newKeys = [NSMutableSet set];
        for(NSString *key in [item allKeys])
        {
            [newKeys addObject:key];
        }
        
        if([keys isEqualToSet:newKeys] == NO)
        {
            return NO;
        }
    }
    return YES;
}



-(JsonValueType)type:(id)obj
{
    if ([obj isKindOfClass:[NSString class]]) {
        return kString;
    }
    else if ([obj isKindOfClass:[NSNumber class]]){
        return kNumber;
    }
    else if ([obj isKindOfClass:[NSArray class]]){
        return kArray;
    }
    else if ([obj isKindOfClass:[NSDictionary class]]){
        return kDictionary;
    }
    else if([[obj className] isEqualToString:@"__NSCFBoolean"]){
        return kBool;
    }
    return -1;
    if([[obj className] isEqualToString:@"__NSCFString"] || [[obj className] isEqualToString:@"__NSCFConstantString"]) return kString;
    else if([[obj className] isEqualToString:@"__NSCFNumber"]) return kNumber;
    else if([[obj className] isEqualToString:@"__NSCFBoolean"])return kBool;
    else if([[obj className] isEqualToString:@"JKDictionary"])return kDictionary;
    else if([[obj className] isEqualToString:@"JKArray"])return kArray;
    return -1;
}

-(NSString *)typeName:(JsonValueType)type
{
    switch (type) {
        case kString:
            return @"NSString";
            break;
        case kNumber:
            return @"NSNumber";
            break;
        case kBool:
            return @"BOOL";
            break;
        case kArray:
        case kDictionary:
            return @"";
            break;
            
        default:
            break;
    }
}


-(NSString *)uppercaseFirstChar:(NSString *)str
{
    return [NSString stringWithFormat:@"%@%@",[[str substringToIndex:1] uppercaseString],[str substringWithRange:NSMakeRange(1, str.length-1)]];
}
-(NSString *)lowercaseFirstChar:(NSString *)str
{
    return [NSString stringWithFormat:@"%@%@",[[str substringToIndex:1] lowercaseString],[str substringWithRange:NSMakeRange(1, str.length-1)]];
}

@end

