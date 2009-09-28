BBXMLReader
===========
---


Description
-----------

BBXMLReader is an XML to Objective-C object parser. That means it takes an XML string and creates objects that have data from the XML stored in them.

BBXMLReader was inspired by Apple's SeismicXML sample project. I have added some features to make it more useful and to address some limitations and performance issues. It is built on top of NSXMLParser, and so won't have any better performance then it does.

I created it because I was reading a large number of different XML-RPC messages and I wanted an easy way to create the definitions for each message and all the objects in them.

BBXMLReader works on Mac OS X 10.5+. It should work with the iPhone OS but I've never tested it.

BBXMLReader is released under a BSD license by nkinsinger at brotherbard com.


Usage
-----

The simplest case is to create a single instance of a given class from an XML element:

	MyBookList *bookList = [BBXMLReader objectOfClass:[MyBookList class] withElementName:@"books" fromXMLString:xmlString];

An array of instances can also be created:

	NSDictionary *classDict = [NSDictionary dictionaryWithObject:[MyBook class] forKey:@"book"];
	NSArray *bookList = [BBXMLReader objectsInClassDictionary:classDict fromXMLString:xmlString];

When reading an array of items, instances of different classes can be created:

	NSDictionary *classDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               [Dog class], @"dog", 
                               [Cat class], @"cat", 
                               [Bird class], @"bird", 
                               nil];
	NSArray *pets = [BBXMLReader objectsInClassDictionary:classDict fromXMLString:xmlString];

There is an alternate version of each of the above two methods that accept XML in NSData form (see BBXMLReader.h).


Parsing Descriptions
--------------------

Each class that is to be read needs to have a parsing description and conform to the `<BBXMLModelObject>` protocol (in BBXMLParsingDescription.h).

	@protocol BBXMLModelObject
	
	+ (BBXMLParsingDescription *)xmlParsingDescription;
	
	@end

An example for a simple Book class:

	+ (BBXMLParsingDescription *)xmlParsingDescription
	{
		static BBXMLParsingDescription *parseDescription = nil;
		if (parseDescription) 
			return parseDescription;
		
		parseDescription = [[BBXMLParsingDescription alloc] initWithTarget:self];
		[parseDescription addStringSelector:@selector(setISBN:) forElement:@"ISBN"];
		[parseDescription addStringSelector:@selector(setTitle:) forElement:@"title"];
		[parseDescription addArraySelector:@selector(setAuthors:) withClassDictionary:[NSDictionary dictionaryWithObject:[Author class] forKey:@"author"] forElement:@"authors"];
		[parseDescription addNSIntegerSelector:@selector(setPages:) forElement:@"pages"];
		[parseDescription addBoolSelector:@selector(isCheckedOut:) forElement:@"checked_out"];
		[parseDescription addObjectSelector:@selector(setPublisher:) ofClass:[Publisher class] forElement:@"publisher"];
		
		return parseDescription;
	}

When the XML is being parsed the setter for each element will be called with the type as specified. If there is not type for what you need then use the string selector and convert it to whatever you need. For example there is no date type, instead use an NSDateFormatter to convert the string representing a date to an NSDate.

	[parseDescription addStringSelector:@selector(setPublishedDateFromXML:) forElement:@"date_published"];

The order that selectors are added to the description does not matter, put them in the order that makes the most sense to you.


String Elements
---------------

The content of an XML element as an NSString:

	[parseDescription addStringSelector:@selector(setTitle:) forElement:@"title"];

You can store the entire content of an element and all it's child elements as a full XML string. This is useful to store a string that may have HTML like formatting tags in it. There may be some changes to the actual string, such as empty elements will have both a start tag and and end tag, but the meaning of the XML will not change.

	[parseDescription addXMLStringSelector:@selector(setDescriptionHTML:) forElement:@"description"];


Numerical Elements
------------------

There are methods for adding several different types of numbers:

	[parseDescription addFloatSelector:@selector(setAge:) forElement:@"age"];
	[parseDescription addDoubleSelector:@selector(setDownloadFractionDone:) forElement:@"fraction_done"];
	[parseDescription addIntSelector:@selector(setTaskCount:) forElement:@"tasks"];
	[parseDescription addNSIntegerSelector:@selector(setPages:) forElement:@"pages"];
	[parseDescription addLonglongSelector:@selector(setFileSize:) forElement:@"size"];

If the numerical type you need is not listed you can always parse it as a string and convert it in the setter. This is the recommended way if you need to use a formatter.


Bool Elements
----------------

The value for a bool element is determined as follows:

1. If the element does not exist then the setter will not be called.
2. If it exists but has no content (value) then it is set to YES.
3. It is set to the return value of NSString's -boolValue method.  

Example:

	[parseDescription addBoolSelector:@selector(isCheckedOut:) forElement:@"checked_out"];


Object Elements
---------------

Child elements can be objects that have their own parsing description and have a setter with that object as it's type. The new object's parsing description in read and is used to instantiate an object of that type from the XML and, when it is completely parsed, sent as the parameter of the given selector to the existing object.

	[parseDescription addObjectSelector:@selector(setPublisher:) ofClass:[Publisher class] forElement:@"publisher"];


Array Elements
--------------

An NSArray filled with all the objects contained in an XML element. The order that objects parsed from the XML exist in the array is random (based on the order that NSXMLParser parses them, which is not guaranteed to be the order that they exist in the XML document).

	[parseDescription addArraySelector:@selector(setAuthors:) withClassDictionary:[NSDictionary dictionaryWithObject:[Author class] forKey:@"author"] forElement:@"authors"];

If there are more than one type of object in the XML array then add each class with the appropriate tag to the class dictionary (similar to the pets example above).

If you need an NSMutableArray then you will need to do a -mutableCopy in the setter.


Attributes
----------

There are several methods for getting the values of attributes:

	- (void)addStringSelector:(SEL)selector    forAttribute:(NSString *)attributeName;
	- (void)addBoolSelector:(SEL)selector      forAttribute:(NSString *)attributeName;
	- (void)addFloatSelector:(SEL)selector     forAttribute:(NSString *)attributeName;
	- (void)addDoubleSelector:(SEL)selector    forAttribute:(NSString *)attributeName;
	- (void)addIntSelector:(SEL)selector       forAttribute:(NSString *)attributeName;
	- (void)addNSIntegerSelector:(SEL)selector forAttribute:(NSString *)attributeName;
	- (void)addLonglongSelector:(SEL)selector  forAttribute:(NSString *)attributeName;

I haven't really needed to use them so they haven't been tested as much as the element methods have.


Ignoring Elements
-----------------

If you are reading an XML document and you don't need major sections of it you can set certain elements to be ignored. This should only be used as a performance enhancement, it just reduces the overhead that BBXMLReader adds to NSXMLParser. If the element is small then you don't need to use this.

In the examples below all `<dog>` nodes will be ignored. If the `<dog>` element was just not listed then no instances of the Dog class would be created, but BBXMLReader would have to look inside all child elements of every `<dog>` node and see if any `<cat>` or `<bird>` elements existed inside it. By ignoring the `<dog>` element you avoid this overhead. However NSXMLParser will still read all of the XML.

However, if the `<dog>` node could contain a `<cat>` element then you would have to ignore the `<dog>` nodes if you were not otherwise parsing them.

This is only really needed when setting up a class dictionary for sending to the BBXMLReader. Once in a parsing description BBXMLReader will automatically ignore any elements that are not specifically listed in the description.

Use kBBXMLIgnoredElement to ignore an element in a class dictionary:

	NSDictionary *classDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               kBBXMLIgnoredElement, @"dog", 
                               [Cat class], @"cat", 
                               [Bird class], @"bird", 
                               nil];
	NSArray *pets = [BBXMLReader objectsInClassDictionary:classDict fromXMLString:xmlString];


Skipping Elements
-----------------

Skipping an element removes that element from the XML path and promotes all it's child elements to be at the same level it is.

I needed this because some of the XML-RPC messages I read have an extra "grouping" element but that grouping is not relevant to my class hierarchy. I could just create another class and parse all it's elements then add them to the main class in the setter. But that didn't feel like the right way to do it and is kind of a pain.

In the above example of the Book parsing description there is a Publisher class that is read in. The `<publisher>` element probably contains the name of the publisher and an address or other contact information. If you didn't want to create a Publisher class and only wanted the name then you could skip the `<publisher>` element and just parse the `<name>` element in the Book class.

>Warning:  You must be very careful with this option. If **any** of the elements of the children of the skipped element are the same as in it's parent then you will get two calls to the same setter and whichever one is parsed last will determine the value. Which is unlikely to be what you want.

	[parseDescription addSkippedElement:@"publisher"];
	[parseDescription addStringSelector:@selector(setPublisherName:) forElement:@"name"];


Post Processing
---------------

If the object needs any post processing after it is parsed add a parsing completion selector. This method will run after the object is fully parsed (it's end tag has been reached) but before it is assigned to whatever object will contain it.

	[parseDescription addParsingCompletionSelector:@selector(finishedXMLParsing)];


Things to do:
-------------

1. XML Namespaces  
	BBXMLReader does not currently support namespaces. This is because none of the XML I have been parsing uses them. If I were to tack on namespaces it would probably not really work right unless I actually needed them. Feel free to add them and send me the patch :)

2. Garbage Collection support  
	Same as above, I haven't worked on an app using GC yet so I haven't added support for it.

3. 10.4 Support  
	I've used a handful of Obj-C 2.0 properties. But it would not be particularly hard to remove them if you needed to support 10.4.

4. Type checking  
	BBXMLReader currently checks to see if a class responds to a selector before adding it to the parsing description. It would be nice if it would also check the type that the selector accepts. I meant to add this but it hasn't been an issue so I never have.

5. An example project  
	No time yet.

