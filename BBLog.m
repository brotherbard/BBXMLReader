//
//  BBLog.m
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


#ifndef NDEBUG

#import "BBLog.h"


@implementation BBLogger

+(void)logInfo:(BOOL)logInfo showTime:(BOOL)showTime lineNumber:(int)lineNumber prettyFunction:(char*)function format:(NSString*)format, ...;
{
	NSString *message = @"";
    NSString *logOutput = nil;
	va_list ap;
	
	va_start(ap,format);
    if (format)
        message = [[NSString alloc] initWithFormat:format arguments:ap];
	va_end(ap);
    	
    if (logInfo)
        logOutput = [[NSString alloc] initWithFormat:@"%s:%d:  %@", function, lineNumber, message];
	else
        logOutput =  [message retain];
    
    if (showTime)
        NSLog(@"%@", logOutput);
    else
        printf ("%s\n", [logOutput UTF8String]);
	
	[message release];
	[logOutput release];
}

@end

#endif
