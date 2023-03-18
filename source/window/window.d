module window.window;

import std.stdio;
import std.conv;
import std.string;
import bindbc.opengl;
import bindbc.glfw;
import doml.vector_2i;
import doml.vector_2d;
import doml.vector_3d;
import delta_time;


// This is a special import. We only want to extract the loader from this module.
import loader = bindbc.loader.sharedlib;

// This is an import that allows us to print debug info.
import tools.glfw_error_logger;
import tools.gl_loader_logger;

import OpenGlLogger = tools.opengl_error_logger;

// OpenGL fields
private string glVersion;
private Vector3d clearColor;

// GLFW fields
private string title;
private Vector2i windowSize;

private  GLFWwindow* window = null;
private GLFWmonitor* monitor = null;
private GLFWvidmode videoMode;
private bool fullscreen = false;

private bool mouseButtonPressed = false;
private bool mouseButtonWasPressed = false;

// 0 none, 1 normal vsync, 2 double buffered
private int vsync = 1;

// These 3 functions calculate the FPS
private double deltaAccumulator = 0.0;
private int fpsCounter = 0;
private int FPS = 0;


void initialize() {
    initializeGLFW();
    initializeOpenGL();
}

//* ======== GLFW Tools ========

// Returns success state 
private void initializeGLFWComponents() {
    
    GLFWSupport returnedSupport;
    
    version(Windows) {
        returnedSupport = loadGLFW("libs/glfw3.dll");
    } else {
        // Linux, FreeBSD, OpenBSD, Mac OS, haiku, etc
        returnedSupport = loadGLFW();
    }

    // We're using a custom class to automate debugging
    if(returnedSupport != glfwSupport) {

        GLFWErrorLogger logger = new GLFWErrorLogger();

        if (returnedSupport == GLFWSupport.noLibrary) {
            logger.attachTip("The GLFW shared library failed to load!\n" ~ "Is GLFW installed correctly?");
        } else if (returnedSupport == GLFWSupport.badLibrary) {
            logger.attachTip(
                "One or more symbols failed to load.\n" ~
                "The likely cause is that the shared library is for a lower\n" ~
                "version than bindbc-glfw was configured to load!\n" ~
                "The required version is GLFW 3.3"
            );
        }

        logger.execute();
    }
}

// private nothrow static
// extern(C) void mouseButtonCallback(GLFWwindow* window, int button, int action, int mods) {
//     mouseButtonWasPressed = mouseButtonPressed;
//     mouseButtonPressed = button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS;
//     try{
//         writeln("was mouse button pressed?", mouseButtonPressed);
//     } catch(Exception e) {}
// }

private nothrow static
extern(C) void myframeBufferSizeCallback(GLFWwindow* theWindow, int x, int y) {
    windowSize.x = x;
    windowSize.y = y;
    glViewport(0,0,x,y);
}

// Window talks directly to GLFW
private void initializeGLFW(int windowSizeX = -1, int windowSizeY = -1) {

    // Something fails to load
    initializeGLFWComponents();

    // Something scary fails to load
    if (!glfwInit()) {
        throw new Exception("GLFW FAILED TO LOAD!");
    }

    // Minimum version is 4.1 (July 26, 2010)
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    // Allow driver optimizations
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);

    bool halfScreenAuto = false;

    // Auto start as half screened
    if (windowSizeX == -1 || windowSizeY == -1) {
        halfScreenAuto = true;
        // Literally one pixel so glfw does not crash.
        // Is automatically changed before the player even sees the window.
        // Desktops like KDE will override the height (y) regardless
        windowSizeX = 1;
        windowSizeY = 1;
    }

    // Create a window on the primary monitor
    window = glfwCreateWindow(windowSizeX, windowSizeY, title.toStringz, null, null);

    // Something even scarier fails to load
    if (!window || window == null) {
        throw new Exception("WINDOW FAILED TO OPEN!");
    }

    // In the future, get array of monitor pointers with: GLFWmonitor** monitors = glfwGetMonitors(&count);
    monitor = glfwGetPrimaryMonitor();

    // Using 3.3 regardless so enable raw input
    // This is so windows, kde, & gnome scale identically with cursor input, only the mouse dpi changes this
    // This allows the sensitivity to be controlled in game and behave the same regardless
    glfwSetInputMode(window, GLFW_RAW_MOUSE_MOTION, GLFW_TRUE);


    // Monitor information & full screening & halfscreening

    // Automatically half the monitor size
    if (halfScreenAuto) {
        writeln("automatically half sizing the window");
        setHalfSizeInternal();
    }


    glfwSetFramebufferSizeCallback(window, &myframeBufferSizeCallback);

    // glfwSetKeyCallback(window, &externalKeyCallBack);

    // glfwSetCursorPosCallback(window, &externalcursorPositionCallback);

    // glfwSetWindowRefreshCallback(window, &myRefreshCallback);

    // glfwSetMouseButtonCallback(window, &mouseButtonCallback);
    
    glfwMakeContextCurrent(window);

    // The swap interval is ignored before context is current
    // We must set it again, even though it is automated in fullscreen/halfsize
    glfwSwapInterval(vsync);

    glfwGetWindowSize(window,&windowSize.x, &windowSize.y);
}

private void pollMouse() {

    mouseButtonWasPressed = mouseButtonPressed;

    int state = glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT);

    mouseButtonPressed = state == 1;
}

private void updateVideoMode() {
    // Get primary monitor specs
    const GLFWvidmode* mode = glfwGetVideoMode(monitor);
    // Dereference the pointer into a usable structure in class
    videoMode = *mode;
}

private void setHalfSizeInternal() {

    updateVideoMode();
    
    // Divide by 2 to get a "perfectly" half sized window
    int windowSizeX = videoMode.width  / 2;
    int windowSizeY = videoMode.height / 2;

    // Divide by 4 to get a "perfectly" centered window
    int windowPositionX = videoMode.width  / 4;
    int windowPositionY = videoMode.height / 4;

    glfwSetWindowMonitor(
        window,
        null,
        windowPositionX,
        windowPositionY,
        windowSizeX,
        windowSizeY,
        videoMode.refreshRate
    );

    glfwSwapInterval(vsync);

    fullscreen = false;
}

void setMousePosition(double x, double y) {
    glfwSetCursorPos(window, x, y);
}

Vector2d getMousePosition() {
    Vector2d currentPos;
    glfwGetCursorPos(window, &currentPos.x, &currentPos.y);
    return currentPos;
}


Vector2d centerMouse() {
    double x = windowSize.x / 2.0;
    double y = windowSize.y / 2.0;
    glfwSetCursorPos(
        window,
        x,
        y
    );
    return Vector2d(x,y);
}

void setVsync(int value) {
    // There is an EXTREME bug with posix (Linux, BSD) that can lock the operating system up.
    // For now, it will ignore trying to turn off vsync during runtime.
    if (isPosix()) {
        return;
    }
    vsync = value;
    glfwSwapInterval(vsync);
}

// Internally handles interfacing to C
bool shouldClose() {
    bool newValue = (glfwWindowShouldClose(window) != 0);
    return newValue;
}

void swapBuffers() {
    glfwSwapBuffers(window);
}

Vector2i getSize() {
    return windowSize;
}

void destroy() {
    glfwDestroyWindow(window);
    glfwTerminate();
}

double getAspectRatio() {
    return cast(double)windowSize.x / cast(double)windowSize.y;
}

void pollEvents() {
    calculateDelta();
    glfwPollEvents();
    pollMouse();
    // This causes an issue with low FPS getting the wrong FPS
    // Perhaps make an internal engine ticker that is created as an object or struct
    // Store it on heap, then calculate from there, specific to this
    deltaAccumulator += getDelta();
    fpsCounter += 1;
    // Got a full second, reset counter, set variable
    if (deltaAccumulator >= 1) {
        deltaAccumulator = 0.0;
        FPS = fpsCounter;
        fpsCounter = 0;
    }
}

int getFPS() {
    return FPS;
}

/// Setting storage to false allows you to chain data into a base window title
void setTitle(string newTitle, bool storeNewTitle = true) {
    if (storeNewTitle) {
        title = newTitle;
    }
    glfwSetWindowTitle(window, newTitle.toStringz);
}

string getTitle() {
    return title;
}

void close() {
    glfwSetWindowShouldClose(window, true);
}

bool isFullScreen() {
    return fullscreen;
}

bool mouseButtonClicked() {
    return mouseButtonPressed && !mouseButtonWasPressed;
}

bool mouseButtonHeld() {
    return mouseButtonPressed;
}

//! ====== End GLFW Tools ======


//* ======= OpenGL Tools =======

/// Returns success
private void initializeOpenGL() {
    /**
    Compare the return value of loadGL with the global `glSupport` constant to determine if the version of GLFW
    configured at compile time is the version that was loaded.
    */
    GLSupport returnedSupport = loadOpenGL();

    writeln(returnedSupport);

    glVersion = translateGLVersionName(returnedSupport);

    writeln("The current supported context is: ", glVersion);

    // Minimum version is GL 4.1 (July 26, 2010)
    if(returnedSupport < GLSupport.gl41) {

        OpenGLLoaderErrorLogger logger = new OpenGLLoaderErrorLogger();
        
        if(returnedSupport == GLSupport.noLibrary) {
            logger.attachTip("This application requires the GLFW library.\n" ~ "Is GLFW 3.3 installed?");
        } else if(returnedSupport == GLSupport.badLibrary) {
            logger.attachTip("The version of the GLFW library on your system is too low. Please upgrade.");
        } else {
            logger.attachTip("Your GPU cannot support the minimum OpenGL Version: 4.1! Released: July 26, 2010.\n" ~ "Are your graphics drivers updated?");
        }

        logger.execute();
    }

    // Something went horrifically wrong
    if (!isOpenGLLoaded()) {
        throw new Exception("OpenGL FAILED TO LOAD!");
    }

    // Wipe the error buffer completely
    OpenGlLogger.clearOpenGLErrors();
    
    // Vector2i windowSize = Window.getSize();

    glViewport(0, 0, windowSize.x, windowSize.y);

    bool cull = false;
    
    if (cull) {
        // Enable backface culling
        glEnable(GL_CULL_FACE);
    } 
    else {
        // Disable backface culling
        glDisable(GL_CULL_FACE);
    }

    // Alpha color blending
    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE);

    // Wireframe mode for debugging polygons
    // glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );

    // Enable depth testing
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);


    OpenGlLogger.execute("This error exists in the initialization stage. Something went very wrong!");
}

string getInitialOpenGLVersion() {
    string raw = to!string(loadedOpenGLVersion());
    char[] charArray = raw.dup[2..raw.length];
    return "OpenGL " ~ charArray[0] ~ "." ~ charArray[1];
}

string translateGLVersionName(GLSupport name) {
    string raw = to!string(name);
    char[] charArray = raw.dup[2..raw.length];
    return "OpenGL " ~ charArray[0] ~ "." ~ charArray[1];
}

void clear() {
    glClear(GL_COLOR_BUFFER_BIT);
}

void clear(double intensity) {
    clearColor = Vector3d(intensity);
    glClearColor(clearColor.x,clearColor.y,clearColor.z,1);
    glClear(GL_COLOR_BUFFER_BIT);
}

void clear(double r, double g, double b) {
    clearColor = Vector3d(r,g,b);
    glClearColor(clearColor.x,clearColor.y,clearColor.z,1);
    glClear(GL_COLOR_BUFFER_BIT);
}

void clear(Vector3d rgb) {
    clearColor = rgb;
    glClearColor(clearColor.x,clearColor.y,clearColor.z,1);
    glClear(GL_COLOR_BUFFER_BIT);
}

double getWidth() {
    return windowSize.x;
}
double getHeight() {
    return windowSize.y;
}

//! ===== End OpenGL Tools =====


// This is a simple tool by ADR to tell if the platform is posix.
bool isPosix() {
    version(Posix) return true;
    else return false;
}