 cat docker-compose.yml | grep container|cut -d":" -f2 | sed 's/^ /\$\{MEDIACRACY_DIR\}\/configs\//g' |sed 's/$/\/config/g'
