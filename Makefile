PWD = $(shell pwd)

examples := $(wildcard example/*.ttl)
examples-val = $(examples:.ttl=.ttl-val.txt)

JENA-version = apache-jena-4.10.0
JENA = bin/$(JENA-version)

$(JENA):
	mkdir -p bin
	wget https://apache.uib.no/jena/binaries/$(JENA-version).zip -O $@.zip
	unzip -u $@.zip -d bin

install: \
	$(JENA)


.tangle: README.org
	emacs --batch --quick -l org -l ${HOME}/.emacs --eval "(org-babel-tangle-file \"$<\")"
	touch $@

pkg-vocabulary.shacl.ttl: .tangle
	$(JENA)/bin/shacl v --text --shapes  http://www.w3.org/ns/shacl-shacl --data $@ > $@-val.txt

%.json: %.ttl
	$(JENA)/bin/riot --formatted=JSONLD $< > $@.temp
	bin/ld-cli frame -i file:$(PWD)/$@.temp file:$(PWD)/... -po > $@
	sed -i 's/http:\/\/purl.org\/pav\/\(\w\)/pav:\1/g' $@
	rm $@.temp

%.html: %.ttl
	rapper -gc $<
	curl https://shacl-play.sparna.fr/play/doc -F includeDiagram=on -F shapesSource=file -F inputShapeFile=@$< > $@

%-val.txt: % pkg-vocabulary.shacl.ttl
	$(JENA)/bin/shacl v --text --shapes pkg-vocabulary.shacl.ttl --data $< > $@


all: \
	pkg-vocabulary.shacl.html \
	$(examples-val)

docs/%: all
	mkdir -p $@
	cp -u pkg-vocabulary.shacl.html $@/index.html
	cp -u pkg-vocabulary.shacl.ttl $@
	mkdir -p $@/example
	cp -u example/* $@/example
