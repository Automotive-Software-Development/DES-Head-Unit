import QtQuick 2.15
import QtMultimedia 5.15
import QtQuick.Controls 2.15
import Qt.labs.folderlistmodel 2.15
import QtQml 2.15
import QtGraphicalEffects 1.15


Item {
    id: videoLayout
    width: parent.width
    height: parent.height

    RadialGradient {
        visible: folderModel.count === 0
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: themeColor }
            GradientStop { position: 0.4; color: "transparent" }
            GradientStop { position: 1.0; color: "#000" }
        }
    }

    Text {
        visible: folderModel.count === 0
        color: "#fff"
        text: "Please plug-in your USB!"
        font.pointSize: 16
        anchors.centerIn: parent
    }

    GearMenu {
        id: gearMenu
        width: parent.width
        height: parent.height
    }

    Rectangle {
        id: topLine
        anchors.top: parent.top
        anchors.topMargin: 40
        width: parent.width
        border.color: "#fff"
        height: 1
    }

    Rectangle {
        id: bottomLine
        anchors {
            bottom: parent.bottom
            bottomMargin: 55
        }
        border.color: "#fff"
        width: parent.width
        height: 1
    }

    Back {
        id: videoLayoutForBack
        width: parent.width
    }

    Item {
        visible: folderModel.count > 0
        id: loopItemForVideo
        anchors{
            top: videoLayoutForBack.top
            topMargin: 40
            left: videoLayoutForBack.left
            bottom: bottomLine.top
        }
        width: parent.width * 0.4
        height: parent.height - videoLayoutForBack.height

        FolderListModel {
            id: folderModel
            folder: "file:///home/charmi/Videos" // Specify the path to your pendrive folder
            nameFilters: ["*.mp4"]
            showDirs: false
            onStatusChanged: {
                if (status === FolderListModel.Ready) {
                    for (var i = 0; i < folderModel.count; i++) {
                        videoListModel.append({
                                                  "name": folderModel.get(i, "fileName"),
                                                  "url": "file://" + folderModel.get(i, "filePath"),
                                                  "selected": false
                                              });
                    }
                }
            }
        }

        ScrollView {
            id: scrollView
            width: parent.width
            height: parent.height
            clip: true
            ScrollBar.horizontal.visible: false
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            ListView {
                id: listView
                width: parent.width
                height: parent.height
                model: ListModel {
                    id: videoListModel
                }
                delegate: Rectangle {
                    width: parent.width
                    height: 70
                    color: "transparent"
                    border.color: "#fff"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        text: model.name
                        color: "#fff"
                        font.pointSize: 16
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        onClicked: {
                            if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                                mediaPlayer.pause();
                            }
                            // Play the selected audio file
                            videoSelected = true;
                            videoPlayer.source = model.url;
                            videoPlayer.play();

                            videoPlayer.durationChanged.connect(function() {
                                console.log("Duration:", formatDuration(videoPlayer.duration));
                            });
                        }
                    }
                }
            }
        }
    }

    MediaPlayer {
        id: videoPlayer
        volume: 1.0 // Initial volume
        autoPlay: true
        onDurationChanged: {
            if (videoPlayer.duration > 0) {
                // Start the slider update timer when the duration becomes available
                sliderUpdateTimer.start();
            }
        }
        onPositionChanged: {
            if (videoPlayer.duration > 0) {
                control.value = videoPlayer.position / videoPlayer.duration;
                elapsedTime = formatDuration(videoPlayer.position);
            }
        }
        onErrorChanged: {
            // Debugging: Check if there's any error
            if (videoPlayer.error !== MediaPlayer.NoError) {
                console.error("MediaPlayer Error:", videoPlayer.errorString);
            }
        }
    }

    Rectangle {
        visible: folderModel.count > 0
        id: verticalSeparator
        color: "#fff"
        height: parent.height
        width: 1
        anchors {
            top: videoLayoutForBack.top
            topMargin: 40
            left: loopItemForVideo.right
            bottom: bottomLine.top
        }
    }

    /////////////////////////////////////////////////////////////////////////////////

    Item {
        visible: folderModel.count > 0
        height: parent.height
        width: parent.width - loopItemForVideo.width
        anchors {
            top: videoLayoutForBack.top
            topMargin: 40
            left: verticalSeparator.right
            bottom: bottomLine.top
        }

        RadialGradient {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: themeColor }
                GradientStop { position: 0.4; color: "transparent" }
                GradientStop { position: 1.0; color: "#000" }
            }
        }

        Text {
            visible: !videoSelected
            id: noVideoSelected
            text: "Please select a video to play!"
            font.pointSize: 16
            color: "#fff"
            anchors.centerIn: parent
        }

        Rectangle {
            visible: videoSelected
            id: videoLogoOuter
            height: parent.height - 4
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors {
                top: parent.top
                topMargin: 1
                bottom: parent.bottom
                bottomMargin: 1
            }

            color: "transparent"
            border.color: "#fff"
            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                source: videoPlayer
                fillMode: VideoOutput.PreserveAspectCrop
            }
        }

        Timer {
            id: sliderUpdateTimer
            interval: 1000 // Update every second
            running: videoPlayer.playbackState === MediaPlayer.PlayingState // Only update when the media is playing

            onTriggered: {
                if (videoPlayer.duration > 0) {
                    control.value = videoPlayer.position / videoPlayer.duration;
                }
            }
        }

        Slider {
            visible: videoSelected
            id: control
            value: 0.0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: volumeControl.top
            width: 600

            background: Rectangle {
                x: control.leftPadding
                y: control.topPadding + control.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 4
                width: control.availableWidth
                height: implicitHeight
                radius: 2
                color: "#bdbebf"

                Rectangle {
                    width: control.visualPosition * parent.width
                    height: parent.height
                    color: "gray"
                    radius: 2
                }
            }

            handle: Rectangle {
                x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
                y: control.topPadding + control.availableHeight / 2 - height / 2
                implicitWidth: 20
                implicitHeight: 20
                radius: 10
                color: control.pressed ? "#f0f0f0" : "#f6f6f6"
                border.color: "#bdbebf"
            }

            onValueChanged: {
                // Calculate the position in milliseconds based on the slider's value
                var newPosition = control.value * videoPlayer.duration;

                // Seek to the new position
                videoPlayer.seek(newPosition);
            }
        }

        Button {
            id: playOrPauseButton
            visible: videoSelected
            height: control.height
            width: 30
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.top: control.bottom
            background: Rectangle {
                color: "transparent"
            }

            Image {
                id: playOrPause
                source: videoPlayer.playbackState === MediaPlayer.PlayingState ? "qrc:/assets/Images/Pause.svg" : "qrc:/assets/Images/Play.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
            }
            onClicked: {
                if (videoPlayer.playbackState === MediaPlayer.PlayingState) {
                    videoPlayer.pause();
                } else {
                    videoPlayer.play();
                }
            }
        }

        Button {
            id: nextVideo
            visible: videoSelected
            height: control.height
            width: 30
            anchors.left: playOrPauseButton.right
            anchors.leftMargin: 3
            anchors.top: control.bottom
            background: Rectangle {
                color: "transparent"
            }
            enabled: listView.currentIndex < videoListModel.count - 1
            Image {
                id: nextButton
                source: "qrc:/assets/Images/Next.svg"
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
            }
            onClicked: {
                if (listView.currentIndex < videoListModel.count - 1) {
                    listView.currentIndex++;
                    playCurrentItem();
                }
            }
        }

        Text {
            visible: videoSelected
            id: videoDuration
            text: videoPlayer.duration > 0 ? elapsedTime + "/" + formatDuration(videoPlayer.duration) : elapsedTime + "/" + "0:00"
            font.pointSize: 12
            color: "#fff"
            anchors.bottom: volumeUp.bottom
            anchors.left: nextVideo.right
            anchors.leftMargin: 8
        }

        Image {
            visible: videoSelected
            id: volumeUp
            source: "qrc:/assets/Images/Volume_Up.svg"
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 20
            width: 25
            height: 25
            MouseArea {
                id: volumeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    volumeControl.visible = !volumeControl.visible;
                }
            }
        }

        Slider {
            visible: false
            id: volumeControl
            value: videoPlayer.volume // Initial value
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.right: volumeUp.left
            width: 150

            // Slider background and handle properties...
            background: Rectangle {
                x: volumeControl.leftPadding
                y: volumeControl.topPadding + volumeControl.availableHeight / 2 - height / 2
                implicitWidth: 200
                implicitHeight: 3
                width: volumeControl.availableWidth
                height: implicitHeight
                radius: 2
                color: "#bdbebf"

                Rectangle {
                    width: volumeControl.visualPosition * parent.width
                    height: parent.height
                    color: "gray"
                    radius: 2
                }
            }
            handle: Rectangle {
                x: volumeControl.leftPadding + volumeControl.visualPosition * (volumeControl.availableWidth - width)
                y: volumeControl.topPadding + volumeControl.availableHeight / 2 - height / 2
                implicitWidth: 20
                implicitHeight: 20
                radius: 10
                color: volumeControl.pressed ? "#f0f0f0" : "#f6f6f6"
                border.color: "#bdbebf"
            }

            onValueChanged: {
                // Set the volume of the media player
                videoPlayer.volume = volumeControl.value;
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////////////

    property bool videoSelected: false;
    property bool videoListModelPopulated: false;
    property string elapsedTime: '0:00';
    property bool fullScreenMode: false;
}

