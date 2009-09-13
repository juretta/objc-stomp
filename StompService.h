//
// StompService.h
// Objective-C Stomp Client
//
// Implements the Stomp Protocol v1.0, as described here: http://stomp.codehaus.org/Protocol
// Requires the AsyncSocket library: http://code.google.com/p/cocoaasyncsocket/
//
// This class is in the public domain.
// by Scott Raymond <sco@scottraymond.net>.
//
#import <Foundation/Foundation.h>
#import "AsyncSocket.h"

@class StompService;

@protocol StompServiceDelegate <NSObject>
- (void)stompServiceDidConnect:(StompService *)stompService;
- (void)stompService:(StompService *)stompService gotMessage:(NSString *)body withHeader:(NSDictionary *)messageHeader;
@optional
- (void)stompServiceDidDisconnect:(StompService *)stompService;
@end

@interface StompService : NSObject {
	id<StompServiceDelegate> delegate;
	AsyncSocket *sock;
	NSString *host;
	NSInteger port;
	NSString *login;
	NSString *passcode;
	NSString *sessionId;
}

@property (nonatomic, assign) id<StompServiceDelegate> delegate;
@property (nonatomic, retain) AsyncSocket *sock;
@property (nonatomic, retain) NSString *host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, retain) NSString *login;
@property (nonatomic, retain) NSString *passcode;

- (id)initWithHost:(NSString *)h port:(NSInteger)r login:(NSString *)l passcode:(NSString *)p delegate:(id<StompServiceDelegate>)d;

- (void)connect;
- (void)sendBody:(NSString *)body toDestination:(NSString *)destination;
- (void)subscribeToDestination:(NSString *)destination;
- (void)subscribeToDestination:(NSString *)destination withAck:(NSString *) ackMode;
- (void)subscribeToDestination:(NSString *)destination withHeader:(NSDictionary *) header;
- (void)unsubscribeToDestination:(NSString *)destination;
- (void)begin:(NSString *)transaction;
- (void)commit:(NSString *)transaction;
- (void)abort:(NSString *)transaction;
- (void)ack:(NSString *)messageId;
- (void)disconnect;

@end