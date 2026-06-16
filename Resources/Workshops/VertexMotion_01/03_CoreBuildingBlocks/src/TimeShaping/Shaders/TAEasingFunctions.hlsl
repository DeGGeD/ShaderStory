#ifndef TA_EASING_FUNCTIONS_INCLUDED
#define TA_EASING_FUNCTIONS_INCLUDED

// -----------------------------------------------------------------------------
// Workshop Helpers
// Reusable easing library
// Input:  t in [0..1]
// Output: usually in [0..1]
// -----------------------------------------------------------------------------

inline half EaseLinear(half t)
{
    return t;
}

inline half EaseInSine(half t)
{
    return 1.0h - cos(0.5h * PI * t);
}

inline half EaseOutSine(half t)
{
    return sin(0.5h * PI * t);
}

inline half EaseInOutSine(half t)
{
    return 0.5h - 0.5h * cos(PI * t);
}

inline half EaseInQuad(half t)
{
    return t * t;
}

inline half EaseOutQuad(half t)
{
    return t * (2.0h - t);
}

inline half EaseInOutQuad(half t)
{
    if (t < 0.5h)
        return 2.0h * t * t;

    half x = -2.0h * t + 2.0h;
    return 1.0h - 0.5h * x * x;
}

inline half EaseInCubic(half t)
{
    return t * t * t;
}

inline half EaseOutCubic(half t)
{
    half x = 1.0h - t;
    return 1.0h - x * x * x;
}

inline half EaseInOutCubic(half t)
{
    if (t < 0.5h)
        return 4.0h * t * t * t;

    half x = -2.0h * t + 2.0h;
    return 1.0h - 0.5h * x * x * x;
}

inline half EaseInOutSmoothstep(half t)
{
    return t * t * (3.0h - 2.0h * t);
}

inline half EaseInOutSmootherstep(half t)
{
    return t * t * t * (t * (t * 6.0h - 15.0h) + 10.0h);
}

inline half EaseOutBounce(half t)
{
    const half n1 = 7.5625h;
    const half d1 = 2.75h;

    if (t < 1.0h / d1)
        return n1 * t * t;
    else if (t < 2.0h / d1)
    {
        t -= 1.5h / d1;
        return n1 * t * t + 0.75h;
    }
    else if (t < 2.5h / d1)
    {
        t -= 2.25h / d1;
        return n1 * t * t + 0.9375h;
    }
    else
    {
        t -= 2.625h / d1;
        return n1 * t * t + 0.984375h;
    }
}

inline half EaseInOutBack(half t)
{
    const half c1 = 1.70158h;
    const half c2 = c1 * 1.525h;

    if (t < 0.5h)
    {
        half x = 2.0h * t;
        return 0.5h * (x * x * ((c2 + 1.0h) * x - c2));
    }
    else
    {
        half x = 2.0h * t - 2.0h;
        return 0.5h * (x * x * ((c2 + 1.0h) * x + c2) + 2.0h);
    }
}

inline half EaseOutElastic(half t)
{
    const half c4 = (2.0h * PI) / 3.0h;

    if (t == 0.0h) return 0.0h;
    if (t == 1.0h) return 1.0h;

    return pow(2.0h, -10.0h * t) * sin((t * 10.0h - 0.75h) * c4) + 1.0h;
}

inline half ApplyEaseByEnum(half t, int easeMode)
{
    switch (easeMode)
    {
        case 0: return EaseLinear(t);
        case 1: return EaseInSine(t);
        case 2: return EaseInOutSine(t);
        case 3: return EaseInQuad(t);
        case 4: return EaseOutBounce(t);
        case 5: return EaseInOutBack(t);
        case 6: return EaseOutElastic(t);
        default: return t;
    }
}

#endif