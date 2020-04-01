import QtQuick 2.0
import QtQuick.Controls 2.1
import Test 1.0

FramelessWindow {
    id: _framelessWindow

    default property alias content: _content.children

    Item {
        id: _content
        anchors.fill: parent
        anchors.margins: Qt.platform.os === "windows" ? _framelessWindow.borderMargins :0
        z: -100
    }

    property Component titleItem: Component {
        id: _titleCom

        Item {
            id: title
            anchors.fill: parent
            //color: "white"

            Row{
                anchors {
                    right: parent.right
                    top:parent.top
                }

                width: childrenRect.width
                height: parent.height

                Button {
                    text: "关闭"
                    height: parent.height

                    onClicked: {
                        window.close()
                    }
                }

                Button {
                    text: "最小化"
                    height: parent.height

                    onClicked: {
                        window.showMinimized()
                    }
                }

                Button {
                    text: "最大化"
                    height: parent.height

                    onClicked: {
                        if(window.isMaximized()) {
                            window.showNormal()
                        }else{
                            window.showMaximized()
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: _titleLoader
        anchors {
            left: _content.left
            top: _content.top
            right: _content.right
        }

        height: 30
        visible: Qt.platform.os === "windows"

        sourceComponent: visible ? _titleCom:undefined

        onLoaded: {
            if(Qt.platform.os === "windows") {
                _framelessWindow.setTitleBar(_titleLoader.item)
            }
        }
    }
}
