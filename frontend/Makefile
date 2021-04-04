CC=pyinstaller

udbrew: udbrew.py
	$(CC) -F udbrew.py
	cp -vf ./dist/udbrew ./

all: udbrew

clean:
	rm -rfv ./dist ./build ./udbrew ./__pycache__
