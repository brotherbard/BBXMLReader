//
//  BBXMLParsingDescription.h
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


#import <Cocoa/Cocoa.h>


@class BBXMLParsingDescription;
@class BBXMLObjectCompletion;


// all model classes need to conform to this protocol <BBXMLModelObject>
@protocol BBXMLModelObject

+ (BBXMLParsingDescription *)xmlParsingDescription;

@end


// constants for special elements (to be used in class dictionaries)
extern NSString * const kBBXMLIgnoredElement;
extern NSString * const kBBXMLSkippedElement;
extern NSString * const kBBXMLXMLStringElement;
extern NSString * const kBBXMLArrayElement;



// for classes to define how to map XML element names to property/method setters
@interface BBXMLParsingDescription : NSObject
{
    Class                  _target;
    NSMutableDictionary   *_elementSetters;
    NSMutableDictionary   *_attributeSetters;
    BBXMLObjectCompletion *_completionSelector;
}

- (id)initWithTarget:(id)targetClass;
- (id)initWithArrayTarget;

- (NSMutableDictionary *)elementSetters;
- (NSMutableDictionary *)attributeSetters;
- (BBXMLObjectCompletion *)completionSelector;

- (void)addParsingCompletionSelector:(SEL)selector;
- (void)addIgnoredElement:(NSString *)elementName;
- (void)addSkippedElement:(NSString *)elementName;
- (void)addClassDictionary:(NSDictionary *)classDictionary;

- (void)addObjectSelector:(SEL)selector    ofClass:(Class)classType                            forElement:(NSString *)elementName;
- (void)addArraySelector:(SEL)selector     withClassDictionary:(NSDictionary *)classDictionary forElement:(NSString *)elementName;
- (void)addStringSelector:(SEL)selector    forElement:(NSString *)elementName;
- (void)addXMLStringSelector:(SEL)selector forElement:(NSString *)elementName;
- (void)addBoolSelector:(SEL)selector      forElement:(NSString *)elementName;
- (void)addFloatSelector:(SEL)selector     forElement:(NSString *)elementName;
- (void)addDoubleSelector:(SEL)selector    forElement:(NSString *)elementName;
- (void)addIntSelector:(SEL)selector       forElement:(NSString *)elementName;
- (void)addNSIntegerSelector:(SEL)selector forElement:(NSString *)elementName;
- (void)addLonglongSelector:(SEL)selector  forElement:(NSString *)elementName;

- (void)addStringSelector:(SEL)selector    forAttribute:(NSString *)attributeName;
- (void)addBoolSelector:(SEL)selector      forAttribute:(NSString *)attributeName;
- (void)addFloatSelector:(SEL)selector     forAttribute:(NSString *)attributeName;
- (void)addDoubleSelector:(SEL)selector    forAttribute:(NSString *)attributeName;
- (void)addIntSelector:(SEL)selector       forAttribute:(NSString *)attributeName;
- (void)addNSIntegerSelector:(SEL)selector forAttribute:(NSString *)attributeName;
- (void)addLonglongSelector:(SEL)selector  forAttribute:(NSString *)attributeName;

- (NSString *)debugDescription;

@end


#pragma mark -
#pragma mark Private
// classes private to BBXMLReader

//////////////////////////////////////////////////////////////////
@interface BBXMLArrayProxy : NSObject
{
    NSMutableArray *_array;
}
- (NSMutableArray *)array;
- (void)addObject:(id)object;

@end


//////////////////////////////////////////////////////////////////
@interface BBXMLSetter : NSObject
{
    SEL  _selector;
    BOOL _isLeafElement;
    BOOL _isIgnored;
    BOOL _shouldSkipElement;
    BOOL _shouldPreserveXMLContent;
}

- (id)initWithSelector:(SEL)selector;

- (void)setContent:(id)content onTarget:(id)target;

- (BOOL)isLeafElement;

- (void)setIgnoreElement:(BOOL)ignore;
- (BOOL)isIgnored;

- (void)setShouldSkipElement:(BOOL)skip;
- (BOOL)shouldSkipElement;

// warning: shouldPreserveXMLContent
//   1) does not preserve attributes
//   2) will create both a start and an end element for standalone empty elements
- (void)setShouldPreserveXMLContent:(BOOL)preserveXML;
- (BOOL)shouldPreserveXMLContent;

- (BBXMLParsingDescription *)parseDescription;

- (Class)classForObject;

- (NSString *)debugDescription;

@end


//////////////////////////////////////////////////////////////////
@interface BBXMLObjectCompletion : BBXMLSetter
{
    void (*_completionIMP)(id, SEL);
}
- (id)initWithSelector:(SEL)selector forClass:(Class)class;
- (void)finishedParsing:(id)target;
@end


//////////////////////////////////////////////////////////////////
@interface BBXMLObjectSetter : BBXMLSetter
{
    void (*_objectIMP)(id, SEL, id);
    Class _classForObject;
}
- (id)initWithSelector:(SEL)selector ofType:(Class)classType forClass:(Class)class;
@end


//////////////////////////////////////////////////////////////////
@interface BBXMLArraySetter : BBXMLObjectSetter
{
    BBXMLParsingDescription *_parseDescription;
}
- (id)initWithSelector:(SEL)selector forParseDescription:(BBXMLParsingDescription *)description forClass:(Class)class;
@end


//////////////////////////////////////////////////////////////////
@interface BBXMLStringSetter : BBXMLSetter
{
    void (*_stringIMP)(id, SEL, NSString *);
}
- (id)initWithSelector:(SEL)selector forClass:(Class)class;
@end


//////////////////////////////////////////////////////////////////
@interface BBXMLDoubleSetter : BBXMLSetter
{
    void (*_doubleIMP)(id, SEL, double);
}
- (id)initWithSelector:(SEL)selector forClass:(Class)class;
@end


//////////////////////////////////////////////////////////////////
@interface BBXMLFloatSetter : BBXMLSetter
{
    void (*_floatIMP)(id, SEL, float);
}
- (id)initWithSelector:(SEL)selector forClass:(Class)class;
@end


//////////////////////////////////////////////////////////////////
@interface BBXMLIntSetter : BBXMLSetter
{
    void (*_intIMP)(id, SEL, int);
}
- (id)initWithSelector:(SEL)selector forClass:(Class)class;
@end


//////////////////////////////////////////////////////////////////
@interface BBXMLNSIntegerSetter : BBXMLSetter
{
    void (*_integerIMP)(id, SEL, NSInteger);
}
- (id)initWithSelector:(SEL)selector forClass:(Class)class;
@end


//////////////////////////////////////////////////////////////////
@interface BBXMLLongLongSetter : BBXMLSetter
{
    void (*_longLongIMP)(id, SEL, long long);
}
- (id)initWithSelector:(SEL)selector forClass:(Class)class;
@end


//////////////////////////////////////////////////////////////////
@interface BBXMLBoolSetter : BBXMLSetter
{
    void (*_BOOLIMP)(id, SEL, BOOL);
}
- (id)initWithSelector:(SEL)selector forClass:(Class)class;
@end
