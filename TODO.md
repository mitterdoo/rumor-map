# PHASE 1 main features
- [x] Curiosity images
- [x] Shift+scroll wheel increases/decreases size of hovered Curiosity, and/or entire selection
- [x] Paste path to image file
- [x] Note categories
- [x] Bidirectional Segments
- [x] Icons for buttons 
- [x] Switch sidebar to TabView for: no selection, one selection (editable), multiple selections (make tabview fit the largest tab)
- [x] Save/load
- [x] persistent state saved and loaded in user folder (for settings etc)
- - [x] Recent files
- - [x] clear history function
- - [x] remove file from history if it is missing upon opening attempt
- - [x] last location for file browser

# BUGS
- [x] move bugs to github issues
- [x] If you resize the sidebar to its smallest size with a node selected, then deselect it, the "click something" hint text makes it bigger, causing the UI to "jump" unexpectedly
- - This messes with click and drag operations on Curiosities, offsetting the cursor position incorrectly
- - Could maybe be fixed by using a TabView to switch between different states, having the size dictated by its largest tab

# PHASE 2 secondary features
- [x] Settings menu
- [x] Curiosity name entry UX
- - [x] Double-click a curiosity to instantly edit its name
- - [x] Any node creation (add, or new connection) should focus the text for the node's title
- - [x] Curiosity name boxes should have an outline on the box when editing
- [ ] Flags
- [ ] User styles, categories, and flags
- [ ] Note rearrangement
- [ ] Keyboard shortcuts
- - [ ] swap to other connection in bidir segment
- - [ ] create node
- - [x] save/load/new
- [ ] Undo/redo
- [ ] Automatic backups
- - [ ] "attach" autosave to current file, so when the user re-saves a recovered backup, they dont have to browse to find the original
- [ ] Manual or other learning resource

# PHASE 3
## polish
- [ ] Hold shift while dragging connection to reverse the connection direction (make a new node then connect it *to* the source)
- [ ] Add bar at bottom like Blender's shortcut hints
- [ ] Add bar at bottom like FL Studio's tooltip
- [ ] Saved file should remember current position and zoom of camera
- [ ] Recent files should show filename instead of full path, but distinguish when there are identical filenames listed
- [ ] User should be able to move the left sidebar and dock it to the bottom or right sides of the screen. should retain resizability
- [ ] Midpoint of connections should be the center of only the visible portion of the segment unobstructed
- [ ] Resizing with scroll wheel should update the desired size box at the top
- [ ] Show a preview curiosity and connection line when clicking and dragging a new connection
- [ ] Allow user to cancel click+drag new connection with ESC
- [ ] Button in sidebar to see (and switch between) bidirectional connections
- [ ] CTRL+F (search by title, note contents) (case-sensitive, whole word)
- [ ] Note Count view. select note category/categories to filter by, and display count on each curiosity and connection (+bidirectionals)
- [ ] Custom file extension instead of .res?
- [ ] On a Curiosity, if hovering over or editing an inbound Note, it should highlight the connection it's coming from (maybe different color than selection)
- [ ] Export as an SVG or PNG (won't be able to export notes obviously)
- [ ] PROBABLY BIGGER THAN YOU THINK: "Label" node that can be resized, always on bottom layer, has title at top.

## unsure features
- [ ] Copy selection to clipboard (in base64 like Factorio) and paste
- - how tf would style mapping work???

## nitpicks
- [ ] The sidebar's note panel jumps up and down whenever you change the selection. it seems pretty distracting
- [ ] Opening the category dropdown from an empty Note should not erase the note. the user should be able to select the category

# PHASE 4 release
- [x] Double check font licensing
- [ ] Thumbnail
- [ ] app icon
- [ ] Linux build
- [ ] Windows build
- [ ] macOS build?
- [ ] Test windows build
- [ ] test macOS build
- [ ] Upload to github

# Flags
Note flags

Also, if a user is creating a map, there is no way to know if "there is more to explore here". So the user should be able to mark a Node as a loose end, or have it done automatically

"Flagging" nodes to put an asterisk, question mark, or some other icons next to the node
- Can be automatic, determining whether a note should have a flag set
- User can change the criteria
- User can also manually enable or disable a flag

Criteria can be changed as a drop-down of all Note types (including the base type), with a trinary tickbox (don't filter, must include, must exclude)
maybe in the future, user could add more complex conditions but i doubt i'll get there

## Flag types
- "Rumored" - automatically set when a Node doesn't have any regular tags
- "Loose end" indicating there are still questions on the Node

# Notes

## Note types
There are some preloaded Note types. The user should be able to create their own types as well.

There should be a setting for default Note type for both Nodes and Segments (e.g. Nodes will just have the "normal" type and Segments will have "rumor" type)

Types:
- (none) - base note type, no colors or really any name indicated
- Rumor
- Question - questions the user has about a Node
- Theory - user-crafted theory about something

# Sidebar
- "Click on a Node or Segment to edit" when nothing is selected (or maybe node creation is here?)
- Changeable color for Node button
- icons
- button to add a new note
- button to add a new note connected to other node
- function to connect existing note to other node
- function to delete a node
- tags, with color shown on left hand side
- "from NODE_NAME" showing source of a rumor (note in a Segment pointing to this Node)
- - "Show Incoming" setting universal to project
- - - Always (always show incoming notes)
- - - Only when flag(s) are present (default to include "Rumored" tag)
- - - Never
