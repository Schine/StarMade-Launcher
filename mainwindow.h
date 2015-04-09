#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

    void checkJavaVersion(int maxFileReadAttempts = 3);
    int shouldInstall64Bit();

    void mousePressEvent(QMouseEvent* event);
    void mouseMoveEvent(QMouseEvent* event);

private:
    Ui::MainWindow *ui;
    QPoint m_mouseClickPos;
};

#endif // MAINWINDOW_H
