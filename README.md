STOMP client for Objective-C
============================

This is a slightly modified STOMP client based on

* http://gist.github.com/72935 from Scott Raymond <sco@scottraymond.net>
* and AsynSocket: http://code.google.com/p/cocoaasyncsocket/


Usage
-----

Add AsynSocket.{h,m} and StompService.{h,m} to your project.

MyExample.h

	#import <Foundation/Foundation.h>
	@protocol StompServiceDelegate;


	@interface MyExample : NSObject<StompServiceDelegate> {
    
	}
	@property(nonatomic, retain) StompService *service;

	@end


In MyExample.m

	-(void) aMethod {
		StompService *service = [[StompService alloc] 
				initWithHost:@"localhost" 
						port:61613 
						login:@"MYLOGINNAME" 
					passcode:@"MYLOGINPASSWORD" 
					delegate:self];
		[service connect];
	

		NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: 	
				@"client", @"ack", 
				@"true", @"activemq.dispatchAsync",
				@"1", @"activemq.prefetchSize", nil];
		[service subscribeToDestination:@"/queue/name-abc" withHeader: headers];
	
		[self setService: service];
		[service release];
	}
	
	#pragma mark StompServiceDelegate
	- (void)stompServiceDidConnect:(StompService *)stompService {
			NSLog(@"stompServiceDidConnect");
	}

	- (void)stompService:(StompService *)stompService gotMessage:(NSString *)body withHeader:(NSDictionary *)messageHeader {
		NSLog(@"gotMessage body: %@, header: %@", body, messageHeader);
		NSLog(@"Message ID: %@", [messageHeader valueForKey:@"message-id"]);
		// If we have successfully received the message ackknowledge it.
		[stompService ack: [messageHeader valueForKey:@"message-id"]];
	}
	
	- (void)dealloc {
		[service release];
		[super dealloc];
	}
	