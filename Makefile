dependency_extension=dep

directory_marker_file_extension=dirmarker
directory_marker_file=.directory.$(directory_marker_file_extension)

config=debug
config_prefix=$(config)

module_name=testmod
module_source_dir=.
module_dep_dir=dep
module_dep_path=$(config_prefix)/$(module_dep_dir)

module_target=$(module_name)

source_dependency_file=$(module_dep_path)/src.$(dependency_extension)

$(module_target): $(source_dependency_file)

include $(source_dependency_file)

%/$(directory_marker_file):
	mkdir -p $(@D)
	touch $@

.PRECIOUS: %/$(directory_marker_file)

$(source_dependency_file): $(module_dep_path)/$(directory_marker_file)
	bash makelib/generate_directory_dependencies $@ $(module_source_dir)
