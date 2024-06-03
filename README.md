## Linux
Astrometry.net platesolver to be used by INDIGO indigo_agent_astrometry.

### Build from source
To get astrometry.net and cfitsio sources run:
```
clone_sources.sh
```
To build it, run:
```
make
```

### Create deb packages for all architectures
Execute:
```
make debs-docker
```
NOTE: you need a running Docker and ARM qemu emulator.

## MacOS
MacOS local Astrometry.net plate-solver with GUI and embeded HTTP service.

To build from source, unpack astrometry.net and cfitsio sources to ../astrometry.net and ../cfitsio, or simply call:
```
clone_sources.sh
```
then build it with Xcode
