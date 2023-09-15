const BABYLON = require("babylonjs");

global.BABYLON = BABYLON;

const Ammo = require("./../public/ammo.wasm.js")
global.AmmoFn = Ammo;

require("./RunTests.bc.js");
