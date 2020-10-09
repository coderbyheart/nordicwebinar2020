slides.pptx: slides.md
	pandoc slides.md -o slides.pptx

slides.html: slides.md
	pandoc --standalone -t revealjs -o slides.html --slide-level 3 slides.md