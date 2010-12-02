define rules_template
$(2)/%/.$(dependency_extension): $(1)/%/ $(2)/%/$(directory_marker_file)
	bash makelib/generate_directory_dependencies $$@ $(1)/$$*

$(2)/%.cpp.$(dependency_extension): $(1)/%.cpp
	bash makelib/generate_c_dependencies $$@ $(1)/$$*.cpp
endef

$(eval $(call rules_template,$(directory),$(dependency_directory)))
