set-option -g default-path .

neww -t 1 -n web  'bin/tracklet'
neww -t 2 -n psql 'psql tracklet'
neww -t 3 -n irb  'ruby -rirb -r./lib/tracklet -e "Bundler.require :dev; IRB.start"'
neww -t 4 -n tig  'tig'

bind T neww -t 0 -n bash 'bash'
bind Y neww -t 1 -n web  'bin/tracklet'
bind U neww -t 2 -n psql 'psql tracklet'
bind I neww -t 3 -n irb  'ruby -rirb -r./lib/tracklet -e "Bundler.require :dev; IRB.start"'
bind O neww -t 4 -n tig  'tig'

selectw -t 0
kill-window
neww -t 0 -n bash 'bash'
