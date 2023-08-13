CMD /C dart pub global activate melos
CMD /C dart pub global activate dartdoc
REM Workaround an issue when running global executables on Windows for the first time.
CMD /C melos > NUL
melos bootstrap