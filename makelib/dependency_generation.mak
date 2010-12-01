$(dependency_directory)/%/.$(dependency_extension): \
	$(directory)/%/ \
	$(dependency_directory)/%/$(directory_marker_file)
	bash makelib/generate_directory_dependencies $@ $(directory)/$*

#$(dependency_directory)/%.$(dependency_extension):
#	touch $@
