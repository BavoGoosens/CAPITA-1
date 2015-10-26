
WORDS?=10


default: assignment

all: assignment solve test


download:
	@echo "Download Reuters archive from http://kdd.ics.uci.edu/databases/reuters21578/reuters21578.html"
	mkdir -p reuters21578
	cd reuters21578 && wget http://kdd.ics.uci.edu/databases/reuters21578/reuters21578.tar.gz
	cd reuters21578 && tar -zxvf reuters21578.tar.gz


assignment:
	mkdir -p data_${WORDS}
	./convert_reuters.py -t grain -t interest -p -w ${WORDS} reuters21578/reut2-003.sgm
	mv reuters_facts.pl data_${WORDS}/reuters_facts_test.pl
	./convert_reuters.py -t grain -t interest -p -w ${WORDS} reuters21578/reut2-00{1,2}.sgm
	mv reuters_ev.pl data_${WORDS}
	mv reuters_model.pl data_${WORDS}/


solve:
	problog-cli lfi -O data_${WORDS}/reuters_model_trained.pl -v data_${WORDS}/reuters_model.pl data_${WORDS}/reuters_ev.pl


test:
	cat data_${WORDS}/reuters_model_trained.pl data_${WORDS}/reuters_facts_test.pl > data_${WORDS}/reuters_test.pl
	problog-cli data_${WORDS}/reuters_test.pl


data:
	make WORDS=10
	make WORDS=20
	make WORDS=30
	make WORDS=40
	make WORDS=50
