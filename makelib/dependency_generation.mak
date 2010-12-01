# TODO: Make this immediate rather than deferred.
define recipe
bash makelib/generate_directory_dependencies $@ $(directory)/$*
endef

$(dependency_directory)/%/.$(dependency_extension): $(directory)/%/ $(dependency_directory)/%/$(directory_marker_file)
	$(recipe)
