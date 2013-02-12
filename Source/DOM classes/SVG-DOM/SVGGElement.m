#import "SVGGElement.h"

#import "CALayerWithChildHitTest.h"

@implementation SVGGElement 

@synthesize opacity = _opacity;

- (void)loadDefaults {
	_opacity = 1.0f;
}

- (void)postProcessAttributesAddingErrorsTo:(SVGKParseResult *)parseResult {
	[super postProcessAttributesAddingErrorsTo:parseResult];
	
	if( [[self getAttribute:@"opacity"] length] > 0 )
		_opacity = [[self getAttribute:@"opacity"] floatValue];
}

- (CALayer *) newLayer
{
	
	CALayer* _layer = [[CALayerWithChildHitTest layer] retain];
	
	_layer.name = self.identifier;
	[_layer setValue:self.identifier forKey:kSVGElementIdentifier];
	_layer.opacity = _opacity;
	
	if ([_layer respondsToSelector:@selector(setShouldRasterize:)]) {
		[_layer performSelector:@selector(setShouldRasterize:)
					 withObject:[NSNumber numberWithBool:YES]];
	}
	
	return _layer;
}

- (void)layoutLayer:(CALayer *)layer {
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
		frame.origin.x -= frameRect.origin.x;
		frame.origin.y -= frameRect.origin.y;
		
		currentLayer.frame = frame;
	}
}

@end
