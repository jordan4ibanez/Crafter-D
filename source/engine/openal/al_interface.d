module engine.openal.al_interface;

import bindbc.openal;
import std.stdio;
import stb_vorbis;
import std.conv: to;
import vector_3d;
import openal.sound_manager;

/*
This is utilizing OpenAL Soft for maximum compatibility.

This holds all OpenAL init, and structs for sound_manager to use.
*/

private immutable bool debugNow = false;

private void* context;
private void* device;
private string deviceName;

// Holds the cache of loaded sounds - Automatically deleted on program exit, it's contained in GC Heap
private VorbisCache[string] soundCache;

bool initializeOpenAL() {

    ALSupport returnedError;
    
    version(Windows) {
        returnedError = loadOpenAL("libs/soft_oal.dll");
    } else {
        // Linux,FreeBSD, OpenBSD, macOSX, haiku, etc
        returnedError = loadOpenAL();
    }

    if(returnedError < ALSupport.al11) {

        if(returnedError == ALSupport.noLibrary) {
            // GLFW shared library failed to load
            writeln("FAILED TO LOAD OPENAL! LIBRARY IS NOT INSTALLED!");
        }
        else if(returnedError == ALSupport.badLibrary) {
            // One or more symbols failed to load.
            writeln("BAD OPENAL LIBRARY INSTALLED! DO YOU HAVE OPENAL 1.1+?");
        }
        return true;
    }

    device = alcOpenDevice(cast(const(char)*)null);

    deviceName = to!string(alcGetString(device, ALC_DEVICE_SPECIFIER));

    // Blank devices aren't allowed, this is a software api
    if (deviceName == null) {
        writeln("OPENAL NULL DEVICE!!");
        return true;
    }
    if (debugNow) {
        writeln("the AL device pointer: ", device);
        writeln("the AL device name: ", deviceName);
    }

    ALCint[] attributes = [
        ALC_MAJOR_VERSION, 1,
        ALC_MINOR_VERSION, 1,
        0,                 0
    ];

    // Attempt to get a context
    if (device != null) {
        context = alcCreateContext(device,attributes.ptr);
    } else {
        // Something went horribly wrong
        return true;
    }

    // Now we have a context
    alcMakeContextCurrent(context);

    // Generate buffers
    alGetError();

    // We don't need that many buffers
    // alGenBuffers(256,buffers.ptr);

    // Make sure nothing dumb is happening
    debugOpenAL();

    initializeListener();

    if (debugNow) {
        writeln("OpenAL initialized successfully!");
    }

    // No errors
    return false;
}

struct VorbisCache {
    short[] pcm;
    int pcmLength = 0;
    ubyte channels = 0;
    int sampleRate = 0;
    this(
        short[] pcm,
        int pcmLength,
        ubyte channels,
        int sampleRate
    ) {
        this.pcm = pcm;
        this.pcmLength = pcmLength;
        this.channels = channels;
        this.sampleRate = sampleRate;
    }
}

struct SoundBuffer {

    private bool exists = false;
    private ALuint id = 0;

    ALuint getID() {
        return this.id;
    }

    this(string fileName) {

        // Hold this data in an associative array
        // After the first call, the game can pull data out of it instead of from disk

        // Can load out of RAM
        if (fileName in soundCache) {
            VorbisCache cacheSound = soundCache[fileName];
            // Get a buffer ID
            alGenBuffers(1, &this.id);
            alBufferData(
                this.id,
                cacheSound.channels == 1 ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16,
                cast(const(void)*)cacheSound.pcm,
                cacheSound.pcmLength,
                cacheSound.sampleRate
            );
            if (debugNow) {
                writeln("Loaded ", fileName, " from cache!");
            }
        } else { // Load from disk and cache for next use
            VorbisDecoder vorbisHandler = VorbisDecoder(fileName);
            int streamLength = vorbisHandler.streamLengthInSamples();
            short[] pcm = new short[streamLength];
            int pcmLength = cast(int)(pcm.length * short.sizeof);
            ubyte channels = vorbisHandler.chans();
            int sampleRate = vorbisHandler.sampleRate();

            vorbisHandler.getSamplesShortInterleaved(channels, pcm.ptr, streamLength);
            // Get a buffer ID
            alGenBuffers(1, &this.id);
            alBufferData(
                this.id,
                channels == 1 ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16,
                cast(const(void)*)pcm,
                pcmLength,
                sampleRate
            );
            // Make sure nothing dumb is happening
            // debugOpenAL();
            if (debugNow) {
                writeln("caching ", fileName, "!");
            }
            soundCache[fileName] = VorbisCache(pcm,pcmLength,channels,sampleRate);
        }
        if (debugNow) {
            writeln("My sound buffer ID is: ", this.id);
        }
        this.exists = true;
    }

    bool doesExist() {
        return this.exists;
    }

    void cleanUp() {
        if (this.exists) {
            alDeleteBuffers(1, &this.id);
            if (debugNow) {
                writeln("cleaned up albuffer ", this.id);
            }
            this.exists = false;
        }
    }
}


struct SoundSource {
    private bool exists = false;
    private ALuint id = 0;
    private ALuint buffer = 0;

    this(bool loop, bool relative) {
        alGenSources(1, &this.id);
        alSourcei(this.id,AL_LOOPING, loop ? AL_TRUE : AL_FALSE);
        alSourcei(this.id, AL_SOURCE_RELATIVE, relative ? AL_TRUE : AL_FALSE);
        this.exists = true;
        if (debugNow) {
            writeln("My sound source ID is: ", this.id);
        }
    }

    bool doesExist() {
        return this.exists;
    }

    void cleanUp() {
        if (this.exists){
            alDeleteSources(1, &this.id);
            this.exists = false;
            if (debugNow) {
                writeln("cleaned up sound source: ", this.id);
            }
        }
    }

    ALuint getID() {
        return this.id;
    }

    bool isPlaying() {
        ALint value;
        alGetSourcei(this.id, AL_SOURCE_STATE, &value);
        return value == AL_PLAYING;
    }

    void pause() {
        alSourcePause(this.id);
    }

    void play() {
        alSourcePlay(this.id);
    }

    void setBuffer(ALuint bufferID) {
        stop();
        alSourcei(this.id, AL_BUFFER, bufferID);
        this.buffer = bufferID;
    }

    ALuint getBuffer() {
        return this.buffer;
    }

    void setPosition(Vector3d newPosition) {
        alSource3f(
            this.id,
            AL_POSITION,
            newPosition.x,
            newPosition.y,
            newPosition.z
        );
    }

    void setPitch(float pitch) {
        alSourcef(this.id, AL_PITCH, pitch);
    }

    void stop() {
        alSourceStop(this.id);
    }
}


// There can only be one listener or else weird things will happen
struct SoundListener {
    this(Vector3d position) {
        alListener3f(AL_POSITION, position.x, position.y, position.z);
        alListener3f(AL_VELOCITY,0.0,0.0,0.0);
    }

    void setSpeed(Vector3d speed){
        alListener3f(AL_VELOCITY, speed.x, speed.y, speed.z);
    }

    void setPosition(Vector3d newPosition){
        alListener3f(AL_POSITION, newPosition.x, newPosition.y, newPosition.z);
    }

    void setOrientation(Vector3d at, Vector3d up) {
        float[6] data = [
            at.x,
            at.y,
            at.z,
            up.x,
            up.y,
            up.z
        ];
        alListenerfv(AL_ORIENTATION, data.ptr);
    }
}





void debugOpenAL() {
    int error = alGetError();

    if (!error == AL_NO_ERROR) {

        writeln("OpenAL buffer error! Error number: ", error);
        switch (error) {
            case ALC_INVALID_DEVICE: {
                writeln("AL_INVALID_DEVICE");
                break;
            }
            case ALC_INVALID_CONTEXT: {
                writeln("AL_INVALID_CONTEXT");
                break;
            }
            case AL_INVALID_VALUE:{
                writeln("AL_INVALID_VALUE");
                break;
            }
            case AL_OUT_OF_MEMORY: {
                writeln("AL_OUT_OF_MEMORY");
                break;
            }                
            default:
                writeln("Unknown error code");
        }

        assert(true == false);
    }
}

void cleanUpOpenAL() {

    cleanUpSoundManager();

    alcMakeContextCurrent(null);
    alcDestroyContext(context);
    alcCloseDevice(device);
    if (debugNow) {
        writeln("OpenAL has successfully closed");
    }
}