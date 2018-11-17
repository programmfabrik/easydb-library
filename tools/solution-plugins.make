WEB = build/webfrontend
L10N2JSON := easydb-l10n2json.py

JS ?= $(WEB)/${PLUGIN_NAME}.js
L10N = build-stamp-l10n
JS_FILES ?=
SCSS_FILES ?=

CSS ?= $(WEB)/${PLUGIN_NAME}.scss

export SASS_PATH=.
scss_call =  sass --scss --no-cache --sourcemap=inline

css: $(CSS)

$(CSS): $(SCSS_FILES)
	mkdir -p $(dir $@)
	cat $(SCSS_FILES) | $(scss_call) > $(CSS)

${JS}: $(subst .coffee,.coffee.js,${COFFEE_FILES}) $(JS_FILES)
	mkdir -p $(dir $@)
	cat $^ > $@

${SCSS}: ${SCSS_FILES}
	mkdir -p $(dir $@)
	cat $^ > $@

build-stamp-l10n: $(CULTURES_CSV) $(L10N_FILES)
	mkdir -p $(WEB)/l10n
	$(L10N2JSON) $(CULTURES_CSV) $(L10N_FILES) $(WEB)/l10n
	touch $@

%.coffee.js: %.coffee
	coffee -b -p --compile "$^" > "$@" || ( rm -f "$@" ; false )

$(WEB)/%: src/webfrontend/%
	mkdir -p $(dir $@)
	cp $^ $@

install:

uninstall:

install-solution: ${INSTALL_FILES}
	[ ! -z "${INSTALL_PREFIX}" ]
	mkdir -p ${INSTALL_PREFIX}/solution-${SOLUTION}/solutions/${SOLUTION}/plugins/${PLUGIN_NAME}
	for f in ${INSTALL_FILES}; do \
		mkdir -p ${INSTALL_PREFIX}/solution-${SOLUTION}/solutions/${SOLUTION}/plugins/${PLUGIN_NAME}/`dirname $$f`; \
		if [ -d "$$f" ]; then \
			cp -Pr $$f ${INSTALL_PREFIX}/solution-${SOLUTION}/solutions/${SOLUTION}/plugins/${PLUGIN_NAME}/`dirname $$f`; \
		else \
			cp $$f ${INSTALL_PREFIX}/solution-${SOLUTION}/solutions/${SOLUTION}/plugins/${PLUGIN_NAME}/$$f; \
		fi; \
	done

google_csv:
	chmod u+w $(L10N_FILES)
	curl --silent -o - "https://docs.google.com/spreadsheets/u/1/d/$(L10N_GOOGLE_KEY)/export?format=csv&id=$(L10N_GOOGLE_KEY)&gid=$(L10N_GOOGLE_GID)" | sed -e 's/[[:space:]]*$$//' > $(L10N_FILES)
	chmod a-w $(L10N_FILES)
	$(MAKE) build-stamp-l10n

clean-base:
	rm -f $(L10N) $(subst .coffee,.coffee.js,${COFFEE_FILES}) $(JS) $(SCSS)

.PHONY: all build clean clean-base code install uninstall install-server google_csv

# vim:set ft=make:
