# Contributing

MicroJam is currently a research project into music technology and is mainly of interest to students and researchers in this field.

The best way you could contributed right now would be to test beta versions, there's a signup sheet on [microjam.info](http://microjam.info).
However we also welcome new ideas or forks that take transform our ideas in some way. 

If you're interested in using microjam for education or research get in touch with [Charles Martin](http://charlesmartin.com.au).

## Building

MicroJam is an iOS project written in Swift and using [`libpd`](https://github.com/libpd/libpd) for the audio backend and synthesis components. You should be able to build MicroJam by opening `microjam.xcworkspace` in Xcode (currently using 8.3.3).

Synthesis components can be found in the `synth` components and edited with [Pure Data](http://msp.ucsd.edu/software.html).

## Build instructions:

1. Install [homebrew](https://brew.sh).
2. Install Xcode 8 from Mac App Store.
3. Install Pure Data (`brew cask install pd`) and git (`brew install git`) and [Cocoapods](https://cocoapods.org/) (`git install cocoapods`)
4. Clone project `git clone ...`
5. Install git submodules: `git submodule update --init --recursive`
6. Open up the main project workspace: `open microjam.xcworkspace` (n.b., `microjam.xcodeproj` will not have access to pods so will not build).
7. Build and test in simulator.

## Development instructions:

- Use [branches for developing new features](http://nvie.com/posts/a-successful-git-branching-model/) all development happens on the `dev` branch.
- Follow [Swift/Xcode best practices](https://github.com/futurice/ios-good-practices).
