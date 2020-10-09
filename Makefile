public/slides.pptx: slides.md
	mkdir -p public/
	pandoc $< -o $@

public/index.html: slides.md
	mkdir -p public/
	pandoc --standalone -t revealjs -V revealjs-url=https://unpkg.com/reveal.js@\^4 -o $@ --slide-level 3 $<