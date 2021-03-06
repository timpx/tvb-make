# Rules for FreeSurfer reconstruction & downsampling

# ensure user provided SUBJECTS_DIR propagates to commands
# as an environment variable
export SUBJECTS_DIR

# most other parts of the pipeline are organized into topic
# folders inside the subject folder, so we need FreeSurfer to
# setup that folder first; it just requires importing the
# T1. Other rules depend on the 001.mgz, so that they can
# run in parallel to the recon-all -all below
$(sd)/mri/orig/001.mgz: $(T1)
	mrconvert $(T1) $(SUBJECT)-T1_raw.nii.gz
	recon-all -s $(SUBJECT) -i $(SUBJECT)-T1_raw.nii.gz
	rm $(SUBJECT)-T1_raw.nii.gz

# run the full reconstruction w/ parallelism
$(fs_done): $(sd)/mri/orig/001.mgz
	recon-all -s $(SUBJECT) -all -parallel -openmp $(nthread)

# this ensures we have a writeable copy of the resample target data
$(rtd):
	cp -r $(FREESURFER_HOME)/subjects/$(resamp_target) $(SUBJECTS_DIR)/

# resample anatomy, usually at lower resolution
$(sd)/surf/%.$(sval).$(resamp_target): $(rtd) $(fs_done)
	mri_surf2surf \
		--srcsubject $(SUBJECT) \
		--trgsubject $(resamp_target) \
		--hemi $* \
		--sval-xyz $(sval) \
		--tval $(sval).$(SUBJECT) \
		--tval-xyz $(sd)/mri/T1.mgz
	cp $(rtd)/surf/$*.$(sval).$(SUBJECT) \
	    $(sd)/surf/$*.$(sval).$(resamp_target)
	mri_surf2surf \
		--srcsubject $(SUBJECT) \
		--trgsubject $(resamp_target) \
		--hemi $* \
		--sval-annot $(sd)/label/$*.$(parc).annot \
		--tval $(sd)/label/$*.$(parc).annot.$(resamp_target)

# generate centers
$(sd)/mri/$(aa).xyz: $(fs_done)
	python -m util.util label_volume_centers $(sd)/mri/$(aa).mgz $@

# generate subcortical region volume bounding surfaces
$(sd)/aseg2srf: $(fs_done)
	$(here)/util/aseg2srf -s $(SUBJECT)
