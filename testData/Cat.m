//
//  Cat.m
//  testData
//
//  Created by LuxLightQ on 16/4/7.
//  Copyright © 2016年 L.Q. All rights reserved.
//

#import "Cat.h"

@implementation Cat
//编码 如果对自定义类的子类归档时, 需要先实现父类的编码解码方法, 即[super encodeWithCoder:aCoder]与[super initWithCoder:aDecoder].
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeInteger:self.age forKey:@"age"];
}
//解码
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.age = [aDecoder decodeIntegerForKey:@"age"];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"\n name:%@ \n age:%@",self.name,@(self.age)];
}
@end
