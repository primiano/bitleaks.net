OUT=htdocs
SCSS=pyscss --images-root=images --images-url=/static/images --no-debug-info -C
OPTIPNG=optipng -o2 -quiet
SHASUM=python -c "import hashlib,sys; h=hashlib.sha1(); h.update(open(sys.argv[1]).read()); print h.hexdigest()[0:8]"
MERGEJSON=python mergejson.py
RENDER=python render.py --out-base-dir $(OUT)

BLOG_TAGS=android coding electronics git
ASSETS_IMAGES=$(wildcard assets/images/*.png)
ASSETS_IMAGES+=$(wildcard assets/images/*.ico)
OUT_BLOGPOSTS=$(patsubst blogposts/%,$(OUT)/blog/%,$(wildcard blogposts/*))
PARTIAL_TEMPLATES=$(wildcard templates/_*.html)

all: blogposts home tags atomfeed

$(OUT)/.mkdir $(OUT)/%/.mkdir:
	@mkdir -p $(dir $(abspath $@))
	@touch $(abspath $@)

$(OUT)/index.html: templates/home.html \
                   $(PARTIAL_TEMPLATES) \
                   $(OUT)/blog/index.json \
                   $(OUT)/static/.stamp \
                   render.py \
                   | $(OUT)/.mkdir
	$(RENDER) --template-in $< \
	          --html-out $@ \
	          --json-in $(OUT)/blog/index.json

$(OUT)/blog/tags/%/index.html: templates/home.html \
                               $(PARTIAL_TEMPLATES) \
                               $(OUT)/blog/index.json \
                               $(OUT)/static/.stamp \
                               render.py \
                               | $(OUT)/blog/tags/%/.mkdir
	$(RENDER) --template-in $< \
	          --html-out $@ \
	          --var cur_tag=$* \
	          --json-in $(OUT)/blog/index.json

$(OUT)/blog/%/index.html \
$(OUT)/blog/%/index.json: blogposts/%/index.md \
                          templates/blogpost.html \
                          $(PARTIAL_TEMPLATES) \
                          $(OUT)/static/.stamp \
                          $(OUT)/static/blog/attachments.stamp \
                          render.py \
                          | $(OUT)/blog/%/.mkdir
	cp -f $< $(OUT)/blog/$*/index.md
	$(RENDER) --template-in templates/blogpost.html \
	          --markdown-in $(OUT)/blog/$*/index.md \
	          --markdown-meta-out $(OUT)/blog/$*/index.json \
	          --resources-dir /static/blog/$* \
	          --html-out $(OUT)/blog/$*/index.html

$(OUT)/blog/index.json: $(addsuffix /index.json,$(OUT_BLOGPOSTS))
	$(MERGEJSON) $@ $^

$(OUT)/atom.xml: templates/atom.xml \
                 $(OUT)/blog/index.json \
                 render.py \
                 | $(OUT)/.mkdir
	$(RENDER) --template-in $< \
	          --html-out $@ \
	          --json-in $(OUT)/blog/index.json

$(OUT)/static/css/%.css.in: assets/css/%.scss \
                            $(wildcard assets/css/_*.scss) \
                            $(wildcard assets/images/*) \
                            | $(OUT)/static/css/.mkdir
	$(SCSS) $< -o $@

$(OUT)/static/images/%.png.in: assets/images/%.png \
                               | $(OUT)/static/images/.mkdir
	@cp -f $< $@
	$(OPTIPNG) $@

$(OUT)/static/images/%.in: assets/images/% \
                           | $(OUT)/static/images/.mkdir
	@cp -f $< $@

$(OUT)/static/js/%.in: assets/js/% \
                       | $(OUT)/static/js/.mkdir
	@cp -f $< $@

$(OUT)/static/blog/%.png.in: blogposts/%.png \
                             | $(OUT)/static/blog/%/../.mkdir
	@cp -f $< $@
	$(OPTIPNG) $@

$(OUT)/static/blog/%.in: blogposts/% \
                         | $(OUT)/static/blog/%/../.mkdir
	@cp -f $< $@

$(OUT)/static/fonts/.stamp: assets/fonts/* | $(OUT)/static/fonts/.mkdir
	cp -rf assets/fonts/* $(OUT)/static/fonts/
	touch $@

$(OUT)/static/.stamp: \
    $(patsubst assets/images/%,$(OUT)/static/images/%,$(ASSETS_IMAGES)) \
		$(patsubst assets/css/%.scss,$(OUT)/static/css/%.css,$(wildcard assets/css/[a-z]*.scss)) \
    $(patsubst assets/js/%,$(OUT)/static/js/%,$(wildcard assets/js/*.js)) \
    $(OUT)/static/fonts/.stamp \
    | $(OUT)/static/images/.mkdir \
      $(OUT)/static/fonts/.mkdir \
      $(OUT)/static/css/.mkdir \
      $(OUT)/static/js/.mkdir
	touch $@

$(OUT)/static/blog/attachments.stamp: \
    $(patsubst blogposts/%,$(OUT)/static/blog/%,$(wildcard blogposts/*/*))
	touch $@

$(OUT)/blog/tags/.stamp: \
    $(addprefix $(OUT)/blog/tags/, $(addsuffix /index.html, $(BLOG_TAGS)))
	touch $@

$(OUT)/static/% : $(OUT)/static/%.in
	$(eval SHA := $(shell $(SHASUM) $<))
	$(eval TARGET := $(basename $@)-$(SHA)$(suffix $@))
	@cp $< $(basename $@)-$(SHA)$(suffix $@)
	@ln -fs $(notdir $(TARGET)) $@

$(OUT)/%: assets/%
	cp $(patsubst $(OUT)/%,assets/%,$@) $@

home: $(OUT)/index.html $(OUT)/robots.txt $(OUT)/robots-allow.txt
tags: $(OUT)/blog/tags/.stamp
blogposts: $(addsuffix /index.html,$(OUT_BLOGPOSTS))
atomfeed: $(OUT)/atom.xml

dev:
	dev_appserver.py .

deploy:
	gcloud app deploy --project bitleaks-net
	@echo 'Done. Remember to push to github'

clean:
	rm -rf $(OUT)/*

.PHONY: all home tags blogposts atomfeed dev clean
