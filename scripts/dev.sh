rojo sourcemap examples-sourcemap.project.json --output sourcemap.json
darklua process --config .darklua-dev.json node_modules/ dist/node_modules
darklua process --config .darklua-dev.json examples/ dist/examples

rojo serve examples.project.json &
    rojo sourcemap examples-sourcemap.project.json --output sourcemap.json --watch &
    darklua process --config .darklua-dev.json --watch src/ dist/src
    darklua process --config .darklua-dev.json --watch examples/ dist/examples
