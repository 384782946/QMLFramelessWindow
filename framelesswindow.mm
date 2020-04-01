#include "framelesswindow.h"

#ifdef Q_OS_MAC
#include <QDebug>
#include <Cocoa/Cocoa.h>

FramelessWindow::FramelessWindow(QWindow *parent)
    : QQuickWindow(parent),
      m_draggableHeight(0),
      m_bWinMoving(false),
      m_bMousePressed(false),
      m_bCloseBtnQuit(true),
      m_bNativeSystemBtn(false),
      m_bIsCloseBtnEnabled(true),
      m_bIsMinBtnEnabled(true),
      m_bIsZoomBtnEnabled(true),
      m_bTitleBarVisible(false)
{
    initUI();
}

//此类用于支持重载系统按钮的行为
//this Objective-c class is used to override the action of sysytem close button and zoom button
//https://stackoverflow.com/questions/27643659/setting-c-function-as-selector-for-nsbutton-produces-no-results
@interface ButtonPasser : NSObject{
}
@property(readwrite) FramelessWindow* window;
+ (void)closeButtonAction:(id)sender;
- (void)zoomButtonAction:(id)sender;
@end

@implementation ButtonPasser{
}
+ (void)closeButtonAction:(id)sender
{
    Q_UNUSED(sender);
    ProcessSerialNumber pn;
    GetFrontProcess (&pn);
    ShowHideProcess(&pn,false);
}
- (void)zoomButtonAction:(id)sender
{
    Q_UNUSED(sender);
    if (0 == self.window) return;
    if (self.window->isMaximized()) self.window->showNormal();
    else self.window->showMaximized();
}
@end

void FramelessWindow::initUI()
{
    m_bNativeSystemBtn = false;

    //如果当前osx版本老于10.9，则后续代码不可用。转为使用定制的系统按钮，不支持自由缩放窗口及窗口阴影
    if (QSysInfo::MV_None == QSysInfo::macVersion())
    {
        if (QSysInfo::MV_None == QSysInfo::MacintoshVersion) {
            setFlags(Qt::FramelessWindowHint);
            return;
        }
    }
    if (QSysInfo::MV_10_9 >= QSysInfo::MacintoshVersion) {
        setFlags(Qt::FramelessWindowHint);
        return;
    }

    NSView* view = (NSView*)winId();
    if (0 == view) {setFlags(Qt::FramelessWindowHint); return;}
    NSWindow *window = view.window;
    if (0 == window) {setFlags(Qt::FramelessWindowHint); return;}

    //设置标题文字和图标为不可见
    window.titleVisibility = NSWindowTitleHidden;   //MAC_10_10及以上版本支持
    //设置标题栏为透明
    window.titlebarAppearsTransparent = YES;        //MAC_10_10及以上版本支持
    //设置不可由标题栏拖动,避免与自定义拖动冲突
    [window setMovable:NO];                         //MAC_10_6及以上版本支持
    //window.movableByWindowBackground = YES;
    //设置view扩展到标题栏
    window.styleMask |=  NSWindowStyleMaskFullSizeContentView; //MAC_10_10及以上版本支持

    m_bNativeSystemBtn = true;

    ButtonPasser * passer = [[ButtonPasser alloc] init];
    passer.window = this;
    //重载全屏按钮的行为
    //override the action of fullscreen button
    NSButton *zoomButton = [window standardWindowButton:NSWindowZoomButton];
    [zoomButton setTarget:passer];
    [zoomButton setAction:@selector(zoomButtonAction:)];
}

void FramelessWindow::setCloseBtnQuit(bool bQuit)
{
    if (bQuit || !m_bNativeSystemBtn) return;
    NSView* view = (NSView*)winId();
    if (0 == view) return;
    NSWindow *window = view.window;
    if (0 == window) return;

    //重载关闭按钮的行为
    //override the action of close button
    //https://stackoverflow.com/questions/27643659/setting-c-function-as-selector-for-nsbutton-produces-no-results
    //https://developer.apple.com/library/content/documentation/General/Conceptual/CocoaEncyclopedia/Target-Action/Target-Action.html
    NSButton *closeButton = [window standardWindowButton:NSWindowCloseButton];
    [closeButton setTarget:[ButtonPasser class]];
    [closeButton setAction:@selector(closeButtonAction:)];
}

void FramelessWindow::setCloseBtnEnabled(bool bEnable)
{
    if (!m_bNativeSystemBtn) return;
    NSView* view = (NSView*)winId();
    if (0 == view) return;
    NSWindow *window = view.window;
    if (0 == window) return;

    m_bIsCloseBtnEnabled = bEnable;
    if (bEnable){
        [[window standardWindowButton:NSWindowCloseButton] setEnabled:YES];
    }else{
        [[window standardWindowButton:NSWindowCloseButton] setEnabled:NO];
    }
}

void FramelessWindow::setMinBtnEnabled(bool bEnable)
{
    if (!m_bNativeSystemBtn) return;
    NSView* view = (NSView*)winId();
    if (0 == view) return;
    NSWindow *window = view.window;
    if (0 == window) return;

    m_bIsMinBtnEnabled = bEnable;
    if (bEnable){
        [[window standardWindowButton:NSWindowMiniaturizeButton] setEnabled:YES];
    }else{
        [[window standardWindowButton:NSWindowMiniaturizeButton] setEnabled:NO];
    }
}

void FramelessWindow::setZoomBtnEnabled(bool bEnable)
{
    if (!m_bNativeSystemBtn) return;
    NSView* view = (NSView*)winId();
    if (0 == view) return;
    NSWindow *window = view.window;
    if (0 == window) return;

    m_bIsZoomBtnEnabled = bEnable;
    if (bEnable){
        [[window standardWindowButton:NSWindowZoomButton] setEnabled:YES];
    }else{
        [[window standardWindowButton:NSWindowZoomButton] setEnabled:NO];
    }
}

bool FramelessWindow::isMaximized() const
{
    return Qt::WindowMaximized & this->windowStates();
}

void FramelessWindow::setDraggableAreaHeight(int height)
{
    if (height < 0) height = 0;
    m_draggableHeight = height;
}

void FramelessWindow::mousePressEvent(QMouseEvent *event)
{
    if ((event->button() != Qt::LeftButton) || isMaximized() )
    {
        return QQuickWindow::mousePressEvent(event);
    }

    int height = size().height();
    if (m_draggableHeight > 0) height = m_draggableHeight;
    QRect rc;
    rc.setRect(0,0,size().width(), height);
    if(rc.contains(this->mapFromGlobal(QCursor::pos()))==true)//如果按下的位置
    {
        m_WindowPos =this->geometry().topLeft();
        m_MousePos = event->globalPos();
        m_bMousePressed = true;
    }
    return QQuickWindow::mousePressEvent(event);
}

void FramelessWindow::mouseReleaseEvent(QMouseEvent *event)
{
    m_bWinMoving = false;
    if ((event->button() == Qt::LeftButton))
    {
        m_bMousePressed = false;
    }
    return QQuickWindow::mouseReleaseEvent(event);
}

void FramelessWindow::mouseMoveEvent(QMouseEvent *event)
{
    if (!m_bMousePressed) return QQuickWindow::mouseMoveEvent(event);
    m_bWinMoving = true;
    auto pos = m_WindowPos + (event->globalPos() - m_MousePos);
    this->setGeometry(pos.x(),pos.y(),this->width(),this->height());
    return QQuickWindow::mouseMoveEvent(event);
}

void FramelessWindow::mouseDoubleClickEvent(QMouseEvent *event)
{
    auto pos = event->pos();
    if(pos.y() < 20) {
        showMaximized();
    }
    return QQuickWindow::mouseMoveEvent(event);
}

void FramelessWindow::resizeEvent(QResizeEvent *event)
{
    QQuickWindow::resizeEvent(event);
    //TODO
//    if (!isFullScreen())
//    {
//        emit restoreFromFullScreen();
//    }
}

void FramelessWindow::onRestoreFromFullScreen()
{
    setTitlebarVisible(false);
}

void FramelessWindow::setTitlebarVisible(bool bTitlebarVisible)
{
    if (!m_bNativeSystemBtn) return;
    NSView* view = (NSView*)winId();
    if (0 == view) return;
    NSWindow *window = view.window;
    if (0 == window) return;

    m_bTitleBarVisible = bTitlebarVisible;
    if (bTitlebarVisible)
    {
        window.styleMask ^= NSWindowStyleMaskFullSizeContentView; //MAC_10_10及以上版本支持
    }else{
        window.styleMask |= NSWindowStyleMaskFullSizeContentView; //MAC_10_10及以上版本支持
    }
}
#endif //Q_OS_MAC
