module engine.opengl.frustum_culling;

import vector_3d;
import matrix_4d;
import frustum_intersection;

private immutable int NUMBER_OF_PLANES = 6;

private FrustumIntersection frustumIntersect = FrustumIntersection();


void updateFrustum(Matrix4d cameraMatrix, Matrix4d objectMatrix) {
    Matrix4d prjViewMatrix = Matrix4d();
    prjViewMatrix.set(cameraMatrix);
    prjViewMatrix.mul(objectMatrix);
    frustumIntersect.set(prjViewMatrix);
}

bool insideFrustumSphere(float x0, float y0, float z0, float boundingRadius) {
    return frustumIntersect.testSphere(x0, y0, z0, boundingRadius);
}

bool insideFrustumAABB(Vector3d min, Vector3d max){
    return frustumIntersect.testAab(min,max);
}