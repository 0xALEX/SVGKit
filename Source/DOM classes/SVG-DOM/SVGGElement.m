#import "SVGGElement.h"

#import "CALayerWithChildHitTest.h"

#import "SVGHelperUtilities.h"

@implementation SVGGElement 

@synthesize transform; // each SVGElement subclass that conforms to protocol "SVGTransformable" has to re-synthesize this to work around bugs in Apple's Objective-C 2.0 design that don't allow @properties to be extended by categories / protocols

- (CALayer *) newLayer
{
	
	CALayer* _layer = [[CALayerWithChildHitTest layer] retain];
	
	_layer.name = self.identifier;
	[_layer setValue:self.identifier forKey:kSVGElementIdentifier];
	
	NSString* actualOpacity = [self cascadedValueForStylableProperty:@"opacity"];
	_layer.opacity = actualOpacity.length > 0 ? [actualOpacity floatValue] : 1.0f; // svg's "opacity" defaults to 1!
	
	if ([_layer respondsToSelector:@selector(setShouldRasterize:)]) {
		[_layer performSelector:@selector(setShouldRasterize:)
					 withObject:[NSNumber numberWithBool:YES]];
	}
	
	return _layer;
}

- (void)layoutLayer:(CALayer *)layer {
#define ORIGINAL_PRE_MTRUBNIKOV_MERGE 1
#if ORIGINAL_PRE_MTRUBNIKOV_MERGE
	CGRect mainRect = CGRectZero;
	
	/** Adam: make a frame thats the UNION of all sublayers frames */
	for ( CALayer *currentLayer in [layer sublayers] )
	{
		CGRect subLayerFrame = currentLayer.frame;
		mainRect = CGRectUnion(mainRect, subLayerFrame);
	}
	
	layer.frame = mainRect;
#else
	CGRect frameRect = CGRectZero;
    CGRect mainRect = CGRectZero;
    CGRect boundsRect = CGRectZero;
	
	NSArray *sublayers = [layer sublayers];
    
	for ( CALayer *sublayer in sublayers) {
		if (CGRectEqualToRect(frameRect,CGRectZero)) {
			frameRect = sublayer.frame;
		}
		else {
			frameRect = CGRectUnion(frameRect, sublayer.frame);
		}
        mainRect = CGRectUnion(mainRect, sublayer.frame);
	}
    
    boundsRect = CGRectOffset(frameRect, -frameRect.origin.x, -frameRect.origin.y);
    
	layer.frame = boundsRect;
#endif

	/** (dont know why this is here): set each sublayer to have a frame the same size as the parent frame, but with 0 offset.
	 
	 if I understand this correctly, the person who wrote it should have just written:
	 
	 "currentLayer.bounds = layer.frame"
	 
	 i.e. make every layer have the same size as the parent layer.
	 
	 But whoever wrote this didn't document their code, so I have no idea if thats correct or not
	 */
	for (CALayer *currentLayer in [layer sublayers]) {
		CGRect frame = currentLayer.frame;
		frame.origin.x -= mainRect.origin.x;
		frame.origin.y -= mainRect.origin.y;
		
		currentLayer.frame = frame;
	}
	
#if OUTLINE_SHAPES
    
    layer.borderColor = [UIColor redColor].CGColor;
    layer.borderWidth = 2.0f;
    
    NSString* textToDraw = [NSString stringWithFormat:@"%@ (%@): {%.1f, %.1f} {%.1f, %.1f}", self.identifier, [self class], layer.frame.origin.x, layer.frame.origin.y, layer.frame.size.width, layer.frame.size.height];
    
    UIFont* fontToDraw = [UIFont fontWithName:@"Helvetica"
                                         size:10.0f];
    CGSize sizeOfTextRect = [textToDraw sizeWithFont:fontToDraw];
    
    CATextLayer *debugText = [[[CATextLayer alloc] init] autorelease];
    [debugText setFont:@"Helvetica"];
    [debugText setFontSize:10.0f];
    [debugText setFrame:CGRectMake(0, 0, sizeOfTextRect.width, sizeOfTextRect.height)];
    [debugText setString:textToDraw];
    [debugText setAlignmentMode:kCAAlignmentLeft];
    [debugText setForegroundColor:[UIColor redColor].CGColor];
    [debugText setContentsScale:[[UIScreen mainScreen] scale]];
    [debugText setShouldRasterize:NO];
    [layer addSublayer:debugText];
#endif
}

@end
