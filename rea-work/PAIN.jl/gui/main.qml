import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import jlqml

ApplicationWindow {
    id: root
    visible: true
    width: 1180
    height: 780
    title: "PAIN - Propeller Aircraft Interior Noise"
    color: "#f4f6f8"

    readonly property color ink: "#1a2332"
    readonly property color muted: "#5a6577"
    readonly property color panel: "#ffffff"
    readonly property color accent: "#0b6e4f"
    readonly property color warn: "#8a4b08"
    readonly property color border: "#d5dbe3"

    function isExtrapolated() {
        return pain.validity_tag === "X-EXTRAP"
    }

    function setSource(name) {
        // phase 33g: GUI offers aircraft only (e11/synthetic remain for tests/scripts)
        pain.source = name
    }

    function caseIdFromRow(rowText) {
        var parts = String(rowText).split("\t")
        return parts.length > 0 ? parts[0] : ""
    }

    function caseUnavailable(rowText) {
        return String(rowText).indexOf("[unavailable]") >= 0
    }

    Timer {
        interval: Math.max(1, Math.round(pain.smoke_ms))
        running: pain.smoke_ms > 0
        repeat: false
        onTriggered: Qt.quit()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "PAIN"
                font.pixelSize: 28
                font.bold: true
                color: root.ink
            }
            Text {
                text: "CCBlade + AcousticAnalogies cabin pipeline"
                color: root.muted
                font.pixelSize: 13
                Layout.fillWidth: true
            }
            Rectangle {
                visible: pain.validity_tag.length > 0
                radius: 4
                color: root.isExtrapolated() ? "#fff4e8" : "#e8ffe8"
                border.color: root.isExtrapolated() ? root.warn : root.accent
                implicitHeight: tagLabel.implicitHeight + 8
                implicitWidth: tagLabel.implicitWidth + 16
                Text {
                    id: tagLabel
                    anchors.centerIn: parent
                    text: pain.validity_tag
                    font.bold: true
                    color: root.isExtrapolated() ? root.warn : root.accent
                }
            }
        }

        TabBar {
            id: tabs
            Layout.fillWidth: true
            TabButton { text: "Run" }
            TabButton { text: "Validation" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex

            // ---- Run tab (aircraft pipeline) ----
            RowLayout {
                spacing: 14

                Frame {
                    Layout.preferredWidth: 360
                    Layout.fillHeight: true

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 12
                        clip: true

                        ColumnLayout {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "Run setup"
                                font.bold: true
                                font.pixelSize: 15
                                color: root.ink
                            }

                            Label { text: "Source"; color: root.muted }
                            ComboBox {
                                id: sourceBox
                                Layout.fillWidth: true
                                model: ["aircraft"]
                                Component.onCompleted: {
                                    pain.source = "aircraft"
                                    currentIndex = 0
                                }
                                onActivated: function (index) {
                                    root.setSource(model[index])
                                }
                            }
                            Label {
                                text: "e11 / synthetic are validation-only (not in GUI)."
                                color: root.muted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label { text: "Blocking"; color: root.muted }
                            ComboBox {
                                Layout.fillWidth: true
                                model: ["R2", "R1"]
                                Component.onCompleted: currentIndex = pain.blocking === "R1" ? 1 : 0
                                onActivated: function (index) {
                                    pain.blocking = model[index]
                                }
                            }

                            GridLayout {
                                columns: 2
                                columnSpacing: 8
                                rowSpacing: 6
                                Layout.fillWidth: true

                                Label { text: "L [m]"; color: root.muted }
                                TextField {
                                    Layout.fillWidth: true
                                    text: Number(pain.L).toFixed(3)
                                    onEditingFinished: pain.L = Number(text)
                                }

                                Label { text: "a [m]"; color: root.muted }
                                TextField {
                                    Layout.fillWidth: true
                                    text: Number(pain.a).toFixed(3)
                                    onEditingFinished: pain.a = Number(text)
                                }

                                Label { text: "theta0 [deg]"; color: root.muted }
                                TextField {
                                    Layout.fillWidth: true
                                    text: Number(pain.theta0_deg).toFixed(1)
                                    onEditingFinished: pain.theta0_deg = Number(text)
                                }

                                Label { text: "r_p [m]"; color: root.muted }
                                TextField {
                                    Layout.fillWidth: true
                                    text: Number(pain.r_p).toFixed(3)
                                    onEditingFinished: pain.r_p = Number(text)
                                }

                                Label { text: "phi_p [deg]"; color: root.muted }
                                TextField {
                                    Layout.fillWidth: true
                                    text: Number(pain.phi_p_deg).toFixed(1)
                                    onEditingFinished: pain.phi_p_deg = Number(text)
                                }

                                Label { text: "z_p [m]"; color: root.muted }
                                TextField {
                                    Layout.fillWidth: true
                                    text: Number(pain.z_p).toFixed(3)
                                    onEditingFinished: pain.z_p = Number(text)
                                }

                                Label { text: "n harmonics"; color: root.muted }
                                TextField {
                                    Layout.fillWidth: true
                                    text: String(Math.round(pain.n_harmonics))
                                    onEditingFinished: pain.n_harmonics = Number(text)
                                }

                                Label { text: "BPF [Hz]"; color: root.muted }
                                TextField {
                                    Layout.fillWidth: true
                                    text: Number(pain.bpf_Hz).toFixed(1)
                                    onEditingFinished: pain.bpf_Hz = Number(text)
                                }

                                Label { text: "C (Eq. 80)"; color: root.muted }
                                TextField {
                                    Layout.fillWidth: true
                                    text: Number(pain.C_struc).toFixed(2)
                                    onEditingFinished: pain.C_struc = Number(text)
                                }

                                Label { text: "eta_n bare"; color: root.muted }
                                TextField {
                                    Layout.fillWidth: true
                                    text: Number(pain.eta_n_bare).toFixed(3)
                                    onEditingFinished: pain.eta_n_bare = Number(text)
                                }

                                Label { text: "trim (auto, bare, phase3)"; color: root.muted }
                                TextField {
                                    Layout.fillWidth: true
                                    text: pain.trim
                                    onEditingFinished: pain.trim = text
                                }
                            }

                            Label {
                                visible: pain.source === "aircraft"
                                text: "Aircraft JSON path"
                                color: root.muted
                            }
                            TextField {
                                visible: pain.source === "aircraft"
                                Layout.fillWidth: true
                                text: pain.aircraft_json
                                onEditingFinished: pain.aircraft_json = text
                            }

                            Button {
                                Layout.fillWidth: true
                                Layout.topMargin: 8
                                text: pain.busy ? "Running..." : "Run"
                                enabled: !pain.busy
                                highlighted: true
                                onClicked: Julia.run_pain_from_qml()
                            }
                        }
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: pain.status
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            color: root.ink
                            font.pixelSize: 13
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16
                            Text {
                                text: pain.dBA_text
                                color: root.ink
                                font.bold: true
                            }
                            Text {
                                text: pain.sil_text
                                color: root.ink
                            }
                            Text {
                                text: pain.source_out.length ? ("source=" + pain.source_out) : ""
                                color: root.muted
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        Text { text: "Tonal SPL"; font.bold: true; color: root.ink }
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 90
                            TextArea {
                                readOnly: true
                                wrapMode: TextEdit.NoWrap
                                text: pain.tonal_text
                                color: root.ink
                                background: null
                            }
                        }

                        Text { text: "1/3-octave"; font.bold: true; color: root.ink }
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 80
                            TextArea {
                                readOnly: true
                                wrapMode: TextEdit.NoWrap
                                text: pain.third_text
                                color: root.ink
                                background: null
                            }
                        }

                        Text { text: "T1 gates"; font.bold: true; color: root.ink }
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            TextArea {
                                readOnly: true
                                wrapMode: TextEdit.Wrap
                                text: pain.t1_text
                                color: root.ink
                                background: null
                            }
                        }

                        Text { text: "T2 gates"; font.bold: true; color: root.ink }
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            TextArea {
                                readOnly: true
                                wrapMode: TextEdit.Wrap
                                text: pain.t2_text
                                color: root.ink
                                background: null
                            }
                        }

                        Text {
                            text: pain.notes
                            wrapMode: Text.WordWrap
                            color: root.muted
                            font.pixelSize: 11
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // ---- Validation tab (read-only registered cases) ----
            RowLayout {
                spacing: 14

                Frame {
                    Layout.preferredWidth: 420
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: "Validation cases"
                            font.bold: true
                            font.pixelSize: 15
                            color: root.ink
                        }
                        Text {
                            text: "Fixed inputs and criteria. Not a calibration tool."
                            color: root.muted
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            font.pixelSize: 11
                        }

                        ListView {
                            id: caseList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: pain.val_cases.split("\n").filter(function (s) { return s.length > 0 })
                            currentIndex: 0
                            delegate: ItemDelegate {
                                width: caseList.width
                                text: modelData
                                font.pixelSize: 11
                                opacity: root.caseUnavailable(modelData) ? 0.45 : 1.0
                                highlighted: ListView.isCurrentItem
                                onClicked: {
                                    caseList.currentIndex = index
                                    var id = root.caseIdFromRow(modelData)
                                    pain.val_selected = id
                                    Julia.select_validation_case_from_qml(id)
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Button {
                                text: pain.busy ? "Running…" : "Run"
                                enabled: !pain.busy && !root.caseUnavailable(caseList.currentItem ? caseList.currentItem.text : "")
                                highlighted: true
                                onClicked: {
                                    var id = root.caseIdFromRow(caseList.currentItem ? caseList.currentItem.text : pain.val_selected)
                                    Julia.run_validation_from_qml(id)
                                }
                            }
                            Button {
                                text: "Run all"
                                enabled: !pain.busy
                                onClicked: Julia.run_all_validation_from_qml()
                            }
                            Button {
                                text: "Open report"
                                enabled: pain.val_report_path.length > 0
                                onClicked: Julia.open_validation_report_from_qml()
                            }
                        }
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: pain.val_status
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            color: root.ink
                            font.pixelSize: 13
                        }
                        Text {
                            text: "Selected: " + pain.val_selected
                            color: root.muted
                            font.pixelSize: 11
                        }
                        Text {
                            text: pain.val_criterion
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            color: root.ink
                            font.pixelSize: 11
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 260
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Text { text: "Comparison plot"; font.bold: true; color: root.ink; font.pixelSize: 12 }
                                Image {
                                    id: valPlot
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: false
                                    source: pain.val_plot_path.length > 0
                                            ? ("file:///" + String(pain.val_plot_path).replace(/\\/g, "/"))
                                            : ""
                                }
                            }
                            ColumnLayout {
                                visible: pain.val_source_path.length > 0
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Text { text: "Source figure page"; font.bold: true; color: root.ink; font.pixelSize: 12 }
                                Image {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: false
                                    source: pain.val_source_path.length > 0
                                            ? ("file:///" + String(pain.val_source_path).replace(/\\/g, "/"))
                                            : ""
                                }
                            }
                        }

                        Text { text: "Result table / inputs echo"; font.bold: true; color: root.ink }
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            TextArea {
                                readOnly: true
                                wrapMode: TextEdit.NoWrap
                                text: pain.val_result_text
                                color: root.ink
                                font.family: "Consolas"
                                font.pixelSize: 11
                                background: null
                            }
                        }
                    }
                }
            }
        }
    }
}
