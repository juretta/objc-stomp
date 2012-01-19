//
//  CRVStompClient.h
//  Objc-Stomp
//
//
//  Implements the Stomp Protocol v1.0
//  See: http://stomp.codehaus.org/Protocol
// 
//  Requires the AsyncSocket library
//  See: http://code.google.com/p/cocoaasyncsocket/
//  
//  See: LICENSE
//	Stefan Saasen <stefan@coravy.com>
//  Based on StompService.{h,m} by Scott Raymond <sco@scottraymond.net>.


#import <Foundation/Foundation.h>
#import "AsyncSocket.h"

@class CRVStompClient;

typedef enum {
	CRVStompAckModeAuto,
	CRVStompAckModeClient
} CRVStompAckMode;

@protocol CRVStompClientDelegate <NSObject>
- (void)stompClient:(CRVStompClient *)stompService messageReceived:(NSString *)body withHeader:(NSDictionary *)messageHeader;

@optional
- (void)stompClientDidDisconnect:(CRVStompClient *)stompService;
- (void)stompClientDidConnect:(CRVStompClient *)stompService;
- (void)serverDidSendReceipt:(CRVStompClient *)stompService withReceiptId:(NSString *)receiptId;
- (void)serverDidSendError:(CRVStompClient *)stompService withErrorMessage:(NSString *)description detailedErrorMessage:(NSString *) theMessage;
@end

@interface CRVStompClient : NSObject {
	@private
	id<CRVStompClientDelegate> delegate;
	AsyncSocket *socket;
	NSString *host;
	NSUInteger port;
	NSString *login;
	NSString *passcode;
	NSString *sessionId;
	BOOL doAutoconnect;
	BOOL anonymous;
}

@property (nonatomic, assign) id<CRVStompClientDelegate> delegate;

- (id)initWithHost:(NSString *)theHost 
			  port:(NSUInteger)thePort 
			 login:(NSString *)theLogin
		  passcode:(NSString *)thePasscode 
		  delegate:(id<CRVStompClientDelegate>)theDelegate;

- (id)initWithHost:(NSString *)theHost 
			  port:(NSUInteger)thePort 
			 login:(NSString *)theLogin
		  passcode:(NSString *)thePasscode 
		  delegate:(id<CRVStompClientDelegate>)theDelegate
	   autoconnect:(BOOL) autoconnect;

/**
 * Connects as an anonymous user. Suppresses "login" and "passcode" headers.
 */
- (id)initWithHost:(NSString *)theHost 
			  port:(NSUInteger)thePort 
		  delegate:(id<CRVStompClientDelegate>)theDelegate
	   autoconnect:(BOOL) autoconnect;

- (void)connect;
- (void)sendMessage:(NSString *)theMessage toDestination:(NSString *)destination;
- (void)sendMessage:(NSString *)theMessage toDestination:(NSString *)destination withHeaders:(NSDictionary*)headers;
- (void)subscribeToDestination:(NSString *)destination;
- (void)subscribeToDestination:(NSString *)destination withAck:(CRVStompAckMode) ackMode;
- (void)subscribeToDestination:(NSString *)destination withHeader:(NSDictionary *) header;
- (void)unsubscribeFromDestination:(NSString *)destination;
- (void)begin:(NSString *)transactionId;
- (void)commit:(NSString *)transactionId;
- (void)abort:(NSString *)transactionId;
- (void)ack:(NSString *)messageId;
- (void)disconnect;

@end