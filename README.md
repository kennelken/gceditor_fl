# gceditor
<img src="https://kennelken.github.io/Icon-192.png" width="120">

----
<b>gceditor</b> is a client/server application for creating a persistent data of an application (config/model).
It can generate <b>json, java, c#</b> files for the model which makes it very useful for c#-based applications/games.

The application is written in dart (flutter) and contains both the backend and frontend logic. The client is available as a native desktop application and a web application.

It does not require to setup any complex environment because it stores data in json files so it should fit small and medium projects.

## Main Screen
<center><img src="https://kennelken.github.io/gceditor_overview.png" width="700"></center>

## Features
* <b>Json</b>, <b>C#</b>, <b>Java</b> generators produce files that can be imported and parsed in c# environment as simple as
```
	var config = GceditorJsonParser.Parse(_getConfigText());
```
* All vital data types are supported, including <b>simple types</b>, <b>reference types</b>, <b>enums</b>, <b>lists</b>, <b>sets</b>, <b>dictionaries</b>
* A lot of useful helpers: <b>Find</b> with advanced settings, <b>pin</b> items, <b>problems</b> view.
* Possibility to <b>undo</b> any action.
* All generated classes are <b>partial</b>. They can be expanded if needed.
* <b>Classes</b> support inheritance.
* Clients establish <b>socket</b> connection with the server which guarantees high responsiveness of a client to the changes made by  other clients.
* Shortcuts for <b>git</b> commit and push for saving the progress.
* <b>History</b> of made changes that can be used to reproduce the changes in other branches.
* Possibility to run the application in <b>standalone</b> mode - perfect for solo developers.
* <b>Copy/paste</b> data rows, including interacting with external spreadsheets applications via Clipboard.
* Available as both standalone application and web application (client mode only)
* Config files created by <b>gceditor</b> are ready to use with <b>Unity</b>.
* <b>Git-friendly</b> generated Json, c#, Java files
* Full set of <b>cli arguments</b>
* <b>Client</b> application is available for <b>Windows</b>, <b>Linux</b>, <b>macOS</b>, <b>Web</b>
* <b>Server</b> mode is available for <b>Windows</b>, <b>Linux</b>, <b>macOS</b>

## Screenshots

<details>
	<summary>Data types (click to expand)</summary>
	<img src="https://kennelken.github.io/gceditor_datatypes.png" width="700">
</details>

<details>
	<summary>Find (click to expand)</summary>
	<img src="https://kennelken.github.io/gceditor_find.png" width="700">
</details>

<details>
	<summary>Pin items (click to expand)</summary>
	<img src="https://kennelken.github.io/gceditor_pin.png" width="700">
</details>

<details>
	<summary>Problems (click to expand)</summary>
	<img src="https://kennelken.github.io/gceditor_problems.png" width="700">
</details>

<details>
	<summary>References (click to expand)</summary>
	<img src="https://kennelken.github.io/gceditor_reference.png" width="700">
</details>

<details>
	<summary>Settings (click to expand)</summary>
	<img src="https://kennelken.github.io/gceditor_settings.png" width="700">
</details>

<details>
	<summary>History (click to expand)</summary>
	<img src="https://kennelken.github.io/gceditor_history.png" width="700">
</details>

# Usage
## Binaries from the Releases section
Latest binaries are available in the Releases section here https://github.com/kennelken/gceditor_fl/releases
## From the source code
To build the application from the source code you need:
* Install flutter from https://docs.flutter.dev/get-started/install
* Build the project with the following commands from the corresponding OS:
```
	// windows
	flutter config --enable-windows-desktop
	flutter build windows --release

	// linux
	sudo apt install clang libgtk-3-dev ninja-build -y
	flutter config --enable-linux-desktop
	flutter build linux --release

	// macos
	flutter config --enable-macos-desktop
	flutter build macos --release

	// any OS
	flutter build web --release
```