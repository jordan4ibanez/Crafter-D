module engine.opengl.frustum_culling;

import matrix_4d;
import frustum_intersection;

private immutable int NUMBER_OF_PLANES = 6;

private FrustumIntersection frustumIntersect = FrustumIntersection();

private Matrix4d prjViewMatrix = Matrix4d();


void updateFrustum(Matrix4d cameraMatrix, Matrix4d objectMatrix) {
    // Calculate projection view matrix
    prjViewMatrix.set(objectMatrix);
    prjViewMatrix.mul(cameraMatrix);
    // Update frustum intersection class
    frustumIntersect.set(prjViewMatrix);
}

bool insideFrustumSphere(float x0, float y0, float z0, float boundingRadius) {
    return frustumIntersect.testSphere(x0, y0, z0, boundingRadius);
}