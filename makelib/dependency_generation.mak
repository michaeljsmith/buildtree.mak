define rules_template
$(2)/%/.$(dependency_extension): $(1)/%/ $(2)/%/.$(marker_extension)
	bash makelib/generate_directory_dependencies $$@ $(1)/$$* $(3)/$$*

$(2)/%.cpp.$(dependency_extension): $(1)/%.cpp
	bash $(CPPFLAGS) makelib/generate_c_dependencies $$@ $(1)/$$*.cpp $(3)/$$(*D)

$(2)/%.h.$(dependency_extension): $(1)/%.h
	bash $(CPPFLAGS) makelib/generate_h_dependencies $$@ $(1)/$$*.h $(3)/$$(*D)
endef

$(eval $(call rules_template,$(directory),$(dependency_directory),$(object_directory)))
