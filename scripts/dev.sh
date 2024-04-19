rojo sourcemap examples-sourcemap.project.json --output sourcemap.json
darklua process --config .darklua-dev.json node_modules/ dist/node_modules

rojo serve examples.project.json &
    rojo sourcemap examples-sourcemap.project.json --output sourcemap.json --watch &
    darklua process --config .darklua-dev.json --watch modules/ dist/
