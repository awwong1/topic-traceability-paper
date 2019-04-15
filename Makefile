NAME=main
#NAME=paper-diffsubmited-to-emse-1
BIBTEX=bibtex
LATEX=latex
VIEWER=`cat ~/.viewer || which okular || which evince || which open`
LATEX_OPTS=-interaction=nonstopmode -halt-on-error

VPATH=.:figures:figs:autofigs
FIGS=$(wildcard ./figures/*.png) $(wildcard ./figures/*.pdf)
CROPS=


JPGS=$(patsubst %.jpg,%.eps,$(filter %.jpg,$(FIGS)))
GIFS=$(patsubst %.gif,%.eps,$(filter %.gif,$(FIGS)))
PNGS=$(patsubst %.png,%.eps,$(filter %.png,$(FIGS)))
SVGS=$(patsubst %.svg,%.eps,$(filter %.svg,$(FIGS)))
PDFS=$(patsubst %.pdf,%.eps,$(filter %.pdf,$(FIGS)))

EPSS=$(addsuffix .eps,$(basename $(FIGS)))


.PHONY: all clean default view push commit zip

default: view

all: $(NAME).pdf

$(NAME).pdf: *.cls $(NAME).tex *.bib $(EPSS) $(CROPS)
	echo $(EPSS)
	$(LATEX) $(LATEX_OPTS) $(NAME).tex
	@if(grep "There were undefined references" $(NAME).log > /dev/null);\
	then \
		$(BIBTEX) $(NAME); \
		$(LATEX) $(LATEX_OPTS) $(NAME).tex; \
	fi
	@if(grep "Rerun" $(NAME).log > /dev/null);\
	then \
		$(LATEX) $(LATEX_OPTS) $(NAME).tex;\
	fi
	$(LATEX) $(LATEX_OPTS) $(NAME).tex
	dvips -j0 -Ppdf -Pbuiltin35 -G0 -z $(NAME).dvi
	gs -q -dPDFA \
	-dNOPAUSE -dBATCH -dSAFER -dPDFSETTINGS=/prepress \
	-dAutoFilterColorImages=false \
	-dAutoFilterGrayImages=false \
	-dAutoFilterMonoImages=false \
	-dColorImageFilter=/FlateEncode \
	-dGrayImageFilter=/FlateEncode \
	-dMonoImageFilter=/FlateEncode \
	-sDEVICE=pdfwrite -sOutputFile=$(NAME).pdf \
	-c .setpdfwrite \
	-f $(NAME).ps





clean:
	rm *.blg *.bbl *.log *.aux $(NAME).pdf $(NAME).dvi $(NAME).ps || echo Already Clean

view:	$(NAME).pdf
	$(VIEWER) $(NAME).pdf

$(SVGS) : %.eps : %.svg
	inkscape -b white -t -T --export-ignore-filters --export-eps=$@ $<

# Use PS pipeline for maximum compatibility with random latex packages

$(JPGS) : %.eps : %.jpg
	anytopnm $< | pnmtops -nocenter -equalpixels -dpi 72 -noturn -rle -setpage - > $@
$(GIFS) : %.eps : %.gif
	anytopnm $< | pnmtops -nocenter -equalpixels -dpi 72 -noturn -rle -setpage - > $@
$(PNGS) : %.eps : %.png
	anytopnm $< | pnmtops -nocenter -equalpixels -dpi 72 -noturn -rle -setpage - > $@



%-crop.pdf: %.pdf
	pdfcrop $<

%-crop.eps: %-crop.pdf
	pdftops -eps $< $@

$(PDFS) : %.eps : %.pdf
	pdftops -eps $< $@

push:	commit
	git push

commit:	
	git commit -av

zip : $(NAME).zip

$(NAME).zip : *.cls $(NAME).tex *.bib $(EPSS) Makefile
	zip $@ $^

x: $(NAME).pdf
	xournal $(NAME).pdf

