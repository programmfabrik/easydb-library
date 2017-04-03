all:
	@echo install tools:
	@echo "  make install-home               # install to $$HOME/bin"
	@echo "  make install-usrlocal           # install to /usr/local/bin"
	@echo "  make install PREFIX=/somewhere  # install to /somewhere/bin"

TOOLS_TO_INSTALL = \
	l10n2json.py \
	unimport_scss.py

install:
	[ ! -z "${PREFIX}" ] # ensure PREFIX is set
	mkdir -p "${PREFIX}/bin"
	for tool in ${TOOLS_TO_INSTALL}; do \
		install -m 755 "$$tool" "${PREFIX}/bin/easydb-$$tool" ; \
	done

install-home:
	$(MAKE) install PREFIX="${HOME}"

install-usrlocal:
	$(MAKE) install PREFIX=/usr/local
