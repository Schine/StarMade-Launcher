#-------------------------------------------------
#
# Project created by QtCreator 2015-04-08T15:49:38
#
#-------------------------------------------------

QT       += core gui opengl

CONFIG += c++11

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = StarMadeLauncher
TEMPLATE = app


SOURCES += main.cpp\
        mainwindow.cpp \
    glwidget.cpp \
    launcherwidget.cpp \
    widgetpane.cpp \
    glutil.cpp \
    gltexture.cpp

HEADERS  += mainwindow.h \
    glwidget.h \
    launcherwidget.h \
    widgetpane.h \
    glutil.h \
    gltexture.h

FORMS    += mainwindow.ui
