//
//  egl.m
//  MinimalIOSApp
//
//  Created by alco on 24.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <EGL/egl.h>
#import <OpenGLES/EAGLDrawable.h>


#define STRINGIFY(x) #x


static const EGLint INTERNAL_AEGL_VERSION_MAJOR = 1;
static const EGLint INTERNAL_AEGL_VERSION_MINOR = 4;

static const int INTERNAL_AEGL_DISPLAY_SECRET = 0xf00d;


// This is a dummy object with a single field that is used
// to check that the valid display object is passed to EGL functions.
static struct internalAEGLDisplay_t {
    int secret_number;  // equal to INTERNAL_AEGL_DISPLAY for a valid display
} s_internalAEGLDisplay = { INTERNAL_AEGL_DISPLAY_SECRET };

struct internalAEGLConfig_t {
    EGLint config_id;

    EGLint red_size;
    EGLint green_size;
    EGLint blue_size;
    EGLint alpha_size;

    EGLint depth_size;

    EGLint render_type_bitmask;
    EGLint buffer_size;
};

static struct internalAEGLConfig_t s_internalAEGL_OpenGLES_1_config = {
    0,
    5, 6, 5, 0,
    0,
    EGL_OPENGL_ES_BIT,
    16
};

static struct internalAEGLConfig_t s_internalAEGL_OpenGLES_2_config = {
    1,
    8, 8, 8, 8,
    24,
    EGL_OPENGL_ES_BIT | EGL_OPENGL_ES2_BIT,
    32
};

static EGLint s_internalAEGLError = EGL_SUCCESS;


#define CHECK_DISPLAY(display)                                                                      \
    if (((struct internalAEGLDisplay_t *)display)->secret_number != INTERNAL_AEGL_DISPLAY_SECRET) { \
        s_internalAEGLError = EGL_BAD_DISPLAY;                                                      \
        return EGL_FALSE;                                                                           \
    }

#define CHECK_DISPLAY_2(display, retval)                                                            \
    if (((struct internalAEGLDisplay_t *)display)->secret_number != INTERNAL_AEGL_DISPLAY_SECRET) { \
        s_internalAEGLError = EGL_BAD_DISPLAY;                                                      \
        return retval;                                                                              \
    }

#define GET_CONFIG(config, field) ((struct internalAEGLConfig_t *)config)->field


#pragma mark -

EGLint eglGetError(void)
{
    return s_internalAEGLError;
}

EGLDisplay eglGetDisplay(EGLNativeDisplayType display_id)
{
    if (display_id != EGL_DEFAULT_DISPLAY) {
        return EGL_NO_DISPLAY;
    }
    return &s_internalAEGLDisplay;
}

EGLBoolean eglInitialize(EGLDisplay dpy, EGLint *major, EGLint *minor)
{
    CHECK_DISPLAY(dpy);

    if (major) {
        *major = INTERNAL_AEGL_VERSION_MAJOR;
    }
    if (minor) {
        *minor = INTERNAL_AEGL_VERSION_MINOR;
    }

    // No further work needed

    return EGL_TRUE;
}

EGLBoolean eglTerminate(EGLDisplay dpy)
{
    CHECK_DISPLAY(dpy);

    // Do nothing

    return EGL_TRUE;
}

const char * eglQueryString(EGLDisplay dpy, EGLint name)
{
    CHECK_DISPLAY_2(dpy, NULL);

    switch (name) {
    case EGL_CLIENT_APIS:
        // Returns a string describing which client rendering APIs are
        // supported. The string contains a space-separate list of API names.
        // The list must include at least one of OpenGL, OpenGL_ES, or OpenVG.
        // These strings correspond respectively to values EGL_OPENGL_API,
        // EGL_OPENGL_ES_API, and EGL_OPENVG_API of the eglBindAPI, api
        // argument.
        return "OpenGL_ES";

    case EGL_VENDOR:
        // Returns the company responsible for this EGL implementation. This
        // name does not change from release to release.
        return "alco";

    case EGL_VERSION:
        // Returns a version or release number. The EGL_VERSION string is laid
        // out as follows:
        //
        // major_version.minor_version space vendor_specific_info
        return STRINGIFY(INTERNAL_AEGL_VERSION_MAJOR) "." STRINGIFY(INTERNAL_AEGL_VERSION_MINOR) " alpha";

    case EGL_EXTENSIONS:
        // Returns a space separated list of supported extensions to EGL.
        return "";

    default:
        s_internalAEGLError = EGL_BAD_PARAMETER;
        return NULL;
    }

    return NULL;
}

EGLBoolean eglGetConfigs(EGLDisplay dpy, EGLConfig *configs,
                                     EGLint config_size, EGLint *num_config)
{
    CHECK_DISPLAY(dpy);

    if (!num_config) {
        s_internalAEGLError = EGL_BAD_PARAMETER;
        return EGL_FALSE;
    }

    if (configs) {
        if (config_size < 1) {
            *num_config = 0;
        } else if (config_size == 1) {
            // Return only OpenGL ES 1 for compatibility with old devices
            configs[0] = (EGLConfig)&s_internalAEGL_OpenGLES_1_config;
            *num_config = 1;
        } else if (config_size > 1) {
            // Return both OpenGL ES 1 and OpenGL ES 2
            configs[0] = (EGLConfig)&s_internalAEGL_OpenGLES_1_config;
            configs[1] = (EGLConfig)&s_internalAEGL_OpenGLES_2_config;
            *num_config = 2;
        }
    } else {
        *num_config = 2;
    }

    return EGL_TRUE;
}


EGLBoolean  eglChooseConfig(EGLDisplay dpy, const EGLint *attrib_list,
                                       EGLConfig *configs, EGLint config_size,
                                       EGLint *num_config)
{
    // FIXME: not implemented
    return false;
}

EGLBoolean  eglGetConfigAttrib(EGLDisplay dpy, EGLConfig config,
                                          EGLint attribute, EGLint *value)
{
    CHECK_DISPLAY(dpy);

    if (!value) {
        return EGL_FALSE;
    }

    switch (attribute) {
    case EGL_ALPHA_SIZE:
        // Returns the number of bits of alpha stored in the color buffer.
        *value = GET_CONFIG(config, alpha_size);
        break;

    case EGL_ALPHA_MASK_SIZE:
        // Returns the number of bits in the alpha mask buffer.
        *value = 0;
        break;

    case EGL_BIND_TO_TEXTURE_RGB:
        // Returns EGL_TRUE if color buffers can be bound to an RGB texture,
        // EGL_FALSE otherwise.
        *value = EGL_TRUE;
        break;

    case EGL_BIND_TO_TEXTURE_RGBA:
        // Returns EGL_TRUE if color buffers can be bound to an RGBA texture,
        // EGL_FALSE otherwise.
        *value = EGL_TRUE;
        break;

    case EGL_BLUE_SIZE:
        // Returns the number of bits of blue stored in the color buffer.
        *value = GET_CONFIG(config, blue_size);
        break;

    case EGL_BUFFER_SIZE:
        // Returns the depth of the color buffer. It is the sum of
        // EGL_RED_SIZE, EGL_GREEN_SIZE, EGL_BLUE_SIZE, and EGL_ALPHA_SIZE.
        *value = GET_CONFIG(config, buffer_size);
        break;

    case EGL_COLOR_BUFFER_TYPE:
        //Returns the color buffer type. Possible types are EGL_RGB_BUFFER and
        //EGL_LUMINANCE_BUFFER.
        *value = EGL_RGB_BUFFER;
        break;

    case EGL_CONFIG_CAVEAT:
        // Returns the caveats for the frame buffer configuration. Possible
        // caveat values are EGL_NONE, EGL_SLOW_CONFIG, and EGL_NON_CONFORMANT.
        *value = EGL_NONE;
        break;

    case EGL_CONFIG_ID:
        // Returns the ID of the frame buffer configuration.
        *value = GET_CONFIG(config, config_id);
        break;

    case EGL_CONFORMANT:
        // Returns a bitmask indicating which client API contexts created with
        // respect to this config are conformant.
        *value = GET_CONFIG(config, render_type_bitmask);
        break;

    case EGL_DEPTH_SIZE:
        // Returns the number of bits in the depth buffer.
        *value = GET_CONFIG(config, depth_size);
        break;

    case EGL_GREEN_SIZE:
        // Returns the number of bits of green stored in the color buffer.
        *value = GET_CONFIG(config, green_size);
        break;

    case EGL_LEVEL:
        // Returns the frame buffer level. Level zero is the default frame
        // buffer. Positive levels correspond to frame buffers that overlay the
        // default buffer and negative levels correspond to frame buffers that
        // underlay the default buffer.
        *value = 0;
        break;

    case EGL_LUMINANCE_SIZE:
        // Returns the number of bits of luminance stored in the luminance
        // buffer.
        *value = 0;
        break;

    case EGL_MAX_PBUFFER_WIDTH:
        // Returns the maximum width of a pixel buffer surface in pixels.
        *value = 0;
        break;

    case EGL_MAX_PBUFFER_HEIGHT:
        // Returns the maximum height of a pixel buffer surface in pixels.
        *value = 0;
        break;

    case EGL_MAX_PBUFFER_PIXELS:
        // Returns the maximum size of a pixel buffer surface in pixels.
        *value = 0;
        break;

    case EGL_MAX_SWAP_INTERVAL:
        // Returns the maximum value that can be passed to eglSwapInterval.
        *value = 10;
        break;

    case EGL_MIN_SWAP_INTERVAL:
        // Returns the minimum value that can be passed to eglSwapInterval.
        *value = 0;
        break;

    case EGL_NATIVE_RENDERABLE:
        // Returns EGL_TRUE if native rendering APIs can render into the
        // surface, EGL_FALSE otherwise.
        *value = EGL_TRUE;
        break;

    case EGL_NATIVE_VISUAL_ID:
        // Returns the ID of the associated native visual.
        *value = 0;
        break;

    case EGL_NATIVE_VISUAL_TYPE:
        // Returns the type of the associated native visual.
        *value = 0;
        break;

    case EGL_RED_SIZE:
        // Returns the number of bits of red stored in the color buffer.
        *value = GET_CONFIG(config, red_size);
        break;

    case EGL_RENDERABLE_TYPE:
        // Returns a bitmask indicating the types of supported client API
        // contexts.
        *value = GET_CONFIG(config, render_type_bitmask);
        break;

    case EGL_SAMPLE_BUFFERS:
        // Returns the number of multisample buffers.
        *value = 0;
        break;

    case EGL_SAMPLES:
        // Returns the number of samples per pixel.
        *value = 0;
        break;

    case EGL_STENCIL_SIZE:
        // Returns the number of bits in the stencil buffer.
        *value = 0;
        break;

    case EGL_SURFACE_TYPE:
        // Returns a bitmask indicating the types of supported EGL surfaces.
        *value = 0;
        break;

    case EGL_TRANSPARENT_TYPE:
        // Returns the type of supported transparency. Possible transparency
        // values are: EGL_NONE, and EGL_TRANSPARENT_RGB.
        *value = 0;
        break;

    case EGL_TRANSPARENT_RED_VALUE:
        // Returns the transparent red value.
        *value = 0;
        break;

    case EGL_TRANSPARENT_GREEN_VALUE:
        // Returns the transparent green value.
        *value = 0;
        break;

    case EGL_TRANSPARENT_BLUE_VALUE:
        // Returns the transparent blue value.
        *value = 0;
        break;

    default:
        s_internalAEGLError = EGL_BAD_ATTRIBUTE;
        return EGL_FALSE;
    }

    return EGL_TRUE;
}

EGLSurface  eglCreateWindowSurface(EGLDisplay dpy, EGLConfig config,
                                              EGLNativeWindowType win,
                                              const EGLint *attrib_list)
{
    NSDictionary *drawableProperties =
      [NSDictionary dictionaryWithObjectsAndKeys:
       [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
       kEAGLColorFormatRGBA8,        kEAGLDrawablePropertyColorFormat,
       nil];
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

    return false;
}

EGLSurface  eglCreatePbufferSurface(EGLDisplay dpy, EGLConfig config,
                                               const EGLint *attrib_list)
{
    return false;
}

EGLSurface  eglCreatePixmapSurface(EGLDisplay dpy, EGLConfig config,
                                              EGLNativePixmapType pixmap,
                                              const EGLint *attrib_list)
{
    return false;
}

EGLBoolean  eglDestroySurface(EGLDisplay dpy, EGLSurface surface)
{
    return false;
}

EGLBoolean  eglQuerySurface(EGLDisplay dpy, EGLSurface surface,
                                       EGLint attribute, EGLint *value)
{
    return false;
}


EGLBoolean  eglBindAPI(EGLenum api)
{
    return false;
}

EGLenum  eglQueryAPI(void)
{
    return false;
}

EGLBoolean  eglWaitClient(void)
{
    return false;
}

EGLBoolean  eglReleaseThread(void)
{
    return false;
}

EGLSurface  eglCreatePbufferFromClientBuffer(EGLDisplay dpy, EGLenum buftype, EGLClientBuffer buffer,
                                             EGLConfig config, const EGLint *attrib_list)
{
    // FIXME: not implemented
    return false;
}

EGLBoolean  eglSurfaceAttrib(EGLDisplay dpy, EGLSurface surface,
                                        EGLint attribute, EGLint value)
{
    // FIXME: not implemented
    return false;
}

EGLBoolean  eglBindTexImage(EGLDisplay dpy, EGLSurface surface, EGLint buffer)
{
    // FIXME: not implemented
    return false;
}

EGLBoolean  eglReleaseTexImage(EGLDisplay dpy, EGLSurface surface, EGLint buffer)
{
    // FIXME: not implemented
    return false;
}


EGLBoolean  eglSwapInterval(EGLDisplay dpy, EGLint interval)
{
    // TODO: implementation
    return false;
}


EGLContext  eglCreateContext(EGLDisplay dpy, EGLConfig config,
                                        EGLContext share_context,
                                        const EGLint *attrib_list)
{
    // TODO: implementation
    return false;
}

EGLBoolean  eglDestroyContext(EGLDisplay dpy, EGLContext ctx)
{
    // TODO: implementation
    return false;
}

EGLBoolean  eglMakeCurrent(EGLDisplay dpy, EGLSurface draw,
                                      EGLSurface read, EGLContext ctx)
{
    // TODO: implementation
    return false;
}


EGLContext  eglGetCurrentContext(void)
{
    return false;
}

EGLSurface  eglGetCurrentSurface(EGLint readdraw)
{
    return false;
}

EGLDisplay  eglGetCurrentDisplay(void)
{
    return false;
}

EGLBoolean  eglQueryContext(EGLDisplay dpy, EGLContext ctx,
                                       EGLint attribute, EGLint *value)
{
    return false;
}


EGLBoolean  eglWaitGL(void)
{
    return false;
}

EGLBoolean  eglWaitNative(EGLint engine)
{
    return false;
}

EGLBoolean  eglSwapBuffers(EGLDisplay dpy, EGLSurface surface)
{
    return false;
}

EGLBoolean  eglCopyBuffers(EGLDisplay dpy, EGLSurface surface,
                                      EGLNativePixmapType target)
{
    // FIXME: not implemented
    return false;
}


EGLBoolean _createFrameBuffer()
{
//    glGenFramebuffersOES(1, &viewFramebuffer);
//    glGenRenderbuffersOES(1, &viewRenderbuffer);
//
//    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
//    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
//    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
//    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
//
//    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
//    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
//
//    if (USE_DEPTH_BUFFER)
//	{
//        glGenRenderbuffersOES(1, &depthRenderbuffer);
//        glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
//        glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
//        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
//    }
//
//    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
//        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
//        return false;
//    }

    return true;
}

