import QtQuick 2.0
import QtQuick.Controls 2.1
import Test 1.0

QuickWindow {
    id: window
    visible: true
    width: 640
    height: 480
    title: qsTr("Hello World")

    Rectangle{
        anchors.fill: parent
        color: "gray"
        //border.width: 5
        //border.color: "white"
    }
}
