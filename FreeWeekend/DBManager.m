//
//  DBManager.m
//  LimitFreeProject
//


#import "DBManager.h"
#import "FavouriteModel.h"

//全局变量
NSString * const kLZXFavorite = @"favorites";
NSString * const kLZXDownloads = @"downloads";
NSString * const kLZXBrowses = @"browese";

/*
 数据库
 1.导入 libsqlite3.dylib
 2.导入 fmdb
 3.导入头文件
 fmdb 是对底层C语言的sqlite3的封装
 
 */
@implementation DBManager
{
    //数据库对象
    FMDatabase *_database;
}

+ (DBManager *)sharedManager {
    static DBManager *manager = nil;
    @synchronized(self) {//同步 执行 防止多线程操作
        if (manager == nil) {
            manager = [[DBManager alloc] init];
        }
    }
    return manager;
}
- (id)init {
    if (self = [super init]) {
        //1.获取数据库文件app.db的路径
        NSString *filePath = [self getFileFullPathWithFileName:@"app.db"];
        //2.创建database
        _database = [[FMDatabase alloc] initWithPath:filePath];
        //3.open
        //第一次 数据库文件如果不存在那么 会创建并且打开
        //如果存在 那么直接打开
        if ([_database open]) {
//            NSLog(@"数据库打开成功");
            //创建表 不存在 则创建
            [self creatTable];
        }else {
//            NSLog(@"database open failed:%@",_database.lastErrorMessage);
        }
    }
    return self;
}
#pragma mark - 创建表
- (void)creatTable {
    //字段: 应用名 应用id 当前价格 最后价格 icon地址 记录类型 价格类型
    NSString *sql = @"create table if not exists appInfo(serial integer  Primary Key Autoincrement,title Varchar(1024),leo_id Varchar(1024),front_cover_image_list Varchar(1024),time_info Varchar(1024))";
    //创建表 如果不存在则创建新的表
    BOOL isSuccees = [_database executeUpdate:sql];
    if (isSuccees) {
//        NSLog(@"创建表成功");
    }
    if (!isSuccees) {
//        NSLog(@"creatTable error:%@",_database.lastErrorMessage);
    }
}
#pragma mark - 获取文件的全路径

//获取文件在沙盒中的 Documents中的路径
- (NSString *)getFileFullPathWithFileName:(NSString *)fileName {
    NSString *docPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents"];
//    NSLog(@"%@",docPath);
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:docPath]) {
        //文件的全路径
        return [docPath stringByAppendingFormat:@"/%@",fileName];
    }else {
        //如果不存在可以创建一个新的
//        NSLog(@"Documents不存在");
        return nil;
    }
}


//增加 数据 收藏/浏览/下载记录
//存储类型 favorites downloads browses
-(void)insertModel:(id)model{
    FavouriteModel *Model = (FavouriteModel *)model;
    if ([self isExistAppForAppId:Model.leo_id]) {
//        NSLog(@"this app has  recorded");
        return;
    }
    NSString *sql = @"insert into appInfo(title,leo_id,front_cover_image_list,time_info) values (?,?,?,?)";
    BOOL isSuccess = [_database executeUpdate:sql,Model.title,Model.leo_id,Model.front_cover_image_list,Model.time_info];
    if (!isSuccess) {
//        NSLog(@"insert error:%@",_database.lastErrorMessage);
    }
}
//删除指定的应用数据 根据指定的类型
- (void)deleteModelForAppId:(NSString *)appId{
    NSString *sql = @"delete from appInfo where leo_id = ?";
    BOOL isSuccess = [_database executeUpdate:sql,appId];
    if (!isSuccess) {
//        NSLog(@"delete error:%@",_database.lastErrorMessage);
    }
}

//根据指定类型  查找所有的记录
//根据记录类型 查找 指定的记录
- (NSArray *)readModels{
    
    NSString *sql = @"select * from appInfo";
    FMResultSet *rs = [_database executeQuery:sql];


    NSMutableArray *arr = [NSMutableArray array];
    //遍历集合
    while ([rs next]) {
        //把查询之后结果 放在model
        FavouriteModel *model = [[FavouriteModel alloc] init];
//        DResultModel *appModel = model.result;
        model.title = [rs stringForColumn:@"title"];
        model.leo_id = [rs stringForColumn:@"leo_id"];
       
        model.time_info = [rs stringForColumn:@"time_info"];
        model.front_cover_image_list  = [rs stringForColumn:@"front_cover_image_list"];
        //放入数组
        [arr addObject:model];
        //?
    }
    return arr;
    
    
}
//根据指定的类型 返回 这条记录在数据库中是否存在
- (BOOL)isExistAppForAppId:(NSString *)appId{
    NSString *sql = @"select * from appInfo where leo_id = ?";
    FMResultSet *rs = [_database executeQuery:sql,appId];
    if ([rs next]) {//查看是否存在 下条记录 如果存在 肯定 数据库中有记录
        return YES;
    }else{
        return NO;
    }
}
//根据 指定的记录类型  返回 记录的条数
//- (NSInteger)getCountsFromAppWithRecordType:(NSString *)type {
//    NSString *sql = @"select count(*) from appInfo where recordType = ?";
//    FMResultSet *rs = [_database executeQuery:sql,type];
//    NSInteger count = 0;
//    while ([rs next]) {
//        //查找 指定类型的记录条数
//        count = [[rs stringForColumnIndex:0] integerValue];
//    }
//    return count;
//}


@end
