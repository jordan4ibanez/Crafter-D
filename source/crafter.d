import std.stdio;

import Window = window.window;

public void main() {

    Window.initialize();

    Window.setTitle("Crafter v0.0.0 Prototype");

    while (!Window.shouldClose()) {
        
        Window.pollEvents();

        Window.clear(0.25);



        Window.swapBuffers();
    }

    Window.destroy();
    
}