PWD = $(shell pwd)

.tangle: source.org
	emacs --batch --quick -l org -l ${HOME}/.emacs --eval "(org-babel-tangle-file \"$<\")"
	touch $@


%.json: %.ttl
	bin/apache-jena/bin/riot --formatted=JSONLD $< > $@.temp
	bin/ld-cli frame -i file:$(PWD)/$@.temp file:$(PWD)/schema/... -po > $@
	sed -i 's/http:\/\/purl.org\/pav\/\(\w\)/pav:\1/g' $@
	rm $@.temp

%.html: %.ttl
	curl https://shacl-play.sparna.fr/play/doc -F includeDiagram=on -F shapesSource=file -F inputShapeFile=@$< > $@

%-val.txt: % schema/pkg-vocabulary.shacl.ttl
	bin/apache-jena-4.4.0/bin/shacl v --text --shapes schema/pkg-vocabulary.shacl.ttl --data $< > $@


all: \
	schema/pkg-vocabulary.shacl.html

docs/%: all
	mkdir -p $@
	cp -u schema/pkg-vocabulary.shacl.html $@/index.html
	cp -u schema/pkg-vocabulary.shacl.ttl $@
	mkdir -p $@/example
	cp -u example/* $@/example
