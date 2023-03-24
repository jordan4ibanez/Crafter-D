module gui.gui;

import std.stdio;
import bindbc.opengl;
import doml.vector_2d;
import doml.vector_4d;

import Font = razor_font;
import Texture = texture.texture;
import Window = window.window;
import Shader = shader.shader;
import Camera = camera.camera;

import mesh.mesh;


// Allows elements to be bolted to a part of the window
enum WINDOW_POSITION : Vector2d {

    TOP_LEFT      = Vector2d( 0.0, 0.0 ),
    TOP_CENTER    = Vector2d( 0.5, 0.0 ),
    TOP_RIGHT     = Vector2d( 1.0, 0.0 ),

    CENTER_LEFT   = Vector2d( 0.0, 0.5 ),
    CENTER_CENTER = Vector2d( 0.5, 0.5 ),
    CENTER_RIGHT  = Vector2d( 1.0, 0.5 ),

    BOTTOM_LEFT   = Vector2d( 0.0, 1.0 ),
    BOTTOM_CENTER = Vector2d( 0.5, 1.0 ),
    BOTTOM_RIGHT  = Vector2d( 1.0, 1.0 )

}

// Export as public enums so you don't have to type out WINDOW_POSITION every time
enum TOP_LEFT      = WINDOW_POSITION.TOP_LEFT;
enum TOP_CENTER    = WINDOW_POSITION.TOP_CENTER;
enum TOP_RIGHT     = WINDOW_POSITION.TOP_RIGHT;

enum CENTER_LEFT   = WINDOW_POSITION.CENTER_LEFT;
enum CENTER_CENTER = WINDOW_POSITION.CENTER_CENTER;
enum CENTER_RIGHT  = WINDOW_POSITION.CENTER_RIGHT;

enum BOTTOM_LEFT   = WINDOW_POSITION.BOTTOM_LEFT;
enum BOTTOM_CENTER = WINDOW_POSITION.BOTTOM_CENTER;
enum BOTTOM_RIGHT  = WINDOW_POSITION.BOTTOM_RIGHT;

// Default the position to top left
private immutable WINDOW_POSITION DEFAULT = WINDOW_POSITION.TOP_LEFT;

/// This auto converts the enumerator into a direct position on screen
private Vector2d grabWindowPosition(WINDOW_POSITION inputPosition) {
    Vector2d windowSize = Window.getSize();
    
    return Vector2d(
        inputPosition.x * windowSize.x,
        inputPosition.y * windowSize.y
    );
}

// This auto converts the text into position utilizing it's offset size when rendered
private Vector2d grabRealPosition(Text text) {
    Vector2d windowPosition = grabWindowPosition(text.windowPosition);
    Font.RazorTextSize textSize = Font.getTextSize(text.size, text.textData);

    Vector2d outputtingPosition;

    // This automatically centers the text as much as possible.
    // So if you're in the center, you're in the direct center.
    // If you're on the right, you're exactly on the right, etc.

    final switch (cast(int)(text.windowPosition.x * 10)) {
        case (0): {
            outputtingPosition.x = windowPosition.x;
            break;
        }
        case (5): {
            outputtingPosition.x = windowPosition.x - (textSize.width / 2.0);
            break;
        }
        case (10): {
            outputtingPosition.x = windowPosition.x - textSize.width;
            break;
        }
    }

    final switch (cast(int)(text.windowPosition.y * 10)) {
        case (0): {
            outputtingPosition.y = windowPosition.y;
            break;
        }
        case (5): {
            outputtingPosition.y = windowPosition.y - (textSize.height / 2.0);
            break;
        }
        case (10): {
            outputtingPosition.y = windowPosition.y - textSize.height;
            break;
        }
    }

    return outputtingPosition;
}

Vector2d grabFinalPosition(Text text) {
    Vector2d realPosition = grabRealPosition(text);
    realPosition.x += text.position.x;
    realPosition.y += text.position.y;
    return realPosition;
}

Vector2d grabButtonFix(Button button) {

    WINDOW_POSITION windowPosition = button.windowPosition;

    Vector2d outputtingPosition;

    double buttonWidth = button.size.x;
    double buttonHeight = button.size.y;


    final switch (cast(int)(windowPosition.x * 10)) {
        case (0): {
            outputtingPosition.x = buttonWidth;
            break;
        }
        case (5): {
            outputtingPosition.x = -buttonWidth / 2.0;
            break;
        }
        case (10): {
            outputtingPosition.x = -buttonWidth;
            break;
        }
    }

    final switch (cast(int)(windowPosition.y * 10)) {
        case (0): {
            outputtingPosition.y = 0;
            break;
        }
        case (5): {
            outputtingPosition.y = -buttonHeight / 2.0;
            break;
        }
        case (10): {
            outputtingPosition.y = -buttonHeight;
            break;
        }
    }

    return outputtingPosition;
}

class GUI {

    private Button[string] buttonObjects;
    private Text[string] textObjects;

    void addText(string name, Text text) {
        this.textObjects[name] = text;
    }

    void addButton(string name, Button button) {
        this.buttonObjects[name] = button;
    }

    void render() {

        Font.switchColors(1,0,0,1);

        Shader.setUniformMatrix4("2d", "cameraMatrix", Camera.updateGuiMatrix());

        foreach (Button button; buttonObjects) {
            

            Vector2d windowPosition = grabWindowPosition(button.windowPosition);

            windowPosition.x -= Window.getWidth() / 2.0;
            windowPosition.y -= Window.getHeight() / 2.0;

            Vector2d buttonFix = grabButtonFix(button);

            windowPosition.x += buttonFix.x;
            windowPosition.y += buttonFix.y;

            windowPosition.x += button.position.x;
            windowPosition.y -= button.position.y;

            Shader.setUniformMatrix4("2d", "objectMatrix", Camera.setGuiObjectMatrix(Vector2d(0,0)));
            
            Font.renderToCanvas(
                windowPosition.x + (Window.getWidth() / 2.0) + button.padding,
                windowPosition.y + (Window.getHeight() / 2.0) + button.padding,
                button.text.size,
                button.text.textData
            );
            Font.render();

            Shader.setUniformMatrix4("2d", "objectMatrix", Camera.setGuiObjectMatrix(
                    windowPosition
                )
            );

            button.mesh.render("2d");
        }

        Shader.setUniformMatrix4("2d", "objectMatrix", Camera.setGuiObjectMatrix(Vector2d(0,0)));

        foreach (Text text; textObjects) {

            Vector2d finalPosition = grabFinalPosition(text);

            Font.renderToCanvas(finalPosition.x, finalPosition.y, text.size, text.textData);
        }

        Font.render();
    }

    void collisionDetect() {



        if (!Window.mouseButtonClicked()) {
            return;
        }

        Vector2d mousePosition = Window.getMousePosition();
        

        foreach (string name, Button button; buttonObjects) {
            

            // We're getting the top left of the button

            Vector2d windowPosition = grabWindowPosition(button.windowPosition);

            Vector2d buttonFix = grabButtonFix(button);

            windowPosition.x += buttonFix.x;
            windowPosition.y += buttonFix.y;

            windowPosition.x += button.position.x;
            windowPosition.y -= button.position.y;

            // Check if collided
            if (mousePosition.x >= windowPosition.x && mousePosition.x <= windowPosition.x + button.size.x &&
                mousePosition.y >= windowPosition.y && mousePosition.y <= windowPosition.y + button.size.y) {


                if (button.buttonFunction !is null) {
                    button.buttonFunction();
                }
                return;
            }

            
        }

    }

    void destroy() {
        foreach (Button button; buttonObjects) {
            button.mesh.destroy();            
        }
    }

}


class Button {

    // Real window position
    WINDOW_POSITION windowPosition = DEFAULT;

    // Offset from real window position in pixels
    Vector2d position;

    Vector2d size;

    double padding = 0.0;
    
    private Text text;

    Mesh mesh;

    // What this button does when pushed
    void delegate() buttonFunction;

    this(Text text) {

        this.text = text;

        Font.RazorTextSize textSize = Font.getTextSize(text.size, text.textData);

        // pixels
        padding = 10;

        size = Vector2d(
            textSize.width + (padding * 2),
            textSize.height + (padding * 2)
        );

        this.mesh = new Mesh()
            .addVertices2d([
                0.0,    0.0,
                0.0,    size.y,
                size.x, size.y,
                size.x, 0.0
            ])
            .addTextureCoordinates([
                0.0, 0.0,
                0.0, 1.0,
                1.0, 1.0,
                1.0, 0.0
            ])
            .addIndices([
                0,1,2,2,3,0
            ])
            // This is hardcoded for now
            .setTexture(Texture.getTexture("textures/button.png"))
            .finalize();
    }

    Button setPostion(Vector2d position) {
        this.position = position;
        return this;
    }

    Button setWindowPosition(WINDOW_POSITION windowPosition) {
        this.windowPosition = windowPosition;
        return this;
    }

    Button setFunction(void delegate() buttonFunction) {
        this.buttonFunction = buttonFunction;
        return this;
    }
    
}

class Text {

    double size = 0;

    // If the text is within a button, this will be ignored
    WINDOW_POSITION windowPosition = DEFAULT;

    // This is the position relative to the window position
    Vector2d position;

    Vector4d color = Vector4d(0,0,0,1);

    private string textData;

    this(string textData) {
        this.textData = textData;
    }

    /// This is the position relative to the window position
    Text setPosition(Vector2d position) {
        this.position = position;
        return this;
    }

    /// This is the position in the window where the text will be bolted to
    Text setWindowPosition(WINDOW_POSITION windowPosition) {
        this.windowPosition = windowPosition;
        return this;
    }

    Text setSize(double size) {
        this.size = size;
        return this;
    }

    Text setColor(double r, double b, double g, double a) {
        this.color = Vector4d(r,g,b,a);
        return this;
    }
    
}