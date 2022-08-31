module engine.opengl.frustum_culling;

import vector_4d;
import frustum_intersection;

private immutable int NUMBER_OF_PLANES = 6;

private Vector4d[] frustumPlanes = {
    Vector4d[] temp;
    for (int i = 0; i < NUMBER_OF_PLANES; i++) {
        temp ~= Vector4d();
    }
    return temp;
}();