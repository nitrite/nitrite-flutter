CMD /C mkdir coverage
CMD /C dart pub global activate melos
CMD /C dart pub global activate dartdoc
CMD /C dart pub global activate coverage
CMD /C dart pub global activate coverde
REM Workaround an issue when running global executables on Windows for the first time.
CMD /C melos > NUL
melos bootstrap