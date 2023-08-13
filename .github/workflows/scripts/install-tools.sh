#!/bin/bash

mkdir coverage
dart pub global activate melos
dart pub global activate dartdoc
dart pub global activate coverage
dart pub global activate coverde
melos bootstrap