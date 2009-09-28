//
//  BBXMLParsingDescription.m
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

#import "BBXMLParsingDescription.h"


// constants for special elements
NSString * const kBBXMLIgnoredElement   = @"kBBXMLIgnoredElement";
NSString * const kBBXMLSkippedElement   = @"kBBXMLSkippedElement";
NSString * const kBBXMLXMLStringElement = @"kBBXMLXMLStringElement";
NSString * const kBBXMLArrayElement     = @"kBBXMLArrayElement";



//////////////////////////////////////////////////////////////////////////
#pragma mark BBXMLParsingDescription
@implementation BBXMLParsingDescription


- (id)initWithTarget:(id)targetClass
{
    self = [super init];
    if (self == nil) return nil;
    
    _target           = [[targetClass class] retain];
    _elementSetters   = [[NSMutableDictionary alloc] init];
    _attributeSetters = [[NSMutableDictionary alloc] init];
    
    return self;
}


- (id)initWithArrayTarget
{
    self = [self initWithTarget:[BBXMLArrayProxy class]];
    if (self == nil) return nil;
    
    return self;
}


- (void)dealloc
{
    [_target release];
    [_elementSetters release];
    [_attributeSetters release];
    
    [super dealloc];
}



- (NSMutableDictionary *)elementSetters
{
    return _elementSetters;
}


- (NSMutableDictionary *)attributeSetters
{
    return _attributeSetters;
}


- (BBXMLObjectCompletion *)completionSelector
{
    return _completionSelector;
}


- (void)logErrorForSelector:(SEL)selector class:(Class)class
{
    BBQLog(@"**** %@ does not respond to %s, you must implement -[%@ %s] ****", [class className], sel_getName(selector), [class className], sel_getName(selector));
}


- (void)addParsingCompletionSelector:(SEL)selector
{
    if ([_target instancesRespondToSelector:selector])
        _completionSelector = [[BBXMLObjectCompletion alloc] initWithSelector:selector forClass:_target];
    else
        [self logErrorForSelector:selector class:_target];
}


#pragma mark Elements 
- (void)addIgnoredElement:(NSString *)elementName
{
    if (elementName) {
        BBXMLSetter *setter = [[[BBXMLSetter alloc] initWithSelector:nil] autorelease];
        [setter setIgnoreElement:YES];
        [_elementSetters setObject:setter forKey:elementName];
    }
}


- (void)addSkippedElement:(NSString *)elementName
{
    if (elementName) {
        BBXMLSetter *setter = [[[BBXMLSetter alloc] initWithSelector:nil] autorelease];
        [setter setShouldSkipElement:YES];
        [_elementSetters setObject:setter forKey:elementName];
    }
}


- (void)addObjectSelector:(SEL)selector ofClass:(Class)classType forElement:(NSString *)elementName
{
    if (elementName && selector && classType) {
        if ([_target instancesRespondToSelector:selector]) {
            id setter = [[[BBXMLObjectSetter alloc] initWithSelector:selector ofType:classType forClass:_target] autorelease];
            [_elementSetters setObject:setter forKey:elementName];
        }
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addClassDictionary:(NSDictionary *)classDictionary
{
    for (NSString *elementName in classDictionary) {
        id objectForElement = [classDictionary objectForKey:elementName];
        
        if (objectForElement == kBBXMLIgnoredElement)
            [self addIgnoredElement:elementName];
        else if (objectForElement == kBBXMLSkippedElement)
            [self addSkippedElement:elementName];
        else if (objectForElement == kBBXMLXMLStringElement)
            [self addXMLStringSelector:@selector(addObject:) forElement:elementName];
        else if ([objectForElement isKindOfClass:[NSDictionary class]])
            [self addArraySelector:@selector(addObject:) withClassDictionary:objectForElement forElement:elementName];
        else
            [self addObjectSelector:@selector(addObject:) ofClass:objectForElement forElement:elementName];
    }
}


- (void)addArraySelector:(SEL)selector withClassDictionary:(NSDictionary *)classDictionary forElement:(NSString *)elementName
{
    if (elementName && selector && classDictionary) {
        if ([_target instancesRespondToSelector:selector]) {
        BBXMLParsingDescription *description = [[[BBXMLParsingDescription alloc] initWithArrayTarget] autorelease];
        [description addClassDictionary:classDictionary];
        
        [_elementSetters setObject:[[[BBXMLArraySetter alloc] initWithSelector:selector forParseDescription:description forClass:_target] autorelease] forKey:elementName];
        }
        else
            [self logErrorForSelector:selector class:_target];
    }    
}


- (void)addStringSelector:(SEL)selector forElement:(NSString *)elementName
{
    if (elementName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_elementSetters setObject:[[[BBXMLStringSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:elementName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addXMLStringSelector:(SEL)selector forElement:(NSString *)elementName
{
    if (elementName) {
        if ([_target instancesRespondToSelector:selector]) {
            BBXMLStringSetter *setter = [[[BBXMLStringSetter alloc] initWithSelector:selector forClass:_target] autorelease];
            [setter setShouldPreserveXMLContent:YES];
            [_elementSetters setObject:setter forKey:elementName];
        }
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addBoolSelector:(SEL)selector forElement:(NSString *)elementName
{
    if (elementName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_elementSetters setObject:[[[BBXMLBoolSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:elementName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addFloatSelector:(SEL)selector forElement:(NSString *)elementName
{
    if (elementName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_elementSetters setObject:[[[BBXMLFloatSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:elementName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addDoubleSelector:(SEL)selector forElement:(NSString *)elementName
{
    if (elementName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_elementSetters setObject:[[[BBXMLDoubleSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:elementName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addIntSelector:(SEL)selector forElement:(NSString *)elementName
{
    if (elementName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_elementSetters setObject:[[[BBXMLIntSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:elementName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addNSIntegerSelector:(SEL)selector forElement:(NSString *)elementName
{
    if (elementName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_elementSetters setObject:[[[BBXMLNSIntegerSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:elementName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addLonglongSelector:(SEL)selector forElement:(NSString *)elementName
{
    if (elementName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_elementSetters setObject:[[[BBXMLLongLongSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:elementName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


//////////////////////////////////////////////////////////////////////////
#pragma mark Attributes 
- (void)addStringSelector:(SEL)selector forAttribute:(NSString *)attributeName
{
    if (attributeName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_attributeSetters setObject:[[[BBXMLStringSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:attributeName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addBoolSelector:(SEL)selector forAttribute:(NSString *)attributeName
{
    if (attributeName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_attributeSetters setObject:[[[BBXMLBoolSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:attributeName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addFloatSelector:(SEL)selector forAttribute:(NSString *)attributeName
{
    if (attributeName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_attributeSetters setObject:[[[BBXMLFloatSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:attributeName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addDoubleSelector:(SEL)selector forAttribute:(NSString *)attributeName
{
    if (attributeName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_attributeSetters setObject:[[[BBXMLDoubleSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:attributeName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addIntSelector:(SEL)selector forAttribute:(NSString *)attributeName
{
    if (attributeName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_attributeSetters setObject:[[[BBXMLIntSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:attributeName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addNSIntegerSelector:(SEL)selector forAttribute:(NSString *)attributeName
{
    if (attributeName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_attributeSetters setObject:[[[BBXMLNSIntegerSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:attributeName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (void)addLonglongSelector:(SEL)selector forAttribute:(NSString *)attributeName
{
    if (attributeName && selector) {
        if ([_target instancesRespondToSelector:selector])
            [_attributeSetters setObject:[[[BBXMLLongLongSetter alloc] initWithSelector:selector forClass:_target] autorelease] forKey:attributeName];
        else
            [self logErrorForSelector:selector class:_target];
    }
}


- (NSString *)debugDescription
{
    NSMutableString *theDescription = [NSMutableString string];
    
    [theDescription appendString:@"BBXMLParsingDescription\n"];
    [theDescription appendString:@"=========================================\n"];
    [theDescription appendFormat:@"    target = %@\n", [_target className]];
    if (_completionSelector)
        [theDescription appendFormat:@"%@", [_completionSelector debugDescription]];
    for (NSString *elementName in _elementSetters)
        [theDescription appendFormat:@"\n  elementName = %@\n%@", elementName, [[_elementSetters objectForKey:elementName] debugDescription]];
    for (NSString *attributeName in _attributeSetters)
        [theDescription appendFormat:@"\n  attributeName = %@\n%@", attributeName, [[_elementSetters objectForKey:attributeName] debugDescription]];
    
    return theDescription;
}

@end

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////


#pragma mark -
#pragma mark Private Classes
@implementation BBXMLSetter


- (id)initWithSelector:(SEL)selector
{   
    self = [super init];
    if (self == nil) return nil;
    
    _selector = selector;
    _isLeafElement = YES;
    _isIgnored = NO;
    _shouldSkipElement = NO;
    
    return self;
}


- (void)setContent:(id)content onTarget:(id)target
{
    // will be implemented by subclasses
}


- (BOOL)isLeafElement
{
    return _isLeafElement;
}


- (void)setIgnoreElement:(BOOL)ignore
{
    _isIgnored = ignore;
}


- (BOOL)isIgnored
{
    return _isIgnored;
}


- (void)setShouldSkipElement:(BOOL)skip
{
    _shouldSkipElement = skip;
}


- (BOOL)shouldSkipElement
{
    return _shouldSkipElement;
}


- (void)setShouldPreserveXMLContent:(BOOL)preserveXML
{
    _shouldPreserveXMLContent = preserveXML;
}


- (BOOL)shouldPreserveXMLContent
{
    return _shouldPreserveXMLContent;
}


- (BBXMLParsingDescription *)parseDescription
{
    // may be implemented by some subclasses
    return nil;
}


- (Class)classForObject
{
    // may be implemented by some subclasses
    return nil;
}


- (NSString *)debugDescription
{
    NSMutableString *theDescription = [NSMutableString string];
    
    [theDescription appendFormat:@"    %@\n", [self class]];
    [theDescription appendString:@"    =========================================\n"];
    [theDescription appendFormat:@"    isLeafElement = %@\n", _isLeafElement ? @"YES" : @"NO"];
    [theDescription appendFormat:@"    selector = %s\n", sel_getName(_selector)];
    
    return theDescription;
}


@end


@implementation BBXMLObjectCompletion

- (id)initWithSelector:(SEL)selector forClass:(Class)class
{
    self = [super initWithSelector:selector];
    if (self == nil) return nil;
    
    _completionIMP = (void (*)(id,SEL))[class instanceMethodForSelector:selector];
    
    return self;
}


- (void)finishedParsing:(id)target
{
    _completionIMP(target, _selector);
}

@end


@implementation BBXMLObjectSetter

- (id)initWithSelector:(SEL)selector ofType:(Class)classType forClass:(Class)class
{
    self = [super initWithSelector:selector];
    if (self == nil) return nil;
    
    _objectIMP = (void (*)(id,SEL,id))[class instanceMethodForSelector:selector];
    _classForObject = [classType retain];
    _isLeafElement = NO;
    
    return self;
}


- (void)dealloc
{
    [_classForObject release];
    
    [super dealloc];
}


- (void)setContent:(id)content onTarget:(id)target
{
    _objectIMP(target, _selector, content);
}


- (BBXMLParsingDescription *)parseDescription
{
    return [_classForObject xmlParsingDescription];
}


- (Class)classForObject
{
    return _classForObject;
}


- (NSString *)debugDescription
{
    NSMutableString *theDescription = [NSMutableString string];
    
    [theDescription appendString:[super debugDescription]];
    [theDescription appendFormat:@"    classForObject = %@\n", [_classForObject className]];
    
    return theDescription;
}

@end


@implementation BBXMLArraySetter

- (id)initWithSelector:(SEL)selector forParseDescription:(BBXMLParsingDescription *)description forClass:(Class)class
{
    self = [super initWithSelector:selector ofType:[BBXMLArrayProxy class] forClass:class];
    if (self == nil) return nil;
    
    _parseDescription = [description retain];
    
    return self;
}


- (void)dealloc
{
    [_parseDescription release];
    
    [super dealloc];
}


- (void)setContent:(id)content onTarget:(id)target
{
    _objectIMP(target, _selector, [content array]);
}


- (BBXMLParsingDescription *)parseDescription
{
    return _parseDescription;
}


- (NSString *)debugDescription
{
    NSMutableString *theDescription = [NSMutableString string];
    
    [theDescription appendString:[super debugDescription]];
    [theDescription appendString:[_parseDescription debugDescription]];
    
    return theDescription;
}

@end


@implementation BBXMLStringSetter

- (id)initWithSelector:(SEL)selector forClass:(Class)class
{
    self = [super initWithSelector:selector];
    if (self == nil) return nil;
    
    _stringIMP = (void (*)(id,SEL,NSString *))[class instanceMethodForSelector:selector];
    
    return self;
}


- (void)setContent:(id)content onTarget:(id)target
{
    _stringIMP(target, _selector, content);
}

@end


@implementation BBXMLDoubleSetter

- (id)initWithSelector:(SEL)selector forClass:(Class)class
{
    self = [super initWithSelector:selector];
    if (self == nil) return nil;
    
    _doubleIMP = (void (*)(id,SEL,double))[class instanceMethodForSelector:selector];
    
    return self;
}


- (void)setContent:(id)content onTarget:(id)target
{
    _doubleIMP(target, _selector, [content doubleValue]);
}

@end


@implementation BBXMLFloatSetter

- (id)initWithSelector:(SEL)selector forClass:(Class)class
{
    self = [super initWithSelector:selector];
    if (self == nil) return nil;
    
    _floatIMP = (void (*)(id,SEL,float))[class instanceMethodForSelector:selector];
    
    return self;
}


- (void)setContent:(id)content onTarget:(id)target
{
    _floatIMP(target, _selector, [content floatValue]);
}

@end


@implementation BBXMLIntSetter

- (id)initWithSelector:(SEL)selector forClass:(Class)class
{
    self = [super initWithSelector:selector];
    if (self == nil) return nil;
    
    _intIMP = (void (*)(id,SEL,int))[class instanceMethodForSelector:selector];
    
    return self;
}


- (void)setContent:(id)content onTarget:(id)target
{
    _intIMP(target, _selector, [content intValue]);
}

@end


@implementation BBXMLNSIntegerSetter

- (id)initWithSelector:(SEL)selector forClass:(Class)class
{
    self = [super initWithSelector:selector];
    if (self == nil) return nil;
    
    _integerIMP = (void (*)(id,SEL,NSInteger))[class instanceMethodForSelector:selector];
    
    return self;
}


- (void)setContent:(id)content onTarget:(id)target
{
    _integerIMP(target, _selector, [content integerValue]);
}

@end


@implementation BBXMLLongLongSetter

- (id)initWithSelector:(SEL)selector forClass:(Class)class
{
    self = [super initWithSelector:selector];
    if (self == nil) return nil;
    
    _longLongIMP = (void (*)(id,SEL,long long))[class instanceMethodForSelector:selector];
    
    return self;
}


- (void)setContent:(id)content onTarget:(id)target
{
    _longLongIMP(target, _selector, [content longLongValue]);
}

@end


@implementation BBXMLBoolSetter

- (id)initWithSelector:(SEL)selector forClass:(Class)class
{
    self = [super initWithSelector:selector];
    if (self == nil) return nil;
    
    _BOOLIMP = (void (*)(id,SEL,BOOL))[class instanceMethodForSelector:selector];
    
    return self;
}

// some boolean XML values are of the type <element/> or <element></element>
// if they don't exist then there is no element for the parser to find (and we never get here)
// if it finds it then it's true (but there is no content to test against)
- (void)setContent:(id)content onTarget:(id)target
{
    if ([content boolValue] || [content isEqualToString:@""])
        _BOOLIMP(target, _selector, YES);
    else
        _BOOLIMP(target, _selector, NO);
}

@end







@implementation BBXMLArrayProxy

- (id)init
{
    self = [super init];
    if (self == nil) return nil;
    
    _array = [[NSMutableArray alloc] init];
    
    return self;
}

- (void)dealloc
{
    [_array release];
    [super dealloc];
}

- (NSMutableArray *)array
{
    return _array;
}

- (void)addObject:(id)object
{
    if (object)
        [_array addObject:object];
}

@end

