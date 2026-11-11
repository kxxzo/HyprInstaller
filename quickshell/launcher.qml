import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "."

PanelWindow {
  id: launcher

  WlrLayershell.namespace: "quickshell-ui"

  focusable: true
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  property bool closing: false

  function openLauncher() {
    search.text = ""
    closing = false
    visible = true
    search.forceActiveFocus()
    base.opacity = 0
    base.scale = 0.96
    openAnim.restart()
  }

  function closeLauncher() {
    if (!visible || closing)
      return
    closing = true
    closeAnim.restart()
  }

  IpcHandler {
    target: "launcher"

    function toggle(): void {
      if (launcher.visible && !launcher.closing)
        launcher.closeLauncher()
      else
        launcher.openLauncher()
    }
  }

  GlobalShortcut {
    name: "launcher"
    description: "Toggle application launcher"
    onPressed: launcher.visible && !launcher.closing ? launcher.closeLauncher() : launcher.openLauncher()
  }

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  color: "transparent"

  readonly property string fontFamily: "Maple Mono NF"
  readonly property int fontSize: 17
  readonly property int fontWeight: 700

  // Layout constants
  readonly property int searchHeight: 60
  readonly property int cardHeight: 62
  readonly property int cardSpacing: 3
  readonly property int listTopMargin: 76
  readonly property int bottomPadding: 12
  readonly property real maxCards: 6.6

  readonly property bool hasResults: search.text.trim().length > 0 && list.count > 0
  readonly property bool hasQuery: search.text.trim().length > 0
  readonly property string webSearchUrl: "https://www.google.com/search?q="

  property var customEntries: [
    {
      name: "Shutdown",
      genericName: "Shutdown the computer",
      exec: "shutdown now",
      command: "shutdown now",
      icon: "system-shutdown"
    },
    {
      name: "Reboot",
      genericName: "Reboots the computer",
      exec: "reboot",
      command: "reboot",
      icon: "system-reboot"
    }
  ]

  function executeEntry(entry) {
    if (!entry)
      return

    // DesktopEntry objects also have a `command` property, so don't use
    // that property alone to identify custom entries. Custom entries don't
    // have DesktopEntry.execute().
    if (entry.command !== undefined && typeof entry.execute !== "function") {
      // Custom commands are written naturally as strings, e.g.
      // command: "shutdown now"
      // Run them through the user's shell.
      Quickshell.execDetached(["sh", "-c", entry.command])
    } else {
      // Keep normal desktop applications on DesktopEntry.execute(), which
      // also preserves their working directory and parsed Exec command.
      entry.execute()
    }
  }

  function searchWeb() {
    const query = search.text.trim()
    if (!query)
      return
    Qt.openUrlExternally(launcher.webSearchUrl + encodeURIComponent(query))
    launcher.closeLauncher()
  }

  // Search data is normalized once per desktop entry instead of once per
  // keystroke. This is the main performance win for large application sets.
  property var searchIndex: {
    const entries = []
    const apps = DesktopEntries.applications.values

    function normalize(value) {
      return (value || "").toString().trim().toLowerCase()
    }

    function words(value) {
      return normalize(value).split(/[^a-z0-9]+/).filter(word => word.length > 0)
    }

    for (const custom of launcher.customEntries) {
      const name = normalize(custom.name)
      const generic = normalize(custom.genericName)
      const command = custom.command || ""
      const keywordWords = words(custom.keywords || "")
      const categoryWords = words(custom.categories || "")

      entries.push({
        app: custom,
        key: name + "\u0000" + normalize(custom.exec || command),
        name: name,
        nameWords: words(name),
        generic: generic,
        genericWords: words(generic),
        keywords: keywordWords,
        categories: categoryWords,
        iconPath: custom.icon
          ? Quickshell.iconPath(custom.icon, true)
          : ""
      })
    }

    for (const app of apps) {
      const name = normalize(app.name)
      const generic = normalize(app.genericName)
      const keywordWords = words((app.keywords || []).join(" "))
      const categoryWords = words((app.categories || []).join(" "))

      entries.push({
        app: app,
        key: name + "\u0000" + normalize(app.exec),
        name: name,
        nameWords: words(name),
        generic: generic,
        genericWords: words(generic),
        keywords: keywordWords,
        categories: categoryWords,
        iconPath: Quickshell.iconPath(app.icon, true)
      })
    }

    return entries
  }

  // Session usage ranking. The textual match always has priority; usage is
  // intentionally capped so a frequently launched app cannot outrank an
  // exact/stronger textual match merely because it is popular.
  property var usageCounts: ({})

  function usageScore(key) {
    return usageCounts[key] || 0
  }

  function recordUsage(app) {
    if (!app)
      return

    const key = (app.name || "") + "\u0000" + (app.exec || "")
    const next = Object.assign({}, usageCounts)
    next[key] = Math.min(20, (next[key] || 0) + 1)
    usageCounts = next
  }
    property bool scrollAnimating: false

  BackgroundEffect.blurRegion: Region {
    x: base.x + (base.width * (1 - base.scale) / 2) + 1
    y: base.y + (base.height * (1 - base.scale) / 2) + 1
    width: popup.width * base.scale - 2
    height: popup.height * base.scale - 2
    radius: popup.radius * base.scale
  }
  Rectangle {
    id: base
    width: 622
    height: popup.height + 2
    x: (parent.width - base.width) / 2
    y: (parent.height - launcher.searchHeight - 2) / 2
    radius: 16
    color: Colors.bgs
    opacity: 1
    scale: 1

    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    SequentialAnimation {
      id: openAnim
      PropertyAnimation { target: base; property: "opacity"; to: 1; duration: 170; easing.type: Easing.OutCubic }
      PropertyAnimation { target: base; property: "scale"; to: 1; duration: 180; easing.type: Easing.OutBack }
    }

    SequentialAnimation {
      id: closeAnim
      ParallelAnimation {
        PropertyAnimation { target: base; property: "opacity"; to: 0; duration: 130; easing.type: Easing.InCubic }
        PropertyAnimation { target: base; property: "scale"; to: 0.96; duration: 160; easing.type: Easing.InCubic }
      }
      ScriptAction {
        script: {
          launcher.visible = false
          launcher.closing = false
          base.opacity = 1
          base.scale = 1
        }
      }
    }
  Rectangle {
    id: popup

    width: base.width-2
    height: launcher.hasResults
      ? launcher.listTopMargin
        + Math.min(
            list.count * launcher.cardHeight
              + Math.max(0, list.count - 1) * launcher.cardSpacing,
            launcher.maxCards * launcher.cardHeight
              + (launcher.maxCards - 1) * launcher.cardSpacing
          )
        + launcher.bottomPadding
      : (launcher.hasQuery ? launcher.searchHeight + 28 : launcher.searchHeight)
    y: 1
    x: 1

    Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
    radius: base.radius-1
    border.width: 1

    border.color: Colors.surface
    color: "#00000000"
    clip: true

    TextInput {
      id: search
      focus: true

      x: 15
      y: 15
      width: parent.width - 30
      height: 30

      color: Colors.fg
      selectionColor: Colors.accent
      selectedTextColor: Colors.bg
      
      font {
        family: launcher.fontFamily
        pixelSize: 22
        weight: launcher.fontWeight
      }

      onTextChanged: {
        Qt.callLater(function() {
          if (list.count > 0) {
            list.currentIndex = 0
            list.positionViewAtIndex(0, ListView.Contain)
          } else {
            list.currentIndex = -1
          }
        })
      }

      Text {
        anchors.fill: parent

        text: "Search for apps..."
        color: Colors.dim

        font {
          family: launcher.fontFamily
          pixelSize: 22
          weight: launcher.fontWeight
        }

        verticalAlignment: Text.AlignVCenter
        visible: !search.text
      }
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Down) {
          if (list.count > 0)
            list.currentIndex = (list.currentIndex + 1) % list.count
          event.accepted = true
        }
        else if (event.key === Qt.Key_Up) {
          if (list.count > 0)
            list.currentIndex = (list.currentIndex - 1 + list.count) % list.count
          event.accepted = true
        }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          if (list.currentItem) {
            launcher.recordUsage(list.currentItem.modelData)
            launcher.executeEntry(list.currentItem.modelData)
            launcher.closeLauncher()
          } else if (launcher.hasQuery) {
            launcher.searchWeb()
          }
          event.accepted = true
        }
        else if (event.key === Qt.Key_Escape) {
          launcher.closeLauncher()
          event.accepted = true
        }
      }
    }

    Rectangle {
      x: 15
      y: 60
      width: parent.width - 30
      height: 1
      color: Colors.surface
      visible: launcher.hasResults || (launcher.hasQuery && !launcher.hasResults)
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      y: launcher.searchHeight + 5
      text: "Press Enter to search the web"
      color: Colors.dim
      font {
        family: launcher.fontFamily
        pixelSize: 13
        weight: launcher.fontWeight
      }
      visible: launcher.hasQuery && !launcher.hasResults
    }

    Rectangle {
      id: selectionBox

      x: list.x
      // Keep the highlight inside the visible list area. While the list is
      // scrolling, the highlight follows contentY directly, so it stays
      // glued to the top/bottom edge instead of lagging behind.
      y: list.y + (list.currentItem
        ? Math.max(0, Math.min(
            list.height - height,
            list.currentItem.y - list.contentY
          ))
        : 0)
      width: list.width
      height: launcher.cardHeight
      radius: 15
      color: Colors.surface
      visible: launcher.hasResults && list.currentItem !== null
      z: 0

      Behavior on y {
        NumberAnimation {
          duration: 55
          easing.type: Easing.OutCubic
        }
      }
    }

    ListView {
      id: list

      x: 15
      y: launcher.listTopMargin
      width: parent.width - 30
      height: Math.max(0, parent.height - launcher.listTopMargin - launcher.bottomPadding)

      spacing: launcher.cardSpacing
      clip: true
      visible: launcher.hasResults
      z: 1

      currentIndex: -1

      // Let ListView handle which items need to stay visible.
      // SmoothedAnimation makes contentY move quickly without fighting
      // ListView's own delegate/recycling logic.
      Behavior on contentY {
        SmoothedAnimation {
          id: scrollAnimation
          duration: 90
          velocity: 2200
          onRunningChanged: launcher.scrollAnimating = running
        }
      }

      onCurrentIndexChanged: {
        if (currentIndex >= 0)
          positionViewAtIndex(currentIndex, ListView.Contain)
      }

      onCountChanged: {
        if (count === 0) {
          currentIndex = -1
        } else {
          // A count change means the result set changed. Start at the
          // first result rather than preserving an index from the old set.
          currentIndex = 0
          Qt.callLater(function() {
            positionViewAtIndex(0, ListView.Contain)
          })
        }
      }

      onHeightChanged: {
        if (currentIndex >= 0)
          Qt.callLater(function() {
            positionViewAtIndex(currentIndex, ListView.Contain)
          })
      }

      model: ScriptModel {
        values: {
          const q = search.text.trim().toLowerCase()
          const index = launcher.searchIndex
          const usage = launcher.usageCounts

          if (!q)
            return index.map(entry => entry.app)

          function editDistance(a, b, limit) {
            if (Math.abs(a.length - b.length) > limit)
              return limit + 1

            let previous = new Array(b.length + 1)
            let current = new Array(b.length + 1)

            for (let j = 0; j <= b.length; ++j)
              previous[j] = j

            for (let i = 1; i <= a.length; ++i) {
              current[0] = i
              let rowMin = current[0]

              for (let j = 1; j <= b.length; ++j) {
                const value = Math.min(
                  previous[j] + 1,
                  current[j - 1] + 1,
                  previous[j - 1] +
                    (a.charCodeAt(i - 1) === b.charCodeAt(j - 1) ? 0 : 1)
                )

                current[j] = value
                if (value < rowMin)
                  rowMin = value
              }

              if (rowMin > limit)
                return limit + 1

              const swap = previous
              previous = current
              current = swap
            }

            let result = previous[b.length]

            // Damerau-style adjacent transposition: disocrd -> discord.
            if (a.length === b.length && a.length >= 2) {
              for (let i = 0; i < a.length - 1; ++i) {
                if (a.charCodeAt(i) !== b.charCodeAt(i) &&
                    a.charCodeAt(i) === b.charCodeAt(i + 1) &&
                    a.charCodeAt(i + 1) === b.charCodeAt(i)) {
                  let valid = true

                  for (let j = 0; j < i; ++j) {
                    if (a.charCodeAt(j) !== b.charCodeAt(j)) {
                      valid = false
                      break
                    }
                  }

                  if (valid) {
                    for (let j = i + 2; j < a.length; ++j) {
                      if (a.charCodeAt(j) !== b.charCodeAt(j)) {
                        valid = false
                        break
                      }
                    }
                  }

                  if (valid) {
                    result = Math.min(result, 1)
                    break
                  }
                }
              }
            }

            return result
          }

          function fuzzyWordScore(word, query) {
            if (!word || query.length < 2)
              return 0

            const limit = query.length <= 3 ? 1 : (query.length <= 6 ? 2 : 3)
            const minPrefix = Math.max(1, query.length - limit)
            const maxPrefix = Math.min(word.length, query.length + Math.max(3, limit))

            let bestDistance = limit + 1
            let bestPrefixLength = 0

            for (let length = minPrefix; length <= maxPrefix; ++length) {
              const distance = editDistance(query, word.slice(0, length), limit)

              if (distance < bestDistance) {
                bestDistance = distance
                bestPrefixLength = length

                if (distance === 0)
                  break
              }
            }

            const missingSuffix = Math.max(0, word.length - bestPrefixLength)

            if (bestDistance > limit) {
              // Levenshtein can over-penalize transposed/shifted typos.
              // Example: "moncarft" should still match "minecraft":
              // most characters are present even though the insertion shifts
              // the rest of the word.
              const counts = Object.create(null)
              for (const c of word)
                counts[c] = (counts[c] || 0) + 1

              let overlap = 0
              for (const c of query) {
                if ((counts[c] || 0) > 0) {
                  ++overlap
                  --counts[c]
                }
              }

              const requiredOverlap = Math.max(2, query.length - 1)
              if (overlap < requiredOverlap)
                return 0

              // Keep this below normal prefix/substring matches, but high
              // enough to survive as a useful typo match.
              return 285
                + Math.min(25, overlap * 3)
                - Math.min(30, Math.abs(word.length - query.length) * 10)
            }

            if (missingSuffix > 5 && query.length < 6)
              return 0

            return 360
              - bestDistance * 80
              - Math.min(5, missingSuffix) * 10
              + Math.min(30, bestPrefixLength)
          }

          function fuzzyWords(words, query) {
            let best = 0

            for (const word of words) {
              const score = fuzzyWordScore(word, query)
              if (score > best)
                best = score
            }

            return best
          }

          function subsequenceScore(name, query) {
            if (query.length < 2)
              return 0

            let pos = 0
            let matched = 0

            for (const c of query) {
              const found = name.indexOf(c, pos)
              if (found < 0)
                break
              ++matched
              pos = found + 1
            }

            if (matched !== query.length)
              return 0

            const gaps = Math.max(0, pos - query.length)
            return 290 - Math.min(70, gaps * 6)
          }

          function typoScore(word, query) {
            if (!word || query.length < 4)
              return 0

            // Cheap multiset overlap catches "moncarft" -> "minecraft",
            // where normal Levenshtein distance is unnecessarily harsh.
            if (Math.abs(word.length - query.length) > 2)
              return 0

            const counts = Object.create(null)
            for (const c of word)
              counts[c] = (counts[c] || 0) + 1

            let overlap = 0
            for (const c of query) {
              if ((counts[c] || 0) > 0) {
                ++overlap
                --counts[c]
              }
            }

            const required = Math.max(3, Math.ceil(query.length * 0.75))
            if (overlap < required)
              return 0

            // Require the characters to retain some ordering too, preventing
            // pure anagrams/unrelated names from flooding the results.
            let pos = 0
            let subsequence = 0
            for (const c of query) {
              const found = word.indexOf(c, pos)
              if (found >= 0) {
                ++subsequence
                pos = found + 1
              }
            }

            if (subsequence < required)
              return 0

            let positional = 0
            const commonLength = Math.min(word.length, query.length)
            for (let i = 0; i < commonLength; ++i) {
              if (word.charCodeAt(i) === query.charCodeAt(i))
                ++positional
            }

            return 400
              + Math.min(45, overlap * 5)
              + Math.min(30, subsequence * 4)
              + Math.min(20, positional * 4)
              - Math.abs(word.length - query.length) * 20
          }

          function scoreSingle(entry, query) {
            const name = entry.name

            // Name matches dominate metadata matches.
            if (name === query)
              return 1200
            if (name.startsWith(query))
              return 850 - Math.min(100, Math.max(0, name.length - query.length) * 2)
            if (name.includes(query))
              return 620

            const subsequence = subsequenceScore(name, query)
            if (subsequence > 0)
              return subsequence

            // Metadata is intentionally weaker than a name match.
            if (entry.generic.includes(query))
              return 360
            if (entry.keywords.some(word => word === query))
              return 330
            if (entry.keywords.some(word => word.includes(query)))
              return 270
            if (entry.categories.some(word => word.includes(query)))
              return 220

            // Aggressive typo matching is applied to the application name
            // before falling back to the more conservative edit-distance
            // scorer. This keeps common launcher typos forgiving.
            const typo = typoScore(name, query)
            if (typo > 0)
              return typo

            return Math.max(
              fuzzyWords(entry.nameWords, query),
              fuzzyWords(entry.genericWords, query) - 80,
              fuzzyWords(entry.keywords, query) - 100
            )
          }

          const queryWords = q.split(/\s+/).filter(word => word.length > 0)
          const results = []

          for (const entry of index) {
            let score = 0
            let matchedWords = 0

            if (queryWords.length === 1) {
              score = scoreSingle(entry, queryWords[0])
              matchedWords = score > 0 ? 1 : 0
            } else {
              // Multi-word queries are treated as a phrase/name query rather
              // than scoring each tiny word independently. Otherwise natural
              // language such as "i am too good" can accidentally match
              // unrelated apps through short words like "i", "am", or "to".
              const compactQuery = queryWords.join("")
              const compactName = entry.name.replace(/[^a-z0-9]/g, "")

              if (entry.name === q) {
                score = 1200
              } else if (entry.name.includes(q)) {
                score = 900
              } else if (compactName === compactQuery) {
                score = 1080
              } else if (compactName.includes(compactQuery)) {
                score = 760
              } else {
                // Only allow fuzzy matching when the WHOLE phrase resembles
                // the application name. This preserves "google chorme" /
                // "fire fox" style searches without matching arbitrary prose.
                const phraseTypo = typoScore(compactName, compactQuery)
                if (phraseTypo > 0)
                  score = phraseTypo
              }

              if (score > 0) {
                // Metadata is intentionally excluded for multi-word fuzzy
                // searches. A phrase should describe the application itself.
                matchedWords = queryWords.length
              }
            }

            if (score > 0) {
              // Usage is deliberately a small tie-breaker, never enough to
              // beat a materially stronger textual match.
              score += Math.min(90, (usage[entry.key] || 0) * 12)

              results.push({
                app: entry.app,
                score: score,
                name: entry.app.name || ""
              })
            }
          }

          results.sort((a, b) =>
            b.score - a.score ||
            a.name.localeCompare(b.name)
          )

          return results.map(result => result.app)
        }
      }

      delegate: Rectangle {
        required property var modelData
        required property int index

        width: list.width
        height: launcher.cardHeight
        radius: 15

        color: "transparent"

        Row {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 12

          Image {
            width: 42
            height: 42
            anchors.verticalCenter: parent.verticalCenter

            source: {
              if (modelData.command !== undefined && modelData.icon)
                return Quickshell.iconPath(modelData.icon, true)

              const entry = launcher.searchIndex.find(item => item.app === modelData)
              return entry
                ? entry.iconPath
                : Quickshell.iconPath(modelData.icon, true)
            }
            visible: source !== ""

            sourceSize: Qt.size(42, 42)
            fillMode: Image.PreserveAspectFit
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
              text: modelData.name
              color: Colors.fg

              font {
                family: launcher.fontFamily
                pixelSize: 16
                weight: launcher.fontWeight
              }
            }

            Text {
              text: modelData.genericName
              color: Colors.dim

              font {
                family: launcher.fontFamily
                pixelSize: 12
                weight: launcher.fontWeight
              }

              visible: text.length > 0
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true

          onEntered: {
            // Do not let hover selection fight the list while it is scrolling.
            // Delegates move under the mouse during scrolling, which can otherwise
            // repeatedly change currentIndex and create a scroll loop.
            if (!launcher.scrollAnimating && !list.moving && !list.flicking)
              list.currentIndex = index
          }

          onClicked: {
            launcher.recordUsage(modelData)
            launcher.executeEntry(modelData)
            launcher.closeLauncher()
          }
        }
      }
    }
  }
  }
}
