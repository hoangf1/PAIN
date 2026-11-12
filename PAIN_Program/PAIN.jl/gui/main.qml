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

    // Phase 130 (2026-11-04): the window is drawn light, so the controls' palette is set light too. Without it the
    // Fusion style takes the system palette, and in Windows dark mode the input text is white on the white fields.
    palette.window: "#f4f6f8"
    palette.windowText: ink
    palette.base: "#ffffff"
    palette.alternateBase: "#eef1f4"
    palette.text: ink
    palette.button: "#e9edf1"
    palette.buttonText: ink
    palette.placeholderText: muted
    palette.highlight: accent
    palette.highlightedText: "#ffffff"
    palette.toolTipBase: "#ffffff"
    palette.toolTipText: ink
    palette.brightText: "#ffffff"
    palette.light: "#ffffff"
    palette.midlight: "#e9edf1"
    palette.mid: border
    palette.dark: "#9aa4b0"
    palette.shadow: "#5a6577"


    // Phase 114 - run-status box. Every Run button gets one, so the user can tell which of five things the panel
    // is showing: nothing run yet, a result recorded earlier and read from disk, a run in progress, a result this
    // session just computed, or one that is out of date because an input moved since. runState comes from Julia
    // (the *_state Observables); STALE is decided here, by comparing the inputs now on screen with the ones the
    // run actually used.
    component RunStatusBox: Frame {
        id: rsb
        property string runState: "ready"      // ready | snapshot | running | done | error
        property string statusText: ""
        property string logText: ""
        property string signature: ""          // the inputs this panel would run with, as one string
        property string pendingSignature: ""
        property string ranSignature: ""
        property bool expanded: false
        readonly property bool stale: runState === "done" && signature !== ranSignature
        readonly property string shownState: stale ? "stale" : runState

        function stateColor(st) {
            if (st === "running") return "#0b5fa5"
            if (st === "done") return root.accent
            if (st === "stale" || st === "snapshot") return root.warn
            if (st === "error") return "#a32015"
            return root.muted
        }
        function stateLabel(st) {
            if (st === "running") return "GENERATING"
            if (st === "done") return "FRESH"
            if (st === "stale") return "STALE"
            if (st === "snapshot") return "RECORDED"
            if (st === "error") return "ERROR"
            return "READY"
        }
        function stateHint(st) {
            if (st === "running") return "Running now. Each step appears below as it finishes."
            if (st === "done") return "Generated in this session, from the inputs now on screen."
            if (st === "stale") return "An input changed since this result was generated, so what you see is out of date. Press Run to regenerate it."
            if (st === "snapshot") return "Read from disk - recorded earlier, not run in this session. Press Run to compute it now."
            if (st === "error") return "The run stopped before it finished. The reason is in the log below."
            return "Nothing has been run in this session yet."
        }

        onRunStateChanged: {
            if (runState === "running") {
                pendingSignature = signature
                expanded = true
            } else if (runState === "done") {
                ranSignature = pendingSignature
            }
        }

        Layout.fillWidth: true
        padding: 8

        ColumnLayout {
            anchors.fill: parent
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    radius: 3
                    color: rsb.stateColor(rsb.shownState)
                    implicitWidth: rsbPill.implicitWidth + 12
                    implicitHeight: rsbPill.implicitHeight + 6
                    Text {
                        id: rsbPill
                        anchors.centerIn: parent
                        text: rsb.stateLabel(rsb.shownState)
                        color: "#ffffff"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                BusyIndicator {
                    running: rsb.runState === "running"
                    visible: running
                    implicitWidth: 18
                    implicitHeight: 18
                }

                Text {
                    Layout.fillWidth: true
                    text: rsb.statusText
                    color: root.ink
                    font.pixelSize: 12
                    // Wrap like the plain status line this box replaced; a very long reason still elides.
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

                Button {
                    text: rsb.expanded ? "Hide log" : "Show log"
                    flat: true
                    font.pixelSize: 11
                    onClicked: rsb.expanded = !rsb.expanded
                }
            }

            Text {
                Layout.fillWidth: true
                text: rsb.stateHint(rsb.shownState)
                color: (rsb.shownState === "stale" || rsb.shownState === "error") ? root.warn : root.muted
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }

            ScrollView {
                visible: rsb.expanded && rsb.logText.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 110
                clip: true
                TextArea {
                    readOnly: true
                    text: rsb.logText
                    font.family: "Consolas"
                    font.pixelSize: 11
                    wrapMode: TextArea.NoWrap
                    onTextChanged: cursorPosition = length
                }
            }
        }
    }

    // The inputs the Run tab and the printed-output tab would run with; a change here makes their result stale.
    function pipelineSignature() {
        // the fields are the run's inputs (a Save rewrites the project file but not what a run computes)
        return pain.input_values_json
    }

    function isExtrapolated() {
        return pain.validity_tag === "X-EXTRAP"
    }

    function caseIdFromRow(rowText) {
        var parts = String(rowText).split("\t")
        return parts.length > 0 ? parts[0] : ""
    }

    function caseUnavailable(rowText) {
        return String(rowText).indexOf("[unavailable]") >= 0
    }

    // Cache case rows so the ListView model is not a fresh JS array on every
    // pain.* Observable notify (that reset currentIndex and cleared the highlight).
    property var valCaseRows: []
    // Phase 151 (2026-11-11): the play flag lives in QML. A binding on pain.cm_playing was not re-evaluated after QML
    // wrote that property itself, so the play Timer never started; Julia gets a copy for the log.
    property bool cmPlaying: false
    readonly property string valCasesWatch: pain.val_cases
    onValCasesWatchChanged: rebuildValCaseRows()
    function rebuildValCaseRows() {
        valCaseRows = String(pain.val_cases || "").split("\n").filter(function (s) { return s.length > 0 })
    }
    // Phase 151: frame paths (a JSON list from Julia) as a Repeater model
    function cmFrames(js) {
        try { var a = JSON.parse(String(js)); return Array.isArray(a) ? a : [] } catch (e) { return [] }
    }
    function indexOfValSelected() {
        var id = String(pain.val_selected || "")
        for (var i = 0; i < valCaseRows.length; i++) {
            if (caseIdFromRow(valCaseRows[i]) === id)
                return i
        }
        return -1
    }
    Component.onCompleted: {
        rebuildValCaseRows()
        reloadValInfo()
    }

    // ---- Validation tab case info (from §2.13 via case_info_json) ----
    property var valInfo: ({})
    readonly property string valInfoWatch: pain.val_info_json
    onValInfoWatchChanged: reloadValInfo()
    function reloadValInfo() {
        try {
            valInfo = JSON.parse(String(pain.val_info_json || "{}"))
        } catch (e) {
            valInfo = {}
        }
    }

    onClosing: Julia.mark_gui_closed_from_qml()

    Timer {
        interval: Math.max(1, Math.round(pain.smoke_ms))
        running: pain.smoke_ms > 0
        repeat: false
        onTriggered: {
            Julia.mark_gui_closed_from_qml()
            Qt.quit()
        }
    }

    // Phase 37i smoke: same call as Validation Run button, then quit when Done.
    Timer {
        interval: 50
        running: String(pain.smoke_case || "").length > 0
        repeat: false
        onTriggered: Julia.run_validation_from_qml(pain.smoke_case)
    }
    Timer {
        property real elapsedMs: 0
        interval: 200
        running: String(pain.smoke_case || "").length > 0
        repeat: true
        onTriggered: {
            elapsedMs += interval
            var st = String(pain.val_status || "")
            if (!pain.busy && st.indexOf("Done") === 0) {
                running = false
                Julia.mark_gui_closed_from_qml()
                Qt.quit()
            } else if (elapsedMs >= 120000) {
                running = false
                Julia.mark_gui_closed_from_qml()
                Qt.quit()
            }
        }
    }

    // Phase 114 smoke: open the Validation tab, run one case, and save a shot of the window so the run-status
    // box (pill, hint and verbose log) is checked as it is drawn, not only as Observables.
    Timer {
        interval: 300
        running: String(pain.smoke_runbox_png || "").length > 0
        repeat: false
        onTriggered: {
            tabs.currentIndex = 1
            Julia.select_validation_case_from_qml("BLK_P68")
            Julia.run_validation_from_qml("BLK_P68")
        }
    }
    Timer {
        property real elapsedMs: 0
        property bool shotTaken: false
        interval: 250
        running: String(pain.smoke_runbox_png || "").length > 0
        repeat: true
        onTriggered: {
            elapsedMs += interval
            if (shotTaken) return
            var st = String(pain.val_status || "")
            if ((!pain.busy && st.indexOf("Done") === 0) || elapsedMs >= 90000) {
                shotTaken = true
                mainColumn.grabToImage(function (result) {
                    result.saveToFile(String(pain.smoke_runbox_png))
                    console.log("RUN_STATUS_BOX saved:", String(pain.smoke_runbox_png))
                    Julia.mark_gui_closed_from_qml()
                    Qt.quit()
                })
            }
        }
    }

    // Phase 127 smoke: the Run tab's input tabs, drawn: a shot of the Propeller tab and of a Numerics tab.
    Timer {
        property int step: 0
        interval: 700
        running: String(pain.smoke_inputs_png || "").length > 0
        repeat: true
        onTriggered: {
            var out = String(pain.smoke_inputs_png)
            step += 1
            if (step === 1) {
                tabs.currentIndex = 0
                inputsFrame.groupIndex = 1
            } else if (step === 2) {
                inputsFrame.grabToImage(function (result) {
                    result.saveToFile(out)
                    console.log("RUN_INPUTS saved:", out)
                })
            } else if (step === 3) {
                for (var i = 0; i < inputsFrame.groups.length; i++)
                    if (inputsFrame.groups[i].name === "Numerics: Blocking") inputsFrame.groupIndex = i
            } else if (step === 4) {
                var out2 = out.replace(".png", "_numerics.png")
                inputsFrame.grabToImage(function (result) {
                    result.saveToFile(out2)
                    console.log("RUN_INPUTS saved:", out2)
                    Julia.mark_gui_closed_from_qml()
                    Qt.quit()
                })
            }
        }
    }

    // Phase 134 smoke: the Coverage tab, drawn: a shot with the cases with a verdict, then one with every case.
    Timer {
        property int step: 0
        interval: 700
        running: String(pain.smoke_coverage_png || "").length > 0
        repeat: true
        onTriggered: {
            var out = String(pain.smoke_coverage_png)
            step += 1
            if (step === 1) {
                tabs.currentIndex = 4
            } else if (step === 2) {
                coveragePage.grabToImage(function (result) {
                    result.saveToFile(out)
                    console.log("COVERAGE saved:", out)
                })
            } else if (step === 3) {
                coverageShowAll.checked = true
            } else if (step === 4) {
                var out2 = out.replace(".png", "_all.png")
                coveragePage.grabToImage(function (result) {
                    result.saveToFile(out2)
                    console.log("COVERAGE saved:", out2)
                    Julia.mark_gui_closed_from_qml()
                    Qt.quit()
                })
            }
        }
    }

    // Phase 151d smoke: open the Cabin modes tab (the frames are built on open), press Play, and grab the frame view
    // twice, some ticks apart; the two shots must differ (the mode is seen moving).
    Timer {
        property int step: 0
        property real elapsedMs: 0
        interval: 500
        running: String(pain.smoke_cabin_png || "").length > 0
        repeat: true
        onTriggered: {
            var out = String(pain.smoke_cabin_png)
            elapsedMs += interval
            if (step === 0) {
                tabs.currentIndex = 3
                step = 1
            } else if (step === 1) {
                if (pain.cm_frame_path.length > 0 && !pain.busy) {
                    root.cmPlaying = true
                    pain.cm_playing = true
                    step = 2
                } else if (elapsedMs >= 150000) {
                    console.log("CABIN_ANIM: no frames after", elapsedMs, "ms")
                    Julia.mark_gui_closed_from_qml()
                    Qt.quit()
                }
            } else if (step === 2) {
                cmFrameView.grabToImage(function (result) {
                    result.saveToFile(out)
                    console.log("CABIN_ANIM saved:", out, "frame", pain.cm_frame_index)
                })
                step = 3
            } else if (step === 3) {
                var out2 = out.replace(".png", "_later.png")
                cmFrameView.grabToImage(function (result) {
                    result.saveToFile(out2)
                    console.log("CABIN_ANIM saved:", out2, "frame", pain.cm_frame_index)
                    Julia.mark_gui_closed_from_qml()
                    Qt.quit()
                })
                step = 4
            }
        }
    }

    ColumnLayout {
        id: mainColumn
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
            onCurrentIndexChanged: {
                // Coverage tab (index 4): re-parse §2.13 so an edited .md shows without restart.
                if (currentIndex === 4)
                    Julia.reload_validation_docs_from_qml()
                // Phase 151c: the cabin-mode frames (tab index 3) are built when the tab first opens, not only on Refresh
                if (currentIndex === 3 && pain.cm_frame_path.length === 0 && !pain.busy)
                    Julia.run_cabin_modes_from_qml()
            }
            TabButton { text: "Run" }
            TabButton { text: "Validation" }
            TabButton { text: "Printed outputs" }
            TabButton { text: "Cabin modes" }
            TabButton { text: "Coverage" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex

            // ---- Run tab (aircraft pipeline) ----
            RowLayout {
                spacing: 14

                Frame {
                    id: inputsFrame
                    Layout.preferredWidth: 520
                    Layout.fillHeight: true
                    background: Rectangle { color: root.panel; border.color: root.border; radius: 4 }

                    // Phase 127: every input as a field, grouped in tabs (gui_inputs.jl); the project file is optional
                    property var groups: JSON.parse(pain.inputs_json).groups
                    property var values: JSON.parse(pain.input_values_json)
                    property int groupIndex: 0

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        Text {
                            text: "Inputs"
                            font.bold: true
                            font.pixelSize: 15
                            color: root.ink
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            TextField {
                                id: projectPathField
                                Layout.fillWidth: true
                                text: pain.project_path
                                placeholderText: "project file (optional)"
                                ToolTip.visible: hovered
                                ToolTip.text: "A project file is optional: Open fills the fields from it, Save writes the fields to it."
                            }
                            Button {
                                text: "Open"
                                enabled: !pain.busy
                                onClicked: Julia.open_project_from_qml(projectPathField.text)
                            }
                            Button {
                                text: "Save"
                                enabled: !pain.busy
                                onClicked: Julia.save_project_from_qml(projectPathField.text)
                            }
                            Button {
                                text: "Defaults"
                                enabled: !pain.busy
                                onClicked: Julia.reset_project_from_qml()
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            text: pain.project_note
                            color: root.muted
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 8

                            ListView {
                                id: groupList
                                Layout.preferredWidth: 150
                                Layout.fillHeight: true
                                clip: true
                                model: inputsFrame.groups
                                currentIndex: inputsFrame.groupIndex
                                delegate: ItemDelegate {
                                    width: groupList.width
                                    height: 30
                                    highlighted: index === inputsFrame.groupIndex
                                    text: modelData.name
                                    font.pixelSize: 12
                                    onClicked: inputsFrame.groupIndex = index
                                }
                            }

                            ScrollView {
                                id: fieldScroll
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                contentWidth: availableWidth

                                ColumnLayout {
                                    width: fieldScroll.availableWidth
                                    spacing: 4

                                    Repeater {
                                        model: inputsFrame.groups.length > 0 ? inputsFrame.groups[inputsFrame.groupIndex].fields : []

                                        delegate: ColumnLayout {
                                            id: fieldRow
                                            property var f: modelData
                                            property string val: inputsFrame.values[f.key] !== undefined ? inputsFrame.values[f.key] : f.value
                                            Layout.fillWidth: true
                                            spacing: 1

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Label {
                                                    Layout.fillWidth: true
                                                    text: fieldRow.f.label + (fieldRow.f.unit.length ? " [" + fieldRow.f.unit + "]" : "")
                                                    color: root.ink
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                }
                                                Label {
                                                    // numbers compare as numbers ("0" is the default "0.0")
                                                    visible: fieldRow.f.kind !== "elements" && fieldRow.f["default"].length > 0
                                                             && (isNaN(Number(fieldRow.val)) || isNaN(Number(fieldRow.f["default"]))
                                                                 ? fieldRow.val !== fieldRow.f["default"]
                                                                 : Number(fieldRow.val) !== Number(fieldRow.f["default"]))
                                                    text: "default " + fieldRow.f["default"]
                                                    color: root.warn
                                                    font.pixelSize: 10
                                                }
                                            }

                                            Loader {
                                                Layout.fillWidth: true
                                                sourceComponent: fieldRow.f.kind === "bool" ? boolEditor
                                                               : fieldRow.f.kind === "choice" ? choiceEditor
                                                               : fieldRow.f.kind === "elements" ? elementsEditor
                                                               : textEditor
                                            }

                                            Component {
                                                id: textEditor
                                                TextField {
                                                    text: fieldRow.val
                                                    placeholderText: fieldRow.f["default"].length ? "" : "(not given)"
                                                    selectByMouse: true
                                                    ToolTip.visible: hovered && fieldRow.f.tip.length > 0
                                                    ToolTip.text: fieldRow.f.tip
                                                    onEditingFinished: Julia.set_gui_input_from_qml(fieldRow.f.key, text)
                                                }
                                            }
                                            Component {
                                                id: boolEditor
                                                CheckBox {
                                                    checked: fieldRow.val === "true"
                                                    text: checked ? "on" : "off"
                                                    ToolTip.visible: hovered && fieldRow.f.tip.length > 0
                                                    ToolTip.text: fieldRow.f.tip
                                                    onToggled: Julia.set_gui_input_from_qml(fieldRow.f.key, checked ? "true" : "false")
                                                }
                                            }
                                            Component {
                                                id: choiceEditor
                                                ComboBox {
                                                    model: fieldRow.f.choices
                                                    currentIndex: Math.max(0, fieldRow.f.choices.indexOf(fieldRow.val))
                                                    ToolTip.visible: hovered && fieldRow.f.tip.length > 0
                                                    ToolTip.text: fieldRow.f.tip
                                                    onActivated: function (i) {
                                                        Julia.set_gui_input_from_qml(fieldRow.f.key, fieldRow.f.choices[i])
                                                    }
                                                }
                                            }
                                            Component {
                                                id: elementsEditor
                                                TextArea {
                                                    text: fieldRow.val
                                                    placeholderText: "(not given)"
                                                    font.family: "Consolas"
                                                    font.pixelSize: 11
                                                    wrapMode: TextArea.NoWrap
                                                    background: Rectangle { border.color: root.border; color: "#ffffff" }
                                                    ToolTip.visible: hovered && fieldRow.f.tip.length > 0
                                                    ToolTip.text: fieldRow.f.tip
                                                    onEditingFinished: Julia.set_gui_input_from_qml(fieldRow.f.key, text)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            text: pain.bpf_text
                            color: root.muted
                        }

                        Button {
                            Layout.fillWidth: true
                            text: pain.busy ? "Running..." : "Run"
                            enabled: !pain.busy
                            highlighted: true
                            onClicked: Julia.run_pain_from_qml()
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

                        RunStatusBox {
                            runState: pain.run_state
                            statusText: pain.status
                            logText: pain.run_log
                            signature: root.pipelineSignature()
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
                            model: root.valCaseRows
                            // Selection keyed by case id (survives Run / Run all and model rebuilds).
                            currentIndex: root.indexOfValSelected()
                            Component.onCompleted: {
                                if (root.valCaseRows.length > 0 && String(pain.val_selected || "").length === 0)
                                    Julia.select_validation_case_from_qml(root.caseIdFromRow(root.valCaseRows[0]))
                            }
                            delegate: ItemDelegate {
                                width: caseList.width
                                text: modelData
                                font.pixelSize: 11
                                opacity: root.caseUnavailable(modelData) ? 0.45 : 1.0
                                highlighted: root.caseIdFromRow(modelData) === pain.val_selected
                                onClicked: {
                                    var id = root.caseIdFromRow(modelData)
                                    // Always select through Julia so val_selected / val_runnable stay in sync.
                                    Julia.select_validation_case_from_qml(id)
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Button {
                                text: pain.busy ? "Running…" : "Run"
                                // Use Julia-side val_selected / val_runnable — not ListView.currentItem
                                // (currentItem.text was unreliable after selecting other rows).
                                enabled: !pain.busy && pain.val_runnable && pain.val_selected.length > 0
                                highlighted: true
                                onClicked: Julia.run_validation_from_qml(pain.val_selected)
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

                    ScrollView {
                        id: valDetailScroll
                        anchors.fill: parent
                        anchors.margins: 12
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        onAvailableWidthChanged: contentWidth = availableWidth
                        Component.onCompleted: contentWidth = availableWidth

                        ColumnLayout {
                            width: valDetailScroll.availableWidth
                            spacing: 8

                            RunStatusBox {
                                runState: pain.val_state
                                statusText: pain.val_status
                                logText: pain.val_log
                                signature: pain.val_selected
                            }
                            Text {
                                text: (root.valInfo && root.valInfo.title)
                                      ? (String(root.valInfo.title) + " (" + pain.val_selected + ")")
                                      : ("Selected: " + pain.val_selected)
                                color: root.ink
                                font.bold: true
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            Text {
                                visible: !!(root.valInfo && root.valInfo.verifies)
                                text: "What it tests: " + (root.valInfo.verifies || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.valInfo && root.valInfo.why)
                                text: "Why it is here: " + (root.valInfo.why || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.valInfo && root.valInfo.meaning)
                                text: "A pass means: " + (root.valInfo.meaning || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.valInfo && root.valInfo.missing)
                                text: "Not covered: " + (root.valInfo.missing || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.valInfo && root.valInfo.chain_span)
                                text: "Chain span: " + (root.valInfo.chain_span || "") + "; compared with "
                                      + (root.valInfo.compared_with || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.valInfo && root.valInfo.recorded)
                                text: "Recorded outcome: " + (root.valInfo.recorded || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.valInfo && root.valInfo.explanation)
                                text: "Explanation: " + (root.valInfo.explanation || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                text: pain.val_criterion
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.muted
                                font.pixelSize: 11
                            }

                            Text { text: "Comparison plot"; font.bold: true; color: root.ink; font.pixelSize: 12 }
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 560
                                Image {
                                    id: valPlot
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: false
                                    visible: pain.val_plot_path.length > 0
                                    source: pain.val_plot_path.length > 0
                                            ? ("file:///" + String(pain.val_plot_path).replace(/\\/g, "/"))
                                            : ""
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: pain.val_plot_path.length > 0
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally("file:///" + String(pain.val_plot_path).replace(/\\/g, "/"))
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: pain.val_plot_path.length === 0
                                    text: "Press Run to draw the comparison plot"
                                    color: root.muted
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                    width: parent.width - 24
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            CheckBox {
                                id: valShowSource
                                visible: pain.val_source_path.length > 0
                                text: "Show source figure"
                                checked: false
                            }
                            Image {
                                visible: valShowSource.visible && valShowSource.checked
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(480, implicitHeight > 0 ? implicitHeight : 480)
                                Layout.maximumHeight: 480
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: false
                                source: pain.val_source_path.length > 0
                                        ? ("file:///" + String(pain.val_source_path).replace(/\\/g, "/"))
                                        : ""
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: pain.val_source_path.length > 0
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally("file:///" + String(pain.val_source_path).replace(/\\/g, "/"))
                                }
                            }

                            Text { text: "Result table / inputs echo"; font.bold: true; color: root.ink }
                            TextArea {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(420, Math.max(160, contentHeight + 16))
                                readOnly: true
                                wrapMode: TextEdit.Wrap
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

            // (Validation map tab removed in Phase 147, 2026-11-10: the coverage chart is the one view, ISSUE-015)

            // ---- Printed outputs tab (Manual §5.4.3, phase 38h; read-only) ----
            ColumnLayout {
                spacing: 10

                Frame {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Printed outputs (Manual §5.4.3)"
                                font.bold: true
                                font.pixelSize: 15
                                color: root.ink
                            }
                            Text {
                                text: "Read-only tables for the current Run-tab case. No comparison criterion."
                                color: root.muted
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                        Button {
                            text: pain.busy ? "Running…" : "Run / Refresh"
                            enabled: !pain.busy
                            highlighted: true
                            onClicked: Julia.run_printed_outputs_from_qml()
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
                        RunStatusBox {
                            runState: pain.po_state
                            statusText: pain.po_status
                            logText: pain.po_log
                            signature: root.pipelineSignature()
                        }
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            TextArea {
                                readOnly: true
                                wrapMode: TextEdit.Wrap
                                text: pain.po_text
                                color: root.ink
                                font.family: "Consolas"
                                font.pixelSize: 12
                                selectByMouse: true
                                background: null
                            }
                        }
                    }
                }
            }

            // ---- Cabin modes tab (phase 36; display only; own tab — cheaper than map detail) ----
            ColumnLayout {
                spacing: 10

                Frame {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 96
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4
                        Text {
                            text: "Cabin modes (display only)"
                            font.bold: true
                            font.pixelSize: 15
                            color: root.ink
                        }
                        Text {
                            text: "CYL2D App. C animation — no criterion, no verdict. Fixed CYL2D_C1 inputs (not editable). Interpolation for drawing only; node values unchanged."
                            color: root.muted
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "Inputs c0=" + pain.cm_c0 + " m/s, θ0=" + pain.cm_theta0 + "°, NY=" + pain.cm_NY
                            color: root.muted
                            font.pixelSize: 11
                        }
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10
                        Text { text: "Mode"; color: root.ink; font.pixelSize: 12 }
                        SpinBox {
                            from: 0; to: 19
                            value: Math.round(pain.cm_mode)
                            editable: true
                            onValueModified: Julia.set_cabin_mode_from_qml(value)
                        }
                        Text { text: "q"; color: root.ink; font.pixelSize: 12 }
                        SpinBox {
                            from: 0; to: 20
                            value: Math.round(pain.cm_q)
                            editable: true
                            onValueModified: Julia.set_cabin_q_from_qml(value)
                        }
                        Text { text: "Struct r"; color: root.ink; font.pixelSize: 12 }
                        SpinBox {
                            from: 1; to: 32
                            value: Math.round(pain.cm_struct_mode)
                            editable: true
                            onValueModified: Julia.set_cabin_struct_from_qml(value)
                        }
                        Text { text: "Speed"; color: root.ink; font.pixelSize: 12 }
                        SpinBox {
                            from: 1; to: 8
                            value: Math.round(pain.cm_speed)
                            editable: true
                            onValueModified: pain.cm_speed = value
                        }
                        Button {
                            text: root.cmPlaying ? "Pause" : "Play"
                            enabled: pain.cm_frame_path.length > 0
                            onClicked: { root.cmPlaying = !root.cmPlaying; pain.cm_playing = root.cmPlaying }
                        }
                        Button {
                            text: "Open in new window"
                            ToolTip.visible: hovered
                            ToolTip.text: "Plays the selected mode in a window of its own, with Play / Pause and a frame slider"
                            onClicked: Julia.cabin_modes_open_window_from_qml()
                        }
                        Button {
                            text: pain.busy ? "Building…" : "Refresh"
                            enabled: !pain.busy
                            highlighted: true
                            onClicked: Julia.run_cabin_modes_from_qml()
                        }
                    }
                }

                RunStatusBox {
                    runState: pain.cm_state
                    statusText: pain.cm_status
                    logText: pain.cm_log
                    signature: [pain.cm_mode, pain.cm_q, pain.cm_nframes, pain.cm_struct_mode].join("|")
                }

                Timer {
                    interval: Math.max(40, Math.round(120 / Math.max(1, pain.cm_speed)))
                    running: root.cmPlaying && pain.cm_frame_path.length > 0
                    repeat: true
                    onTriggered: Julia.cabin_modes_step_frame_from_qml(1)
                }

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 6
                            Text {
                                text: "Status: " + pain.cm_status
                                color: root.muted
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "f = " + pain.cm_f + " Hz   Φ_G = " + pain.cm_Phi_G + "   " + pain.cm_symmetry
                                color: root.ink
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                            }
                            Text {
                                text: pain.cm_axial_note
                                color: root.muted
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            Text {
                                text: pain.cm_f_prime
                                color: root.ink
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            Text {
                                text: pain.cm_note
                                color: root.muted
                                font.pixelSize: 11
                                Layout.fillWidth: true
                            }
                            Item {
                                id: cmFrameView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredHeight: 360
                                // Phase 151 (2026-11-10): every frame is loaded once when the frames are built and
                                // shown by index, so playing does not read a file from disk at each tick.
                                Repeater {
                                    model: root.cmFrames(pain.cm_frame_paths_json)
                                    delegate: Image {
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: false
                                        cache: true
                                        visible: index === Math.round(pain.cm_frame_index)
                                        source: "file:///" + String(modelData).replace(/\\/g, "/")
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: pain.cm_frame_path.length === 0
                                    text: "Press Refresh to build frames"
                                    color: root.muted
                                    font.pixelSize: 13
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.preferredWidth: 280
                            Layout.fillHeight: true
                            spacing: 8
                            Text {
                                text: "Fig. C-3 (modes 0–5)"
                                font.bold: true
                                color: root.ink
                                font.pixelSize: 12
                            }
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 200
                                clip: true
                                Text {
                                    width: 250
                                    text: pain.cm_fig_c3.length > 0 ? pain.cm_fig_c3 : "(select mode 0–5 and Refresh)"
                                    color: root.ink
                                    font.family: "Consolas"
                                    font.pixelSize: 10
                                    wrapMode: Text.WordWrap
                                }
                            }
                            Text {
                                text: "Structural mode ψ, animated with the frames above (36d / 63)"
                                font.bold: true
                                color: root.ink
                                font.pixelSize: 12
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 240
                                visible: pain.cm_struct_path.length > 0
                                Repeater {   // Phase 151: preloaded, shown by index (as the cabin frames)
                                    model: root.cmFrames(pain.cm_struct_frame_paths_json)
                                    delegate: Image {
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: false
                                        cache: true
                                        visible: index === Math.round(pain.cm_frame_index)
                                        source: "file:///" + String(modelData).replace(/\\/g, "/")
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- Coverage tab (phase 134; display only): each case's chain span, what it is compared with, its verdict ----
            Rectangle {
                id: coveragePage
                color: root.color
                property var cov: JSON.parse(String(pain.coverage_json || "{}"))
                property var stages: cov.stages || []
                property var refs: cov.references || []
                property var rows: {
                    var rs = (cov.rows || []).filter(function (r) {
                        return coverageShowAll.checked || r.verdict !== "no verdict"
                    })
                    // Phase 146b: by source figure, then measurement / NASA's printed prediction / verification;
                    // a family (Phase 145d) stays together, its parent before the cases derived from it
                    if (coverageByFigure.checked) {
                        var order = { "measurement": 0, "nasa": 1, "verification": 2 }
                        rs = rs.slice().sort(function (a, b) {
                            if (a.figure !== b.figure) return a.figure < b.figure ? -1 : 1
                            if (a.reference !== b.reference) return order[a.reference] - order[b.reference]
                            if ((a.family || "") !== (b.family || "")) return (a.family || "") < (b.family || "") ? -1 : 1
                            var da = (a.derived_from || "").length > 0, db = (b.derived_from || "").length > 0
                            if (da !== db) return da ? 1 : -1
                            return a.id < b.id ? -1 : (a.id > b.id ? 1 : 0)
                        })
                    }
                    return rs
                }
                property real labelW: 190
                property real verdictW: 130
                property real colW: Math.max(40, (width - labelW - verdictW - 16) / Math.max(1, stages.length))
                function refColour(key) {
                    for (var i = 0; i < refs.length; i++)
                        if (refs[i].key === key) return refs[i].colour
                    return "#888780"
                }
                function refLabel(key) {
                    for (var i = 0; i < refs.length; i++)
                        if (refs[i].key === key) return refs[i].label
                    return key
                }
                function verdictColour(v) {
                    return v === "met" ? "#1b7a3a" : (v === "not met" ? "#b3261e" : root.muted)
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6

                    Frame {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4
                            Text {
                                text: "Chain coverage (display only)"
                                font.bold: true
                                font.pixelSize: 15
                                color: root.ink
                            }
                            Text {
                                text: "Each bar spans the stages of the program chain a case runs: from the stage its given input enters at to the stage of the quantity it compares (§2.13 Chain span). Its colour is what it is compared with; only cases compared with measurement or NASA's printed prediction carry a verdict. Verdicts are the recorded snapshot; n/N = rows within the case's own criterion (for a case without a verdict, not a pass). A thin bar is computed from another case (a sum or a variant); \"method limit\" means NASA's own printout misses the same gate. Click a row to open the case in the Validation tab."
                                color: root.muted
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                            RowLayout {
                                spacing: 14
                                CheckBox {
                                    id: coverageShowAll
                                    text: "Show cases without a verdict (pale)"
                                    font.pixelSize: 11
                                }
                                CheckBox {
                                    id: coverageByFigure
                                    text: "Order by source figure"
                                    font.pixelSize: 11
                                }
                                Repeater {
                                    model: coveragePage.refs
                                    delegate: RowLayout {
                                        spacing: 5
                                        Rectangle {
                                            width: 14; height: 10; radius: 2
                                            color: modelData.colour
                                        }
                                        Text { text: modelData.label; color: root.ink; font.pixelSize: 11 }
                                    }
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: coveragePage.rows.length + " cases shown"
                                    color: root.muted
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        Repeater {
                            model: coveragePage.stages
                            delegate: Text {
                                x: coveragePage.labelW + index * coveragePage.colW
                                width: coveragePage.colW
                                height: parent.height
                                text: modelData
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignBottom
                                wrapMode: Text.WordWrap
                                font.pixelSize: 11
                                font.bold: true
                                color: root.ink
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        Repeater {
                            model: coveragePage.stages.length + 1
                            delegate: Rectangle {
                                x: coveragePage.labelW + index * coveragePage.colW
                                width: 1
                                height: parent.height
                                color: root.border
                            }
                        }
                        ListView {
                            id: coverageList
                            anchors.fill: parent
                            clip: true
                            model: coveragePage.rows
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                            delegate: Item {
                                id: covRow
                                width: coverageList.width
                                height: 20
                                property bool pale: modelData.verdict === "no verdict"
                                property color base: coveragePage.refColour(modelData.reference)
                                Rectangle {
                                    anchors.fill: parent
                                    color: rowMouse.containsMouse ? "#eef2f6" : "transparent"
                                }
                                Text {
                                    x: 0
                                    width: coveragePage.labelW - 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.id
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideLeft
                                    font.pixelSize: 10
                                    color: root.ink
                                }
                                Rectangle {
                                    x: coveragePage.labelW + modelData.from * coveragePage.colW + 3
                                    width: (modelData.to - modelData.from + 1) * coveragePage.colW - 6
                                    height: (modelData.derived_from || "").length > 0 ? 7 : 12   // Phase 145d: derived, thinner
                                    radius: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Qt.rgba(covRow.base.r, covRow.base.g, covRow.base.b, covRow.pale ? 0.25 : 0.9)
                                    border.width: covRow.pale ? 1 : 0
                                    border.color: covRow.base
                                }
                                Text {
                                    x: coveragePage.labelW + coveragePage.stages.length * coveragePage.colW + 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.verdict + (modelData.points.length > 0 ? " " + modelData.points : "")
                                          + (modelData.method_limit ? " · method limit" : "")
                                    font.pixelSize: 10
                                    color: coveragePage.verdictColour(modelData.verdict)
                                }
                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    ToolTip.visible: containsMouse
                                    ToolTip.delay: 400
                                    ToolTip.text: modelData.id + ": " + modelData.title + "\n"
                                                  + coveragePage.stages[modelData.from] + " → "
                                                  + coveragePage.stages[modelData.to] + "; compared with "
                                                  + coveragePage.refLabel(modelData.reference)
                                                  + (modelData.figure && modelData.figure.length > 0 ? "\nsource: " + modelData.figure : "")
                                                  + (modelData.family && modelData.family.length > 0 ? "\nfamily: " + modelData.family : "")
                                                  + (modelData.derived_from && modelData.derived_from.length > 0 ? " (computed from " + modelData.derived_from + ")" : "")
                                                  + (modelData.method_limit ? "\nmethod limit: NASA's own printout misses the same gate" : "")
                                    onClicked: {
                                        Julia.select_validation_case_from_qml(modelData.id)
                                        tabs.currentIndex = 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
