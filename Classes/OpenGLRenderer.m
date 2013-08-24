/*
 ////////////////////////////////////////////////////////////////////
 // This example is derived from the Apple OSXGLEssentials example //
 ////////////////////////////////////////////////////////////////////
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "OpenGLRenderer.h"
#import "sourceUtil.h"

// Vertices of the triangle
GLfloat posArray[] = {
    -0.5f,  -0.5f,  0.0f,
     0.5f,  -0.5f,  0.0f,
     0.0f,   0.5f,  0.0f
};

#define GetGLError()									\
{														\
	GLenum err = glGetError();							\
	while (err != GL_NO_ERROR) {						\
		NSLog(@"GLError %s set in File:%s Line:%d\n",	\
				GetGLErrorString(err),					\
				__FILE__,								\
				__LINE__);								\
		err = glGetError();								\
	}													\
}

// Indicies to which we will set vertex array attibutes
// See buildVAO and buildProgram
enum {
	POSITION_ATTRIBUTE_INDEX,
};

#ifndef NULL
#define NULL 0
#endif

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

#pragma mark - Private Ivars

@interface OpenGLRenderer ()
{
	GLuint  _defaultFBOName;
    GLuint  _programName;
    GLuint  _vaoName;
    GLuint  _viewWidth;
    GLuint  _viewHeight;
}
@end

@implementation OpenGLRenderer

#pragma mark - Public Methods

- (id) initWithDefaultFBO: (GLuint) defaultFBOName
{
	if((self = [super init]))
	{
		NSLog(@"%s %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));
		
		////////////////////////////////////////////////////
		// Build all of our and setup initial state here  //
		// Don't wait until our real time run loop begins //
		////////////////////////////////////////////////////
		
		_defaultFBOName = defaultFBOName;          // 0 on OS X
		
		_viewWidth = 100;
		_viewHeight = 100;
		
		// Build Vertex Buffer Objects (VBOs) and Vertex Array Object (VAOs) with our model data
		_vaoName = [self buildVAO];
		
		///////////////////////////////////////////////////
		// Load and Setup shaders for triangle rendering //
		///////////////////////////////////////////////////
		
		shaderSource *vtxSource = NULL;
		shaderSource *frgSource = NULL;
		
		NSString* filePathName = nil;
		filePathName = [[NSBundle mainBundle] pathForResource:@"triangle" ofType:@"vsh"];
		vtxSource = srcLoadSource([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
		
		filePathName = [[NSBundle mainBundle] pathForResource:@"triangle" ofType:@"fsh"];
		frgSource = srcLoadSource([filePathName cStringUsingEncoding:NSASCIIStringEncoding]);
		
		// Build Program
		_programName = [self buildProgramWithVertexSource:vtxSource
                                       withFragmentSource:frgSource];
		
		srcDestroySource(vtxSource);
		srcDestroySource(frgSource);
		
		////////////////////////////////////////////////
		// Set up OpenGL state that will never change //
		////////////////////////////////////////////////
		
		// Always use this clear color
		glClearColor(1.0f, 0.0f, 1.0f, 1.0f);
		
		// Check for errors to make sure all of our setup went ok
		GetGLError();
	}
	return self;
}

- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height
{
	glViewport(0, 0, width, height);

	_viewWidth = width;
	_viewHeight = height;
}

- (void) render
{    
	glClear(GL_COLOR_BUFFER_BIT);
	
	// Use our program
	glUseProgram(_programName);
	
	// Bind our vertex array object
	glBindVertexArray(_vaoName);
	
	// Draw our triangle
    glDrawArrays(GL_TRIANGLES, 0, 3);
}

#pragma mark - Private Methods & Functions

static GLsizei GetGLTypeSize(GLenum type)
{
	switch (type) {
		case GL_BYTE:
			return sizeof(GLbyte);
		case GL_UNSIGNED_BYTE:
			return sizeof(GLubyte);
		case GL_SHORT:
			return sizeof(GLshort);
		case GL_UNSIGNED_SHORT:
			return sizeof(GLushort);
		case GL_INT:
			return sizeof(GLint);
		case GL_UNSIGNED_INT:
			return sizeof(GLuint);
		case GL_FLOAT:
			return sizeof(GLfloat);
	}
	return 0;
}

- (GLuint) buildVAO
{	
	GLuint vaoName;             // Vertex Array Object name
	
	// Create a vertex array object (VAO) to cache model parameters
	glGenVertexArrays(1, &vaoName);
	glBindVertexArray(vaoName);
	GetGLError();
	
    GLuint posBufferName;       // Vertex Buffer Object name
    
    // Create a vertex buffer object (VBO) to store positions
    glGenBuffers(1, &posBufferName);
    glBindBuffer(GL_ARRAY_BUFFER, posBufferName);
    GetGLError();
    
    // Allocate and load position data into the VBO
    glBufferData(GL_ARRAY_BUFFER, sizeof(posArray), posArray, GL_STATIC_DRAW);
    
    // Enable the position attribute for this VAO
    glEnableVertexAttribArray(POSITION_ATTRIBUTE_INDEX);
    
    // Get the size of the position type so we can set the stride properly
    GLsizei posTypeSize = GetGLTypeSize(GL_FLOAT);
    
    // Set up parmeters for position attribute in the VAO including,
    //  size, type, stride, and offset in the currenly bound VAO
    // This also attaches the position VBO to the VAO
    glVertexAttribPointer(POSITION_ATTRIBUTE_INDEX,	// What attibute index will this array feed in the vertex shader (see buildProgram)
                          3,	// How many elements are there per position?
                          GL_FLOAT,	// What is the type of this data?
                          GL_FALSE,				// Do we want to normalize this data (0-1 range for fixed-pont types)
                          3*posTypeSize, // What is the stride (i.e. bytes between positions)?
                          BUFFER_OFFSET(0));	// What is the offset in the VBO to the position data?
	GetGLError();
	
	return vaoName;
}

-(GLuint) buildProgramWithVertexSource:(shaderSource*)vertexSource
					withFragmentSource:(shaderSource*)fragmentSource
{
	GLuint prgName;
	
	GLint logLength, status;
	
	// String to pass to glShaderSource
	GLchar* sourceString = NULL;  
	
	// Determine if GLSL version 140 is supported by this context.
	//  We'll use this info to generate a GLSL shader source string  
	//  with the proper version preprocessor string prepended
	float  glLanguageVersion;
	
	sscanf((char *)glGetString(GL_SHADING_LANGUAGE_VERSION), "%f", &glLanguageVersion);	
	
	// GL_SHADING_LANGUAGE_VERSION returns the version standard version form 
	//  with decimals, but the GLSL version preprocessor directive simply
	//  uses integers (thus 1.10 should 110 and 1.40 should be 140, etc.)
	//  We multiply the floating point number by 100 to get a proper
	//  number for the GLSL preprocessor directive
	GLuint version = 100 * glLanguageVersion;
	
	// Get the size of the version preprocessor string info so we know 
	//  how much memory to allocate for our sourceString
	const GLsizei versionStringSize = sizeof("#version 123\n");
	
	// Create a program object
	prgName = glCreateProgram();
	
	// Indicate the attribute indicies on which vertex arrays will be
	//  set with glVertexAttribPointer
	//  See buildVAO to see where vertex arrays are actually set
	glBindAttribLocation(prgName, POSITION_ATTRIBUTE_INDEX, "inPosition");
	
	//////////////////////////////////////
	// Specify and compile VertexShader //
	//////////////////////////////////////
	
	// Allocate memory for the source string including the version preprocessor information
	sourceString = malloc(vertexSource->byteSize + versionStringSize);
	
	// Prepend our vertex shader source string with the supported GLSL version so
	//  the shader will work on ES, Legacy, and OpenGL 3.2 Core Profile contexts
	sprintf(sourceString, "#version %d\n%s", version, vertexSource->string);
			
	GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);	
	glShaderSource(vertexShader, 1, (const GLchar **)&(sourceString), NULL);
	glCompileShader(vertexShader);
	glGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH, &logLength);
	
	if (logLength > 0) 
	{
		GLchar *log = (GLchar*) malloc(logLength);
		glGetShaderInfoLog(vertexShader, logLength, &logLength, log);
		NSLog(@"Vtx Shader compile log:%s\n", log);
		free(log);
	}
	
	glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &status);
	if (status == 0)
	{
		NSLog(@"Failed to compile vtx shader:\n%s\n", sourceString);
		return 0;
	}
	
	free(sourceString);
	sourceString = NULL;
	
	// Attach the vertex shader to our program
	glAttachShader(prgName, vertexShader);
	
	// Delete the vertex shader since it is now attached
	// to the program, which will retain a reference to it
	glDeleteShader(vertexShader);
	
	/////////////////////////////////////////
	// Specify and compile Fragment Shader //
	/////////////////////////////////////////
	
	// Allocate memory for the source string including the version preprocessor	 information
	sourceString = malloc(fragmentSource->byteSize + versionStringSize);
	
	// Prepend our fragment shader source string with the supported GLSL version so
	//  the shader will work on ES, Legacy, and OpenGL 3.2 Core Profile contexts
	sprintf(sourceString, "#version %d\n%s", version, fragmentSource->string);
	
	GLuint fragShader = glCreateShader(GL_FRAGMENT_SHADER);	
	glShaderSource(fragShader, 1, (const GLchar **)&(sourceString), NULL);
	glCompileShader(fragShader);
	glGetShaderiv(fragShader, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0) 
	{
		GLchar *log = (GLchar*)malloc(logLength);
		glGetShaderInfoLog(fragShader, logLength, &logLength, log);
		NSLog(@"Frag Shader compile log:\n%s\n", log);
		free(log);
	}
	
	glGetShaderiv(fragShader, GL_COMPILE_STATUS, &status);
	if (status == 0)
	{
		NSLog(@"Failed to compile frag shader:\n%s\n", sourceString);
		return 0;
	}
	
	free(sourceString);
	sourceString = NULL;
	
	// Attach the fragment shader to our program
	glAttachShader(prgName, fragShader);
	
	// Delete the fragment shader since it is now attached
	// to the program, which will retain a reference to it
	glDeleteShader(fragShader);
	
	//////////////////////
	// Link the program //
	//////////////////////
	
	glLinkProgram(prgName);
	glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar*)malloc(logLength);
		glGetProgramInfoLog(prgName, logLength, &logLength, log);
		NSLog(@"Program link log:\n%s\n", log);
		free(log);
	}
	
	glGetProgramiv(prgName, GL_LINK_STATUS, &status);
	if (status == 0)
	{
		NSLog(@"Failed to link program");
		return 0;
	}
	
	glValidateProgram(prgName);
	glGetProgramiv(prgName, GL_INFO_LOG_LENGTH, &logLength);
	if (logLength > 0)
	{
		GLchar *log = (GLchar*)malloc(logLength);
		glGetProgramInfoLog(prgName, logLength, &logLength, log);
		NSLog(@"Program validate log:\n%s\n", log);
		free(log);
	}
	
	glGetProgramiv(prgName, GL_VALIDATE_STATUS, &status);
	if (status == 0)
	{
		NSLog(@"Failed to validate program");
		return 0;
	}
	
	glUseProgram(prgName);

    GetGLError();
	
	return prgName;
}
@end
