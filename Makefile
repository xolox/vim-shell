# This makefile for UNIX prepares the plug-in for publishing.

VIMDOC=doc/shell.txt
HTMLDOC=doc/readme.html
ZIPDIR := $(shell mktemp -d)
ZIPFILE := $(shell mktemp -u)
RELEASE=shell.zip

$(RELEASE): Makefile autoload.vim dll/shell.dll $(VIMDOC) $(HTMLDOC)
	@echo "Creating \`$(RELEASE)' .."
	@mkdir -p $(ZIPDIR)/autoload/xolox $(ZIPDIR)/doc $(ZIPDIR)/etc/shell
	@cp autoload.vim $(ZIPDIR)/autoload/xolox/shell.vim
	@cp dll/shell.dll $(ZIPDIR)/autoload/xolox/
	@cp $(VIMDOC) $(ZIPDIR)/doc/
	@cp dll/shell.c dll/Makefile $(HTMLDOC) $(ZIPDIR)/etc/shell/
	@cd $(ZIPDIR) && zip -r $(ZIPFILE) . >/dev/null
	@rm -R $(ZIPDIR)
	@mv $(ZIPFILE) $(RELEASE)

# This rule converts the Markdown README to Vim documentation.
$(VIMDOC): Makefile README.md
	@echo "Creating \`$(VIMDOC)' .."
	@mkd2vimdoc.py `basename $(VIMDOC)` < README.md > $(VIMDOC)

# This rule converts the Markdown README to HTML, which reads easier.
$(HTMLDOC): Makefile README.md
	@echo "Creating \`$(HTMLDOC)' .."
	@cat doc/README.header > $(HTMLDOC)
	@cat README.md | markdown | SmartyPants >> $(HTMLDOC)
	@cat doc/README.footer >> $(HTMLDOC)

# This is only useful for myself, it uploads the latest README to my website.
web: $(HTMLDOC)
	@echo "Uploading homepage and latest release .."
	@scp -q $(HTMLDOC) vps:/home/peterodding.com/public/files/code/vim/shell/index.html
	@scp -q $(RELEASE) vps:/home/peterodding.com/public/files/code/vim/shell/

all: $(RELEASE) web
