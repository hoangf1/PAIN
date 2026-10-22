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

    // Cache case rows so the ListView model is not a fresh JS array on every
    // pain.* Observable notify (that reset currentIndex and cleared the highlight).
    property var valCaseRows: []
    readonly property string valCasesWatch: pain.val_cases
    onValCasesWatchChanged: rebuildValCaseRows()
    function rebuildValCaseRows() {
        valCaseRows = String(pain.val_cases || "").split("\n").filter(function (s) { return s.length > 0 })
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

    // ---- Validation map helpers ----
    property string activeMapId: "pain"
    property var mapData: ({ "id": "", "title": "", "intro": "", "what_is": "", "how_to_read": "", "blocks": [] })
    property var mapDetail: ({})
    property bool mapHowExpanded: false

    function categoryColor(cat) {
        if (cat === "verification") return "#0b6e4f"
        if (cat === "experiment") return "#1f5fa8"
        if (cat === "calibrated") return "#8a4b08"
        if (cat === "input_qa") return "#5b4b8a"
        if (cat === "extrap") return "#b4500a"
        return "#9aa3ae"  // deferred / unknown
    }

    function kindTag(kind) {
        if (kind === "pkgtest") return "Pkg.test"
        if (kind === "replay") return "replay"
        if (kind === "report") return "report"
        if (kind === "deferred") return "deferred"
        return ""
    }

    function resetMapFlowScroll() {
        if (typeof mapFlowScroll !== "undefined" && mapFlowScroll) {
            if (mapFlowScroll.contentItem)
                mapFlowScroll.contentItem.contentY = 0
            if (mapFlowScroll.ScrollBar && mapFlowScroll.ScrollBar.vertical)
                mapFlowScroll.ScrollBar.vertical.position = 0
        }
    }

    function reloadActiveMap() {
        var raw = activeMapId === "aircraft" ? pain.map_aircraft_json : pain.map_pain_json
        try {
            mapData = JSON.parse(String(raw || "{}"))
        } catch (e) {
            mapData = { "id": "", "title": "", "intro": "", "blocks": [] }
        }
        resetMapFlowScroll()
    }

    function reloadMapDetail() {
        try {
            mapDetail = JSON.parse(String(pain.map_detail_json || "{}"))
        } catch (e) {
            mapDetail = {}
        }
    }

    function setActiveMap(id) {
        activeMapId = id
        reloadActiveMap()
        resetMapFlowScroll()
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
            onCurrentIndexChanged: {
                // Validation map tab index 2: re-parse §2.13 so an edited .md shows without restart.
                if (currentIndex === 2)
                    Julia.reload_validation_docs_from_qml()
            }
            TabButton { text: "Run" }
            TabButton { text: "Validation" }
            TabButton { text: "Validation map" }
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

                            Text {
                                text: pain.val_status
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 13
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

            // ---- Validation map tab (two flowcharts) ----
            RowLayout {
                spacing: 14
                Component.onCompleted: {
                    root.reloadActiveMap()
                    root.reloadMapDetail()
                }

                // Re-parse when Julia refreshes map / detail Observables after a Run.
                property string mapJsonWatch: root.activeMapId === "aircraft"
                                              ? pain.map_aircraft_json : pain.map_pain_json
                onMapJsonWatchChanged: root.reloadActiveMap()
                property string mapDetailWatch: pain.map_detail_json
                onMapDetailWatchChanged: root.reloadMapDetail()

                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Button {
                                text: "PAIN verification"
                                highlighted: root.activeMapId === "pain"
                                onClicked: root.setActiveMap("pain")
                            }
                            Button {
                                text: "Aircraft source validation"
                                highlighted: root.activeMapId === "aircraft"
                                onClicked: root.setActiveMap("aircraft")
                            }
                        }

                        Text {
                            text: (root.mapData && root.mapData.title) ? root.mapData.title : ""
                            font.bold: true
                            font.pixelSize: 15
                            color: root.ink
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }

                        // Collapsible "How to read this map" (from §2.13 what_is + how_to_read)
                        Rectangle {
                            Layout.fillWidth: true
                            radius: 4
                            color: "#f0f3f6"
                            border.color: root.border
                            implicitHeight: mapHowCol.implicitHeight + 12
                            Column {
                                id: mapHowCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 6
                                spacing: 4
                                RowLayout {
                                    width: parent.width
                                    Text {
                                        text: "How to read this map"
                                        font.bold: true
                                        font.pixelSize: 12
                                        color: root.ink
                                        Layout.fillWidth: true
                                    }
                                    Button {
                                        text: root.mapHowExpanded ? "Hide" : "Show"
                                        flat: true
                                        onClicked: root.mapHowExpanded = !root.mapHowExpanded
                                    }
                                }
                                Text {
                                    visible: root.mapHowExpanded
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    color: root.ink
                                    font.pixelSize: 11
                                    text: (root.mapData && (root.mapData.what_is || root.mapData.intro))
                                          ? String(root.mapData.what_is || root.mapData.intro) : ""
                                }
                                Text {
                                    visible: root.mapHowExpanded
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    color: root.muted
                                    font.pixelSize: 11
                                    text: (root.mapData && root.mapData.how_to_read)
                                          ? String(root.mapData.how_to_read) : ""
                                }
                            }
                        }

                        // Legend
                        Flow {
                            Layout.fillWidth: true
                            spacing: 10
                            Repeater {
                                model: [
                                    { label: "verification", color: "#0b6e4f" },
                                    { label: "experiment", color: "#1f5fa8" },
                                    { label: "calibrated / post-hoc", color: "#8a4b08" },
                                    { label: "input QA", color: "#5b4b8a" },
                                    { label: "X-EXTRAP", color: "#b4500a" },
                                    { label: "deferred", color: "#9aa3ae" }
                                ]
                                delegate: Row {
                                    spacing: 4
                                    Rectangle {
                                        width: 12; height: 12; radius: 2
                                        color: "transparent"
                                        border.color: modelData.color
                                        border.width: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 10
                                        color: root.muted
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                            Row {
                                spacing: 4
                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    color: "#0b6e4f"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text { text: "met"; font.pixelSize: 10; color: root.muted; anchors.verticalCenter: parent.verticalCenter }
                            }
                            Row {
                                spacing: 4
                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    color: "#c0392b"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text { text: "not_met"; font.pixelSize: 10; color: root.muted; anchors.verticalCenter: parent.verticalCenter }
                            }
                            Row {
                                spacing: 4
                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    color: "#9aa3ae"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text { text: "no_verdict"; font.pixelSize: 10; color: root.muted; anchors.verticalCenter: parent.verticalCenter }
                            }
                            Row {
                                spacing: 4
                                Rectangle {
                                    width: 10; height: 10; radius: 5
                                    color: "transparent"
                                    border.color: "#9aa3ae"
                                    border.width: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text { text: "not run"; font.pixelSize: 10; color: root.muted; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }

                        ScrollView {
                            id: mapFlowScroll
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            // Assign (not bind) so availableWidth ↔ contentWidth cannot loop.
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            onAvailableWidthChanged: contentWidth = availableWidth
                            Component.onCompleted: contentWidth = availableWidth

                            Column {
                                width: mapFlowScroll.availableWidth
                                spacing: 4

                                Repeater {
                                    model: (root.mapData && root.mapData.blocks) ? root.mapData.blocks : []
                                    delegate: Column {
                                        id: blockCol
                                        property var block: modelData
                                        property int blockIndex: index
                                        width: parent.width
                                        spacing: 4

                                        RowLayout {
                                            width: parent.width
                                            spacing: 10

                                            Rectangle {
                                                Layout.preferredWidth: 240
                                                Layout.minimumHeight: 64
                                                radius: 4
                                                color: "#f0f3f6"
                                                border.color: root.border
                                                Column {
                                                    anchors.fill: parent
                                                    anchors.margins: 8
                                                    spacing: 2
                                                    Text {
                                                        text: blockCol.block.title
                                                        font.bold: true
                                                        font.pixelSize: 11
                                                        color: root.ink
                                                        wrapMode: Text.WordWrap
                                                        width: parent.width
                                                    }
                                                    Text {
                                                        visible: String(blockCol.block.code || "").length > 0
                                                        text: blockCol.block.code
                                                        font.pixelSize: 9
                                                        color: root.muted
                                                        wrapMode: Text.WordWrap
                                                        width: parent.width
                                                    }
                                                    Text {
                                                        visible: String(blockCol.block.what_it_does || blockCol.block.note || "").length > 0
                                                        text: blockCol.block.what_it_does || blockCol.block.note || ""
                                                        font.pixelSize: 9
                                                        color: root.muted
                                                        wrapMode: Text.WordWrap
                                                        width: parent.width
                                                    }
                                                }
                                            }

                                            Flow {
                                                Layout.fillWidth: true
                                                spacing: 6
                                                Repeater {
                                                    model: blockCol.block.cases || []
                                                    delegate: Rectangle {
                                                        property var chip: modelData
                                                        property color catColor: root.categoryColor(chip.category)
                                                        property bool selected: pain.map_selected === chip.id
                                                        radius: 10
                                                        color: selected ? "#e8f4ef" : root.panel
                                                        border.color: catColor
                                                        border.width: selected ? 2 : 1
                                                        implicitHeight: chipCol.implicitHeight + 10
                                                        implicitWidth: chipCol.implicitWidth + 16
                                                        Column {
                                                            id: chipCol
                                                            anchors.centerIn: parent
                                                            spacing: 2
                                                            Row {
                                                                spacing: 5
                                                                Rectangle {
                                                                    width: 8; height: 8; radius: 4
                                                                    color: {
                                                                        var last = String(chip.last || "not_run")
                                                                        if (last === "met") return "#0b6e4f"
                                                                        if (last === "not_met") return "#c0392b"
                                                                        if (last === "no_verdict") return "#9aa3ae"
                                                                        return "transparent"
                                                                    }
                                                                    border.color: "#9aa3ae"
                                                                    border.width: String(chip.last || "not_run") === "not_run" ? 1 : 0
                                                                    anchors.verticalCenter: parent.verticalCenter
                                                                }
                                                                Text {
                                                                    text: chip.id
                                                                    font.pixelSize: 11
                                                                    font.bold: true
                                                                    color: root.ink
                                                                    anchors.verticalCenter: parent.verticalCenter
                                                                }
                                                                Text {
                                                                    visible: root.kindTag(chip.kind).length > 0
                                                                    text: root.kindTag(chip.kind)
                                                                    font.pixelSize: 9
                                                                    color: root.muted
                                                                    anchors.verticalCenter: parent.verticalCenter
                                                                }
                                                            }
                                                            Text {
                                                                text: chip.title
                                                                font.pixelSize: 9
                                                                color: root.muted
                                                                width: Math.min(180, implicitWidth)
                                                                elide: Text.ElideRight
                                                            }
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: Julia.select_map_case_from_qml(chip.id)
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            visible: blockCol.blockIndex < ((root.mapData && root.mapData.blocks) ? root.mapData.blocks.length : 0) - 1
                                            text: "▼"
                                            color: root.muted
                                            font.pixelSize: 14
                                            horizontalAlignment: Text.AlignHCenter
                                            width: 240
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Frame {
                    Layout.preferredWidth: 520
                    Layout.fillHeight: true

                    ScrollView {
                        id: mapDetailScroll
                        anchors.fill: parent
                        anchors.margins: 12
                        clip: true
                        // Assign (not bind) so availableWidth ↔ contentWidth cannot loop.
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        onAvailableWidthChanged: contentWidth = availableWidth
                        Component.onCompleted: contentWidth = availableWidth

                        ColumnLayout {
                            width: mapDetailScroll.availableWidth
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: (root.mapDetail && root.mapDetail.title) ? root.mapDetail.title : "(select a case chip)"
                                    font.bold: true
                                    font.pixelSize: 14
                                    color: root.ink
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                                Rectangle {
                                    visible: !!(root.mapDetail && root.mapDetail.category)
                                    radius: 4
                                    color: "transparent"
                                    border.color: root.categoryColor(root.mapDetail.category || "")
                                    border.width: 1
                                    implicitHeight: catBadge.implicitHeight + 6
                                    implicitWidth: catBadge.implicitWidth + 12
                                    Text {
                                        id: catBadge
                                        anchors.centerIn: parent
                                        text: root.mapDetail.category || ""
                                        font.pixelSize: 10
                                        color: root.categoryColor(root.mapDetail.category || "")
                                    }
                                }
                            }

                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.id)
                                text: "Source: " + (root.mapDetail.source || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.id)
                                text: "What it tests: " + (root.mapDetail.verifies || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.id)
                                text: "Why it is here: " + (root.mapDetail.why || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.id)
                                text: "A pass means: " + (root.mapDetail.meaning || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.id)
                                text: "Not covered: " + (root.mapDetail.missing || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.id)
                                text: "Recorded outcome: " + (root.mapDetail.recorded || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.id)
                                text: "Explanation: " + (root.mapDetail.explanation || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.criterion_text)
                                text: "Criterion (" + (root.mapDetail.criterion_date || "") + "): " + (root.mapDetail.criterion_text || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.muted
                                font.pixelSize: 11
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Button {
                                    text: pain.busy ? "Running…" : "Run"
                                    enabled: !pain.busy
                                             && !!root.mapDetail
                                             && !!root.mapDetail.id
                                             && (root.mapDetail.kind === "runnable" || root.mapDetail.kind === "replay")
                                             && root.mapDetail.in_registry === true
                                    highlighted: true
                                    onClicked: Julia.run_validation_from_qml(pain.map_selected)
                                }
                                Button {
                                    text: "Open report"
                                    enabled: pain.val_report_path.length > 0 && pain.map_selected === pain.val_selected
                                    onClicked: Julia.open_validation_report_from_qml()
                                }
                            }

                            Text {
                                text: "Code vs figure"
                                font.bold: true
                                color: root.ink
                                font.pixelSize: 12
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 560
                                Image {
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: false
                                    visible: pain.map_selected.length > 0
                                             && pain.val_selected === pain.map_selected
                                             && pain.val_plot_path.length > 0
                                    source: (pain.map_selected.length > 0
                                             && pain.val_selected === pain.map_selected
                                             && pain.val_plot_path.length > 0)
                                            ? ("file:///" + String(pain.val_plot_path).replace(/\\/g, "/"))
                                            : ""
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: pain.map_selected.length > 0
                                                 && pain.val_selected === pain.map_selected
                                                 && pain.val_plot_path.length > 0
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally("file:///" + String(pain.val_plot_path).replace(/\\/g, "/"))
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: !(pain.map_selected.length > 0
                                               && pain.val_selected === pain.map_selected
                                               && pain.val_plot_path.length > 0)
                                    text: "Press Run to draw the comparison plot"
                                    color: root.muted
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                    width: parent.width - 24
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            CheckBox {
                                id: mapShowSource
                                visible: !!(root.mapDetail && root.mapDetail.source_image)
                                text: "Show source figure"
                                checked: false
                            }
                            Image {
                                visible: mapShowSource.visible && mapShowSource.checked
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(480, implicitHeight > 0 ? implicitHeight : 480)
                                Layout.maximumHeight: 480
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: false
                                source: (root.mapDetail && root.mapDetail.source_image)
                                        ? ("file:///" + String(root.mapDetail.source_image).replace(/\\/g, "/"))
                                        : ""
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: !!(root.mapDetail && root.mapDetail.source_image)
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally("file:///" + String(root.mapDetail.source_image).replace(/\\/g, "/"))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
