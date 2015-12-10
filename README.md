# Emacs File Reference Recorder
Emacs File Reference Recorder is a recording file history client for DTB.
Please refer to [DTB's repository](https://github.com/nomlab/DTB) in order to know DTB.

## Version
0.3

## Requirements
+ Emacs 24 or higher
+ Latest [request.el](https://github.com/tkf/emacs-request)

## Install and Setup

### Install Emacs File Reference Recorder

```sh
$ cd ~/.emacs.d/elpa
$ git clone git@github.com:okada-takuya/emacs-file-reference-recorder
```

### Install package Emacs File Reference Recorder depends on

```sh
$ cd ~/.emacs.d/elpa
$ git clone git@github.com:tkf/emacs-request.git
```

### Add load path

```sh
$ echo "(add-to-list 'load-path \"~/.emacs.d/elpa/emacs-request\")" >> ~/.emacs.d/init.el
$ echo "(add-to-list 'load-path \"~/.emacs.d/elpa/emacs-file-reference-recorder\")" >> ~/.emacs.d/init.el
```

### Require Emacs File Reference Recorder and set custom value

```sh
$ echo "(require 'file-reference-recorder)" >> ~/.emacs.d/init.el
$ echo "(custom-set-variables '(frr:dtb-url \"http://localhost:3000\")'(frr:history-location \"~/.file-reference-history\"))" >> ~/.emacs.d/init.el
```

## How to use
### Record history
Edit and refer to files by Emacs as usual.
Emacs File Reference Recorder records and posts history to DTB automatically.

### Check stored Unified History in DTB
Access to http://your-DTB-url/unified_histories
