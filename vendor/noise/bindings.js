// Provides: noise_seed
function noise_seed(seed) {
    noise.seed(seed);
};

// Provides: noise_simplex2d
function noise_simplex2d(x, y) {
    return noise.simplex2(x, y);
}

// Provides: noise_perlin2d
function noise_perlin2d(x, y) {
    return noise.perlin2(x, y);
}
