# MicroJam

![MicroJam allows users to record and share very short musical
performances on a touch screen. This user is recording a reply over a
previously saved
performance.](https://raw.githubusercontent.com/cpmpercussion/microjam/develop/images/rc1/microjam-rc-1-duo.jpg)

[![DOI](https://zenodo.org/badge/70703690.svg)](https://zenodo.org/badge/latestdoi/70703690)

MicroJam is a mobile app for sharing tiny touch-screen performances. Mobile applications that streamline creativity and social interaction have enabled a very broad audience to develop their own creative practices. While these apps have been very successful in visual arts (particularly photography), the idea of social music-making has not had such a broad impact. MicroJam includes several novel performance concepts intended to engage the casual music maker and inspired by current trends in social creativity support tools. Touch-screen performances are limited to 5-seconds, instrument settings are posed as sonic "filters", and past performances are arranged as a timeline with replies and layers. These features of MicroJam encourage users not only to perform music more frequently, but to engage with others in impromptu ensemble music making.

## Research Goals

- encourage everyday music-making with smartphones
- investigate asynchronous and distributed smartphone performance
- create generative microjams to mimic user styles

## Building

MicroJam is an iOS project written in Swift and using [`libpd`](https://github.com/libpd/libpd) for the audio backend and synthesis components. You should be able to build MicroJam by opening `microjam.xcworkspace` in Xcode (currently using 8.3.3).

Synthesis components can be found in the `synth` components and edited with [Pure Data](http://msp.ucsd.edu/software.html).

## Build instructions:

1. Install [homebrew](https://brew.sh).
2. Install Xcode 8 from Mac App Store.
3. Install Pure Data (`brew cask install pd`) and git (`brew install git`) and [Cocoapods](https://cocoapods.org/) (`brew install cocoapods`)
4. Clone project `git clone ...`
5. Install git submodules: `git submodule update --init --recursive`
6. Open up the main project workspace: `open microjam.xcworkspace` (n.b., `microjam.xcodeproj` will not have access to pods so will not build).
7. Build and test in simulator.

## Development instructions:

- Use [branches for developing new features](http://nvie.com/posts/a-successful-git-branching-model/) all development happens on the `dev` branch.
- Follow [Swift/Xcode best practices](https://github.com/futurice/ios-good-practices).
