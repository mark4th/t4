

all:    linux

linux:
	cd src/kernel/ && make

clean:
	rm t4 t4k
	cd src/kernel/ && make clean
