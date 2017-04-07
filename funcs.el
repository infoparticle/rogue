;;; funcs.el --- rogue Layer utility functions

(defun kill-other-buffers ()
  "Kill all other buffers."
  (interactive)
  (mapc 'kill-buffer
        (delq (current-buffer) (buffer-list))))

(defun explore-here ()
  "Open file manager in current buffer's directory."
  (interactive)
  (if (eq system-type 'windows-nt)
      (shell-command "explorer .")
    (if (eq system-type 'gnu/linux)
        (shell-command "xdg-open .")
      (display-warning :error "System Not supported"))))

(defun to-fish-find-file (candidate)
  "Run find file for given bookmark"
  (helm-find-files-1 (concat
                      (file-name-as-directory (expand-file-name "~/.tofish"))
                      candidate
                      "/")))

(defun to-fish-jump ()
  "Jump to to-fish bookmarks"
  (interactive)
  (helm :sources (helm-build-sync-source "bookmarks"
                   :candidates (lambda ()
                                 (directory-files "~/.tofish"))
                   :action '(("Jump to bookmark" . to-fish-find-file)))
        :buffer "*helm tofish jump*"
        :prompt "Jump to : "))

(defun git-archive ()
  "Archive current repository"
  (interactive)
  (let ((repo-root (magit-toplevel)))
    (if repo-root
        (let ((output-file (read-file-name "Output file: ")))
          (if (eq 0 (call-process "git"
                                  nil nil nil
                                  "archive"
                                  "-o" output-file
                                  "HEAD"))
              (message "git-archive finished")
            (display-warning :error "Error in archiving")))
      (display-warning :error "Not in a git repository"))))

(defun fahrenheit-to-celcius (f)
  "Convert F to C"
  (/ (- f 32) 1.8))

(defun transform-pair-units (pairs)
  "Transform unit pairs to SI. Just temp for now."
  (mapcar (lambda (pair)
            (let ((split (split-string (second pair) "°")))
              (if (string-equal (second split) "F")
                  (progn
                    (list
                     (first pair)
                     (concat (format "%0.2f"
                              (fahrenheit-to-celcius
                               (string-to-number (first split)))) "°C")))
                pair))) pairs))

(defun show-weather-in-buffer (pairs location)
  "Display weather data in a new buffer"
  (let ((buffer (get-buffer-create "*Weather*")))
    (set-buffer buffer)
    (setq buffer-read-only nil)
    (erase-buffer)
    (org-mode)
    (insert "#+TITLE: ")
    (insert location)
    (insert "\n\n")
    (mapc (lambda (pair)
            (insert (concat "+ " (first pair) " :: " (second pair) "\n")))
          (transform-pair-units (butlast pairs)))
    (switch-to-buffer buffer)
    (setq buffer-read-only t)
    (goto-char (point-min))))

(defun mpc-send-message (channel message)
  "Send message to mpc"
  (if (eq 0 (call-process "mpc"
                          nil nil nil
                          "sendmessage"
                          channel message))
      (message "Done")
    (display-warning :error "Error in sending message to mpc")))

(defun mpdas-love ()
  "Love song on scrobbler service"
  (interactive)
  (mpc-send-message "mpdas" "love"))

(defun mpdas-unlove ()
  "Unlove currently playing song"
  (interactive)
  (mpc-send-message "mpdas" "unlove"))

(defun weather-amherst ()
  "Get local weather information for Amherst from CS station"
  (interactive)
  (let* ((rss-url "http://weather.cs.umass.edu/RSS/weewx_rss.xml")
         (location "Amherst, MA (USA)")
         (node (first (enlive-get-elements-by-tag-name
                       (enlive-fetch rss-url) 'encoded)))
         (items (split-string (enlive-text node) "\n" t)))
    (show-weather-in-buffer
     (mapcar (lambda (item)
               (mapcar 'string-trim (split-string item ": "))) items) location)
    (weather-amherst-mode)))

(defvar weather-amherst-mode-map (make-sparse-keymap))
(define-key weather-amherst-mode-map (kbd "q") 'kill-this-buffer)

(define-minor-mode weather-amherst-mode
  "Minor mode for adding keybindings"
  nil nil
  weather-amherst-mode-map)

(defun delete-word (arg)
  "Delete characters forward until encountering the end of a word.
With argument, do this that many times."
  (interactive "p")
  (delete-region (point) (progn (forward-word arg) (point))))

(defun backward-delete-word (arg)
  "Delete characters backward until encountering the end of a word.
With argument, do this that many times."
  (interactive "p")
  (delete-word (- arg)))

(defun duplicate-line ()
  "Duplicate a line."
  (interactive)
  (move-beginning-of-line 1)
  (kill-line)
  (yank)
  (newline)
  (yank))

(defun insect-calc ()
  "Run insect calculator."
  (interactive)
  (shell-command (format "insect \"%s\"" (read-string "insect: "))))

(defun org-random-sort ()
  "Shuffle org-entries randomly"
  (random 1000))

(defun org-shuffle-projects ()
  "Shuffle first level items in project files"
  (interactive)
  (dolist (project-file user-project-files)
    (find-file project-file)
    (goto-char (point-min))
    (org-sort-entries nil ?f 'org-random-sort)
    (save-buffer)))

(defun org-screenshot-store-path ()
  "Return path to a directory that stores images for given ORG-FILE-NAME.
Create the directory if not present."
  (let ((store-directory-path (file-name-as-directory "./images")))
    (unless (file-exists-p store-directory-path)
      (make-directory store-directory-path))
    store-directory-path))

(defun org-screenshot-unique-file ()
  "Return path to a unique image file in png"
  (let ((image-file (concat (number-to-string (float-time)) ".png")))
    (concat (org-screenshot-store-path) image-file)))

(defun org-insert-screenshot ()
  "Take screenshot using `import' and insert in current buffer"
  (interactive)
  (let* ((image-path (org-screenshot-unique-file))
         (command (concat "import " image-path)))
    (call-process-shell-command command)
    (org-insert-link nil image-path "")
    (org-display-inline-images)))

(defun org-paste-image ()
  "Paste image from clipboard into current buffer"
  (interactive)
  (let* ((image-path (org-screenshot-unique-file))
         (command (concat "xclip -selection clipboard -t image/png -o > " image-path)))
    (call-process-shell-command command)
    (org-insert-link nil image-path "")
    (org-display-inline-images)))
