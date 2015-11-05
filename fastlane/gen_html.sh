awk '{sub(/\$version/,version);sub(/\$build/,build);sub(/\$date/,date);}1' version="$1" build="$2" date="$3" template.html > ~/Dropbox/p2.html
