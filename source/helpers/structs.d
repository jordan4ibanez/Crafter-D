module helpers.structs;

struct Vector2I {
    int x = 0;
    int y = 0;
    this(int x, int y){
        this.x = x;
        this.y = y;
    }
}

struct Vector3I {
    int x = 0;
    int y = 0;
    int z = 0;
    this(int x, int y, int z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
}