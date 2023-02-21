module engine.opengl.frustum_culling;

import vector_3d;
import matrix_4d;
import frustum_intersection;
import Camera = engine.camera.camera;


// These functions are a rollercoaster of one-linedness

bool insideFrustumSphere(float boundingRadius) {
    return FrustumIntersection(
            Matrix4d()
            .set(Camera.getCameraMatrix())
            .mul(Camera.getObjectMatrix())
    ).testSphere(0, 0, 0, boundingRadius);
}

bool insideFrustumAABB(Vector3d min, Vector3d max){
    return FrustumIntersection(
            Matrix4d()
            .set(Camera.getCameraMatrix())
            .mul(Camera.getObjectMatrix())
    ).testAab(min,max);
}