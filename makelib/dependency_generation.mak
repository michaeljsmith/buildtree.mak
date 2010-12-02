define rules_template
$(2)/%/.$(dependency_extension): $(1)/%/ $(2)/%/$(directory_marker_file)
	bash makelib/generate_directory_dependencies $$@ $(1)/$$*
endef

$(eval $(call rules_template,$(directory),$(dependency_directory)))
