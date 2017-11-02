//
//  ViewController.m
//  iOSLockDemo
//
//  Created by macOfEthan on 17/11/2.
//  Copyright © 2017年 macOfEthan. All rights reserved.
//

#import "ViewController.h"
#import <libkern/OSAtomic.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self OSSpinLockDemo];
}

#pragma mark - NSLock
- (void)NSLockDemo
{
    /**NSLock、NSConditionLock、NSRecursiveLock、NSCondition，然后有一个 NSLocking 协议：
     lock与unlock操作必须在同一线程，否则结果不确定甚至会引起死锁
     trylock 和 lock 使用场景：当前线程锁失败，也可以继续其它任务，用 trylock 合适；当前线程只有锁成功后，才会做一些有意义的工作，那就 lock，没必要轮询 trylock。
     lockBeforeDate: 方法会在所指定 Date 之前尝试加锁，会阻塞线程，如果在指定时间之前都不能加锁，则返回 NO，指定时间之前能加锁，则返回 YES。
     由于是互斥锁，当一个线程进行访问的时候，该线程获得锁，其他线程进行访问的时候，将被操作系统挂起，直到该线程释放锁，其他线程才能对其进行访问，从而却确保了线程安全。但是如果连续锁定两次，则会造成死锁问题。
     */
    
    NSLock *lock = [NSLock new];
    
    dispatch_queue_t q = dispatch_get_global_queue(0, 0);
    dispatch_queue_t q2 = dispatch_get_global_queue(0, 0);
    
    dispatch_async(q, ^{
        
        if ([lock tryLock]) {
            
            NSLog(@"加锁成功");
            
            [lock lock];
            // 上锁解锁必须一对对出现
            // 此处报错 ： -[NSLock unlock]: lock (<NSLock: 0x6080000cbd70> '(null)') unlocked from thread which did not lock it
            //[lock lock];
            
            sleep(5);
            
            NSLog(@"NSLock 1 加锁成功");
            
            [lock unlock];
            
            NSLog(@"NSLock 1 解锁成功");
            
        }else{
            
            NSLog(@"加锁失败");
        }
        
    });
    
    dispatch_async(q2, ^{
        
        [lock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
        
        sleep(5);
        
        NSLog(@"NSLock 2 加锁成功");
        
        [lock unlock];
        
        NSLog(@"NSLock 2 解锁成功");
    });
}

#pragma mark - NSRecursiveLock
/**
 NSRecursiveLock 是递归锁，顾名思义，可以被一个线程多次获得，而不会引起死锁。它记录了成功获得锁的次数，每一次成功的获得锁，必须有一个配套的释放锁和其对应，这样才不会引起死锁。NSRecursiveLock 会记录上锁和解锁的次数，当二者平衡的时候，才会释放锁，其它线程才可以上锁成功。
 */
- (void)NSRecursiveLockDemo
{
    NSRecursiveLock *recursiveLock = [[NSRecursiveLock alloc] init];
    
    static void(^recursiveLockBlock)(int value);
    
    recursiveLockBlock = ^(int value){
        
        [recursiveLock lock];
        
        NSLog(@"recursiveLock 加锁成功");
        
        if (value < 10) {
            
            NSLog(@"value = %d", value);
            
            recursiveLockBlock(value+1);
        }
        
        [recursiveLock unlock];
        
        NSLog(@"recursiveLock解锁成功");
    };
    
    recursiveLockBlock(1);
    
}

#pragma mark - NSConditionLock
- (void)conditionLockDemo
{
    /**
     NSConditionLock 对象所定义的互斥锁可以在使得在某个条件下进行锁定和解锁，它和 NSLock 类似，都遵循 NSLocking 协议，方法都类似，只是多了一个 condition 属性，以及每个操作都多了一个关于 condition 属性的方法，例如 tryLock、tryLockWhenCondition:，所以 NSConditionLock 可以称为条件锁。
     
     只有 condition 参数与初始化时候的 condition 相等，lock 才能正确进行加锁操作。
     unlockWithCondition: 并不是当 condition 符合条件时才解锁，而是解锁之后，修改 condition 的值。
     */
    
    NSConditionLock *conditionLock = [[NSConditionLock alloc] initWithCondition:0];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSLog(@"thread 1 = %@", [NSThread currentThread]);
        
        [conditionLock lock];
        
        NSLog(@"NSConditionLock 1 加锁成功");
        
        sleep(2);
        
        [conditionLock unlock];
        
        NSLog(@"NSConditionLock 1 解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSLog(@"thread 2 = %@", [NSThread currentThread]);
        
        [conditionLock lockWhenCondition:0];
        
        NSLog(@"NSConditionLock 2 加锁成功");
        
        sleep(2);
        
        //解锁之后，修改 condition 的值
        [conditionLock unlockWithCondition:1];
        
        NSLog(@"NSConditionLock 2 解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSLog(@"thread 3 = %@", [NSThread currentThread]);
        
        //lockWhenCondition 与 lock 方法类似，加锁失败会阻塞线程，所以线程会被阻塞着。
        [conditionLock lockWhenCondition:1];
        
        NSLog(@"NSConditionLock 3 加锁成功");
        
        sleep(2);
        
        [conditionLock unlock];
        
        NSLog(@"NSConditionLock 3 解锁成功");
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSLog(@"thread 4 = %@", [NSThread currentThread]);
        
        [conditionLock lockWhenCondition:0 beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
        
        NSLog(@"NSConditionLock 4 加锁成功");
        
        sleep(2);
        
        [conditionLock unlock];
        
        NSLog(@"NSConditionLock 4 解锁成功");
    });
}

#pragma mark - NSCondition
- (void)NSConditionDemo
{
    /**
     NSCondition 是一种特殊类型的锁，通过它可以实现不同线程的调度。一个线程被某一个条件所阻塞，直到另一个线程满足该条件从而发送信号给该线程使得该线程可以正确的执行。比如说，你可以开启一个线程下载图片，一个线程处理图片。这样的话，需要处理图片的线程由于没有图片会阻塞，当下载线程下载完成之后，则满足了需要处理图片的线程的需求，这样可以给定一个信号，让处理图片的线程恢复运行。
     
     NSCondition 的对象实际上作为一个锁和一个线程检查器，锁上之后其它线程也能上锁，而之后可以根据条件决定是否继续运行线程，即线程是否要进入 waiting 状态，如果进入 waiting (挂起线程)状态，当其它线程中的该锁执行 signal(唤醒一条挂起线程) 或者 broadcast(唤醒所有挂起线程) 方法时，线程被唤醒，继续运行之后的方法。
     
     NSCondition 可以手动控制线程的挂起与唤醒，可以利用这个特性设置依赖。
     */
    
    NSCondition *condition = [[NSCondition alloc] init];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [condition lock];
        
        NSLog(@"condition thread 1 上锁");
        
        [condition wait];
        
        NSLog(@"condition thread 1 挂起");
        
        [condition unlock];
        
        NSLog(@"condition thread 1 解锁");
        
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [condition lock];
        
        NSLog(@"condition thread 2 上锁");
        
        if ([condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]]) {
            
            NSLog(@"condition thread 2 挂起");
            
            [condition unlock];
            
            NSLog(@"condition thread 2 解锁");
        }
        
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        sleep(5);
        
        //3s之后唤醒 signal没有唤醒thread2 造成死锁
        [condition signal];
    });
}

#pragma mark - dispatch_semaphore
- (void)dispatch_semaphoreDemo
{
    /**
     dispatch_semaphore 使用信号量机制实现锁，等待信号和发送信号。
     
     dispatch_semaphore 是 GCD 用来同步的一种方式，与他相关的只有三个函数，一个是创建信号量，一个是等待信号，一个是发送信号。
     dispatch_semaphore 的机制就是当有多个线程进行访问的时候，只要有一个获得了信号，其他线程的就必须等待该信号释放。
     */
    
    //创建一个 dispatch_semaphore_t 类型的信号量，设定信号量的初始值为 1 这里的传入的参数必须大于或等于 0，否则 dispatch_semaphore_create 会返回 NULL。
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 6 * NSEC_PER_SEC);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        //判断 semaphore 的信号值是否大于 0 大于 0 不会阻塞线程，消耗掉一个信号，执行后续任务。 如果信号值为 0，该线程会和 NSCondition 一样直接进入 waiting 状态，等待其他线程发送信号唤醒线程去执行后续任务，或者当 timeout 时限到了，也会执行后续任务。
        //lock unlock 只能同一时间，一个线程访问被保护的临界区，而如果 dispatch_semaphore 的信号量初始值为 x ，则可以有 x 个线程同时访问被保护的临界区。
        dispatch_semaphore_wait(semaphore, timeout);
        
        NSLog(@"线程1开始");
        
        sleep(5);
        
        NSLog(@"线程1结束");
        
        //发送信号，如果没有等待的线程接受信号，则使 signal 信号值加一（做到对信号的保存）
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        sleep(1);
        
        dispatch_semaphore_wait(semaphore, timeout);
        
        NSLog(@"线程2开始");
        
        dispatch_semaphore_signal(semaphore);
    });
    
    
#pragma mark - semaphore 控制并发数量例子 模拟UI界面图片一组一组展现
    
    dispatch_semaphore_t semaphore2 = dispatch_semaphore_create(10);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        for (NSInteger i=0; i< 100; i++) {
            
            dispatch_semaphore_wait(semaphore2, DISPATCH_TIME_FOREVER);
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                sleep(5);
                
                NSLog(@"i = %ld", i);
                
                dispatch_semaphore_signal(semaphore2);
            });
        }
    });
    
}

#pragma mark - 1. @synchronized(obj)
- (void)synchronizedDemo
{
    /**
     @synchronized(self) 指令使用的 self 为该锁的唯一标识，只有当标识相同时，才为满足互斥，如果线程 2 中的 @synchronized(self) 改为 @synchronized(self.view) ，那么线程 2 就不会被阻塞，@synchronized 指令实现锁的优点就是我们不需要在代码中显式的创建锁对象，便可以实现锁的机制，但作为一种预防措施，@synchronized 块会隐式的添加一个异常处理例程来保护代码，该处理例程会在异常抛出的时候自动的释放互斥锁。所以如果不想让隐式的异常处理例程带来额外的开销，你可以考虑使用锁对象。
     
     @sychronized(self){} 内部 self 被释放或被设为 nil 不会影响锁的功能，但如果 self 一开始就是 nil，那就会丢失了锁的功能了。
     */
    
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_queue_t queue2 = dispatch_get_global_queue(0, 0);
    
    dispatch_async(queue, ^{
        
        @synchronized (self) {
            
            NSLog(@"1 start");
            
            sleep(5);
            
            NSLog(@"1 end");
        }
    });
    
    
    dispatch_async(queue2, ^{
        
        @synchronized (self) {
            
            NSLog(@"2 start");
            
            sleep(5);
            
            NSLog(@"2 end");
        }
    });
}


#pragma mark - OSSpinLock
- (void)OSSpinLockDemo
{
    /**
     OSSpinLock 是一种自旋锁，和互斥锁类似，都是为了保证线程安全的锁。但二者的区别是不一样的，对于互斥锁，当一个线程获得这个锁之后，其他想要获得此锁的线程将会被阻塞，直到该锁被释放。但自旋锁不一样，当一个线程获得锁之后，其他线程将会一直循环在哪里查看是否该锁被释放。所以，此锁比较适用于锁的持有者保存时间较短的情况下。
     */
    
    __block OSSpinLock lock = OS_SPINLOCK_INIT;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        OSSpinLockLock(&lock);
        
        NSLog(@"OSSpinLock 1 加锁成功");
        
        sleep(5);
        
        OSSpinLockUnlock(&lock);
        
        NSLog(@"OSSpinLock 1 解锁成功");
        
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        OSSpinLockLock(&lock);
        
        NSLog(@"OSSpinLock 2 加锁成功");
        
        sleep(2);
        
        OSSpinLockUnlock(&lock);
        
        NSLog(@"OSSpinLock 2 解锁成功");
    });
    
}

@end
