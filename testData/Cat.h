//
//  Cat.h
//  testData
//
//  Created by LuxLightQ on 16/4/7.
//  Copyright © 2016年 L.Q. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Cat : NSObject <NSCoding>
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSUInteger age;
@end
