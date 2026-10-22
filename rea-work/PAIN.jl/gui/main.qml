import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import jlqml

ApplicationWindow {
    id: root
    visible: true
    width: String(pain.smoke_map_png || "").length > 0 ? 1900 : 1180
    height: String(pain.smoke_map_png || "").length > 0 ? 1000 : 780
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

    // ---- Validation map helpers (single total flowchart) ----
    property string activeMapId: "total"
    property var mapData: ({ "id": "", "title": "", "intro": "", "what_is": "", "how_to_read": "", "blocks": [], "groups": [] })
    property var mapDetail: ({})
    property bool mapHowExpanded: false
    property real mapZoom: 1.0
    readonly property real mapCellW: 168
    readonly property real mapCellH: 118
    readonly property real mapPad: 28

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

    function roleBorder(role) {
        if (role === "input") return "#5b4b8a"
        if (role === "function") return "#1f5fa8"
        if (role === "output") return "#0b6e4f"
        if (role === "check") return "#8a4b08"
        return root.border
    }

    function blockAt(col, row) {
        return Qt.point(root.mapPad + col * root.mapCellW, root.mapPad + row * root.mapCellH)
    }

    // Chip stack height under a title box (Flow ~2 chips wide, ~30 px/row). Must match
    // validation_map_group_rects in validation_map.jl for the smoke disjoint check.
    function blockChipExtra(block) {
        var n = (block && block.cases) ? block.cases.length : 0
        if (n <= 0)
            return 0
        var rows = Math.ceil(n / 2)
        return 4 + rows * 30
    }

    // Axis-aligned group rectangle from that group's own blocks only (incl. check chips).
    function groupBounds(groupId, blocks) {
        var minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9, any = false
        for (var i = 0; i < blocks.length; i++) {
            var b = blocks[i]
            if (String(b.group || "") !== String(groupId))
                continue
            any = true
            var p = root.blockAt(b.col, b.row)
            var extra = root.blockChipExtra(b)
            if (p.x < minX) minX = p.x
            if (p.y < minY) minY = p.y
            if (p.x + 148 > maxX) maxX = p.x + 148
            if (p.y + 44 + extra > maxY) maxY = p.y + 44 + extra
        }
        if (!any)
            return { x: 0, y: 0, w: 40, h: 40 }
        return {
            x: minX - 10,
            y: minY - 22,
            w: Math.max(40, (maxX + 10) - (minX - 10)),
            h: Math.max(40, (maxY + 10) - (minY - 22))
        }
    }

    function mapContentSize() {
        var blocks = (root.mapData && root.mapData.blocks) ? root.mapData.blocks : []
        var maxC = 0, maxR = 0
        for (var i = 0; i < blocks.length; i++) {
            if (blocks[i].col > maxC) maxC = blocks[i].col
            if (blocks[i].row > maxR) maxR = blocks[i].row
        }
        return Qt.size(root.mapPad * 2 + (maxC + 1) * root.mapCellW + 80,
                       root.mapPad * 2 + (maxR + 1) * root.mapCellH + 100)
    }

    function resetMapFlowScroll() {
        if (typeof mapCanvasFlick !== "undefined" && mapCanvasFlick) {
            mapCanvasFlick.contentX = 0
            mapCanvasFlick.contentY = 0
        }
    }

    function reloadActiveMap() {
        var raw = pain.map_total_json
        try {
            mapData = JSON.parse(String(raw || "{}"))
        } catch (e) {
            mapData = { "id": "", "title": "", "intro": "", "blocks": [], "groups": [] }
        }
        resetMapFlowScroll()
        Qt.callLater(function () {
            if (typeof mapCanvasFlick !== "undefined" && mapCanvasFlick)
                Julia.report_map_canvas_size_from_qml(mapCanvasFlick.contentWidth, mapCanvasFlick.width)
        })
    }

    function reloadMapDetail() {
        try {
            mapDetail = JSON.parse(String(pain.map_detail_json || "{}"))
        } catch (e) {
            mapDetail = {}
        }
    }

    function fitMapToWindow() {
        if (typeof mapCanvasFlick === "undefined" || !mapCanvasFlick)
            return
        var sz = root.mapContentSize()
        var zx = mapCanvasFlick.width / Math.max(1, sz.width)
        var zy = mapCanvasFlick.height / Math.max(1, sz.height)
        root.mapZoom = Math.max(0.35, Math.min(1.5, Math.min(zx, zy) * 0.95))
        resetMapFlowScroll()
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
            TabButton { text: "Printed outputs" }
            TabButton { text: "Cabin modes" }
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

            // ---- Validation map tab (single total flowchart, horizontal) ----
            RowLayout {
                spacing: 14
                Component.onCompleted: {
                    root.reloadActiveMap()
                    root.reloadMapDetail()
                }

                property string mapJsonWatch: pain.map_total_json
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
                            Text {
                                text: (root.mapData && root.mapData.title) ? root.mapData.title : ""
                                font.bold: true
                                font.pixelSize: 14
                                color: root.ink
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                            Button {
                                text: "Fit"
                                flat: true
                                onClicked: root.fitMapToWindow()
                            }
                            Button {
                                text: "−"
                                flat: true
                                onClicked: root.mapZoom = Math.max(0.35, root.mapZoom - 0.1)
                            }
                            Text {
                                text: Math.round(root.mapZoom * 100) + "%"
                                color: root.muted
                                font.pixelSize: 11
                            }
                            Button {
                                text: "+"
                                flat: true
                                onClicked: root.mapZoom = Math.min(2.0, root.mapZoom + 0.1)
                            }
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

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Flickable {
                                id: mapCanvasFlick
                                anchors.fill: parent
                                clip: true
                                interactive: true
                                boundsBehavior: Flickable.StopAtBounds
                                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOn }
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }
                                contentWidth: mapScaled.width
                                contentHeight: mapScaled.height
                                onWidthChanged: Julia.report_map_canvas_size_from_qml(contentWidth, width)
                                onContentWidthChanged: Julia.report_map_canvas_size_from_qml(contentWidth, width)
                                Component.onCompleted: Julia.report_map_canvas_size_from_qml(contentWidth, width)

                                // Shift+wheel → horizontal scroll; Ctrl+wheel → zoom
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.NoButton
                                    onWheel: function (w) {
                                        if (w.modifiers & Qt.ControlModifier) {
                                            var dz = w.angleDelta.y > 0 ? 0.1 : -0.1
                                            root.mapZoom = Math.max(0.35, Math.min(2.0, root.mapZoom + dz))
                                            w.accepted = true
                                        } else if (w.modifiers & Qt.ShiftModifier) {
                                            mapCanvasFlick.contentX = Math.max(0, Math.min(
                                                mapCanvasFlick.contentWidth - mapCanvasFlick.width,
                                                mapCanvasFlick.contentX - w.angleDelta.y))
                                            w.accepted = true
                                        }
                                    }
                                }

                                Item {
                                    id: mapScaled
                                    width: mapCanvas.width * root.mapZoom
                                    height: mapCanvas.height * root.mapZoom

                                    Item {
                                        id: mapCanvas
                                        property var blocks: (root.mapData && root.mapData.blocks) ? root.mapData.blocks : []
                                        property var groups: (root.mapData && root.mapData.groups) ? root.mapData.groups : []
                                        width: root.mapContentSize().width
                                        height: root.mapContentSize().height
                                        transform: Scale {
                                            xScale: root.mapZoom
                                            yScale: root.mapZoom
                                            origin.x: 0
                                            origin.y: 0
                                        }

                                        // Stage group frames (bounds from that group's blocks only)
                                        Repeater {
                                            model: mapCanvas.groups
                                            delegate: Rectangle {
                                                id: grpRect
                                                property var grp: modelData
                                                property var ownBounds: root.groupBounds(grp.id, mapCanvas.blocks)
                                                x: ownBounds.x
                                                y: ownBounds.y
                                                width: ownBounds.w
                                                height: ownBounds.h
                                                radius: 10
                                                color: "#f7f9fb"
                                                border.color: "#c5ced8"
                                                border.width: 1
                                                z: 0
                                                Text {
                                                    anchors.left: parent.left
                                                    anchors.top: parent.top
                                                    anchors.margins: 6
                                                    text: String(grp.title || grp.id || "")
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: root.muted
                                                }
                                            }
                                        }

                                        // Edges (feeds)
                                        Canvas {
                                            id: mapEdges
                                            anchors.fill: parent
                                            z: 1
                                            property var blocks: mapCanvas.blocks
                                            onBlocksChanged: requestPaint()
                                            onPaint: {
                                                var ctx = getContext("2d")
                                                ctx.reset()
                                                var byId = {}
                                                for (var i = 0; i < blocks.length; i++)
                                                    byId[blocks[i].id] = blocks[i]
                                                function centerOf(b) {
                                                    var p = root.blockAt(b.col, b.row)
                                                    var h = 44 + root.blockChipExtra(b)
                                                    return { x: p.x + 74, y: p.y + Math.min(22, h / 2) }
                                                }
                                                function route(c0, c1, toCheck) {
                                                    // Prefer orthogonal elbows so curves do not cut block titles.
                                                    ctx.moveTo(c0.x, c0.y)
                                                    if (Math.abs(c0.y - c1.y) < 8) {
                                                        ctx.lineTo(c1.x, c1.y)
                                                    } else if (toCheck) {
                                                        var midY = (c0.y + c1.y) / 2
                                                        ctx.lineTo(c0.x, midY)
                                                        ctx.lineTo(c1.x, midY)
                                                        ctx.lineTo(c1.x, c1.y)
                                                    } else if (c1.x >= c0.x + 40) {
                                                        var mx = c0.x + Math.max(36, (c1.x - c0.x) * 0.35)
                                                        ctx.lineTo(mx, c0.y)
                                                        ctx.lineTo(mx, c1.y)
                                                        ctx.lineTo(c1.x, c1.y)
                                                    } else {
                                                        var mid = (c0.x + c1.x) / 2
                                                        ctx.bezierCurveTo(mid, c0.y, mid, c1.y, c1.x, c1.y)
                                                    }
                                                }
                                                for (var i = 0; i < blocks.length; i++) {
                                                    var src = blocks[i]
                                                    var feeds = src.feeds || []
                                                    var c0 = centerOf(src)
                                                    for (var j = 0; j < feeds.length; j++) {
                                                        var dst = byId[feeds[j]]
                                                        if (!dst) continue
                                                        var c1 = centerOf(dst)
                                                        var toCheck = String(dst.role || "") === "check"
                                                        ctx.beginPath()
                                                        if (toCheck) {
                                                            ctx.setLineDash([5, 4])
                                                            ctx.strokeStyle = "#a0a8b4"
                                                        } else {
                                                            ctx.setLineDash([])
                                                            ctx.strokeStyle = "#6a7585"
                                                        }
                                                        ctx.lineWidth = 1.5
                                                        route(c0, c1, toCheck)
                                                        ctx.stroke()
                                                        // arrowhead along final segment
                                                        var ang = Math.atan2(c1.y - c0.y, c1.x - c0.x)
                                                        if (toCheck)
                                                            ang = Math.atan2(c1.y - ((c0.y + c1.y) / 2), 0)
                                                        else if (Math.abs(c0.y - c1.y) >= 8 && c1.x >= c0.x + 40)
                                                            ang = 0
                                                        ctx.setLineDash([])
                                                        ctx.beginPath()
                                                        ctx.moveTo(c1.x, c1.y)
                                                        ctx.lineTo(c1.x - 8 * Math.cos(ang - 0.35), c1.y - 8 * Math.sin(ang - 0.35))
                                                        ctx.lineTo(c1.x - 8 * Math.cos(ang + 0.35), c1.y - 8 * Math.sin(ang + 0.35))
                                                        ctx.closePath()
                                                        ctx.fillStyle = toCheck ? "#a0a8b4" : "#6a7585"
                                                        ctx.fill()
                                                    }
                                                }
                                            }
                                        }

                                        // Blocks (titles only + chips)
                                        Repeater {
                                            model: mapCanvas.blocks
                                            delegate: Item {
                                                id: blockItem
                                                property var block: modelData
                                                x: root.blockAt(block.col, block.row).x
                                                y: root.blockAt(block.col, block.row).y
                                                width: 148
                                                height: blockBox.height + chipFlow.implicitHeight + 4
                                                z: 2

                                                Rectangle {
                                                    id: blockBox
                                                    width: parent.width
                                                    height: 44
                                                    radius: 6
                                                    color: pain.map_selected_block === block.id ? "#e8f4ef" : "#ffffff"
                                                    border.color: root.roleBorder(String(block.role || ""))
                                                    border.width: pain.map_selected_block === block.id ? 2 : 1
                                                    Text {
                                                        anchors.fill: parent
                                                        anchors.margins: 6
                                                        text: String(block.title || block.id)
                                                        font.bold: true
                                                        font.pixelSize: 11
                                                        color: root.ink
                                                        wrapMode: Text.WordWrap
                                                        horizontalAlignment: Text.AlignHCenter
                                                        verticalAlignment: Text.AlignVCenter
                                                    }
                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: Julia.select_map_block_from_qml(block.id)
                                                    }
                                                }

                                                Flow {
                                                    id: chipFlow
                                                    anchors.top: blockBox.bottom
                                                    anchors.topMargin: 4
                                                    width: parent.width
                                                    spacing: 4
                                                    Repeater {
                                                        model: blockItem.block.cases || []
                                                        delegate: Rectangle {
                                                            property var chip: modelData
                                                            property color catColor: root.categoryColor(chip.category)
                                                            property bool selected: pain.map_selected === chip.id
                                                            radius: 8
                                                            color: selected ? "#e8f4ef" : root.panel
                                                            border.color: catColor
                                                            border.width: selected ? 2 : 1
                                                            implicitHeight: chipCol.implicitHeight + 6
                                                            implicitWidth: Math.min(parent.width, chipCol.implicitWidth + 10)
                                                            Column {
                                                                id: chipCol
                                                                anchors.centerIn: parent
                                                                spacing: 1
                                                                Row {
                                                                    spacing: 3
                                                                    Rectangle {
                                                                        width: 7; height: 7; radius: 4
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
                                                                        font.pixelSize: 9
                                                                        font.bold: true
                                                                        color: root.ink
                                                                        anchors.verticalCenter: parent.verticalCenter
                                                                    }
                                                                }
                                                                Text {
                                                                    text: chip.title
                                                                    font.pixelSize: 8
                                                                    color: root.muted
                                                                    width: Math.min(130, implicitWidth)
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
                                        }
                                    }
                                }
                            }

                            // Offscreen screenshots (zoom 1, no fit): left then scrolled right.
                            Timer {
                                interval: 400
                                running: String(pain.smoke_map_png || "").length > 0
                                repeat: false
                                onTriggered: {
                                    tabs.currentIndex = 2
                                    root.mapHowExpanded = false
                                    root.mapZoom = 1.0
                                    root.reloadActiveMap()
                                    mapShotDelay.start()
                                }
                            }
                            Timer {
                                id: mapShotDelay
                                interval: 700
                                repeat: false
                                onTriggered: {
                                    var path = String(pain.smoke_map_png || "")
                                    if (path.length === 0) return
                                    mapCanvasFlick.contentX = 0
                                    mapCanvasFlick.contentY = 0
                                    mapCanvasFlick.grabToImage(function (result) {
                                        result.saveToFile(path)
                                        console.log("VALIDATION_MAP_TOTAL saved:", path)
                                        mapShotRightDelay.start()
                                    })
                                }
                            }
                            Timer {
                                id: mapShotRightDelay
                                interval: 500
                                repeat: false
                                onTriggered: {
                                    var path = String(pain.smoke_map_png || "")
                                    if (path.length === 0) return
                                    var rightPath = path.replace("VALIDATION_MAP_TOTAL.png",
                                                                 "VALIDATION_MAP_TOTAL_right.png")
                                    if (rightPath === path)
                                        rightPath = path + ".right.png"
                                    var maxX = Math.max(0, mapCanvasFlick.contentWidth - mapCanvasFlick.width)
                                    mapCanvasFlick.contentX = maxX
                                    mapCanvasFlick.contentY = 0
                                    mapCanvasFlick.grabToImage(function (result) {
                                        result.saveToFile(rightPath)
                                        console.log("VALIDATION_MAP_TOTAL_right saved:", rightPath)
                                    })
                                }
                            }
                        }
                    }
                }

                Frame {
                    // Offscreen map shots: hide detail so the canvas uses the full 1900 px width.
                    visible: String(pain.smoke_map_png || "").length === 0
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
                                    text: (root.mapDetail && root.mapDetail.title)
                                          ? root.mapDetail.title
                                          : "(select a block or case chip)"
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

                            // Block detail (click a pipeline box)
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.detail_kind === "block")
                                text: "Role: " + (root.mapDetail.role || "")
                                      + (root.mapDetail.group_title ? (" · " + root.mapDetail.group_title)
                                         : (root.mapDetail.group ? (" · " + root.mapDetail.group) : ""))
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.muted
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.detail_kind === "block" && root.mapDetail.code)
                                text: "Code: " + (root.mapDetail.code || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.detail_kind === "block")
                                text: root.mapDetail.what_it_does || ""
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }

                            // Case detail (click a chip)
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.detail_kind !== "block" && root.mapDetail.id)
                                text: "Source: " + (root.mapDetail.source || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.detail_kind !== "block" && root.mapDetail.id)
                                text: "What it tests: " + (root.mapDetail.verifies || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.detail_kind !== "block" && root.mapDetail.id)
                                text: "Why it is here: " + (root.mapDetail.why || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.detail_kind !== "block" && root.mapDetail.id)
                                text: "A pass means: " + (root.mapDetail.meaning || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.detail_kind !== "block" && root.mapDetail.id)
                                text: "Not covered: " + (root.mapDetail.missing || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.detail_kind !== "block" && root.mapDetail.id)
                                text: "Recorded outcome: " + (root.mapDetail.recorded || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.detail_kind !== "block" && root.mapDetail.id)
                                text: "Explanation: " + (root.mapDetail.explanation || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.ink
                                font.pixelSize: 11
                            }
                            Text {
                                visible: !!(root.mapDetail && root.mapDetail.detail_kind !== "block" && root.mapDetail.criterion_text)
                                text: "Criterion (" + (root.mapDetail.criterion_date || "") + "): " + (root.mapDetail.criterion_text || "")
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                color: root.muted
                                font.pixelSize: 11
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: !!(root.mapDetail && root.mapDetail.detail_kind !== "block")
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
                        Text {
                            text: "Status: " + pain.po_status
                            color: root.muted
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
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
                            text: pain.cm_playing ? "Pause" : "Play"
                            enabled: pain.cm_frame_path.length > 0
                            onClicked: pain.cm_playing = !pain.cm_playing
                        }
                        Button {
                            text: pain.busy ? "Building…" : "Refresh"
                            enabled: !pain.busy
                            highlighted: true
                            onClicked: Julia.run_cabin_modes_from_qml()
                        }
                    }
                }

                Timer {
                    interval: Math.max(40, Math.round(120 / Math.max(1, pain.cm_speed)))
                    running: !!pain.cm_playing && pain.cm_frame_path.length > 0
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
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredHeight: 360
                                Image {
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: false
                                    visible: pain.cm_frame_path.length > 0
                                    source: pain.cm_frame_path.length > 0
                                            ? ("file:///" + String(pain.cm_frame_path).replace(/\\/g, "/"))
                                            : ""
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
                                text: "Structural ψ (36d)"
                                font.bold: true
                                color: root.ink
                                font.pixelSize: 12
                            }
                            Image {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 160
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: false
                                visible: pain.cm_struct_path.length > 0
                                source: pain.cm_struct_path.length > 0
                                        ? ("file:///" + String(pain.cm_struct_path).replace(/\\/g, "/"))
                                        : ""
                            }
                        }
                    }
                }
            }
        }
    }
}
