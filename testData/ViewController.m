//
//  ViewController.m
//  testData
//
//  Created by LuxLightQ on 16/4/7.
//  Copyright © 2016年 L.Q. All rights reserved.
//

#import "ViewController.h"
#import <sqlite3.h>
#import "Cat.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //沙盒:先理解一下沙盒机制, 简单说就是除了APP自己的目录外, 不允许你在其他地方存取数据.
    //整个沙盒目录下有三个子目录:Documents Library tmp.
    //Documents目录下的数据在连接iTunes时会进行同步, 适合存储重要数据, 如用户信息啥的.
    //Library目录下又有两个子目录Caches Preferences, 一个是缓存, 一个是应用设置信息.
    //Library/Caches目录存储体积大且不需要备份的数据, Library/Preferences目录保存的设置信息会在iTunes连接时同步.
    //tmp用来保存临时数据, 在应用关闭时候就自动删除掉了.
    
//    [self testPropertyList];
//    [self testPreference];
//    [self testKeyedArchiver];
    [self testSqlite3];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//属性列表 被序列化的类型只有OC中的对象类型(String Array Dictionary Data Number).
//操作的对象有限, 另一点也是最为重要的一点, 保存方式为明文保存,
- (void)testPropertyList {
    //创建地址
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *plistPath = [docPath stringByAppendingString:@"testPlistFile.plist"];
    NSLog(@"path ----- %@", plistPath);
    NSDictionary *dic = @{@"key1":@"value1",@"key2":@"value2"};
    //存 //atomically 表示是否需要先写入一个辅助文件, 再把辅助文件拷贝到目标文件地址.能够进行writeToFile的只有Array和Dictionary类型, 反序列化同样是调用arrayWithContentsOfFile或dictionaryWithContentsOfFile.
    BOOL result = [dic writeToFile:plistPath atomically:YES];
    if (!result) {
        NSLog(@"写入失败了");
    }
    //读
    NSDictionary *dicRead = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSLog(@"\n read result--%@",dicRead);
}
//偏好设置一般是用来保存应用设置信息的, 最好不要在其中保存大量其他数据
//偏好设置文件保存在Library/Preferences目录下, 以工程的Bundle Identifier为名的plist文件中.
- (void)testPreference {
    // 获取偏好设置文件
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    // 存储
    [userDefaults setObject:@"isValue" forKey:@"object"];
    [userDefaults setBool:YES forKey:@"isBool"];
    [userDefaults setObject:@[@"1", @"2", @"3"] forKey:@"array"];
    // 立即保存 调用synchronize方法会进行立即保存, 否则系统会根据I/O不定时刻保存.
    [userDefaults synchronize];
    // 读取
    NSString *object = [userDefaults objectForKey:@"object"];
    BOOL isBool = [userDefaults boolForKey:@"isBool"];
    NSArray *array = [userDefaults objectForKey:@"array"];
    NSLog(@"\nobject : %@\nisBool : %@\narray : %@", object, isBool?@"YES":@"NO", array);
}
- (void)testKeyedArchiver {
    // 归档文件路径
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"cat.data"];
    NSLog(@"归档filePath --- %@",filePath);
    Cat *cat = [[Cat alloc] init];
    cat.name = @"guaguagua";
    cat.age = 1;
    //存
    [NSKeyedArchiver archiveRootObject:cat toFile:filePath];
    //取
    Cat *readCat = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    
    NSLog(@"\n catRead === %@",readCat);
}
//因为前几种方法属于覆盖式存储, 如果要改变其中某一条, 需要整体取出修改后再行归档.
//相比较之前的几种方法, SQLite方便进行增删改查, 更适合存储读取大量数据内容.
- (void)testSqlite3 {
    
    // 路径
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"personSqlite.sqlite"];
    NSLog(@"保存路径%@",filePath);
    sqlite3 *db;
    if (sqlite3_open(filePath.UTF8String, &db)!=SQLITE_OK) {
        sqlite3_close(db);
        NSAssert(0, @"open database faid!");
        NSLog(@"数据库创建失败！");
    }
    NSString *ceateSQL = @"CREATE TABLE IF NOT EXISTS PERSONINFO(ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT, AGE INTEGER, SEX TEXT, WEIGHT INTEGER, ADDRESS TEXT)";
    char *error;
    if (sqlite3_exec(db, [ceateSQL UTF8String], NULL, NULL, &error)!=SQLITE_OK){
        sqlite3_close(db);
        NSAssert(0, @"ceate table faild!");
        NSLog(@"表创建失败");
    }

    //增
    char *errorMsg = NULL;
    
    NSString *insert = [NSString stringWithFormat:@"INSERT OR REPLACE INTO PERSONINFO('NAME','AGE','SEX','WEIGHT','ADDRESS')VALUES('%@','%d','%@','%d','%@')",@"LuxLightQ",24,@"man",65,@"中国江苏,苏州,TC"];
    //执行语句
    if (sqlite3_exec(db, [insert UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK) {
        sqlite3_close(db);
    }
    
    ///查询
    NSString *quary = @"SELECT * FROM PERSONINFO";//SELECT ROW,FIELD_DATA FROM FIELDS ORDER BY ROW
    sqlite3_stmt *stmt;
    //sqlite3_prepare_v2是执行查询的方法，当查询语句执行成功时，使用sqlite3_step当游标指向每一行
    if (sqlite3_prepare_v2(db, [quary UTF8String], -1, &stmt, nil) == SQLITE_OK) {
        
        while (sqlite3_step(stmt)==SQLITE_ROW) {
            
            char *name = (char *)sqlite3_column_text(stmt, 1);
            NSString *nameString = [[NSString alloc] initWithUTF8String:name];
            NSLog(@"姓名-----%@",nameString);
            
            int age = sqlite3_column_int(stmt, 2);
            NSLog(@"年龄------%@",@(age));
            
            char *sex = (char *)sqlite3_column_text(stmt, 3);
            NSString *sexString = [[NSString alloc] initWithUTF8String:sex];
            NSLog(@"性别------%@",sexString);
            
            
            int weight = sqlite3_column_int(stmt, 4);
            NSLog(@"体重------%@",@(weight));
            
            char *address = (char *)sqlite3_column_text(stmt, 5);
            NSString *addressString = [[NSString alloc] initWithUTF8String:address];
            NSLog(@"地址------%@",addressString);
        }
        sqlite3_finalize(stmt);
    }
    //用完了一定记得关闭，释放内存
    sqlite3_close(db);
}
@end
