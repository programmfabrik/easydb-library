<Macro easydb-5-server-base \
	$uniqueid \
	$server_basedir \
	$plugins_basedir \
	$webfrontend_basedir \
	$solution_basedir \
	$frontend_slow_socket \
	$frontend_medium_socket \
	$frontend_fast_socket \
	$imexporter_socket \
	$upload_socket>

	RewriteMap easydb-5-dispatch-$uniqueid prg:$server_basedir/src/cgi-bin/dispatch_requests

	ScriptAlias /cgi-bin/ $server_basedir/src/cgi-bin/

	DocumentRoot $webfrontend_basedir/build

	<Location />
		Options -Indexes
		Require all granted
	</Location>

	AliasMatch ^/imexporter/ $server_basedir/src/imexporter/imexporter-$uniqueid

	AliasMatch ^/api/(v1/|)l10n/static/(.*)$ $server_basedir/build/l10n/$2
	AliasMatch ^/api/(v1/|)xmlmapping/static/(.*)$ $server_basedir/build/xmlmapping/$2
	AliasMatch ^/api/(v1/|)xmlmapping/tags$ $server_basedir/build/xmlmapping/eas-tags.json
	AliasMatch ^/api/(v1/|)plugin/static/base/([^/]*)/(.*)$ \
		$plugins_basedir/$2/build/webfrontend/$3
	AliasMatch ^/api/(v1/|)plugin/static/solution/([^/]*)/([^/]*)/(.*)$ \
		$solution_basedir/$2/plugins/$3/build/webfrontend/$4

	# /api/eas/put to "upload" socket
	AliasMatch ^/api/(v1/|)eas/put$ $server_basedir/src/imexporter/upload-$uniqueid
	
	RewriteEngine on
	RewriteCond $webfrontend_basedir/build/%{REQUEST_URI} !-f
	RewriteCond $webfrontend_basedir/build/%{REQUEST_URI} !-d
	RewriteCond $webfrontend_basedir/build/%{REQUEST_URI} !-l
	RewriteCond %{REQUEST_URI} !^/api
	RewriteCond %{REQUEST_URI} !^/cgi-bin
	RewriteCond %{REQUEST_URI} !^/docs
	RewriteCond %{REQUEST_URI} !^/cui
	RewriteCond %{REQUEST_URI} !^/eas
	RewriteCond %{REQUEST_URI} !^/imexporter
	RewriteCond %{REQUEST_URI} !^/exec-php
	RewriteCond %{REQUEST_URI} !^/test
	RewriteCond %{REQUEST_URI} !^/upload
	RewriteRule ^.*$ $webfrontend_basedir/build/index.html [QSA]

	FastCgiExternalServer $server_basedir/src/imexporter/frontend-s-$uniqueid \
		-idle-timeout 3000 -socket $frontend_slow_socket
	FastCgiExternalServer $server_basedir/src/imexporter/frontend-m-$uniqueid \
		-idle-timeout 3000 -socket $frontend_medium_socket
	FastCgiExternalServer $server_basedir/src/imexporter/frontend-f-$uniqueid \
		-idle-timeout 3000 -socket $frontend_fast_socket
	FastCgiExternalServer $server_basedir/src/imexporter/imexporter-$uniqueid \
		-idle-timeout 3000 -socket $imexporter_socket
	FastCgiExternalServer $server_basedir/src/imexporter/upload-$uniqueid \
		-idle-timeout 3000 -socket $upload_socket

	RewriteCond %{REQUEST_URI} !^/api/(v1/|)(l10n|plugin|xmlmapping)/static
	RewriteCond %{REQUEST_URI} !^/api/(v1/|)xmlmapping/tags
	RewriteCond %{REQUEST_URI} !^/api/(v1/|)eas/put
	RewriteRule ^/api/(v1/|)(.*)$ \
		$server_basedir/src/imexporter/frontend-${easydb-5-dispatch-$uniqueid:$2:$frontend_medium_socket:$frontend_fast_socket}-$uniqueid [L,NS]

	AddCharset utf-8 .js
	AddCharset utf-8 .json
	AddCharset utf-8 .html

	<IfModule mod_deflate.c>
		SetOutputFilter DEFLATE
		SetEnvIfNoCase Request_URI "\.(?:gif|jpe?g|png)$" no-gzip
	</IfModule>

	<Files ~ "\.(svg)$">
		Header set "Access-Control-Allow-Origin" "*"
		Header set "Access-Control-Allow-Headers" "Authorization, X-Easydb-Token"
		Header set "Cache-Control" "public,max-age=3600"
	</Files>

	<Files ~ "\.(html|json|js|css|otf|eot|ttf|woff|woff2)$">
		Header set "Access-Control-Allow-Origin" "*"
		Header set "Access-Control-Allow-Headers" "Authorization, X-Easydb-Token"
		Header set "Cache-Control" "no-cache,private,must-revalidate"
	</Files>

	<LocationMatch ^/api/(v1/|)(l10n|plugin|xmlmapping)/static>
		Header set "Access-Control-Allow-Origin" "*"
		Header set "Access-Control-Allow-Headers" "Authorization, X-Easydb-Token"
		Header set "Cache-Control" "no-cache,private,must-revalidate"
	</LocationMatch>
	<LocationMatch ^/api/(v1/|)xmlmapping/tags>
		Header set "Access-Control-Allow-Origin" "*"
		Header set "Access-Control-Allow-Headers" "Authorization, X-Easydb-Token"
		Header set "Cache-Control" "no-cache,private,must-revalidate"
	</LocationMatch>


	ErrorDocument 404 /cgi-bin/error-handler.sh
	ErrorDocument 500 /cgi-bin/error-handler.sh
	ErrorDocument 502 /cgi-bin/error-handler.sh
</Macro>

<Macro easydb-5-webdav-share $directory>
	AliasMatch ^/upload(.*) $directory$1
	<Location /upload>
		DAV on
		Options -MultiViews

		ErrorDocument 404 "Not Found"
		ErrorDocument 500 "Internal Server Error"
		ErrorDocument 502 "Bad Gateway"
	</Location>
</Macro>

# vim:set ft=apache:
