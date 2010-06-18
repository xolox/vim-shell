PROJECT=shell
RELEASE=$(PROJECT).zip
VIMDOC := $(shell mktemp -u)
ZIPFILE := $(shell mktemp -u)
ZIPDIR := $(shell mktemp -d)

$(RELEASE): Makefile README.md autoload.vim dll/$(PROJECT).dll
	@echo "Creating \`$(PROJECT).txt' .."
	@mkd2vimdoc.py $(PROJECT).txt < README.md > $(VIMDOC)
	@echo "Creating \`$(RELEASE)' .."
	@mkdir -p $(ZIPDIR)/autoload/xolox $(ZIPDIR)/doc $(ZIPDIR)/etc/$(PROJECT)
	@cp autoload.vim $(ZIPDIR)/autoload/xolox/$(PROJECT).vim
	@cp dll/$(PROJECT).dll $(ZIPDIR)/autoload/xolox/
	@cp $(VIMDOC) $(ZIPDIR)/doc/$(PROJECT).txt
	@cp dll/$(PROJECT).c dll/Makefile $(ZIPDIR)/etc/$(PROJECT)/
	@cd $(ZIPDIR) && zip -r $(ZIPFILE) . >/dev/null
	@rm -R $(ZIPDIR)
	@mv $(ZIPFILE) $(RELEASE)
