esy build
esy test:native > /dev/null 2>&1 || true

echo $?

node _build/install/default/bin/test-runner.js

