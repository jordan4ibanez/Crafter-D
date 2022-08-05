module math.delta;

import core.time;

public static class Delta {

    private static MonoTime before = MonoTime.zero;
    private static MonoTime after = MonoTime.zero;

    // High precision delta for users with powerful computers
    private static double delta = 0;

    // Calculates the delta time between frames. First will always be 0
    public static void calculateDelta() {
        this.after = MonoTime.currTime;
        Duration duration = after - before;
        this.delta = cast(double)duration.total!("nsecs") / 1_000_000_000.0;
        this.before = MonoTime.currTime;
    }

    // Allows any function or object to get the delta anywhere in the program
    public static double getDelta() {
        return this.delta;
    }
}

// Users do not have to explicitly call Delta class
alias getDelta = Delta.getDelta;
alias calculateDelta = Delta.calculateDelta;