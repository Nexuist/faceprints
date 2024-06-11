#!/bin/bash

# Install dependencies
swift package resolve

# Build the project
swift build

# Run the project
swift run Faceprints
