//
//  BBXMLReader.m
//
//  Created by BrotherBard on 8/15/08.
//  Copyright 2008-2009 BrotherBard <nkinsinger at brotherbard dot com>. All rights reserved.
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

#import "BBXMLReader.h"



// Private class
@interface BBElementObject : NSObject
{
    BBXMLParsingDescription *parseDescription;
    id                       object;
    NSString                *objectElementName;
    
    BBXMLSetter             *currentChildSetter;
}
@property (nonatomic, retain) BBXMLParsingDescription *parseDescription;
@property (nonatomic, retain) id                       object;
@property (nonatomic, copy)   NSString                *objectElementName;
@property (nonatomic, retain) BBXMLSetter             *currentChildSetter;

- (id)initWithParsingDescription:(BBXMLParsingDescription *)description forObject:(id)newObject withElementName:(NSString *)name;

@end



// Private method
@interface BBXMLReader()
- (NSArray *)parseObjectsInClassDictionary:(NSDictionary *)classDictionary fromXMLData:(NSData *)XMLData;
@end



//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark BBXMLReader
@implementation BBXMLReader


- (void)dealloc
{   
    //[_parser release];
    [_currentElementObject release];
    [_objectStack release];
    
    [super dealloc];
}


#pragma mark Public methods
+ (NSArray *)objectsInClassDictionary:(NSDictionary *)classDictionary fromXMLData:(NSData *)XMLData
{
    if (([classDictionary count] == 0) || [XMLData length] == 0)
        return nil;
    
    BBXMLReader *reader = [[self alloc] init];
    NSArray *replyObjects = [reader parseObjectsInClassDictionary:classDictionary fromXMLData:XMLData];
    [reader release];
    
    return replyObjects;
}


+ (NSArray *)objectsInClassDictionary:(NSDictionary *)classDictionary fromXMLString:(NSString *)XMLString
{
    if (([classDictionary count] == 0) || [XMLString isEqualToString:@""])
        return nil;
    
    return [self objectsInClassDictionary:classDictionary fromXMLData:[XMLString dataUsingEncoding:NSUTF8StringEncoding]];
}


+ (id)objectOfClass:(Class)class withElementName:(NSString *)elementName fromXMLString:(NSString *)XMLString
{
    if ((class == nil) || [XMLString isEqualToString:@""] || [elementName isEqualToString:@""])
        return nil;
    
    NSArray *replyObjects = [self objectsInClassDictionary:[NSDictionary dictionaryWithObject:class forKey:elementName] fromXMLString:XMLString];
    
    return [replyObjects count] ? [replyObjects objectAtIndex:0] : nil;
}


+ (id)objectOfClass:(Class)class withElementName:(NSString *)elementName fromXMLData:(NSData *)XMLData
{
    if ((class == nil) || ([XMLData length] == 0) || [elementName isEqualToString:@""])
        return nil;
    
    NSArray *replyObjects = [self objectsInClassDictionary:[NSDictionary dictionaryWithObject:class forKey:elementName] fromXMLData:XMLData];
    
    return [replyObjects count] ? [replyObjects objectAtIndex:0] : nil;
}


#pragma mark Private methods
- (NSArray *)parseObjectsInClassDictionary:(NSDictionary *)classDictionary fromXMLData:(NSData *)XMLData
{   
    if ((classDictionary == nil) || (XMLData == nil))
        return nil;
    
    _parserPool = [[NSAutoreleasePool alloc] init];
    _poolCounter = 0;
    
    // kick start things by setting up the object stack with a topLevelObjects array and the classDictionary the caller sent us
    BBXMLArrayProxy *topLevelObjects = [[BBXMLArrayProxy alloc] init];
    
    BBXMLParsingDescription *description = [[[BBXMLParsingDescription alloc] initWithArrayTarget] autorelease];
    [description addClassDictionary:classDictionary];
    
    _currentElementObject = [[BBElementObject alloc] initWithParsingDescription:description forObject:topLevelObjects withElementName:nil];
    
    _objectStack = [[NSMutableArray alloc] init];
    
    [_objectStack addObject:_currentElementObject];
    
    // Begin parsing
    _parser = [[NSXMLParser alloc] initWithData:XMLData];
    [_parser setDelegate:self];
    
    BOOL success = [_parser parse];
    if (success == NO) {
        BBLog(@"XMLReader  Failure to parse XML, error = %@", [_parser parserError]);
    }
    [_parser release];
    
    // get the objects from the array proxy
    NSArray *replyObjects = [[topLevelObjects array] retain];
    [topLevelObjects release];
    
    [_parserPool release];
    return [replyObjects autorelease];
}


- (void)parser:(NSXMLParser *)theParser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    if (_poolCounter++ == 50) {
        [_parserPool release];
        _parserPool = [[NSAutoreleasePool alloc] init];
        _poolCounter = 0;
    }
    
    if (_parsingIgnoredElement)
        return;
    
    if ([_currentElementObject.currentChildSetter shouldPreserveXMLContent]) {
        [_currentChildContent appendFormat:@"<%@>", elementName];
        return;
    }
    
    BBXMLSetter *setterForElement = [[_currentElementObject.parseDescription elementSetters] objectForKey:elementName];
        
    // when parsing an object, don't allow parsing any unknown/ignored element's children
    if (   ((setterForElement == nil) && (_currentElementObject.objectElementName != nil))
        || [setterForElement isIgnored])
    {
        _ignoredElementName = [elementName retain];
        _parsingIgnoredElement = YES;
        return;
    }
    
    if ((setterForElement == nil) || [setterForElement shouldSkipElement])
        return;
    
    _currentElementObject.currentChildSetter = setterForElement;
    
    if ([setterForElement isLeafElement]) {
        // the element is data for an existing object
        _currentChildContent = [[NSMutableString alloc] init];
        _currentChildElementName = [elementName retain];
    } else {
        // the element is an object
        [_currentElementObject release];
        _currentElementObject = 
        [[BBElementObject alloc] initWithParsingDescription:[setterForElement parseDescription] 
                                                  forObject:[[[[setterForElement classForObject] alloc] init] autorelease]
                                            withElementName:elementName];
        [_objectStack addObject:_currentElementObject];
    }
    
    // parse attributes
    NSDictionary *attributeSetters = [_currentElementObject.parseDescription attributeSetters];
    if (attributeSetters != nil)
        for (NSString *attributeName in attributeDict) {
            BBXMLSetter *setterForAttribute = [attributeSetters objectForKey:attributeName];
            [setterForAttribute setContent:[attributeDict objectForKey:attributeName]
                                  onTarget:_currentElementObject.object];
        }
}


// only add characters if we are parsing an element that has a setter
- (void)parser:(NSXMLParser *)theParser foundCharacters:(NSString *)characters
{
    if (_currentElementObject.currentChildSetter != nil)
        [_currentChildContent appendString:characters];
}


- (void)parser:(NSXMLParser *)theParser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
{
    if (_parsingIgnoredElement) {
        if ([_ignoredElementName isEqualToString:elementName]) {
            [_ignoredElementName release];
            _ignoredElementName = nil;
            _parsingIgnoredElement = NO;
        }
        return;
    }
    
    if (([_currentElementObject.currentChildSetter shouldPreserveXMLContent]) && ([_currentChildElementName isEqualToString:elementName] == NO)) {
        [_currentChildContent appendFormat:@"</%@>", elementName];
        return;
    }
    
    if (_currentElementObject.currentChildSetter != nil) {
        if ([_currentChildElementName isEqualToString:elementName]) {
            [(_currentElementObject.currentChildSetter) setContent:_currentChildContent 
                                                          onTarget:_currentElementObject.object];
            _currentElementObject.currentChildSetter = nil;
            [_currentChildContent release];
            _currentChildContent = nil;
            [_currentChildElementName release];
            _currentChildElementName = nil;
        }
        return;
    }
    
    if ([_currentElementObject.objectElementName isEqualToString:elementName]) {
        id childObject = [_currentElementObject.object retain];
        [[_currentElementObject.parseDescription completionSelector] finishedParsing:childObject];
        
        [_currentElementObject release];
        [_objectStack removeLastObject];
        _currentElementObject = [[_objectStack lastObject] retain];
        [(_currentElementObject.currentChildSetter) setContent:childObject 
                                                      onTarget:_currentElementObject.object];
        _currentElementObject.currentChildSetter = nil;
        [childObject release];
    }
}


- (void)parser:(NSXMLParser *)theParser parseErrorOccurred:(NSError *)parseError
{
    BBError(@"BBXMLReader: parsing error occurred: %@", parseError);
}


@end




//////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark BBElementObject
// Private class
@implementation BBElementObject


@synthesize parseDescription;
@synthesize object;
@synthesize objectElementName;
@synthesize currentChildSetter;


- (id)initWithParsingDescription:(BBXMLParsingDescription *)description forObject:(id)newObject withElementName:(NSString *)name
{
    self = [super init];
    if (self == nil) return nil;
    
    parseDescription = [description retain];
    object = [newObject retain];
    objectElementName = [name copy];
    
    return self;
}


- (void)dealloc
{
    [parseDescription release];
    [object release];
    [objectElementName release];
    [currentChildSetter release];
    
    [super dealloc];
}


@end
