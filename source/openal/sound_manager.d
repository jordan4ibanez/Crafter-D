module openal.sound_manager;

import std.stdio;
import bindbc.openal;
import openal.al_interface;
import vector_3d;
import matrix_4d;
import Math = math;
import Camera = camera.camera;

/*
This is the work horse of the game's OpenAL implementation.

No parts of the game will talk to OpenAL's buffer, source, and listener besides this.

This acts as a static factory class and will allow the whole program
to easily access all OpenAL related components, safely.
*/

private immutable bool debugNow = false;

// We do not need that many buffers, this is WAY more than enough
immutable int MAX_SOUNDS = 512;
private SoundBuffer[MAX_SOUNDS] buffers      = new SoundBuffer[MAX_SOUNDS];
private SoundSource[MAX_SOUNDS] soundSources = new SoundSource[MAX_SOUNDS];
private SoundListener listener;

// PlayMusic will LOCK it's buffer
public void playSound(string name) {
    if (!freeBuffers()) {
        return;
    }
    SoundBuffer thisBuffer = SoundBuffer(name);
    SoundSource thisSource = SoundSource(false, false);
    thisSource.setBuffer(thisBuffer.getID());
    thisSource.play();
    buffers[thisBuffer.getID()] = thisBuffer;
    soundSources[thisSource.getID()] = thisSource;
}
public void playSound(string name, Vector3d position, bool randomPitch) {
    if (!freeBuffers()) {
        return;
    }
    SoundBuffer thisBuffer = SoundBuffer(name);
    SoundSource thisSource = SoundSource(false, false);
    thisSource.setBuffer(thisBuffer.getID());
    thisSource.setPosition(position);
    if (randomPitch) {
        thisSource.setPitch(0.75 + (Math.random() / 2));
    }
    thisSource.play();
    buffers[thisBuffer.getID()] = thisBuffer;
    soundSources[thisSource.getID()] = thisSource;
}

bool freeBuffers() {
    bool found = false;
    // Couldn't find a free slot, something went seriously wrong
    // Either that, or somebody found a bug and went crazy
    // 0 is reserved for error
    for (int i = 1; i < MAX_SOUNDS; i++) {
        SoundSource thisSoundSource = soundSources[i];
        if (!thisSoundSource.doesExist() || !thisSoundSource.isPlaying()){
            // Free the buffer & sound source
            // THIS NEEDS TO GO IN THIS ORDER!
            // IF IT ISN'T THE BUFFERS WILL KEEP GOING UP!     
            soundSources[i].cleanUp();
            buffers[thisSoundSource.getBuffer()].cleanUp();
            

            // Now they're both freed
            found = true;

            if (debugNow) {
                writeln("deleted buffer,  ", thisSoundSource.getBuffer());
                writeln("deleted sound source, ", i);
            }
            break;
        }
    }
    if (!found) {
        writeln("All ", MAX_SOUNDS, " buffers are full (OpenAL)");
    }
    return found;
}

void debugALInterfaceThing() {
    writeln(soundSources[1].isPlaying());
}

void playSoundSource(string name) {
    // soundSources[name].play();
}

void removeSoundSource(string name) {
    // if ((name in soundSources) != null) {
       // soundSources[name].stop();
        // soundSources.remove(name);
    // }
}

void setAttenuationModel(ALint model) {
    alDistanceModel(model);
}

void updateListenerPosition() {
    Matrix4d cameraMatrix = Camera.getCameraMatrix();
    Vector3d cameraPosition = Camera.getPosition();
    listener.setPosition(cameraPosition);
    Vector3d at = Vector3d();
    // This might need testing
    cameraMatrix.positiveZ(at).negate();
    Vector3d up = Vector3d();
    //This might need testing
    cameraMatrix.positiveY(up);
    listener.setOrientation(at, up);

}


void initializeListener() {
    listener = SoundListener(Vector3d(0,0,0));
    if (debugNow) {
        writeln("OpenAL sound listener initialized");
    }
}

void cleanUpSoundManager() {
    cleanSoundBuffers();
    cleanSoundSources();
}

private void cleanSoundBuffers() {
    for (int i = 0; i < MAX_SOUNDS; i++) {
        buffers[i].cleanUp();
    }
    if (debugNow) {
        writeln("Sound buffers are cleaned");
    }
}

private void cleanSoundSources() {
    for (int i = 0; i < MAX_SOUNDS; i++) {
        soundSources[i].cleanUp();
    }
    if (debugNow) {
        writeln("Sound sources are cleaned");
    }
}