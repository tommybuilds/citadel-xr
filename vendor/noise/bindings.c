#define STUB(name) \
    void name() { \
        return; \
    }

STUB(noise_seed);
STUB(noise_simplex2d);
STUB(noise_perlin2d);
