#!/bin/sh

hotdog input OK Cancel "Type the name of a program to open:" | xargs -r -I {} sh -c "{}"