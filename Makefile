#TODO: Handle includes outside of tree.
dependency_extension=dep.mak

marker_extension=marker

config=debug
config_prefix=$(config)

module_name=testmod
module_source_dir=.
module_dep_dir=dep
module_dep_path=$(config_prefix)/$(module_dep_dir)
module_obj_dir=obj
module_obj_path=$(config_prefix)/$(module_obj_dir)
module_bin_dir=bin
module_bin_path=$(config_prefix)/$(module_bin_dir)

module_target=$(module_bin_path)/$(module_name)

source_dependency_file=$(module_dep_path)/src.$(dependency_extension)

.PHONY: default clean
default: $(module_target) $(config_prefix)/.$(marker_extension)

clean:
	rm -rf $(config_prefix)

include $(source_dependency_file)

$(module_target): $(objects) |$(module_bin_path)/.$(marker_extension)
	$(CXX) $(LDFLAGS) -o $@ $^ $(LOADLIBES) $(LDLIBS)

%/.$(marker_extension):
	mkdir -p $(@D)
	touch $@

.PRECIOUS: %/.$(marker_extension)

$(source_dependency_file): $(module_dep_path)/.$(marker_extension)
	bash makelib/generate_directory_dependencies $@ $(module_source_dir) $(module_obj_path)

$(module_obj_path)/%.cpp.o: $(module_source_dir)/%.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $(module_obj_path)/$*.cpp.o $(module_source_dir)/$*.cpp

$(module_dep_path)/%/.$(dependency_extension): $(module_source_dir)/%/ $(module_dep_path)/%/.$(marker_extension)
	bash makelib/generate_directory_dependencies $@ $(module_source_dir)/$* $(module_obj_path)/$*

$(module_dep_path)/%.cpp.$(dependency_extension): $(module_source_dir)/%.cpp
	bash $(CPPFLAGS) makelib/generate_c_dependencies $@ $(module_source_dir)/$*.cpp $(module_obj_path)/$(*D)

$(module_dep_path)/%.h.$(dependency_extension): $(module_source_dir)/%.h
	bash $(CPPFLAGS) makelib/generate_h_dependencies $@ $(module_source_dir)/$*.h $(module_obj_path)/$(*D)
