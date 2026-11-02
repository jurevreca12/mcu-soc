# mcu-soc
An experimental open source microcontroller style system-on-chip.


## Devcontainer
The entire design environment sits inside a devcontainer. You can open it either using vscode (or similar) or using the CLI devcontainer interface:
```
    git clone https://github.com/jurevreca12/mcu-soc.git
    cd mcu-soc
    devcontainer up
    devcontainer exec bash
    bender update
```


## Bender - Dependency management
We use the [bender](https://github.com/pulp-platform/bender.git) dependency management tool to manage hardware dependency. 
