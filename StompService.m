#import "StompService.h"

// private methods
@interface StompService ()
- (void)sendCommand:(NSString *)cmd headers:(NSDictionary *)headers body:(NSString *)body;
- (void)receiveCommand:(NSString *)cmd headers:(NSDictionary *)headers body:(NSString *)body;
- (void)readFrame;
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag;
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag;
- (void)onSocketDidDisconnect:(AsyncSocket *)sock;
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err;
@end

@implementation StompService

@synthesize delegate, sock, host, port, login, passcode;

- (id)initWithHost:(NSString *)h port:(NSInteger)r login:(NSString *)l passcode:(NSString *)p delegate:(id<StompServiceDelegate>)d {
	if (self = [super init]) {
		self.delegate = d;
		AsyncSocket *aSock = [[AsyncSocket alloc] initWithDelegate:self];
		self.sock = aSock;
		[aSock release];
		self.host = h;
		self.port = r;
		self.login = l;
		self.passcode = p;
		NSError *err = nil;
		if(![self.sock connectToHost:self.host onPort:self.port error:&err]) {
			NSLog(@"StompService error: %@", err);
		}
    }
    return self;
}

- (void)connect {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:self.login, @"login", self.passcode, @"passcode", nil];
    [self sendCommand:@"CONNECT" headers:headers body:nil];
	[self readFrame];
}

- (void)sendBody:(NSString *)body toDestination:(NSString *)destination {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: destination, @"destination", nil];
    [self sendCommand:@"SEND" headers:headers body:body];
}

- (void)subscribeToDestination:(NSString *)destination {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: destination, @"destination", @"auto", @"ack", nil];
    [self sendCommand:@"SUBSCRIBE" headers:headers body:nil];
}

- (void)subscribeToDestination:(NSString *)destination withHeader:(NSDictionary *) header {
	NSMutableDictionary *headers = [[NSMutableDictionary alloc] initWithDictionary:header];
	[headers setObject:destination forKey:@"destination"];
    [self sendCommand:@"SUBSCRIBE" headers:headers body:nil];	
	[headers release];
}

- (void)unsubscribeToDestination:(NSString *)destination {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: destination, @"destination", nil];
    [self sendCommand:@"UNSUBSCRIBE" headers:headers body:nil];
}

- (void)begin:(NSString *)transaction {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: transaction, @"transaction", nil];
    [self sendCommand:@"BEGIN" headers:headers body:nil];
}

- (void)commit:(NSString *)transaction {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: transaction, @"transaction", nil];
    [self sendCommand:@"COMMIT" headers:headers body:nil];
}

- (void)abort:(NSString *)transaction {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: transaction, @"transaction", nil];
    [self sendCommand:@"ABORT" headers:headers body:nil];
}

- (void)ack:(NSString *)messageId {
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys: messageId, @"message-id", nil];
    [self sendCommand:@"ACK" headers:headers body:nil];
}

- (void)disconnect {
    [self sendCommand:@"DISCONNECT" headers:nil body:nil];
	[self.sock disconnect];
}


#pragma mark - private methods

- (void)sendCommand:(NSString *)command headers:(NSDictionary *)headers body:(NSString *)body {
    NSMutableString *frameString = [NSMutableString stringWithString: [command stringByAppendingString:@"\n"]];
	NSEnumerator *enumerator = [headers keyEnumerator];
	NSString *key;
	while (key = [enumerator nextObject]) {
		[frameString appendString:key];
		[frameString appendString:@":"];
		[frameString appendString:[headers objectForKey:key]];
		[frameString appendString:@"\n"];
	}
	if (body!=nil) {
		[frameString appendString:@"\n"];
		[frameString appendString:body];
	}
    [frameString appendString:[NSString stringWithFormat:@"\n%C", 0]]; // control char
	[self.sock writeData:[frameString dataUsingEncoding:NSASCIIStringEncoding] withTimeout:5 tag:123];
}

-(void)receiveCommand:(NSString *)command headers:(NSDictionary *)headers body:(NSString *)body {
	if([command isEqual:@"CONNECTED"]) {
		[self.delegate stompServiceDidConnect:self];
	} else if([command isEqual:@"MESSAGE"]) {
		[self.delegate stompService:self gotMessage:body withHeader:headers];
	} else if([command isEqual:@"RECEIPT"]) {
	} else if([command isEqual:@"ERROR"]) {
	}
}

- (void)readFrame {
	[self.sock readDataToData:[AsyncSocket ZeroData] withTimeout:-1 tag:0];
}



-(void) dealloc {
	delegate = nil;
	[sock release];
	[host release];
	[login release];
	[passcode release];
	[super dealloc];
}


#pragma mark - asyncsocket delegate methods

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {
	NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
	NSString *msg = [[[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding] autorelease];
    NSMutableArray *contents = (NSMutableArray *)[msg componentsSeparatedByString:@"\n"];
	if([[contents objectAtIndex:0] isEqual:@""]) {
		[contents removeObjectAtIndex:0];
	}
	NSString *command = [[[contents objectAtIndex:0] copy] autorelease];
	NSMutableDictionary *headers = [[[NSMutableDictionary alloc] init] autorelease];
	NSMutableString *body = [[[NSMutableString alloc] init] autorelease];
	BOOL hasHeaders = NO;
    [contents removeObjectAtIndex:0];
	for(NSString *line in contents) {
		if(hasHeaders) {
			[body appendString:line];
		} else {
			if ([line isEqual:@""]) {
				hasHeaders = YES;
			} else {
				// message-id can look like this: message-id:ID:macbook-pro.local-50389-1237007652070-5:6:-1:1:1
				NSMutableArray *parts = [NSMutableArray arrayWithArray:[line componentsSeparatedByString:@":"]];
				// key ist the first part
				NSString *key = [parts objectAtIndex:0];
				[parts removeObjectAtIndex:0];
				[headers setObject:[parts componentsJoinedByString:@":"] forKey:key];
			}
		}
	}
	[self receiveCommand:command headers:headers body:body];
	[self readFrame];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	[self connect];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
}

@end


// This initialization function gets called when we import the Ruby module.
// It doesn't need to do anything because the RubyCocoa bridge will do
// all the initialization work.
// The rbiphonetest test framework automatically generates bundles for 
// each objective-c class containing the following line. These
// can be used by your tests.
void Init_StompService() { }