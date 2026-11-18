;; H871 Available Command definition
;; Target: Creo Elements/Direct Modeling 18.1
;; Integration Kit file syntax – NOT a normal Lisp source file.
;; Do not load this file with (load ...).
;;
;; For the first runtime test, create the equivalent command through the
;; Modeling Customize UI. If integrating this definition into the user's
;; user_avail_cmds.cmd, back up that file first and preserve other entries.

(:Application "SolidDesigner")
(:Group "H871" :title "H871")

("H871 Part Filter - All Pages"
 :title "H871 Part Filter"
 :action "H871_PART_FILTER_VER_03"
 :description "Open the H871 Part Filter with Part Note and cross-page selection."
 :image "H871/part_filter"
 :ui-behavior :default)
