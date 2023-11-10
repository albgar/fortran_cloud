Within the Materials at the eXascale project [MaX](https://www.max-centre.eu)
we consider the fortran_cloud package, possibly paired with HyperQueue and others,
as a tool to construct general workflows.

A number of additions have been made to the [original package by
Riccardo Bertossa](https://github.com/rikigigi/fortran_cloud):

* Complete CMake building framework (work in progress for refinements)
* Addition of the workflows subdirectory for workflow examples (wip)
* ...


To install, instatiate the git submodules:

    git submodule update --init 

and then just type

```
   cmake -S. -B_build -DCMAKE_INSTALL_PREFIX=/path/to/installation
   cmake --build _build
   cmake --install _build
```


