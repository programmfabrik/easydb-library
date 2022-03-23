WEB = build/webfrontend
WEBHOOKS = build/webhooks

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

L10N2JSON = $(SELF_DIR)/l10n2json.py

JS ?= $(WEB)/${PLUGIN_NAME}.js
WEBHOOK_NAME ?= ${PLUGIN_NAME}
WEBHOOK_JS ?= ${WEBHOOKS}/${WEBHOOK_NAME}.js
CSS ?= $(WEB)/${PLUGIN_NAME}.css
L10N = build-stamp-l10n

WEBFRONTEND_SASS ?= sass

PLUGIN_PATH ?= $(PLUGIN_NAME)

css: $(CSS)

$(CSS): $(SCSS_FILES)
	mkdir -p $(dir $@)
	cat $(SCSS_FILES) | $(WEBFRONTEND_SASS) --stdin > $(CSS) || ( rm -f $(CSS) ; false )

${JS}: $(subst .coffee,.coffee.js,${COFFEE_FILES})
	mkdir -p $(dir $@)
	cat $^ > $@

${WEBHOOK_JS}: $(subst .coffee,.coffee.js,${WEBHOOK_FILES})
	mkdir -p $(dir $@)
	cat $^ > $@

build-stamp-l10n: $(L10N_FILES)
	mkdir -p $(WEB)/l10n
	$(L10N2JSON) $(L10N_FILES) $(WEB)/l10n
	touch $@

buildinfojson:
	repo=`git remote get-url origin | sed -e 's/\.git$$//' -e 's#.*[/\\]##'` ;\
	rev=`git show --no-patch --format=%H` ;\
	lastchanged=`git show --no-patch --format=%ad --date=format:%Y-%m-%dT%T%z` ;\
	builddate=`date +"%Y-%m-%dT%T%z"` ;\
	echo '{' > build-info.json ;\
	echo '  "repository": "'$$repo'",' >> build-info.json ;\
	echo '  "rev": "'$$rev'",' >> build-info.json ;\
	echo '  "lastchanged": "'$$lastchanged'",' >> build-info.json ;\
	echo '  "builddate": "'$$builddate'"' >> build-info.json ;\
	echo '}' >> build-info.json

%.coffee.js: %.coffee
	coffee -b -p --compile "$^" > "$@" || ( rm -f "$@" ; false )

$(WEB)/%: src/webfrontend/%
	mkdir -p $(dir $@)
	cp $^ $@

install:

uninstall:

google_csv:
	chmod u+w $(L10N_FILES)
	curl --silent -L -o - "https://docs.google.com/spreadsheets/u/1/d/$(L10N_GOOGLE_KEY)/export?format=csv&id=$(L10N_GOOGLE_KEY)&gid=$(L10N_GOOGLE_GID)" | sed -e 's/[[:space:]]*$$//' > $(L10N_FILES)
	chmod a-w $(L10N_FILES)
	$(MAKE) build-stamp-l10n


install-server: ${INSTALL_FILES}
	[ ! -z "${INSTALL_PREFIX}" ]
	mkdir -p ${INSTALL_PREFIX}/server/base/plugins/${PLUGIN_PATH}
	for f in ${INSTALL_FILES}; do \
		mkdir -p ${INSTALL_PREFIX}/server/base/plugins/${PLUGIN_PATH}/`dirname $$f`; \
		if [ -d "$$f" ]; then \
			cp -Pr $$f ${INSTALL_PREFIX}/server/base/plugins/${PLUGIN_PATH}/`dirname $$f`; \
		else \
			cp $$f ${INSTALL_PREFIX}/server/base/plugins/${PLUGIN_PATH}/$$f; \
		fi; \
	done
	if [ -f "build-info.json" ]; then \
		cp "build-info.json" "${INSTALL_PREFIX}/server/base/plugins/${PLUGIN_PATH}/build-info.json"; \
	fi

clean-base:
	rm -f $(L10N) $(subst .coffee,.coffee.js,${COFFEE_FILES}) $(JS) $(SCSS)
	rm -f $(subst .coffee,.coffee.js,${WEBHOOK_FILES}) $(WEBHOOK_JS)
	rm -f $(WEB)/l10n/*.json
	rm -f build-stamp-l10n
	rm -rf build

wipe-base: clean-base
	find . -name '*~' -or -name '#*#' | xargs rm -f

.PHONY: all build buildinfojson clean clean-base wipe-base code install uninstall install-server google_csv

# vim:set ft=make:
