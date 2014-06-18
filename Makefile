-include Makefile.config

.PHONY: opam-lib opam opam-admin opam-installer
all: opam-lib opam opam-admin opam-installer
	@

#backwards-compat
compile with-ocamlbuild: all
	@
install-with-ocamlbuild: install
	@
libinstall-with-ocamlbuild: libinstall
	@

byte:
	$(MAKE) all USE_BYTE=true

src/%:
	$(MAKE) -C src $*

%:
	$(MAKE) -C src $@

lib-ext:
	$(MAKE) -C src_ext lib-ext

download-ext:
	$(MAKE) -C src_ext archives

clean-ext:
	$(MAKE) -C src_ext distclean

clean:
	$(MAKE) -C src $@
	$(MAKE) -C doc $@

# With ocamlfind, prefer to install to the standard directory rather
# than $(prefix) if there are no overrides
ifndef LIBINSTALL_PREFIX
ifndef DESTDIR
ifneq ($(OCAMLFIND),no)
    LIBINSTALL_PREFIX = $(dir $(shell $(OCAMLFIND) printconf destdir))
endif
endif
endif

LIBINSTALL_PREFIX ?= $(prefix)

libinstall:
	$(if $(wildcard src_ext/lib/*),$(error Installing the opam libraries is incompatible with embedding the dependencies. Run 'make clean-ext' and try again))
	src/opam-installer --prefix $(DESTDIR)$(LIBINSTALL_PREFIX) --name opam opam-lib.install

install:
	src/opam-installer --prefix $(DESTDIR)$(prefix) opam.install

libuninstall:
	src/opam-installer -u --prefix $(DESTDIR)$(LIBINSTALL_PREFIX) --name opam opam-lib.install

uninstall:
	src/opam-installer -u --prefix $(DESTDIR)$(prefix) opam.install

.PHONY: tests tests-local tests-git
tests: opam opam-admin opam-check
	$(MAKE) -C tests all

# tests-local, tests-git
tests-%: opam opam-admin opam-check
	$(MAKE) -C tests $*

.PHONY: doc
doc: all
	$(MAKE) -C doc

.PHONY: man
man: opam opam-admin opam-installer
	$(MAKE) -C doc $@

configure: configure.ac m4/*.m4
	aclocal -I m4
	autoconf

release-tag:
	git tag -d latest || true
	git tag -a latest -m "Latest release"
	git tag -a $(version) -m "Release $(version)"


$(OPAM_FULL).tar.gz:
	$(MAKE) -C src_ext distclean
	$(MAKE) -C src_ext downloads
	rm -f $(OPAM_FULL) $(OPAM_FULL).tar.gz
	ln -s .

fast: src/core/opamGitVersion.ml src/core/opamScript.ml
	@if [ -n "$(wildcard src/*/*.cmi)" ]; then $(MAKE) clean; fi
	@ocp-build -init -scan
	@ln -sf ../_obuild/opam/opam.asm src/opam
	@ln -sf ../_obuild/opam-admin/opam-admin.asm src/opam-admin
	@ln -sf ../_obuild/opam-installer/opam-installer.asm src/opam-installer
	@ln -sf ../_obuild/opam-check/opam-check.asm src/opam-check

fastclean:
	@ocp-build -clean
	@rm -f $(addprefix src/, opam opam-admin opam-installer opam-check)
