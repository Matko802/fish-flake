import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
	id: root

	property string displayUser: Quickshell.env("USER") || ""

	IpcHandler {
		target: "lock"
		function lock() { LockState.locked = true }
	}

	LockContext {
		id: lockContext

		onUnlocked: {
			// Unlock the screen before exiting, or the compositor will display a
			// fallback lock you can't interact with.
			LockState.locked = false;
		}
	}

	WlSessionLock {
		id: lock
		locked: LockState.locked

		surface: Component {
			WlSessionLockSurface {
				id: surf
				color: "#000000"

				Text {
					id: clock
					property var date: new Date()

					anchors {
						horizontalCenter: parent.horizontalCenter
						top: parent.top
						topMargin: 100
					}

					color: "#ffffff"
					renderType: Text.NativeRendering
					font.pointSize: 72
					font.family: Theme.fontFamily

					// updates the clock every second
					Timer {
						running: true
						repeat: true
						interval: 1000

						onTriggered: clock.date = new Date();
					}

					text: {
						const hours = this.date.getHours().toString().padStart(2, '0');
						const minutes = this.date.getMinutes().toString().padStart(2, '0');
						return `${hours}:${minutes}`;
					}
				}

				ColumnLayout {
					anchors {
						horizontalCenter: parent.horizontalCenter
						top: parent.verticalCenter
					}

					spacing: 12

					Text {
						visible: root.displayUser !== ""
						Layout.alignment: Qt.AlignHCenter

						text: root.displayUser
						color: "#888888"
						font.pixelSize: 14
						font.family: Theme.fontFamily
					}

					RowLayout {
						Layout.alignment: Qt.AlignHCenter
						spacing: 8

						TextField {
							id: passwordBox

							implicitWidth: 260
							padding: 10

							color: "#ffffff"
							font.pixelSize: 14
							font.family: Theme.fontFamily
							selectedTextColor: "#000000"
							selectionColor: "#ffffff"

							background: Rectangle {
								color: "#000000"
								border.color: lockContext.showFailure ? "#ff0000" : "#ffffff"
								border.width: 1
							}

							focus: true
							enabled: !lockContext.unlockInProgress
							echoMode: TextInput.Password
							inputMethodHints: Qt.ImhSensitiveData

							// Update the text in the context when the text in the box changes.
							onTextChanged: lockContext.currentText = this.text;

							// Try to unlock when enter is pressed.
							onAccepted: lockContext.tryUnlock();

							// Update the text in the box to match the text in the context.
							// This makes sure multiple monitors have the same text.
							Connections {
								target: lockContext

								function onCurrentTextChanged() {
									passwordBox.text = lockContext.currentText;
								}
							}
						}

						Rectangle {
							id: unlockButton

							implicitWidth: 70
							implicitHeight: passwordBox.height

							color: unlockButtonMa.pressed ? "#ffffff" : "#000000"
							border.color: "#ffffff"
							border.width: 1
							opacity: lockContext.unlockInProgress || lockContext.currentText === "" ? 0.5 : 1.0

							Text {
								anchors.centerIn: parent

								text: "Unlock"
								color: unlockButtonMa.pressed ? "#000000" : "#ffffff"
								font.pixelSize: 11
								font.family: Theme.fontFamily
							}

							MouseArea {
								id: unlockButtonMa
								anchors.fill: parent
								cursorShape: Qt.PointingHandCursor

								// don't steal focus from the text box
								focusPolicy: Qt.NoFocus
								enabled: !lockContext.unlockInProgress && lockContext.currentText !== "";
								onClicked: lockContext.tryUnlock();
							}
						}
					}

					Text {
						visible: lockContext.showFailure
						Layout.alignment: Qt.AlignHCenter

						text: "This Password is Incorrect"
						color: "#ff0000"
						font.pixelSize: 12
						font.family: Theme.fontFamily
					}
				}
			}
		}
	}
}
