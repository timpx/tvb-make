# TODO phony targets
vep_algo = variational

$(sd)/vep:
	mkdir -p $(sd)/vep

$(sd)/vep/input.R: $(sd)/vep $(SEIZURE) $(sd)/dwi/count.txt $(sd)/mri/$(aa).xyz $(sd)/seeg/gain.mat $(sd)/seeg/seeg.xyz
	./vep.py prep_vep_data $@ $^

$(sd)/vep/vep.stan: vep.stan
	cp $< $@

$(sd)/vep/vep: $(sd)/vep/vep.stan
	cd $(cmdstan) && make $@

$(sd)/vep/output.csv: $(sd)/vep/input.R
	./vep $(vep_algo) data file=$< output file=$@

$(sd)/vep/summary.png: $(sd)/vep/output.csv
	./vep.py
