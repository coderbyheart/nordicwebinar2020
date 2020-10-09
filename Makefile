public/slides.pptx: slides.md
	mkdir -p public/
	pandoc $< -o $@

public/slides.html: slides.md
	mkdir -p public/
	pandoc --standalone -t revealjs -o $@ --slide-level 3 $<