//
//  BBLog.h
//
//  based on:
//    A Better NSLog() by AgentM
//      http://www.borkware.com/rants/agentm/mlog/
//
//  Created by BrotherBard on 1/8/09.
//  Copyright 2009 BrotherBard <nkinsinger at earthlink dot net>. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright notice, this
//       list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright notice,
//       this list of conditions and the following disclaimer in the documentation 
//       and/or other materials provided with the distribution.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//


#import <Cocoa/Cocoa.h>

// this will log in all build configurations
// example: BBError(@"message = %@", myMessageString);
//  output: 2009-01-08 10:00:15.983 BBApp[451] -[MyClass isDoingSomethingWrong]:112  message = some message
// 
#define BBError(s,...) [BBLogger logInfo:YES showTime:YES lineNumber:__LINE__  prettyFunction:__PRETTY_FUNCTION__ format:(s),##__VA_ARGS__]


#ifndef BBDEBUG

// when not running in debug mode these are NOP's
// use ';' to allow log macros in single line blocks
#define BBLog(s,...) ;
#define BBQLog(s,...) ;
#define BBMark ;

#else

// example: BBLog(@"message = %@", myMessageString);
//  output: -[MyClass isDoingSomethingWrong]:112  message = some message
// 
// example: BBQLog(@"message = %@", myMessageString);
//  output: message = some message
// 
// example: BBMark;
//  output: -[MyClass isDoingSomethingWrong]:112
// 
#define BBLog(s,...) [BBLogger logInfo:YES showTime:NO lineNumber:__LINE__  prettyFunction:__PRETTY_FUNCTION__ format:(s),##__VA_ARGS__]
#define BBQLog(s,...) [BBLogger logInfo:NO showTime:NO lineNumber:0  prettyFunction:NULL format:(s),##__VA_ARGS__]
#define BBMark [BBLogger logInfo:YES showTime:NO lineNumber:__LINE__  prettyFunction:__PRETTY_FUNCTION__ format:nil]

#endif

@interface BBLogger : NSObject
{
}
+(void)logInfo:(BOOL)logInfo showTime:(BOOL)showTime lineNumber:(int)lineNumber prettyFunction:(const char*)function format:(NSString*)format, ...;
@end
